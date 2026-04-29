from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional
from database import get_db
import models
from auth import require_role
from atcd import process_notice_text
from summarizer import generate_summary
import pytesseract
from PIL import Image, ImageFilter, ImageEnhance
import fitz
import io
import os
import re
from datetime import datetime

# ─── Tesseract Configuration ────────────────────────────────
if os.name == 'nt':  # Windows
    pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
else:  # Linux (Render)
    # On Render/Linux, it's usually in the PATH, but we'll set it just in case
    # or handle the missing binary gracefully
    if os.path.exists('/usr/bin/tesseract'):
        pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'
    else:
        # If missing, extract_text_from_image will just return empty string instead of crashing
        pass

router = APIRouter(prefix="/notices", tags=["Notices"])

notice_posters = require_role(
    "super_admin", "admin", "hod",
    "placement_cell", "club_coordinator", "sports_coordinator"
)

def preprocess_image(image: Image.Image) -> Image.Image:
    """
    ATCD Concept: Preprocessing pipeline for better OCR
    State machine: Original -> Grayscale -> Resize -> Enhance -> Sharpen
    """
    # Convert to grayscale
    if image.mode != 'L':
        image = image.convert('L')
    
    # Resize for better OCR
    width, height = image.size
    if width < 2000:
        scale = 2000 / width
        image = image.resize(
            (int(width * scale), int(height * scale)),
            Image.LANCZOS
        )
    
    # Enhance contrast
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(2.0)
    
    # Enhance sharpness
    enhancer = ImageEnhance.Sharpness(image)
    image = enhancer.enhance(2.0)
    
    # Apply slight sharpening filter
    image = image.filter(ImageFilter.SHARPEN)
    
    return image

def extract_text_from_pdf(file_bytes: bytes) -> str:
    """Extract text from PDF using PyMuPDF"""
    try:
        text = ""
        pdf = fitz.open(stream=file_bytes, filetype="pdf")
        for page in pdf:
            text += page.get_text()
        
        # If PDF has no text (scanned PDF), try OCR on each page
        if len(text.strip()) < 50:
            for page in pdf:
                pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
                img_bytes = pix.tobytes("png")
                text += extract_text_from_image(img_bytes)
        
        return re.sub(r'\s+', ' ', text).strip()
    except Exception as e:
        return ""

def extract_text_from_image(file_bytes: bytes) -> str:
    """
    Enhanced OCR with preprocessing
    ATCD: Multi-pass OCR with different configs
    """
    try:
        image = Image.open(io.BytesIO(file_bytes))
        
        # Convert to RGB first
        if image.mode not in ['RGB', 'L']:
            image = image.convert('RGB')
        
        # Preprocess
        processed = preprocess_image(image)
        
        # Try multiple PSM modes and take best result
        configs = [
            r'--oem 3 --psm 6',   # Assume uniform block of text
            r'--oem 3 --psm 3',   # Fully automatic
            r'--oem 3 --psm 4',   # Single column
        ]
        
        best_text = ""
        for config in configs:
            try:
                text = pytesseract.image_to_string(
                    processed,
                    config=config,
                    lang='eng'
                )
                text = re.sub(r'\s+', ' ', text).strip()
                if len(text) > len(best_text):
                    best_text = text
            except:
                continue
        
        return best_text if best_text else ""
        
    except Exception as e:
        return ""

@router.post("/post")
async def post_notice(
    title: str = Form(...),
    content: Optional[str] = Form(None),
    department: Optional[str] = Form(None),
    year: Optional[str] = Form(None),
    target_years: Optional[str] = Form(None),
    target_departments: Optional[str] = Form(None),
    category: Optional[str] = Form(None),
    is_general: bool = Form(False),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(notice_posters)
):
    extracted_text = content or ""
    file_path = None
    file_type = None

    try:
        if file and file.filename:
            file_bytes = await file.read()
            file_type = file.content_type
            file_path = f"uploads/{file.filename}"

            os.makedirs("uploads", exist_ok=True)
            with open(file_path, "wb") as f:
                f.write(file_bytes)

            try:
                if file_type and "pdf" in file_type:
                    extracted_text = extract_text_from_pdf(file_bytes)
                elif file_type and "image" in file_type:
                    extracted_text = extract_text_from_image(file_bytes)
                else:
                    extracted_text = content or title
            except:
                extracted_text = content or title

        if not extracted_text or len(extracted_text.strip()) < 10:
            extracted_text = content or title

        try:
            atcd_result = process_notice_text(extracted_text)
        except:
            atcd_result = {
                "tokens": [],
                "dates_found": [],
                "due_date": None,
                "has_deadline": False,
                "event_type": None,
                "mentioned_departments": [],
                "mentioned_years": [],
                "word_count": 0
            }

        try:
            summary = generate_summary(extracted_text)
        except:
            summary = extracted_text[:200] if extracted_text else title

        due_date = None
        if atcd_result.get("due_date"):
            try:
                due_date_str = atcd_result["due_date"]
                for fmt in ["%d %B %Y", "%d %b %Y", "%d/%m/%Y",
                           "%d-%m-%Y", "%d/%m/%y", "%d %m %Y", "%d %m %y", "%B %d %Y"]:
                    try:
                        due_date = datetime.strptime(due_date_str, fmt)
                        break
                    except:
                        continue
            except:
                due_date = None

        # Auto-categorize if admin left it blank (ATCD DFA classifier)
        final_category = category or atcd_result.get("auto_category", "general")

        notice = models.Notice(
            title=title,
            content=extracted_text,
            file_path=file_path,
            file_type=file_type,
            summary=summary,
            due_date=due_date,
            department=department,
            year=year,
            target_years=target_years,
            target_departments=target_departments,
            category=final_category,
            is_general=is_general,
            posted_by_id=current_user.id
        )
        db.add(notice)
        db.commit()
        db.refresh(notice)

        return {
            "message": "Notice posted successfully",
            "notice_id": notice.id,
            "title": notice.title,
            "summary": notice.summary,
            "atcd_analysis": atcd_result,
            "due_date": str(due_date) if due_date else atcd_result.get("due_date"),
            "posted_by": current_user.full_name,
            "role": current_user.role,
            "auto_category": atcd_result.get("auto_category", "general"),
            "category_was_auto": category is None,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error posting notice: {str(e)}"
        )

@router.get("/my-notices")
def get_my_notices(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role(
        "student", "super_admin", "admin", "hod",
        "placement_cell", "club_coordinator", "sports_coordinator"
    ))
):
    query = db.query(models.Notice)

    if current_user.role == "student":
        from sqlalchemy import or_
        conditions = [models.Notice.is_general == True]
        if current_user.department:
            conditions.append(
                models.Notice.department == current_user.department
            )
            conditions.append(
                models.Notice.target_departments.contains(
                    current_user.department
                )
            )
        if current_user.year:
            conditions.append(
                models.Notice.year == current_user.year
            )
            conditions.append(
                models.Notice.target_years.contains(current_user.year)
            )
        query = query.filter(or_(*conditions))

    elif current_user.role in ["admin", "hod", "placement_cell",
                                "club_coordinator", "sports_coordinator"]:
        from sqlalchemy import or_
        conditions = [
            models.Notice.posted_by_id == current_user.id,
            models.Notice.is_general == True,
        ]
        if current_user.department:
            conditions.append(
                models.Notice.department == current_user.department
            )
            conditions.append(
                models.Notice.target_departments.contains(
                    current_user.department
                )
            )
        query = query.filter(or_(*conditions))

    notices = query.order_by(models.Notice.created_at.desc()).all()

    result = []
    for notice in notices:
        poster = db.query(models.User).filter(
            models.User.id == notice.posted_by_id
        ).first()
        result.append({
            "id": notice.id,
            "title": notice.title,
            "summary": notice.summary,
            "content": notice.content,
            "department": notice.department,
            "year": notice.year,
            "target_years": notice.target_years,
            "target_departments": notice.target_departments,
            "category": notice.category,
            "is_general": notice.is_general,
            "due_date": str(notice.due_date) if notice.due_date else None,
            "file_type": notice.file_type,
            "file_path": notice.file_path,
            "created_at": str(notice.created_at),
            "posted_by_id": notice.posted_by_id,
            "posted_by_name": poster.full_name if poster else "Unknown",
            "posted_by_role": poster.role if poster else "unknown",
        })
    return result

@router.get("/urgency-map")
def get_urgency_map(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role(
        "student", "super_admin", "admin", "hod",
        "placement_cell", "club_coordinator", "sports_coordinator"
    ))
):
    """
    ATCD: Timed DFA - Deadline Urgency State Machine
    States: UPCOMING -> APPROACHING -> URGENT -> DUE_TODAY -> OVERDUE
    Returns all notices grouped by urgency state for this user.
    """
    from sqlalchemy import or_
    query = db.query(models.Notice)

    if current_user.role == "student":
        conditions = [models.Notice.is_general == True]
        if current_user.department:
            conditions.append(models.Notice.department == current_user.department)
            conditions.append(models.Notice.target_departments.contains(current_user.department))
        if current_user.year:
            conditions.append(models.Notice.year == current_user.year)
            conditions.append(models.Notice.target_years.contains(current_user.year))
        query = query.filter(or_(*conditions))

    notices = query.filter(models.Notice.due_date.isnot(None)).all()

    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    urgency_map = {
        "due_today":   [],
        "urgent":      [],
        "approaching": [],
        "upcoming":    [],
        "overdue":     [],
    }

    for notice in notices:
        if not notice.due_date:
            continue
        due = notice.due_date.replace(hour=0, minute=0, second=0, microsecond=0)
        diff = (due - today).days
        entry = {
            "id": notice.id,
            "title": notice.title,
            "category": notice.category or "general",
            "due_date": str(notice.due_date)[:10],
            "days_left": diff,
        }
        if diff < 0:
            entry["overdue_by"] = abs(diff)
            urgency_map["overdue"].append(entry)
        elif diff == 0:
            urgency_map["due_today"].append(entry)
        elif diff <= 3:
            urgency_map["urgent"].append(entry)
        elif diff <= 7:
            urgency_map["approaching"].append(entry)
        else:
            urgency_map["upcoming"].append(entry)
    return urgency_map


@router.get("/{notice_id}")
def get_notice(
    notice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role(
        "student", "super_admin", "admin", "hod",
        "placement_cell", "club_coordinator", "sports_coordinator"
    ))
):
    notice = db.query(models.Notice).filter(
        models.Notice.id == notice_id
    ).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    return {
        "id": notice.id,
        "title": notice.title,
        "content": notice.content,
        "summary": notice.summary,
        "department": notice.department,
        "year": notice.year,
        "is_general": notice.is_general,
        "due_date": str(notice.due_date) if notice.due_date else None,
        "file_type": notice.file_type,
        "file_path": notice.file_path,
        "created_at": str(notice.created_at),
    }


@router.post("/{notice_id}/view")
def track_notice_view(
    notice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role(
        "student", "super_admin", "admin", "hod",
        "placement_cell", "club_coordinator", "sports_coordinator"
    ))
):
    """Record that the current user viewed this notice (once per user per notice)."""
    notice = db.query(models.Notice).filter(models.Notice.id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")

    existing = db.query(models.NoticeView).filter(
        models.NoticeView.notice_id == notice_id,
        models.NoticeView.user_id == current_user.id
    ).first()

    if not existing:
        view = models.NoticeView(
            notice_id=notice_id,
            user_id=current_user.id
        )
        db.add(view)
        db.commit()

    return {"message": "View recorded"}


@router.delete("/{notice_id}")
def delete_notice(
    notice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role(
        "super_admin", "admin"
    ))
):
    notice = db.query(models.Notice).filter(
        models.Notice.id == notice_id
    ).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    db.delete(notice)
    db.commit()
    return {"message": "Notice deleted successfully"}
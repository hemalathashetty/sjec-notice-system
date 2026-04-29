from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas
from auth import hash_password, require_role
from models import RoleEnum, DepartmentEnum

router = APIRouter(prefix="/superadmin", tags=["Super Admin"])

# ─── DEPENDENCY: only super_admin can access ───────────────
super_admin_only = require_role("super_admin")

# ─── ADD ANY USER (admin, hod, placement, club, sports) ────
@router.post("/add-user", response_model=schemas.UserResponse)
def add_user(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    # Super admin cannot be created through this route
    if user.role == RoleEnum.super_admin:
        raise HTTPException(
            status_code=400,
            detail="Cannot create another super admin"
        )

    existing = db.query(models.User).filter(
        models.User.email == user.email
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = models.User(
        full_name=user.full_name,
        email=user.email,
        hashed_password=hash_password(user.password[:72]),
        role=user.role,
        department=user.department,
        year=user.year
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

# ─── GET ALL USERS ──────────────────────────────────────────
@router.get("/users", response_model=List[schemas.UserResponse])
def get_all_users(
    role: Optional[str] = None,
    department: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    if department:
        query = query.filter(models.User.department == department)
    return query.all()

# ─── GET ALL STUDENTS ───────────────────────────────────────
@router.get("/students", response_model=List[schemas.UserResponse])
def get_all_students(
    department: Optional[str] = None,
    year: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    query = db.query(models.User).filter(
        models.User.role == RoleEnum.student
    )
    if department:
        query = query.filter(models.User.department == department)
    if year:
        query = query.filter(models.User.year == year)
    return query.all()

# ─── ACTIVATE / DEACTIVATE USER ─────────────────────────────
@router.put("/user/{user_id}/toggle-status")
def toggle_user_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = not user.is_active
    db.commit()
    return {
        "message": f"User {'activated' if user.is_active else 'deactivated'} successfully",
        "is_active": user.is_active
    }

# ─── DELETE USER ────────────────────────────────────────────
@router.delete("/user/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == RoleEnum.super_admin:
        raise HTTPException(status_code=400, detail="Cannot delete super admin")

    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}

# ─── DELETE ALL STUDENTS OF A CLASS (year + dept) ───────────
@router.delete("/students/batch")
def delete_students_batch(
    year: str,
    department: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    students = db.query(models.User).filter(
        models.User.role == RoleEnum.student,
        models.User.year == year,
        models.User.department == department,
    ).all()
    count = len(students)
    for s in students:
        db.delete(s)
    db.commit()
    return {"message": f"Deleted {count} student(s) from {year} / {department}"}

# ─── PROMOTE ALL STUDENTS OF A CLASS ────────────────────────
YEAR_PROGRESSION = {
    "UG1": "UG2", "UG2": "UG3", "UG3": "UG4",
    "UG4": None,   # Graduates
    "PG1": "PG2",
    "PG2": None,   # Graduates
}

@router.put("/students/promote")
def promote_students(
    year: str,
    department: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    next_year = YEAR_PROGRESSION.get(year)
    students = db.query(models.User).filter(
        models.User.role == RoleEnum.student,
        models.User.year == year,
        models.User.department == department,
    ).all()

    promoted = 0
    graduated = 0
    for s in students:
        if next_year:
            s.year = next_year
            promoted += 1
        else:
            s.is_active = False
            graduated += 1

    db.commit()
    if next_year:
        return {
            "message": f"Promoted {promoted} student(s): {year} → {next_year} ({department})",
            "promoted": promoted, "graduated": 0, "next_year": next_year,
        }
    else:
        return {
            "message": f"Graduated {graduated} student(s) from {year} ({department}) — accounts deactivated",
            "promoted": 0, "graduated": graduated, "next_year": None,
        }

# ─── GET DASHBOARD ANALYTICS ────────────────────────────────
@router.get("/dashboard")
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    total_users = db.query(models.User).count()
    total_students = db.query(models.User).filter(
        models.User.role == RoleEnum.student
    ).count()
    total_admins = db.query(models.User).filter(
        models.User.role == RoleEnum.admin
    ).count()
    total_notices = db.query(models.Notice).count()

    # Students per department
    dept_stats = []
    for dept in DepartmentEnum:
        count = db.query(models.User).filter(
            models.User.role == RoleEnum.student,
            models.User.department == dept
        ).count()
        dept_stats.append({"department": dept.value, "students": count})

    # Notices per department
    notice_stats = []
    for dept in DepartmentEnum:
        count = db.query(models.Notice).filter(
            models.Notice.department == dept
        ).count()
        notice_stats.append({"department": dept.value, "notices": count})

    return {
        "super_admin_name": current_user.full_name,
        "total_users": total_users,
        "total_students": total_students,
        "total_admins": total_admins,
        "total_notices": total_notices,
        "students_per_department": dept_stats,
        "notices_per_department": notice_stats
    }

# ─── GET ALL NOTICES ────────────────────────────────────────
@router.get("/notices")
def get_all_notices(
    department: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(super_admin_only)
):
    query = db.query(models.Notice)
    if department:
        query = query.filter(models.Notice.department == department)
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
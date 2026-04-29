from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, distinct
from database import get_db
import models
from auth import require_role
from datetime import datetime, timedelta

router = APIRouter(prefix="/analytics", tags=["Analytics"])


def _count_eligible_students(db: Session, notice: models.Notice) -> int:
    """Count how many students are eligible to see this notice."""
    from sqlalchemy import or_
    query = db.query(func.count(models.User.id)).filter(
        models.User.role == "student",
        models.User.is_active == True
    )
    if not notice.is_general:
        conditions = []
        if notice.department:
            conditions.append(models.User.department == notice.department)
        if notice.year:
            conditions.append(models.User.year == notice.year)
        if conditions:
            query = query.filter(or_(*conditions))
    return query.scalar() or 0


@router.get("/stats")
def get_analytics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(
        require_role("super_admin", "admin", "hod",
                     "placement_cell", "club_coordinator", "sports_coordinator")
    ),
):
    """Return analytics stats for the current admin's notices."""
    # Only fetch notices posted by this user (or all for super_admin)
    if current_user.role == "super_admin":
        notices = db.query(models.Notice).order_by(models.Notice.created_at.desc()).all()
    else:
        notices = (
            db.query(models.Notice)
            .filter(models.Notice.posted_by_id == current_user.id)
            .order_by(models.Notice.created_at.desc())
            .all()
        )

    total_notices = len(notices)
    notice_ids = [n.id for n in notices]

    # Total unique views across all notices
    total_views = db.query(func.count(models.NoticeView.id)).filter(
        models.NoticeView.notice_id.in_(notice_ids)
    ).scalar() or 0

    # Unique students who viewed at least one notice
    unique_readers = db.query(func.count(distinct(models.NoticeView.user_id))).filter(
        models.NoticeView.notice_id.in_(notice_ids)
    ).scalar() or 0

    # Total students in system
    total_students = db.query(func.count(models.User.id)).filter(
        models.User.role == "student",
        models.User.is_active == True
    ).scalar() or 0

    # Last 7 days notices count
    week_ago = datetime.utcnow() - timedelta(days=7)
    recent_count = sum(1 for n in notices if n.created_at and n.created_at >= week_ago)

    # Per-notice analytics
    notice_stats = []
    category_map: dict = {}

    for notice in notices:
        view_count = db.query(func.count(models.NoticeView.id)).filter(
            models.NoticeView.notice_id == notice.id
        ).scalar() or 0

        unique_viewers = db.query(func.count(distinct(models.NoticeView.user_id))).filter(
            models.NoticeView.notice_id == notice.id
        ).scalar() or 0

        eligible = _count_eligible_students(db, notice)
        view_rate = round((unique_viewers / eligible * 100), 1) if eligible > 0 else 0.0

        notice_stats.append({
            "id": notice.id,
            "title": notice.title,
            "category": notice.category or "general",
            "department": notice.department,
            "posted_at": str(notice.created_at)[:10] if notice.created_at else None,
            "due_date": str(notice.due_date)[:10] if notice.due_date else None,
            "views": view_count,
            "unique_readers": unique_viewers,
            "eligible_students": eligible,
            "view_rate": view_rate,
            "is_general": notice.is_general,
        })

        # Category breakdown
        cat = notice.category or "general"
        if cat not in category_map:
            category_map[cat] = {"count": 0, "views": 0}
        category_map[cat]["count"] += 1
        category_map[cat]["views"] += view_count

    # Sort by view count desc
    notice_stats.sort(key=lambda x: x["views"], reverse=True)

    overall_view_rate = round((unique_readers / total_students * 100), 1) if total_students > 0 else 0.0

    return {
        "total_notices": total_notices,
        "total_views": total_views,
        "unique_readers": unique_readers,
        "total_students": total_students,
        "overall_view_rate": overall_view_rate,
        "recent_7_days": recent_count,
        "notices": notice_stats,
        "by_category": category_map,
    }

from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Text, Enum
from sqlalchemy.orm import relationship
from database import Base
import enum
from datetime import datetime

class RoleEnum(str, enum.Enum):
    super_admin = "super_admin"
    admin = "admin"
    hod = "hod"
    placement_cell = "placement_cell"
    club_coordinator = "club_coordinator"
    sports_coordinator = "sports_coordinator"
    student = "student"

class DepartmentEnum(str, enum.Enum):
    CSE = "CSE"
    CSBS = "CSBS"
    CSDS = "CSDS"
    AIML = "AIML"
    EEE = "EEE"
    EC = "EC"
    ME = "ME"
    CIVIL = "CIVIL"
    MBA = "MBA"
    MCA = "MCA"

class YearEnum(str, enum.Enum):
    UG1 = "UG1"
    UG2 = "UG2"
    UG3 = "UG3"
    UG4 = "UG4"
    PG1 = "PG1"
    PG2 = "PG2"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(RoleEnum), nullable=False)
    department = Column(Enum(DepartmentEnum), nullable=True)
    year = Column(Enum(YearEnum), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    notices = relationship("Notice", back_populates="posted_by")

class Notice(Base):
    __tablename__ = "notices"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=True)
    file_path = Column(String, nullable=True)
    file_type = Column(String, nullable=True)
    summary = Column(Text, nullable=True)
    due_date = Column(DateTime, nullable=True)
    department = Column(Enum(DepartmentEnum), nullable=True)
    target_years = Column(String, nullable=True)
    target_departments = Column(String, nullable=True)
    category = Column(String, nullable=True)
    year = Column(Enum(YearEnum), nullable=True)
    is_general = Column(Boolean, default=False)
    posted_by_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)

    posted_by = relationship("User", back_populates="notices")
    views = relationship("NoticeView", back_populates="notice", cascade="all, delete-orphan")

class NoticeView(Base):
    __tablename__ = "notice_views"

    id = Column(Integer, primary_key=True, index=True)
    notice_id = Column(Integer, ForeignKey("notices.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    viewed_at = Column(DateTime, default=datetime.utcnow)

    notice = relationship("Notice", back_populates="views")
    user = relationship("User")
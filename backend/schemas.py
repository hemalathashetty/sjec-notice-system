from pydantic import BaseModel, field_validator
from typing import Optional
from models import RoleEnum, DepartmentEnum, YearEnum

class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str
    role: RoleEnum
    department: Optional[DepartmentEnum] = None
    year: Optional[YearEnum] = None

class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    role: str
    full_name: str
    user_id: int

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    role: RoleEnum
    department: Optional[DepartmentEnum]
    year: Optional[YearEnum]
    is_active: bool

    class Config:
        from_attributes = True
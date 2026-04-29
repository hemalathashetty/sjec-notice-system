from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
import models, schemas
from auth import hash_password, verify_password, create_access_token, is_valid_college_email, require_role

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    email_str = str(user.email)
    
    # ATCD: DFA email validation
    if not is_valid_college_email(email_str):
        raise HTTPException(
            status_code=400,
            detail="Only SJEC email allowed. Student: 25cs001@sjec.ac.in | Staff: firstname@sjec.ac.in"
    )

    # Check if email already exists
    existing = db.query(models.User).filter(
        models.User.email == email_str
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create new user
    new_user = models.User(
        full_name=user.full_name,
        email=email_str,
        hashed_password=hash_password(user.password),
        role=user.role,
        department=user.department,
        year=user.year
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=schemas.TokenResponse)
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    email_str = str(user.email).lower().strip()
    # ATCD: validate email format first
    if not is_valid_college_email(email_str):
        raise HTTPException(status_code=400, detail="Invalid college email")

    # Find user
    print(f"Login attempt for email: '{email_str}' with password length: {len(user.password)}")
    db_user = db.query(models.User).filter(
        models.User.email == email_str
    ).first()
    
    if not db_user:
        print(f"User not found in DB: '{email_str}'")
        raise HTTPException(status_code=401, detail="Invalid email or password (User not found)")
        
    is_valid_pwd = verify_password(user.password, db_user.hashed_password)
    print(f"Password valid for {email_str}: {is_valid_pwd}")
    
    if not is_valid_pwd:
        raise HTTPException(status_code=401, detail="Invalid email or password (Wrong password)")

    if not db_user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    token = create_access_token({"sub": db_user.email})
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": db_user.role,
        "full_name": db_user.full_name,
        "user_id": db_user.id
    }

@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user: models.User = Depends(require_role(
    "super_admin", "admin", "hod", "placement_cell",
    "club_coordinator", "sports_coordinator", "student"
))):
    return current_user
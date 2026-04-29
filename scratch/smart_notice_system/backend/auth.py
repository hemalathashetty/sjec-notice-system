import re
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
import models

# ─── CONFIG ───────────────────────────────────────────────
SECRET_KEY = "your_secret_key_here_make_it_long_and_random"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

# ─── ATCD: DFA for college email validation ───────────────
# Only allows emails ending with @college.edu.in or @student.college.edu.in
# ATCD: DFA patterns for SJEC email validation

# Student email: 25cs001@sjec.ac.in
# Pattern: 2digits + dept_code + roll_number + @sjec.ac.in
STUDENT_EMAIL_PATTERN = re.compile(
    r'^\d{2}(cs|csbs|csds|aiml|eee|ec|me|civil|mba|mca)\d{3}@sjec\.ac\.in$',
    re.IGNORECASE
)

# Staff/Admin email: firstname@sjec.ac.in or firstname.lastname@sjec.ac.in
STAFF_EMAIL_PATTERN = re.compile(
    r'^[a-zA-Z0-9._%+-]+@sjec\.ac\.in$'
)

def is_valid_college_email(email: str) -> bool:
    """
    ATCD Concept: DFA-based email validation
    Two automata - one for students, one for staff
    Both must end with @sjec.ac.in

    Student DFA states:
    Start -> 2 digits -> dept code -> 3 digit roll -> @ -> sjec.ac.in -> Accept

    Staff DFA states:
    Start -> letters -> optional(.letters) -> @ -> sjec.ac.in -> Accept
    """
    return bool(
        STUDENT_EMAIL_PATTERN.match(email) or
        STAFF_EMAIL_PATTERN.match(email)
    )

def is_student_email(email: str) -> bool:
    return bool(STUDENT_EMAIL_PATTERN.match(email))

def is_staff_email(email: str) -> bool:
    return bool(STAFF_EMAIL_PATTERN.match(email))

# ─── PASSWORD HASHING ─────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password[:72])

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password[:72], hashed_password)

# ─── JWT TOKEN ────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

def require_role(*roles):
    """Role-based access control checker"""
    def role_checker(current_user: models.User = Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {roles}"
            )
        return current_user
    return role_checker
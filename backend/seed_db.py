import models
from database import SessionLocal, engine
from auth import hash_password

def seed_users():
    models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    if not db.query(models.User).first():
        users = [
            models.User(full_name="Super Admin", email="superadmin@sjec.ac.in", hashed_password=hash_password("password123"), role=models.RoleEnum.super_admin),
            models.User(full_name="Admin User", email="admin@sjec.ac.in", hashed_password=hash_password("password123"), role=models.RoleEnum.admin),
            models.User(full_name="HOD CSE", email="hodcse@sjec.ac.in", hashed_password=hash_password("password123"), role=models.RoleEnum.hod, department=models.DepartmentEnum.CSE),
            models.User(full_name="Student One", email="25cs001@sjec.ac.in", hashed_password=hash_password("password123"), role=models.RoleEnum.student, department=models.DepartmentEnum.CSE, year=models.YearEnum.UG1),
            models.User(full_name="Student Two", email="25cs002@sjec.ac.in", hashed_password=hash_password("password123"), role=models.RoleEnum.student, department=models.DepartmentEnum.CSE, year=models.YearEnum.UG1)
        ]
        db.add_all(users)
        db.commit()
        print("Database seeded with test accounts.")
    else:
        print("Database already seeded.")
    db.close()

if __name__ == "__main__":
    seed_users()

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import get_db
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from routers import users
from routers import superadmin
from routers import notices
from routers import chatbot
from routers import analytics
from seed_db import seed_users

app = FastAPI(
    title="Smart Notice Management System",
    description="AI + ATCD powered notice system",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

from database import engine
import models
models.Base.metadata.create_all(bind=engine)
seed_users()

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(users.router)
app.include_router(superadmin.router)
app.include_router(notices.router)
app.include_router(chatbot.router)
app.include_router(analytics.router)

@app.get("/")
def root():
    return {"message": "Smart Notice System API is running!"}
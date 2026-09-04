from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.children import router as children_router
from routes.activities import router as activities_router
from routes.activity_attempts import router as activity_attempts_router
from routes.activity_results import router as activity_results_router
from routes.progress import router as progress_router
from database import Base, engine
from routes.child_assignments import router as child_assignments_router
from models import (
    User,
    Child,
    Activity,
    ActivityAttempt,
    ActivityResult,
    Progress
)

from routes.auth import router as auth_router
from routes.analysis import router as analysis_router
from routes.recommendations import router as recommendations_router

app = FastAPI(
    title="Autism Learning Assistant API"
)


# Allow local Flutter web development to call the API.
# For production, replace "*" with the real frontend origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(
    bind=engine
)


# Authentication routes
app.include_router(auth_router)
app.include_router(child_assignments_router)
app.include_router(recommendations_router)
app.include_router(analysis_router)
app.include_router(children_router)
app.include_router(activities_router)
app.include_router(activity_attempts_router)
app.include_router(activity_results_router)
app.include_router(progress_router)

@app.get("/")
def home():
    return {
        "message": "Autism Learning Assistant API is running!"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }
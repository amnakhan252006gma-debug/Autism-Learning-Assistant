from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from sqlalchemy.orm import Session

import bcrypt
import os
from dotenv import load_dotenv

from database import SessionLocal
from models import User

load_dotenv()
router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


# -------------------------
# Security settings
# -------------------------

SECRET_KEY = os.getenv("SECRET_KEY")

if not SECRET_KEY:
    raise ValueError("SECRET_KEY is not set in the .env file")
ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 60


oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/token"
)


# -------------------------
# Database session
# -------------------------

def get_db():
    db = SessionLocal()

    try:
        yield db

    finally:
        db.close()


# -------------------------
# Request models
# -------------------------

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    role: str


class LoginRequest(BaseModel):
    email: str
    password: str


# -------------------------
# Password functions
# -------------------------

def hash_password(password: str):

    password_bytes = password.encode("utf-8")

    hashed = bcrypt.hashpw(
        password_bytes,
        bcrypt.gensalt()
    )

    return hashed.decode("utf-8")


def verify_password(
    plain_password: str,
    hashed_password: str
):

    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8")
    )


# -------------------------
# JWT function
# -------------------------

def create_access_token(
    data: dict,
    expires_delta: timedelta | None = None
):

    to_encode = data.copy()

    if expires_delta:

        expire = datetime.now(timezone.utc) + expires_delta

    else:

        expire = datetime.now(timezone.utc) + timedelta(
            minutes=15
        )

    to_encode.update({
        "exp": expire
    })

    return jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )


# -------------------------
# REGISTER
# -------------------------

@router.post("/register")
def register(
    user_data: RegisterRequest,
    db: Session = Depends(get_db)
):

    existing_user = (
        db.query(User)
        .filter(User.email == user_data.email)
        .first()
    )

    if existing_user:

        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    allowed_roles = [
        "parent",
        "teacher",
        "therapist"
    ]

    if user_data.role.lower() not in allowed_roles:

        raise HTTPException(
            status_code=400,
            detail="Invalid role"
        )

    new_user = User(
        name=user_data.name,
        email=user_data.email,
        password=hash_password(user_data.password),
        role=user_data.role.lower()
    )

    db.add(new_user)

    db.commit()

    db.refresh(new_user)

    return {
        "message": "User registered successfully",

        "user": {
            "id": new_user.id,
            "name": new_user.name,
            "email": new_user.email,
            "role": new_user.role
        }
    }


# -------------------------
# LOGIN
# -------------------------

@router.post("/login")
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):

    user = (
        db.query(User)
        .filter(User.email == login_data.email)
        .first()
    )

    if not user:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    if not verify_password(
        login_data.password,
        user.password
    ):

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "role": user.role
        },

        expires_delta=timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        )
    )

    return {
        "message": "Login successful",

        "access_token": access_token,

        "token_type": "bearer",

        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role
        }
    }


# -------------------------
# OAUTH2 TOKEN FOR SWAGGER
# -------------------------

@router.post("/token")
async def oauth2_login(
    request: Request,
    db: Session = Depends(get_db)
):

    form_data = await request.form()

    username = form_data.get("username")
    password = form_data.get("password")

    if not username or not password:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Username and password are required"
        )

    user = (
        db.query(User)
        .filter(User.email == username)
        .first()
    )

    if not user:

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    if not verify_password(
        password,
        user.password
    ):

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "role": user.role
        },

        expires_delta=timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        )
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


# -------------------------
# GET CURRENT USER
# -------------------------

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,

        detail="Could not validate credentials",

        headers={
            "WWW-Authenticate": "Bearer"
        }
    )

    try:

        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        user_id = payload.get("sub")

        if user_id is None:

            raise credentials_exception

    except JWTError:

        raise credentials_exception

    user = (
        db.query(User)
        .filter(User.id == int(user_id))
        .first()
    )

    if user is None:

        raise credentials_exception

    return user


# -------------------------
# TEST PROTECTED ROUTE
# -------------------------

@router.get("/me")
def get_me(
    current_user: User = Depends(get_current_user)
):

    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role
    }
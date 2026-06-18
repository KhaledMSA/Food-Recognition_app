"""
routers/auth.py
===============
Authentication endpoints.

Endpoints:
    POST /auth/signup  — create account, return token
    POST /auth/login   — verify credentials, return token
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User
from app.schemas import LoginRequest, OnboardingRequest, SignupRequest, TokenResponse, UserResponse
from app.nutrition_utils import calculate_nutrition_goals

router = APIRouter(prefix="/auth", tags=["Auth"])

# ---------------------------------------------------------------------------
# Password hashing
# ---------------------------------------------------------------------------
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _hash_password(plain: str) -> str:
    return _pwd_context.hash(plain)


def _verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


def _generate_token() -> str:
    return uuid.uuid4().hex + uuid.uuid4().hex  # 64-char hex string


# ---------------------------------------------------------------------------
# POST /auth/signup
# ---------------------------------------------------------------------------

@router.post("/signup", response_model=TokenResponse, status_code=201)
def signup(payload: SignupRequest, db: Session = Depends(get_db)):
    """
    Create a new user account.

    Returns a simple auth token and the new user_id.
    Onboarding is NOT yet complete — the Flutter app should redirect
    to the onboarding screen.
    """
    # Check email uniqueness
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(status_code=409, detail="An account with this email already exists.")

    token = _generate_token()
    user = User(
        email=payload.email.lower().strip(),
        password_hash=_hash_password(payload.password),
        name=payload.name,
        auth_token=token,
        onboarding_completed=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenResponse(
        token=token,
        user_id=user.id,
        onboarding_completed=False,
    )


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------

@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate with email + password.

    Returns a token and whether onboarding has been completed.
    If onboarding_completed is False, redirect to onboarding.
    """
    user: User | None = db.query(User).filter(User.email == payload.email.lower()).first()

    if not user or not _verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password.",
        )

    # Rotate token on each login for basic security
    token = _generate_token()
    user.auth_token = token
    db.commit()

    return TokenResponse(
        token=token,
        user_id=user.id,
        onboarding_completed=user.onboarding_completed,
    )


# ---------------------------------------------------------------------------
# POST /auth/onboarding — complete onboarding and compute nutrition goals
# ---------------------------------------------------------------------------

@router.post("/onboarding", response_model=UserResponse)
def complete_onboarding(
    user_id: int,
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
):
    """
    Save onboarding answers and calculate daily nutrition targets.

    Call this after the user completes the 6-step onboarding flow.
    Sets onboarding_completed = True.
    """
    user: User | None = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail=f"User {user_id} not found.")

    # Calculate nutrition goals
    goals = calculate_nutrition_goals(
        gender=payload.gender,
        weight_kg=payload.weight_kg,
        height_cm=payload.height_cm,
        goal=payload.goal,
        weekly_effort=payload.weekly_effort,
    )

    user.name = payload.name
    user.goal = payload.goal
    user.gender = payload.gender
    user.weight_kg = payload.weight_kg
    user.height_cm = payload.height_cm
    user.weekly_effort = payload.weekly_effort
    user.daily_calorie_goal = goals["calories"]
    user.daily_protein_goal = goals["protein"]
    user.daily_carbs_goal = goals["carbs"]
    user.daily_fat_goal = goals["fat"]
    user.onboarding_completed = True

    db.commit()
    db.refresh(user)

    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        gender=user.gender,
        height_cm=user.height_cm,
        weight_kg=user.weight_kg,
        goal=user.goal,
        weekly_effort=user.weekly_effort,
        daily_calorie_goal=user.daily_calorie_goal,
        daily_protein_goal=user.daily_protein_goal,
        daily_carbs_goal=user.daily_carbs_goal,
        daily_fat_goal=user.daily_fat_goal,
        onboarding_completed=user.onboarding_completed,
    )

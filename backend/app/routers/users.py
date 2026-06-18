"""
routers/users.py
================
User profile endpoints.

Endpoints:
    GET   /users/me         — return current user's profile
    PATCH /users/me         — update profile fields
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import User
from app.nutrition_utils import calculate_nutrition_goals
from app.schemas import UpdateProfileRequest, UserResponse

router = APIRouter(prefix="/users", tags=["Users"])


# ---------------------------------------------------------------------------
# Helper — resolve user from token header
# ---------------------------------------------------------------------------

def _get_user_by_token(token: str, db: Session) -> User:
    user = db.query(User).filter(User.auth_token == token).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    return user


# ---------------------------------------------------------------------------
# GET /users/me
# ---------------------------------------------------------------------------

@router.get("/me", response_model=UserResponse)
def get_me(
    x_auth_token: str = Header(..., description="Auth token from login/signup"),
    db: Session = Depends(get_db),
):
    """Return the current user's profile."""
    user = _get_user_by_token(x_auth_token, db)
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


# ---------------------------------------------------------------------------
# PATCH /users/me
# ---------------------------------------------------------------------------

@router.patch("/me", response_model=UserResponse)
def update_me(
    payload: UpdateProfileRequest,
    x_auth_token: str = Header(..., description="Auth token from login/signup"),
    db: Session = Depends(get_db),
):
    """
    Update profile fields. Only provided fields are changed.
    If goal, weight, or effort changes, nutrition goals are recalculated.
    """
    user = _get_user_by_token(x_auth_token, db)

    if payload.name is not None:
        user.name = payload.name
    if payload.goal is not None:
        user.goal = payload.goal
    if payload.gender is not None:
        user.gender = payload.gender
    if payload.weight_kg is not None:
        user.weight_kg = payload.weight_kg
    if payload.height_cm is not None:
        user.height_cm = payload.height_cm
    if payload.weekly_effort is not None:
        user.weekly_effort = payload.weekly_effort

    # Recalculate nutrition goals if we have enough data
    if all([user.gender, user.weight_kg, user.height_cm, user.goal, user.weekly_effort]):
        goals = calculate_nutrition_goals(
            gender=user.gender,
            weight_kg=user.weight_kg,
            height_cm=user.height_cm,
            goal=user.goal,
            weekly_effort=user.weekly_effort,
        )
        user.daily_calorie_goal = goals["calories"]
        user.daily_protein_goal = goals["protein"]
        user.daily_carbs_goal = goals["carbs"]
        user.daily_fat_goal = goals["fat"]

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

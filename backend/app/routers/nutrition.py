"""
routers/nutrition.py
====================
Nutrition summary endpoint.

Endpoints:
    GET /nutrition/daily-summary  — aggregate daily totals from meal_items

No cache table (daily_nutrition_summary) is used here.
Totals are computed live by a single aggregation query over meal_items.
This is fast enough for a graduation project. Add a cache table as a
Phase 2 optimisation when needed.
"""

from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Meal, MealItem, User
from app.schemas import DailySummaryResponse

router = APIRouter(prefix="/nutrition", tags=["Nutrition"])


@router.get("/daily-summary", response_model=DailySummaryResponse)
def daily_summary(
    user_id: int = Query(..., description="User ID to summarise"),
    date: date_type | None = Query(None, description="Date to summarise (YYYY-MM-DD). Defaults to today."),
    db: Session = Depends(get_db),
):
    """
    **Daily nutrition totals for a user.**

    Aggregates `calories`, `protein_g`, `carbs_g`, and `fat_g` directly
    from `meal_items` for the requested date. No cache table required.

    Also returns the user's `calorie_goal` and `calories_remaining`
    so the frontend can render a progress bar without an extra request.

    ---
    **Example request:**
    ```
    GET /nutrition/daily-summary?user_id=1&date=2026-06-14
    ```

    **Example response:**
    ```json
    {
        "user_id": 1,
        "date": "2026-06-14",
        "total_calories": 1540.0,
        "total_protein_g": 72.5,
        "total_carbs_g": 185.0,
        "total_fat_g": 52.0,
        "entry_count": 4,
        "calorie_goal": 2000,
        "calories_remaining": 460.0
    }
    ```

    Equivalent SQL:
    ```sql
    SELECT
        SUM(mi.calories)   AS total_calories,
        SUM(mi.protein_g)  AS total_protein_g,
        SUM(mi.carbs_g)    AS total_carbs_g,
        SUM(mi.fat_g)      AS total_fat_g,
        COUNT(mi.id)       AS entry_count
    FROM meal_items mi
    JOIN meals m ON m.id = mi.meal_id
    WHERE m.user_id = :user_id
      AND m.meal_date = :date;
    ```
    """
    target_date = date or date_type.today()

    # ── Validate user exists ──────────────────────────────────────────────────
    user: User | None = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail=f"User with id={user_id} not found.",
        )

    # ── Single aggregation query — no cache table needed ─────────────────────
    # Equivalent SQL:
    #   SELECT SUM(mi.calories), SUM(mi.protein_g), SUM(mi.carbs_g),
    #          SUM(mi.fat_g), COUNT(mi.id)
    #   FROM meal_items mi JOIN meals m ON m.id = mi.meal_id
    #   WHERE m.user_id = :user_id AND m.meal_date = :date
    result = (
        db.query(
            func.coalesce(func.sum(MealItem.calories),  0.0).label("total_calories"),
            func.coalesce(func.sum(MealItem.protein_g), 0.0).label("total_protein_g"),
            func.coalesce(func.sum(MealItem.carbs_g),   0.0).label("total_carbs_g"),
            func.coalesce(func.sum(MealItem.fat_g),     0.0).label("total_fat_g"),
            func.count(MealItem.id).label("entry_count"),
        )
        .join(Meal, Meal.id == MealItem.meal_id)
        .filter(Meal.user_id == user_id, Meal.meal_date == target_date)
        .one()
    )

    total_calories = round(float(result.total_calories),  2)
    total_protein  = round(float(result.total_protein_g), 2)
    total_carbs    = round(float(result.total_carbs_g),   2)
    total_fat      = round(float(result.total_fat_g),     2)

    calorie_goal       = user.daily_calorie_goal  # default 2000 from schema
    calories_remaining = round(calorie_goal - total_calories, 2)

    return DailySummaryResponse(
        user_id=user_id,
        date=target_date,
        total_calories=total_calories,
        total_protein_g=total_protein,
        total_carbs_g=total_carbs,
        total_fat_g=total_fat,
        entry_count=result.entry_count,
        calorie_goal=calorie_goal,
        calories_remaining=calories_remaining,
    )

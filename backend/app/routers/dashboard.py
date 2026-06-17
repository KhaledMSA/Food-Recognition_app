"""
routers/dashboard.py
====================
Stage 4 of the data flow: Dashboard.

Endpoint:
    GET /dashboard/daily  — aggregate daily nutrition totals from meal_items

No daily_nutrition_summary table is used here.
Totals are computed live by querying meal_items → meals for the requested
user + date. This is fast enough for a graduation project.

When you're ready to optimise (Phase 2), add the daily_nutrition_summary
table and replace this aggregation with a single SELECT on that table.
"""

from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models import Meal, MealItem, User
from app.schemas import DailyDashboard, DailyMealSummary, MealItemResponse

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/daily", response_model=DailyDashboard)
def daily_dashboard(
    user_id: int,
    date: date_type | None = None,
    db: Session = Depends(get_db),
):
    """
    **Stage 4: Dashboard**

    Returns a complete nutrition summary for a user on a given date.

    Aggregates directly from `meal_items` (no cache table needed yet):
    - Total calories, protein, carbs, fat for the day
    - Per-meal breakdown with individual food items
    - Calorie goal and remaining calories (if the user has a goal set)

    Query params:
        user_id  — required
        date     — optional, defaults to today (YYYY-MM-DD)
    """
    target_date = date or date_type.today()

    # --- Validate user exists ---
    user: User | None = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail=f"User {user_id} not found.")

    # --- Load all meals + items for this user + date ---
    meals = (
        db.query(Meal)
        .options(
            joinedload(Meal.items).joinedload(MealItem.food_item)
        )
        .filter(Meal.user_id == user_id, Meal.meal_date == target_date)
        .order_by(Meal.created_at)
        .all()
    )

    # --- Build per-meal breakdown ---
    daily_meals: list[DailyMealSummary] = []
    total_calories = 0.0
    total_protein  = 0.0
    total_carbs    = 0.0
    total_fat      = 0.0

    for meal in meals:
        meal_items_response = [
            MealItemResponse(
                predicted_label=mi.predicted_label or "",
                display_name=(
                    mi.food_item.display_name
                    if mi.food_item
                    else (mi.predicted_label or "Unknown")
                ),
                serving_g=mi.serving_g,
                calories=mi.calories,
                protein_g=mi.protein_g,
                carbs_g=mi.carbs_g,
                fat_g=mi.fat_g,
                confidence=mi.confidence,
                image_path=mi.image_path,
                source="db" if mi.food_item_id else "map",
            )
            for mi in meal.items
        ]

        meal_cal  = round(sum(i.calories  for i in meal_items_response), 2)
        meal_prot = round(sum(i.protein_g for i in meal_items_response), 2)
        meal_carb = round(sum(i.carbs_g   for i in meal_items_response), 2)
        meal_fat  = round(sum(i.fat_g     for i in meal_items_response), 2)

        total_calories += meal_cal
        total_protein  += meal_prot
        total_carbs    += meal_carb
        total_fat      += meal_fat

        daily_meals.append(
            DailyMealSummary(
                meal_id=meal.id,
                meal_type=meal.name,
                items=meal_items_response,
                meal_calories=meal_cal,
                meal_protein_g=meal_prot,
                meal_carbs_g=meal_carb,
                meal_fat_g=meal_fat,
            )
        )

    # --- Calorie goal tracking ---
    calorie_goal = user.daily_calorie_goal  # default 2000 from schema
    calories_remaining = round(calorie_goal - total_calories, 2)

    return DailyDashboard(
        user_id=user_id,
        date=target_date,
        total_calories=round(total_calories, 2),
        total_protein_g=round(total_protein,  2),
        total_carbs_g=round(total_carbs,    2),
        total_fat_g=round(total_fat,      2),
        meal_count=len(meals),
        meals=daily_meals,
        calorie_goal=calorie_goal,
        calories_remaining=calories_remaining,
    )

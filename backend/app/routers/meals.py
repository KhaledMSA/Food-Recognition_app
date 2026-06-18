"""
routers/meals.py
================
Meal logging endpoints.

Endpoints:
    POST   /meals                — log one food item, save nutrition snapshot
    GET    /meals                — list all logged entries for a user (paginated)
    GET    /meals/today          — shortcut for today's entries
    DELETE /meals/{meal_id}      — remove a logged meal entry

Serving-unit conversion
-----------------------
The user supplies serving_quantity + serving_unit.
This router converts that to grams before calculating macros:

    Unit      → Grams
    ─────────────────
    g / ml    → 1× (direct)
    oz        → 28.35×
    lb        → 453.59×
    cup       → 240×  (approximate — water density)
    tbsp      → 15×
    tsp       → 5×
    piece / slice / serving  → food's default_serving_g × quantity

Nutrition lookup order:
    1. food_items DB table (seeded from seed_food_items.sql)
    2. nutrition_map.py in-memory dict (fallback, no DB round-trip)
    3. 404 if unknown in both
"""

from datetime import date as date_type
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models import FoodItem, Meal, MealItem
from app.nutrition_utils import ALL_VALID_UNITS, resolve_nutrition, to_grams
from app.schemas import MealEntryResponse, MealLogRequest, ManualMealRequest

router = APIRouter(prefix="/meals", tags=["Meals"])




# ─────────────────────────────────────────────────────────────────────────────
# Shared helper — MealItem → MealEntryResponse
# ─────────────────────────────────────────────────────────────────────────────

def _to_entry_response(mi: MealItem, meal: Meal) -> MealEntryResponse:
    """Build a flat MealEntryResponse from ORM objects."""
    food_name = (
        mi.food_item.display_name
        if mi.food_item
        else (mi.predicted_label or "Unknown")
    )
    return MealEntryResponse(
        meal_item_id=mi.id,
        meal_id=meal.id,
        user_id=meal.user_id,
        food_name=food_name,
        predicted_label=mi.predicted_label or "",
        serving_quantity=mi.serving_quantity,
        serving_unit=mi.serving_unit,
        serving_g=mi.serving_g,
        calories=mi.calories,
        protein_g=mi.protein_g,
        carbs_g=mi.carbs_g,
        fat_g=mi.fat_g,
        confidence=mi.confidence,
        image_url=mi.image_path,
        meal_type=meal.name,
        meal_date=meal.meal_date,
        logged_at=mi.created_at,
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /meals  — log one food item
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/", response_model=MealEntryResponse, status_code=201)
def log_meal(payload: MealLogRequest, db: Session = Depends(get_db)):
    """
    **Log a single food item as a meal entry.**

    Steps:
    1. Validate serving_unit.
    2. Look up the food by `predicted_label` → food_items table (or fallback map).
    3. Convert `serving_quantity` + `serving_unit` → grams.
    4. Calculate `calories`, `protein_g`, `carbs_g`, `fat_g` for that portion.
    5. Save to `meals` (session) and `meal_items` (snapshot) — then return.

    ---
    **Example request:**
    ```json
    {
        "user_id": 1,
        "predicted_label": "pizza",
        "confidence": 0.91,
        "serving_quantity": 2,
        "serving_unit": "slice",
        "meal_type": "lunch",
        "image_url": "https://example.com/photo.jpg"
    }
    ```

    **Example response:**
    ```json
    {
        "meal_item_id": 5,
        "meal_id": 3,
        "user_id": 1,
        "food_name": "Pizza",
        "predicted_label": "pizza",
        "serving_quantity": 2.0,
        "serving_unit": "slice",
        "serving_g": 300.0,
        "calories": 798.0,
        "protein_g": 33.0,
        "carbs_g": 99.0,
        "fat_g": 30.0,
        "confidence": 0.91,
        "image_url": "https://example.com/photo.jpg",
        "meal_type": "lunch",
        "meal_date": "2026-06-14",
        "logged_at": "2026-06-14T10:32:00"
    }
    ```
    """
    # Validate serving_unit early to give a clear error before hitting the DB
    unit = payload.serving_unit.strip().lower()
    if unit not in ALL_VALID_UNITS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported serving_unit '{payload.serving_unit}'. "
                   f"Supported: {sorted(ALL_VALID_UNITS)}",
        )

    # Resolve food + compute macros
    try:
        nutrition = resolve_nutrition(
            payload.predicted_label,
            payload.serving_quantity,
            payload.serving_unit,
            db,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    meal_date = payload.meal_date or date_type.today()

    # Insert meal session
    meal = Meal(
        user_id=payload.user_id,
        name=payload.meal_type,
        meal_date=meal_date,
    )
    db.add(meal)
    db.flush()  # get meal.id before inserting meal_items

    # Insert nutrition snapshot (immune to future edits of food_items)
    meal_item = MealItem(
        meal_id=meal.id,
        food_item_id=nutrition["food_item_id"],
        serving_quantity=payload.serving_quantity,
        serving_unit=payload.serving_unit,
        serving_g=nutrition["serving_g"],
        calories=nutrition["calories"],
        protein_g=nutrition["protein_g"],
        carbs_g=nutrition["carbs_g"],
        fat_g=nutrition["fat_g"],
        predicted_label=payload.predicted_label,
        confidence=payload.confidence,
        image_path=payload.image_url,
    )
    db.add(meal_item)
    db.commit()
    db.refresh(meal_item)
    db.refresh(meal)

    return _to_entry_response(meal_item, meal)


# ─────────────────────────────────────────────────────────────────────────────
# GET /meals  — all logged entries for a user (paginated)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/", response_model=list[MealEntryResponse])
def get_meals(
    user_id: int = Query(..., description="Filter by user ID"),
    limit: int  = Query(20, ge=1, le=100, description="Max entries to return"),
    offset: int = Query(0,  ge=0,         description="Pagination offset"),
    db: Session = Depends(get_db),
):
    """
    **List all meal entries for a user, newest first.**

    ---
    **Example request:**
    ```
    GET /meals?user_id=1&limit=20&offset=0
    ```

    **Example response:** *(list of MealEntryResponse objects)*
    ```json
    [
        {
            "meal_item_id": 5,
            "meal_id": 3,
            "user_id": 1,
            "food_name": "Pizza",
            "predicted_label": "pizza",
            "serving_quantity": 2.0,
            "serving_unit": "slice",
            "serving_g": 300.0,
            "calories": 798.0,
            ...
        },
        ...
    ]
    ```

    Equivalent SQL:
    ```sql
    SELECT mi.*, m.user_id, m.name AS meal_type, m.meal_date
    FROM meal_items mi
    JOIN meals m ON m.id = mi.meal_id
    WHERE m.user_id = :user_id
    ORDER BY mi.created_at DESC
    LIMIT :limit OFFSET :offset;
    ```
    """
    rows = (
        db.query(MealItem)
        .join(Meal)
        .options(joinedload(MealItem.food_item), joinedload(MealItem.meal))
        .filter(Meal.user_id == user_id)
        .order_by(MealItem.created_at.desc())
        .limit(limit)
        .offset(offset)
        .all()
    )
    return [_to_entry_response(mi, mi.meal) for mi in rows]


# ─────────────────────────────────────────────────────────────────────────────
# GET /meals/today  — shortcut for today's entries
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/today", response_model=list[MealEntryResponse])
def get_meals_today(
    user_id: int = Query(..., description="Filter by user ID"),
    db: Session   = Depends(get_db),
):
    """
    **Return all food items logged by a user today.**

    Equivalent to `GET /meals?user_id=X` but pre-filtered to today's date.

    ---
    **Example request:**
    ```
    GET /meals/today?user_id=1
    ```

    Equivalent SQL:
    ```sql
    SELECT mi.*, m.user_id, m.name AS meal_type, m.meal_date
    FROM meal_items mi
    JOIN meals m ON m.id = mi.meal_id
    WHERE m.user_id = :user_id
      AND m.meal_date = CURRENT_DATE
    ORDER BY mi.created_at ASC;
    ```
    """
    today = date_type.today()
    rows = (
        db.query(MealItem)
        .join(Meal)
        .options(joinedload(MealItem.food_item), joinedload(MealItem.meal))
        .filter(Meal.user_id == user_id, Meal.meal_date == today)
        .order_by(MealItem.created_at.asc())
        .all()
    )
    return [_to_entry_response(mi, mi.meal) for mi in rows]


# ─────────────────────────────────────────────────────────────────────────────
# DELETE /meals/{meal_id}  — remove a meal entry
# ─────────────────────────────────────────────────────────────────────────────

@router.delete("/{meal_id}", status_code=204)
def delete_meal(meal_id: int, db: Session = Depends(get_db)):
    """
    **Delete a meal entry by its meal_id.**

    Deletes the `meals` row; the associated `meal_items` row is removed
    automatically via the ON DELETE CASCADE foreign key.

    ---
    **Example request:**
    ```
    DELETE /meals/3
    ```

    **Response:** `204 No Content` on success.

    **Error:** `404 Not Found` if meal_id does not exist.

    Equivalent SQL:
    ```sql
    DELETE FROM meals WHERE id = :meal_id;
    -- meal_items rows are cascade-deleted automatically
    ```
    """
    meal: Meal | None = db.query(Meal).filter(Meal.id == meal_id).first()
    if not meal:
        raise HTTPException(
            status_code=404,
            detail=f"Meal with id={meal_id} was not found.",
        )
    db.delete(meal)
    db.commit()
    # 204 No Content — return nothing


# ─────────────────────────────────────────────────────────────────────────────
# POST /meals/manual  — log a meal manually (no AI)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/manual", response_model=MealEntryResponse, status_code=201)
def log_manual_meal(payload: ManualMealRequest, db: Session = Depends(get_db)):
    """
    **Log a food item manually without AI prediction.**

    The user provides food name and nutrition values directly.
    Uses nutrition_source = "manual" and reuses the same meals/meal_items tables.
    """
    meal_date = payload.meal_date or date_type.today()

    # Convert serving to grams (basic)
    unit = payload.serving_unit.strip().lower()
    serving_g_map = {
        "g": payload.serving_quantity,
        "ml": payload.serving_quantity,
        "oz": payload.serving_quantity * 28.3495,
        "lb": payload.serving_quantity * 453.592,
        "cup": payload.serving_quantity * 240.0,
        "tbsp": payload.serving_quantity * 15.0,
        "tsp": payload.serving_quantity * 5.0,
    }
    serving_g = serving_g_map.get(unit, payload.serving_quantity)

    meal = Meal(
        user_id=payload.user_id,
        name=payload.meal_type,
        meal_date=meal_date,
    )
    db.add(meal)
    db.flush()

    meal_item = MealItem(
        meal_id=meal.id,
        food_item_id=None,
        serving_quantity=payload.serving_quantity,
        serving_unit=payload.serving_unit,
        serving_g=round(serving_g, 1),
        calories=payload.calories,
        protein_g=payload.protein_g,
        carbs_g=payload.carbs_g,
        fat_g=payload.fat_g,
        predicted_label=payload.food_name,  # store the name here for display
        confidence=None,
        image_path=None,
        nutrition_source="manual",
    )
    db.add(meal_item)
    db.commit()
    db.refresh(meal_item)
    db.refresh(meal)

    return MealEntryResponse(
        meal_item_id=meal_item.id,
        meal_id=meal.id,
        user_id=meal.user_id,
        food_name=payload.food_name,
        predicted_label=payload.food_name,
        serving_quantity=meal_item.serving_quantity,
        serving_unit=meal_item.serving_unit,
        serving_g=meal_item.serving_g,
        calories=meal_item.calories,
        protein_g=meal_item.protein_g,
        carbs_g=meal_item.carbs_g,
        fat_g=meal_item.fat_g,
        confidence=None,
        image_url=None,
        meal_type=meal.name,
        meal_date=meal.meal_date,
        logged_at=meal_item.created_at,
    )

"""
nutrition_utils.py
==================
Shared helpers used by both routers/meals.py and routers/analyze.py.

Centralising these here avoids duplicating logic across routers.

Functions:
    to_grams()         — convert any serving unit to grams
    resolve_nutrition() — look up macros for a label + serving (DB → map fallback)
"""

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import FoodItem
from app.nutrition_map import calculate_nutrition_for_serving, get_nutrition


# =============================================================================
# Serving-unit conversion table
# =============================================================================

# Fixed units: 1 unit = N grams
UNIT_TO_GRAMS: dict[str, float] = {
    "g":    1.0,
    "ml":   1.0,      # water density approximation
    "oz":   28.3495,
    "lb":   453.592,
    "cup":  240.0,
    "tbsp": 15.0,
    "tsp":  5.0,
}

# Relative units: 1 unit = food's own default_serving_g
RELATIVE_UNITS: set[str] = {"piece", "slice", "serving"}

# All valid units (used for validation)
ALL_VALID_UNITS: set[str] = set(UNIT_TO_GRAMS.keys()) | RELATIVE_UNITS


def to_grams(quantity: float, unit: str, default_serving_g: float) -> float:
    """
    Convert a user-supplied serving into grams.

    For relative units (piece / slice / serving) the result scales against the
    food's own default_serving_g — e.g. 2 slices of pizza at 150 g/slice = 300 g.

    For fixed units (g, oz, cup …) it applies the conversion factor directly.

    Args:
        quantity:         How much the user ate (e.g. 2).
        unit:             Unit string, case-insensitive (e.g. "slice", "oz", "g").
        default_serving_g: The food's standard single-portion size in grams.

    Returns:
        Total grams as a float, rounded to 1 decimal place.

    Raises:
        ValueError: If the unit is not recognised.

    Examples:
        to_grams(2, "slice", 150)  → 300.0
        to_grams(1, "cup",   150)  → 240.0
        to_grams(3, "oz",    150)  → 85.0
        to_grams(200, "g",   150)  → 200.0
    """
    u = unit.strip().lower()

    if u in RELATIVE_UNITS:
        return round(quantity * default_serving_g, 1)

    factor = UNIT_TO_GRAMS.get(u)
    if factor is None:
        raise ValueError(
            f"Unknown serving unit '{unit}'. "
            f"Supported units: {sorted(ALL_VALID_UNITS)}"
        )

    return round(quantity * factor, 1)


# =============================================================================
# Nutrition resolver
# =============================================================================

def resolve_nutrition(
    label: str,
    serving_quantity: float,
    serving_unit: str,
    db: Session,
) -> dict:
    """
    Look up a food by model label and compute macros for the given serving.

    Lookup order:
        1. food_items DB table  — seeded from seed_food_items.sql (preferred)
        2. nutrition_map.py dict — in-memory fallback, no extra DB query needed
        3. HTTP 404             — if unknown in both sources

    The returned dict is ready to be written directly into a MealItem row.

    Args:
        label:            Exact model label string, e.g. "baby_back_ribs".
        serving_quantity: How much the user ate (e.g. 2).
        serving_unit:     Unit string (e.g. "slice").  Must be in ALL_VALID_UNITS.
        db:               Active SQLAlchemy session.

    Returns:
        {
            "food_item_id": int | None,   # None when using map fallback
            "display_name": str,
            "serving_g":    float,
            "calories":     float,
            "protein_g":    float,
            "carbs_g":      float,
            "fat_g":        float,
            "source":       "db" | "map",
        }

    Raises:
        ValueError:        If serving_unit is invalid.
        HTTPException 404: If the label is unknown in both DB and nutrition map.

    Equivalent SQL (step 1):
        SELECT * FROM food_items WHERE model_label = :label LIMIT 1;
    """
    # ── Step 1: DB lookup ─────────────────────────────────────────────────────
    food: FoodItem | None = (
        db.query(FoodItem)
        .filter(FoodItem.model_label == label)
        .first()
    )

    if food:
        serving_g = to_grams(serving_quantity, serving_unit, food.default_serving_g)
        scale = serving_g / 100.0
        return {
            "food_item_id": food.id,
            "display_name": food.display_name,
            "serving_g":    serving_g,
            "calories":     round(food.calories_per_100g * scale, 2),
            "protein_g":    round(food.protein_per_100g  * scale, 2),
            "carbs_g":      round(food.carbs_per_100g    * scale, 2),
            "fat_g":        round(food.fat_per_100g      * scale, 2),
            "source":       "db",
        }

    # ── Step 2: in-memory nutrition_map fallback ──────────────────────────────
    info = get_nutrition(label)
    if not info:
        raise HTTPException(
            status_code=404,
            detail=(
                f"Food label '{label}' was not found in the food_items table "
                "or the built-in nutrition map. "
                "Make sure seed_food_items.sql is loaded, or add the item manually."
            ),
        )

    serving_g = to_grams(serving_quantity, serving_unit, info["serving_g"])
    result = calculate_nutrition_for_serving(label, serving_g)

    return {
        "food_item_id": None,
        "display_name": info["display_name"],
        "serving_g":    serving_g,
        "calories":     result["calories"],
        "protein_g":    result["protein_g"],
        "carbs_g":      result["carbs_g"],
        "fat_g":        result["fat_g"],
        "source":       "map",
    }

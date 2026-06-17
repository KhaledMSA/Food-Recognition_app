"""
schemas.py — All Pydantic request/response models.

Sections:
    1. Inference      (POST /predict)
    2. Meal Logging   (POST /meals, GET /meals, GET /meals/today, DELETE /meals/{meal_id})
    3. Nutrition      (GET /nutrition/daily-summary)
    4. Image Analysis (POST /analyze-image, POST /meals/from-analysis)
"""

from datetime import date, datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field


# =============================================================================
# 1. Inference  —  POST /predict
# =============================================================================

class PredictionItem(BaseModel):
    """One entry in the ranked top-5 list."""
    class_name: str = Field(..., description="Predicted food class label")
    confidence: float = Field(..., ge=0.0, le=1.0)


class PredictionResponse(BaseModel):
    """
    Response from POST /predict.

    Example:
        {
            "predicted_class": "pizza",
            "confidence": 0.91,
            "top_predictions": [
                {"class_name": "pizza",     "confidence": 0.91},
                {"class_name": "flatbread", "confidence": 0.05},
                ...
            ],
            "processing_time_ms": 312.4
        }
    """
    predicted_class: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    top_predictions: List[PredictionItem]
    processing_time_ms: float


# =============================================================================
# 2. Meal Logging
# =============================================================================

VALID_UNITS = {"g", "ml", "oz", "lb", "cup", "tbsp", "tsp", "piece", "slice", "serving"}

MealType = Literal["breakfast", "lunch", "dinner", "snack", "meal"]


class MealLogRequest(BaseModel):
    """
    Request body for POST /meals.

    One call = one food item logged.

    Example request:
        {
            "user_id": 1,
            "predicted_label": "pizza",
            "confidence": 0.91,
            "serving_quantity": 2,
            "serving_unit": "slice",
            "meal_type": "lunch",
            "image_url": "https://example.com/photo.jpg"
        }
    """
    user_id: int = Field(..., description="ID of the user logging the meal")
    predicted_label: str = Field(..., description="Model label returned by POST /predict")
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    serving_quantity: float = Field(100.0, gt=0, description="How much the user ate")
    serving_unit: str = Field("g", description="Supported: g, ml, oz, lb, cup, tbsp, tsp, piece, slice, serving")
    meal_type: MealType = Field("meal")
    meal_date: Optional[date] = Field(None, description="Defaults to today if omitted")
    image_url: Optional[str] = Field(None, description="Photo URL from the prediction step")


class MealEntryResponse(BaseModel):
    """
    A single logged meal entry.

    Example response:
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
            "image_url": "uploads/user1_1718323200_abc12345.jpg",
            "meal_type": "lunch",
            "meal_date": "2026-06-14",
            "logged_at": "2026-06-14T10:32:00"
        }
    """
    meal_item_id: int
    meal_id: int
    user_id: int
    food_name: str
    predicted_label: str
    serving_quantity: float
    serving_unit: str
    serving_g: float
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    confidence: Optional[float] = None
    image_url: Optional[str] = None
    meal_type: str
    meal_date: date
    logged_at: datetime


# =============================================================================
# 3. Nutrition Summary  —  GET /nutrition/daily-summary
# =============================================================================

class DailySummaryResponse(BaseModel):
    """
    Daily nutrition totals aggregated live from meal_items.

    Example response:
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
    """
    user_id: int
    date: date
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    entry_count: int = Field(..., description="Number of individual food items logged today")
    calorie_goal: Optional[int] = Field(None, description="User's daily calorie target")
    calories_remaining: Optional[float] = Field(None, description="calorie_goal − total_calories")


# =============================================================================
# 4. Image Analysis  —  POST /analyze-image  +  POST /meals/from-analysis
# =============================================================================

class AnalysisPreview(BaseModel):
    """
    Response from POST /analyze-image.

    Contains everything the Flutter app needs to show a confirmation screen
    before the user saves the meal. No data is written to the DB at this point.

    The client should:
        1. Show the photo, food name, and macro breakdown.
        2. Let the user adjust serving_quantity / serving_unit.
        3. Let the user pick a different label from top_predictions if the model was wrong.
        4. POST the confirmed data to /meals/from-analysis to save.

    Example response:
        {
            "image_url": "uploads/user1_1718323200_abc12345.jpg",
            "predicted_label": "pizza",
            "confidence": 0.91,
            "low_confidence_warning": false,
            "top_predictions": [
                {"class_name": "pizza",     "confidence": 0.91},
                {"class_name": "flatbread", "confidence": 0.05}
            ],
            "processing_time_ms": 312.4,
            "food_name": "Pizza",
            "serving_quantity": 2.0,
            "serving_unit": "slice",
            "serving_g": 300.0,
            "calories": 798.0,
            "protein_g": 33.0,
            "carbs_g": 99.0,
            "fat_g": 30.0,
            "nutrition_source": "db"
        }
    """
    # Saved photo
    image_url: str = Field(..., description="Relative path served at GET /uploads/filename")

    # Prediction
    predicted_label: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    low_confidence_warning: bool = Field(
        ..., description="True if confidence < 0.40 — model may have misidentified the food"
    )
    top_predictions: List[PredictionItem] = Field(
        ..., description="Top-5 alternatives the user can pick if the top-1 is wrong"
    )
    processing_time_ms: float

    # Nutrition estimate
    food_name: str
    serving_quantity: float
    serving_unit: str
    serving_g: float    = Field(..., description="serving_quantity converted to grams")
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    nutrition_source: str = Field(..., description="'db' = food_items table  |  'map' = built-in fallback")


class MealFromAnalysisRequest(BaseModel):
    """
    Request body for POST /meals/from-analysis.

    Sent after the user reviews the AnalysisPreview and taps Confirm.
    The backend re-resolves nutrition and saves to DB.

    Example (user accepts prediction as-is):
        {
            "user_id": 1,
            "predicted_label": "pizza",
            "confirmed_label": null,
            "confidence": 0.91,
            "serving_quantity": 2,
            "serving_unit": "slice",
            "meal_type": "lunch",
            "image_url": "uploads/user1_1718323200_abc12345.jpg"
        }

    Example (user corrects the label):
        {
            "user_id": 1,
            "predicted_label": "pizza",
            "confirmed_label": "flatbread",
            "confidence": 0.91,
            "serving_quantity": 1,
            "serving_unit": "piece",
            "meal_type": "lunch",
            "image_url": "uploads/user1_1718323200_abc12345.jpg"
        }
    """
    user_id: int
    predicted_label: str = Field(..., description="Original model label — stored for audit trail")
    confirmed_label: Optional[str] = Field(
        None,
        description="Label override from top_predictions. Nutrition is resolved from this if set.",
    )
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    serving_quantity: float = Field(100.0, gt=0)
    serving_unit: str = Field("g")
    meal_type: MealType = Field("meal")
    meal_date: Optional[date] = Field(None, description="Defaults to today")
    image_url: Optional[str] = Field(None, description="image_url from the AnalysisPreview response")

"""
schemas.py — All Pydantic request/response models.

Sections:
    1. Inference      (POST /predict)
    2. Meal Logging   (POST /meals, GET /meals, GET /meals/today, DELETE /meals/{meal_id})
    3. Nutrition      (GET /nutrition/daily-summary)
    4. Image Analysis (POST /analyze-image, POST /meals/from-analysis)
    5. Auth           (POST /auth/signup, POST /auth/login)
    6. Users          (GET /users/me, PATCH /users/me)
    7. Manual Meals   (POST /meals/manual)
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
    user_id: int = Field(..., description="ID of the user logging the meal")
    predicted_label: str = Field(..., description="Model label returned by POST /predict")
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    serving_quantity: float = Field(100.0, gt=0, description="How much the user ate")
    serving_unit: str = Field("g", description="Supported: g, ml, oz, lb, cup, tbsp, tsp, piece, slice, serving")
    meal_type: MealType = Field("meal")
    meal_date: Optional[date] = Field(None, description="Defaults to today if omitted")
    image_url: Optional[str] = Field(None, description="Photo URL from the prediction step")


class MealEntryResponse(BaseModel):
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
    user_id: int
    date: date
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    entry_count: int = Field(..., description="Number of individual food items logged today")
    calorie_goal: Optional[int] = Field(None, description="User's daily calorie target")
    calories_remaining: Optional[float] = Field(None, description="calorie_goal − total_calories")
    protein_goal: Optional[int] = Field(None, description="User's daily protein target (g)")
    carbs_goal: Optional[int] = Field(None, description="User's daily carbs target (g)")
    fat_goal: Optional[int] = Field(None, description="User's daily fat target (g)")


# =============================================================================
# 4. Image Analysis  —  POST /analyze-image  +  POST /meals/from-analysis
# =============================================================================

class AnalysisPreview(BaseModel):
    # Saved photo
    image_url: str = Field(..., description="Relative path served at GET /uploads/<filename>")

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


# =============================================================================
# 5. Auth  —  POST /auth/signup  +  POST /auth/login
# =============================================================================

class SignupRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="Plain-text password (will be hashed)")
    name: Optional[str] = Field(None, description="Display name")


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    """Returned after signup or login."""
    token: str
    user_id: int
    onboarding_completed: bool


# =============================================================================
# 6. Users  —  GET /users/me  +  PATCH /users/me
# =============================================================================

class UserResponse(BaseModel):
    id: int
    email: str
    name: Optional[str] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    weekly_effort: Optional[str] = None
    daily_calorie_goal: int
    daily_protein_goal: int
    daily_carbs_goal: int
    daily_fat_goal: int
    onboarding_completed: bool


class OnboardingRequest(BaseModel):
    """Sent after the user completes the onboarding questions."""
    name: str
    goal: Literal["lose_weight", "maintain_weight", "gain_weight", "build_muscle"]
    gender: Literal["male", "female", "other"]
    weight_kg: float = Field(..., gt=0)
    height_cm: float = Field(..., gt=0)
    weekly_effort: Literal["low", "moderate", "high"]


class UpdateProfileRequest(BaseModel):
    """Optional fields for PATCH /users/me."""
    name: Optional[str] = None
    goal: Optional[str] = None
    gender: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    weekly_effort: Optional[str] = None


# =============================================================================
# 7. Manual Meals  —  POST /meals/manual
# =============================================================================

class ManualMealRequest(BaseModel):
    """Log a meal manually without AI prediction."""
    user_id: int
    food_name: str = Field(..., description="Name of the food item")
    serving_quantity: float = Field(1.0, gt=0)
    serving_unit: str = Field("g")
    calories: float = Field(..., ge=0)
    protein_g: float = Field(0.0, ge=0)
    carbs_g: float = Field(0.0, ge=0)
    fat_g: float = Field(0.0, ge=0)
    meal_type: MealType = Field("meal")
    meal_date: Optional[date] = Field(None, description="Defaults to today")

"""
models.py — SQLAlchemy ORM models.

Maps to the 4 core tables defined in database/schema.sql:
    users, food_items, meals, meal_items

daily_nutrition_summary is intentionally excluded (Phase 2 optimization).
"""

from datetime import date, datetime

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


# ---------------------------------------------------------------------------
# users
# ---------------------------------------------------------------------------
class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(120))
    age: Mapped[int | None] = mapped_column(Integer)
    gender: Mapped[str | None] = mapped_column(String(10))
    height_cm: Mapped[float | None] = mapped_column(Float)
    weight_kg: Mapped[float | None] = mapped_column(Float)
    daily_calorie_goal: Mapped[int] = mapped_column(Integer, default=2000)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # Relationships
    meals: Mapped[list["Meal"]] = relationship("Meal", back_populates="user")


# ---------------------------------------------------------------------------
# food_items
# ---------------------------------------------------------------------------
class FoodItem(Base):
    __tablename__ = "food_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # Must match the exact string the ML model returns (e.g. "baby_back_ribs")
    model_label: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    display_name: Mapped[str] = mapped_column(String(150), nullable=False)

    # Macros per 100 g
    calories_per_100g: Mapped[float] = mapped_column(Float, nullable=False)
    protein_per_100g: Mapped[float] = mapped_column(Float, default=0.0)
    carbs_per_100g: Mapped[float] = mapped_column(Float, default=0.0)
    fat_per_100g: Mapped[float] = mapped_column(Float, default=0.0)
    fiber_per_100g: Mapped[float] = mapped_column(Float, default=0.0)
    sugar_per_100g: Mapped[float] = mapped_column(Float, default=0.0)
    sodium_per_100g: Mapped[float] = mapped_column(Float, default=0.0)  # mg per 100 g

    # Default serving
    default_serving_g: Mapped[float] = mapped_column(Float, default=100.0)
    serving_unit: Mapped[str] = mapped_column(String(30), default="g")

    # Metadata
    data_source: Mapped[str] = mapped_column(String(50), default="manual")
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # Relationships
    meal_items: Mapped[list["MealItem"]] = relationship("MealItem", back_populates="food_item")


# ---------------------------------------------------------------------------
# meals
# ---------------------------------------------------------------------------
class Meal(Base):
    __tablename__ = "meals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(50), default="meal")
    meal_date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="meals")
    items: Mapped[list["MealItem"]] = relationship(
        "MealItem", back_populates="meal", cascade="all, delete-orphan"
    )


# ---------------------------------------------------------------------------
# meal_items
# ---------------------------------------------------------------------------
class MealItem(Base):
    __tablename__ = "meal_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    meal_id: Mapped[int] = mapped_column(Integer, ForeignKey("meals.id", ondelete="CASCADE"), nullable=False)

    # Nullable so we can still log items even if not found in food_items table
    food_item_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("food_items.id"), nullable=True)

    # Portion consumed — original user-facing values preserved alongside grams
    serving_quantity: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    serving_unit: Mapped[str] = mapped_column(String(30), nullable=False, default="g")
    serving_g: Mapped[float] = mapped_column(Float, nullable=False, default=100.0)

    # Pre-computed nutrition for this exact portion
    # Stored at insert time — immune to future food_items edits
    calories: Mapped[float] = mapped_column(Float, nullable=False)
    protein_g: Mapped[float] = mapped_column(Float, default=0.0)
    carbs_g: Mapped[float] = mapped_column(Float, default=0.0)
    fat_g: Mapped[float] = mapped_column(Float, default=0.0)

    # ML prediction context for auditing
    predicted_label: Mapped[str | None] = mapped_column(String(100))
    confidence: Mapped[float | None] = mapped_column(Float)
    image_path: Mapped[str | None] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # Relationships
    meal: Mapped["Meal"] = relationship("Meal", back_populates="items")
    food_item: Mapped["FoodItem | None"] = relationship("FoodItem", back_populates="meal_items")

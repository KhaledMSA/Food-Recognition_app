"""
routers/analyze.py
==================
Layer 4: Image Upload → Prediction → Nutrition Preview → Meal Save

Two-step flow:

    Step 1  POST /analyze-image
            ├── Save image to  uploads/
            ├── Run EfficientNetB3 prediction
            ├── Resolve nutrition for predicted label + serving
            └── Return AnalysisPreview  (NO database write yet)

    Step 2  POST /meals/from-analysis
            ├── Accept the preview data + any user adjustments
            ├── Re-resolve nutrition (in case serving or label changed)
            └── Save to  meals  +  meal_items  → return MealEntryResponse

Error handling:
    400  Invalid image format or empty file
    400  File exceeds size limit
    400  Invalid serving_unit
    404  Unknown food label (not in DB or nutrition map)
    413  File too large
    422  PIL cannot decode the image bytes
    503  ML model not loaded yet
"""

import time
import uuid
from datetime import date as date_type
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.db import get_db
from app.model_loader import model_manager
from app.models import Meal, MealItem
from app.nutrition_utils import ALL_VALID_UNITS, resolve_nutrition
from app.schemas import (
    AnalysisPreview,
    MealEntryResponse,
    MealFromAnalysisRequest,
    PredictionItem,
)
from app.utils import get_top_predictions, preprocess_image

router = APIRouter(tags=["Layer 4 — Image Analysis"])


# =============================================================================
# Configuration
# =============================================================================

# Predictions below this threshold still succeed but include a warning flag.
CONFIDENCE_THRESHOLD: float = 0.40

# Hard limit on uploaded file size.
MAX_FILE_SIZE_MB: int = 10
MAX_FILE_SIZE_BYTES: int = MAX_FILE_SIZE_MB * 1024 * 1024

# Accepted MIME types.
ALLOWED_MIME_TYPES: set[str] = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/bmp",
    "image/gif",
}

# Valid file extensions for naming saved files.
ALLOWED_EXTENSIONS: set[str] = {"jpg", "jpeg", "png", "webp", "bmp", "gif"}

# Uploads directory — resolved relative to this file so it always lands in
# backend/uploads/ regardless of the working directory.
UPLOADS_DIR: Path = Path(__file__).resolve().parent.parent.parent / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


# =============================================================================
# Internal helpers
# =============================================================================

def _save_image(file: UploadFile, user_id: int, image_bytes: bytes) -> str:
    """
    Write image bytes to backend/uploads/ with a unique filename.

    Filename format:
        user{user_id}_{unix_timestamp}_{8-char uuid}.{ext}
        e.g.  user1_1718323200_a3f9bc12.jpg

    Returns:
        Relative URL path served at GET /uploads/<filename>
        e.g.  "uploads/user1_1718323200_a3f9bc12.jpg"
    """
    original_name = file.filename or "photo.jpg"
    raw_ext = original_name.rsplit(".", 1)[-1].lower() if "." in original_name else "jpg"
    ext = raw_ext if raw_ext in ALLOWED_EXTENSIONS else "jpg"

    filename = f"user{user_id}_{int(time.time())}_{uuid.uuid4().hex[:8]}.{ext}"
    (UPLOADS_DIR / filename).write_bytes(image_bytes)

    return f"uploads/{filename}"


def _build_entry_response(mi: MealItem, meal: Meal) -> MealEntryResponse:
    """Assemble a flat MealEntryResponse from ORM objects."""
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


# =============================================================================
# Step 1  —  POST /analyze-image
# =============================================================================

@router.post(
    "/analyze-image",
    response_model=AnalysisPreview,
    summary="Analyze a food image",
    tags=["Layer 4 — Image Analysis"],
)
async def analyze_image(
    user_id: int = Form(..., description="ID of the user uploading the image"),
    file: UploadFile = File(..., description="Food photo (JPEG, PNG, WEBP, BMP, GIF)"),
    serving_quantity: float = Form(
        100.0,
        gt=0,
        description="How much the user plans to eat (default 100 g)",
    ),
    serving_unit: str = Form(
        "g",
        description="Unit for serving_quantity. Supported: g, ml, oz, lb, cup, tbsp, tsp, piece, slice, serving",
    ),
    db: Session = Depends(get_db),
):
    """
    **Step 1 of the image-to-meal flow.**

    Uploads a food photo, runs the EfficientNetB3 model, estimates nutrition
    for the predicted food + serving, and returns a preview.

    **Nothing is saved to the database at this point.**
    The user reviews the preview, optionally adjusts the label or serving,
    then calls `POST /meals/from-analysis` to confirm and save.

    ---
    **Request** (multipart form):
    ```
    user_id         = 1
    file            = <image file>
    serving_quantity = 2          (optional, default 100)
    serving_unit    = "slice"     (optional, default "g")
    ```

    **Response:**
    ```json
    {
        "image_url": "uploads/user1_1718323200_a3f9bc12.jpg",
        "predicted_label": "pizza",
        "confidence": 0.91,
        "low_confidence_warning": false,
        "top_predictions": [
            {"class_name": "pizza",     "confidence": 0.91},
            {"class_name": "flatbread", "confidence": 0.05},
            {"class_name": "focaccia",  "confidence": 0.02},
            {"class_name": "nachos",    "confidence": 0.01},
            {"class_name": "hot_dog",   "confidence": 0.01}
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
    ```

    **Error responses:**
    - `400` Invalid file type or empty file
    - `400` Invalid serving_unit
    - `404` Predicted label not found in nutrition data
    - `413` File exceeds 10 MB limit
    - `422` Image bytes cannot be decoded (corrupted file)
    - `503` ML model not yet loaded
    """

    # ── Guard: model must be loaded ───────────────────────────────────────────
    if model_manager.model is None or model_manager.class_names is None:
        raise HTTPException(
            status_code=503,
            detail="The ML model is not loaded yet. Wait a moment and retry.",
        )

    # ── Validate MIME type ────────────────────────────────────────────────────
    if not file.content_type or file.content_type.lower() not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid file type '{file.content_type}'. "
                f"Allowed types: {sorted(ALLOWED_MIME_TYPES)}"
            ),
        )

    # ── Validate serving unit ─────────────────────────────────────────────────
    if serving_unit.strip().lower() not in ALL_VALID_UNITS:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid serving_unit '{serving_unit}'. "
                f"Supported: {sorted(ALL_VALID_UNITS)}"
            ),
        )

    # ── Read file bytes ───────────────────────────────────────────────────────
    image_bytes = await file.read()

    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    if len(image_bytes) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large ({len(image_bytes) // 1024 // 1024} MB). "
                   f"Maximum allowed size is {MAX_FILE_SIZE_MB} MB.",
        )

    # ── Save image to uploads/ ────────────────────────────────────────────────
    image_url = _save_image(file, user_id, image_bytes)

    # ── Preprocess + run model ────────────────────────────────────────────────
    try:
        t_start = time.perf_counter()
        img_tensor = preprocess_image(image_bytes)
        raw_preds = model_manager.model.predict(img_tensor, verbose=0)
        processing_time_ms = round((time.perf_counter() - t_start) * 1000, 2)
    except ValueError as exc:
        # preprocess_image raises ValueError for corrupt/unreadable files
        raise HTTPException(
            status_code=422,
            detail=f"Could not decode image: {exc}",
        ) from exc

    top5 = get_top_predictions(raw_preds, model_manager.class_names, top_k=5)
    best = top5[0]
    predicted_label = best["class_name"]
    confidence = best["confidence"]

    # ── Resolve nutrition ─────────────────────────────────────────────────────
    try:
        nutrition = resolve_nutrition(predicted_label, serving_quantity, serving_unit, db)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    # HTTPException 404 from resolve_nutrition propagates as-is

    # ── Build preview response (no DB write) ──────────────────────────────────
    return AnalysisPreview(
        image_url=image_url,
        predicted_label=predicted_label,
        confidence=confidence,
        low_confidence_warning=confidence < CONFIDENCE_THRESHOLD,
        top_predictions=[
            PredictionItem(class_name=p["class_name"], confidence=p["confidence"])
            for p in top5
        ],
        processing_time_ms=processing_time_ms,
        food_name=nutrition["display_name"],
        serving_quantity=serving_quantity,
        serving_unit=serving_unit,
        serving_g=nutrition["serving_g"],
        calories=nutrition["calories"],
        protein_g=nutrition["protein_g"],
        carbs_g=nutrition["carbs_g"],
        fat_g=nutrition["fat_g"],
        nutrition_source=nutrition["source"],
    )


# =============================================================================
# Step 2  —  POST /meals/from-analysis
# =============================================================================

@router.post(
    "/meals/from-analysis",
    response_model=MealEntryResponse,
    status_code=201,
    summary="Confirm analysis and save meal",
    tags=["Layer 4 — Image Analysis"],
)
def confirm_and_save(
    payload: MealFromAnalysisRequest,
    db: Session = Depends(get_db),
):
    """
    **Step 2 of the image-to-meal flow.**

    Accepts the user-confirmed prediction + serving details, re-resolves
    nutrition, and saves the meal to the database.

    If the user corrected the label (because the model was wrong), pass the
    corrected label as `confirmed_label`. Nutrition will be resolved using
    that instead. The original `predicted_label` is still stored for audit.

    ---
    **Request body (JSON):**
    ```json
    {
        "user_id": 1,
        "predicted_label": "pizza",
        "confirmed_label": null,
        "confidence": 0.91,
        "serving_quantity": 2,
        "serving_unit": "slice",
        "meal_type": "lunch",
        "meal_date": "2026-06-14",
        "image_url": "uploads/user1_1718323200_a3f9bc12.jpg"
    }
    ```

    **Response:** Same `MealEntryResponse` as `POST /meals`.
    ```json
    {
        "meal_item_id": 7,
        "meal_id": 5,
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
        "image_url": "uploads/user1_1718323200_a3f9bc12.jpg",
        "meal_type": "lunch",
        "meal_date": "2026-06-14",
        "logged_at": "2026-06-14T10:45:00"
    }
    ```

    **Error responses:**
    - `400` Invalid serving_unit
    - `404` Label not found in nutrition data
    """

    # Use confirmed_label if user overrode the prediction, else use original
    label_to_use = (payload.confirmed_label or payload.predicted_label).strip().lower()

    # ── Validate serving unit ─────────────────────────────────────────────────
    if payload.serving_unit.strip().lower() not in ALL_VALID_UNITS:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid serving_unit '{payload.serving_unit}'. "
                f"Supported: {sorted(ALL_VALID_UNITS)}"
            ),
        )

    # ── Re-resolve nutrition from scratch ─────────────────────────────────────
    # Always recalculate — the user may have changed the label or serving.
    try:
        nutrition = resolve_nutrition(
            label_to_use,
            payload.serving_quantity,
            payload.serving_unit,
            db,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    meal_date = payload.meal_date or date_type.today()

    # ── Insert meal session ───────────────────────────────────────────────────
    meal = Meal(
        user_id=payload.user_id,
        name=payload.meal_type,
        meal_date=meal_date,
    )
    db.add(meal)
    db.flush()  # populate meal.id before inserting meal_items

    # ── Insert nutrition snapshot ─────────────────────────────────────────────
    # Values are stored at insert time — immune to future food_items edits.
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
        # Store original model prediction for audit trail
        predicted_label=payload.predicted_label,
        confidence=payload.confidence,
        image_path=payload.image_url,
    )
    db.add(meal_item)
    db.commit()
    db.refresh(meal_item)
    db.refresh(meal)

    return _build_entry_response(meal_item, meal)

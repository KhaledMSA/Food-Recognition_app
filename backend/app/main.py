"""
FastAPI Application Entry Point
================================
Food Recognition & Nutrition Analysis API

Layer overview:
    1. POST /predict              → image → predicted label + confidence
    2. POST /meals                → predicted label → nutrition saved to DB
    3. GET  /meals                → history, paginated
       GET  /meals/today          → today's entries
       GET  /nutrition/daily-summary → daily macro totals
       DELETE /meals/{meal_id}    → remove entry
    4. POST /analyze-image        → upload + predict + nutrition preview (no DB write)
       POST /meals/from-analysis  → confirm preview → save to DB
"""

import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.db import Base, engine
from app.model_loader import model_manager
from app.routers import meals, nutrition
from app.routers.analyze import UPLOADS_DIR, router as analyze_router
from app.routers.auth import router as auth_router
from app.routers.users import router as users_router
from app.schemas import PredictionItem, PredictionResponse
from app.utils import get_top_predictions, preprocess_image


# ---------------------------------------------------------------------------
# Lifespan: DB tables + ML model + uploads directory
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Create all DB tables (skip if they already exist).
    #    In production, switch to Alembic migrations.
    Base.metadata.create_all(bind=engine)
    print("[startup] Database tables ready.")

    # 2. Ensure uploads directory exists
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    print(f"[startup] Uploads directory: {UPLOADS_DIR}")

    # 3. Load EfficientNetB3 model + class labels
    try:
        model_manager.load()
        print(f"[startup] Model loaded. Classes: {len(model_manager.class_names)}")
    except Exception as exc:
        raise RuntimeError(f"Failed to load model at startup: {exc}") from exc

    yield
    # Nothing to clean up on shutdown.


# ---------------------------------------------------------------------------
# App instance
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Food Recognition & Nutrition API",
    description=(
        "End-to-end food recognition and nutrition tracking.\n\n"
        "**Layer 1 — Inference**\n"
        "- `POST /predict` — upload a photo → predicted food label + top-5\n\n"
        "**Layer 2 — Nutrition** (internal mapping, no endpoint)\n\n"
        "**Layer 3 — Meal Logging**\n"
        "- `POST /meals` — log one food item → nutrition saved to DB\n"
        "- `GET /meals` — paginated history\n"
        "- `GET /meals/today` — today's entries\n"
        "- `GET /nutrition/daily-summary` — daily macro totals\n"
        "- `DELETE /meals/{meal_id}` — remove a meal entry\n\n"
        "**Layer 4 — Image to Meal Flow**\n"
        "- `POST /analyze-image` — upload + predict + nutrition preview (no DB write)\n"
        "- `POST /meals/from-analysis` — confirm preview → save to DB"
    ),
    version="4.0.0",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS — allow the Flutter app (and Swagger UI in the browser)
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],    # tighten to your app's domain in production
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Static files — serve uploaded images at GET /uploads/<filename>
# ---------------------------------------------------------------------------
app.mount(
    "/uploads",
    StaticFiles(directory=str(UPLOADS_DIR)),
    name="uploads",
)

# ---------------------------------------------------------------------------
# Routers
# ---------------------------------------------------------------------------
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(meals.router)
app.include_router(nutrition.router)
app.include_router(analyze_router)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/", tags=["Health"])
async def health_check():
    """API health check — confirms service, model, and DB are all operational."""
    return {
        "status": "healthy",
        "version": "4.0.0",
        "model_loaded": model_manager.model is not None,
        "num_classes": len(model_manager.class_names) if model_manager.class_names else 0,
        "uploads_dir": str(UPLOADS_DIR),
    }


# ---------------------------------------------------------------------------
# Layer 1: POST /predict  (kept here for direct, no-save inference)
# ---------------------------------------------------------------------------

@app.post("/predict", response_model=PredictionResponse, tags=["Layer 1 — Inference"])
async def predict(file: UploadFile = File(...)):
    """
    **Direct prediction — no image saved, no meal logged.**

    Upload a food photo → get the predicted label, confidence, and top-5.
    Use this when you only need the label (e.g. for testing).

    For the full upload → preview → save flow, use `POST /analyze-image` instead.
    """
    if model_manager.model is None or model_manager.class_names is None:
        raise HTTPException(
            status_code=503,
            detail="Model is not loaded. The service may still be starting up.",
        )

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{file.content_type}'. Please upload an image.",
        )

    try:
        image_bytes = await file.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        t_start = time.perf_counter()
        img_tensor = preprocess_image(image_bytes)
        predictions = model_manager.model.predict(img_tensor, verbose=0)
        elapsed_ms = round((time.perf_counter() - t_start) * 1000, 2)

        top5 = get_top_predictions(predictions, model_manager.class_names, top_k=5)
        best = top5[0]

        return PredictionResponse(
            predicted_class=best["class_name"],
            confidence=best["confidence"],
            top_predictions=[
                PredictionItem(class_name=p["class_name"], confidence=p["confidence"])
                for p in top5
            ],
            processing_time_ms=elapsed_ms,
        )

    except HTTPException:
        raise
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc

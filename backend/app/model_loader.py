"""
Model & class-name loader for the food classifier.
Paths are resolved relative to this file so the service works from any
working directory.
"""

import json
from pathlib import Path

from tensorflow import keras


class ModelManager:
    """Singleton-style container that holds the Keras model and class labels."""

    def __init__(self):
        self.model = None
        self.class_names: list[str] | None = None

        # Resolve paths relative to this file's location so they work
        # regardless of from where uvicorn is launched.
        _here = Path(__file__).resolve().parent  # backend/app/
        _backend = _here.parent                  # backend/

        # ---------- Adjust these paths to match your actual file layout ----------
        self.model_path   = _backend / "models" / "BestModel.keras"
        self.classes_path = _backend / "models" / "class_names.json"
        # -------------------------------------------------------------------------

    def load(self) -> None:
        """Load the Keras model and class-name list from disk."""
        if not self.model_path.exists():
            raise FileNotFoundError(
                f"Model file not found at: {self.model_path}\n"
                "Place BestModel.keras in backend/models/ or update model_path."
            )
        if not self.classes_path.exists():
            raise FileNotFoundError(
                f"Class-names file not found at: {self.classes_path}\n"
                "Place class_names.json in backend/models/ or update classes_path."
            )

        print(f"[startup] Loading model from: {self.model_path}")
        self.model = keras.models.load_model(str(self.model_path))
        print("[startup] Model loaded successfully.")

        print(f"[startup] Loading class names from: {self.classes_path}")
        with open(self.classes_path, "r", encoding="utf-8") as f:
            self.class_names = json.load(f)
        print(f"[startup] Loaded {len(self.class_names)} class labels.")


# Single shared instance imported by main.py
model_manager = ModelManager()

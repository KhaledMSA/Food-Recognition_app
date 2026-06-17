"""
Image preprocessing utilities for the EfficientNetB3 food classifier.
Input resolution: 300×300 (the training resolution for EfficientNetB3).
"""

import numpy as np
from io import BytesIO

from PIL import Image
from tensorflow.keras.applications.efficientnet import preprocess_input


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Decode raw image bytes and prepare a batch-ready tensor for MobileNetV2.

    Steps:
        1. Decode bytes → PIL Image
        2. Convert to RGB (handles RGBA, grayscale, palette images, …)
        3. Resize to 224×224 using high-quality Lanczos resampling
        4. Cast to float32
        5. Add batch dimension → shape (1, 224, 224, 3)
        6. Apply MobileNetV2-specific preprocessing (scales pixels to [-1, 1])

    Args:
        image_bytes: Raw bytes of the uploaded image file.

    Returns:
        numpy array of shape (1, 300, 300, 3), dtype float32.

    Raises:
        ValueError: If the bytes cannot be decoded as a valid image.
    """
    try:
        img = Image.open(BytesIO(image_bytes))

        # Normalise colour mode to plain RGB
        if img.mode != "RGB":
            img = img.convert("RGB")

        # Resize to the model's expected spatial resolution
        img = img.resize((300, 300), Image.LANCZOS)

        # NumPy conversion + batch dimension
        img_array = np.array(img, dtype=np.float32)
        img_array = np.expand_dims(img_array, axis=0)  # (1, 300, 300, 3)

        # EfficientNet preprocessing: maps [0, 255] → [-1, 1]
        img_array = preprocess_input(img_array)

        return img_array

    except Exception as exc:
        raise ValueError(f"Failed to preprocess image: {exc}") from exc


def get_top_predictions(
    predictions: np.ndarray,
    class_names: list[str],
    top_k: int = 5,
) -> list[dict]:
    """
    Extract the top-k class predictions from raw model output.

    Args:
        predictions: Raw softmax output from model.predict(), shape (1, num_classes).
        class_names: Ordered list of class label strings (must match model output size).
        top_k: Number of top predictions to return.

    Returns:
        List of dicts [{"class_name": str, "confidence": float}, …],
        sorted by confidence descending.
    """
    scores = predictions[0]  # shape (num_classes,)
    top_k = min(top_k, len(scores))

    top_indices = np.argsort(scores)[::-1][:top_k]

    return [
        {"class_name": class_names[int(idx)], "confidence": float(scores[idx])}
        for idx in top_indices
    ]

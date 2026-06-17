# Food-104 FastAPI Backend

A FastAPI backend for predicting food classes from images using MobileNetV2 model.

## 🚀 Quick Start

### Option 1: Test Only (No Model Required)
```bash
python test_server.py
```
Visit: http://localhost:8000/docs

### Option 2: Full Setup with Model
```bash
python setup.py      # Install dependencies (one-time)
python run_server.py # Start server
```

## 📚 API Endpoints

### Health Check
```bash
GET http://localhost:8000/
```

### Predict Food Class
```bash
POST http://localhost:8000/predict
# Upload image file in "file" field
```

**Response:**
```json
{
  "predicted_class": "pizza",
  "confidence": 0.91,
  "top_predictions": [
    {"class_name": "pizza", "confidence": 0.91},
    {"class_name": "pasta", "confidence": 0.05},
    {"class_name": "burger", "confidence": 0.02},
    {"class_name": "bread", "confidence": 0.01},
    {"class_name": "salad", "confidence": 0.005}
  ]
}
```

## 🔧 Manual Setup (Alternative)

```bash
# 1. Create virtual environment
py -3.12 -m venv venv

# 2. Activate it
venv\Scripts\activate.bat

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run server
python -m uvicorn app.main:app --reload
```

## 🌐 API Documentation

Once running:
- **Interactive Docs**: http://localhost:8000/docs (Try it out here!)
- **Alternative Docs**: http://localhost:8000/redoc

## 🧪 Testing

### With cURL
```bash
curl http://localhost:8000/
curl -X POST -F "file=@pizza.jpg" http://localhost:8000/predict
```

### With Python
```python
import requests
response = requests.post(
    "http://localhost:8000/predict",
    files={"file": open("pizza.jpg", "rb")}
)
print(response.json())
```

## 📁 Project Structure

```
backend/
├── setup.py              # Install dependencies
├── run_server.py         # Start server
├── test_server.py        # Test without model
├── requirements.txt      # Python dependencies
├── app/
│   ├── main.py          # FastAPI endpoints
│   ├── model_loader.py  # Model loading
│   ├── schemas.py       # Response schemas
│   └── utils.py         # Image preprocessing
├── data/
│   ├── class_names_101.json  # 101 food categories
│   └── nutrition.json
└── README.md            # This file
```

## ⚙️ System Requirements

- Python 3.12+
- 4GB+ RAM
- 500MB+ free disk space

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 8000 in use | `python -m uvicorn app.main:app --port 8001` |
| Model not found | Check `test102/Models/food101_mobilenetv2_final.keras` exists |
| Dependency issues | Run `python setup.py` |
| Reset venv | `rmdir /s venv && py -3.12 -m venv venv && python setup.py` |

## 📝 Features

- ✅ Health check endpoint
- ✅ Image upload and prediction
- ✅ Top 5 predictions with confidence scores
- ✅ Auto image resizing (224x224)
- ✅ RGB conversion (handles RGBA, grayscale)
- ✅ Interactive Swagger UI documentation
- ✅ Error handling for invalid files

## 🔄 Changes Made

- TensorFlow 2.14.0 → 2.16.1 (Python 3.12 compatible)
- Fixed model paths to project root `Models/` directory
- Created `class_names_101.json` from existing class list
- Added convenient setup and run scripts

## 📖 Model Information

- **Architecture**: BestModel
- **Dataset**: Compiled Food-101 and Fruity (104 food classes)
- **Input Size**: 224x224 RGB images
- **Validation Accuracy**: ~83%
- **Preprocessing**: BestModel standard normalization

---

**Ready to go!** Run `python test_server.py` to start testing!

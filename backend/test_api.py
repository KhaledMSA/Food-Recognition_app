import os
import requests
import json

BASE_URL = "http://127.0.0.1:8000"
IMAGE_PATH = "pizza.png"

def run_tests():
    print("=" * 60)
    print("STARTING API AND MODEL INTEGRATION TESTS")
    print("=" * 60)

    # Check image file exists
    if not os.path.exists(IMAGE_PATH):
        print(f"[-] Error: {IMAGE_PATH} not found. Please place a sample image in the backend directory.")
        return

    # 1. Health Check
    print("\n[1/7] Testing Health Check endpoint...")
    try:
        r = requests.get(f"{BASE_URL}/")
        r.raise_for_status()
        data = r.json()
        print(f"[+] Health check response: {json.dumps(data, indent=2)}")
        assert data["status"] == "healthy", "Server should be healthy"
        assert data["model_loaded"] is True, "Model should be loaded"
    except Exception as e:
        print(f"[-] Health Check failed: {e}")
        return

    # 2. Prediction API (POST /predict)
    print("\n[2/7] Testing direct model prediction (POST /predict)...")
    try:
        with open(IMAGE_PATH, "rb") as f:
            files = {"file": (IMAGE_PATH, f, "image/png")}
            r = requests.post(f"{BASE_URL}/predict", files=files)
        r.raise_for_status()
        data = r.json()
        print(f"[+] Prediction response: {json.dumps(data, indent=2)}")
        print(f"[+] Predicted Class: {data['predicted_class']} (Confidence: {data['confidence']:.2f})")
    except Exception as e:
        print(f"[-] Prediction failed: {e}")
        return

    # 3. Image Analysis API (POST /analyze-image)
    print("\n[3/7] Testing Layer 4 Image Analysis (POST /analyze-image)...")
    preview_data = None
    try:
        with open(IMAGE_PATH, "rb") as f:
            files = {"file": (IMAGE_PATH, f, "image/png")}
            form_data = {
                "user_id": 1,
                "serving_quantity": 2.0,
                "serving_unit": "slice"
            }
            r = requests.post(f"{BASE_URL}/analyze-image", files=files, data=form_data)
        r.raise_for_status()
        preview_data = r.json()
        print(f"[+] Analysis preview response: {json.dumps(preview_data, indent=2)}")
        print(f"[+] Estimated portion calories: {preview_data['calories']} kcal")
    except Exception as e:
        print(f"[-] Image Analysis failed: {e}")
        return

    # 4. Confirm and Save Meal (POST /meals/from-analysis)
    print("\n[4/7] Testing Meal Save from Analysis (POST /meals/from-analysis)...")
    meal_entry = None
    try:
        payload = {
            "user_id": 1,
            "predicted_label": preview_data["predicted_label"],
            "confirmed_label": None,
            "confidence": preview_data["confidence"],
            "serving_quantity": preview_data["serving_quantity"],
            "serving_unit": preview_data["serving_unit"],
            "meal_type": "lunch",
            "image_url": preview_data["image_url"]
        }
        r = requests.post(f"{BASE_URL}/meals/from-analysis", json=payload)
        r.raise_for_status()
        meal_entry = r.json()
        print(f"[+] Meal entry logged: {json.dumps(meal_entry, indent=2)}")
        print(f"[+] Meal logged successfully! Meal Item ID: {meal_entry['meal_item_id']}, Meal ID: {meal_entry['meal_id']}")
    except Exception as e:
        print(f"[-] Confirm and Save Meal failed: {e}")
        return

    # 5. Fetch Today's Meals (GET /meals/today)
    print("\n[5/7] Testing Fetch Today's Meals (GET /meals/today)...")
    try:
        r = requests.get(f"{BASE_URL}/meals/today", params={"user_id": 1})
        r.raise_for_status()
        today_meals = r.json()
        print(f"[+] Today's meals list (found {len(today_meals)} item(s)):")
        for item in today_meals:
            print(f"    - Meal ID {item['meal_id']}: {item['food_name']} ({item['serving_quantity']} {item['serving_unit']}) -> {item['calories']} kcal")
    except Exception as e:
        print(f"[-] Fetch Today's Meals failed: {e}")
        return

    # 6. Fetch Daily Summary (GET /nutrition/daily-summary)
    print("\n[6/7] Testing Fetch Daily Summary (GET /nutrition/daily-summary)...")
    try:
        r = requests.get(f"{BASE_URL}/nutrition/daily-summary", params={"user_id": 1})
        r.raise_for_status()
        summary = r.json()
        print(f"[+] Daily Summary: {json.dumps(summary, indent=2)}")
        print(f"[+] Total Calories Today: {summary['total_calories']} / {summary.get('calorie_goal', 2000)} kcal")
    except Exception as e:
        print(f"[-] Fetch Daily Summary failed: {e}")
        return

    # 7. Clean up by deleting the logged meal (DELETE /meals/{meal_id})
    print("\n[7/7] Testing Delete Meal (DELETE /meals/{meal_id}) to clean up database...")
    try:
        meal_id = meal_entry["meal_id"]
        r = requests.delete(f"{BASE_URL}/meals/{meal_id}")
        r.raise_for_status()
        print(f"[+] Meal ID {meal_id} deleted successfully (Status: {r.status_code})")
    except Exception as e:
        print(f"[-] Delete Meal failed: {e}")
        return

    print("\n" + "=" * 60)
    print("ALL TESTS COMPLETED SUCCESSFULLY! ENTIRE FLOW IS FUNCTIONAL")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()

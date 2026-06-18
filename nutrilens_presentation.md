---
marp: true
theme: default
paginate: true
size: 16:9
---

<style>
  :root {
    --primary-green: #2E7D32;
    --accent-green: #43A047;
    --light-green: #E8F5E9;
    --dark-bg: #1B5E20;
    --text-dark: #212121;
    --text-light: #F5F5F5;
  }
  section {
    background-color: #F7F8FA;
    color: var(--text-dark);
    font-family: 'Roboto', 'Inter', sans-serif;
  }
  h1, h2, h3 {
    color: var(--primary-green);
    margin-top: 0;
  }
  .box {
    background: white;
    padding: 1.5rem;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    border: 1px solid #eaeaea;
    margin-bottom: 1rem;
  }
  .accent-box {
    background: var(--light-green);
    padding: 1.5rem;
    border-radius: 12px;
    border-left: 6px solid var(--accent-green);
    margin-bottom: 1rem;
  }
  .tag {
    background: var(--primary-green);
    color: white;
    padding: 0.3rem 0.6rem;
    border-radius: 6px;
    font-size: 0.85em;
    font-weight: bold;
    display: inline-block;
    margin: 0.2rem;
  }
  .flow {
    display: flex;
    justify-content: space-around;
    align-items: center;
    gap: 1.5rem;
    text-align: center;
    margin-top: 2rem;
  }
  .arch-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    align-items: start;
  }
  .screenshot-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.5rem;
    text-align: center;
    margin-top: 1rem;
  }
  .screenshot-grid img {
    border-radius: 16px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.12);
    max-height: 420px;
    object-fit: contain;
  }
  .entity {
    font-family: 'Courier New', monospace;
    background: #e0e0e0;
    padding: 2px 6px;
    border-radius: 4px;
    color: #d32f2f;
    font-weight: bold;
  }
  .footer {
    position: absolute;
    bottom: 20px;
    left: 40px;
    font-size: 0.6em;
    color: #888;
  }
</style>

<!-- _backgroundColor: #1B5E20 -->
<!-- _color: #F5F5F5 -->

# NutriLens
### AI-Powered Nutrition Tracking
<br>
<br>
**Graduation Project Presentation**
**Presented By:** [Your Name / Team]
**Date:** [Date]

---

## 1. Problem Statement

<div class="arch-grid">
<div class="box">

**The Challenge**
- Traditional calorie counting is tedious and inaccurate.
- Users struggle to estimate portion sizes and identify macronutrients.
- Manual data entry leads to high app abandonment rates.

</div>
<div class="accent-box">

**The Impact**
- Lack of consistent tracking limits users from achieving their health goals.
- Nutritional illiteracy remains a barrier to healthy eating.

</div>
</div>

---

## 2. Project Objectives

<div class="box">

**1. Automate Food Logging**
Use image recognition to instantly identify foods and extract nutritional data.

**2. Personalize Nutrition**
Calculate unique macronutrient targets based on individual physical traits.

**3. Provide a Seamless Experience**
Deliver a smooth, cross-platform mobile interface that encourages daily use.

**4. Ensure Reliable Architecture**
Build a fast, local-first robust backend capable of serving AI predictions efficiently.

</div>

---

## 3. Existing Solutions

<div class="arch-grid">
<div class="box">

**Current Market Options**
- MyFitnessPal
- LoseIt!
- FatSecret

</div>
<div class="accent-box">

**Their Limitations**
- Heavy reliance on manual text search.
- Barcode scanning only works for packaged foods.
- Paywalled premium features for basic macro tracking.
- Cluttered UI/UX.

</div>
</div>

**NutriLens Edge:** Focuses on instant visual recognition with a clean, modern interface, removing friction from logging fresh meals.

---

## 4. Target Users

<div class="flow">

<div class="box">
  <h3>🏋️ Fitness Enthusiasts</h3>
  <p>Looking to accurately track protein and macros for muscle gain.</p>
</div>

<div class="box">
  <h3>🥗 Health Conscious</h3>
  <p>Seeking weight loss or maintenance through simple calorie awareness.</p>
</div>

<div class="box">
  <h3>📱 Everyday Users</h3>
  <p>Want a frictionless, visually appealing way to log their daily meals.</p>
</div>

</div>

---

## 5. Rubric Coverage

Our project strongly targets the core evaluation criteria:

<div class="arch-grid">
<div>

- <span class="tag">AI / Data Science (30 pts)</span>
  - Integration of a Keras/TensorFlow model using the Food-101 dataset.
- <span class="tag">Code Quality & Arch (25 pts)</span>
  - Clean client-server separation (Flutter + FastAPI) with local SQLite.

</div>
<div>

- <span class="tag">Originality & Problem-Solving (25 pts)</span>
  - Bridging complex machine learning with personalized mobile UX.
- <span class="tag">UI / UX (20 pts)</span>
  - Modern, responsive, and visually appealing Flutter interface.

</div>
</div>

---

## 6. System Overview

A highly cohesive Client-Server architecture bridging Mobile UX and AI.

<div class="flow">
  <div class="box">
    <strong>Mobile App</strong><br>
    <span class="tag">Flutter</span><br>
    Camera, Auth, Dashboard
  </div>
  ➡
  <div class="accent-box">
    <strong>REST API</strong><br>
    <span class="tag">FastAPI</span><br>
    Authentication, User logic
  </div>
  ➡
  <div class="box">
    <strong>AI Engine & DB</strong><br>
    <span class="tag">TensorFlow</span> | <span class="tag">SQLite</span><br>
    Inference & Data Persistence
  </div>
</div>

---

## 7. Tech Stack

<div class="arch-grid">
<div class="box">

**Frontend (Mobile App)**
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Storage:** SharedPreferences

</div>
<div class="box">

**Backend (API & AI)**
- **Framework:** FastAPI (Python)
- **Database:** SQLite
- **ORM:** SQLAlchemy
- **Machine Learning:** TensorFlow / Keras

</div>
</div>

---

## 8. Software Architecture

<div class="accent-box">

**Client-Server Model**
- The **Flutter Client** handles all UI rendering, state management, and device camera interaction.
- The **FastAPI Server** operates as a centralized hub, processing HTTP requests, executing business logic, and querying the database.
- **Model Isolation:** The heavy Keras model is loaded once into server memory on startup, preventing mobile device battery drain or lag.

</div>

---

## 9. Backend API Design

<div class="box">

**Authentication & Users**
- `POST /auth/signup` - Creates user (bcrypt hashing).
- `POST /auth/login` - Returns session token.
- `GET /users/me` - Retrieves profile.
- `POST /auth/onboarding` - Calculates physical macros.

**Meals & AI**
- `POST /analyze-image` - AI prediction endpoint.
- `POST /meals/from-analysis` - Saves scanned meal.
- `POST /meals/manual` - Saves diary entry.
- `GET /meals/today` - Retrieves daily log.

</div>

---

## 10. Database / UML Design

<div class="arch-grid">
<div>

**Entity Relationship Overview**
- <span class="entity">users</span>
  - Stores credentials, physical traits, and calculated macro goals.
- <span class="entity">meals</span>
  - Links to a user, storing date and meal type (Breakfast, Lunch, etc.).
- <span class="entity">meal_items</span>
  - Links to a meal. Contains specific food name, serving size, and macro snapshot.
- <span class="entity">food_items</span>
  - Base nutritional reference dictionary.

</div>
<div class="accent-box">

**Design Philosophy**
- Normalized SQLite relational structure.
- "Manual" vs "Scanned" meals share the same structure for unified history querying.

</div>
</div>

---

## 11. AI / Data Science Component

<div class="box">

**The Prediction Engine**
- **Framework:** TensorFlow / Keras
- **Dataset:** Food-101 (104 output classes).
- **Model File:** `BestModel.keras`
- **Mapping:** `class_names.json` links model output nodes to human-readable food names.

**Implementation Details**
- Image preprocessing matches the exact input dimensions used during model training.
- Outputs a softmax probability array to determine the top predicted class and confidence score.

</div>

---

## 12. Model Prediction Pipeline

<div class="flow">
  <div class="box">1. Image Capture<br><small>(Flutter Camera)</small></div>
  ➡
  <div class="box">2. Multipart Upload<br><small>(FastAPI Route)</small></div>
  ➡
  <div class="accent-box">3. Preprocessing &<br>Inference <small>(Keras)</small></div>
  ➡
  <div class="box">4. Nutrition Lookup<br><small>(SQLite / Dict)</small></div>
  ➡
  <div class="box">5. JSON Response<br><small>(Top 5 Predictions)</small></div>
</div>

---

## 13. Nutrition Calculation & Personalization

<div class="arch-grid">
<div class="accent-box">

**The Onboarding Formula**
- **Inputs:** Age, Gender, Weight (kg), Height (cm), Activity Level.
- **BMR:** Calculated using standard formulas.
- **TDEE:** BMR scaled by weekly effort multiplier.
- **Goal Adjustment:** Caloric deficit for weight loss, surplus for gain.

</div>
<div class="box">

**Macro Splits**
- Automatically distributed based on the goal (e.g., higher protein for muscle building).
- Dynamic tracking: The dashboard compares real-time consumption against these calculated limits.

</div>
</div>

---

## 14. Main Application Features

<div class="box">

✔️ **Secure Authentication:** Signup, login, and logout.
✔️ **Personalized Onboarding:** First-time physical profiling.
✔️ **Dynamic Dashboard:** Live tracking of daily calories and macros.
✔️ **AI Food Scanning:** Real-time predictions via Keras.
✔️ **Manual Diary:** Logging standard meals without photos.
✔️ **Meal History:** Reviewing past consumption.
✔️ **Profile Management:** Viewing and editing goals.

</div>

---

## 15. UI / UX Screens

Our design language focuses on a modern, clean, "NutriLens Green" theme.

<div class="screenshot-grid">

![Landing](screenshots/landing.png)
**Landing / Auth**

![Onboarding](screenshots/onboarding.png)
**Onboarding**

![Dashboard](screenshots/dashboard.png)
**Dashboard**

</div>

*(Note: Replace placeholders with actual Android device screenshots)*

---

## 16. End-to-End Demo Flow

<div class="screenshot-grid">

![Scan](screenshots/scan.png)
**1. Scan Food**

![Result](screenshots/prediction.png)
**2. AI Prediction**

![History](screenshots/history.png)
**3. Meal Saved**

</div>

*(Note: Replace placeholders with actual Android device screenshots)*

---

## 17. Testing and Results

<div class="arch-grid">
<div class="box">

**Development Testing**
- Full integration tested locally (Windows Desktop target for Flutter).
- FastAPI backend verified via Swagger UI and cURL.

</div>
<div class="accent-box">

**Mobile Deployment**
- **Android APK Built Successfully.**
- Verified end-to-end functionality on a physical Android device.
- Model latency is low due to efficient FastAPI backend execution.

</div>
</div>

---

## 18. Problems Encountered

<div class="box">

**1. Model Loading Overhead**
- *Problem:* Loading the Keras model per request caused massive timeouts.
- *Solution:* Instantiated the model globally during FastAPI startup, ensuring rapid sub-second inference.

**2. Image Data Handling**
- *Problem:* Syncing multipart form-data image uploads between Flutter and Python reliably.
- *Solution:* Standardized the HTTP multipart structure and MIME types.

**3. State Management**
- *Problem:* Keeping the dashboard UI updated immediately after a scan.
- *Solution:* Implemented Flutter `Provider` to trigger localized UI rebuilds upon meal saving.

</div>

---

## 19. Limitations and Future Work

<div class="arch-grid">
<div class="accent-box">

**Current Limitations**
- Requires network connection to the backend for AI inference.
- Model is limited to the 104 specific classes trained from Food-101.
- Only identifies single-item foods clearly.

</div>
<div class="box">

**Future Work**
- Add Barcode Scanning via public food databases.
- Multi-object detection to recognize entire plates of food.
- Implement data visualization graphs for weekly/monthly trends.

</div>
</div>

---

<!-- _backgroundColor: #1B5E20 -->
<!-- _color: #F5F5F5 -->

# Conclusion

**NutriLens** successfully bridges the gap between complex machine learning and accessible health tracking. 

By combining a fast **Python/Keras AI backend** with a beautiful, personalized **Flutter frontend**, we have created a functional, scalable solution to dietary tracking.

<br>
<br>
<br>

### Thank You!
**Questions?**

"""
nutrition_map.py
================
Single-source-of-truth nutrition lookup for all 104 model classes.

Usage
-----
    from app.nutrition_map import get_nutrition, NUTRITION_MAP

    info = get_nutrition("baby_back_ribs")
    print(info["display_name"])   # "Baby Back Ribs"
    print(info["calories"])       # 275  (per 100 g)

Structure of each entry
-----------------------
    "model_label": {
        "display_name":   str,    # human-readable label for the UI
        "calories":       float,  # kcal per 100 g
        "protein":        float,  # g per 100 g
        "carbs":          float,  # g per 100 g
        "fat":            float,  # g per 100 g
        "fiber":          float,  # g per 100 g
        "sugar":          float,  # g per 100 g
        "sodium":         float,  # mg per 100 g
        "serving_g":      float,  # default portion size in grams
        "serving_unit":   str,    # g | piece | slice | cup | ml
        "notes":          str | None,
    }

Label-mapping strategy
-----------------------
Some Food-101 labels are compound or ambiguous.  The approach used here:

  1. DIRECT MAPPING  — exact label → specific food  (most entries below).
  2. CANONICAL FORM  — labels like "spaghetti_bolognese" map to a
     representative bolognese average.
  3. BEST-MATCH APPROXIMATION — labels like "chocolate_cake" or
     "baby_back_ribs" map to a carefully chosen average value with a
     note explaining the choice.
  4. ALIAS TABLE      — the LABEL_ALIASES dict at the bottom maps any
     label variants or spelling differences to canonical labels.

If get_nutrition() returns None, the caller should prompt the user to
enter the item manually or flag it for human review.
"""

from __future__ import annotations


# ---------------------------------------------------------------------------
# Main mapping  (all 104 labels)
# ---------------------------------------------------------------------------

NUTRITION_MAP: dict[str, dict] = {

    # ── Appetisers & small bites ─────────────────────────────────────────────
    "bruschetta": {
        "display_name": "Bruschetta", "calories": 195, "protein": 6.0,
        "carbs": 28.0, "fat": 7.0, "fiber": 2.0, "sugar": 3.0, "sodium": 350,
        "serving_g": 80, "serving_unit": "slice", "notes": None,
    },
    "deviled_eggs": {
        "display_name": "Deviled Eggs", "calories": 185, "protein": 8.5,
        "carbs": 3.0, "fat": 15.5, "fiber": 0.0, "sugar": 1.0, "sodium": 330,
        "serving_g": 60, "serving_unit": "piece", "notes": "2-egg half default",
    },
    "edamame": {
        "display_name": "Edamame", "calories": 122, "protein": 11.0,
        "carbs": 10.0, "fat": 5.0, "fiber": 5.0, "sugar": 2.0, "sodium": 63,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "escargots": {
        "display_name": "Escargots", "calories": 90, "protein": 16.0,
        "carbs": 2.0, "fat": 2.0, "fiber": 0.0, "sugar": 0.0, "sodium": 200,
        "serving_g": 80, "serving_unit": "g", "notes": "without butter sauce",
    },
    "falafel": {
        "display_name": "Falafel", "calories": 333, "protein": 13.3,
        "carbs": 32.0, "fat": 17.8, "fiber": 5.4, "sugar": 1.6, "sodium": 294,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "guacamole": {
        "display_name": "Guacamole", "calories": 160, "protein": 1.9,
        "carbs": 8.5, "fat": 14.7, "fiber": 6.7, "sugar": 0.4, "sodium": 211,
        "serving_g": 60, "serving_unit": "g", "notes": None,
    },
    "hummus": {
        "display_name": "Hummus", "calories": 166, "protein": 7.9,
        "carbs": 14.3, "fat": 9.6, "fiber": 6.0, "sugar": 0.5, "sodium": 379,
        "serving_g": 60, "serving_unit": "g", "notes": None,
    },
    "nachos": {
        "display_name": "Nachos", "calories": 300, "protein": 7.5,
        "carbs": 34.0, "fat": 15.0, "fiber": 2.5, "sugar": 2.0, "sodium": 420,
        "serving_g": 100, "serving_unit": "g", "notes": "with cheese",
    },
    "samosa": {
        "display_name": "Samosa", "calories": 262, "protein": 5.7,
        "carbs": 32.0, "fat": 13.0, "fiber": 3.0, "sugar": 2.0, "sodium": 430,
        "serving_g": 80, "serving_unit": "piece", "notes": None,
    },
    "spring_rolls": {
        "display_name": "Spring Rolls", "calories": 200, "protein": 5.5,
        "carbs": 27.0, "fat": 8.5, "fiber": 1.5, "sugar": 1.5, "sodium": 320,
        "serving_g": 80, "serving_unit": "piece", "notes": "fried",
    },
    "gyoza": {
        "display_name": "Gyoza (Dumplings)", "calories": 200, "protein": 9.0,
        "carbs": 22.0, "fat": 8.0, "fiber": 1.5, "sugar": 1.0, "sodium": 400,
        "serving_g": 70, "serving_unit": "piece", "notes": None,
    },
    "dumplings": {
        "display_name": "Dumplings", "calories": 195, "protein": 8.5,
        "carbs": 22.5, "fat": 7.5, "fiber": 1.5, "sugar": 1.0, "sodium": 390,
        "serving_g": 80, "serving_unit": "piece", "notes": None,
    },
    "takoyaki": {
        "display_name": "Takoyaki", "calories": 194, "protein": 7.3,
        "carbs": 22.5, "fat": 8.4, "fiber": 0.8, "sugar": 3.2, "sodium": 505,
        "serving_g": 80, "serving_unit": "g", "notes": None,
    },

    # ── Salads ───────────────────────────────────────────────────────────────
    "caesar_salad": {
        "display_name": "Caesar Salad", "calories": 100, "protein": 5.0,
        "carbs": 4.5, "fat": 7.5, "fiber": 1.0, "sugar": 1.0, "sodium": 380,
        "serving_g": 150, "serving_unit": "g", "notes": "with dressing",
    },
    "caprese_salad": {
        "display_name": "Caprese Salad", "calories": 160, "protein": 8.5,
        "carbs": 4.0, "fat": 12.5, "fiber": 0.5, "sugar": 3.0, "sodium": 300,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "greek_salad": {
        "display_name": "Greek Salad", "calories": 95, "protein": 3.5,
        "carbs": 6.5, "fat": 6.5, "fiber": 1.5, "sugar": 4.0, "sodium": 420,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "beet_salad": {
        "display_name": "Beet Salad", "calories": 100, "protein": 2.5,
        "carbs": 12.5, "fat": 5.0, "fiber": 2.5, "sugar": 9.0, "sodium": 250,
        "serving_g": 120, "serving_unit": "g", "notes": None,
    },
    "seaweed_salad": {
        "display_name": "Seaweed Salad", "calories": 70, "protein": 1.5,
        "carbs": 11.0, "fat": 2.5, "fiber": 1.5, "sugar": 6.0, "sodium": 870,
        "serving_g": 80, "serving_unit": "g", "notes": None,
    },

    # ── Soups ────────────────────────────────────────────────────────────────
    "clam_chowder": {
        "display_name": "Clam Chowder", "calories": 100, "protein": 5.5,
        "carbs": 10.5, "fat": 4.0, "fiber": 0.5, "sugar": 2.0, "sodium": 440,
        "serving_g": 240, "serving_unit": "ml", "notes": "1 cup",
    },
    "french_onion_soup": {
        "display_name": "French Onion Soup", "calories": 73, "protein": 3.5,
        "carbs": 8.0, "fat": 3.0, "fiber": 0.5, "sugar": 4.0, "sodium": 680,
        "serving_g": 250, "serving_unit": "ml", "notes": None,
    },
    "hot_and_sour_soup": {
        "display_name": "Hot and Sour Soup", "calories": 50, "protein": 4.5,
        "carbs": 5.0, "fat": 1.5, "fiber": 0.5, "sugar": 1.0, "sodium": 550,
        "serving_g": 240, "serving_unit": "ml", "notes": None,
    },
    "miso_soup": {
        "display_name": "Miso Soup", "calories": 40, "protein": 3.0,
        "carbs": 5.5, "fat": 1.0, "fiber": 0.5, "sugar": 1.5, "sodium": 630,
        "serving_g": 240, "serving_unit": "ml", "notes": None,
    },
    "lobster_bisque": {
        "display_name": "Lobster Bisque", "calories": 130, "protein": 7.0,
        "carbs": 9.0, "fat": 7.5, "fiber": 0.0, "sugar": 4.0, "sodium": 480,
        "serving_g": 240, "serving_unit": "ml", "notes": None,
    },
    "pho": {
        "display_name": "Pho", "calories": 70, "protein": 5.5,
        "carbs": 9.5, "fat": 1.5, "fiber": 0.3, "sugar": 1.0, "sodium": 430,
        "serving_g": 400, "serving_unit": "ml", "notes": "1 bowl",
    },

    # ── Sandwiches & burgers ─────────────────────────────────────────────────
    "hamburger": {
        "display_name": "Hamburger", "calories": 290, "protein": 15.0,
        "carbs": 24.0, "fat": 14.0, "fiber": 1.5, "sugar": 5.0, "sodium": 480,
        "serving_g": 150, "serving_unit": "g", "notes": "1 patty + bun",
    },
    "hot_dog": {
        "display_name": "Hot Dog", "calories": 290, "protein": 11.0,
        "carbs": 23.0, "fat": 17.5, "fiber": 1.0, "sugar": 5.0, "sodium": 610,
        "serving_g": 130, "serving_unit": "g", "notes": "with bun",
    },
    "club_sandwich": {
        "display_name": "Club Sandwich", "calories": 290, "protein": 17.5,
        "carbs": 26.0, "fat": 12.0, "fiber": 1.5, "sugar": 3.0, "sodium": 680,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "grilled_cheese_sandwich": {
        "display_name": "Grilled Cheese Sandwich", "calories": 350, "protein": 14.0,
        "carbs": 30.0, "fat": 19.0, "fiber": 1.0, "sugar": 3.0, "sodium": 590,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "pulled_pork_sandwich": {
        "display_name": "Pulled Pork Sandwich", "calories": 280, "protein": 16.0,
        "carbs": 27.0, "fat": 11.5, "fiber": 1.0, "sugar": 8.0, "sodium": 520,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "lobster_roll_sandwich": {
        "display_name": "Lobster Roll Sandwich", "calories": 280, "protein": 16.5,
        "carbs": 24.0, "fat": 12.0, "fiber": 1.0, "sugar": 3.5, "sodium": 580,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "croque_madame": {
        "display_name": "Croque Madame", "calories": 330, "protein": 18.5,
        "carbs": 23.0, "fat": 18.0, "fiber": 1.0, "sugar": 4.0, "sodium": 760,
        "serving_g": 180, "serving_unit": "g", "notes": None,
    },

    # ── Pizza & Italian ───────────────────────────────────────────────────────
    "pizza": {
        "display_name": "Pizza", "calories": 266, "protein": 11.0,
        "carbs": 33.0, "fat": 10.0, "fiber": 2.0, "sugar": 3.5, "sodium": 598,
        "serving_g": 150, "serving_unit": "g", "notes": "1–2 slices, cheese pizza average",
    },
    "lasagna": {
        "display_name": "Lasagna", "calories": 135, "protein": 9.5,
        "carbs": 13.0, "fat": 5.0, "fiber": 1.0, "sugar": 3.0, "sodium": 325,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "spaghetti_bolognese": {
        "display_name": "Spaghetti Bolognese", "calories": 150, "protein": 9.0,
        "carbs": 18.0, "fat": 4.5, "fiber": 1.5, "sugar": 2.5, "sodium": 350,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "spaghetti_carbonara": {
        "display_name": "Spaghetti Carbonara", "calories": 250, "protein": 12.0,
        "carbs": 28.0, "fat": 10.0, "fiber": 1.0, "sugar": 1.5, "sodium": 380,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "ravioli": {
        "display_name": "Ravioli", "calories": 190, "protein": 9.5,
        "carbs": 25.0, "fat": 6.0, "fiber": 1.5, "sugar": 2.0, "sodium": 310,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "gnocchi": {
        "display_name": "Gnocchi", "calories": 130, "protein": 3.5,
        "carbs": 27.0, "fat": 1.0, "fiber": 1.5, "sugar": 1.5, "sodium": 220,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "risotto": {
        "display_name": "Risotto", "calories": 165, "protein": 4.5,
        "carbs": 25.0, "fat": 5.5, "fiber": 0.5, "sugar": 1.0, "sodium": 310,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "macaroni_and_cheese": {
        "display_name": "Macaroni and Cheese", "calories": 170, "protein": 7.5,
        "carbs": 22.5, "fat": 6.0, "fiber": 1.0, "sugar": 4.0, "sodium": 420,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },

    # ── Asian dishes ─────────────────────────────────────────────────────────
    "sushi": {
        "display_name": "Sushi", "calories": 150, "protein": 6.5,
        "carbs": 26.0, "fat": 2.5, "fiber": 0.5, "sugar": 4.0, "sodium": 430,
        "serving_g": 150, "serving_unit": "g", "notes": "3–4 pieces (nigiri/maki mix)",
    },
    "sashimi": {
        "display_name": "Sashimi", "calories": 130, "protein": 22.0,
        "carbs": 0.0, "fat": 4.5, "fiber": 0.0, "sugar": 0.0, "sodium": 250,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "ramen": {
        "display_name": "Ramen", "calories": 105, "protein": 7.5,
        "carbs": 14.0, "fat": 2.5, "fiber": 0.5, "sugar": 1.5, "sodium": 680,
        "serving_g": 400, "serving_unit": "ml", "notes": "1 bowl",
    },
    "pad_thai": {
        "display_name": "Pad Thai", "calories": 170, "protein": 9.0,
        "carbs": 22.0, "fat": 5.5, "fiber": 1.5, "sugar": 4.0, "sodium": 480,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "fried_rice": {
        "display_name": "Fried Rice", "calories": 160, "protein": 5.5,
        "carbs": 24.0, "fat": 5.0, "fiber": 1.0, "sugar": 2.0, "sodium": 430,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "bibimbap": {
        "display_name": "Bibimbap", "calories": 120, "protein": 7.0,
        "carbs": 17.0, "fat": 3.0, "fiber": 2.0, "sugar": 2.0, "sodium": 380,
        "serving_g": 350, "serving_unit": "g", "notes": "1 bowl",
    },
    "chicken_curry": {
        "display_name": "Chicken Curry", "calories": 150, "protein": 13.0,
        "carbs": 8.0, "fat": 7.5, "fiber": 1.5, "sugar": 3.5, "sodium": 430,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "peking_duck": {
        "display_name": "Peking Duck", "calories": 340, "protein": 19.0,
        "carbs": 10.0, "fat": 25.5, "fiber": 0.0, "sugar": 5.0, "sodium": 460,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "paella": {
        "display_name": "Paella", "calories": 175, "protein": 11.5,
        "carbs": 21.5, "fat": 5.0, "fiber": 1.0, "sugar": 1.5, "sodium": 380,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },

    # ── Mexican ───────────────────────────────────────────────────────────────
    "tacos": {
        "display_name": "Tacos", "calories": 218, "protein": 11.0,
        "carbs": 20.0, "fat": 10.0, "fiber": 2.0, "sugar": 2.0, "sodium": 390,
        "serving_g": 150, "serving_unit": "g", "notes": "2 soft tacos",
    },
    "breakfast_burrito": {
        "display_name": "Breakfast Burrito", "calories": 230, "protein": 11.5,
        "carbs": 22.5, "fat": 11.0, "fiber": 2.0, "sugar": 2.5, "sodium": 530,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "chicken_quesadilla": {
        "display_name": "Chicken Quesadilla", "calories": 270, "protein": 17.5,
        "carbs": 22.0, "fat": 12.5, "fiber": 1.5, "sugar": 2.0, "sodium": 590,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "huevos_rancheros": {
        "display_name": "Huevos Rancheros", "calories": 180, "protein": 10.5,
        "carbs": 14.0, "fat": 9.0, "fiber": 2.5, "sugar": 3.5, "sodium": 420,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },

    # ── Meat & seafood mains ─────────────────────────────────────────────────
    "steak": {
        "display_name": "Steak", "calories": 250, "protein": 26.0,
        "carbs": 0.0, "fat": 16.5, "fiber": 0.0, "sugar": 0.0, "sodium": 150,
        "serving_g": 200, "serving_unit": "g", "notes": "sirloin, cooked",
    },
    "filet_mignon": {
        "display_name": "Filet Mignon", "calories": 267, "protein": 26.0,
        "carbs": 0.0, "fat": 17.5, "fiber": 0.0, "sugar": 0.0, "sodium": 130,
        "serving_g": 170, "serving_unit": "g", "notes": None,
    },
    "prime_rib": {
        "display_name": "Prime Rib", "calories": 340, "protein": 24.0,
        "carbs": 0.0, "fat": 27.0, "fiber": 0.0, "sugar": 0.0, "sodium": 160,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "baby_back_ribs": {
        "display_name": "Baby Back Ribs", "calories": 275, "protein": 20.5,
        "carbs": 5.0, "fat": 19.5, "fiber": 0.0, "sugar": 3.0, "sodium": 380,
        "serving_g": 200, "serving_unit": "g",
        "notes": "Average of sauced BBQ ribs. Actual calories vary widely by sauce & cut.",
    },
    "pork_chop": {
        "display_name": "Pork Chop", "calories": 230, "protein": 25.5,
        "carbs": 0.0, "fat": 14.0, "fiber": 0.0, "sugar": 0.0, "sodium": 160,
        "serving_g": 180, "serving_unit": "g", "notes": None,
    },
    "grilled_salmon": {
        "display_name": "Grilled Salmon", "calories": 180, "protein": 24.0,
        "carbs": 0.0, "fat": 8.5, "fiber": 0.0, "sugar": 0.0, "sodium": 110,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "fish_and_chips": {
        "display_name": "Fish and Chips", "calories": 240, "protein": 12.0,
        "carbs": 22.5, "fat": 11.5, "fiber": 1.5, "sugar": 1.0, "sodium": 460,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "shrimp_and_grits": {
        "display_name": "Shrimp and Grits", "calories": 190, "protein": 13.5,
        "carbs": 17.5, "fat": 7.0, "fiber": 1.0, "sugar": 1.5, "sodium": 520,
        "serving_g": 250, "serving_unit": "g", "notes": None,
    },
    "crab_cakes": {
        "display_name": "Crab Cakes", "calories": 220, "protein": 14.5,
        "carbs": 11.0, "fat": 13.5, "fiber": 0.5, "sugar": 1.5, "sodium": 680,
        "serving_g": 90, "serving_unit": "piece", "notes": "1 cake",
    },
    "mussels": {
        "display_name": "Mussels", "calories": 86, "protein": 11.9,
        "carbs": 3.7, "fat": 2.2, "fiber": 0.0, "sugar": 0.0, "sodium": 286,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "oysters": {
        "display_name": "Oysters", "calories": 68, "protein": 7.0,
        "carbs": 3.9, "fat": 2.5, "fiber": 0.0, "sugar": 0.0, "sodium": 220,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "scallops": {
        "display_name": "Scallops", "calories": 88, "protein": 16.8,
        "carbs": 3.2, "fat": 0.9, "fiber": 0.0, "sugar": 0.0, "sodium": 161,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "tuna_tartare": {
        "display_name": "Tuna Tartare", "calories": 132, "protein": 23.5,
        "carbs": 1.5, "fat": 3.5, "fiber": 0.0, "sugar": 0.5, "sodium": 220,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "beef_carpaccio": {
        "display_name": "Beef Carpaccio", "calories": 155, "protein": 18.5,
        "carbs": 1.0, "fat": 8.5, "fiber": 0.0, "sugar": 0.5, "sodium": 240,
        "serving_g": 80, "serving_unit": "g", "notes": None,
    },
    "beef_tartare": {
        "display_name": "Beef Tartare", "calories": 168, "protein": 20.0,
        "carbs": 1.5, "fat": 9.0, "fiber": 0.0, "sugar": 0.5, "sodium": 260,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "foie_gras": {
        "display_name": "Foie Gras", "calories": 462, "protein": 11.4,
        "carbs": 4.7, "fat": 44.0, "fiber": 0.0, "sugar": 0.0, "sodium": 697,
        "serving_g": 50, "serving_unit": "g", "notes": None,
    },
    "ceviche": {
        "display_name": "Ceviche", "calories": 75, "protein": 13.5,
        "carbs": 4.5, "fat": 1.0, "fiber": 0.5, "sugar": 1.5, "sodium": 210,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "chicken_wings": {
        "display_name": "Chicken Wings", "calories": 290, "protein": 22.5,
        "carbs": 3.0, "fat": 21.0, "fiber": 0.0, "sugar": 1.0, "sodium": 480,
        "serving_g": 120, "serving_unit": "g", "notes": "4–5 wings",
    },

    # ── Eggs & breakfast ─────────────────────────────────────────────────────
    "omelette": {
        "display_name": "Omelette", "calories": 154, "protein": 11.0,
        "carbs": 1.5, "fat": 11.5, "fiber": 0.0, "sugar": 1.0, "sodium": 310,
        "serving_g": 120, "serving_unit": "g", "notes": "2-egg plain",
    },
    "eggs_benedict": {
        "display_name": "Eggs Benedict", "calories": 275, "protein": 14.5,
        "carbs": 18.5, "fat": 16.0, "fiber": 0.5, "sugar": 2.5, "sodium": 720,
        "serving_g": 200, "serving_unit": "g", "notes": None,
    },
    "french_toast": {
        "display_name": "French Toast", "calories": 230, "protein": 7.5,
        "carbs": 31.0, "fat": 8.5, "fiber": 1.0, "sugar": 9.0, "sodium": 310,
        "serving_g": 150, "serving_unit": "g", "notes": "2 slices",
    },
    "pancakes": {
        "display_name": "Pancakes", "calories": 227, "protein": 6.0,
        "carbs": 36.5, "fat": 7.0, "fiber": 1.0, "sugar": 10.0, "sodium": 360,
        "serving_g": 150, "serving_unit": "g", "notes": "2 medium pancakes",
    },
    "waffles": {
        "display_name": "Waffles", "calories": 290, "protein": 7.5,
        "carbs": 37.5, "fat": 12.0, "fiber": 1.0, "sugar": 8.0, "sodium": 490,
        "serving_g": 130, "serving_unit": "g", "notes": "1 waffle",
    },

    # ── Bread & sides ─────────────────────────────────────────────────────────
    "garlic_bread": {
        "display_name": "Garlic Bread", "calories": 350, "protein": 8.0,
        "carbs": 46.5, "fat": 15.0, "fiber": 2.0, "sugar": 2.0, "sodium": 640,
        "serving_g": 60, "serving_unit": "slice", "notes": None,
    },
    "french_fries": {
        "display_name": "French Fries", "calories": 312, "protein": 3.4,
        "carbs": 41.0, "fat": 15.0, "fiber": 3.5, "sugar": 0.5, "sodium": 210,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "onion_rings": {
        "display_name": "Onion Rings", "calories": 411, "protein": 5.0,
        "carbs": 42.0, "fat": 25.0, "fiber": 2.5, "sugar": 4.0, "sodium": 500,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "poutine": {
        "display_name": "Poutine", "calories": 230, "protein": 8.5,
        "carbs": 25.5, "fat": 11.0, "fiber": 2.5, "sugar": 2.0, "sodium": 560,
        "serving_g": 300, "serving_unit": "g", "notes": None,
    },
    "cheese_plate": {
        "display_name": "Cheese Plate", "calories": 390, "protein": 22.0,
        "carbs": 3.0, "fat": 32.0, "fiber": 0.0, "sugar": 0.5, "sodium": 620,
        "serving_g": 120, "serving_unit": "g", "notes": "assorted hard cheeses",
    },

    # ── Middle-Eastern / Mediterranean ───────────────────────────────────────
    "baklava": {
        "display_name": "Baklava", "calories": 428, "protein": 6.0,
        "carbs": 52.5, "fat": 23.0, "fiber": 2.0, "sugar": 34.0, "sodium": 180,
        "serving_g": 60, "serving_unit": "piece", "notes": None,
    },

    # ── Desserts & sweets ─────────────────────────────────────────────────────
    "apple_pie": {
        "display_name": "Apple Pie", "calories": 237, "protein": 2.0,
        "carbs": 34.0, "fat": 11.0, "fiber": 1.5, "sugar": 15.0, "sodium": 250,
        "serving_g": 125, "serving_unit": "g", "notes": "1 slice",
    },
    "carrot_cake": {
        "display_name": "Carrot Cake", "calories": 415, "protein": 4.5,
        "carbs": 56.0, "fat": 20.5, "fiber": 1.5, "sugar": 40.0, "sodium": 330,
        "serving_g": 100, "serving_unit": "g",
        "notes": "Includes cream-cheese frosting — actual values vary by recipe.",
    },
    "chocolate_cake": {
        "display_name": "Chocolate Cake", "calories": 371, "protein": 5.0,
        "carbs": 51.0, "fat": 17.5, "fiber": 2.5, "sugar": 32.0, "sodium": 360,
        "serving_g": 100, "serving_unit": "g",
        "notes": "With chocolate buttercream. Calories range from 300–450 depending on recipe.",
    },
    "cheesecake": {
        "display_name": "Cheesecake", "calories": 321, "protein": 5.5,
        "carbs": 25.0, "fat": 22.5, "fiber": 0.5, "sugar": 19.0, "sodium": 310,
        "serving_g": 100, "serving_unit": "g", "notes": "1 slice",
    },
    "red_velvet_cake": {
        "display_name": "Red Velvet Cake", "calories": 390, "protein": 4.5,
        "carbs": 52.0, "fat": 19.0, "fiber": 1.0, "sugar": 37.0, "sodium": 320,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "tiramisu": {
        "display_name": "Tiramisu", "calories": 283, "protein": 5.0,
        "carbs": 27.5, "fat": 17.0, "fiber": 0.5, "sugar": 20.0, "sodium": 145,
        "serving_g": 120, "serving_unit": "g", "notes": None,
    },
    "panna_cotta": {
        "display_name": "Panna Cotta", "calories": 220, "protein": 3.5,
        "carbs": 23.5, "fat": 13.0, "fiber": 0.0, "sugar": 22.0, "sodium": 55,
        "serving_g": 120, "serving_unit": "g", "notes": None,
    },
    "creme_brulee": {
        "display_name": "Crème Brûlée", "calories": 290, "protein": 4.5,
        "carbs": 26.5, "fat": 19.0, "fiber": 0.0, "sugar": 23.0, "sodium": 65,
        "serving_g": 120, "serving_unit": "g", "notes": None,
    },
    "chocolate_mousse": {
        "display_name": "Chocolate Mousse", "calories": 250, "protein": 4.5,
        "carbs": 22.0, "fat": 16.5, "fiber": 2.0, "sugar": 19.0, "sodium": 55,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "ice_cream": {
        "display_name": "Ice Cream", "calories": 207, "protein": 3.5,
        "carbs": 23.5, "fat": 11.0, "fiber": 0.0, "sugar": 21.0, "sodium": 80,
        "serving_g": 130, "serving_unit": "g", "notes": "2 scoops vanilla",
    },
    "frozen_yogurt": {
        "display_name": "Frozen Yogurt", "calories": 159, "protein": 3.5,
        "carbs": 28.0, "fat": 4.0, "fiber": 0.0, "sugar": 23.0, "sodium": 78,
        "serving_g": 120, "serving_unit": "g", "notes": None,
    },
    "donuts": {
        "display_name": "Doughnuts", "calories": 452, "protein": 5.0,
        "carbs": 51.0, "fat": 25.0, "fiber": 1.5, "sugar": 22.0, "sodium": 360,
        "serving_g": 60, "serving_unit": "piece", "notes": None,
    },
    "cup_cakes": {
        "display_name": "Cupcakes", "calories": 305, "protein": 3.5,
        "carbs": 44.0, "fat": 13.0, "fiber": 0.5, "sugar": 29.0, "sodium": 250,
        "serving_g": 65, "serving_unit": "piece", "notes": None,
    },
    "macarons": {
        "display_name": "Macarons", "calories": 390, "protein": 5.5,
        "carbs": 55.0, "fat": 17.0, "fiber": 1.0, "sugar": 50.0, "sodium": 70,
        "serving_g": 35, "serving_unit": "piece", "notes": None,
    },
    "cannoli": {
        "display_name": "Cannoli", "calories": 300, "protein": 7.5,
        "carbs": 31.0, "fat": 16.5, "fiber": 0.5, "sugar": 15.0, "sodium": 195,
        "serving_g": 85, "serving_unit": "piece", "notes": None,
    },
    "churros": {
        "display_name": "Churros", "calories": 390, "protein": 5.0,
        "carbs": 55.0, "fat": 18.0, "fiber": 2.0, "sugar": 12.0, "sodium": 150,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },
    "strawberry_shortcake": {
        "display_name": "Strawberry Shortcake", "calories": 250, "protein": 4.0,
        "carbs": 35.0, "fat": 11.0, "fiber": 1.0, "sugar": 18.0, "sodium": 240,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "bread_pudding": {
        "display_name": "Bread Pudding", "calories": 200, "protein": 6.5,
        "carbs": 31.5, "fat": 6.0, "fiber": 1.0, "sugar": 14.0, "sodium": 290,
        "serving_g": 150, "serving_unit": "g", "notes": None,
    },
    "beignets": {
        "display_name": "Beignets", "calories": 390, "protein": 6.0,
        "carbs": 52.5, "fat": 18.0, "fiber": 1.5, "sugar": 14.0, "sodium": 310,
        "serving_g": 100, "serving_unit": "g", "notes": None,
    },

    # ── Fruits (the 3 extra classes beyond Food-101) ──────────────────────────
    "apple": {
        "display_name": "Apple", "calories": 52, "protein": 0.3,
        "carbs": 13.8, "fat": 0.2, "fiber": 2.4, "sugar": 10.4, "sodium": 1,
        "serving_g": 180, "serving_unit": "piece", "notes": "1 medium apple ≈ 180 g",
    },
    "banana": {
        "display_name": "Banana", "calories": 89, "protein": 1.1,
        "carbs": 23.0, "fat": 0.3, "fiber": 2.6, "sugar": 12.2, "sodium": 1,
        "serving_g": 120, "serving_unit": "piece", "notes": "1 medium banana ≈ 120 g",
    },
    "orange": {
        "display_name": "Orange", "calories": 47, "protein": 0.9,
        "carbs": 12.0, "fat": 0.1, "fiber": 2.4, "sugar": 9.4, "sodium": 0,
        "serving_g": 130, "serving_unit": "piece", "notes": "1 medium orange ≈ 130 g",
    },
}


# ---------------------------------------------------------------------------
# Alias table
# Handle any label variants the model might output for the same food.
# ---------------------------------------------------------------------------
LABEL_ALIASES: dict[str, str] = {
    # Model may output either form
    "hot_dog":         "hot_dog",
    "hotdog":          "hot_dog",
    "burger":          "hamburger",
    "bbq_ribs":        "baby_back_ribs",
    "donut":           "donuts",
    "doughnut":        "donuts",
    "cupcake":         "cup_cakes",
    "macaron":         "macarons",
    "dumpling":        "dumplings",
    "taco":            "tacos",
    "waffle":          "waffles",
    "pancake":         "pancakes",
    "fries":           "french_fries",
    "pasta_bolognese": "spaghetti_bolognese",
    "pasta_carbonara": "spaghetti_carbonara",
    "grilled_cheese":  "grilled_cheese_sandwich",
}


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def get_nutrition(model_label: str) -> dict | None:
    """
    Look up nutrition info for a model prediction label.

    Resolves aliases and returns a copy of the nutrition dict, or None if
    the label is completely unknown (should prompt manual entry).

    Args:
        model_label: The raw label string from the ML model (e.g. "baby_back_ribs").

    Returns:
        Dict with nutrition fields, or None if not found.
    """
    label = model_label.strip().lower()

    # Resolve alias if present
    label = LABEL_ALIASES.get(label, label)

    entry = NUTRITION_MAP.get(label)
    if entry is None:
        return None

    # Return a copy to prevent accidental mutation of the map
    return {"model_label": label, **entry}


def calculate_nutrition_for_serving(
    model_label: str,
    serving_g: float,
) -> dict | None:
    """
    Calculate actual macros consumed for a given serving size.

    Args:
        model_label: Label string from the ML model.
        serving_g:   Portion size in grams.

    Returns:
        Dict with computed calories, protein, carbs, fat for the portion,
        or None if label is unknown.
    """
    info = get_nutrition(model_label)
    if info is None:
        return None

    scale = serving_g / 100.0
    return {
        "model_label":  info["model_label"],
        "display_name": info["display_name"],
        "serving_g":    serving_g,
        "calories":     round(info["calories"] * scale, 1),
        "protein_g":    round(info["protein"]  * scale, 1),
        "carbs_g":      round(info["carbs"]    * scale, 1),
        "fat_g":        round(info["fat"]       * scale, 1),
    }

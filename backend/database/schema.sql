
CREATE TABLE IF NOT EXISTS users (
    id                  SERIAL PRIMARY KEY,
    email               VARCHAR(255) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    full_name           VARCHAR(120),
    age                 INTEGER CHECK (age > 0 AND age < 130),
    gender              VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    height_cm           NUMERIC(5,1),                -- e.g. 175.0
    weight_kg           NUMERIC(5,1),                -- e.g. 72.5
    daily_calorie_goal  INTEGER DEFAULT 2000,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);


-- ---------------------------------------------------------------------------
-- 2. FOOD ITEMS
--    One row per recognisable food label.
--    All nutrition values are per 100 g of the food.
--    Serving defaults give the app a sensible starting point when no
--    custom portion is supplied.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS food_items (
    id                  SERIAL PRIMARY KEY,

    -- Exact label string returned by the ML model (e.g. "baby_back_ribs")
    model_label         VARCHAR(100) NOT NULL UNIQUE,

    -- Human-readable name shown in the UI (e.g. "Baby Back Ribs")
    display_name        VARCHAR(150) NOT NULL,

    -- Macros per 100 g
    calories_per_100g   NUMERIC(7,2) NOT NULL,
    protein_per_100g    NUMERIC(6,2) NOT NULL DEFAULT 0,
    carbs_per_100g      NUMERIC(6,2) NOT NULL DEFAULT 0,
    fat_per_100g        NUMERIC(6,2) NOT NULL DEFAULT 0,
    fiber_per_100g      NUMERIC(6,2) DEFAULT 0,
    sugar_per_100g      NUMERIC(6,2) DEFAULT 0,
    sodium_per_100g     NUMERIC(7,2) DEFAULT 0,      -- mg per 100 g

    -- Default serving used for initial calculations
    default_serving_g   NUMERIC(6,1) NOT NULL DEFAULT 100,
    serving_unit        VARCHAR(30)  NOT NULL DEFAULT 'g',  -- g / oz / piece / cup / slice

    -- Metadata
    data_source         VARCHAR(50)  DEFAULT 'manual',      -- manual | usda | edamam
    notes               TEXT,                               -- e.g. "average of multiple varieties"
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_items_model_label ON food_items(model_label);


-- ---------------------------------------------------------------------------
-- 3. MEALS
--    A logical meal session (breakfast, lunch, dinner, snack).
--    Each user can log multiple meals per day.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meals (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        VARCHAR(50) DEFAULT 'meal'
                    CHECK (name IN ('breakfast','lunch','dinner','snack','meal')),
    meal_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    notes       TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meals_user_date ON meals(user_id, meal_date);


-------------------------------------------------
CREATE TABLE IF NOT EXISTS meal_items (
    id                  SERIAL PRIMARY KEY,
    meal_id             INTEGER NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
    food_item_id        INTEGER NOT NULL REFERENCES food_items(id),

    -- Portion consumed — original user-facing values + computed grams
    serving_quantity    NUMERIC(8,2) NOT NULL DEFAULT 1,       -- e.g. 2
    serving_unit        VARCHAR(30)  NOT NULL DEFAULT 'g',     -- e.g. "slice"
    serving_g           NUMERIC(6,1) NOT NULL DEFAULT 100,     -- converted to grams

    -- Pre-computed nutrition for this portion
    -- Formula: (value_per_100g / 100) * serving_g
    calories            NUMERIC(7,2) NOT NULL,
    protein_g           NUMERIC(6,2) NOT NULL DEFAULT 0,
    carbs_g             NUMERIC(6,2) NOT NULL DEFAULT 0,
    fat_g               NUMERIC(6,2) NOT NULL DEFAULT 0,

    -- ML prediction context (optional, useful for auditing)
    predicted_label     VARCHAR(100),
    confidence          NUMERIC(5,4),               -- 0.0000 – 1.0000
    image_path          TEXT,                       -- stored image path / S3 key

    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_items_meal ON meal_items(meal_id);


-- ---------------------------------------------------------------------------
-- 5. HELPER VIEW
--    Joins meal_items → meals → food_items for convenient reporting queries.
--    Replaces the need to manually JOIN three tables in every query.
--
--    Example:
--        SELECT * FROM meal_items_detail
--        WHERE user_id = 1 AND meal_date = CURRENT_DATE;
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW meal_items_detail AS
SELECT
    mi.id                   AS meal_item_id,
    mi.meal_id,
    m.user_id,
    m.meal_date,
    m.name                  AS meal_type,
    fi.model_label,
    fi.display_name,
    mi.serving_g,
    mi.calories,
    mi.protein_g,
    mi.carbs_g,
    mi.fat_g,
    mi.confidence,
    mi.image_path,
    mi.created_at
FROM meal_items mi
JOIN meals      m  ON m.id = mi.meal_id
JOIN food_items fi ON fi.id = mi.food_item_id;

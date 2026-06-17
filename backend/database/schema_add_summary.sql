-- =============================================================================
-- Phase 2 Optimization — Daily Nutrition Summary
--
-- Run this ONLY after the core schema (schema.sql) is applied and the app
-- is working. This is a denormalised cache table — not required for the MVP.
--
-- Apply with:
--     psql -U postgres -d food_app -f database/schema_add_summary.sql
-- =============================================================================


-- ---------------------------------------------------------------------------
-- DAILY NUTRITION SUMMARY
--    Denormalised cache: one row per user per day.
--    Lets the dashboard do a single SELECT instead of re-aggregating
--    all meal_items every request.
--
--    Update strategy: upsert after every POST /meals call, or run the
--    refresh query below on a schedule.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daily_nutrition_summary (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    summary_date    DATE    NOT NULL,
    total_calories  NUMERIC(8,2) DEFAULT 0,
    total_protein   NUMERIC(7,2) DEFAULT 0,
    total_carbs     NUMERIC(7,2) DEFAULT 0,
    total_fat       NUMERIC(7,2) DEFAULT 0,
    meal_count      INTEGER DEFAULT 0,
    updated_at      TIMESTAMP DEFAULT NOW(),

    UNIQUE (user_id, summary_date)
);

CREATE INDEX IF NOT EXISTS idx_dns_user_date ON daily_nutrition_summary(user_id, summary_date);


-- ---------------------------------------------------------------------------
-- REFRESH QUERY
--    Call this to rebuild the summary for a specific user + date.
--    In Python: run after every successful meal_items insert.
-- ---------------------------------------------------------------------------
-- INSERT INTO daily_nutrition_summary
--     (user_id, summary_date, total_calories, total_protein, total_carbs, total_fat, meal_count)
-- SELECT
--     m.user_id,
--     m.meal_date,
--     SUM(mi.calories)         AS total_calories,
--     SUM(mi.protein_g)        AS total_protein,
--     SUM(mi.carbs_g)          AS total_carbs,
--     SUM(mi.fat_g)            AS total_fat,
--     COUNT(DISTINCT m.id)     AS meal_count
-- FROM meal_items mi
-- JOIN meals m ON m.id = mi.meal_id
-- WHERE m.user_id = :user_id AND m.meal_date = :date
-- GROUP BY m.user_id, m.meal_date
-- ON CONFLICT (user_id, summary_date)
-- DO UPDATE SET
--     total_calories = EXCLUDED.total_calories,
--     total_protein  = EXCLUDED.total_protein,
--     total_carbs    = EXCLUDED.total_carbs,
--     total_fat      = EXCLUDED.total_fat,
--     meal_count     = EXCLUDED.meal_count,
--     updated_at     = NOW();

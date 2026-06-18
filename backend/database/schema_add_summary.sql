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


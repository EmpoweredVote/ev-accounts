-- Phase 34: RLS + grants for treasury schema (4 tables)
-- All tables are public-read. No INSERT/UPDATE/DELETE policies — all writes via service role (pool.query()).

BEGIN;

-- ============================================================
-- Section 1: Enable RLS on every table
-- ============================================================
ALTER TABLE treasury.budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury.budget_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE treasury.cities ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Section 2: Public-read policies
-- ============================================================
CREATE POLICY "budget_categories: public read"
  ON treasury.budget_categories FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "budget_line_items: public read"
  ON treasury.budget_line_items FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "budgets: public read"
  ON treasury.budgets FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "cities: public read"
  ON treasury.cities FOR SELECT TO anon, authenticated USING (true);

-- ============================================================
-- Section 3: Grants
-- ============================================================
GRANT USAGE ON SCHEMA treasury TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA treasury TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA treasury GRANT SELECT ON TABLES TO anon, authenticated;

COMMIT;

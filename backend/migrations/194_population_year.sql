-- 194_population_year.sql
-- Add population_year column to treasury.municipalities
-- Tracks the vintage year of the Census population estimate stored in the population column.
-- v1.3 Phase 11 — supports per-capita display labels in treasury-tracker frontend.

ALTER TABLE treasury.municipalities
  ADD COLUMN IF NOT EXISTS population_year INTEGER;

-- Verify the column was added (returns 2 rows: population and population_year)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'treasury'
  AND table_name = 'municipalities'
  AND column_name IN ('population', 'population_year')
ORDER BY column_name;

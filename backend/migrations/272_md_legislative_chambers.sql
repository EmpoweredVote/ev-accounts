-- Migration 272: MD legislative chambers under the existing State of Maryland government row
--
-- Purpose: Seeds Maryland Senate and Maryland House of Delegates chambers
-- under the pre-existing State of Maryland government row (geo_id='24').
-- No governments INSERT — row pre-exists from migration 174.
-- No officials, offices, or districts — chambers-only migration.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include
-- in INSERT column list or the INSERT will error.
--
-- CRITICAL: essentials.governments has no unique constraint on geo_id — use
-- name+state subquery to resolve government_id (not ON CONFLICT on geo_id).
--
-- Naming convention: Short name + state-qualified formal name (OR/CA/MD exec pattern).
--   name='Maryland Senate', name_formal='Maryland State Senate'
--   name='Maryland House of Delegates', name_formal='Maryland House of Delegates'
--   (legislative chamber names are self-qualifying — same convention as
--    'Oregon House of Representatives' in migration 222 line 83)
--
-- D-07 (Phase 93 CONTEXT.md): first migration in the 4-migration seeding sequence
--   272 (chambers) → 273 (senators) → 274 (delegates) → 275 (federal)
--
-- D-08 (Phase 93 CONTEXT.md): pre-flight assertions verify no MD legislative chambers
--   already exist under State of Maryland government before inserting.
--
-- D-02 (Phase 93 RESEARCH.md, RESOLVED): A/B-split districts elect 3 delegates total
--   (2 subdistrict + 1 from the other subdistrict) — no parent STATE_LOWER rows needed.
--   The 71 existing SLDL rows cover all 141 delegate positions. This migration is
--   chambers-only (no district rows added).
--
-- Idempotency: all INSERTs guarded by WHERE NOT EXISTS on (name + government_id).
-- Safe to re-run — produces no errors and no duplicate rows.

BEGIN;

-- Pre-flight: assert State of Maryland government row exists (exactly 1 row)
-- DO NOT insert — row pre-exists from migration 174; if missing or duplicated, fail fast.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Maryland' AND state = 'MD') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Maryland government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Maryland' AND state = 'MD');
  END IF;
END $$;

-- Pre-flight: assert no MD legislative chambers exist yet under State of Maryland
-- (fail-fast before any INSERT — D-08 idempotency guard for this migration's output)
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.chambers c
      JOIN essentials.governments g ON g.id = c.government_id
      WHERE g.name = 'State of Maryland'
        AND c.name IN ('Maryland Senate', 'Maryland House of Delegates')) <> 0 THEN
    RAISE EXCEPTION 'Pre-flight failed: MD legislative chambers already exist under State of Maryland';
  END IF;
END $$;

-- Maryland Senate chamber
-- name_formal='Maryland State Senate' per CONTEXT.md Claude's Discretion naming convention
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maryland Senate',
       'Maryland State Senate',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maryland Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

-- Maryland House of Delegates chamber
-- name_formal='Maryland House of Delegates' — legislative chamber name is self-qualifying
-- (same convention as 'Oregon House of Representatives' in migration 222)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maryland House of Delegates',
       'Maryland House of Delegates',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maryland House of Delegates'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

COMMIT;

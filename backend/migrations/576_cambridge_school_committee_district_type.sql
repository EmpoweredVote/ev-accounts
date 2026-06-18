-- Migration 576: Cambridge School Committee district_type fix
--
-- Problem: Cambridge School Committee offices share the same essentials.districts
-- row (district_type='LOCAL') as Cambridge City Council. The frontend groups
-- both bodies into the Local tier, mixing them together on the Reps tab.
--
-- Fix: Insert a separate essentials.districts row for the School Committee with
-- district_type='SCHOOL' (same geo_id/mtfcc/state so geofence lookups still
-- return it for Cambridge addresses), then point the 6 School Committee offices
-- at this new row. City Council offices remain on the existing LOCAL district.
--
-- After this migration the frontend groupHierarchy.js will route School Committee
-- members to the School tier (between Local and State), matching the desired order:
--   Local (City Manager → City Council) → School (School Committee) → State
--
-- Chambers:
--   City Council:     b4b8c0a1-2658-4df4-9196-9646c99d173c  (unchanged, stays LOCAL)
--   School Committee: 41846a49-e5d5-460d-b2c2-0f4f8130b949  (6 offices → new SCHOOL district)

BEGIN;

-- Step 1: Insert the SCHOOL-typed district row for Cambridge (idempotent)
INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
SELECT '2511000', 'SCHOOL', 'G4110', 'MA', 'Cambridge School District'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
    AND district_type = 'SCHOOL'
);

-- Step 2: Point all Cambridge School Committee offices at the new SCHOOL district
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
    AND district_type = 'SCHOOL'
  LIMIT 1
)
WHERE chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
AND district_id IS DISTINCT FROM (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
    AND district_type = 'SCHOOL'
  LIMIT 1
);

-- Verification gates
DO $$
DECLARE
  v_school_district_count INT;
  v_sc_offices_correct INT;
  v_sc_offices_total INT;
BEGIN
  -- Gate 1: exactly one Cambridge SCHOOL district row exists
  SELECT COUNT(*) INTO v_school_district_count
  FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
    AND district_type = 'SCHOOL';

  IF v_school_district_count <> 1 THEN
    RAISE EXCEPTION 'Migration 576 FAILED: expected 1 Cambridge SCHOOL district, found %', v_school_district_count;
  END IF;

  -- Gate 2: exactly 6 School Committee offices exist
  SELECT COUNT(*) INTO v_sc_offices_total
  FROM essentials.offices
  WHERE chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949';

  IF v_sc_offices_total <> 6 THEN
    RAISE EXCEPTION 'Migration 576 FAILED: expected 6 School Committee offices, found %', v_sc_offices_total;
  END IF;

  -- Gate 3: all 6 School Committee offices point at the SCHOOL district
  SELECT COUNT(*) INTO v_sc_offices_correct
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.chamber_id = '41846a49-e5d5-460d-b2c2-0f4f8130b949'
    AND d.district_type = 'SCHOOL';

  IF v_sc_offices_correct <> 6 THEN
    RAISE EXCEPTION 'Migration 576 FAILED: expected 6 School Committee offices on SCHOOL district, found %', v_sc_offices_correct;
  END IF;

  RAISE NOTICE 'Migration 576 OK: Cambridge School Committee (%) offices now district_type=SCHOOL', v_sc_offices_correct;
END $$;

COMMIT;

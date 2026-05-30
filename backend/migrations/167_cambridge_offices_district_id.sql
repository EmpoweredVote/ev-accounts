-- Migration 167: Cambridge offices district_id back-fill
--
-- Phase 48 UAT gap: Cambridge address search returns no local officials.
-- Root cause: Cambridge offices had district_id pointing at legacy district rows
-- (geo_id='2511000', mtfcc='', state='25') that don't match the G4110 geofence.
-- getRepresentativesByAddress joins geofence_boundaries to districts on geo_id+mtfcc,
-- then joins offices on district_id. The legacy district rows (no mtfcc) never matched
-- the G4110 geofence boundary, so all 17 Cambridge offices were silently dropped.
--
-- Fix: INSERT one essentials.districts row for Cambridge with correct G4110+MA metadata
-- (geo_id='2511000', mtfcc='G4110', state='MA'), then UPDATE all 17 Cambridge offices
-- (City Council + School Committee) to point at that district.
--
-- Precedent: Migration 115 (LA City Attorney/Controller) applied the identical
-- pattern when offices existed with NULL district_id and address-lookup dropped them.
--
-- Idempotency: essentials.districts has NO unique constraint on geo_id, so we
-- gate the INSERT with WHERE NOT EXISTS. UPDATE targets all Cambridge offices
-- (not just NULL) to correct offices that previously pointed at legacy rows.

BEGIN;

-- Step 1: INSERT Cambridge district row with correct G4110 metadata (idempotent)
INSERT INTO essentials.districts (geo_id, district_type, mtfcc, state, label)
SELECT '2511000', 'LOCAL', 'G4110', 'MA', 'Cambridge'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
);

-- Step 2: UPDATE all 17 Cambridge offices to point at the correct G4110 district
-- Chambers (from migration 158):
--   City Council:     b4b8c0a1-2658-4df4-9196-9646c99d173c  (11 offices)
--   School Committee: 41846a49-e5d5-460d-b2c2-0f4f8130b949  (6 offices)
-- Both chambers update unconditionally so legacy district pointers are corrected.

UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
  LIMIT 1
)
WHERE chamber_id IN (
  'b4b8c0a1-2658-4df4-9196-9646c99d173c',  -- Cambridge City Council
  '41846a49-e5d5-460d-b2c2-0f4f8130b949'   -- Cambridge School Committee
)
AND district_id IS DISTINCT FROM (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA'
  LIMIT 1
);

-- Step 3: Verification gates (raise exception on failure, rolling back entire migration)
DO $$
DECLARE
  v_district_count INT;
  v_offices_correct INT;
  v_offices_total INT;
BEGIN
  -- Gate 1: exactly one Cambridge G4110/MA district row exists
  SELECT COUNT(*) INTO v_district_count
  FROM essentials.districts
  WHERE geo_id = '2511000' AND mtfcc = 'G4110' AND state = 'MA';

  IF v_district_count <> 1 THEN
    RAISE EXCEPTION 'Migration 167 FAILED: expected 1 Cambridge G4110/MA district row, found %', v_district_count;
  END IF;

  -- Gate 2: all 17 Cambridge offices exist
  SELECT COUNT(*) INTO v_offices_total
  FROM essentials.offices
  WHERE chamber_id IN (
    'b4b8c0a1-2658-4df4-9196-9646c99d173c',
    '41846a49-e5d5-460d-b2c2-0f4f8130b949'
  );

  IF v_offices_total <> 17 THEN
    RAISE EXCEPTION 'Migration 167 FAILED: expected 17 Cambridge offices, found %', v_offices_total;
  END IF;

  -- Gate 3: all 17 Cambridge offices point at the correct G4110/MA district
  SELECT COUNT(*) INTO v_offices_correct
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.chamber_id IN (
    'b4b8c0a1-2658-4df4-9196-9646c99d173c',
    '41846a49-e5d5-460d-b2c2-0f4f8130b949'
  )
  AND d.geo_id = '2511000' AND d.mtfcc = 'G4110' AND d.state = 'MA';

  IF v_offices_correct <> 17 THEN
    RAISE EXCEPTION 'Migration 167 FAILED: expected 17 Cambridge offices pointing at G4110 district, found %', v_offices_correct;
  END IF;

  RAISE NOTICE 'Migration 167 OK: 1 Cambridge G4110/MA district, % offices correctly linked', v_offices_correct;
END $$;

-- Step 4: INSERT government_bodies rows so frontend groups City Council and
-- School Committee into separate sections (body_key must match chamber.name_formal)
INSERT INTO essentials.government_bodies (state, geo_id, body_key, display_name, website_url)
VALUES
  ('MA', '2511000', 'Cambridge City Council',     'Cambridge City Council',     'https://www.cambridgema.gov/Departments/citycouncil'),
  ('MA', '2511000', 'Cambridge School Committee', 'Cambridge School Committee', 'https://www.cpsd.us/school_committee')
ON CONFLICT (state, geo_id, body_key) DO NOTHING;

COMMIT;

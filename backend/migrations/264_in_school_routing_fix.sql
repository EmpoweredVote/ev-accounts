-- Migration 264: Indiana school routing fix
-- Corrects IPS + MCCSC routing per Phase 89 Plan 01.
--
-- Actions:
--   1. UPDATE IPS D2 (Gayle Cosby → Hasaan Rashid; same external_id preserved)
--   2. INSERT IPS SCHOOL whole-district districts row (geo_id='1804770', state='in' LOWERCASE)
--   3. INSERT MCCSC SCHOOL whole-district districts row (geo_id='1800630', state='in' LOWERCASE)
--   4. UPDATE all IPS offices to point to IPS whole-district row (replaces sub-district district_ids)
--   5. UPDATE all MCCSC offices to point to MCCSC whole-district row (replaces sub-district district_ids)
--   6. INSERT new IPS chamber for District 3 + INSERT IPS D3 Hope Duke Star (external_id=-890001) + office
--   7. UPDATE MCCSC D7 (Brandon Shurr → Aja Jester; same external_id preserved)
--   8. Back-fill politicians.office_id on new D3 row
--
-- CRITICAL rules:
--   - IPS GEOID = 1804770 (NOT 1800630 — that is MCCSC)
--   - MCCSC GEOID = 1800630 (NOT 1809480 — that is Richland Bean Borden, wrong district)
--   - IPS has 5 districts + 2 At-Large = 7 seats. NO District 6.
--   - districts.state = 'in' LOWERCASE (routing query uses lowercase state)
--   - offices.representing_state = 'IN' UPPERCASE
--   - district_type = 'SCHOOL' (NOT 'SCHOOL_DISTRICT')
--   - G5420 geofence rows MUST exist before this migration (loader runs first)
--   - slug column NEVER included in any chambers INSERT (slug is GENERATED ALWAYS)
--   - All IPS offices updated to point to whole-district row (not just NULL ones)
--   - All MCCSC offices updated to point to whole-district row (not just NULL ones)
--   - IPS title convention (discovered pre-migration): 'Indianapolis Public School Board - District N'
--   - IPS D3 chamber: 'Indianapolis Public School Board - District 3' (matches existing pattern)
--
-- Pre-migration discovery (captured 2026-06-03):
--   IPS titles: 'Indianapolis Public School Board - District N' / 'Indianapolis Public School Board - At Large'
--   MCCSC D4: 'Tiana Williams Iruoje' (no change needed)
--   Gayle Cosby external_id: 506586 (preserved through UPDATE)
--   Brandon Shurr external_id: 437675 (preserved through UPDATE)
--
-- Run: 2026-06-03

BEGIN;

-- =============================================================================
-- Pre-flight 1: Verify IPS and MCCSC government rows exist
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name LIKE 'Indianapolis Public Schools%') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: IPS government not found — Phase 89 Plan 01 requires existing IPS seed';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name LIKE 'Monroe County Community School%') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: MCCSC government not found — Phase 89 Plan 01 requires existing MCCSC seed';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Hope Duke Star does NOT already exist
-- =============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE full_name = 'Hope Duke Star') THEN
    RAISE EXCEPTION 'Pre-flight FAILED: Hope Duke Star already exists in DB — migration already applied?';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 3: external_id -890001 is unoccupied
-- =============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -890001) THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id -890001 already occupied — migration already applied?';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 4: G5420 geofence rows exist (loader must have run first)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id IN ('1804770', '1800630') AND mtfcc = 'G5420';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 2 G5420 rows for IN (geo_ids 1804770 + 1800630), found % — run load-in-school-boundaries.ts first', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 1: UPDATE IPS D2 (Gayle Cosby → Hasaan Rashid; external_id 506586 preserved)
-- =============================================================================
UPDATE essentials.politicians
SET full_name = 'Hasaan Rashid',
    first_name = 'Hasaan',
    last_name = 'Rashid'
WHERE full_name = 'Gayle Cosby'
  AND EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    WHERE o.politician_id = essentials.politicians.id
      AND g.name LIKE 'Indianapolis Public Schools%'
  );

-- =============================================================================
-- Step 2: INSERT IPS whole-district SCHOOL districts row
-- state='in' LOWERCASE — routing query uses lowercase state for SCHOOL districts
-- geo_id='1804770' — matches the G5420 whole-district geofence_boundaries row
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'in', '1804770', 'Indianapolis Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '1804770' AND district_type = 'SCHOOL' AND state = 'in'
);

-- =============================================================================
-- Step 3: INSERT MCCSC whole-district SCHOOL districts row
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'in', '1800630', 'Monroe County Community School Corporation', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '1800630' AND district_type = 'SCHOOL' AND state = 'in'
);

-- =============================================================================
-- Step 4: UPDATE ALL IPS offices to point to IPS whole-district row
-- NOTE: Updates ALL IPS offices (not just NULL) because existing offices point to
--       sub-district districts rows (geo_id like '180477000001') that have NO matching
--       geofence_boundaries row — routing is broken until offices point to '1804770'.
-- =============================================================================
UPDATE essentials.offices o
SET district_id = (
  SELECT d.id FROM essentials.districts d
  WHERE d.geo_id = '1804770'
    AND d.district_type = 'SCHOOL'
    AND d.state = 'in'
)
WHERE o.chamber_id IN (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name LIKE 'Indianapolis Public Schools%'
);

-- =============================================================================
-- Step 5: UPDATE ALL MCCSC offices to point to MCCSC whole-district row
-- NOTE: Updates ALL MCCSC offices (not just NULL) because existing offices point to
--       sub-district districts rows (geo_id like '180063000001'). The Bloomington
--       coordinate covers the whole-district MCCSC boundary — whole-district routing
--       means all 7 trustees appear for any Bloomington address.
-- =============================================================================
UPDATE essentials.offices o
SET district_id = (
  SELECT d.id FROM essentials.districts d
  WHERE d.geo_id = '1800630'
    AND d.district_type = 'SCHOOL'
    AND d.state = 'in'
)
WHERE o.chamber_id IN (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name LIKE 'Monroe County Community School%'
);

-- =============================================================================
-- Step 6: INSERT IPS D3 Hope Duke Star (external_id=-890001) + chamber + office
--
-- The IPS structure uses one chamber per seat (discovered pre-migration 2026-06-03).
-- New chamber: 'Indianapolis Public School Board - District 3' (matches existing pattern)
-- Office title: 'Indianapolis Public School Board - District 3' (matches existing pattern)
-- =============================================================================

-- Step 6a: Insert new chamber for IPS District 3
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Indianapolis Public School Board - District 3',
       '',
       (SELECT id FROM essentials.governments WHERE name LIKE 'Indianapolis Public Schools%')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Indianapolis Public School Board - District 3'
    AND government_id = (SELECT id FROM essentials.governments WHERE name LIKE 'Indianapolis Public Schools%')
);

-- Step 6b: INSERT IPS D3 politician (Hope Duke Star) + office via CTE
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
  VALUES
    (gen_random_uuid(), 'Hope Duke Star', 'Hope', 'Star', NULL, true, false, false, true, -890001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant, role_canonical)
SELECT
  gen_random_uuid(),
  d.id,
  ch.id,
  p.id,
  'Indianapolis Public School Board - District 3',
  'IN',
  false,
  false,
  NULL
FROM essentials.districts d
CROSS JOIN ins_p p
JOIN essentials.chambers ch
  ON ch.name = 'Indianapolis Public School Board - District 3'
  AND ch.government_id = (SELECT id FROM essentials.governments WHERE name LIKE 'Indianapolis Public Schools%')
WHERE d.geo_id = '1804770'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'in'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 7: UPDATE MCCSC D7 (Brandon Shurr → Aja Jester; external_id 437675 preserved)
-- =============================================================================
UPDATE essentials.politicians
SET full_name = 'Aja Jester',
    first_name = 'Aja',
    last_name = 'Jester'
WHERE full_name = 'Brandon Shurr'
  AND EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    WHERE o.politician_id = essentials.politicians.id
      AND g.name LIKE 'Monroe County Community School%'
  );

-- =============================================================================
-- Step 8: Back-fill office_id on new D3 politician (Hope Duke Star)
-- =============================================================================
UPDATE essentials.politicians
SET office_id = o.id
FROM essentials.offices o
WHERE essentials.politicians.id = o.politician_id
  AND essentials.politicians.external_id = -890001
  AND essentials.politicians.office_id IS NULL;

-- =============================================================================
-- Post-verification: 7 gates — RAISE EXCEPTION on any failure
-- =============================================================================
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Gate (a): IPS SCHOOL districts row exists with state='in', geo_id='1804770'
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL' AND state = 'in' AND geo_id = '1804770';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED (a): expected 1 IPS SCHOOL district row with state=''in'' geo_id=''1804770'', found %', v_count;
  END IF;

  -- Gate (b): MCCSC SCHOOL districts row exists with state='in', geo_id='1800630'
  SELECT COUNT(*) INTO v_count
  FROM essentials.districts
  WHERE district_type = 'SCHOOL' AND state = 'in' AND geo_id = '1800630';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED (b): expected 1 MCCSC SCHOOL district row with state=''in'' geo_id=''1800630'', found %', v_count;
  END IF;

  -- Gate (c): Hope Duke Star exists with external_id=-890001 and has non-NULL office_id
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id = -890001
    AND full_name = 'Hope Duke Star'
    AND office_id IS NOT NULL;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED (c): Hope Duke Star (external_id=-890001) not found or has NULL office_id (count=%)', v_count;
  END IF;

  -- Gate (d): No politician named Gayle Cosby (D2 must be Hasaan Rashid)
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE full_name = 'Gayle Cosby';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (d): Gayle Cosby still exists in DB (count=%) — Step 1 UPDATE did not fire', v_count;
  END IF;

  -- Gate (e): No politician named Brandon Shurr (D7 must be Aja Jester)
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE full_name = 'Brandon Shurr';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (e): Brandon Shurr still exists in DB (count=%) — Step 7 UPDATE did not fire', v_count;
  END IF;

  -- Gate (f): Zero IPS or MCCSC offices have NULL district_id
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE (g.name LIKE 'Indianapolis Public Schools%'
      OR g.name LIKE 'Monroe County Community School%')
    AND o.district_id IS NULL;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (f): % IPS or MCCSC offices still have NULL district_id after back-fill', v_count;
  END IF;

  -- Gate (g): Section-split — 0 orphan G5420 rows for the 2 IN GEOIDs
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('1804770', '1800630')
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'in'
    );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED (g): % orphan G5420 rows for IN GEOIDs (missing SCHOOL districts row with state=''in'')', v_count;
  END IF;

  RAISE NOTICE 'Migration 264 post-verification PASSED: IPS D3 added, IPS D2 updated, MCCSC D7 updated, 2 SCHOOL districts inserted, all IPS+MCCSC offices wired, 0 orphans.';
END $$;

-- =============================================================================
-- Ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('264')
ON CONFLICT (version) DO NOTHING;

COMMIT;

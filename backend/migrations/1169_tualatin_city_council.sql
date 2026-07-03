-- Migration 1169: City of Tualatin government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Tualatin, Oregon (Washington County, west-metro):
--   Tualatin (geo_id='4174950' -- the CORRECTED value confirmed live against
--   essentials.geofence_boundaries; the originally-stated ROADMAP/CONTEXT value was wrong and
--   must never be used) -- 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices.
--
-- Form of government (RESEARCH-confirmed, re-verified fresh same-day at Wave-0 2026-07-02 via
-- tualatinoregon.gov/city-council/, no WAF): council-manager. Directly-elected Mayor (LOCAL_EXEC,
-- citywide) plus 6 Council Members elected at-large citywide in numbered Positions 1-6 (LOCAL,
-- shared district -- the numbers are seat labels on the office title, NOT separate districts or
-- wards). This is the Beaverton mig 1131 shape, NOT Tigard's plain-title pure-at-large shape.
--
-- Appointed seats: NONE. All 7 seats are presently held by ELECTION. Valerie Pratt (Position 6)
-- was originally APPOINTED in Aug 2019 to fill a vacancy, but her CURRENT term (Jan 2025-Dec 2028)
-- is by election (elected 2020, reelected 2024) -- is_appointed=false is correct for her present
-- seating. She holds the annually-elected Council President title -- a title on her seat, NOT a
-- separate office row. ONE office row only, title stays 'Council Member (Position 6)'. This is
-- the uniform Hillsboro/Beaverton shape -- do NOT import Tigard's appointed-seat block for any
-- Tualatin seat.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id -- use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: numbered Positions are labels on the office title only -- NO per-Position districts,
--           NO ward geofences of any kind. All 6 councilors share the ONE LOCAL district.
-- CRITICAL: representing_city='Tualatin' is set INLINE on every office INSERT (Hillsboro/Tigard
--           D-11 improvement) so the community banner derives correctly at first browse -- no
--           follow-up backfill migration needed.
-- CRITICAL: geo_id is '4174950' -- the CORRECTED value re-confirmed at Wave-0 (Probe A1/A2). The
--           originally-stated ROADMAP/CONTEXT value returns 0 rows against essentials.geofence_
--           boundaries and must never appear anywhere in this file.
-- CRITICAL: post-verification below applies the WR-01 fix (independent geofence-presence
--           assertion + canonical section-split query), not the dead same-transaction gate
--           inherited from the Beaverton/Hillsboro template (which cannot ever fail by
--           construction, since the same transaction both creates and checks for the districts).

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE EXCEPTION if the Tualatin government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Tualatin, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1169 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- TUALATIN (geo_id='4174950')
-- 7 officials: Mayor Frank Bubenik (elected) + 6 numbered Council Positions (all elected)
-- =============================================================================

-- Step 1: Government row
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Tualatin, Oregon, US',
       'LOCAL', 'OR', 'Tualatin', '4174950'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Tualatin, Oregon, US'
);

-- Step 2: City Council chamber (generated identifier column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Tualatin City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Tualatin, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Tualatin, Oregon, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — citywide)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4174950', 'Tualatin (Mayor, Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4174950' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- Step 4: LOCAL at-large district (all 6 numbered Council Positions share this — the position
-- numbers are seat labels on the office title, NOT separate districts; no ward geography)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4174950', 'Tualatin (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4174950' AND district_type = 'LOCAL' AND state = 'or'
);

-- Step 5: Mayor Frank Bubenik (-4174951) — directly elected citywide, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Frank Bubenik', 'Frank', 'Bubenik', NULL,
          true, false, false, true, -4174951)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Mayor', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council Member Position 1 María Reyes (-4174952) — elected, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'María Reyes', 'María', 'Reyes', NULL,
          true, false, false, true, -4174952)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 1)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Council Member Position 2 Christen Sacco (-4174953) — elected, term through Dec 31, 2028.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christen Sacco', 'Christen', 'Sacco', NULL,
          true, false, false, true, -4174953)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 2)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Council Member Position 3 Bridget Brooks (-4174954) — elected, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bridget Brooks', 'Bridget', 'Brooks', NULL,
          true, false, false, true, -4174954)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 3)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Council Member Position 4 Cyndy Hillier (-4174955) — elected, term through Dec 31, 2028.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cyndy Hillier', 'Cyndy', 'Hillier', NULL,
          true, false, false, true, -4174955)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 4)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Council Member Position 5 Octavio Gonzalez (-4174956) — elected, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Octavio Gonzalez', 'Octavio', 'Gonzalez', NULL,
          true, false, false, true, -4174956)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 5)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Council Member Position 6 Valerie Pratt (-4174957) — holds the annually-elected
-- Council President title. Originally APPOINTED Aug 2019 to fill a vacancy, but her CURRENT
-- term (Jan 2025-Dec 2028) is by ELECTION (elected 2020, reelected 2024) — is_appointed=false is
-- correct for her present seating. Council President is a title on her seat, NOT a separate
-- office row. ONE office row only.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Valerie Pratt', 'Valerie', 'Pratt', NULL,
          true, false, false, true, -4174957)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tualatin, Oregon, US')),
       p.id,
       'Council Member (Position 6)', 'OR', 'Tualatin', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4174950'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Tualatin officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4174951,-4174952,-4174953,-4174954,-4174955,-4174956,-4174957
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block — WR-01 FIX applied
-- Raises EXCEPTION on any failure — rolls back the transaction
-- Gates: (a) gov=1  (b) office=7
--        (c) INDEPENDENT geofence-presence assertion (not the dead same-transaction gate) —
--            this is the exact check that would have caught the wrong-geo_id phantom-seed error
--        (d) canonical section-split query (GROUP BY / HAVING) = 0
--        (e) office_id back-fill nulls=0
--        (f) representing_city='Tualatin' set inline on all 7 offices
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
  v_repcity_count  INTEGER;
  v_geofence_count INTEGER;
BEGIN

  -- Gate (a): Tualatin government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Tualatin, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Tualatin gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): Tualatin offices linked to LOCAL/LOCAL_EXEC districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4174950' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Tualatin office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): WR-01 FIX — independent geofence-presence assertion (not the same-transaction
  -- "created it then checked for its absence" dead gate inherited from the Beaverton/Hillsboro
  -- template). This is the exact check that catches the phantom-seed risk of a wrong geo_id.
  SELECT COUNT(*) INTO v_geofence_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '4174950' AND mtfcc = 'G4110';
  IF v_geofence_count < 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: no G4110 geofence row found for geo_id 4174950';
  END IF;

  -- Gate (d): WR-01 FIX — canonical section-split query (GROUP BY / HAVING), independent of the
  -- INSERTs above
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '4174950'
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows', v_split_count;
  END IF;

  -- Gate (e): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4174951,-4174952,-4174953,-4174954,-4174955,-4174956,-4174957
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  -- Gate (f), Tualatin-specific: representing_city set inline (no backfill mig needed)
  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4174957 AND -4174951
    AND o.representing_city = 'Tualatin';
  IF v_repcity_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Tualatin offices have representing_city=Tualatin', v_repcity_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Tualatin gov=1, offices=7, geofence>=1, section-split=0, office_id nulls=0, representing_city=7';
END $$;


-- =============================================================================
-- Supabase migration ledger entry
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1169')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- Migration 1288: Pima County government + Board of Supervisors chamber + 5 LOCAL X0019 districts + 5 supervisors + offices
--
-- Phase 193 (PIMA-02) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds Pima County Board of Supervisors under geo_id='04019'.
--   - 1 government row: 'Pima County, Arizona, US' (type='County', state='AZ' uppercase, geo_id='04019')
--     STANDALONE — NOT nested under State of Arizona; no parent government linkage.
--   - 1 chamber row: 'Board of Supervisors'
--     (name_formal='Pima County Board of Supervisors', official_count=5)
--   - 5 LOCAL district rows: geo_id='pima-az-supervisor-district-1'..'-5',
--     district_type='LOCAL', state='az' (lowercase), mtfcc='X0019'
--     (pre-flight asserts >=5 X0019 geofences were loaded first by the Plan 01 loader script)
--   - 5 politicians: Supervisors D1-D5 (-4007001..-4007005)
--       -4007001 Rex Scott          (District 1)
--       -4007002 Dr. Matt Heinz     (District 2)
--       -4007003 Jennifer Allen     (District 3 — 2026 Chair, title annotation on her seat)
--       -4007004 Steve Christy      (District 4)
--       -4007005 Andrés Cano        (District 5 — is_appointed=true, appointed Apr 2025)
--   - Each supervisor office links to its OWN LOCAL X0019 district — per-district routing.
--   - office_id back-fill on all 5 politicians.
--
-- Chair modeling (D-02, by-district relabel pattern): the 2026 Chair (Jennifer Allen, D3) is
-- surfaced ONLY via a TITLE ANNOTATION on her existing D3 supervisor seat
-- (title='Supervisor, District 3 (Chair)'). There is NO separate 6th Chair office and the Chair is
-- NOT separately elected (board-selected annually, rotational — informational). role_canonical stays
-- NULL on all 5 — the Chair distinction lives in the D3 title string, matching the rotational-Mayor
-- precedent. The other four carry plain 'Supervisor, District N' with no marker. The annotation
-- rotates annually; the Task 2 roster checkpoint re-confirms the chair before apply.
--
-- CRITICAL: the auto-generated column on essentials.chambers must never appear in the INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'az' (LOWERCASE) for LOCAL type to match routing queries.
--   Using uppercase 'AZ' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'AZ' (uppercase) and offices.representing_state = 'AZ' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.
-- CRITICAL Pitfall 2: geo_id='04019' is a 3-WAY collision (COUNTY + STATE_UPPER SD-19 + STATE_LOWER
--   HD-19). This migration NEVER inserts or joins an office to the bare geo_id='04019' row. Every
--   office↔district join is scoped district_type='LOCAL' AND mtfcc='X0019' AND state='az'.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Pima County, Arizona, US') > 0 THEN
    RAISE NOTICE 'Pima County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Pima County, Arizona, US)
-- type='County' matches Clark/Washington County precedents.
-- state='AZ' uppercase (governments table convention).
-- STANDALONE — no government_id/parent linkage to State of Arizona.
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Pima County, Arizona, US',
       'County', 'AZ', NULL, '04019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Pima County, Arizona, US'
);

-- =============================================================================
-- Step 2: Board of Supervisors chamber
-- CRITICAL: the auto-generated column is GENERATED ALWAYS — never include in INSERT column list.
-- Body name: 'Board of Supervisors' (verified pima.gov).
-- official_count=5 (5 by-district supervisors).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of Supervisors',
       'Pima County Board of Supervisors',
       (SELECT id FROM essentials.governments WHERE name = 'Pima County, Arizona, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Supervisors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Pima County, Arizona, US')
);

-- =============================================================================
-- Step 3: Pre-flight geofence assertion + 5 LOCAL X0019 district rows
-- The pre-flight asserts that the Plan 01 loader ran first (>=5 X0019 geofences).
-- state='az' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'az').
-- NEVER insert or reference the bare COUNTY geo_id='04019' row (Pitfall 2 — 3-way collision).
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'az' AND mtfcc = 'X0019') < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 5 X0019 geofences found — run load-pima-supervisor-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- LOCAL district for Supervisor District 1 (Rex Scott)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'pima-az-supervisor-district-1',
       'Pima County Supervisor District 1', 'X0019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'pima-az-supervisor-district-1' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Supervisor District 2 (Dr. Matt Heinz)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'pima-az-supervisor-district-2',
       'Pima County Supervisor District 2', 'X0019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'pima-az-supervisor-district-2' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Supervisor District 3 (Jennifer Allen — 2026 Chair)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'pima-az-supervisor-district-3',
       'Pima County Supervisor District 3', 'X0019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'pima-az-supervisor-district-3' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Supervisor District 4 (Steve Christy)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'pima-az-supervisor-district-4',
       'Pima County Supervisor District 4', 'X0019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'pima-az-supervisor-district-4' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Supervisor District 5 (Andrés Cano)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'pima-az-supervisor-district-5',
       'Pima County Supervisor District 5', 'X0019'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'pima-az-supervisor-district-5' AND district_type = 'LOCAL' AND state = 'az'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Supervisors D1-D5)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party stored (antipartisan — never displayed).
-- is_appointed_position=false on all 5 offices; representing_state='AZ' uppercase.
-- role_canonical NULL on all 5 — the Chair distinction lives ONLY in the D3 title annotation.
-- is_active/is_incumbent=true, is_vacant=false on all 5 politicians.
-- Cano (D5) ONLY: politician is_appointed=true (Apr 2025 appointment); office is_appointed_position
--   stays false. The other 4 politicians: is_appointed=false.
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians;
--             WHERE NOT EXISTS (district_id, politician_id) guard on offices.
-- Each office links to its OWN LOCAL X0019 district — never the bare COUNTY 04019 row (Pitfall 2).
-- =============================================================================

-- BLOCK 1: Supervisor District 1 Rex Scott (-4007001)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rex Scott', 'Rex', 'Scott', 'Democratic',
          true, false, false, true, -4007001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Supervisors'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Pima County, Arizona, US')),
       p.id,
       'Supervisor, District 1', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'pima-az-supervisor-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0019'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Supervisor District 2 Dr. Matt Heinz (-4007002)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Matt Heinz', 'Matt', 'Heinz', 'Democratic',
          true, false, false, true, -4007002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Supervisors'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Pima County, Arizona, US')),
       p.id,
       'Supervisor, District 2', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'pima-az-supervisor-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0019'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Supervisor District 3 Jennifer Allen (-4007003) [2026 Chair — title annotation on seat]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Allen', 'Jennifer', 'Allen', 'Democratic',
          true, false, false, true, -4007003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Supervisors'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Pima County, Arizona, US')),
       p.id,
       'Supervisor, District 3 (Chair)', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'pima-az-supervisor-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0019'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Supervisor District 4 Steve Christy (-4007004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Christy', 'Steve', 'Christy', 'Republican',
          true, false, false, true, -4007004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Supervisors'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Pima County, Arizona, US')),
       p.id,
       'Supervisor, District 4', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'pima-az-supervisor-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0019'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Supervisor District 5 Andrés Cano (-4007005) [is_appointed=true — appointed Apr 2025]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andrés Cano', 'Andrés', 'Cano', 'Democratic',
          true, true, false, true, -4007005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of Supervisors'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Pima County, Arizona, US')),
       p.id,
       'Supervisor, District 5', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'pima-az-supervisor-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0019'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Pima County supervisors.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4007005 AND -4007001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices joined to LOCAL X0019 districts must be exactly 5
-- Gate (c): each of the 5 LOCAL districts holds exactly 1 office (no HAVING count<>1 row)
-- Gate (d): is_appointed=true count among the 5 politicians = exactly 1 (Cano)
-- Gate (e): section-split — 0 offices reachable via these 5 districts under a NON-Pima government
-- Gate (f): exactly 1 office carries a '(Chair)' title annotation AND it is the -4007003 (D3) seat
-- =============================================================================
DO $$
DECLARE
  v_gov_count       INTEGER;
  v_office_count    INTEGER;
  v_multi_office    INTEGER;
  v_appointed_count INTEGER;
  v_split_count     INTEGER;
  v_chair_count     INTEGER;
  v_chair_extid     BIGINT;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'Pima County, Arizona, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Pima County government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices on LOCAL X0019 supervisor districts = 5
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'pima-az-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'az'
    AND d.mtfcc = 'X0019';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 supervisor offices on LOCAL X0019 districts, found %', v_office_count;
  END IF;

  -- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
  SELECT COUNT(*) INTO v_multi_office
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id LIKE 'pima-az-supervisor-district-%'
      AND d.district_type = 'LOCAL'
      AND d.state = 'az'
      AND d.mtfcc = 'X0019'
    GROUP BY o.district_id
    HAVING COUNT(*) <> 1
  ) x;

  IF v_multi_office <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % LOCAL district(s) do not hold exactly 1 office', v_multi_office;
  END IF;

  -- Gate (d): exactly 1 appointed politician (Cano) among the 5
  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4007005 AND -4007001
    AND is_appointed;

  IF v_appointed_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 appointed supervisor (Cano), found %', v_appointed_count;
  END IF;

  -- Gate (e): section-split — 0 offices reachable via these 5 districts under any NON-Pima government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id LIKE 'pima-az-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'az'
    AND d.mtfcc = 'X0019'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'Pima County, Arizona, US');

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Pima government', v_split_count;
  END IF;

  -- Gate (f): exactly 1 office carries a '(Chair)' annotation AND it is the D3/-4007003 seat
  SELECT COUNT(*) INTO v_chair_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'pima-az-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'az'
    AND d.mtfcc = 'X0019'
    AND o.title LIKE '%(Chair)%';

  IF v_chair_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with a (Chair) annotation, found %', v_chair_count;
  END IF;

  SELECT p.external_id INTO v_chair_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id LIKE 'pima-az-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'az'
    AND d.mtfcc = 'X0019'
    AND o.title LIKE '%(Chair)%';

  IF v_chair_extid <> -4007003 THEN
    RAISE EXCEPTION 'Post-verification FAILED: (Chair) annotation is on external_id % — expected -4007003 (Jennifer Allen, D3)', v_chair_extid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, offices=%, appointed=%, split=%, chair_on=%',
    v_gov_count, v_office_count, v_appointed_count, v_split_count, v_chair_extid;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- Disk-MAX authoritative (Pitfall 5): on-disk MAX = 1287, so this is 1288 (ledger-MAX is 1286).
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1288', 'pima_county_board_of_supervisors')
ON CONFLICT (version) DO NOTHING;

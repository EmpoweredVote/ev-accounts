-- Migration 1314: Riverside County government + Board of Supervisors chamber + 5 LOCAL X0021 districts + 5 supervisors + offices
--
-- Phase 201 Plan 02 (CV-01) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds Riverside County Board of Supervisors under geo_id='06065'.
--   - 1 government row: 'Riverside County, California, US' (type='County', state='CA' uppercase, geo_id='06065')
--     STANDALONE — NOT nested under State of California; no parent government linkage.
--   - 1 chamber row: 'Board of Supervisors'
--     (name_formal='Riverside County Board of Supervisors', official_count=5)
--   - 5 LOCAL district rows: geo_id='riverside-ca-supervisor-district-1'..'-5',
--     district_type='LOCAL', state='ca' (lowercase), mtfcc='X0021'
--     (pre-flight asserts >=5 X0021 geofences were loaded first by the Plan 01 loader script)
--   - 5 politicians: Supervisors D1-D5 (-4010001..-4010005)
--       -4010001 Jose Medina              (District 1)
--       -4010002 Karen Spiegel            (District 2 — 2026 Chair, title annotation on her seat)
--       -4010003 Chuck Washington         (District 3)
--       -4010004 V. Manuel "Manny" Perez  (District 4)
--       -4010005 Dr. Yxstian Gutierrez    (District 5)
--   - Each supervisor office links to its OWN LOCAL X0021 district — per-district routing.
--   - office_id back-fill on all 5 politicians.
--
-- Board-only (D-01): no constitutional-officer office (Sheriff/DA/Assessor deferred). Exactly 5
-- offices, one 'Board of Supervisors' chamber.
--
-- Chair modeling (D-02, by-district relabel pattern): the 2026 Chair (Karen Spiegel, D2) is
-- surfaced ONLY via a TITLE ANNOTATION on her existing D2 supervisor seat
-- (title='Supervisor, District 2 (Chair)'). There is NO separate 6th Chair office and the Chair is
-- NOT separately elected (board-selected annually, rotational — informational). role_canonical stays
-- NULL on all 5 — the Chair distinction lives in the D2 title string, matching the rotational-Mayor
-- precedent (Pima County / Clark County). The other four carry plain 'Supervisor, District N' with
-- no marker. The annotation rotates annually; the Task 2 roster checkpoint re-confirms the chair
-- before apply — June-2026 certification pending.
--
-- No appointee in recon (contrast Pima's Cano/D5): all 5 politicians is_appointed=false;
-- gate (d) below asserts appointed-count = 0 among the 5 (adjust only if the Task 2 roster
-- checkpoint finds an appointment before apply).
--
-- CRITICAL: the auto-generated `slug` column on essentials.chambers must never appear in the INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'ca' (LOWERCASE) for LOCAL type to match routing queries.
--   Using uppercase 'CA' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'CA' (uppercase) and offices.representing_state = 'CA' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.
-- CRITICAL: no known geo_id='06065' collision was found in existing migrations (unlike Pima's 3-way
--   04019 collision), but this migration NEVER inserts or joins an office to a bare geo_id='06065'
--   row regardless — every office↔district join is scoped district_type='LOCAL' AND mtfcc='X0021'
--   AND state='ca', and the pre-existing COUNTY G4020 06065 boundary row is never touched.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Riverside County, California, US') > 0 THEN
    RAISE NOTICE 'Riverside County government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (Riverside County, California, US)
-- type='County' matches Pima/Clark/Washington County precedents.
-- state='CA' uppercase (governments table convention).
-- STANDALONE — no government_id/parent linkage to State of California.
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Riverside County, California, US',
       'County', 'CA', NULL, '06065'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Riverside County, California, US'
);

-- =============================================================================
-- Step 2: Board of Supervisors chamber
-- CRITICAL: the auto-generated `slug` column is GENERATED ALWAYS — never include in INSERT column list.
-- Body name: 'Board of Supervisors'.
-- official_count=5 (5 by-district supervisors).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of Supervisors',
       'Riverside County Board of Supervisors',
       (SELECT id FROM essentials.governments WHERE name = 'Riverside County, California, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Supervisors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Riverside County, California, US')
);

-- =============================================================================
-- Step 3: Pre-flight geofence assertion + 5 LOCAL X0021 district rows
-- The pre-flight asserts that the Plan 01 loader ran first (>=5 X0021 geofences).
-- state='ca' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'ca').
-- NEVER insert or reference the bare COUNTY geo_id='06065' row.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'ca' AND mtfcc = 'X0021') < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 5 X0021 geofences found — run load-riverside-supervisor-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- LOCAL district for Supervisor District 1 (Jose Medina)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'riverside-ca-supervisor-district-1',
       'Riverside County Supervisor District 1', 'X0021'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'riverside-ca-supervisor-district-1' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Supervisor District 2 (Karen Spiegel — 2026 Chair)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'riverside-ca-supervisor-district-2',
       'Riverside County Supervisor District 2', 'X0021'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'riverside-ca-supervisor-district-2' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Supervisor District 3 (Chuck Washington)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'riverside-ca-supervisor-district-3',
       'Riverside County Supervisor District 3', 'X0021'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'riverside-ca-supervisor-district-3' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Supervisor District 4 (V. Manuel "Manny" Perez)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'riverside-ca-supervisor-district-4',
       'Riverside County Supervisor District 4', 'X0021'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'riverside-ca-supervisor-district-4' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Supervisor District 5 (Dr. Yxstian Gutierrez)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'riverside-ca-supervisor-district-5',
       'Riverside County Supervisor District 5', 'X0021'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'riverside-ca-supervisor-district-5' AND district_type = 'LOCAL' AND state = 'ca'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Supervisors D1-D5)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party stored (antipartisan — never displayed).
-- is_appointed_position=false on all 5 offices; representing_state='CA' uppercase.
-- role_canonical NULL on all 5 — the Chair distinction lives ONLY in the D2 title annotation.
-- is_active/is_incumbent=true, is_vacant=false, is_appointed=false on all 5 politicians (no
-- appointee flagged in recon — re-verify at the Task 2 roster checkpoint before apply).
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians;
--             WHERE NOT EXISTS (district_id, politician_id) guard on offices.
-- Each office links to its OWN LOCAL X0021 district — never the bare COUNTY 06065 row.
-- =============================================================================

-- BLOCK 1: Supervisor District 1 Jose Medina (-4010001)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jose Medina', 'Jose', 'Medina', 'Democratic',
          true, false, false, true, -4010001)
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
                               WHERE name = 'Riverside County, California, US')),
       p.id,
       'Supervisor, District 1', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'riverside-ca-supervisor-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0021'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Supervisor District 2 Karen Spiegel (-4010002) [2026 Chair — title annotation on seat]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Spiegel', 'Karen', 'Spiegel', 'Republican',
          true, false, false, true, -4010002)
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
                               WHERE name = 'Riverside County, California, US')),
       p.id,
       'Supervisor, District 2 (Chair)', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'riverside-ca-supervisor-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0021'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Supervisor District 3 Chuck Washington (-4010003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chuck Washington', 'Chuck', 'Washington', 'Republican',
          true, false, false, true, -4010003)
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
                               WHERE name = 'Riverside County, California, US')),
       p.id,
       'Supervisor, District 3', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'riverside-ca-supervisor-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0021'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Supervisor District 4 V. Manuel "Manny" Perez (-4010004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'V. Manuel "Manny" Perez', 'Manuel', 'Perez', 'Democratic',
          true, false, false, true, -4010004)
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
                               WHERE name = 'Riverside County, California, US')),
       p.id,
       'Supervisor, District 4', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'riverside-ca-supervisor-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0021'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Supervisor District 5 Dr. Yxstian Gutierrez (-4010005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Yxstian Gutierrez', 'Yxstian', 'Gutierrez', 'Democratic',
          true, false, false, true, -4010005)
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
                               WHERE name = 'Riverside County, California, US')),
       p.id,
       'Supervisor, District 5', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'riverside-ca-supervisor-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0021'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Riverside County supervisors.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4010005 AND -4010001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices joined to LOCAL X0021 districts must be exactly 5
-- Gate (c): each of the 5 LOCAL districts holds exactly 1 office (no HAVING count<>1 row)
-- Gate (d): is_appointed=true count among the 5 politicians = exactly 0 (no appointee per recon)
-- Gate (e): section-split — 0 offices reachable via these 5 districts under a NON-Riverside government
-- Gate (f): exactly 1 office carries a '(Chair)' title annotation AND it is the -4010002 (D2) seat
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
  WHERE name = 'Riverside County, California, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 Riverside County government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices on LOCAL X0021 supervisor districts = 5
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'riverside-ca-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0021';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 supervisor offices on LOCAL X0021 districts, found %', v_office_count;
  END IF;

  -- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
  SELECT COUNT(*) INTO v_multi_office
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id LIKE 'riverside-ca-supervisor-district-%'
      AND d.district_type = 'LOCAL'
      AND d.state = 'ca'
      AND d.mtfcc = 'X0021'
    GROUP BY o.district_id
    HAVING COUNT(*) <> 1
  ) x;

  IF v_multi_office <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % LOCAL district(s) do not hold exactly 1 office', v_multi_office;
  END IF;

  -- Gate (d): exactly 0 appointed politicians among the 5 (no appointee per recon)
  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4010005 AND -4010001
    AND is_appointed;

  IF v_appointed_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 0 appointed supervisors, found %', v_appointed_count;
  END IF;

  -- Gate (e): section-split — 0 offices reachable via these 5 districts under any NON-Riverside government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id LIKE 'riverside-ca-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0021'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'Riverside County, California, US');

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Riverside government', v_split_count;
  END IF;

  -- Gate (f): exactly 1 office carries a '(Chair)' annotation AND it is the D2/-4010002 seat
  SELECT COUNT(*) INTO v_chair_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'riverside-ca-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0021'
    AND o.title LIKE '%(Chair)%';

  IF v_chair_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with a (Chair) annotation, found %', v_chair_count;
  END IF;

  SELECT p.external_id INTO v_chair_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id LIKE 'riverside-ca-supervisor-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0021'
    AND o.title LIKE '%(Chair)%';

  IF v_chair_extid <> -4010002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: (Chair) annotation is on external_id % — expected -4010002 (Karen Spiegel, D2)', v_chair_extid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, offices=%, appointed=%, split=%, chair_on=%',
    v_gov_count, v_office_count, v_appointed_count, v_split_count, v_chair_extid;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- Disk-MAX authoritative: on-disk MAX = 1313, so this is 1314.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1314', 'riverside_county_board_of_supervisors')
ON CONFLICT (version) DO NOTHING;

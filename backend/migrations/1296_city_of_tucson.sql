-- Migration 1296: City of Tucson government + City Council chamber + 6 LOCAL X0020 ward districts
--                  + 1 NEW LOCAL_EXEC G4110 Mayor district + 7 politicians/offices
--
-- Phase 194 (TUC-02) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds the greenfield City of Tucson under geo_id='0477000'.
--   - 1 government row: 'City of Tucson, Arizona, US' (type='City', state='AZ' uppercase, geo_id='0477000')
--     GREENFIELD — no City of Tucson government row exists today; no parent linkage.
--   - 1 chamber row: 'City Council' (name_formal='Tucson City Council', official_count=7)
--   - 6 LOCAL district rows: geo_id='tucson-az-ward-1'..'-6', district_type='LOCAL', state='az'
--     (lowercase), mtfcc='X0020' (pre-flight asserts >=6 X0020 geofences loaded by Plan 01's loader).
--   - 1 NEW LOCAL_EXEC district row: geo_id='0477000', district_type='LOCAL_EXEC', state='az'
--     (lowercase), mtfcc='G4110' — reuses the ALREADY-LIVE Phase-190 whole-city geofence (Pitfall 5:
--     the Mayor's office cannot attach to anything otherwise; Pima never needed this row).
--   - 7 politicians/offices (-4008001..-4008007): an at-large Mayor + 6 by-ward council members.
--       -4008001 Regina Romero     → Mayor                                   (LOCAL_EXEC / G4110 / 0477000)
--       -4008002 Lane Santa Cruz   → Council Member, Ward 1 (Vice Mayor)     (LOCAL / X0020 / tucson-az-ward-1)
--       -4008003 Paul Cunningham   → Council Member, Ward 2                  (tucson-az-ward-2)
--       -4008004 Kevin Dahl        → Council Member, Ward 3                  (tucson-az-ward-3)
--       -4008005 Nikki Lee         → Council Member, Ward 4                  (tucson-az-ward-4)
--       -4008006 Selina Barajas    → Council Member, Ward 5                  (tucson-az-ward-5)
--       -4008007 Miranda Schubert  → Council Member, Ward 6                  (tucson-az-ward-6)
--   - office_id back-fill on all 7 politicians.
--
-- Vice Mayor modeling (D-05, title-annotation pattern, SAME shape Phase 193 used for the Pima Chair):
--   The Vice Mayor (Lane Santa Cruz, Ward 1) is surfaced ONLY via a TITLE ANNOTATION on her existing
--   Ward 1 seat (title='Council Member, Ward 1 (Vice Mayor)'). There is NO separate 8th Vice Mayor
--   office. role_canonical stays NULL on all 7 — the distinction lives in the Ward 1 title string. The
--   other five wards carry plain 'Council Member, Ward N' with no marker; the Mayor carries 'Mayor'.
--   The Vice Mayor rotates annually (council-selected each December); the Task 2 roster checkpoint
--   re-confirms the current holder before apply.
--
-- D-04: all 7 recorded as 'Democratic' in politicians.party (Tucson runs partisan municipal
--   elections) — stored, NEVER displayed (antipartisan; no special-casing).
--
-- CRITICAL: the auto-generated slug column on essentials.chambers must never appear in the INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'az' (LOWERCASE) for LOCAL/LOCAL_EXEC types to match routing queries.
--   Using uppercase 'AZ' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'AZ' (uppercase) and offices.representing_state = 'AZ' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.
-- CRITICAL Pitfall 7: geo_id='0477000' also appears in geofence_boundaries with state stored as FIPS
--   '04' (an unrelated convention). Every office↔district join is scoped by district_type + mtfcc +
--   state='az' — the Mayor join scopes LOCAL_EXEC/G4110/az; each ward join scopes LOCAL/X0020/az.
--   This migration NEVER joins an office to a bare geo_id.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Tucson, Arizona, US') > 0 THEN
    RAISE NOTICE 'City of Tucson government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (City of Tucson, Arizona, US) — greenfield
-- type='City'; state='AZ' uppercase (governments table convention).
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Tucson, Arizona, US',
       'City', 'AZ', NULL, '0477000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Tucson, Arizona, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- CRITICAL: the auto-generated slug column is GENERATED ALWAYS — never include in INSERT column list.
-- official_count=7 (at-large Mayor + 6 by-ward council members).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Tucson City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Tucson, Arizona, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Tucson, Arizona, US')
);

-- =============================================================================
-- Step 3: Pre-flight geofence assertion + district rows (TWO kinds)
-- Pre-flight asserts Plan 01's loader ran first (>=6 X0020 geofences).
-- state='az' LOWERCASE — matches routing query WHERE d.state = $1 (geocoder returns lowercase 'az').
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'az' AND mtfcc = 'X0020') < 6 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 6 X0020 geofences found — run load-tucson-ward-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- (1) 6 LOCAL ward districts (X0020)
-- LOCAL district for Ward 1 (Lane Santa Cruz — Vice Mayor)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-1', 'Tucson Ward 1', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-1' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Ward 2 (Paul Cunningham)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-2', 'Tucson Ward 2', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-2' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Ward 3 (Kevin Dahl)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-3', 'Tucson Ward 3', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-3' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Ward 4 (Nikki Lee)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-4', 'Tucson Ward 4', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-4' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Ward 5 (Selina Barajas)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-5', 'Tucson Ward 5', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-5' AND district_type = 'LOCAL' AND state = 'az'
);

-- LOCAL district for Ward 6 (Miranda Schubert)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', 'tucson-az-ward-6', 'Tucson Ward 6', 'X0020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'tucson-az-ward-6' AND district_type = 'LOCAL' AND state = 'az'
);

-- (2) 1 NEW LOCAL_EXEC Mayor district (G4110) — Pitfall 5.
-- Reuses the existing Phase-190 whole-city geofence (geo_id='0477000') — NO geometry work.
-- Use `label` (there is no name_formal column on districts).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'az', '0477000', 'City of Tucson (Mayor)', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0477000' AND district_type = 'LOCAL_EXEC' AND state = 'az'
);

-- =============================================================================
-- Step 4: Politicians + offices (7 blocks — Mayor + Wards 1-6)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party stored (antipartisan — never displayed).
-- is_appointed_position=false on all 7 offices; representing_state='AZ' uppercase.
-- role_canonical NULL on all 7 — the Vice Mayor distinction lives ONLY in the Ward 1 title annotation.
-- is_active/is_incumbent=true, is_vacant=false, is_appointed=false on all 7 politicians (all elected).
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians;
--             WHERE NOT EXISTS (district_id, politician_id) guard on offices.
-- Mayor joins LOCAL_EXEC/G4110/0477000; each ward joins LOCAL/X0020/tucson-az-ward-N — never bare geo_id.
-- =============================================================================

-- BLOCK 1: Mayor Regina Romero (-4008001) [at-large, LOCAL_EXEC / G4110 / 0477000]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Regina Romero', 'Regina', 'Romero', 'Democratic',
          true, false, false, true, -4008001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0477000'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Ward 1 Lane Santa Cruz (-4008002) [Vice Mayor — title annotation on this seat]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lane Santa Cruz', 'Lane', 'Santa Cruz', 'Democratic',
          true, false, false, true, -4008002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 1 (Vice Mayor)', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Ward 2 Paul Cunningham (-4008003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Cunningham', 'Paul', 'Cunningham', 'Democratic',
          true, false, false, true, -4008003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 2', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Ward 3 Kevin Dahl (-4008004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Dahl', 'Kevin', 'Dahl', 'Democratic',
          true, false, false, true, -4008004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 3', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Ward 4 Nikki Lee (-4008005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nikki Lee', 'Nikki', 'Lee', 'Democratic',
          true, false, false, true, -4008005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 4', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Ward 5 Selina Barajas (-4008006) [newly seated Dec 2025, replacing Fimbres — do NOT seed Fimbres]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Selina Barajas', 'Selina', 'Barajas', 'Democratic',
          true, false, false, true, -4008006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 5', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Ward 6 Miranda Schubert (-4008007) [newly seated Dec 2025, replacing Kozachik — do NOT seed Kozachik]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Miranda Schubert', 'Miranda', 'Schubert', 'Democratic',
          true, false, false, true, -4008007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Tucson, Arizona, US')),
       p.id,
       'Council Member, Ward 6', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'tucson-az-ward-6'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'X0020'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 7 Tucson officials.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4008007 AND -4008001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count must be exactly 1
-- Gate (b): offices joined to the 7 Tucson districts (6 LOCAL X0020 + 1 LOCAL_EXEC G4110) = 7
-- Gate (c): each of the 7 districts holds exactly 1 office (no HAVING count<>1 row)
-- Gate (d): the NEW LOCAL_EXEC/G4110/0477000/az districts row exists (Pitfall 5)
-- Gate (e): section-split — 0 offices reachable via these 7 districts under a NON-Tucson government
-- Gate (f): exactly 1 office carries a '(Vice Mayor)' annotation
-- Gate (g): that annotation is on the -4008002 (Ward 1, Santa Cruz) seat
-- (No is_appointed gate — all 7 Tucson officials are elected, not appointed.)
-- =============================================================================
DO $$
DECLARE
  v_gov_count    INTEGER;
  v_office_count INTEGER;
  v_multi_office INTEGER;
  v_exec_count   INTEGER;
  v_split_count  INTEGER;
  v_vm_count     INTEGER;
  v_vm_extid     BIGINT;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Tucson, Arizona, US' AND geo_id = '0477000' AND type = 'City';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Tucson government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices on the 7 Tucson districts = 7
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE (d.geo_id LIKE 'tucson-az-ward-%' AND d.district_type = 'LOCAL' AND d.state = 'az' AND d.mtfcc = 'X0020')
     OR (d.geo_id = '0477000' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'az' AND d.mtfcc = 'G4110');

  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 Tucson offices on the ward + Mayor districts, found %', v_office_count;
  END IF;

  -- Gate (c): each of the 7 districts holds exactly 1 office
  SELECT COUNT(*) INTO v_multi_office
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE (d.geo_id LIKE 'tucson-az-ward-%' AND d.district_type = 'LOCAL' AND d.state = 'az' AND d.mtfcc = 'X0020')
       OR (d.geo_id = '0477000' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'az' AND d.mtfcc = 'G4110')
    GROUP BY o.district_id
    HAVING COUNT(*) <> 1
  ) x;

  IF v_multi_office <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % Tucson district(s) do not hold exactly 1 office', v_multi_office;
  END IF;

  -- Gate (d): the NEW LOCAL_EXEC/G4110/0477000/az district row exists (Pitfall 5)
  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.districts
  WHERE geo_id = '0477000' AND district_type = 'LOCAL_EXEC' AND state = 'az' AND mtfcc = 'G4110';

  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 LOCAL_EXEC/G4110/0477000 Mayor district, found %', v_exec_count;
  END IF;

  -- Gate (e): section-split — 0 offices reachable via these 7 districts under any NON-Tucson government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE ((d.geo_id LIKE 'tucson-az-ward-%' AND d.district_type = 'LOCAL' AND d.state = 'az' AND d.mtfcc = 'X0020')
      OR (d.geo_id = '0477000' AND d.district_type = 'LOCAL_EXEC' AND d.state = 'az' AND d.mtfcc = 'G4110'))
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'City of Tucson, Arizona, US');

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Tucson government', v_split_count;
  END IF;

  -- Gate (f): exactly 1 office carries a '(Vice Mayor)' annotation
  SELECT COUNT(*) INTO v_vm_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.mtfcc IN ('X0020', 'G4110')
    AND o.title LIKE '%(Vice Mayor)%';

  IF v_vm_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with a (Vice Mayor) annotation, found %', v_vm_count;
  END IF;

  -- Gate (g): that annotation is on the Ward-1/-4008002 (Santa Cruz) seat
  SELECT p.external_id INTO v_vm_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.mtfcc IN ('X0020', 'G4110')
    AND o.title LIKE '%(Vice Mayor)%';

  IF v_vm_extid <> -4008002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: (Vice Mayor) annotation is on external_id % — expected -4008002 (Lane Santa Cruz, Ward 1)', v_vm_extid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, offices=%, exec_district=%, split=%, vice_mayor_on=%',
    v_gov_count, v_office_count, v_exec_count, v_split_count, v_vm_extid;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- Disk-MAX authoritative (Pitfall 9): on-disk MAX = 1295, so this is 1296.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1296', 'city_of_tucson')
ON CONFLICT (version) DO NOTHING;

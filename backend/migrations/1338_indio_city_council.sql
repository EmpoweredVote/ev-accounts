-- Migration 1338: City of Indio government + City Council chamber + 5 LOCAL X0023 districts + 5 councilmembers + offices
--
-- Phase 203 Plan 02 (CV-03) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds the City of Indio City Council under geo_id='0636448'.
--   - 1 government row: 'City of Indio, California, US' (type='City', state='CA' uppercase, city='Indio', geo_id='0636448')
--     STANDALONE — NOT nested under State of California; no parent government linkage.
--   - 1 chamber row: 'City Council' (name_formal='Indio City Council', official_count=5)
--   - 5 LOCAL district rows: geo_id='indio-ca-council-district-1'..'-5',
--     district_type='LOCAL', state='ca' (lowercase), mtfcc='X0023'
--     (pre-flight asserts >=5 X0023 geofences were loaded first by the Plan 01 loader script)
--   - 5 politicians: Councilmembers D1-D5 (-4012001..-4012005) — ALL net-new greenfield
--       -4012001 Glenn Miller          (District 1) — Councilmember
--       -4012002 Waymond Fermon        (District 2) — Mayor Pro Tem (rotational, title-on-seat)
--       -4012003 Elaine Holmes         (District 3) — Mayor (rotational, title-on-seat)
--       -4012004 Oscar Ortiz           (District 4) — Councilmember
--       -4012005 Benjamin Guitron IV   (District 5) — Councilmember
--   - Each councilmember office links to its OWN LOCAL X0023 district — per-district routing.
--   - office_id back-fill on all 5 politicians.
--
-- ROTATIONAL MAYOR (by-district relabel / title-on-seat pattern): Indio elects its 5-member council
-- ENTIRELY by district (adopted 2017 after CVRA, current boundaries = 2022 adopted "Map 108"); the
-- Mayor + Mayor Pro Tem are council-selected 1-year rotational roles chosen each December, NOT
-- separately elected. They are surfaced ONLY as the office TITLE on their existing district seats
-- (Holmes D3 = 'Mayor', Fermon D2 = 'Mayor Pro Tem'); the other three carry 'Councilmember'. There is
-- NO separate directly-elected Mayor office/chamber/district and official_count=5 INCLUDES the Mayor's
-- seat. Elaine Holmes was sworn in as Mayor on 2025-12-03 (KESQ / The Indio Post / City of Indio);
-- Waymond Fermon is Mayor Pro Tem — re-verified live at the Task 2 roster checkpoint (2026-07-13).
-- role_canonical stays NULL on all 5 — the Mayor/MPT distinction lives entirely in the title string.
--
-- Nonpartisan municipal office: party = NULL on all 5 (Indio council is officially nonpartisan;
-- party is antipartisan/never-displayed regardless).
--
-- No appointee in recon: all 5 politicians is_appointed=false; gate (d) below asserts appointed-count=0.
--
-- CRITICAL: the auto-generated `slug` column on essentials.chambers must never appear in the INSERT column list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'ca' (LOWERCASE) for LOCAL type to match routing queries.
--   Using uppercase 'CA' in the office WHERE clauses matches ZERO rows (silent no-op).
-- CRITICAL: governments.state = 'CA' (uppercase) and offices.representing_state = 'CA' (uppercase)
--   are table conventions / free-text labels — NOT the district join key.
-- CRITICAL: this migration NEVER inserts or joins an office to a bare geo_id='0636448' row — every
--   office↔district join is scoped district_type='LOCAL' AND mtfcc='X0023' AND state='ca', and the
--   pre-existing whole-city G4110 0636448 boundary row is never touched.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Indio, California, US') > 0 THEN
    RAISE NOTICE 'City of Indio government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (City of Indio, California, US)
-- type='City'; state='CA' uppercase (governments table convention).
-- STANDALONE — no government_id/parent linkage to State of California.
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Indio, California, US',
       'City', 'CA', 'Indio', '0636448'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Indio, California, US'
);

-- =============================================================================
-- Step 2: City Council chamber
-- CRITICAL: the auto-generated `slug` column is GENERATED ALWAYS — never include in INSERT column list.
-- Body name: 'City Council'. official_count=5 (5 by-district seats incl. the Mayor's seat).
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Indio City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Indio, California, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Indio, California, US')
);

-- =============================================================================
-- Step 3: Pre-flight geofence assertion + 5 LOCAL X0023 district rows
-- The pre-flight asserts the Plan 01 loader ran first (>=5 X0023 geofences).
-- state='ca' LOWERCASE — matches routing query (geocoder returns lowercase 'ca').
-- NEVER insert or reference the bare whole-city geo_id='0636448' row.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'ca' AND mtfcc = 'X0023') < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 5 X0023 geofences found — run load-indio-council-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- LOCAL district for Council District 1 (Glenn Miller)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'indio-ca-council-district-1',
       'Indio City Council District 1', 'X0023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'indio-ca-council-district-1' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 2 (Waymond Fermon — Mayor Pro Tem)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'indio-ca-council-district-2',
       'Indio City Council District 2', 'X0023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'indio-ca-council-district-2' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 3 (Elaine Holmes — Mayor)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'indio-ca-council-district-3',
       'Indio City Council District 3', 'X0023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'indio-ca-council-district-3' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 4 (Oscar Ortiz)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'indio-ca-council-district-4',
       'Indio City Council District 4', 'X0023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'indio-ca-council-district-4' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 5 (Benjamin Guitron IV)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'indio-ca-council-district-5',
       'Indio City Council District 5', 'X0023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'indio-ca-council-district-5' AND district_type = 'LOCAL' AND state = 'ca'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Councilmembers D1-D5)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (nonpartisan municipal / antipartisan).
-- is_appointed_position=false on all 5 offices; representing_state='CA' uppercase.
-- role_canonical NULL on all 5 — Mayor/MPT distinction lives ONLY in the title string.
-- is_active/is_incumbent=true, is_vacant=false, is_appointed=false on all 5 politicians.
-- Title set DIRECTLY at INSERT (all 5 net-new greenfield):
--   D3 Holmes='Mayor', D2 Fermon='Mayor Pro Tem', other three='Councilmember'.
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians;
--             WHERE NOT EXISTS (district_id, politician_id) guard on offices.
-- Each office links to its OWN LOCAL X0023 district — never the bare 0636448 row.
-- =============================================================================

-- BLOCK 1: Council District 1 Glenn Miller (-4012001) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Glenn Miller', 'Glenn', 'Miller', NULL,
          true, false, false, true, -4012001)
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
                               WHERE name = 'City of Indio, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'indio-ca-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0023'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Council District 2 Waymond Fermon (-4012002) — Mayor Pro Tem (rotational, title-on-seat)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Waymond Fermon', 'Waymond', 'Fermon', NULL,
          true, false, false, true, -4012002)
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
                               WHERE name = 'City of Indio, California, US')),
       p.id,
       'Mayor Pro Tem', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'indio-ca-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0023'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Council District 3 Elaine Holmes (-4012003) — Mayor (rotational, title-on-seat)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elaine Holmes', 'Elaine', 'Holmes', NULL,
          true, false, false, true, -4012003)
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
                               WHERE name = 'City of Indio, California, US')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'indio-ca-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0023'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Council District 4 Oscar Ortiz (-4012004) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Oscar Ortiz', 'Oscar', 'Ortiz', NULL,
          true, false, false, true, -4012004)
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
                               WHERE name = 'City of Indio, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'indio-ca-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0023'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Council District 5 Benjamin Guitron IV (-4012005) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Benjamin Guitron IV', 'Benjamin', 'Guitron', NULL,
          true, false, false, true, -4012005)
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
                               WHERE name = 'City of Indio, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'indio-ca-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0023'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Indio councilmembers.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4012005 AND -4012001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count = exactly 1
-- Gate (b): offices joined to LOCAL X0023 districts = exactly 5
-- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
-- Gate (d): is_appointed=true count among the 5 politicians = exactly 0
-- Gate (e): section-split — 0 offices reachable via these 5 districts under a NON-Indio government
-- Gate (f): exactly 1 office with title='Mayor' (on -4012003) AND exactly 1 with title='Mayor Pro Tem' (on -4012002)
-- =============================================================================
DO $$
DECLARE
  v_gov_count       INTEGER;
  v_office_count    INTEGER;
  v_multi_office    INTEGER;
  v_appointed_count INTEGER;
  v_split_count     INTEGER;
  v_mayor_count     INTEGER;
  v_mpt_count       INTEGER;
  v_mayor_extid     BIGINT;
  v_mpt_extid       BIGINT;
BEGIN
  -- Gate (a): government row
  SELECT COUNT(*) INTO v_gov_count
  FROM essentials.governments
  WHERE name = 'City of Indio, California, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Indio government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices on LOCAL X0023 council districts = 5
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0023';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 council offices on LOCAL X0023 districts, found %', v_office_count;
  END IF;

  -- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
  SELECT COUNT(*) INTO v_multi_office
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id LIKE 'indio-ca-council-district-%'
      AND d.district_type = 'LOCAL'
      AND d.state = 'ca'
      AND d.mtfcc = 'X0023'
    GROUP BY o.district_id
    HAVING COUNT(*) <> 1
  ) x;

  IF v_multi_office <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % LOCAL district(s) do not hold exactly 1 office', v_multi_office;
  END IF;

  -- Gate (d): exactly 0 appointed politicians among the 5
  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4012005 AND -4012001
    AND is_appointed;

  IF v_appointed_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 0 appointed councilmembers, found %', v_appointed_count;
  END IF;

  -- Gate (e): section-split — 0 offices reachable via these 5 districts under any NON-Indio government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0023'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'City of Indio, California, US');

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Indio government', v_split_count;
  END IF;

  -- Gate (f): exactly 1 title='Mayor' AND exactly 1 title='Mayor Pro Tem' across the X0023 council districts
  SELECT COUNT(*) INTO v_mayor_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0023'
    AND o.title = 'Mayor';

  SELECT COUNT(*) INTO v_mpt_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0023'
    AND o.title = 'Mayor Pro Tem';

  IF v_mayor_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Mayor, found %', v_mayor_count;
  END IF;
  IF v_mpt_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Mayor Pro Tem, found %', v_mpt_count;
  END IF;

  SELECT p.external_id INTO v_mayor_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0023'
    AND o.title = 'Mayor';

  SELECT p.external_id INTO v_mpt_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id LIKE 'indio-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0023'
    AND o.title = 'Mayor Pro Tem';

  IF v_mayor_extid <> -4012003 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor title is on external_id % — expected -4012003 (Elaine Holmes, D3)', v_mayor_extid;
  END IF;
  IF v_mpt_extid <> -4012002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Pro Tem title is on external_id % — expected -4012002 (Waymond Fermon, D2)', v_mpt_extid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, offices=%, appointed=%, split=%, mayor_on=%, mpt_on=%',
    v_gov_count, v_office_count, v_appointed_count, v_split_count, v_mayor_extid, v_mpt_extid;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- Disk MAX = 1337 → disk-next = 1338. Re-verify the real ledger MAX at apply time
-- and use MAX+1 if an interim migration consumed 1338.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1338', 'indio_city_council')
ON CONFLICT (version) DO NOTHING;

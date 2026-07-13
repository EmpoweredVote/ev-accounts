-- Migration 1329: City of Palm Springs government + City Council chamber + 5 LOCAL X0022 districts + 5 councilmembers + offices
--
-- Phase 202 Plan 02 (CV-02) — STRUCTURAL (registers in the migration ledger). Idempotent.
--
-- Purpose: Seeds the City of Palm Springs City Council under geo_id='0655254'.
--   - 1 government row: 'City of Palm Springs, California, US' (type='City', state='CA' uppercase, city='Palm Springs', geo_id='0655254')
--     STANDALONE — NOT nested under State of California; no parent government linkage.
--   - 1 chamber row: 'City Council' (name_formal='Palm Springs City Council', official_count=5)
--   - 5 LOCAL district rows: geo_id='palm-springs-ca-council-district-1'..'-5',
--     district_type='LOCAL', state='ca' (lowercase), mtfcc='X0022'
--     (pre-flight asserts >=5 X0022 geofences were loaded first by the Plan 01 loader script)
--   - 5 politicians: Councilmembers D1-D5 (-4011001..-4011005) — ALL net-new greenfield
--       -4011001 Grace Elena Garner   (District 1) — Councilmember
--       -4011002 Jeffrey Bernstein    (District 2) — Councilmember
--       -4011003 Ron deHarte          (District 3) — Councilmember
--       -4011004 Naomi Soto           (District 4) — Mayor (rotational, title-on-seat)
--       -4011005 David H. Ready       (District 5) — Mayor Pro Tem (rotational, title-on-seat)
--   - Each councilmember office links to its OWN LOCAL X0022 district — per-district routing.
--   - office_id back-fill on all 5 politicians.
--
-- ROTATIONAL MAYOR (by-district relabel / title-on-seat pattern): Palm Springs elects its 5-member
-- council ENTIRELY by district (adopted 2018 after CVRA); the Mayor + Mayor Pro Tem are council-
-- appointed 1-year rotational roles, NOT separately elected. They are surfaced ONLY as the office
-- TITLE on their existing district seats (Soto D4 = 'Mayor', Ready D5 = 'Mayor Pro Tem'); the other
-- three carry 'Councilmember'. There is NO separate directly-elected Mayor office/chamber/district and
-- official_count=5 INCLUDES the Mayor's seat. The directly-elected-mayor petition (KESQ, 2026) was
-- NOT adopted as of 2026-07-12 — re-verify at the Task 2 roster checkpoint before apply. role_canonical
-- stays NULL on all 5 — the Mayor/MPT distinction lives entirely in the title string.
--
-- Nonpartisan municipal office: party = NULL on all 5 (Palm Springs council is officially nonpartisan;
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
-- CRITICAL: this migration NEVER inserts or joins an office to a bare geo_id='0655254' row — every
--   office↔district join is scoped district_type='LOCAL' AND mtfcc='X0022' AND state='ca', and the
--   pre-existing whole-city G4110 0655254 boundary row is never touched.

BEGIN;

-- =============================================================================
-- Pre-flight: RAISE NOTICE if government row already exists (idempotency guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Palm Springs, California, US') > 0 THEN
    RAISE NOTICE 'City of Palm Springs government row already exists — skipping government INSERT (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government row (City of Palm Springs, California, US)
-- type='City'; state='CA' uppercase (governments table convention).
-- STANDALONE — no government_id/parent linkage to State of California.
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id).
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Palm Springs, California, US',
       'City', 'CA', 'Palm Springs', '0655254'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Palm Springs, California, US'
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
       'Palm Springs City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Palm Springs, California, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Palm Springs, California, US')
);

-- =============================================================================
-- Step 3: Pre-flight geofence assertion + 5 LOCAL X0022 district rows
-- The pre-flight asserts the Plan 01 loader ran first (>=5 X0022 geofences).
-- state='ca' LOWERCASE — matches routing query (geocoder returns lowercase 'ca').
-- NEVER insert or reference the bare whole-city geo_id='0655254' row.
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state).
-- =============================================================================

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE state = 'ca' AND mtfcc = 'X0022') < 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: fewer than 5 X0022 geofences found — run load-palmsprings-council-boundaries.ts before applying this migration.';
  END IF;
END $$;

-- LOCAL district for Council District 1 (Grace Elena Garner)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'palm-springs-ca-council-district-1',
       'Palm Springs City Council District 1', 'X0022'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'palm-springs-ca-council-district-1' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 2 (Jeffrey Bernstein)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'palm-springs-ca-council-district-2',
       'Palm Springs City Council District 2', 'X0022'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'palm-springs-ca-council-district-2' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 3 (Ron deHarte)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'palm-springs-ca-council-district-3',
       'Palm Springs City Council District 3', 'X0022'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'palm-springs-ca-council-district-3' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 4 (Naomi Soto — Mayor)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'palm-springs-ca-council-district-4',
       'Palm Springs City Council District 4', 'X0022'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'palm-springs-ca-council-district-4' AND district_type = 'LOCAL' AND state = 'ca'
);

-- LOCAL district for Council District 5 (David H. Ready — Mayor Pro Tem)
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ca', 'palm-springs-ca-council-district-5',
       'Palm Springs City Council District 5', 'X0022'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'palm-springs-ca-council-district-5' AND district_type = 'LOCAL' AND state = 'ca'
);

-- =============================================================================
-- Step 4: Politicians + offices (5 blocks — Councilmembers D1-D5)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (nonpartisan municipal / antipartisan).
-- is_appointed_position=false on all 5 offices; representing_state='CA' uppercase.
-- role_canonical NULL on all 5 — Mayor/MPT distinction lives ONLY in the title string.
-- is_active/is_incumbent=true, is_vacant=false, is_appointed=false on all 5 politicians.
-- Title set DIRECTLY at INSERT (Bellflower model — all 5 net-new greenfield):
--   D4 Soto='Mayor', D5 Ready='Mayor Pro Tem', other three='Councilmember'.
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians;
--             WHERE NOT EXISTS (district_id, politician_id) guard on offices.
-- Each office links to its OWN LOCAL X0022 district — never the bare 0655254 row.
-- =============================================================================

-- BLOCK 1: Council District 1 Grace Elena Garner (-4011001) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Grace Elena Garner', 'Grace', 'Garner', NULL,
          true, false, false, true, -4011001)
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
                               WHERE name = 'City of Palm Springs, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'palm-springs-ca-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0022'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Council District 2 Jeffrey Bernstein (-4011002) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeffrey Bernstein', 'Jeffrey', 'Bernstein', NULL,
          true, false, false, true, -4011002)
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
                               WHERE name = 'City of Palm Springs, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'palm-springs-ca-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0022'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Council District 3 Ron deHarte (-4011003) — Councilmember
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ron deHarte', 'Ron', 'deHarte', NULL,
          true, false, false, true, -4011003)
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
                               WHERE name = 'City of Palm Springs, California, US')),
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'palm-springs-ca-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0022'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Council District 4 Naomi Soto (-4011004) — Mayor (rotational, title-on-seat)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Naomi Soto', 'Naomi', 'Soto', NULL,
          true, false, false, true, -4011004)
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
                               WHERE name = 'City of Palm Springs, California, US')),
       p.id,
       'Mayor', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'palm-springs-ca-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0022'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: Council District 5 David H. Ready (-4011005) — Mayor Pro Tem (rotational, title-on-seat)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David H. Ready', 'David', 'Ready', NULL,
          true, false, false, true, -4011005)
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
                               WHERE name = 'City of Palm Springs, California, US')),
       p.id,
       'Mayor Pro Tem', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'palm-springs-ca-council-district-5'
  AND d.district_type = 'LOCAL'
  AND d.state = 'ca'
  AND d.mtfcc = 'X0022'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill
-- Updates politicians.office_id for all 5 Palm Springs councilmembers.
-- WHERE p.office_id IS NULL for idempotency. BETWEEN: more-negative bound first.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -4011005 AND -4011001
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block
-- Raises EXCEPTION on any failure — rolls back the transaction.
-- Gate (a): government row count = exactly 1
-- Gate (b): offices joined to LOCAL X0022 districts = exactly 5
-- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
-- Gate (d): is_appointed=true count among the 5 politicians = exactly 0
-- Gate (e): section-split — 0 offices reachable via these 5 districts under a NON-Palm-Springs government
-- Gate (f): exactly 1 office with title='Mayor' AND exactly 1 office with title='Mayor Pro Tem'
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
  WHERE name = 'City of Palm Springs, California, US';

  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 City of Palm Springs government row, found %', v_gov_count;
  END IF;

  -- Gate (b): offices on LOCAL X0022 council districts = 5
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0022';

  IF v_office_count <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 council offices on LOCAL X0022 districts, found %', v_office_count;
  END IF;

  -- Gate (c): each of the 5 LOCAL districts holds exactly 1 office
  SELECT COUNT(*) INTO v_multi_office
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
      AND d.district_type = 'LOCAL'
      AND d.state = 'ca'
      AND d.mtfcc = 'X0022'
    GROUP BY o.district_id
    HAVING COUNT(*) <> 1
  ) x;

  IF v_multi_office <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % LOCAL district(s) do not hold exactly 1 office', v_multi_office;
  END IF;

  -- Gate (d): exactly 0 appointed politicians among the 5
  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -4011005 AND -4011001
    AND is_appointed;

  IF v_appointed_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 0 appointed councilmembers, found %', v_appointed_count;
  END IF;

  -- Gate (e): section-split — 0 offices reachable via these 5 districts under any NON-Palm-Springs government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL'
    AND d.state = 'ca'
    AND d.mtfcc = 'X0022'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'City of Palm Springs, California, US');

  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Palm-Springs government', v_split_count;
  END IF;

  -- Gate (f): exactly 1 title='Mayor' AND exactly 1 title='Mayor Pro Tem' across the X0022 council districts
  SELECT COUNT(*) INTO v_mayor_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0022'
    AND o.title = 'Mayor';

  SELECT COUNT(*) INTO v_mpt_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0022'
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
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0022'
    AND o.title = 'Mayor';

  SELECT p.external_id INTO v_mpt_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id LIKE 'palm-springs-ca-council-district-%'
    AND d.district_type = 'LOCAL' AND d.state = 'ca' AND d.mtfcc = 'X0022'
    AND o.title = 'Mayor Pro Tem';

  IF v_mayor_extid <> -4011004 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor title is on external_id % — expected -4011004 (Naomi Soto, D4)', v_mayor_extid;
  END IF;
  IF v_mpt_extid <> -4011005 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor Pro Tem title is on external_id % — expected -4011005 (David H. Ready, D5)', v_mpt_extid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: gov=%, offices=%, appointed=%, split=%, mayor_on=%, mpt_on=%',
    v_gov_count, v_office_count, v_appointed_count, v_split_count, v_mayor_extid, v_mpt_extid;
END $$;

COMMIT;

-- =============================================================================
-- Step 7: Migration ledger registration (OUTSIDE the transaction)
-- Structural migration registers with the 2-column (version, name) form.
-- Disk MAX = 1328 (1328_tx_sd4_brett_ligon_seed.sql, unrelated), so disk-next = 1329.
-- Ledger-verified: version '1329' is NOT present (free) as of 2026-07-12.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1329', 'palm_springs_city_council')
ON CONFLICT (version) DO NOTHING;

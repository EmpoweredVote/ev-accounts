-- Migration 265: Maine city school board seed (Lewiston + Bangor + South Portland + Auburn + Biddeford)
-- Phase 89 Plan 02. Greenfield — no existing rows for these 5 districts.
--
-- Districts (per RESEARCH.md §TIGER File Verification):
--   Lewiston Public Schools       (geo_id='2307320', 8 members: 7 wards + 1 at-large)
--   Bangor School Department      (geo_id='2302820', 7 at-large members)
--   South Portland Public Schools (geo_id='2312330', 7 members — district + at-large mix)
--   Auburn Public Schools         (geo_id='2302610', 8 members: 5 wards + 3 at-large)
--   Biddeford Public Schools      (geo_id='2303150', 7 at-large members)
--
-- Totals: 5 govs, 5 chambers, 5 SCHOOL districts, 37 politicians, 37 offices.
--
-- CRITICAL rules (per RESEARCH.md §Common Pitfalls):
--   - districts.state = 'me' LOWERCASE (Pitfall 5; matches essentialsService.ts routing)
--   - governments.state = 'ME' UPPERCASE
--   - offices.representing_state = 'ME' UPPERCASE
--   - district_type = 'SCHOOL' (NOT 'SCHOOL_DISTRICT')
--   - slug NEVER included in chambers INSERT (GENERATED ALWAYS)
--   - All 5 G5420 geofence_boundaries rows MUST exist before this migration (run load-me-school-boundaries.ts first)
--
-- Roster reconciliation (per Task 3 verification of Open Questions 1, 2, 3):
--   Lewiston: Ward 5 VACANT (Iman Osman resigned after indictment/residency controversy; unfilled as of Jan 5 2026);
--             Ward 2 = Janet Beaudoin (confirmed Sun Journal "Beaudoin, Hird win reelection" Nov 2025)
--   South Portland: D5 VACANT (Adrian Dowling resigned April 2026); D1=Susan Rauscher [ASSUMED spsd.org blocked];
--                   At-Large Jennifer Ryan [ASSUMED]; all others confirmed (pressherald.com Dec 2025)
--   Bangor: Sara Luciano still a member (confirmed bangormaine.gov Jan 2026 minutes "Motion: Luciano Second: Okere");
--           Nov 2025 election added only Cook + Speed (2 seats); Surrette/Brydon/Sprague/Okere/Luciano holdovers
--   Auburn: All 8 seats on Nov 2025 ballot confirmed (sunjournal.com vote counts); no holdovers beyond 8 winners
--
-- Run: 2026-06-03

BEGIN;

-- =============================================================================
-- Pre-flight 1: RAISE EXCEPTION if any of the 5 government names already exist
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (
        'Lewiston Public Schools, Maine, US',
        'Bangor School Department, Maine, US',
        'South Portland Public Schools, Maine, US',
        'Auburn Public Schools, Maine, US',
        'Biddeford Public Schools, Maine, US'
      )) > 0 THEN
    RAISE EXCEPTION 'Migration 265 already applied — aborting re-run';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 2: Verify external_id block -890011..-890057 is clear
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -890057 AND -890011;
  IF v_count > 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: external_id block -890011..-890057 is not clear (% rows found)', v_count;
  END IF;
END $$;

-- =============================================================================
-- Pre-flight 3: Verify all 5 G5420 geofences exist (loader must run first)
-- =============================================================================
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id IN ('2307320','2302820','2312330','2302610','2303150')
    AND mtfcc = 'G5420';
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 5 G5420 rows for ME, found % — run load-me-school-boundaries.ts first', v_count;
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows (5 school districts)
-- type='LOCAL' matches school district type (same as LAUSD and Phase 86/87 pattern)
-- governments.state = 'ME' uppercase (governments convention)
-- WHERE NOT EXISTS guard — governments has no unique constraint on (name, geo_id)
-- =============================================================================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Lewiston Public Schools, Maine, US',
       'LOCAL', 'ME', NULL, '2307320'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Lewiston Public Schools, Maine, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Bangor School Department, Maine, US',
       'LOCAL', 'ME', NULL, '2302820'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Bangor School Department, Maine, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'South Portland Public Schools, Maine, US',
       'LOCAL', 'ME', NULL, '2312330'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'South Portland Public Schools, Maine, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Auburn Public Schools, Maine, US',
       'LOCAL', 'ME', NULL, '2302610'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Auburn Public Schools, Maine, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Biddeford Public Schools, Maine, US',
       'LOCAL', 'ME', NULL, '2303150'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Biddeford Public Schools, Maine, US'
);

-- =============================================================================
-- Step 2: School Committee / Board of Education chambers (5 — one per district)
-- CRITICAL: slug is GENERATED ALWAYS — never include in INSERT column list.
-- Per RESEARCH.md: South Portland uses 'Board of Education'; all others use 'School Committee'
-- Idempotency guard: WHERE NOT EXISTS on (name, government_id).
-- =============================================================================

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Lewiston Public Schools School Committee',
       (SELECT id FROM essentials.governments WHERE name = 'Lewiston Public Schools, Maine, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Lewiston Public Schools, Maine, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Bangor School Department School Committee',
       (SELECT id FROM essentials.governments WHERE name = 'Bangor School Department, Maine, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Bangor School Department, Maine, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Board of Education',
       'South Portland Public Schools Board of Education',
       (SELECT id FROM essentials.governments WHERE name = 'South Portland Public Schools, Maine, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Education'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'South Portland Public Schools, Maine, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Auburn Public Schools School Committee',
       (SELECT id FROM essentials.governments WHERE name = 'Auburn Public Schools, Maine, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Auburn Public Schools, Maine, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'School Committee',
       'Biddeford Public Schools School Committee',
       (SELECT id FROM essentials.governments WHERE name = 'Biddeford Public Schools, Maine, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Committee'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Biddeford Public Schools, Maine, US')
);

-- =============================================================================
-- Step 3: SCHOOL district rows (5 — one per district)
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT')
-- CRITICAL: state='me' LOWERCASE — routing query uses geocoder output which is lowercase
-- CRITICAL: mtfcc='G5420' must match the geofence_boundaries row
-- Idempotency guard: WHERE NOT EXISTS on (geo_id, district_type, state)
-- =============================================================================

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'me', '2307320', 'Lewiston Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2307320' AND district_type = 'SCHOOL' AND state = 'me'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'me', '2302820', 'Bangor School Department', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2302820' AND district_type = 'SCHOOL' AND state = 'me'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'me', '2312330', 'South Portland Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2312330' AND district_type = 'SCHOOL' AND state = 'me'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'me', '2302610', 'Auburn Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2302610' AND district_type = 'SCHOOL' AND state = 'me'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'me', '2303150', 'Biddeford Public Schools', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '2303150' AND district_type = 'SCHOOL' AND state = 'me'
);

-- =============================================================================
-- Step 4: Politicians + offices (37 blocks)
-- Pattern: WITH ins_p AS (INSERT...RETURNING id) INSERT INTO offices SELECT...
-- party=NULL (antipartisan — D-11)
-- is_appointed=false, is_appointed_position=false (elected board members; EXCEPT Lewiston Ward 5)
-- representing_state='ME' uppercase (offices convention)
-- is_incumbent=true (verified current board members)
-- Idempotency: ON CONFLICT (external_id) DO NOTHING on politicians
--             WHERE NOT EXISTS (district_id, politician_id) on offices
-- =============================================================================

-- ============================
-- LEWISTON PUBLIC SCHOOLS — 8 members (7 wards + 1 at-large), geo_id='2307320'
-- Sources: sunjournal.com Nov 2025 election results; citizenportal.ai Jan 5 2026 meeting recap
-- Office title convention: 'School Committee Member (Ward N)' / 'School Committee Member (At-Large)'
-- Ward 5: VACANT as of Jan 5 2026 (Iman Osman resigned after City Council win + indictment;
--         appointee not confirmed at implementation time — using is_vacant=true placeholder)
-- ============================

-- BLOCK 1: Phoenix McLaughlin (Ward 1) — -890011
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Phoenix McLaughlin', 'Phoenix', 'McLaughlin', NULL,
          true, false, false, true, -890011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 1)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 2: Janet Beaudoin (Ward 2) — -890012
-- Confirmed: Sun Journal "Beaudoin, Hird win reelection to Lewiston School Committee" Nov 2025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janet Beaudoin', 'Janet', 'Beaudoin', NULL,
          true, false, false, true, -890012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 2)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 3: Elizabeth Eames (Ward 3) — -890013
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Eames', 'Elizabeth', 'Eames', NULL,
          true, false, false, true, -890013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 3)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 4: Julia Harper (Ward 4) — -890014
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julia Harper', 'Julia', 'Harper', NULL,
          true, false, false, true, -890014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 4)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 5: VACANT - Ward 5 — -890015
-- Ward 5 seat unfilled as of Jan 5 2026 (Task 3 verification: citizenportal.ai Jan 5 2026 recap
-- confirmed "Ward 5 remained vacant" at first post-election meeting; Osman resigned after indictment).
-- Using is_vacant=true, is_appointed=true (seat filled by mayoral appointment process when filled).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'VACANT - Ward 5', NULL, NULL, NULL,
          true, true, true, false, -890015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 5)', 'ME', true, true, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Meghan Hird (Ward 6) — -890016
-- Confirmed: Sun Journal "Beaudoin, Hird win reelection to Lewiston School Committee" Nov 2025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Meghan Hird', 'Meghan', 'Hird', NULL,
          true, false, false, true, -890016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 6)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Donna Gallant (Ward 7) — -890017
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Gallant', 'Donna', 'Gallant', NULL,
          true, false, false, true, -890017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 7)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 8: Luke Jensen (At-Large) — -890018
-- Confirmed: sunjournal.com Nov 2025 election results (HIGH confidence)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Luke Jensen', 'Luke', 'Jensen', NULL,
          true, false, false, true, -890018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Lewiston Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (At-Large)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2307320'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- BANGOR SCHOOL DEPARTMENT — 7 at-large members, geo_id='2302820'
-- Sources: WABI TV Nov 2025 election (Cook + Speed elected); bangormaine.gov Jan 2026 minutes
--          confirming Luciano + Okere still members; RESEARCH.md §Bangor Board Roster
-- Office title convention: 'School Committee Member' (at-large, no qualifier per RESEARCH.md)
-- Nov 2025 election added 2 new members (Cook + Speed), 5 holdovers from prior terms
-- ============================

-- BLOCK 9: Tim Surrette — -890021
-- New Chair after Nov 2025 reorganization (RESEARCH.md)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Surrette', 'Tim', 'Surrette', NULL,
          true, false, false, true, -890021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Katie Brydon — -890022
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katie Brydon', 'Katie', 'Brydon', NULL,
          true, false, false, true, -890022)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 11: Mallory Cook — -890023
-- Confirmed: WABI TV Nov 5 2025 "Mallory Cook and Benjamin Speed were elected to the Bangor School Committee"
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mallory Cook', 'Mallory', 'Cook', NULL,
          true, false, false, true, -890023)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Ben Speed — -890024
-- Confirmed: WABI TV Nov 5 2025 election (same source as Cook above)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Speed', 'Ben', 'Speed', NULL,
          true, false, false, true, -890024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: Ben Sprague — -890025
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Sprague', 'Ben', 'Sprague', NULL,
          true, false, false, true, -890025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 14: Shelly Okere — -890026
-- Confirmed: bangormaine.gov Jan 2026 minutes "Motion: Luciano Second: Okere Vote: 7-0"
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelly Okere', 'Shelly', 'Okere', NULL,
          true, false, false, true, -890026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 15: Sara Luciano — -890027
-- Confirmed still a member: bangormaine.gov Jan 2026 meeting minutes "Motion: Luciano Second: Okere Vote: 7-0"
-- Nov 2025 election added only 2 new seats (Cook + Speed); Luciano's term had not expired
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sara Luciano', 'Sara', 'Luciano', NULL,
          true, false, false, true, -890027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Bangor School Department, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302820'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- SOUTH PORTLAND PUBLIC SCHOOLS — 7 members (D1-D5 + 2 at-large), geo_id='2312330'
-- Sources: pressherald.com Dec 8 2025 (De Angelis new chair); sunjournal.com Nov 2025 results;
--          RESEARCH.md §South Portland — spsd.org/spsdme.org blocked by JS client challenge
-- Office title convention: 'Board Member (District N)' for D1-D5; 'Board Member' for at-large
-- D5 VACANT (Adrian Dowling resigned April 2026 per pressherald.com; seat unfilled at research time)
-- D1 = Susan Rauscher [ASSUMED — spsd.org blocked], At-Large = Jennifer Ryan [ASSUMED]
-- ============================

-- BLOCK 16: Susan Rauscher (District 1) — -890031
-- [ASSUMED from RESEARCH.md search summary; spsd.org blocked by JS challenge at implementation time]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan Rauscher', 'Susan', 'Rauscher', NULL,
          true, false, false, true, -890031)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member (District 1)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 17: Tyler Smith (District 2) — -890032
-- Confirmed: New Vice Chair April 2026; elected Nov 2025 (sunjournal.com)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tyler Smith', 'Tyler', 'Smith', NULL,
          true, false, false, true, -890032)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member (District 2)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 18: Rosemarie De Angelis (District 3) — -890033
-- Confirmed Chair: pressherald.com Dec 8 2025 "Meet South Portland's new school board chair"
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rosemarie De Angelis', 'Rosemarie', 'De Angelis', NULL,
          true, false, false, true, -890033)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member (District 3)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 19: George Risch (District 4) — -890034
-- Confirmed: Won Nov 2025 special election (RESEARCH.md)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'George Risch', 'George', 'Risch', NULL,
          true, false, false, true, -890034)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member (District 4)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 20: VACANT - District 5 — -890035
-- Adrian Dowling resigned April 2026 (pressherald.com confirmed);
-- Seat vacancy not filled at implementation time (Task 3 verification: spsd.org blocked)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'VACANT - District 5', NULL, NULL, NULL,
          true, false, true, false, -890035)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member (District 5)', 'ME', false, true, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 21: Jennifer Ryan (At-Large) — -890036
-- [ASSUMED from RESEARCH.md search summary; spsd.org blocked by JS challenge at implementation time]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jennifer Ryan', 'Jennifer', 'Ryan', NULL,
          true, false, false, true, -890036)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 22: Eleni Richardson (At-Large) — -890037
-- Confirmed: Won Nov 2025 special election (RESEARCH.md)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eleni Richardson', 'Eleni', 'Richardson', NULL,
          true, false, false, true, -890037)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'South Portland Public Schools, Maine, US'
          AND ch.name = 'Board of Education'),
       p.id,
       'Board Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2312330'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- AUBURN PUBLIC SCHOOLS — 8 members (5 wards + 3 at-large), geo_id='2302610'
-- Sources: sunjournal.com Nov 2025 election results (all 8 confirmed with vote counts)
-- All 8 seats were on the Nov 2025 ballot (confirmed: Ward 4 Chapman vs Gormley,
-- Ward 1 McGuigan unopposed, At-Large 3-way Albert/Rich/Pulk)
-- Office title convention: 'School Committee Member (Ward N)' / 'School Committee Member (At-Large)'
-- ============================

-- BLOCK 23: Korin McGuigan (Ward 1) — -890041
-- Confirmed: Won Nov 2025 (100%, unopposed) — sunjournal.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Korin McGuigan', 'Korin', 'McGuigan', NULL,
          true, false, false, true, -890041)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 1)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 24: Misty Edgecomb (Ward 2) — -890042
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Misty Edgecomb', 'Misty', 'Edgecomb', NULL,
          true, false, false, true, -890042)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 2)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 25: Patricia Gautier (Ward 3) — -890043
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patricia Gautier', 'Patricia', 'Gautier', NULL,
          true, false, false, true, -890043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 3)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 26: Lydia Chapman (Ward 4) — -890044
-- Confirmed: Won Nov 2025 (60% vs Gormley 40%) — sunjournal.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lydia Chapman', 'Lydia', 'Chapman', NULL,
          true, false, false, true, -890044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 4)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 27: Daniel F. Poisson Sr. (Ward 5) — -890045
-- Confirmed: Won Nov 2025 (68% vs Mercier) — sunjournal.com
-- Note: 'Sr.' is part of the name; last_name includes suffix per Sacramento pattern (Rick Jennings II)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Daniel F. Poisson Sr.', 'Daniel', 'Poisson Sr.', NULL,
          true, false, false, true, -890045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (Ward 5)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 28: Pamela Albert (At-Large) — -890046
-- Confirmed: Won Nov 2025 (34% / 3-way) — sunjournal.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pamela Albert', 'Pamela', 'Albert', NULL,
          true, false, false, true, -890046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (At-Large)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 29: Olivia Jaye Rich (At-Large) — -890047
-- Confirmed: Won Nov 2025 (33% / 3-way) — sunjournal.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Olivia Jaye Rich', 'Olivia', 'Rich', NULL,
          true, false, false, true, -890047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (At-Large)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 30: Nancy Pulk (At-Large) — -890048
-- Confirmed: Won Nov 2025 (33% / 3-way) — sunjournal.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Pulk', 'Nancy', 'Pulk', NULL,
          true, false, false, true, -890048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Auburn Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member (At-Large)', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2302610'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================
-- BIDDEFORD PUBLIC SCHOOLS — 7 at-large members, geo_id='2303150'
-- Sources: sacobaynews.com + biddeford-gazette.com Nov 2025 election vote totals (HIGH confidence)
-- All 7 seats on ballot; all 7 winners confirmed with vote counts
-- Office title convention: 'School Committee Member' (at-large, no qualifier)
-- ============================

-- BLOCK 31: Amy Clearwater — -890051
-- Confirmed: Elected Nov 2025 (2,718 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Clearwater', 'Amy', 'Clearwater', NULL,
          true, false, false, true, -890051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 32: Meagan Desjardins — -890052
-- Confirmed: Elected Nov 2025 (3,242 votes — highest) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Meagan Desjardins', 'Meagan', 'Desjardins', NULL,
          true, false, false, true, -890052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 33: Michele Landry — -890053
-- Confirmed: Elected Nov 2025 (2,799 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michele Landry', 'Michele', 'Landry', NULL,
          true, false, false, true, -890053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 34: Marie Potvin — -890054
-- Confirmed: Elected Nov 2025 (3,175 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marie Potvin', 'Marie', 'Potvin', NULL,
          true, false, false, true, -890054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 35: Timothy Stebbins — -890055
-- Confirmed: Elected Nov 2025 (3,044 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Timothy Stebbins', 'Timothy', 'Stebbins', NULL,
          true, false, false, true, -890055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 36: Karen Ruel — -890056
-- Confirmed: Elected Nov 2025 (2,486 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Ruel', 'Karen', 'Ruel', NULL,
          true, false, false, true, -890056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 37: Emily Henley — -890057
-- Confirmed: Elected Nov 2025 (2,667 votes) — sacobaynews.com
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Emily Henley', 'Emily', 'Henley', NULL,
          true, false, false, true, -890057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT ch.id FROM essentials.chambers ch
        JOIN essentials.governments g ON g.id = ch.government_id
        WHERE g.name = 'Biddeford Public Schools, Maine, US'
          AND ch.name = 'School Committee'),
       p.id,
       'School Committee Member', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '2303150'
  AND d.district_type = 'SCHOOL'
  AND d.state = 'me'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: Back-fill office_id on all new politicians
-- =============================================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -890057 AND -890011
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification — 8 gates, RAISE EXCEPTION on any failure
-- =============================================================================

DO $$
DECLARE
  v_govs      INTEGER;
  v_chambers  INTEGER;
  v_districts INTEGER;
  v_pols      INTEGER;
  v_offices   INTEGER;
  v_split     INTEGER;
  v_orphans   INTEGER;
  v_lew       INTEGER;
  v_ban       INTEGER;
  v_sp        INTEGER;
  v_aub       INTEGER;
  v_bid       INTEGER;
BEGIN
  -- (a) 5 government rows
  SELECT COUNT(*) INTO v_govs
  FROM essentials.governments
  WHERE name IN (
    'Lewiston Public Schools, Maine, US',
    'Bangor School Department, Maine, US',
    'South Portland Public Schools, Maine, US',
    'Auburn Public Schools, Maine, US',
    'Biddeford Public Schools, Maine, US'
  );
  IF v_govs <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 ME government rows, found %', v_govs;
  END IF;

  -- (b) 5 chamber rows
  SELECT COUNT(*) INTO v_chambers
  FROM essentials.chambers ch
  WHERE ch.government_id IN (
    SELECT id FROM essentials.governments
    WHERE name IN (
      'Lewiston Public Schools, Maine, US',
      'Bangor School Department, Maine, US',
      'South Portland Public Schools, Maine, US',
      'Auburn Public Schools, Maine, US',
      'Biddeford Public Schools, Maine, US'
    )
  )
  AND ch.name IN ('School Committee','Board of Education');
  IF v_chambers <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 ME chamber rows, found %', v_chambers;
  END IF;

  -- (c) 5 SCHOOL districts rows
  SELECT COUNT(*) INTO v_districts
  FROM essentials.districts
  WHERE district_type = 'SCHOOL'
    AND state = 'me'
    AND geo_id IN ('2307320','2302820','2312330','2302610','2303150');
  IF v_districts <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 SCHOOL districts rows for ME, found %', v_districts;
  END IF;

  -- (d) 37 politicians in range
  SELECT COUNT(*) INTO v_pols
  FROM essentials.politicians
  WHERE external_id BETWEEN -890057 AND -890011;
  IF v_pols <> 37 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 37 politicians in -890011..-890057, found %', v_pols;
  END IF;

  -- (e) 37 offices in range
  SELECT COUNT(*) INTO v_offices
  FROM essentials.offices o
  JOIN essentials.politicians p ON o.politician_id = p.id
  WHERE p.external_id BETWEEN -890057 AND -890011;
  IF v_offices <> 37 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 37 offices for ME board members, found %', v_offices;
  END IF;

  -- (f) Section-split: 0 orphan G5420 rows
  SELECT COUNT(*) INTO v_split
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('2307320','2302820','2312330','2302610','2303150')
    AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id
        AND d.district_type = 'SCHOOL'
        AND d.state = 'me'
    );
  IF v_split <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split check found % orphan G5420 rows', v_split;
  END IF;

  -- (g) office_id back-fill: 0 politicians with NULL office_id in range
  SELECT COUNT(*) INTO v_orphans
  FROM essentials.politicians
  WHERE external_id BETWEEN -890057 AND -890011
    AND office_id IS NULL;
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians in range have NULL office_id (back-fill incomplete)', v_orphans;
  END IF;

  -- (h) Per-district roster size spot-check
  SELECT COUNT(*) INTO v_lew
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'Lewiston Public Schools, Maine, US';
  IF v_lew <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Lewiston expected 8 offices, found %', v_lew;
  END IF;

  SELECT COUNT(*) INTO v_ban
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'Bangor School Department, Maine, US';
  IF v_ban <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Bangor expected 7 offices, found %', v_ban;
  END IF;

  SELECT COUNT(*) INTO v_sp
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'South Portland Public Schools, Maine, US';
  IF v_sp <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: South Portland expected 7 offices, found %', v_sp;
  END IF;

  SELECT COUNT(*) INTO v_aub
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'Auburn Public Schools, Maine, US';
  IF v_aub <> 8 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Auburn expected 8 offices, found %', v_aub;
  END IF;

  SELECT COUNT(*) INTO v_bid
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.name = 'Biddeford Public Schools, Maine, US';
  IF v_bid <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Biddeford expected 7 offices, found %', v_bid;
  END IF;

  RAISE NOTICE 'Migration 265 post-verification PASSED: 5 govs, 5 chambers, 5 SCHOOL districts, 37 politicians, 37 offices, section-split=0, office_id back-fill complete.';
END $$;

-- =============================================================================
-- Ledger entry
-- =============================================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('265')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- Migration 193: CA Federal Officials — 34 new House reps + 3 data fixes + Cárdenas office deactivation
--
-- What this migration does:
--   DATA FIXES (3 UPDATEs + 1 office deactivation):
--     1. Alex Padilla: fix external_id from legacy 666262 → -6000201, set party='Democratic'
--     2. Tony Cárdenas: assign external_id -6000203 (was NULL) + deactivate his stale CD-29 office row
--     3. Pete Aguilar: assign external_id -6000204 (was NULL; -100097 is occupied by CA Assembly member)
--
--   NEW POLITICIANS + OFFICES (34 House reps):
--     Seeds the 34 CA US House reps missing from DB (CDs 01-22, 24-25, 39-41, 46-52).
--     The 18 reps already seeded (CDs 23, 26-38, 42-45) are NOT re-inserted (ON CONFLICT DO NOTHING).
--     Adam Schiff (-100047) was already seeded as a House rep and promoted to Senator — skipped here.
--     NOTE: The plan originally assigned IDs in the -100049..-100117 range, but that range is
--     occupied by CA State Assembly and TX legislators. Using -60003xx scheme instead:
--     CD-01 → -6000301, CD-02 → -6000302, ..., CD-52 → -6000352 (skipping CDs without new reps).
--
--   SENATOR OFFICE GUARDS (idempotent):
--     Ensures Padilla (-6000201) and Schiff (-100047) both have office rows on the CA NATIONAL_UPPER district.
--
--   OFFICE_ID BACK-FILL:
--     Sets politicians.office_id for the 34 new reps and for Padilla after the external_id fix.
--
--   VACANCY NOTES:
--     CD-01 (LaMalfa): died January 6, 2026; special election August 4, 2026. Seeding the elected
--       119th Congress rep as the official holder; update after special election.
--     CD-14 (Swalwell): resigned April 14, 2026; special election pending. Same approach.
--
--   CA NATIONAL_UPPER geo_id: '06', state='CA'
--   CA NATIONAL_LOWER geo_ids: '0601'..'0652', state='CA'
--   U.S. Senate chamber UUID: 7cbe07bc-84b8-433b-952b-540e7de18a92
--   U.S. House chamber UUID:  c2facc31-7b13-428c-b7b9-32d0d3b95f76

BEGIN;

-- =============================================================================
-- SECTION 1: DATA FIXES
-- =============================================================================

-- Fix 1: Padilla — correct legacy external_id + set party
UPDATE essentials.politicians
SET party = 'Democratic', external_id = -6000201
WHERE external_id = 666262;

-- Fix 2a: Cárdenas — assign external_id (was NULL)
-- Use id-based subquery to target exactly one row (the one with office rows = the real CD-29 rep)
-- Both 'Tony Cárdenas' and 'Tony Cardenas' rows exist; target the one with office rows
UPDATE essentials.politicians
SET external_id = -6000203
WHERE id = (
  SELECT p.id FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  WHERE (p.full_name = 'Tony Cárdenas' OR p.full_name = 'Tony Cardenas')
    AND p.external_id IS NULL
  LIMIT 1
);

-- Fix 2b: Cárdenas — deactivate his stale CD-29 office row
UPDATE essentials.offices
SET is_vacant = true
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -6000203
);

-- Fix 3: Pete Aguilar — assign external_id (was NULL; use -6000204 since -100097 is occupied)
UPDATE essentials.politicians
SET external_id = -6000204
WHERE full_name = 'Pete Aguilar'
  AND external_id IS NULL;

-- =============================================================================
-- SECTION 2: 34 NEW HOUSE REPS
-- Using -60003xx scheme (CD number maps to last 2 digits where available)
-- =============================================================================

-- CD-01 Doug LaMalfa (Republican, -6000301) — vacancy note: died 2026-01-06, special election 2026-08-04
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Doug LaMalfa', 'Doug', 'LaMalfa', 'Republican',
          true, false, false, true, -6000301)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0601' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-02 Jared Huffman (Democratic, -6000302)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jared Huffman', 'Jared', 'Huffman', 'Democratic',
          true, false, false, true, -6000302)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0602' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-03 Kevin Kiley (Independent, -6000303 — changed from Republican on 2026-03-19)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Kiley', 'Kevin', 'Kiley', 'Independent',
          true, false, false, true, -6000303)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0603' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-04 Mike Thompson (Democratic, -6000304)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Thompson', 'Mike', 'Thompson', 'Democratic',
          true, false, false, true, -6000304)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0604' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-05 Tom McClintock (Republican, -6000305)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom McClintock', 'Tom', 'McClintock', 'Republican',
          true, false, false, true, -6000305)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0605' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-06 Ami Bera (Democratic, -6000306)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ami Bera', 'Ami', 'Bera', 'Democratic',
          true, false, false, true, -6000306)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0606' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-07 Doris Matsui (Democratic, -6000307)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Doris Matsui', 'Doris', 'Matsui', 'Democratic',
          true, false, false, true, -6000307)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0607' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-08 John Garamendi (Democratic, -6000308)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Garamendi', 'John', 'Garamendi', 'Democratic',
          true, false, false, true, -6000308)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0608' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-09 Josh Harder (Democratic, -6000309)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josh Harder', 'Josh', 'Harder', 'Democratic',
          true, false, false, true, -6000309)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0609' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-10 Mark DeSaulnier (Democratic, -6000310)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark DeSaulnier', 'Mark', 'DeSaulnier', 'Democratic',
          true, false, false, true, -6000310)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0610' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-11 Nancy Pelosi (Democratic, -6000311)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Pelosi', 'Nancy', 'Pelosi', 'Democratic',
          true, false, false, true, -6000311)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0611' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-12 Lateefah Simon (Democratic, -6000312)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lateefah Simon', 'Lateefah', 'Simon', 'Democratic',
          true, false, false, true, -6000312)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0612' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-13 Adam Gray (Democratic, -6000313)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Adam Gray', 'Adam', 'Gray', 'Democratic',
          true, false, false, true, -6000313)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0613' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-14 Eric Swalwell (Democratic, -6000314) — vacancy: resigned 2026-04-14, special election pending
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Swalwell', 'Eric', 'Swalwell', 'Democratic',
          true, false, false, true, -6000314)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0614' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-15 Kevin Mullin (Democratic, -6000315)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Mullin', 'Kevin', 'Mullin', 'Democratic',
          true, false, false, true, -6000315)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0615' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-16 Sam Liccardo (Democratic, -6000316)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sam Liccardo', 'Sam', 'Liccardo', 'Democratic',
          true, false, false, true, -6000316)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0616' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-17 Ro Khanna (Democratic, -6000317)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ro Khanna', 'Ro', 'Khanna', 'Democratic',
          true, false, false, true, -6000317)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0617' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-18 Zoe Lofgren (Democratic, -6000318)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Zoe Lofgren', 'Zoe', 'Lofgren', 'Democratic',
          true, false, false, true, -6000318)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0618' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-19 Jimmy Panetta (Democratic, -6000319)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jimmy Panetta', 'Jimmy', 'Panetta', 'Democratic',
          true, false, false, true, -6000319)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0619' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-20 Vince Fong (Republican, -6000320)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vince Fong', 'Vince', 'Fong', 'Republican',
          true, false, false, true, -6000320)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0620' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-21 Jim Costa (Democratic, -6000321)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jim Costa', 'Jim', 'Costa', 'Democratic',
          true, false, false, true, -6000321)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0621' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-22 David Valadao (Republican, -6000322)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Valadao', 'David', 'Valadao', 'Republican',
          true, false, false, true, -6000322)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0622' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-24 Salud Carbajal (Democratic, -6000324)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Salud Carbajal', 'Salud', 'Carbajal', 'Democratic',
          true, false, false, true, -6000324)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0624' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-25 Raul Ruiz (Democratic, -6000325)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raul Ruiz', 'Raul', 'Ruiz', 'Democratic',
          true, false, false, true, -6000325)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0625' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-39 Mark Takano (Democratic, -6000339)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Takano', 'Mark', 'Takano', 'Democratic',
          true, false, false, true, -6000339)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0639' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-40 Young Kim (Republican, -6000340)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Young Kim', 'Young', 'Kim', 'Republican',
          true, false, false, true, -6000340)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0640' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-41 Ken Calvert (Republican, -6000341)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ken Calvert', 'Ken', 'Calvert', 'Republican',
          true, false, false, true, -6000341)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0641' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-46 Lou Correa (Democratic, -6000346)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lou Correa', 'Lou', 'Correa', 'Democratic',
          true, false, false, true, -6000346)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0646' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-47 Dave Min (Democratic, -6000347)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dave Min', 'Dave', 'Min', 'Democratic',
          true, false, false, true, -6000347)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0647' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-48 Darrell Issa (Republican, -6000348)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Darrell Issa', 'Darrell', 'Issa', 'Republican',
          true, false, false, true, -6000348)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0648' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-49 Mike Levin (Democratic, -6000349)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Levin', 'Mike', 'Levin', 'Democratic',
          true, false, false, true, -6000349)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0649' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-50 Scott Peters (Democratic, -6000350)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Peters', 'Scott', 'Peters', 'Democratic',
          true, false, false, true, -6000350)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0650' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-51 Sara Jacobs (Democratic, -6000351)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sara Jacobs', 'Sara', 'Jacobs', 'Democratic',
          true, false, false, true, -6000351)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0651' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- CD-52 Juan Vargas (Democratic, -6000352)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Juan Vargas', 'Juan', 'Vargas', 'Democratic',
          true, false, false, true, -6000352)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       'c2facc31-7b13-428c-b7b9-32d0d3b95f76',
       p.id,
       'U.S. Representative', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0652' AND d.district_type = 'NATIONAL_LOWER' AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'
  );

-- =============================================================================
-- SECTION 3: SENATOR OFFICE GUARDS (idempotent — self-heal if office row missing)
-- =============================================================================

-- Padilla senator office — ensure linked to CA NATIONAL_UPPER after external_id fix
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -6000201) p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CA'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Schiff senator office — idempotent guard (external_id=-100047)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (SELECT id FROM essentials.politicians WHERE external_id = -100047) p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CA'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- SECTION 4: OFFICE_ID BACK-FILL
-- =============================================================================

-- Back-fill office_id for the 34 new House reps (using -60003xx range)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -6000301, -6000302, -6000303, -6000304, -6000305, -6000306, -6000307,
    -6000308, -6000309, -6000310, -6000311, -6000312, -6000313, -6000314,
    -6000315, -6000316, -6000317, -6000318, -6000319, -6000320, -6000321,
    -6000322, -6000324, -6000325, -6000339, -6000340, -6000341, -6000346,
    -6000347, -6000348, -6000349, -6000350, -6000351, -6000352
  )
  AND p.office_id IS NULL;

-- Back-fill office_id for Padilla after external_id fix
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id = -6000201
  AND p.office_id IS NULL;

COMMIT;

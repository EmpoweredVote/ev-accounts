-- Migration 176: US Senators MT through WY (48 new senators, alphabetical second half)
--
-- Purpose: Insert 48 new US Senator politician rows for states MT–WY, create their
--   office rows on the correct NATIONAL_UPPER district per state, set photo_origin_url
--   from unitedstates.github.io CDN (or official senate.gov for recently-appointed
--   senators not yet in the CDN), and backfill photo_origin_url for the 6 existing
--   MA/ME/TX senators.
--
-- Pre-state:  52 senators reachable via NATIONAL_UPPER (10 existing + 42 from migration 175)
-- Post-state: 100 senators reachable (52 + 48 new), all with photos
--
-- Expected row counts after this migration:
--   essentials.politicians WHERE external_id BETWEEN -400090 AND -400043: 48
--   essentials.offices linked to those 48: 48
--   essentials.politicians (all, via NATIONAL_UPPER offices): 100
--   senators missing photo_origin_url: 0
--
-- Appointed senators (is_appointed=true + is_appointed_position=true):
--   -400061 Jon Husted (OH)    — appointed Jan 21, 2025 to fill Vance vacancy
--   -400064 Alan Armstrong (OK)— appointed 2025 to fill Lankford vacancy (still serving)
--
-- NOTE: Armstrong appears as BOTH an existing senator (-400063 James Lankford) AND
--   appointed replacement (-400064 Alan Armstrong). Lankford resigned to become SBA chief.
--
-- Bioguide verification (2026-05-19):
--   H001099 Bill Hagerty (TN)           — CORRECTED to H000601 (H001099 returns 404)
--     Confirmed via unitedstates/congress-legislators legislators-current.yaml
--   J000293 Ron Johnson (WI)            — verified HTTP 200, 45.9KB JPEG
--   H001104 Jon Husted (OH, appt'd)     — not yet on unitedstates CDN (recently appointed 2025)
--     fallback: https://www.husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp
--     (verified HTTP 200, 177KB WebP)
--   A000383 Alan Armstrong (OK, appt'd) — not yet on unitedstates CDN (recently appointed 2025)
--     fallback: https://www.armstrong.senate.gov/wp-content/uploads/2026/03/pic-scaled.jpg
--     (verified HTTP 200, 431KB JPEG)
--
-- Existing MA/ME/TX senators photo note:
--   All 6 existing senators (Warren, Markey, Collins, King, Cornyn, Cruz) already have
--   Wikipedia URLs as photo_origin_url. The IS NULL OR = '' guard means those UPDATEs
--   in Section C will be no-ops. Included for completeness and future re-runs after URL reset.
--   DB confirmed full_names: 'Elizabeth Warren', 'Edward J. Markey',
--   'Susan M. Collins', 'Angus S. King, Jr.', 'John Cornyn', 'Ted Cruz'
--
-- Idempotency:
--   - ON CONFLICT (external_id) DO NOTHING on politicians prevents duplicate rows
--   - NOT EXISTS guard on offices prevents duplicate office rows
--   - photo_origin_url UPDATE is guarded with IS NULL OR = ''
--   - office_id backfill is guarded with p.office_id IS NULL
--   Safe to re-run: second apply is a no-op.
--
-- Chamber UUID (U.S. Senate — confirmed in migrations 155, 170, 103, 175):
--   7cbe07bc-84b8-433b-952b-540e7de18a92

BEGIN;

-- ============================================================
-- SECTION A: 48 new senator INSERT blocks (MT through WY)
-- ============================================================

-- ----- Steve Daines (-400043) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Daines', 'Steve', 'Daines', 'Republican',
          true, false, false, true, -400043)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'MT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tim Sheehy (-400044) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Sheehy', 'Tim', 'Sheehy', 'Republican',
          true, false, false, true, -400044)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'MT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Thom Tillis (-400045) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Thom Tillis', 'Thom', 'Tillis', 'Republican',
          true, false, false, true, -400045)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ted Budd (-400046) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ted Budd', 'Ted', 'Budd', 'Republican',
          true, false, false, true, -400046)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Hoeven (-400047) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Hoeven', 'John', 'Hoeven', 'Republican',
          true, false, false, true, -400047)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'ND', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ND'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Kevin Cramer (-400048) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Cramer', 'Kevin', 'Cramer', 'Republican',
          true, false, false, true, -400048)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'ND', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ND'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Deb Fischer (-400049) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deb Fischer', 'Deb', 'Fischer', 'Republican',
          true, false, false, true, -400049)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NE', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NE'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Pete Ricketts (-400050) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pete Ricketts', 'Pete', 'Ricketts', 'Republican',
          true, false, false, true, -400050)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NE', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NE'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jeanne Shaheen (-400051) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeanne Shaheen', 'Jeanne', 'Shaheen', 'Democrat',
          true, false, false, true, -400051)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Maggie Hassan (-400052) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maggie Hassan', 'Maggie', 'Hassan', 'Democrat',
          true, false, false, true, -400052)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Cory Booker (-400053) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cory Booker', 'Cory', 'Booker', 'Democrat',
          true, false, false, true, -400053)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NJ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NJ'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Andy Kim (-400054) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andy Kim', 'Andy', 'Kim', 'Democrat',
          true, false, false, true, -400054)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NJ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NJ'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Martin Heinrich (-400055) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Martin Heinrich', 'Martin', 'Heinrich', 'Democrat',
          true, false, false, true, -400055)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NM', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NM'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ben Ray Luján (-400056) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ben Ray Luján', 'Ben Ray', 'Luján', 'Democrat',
          true, false, false, true, -400056)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NM', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NM'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Catherine Cortez Masto (-400057) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Catherine Cortez Masto', 'Catherine', 'Cortez Masto', 'Democrat',
          true, false, false, true, -400057)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NV'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jacky Rosen (-400058) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jacky Rosen', 'Jacky', 'Rosen', 'Democrat',
          true, false, false, true, -400058)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NV'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Chuck Schumer (-400059) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chuck Schumer', 'Chuck', 'Schumer', 'Democrat',
          true, false, false, true, -400059)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Kirsten Gillibrand (-400060) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kirsten Gillibrand', 'Kirsten', 'Gillibrand', 'Democrat',
          true, false, false, true, -400060)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'NY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jon Husted (-400061) — APPOINTED -----
-- Appointed 2025-01-21 to fill vacancy left by JD Vance (became VP)
-- is_appointed=true on politician row, is_appointed_position=true on office row
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jon Husted', 'Jon', 'Husted', 'Republican',
          true, true,   -- <-- is_appointed = true
          false, true, -400061)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OH',
       true,           -- <-- is_appointed_position = true
       false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Bernie Moreno (-400062) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bernie Moreno', 'Bernie', 'Moreno', 'Republican',
          true, false, false, true, -400062)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- James Lankford (-400063) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Lankford', 'James', 'Lankford', 'Republican',
          true, false, false, true, -400063)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Alan Armstrong (-400064) — APPOINTED -----
-- Appointed 2025 to fill vacancy left by James Lankford (became SBA Administrator)
-- is_appointed=true on politician row, is_appointed_position=true on office row
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alan Armstrong', 'Alan', 'Armstrong', 'Republican',
          true, true,   -- <-- is_appointed = true
          false, true, -400064)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OK',
       true,           -- <-- is_appointed_position = true
       false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ron Wyden (-400065) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ron Wyden', 'Ron', 'Wyden', 'Democrat',
          true, false, false, true, -400065)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jeff Merkley (-400066) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jeff Merkley', 'Jeff', 'Merkley', 'Democrat',
          true, false, false, true, -400066)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Fetterman (-400067) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Fetterman', 'John', 'Fetterman', 'Democrat',
          true, false, false, true, -400067)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'PA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'PA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Dave McCormick (-400068) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dave McCormick', 'Dave', 'McCormick', 'Republican',
          true, false, false, true, -400068)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'PA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'PA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jack Reed (-400069) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jack Reed', 'Jack', 'Reed', 'Democrat',
          true, false, false, true, -400069)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'RI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'RI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Sheldon Whitehouse (-400070) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sheldon Whitehouse', 'Sheldon', 'Whitehouse', 'Democrat',
          true, false, false, true, -400070)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'RI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'RI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Lindsey Graham (-400071) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lindsey Graham', 'Lindsey', 'Graham', 'Republican',
          true, false, false, true, -400071)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'SC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'SC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tim Scott (-400072) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Scott', 'Tim', 'Scott', 'Republican',
          true, false, false, true, -400072)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'SC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'SC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Thune (-400073) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Thune', 'John', 'Thune', 'Republican',
          true, false, false, true, -400073)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'SD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'SD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mike Rounds (-400074) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Rounds', 'Mike', 'Rounds', 'Republican',
          true, false, false, true, -400074)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'SD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'SD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Marsha Blackburn (-400075) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marsha Blackburn', 'Marsha', 'Blackburn', 'Republican',
          true, false, false, true, -400075)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'TN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'TN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Bill Hagerty (-400076) -----
-- Note: bioguide corrected from H001099 (404) to H000601 (verified HTTP 200, 11.4KB JPEG)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bill Hagerty', 'Bill', 'Hagerty', 'Republican',
          true, false, false, true, -400076)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'TN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'TN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mike Lee (-400077) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Lee', 'Mike', 'Lee', 'Republican',
          true, false, false, true, -400077)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'UT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'UT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Curtis (-400078) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Curtis', 'John', 'Curtis', 'Republican',
          true, false, false, true, -400078)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'UT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'UT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tim Kaine (-400079) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Kaine', 'Tim', 'Kaine', 'Democrat',
          true, false, false, true, -400079)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mark Warner (-400080) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Warner', 'Mark', 'Warner', 'Democrat',
          true, false, false, true, -400080)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'VA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Bernie Sanders (-400081) -----
-- party = 'Independent' (caucuses with Democrats but registered Independent)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bernie Sanders', 'Bernie', 'Sanders', 'Independent',
          true, false, false, true, -400081)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'VT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'VT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Peter Welch (-400082) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Peter Welch', 'Peter', 'Welch', 'Democrat',
          true, false, false, true, -400082)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'VT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'VT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Patty Murray (-400083) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patty Murray', 'Patty', 'Murray', 'Democrat',
          true, false, false, true, -400083)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Maria Cantwell (-400084) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maria Cantwell', 'Maria', 'Cantwell', 'Democrat',
          true, false, false, true, -400084)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tammy Baldwin (-400085) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tammy Baldwin', 'Tammy', 'Baldwin', 'Democrat',
          true, false, false, true, -400085)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ron Johnson (-400086) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ron Johnson', 'Ron', 'Johnson', 'Republican',
          true, false, false, true, -400086)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Shelley Moore Capito (-400087) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Shelley Moore Capito', 'Shelley', 'Moore Capito', 'Republican',
          true, false, false, true, -400087)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WV'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jim Justice (-400088) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jim Justice', 'Jim', 'Justice', 'Republican',
          true, false, false, true, -400088)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WV'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Barrasso (-400089) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Barrasso', 'John', 'Barrasso', 'Republican',
          true, false, false, true, -400089)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Cynthia Lummis (-400090) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cynthia Lummis', 'Cynthia', 'Lummis', 'Republican',
          true, false, false, true, -400090)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'WY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION B: photo_origin_url UPDATE for the 48 new senators
-- ============================================================

-- ===== Photo URLs (MT–WY, external_ids -400043 through -400090) =====

-- MT Steve Daines (D000618)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/D000618.jpg'
WHERE external_id = -400043
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- MT Tim Sheehy (S001232)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001232.jpg'
WHERE external_id = -400044
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NC Thom Tillis (T000476)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/T000476.jpg'
WHERE external_id = -400045
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NC Ted Budd (B001316)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001316.jpg'
WHERE external_id = -400046
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- ND John Hoeven (H001061)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001061.jpg'
WHERE external_id = -400047
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- ND Kevin Cramer (C001096)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001096.jpg'
WHERE external_id = -400048
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NE Deb Fischer (F000463)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/F000463.jpg'
WHERE external_id = -400049
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NE Pete Ricketts (R000618)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/R000618.jpg'
WHERE external_id = -400050
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NH Jeanne Shaheen (S001181)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001181.jpg'
WHERE external_id = -400051
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NH Maggie Hassan (H001076)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001076.jpg'
WHERE external_id = -400052
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NJ Cory Booker (B001288)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001288.jpg'
WHERE external_id = -400053
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NJ Andy Kim (K000394)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000394.jpg'
WHERE external_id = -400054
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NM Martin Heinrich (H001046)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001046.jpg'
WHERE external_id = -400055
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NM Ben Ray Luján (L000570)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/L000570.jpg'
WHERE external_id = -400056
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NV Catherine Cortez Masto (C001113)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001113.jpg'
WHERE external_id = -400057
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NV Jacky Rosen (R000608)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/R000608.jpg'
WHERE external_id = -400058
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NY Chuck Schumer (S000148)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S000148.jpg'
WHERE external_id = -400059
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- NY Kirsten Gillibrand (G000555)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/G000555.jpg'
WHERE external_id = -400060
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OH Jon Husted (H001104) — APPOINTED — fallback URL (not yet on unitedstates CDN)
UPDATE essentials.politicians SET photo_origin_url =
  'https://www.husted.senate.gov/wp-content/uploads/2025/10/Husted_OfficialPortrait.webp'
WHERE external_id = -400061
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OH Bernie Moreno (M001246)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001246.jpg'
WHERE external_id = -400062
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OK James Lankford (L000575)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/L000575.jpg'
WHERE external_id = -400063
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OK Alan Armstrong (A000383) — APPOINTED — fallback URL (not yet on unitedstates CDN)
UPDATE essentials.politicians SET photo_origin_url =
  'https://www.armstrong.senate.gov/wp-content/uploads/2026/03/pic-scaled.jpg'
WHERE external_id = -400064
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OR Ron Wyden (W000779)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000779.jpg'
WHERE external_id = -400065
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- OR Jeff Merkley (M001176)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001176.jpg'
WHERE external_id = -400066
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- PA John Fetterman (F000479)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/F000479.jpg'
WHERE external_id = -400067
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- PA Dave McCormick (M001243)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001243.jpg'
WHERE external_id = -400068
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- RI Jack Reed (R000122)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/R000122.jpg'
WHERE external_id = -400069
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- RI Sheldon Whitehouse (W000802)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000802.jpg'
WHERE external_id = -400070
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- SC Lindsey Graham (G000359)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/G000359.jpg'
WHERE external_id = -400071
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- SC Tim Scott (S001184)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001184.jpg'
WHERE external_id = -400072
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- SD John Thune (T000250)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/T000250.jpg'
WHERE external_id = -400073
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- SD Mike Rounds (R000605)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/R000605.jpg'
WHERE external_id = -400074
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- TN Marsha Blackburn (B001243)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001243.jpg'
WHERE external_id = -400075
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- TN Bill Hagerty (H000601) — bioguide corrected from H001099 (404) to H000601 (200 OK)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H000601.jpg'
WHERE external_id = -400076
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- UT Mike Lee (L000577)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/L000577.jpg'
WHERE external_id = -400077
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- UT John Curtis (C001114)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001114.jpg'
WHERE external_id = -400078
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- VA Tim Kaine (K000384)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000384.jpg'
WHERE external_id = -400079
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- VA Mark Warner (W000805)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000805.jpg'
WHERE external_id = -400080
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- VT Bernie Sanders (S000033)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S000033.jpg'
WHERE external_id = -400081
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- VT Peter Welch (W000800)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000800.jpg'
WHERE external_id = -400082
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WA Patty Murray (M001111)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001111.jpg'
WHERE external_id = -400083
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WA Maria Cantwell (C000127)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C000127.jpg'
WHERE external_id = -400084
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WI Tammy Baldwin (B001230)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001230.jpg'
WHERE external_id = -400085
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WI Ron Johnson (J000293)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/J000293.jpg'
WHERE external_id = -400086
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WV Shelley Moore Capito (C001047)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001047.jpg'
WHERE external_id = -400087
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WV Jim Justice (J000312)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/J000312.jpg'
WHERE external_id = -400088
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WY John Barrasso (B001261)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001261.jpg'
WHERE external_id = -400089
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- WY Cynthia Lummis (L000571)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/L000571.jpg'
WHERE external_id = -400090
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- ============================================================
-- SECTION C: Photo backfill for 6 remaining existing senators (MA, ME, TX)
-- These rows were imported pre-Phase 73. Current photo_origin_url values are
-- Wikipedia page URLs (non-null, non-empty). The IS NULL OR = '' guard means
-- these UPDATEs will be no-ops (same as Padilla in migration 175). Included
-- for completeness and future re-runs if Wikipedia URLs are ever cleared.
--
-- DB confirmed (2026-05-19):
--   external_id=-200101, full_name='Elizabeth Warren',   photo=Wikipedia URL
--   external_id=-200102, full_name='Edward J. Markey',   photo=Wikipedia URL
--   external_id=-230101, full_name='Susan M. Collins',   photo=Wikipedia URL
--   external_id=-230102, full_name='Angus S. King, Jr.', photo=Wikipedia URL
--   external_id=-100201, full_name='John Cornyn',        photo=Wikipedia URL
--   external_id=-100200, full_name='Ted Cruz',           photo=Wikipedia URL
-- ============================================================

-- Backfill photo for existing MA senator Elizabeth Warren (-200101, W000817)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000817.jpg'
WHERE external_id = -200101
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Backfill photo for existing MA senator Edward J. Markey (-200102, M000133)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M000133.jpg'
WHERE external_id = -200102
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Backfill photo for existing ME senator Susan M. Collins (-230101, C001035)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001035.jpg'
WHERE external_id = -230101
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Backfill photo for existing ME senator Angus S. King, Jr. (-230102, K000383)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000383.jpg'
WHERE external_id = -230102
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Backfill photo for existing TX senator John Cornyn (-100201, C001056)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001056.jpg'
WHERE external_id = -100201
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Backfill photo for existing TX senator Ted Cruz (-100200, C001098)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001098.jpg'
WHERE external_id = -100200
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- ============================================================
-- SECTION D: office_id back-fill for the 48 new senators
-- Scoped to this migration's external_id range.
-- Guard: p.office_id IS NULL ensures idempotency.
-- ============================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -400090 AND -400043
  AND p.office_id IS NULL;

COMMIT;

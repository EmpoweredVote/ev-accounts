-- Migration 175: US Senators AK through MS (42 new senators, alphabetical first half)
--
-- Purpose: Insert 42 new US Senator politician rows for states AK–MS, create their
--   office rows on the correct NATIONAL_UPPER district per state, set photo_origin_url
--   from unitedstates.github.io CDN, and backfill photo_origin_url for the 4 existing
--   CA/IN senators that were imported pre-Phase 73.
--
-- Pre-state:  10 existing senators (CA: Padilla + Schiff, IN: Young + Banks,
--   MA: Warren + Markey, ME: Collins + King, TX: Cornyn + Cruz)
-- Post-state: 10 existing + 42 new = 52 senators reachable via NATIONAL_UPPER districts
--
-- Expected row counts after this migration:
--   essentials.politicians WHERE external_id BETWEEN -400042 AND -400001: 42
--   essentials.offices linked to those 42: 42
--   essentials.politicians WHERE external_id BETWEEN -400042 AND -400001 AND photo_origin_url IS NULL: 0
--   essentials.politicians (all, via NATIONAL_UPPER offices): 52
--
-- Plan 73-02 adds the remaining 48 senators (states MT–WY) in migration 176.
--
-- Bioguide verification (2026-05-19):
--   K000368 Mark Kelly (AZ)      — verified HTTP 200, 17.5KB JPEG
--   K000383 Angus King (ME)      — verified HTTP 200, 48.6KB JPEG (existing senator, photo backfill only)
--   Y000064 Todd Young (IN)      — verified HTTP 200, 51.8KB JPEG (existing senator, photo backfill only)
--   H001079 Cindy Hyde-Smith (MS) — verified HTTP 200, 8.8KB JPEG
--     CORRECTION: research file listed H001102, but that ID returns 404.
--     Correct bioguide confirmed via unitedstates/congress-legislators YAML (legislators-current.yaml).
--
-- Idempotency:
--   - ON CONFLICT (external_id) DO NOTHING on politicians prevents duplicate rows
--   - NOT EXISTS guard on offices prevents duplicate office rows
--   - photo_origin_url UPDATE is guarded with IS NULL OR = ''
--   - office_id backfill is guarded with p.office_id IS NULL
--   Safe to re-run: second apply is a no-op.
--
-- Chamber UUID (U.S. Senate — confirmed in migrations 155, 170, 103):
--   7cbe07bc-84b8-433b-952b-540e7de18a92

BEGIN;

-- ============================================================
-- SECTION A: 42 new senator INSERT blocks (AK through MS)
-- ============================================================

-- ----- Lisa Murkowski (-400001) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Murkowski', 'Lisa', 'Murkowski', 'Republican',
          true, false, false, true, -400001)
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
       'Senator', 'AK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Dan Sullivan (-400002) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Sullivan', 'Dan', 'Sullivan', 'Republican',
          true, false, false, true, -400002)
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
       'Senator', 'AK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tommy Tuberville (-400003) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tommy Tuberville', 'Tommy', 'Tuberville', 'Republican',
          true, false, false, true, -400003)
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
       'Senator', 'AL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Katie Britt (-400004) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katie Britt', 'Katie', 'Britt', 'Republican',
          true, false, false, true, -400004)
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
       'Senator', 'AL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Boozman (-400005) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Boozman', 'John', 'Boozman', 'Republican',
          true, false, false, true, -400005)
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
       'Senator', 'AR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tom Cotton (-400006) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Cotton', 'Tom', 'Cotton', 'Republican',
          true, false, false, true, -400006)
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
       'Senator', 'AR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mark Kelly (-400007) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Kelly', 'Mark', 'Kelly', 'Democrat',
          true, false, false, true, -400007)
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
       'Senator', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AZ'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ruben Gallego (-400008) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ruben Gallego', 'Ruben', 'Gallego', 'Democrat',
          true, false, false, true, -400008)
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
       'Senator', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AZ'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Michael Bennet (-400009) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Bennet', 'Michael', 'Bennet', 'Democrat',
          true, false, false, true, -400009)
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
       'Senator', 'CO', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CO'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Hickenlooper (-400010) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Hickenlooper', 'John', 'Hickenlooper', 'Democrat',
          true, false, false, true, -400010)
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
       'Senator', 'CO', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CO'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Richard Blumenthal (-400011) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Blumenthal', 'Richard', 'Blumenthal', 'Democrat',
          true, false, false, true, -400011)
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
       'Senator', 'CT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Christopher Murphy (-400012) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Christopher Murphy', 'Christopher', 'Murphy', 'Democrat',
          true, false, false, true, -400012)
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
       'Senator', 'CT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Chris Coons (-400013) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Coons', 'Chris', 'Coons', 'Democrat',
          true, false, false, true, -400013)
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
       'Senator', 'DE', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'DE'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Lisa Blunt Rochester (-400014) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Blunt Rochester', 'Lisa', 'Blunt Rochester', 'Democrat',
          true, false, false, true, -400014)
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
       'Senator', 'DE', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'DE'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Rick Scott (-400015) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rick Scott', 'Rick', 'Scott', 'Republican',
          true, false, false, true, -400015)
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
       'Senator', 'FL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'FL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ashley Moody (-400016) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ashley Moody', 'Ashley', 'Moody', 'Republican',
          true, false, false, true, -400016)
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
       'Senator', 'FL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'FL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jon Ossoff (-400017) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jon Ossoff', 'Jon', 'Ossoff', 'Democrat',
          true, false, false, true, -400017)
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
       'Senator', 'GA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'GA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Raphael Warnock (-400018) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raphael Warnock', 'Raphael', 'Warnock', 'Democrat',
          true, false, false, true, -400018)
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
       'Senator', 'GA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'GA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Brian Schatz (-400019) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Schatz', 'Brian', 'Schatz', 'Democrat',
          true, false, false, true, -400019)
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
       'Senator', 'HI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'HI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mazie Hirono (-400020) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mazie Hirono', 'Mazie', 'Hirono', 'Democrat',
          true, false, false, true, -400020)
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
       'Senator', 'HI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'HI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Chuck Grassley (-400021) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chuck Grassley', 'Chuck', 'Grassley', 'Republican',
          true, false, false, true, -400021)
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
       'Senator', 'IA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Joni Ernst (-400022) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joni Ernst', 'Joni', 'Ernst', 'Republican',
          true, false, false, true, -400022)
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
       'Senator', 'IA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mike Crapo (-400023) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Crapo', 'Mike', 'Crapo', 'Republican',
          true, false, false, true, -400023)
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
       'Senator', 'ID', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ID'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- James Risch (-400024) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Risch', 'James', 'Risch', 'Republican',
          true, false, false, true, -400024)
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
       'Senator', 'ID', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ID'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Richard Durbin (-400025) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard Durbin', 'Richard', 'Durbin', 'Democrat',
          true, false, false, true, -400025)
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
       'Senator', 'IL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tammy Duckworth (-400026) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tammy Duckworth', 'Tammy', 'Duckworth', 'Democrat',
          true, false, false, true, -400026)
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
       'Senator', 'IL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Jerry Moran (-400027) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jerry Moran', 'Jerry', 'Moran', 'Republican',
          true, false, false, true, -400027)
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
       'Senator', 'KS', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KS'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Roger Marshall (-400028) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Marshall', 'Roger', 'Marshall', 'Republican',
          true, false, false, true, -400028)
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
       'Senator', 'KS', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KS'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mitch McConnell (-400029) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mitch McConnell', 'Mitch', 'McConnell', 'Republican',
          true, false, false, true, -400029)
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
       'Senator', 'KY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Rand Paul (-400030) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rand Paul', 'Rand', 'Paul', 'Republican',
          true, false, false, true, -400030)
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
       'Senator', 'KY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Bill Cassidy (-400031) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bill Cassidy', 'Bill', 'Cassidy', 'Republican',
          true, false, false, true, -400031)
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
       'Senator', 'LA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'LA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Kennedy (-400032) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Kennedy', 'John', 'Kennedy', 'Republican',
          true, false, false, true, -400032)
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
       'Senator', 'LA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'LA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Chris Van Hollen (-400033) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Van Hollen', 'Chris', 'Van Hollen', 'Democrat',
          true, false, false, true, -400033)
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
       'Senator', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Angela Alsobrooks (-400034) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angela Alsobrooks', 'Angela', 'Alsobrooks', 'Democrat',
          true, false, false, true, -400034)
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
       'Senator', 'MD', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MD'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Gary Peters (-400035) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Gary Peters', 'Gary', 'Peters', 'Democrat',
          true, false, false, true, -400035)
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
       'Senator', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Elissa Slotkin (-400036) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elissa Slotkin', 'Elissa', 'Slotkin', 'Democrat',
          true, false, false, true, -400036)
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
       'Senator', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Amy Klobuchar (-400037) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Amy Klobuchar', 'Amy', 'Klobuchar', 'Democrat',
          true, false, false, true, -400037)
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
       'Senator', 'MN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Tina Smith (-400038) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tina Smith', 'Tina', 'Smith', 'Democrat',
          true, false, false, true, -400038)
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
       'Senator', 'MN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Josh Hawley (-400039) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josh Hawley', 'Josh', 'Hawley', 'Republican',
          true, false, false, true, -400039)
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
       'Senator', 'MO', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MO'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Eric Schmitt (-400040) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Schmitt', 'Eric', 'Schmitt', 'Republican',
          true, false, false, true, -400040)
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
       'Senator', 'MO', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MO'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Roger Wicker (-400041) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Wicker', 'Roger', 'Wicker', 'Republican',
          true, false, false, true, -400041)
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
       'Senator', 'MS', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MS'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Cindy Hyde-Smith (-400042) -----
-- Note: bioguide corrected from H001102 (404) to H001079 (verified)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cindy Hyde-Smith', 'Cindy', 'Hyde-Smith', 'Republican',
          true, false, false, true, -400042)
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
       'Senator', 'MS', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MS'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION B: photo_origin_url UPDATE for the 42 new senators
-- ============================================================

-- ===== Photo URLs (AK–MS, external_ids -400001 through -400042) =====

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001153.jpg'
WHERE external_id = -400001
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001198.jpg'
WHERE external_id = -400002
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/T000278.jpg'
WHERE external_id = -400003
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001310.jpg'
WHERE external_id = -400004
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001236.jpg'
WHERE external_id = -400005
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001095.jpg'
WHERE external_id = -400006
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000368.jpg'
WHERE external_id = -400007
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/G000574.jpg'
WHERE external_id = -400008
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001267.jpg'
WHERE external_id = -400009
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H000273.jpg'
WHERE external_id = -400010
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001277.jpg'
WHERE external_id = -400011
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001169.jpg'
WHERE external_id = -400012
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001088.jpg'
WHERE external_id = -400013
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/B001303.jpg'
WHERE external_id = -400014
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001217.jpg'
WHERE external_id = -400015
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001244.jpg'
WHERE external_id = -400016
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/O000174.jpg'
WHERE external_id = -400017
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000790.jpg'
WHERE external_id = -400018
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001194.jpg'
WHERE external_id = -400019
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001042.jpg'
WHERE external_id = -400020
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/G000386.jpg'
WHERE external_id = -400021
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/E000295.jpg'
WHERE external_id = -400022
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C000880.jpg'
WHERE external_id = -400023
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/R000584.jpg'
WHERE external_id = -400024
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/D000563.jpg'
WHERE external_id = -400025
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/D000622.jpg'
WHERE external_id = -400026
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M000934.jpg'
WHERE external_id = -400027
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001198.jpg'
WHERE external_id = -400028
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M000355.jpg'
WHERE external_id = -400029
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/P000603.jpg'
WHERE external_id = -400030
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/C001075.jpg'
WHERE external_id = -400031
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000393.jpg'
WHERE external_id = -400032
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/V000128.jpg'
WHERE external_id = -400033
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/A000382.jpg'
WHERE external_id = -400034
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/P000595.jpg'
WHERE external_id = -400035
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001208.jpg'
WHERE external_id = -400036
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/K000367.jpg'
WHERE external_id = -400037
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001203.jpg'
WHERE external_id = -400038
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001089.jpg'
WHERE external_id = -400039
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001212.jpg'
WHERE external_id = -400040
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000437.jpg'
WHERE external_id = -400041
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Cindy Hyde-Smith: corrected bioguide H001079 (H001102 was wrong — 404)
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/H001079.jpg'
WHERE external_id = -400042
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- ============================================================
-- SECTION C: Photo backfill for 4 existing CA + IN senators
-- These rows were imported pre-Phase 73 and lack GitHub CDN URLs.
-- Using name + NATIONAL_UPPER state JOIN since they have BallotReady
-- integer external_ids (not our negative synthetic scheme).
-- NOTE: DB confirmed full_name = 'Adam B. Schiff' (includes middle initial).
-- NOTE: Alex Padilla already has a city-of-Inglewood URL (non-null/non-empty);
--       that UPDATE will be a no-op due to the IS NULL OR = '' guard. Still
--       included for completeness and future re-runs after a URL reset.
-- ============================================================

-- Backfill photo for existing CA senator Alex Padilla (P000145)
UPDATE essentials.politicians p
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/P000145.jpg'
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE o.politician_id = p.id
  AND d.district_type = 'NATIONAL_UPPER'
  AND d.state = 'CA'
  AND p.full_name = 'Alex Padilla'
  AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '');

-- Backfill photo for existing CA senator Adam B. Schiff (S001150)
UPDATE essentials.politicians p
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/S001150.jpg'
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE o.politician_id = p.id
  AND d.district_type = 'NATIONAL_UPPER'
  AND d.state = 'CA'
  AND p.full_name = 'Adam B. Schiff'
  AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '');

-- Backfill photo for existing IN senator Todd Young (Y000064)
UPDATE essentials.politicians p
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/Y000064.jpg'
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE o.politician_id = p.id
  AND d.district_type = 'NATIONAL_UPPER'
  AND d.state = 'IN'
  AND p.full_name = 'Todd Young'
  AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '');

-- Backfill photo for existing IN senator Jim Banks (B001299)
UPDATE essentials.politicians p
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/B001299.jpg'
FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
WHERE o.politician_id = p.id
  AND d.district_type = 'NATIONAL_UPPER'
  AND d.state = 'IN'
  AND p.full_name = 'Jim Banks'
  AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '');

-- ============================================================
-- SECTION D: office_id back-fill for the 42 new senators
-- Scoped to this migration's external_id range.
-- Guard: p.office_id IS NULL ensures idempotency.
-- ============================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -400042 AND -400001
  AND p.office_id IS NULL;

COMMIT;

-- Migration 196: 2026 US Senate Candidates (43 non-incumbent declared candidates)
--
-- Purpose: Insert 43 major non-incumbent 2026 US Senate candidates as
--   essentials.politicians rows with candidate office rows on the correct
--   NATIONAL_UPPER district per state. Provides the data foundation for
--   Phase 76 stance research and compass compare view.
--
-- Pre-state:  100 sitting senators from Phase 73 (migrations 175 + 176)
-- Post-state: 100 senators + 43 candidates (143 politicians reachable via
--   NATIONAL_UPPER offices); candidates identified by:
--   essentials.offices.title LIKE 'Candidate for U.S. Senate%'
--   + essentials.politicians.is_incumbent = false
--
-- NOTE: essentials.politicians has NO office_title column.
--   office_title is always derived as o.title AS office_title from essentials.offices.
--   essentials.offices has NO is_current column.
--   The offices INSERT column list is:
--     id, district_id, chamber_id, politician_id, title, representing_state,
--     is_appointed_position, is_vacant, role_canonical
--
-- Expected row counts after this migration:
--   essentials.politicians WHERE external_id BETWEEN -400143 AND -400101: 43
--   essentials.offices WHERE title LIKE 'Candidate for U.S. Senate%': 43
--   essentials.politicians WHERE external_id BETWEEN -400143 AND -400101
--     AND (photo_origin_url IS NULL OR photo_origin_url = ''): 8
--     (Explicit-null candidates: Larriett, Shoffner, Joshi, Roth, Tracy, Colom, Andrews, Fetty Anderson)
--
-- Pre-flight findings (Task 1, 2026-05-22):
--   Chamber UUID = '7cbe07bc-84b8-433b-952b-540e7de18a92' (confirmed)
--   NATIONAL_UPPER districts = 50 states, 1 each (no disambiguation needed)
--   Sherrod Brown = no existing record in DB; INSERT new at external_id -400137
--   Jon Husted (-400061) = exists, is_appointed=true — NOT touched here
--   Alan Armstrong (-400064) = exists, is_appointed=true — NOT touched here
--
-- Bioguide HEAD-verification (2026-05-22, all returned HTTP 200):
--   M001212 Barry Moore (AL)         S001215 Haley Stevens (MI)
--   C001129 Mike Collins (GA)        C001119 Angie Craig (MN)
--   H001091 Ashley Hinson (IA)       P000614 Chris Pappas (NH)
--   B001282 Andy Barr (KY)           H001082 Kevin Hern (OK)
--   L000595 Julia Letlow (LA)        H001096 Harriet Hageman (WY)
--   M001196 Seth Moulton (MA)        F000456 John Fleming (LA, hist.)
--   R000572 Mike Rogers (MI, hist.)  P000619 Mary Peltola (AK, hist.)
--   S001078 John Sununu (NH, hist.)  B000944 Sherrod Brown (OH, hist.)
--
-- Explicit-null candidates (no stable public photo found 2026-05-22):
--   -400103 Dakarai Larriett (AL-D)
--   -400105 Hallie Shoffner (AR-D)
--   -400106 Janak Joshi (CO-R)
--   -400111 David Roth (ID-D)
--   -400113 Don Tracy (IL-R)
--   -400129 Scott Colom (MS-D)
--   -400140 Annie Andrews (SC-D)
--   -400141 Rachel Fetty Anderson (WV-D)
--
-- Idempotency:
--   - ON CONFLICT (external_id) DO NOTHING on politicians prevents duplicate rows
--   - NOT EXISTS guard on offices prevents duplicate office rows
--   - photo_origin_url UPDATE is guarded with IS NULL OR = ''
--   Safe to re-run: second apply is a no-op.
--
-- Chamber UUID (U.S. Senate — confirmed in migrations 155, 170, 103, 175, 176):
--   7cbe07bc-84b8-433b-952b-540e7de18a92

BEGIN;

-- ============================================================
-- SECTION A: 43 candidate politician + office INSERT blocks
-- (ordered alphabetically by state, then by external_id within state)
-- NOTE: essentials.politicians has no office_title column.
--       Candidate identity is stored in essentials.offices.title.
--       essentials.offices has no is_current column.
-- ============================================================

-- ----- Steve Marshall (-400101, AL-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Marshall', 'Steve', 'Marshall', 'Republican',
          true, false, false, false, -400101)
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
       'Candidate for U.S. Senate — Alabama', 'AL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Barry Moore (-400102, AL-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Barry Moore', 'Barry', 'Moore', 'Republican',
          true, false, false, false, -400102)
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
       'Candidate for U.S. Senate — Alabama', 'AL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Dakarai Larriett (-400103, AL-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dakarai Larriett', 'Dakarai', 'Larriett', 'Democratic',
          true, false, false, false, -400103)
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
       'Candidate for U.S. Senate — Alabama', 'AL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mary Peltola (-400104, AK-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mary Peltola', 'Mary', 'Peltola', 'Democratic',
          true, false, false, false, -400104)
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
       'Candidate for U.S. Senate — Alaska', 'AK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Hallie Shoffner (-400105, AR-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hallie Shoffner', 'Hallie', 'Shoffner', 'Democratic',
          true, false, false, false, -400105)
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
       'Candidate for U.S. Senate — Arkansas', 'AR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Janak Joshi (-400106, CO-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Janak Joshi', 'Janak', 'Joshi', 'Republican',
          true, false, false, false, -400106)
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
       'Candidate for U.S. Senate — Colorado', 'CO', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'CO'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Alex Vindman (-400107, FL-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alex Vindman', 'Alex', 'Vindman', 'Democratic',
          true, false, false, false, -400107)
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
       'Candidate for U.S. Senate — Florida', 'FL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'FL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Angie Nixon (-400108, FL-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angie Nixon', 'Angie', 'Nixon', 'Democratic',
          true, false, false, false, -400108)
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
       'Candidate for U.S. Senate — Florida', 'FL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'FL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mike Collins (-400109, GA-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Collins', 'Mike', 'Collins', 'Republican',
          true, false, false, false, -400109)
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
       'Candidate for U.S. Senate — Georgia', 'GA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'GA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Derek Dooley (-400110, GA-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Derek Dooley', 'Derek', 'Dooley', 'Republican',
          true, false, false, false, -400110)
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
       'Candidate for U.S. Senate — Georgia', 'GA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'GA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- David Roth (-400111, ID-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Roth', 'David', 'Roth', 'Democratic',
          true, false, false, false, -400111)
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
       'Candidate for U.S. Senate — Idaho', 'ID', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ID'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Juliana Stratton (-400112, IL-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Juliana Stratton', 'Juliana', 'Stratton', 'Democratic',
          true, false, false, false, -400112)
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
       'Candidate for U.S. Senate — Illinois', 'IL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Don Tracy (-400113, IL-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Don Tracy', 'Don', 'Tracy', 'Republican',
          true, false, false, false, -400113)
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
       'Candidate for U.S. Senate — Illinois', 'IL', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IL'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Ashley Hinson (-400114, IA-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ashley Hinson', 'Ashley', 'Hinson', 'Republican',
          true, false, false, false, -400114)
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
       'Candidate for U.S. Senate — Iowa', 'IA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Zach Wahls (-400115, IA-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Zach Wahls', 'Zach', 'Wahls', 'Democratic',
          true, false, false, false, -400115)
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
       'Candidate for U.S. Senate — Iowa', 'IA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'IA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Charles Booker (-400116, KY-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Charles Booker', 'Charles', 'Booker', 'Democratic',
          true, false, false, false, -400116)
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
       'Candidate for U.S. Senate — Kentucky', 'KY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Andy Barr (-400117, KY-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andy Barr', 'Andy', 'Barr', 'Republican',
          true, false, false, false, -400117)
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
       'Candidate for U.S. Senate — Kentucky', 'KY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'KY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Julia Letlow (-400118, LA-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julia Letlow', 'Julia', 'Letlow', 'Republican',
          true, false, false, false, -400118)
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
       'Candidate for U.S. Senate — Louisiana', 'LA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'LA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Fleming (-400119, LA-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Fleming', 'John', 'Fleming', 'Republican',
          true, false, false, false, -400119)
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
       'Candidate for U.S. Senate — Louisiana', 'LA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'LA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Graham Platner (-400120, ME-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Graham Platner', 'Graham', 'Platner', 'Democratic',
          true, false, false, false, -400120)
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
       'Candidate for U.S. Senate — Maine', 'ME', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'ME'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Seth Moulton (-400121, MA-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Seth Moulton', 'Seth', 'Moulton', 'Democratic',
          true, false, false, false, -400121)
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
       'Candidate for U.S. Senate — Massachusetts', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Abdul El-Sayed (-400122, MI-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abdul El-Sayed', 'Abdul', 'El-Sayed', 'Democratic',
          true, false, false, false, -400122)
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
       'Candidate for U.S. Senate — Michigan', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mallory McMorrow (-400123, MI-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mallory McMorrow', 'Mallory', 'McMorrow', 'Democratic',
          true, false, false, false, -400123)
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
       'Candidate for U.S. Senate — Michigan', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Haley Stevens (-400124, MI-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Haley Stevens', 'Haley', 'Stevens', 'Democratic',
          true, false, false, false, -400124)
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
       'Candidate for U.S. Senate — Michigan', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Mike Rogers (-400125, MI-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mike Rogers', 'Mike', 'Rogers', 'Republican',
          true, false, false, false, -400125)
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
       'Candidate for U.S. Senate — Michigan', 'MI', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MI'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Peggy Flanagan (-400126, MN-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Peggy Flanagan', 'Peggy', 'Flanagan', 'Democratic',
          true, false, false, false, -400126)
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
       'Candidate for U.S. Senate — Minnesota', 'MN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Angie Craig (-400127, MN-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angie Craig', 'Angie', 'Craig', 'Democratic',
          true, false, false, false, -400127)
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
       'Candidate for U.S. Senate — Minnesota', 'MN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Royce White (-400128, MN-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Royce White', 'Royce', 'White', 'Republican',
          true, false, false, false, -400128)
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
       'Candidate for U.S. Senate — Minnesota', 'MN', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MN'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Scott Colom (-400129, MS-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Scott Colom', 'Scott', 'Colom', 'Democratic',
          true, false, false, false, -400129)
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
       'Candidate for U.S. Senate — Mississippi', 'MS', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MS'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Kurt Alme (-400130, MT-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kurt Alme', 'Kurt', 'Alme', 'Republican',
          true, false, false, false, -400130)
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
       'Candidate for U.S. Senate — Montana', 'MT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Seth Bodnar (-400131, MT-I) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Seth Bodnar', 'Seth', 'Bodnar', 'Independent',
          true, false, false, false, -400131)
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
       'Candidate for U.S. Senate — Montana', 'MT', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MT'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Dan Osborn (-400132, NE-I) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Osborn', 'Dan', 'Osborn', 'Independent',
          true, false, false, false, -400132)
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
       'Candidate for U.S. Senate — Nebraska', 'NE', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NE'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Chris Pappas (-400133, NH-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chris Pappas', 'Chris', 'Pappas', 'Democratic',
          true, false, false, false, -400133)
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
       'Candidate for U.S. Senate — New Hampshire', 'NH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- John Sununu (-400134, NH-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'John Sununu', 'John', 'Sununu', 'Republican',
          true, false, false, false, -400134)
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
       'Candidate for U.S. Senate — New Hampshire', 'NH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Roy Cooper (-400135, NC-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roy Cooper', 'Roy', 'Cooper', 'Democratic',
          true, false, false, false, -400135)
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
       'Candidate for U.S. Senate — North Carolina', 'NC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Michael Whatley (-400136, NC-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Whatley', 'Michael', 'Whatley', 'Republican',
          true, false, false, false, -400136)
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
       'Candidate for U.S. Senate — North Carolina', 'NC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'NC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Sherrod Brown (-400137, OH-D) -----
-- Task 1.D: No existing record found. INSERT new at external_id=-400137.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sherrod Brown', 'Sherrod', 'Brown', 'Democratic',
          true, false, false, false, -400137)
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
       'Candidate for U.S. Senate — Ohio', 'OH', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OH'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Kevin Hern (-400138, OK-R) -----
-- NOTE: Alan Armstrong (-400064, is_appointed=true) already exists in DB.
--   Armstrong agreed not to run for the full term. Kevin Hern IS the R candidate.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kevin Hern', 'Kevin', 'Hern', 'Republican',
          true, false, false, false, -400138)
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
       'Candidate for U.S. Senate — Oklahoma', 'OK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- David Brock Smith (-400139, OR-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Brock Smith', 'David', 'Brock Smith', 'Republican',
          true, false, false, false, -400139)
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
       'Candidate for U.S. Senate — Oregon', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'OR'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Annie Andrews (-400140, SC-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Annie Andrews', 'Annie', 'Andrews', 'Democratic',
          true, false, false, false, -400140)
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
       'Candidate for U.S. Senate — South Carolina', 'SC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'SC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Rachel Fetty Anderson (-400141, WV-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachel Fetty Anderson', 'Rachel', 'Fetty Anderson', 'Democratic',
          true, false, false, false, -400141)
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
       'Candidate for U.S. Senate — West Virginia', 'WV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WV'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Harriet Hageman (-400142, WY-R) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Harriet Hageman', 'Harriet', 'Hageman', 'Republican',
          true, false, false, false, -400142)
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
       'Candidate for U.S. Senate — Wyoming', 'WY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- James Byrd (-400143, WY-D) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'James Byrd', 'James', 'Byrd', 'Democratic',
          true, false, false, false, -400143)
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
       'Candidate for U.S. Senate — Wyoming', 'WY', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'WY'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ============================================================
-- SECTION B: photo_origin_url UPDATEs (guarded with IS NULL OR = '')
-- URLs HEAD-verified 2026-05-22; bioguide CDN URLs for current/former
-- Congress members, Wikipedia for others.
-- Candidates with no verified photo URL (left NULL — see header above):
--   -400103 Dakarai Larriett (AL-D)
--   -400105 Hallie Shoffner (AR-D)
--   -400106 Janak Joshi (CO-R)
--   -400111 David Roth (ID-D)
--   -400113 Don Tracy (IL-R)
--   -400129 Scott Colom (MS-D)
--   -400140 Annie Andrews (SC-D)
--   -400141 Rachel Fetty Anderson (WV-D)
-- ============================================================

-- Steve Marshall (-400101) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/8/87/Steve_Marshall_%2841773693585%29.jpg'
WHERE external_id = -400101
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Barry Moore (-400102) — CDN bioguide M001212
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/M001212.jpg'
WHERE external_id = -400102
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Dakarai Larriett (-400103) — no photo, skip

-- Mary Peltola (-400104) — CDN bioguide P000619 (historical)
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/P000619.jpg'
WHERE external_id = -400104
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Hallie Shoffner (-400105) — no photo, skip

-- Janak Joshi (-400106) — no photo, skip

-- Alex Vindman (-400107) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/0/07/Alexander_Vindman_on_May_20%2C_2019.jpg'
WHERE external_id = -400107
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Angie Nixon (-400108) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/5/54/Angie_Nixon_newer.jpg'
WHERE external_id = -400108
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Mike Collins (-400109) — CDN bioguide C001129
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/C001129.jpg'
WHERE external_id = -400109
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Derek Dooley (-400110) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/c/cf/Derekdooleyorangewhite.jpg'
WHERE external_id = -400110
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- David Roth (-400111) — no photo, skip

-- Juliana Stratton (-400112) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/a/a8/Juliana_Stratton_2023_%28cropped%29.jpg'
WHERE external_id = -400112
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Don Tracy (-400113) — no photo, skip

-- Ashley Hinson (-400114) — CDN bioguide H001091
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/H001091.jpg'
WHERE external_id = -400114
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Zach Wahls (-400115) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/d/d9/Member_of_the_Iowa_Senate_Zacharia_Wahls.jpg'
WHERE external_id = -400115
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Charles Booker (-400116) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/3/3d/Charles_solar_panels_%28cropped%29.jpg'
WHERE external_id = -400116
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Andy Barr (-400117) — CDN bioguide B001282
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/B001282.jpg'
WHERE external_id = -400117
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Julia Letlow (-400118) — CDN bioguide L000595
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/L000595.jpg'
WHERE external_id = -400118
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- John Fleming (-400119) — CDN bioguide F000456 (historical)
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/F000456.jpg'
WHERE external_id = -400119
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Graham Platner (-400120) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/1/1a/Platner_headshot.jpg'
WHERE external_id = -400120
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Seth Moulton (-400121) — CDN bioguide M001196
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/M001196.jpg'
WHERE external_id = -400121
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Abdul El-Sayed (-400122) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/2/26/Abdul_El-Sayed.jpg'
WHERE external_id = -400122
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Mallory McMorrow (-400123) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/6/6f/Mallory_McMorrow_in_2023_-_8R4A5252.jpg'
WHERE external_id = -400123
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Haley Stevens (-400124) — CDN bioguide S001215
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/S001215.jpg'
WHERE external_id = -400124
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Mike Rogers (-400125) — CDN bioguide R000572 (historical)
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/R000572.jpg'
WHERE external_id = -400125
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Peggy Flanagan (-400126) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/c/c6/2026PeggyFlanagan.jpg'
WHERE external_id = -400126
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Angie Craig (-400127) — CDN bioguide C001119
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/C001119.jpg'
WHERE external_id = -400127
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Royce White (-400128) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/c/c9/Royce_White_speaks_at_Native_Lives_Matter_Rally_%28cropped%29.jpg'
WHERE external_id = -400128
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Scott Colom (-400129) — no photo, skip

-- Kurt Alme (-400130) — Wikipedia (DOJ official photo)
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/5/5e/Kurt_G._Alme_official_photo.jpg'
WHERE external_id = -400130
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Seth Bodnar (-400131) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/3/31/Seth_Bodnar_-_President_at_University_of_Montana_%28cropped%29.jpg'
WHERE external_id = -400131
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Dan Osborn (-400132) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/9/95/Osborn_Headshot_2_%28cropped%29.jpg'
WHERE external_id = -400132
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Chris Pappas (-400133) — CDN bioguide P000614
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/P000614.jpg'
WHERE external_id = -400133
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- John Sununu (-400134) — CDN bioguide S001078 (historical senator)
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/S001078.jpg'
WHERE external_id = -400134
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Roy Cooper (-400135) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/3/30/Roy_Cooper_in_November_2023_%28cropped2%29.jpg'
WHERE external_id = -400135
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Michael Whatley (-400136) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/b/b5/Michael_Whatley_%2854670563614%29_%28cropped%29.jpg'
WHERE external_id = -400136
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Sherrod Brown (-400137) — CDN bioguide B000944 (historical senator)
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/B000944.jpg'
WHERE external_id = -400137
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Kevin Hern (-400138) — CDN bioguide H001082
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/H001082.jpg'
WHERE external_id = -400138
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- David Brock Smith (-400139) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/1/10/DBS_FB_Profile.jpg'
WHERE external_id = -400139
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- Annie Andrews (-400140) — no photo, skip

-- Rachel Fetty Anderson (-400141) — no photo, skip

-- Harriet Hageman (-400142) — CDN bioguide H001096
UPDATE essentials.politicians SET photo_origin_url = 'https://unitedstates.github.io/images/congress/225x275/H001096.jpg'
WHERE external_id = -400142
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

-- James Byrd (-400143) — Wikipedia
UPDATE essentials.politicians SET photo_origin_url = 'https://upload.wikimedia.org/wikipedia/commons/6/61/James_W._Byrd_at_Campbell_County_League_of_Women_Voters%27_General_Election_Candidates%27_Forum_in_Gillette%2C_Wyoming_%28cropped%29.jpg'
WHERE external_id = -400143
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

COMMIT;

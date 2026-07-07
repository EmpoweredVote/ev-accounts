-- Migration 1203: Beaverton SD 48J + Hillsboro SD 1J school boards (wave 1)
--
-- Purpose: Deep-seeds BOTH west-metro school-district governments end-to-end:
--   Beaverton School District 48J (geo_id='4101920') -- 1 gov + 'School Board' chamber
--     (official_count=7) + 1 shared SCHOOL district + 7 directors (Zones 1-7).
--   Hillsboro School District 1J (geo_id='4100023') -- 1 gov + 'Board of Directors' chamber
--     (official_count=7) + 1 shared SCHOOL district + 7 directors (Positions 1-7).
--   Both boards are WHOLE-DISTRICT AT-LARGE (Wave-0 confirmed) -- one shared SCHOOL district
--   per government carries all 7 seats; there are NO sub-zone/per-seat districts or geofences.
--
-- Verbatim per-district chamber naming (D-R1/D-R2 -- deliberate deviation from the 254_or
-- precedent's blanket "Board of Education"): Beaverton = 'School Board'; Hillsboro =
-- 'Board of Directors'. Office titles: Beaverton 'Director, Zone N' (HIGH confidence, matches
-- the district's own election-filing language); Hillsboro 'Director, Position N' (MEDIUM
-- confidence, per ORS 332 statutory language + parallel filing convention). Chair/Vice-Chair
-- are title-on-seat suffixes on an existing director row, NOT separate offices -- 14 offices
-- total (7+7), not 16.
--
-- CRITICAL: the auto-generated column on essentials.chambers is GENERATED ALWAYS -- never in the
--           INSERT list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id/name -- every government
--           INSERT uses a WHERE NOT EXISTS name guard.
-- CRITICAL: districts.state must be 'or' (LOWERCASE) to match routing queries -- uppercase = 0
--           rows and a silently-empty office JOIN (the #1 pitfall this milestone).
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: both G5420 geofence rows (geo_id='4101920' / geo_id='4100023') ALREADY EXIST --
--           loaded by Phase 174. This migration does NOT run any geofence loader.
-- CRITICAL: party=NULL on all 14 directors (antipartisan mission).
-- CRITICAL: all 14 seats are ELECTED -- is_appointed=false on every politician,
--           is_appointed_position=false on every office (no appointed branch this phase).
-- CRITICAL: Chair/Vice-Chair are titles on existing elected seats, NOT separate rows -- 7 offices
--           per district (14 total), never 8/9 per district.
-- CRITICAL: this file is saved as UTF-8 -- the roster carries 'Vân Truong' (Vietnamese
--           circumflex) and 'Karen Pérez' (Spanish acute accent); do not drop the diacritics.
--
-- Applied to production Supabase via psql -f (DATABASE_URL from C:/EV-Accounts/backend/.env).
-- Ledger convention note: the freshest west-metro structural migrations (1159/1178/1196) register
-- with a (version)-only INSERT placed BEFORE COMMIT, inside the transaction -- that convention is
-- followed here rather than the older 1107-era (version, name) / after-COMMIT shape.

BEGIN;

-- =============================================================================
-- Pre-flight: idempotent NOTICE if either government already exists
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Beaverton School District 48J, Oregon, US') > 0 THEN
    RAISE NOTICE 'Beaverton School District 48J government row already exists — skipping (idempotent re-run)';
  END IF;
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Hillsboro School District 1J, Oregon, US') > 0 THEN
    RAISE NOTICE 'Hillsboro School District 1J government row already exists — skipping (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows. type='LOCAL'. state='OR' uppercase. Standalone rows
-- (not nested under any parent government). WHERE NOT EXISTS guard -- governments
-- has no unique constraint on geo_id or name.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Beaverton School District 48J, Oregon, US',
       'LOCAL', 'OR', NULL, '4101920'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Beaverton School District 48J, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Hillsboro School District 1J, Oregon, US',
       'LOCAL', 'OR', NULL, '4100023'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Hillsboro School District 1J, Oregon, US'
);

-- =============================================================================
-- Step 2: Chambers. Verbatim per-district naming (D-R1/D-R2) -- NOT the 254_or blanket
-- "Board of Education". The auto-generated column is GENERATED ALWAYS -- never in the
-- INSERT list. official_count=7 each.
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'School Board',
       'Beaverton School District 48J School Board',
       (SELECT id FROM essentials.governments WHERE name = 'Beaverton School District 48J, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of Directors',
       'Hillsboro School District 1J Board of Directors',
       (SELECT id FROM essentials.governments WHERE name = 'Hillsboro School District 1J, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
);

-- =============================================================================
-- Step 3: ONE shared SCHOOL district per government (SF/SD/Portland/CCSD single-shared-district
-- pattern). district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT'); state='or' LOWERCASE; mtfcc='G5420'.
-- Both geo_ids' G5420 geofence rows ALREADY EXIST (Phase 174) -- no loader run here.
-- All 7 director offices per district attach to this ONE row -- NOT one district per seat.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4101920', 'Beaverton School District 48J', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4101920' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4100023', 'Hillsboro School District 1J', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4100023' AND district_type = 'SCHOOL' AND state = 'or'
);

-- =============================================================================
-- Step 4: Politicians + offices -- 14 blocks (7 Beaverton + 7 Hillsboro).
-- All seats ELECTED: is_appointed=false, is_appointed_position=false. party=NULL (antipartisan).
-- is_active=true, is_incumbent=true, is_vacant=false on every row.
-- representing_state='OR' uppercase. ON CONFLICT (external_id) DO NOTHING; office guard
-- NOT EXISTS (district_id, politician_id).
-- =============================================================================

-- BEAVERTON SCHOOL DISTRICT 48J -- School Board (Zones 1-7)

-- Zone 1: Vân Truong (site spelling with Vietnamese circumflex; UTF-8 required) — -4101921
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Vân Truong', 'Vân', 'Truong', NULL,
          true, false, false, true, -4101921)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 1', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 2: Karen Pérez — -4101922
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Pérez', 'Karen', 'Pérez', NULL,
          true, false, false, true, -4101922)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 2', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 3: Melissa Potter (Vice Chair — title on seat, not a separate row) — -4101923
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melissa Potter', 'Melissa', 'Potter', NULL,
          true, false, false, true, -4101923)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 3 (Vice Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 4: Sunita Garg — -4101924
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sunita Garg', 'Sunita', 'Garg', NULL,
          true, false, false, true, -4101924)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 4', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 5: Syed Qasim — -4101925
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Syed Qasim', 'Syed', 'Qasim', NULL,
          true, false, false, true, -4101925)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 5', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 6: Justice Rajee (Chair — title on seat, not a separate row) — -4101926
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Justice Rajee', 'Justice', 'Rajee', NULL,
          true, false, false, true, -4101926)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 6 (Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Zone 7: Tammy Carpenter — -4101927
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Beaverton School District 48J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tammy Carpenter', 'Tammy', 'Carpenter', NULL,
          true, false, false, true, -4101927)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Zone 7', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- HILLSBORO SCHOOL DISTRICT 1J -- Board of Directors (Positions 1-7)

-- Position 1: Yessica Hardin Mercado — -4100024
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Yessica Hardin Mercado', 'Yessica', 'Hardin Mercado', NULL,
          true, false, false, true, -4100024)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 1', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 2: Mark Watson — -4100025
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Watson', 'Mark', 'Watson', NULL,
          true, false, false, true, -4100025)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 2', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 3: Nancy Thomas — -4100026
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Nancy Thomas', 'Nancy', 'Thomas', NULL,
          true, false, false, true, -4100026)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 3', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 4: See Eun Kim (Vice Chair — title on seat, not a separate row) — -4100027
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'See Eun Kim', 'See Eun', 'Kim', NULL,
          true, false, false, true, -4100027)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 4 (Vice Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 5: Ivette Pantoja (Chair — title on seat, not a separate row) — -4100028
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ivette Pantoja', 'Ivette', 'Pantoja', NULL,
          true, false, false, true, -4100028)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 5 (Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 6: Katie Rhyne — -4100029
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Katie Rhyne', 'Katie', 'Rhyne', NULL,
          true, false, false, true, -4100029)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 6', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 7: Patrick Maguire — -4100030
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Hillsboro School District 1J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patrick Maguire', 'Patrick', 'Maguire', NULL,
          true, false, false, true, -4100030)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 7', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (all 14 directors), idempotent.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (-4101921,-4101922,-4101923,-4101924,-4101925,-4101926,-4101927,
                         -4100024,-4100025,-4100026,-4100027,-4100028,-4100029,-4100030)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (RAISE EXCEPTION on any mismatch — rolls back the
-- whole migration). Gates: (a) exactly 1 government row per district; (b) exactly 7 offices
-- on each SCHOOL district; (c) 0 section-split orphan rows for both G5420 geo_ids;
-- (d) office_id back-fill completeness for all 14 directors.
-- =============================================================================
DO $$
DECLARE
  v_bsd_gov  INTEGER;
  v_hsd_gov  INTEGER;
  v_bsd_off  INTEGER;
  v_hsd_off  INTEGER;
  v_split    INTEGER;
  v_null_oid INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_bsd_gov FROM essentials.governments
  WHERE name = 'Beaverton School District 48J, Oregon, US';
  SELECT COUNT(*) INTO v_hsd_gov FROM essentials.governments
  WHERE name = 'Hillsboro School District 1J, Oregon, US';
  IF v_bsd_gov <> 1 OR v_hsd_gov <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 gov each, found BSD=%, HSD=%', v_bsd_gov, v_hsd_gov;
  END IF;

  SELECT COUNT(*) INTO v_bsd_off
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4101920' AND d.district_type = 'SCHOOL' AND d.state = 'or';
  SELECT COUNT(*) INTO v_hsd_off
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4100023' AND d.district_type = 'SCHOOL' AND d.state = 'or';
  IF v_bsd_off <> 7 OR v_hsd_off <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 offices each, found BSD=%, HSD=%', v_bsd_off, v_hsd_off;
  END IF;

  SELECT COUNT(*) INTO v_split
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('4101920','4100023') AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL' AND d.state = 'or'
    );
  IF v_split <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows', v_split;
  END IF;

  SELECT COUNT(*) INTO v_null_oid
  FROM essentials.politicians
  WHERE external_id IN (-4101921,-4101922,-4101923,-4101924,-4101925,-4101926,-4101927,
                         -4100024,-4100025,-4100026,-4100027,-4100028,-4100029,-4100030)
    AND office_id IS NULL;
  IF v_null_oid <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % directors still have NULL office_id after back-fill', v_null_oid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: BSD gov=%/off=%, HSD gov=%/off=%, split_orphans=%, office_id_nulls=%',
    v_bsd_gov, v_bsd_off, v_hsd_gov, v_hsd_off, v_split, v_null_oid;
END $$;

-- =============================================================================
-- Step 7: Migration ledger registration — structural migrations register (version-only
-- form, matching the freshest west-metro convention in 1159/1178/1196), placed BEFORE COMMIT.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1203')
ON CONFLICT (version) DO NOTHING;

COMMIT;

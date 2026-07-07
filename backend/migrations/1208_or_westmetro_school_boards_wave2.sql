-- Migration 1208: Tigard-Tualatin SD 23J + Forest Grove SD 15 + Sherwood SD 88J school boards (wave 2)
--
-- Purpose: Deep-seeds THREE west-metro school-district governments end-to-end:
--   Tigard-Tualatin SD 23J (geo_id='4112240') -- 1 gov + 'School Board' chamber
--     (official_count=5) + 1 shared SCHOOL district + 5 directors (Position 1-5).
--   Forest Grove SD 15 (geo_id='4105160') -- 1 gov + 'School Board' chamber
--     (official_count=5) + 1 shared SCHOOL district + 5 directors (Position 1-5).
--   Sherwood SD 88J (geo_id='4111290') -- 1 gov + 'Board of Directors' chamber
--     (official_count=5) + 1 shared SCHOOL district + 5 directors (Position 1-5).
--   All three boards are WHOLE-DISTRICT AT-LARGE (Wave-0 confirmed) -- one shared SCHOOL
--   district per government carries all 5 seats; NO sub-zone/per-seat districts or geofences.
--
-- NUMBERING: planned as 1206 in the phase docs, but a concurrent Missouri 2026-House workstream
--   claimed 1206 and 1207 (1206_seed_mo_2026_house_elections_races.sql /
--   1207_seed_mo_2026_house_candidates.sql). On-disk MAX at authoring = 1207 -> this structural
--   migration is 1208, the headshot (audit-only) migration is 1209.
--
-- Verbatim per-district chamber naming (D-R1/D-R2): TTSD = 'School Board'; FGSD = 'School Board';
-- SSD = 'Board of Directors' (all live-verified). Office titles all 'Director, Position N';
-- Sherwood's Chair/Vice-Chair use the district's HIGH-confidence LITERAL strings
-- ('Board Chair/Director, Position 1' / 'Board Vice Chair/Director, Position 3'); TTSD/FGSD use a
-- '(Chair)'/'(Vice Chair)' title-on-seat suffix. Chair/Vice-Chair are titles on an existing
-- director row, NOT separate offices -- 15 offices total (5+5+5), never 6 per district.
--
-- CRITICAL: all three boards are 5-SEAT (NOT 7 like Wave 1) -- official_count, the office-CTE
--           count (15 total, not 21), the ext_id block width, and the post-verify gate literals
--           all read 5. (Live-verified Wave-0.)
-- CRITICAL: the auto-generated column on essentials.chambers is GENERATED ALWAYS -- never in the
--           INSERT list.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id/name -- every government
--           INSERT uses a WHERE NOT EXISTS name guard.
-- CRITICAL: districts.state must be 'or' (LOWERCASE) to match routing queries -- uppercase = 0
--           rows and a silently-empty office JOIN (the #1 pitfall this milestone).
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='SCHOOL' (NOT 'SCHOOL_DISTRICT').
-- CRITICAL: all three G5420 geofence rows (4112240 / 4105160 / 4111290) ALREADY EXIST -- loaded
--           by Phase 174. This migration does NOT run any geofence loader.
-- CRITICAL: party=NULL on all 15 directors (antipartisan mission).
-- CRITICAL: all 15 seats are ELECTED -- is_appointed=false on every politician,
--           is_appointed_position=false on every office. Linda Harrington (FGSD Position 4) is a
--           June 23, 2026 mid-term appointee but sits as a seated elected-seat director (D-R4).
-- CRITICAL (183-REVIEW WR-01/WR-02 baked in from authoring, not patched after): every
--           politician+office block resolves the politician id via a `pol` union CTE
--           (SELECT id FROM ins_p UNION SELECT id FROM politicians WHERE external_id = -N), and
--           the office INSERT CROSS JOINs `pol` -- so the office NOT EXISTS guard is genuinely
--           live/self-healing on a re-run (a raw CROSS JOIN on ins_p yields 0 rows when the
--           politician already exists). The post-verify DO block additionally asserts
--           chamber_id IS NOT NULL for all 15 offices.
--
-- Applied to production Supabase via psql -f (DATABASE_URL from C:/EV-Accounts/backend/.env).
-- Ledger convention: version-only INSERT placed BEFORE COMMIT (freshest west-metro convention,
-- matching 1159/1178/1196/1203).

BEGIN;

-- =============================================================================
-- Pre-flight: idempotent NOTICE if any government already exists
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US') > 0 THEN
    RAISE NOTICE 'Tigard-Tualatin School District 23J government row already exists — skipping (idempotent re-run)';
  END IF;
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Forest Grove School District 15, Oregon, US') > 0 THEN
    RAISE NOTICE 'Forest Grove School District 15 government row already exists — skipping (idempotent re-run)';
  END IF;
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Sherwood School District 88J, Oregon, US') > 0 THEN
    RAISE NOTICE 'Sherwood School District 88J government row already exists — skipping (idempotent re-run)';
  END IF;
END $$;

-- =============================================================================
-- Step 1: Government rows. type='LOCAL'. state='OR' uppercase. Standalone rows.
-- WHERE NOT EXISTS guard -- governments has no unique constraint on geo_id or name.
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Tigard-Tualatin School District 23J, Oregon, US',
       'LOCAL', 'OR', NULL, '4112240'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Forest Grove School District 15, Oregon, US',
       'LOCAL', 'OR', NULL, '4105160'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Forest Grove School District 15, Oregon, US'
);

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Sherwood School District 88J, Oregon, US',
       'LOCAL', 'OR', NULL, '4111290'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Sherwood School District 88J, Oregon, US'
);

-- =============================================================================
-- Step 2: Chambers. Verbatim per-district naming (D-R1/D-R2). The auto-generated column is
-- GENERATED ALWAYS -- never in the INSERT list. official_count=5 each (NOT 7).
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'School Board',
       'Tigard-Tualatin School District 23J School Board',
       (SELECT id FROM essentials.governments WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'School Board',
       'Forest Grove School District 15 School Board',
       (SELECT id FROM essentials.governments WHERE name = 'Forest Grove School District 15, Oregon, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Board of Directors',
       'Sherwood School District 88J Board of Directors',
       (SELECT id FROM essentials.governments WHERE name = 'Sherwood School District 88J, Oregon, US'),
       5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
);

-- =============================================================================
-- Step 3: ONE shared SCHOOL district per government (single-shared-district pattern).
-- district_type='SCHOOL'; state='or' LOWERCASE; mtfcc='G5420'. All three geo_ids' G5420
-- geofence rows ALREADY EXIST (Phase 174) -- no loader run here. All 5 director offices per
-- district attach to this ONE row -- NOT one district per seat.
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4112240', 'Tigard-Tualatin School District 23J', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4112240' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4105160', 'Forest Grove School District 15', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4105160' AND district_type = 'SCHOOL' AND state = 'or'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'SCHOOL', 'or', '4111290', 'Sherwood School District 88J', 'G5420'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4111290' AND district_type = 'SCHOOL' AND state = 'or'
);

-- =============================================================================
-- Step 4: Politicians + offices -- 15 blocks (5 TTSD + 5 FGSD + 5 SSD).
-- WR-01 FIX: politician id resolved via `pol` union CTE; office INSERT CROSS JOINs `pol`.
-- All seats ELECTED: is_appointed=false, is_appointed_position=false. party=NULL (antipartisan).
-- is_active=true, is_incumbent=true, is_vacant=false. representing_state='OR' uppercase.
-- ON CONFLICT (external_id) DO NOTHING; office guard NOT EXISTS (district_id, politician_id).
-- =============================================================================

-- TIGARD-TUALATIN SCHOOL DISTRICT 23J -- School Board (Positions 1-5)

-- Position 1: David Jaimes — -4112241
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Jaimes', 'David', 'Jaimes', NULL,
          true, false, false, true, -4112241)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4112241
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
CROSS JOIN pol p
WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 2: Kristen Miles — -4112242
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kristen Miles', 'Kristen', 'Miles', NULL,
          true, false, false, true, -4112242)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4112242
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
CROSS JOIN pol p
WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 3: Tristan Irvin (Vice Chair — title on seat, not a separate row) — -4112243
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tristan Irvin', 'Tristan', 'Irvin', NULL,
          true, false, false, true, -4112243)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4112243
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 3 (Vice Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 4: Jill Zurschmeide (Chair — title on seat, not a separate row) — -4112244
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jill Zurschmeide', 'Jill', 'Zurschmeide', NULL,
          true, false, false, true, -4112244)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4112244
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 4 (Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 5: Crystal Weston — -4112245
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Crystal Weston', 'Crystal', 'Weston', NULL,
          true, false, false, true, -4112245)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4112245
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 5', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- FOREST GROVE SCHOOL DISTRICT 15 -- School Board (Positions 1-5)

-- Position 1: Brisa Franco — -4105161
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brisa Franco', 'Brisa', 'Franco', NULL,
          true, false, false, true, -4105161)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4105161
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
CROSS JOIN pol p
WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 2: Pete Truax — -4105162
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pete Truax', 'Pete', 'Truax', NULL,
          true, false, false, true, -4105162)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4105162
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
CROSS JOIN pol p
WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 3: Alma Lozano (Vice Chair — title on seat, not a separate row) — -4105163
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alma Lozano', 'Alma', 'Lozano', NULL,
          true, false, false, true, -4105163)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4105163
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 3 (Vice Chair)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 4: Linda Harrington (June 23, 2026 mid-term appointee, seated elected seat) — -4105164
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Linda Harrington', 'Linda', 'Harrington', NULL,
          true, false, false, true, -4105164)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4105164
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 4', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 5: Kristy Kottkey (Chair — title on seat, not a separate row) — -4105165
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'School Board'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Forest Grove School District 15, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kristy Kottkey', 'Kristy', 'Kottkey', NULL,
          true, false, false, true, -4105165)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4105165
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
CROSS JOIN pol p
WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- SHERWOOD SCHOOL DISTRICT 88J -- Board of Directors (Positions 1-5).
-- Sherwood's Chair/Vice-Chair use the district's HIGH-confidence LITERAL title strings.

-- Position 1: Harmony Carson (Board Chair) — -4111291
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Harmony Carson', 'Harmony', 'Carson', NULL,
          true, false, false, true, -4111291)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4111291
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Board Chair/Director, Position 1', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 2: Matt Kaufman — -4111292
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Kaufman', 'Matt', 'Kaufman', NULL,
          true, false, false, true, -4111292)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4111292
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
CROSS JOIN pol p
WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 3: Abby Hawkins (Board Vice Chair) — -4111293
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abby Hawkins', 'Abby', 'Hawkins', NULL,
          true, false, false, true, -4111293)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4111293
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Board Vice Chair/Director, Position 3', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 4: Hans Moller — -4111294
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Hans Moller', 'Hans', 'Moller', NULL,
          true, false, false, true, -4111294)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4111294
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 4', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Position 5: Matt Thornton — -4111295
WITH chamber AS (
  SELECT id FROM essentials.chambers
  WHERE name = 'Board of Directors'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Sherwood School District 88J, Oregon, US')
),
ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Matt Thornton', 'Matt', 'Thornton', NULL,
          true, false, false, true, -4111295)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
),
pol AS (
  SELECT id FROM ins_p
  UNION
  SELECT id FROM essentials.politicians WHERE external_id = -4111295
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM chamber),
       p.id,
       'Director, Position 5', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN pol p
WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- Step 5: office_id back-fill (all 15 directors), idempotent.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (-4112241,-4112242,-4112243,-4112244,-4112245,
                         -4105161,-4105162,-4105163,-4105164,-4105165,
                         -4111291,-4111292,-4111293,-4111294,-4111295)
  AND p.office_id IS NULL;

-- =============================================================================
-- Step 6: Post-verification DO block (RAISE EXCEPTION on any mismatch — rolls back the
-- whole migration). Gates: (a) exactly 1 government row per district; (b) exactly 5 offices
-- on each SCHOOL district (NOT 7 like Wave 1); (c) WR-02: 0 offices with a NULL chamber_id;
-- (d) 0 section-split orphan rows for all three G5420 geo_ids; (e) office_id back-fill
-- completeness for all 15 directors.
-- =============================================================================
DO $$
DECLARE
  v_ttsd_gov     INTEGER;
  v_fgsd_gov     INTEGER;
  v_ssd_gov      INTEGER;
  v_ttsd_off     INTEGER;
  v_fgsd_off     INTEGER;
  v_ssd_off      INTEGER;
  v_null_chamber INTEGER;
  v_split        INTEGER;
  v_null_oid     INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_ttsd_gov FROM essentials.governments
  WHERE name = 'Tigard-Tualatin School District 23J, Oregon, US';
  SELECT COUNT(*) INTO v_fgsd_gov FROM essentials.governments
  WHERE name = 'Forest Grove School District 15, Oregon, US';
  SELECT COUNT(*) INTO v_ssd_gov FROM essentials.governments
  WHERE name = 'Sherwood School District 88J, Oregon, US';
  IF v_ttsd_gov <> 1 OR v_fgsd_gov <> 1 OR v_ssd_gov <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 1 gov each, found TTSD=%, FGSD=%, SSD=%', v_ttsd_gov, v_fgsd_gov, v_ssd_gov;
  END IF;

  SELECT COUNT(*) INTO v_ttsd_off
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4112240' AND d.district_type = 'SCHOOL' AND d.state = 'or';
  SELECT COUNT(*) INTO v_fgsd_off
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4105160' AND d.district_type = 'SCHOOL' AND d.state = 'or';
  SELECT COUNT(*) INTO v_ssd_off
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4111290' AND d.district_type = 'SCHOOL' AND d.state = 'or';
  -- NOTE: expected count is 5 per district (Key Finding 1) -- NOT 7 like Wave 1.
  IF v_ttsd_off <> 5 OR v_fgsd_off <> 5 OR v_ssd_off <> 5 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 5 offices each, found TTSD=%, FGSD=%, SSD=%', v_ttsd_off, v_fgsd_off, v_ssd_off;
  END IF;

  -- WR-02 FIX: assert no office landed with a NULL chamber_id (chamber-name string drift guard)
  SELECT COUNT(*) INTO v_null_chamber
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id IN ('4112240','4105160','4111290') AND d.district_type = 'SCHOOL' AND d.state = 'or'
    AND o.chamber_id IS NULL;
  IF v_null_chamber <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % offices have NULL chamber_id', v_null_chamber;
  END IF;

  SELECT COUNT(*) INTO v_split
  FROM essentials.geofence_boundaries gb
  WHERE gb.geo_id IN ('4112240','4105160','4111290') AND gb.mtfcc = 'G5420'
    AND NOT EXISTS (
      SELECT 1 FROM essentials.districts d
      WHERE d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL' AND d.state = 'or'
    );
  IF v_split <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % orphan rows', v_split;
  END IF;

  SELECT COUNT(*) INTO v_null_oid
  FROM essentials.politicians
  WHERE external_id IN (-4112241,-4112242,-4112243,-4112244,-4112245,
                         -4105161,-4105162,-4105163,-4105164,-4105165,
                         -4111291,-4111292,-4111293,-4111294,-4111295)
    AND office_id IS NULL;
  IF v_null_oid <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % directors still have NULL office_id after back-fill', v_null_oid;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: TTSD gov=%/off=%, FGSD gov=%/off=%, SSD gov=%/off=%, null_chamber=%, split_orphans=%, office_id_nulls=%',
    v_ttsd_gov, v_ttsd_off, v_fgsd_gov, v_fgsd_off, v_ssd_gov, v_ssd_off, v_null_chamber, v_split, v_null_oid;
END $$;

-- =============================================================================
-- Step 7: Migration ledger registration -- structural migration registers (version-only form,
-- matching the freshest west-metro convention 1159/1178/1196/1203), placed BEFORE COMMIT.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1208')
ON CONFLICT (version) DO NOTHING;

COMMIT;

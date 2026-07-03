-- Migration 1187: City of Sherwood government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Sherwood, Oregon (Washington County, west-metro):
--   Sherwood (geo_id='4167100' -- CORRECTED against essentials.geofence_boundaries at Wave-0;
--   the ROADMAP/CONTEXT-stated '4167450' returns 0 rows and does not exist at all) -- 1 gov +
--   1 chamber + 2 districts + 7 officials + 7 offices.
--
-- Form of government (RESEARCH-confirmed, re-verified fresh at Wave-0 2026-07-03 via
-- sherwoodoregon.gov/government/city-council/, Washington County SEL101 candidate-filing PDFs,
-- and the city's own Dec-2024 organizational chart, no WAF): Sherwood is council-manager, PURE
-- AT-LARGE, PLAIN titles ('Mayor' / 'Councilor', NO numbered positions, NO wards) -- the exact
-- Tigard (1159) / Forest Grove (1178) shape class. Mayor is directly elected citywide on a
-- 2-YEAR term (a new wrinkle this milestone -- every other WashCo Mayor so far, incl. Forest
-- Grove, is 4-year); this does NOT change the structural shape -- same LOCAL_EXEC + shared LOCAL
-- split as Beaverton/Tualatin/Forest Grove, just a different term-length note in the district
-- label/comment. All 6 Councilors are elected at-large citywide on 4-year staggered terms,
-- sharing ONE LOCAL district.
--
-- Appointed seats: NONE. All 7 seats are presently held by ELECTION -- uniform Forest
-- Grove/Tualatin shape (false/false for is_appointed / is_appointed_position on every seat) --
-- do NOT import Tigard's appointed-seat block for any Sherwood seat.
--
-- PITFALL GUARD: Keith Mays is a FORMER Mayor (2018-2022, 2005-2012) and FORMER Council
-- President (2001-2004) -- he is now seated as a PLAIN Councilor. Do NOT title him 'Mayor' or
-- give him the Council President designation; that belongs to the currently-seated
-- Rosener/Young.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id -- use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: titles are PLAIN 'Mayor' / 'Councilor' only -- NO position numbers, NO ward suffixes.
--           All 6 councilors share the ONE LOCAL district; create NO per-seat/per-position
--           districts and NO ward/X00xx geofences of any kind (pure at-large model).
-- CRITICAL: representing_city='Sherwood' is set INLINE on every office INSERT (D-11 convention)
--           so the community banner derives correctly at first browse -- no backfill migration
--           needed.
-- CRITICAL: politicians.party is ALWAYS NULL (antipartisan mission).
-- CRITICAL: this migration upgrades the post-verification identity gate to the D-15 WR-B
--           PAIRWISE (external_id, full_name) form -- stronger than Forest Grove/Tigard's
--           set-membership two-independent-IN-lists gate, which would pass a name/id
--           transposition. This catches an ON CONFLICT (external_id) DO UPDATE path that could
--           silently re-attach a stale/wrong name to a colliding external_id on re-run.

BEGIN;

-- Pre-flight hard-abort guard.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Sherwood, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1187 already applied — aborting re-run';
  END IF;
END $$;

-- Government row.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Sherwood, Oregon, US',
       'LOCAL', 'OR', 'Sherwood', '4167100'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Sherwood, Oregon, US'
);

-- Chamber row. NOTE: chambers has a GENERATED ALWAYS column — never insert it.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Sherwood City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Sherwood, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Sherwood, Oregon, US')
);

-- LOCAL_EXEC district — Mayor is directly elected citywide on a 2-YEAR term (new pattern this
-- milestone — every other WashCo Mayor so far, incl. Forest Grove, is 4-year). Structural shape
-- is unchanged: same LOCAL_EXEC + shared LOCAL split as Beaverton/Tualatin/Forest Grove.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4167100', 'Sherwood (Mayor, Citywide, 2-Year Term)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4167100' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- LOCAL at-large district — all 6 councilors share ONE row. Do NOT create per-seat/per-position
-- districts; RESEARCH confirms zero position-number or ward differentiation for Sherwood
-- (verified via three independent primary sources incl. SEL101 candidate filings).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4167100', 'Sherwood (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4167100' AND district_type = 'LOCAL' AND state = 'or'
);

-- Mayor Tim Rosener (-4167101) — directly elected citywide, 2-year term, current term expires
-- January 2027 (began January 2025 following the Nov 2024 election). Not appointed: false/false
-- (Sherwood has zero appointed seats — use this Forest Grove/Tualatin shape, NOT Tigard's
-- appointed-Mayor Hu block).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tim Rosener', 'Tim', 'Rosener', NULL,
          true, false, false, true, -4167101)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Mayor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Kim Young holds the annually-designated Council President title (confirmed via both
-- the live city council page and the city's Dec-2024 org chart). This is a title on her seat,
-- NOT a separate office row. ONE office row only, title stays plain 'Councilor' — same
-- treatment class as Tigard's Wolf, Tualatin's Pratt, Forest Grove's Valenzuela. Elected Nov
-- 2024, term through January 2029. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kim Young', 'Kim', 'Young', NULL,
          true, false, false, true, -4167102)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Renee Brouse (-4167103) — CEO, Sherwood Chamber of Commerce. Elected Nov 2024, term
-- through January 2029. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Renee Brouse', 'Renee', 'Brouse', NULL,
          true, false, false, true, -4167103)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Taylor Giles (-4167104) — product-management executive; co-founded Voices for the
-- Performing Arts. Term through January 2027. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Taylor Giles', 'Taylor', 'Giles', NULL,
          true, false, false, true, -4167104)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Keith Mays (-4167105) — term through January 2027. Not appointed: false/false.
-- PITFALL GUARD: Keith Mays is a FORMER Mayor of Sherwood (2018-2022 AND 2005-2012) and FORMER
-- Council President (2001-2004) — he is now seated as a PLAIN Councilor. Do NOT title him
-- 'Mayor' or give him the Council President designation; those belong to the currently-seated
-- Rosener/Young.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Mays', 'Keith', 'Mays', NULL,
          true, false, false, true, -4167105)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Doug Scott (-4167106) — Software Product Director. Term through January 2027.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Doug Scott', 'Doug', 'Scott', NULL,
          true, false, false, true, -4167106)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Dan Standke (-4167107) — US Navy veteran; cabinet maker/small-business owner.
-- Elected/re-elected Nov 2024, term through January 2029. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Standke', 'Dan', 'Standke', NULL,
          true, false, false, true, -4167107)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of Sherwood, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Sherwood', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4167100'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- office_id back-fill — explicit IN list, idempotent.
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4167101,-4167102,-4167103,-4167104,-4167105,-4167106,-4167107
  )
  AND p.office_id IS NULL;

-- Post-verification DO block: independent geofence-presence assertion + canonical section-split
-- query, PLUS the D-15 WR-B PAIRWISE (external_id, full_name) identity gate — an upgrade from
-- Forest Grove/Tigard's set-membership two-independent-IN-lists gate (which would pass a
-- name/id transposition). This catches an ON CONFLICT DO UPDATE that silently re-attached a
-- stale/wrong full_name to a colliding external_id on re-run.
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
  v_repcity_count  INTEGER;
  v_geofence_count INTEGER;
  v_pair_count     INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Sherwood, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Sherwood gov_count=%, expected 1', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4167100' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Sherwood office_count=%, expected 7', v_office_count;
  END IF;

  -- Independent geofence-presence assertion (not the dead same-transaction gate).
  SELECT COUNT(*) INTO v_geofence_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '4167100' AND mtfcc = 'G4110';
  IF v_geofence_count < 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: no G4110 geofence row found for geo_id 4167100';
  END IF;

  -- Canonical section-split query (GROUP BY / HAVING), independent of the INSERTs above.
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '4167100'
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows', v_split_count;
  END IF;

  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (-4167101,-4167102,-4167103,-4167104,-4167105,-4167106,-4167107)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4167107 AND -4167101
    AND o.representing_city = 'Sherwood';
  IF v_repcity_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Sherwood offices have representing_city=Sherwood', v_repcity_count;
  END IF;

  -- D-15 WR-B FIX: upgrade the Forest Grove/Tigard set-membership identity gate (two
  -- independent IN lists) to a PAIRWISE (external_id, full_name) assertion, so a name/id
  -- transposition on re-run cannot silently pass just because both sets independently match.
  SELECT COUNT(*) INTO v_pair_count
  FROM essentials.politicians
  WHERE (external_id, full_name) IN (
    (-4167101, 'Tim Rosener'), (-4167102, 'Kim Young'), (-4167103, 'Renee Brouse'),
    (-4167104, 'Taylor Giles'), (-4167105, 'Keith Mays'), (-4167106, 'Doug Scott'),
    (-4167107, 'Dan Standke')
  );
  IF v_pair_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: pairwise identity gate — expected 7 exact (external_id, full_name) matches, found %', v_pair_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Sherwood gov=1, offices=7, geofence>=1, section-split=0, office_id nulls=0, representing_city=7, pairwise_identity=7';
END $$;

-- Ledger entry — structural migrations register.
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1187')
ON CONFLICT (version) DO NOTHING;

COMMIT;

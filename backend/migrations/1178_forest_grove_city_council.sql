-- Migration 1178: City of Forest Grove government + chamber + districts + officials + offices
--
-- Purpose: Seeds the City of Forest Grove, Oregon (Washington County, west-metro):
--   Forest Grove (geo_id='4126200' -- CONFIRMED CORRECT against essentials.geofence_boundaries at
--   Wave-0, the first WashCo city this milestone to match the ROADMAP-stated value on the first
--   check; no correction needed) -- 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices.
--
-- Form of government (RESEARCH-confirmed, re-verified fresh at Wave-0 2026-07-03 via
-- forestgrove-or.gov/611/Meet-the-Council and the city's own Elections page, no WAF): Forest
-- Grove is a genuine HYBRID of its two immediately-preceding sister cities. It uses Tualatin
-- migration 1169's district/politician shape (directly-elected Mayor, LOCAL_EXEC citywide, plus
-- 6 Council Members elected at-large citywide sharing ONE LOCAL district) but Tigard migration
-- 1159's PLAIN title convention ('Mayor' / 'Councilor', NO numbered positions, NO wards). The
-- city's own Elections page states verbatim: "The Council consists of a Mayor and six Councilors
-- each elected at large" -- no Position numbers, no ward suffixes anywhere in primary-source text.
--
-- Appointed seats: NONE. All 7 seats are presently held by ELECTION. Mariana Valenzuela was
-- originally APPOINTED in 2020 to fill a vacancy, but her CURRENT term (elected Nov 2022, through
-- Dec 31, 2026) is by election -- is_appointed=false is correct for her present seating. She holds
-- the annually-designated Council President title -- a title on her seat, NOT a separate office
-- row. ONE office row only, title stays plain 'Councilor'. This is the uniform Tualatin shape
-- (0 of 7 appointed) -- do NOT import Tigard's appointed-seat block (2 of 7 appointed) for any
-- Forest Grove seat.
--
-- PITFALL GUARD 1: Do NOT attribute Angel Falconer's pre-2022 "council president"/2016/2020
-- history to Forest Grove -- that record belongs to Milwaukie, OR, a DIFFERENT city. Her Forest
-- Grove seat begins Nov 2024.
-- PITFALL GUARD 2: Do NOT seed Peter Truax -- he lost the close 2024 race to Brian Schimmel, who
-- is the current seated official per the primary-source roster page. Schimmel, not Truax, below.
--
-- CRITICAL: the generated identifier column on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id -- use WHERE NOT EXISTS guard.
-- CRITICAL: districts.state must be 'or' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'OR' (uppercase). offices.representing_state = 'OR' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: titles are PLAIN 'Mayor' / 'Councilor' only -- NO position numbers, NO ward suffixes.
--           All 6 councilors share the ONE LOCAL district; create NO per-seat/per-position
--           districts and NO ward/X00xx geofences of any kind (pure at-large model).
-- CRITICAL: representing_city='Forest Grove' is set INLINE on every office INSERT (D-11
--           convention) so the community banner derives correctly at first browse -- no backfill
--           migration needed.
-- CRITICAL: politicians.party is ALWAYS NULL (antipartisan mission).
-- CRITICAL: this migration includes a NEW template-hardening block not present in any prior
--           structural migration (D-14 WR-02) -- the post-verification DO block asserts that the
--           7 politicians seated on the ext_id block carry the exact researched full_names, RAISing
--           EXCEPTION on any mismatch. This catches an ON CONFLICT (external_id) DO UPDATE path
--           that could silently re-attach a stale/wrong name to a colliding external_id on re-run.

BEGIN;

-- Pre-flight hard-abort guard.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of Forest Grove, Oregon, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1178 already applied — aborting re-run';
  END IF;
END $$;

-- Government row.
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Forest Grove, Oregon, US',
       'LOCAL', 'OR', 'Forest Grove', '4126200'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Forest Grove, Oregon, US'
);

-- Chamber row. NOTE: chambers has a GENERATED ALWAYS column — never insert it.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'Forest Grove City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Forest Grove, Oregon, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Forest Grove, Oregon, US')
);

-- LOCAL_EXEC district — Mayor, citywide.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', '4126200', 'Forest Grove (Mayor, Citywide)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4126200' AND district_type = 'LOCAL_EXEC' AND state = 'or'
);

-- LOCAL at-large district — all 6 councilors share ONE row. Do NOT create per-seat/per-position
-- districts; RESEARCH confirms zero position-number or ward differentiation for Forest Grove.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'or', '4126200', 'Forest Grove (At-Large)', NULL
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4126200' AND district_type = 'LOCAL' AND state = 'or'
);

-- Mayor Malynda Wenzl (-4126201) — elected to Council 2014, elected Mayor Nov 2022, term through
-- Dec 31, 2026. Not appointed: false/false (Forest Grove has zero appointed seats — contrast with
-- Tigard's appointed-Mayor Hu block; use Tualatin's elected-Mayor shape instead).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Malynda Wenzl', 'Malynda', 'Wenzl', NULL,
          true, false, false, true, -4126201)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Mayor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Michael Marshall (-4126202) — elected Nov 2022, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael Marshall', 'Michael', 'Marshall', NULL,
          true, false, false, true, -4126202)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Karen Martinez (-4126203) — elected Nov 2022, term through Dec 31, 2026.
-- Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Karen Martinez', 'Karen', 'Martinez', NULL,
          true, false, false, true, -4126203)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Mariana Valenzuela (-4126204) — holds the annually-designated Council President
-- title (confirmed via the city's own stipend table: distinct $792/mo line for "Council
-- President" vs $667 for "Councilors"). Originally APPOINTED 2020 to fill a vacancy, but her
-- CURRENT term (elected Nov 2022, through Dec 31, 2026) is by ELECTION — is_appointed=false is
-- correct for her present seating (same treatment class as Tualatin's Pratt). Council President
-- is a title on her seat, NOT a separate office row. ONE office row only, title stays plain
-- 'Councilor'.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mariana Valenzuela', 'Mariana', 'Valenzuela', NULL,
          true, false, false, true, -4126204)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Donna Gustafson (-4126205) — elected Nov 2020, reelected Nov 2024, term through
-- Dec 31, 2028. Not appointed: false/false.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Donna Gustafson', 'Donna', 'Gustafson', NULL,
          true, false, false, true, -4126205)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Angel Falconer (-4126206) — elected Nov 2024, FIRST Forest Grove term, term through
-- Dec 31, 2028. Not appointed: false/false.
-- PITFALL GUARD: her pre-2022 "council president"/2016/2020 election history belongs to
-- Milwaukie, OR — a DIFFERENT city. That record must NOT be recorded as Forest Grove tenure.
-- Her Forest Grove seat begins Nov 2024 only.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angel Falconer', 'Angel', 'Falconer', NULL,
          true, false, false, true, -4126206)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Councilor Brian Schimmel (-4126207) — elected Nov 2024, narrow win over Peter Truax, term
-- through Dec 31, 2028. Not appointed: false/false.
-- PITFALL GUARD: Peter Truax lost this race and is NOT seated — do NOT create a Truax block.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Schimmel', 'Brian', 'Schimmel', NULL,
          true, false, false, true, -4126207)
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
                               WHERE name = 'City of Forest Grove, Oregon, US')),
       p.id,
       'Councilor', 'OR', 'Forest Grove', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4126200'
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
    -4126201,-4126202,-4126203,-4126204,-4126205,-4126206,-4126207
  )
  AND p.office_id IS NULL;

-- Post-verification DO block: independent geofence-presence assertion + canonical section-split
-- query (WR-01-style inherited pattern) PLUS the D-14 WR-02 in-file identity gate — NEW for this
-- phase, no prior structural migration (1150 Hillsboro, 1159 Tigard, 1169 Tualatin) includes a
-- name-match assertion. This catches an ON CONFLICT DO UPDATE that silently re-attached a
-- stale/wrong full_name to a colliding external_id on re-run.
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
  v_repcity_count  INTEGER;
  v_geofence_count INTEGER;
  v_name_count     INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of Forest Grove, Oregon, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Forest Grove gov_count=%, expected 1', v_gov_count;
  END IF;

  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '4126200' AND d.district_type IN ('LOCAL','LOCAL_EXEC') AND d.state = 'or';
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Forest Grove office_count=%, expected 7', v_office_count;
  END IF;

  -- Independent geofence-presence assertion (WR-01-style, inherited pattern — not the dead
  -- same-transaction gate).
  SELECT COUNT(*) INTO v_geofence_count
  FROM essentials.geofence_boundaries
  WHERE geo_id = '4126200' AND mtfcc = 'G4110';
  IF v_geofence_count < 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: no G4110 geofence row found for geo_id 4126200';
  END IF;

  -- Canonical section-split query (GROUP BY / HAVING), independent of the INSERTs above.
  SELECT COUNT(*) INTO v_split_count
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = '4126200'
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split detector returned % rows', v_split_count;
  END IF;

  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (-4126201,-4126202,-4126203,-4126204,-4126205,-4126206,-4126207)
    AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  SELECT COUNT(*) INTO v_repcity_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4126207 AND -4126201
    AND o.representing_city = 'Forest Grove';
  IF v_repcity_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Forest Grove offices have representing_city=Forest Grove', v_repcity_count;
  END IF;

  -- WR-02 FIX (NEW for this phase, D-14): in-file identity gate — assert the seated
  -- names on the ext_id block match the researched roster, catching an ON CONFLICT
  -- DO UPDATE that silently re-attached a stale/wrong full_name to a colliding
  -- external_id on re-run, not just relying on the out-of-band Wave-0 Probe D.
  SELECT COUNT(*) INTO v_name_count
  FROM essentials.politicians
  WHERE external_id IN (-4126201,-4126202,-4126203,-4126204,-4126205,-4126206,-4126207)
    AND full_name IN ('Malynda Wenzl','Michael Marshall','Karen Martinez','Mariana Valenzuela',
                       'Donna Gustafson','Angel Falconer','Brian Schimmel');
  IF v_name_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: identity gate — expected 7 matching names, found %', v_name_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Forest Grove gov=1, offices=7, geofence>=1, section-split=0, office_id nulls=0, representing_city=7, identity_gate=7';
END $$;

-- Ledger entry — structural migrations register.
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1178')
ON CONFLICT (version) DO NOTHING;

COMMIT;

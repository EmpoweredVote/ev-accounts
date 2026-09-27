-- CC_0159 — KS-3 structure: the City of Wichita government, its seven districts and seven offices.
--
-- THE OFFICE INVENTORY IS THE CHARTER'S, AND THE CODE STATES IT TWICE IN TWO UNRELATED PLACES.
--   Sec. 2.04.005(a): the governing body consists of "six council members and the mayor".
--   The licence-appeal panel section, which is not about defining the council at all and is
--   therefore a real check rather than a restatement: "The panel of three City Council members
--   shall be chosen on a rotating basis by District Numbers 1—6 with the Mayor being number 7."
--   Sec. 2.04.005(c) corroborates arithmetically — a majority "shall mean four members", which is
--   a majority of seven.
-- ▶ SEVEN OFFICES: Mayor (at large) + Council Member, Districts 1-6.
--
-- 🔴🔴 THERE IS A VICE MAYOR AND IT IS NOT AN OFFICE. Sec. 2.04.010 has the council choose it "from
-- among its membership" for "a term of one year", and Mayor Wu says so in the minutes of 2026-01-13:
-- "By ordinance, this position is for a term of one year, and it's rotated among the six council
-- members." Dalton Glasscock holds it for 2026 AND holds District 4; J.V. Johnston held it for 2025
-- AND holds District 5. Writing it as an office would seat one person twice.
-- ⚠ The city's own District 4 page says Glasscock "was selected by the City Council to serve as Vice
-- Mayor in 2026" — that is the sentence shape that made KY-3 invent a Vice Mayor office for
-- Lexington, where the role did not even exist. Here it exists, which makes the trap sharper, not
-- weaker. The ordinance was read; the bio was not trusted.
--
-- THE MAYOR NEEDS NO NEW POLYGON. He is elected at large, so the LOCAL_EXEC district hangs on TIGER
-- place 2079000 / G4110, already in production — the pattern every other mayor in this database
-- uses. Only the six council districts need custom geometry, and that is mtfcc X0070, loaded by
-- scripts/load-wichita-council-boundaries.mjs.
--
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THOSE SIX BOUNDARIES ARE ABSENT. An office on a district with
-- no polygon is invisible to every address search and NOTHING ERRORS — the one failure mode CI
-- cannot catch. The guard is first, before any write.
--
-- STATE CASE: 'ks' lowercase, matching CC_0156's 125 House and 40 Senate districts and the 105
-- counties. ⚠ Kansas rows are MIXED in production — the older federal and state-exec rows are 'KS'.
-- Reads must keep using lower(d.state); this migration does not touch the existing rows.
--
-- Idempotent: every insert is guarded by NOT EXISTS, so a second run reports INSERT 0.

BEGIN;

-- ── Guard: the geometry must exist before any office hangs off it ──────────────────────────────
DO $$
DECLARE
  v_council int;
  v_place   int;
BEGIN
  SELECT count(*) INTO v_council
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0070' AND geo_id LIKE 'wichita-ks-council-district-%';
  IF v_council <> 6 THEN
    RAISE EXCEPTION 'CC_0159: expected 6 X0070 council boundaries, found %. Run '
                    'scripts/load-wichita-council-boundaries.mjs first — an office on a district '
                    'with no polygon is unreachable by any address and nothing errors.', v_council;
  END IF;

  SELECT count(*) INTO v_place
    FROM essentials.geofence_boundaries WHERE mtfcc = 'G4110' AND geo_id = '2079000';
  IF v_place <> 1 THEN
    RAISE EXCEPTION 'CC_0159: TIGER place 2079000 (Wichita city, G4110) is absent — the at-large '
                    'mayor has nothing to hang on';
  END IF;
END $$;

-- ── The government ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name)
SELECT gen_random_uuid(), 'City of Wichita, Kansas, US'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'City of Wichita, Kansas, US');

-- ── The six council districts ──────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts
  (id, label, district_type, state, city, mtfcc, geo_id, num_officials, government_id)
SELECT gen_random_uuid(),
       'Wichita City Council District ' || n,
       'LOCAL', 'ks', 'Wichita', 'X0070',
       'wichita-ks-council-district-' || n,
       1,
       (SELECT id FROM essentials.governments WHERE name = 'City of Wichita, Kansas, US')
  FROM generate_series(1, 6) AS n
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = 'wichita-ks-council-district-' || n AND d.district_type = 'LOCAL');

-- ── The mayor's at-large district ──────────────────────────────────────────────────────────────
INSERT INTO essentials.districts
  (id, label, district_type, state, city, mtfcc, geo_id, num_officials, government_id)
SELECT gen_random_uuid(),
       'City of Wichita (Mayor)', 'LOCAL_EXEC', 'ks', 'Wichita', 'G4110', '2079000', 1,
       (SELECT id FROM essentials.governments WHERE name = 'City of Wichita, Kansas, US')
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = '2079000' AND d.district_type = 'LOCAL_EXEC' AND lower(d.state) = 'ks');

-- ── The seven offices ──────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices (id, district_id, title, seats, representing_state, representing_city)
SELECT gen_random_uuid(), d.id, 'Council Member, District ' || n, 1, 'KS', 'Wichita'
  FROM generate_series(1, 6) AS n
  JOIN essentials.districts d
    ON d.geo_id = 'wichita-ks-council-district-' || n AND d.district_type = 'LOCAL'
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Council Member, District ' || n);

INSERT INTO essentials.offices (id, district_id, title, seats, representing_state, representing_city)
SELECT gen_random_uuid(), d.id, 'Mayor', 1, 'KS', 'Wichita'
  FROM essentials.districts d
 WHERE d.geo_id = '2079000' AND d.district_type = 'LOCAL_EXEC' AND lower(d.state) = 'ks'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = 'Mayor');

-- ── Post-verify. Asserts the END STATE, so a re-run that inserts nothing still passes. ─────────
DO $$
DECLARE
  v_gov int; v_local int; v_exec int; v_offices int; v_nogeom int; v_dupes int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'City of Wichita, Kansas, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0159: expected 1 Wichita government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_local FROM essentials.districts
   WHERE district_type = 'LOCAL' AND geo_id LIKE 'wichita-ks-council-district-%';
  IF v_local <> 6 THEN RAISE EXCEPTION 'CC_0159: expected 6 council districts, found %', v_local; END IF;

  SELECT count(*) INTO v_exec FROM essentials.districts
   WHERE district_type = 'LOCAL_EXEC' AND geo_id = '2079000' AND lower(state) = 'ks';
  IF v_exec <> 1 THEN RAISE EXCEPTION 'CC_0159: expected 1 mayoral district, found %', v_exec; END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks';
  IF v_offices <> 7 THEN RAISE EXCEPTION 'CC_0159: expected 7 Wichita offices, found %', v_offices; END IF;

  -- 🔴 The failure mode CI cannot catch: an office whose district has no polygon.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.city = 'Wichita' AND lower(d.state) = 'ks'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0159: % Wichita office(s) sit on a district with no matching boundary', v_nogeom;
  END IF;

  -- No two offices on one district, and no duplicate titles.
  SELECT count(*) INTO v_dupes FROM (
    SELECT o.title FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.city = 'Wichita' AND lower(d.state) = 'ks'
     GROUP BY o.title HAVING count(*) > 1) t;
  IF v_dupes <> 0 THEN RAISE EXCEPTION 'CC_0159: % duplicated office title(s)', v_dupes; END IF;

  -- ⚠ And the trap this migration exists to avoid: no office may be called Vice Mayor.
  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
              WHERE d.city = 'Wichita' AND lower(d.state) = 'ks' AND o.title ILIKE '%vice mayor%') THEN
    RAISE EXCEPTION 'CC_0159: a Vice Mayor office was created. It is a one-year rotation among the '
                    'six council members (Sec. 2.04.010), not a seat.';
  END IF;

  RAISE NOTICE 'CC_0159 OK — Wichita: 1 government, 6 council districts + 1 mayoral district, 7 offices, '
               'every one on a district with geometry.';
END $$;

COMMIT;

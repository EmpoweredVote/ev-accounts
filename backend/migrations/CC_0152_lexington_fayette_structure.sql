-- CC_0152_lexington_fayette_structure.sql
-- Knight Foundation program, wave KY-3 (structure half). Slot RESERVED from the allocator.
--
-- Production holds NO Lexington or Fayette government row and NO Kentucky LOCAL districts before
-- this migration; measured 2026-09-26. It:
--
--   1. creates the government and its two chambers;
--   2. creates 13 LOCAL districts -- 12 council districts plus one citywide district on the TIGER
--      place GEOID 2146027, which carries the Mayor and the three at-large seats;
--   3. creates 16 offices -- Mayor (1), Council At-Large (3), Council District 1-12 (12).
--
-- Creates NO people and NO terms -- CC_0153 does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE CITY'S OWN COUNCILMEMBERS PAGE PRODUCES A WRONG INVENTORY IF READ LITERALLY. Its prose says
-- the Council has 15 members: "The vice mayor / Two at-large councilmembers / 12 district
-- councilmembers". Read as written that creates a separately elected VICE MAYOR office. There is
-- none. The Government page states "There are 12 district council members and three at-large
-- council members", and the roster lists Dan Wu as "Council At-Large and Vice Mayor". Voters elect
-- THREE at-large members and the top vote-getter takes the title. By the inclusion ruling -- an
-- office is seated if the VOTERS elect it -- Vice Mayor is a title, not an office.
--
-- REFUSES TO RUN IF THE X0068 BOUNDARIES ARE ABSENT. An office on a district with no polygon is
-- unreachable by any address and NOTHING ERRORS. load-lexington-council-boundaries.mjs writes them.
--
-- Two term lengths inside one body: at-large 4 years, district 2 years.
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 0. Refuse to run without the geometry ────────────────────────────────────

DO $$
DECLARE v_b int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries WHERE mtfcc = 'X0068';
  IF v_b <> 12 THEN
    RAISE EXCEPTION 'CC_0152: X0068 holds % boundaries, expected 12. Run load-lexington-council-boundaries.mjs first - an office on a district with no polygon is unreachable and nothing errors.', v_b;
  END IF;
END $$;

-- ─── 1. Government and chambers ───────────────────────────────────────────────

INSERT INTO essentials.governments (name)
SELECT 'Lexington-Fayette Urban County Government, Kentucky, US'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = 'Lexington-Fayette Urban County Government, Kentucky, US');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.gid, v.nm, v.nm, v.cnt, v.tl, v.stag
FROM (VALUES
  ((SELECT id FROM essentials.governments WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US'), 'Lexington-Fayette Urban County Council', 15, 2, true),
  ((SELECT id FROM essentials.governments WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US'), 'Office of the Mayor of Lexington-Fayette, Kentucky', 1, 4, false)
) AS v(gid, nm, cnt, tl, stag)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.nm);

-- ─── 2. The 13 LOCAL districts ────────────────────────────────────────────────
--
-- 12 council districts on their own polygons, plus ONE citywide district on the TIGER place
-- GEOID. The place polygon was MEASURED exactly coterminous with Fayette County -- both
-- 285.567 sq mi, zero difference in either direction -- so a citywide seat on it reaches every
-- resident of the consolidated government.

CREATE TEMP TABLE lex_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO lex_districts(geo_id, label) VALUES
  ('lexington-fayette-ky-council-district-1', 'Lexington-Fayette Urban County Council District 1'),
  ('lexington-fayette-ky-council-district-2', 'Lexington-Fayette Urban County Council District 2'),
  ('lexington-fayette-ky-council-district-3', 'Lexington-Fayette Urban County Council District 3'),
  ('lexington-fayette-ky-council-district-4', 'Lexington-Fayette Urban County Council District 4'),
  ('lexington-fayette-ky-council-district-5', 'Lexington-Fayette Urban County Council District 5'),
  ('lexington-fayette-ky-council-district-6', 'Lexington-Fayette Urban County Council District 6'),
  ('lexington-fayette-ky-council-district-7', 'Lexington-Fayette Urban County Council District 7'),
  ('lexington-fayette-ky-council-district-8', 'Lexington-Fayette Urban County Council District 8'),
  ('lexington-fayette-ky-council-district-9', 'Lexington-Fayette Urban County Council District 9'),
  ('lexington-fayette-ky-council-district-10', 'Lexington-Fayette Urban County Council District 10'),
  ('lexington-fayette-ky-council-district-11', 'Lexington-Fayette Urban County Council District 11'),
  ('lexington-fayette-ky-council-district-12', 'Lexington-Fayette Urban County Council District 12'),
  ('2146027', 'Lexington-Fayette Urban County Government (citywide)');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT ld.geo_id, ld.label, 'LOCAL', 'ky',
       CASE WHEN ld.geo_id = '2146027' THEN 'G4110' ELSE 'X0068' END
FROM lex_districts ld
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = ld.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'ky'
);

-- ─── 3. The 16 offices ────────────────────────────────────────────────────────

CREATE TEMP TABLE lex_seats(geo_id text, chamber_formal text, title text, n int) ON COMMIT DROP;
INSERT INTO lex_seats(geo_id, chamber_formal, title, n) VALUES
  ('2146027', 'Office of the Mayor of Lexington-Fayette, Kentucky', 'Mayor', 0),
  ('2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 1),
  ('2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 2),
  ('2146027', 'Lexington-Fayette Urban County Council', 'Council Member, At-Large', 3),
  ('lexington-fayette-ky-council-district-1', 'Lexington-Fayette Urban County Council', 'Council Member, District 1', 4),
  ('lexington-fayette-ky-council-district-2', 'Lexington-Fayette Urban County Council', 'Council Member, District 2', 5),
  ('lexington-fayette-ky-council-district-3', 'Lexington-Fayette Urban County Council', 'Council Member, District 3', 6),
  ('lexington-fayette-ky-council-district-4', 'Lexington-Fayette Urban County Council', 'Council Member, District 4', 7),
  ('lexington-fayette-ky-council-district-5', 'Lexington-Fayette Urban County Council', 'Council Member, District 5', 8),
  ('lexington-fayette-ky-council-district-6', 'Lexington-Fayette Urban County Council', 'Council Member, District 6', 9),
  ('lexington-fayette-ky-council-district-7', 'Lexington-Fayette Urban County Council', 'Council Member, District 7', 10),
  ('lexington-fayette-ky-council-district-8', 'Lexington-Fayette Urban County Council', 'Council Member, District 8', 11),
  ('lexington-fayette-ky-council-district-9', 'Lexington-Fayette Urban County Council', 'Council Member, District 9', 12),
  ('lexington-fayette-ky-council-district-10', 'Lexington-Fayette Urban County Council', 'Council Member, District 10', 13),
  ('lexington-fayette-ky-council-district-11', 'Lexington-Fayette Urban County Council', 'Council Member, District 11', 14),
  ('lexington-fayette-ky-council-district-12', 'Lexington-Fayette Urban County Council', 'Council Member, District 12', 15);

-- The three at-large seats share one title and one district and are distinguished only by row,
-- which is Arizona's and Duluth's shape: the ballot does not number them.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant)
SELECT c.id, d.id, s.title, 'KY', 'Lexington', 1, false
FROM lex_seats s
JOIN essentials.chambers c ON c.name_formal = s.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = s.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'ky'
LEFT JOIN LATERAL (
  SELECT count(*) AS have FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = s.title
) x ON true
LEFT JOIN LATERAL (
  SELECT count(*) AS want FROM lex_seats s2
   WHERE s2.geo_id = s.geo_id AND s2.chamber_formal = s.chamber_formal AND s2.title = s.title
) y ON true
-- Idempotent by COUNT, not by existence: three at-large rows share one (chamber, district,
-- title), so an EXISTS guard would create one seat instead of three. On a re-run have = want
-- and nothing is inserted.
WHERE x.have < y.want;

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_council int; v_mayor int; v_al int; v_noc int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Lexington-Fayette Urban County Government, Kentucky, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0152: expected 1 government row, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE name_formal IN ('Lexington-Fayette Urban County Council', 'Office of the Mayor of Lexington-Fayette, Kentucky');
  IF v_ch <> 2 THEN RAISE EXCEPTION 'CC_0152: expected 2 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'ky';
  IF v_dist <> 13 THEN RAISE EXCEPTION 'CC_0152: expected 13 Kentucky LOCAL districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_council FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = 'Lexington-Fayette Urban County Council';
  SELECT count(*) INTO v_mayor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = 'Office of the Mayor of Lexington-Fayette, Kentucky';
  v_off := v_council + v_mayor;
  IF v_council <> 15 THEN RAISE EXCEPTION 'CC_0152: expected 15 council offices, got %', v_council; END IF;
  IF v_mayor <> 1 THEN RAISE EXCEPTION 'CC_0152: expected 1 mayor office, got %', v_mayor; END IF;

  -- Exactly three at-large seats, and they must NOT be numbered: the ballot does not number them,
  -- and a "Vice Mayor" office must not exist at all.
  SELECT count(*) INTO v_al FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Lexington-Fayette Urban County Council' AND o.title = 'Council Member, At-Large';
  IF v_al <> 3 THEN RAISE EXCEPTION 'CC_0152: expected 3 at-large offices, got %', v_al; END IF;

  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.chambers c ON c.id = o.chamber_id
              WHERE c.name_formal = 'Lexington-Fayette Urban County Council' AND o.title ILIKE '%vice mayor%') THEN
    RAISE EXCEPTION 'CC_0152: a Vice Mayor OFFICE exists. Voters elect three at-large members; the top vote-getter takes the Vice Mayor TITLE. It is not a separate office.';
  END IF;

  -- Every district seat must sit on its own polygon.
  SELECT count(*) INTO v_noc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal = 'Lexington-Fayette Urban County Council' AND o.title LIKE 'Council Member, District%'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = 'X0068');
  IF v_noc <> 0 THEN
    RAISE EXCEPTION 'CC_0152: % district office(s) sit on a district with no X0068 polygon - unreachable by address, and nothing would error', v_noc;
  END IF;

  RAISE NOTICE 'CC_0152 OK: 1 government, 2 chambers, 13 LOCAL districts, % offices (% council incl 3 at-large, % mayor)', v_off, v_council, v_mayor;
END $$;

COMMIT;

-- CC_0386_washoe_county_nv_structure.sql
-- Washoe County, Nevada — greenfield seed, STRUCTURE ONLY: government, one chamber,
-- five commission districts, five offices. NO PEOPLE ARE SEATED BY THIS MIGRATION.
--
-- Companion to CC_0385 (City of Reno). Reno sits wholly inside Washoe County — verified, not
-- assumed: the Reno place polygon has 0.000 km² outside the county polygon.
--
-- ═══ 🔴 WASHOE'S HANDOVER IS IN JANUARY, NOT ON RENO'S 2026-11-13 ═══
--
-- This is the trap in doing the two together. Reno's winners are sworn in at the Council
-- meeting following the election (Charter § 5.100(3)) — 2026-11-13. Washoe County's
-- commissioners are NOT: the three seats contested on 2026-11-03 (Districts 2, 3 and 5) do
-- not change hands until JANUARY 2027, and one of those races was still too close to call on
-- 2026-11-09.
--
-- The practical consequence is the opposite of Reno's: the five commissioners sitting today
-- REMAIN CORRECT for another two months, so unlike Reno there is no 96-hour shelf life on
-- seating them. They are still not seated here, so that structure can be reviewed and
-- reverted independently of any roster claim, and so that one roster pass can cite one
-- canvass. The January date belongs in `essentials.office_swearing_in` (CC_0344).
--
-- ═══ TRUE GREENFIELD, VERIFIED ═══
--   essentials.governments WHERE name ILIKE '%washoe%'  → 0 rows   (pre-checked 2026-11-09)
--   essentials.governments WHERE geo_id = '32031'       → 0 rows
-- Nevada's local tier was CLARK COUNTY ONLY before CC_0385/CC_0386.
--
-- ═══ 🔴 geo_id '32031' IS AMBIGUOUS WITHOUT AN MTFCC ═══
-- '32031' is BOTH Washoe County (G4020) and Nevada Assembly District 31 (G5220) in
-- `geofence_boundaries`. Every lookup in this file is keyed on (geo_id, mtfcc). A query that
-- keys on geo_id alone will silently pick up a state legislative district.
--
-- ═══ STRUCTURE ═══
-- Five commissioners, each elected by district to a four-year term, staggered. There is no
-- at-large seat and no separately elected executive: the Board elects its own Chair from
-- among its members, which is a ROLE and not a seat, so no office is created for it.
--
-- ⚠ SCOPE: the commission only. Washoe also elects a Sheriff, District Attorney, Assessor,
--   Recorder, Treasurer, Clerk and Public Administrator; none is seeded here. That is a
--   deliberate scope boundary agreed with the operator, not an oversight.
--
-- ⚠ CLARK COUNTY, the only other Nevada county in production, hangs all seven of its
--   commissioners on the COUNTYWIDE polygon with no per-district geography, so a Clark
--   address cannot tell you which commissioner is yours. Washoe is seeded BY DISTRICT and is
--   therefore better, not inconsistent. Clark is worth revisiting.
--
-- ═══ GEOGRAPHY ═══
-- The five district polygons load first, as X0087 / washoe-nv-commission-district-1..5, from
-- the county's OWN GIS (wcgisweb.washoecounty.us OpenData layer 4) — not from the City of Reno
-- or NDOT copies that an arcgis.com search returns first. This migration REFUSES TO RUN
-- without them.
--
-- Vintage proved against the county Registrar's own precinct layer (OpenData layer 7, field
-- COMMISSION) on 471 of 472 precincts. 🔴 THE ONE EXCEPTION IS PRECINCT 9113 and it is
-- documented rather than smoothed over: that 0.066 km² precinct straddles the District 1/5
-- boundary 20.8%/79.2% while the Registrar assigns all of it to District 1. It cannot
-- misroute anyone — the county's own address-point layer holds ZERO addresses inside precinct
-- 9113, against 185 in the surrounding bounding box, which is the control proving that layer
-- was answering. The loader baselines it BY PRECINCT NUMBER, so a different precinct drifting
-- later still fails the gate.
--
-- The five districts tile the county: 16,940.0 of 16,940.8 km² (99.995%), against a census
-- land area of 16,358.0 km².

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_d int; v_stray int; v_county int; v_gov int;
BEGIN
  SELECT count(*) INTO v_d FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0087' AND geo_id LIKE 'washoe-nv-commission-district-%';
  IF v_d <> 5 THEN
    RAISE EXCEPTION 'CC_0386 pre-flight: expected 5 X0087 Washoe commission polygons, found % — '
                    'run scripts/load-reno-washoe-districts.mjs first. An office on a district '
                    'with no polygon is unreachable by any address and nothing errors.', v_d;
  END IF;

  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0087' AND geo_id NOT LIKE 'washoe-nv-commission-district-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0386 pre-flight: % X0087 polygon(s) are not Washoe commission districts '
                    '— somebody else took this mtfcc code', v_stray;
  END IF;

  -- keyed on (geo_id, mtfcc): bare '32031' is also NV Assembly District 31
  SELECT count(*) INTO v_county FROM essentials.geofence_boundaries
   WHERE geo_id = '32031' AND mtfcc = 'G4020' AND state = '32';
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'CC_0386 pre-flight: expected the TIGER county polygon 32031/G4020, found %', v_county;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE (geo_id = '32031' AND mtfcc = 'G4020') OR name = 'Washoe County, Nevada, US';
  IF v_gov <> 0 THEN
    RAISE EXCEPTION 'CC_0386 pre-flight: Washoe County already exists (% row(s)). This migration '
                    'is written as a greenfield seed; re-check before re-running.', v_gov;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'Washoe County, Nevada, US', 'County', 'NV', NULL, '32031', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Washoe County, Nevada, US');

-- ── Chamber ───────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, not `name`, and the app ROUTES ON
--    THE SLUG. `name` matches Clark County's ('Board of County Commissioners') so the two Nevada
--    counties read the same way, but `name_formal` MUST carry the county or the slug collides:
--    14 of the 17 existing boards qualify it ('clark-county-board-of-county-commissioners'),
--    while Allen County IN and Centre County PA do not and therefore already SHARE the bare
--    slug 'board-of-county-commissioners' with each other. That is a pre-existing defect; this
--    migration does not join it. (No unique index enforces this — the collision is silent.)
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT g.id, 'Board of County Commissioners', 'Washoe County Board of County Commissioners', 5, '4', true
FROM essentials.governments g
WHERE g.name = 'Washoe County, Nevada, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners');

-- ── Districts ─────────────────────────────────────────────────────────────────
CREATE TEMP TABLE washoe_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO washoe_districts(geo_id, label) VALUES
  ('washoe-nv-commission-district-1', 'Washoe County Commission District 1'),
  ('washoe-nv-commission-district-2', 'Washoe County Commission District 2'),
  ('washoe-nv-commission-district-3', 'Washoe County Commission District 3'),
  ('washoe-nv-commission-district-4', 'Washoe County Commission District 4'),
  ('washoe-nv-commission-district-5', 'Washoe County Commission District 5');

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials, representation_basis)
SELECT n.geo_id, n.label, 'COUNTY', 'nv', NULL, 'X0087', 1, 'residency'
FROM washoe_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0087' AND d.district_type = 'COUNTY');

-- ── Offices ───────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state,
                                seats, is_vacant, is_appointed_position, voting_powers, representation_note)
SELECT c.id, d.id,
       'Commissioner, District ' || right(d.geo_id, 1),
       'NV', 1, true, false, 'full',
       'Elected by district to a staggered four-year term. The Board elects its own Chair from '
       || 'among the five members; the chairmanship is a role, not a separate seat.'
FROM essentials.districts d
JOIN essentials.governments g ON g.name = 'Washoe County, Nevada, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of County Commissioners'
WHERE d.mtfcc = 'X0087' AND d.district_type = 'COUNTY'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.chamber_id = c.id
      AND o.title = 'Commissioner, District ' || right(d.geo_id, 1));

-- ── Post-conditions ───────────────────────────────────────────────────────────
DO $$
DECLARE v_gov uuid; v_ch int; v_off int; v_dist int; v_badslug int; v_seated int; v_titles text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE name = 'Washoe County, Nevada, US';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'CC_0386 post: the government row is missing'; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE government_id = v_gov;
  IF v_ch <> 1 THEN RAISE EXCEPTION 'CC_0386 post: expected 1 chamber, found %', v_ch; END IF;

  SELECT count(*) INTO v_badslug FROM essentials.chambers
   WHERE government_id = v_gov AND (slug IS NULL OR slug = '');
  IF v_badslug <> 0 THEN
    RAISE EXCEPTION 'CC_0386 post: the Washoe chamber has an empty slug — name_formal was not set';
  END IF;

  -- the slug must be the county-qualified one, and must not be shared with another government
  SELECT count(*) INTO v_badslug FROM essentials.chambers
   WHERE slug = 'washoe-county-board-of-county-commissioners' AND government_id <> v_gov;
  IF v_badslug <> 0 THEN
    RAISE EXCEPTION 'CC_0386 post: % other chamber(s) already use the Washoe slug', v_badslug;
  END IF;
  PERFORM 1 FROM essentials.chambers
   WHERE government_id = v_gov AND slug = 'washoe-county-board-of-county-commissioners';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0386 post: the Washoe chamber slug is not the county-qualified one — '
                    'name_formal must be "Washoe County Board of County Commissioners", or the '
                    'slug collides with Allen County IN and Centre County PA';
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts WHERE mtfcc = 'X0087';
  IF v_dist <> 5 THEN RAISE EXCEPTION 'CC_0386 post: expected 5 X0087 districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.government_id = v_gov;
  IF v_off <> 5 THEN RAISE EXCEPTION 'CC_0386 post: expected 5 offices, found %', v_off; END IF;

  -- the five titles must be Districts 1..5 exactly — right(geo_id,1) is only safe while the
  -- count is single-digit, so assert the result rather than trusting the expression
  SELECT string_agg(o.title, ' | ' ORDER BY o.title) INTO v_titles
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_titles <> 'Commissioner, District 1 | Commissioner, District 2 | Commissioner, District 3 '
                 || '| Commissioner, District 4 | Commissioner, District 5' THEN
    RAISE EXCEPTION 'CC_0386 post: unexpected office titles: %', v_titles;
  END IF;

  SELECT count(*) INTO v_seated FROM essentials.politicians p
    JOIN essentials.offices o ON o.id = p.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov;
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0386 post: % politician(s) attached. This migration seeds STRUCTURE ONLY.', v_seated;
  END IF;

  RAISE NOTICE 'CC_0386 OK: Washoe County — 1 chamber, 5 districts, 5 offices, 0 seated (by design).';
END $$;

COMMIT;

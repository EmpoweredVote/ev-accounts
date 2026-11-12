-- CC_0392_corte_madera_ca_and_marin_bos_structure.sql
-- Town of Corte Madera, California — greenfield seed, STRUCTURE ONLY.
-- Marin County, California — RECONCILE: the Board of Supervisors, which the county's existing
-- record does not have at all.
-- NO PEOPLE ARE SEATED BY THIS MIGRATION. The roster is CC_0393.
--
-- ═══ 🔴 MARIN IS NOT GREENFIELD, AND THE PRE-CHECK THAT SAYS IT IS, IS READING THE WRONG
--        POINTER ═══
--
-- `essentials.governments` already holds 'Marin County, California, US' (geo_id 06041,
-- G4020) with a 'Countywide Elected Officials' chamber and three offices — Assessor-Recorder-
-- County Clerk, District Attorney, Sheriff-Coroner — all three OCCUPIED since migration 1666
-- (2026-08-10): Shelly Scott (-62041001), Lori E. Frugoli (-62041002), Jamie Scardina
-- (-62041003).
--
-- 🔴 A JOIN ON `politicians.office_id = offices.id` SHOWS ALL THREE AS EMPTY. It is the wrong
--    pointer: occupancy lives in `essentials.office_terms`, and those three politicians have
--    `office_id IS NULL`. `essentials.offices.politician_id` — the column the old Lancaster
--    write-up says to cross-check — NO LONGER EXISTS. Read `office_terms`, or read nothing.
--
-- What Marin is actually missing is the BOARD OF SUPERVISORS: no chamber, no district rows,
-- no offices. Five supervisors elected BY DISTRICT to four-year terms. This migration adds
-- exactly that and touches nothing migration 1666 wrote.
--
-- ═══ 🔴 THE NOVEMBER 3 2026 ELECTION IS STILL BEING COUNTED, AND NOTHING FROM IT IS SEATED
--        ANYWHERE IN THIS PAIR OF MIGRATIONS ═══
--
-- As of 2026-11-10 Marin had counted about 70% of its ballots with roughly 41,670 left, and
-- certification falls in December. Three of Corte Madera's five council seats were on that
-- ballot (Thomas, Beckman, Ravasio; Rosa Thomas did not file). The sitting five remain correct
-- until the Town reorganises in December, which is when a successor pass belongs.
--
-- ⚖ The County Supervisor races are NOT on that ballot: the June 2 2026 primary settled them,
--   so District 5 — an OPEN seat — has a successor arriving in JANUARY 2027. That successor is
--   deliberately NOT recorded, here or in CC_0393: the certified Statement of Votes Cast is
--   unreachable from this network (assets.marincounty.gov answers 403, both recount news
--   releases fail every fetch tier and have no Wayback snapshot). A name carried in on a search
--   summary is not a source. See the TO DO at the foot of CC_0393.
--
-- ═══ CORTE MADERA: FIVE AT-LARGE SEATS, AND THE MAYOR IS NOT ONE OF THEM ═══
--
-- The Town Council has five members elected AT LARGE by the whole town to four-year staggered
-- terms, in November of even years. "The Mayor and Vice Mayor are chosen by the Council for a
-- 1-year term, with the reorganization occurring annually in December"
-- (townofcortemadera.org/140/Town-Council, read 2026-11-11).
--
-- ⚖ So Mayor and Vice Mayor are ROTATING TITLES ON COUNCIL SEATS, not offices. Creating a
--   Mayor office would be wrong twice: it would invent a seat no voter elects, and it would
--   need a migration every December. This is the Santa Clarita shape. The rotation is recorded
--   on the chamber instead, where it is a fact about the body rather than about a seat.
--
-- ⚠ The five seats are genuinely INDISTINGUISHABLE — Corte Madera does not number them, and
--   the ballot contest is simply "Member, Town Council" with N seats open. So the five offices
--   carry the SAME title, which means the usual `NOT EXISTS (... AND o.title = n.title)` guard
--   would collapse them into one row. This file guards on the chamber's office COUNT instead.
--   Inventing "Seat 1..5" to make them distinct would be inventing data the Town does not have.
--
-- ⚠ SCOPE: the council only. Per the County's own filing record for 11/03/26, Corte Madera
--   elects NO other officer — unlike Fairfax, which elects a Town Clerk and a Town Treasurer.
--   That is a verified boundary, not an omission.
--
-- ═══ GEOGRAPHY ═══
--
-- Corte Madera needs no new polygon: TIGER 2024 place 0616462 (G4110, 4.40 sq mi) is already
-- in `geofence_boundaries`, and an at-large council hangs on the town polygon.
--
-- The five supervisorial districts load first as X0088 /
-- marin-county-ca-supervisorial-district-1..5, by
-- scripts/load-marin-supervisorial-districts.mjs, from the County's OWN open data
-- (services6.arcgis.com .../Supervisorial_Districts/30). THIS MIGRATION REFUSES TO RUN without
-- them: an office on a district with no polygon is unreachable by any address and NOTHING
-- ERRORS.
--
-- 🔑 Vintage proved against the County's own ballot layer. Marin's Subprecincts layer
--    (lastEditDate 2026-09-04) carries no district column — but THE LEADING DIGIT OF A
--    SubPrecinct ID IS ITS SUPERVISORIAL DISTRICT, measured 738 of 738 with 0 disagreements
--    across 170,099 registered voters. Every subprecinct's interior point falls in the district
--    its own ballot number claims. The loader's control (--control=scramble) swaps two
--    districts and scores 277 disagreements, so the gate is not vacuous.
--
-- 🔴 The district layer's `Supervisor` column is TWO YEARS STALE — D2 still says Katie Rice,
--    who left in 2024. Geometry is taken from that layer; occupancy never is.
--
-- 🔴 geo_id '06041' IS AMBIGUOUS WITHOUT AN MTFCC: it is BOTH Marin County (G4020) and
--    California Assembly District 41 (G5220) in `geofence_boundaries`. Every lookup in this
--    file is keyed on (geo_id, mtfcc).

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_poly int; v_cm int; v_marin uuid; v_bos int; v_county_poly int; v_town_poly int;
BEGIN
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0088' AND geo_id LIKE 'marin-county-ca-supervisorial-district-%';
  IF v_poly <> 5 THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: expected 5 X0088 Marin supervisorial polygons, found % — '
                    'run scripts/load-marin-supervisorial-districts.mjs first. An office on a '
                    'district with no polygon is unreachable by any address, and nothing errors.', v_poly;
  END IF;

  SELECT count(*) INTO v_town_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '0616462' AND mtfcc = 'G4110';
  IF v_town_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: the Corte Madera town polygon (0616462/G4110) is missing.';
  END IF;

  SELECT count(*) INTO v_county_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '06041' AND mtfcc = 'G4020';
  IF v_county_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: the Marin County polygon (06041/G4020) is missing.';
  END IF;

  -- Corte Madera must be absent: this half is a greenfield seed.
  SELECT count(*) INTO v_cm FROM essentials.governments
   WHERE geo_id = '0616462' OR name = 'Town of Corte Madera, California, US';
  IF v_cm <> 0 THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: Corte Madera already exists (% row(s)). This half is '
                    'written as a greenfield seed; re-check before re-running.', v_cm;
  END IF;

  -- Marin must be PRESENT: this half is a reconcile, and running it against a missing county
  -- would silently create nothing.
  SELECT id INTO v_marin FROM essentials.governments
   WHERE name = 'Marin County, California, US' AND geo_id = '06041';
  IF v_marin IS NULL THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: Marin County is missing. This half is a RECONCILE of the '
                    'government migration 1666 created, not a greenfield seed.';
  END IF;

  SELECT count(*) INTO v_bos FROM essentials.chambers
   WHERE government_id = v_marin AND name ILIKE '%supervisor%';
  IF v_bos <> 0 THEN
    RAISE EXCEPTION 'CC_0392 pre-flight: Marin already has % Board of Supervisors chamber(s).', v_bos;
  END IF;
END $$;

-- ══ CORTE MADERA ══════════════════════════════════════════════════════════════

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'Town of Corte Madera, California, US', 'Town', 'CA', 'Corte Madera', '0616462', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Town of Corte Madera, California, US');

-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
--    A bare 'town-council' would also collide with every other Town Council in the country.
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length,
                                 election_method, election_frequency, staggered_term, remarks)
SELECT g.id, 'Town Council', 'Corte Madera Town Council', 5, '4',
       'at-large', 'November of even-numbered years', true,
       'Five members elected at large to four-year staggered terms. The Mayor and Vice Mayor '
       || 'are chosen BY THE COUNCIL from among its own members for one-year terms, at a '
       || 'reorganisation held each December — they are rotating titles on council seats, not '
       || 'separate offices, and no voter elects them. Councilmember salary $950/month from '
       || '2026-01-01 (Ordinance No. 1037, Government Code s 36516.5). '
       || 'Source: townofcortemadera.org/140/Town-Council, read 2026-11-11.'
FROM essentials.governments g
WHERE g.name = 'Town of Corte Madera, California, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = 'Town Council');

-- One townwide at-large district carries all five seats.
INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc,
                                  num_officials, representation_basis)
SELECT '0616462', 'Town of Corte Madera (At-Large)', 'LOCAL', 'ca', 'Corte Madera', 'G4110',
       5, 'residency'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = '0616462' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL');

-- ⚠ Five IDENTICAL offices. The guard is the chamber's office COUNT, because the titles cannot
--   tell the rows apart — see the header. Title is the County's own ballot wording for the
--   contest ("Town of Corte Madera / Member Town Council", 11/03/26 filing record).
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city,
                                seats, is_vacant, is_appointed_position, voting_powers, representation_note)
SELECT c.id, d.id, 'Member, Town Council', 'CA', 'Corte Madera', 1, true, false, 'full',
       'Elected at large by the whole town to a four-year term; terms are staggered, so three '
       || 'seats stand in one cycle and two in the next. The Town does not number its seats.'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Town Council'
JOIN essentials.districts d
  ON d.geo_id = '0616462' AND d.mtfcc = 'G4110' AND d.district_type = 'LOCAL' AND lower(d.state) = 'ca'
CROSS JOIN generate_series(1, 5) AS s(i)
WHERE g.name = 'Town of Corte Madera, California, US'
  AND (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id) = 0;

-- ══ MARIN COUNTY BOARD OF SUPERVISORS ═════════════════════════════════════════

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length,
                                 election_method, staggered_term, remarks)
SELECT g.id, 'Board of Supervisors', 'Marin County Board of Supervisors', 5, '4',
       'by-district', true,
       'Five supervisors elected BY DISTRICT to four-year staggered terms; the Board elects its '
       || 'own President and Vice Presidents from among its members, which is a role and not a '
       || 'seat, so no office is created for it. The Board is both the legislative and the '
       || 'executive body of the county and also governs the County Free Library and several '
       || 'special districts. Source: marincounty.gov/departments/board/about-board-supervisors.'
FROM essentials.governments g
WHERE g.name = 'Marin County, California, US' AND g.geo_id = '06041'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Board of Supervisors');

CREATE TEMP TABLE marin_districts(num int, geo_id text, label text) ON COMMIT DROP;
INSERT INTO marin_districts(num, geo_id, label) VALUES
  (1, 'marin-county-ca-supervisorial-district-1', 'Marin County Supervisorial District 1'),
  (2, 'marin-county-ca-supervisorial-district-2', 'Marin County Supervisorial District 2'),
  (3, 'marin-county-ca-supervisorial-district-3', 'Marin County Supervisorial District 3'),
  (4, 'marin-county-ca-supervisorial-district-4', 'Marin County Supervisorial District 4'),
  (5, 'marin-county-ca-supervisorial-district-5', 'Marin County Supervisorial District 5');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc,
                                  num_officials, representation_basis, government_id)
SELECT n.geo_id, n.label, 'COUNTY', 'ca', 'X0088', 1, 'residency', g.id
FROM marin_districts n
JOIN essentials.governments g ON g.name = 'Marin County, California, US' AND g.geo_id = '06041'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0088' AND d.district_type = 'COUNTY');

-- Title follows the County's own contest wording ("County Supervisor District 5", Elections
-- Department, June 2 2026 primary pages).
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state,
                                seats, is_vacant, is_appointed_position, voting_powers)
SELECT c.id, d.id, 'County Supervisor, District ' || n.num, 'CA', 1, true, false, 'full'
FROM marin_districts n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = 'X0088' AND d.district_type = 'COUNTY'
JOIN essentials.governments g ON g.name = 'Marin County, California, US' AND g.geo_id = '06041'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of Supervisors'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id AND o.chamber_id = c.id
    AND o.title = 'County Supervisor, District ' || n.num);

-- ── Post-conditions ───────────────────────────────────────────────────────────
-- 🔴 VERIFY ON ROW COUNTS AND ON THE SLUG, not on "the inserts did not error". An empty slug
--    is the silent failure mode here, and it does not raise.
DO $$
DECLARE v_cm uuid; v_marin uuid; v_ch int; v_off int; v_dist int; v_badslug int;
        v_bos_off int; v_seated int; v_countywide int;
BEGIN
  SELECT id INTO v_cm FROM essentials.governments WHERE name = 'Town of Corte Madera, California, US';
  IF v_cm IS NULL THEN RAISE EXCEPTION 'CC_0392 post: the Corte Madera government row is missing'; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE government_id = v_cm;
  IF v_ch <> 1 THEN RAISE EXCEPTION 'CC_0392 post: expected 1 Corte Madera chamber, found %', v_ch; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.government_id = v_cm;
  IF v_off <> 5 THEN RAISE EXCEPTION 'CC_0392 post: expected 5 Corte Madera council offices, found %', v_off; END IF;

  SELECT id INTO v_marin FROM essentials.governments
   WHERE name = 'Marin County, California, US' AND geo_id = '06041';

  SELECT count(*) INTO v_bos_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_marin AND c.name = 'Board of Supervisors';
  IF v_bos_off <> 5 THEN RAISE EXCEPTION 'CC_0392 post: expected 5 supervisor offices, found %', v_bos_off; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0088' AND district_type = 'COUNTY';
  IF v_dist <> 5 THEN RAISE EXCEPTION 'CC_0392 post: expected 5 X0088 district rows, found %', v_dist; END IF;

  -- Every supervisor office must sit on a district that HAS a polygon.
  SELECT count(*) INTO v_dist FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id AND c.government_id = v_marin
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name = 'Board of Supervisors'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_dist <> 0 THEN
    RAISE EXCEPTION 'CC_0392 post: % supervisor office(s) sit on a district with no polygon — '
                    'unreachable by any address', v_dist;
  END IF;

  SELECT count(*) INTO v_badslug FROM essentials.chambers
   WHERE government_id IN (v_cm, v_marin) AND (slug IS NULL OR slug = '');
  IF v_badslug <> 0 THEN
    RAISE EXCEPTION 'CC_0392 post: % chamber(s) have an empty slug — name_formal was not set, and '
                    'the app routes on the slug', v_badslug;
  END IF;

  -- This migration seats NOBODY.
  SELECT count(*) INTO v_seated FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_cm
      OR (c.government_id = v_marin AND c.name = 'Board of Supervisors');
  IF v_seated <> 0 THEN
    RAISE EXCEPTION 'CC_0392 post: % office_terms row(s) exist — this migration seats nobody; '
                    'the roster is CC_0393', v_seated;
  END IF;

  -- And it must not have disturbed what migration 1666 wrote.
  SELECT count(*) INTO v_countywide FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_marin AND c.name = 'Countywide Elected Officials';
  IF v_countywide <> 3 THEN
    RAISE EXCEPTION 'CC_0392 post: expected migration 1666''s 3 countywide office_terms to be '
                    'untouched, found %', v_countywide;
  END IF;
END $$;

COMMIT;

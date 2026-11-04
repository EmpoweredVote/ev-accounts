-- CC_0316_alaska_legislature_structure.sql
-- Alaska Legislature — structure only: two chambers and 60 offices.
-- Occupancy is CC_0317. Portraits are CC_0318.
--
-- Roster, sources, structural rulings and source defects:
--   backend/data/seed-ak-legislature-2026/ROSTERS.md
--
-- ═══ WHAT ALASKA IS ═══
--
-- Alaska Const. Art. II sec. 2 fixes the legislature at "a senate of twenty members and a house of
-- representatives of forty members". Both chambers are SINGLE-MEMBER — unlike Idaho, there is no
-- Seat A / Seat B, and the polygon count IS the seat count in both.
--
--   essentials.districts G5210 for Alaska: 20 rows  -> 20 Senate offices  (1 per district)
--   essentials.districts G5220 for Alaska: 40 rows  -> 40 House offices   (1 per district)
--
-- 🔴 ALASKA'S SENATE DISTRICTS ARE LETTERED A..T, NOT NUMBERED. The House is numbered 1..40.
--    Read straight from TIGER tl_2024_02_sldu.dbf on 2026-10-30: SLDUST is '00A'..'00T' and
--    GEOID is '0200A'..'0200T'. This is the INVERSE of Idaho, whose loader pre-flight asserts
--    that lettered codes are ABSENT. Both assertions now sit in
--    scripts/load-state-tiger-boundaries.ts and each names which it is, so neither can be pasted
--    over the other.
--
-- 🔴 THE DIGITS IN '00A' ARE PADDING AND parseInt WOULD EAT THE LETTER. src/lib/ocdDistrictSuffix.ts
--    carries the branch that returns 'A' rather than '0A'; Alaska is the first state loaded here
--    whose district code is PURELY alphabetic. Measured before changing it: zero existing
--    STATE_UPPER/STATE_LOWER rows in production match ^0+[A-Za-z]+$, so no existing row moved.
--    Verified after the load: all 20 rows are ocd-division/country:us/state:ak/sldu:A .. :T, and
--    none carries a leading zero.
--
-- ⚠ G5220 AND G4020 SHARE A geo_id IN ALASKA. House Districts 13, 16 and 20 are geo_id '02013',
--   '02016' and '02020' — and so are the Aleutians East, Aleutians West and Anchorage boroughs,
--   which are G4020. The key is the PAIR (mtfcc, geo_id), never geo_id alone. Every predicate
--   below pairs mtfcc with district_type and filters on lower(state) = 'ak', because
--   essentials.districts.state is mixed case.
--
-- ═══ 🔴 THE SENATE/HOUSE NESTING, AND WHY IT IS ASSERTED *HERE* ═══
--
-- Senate district letter N covers House districts 2N-1 and 2N: A = 1+2, B = 3+4, ... T = 39+40.
-- Measured 2026-10-30, three independent ways:
--   * all 40 House interior points fall inside Senate ceil(N/2)  (TIGER shapefile, offline)
--   * all 20 Senate ALAND values equal the sum of their two House ALAND values to within 0.1%
--   * all 40 again after loading, with ST_Contains against the loaded polygons (the gate below)
--
-- 🔴 THIS IS THE EXACT THING ALASKA'S 2021-22 REDISTRICTING LITIGATION WAS ABOUT. The Alaska
--    Supreme Court twice struck down the Board's Senate PAIRINGS around Eagle River and East
--    Anchorage while leaving the 40 House districts standing — so in Alaska the pairing is the
--    part that moved, and it is the part worth gating on. The gate confirms Eagle River's two
--    House districts (23, 24) pair with each other as Senate L, and East Anchorage's (21, 22)
--    as Senate K.
--
-- ⚠ IT IS A STRUCTURAL CHECK AND NOT A VINTAGE CHECK, AND THE DIFFERENCE MATTERS. The superseded
--   2013 plan nests exactly the same way, so this gate passing says NOTHING about which map was
--   loaded. Dating the map is the loader pre-flight's job and is done with eight discriminating
--   anchors per layer; `--vintage 2021` was run as a live control and aborted with "THIS FILE IS
--   THE SUPERSEDED 2013 PLAN". Keeping the two apart is deliberate: a reader who finds the
--   nesting gate green must not conclude the vintage was checked.
--
-- ═══ PARTY IS NOT WRITTEN ON THE PERSON ═══
--
-- The Legislature's roster prints a party for all 60 and CC_0317 still leaves
-- `politicians.party` NULL — party lives on `races.primary_party`. That is what HI, ID, MN, SC
-- and FL carry for their legislators. `offices.partisan_type` records that the contest is
-- partisan; `chambers.election_rules` records HOW Alaska runs it, which is unusual enough to
-- write down rather than imply.
--
-- ⚠ ALASKA IS NOT A CONVENTIONAL PARTISAN-PRIMARY STATE. Since Ballot Measure 2 (2020) it runs a
--   single open TOP-FOUR primary and a RANKED-CHOICE general; this repo already carries that as
--   verified for Alaska in migration 1254, against elections.alaska.gov. Party preference still
--   appears on the ballot and the chambers organise by caucus, so `partisan_type = 'partisan'` is
--   right — but 'partisan' here must not be read as "closed partisan primary".
-- ⚠ AND THE CAUCUSES ARE NOT THE PARTIES. Both chambers of the 34th Legislature are run by
--   BIPARTISAN COALITION majorities. Nothing in this migration encodes a majority, and nothing
--   should: a coalition is re-formed at the start of each legislature and would go stale.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. NO `term_end`. A future term_end makes a seat silently self-vacate.
--  2. NO occupancy. An office with no `office_terms` row is INVISIBLE — no holder, so the member
--     never appears in Essentials, stance research, coverage or campaign finance, and NOTHING
--     ERRORS. That is why CC_0317 ships in the same session.
--  3. NO `is_vacant`. Every one of the 60 seats is filled; CC_0317's gate asserts that, and a
--     flag set here would have to be cleared there (the two helpers are not symmetric about it).
--  4. NO geography. The 60 district rows were loaded by
--     `scripts/load-state-tiger-boundaries.ts --state AK --fips 02 --layers sldu,sldl`, whose AK
--     pre-flight proved the vintage is the adopted 2021 plan and not the superseded 2013 plan.
--     A count cannot tell those apart — both are 20/40, fixed by the constitution — so only the
--     anchors can.

BEGIN;

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_sldu int; v_sldl int; v_ch int; v_off int;
  v_unlettered int; v_lettered_house int; v_nogeom int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'State of Alaska' AND geo_id = '02' AND mtfcc = 'G4000';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: expected exactly 1 "State of Alaska" government on 02/G4000, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_sldu FROM essentials.districts
   WHERE mtfcc = 'G5210' AND district_type = 'STATE_UPPER' AND lower(state) = 'ak';
  IF v_sldu <> 20 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: expected 20 Alaska G5210 districts, found % — run '
                    'load-state-tiger-boundaries.ts --state AK --fips 02 --layers sldu,sldl first', v_sldu;
  END IF;

  SELECT count(*) INTO v_sldl FROM essentials.districts
   WHERE mtfcc = 'G5220' AND district_type = 'STATE_LOWER' AND lower(state) = 'ak';
  IF v_sldl <> 40 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: expected 40 Alaska G5220 districts, found %', v_sldl;
  END IF;

  -- 🔴 ASSERTED AS A PRESENCE. The Senate districts ARE the letters A..T; every office title,
  -- district label and seating below is keyed on the letter. If these ever arrive numbered, the
  -- whole slice is keyed on something that no longer exists.
  SELECT count(*) INTO v_unlettered FROM essentials.districts
   WHERE mtfcc = 'G5210' AND lower(state) = 'ak'
     AND ocd_id !~ '/sldu:[A-T]$';
  IF v_unlettered <> 0 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: % Alaska Senate districts do not carry a single-letter '
                    'A..T OCD-ID suffix. Alaska Senate districts are LETTERED. A suffix like '
                    '"0A" means ocdDistrictSuffix dropped the padding rule; a numbered suffix '
                    'means TIGER renamed the chamber. Either way, stop.', v_unlettered;
  END IF;

  -- 🔴 ASSERTED AS AN ABSENCE on the House — the inverse, on the other layer.
  SELECT count(*) INTO v_lettered_house FROM essentials.districts
   WHERE mtfcc = 'G5220' AND lower(state) = 'ak'
     AND ocd_id !~ '/sldl:([1-9]|[12][0-9]|3[0-9]|40)$';
  IF v_lettered_house <> 0 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: % Alaska House districts do not carry a plain 1..40 '
                    'OCD-ID suffix. The House is numbered and single-member.', v_lettered_house;
  END IF;

  -- An office on a district with no polygon is unreachable by any address, and nothing errors.
  SELECT count(*) INTO v_nogeom
    FROM essentials.districts d
    LEFT JOIN essentials.geofence_boundaries gb
           ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
   WHERE lower(d.state) = 'ak' AND d.mtfcc IN ('G5210','G5220') AND gb.id IS NULL;
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: % Alaska legislative districts have NO geofence polygon. '
                    'An office on one is invisible to address search and nothing errors.', v_nogeom;
  END IF;

  -- Greenfield, verified rather than assumed.
  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '02' AND g.mtfcc = 'G4000'
     AND c.name IN ('Alaska Senate', 'Alaska House of Representatives');
  IF v_ch <> 0 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: % Alaska legislative chamber(s) already exist — this '
                    'migration creates them and is not a re-seeder', v_ch;
  END IF;

  SELECT count(*) INTO v_off
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF v_off <> 0 THEN
    RAISE EXCEPTION 'CC_0316 pre-flight: % Alaska state legislative office(s) already exist', v_off;
  END IF;

  RAISE NOTICE 'CC_0316 pre-flight OK: 20 G5210 + 40 G5220 Alaska districts, all with polygons, '
               'Senate lettered A..T, House numbered 1..40, no existing chambers or offices.';
END $$;

-- ── The two chambers ──────────────────────────────────────────────────────────
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term,
   election_method, election_rules, vacancy_rules, inauguration_rules)
SELECT g.id, v.name, v.name_formal, v.official_count, v.term_length, v.staggered_term,
       v.election_method, v.election_rules, v.vacancy_rules, v.inauguration_rules
  FROM essentials.governments g
  CROSS JOIN (VALUES
    ('Alaska Senate', 'Alaska State Senate', 20::bigint, '4', true, 'rcv',
     'Open top-four primary and a ranked-choice general election (Ballot Measure 2, 2020). '
     || 'Four-year terms, staggered: half the 20 seats are on the ballot at each general election. '
     || 'Senate districts are LETTERED A through T and each is exactly two House districts.',
     'Alaska Const. Art. II sec. 4: a vacancy is filled for the unexpired term as provided by law; '
     || 'absent provision the governor appoints. Alaska fills legislative vacancies by appointment, '
     || 'not by special election — 2 of the 20 sitting senators arrived that way.',
     'Alaska Const. Art. II sec. 3 gives the fourth Monday of January "unless otherwise provided by '
     || 'law", and AS 24.05.080 so provides: terms begin on the THIRD TUESDAY IN JANUARY following '
     || 'the election. Observed on three separate cycles — 2015-01-20, 2023-01-17, 2025-01-21.'),
    ('Alaska House of Representatives', 'Alaska House of Representatives', 40::bigint, '2', false, 'rcv',
     'Open top-four primary and a ranked-choice general election (Ballot Measure 2, 2020). '
     || 'Two-year terms, so ALL 40 seats are on the ballot at every general election. '
     || 'House districts are NUMBERED 1 through 40 and each is single-member.',
     'Alaska Const. Art. II sec. 4: a vacancy is filled for the unexpired term as provided by law; '
     || 'absent provision the governor appoints. 2 of the 40 sitting representatives arrived that way.',
     'AS 24.05.080 — terms begin on the third Tuesday in January following the election.')
  ) AS v(name, name_formal, official_count, term_length, staggered_term,
         election_method, election_rules, vacancy_rules, inauguration_rules)
 WHERE g.geo_id = '02' AND g.mtfcc = 'G4000'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name
   );

-- ── The 60 offices ────────────────────────────────────────────────────────────
-- One per district. `seats = 1` in BOTH chambers: Alaska is single-member throughout.
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, partisan_type, seats, is_vacant)
SELECT c.id, d.id, v.title, 'AK', 'partisan', 1, false
  FROM (VALUES
-- @generated-by data/seed-ak-legislature-2026/gen-migration-values.mjs from roster-final.json
    ('G5220', '02010', 'STATE_LOWER', 'Representative', '10'),
    ('G5220', '02037', 'STATE_LOWER', 'Representative', '37'),
    ('G5220', '02025', 'STATE_LOWER', 'Representative', '25'),
    ('G5220', '02023', 'STATE_LOWER', 'Representative', '23'),
    ('G5220', '02001', 'STATE_LOWER', 'Representative', '1'),
    ('G5220', '02035', 'STATE_LOWER', 'Representative', '35'),
    ('G5220', '02015', 'STATE_LOWER', 'Representative', '15'),
    ('G5220', '02011', 'STATE_LOWER', 'Representative', '11'),
    ('G5220', '02031', 'STATE_LOWER', 'Representative', '31'),
    ('G5220', '02022', 'STATE_LOWER', 'Representative', '22'),
    ('G5220', '02008', 'STATE_LOWER', 'Representative', '8'),
    ('G5220', '02017', 'STATE_LOWER', 'Representative', '17'),
    ('G5220', '02039', 'STATE_LOWER', 'Representative', '39'),
    ('G5220', '02040', 'STATE_LOWER', 'Representative', '40'),
    ('G5220', '02014', 'STATE_LOWER', 'Representative', '14'),
    ('G5220', '02020', 'STATE_LOWER', 'Representative', '20'),
    ('G5220', '02016', 'STATE_LOWER', 'Representative', '16'),
    ('G5220', '02004', 'STATE_LOWER', 'Representative', '4'),
    ('G5220', '02002', 'STATE_LOWER', 'Representative', '2'),
    ('G5220', '02009', 'STATE_LOWER', 'Representative', '9'),
    ('G5220', '02038', 'STATE_LOWER', 'Representative', '38'),
    ('G5220', '02013', 'STATE_LOWER', 'Representative', '13'),
    ('G5220', '02030', 'STATE_LOWER', 'Representative', '30'),
    ('G5220', '02021', 'STATE_LOWER', 'Representative', '21'),
    ('G5220', '02019', 'STATE_LOWER', 'Representative', '19'),
    ('G5220', '02028', 'STATE_LOWER', 'Representative', '28'),
    ('G5220', '02018', 'STATE_LOWER', 'Representative', '18'),
    ('G5220', '02029', 'STATE_LOWER', 'Representative', '29'),
    ('G5220', '02033', 'STATE_LOWER', 'Representative', '33'),
    ('G5220', '02007', 'STATE_LOWER', 'Representative', '7'),
    ('G5220', '02024', 'STATE_LOWER', 'Representative', '24'),
    ('G5220', '02012', 'STATE_LOWER', 'Representative', '12'),
    ('G5220', '02036', 'STATE_LOWER', 'Representative', '36'),
    ('G5220', '02026', 'STATE_LOWER', 'Representative', '26'),
    ('G5220', '02034', 'STATE_LOWER', 'Representative', '34'),
    ('G5220', '02003', 'STATE_LOWER', 'Representative', '3'),
    ('G5220', '02005', 'STATE_LOWER', 'Representative', '5'),
    ('G5220', '02032', 'STATE_LOWER', 'Representative', '32'),
    ('G5220', '02027', 'STATE_LOWER', 'Representative', '27'),
    ('G5220', '02006', 'STATE_LOWER', 'Representative', '6'),
    ('G5210', '0200E', 'STATE_UPPER', 'Senator', 'E'),
    ('G5210', '0200C', 'STATE_UPPER', 'Senator', 'C'),
    ('G5210', '0200R', 'STATE_UPPER', 'Senator', 'R'),
    ('G5210', '0200D', 'STATE_UPPER', 'Senator', 'D'),
    ('G5210', '0200H', 'STATE_UPPER', 'Senator', 'H'),
    ('G5210', '0200J', 'STATE_UPPER', 'Senator', 'J'),
    ('G5210', '0200G', 'STATE_UPPER', 'Senator', 'G'),
    ('G5210', '0200S', 'STATE_UPPER', 'Senator', 'S'),
    ('G5210', '0200F', 'STATE_UPPER', 'Senator', 'F'),
    ('G5210', '0200P', 'STATE_UPPER', 'Senator', 'P'),
    ('G5210', '0200B', 'STATE_UPPER', 'Senator', 'B'),
    ('G5210', '0200L', 'STATE_UPPER', 'Senator', 'L'),
    ('G5210', '0200Q', 'STATE_UPPER', 'Senator', 'Q'),
    ('G5210', '0200T', 'STATE_UPPER', 'Senator', 'T'),
    ('G5210', '0200O', 'STATE_UPPER', 'Senator', 'O'),
    ('G5210', '0200A', 'STATE_UPPER', 'Senator', 'A'),
    ('G5210', '0200M', 'STATE_UPPER', 'Senator', 'M'),
    ('G5210', '0200I', 'STATE_UPPER', 'Senator', 'I'),
    ('G5210', '0200K', 'STATE_UPPER', 'Senator', 'K'),
    ('G5210', '0200N', 'STATE_UPPER', 'Senator', 'N')
  ) AS v(mtfcc, geo_id, district_type, title, district_code)
  JOIN essentials.districts d
    ON d.mtfcc = v.mtfcc AND d.geo_id = v.geo_id
   AND d.district_type = v.district_type AND lower(d.state) = 'ak'
  JOIN essentials.governments g ON g.geo_id = '02' AND g.mtfcc = 'G4000'
  JOIN essentials.chambers c
    ON c.government_id = g.id
   AND c.name = CASE WHEN v.district_type = 'STATE_UPPER'
                     THEN 'Alaska Senate' ELSE 'Alaska House of Representatives' END
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.chamber_id = c.id
 );

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_sen int; v_hou int; v_dup int; v_ch int; v_vac int; v_nest int; v_pair text; v_nest_rows int;
BEGIN
  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '02' AND g.mtfcc = 'G4000'
     AND c.name IN ('Alaska Senate', 'Alaska House of Representatives');
  IF v_ch <> 2 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: expected 2 Alaska legislative chambers, found %', v_ch;
  END IF;

  SELECT count(*) INTO v_sen
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type = 'STATE_UPPER';
  IF v_sen <> 20 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: expected 20 Alaska Senate offices (20 districts x 1 '
                    'senator), found %', v_sen;
  END IF;

  SELECT count(*) INTO v_hou
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type = 'STATE_LOWER';
  IF v_hou <> 40 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: expected 40 Alaska House offices (40 districts x 1 '
                    'representative — Alaska is single-member, there is no Seat A / Seat B), found %', v_hou;
  END IF;

  -- One office per district, in both chambers.
  SELECT count(*) INTO v_dup FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: % Alaska legislative district(s) carry more than one '
                    'office. Both chambers are single-member.', v_dup;
  END IF;

  -- No seat is flagged vacant here; CC_0317 fills all 60.
  SELECT count(*) INTO v_vac
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ak' AND d.district_type IN ('STATE_UPPER','STATE_LOWER')
     AND o.is_vacant;
  IF v_vac <> 0 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: % Alaska legislative office(s) are flagged vacant. All '
                    '60 are filled and CC_0317 seats them; seat_officeholder does NOT clear the '
                    'flag, so a flag set here would survive into production as held-AND-vacant.', v_vac;
  END IF;

  -- 🔴 THE NESTING GATE. Senate letter N must contain the interior point of House 2N-1 and 2N.
  -- Run against the LOADED polygons, so it tests what production will actually answer with.
  -- ⚠ STRUCTURAL, NOT A VINTAGE CHECK — the superseded 2013 plan nests identically. See header.
  SELECT count(*), string_agg(t.hnum::text || '->' || coalesce(t.got,'NONE')
                              || ' (want ' || t.want || ')', ', ' ORDER BY t.hnum)
    INTO v_nest, v_pair
    FROM (
      SELECT (right(h.geo_id,3))::int AS hnum,
             chr(64 + ((right(h.geo_id,3))::int + 1) / 2) AS want,
             (SELECT right(s.geo_id,1) FROM essentials.geofence_boundaries s
               WHERE s.state='02' AND s.mtfcc='G5210'
                 AND ST_Contains(s.geometry, ST_PointOnSurface(h.geometry)) LIMIT 1) AS got
        FROM essentials.geofence_boundaries h
       WHERE h.state='02' AND h.mtfcc='G5220'
    ) t
   WHERE t.got IS DISTINCT FROM t.want;

  -- ⚠ A GATE THAT READ NO ROWS REPORTS ZERO MISMATCHES AND PASSES. Count what it examined.
  SELECT count(*) INTO v_nest_rows FROM essentials.geofence_boundaries
   WHERE state='02' AND mtfcc='G5220';
  IF v_nest_rows <> 40 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: the nesting gate examined % House polygons, expected 40. '
                    'A gate that reads nothing finds nothing wrong.', v_nest_rows;
  END IF;
  IF v_nest <> 0 THEN
    RAISE EXCEPTION 'CC_0316 post-verify: % of 40 Alaska House districts do not sit inside the '
                    'Senate district the A..T pairing requires (Senate ceil(N/2)): %. ⚠ The Senate '
                    'PAIRINGS are exactly what Alaska''s 2021-22 redistricting litigation moved — '
                    'Eagle River (House 23,24 = Senate L) and East Anchorage (21,22 = Senate K) '
                    'were each redrawn twice by court order. A failure here means the loaded '
                    'Senate layer does not pair with the loaded House layer, so STOP and '
                    're-measure both before seating anyone.', v_nest, v_pair;
  END IF;

  RAISE NOTICE 'CC_0316 OK: 2 chambers, 20 Senate + 40 House offices, one per district, none '
               'flagged vacant, and all 40 House districts nest in Senate ceil(N/2) against the '
               'loaded polygons. Occupancy is CC_0317 — until it runs these 60 seats are INVISIBLE.';
END $$;

COMMIT;

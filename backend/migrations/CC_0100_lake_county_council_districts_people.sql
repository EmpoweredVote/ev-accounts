-- CC_0100_lake_county_council_districts_people.sql
-- Knight Foundation program, wave IN-9 (occupancy half). Slot RESERVED from the allocator.
--
-- Seats the seven Lake County Council district members created by CC_0099. 7 people, 7 terms,
-- 0 vacancies. Apply immediately after CC_0099: between the two, seven offices exist with no
-- term, which is the state `essentials.offices_missing_terms` counts.
--
--   D1  David Hamm              D5  Christine Cid          (Council President)
--   D2  Ronald G. Brewer Sr.    D6  Ted Bilski
--       (Council Vice President)
--   D3  Charlie Brown           D7  Randy Niemeyer
--   D4  Pete Lindemulder
--
-- SOURCE: lakecountyin.gov/departments/council -- the Council's own "Our Team" block -- AND, read
-- separately, the county's SEVEN per-district pages `departments/council-1stdist` ..
-- `council-7thdist`. Both read live 2026-09-11.
--
-- 🟢 THE PER-DISTRICT PAGES ARE THE STRONGER EVIDENCE AND THAT IS WHY THEY WERE READ.
-- IN-6's roster came from the aggregate "Our Team" list, which pairs names and districts in one
-- block -- and a block can be mis-ordered without looking wrong. Seven separately-addressed pages,
-- each naming exactly ONE member, cannot be. They agree with the block on all seven.
-- ⚠ IN-6 also recorded that an AGGREGATED roster source returned three commissioners belonging to
-- a Lake County in ANOTHER STATE. Only the county's own pages are used here.
--
-- CHANGE-CHECK (the "has this person LEFT?" question, which only the body's own roster answers):
-- all seven are still named, still on the same districts, and no unexplained name appears.
-- The only change since IN-6 is that Brewer is now listed as Council Vice President.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 ALL SEVEN TERMS ARE `unknown`, AND THAT IS THE HONEST ANSWER, NOT A GAP.
-- IN-6 established that Ballotpedia returns HTTP 404 for all thirteen Lake County officials tried,
-- while the same batch returned 14 of 19 for Allen County and 9 of 9 for Fort Wayne minutes
-- earlier -- so it is coverage, not method. The county publishes no tenure: all seven district
-- pages carry a name, a title and a phone number, and nothing else. CC_0095 wrote the county's
-- twelve the same way. Inventing a January would be arithmetic on an election year, not a source.
--
-- 🔴 RONALD G. BREWER SR. MUST HOLD EXACTLY ONE OFFICE, AND THE GATE ASSERTS IT.
-- He is the man who left Gary's at-large council seat; IN-4's change-check found that vacancy but
-- not where he went. He went here. This slice has now seen TWO people move between jurisdictions
-- mid-term -- Mark Spencer (Gary at-large -> Senate District 3) and Brewer -- and
-- `office_terms_no_overlap` forbids two people on one office but CANNOT see one person on two.
-- ⚠ Measured 2026-09-11: no Brewer row exists at all, so this seats a new person rather than
-- reusing one. The assertion is kept anyway, because it is cheap and because a later reuse of
-- this person row is exactly when it would start mattering.
--
-- ⚠ CHARLIE BROWN (Council D3) AND MICHAEL A. BROWN (Clerk, CC_0095) ARE DIFFERENT PEOPLE.
-- ⚠ RANDY NIEMEYER (Council D7) AND RICK NIEMEYER (Indiana Senate, `indiana_discovery`) ARE
--   DIFFERENT PEOPLE. Two of four Georgia roster hits were a Colorado senator and a Utah
--   treasurer; a shared surname in the same county is not a match.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int; v_band int; v_terms int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051' AND o.title LIKE 'Council Member, District%';
  IF v_off <> 7 THEN RAISE EXCEPTION 'IN-9 occupancy pre-flight: % district offices on X0051, expected 7 (run CC_0099 first)', v_off; END IF;

  -- The band must be free, OR already hold exactly our seven -- this migration is idempotent and
  -- gets re-run as a check. 🔴 An external_id collision seats the WRONG person silently, so the
  -- re-run case is verified by NAME, not just by count.
  SELECT count(*) INTO v_band FROM essentials.politicians
   WHERE external_id BETWEEN -1332211 AND -1332205;
  IF v_band NOT IN (0, 7) THEN
    RAISE EXCEPTION 'IN-9 occupancy pre-flight: % politician(s) occupy the band -1332211..-1332205, expected 0 or exactly our 7', v_band;
  END IF;
  IF v_band = 7 THEN
    PERFORM 1 FROM essentials.politicians
     WHERE external_id BETWEEN -1332211 AND -1332205
       AND full_name NOT IN ('David Hamm','Ronald G. Brewer Sr.','Charlie Brown','Pete Lindemulder',
                             'Christine Cid','Ted Bilski','Randy Niemeyer');
    IF FOUND THEN
      RAISE EXCEPTION 'IN-9 occupancy pre-flight: the band -1332211..-1332205 holds someone who is not one of the seven Lake County Council members -- an external_id collision would seat the wrong person';
    END IF;
  END IF;

  -- CC_0099 leaves the seven offices unseated. Anything already there was not written by this pair.
  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051';
  IF v_terms NOT IN (0, 7) THEN
    RAISE EXCEPTION 'IN-9 occupancy pre-flight: % term(s) already on the X0051 offices, expected 0 or exactly our 7', v_terms;
  END IF;
END $$;

-- ─── 1. Seven people ─────────────────────────────────────────────────────────
-- 🔴 party is left NULL deliberately. Party is antipartisan here: it lives on
-- races.primary_party -- which ballot a voter requests -- and never on a person.

CREATE TEMP TABLE lake_c_people(
  external_id bigint, full_name text, first_name text, last_name text, district text) ON COMMIT DROP;
INSERT INTO lake_c_people VALUES
  (-1332205, 'David Hamm',           'David',     'Hamm',        '1'),
  (-1332206, 'Ronald G. Brewer Sr.', 'Ronald',    'Brewer',      '2'),
  (-1332207, 'Charlie Brown',        'Charlie',   'Brown',       '3'),
  (-1332208, 'Pete Lindemulder',     'Pete',      'Lindemulder', '4'),
  (-1332209, 'Christine Cid',        'Christine', 'Cid',         '5'),
  (-1332210, 'Ted Bilski',           'Ted',       'Bilski',      '6'),
  (-1332211, 'Randy Niemeyer',       'Randy',     'Niemeyer',    '7');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, true,
       'Lake County Council, lakecountyin.gov/departments/council and the seven per-district pages council-1stdist..council-7thdist, read 2026-09-11 (CC_0100, IN-9)'
FROM lake_c_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Seven terms ──────────────────────────────────────────────────────────
-- These offices were created by CC_0099 and have never been held, so there is no predecessor to
-- close and `essentials.seat_officeholder`'s two-step has nothing to do. The pre-flight asserts
-- the offices carry 0 or exactly our 7 terms, which is the condition that makes a direct insert
-- equivalent. 🔴 Any LATER seating of these offices must use the helper.

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown',
       'Lake County IN-9 (CC_0100): the county publishes no tenure for its council members; ' ||
       'Ballotpedia returns 404 for all thirteen Lake County officials tried (IN-6), while the ' ||
       'same batch returned 14 of 19 for Allen County -- coverage, not method. No date invented.'
FROM lake_c_people n
JOIN essentials.districts d
  ON d.geo_id = 'lake-county-in-council-district-' || n.district
 AND d.district_type = 'COUNTY' AND lower(d.state) = 'in' AND d.mtfcc = 'X0051'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = 'Council Member, District ' || n.district
JOIN essentials.politicians p ON p.external_id = n.external_id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'Lake County, Indiana, US'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
-- 🔴 SCOPED TO X0051 AND THE COUNCIL CHAMBER, never to the whole Lake County government:
-- GA-5's gates counted a government and broke when a later wave added offices to it.

DO $$
DECLARE v_people int; v_seated int; v_unknown int; v_dated int; v_ended int;
        v_brewer int; v_dupe int; v_council int; v_vacant int; v_distinct int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332211 AND -1332205;
  IF v_people <> 7 THEN RAISE EXCEPTION 'IN-9 occupancy: % people in the band, expected 7', v_people; END IF;

  -- 🔴 office_current_holder LEFT JOINs from offices, so a vacancy is a NULL politician_id, not an
  -- absent row. count(*) would pass vacuously; count the politician.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = 'X0051';
  IF v_seated <> 7 THEN
    RAISE EXCEPTION 'IN-9 occupancy: % of 7 Lake council district seats filled', v_seated;
  END IF;

  -- Seven DISTINCT people on seven seats.
  SELECT count(DISTINCT och.politician_id) INTO v_distinct
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = 'X0051';
  IF v_distinct <> 7 THEN RAISE EXCEPTION 'IN-9 occupancy: % distinct people across 7 seats', v_distinct; END IF;

  -- 🔴 Ronald G. Brewer Sr. must hold EXACTLY ONE office anywhere. He left Gary's at-large seat;
  -- two live seats for one person is the Mark Spencer failure this slice already caught once.
  SELECT count(*) INTO v_brewer
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.full_name = 'Ronald G. Brewer Sr.';
  IF v_brewer <> 1 THEN
    RAISE EXCEPTION 'IN-9 occupancy: Ronald G. Brewer Sr. holds % offices, expected exactly 1 (Lake County Council District 2). He left Gary''s at-large seat.', v_brewer;
  END IF;

  -- Nobody holds two Lake County Council seats.
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council'
     GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-9 occupancy: % person(s) hold more than one Lake council seat', v_dupe; END IF;

  -- The council is now completely seated: 7 of 7.
  SELECT count(och.politician_id) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Lake County, Indiana, US' AND c.name = 'Lake County Council';
  IF v_council <> 7 THEN RAISE EXCEPTION 'IN-9 occupancy: Lake County Council seats % of 7', v_council; END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051' AND o.is_vacant;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'IN-9 occupancy: % X0051 office(s) flagged vacant', v_vacant; END IF;

  -- The precision tuple, asserted so a later "tidy" that invents dates fails loudly.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_unknown, v_dated, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0051';
  IF v_unknown <> 7 THEN RAISE EXCEPTION 'IN-9 occupancy: % unknown-precision terms, expected 7', v_unknown; END IF;
  IF v_dated <> 0 THEN RAISE EXCEPTION 'IN-9 occupancy: % term(s) carry a start date nobody published', v_dated; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'IN-9 occupancy: % term(s) already closed', v_ended; END IF;

  RAISE NOTICE 'IN-9 occupancy OK: 7 district members seated, Lake County Council 7 of 7, Brewer on exactly one seat, 7 unknown-precision open terms';
END $$;

COMMIT;

-- CC_0097_gary_council_districts_people.sql
-- Knight Foundation program, wave IN-8 (occupancy half). Slot RESERVED from the allocator.
--
-- Seats the six Gary district councilmembers created by CC_0096. 6 people, 6 terms, 0 vacancies.
-- Apply immediately after CC_0096: between the two, six offices exist with no term, which is the
-- state `essentials.offices_missing_terms` counts.
--
--   D1  Lori Latham             D4  Marian Ivey
--   D2  Dwayne Halliburton      D5  Linda Barnes-Caldwell   (Council President)
--   D3  Mary Brown              D6  Dwight A Williams
--
-- SOURCE: garycommoncouncil.gov/council-members/ -- the Council's OWN page, which pairs each
-- member with their district in its own text. Re-read live 2026-09-11 as the change-check: all
-- six still named, all six still on the same district, and no unexplained name on the page.
-- ⚠ garycommoncouncil.ORG also exists and is stale; the .gov is current (IN-4).
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 FIVE OF THE SIX TERMS ARE `unknown`, AND THAT IS THE HONEST ANSWER, NOT A GAP.
-- IN-4 established that Ballotpedia returns HTTP 404 for ten of Gary's twelve officials -- Fort
-- Wayne is a top-100 city and Gary is not -- and that the Council's own member pages are prose
-- biographies carrying no tenure data. No source covering Gary publishes a first-taking-office
-- date for these five. Georgia's 235 legislative terms are open-ended `unknown` for the same
-- reason. Inventing a January would be arithmetic on an election year, not a source.
--
-- ⚠ THE ONE DATED ROW IS DATED FROM THE CAUCUS, NOT THE SWEARING-IN, so it is `month`.
-- Marian Ivey held an AT-LARGE seat (succeeding Ronald G Brewer Sr) and moved to District 4 when
-- Tai Adkins became Calumet Township trustee; she won the District 4 caucus on 2025-02-19 on the
-- county chairman's tie-break. The swearing-in is a different event, days later, and is not
-- published -- so the day is not claimed. This is the same rule CC_0093 applied to Kenneth
-- Whisenton and Myles Tolliver.
--
-- 🔴 IVEY'S AT-LARGE SEAT IS ALREADY HELD BY SOMEONE ELSE, AND THAT IS CORRECT.
-- Myles Tolliver took it at the 2025-03-21 caucus and CC_0093 seated him there. So Ivey must end
-- up holding EXACTLY ONE Gary office -- District 4 -- and the gate asserts it. Seating her here
-- without that check is how the same person ends up on two live seats, which this slice already
-- came within one wave of doing with Mark Spencer.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int; v_band int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_off <> 6 THEN RAISE EXCEPTION 'IN-8 occupancy pre-flight: % district offices, expected 6 (run CC_0096 first)', v_off; END IF;

  -- The band must be free, OR already hold exactly our six -- this migration is idempotent and
  -- gets re-run as a check. ⚠ The first version asserted `= 0` and therefore FAILED on its own
  -- second run, which is not the same thing as a collision. An external_id collision seats the
  -- WRONG person silently, so the re-run case is verified by NAME, not just by count.
  SELECT count(*) INTO v_band FROM essentials.politicians
   WHERE external_id BETWEEN -1332204 AND -1332199;
  IF v_band NOT IN (0, 6) THEN
    RAISE EXCEPTION 'IN-8 occupancy pre-flight: % politician(s) occupy the band -1332204..-1332199, expected 0 or exactly our 6', v_band;
  END IF;
  IF v_band = 6 THEN
    PERFORM 1 FROM essentials.politicians
     WHERE external_id BETWEEN -1332204 AND -1332199
       AND full_name NOT IN ('Lori Latham','Dwayne Halliburton','Mary Brown','Marian Ivey',
                             'Linda Barnes-Caldwell','Dwight A Williams');
    IF FOUND THEN
      RAISE EXCEPTION 'IN-8 occupancy pre-flight: the band -1332204..-1332199 holds someone who is not one of the six Gary district councilmembers -- an external_id collision would seat the wrong person';
    END IF;
  END IF;
END $$;

-- ─── 1. Six people ───────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_d_people(
  external_id bigint, full_name text, first_name text, last_name text, district text) ON COMMIT DROP;
INSERT INTO gary_d_people VALUES
  (-1332199, 'Lori Latham',           'Lori',   'Latham',         '1'),
  (-1332200, 'Dwayne Halliburton',    'Dwayne', 'Halliburton',    '2'),
  (-1332201, 'Mary Brown',            'Mary',   'Brown',          '3'),
  (-1332202, 'Marian Ivey',           'Marian', 'Ivey',           '4'),
  (-1332203, 'Linda Barnes-Caldwell', 'Linda',  'Barnes-Caldwell','5'),
  (-1332204, 'Dwight A Williams',     'Dwight', 'Williams',       '6');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, true,
       'gary_in8_council_districts'
FROM gary_d_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Six terms ────────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_d_terms(
  external_id bigint, district text,
  term_start date, start_precision text, date_source text) ON COMMIT DROP;
INSERT INTO gary_d_terms VALUES
  (-1332199, '1', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332200, '2', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332201, '3', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s'),
  (-1332202, '4', DATE '2025-02-01', 'month',
   'Won the District 4 caucus 2025-02-19 on the county chairman tie-break, moving from an at-large seat after Tai Adkins became Calumet Township trustee; swearing-in day not published'),
  (-1332203, '5', NULL, 'unknown',
   'Council President; no source covering Gary publishes a tenure start'),
  (-1332204, '6', NULL, 'unknown',
   'No source covering Gary publishes a first-taking-office date; Ballotpedia 404s');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'unknown',
       'Gary IN-8 (CC_0097): ' || t.date_source
FROM gary_d_terms t
JOIN essentials.districts d
  ON d.geo_id = 'gary-in-council-district-' || t.district
 AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = 'Council Member, District ' || t.district
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Gary, Indiana, US'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_people int; v_seated int; v_month int; v_unknown int; v_ended int;
        v_ivey int; v_dupe int; v_council int; v_vacant int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -1332204 AND -1332199;
  IF v_people <> 6 THEN RAISE EXCEPTION 'IN-8 occupancy: % people in the band, expected 6', v_people; END IF;

  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_seated <> 6 THEN
    RAISE EXCEPTION 'IN-8 occupancy: % district seats filled, expected 6 (office_current_holder LEFT JOINs, so count the politician, not the row)', v_seated;
  END IF;

  -- 🔴 Marian Ivey must hold EXACTLY ONE Gary office. Her old at-large seat belongs to Myles
  -- Tolliver since the 2025-03-21 caucus. Two live seats for one person is the Mark Spencer
  -- failure this slice already caught once.
  SELECT count(*) INTO v_ivey
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND p.full_name = 'Marian Ivey';
  IF v_ivey <> 1 THEN
    RAISE EXCEPTION 'IN-8 occupancy: Marian Ivey holds % Gary offices, expected exactly 1 (District 4). Her at-large seat is Myles Tolliver''s.', v_ivey;
  END IF;

  -- Nobody holds two Gary council seats.
  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council'
     GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % person(s) hold more than one Gary council seat', v_dupe; END IF;

  -- The council is now completely seated: 9 of 9.
  SELECT count(och.politician_id) INTO v_council
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Gary, Indiana, US' AND c.name = 'Gary Common Council';
  IF v_council <> 9 THEN RAISE EXCEPTION 'IN-8 occupancy: Gary Common Council seats % of 9', v_council; END IF;

  SELECT count(*) INTO v_vacant FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%' AND o.is_vacant;
  IF v_vacant <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % district office(s) flagged vacant', v_vacant; END IF;

  -- The precision tuple, asserted so a later "tidy" that invents dates fails loudly.
  SELECT count(*) FILTER (WHERE ot.start_precision = 'month'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_month, v_unknown, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Gary, Indiana, US' AND o.title LIKE 'Council Member, District%';
  IF v_month <> 1 OR v_unknown <> 5 THEN
    RAISE EXCEPTION 'IN-8 occupancy: precision is % month + % unknown, expected 1 + 5', v_month, v_unknown;
  END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'IN-8 occupancy: % district term(s) already closed', v_ended; END IF;

  RAISE NOTICE 'IN-8 occupancy OK: 6 district members seated, Gary Common Council 9 of 9, Ivey on exactly one seat, 1 month + 5 unknown';
END $$;

COMMIT;

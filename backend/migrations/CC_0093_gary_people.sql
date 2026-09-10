-- CC_0093_gary_people.sql
-- Knight Foundation program, wave IN-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0092.
--
-- Seats the SIX citywide Gary offices: 6 people, 6 terms, 0 vacancies.
-- external_id band -1332162 .. -1332167, measured free 2026-09-10.
--
-- 🔴🔴 FOUR OF GARY'S TWELVE SEATS HAVE CHANGED HANDS SINCE THE 2023 ELECTION, AND ONE OF THE
-- DEPARTURES IS A MAN THIS SLICE ALREADY SEATED SOMEWHERE ELSE.
--
--   At Large  Mark Spencer won INDIANA SENATE DISTRICT 3 and was sworn in 2024-11-19, vacating
--             his Gary at-large seat. He is seated in SD-3 by CC_0089, three days ago in wave
--             IN-2. A wave that read Gary's 2023 certified results as current would have put the
--             SAME MAN on TWO live offices at once.
--   At Large  Kenneth Whisenton won the replacement caucus, reported 2024-12-04, 20 votes to 19.
--   District 4 Tai Adkins left to become Calumet Township trustee; Marian Ivey, then at-large,
--             won the D4 caucus 2025-02-19 on the county chairman's tie-breaking vote.
--   At Large  Myles Tolliver won the caucus for Ivey's vacated at-large seat on Fri 2025-03-21.
--
-- 🔴 A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT. The 2023 Lake County results are
-- used here ONLY to enumerate what Gary elects. Who holds each seat comes from the Council's own
-- current roster.
--
-- 🔴 THREE OF SIX TERMS ARE 'unknown', AND THAT IS THE HONEST ANSWER RATHER THAN A GAP.
-- Gary's council publishes prose biographies with no tenure data; Ballotpedia does not cover Gary
-- (ten of twelve officials are HTTP 404, where Fort Wayne -- a top-100 city -- has a tenure field
-- for every member); and the 2023 result gives a TERM, which IN-3 established is not an occupancy
-- start for anyone re-elected. GA-2 wrote all 235 Georgia legislative terms 'unknown' for exactly
-- this reason. No date is invented.
--
-- ⚠ THE TWO 'month' ROWS ARE DATED FROM THE CAUCUS, NOT THE SWEARING-IN. A caucus win and taking
-- office are different events, usually days apart, and the swearing-in day is not published for
-- either man -- so the month is asserted and the day is not.
--
-- 🔴 NO term_end IS WRITTEN. 🔴 PARTY IS NOT WRITTEN -- it lives on races.primary_party.
-- 🔴 alternate_names IS NOT NULL DEFAULT '{}' -- an empty array is emitted, never NULL.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).

BEGIN;

-- ─── Six people ──────────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO gary_people(external_id, full_name, first_name, last_name) VALUES
  (-1332162, 'Eddie Melton',      'Eddie',    'Melton'),
  (-1332163, 'Suzette Raggs',     'Suzette',  'Raggs'),
  (-1332164, 'Deidre L Monroe',   'Deidre',   'Monroe'),
  (-1332165, 'Darren Washington', 'Darren',   'Washington'),
  (-1332166, 'Kenneth Whisenton', 'Kenneth',  'Whisenton'),
  (-1332167, 'Myles Tolliver',    'Myles',    'Tolliver');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'Gary Common Council roster, garycommoncouncil.gov/council-members/, with offices enumerated from the Lake County certified 2023 municipal results, read 2026-09-10 (CC_0093, IN-4)',
       '{}'
FROM gary_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── Six terms ───────────────────────────────────────────────────────────────

CREATE TEMP TABLE gary_terms(
  external_id bigint, title text, ordinal int,
  term_start date, start_precision text, date_source text) ON COMMIT DROP;
INSERT INTO gary_terms VALUES
  (-1332162, 'Mayor', NULL, DATE '2024-01-01', 'day',
   'Assumed office 2024-01-01, his first term as mayor, having previously held Indiana Senate District 3'),
  (-1332163, 'City Clerk', NULL, NULL, 'unknown',
   'Elected 2023; no first-taking-office date is published and she may be a returning incumbent'),
  (-1332164, 'Judge of the City Court', NULL, NULL, 'unknown',
   'Elected 2023 unopposed; no first-taking-office date is published'),
  (-1332165, 'Council Member, At Large', 1, NULL, 'unknown',
   'Long-serving at-large member; no source covering Gary publishes a tenure start'),
  (-1332166, 'Council Member, At Large', 2, DATE '2024-12-01', 'month',
   'Caucus victory reported 2024-12-04, succeeding Mark Spencer who left for Indiana Senate District 3; swearing-in day not published'),
  (-1332167, 'Council Member, At Large', 3, DATE '2025-03-01', 'month',
   'Caucus held Friday 2025-03-21 for the seat Marian Ivey vacated on moving to District 4; swearing-in day not published');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, 'unknown',
       'Gary IN-4 (CC_0093): ' || t.date_source
FROM gary_terms t
JOIN essentials.districts d ON d.geo_id = '1827000' AND d.district_type = 'LOCAL' AND lower(d.state) = 'in'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.title = t.title
 AND (t.ordinal IS NULL OR o.description LIKE 'Internal ordinal ' || t.ordinal || ' of 3%')
JOIN essentials.politicians p ON p.external_id = t.external_id
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Gary, Indiana, US'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_people int; v_off int; v_seated int; v_day int; v_month int; v_unknown int; v_ended int; v_dupe int; v_spencer int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -1332167 AND -1332162;
  IF v_people <> 6 THEN RAISE EXCEPTION 'IN-4 occupancy: % people in the band, expected 6', v_people; END IF;

  SELECT count(o.id), count(och.politician_id) INTO v_off, v_seated
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE g.name = 'City of Gary, Indiana, US';
  IF v_off <> 6 OR v_seated <> 6 THEN
    RAISE EXCEPTION 'IN-4 occupancy: expected 6 offices all seated, got % offices / % seated', v_off, v_seated;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE g.name = 'City of Gary, Indiana, US' AND o.title = 'Council Member, At Large'
    GROUP BY och.politician_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'IN-4 occupancy: an at-large person holds more than one at-large seat'; END IF;

  SELECT count(*) FILTER (WHERE ot.start_precision='day'),
         count(*) FILTER (WHERE ot.start_precision='month'),
         count(*) FILTER (WHERE ot.start_precision='unknown'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_day, v_month, v_unknown, v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Gary, Indiana, US';
  IF v_day <> 1 OR v_month <> 2 OR v_unknown <> 3 THEN
    RAISE EXCEPTION 'IN-4 occupancy: expected 1 day / 2 month / 3 unknown, got % / % / %', v_day, v_month, v_unknown;
  END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'IN-4 occupancy: % terms carry a term_end; none may', v_ended; END IF;

  -- 🔴 Mark Spencer left Gary's at-large seat for SD-3 and is seated there by CC_0089. He must NOT
  -- appear on a Gary office: that would be the same man on two live seats.
  SELECT count(*) INTO v_spencer
  FROM essentials.office_current_holder och
  JOIN essentials.politicians p ON p.id = och.politician_id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  WHERE g.name = 'City of Gary, Indiana, US'
    AND lower(p.last_name) = 'spencer' AND lower(p.first_name) = 'mark';
  IF v_spencer <> 0 THEN
    RAISE EXCEPTION 'IN-4 occupancy: Mark Spencer holds a Gary office. He left the at-large seat for Indiana Senate District 3 (sworn 2024-11-19) and is seated there by CC_0089.';
  END IF;

  RAISE NOTICE 'IN-4 occupancy OK: 6 people, 6 offices, 6 seated, 1 day + 2 month + 3 unknown, 0 ended, Mark Spencer correctly absent';
END $$;

COMMIT;

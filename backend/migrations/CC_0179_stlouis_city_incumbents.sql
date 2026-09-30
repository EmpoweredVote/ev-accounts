-- CC_0179_stlouis_city_incumbents.sql
-- St. Louis MO deep seed, wave 3 (occupancy half). Slot RESERVED from the allocator.
-- Applied back to back with CC_0178, which creates the government, 6 chambers, 16 districts and
-- 23 offices.
--
-- Seats 22 of the City of St. Louis's 23 elected officials. Creates 22 people, reuses 0.
-- The 23rd — the SHERIFF — is deliberately left unseated; see CC_0178 and the note below.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO DIFFERENT DATING RULES ARE USED HERE, AND EACH ROW SAYS WHICH. This is not sloppiness;
-- the evidence genuinely differs between the Board of Aldermen and the citywide officers.
--
-- (a) THE 14 ALDERMEN CARRY TRUE OCCUPANCY, floored at the map change — the same ruling wave 2
--     used. The Board went from 28 wards to 14 at the April 2023 election, so occupancy of a ward
--     AS CURRENTLY DRAWN cannot begin before the 14-ward board's first day. That day is dated from
--     the Board's OWN record: its 2023-2024 legislative session's first Full Board meeting,
--     2023-04-18 (and 2025-04-15 for the 2025-2026 session). Twelve wards are held by the same
--     person across sessions 199-202; Ward 5 changed at the April 2025 election; Ward 8 changed at
--     a special.
--
-- (b) THE CITYWIDE AND COUNTY-TIER OFFICERS CARRY A MIXTURE, because only some publish a date:
--       · Mayor      — the city's own page STATES it: "Mayor Cara Spencer was sworn in as Mayor of
--                      St. Louis on April 15th, 2025." Day precision, true occupancy.
--       · Treasurer  — the Treasurer's own page STATES it: "Treasurer Adam Layne was appointed in
--                      April of 2021 as the successor for Mayor, Tishaura O. Jones". Month
--                      precision, how_started 'appointed', true occupancy.
--       · the other six — NO city page states a take-office date (checked, all of them). They
--                      carry the start of their CURRENT TERM from the certified result that began
--                      it, at MONTH precision, and the source string says so. For Gabriel Gore an
--                      earlier appointment as Circuit Attorney is known but is not dated by any
--                      document read here, so his row understates his occupancy and admits it.
--
-- 🔴 WHY THE SIX WERE NOT CHASED FURTHER. Gregory F.X. Daly, Mavis Thompson and Michael Butler are
-- long-serving; their occupancy predates the earliest certified summary read here. Chasing it runs
-- into 2012-era multi-column result PDFs whose text extraction is unreliable — the exact shape that
-- cost the Nashville wave nine seats to a fixed-column parser. A month-precision current-term start
-- that says what it is beats a deep date that might be wrong.
--   ⚠ AND PRESENCE IN A RESULTS PDF IS NOT EVIDENCE OF WINNING. Measured: Donna Baringer appears in
--   FOUR November ballots as a STATE REPRESENTATIVE, and Cara Spencer appears in April 2021 because
--   she LOST the mayoral race. A name sweep across cycles is a lead, never a term start.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE SHERIFF IS NOT SEATED AND IS NOT FLAGGED VACANT. Ruled 2026-09-28 (Cantrell). Alfred
-- Montgomery won it in Nov 2024 with 85.90%; the Missouri Attorney General's own statement says a
-- judge ordered him "immediately and completely removed"; that order was later halted; a new-trial
-- motion was denied in April 2026; an interim runs the office; and the city publishes no sheriff
-- anywhere. Any occupancy claim would be a claim about contested facts concerning a named person.
-- The seat therefore shows as unknown occupancy, and essentials.offices_missing_terms unflagged
-- moves 238 -> 239. That is this wave's doing and is NOT drift.
--
-- 🟢 NO NAME COLLIDES. All 22 were swept with the duplicate-name guard's OWN predicate
-- (lower(btrim(first_name)) AND lower(btrim(last_name)), active rows only) — 0 hits. That zero was
-- controlled: adding 'Jeff Farnan' to the same query returns his row (external_id -2790202, MO
-- House District 1), so the sweep is not blind. No guard is lifted anywhere in this file.
--   ⚠ Two people here previously sat in the Missouri House and are NOT the wave-2 rows: Rasheen
--   Aldridge held HD-78 and Donna M.C. Baringer held HD-82 in the 102nd General Assembly. Wave 2
--   seated only CURRENT holders, so neither is in production and both are created fresh here.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY INSERT. It defaults to false since CA_0188, and a
-- seated person inserted without it is HIDDEN from address search.
--
-- 🔴 PARTY IS NOT WRITTEN. Party lives on races.primary_party, never on a person.
--
-- 🟢 THE RESERVED external_id BAND IS -2790422 .. -2790401 (22 ids), MEASURED EMPTY 2026-09-28.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The 22 people ─────────────────────────────────────────────────────────

CREATE TEMP TABLE stl_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO stl_people(external_id, full_name, first_name, last_name) VALUES
  (-2790401::bigint, 'Anne Schweitzer',       'Anne',    'Schweitzer'),
  (-2790402::bigint, 'Thomas Oldenburg',      'Thomas',  'Oldenburg'),
  (-2790403::bigint, 'Shane Cohn',            'Shane',   'Cohn'),
  (-2790404::bigint, 'Bret Narayan',          'Bret',    'Narayan'),
  (-2790405::bigint, 'Matt Devoti',           'Matt',    'Devoti'),
  (-2790406::bigint, 'Daniela Velazquez',     'Daniela', 'Velazquez'),
  (-2790407::bigint, 'Alisha Sonnier',        'Alisha',  'Sonnier'),
  (-2790408::bigint, 'Jami Cox Antwi',        'Jami',    'Antwi'),
  (-2790409::bigint, 'Michael Browning',      'Michael', 'Browning'),
  (-2790410::bigint, 'Shameem Clark Hubbard', 'Shameem', 'Hubbard'),
  (-2790411::bigint, 'Laura Keys',            'Laura',   'Keys'),
  (-2790412::bigint, 'Sharon Tyus',           'Sharon',  'Tyus'),
  (-2790413::bigint, 'Pamela Boyd',           'Pamela',  'Boyd'),
  (-2790414::bigint, 'Rasheen Aldridge',      'Rasheen', 'Aldridge'),
  (-2790415::bigint, 'Megan Green',           'Megan',   'Green'),
  (-2790416::bigint, 'Cara Spencer',          'Cara',    'Spencer'),
  (-2790417::bigint, 'Donna M.C. Baringer',   'Donna',   'Baringer'),
  (-2790418::bigint, 'Gabriel Gore',          'Gabriel', 'Gore'),
  (-2790419::bigint, 'Adam L. Layne',         'Adam',    'Layne'),
  (-2790420::bigint, 'Gregory F.X. Daly',     'Gregory', 'Daly'),
  (-2790421::bigint, 'Mavis Thompson',        'Mavis',   'Thompson'),
  (-2790422::bigint, 'Michael Butler',        'Michael', 'Butler');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
  'City of St. Louis elected officials, read 2026-09-28. The OFFICE LIST comes from certified ' ||
  'Board of Election Commissioners summaries (Nov 2020, Apr 2021, Nov 2022, Apr 2023, Nov 2024, ' ||
  'Apr 2025, Apr 2026, Aug 2026), NOT from stlouis-mo.gov/government/elected-officials.cfm, which ' ||
  'omits the Sheriff entirely and names 22 of the 23 elected officials. Aldermanic occupancy is ' ||
  'floored at the first day of the 14-ward Board of Aldermen, 2023-04-18, dated from the Board''s ' ||
  'own 2023-2024 legislative-session meeting record (the Board went from 28 wards to 14 at the ' ||
  'April 2023 election). Citywide dates: the Mayor''s own page states 2025-04-15; the Treasurer''s ' ||
  'own page states an April 2021 appointment; the remaining six carry their CURRENT TERM start at ' ||
  'month precision because no city page states a take-office date. (MO-3) (CC_0179, MO-3)',
  true, true
FROM stl_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 22 terms ──────────────────────────────────────────────────────────
-- Keyed on (geo_id, district_type, title). NEVER a label: `St. Louis County` exists in production
-- in MINNESOTA with the same label and the same seat count as Missouri's.

CREATE TEMP TABLE stl_terms(
  geo_id text, district_type text, title text, external_id bigint,
  term_start date, start_precision text, how_started text, basis text
) ON COMMIT DROP;

INSERT INTO stl_terms VALUES
  -- (a) the 14 aldermen — TRUE OCCUPANCY, floored at the 14-ward board's first day
  ('stlouis-mo-ward-1',  'LOCAL', 'Alderman', -2790401, '2023-04-18', 'day',   'elected', 'held Ward 1 across sessions 2023-2024 .. 2026-2027; 14-ward board first met 2023-04-18'),
  ('stlouis-mo-ward-2',  'LOCAL', 'Alderman', -2790402, '2023-04-18', 'day',   'elected', 'held Ward 2 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-3',  'LOCAL', 'Alderman', -2790403, '2023-04-18', 'day',   'elected', 'held Ward 3 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-4',  'LOCAL', 'Alderman', -2790404, '2023-04-18', 'day',   'elected', 'held Ward 4 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-5',  'LOCAL', 'Alderman', -2790405, '2025-04-15', 'day',   'elected', 'ARRIVED 2025: the Apr 2025 ballot carried the 7 odd wards; Ward 5 changed from Vollmer. 2025-2026 session first met 2025-04-15'),
  ('stlouis-mo-ward-6',  'LOCAL', 'Alderman', -2790406, '2023-04-18', 'day',   'elected', 'held Ward 6 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-7',  'LOCAL', 'Alderman', -2790407, '2023-04-18', 'day',   'elected', 'held Ward 7 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-8',  'LOCAL', 'Alderman', -2790408, '2025-07-01', 'month', 'elected', 'ARRIVED 2025: WON THE WARD 8 SPECIAL of 2025-07-01 for the UNEXPIRED TERM with 1,072 votes / 54.95%, after Cara Spencer left Ward 8 for the Mayor''s office. The oath date is not published, so month precision'),
  ('stlouis-mo-ward-9',  'LOCAL', 'Alderman', -2790409, '2023-04-18', 'day',   'elected', 'held Ward 9 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-10', 'LOCAL', 'Alderman', -2790410, '2023-04-18', 'day',   'elected', 'held Ward 10 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-11', 'LOCAL', 'Alderman', -2790411, '2023-04-18', 'day',   'elected', 'held Ward 11 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-12', 'LOCAL', 'Alderman', -2790412, '2023-04-18', 'day',   'elected', 'held Ward 12 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-13', 'LOCAL', 'Alderman', -2790413, '2023-04-18', 'day',   'elected', 'held Ward 13 across sessions 2023-2024 .. 2026-2027'),
  ('stlouis-mo-ward-14', 'LOCAL', 'Alderman', -2790414, '2023-04-18', 'day',   'elected', 'held Ward 14 across sessions 2023-2024 .. 2026-2027'),
  -- (b) the citywide seats
  ('2965000', 'LOCAL',      'President of the Board of Aldermen', -2790415, '2022-11-01', 'month', 'elected',   'won the PRES OF BOA special on the Nov 2022 ballot after Lewis Reed resigned, then the full term in Apr 2023; the oath date is not published, so month precision'),
  ('2965000', 'LOCAL_EXEC', 'Mayor',                             -2790416, '2025-04-15', 'day',   'elected',   'the Mayor''s own city page STATES it: "sworn in as Mayor of St. Louis on April 15th, 2025"'),
  ('2965000', 'LOCAL_EXEC', 'Comptroller',                       -2790417, '2025-04-01', 'month', 'elected',   'Apr 2025 certified result; no city page states a take-office date, so month precision'),
  ('2965000', 'LOCAL_EXEC', 'Circuit Attorney',                  -2790418, '2025-01-01', 'month', 'elected',   'CURRENT TERM start from the Nov 2024 certified result. UNDERSTATES his occupancy: he was appointed Circuit Attorney earlier, and no document read here dates that appointment'),
  ('2965000', 'LOCAL_EXEC', 'Treasurer',                         -2790419, '2021-04-01', 'month', 'appointed', 'the Treasurer''s own city page STATES it: "appointed in April of 2021 as the successor for Mayor, Tishaura O. Jones"; re-elected Nov 2024'),
  ('2965000', 'LOCAL_EXEC', 'Collector of Revenue',              -2790420, '2023-01-01', 'month', 'elected',   'CURRENT TERM start from the Nov 2022 certified result (COL OF REVENUE). Long-serving; earlier terms not chased'),
  ('2965000', 'LOCAL_EXEC', 'License Collector',                 -2790421, '2023-01-01', 'month', 'elected',   'CURRENT TERM start from the Nov 2022 certified result. Long-serving; earlier terms not chased'),
  ('2965000', 'LOCAL_EXEC', 'Recorder of Deeds',                 -2790422, '2023-01-01', 'month', 'elected',   'CURRENT TERM start from the Nov 2022 certified result (REC OF DEEDS)');

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       'City of St. Louis, MO-3 (CC_0179). ' || t.basis
FROM stl_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mo'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_sheriff_terms int; v_sheriff_vac int;
  v_noninc int; v_ward int; v_missing int; v_dupe int; v_baddate int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2790422 AND -2790401;
  IF v_people <> 22 THEN RAISE EXCEPTION 'MO-3 occupancy gate: expected 22 people in the reserved band, got %', v_people; END IF;

  SELECT count(*) INTO v_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of St. Louis, Missouri, US';
  IF v_terms <> 22 THEN RAISE EXCEPTION 'MO-3 occupancy gate: expected 22 St. Louis city terms, found %', v_terms; END IF;

  -- 🔴 count och.politician_id, NOT *: office_current_holder LEFT JOINs from offices, so a seat
  -- with no holder is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of St. Louis, Missouri, US';
  IF v_seated <> 22 THEN RAISE EXCEPTION 'MO-3 occupancy gate: expected 22 seated, found %', v_seated; END IF;

  -- 🔴🔴 The Sheriff must carry NO term and NO vacancy flag. Both directions asserted, because
  -- either one alone would let the other slip through.
  SELECT count(ot.id), count(*) FILTER (WHERE o.is_vacant IS true)
    INTO v_sheriff_terms, v_sheriff_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.name = 'City of St. Louis, Missouri, US' AND o.title = 'Sheriff';
  IF v_sheriff_terms <> 0 THEN
    RAISE EXCEPTION 'MO-3 occupancy gate: the Sheriff carries % term row(s) — the seat is contested and must assert no occupancy', v_sheriff_terms;
  END IF;
  IF v_sheriff_vac <> 0 THEN
    RAISE EXCEPTION 'MO-3 occupancy gate: the Sheriff is flagged is_vacant — a vacancy is a claim, and the removal order was halted';
  END IF;

  SELECT count(*) INTO v_noninc
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE g.name = 'City of St. Louis, Missouri, US'
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN RAISE EXCEPTION 'MO-3 occupancy gate: % seated official(s) are not is_incumbent/is_active — they would be hidden from address search', v_noninc; END IF;

  -- The 14 wards: 12 at the board's first day, 1 in Apr 2025, 1 at the Jul 2025 special.
  SELECT count(*) INTO v_ward
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0075' AND ot.term_start = DATE '2023-04-18';
  IF v_ward <> 12 THEN RAISE EXCEPTION 'MO-3 occupancy gate: expected 12 aldermen at 2023-04-18, found %', v_ward; END IF;

  -- No term may predate the 14-ward board EXCEPT a citywide seat, whose district never changed.
  SELECT count(*) INTO v_baddate
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = 'X0075' AND ot.term_start < DATE '2023-04-18';
  IF v_baddate <> 0 THEN
    RAISE EXCEPTION 'MO-3 occupancy gate: % ward term(s) start before 2023-04-18 — a ward as currently drawn did not exist then', v_baddate;
  END IF;

  -- 🔴 Every seat except the Sheriff must carry a term, or it is invisible and nothing errors.
  SELECT count(*) INTO v_missing
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of St. Louis, Missouri, US'
     AND o.title <> 'Sheriff'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);
  IF v_missing <> 0 THEN RAISE EXCEPTION 'MO-3 occupancy gate: % non-Sheriff seat(s) carry no term row', v_missing; END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of St. Louis, Missouri, US'
     GROUP BY 1 HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'MO-3 occupancy gate: % person(s) hold more than one St. Louis city seat', v_dupe; END IF;

  RAISE NOTICE 'MO-3 occupancy gate PASSED: 22 people, 22 terms, 22 seated, 12 aldermen at 2023-04-18 and none earlier, the Sheriff carries no term and no vacancy flag, 0 double-seated.';
END $$;

COMMIT;

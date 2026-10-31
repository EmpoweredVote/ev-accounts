-- CC_0298: write vacant_since on the sixteen flagged offices whose vacancy date can be cited.
--
-- WHAT A VOTER SEES TODAY. PR #1178 (CC_0296's sibling) stopped /api/essentials/address-search
-- returning a vacant seat as a row that looked like a person with no name. Every such row now
-- carries `seat_status = 'vacant'` and the seat's own title, so the card can say "this seat is
-- empty". That was the CODE half. This is the DATA half: of the 65 offices flagged `is_vacant`,
-- 41 carry no `vacant_since`, so the card can only say "vacant, date unknown".
--
-- 🔴 "FLAGGED AND UNDATED" IS NOT ONE DEFECT. IT IS FOUR, AND ONLY ONE OF THEM WANTS A DATE.
-- Measuring all 41 against their own chambers split them cleanly, and most of them are not
-- vacancies at all:
--
--   16  REAL VACANCIES, DATE CITED       <- this migration, and only this
--    1  REAL VACANCY, DATE NOT PUBLISHED  Richland County SC Soil and Water Conservation
--                                         District Commissioner. Already correct: its
--                                         `description` says the SC DNR record lists the seat
--                                         "Vacant" and that the date is not published, which is
--                                         exactly what CLAUDE.md asks for. Left untouched.
--    1  NOT VACANT, A HOLDER EXISTS       City of Cornelius OR, Councilor. The city's own roster
--                                         lists four councillors; we hold three. Seating a person
--                                         is a different act from dating a vacancy, so it is not
--                                         done here.
--   23  NOT DEMONSTRABLY VACANT           20 of them are the same defect wearing a vacancy's
--                                         clothes: eight California boards and councils carry
--                                         BOTH legacy At-Large office rows (seated) AND newer
--                                         by-district rows (empty), and in every one of the eight
--                                         the At-Large rows already account for the whole body.
--                                         Montebello Unified seats five people on five At-Large
--                                         rows and then shows three empty Trustee Area rows for
--                                         the same five-member board. Those are duplicates, not
--                                         vacancies, and a date would make the false claim
--                                         durable. The other 3 (Three Valleys MWD Division 3,
--                                         Torrance Unified Trustee Area D, Caledonia WI Village
--                                         Trustee Seat 2) are unseeded seats we cannot show to be
--                                         empty. All 23 are left for their own change.
--
-- ⚠ THE FLAG WAS RIGHT AND THE SEARCH SUMMARY WAS WRONG. A web search reported the Missouri House
-- as having five vacancies against our eight, which read like stale data on our side. The
-- chamber's own roster (house.mo.gov member grid) lists exactly eight: 029, 095, 099, 110, 114,
-- 149, 159, 160 — our eight, to the district. A search summary is a lead, never a measurement.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHICH DAY `vacant_since` MEANS, AND WHY IT IS NOT THE DAY THE MEMBER LEFT
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- `essentials.vacate_office(office_id, p_as_of, ...)` closes the predecessor's term at
-- `term_end = p_as_of - 1` and sets `vacant_since = COALESCE(vacant_since, p_as_of)`. So the
-- repo's own helper defines `vacant_since` as THE FIRST DAY THE SEAT WAS EMPTY, not the day the
-- member departed. Those differ by one.
--
-- Ballotpedia's state-legislative vacancy tables carry a column headed "DATE OF VACANCY", which
-- reads like the same thing and is not. Calibrated against a primary record: that table gives
-- Missouri Senate District 10 as "May 15, 2026", and the Missouri Senate's own archived page for
-- the seat says "Senator Fitzwater resigned his seat on 05-15-2026". The column is the DEPARTURE
-- date — the member's last day. So every date taken from it is written here as departure + 1.
--
-- 🟢 That rule was checked against this repo's existing data before being used, not just reasoned
-- about. Nine already-dated offices also appear in Ballotpedia's 2026 table; departure + 1
-- reproduces five of them to the day (OH House 66, CO House 32, FL House 55, MN House 21A,
-- FL House 78). Five exact agreements is not chance.
-- ⚠ The other four disagree (CA Senate 10, CA Assembly 3, VA House 20 by one day, TX Senate 22 by
-- two), so THIS COLUMN IS ALREADY INTERNALLY INCONSISTENT. Those four were written by earlier
-- passes from sources this migration has not re-checked. They are NOT corrected here: changing a
-- published date needs its own sourcing, and guessing which convention each used would be the
-- same error again. Recorded so the next pass knows the inconsistency is known, not new.
--
-- ⚠ Residual uncertainty, stated rather than hidden: for the twelve dates that come from that
-- table the edge is ±1 day, because Ballotpedia does not publish the hour. For the four taken
-- from primary records (three Missouri House resignation letters and one news report of a named
-- resignation date) there is no such edge.
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- SOURCES, ONE PER SEAT
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- PRIMARY — Journal of the Missouri House, Veto Session, Second Regular Session, 103rd General
-- Assembly, First Day, Wednesday, September 16, 2026, "LETTERS OF RESIGNATION", pages 1-3:
--   https://documents.house.mo.gov/billtracking/bills261/jrnpdf/jrn073.pdf
--   · District 159, Dirk Deaton, letter of August 7 2026: "effective Sunday, August 9, 2026, at
--     11:59 p.m."                                         -> first vacant day 2026-08-10
--   · District  99, Ian Mackey, letter of August 27 2026: "effective at 11:59 p.m., August 31,
--     2026"                                               -> first vacant day 2026-09-01
--   · District  29, Aaron Crossley, letter of August 27 2026: "effective at 11:59 p.m. on
--     August 31, 2026, as state representative for the 29th House District"
--                                                         -> first vacant day 2026-09-01
--   These three appear in NEITHER Ballotpedia vacancy table. Without the Journal they would have
--   been written off as unsourceable, or worse, taken from two secondary pages that disagree with
--   each other (one still lists Mackey as sitting today; the chamber's roster says the seat is
--   vacant).
--
-- PRIMARY — Missouri Senate, archived member page for District 10:
--   https://www.senate.mo.gov/senators/PastSenators?id=269
--   "Senator Fitzwater resigned his seat on 05-15-2026."  -> first vacant day 2026-05-16
--
-- NAMED DATE IN REPORTING — Fulton County GA, Commission District 4:
--   https://roughdraftatlanta.com/2026/03/20/fulton-county-commissioner-resigns/
--   "Fulton County Commissioner Mo Ivory resigned on March 6 from the District 4 seat"
--                                                         -> first vacant day 2026-03-07
--
-- BALLOTPEDIA "DATE OF VACANCY" + 1, all with DATE FILLED = TBD at time of writing:
--   https://ballotpedia.org/State_legislative_vacancies,_2026
--   https://ballotpedia.org/State_legislative_vacancies,_2025
--   · MO House  95  Michael O'Donnell  2025-01-15 -> 2025-01-16
--   · MO House 160  Ben Baker          2025-05-04 -> 2025-05-05
--   · MO House 149  Donnie Brown       2025-08-21 -> 2025-08-22
--   · MO House 114  Ken Waller (death) 2025-08-23 -> 2025-08-24
--   · MO House 110  Justin Sparks      2025-11-24 -> 2025-11-25
--   · MA 1st Franklin     Natalie Blais 2026-01-19 -> 2026-01-20
--   · MA 17th Middlesex   Vanna Howard  2026-03-18 -> 2026-03-19
--   · GA Senate 12  Freddie Sims       2026-03-23 -> 2026-03-24
--   · OH Senate 13  Nathan Manning     2026-08-03 -> 2026-08-04
--   · FL Senate 39  Bryan Avila        2026-08-25 -> 2026-08-26
--   · TN House  84  Joe Towns Jr.      2026-08-31 -> 2026-09-01
--
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- WHAT THIS DOES NOT CHANGE
-- ═════════════════════════════════════════════════════════════════════════════════════════════
-- Nothing is seated, nothing is unflagged, no term row is written. All sixteen offices have ZERO
-- `office_terms` rows (asserted below), so `vacate_office` finds no term to close and only sets
-- the flag and the date — which is why `essentials.offices_missing_terms` cannot move. Its
-- 295 / 57 / 238 is asserted unchanged on both sides.
--
-- Measured 2026-10-26, before: 65 flagged, 24 dated, 41 undated.
--                       after: 65 flagged, 40 dated, 25 undated.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 1. The sixteen, with the identity each one must have before it is touched.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE ID ALONE IS NOT ENOUGH. A transposed uuid would silently date the wrong seat, and every
-- gate below would still pass because the counts would be right. Each row therefore carries the
-- district label and office title it must match, and the pre-flight refuses on any mismatch.
CREATE TEMP TABLE _targets (
  office_id        uuid PRIMARY KEY,
  expect_label     text NOT NULL,
  expect_title     text NOT NULL,
  new_vacant_since date NOT NULL,
  why              text NOT NULL
) ON COMMIT DROP;

INSERT INTO _targets VALUES
  ('fbb76a0d-118c-472a-8c47-44a92ad4106c', 'State House District 95',  'Representative',
   DATE '2025-01-16', 'MO House 95: Michael O''Donnell departed 2025-01-15'),
  ('b02f28d3-2ebb-47d7-8e2a-a46f9208d4ed', 'State House District 160', 'Representative',
   DATE '2025-05-05', 'MO House 160: Ben Baker departed 2025-05-04'),
  ('d235998c-e374-4ee2-94f1-225155b0807c', 'State House District 149', 'Representative',
   DATE '2025-08-22', 'MO House 149: Donnie Brown resigned 2025-08-21'),
  ('098cea75-1ca5-4e14-84c8-eb180f12113b', 'State House District 114', 'Representative',
   DATE '2025-08-24', 'MO House 114: Ken Waller died 2025-08-23'),
  ('00fd7ce7-8c65-41df-8195-4d4beaec6ff9', 'State House District 110', 'Representative',
   DATE '2025-11-25', 'MO House 110: Justin Sparks departed 2025-11-24'),
  ('4965c918-2024-4b4c-aaf1-a8b4ca45bfea', '1st Franklin District',
   'Representative, 1st Franklin District',
   DATE '2026-01-20', 'MA 1st Franklin: Natalie Blais resigned 2026-01-19'),
  ('d8ac922d-3c87-4724-a4c6-57cb40df4da9', 'Fulton County Commission District 4',
   'Commissioner, District 4',
   DATE '2026-03-07', 'Fulton County GA District 4: Mo Ivory resigned 2026-03-06'),
  ('b45625f8-4c85-4924-b850-f2ba0fdf0c24', '17th Middlesex District',
   'Representative, 17th Middlesex District',
   DATE '2026-03-19', 'MA 17th Middlesex: Vanna Howard departed 2026-03-18'),
  ('9f9cc8c6-cd99-42df-81fc-0e3e0da61595', 'State Senate District 12', 'Senator',
   DATE '2026-03-24', 'GA Senate 12: Freddie Sims resigned 2026-03-23'),
  ('428ad552-a2ab-4288-9d8f-155d82a832d6', 'State Senate District 10', 'Senator',
   DATE '2026-05-16', 'MO Senate 10: Travis Fitzwater resigned 2026-05-15 (Senate page)'),
  ('3ba25074-8a38-4575-a7ba-7b57655bf30c', 'State House District 159', 'Representative',
   DATE '2026-08-10', 'MO House 159: Dirk Deaton, effective 11:59pm 2026-08-09 (House Journal)'),
  ('d98b176d-3fe5-4535-9003-e20a547b3897', 'State Senate District 13', 'Senator',
   DATE '2026-08-04', 'OH Senate 13: Nathan Manning departed 2026-08-03'),
  ('8716c4f7-9da4-44d2-af89-c79bbf1be35a', 'State Senate District 39', 'Senator',
   DATE '2026-08-26', 'FL Senate 39: Bryan Avila resigned 2026-08-25'),
  ('5453d70c-f2ed-4457-a7ad-161572ab0f31', 'State House District 29',  'Representative',
   DATE '2026-09-01', 'MO House 29: Aaron Crossley, effective 11:59pm 2026-08-31 (House Journal)'),
  ('cb68712d-a0fe-40ee-9633-d4a70e871af6', 'State House District 99',  'Representative',
   DATE '2026-09-01', 'MO House 99: Ian Mackey, effective 11:59pm 2026-08-31 (House Journal)'),
  ('f83c9695-eb83-4ea8-81e6-e6e4e24a4559', 'State House District 84',  'Representative',
   DATE '2026-09-01', 'TN House 84: Joe Towns Jr. departed 2026-08-31');

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 2. Pre-flight. Refuse before writing anything if the ground is not what was measured.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad text;
BEGIN
  SELECT count(*) INTO n FROM _targets;
  IF n <> 16 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected 16 target offices, found %', n;
  END IF;

  -- Every target must exist, with the district label and title it was researched under.
  SELECT string_agg(format('%s (want %L / %L, got %L / %L)',
                           t.office_id, t.expect_label, t.expect_title,
                           coalesce(d.label,'<no district>'), coalesce(o.title,'<no office>')),
                    E'\n  ')
    INTO bad
    FROM _targets t
    LEFT JOIN essentials.offices   o ON o.id = t.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.id IS NULL
      OR coalesce(d.label,'') IS DISTINCT FROM t.expect_label
      OR o.title              IS DISTINCT FROM t.expect_title;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target identity does not match:%s  %s', E'\n  ', bad;
  END IF;

  -- Each must be flagged vacant and undated. A target that already carries a date is a sign the
  -- world moved, not something to overwrite.
  SELECT string_agg(format('%s is_vacant=%s vacant_since=%s', o.id, o.is_vacant, o.vacant_since),
                    ', ')
    INTO bad
    FROM _targets t JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.is_vacant IS DISTINCT FROM true OR o.vacant_since IS NOT NULL;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target is not flagged-and-undated: %', bad;
  END IF;

  -- 🔴 ZERO TERM ROWS IS LOAD BEARING. vacate_office closes any open term at p_as_of - 1. These
  -- offices have none, which is why this migration cannot move offices_missing_terms. If one grew
  -- a term since measurement, stop: closing it is a different decision than dating a flag.
  SELECT string_agg(format('%s has %s term row(s)', t.office_id, c), ', ') INTO bad
    FROM _targets t
    CROSS JOIN LATERAL (SELECT count(*) AS c FROM essentials.office_terms x
                         WHERE x.office_id = t.office_id) q
   WHERE q.c <> 0;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'PRE-FLIGHT: target has term rows, refusing: %', bad;
  END IF;

  -- The population this migration claims to be a subset of.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL;
  IF n <> 41 THEN
    RAISE EXCEPTION 'PRE-FLIGHT: expected 41 flagged-and-undated offices, found % '
                    '(re-triage before running: the 41 were classified one at a time)', n;
  END IF;

  -- ⚠ The Richland County SC seat is the one correct undated vacancy. If this migration ever
  -- grows to include it, that is a mistake: its date is not published and its description says so.
  IF EXISTS (SELECT 1 FROM _targets
              WHERE office_id = '458328a9-1013-402d-ad7d-52284217be5e') THEN
    RAISE EXCEPTION 'PRE-FLIGHT: Richland County SC SWCD must stay undated — its date is not '
                    'published and its description already records that';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 3. Snapshot, in this transaction, for a delta gate.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 GATE ON THE DELTA, NOT ON A TOTAL. Another session can move these totals between the moment
-- they were measured and the moment this runs. `did_run` keeps the delta honest on a re-run: if
-- the dates are already written, the expected delta is zero rather than sixteen.
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)                            AS vac_total,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL)   AS undated,
       (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) AS dated,
       (SELECT count(*) FROM essentials.office_terms)                                       AS terms_total,
       (SELECT count(*) FROM essentials.offices_missing_terms)                              AS omt_total,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant)                AS omt_flagged,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant)            AS omt_unflagged,
       (SELECT count(*) FROM _targets t JOIN essentials.offices o ON o.id = t.office_id
         WHERE o.vacant_since IS NULL)                                                      AS to_write;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 4. Write. One call to the house helper per seat, in date order.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- CLAUDE.md: use the helpers rather than hand-rolling. vacate_office is idempotent by
-- construction — `vacant_since = COALESCE(vacant_since, p_as_of)` — so a re-run writes nothing.
-- Its `source` argument is recorded on the term it closes; with no term to close it is not
-- stored, so the per-seat citation lives in this file, which is the record (there is no
-- schema_migrations table here).
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM _targets ORDER BY new_vacant_since, office_id LOOP
    PERFORM essentials.vacate_office(
              r.office_id,
              r.new_vacant_since,
              'CC_0298: ' || r.why,
              'resigned');
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 5. Post-verify.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE b record; bad text; n int;
BEGIN
  SELECT * INTO b FROM _before;

  -- (a) Every target carries EXACTLY the researched date. This is the assertion a transposed
  --     date or a swapped pair of seats fails; the counts below would not notice either.
  SELECT string_agg(format('%s (%s): want %s, got %s',
                           t.office_id, t.expect_label, t.new_vacant_since, o.vacant_since),
                    E'\n  ')
    INTO bad
    FROM _targets t JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.vacant_since IS DISTINCT FROM t.new_vacant_since;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'POST-VERIFY: wrong vacant_since on:%s  %s', E'\n  ', bad;
  END IF;

  -- (b) Still flagged. Dating a vacancy must not unflag it.
  SELECT count(*) INTO n
    FROM _targets t JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.is_vacant IS DISTINCT FROM true;
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % target office(s) are no longer flagged is_vacant', n;
  END IF;

  -- (c) The delta is exactly what was intended: `to_write` offices moved undated -> dated, and
  --     nothing else about the vacant population changed.
  IF (b.undated - (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL))
       IS DISTINCT FROM b.to_write THEN
    RAISE EXCEPTION 'POST-VERIFY: undated fell by %, expected % '
                    '(a seat outside the target list changed, or one of them did not)',
      b.undated - (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL),
      b.to_write;
  END IF;

  IF ((SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) - b.dated)
       IS DISTINCT FROM b.to_write THEN
    RAISE EXCEPTION 'POST-VERIFY: dated rose by %, expected %',
      (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NOT NULL) - b.dated,
      b.to_write;
  END IF;

  -- (d) 🔴 NO SEAT WAS FLAGGED OR UNFLAGGED. The total flagged population must not move at all:
  --     this migration dates vacancies, it does not declare or withdraw any.
  IF (SELECT count(*) FROM essentials.offices WHERE is_vacant) IS DISTINCT FROM b.vac_total THEN
    RAISE EXCEPTION 'POST-VERIFY: flagged-vacant total moved % -> %',
      b.vac_total, (SELECT count(*) FROM essentials.offices WHERE is_vacant);
  END IF;

  -- (e) No term row written, closed or touched. vacate_office would have closed an open term had
  --     one existed; the pre-flight proved none did, and this proves none appeared.
  IF (SELECT count(*) FROM essentials.office_terms) IS DISTINCT FROM b.terms_total THEN
    RAISE EXCEPTION 'POST-VERIFY: office_terms count moved % -> %',
      b.terms_total, (SELECT count(*) FROM essentials.office_terms);
  END IF;
  SELECT count(*) INTO n FROM _targets t
    JOIN essentials.office_terms x ON x.office_id = t.office_id;
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % term row(s) now hang off a target office', n;
  END IF;

  -- (f) The occupancy metric is untouched, all three numbers. CLAUDE.md: only `unflagged` is the
  --     baseline, and it must not move either way here.
  IF ((SELECT count(*) FROM essentials.offices_missing_terms),
      (SELECT count(*) FROM essentials.offices_missing_terms m
         JOIN essentials.offices o ON o.id = m.office_id WHERE o.is_vacant),
      (SELECT count(*) FROM essentials.offices_missing_terms m
         JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant))
     IS DISTINCT FROM (b.omt_total, b.omt_flagged, b.omt_unflagged) THEN
    RAISE EXCEPTION 'POST-VERIFY: offices_missing_terms moved from % / % / %',
      b.omt_total, b.omt_flagged, b.omt_unflagged;
  END IF;

  -- (g) The Richland County SC seat is still flagged and still undated — the one vacancy whose
  --     missing date is correct.
  IF NOT EXISTS (SELECT 1 FROM essentials.offices
                  WHERE id = '458328a9-1013-402d-ad7d-52284217be5e'
                    AND is_vacant AND vacant_since IS NULL) THEN
    RAISE EXCEPTION 'POST-VERIFY: Richland County SC SWCD is no longer flagged-and-undated';
  END IF;

  -- (h) The 20 California duplicate-seat rows are still undated. Dating one would turn a modelling
  --     duplicate into a published claim that a sitting board has an empty chair.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers  c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.is_vacant AND o.vacant_since IS NOT NULL
     AND g.name IN ('Acton-Agua Dulce Unified, California, US',
                    'Altadena Library District, California, US',
                    'City of Azusa, California, US',
                    'City of Santa Clarita, California, US',
                    'Keppel Union Elementary, California, US',
                    'Montebello Unified, California, US',
                    'Palmdale Elementary, California, US',
                    'Paramount Unified, California, US');
  IF n <> 0 THEN
    RAISE EXCEPTION 'POST-VERIFY: % California duplicate-seat row(s) were dated; they are '
                    'duplicates of a seated At-Large row, not vacancies', n;
  END IF;

  RAISE NOTICE 'CC_0298 OK: % office(s) dated; flagged total % unchanged; undated % -> %; '
               'offices_missing_terms % / % / % unchanged',
    b.to_write, b.vac_total, b.undated,
    (SELECT count(*) FROM essentials.offices WHERE is_vacant AND vacant_since IS NULL),
    b.omt_total, b.omt_flagged, b.omt_unflagged;
END $$;

COMMIT;

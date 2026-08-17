-- Migration 1814: Fort Worth's only 2026 race — the District 10 special — plus term_end on
--                 all 11 city council seats.
--
-- ============================================================================
-- WHAT WAS MISSING, AND WHAT WAS NOT
-- ============================================================================
-- The Tarrant seed (2026-08-08) gave the City of Fort Worth 11 offices with 11 seated members and
-- ZERO races. Checked before writing: the OFFICE ROSTER IS ALREADY COMPLETE and needs nothing.
-- Fort Worth is council-manager and elects only the Mayor plus ten district council members;
-- Ballotpedia states outright "Ballotpedia does not cover any additional city officials in Fort
-- Worth, Texas," and the city's own elected-officials index lists exactly those eleven. There is no
-- elected city attorney, clerk, marshal or auditor to add.
--
-- ⚠ THE DISTRICTS ARE NUMBERED 2 THROUGH 11 — THERE IS NO DISTRICT 1. Ten districts, numbered
-- 2..11, plus the at-large Mayor = 11 seats. A "District 1 is missing" bug report against this
-- roster is a false positive; do not add one.
--
-- So the gaps were (a) no race row for the one 2026 contest, and (b) all 11 office_terms carried
-- term_start NULL *and* term_end NULL.
--
-- ============================================================================
-- THE RACE: District 10 special, May 2, 2026 — and 🔴 THE WINNER LOST THE BIG COUNTY
-- ============================================================================
-- Alan Blaylock vacated District 10 to run for the Texas House, so the seat went to a special
-- election for the UNEXPIRED remainder of his two-year term. Tarrant County's official contest
-- title is "City of Fort Worth Member of the City Council, District 10 (Unexpired Term)".
-- (Blaylock has no politicians row in this corpus, so there is no predecessor term to close here.)
--
-- 🔴🔴 FORT WORTH SPANS FOUR COUNTIES AND THIS RACE SPANS THREE. Citing one county's canvass would
-- not merely understate the totals the way the Frisco mayor rows do — IT WOULD RECORD THE WRONG
-- WINNER. Alicia Ortiz WON Tarrant County. Chris Jamieson won the seat on Denton County:
--
--     county    Jamieson   Ortiz   total   source
--     Tarrant      1,602   1,613   3,215   Tarrant County / Clarity election 126069, canvassed
--     Denton         238     150     388   Denton County / Clarity election 126278, canvassed
--     Wise             1       2       3   Fort Worth Report, "all votes counted"
--     TOTAL        1,841   1,765   3,606
--
-- Jamieson wins by 76. ⚠ THE TOTAL IS COMPOSED FROM THREE DOCUMENTS, NOT READ OFF ONE. Recorded
-- that way deliberately, with all three named in result_source — the city never published a
-- combined canvass document for the D10 race (its election-history page carries ordinances,
-- notices and polling lists only, no returns), and the alternative would be inventing a citation
-- for a document that does not exist. Every published combined figure is a news tally, and they
-- disagree with each other: Ballotpedia 1,835/1,759; Community Impact 1,836/1,760; Fort Worth
-- Report 1,836/1,761 and "a reported 75 votes". All are election-night; the canvassed county
-- numbers above are higher, as canvasses normally are. Only the OUTCOME is beyond doubt, and the
-- outcome is what `result` records. Parker County is a Fort Worth county too but has no D10
-- territory; it appears in the city's election notices only for the citywide bond and charter
-- propositions.
--
-- ⚠⚠ KNOWN LIMITATION, PRE-EXISTING AND NOT INTRODUCED HERE: EVERY FORT WORTH ADDRESS NOW SURFACES
-- THIS RACE, INCLUDING THE TEN DISTRICTS THAT COULD NOT VOTE IN IT. Verified after applying: a
-- downtown (District 9) address returns the District 10 contest. All 11 Fort Worth offices attach to
-- the citywide polygon 4827000/G4110 because Tarrant County has ZERO sub-county geofences — the
-- deliberate choice recorded in the 2026-08-08 Tarrant handoff, where over-showing was judged safer
-- than under-showing for OFFICEHOLDERS. A RACE is a harder case: a District 9 voter is shown a
-- contest that was never on their ballot. The vote totals prove the point — this race drew ~3,600
-- votes while the citywide bond propositions on the same ballot drew ~23,000.
--
-- 🔑 UNLIKE Kitsap County and Bainbridge Island (migrations 1800/1801), FORT WORTH COUNCIL DISTRICTS
-- REALLY DO ELECT. These are single-member districts; only the Mayor is at-large. So per-district
-- routing is the CORRECT model here, not a distortion, and it is the real fix.
-- ▶ OWED: load the city's own current layer — CFW_AGOL_ADMIN "CFW Council Districts",
--   https://mapit.fortworthtexas.gov/ags/rest/services/CIVIC/OpenData_Boundaries/MapServer/2
--   (modified 2026-08-07) — under a new X-series mtfcc, then re-point the ten district offices at it
--   and leave the Mayor on 4827000/G4110. Geometry before districts, as the handoff says. That also
--   removes the same over-showing from the 10 district councilmembers themselves.
--
-- ⚠ NOT SEEDED: the fifteen citywide propositions on the same ballot (a $845M bond, Props A-F, and
-- nine charter amendments, Props G-O). This corpus models candidates, not ballot measures, and
-- there is no races/race_candidates shape for a For/Against question. Noted so their absence reads
-- as scope, not omission.
--
-- ============================================================================
-- TERMS: all eleven seats expire May 2027
-- ============================================================================
-- Fort Worth council terms are TWO YEARS and every seat is elected together in May of odd years
-- (2021, 2023, 2025 → next 2027). KERA, reporting the swearing-in: "In May 2027, District 10 will
-- again elect its council member as all seats go up for grabs citywide." KERA on the special
-- election: the winner "fills the remaining year of Blaylock's two-year term, which expires in
-- May 2027."
--
-- 🔑 CHECKED, BECAUSE IT WOULD HAVE INVALIDATED EVERY term_end BELOW: the May 2, 2026 charter
-- election did NOT change council term length. Extending terms from two years to three or four was
-- discussed in the December 2025 charter-review coverage, but no such proposition reached the
-- ballot; the nine that did (Props G-O) covered council pay, city-manager authority, appointee
-- hearings, budget adoption, vacancy/election-timing conformance and claims documentation. So the
-- two-year term stands and all eleven terms end together.
--
-- term_end is therefore set on ALL ELEVEN seats. That is a property of the TERM, not of how its
-- occupant arrived — an appointee filling a vacancy would still serve to the same expiry — so it
-- holds without needing to prove each member was elected in 2025.
--
-- ⚠ MONTH PRECISION, ENCODED AS A DAY. Every source says "May 2027" and none prints a day, so
-- term_end is written 2027-05-31, the same convention migration 1798 used for Kitsap's
-- "Dec. 2026". office_terms has NO end_precision column, so this comment is the only record that
-- the day is a month-precision reading and not a claim about a successor's swearing-in. ⚠ There is
-- a real tension worth resolving before anyone treats 2027-05-31 as exact: Mattie Parker's
-- assumed-office date is June 15, 2021, which suggests Fort Worth actually seats a new council in
-- mid-June, a fortnight after the term nominally "expires in May".
--
-- term_start is set for JAMIESON ONLY, at day precision: "Chris Jamieson smiles before his
-- swearing-in to Fort Worth City Council during a special meeting on May 12, 2026" (KERA).
-- ▶ The other ten term_starts stay NULL and are OWED. They are not derivable from what was read
-- here, and guessing the 2025 swearing-in date is exactly the invention this corpus keeps catching.
-- ⚠ Also unresolved: KERA says that May 12 meeting canvassed "Fort Worth's bond and charter
-- elections" and does not say the D10 special was canvassed then. A special election must be
-- canvassed before its winner is seated, so it happened on or before May 12 — but the date is not
-- established, which is why result_source cites the county canvasses rather than a city canvass.
--
-- Sources read 2026-08-16:
--   results.enr.clarityelections.com/TX/Tarrant/126069 (ver 376509) json/en/summary.json
--   results.enr.clarityelections.com/TX/Denton/126278  (ver 374170) json/en/summary.json
--   ballotpedia.org/City_elections_in_Fort_Worth,_Texas_(2026) · ballotpedia.org/Fort_Worth,_Texas
--   keranews.org 2026-03-09 (vacancy, term) · keranews.org 2026-05-13 (swearing-in)
--   fortworthreport.org 2026-05-03 (Wise County, margin)
--   fortworthtexas.gov/departments/citysecretary/elections/election-history/election-2026
--
-- The race hangs off the EXISTING "2026 Texas Municipal General" row (2026-05-02), which already
-- carries 40 May-2 municipal races from Collin, Grayson and Gregg counties — including Collin's
-- own "Joint General and Special Election" contests, so a special belongs there. No new election
-- row. Losing candidates get NO politicians row, matching every May-2 loser already in that
-- election (Shafer, Olivarez, Becker, Cornelius).
--
-- Idempotency: NOT EXISTS on every insert, keyed on (election, position_name) and (race, full_name).

BEGIN;

-- ─── 1. The race ─────────────────────────────────────────────────────────────

INSERT INTO essentials.races (id, election_id, office_id, position_name, seats, description)
SELECT gen_random_uuid(),
       e.id,
       o.id,
       'Fort Worth Council Member District 10 (Unexpired Term)',
       1,
       'Special election for the unexpired remainder of the District 10 term vacated by Alan '
       || 'Blaylock, who resigned to run for the Texas House. District 10 spans Tarrant, Denton '
       || 'and Wise counties; the term runs to May 2027.'
FROM essentials.elections e
CROSS JOIN essentials.offices o
JOIN essentials.chambers c    ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id
WHERE e.name = '2026 Texas Municipal General'
  AND e.election_date = DATE '2026-05-02'
  AND g.name = 'City of Fort Worth, Texas, US'
  AND o.title = 'Council Member District 10'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
    WHERE r.election_id = e.id
      AND r.position_name = 'Fort Worth Council Member District 10 (Unexpired Term)'
  );

-- ─── 2. The two candidates ───────────────────────────────────────────────────
--
-- is_incumbent is FALSE for BOTH. Ballotpedia: "There were no incumbents in this race." Jamieson
-- is the incumbent OFFICEHOLDER now, but he was not one when he ran, and race_candidates records
-- the race. Same distinction migration 1636 recorded for Alisa Simmons — incumbency belongs to an
-- office, not to a person.
--
-- Jamieson links to his existing politicians row (already seated in District 10 by the Tarrant
-- seed); Ortiz gets none.

WITH jamieson AS (
  SELECT p.id FROM essentials.politicians p
   WHERE p.full_name = 'Chris Jamieson' AND p.is_active = true
   LIMIT 1
)
INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   result, result_source, result_recorded_at, provisional_until, source, last_verified_at)
SELECT gen_random_uuid(),
       r.id,
       CASE WHEN v.link_politician THEN (SELECT id FROM jamieson) END,
       v.full_name, v.first_name, v.last_name,
       false,
       'active',
       v.result,
       'Composed from three county canvasses — no combined city canvass of this race was published. '
       || 'Tarrant County (Clarity election 126069, ver 376509, contest "City of Fort Worth Member '
       || 'of the City Council, District 10 (Unexpired Term)"): Jamieson 1,602, Ortiz 1,613. '
       || 'Denton County (Clarity election 126278, ver 374170): Jamieson 238, Ortiz 150. '
       || 'Wise County (Fort Worth Report, 2026-05-03, "all votes counted"): Jamieson 1, Ortiz 2. '
       || 'Combined 1,841 to 1,765. Ortiz carried Tarrant; Jamieson won on Denton. '
       || 'Published combined news tallies are election-night and disagree with one another. '
       || '(fetched 2026-08-16)',
       now(),
       NULL,
       'tarrant_denton_clarity_canvass+fwreport_wise',
       now()
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
CROSS JOIN (VALUES
  ('Chris Jamieson', 'Chris',  'Jamieson', 'won',  true),
  ('Alicia Ortiz',   'Alicia', 'Ortiz',    'lost', false)
) AS v(full_name, first_name, last_name, result, link_politician)
WHERE e.name = '2026 Texas Municipal General'
  AND r.position_name = 'Fort Worth Council Member District 10 (Unexpired Term)'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND rc.full_name = v.full_name
  );

-- ─── 3. term_end on all 11 seats; term_start for Jamieson ────────────────────

UPDATE essentials.office_terms trm
   SET term_end = DATE '2027-05-31'
  FROM essentials.offices o, essentials.chambers c, essentials.governments g
 WHERE trm.office_id = o.id
   AND o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.name = 'City of Fort Worth, Texas, US'
   AND trm.term_end IS NULL;

UPDATE essentials.office_terms trm
   SET term_start = DATE '2026-05-12',
       start_precision = 'day',
       how_started = 'elected'
  FROM essentials.offices o, essentials.chambers c, essentials.governments g,
       essentials.politicians p
 WHERE trm.office_id = o.id
   AND o.chamber_id = c.id
   AND c.government_id = g.id
   AND trm.politician_id = p.id
   AND g.name = 'City of Fort Worth, Texas, US'
   AND o.title = 'Council Member District 10'
   AND p.full_name = 'Chris Jamieson'
   AND trm.term_start IS NULL;

-- The Tarrant seed left start_precision at its DEFAULT 'day' on all eleven rows while term_start
-- was NULL — a precision claim about a date that does not exist. The ten still-undated rows are
-- corrected to 'unknown' (the value migration 1798 used for Bainbridge's undated starts); only
-- Jamieson's row, which now has a real sourced day, keeps 'day'.

UPDATE essentials.office_terms trm
   SET start_precision = 'unknown'
  FROM essentials.offices o, essentials.chambers c, essentials.governments g
 WHERE trm.office_id = o.id
   AND o.chamber_id = c.id
   AND c.government_id = g.id
   AND g.name = 'City of Fort Worth, Texas, US'
   AND trm.term_start IS NULL
   AND trm.start_precision <> 'unknown';

-- ─── 4. Guards ───────────────────────────────────────────────────────────────

DO $$
DECLARE
  n_races int; n_cands int; n_won int; n_linked int;
  n_terms int; n_end int; jamieson_start date;
BEGIN
  SELECT count(*) INTO n_races
    FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = '2026 Texas Municipal General'
     AND r.position_name = 'Fort Worth Council Member District 10 (Unexpired Term)';
  IF n_races <> 1 THEN
    RAISE EXCEPTION 'Migration 1814: expected exactly 1 D10 race, got %', n_races;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE rc.result = 'won'),
         count(rc.politician_id)
    INTO n_cands, n_won, n_linked
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = '2026 Texas Municipal General'
     AND r.position_name = 'Fort Worth Council Member District 10 (Unexpired Term)';
  IF n_cands <> 2 THEN
    RAISE EXCEPTION 'Migration 1814: expected 2 candidates, got %', n_cands;
  END IF;
  IF n_won <> 1 THEN
    RAISE EXCEPTION 'Migration 1814: expected exactly 1 winner, got %', n_won;
  END IF;
  -- Jamieson linked, Ortiz not: exactly one politician_id.
  IF n_linked <> 1 THEN
    RAISE EXCEPTION 'Migration 1814: expected exactly 1 linked politician_id, got %', n_linked;
  END IF;

  SELECT count(*), count(trm.term_end) INTO n_terms, n_end
    FROM essentials.office_terms trm
    JOIN essentials.offices o     ON o.id = trm.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Worth, Texas, US';
  IF n_terms <> 11 OR n_end <> 11 THEN
    RAISE EXCEPTION 'Migration 1814: expected 11 Fort Worth terms all with term_end, got % terms / % dated', n_terms, n_end;
  END IF;

  SELECT trm.term_start INTO jamieson_start
    FROM essentials.office_terms trm
    JOIN essentials.offices o     ON o.id = trm.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Worth, Texas, US' AND o.title = 'Council Member District 10';
  IF jamieson_start <> DATE '2026-05-12' THEN
    RAISE EXCEPTION 'Migration 1814: District 10 term_start is %, expected 2026-05-12', jamieson_start;
  END IF;

  -- No row may claim a precision for a term_start it does not have.
  PERFORM 1
    FROM essentials.office_terms trm
    JOIN essentials.offices o     ON o.id = trm.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Fort Worth, Texas, US'
     AND trm.term_start IS NULL
     AND trm.start_precision <> 'unknown';
  IF FOUND THEN
    RAISE EXCEPTION 'Migration 1814: a Fort Worth term with NULL term_start still claims a start_precision';
  END IF;
END $$;

COMMIT;

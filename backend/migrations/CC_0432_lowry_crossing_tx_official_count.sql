-- CC_0432 — Lowry Crossing TX: the council is EIGHT members plus a mayor, not five.
--
-- `check:body-completeness` (PR #1472) flagged this as the largest surplus in the whole
-- `too_many` bucket: official_count 5 against NINE office rows held by NINE different people.
-- A surplus of four with no duplicate people is not South Portland's shape, so the question was
-- which number is wrong -- ours or theirs.
--
-- 🟢 OURS ARE RIGHT. THEIRS IS A DEFAULT THAT DOES NOT FIT THIS CITY. The city's own council
-- page (lowrycrossingtexas.org/operations/city_council.php, "Click on the names below to email
-- our current council members") lists exactly nine people, and they are exactly our nine:
--
--   Mayor Pat Kelly
--   Ward 1  Scott Pitchure              · Chris Madrid (Treasurer)
--   Ward 2  Tammy Hodges (Mayor Pro Tem) · Agur Rios
--   Ward 3  Eusebio "Joe" Trujillo III   · Cindy Cash
--   Ward 4  Muhanad (G) Hijazen          · Ollie Simpson
--
-- 🔴 WHERE THE 5 CAME FROM, MEASURED RATHER THAN GUESSED. Exactly FOUR Texas council chambers
-- carry official_count 5, and all four are small Collin County towns: Blue Ridge, Josephine,
-- Weston and this one. The other three hold Mayor + 5 council = 6 offices, so 5 is right for
-- them -- it is Texas's general-law default of five aldermen, excluding the mayor. Lowry Crossing
-- has EIGHT councilmembers, so the default was simply carried onto a city it does not describe.
-- ▶ A DEFAULT THAT IS RIGHT THREE TIMES OUT OF FOUR LOOKS LIKE A SOURCED FIGURE.
--
-- 🔴 OVERWRITTEN VALUE, recorded here because nothing else will: `official_count` was **5**.
-- There is no history table and no replay, so the previous value exists nowhere else once this
-- commits (CLAUDE.md).
--
-- 🔴 8 AND NOT 9, DELIBERATELY. The new value counts the COUNCILMEMBERS and excludes the mayor,
-- which is the convention its three Texas siblings already use and which the city's own page
-- follows (the Mayor is listed above the wards, not inside one). So `tx|too_many` stays at 4 and
-- Lowry Crossing stays in the bucket -- with a surplus of ONE, the Mayor, which is the large
-- documented "the count excludes a separately-elected executive" class rather than an
-- unexplained surplus of four. Setting it to 9 would have made this one chamber green by
-- adopting a different meaning for the column than its neighbours use, which is how a column
-- ends up meaning two things.
--
-- ⚠ THIS FILE FIXES THE COUNT AND NOTHING ELSE. Two findings are left open ON PURPOSE because
-- both turn on a question this research could not settle:
--
--   (1) 🔴 FOUR SITTING COUNCILMEMBERS ARE UNREACHABLE FROM EVERY ADDRESS. `Place 5`, `6`, `7`
--       and `8` -- Madrid, Rios, Cash and Simpson -- carry `district_id IS NULL`. Measured, not
--       reasoned: no district means no geofence join can ever match, so address search cannot
--       return them. `Place 1`-`4` and `Mayor` all point at the city-wide district
--       (7534e932, geo_id 4844308, G4110, one geofence row), so half this council is visible and
--       half is not.
--
--   (2) ⚠ THE TITLES SAY `Place`, THE CITY SAYS `Ward`, AND THE MAPPING IS EXACT. Places 1-4 are
--       the first-listed member of Wards 1-4 and Places 5-8 the second, matched by name. So our
--       eight seats are probably ward seats wearing at-large titles -- which is ROSTERS.md R8,
--       "the office titles themselves can be the defect", with the right COUNT and the wrong KIND.
--
--   🔴 BOTH FIXES DEPEND ON ONE UNANSWERED QUESTION: ARE THE WARDS ELECTORATES OR RESIDENCY
--   QUALIFICATIONS? If each ward elects its own two members, the right fix is four ward polygons
--   and eight retitled seats. If the wards are residency qualifications and all eight are elected
--   city-wide under a place system, our titles are RIGHT and the fix is simply to point Places
--   5-8 at the city-wide district. ROSTERS.md R9i settled exactly this question for South
--   Portland and the answer there was "residency qualifications, not separate electorates", so
--   it cannot be assumed either way. ▶ Guessing picks between showing a voter seven councillors
--   who do not represent them and hiding four who do. Neither is worth guessing, so neither is
--   done here. The city's election notice or the Collin County ballot settles it.
--
-- ⚠ TWO SOURCES THAT LOOKED AUTHORITATIVE AND WERE OTHER CITIES. A search for Lowry Crossing's
-- council composition returned ecode360 pages reading "The Council shall consist of nine (9)
-- members consisting of a Mayor and eight (8) Councilmembers" and "All members of the City
-- Council, other than the Mayor, shall be elected at-large under a place system" -- which look
-- decisive, agree with our row count, and would have settled finding (2) outright. They are
-- **City of Garland** (custId GA6318) and **City of Joshua** (JO6365). Checking the custId is
-- what caught it. ▶ A CODE PAGE THAT MATCHES YOUR EXPECTATION IS STILL A PAGE ABOUT SOME CITY;
-- read which one. Lowry Crossing's own code is ecode360 LO6395.
--
-- @incumbency-decision: no-effect — this migration writes no `essentials.office_terms` row at
-- all. It changes one integer on one `essentials.chambers` row and touches no office, no term
-- and no race, so no cached `race_candidates.is_incumbent` answer can move.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0432_lowry_crossing_tx_official_count.sql

BEGIN;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_stated   int;
  v_offices  int;
  v_people   int;
  v_nodist   int;
BEGIN
  SELECT ch.official_count,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id),
         (SELECT count(DISTINCT och.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE o.chamber_id = ch.id AND och.politician_id IS NOT NULL),
         (SELECT count(*) FROM essentials.offices o
           WHERE o.chamber_id = ch.id AND o.district_id IS NULL)
    INTO v_stated, v_offices, v_people, v_nodist
    FROM essentials.chambers ch
   WHERE ch.id = '44d56ac7-d894-432d-896b-59237c837c5e';

  IF v_stated IS DISTINCT FROM 5 THEN
    RAISE EXCEPTION 'CC_0432: official_count is % , expected the 5 this file overwrites.', v_stated;
  END IF;

  -- 🔴 THE REASON THE NEW NUMBER IS 8. Nine offices held by nine DISTINCT people means no row is
  -- a duplicate of another, so the count is what is wrong -- not the rows. If this ever stops
  -- being true the premise of the whole file is gone.
  IF v_offices <> 9 OR v_people <> 9 THEN
    RAISE EXCEPTION
      'CC_0432: expected 9 offices held by 9 distinct people; found % offices / % people. If a '
      'person holds two of these rows this is South Portland''s shape and the fix is a DELETE, '
      'not a recount.', v_offices, v_people;
  END IF;

  -- Finding (1) must still be true, so the follow-up it records is not silently already gone.
  IF v_nodist <> 4 THEN
    RAISE EXCEPTION
      'CC_0432: expected 4 offices with NULL district_id (Places 5-8); found %. Somebody has '
      'changed the geography since this file was researched -- re-read finding (1) in the header.',
      v_nodist;
  END IF;
END $$;

CREATE TEMP TABLE _bc_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices)                                AS offices,
       (SELECT count(*) FROM essentials.office_terms)                           AS terms,
       (SELECT count(*) FROM essentials.offices_missing_terms m
          JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant) AS drift_unflagged;

-- ── The one change ───────────────────────────────────────────────────────────────────────────
UPDATE essentials.chambers
   SET official_count = 8          -- was 5; see the header
 WHERE id = '44d56ac7-d894-432d-896b-59237c837c5e'
   AND official_count = 5;

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_stated int;
  v_net    int;
  v_terms  int;
  v_drift  int;
BEGIN
  SELECT official_count INTO v_stated
    FROM essentials.chambers WHERE id = '44d56ac7-d894-432d-896b-59237c837c5e';
  IF v_stated <> 8 THEN
    RAISE EXCEPTION 'CC_0432: official_count is % after the update, expected 8.', v_stated;
  END IF;

  -- This file must not have touched occupancy in any way.
  SELECT (SELECT count(*) FROM essentials.offices) - b.offices,
         (SELECT count(*) FROM essentials.office_terms) - b.terms,
         (SELECT count(*) FROM essentials.offices_missing_terms m
            JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant) - b.drift_unflagged
    INTO v_net, v_terms, v_drift
    FROM _bc_before b;

  IF v_net <> 0 OR v_terms <> 0 THEN
    RAISE EXCEPTION 'CC_0432: offices changed by % and terms by %; this file must change neither.', v_net, v_terms;
  END IF;
  IF v_drift <> 0 THEN
    RAISE EXCEPTION 'CC_0432: the unflagged drift baseline moved by %; it must stay at 238.', v_drift;
  END IF;

  RAISE NOTICE 'CC_0432 OK: Lowry Crossing official_count 5 -> 8 against 9 offices / 9 people; the surplus is now the Mayor alone. Places 5-8 still carry no district -- see finding (1).';
END $$;

COMMIT;

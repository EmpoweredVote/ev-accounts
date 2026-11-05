-- CC_0339 — 2026-11-03 US Senate: record the 33 races AP has called.
--
-- Wave 1, the trial run. 33 of the 35 Senate races now carry a winner, each marked
-- `result_certainty = 'called'` and sourced to the AP race call that named the person.
--
-- 🔴 WHY THIS WAS EMPTY FOR A DAY, AND WHY THAT WAS WRONG.
-- `backend/data/senate-2026-results/RESULTS.md` held the rule "a media call is not a state
-- return ... Those calls are leads for where to look; they are not what gets written here", and
-- so recorded nothing. That is a misreading of the operator's ruling, which is:
--
--     "AP for called races, then state SoS to confirm certified -- we should label each so we
--      know what's been called and what's been certified."
--
-- `result_certainty` exists BECAUSE a call and a canvass are different things. Refusing to
-- record a call until the state certifies throws away the distinction the column was added to
-- carry, and leaves the site showing 35 departing senators as though nothing had happened. The
-- repo rule it borrowed -- "the chamber's own roster outranks every aggregator" -- is about
-- OFFICEHOLDER ROSTERS, not election night.
--
-- ⚠ NOTHING HERE IS CERTIFIED. Every row is `called`. Not one of the 35 races has
-- `isCertified: true` in AP's own metadata as of 2026-11-04. The state canvasses run for weeks;
-- a follow-up pass upgrades each row to `certified` against that state's own return.
--
-- ⚠ THIS SEATS NOBODY. Nothing here writes `office_terms`. Seating is a separate migration, at
-- the date CC_0348 established: 2027-01-03.
--
-- ============================================================================================
-- THE TWO RACES DELIBERATELY LEFT OUT
-- ============================================================================================
--   AK  "Too Early to Call" -- ranked choice (AP `rankedChoice: true`). Tabulation runs for
--       weeks; there is no winner to record, and an uncalled race correctly stays at seat
--       state 1.
--   MS  "Too Early to Call".
-- A race with no call gets no row. That is the correct answer, not a gap.
--
-- ============================================================================================
-- 🔴 MATCHING AP'S NAME TO OUR CANDIDATE IS WHERE THIS GOES WRONG, SO IT IS A CHECKED LIST
-- AND A GATE, NOT A FUZZY JOIN
-- ============================================================================================
-- AP and this database spell six of the 33 winners differently:
--     ID  AP "Jim Risch"        / ours "James Risch"
--     MA  AP "Edward Markey"    / ours "Edward J. Markey"
--     ME  AP "Troy Jackson"     / ours "Troy D. Jackson"
--     RI  AP "John Reed"        / ours "Jack Reed"
--     WV  AP "Shelley Capito"   / ours "Shelley Moore Capito"   (last_name is "Moore Capito")
--     WY  AP "Harriet Hageman"  / ours "Harriet M. Hageman"
-- and one cannot be matched on text at all:
--     NM  AP "Lujan"            / ours "Luján"  -- `unaccent` is not installed on production.
--
-- So the match is a per-state LAST NAME, read against our own candidate rows first, and New
-- Mexico is pinned by its `race_candidates.id` instead of by name.
--
-- ▶ MEASURED BEFORE WRITING: the last-name match returned 32 of 33, every one unique within its
-- race. The missing one was New Mexico. 🔴 THE COUNT IS WHAT CAUGHT IT -- the join simply
-- returned a smaller set, with no error, exactly as the NULL did in CC_0347. The gate below
-- re-asserts 33 and one-winner-per-race at apply time.
--
-- ⚠ SOUTH CAROLINA CARRIES TWO CANDIDATES NAMED GRAHAM -- the appointed incumbent Darline
-- Graham, and Lindsey Graham, who died in office on 2026-07-11. Neither won, so the winner
-- match is unambiguous. But it is why this file matches on a list that was read against the
-- real rows rather than on "the last name AP printed".
--
-- 🔴 AND IT IS WHY ONLY WINNERS ARE RECORDED. The obvious next step -- "everyone in a called
-- race who is not the winner lost" -- would mark LINDSEY GRAHAM as having lost the November
-- election. He was not in it: AP's own South Carolina ballot lists four candidates and he is
-- not among them. Losers want a per-candidate match against AP's own candidate list, which is
-- a separate pass. Asserting a result about a dead man from a blanket rule is not.
--
-- No value is overwritten: all 35 races carry `result IS NULL` today.

CREATE TEMP TABLE ap_senate_calls (state text, ap_last text, src text) ON COMMIT DROP;
INSERT INTO ap_senate_calls (state, ap_last, src) VALUES
  ('AL', 'Moore', 'AP race call for the 2026-11-03 general election: Barry Moore (GOP) 54.71%, 917,347 votes; called 2026-11-04T04:17:58.590Z. AP race 20261103AL1755, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('AR', 'Cotton', 'AP race call for the 2026-11-03 general election: Tom Cotton (GOP) 54.26%, 480,627 votes; called 2026-11-04T03:40:06.259Z. AP race 20261103AR6345, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('CO', 'Hickenlooper', 'AP race call for the 2026-11-03 general election: John Hickenlooper (Dem) 60.21%, 1,365,991 votes; called 2026-11-04T02:00:32.190Z. AP race 20261103CO7168, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('DE', 'Coons', 'AP race call for the 2026-11-03 general election: Chris Coons (Dem) 63.57%, 240,347 votes; called 2026-11-04T01:00:20.744Z. AP race 20261103DE8362, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('FL', 'Moody', 'AP race call for the 2026-11-03 general election: Ashley Moody (GOP) 50.87%, 4,208,022 votes; called 2026-11-04T01:34:55.352Z. AP race 20261103FL84979, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('GA', 'Ossoff', 'AP race call for the 2026-11-03 general election: Jon Ossoff (Dem) 59.03%, 2,466,207 votes; called 2026-11-04T00:55:21.984Z. AP race 20261103GA12301, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('IA', 'Turek', 'AP race call for the 2026-11-03 general election: Josh Turek (Dem) 50.51%, 686,487 votes; called 2026-11-04T04:35:30.952Z. AP race 20261103IA17247, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('ID', 'Risch', 'AP race call for the 2026-11-03 general election: Jim Risch (GOP) 56.53%, 401,731 votes; called 2026-11-04T06:31:52.473Z. AP race 20261103ID13252, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('IL', 'Stratton', 'AP race call for the 2026-11-03 general election: Juliana Stratton (Dem) 60.94%, 2,429,072 votes; called 2026-11-04T01:00:40.102Z. AP race 20261103IL16430, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('KS', 'Hamilton', 'AP race call for the 2026-11-03 general election: Adam Hamilton (Dem) 50.96%, 558,796 votes; called 2026-11-04T04:24:51.393Z. AP race 20261103KS17585, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('KY', 'Barr', 'AP race call for the 2026-11-03 general election: Andy Barr (GOP) 55%, 784,869 votes; called 2026-11-04T02:16:00.684Z. AP race 20261103KY18783, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('LA', 'Letlow', 'AP race call for the 2026-11-03 general election: Julia Letlow (GOP) 50.88%, 745,963 votes; called 2026-11-04T05:31:29.298Z. AP race 20261103LA20157, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('MA', 'Markey', 'AP race call for the 2026-11-03 general election: Edward Markey (Dem) 63.25%, 1,590,089 votes; called 2026-11-04T01:01:27.995Z. AP race 20261103MA24467, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('ME', 'Jackson', 'AP race call for the 2026-11-03 general election: Troy Jackson (Dem) 53.41%, 368,429 votes; called 2026-11-04T06:02:01.517Z. AP race 20261103ME20643, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('MI', 'El-Sayed', 'AP race call for the 2026-11-03 general election: Abdul El-Sayed (Dem) 52.5%, 2,507,454 votes; called 2026-11-04T07:27:18.642Z. AP race 20261103MI24463, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('MN', 'Flanagan', 'AP race call for the 2026-11-03 general election: Peggy Flanagan (Dem) 53.71%, 1,520,869 votes; called 2026-11-04T05:07:07.217Z. AP race 20261103MN25151, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('MT', 'Alme', 'AP race call for the 2026-11-03 general election: Kurt Alme (GOP) 48.58%, 230,011 votes; called 2026-11-04T07:54:25.875Z. AP race 20261103MT27607, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('NC', 'Cooper', 'AP race call for the 2026-11-03 general election: Roy Cooper (Dem) 58.72%, 2,467,963 votes; called 2026-11-04T01:23:59.591Z. AP race 20261103NC35984, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('NE', 'Ricketts', 'AP race call for the 2026-11-03 general election: Pete Ricketts (GOP) 50.44%, 373,122 votes; called 2026-11-04T08:27:46.220Z. AP race 20261103NE28594, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('NH', 'Pappas', 'AP race call for the 2026-11-03 general election: Chris Pappas (Dem) 55.96%, 341,737 votes; called 2026-11-04T01:20:51.833Z. AP race 20261103NH30003, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('NJ', 'Booker', 'AP race call for the 2026-11-03 general election: Cory Booker (Dem) 62.12%, 1,787,172 votes; called 2026-11-04T01:00:53.549Z. AP race 20261103NJ31296, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('NM', 'Lujan', 'AP race call for the 2026-11-03 general election: Ben Lujan (Dem) 63.15%, 455,165 votes; called 2026-11-04T02:00:42.148Z. AP race 20261103NM33948, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('OH', 'Brown', 'AP race call for the 2026-11-03 general election: Sherrod Brown (Dem) 50.01%, 2,301,042 votes; called 2026-11-04T04:10:04.990Z. AP race 20261103OH84327, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('OK', 'Hern', 'AP race call for the 2026-11-03 general election: Kevin Hern (GOP) 57.2%, 639,510 votes; called 2026-11-04T02:36:04.840Z. AP race 20261103OK37960, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('OR', 'Merkley', 'AP race call for the 2026-11-03 general election: Jeff Merkley (Dem) 56.57%, 864,491 votes; called 2026-11-04T04:00:14.705Z. AP race 20261103OR38952, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('RI', 'Reed', 'AP race call for the 2026-11-03 general election: John Reed (Dem) 66.64%, 237,742 votes; called 2026-11-04T01:01:11.089Z. AP race 20261103RI40003, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('SC', 'Andrews', 'AP race call for the 2026-11-03 general election: Annie Andrews (Dem) 51.13%, 1,042,362 votes; called 2026-11-04T03:39:16.039Z. AP race 20261103SC41938, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('SD', 'Rounds', 'AP race call for the 2026-11-03 general election: Mike Rounds (GOP) 60.5%, 184,584 votes; called 2026-11-04T05:02:17.689Z. AP race 20261103SD42003, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('TN', 'Hagerty', 'AP race call for the 2026-11-03 general election: Bill Hagerty (GOP) 55.08%, 1,138,457 votes; called 2026-11-04T04:28:22.446Z. AP race 20261103TN43441, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('TX', 'Talarico', 'AP race call for the 2026-11-03 general election: James Talarico (Dem) 55.08%, 5,445,121 votes; called 2026-11-04T04:03:28.187Z. AP race 20261103TX46643, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('VA', 'Warner', 'AP race call for the 2026-11-03 general election: Mark Warner (Dem) 61.16%, 2,183,072 votes; called 2026-11-04T00:00:10.929Z. AP race 20261103VA47917, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('WV', 'Capito', 'AP race call for the 2026-11-03 general election: Shelley Capito (GOP) 58.33%, 266,068 votes; called 2026-11-04T01:52:23.966Z. AP race 20261103WV49137, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.'),
  ('WY', 'Hageman', 'AP race call for the 2026-11-03 general election: Harriet Hageman (GOP) 65.24%, 122,157 votes; called 2026-11-04T02:00:20.492Z. AP race 20261103WY51677, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). UNOFFICIAL - this is a race call, not the state canvass.')
;

CREATE TEMP TABLE sen_2026 ON COMMIT DROP AS
SELECT upper(d.state) AS st, r.id AS race_id, rc.id AS rc_id, p.full_name, p.last_name
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.race_candidates rc ON rc.race_id = r.id
  JOIN essentials.politicians p ON p.id = rc.politician_id
 WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'NATIONAL_UPPER';

-- The matched winners: 32 by checked last name, plus New Mexico pinned by id.
CREATE TEMP TABLE sen_winners ON COMMIT DROP AS
SELECT s.rc_id, s.race_id, s.st, s.full_name, a.src
  FROM ap_senate_calls a
  JOIN sen_2026 s ON s.st = a.state
                 AND (s.last_name = a.ap_last OR s.last_name LIKE '%' || a.ap_last)
 WHERE a.state <> 'NM'
UNION ALL
SELECT s.rc_id, s.race_id, s.st, s.full_name, a.src
  FROM ap_senate_calls a
  JOIN sen_2026 s ON s.rc_id = '5badf9c8-def0-42dc-8ae1-c453a4555fb4'::uuid  -- Ben Ray Luján
 WHERE a.state = 'NM';

UPDATE essentials.race_candidates rc
   SET result           = 'won',
       result_certainty = 'called',
       result_source    = w.src
  FROM sen_winners w
 WHERE rc.id = w.rc_id
   AND rc.result IS DISTINCT FROM 'won';

DO $$
DECLARE
  v_calls bigint; v_matched bigint; v_won bigint; v_races bigint; v_dupe bigint; v_cert bigint;
BEGIN
  SELECT count(*) INTO v_calls FROM ap_senate_calls;
  IF v_calls <> 33 THEN RAISE EXCEPTION 'CC_0339: expected 33 AP calls, found %', v_calls; END IF;

  SELECT count(*) INTO v_matched FROM sen_winners;
  IF v_matched <> 33 THEN
    RAISE EXCEPTION 'CC_0339: % winner(s) matched, expected 33 -- a name match that returns a smaller set fails silently', v_matched;
  END IF;

  -- 🔴 ONE WINNER PER RACE. Two Grahams sit in South Carolina; this is what stops a second row
  -- in any race from being marked won.
  SELECT count(*) INTO v_dupe FROM (
    SELECT race_id FROM sen_winners GROUP BY race_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CC_0339: % race(s) matched more than one winner', v_dupe; END IF;

  SELECT count(*) INTO v_won
    FROM essentials.race_candidates rc JOIN sen_2026 s ON s.rc_id = rc.id
   WHERE rc.result = 'won';
  IF v_won <> 33 THEN RAISE EXCEPTION 'CC_0339: expected 33 Senate rows marked won, found %', v_won; END IF;

  SELECT count(DISTINCT s.race_id) INTO v_races
    FROM essentials.race_candidates rc JOIN sen_2026 s ON s.rc_id = rc.id
   WHERE rc.result = 'won';
  IF v_races <> 33 THEN RAISE EXCEPTION 'CC_0339: 33 winners span % races, not 33', v_races; END IF;

  -- 🔴 NOTHING MAY CLAIM TO BE CERTIFIED. Not one race is certified in AP's own metadata, and a
  -- row that said otherwise would assert a state canvass that has not happened.
  SELECT count(*) INTO v_cert
    FROM essentials.race_candidates rc JOIN sen_2026 s ON s.rc_id = rc.id
   WHERE rc.result_certainty = 'certified';
  IF v_cert <> 0 THEN RAISE EXCEPTION 'CC_0339: % Senate row(s) claim certification', v_cert; END IF;

  RAISE NOTICE 'CC_0339 OK: 33 of 35 Senate races recorded as called; AK and MS left uncalled';
END $$;

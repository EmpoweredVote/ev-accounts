-- CC_0353 - 2026-11-03 federal: seed the last two candidates AP names in LA-01 and VA-11.
--
-- `CC_0352` closed the four seeding gaps that changed an outcome or took more than 20% of a
-- district. It left two behind on purpose, and named them: the minor candidates in the two
-- races it had already touched. This file closes those two.
--
-- | Seat  | Person         | Party | AP share | Votes | What this file does                |
-- |-------|----------------|-------|----------|-------|------------------------------------|
-- | LA-01 | E. Liddy Glass | NPA   |   1.62%  | 4,279 | new person + candidacy, result 'lost' |
-- | VA-11 | Dianne Blais   | Grn   |   1.22%  | 4,078 | new person + candidacy, result 'lost' |
--
-- ⚠ NOTHING HERE IS CERTIFIED and NOTHING HERE SEATS ANYBODY. Both rows are losses recorded
-- from a media call.
-- 🟢 THIS FILE OVERWRITES NOTHING. It is two INSERTs into `politicians` and two into
-- `race_candidates`; no existing row of any kind is updated or deleted, and a gate below
-- asserts that the six result-less rows already in these two races are still result-less.
--
-- ============================================================================================
-- SOURCES
-- ============================================================================================
-- Vote shares, parties, AP candidate ids and AP race ids are read from AP's own feed,
-- https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04),
-- the same source as `CC_0339`, `CC_0350`, `CC_0351` and `CC_0352`. 🔴 A bare `curl` to that
-- host now returns 403; it needs a browser `User-Agent` and `Referer: https://apnews.com/`.
-- The snapshot read for this file is byte-identical to the one `CC_0351` recorded for these two
-- races, so no count has moved since the losers pass.
--
-- Each person's identity was then established FROM THE PAGE, not from a search summary:
--
--   LA-01, Louisiana Illuminator, "Candidates, amendments on Nov. 3 ballot", read 2026-11-04,
--   https://lailluminator.com/voter-guides/nov-3-2026-election-guide/ - its 1st Congressional
--   District block reads: Candidate (Republican) (R) Randall Arrington - Candidate (No Party)
--   (None) E. "Liddy" Glass - Candidate (Democrat) (D) Lauren Jewett - Candidate (Republican)
--   (R) Steve Scalise. That is AP's four-name ballot, independently.
--
--   VA-11, Virginia Mercury 2026 voter guide, read 2026-11-04,
--   https://virginiamercury.com/voter-guides/contests/2026-general-election-11th-congressional-district/
--   - "Representing the Green Party, Dianne Blais seeks to unseat Democratic incumbent U.S.
--   Rep. James Walkinshaw in Virginia's 11th Congressional District." (The same page already
--   sourced Arthur Purves for `CC_0352`.)
--
-- ⚠ A SEARCH SUMMARY ATTACHED THE WRONG OCCUPATION TO THE WRONG CANDIDATE, AND THE PAGE CAUGHT
-- IT. A summary of the Wikipedia Louisiana page reported Glass as "an Independent, special
-- education teacher". The page itself reads: "E. Glass (Independent)" with no occupation, and
-- "Lauren Jewett (Democratic), special education teacher" on the next line. Jewett's occupation
-- had already been written into `CC_0352` from her own Ballotpedia biography. Nothing about
-- Glass's occupation is recorded here, because nothing establishes it.
--
-- ============================================================================================
-- 🔴 NEITHER PERSON EXISTS IN `politicians`, AND THE WHOLE TABLE WAS SEARCHED, NOT THE RACE
-- ============================================================================================
-- This is the `CC_0352` lesson applied before the fact: Jennifer Balkcom read as "a person we
-- do not hold" only because the losers pass looked for her inside her race, while she sat in
-- `politicians` as a sitting state representative. So both surnames were matched against the
-- ENTIRE table on `full_name` as well as `last_name`, archived rows included:
--
--   ILIKE '%glass%'  - 24 rows. One real person surnamed Glass: Jackie Hope Glass
--                      (57517048-31a9-4974-bb5a-f82c3563a514, Nevada). Different first name,
--                      different state, not this person. The rest are Glassburn / Glasscock /
--                      Glasstein / Douglass / Jaglassian, plus CAL-ACCESS committee rows.
--   ILIKE '%blais%'  - 7 rows. NO person surnamed Blais at all. The rest are CAL-ACCESS
--                      committee names and Blaise Ingoglia, a first name.
--
-- ⚠ Dianne Blais has run before - VA-10 in 2014 and Virginia House of Delegates 40 in 2011
-- (Ballotpedia) - so a historical row was the thing to look for. There is none.
-- 🔴 The duplicate-name guard keys on (first_name, last_name), so 'E. Liddy'/'Glass' does not
-- collide with 'Jackie Hope'/'Glass'. The unique index `race_candidates_race_name_key_uniq`
-- keys on (race_id, candidate_name_key(full_name)); the two new keys are 'liddy glass' and
-- 'dianne blais', and neither matches any key in its race. Both were computed against prod.
--
-- ============================================================================================
-- 🔴 THE TWO COUNTS DISAGREE, AND THAT IS WHY `result_certainty` IS 'called' AND NOT 'certified'
-- ============================================================================================
-- Ballotpedia, read 2026-11-04, reports the same orderings and different numbers:
--   LA-01  Liddy Glass (Unaffiliated)  1.6%,  4,184   vs AP 1.62%,  4,279
--   VA-11  Dianne Blais (G)            1.5%,  2,921   vs AP 1.22%,  4,078
-- Neither is final - Ballotpedia's own VA-11 total (193,618) is well behind AP's, so it is
-- counting a smaller return, not a different election. AP's figures are recorded, because every
-- other row written by this programme carries AP's. ▶ A call and a canvass are two facts; the
-- canvass is a later pass, per state.
--
-- 🟢 BOTH LOSSES ARE INDEPENDENTLY ESTABLISHED, NOT INFERRED FROM "NOT THE WINNER".
--   Ballotpedia LA-01: "Incumbent Steve Scalise (R) won election outright against Lauren Jewett
--   (D), Randall Arrington (R), and Liddy Glass (Unaffiliated) in the primary for U.S. House
--   Louisiana District 1 on November 3, 2026."
--   Ballotpedia VA-11: "Incumbent James Walkinshaw (D) defeated Arthur Purves (R) and Dianne
--   Blais (G) in the general election for U.S. House Virginia District 11 on November 3, 2026."
--
-- 🔴 LOUISIANA'S NOVEMBER CONTEST IS A NONPARTISAN PRIMARY, AND 'lost' IS ONLY RIGHT BECAUSE
-- SCALISE TOOK A MAJORITY. Had no one cleared 50%, the top two would have gone to the
-- 2026-12-12 general and the right result for them would be 'runoff', not 'lost' - which is
-- exactly what LA-05 still is. Scalise took 60.71%, and Ballotpedia records that "the general
-- election scheduled for December 12, 2026, was canceled". So LA-01 is finished and Glass lost.
--
-- ============================================================================================
-- WHAT THIS FILE DOES NOT CLOSE
-- ============================================================================================
-- ⚠ AFTER THIS, EVERY CANDIDATE AP NAMES IN LA-01 AND VA-11 HAS A ROW - BUT THE TWO RACES STILL
-- DO NOT MATCH OUR TABLE, BECAUSE WE HOLD SIX ROWS AP DOES NOT NAME, ALL WITH NO RESULT:
--   LA-01  Jim Long - entered the jungle primary and is listed under "Withdrawn" on Wikipedia.
--   VA-11  Amy Roma, Bree Fram, Michael Van Meter, Nathan Headrick, Stella Pekarsky - the
--          Democratic primary field for a primary that never happened; Ballotpedia records
--          "The Democratic primary scheduled for August 4, 2026, was canceled."
-- They belong to the 215 result-less rows `CC_0351` reported and each needs its own
-- disposition - and `CC_0352` has already shown that "withdrew" and "never filed" look
-- identical here and want opposite acts. None of them is touched by this file, and a gate
-- below asserts all six still read NULL.
-- ⚠ 104 of the 106 AP candidates we hold no row for remain unheld. These were the last two in
-- races this programme had already opened; the rest are a separate pass.
-- ⚠ `result_recorded_at` is still NULL on the 1,009 rows written by `CC_0339`, `CC_0350` and
-- `CC_0351`. This file sets it on its own two rows, as `CC_0352` did. The backfill is still owed.

BEGIN;

CREATE TEMP TABLE seed_people (
  seat        text,
  geo_id      text,
  race_id     uuid,
  full_name   text,
  first_name  text,
  last_name   text,
  result      text,
  person_src  text,
  result_src  text
) ON COMMIT DROP;

INSERT INTO seed_people VALUES
  ('LA-01', '2201', '10a69df9-4fdd-4f33-a6d5-58c6d43d8f03',
   'E. Liddy Glass', 'E. Liddy', 'Glass', 'lost',
   'AP candidate list for the 2026-11-03 US House election in LA-01 (AP candidateID 178730), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). No-party candidate against incumbent Steve Scalise. Listed on the Louisiana Illuminator''s ballot guide for 2026-11-03 as ''Candidate (No Party) (None) E. "Liddy" Glass'' in the 1st Congressional District, https://lailluminator.com/voter-guides/nov-3-2026-election-guide/ (read 2026-11-04), and by Ballotpedia as ''Liddy Glass (Unaffiliated)'', https://ballotpedia.org/Louisiana%27s_1st_Congressional_District_election,_2026 (read 2026-11-04). Name variants across sources: AP ''E. Liddy Glass'', Louisiana Illuminator ''E. "Liddy" Glass'', Ballotpedia ''Liddy Glass'', Wikipedia ''E. Glass''; AP''s spelling is the one recorded here, as for every other row in this programme. No occupation is recorded because no source establishes one. Seeded by CC_0353.',
   'AP race call for the 2026-11-03 election: E. Liddy Glass (NPA) 1.62%, 4,279 votes - DID NOT WIN. AP race 20261103LA20556; Steve Scalise was called the winner at 2026-11-04T03:58:50.646Z with 60.71%, 159,890 votes. https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Louisiana runs a nonpartisan general: Scalise took an outright majority, so the 2026-12-12 runoff was cancelled and this is a final loss rather than a runoff place. Corroborated independently by Ballotpedia, "Incumbent Steve Scalise (R) won election outright against Lauren Jewett (D), Randall Arrington (R), and Liddy Glass (Unaffiliated) in the primary for U.S. House Louisiana District 1 on November 3, 2026", which reports Glass at 1.6%, 4,184 votes on a count that differs from AP''s because neither is final. This person appears on AP''s own candidate list for the race; the loss is not inferred from not being the winner. UNOFFICIAL - this is a race call, not the state canvass.'),

  ('VA-11', '5111', 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e',
   'Dianne Blais', 'Dianne', 'Blais', 'lost',
   'AP candidate list for the 2026-11-03 US House general election, VA-11 (AP candidateID 179330), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Green Party nominee against Democratic incumbent James Walkinshaw and Republican Arthur Purves. Virginia Mercury 2026 voter guide, https://virginiamercury.com/voter-guides/contests/2026-general-election-11th-congressional-district/ (read 2026-11-04): "Representing the Green Party, Dianne Blais seeks to unseat Democratic incumbent U.S. Rep. James Walkinshaw in Virginia''s 11th Congressional District. Blais is a native of Washington state who moved to Virginia''s Fairfax County in 8th grade. She is a former co-president of the League of Women Voters and the American Association of University Women." Previously the Green candidate in VA-10 in 2014 and an independent for Virginia House of Delegates District 40 in 2011 (Ballotpedia); we held no row for her from either. WARNING: the Virginia Mercury page spells the first name ''Diane'' in its summary line and ''Dianne'' in her own entry; AP and Ballotpedia both use ''Dianne'', which is what this row carries. Seeded by CC_0353.',
   'AP race call for the 2026-11-03 general election: Dianne Blais (Grn) 1.22%, 4,078 votes - DID NOT WIN. AP race 20261103VA47021; James Walkinshaw was called the winner at 2026-11-04T02:10:56.310Z with 74.08%, 247,201 votes. https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Corroborated independently by Ballotpedia, "Incumbent James Walkinshaw (D) defeated Arthur Purves (R) and Dianne Blais (G) in the general election for U.S. House Virginia District 11 on November 3, 2026", which reports Blais at 1.5%, 2,921 votes on a smaller and later-counted return. This person appears on AP''s own candidate list for the race; the loss is not inferred from not being the winner. UNOFFICIAL - this is a race call, not the state canvass.');

-- ─── 1. The two people ───────────────────────────────────────────────────────────────────────
-- 🔴 Keyed on (first_name, last_name), the predicate the repo's duplicate-name guard uses.
-- 🔴 `is_incumbent` is set EXPLICITLY and is FALSE for both: neither held the seat, and the
-- column defaults in a direction that hides people from address search.
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT n.full_name, n.first_name, n.last_name, n.person_src, true, false
  FROM seed_people n
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE p.first_name = n.first_name AND p.last_name = n.last_name);

-- ─── 2. The two candidacies ──────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, source, result, result_certainty, result_source, result_recorded_at)
SELECT n.race_id, p.id, n.full_name, n.first_name, n.last_name, false, false,
       'active', n.person_src, n.result, 'called', n.result_src, now()
  FROM seed_people n
  JOIN essentials.politicians p
    ON p.first_name = n.first_name AND p.last_name = n.last_name
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = n.race_id AND rc.politician_id = p.id);

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_created bigint; v_people bigint; v_dupes bigint; v_cands bigint;
  v_la_won bigint; v_va_won bigint; v_la_names text; v_va_names text;
  v_untouched bigint; v_fed_won bigint; v_fed_lost bigint; v_cert bigint; v_orphans bigint;
  v_glass_result text; v_blais_result text;
BEGIN
  -- 🔴 THIS FILE MAY CREATE EXACTLY TWO PEOPLE. A typo in a name would quietly create a third
  -- instead of being caught, and every other count below would still add up.
  SELECT count(*) INTO v_created FROM essentials.politicians WHERE source LIKE '%CC_0353%';
  IF v_created <> 2 THEN
    RAISE EXCEPTION 'CC_0353: % politician row(s) created by this file, expected exactly 2', v_created;
  END IF;

  -- 🔴 ONE ROW PER PERSON.
  SELECT count(*) INTO v_people
    FROM seed_people n JOIN essentials.politicians p
      ON p.first_name = n.first_name AND p.last_name = n.last_name;
  IF v_people <> 2 THEN
    RAISE EXCEPTION 'CC_0353: the two names resolve to % politician row(s), expected 2', v_people;
  END IF;

  SELECT count(*) INTO v_dupes FROM (
    SELECT n.first_name, n.last_name
      FROM seed_people n JOIN essentials.politicians p
        ON p.first_name = n.first_name AND p.last_name = n.last_name
     GROUP BY 1,2 HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0353: % of the two names now has more than one politician row', v_dupes;
  END IF;

  -- The two candidacies, carrying the result this file claims.
  SELECT count(*) INTO v_cands
    FROM seed_people n
    JOIN essentials.politicians p ON p.first_name = n.first_name AND p.last_name = n.last_name
    JOIN essentials.race_candidates rc ON rc.race_id = n.race_id AND rc.politician_id = p.id
   WHERE rc.result = n.result AND rc.result_certainty = 'called'
     AND rc.result_source IS NOT NULL AND btrim(rc.result_source) <> ''
     AND rc.result_recorded_at IS NOT NULL
     AND rc.is_incumbent = false AND rc.is_write_in = false;
  IF v_cands <> 2 THEN
    RAISE EXCEPTION 'CC_0353: % of the 2 candidacies carry the expected result, expected 2', v_cands;
  END IF;

  -- 🔴 NAMED GUARDS: each new row sits in ITS OWN race and reads 'lost'. A race_id typed into
  -- the wrong row would still produce two candidacies and two people.
  SELECT rc.result INTO v_glass_result
    FROM essentials.race_candidates rc
   WHERE rc.race_id = '10a69df9-4fdd-4f33-a6d5-58c6d43d8f03'::uuid AND rc.full_name = 'E. Liddy Glass';
  IF v_glass_result IS DISTINCT FROM 'lost' THEN
    RAISE EXCEPTION 'CC_0353: E. Liddy Glass reads % in LA-01, expected lost', coalesce(v_glass_result, '(missing)');
  END IF;

  SELECT rc.result INTO v_blais_result
    FROM essentials.race_candidates rc
   WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND rc.full_name = 'Dianne Blais';
  IF v_blais_result IS DISTINCT FROM 'lost' THEN
    RAISE EXCEPTION 'CC_0353: Dianne Blais reads % in VA-11, expected lost', coalesce(v_blais_result, '(missing)');
  END IF;

  -- 🔴 ONE WINNER PER RACE, STILL. Adding a loser must not disturb the call.
  SELECT count(*) INTO v_la_won FROM essentials.race_candidates
   WHERE race_id = '10a69df9-4fdd-4f33-a6d5-58c6d43d8f03'::uuid AND result = 'won';
  IF v_la_won <> 1 THEN RAISE EXCEPTION 'CC_0353: LA-01 carries % winners, expected 1', v_la_won; END IF;

  SELECT count(*) INTO v_va_won FROM essentials.race_candidates
   WHERE race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND result = 'won';
  IF v_va_won <> 1 THEN RAISE EXCEPTION 'CC_0353: VA-11 carries % winners, expected 1', v_va_won; END IF;

  -- 🟢 EVERY CANDIDATE AP NAMES IN THESE TWO RACES NOW HAS A ROW. Asserted by name, against
  -- AP's own ballots: LA-01 Scalise/Jewett/Arrington/Glass, VA-11 Walkinshaw/Purves/Blais.
  -- (AP's VA-11 ballot also carries the 'Total Write-ins' aggregate, which is not a person.)
  SELECT string_agg(full_name, ', ' ORDER BY full_name) INTO v_la_names
    FROM essentials.race_candidates
   WHERE race_id = '10a69df9-4fdd-4f33-a6d5-58c6d43d8f03'::uuid
     AND full_name IN ('Steve Scalise','Lauren Jewett','Randall Arrington','E. Liddy Glass');
  IF v_la_names IS DISTINCT FROM 'E. Liddy Glass, Lauren Jewett, Randall Arrington, Steve Scalise' THEN
    RAISE EXCEPTION 'CC_0353: LA-01 holds [%], expected all four AP names', coalesce(v_la_names, '(none)');
  END IF;

  SELECT string_agg(full_name, ', ' ORDER BY full_name) INTO v_va_names
    FROM essentials.race_candidates
   WHERE race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid
     AND full_name IN ('James Walkinshaw','Arthur Purves','Dianne Blais');
  IF v_va_names IS DISTINCT FROM 'Arthur Purves, Dianne Blais, James Walkinshaw' THEN
    RAISE EXCEPTION 'CC_0353: VA-11 holds [%], expected all three AP names', coalesce(v_va_names, '(none)');
  END IF;

  -- 🔴 THIS FILE ADDS ROWS; IT DOES NOT RECLASSIFY ANY. The six rows AP does not name in these
  -- two races must still read NULL - Jim Long in LA-01, and the five VA-11 Democrats whose
  -- primary was cancelled. If one of them had quietly acquired a result, this file reached
  -- further than it says it does.
  SELECT count(*) INTO v_untouched
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN ('10a69df9-4fdd-4f33-a6d5-58c6d43d8f03'::uuid,
                        'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid)
     AND rc.full_name IN ('Jim Long','Amy Roma','Bree Fram','Michael Van Meter',
                          'Nathan Headrick','Stella Pekarsky')
     AND rc.result IS NULL AND rc.result_certainty IS NULL;
  IF v_untouched <> 6 THEN
    RAISE EXCEPTION 'CC_0353: % of the 6 result-less rows in these races are still untouched, expected 6', v_untouched;
  END IF;

  -- 🔴 THE PROGRAMME TOTALS. Winners unchanged at 411; 602 losers + two = 604.
  SELECT count(*) FILTER (WHERE rc.result = 'won'),
         count(*) FILTER (WHERE rc.result = 'lost'),
         count(*) FILTER (WHERE rc.result_certainty = 'certified')
    INTO v_fed_won, v_fed_lost, v_cert
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER');
  IF v_fed_won <> 411 THEN RAISE EXCEPTION 'CC_0353: % federal winners, expected 411 (unchanged)', v_fed_won; END IF;
  IF v_fed_lost <> 604 THEN RAISE EXCEPTION 'CC_0353: % federal losers, expected 604', v_fed_lost; END IF;
  IF v_cert <> 0 THEN RAISE EXCEPTION 'CC_0353: % federal row(s) claim certification', v_cert; END IF;

  -- 🟢 AND NO FEDERAL RACE CARRIES A LOSER WITH NO WINNER - the anomaly CC_0351 pinned and
  -- CC_0352 closed stays closed. Writing a loser is exactly the act that could reopen it.
  SELECT count(*) INTO v_orphans FROM (
    SELECT r.id
      FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices   o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03'
       AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won')  = 0) x;
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION 'CC_0353: % federal race(s) carry a loser with no winner, expected 0', v_orphans;
  END IF;

  RAISE NOTICE 'CC_0353 OK: 2 people created, 2 candidacies recorded lost, LA-01 and VA-11 now hold every candidate AP names';
END $$;

COMMIT;

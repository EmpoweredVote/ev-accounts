-- CC_0454 - 2026-11-03 federal: record the last two races AP has called.
--
-- These are the two seats the 2026-11-18 sweep against AP's live wire found CALLED AND UNHELD.
-- Every other called federal race already carries its result, and all 461 of our winners agree
-- with AP. These two were called AFTER the last results pass and nothing had touched them since
-- they were seeded from a candidate list: all seven rows across the two races carry `result`
-- NULL and `result_source` NULL.
--
-- | Seat   | Person                 | AP id  |   Votes | AP share | result |
-- |--------|------------------------|--------|---------|----------|--------|
-- | NC-03  | Raymond Smith Jr.      | 136139 | 118,434 |  49.43%  | won    |
-- | NC-03  | Gregory F. Murphy  (i) |  67890 | 118,176 |  49.32%  | lost   |
-- | NC-03  | Daniel Cavender        | 166381 |   3,004 |   1.25%  | lost   |
-- | AK-SEN | Mary Peltola           |  70718 | 144,302 |  50.12%  | won    |
-- | AK-SEN | Dan S. Sullivan    (i) |  64262 | 131,844 |  45.80%  | lost   |
-- | AK-SEN | Gerald L. Heikes       |  57566 |   6,105 |   2.12%  | lost   |
-- | AK-SEN | Daniel J. Sullivan Jr. | 177716 |   4,760 |   1.65%  | lost   |
--
-- (i) = the seat's incumbent, per AP's own `metadata[race].incumbents[]`. BOTH SEATS FLIP.
--
-- ⚠ NOTHING HERE IS CERTIFIED AND NOTHING HERE SEATS ANYBODY. Seven rows — two winners and five
-- losers — gain a `result` from a media call. Seating is a separate act against `office_terms`
-- and is deliberately not done here — see "WHY THIS FILE DOES NOT SEAT THEM" below.
-- 🟢 THIS FILE OVERWRITES NOTHING. Seven UPDATEs, each pinned by `race_candidates.id`, each gated
-- on `result IS NULL`. No INSERT, no DELETE, and a pre-gate refuses the whole file if any of the
-- six already carries a result — so no citation can be destroyed. There is no history table for
-- `result_source`, which is why that gate is a refusal and not a warning.
--
-- @incumbency-decision: no-effect - this file writes only `essentials.race_candidates` result
-- columns. It does not touch `essentials.office_terms`, `politicians.is_incumbent` or
-- `race_candidates.is_incumbent`, so the cached incumbency flags cannot drift from it.
--
-- ============================================================================================
-- SOURCES
-- ============================================================================================
-- AP's own feed, read 2026-11-18:
--   https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/
--   {metadata,progress}.json
-- 🔴 A bare `curl` to that host returns 403; it needs a browser `User-Agent` and
-- `Referer: https://apnews.com/`. The two races, extracted verbatim with the join already made,
-- are committed at `backend/data/nc03-ak-senate-2026/ap-calls-2026-11-18.json`.
--
--   NC-03  apRaceID 20261103NC34969  raceCallStatus "Called"  isCertified false
--          calledAt 2026-11-17T20:45:05.431Z   eevp 99
--   AK-SEN apRaceID 20261103AK3079   raceCallStatus "Called"  isCertified false
--          calledAt 2026-11-18T03:19:36.972Z   eevp 99   rankedChoice TRUE
--
-- 🟢 EACH STATE'S OWN RETURN WAS READ TOO, AND BOTH AGREE WITH AP TO THE VOTE. That is what
-- makes these calls safe to record this early; where a second source has disagreed on the
-- numbers before (CC_0353), the file said so instead of pretending otherwise.
--
--   NC State Board of Elections, er.ncsbe.gov contest 1371, read 2026-11-18, "Last County
--   Submit: November 18, 2026 12:35 pm", 190 of 190 precincts:
--       Raymond Smith DEM 118,434 49.43% | Greg Murphy REP 118,176 49.32%
--       Daniel Cavender LIB 3,004 1.25%          -- identical to AP on all three lines.
--
--   Alaska Division of Elections, elections.alaska.gov/enr/26GENR/results/statewide.js, read
--   2026-11-18, updated 11/17/2026 6:09 PM, certified FALSE, 401 of 403 precincts. Committed at
--   `backend/data/nc03-ak-senate-2026/ak-division-of-elections-2026-11-18.json`. Identical to
--   AP on all four candidate lines.
--
-- Passages quoted at length (the concession, the recount statute, Alaska's tabulation notice):
-- `backend/data/nc03-ak-senate-2026/source-extracts-2026-11-18.txt`.
--
-- ============================================================================================
-- 🔴🔴 ALASKA IS RANKED-CHOICE, AND WHETHER THAT MATTERS TURNS ON THE DENOMINATOR
-- ============================================================================================
-- A ranked-choice contest is decided in round one if the leader clears 50% of first-choice
-- votes; otherwise transfers begin and the leader on first preferences CAN lose. So "Peltola is
-- top" is not by itself a result in Alaska, and the usual "the winner is the top vote-getter"
-- gate is not by itself enough.
--
-- ⚠ THIS EXACT RACE IS THE WORKED EXAMPLE OF GETTING IT WRONG. Measured 2026-11-17, Peltola had
-- 141,637 of 283,377 votes counting the aggregate write-in line = 49.98%, which is 52 votes
-- SHORT of a majority; drop the 874 write-ins and the same ballots read 50.14%, 385 OVER. The
-- press reported "50.1%". AP printed 49.98 and held the race at Too Early to Call. One set of
-- ballots, two correct-looking percentages, two different outcomes.
--
-- 🟢 THAT AMBIGUITY IS NOW GONE, AND THAT IS WHY THE RACE COULD BE CALLED. With the fuller
-- count, Peltola clears a majority on BOTH denominators:
--
--       144,302 of 287,011 (Alaska's contest total, write-ins excluded) = 50.2775%  (+796)
--       144,302 of 287,896 (AP's total, 885 write-ins included)         = 50.1230%  (+353)
--
-- So the contest ends in round one and no transfer can reach it. Alaska's own page says ranked-
-- choice tabulation starts 2026-11-18 "for required races"; this is not one of them.
-- ▶ Assertion P9 below RE-DERIVES both of those from the vote counts in this file. It does not
--   trust the percentages, because a percentage is where this race already hid an answer once.
--
-- ============================================================================================
-- 🔴🔴 ALASKA'S BALLOT HOLDS TWO SULLIVANS, AND `result` CANNOT TELL THEM APART
-- ============================================================================================
--   AP  64262 "Dan Sullivan"    (GOP) 131,844 - the SITTING SENATOR, and AP's own incumbents[]
--   AP 177716 "Daniel Sullivan" (UDC)   4,760 - a different man, 1.65%
--
-- Our rows are "Dan S. Sullivan" (`is_incumbent` true) and "Daniel J. Sullivan Jr." (false), and
-- Alaska's own return names them exactly as we do - "Sullivan, Dan S. (REP)" and "Sullivan,
-- Daniel J. Jr." with no party - with the matching vote totals. Three independent sources agree
-- that these are two people.
--
-- 🔴 BOTH LOST, so a swap between them would NOT change either row's `result` and NO ordinary
-- gate would see it. It would simply put 131,844 votes and the words "the seat's incumbent" onto
-- a man who polled 4,760. Assertion P8 exists for that one failure: the row this file pins as AP
-- 64262 must be the row the database flags as the incumbent, and the row pinned as AP 177716
-- must not be. This is the TX-22 lesson - identical twins, surname match, wrong person - caught
-- on the other side of the join.
--
-- ============================================================================================
-- 🔴 NC-03 IS 258 VOTES, WHICH IS INSIDE NORTH CAROLINA'S RECOUNT THRESHOLD
-- ============================================================================================
-- N.C. Gen. Stat. 163-182.7(c)(1): for a nonstatewide ballot item, a candidate may demand a
-- recount where the margin is not more than 1% of the total votes cast. 1% of 239,614 = 2,396.
-- THE MARGIN IS 258 (0.1077%). Murphy was entitled to demand one.
--
-- Three things are nevertheless recorded, and each is sourced:
--   1. Murphy CONCEDED on 2026-11-11, a week before AP's call (NC Newsline, quoted in the
--      extracts file). A concession is not a canvass, but it is a fact about the contest.
--   2. The statutory demand window is "noon on the second business day after the county
--      canvass"; AP called the race at 20:45Z on 2026-11-17, after noon Eastern that day.
--   3. `result_certainty` is 'called'. It is NOT 'certified', and NC has not certified.
--
-- 🔴 WHAT IS *NOT* ASSERTED: that no recount was demanded. No primary source was read that says
-- so, and a search summary is not one. The row says what AP called and what the state's return
-- shows, and the certainty column says it is a call. ▶ If a recount is later demanded and
-- changes this, the correction is a new migration, not a reason to have withheld the result -
-- a session once left 35 Senate seats blank for a day on exactly that reasoning.
--
-- ============================================================================================
-- WHY THIS FILE DOES NOT SEAT THEM
-- ============================================================================================
-- `CC_0340` and `CC_0453` scheduled 461 federal winners into `office_terms` at 2027-01-03.
-- These two seats were left out of both because no result existed to seat from. Recording the
-- result is what unblocks seating; it is not seating.
--
-- Seating is kept separate on purpose. It is a claim to voters that a named person will hold a
-- seat, and NC-03's 258-vote margin sits inside a recount threshold. Writing the result costs
-- nothing if it moves - the column says 'called' and carries its sources. Writing an
-- `office_terms` row for a seat that may yet flip is a different and larger claim, and
-- `seat_officeholder` closes the predecessor's term as a side effect. ▶ Seat these two in their
-- own migration, by preference after NC certifies.
--
-- ============================================================================================

BEGIN;

-- ─── The seven rows, pinned by id ────────────────────────────────────────────
-- Pinned by `race_candidates.id` so that no name, no name-key and no join decides what gets
-- written. Every id was read from production on 2026-11-18.
--
-- Seven rows cover both ballots completely: NC-03 has three candidates and Alaska four. AP's
-- Alaska ballot carries a fifth LINE that is not a person — the 885-vote aggregate
-- `Total Write-ins` — and we hold no row for it, correctly. (AP ballots carry two kinds of
-- write-in and the discriminator is the exact string `Total Write-ins`, not the words
-- "write in"; a named write-in candidate reads `Parkman (write-in)` and IS a person.)

CREATE TEMP TABLE cc0454_calls (
  rc_id         uuid PRIMARY KEY,
  race_id       uuid    NOT NULL,
  seat          text    NOT NULL,
  who           text    NOT NULL,
  ap_cand_id    text    NOT NULL,
  ap_is_incumbent boolean NOT NULL,   -- from AP's own metadata[race].incumbents[]
  result        text    NOT NULL,
  votes         integer NOT NULL,
  vote_pct      numeric NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0454_calls VALUES
  -- NC-03, apRaceID 20261103NC34969, called 2026-11-17T20:45:05.431Z
  ('86850f05-045a-47a9-aa4f-3afa33d43f8e'::uuid, 'd5edae06-65c7-4853-a15b-97731330295c'::uuid,
   'NC-03',  'Raymond Smith Jr.',      '136139', false, 'won',  118434, 49.43),
  ('cfa6c596-4d43-4fcf-b0a1-50a96fb925cf'::uuid, 'd5edae06-65c7-4853-a15b-97731330295c'::uuid,
   'NC-03',  'Gregory F. Murphy',      '67890',  true,  'lost', 118176, 49.32),
  ('34cc68f9-4766-4f8a-a6d6-13231770adba'::uuid, 'd5edae06-65c7-4853-a15b-97731330295c'::uuid,
   'NC-03',  'Daniel Cavender',        '166381', false, 'lost',   3004,  1.25),
  -- AK U.S. Senate, apRaceID 20261103AK3079, called 2026-11-18T03:19:36.972Z, rankedChoice true
  ('0c1e8318-8db1-4269-8f52-6558509dbbd5'::uuid, '96ca077b-c2c9-4394-8a23-c3de6e373e57'::uuid,
   'AK-SEN', 'Mary Peltola',           '70718',  false, 'won',  144302, 50.12),
  ('d2e5e026-7009-49bf-a091-aba5d87f35d1'::uuid, '96ca077b-c2c9-4394-8a23-c3de6e373e57'::uuid,
   'AK-SEN', 'Dan S. Sullivan',        '64262',  true,  'lost', 131844, 45.80),
  ('b6fd37ec-1ceb-446c-9abb-7efb2bdb09bd'::uuid, '96ca077b-c2c9-4394-8a23-c3de6e373e57'::uuid,
   'AK-SEN', 'Gerald L. Heikes',       '57566',  false, 'lost',   6105,  2.12),
  ('21ad7ab4-57fa-4fc2-aaf7-3ef117f4ef49'::uuid, '96ca077b-c2c9-4394-8a23-c3de6e373e57'::uuid,
   'AK-SEN', 'Daniel J. Sullivan Jr.', '177716', false, 'lost',   4760,  1.65);

-- Alaska's aggregate write-in line, which is not a person and is not in the table above. It is
-- named here because assertion P9 needs it: it is the difference between the two denominators.
CREATE TEMP TABLE cc0454_ak_writeins ON COMMIT DROP AS SELECT 885 AS votes;

-- ─── The pre-write snapshot ──────────────────────────────────────────────────
-- Every 2026-11-03 federal candidacy, not just the seven. This is what makes "it changed
-- nothing else" a measurement rather than a claim: the post-verify diffs against it.

CREATE TEMP TABLE cc0454_before ON COMMIT DROP AS
SELECT rc.id, rc.result, rc.result_certainty, rc.result_source, rc.result_recorded_at
  FROM essentials.race_candidates rc
  JOIN essentials.races r     ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices o   ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER');

-- ─── Pre-gates ───────────────────────────────────────────────────────────────

DO $$
DECLARE n int; txt text; v_den_excl int; v_den_incl int; v_win int;
BEGIN
  -- P1. The federal tier is where the last pass left it. If somebody else has moved it while
  --     this file was being written, the deltas asserted at the end are not this file's.
  SELECT count(*) INTO n FROM cc0454_before;
  IF n <> 1690 THEN
    RAISE EXCEPTION 'P1: the 2026-11-03 federal tier holds % candidacies, expected 1690', n;
  END IF;
  SELECT count(*) INTO n FROM cc0454_before WHERE result = 'won';
  IF n <> 461 THEN RAISE EXCEPTION 'P1: federal holds % winners before this file, expected 461', n; END IF;
  SELECT count(*) INTO n FROM cc0454_before WHERE result = 'lost';
  IF n <> 688 THEN RAISE EXCEPTION 'P1: federal holds % losers before this file, expected 688', n; END IF;
  SELECT count(*) INTO n FROM cc0454_before WHERE result IS NOT NULL AND result_recorded_at IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'P1: % federal result row(s) carry no result_recorded_at; CC_0354 regressed', n; END IF;

  -- P2. Every pinned id exists AND sits in the race this file says it does. A mistyped id that
  --     happens to exist would otherwise move a result to another seat.
  SELECT count(*) INTO n
    FROM cc0454_calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id AND rc.race_id = c.race_id;
  IF n <> 7 THEN RAISE EXCEPTION 'P2: only % of the 7 pinned rows exist in their stated race', n; END IF;

  -- P3. A pinned id that now names somebody else means the row was re-used and the pin is stale.
  SELECT string_agg(c.seat || ' expected ' || c.who || ' but row holds ' || rc.full_name, '; ')
    INTO txt FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.full_name <> c.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'P3: a pinned id no longer names the expected candidate: %', txt; END IF;

  -- P4. Nothing here overwrites a result. `result_source` has no history table, so this refuses
  --     rather than warns.
  SELECT count(*) INTO n FROM cc0454_calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.result IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'P4: % of the 7 rows already carry a result; this file overwrites nothing', n; END IF;

  -- P5. Our ballot and AP's are the same size in each race. If ours were larger, "everyone else
  --     lost" would be asserting a result about somebody AP does not list.
  SELECT string_agg(x.seat || ' holds ' || x.n || ' candidacies', '; ') INTO txt
    FROM (SELECT c.seat, c.race_id,
                 (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = c.race_id) AS n
            FROM cc0454_calls c GROUP BY c.seat, c.race_id) x
   WHERE (x.seat = 'NC-03' AND x.n <> 3) OR (x.seat = 'AK-SEN' AND x.n <> 4);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'P5: a race holds a different number of candidacies than AP''s ballot: %', txt; END IF;

  -- P6. Exactly two winners, in two distinct races.
  SELECT count(*) INTO n FROM cc0454_calls WHERE result = 'won';
  IF n <> 2 THEN RAISE EXCEPTION 'P6: this file names % winners, expected 2', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM cc0454_calls WHERE result = 'won';
  IF n <> 2 THEN RAISE EXCEPTION 'P6: the 2 winners sit in % distinct races, expected 2', n; END IF;

  -- P7. The winner is also the top vote-getter. `votes` and `result` are INDEPENDENT fields in
  --     AP's feed, so a transposed pair breaks their agreement and this sees it. Without it
  --     nothing in the file could catch a swap: the write reads this table and so does the
  --     post-verify, and a swapped pair agrees with itself. (CC_0356 learned this on CA-48,
  --     where ballot order was read as a result.)
  --     ⚠ This holds for NC-03 because a U.S. House seat is won on a plurality and Smith has it,
  --       and for AK-SEN only because of P9 below. It is NOT a general rule in a ranked-choice
  --       race, where the first-preference leader can lose on transfers.
  SELECT string_agg(a.seat || ': ' || a.who || ' won on ' || a.votes
                    || ' votes but ' || b.who || ' polled ' || b.votes, '; ')
    INTO txt FROM cc0454_calls a
    JOIN cc0454_calls b ON b.race_id = a.race_id AND b.votes > a.votes
   WHERE a.result = 'won';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'P7: the winner is not the top vote-getter: %', txt; END IF;

  -- P8. 🔴 THE TWO SULLIVANS. Both lost, so `result` cannot tell a swap apart — but the vote
  --     counts and the word "incumbent" in the citation can land on the wrong man. AP's
  --     incumbents[] names candidateID 64262; the database flags exactly one Sullivan row. They
  --     must be the same row.
  SELECT string_agg(c.seat || ' ' || c.who || ' (AP ' || c.ap_cand_id || '): AP says incumbent='
                    || c.ap_is_incumbent || ', our row says ' || rc.is_incumbent, '; ')
    INTO txt FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.is_incumbent IS DISTINCT FROM c.ap_is_incumbent;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'P8: AP and our rows disagree about who the incumbent is: %', txt;
  END IF;
  -- And there really are two of them, or the gate above is guarding nothing.
  SELECT count(*) INTO n FROM cc0454_calls WHERE seat = 'AK-SEN' AND who LIKE '%Sullivan%';
  IF n <> 2 THEN RAISE EXCEPTION 'P8: expected 2 Sullivans on the Alaska ballot, found %', n; END IF;

  -- P9. 🔴 ALASKA ENDS IN ROUND ONE. Re-derived from the vote counts, not read off a percentage
  --     — a percentage is where this race hid the answer on 2026-11-17, when the same ballots
  --     read 49.98% or 50.14% depending on whether the 885 write-ins were under the line.
  --     BOTH denominators must give Peltola a majority, or the ranked-choice rounds can still
  --     move this and the call must not be recorded as final.
  SELECT votes INTO v_win FROM cc0454_calls WHERE seat = 'AK-SEN' AND result = 'won';
  SELECT sum(votes) INTO v_den_excl FROM cc0454_calls WHERE seat = 'AK-SEN';
  SELECT v_den_excl + (SELECT votes FROM cc0454_ak_writeins) INTO v_den_incl;
  IF v_den_excl <> 287011 THEN
    RAISE EXCEPTION 'P9: Alaska candidate lines sum to %, Division of Elections says 287011', v_den_excl;
  END IF;
  IF v_den_incl <> 287896 THEN
    RAISE EXCEPTION 'P9: Alaska total incl. write-ins is %, AP says 287896', v_den_incl;
  END IF;
  IF v_win * 2 <= v_den_excl THEN
    RAISE EXCEPTION 'P9: Peltola has % of % excluding write-ins — NOT a majority, so ranked-choice rounds decide this race', v_win, v_den_excl;
  END IF;
  IF v_win * 2 <= v_den_incl THEN
    RAISE EXCEPTION 'P9: Peltola has % of % including the 885 write-ins — NOT a majority, so ranked-choice rounds decide this race', v_win, v_den_incl;
  END IF;

  RAISE NOTICE 'CC_0454: pre-gates passed. Alaska majority holds on both denominators (% of % and % of %).',
    v_win, v_den_excl, v_win, v_den_incl;
END $$;

-- ─── The write ───────────────────────────────────────────────────────────────
-- `result_recorded_at` is `now()`: a MEASURED instant, taken as the row is written. Do not reach
-- for `updated_at` later to date these — no trigger maintains it.
--
-- The citation names the person, the AP candidate id, the count, the share, the AP race id, the
-- call time, both sources and the words "not the state canvass". The two winners' citations also
-- say whom they beat; `npm run check:incumbent-claims` tests every such sentence against the
-- rows the database says lost that race, so the claim cannot drift from the data.

UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_certainty   = 'called',
       result_recorded_at = now(),
       result_source      =
         c.who || ' (AP candidateID ' || c.ap_cand_id || '), ' || c.votes || ' votes, '
         || c.vote_pct || '% — '
         || CASE WHEN c.result = 'won' THEN
                 'WON, defeating incumbent '
                 || (SELECT w.who FROM cc0454_calls w
                      WHERE w.race_id = c.race_id AND w.ap_is_incumbent) || '. '
            ELSE 'LOST. ' END
         || 'AP race ' || CASE c.seat WHEN 'NC-03' THEN '20261103NC34969 called 2026-11-17T20:45:05.431Z'
                                      ELSE '20261103AK3079 called 2026-11-18T03:19:36.972Z' END
         || CASE c.seat WHEN 'AK-SEN' THEN
              ' (ranked-choice; decided in round one — 144,302 of 287,011 excl. write-ins = 50.28%, '
              || 'and of 287,896 incl. them = 50.12%, a majority either way, so no transfers)'
            ELSE
              ' (margin 258 votes of 239,614 = 0.11%, inside the 1% recount threshold of '
              || 'N.C.G.S. 163-182.7(c)(1); the incumbent conceded 2026-11-11)' END
         || '. Sources: https://interactives.apelections.org/election-results/data-live/2026-11-03/'
         || 'results/national/progress.json, read 2026-11-18, and '
         || CASE c.seat WHEN 'NC-03' THEN 'the NC State Board of Elections return at er.ncsbe.gov '
                                          || '(contest 1371, 190/190 precincts), which agrees to the vote'
                        ELSE 'the Alaska Division of Elections return at '
                             || 'elections.alaska.gov/enr/26GENR (401/403 precincts), which agrees to the vote' END
         || '. This is a media call confirmed by the state''s unofficial return, NOT the state '
         || 'canvass — nothing here is certified. CC_0454'
  FROM cc0454_calls c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE n int; txt text;
BEGIN
  -- 1. Exactly the seven rows changed, and every changed row is one of the seven.
  SELECT count(*) INTO n FROM cc0454_before b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result IS DISTINCT FROM b.result
      OR rc.result_certainty IS DISTINCT FROM b.result_certainty
      OR rc.result_source IS DISTINCT FROM b.result_source
      OR rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at;
  IF n <> 7 THEN RAISE EXCEPTION 'V1: % federal row(s) changed, expected exactly 7', n; END IF;

  SELECT count(*) INTO n FROM cc0454_before b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE (rc.result IS DISTINCT FROM b.result
       OR rc.result_certainty IS DISTINCT FROM b.result_certainty
       OR rc.result_source IS DISTINCT FROM b.result_source
       OR rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at)
     AND rc.id NOT IN (SELECT rc_id FROM cc0454_calls);
  IF n <> 0 THEN RAISE EXCEPTION 'V1: % row(s) outside the pinned seven were changed', n; END IF;

  -- 2. Each of the seven holds the result this file names.
  SELECT string_agg(c.seat || ' ' || c.who || ' = ' || coalesce(rc.result,'NULL'), '; ')
    INTO txt FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS DISTINCT FROM c.result;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'V2: a pinned row does not hold its stated result: %', txt; END IF;

  -- 3. Certainty, citation and timestamp on all seven; and the citation names its own source,
  --    its own migration and its own candidate — not a generic string.
  SELECT count(*) INTO n FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_certainty = 'called'
     AND rc.result_recorded_at IS NOT NULL
     AND rc.result_source LIKE '%interactives.apelections.org%'
     AND rc.result_source LIKE '%CC_0454%'
     AND rc.result_source LIKE '%NOT the state canvass%'
     AND position(c.who in rc.result_source) > 0
     AND position(c.ap_cand_id in rc.result_source) > 0;
  IF n <> 7 THEN RAISE EXCEPTION 'V3: only % of the 7 rows carry certainty, a self-naming citation and a timestamp', n; END IF;

  -- 4. No row claims a canvass. Neither state has certified.
  SELECT count(*) INTO n FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION 'V4: % of the 7 rows claim something other than a call', n; END IF;

  -- 5. Both races now come out whole: one winner, nobody undecided.
  SELECT string_agg(x.seat || ': ' || x.won || ' winner(s), ' || x.undecided || ' undecided', '; ')
    INTO txt FROM (
      SELECT c.seat,
             (SELECT count(*) FROM essentials.race_candidates rc
               WHERE rc.race_id = c.race_id AND rc.result = 'won')  AS won,
             (SELECT count(*) FROM essentials.race_candidates rc
               WHERE rc.race_id = c.race_id AND rc.result IS NULL)  AS undecided
        FROM cc0454_calls c GROUP BY c.seat, c.race_id) x
   WHERE x.won <> 1 OR x.undecided <> 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'V5: a race did not come out with one winner and nobody undecided: %', txt; END IF;

  -- 6. Both incumbents are recorded as having LOST. Both seats flip; if either reads otherwise
  --    the citations written above ("defeating incumbent …") contradict the data.
  SELECT string_agg(c.seat || ' incumbent ' || c.who || ' = ' || coalesce(rc.result,'NULL'), '; ')
    INTO txt FROM cc0454_calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE c.ap_is_incumbent AND rc.result IS DISTINCT FROM 'lost';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'V6: an incumbent this file calls defeated is not recorded as lost: %', txt; END IF;

  -- 7. The federal tier moved by exactly two winners and five losers.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER') AND rc.result = 'won';
  IF n <> 463 THEN RAISE EXCEPTION 'V7: federal holds % winners after this file, expected 463', n; END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER') AND rc.result = 'lost';
  IF n <> 693 THEN RAISE EXCEPTION 'V7: federal holds % losers after this file, expected 693', n; END IF;

  -- 8. No 2026-11-03 federal race holds a loser and no winner, and none holds two winners.
  --    Those are the two shapes a half-applied result pass leaves behind.
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03'
       AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won')  = 0) z;
  IF n <> 0 THEN RAISE EXCEPTION 'V8: % federal race(s) hold a loser and no winner', n; END IF;

  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03'
       AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     GROUP BY r.id HAVING count(*) FILTER (WHERE rc.result = 'won') > 1) z;
  IF n <> 0 THEN RAISE EXCEPTION 'V8: % federal race(s) hold more than one winner', n; END IF;

  -- 9. Neither of these two seats is seated by this file. Seating is a separate migration.
  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.races r ON r.office_id = t.office_id
   WHERE r.id IN (SELECT DISTINCT race_id FROM cc0454_calls)
     AND t.term_start = DATE '2027-01-03';
  IF n <> 0 THEN RAISE EXCEPTION 'V9: % office_terms row(s) at 2027-01-03 exist for these seats; this file must not seat anybody', n; END IF;

  RAISE NOTICE 'CC_0454: 7 rows written — NC-03 and the Alaska Senate are recorded. Federal is now 463 won / 693 lost, 470 races, none half-decided. NOBODY IS SEATED.';
END $$;

COMMIT;

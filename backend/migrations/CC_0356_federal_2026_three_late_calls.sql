-- CC_0356 — 2026-11-03 US House: the three results AP called after CC_0351 ran.
--
-- WHAT THIS IS
-- ─────────────────────────────────────────────────────────────────────────────
-- `CC_0339` (Senate winners), `CC_0350` (House winners) and `CC_0351` (losers, both
-- chambers) recorded every federal result the Associated Press had called by
-- 2026-11-05 01:12 UTC. AP has called three more House races since, so this file
-- records them and nothing else.
--
--   CA-47  Dave Min (Dem) HELD the seat                 called 2026-11-05T01:15:59.925Z
--   CA-48  Marni von Wilpert (Dem) FLIPPED a GOP seat   called 2026-11-05T01:32:45.566Z
--   NV-2   Teresa F. Benitez-Thompson (Dem) FLIPPED     called 2026-11-05T02:29:25.426Z
--
-- Seven candidacies: 3 won and 4 lost. Federal goes 411 → 414 won, 604 → 608 lost.
--
-- 🟢 THIS FILE OVERWRITES NOTHING. All seven rows carry `result IS NULL` today
--    (measured 2026-11-05, and the pre-gate re-measures it inside the transaction).
--    There is therefore no prior value to record in this header, and no companion
--    column holding a statement about a result that is being replaced — which is the
--    defect `CC_0354` had to repair on 155 rows. The `UPDATE` is still guarded on
--    `result IS NULL` so a re-run cannot silently overwrite a later, better value.
--
-- 🔴 THE WINNER COMES FROM AP'S `winner` FLAG IN `progress.json`, NOT FROM THE
--    CANDIDATE LIST IN `metadata.json`. `metadata.json` lists candidates in BALLOT
--    ORDER and says nothing about who won. Reading the first-listed candidate as the
--    winner gets CA-48 exactly backwards: ballot order there is Desmond, von Wilpert,
--    and the winner is von Wilpert. That mistake was made once while preparing this
--    migration, off a correct feed, and caught by reading the flag.
--
-- ⚠ A CALL IS NOT A CANVASS. `result_certainty` is `called`; AP reports
--   `isCertified: false` for all three, and for every other federal race today.
--   Counting is still live — CA-48 is at 53.72% of the expected vote. A call is AP's
--   judgement that the outcome cannot change, not the state's certificate. The
--   `certified` upgrade is a separate, later pass per state.
--
-- ⚠ NEITHER CA-48 NOR NV-2 HAS ITS INCUMBENT ON THE BALLOT. AP's incumbent of record
--   is Darrell Issa (GOP) in CA-48 and Mark Amodei (GOP) in NV-2, and neither appears
--   among that race's candidates, in AP's data or in ours. So `is_incumbent = false`
--   on all four of those rows is correct and is left alone. CA-47 is the opposite
--   case: Dave Min is both AP's incumbent of record and the winner, and our row
--   already reads `is_incumbent = true`. This file changes no `is_incumbent` value.
--
-- ⚠ OUR CA-47 ROW IS NAMED `Jenny Le Roux`; AP WRITES `Jenny Rae Le Roux`. Same
--   person — AP carries the middle name, our seeding source (Wikipedia) does not.
--   Renaming is out of scope here and the row is pinned by id, not by name, so the
--   difference cannot mis-target the write.
--
-- SOURCE
-- ─────────────────────────────────────────────────────────────────────────────
-- https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/metadata.json
-- https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json
-- Both fetched 2026-11-05. The joined response for these three races is committed
-- verbatim at `backend/data/federal-2026-late-calls/ap-2026-11-05.json`, because a
-- live feed is overwritten in place and nothing else would let a reader check this.
-- ⚠ A bare `curl` gets 403; the feed needs a browser User-Agent plus
--   `Referer: https://apnews.com/`, and `--compressed` or the body is unreadable.
--
-- WHAT AP REPORTS, ROW BY ROW
-- ─────────────────────────────────────────────────────────────────────────────
--   seat   AP id    candidate                     party  pct     result   EEVP
--   CA-47  66599    Dave Min                      Dem    56.90   won      62.30
--   CA-47  69777    Jenny Rae Le Roux             GOP    43.10   lost
--   CA-48  172653   Marni von Wilpert             Dem    59.50   won      53.72
--   CA-48  172645   Jim Desmond                   GOP    40.50   lost
--   NV-2   131937   Teresa F. Benitez-Thompson    Dem    50.26   won      92.67
--   NV-2   132830   David Flippo                  GOP    44.39   lost
--   NV-2   166655   Lynn Chapman                  IAP     5.35   lost
--
-- 🔴 THE LOSERS COME FROM AP'S OWN BALLOT FOR EACH RACE, NOT FROM "EVERYONE WHO IS
--    NOT THE WINNER" IN OUR TABLE. Those two sets are equal in these three races —
--    asserted by the pre-gate, which refuses to run if any race's candidate count
--    disagrees with AP's — but they are not the same claim, and in LA-01 and VA-11
--    they were not equal.
--
-- Party is deliberately absent: party lives on `races.primary_party`, never on
-- `race_candidates` (this repo is antipartisan by design). It is in the table above
-- only to identify the people.
--
-- A GATE OF THIS FILE'S OWN FIRED ON THE FIRST DRY RUN, AND IT WAS THE GATE THAT WAS
-- WRONG — RECORDED HERE BECAUSE IT FOUND SOMETHING
-- ─────────────────────────────────────────────────────────────────────────────
-- Post-verify check 6 first read "no race ANYWHERE holds a loser and no winner" and
-- failed the dry run with `24 race(s) hold a loser and no winner`. The write was not
-- the cause: prod is unchanged, and measuring the 24 shows **none of them is in this
-- election**.
--
--   2026-05-02   3 races   (TX municipal)
--   2026-06-02  20 races   (CA statewide primary; 12 of them have no office/district row)
--   2026-08-18   1 race    (AK US Senate primary)
--   2026-11-03   0 races   ← the tier this file writes to
--
-- 🔴 THE BROAD VERSION ASKED A QUESTION THAT IS WRONG FOR A PRIMARY. In a primary the
--    winner's row reads `advanced`, not `won`, so "losers and no winner" is the NORMAL
--    and correct shape there — 11 of the 24 hold exactly that. Check 6 is therefore
--    scoped to the 2026-11-03 federal tier, where `won` is the right marker.
-- ⚠ THE REMAINING 13 ARE A REAL, SEPARATE QUESTION AND ARE NOT CLOSED BY THIS FILE:
--   losers recorded in an earlier primary with neither a winner nor an advancer beside
--   them. They predate this programme, they are not in this election, and 12 of the 20
--   June rows cannot even be joined to an office. Someone should look; it is not this
--   migration's business to decide what they are, and widening a gate until it passes
--   would have hidden them.

BEGIN;

-- ─── The seven rows, pinned by id ────────────────────────────────────────────
-- Pinned by `race_candidates.id` so that no name, no name-key and no join decides
-- what gets written. Each id was read from production on 2026-11-05.

CREATE TEMP TABLE calls (
  rc_id        uuid PRIMARY KEY,
  race_id      uuid    NOT NULL,
  seat         text    NOT NULL,
  who          text    NOT NULL,
  ap_cand_id   text    NOT NULL,
  result       text    NOT NULL,
  vote_pct     numeric NOT NULL
) ON COMMIT DROP;

INSERT INTO calls VALUES
  ('962b5359-bec8-4978-a52f-a2962a4bdd8a'::uuid, 'ccdca7a6-eb1c-4c20-8651-0c1ba6c30d6c'::uuid,
   'CA-47', 'Dave Min',                   '66599',  'won',  56.90),
  ('b3bc6a9d-de4c-44b3-a63e-c73053992a20'::uuid, 'ccdca7a6-eb1c-4c20-8651-0c1ba6c30d6c'::uuid,
   'CA-47', 'Jenny Le Roux',              '69777',  'lost', 43.10),
  ('cfde6cca-e97e-430a-b659-b054eb455c34'::uuid, '9770ac95-8777-41a2-9006-937ba5e14ba3'::uuid,
   'CA-48', 'Marni von Wilpert',          '172653', 'won',  59.50),
  ('34e60d4b-6d93-4c41-939e-8b19e36a7d86'::uuid, '9770ac95-8777-41a2-9006-937ba5e14ba3'::uuid,
   'CA-48', 'Jim Desmond',                '172645', 'lost', 40.50),
  ('ce05df57-a034-4bd7-94aa-d98d94bcfcc9'::uuid, '0c470cc0-5250-43f1-b7f7-57778cadacc6'::uuid,
   'NV-2',  'Teresa Benitez-Thompson',    '131937', 'won',  50.26),
  ('fddb93e4-cc29-4fe9-847f-416a2bed3616'::uuid, '0c470cc0-5250-43f1-b7f7-57778cadacc6'::uuid,
   'NV-2',  'David Flippo',               '132830', 'lost', 44.39),
  ('08dfb911-9ddc-4c0d-85a2-fb14884a9160'::uuid, '0c470cc0-5250-43f1-b7f7-57778cadacc6'::uuid,
   'NV-2',  'Lynn Chapman',               '166655', 'lost',  5.35);

-- ─── The pre-write snapshot ──────────────────────────────────────────────────
-- Every federal 2026 candidacy, not just the seven. This is what makes "it changed
-- nothing else" a measurement instead of a claim: the post-verify diffs against it.

CREATE TEMP TABLE before_rows ON COMMIT DROP AS
SELECT rc.id,
       rc.result,
       rc.result_certainty,
       rc.result_source,
       rc.result_recorded_at
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections e  ON e.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER');

-- ─── Pre-gate: refuse to write if the ground has moved ───────────────────────

DO $$
DECLARE
  n int;
  txt text;
BEGIN
  SELECT count(*) INTO n FROM before_rows;
  IF n <> 1689 THEN
    RAISE EXCEPTION 'the federal 2026 tier holds % candidacies, expected 1689', n;
  END IF;

  -- Every pinned id must exist, and must sit in the race this file says it does.
  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id AND rc.race_id = c.race_id;
  IF n <> 7 THEN
    RAISE EXCEPTION 'only % of the 7 pinned rows exist in their stated race', n;
  END IF;

  -- The name is not what targets the write, but a pinned id that now names someone
  -- else means the row was re-used and the pin is stale.
  SELECT string_agg(c.seat || ' ' || c.who || ' <> ' || rc.full_name, '; ')
    INTO txt
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.full_name <> c.who;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'a pinned id no longer names the expected candidate: %', txt;
  END IF;

  -- Nothing here overwrites a result.
  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '% of the 7 rows already carry a result; this file overwrites nothing', n;
  END IF;

  -- AP's ballot and ours must be the same size in each race, or "the losers are
  -- everyone else" is not a safe reading of AP's list.
  SELECT string_agg(x.seat || ' has ' || x.n || ' candidacies', '; ')
    INTO txt
    FROM (SELECT c.seat, c.race_id, count(*) OVER () AS dummy,
                 (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = c.race_id) AS n
            FROM calls c GROUP BY c.seat, c.race_id) x
   WHERE (x.seat = 'CA-47' AND x.n <> 2)
      OR (x.seat = 'CA-48' AND x.n <> 2)
      OR (x.seat = 'NV-2'  AND x.n <> 3);
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'a race holds a different number of candidacies than AP''s ballot: %', txt;
  END IF;

  -- 🔴 THE WINNER MUST ALSO BE THE TOP VOTE-GETTER AP REPORTS.
  -- Without this, nothing in the file could catch a transposed winner: the write
  -- reads `calls`, the post-verify reads `calls`, and a swapped pair agrees with
  -- itself. `vote_pct` and the `winner` flag are two INDEPENDENT fields in AP's
  -- feed, so a transposition breaks their agreement and this gate sees it. That is
  -- the exact mistake made while preparing this file (CA-48, ballot order read as a
  -- result), and it is why this check exists.
  -- ⚠ This holds because all three races have a majority winner and a single round.
  --   It is NOT a general rule — a plurality or ranked-choice race can be called for
  --   someone who is not top on first preferences. Do not copy it unexamined.
  SELECT string_agg(a.seat || ': ' || a.who || ' won on ' || a.vote_pct
                    || '% but ' || b.who || ' polled ' || b.vote_pct || '%', '; ')
    INTO txt
    FROM calls a
    JOIN calls b ON b.race_id = a.race_id AND b.vote_pct > a.vote_pct
   WHERE a.result = 'won';
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'the winner is not the top vote-getter: %', txt;
  END IF;

  -- Exactly one winner per race, in this file.
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 3 THEN
    RAISE EXCEPTION 'this file names % winners, expected 3', n;
  END IF;
  SELECT count(DISTINCT race_id) INTO n FROM calls WHERE result = 'won';
  IF n <> 3 THEN
    RAISE EXCEPTION 'the 3 winners sit in % distinct races, expected 3', n;
  END IF;

  -- The federal tier must be where CC_0351 left it.
  SELECT count(*) INTO n FROM before_rows WHERE result = 'won';
  IF n <> 411 THEN
    RAISE EXCEPTION 'federal holds % winners before this file, expected 411', n;
  END IF;
  SELECT count(*) INTO n FROM before_rows WHERE result = 'lost';
  IF n <> 604 THEN
    RAISE EXCEPTION 'federal holds % losers before this file, expected 604', n;
  END IF;

  -- CC_0354 left no federal result undated. If that has regressed, stop.
  SELECT count(*) INTO n
    FROM before_rows WHERE result IS NOT NULL AND result_recorded_at IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '% federal result row(s) carry no result_recorded_at; CC_0354 regressed', n;
  END IF;
END $$;

-- ─── The write ───────────────────────────────────────────────────────────────
-- `result_recorded_at` is `now()`: a MEASURED instant, taken as the row is written.
-- Do not reach for `updated_at` later to date these — no trigger maintains it. See
-- the column comment and `backend/data/federal-2026-recorded-at-backfill/NOTES.md`.

UPDATE essentials.race_candidates rc
   SET result            = c.result,
       result_certainty  = 'called',
       result_source     = 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0356)',
       result_recorded_at = now()
  FROM calls c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── Post-verify ─────────────────────────────────────────────────────────────

DO $$
DECLARE
  n int;
  txt text;
BEGIN
  -- 1. Exactly the seven rows changed, and every changed row is one of the seven.
  SELECT count(*) INTO n
    FROM before_rows b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result            IS DISTINCT FROM b.result
      OR rc.result_certainty  IS DISTINCT FROM b.result_certainty
      OR rc.result_source     IS DISTINCT FROM b.result_source
      OR rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at;
  IF n <> 7 THEN
    RAISE EXCEPTION '% federal row(s) changed, expected exactly 7', n;
  END IF;

  SELECT count(*) INTO n
    FROM before_rows b
    JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE (rc.result IS DISTINCT FROM b.result
       OR rc.result_certainty IS DISTINCT FROM b.result_certainty
       OR rc.result_source IS DISTINCT FROM b.result_source
       OR rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at)
     AND rc.id NOT IN (SELECT rc_id FROM calls);
  IF n <> 0 THEN
    RAISE EXCEPTION '% row(s) outside the pinned seven were changed', n;
  END IF;

  -- 2. Each of the seven holds the result this file names, dated and cited.
  SELECT string_agg(c.seat || ' ' || c.who || ' = ' || coalesce(rc.result,'NULL'), '; ')
    INTO txt
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS DISTINCT FROM c.result;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'a pinned row does not hold its stated result: %', txt;
  END IF;

  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_certainty = 'called'
     AND rc.result_recorded_at IS NOT NULL
     AND rc.result_source LIKE '%interactives.apelections.org%'
     AND rc.result_source LIKE '%CC_0356%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'only % of the 7 rows carry certainty, citation and timestamp', n;
  END IF;

  -- 3. No row claims a canvass. AP has certified nothing.
  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN
    RAISE EXCEPTION '% of the 7 rows claim something other than a call', n;
  END IF;

  -- 4. Each of the three races now has exactly one winner and no one left undecided.
  SELECT string_agg(x.seat || ': ' || x.won || ' winner(s), ' || x.undecided || ' undecided', '; ')
    INTO txt
    FROM (SELECT c.seat,
                 (SELECT count(*) FROM essentials.race_candidates rc
                   WHERE rc.race_id = c.race_id AND rc.result = 'won')    AS won,
                 (SELECT count(*) FROM essentials.race_candidates rc
                   WHERE rc.race_id = c.race_id AND rc.result IS NULL)    AS undecided
            FROM calls c GROUP BY c.seat, c.race_id) x
   WHERE x.won <> 1 OR x.undecided <> 0;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'a race did not come out with one winner and nobody undecided: %', txt;
  END IF;

  -- 5. The federal tier moved by exactly three winners and four losers.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     AND rc.result = 'won';
  IF n <> 414 THEN
    RAISE EXCEPTION 'federal holds % winners after this file, expected 414', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices o    ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     AND rc.result = 'lost';
  IF n <> 608 THEN
    RAISE EXCEPTION 'federal holds % losers after this file, expected 608', n;
  END IF;

  -- 6. No 2026-11-03 federal race holds a loser and no winner. That is the shape a
  --    half-applied result pass leaves behind.
  --    ⚠ SCOPED TO THIS ELECTION ON PURPOSE — see the note at the foot of the header.
  SELECT count(*) INTO n
    FROM (SELECT r.id
            FROM essentials.races r
            JOIN essentials.elections e  ON e.id = r.election_id
            JOIN essentials.offices o    ON o.id = r.office_id
            JOIN essentials.districts d  ON d.id = o.district_id
            JOIN essentials.race_candidates rc ON rc.race_id = r.id
           WHERE e.election_date = DATE '2026-11-03'
             AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
           GROUP BY r.id
          HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
             AND count(*) FILTER (WHERE rc.result = 'won')  = 0) z;
  IF n <> 0 THEN
    RAISE EXCEPTION '% federal 2026-11-03 race(s) hold a loser and no winner', n;
  END IF;

  -- 7. Nothing can be recorded before the polls closed.
  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_recorded_at < TIMESTAMPTZ '2026-11-04 00:00:00+00';
  IF n <> 0 THEN
    RAISE EXCEPTION '% row(s) claim to have been recorded before election day', n;
  END IF;

  RAISE NOTICE 'CC_0356 OK: CA-47, CA-48 and NV-2 recorded — 3 won, 4 lost; federal now 414 won / 608 lost.';
END $$;

COMMIT;

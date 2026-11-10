-- CC_0358 — Texas 2026 state executives: create the three races AP covers, seed the four
--           candidates we hold no row for, and record AP's called results.
--
-- WHY THIS FILE EXISTS: CC_0357 recorded 18 state-executive results and reported the tier
--   done. It was not. CC_0357 could only touch races we ALREADY HELD, and Texas — like 31
--   other states — holds the SEATS and their current officeholders but has NO 2026 race
--   rows at all. AP has called 98 state-executive races nationally; we had recorded 18.
--   Measured 2026-11-05: 76 called races sit on seats we hold with no race row, 4 on seats
--   we do not hold, 6 are still uncalled. This file closes Texas, as the worked pattern.
--
-- WHAT IT WRITES — nothing is updated or deleted; every statement is an INSERT:
--   4 politicians · 3 races · 10 candidacies (3 won, 7 lost)
--
--   Texas Governor             AP 20261103TX45901  eevp=99  🔴 FLIPPED SEAT
--     🏆  52.82%  Gina Hinojosa      5,230,929  existing person
--         45.69%  Greg Abbott        4,524,955  existing person  (AP: incumbent)
--           1.5%  Pat Dixon          148,096    NEW person
--   Texas Lieutenant Governor  AP 20261103TX45902  eevp=99
--     🏆  51.73%  Vikki Goodwin      5,083,719  existing person
--         45.64%  Dan Patrick        4,485,059  existing person  (AP: incumbent)
--          1.73%  Anthony Cristo     170,464    NEW person
--           0.9%  Kevin McCormick    88,044     NEW person
--   Texas Attorney General     AP 20261103TX45903  eevp=99
--     🏆  52.37%  Nathan Johnson     5,133,762  existing person
--         45.94%  Mayes Middleton    4,502,859  existing person
--          1.69%  Tom Oxford         165,574    NEW person
--
-- SOURCES
--   Vote shares, vote counts, parties, AP candidate ids and the winner flag: AP's feed,
--   fetched 2026-11-05. 🔴 The winner is winner:"X" in progress.json; metadata.json is
--   ballot order and names nobody. ⚠ progress.json's "candidates" is an ARRAY while
--   metadata.json's is an OBJECT MAP — indexing one as the other returns undefined for
--   every candidate and reads as "no results" (it did, in CC_0357's first run).
--   The joined response for these three races is saved verbatim beside this file.
--
--   The four NEW people's identity and party were established FROM A PAGE, not from a
--   search summary: Ballotpedia, "Texas state executive official elections, 2026",
--   read 2026-11-05, which lists each in the general-election table for their race.
--   🔴 THAT PAGE IS AUTHORITATIVE FOR IDENTITY AND STALE FOR NUMBERS. Its Governor table
--     reads Hinojosa 56.3% on 4,219,438 votes; AP has 52.82% on 5,230,929 at 99% counted.
--     Ballotpedia is mid-count. NOT ONE NUMBER IN THIS FILE COMES FROM IT.
--   🟢 It also settled a contradiction: a web search said Mike Collier (Ind.) was on the
--     Lieutenant Governor ballot and AP did not list him. The page files him under
--     "Withdrawn or disqualified candidates". AP's ballot is right; the summary was stale.
--
-- ⚠ THIS DOES NOT FINISH TEXAS, AND THE REMAINDER IS NAMED:
--   · Texas Railroad Commissioner — AP CALLED IT (Jon Rosenthal (Dem) 52.51%, Bo French
--     (GOP) 45.55%, Arthur DiBianca (Lib) 1.93%) and WE HOLD NO SUCH OFFICE. Creating one
--     means a new district + office + a decision about its current holder, which is an
--     occupancy act with its own sourcing bar. NOT DONE HERE.
--   · Texas Comptroller, Land Commissioner and Agriculture Commissioner — we hold all
--     three seats, all three were on the 2026 ballot, and AP publishes NO race for any of
--     them. They need a non-AP source.
--   · WRITE-IN CANDIDATES ARE NOT IN AP'S BALLOT. Ballotpedia lists Edward Giles (Ind.,
--     write-in, 0 votes) for Governor and Stephen Samuelson (Ind., write-in, 751) and
--     Arturo Espinosa for Lieutenant Governor. This file seeds AP's ballot only, so those
--     rows are absent rather than wrong. Said out loud so nobody reads the ballot as whole.
--
-- A CALL IS NOT A CANVASS: result_certainty is 'called' on all 10. AP reports
--   isCertified:false for all three races. The 'certified' upgrade is a separate pass.
--
-- 🔴 is_incumbent IS SET EXPLICITLY ON EVERY ROW, from AP's own incumbent flag, because it
--   is a cached flag the incumbents-only reads filter on and a seeded person who omits it
--   is HIDDEN from address search. Abbott (Governor) and Patrick (Lt Governor) are AP's
--   incumbents; the Attorney General race has none, because Ken Paxton ran for the US
--   Senate instead — an open seat, not a missing row.
--
-- Applied to production 2026-11-05 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The four people we hold no row for ───
CREATE TEMP TABLE seed_people (first_name text, last_name text, full_name text) ON COMMIT DROP;
INSERT INTO seed_people (first_name, last_name, full_name) VALUES
  ('Pat',       'Dixon',       'Pat Dixon'),
  ('Kevin',     'McCormick',   'Kevin McCormick'),
  ('Anthony',   'Cristo',      'Anthony Cristo'),
  ('Tom',       'Oxford',      'Tom Oxford');

DO $$
DECLARE n int; txt text;
BEGIN
  -- 🔴 The duplicate guard keys on (first_name, last_name) and is CASE-SENSITIVE, so it is
  --    blind to a differently-split or differently-cased row. Checked by hand against every
  --    row sharing these surnames, ARCHIVED ROWS INCLUDED, on 2026-11-05: none of the four
  --    exists under any spelling. ⚠ That sweep did surface two unrelated pre-existing pairs
  --    — "Arthur Dixon" x2 and "Jessica McCormick"/"Jessica Mccormick" — which are NOT
  --    touched here and are written up in NOTES.md.
  SELECT string_agg(p.full_name || ' (' || p.id || ', active=' || p.is_active || ')', '; ') INTO txt
    FROM essentials.politicians p JOIN seed_people s
      ON lower(p.first_name) = lower(s.first_name) AND lower(p.last_name) = lower(s.last_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;
END $$;

INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, 'Ballotpedia, "Texas state executive official elections, 2026", read 2026-11-05 (identity and party only — its vote counts were mid-count and are NOT used); vote shares from AP (CC_0358)', true, false
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE lower(p.first_name) = lower(s.first_name)
                      AND lower(p.last_name)  = lower(s.last_name));

-- ─── 2. The three races ───
CREATE TEMP TABLE new_races (ap_race text PRIMARY KEY, office_id uuid, position_name text) ON COMMIT DROP;
INSERT INTO new_races (ap_race, office_id, position_name) VALUES
  ('20261103TX45901', 'd660034d-4215-47b0-bb59-3e1616fab09d'::uuid, 'Texas Governor'),
  ('20261103TX45902', 'ecfc1979-4edc-4232-bc4c-381ecbc6a516'::uuid, 'Texas Lieutenant Governor'),
  ('20261103TX45903', '12a2385f-4dbc-4de3-9eaf-935c6fc58a8f'::uuid, 'Texas Attorney General');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id;
  IF n <> 3 THEN RAISE EXCEPTION 'only % of the 3 target offices exist', n; END IF;

  -- each target office must hold NO race on this date, or this file is duplicating one
  SELECT count(*) INTO n
    FROM new_races nr
    JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03';
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) already exist on these offices for 2026-11-03', n; END IF;

  PERFORM 1 FROM essentials.elections WHERE id = '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid AND election_date = DATE '2026-11-03';
  IF NOT FOUND THEN RAISE EXCEPTION 'the TX 2026 Statewide General election row is not where this file expects it'; END IF;
END $$;

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, nr.office_id, nr.position_name, NULL, 1
  FROM new_races nr
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r
                     JOIN essentials.elections e ON e.id = r.election_id
                    WHERE r.office_id = nr.office_id AND e.election_date = DATE '2026-11-03');

-- ─── 3. The candidacies, with AP's result ───
CREATE TEMP TABLE calls (
  ap_race text NOT NULL, office_id uuid NOT NULL, seat text NOT NULL, who text NOT NULL,
  ap_cand_id text PRIMARY KEY, result text NOT NULL, vote_pct numeric NOT NULL, is_inc boolean NOT NULL
) ON COMMIT DROP;
INSERT INTO calls (ap_race, office_id, seat, who, ap_cand_id, result, vote_pct, is_inc) VALUES
  ('20261103TX45901', 'd660034d-4215-47b0-bb59-3e1616fab09d'::uuid,
   'Texas Governor',              'Greg Abbott',       '41404',   'lost',   45.69, true),
  ('20261103TX45901', 'd660034d-4215-47b0-bb59-3e1616fab09d'::uuid,
   'Texas Governor',              'Gina Hinojosa',     '152027',  'won',    52.82, false),
  ('20261103TX45901', 'd660034d-4215-47b0-bb59-3e1616fab09d'::uuid,
   'Texas Governor',              'Pat Dixon',         '155880',  'lost',     1.5, false),
  ('20261103TX45902', 'ecfc1979-4edc-4232-bc4c-381ecbc6a516'::uuid,
   'Texas Lieutenant Governor',   'Dan Patrick',       '64382',   'lost',   45.64, true),
  ('20261103TX45902', 'ecfc1979-4edc-4232-bc4c-381ecbc6a516'::uuid,
   'Texas Lieutenant Governor',   'Kevin McCormick',   '65558',   'lost',     0.9, false),
  ('20261103TX45902', 'ecfc1979-4edc-4232-bc4c-381ecbc6a516'::uuid,
   'Texas Lieutenant Governor',   'Anthony Cristo',    '67198',   'lost',    1.73, false),
  ('20261103TX45902', 'ecfc1979-4edc-4232-bc4c-381ecbc6a516'::uuid,
   'Texas Lieutenant Governor',   'Vikki Goodwin',     '153028',  'won',    51.73, false),
  ('20261103TX45903', '12a2385f-4dbc-4de3-9eaf-935c6fc58a8f'::uuid,
   'Texas Attorney General',      'Tom Oxford',        '149719',  'lost',    1.69, false),
  ('20261103TX45903', '12a2385f-4dbc-4de3-9eaf-935c6fc58a8f'::uuid,
   'Texas Attorney General',      'Nathan Johnson',    '152897',  'won',    52.37, false),
  ('20261103TX45903', '12a2385f-4dbc-4de3-9eaf-935c6fc58a8f'::uuid,
   'Texas Attorney General',      'Mayes Middleton',   '152985',  'lost',   45.94, false);

DO $$
DECLARE n int; txt text;
BEGIN
  -- 🔴 the winner must be AP's top vote-getter in that race. winner and votePct are
  --    independent fields, so a transposition breaks their agreement. Valid here only
  --    because all three races are single-round and AP flags none as rankedChoice.
  SELECT string_agg(a.seat || ': ' || a.who || ' won on ' || a.vote_pct
                    || '% but ' || b.who || ' polled ' || b.vote_pct || '%', '; ') INTO txt
    FROM calls a JOIN calls b ON b.ap_race = a.ap_race AND b.vote_pct > a.vote_pct
   WHERE a.result = 'won';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the top vote-getter: %', txt; END IF;

  -- every named person must now resolve to EXACTLY ONE politician row
  SELECT string_agg(c.who || ' -> ' || cnt, '; ') INTO txt FROM (
    SELECT c.who, (SELECT count(*) FROM essentials.politicians p WHERE p.full_name = c.who) AS cnt
      FROM calls c) c WHERE cnt <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidate does not resolve to exactly one person: %', txt; END IF;

  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 winners, found %', n; END IF;

  -- 🔴 THE INCUMBENCY FLAG IS CROSS-CHECKED AGAINST WHO ACTUALLY HOLDS THE SEAT.
  --    A control proved this gate was needed: swapping the flag from the losing incumbent
  --    to the winner passed every other check, because the write reads this file's own
  --    table and the post-verify read the same table — a tampered file AGREES WITH ITSELF.
  --    essentials.office_current_holder is a fact this file does not supply, so it can
  --    disagree. Checked in BOTH directions: marked-but-not-holding, and holding-but-not-marked.
  SELECT string_agg(msg, '; ') INTO txt FROM (
    SELECT c.seat || ': this file marks ' || c.who || ' as incumbent, but the seat is held by '
           || coalesce(h.full_name, '(nobody)') AS msg
      FROM calls c
      LEFT JOIN essentials.office_current_holder och ON och.office_id = c.office_id
      LEFT JOIN essentials.politicians h ON h.id = och.politician_id
     WHERE c.is_inc AND h.full_name IS DISTINCT FROM c.who
    UNION ALL
    SELECT c.seat || ': ' || c.who || ' holds this seat but is not marked incumbent'
      FROM calls c
      JOIN essentials.office_current_holder och ON och.office_id = c.office_id
      JOIN essentials.politicians h ON h.id = och.politician_id AND h.full_name = c.who
     WHERE NOT c.is_inc) z;
  IF txt IS NOT NULL THEN
    RAISE EXCEPTION 'incumbency disagrees with the current officeholder: %', txt;
  END IF;
END $$;

-- full_name is NOT NULL on race_candidates and the table carries its own name split, so
-- both are taken FROM THE POLITICIAN ROW rather than retyped — they cannot drift apart.
-- external_id stays NULL, matching every other state-executive candidacy in this election;
-- AP's candidate id lives in this file's header and in the saved feed, not in a column
-- where a collision could later seat the wrong person.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, c.is_inc, 'active',
       false, 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0358)', c.result, 'called', 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0358)', now()
  FROM calls c
  JOIN essentials.races r ON r.office_id = c.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.politicians p ON p.full_name = c.who
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND rc.politician_id = p.id);

-- ─── Post-verify ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND upper(d.state) = 'TX';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 Texas state-executive races, found %', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND upper(d.state) = 'TX';
  IF n <> 10 THEN RAISE EXCEPTION 'expected 10 Texas state-executive candidacies, found %', n; END IF;

  -- every pinned call landed on the right person, with its citation and a measured stamp
  SELECT count(*) INTO n
    FROM calls c
    JOIN essentials.politicians p ON p.full_name = c.who
    JOIN essentials.races r ON r.office_id = c.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = p.id
   WHERE rc.result = c.result AND rc.result_certainty = 'called'
     AND rc.result_source = 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0358)' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-04'
     AND rc.is_incumbent = c.is_inc;
  IF n <> 10 THEN RAISE EXCEPTION 'only % of the 10 candidacies hold their stated result', n; END IF;

  -- each race: exactly one winner, nobody undecided
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND upper(d.state) = 'TX'
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> 1
        OR count(*) FILTER (WHERE rc.result IS NULL) <> 0) z;
  IF n <> 0 THEN RAISE EXCEPTION '% Texas race(s) lack exactly one winner or hold an undecided row', n; END IF;

  -- the four seeded people exist exactly once and are not marked incumbent
  SELECT string_agg(s.full_name || ' x' || (SELECT count(*) FROM essentials.politicians p
                      WHERE p.full_name = s.full_name), '; ') INTO txt
    FROM seed_people s
   WHERE (SELECT count(*) FROM essentials.politicians p WHERE p.full_name = s.full_name) <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded person is not present exactly once: %', txt; END IF;

  SELECT count(*) INTO n FROM seed_people s
    JOIN essentials.politicians p ON p.full_name = s.full_name
   WHERE p.is_active = true AND p.is_incumbent = false AND p.source = 'Ballotpedia, "Texas state executive official elections, 2026", read 2026-11-05 (identity and party only — its vote counts were mid-count and are NOT used); vote shares from AP (CC_0358)';
  IF n <> 4 THEN RAISE EXCEPTION 'only % of the 4 seeded people read active, non-incumbent and sourced', n; END IF;

  -- nothing claims to be certified
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND upper(d.state) = 'TX'
     AND rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION '% Texas row(s) do not read called', n; END IF;

  -- and the tier total moves by exactly these three winners
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND rc.result = 'won';
  IF n <> 21 THEN RAISE EXCEPTION 'expected 21 state-executive winners nationally (18 from CC_0357 + 3 here), found %', n; END IF;

  RAISE NOTICE 'CC_0358 OK — Texas: 3 races, 10 candidacies (3 won, 7 lost), 4 people seeded.';
END $$;

COMMIT;

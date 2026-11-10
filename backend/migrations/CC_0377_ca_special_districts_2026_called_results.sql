-- CC_0377 — 2026-11-03 California special districts: record the nine contests that are
--           decisive against Los Angeles County's own outstanding-ballot estimate.
--
-- WHY THIS FILE EXISTS. 19 seats hand over at noon on Friday 2026-12-04 — the earliest
--   handover anywhere in the post-election programme, and the first piece of the local tier,
--   which until now holds ZERO recorded winners against 524 races. Cal. Water Code 71253,
--   Cal. Elec. Code 10554, Cal. Water Code 21101/35057, Cal. Educ. Code 19700(b) and Cal.
--   Gov. Code 61042(a) all fix the same day for these bodies; essentials.office_swearing_in
--   already carries it per office, with the authority quoted (piece 4, CC_0344-CC_0347).
--
-- 🔴🔴 NEITHER COUNTY PUBLISHES A WINNER FLAG, SO THE CALL IS OURS. Every federal and
--   state-executive pass in this programme recorded `called` on AP's own flag, or on
--   Ballotpedia's, and the rule that made that safe was: use the flag, never the count. There
--   is no flag here. Los Angeles RR/CC and San Bernardino ROV publish running totals and
--   nothing else, so a winner can only be derived — and this file derives it by ARITHMETIC
--   ALONE, never by reading a lead as a result:
--
--     a contest is recorded only when the trailing candidate could not overtake the leader
--     EVEN IF EVERY BALLOT STILL UNCOUNTED IN THAT CONTEST BROKE THEIR WAY and the leader
--     gained nothing at all.
--
--   That is a bound on the worst case, not a projection about how late ballots lean. LA's
--   "Post-Election Night Ballot Count Update" (read 2026-11-08) puts 131,000 ballots still
--   outstanding — 94,000 vote-by-mail, 32,000 conditional-registration, 5,000 provisional —
--   against 3,041,114 counted, 51.47% turnout.
--   🔴 THE PER-CONTEST FIGURE DOES NOT EXIST. The countywide one is apportioned by each
--     contest's own share of ballots cast and then multiplied by THREE, so a district would
--     have to be holding three times its proportional share of everything still uncounted
--     before the bound could be wrong. Both numbers are carried in the rows below and the
--     gate re-derives the decision inside this transaction rather than trusting the label.
--
-- 🔴 TEN OF THE NINETEEN ARE DELIBERATELY LEFT NULL, and several of them are not close:
--     West Basin Division 2 leads by 2,614 and Three Valleys Division 3 by 1,145. They are
--     held because the BOUND, not the margin, is what decides — those are large contests
--     (57,515 and 31,283 ballots), so their share of the 131,000 is large too. A lead that
--     looks safe in percentage terms is not the test.
--   ▶ They are not a backlog and they are not a failure: LA certifies by 2026-12-01 and the
--     seats do not turn over until 2026-12-04. The certification pass records all nineteen as
--     `certified` and seats the winners. See
--     backend/data/ca-special-districts-2026-results/NOTES.md.
--
-- WHAT IT WRITES: 22 existing candidacies UPDATED across 9 races — 11 won, 11 lost, every one
--   result_certainty = 'called'. No politician, race, office or term is created or deleted.
--   🔴 EVERY PRIOR VALUE OF EVERY COLUMN THIS FILE TOUCHES IS NULL — result, result_certainty,
--     result_source and result_recorded_at alike, on all 22 rows. There is no history table
--     and no replayable runner, so that is recorded here and the gate REFUSES to overwrite
--     anything that is not NULL. The ten held-back races keep 37 untouched NULL candidacies.
--
--   Crescenta Valley Water District — Director, 3 of 4, EC 10554   margin 2,466 / bound 1,116
--     🏆 Carla D. Dillon · 🏆 James Bodnar (incumbent) · 🏆 Jeffery W. Johnson (incumbent)
--        Alec Hyeler
--   Foothill MWD Division 2 — WC 71253                             margin 1,445 / bound   966
--     🏆 John Vrsalovich (incumbent, HELD)    Tom Majich
--   Foothill MWD Division 4 — WC 71253                             margin 3,495 / bound 1,053
--     🏆 Amy I. Chen                          Laura Olhasso (incumbent, DEFEATED)
--   Foothill MWD Division 5 — WC 71253                             margin   985 / bound   915
--     🏆 Patrick W. Atwater                   Noosha Razavian      ⚠ the narrowest call here
--   La Cañada Irrigation District Division 4 — WC 21101            margin   290 / bound   129
--     🏆 Helen Grace Avila Olivares           Sheree Rae Butts (incumbent, DEFEATED)
--   Las Virgenes MWD Division 2 — WC 71253                         margin 1,895 / bound   651
--     🏆 Andy Coradeschi (incumbent, HELD)    Teri L. Davis
--   Walnut Valley WD Division 2 — WC 35057 → UDEL → EC 10554       margin 1,194 / bound   930
--     🏆 Brian Worthington                    Michael Braun
--     ⚠ Michael Braun's candidacy carries NO politician_id. Recording a result does not need
--       one — the result lives on the candidacy — and inventing a person to carry a loss would
--       be a write nobody asked for. Left as it is, named here so it is not read as damage.
--   Walnut Valley WD Division 3 — WC 35057 → UDEL → EC 10554       margin 2,469 / bound   783
--     🏆 Theresa Lee (incumbent, HELD)        Kenny Shu
--   West Basin MWD Division 1 — WC 71253                          margin 13,773 / bound 8,904
--     🏆 Tommy G. Faavae (incumbent, HELD)    Tim Zajic · Anthony J. Fidaleo · Deirdre Badal
--
-- SOURCING. results.lavote.gov serves the page's own JSON API, and it comes in two pieces of
--   which NEITHER IS USABLE ALONE:
--     GetElectionData — the contests and candidates. Every Votes field is 0 and every Winner
--       flag is false. 🔴 IT IS THE BALLOT, NOT THE RESULT; read by itself it reports a
--       complete election in which nobody received a vote, and that reads as "no results yet".
--     GetCounterData  — the counts, keyed by candidate id, plus per-contest ballots cast.
--   The join of the two is then re-read against results.lavote.gov/text-results/4348, which
--   the server renders independently from the same data: a free second reading of all 22
--   numbers, and they agree. Raw extracts, the analyser and its controls are committed in
--   backend/data/ca-special-districts-2026-results/.
--
-- 🔴🔴 A SPECIAL DISTRICT CAN STRADDLE A COUNTY LINE AND EACH COUNTY THEN PUBLISHES ONLY ITS
--   OWN SLICE — complete-looking, every candidate present, counted from a fraction of the
--   ballots. Wrightwood CSD is one: Los Angeles holds 71 ballots and files it under
--   "Recreation and Park", San Bernardino holds 1,309. Reading either county alone would have
--   ranked that board on 5% or 95% of its electorate, and nothing would have looked wrong.
--   It is HELD here in any case, because San Bernardino publishes no outstanding-ballot
--   estimate at all and the margin therefore cannot be bounded from either side.
--
-- 🔴 THE INCUMBENT CROSS-CHECK IS AN INDEPENDENT FACT AND IT RUNS BOTH WAYS. CC_0358 shipped a
--   post-verify that compared is_incumbent against THE FILE'S OWN TABLE, and a tamper moving
--   the flag from the losing incumbent to the winner passed it: a tampered file agrees with
--   itself. The gate below asks essentials.office_current_holder instead, which this file does
--   not supply, for every SINGLE-SEAT office — all eight agree today.
--   ⚠ It can only run on single-seat offices. Four of these bodies are one office carrying
--     seats = 3, and the view is exactly one row per OFFICE, so it names one of the three
--     sitting directors and says nothing about the other two. That is the model working as
--     designed, not a defect, and a gate that demanded more would be wrong.
--
-- Slot reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  district     text NOT NULL,
  office_title text NOT NULL,
  race_id      uuid NOT NULL,
  rc_id        uuid PRIMARY KEY,
  ballot_name  text NOT NULL,   -- exactly as Los Angeles County prints it
  votes        int  NOT NULL,
  rank         int  NOT NULL,
  outcome      text NOT NULL CHECK (outcome IN ('won', 'lost'))
) ON COMMIT DROP;

INSERT INTO called (district, office_title, race_id, rc_id, ballot_name, votes, rank, outcome) VALUES
  -- Crescenta Valley Water District — Director, 3 seat(s); margin 2466 vs bound 1116
  ('Crescenta Valley Water District', 'Director', '27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid, 'fd3a5681-4eef-42d9-ad3d-0d79ee6b15dd'::uuid, 'CARLA D. DILLON', 4402, 1, 'won'),
  ('Crescenta Valley Water District', 'Director', '27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid, 'b70917b3-713d-460d-86e3-64d72c59f90d'::uuid, 'JAMES BODNAR', 4157, 2, 'won'),
  ('Crescenta Valley Water District', 'Director', '27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid, '569c56a0-fe68-47ab-a9cb-d91ca29212b8'::uuid, 'JEFFERY W. JOHNSON', 3567, 3, 'won'),
  ('Crescenta Valley Water District', 'Director', '27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid, '2c9f901e-4a80-4098-bf37-226d074911ae'::uuid, 'ALEC HYELER', 1101, 4, 'lost'),
  -- Foothill Municipal Water District - Division 2 — Director (Division 2), 1 seat(s); margin 1445 vs bound 966
  ('Foothill Municipal Water District - Division 2', 'Director (Division 2)', '3e37bd0a-b384-5919-834d-a99eebe633c1'::uuid, '3f7e3ada-73da-4d04-85a5-47b797081932'::uuid, 'JOHN VRSALOVICH', 3379, 1, 'won'),
  ('Foothill Municipal Water District - Division 2', 'Director (Division 2)', '3e37bd0a-b384-5919-834d-a99eebe633c1'::uuid, '3e6fc72f-0dab-4956-878b-e8ac5ed6d448'::uuid, 'TOM MAJICH', 1934, 2, 'lost'),
  -- Foothill Municipal Water District - Division 4 — Director (Division 4), 1 seat(s); margin 3495 vs bound 1053
  ('Foothill Municipal Water District - Division 4', 'Director (Division 4)', '2266398e-0740-54dc-a75f-ecc082437603'::uuid, 'c89665fc-d487-4c06-968d-6accb7b103b8'::uuid, 'AMY I. CHEN', 5255, 1, 'won'),
  ('Foothill Municipal Water District - Division 4', 'Director (Division 4)', '2266398e-0740-54dc-a75f-ecc082437603'::uuid, 'e8d805bb-0d99-47b7-a1b9-3157958af591'::uuid, 'LAURA OLHASSO', 1760, 2, 'lost'),
  -- Foothill Municipal Water District - Division 5 — Director (Division 5), 1 seat(s); margin 985 vs bound 915
  ('Foothill Municipal Water District - Division 5', 'Director (Division 5)', '79342cfc-56c9-5e29-a3fa-5feca02d145a'::uuid, '22e1e130-5d65-4cc1-91e2-3eb1da38754d'::uuid, 'PATRICK W. ATWATER', 3286, 1, 'won'),
  ('Foothill Municipal Water District - Division 5', 'Director (Division 5)', '79342cfc-56c9-5e29-a3fa-5feca02d145a'::uuid, 'd85e94b4-1d0e-493e-a040-f3d52de8ef3d'::uuid, 'NOOSHA RAZAVIAN', 2301, 2, 'lost'),
  -- La Cañada Irrigation District - Division 4 — Director (Division 4), 1 seat(s); margin 290 vs bound 129
  ('La Cañada Irrigation District - Division 4', 'Director (Division 4)', 'a1fafd45-51ee-595b-9270-7df24563512e'::uuid, '75806e33-a486-4318-a239-941d4c7c107c'::uuid, 'HELEN GRACE AVILA OLIVARES', 527, 1, 'won'),
  ('La Cañada Irrigation District - Division 4', 'Director (Division 4)', 'a1fafd45-51ee-595b-9270-7df24563512e'::uuid, 'ef55df04-c94a-407f-b7f5-7b281388217b'::uuid, 'SHEREE RAE BUTTS', 237, 2, 'lost'),
  -- Las Virgenes Municipal Water District - Division 2 — Director (Division 2), 1 seat(s); margin 1895 vs bound 651
  ('Las Virgenes Municipal Water District - Division 2', 'Director (Division 2)', '6947b0d4-96eb-54c6-b1cb-be1d832ba02b'::uuid, '0b943fc1-cd2d-4f86-b6eb-2cc0453d9e80'::uuid, 'ANDY CORADESCHI', 2658, 1, 'won'),
  ('Las Virgenes Municipal Water District - Division 2', 'Director (Division 2)', '6947b0d4-96eb-54c6-b1cb-be1d832ba02b'::uuid, 'deced586-3b3b-4ce0-83be-032e73fc9710'::uuid, 'TERI L. DAVIS', 763, 2, 'lost'),
  -- Walnut Valley Water District - Division 2 — Director (Division 2), 1 seat(s); margin 1194 vs bound 930
  ('Walnut Valley Water District - Division 2', 'Director (Division 2)', 'a8b9d5ce-1559-544b-b3b8-fc3835112119'::uuid, 'c717d33b-cc99-4b2b-bdc4-06b6f3d1a16d'::uuid, 'BRIAN WORTHINGTON', 3538, 1, 'won'),
  ('Walnut Valley Water District - Division 2', 'Director (Division 2)', 'a8b9d5ce-1559-544b-b3b8-fc3835112119'::uuid, 'a63fd90b-02c8-4d08-931b-ffd616f8bac7'::uuid, 'MICHAEL BRAUN', 2344, 2, 'lost'),
  -- Walnut Valley Water District - Division 3 — Director (Division 3), 1 seat(s); margin 2469 vs bound 783
  ('Walnut Valley Water District - Division 3', 'Director (Division 3)', '023e8c57-26d8-5f47-8a27-01ad5157f2d9'::uuid, '90fba149-a000-4bfd-95ec-ac1f514784e9'::uuid, 'THERESA LEE', 3698, 1, 'won'),
  ('Walnut Valley Water District - Division 3', 'Director (Division 3)', '023e8c57-26d8-5f47-8a27-01ad5157f2d9'::uuid, 'cc72fd2a-6595-45ef-969f-eb9ae65debf4'::uuid, 'KENNY SHU', 1229, 2, 'lost'),
  -- West Basin Municipal Water District - Division 1 — Director (Division 1), 1 seat(s); margin 13773 vs bound 8904
  ('West Basin Municipal Water District - Division 1', 'Director (Division 1)', '0b9c841e-672b-5d60-a61e-09fca78c3605'::uuid, '2f18e81e-f9c5-475d-b207-5c70c15346ae'::uuid, 'TOMMY G. FAAVAE', 28710, 1, 'won'),
  ('West Basin Municipal Water District - Division 1', 'Director (Division 1)', '0b9c841e-672b-5d60-a61e-09fca78c3605'::uuid, '32349d76-439a-42d2-92c5-c371d8bc1d3e'::uuid, 'TIM ZAJIC', 14937, 2, 'lost'),
  ('West Basin Municipal Water District - Division 1', 'Director (Division 1)', '0b9c841e-672b-5d60-a61e-09fca78c3605'::uuid, '47999601-942d-4d4b-8f9d-f1e9c7cf5ac1'::uuid, 'ANTHONY J. FIDALEO', 4614, 3, 'lost'),
  ('West Basin Municipal Water District - Division 1', 'Director (Division 1)', '0b9c841e-672b-5d60-a61e-09fca78c3605'::uuid, 'd0df5bf2-2428-43d9-afb6-aeeb581a1027'::uuid, 'DEIRDRE BADAL', 3036, 4, 'lost');

-- What each contest is being judged against. ballots_cast and est_outstanding come from the
-- county; bound is est_outstanding x 3 and the gate below recomputes the decision from these
-- columns rather than taking the presence of a row as the answer.
CREATE TEMP TABLE bound (
  race_id        uuid PRIMARY KEY,
  ballots_cast   int NOT NULL,
  est_outstanding int NOT NULL,
  safety         int NOT NULL,
  bound          int NOT NULL
) ON COMMIT DROP;
INSERT INTO bound (race_id, ballots_cast, est_outstanding, safety, bound) VALUES
  ('27d5eab3-f128-5eee-b2a7-62a1732448d1'::uuid,  8635,  372, 3,  1116),   -- Crescenta Valley
  ('3e37bd0a-b384-5919-834d-a99eebe633c1'::uuid,  7460,  322, 3,   966),   -- Foothill Div 2
  ('2266398e-0740-54dc-a75f-ecc082437603'::uuid,  8126,  351, 3,  1053),   -- Foothill Div 4
  ('79342cfc-56c9-5e29-a3fa-5feca02d145a'::uuid,  7079,  305, 3,   915),   -- Foothill Div 5
  ('a1fafd45-51ee-595b-9270-7df24563512e'::uuid,   992,   43, 3,   129),   -- La Cañada Div 4
  ('6947b0d4-96eb-54c6-b1cb-be1d832ba02b'::uuid,  5026,  217, 3,   651),   -- Las Virgenes Div 2
  ('a8b9d5ce-1559-544b-b3b8-fc3835112119'::uuid,  7183,  310, 3,   930),   -- Walnut Valley Div 2
  ('023e8c57-26d8-5f47-8a27-01ad5157f2d9'::uuid,  6057,  261, 3,   783),   -- Walnut Valley Div 3
  ('0b9c841e-672b-5d60-a61e-09fca78c3605'::uuid, 68892, 2968, 3,  8904);   -- West Basin Div 1

-- ─── 2. Everything that must be true before a single row is written ───
CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  -- 🔴 unaccent is NOT installed on prod, and the county prints PEÑA and LA CAÑADA with the
  --    accent. Fold it here, in the application's own terms, exactly as CLAUDE.md requires.
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),
           '[^A-Z0-9]', '', 'g')
$f$;

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 22 THEN RAISE EXCEPTION 'expected 22 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM bound;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 bounds, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called c LEFT JOIN bound b ON b.race_id = c.race_id WHERE b.race_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% measured rows belong to a race with no bound', n; END IF;

  -- a positive control: the name comparison must be able to see a row known to exist, or
  -- every "no mismatch found" below is vacuous
  PERFORM 1 FROM essentials.race_candidates
   WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Helen Grace Avila Olivares');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist — the name gate below would pass vacuously'; END IF;

  -- 🔴 EVERY ROW IS ADDRESSED BY uuid AND THE NAME BESIDE IT IS NOT USED TO FIND IT. A swapped
  --   uuid is invisible to any check the file makes against itself, so the name written here
  --   is compared with the DATABASE ROW'S name. CC_0359 gate D, and it has caught a real swap.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.ballot_name || ' (rc ' || c.rc_id || ') is ' ||
           coalesce(rc.full_name, '(no such candidacy)') || ' in the database' AS msg
      FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id
     WHERE rc.id IS NULL OR pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.ballot_name)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a measured name does not match the row it is written against: %', txt; END IF;

  -- and the candidacy must belong to the race the file says it does
  SELECT string_agg(c.ballot_name || ' sits in race ' || rc.race_id || ', not ' || c.race_id, '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy is attached to the wrong race: %', txt; END IF;

  -- 🔴 THIS IS THE WAVE'S DEFINITION AND IT COMES FROM THE DATABASE, NOT FROM THE FILE: every
  --   race here must be a 2026-11-03 contest for an office that hands over on 2026-12-04.
  SELECT string_agg(c.district || ' -> ' || coalesce(s.swearing_in_date::text, '(no row)') ||
                    ' / ' || coalesce(e.election_date::text, '(no election)'), '; ') INTO txt
    FROM (SELECT DISTINCT race_id, district FROM called) c
    JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.office_swearing_in s
           ON s.office_id = r.office_id AND s.election_date = e.election_date
   WHERE e.election_date <> DATE '2026-11-03'
      OR s.swearing_in_date IS DISTINCT FROM DATE '2026-12-04';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is not a 2026-11-03 contest handing over on 2026-12-04: %', txt; END IF;

  -- the number of winners must equal the seats the race carries — never 1
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || count(*) FILTER (WHERE c.outcome = 'won') ||
           ' winners for ' || r.seats || ' seat(s)' AS msg
      FROM called c JOIN essentials.races r ON r.id = c.race_id
     GROUP BY c.race_id, c.district, r.seats
    HAVING count(*) FILTER (WHERE c.outcome = 'won') <> r.seats) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race records the wrong number of winners: %', txt; END IF;

  -- the file must carry EVERY candidacy in each of these races, or a winner could be hidden
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': the file has ' || count(DISTINCT c.rc_id) || ' of ' ||
           (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = c.race_id) ||
           ' candidacies' AS msg
      FROM called c GROUP BY c.race_id, c.district
    HAVING count(DISTINCT c.rc_id) <>
           (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = c.race_id)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is only partly measured: %', txt; END IF;

  -- 🔴 NOTHING IS OVERWRITTEN. Every one of these 22 rows is NULL in all four columns today,
  --   and that is the only state this file is willing to write over.
  SELECT string_agg(rc.full_name || ' already reads result=' || coalesce(rc.result, '(null)') ||
                    ' certainty=' || coalesce(rc.result_certainty, '(null)'), '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL
      OR rc.result_source IS NOT NULL OR rc.result_recorded_at IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file only writes over NULL and found a value: %', txt; END IF;

  -- ── the decision itself, recomputed from the measurements ──
  -- every winner must out-poll every loser in the same race
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.district || ': ' || l.ballot_name || ' (' || l.votes || ') is recorded LOST above ' ||
           w.ballot_name || ' (' || w.votes || ') recorded WON' AS msg
      FROM called w JOIN called l ON l.race_id = w.race_id
     WHERE w.outcome = 'won' AND l.outcome = 'lost' AND l.votes >= w.votes) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loser out-polls a winner: %', txt; END IF;

  -- 🔴 AND THE GAP MUST CLEAR THE BOUND. This is the whole claim of the file: the trailing
  --   candidate cannot overtake even if every uncounted ballot in the contest breaks their way.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT z2.district || ': margin ' || z2.margin || ' does not clear its bound of ' || z2.bound ||
           ' (' || z2.est_outstanding || ' estimated outstanding x' || z2.safety || ')' AS msg
      FROM (SELECT c.district, c.race_id,
                   min(c.votes) FILTER (WHERE c.outcome = 'won')
                     - max(c.votes) FILTER (WHERE c.outcome = 'lost') AS margin,
                   b.bound, b.est_outstanding, b.safety
              FROM called c JOIN bound b ON b.race_id = c.race_id
             GROUP BY c.district, c.race_id, b.bound, b.est_outstanding, b.safety) z2
     WHERE z2.margin IS NULL OR z2.margin <= z2.bound) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a recorded contest is not decisive against its own bound: %', txt; END IF;

  -- the bound must be the safety multiple of the estimate, not a number typed next to it
  SELECT string_agg(b.race_id || ': bound ' || b.bound || ' <> ' || b.est_outstanding || ' x ' || b.safety, '; ') INTO txt
    FROM bound b WHERE b.bound <> b.est_outstanding * b.safety OR b.safety < 3;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a bound does not follow from its own inputs: %', txt; END IF;

  -- 🔴 AN INDEPENDENT FACT, BOTH DIRECTIONS, ON EVERY SINGLE-SEAT OFFICE. Not the file's own
  --   table — essentials.office_current_holder, which this file does not write.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' is flagged incumbent but the seat is held by ' ||
           coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND rc.is_incumbent
       AND och.politician_id IS DISTINCT FROM rc.politician_id
    UNION
    SELECT c.district || ': the seat is held by ' || p.full_name ||
           ', who is on this ballot and is NOT flagged incumbent'
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND och.politician_id = rc.politician_id AND NOT rc.is_incumbent) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent flag disagrees with who holds the seat: %', txt; END IF;

  RAISE NOTICE 'CC_0377 pre-checks passed: 22 candidacies, 9 races, all NULL, all decisive against their bounds';
END $$;

-- ─── 3. The write ───
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Los Angeles County RR/CC official results for the 2026-11-03 General Election '
         || '(results.lavote.gov, election 4348; ElectionResults/GetElectionData joined to '
         || 'ElectionResults/GetCounterData and re-read against results.lavote.gov/text-results/4348), '
         || 'count of 2026-11-07 16:38 PT, retrieved 2026-11-08: ' || c.ballot_name || ' '
         || c.votes || ' votes, rank ' || c.rank || '. The county publishes no winner flag; '
         || 'recorded as called by CC_0377 because the margin exceeds three times this contest''s '
         || 'proportional share of the 131,000 ballots the RR/CC reports still outstanding.',
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result_source LIKE '%CC_0377%';
  IF n <> 22 THEN RAISE EXCEPTION 'this file wrote % of its 22 rows', n; END IF;

  SELECT count(*) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result = 'lost')
    INTO n, total
    FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;
  IF n <> 11 OR total <> 11 THEN RAISE EXCEPTION 'expected 11 won and 11 lost, wrote % and %', n, total; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result <> c.outcome OR rc.result_certainty <> 'called' OR rc.result_recorded_at IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% rows did not take the outcome this file measured', n; END IF;

  -- 🔴 THE TEN HELD-BACK RACES MUST BE UNTOUCHED. A result written to one of them would be a
  --   call made on a margin nobody bounded, which is the one thing this file refuses to do.
  SELECT string_agg(d.label || ': ' || rc.full_name || ' = ' || rc.result, '; ') INTO txt
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-04'
     AND r.id NOT IN (SELECT race_id FROM bound)
     AND (rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL OR rc.result_source IS NOT NULL);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race this file holds back has acquired a result: %', txt; END IF;

  -- and the wave now stands at exactly 9 of 19 decided, 37 candidacies still NULL
  SELECT count(DISTINCT r.id) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result IS NULL)
    INTO n, total
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-04';
  IF n <> 9 THEN RAISE EXCEPTION 'the 2026-12-04 wave shows % races with a winner, expected 9', n; END IF;
  IF total <> 37 THEN RAISE EXCEPTION 'the wave shows % candidacies still unrecorded, expected 37', total; END IF;

  -- no race in the wave may hold a loser and no winner
  SELECT string_agg(z.d, '; ') INTO txt FROM (
    SELECT d.label AS d
      FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-04'
     GROUP BY d.label
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won') = 0) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race holds a loser and no winner: %', txt; END IF;

  -- 🔴 THE INCUMBENT FLAG IS NOT THIS FILE'S TO MOVE, and a count would never see it move:
  --   one true going to another row leaves the total alone. Asked of the view again, after
  --   the write, in both directions.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' flagged incumbent, seat held by ' ||
           coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND rc.is_incumbent AND och.politician_id IS DISTINCT FROM rc.politician_id
    UNION
    SELECT c.district || ': seat held by ' || p.full_name || ', on this ballot, not flagged incumbent'
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND och.politician_id = rc.politician_id AND NOT rc.is_incumbent) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent flag moved under this file: %', txt; END IF;

  -- 🔴 NOBODY IS SEATED HERE. An election result is not an officeholder: these winners take
  --   office at noon on 2026-12-04 and not a day earlier. The occupancy drift baseline must
  --   therefore be exactly where it was, and the view must still show the SITTING directors.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN
    RAISE EXCEPTION 'the unflagged offices_missing_terms baseline reads %, not 238 (total %, flagged %)', unflagged, total, flagged;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.races r ON r.office_id = ot.office_id
   WHERE r.id IN (SELECT race_id FROM bound) AND ot.term_start >= DATE '2026-11-04';
  IF n <> 0 THEN RAISE EXCEPTION '% term row(s) start after the election on an office this file touched — nothing here seats anyone', n; END IF;

  RAISE NOTICE 'CC_0377 post-verify passed: 9 of the 19 races decided (11 won / 11 lost, all called), 37 candidacies still open, baseline unflagged 238 (total %, flagged %)', total, flagged;
END $$;

COMMIT;

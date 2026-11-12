-- CA_0374 — seat four Indiana legislators whose terms began on 2026-11-04.
--
-- WHY. Indiana legislators take office THE DAY AFTER the general election, not in January:
--   "Senators shall be elected for the term of four years, and Representatives for the term of two
--   years, from the day next after their general election" (Indiana Constitution, Art. 4 §3;
--   https://ballotpedia.org/Article_4,_Indiana_Constitution). Our own stored starts already follow
--   that rule: Borders 2014-11-05, Bassler 2014-11-05, Hall and Hunley 2022-11-09 (each the day
--   after that year's election). So the 2026 terms began on 2026-11-04.
--   CC_0381 recorded Indiana's AP results but says "these members take office in January", and the
--   transition tracker has no swearing_in date for any Indiana Wave 4 seat. As a result, on
--   2026-11-12 our API still showed four people who left these seats on 2026-11-03.
--   Found by the ev-qa weekly self-check (2026-11-09); EmpoweredVote/ev-accounts#1398.
--
-- WHAT HAPPENED (2026-11-03 general election; results read 2026-11-12):
--   House 45  Bruce Borders lost the May 2026 Republican primary to Kellie Streeter, so he was not on
--             the November ballot. Streeter (R) 13,410 (69.6%) d. Rebecca "Becky" Mayfield (D) 5,856.
--             https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election ;
--             primary: https://indianacapitalchronicle.com/2026/05/05/anti-incumbent-fever-not-evident-in-indiana-house-races/
--   House 62  Amy Huffman Oliver (D) 15,748 (59.3%) d. Dave Hall (R, incumbent) 10,799 (40.7%).
--             AP, as already recorded on our candidacy rows by CC_0381 (result 'won' / 'lost',
--             result_certainty 'called'); the Wikipedia table gives the same counts.
--   House 63  Shane M Lindauer (R) did not run. Amy Kippenbrock (R) won with 61%. (Wikipedia, above.)
--   Senate 39 Eric S Bassler (R) did not run. Jeff Ellington (R) won unopposed, 100%.
--             https://en.wikipedia.org/wiki/2026_Indiana_Senate_election — Ellington is the former
--             House 62 member (2015–2022).
--   ⚠ These are election-night results, not Indiana's certified canvass. Every winner here won by
--   more than 18 points or unopposed. Someone should re-read the Indiana Election Division's
--   certified results once they are posted and correct this file's rows if any differ.
--
-- HOW IT IS MODELLED. Each seat: seat_officeholder(office, winner, 2026-11-04, ..., 'elected', 'day',
--   <how the outgoing term ended>). The helper closes the outgoing term at 2026-11-03.
--     House 45   Borders   -> Streeter     how_ended 'defeated'  (lost the primary for this term)
--     House 62   Hall      -> Oliver       how_ended 'defeated'
--     House 63   Lindauer  -> Kippenbrock  how_ended 'retired'
--     Senate 39  Bassler   -> Ellington    how_ended 'retired'
--   Office ids are the ones our API reported for each seat's holder on 2026-11-12.
--   Oliver already exists: her person row is read from CC_0381's candidacy row
--   (race_candidates ca3a0f51-5087-4735-84e8-f85b881236a6). Streeter, Kippenbrock and Ellington
--   are inserted unless a same-name person already exists — see the pre-gate, which RAISES rather than
--   guess, because Ellington in particular may already have a row from his earlier House years.
--   To reuse an existing row, put its id in the `reuse_id` column of ca0374_new below and re-run.
--
-- 🔴 PRIOR VALUES (an UPDATE is final; there is no history table). Read from our public API on
--   2026-11-12. The four outgoing terms are open: term_end NULL; their starts are Borders
--   2014-11-05, Hall 2022-11-09, Lindauer 2017-01-01 (precision 'year'), Bassler 2014-11-05.
--   how_ended on them is not visible through the API; seat_officeholder only fills it when NULL
--   (COALESCE), so a value already there is kept. politicians.is_incumbent is true for all four.
--   Their office_terms.source values are appended to, never replaced.
--
-- 🔴 WHAT IS DELIBERATELY NOT WRITTEN.
--   Senate 46  Andrea Hunley did not run; Allissa Impink was the Democratic nominee, but I could not
--              read a general-election result, so the seat is left as it is.
--   House 96–100 (Porter, Moed, Shackleford, Summers, Johnson): November results not read.
--   No race, candidacy or transition-tracker row is written. Hall's and Oliver's 2026 candidacy
--   rows (CC_0381) already say lost / won; their is_incumbent values are right before and after
--   this file (Hall held the seat on election day, Oliver did not), and the incumbency guard checks it.
--   The deprecated politicians.office_id snapshot is not written.
--
-- Idempotent: seat_officeholder is idempotent on (office, person, start); the inserts, source appends
-- and flag writes are guarded on the values they change.
--
-- NOT YET DRY-RUN. Written without production access. Before applying:
--   node backend/scripts/dry-run-migration.mjs backend/migrations/CA_0374_in_legislature_nov4_seating.sql

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- The plan.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE ca0374_seats ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('30451f34-837d-4474-96b2-b75dfc37f7ad'::uuid, 'Indiana House of Representatives - District 45',
   '6882686d-8db8-445c-9a5c-8f85f0c1ad5e'::uuid, 'Bruce Borders',    'defeated', 'Kellie Streeter',
   'CA_0374: Kellie Streeter (R) 13,410 (69.6%) d. Rebecca "Becky" Mayfield (D) 5,856, 2026-11-03 general (https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election, read 2026-11-12; election-night, not certified); term begins "from the day next after their general election" (Ind. Const. art. 4 §3)',
   'CA_0374: lost the May 2026 Republican primary to Kellie Streeter (https://indianacapitalchronicle.com/2026/05/05/anti-incumbent-fever-not-evident-in-indiana-house-races/); term ended 2026-11-03, the day before the new term began (Ind. Const. art. 4 §3)'),
  ('847135b4-5bd6-46e2-87e4-41bd792097bd'::uuid, 'Indiana House of Representatives - District 62',
   'e971c7f2-3ab2-483d-97a4-7fe919365f98'::uuid, 'Dave Hall',        'defeated', 'Amy Huffman Oliver',
   'CA_0374: Amy Huffman Oliver (D) 15,748 (59.3%) d. Dave Hall (R) 10,799, 2026-11-03 general (AP, recorded by CC_0381 as called; https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election, read 2026-11-12); term begins "from the day next after their general election" (Ind. Const. art. 4 §3)',
   'CA_0374: defeated by Amy Huffman Oliver on 2026-11-03 (AP via CC_0381); term ended 2026-11-03 (Ind. Const. art. 4 §3)'),
  ('705ce366-6fb8-45f1-8424-a37725c1d704'::uuid, 'Indiana House of Representatives - District 63',
   'c2f7b661-b9cc-4fc4-929e-6d5c776d0f17'::uuid, 'Shane M Lindauer', 'retired',  'Amy Kippenbrock',
   'CA_0374: Amy Kippenbrock (R) won with 61%, 2026-11-03 general (https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election, read 2026-11-12; election-night, not certified); term begins "from the day next after their general election" (Ind. Const. art. 4 §3)',
   'CA_0374: did not seek re-election in 2026 (https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election); term ended 2026-11-03 (Ind. Const. art. 4 §3)'),
  ('0e0178dc-ea70-415a-a739-880c33e8c9db'::uuid, 'Indiana State Senate - District 39',
   'f7327a6f-1eb9-4714-9b3f-519916b436d5'::uuid, 'Eric S Bassler',   'retired',  'Jeff Ellington',
   'CA_0374: Jeff Ellington (R) won unopposed, 2026-11-03 general (https://en.wikipedia.org/wiki/2026_Indiana_Senate_election, read 2026-11-12; election-night, not certified); term begins "from the day next after their general election" (Ind. Const. art. 4 §3)',
   'CA_0374: declined to seek re-election in 2026 (https://en.wikipedia.org/wiki/2026_Indiana_Senate_election); term ended 2026-11-03 (Ind. Const. art. 4 §3)')
) v(office_id, seat, outgoing_id, outgoing_name, how_ended, incoming_name, incoming_source, outgoing_note);

-- The three winners we may not hold yet. reuse_id: set it to an existing politicians.id to reuse
-- that row instead of inserting (the pre-gate tells you when you must decide).
CREATE TEMP TABLE ca0374_new ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Kellie Streeter', 'Kellie', 'Streeter',    'Republican', NULL::uuid,
   'CA_0374 Indiana House District 45, elected 2026-11-03 (https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election, read 2026-11-12)'),
  ('Amy Kippenbrock', 'Amy',    'Kippenbrock', 'Republican', NULL::uuid,
   'CA_0374 Indiana House District 63, elected 2026-11-03 (https://en.wikipedia.org/wiki/2026_Indiana_House_of_Representatives_election, read 2026-11-12)'),
  ('Jeff Ellington',  'Jeff',   'Ellington',   'Republican', NULL::uuid,
   'CA_0374 Indiana State Senate District 39, elected 2026-11-03 (https://en.wikipedia.org/wiki/2026_Indiana_Senate_election, read 2026-11-12)')
) v(full_name, first_name, last_name, party, reuse_id, source);

-- ---------------------------------------------------------------------------------------------
-- Pre-gate: each seat is still the state this was written against (or already the end state).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad text; v_n int;
BEGIN
  -- Each office exists and the outgoing person holds it either open-ended (before) or through
  -- 2026-11-03 (a re-run).
  SELECT string_agg(s.seat || ' / ' || s.outgoing_name, '; ') INTO v_bad
    FROM ca0374_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices f WHERE f.id = s.office_id)
      OR NOT EXISTS (SELECT 1 FROM essentials.politicians p
                      WHERE p.id = s.outgoing_id AND p.full_name = s.outgoing_name)
      OR NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.outgoing_id
                        AND (t.term_end IS NULL OR t.term_end = '2026-11-03'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0374 pre-gate: seat not in the expected state: %', v_bad;
  END IF;

  -- Nobody but the outgoing person holds any of these offices on or after 2026-11-04, except this
  -- file's own winners on a re-run.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t JOIN ca0374_seats s ON s.office_id = t.office_id
   WHERE t.politician_id <> s.outgoing_id
     AND (t.term_end IS NULL OR t.term_end >= '2026-11-04')
     AND t.source NOT LIKE 'CA_0374:%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0374 pre-gate: % other term(s) already cover these seats after 2026-11-03 — another session may have seated them', v_n;
  END IF;

  -- Oliver's candidacy row is the one CC_0381 wrote, on House 62, marked won, linked to a person
  -- named Amy Huffman Oliver.
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                   JOIN essentials.races r ON r.id = rc.race_id
                   JOIN essentials.politicians p ON p.id = rc.politician_id
                  WHERE rc.id = 'ca3a0f51-5087-4735-84e8-f85b881236a6'
                    AND r.id = 'a1d1a61b-4c6f-45fa-805a-bcf8d74aa6b2'
                    AND r.office_id = '847135b4-5bd6-46e2-87e4-41bd792097bd'
                    AND rc.result = 'won'
                    AND p.full_name = 'Amy Huffman Oliver') THEN
    RAISE EXCEPTION 'CA_0374 pre-gate: Oliver''s House 62 candidacy is not the won row CC_0381 wrote, on this office';
  END IF;

  -- A winner we would insert must not already exist under another source, unless reuse_id says
  -- which row to use. Raise rather than guess: a same-name row may be a different person.
  SELECT string_agg(format('%s (existing id(s): %s)', n.full_name,
           (SELECT string_agg(p.id::text || ' source=' || coalesce(p.source, '∅'), ', ')
              FROM essentials.politicians p
             WHERE lower(p.last_name) = lower(n.last_name)
               AND lower(p.first_name) = lower(n.first_name))), '; ')
    INTO v_bad
    FROM ca0374_new n
   WHERE n.reuse_id IS NULL
     AND EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE lower(p.last_name) = lower(n.last_name)
                    AND lower(p.first_name) = lower(n.first_name)
                    AND coalesce(p.source, '') NOT LIKE 'CA_0374 %');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0374 pre-gate: a same-name person already exists — check each and set reuse_id in ca0374_new (or confirm a different person and rename the check): %', v_bad;
  END IF;

  SELECT string_agg(n.full_name, ', ') INTO v_bad
    FROM ca0374_new n
   WHERE n.reuse_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = n.reuse_id);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0374 pre-gate: reuse_id does not exist for: %', v_bad;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- The new people (only those not reused, and only once).
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, party, is_active, is_incumbent, is_appointed, source)
SELECT n.full_name, n.first_name, n.last_name, n.party, true, true, false, n.source
  FROM ca0374_new n
 WHERE n.reuse_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.last_name = n.last_name AND p.first_name = n.first_name
                      AND p.source LIKE 'CA_0374 %');

-- Resolve every winner to a person id.
ALTER TABLE ca0374_seats ADD COLUMN incoming_id uuid;

UPDATE ca0374_seats s
   SET incoming_id = coalesce(n.reuse_id,
                              (SELECT p.id FROM essentials.politicians p
                                WHERE p.last_name = n.last_name AND p.first_name = n.first_name
                                  AND p.source LIKE 'CA_0374 %'))
  FROM ca0374_new n
 WHERE n.full_name = s.incoming_name;

UPDATE ca0374_seats s
   SET incoming_id = (SELECT rc.politician_id FROM essentials.race_candidates rc
                       WHERE rc.id = 'ca3a0f51-5087-4735-84e8-f85b881236a6')
 WHERE s.incoming_name = 'Amy Huffman Oliver';

CREATE TEMP TABLE ca0374_people ON COMMIT DROP AS
SELECT outgoing_id AS politician_id FROM ca0374_seats
UNION
SELECT incoming_id FROM ca0374_seats;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM ca0374_seats WHERE incoming_id IS NULL) THEN
    RAISE EXCEPTION 'CA_0374: a winner did not resolve to a person: %',
      (SELECT string_agg(incoming_name, ', ') FROM ca0374_seats WHERE incoming_id IS NULL);
  END IF;
  IF (SELECT count(*) FROM ca0374_people WHERE politician_id IS NOT NULL) <> 8 THEN
    RAISE EXCEPTION 'CA_0374: expected 8 people in scope, found %', (SELECT count(*) FROM ca0374_people);
  END IF;
END $$;


-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

-- @incumbency-decision: gated — closes Borders, Hall, Lindauer and Bassler at 2026-11-03 and seats Streeter, Oliver, Kippenbrock and Ellington from 2026-11-04; Hall and Oliver have 2026 race rows on House 62 and neither moves (Hall held the seat on election day, Oliver did not)

-- Snapshot what the cached column says, and what office_terms says, for every race row belonging to
-- a person this migration touches. `expected` is reconcile-incumbency.mjs's own SQL.
--
-- ⚠ KEEP THE `expected` EXPRESSION AND THE THREE WHERE CLAUSES CHARACTER-IDENTICAL TO THE SCRIPT
-- (backend/scripts/reconcile-incumbency.mjs, computeIncumbencyDrift). If they drift apart, this
-- passes while CI fails, which is worse than having no guard — you would then believe the question
-- had been asked.
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM ca0374_people);

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲

-- ---------------------------------------------------------------------------------------------
-- Write: seat each winner from 2026-11-04 (closes the outgoing term at 2026-11-03).
-- ---------------------------------------------------------------------------------------------
SELECT s.seat, essentials.seat_officeholder(
         s.office_id, s.incoming_id, '2026-11-04', s.incoming_source, 'elected', 'day', s.how_ended)
  FROM ca0374_seats s
 ORDER BY s.seat;

-- Say on each closed term why it closed.
UPDATE essentials.office_terms t
   SET source = coalesce(t.source, '') || ' | ' || s.outgoing_note
  FROM ca0374_seats s
 WHERE t.office_id = s.office_id
   AND t.politician_id = s.outgoing_id
   AND t.term_end = '2026-11-03'
   AND coalesce(t.source, '') NOT LIKE '%CA_0374:%';

-- Cached flags: the four who left hold no other seat in our data unless office_current_holder says
-- so; the four winners now hold one.
UPDATE essentials.politicians p SET is_incumbent = false
  FROM ca0374_seats s
 WHERE p.id = s.outgoing_id
   AND p.is_incumbent IS DISTINCT FROM false
   AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);

UPDATE essentials.politicians p SET is_incumbent = true
  FROM ca0374_seats s
 WHERE p.id = s.incoming_id
   AND p.is_incumbent IS DISTINCT FROM true;

-- ▼▼ BLOCK B — PASTE AFTER YOUR LAST WRITE TO essentials.office_terms, BEFORE COMMIT ▼▼

DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM ca0374_people;
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

-- ▲▲ END OF BLOCK B ▲▲

-- ---------------------------------------------------------------------------------------------
-- Post-gate, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_bad text; v_n int;
BEGIN
  -- Each seat resolves to exactly its winner today.
  SELECT string_agg(s.seat || ' resolves to ' || coalesce(p.full_name, '(nobody)'), '; ') INTO v_bad
    FROM ca0374_seats s
    LEFT JOIN essentials.office_current_holder och ON och.office_id = s.office_id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.politician_id IS DISTINCT FROM s.incoming_id;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0374 gate: %', v_bad; END IF;

  -- Each outgoing term is closed at 2026-11-03 with a how_ended, and says why.
  SELECT count(*) INTO v_n
    FROM ca0374_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.outgoing_id
                        AND t.term_end = '2026-11-03' AND t.how_ended IS NOT NULL
                        AND t.source LIKE '%CA_0374:%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0374 gate: % outgoing term(s) not closed as described', v_n; END IF;

  -- Each winner's term starts 2026-11-04, open-ended, elected.
  SELECT count(*) INTO v_n
    FROM ca0374_seats s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                      WHERE t.office_id = s.office_id AND t.politician_id = s.incoming_id
                        AND t.term_start = '2026-11-04' AND t.term_end IS NULL
                        AND t.how_started = 'elected');
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0374 gate: % winner term(s) missing', v_n; END IF;

  -- No seat is flagged vacant.
  SELECT count(*) INTO v_n
    FROM essentials.offices f JOIN ca0374_seats s ON s.office_id = f.id
   WHERE f.is_vacant OR f.vacant_since IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0374 gate: % seat(s) flagged vacant', v_n; END IF;

  -- Exactly the three new people were inserted (or reused), never more.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE source LIKE 'CA_0374 %';
  IF v_n > 3 THEN RAISE EXCEPTION 'CA_0374 gate: % CA_0374 person rows (expected at most 3)', v_n; END IF;

  -- Cached incumbency flags agree with the seats for all eight people.
  SELECT count(*) INTO v_n
    FROM ca0374_people c JOIN essentials.politicians p ON p.id = c.politician_id
   WHERE p.is_incumbent IS DISTINCT FROM
         EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'CA_0374 gate: % person/people with is_incumbent out of step with their seats', v_n; END IF;
END $$;

COMMIT;

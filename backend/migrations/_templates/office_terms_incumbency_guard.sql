-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- TEMPLATE — paste into any migration that WRITES essentials.office_terms: inserting a term,
-- closing one, moving a term_start or term_end, or NULLing a date back out.
-- Not a migration. Nothing here runs on its own; `_templates/` carries no slot, so the numbering,
-- reservation and answer-delete checks all skip it.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
-- 🔴 WHY THIS EXISTS. On 2026-11-11, CC_0394 put dates on 290 tenures and turned MASTER CI red on
-- `check:incumbency` — a gate that runs only on push, schedule and manual dispatch, never on a PR
-- (the `reachability` job carries `if: github.event_name != 'pull_request'`). So it did not fail on
-- the pull request that caused it. It failed on the NEXT one, and named an innocent author. Six rows
-- from CC_0394; CC_0395 made it seven by sharpening Allen TX's mayor from "May 2026" to 2026-05-26.
-- CC_0396 cleaned it up, three migrations downstream of the change that did it.
--
-- 🔑 THE MECHANISM, AND IT IS NOT OBVIOUS. `race_candidates.is_incumbent` means "incumbent OF THE
-- SEAT THIS RACE IS FOR, measured on the race's own election date" (ruled 2026-11-04, widened for
-- multi-seat races 2026-11-07). Nothing recomputes it. So the moment you write a term_start, you have
-- silently restated who held that seat on every election day the term now fails to cover — and the
-- cached column still says what it said yesterday. A date you make MORE precise can do this; a date
-- you ADD to a previously open-ended term does it most often.
--
-- ⚠ THE SNAPSHOT COLUMN THAT CAUSED IT IS STILL THERE. `politicians.valid_from` records the start of
-- the person's CURRENT TERM, not the start of their tenure. For a newcomer those are the same date.
-- For someone RE-ELECTED it is their second or third term's start, and writing it as the tenure start
-- asserts they were not in office before it — which is false, and is exactly what went red. If your
-- migration copies a date from a per-person column, assume some of your rows are the second kind.
--
-- ⚠ A GUARD ON THE TOTAL IS NOT THIS GUARD. `check:incumbency` reports every drifted row in the
-- database, and most of them are not yours — the first measurement of it found 429 rows of which 9
-- were real. A migration that failed on the total would be unmergeable for other people's drift, and
-- would tempt you to "fix" rows you have not read. This gate is a DELTA: it fires only on a row that
-- AGREED with office_terms before your write and DISAGREES after it.
--
-- ⚠ AND DO NOT ANSWER IT WITH `--apply`. `reconcile-incumbency.mjs --apply` reads only the predicate.
-- Run against CC_0394's seven rows it would have flipped all seven race rows to false and published
-- three sitting officeholders as challengers for their own seats. CC_0396's header splits the two
-- cases; read it before you decide anything.
--
-- ── HOW TO USE ─────────────────────────────────────────────────────────────────────────────────
-- 1. Your migration almost certainly already has a plan/target table naming the people it touches —
--    `v_plan`, `ts_plan`, `my_target`. If it does not, make one. You need a column of politician ids.
-- 2. 🔴 SCOPE IT TO BOTH SIDES OF A SEATING. The scope is EVERY politician whose office_terms rows
--    this migration inserts, updates or deletes — the person arriving AND the predecessor whose term
--    you close. `essentials.seat_officeholder` closes the predecessor for you, so a migration that
--    only ever names the newcomer still moves the other person's dates.
-- 3. Paste block A immediately BEFORE your first write to office_terms. Paste block B after the last
--    one, before COMMIT.
-- 4. Your migration must run as ONE transaction (the house `BEGIN; … COMMIT;`). `ON COMMIT DROP`
--    needs that, and so does the before/after comparison.
--
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- ▼▼ BLOCK A — PASTE BEFORE YOUR FIRST WRITE TO essentials.office_terms ▼▼

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
   AND rc.politician_id IN (SELECT politician_id FROM my_plan);   -- ⚠ REPLACE with your plan table

-- 🔴 `o2` IS THE SCRIPT'S OWN ALIAS AND IT IS A TRAP. Never write `o2.politician_id` anywhere near
-- this block. `check:occupancy` reads `o<digits>.politician_id` as the dropped essentials.offices
-- column — that is the repo's offices alias convention — and CC_0394 turned the "static guards" job
-- red on exactly that. Here `o2` is only ever read for `chamber_id`, which is safe. Rename it to
-- something not starting with `o` if you need any other column off it.

-- ▲▲ END OF BLOCK A ▲▲
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
--   … your INSERT / UPDATE / seat_officeholder() / vacate_office() calls go here …
--
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
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
  SELECT count(*) INTO v_planned FROM my_plan;   -- ⚠ REPLACE with your plan table
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
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
-- ── IF THE GUARD FIRES ─────────────────────────────────────────────────────────────────────────
-- It is telling you that your dates and the cached column now disagree about who held a seat on an
-- election day. One of the two is wrong, and WHICH ONE IS NOT A PREDICATE QUESTION:
--
--   Did this person first take the seat at the date you just wrote?
--     YES -> they are a NEWCOMER. The date stands; the race row is stale. Flip
--            race_candidates.is_incumbent to false here, and say in the header what established it
--            (CC_0396 used a resolution signed by the OUTGOING mayor, and a Form 13-1 certification
--            naming a SPECIAL election — a special election fills a seat its winner does not hold).
--     NO  -> they were RE-ELECTED and your date is their latest term's start, not their tenure's.
--            The race row is right. Do not write the date. `start_precision => 'unknown'` on an
--            open-ended term is the honest shape, and CLAUDE.md's "FIRST ELECTED IS NOT A TERM
--            START" rule is the same mistake wearing a different hat.
--
-- ⚠ A MULTI-SEAT RACE IS FOR SEVERAL SEATS BUT HANGS OFF ONE OFFICE. If your row is in a race with
-- seats > 1, the rule widens to "holds ANY office of that race office's chamber on election day"
-- (ruled 2026-11-07 after the seat-only rule called 128 sitting members challengers and turned master
-- red on CC_0364's four board members). The `expected` expression above already implements it — do
-- not simplify it away when you paste it.
--
-- ── WATCH IT FAIL BEFORE YOU TRUST IT ──────────────────────────────────────────────────────────
-- A gate nobody has seen go red is not a gate. Inside your BEGIN/ROLLBACK dry run, push one of your
-- own written dates past the election date of a race that person is in and confirm the EXCEPTION
-- names them; then put it back. If it does not fire, your plan table is not the one the scope
-- subquery reads.
--
-- Related: CC_0394 (the 290 dates), CC_0395 (the seventh row), CC_0396 (the split, and the four
-- newcomer sources), backend/scripts/reconcile-incumbency.mjs, CI job "address-search reachability",
-- step "Check incumbency has not drifted from office_terms".

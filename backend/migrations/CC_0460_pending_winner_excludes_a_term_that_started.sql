-- CC_0460 — essentials.office_pending_winner: a seat whose new term HAS ALREADY STARTED is not
--            waiting for anything, and must leave this view.
--
-- 🔴 THE DEFECT, AND IT TELLS A VOTER THE OPPOSITE OF THE TRUTH.
--
-- CC_0458 kept this view disjoint from essentials.office_next_term. But office_next_term is
-- defined as `term_start > CURRENT_DATE`. So an office leaves THAT view on the morning its term
-- begins — and because its race result is still sitting in race_candidates, it immediately
-- qualifies for THIS one. The seat goes straight from "a successor is coming on <date>" to
-- "somebody won an election and we do not know when they start", on the day we were proudest of.
--
-- Measured on prod 2026-11-21: ELEVEN offices are already in this state. Four are Indiana
-- legislators seated by CA_0374 on 2026-11-04 under Ind. Const. art. 4 §3 ("term begins the day
-- next after their general election"), the citation recorded in each term's own source:
--
--     IN House  — Kellie Streeter   replaced Bruce Borders      term_start 2026-11-04
--     IN House  — Amy Kippenbrock   replaced Shane M Lindauer   term_start 2026-11-04
--     IN House  — Amy Oliver        replaced Dave Hall          term_start 2026-11-04
--     IN Senate — Jeffrey Ellington replaced Eric S Bassler     term_start 2026-11-04
--
-- All four are single-seat districts, so the display resolves them to the re-election case and
-- the card reads "Declared re-elected November 3 — date of the new term not yet confirmed".
-- BOTH HALVES ARE FALSE. Not one of them was re-elected — each replaced a different person — and
-- the term's start date is confirmed, is in our own database, and was seventeen days ago.
--
-- 🔴 IT SCALES ON A DATE NOBODY HAS TO TOUCH. 519 of the 638 offices that carry a dated future
-- term ALSO carry a qualifying won result, so each flips into this view the day its term begins.
-- The first is 2026-12-01. The Los Angeles Mayor — the seat this whole feature was built for —
-- flips on 2026-12-14. On 2027-01-03 every federal seat CC_0453 dated acquires a line saying its
-- date is not confirmed, and the 172 who are genuinely new arrivals are described as re-elected.
--
-- THE FIX. CC_0458's own header says "a dated term always wins: it is the stronger fact". That
-- rule was only half applied — to terms that have not started. Applied to terms that HAVE
-- started it is the same rule, and it subsumes the office_next_term check entirely: any term at
-- or after the election date means the result has already been acted on.
--
-- ⚠ `term_start >= e.election_date`, NOT `>= CURRENT_DATE`. The question is whether THIS
-- election's result has been recorded as a term, not whether some older term exists. An
-- incumbent's current term started before the election and must not exclude the seat.
--
-- ⚠ OVERWRITES CC_0458's DEFINITION OF THIS VIEW. The previous `latest` CTE predicate was:
--
--        WHERE e.election_type IN ('general', 'special')
--          AND EXISTS (SELECT 1 FROM essentials.race_candidates rc
--                       WHERE rc.race_id = r.id AND rc.result = 'won')
--          AND NOT EXISTS (SELECT 1 FROM essentials.office_next_term ont
--                           WHERE ont.office_id = o.id)
--
-- Everything else about the view is byte-for-byte CC_0458's. district_seat_group is untouched
-- and continues to read this view, so its counts follow automatically.

BEGIN;

CREATE OR REPLACE VIEW essentials.office_pending_winner
WITH (security_invoker = on) AS
WITH latest AS (
  SELECT DISTINCT ON (o.id)
         o.id AS office_id,
         r.id AS race_id,
         e.election_date,
         r.seats
    FROM essentials.offices o
    JOIN essentials.races r     ON r.office_id = o.id
    JOIN essentials.elections e ON e.id        = r.election_id
   WHERE e.election_type IN ('general', 'special')
     AND EXISTS (SELECT 1
                   FROM essentials.race_candidates rc
                  WHERE rc.race_id = r.id
                    AND rc.result  = 'won')
     -- 🔴 A DATED TERM ALWAYS WINS, WHETHER OR NOT IT HAS STARTED YET. See the header: the
     -- version that tested only office_next_term let a seat fall out of that view and into this
     -- one at midnight on the day its term began.
     AND NOT EXISTS (SELECT 1
                       FROM essentials.office_terms t
                      WHERE t.office_id  = o.id
                        AND t.term_start >= e.election_date)
   ORDER BY o.id, e.election_date DESC, r.id
)
SELECT l.office_id,
       l.race_id,
       l.election_date,
       l.seats,
       CASE WHEN bool_and(rc.result_certainty = 'certified') THEN 'certified' ELSE 'called' END
         AS certainty,
       count(*)::int AS winner_count,
       jsonb_agg(jsonb_build_object('id', rc.politician_id, 'name', rc.full_name)
                 ORDER BY rc.full_name) AS winners
  FROM latest l
  JOIN essentials.race_candidates rc ON rc.race_id = l.race_id AND rc.result = 'won'
 GROUP BY l.office_id, l.race_id, l.election_date, l.seats;

COMMENT ON VIEW essentials.office_pending_winner IS
  'Who won this seat, for seats where that result has NOT yet been recorded as an office_terms '
  'row. One row per office, from the most recent general or special election it carries a won '
  'result for. An office with a term dated at or after that election never appears here, whether '
  'that term has started or not: a dated term is the stronger fact. An election result is NOT a '
  'fact about who holds the seat, so the read path must label it as a result and never as a '
  'term. CC_0458, CC_0460.';

DO $$
DECLARE
  v_offices       int;
  v_already_began int;
  v_overlap       int;
  v_dupes         int;
  v_orphaned      int;
BEGIN
  SELECT count(*) INTO v_offices FROM essentials.office_pending_winner;

  -- 🔴 THE GATE FOR THIS CHANGE. Not one row may describe a seat whose term for that election
  -- has already been written, started or not.
  SELECT count(*) INTO v_already_began
    FROM essentials.office_pending_winner w
    JOIN essentials.office_terms t ON t.office_id = w.office_id
   WHERE t.term_start >= w.election_date;

  SELECT count(*) INTO v_overlap
    FROM essentials.office_pending_winner w
    JOIN essentials.office_next_term ont ON ont.office_id = w.office_id;

  SELECT count(*) INTO v_dupes FROM (
    SELECT office_id FROM essentials.office_pending_winner
     GROUP BY office_id HAVING count(*) > 1
  ) d;

  -- district_seat_group reads this view, so the two must stay consistent: every office that
  -- still has a pending winner must still resolve a group.
  SELECT count(*) INTO v_orphaned
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o ON o.id = w.office_id
    LEFT JOIN essentials.district_seat_group dsg
           ON dsg.district_id = o.district_id
          AND dsg.chamber_id IS NOT DISTINCT FROM o.chamber_id
   WHERE o.district_id IS NOT NULL AND dsg.group_id IS NULL;

  IF v_already_began <> 0 THEN
    RAISE EXCEPTION 'CC_0460: % office(s) whose term for that election is already recorded are still reported as pending', v_already_began;
  END IF;

  IF v_overlap <> 0 THEN
    RAISE EXCEPTION 'CC_0460: % office(s) appear in BOTH office_pending_winner and office_next_term', v_overlap;
  END IF;

  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0460: % office(s) return more than one pending winner row', v_dupes;
  END IF;

  IF v_orphaned <> 0 THEN
    RAISE EXCEPTION 'CC_0460: % office(s) have a pending winner but NO seat group', v_orphaned;
  END IF;

  -- The delta this migration creates, asserted in its own transaction rather than against a
  -- repo-wide total another session can move. 1,334 before, 11 already-seated offices removed.
  IF v_offices <> 1323 THEN
    RAISE EXCEPTION 'CC_0460: expected 1323 pending offices after removing the 11 already seated, found %', v_offices;
  END IF;

  RAISE NOTICE 'CC_0460 OK: % office(s) pending (was 1334), 0 already seated, 0 overlap, 0 orphaned',
               v_offices;
END $$;

COMMIT;

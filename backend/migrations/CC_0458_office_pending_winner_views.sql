-- CC_0458 — essentials.office_pending_winner and essentials.district_seat_group:
--            who won the seat, for the seats that have no term row yet.
--
-- WHY. CC_0341 gave us essentials.office_next_term, so a seat with a DATED future term can show
-- its successor. 1,334 offices have a recorded election winner and NO term row at all, so they
-- show nothing: the voter sees only the person who is leaving. A winner is not a term — taking
-- office is a separate, later event — so this is a SECOND view with a SECOND meaning, never a
-- widening of office_next_term. The read paths join both and the page renders two different
-- sentences, because they are two different claims.
--
-- 🔴 CONSULTED ONLY WHERE office_next_term HAS NO ROW. The NOT EXISTS below is what keeps the two
-- views disjoint. A dated term always wins: it is the stronger fact, and an office that has one
-- must never also offer an election result, or the read path has to choose and will choose
-- differently in different places.
--
-- 🔴 THE ELECTION FILTER IS ON election_type, NEVER ON A DATE. A naive `result = 'won'` sweeps in
-- PRIMARIES — measured 2026-11-21, the 2026-08-11 primaries alone add 132 offices and 252 winner
-- rows — and a primary winner is a NOMINEE, not an officeholder-elect. Admitting only 'general'
-- and 'special' and taking the most recent one per office is correct today AND at the next
-- special; a hard-coded '2026-11-03' would be correct today and silently wrong in six months.
--
-- 🔴 result = 'won' ONLY. Louisiana's December runoff rows carry result = 'runoff', and a runoff
-- contender is a candidate still running. They must not reach a voter as winners.
--
-- 🔴 OFFICE-ROOTED DE-DUPLICATION, like office_next_term. `DISTINCT ON (o.id)` ordered by
-- election_date DESC takes the most recent qualifying election. A politician-rooted read of the
-- same data needs `DISTINCT ON (p.id)` instead — the right key is opposite in each direction.
--
-- ⚠ A MULTI-SEAT RACE ATTACHES ALL ITS WINNERS TO ONE OFFICE ROW. Maryland House District 13
-- elects three delegates and one race carries three winners pointing at a single office. So
-- `winners` is an ARRAY, `winner_count` can exceed 1, and "the winner of this office's race" is
-- NOT the same question as "who will hold this seat". The second view exists for that gap.
--
-- 🔴 district_seat_group COUNTS och.politician_id, NOT count(*). office_current_holder LEFT JOINs
-- from offices, so a vacancy is a row with a NULL politician_id and count(*) would count the empty
-- seats as occupied — the vacuous pass CLAUDE.md warns about. The group arrow is only drawn when
-- offices = winners = seated, so an inflated `seated` would draw an arrow for a body that is not
-- whole.
--
-- No RLS statement: a view does not carry its own policies. `security_invoker = on` makes the
-- underlying tables' RLS apply as the calling user, rather than as the view's owner.

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
     AND NOT EXISTS (SELECT 1
                       FROM essentials.office_next_term ont
                      WHERE ont.office_id = o.id)
   ORDER BY o.id, e.election_date DESC, r.id
)
SELECT l.office_id,
       l.race_id,
       l.election_date,
       l.seats,
       -- 🔴 A GROUP IS ONLY AS CERTIFIED AS ITS WEAKEST ROW. bool_and, not bool_or: one called
       -- winner holds the whole office at the weaker wording, because the card's sentence is a
       -- claim about all of them. Measured 2026-11-21: 1,943 of 1,945 November winners are
       -- 'called' and 2 are 'certified', so almost every card ships on an unofficial count and
       -- says so until the canvass finishes.
       CASE WHEN bool_and(rc.result_certainty = 'certified') THEN 'certified' ELSE 'called' END
         AS certainty,
       count(*)::int AS winner_count,
       jsonb_agg(jsonb_build_object('id', rc.politician_id, 'name', rc.full_name)
                 ORDER BY rc.full_name) AS winners
  FROM latest l
  JOIN essentials.race_candidates rc ON rc.race_id = l.race_id AND rc.result = 'won'
 GROUP BY l.office_id, l.race_id, l.election_date, l.seats;

COMMENT ON VIEW essentials.office_pending_winner IS
  'Who won this seat, for seats that have no office_terms row for the new term yet. One row per '
  'office, from the most recent general or special election it carries a won result for. '
  'Disjoint from essentials.office_next_term by construction: an office with a dated future term '
  'never appears here. An election result is NOT a fact about who holds the seat, so the read '
  'path must label it as a result and never as a term. CC_0458.';

CREATE OR REPLACE VIEW essentials.district_seat_group
WITH (security_invoker = on) AS
SELECT o.district_id,
       o.chamber_id,
       o.district_id::text || '|' || COALESCE(o.chamber_id::text, '') AS group_id,
       count(*)::int                              AS offices,
       -- 🔴 NOT count(*) — see the header. A vacancy is a row with a NULL politician_id.
       count(och.politician_id)::int              AS seated,
       COALESCE(sum(w.winner_count), 0)::int      AS winners
  FROM essentials.offices o
  LEFT JOIN essentials.office_current_holder och  ON och.office_id = o.id
  LEFT JOIN essentials.office_pending_winner w    ON w.office_id   = o.id
 -- 🔴 A GROUP IS A DISTRICT FACT, AND 25 OFFICES CARRY NO DISTRICT. Without this the group_id
 -- expression evaluates to NULL for every one of them (anything || NULL is NULL), all those NULLs
 -- collapse into a single group under GROUP BY, and the duplicate-group_id gate below fires. They
 -- are also unreachable from the read path either way: it joins on dsg.district_id = o.district_id,
 -- and NULL = NULL is not a match. Excluding them loses no seat and makes group_id non-null by
 -- construction. Found by this migration's own gate on the first dry run.
 WHERE o.district_id IS NOT NULL
 GROUP BY o.district_id, o.chamber_id;

COMMENT ON VIEW essentials.district_seat_group IS
  'The three counts the multi-seat group display needs, one row per (district_id, chamber_id): '
  'how many office rows the body has here, how many of them someone sits in today, and how many '
  'election winners are recorded across them. The group-to-group arrow is permitted ONLY when all '
  'three agree — a staggered body (five members, three seats up) would otherwise draw an arrow '
  'from five people to three and imply the body is shrinking. CC_0458.';

GRANT SELECT ON essentials.office_pending_winner  TO anon, authenticated, service_role, ev_api;
GRANT SELECT ON essentials.district_seat_group    TO anon, authenticated, service_role, ev_api;

DO $$
DECLARE
  v_offices      int;
  v_winner_rows  int;
  v_clean_groups int;
  v_dupes        int;
  v_overlap      int;
  v_wrong_type   int;
  v_group_dupes  int;
  v_oversubscribed int;
BEGIN
  SELECT count(*), COALESCE(sum(winner_count), 0)
    INTO v_offices, v_winner_rows
    FROM essentials.office_pending_winner;

  SELECT count(*) INTO v_dupes FROM (
    SELECT office_id FROM essentials.office_pending_winner
     GROUP BY office_id HAVING count(*) > 1
  ) d;

  SELECT count(*) INTO v_overlap
    FROM essentials.office_pending_winner w
    JOIN essentials.office_next_term ont ON ont.office_id = w.office_id;

  SELECT count(*) INTO v_wrong_type
    FROM essentials.office_pending_winner w
    JOIN essentials.races r     ON r.id = w.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_type NOT IN ('general', 'special');

  SELECT count(*) INTO v_group_dupes FROM (
    SELECT group_id FROM essentials.district_seat_group
     GROUP BY group_id HAVING count(*) > 1
  ) g;

  SELECT count(*) INTO v_oversubscribed
    FROM essentials.district_seat_group WHERE seated > offices;

  SELECT count(*) INTO v_clean_groups
    FROM essentials.district_seat_group
   WHERE offices > 1 AND winners > 0 AND offices = winners AND offices = seated;

  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0458: % office(s) return more than one pending winner row', v_dupes;
  END IF;

  IF v_overlap <> 0 THEN
    RAISE EXCEPTION 'CC_0458: % office(s) appear in BOTH office_pending_winner and office_next_term; the two views must be disjoint', v_overlap;
  END IF;

  IF v_wrong_type <> 0 THEN
    RAISE EXCEPTION 'CC_0458: % row(s) come from an election that is not a general or a special', v_wrong_type;
  END IF;

  IF v_group_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0458: % group_id(s) appear more than once in district_seat_group', v_group_dupes;
  END IF;

  IF v_oversubscribed <> 0 THEN
    RAISE EXCEPTION 'CC_0458: % group(s) report more people seated than they have offices', v_oversubscribed;
  END IF;

  RAISE NOTICE 'CC_0458 OK: % office(s) with a pending winner, % winner row(s), % clean multi-seat group(s)',
               v_offices, v_winner_rows, v_clean_groups;
END $$;

COMMIT;

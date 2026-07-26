-- 1476: re-date the one row migration 1457 deliberately left overdue — AZ-02, Curtis Goodwin
--
-- 1457 resolved 16 of the 17 rows that 1456 exposed as past their provisional_until, and
-- documented the seventeenth as "STILL PROVISIONAL (1) — deliberately left alone, NOT cleared and
-- NOT culled". Its reasoning was correct and is unchanged: Goodwin ran in the 2026-07-21 Arizona
-- Libertarian primary for CD2 against Alex Flores (write-in), Ballotpedia still reports "The
-- outcome of this election has not been called yet", and the AZ-02 general-election field still
-- lists only Eli Crane and Jonathan Nez with "Additional general election candidates will be added
-- here following the primary". He is genuinely unresolved.
--
-- WHAT IS NEW: the date resolution becomes possible. 1457 had no date to point at, so it left the
-- row at its expired 2026-07-22 value and relied on it surfacing in stale_provisional_candidates
-- indefinitely. The Arizona SoS election calendar (azsos.gov/elections/calendar-dates) gives it:
--   2026-08-06  Official Statewide Canvass of the July 21, 2026 Primary Election
--   2026-08-11  deadline to challenge a primary result in court (5 days after the canvass)
-- Until the canvass, every AZ result is unofficial, so the Libertarian nomination cannot be
-- confirmed no matter how often anyone looks. Re-dating to 2026-08-06 turns a permanently-overdue
-- row into a scheduled one.
--
-- WHY last_verified_at IS ALSO STAMPED, and why that does not hide the row: 1457 notes the stamp
-- "is what keeps them out of the stale view regardless of provisional_until" — true for its rows,
-- whose dates were in the PAST (last_verified_at < provisional_until went false). Here
-- provisional_until moves to the FUTURE, so last_verified_at (2026-07-26) < 2026-08-06 still
-- holds: the row keeps the flag, keeps rendering the reader-facing note, and re-enters
-- stale_provisional_candidates by itself on 2026-08-06. The stamp only records that a human
-- actually re-checked today.
--
-- Reader-facing effect (electionService.PROVISIONAL_UNTIL, live since master e0e2b936): the AZ-02
-- note stops saying "past its 22 July 2026 re-verification date and may be out of date" and starts
-- saying "deadlines are still open, we re-verify on or after August 6, 2026" — which is what is
-- actually true. Pending a canvass is not the same as neglected.
--
-- Follow-up: .planning/todos/2026-08-06-az02-libertarian-canvass.md
-- Idempotent: the UPDATE is guarded on the old date.

BEGIN;

UPDATE essentials.race_candidates rc
   SET provisional_until = DATE '2026-08-06',
       last_verified_at  = now(),
       source = rc.source
         || ' | re-verified 2026-07-26: ran in the 2026-07-21 AZ Libertarian primary for CD2 vs'
         || ' Alex Flores (write-in); outcome NOT called, AZ-02 general still lists only Crane and'
         || ' Nez (Ballotpedia). Re-dated to the AZ official statewide canvass 2026-08-06'
         || ' (azsos.gov calendar); primary challenges close 2026-08-11.',
       updated_at = now()
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
 WHERE rc.race_id = r.id
   AND rc.full_name = 'Curtis Goodwin'
   AND r.position_name = 'U.S. Representative District 2'
   AND e.election_date = DATE '2026-11-03'
   AND rc.provisional_until = DATE '2026-07-22';

DO $$
DECLARE
  v_named int; v_row int; v_stale int; v_unmarked int;
BEGIN
  -- 1457's precondition: never key on a name without confirming it is unique table-wide
  SELECT count(*) INTO v_named FROM essentials.race_candidates WHERE full_name = 'Curtis Goodwin';
  IF v_named <> 1 THEN
    RAISE EXCEPTION '1476 gate: expected exactly 1 "Curtis Goodwin" row table-wide, found %', v_named;
  END IF;

  SELECT count(*) INTO v_row
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE rc.full_name = 'Curtis Goodwin'
     AND r.position_name = 'U.S. Representative District 2'
     AND rc.provisional_until = DATE '2026-08-06'
     AND rc.last_verified_at IS NOT NULL
     AND rc.last_verified_at::date < rc.provisional_until;
  IF v_row <> 1 THEN
    RAISE EXCEPTION '1476 gate: Goodwin row not in the expected state (got % matching)', v_row;
  END IF;

  -- the flag must still be live: out of the stale view now, back on its own on 2026-08-06
  SELECT count(*) INTO v_stale FROM essentials.stale_provisional_candidates
   WHERE full_name = 'Curtis Goodwin';
  IF v_stale <> 0 THEN
    RAISE EXCEPTION '1476 gate: Goodwin still stale — re-dating did not take';
  END IF;

  -- 1456 invariant B must survive the source append
  SELECT count(*) INTO v_unmarked FROM essentials.race_candidates
   WHERE provisional_until IS NOT NULL
     AND source !~* 'provisional|pre-primary|cull|filing deadline';
  IF v_unmarked <> 0 THEN
    RAISE EXCEPTION '1476 gate: % dated row(s) lack a provisional marker (breaks 1456)', v_unmarked;
  END IF;

  RAISE NOTICE '1476 PASSED: Goodwin re-dated 2026-07-22 -> 2026-08-06, flag live, 1456 intact.';
END $$;

COMMIT;

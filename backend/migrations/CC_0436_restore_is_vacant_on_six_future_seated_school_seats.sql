-- CC_0436 — six school seats CC_0434 unflagged are still empty today, and the flag was right.
--
-- 🔴 THIS CORRECTS CC_0434, APPLIED HOURS EARLIER THE SAME DAY. That file seated 85 LA County
-- school board members appointed in lieu of election, with terms starting **2026-12-11** so the
-- view would flip by itself on the day. It ended with a blanket
--
--     UPDATE essentials.offices SET is_vacant = false, vacant_since = NULL
--      WHERE id IN (<the 85>) AND is_vacant;
--
-- because `seat_officeholder` does not clear the flag and a seat left held-AND-flagged emits a
-- spurious all-NULL office row. That reasoning is right for the 79 seats that have a sitting
-- predecessor. **It is wrong for the 6 that do not**, and those 6 are exactly the rows the
-- statement touched (`stmt6:UPDATE=6`).
--
-- ⚠ THE WHOLE POINT OF CC_0434 IS THAT THE TERMS ARE IN THE FUTURE. A seat whose only
-- `office_terms` row starts on 2026-12-11 has **no holder today**. Clearing its vacancy flag
-- therefore asserted, for 26 days, that a seat is neither vacant nor held — which is the one
-- state the read path has no way to describe.
--
-- 🔴 AND THE GATE SAID SO WITHIN MINUTES. `check:reachability` reported a NEW bucket,
-- **`DEAD_GEOGRAPHY ca|SCHOOL observed 6`** (18 → 24 overall), which is precisely the failure
-- `backend/migrations/CLAUDE.md` describes: that check flags a district with
-- `active_holders = 0 AND vacant_offices = 0`, so **the flag is the only thing keeping an
-- unseated office out of it**. The note warns against clearing the flag to hide an office from
-- address search; this did the same damage from the opposite motive — clearing it as routine
-- hygiene on a set that happened to include six unseated seats.
--
-- ▶ THE LESSON IS ABOUT THE SHAPE OF THE STATEMENT, NOT THE SIX ROWS. A blanket write over "the
-- offices this migration touched" is a predicate on the migration's scope, not on the thing the
-- column means. `is_vacant` means "nobody holds this seat", and whether that is true after a
-- seating depends on whether the seating has HAPPENED YET. Future-dated seating breaks the
-- assumption the one-liner was built on.
--
-- ── WHAT THESE SIX ARE ──────────────────────────────────────────────────────────────────────
-- All six are the documented `CC_0299` class — a seat awaiting its FIRST election in a staggered
-- California Voting Rights Act by-district conversion — and each still carries its voter-facing
-- description saying so:
--
--   Acton-Agua Dulce Unified   Trustee Area 1, Trustee Area 2
--   Montebello Unified         Trustee Area 1, Trustee Area 3
--   Paramount Unified          Trustee Area 1, Trustee Area 5
--
--   "No one holds this seat yet. It is filled at the election on 3 November 2026, and the winner
--    takes office in December 2026. Until then this area is represented by the N at-large members
--    of the … board, who are listed alongside it."
--
-- That sentence is still true, and it is the reason the flag belongs on the row.
--
-- 🔴 OVERWRITTEN VALUES, AND ONE THAT CC_0434 DID NOT RECORD. This file restores
-- `is_vacant = true`. It also restores `vacant_since = NULL` — and **CC_0434 overwrote the
-- previous `vacant_since` without writing it down**, which is the rule in CLAUDE.md that it
-- broke. NULL is restored rather than guessed, on the evidence that these six belong to the
-- undated-flag class the occupancy notes describe (21 of the 40 undated flags are Los Angeles
-- County school boards, and an "awaiting its first election" seat has no vacancy start date to
-- hold: nobody ever left it). ⚠ If a date is ever found for one of these, it is new information,
-- not a restoration.
--
-- ── WHAT THIS FILE DOES NOT TOUCH ───────────────────────────────────────────────────────────
-- The 79 seats with a sitting predecessor keep `is_vacant = false`. They are held today, by the
-- outgoing member, exactly as intended.
--
-- ▶ 🔴 DATED FOLLOW-UP, 2026-12-11. On that day these six terms begin and the flag must be
-- cleared, in the same act that deletes the `CC_0299` descriptions — which name a past election
-- and go false the moment a winner is seated. Nothing clears a stored flag on a date; the
-- occupancy model is deliberately computed, but THIS column is not.
--
-- @incumbency-decision: no-effect — this writes no `essentials.office_terms` row and touches no
-- race. It sets two columns on six `essentials.offices` rows, so no cached
-- `race_candidates.is_incumbent` answer can move.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0436_restore_is_vacant_on_six_future_seated_school_seats.sql

BEGIN;

CREATE TEMP TABLE cc0436_seats ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('8988a457-e7f9-438e-9d4c-a2011f2e3e6d'::uuid, 'Acton-Agua Dulce Unified — Trustee Area 1'),
  ('ed2b10e2-5e04-4425-b870-87845fedde47'::uuid, 'Acton-Agua Dulce Unified — Trustee Area 2'),
  ('67ede8d7-0cd4-4e90-840d-043e27d57125'::uuid, 'Montebello Unified — Trustee Area 1'),
  ('f7e0f453-6f79-4784-a6de-bb82275775f3'::uuid, 'Montebello Unified — Trustee Area 3'),
  ('0ec66343-9444-4474-8be2-9343f776304c'::uuid, 'Paramount Unified — Trustee Area 1'),
  ('8f3861f4-0a11-4ae9-b4cc-9c66ae515316'::uuid, 'Paramount Unified — Trustee Area 5')
) AS t(office_id, label);

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0436_seats;
  IF v_n <> 6 THEN RAISE EXCEPTION 'CC_0436: expected 6 seats, found %.', v_n; END IF;

  -- 🔴 THE CLAIM IS "EMPTY TODAY", SO ASSERT IT RATHER THAN THE FLAG. If one of these is in fact
  -- held right now, flagging it vacant would publish a vacancy that does not exist — the exact
  -- mirror of the error being corrected.
  SELECT count(*) INTO v_bad
    FROM cc0436_seats s
    JOIN essentials.office_current_holder och ON och.office_id = s.office_id
   WHERE och.politician_id IS NOT NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0436: % of these seats IS held today. Do not flag a held seat vacant.', v_bad;
  END IF;

  -- Each must carry exactly the one future term CC_0434 wrote, and nothing earlier. An earlier
  -- term would mean somebody did once hold the seat and the vacancy has a real start date.
  SELECT count(*) INTO v_bad
    FROM cc0436_seats s
   WHERE (SELECT count(*) FROM essentials.office_terms t WHERE t.office_id = s.office_id) <> 1
      OR (SELECT min(t.term_start) FROM essentials.office_terms t WHERE t.office_id = s.office_id)
         IS DISTINCT FROM DATE '2026-12-11';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0436: % seat(s) do not carry exactly one term starting 2026-12-11.', v_bad;
  END IF;

  -- And each must currently be unflagged — otherwise CC_0434 is not what this file is correcting.
  SELECT count(*) INTO v_bad
    FROM cc0436_seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0436: % seat(s) are already flagged vacant; nothing to restore.', v_bad;
  END IF;
END $$;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET is_vacant = true, vacant_since = NULL
  FROM cc0436_seats s
 WHERE o.id = s.office_id
   AND NOT o.is_vacant;

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_flagged int; v_held int; v_79 int;
BEGIN
  SELECT count(*) INTO v_flagged
    FROM cc0436_seats s JOIN essentials.offices o ON o.id = s.office_id
   WHERE o.is_vacant AND o.vacant_since IS NULL;
  IF v_flagged <> 6 THEN
    RAISE EXCEPTION 'CC_0436: expected 6 seats flagged vacant with no date; found %.', v_flagged;
  END IF;

  -- Still nobody in them, and still due on 2026-12-11.
  SELECT count(*) INTO v_held
    FROM cc0436_seats s JOIN essentials.office_current_holder och ON och.office_id = s.office_id
   WHERE och.politician_id IS NOT NULL;
  IF v_held <> 0 THEN
    RAISE EXCEPTION 'CC_0436: % seat(s) resolved a holder after the write.', v_held;
  END IF;

  -- 🔴 THE 79 MUST NOT HAVE MOVED. This file corrects six rows, not CC_0434's whole scope: those
  -- 79 are held today by their outgoing member and flagging them would blank a sitting official.
  SELECT count(*) INTO v_79
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
   WHERE t.term_start = DATE '2026-12-11'
     AND o.is_vacant
     AND o.id NOT IN (SELECT office_id FROM cc0436_seats);
  IF v_79 <> 0 THEN
    RAISE EXCEPTION 'CC_0436: % of CC_0434''s other seats are now flagged vacant.', v_79;
  END IF;
  RAISE NOTICE 'CC_0436: 6 seats re-flagged; CC_0434''s other 79 untouched.';
END $$;

COMMIT;

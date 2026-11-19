-- CC_0455 — 2027-01-03: clear is_vacant on TX-23 and FL-20
--
-- 🔴🔴 DO NOT APPLY THIS BEFORE 2027-01-03. Assertion P1 refuses to let you.
--
-- WHAT THIS IS. CC_0453 seated 427 House winners at 2027-01-03. 425 of them closed a
-- predecessor's term at 2027-01-02, because `seat_officeholder` closes the sitting term as a side
-- effect. TWO closed nothing, and that is the signature of a seat that was already empty:
--
--     TX-23  Katy Padilla Stout        office b746cfac-5e06-413e-abde-898c4e4b8a2d
--     FL-20  Debbie Wasserman Schultz  office 5dd1387d-f8c9-4583-aaa3-09ab2ed538ba
--
-- Both offices carry `is_vacant = true` from a real, dated mid-term vacancy in April 2026.
-- 🔴 `seat_officeholder` NEVER CLEARS THAT FLAG — it writes `essentials.office_terms` and does not
-- touch `essentials.offices` at all. So from 2027-01-03 each seat reads HELD AND VACANT, which is
-- the `is_vacant` trap: a filter applied after the match emits a spurious all-NULL office row
-- beside the member who has just taken the seat. This file closes that, and nothing else.
--
-- 🔴🔴 THE VALUES THIS FILE OVERWRITES, RECORDED HERE BECAUSE NOTHING ELSE WILL KEEP THEM.
-- There is no history table for `essentials.offices` and no `schema_migrations` to replay from, so
-- the moment this commits the previous values exist nowhere. Measured against production
-- 2026-11-18:
--
--     office                                  is_vacant   vacant_since
--     b746cfac-… (TX-23)                      true        2026-04-14
--     5dd1387d-… (FL-20)                      true        2026-04-21
--
--   ▶ To undo this file: set both back to `is_vacant = true` with those two dates.
--
-- 🔴 WHY THIS IS A DATED MIGRATION AND NOT A TRIGGER. `is_vacant` is a CACHED BOOLEAN. Nothing
-- fires merely because the calendar advanced — that is the whole reason the temporal model exists.
-- The TERMS flip by themselves on 2027-01-03 (CC_0453 wrote them in advance at day precision, the
-- Reno pattern); this flag cannot. Somebody has to run this on the day.
--
-- 🔴🔴 WHY IT MUST NOT RUN EARLY, STATED AS THE FAILURE IT CAUSES. Each of these two districts
-- holds EXACTLY ONE office — the House seat itself. Clear the flag while the seat is still empty
-- and the district reads `offices > 0 AND active_holders = 0 AND vacant_offices = 0`, which is
-- verbatim the DEAD_GEOGRAPHY classifier in `backend/scripts/check-address-reachability.mjs`.
-- `backend/data/address-reachability-baseline.json` carries NO `NATIONAL_LOWER` bucket at all, so
-- that would be TWO NEW BUCKETS, and the gate fires on any new bucket. It is a MASTER-ONLY gate,
-- so it would not fail this PR — it would fail the NEXT one and name an innocent author.
--   ▶ And the honest fix would then be blocked: never raise a baseline to clear a red.
--   ▶ Assertion V3 carries that same check INTO this file, as the delta it creates. A master-only
--     gate cannot vet the merge that trips it.
--
-- @incumbency-decision: no-effect — writes only `essentials.offices.is_vacant` / `vacant_since`.
-- Creates no office, seats nobody, and touches no `office_terms` row (V4 asserts that).
--
-- Idempotent: the UPDATE is guarded on `is_vacant = true`, and the post-verify asserts the END
-- STATE, not the row count of the write. Running it twice is a no-op.

BEGIN;

CREATE TEMP TABLE cc0455_seats (
  office_id          uuid PRIMARY KEY,
  seat               text NOT NULL,
  expect_state       text NOT NULL,
  expect_position    text NOT NULL,
  expect_incoming    text NOT NULL,
  was_vacant_since   date NOT NULL      -- the value being destroyed; P6 asserts it still matches
) ON COMMIT DROP;

INSERT INTO cc0455_seats (office_id, seat, expect_state, expect_position, expect_incoming, was_vacant_since)
VALUES
  ('b746cfac-5e06-413e-abde-898c4e4b8a2d'::uuid, 'TX-23', 'TX',
   'U.S. Representative District 23', 'Katy Padilla Stout',       DATE '2026-04-14'),
  ('5dd1387d-f8c9-4583-aaa3-09ab2ed538ba'::uuid, 'FL-20', 'FL',
   'U.S. Representative District 20', 'Debbie Wasserman Schultz', DATE '2026-04-21');

-- ─── Pre-flight ───────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n bigint;
  bad text;
BEGIN
  -- P1 🔴🔴 THE DATE GATE. The seats are empty until the 20th Amendment seats their winners.
  -- Clearing the flag before then asserts to a voter that a seat is filled when it is not, AND
  -- creates the DEAD_GEOGRAPHY buckets described in the header.
  IF CURRENT_DATE < DATE '2027-01-03' THEN
    RAISE EXCEPTION
      'P1: today is %, and these seats are not filled until 2027-01-03. Clearing is_vacant now '
      'would leave each district with 1 office, 0 active holders and 0 vacant offices — the '
      'DEAD_GEOGRAPHY condition — and would tell voters in TX-23 and FL-20 that their seat is '
      'held while it is empty. Wait for the date; do not relax this gate.', CURRENT_DATE;
  END IF;

  -- P2 the two pinned offices exist, exactly two of them
  SELECT count(*) INTO n
    FROM cc0455_seats c JOIN essentials.offices o ON o.id = c.office_id;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P2: expected both pinned offices to exist, found %', n;
  END IF;

  -- P3 each pin still NAMES the seat it is supposed to be. A uuid is not an identity; a pin that
  -- has drifted onto another office would clear a flag on a seat nobody looked at.
  SELECT string_agg(format('%s: state=%s position=%s', c.seat, d.state,
                           coalesce(r.position_name, '(no 2026-11-03 race)')), ' | ')
    INTO bad
    FROM cc0455_seats c
    JOIN essentials.offices o   ON o.id = c.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.races r ON r.office_id = o.id
         AND r.election_id IN (SELECT id FROM essentials.elections WHERE election_date = DATE '2026-11-03')
   WHERE d.state <> c.expect_state
      OR d.district_type <> 'NATIONAL_LOWER'
      OR coalesce(r.position_name, '') <> c.expect_position;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'P3: a pinned office no longer names its expected seat — %', bad;
  END IF;

  -- P4 🔴 THE SAFETY GATE: SOMEBODY MUST ACTUALLY HOLD THE SEAT TODAY. This is the check that
  -- makes clearing the flag honest, and it is deliberately NOT "a term row exists" — it is date
  -- containment, which is what `office_current_holder` asks. An open-ended term is not "current".
  SELECT string_agg(c.seat || ' (' || c.expect_incoming || ')', ', ') INTO bad
    FROM cc0455_seats c
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = c.office_id
        AND t.politician_id IS NOT NULL
        AND t.term_start <= CURRENT_DATE
        AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE));
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION
      'P4: no current officeholder resolves for %. Do NOT clear is_vacant on an unseated office — '
      'unseated and unflagged is invisible to address search and is the DEAD_GEOGRAPHY bucket. '
      'Fix the seating first.', bad;
  END IF;

  -- P5 the incoming holder is the person CC_0453 seated, by name. Guards against this file being
  -- run after somebody else has moved the seat under it.
  SELECT string_agg(format('%s: expected %s, holds %s', c.seat, c.expect_incoming, p.full_name), ' | ')
    INTO bad
    FROM cc0455_seats c
    JOIN essentials.office_terms t ON t.office_id = c.office_id
         AND t.term_start <= CURRENT_DATE
         AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE)
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.full_name <> c.expect_incoming;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'P5: the seat is held by somebody other than the recorded winner — %', bad;
  END IF;

  -- P6 🔴 THE VALUE THIS FILE DESTROYS IS STILL THE VALUE THE HEADER RECORDS. If somebody has
  -- re-dated these vacancies since 2026-11-18, the header's undo instructions are wrong and this
  -- file must not silently overwrite a value nobody wrote down.
  SELECT string_agg(format('%s: header says %s, row says %s', c.seat, c.was_vacant_since,
                           coalesce(o.vacant_since::date::text, 'NULL')), ' | ')
    INTO bad
    FROM cc0455_seats c
    JOIN essentials.offices o ON o.id = c.office_id
   WHERE o.is_vacant = true
     AND coalesce(o.vacant_since::date, DATE '0001-01-01') <> c.was_vacant_since;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION
      'P6: vacant_since has changed since this file was written — %. Re-read it and update the '
      'header''s undo note before applying.', bad;
  END IF;

  RAISE NOTICE 'CC_0455 pre-flight OK: 2 offices, both held today, both still flagged as written.';
END $$;

-- ─── Capture the baseline this migration is gated on ──────────────────────────────────────────
CREATE TEMP TABLE cc0455_before AS
SELECT (SELECT count(*) FROM essentials.offices WHERE is_vacant)             AS vacant_offices_repo_wide,
       (SELECT count(*) FROM essentials.office_terms)                        AS office_terms_rows;

-- ─── The write ────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.offices o
   SET is_vacant = false,
       vacant_since = NULL
  FROM cc0455_seats c
 WHERE o.id = c.office_id
   AND o.is_vacant = true;

-- ─── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n bigint;
  bad text;
  b   record;
BEGIN
  SELECT * INTO b FROM cc0455_before;

  -- V1 the end state, asserted directly rather than from the UPDATE's row count (idempotency)
  SELECT count(*) INTO n
    FROM cc0455_seats c JOIN essentials.offices o ON o.id = c.office_id
   WHERE o.is_vacant = false AND o.vacant_since IS NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION 'V1: expected 2 offices unflagged with a NULL vacant_since, got %', n;
  END IF;

  -- V2 🔴 NOTHING OUTSIDE THE TWO PINS MOVED. The repo-wide vacant count must fall by EXACTLY 2.
  -- Gated on the DELTA captured in this transaction, never on a total somebody else can move
  -- while this file sits unapplied for six weeks.
  SELECT count(*) INTO n FROM essentials.offices WHERE is_vacant;
  IF n <> b.vacant_offices_repo_wide - 2 THEN
    RAISE EXCEPTION 'V2: repo-wide vacant offices went % -> %, expected a fall of exactly 2',
      b.vacant_offices_repo_wide, n;
  END IF;

  -- V3 🔴🔴 THE REACHABILITY CHECK, CARRIED INTO THIS FILE AS A DELTA. This is the master-only
  -- DEAD_GEOGRAPHY classifier applied to exactly the two districts this file touches:
  --   offices > 0 AND active_holders = 0 AND vacant_offices = 0
  -- If this file ever runs early, V3 is what catches it after P1.
  SELECT string_agg(c.seat || ' (district ' || d.id::text || ')', ', ') INTO bad
    FROM cc0455_seats c
    JOIN essentials.offices o   ON o.id = c.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (SELECT count(*) FROM essentials.offices o2
            JOIN essentials.office_current_holder och ON och.office_id = o2.id
           WHERE o2.district_id = d.id AND och.politician_id IS NOT NULL) = 0
     AND (SELECT count(*) FROM essentials.offices o2
           WHERE o2.district_id = d.id AND o2.is_vacant) = 0;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION
      'V3: % now has offices, no active holder and no vacant flag — that is DEAD_GEOGRAPHY, and '
      'check-address-reachability.mjs would fail the NEXT person''s PR with it.', bad;
  END IF;

  -- V4 this file seats nobody and unseats nobody
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.office_terms_rows THEN
    RAISE EXCEPTION 'V4: office_terms went % -> %; this file must not touch a single term row',
      b.office_terms_rows, n;
  END IF;

  -- V5 🔴 HELD AND VACANT IS ZERO REPO-WIDE, which is the condition the read path relies on
  -- (`seat_status` is derived from whether a holder resolved, never from `is_vacant`, precisely
  -- so that the two can be compared). This file should shrink that set, never grow it.
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant = true AND och.politician_id IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'V5: % office(s) repo-wide now read HELD AND VACANT', n;
  END IF;

  RAISE NOTICE 'CC_0455 OK: TX-23 and FL-20 unflagged; vacant offices % -> %; 0 held-and-vacant; '
               '0 office_terms rows touched.', b.vacant_offices_repo_wide, b.vacant_offices_repo_wide - 2;
END $$;

COMMIT;

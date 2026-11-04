-- CC_0344 — essentials.office_swearing_in: when a winner actually takes office, with a citation.
--
-- Piece 4 of the post-election transition programme.
-- Design: docs/superpowers/specs/2026-11-04-post-election-transition-tracker-design.md
--
-- WHY THIS TABLE EXISTS. `seat_officeholder` takes a `term_start` and the temporal model does the
-- rest: a future-dated term starts resolving as current on its own date, with no trigger and no
-- deploy. That makes the DATE the whole decision, and there is nowhere in the schema to put one
-- before it is used. 2,159 races need one, and nothing today can answer "when does this seat
-- change hands?" for any of them.
--
-- 🔴 THE DATES WE ALREADY HELD ARE NOT DATES, AND THE WAVE ORDER WAS DRAWN FROM THEM.
-- Wave 3 was scoped by reading the MONTH of each office's existing `office_terms.term_start`.
-- Measured 2026-11-04: 118 of ~140 dated California SCHOOL terms read `2022-12-01`, and every one
-- carries `start_precision = 'month'`. 1 December is this repo's honest encoding of "December,
-- day unknown" — so the design doc's "the earliest on 1 December, 27 days from this document"
-- read a PRECISION ARTIFACT as a deadline. Reading the month was right. Reading the day was
-- reading a value the column never claimed to hold.
--
-- 🔴 THE MONTH IS CONTAMINATED TOO. 22 offices across 16 states carry NOVEMBER historical term
-- starts, almost all NATIONAL_LOWER/NATIONAL_UPPER. Federal terms begin 3 January by statute, so
-- those rows are SPECIAL-ELECTION seatings — a mid-term vacancy fill, not a convention. A
-- historical start month is a search tool for finding seats to check. It is not evidence of when
-- the next term begins, and this table exists so that nothing has to pretend otherwise.
--
-- WHAT A ROW ASSERTS. One row per (office, election): the date the winner of THAT election takes
-- THAT seat, the authority it came from, and how strong that authority is.
--
-- 🔴 `basis` IS LOAD-BEARING AND THE SEEDING SCRIPT MUST READ IT.
--   'statute'   computed from a cited statute. Seatable.
--   'published' the body itself published the date. Seatable.
--   'estimated' inferred from convention or a neighbouring body. NOT SEATABLE — it is a to-do
--               marker that says "a date is owed here", and writing a term from one would create
--               exactly the unsourced row the repo's sourcing rules forbid.
-- The CHECK cannot enforce "do not seat from estimated" — only the caller can — so the column is
-- NOT NULL and has no default, which makes an author state the strength of what they wrote.
--
-- 🔴 `window_end_date` EXISTS BECAUSE SOME AUTHORITIES FIX A WINDOW, NOT A DAY, AND FLATTENING
-- ONE INTO A POINT IS A LIE THE SCHEMA WOULD OTHERWISE HELP TELL. California school and
-- community college boards are the worked example and they take BOTH columns:
--   Cal. Educ. Code § 5017   the term COMMENCES on the second Friday in December (2026-12-11).
--   Cal. Educ. Code § 35143  the organizational meeting at which the oath is administered falls
--                            on a day within the 15-day period beginning that Friday — so the
--                            successor qualifies somewhere in 2026-12-11 .. 2026-12-25, and
--                            § 5017's second sentence keeps the predecessor discharging the
--                            duties of the office until they do.
-- Our own day-precision rows record the OATH, not the commencement: Glendora 2022-12-12, Azusa
-- and Duarte 2022-12-13, others on the 14th and 15th, each sourced to that district's
-- organizational-meeting minutes — while the second Friday of December 2022 was the 9th. Two
-- different events, a week apart, and the column recorded whichever one the source described.
-- `swearing_in_date` is the commencement; `window_end_date` is the last day the handover can
-- legally happen. A NULL window means the authority fixes an exact day.
--
-- NOTHING IS SEEDED HERE. This migration creates the table and nothing else, so that the create
-- and the 227 California rows can be reviewed, dry-run and reverted independently.
--
-- No value is overwritten and no row is deleted: the table does not exist before this file.

CREATE TABLE IF NOT EXISTS essentials.office_swearing_in (
  office_id         uuid        NOT NULL REFERENCES essentials.offices (id) ON DELETE CASCADE,
  election_date     date        NOT NULL,
  swearing_in_date  date        NOT NULL,
  window_end_date   date,
  basis             text        NOT NULL,
  rule_id           text,
  authority         text        NOT NULL,
  source            text        NOT NULL,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT office_swearing_in_pkey PRIMARY KEY (office_id, election_date),
  CONSTRAINT office_swearing_in_basis_check
    CHECK (basis IN ('statute', 'published', 'estimated')),
  -- A handover cannot precede the election that caused it. This catches a year typo, which is
  -- the mistake that would otherwise seat a winner into the past and resolve as current TODAY.
  CONSTRAINT office_swearing_in_after_election
    CHECK (swearing_in_date > election_date),
  CONSTRAINT office_swearing_in_window_order
    CHECK (window_end_date IS NULL OR window_end_date >= swearing_in_date),
  -- An empty citation is the same as no citation, and ''::text passes NOT NULL.
  CONSTRAINT office_swearing_in_cited
    CHECK (btrim(authority) <> '' AND btrim(source) <> '')
);

COMMENT ON TABLE essentials.office_swearing_in IS
  'When the winner of a given election takes a given seat, with the authority it came from. '
  'Piece 4 of the post-election transition programme. basis=''estimated'' rows are NOT seatable: '
  'they record that a date is owed, not what it is. window_end_date is set where the authority '
  'fixes a window rather than a day (e.g. Cal. Educ. Code 35143''s 15-day organizational-meeting '
  'period) and NULL where it fixes an exact day.';

COMMENT ON COLUMN essentials.office_swearing_in.swearing_in_date IS
  'The date the term commences under the cited authority. This is what seat_officeholder is '
  'given as term_start.';
COMMENT ON COLUMN essentials.office_swearing_in.window_end_date IS
  'The last day the handover can legally occur, where the authority fixes a window. NULL when '
  'the authority fixes an exact day. NEVER a guess at the far end of an unknown range.';
COMMENT ON COLUMN essentials.office_swearing_in.basis IS
  'statute | published | estimated. Only statute and published may seat a term.';
COMMENT ON COLUMN essentials.office_swearing_in.rule_id IS
  'The rule in backend/scripts/lib/ca-swearing-in.mjs (or a later per-state equivalent) that '
  'produced this row, so a corrected rule can find every row it wrote. NULL for a hand-sourced '
  'row.';

CREATE INDEX IF NOT EXISTS office_swearing_in_election_date_idx
  ON essentials.office_swearing_in (election_date);

-- Finds every seat still owed a real date, which is the tracker's "blocked on a date" bucket.
CREATE INDEX IF NOT EXISTS office_swearing_in_basis_idx
  ON essentials.office_swearing_in (basis)
  WHERE basis = 'estimated';

ALTER TABLE essentials.office_swearing_in ENABLE ROW LEVEL SECURITY;

-- Explicit, minimal grants. The essentials frontend never reads essentials.* directly; it goes
-- through this API as ev_api, which only ever reads this table. Writes arrive by migration.
GRANT SELECT ON essentials.office_swearing_in TO ev_api;
GRANT ALL    ON essentials.office_swearing_in TO service_role;

DROP POLICY IF EXISTS office_swearing_in_read ON essentials.office_swearing_in;
CREATE POLICY office_swearing_in_read
  ON essentials.office_swearing_in
  FOR SELECT TO ev_api
  USING (true);

DROP POLICY IF EXISTS office_swearing_in_service ON essentials.office_swearing_in;
CREATE POLICY office_swearing_in_service
  ON essentials.office_swearing_in
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- Post-verify. Gates the SHAPE this migration creates, not a total another session can move.
DO $$
DECLARE
  v_cols      int;
  v_checks    int;
  v_rls       boolean;
  v_policies  int;
  v_rows      bigint;
BEGIN
  SELECT count(*) INTO v_cols
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'office_swearing_in';
  IF v_cols <> 11 THEN
    RAISE EXCEPTION 'CC_0344: expected 11 columns, found %', v_cols;
  END IF;

  SELECT count(*) INTO v_checks
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'office_swearing_in' AND c.contype = 'c';
  IF v_checks < 4 THEN
    RAISE EXCEPTION 'CC_0344: expected at least 4 CHECK constraints, found %', v_checks;
  END IF;

  SELECT relrowsecurity INTO v_rls
    FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'office_swearing_in';
  IF NOT v_rls THEN
    RAISE EXCEPTION 'CC_0344: row level security is not enabled';
  END IF;

  SELECT count(*) INTO v_policies
    FROM pg_policies
   WHERE schemaname = 'essentials' AND tablename = 'office_swearing_in';
  IF v_policies <> 2 THEN
    RAISE EXCEPTION 'CC_0344: expected 2 policies, found %', v_policies;
  END IF;

  IF NOT has_table_privilege('ev_api', 'essentials.office_swearing_in', 'SELECT') THEN
    RAISE EXCEPTION 'CC_0344: ev_api cannot SELECT the table it has to read';
  END IF;

  -- 🔴 A UNIFORM ANSWER IS A BROKEN DETECTOR UNTIL A CONTROL PASSES. Prove the two constraints
  -- that stop a bad date reaching production actually fire, here, in this transaction, rather
  -- than trusting that a CHECK written above is a CHECK that works.
  BEGIN
    INSERT INTO essentials.office_swearing_in
      (office_id, election_date, swearing_in_date, basis, authority, source)
    SELECT id, DATE '2026-11-03', DATE '2026-01-04', 'statute', 'control', 'control'
      FROM essentials.offices LIMIT 1;
    RAISE EXCEPTION 'CC_0344: a swearing-in date BEFORE its election was accepted';
  EXCEPTION
    WHEN check_violation THEN NULL;
  END;

  BEGIN
    INSERT INTO essentials.office_swearing_in
      (office_id, election_date, swearing_in_date, basis, authority, source)
    SELECT id, DATE '2026-11-03', DATE '2026-12-11', 'guessed', 'control', 'control'
      FROM essentials.offices LIMIT 1;
    RAISE EXCEPTION 'CC_0344: an unknown basis was accepted';
  EXCEPTION
    WHEN check_violation THEN NULL;
  END;

  SELECT count(*) INTO v_rows FROM essentials.office_swearing_in;
  IF v_rows <> 0 THEN
    RAISE EXCEPTION 'CC_0344: creates the table and seeds nothing, but found % row(s)', v_rows;
  END IF;

  RAISE NOTICE 'CC_0344 OK: table created, % columns, % checks, RLS on, % policies, 0 rows',
    v_cols, v_checks, v_policies;
END $$;

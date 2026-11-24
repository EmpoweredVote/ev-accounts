-- CC_0472 — `essentials.office_swearing_in`: a term CAN begin on election day. Widen the check
-- that said it could not.
--
-- 🔴🔴 APPLY ORDER: THIS FILE RUNS **BEFORE** CC_0469, DESPITE CARRYING A LATER SLOT NUMBER.
--    CC_0469 writes three Hawaii rows whose `swearing_in_date` EQUALS their `election_date`, and
--    the constraint below rejects them until this file has run. CC_0469's own P0 refuses to
--    start unless it finds the widened definition, so the order is enforced by the data rather
--    than by this comment. The number is later because the need was only discovered when
--    CC_0469 was rehearsed against production and aborted.
--
-- 🔴 THIS FILE IS DDL AND `ev_api` CANNOT RUN IT. `scripts/apply-migration-file.mjs` and
--    `scripts/rehearse-migration-chain.mjs` both connect as `ev_api`, which is not the owner of
--    this table — they fail with "must be owner of table office_swearing_in". Apply it as the
--    owner (the Supabase MCP), and rehearse it the same way inside `BEGIN; … ROLLBACK;`. That is
--    the existing route for DDL in this repo; it is written here because the failure is
--    otherwise read as a broken file.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT WAS WRONG WITH IT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
--   BEFORE: CHECK (swearing_in_date >  election_date)
--   AFTER:  CHECK (swearing_in_date >= election_date)
--
-- The old definition is written out here because nothing else records it: dropping a constraint
-- destroys its text, and `CLAUDE.md` requires a migration that overwrites a value to record the
-- value it overwrote.
--
-- 🔴 IT WAS AN ASSUMPTION THAT HAD NEVER BEEN CONTRADICTED, WHICH IS NOT THE SAME AS A RULE.
--    Twenty states have been dated in the 2026 state seating pass and every one of them starts
--    its terms in December 2026 or January 2027, so a strict `>` held for 1,086 offices and read
--    as a sound invariant. Hawaii is the counter-example, and it is in statute, not in an edge
--    case:
--
--      HRS § 13D-5 — "The term of office of members of the board shall be four years BEGINNING
--      ON THE DAY OF THE GENERAL ELECTION AT WHICH THEY ARE ELECTED … and ending on the day of
--      the second general election after their election."
--
--    The Office of Hawaiian Affairs trustees elected on 2026-11-03 began their terms on
--    2026-11-03. The constraint forbade recording a date the statute states in words.
--
-- ⚠ THE ONLY ALTERNATIVE WAS TO CARRY THAT DATE AS A LITERAL IN THE SEATING MIGRATION, which is
--   the one thing the pass refuses: a date written into a seating file agrees with itself
--   however wrong it is. The whole point of `office_swearing_in` is that the seating file READS
--   a sourced date rather than asserting one.
--
-- ⚠ WHY THE CHECK IS WIDENED AND NOT DROPPED. It still catches the fault it was written for — a
--   term that begins BEFORE its own election, which is a data error in every jurisdiction. Only
--   the boundary moves.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS CHANGES FOR EXISTING ROWS: NOTHING, AND THAT IS MEASURED
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- A widening cannot invalidate a row that already satisfied the stricter rule, so no existing
-- row is touched and `ALTER TABLE … ADD CONSTRAINT` revalidates all of them on the way in. What
-- a widening CAN do is quietly stop catching something, so the replacement is given a positive
-- control: a deliberately backwards row is offered to it and this file refuses unless the
-- constraint rejects it.
--
-- 🔴 THE CONTROL WAS WATCHED FAILING FIRST, which is what makes it a control rather than
--    ceremony. Rehearsed against the ORIGINAL `>` constraint on 2026-11-23, CC_0469's three OHA
--    rows aborted with "new row for relation office_swearing_in violates check constraint
--    office_swearing_in_after_election" — that abort is how this file came to exist.

BEGIN;

DO $$
DECLARE d text; n bigint;
BEGIN
  SELECT pg_get_constraintdef(con.oid) INTO d
    FROM pg_constraint con
    JOIN pg_class c      ON c.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE ns.nspname = 'essentials' AND c.relname = 'office_swearing_in'
     AND con.conname = 'office_swearing_in_after_election';

  -- P1 — the constraint is there and says exactly what this file recorded. If it has already
  -- been widened, say so plainly rather than destroying and rebuilding somebody else's rule.
  IF d IS NULL THEN
    RAISE EXCEPTION 'P1: office_swearing_in_after_election does not exist. Somebody has already '
                    'changed this constraint; read what they did before touching it.';
  END IF;
  IF d = 'CHECK ((swearing_in_date >= election_date))' THEN
    RAISE EXCEPTION 'P1: the constraint is ALREADY widened. Applied before.';
  END IF;
  IF d <> 'CHECK ((swearing_in_date > election_date))' THEN
    RAISE EXCEPTION 'P1: the constraint reads "%", which is neither definition this file knows '
                    'about. It would be destroying a rule it has not written down.', d;
  END IF;

  -- P2 — nothing in the table is currently on the boundary, so this widening admits no row that
  -- is already there. It is a measurement of what the change DOES, not a formality: if rows at
  -- equality existed, the old constraint would not have been enforcing what its text says.
  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE swearing_in_date <= election_date;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % existing row(s) already violate the strict constraint. Read them '
                    'before widening the rule that was supposed to be stopping them.', n;
  END IF;
END $$;

ALTER TABLE essentials.office_swearing_in
  DROP CONSTRAINT office_swearing_in_after_election;

ALTER TABLE essentials.office_swearing_in
  ADD CONSTRAINT office_swearing_in_after_election
  CHECK (swearing_in_date >= election_date);

-- ── The positive control ────────────────────────────────────────────────────────────────────
-- 🔴🔴 A WIDENED CONSTRAINT IS A CONSTRAINT THAT HAS STOPPED CATCHING SOMETHING, AND THE ONLY
--    WAY TO KNOW IT STILL CATCHES THE REST IS TO HAND IT SOMETHING IT MUST REJECT.
--
-- Two rows are offered, in this order, and both must be rejected or accepted exactly as stated:
--   • a term beginning the day BEFORE its own election — must be REJECTED;
--   • a term beginning ON its own election day — must be ACCEPTED, which is the whole purpose.
--
-- ⚠ BOTH USE AN ELECTION DATE NO REAL ROW USES (2099-01-06) AND AN OFFICE PICKED FROM THE TABLE
--   ITSELF, so the primary key cannot collide and turn a `unique_violation` into a false pass —
--   a rejection for the wrong reason reads exactly like a rejection for the right one.
-- ⚠ EACH IS ROLLED BACK BY ITS OWN SUBTRANSACTION OR DELETED, and the final assertion measures
--   that nothing survived rather than assuming it.
DO $$
DECLARE v_office uuid; n bigint;
BEGIN
  SELECT office_id INTO v_office FROM essentials.office_swearing_in
   ORDER BY office_id::text LIMIT 1;
  IF v_office IS NULL THEN
    RAISE EXCEPTION 'control: office_swearing_in is empty, so the control has nothing to key on '
                    'and this file would report a pass having tested nothing.';
  END IF;

  -- 1. BACKWARDS — must be rejected.
  BEGIN
    INSERT INTO essentials.office_swearing_in
      (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
    VALUES (v_office, DATE '2099-01-06', DATE '2099-01-05', 'statute', 'cc0472-control',
            'control row', 'control row', 'control row');
    RAISE EXCEPTION 'CONTROL FAILED: the widened constraint ACCEPTED a swearing-in date before '
                    'its own election. It is no longer constraining anything.';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'CC_0472 control 1 OK: a date BEFORE the election is still rejected.';
  END;

  -- 2. ON THE DAY — must be accepted. This is the row Hawaii needs, proven before CC_0469
  --    depends on it, and then removed.
  BEGIN
    INSERT INTO essentials.office_swearing_in
      (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
    VALUES (v_office, DATE '2099-01-06', DATE '2099-01-06', 'statute', 'cc0472-control',
            'control row', 'control row', 'control row');
    RAISE NOTICE 'CC_0472 control 2 OK: a date ON the election day is now accepted.';
  EXCEPTION
    WHEN check_violation THEN
      RAISE EXCEPTION 'CONTROL FAILED: the widened constraint still rejects a term beginning on '
                      'election day, which is the only reason this file exists.';
  END;

  DELETE FROM essentials.office_swearing_in WHERE rule_id = 'cc0472-control';

  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE rule_id = 'cc0472-control' OR election_date = DATE '2099-01-06';
  IF n <> 0 THEN
    RAISE EXCEPTION 'control: % control row(s) survived. A control must leave nothing behind.', n;
  END IF;
END $$;

-- ── Post-verify ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n bigint; d text;
BEGIN
  SELECT pg_get_constraintdef(con.oid) INTO d
    FROM pg_constraint con
    JOIN pg_class c      ON c.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE ns.nspname = 'essentials' AND c.relname = 'office_swearing_in'
     AND con.conname = 'office_swearing_in_after_election';
  IF d <> 'CHECK ((swearing_in_date >= election_date))' THEN
    RAISE EXCEPTION '1: the constraint reads "%", expected the widened definition.', d;
  END IF;

  -- 2. The other four constraints on this table are untouched. A DROP/ADD on one is the shape of
  --    change that quietly loses a neighbour, and the basis check is the one that enforces
  --    "an estimate may not seat anybody" two files downstream.
  SELECT count(*) INTO n
    FROM pg_constraint con
    JOIN pg_class c      ON c.oid = con.conrelid
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
   WHERE ns.nspname = 'essentials' AND c.relname = 'office_swearing_in'
     AND con.conname IN ('office_swearing_in_basis_check', 'office_swearing_in_cited',
                         'office_swearing_in_window_order', 'office_swearing_in_pkey',
                         'office_swearing_in_office_id_fkey');
  IF n <> 5 THEN
    RAISE EXCEPTION '2: % of the table''s 5 other constraints survive, expected 5.', n;
  END IF;

  -- 3. No row was written, changed or removed by this file.
  SELECT count(*) INTO n FROM essentials.office_swearing_in
   WHERE rule_id = 'cc0472-control';
  IF n <> 0 THEN
    RAISE EXCEPTION '3: % control row(s) remain.', n;
  END IF;

  RAISE NOTICE 'CC_0472 OK: office_swearing_in_after_election widened from > to >=; a date '
               'before the election is still rejected, a date on election day is now accepted; '
               'the table''s other 5 constraints intact; no rows written. ▶ CC_0469 may now run.';
END $$;

COMMIT;

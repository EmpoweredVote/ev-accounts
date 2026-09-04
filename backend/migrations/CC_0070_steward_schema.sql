-- CC_0070_steward_schema.sql
--
-- The steward: coordination for concurrent work in ev-accounts.
--
-- Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md
-- Scanner: backend/scripts/lib/migration-slots.mjs (already merged, tested, no prod contact)
--
-- Creates structure ONLY. It does not seed. See the 🔴 guard in §3 — the allocator refuses to
-- issue a number until the table has been seeded from git history, because an unseeded
-- allocator would confidently return CC_0001.
--
-- ── WHAT THIS IS FOR ────────────────────────────────────────────────────────────────────
--
-- Several workstreams and a growing number of concurrent sessions write into this one repo and
-- one production database. Today they avoid each other by social protocol: Chris Andrews works
-- in other repos, and the second machine stays off. The goal is to remove that constraint.
--
-- Of the four ways concurrent work collides here, TWO cross machines and so cannot be fixed by
-- any local convention:
--
--   * two sessions take the same migration slot   -> steward.migration_slots  (§2, §3)
--   * two sessions write the same jurisdiction    -> steward.claims           (§4)
--
-- The other two — a shared worktree's HEAD moving underneath a session, and two sessions
-- staging each other's files — both require a shared working directory. They are conventions,
-- documented in §9 of the design, and are deliberately NOT modelled here.
--
-- 🔴 BEING CAREFUL IS NOT A FIX, WHICH IS WHY THIS IS A TABLE AND NOT A RULE.
--    check-migration-numbers.mjs scans every local and remote ref, and its own header names the
--    hole: a number claimed before anyone pushes is not observable from any repo state. The
--    CC_/CA_ namespaces mitigated that until one author began running concurrent sessions. On
--    2026-09-04 two of Chris Cantrell's sessions came within one step of colliding twice, with
--    the correct procedure followed both times. A PRIMARY KEY makes it impossible instead.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 1. Schema
-- ─────────────────────────────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS steward;

COMMENT ON SCHEMA steward IS
  'Coordination between concurrent sessions, machines and people working in this repo. '
  'Development workflow state, not application data. '
  'Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md';

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 2. Migration slots — the authoritative allocator
--
-- The PRIMARY KEY is the entire point: two sessions cannot both hold ('CC', 70).
--
-- ⚠ There is deliberately NO 'applied' state. This repo has no schema_migrations table and no
--   ordered runner — each migration is applied once, by hand — so nothing can observe that a
--   migration ran. A column claiming to track it would always be stale.
-- ─────────────────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS steward.migration_slots (
  namespace   text        NOT NULL,
  num         integer     NOT NULL CHECK (num > 0),
  state       text        NOT NULL DEFAULT 'reserved'
                          CHECK (state IN ('reserved', 'written', 'abandoned')),
  claimed_by  text        NOT NULL,
  machine     text,
  purpose     text        NOT NULL,
  branch      text,
  filename    text,
  claimed_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (namespace, num)
);

COMMENT ON TABLE steward.migration_slots IS
  'Every migration slot ever claimed. Seeded from git history; thereafter the only sanctioned '
  'way to obtain a number is steward.claim_migration_slot().';
COMMENT ON COLUMN steward.migration_slots.namespace IS
  'CC (Cantrell), CA (Andrews), or the empty string for the shared numeric sequence. '
  'Uppercase; CA_0001 and CA_1 are the SAME slot, so num is stored with leading zeros stripped.';
COMMENT ON COLUMN steward.migration_slots.machine IS
  'Hostname. One author running two boxes is as likely to collide with themselves as with '
  'a second person, so the holder is (email, machine), not email alone.';

CREATE INDEX IF NOT EXISTS migration_slots_by_holder
  ON steward.migration_slots (claimed_by, state);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 3. The allocator
--
-- 🔴 IT REFUSES TO RUN AGAINST AN EMPTY TABLE. Without the git-history seed the max of an
--    empty namespace is nothing, and the first caller would be handed CC_0001 — a number
--    claimed years ago and long since applied to production. That is the single most likely
--    way to deploy this wrongly, so the function will not let you.
-- ─────────────────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION steward.claim_migration_slot(
  p_namespace text,
  p_who       text,
  p_purpose   text,
  p_branch    text DEFAULT NULL,
  p_machine   text DEFAULT NULL
) RETURNS integer
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_ns  text := upper(coalesce(p_namespace, ''));
  v_num integer;
BEGIN
  IF coalesce(p_who, '') = '' OR coalesce(p_purpose, '') = '' THEN
    RAISE EXCEPTION 'claim_migration_slot needs a claimant and a purpose; an anonymous '
                    'reservation tells the next reader nothing';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM steward.migration_slots) THEN
    RAISE EXCEPTION 'steward.migration_slots is EMPTY — seed it from git history before '
                    'allocating, or this would hand out slot 1. Run: npm run steward -- sync --seed';
  END IF;

  -- Serialise callers within a namespace. Two sessions asking at the same instant queue;
  -- the second reads a max that already includes the first.
  PERFORM pg_advisory_xact_lock(hashtext('steward:migration:' || v_ns));

  SELECT coalesce(max(s.num), 0) + 1 INTO v_num
    FROM steward.migration_slots s
   WHERE s.namespace = v_ns;

  INSERT INTO steward.migration_slots (namespace, num, state, claimed_by, machine, purpose, branch)
  VALUES (v_ns, v_num, 'reserved', p_who, p_machine, p_purpose, p_branch);

  RETURN v_num;
END $function$;

COMMENT ON FUNCTION steward.claim_migration_slot(text, text, text, text, text) IS
  'Reserve the next free slot in a namespace, atomically. Refuses on an unseeded table.';

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 4. Jurisdiction claims — the notice board
--
-- Claims are LEASES. An abandoned session must not hold Lomita forever, so expires_at is
-- required and defaults to eight hours.
--
-- ⚠ scope is a plain string and NOT a foreign key: geo_id is not unique — 5,790 distinct
--   values across 7,684 essentials.districts rows on 2026-09-04.
--
-- ⚠ The exclusion constraint catches EXACT scope collisions only. 'county:06037' and
--   'place:0642468' overlap in reality — Lomita sits inside Los Angeles County — but the
--   strings differ, so the database will not stop you. Containment is a warning computed at
--   claim time from geofence_boundaries, not a constraint. Structural for exact, advisory for
--   hierarchical; stated here so nobody reads more safety into this than it has.
-- ─────────────────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS steward.claims (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  scope        text        NOT NULL CHECK (scope <> ''),
  label        text,
  holder       text        NOT NULL,
  machine      text        NOT NULL,
  session_ref  text,
  started_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL DEFAULT now() + interval '8 hours',
  released_at  timestamptz,
  notes        text,
  CONSTRAINT claims_dates_sane CHECK (expires_at > started_at),
  CONSTRAINT claims_release_sane CHECK (released_at IS NULL OR released_at >= started_at),
  CONSTRAINT claims_no_overlap EXCLUDE USING gist (
    scope WITH =,
    tstzrange(started_at, COALESCE(released_at, expires_at), '[)') WITH &&
  )
);

COMMENT ON TABLE steward.claims IS
  'Who is working on which jurisdiction, as a lease. Advisory by design: the point is that '
  'concurrent sessions can SEE each other, not that anyone is blocked.';
COMMENT ON COLUMN steward.claims.scope IS
  'place:<geoid> | county:<fips> | state:<usps>. Free-form so it can also carry non-'
  'jurisdiction scopes later, e.g. worktree:<path>.';

CREATE INDEX IF NOT EXISTS claims_live ON steward.claims (scope)
  WHERE released_at IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 5. Grants. Agreed with Chris Cantrell 2026-09-04: ev_api gets read and write.
--    That is the credential CI and several sessions actually carry. This is development
--    workflow metadata, not user data, so the blast radius of the grant is small.
-- ─────────────────────────────────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA steward TO ev_api;
GRANT SELECT, INSERT, UPDATE ON steward.migration_slots TO ev_api;
GRANT SELECT, INSERT, UPDATE ON steward.claims TO ev_api;
GRANT EXECUTE ON FUNCTION steward.claim_migration_slot(text, text, text, text, text) TO ev_api;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 6. POST-VERIFY. End state, not delta.
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n   int;
  v_err text;
BEGIN
  -- 1. Both tables exist.
  SELECT count(*) INTO v_n FROM information_schema.tables
   WHERE table_schema = 'steward' AND table_name IN ('migration_slots', 'claims');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'expected 2 steward tables, found %', v_n;
  END IF;

  -- 2. The allocator's atomicity actually rests on a primary key.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'steward.migration_slots'::regclass AND contype = 'p'
  ) THEN
    RAISE EXCEPTION 'migration_slots has no primary key — double allocation would be possible';
  END IF;

  -- 3. The overlap exclusion exists. Without it two live claims on one scope are legal.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'steward.claims'::regclass AND conname = 'claims_no_overlap'
       AND contype = 'x'
  ) THEN
    RAISE EXCEPTION 'claims_no_overlap is missing or is not an exclusion constraint';
  END IF;

  -- 4. 🔴 THE GUARD FIRES ON AN EMPTY TABLE. This is the check that matters most: it proves
  --    the allocator cannot be used before seeding, which is the way this gets deployed wrong.
  BEGIN
    PERFORM steward.claim_migration_slot('CC', 'verify@migration', 'post-verify probe');
    RAISE EXCEPTION 'allocator returned a slot against an EMPTY table; the seed guard is dead';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    IF v_err NOT LIKE '%EMPTY%' THEN RAISE; END IF;
  END;

  -- 5. It also refuses an anonymous reservation.
  BEGIN
    PERFORM steward.claim_migration_slot('CC', '', '');
    RAISE EXCEPTION 'allocator accepted an anonymous reservation';
  EXCEPTION WHEN raise_exception THEN
    GET STACKED DIAGNOSTICS v_err = MESSAGE_TEXT;
    IF v_err NOT LIKE '%claimant%' THEN RAISE; END IF;
  END;

  -- 6. ev_api can actually reach it. A steward nobody can write to is worse than none.
  IF NOT has_table_privilege('ev_api', 'steward.migration_slots', 'INSERT')
     OR NOT has_table_privilege('ev_api', 'steward.claims', 'INSERT') THEN
    RAISE EXCEPTION 'ev_api cannot INSERT into the steward tables';
  END IF;

  -- 7. Structure only — the seed is a separate, scripted step.
  SELECT count(*) INTO v_n FROM steward.migration_slots;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'expected migration_slots to be empty at creation, found % row(s)', v_n;
  END IF;

  RAISE NOTICE 'steward schema created: migration_slots (PK-atomic, seed-guarded), claims '
               '(lease + overlap exclusion), allocator, ev_api granted. NOT SEEDED — run '
               'the seeder before allocating.';
END $$;

COMMIT;

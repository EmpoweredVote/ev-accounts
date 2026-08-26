BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-25. Verified: 5 columns on each table, the
-- three reference columns nullable, the two timestamps NOT NULL. FK targets read
-- back from pg_constraint: season_id -> inform.seasons, topic_revision_id ->
-- inform.compass_topic_revisions, editor_id -> public.users (both tables).
-- 33,164 answers / 33,818 context intact, 0 carrying a season, 0 carrying an
-- editor, 1 distinct created_at (the fast default did not rewrite the table).
-- Dry-run first inside BEGIN…ROLLBACK; the revert was confirmed (both tables
-- back to their original 4 columns) before applying.
-- Probed against real data in a rolled-back transaction:
--   1 old-shape INSERT naming only the original columns -> still works
--   2 the new row                -> timestamps defaulted, references NULL
--   3 bogus season_id            -> refused by FK
--   4 editor_id = a real public.users id -> accepted
--   5 editor_id = an auth.users-only id  -> COULD NOT BE TESTED, see below
--   6 old-shape context INSERT   -> still works
-- Nothing left behind: counts and NULL-counts unchanged after the rollback.
--
-- ⚠ Case 5 did not run. It was meant to prove behaviourally that editor_id
-- refuses an id that exists only in auth.users. auth.users and public.users
-- currently hold the SAME 21 ids (auth-only = 0), so no such id exists to test
-- with and the case is vacuous, not passing. The FK target is instead proven
-- from the catalog by resolving confrelid, which reads public.users. Note that
-- pg_get_constraintdef PRINTS it as "REFERENCES users(id)" with no schema,
-- because public is on the search_path — do not read that as ambiguity.

-- =============================================================================
-- CA_0018: Provenance columns on the two answer tables
-- =============================================================================
-- Task 2 of docs/superpowers/plans/2026-08-25-compass-seasons.md. Requires
-- CA_0017 (inform.seasons must exist before anything can reference it).
--
-- Still purely additive. Every new reference column is NULLABLE, so no existing
-- write breaks and no existing read changes. The two timestamps are NOT NULL
-- with a DEFAULT, which on PG 17 is a metadata-only "fast default" — no table
-- rewrite, and every pre-existing row reads back the migration's own clock.
-- That is a known and accepted lie about when those rows were really written:
-- these tables carried NO timestamps at all until now, so the true creation
-- time is not recoverable from anywhere.
--
-- Three deliberate departures from the plan's draft, all recorded here because
-- the next reader will diff them:
--
--   1. editor_id REFERENCES public.users(id), SCHEMA-QUALIFIED. The draft said
--      bare `users(id)`. There are TWO users tables on this database —
--      auth.users (Supabase auth) and public.users — and the resolution of the
--      bare name depends entirely on search_path. Every existing FK from the
--      inform schema to a users table points at public.users; this one matches.
--      Do not un-qualify it.
--   2. The editor_id COMMENT does not describe what the season-1 backfill does
--      with the column. The draft's wording ("NULL means it predates
--      provenance") is contradicted by Task 3, which stamps an editor onto all
--      of these rows and then RAISE EXCEPTIONs if any is left NULL. A COMMENT
--      is production data; it should not ship already false.
--   3. The gate also pins inform.politician_context at 33,818 rows. The draft
--      only pinned the answer count, which would let a surprise on the context
--      side through unnoticed.
-- =============================================================================

ALTER TABLE inform.politician_answers
  ADD COLUMN IF NOT EXISTS season_id         uuid REFERENCES inform.seasons(id),
  ADD COLUMN IF NOT EXISTS topic_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS editor_id         uuid REFERENCES public.users(id),
  ADD COLUMN IF NOT EXISTS created_at        timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz NOT NULL DEFAULT now();

ALTER TABLE inform.politician_context
  ADD COLUMN IF NOT EXISTS season_id         uuid REFERENCES inform.seasons(id),
  ADD COLUMN IF NOT EXISTS topic_revision_id uuid REFERENCES inform.compass_topic_revisions(id),
  ADD COLUMN IF NOT EXISTS editor_id         uuid REFERENCES public.users(id),
  ADD COLUMN IF NOT EXISTS created_at        timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz NOT NULL DEFAULT now();

COMMENT ON COLUMN inform.politician_answers.editor_id IS
  'Who wrote this row, as public.users(id) — NOT auth.users. Nullable by '
  'design: authorship was never recorded before seasons existed, so it cannot '
  'be reconstructed for every row. What the season-1 backfill puts here is the '
  'backfill migration''s decision, not this column''s contract. See the spec, '
  'Open before implementation #1 and #2.';
COMMENT ON COLUMN inform.politician_context.editor_id IS
  'Who wrote this row, as public.users(id) — NOT auth.users. Nullable by design; '
  'see the matching comment on inform.politician_answers.editor_id.';
COMMENT ON COLUMN inform.politician_answers.created_at IS
  'Added by this migration with a fast default, so every row that predates it '
  'shares one timestamp — the moment the column was added. Not a true creation '
  'time for those rows; these tables carried no timestamps before.';
COMMENT ON COLUMN inform.politician_context.created_at IS
  'Added by this migration with a fast default; see the matching comment on '
  'inform.politician_answers.created_at.';

DO $$
DECLARE
  v_answers_cols int;
  v_context_cols int;
  v_editor_fk    text;
BEGIN
  SELECT count(*) INTO v_answers_cols FROM information_schema.columns
   WHERE table_schema='inform' AND table_name='politician_answers'
     AND column_name IN ('season_id','topic_revision_id','editor_id','created_at','updated_at');
  IF v_answers_cols <> 5 THEN
    RAISE EXCEPTION 'politician_answers: expected 5 provenance columns, found %',
      v_answers_cols;
  END IF;

  SELECT count(*) INTO v_context_cols FROM information_schema.columns
   WHERE table_schema='inform' AND table_name='politician_context'
     AND column_name IN ('season_id','topic_revision_id','editor_id','created_at','updated_at');
  IF v_context_cols <> 5 THEN
    RAISE EXCEPTION 'politician_context: expected 5 provenance columns, found %',
      v_context_cols;
  END IF;

  -- The three reference columns must be nullable. If any is NOT NULL, an
  -- existing insert path is already broken and we must not commit.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema='inform'
       AND table_name IN ('politician_answers','politician_context')
       AND column_name IN ('season_id','topic_revision_id','editor_id')
       AND is_nullable = 'NO'
  ) THEN
    RAISE EXCEPTION 'a provenance reference column landed NOT NULL — Task 2 must stay additive';
  END IF;

  -- editor_id must point at public.users, not auth.users. This is the whole
  -- reason the reference is schema-qualified above.
  SELECT tn.nspname || '.' || tc.relname INTO v_editor_fk
    FROM pg_constraint c
    JOIN pg_class sc ON sc.oid = c.conrelid
    JOIN pg_namespace sn ON sn.oid = sc.relnamespace
    JOIN pg_class tc ON tc.oid = c.confrelid
    JOIN pg_namespace tn ON tn.oid = tc.relnamespace
   WHERE sn.nspname='inform' AND sc.relname='politician_answers' AND c.contype='f'
     AND c.conkey = ARRAY[(SELECT attnum FROM pg_attribute
                            WHERE attrelid = sc.oid AND attname='editor_id')]::smallint[];
  IF v_editor_fk IS DISTINCT FROM 'public.users' THEN
    RAISE EXCEPTION 'editor_id FK points at %, expected public.users',
      coalesce(v_editor_fk, '<none>');
  END IF;

  -- Nothing may have been added, lost or rewritten.
  IF (SELECT count(*) FROM inform.politician_answers) <> 33164 THEN
    RAISE EXCEPTION 'answer count changed: expected 33164, got %',
      (SELECT count(*) FROM inform.politician_answers);
  END IF;
  IF (SELECT count(*) FROM inform.politician_context) <> 33818 THEN
    RAISE EXCEPTION 'context count changed: expected 33818, got %',
      (SELECT count(*) FROM inform.politician_context);
  END IF;

  -- Additive means additive: no row may have acquired a season yet.
  IF (SELECT count(*) FROM inform.politician_answers WHERE season_id IS NOT NULL) <> 0
     OR (SELECT count(*) FROM inform.politician_context WHERE season_id IS NOT NULL) <> 0 THEN
    RAISE EXCEPTION 'a row already carries a season — that is Task 3, not this migration';
  END IF;

  RAISE NOTICE 'provenance columns OK — 5+5 columns, all references nullable, '
               'editor_id -> public.users, 33164 answers / 33818 context intact';
END $$;

COMMIT;

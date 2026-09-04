BEGIN;

-- =============================================================================
-- CC_0040: drop the legacy pair scaffolds — ADR 0005 §1.6, rollout step 3
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell (4e6dde8f-2bd0-4054-824f-4164744165ea).
--
-- WHAT: drops the two scaffolding unique indexes CC_0002 deliberately left up:
--   inform.politician_answers_legacy_pair_scaffold  UNIQUE (politician_id, topic_id)
--   inform.politician_context_legacy_pair_scaffold  UNIQUE (politician_id, topic_id)
--
-- WHY NOW: these are an interlock, not an oversight. While they stand the database
--   PHYSICALLY CANNOT HOLD A SECOND SEASON — a politician may have exactly one
--   answer per topic, full stop. `inform.admin_open_season` checks for them
--   structurally and raises SCAFFOLD_INDEXES_PRESENT, so **Season 2 cannot be
--   opened until this lands**. ADR 0005 §1.6 sequences it:
--     1. Deploy season-aware code            DONE (PR #177)
--     2. Migrate the five RPCs               DONE (CC_0003)
--     3. Drop the scaffolding indexes        <- THIS MIGRATION
--     4. Open Season 2                       next, and Chris's call
--     5. Closed-season immutability trigger  STILL OUTSTANDING, see below
--
-- WHAT THIS UNLOCKS, AND WHY IT MATTERS BEYOND SEASON 2. Season 1 seatings are
--   the historical record: the compass is meant to show how and when someone
--   changed their stance. Correcting a Season 1 answer in place destroys that.
--   With these indexes up there is no alternative — one row per (politician,
--   topic) is all the database allows, so every correction is a rewrite of
--   history. Dropping them is what makes "Season 1 stays intact, Season 2 is
--   built from it" expressible at all.
--
-- 🔴 THE PRECEDENTS GOT THIS WRONG AND IT COST REAL HISTORY. CA_0035 and CA_0056
--   both state in their headers that the schema "cannot represent blank in
--   Season 2, seated in Season 1" and therefore applied their corrections IN
--   PLACE to open Season 1 — 13 and 58 deletions respectively. The premise was
--   false even then: both primary keys already carry season_id. The pair
--   scaffolds, not the schema, were the constraint. Those 71 rows are gone.
--
-- SAFETY — NOTHING DEPENDS ON THESE INDEXES:
--   * Uniqueness is not lost. The real primary keys already cover the same
--     columns plus season_id:
--       politician_answers_pkey  UNIQUE (politician_id, topic_id, season_id)
--       politician_context_pkey  UNIQUE (politician_id, topic_id, season_id)
--     Within a single season the guarantee is identical; across seasons it is
--     the guarantee we now want.
--   * No write path targets the pair. Every upsert in backend/src/lib/
--     seasonService.ts (4 sites) already uses
--     ON CONFLICT (politician_id, topic_id, season_id), and
--     seasonService.test.ts asserts that conflict target explicitly.
--   * The guard below refuses to drop anything unless both season-aware primary
--     keys are present, so this can never leave the tables unprotected.
--
-- ⚠ STEP 5 IS NOT THIS MIGRATION AND IS EASY TO FORGET. Once a second season
--   exists, nothing at the schema level stops a direct write into a CLOSED
--   season. The write paths only ever target the open one, so the application is
--   safe; a direct SQL write is not. ADR 0005 §1.6 step 5 adds that trigger, and
--   it is the thing that actually enforces "you cannot adjust your old stances".
--   It should follow closely behind opening Season 2.
--
-- IDEMPOTENT: DROP INDEX IF EXISTS. Re-running is a no-op.
-- TO REVERT: recreate either index — but note that doing so re-imposes the
--   one-season-only limit and will break any second-season rows that exist by
--   then, so a revert is only safe before Season 2 opens.
-- =============================================================================

DO $$
DECLARE
  v_pk_answers  int;
  v_pk_context  int;
BEGIN
  -- Refuse to proceed unless the season-aware primary keys are actually there.
  SELECT count(*) INTO v_pk_answers
    FROM pg_index x JOIN pg_class t ON t.oid = x.indrelid
    JOIN pg_class i ON i.oid = x.indexrelid JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname='inform' AND t.relname='politician_answers'
     AND i.relname='politician_answers_pkey' AND x.indisunique;

  SELECT count(*) INTO v_pk_context
    FROM pg_index x JOIN pg_class t ON t.oid = x.indrelid
    JOIN pg_class i ON i.oid = x.indexrelid JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname='inform' AND t.relname='politician_context'
     AND i.relname='politician_context_pkey' AND x.indisunique;

  IF v_pk_answers <> 1 OR v_pk_context <> 1 THEN
    RAISE EXCEPTION
      'CC_0040: season-aware primary keys not found (answers=%, context=%) — refusing to drop the scaffolds and leave the tables unprotected',
      v_pk_answers, v_pk_context;
  END IF;
END $$;

DROP INDEX IF EXISTS inform.politician_answers_legacy_pair_scaffold;
DROP INDEX IF EXISTS inform.politician_context_legacy_pair_scaffold;

-- ---------------------------------------------------------------------------
-- Post-verify gate. The last check is the one that matters: it asks the same
-- structural question admin_open_season asks, so a pass here means the season
-- open will no longer refuse.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_scaffolds int;
  v_pkeys     int;
  v_interlock boolean;
BEGIN
  SELECT count(*) INTO v_scaffolds
    FROM pg_class i JOIN pg_namespace n ON n.oid = i.relnamespace
   WHERE n.nspname='inform'
     AND i.relname IN ('politician_answers_legacy_pair_scaffold','politician_context_legacy_pair_scaffold');
  IF v_scaffolds <> 0 THEN
    RAISE EXCEPTION 'CC_0040: % scaffold index(es) survive', v_scaffolds;
  END IF;

  SELECT count(*) INTO v_pkeys
    FROM pg_class i JOIN pg_namespace n ON n.oid = i.relnamespace
   WHERE n.nspname='inform'
     AND i.relname IN ('politician_answers_pkey','politician_context_pkey');
  IF v_pkeys <> 2 THEN
    RAISE EXCEPTION 'CC_0040: expected both season-aware primary keys, found %', v_pkeys;
  END IF;

  -- admin_open_season's own test, reproduced verbatim in shape.
  SELECT EXISTS (
    SELECT 1
      FROM pg_index i
      JOIN pg_class t ON t.oid = i.indrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
     WHERE n.nspname = 'inform'
       AND t.relname IN ('politician_answers', 'politician_context')
       AND i.indisunique
       AND i.indnkeyatts = 2
       AND (SELECT array_agg(a.attname ORDER BY k.ord)
              FROM unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord)
              JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
           ) = ARRAY['politician_id', 'topic_id']::name[]
  ) INTO v_interlock;
  IF v_interlock THEN
    RAISE EXCEPTION 'CC_0040: admin_open_season would still raise SCAFFOLD_INDEXES_PRESENT';
  END IF;

  RAISE NOTICE 'CC_0040 OK — scaffolds dropped, season-aware primary keys intact, open-season interlock clear';
END $$;

COMMIT;

BEGIN;

-- =============================================================================
-- CA_0341: the argument tree — connect.claims, claim_ratings, claim_edits
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews. Task 1 of the argument-tree build.
--
-- WHAT THIS DOES
-- Adds the three tables every later task reads or writes, plus their indexes,
-- grants, RLS policies and triggers, and seeds one root claim per community.
-- Nothing reads them yet.
--
--   connect.claims        the tree. One root per community (parent, side and
--                         author all NULL), children that `supports` or
--                         `opposes` their parent. `path` is the root-first list
--                         of ancestors EXCLUDING self; depth = cardinality(path).
--   connect.claim_ratings one row per (claim, user), value 1-9, with the rater's
--                         account age and verification status snapshotted at
--                         rating time so weighting can be recomputed later.
--   connect.claim_edits   append-only history. Written ONLY by the trigger below.
--
-- A root claim is not only backfilled for the 44 communities that exist today — section
-- 7a puts an AFTER INSERT trigger on connect.communities so every community created from
-- now on gets one too. The root read is the entry point for the whole argument band; a
-- community without a root is a tree that 404s on first load with nothing to explain why.
-- Section 9's gate proves the trigger works by actually inserting a throwaway community
-- and rolling it back, not merely by finding a row in pg_trigger.
--
-- WHY THE TREE IS NOT SEASONED
-- Compass topics move through editorial seasons (CA_0340). The argument tree does
-- not: a claim about a problem outlives the season in which it was written, so
-- claims carries no season_id and is keyed to the community, not a revision.
--
-- REUSED, NOT RECREATED
--   * connect.moderation_status already exists ('visible','hidden') — the guard in
--     section 0 fails loudly rather than letting a CREATE TYPE collide.
--   * connect.snapshot_author_display_name() already exists, is SECURITY DEFINER
--     owned by postgres, and is fully generic (its body reads NEW.author_id and
--     assigns NEW.author_display_name). It is attached here rather than copied.
--     🔴 The WHEN (NEW.author_id IS NOT NULL) clause on that trigger is load
--     bearing: the function stamps 'Unknown' when author_id is NULL, and every
--     root claim has a NULL author by design. Without the WHEN clause this
--     migration would invent an author named "Unknown" for all 44 roots. The
--     post-verify gate in section 9 asserts both the clause and its effect.
--
-- WHY log_claim_edit DOES NOT COPY log_post_edit
-- connect.log_post_edit() records OLD.author_id as the editor. That is right for a
-- post (only its author may edit it) and wrong for a claim: Task 7 lets a maven
-- move, merge and hide claims they did not write, and copying the pattern would
-- attribute every one of those to the claim's original author. Instead the route
-- announces itself before the UPDATE:
--     SELECT set_config('fc.actor_id', $1, true);   -- true = transaction-local
--     UPDATE connect.claims SET ... WHERE id = $2;
-- and the trigger reads it back with current_setting('fc.actor_id', true). An
-- UPDATE that reaches a logged column without that setting RAISES. An edit with
-- no recorded actor is an unaudited edit, and claim_edits.actor_id is NOT NULL —
-- failing loudly is the only honest option. This applies to a psql session too:
-- set fc.actor_id first, or the UPDATE is refused.
--
-- COUNTS SURVIVE CONCURRENCY AND MOVES
-- child_supports_count / child_opposes_count are bumped with count = count ± 1
-- inside the trigger's UPDATE — never read in one statement and written in
-- another — so two sessions inserting a child of the same parent serialize on the
-- parent's row lock and both land. The trigger also fires on a move
-- (UPDATE OF parent_claim_id, side): the OLD parent's OLD side decrements and the
-- NEW parent's NEW side increments, so counts self-correct instead of drifting
-- upward forever. Hiding a claim touches moderation_status only and is deliberately
-- NOT counted — a hidden claim is still a child, and the read API filters.
--
-- NOTHING IS EVER DELETED
-- No DELETE grant on any of the three tables, to any role — memory over moderation,
-- as with threads and posts. A claim is withdrawn by setting moderation_status,
-- superseded by setting merged_into_claim_id. This goes further than threads and
-- posts do: the connect schema's default privileges hand service_role and ev_api
-- DELETE on every new table, and section 8 takes it back. Section 9 asserts the
-- absence for all five grantable roles.
--
-- TWO DELIBERATE DEPARTURES FROM THE BRIEF, both flagged for review:
--   1. The brief asks for an index on claim_ratings (claim_id). It is not created:
--      the UNIQUE (claim_id, user_id) constraint already builds a btree whose
--      leading column is claim_id, which serves `WHERE claim_id = ?` identically.
--      A second index would cost every rating write and buy nothing.
--   2. The brief scopes log_claim_edit to "body or parent changed". That WHEN
--      clause can never produce the 'merge' or 'hide' values its own kind check
--      allows, so it also fires on side, merged_into_claim_id and
--      moderation_status. Narrow it here if the intent was to leave merges and
--      hides unlogged.
--
-- updated_at is set by the routes, matching threads and posts — there is no touch
-- trigger anywhere in the connect schema and this migration does not add one.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and
-- lets a DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 0. Preconditions. Reuse, do not recreate.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'connect' AND t.typname = 'moderation_status'
  ) THEN
    RAISE EXCEPTION 'CA_0341: connect.moderation_status is missing — this migration reuses that enum, it does not create it';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'connect' AND p.proname = 'snapshot_author_display_name'
  ) THEN
    RAISE EXCEPTION 'CA_0341: connect.snapshot_author_display_name() is missing — this migration attaches it, it does not create it';
  END IF;
END $$;

-- 1. connect.claims — the tree.
CREATE TABLE IF NOT EXISTS connect.claims (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id          UUID NOT NULL REFERENCES connect.communities(id),
  parent_claim_id       UUID REFERENCES connect.claims(id),
  side                  TEXT,
  body                  TEXT NOT NULL,
  author_id             UUID,
  author_display_name   TEXT,
  moderation_status     connect.moderation_status NOT NULL DEFAULT 'visible',
  path                  UUID[] NOT NULL,          -- root-first ancestors, EXCLUDING self
  depth                 INT NOT NULL,
  child_supports_count  INT NOT NULL DEFAULT 0,
  child_opposes_count   INT NOT NULL DEFAULT 0,
  merged_into_claim_id  UUID REFERENCES connect.claims(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT claims_side_values CHECK (side IS NULL OR side IN ('supports', 'opposes')),
  CONSTRAINT claims_body_not_blank CHECK (btrim(body) <> ''),
  CONSTRAINT claims_no_self_parent CHECK (parent_claim_id IS DISTINCT FROM id),
  CONSTRAINT claims_no_self_merge CHECK (merged_into_claim_id IS DISTINCT FROM id),
  CONSTRAINT claims_counts_nonnegative CHECK (child_supports_count >= 0 AND child_opposes_count >= 0),

  -- Root and child are two shapes, not one shape with optional parts. A root has no
  -- parent, no side, depth 0 and an empty path; a child has all four. depth and path
  -- are derived, so this also catches a route that writes one and forgets the other.
  CONSTRAINT claims_root_or_child_shape CHECK (
    (parent_claim_id IS NULL     AND side IS NULL     AND depth = 0 AND cardinality(path) = 0)
    OR
    (parent_claim_id IS NOT NULL AND side IS NOT NULL AND depth > 0 AND cardinality(path) = depth)
  )
);

-- The brief's "one root claim per row in connect.communities", enforced rather than
-- merely seeded: a second root for a community is rejected by the index, not by a route.
CREATE UNIQUE INDEX IF NOT EXISTS claims_one_root_per_community
  ON connect.claims (community_id) WHERE parent_claim_id IS NULL;

-- Reading one parent's children, the hot path for the tree API.
CREATE INDEX IF NOT EXISTS claims_community_parent_idx
  ON connect.claims (community_id, parent_claim_id);

-- Subtree reads: WHERE path @> ARRAY[<ancestor>]::uuid[].
CREATE INDEX IF NOT EXISTS claims_path_gin_idx
  ON connect.claims USING gin (path);

-- 2. connect.claim_ratings — one row per (claim, user).
-- rater_account_age_days and rater_verification_status are SNAPSHOTS taken when the
-- rating was cast. They are not a join to the account: an account that verifies next
-- month must not retroactively reweight a rating it cast today.
CREATE TABLE IF NOT EXISTS connect.claim_ratings (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id                  UUID NOT NULL REFERENCES connect.claims(id),
  user_id                   UUID NOT NULL,
  value                     INT NOT NULL,
  rater_account_age_days    INT,
  rater_verification_status TEXT,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT claim_ratings_value_range CHECK (value BETWEEN 1 AND 9),
  CONSTRAINT claim_ratings_one_per_user UNIQUE (claim_id, user_id)
);
-- No separate (claim_id) index: claim_ratings_one_per_user is a btree led by claim_id
-- and already serves `WHERE claim_id = ?`. See the header's departure #1.

-- 3. connect.claim_edits — append-only, trigger-written.
CREATE TABLE IF NOT EXISTS connect.claim_edits (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id              UUID NOT NULL REFERENCES connect.claims(id),
  actor_id              UUID NOT NULL,   -- the real actor, from fc.actor_id; see header
  kind                  TEXT NOT NULL,
  old_body              TEXT,
  old_parent_claim_id   UUID,
  merge_target_claim_id UUID,
  edited_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT claim_edits_kind_values CHECK (kind IN ('edit', 'move', 'merge', 'hide'))
);

CREATE INDEX IF NOT EXISTS claim_edits_claim_idx
  ON connect.claim_edits (claim_id, edited_at DESC);

-- 4. Display-name snapshot. The EXISTING generic function, with the WHEN clause that
--    keeps it away from the authorless roots (see header).
DROP TRIGGER IF EXISTS trg_claims_snapshot_display_name ON connect.claims;
CREATE TRIGGER trg_claims_snapshot_display_name
BEFORE INSERT ON connect.claims
FOR EACH ROW
WHEN (NEW.author_id IS NOT NULL)
EXECUTE FUNCTION connect.snapshot_author_display_name();

-- 5. Child counts. An insert bumps the new parent; a move debits the old parent's old
--    side and credits the new parent's new side. Every change is count = count ± 1
--    evaluated inside the UPDATE, so concurrent children of one parent serialize on
--    that parent's row lock and neither is lost.
CREATE OR REPLACE FUNCTION connect.bump_claim_child_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'connect', 'pg_temp'
AS $fn$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.parent_claim_id IS NOT NULL THEN
    UPDATE connect.claims
       SET child_supports_count = child_supports_count - (COALESCE(OLD.side, '') = 'supports')::int,
           child_opposes_count  = child_opposes_count  - (COALESCE(OLD.side, '') = 'opposes')::int
     WHERE id = OLD.parent_claim_id;
  END IF;

  IF NEW.parent_claim_id IS NOT NULL THEN
    UPDATE connect.claims
       SET child_supports_count = child_supports_count + (COALESCE(NEW.side, '') = 'supports')::int,
           child_opposes_count  = child_opposes_count  + (COALESCE(NEW.side, '') = 'opposes')::int
     WHERE id = NEW.parent_claim_id;
  END IF;

  RETURN NULL;  -- AFTER trigger: the return value is ignored.
END;
$fn$;

-- Two triggers, one function: a WHEN clause may not mention OLD on a trigger whose
-- event list includes INSERT, so the insert case and the move case are declared apart.
DROP TRIGGER IF EXISTS trg_claims_bump_child_counts_insert ON connect.claims;
CREATE TRIGGER trg_claims_bump_child_counts_insert
AFTER INSERT ON connect.claims
FOR EACH ROW
WHEN (NEW.parent_claim_id IS NOT NULL)
EXECUTE FUNCTION connect.bump_claim_child_counts();

-- UPDATE OF parent_claim_id, side also covers a re-classification that keeps the parent
-- and flips supports <-> opposes: that moves a count too. The WHEN clause makes the
-- trigger a no-op when a route merely restates a column at its current value.
DROP TRIGGER IF EXISTS trg_claims_bump_child_counts_move ON connect.claims;
CREATE TRIGGER trg_claims_bump_child_counts_move
AFTER UPDATE OF parent_claim_id, side ON connect.claims
FOR EACH ROW
WHEN (OLD.parent_claim_id IS DISTINCT FROM NEW.parent_claim_id
      OR OLD.side IS DISTINCT FROM NEW.side)
EXECUTE FUNCTION connect.bump_claim_child_counts();

-- 6. Edit history, recording the real actor (see header).
CREATE OR REPLACE FUNCTION connect.log_claim_edit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'connect', 'pg_temp'
AS $fn$
DECLARE
  v_actor_text TEXT;
  v_actor      UUID;
  v_kind       TEXT;
BEGIN
  -- Absent (never set this session) and empty (set then cleared) both arrive as NULL.
  v_actor_text := NULLIF(btrim(COALESCE(current_setting('fc.actor_id', true), '')), '');

  IF v_actor_text IS NULL THEN
    RAISE EXCEPTION
      'connect.log_claim_edit: fc.actor_id is not set, so this edit to claim % has no recorded actor. Run SELECT set_config(''fc.actor_id'', ''<user uuid>'', true); in the same transaction before the UPDATE.',
      OLD.id;
  END IF;

  BEGIN
    v_actor := v_actor_text::uuid;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'connect.log_claim_edit: fc.actor_id is not a uuid (got %)', v_actor_text;
  END;

  -- One UPDATE may do several things at once; the kind names the strongest of them.
  -- The OLD body and OLD parent are stored regardless, so the row is enough to undo.
  IF NEW.merged_into_claim_id IS DISTINCT FROM OLD.merged_into_claim_id
     AND NEW.merged_into_claim_id IS NOT NULL THEN
    v_kind := 'merge';
  ELSIF NEW.parent_claim_id IS DISTINCT FROM OLD.parent_claim_id
     OR NEW.side IS DISTINCT FROM OLD.side THEN
    v_kind := 'move';
  ELSIF NEW.moderation_status IS DISTINCT FROM OLD.moderation_status THEN
    v_kind := 'hide';
  ELSE
    v_kind := 'edit';
  END IF;

  INSERT INTO connect.claim_edits
    (claim_id, actor_id, kind, old_body, old_parent_claim_id, merge_target_claim_id)
  VALUES
    (OLD.id, v_actor, v_kind, OLD.body, OLD.parent_claim_id, NEW.merged_into_claim_id);

  RETURN NULL;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_log_claim_edit ON connect.claims;
CREATE TRIGGER trg_log_claim_edit
AFTER UPDATE ON connect.claims
FOR EACH ROW
WHEN (OLD.body                 IS DISTINCT FROM NEW.body
   OR OLD.parent_claim_id      IS DISTINCT FROM NEW.parent_claim_id
   OR OLD.side                 IS DISTINCT FROM NEW.side
   OR OLD.merged_into_claim_id IS DISTINCT FROM NEW.merged_into_claim_id
   OR OLD.moderation_status    IS DISTINCT FROM NEW.moderation_status)
EXECUTE FUNCTION connect.log_claim_edit();

-- 7a. Every community gets a root claim, forever — not just the 44 that exist today.
--     The root read is the entry point for the whole argument band, so a community with
--     no root is a tree that 404s on first load with nothing to explain why. A one-time
--     backfill (7b) cannot promise that; a trigger can. The body is the community's
--     name: a topic label that is always honest, rather than a description field that
--     frames a real question for some communities and opens with instructional filler
--     for others. A better framing is an editorial act, not something to synthesize here.
CREATE OR REPLACE FUNCTION connect.seed_community_root_claim()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'connect', 'pg_temp'
AS $fn$
BEGIN
  IF btrim(COALESCE(NEW.name, '')) = '' THEN
    RAISE EXCEPTION
      'connect.seed_community_root_claim: community % has a blank name, so its root claim would have no body. The root of an argument tree is its problem statement — name the community first.',
      NEW.id;
  END IF;

  -- No-op if a root is already there, so this trigger and the 7b backfill can never
  -- collide, in either order, however many times either one runs.
  INSERT INTO connect.claims (community_id, body, path, depth)
  SELECT NEW.id, NEW.name, '{}'::uuid[], 0
  WHERE NOT EXISTS (
    SELECT 1 FROM connect.claims k
    WHERE k.community_id = NEW.id AND k.parent_claim_id IS NULL
  );

  RETURN NULL;  -- AFTER trigger: the return value is ignored.
END;
$fn$;

DROP TRIGGER IF EXISTS trg_communities_seed_root_claim ON connect.communities;
CREATE TRIGGER trg_communities_seed_root_claim
AFTER INSERT ON connect.communities
FOR EACH ROW
EXECUTE FUNCTION connect.seed_community_root_claim();

-- 7b. Backfill the communities that already exist. Same shape the trigger produces, same
--     NOT EXISTS guard, so a re-run is a no-op; the unique index would reject a duplicate
--     anyway.
INSERT INTO connect.claims (community_id, body, path, depth)
SELECT c.id, c.name, '{}'::uuid[], 0
FROM connect.communities c
WHERE NOT EXISTS (
  SELECT 1 FROM connect.claims k
  WHERE k.community_id = c.id AND k.parent_claim_id IS NULL
);

-- 8. Grants and RLS, mirroring CA_0323. focused_communities_app holds no BYPASSRLS,
--    so each table needs both a grant and a policy scoped to that role.
GRANT SELECT, INSERT, UPDATE ON connect.claims, connect.claim_ratings TO focused_communities_app;
GRANT SELECT ON connect.claim_edits TO focused_communities_app;

-- claim_edits is written by a SECURITY DEFINER trigger and by nothing else. The connect
-- schema's ALTER DEFAULT PRIVILEGES (20260415214600) hands `authenticated` INSERT and
-- UPDATE on every new table in the schema; RLS already refuses them for want of a
-- policy, but an audit table should not carry the grant at all.
REVOKE INSERT, UPDATE ON connect.claim_edits FROM authenticated;

-- 🔴 THIS IS WHERE THE ARGUMENT TREE DIFFERS FROM threads AND posts.
-- That same ALTER DEFAULT PRIVILEGES also hands service_role (arwdDxtm) and ev_api
-- (arwd) DELETE on every new connect table — both hold DELETE on threads, posts and
-- post_edits today. "Nothing is ever deleted" is stated for the tree without exception,
-- so the inherited DELETE (and service_role's TRUNCATE) is taken back here instead of
-- being left as a default nobody chose. A claim is withdrawn, not removed; the edit
-- history that proves it must outlive the claim.
-- The table owner, postgres, is a superuser and is not constrained by any grant — this
-- closes the door to every role that is. Drop these four lines if the tree should match
-- threads and posts rather than exceed them.
REVOKE DELETE, TRUNCATE ON connect.claims, connect.claim_ratings, connect.claim_edits FROM service_role;
REVOKE DELETE, TRUNCATE ON connect.claims, connect.claim_ratings, connect.claim_edits FROM ev_api;
REVOKE DELETE, TRUNCATE ON connect.claims, connect.claim_ratings, connect.claim_edits FROM authenticated;
REVOKE DELETE, TRUNCATE ON connect.claims, connect.claim_ratings, connect.claim_edits FROM anon;

ALTER TABLE connect.claims        ENABLE ROW LEVEL SECURITY;
ALTER TABLE connect.claim_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE connect.claim_edits   ENABLE ROW LEVEL SECURITY;

-- No policies for anon or authenticated: these tables are reached through the module's
-- routes, never through PostgREST. RLS with no matching policy denies, which is the
-- intended answer for both roles.
DROP POLICY IF EXISTS fc_app_select ON connect.claims;
CREATE POLICY fc_app_select ON connect.claims FOR SELECT TO focused_communities_app USING (true);
DROP POLICY IF EXISTS fc_app_insert ON connect.claims;
CREATE POLICY fc_app_insert ON connect.claims FOR INSERT TO focused_communities_app WITH CHECK (true);
DROP POLICY IF EXISTS fc_app_update ON connect.claims;
CREATE POLICY fc_app_update ON connect.claims FOR UPDATE TO focused_communities_app USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS fc_app_select ON connect.claim_ratings;
CREATE POLICY fc_app_select ON connect.claim_ratings FOR SELECT TO focused_communities_app USING (true);
DROP POLICY IF EXISTS fc_app_insert ON connect.claim_ratings;
CREATE POLICY fc_app_insert ON connect.claim_ratings FOR INSERT TO focused_communities_app WITH CHECK (true);
DROP POLICY IF EXISTS fc_app_update ON connect.claim_ratings;
CREATE POLICY fc_app_update ON connect.claim_ratings FOR UPDATE TO focused_communities_app USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS fc_app_select ON connect.claim_edits;
CREATE POLICY fc_app_select ON connect.claim_edits FOR SELECT TO focused_communities_app USING (true);

-- 9. Post-verify gate — fail loudly if this migration did not achieve what it claims.
DO $$
DECLARE
  v_communities INT;
  v_roots       INT;
  v_tbl         TEXT;
  v_role        TEXT;
  v_trigdef     TEXT;
  v_probe_id          UUID;
  v_probe_well_shaped INT;
  v_probe_total       INT;
  v_probe_ok          BOOLEAN := false;
  v_probe_detail      TEXT;
BEGIN
  -- a. RLS is on for all three.
  FOREACH v_tbl IN ARRAY ARRAY['claims', 'claim_ratings', 'claim_edits'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'connect' AND c.relname = v_tbl) THEN
      RAISE EXCEPTION 'CA_0341: RLS is not enabled on connect.%', v_tbl;
    END IF;
  END LOOP;

  -- b. The module's role can do exactly what it needs and no more.
  IF NOT has_table_privilege('focused_communities_app', 'connect.claims', 'SELECT,INSERT,UPDATE')
     OR NOT has_table_privilege('focused_communities_app', 'connect.claim_ratings', 'SELECT,INSERT,UPDATE') THEN
    RAISE EXCEPTION 'CA_0341: missing SELECT/INSERT/UPDATE on connect.claims or connect.claim_ratings';
  END IF;
  IF NOT has_table_privilege('focused_communities_app', 'connect.claim_edits', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0341: missing SELECT on connect.claim_edits';
  END IF;
  IF has_table_privilege('focused_communities_app', 'connect.claim_edits', 'INSERT')
     OR has_table_privilege('focused_communities_app', 'connect.claim_edits', 'UPDATE') THEN
    RAISE EXCEPTION 'CA_0341: focused_communities_app must not write connect.claim_edits directly — the trigger owns it';
  END IF;

  -- c. Nothing is ever deleted, asserted from the other side, for every role that a
  --    grant can constrain. postgres owns the tables and is exempt by definition.
  FOREACH v_role IN ARRAY ARRAY['focused_communities_app', 'anon', 'authenticated', 'service_role', 'ev_api'] LOOP
    FOREACH v_tbl IN ARRAY ARRAY['claims', 'claim_ratings', 'claim_edits'] LOOP
      IF has_table_privilege(v_role, 'connect.' || v_tbl, 'DELETE') THEN
        RAISE EXCEPTION 'CA_0341: % can DELETE connect.% — nothing in the argument tree is ever deleted', v_role, v_tbl;
      END IF;
    END LOOP;
  END LOOP;

  -- d. One root per community, and no more.
  SELECT count(*) INTO v_communities FROM connect.communities;
  SELECT count(*) INTO v_roots FROM connect.claims WHERE depth = 0;
  IF v_roots <> v_communities THEN
    RAISE EXCEPTION 'CA_0341: % root claims for % communities — expected one each', v_roots, v_communities;
  END IF;

  -- e. The WHEN clause on the snapshot trigger, and its effect. If this is ever dropped,
  --    every authorless root silently acquires an author called "Unknown".
  SELECT pg_get_triggerdef(t.oid) INTO v_trigdef
  FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'connect' AND c.relname = 'claims' AND t.tgname = 'trg_claims_snapshot_display_name';
  IF v_trigdef IS NULL OR v_trigdef NOT LIKE '%author_id IS NOT NULL%' THEN
    RAISE EXCEPTION 'CA_0341: trg_claims_snapshot_display_name is missing its WHEN (NEW.author_id IS NOT NULL) guard';
  END IF;
  IF EXISTS (SELECT 1 FROM connect.claims WHERE author_id IS NULL AND author_display_name IS NOT NULL) THEN
    RAISE EXCEPTION 'CA_0341: an authorless claim was given a display name — the snapshot trigger fired where it must not';
  END IF;

  -- f. The count and edit triggers are attached.
  IF (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'connect' AND c.relname = 'claims' AND NOT t.tgisinternal
        AND t.tgname IN ('trg_claims_bump_child_counts_insert',
                         'trg_claims_bump_child_counts_move',
                         'trg_log_claim_edit')) <> 3 THEN
    RAISE EXCEPTION 'CA_0341: the child-count and edit-log triggers are not all attached to connect.claims';
  END IF;

  -- g. Seeded roots start at zero and are shaped as roots.
  IF EXISTS (SELECT 1 FROM connect.claims WHERE depth = 0
             AND (parent_claim_id IS NOT NULL OR side IS NOT NULL OR author_id IS NOT NULL
                  OR cardinality(path) <> 0 OR child_supports_count <> 0 OR child_opposes_count <> 0)) THEN
    RAISE EXCEPTION 'CA_0341: a seeded root claim is not shaped like a root';
  END IF;

  -- h. The root-claim trigger is attached to connect.communities...
  SELECT pg_get_triggerdef(t.oid) INTO v_trigdef
  FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'connect' AND c.relname = 'communities'
    AND t.tgname = 'trg_communities_seed_root_claim' AND NOT t.tgisinternal;
  IF v_trigdef IS NULL THEN
    RAISE EXCEPTION 'CA_0341: trg_communities_seed_root_claim is not attached to connect.communities — community #45 would have no root claim and its tree would 404';
  END IF;

  -- i. ...and it actually works. A gate that only reads pg_trigger proves the trigger
  --    exists, not that it seeds anything, so this inserts a throwaway community, checks
  --    what appeared, and unwinds. The RAISE at the end of the inner block aborts the
  --    implicit subtransaction that plpgsql opens for any BEGIN...EXCEPTION block, which
  --    rolls back the probe community AND its root claim. plpgsql variables are not
  --    transactional, so the verdict computed inside survives the unwind. The probe
  --    therefore leaves nothing behind whether the outer transaction commits or not.
  BEGIN
    INSERT INTO connect.communities (topic_id, slug, name)
    VALUES (gen_random_uuid(),
            'ca0341-root-trigger-probe-' || gen_random_uuid()::text,  -- slug is UNIQUE; never collide
            'CA_0341 root trigger probe')
    RETURNING id INTO v_probe_id;

    SELECT count(*) INTO v_probe_total
    FROM connect.claims WHERE community_id = v_probe_id;

    SELECT count(*) INTO v_probe_well_shaped
    FROM connect.claims
    WHERE community_id = v_probe_id
      AND parent_claim_id IS NULL
      AND side IS NULL
      AND author_id IS NULL
      AND author_display_name IS NULL          -- the WHEN guard held: no invented "Unknown"
      AND body = 'CA_0341 root trigger probe'  -- body is the community's name
      AND cardinality(path) = 0
      AND depth = 0
      AND moderation_status = 'visible'
      AND child_supports_count = 0
      AND child_opposes_count = 0;

    IF v_probe_total = 1 AND v_probe_well_shaped = 1 THEN
      v_probe_ok := true;
    ELSE
      v_probe_detail := format('%s claim(s) for the probe community, %s of them a well-shaped root; expected 1 and 1',
                               v_probe_total, v_probe_well_shaped);
    END IF;

    -- Deliberate abort: this is how the probe cleans up after itself.
    RAISE EXCEPTION 'CA_0341 probe rollback' USING ERRCODE = 'CA341';
  EXCEPTION
    WHEN SQLSTATE 'CA341' THEN
      NULL;  -- expected; any other error propagates and fails the migration, as it should
  END;

  IF NOT v_probe_ok THEN
    RAISE EXCEPTION 'CA_0341: the root-claim trigger did not seed exactly one well-shaped root for a new community — %',
      COALESCE(v_probe_detail, 'the probe did not run to completion');
  END IF;

  IF EXISTS (SELECT 1 FROM connect.communities WHERE id = v_probe_id)
     OR EXISTS (SELECT 1 FROM connect.claims WHERE community_id = v_probe_id) THEN
    RAISE EXCEPTION 'CA_0341: the trigger probe left rows behind — the subtransaction did not unwind';
  END IF;

  RAISE NOTICE 'CA_0341 OK — connect.claims / claim_ratings / claim_edits created, RLS on, scoped to focused_communities_app (no DELETE anywhere), % root claims backfilled, snapshot/count/edit triggers attached, and connect.communities now seeds a root claim for every new community (verified by probe, rolled back).', v_roots;
END $$;

COMMIT;

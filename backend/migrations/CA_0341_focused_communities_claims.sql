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
--                         kind is one of edit, move, merge, unmerge, hide.
--
-- 🔴 ROUTES DO NOT SUPPLY path, depth OR community_id ON A CHILD CLAIM.
-- Those three are facts about the parent, and section 4a derives them from it under a
-- row lock, discarding whatever the caller passed. A route inserting a child sends
-- community_id (ignored), parent_claim_id, side, body and author_id — or just the last
-- four. A route moving a claim sets parent_claim_id and side and nothing else; path,
-- depth and community_id follow. This is what Task 4 and Task 7 should be written
-- against. The one thing still owed by hand is the descendant sweep after a move: the
-- derivation fires for the claim whose own parent changed, not for its subtree.
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
-- COUNTS SURVIVE CONCURRENCY, MOVES AND DELETES
-- child_supports_count / child_opposes_count are bumped with count = count ± 1
-- inside the trigger's UPDATE — never read in one statement and written in
-- another — so two sessions inserting a child of the same parent serialize on the
-- parent's row lock and both land. The trigger also fires on a move
-- (UPDATE OF parent_claim_id, side): the OLD parent's OLD side decrements and the
-- NEW parent's NEW side increments, so counts self-correct instead of drifting
-- upward forever. Hiding a claim touches moderation_status only and is deliberately
-- NOT counted — a hidden claim is still a child, and the read API filters.
-- There is a DELETE branch too, even though nothing in the application may delete a
-- claim. postgres owns these tables and is exempt from every grant below, so the only
-- actor who can delete is the only actor the counts would silently break for. See the
-- comment above trg_claims_bump_child_counts_delete.
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

  -- No claim may be its own ancestor. claims_no_self_parent catches only the one-hop
  -- case; this catches every longer ring. Moving A under its own descendant D passes
  -- every other constraint here, and A.path then contains A — at which point Task 7's
  -- sweep (WHERE path @> ARRAY[A]) matches A itself, A and D become a detached ring
  -- unreachable from the root, and any WITH RECURSIVE walk over parent_claim_id loops
  -- forever. Task 7 still does its own check so the maven gets a 409 and a sentence;
  -- this is the backstop that makes the ring impossible rather than merely unlikely.
  -- Valid against all 44 live rows: every root has an empty path.
  CONSTRAINT claims_not_own_ancestor CHECK (NOT (path @> ARRAY[id])),
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

-- CA_0341 was already applied once, so CREATE TABLE IF NOT EXISTS above is a no-op on the
-- live database and its inline constraints would never reach it. Everything added after
-- the first apply therefore also appears here as a guarded ALTER. The inline forms are
-- what a fresh rebuild gets; these are what the live table gets. Keep the two in step.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conrelid = 'connect.claims'::regclass AND conname = 'claims_not_own_ancestor') THEN
    ALTER TABLE connect.claims
      ADD CONSTRAINT claims_not_own_ancestor CHECK (NOT (path @> ARRAY[id]));
  END IF;
END $$;

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
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id                 UUID NOT NULL REFERENCES connect.claims(id),
  actor_id                 UUID NOT NULL,   -- the real actor, from fc.actor_id; see header
  kind                     TEXT NOT NULL,
  old_body                 TEXT,
  old_parent_claim_id      UUID,
  old_side                 TEXT,
  old_merged_into_claim_id UUID,
  merge_target_claim_id    UUID,
  edited_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT claim_edits_kind_values CHECK (kind IN ('edit', 'move', 'merge', 'unmerge', 'hide'))
);

-- Added after the first apply; see the note above the claims ALTER block. claim_edits had
-- 0 rows when these columns were added, so there is no backfill and no partial history:
-- every row the table will ever hold carries them.
--
-- WHY old_side AND old_merged_into_claim_id EXIST
-- Without them two of the kinds record nothing about what actually changed. A side flip
-- under the same parent logged kind='move' with an UNCHANGED old_parent_claim_id, so the
-- history could not reconstruct a polarity inversion — in a pro/con tree, the edit that
-- most changes what a claim means. And undoing a merge (merged_into_claim_id back to
-- NULL) fell through to kind='edit' with an unchanged old_body, so the most consequential
-- curation action there is left a row that said nothing. Hence 'unmerge' as well.
ALTER TABLE connect.claim_edits ADD COLUMN IF NOT EXISTS old_side TEXT;
ALTER TABLE connect.claim_edits ADD COLUMN IF NOT EXISTS old_merged_into_claim_id UUID;
ALTER TABLE connect.claim_edits DROP CONSTRAINT IF EXISTS claim_edits_kind_values;
ALTER TABLE connect.claim_edits
  ADD CONSTRAINT claim_edits_kind_values CHECK (kind IN ('edit', 'move', 'merge', 'unmerge', 'hide'));

CREATE INDEX IF NOT EXISTS claim_edits_claim_idx
  ON connect.claim_edits (claim_id, edited_at DESC);

-- 4a. Position derivation. path, depth and community_id are NOT inputs — they are facts
--     about the parent, and the database works them out. Whatever a caller supplies in
--     those three columns is discarded.
--
-- WHY THIS EXISTS AT ALL
-- claims_root_or_child_shape validates a row against ITSELF: it proves depth matches
-- cardinality(path), not that either one has anything to do with the named parent. An
-- INSERT naming parent P while passing P's OWN path and depth satisfies every constraint
-- on the table, and the row then answers `path @> ARRAY[R]` but not `path @> ARRAY[P]` —
-- the subtree read and the parent read disagree about where that claim lives, forever,
-- and nothing ever notices. The same hole lets a child sit in a different community from
-- its parent.
--
-- WHY IT TAKES A ROW LOCK
-- It is also a race, not just a validation gap. T1 reads P to build a child; T2 moves P
-- under G and sweeps P's descendants; T1 then inserts using the path it read before the
-- move, and that child is absent from G's subtree forever. The count trigger's row lock
-- does not help — it fires AFTER, by which time T1's path is already decided. Locking the
-- parent row HERE, before the derivation, serializes against the mover: T1 blocks, and
-- when it wakes READ COMMITTED re-evaluates the lookup and hands it the post-move parent.
--
-- 🔴 FOR UPDATE, NOT FOR SHARE — this is deliberate and it matters.
-- FOR SHARE is the weaker, more obvious lock and it would DEADLOCK here. Two sessions
-- inserting children of the same parent would each take a shared lock on P, and each
-- would then need an exclusive lock on P when the AFTER-INSERT count trigger runs its
-- UPDATE. Neither can have it until the other commits: a textbook lock-upgrade deadlock,
-- and one of the two inserts dies. That is exactly the concurrent-insert property this
-- migration is supposed to guarantee. FOR UPDATE takes the stronger lock up front, so the
-- second session simply waits where it would have waited anyway — the count trigger
-- already holds P exclusively from its UPDATE until commit, so this costs no concurrency
-- that was ever available, and it removes the deadlock entirely.
--
-- WHAT THIS DOES NOT COVER
-- It fires on INSERT and on UPDATE OF parent_claim_id — a claim whose own parent changes.
-- It deliberately does NOT fire for Task 7's descendant sweep, which rewrites path and
-- depth for a moved claim's whole subtree without touching their parent_claim_id. Those
-- rows keep the values the sweep computes; that remains Task 7's to get right.
CREATE OR REPLACE FUNCTION connect.derive_claim_position()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'connect', 'pg_temp'
AS $fn$
DECLARE
  v_parent_path      UUID[];
  v_parent_depth     INT;
  v_parent_community UUID;
BEGIN
  IF NEW.parent_claim_id IS NULL THEN
    RETURN NEW;  -- a root: its position is its own, and its community is whatever created it
  END IF;

  SELECT path, depth, community_id
    INTO v_parent_path, v_parent_depth, v_parent_community
  FROM connect.claims
  WHERE id = NEW.parent_claim_id
  FOR UPDATE;   -- see the header above: NOT FOR SHARE

  IF NOT FOUND THEN
    RAISE EXCEPTION 'connect.derive_claim_position: parent claim % does not exist', NEW.parent_claim_id;
  END IF;

  NEW.path         := v_parent_path || NEW.parent_claim_id;  -- root-first, excluding self
  NEW.depth        := v_parent_depth + 1;
  NEW.community_id := v_parent_community;                    -- a child cannot leave its tree

  RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS trg_claims_derive_position ON connect.claims;
CREATE TRIGGER trg_claims_derive_position
BEFORE INSERT OR UPDATE OF parent_claim_id ON connect.claims
FOR EACH ROW
EXECUTE FUNCTION connect.derive_claim_position();

-- 4b. Display-name snapshot. The EXISTING generic function, with the WHEN clause that
--     keeps it away from the authorless roots (see header).
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
  -- OLD exists for UPDATE and DELETE; NEW exists for INSERT and UPDATE. Referencing the
  -- wrong one raises "record is not assigned yet" at runtime, and SQL gives no guarantee
  -- that AND short-circuits left to right — so the TG_OP guards are NESTED, never ANDed
  -- with the field test.
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    IF OLD.parent_claim_id IS NOT NULL THEN
      UPDATE connect.claims
         SET child_supports_count = child_supports_count - (COALESCE(OLD.side, '') = 'supports')::int,
             child_opposes_count  = child_opposes_count  - (COALESCE(OLD.side, '') = 'opposes')::int
       WHERE id = OLD.parent_claim_id;
    END IF;
  END IF;

  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    IF NEW.parent_claim_id IS NOT NULL THEN
      UPDATE connect.claims
         SET child_supports_count = child_supports_count + (COALESCE(NEW.side, '') = 'supports')::int,
             child_opposes_count  = child_opposes_count  + (COALESCE(NEW.side, '') = 'opposes')::int
       WHERE id = NEW.parent_claim_id;
    END IF;
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

-- 🔴 A DELETE branch on a table nothing is allowed to delete from is not dead code.
-- Section 8 takes DELETE away from every role a grant can reach, but postgres OWNS these
-- tables and is a superuser, so the one actor who CAN delete a claim is exactly the actor
-- the counts would silently break for — and a stale count is invisible, because it reads
-- as a legitimate number. Proven the hard way during review: probe rows were cleaned up
-- with DELETE as postgres and a root was left claiming a supporting child it no longer
-- had. The gate in section 9 now inserts a child, deletes it, and asserts the count
-- returns to zero, so this branch is checked rather than assumed.
DROP TRIGGER IF EXISTS trg_claims_bump_child_counts_delete ON connect.claims;
CREATE TRIGGER trg_claims_bump_child_counts_delete
AFTER DELETE ON connect.claims
FOR EACH ROW
WHEN (OLD.parent_claim_id IS NOT NULL)
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

  -- One UPDATE may do several things at once; the kind names the strongest of them:
  --   merge    merged_into_claim_id set to a claim        -- this claim is superseded
  --   unmerge  merged_into_claim_id cleared back to NULL  -- that supersession undone
  --   move     parent_claim_id or side changed            -- reparented, or polarity flipped
  --   hide     moderation_status changed                  -- withdrawn or restored
  --   edit     body changed and nothing above             -- a rewrite
  -- Every OLD value a logged column can carry is stored on every row whatever the kind,
  -- so one row is always enough to undo one edit.
  IF NEW.merged_into_claim_id IS DISTINCT FROM OLD.merged_into_claim_id
     AND NEW.merged_into_claim_id IS NOT NULL THEN
    v_kind := 'merge';
  ELSIF NEW.merged_into_claim_id IS DISTINCT FROM OLD.merged_into_claim_id
     AND NEW.merged_into_claim_id IS NULL THEN
    v_kind := 'unmerge';
  ELSIF NEW.parent_claim_id IS DISTINCT FROM OLD.parent_claim_id
     OR NEW.side IS DISTINCT FROM OLD.side THEN
    v_kind := 'move';
  ELSIF NEW.moderation_status IS DISTINCT FROM OLD.moderation_status THEN
    v_kind := 'hide';
  ELSE
    v_kind := 'edit';
  END IF;

  INSERT INTO connect.claim_edits
    (claim_id, actor_id, kind, old_body, old_parent_claim_id, old_side,
     old_merged_into_claim_id, merge_target_claim_id)
  VALUES
    (OLD.id, v_actor, v_kind, OLD.body, OLD.parent_claim_id, OLD.side,
     OLD.merged_into_claim_id,
     -- Only a merge has a merge target. Stamping NEW.merged_into_claim_id on every row
     -- meant that after C was merged into M, a LATER body edit by a different maven
     -- logged {kind:'edit', merge_target:M} — and from the history alone that second
     -- maven looked like the one who performed the merge.
     CASE WHEN v_kind = 'merge' THEN NEW.merged_into_claim_id END);

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

-- claim_edits is written by a SECURITY DEFINER trigger and by nothing else — and that
-- sentence has to be true of every role, not just the convenient ones. The connect
-- schema's ALTER DEFAULT PRIVILEGES (20260415214600) hands INSERT/UPDATE on every new
-- table in the schema to `authenticated` (arw), `service_role` (arwdDxtm) and `ev_api`
-- (arwd). RLS refuses `authenticated` and `anon` for want of a policy, but service_role
-- bypasses RLS entirely, so for it the grant is the only thing standing in the way.
-- The audit trail is what makes a maven's move, merge and hide accountable; a role that
-- can append to it directly can launder one.
-- This cannot break the trigger: log_claim_edit is SECURITY DEFINER owned by postgres,
-- which owns the table, so it writes regardless of the caller's grants.
REVOKE INSERT, UPDATE ON connect.claim_edits FROM authenticated;
REVOKE INSERT, UPDATE ON connect.claim_edits FROM service_role;
REVOKE INSERT, UPDATE ON connect.claim_edits FROM ev_api;
REVOKE INSERT, UPDATE ON connect.claim_edits FROM anon;

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
  v_priv        TEXT;
  v_trigdef     TEXT;
  v_probe_id          UUID;
  v_probe_well_shaped INT;
  v_probe_total       INT;
  v_probe_ok          BOOLEAN := false;
  v_probe_detail      TEXT;
  v_probe_root        UUID;
  v_probe_child_a     UUID;
  v_probe_child_b     UUID;
  v_probe_child_c     UUID;
  v_probe_count       INT;
  v_probe_count2      INT;
  -- A fixed, obviously synthetic actor. It is never committed (the probe unwinds), and
  -- it must not resemble a real account id in any log that catches a failure mid-probe.
  v_probe_actor       UUID := '00000000-0000-4341-8341-000000000341';
BEGIN
  -- a. RLS is on for all three.
  FOREACH v_tbl IN ARRAY ARRAY['claims', 'claim_ratings', 'claim_edits'] LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'connect' AND c.relname = v_tbl) THEN
      RAISE EXCEPTION 'CA_0341: RLS is not enabled on connect.%', v_tbl;
    END IF;
  END LOOP;

  -- b. The module's role can do exactly what it needs and no more.
  --
  -- 🔴 ONE CALL PER PRIVILEGE. has_table_privilege(role, table, 'SELECT,INSERT,UPDATE')
  -- is OR, not AND — it answers "any of these", so it returns true for a role holding
  -- SELECT alone. Verified live: has_table_privilege('anon','connect.claims',
  -- 'SELECT,INSERT,UPDATE') is true while anon holds only SELECT. Written the comma way,
  -- this check could never fail, and a change that left focused_communities_app with
  -- SELECT alone would 403 the write API in production behind a green migration log.
  -- CA_0323:109-112 has the same bug and is being raised separately.
  FOREACH v_priv IN ARRAY ARRAY['SELECT', 'INSERT', 'UPDATE'] LOOP
    FOREACH v_tbl IN ARRAY ARRAY['claims', 'claim_ratings'] LOOP
      IF NOT has_table_privilege('focused_communities_app', 'connect.' || v_tbl, v_priv) THEN
        RAISE EXCEPTION 'CA_0341: focused_communities_app is missing % on connect.%', v_priv, v_tbl;
      END IF;
    END LOOP;
  END LOOP;
  IF NOT has_table_privilege('focused_communities_app', 'connect.claim_edits', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0341: missing SELECT on connect.claim_edits';
  END IF;

  -- c. Two invariants, asserted from the other side for every role a grant can
  --    constrain. postgres owns the tables and is exempt by definition — it is the
  --    friction-free actor the DELETE branch of the count trigger exists for.
  --      * nothing in the argument tree is ever deleted;
  --      * claim_edits is written by the SECURITY DEFINER trigger and by nothing else,
  --        so no role may INSERT or UPDATE it directly. A role that can append to the
  --        audit trail can launder a move, a merge or a hide.
  FOREACH v_role IN ARRAY ARRAY['focused_communities_app', 'anon', 'authenticated', 'service_role', 'ev_api'] LOOP
    FOREACH v_tbl IN ARRAY ARRAY['claims', 'claim_ratings', 'claim_edits'] LOOP
      IF has_table_privilege(v_role, 'connect.' || v_tbl, 'DELETE') THEN
        RAISE EXCEPTION 'CA_0341: % can DELETE connect.% — nothing in the argument tree is ever deleted', v_role, v_tbl;
      END IF;
    END LOOP;

    IF has_table_privilege(v_role, 'connect.claim_edits', 'INSERT')
       OR has_table_privilege(v_role, 'connect.claim_edits', 'UPDATE') THEN
      RAISE EXCEPTION 'CA_0341: % can write connect.claim_edits directly — only the log_claim_edit trigger may, or the audit trail proves nothing', v_role;
    END IF;
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
        AND t.tgname IN ('trg_claims_derive_position',
                         'trg_claims_bump_child_counts_insert',
                         'trg_claims_bump_child_counts_move',
                         'trg_claims_bump_child_counts_delete',
                         'trg_log_claim_edit')) <> 5 THEN
    RAISE EXCEPTION 'CA_0341: the derivation, child-count and edit-log triggers are not all attached to connect.claims';
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

  -- i. ...and so does everything else. Reading pg_trigger proves a trigger exists, not
  --    that it does anything, and every bug found in this migration after it was first
  --    applied lived in a behaviour the gate had only asserted the EXISTENCE of. So the
  --    probe below builds a real community, a real root and three real children, and
  --    exercises derivation, all three count branches, both merge directions, the actor
  --    guard and the edit log against them.
  --
  --    HOW IT CLEANS UP. plpgsql opens an implicit subtransaction for any
  --    BEGIN...EXCEPTION block. Every exit from this one is a RAISE, so the subtransaction
  --    always aborts and every row the probe wrote is gone — including the GUC set by
  --    set_config(..., true), which is also rolled back. plpgsql variables are NOT
  --    transactional, so the verdict survives. Nothing is left behind whether the outer
  --    transaction commits or not, and nothing is DELETEd to achieve it.
  --
  --    HOW IT REPORTS. Two private SQLSTATEs rather than a chain of nested IFs:
  --      CA341 — reached the end, every assertion passed
  --      CA342 — an assertion failed; v_probe_detail says which
  --    v_probe_ok starts false and is set true only by the CA341 handler, so a probe that
  --    somehow exits any other way fails the gate rather than passing it.
  BEGIN
    ------------------------------------------------------------------ the root trigger
    INSERT INTO connect.communities (topic_id, slug, name)
    VALUES (gen_random_uuid(),
            'ca0341-probe-' || gen_random_uuid()::text,  -- slug is UNIQUE; never collide
            'CA_0341 probe')
    RETURNING id INTO v_probe_id;

    SELECT count(*) INTO v_probe_total
    FROM connect.claims WHERE community_id = v_probe_id;

    SELECT count(*) INTO v_probe_well_shaped
    FROM connect.claims
    WHERE community_id = v_probe_id
      AND parent_claim_id IS NULL
      AND side IS NULL
      AND author_id IS NULL
      AND author_display_name IS NULL   -- the WHEN guard held: no invented "Unknown"
      AND body = 'CA_0341 probe'        -- body is the community's name
      AND cardinality(path) = 0
      AND depth = 0
      AND moderation_status = 'visible'
      AND child_supports_count = 0
      AND child_opposes_count = 0;

    IF v_probe_total <> 1 OR v_probe_well_shaped <> 1 THEN
      v_probe_detail := format('the root-claim trigger produced %s claim(s) for a new community, %s of them a well-shaped root; expected 1 and 1',
                               v_probe_total, v_probe_well_shaped);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    SELECT id INTO v_probe_root FROM connect.claims WHERE community_id = v_probe_id;

    ------------------------------------------- derivation, and counts on INSERT
    -- Child A is inserted WITHOUT path or depth: the derivation trigger owes them.
    INSERT INTO connect.claims (community_id, parent_claim_id, side, body)
    VALUES (v_probe_id, v_probe_root, 'supports', 'CA_0341 probe child A')
    RETURNING id INTO v_probe_child_a;

    IF NOT EXISTS (SELECT 1 FROM connect.claims
                   WHERE id = v_probe_child_a
                     AND path = ARRAY[v_probe_root] AND depth = 1 AND community_id = v_probe_id) THEN
      SELECT format('derivation on INSERT gave path=%s depth=%s community=%s, expected path={%s} depth=1 community=%s',
                    path, depth, community_id, v_probe_root, v_probe_id)
        INTO v_probe_detail FROM connect.claims WHERE id = v_probe_child_a;
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    -- Child B is inserted WITH hostile values in all three derived columns — a stale
    -- path, a wrong depth and someone else's community. All three must be discarded.
    INSERT INTO connect.claims (community_id, parent_claim_id, side, body, path, depth)
    VALUES ((SELECT id FROM connect.communities WHERE id <> v_probe_id LIMIT 1),
            v_probe_root, 'supports', 'CA_0341 probe child B',
            ARRAY[gen_random_uuid()], 97)
    RETURNING id INTO v_probe_child_b;

    IF NOT EXISTS (SELECT 1 FROM connect.claims
                   WHERE id = v_probe_child_b
                     AND path = ARRAY[v_probe_root] AND depth = 1 AND community_id = v_probe_id) THEN
      SELECT format('derivation did not discard caller-supplied values: path=%s depth=%s community=%s',
                    path, depth, community_id)
        INTO v_probe_detail FROM connect.claims WHERE id = v_probe_child_b;
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    INSERT INTO connect.claims (community_id, parent_claim_id, side, body)
    VALUES (v_probe_id, v_probe_root, 'opposes', 'CA_0341 probe child C')
    RETURNING id INTO v_probe_child_c;

    SELECT child_supports_count, child_opposes_count INTO v_probe_count, v_probe_count2
    FROM connect.claims WHERE id = v_probe_root;
    IF v_probe_count <> 2 OR v_probe_count2 <> 1 THEN
      v_probe_detail := format('after two supporting and one opposing child the root reads (%s, %s), expected (2, 1)',
                               v_probe_count, v_probe_count2);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    ------------------------------------------- counts on MOVE, and the edit log
    PERFORM set_config('fc.actor_id', v_probe_actor::text, true);

    -- B moves from the root to A and flips polarity in the same statement: the OLD
    -- parent's OLD side must debit and the NEW parent's NEW side must credit.
    UPDATE connect.claims
       SET parent_claim_id = v_probe_child_a, side = 'opposes'
     WHERE id = v_probe_child_b;

    SELECT child_supports_count, child_opposes_count INTO v_probe_count, v_probe_count2
    FROM connect.claims WHERE id = v_probe_root;
    IF v_probe_count <> 1 OR v_probe_count2 <> 1 THEN
      v_probe_detail := format('after moving one supporting child away the root reads (%s, %s), expected (1, 1)',
                               v_probe_count, v_probe_count2);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    SELECT child_supports_count, child_opposes_count INTO v_probe_count, v_probe_count2
    FROM connect.claims WHERE id = v_probe_child_a;
    IF v_probe_count <> 0 OR v_probe_count2 <> 1 THEN
      v_probe_detail := format('after receiving one opposing child the new parent reads (%s, %s), expected (0, 1)',
                               v_probe_count, v_probe_count2);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    -- The move must have re-derived B's position under its new parent.
    IF NOT EXISTS (SELECT 1 FROM connect.claims
                   WHERE id = v_probe_child_b
                     AND path = ARRAY[v_probe_root, v_probe_child_a] AND depth = 2) THEN
      SELECT format('after the move the child reads path=%s depth=%s, expected {%s,%s} and 2',
                    path, depth, v_probe_root, v_probe_child_a)
        INTO v_probe_detail FROM connect.claims WHERE id = v_probe_child_b;
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    -- ...and logged it as a move, against the ACTOR, not the claim's author.
    IF NOT EXISTS (SELECT 1 FROM connect.claim_edits
                   WHERE claim_id = v_probe_child_b AND kind = 'move'
                     AND actor_id = v_probe_actor
                     AND old_parent_claim_id = v_probe_root
                     AND old_side = 'supports'
                     AND merge_target_claim_id IS NULL) THEN
      v_probe_detail := 'the move produced no claim_edits row with kind=move, the actor from fc.actor_id, the old parent, the old side and a null merge target';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    ------------------------------------------- merge, unmerge, and a plain edit
    UPDATE connect.claims SET merged_into_claim_id = v_probe_child_c WHERE id = v_probe_child_b;
    IF NOT EXISTS (SELECT 1 FROM connect.claim_edits
                   WHERE claim_id = v_probe_child_b AND kind = 'merge'
                     AND merge_target_claim_id = v_probe_child_c
                     AND old_merged_into_claim_id IS NULL) THEN
      v_probe_detail := 'setting merged_into_claim_id did not log kind=merge with the merge target';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    UPDATE connect.claims SET merged_into_claim_id = NULL WHERE id = v_probe_child_b;
    IF NOT EXISTS (SELECT 1 FROM connect.claim_edits
                   WHERE claim_id = v_probe_child_b AND kind = 'unmerge'
                     AND old_merged_into_claim_id = v_probe_child_c
                     AND merge_target_claim_id IS NULL) THEN
      v_probe_detail := 'clearing merged_into_claim_id did not log kind=unmerge naming the merge it undid';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    -- A plain body edit, well after the merge: it must NOT inherit the merge target, or
    -- this maven reads as the one who performed the merge.
    UPDATE connect.claims SET body = 'CA_0341 probe child B, rewritten' WHERE id = v_probe_child_b;
    IF NOT EXISTS (SELECT 1 FROM connect.claim_edits
                   WHERE claim_id = v_probe_child_b AND kind = 'edit'
                     AND actor_id = v_probe_actor
                     AND old_body = 'CA_0341 probe child B'
                     AND merge_target_claim_id IS NULL) THEN
      v_probe_detail := 'a plain body edit after a merge did not log kind=edit with the old body and a NULL merge target';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    ------------------------------------------- the actor guard
    -- Cleared, not absent: current_setting returns '' rather than NULL, and both must
    -- be refused. An edit nobody is accountable for is not an edit this table accepts.
    PERFORM set_config('fc.actor_id', '', true);
    BEGIN
      UPDATE connect.claims SET body = 'CA_0341 probe unattributed' WHERE id = v_probe_child_b;
      v_probe_detail := 'an UPDATE with fc.actor_id cleared was allowed through — log_claim_edit did not refuse an unattributed edit';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    EXCEPTION
      WHEN raise_exception THEN
        NULL;  -- expected: log_claim_edit raised. CA342 is a different SQLSTATE and escapes.
    END;
    PERFORM set_config('fc.actor_id', v_probe_actor::text, true);

    ------------------------------------------- counts on DELETE
    -- The branch that exists for postgres alone. C was never edited, so it carries no
    -- claim_edits row and its delete meets no foreign key.
    DELETE FROM connect.claims WHERE id = v_probe_child_c;

    SELECT child_supports_count, child_opposes_count INTO v_probe_count, v_probe_count2
    FROM connect.claims WHERE id = v_probe_root;
    IF v_probe_count <> 1 OR v_probe_count2 <> 0 THEN
      v_probe_detail := format('deleting the opposing child left the root at (%s, %s), expected (1, 0) — the AFTER DELETE branch did not fire',
                               v_probe_count, v_probe_count2);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA342';
    END IF;

    -- Every assertion passed. Abort anyway: this is how the probe cleans up after itself.
    RAISE EXCEPTION 'CA_0341 probe rollback' USING ERRCODE = 'CA341';
  EXCEPTION
    WHEN SQLSTATE 'CA341' THEN
      v_probe_ok := true;
    WHEN SQLSTATE 'CA342' THEN
      v_probe_ok := false;   -- v_probe_detail already names the failure
  END;

  IF NOT v_probe_ok THEN
    RAISE EXCEPTION 'CA_0341: the behavioural probe failed — %',
      COALESCE(v_probe_detail, 'the probe did not run to completion');
  END IF;

  -- Belt and braces across all three tables the probe touched, including the edit rows
  -- it made for child B. A future change that breaks the unwind must not pass quietly.
  IF EXISTS (SELECT 1 FROM connect.communities WHERE id = v_probe_id)
     OR EXISTS (SELECT 1 FROM connect.claims WHERE community_id = v_probe_id)
     OR EXISTS (SELECT 1 FROM connect.claim_edits
                WHERE claim_id IN (v_probe_root, v_probe_child_a, v_probe_child_b, v_probe_child_c)
                   OR actor_id = v_probe_actor) THEN
    RAISE EXCEPTION 'CA_0341: the behavioural probe left rows behind — the subtransaction did not unwind';
  END IF;

  RAISE NOTICE 'CA_0341 OK — connect.claims / claim_ratings / claim_edits created, RLS on, scoped to focused_communities_app (no role but the owner can DELETE any of the three or write claim_edits), % root claims backfilled. Probe verified, then rolled back: the root-claim trigger, path/depth/community derivation on insert and on move (including discarding hostile caller values), child counts on insert, move and delete, the edit log for move, merge, unmerge and edit with the real actor and no inherited merge target, and the refusal of an edit with fc.actor_id cleared.', v_roots;
END $$;

COMMIT;

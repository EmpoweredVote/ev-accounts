BEGIN;

-- =============================================================================
-- CA_0344: a depth ceiling on connect.claims
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews. Task 4 fix round 2 (review finding R35).
--
-- WHAT THIS DOES
-- Adds one CHECK constraint: connect.claims.depth <= 50.
--
-- WHY 50
-- A Kialo-style debate runs 8-10 levels. 50 is far past any legitimate use while
-- bounding the breadcrumb a claim read has to build to about 50 rows, rather than
-- the half-megabyte response a depth-500 claim would produce — and that response is
-- served to anonymous readers as `public, s-maxage=30`, so one pathological claim
-- would be cached and re-served rather than merely computed once.
--
-- Erring high is the cheap direction. Raising this cap later is a one-constant change
-- in src/focused_communities/lib/utils.ts plus a relaxed CHECK, with no data migration.
-- LOWERING one orphans rows that already exist, which is why the number is generous
-- rather than snug.
--
-- 🔴 WHY A CONSTRAINT AND NOT ONLY A ROUTE CHECK
-- routes/claimWrites.ts already answers 422 when the parent is at the cap, and that is
-- the check a contributor sees. It is not the one that BINDS. `postgres` is exempt from
-- every grant and every policy in CA_0323 and CA_0341, so a psql session, a future
-- migration, or a maven tool running as the owner can deepen the tree past any number a
-- route knows about. Only a CHECK constraint is in the way of all of them. This is the
-- same reasoning that put the DELETE branch on connect.bump_claim_child_counts in
-- CA_0341 (review finding R14): the grant says DELETE cannot happen, and the trigger
-- handles it anyway, because `postgres` is not bound by the grant.
--
-- THE THIRD ENFORCEMENT POINT
-- Three places agree on this number and all three are needed:
--   (a) routes/claimWrites.ts  — 422 before the write, so a contributor gets a sentence
--   (b) routes/claims.ts       — LIMIT on the breadcrumb query, so a read stays bounded
--                                whatever the table turns out to hold
--   (c) this constraint        — so nothing, including the owner, can get past it
-- MAX_CLAIM_DEPTH in src/focused_communities/lib/utils.ts is the single constant (a) and
-- (b) share; this file is the copy that lives in the database. Change all three together.
--
-- WHAT THIS ENABLES LATER
-- Task 7's move must reject a move that would push a subtree past the cap. With this in
-- place it FAILS LOUDLY on the attempt instead of silently deepening the tree, which is
-- the point of putting the number somewhere a route cannot route around.
--
-- SAFE ON LIVE DATA
-- At the time of writing connect.claims holds 61 rows, every one of them a root at
-- depth 0 (one per community, seeded by CA_0341 §7 and CA_0342). Maximum depth live is
-- 0 and nothing is within 50 levels of the cap, so this constraint validates against the
-- existing table without rewriting or rejecting a single row. Section 2 proves that
-- rather than asserting it.
--
-- REVERSIBILITY
-- ALTER TABLE connect.claims DROP CONSTRAINT claims_depth_within_cap;
-- No data is changed by this migration, so dropping it restores the previous state exactly.

-- 1. The constraint.
--
-- Guarded, because the house style in CA_0341 is that re-running a migration is a no-op
-- rather than an error: an unguarded ADD CONSTRAINT raises 42710 on the second apply.
-- depth is NOT NULL (CA_0341 §1), so there is no NULL case to admit here.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'connect.claims'::regclass
       AND conname = 'claims_depth_within_cap'
  ) THEN
    ALTER TABLE connect.claims
      ADD CONSTRAINT claims_depth_within_cap CHECK (depth <= 50);
  END IF;
END $$;

COMMENT ON CONSTRAINT claims_depth_within_cap ON connect.claims IS
  'Argument tree depth ceiling (CA_0344). Mirrors MAX_CLAIM_DEPTH in '
  'src/focused_communities/lib/utils.ts, which routes/claimWrites.ts and routes/claims.ts '
  'both read. Raising it means changing the constant and this constraint together.';

-- 2. Post-verify gate.
--
-- Proves three things and ROLLS THE WHOLE MIGRATION BACK if any of them fails: that the
-- constraint is really there, that it was validated against the rows that already exist,
-- and that it actually BITES. A constraint nobody has tested is a comment with extra
-- syntax, so the third one is a real refused write, in CA_0341 §9's style, not a lookup
-- in pg_constraint.
DO $$
DECLARE
  v_convalidated BOOLEAN;
  v_max_depth    INT;
  v_over_cap     BIGINT;
  v_root         UUID;
  v_child        UUID;
  v_constraint   TEXT;
  v_probe_ok     BOOLEAN := FALSE;
  v_probe_detail TEXT;
BEGIN
  -- (a) It exists, and it is VALIDATED rather than NOT VALID — i.e. every existing row
  --     was checked, not merely every future one.
  SELECT convalidated INTO v_convalidated
    FROM pg_constraint
   WHERE conrelid = 'connect.claims'::regclass
     AND conname = 'claims_depth_within_cap';

  IF v_convalidated IS NULL THEN
    RAISE EXCEPTION 'CA_0344 gate: constraint claims_depth_within_cap does not exist';
  END IF;
  IF NOT v_convalidated THEN
    RAISE EXCEPTION 'CA_0344 gate: claims_depth_within_cap exists but is NOT VALID — the rows already in the table were never checked';
  END IF;

  -- (b) No existing row violates it. Implied by (a), and stated anyway because this is
  --     the number a future reader will want to find in the log.
  SELECT coalesce(max(depth), 0), count(*) FILTER (WHERE depth > 50)
    INTO v_max_depth, v_over_cap
    FROM connect.claims;

  IF v_over_cap > 0 THEN
    RAISE EXCEPTION 'CA_0344 gate: % existing claim(s) are deeper than the cap', v_over_cap;
  END IF;

  -- (c) It BITES.
  --
  -- 🔴 WHY THE PROBE IS AN UPDATE OF A CHILD AND NOT AN INSERT OF A ROOT.
  -- The obvious probe — INSERT a root with depth 51 — tests the wrong thing three times
  -- over. A root at depth 51 violates claims_root_or_child_shape (a root must be depth 0)
  -- and collides with claims_one_root_per_community, so it would be refused whether or
  -- not THIS constraint exists, and the gate would pass on a migration that did nothing.
  -- A child cannot be inserted over-cap either, because CA_0341 §4a derives depth from
  -- the parent and discards what the statement supplies.
  --
  -- So: insert a legitimate child (the trigger puts it at depth 1), then UPDATE it to
  -- depth 51 with a matching 51-element path. That row satisfies every other constraint —
  -- parent and side are set, depth > 0, cardinality(path) = depth, and the path holds
  -- fresh uuids so claims_not_own_ancestor is untouched — which leaves exactly one reason
  -- it can be refused. The UPDATE touches neither parent_claim_id (so the derivation
  -- trigger stays out of it) nor body/side/merge/moderation (so log_claim_edit does not
  -- fire and demand an actor).
  --
  -- The whole probe lives inside a block with an EXCEPTION clause, which is a
  -- subtransaction: when the expected failure is caught, the child insert that preceded
  -- it is rolled back with it, and the parent's child_supports_count with that. Nothing
  -- survives the probe, which section (d) then proves rather than assumes.
  SELECT id INTO v_root FROM connect.claims WHERE parent_claim_id IS NULL LIMIT 1;
  IF v_root IS NULL THEN
    RAISE EXCEPTION 'CA_0344 gate: no root claim to probe against';
  END IF;

  BEGIN
    INSERT INTO connect.claims (parent_claim_id, side, body)
    VALUES (v_root, 'supports', 'CA_0344 gate probe')
    RETURNING id INTO v_child;

    UPDATE connect.claims
       SET depth = 51,
           path  = (SELECT array_agg(gen_random_uuid()) FROM generate_series(1, 51))
     WHERE id = v_child;

    -- Only reachable if the UPDATE was ACCEPTED, which is the failure this gate exists for.
    v_probe_detail := 'a claim was moved to depth 51 and the table accepted it — claims_depth_within_cap does not bite';
    RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA345';
  EXCEPTION
    WHEN check_violation THEN
      GET STACKED DIAGNOSTICS v_constraint = CONSTRAINT_NAME;
      IF v_constraint = 'claims_depth_within_cap' THEN
        v_probe_ok := TRUE;
      ELSE
        -- Refused, but by something else — so this gate proved nothing about the new
        -- constraint. Name the one that actually fired rather than passing quietly.
        v_probe_detail := format('the over-cap UPDATE was refused by %s, not claims_depth_within_cap', v_constraint);
      END IF;
    WHEN SQLSTATE 'CA345' THEN
      NULL;  -- v_probe_detail already names the failure
  END;

  IF NOT v_probe_ok THEN
    RAISE EXCEPTION 'CA_0344: the behavioural probe failed — %',
      COALESCE(v_probe_detail, 'the probe did not run to completion');
  END IF;

  -- (d) Belt and braces: the probe unwound completely. A future change that breaks the
  --     unwind must not pass quietly, and least of all leave a stray claim in a real
  --     community's tree.
  IF EXISTS (SELECT 1 FROM connect.claims WHERE body = 'CA_0344 gate probe') THEN
    RAISE EXCEPTION 'CA_0344 gate: the probe claim survived — the subtransaction did not unwind';
  END IF;

  RAISE NOTICE 'CA_0344 gate PASSED: claims_depth_within_cap exists, is validated and refuses an over-cap row; % claims live, deepest is %, cap is 50',
    (SELECT count(*) FROM connect.claims), v_max_depth;
END $$;

COMMIT;

BEGIN;

-- =============================================================================
-- CA_0345: impact — the rating aggregate, stored on connect.claims
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews. Task 5 of the argument-tree build
-- (rulings R37, R38, R39).
--
-- WHAT THIS DOES
-- Adds three columns to connect.claims and one trigger to connect.claim_ratings:
--
--   rating_count INT NOT NULL DEFAULT 0   how many people have rated this claim
--   rating_sum   INT NOT NULL DEFAULT 0   the total of their 1-9 values
--   impact       NUMERIC GENERATED        the Bayesian-weighted mean, derived
--
--   trg_claim_ratings_bump_aggregate_{insert,update,delete}
--     keeps the first two in step with connect.claim_ratings.
--
-- plus the composite index the column read's ORDER BY walks, and the grant check
-- for the module's role.
--
-- CA_0341 created connect.claim_ratings but gave connect.claims nowhere to keep the
-- aggregate. Verified live before writing this: connect.claims had no impact and no
-- rating_count column, and connect.claim_ratings holds 0 rows across 61 claims.
--
-- -----------------------------------------------------------------------------
-- WHY A STORED COLUMN AND NOT A JOIN (R37)
-- -----------------------------------------------------------------------------
-- Two readers make a read-time aggregate the wrong shape:
--
--   * routes/claims.ts orders each child column by
--       ORDER BY c.impact DESC NULLS LAST, c.created_at DESC, c.id DESC
--     under keyset pagination. Keyset paging needs an index the planner can WALK; an
--     aggregate computed per request turns every page of a 500-child column into a sort
--     over the whole child set.
--   * GET /communities/:id/claims/shape returns impact for up to 2000 nodes in one
--     response, on every community page view.
--
-- The trade this makes, stated rather than discovered: WRITES GET SLOWER SO READS STAY
-- SUB-LINEAR. Every rating now updates a row of connect.claims, recomputes the generated
-- column, and moves an entry in claims_column_order_idx (an indexed column changing also
-- costs the UPDATE its HOT-update path). That is the right direction for a tree that is
-- read far more often than it is rated.
--
-- -----------------------------------------------------------------------------
-- WHY THE TRIGGER KEEPS TWO FACTS AND THE COLUMN DERIVES THE MEAN (R38)
-- -----------------------------------------------------------------------------
-- The trigger could compute the Bayesian mean itself. It must not, for three reasons:
--
--   1. The formula then lives in exactly one place. A trigger that stored a mean would
--      have to be mirrored by whatever recomputes it, and routes/claims.ts would have a
--      second copy in TypeScript for the cursor. One expression, three readers.
--   2. The trigger stays arithmetic nobody has to re-derive: count +/- 1, sum +/- value.
--   3. THE RAW SUM AND COUNT SURVIVE A CHANGE OF FORMULA. Revise the prior weight and
--      every historical impact recomputes itself when the generated expression is
--      replaced — no backfill, no window where the column is wrong. A stored mean would
--      need the ratings re-read, which is exactly the scan this column exists to avoid.
--
-- This is idiomatic here: inform.compass_topics.is_active is already
-- GENERATED ALWAYS AS (is_live) STORED.
--
-- -----------------------------------------------------------------------------
-- THE NUMBERS IN THE EXPRESSION, AND WHY THEY ARE LITERALS
-- -----------------------------------------------------------------------------
-- A generated expression must be IMMUTABLE, so it cannot read a settings table. Both
-- constants are therefore written into the expression and named here:
--
--   IMPACT_NEUTRAL       = 5   the midpoint of the 1-9 rating range
--   IMPACT_PRIOR_WEIGHT  = 5   five phantom neutral raters
--
--   impact = round( (IMPACT_PRIOR_WEIGHT * IMPACT_NEUTRAL + rating_sum)
--                   / (IMPACT_PRIOR_WEIGHT + rating_count), 4 )
--
-- WHY 5 AND NOT 1. The case this has to pass is the brief's: a single enthusiastic 9 must
-- not outrank a well-supported 7. The arithmetic, computed on this database:
--
--   weight   one 9                      twenty 7s                  verdict
--   ------   ------------------------   ------------------------   ---------------------
--   1        (1*5 + 9)/(1+1)  = 7.0000  (1*5 + 140)/(1+20) = 6.9048  single 9 WINS - wrong
--   5        (5*5 + 9)/(5+1)  = 5.6667  (5*5 + 140)/(5+20) = 6.6000  0.93 of margin - right
--
-- Weight 1 is not an option. 5 passes with room and is the value this migration uses;
-- CA_0345's gate re-runs that exact comparison against the real table rather than
-- trusting the arithmetic above.
--
-- WHY round(..., 4). Without it, numeric division yields ~16 fractional digits
-- (34/6 = 5.6666666666666667). node-postgres hands NUMERIC to JavaScript as a string, and
-- routes/claims.ts turns it into a Number for the response AND writes it into the keyset
-- cursor it later compares back against this column. A 4-decimal value in [1, 9] has five
-- significant digits, so it round-trips through a float64 and back to its shortest string
-- EXACTLY; sixteen digits would not, and the cursor would land between two rows. Four
-- decimals is also far more precision than a 1-9 impact bar can show.
-- round(numeric, integer) is IMMUTABLE (provolatile = 'i', verified live), so it is legal
-- in a generated expression.
--
-- 🔴 IMPACT IS NOT NULL, AND THAT IS THE POINT OF THE PRIOR.
-- An unrated claim reads 25/5 = 5.0000 — dead neutral — not NULL. That is what makes the
-- ordering sane: a claim carrying one rating of 1 scores (25+1)/6 = 4.3333 and correctly
-- sorts BELOW an untouched claim, which a null-means-unrated scheme could not express.
-- The column is declared NOT NULL so nothing can quietly reintroduce the other reading.
-- routes/claims.ts still writes DESC NULLS LAST, which is the ordering the Task 2 design
-- note settled on; against a NOT NULL column the clause is a no-op, kept so the SQL and
-- that note cannot be read as disagreeing.
--
-- -----------------------------------------------------------------------------
-- WHY THE TRIGGER CARRIES A DELETE BRANCH (R39, and CA_0341's R14)
-- -----------------------------------------------------------------------------
-- Section 8 of CA_0341 takes DELETE on connect.claim_ratings away from every role a grant
-- can reach. `postgres` owns the table and is exempt from all of it — so the one actor who
-- CAN delete a rating is exactly the actor a missing DELETE branch would silently corrupt
-- the aggregate for, and a stale impact is invisible because it reads as a legitimate
-- number. This has already happened once in this plan: a probe cleanup by DELETE left a
-- root claiming a child it no longer had. The gate below deletes a rating and asserts the
-- aggregate returns, so the branch is checked rather than assumed.
--
-- 🔴 THE TG_OP GUARDS ARE NESTED, NOT AND-CHAINED, matching
-- connect.bump_claim_child_counts(). SQL gives no guarantee that AND short-circuits left
-- to right, and NEW is unassigned on DELETE: `TG_OP <> 'DELETE' AND NEW.claim_id ...` is a
-- runtime "record is not assigned yet" waiting to happen.
--
-- -----------------------------------------------------------------------------
-- WHAT THIS MIGRATION DELIBERATELY DOES NOT DO
-- -----------------------------------------------------------------------------
--   * It does not weight by rater_account_age_days or rater_verification_status. Those
--     columns are written at rating time (routes/claimWrites.ts) because they cannot be
--     reconstructed afterwards, and the aggregate ignores them for now. Changing the
--     formula later is an ALTER of the generated expression; see reason 3 above.
--   * It adds no grant. CA_0341 already granted SELECT, INSERT, UPDATE on connect.claims
--     to focused_communities_app AT TABLE LEVEL, which covers columns added afterwards.
--     A table-level grant cannot be partially revoked — REVOKE UPDATE (rating_count) is a
--     no-op with a warning — so the role nominally holds UPDATE on the two count columns
--     exactly as it already does on child_supports_count. What keeps them correct is the
--     trigger plus the fact that no route names them in an UPDATE, which is the same
--     answer CA_0341 settled on for the child counts.
--   * It adds no DELETE anywhere. Nothing in the argument tree is ever deleted.
--
-- SAFE ON LIVE DATA
-- connect.claim_ratings holds 0 rows and connect.claims 61, every one of them a seeded
-- root. So rating_count = 0 and rating_sum = 0 are correct for every existing row with no
-- backfill, and section 5(d) proves that rather than asserting it. Adding the STORED
-- generated column rewrites the table; at 61 rows that is instant.
--
-- REVERSIBILITY
--   DROP TRIGGER trg_claim_ratings_bump_aggregate_insert ON connect.claim_ratings;
--   DROP TRIGGER trg_claim_ratings_bump_aggregate_update ON connect.claim_ratings;
--   DROP TRIGGER trg_claim_ratings_bump_aggregate_delete ON connect.claim_ratings;
--   DROP FUNCTION connect.bump_claim_rating_aggregate();
--   DROP INDEX connect.claims_column_order_idx;
--   ALTER TABLE connect.claims DROP COLUMN impact, DROP COLUMN rating_sum,
--                              DROP COLUMN rating_count;
-- No row of connect.claim_ratings is read or written by this migration outside the probe,
-- so dropping the above restores the previous state exactly.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change and lets a
-- DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 0. Preconditions. This migration extends CA_0341's tables; it does not create them.
DO $$
BEGIN
  IF to_regclass('connect.claims') IS NULL OR to_regclass('connect.claim_ratings') IS NULL THEN
    RAISE EXCEPTION 'CA_0345: connect.claims and connect.claim_ratings must exist — apply CA_0341 first';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conrelid = 'connect.claim_ratings'::regclass
                   AND conname = 'claim_ratings_one_per_user') THEN
    RAISE EXCEPTION 'CA_0345: claim_ratings_one_per_user is missing — the upsert in routes/claimWrites.ts and the one-rating-per-person invariant both depend on it';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conrelid = 'connect.claim_ratings'::regclass
                   AND conname = 'claim_ratings_value_range') THEN
    RAISE EXCEPTION 'CA_0345: claim_ratings_value_range is missing — rating_sum BETWEEN rating_count AND 9*rating_count below assumes every value is 1-9';
  END IF;
END $$;

-- 1. The two facts the trigger maintains.
--
-- NOT NULL DEFAULT 0 on an existing table is a fast default in Postgres 11+ — no rewrite,
-- and correct for every existing row because connect.claim_ratings is empty.
ALTER TABLE connect.claims
  ADD COLUMN IF NOT EXISTS rating_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rating_sum   INT NOT NULL DEFAULT 0;

-- The bounds the trigger's arithmetic must stay inside, so a lost or double-applied
-- increment is refused at the moment it happens rather than found later in a bad average.
-- Every rating is 1-9 (claim_ratings_value_range), so n ratings sum to between n and 9n —
-- which also pins count and sum to each other, catching a branch that moved one and not
-- the other. Both sides hold at (0, 0).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                 WHERE conrelid = 'connect.claims'::regclass
                   AND conname = 'claims_rating_totals_coherent') THEN
    ALTER TABLE connect.claims
      ADD CONSTRAINT claims_rating_totals_coherent
      CHECK (rating_count >= 0 AND rating_sum BETWEEN rating_count AND 9 * rating_count);
  END IF;
END $$;

-- 2. impact — derived, never written.
--
-- 🔴 THE TWO FIVES ARE DIFFERENT CONSTANTS. The first is IMPACT_PRIOR_WEIGHT (five
-- phantom raters), the second is IMPACT_NEUTRAL (the midpoint of the 1-9 range). They are
-- written out rather than folded into 25 so that changing one does not silently change
-- the other. See the header for the arithmetic that chose the weight.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_attribute
                 WHERE attrelid = 'connect.claims'::regclass
                   AND attname = 'impact' AND NOT attisdropped) THEN
    ALTER TABLE connect.claims
      ADD COLUMN impact NUMERIC
        GENERATED ALWAYS AS (
          round((5 * 5 + rating_sum)::numeric / (5 + rating_count), 4)
        ) STORED NOT NULL;
  END IF;
END $$;

COMMENT ON COLUMN connect.claims.impact IS
  'Bayesian-weighted mean of connect.claim_ratings.value, pulled toward the neutral '
  'midpoint while the sample is small: round((W*N + rating_sum)/(W + rating_count), 4) '
  'with W = IMPACT_PRIOR_WEIGHT = 5 and N = IMPACT_NEUTRAL = 5 (CA_0345). Never NULL: an '
  'unrated claim reads 5.0000. Derived — write rating_count and rating_sum, never this.';

-- 3. The index the column read walks.
--
-- routes/claims.ts serves one parent''s children, one side at a time, ordered by
--   impact DESC NULLS LAST, created_at DESC, id DESC
-- with a keyset predicate in exactly those keys. claims_community_parent_idx
-- (community_id, parent_claim_id) can find the children but not deliver them in that
-- order, so without this the planner sorts the whole child set on every page — which is
-- the cost R37's stored column was chosen to avoid, so leaving the index out would make
-- the column pointless. The NULLS LAST / DESC spellings MATCH THE ORDER BY EXACTLY; a
-- mismatched nulls ordering is not an index the planner can use for sorting, even though
-- impact is NOT NULL and the clause never bites.
--
-- claims_community_parent_idx is left in place: it is cheaper for the shape read's
-- `WHERE community_id = $1` and for Task 7's parent lookups, and dropping an index CA_0341
-- chose is not this migration's call.
CREATE INDEX IF NOT EXISTS claims_column_order_idx
  ON connect.claims (community_id, parent_claim_id, side,
                     impact DESC NULLS LAST, created_at DESC, id DESC);

-- 4. The trigger. An insert credits; a delete debits; an update does both, which also
--    covers the one-person-changes-their-mind case the route's upsert produces.
CREATE OR REPLACE FUNCTION connect.bump_claim_rating_aggregate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'connect', 'pg_temp'
AS $fn$
BEGIN
  -- OLD exists for UPDATE and DELETE; NEW exists for INSERT and UPDATE. Referencing the
  -- wrong one raises "record is not assigned yet" at runtime, and SQL gives no guarantee
  -- that AND short-circuits left to right — so the TG_OP guards are NESTED, never ANDed
  -- with the field test. Copied in shape from connect.bump_claim_child_counts().
  --
  -- No IS NOT NULL guard inside either branch: claim_id and value are both NOT NULL on
  -- connect.claim_ratings, unlike parent_claim_id on connect.claims.
  IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    UPDATE connect.claims
       SET rating_count = rating_count - 1,
           rating_sum   = rating_sum - OLD.value
     WHERE id = OLD.claim_id;
  END IF;

  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE connect.claims
       SET rating_count = rating_count + 1,
           rating_sum   = rating_sum + NEW.value
     WHERE id = NEW.claim_id;
  END IF;

  RETURN NULL;  -- AFTER trigger: the return value is ignored.
END;
$fn$;

-- Three triggers, one function, for CA_0341's reason: a WHEN clause may not mention OLD
-- on a trigger whose event list includes INSERT, so the branches are declared apart.
--
-- 🔴 These UPDATE connect.claims and therefore brush past its own triggers. They are safe
-- by construction and this is why:
--   * trg_log_claim_edit fires WHEN body, parent_claim_id, side, merged_into_claim_id or
--     moderation_status changed. None of those is touched here, so log_claim_edit does NOT
--     run — which matters, because it RAISES when fc.actor_id is unset and a reader rating
--     a claim sets no actor. Section 5(f) proves a rating writes no claim_edits row.
--   * trg_claims_bump_child_counts_move fires only on UPDATE OF parent_claim_id, side.
--   * trg_claims_derive_position fires BEFORE UPDATE OF parent_claim_id.
-- Adding a column to any of those WHEN clauses would make rating a claim fail; the gate
-- below is what would tell you.
DROP TRIGGER IF EXISTS trg_claim_ratings_bump_aggregate_insert ON connect.claim_ratings;
CREATE TRIGGER trg_claim_ratings_bump_aggregate_insert
AFTER INSERT ON connect.claim_ratings
FOR EACH ROW
EXECUTE FUNCTION connect.bump_claim_rating_aggregate();

-- UPDATE OF value, claim_id and not merely value: a rating moved to another claim has to
-- debit the old one. Nothing moves a rating today, and a column list that quietly assumed
-- nothing ever would is the kind of assumption CA_0341's DELETE branch was added for.
-- The WHEN clause makes a re-rate at the SAME value a no-op, which is what the route's
-- ON CONFLICT DO UPDATE produces when somebody taps the control they already chose.
DROP TRIGGER IF EXISTS trg_claim_ratings_bump_aggregate_update ON connect.claim_ratings;
CREATE TRIGGER trg_claim_ratings_bump_aggregate_update
AFTER UPDATE OF value, claim_id ON connect.claim_ratings
FOR EACH ROW
WHEN (OLD.value IS DISTINCT FROM NEW.value OR OLD.claim_id IS DISTINCT FROM NEW.claim_id)
EXECUTE FUNCTION connect.bump_claim_rating_aggregate();

-- The branch that exists for `postgres` alone. See the header.
DROP TRIGGER IF EXISTS trg_claim_ratings_bump_aggregate_delete ON connect.claim_ratings;
CREATE TRIGGER trg_claim_ratings_bump_aggregate_delete
AFTER DELETE ON connect.claim_ratings
FOR EACH ROW
EXECUTE FUNCTION connect.bump_claim_rating_aggregate();

-- 5. Post-verify gate — fail loudly if this migration did not achieve what it claims.
--
-- Structured as CA_0341 §9 is: lookups first, then ONE behavioural probe inside a
-- BEGIN...EXCEPTION block (an implicit subtransaction) whose every exit is a RAISE, so
-- every row it wrote is unwound whether the outer transaction commits or not. plpgsql
-- variables are not transactional, so the verdict survives the unwind.
--   CA345 — reached the end, every assertion passed
--   CA346 — an assertion failed; v_probe_detail says which
-- v_probe_ok starts false and is set true only by the CA345 handler.
DO $$
DECLARE
  v_priv          TEXT;
  v_col           TEXT;
  v_notnull       BOOLEAN;
  v_default       TEXT;
  v_generated     "char";
  v_genexpr       TEXT;
  v_trigname      TEXT;
  v_mismatched    BIGINT;
  v_nonzero       BIGINT;
  v_probe_ok      BOOLEAN := FALSE;
  v_probe_detail  TEXT;
  v_probe_comm    UUID;
  v_probe_root    UUID;
  v_probe_a       UUID;
  v_probe_b       UUID;
  v_impact_a      NUMERIC;
  v_impact_b      NUMERIC;
  v_count         INT;
  v_sum           INT;
  v_edits         BIGINT;
  v_rater         UUID := '00000000-0000-4345-8345-000000000345';
  i               INT;
BEGIN
  -- (a) Both count columns exist, are NOT NULL, and default to 0.
  FOREACH v_col IN ARRAY ARRAY['rating_count', 'rating_sum'] LOOP
    SELECT a.attnotnull, pg_get_expr(d.adbin, d.adrelid)
      INTO v_notnull, v_default
      FROM pg_attribute a
      LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
     WHERE a.attrelid = 'connect.claims'::regclass AND a.attname = v_col AND NOT a.attisdropped;

    IF v_notnull IS NULL THEN
      RAISE EXCEPTION 'CA_0345 gate: connect.claims.% does not exist', v_col;
    END IF;
    IF NOT v_notnull THEN
      RAISE EXCEPTION 'CA_0345 gate: connect.claims.% is nullable — the generated impact expression would yield NULL for it', v_col;
    END IF;
    IF v_default IS DISTINCT FROM '0' THEN
      RAISE EXCEPTION 'CA_0345 gate: connect.claims.% defaults to %, expected 0', v_col, COALESCE(v_default, 'nothing');
    END IF;
  END LOOP;

  -- (b) impact exists, is GENERATED (not an ordinary column something could write), is
  --     NOT NULL, and carries the weight this migration chose. The expression is read
  --     rather than assumed because a later migration could CREATE OR REPLACE a different
  --     formula and leave every other assertion here passing.
  SELECT a.attnotnull, a.attgenerated, pg_get_expr(d.adbin, d.adrelid)
    INTO v_notnull, v_generated, v_genexpr
    FROM pg_attribute a
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
   WHERE a.attrelid = 'connect.claims'::regclass AND a.attname = 'impact' AND NOT a.attisdropped;

  IF v_notnull IS NULL THEN
    RAISE EXCEPTION 'CA_0345 gate: connect.claims.impact does not exist';
  END IF;
  IF v_generated <> 's' THEN
    RAISE EXCEPTION 'CA_0345 gate: connect.claims.impact is not a STORED generated column (attgenerated = %) — something other than the formula can write it', COALESCE(NULLIF(v_generated::text, ''), 'none');
  END IF;
  IF NOT v_notnull THEN
    RAISE EXCEPTION 'CA_0345 gate: connect.claims.impact is nullable — an unrated claim must read 5.0000, not NULL, or the ordering cannot place it';
  END IF;
  IF v_genexpr IS NULL OR v_genexpr NOT LIKE '%rating_sum%' OR v_genexpr NOT LIKE '%rating_count%' THEN
    RAISE EXCEPTION 'CA_0345 gate: connect.claims.impact is generated from %, which does not read both rating_sum and rating_count', COALESCE(v_genexpr, 'nothing');
  END IF;

  -- (c) All three trigger branches are attached. R39: the DELETE one is for `postgres`,
  --     who is exempt from the grant that says deletes cannot happen.
  FOREACH v_trigname IN ARRAY ARRAY['trg_claim_ratings_bump_aggregate_insert',
                                    'trg_claim_ratings_bump_aggregate_update',
                                    'trg_claim_ratings_bump_aggregate_delete'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'connect' AND c.relname = 'claim_ratings'
         AND NOT t.tgisinternal AND t.tgname = v_trigname
    ) THEN
      RAISE EXCEPTION 'CA_0345 gate: % is not attached to connect.claim_ratings', v_trigname;
    END IF;
  END LOOP;

  -- (d) Every existing row starts at zero, and the stored aggregate agrees with a direct
  --     count over connect.claim_ratings for EVERY claim — which is the invariant the
  --     trigger exists to hold, checked against the data rather than against the code.
  SELECT count(*) INTO v_nonzero
    FROM connect.claims WHERE rating_count <> 0 OR rating_sum <> 0;

  SELECT count(*) INTO v_mismatched
    FROM connect.claims c
    LEFT JOIN (SELECT claim_id, count(*) AS n, sum(value) AS s
                 FROM connect.claim_ratings GROUP BY claim_id) r ON r.claim_id = c.id
   WHERE c.rating_count <> COALESCE(r.n, 0) OR c.rating_sum <> COALESCE(r.s, 0);

  IF v_mismatched > 0 THEN
    RAISE EXCEPTION 'CA_0345 gate: % claim(s) disagree with a direct count over connect.claim_ratings', v_mismatched;
  END IF;
  IF (SELECT count(*) FROM connect.claim_ratings) = 0 AND v_nonzero > 0 THEN
    RAISE EXCEPTION 'CA_0345 gate: % claim(s) carry a non-zero aggregate while no rating exists', v_nonzero;
  END IF;

  -- (e) The index the ORDER BY walks. Checked by DEFINITION, not merely by name: an index
  --     on the right columns in the wrong direction cannot deliver the sort, and the
  --     planner would quietly fall back to sorting the whole child set.
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
     WHERE schemaname = 'connect' AND tablename = 'claims'
       AND indexname = 'claims_column_order_idx'
       AND indexdef LIKE '%impact DESC%'
       AND indexdef LIKE '%created_at DESC%'
  ) THEN
    RAISE EXCEPTION 'CA_0345 gate: claims_column_order_idx is missing or does not descend on impact and created_at — the column read would sort every child on every page';
  END IF;

  -- (f) The module's role can still read connect.claims, including the new columns.
  --
  -- 🔴 ONE CALL PER PRIVILEGE. has_table_privilege(role, table, 'SELECT,INSERT,UPDATE')
  -- is OR, not AND — it answers "any of these" — so written the comma way this check could
  -- never fail. Same bug CA_0341 §9(b) calls out.
  FOREACH v_priv IN ARRAY ARRAY['SELECT', 'INSERT', 'UPDATE'] LOOP
    IF NOT has_table_privilege('focused_communities_app', 'connect.claim_ratings', v_priv) THEN
      RAISE EXCEPTION 'CA_0345 gate: focused_communities_app is missing % on connect.claim_ratings — the rating upsert needs INSERT and UPDATE and reads the row back', v_priv;
    END IF;
  END LOOP;
  -- And per COLUMN for the three new ones, since a table-level grant is what covers them
  -- and a future column-level regrant could leave the table check passing while impact
  -- became unreadable.
  FOREACH v_col IN ARRAY ARRAY['rating_count', 'rating_sum', 'impact'] LOOP
    IF NOT has_column_privilege('focused_communities_app', 'connect.claims', v_col, 'SELECT') THEN
      RAISE EXCEPTION 'CA_0345 gate: focused_communities_app cannot SELECT connect.claims.%', v_col;
    END IF;
  END LOOP;
  -- Nothing gains DELETE. CA_0341's rule, restated for the role this migration touches.
  IF has_table_privilege('focused_communities_app', 'connect.claim_ratings', 'DELETE') THEN
    RAISE EXCEPTION 'CA_0345 gate: focused_communities_app can DELETE connect.claim_ratings — nothing in the argument tree is ever deleted';
  END IF;

  -- (g) It all actually WORKS. Everything above proves things EXIST; this proves they do
  --     what the header says, against real rows, and then unwinds.
  BEGIN
    INSERT INTO connect.communities (topic_id, slug, name)
    VALUES (gen_random_uuid(), 'ca0345-probe-' || gen_random_uuid()::text, 'CA_0345 probe')
    RETURNING id INTO v_probe_comm;

    SELECT id INTO v_probe_root FROM connect.claims WHERE community_id = v_probe_comm;

    -- An unrated claim is NEUTRAL, not null. This is the line the whole prior exists for.
    SELECT rating_count, rating_sum, impact INTO v_count, v_sum, v_impact_a
      FROM connect.claims WHERE id = v_probe_root;
    IF v_count <> 0 OR v_sum <> 0 OR v_impact_a <> 5.0000 THEN
      v_probe_detail := format('a brand new claim reads count=%s sum=%s impact=%s, expected 0, 0 and 5.0000',
                               v_count, v_sum, v_impact_a);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    INSERT INTO connect.claims (parent_claim_id, side, body)
    VALUES (v_probe_root, 'supports', 'CA_0345 probe claim A — one enthusiast')
    RETURNING id INTO v_probe_a;
    INSERT INTO connect.claims (parent_claim_id, side, body)
    VALUES (v_probe_root, 'supports', 'CA_0345 probe claim B — twenty supporters')
    RETURNING id INTO v_probe_b;

    ----------------------------------------------------- INSERT branch, and the brief's case
    INSERT INTO connect.claim_ratings (claim_id, user_id, value) VALUES (v_probe_a, v_rater, 9);
    FOR i IN 1..20 LOOP
      INSERT INTO connect.claim_ratings (claim_id, user_id, value)
      VALUES (v_probe_b, gen_random_uuid(), 7);
    END LOOP;

    SELECT impact INTO v_impact_a FROM connect.claims WHERE id = v_probe_a;
    SELECT impact INTO v_impact_b FROM connect.claims WHERE id = v_probe_b;

    IF v_impact_a <> 5.6667 OR v_impact_b <> 6.6000 THEN
      v_probe_detail := format('one 9 scored %s and twenty 7s scored %s; at IMPACT_PRIOR_WEIGHT = 5 they must be 5.6667 and 6.6000',
                               v_impact_a, v_impact_b);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;
    -- 🔴 THE STABILITY CASE. A single enthusiastic 9 must not outrank a well-supported 7.
    IF v_impact_a >= v_impact_b THEN
      v_probe_detail := format('a single 9 (%s) ranks at or above twenty 7s (%s) — the prior weight is too low',
                               v_impact_a, v_impact_b);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    ----------------------------------------------------- the edit log must stay out of it
    -- Rating a claim UPDATEs connect.claims. If trg_log_claim_edit ever fired for that, it
    -- would RAISE for want of fc.actor_id and every rating in production would 500.
    SELECT count(*) INTO v_edits FROM connect.claim_edits
     WHERE claim_id IN (v_probe_root, v_probe_a, v_probe_b);
    IF v_edits <> 0 THEN
      v_probe_detail := format('rating a claim wrote %s claim_edits row(s) — trg_log_claim_edit is firing on an aggregate update and will RAISE for want of fc.actor_id', v_edits);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    ----------------------------------------------------- UPDATE branch (the route's upsert)
    -- The same person changes their mind, 9 -> 1, through the exact statement
    -- routes/claimWrites.ts sends. Count must stay 1; sum must become 1.
    INSERT INTO connect.claim_ratings (claim_id, user_id, value)
    VALUES (v_probe_a, v_rater, 1)
    ON CONFLICT (claim_id, user_id) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

    SELECT rating_count, rating_sum, impact INTO v_count, v_sum, v_impact_a
      FROM connect.claims WHERE id = v_probe_a;
    IF v_count <> 1 OR v_sum <> 1 OR v_impact_a <> 4.3333 THEN
      v_probe_detail := format('after one person changed 9 to 1 the claim reads count=%s sum=%s impact=%s, expected 1, 1 and 4.3333',
                               v_count, v_sum, v_impact_a);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;
    -- And it now sits BELOW an untouched claim, which is the reading the prior buys.
    IF v_impact_a >= 5.0000 THEN
      v_probe_detail := format('a claim rated 1 by one person scores %s, at or above the 5.0000 of a claim nobody has rated', v_impact_a);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    -- Re-stating the SAME value must not double-count: the trigger's WHEN clause is what
    -- stops it, and ON CONFLICT DO UPDATE sends that statement on every repeat tap.
    INSERT INTO connect.claim_ratings (claim_id, user_id, value)
    VALUES (v_probe_a, v_rater, 1)
    ON CONFLICT (claim_id, user_id) DO UPDATE SET value = EXCLUDED.value, updated_at = now();

    SELECT rating_count, rating_sum INTO v_count, v_sum
      FROM connect.claims WHERE id = v_probe_a;
    IF v_count <> 1 OR v_sum <> 1 THEN
      v_probe_detail := format('re-sending the same rating moved the aggregate to count=%s sum=%s, expected 1 and 1', v_count, v_sum);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    ----------------------------------------------------- DELETE branch
    DELETE FROM connect.claim_ratings WHERE claim_id = v_probe_a AND user_id = v_rater;

    SELECT rating_count, rating_sum, impact INTO v_count, v_sum, v_impact_a
      FROM connect.claims WHERE id = v_probe_a;
    IF v_count <> 0 OR v_sum <> 0 OR v_impact_a <> 5.0000 THEN
      v_probe_detail := format('deleting the only rating left the claim at count=%s sum=%s impact=%s, expected 0, 0 and 5.0000 — the AFTER DELETE branch did not fire',
                               v_count, v_sum, v_impact_a);
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    END IF;

    ----------------------------------------------------- the coherence constraint bites
    -- claims_rating_totals_coherent is the backstop for a trigger branch that moves one
    -- column and not the other. A constraint nobody has tested is a comment with syntax.
    BEGIN
      UPDATE connect.claims SET rating_count = 1, rating_sum = 0 WHERE id = v_probe_b;
      v_probe_detail := 'one rating summing to 0 was accepted — claims_rating_totals_coherent does not bite';
      RAISE EXCEPTION 'probe failed' USING ERRCODE = 'CA346';
    EXCEPTION
      WHEN check_violation THEN
        NULL;  -- expected
    END;

    -- Every assertion passed. Abort anyway: this is how the probe cleans up after itself.
    RAISE EXCEPTION 'CA_0345 probe rollback' USING ERRCODE = 'CA345';
  EXCEPTION
    WHEN SQLSTATE 'CA345' THEN
      v_probe_ok := TRUE;
    WHEN SQLSTATE 'CA346' THEN
      v_probe_ok := FALSE;   -- v_probe_detail already names the failure
  END;

  IF NOT v_probe_ok THEN
    RAISE EXCEPTION 'CA_0345: the behavioural probe failed — %',
      COALESCE(v_probe_detail, 'the probe did not run to completion');
  END IF;

  -- (h) Belt and braces: the probe unwound completely, across all three tables it touched.
  IF EXISTS (SELECT 1 FROM connect.communities WHERE id = v_probe_comm)
     OR EXISTS (SELECT 1 FROM connect.claims WHERE community_id = v_probe_comm)
     OR EXISTS (SELECT 1 FROM connect.claim_ratings WHERE user_id = v_rater) THEN
    RAISE EXCEPTION 'CA_0345: the behavioural probe left rows behind — the subtransaction did not unwind';
  END IF;

  -- (i) ...and the live aggregate is still exactly what it was before the probe ran.
  SELECT count(*) INTO v_mismatched
    FROM connect.claims c
    LEFT JOIN (SELECT claim_id, count(*) AS n, sum(value) AS s
                 FROM connect.claim_ratings GROUP BY claim_id) r ON r.claim_id = c.id
   WHERE c.rating_count <> COALESCE(r.n, 0) OR c.rating_sum <> COALESCE(r.s, 0);
  IF v_mismatched > 0 THEN
    RAISE EXCEPTION 'CA_0345: % claim(s) disagree with connect.claim_ratings after the probe', v_mismatched;
  END IF;

  RAISE NOTICE 'CA_0345 OK — connect.claims gains rating_count, rating_sum and a NOT NULL generated impact (prior weight 5, neutral 5, 4 dp), claims_column_order_idx for the column ORDER BY, and the insert/update/delete aggregate trigger on connect.claim_ratings. % claims live, all at the aggregate a direct count gives. Probe verified, then rolled back: an unrated claim at 5.0000, one 9 (5.6667) ranking below twenty 7s (6.6000), a re-rate through ON CONFLICT DO UPDATE moving the sum but not the count, a repeat of the same value moving neither, a delete returning the aggregate to zero, the coherence constraint refusing an incoherent pair, and no claim_edits row written by any of it.',
    (SELECT count(*) FROM connect.claims);
END $$;

COMMIT;

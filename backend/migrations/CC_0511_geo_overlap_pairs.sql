BEGIN;

-- =============================================================================
-- CC_0511: the overlap answer is stored once per boundary version, not once an hour
-- =============================================================================
-- Created 2026-11-24 with Chris Cantrell.
-- Design: docs/superpowers/specs/2026-11-24-geo-overlap-precompute-design.md
-- Plan:   docs/superpowers/plans/2026-11-24-geo-overlap-precompute.md
-- Step 1: PR #1605 (371e79c895) — the MTFCC filter that took branch 1 off the
--         whole-polygon scan. Read UNRESOLVABLE_PAIR_MTFCCS in
--         backend/src/lib/geoIdGuard.ts for every measurement behind this work.
--
-- -----------------------------------------------------------------------------
-- WHAT THIS IS FOR
-- -----------------------------------------------------------------------------
-- resolveOverlappingGeoPairs answers "which geofences overlap this area". It is
-- pure geometry over essentials.geofence_boundaries, and today it is cached in
-- Redis for one hour. An hour is an arbitrary number: the answer does not change
-- on a clock, it changes when the boundaries change. So every hour, for every
-- area anyone browses, we pay the computation again for an answer that was
-- already correct.
--
-- Measured: California stays at ~3.3 s EVEN WARM, because branch 3 runs
-- ST_Intersection against a 12,103-vertex state outline. That is the cost this
-- table removes.
--
-- The two tables here make the answer durable and make it invalidate on the only
-- two things that can change it:
--   1. essentials.geofence_version — a one-row bigint bumped by a trigger when
--      the geometry actually changes. The DATA half of the key.
--   2. essentials.geo_overlap_pairs — one row per (seed, version, fingerprint),
--      holding that seed's whole answer. The CODE half of the key is
--      query_fingerprint.
--
-- -----------------------------------------------------------------------------
-- 🔴🔴 THE ANSWER IS NOT A PURE FUNCTION OF THE GEOMETRY, AND query_fingerprint
--      IS WHY THIS TABLE HAS FOUR KEY COLUMNS RATHER THAN THREE
-- -----------------------------------------------------------------------------
-- Four values that live in TypeScript change the answer for unchanged geometry:
-- UNRESOLVABLE_PAIR_MTFCCS (geoIdGuard.ts), branch 3's seven-MTFCC list, branch
-- 2's ('G4110','G4120') exclusion, and MIN_OVERLAP_FRACTION. Keyed on the
-- boundary version alone, an edit to any of them would leave every stored row
-- readable and WRONG — the precise anti-goal of this work, and worse than the
-- hourly recompute it replaces, because a wrong answer at the current version
-- never expires.
--
-- query_fingerprint is 16 hex characters of the SHA-256 of the resolver's
-- FINISHED SQL TEXT (backend/src/lib/geoOverlapStore.ts fingerprintOf,
-- essentialsBrowseService.ts OVERLAP_QUERY_FINGERPRINT). All four constants are
-- already interpolated into, or written literally inside, that string, so hashing
-- it covers all four and there is no second hand-maintained list to fall out of
-- step. Change any of them and every row computed under the old rule becomes
-- UNREADABLE rather than wrong; the sweep then deletes it.
--
-- -----------------------------------------------------------------------------
-- WHY `pairs` IS jsonb AND NOT A ROW PER PAIR
-- -----------------------------------------------------------------------------
-- Every consumer wants the whole list for a seed and nothing else — there is no
-- query in this product that asks "which seeds contain pair X". The lists run
-- 852-4,918 entries for a state seed. One row per seed makes the version-and-
-- fingerprint predicate a PRIMARY KEY LOOKUP; one row per pair would make it a
-- filtered scan over millions of rows, and would need the same four key columns
-- repeated on every one of them. pair_count is stored beside it so a health
-- check can read the shape of an answer without detoasting the answer.
--
-- -----------------------------------------------------------------------------
-- 🔴🔴 CORRECTION, AND IT CONTRADICTS THE OBVIOUS READING OF "STATEMENT-LEVEL"
-- -----------------------------------------------------------------------------
-- The bump is a statement trigger so that one bulk load costs one version, not
-- one per row. VERIFIED ON THIS BRANCH 2026-11-24, THAT IS NOT WHAT THE LOADERS
-- DO. backend/scripts/load-state-tiger-boundaries.ts:1330 and
-- backend/scripts/1642-import-core.mts:145 both insert ONE ROW PER STATEMENT
-- (INSERT ... VALUES ($1...) ON CONFLICT (geo_id, mtfcc) DO NOTHING), and
-- NEITHER SCRIPT OPENS A TRANSACTION — zero `BEGIN` in either file. They
-- autocommit per row. So the once-per-transaction guard below cannot coalesce a
-- TIGER load: during one the version moves once per CHANGED row.
--
-- That is still correct. A reader at a superseded version misses and recomputes;
-- it is never served a stale answer. And the transition-table guard still kills
-- the case that actually hurts, which is the NO-OP RE-RUN: a loader re-run where
-- every row hits ON CONFLICT DO NOTHING changes no geometry at all, and without
-- the guard would discard every stored answer — the 53 warm states included —
-- 70,000 times over.
--
-- ⚠ THE REMEDY, IF THE MEASURED OVERHEAD IS EVER TOO DEAR, IS A TRANSACTION
--   AROUND THE LOADER'S ROW LOOP — NOT A BYPASS THE LOADER MUST REMEMBER TO USE.
--   A bypass is two mechanisms kept in sync by hand, which is the thing this
--   design exists to avoid. Measured overhead is recorded at the bottom of this
--   header.
--
-- ⚠ `imported_at` was considered as the version and REJECTED: 389 rows carry
--   NULL, it holds 1,580 distinct values (so it is a per-row ingest stamp, not a
--   global one), and max(imported_at) cannot see a DELETE at all.
--
-- -----------------------------------------------------------------------------
-- THE TWO GUARDS IN THE TRIGGER, AND WHY NEITHER IS OPTIONAL
-- -----------------------------------------------------------------------------
--   (a) TRANSITION TABLES. A Postgres statement trigger fires whether the
--       statement touched 70,000 rows or zero. Without `REFERENCING NEW TABLE`
--       the trigger could not tell a real ingest from a no-op re-run, and the
--       no-op is the common case: loaders are re-run.
--   (b) THE txid GUARD. Within one transaction, many statements must still cost
--       one version. last_bump_txid is what makes the second statement a no-op.
--
-- -----------------------------------------------------------------------------
-- WHAT THE TRIGGER COSTS, MEASURED 2026-11-24 ON PROD, IN A ROLLED-BACK TXN
-- -----------------------------------------------------------------------------
-- 5,000 single-row INSERTs into essentials.geofence_boundaries each time, so the
-- overhead is a DIFFERENCE and not an absolute. 15,000 rows written and rolled
-- back; the baseline was taken with the INSERT trigger DISABLEd on the same
-- table, not against a copy of it.
--
--   B   triggers OFF (baseline)                        693 ms   0.1386 ms/row
--   C   bare geofence_version UPDATEs                  368 ms   0.0736 ms/row
--   A1  triggers ON, txid guard ENGAGED              1,566 ms   0.3133 ms/row
--   A2  triggers ON, guard cleared each row          3,721 ms   0.7442 ms/row
--
--   A1 - B            = 0.175 ms/row  ->  12.2 s per 70,000 rows
--   A2 - B - C        = 0.532 ms/row  ->  37.2 s per 70,000 rows
--
-- A2 IS THE SHAPE THE LOADERS HAVE TODAY, because they autocommit one row per
-- statement, so every row is its own transaction and every row pays a full bump.
-- 37.2 s added to one state's TIGER load, against a budget of 90 s: WITHIN
-- BUDGET, with room. A second run of the whole measurement agreed (9.5 s / 35.8 s).
--
-- A1 is what the same load would cost if its row loop were wrapped in ONE
-- transaction: 12.2 s. That is the remedy named above, and the number says it is
-- worth about 25 seconds a state — worth doing one day, not worth doing now, and
-- NOT a reason to add a bypass.
--
-- Additive + idempotent (safe to re-run). One transaction: a store that exists
-- without its invalidation trigger is worse than no store, because it reads as
-- coverage while serving answers nothing can expire.
--
-- APPLIED to prod (kxsdzaojfaibhuzmclfq) 2026-11-24 through the owner connection,
-- after the identical statements were run inside BEGIN ... ROLLBACK and seen to
-- create 4 triggers, RLS on 2 tables, version seeded at 1 and ev_api arwd true —
-- then seen to leave nothing behind.
--
-- 🔴 WHAT THAT FIRST APPLY CREATED AND THIS FILE NO LONGER DOES. It also created
-- two SELECT policies, which the operator then ruled against in favour of the
-- house precedent (RLS on, no policies). Recorded here because a dropped policy
-- exists nowhere afterwards, and this file is the only record either way:
--
--   CREATE POLICY geofence_version_read  ON essentials.geofence_version
--     FOR SELECT TO anon, authenticated USING (true);
--   CREATE POLICY geo_overlap_pairs_read ON essentials.geo_overlap_pairs
--     FOR SELECT TO anon, authenticated USING (true);
--
-- Both were dropped from prod on 2026-11-24 through the owner connection, by the
-- two DROP statements in section 3 below. No application code changed: every
-- reader of these tables is backend code on the ev_api pool, which bypasses RLS.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. The version. One row, forever.
-- -----------------------------------------------------------------------------
-- `one_row` is a singleton guard, not data: the PRIMARY KEY plus CHECK (one_row)
-- means a second row cannot be inserted by any path. A second row here would be
-- silent and ruinous — readers would pick one arbitrarily and half the fleet
-- would invalidate on a different number from the other half.
--
-- version is bigint and is read as TEXT end to end in TypeScript. node-postgres
-- returns bigint as a string; parsing it to a JavaScript number would be exact
-- today and would stop being exact without any error at all.

CREATE TABLE IF NOT EXISTS essentials.geofence_version (
  one_row        boolean     PRIMARY KEY DEFAULT true CHECK (one_row),
  version        bigint      NOT NULL,
  last_bump_txid bigint,
  bumped_at      timestamptz
);

INSERT INTO essentials.geofence_version (one_row, version, bumped_at)
VALUES (true, 1, now())
ON CONFLICT (one_row) DO NOTHING;


-- -----------------------------------------------------------------------------
-- 2. The store.
-- -----------------------------------------------------------------------------
-- The primary key is the whole identity of an answer: WHICH seed, against WHICH
-- geometry, under WHICH resolver code. A row at any other version or any other
-- fingerprint is not stale data to be refreshed — it is an answer to a different
-- question, and the reader must miss on it rather than repair it.

CREATE TABLE IF NOT EXISTS essentials.geo_overlap_pairs (
  seed_geo_id      text        NOT NULL,
  seed_mtfcc       text        NOT NULL,
  geofence_version bigint      NOT NULL,
  query_fingerprint text       NOT NULL,
  pairs            jsonb       NOT NULL,
  pair_count       int         NOT NULL,
  computed_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (seed_geo_id, seed_mtfcc, geofence_version, query_fingerprint)
);


-- -----------------------------------------------------------------------------
-- 3. RLS on both tables. No policies. No GRANTs.
-- -----------------------------------------------------------------------------
-- 🔴 ON `essentials`, RLS IS NOT BELT-AND-BRACES — IT IS THE ONLY BELT. ALTER
-- DEFAULT PRIVILEGES in this schema already grants `anon` and `authenticated`
-- SELECT and `ev_api` arwd on every new table, before this file says a word
-- ({anon=r, authenticated=r, ev_api=arwd}, measured on prod 2026-11-20 by
-- CC_0457). Both tables above are anon-readable from the moment they exist, and
-- nothing errors if this section is missing.
--
-- 🔴 DO NOT WRITE A GRANT HERE. ev_api reaches these tables through the schema
-- default; a hand-written GRANT would work AND would hide a broken default, so
-- the next table created in this schema would come out unreadable and nobody
-- would know why. The verification block at the bottom checks the default fired
-- instead.
--
-- 🔴 NO POLICIES, WHICH IS THE HOUSE PRECEDENT — RLS ON, DEFAULT DENY. CC_0468
--   and every inform.compass_* table do the same. The backend reads these two
--   tables through its service pool as `ev_api`, which carries
--   rolbypassrls = true, so RLS never governs the only reads this product makes;
--   an anon SELECT policy would admit a read nothing performs. Measured
--   2026-11-24: the only code that names either table is backend/src
--   (essentialsBrowseService.ts, geoOverlapStore.ts, geoOverlapWarm.ts) and two
--   backend scripts, all on that pool. No front end, and no PostgREST call.
--
-- 🔴 THE TWO DROP STATEMENTS BELOW ARE LOAD-BEARING, NOT DECORATION. The first
--   apply of this file created the two policies the design asked for; the
--   operator ruled for the house precedent on 2026-11-24, and these are what
--   remove them from a database that already has them. They ran against prod the
--   same day. The dropped definitions are in this file's header, because a
--   dropped policy exists nowhere else. Re-adding one is a decision about
--   PostgREST exposure, not a formality — check (f2) below will fail until the
--   decision is written down here.

ALTER TABLE essentials.geofence_version   ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.geo_overlap_pairs  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS geofence_version_read  ON essentials.geofence_version;
DROP POLICY IF EXISTS geo_overlap_pairs_read ON essentials.geo_overlap_pairs;


-- -----------------------------------------------------------------------------
-- 4. The bump.
-- -----------------------------------------------------------------------------
-- 🔴 SECURITY DEFINER, owned by postgres, with `SET search_path TO ''`. Anything
-- that writes essentials.geofence_boundaries must be able to fire this trigger,
-- including a role that was never granted UPDATE on geofence_version; an INVOKER
-- trigger would abort that write instead. The pinned empty search_path goes with
-- SECURITY DEFINER always — a mutable one lets the caller choose which schema
-- `geofence_version` resolves to. (pg_catalog is implicitly searched even when
-- the path is empty, so now() and txid_current() still resolve.)
--
-- 🔴 Transition tables resolve through the query environment, NOT through the
-- search_path, so `changed` and `removed` are reachable with the path pinned to
-- empty. They are also the only way to ask "did this statement change anything",
-- which is guard (a) above.

CREATE OR REPLACE FUNCTION essentials.bump_geofence_version()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_changed boolean;
BEGIN
  -- 1. A statement that changed nothing must bump nothing. A Postgres statement
  --    trigger fires regardless of how many rows the statement touched, so
  --    without this a re-run of a loader that ON CONFLICT DO NOTHINGs on every
  --    row -- a no-op -- would discard every stored answer, the 53 warm states
  --    included, for no geometry change at all.
  IF TG_OP = 'TRUNCATE' THEN
    -- TRUNCATE carries no transition table, and it empties the table. It is the
    -- largest geometry change there is, so it always bumps.
    v_changed := true;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT EXISTS (SELECT 1 FROM removed) INTO v_changed;
  ELSE
    SELECT EXISTS (SELECT 1 FROM changed) INTO v_changed;
  END IF;
  IF NOT v_changed THEN RETURN NULL; END IF;

  -- 2. At most one bump per transaction.
  UPDATE essentials.geofence_version
     SET version = version + 1, last_bump_txid = txid_current(), bumped_at = now()
   WHERE last_bump_txid IS DISTINCT FROM txid_current();
  RETURN NULL;
END;
$function$;

-- CREATE OR REPLACE TRIGGER is PostgreSQL 14+ and this is 17.6, so there is no
-- DROP-then-CREATE window in which a write could slip past unrecorded.

CREATE OR REPLACE TRIGGER geofence_boundaries_bump_ins
  AFTER INSERT ON essentials.geofence_boundaries
  REFERENCING NEW TABLE AS changed
  FOR EACH STATEMENT EXECUTE FUNCTION essentials.bump_geofence_version();

CREATE OR REPLACE TRIGGER geofence_boundaries_bump_upd
  AFTER UPDATE ON essentials.geofence_boundaries
  REFERENCING NEW TABLE AS changed
  FOR EACH STATEMENT EXECUTE FUNCTION essentials.bump_geofence_version();

CREATE OR REPLACE TRIGGER geofence_boundaries_bump_del
  AFTER DELETE ON essentials.geofence_boundaries
  REFERENCING OLD TABLE AS removed
  FOR EACH STATEMENT EXECUTE FUNCTION essentials.bump_geofence_version();

-- ⚠ TRUNCATE FIRES NO INSERT, UPDATE OR DELETE TRIGGER. Without this fourth one,
-- a TRUNCATE of geofence_boundaries would empty the geometry while leaving the
-- version untouched — and every stored answer would stay readable at a version
-- that now describes an empty table. CC_0468 learned the same lesson on
-- compass_user_lenses. A TRUNCATE trigger cannot carry a transition table, which
-- is why the function branches on TG_OP above.

CREATE OR REPLACE TRIGGER geofence_boundaries_bump_trunc
  AFTER TRUNCATE ON essentials.geofence_boundaries
  FOR EACH STATEMENT EXECUTE FUNCTION essentials.bump_geofence_version();


-- -----------------------------------------------------------------------------
-- 5. Verification.
-- -----------------------------------------------------------------------------
-- Every check here answers one question and names it. A predicate of several
-- conditions fails for exactly one reason and nothing prints which, so these are
-- written apart rather than as one EXISTS.

DO $$
DECLARE
  v_bad      text;
  v_triggers int;
  v_rows     int;
  v_rls      int;
  v_pol      int;
BEGIN
  -- (a) Exactly one version row, and it is readable.
  SELECT count(*) INTO v_rows FROM essentials.geofence_version;
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'CC_0511: essentials.geofence_version holds % rows, expected exactly 1', v_rows;
  END IF;

  -- (b) The singleton guard really refuses a second row. A constraint nobody has
  --     seen refuse anything is a constraint nobody has tested.
  BEGIN
    INSERT INTO essentials.geofence_version (one_row, version) VALUES (false, 999);
    RAISE EXCEPTION 'CC_0511: a second geofence_version row was accepted — the singleton guard is not holding';
  EXCEPTION
    WHEN check_violation THEN NULL;   -- expected: CHECK (one_row)
  END;

  -- (c) All four triggers are attached.
  SELECT count(*) INTO v_triggers
    FROM pg_trigger
   WHERE tgrelid = 'essentials.geofence_boundaries'::regclass
     AND NOT tgisinternal
     AND tgname IN ('geofence_boundaries_bump_ins', 'geofence_boundaries_bump_upd',
                    'geofence_boundaries_bump_del', 'geofence_boundaries_bump_trunc');
  IF v_triggers <> 4 THEN
    RAISE EXCEPTION 'CC_0511: expected 4 bump triggers on essentials.geofence_boundaries, found %', v_triggers;
  END IF;

  -- (d) The three row triggers carry their transition tables. Without them the
  --     trigger cannot tell a real ingest from a no-op re-run, and a no-op re-run
  --     would discard every stored answer. "Has a trigger" is not the claim.
  SELECT string_agg(tgname, ', ') INTO v_bad
    FROM pg_trigger
   WHERE tgrelid = 'essentials.geofence_boundaries'::regclass
     AND NOT tgisinternal
     AND tgname IN ('geofence_boundaries_bump_ins', 'geofence_boundaries_bump_upd',
                    'geofence_boundaries_bump_del')
     AND pg_get_triggerdef(oid) NOT ILIKE '%REFERENCING%TABLE AS%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION
      'CC_0511: % has no transition table — a statement that changed nothing would still bump '
      'the version, so a no-op loader re-run would discard every stored answer', v_bad;
  END IF;

  -- (e) The function is SECURITY DEFINER with an empty search_path.
  SELECT p.proname INTO v_bad
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'essentials'
     AND p.proname = 'bump_geofence_version'
     AND NOT (p.prosecdef
       AND btrim(coalesce((SELECT substring(c, 13) FROM unnest(p.proconfig) AS c
                            WHERE c LIKE 'search_path=%'), 'UNPINNED'), '"''') = '');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION
      'CC_0511: essentials.bump_geofence_version is not SECURITY DEFINER with search_path pinned '
      'to empty — a writer without UPDATE on geofence_version would abort its own write';
  END IF;

  -- (f) RLS is on for both tables. On essentials this is the only belt.
  SELECT count(*) INTO v_rls
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials'
     AND c.relname IN ('geofence_version', 'geo_overlap_pairs')
     AND c.relrowsecurity;
  IF v_rls <> 2 THEN
    RAISE EXCEPTION
      'CC_0511: row-level security is enabled on only % of the 2 new tables — the other is '
      'anon-readable with no policy governing it', v_rls;
  END IF;

  -- (f2) And NO policies on either table — default deny, the house precedent.
  --      RLS with a permissive policy and RLS with none are opposite postures and
  --      look identical in relrowsecurity, so (f) alone cannot see this. The
  --      message names every policy found, because "1 policy" does not say which.
  SELECT count(*), string_agg(p.schemaname || '.' || p.tablename || '.' || p.policyname, ', ')
    INTO v_pol, v_bad
    FROM pg_policies p
   WHERE p.schemaname = 'essentials'
     AND p.tablename IN ('geofence_version', 'geo_overlap_pairs');
  IF v_pol <> 0 THEN
    RAISE EXCEPTION
      'CC_0511: expected 0 policies on the 2 new tables and found % (%). RLS here is default '
      'deny: ev_api bypasses RLS and is the only reader, so a policy admits a read this product '
      'never makes. If one is wanted, record the decision in this file''s header first', v_pol, v_bad;
  END IF;

  -- (g) ev_api reached both tables through ALTER DEFAULT PRIVILEGES, with no GRANT
  --     written here. A WARNING, not an exception: the remedy is to fix the schema
  --     default, not to paper over it with a GRANT, and aborting would not make
  --     that any likelier to happen.
  --
  -- 🔴 IF THIS WARNS, STOP. The read path cannot reach its own store and every
  --    browse request falls back to the 3.3-second compute.
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ev_api') THEN
    SELECT string_agg(t, ', ') INTO v_bad
      FROM unnest(ARRAY['essentials.geofence_version', 'essentials.geo_overlap_pairs']) AS t
     WHERE NOT (has_table_privilege('ev_api', t, 'SELECT')
            AND has_table_privilege('ev_api', t, 'INSERT')
            AND has_table_privilege('ev_api', t, 'UPDATE')
            AND has_table_privilege('ev_api', t, 'DELETE'));
    IF v_bad IS NOT NULL THEN
      RAISE WARNING
        'CC_0511: ev_api does NOT have arwd on % — ALTER DEFAULT PRIVILEGES IN SCHEMA essentials '
        'did not apply. Fix the default privileges; do NOT paper over it with a hand-written GRANT.',
        v_bad;
    END IF;
  ELSE
    RAISE WARNING 'CC_0511: no ev_api role here, so the default-privileges check did not run.';
  END IF;

  RAISE NOTICE 'CC_0511 OK: geofence_version seeded at 1 with its singleton guard proven, '
               'geo_overlap_pairs created, 4 bump triggers armed (3 with transition tables), '
               'function SECURITY DEFINER with search_path pinned, RLS on both tables.';
END $$;

COMMIT;

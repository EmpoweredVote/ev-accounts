-- CA_0408 — side table for state-source raw_record, and the trigger that moves new JSON into it
-- (ev-cto 0038 Part D, Step 6 as revised 2026-11-21)
--
-- WHAT. Creates transparent_motivations.contributions_raw (data_source, source_transaction_id) -> raw_record,
-- and a BEFORE INSERT OR UPDATE trigger on contributions that moves every non-FEC row's raw_record into it and
-- leaves contributions.raw_record NULL. CA_0409 moves the rows already stored. Nothing is deleted.
--
-- WHY A SIDE TABLE AND NOT A DROP (decided 2026-11-21). The state JSON (~670k rows, ~0.45 GB) is read by nothing
-- that runs today — every reader uses the typed columns (CA_0380, PR #1434) — but it is kept because:
--   * some of it cannot be fetched again: in_monroe_county_local was transcribed from county filings by
--     parse-local-cfa.ts, and Cal-Access rows go back to 2001;
--   * it holds keys never promoted to columns (Indiana Address/Occupation/Description, most of each OCPF row);
--   * it is what each source said at import, which is how a wrong number gets checked without the source.
-- Moved out, it no longer rides in every full read of contributions (the nightly donor_names_search refresh).
--
-- KEY. (data_source, source_transaction_id), the same natural key as idx_contribution_dedup and every
-- adapter's ON CONFLICT — NOT contributions.id. A BEFORE INSERT trigger sees a NEW.id that ON CONFLICT may
-- never store, so an id key would orphan rows. No foreign key, for the same reason. A contribution deleted
-- later leaves its JSON here (provenance); a later insert with the same key overwrites it.
--
-- 🔴 THE ON CONFLICT TRAP. ocpf and netfile refresh rows with
--     INSERT ... ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET ..., raw_record = EXCLUDED.raw_record
-- EXCLUDED is the row AFTER the BEFORE INSERT triggers. Had this trigger nulled raw_record on that INSERT, the
-- refreshed JSON would reach neither table and contributions_fill_typed would not re-derive the typed columns
-- (it skips an UPDATE whose raw_record is unchanged). So when the key already exists the INSERT path leaves the
-- JSON on the proposed row: DO UPDATE carries it to the UPDATE, where fill_typed re-derives the columns and
-- this trigger then moves it; DO NOTHING discards it and the stored JSON stays as it was — the same outcome as
-- before this migration in both cases.
--
-- ORDER. Row triggers fire by name: contributions_fill_typed, contributions_stash_state_raw,
-- contributions_strip_fec_raw. fill_typed must read the JSON before this one clears it.
--
-- ACCESS. Default privileges in this schema give anon and authenticated SELECT on every new table. Raw JSON
-- holds donor street addresses (Indiana), so this table is revoked from every API role and has RLS on with
-- no policy. The trigger function is SECURITY DEFINER (owner postgres, search_path '') so ev_api's writes to
-- contributions need no grant here. Readers are maintenance scripts running as postgres.
--
-- LIMITS. Rows with source_transaction_id NULL keep raw_record on contributions (no key). An UPDATE that changes
-- a row's data_source or source_transaction_id without supplying JSON leaves the JSON under the old key.
--
-- Lock: CREATE TRIGGER takes SHARE ROW EXCLUSIVE on contributions for milliseconds; lock_timeout 3s.
-- UNDO: DROP TRIGGER contributions_stash_state_raw; then copy contributions_raw back (CA_0409's header has it).
--
-- STATUS: APPLIED 2026-11-21 01:33:30-01:33:32 UTC, post-verify ok. Rehearsed first with ROLLBACK and six trigger
-- tests: plain insert moves the JSON and fills the columns; ON CONFLICT DO UPDATE with new JSON updates row,
-- columns and side table; DO NOTHING changes nothing; FEC unchanged; NULL source_transaction_id keeps its JSON;
-- ev_api writes through the trigger but cannot read the side table, nor can anon.
-- ⚠ A second rehearsal (with CA_0409's first draft in the same transaction) held CREATE TRIGGER's lock for
-- ~10 minutes and blocked an outside INSERT into contributions for ~2 minutes until cancelled. Never rehearse
-- a CREATE TRIGGER together with a long statement.

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '1min';

DO $$
BEGIN
  IF to_regclass('transparent_motivations.contributions_raw') IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0408: contributions_raw already exists';
  END IF;
  IF (SELECT array_agg(tgname::text ORDER BY tgname) FROM pg_trigger
       WHERE tgrelid = 'transparent_motivations.contributions'::regclass AND NOT tgisinternal)
     IS DISTINCT FROM ARRAY['contributions_fill_typed', 'contributions_strip_fec_raw'] THEN
    RAISE EXCEPTION 'CA_0408: contributions triggers are not {fill_typed, strip_fec_raw}';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_index WHERE indexrelid = 'transparent_motivations.idx_contribution_dedup'::regclass
                  AND indisunique AND indisvalid) THEN
    RAISE EXCEPTION 'CA_0408: idx_contribution_dedup is not a valid unique index';
  END IF;
END $$;

CREATE TABLE transparent_motivations.contributions_raw (
  data_source           varchar(32)  NOT NULL,
  source_transaction_id varchar(128) NOT NULL,
  raw_record            jsonb        NOT NULL,
  updated_at            timestamptz  NOT NULL DEFAULT now(),
  PRIMARY KEY (data_source, source_transaction_id)
);
COMMENT ON TABLE transparent_motivations.contributions_raw IS
  'Source JSON of non-FEC contributions, keyed like idx_contribution_dedup. Filled by trigger '
  'contributions_stash_state_raw (CA_0408) and CA_0409. Not exposed to any API role: holds donor addresses.';

REVOKE ALL ON transparent_motivations.contributions_raw FROM PUBLIC, anon, authenticated, ev_api, service_role;
ALTER TABLE transparent_motivations.contributions_raw ENABLE ROW LEVEL SECURITY;

CREATE FUNCTION transparent_motivations.contributions_stash_state_raw()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = ''
AS $fn$
BEGIN
  IF new.raw_record IS NULL OR new.data_source = 'fec' OR new.source_transaction_id IS NULL THEN
    RETURN new;
  END IF;
  -- The key is already stored: this INSERT is headed for ON CONFLICT. Leave the JSON on the proposed row
  -- (see the header: DO UPDATE brings it back through this trigger as an UPDATE; DO NOTHING drops it).
  IF tg_op = 'INSERT' AND EXISTS (
       SELECT 1 FROM transparent_motivations.contributions c
        WHERE c.data_source = new.data_source AND c.source_transaction_id = new.source_transaction_id) THEN
    RETURN new;
  END IF;
  INSERT INTO transparent_motivations.contributions_raw AS r (data_source, source_transaction_id, raw_record, updated_at)
  VALUES (new.data_source, new.source_transaction_id, new.raw_record, now())
  ON CONFLICT (data_source, source_transaction_id) DO UPDATE
     SET raw_record = excluded.raw_record, updated_at = excluded.updated_at
   WHERE r.raw_record IS DISTINCT FROM excluded.raw_record;
  new.raw_record := NULL;
  RETURN new;
END
$fn$;
REVOKE ALL ON FUNCTION transparent_motivations.contributions_stash_state_raw() FROM PUBLIC, anon, authenticated, ev_api, service_role;

CREATE TRIGGER contributions_stash_state_raw
  BEFORE INSERT OR UPDATE ON transparent_motivations.contributions
  FOR EACH ROW EXECUTE FUNCTION transparent_motivations.contributions_stash_state_raw();

-- Post-verify.
DO $$
DECLARE
  t oid := 'transparent_motivations.contributions_raw'::regclass;
  acl text;
BEGIN
  IF (SELECT array_agg(tgname::text ORDER BY tgname) FROM pg_trigger
       WHERE tgrelid = 'transparent_motivations.contributions'::regclass AND NOT tgisinternal)
     IS DISTINCT FROM ARRAY['contributions_fill_typed', 'contributions_stash_state_raw', 'contributions_strip_fec_raw'] THEN
    RAISE EXCEPTION 'CA_0408: trigger set is wrong';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = t) THEN RAISE EXCEPTION 'CA_0408: RLS is off'; END IF;
  IF EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = t) THEN RAISE EXCEPTION 'CA_0408: unexpected policy'; END IF;
  SELECT coalesce(relacl::text, '') INTO acl FROM pg_class WHERE oid = t;
  IF acl ~ '(anon|authenticated|ev_api|service_role)=' OR acl ~ '(^|[{,])=' THEN
    RAISE EXCEPTION 'CA_0408: contributions_raw is granted to an API role: %', acl;
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = 'transparent_motivations.contributions_stash_state_raw'::regproc) THEN
    RAISE EXCEPTION 'CA_0408: trigger function is not SECURITY DEFINER';
  END IF;
  IF (SELECT relacl::text FROM pg_class WHERE oid = 'transparent_motivations.contributions'::regclass)
     IS DISTINCT FROM '{postgres=arwdDxtm/postgres,anon=r/postgres,authenticated=r/postgres,ev_api=arwd/postgres}' THEN
    RAISE EXCEPTION 'CA_0408: contributions ACL changed';
  END IF;
  RAISE NOTICE 'CA_0408: post-verify ok (acl %)', acl;
END $$;

COMMIT;

-- CA_0118 — Identity vault store (ev-cto decision 0022, spec 2026-09-17).
-- The app can WRITE (seal) but never READ. Decryption is off-DB (break-glass CLI).
--
-- SECURITY MODEL — why a SECURITY DEFINER function, not table grants + RLS:
--   The API's runtime role `ev_api` (migration 1386) is a BYPASSRLS trusted-backend
--   role, so RLS cannot constrain it — GRANTS are the only control on it. And an
--   `INSERT ... ON CONFLICT DO UPDATE` requires SELECT privilege, which would let the
--   app read ciphertext. So the seal write goes through `id_vault.seal_upsert`, a
--   SECURITY DEFINER function owned by the (superuser) migration role. `ev_api` gets
--   EXECUTE on that function and NO direct privilege on the table — it can seal but
--   cannot read. RLS is enabled as defense-in-depth against any non-BYPASSRLS role.
BEGIN;

CREATE SCHEMA IF NOT EXISTS id_vault;

CREATE TABLE IF NOT EXISTS id_vault.sealed_identities (
  user_id        uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sealed_name    bytea,
  sealed_address bytea,
  key_version    smallint NOT NULL,
  sealed_at      timestamptz NOT NULL DEFAULT now()
);

-- Lock the schema + table down. ev_api gets USAGE on the schema (to call the
-- function) and NOTHING on the table — no SELECT/INSERT/UPDATE/DELETE.
REVOKE ALL ON SCHEMA id_vault FROM PUBLIC;
REVOKE ALL ON id_vault.sealed_identities FROM PUBLIC;
GRANT USAGE ON SCHEMA id_vault TO ev_api;

-- Defense-in-depth: deny-by-default RLS for any non-BYPASSRLS role (e.g. a future
-- PostgREST exposure). ev_api bypasses RLS, so this is NOT its control — the absence
-- of any table grant is. No policies => no row is visible to a non-bypassing role.
ALTER TABLE id_vault.sealed_identities ENABLE ROW LEVEL SECURITY;

-- The one write path: a SECURITY DEFINER upsert, owned by the migration role. It
-- preserves the column not being sealed (COALESCE), which is safe here because the
-- function runs as its owner (which may read), never as ev_api.
CREATE OR REPLACE FUNCTION id_vault.seal_upsert(
  p_user_id        uuid,
  p_sealed_name    bytea,
  p_sealed_address bytea,
  p_key_version    smallint
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  INSERT INTO id_vault.sealed_identities (user_id, sealed_name, sealed_address, key_version, sealed_at)
  VALUES (p_user_id, p_sealed_name, p_sealed_address, p_key_version, now())
  ON CONFLICT (user_id) DO UPDATE SET
    sealed_name    = COALESCE(EXCLUDED.sealed_name,    id_vault.sealed_identities.sealed_name),
    sealed_address = COALESCE(EXCLUDED.sealed_address, id_vault.sealed_identities.sealed_address),
    key_version    = EXCLUDED.key_version,
    sealed_at      = now();
$$;

REVOKE ALL ON FUNCTION id_vault.seal_upsert(uuid, bytea, bytea, smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION id_vault.seal_upsert(uuid, bytea, bytea, smallint) TO ev_api;

-- Post-verify gate: table exists; ev_api holds NO direct privilege on the table
-- (table- or column-level); ev_api CAN execute the seal function.
DO $$
DECLARE
  v_has_table       boolean;
  v_ev_api_table    int;
  v_ev_api_execute  boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'id_vault' AND table_name = 'sealed_identities')
    INTO v_has_table;
  IF NOT v_has_table THEN
    RAISE EXCEPTION 'id_vault.sealed_identities missing after migration';
  END IF;

  SELECT
    (SELECT count(*) FROM information_schema.role_table_grants
       WHERE grantee = 'ev_api' AND table_schema = 'id_vault' AND table_name = 'sealed_identities')
    +
    (SELECT count(*) FROM information_schema.column_privileges
       WHERE grantee = 'ev_api' AND table_schema = 'id_vault' AND table_name = 'sealed_identities')
    INTO v_ev_api_table;
  IF v_ev_api_table <> 0 THEN
    RAISE EXCEPTION 'ev_api must hold no direct privilege on id_vault.sealed_identities (found %)', v_ev_api_table;
  END IF;

  SELECT has_function_privilege('ev_api',
           'id_vault.seal_upsert(uuid, bytea, bytea, smallint)', 'EXECUTE')
    INTO v_ev_api_execute;
  IF NOT v_ev_api_execute THEN
    RAISE EXCEPTION 'ev_api must have EXECUTE on id_vault.seal_upsert';
  END IF;
END $$;

COMMIT;

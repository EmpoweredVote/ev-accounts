-- CA_0118 — Identity vault store (ev-cto decision 0022, spec 2026-09-17).
-- App can WRITE (seal) but never READ ciphertext; decryption is off-DB.
BEGIN;

CREATE SCHEMA IF NOT EXISTS id_vault;

CREATE TABLE IF NOT EXISTS id_vault.sealed_identities (
  user_id        uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  sealed_name    bytea,
  sealed_address bytea,
  key_version    smallint NOT NULL,
  sealed_at      timestamptz NOT NULL DEFAULT now()
);

-- Lock it down: nobody reads ciphertext through the app roles.
REVOKE ALL ON SCHEMA id_vault FROM PUBLIC;
REVOKE ALL ON id_vault.sealed_identities FROM PUBLIC;
GRANT USAGE ON SCHEMA id_vault TO ev_api;

-- ev_api seals (writes) and may check existence/version/time — never the bytea.
GRANT INSERT, UPDATE, DELETE ON id_vault.sealed_identities TO ev_api;
GRANT SELECT (user_id, key_version, sealed_at) ON id_vault.sealed_identities TO ev_api;

-- Default-deny RLS; a single policy lets ev_api write its rows. No SELECT policy.
ALTER TABLE id_vault.sealed_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE id_vault.sealed_identities FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ev_api_write ON id_vault.sealed_identities;
CREATE POLICY ev_api_write ON id_vault.sealed_identities
  FOR ALL TO ev_api USING (true) WITH CHECK (true);

-- Post-verify gate.
DO $$
DECLARE
  v_has_schema boolean;
  v_has_table  boolean;
  v_select_cols int;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'id_vault')
    INTO v_has_schema;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'id_vault' AND table_name = 'sealed_identities')
    INTO v_has_table;
  -- ev_api must NOT hold SELECT on the ciphertext columns.
  SELECT count(*) INTO v_select_cols
    FROM information_schema.column_privileges
    WHERE grantee = 'ev_api' AND table_schema = 'id_vault'
      AND table_name = 'sealed_identities' AND privilege_type = 'SELECT'
      AND column_name IN ('sealed_name', 'sealed_address');
  IF NOT v_has_schema OR NOT v_has_table THEN
    RAISE EXCEPTION 'id_vault schema/table missing after migration';
  END IF;
  IF v_select_cols <> 0 THEN
    RAISE EXCEPTION 'ev_api must not have SELECT on sealed_% columns (found %)', v_select_cols;
  END IF;
END $$;

COMMIT;

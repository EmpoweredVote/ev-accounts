-- CA_0119 — Null connect.connected_profiles.legal_name after the id_vault backfill.
-- APPLY ONLY IN PHASE C: after the ceremony (Phase B) AND a verified backfill.
-- Guard: refuse to null unless every non-null name is already sealed in the vault.
BEGIN;

DO $$
DECLARE
  v_unsealed int;
BEGIN
  SELECT count(*) INTO v_unsealed
    FROM connect.connected_profiles cp
    WHERE cp.legal_name IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM id_vault.sealed_identities v
        WHERE v.user_id = cp.user_id AND v.sealed_name IS NOT NULL
      );
  IF v_unsealed <> 0 THEN
    RAISE EXCEPTION 'Refusing to null: % profiles have a name not yet sealed in id_vault', v_unsealed;
  END IF;
END $$;

UPDATE connect.connected_profiles
   SET legal_name = NULL
 WHERE legal_name IS NOT NULL;

-- Post-verify gate: zero non-null names remain.
DO $$
DECLARE v_remaining int;
BEGIN
  SELECT count(*) INTO v_remaining FROM connect.connected_profiles WHERE legal_name IS NOT NULL;
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'legal_name null-out incomplete: % remain', v_remaining;
  END IF;
END $$;

COMMIT;

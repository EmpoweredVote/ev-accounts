-- Migration 279: MD 2026 Statewide Races — Phase 96 Plan 02
-- Seeds 12 race rows for the 2026 Maryland General Election:
--   Governor of Maryland (Moore incumbent)
--   Attorney General of Maryland (Brown incumbent)
--   Comptroller of Maryland (Lierman incumbent)
--   U.S. Senate Maryland (Van Hollen — Class 3, up in 2026)
--   U.S. House MD-01 through MD-08 (all 8 congressional districts)
--
-- D-01: One race row per DISTRICT (not per seat). Enforced by UNIQUE (election_id, position_name, primary_party).
-- D-02: Bare primary pattern — all race rows reference the GENERAL election only.
--
-- Omissions (documented):
--   LG Aruna Miller: NOT included — runs on same ticket as Governor; no separate LG race row.
--   Angela Alsobrooks: NOT included — she is Class 2, elected 2024, NOT up until 2028.
--   State Treasurer Dereck Davis: NOT included — is_appointed_position=true (General Assembly-appointed).
--
-- Deviation from ROADMAP: 12 statewide rows match D-01 model exactly.
-- ROADMAP "198 total race rows" was based on a one-row-per-seat model that conflicts with the UNIQUE constraint.
-- Actual total is 130 (12 statewide + 47 senate + 71 SLDL house). See migration 280 for full deviation note.
--
-- All office_ids confirmed from live DB query (Phase 96 research).
-- Idempotent via ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING.

WITH gen_elec AS (
  SELECT id FROM essentials.elections WHERE name = '2026 Maryland General Election' AND state = 'MD'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT gen_elec.id, t.office_id_val::uuid, t.position_name_val, NULL, 1
FROM gen_elec, (VALUES
  ('1a7ac65d-983a-4c62-85bc-d506ea2755a3', 'Governor of Maryland'),
  ('6f9fd58a-442c-4c58-bd6d-f36a1bcbf114', 'Attorney General of Maryland'),
  ('816a9ad0-f2ac-48b3-918a-aa75aa2f9efd', 'Comptroller of Maryland'),
  ('59092640-43df-4dea-bac3-441690c76ad9', 'U.S. Senate Maryland'),
  ('44eb9e42-ae4f-46b0-87dc-a4c8518330d2', 'U.S. House MD-01'),
  ('ff4f5b35-a627-42e3-82cd-d4e287cca040', 'U.S. House MD-02'),
  ('fcb4bb30-cfa4-473e-816a-d67df9c17e91', 'U.S. House MD-03'),
  ('365904b7-b72c-4db4-8312-d4c4534a0abb', 'U.S. House MD-04'),
  ('cabd5f12-6aa6-4742-96da-159660141c89', 'U.S. House MD-05'),
  ('58e6825b-aa32-4532-8952-b8c94d83c371', 'U.S. House MD-06'),
  ('7d1685dd-f832-4bf7-8f60-b8ee40152049', 'U.S. House MD-07'),
  ('21839e79-ac55-4733-b517-db000431a9c1', 'U.S. House MD-08')
) AS t(office_id_val, position_name_val)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Ledger entry
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('279')
ON CONFLICT (version) DO NOTHING;

-- Post-verification: confirm exactly 12 MD statewide race rows were seeded
-- Note: only checks rows inserted by this migration (non-legislative races)
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.state = 'MD' AND e.name = '2026 Maryland General Election'
    AND r.position_name IN (
      'Governor of Maryland',
      'Attorney General of Maryland',
      'Comptroller of Maryland',
      'U.S. Senate Maryland',
      'U.S. House MD-01', 'U.S. House MD-02', 'U.S. House MD-03', 'U.S. House MD-04',
      'U.S. House MD-05', 'U.S. House MD-06', 'U.S. House MD-07', 'U.S. House MD-08'
    );
  IF v_count <> 12 THEN
    RAISE EXCEPTION 'Expected 12 MD statewide race rows, found %', v_count;
  END IF;
END $$;

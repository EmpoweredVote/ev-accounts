-- Migration 324: VA 2026 Federal Races — Phase 105 Plan 02
--
-- Seeds 12 race rows for the 2026 Virginia General Election:
--   U.S. Senate Virginia (Mark Warner — Class 2, up in 2026)
--   U.S. House VA-01 through VA-11 (all 11 congressional districts)
--
-- Omissions (documented):
--   Governor, LG, AG: NOT included — no 2026 VA state-exec races.
--     VA gubernatorial cycle is odd-year (next: Nov 2025 was completed; 2029 is next).
--     These are NOT 2026 elections.
--   Tim Kaine: NOT included — Class 1, elected 2024, NOT up until 2030.
--   VA state legislature: NOT included — HoD was Nov 2025; VA Senate is 2027.
--   The universe is exactly 12 rows: Warner Class 2 Senate seat + 11 VA House CDs.
--
-- All office_ids confirmed from live DB queries (Phase 102 Summary + Task 1 resolution):
--   Warner external_id=-400080 → office_id=6204cbda-f055-46db-962d-98ddf945060e
--   VA House external_ids -5102001..-5102011 → geo_ids 5101-5111 (VA-01 through VA-11)
--
-- election_id: resolved via subquery on '2026 Virginia General Election' (seeded in migration 322).
-- Idempotent via ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING.

WITH gen_elec AS (
  SELECT id FROM essentials.elections WHERE name = '2026 Virginia General Election' AND state = 'VA'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT gen_elec.id, t.office_id_val::uuid, t.position_name_val, NULL, 1
FROM gen_elec, (VALUES
  ('6204cbda-f055-46db-962d-98ddf945060e', 'U.S. Senate Virginia'),
  ('7606b2c5-9628-4f3b-a3da-18f4296e3195', 'U.S. House VA-01'),
  ('1439154d-60ef-4186-bff5-8e37465dd596', 'U.S. House VA-02'),
  ('b6343762-c378-4684-ae88-1749b3eefee5', 'U.S. House VA-03'),
  ('baf80dc1-633b-4774-9f9e-701cd50844df', 'U.S. House VA-04'),
  ('39211b8a-e499-4afd-be63-080dda9a68f5', 'U.S. House VA-05'),
  ('5f797901-0cbd-45d9-81f1-060daeee3f1d', 'U.S. House VA-06'),
  ('86664ec7-aabe-46c7-a1a0-dded71fccfc2', 'U.S. House VA-07'),
  ('3c3b3be6-5390-4748-ae16-553feb2f61bb', 'U.S. House VA-08'),
  ('1e2d3f80-252f-48a2-a1bf-b2470436340c', 'U.S. House VA-09'),
  ('5bc6c218-6992-4ff8-b982-d2d0d17a4b70', 'U.S. House VA-10'),
  ('c4119341-e717-483c-b295-8e117125e046', 'U.S. House VA-11')
) AS t(office_id_val, position_name_val)
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

-- Ledger entry
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('324')
ON CONFLICT (version) DO NOTHING;

-- Post-verification: confirm exactly 12 VA federal race rows were seeded
-- Note: only checks rows inserted by this migration (12 specific position_names)
-- to remain idempotent if future plans add more VA races.
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.state = 'VA' AND e.name = '2026 Virginia General Election'
    AND r.position_name IN (
      'U.S. Senate Virginia',
      'U.S. House VA-01', 'U.S. House VA-02', 'U.S. House VA-03', 'U.S. House VA-04',
      'U.S. House VA-05', 'U.S. House VA-06', 'U.S. House VA-07', 'U.S. House VA-08',
      'U.S. House VA-09', 'U.S. House VA-10', 'U.S. House VA-11'
    );
  IF v_count <> 12 THEN
    RAISE EXCEPTION 'Expected 12 VA 2026 federal race rows, found %', v_count;
  END IF;
END $$;

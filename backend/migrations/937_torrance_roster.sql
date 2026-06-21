-- 937_torrance_roster.sql
-- Phase 148 (Torrance Deep-Seed), Plan 02 — STRUCTURAL roster link-repair (registers in schema_migrations).
-- Idempotent. After 936 the survivor chamber f6fcb0ba holds 7 offices; the 3 offices moved from the doomed
-- chamber (Chen/Mattucci/Sheikh) have offices.politician_id set but politicians.office_id was left NULL.
-- This repairs those 3 back-pointers and affirms official_count=7. NO member creation / retirement
-- (ROSTER OVERRIDE: current 7-member council — Chen Mayor + Gerson/Kaji/Kalani/Bridgett-Lewis/Mattucci/Sheikh).

BEGIN;

-- Repair 3 broken back-pointers (resolve office by external_id; guard on IS DISTINCT FROM).
UPDATE essentials.politicians SET office_id = 'c5b5b1b3-6e68-41a0-9722-b02d9e1e34f3'
  WHERE external_id = -201036 AND office_id IS DISTINCT FROM 'c5b5b1b3-6e68-41a0-9722-b02d9e1e34f3';  -- Chen (Mayor)
UPDATE essentials.politicians SET office_id = '220e2cb5-f268-423a-b9a8-2f187f94d9b5'
  WHERE external_id = -201103 AND office_id IS DISTINCT FROM '220e2cb5-f268-423a-b9a8-2f187f94d9b5';  -- Mattucci
UPDATE essentials.politicians SET office_id = '0542b22b-61e1-4a3d-be3c-104a33252d21'
  WHERE external_id = -201102 AND office_id IS DISTINCT FROM '0542b22b-61e1-4a3d-be3c-104a33252d21';  -- Sheikh

-- Affirm survivor official_count = 7 (the 4 survivor members are already correctly linked — untouched).
UPDATE essentials.chambers SET official_count = 7
  WHERE id = 'f6fcb0ba-bc72-4176-9ca3-dc6c9973301d' AND official_count IS DISTINCT FROM 7;

-- Register structural migration 937 (idempotent).
INSERT INTO supabase_migrations.schema_migrations (version, name)
SELECT '937', 'torrance_roster'
WHERE NOT EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations WHERE version = '937');

COMMIT;

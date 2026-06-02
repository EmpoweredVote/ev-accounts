-- Migration 236: Fix OR legislator names — restore Unicode diacritics + add ASCII alternate_names
-- Applied: 2026-05-30
--
-- Phase 75 (migration 227) used PowerShell [char] escape sequences to produce diacritical
-- names for two OR House reps. Two bugs occurred:
--
--   1. HD-38 Daniel Nguyễn: the PowerShell generator used [char]0x1EBF (ế, e-circumflex-acute)
--      instead of [char]0x1EC5 (ễ, e-circumflex-tilde). The resulting INSERT stored
--      'Daniel Nguyến' — a non-word. The correct Vietnamese family name is Nguyễn (U+1EC5).
--
--   2. Migration 227 used ON CONFLICT (external_id) DO NOTHING. If either row already existed
--      (from earlier dev seeding with ASCII names), the INSERT was silently skipped and the
--      DB retained the ASCII version. Both rows currently have pure-ASCII full_name values.
--
-- Fix:
--   - Set full_name / first_name / last_name to the correct Unicode spellings.
--   - Populate alternate_names with the ASCII-only versions so search still works when
--     a user types without diacritics ("Daniel Nguyen", "Thuy Tran").
--
-- Target rows:
--   external_id=-4120038  Daniel Nguyễn  HD-38
--   external_id=-4120045  Thủy Trần      HD-45
--
-- Idempotency: UPDATE to already-correct values is a no-op.

BEGIN;

-- HD-38: Daniel Nguyễn (U+1EC5 for ễ)
UPDATE essentials.politicians
SET
  full_name        = 'Daniel Nguy' || chr(7877) || 'n',
  first_name       = 'Daniel',
  last_name        = 'Nguy' || chr(7877) || 'n',
  alternate_names  = ARRAY['Daniel Nguyen']
WHERE external_id = -4120038;

-- HD-45: Thủy Trần (U+1EE7=ủ for Thủy, U+1EA7=ầ for Trần)
UPDATE essentials.politicians
SET
  full_name        = 'Th' || chr(7911) || 'y Tr' || chr(7847) || 'n',
  first_name       = 'Th' || chr(7911) || 'y',
  last_name        = 'Tr' || chr(7847) || 'n',
  alternate_names  = ARRAY['Thuy Tran']
WHERE external_id = -4120045;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('236')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- 936_torrance_reconcile.sql
-- Phase 148 (Torrance Deep-Seed), Plan 01 — STRUCTURAL reconcile (registers in schema_migrations).
-- Idempotent. Fixes the pre-existing partial/duplicate-chamber Torrance seed:
--   1. backfill geo_id '0680000' on gov b3e97e65 (guard empty/NULL)
--   2. DELETE the Brigitte-Lewis typo duplicate (-201101 / 7f74014f) office-first then politician
--   3. resolve the shared At-Large district (Brigitte/Mattucci/Sheikh all on 84e45ab7):
--        keep Mattucci on 84e45ab7, CREATE one new At-Large LOCAL row, REPOINT Sheikh to it
--   4. MERGE the duplicate chamber: move the 3 remaining doomed-chamber offices (Chen/Mattucci/Sheikh)
--      into the survivor f6fcb0ba, assert doomed is empty, DELETE doomed chamber 2583b565
-- ⚠ Torrance is AT-LARGE — labels stay 'At-Large'; the LOCAL_EXEC 'Torrance Mayor' a99b86b0 is preserved.
-- Does NOT repair back-pointers / set official_count / retire anyone (all Plan 02).

BEGIN;

-- (1) geo_id backfill (Pitfall 8: empty-string guard)
UPDATE essentials.governments
SET geo_id = '0680000'
WHERE id = 'b3e97e65-2b89-4594-b38e-65c531fa801c'
  AND (geo_id IS NULL OR geo_id = '');

-- (2) DELETE the Brigitte-Lewis typo duplicate (office first, then dependent contact, then politician).
--     0 stances / 0 images; her only FK dependent is one essentials.politician_contacts row.
DELETE FROM essentials.offices            WHERE id = 'bf157ee7-0229-4ab2-98ce-3e5e004f7a20';
DELETE FROM essentials.politician_contacts WHERE politician_id = '7f74014f-1a20-4f11-a00d-28b12135d18d';
DELETE FROM essentials.politicians        WHERE id = '7f74014f-1a20-4f11-a00d-28b12135d18d';

-- (3) Shared-At-Large fix (NOT a by-district relabel). New 'At-Large' LOCAL row created ONLY while
--     Sheikh's office still points at the shared 84e45ab7 (idempotent: no-op on re-run), then Sheikh repointed.
WITH new_dist AS (
  INSERT INTO essentials.districts (label, district_type, geo_id, state)
  SELECT 'At-Large', 'LOCAL', '0680000', 'CA'
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices
    WHERE id = '0542b22b-61e1-4a3d-be3c-104a33252d21'
      AND district_id = '84e45ab7-b30f-44ad-b379-b83dc6cedb8f'
  )
  RETURNING id
)
UPDATE essentials.offices o
SET district_id = (SELECT id FROM new_dist)
WHERE o.id = '0542b22b-61e1-4a3d-be3c-104a33252d21'
  AND o.district_id = '84e45ab7-b30f-44ad-b379-b83dc6cedb8f'
  AND EXISTS (SELECT 1 FROM new_dist);
-- Mattucci's office 220e2cb5 KEEPS 84e45ab7 (not repointed).

-- (4) MERGE — move the 3 remaining doomed-chamber offices (Chen c5b5b1b3, Mattucci 220e2cb5, Sheikh 0542b22b)
--     into the survivor f6fcb0ba (target by doomed chamber UUID only — both chambers share the name 'City Council').
UPDATE essentials.offices
SET chamber_id = 'f6fcb0ba-bc72-4176-9ca3-dc6c9973301d'
WHERE chamber_id = '2583b565-7f75-4e32-b150-24db4792ea51';

-- (5) Inline assert: the doomed chamber must be empty before deletion.
DO $$
DECLARE n INT;
BEGIN
  SELECT COUNT(*) INTO n FROM essentials.offices WHERE chamber_id = '2583b565-7f75-4e32-b150-24db4792ea51';
  IF n <> 0 THEN
    RAISE EXCEPTION 'ABORT 936: doomed chamber 2583b565 still has % office(s) — refusing to delete', n;
  END IF;
END $$;

-- (6) DELETE the duplicate chamber by UUID only.
DELETE FROM essentials.chambers WHERE id = '2583b565-7f75-4e32-b150-24db4792ea51';

-- Register structural migration 936 in the ledger (idempotent).
INSERT INTO supabase_migrations.schema_migrations (version, name)
SELECT '936', 'torrance_reconcile'
WHERE NOT EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations WHERE version = '936');

COMMIT;

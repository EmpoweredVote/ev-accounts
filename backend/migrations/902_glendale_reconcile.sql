-- 902_glendale_reconcile.sql
-- Phase 144 / Plan 01 — Glendale structural reconcile (idempotent).
--
-- Reconciles the EXISTING partial, duplicate-chamber Glendale seed (gov
-- a7433437-341a-48e7-907e-a61318954f0a). NO greenfield rebuild. Simpler than SC 894:
-- no member retirement here (Najarian retires in Wave 2, plan 02), and the duplicate
-- chamber is EMPTY (0 offices) — no member migration before deletion.
--
-- PRE-FLIGHT (DB-verified 2026-06-19):
--   gov a7433437  geo_id NULL (state 'CA')  → set geo_id '0630000'
--   Two chambers under the gov, BOTH named 'City Council':
--     KEEP   771727ec-684b-4eb8-98a6-d7205d9bbac0  external_id 10450    (5 offices, official_count 5)
--     DELETE c019a553-e888-4338-abf1-8adbd86f9c00  external_id -200687  (0 offices — empty duplicate)
--   Survivor offices (all 'Councilmember'): Najarian c6f4e77d/-700100, Kassakhian b1c10c09/686339,
--     Brotman 0b17284a/686340, Asatryan 615de18c/686337, Gharpetian c728231c/686336.
--   Rotational Mayor (D-08/D-09): Kassakhian (686339) selected Mayor April 2026 → flag title on his
--     EXISTING seat (office b1c10c09). NO separate LOCAL_EXEC row. Other 4 seats stay 'Councilmember'.
--
-- chambers.slug is GENERATED — never written. All statements idempotent. Structural migration 902
-- (registers in supabase_migrations.schema_migrations; ledger MAX was 895, 896-901 audit-only).

BEGIN;

-- (1) geo_id backfill (D-01 / D-02 / GLEN-01). Guarded WHERE geo_id IS NULL → re-run is a no-op.
UPDATE essentials.governments
   SET geo_id = '0630000'
 WHERE id = 'a7433437-341a-48e7-907e-a61318954f0a'
   AND geo_id IS NULL;

-- (2) Assert the duplicate chamber is empty before deleting it (Pitfall 5).
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'c019a553-e888-4338-abf1-8adbd86f9c00') > 0 THEN
    RAISE EXCEPTION 'Chamber c019a553 has offices — aborting delete (expected 0)';
  END IF;
END $$;

-- (3) DELETE the empty duplicate chamber by UUID ONLY (both share the name 'City Council'). (D-03)
DELETE FROM essentials.chambers
 WHERE id = 'c019a553-e888-4338-abf1-8adbd86f9c00';

-- (4) Flag Kassakhian's EXISTING seat as Mayor (D-08/D-09). Guarded title <> 'Mayor'.
--     No separate LOCAL_EXEC district/chamber/Mayor office; other 4 seats untouched.
UPDATE essentials.offices
   SET title = 'Mayor'
 WHERE id = 'b1c10c09-a6ba-4623-aae4-28a08ffca09c'
   AND title <> 'Mayor';

-- Register structural migration (D-04).
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('902')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================================================================
-- POST-VERIFICATION (run after apply; not part of the transaction)
-- ============================================================================
-- (a) gov geo_id = '0630000'
--   SELECT geo_id FROM essentials.governments WHERE id='a7433437-341a-48e7-907e-a61318954f0a';
-- (b) exactly ONE chamber under the gov (duplicate c019a553 / -200687 gone)
--   SELECT COUNT(*) FROM essentials.chambers WHERE government_id='a7433437-341a-48e7-907e-a61318954f0a';
--   SELECT COUNT(*) FROM essentials.chambers WHERE external_id='-200687';   -- expect 0
-- (c) Kassakhian office b1c10c09 title='Mayor'; other 4 seats 'Councilmember'
--   SELECT id, title FROM essentials.offices WHERE chamber_id='771727ec-684b-4eb8-98a6-d7205d9bbac0';
-- (d) survivor official_count = 5
--   SELECT official_count FROM essentials.chambers WHERE id='771727ec-684b-4eb8-98a6-d7205d9bbac0';
-- (e) feedback_section_split_check — expect Glendale ABSENT (0 rows for it)
-- (f) migration 902 registered
--   SELECT version FROM supabase_migrations.schema_migrations WHERE version='902';

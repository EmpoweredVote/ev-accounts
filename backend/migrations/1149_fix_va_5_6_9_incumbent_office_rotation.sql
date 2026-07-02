-- 1149_fix_va_5_6_9_incumbent_office_rotation.sql
-- Fix a PRE-EXISTING incumbent office->district rotation bug for VA-5/6/9 surfaced during Phase 159-03.
-- essentials.offices linked: CD-5(geo 5105)->Cline, CD-6(5106)->Griffith, CD-9(5109)->McGuire.
-- True 2026 delegation (GovTrack/Wikipedia + districts OCD labels cd:5/6/9):
--   VA-5 = John McGuire, VA-6 = Ben Cline, VA-9 = Morgan Griffith.
-- Fix: 3-cycle swap of offices.politician_id + the matching politicians.office_id back-refs.
-- No unique constraint on politician_id/office_id (verified) -> transient dup mid-txn is safe.
-- Guarded on expected-current (wrong) values -> idempotent (re-run = 0 rows once corrected).
-- Office titles are generic "U.S. Representative" (not person-specific); district_id untouched.
BEGIN;

-- offices.politician_id: point each CD office at its TRUE 2026 holder
UPDATE essentials.offices SET politician_id = 'e603fa67-7992-409e-a1e2-1385c32dc217'  -- McGuire
  WHERE id = '39211b8a-e499-4afd-be63-080dda9a68f5'  -- CD-5 office
    AND politician_id = 'e4deeac3-b172-473d-9696-a07d874f4795';  -- was Cline
UPDATE essentials.offices SET politician_id = 'e4deeac3-b172-473d-9696-a07d874f4795'  -- Cline
  WHERE id = '5f797901-0cbd-45d9-81f1-060daeee3f1d'  -- CD-6 office
    AND politician_id = '12eef223-444e-4bed-8081-f1fd26c43e42';  -- was Griffith
UPDATE essentials.offices SET politician_id = '12eef223-444e-4bed-8081-f1fd26c43e42'  -- Griffith
  WHERE id = '1e2d3f80-252f-48a2-a1bf-b2470436340c'  -- CD-9 office
    AND politician_id = 'e603fa67-7992-409e-a1e2-1385c32dc217';  -- was McGuire

-- politicians.office_id back-refs: point each rep at their TRUE district office
UPDATE essentials.politicians SET office_id = '39211b8a-e499-4afd-be63-080dda9a68f5'  -- CD-5 office
  WHERE external_id = -5102009  -- McGuire
    AND office_id = '1e2d3f80-252f-48a2-a1bf-b2470436340c';  -- was CD-9
UPDATE essentials.politicians SET office_id = '5f797901-0cbd-45d9-81f1-060daeee3f1d'  -- CD-6 office
  WHERE external_id = -5102005  -- Cline
    AND office_id = '39211b8a-e499-4afd-be63-080dda9a68f5';  -- was CD-5
UPDATE essentials.politicians SET office_id = '1e2d3f80-252f-48a2-a1bf-b2470436340c'  -- CD-9 office
  WHERE external_id = -5102006  -- Griffith
    AND office_id = '5f797901-0cbd-45d9-81f1-060daeee3f1d';  -- was CD-6

COMMIT;

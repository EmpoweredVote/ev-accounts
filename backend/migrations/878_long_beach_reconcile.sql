-- Migration 878: Long Beach reconcile / data hygiene
-- Phase 142 (v17.0 LA County City Coverage — Wave 2). Applied: 2026-06-19
--
-- Long Beach was already partially seeded (v7.0 + migration 294). This migration
-- RECONCILES the existing structure before roster completion (879), headshots (880),
-- and stances (881-893). NOT a greenfield build — every statement is an UPDATE/DELETE
-- against existing rows, fully idempotent (re-apply changes 0 rows, raises no error).
--
-- Five fixes, all DB-verified live 2026-06-19 (gov 5e5c3e0b-5479-4759-ac7e-2ea0aecabd38):
--   1. Backfill gov geo_id NULL -> '0643000'                                  (D-07)
--   2. Rename Mayor chamber 867f4e3f -> 'Mayor of Long Beach'                 (D-08)
--      (eliminates the duplicate name_formal 'Long Beach City Council' shared by
--       both chambers — the split-section render risk)
--   3. Dedupe the 3 officials that had 2 politician_images rows -> 1 each     (D-09)
--   4. Back-fill Rex Richardson (-200813) politicians.office_id (Mayor link)  (D-10)
--   5. Relabel the 8 council districts 'At-Large' -> 'District 1'..'District 9' (Open Q2)
--
-- NOTE: essentials.chambers.slug is a GENERATED column — never written here.
-- NOTE: flat-district pattern preserved (D-06) — geo_id and district_id unchanged;
--       only the human-readable label is corrected.

BEGIN;

-- 1. geo_id backfill (D-07)
UPDATE essentials.governments
SET geo_id = '0643000'
WHERE id = '5e5c3e0b-5479-4759-ac7e-2ea0aecabd38' AND geo_id IS NULL;

-- 2. Mayor chamber rename (D-08) — target by ID only (two chambers share name_formal);
--    do NOT touch slug (GENERATED).
UPDATE essentials.chambers
SET name = 'Mayor of Long Beach', name_formal = 'Mayor of Long Beach'
WHERE id = '867f4e3f-2be9-4d55-955d-796a3e5bc0a8';

-- 3. Image dedupe (D-09) — delete the specific duplicate row id; keep press_use where present.
--    Megan Kerr + Roberto Uranga had two scraped_no_license copies; one kept (license upgrade
--    handled in the Wave 3 image audit). Scoped by id — never bulk-delete by politician_id.
DELETE FROM essentials.politician_images WHERE id IN (
  '230a4412-1b63-4c30-989f-4d2af4ee63cc',  -- Cindy Allen 665831 (scraped_no_license; keep press_use 677466b1)
  '9e12052f-de51-46b9-8ce7-0710c0141aab',  -- Megan Kerr 665835 (dup scraped_no_license; keep f8f0a103)
  '40d4cf42-5fdd-4cff-b1e8-c3b5fb5ca99d'   -- Roberto Uranga 665839 (dup scraped_no_license; keep 20666df2)
);

-- 4. Rex Richardson office_id back-fill (D-10) — office 06c1def0 already links to him; fix reverse link.
UPDATE essentials.politicians
SET office_id = '06c1def0-1f1b-4b9a-97a3-dc2903083edc'
WHERE external_id = -200813 AND office_id IS NULL;

-- 5. Council district relabel (Open Q2) — label-only; geo_id/district_id unchanged (flat-district D-06).
UPDATE essentials.districts SET label = 'District 1' WHERE id = 'd88287fc-a517-4ccf-ae19-3a1157e9a355'; -- Zendejas 665830
UPDATE essentials.districts SET label = 'District 2' WHERE id = 'f2c28800-aec2-4701-afd9-a9c88e4dd524'; -- Allen 665831
UPDATE essentials.districts SET label = 'District 3' WHERE id = 'ce0a9c5f-f023-4d79-b425-557d49d423a4'; -- Duggan 665833
UPDATE essentials.districts SET label = 'District 4' WHERE id = '3b572a06-15cc-4ef3-a7d1-dd49cafdbf66'; -- Supernaw 665834
UPDATE essentials.districts SET label = 'District 5' WHERE id = 'e1c0c7a5-ed86-4ef1-9353-1d927ecb7788'; -- Kerr 665835
UPDATE essentials.districts SET label = 'District 6' WHERE id = '550852d9-c36f-4ac8-b8f9-eed814a87359'; -- Saro 665838
UPDATE essentials.districts SET label = 'District 7' WHERE id = '98bb0066-86c9-4ccd-a3c1-22d42a38efcb'; -- Uranga 665839
UPDATE essentials.districts SET label = 'District 9' WHERE id = '222a811c-38fe-474f-94a1-053d702466e7'; -- Ricks-Oddie 665842
-- (District 8 is the missing seat — created/labeled in migration 879.)

COMMIT;

-- ── Post-verification (run after apply; all must pass) ──────────────────────────
-- 1. SELECT geo_id FROM essentials.governments WHERE id='5e5c3e0b-5479-4759-ac7e-2ea0aecabd38';            -> '0643000'
-- 2. SELECT COUNT(*) FROM essentials.chambers WHERE government_id='5e5c3e0b-...' AND name_formal='Long Beach City Council'; -> 1
-- 3. SELECT politician_id,COUNT(*) FROM essentials.politician_images GROUP BY 1 HAVING COUNT(*)>1 (LB officials); -> 0 rows
-- 4. SELECT office_id FROM essentials.politicians WHERE external_id=-200813;                                -> 06c1def0...
-- 5. SELECT label FROM essentials.districts (8 council) -> 'District 1'..'District 9', no 'At-Large'
-- 6. split-section check (duplicate name_formal within government) -> 0 rows

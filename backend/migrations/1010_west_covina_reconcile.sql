-- 1010_west_covina_reconcile.sql
-- Phase 152 Wave 1 (WCOV-01): reconcile City of West Covina structural defects.
-- Gov 1982a9fa-dc56-482d-83fc-27bf69458b22 'City of West Covina, California, US'.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-21 (152-01 Task 1).
--
-- WEST COVINA IS BY-DISTRICT WITH A ROTATIONAL MAYOR (RESEARCH §D-02 Resolution; Ordinance
-- No. 2310 Jan 17 2017 + Sanchez v. City of West Covina CVRA settlement; first district
-- elections Nov 2018): FIVE single-member council districts (D1-D5) + a ROTATIONAL
-- council-selected Mayor (a TITLE on a seat, NOT a separate office). This OVERTURNS the
-- CONTEXT.md At-Large default. Palmdale (146) / Pasadena (149) / El Monte (151) by-district
-- relabel pattern for the council seats; Palmdale (146) / Glendale (144) rotational-mayor-as-
-- title model -- NOT the El Monte (151) / Lancaster (145) directly-elected-LOCAL_EXEC model.
--
-- Fixes:
--   (1) Backfill geo_id '0684200' (was NULL), empty-string-safe.
--   (2) Merge the two duplicate 'City Council' chambers via move-then-delete:
--       move BOTH doomed-chamber (b1a2c4cb) offices -- Diaz abd27abb + Gutierrez 0f3cce5f --
--       into the survivor 12c9360a FIRST, assert the doomed chamber is empty, THEN delete it.
--   (3) Repair the two one-directional links (CONTEXT D-01b): Diaz pol f5bf4ec4 + Gutierrez
--       pol 22fc2cdc have politicians.office_id NULL -> set to match offices.politician_id.
--   (4) BY-DISTRICT form of government: relabel/create district rows D1-D5 per RESEARCH §D-02/D-03.
--       Pre-flight found a 2-WAY shared-district defect: row 0e70a17e 'At-Large' had 2 office refs
--       (Diaz abd27abb, Gutierrez 0f3cce5f). The other three occupants have their own rows.
--         NEW row   -> 'District 3', repoint Diaz (office abd27abb) off the shared row
--         0e70a17e  -> relabel 'District 1' (keep Gutierrez, office 0f3cce5f)
--         adf5b635  -> relabel 'District 2' (Lopez-Viado's own row, office 4a8f2fd6; Mayor -- title is Plan 02)
--         85817d95  -> relabel 'District 4' (Cantos's own row, office 50471af9; Mayor Pro Tem -- title is Plan 02)
--         970809db  -> relabel 'District 5' (Wu's own row, office 65bf4e71)
--   (5) DELETE a pre-existing ORPHAN 'West Covina Mayor' LOCAL_EXEC district row (31a431df,
--       geo_id 0684200) -- pre-flight confirmed NO office references it. West Covina's mayor is
--       rotational (no separate Mayor office), so this stale row is removed; end-state = ZERO
--       LOCAL_EXEC rows under geo_id 0684200. Guarded (only deletes if still office-less).
--       [DEVIATION from plan pre-flight assumption "no LOCAL_EXEC row present" -- documented in
--        152-01-SUMMARY; deletion serves the plan's own ZERO-LOCAL_EXEC acceptance criterion.]
--
-- OUT OF SCOPE (untouched): the same-name West Covina Unified School District gov
--   131e33d0-e40a-4aaf-bc8d-c665750d1b6d. NEVER touched here.
--   (official_count, Mayor/Mayor-Pro-Tem TITLES, live-roster verify are all Plan 02 / mig 1011.)

BEGIN;

-- (1) geo_id backfill (empty-string-safe)
UPDATE essentials.governments
   SET geo_id = '0684200'
 WHERE id = '1982a9fa-dc56-482d-83fc-27bf69458b22'
   AND (geo_id IS NULL OR geo_id = '');

-- (2) MERGE duplicate chamber -- move BOTH doomed-chamber offices into the survivor FIRST.
-- Target by UUID ONLY (both chambers share name 'City Council' / slug 'west-covina-city-council').
UPDATE essentials.offices
   SET chamber_id = '12c9360a-60ac-476f-b2ac-055a26e891a0'
 WHERE chamber_id = 'b1a2c4cb-25b6-46c8-a3ab-852024e00f45';

-- Assert the doomed chamber is empty before deleting it.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
        WHERE chamber_id = 'b1a2c4cb-25b6-46c8-a3ab-852024e00f45') > 0 THEN
    RAISE EXCEPTION 'Chamber b1a2c4cb still has offices; aborting before delete';
  END IF;
END $$;

DELETE FROM essentials.chambers WHERE id = 'b1a2c4cb-25b6-46c8-a3ab-852024e00f45';

-- (3) Repair the two one-directional links (CONTEXT D-01b). The other 3 (Lopez-Viado/Cantos/Wu)
-- are already bidirectional. Guarded IS DISTINCT FROM.
UPDATE essentials.politicians
   SET office_id = 'abd27abb-42c6-4734-b683-5fac4d978174'
 WHERE id = 'f5bf4ec4-7d1b-460e-b4e2-539826c59596'
   AND office_id IS DISTINCT FROM 'abd27abb-42c6-4734-b683-5fac4d978174'; -- Diaz
UPDATE essentials.politicians
   SET office_id = '0f3cce5f-9509-4268-a3fe-2ce972ead493'
 WHERE id = '22fc2cdc-2f51-4d81-8814-4b54b2bc6582'
   AND office_id IS DISTINCT FROM '0f3cce5f-9509-4268-a3fe-2ce972ead493'; -- Gutierrez

-- (4) BY-DISTRICT relabel + split the 2-way shared-district defect on 0e70a17e.
-- Create a NEW row for the displaced occupant (Diaz D3). Guarded.
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 3', 'LOCAL', '0684200', 'CA'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE label = 'District 3' AND geo_id = '0684200');

-- Repoint Diaz off the shared row 0e70a17e to the new 'District 3' row.
UPDATE essentials.offices
   SET district_id = (SELECT id FROM essentials.districts WHERE label = 'District 3' AND geo_id = '0684200')
 WHERE id = 'abd27abb-42c6-4734-b683-5fac4d978174'
   AND district_id IS DISTINCT FROM
       (SELECT id FROM essentials.districts WHERE label = 'District 3' AND geo_id = '0684200'); -- Diaz

-- Relabel the single-occupant rows (label only; district_type/geo_id/state unchanged; guarded).
-- 0e70a17e now holds only Gutierrez after the Diaz repoint above.
UPDATE essentials.districts SET label = 'District 1'
 WHERE id = '0e70a17e-2ed9-434b-bfac-284eae4a1358' AND label IS DISTINCT FROM 'District 1'; -- Gutierrez
UPDATE essentials.districts SET label = 'District 2'
 WHERE id = 'adf5b635-a285-4be8-967b-8e3546ea26c5' AND label IS DISTINCT FROM 'District 2'; -- Lopez-Viado (Mayor)
UPDATE essentials.districts SET label = 'District 4'
 WHERE id = '85817d95-d3f2-4b75-89ac-6a1fe05a249d' AND label IS DISTINCT FROM 'District 4'; -- Cantos (Mayor Pro Tem)
UPDATE essentials.districts SET label = 'District 5'
 WHERE id = '970809db-0230-46d3-85ea-ebe85eb6b290' AND label IS DISTINCT FROM 'District 5'; -- Wu

-- (5) Remove the ORPHAN 'West Covina Mayor' LOCAL_EXEC district row (no office references it;
-- West Covina's mayor is rotational). Guarded: only deletes if still office-less.
DELETE FROM essentials.districts d
 WHERE d.id = '31a431df-41f4-4476-92a4-d649d0def583'
   AND d.district_type = 'LOCAL_EXEC'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

COMMIT;

-- Register structural migration in the ledger.
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1010', 'west_covina_reconcile')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. gov geo_id = '0684200', state 'CA'
--    SELECT geo_id, state FROM essentials.governments WHERE id='1982a9fa-dc56-482d-83fc-27bf69458b22';
-- 2. exactly one 'City Council' chamber (survivor 12c9360a); b1a2c4cb gone
--    SELECT id, name FROM essentials.chambers WHERE government_id='1982a9fa-dc56-482d-83fc-27bf69458b22';
-- 3. survivor 12c9360a has 5 offices
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='12c9360a-60ac-476f-b2ac-055a26e891a0';
-- 4. all 5 survivor offices bidirectional (politicians.office_id <-> offices.politician_id)
-- 5. council seats D1-D5 (LOCAL, 5 rows, each office on a DISTINCT district_id):
--    D1 Gutierrez / D2 Lopez-Viado / D3 Diaz / D4 Cantos / D5 Wu
-- 6. ZERO LOCAL_EXEC rows for geo_id '0684200' (orphan Mayor row removed; rotational mayor)
-- 7. feedback_section_split_check -> 0 rows for West Covina (geo_id '0684200')
-- 8. migration 1010 registered in schema_migrations

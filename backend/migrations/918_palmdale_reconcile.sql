-- 918_palmdale_reconcile.sql
-- Phase 146 (Palmdale deep-seed) Wave 1 — STRUCTURAL (registers in schema_migrations)
-- Reconcile the pre-existing partial Palmdale seed:
--   (1) backfill geo_id '0655156' on gov 4f59ebad (was NULL)
--   (2) merge the duplicate 'City Council' chamber (move office 198661de then delete c8e8d31e)
--   (3) relabel 4 At-Large district rows to their occupant's real district (D1/D2/D4/D5)
--   (4) create a new District 3 row for Bettencourt (her office/politician are Plan 02)
--   (5) set survivor chamber official_count=4 (accurate pre-Plan-02 count; Plan 02 sets 5)
-- Mayor flag, Bishop back-pointer repair, Bettencourt create/seat are Plan 02 (919).
-- DB-verified live state 2026-06-20. Idempotent: re-running changes 0 rows.

BEGIN;

-- (1) geo_id backfill (guarded WHERE geo_id IS NULL — idempotent)
UPDATE essentials.governments
SET geo_id = '0655156'
WHERE id = '4f59ebad-631b-4340-91f0-091a6cecb3bb' AND geo_id IS NULL;

-- (2a) MOVE Bishop's office (198661de) from duplicate c8e8d31e into survivor 000d672d
--      Target the duplicate by its chamber UUID only (both chambers share name/slug).
--      This UPDATE is idempotent: if chamber_id is already 000d672d, 0 rows change.
UPDATE essentials.offices
SET chamber_id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
WHERE chamber_id = 'c8e8d31e-c9f2-4d50-9a94-66be603a5c45';

-- (2b) Assert the duplicate chamber is now empty before deleting it (Lancaster 910 pattern)
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
      WHERE chamber_id = 'c8e8d31e-c9f2-4d50-9a94-66be603a5c45') > 0 THEN
    RAISE EXCEPTION 'Chamber c8e8d31e-c9f2-4d50-9a94-66be603a5c45 still has offices — aborting delete';
  END IF;
END $$;

-- (2c) DELETE the emptied duplicate chamber (UUID-targeted only — never by name/slug)
DELETE FROM essentials.chambers WHERE id = 'c8e8d31e-c9f2-4d50-9a94-66be603a5c45';

-- (3) Relabel the 4 occupied At-Large district rows to their occupant's real district.
--     Each UPDATE is keyed on exact UUID and guarded label IS DISTINCT FROM target
--     so a re-run changes 0 rows. district_type, geo_id, state are NOT touched.
--     Pitfall: these 4 UUIDs map non-obviously to districts — use ONLY these (RESEARCH §Pitfall 2):
--       f61fd139 → District 1 (Bishop's district)
--       6ad1e005 → District 2 (Loa's district)
--       a1d3e3bf → District 4 (Ohlsen's district)
--       7fe09a06 → District 5 (Alarcón's district)

UPDATE essentials.districts SET label = 'District 1'
WHERE id = 'f61fd139-b621-48d7-b06d-784ebfe9192e'
  AND label IS DISTINCT FROM 'District 1';

UPDATE essentials.districts SET label = 'District 2'
WHERE id = '6ad1e005-cf20-4cca-aa16-0e50eb1521da'
  AND label IS DISTINCT FROM 'District 2';

UPDATE essentials.districts SET label = 'District 4'
WHERE id = 'a1d3e3bf-e2d8-4c6d-8277-acac261a6f1f'
  AND label IS DISTINCT FROM 'District 4';

UPDATE essentials.districts SET label = 'District 5'
WHERE id = '7fe09a06-620f-45b6-ae56-78af65600cec'
  AND label IS DISTINCT FROM 'District 5';

-- (4) Create District 3 row for Bettencourt.
--     Guarded NOT EXISTS on (label, geo_id) so re-run is a no-op.
--     Bettencourt's politician + office rows are created in Plan 02 (migration 919).
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 3', 'LOCAL', '0655156', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE label = 'District 3' AND geo_id = '0655156'
);

-- (5) Set survivor chamber official_count = 4 (accurate after move: 3 original + Bishop = 4;
--     Bettencourt's 5th seat is added in Plan 02 which sets official_count = 5).
--     Guarded IS DISTINCT FROM so re-run is a no-op.
UPDATE essentials.chambers
SET official_count = 4
WHERE id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
  AND official_count IS DISTINCT FROM 4;

-- (6) Register this structural migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name, statements)
VALUES ('918', 'palmdale_reconcile', ARRAY[
  'UPDATE essentials.governments SET geo_id = ''0655156'' WHERE id = ''4f59ebad-631b-4340-91f0-091a6cecb3bb'' AND geo_id IS NULL',
  'UPDATE essentials.offices SET chamber_id = ''000d672d-97f1-4f1f-af61-9eb6f008c4fd'' WHERE chamber_id = ''c8e8d31e-c9f2-4d50-9a94-66be603a5c45''',
  'DELETE FROM essentials.chambers WHERE id = ''c8e8d31e-c9f2-4d50-9a94-66be603a5c45''',
  'UPDATE essentials.districts SET label = ''District 1/2/4/5'' on 4 rows; INSERT District 3'
])
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================================================
-- POST-VERIFICATION QUERIES (run after COMMIT to confirm state)
-- ============================================================

-- 1. geo_id backfilled
SELECT geo_id, state FROM essentials.governments
WHERE id = '4f59ebad-631b-4340-91f0-091a6cecb3bb';
-- expect: geo_id='0655156', state='CA'

-- 2. Exactly 1 City Council chamber under this gov (duplicate gone)
SELECT COUNT(*) AS chamber_count FROM essentials.chambers
WHERE government_id = '4f59ebad-631b-4340-91f0-091a6cecb3bb' AND name = 'City Council';
-- expect: 1

-- 3. Duplicate chamber c8e8d31e deleted
SELECT COUNT(*) AS duplicate_gone FROM essentials.chambers
WHERE id = 'c8e8d31e-c9f2-4d50-9a94-66be603a5c45';
-- expect: 0

-- 4. Survivor chamber 000d672d now has 4 offices (Bishop moved in; Bettencourt is Plan 02)
SELECT COUNT(*) AS office_count FROM essentials.offices
WHERE chamber_id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd';
-- expect: 4

-- 5. District labels (4 relabeled + 1 new)
SELECT id, label, district_type, geo_id, state FROM essentials.districts
WHERE geo_id = '0655156' AND district_type = 'LOCAL'
  AND label IN ('District 1','District 2','District 3','District 4','District 5')
ORDER BY label;
-- expect: 5 rows (D1/D2/D3/D4/D5), all district_type=LOCAL, geo_id=0655156, state=CA

-- 6. feedback_section_split_check for Palmdale (expect 0 rows)
SELECT
  c.government_id,
  c.name AS chamber_name,
  COUNT(DISTINCT c.id) AS chamber_count,
  COUNT(o.id) AS office_count
FROM essentials.chambers c
LEFT JOIN essentials.offices o ON o.chamber_id = c.id
WHERE c.government_id = '4f59ebad-631b-4340-91f0-091a6cecb3bb'
GROUP BY c.government_id, c.name
HAVING COUNT(DISTINCT c.id) > 1;
-- expect: 0 rows (no duplicate chamber names)

-- 7. schema_migrations registered
SELECT version, name FROM supabase_migrations.schema_migrations
WHERE version = '918';
-- expect: 1 row

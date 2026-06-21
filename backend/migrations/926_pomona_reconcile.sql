-- 926_pomona_reconcile.sql
-- Phase 147 (Pomona deep-seed) Wave 1 — STRUCTURAL (registers in schema_migrations)
-- Reconcile the pre-existing partial, duplicate-chamber Pomona seed:
--   (1) backfill geo_id '0658072' on gov 3c2c2a4b (was NULL)
--   (2) merge the duplicate 'City Council' chamber: MOVE all 3 doomed-chamber offices
--       (Sandoval/Mayor 657cb0b2, Garcia 315a0a8a, Lustro 8570f2ad) into survivor ddabfccc,
--       assert doomed 54a55a35 is empty, then DELETE it
--   (3) relabel the 4 At-Large district rows to their occupant's real district (D1/D2/D3/D6)
--   (4) create a new District 4 row (Ontiveros-Cole; her office/politician are Plan 02)
--   (5) create a new District 5 row (Lustro) and REPOINT Lustro's office off the shared
--       district UUID 35d17606 onto the new District 5 (resolves Garcia/Lustro shared-district defect)
-- The directly-elected Mayor (Lancaster LOCAL_EXEC model) 'Pomona Mayor' 3ec78ed9 + Sandoval office
-- 657cb0b2 already exist — only Sandoval's office is MOVED to the survivor here; no new Mayor row,
-- no rotational title flag (Pitfall 3). Back-pointer repairs (Garcia/Lustro/Sandoval), Ontiveros-Cole
-- create + her D4 seat, and official_count=7 are Plan 02 (927).
-- DB-verified live state 2026-06-20. Idempotent: re-running changes 0 rows.

BEGIN;

-- (1) geo_id backfill (guarded WHERE geo_id IS NULL — idempotent)
UPDATE essentials.governments
SET geo_id = '0658072'
WHERE id = '3c2c2a4b-a63c-4049-bcf6-e925fcb7d6c4' AND geo_id IS NULL;

-- (2a) MOVE all 3 doomed-chamber offices into the survivor (Pitfall 1 — 3 offices, not 1).
--      Target the duplicate by its chamber UUID only (both chambers share name 'City Council').
--      Idempotent: if chamber_id is already ddabfccc, 0 rows change.
UPDATE essentials.offices
SET chamber_id = 'ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d'
WHERE chamber_id = '54a55a35-54b0-4f2a-b5f8-843665a0c3ae';

-- (2b) Assert the doomed chamber is now empty before deleting it (Lancaster 910 / Palmdale 918 pattern)
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.offices
      WHERE chamber_id = '54a55a35-54b0-4f2a-b5f8-843665a0c3ae') > 0 THEN
    RAISE EXCEPTION 'Chamber 54a55a35-54b0-4f2a-b5f8-843665a0c3ae still has offices — aborting delete';
  END IF;
END $$;

-- (2c) DELETE the emptied duplicate chamber (UUID-targeted only — never by name)
DELETE FROM essentials.chambers WHERE id = '54a55a35-54b0-4f2a-b5f8-843665a0c3ae';

-- (3) Relabel the 4 occupied At-Large district rows to their occupant's real district.
--     Each UPDATE is keyed on exact UUID and guarded label IS DISTINCT FROM target.
--     district_type, geo_id, state are NOT touched. Use ONLY these UUIDs (RESEARCH §Pitfall 2):
--       e282b5d3 → District 1 (Martin)
--       3a213f0d → District 2 (Preciado)
--       35d17606 → District 3 (Garcia ONLY — Lustro is repointed off this below)
--       1946c2e2 → District 6 (Canales)

UPDATE essentials.districts SET label = 'District 1'
WHERE id = 'e282b5d3-b1dc-4966-ad72-9f0629660f79'
  AND label IS DISTINCT FROM 'District 1';

UPDATE essentials.districts SET label = 'District 2'
WHERE id = '3a213f0d-bcbd-4243-b576-b9c18c621520'
  AND label IS DISTINCT FROM 'District 2';

UPDATE essentials.districts SET label = 'District 3'
WHERE id = '35d17606-34ce-47cd-ad83-abde1821cabe'
  AND label IS DISTINCT FROM 'District 3';

UPDATE essentials.districts SET label = 'District 6'
WHERE id = '1946c2e2-a863-45fd-a2d7-56f20c7201ae'
  AND label IS DISTINCT FROM 'District 6';

-- (4) Create District 4 row for Ontiveros-Cole (her politician + office are Plan 02 / 927).
--     Guarded NOT EXISTS on (label, geo_id) so re-run is a no-op.
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 4', 'LOCAL', '0658072', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE label = 'District 4' AND geo_id = '0658072'
);

-- (5) Create District 5 row for Lustro (MUST come before the repoint below). Guarded NOT EXISTS.
INSERT INTO essentials.districts (label, district_type, geo_id, state)
SELECT 'District 5', 'LOCAL', '0658072', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE label = 'District 5' AND geo_id = '0658072'
);

-- (5b) REPOINT Lustro's office off the shared UUID (35d17606, Garcia's District 3) onto the new
--      District 5 (Pitfall 2). Guarded IS DISTINCT FROM so re-run changes 0 rows.
UPDATE essentials.offices
SET district_id = (SELECT id FROM essentials.districts WHERE label = 'District 5' AND geo_id = '0658072')
WHERE id = '8570f2ad-a8e4-476f-a437-4083da315095'
  AND district_id IS DISTINCT FROM (SELECT id FROM essentials.districts WHERE label = 'District 5' AND geo_id = '0658072');

-- (6) Register this structural migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name, statements)
VALUES ('926', 'pomona_reconcile', ARRAY[
  'UPDATE essentials.governments SET geo_id = ''0658072'' WHERE id = ''3c2c2a4b-a63c-4049-bcf6-e925fcb7d6c4'' AND geo_id IS NULL',
  'UPDATE essentials.offices SET chamber_id = ''ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d'' WHERE chamber_id = ''54a55a35-54b0-4f2a-b5f8-843665a0c3ae''',
  'DELETE FROM essentials.chambers WHERE id = ''54a55a35-54b0-4f2a-b5f8-843665a0c3ae''',
  'UPDATE essentials.districts SET label = ''District 1/2/3/6'' on 4 rows (e282b5d3/3a213f0d/35d17606/1946c2e2)',
  'INSERT District 4 + District 5; REPOINT office 8570f2ad (Lustro) to District 5'
])
ON CONFLICT (version) DO NOTHING;

COMMIT;

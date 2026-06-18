-- Migration 713: Fix Alhambra duplicate politician records
--
-- Root cause: Two government records exist for Alhambra:
--   - Old (geo_id=null, pre-district seed): 3 officials, no stances, HAS headshots
--   - New (geo_id=0600884, geofenced): all 5 officials, HAS stances, no headshots
-- Both sets appeared in search, causing duplicates. Stances are on the correct records.
--
-- Fix:
--   1. Move headshot image rows from old (-200xxx) UUIDs → new (-700xxx) UUIDs
--   2. Delete old offices (3 in old City Council + 1 in old Board of Education)
--   3. Delete old politician records

BEGIN;

-- Step 1: Move headshots to the geofenced politicians

-- Katherine Lee: old 22466ac0 (-200532) → new f22187bb (-700450)
UPDATE essentials.politician_images
SET politician_id = 'f22187bb-dc57-4088-bb19-8bc39bcb95c9'
WHERE politician_id = '22466ac0-0239-4dcb-80f2-26c5ff0e5f18';

-- Noya Wang: old f9877088 (-201116) → new abad7f66 (-700453)
UPDATE essentials.politician_images
SET politician_id = 'abad7f66-e2d3-4edf-a35f-2170c2bd4cbb'
WHERE politician_id = 'f9877088-2efa-4db3-9055-1f3750318d40';

-- Ross J. Maza: old 6302513b (-201115) → new 27441d13 (-700451)
UPDATE essentials.politician_images
SET politician_id = '27441d13-d90b-48e8-bb35-3b7da5d24c6e'
WHERE politician_id = '6302513b-ac24-4e8e-a5fd-0c0a2b98546f';

-- Adele Andrade-Stadler: old f49f0a93 (-201851) → new f6d52199 (-700454)
-- Two image rows on the old record: keep the named URL, drop the old-UUID-named one.
UPDATE essentials.politician_images
SET politician_id = 'f6d52199-b1d1-48d3-9972-66b8d229acdc'
WHERE politician_id = 'f49f0a93-02fc-4468-a987-d677864c3b62'
  AND url LIKE '%/alhambra/adele-andrade-stadler.jpg';

DELETE FROM essentials.politician_images
WHERE politician_id = 'f49f0a93-02fc-4468-a987-d677864c3b62';  -- removes the stale UUID-named headshot

-- Step 2: Delete old contacts (generic city website scrapes, no meaningful data)
DELETE FROM essentials.politician_contacts
WHERE politician_id IN (
  '22466ac0-0239-4dcb-80f2-26c5ff0e5f18',
  'f9877088-2efa-4db3-9055-1f3750318d40',
  '6302513b-ac24-4e8e-a5fd-0c0a2b98546f',
  'f49f0a93-02fc-4468-a987-d677864c3b62'
);

-- Step 3: Delete old offices
DELETE FROM essentials.offices
WHERE politician_id IN (
  '22466ac0-0239-4dcb-80f2-26c5ff0e5f18',  -- Katherine Lee (old Mayor title)
  'f9877088-2efa-4db3-9055-1f3750318d40',  -- Noya Wang (old at-large)
  '6302513b-ac24-4e8e-a5fd-0c0a2b98546f',  -- Ross J. Maza (old at-large)
  'f49f0a93-02fc-4468-a987-d677864c3b62'   -- Adele Andrade-Stadler (old Board of Education)
);

-- Step 4: Delete old politician records (no stances, no race_candidates — verified)
DELETE FROM essentials.politicians
WHERE id IN (
  '22466ac0-0239-4dcb-80f2-26c5ff0e5f18',
  'f9877088-2efa-4db3-9055-1f3750318d40',
  '6302513b-ac24-4e8e-a5fd-0c0a2b98546f',
  'f49f0a93-02fc-4468-a987-d677864c3b62'
);

COMMIT;

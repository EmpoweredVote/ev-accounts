-- 1143_hawthorne_dedupe_and_school_relocate.sql
--
-- Hawthorne was the special case deferred from 1142. Its twin government
-- "City of Hawthorne, California, US" (47200b88) held TWO chambers:
--   * City Council — Alex Vargas + Angie Reyes English (duplicates of the
--     canonical "City of Hawthorne" council) plus David Patterson & Haidar Awad
--     (former members — the current council is Mayor Vargas + Monteiro, Reyes
--     English, Johnson, Manning, verified against cityofhawthorne.org).
--   * Board of Trustees — the HAWTHORNE ELEMENTARY SCHOOL DISTRICT board (geo
--     0616680, G5400), mis-parented under the city. These 5 trustees are the
--     only record of that board, so they are RELOCATED to a proper school-
--     district government, not deleted.
--
-- Steps: (1) merge the 2 council duplicates' photos to canonical; (2) create
-- "Hawthorne Elementary, California, US" and move the Board of Trustees chamber
-- to it; (3) deactivate the 4 twin city-council records; (4) delete the twin
-- City Council chamber + offices and the now-empty twin government.

BEGIN;

-- 1. Merge council duplicate photos into canonical "City of Hawthorne".
-- Alex Vargas (Mayor): keep the cc_by_sa_4.0 image, drop the unknown-license dup.
UPDATE essentials.politician_images SET politician_id = 'f4d282ef-5125-4e20-8ca6-8b39aa18e00e'
  WHERE id = 'a04c1307-6be6-4d41-823d-8cc8add07860';
DELETE FROM essentials.politician_images WHERE id = '62058a9f-1b74-484b-bab4-3285c0181c57';
-- Angie Reyes English
UPDATE essentials.politician_images SET politician_id = 'be3ca929-4fe1-4797-acf2-570ba8fcebbf'
  WHERE politician_id = '97f376e1-a21b-48eb-ac4b-b58cff2911d5';

-- 2. Relocate the Hawthorne Elementary SD board to its own government.
WITH new_gov AS (
  INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
  VALUES (gen_random_uuid(), 'Hawthorne Elementary, California, US', 'LOCAL', 'CA', NULL, NULL)
  RETURNING id
)
UPDATE essentials.chambers SET government_id = (SELECT id FROM new_gov)
WHERE id = '8db8ce09-9b41-4c6e-844d-be51c7f97cd0';

-- 3. Deactivate the twin city-council records (2 duplicates + 2 former members).
UPDATE essentials.politicians SET is_active = false
WHERE id IN (
  '0426259e-74c5-4266-a766-3aa73e4ab801', -- Alex Vargas (dup)
  '97f376e1-a21b-48eb-ac4b-b58cff2911d5', -- Angie Reyes English (dup)
  '903b537b-a806-4fa0-8427-1f72e9e85e3b', -- David Patterson (former)
  '156a8cc8-2e5a-4d1f-8a10-e8b3614f7c98'  -- Haidar Awad (former)
);

-- 4. Delete the twin City Council chamber + offices, then the empty twin gov.
DELETE FROM essentials.offices WHERE chamber_id = 'c259d2d2-5614-4c34-b07e-68131d0101c1';
DELETE FROM essentials.chambers WHERE id = 'c259d2d2-5614-4c34-b07e-68131d0101c1';
DELETE FROM essentials.governments WHERE id = '47200b88-b845-487a-8ea1-144402a3bdd9';

COMMIT;

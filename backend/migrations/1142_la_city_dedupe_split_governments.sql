-- 1142_la_city_dedupe_split_governments.sql
--
-- Fix the LA-County "split section" defect: 9 cities were seeded twice — once as
-- the canonical government "City of X" (geo_id set, carries all compass stances)
-- and once as an older twin "City of X, California, US" (geo_id NULL, no stances,
-- but holds some headshots). Both attach to the same district geo_id, so the
-- browse view rendered TWO "CITY OF X" sections and inflated the missing-photo
-- count with duplicate records.
--
-- This migration, for the 9 clean cities (Hawthorne handled separately — its twin
-- also contains mis-seeded school-board members):
--   1. Repoints the headshots that live only on twin records to their canonical
--      counterpart (recovering ~18 photos instead of re-searching them).
--   2. Deactivates the now-redundant twin politician records (they carry 0 stances
--      and 0 race-candidate links; verified none hold an office elsewhere).
--   3. Deletes the twin offices, chambers, and governments so only the canonical
--      "City of X" section remains.
--
-- Twin governments removed (geo_id-NULL "City of X, California, US"):
--   Alhambra 7f3975b6 | Carson eafaa636 | Compton eeee2f87 | Culver City 43f51b26
--   El Segundo 556c7d6a | Gardena eb20e603 | South Gate fbd2efb6
--   West Hollywood 62b9af33 | Whittier 35853533

BEGIN;

-- 1. Recover headshots: repoint twin -> canonical (canonical had no image row).
-- Carson — Lula Davis-Holmes (Mayor)
UPDATE essentials.politician_images SET politician_id = '94de05c6-d1bc-4cd5-ae9a-7c292ec8149e' WHERE politician_id = 'e27fa9bb-cd4a-4e1b-a8ee-330dcfd3d4ae';
-- Compton — Emma Sharif (Mayor)
UPDATE essentials.politician_images SET politician_id = '174f3f47-e4ee-4775-ab6f-f1039d608098' WHERE politician_id = 'ad1c9e2a-2ea0-4fad-99c0-ddb2aa467f4a';
-- Compton — Lillie P. Darden (District 4)
UPDATE essentials.politician_images SET politician_id = '10429226-b00b-4b96-b306-753c2094d719' WHERE politician_id = 'c47e19eb-53cc-4de3-a0f2-d2c6882addea';
-- Culver City — Bryan Fish
UPDATE essentials.politician_images SET politician_id = '6ed5080f-e7cf-493b-9424-80dcbc8d54d0' WHERE politician_id = '837613f5-2022-4844-95d7-df0848ca6fef';
-- Culver City — Dan O'Brien
UPDATE essentials.politician_images SET politician_id = 'a2e727ea-2115-455c-a623-5b69a7336224' WHERE politician_id = '80207395-5f7a-43e9-bfe7-8d33e35d557b';
-- El Segundo — Chris Pimentel
UPDATE essentials.politician_images SET politician_id = '1c77d036-8c9e-4831-9bba-40af2d043ed2' WHERE politician_id = '2fdc11f7-438d-418a-9ec9-2cbbb0ad49b7';
-- El Segundo — Drew Boyles
UPDATE essentials.politician_images SET politician_id = '4e485d3a-79a0-40ce-a52f-f84d187bf5de' WHERE politician_id = '39d282fe-303e-4768-bcf7-4b50d3c244b0';
-- El Segundo — Lance Giroux
UPDATE essentials.politician_images SET politician_id = '70dec2bf-c58c-4e3e-abbb-59a600d444d7' WHERE politician_id = '889f0d4e-841d-41c6-be75-c5c064d64dbf';
-- El Segundo — Michelle Keldorf
UPDATE essentials.politician_images SET politician_id = '2616c881-04da-4ec4-975b-4f82235ccf21' WHERE politician_id = '6310e53f-5749-41d3-b20e-2fa516573105';
-- Gardena — Mark E. Henderson
UPDATE essentials.politician_images SET politician_id = 'f584e436-2e32-43c2-b553-3121e0d89fc2' WHERE politician_id = '4b1c1830-491c-4c9c-a9f7-d52881bd19e8';
-- Gardena — Paulette C. Francis
UPDATE essentials.politician_images SET politician_id = 'cf7e1a9d-7057-4244-b850-d0e2da4d71fc' WHERE politician_id = '7e7834d9-9649-4ea3-9727-c46c80a390ac';
-- Gardena — Tasha Cerda (Mayor)
UPDATE essentials.politician_images SET politician_id = '7e870f7f-cdc3-456e-b773-6a387faf11eb' WHERE politician_id = '7e189f77-9074-420e-807a-5cc79a1e9957';
-- Gardena — Wanda Love
UPDATE essentials.politician_images SET politician_id = '9544d1f3-4a56-4136-a32f-f57f53de15a6' WHERE politician_id = 'bda16858-2d8b-489d-ac63-b00c42315d89';
-- South Gate — Al Rios
UPDATE essentials.politician_images SET politician_id = '8247e088-2ac8-4ae1-bac9-ff537dd27fec' WHERE politician_id = '53069c70-94e5-4de0-81b8-6ebc8e35988b';
-- South Gate — Gil Hurtado
UPDATE essentials.politician_images SET politician_id = '75f11f44-9760-49bf-ab8c-f7aa1f53255f' WHERE politician_id = '1a6190c0-039a-410c-8340-a47a49daa3d2';
-- South Gate — Maria Davila
UPDATE essentials.politician_images SET politician_id = 'cbc8c88e-492d-4e7b-8e8d-cfd573a1afc5' WHERE politician_id = '4931b7d2-9b28-4d8d-9290-9e477a844e99';
-- South Gate — Maria del Pilar Avalos
UPDATE essentials.politician_images SET politician_id = '006ecd0d-526a-49b6-b253-709b76c5965f' WHERE politician_id = '2094104e-9a8f-4ed9-8e60-8c799d477c5e';
-- West Hollywood — Chelsea Byers
UPDATE essentials.politician_images SET politician_id = 'a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a' WHERE politician_id = '201cc4fa-483e-418b-935b-4f7ad852c9b6';

-- 2. Deactivate all twin politician records (members under the 9 twin governments).
UPDATE essentials.politicians SET is_active = false
WHERE id IN (
  SELECT o.politician_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  WHERE ch.government_id IN (
    '7f3975b6-1c21-444c-8114-0a3024256d83','eafaa636-1fca-4265-995f-be061c4835c8',
    'eeee2f87-cca5-431a-93fa-70cbf35acb60','43f51b26-1a69-4a7a-8276-98f4b489ae4f',
    '556c7d6a-455d-4b00-aeea-57ee9410e0a3','eb20e603-1a0d-40fe-932f-9483512ffdc5',
    'fbd2efb6-2ad8-4448-beb7-b091daf0b835','62b9af33-5afc-45e7-a5c9-1c9772fa88c2',
    '35853533-0655-4cf2-a08b-b2899a17f2e9'
  )
);

-- 3. Delete twin offices, chambers, governments.
DELETE FROM essentials.offices
WHERE chamber_id IN (
  SELECT id FROM essentials.chambers WHERE government_id IN (
    '7f3975b6-1c21-444c-8114-0a3024256d83','eafaa636-1fca-4265-995f-be061c4835c8',
    'eeee2f87-cca5-431a-93fa-70cbf35acb60','43f51b26-1a69-4a7a-8276-98f4b489ae4f',
    '556c7d6a-455d-4b00-aeea-57ee9410e0a3','eb20e603-1a0d-40fe-932f-9483512ffdc5',
    'fbd2efb6-2ad8-4448-beb7-b091daf0b835','62b9af33-5afc-45e7-a5c9-1c9772fa88c2',
    '35853533-0655-4cf2-a08b-b2899a17f2e9'
  )
);

DELETE FROM essentials.chambers WHERE government_id IN (
  '7f3975b6-1c21-444c-8114-0a3024256d83','eafaa636-1fca-4265-995f-be061c4835c8',
  'eeee2f87-cca5-431a-93fa-70cbf35acb60','43f51b26-1a69-4a7a-8276-98f4b489ae4f',
  '556c7d6a-455d-4b00-aeea-57ee9410e0a3','eb20e603-1a0d-40fe-932f-9483512ffdc5',
  'fbd2efb6-2ad8-4448-beb7-b091daf0b835','62b9af33-5afc-45e7-a5c9-1c9772fa88c2',
  '35853533-0655-4cf2-a08b-b2899a17f2e9'
);

DELETE FROM essentials.governments WHERE id IN (
  '7f3975b6-1c21-444c-8114-0a3024256d83','eafaa636-1fca-4265-995f-be061c4835c8',
  'eeee2f87-cca5-431a-93fa-70cbf35acb60','43f51b26-1a69-4a7a-8276-98f4b489ae4f',
  '556c7d6a-455d-4b00-aeea-57ee9410e0a3','eb20e603-1a0d-40fe-932f-9483512ffdc5',
  'fbd2efb6-2ad8-4448-beb7-b091daf0b835','62b9af33-5afc-45e7-a5c9-1c9772fa88c2',
  '35853533-0655-4cf2-a08b-b2899a17f2e9'
);

COMMIT;

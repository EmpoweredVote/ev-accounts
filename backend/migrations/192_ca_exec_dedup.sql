-- Migration 192: CA Executive Deduplication
--
-- Migration 190 created 8 duplicate CA constitutional officer rows because
-- the pre-existing seed (positive external_ids) already had all 8 officials.
--
-- This migration:
--   1. Removes the 8 duplicate politicians/offices/districts from migration 190
--   2. Updates the 8 old politicians' external_ids to the -06000xxx scheme
--   3. Fixes Tony Thurmond's title ("Superintendent" → "Superintendent of Public Instruction")
--   4. Sets geo_id='06' on the old STATE_EXEC districts (were empty string)
--
-- The 8 pre-existing politicians to KEEP (already have headshots + correct data):
--   f26309c8  Gavin Newsom         665324  → -6000101
--   03df7cce  Eleni Kounalakis     688464  → -6000102
--   8b183a30  Rob Bonta            690810  → -6000103
--   4ba62f32  Shirley N. Weber     652537  → -6000104
--   ea85dfe3  Malia M. Cohen       686665  → -6000105
--   41ef8aaa  Fiona Ma             692840  → -6000106
--   bab3379b  Ricardo Lara         647872  → -6000107
--   f8808ac0  Tony Thurmond        691295  → -6000108

BEGIN;

-- Step 1: Break circular FK — null out office_id on the 8 new duplicates
-- (politicians.office_id → offices.id creates a cycle; must clear before deleting offices)
UPDATE essentials.politicians
SET office_id = NULL
WHERE external_id BETWEEN -6000108 AND -6000101;

-- Step 2: Delete the 8 new duplicate offices (created by migration 190)
DELETE FROM essentials.offices
WHERE id IN (
  '96b23401-41b8-421f-a2e4-89f017cd0264',  -- Gavin C. Newsom / Governor
  '1a690e0f-79ec-4b00-a928-f1fac6f5b0b2',  -- Eleni Kounalakis / Lieutenant Governor
  '13e06873-7dc9-437b-89ac-150575b5a7b3',  -- Rob Bonta / Attorney General
  '320cbac7-2d0c-456c-a7bc-0a1483e162c4',  -- Shirley N. Weber / Secretary of State
  '1db32709-de2c-4227-a034-def20f8f8006',  -- Malia M. Cohen / Controller
  '0fc43be1-73fa-49e2-8cc1-484987d915bd',  -- Fiona Ma / Treasurer
  'e5c8908a-7a9e-46f7-bc5b-5817495ca4dc',  -- Ricardo Lara / Insurance Commissioner
  'f250dc70-19fd-4781-8102-218334cc38bb'   -- Tony Thurmond / Superintendent of Public Instruction
);

-- Step 3: Delete the 8 new duplicate politicians
DELETE FROM essentials.politicians
WHERE external_id BETWEEN -6000108 AND -6000101;

-- Step 4: Delete the 8 new STATE_EXEC districts created by migration 190
-- (labeled 'California Governor', 'California Attorney General', etc.)
DELETE FROM essentials.districts
WHERE id IN (
  '8ea7e4dc-61f5-4832-ac13-c36e7fe9024d',
  '382d3082-4981-4353-bdcc-04ba1bad2826',
  '6c5fb066-e446-4e91-ac05-f52939a9c37e',
  '168cd306-3a63-413e-ac77-beb9c182e63f',
  '8028e70a-040c-4537-9f9e-463706efa22e',
  'b9d3cf68-2e2c-4ac3-af99-8e252e7ee986',
  'a63aae44-abdb-4ace-8b10-70371a690cdb',
  '499d0bd9-7176-4819-977a-2809ac747b76'
);

-- Step 5: Update old politicians' external_ids to the -06000xxx scheme
UPDATE essentials.politicians SET external_id = -6000101 WHERE id = 'f26309c8-2525-49b2-bdaf-62980cbb1853';
UPDATE essentials.politicians SET external_id = -6000102 WHERE id = '03df7cce-7502-4089-acd5-139841002cbe';
UPDATE essentials.politicians SET external_id = -6000103 WHERE id = '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa';
UPDATE essentials.politicians SET external_id = -6000104 WHERE id = '4ba62f32-dd20-48ce-8d84-d09bb129ad59';
UPDATE essentials.politicians SET external_id = -6000105 WHERE id = 'ea85dfe3-1092-468e-a799-cb8054c135db';
UPDATE essentials.politicians SET external_id = -6000106 WHERE id = '41ef8aaa-b604-4725-b46d-dab1656cc198';
UPDATE essentials.politicians SET external_id = -6000107 WHERE id = 'bab3379b-d64e-423b-b62e-4efa04cee750';
UPDATE essentials.politicians SET external_id = -6000108 WHERE id = 'f8808ac0-8a9d-4657-8bf7-2ae60d96399c';

-- Step 6: Fix Thurmond's title
UPDATE essentials.offices
SET title = 'Superintendent of Public Instruction'
WHERE politician_id = 'f8808ac0-8a9d-4657-8bf7-2ae60d96399c'
  AND title = 'Superintendent';

-- Step 7: Set geo_id='06' on the old STATE_EXEC districts (they had geo_id='')
UPDATE essentials.districts
SET geo_id = '06'
WHERE id IN (
  SELECT o.district_id
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.id IN (
    'f26309c8-2525-49b2-bdaf-62980cbb1853',
    '03df7cce-7502-4089-acd5-139841002cbe',
    '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa',
    '4ba62f32-dd20-48ce-8d84-d09bb129ad59',
    'ea85dfe3-1092-468e-a799-cb8054c135db',
    '41ef8aaa-b604-4725-b46d-dab1656cc198',
    'bab3379b-d64e-423b-b62e-4efa04cee750',
    'f8808ac0-8a9d-4657-8bf7-2ae60d96399c'
  )
)
AND (geo_id IS NULL OR geo_id = '');

COMMIT;

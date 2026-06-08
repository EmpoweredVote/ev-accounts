-- Migration 295: Glendale Wave 1 Gap-Fill
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--   Existing politicians: 4 of 5 at-large council members
--   Roster in DB: Elen Asatryan, Daniel Brotman, Vartan Gharpetian, Ardy Kassakhian
--   Gap: Ara Najarian (5th council member)
--
-- Note: Research (108-RESEARCH.md) indicates Ara Najarian was not seeking re-election
-- after June 2026. He remained the incumbent through the filing period. Per D-03
-- conservative default, he is inserted with is_incumbent=true. A future migration
-- will update is_incumbent to false when his successor takes office.
--
-- External_ids used: -700100 (Najarian)
-- Chamber: 771727ec-684b-4eb8-98a6-d7205d9bbac0 (Glendale City Council — used by existing offices)
-- Government: 'City of Glendale, California, US'
-- District filter: geo_id='0630000', district_type='LOCAL'
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed = false (elected)
--   photo_origin_url: official glendaleca.gov council page

BEGIN;

-- Idempotent geo_id backfill for Glendale districts
UPDATE essentials.districts
SET geo_id = '0630000'
WHERE label LIKE '%Glendale%'
  AND state = 'CA'
  AND district_type = 'LOCAL'
  AND geo_id IS DISTINCT FROM '0630000';

-- Ara Najarian — 5th Glendale at-large council member (external_id=-700100)
-- [VERIFIED: glendaleca.gov city council page, Outlook Newspapers]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Ara Najarian', 'Ara', 'Najarian', NULL,
          true, false, false, true, -700100,
          'https://www.glendaleca.gov/government/city-council')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '771727ec-684b-4eb8-98a6-d7205d9bbac0',
       p.id,
       'Councilmember', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0630000'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  )
ORDER BY d.id
LIMIT 1;

-- office_id back-fill for all new Glendale politicians in this migration
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700102 AND -700100
  AND p.office_id IS NULL;

COMMIT;

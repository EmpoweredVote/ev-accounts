-- =============================================================================
-- Migration 287: DC AG + Shadow Senators + Eleanor Holmes Norton
-- DCOF-02, DCOF-04
-- External IDs: -600015 (Schwalb), -600016 (Strauss), -600017 (Jain), -600030 (EHN)
--
-- CRITICAL: Ankit Jain is the current junior shadow senator (sworn Jan 3, 2025).
--           Michael D. Brown left office Jan 3, 2025. Do NOT insert Michael D. Brown.
--
-- District FKs:
--   Schwalb (AG): dc-council-at-large (citywide; no LOCAL_EXEC district for DC AG)
--   Strauss, Jain, EHN: dc-national-lower (NATIONAL_LOWER)
-- =============================================================================

BEGIN;

-- -600015: Brian Schwalb — Attorney General
-- AG: citywide official; using dc-council-at-large as nearest available citywide district
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Brian Schwalb', 'Brian', 'Schwalb', 'Democratic',
          true, false, false, true, -600015,
          'https://oag.dc.gov/about-oag/our-structure-divisions/about-attorney-general')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Attorney General', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-council-at-large'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600016: Paul Strauss — U.S. Shadow Senator (Senior)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Paul Strauss', 'Paul', 'Strauss', 'Democratic',
          true, false, false, true, -600016,
          'https://statehood.dc.gov/page/shadow-senators')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'U.S. Shadow Senator (Senior)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-national-lower'
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600017: Ankit Jain — U.S. Shadow Senator (Junior)
-- Sworn January 3, 2025. NOT Michael D. Brown (left office Jan 3, 2025).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Ankit Jain', 'Ankit', 'Jain', 'Democratic',
          true, false, false, true, -600017,
          'https://senatorjaindc.com/about')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'U.S. Shadow Senator (Junior)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-national-lower'
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- -600030: Eleanor Holmes Norton — Delegate, District of Columbia
-- EHN reserved at end of DC range (-600030) per D-12
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url, bioguide_id)
  VALUES (gen_random_uuid(), 'Eleanor Holmes Norton', 'Eleanor', 'Norton', 'Democratic',
          true, false, false, true, -600030,
          'https://unitedstates.github.io/images/congress/225x275/N000147.jpg',
          'N000147')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(), d.id, NULL, p.id, 'Delegate, District of Columbia', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-national-lower'
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

COMMIT;

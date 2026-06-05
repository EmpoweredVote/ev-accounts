-- =============================================================================
-- Migration 178: Portland City Council Incumbents
--
-- Seeds the 9 City Council politicians (Mayor + 5 district + 3 at-large) and
-- links them to the 9 skeletal council offices created by migration 177.
-- All politicians have party=NULL (Portland nonpartisan elections).
-- External_id range: -23601001..-23601009.
--
-- Anna Bullett (District 4) verified against Wikipedia Portland City Council
-- (Maine) page on 2026-05-19. Confirmed: Anna Bullett is current District 4
-- councilor (since 2023). All 9 council names confirmed from Wikipedia TOC.
-- Source: https://en.wikipedia.org/wiki/Portland_City_Council_(Maine)
-- =============================================================================

BEGIN;

-- ===== Mayor: Mark Dion =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mark Dion', 'Mark', 'Dion', NULL,
          true, false, false, true, -23601001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- ===== District 1: Sarah Michniewicz =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Michniewicz', 'Sarah', 'Michniewicz', NULL,
          true, false, false, true, -23601002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 1)'
  AND o.politician_id IS NULL;

-- ===== District 2: Wesley Pelletier =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Wesley Pelletier', 'Wesley', 'Pelletier', NULL,
          true, false, false, true, -23601003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 2)'
  AND o.politician_id IS NULL;

-- ===== District 3: Regina Phillips =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Regina Phillips', 'Regina', 'Phillips', NULL,
          true, false, false, true, -23601004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 3)'
  AND o.politician_id IS NULL;

-- ===== District 4: Anna Bullett (VERIFIED 2026-05-19 against Wikipedia) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Anna Bullett', 'Anna', 'Bullett', NULL,
          true, false, false, true, -23601005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 4)'
  AND o.politician_id IS NULL;

-- ===== District 5: Kate Sykes =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kate Sykes', 'Kate', 'Sykes', NULL,
          true, false, false, true, -23601006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601006
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 5)'
  AND o.politician_id IS NULL;

-- ===== At-Large 1: Pious Ali =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pious Ali', 'Pious', 'Ali', NULL,
          true, false, false, true, -23601007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== At-Large 2: April Fournier =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'April Fournier', 'April', 'Fournier', NULL,
          true, false, false, true, -23601008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== At-Large 3: Benjamin Grant =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Benjamin Grant', 'Benjamin', 'Grant', NULL,
          true, false, false, true, -23601009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601009
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 3)'
  AND o.politician_id IS NULL;

-- ===== office_id back-fill (council members -23601001..-23601009) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -23601009 AND -23601001
  AND p.office_id IS NULL;

COMMIT;

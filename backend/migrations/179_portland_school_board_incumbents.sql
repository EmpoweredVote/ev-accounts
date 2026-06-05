-- =============================================================================
-- Migration 179: Portland Board of Public Education Incumbents
--
-- Seeds the 9 School Board politicians (4 at-large + 5 district) and
-- links them to the 9 skeletal school board offices created by migration 177.
-- All politicians have party=NULL (Portland nonpartisan elections).
-- External_id range: -23601010..-23601018.
--
-- School Board roster verified from portlandschools.org/about/board-of-education
-- on 2026-05-19. HIGH confidence source.
-- =============================================================================

BEGIN;

-- ===== At-Large 1: Maya Lena =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Maya Lena', 'Maya', 'Lena', NULL,
          true, false, false, true, -23601010)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601010
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== At-Large 2: Sarah Lentz =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Lentz', 'Sarah', 'Lentz', NULL,
          true, false, false, true, -23601011)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601011
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== At-Large 3: Usira Ali =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Usira Ali', 'Usira', 'Ali', NULL,
          true, false, false, true, -23601012)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601012
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 3)'
  AND o.politician_id IS NULL;

-- ===== At-Large 4: Jayne Sawtelle =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jayne Sawtelle', 'Jayne', 'Sawtelle', NULL,
          true, false, false, true, -23601013)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601013
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (At-Large 4)'
  AND o.politician_id IS NULL;

-- ===== District 1: Abusana "Micky" Bondo =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abusana "Micky" Bondo', 'Abusana', 'Bondo', NULL,
          true, false, false, true, -23601014)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601014
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 1)'
  AND o.politician_id IS NULL;

-- ===== District 2: Ali Ali =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ali Ali', 'Ali', 'Ali', NULL,
          true, false, false, true, -23601015)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601015
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 2)'
  AND o.politician_id IS NULL;

-- ===== District 3: Julianne Opperman =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Julianne Opperman', 'Julianne', 'Opperman', NULL,
          true, false, false, true, -23601016)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601016
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 3)'
  AND o.politician_id IS NULL;

-- ===== District 4: Fatuma Noor =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Fatuma Noor', 'Fatuma', 'Noor', NULL,
          true, false, false, true, -23601017)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601017
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 4)'
  AND o.politician_id IS NULL;

-- ===== District 5: Sarah Brydon =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sarah Brydon', 'Sarah', 'Brydon', NULL,
          true, false, false, true, -23601018)
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
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -23601018
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2360545'
  AND ch.name = 'Board of Public Education'
  AND o.title = 'School Board Member (District 5)'
  AND o.politician_id IS NULL;

-- ===== office_id back-fill (school board members -23601010..-23601018) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -23601018 AND -23601010
  AND p.office_id IS NULL;

COMMIT;

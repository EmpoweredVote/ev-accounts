-- =============================================================================
-- Migration 181: Auburn + Biddeford City Council Incumbents (Tier 2)
--
-- Seeds 18 politicians (Auburn 8 + Biddeford 10) and links them to the
-- skeletal offices created by migration 177.
-- All politicians have party=NULL (Maine city elections are nonpartisan).
-- External_id ranges: Auburn -230201001..-230201008, Biddeford -230481001..-230481010
--
-- NOTE: essentials.offices has NO email column.
-- Emails are stored on politicians.email_addresses (TEXT[] array).
--
-- Auburn emails: full harvest from auburnmaine.gov city directory (8 emails).
-- Biddeford emails: Mayor only (liam.lafountain@biddefordmaine.org);
--   remaining 9 councilors have NULL email_addresses (no public directory found).
--
-- CRITICAL data notes:
-- - Auburn Ward 3 = Mathieu Duvall, Ward 4 = Kelly Butler (verified 2026 incumbents)
-- - Biddeford Mayor = Liam LaFountain (NOT Roger Beaupre)
-- - Roger Beaupre = Ward 3 councilor; informally Council President but NOT a
--   separate DB office (no -230481011 row)
-- - Biddeford Mayor email uses .org domain (biddefordmaine.org), not .gov
-- =============================================================================

BEGIN;

-- =============================================================================
-- CITY 1: AUBURN (geo_id=2302060, chamber='City Council')
-- =============================================================================

-- ===== Auburn Mayor: Jeffrey D. Harmon =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Jeffrey D. Harmon', 'Jeffrey', 'Harmon', NULL,
          true, false, false, true, -230201001, ARRAY['jharmon@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- ===== Auburn Ward 1: Rachel B. Randall =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Rachel B. Randall', 'Rachel', 'Randall', NULL,
          true, false, false, true, -230201002, ARRAY['rrandall@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

-- ===== Auburn Ward 2: Timothy M. Cowan =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Timothy M. Cowan', 'Timothy', 'Cowan', NULL,
          true, false, false, true, -230201003, ARRAY['tcowan@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

-- ===== Auburn Ward 3: Mathieu Duvall (VERIFIED: NOT a 2025 meeting-packet name) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Mathieu Duvall', 'Mathieu', 'Duvall', NULL,
          true, false, false, true, -230201004, ARRAY['mduvall@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

-- ===== Auburn Ward 4: Kelly Butler (VERIFIED: NOT a 2025 meeting-packet name) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Kelly Butler', 'Kelly', 'Butler', NULL,
          true, false, false, true, -230201005, ARRAY['kbutler@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

-- ===== Auburn Ward 5: Leroy G. Walker, Sr. (last_name='Walker', suffix preserved in full_name) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Leroy G. Walker, Sr.', 'Leroy', 'Walker', NULL,
          true, false, false, true, -230201006, ARRAY['lwalker@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201006
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

-- ===== Auburn At-Large 1: Belinda A. Gerry =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Belinda A. Gerry', 'Belinda', 'Gerry', NULL,
          true, false, false, true, -230201007, ARRAY['bgerry@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== Auburn At-Large 2: Adam R. Platz =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Adam R. Platz', 'Adam', 'Platz', NULL,
          true, false, false, true, -230201008, ARRAY['aplatz@auburnmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230201008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302060'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== Auburn office_id back-fill (-230201001..-230201008) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -230201008 AND -230201001
  AND p.office_id IS NULL;

-- =============================================================================
-- CITY 2: BIDDEFORD (geo_id=2304860, chamber='City Council')
-- =============================================================================

-- ===== Biddeford Mayor: Liam LaFountain (NOT Beaupre — Beaupre is Ward 3) =====
-- Biddeford uses .org domain for Mayor email (biddefordmaine.org, not .gov)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Liam LaFountain', 'Liam', 'LaFountain', NULL,
          true, false, false, true, -230481001, ARRAY['liam.lafountain@biddefordmaine.org'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 1: Patricia Boston =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Patricia Boston', 'Patricia', 'Boston', NULL,
          true, false, false, true, -230481002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 2: Abigail Woods =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abigail Woods', 'Abigail', 'Woods', NULL,
          true, false, false, true, -230481003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 3: Roger Beaupre (Ward 3 councilor; informally Council President — NOT a separate DB office) =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roger Beaupre', 'Roger', 'Beaupre', NULL,
          true, false, false, true, -230481004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 4: Dylan Doughty =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dylan Doughty', 'Dylan', 'Doughty', NULL,
          true, false, false, true, -230481005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 5: David Kurtz =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David Kurtz', 'David', 'Kurtz', NULL,
          true, false, false, true, -230481006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481006
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 6: Jake Pierson =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jake Pierson', 'Jake', 'Pierson', NULL,
          true, false, false, true, -230481007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 6)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 6)'
  AND o.politician_id IS NULL;

-- ===== Biddeford Ward 7: Brad Cote =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brad Cote', 'Brad', 'Cote', NULL,
          true, false, false, true, -230481008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 7)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 7)'
  AND o.politician_id IS NULL;

-- ===== Biddeford At-Large 1: Marc Lessard =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Marc Lessard', 'Marc', 'Lessard', NULL,
          true, false, false, true, -230481009)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481009
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== Biddeford At-Large 2: Lisa Vadnais =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Vadnais', 'Lisa', 'Vadnais', NULL,
          true, false, false, true, -230481010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230481010
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2304860'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== Biddeford office_id back-fill (-230481001..-230481010) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -230481010 AND -230481001
  AND p.office_id IS NULL;

COMMIT;

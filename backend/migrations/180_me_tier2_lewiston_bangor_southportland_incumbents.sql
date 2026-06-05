-- =============================================================================
-- Migration 180: Lewiston + Bangor + South Portland Incumbent Politicians
--
-- Seeds incumbent politicians for three of Maine's five Tier 2 cities and
-- links them to skeletal office rows created by migration 177.
-- All politicians have party=NULL (Maine city elections are nonpartisan).
--
-- City / geo_id / external_id range / seat count:
--   Lewiston     2338740  -233871001..-233871008  8 (Mayor + Ward 1-7)
--   Bangor       2302795  -230271001..-230271009  9 (Mayor + At-Large 1-8)
--   South Portland 2371990  -237191001..-237191008 7 unique politicians / 8 offices
--
-- External_id scheme: -(int(geo_id[:5]) * 10000 + seq)
--   5-digit prefix used for ALL Tier 2 cities to avoid the Bangor/Auburn
--   4-digit collision (both would be 2302 at 4 digits).
--
-- Bangor At-Large seat assignment policy:
--   The 8 At-Large seats (1..8) are assigned alphabetically by last name:
--   Beck=AL1, Carson=AL2, Deane=AL3, Faloon=AL4, Fish=AL5,
--   Leonard=AL6, Mallar=AL7, Walker=AL8.
--   This is a project-policy assignment (consistent with Portland precedent),
--   not a city-published ordering.
--
-- South Portland dual-office pattern (Tipton):
--   Elyse Tipton holds BOTH the Mayor seat AND Council Member (District 5).
--   She is INSERTed ONCE as external_id=-237191001. Two separate office UPDATE
--   blocks point both office rows to her politician_id. This is allowed because
--   the unique index on essentials.offices.politician_id was dropped in
--   migration 159.
--   External_id -237191006 is INTENTIONALLY SKIPPED (see comment below).
--
-- Email storage: individual emails stored on politicians.email_addresses (array).
--   Bangor: all 9 emails populated.
--   Lewiston: Ward 1 (Nagine) and Ward 3 (Harriman) only; 6 others not found.
--   South Portland: none found; all email_addresses remain NULL.
--
-- Requires: migration 177 (ME 23-city scaffolding applied 2026-05-19)
-- Researched: 2026-05-19 from official city websites
-- =============================================================================

BEGIN;

-- =============================================================================
-- LEWISTON (geo_id=2338740, chamber 'City Council')
-- 8 officials: Mayor + Council Member (Ward 1..7)
-- external_ids: -233871001 (Mayor) .. -233871008 (Ward 7)
-- =============================================================================

-- ===== Lewiston Mayor: Carl L. Sheline =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carl L. Sheline', 'Carl', 'Sheline', NULL,
          true, false, false, true, -233871001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 1: Joshua L. Nagine =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Joshua L. Nagine', 'Joshua', 'Nagine', NULL,
          true, false, false, true, -233871002,
          ARRAY['jnagine@lewistonmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 1)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 2: Susan G. Longchamps =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Susan G. Longchamps', 'Susan', 'Longchamps', NULL,
          true, false, false, true, -233871003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 2)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 3: Scott A. Harriman =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Scott A. Harriman', 'Scott', 'Harriman', NULL,
          true, false, false, true, -233871004,
          ARRAY['sharriman@lewistonmaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 3)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 4: Michael R. Roy =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Michael R. Roy', 'Michael', 'Roy', NULL,
          true, false, false, true, -233871005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 4)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 5: Chrissy Noble =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Chrissy Noble', 'Chrissy', 'Noble', NULL,
          true, false, false, true, -233871006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871006
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 5)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 6: David B. Chittim =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'David B. Chittim', 'David', 'Chittim', NULL,
          true, false, false, true, -233871007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 6)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 6)'
  AND o.politician_id IS NULL;

-- ===== Lewiston Ward 7: Bret Martel =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Bret Martel', 'Bret', 'Martel', NULL,
          true, false, false, true, -233871008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 7)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -233871008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2338740'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (Ward 7)'
  AND o.politician_id IS NULL;

-- ===== Lewiston office_id back-fill (-233871001..-233871008) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -233871008 AND -233871001
  AND p.office_id IS NULL;

-- =============================================================================
-- BANGOR (geo_id=2302795, chamber 'City Council')
-- 9 officials: Mayor (council-selected Chair) + Council Member (At-Large 1..8)
-- external_ids: -230271001 (Mayor) .. -230271009 (At-Large 8)
-- At-Large seat assignment: alphabetical by last name
--   Beck=AL1, Carson=AL2, Deane=AL3, Faloon=AL4, Fish=AL5,
--   Leonard=AL6, Mallar=AL7, Walker=AL8
-- IMPORTANT: Hawes is_appointed=false on POLITICIAN row (elected to council,
--   council then selected her as Chair). The OFFICE row's is_appointed_position=true
--   was set by migration 177 and is NOT changed here.
-- ALL 9 Bangor emails confirmed from bangormaine.gov/446/City-Council (2026-05-19)
-- =============================================================================

-- ===== Bangor Mayor (Council Chair): Susan Hawes =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Susan Hawes', 'Susan', 'Hawes', NULL,
          true, false, false, true, -230271001,
          ARRAY['susan.hawes@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 1: Michael Beck =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Michael Beck', 'Michael', 'Beck', NULL,
          true, false, false, true, -230271002,
          ARRAY['michael.beck@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 2: Daniel Carson =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Daniel Carson', 'Daniel', 'Carson', NULL,
          true, false, false, true, -230271003,
          ARRAY['daniel.carson@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 3: Susan Deane =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Susan Deane', 'Susan', 'Deane', NULL,
          true, false, false, true, -230271004,
          ARRAY['susan.deane@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 3)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 4: Susan Faloon =====
-- Note: email has mixed case 'Susan.Faloon@bangormaine.gov' — preserved exactly
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Susan Faloon', 'Susan', 'Faloon', NULL,
          true, false, false, true, -230271005,
          ARRAY['Susan.Faloon@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 4)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 5: Carolyn Fish =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Carolyn Fish', 'Carolyn', 'Fish', NULL,
          true, false, false, true, -230271006,
          ARRAY['carolyn.fish@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 5)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271006
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 5)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 6: Joseph Leonard =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Joseph Leonard', 'Joseph', 'Leonard', NULL,
          true, false, false, true, -230271007,
          ARRAY['joseph.leonard@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 6)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 6)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 7: Wayne Mallar =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Wayne Mallar', 'Wayne', 'Mallar', NULL,
          true, false, false, true, -230271008,
          ARRAY['wayne.mallar@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 7)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 7)'
  AND o.politician_id IS NULL;

-- ===== Bangor At-Large 8: Angela Walker =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses)
  VALUES (gen_random_uuid(), 'Angela Walker', 'Angela', 'Walker', NULL,
          true, false, false, true, -230271009,
          ARRAY['angela.walker@bangormaine.gov'])
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 8)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -230271009
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2302795'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 8)'
  AND o.politician_id IS NULL;

-- ===== Bangor office_id back-fill (-230271001..-230271009) =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -230271009 AND -230271001
  AND p.office_id IS NULL;

-- =============================================================================
-- SOUTH PORTLAND (geo_id=2371990, chamber 'City Council')
-- 8 office rows / 7 unique politicians
-- external_ids: -237191001 (Mayor+District5/Tipton) .. -237191008 (At-Large 2)
--
-- DUAL-OFFICE PATTERN (Tipton):
--   Elyse Tipton holds BOTH 'Mayor' AND 'Council Member (District 5)'.
--   She is INSERTed ONCE as external_id=-237191001.
--   First block: INSERT + UPDATE Mayor office.
--   Second block: UPDATE ONLY for 'Council Member (District 5)' (no INSERT).
--
-- SKIP -237191006: District 5 is held by Tipton (-237191001).
--   Do not INSERT any politician with external_id=-237191006.
--
-- No individual emails found; all email_addresses remain NULL.
-- =============================================================================

-- ===== South Portland Mayor + District 5: Elyse Tipton (DUAL OFFICE) =====
-- Step 1: INSERT Tipton + UPDATE Mayor office
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elyse Tipton', 'Elyse', 'Tipton', NULL,
          true, false, false, true, -237191001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- Fallback for Mayor if INSERT was a no-op (idempotency)
UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Mayor'
  AND o.politician_id IS NULL;

-- Step 2: UPDATE Council Member (District 5) for Tipton — no new INSERT
-- SKIP -237191006: District 5 is held by Tipton (-237191001)
UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191001
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 5)'
  AND o.politician_id IS NULL;

-- ===== South Portland District 1: Carter Scott =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Carter Scott', 'Carter', 'Scott', NULL,
          true, false, false, true, -237191002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191002
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 1)'
  AND o.politician_id IS NULL;

-- ===== South Portland District 2: Rachael Coleman =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Rachael Coleman', 'Rachael', 'Coleman', NULL,
          true, false, false, true, -237191003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191003
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 2)'
  AND o.politician_id IS NULL;

-- ===== South Portland District 3: Misha C. Pride =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Misha C. Pride', 'Misha', 'Pride', NULL,
          true, false, false, true, -237191004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 3)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191004
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 3)'
  AND o.politician_id IS NULL;

-- ===== South Portland District 4: Jessica L. Walker =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jessica L. Walker', 'Jessica', 'Walker', NULL,
          true, false, false, true, -237191005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 4)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191005
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (District 4)'
  AND o.politician_id IS NULL;

-- SKIP -237191006: District 5 is held by Tipton (-237191001); no politician INSERT here

-- ===== South Portland At-Large 1: Richard T. Matthews =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Richard T. Matthews', 'Richard', 'Matthews', NULL,
          true, false, false, true, -237191007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191007
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 1)'
  AND o.politician_id IS NULL;

-- ===== South Portland At-Large 2: Natalie West =====
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Natalie West', 'Natalie', 'West', NULL,
          true, false, false, true, -237191008)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
UPDATE essentials.offices o
SET politician_id = (SELECT id FROM ins_p),
    is_vacant = false
FROM essentials.chambers ch
JOIN essentials.governments g ON ch.government_id = g.id
WHERE o.chamber_id = ch.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

UPDATE essentials.offices o
SET politician_id = p.id, is_vacant = false
FROM essentials.politicians p,
     essentials.chambers ch,
     essentials.governments g
WHERE p.external_id = -237191008
  AND o.chamber_id = ch.id
  AND ch.government_id = g.id
  AND g.geo_id = '2371990'
  AND ch.name = 'City Council'
  AND o.title = 'Council Member (At-Large 2)'
  AND o.politician_id IS NULL;

-- ===== South Portland office_id back-fill (-237191001..-237191008) =====
-- Note: Tipton (-237191001) holds two offices (Mayor + District 5).
-- office_id will be set to whichever office UPDATE FOR picks first (both valid).
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -237191008 AND -237191001
  AND p.office_id IS NULL;

COMMIT;

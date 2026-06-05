-- Migration 231: Portland Officials Seed — 16 Portland politicians + offices + office_id back-fill
-- Applied 2026-05-30
--
-- Seeds 16 Portland officials under 'City of Portland, Oregon, US' (state='OR', geo_id='4159000'):
--   1 Mayor (-690001):                Keith Wilson           — LOCAL_EXEC, elected
--   1 City Auditor (-690002):         Simone Rede            — LOCAL_EXEC, elected
--   1 City Administrator (-690003):   Raymond C. Lee III     — LOCAL_EXEC, APPOINTED (is_appointed_position=true)
--   1 City Attorney (-690004):        Robert L. Taylor       — LOCAL_EXEC, APPOINTED (is_appointed_position=true)
--   3 District 1 council (-690010..-690012): Candace Avalos, Jamie Dunphy, Loretta Smith
--   3 District 2 council (-690013..-690015): Dan Ryan, Elana Pirtle-Guiney, Sameer Kanal
--   3 District 3 council (-690016..-690018): Angelita Morillo, Steve Novick, Tiffany Koyama Lane
--   3 District 4 council (-690019..-690021): Eric Zimmerman, Mitch Green, Olivia Clark
--
-- Analog: 214_berkeley_officials.sql (WITH ins_p CTE pattern; Mayor + Auditor on LOCAL_EXEC)
-- Key differences from Berkeley:
--   - Portland: 3 council offices per district (not 1), all pointing to same portland-or-council-district-N geo_id
--   - Portland: state='or' (lowercase) on districts WHERE clauses; state='OR' (uppercase) on government subquery
--   - Portland: 2 appointed officials (City Administrator + City Attorney) with is_appointed_position=true
--
-- VERIFIED per CF-1/CF-2/CF-3 in 077-RESEARCH.md:
--   CF-1: City Attorney is APPOINTED (2025 charter Article 2-201; only 3 elective offices: Mayor, Auditor, 12 Councilors)
--   CF-2: Incumbent roster from portland.gov/auditor/elections/elected-city-officials — CONTEXT.md D-06 names are wrong
--   CF-3: City Administrator is Raymond C. Lee III (NOT Michael Jordan who left Dec 2025)
--
-- TITLE FORMAT: 'City Councilor (District N)' — matches portland.gov display text and 2025 charter
-- (NOT 'City Council Member (District N)' from CONTEXT.md D-07 — that wording is superseded)
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed_position = true ONLY on -690003 (Lee III) and -690004 (Taylor); false on other 14
--   offices column list: id, district_id, chamber_id, politician_id, title, representing_state,
--                        is_appointed_position, is_vacant, role_canonical
--   NO seat_label, email, is_active in offices INSERT

BEGIN;

-- =============================================================================
-- BLOCK 1: Mayor Keith Wilson (-690001) — LOCAL_EXEC, elected
-- =============================================================================
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Keith Wilson', 'Keith', 'Wilson', NULL,
          true, false, false, true, -690001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='Mayor'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'Mayor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4159000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCK 2: City Auditor Simone Rede (-690002) — LOCAL_EXEC, elected
-- =============================================================================
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Simone Rede', 'Simone', 'Rede', NULL,
          true, false, false, true, -690002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Auditor'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Auditor', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4159000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCK 3: City Administrator Raymond C. Lee III (-690003) — LOCAL_EXEC, APPOINTED
-- CF-3: NOT Michael Jordan (left Dec 2025); Lee III confirmed Dec 2025
-- is_appointed_position=true per D-04 and CF-3
-- =============================================================================
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Raymond C. Lee III', 'Raymond', 'Lee', NULL,
          true, false, false, true, -690003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Administrator'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Administrator', 'OR', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4159000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCK 4: City Attorney Robert L. Taylor (-690004) — LOCAL_EXEC, APPOINTED
-- CF-1: appointed by City Council per 2025 charter Article 2-201; NOT elected
-- is_appointed_position=true per CF-1
-- =============================================================================
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Robert L. Taylor', 'Robert', 'Taylor', NULL,
          true, false, false, true, -690004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Attorney'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Attorney', 'OR', true, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '4159000'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCKS 5-7: District 1 Council Members
-- CF-2: verified from portland.gov/auditor/elections/elected-city-officials
-- Correct names: Candace Avalos, Jamie Dunphy, Loretta Smith
-- NOT: Timur Ataseven, Tiffany Kachima (wrong CONTEXT.md D-06 names)
-- =============================================================================

-- BLOCK 5: Candace Avalos (District 1, -690010)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Candace Avalos', 'Candace', 'Avalos', NULL,
          true, false, false, true, -690010)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 6: Jamie Dunphy (District 1, -690011)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jamie Dunphy', 'Jamie', 'Dunphy', NULL,
          true, false, false, true, -690011)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 7: Loretta Smith (District 1, -690012)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Loretta Smith', 'Loretta', 'Smith', NULL,
          true, false, false, true, -690012)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 1)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-1'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCKS 8-10: District 2 Council Members
-- CF-2: verified from portland.gov/auditor/elections/elected-city-officials
-- Correct names: Dan Ryan, Elana Pirtle-Guiney, Sameer Kanal
-- NOT: Candace Avalos, Maxine Dexter, Eric Zimmerman (wrong CONTEXT.md D-06 names)
-- =============================================================================

-- BLOCK 8: Dan Ryan (District 2, -690013)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dan Ryan', 'Dan', 'Ryan', NULL,
          true, false, false, true, -690013)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 9: Elana Pirtle-Guiney (District 2, -690014)
-- NOTE: hyphen preserved in last name: 'Pirtle-Guiney'
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elana Pirtle-Guiney', 'Elana', 'Pirtle-Guiney', NULL,
          true, false, false, true, -690014)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 10: Sameer Kanal (District 2, -690015)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Sameer Kanal', 'Sameer', 'Kanal', NULL,
          true, false, false, true, -690015)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 2)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-2'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCKS 11-13: District 3 Council Members
-- CF-2: verified from portland.gov/auditor/elections/elected-city-officials
-- Correct names: Angelita Morillo, Steve Novick, Tiffany Koyama Lane
-- NOT: Steve Novick (correct), Angelita Morillo (correct), Chris Carey (wrong CONTEXT D-06 name)
-- NOTE: space preserved in last name: 'Koyama Lane'
-- =============================================================================

-- BLOCK 11: Angelita Morillo (District 3, -690016)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Angelita Morillo', 'Angelita', 'Morillo', NULL,
          true, false, false, true, -690016)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 12: Steve Novick (District 3, -690017)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steve Novick', 'Steve', 'Novick', NULL,
          true, false, false, true, -690017)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 13: Tiffany Koyama Lane (District 3, -690018)
-- NOTE: last_name='Koyama Lane' with space preserved
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tiffany Koyama Lane', 'Tiffany', 'Koyama Lane', NULL,
          true, false, false, true, -690018)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 3)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-3'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BLOCKS 14-16: District 4 Council Members
-- CF-2: verified from portland.gov/auditor/elections/elected-city-officials
-- Correct names: Eric Zimmerman, Mitch Green, Olivia Clark
-- NOT: Jonathan Tasini, Elana Pirtle-Guiney (wrong CONTEXT.md D-06 names)
-- =============================================================================

-- BLOCK 14: Eric Zimmerman (District 4, -690019)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Eric Zimmerman', 'Eric', 'Zimmerman', NULL,
          true, false, false, true, -690019)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 15: Mitch Green (District 4, -690020)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mitch Green', 'Mitch', 'Green', NULL,
          true, false, false, true, -690020)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- BLOCK 16: Olivia Clark (District 4, -690021)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Olivia Clark', 'Olivia', 'Clark', NULL,
          true, false, false, true, -690021)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments
                             WHERE name='City of Portland, Oregon, US' AND state='OR')),
       p.id,
       'City Councilor (District 4)', 'OR', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'portland-or-council-district-4'
  AND d.district_type = 'LOCAL'
  AND d.state = 'or'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- BACK-FILL: Update politicians.office_id for all 16 Portland officials
-- REQUIRED: Plan 77-03 headshot work-list query joins politicians on office_id.
-- Without this UPDATE the headshot work-list returns 0 rows.
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -690021 AND -690001
  AND p.office_id IS NULL;

-- =============================================================================
-- LEDGER ENTRY
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('231')
ON CONFLICT (version) DO NOTHING;

COMMIT;

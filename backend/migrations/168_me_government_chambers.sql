-- Migration 168: State of Maine government row + 6 chambers
--
-- Creates the state government row and all chamber scaffolds required for
-- Phase 51 (executives), Phase 52 (legislature), and Phase 53+ (cities).
--
-- Chambers created (6 total):
--   Legislative: Maine Senate, Maine House of Representatives
--   Executive:   Maine Governor, Maine Attorney General,
--                Maine Secretary of State, Maine Treasurer
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never insert it.
-- CRITICAL: governments has no unique constraint on geo_id — guard by name.
-- CRITICAL: state='ME' uppercase for governments (matches TX='TX', MA='MA').
-- Maine FIPS state code: 23
--
-- Idempotency: all inserts guarded by WHERE NOT EXISTS. Safe to re-run.

BEGIN;

-- Government row
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'State of Maine', 'STATE', 'ME', '', '23'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'State of Maine'
);

-- Maine Senate chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine Senate',
       'Maine Senate',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

-- Maine House of Representatives chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine House of Representatives',
       'Maine House of Representatives',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine House of Representatives'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

-- Maine Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine Governor',
       'Maine Governor',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

-- Maine Attorney General chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine Attorney General',
       'Maine Attorney General',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine Attorney General'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

-- Maine Secretary of State chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine Secretary of State',
       'Maine Secretary of State',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine Secretary of State'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

-- Maine Treasurer chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Maine Treasurer',
       'Maine Treasurer',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Maine Treasurer'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maine')
);

COMMIT;

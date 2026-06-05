-- Migration 189: State of California government row + 8 constitutional officer chambers
--
-- Creates (or fixes) the state government row and verifies all executive chamber
-- scaffolds required for Phase 59 (CA government DB foundation) and subsequent CA phases.
--
-- Government row:
--   name    = 'State of California'
--   type    = 'STATE'
--   state   = 'CA'  (uppercase — matches TX='TX', ME='ME', MA='MA')
--   city    = ''    (empty string)
--   geo_id  = '06'  (CA FIPS 2-digit padded — NOT '6')
--
-- NOTE: The 'State of California' government row already existed in production with
-- geo_id=NULL. This migration fixes that with an UPDATE and inserts it if absent.
-- The government UUID is: e0f33bda-bfb5-4dd0-9816-576e6ce35fac
--
-- Chambers created (8 total — all constitutional executive officers):
-- NOTE: These 8 chambers already existed in production under short names (no "California" prefix).
-- Existing names and their slugs (verified 2026-05-21):
--   Governor               → slug: california-governor
--   Lieutenant Governor    → slug: california-lieutenant-governor
--   Attorney General       → slug: attorney-general-of-the-state-of-california
--   Secretary of State     → slug: california-secretary-of-state
--   Controller             → slug: california-state-controller
--   Treasurer              → slug: california-state-treasurer
--   Commissioner of Insurance  → slug: california-commissioner-of-insurance
--   Superintendent of Public Instruction → slug: california-superintendent-of-public-instruction
--
-- The chamber INSERTs below use WHERE NOT EXISTS guards — they are no-ops in production
-- because all 8 chambers already exist. They are retained for correctness in case
-- this migration is applied to a fresh database.
--
-- FUTURE PLANS: When referencing CA chambers, use the SHORT names listed above
-- (e.g., WHERE name = 'Governor' AND government_id = (SELECT id FROM ... 'State of California')).
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — NEVER insert it.
-- CRITICAL: governments has no unique constraint on geo_id — guard by name.
-- CRITICAL: geo_id must be '06' (padded) — never '6'.
-- CRITICAL: state must be 'CA' uppercase.
-- CRITICAL: never hardcode the government UUID — always use subquery by name.
--
-- Idempotency: all inserts/updates guarded by WHERE NOT EXISTS / WHERE conditions. Safe to re-run.

BEGIN;

-- Government row: insert if missing
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'State of California', 'STATE', 'CA', '', '06'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'State of California'
);

-- Government row: fix geo_id if row exists but geo_id is NULL or empty
UPDATE essentials.governments
SET geo_id = '06'
WHERE name = 'State of California'
  AND (geo_id IS NULL OR geo_id = '');

-- Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Governor',
       'California Governor',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Lieutenant Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Lieutenant Governor',
       'California Lieutenant Governor',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Lieutenant Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Attorney General chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Attorney General',
       'Attorney General of the State of California',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Attorney General'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Secretary of State chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Secretary of State',
       'California Secretary of State',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Secretary of State'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Controller chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Controller',
       'California State Controller',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Controller'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Treasurer chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Treasurer',
       'California State Treasurer',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Treasurer'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Insurance Commissioner chamber (stored as 'Commissioner of Insurance')
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Commissioner of Insurance',
       'California Commissioner of Insurance',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Commissioner of Insurance'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- Superintendent of Public Instruction chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Superintendent of Public Instruction',
       'California Superintendent of Public Instruction',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Superintendent of Public Instruction'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

COMMIT;

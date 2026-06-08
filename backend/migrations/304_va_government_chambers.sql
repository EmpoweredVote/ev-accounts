-- Migration 304: 5 VA executive/legislative chambers under the existing State of Virginia government row
--
-- Source analog: C:/EV-Accounts/backend/migrations/269_md_government_chambers.sql
-- Phase: 101
-- Requirement: VA-GOV-01
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include
-- in INSERT column list or the INSERT will error.
--
-- CRITICAL: essentials.governments has no unique constraint on geo_id — use
-- name+state subquery to resolve government_id (not ON CONFLICT on geo_id).
--
-- CRITICAL: The government subquery uses AND state = 'VA' to distinguish from
-- 'State of West Virginia' (UUID 74564736) which has an overlapping name prefix.
--
-- Purpose: Seeds 5 chamber scaffolds (Governor, Lieutenant Governor, Attorney General,
-- Virginia Senate, House of Delegates) under the pre-existing State of Virginia government
-- row (seeded in the bulk 50-state government stub creation).
--
-- IMPORTANT: State of Virginia government row already exists (UUID bf1095e6-8f88-41cd-b758-23c1ba1297b5).
-- This migration does NOT insert into essentials.governments — it asserts exactly 1 row
-- exists and proceeds to create chambers under it.
--
-- NOTE: VA has only 3 voter-elected executives (Governor, LG, AG) — no Comptroller or
-- State Treasurer equivalent. Do NOT seed Comptroller or Treasurer chambers.
--
-- Chamber naming convention:
--   Governor         / Governor of Virginia
--   Lieutenant Governor / Lieutenant Governor of Virginia
--   Attorney General / Attorney General of Virginia
--   Virginia Senate  / Virginia Senate   (self-qualifying — state name in chamber name; OR/MD precedent)
--   House of Delegates / Virginia House of Delegates  (short name omits "Virginia" for display brevity)
--
-- Idempotency: all INSERTs are guarded by WHERE NOT EXISTS on (name + government_id).
-- Safe to re-run — produces no errors and no duplicate rows.

BEGIN;

-- Pre-flight: assert State of Virginia government row exists (exactly 1 row)
-- DO NOT insert — row pre-exists; if missing or duplicated, fail fast.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Virginia' AND state = 'VA') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Virginia government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Virginia' AND state = 'VA');
  END IF;
END $$;

-- Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Governor',
       'Governor of Virginia',
       (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
);

-- Lieutenant Governor chamber
-- Standalone chamber (NOT under Governor) — Hashmi is separately elected statewide
-- and has independent constitutional duties.
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Lieutenant Governor',
       'Lieutenant Governor of Virginia',
       (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Lieutenant Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
);

-- Attorney General chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Attorney General',
       'Attorney General of Virginia',
       (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Attorney General'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
);

-- Virginia Senate chamber
-- Self-qualifying name: name and name_formal are both 'Virginia Senate'
-- (OR/MD precedent: "Oregon Senate"/"Maryland Senate" — state name already embedded)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Virginia Senate',
       'Virginia Senate',
       (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Virginia Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
);

-- House of Delegates chamber
-- Short name: 'House of Delegates'; formal name: 'Virginia House of Delegates'
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'House of Delegates',
       'Virginia House of Delegates',
       (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'House of Delegates'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA')
);

COMMIT;

-- Migration 269: 5 MD executive chambers under the existing State of Maryland government row
--
-- Purpose: Seeds 5 chamber scaffolds (Governor, Lieutenant Governor, Attorney General,
-- Comptroller, State Treasurer) under the pre-existing State of Maryland government row
-- (seeded in migration 174 as part of the bulk 50-state government stub creation).
--
-- IMPORTANT: State of Maryland government row already exists from migration 174
-- (174_senate_infrastructure.sql). This migration does NOT insert into
-- essentials.governments — it asserts exactly 1 row exists and proceeds to
-- create chambers under it.
--
-- Decision D-01: Lieutenant Governor gets her own standalone chamber (NOT modeled
-- under the Governor's chamber). Aruna Miller is separately elected statewide and has
-- independent constitutional duties (chairs Board of Public Works). This results in
-- 5 chambers total, not 4.
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include
-- in INSERT column list or the INSERT will error.
--
-- CRITICAL: essentials.governments has no unique constraint on geo_id — use
-- name+state subquery to resolve government_id (not ON CONFLICT on geo_id).
--
-- Naming convention: Short names for the `name` column (OR/CA pattern, most recent
-- precedent) with state-qualified forms in name_formal.
-- Example: name='Governor', name_formal='Governor of Maryland'
-- Exception: State Treasurer uses asymmetric formal name:
--   name='State Treasurer', name_formal='Maryland State Treasurer'
--   (consistent with OR migration 222 precedent for the same chamber)
--
-- Idempotency: all INSERTs are guarded by WHERE NOT EXISTS on (name + government_id).
-- Safe to re-run — produces no errors and no duplicate rows.

BEGIN;

-- Pre-flight: assert State of Maryland government row exists (exactly 1 row)
-- DO NOT insert — row pre-exists from migration 174; if missing or duplicated, fail fast.
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Maryland' AND state = 'MD') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Maryland government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Maryland' AND state = 'MD');
  END IF;
END $$;

-- Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Governor',
       'Governor of Maryland',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

-- Lieutenant Governor chamber
-- D-01: standalone chamber (NOT under Governor) — Aruna Miller is separately elected
-- statewide; independent constitutional duties (chairs Board of Public Works)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Lieutenant Governor',
       'Lieutenant Governor of Maryland',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Lieutenant Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

-- Attorney General chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Attorney General',
       'Attorney General of Maryland',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Attorney General'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

-- Comptroller chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Comptroller',
       'Comptroller of Maryland',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Comptroller'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

-- State Treasurer chamber
-- Asymmetric formal name: 'Maryland State Treasurer' (not 'State Treasurer of Maryland')
-- Consistent with OR migration 222 precedent for this same chamber type.
-- Note: Dereck E. Davis is legislature-elected (is_appointed_position=true on his office row)
-- but the chamber itself is named the same regardless of appointment mechanism.
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'State Treasurer',
       'Maryland State Treasurer',
       (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'State Treasurer'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD')
);

COMMIT;

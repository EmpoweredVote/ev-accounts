-- Migration 222: 7 OR chambers under the existing State of Oregon government row
--
-- Purpose: Seeds 7 chamber scaffolds under the pre-existing State of Oregon
-- government row (geo_id='41'). This is the foundation for Phases 74-77
-- (OR executives, legislature, Portland city structure).
--
-- IMPORTANT: State of Oregon government row already exists (no governments INSERT).
-- Phase 72 confirmed the State of Oregon row (geo_id='41'). Phase 73 creates
-- chambers only — no government row INSERT, no politicians, no offices, no districts.
--
-- Chambers created (7 total):
--   Executive: Governor, Attorney General, Secretary of State,
--              State Treasurer, Labor Commissioner
--   Legislative: Oregon Senate, Oregon House of Representatives
--
-- CRITICAL: slug is GENERATED ALWAYS on essentials.chambers — never include
-- in INSERT column list or the INSERT will error (D-04).
--
-- CRITICAL: essentials.governments has no unique constraint on geo_id — use
-- name-based subquery to resolve government_id (D-01 canonical pattern).
-- Phase 73 does NOT insert into essentials.governments.
--
-- Naming convention: Short names for the `name` column (CA pattern, most recent
-- precedent) with state-qualified forms in name_formal.
-- Example: name='Governor', name_formal='Governor of Oregon'
-- Exception: bicameral legislative chambers whose name already contains the state
-- carry identical name/name_formal values — see ME (migration 168) and CA (migration 189) precedent.
--
-- All 7 chambers will have is_appointed_position=false on their downstream
-- offices (Phase 74+) — all are voter-elected statewide in Oregon (D-03).
-- This differs from ME where AG/SoS/Treasurer were legislature-elected.
--
-- Migration number: 222 (D-05 note: CONTEXT.md listed 221 as next, but
-- 221_sj_stances.sql landed before Phase 73 started; 222 is the actual
-- next free number verified via directory listing).
--
-- Idempotency: all INSERTs are guarded by WHERE NOT EXISTS on (name + government_id).
-- Safe to re-run — produces no errors and no duplicate rows.

BEGIN;

-- Pre-flight: assert State of Oregon government row exists (exactly 1 row)
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'State of Oregon' AND state = 'OR') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Oregon government row; found %',
      (SELECT COUNT(*) FROM essentials.governments
       WHERE name = 'State of Oregon' AND state = 'OR');
  END IF;
END $$;

-- Governor chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Governor',
       'Governor of Oregon',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Governor'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- Oregon Senate chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Oregon Senate',
       'Oregon Senate',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Oregon Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- Oregon House of Representatives chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Oregon House of Representatives',
       'Oregon House of Representatives',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Oregon House of Representatives'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- Attorney General chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Attorney General',
       'Attorney General of Oregon',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Attorney General'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- Secretary of State chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Secretary of State',
       'Oregon Secretary of State',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Secretary of State'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- State Treasurer chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'State Treasurer',
       'Oregon State Treasurer',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'State Treasurer'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

-- Labor Commissioner chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Labor Commissioner',
       'Oregon Labor Commissioner',
       (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Labor Commissioner'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR')
);

COMMIT;

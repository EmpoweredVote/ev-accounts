-- Migration 306: VA State Executives (Spanberger, Hashmi, Jones)
--
-- Seeds 3 STATE_EXEC districts, 3 politicians, 3 offices, and back-fills
-- office_id on all 3 politicians.
--
-- Source analog: C:/EV-Accounts/backend/migrations/270_md_state_executives.sql (exact adapt)
-- Phase: 101-va-state-government-db
-- Requirements: VA-GOV-02 (3 execs with STATE_EXEC districts), VA-GOV-05 (all voter-elected)
--
-- CRITICAL (1): state='VA' UPPERCASE for STATE_EXEC districts.
--   OR migration 223a lesson — lowercase 'va' silently breaks backend routing because
--   the backend queries districts with WHERE state='VA', not 'va'.
--   All existing STATE_EXEC rows in production use uppercase postal abbreviation.
--
-- CRITICAL (2): district_id='' (empty string, not a named string).
--   OR 223a confirmed that a descriptive district_id (e.g. 'Virginia (Statewide)') is wrong.
--   '' is the correct multi-position statewide value.
--
-- CRITICAL (3): geo_id='51' (Virginia FIPS code).
--
-- CRITICAL (4): ALL 3 executives are voter-elected (VA-GOV-05).
--   Virginia has NO legislature-elected executives (differs from MD where Treasurer is
--   legislature-elected). All 3 have is_appointed=false and is_appointed_position=false.
--   DO NOT set is_appointed=true or is_appointed_position=true for any VA executive.
--
-- Chamber names created by migration 304 (Plan 01):
--   'Governor', 'Lieutenant Governor', 'Attorney General'
--   All under government_id = (State of Virginia, state='VA').
--
-- Note: Plan 02 originally specified migration number 301, but 300-305 are occupied
--   by LA Wave 2/3 city seed migrations. Migration 306 is the next available number.
--
-- external_id range: -510003..-510001 (FIPS-prefix pattern: -51XXXX for exec range)
-- Back-fill range widened to -510010..-510001 for future-proofing (MD 270 pattern).
--
-- role_canonical is set NULL for all 3 (cross-state mapping deferred).
--
-- All inserts are idempotent (WHERE NOT EXISTS / ON CONFLICT DO NOTHING).

BEGIN;

-- ===== Pre-flight: assert State of Virginia government row exists =====
-- State of Virginia government row pre-exists (UUID: bf1095e6-8f88-41cd-b758-23c1ba1297b5).
-- This migration must NOT insert it — assert exactly 1 row exists.
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

-- ===== STEP 1: Create 3 STATE_EXEC districts (one per executive office) =====
-- CRITICAL: state='VA' uppercase — lowercase 'va' breaks routing (OR 223a lesson).
-- district_id='' (empty string) — OR 223a confirmed '' is the correct value.
-- mtfcc='' — no TIGER MTFCC applies to executive office districts.

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'VA', '51', 'Virginia Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'VA' AND label = 'Virginia Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'VA', '51', 'Virginia Lieutenant Governor', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'VA' AND label = 'Virginia Lieutenant Governor'
);

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'VA', '51', 'Virginia Attorney General', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'VA' AND label = 'Virginia Attorney General'
);

-- ===== STEP 2: Politicians + Offices (one CTE block per executive) =====
-- Pattern: WITH ins_p AS (INSERT ... ON CONFLICT DO NOTHING RETURNING id)
--          INSERT INTO offices ... SELECT ... FROM districts CROSS JOIN ins_p
--          WHERE p.id IS NOT NULL (guards against DO NOTHING returning nothing)
--          AND NOT EXISTS (SELECT 1 FROM offices WHERE district_id=... AND chamber_id=...)
--          Uses (district_id, chamber_id) NOT EXISTS — single-member guard.
--
-- Chamber name lookup: use short name + government_id subquery for 'State of Virginia'
-- AND state='VA'. The AND state='VA' guard prevents accidental match on West Virginia.
--
-- representing_state='VA' for all 3 offices.

-- ----- Governor: Abigail Spanberger (-510001) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Abigail Spanberger', 'Abigail', 'Spanberger', 'Democrat',
          true, false, false, true, -510001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Governor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Governor', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'VA' AND d.label = 'Virginia Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Governor'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ----- Lieutenant Governor: Ghazala Hashmi (-510002) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Ghazala Hashmi', 'Ghazala', 'Hashmi', 'Democrat',
          true, false, false, true, -510002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Lieutenant Governor'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Lieutenant Governor', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'VA' AND d.label = 'Virginia Lieutenant Governor'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Lieutenant Governor'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ----- Attorney General: Jay Jones (-510003) — VOTER-ELECTED -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Jay Jones', 'Jay', 'Jones', 'Democrat',
          true, false, false, true, -510003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Attorney General'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'State of Virginia' AND state = 'VA')),
       p.id,
       'Attorney General', 'VA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'VA' AND d.label = 'Virginia Attorney General'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Attorney General'
                            AND government_id = (SELECT id FROM essentials.governments
                                                 WHERE name = 'State of Virginia' AND state = 'VA'))
  );

-- ===== STEP 3: office_id back-fill =====
-- Scoped to -510010..-510001 to cover any future VA execs in the same range.
-- Guard with p.office_id IS NULL for idempotency (re-run = 0 rows affected).

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -510010 AND -510001
  AND p.office_id IS NULL;

COMMIT;

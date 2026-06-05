BEGIN;

-- Migration 230: Portland OR government structure
--
-- Creates:
--   1 government row: 'City of Portland, Oregon, US' (type='LOCAL', state='OR', geo_id='4159000')
--   5 chamber rows:   City Council, Mayor, City Auditor, City Administrator, City Attorney
--   1 district row:   LOCAL_EXEC Portland-wide district (geo_id='4159000', for Mayor + City Auditor
--                     + City Administrator + City Attorney)
--
-- Note: 4 LOCAL council district rows (portland-or-council-district-{1-4}) were created in
-- migration 229 (Phase 76 Portland council geofences) — NOT repeated here.
--
-- Idempotent via WHERE NOT EXISTS guards:
--   - essentials.governments has NO unique constraint on geo_id
--   - essentials.districts has NO unique constraint on (geo_id, district_type)
--   - DO NOT use ON CONFLICT (geo_id, district_type) — that constraint does not exist
--   - essentials.chambers.slug is a GENERATED ALWAYS column — never include in INSERT columns
--
-- State casing (CRITICAL — OR-specific):
--   - essentials.governments.state = 'OR' (uppercase) — government table convention
--   - essentials.districts.state   = 'or' (lowercase) — matches OR TIGER loader convention
--     (confirmed Phase 76 migration 229 used 'or' for portland-or-council-district-{1-4})
--
-- Portland 2025 charter reform:
--   - 3 elective offices: Mayor (citywide), 12 Councilors (4 multi-member districts, 3 each),
--     and City Auditor (citywide). All elected via Ranked Choice Voting.
--   - City Administrator (Raymond C. Lee III): APPOINTED — is_appointed_position=true
--   - City Attorney (Robert L. Taylor): APPOINTED — is_appointed_position=true
--   - Both appointed officials get chambers for parity with SF pattern.
--
-- After this migration, plan 77-02 seeds 16 politicians and their office rows.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Government row (City of Portland, Oregon, US)
-- Full-form name distinguishes from 'City of Portland, Maine, US' already in DB.
-- state='OR' uppercase (government table convention).
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of Portland, Oregon, US',
       'LOCAL', 'OR', 'Portland', '4159000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of Portland, Oregon, US' AND state = 'OR'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Five chamber rows (slug is GENERATED ALWAYS — never include in INSERT)
-- ─────────────────────────────────────────────────────────────────────────────

-- City Council chamber (district-based, 12 seats across 4 multi-member districts via RCV)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'Portland City Council',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
);

-- Mayor chamber (citywide, independently elected via RCV)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'Mayor', 'Mayor of Portland',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Mayor'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
);

-- City Auditor chamber (citywide, independently elected via RCV)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Auditor', 'Portland City Auditor',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Auditor'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
);

-- City Administrator chamber (appointed by City Council; is_appointed_position=true on office row)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Administrator', 'Portland City Administrator',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Administrator'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
);

-- City Attorney chamber (appointed by and serves at the pleasure of the full City Council;
-- is_appointed_position=true on office row; current incumbent: Robert L. Taylor, Feb 2025)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Attorney', 'Portland City Attorney',
       (SELECT id FROM essentials.governments
        WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Attorney'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of Portland, Oregon, US' AND state = 'OR')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Portland-wide LOCAL_EXEC district (for citywide offices)
-- Covers: Mayor, City Auditor (elected) + City Administrator, City Attorney (appointed)
-- Reuses geo_id='4159000' (Portland TIGER G4110 boundary from Phase 72 OR geofences)
--
-- CRITICAL: state='or' lowercase — matches Phase 76 migration 229 portland-or-council-district-{1-4}
--           rows which use state='or'. Routing queries join on lowercase state for LOCAL/LOCAL_EXEC.
-- CRITICAL: NO ON CONFLICT (geo_id, district_type) — that unique constraint does NOT exist.
-- CRITICAL: Column is 'label' NOT 'name' — essentials.districts has no 'name' column.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '4159000', 'LOCAL_EXEC', 'Portland (Citywide)', 'or'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '4159000' AND state = 'or' AND district_type IN ('LOCAL', 'LOCAL_EXEC')
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Ledger entry
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('230')
ON CONFLICT (version) DO NOTHING;

COMMIT;

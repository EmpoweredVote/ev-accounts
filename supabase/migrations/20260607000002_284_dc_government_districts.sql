-- =============================================================================
-- Migration 284: DC Government Stub + 19 District Records
-- DCIN-01: District of Columbia government row in essentials.governments
-- DCIN-02: 19 district rows — 8 CITY_COUNCIL ward + 1 CITY_COUNCIL at-large +
--          9 SCHOOL_BOARD (8 ward + 1 at-large) + 1 NATIONAL_LOWER
--
-- Pre-flight verification (run before applying):
--   SELECT MAX(version) FROM supabase_migrations.schema_migrations;
--   -- Expected: 283
--   SELECT DISTINCT type FROM essentials.governments ORDER BY type;
--   -- Confirm 'LOCAL' is a valid value (used by SF, SJ, SD, Berkeley, Fremont)
--
-- DC FIPS: 11 (state-equivalent)
-- DC ward TIGER GEOIDs: 11001–11008 (backfilled in migration 285 after geo_districts seeded)
-- geo_id '11' for government: consistent with TX = '48', IN = '18', etc.
-- =============================================================================

BEGIN;

-- =============================================================================
-- Section 1: DC Government Stub (DCIN-01)
-- =============================================================================

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'District of Columbia', 'LOCAL', 'DC', 'Washington', '11'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'District of Columbia' AND state = 'DC'
);

-- =============================================================================
-- Section 2: District Records (DCIN-02) — 19 rows total
--
-- Naming convention (slug pattern, consistent with SJ/SD/Berkeley):
--   CITY_COUNCIL ward:   dc-ward-1 through dc-ward-8
--   CITY_COUNCIL at-lg:  dc-council-at-large (Chairman + 4 at-large members)
--   SCHOOL_BOARD ward:   dc-sboe-ward-1 through dc-sboe-ward-8
--   SCHOOL_BOARD at-lg:  dc-sboe-at-large (Jacque Patterson, President)
--   NATIONAL_LOWER:      dc-national-lower (EHN delegate seat + shadow senators)
--
-- tiger_geoid is NULL for all rows here — backfilled in migration 285 for the
-- 8 CITY_COUNCIL ward rows after geo_districts is seeded with dc_ward layer.
--
-- PITFALL-6 resolution: Adding dc-council-at-large as a 9th CITY_COUNCIL row
-- (consistent with D-07 SBOE at-large pattern). Without it, Chairman + 4
-- at-large council members would have no district FK.
-- =============================================================================

INSERT INTO essentials.districts (geo_id, district_type, label, state, government_id)
SELECT v.geo_id, v.district_type, v.label, v.state,
       (SELECT id FROM essentials.governments WHERE name = 'District of Columbia' AND state = 'DC')
FROM (VALUES
  -- CITY_COUNCIL ward seats (8)
  ('dc-ward-1',  'CITY_COUNCIL', 'Ward 1', 'DC'),
  ('dc-ward-2',  'CITY_COUNCIL', 'Ward 2', 'DC'),
  ('dc-ward-3',  'CITY_COUNCIL', 'Ward 3', 'DC'),
  ('dc-ward-4',  'CITY_COUNCIL', 'Ward 4', 'DC'),
  ('dc-ward-5',  'CITY_COUNCIL', 'Ward 5', 'DC'),
  ('dc-ward-6',  'CITY_COUNCIL', 'Ward 6', 'DC'),
  ('dc-ward-7',  'CITY_COUNCIL', 'Ward 7', 'DC'),
  ('dc-ward-8',  'CITY_COUNCIL', 'Ward 8', 'DC'),
  -- CITY_COUNCIL at-large (Chairman Mendelson + 4 at-large members)
  -- PITFALL-6 resolution: at-large Council members cannot FK to a ward district
  ('dc-council-at-large', 'CITY_COUNCIL', 'DC Council At-Large', 'DC'),
  -- SCHOOL_BOARD ward seats (8)
  ('dc-sboe-ward-1', 'SCHOOL_BOARD', 'SBOE Ward 1', 'DC'),
  ('dc-sboe-ward-2', 'SCHOOL_BOARD', 'SBOE Ward 2', 'DC'),
  ('dc-sboe-ward-3', 'SCHOOL_BOARD', 'SBOE Ward 3', 'DC'),
  ('dc-sboe-ward-4', 'SCHOOL_BOARD', 'SBOE Ward 4', 'DC'),
  ('dc-sboe-ward-5', 'SCHOOL_BOARD', 'SBOE Ward 5', 'DC'),
  ('dc-sboe-ward-6', 'SCHOOL_BOARD', 'SBOE Ward 6', 'DC'),
  ('dc-sboe-ward-7', 'SCHOOL_BOARD', 'SBOE Ward 7', 'DC'),
  ('dc-sboe-ward-8', 'SCHOOL_BOARD', 'SBOE Ward 8', 'DC'),
  -- SCHOOL_BOARD at-large (Jacque Patterson, President); tiger_geoid = NULL per D-07
  ('dc-sboe-at-large', 'SCHOOL_BOARD', 'SBOE At-Large', 'DC'),
  -- NATIONAL_LOWER: EHN delegate seat + shadow senators (D-06)
  ('dc-national-lower', 'NATIONAL_LOWER', 'District of Columbia At-Large', 'DC')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id
    AND d.district_type = v.district_type
    AND d.state = v.state
);

COMMIT;

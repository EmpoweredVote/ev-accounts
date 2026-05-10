BEGIN;

-- =============================================================================
-- Migration 091: Backfill essentials.districts.tiger_geoid
-- GEO-09: link existing politician/office district rows to TIGER GEOIDs
--
-- Prereq: Plan 69-02 Task 2 import completed (essentials.geo_districts populated
-- with ca_assembly, ca_senate, us_house layers — 80+40+52 rows).
--
-- Fix: The UNIQUE constraint added in migration 089 is too strict. Assembly district
-- 20 and Senate district 20 both have TIGER geo_id '06020' — same number format,
-- different layers. tiger_geoid must allow duplicates. We drop the unique constraint
-- and add a plain index instead (still supports JOIN lookups).
--
-- Idempotency: WHERE d.tiger_geoid IS NULL ensures re-running does not overwrite
-- any manually-corrected mappings.
--
-- Investigation findings (Task 3 Step A):
--   district_type for CA Assembly  = 'STATE_LOWER'    (80 CA rows)
--   district_type for CA Senate    = 'STATE_UPPER'    (40 CA rows)
--   district_type for US House CA  = 'NATIONAL_LOWER' (52 CA geoids in geo_districts)
--   Join column: d.geo_id = gd.geoid (direct TIGER GEOID match)
-- =============================================================================

-- Drop overly-restrictive UNIQUE constraint from migration 089
ALTER TABLE essentials.districts
  DROP CONSTRAINT IF EXISTS districts_tiger_geoid_key;

-- Add plain index for JOIN performance (non-unique)
CREATE INDEX IF NOT EXISTS idx_districts_tiger_geoid
  ON essentials.districts (tiger_geoid)
  WHERE tiger_geoid IS NOT NULL;

-- CA Assembly (STATE_LOWER)
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE d.tiger_geoid IS NULL
  AND d.state = 'CA'
  AND d.district_type = 'STATE_LOWER'
  AND gd.layer = 'ca_assembly'
  AND d.geo_id = gd.geoid;

-- CA Senate (STATE_UPPER)
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE d.tiger_geoid IS NULL
  AND d.state = 'CA'
  AND d.district_type = 'STATE_UPPER'
  AND gd.layer = 'ca_senate'
  AND d.geo_id = gd.geoid;

-- US House CA (NATIONAL_LOWER, state = 'CA' filter ensures only CA rows)
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE d.tiger_geoid IS NULL
  AND d.state = 'CA'
  AND d.district_type = 'NATIONAL_LOWER'
  AND gd.layer = 'us_house'
  AND d.geo_id = gd.geoid;

COMMIT;

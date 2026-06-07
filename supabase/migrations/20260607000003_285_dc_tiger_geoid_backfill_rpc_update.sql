BEGIN;

-- =============================================================================
-- Migration 285: DC tiger_geoid backfill + resolve_user_districts dc_ward default
-- DCIN-04: link dc-ward-* district rows to TIGER GEOIDs and add dc_ward to RPC
--
-- DC TIGER note: tl_2024_11_sldl.zip returns 404. Ward polygons loaded via
-- load-dc-ward-boundaries.ts (DC GIS MapServer layer 53, Ward - 2022).
--
-- Section 1: Backfill tiger_geoid on dc-ward-1 through dc-ward-8.
-- Section 2: Extend resolve_user_districts DEFAULT to include dc_ward.
--   cache_user_districts calls resolve_user_districts() with NO explicit args,
--   so extending the DEFAULT is sufficient — no update to cache_user_districts needed.
-- =============================================================================

-- Section 1: tiger_geoid backfill
UPDATE essentials.districts SET tiger_geoid = '11001' WHERE geo_id = 'dc-ward-1' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11002' WHERE geo_id = 'dc-ward-2' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11003' WHERE geo_id = 'dc-ward-3' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11004' WHERE geo_id = 'dc-ward-4' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11005' WHERE geo_id = 'dc-ward-5' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11006' WHERE geo_id = 'dc-ward-6' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11007' WHERE geo_id = 'dc-ward-7' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11008' WHERE geo_id = 'dc-ward-8' AND state = 'DC';

-- Section 2: resolve_user_districts with dc_ward in DEFAULT
DROP FUNCTION IF EXISTS essentials.resolve_user_districts(float8, float8, text[]);

CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary',
    'dc_ward'
  ]
)
RETURNS TABLE(layer text, geoid text, district_num text, name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT gd.layer, gd.geoid, gd.district_num, gd.name
  FROM essentials.geo_districts gd
  WHERE gd.layer = ANY(p_layers)
    AND public.ST_Contains(gd.geom, public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326))
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts(float8, float8, text[])
  TO authenticated, anon;

COMMIT;

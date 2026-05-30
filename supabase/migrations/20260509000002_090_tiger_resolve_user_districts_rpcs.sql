BEGIN;

-- =============================================================================
-- Migration 090: TIGER resolve / cache RPCs
-- GEO-04: essentials.resolve_user_districts(lat, lng, layers[]) — point-in-polygon
-- GEO-05: essentials.cache_user_districts(user_id, lat, lng) — resolves + upserts
--
-- Both functions: SECURITY DEFINER + SET search_path = '' + fully-qualified refs.
--
-- ST_MakePoint takes (lng, lat) — order matters. Coords are stored as 4326
-- (WGS84) so we wrap in ST_SetSRID to make the projection explicit.
-- =============================================================================

-- Section 1: essentials.resolve_user_districts (GEO-04)
-- Pure read function. Returns one row per matching layer for the given lat/lng.
-- Default layer set covers Phase 69's three layers; Phase 71 will pass school layers.
CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY['ca_assembly', 'ca_senate', 'us_house']
)
RETURNS TABLE(layer text, geoid text, district_num text, name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT gd.layer, gd.geoid, gd.district_num, gd.name
  FROM essentials.geo_districts gd
  WHERE gd.layer = ANY(p_layers)
    AND public.ST_Contains(gd.geom, public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326))
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts(float8, float8, text[])
  TO authenticated, anon;

-- Section 2: essentials.cache_user_districts (GEO-05)
-- Resolves districts for the given lat/lng and upserts them into
-- connect.user_districts. Called by the location-set flow in Phase 70.
-- ON CONFLICT (user_id, layer) DO UPDATE — idempotent re-resolution.
CREATE OR REPLACE FUNCTION essentials.cache_user_districts(
  p_user_id UUID,
  p_lat     float8,
  p_lng     float8
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT layer, geoid, district_num
    FROM essentials.resolve_user_districts(p_lat, p_lng)
  LOOP
    INSERT INTO connect.user_districts (user_id, layer, geoid, district_num, resolved_at)
    VALUES (p_user_id, r.layer, r.geoid, r.district_num, now())
    ON CONFLICT (user_id, layer) DO UPDATE
      SET geoid        = EXCLUDED.geoid,
          district_num = EXCLUDED.district_num,
          resolved_at  = EXCLUDED.resolved_at;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION essentials.cache_user_districts(UUID, float8, float8)
  TO authenticated;

COMMIT;

-- =============================================================================
-- Migration 093: Phase 71 — Extend cache_user_districts + resolve_user_districts
--                default p_layers to include school district layers
-- =============================================================================

-- 1) resolve_user_districts: extend default p_layers to 6 layers
CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary'
  ]
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
    AND public.ST_Contains(
      gd.geom,
      public.ST_SetSRID(public.ST_MakePoint(p_lng, p_lat), 4326)
    )
$$;

GRANT EXECUTE ON FUNCTION essentials.resolve_user_districts(float8, float8, text[])
  TO authenticated, anon;

-- 2) cache_user_districts: extend default p_layers to 6 layers
CREATE OR REPLACE FUNCTION essentials.cache_user_districts(
  p_user_id UUID,
  p_lat     float8,
  p_lng     float8,
  p_layers  text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary'
  ]
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
    FROM essentials.resolve_user_districts(p_lat, p_lng, p_layers)
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

GRANT EXECUTE ON FUNCTION essentials.cache_user_districts(UUID, float8, float8, text[])
  TO authenticated;

COMMENT ON FUNCTION essentials.resolve_user_districts(float8, float8, text[]) IS
  'Phase 71: Default p_layers extended from 3 (ca_assembly, ca_senate, us_house) to 6 (adds school_unified, school_elementary, school_secondary). All callers passing only lat/lng automatically resolve school layers too.';

COMMENT ON FUNCTION essentials.cache_user_districts(UUID, float8, float8, text[]) IS
  'Phase 71: Default p_layers extended to 6 layers including school districts. Backwards-compatible with 3-arg call sites in connect.ts and account.ts (Postgres uses default for the omitted 4th arg).';

-- CA_0370 — essentials.boundary_extent_4326 stops reprojecting (decision 0006).
BEGIN;

-- CA_0369 (applied 2026-11-07) created essentials.boundary_extent_4326 with an ELSE branch that
-- reprojected any geometry not in SRID 0/4326. Reprojection reads public.spatial_ref_sys, which
-- anon can write and we cannot revoke (ev-cto decision 0006); CI's static guard
-- check-postgis-spatial-ref-guard.mjs refuses it in any migration.
--
-- What it overwrites — the ELSE branch, verbatim as applied by CA_0369:
--     ELSE public.ST_Envelope(public.ST_Transform(p_geom, 4326))
-- Replaced with the whole-world box, which re-asks every basic account in that state instead
-- (the safe failure). The other two branches are unchanged.
--
-- Measured 2026-11-07 before writing: every shaped row in essentials.geofence_boundaries is
-- SRID 4326 (75,059; 4 have no geometry), and essentials.boundary_changes held 0 rows. So the
-- replaced branch never ran and no logged extent needs recomputing.
--
-- CA_0369's file now carries this same body, so a fresh database built from the files matches.

CREATE OR REPLACE FUNCTION essentials.boundary_extent_4326(p_geom public.geometry)
 RETURNS public.geometry
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  SELECT CASE
    WHEN p_geom IS NULL THEN NULL
    WHEN public.ST_SRID(p_geom) IN (0, 4326) THEN public.ST_SetSRID(public.ST_Envelope(p_geom), 4326)
    ELSE public.ST_MakeEnvelope(-180, -90, 180, 90, 4326)
  END
$function$;

-- ── Post-verify gate ─────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_def text := pg_get_functiondef('essentials.boundary_extent_4326(public.geometry)'::regprocedure);
  v_sq  public.geometry := public.ST_SetSRID(public.ST_MakeEnvelope(-82.56, 35.59, -82.55, 35.60), 4326);
BEGIN
  -- Built from two halves so the static guard does not read this check as a call.
  IF v_def ILIKE ('%st_' || 'transform(%') THEN
    RAISE EXCEPTION 'CA_0370 gate: boundary_extent_4326 still reprojects';
  END IF;
  -- 4326 and SRID 0 keep their own box.
  IF NOT public.ST_Equals(essentials.boundary_extent_4326(v_sq), v_sq) THEN
    RAISE EXCEPTION 'CA_0370 gate: a 4326 box changed';
  END IF;
  IF NOT public.ST_Equals(essentials.boundary_extent_4326(public.ST_SetSRID(v_sq, 0)), v_sq) THEN
    RAISE EXCEPTION 'CA_0370 gate: an SRID-0 box changed';
  END IF;
  -- Any other SRID: the whole world, in 4326, with no spatial_ref_sys lookup.
  IF NOT public.ST_Equals(essentials.boundary_extent_4326(public.ST_SetSRID(v_sq, 3857)),
                          public.ST_MakeEnvelope(-180, -90, 180, 90, 4326)) THEN
    RAISE EXCEPTION 'CA_0370 gate: a non-4326 geometry did not get the world box';
  END IF;
  IF essentials.boundary_extent_4326(NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0370 gate: NULL in, non-NULL out';
  END IF;
  -- The guard's premise, re-measured inside the transaction.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE geometry IS NOT NULL AND public.ST_SRID(geometry) NOT IN (0, 4326)) THEN
    RAISE NOTICE 'CA_0370: some boundaries are not SRID 4326 — their changes will re-ask the whole state';
  END IF;
  RAISE NOTICE 'CA_0370 gate OK';
END $$;

COMMIT;

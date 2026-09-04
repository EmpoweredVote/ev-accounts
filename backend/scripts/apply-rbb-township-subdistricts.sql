-- apply-rbb-township-subdistricts.sql
--
-- Richland-Bean Blossom Community School Corporation (RBBSC, geo_id 1809480) elects its
-- board by TOWNSHIP: 2 seats for Richland Township, 2 for Bean Blossom Township, + 1 at-large.
-- All 5 offices hung off the whole-corp district (geo_id 1809480, G5420), so an address
-- returned all 5. This narrows a township address to its 2 township members + the 1 at-large
-- (5 -> 3). It cannot go below 2 — the township genuinely has two seats over one geography.
--
-- Boundaries are REUSED from the TIGER county-subdivision (G4040) township polygons already in
-- essentials.geofence_boundaries (Monroe County FIPS 18105) — verified 2026-09-03 that
-- Richland + Bean Blossom townships together cover 99.9% of the RBB corporation:
--   Richland Township     geo_id 1810564152  (G4040)  -> RBB Richland seats
--   Bean Blossom Township geo_id 1810503808  (G4040)  -> RBB Bean Blossom seats
-- Loaded as mtfcc X0002 (the school-subdistrict layer already wired into the address match).
-- The at-large seat stays on the corp district so it resolves corporation-wide.
--
-- Atomic: the whole DO block commits or rolls back together. Idempotent: ON CONFLICT / NOT
-- EXISTS; re-running relinks 0 (the township offices are no longer on the corp district row).

DO $rbb$
DECLARE
  v_gov uuid;
  v_sub uuid;
  v_old uuid;
  on_subs int;
  on_corp int;
BEGIN
  SELECT government_id INTO v_gov
    FROM essentials.districts
   WHERE geo_id='1809480' AND district_id='At Large' LIMIT 1;

  -- ── Richland Township ────────────────────────────────────────────────
  INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
  SELECT '1809480-twp-richland',
         'Richland-Bean Blossom School Board - Richland Township',
         '18','X0002', public.ST_MakeValid(gb.geometry), 'monroe_county_township_tiger_g4040', now()
    FROM essentials.geofence_boundaries gb
   WHERE gb.geo_id='1810564152' AND gb.mtfcc='G4040'
  ON CONFLICT (geo_id,mtfcc) DO NOTHING;

  INSERT INTO essentials.districts (geo_id,district_type,label,state,mtfcc,district_id,government_id)
  SELECT '1809480-twp-richland','SCHOOL',
         'Richland-Bean Blossom School Board - Richland Township','in','X0002','rbb-twp-richland',v_gov
  WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_id='rbb-twp-richland');

  SELECT id INTO v_sub FROM essentials.districts WHERE district_id='rbb-twp-richland';
  SELECT id INTO v_old FROM essentials.districts WHERE geo_id='1809480' AND district_id='Richland Township';
  UPDATE essentials.offices SET district_id=v_sub WHERE district_id=v_old;

  -- ── Bean Blossom Township ────────────────────────────────────────────
  INSERT INTO essentials.geofence_boundaries (geo_id,name,state,mtfcc,geometry,source,imported_at)
  SELECT '1809480-twp-beanblossom',
         'Richland-Bean Blossom School Board - Bean Blossom Township',
         '18','X0002', public.ST_MakeValid(gb.geometry), 'monroe_county_township_tiger_g4040', now()
    FROM essentials.geofence_boundaries gb
   WHERE gb.geo_id='1810503808' AND gb.mtfcc='G4040'
  ON CONFLICT (geo_id,mtfcc) DO NOTHING;

  INSERT INTO essentials.districts (geo_id,district_type,label,state,mtfcc,district_id,government_id)
  SELECT '1809480-twp-beanblossom','SCHOOL',
         'Richland-Bean Blossom School Board - Bean Blossom Township','in','X0002','rbb-twp-beanblossom',v_gov
  WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_id='rbb-twp-beanblossom');

  SELECT id INTO v_sub FROM essentials.districts WHERE district_id='rbb-twp-beanblossom';
  SELECT id INTO v_old FROM essentials.districts WHERE geo_id='1809480' AND district_id='Bean Blossom Township';
  UPDATE essentials.offices SET district_id=v_sub WHERE district_id=v_old;

  -- ── Post-conditions ──────────────────────────────────────────────────
  SELECT count(*) INTO on_subs
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.geo_id LIKE '1809480-twp-%';
  SELECT count(*) INTO on_corp
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.geo_id='1809480';
  IF on_subs <> 4 OR on_corp <> 1 THEN
    RAISE EXCEPTION 'RBB post-condition failed: township offices=% (expected 4), corp offices=% (expected 1 at-large)', on_subs, on_corp;
  END IF;

  -- Validity backstop: invalid geometry breaks the address-search reachability job.
  IF EXISTS (SELECT 1 FROM essentials.geofence_boundaries
              WHERE geo_id LIKE '1809480-twp-%' AND NOT public.ST_IsValid(geometry)) THEN
    RAISE EXCEPTION 'RBB post-condition failed: imported township geometry is invalid';
  END IF;
  RAISE NOTICE 'RBB ok: township offices=4 (2+2), at-large on corp=1';
END $rbb$;

-- 1832_indiana_appellate_districts.sql
--
-- Give the Indiana Court of Appeals retention seats the geography they actually vote on.
--
-- WHY
-- ---
-- Indiana's 15 Court of Appeals judges sit in five districts. Districts 1, 2 and 3 are GEOGRAPHIC —
-- their judges stand for retention before the voters of that district only. Districts 4 and 5 are
-- AT LARGE: each is made up of one judge from each of the first three districts, and those judges
-- stand for retention STATEWIDE.
--
--   Court of Appeals of Indiana, "Court of Appeals Districts", https://www.in.gov/courts/appeals/districts/
--     "Three members of the Court must come from the 1st District, encompassing the southern third of
--      the state; three from the 2nd District, the middle third; and three from the 3rd District, the
--      northern third of Indiana. Judges named from these districts stand for retention only in their
--      districts. In 1978, a 4th District was created, consisting of three judges, one from each of the
--      first three districts. Likewise, in 1991, a 5th District was added, also with judges from each
--      of the first three districts. Judges representing the 4th and 5th districts stand for retention
--      statewide."
--
-- ⚠ THE 4TH DISTRICT'S DISPOSITION WAS THE OPEN QUESTION and it is answered above: the 4th, like the
-- 5th, is AT LARGE and retains statewide. So this migration creates polygons for Districts 1-3 ONLY.
-- The 4th and 5th District rows CORRECTLY stay on geo_id '18' (the state outline) and must not be
-- repointed. Same for the five Supreme Court retention rows.
--
-- WHAT WAS WRONG
-- --------------
-- Every Indiana Court of Appeals retention row resolved STATEWIDE, so a District 1 judge was shown to
-- a District 3 voter. Two mechanisms produced that, and both are fixed here plus in the read path:
--
--   * 9 rows sat on geo_id '18' (the G4000 state outline) — an over-inclusive shortcut.
--   * 2 rows (1800001 District 1 / 1800002 District 2) were modelled correctly as their own districts
--     but never had polygons loaded, so they had no geometry at all. buildStatewideQuery admitted them
--     anyway, because its rule for "is this a statewide court" was LENGTH(geo_id) <> 5 and those
--     geo_ids are 7 characters. That rule is replaced in districtQueries.ts by the honest test —
--     a JUDICIAL district is statewide iff it has no geofence of its own below the state outline.
--
-- HOW THE POLYGONS WERE BUILT — DERIVED, NOT DOWNLOADED
-- ----------------------------------------------------
-- Indiana's appellate districts are groups of whole counties and there is no TIGER layer for them, so
-- each polygon is public.ST_Union of its member counties' existing G4020 geofences. No new geometry
-- is sourced or approximated; the district boundary is exactly the county boundaries we already hold.
--
-- County composition was transcribed from the Court of Appeals' own published district map
-- (https://www.in.gov/courts/appeals/images/coa-district-map.jpg) by georeferencing the image against
-- our own county polygons and sampling the fill colour at 60 interior points per county, rather than
-- by reading it off the screen. Mean single-colour agreement per county was 0.9911 (only Jay County
-- below 0.90, at 0.89), and two independent projection hypotheses (equirectangular and Mercator)
-- produced an IDENTICAL 92-county assignment. Hand-reading the same map at 1x got Wells and Adams
-- wrong, which is why it was done this way.
--
--   District 1  53 counties   District 2  19 counties   District 3  20 counties   = 92, all assigned
--
-- MTFCC — X0029
-- -------------
-- A new synthesized layer code. X0029 is the next free code (X0001-X0028 in use). It MUST be admitted
-- explicitly for JUDICIAL in BOTH src/lib/geoIdGuard.ts and src/lib/districtQueries.ts: the X-prefix
-- catch-all in geoIdGuard.ts restricts unknown X codes to LOCAL/COUNTY, so relying on it would leave
-- these districts unreachable. Guarded by geoIdGuard.test.ts.
--
-- ⚠ geo_id BAND HAZARD. 1800001/1800002/1800003 sit in the same 18000NN numeric band as Indiana's
-- TIGER school districts (G5420: 1800008, 1800030, 1800060 are live today). They do not collide now,
-- and the (geo_id, mtfcc) guard prevents a JUDICIAL row ever cross-matching a SCHOOL geofence even if
-- a future import takes one of these numbers. Ad-hoc SQL is NOT so protected — always scope Indiana
-- judicial queries by mtfcc/district_type, never by geo_id alone.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. The three geographic district polygons, as unions of their member counties.
-- ---------------------------------------------------------------------------
WITH members(geo_id, name, counties) AS (
  VALUES
    ('1800001', 'Indiana Court of Appeals District 1', ARRAY[
      '18005','18011','18013','18019','18021','18025','18027','18029','18031','18037','18041','18043',
      '18045','18047','18051','18055','18059','18061','18063','18065','18071','18077','18079','18081',
      '18083','18093','18101','18105','18107','18109','18115','18117','18119','18121','18123','18125',
      '18129','18133','18135','18137','18139','18143','18145','18147','18153','18155','18161','18163',
      '18165','18167','18173','18175','18177']),
    ('1800002', 'Indiana Court of Appeals District 2', ARRAY[
      '18001','18009','18015','18017','18023','18035','18053','18057','18067','18069','18075','18095',
      '18097','18103','18157','18159','18169','18179','18181']),
    ('1800003', 'Indiana Court of Appeals District 3', ARRAY[
      '18003','18007','18033','18039','18049','18073','18085','18087','18089','18091','18099','18111',
      '18113','18127','18131','18141','18149','18151','18171','18183'])
)
INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source, imported_at)
SELECT m.geo_id,
       m.name,
       '18',
       'X0029',
       public.ST_Multi(public.ST_MakeValid(public.ST_Union(g.geometry))),
       'derived: union of member county G4020 geofences; composition per Court of Appeals of Indiana '
         || 'district map (in.gov/courts/appeals/districts); migration 1832',
       now()
FROM members m
JOIN essentials.geofence_boundaries g
  ON g.mtfcc = 'G4020' AND g.state = '18' AND g.geo_id = ANY(m.counties)
GROUP BY m.geo_id, m.name
ON CONFLICT (geo_id, mtfcc) DO UPDATE
  SET geometry = EXCLUDED.geometry,
      name     = EXCLUDED.name,
      source   = EXCLUDED.source;

-- ---------------------------------------------------------------------------
-- 2. Repoint the District 1-3 retention rows onto their own district geography.
--    Districts 4 and 5 and the Supreme Court rows are deliberately untouched.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d
   SET geo_id = v.new_geo_id,
       mtfcc  = 'X0029'
  FROM (VALUES
          ('Indiana Appeals Court Judge - District 1 (Retain Foley?)',    '1800001'),
          ('Indiana Appeals Court Judge - District 1 (Retain Bailey?)',   '1800001'),
          ('Indiana Appeals Court Judge - District 2 (Retain Altice?)',   '1800002'),
          ('Indiana Appeals Court Judge - District 2 (Retain Kirsch?)',   '1800002'),
          ('Indiana Appeals Court Judge - District 2 (Retain Bradford?)', '1800002'),
          ('Indiana Appeals Court Judge - District 3 (Retain Crone?)',    '1800003')
       ) AS v(label, new_geo_id)
 WHERE d.label = v.label
   AND d.state = 'IN'
   AND d.district_type = 'JUDICIAL'
   AND (d.geo_id IS DISTINCT FROM v.new_geo_id OR d.mtfcc IS DISTINCT FROM 'X0029');

-- ---------------------------------------------------------------------------
-- 3. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_fences   int;
  n_bad      int;
  n_d1       int; n_d2 int; n_d3 int;
  area_gap   numeric;
  n_moved    int;
  n_statewide int;
  covered    numeric;
BEGIN
  -- 3a. Exactly three polygons, all valid and non-empty.
  SELECT count(*) INTO n_fences
    FROM essentials.geofence_boundaries WHERE mtfcc = 'X0029' AND state = '18';
  IF n_fences <> 3 THEN
    RAISE EXCEPTION 'expected 3 X0029 Indiana geofences, found %', n_fences;
  END IF;

  SELECT count(*) INTO n_bad
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0029' AND state = '18'
     AND (geometry IS NULL OR NOT public.ST_IsValid(geometry) OR public.ST_IsEmpty(geometry));
  IF n_bad > 0 THEN
    RAISE EXCEPTION '% X0029 geofence(s) null/invalid/empty', n_bad;
  END IF;

  -- 3b. Each district must CONTAIN exactly its member counties. A union that silently dropped a
  --     county still passes ST_IsValid, so count what the polygon actually covers.
  SELECT count(*) INTO n_d1 FROM essentials.geofence_boundaries c, essentials.geofence_boundaries d
   WHERE c.mtfcc='G4020' AND c.state='18' AND d.geo_id='1800001' AND d.mtfcc='X0029'
     AND public.ST_Covers(d.geometry, public.ST_PointOnSurface(c.geometry));
  SELECT count(*) INTO n_d2 FROM essentials.geofence_boundaries c, essentials.geofence_boundaries d
   WHERE c.mtfcc='G4020' AND c.state='18' AND d.geo_id='1800002' AND d.mtfcc='X0029'
     AND public.ST_Covers(d.geometry, public.ST_PointOnSurface(c.geometry));
  SELECT count(*) INTO n_d3 FROM essentials.geofence_boundaries c, essentials.geofence_boundaries d
   WHERE c.mtfcc='G4020' AND c.state='18' AND d.geo_id='1800003' AND d.mtfcc='X0029'
     AND public.ST_Covers(d.geometry, public.ST_PointOnSurface(c.geometry));
  IF (n_d1, n_d2, n_d3) IS DISTINCT FROM (53, 19, 20) THEN
    RAISE EXCEPTION 'county coverage wrong: D1=% (want 53) D2=% (want 19) D3=% (want 20)', n_d1, n_d2, n_d3;
  END IF;

  -- 3c. The three districts must tile the state: no overlap, no gap. Compare the union of the three
  --     against the union of all 92 counties.
  SELECT abs(public.ST_Area(public.ST_Union(d.geometry)) - c.total) / c.total INTO area_gap
    FROM essentials.geofence_boundaries d,
         (SELECT public.ST_Area(public.ST_Union(geometry)) AS total
            FROM essentials.geofence_boundaries WHERE mtfcc='G4020' AND state='18') c
   WHERE d.mtfcc = 'X0029' AND d.state = '18'
   GROUP BY c.total;
  IF area_gap IS NULL OR area_gap > 0.0001 THEN
    RAISE EXCEPTION 'district union does not reconstruct Indiana: relative area gap %', area_gap;
  END IF;

  SELECT sum(public.ST_Area(geometry)) / public.ST_Area(public.ST_Union(geometry)) INTO covered
    FROM essentials.geofence_boundaries WHERE mtfcc='X0029' AND state='18';
  IF covered > 1.0001 THEN
    RAISE EXCEPTION 'districts overlap each other: summed/union area ratio %', covered;
  END IF;

  -- 3d. Six retention rows repointed; ten Indiana appellate/supreme rows still statewide.
  SELECT count(*) INTO n_moved
    FROM essentials.districts
   WHERE state='IN' AND district_type='JUDICIAL' AND geo_id IN ('1800001','1800002','1800003');
  IF n_moved <> 6 THEN
    RAISE EXCEPTION 'expected 6 repointed Indiana appellate rows, found %', n_moved;
  END IF;

  SELECT count(*) INTO n_statewide
    FROM essentials.districts
   WHERE state='IN' AND district_type='JUDICIAL' AND geo_id='18';
  IF n_statewide <> 10 THEN
    RAISE EXCEPTION 'expected 10 statewide Indiana judicial rows (5 Supreme Court + District 4/5), found %', n_statewide;
  END IF;

  -- 3e. No District 4 or 5 row may have been repointed — they retain STATEWIDE.
  IF EXISTS (SELECT 1 FROM essentials.districts
              WHERE state='IN' AND district_type='JUDICIAL'
                AND label ~ 'District [45]' AND geo_id <> '18') THEN
    RAISE EXCEPTION 'a District 4/5 row was repointed; those seats retain statewide';
  END IF;

  RAISE NOTICE 'OK: 3 appellate polygons (53/19/20 counties), 6 rows repointed, 10 rows still statewide';
END $$;

COMMIT;

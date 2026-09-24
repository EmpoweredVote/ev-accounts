-- CA_0246_la_elem_high_district_mtfcc.sql
--
-- 31 Los Angeles County elementary / high school board districts: districts.mtfcc G5420 -> the code of the one
-- geofence each district actually has (G5400 elementary, G5410 secondary).
--
-- WHY (measured 2026-09-24)
-- -------------------------
--   CA_0158 recorded the mismatch ("its geofence is the TIGER elementary G5400 or secondary G5410 polygon; the
--   district row itself says G5420") but left it. A census of every district whose mtfcc matches none of its
--   geo_id's geofences found exactly two groups nationwide: these 31 (CA SCHOOL, G5420 vs G5400/G5410) and the
--   five LA County supervisor districts (CA_0245).
--   The address join ignores districts.mtfcc, so address search shows these boards. The election coordinate path
--   does not: electionService.getElectionsByCoordinate matches the geofence on gbo.mtfcc = d.mtfcc, so a race on
--   one of these districts is never found by address. Eight such races are on the 2026-11-03 general ballot (CA_0162):
--     El Monte City, Hawthorne, Hermosa Beach City, Lennox, Mountain View, Rosemead, Valle Lindo, Westside Union
--   Live, 2026-09-24: /api/essentials/elections-by-address for 3540 Lexington Ave, El Monte (the El Monte City
--   School District office) lists El Monte Union High Trustee Area 3 but NOT "El Monte City School Board".
--
-- CHANGE: for each district, set mtfcc to its geofence's code — only where the district is SCHOOL / G5420, has no
--   G5420 geofence, and has EXACTLY ONE geofence, whose code is G5400 or G5410. Nothing else changes.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator: Chris Andrews). Dry run: gates passed, ROLLBACK; apply: COMMIT (UPDATE 31);
--   re-run inside BEGIN/ROLLBACK: 0 candidates, UPDATE 0, gates passed. Live elections-by-address, 3540 Lexington Ave,
--   El Monte: the 2026 LA County General now lists "El Monte City School Board". check:reachability OK.
--
-- ROLLBACK: UPDATE essentials.districts SET mtfcc = 'G5420' WHERE id IN (the 31 ids the pre-flight temp table lists).
-- IDEMPOTENT: a re-run finds 0 candidates and changes 0 rows.

BEGIN;

CREATE TEMP TABLE ca0246_fix ON COMMIT DROP AS
SELECT d.id, d.label, d.geo_id, min(gb.mtfcc) AS new_mtfcc
  FROM essentials.districts d
  JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
 WHERE d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420' AND upper(d.state) = 'CA'
   AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries x WHERE x.geo_id = d.geo_id AND x.mtfcc = 'G5420')
 GROUP BY d.id, d.label, d.geo_id
HAVING count(*) = 1 AND min(gb.mtfcc) IN ('G5400', 'G5410');

-- ---------------------------------------------------------------------------
-- 0. Pre-flight: exactly the 31 measured (first run) or none (re-run).
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; n_done int;
BEGIN
  SELECT count(*) INTO n FROM ca0246_fix;
  SELECT count(*) INTO n_done FROM essentials.districts d
   WHERE d.district_type = 'SCHOOL' AND upper(d.state) = 'CA' AND d.mtfcc IN ('G5400', 'G5410')
     AND d.geo_id IN ('0602820','0607740','0607920','0611850','0611910','0612090','0612120','0614940','0615600','0616680',
                      '0617040','0617880','0619440','0620880','0621210','0621420','0621930','0622890','0626190','0627180',
                      '0629580','0633570','0635970','0637560','0638220','0640650','0642120','0642450','0642480','0642510','0642810');
  IF NOT ((n = 31 AND n_done = 0) OR (n = 0 AND n_done = 31)) THEN
    RAISE EXCEPTION 'candidates % / already fixed % (want 31/0 or 0/31)', n, n_done;
  END IF;
  -- Every candidate is one of the measured geo_ids.
  SELECT count(*) INTO n FROM ca0246_fix WHERE geo_id NOT IN
    ('0602820','0607740','0607920','0611850','0611910','0612090','0612120','0614940','0615600','0616680',
     '0617040','0617880','0619440','0620880','0621210','0621420','0621930','0622890','0626190','0627180',
     '0629580','0633570','0635970','0637560','0638220','0640650','0642120','0642450','0642480','0642510','0642810');
  IF n > 0 THEN RAISE EXCEPTION '% candidate(s) outside the measured 31', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Recode.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d SET mtfcc = f.new_mtfcc
  FROM ca0246_fix f WHERE d.id = f.id AND d.mtfcc = 'G5420';

-- ---------------------------------------------------------------------------
-- 2. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  -- 2a. No CA SCHOOL district is left with an mtfcc none of its geofences carry.
  SELECT count(*) INTO n FROM essentials.districts d
   WHERE d.district_type = 'SCHOOL' AND upper(d.state) = 'CA' AND d.mtfcc IS NOT NULL AND d.mtfcc <> ''
     AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id)
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries x WHERE x.geo_id = d.geo_id AND x.mtfcc = d.mtfcc);
  IF n > 0 THEN RAISE EXCEPTION '% CA SCHOOL district(s) still on a code with no geofence', n; END IF;

  -- 2b. The eight 2026-11-03 races now reach a geofence through the election coordinate path's join.
  SELECT count(DISTINCT r.id) INTO n
    FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries gbo ON gbo.geo_id = d.geo_id AND gbo.mtfcc = d.mtfcc
   WHERE e.election_date = DATE '2026-11-03'
     AND r.position_name IN ('El Monte City School Board', 'Hawthorne School Board', 'Hermosa Beach City School Board',
                             'Lennox School Board', 'Mountain View School Board', 'Rosemead School Board',
                             'Valle Lindo School Board', 'Westside Union School Board');
  IF n <> 8 THEN RAISE EXCEPTION 'races reachable by coordinate: % of 8', n; END IF;

  RAISE NOTICE 'OK: 31 LA elementary/high board districts on their geofence code; 8/8 Nov 2026 races reachable by coordinate';
END $$;

COMMIT;

-- 1247: Un-withhold the 5 severe TN 2026 US House races (Phase 164.1-04, D-01b flip)
--
-- WHY: Phase 161-06 seeded all 9 TN districts but WITHHELD the 5 severe ones
-- (4704, 4705, 4706, 4708, 4709 — per the 161 correspondence audit) by pointing
-- their races at the past-dated special 'TN 2026 Congressional Redistricting -
-- Polygon Pending' (2026-05-07), which ELECTION_VISIBILITY_WINDOW never returns.
-- The stale 2024-TIGER polygons would have served actively-wrong address→race
-- lookups for those districts.
--
-- Phase 164.1 imported TN's 2026-vintage polygons (mtfcc='G5200V26', HB 7003 map,
-- migration-adjacent script 1641-tn-generate-polygon-import.mts) and the D-10
-- 3-layer verify bar passed pre-flip (tiling 0.2022% uncovered; anchors valid;
-- guaranteed differential proven at (36.4452,-86.2503) NEW=4707/OLD=4706).
-- Elections coordinate resolution now prefers the V26 shapes (164.1-01 deploy),
-- so these 5 races can safely surface: re-point election_id to the surfacing
-- 'TN 2026 Statewide General'.
--
-- The 'Polygon Pending' marker election is NOT deleted (historical artifact,
-- per the 163-11 convention).
--
-- Idempotent: the UPDATE is guarded on the OLD (withheld) election_id — re-runs
-- match zero rows.

BEGIN;

UPDATE essentials.races r
SET election_id = (
      SELECT id FROM essentials.elections
      WHERE name = 'TN 2026 Statewide General'
    )
WHERE r.election_id = (
        SELECT id FROM essentials.elections
        WHERE name = 'TN 2026 Congressional Redistricting - Polygon Pending'
      )
  AND r.office_id IN (
        SELECT o.id
        FROM essentials.offices o
        JOIN essentials.districts d ON d.id = o.district_id
        WHERE d.district_type = 'NATIONAL_LOWER'
          AND d.geo_id IN ('4704', '4705', '4706', '4708', '4709')
      );

-- Post-flip assertion: exactly 5 severe TN races now on the general election.
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND d.geo_id IN ('4704', '4705', '4706', '4708', '4709')
    AND e.name = 'TN 2026 Statewide General';
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'unwithhold_tn: expected 5 severe TN races on the general, found %', v_count;
  END IF;
END $$;

COMMIT;

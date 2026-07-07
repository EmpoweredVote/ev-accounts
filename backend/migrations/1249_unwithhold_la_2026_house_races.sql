-- 1249: Un-withhold the 2 severe LA 2026 US House races — LA-2 (2202) + LA-6 (2206)
-- (Phase 164.1-05, D-01b flip)
--
-- WHY: Phase 163 seeded all 6 LA districts but WITHHELD severe LA-2/LA-6 by
-- pointing their races at the past-dated special 'LA 2026 Congressional
-- Redistricting - Polygon Pending', which ELECTION_VISIBILITY_WINDOW excludes.
--
-- Phase 164.1 imported LA's 2026-vintage polygons (mtfcc='G5200V26', SB121 /
-- Act 2 (2026 RS) from redist.legis.la.gov) and the D-10 3-layer bar passed
-- (tiling 0.2573% uncovered; guaranteed differential (32.0740,-92.6110)
-- NEW=2205/OLD=2204; LA-4 borderline ratio 0.881 sane). Re-point both races
-- to the surfacing 'LA 2026 Statewide General'.
--
-- Rick Edmonds (-220605, re-keyed LA-5→LA-6 in migration 1230) surfaces with
-- the LA-6 race after this flip — re-verified by the 164.1-05 gate.
--
-- Marker election NOT deleted (163-11 convention).
-- Idempotent: guarded on the OLD (withheld) election_id — re-runs match 0 rows.

BEGIN;

UPDATE essentials.races r
SET election_id = (
      SELECT id FROM essentials.elections
      WHERE name = 'LA 2026 Statewide General'
    )
WHERE r.election_id = (
        SELECT id FROM essentials.elections
        WHERE name = 'LA 2026 Congressional Redistricting - Polygon Pending'
      )
  AND r.office_id IN (
        SELECT o.id
        FROM essentials.offices o
        JOIN essentials.districts d ON d.id = o.district_id
        WHERE d.district_type = 'NATIONAL_LOWER'
          AND d.geo_id IN ('2202', '2206')
      );

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
    AND d.geo_id IN ('2202', '2206')
    AND e.name = 'LA 2026 Statewide General';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'unwithhold_la: expected 2 severe LA races on the general, found %', v_count;
  END IF;
END $$;

COMMIT;

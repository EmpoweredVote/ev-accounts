-- 1248: Un-withhold the severe AL-2 (0102) 2026 US House race (Phase 164.1-05, D-01b flip)
--
-- WHY: Phase 163 seeded all 7 AL districts but WITHHELD severe AL-2 (0102) by
-- pointing its race at the past-dated special 'AL 2026 Congressional
-- Redistricting - Polygon Pending', which ELECTION_VISIBILITY_WINDOW excludes.
--
-- Phase 164.1 imported AL's 2026-vintage polygons (mtfcc='G5200V26',
-- SCOTUS-reinstated 2023 legislature map — Milligan v. Allen stay 2026-06-02;
-- AL-2 BVAP ~39.9% confirmed = correct severe-map direction, operator-approved
-- checkpoint 2026-07-07) and the D-10 3-layer bar passed (tiling 0.0604%
-- uncovered; guaranteed differential (31.4754,-87.5764) NEW=0107/OLD=0102).
-- Re-point AL-2's race to the surfacing 'AL 2026 Statewide General'.
--
-- Marker election NOT deleted (163-11 convention).
-- Idempotent: guarded on the OLD (withheld) election_id — re-runs match 0 rows.

BEGIN;

UPDATE essentials.races r
SET election_id = (
      SELECT id FROM essentials.elections
      WHERE name = 'AL 2026 Statewide General'
    )
WHERE r.election_id = (
        SELECT id FROM essentials.elections
        WHERE name = 'AL 2026 Congressional Redistricting - Polygon Pending'
      )
  AND r.office_id IN (
        SELECT o.id
        FROM essentials.offices o
        JOIN essentials.districts d ON d.id = o.district_id
        WHERE d.district_type = 'NATIONAL_LOWER'
          AND d.geo_id = '0102'
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
    AND d.geo_id = '0102'
    AND e.name = 'AL 2026 Statewide General';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'unwithhold_al: expected 1 AL-2 race on the general, found %', v_count;
  END IF;
END $$;

COMMIT;

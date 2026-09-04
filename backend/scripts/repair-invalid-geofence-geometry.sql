-- repair-invalid-geofence-geometry.sql
--
-- Repair invalid geofence geometry (ring self-intersections / bowties) IN PLACE, preserving
-- footprint via ST_MakeValid. Idempotent: touches only rows where NOT ST_IsValid, so re-running
-- updates 0 rows.
--
-- WHY: an invalid polygon turns the master address-search reachability job red. Loaders now
-- ST_MakeValid on insert (load-arcgis-from-config.ts, import-mccsc-*.ts), but that ON CONFLICT
-- DO NOTHING path cannot fix rows that ALREADY landed invalid. Known pre-existing case:
-- sacramento-council-district-6 (source sacramento_city_council_districts_2021). MCCSC D3 was
-- repaired manually 2026-09-03; this generalises that repair.
--
-- Safe to run anytime; it is the standing remediation for legacy invalid rows.

UPDATE essentials.geofence_boundaries
   SET geometry = public.ST_MakeValid(geometry)
 WHERE geometry IS NOT NULL
   AND NOT public.ST_IsValid(geometry);

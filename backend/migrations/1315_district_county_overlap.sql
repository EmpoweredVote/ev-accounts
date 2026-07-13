-- 1315_district_county_overlap.sql
--
-- Precomputed district → county overlap for Read & Rank's county relevance tier.
--
-- getPlayableRaces needs the set of G4020 counties each sub-state district overlaps
-- (drives `countyGeoIds`). Computing that live — ST_Intersects + ST_Area(ST_Intersection)
-- over full-resolution polygons for ~300 districts on EVERY request — made
-- GET /api/readrank/races take ~30 s. The overlap is static data, so we cache it here
-- and the endpoint does an indexed lookup instead (~30 s → a few ms).
--
-- DDL only — the (multi-minute) backfill is intentionally NOT run in this migration so
-- it can't block/lock a deploy. Populate + refresh with:
--   cd backend && npx tsx scripts/backfill-district-county-overlap.ts
-- Rerun after loading new geography into essentials.geofence_boundaries.

CREATE TABLE IF NOT EXISTS essentials.district_county_overlap (
  district_layer text NOT NULL,
  district_geoid text NOT NULL,
  county_geoid   text NOT NULL,
  PRIMARY KEY (district_layer, district_geoid, county_geoid)
);

COMMENT ON TABLE essentials.district_county_overlap IS
  'Precomputed G4020 counties each sub-state district (G5200/G5210/G5220/G5400/G5410/G5420/G4040) overlaps. Drives Read & Rank countyGeoIds. Rebuild via scripts/backfill-district-county-overlap.ts.';

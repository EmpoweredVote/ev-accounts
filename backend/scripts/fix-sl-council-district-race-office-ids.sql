-- =============================================================================
-- Fix: Link SL County Council District 1/3/5 races to their specific offices
--
-- Background: A previous fix (fix-ut-county-race-office-ids.sql) linked these
-- races to the county-wide Mayor office as a fallback, assuming the council
-- district geofences weren't loaded. Investigation showed they ARE loaded in
-- geofence_boundaries using OCD-style geo_ids matching the district records.
--
-- This script upgrades those three races to use their precise council-district
-- office_ids, enabling sub-district geofence matching via Part A.
--
-- office_id sources (verified via DB query this session):
--   District 1 → d490589b-... (Jiro Johnson, Council District 1 office)
--                district geo_id: ocd-division/.../salt_lake/council_district:1
--   District 3 → 6e10fb50-... (Aimee Winder Newton, Council District 3 office)
--                district geo_id: ocd-division/.../salt_lake/council_district:3
--   District 5 → fec9ad7c-... (Sheldon Stewart, Council District 5 office)
--                district geo_id: ocd-division/.../salt_lake/council_district:5
--
-- After applying:
--   • A Magna address (District 1) → Council District 1 race shows; 3/5 do not
--   • A South Jordan address (District 5) → Council District 5 race shows; 1/3 do not
--
-- Idempotent — re-running just sets the same value.
-- Usage: psql "$DATABASE_URL" -f scripts/fix-sl-council-district-race-office-ids.sql
-- =============================================================================

BEGIN;

UPDATE essentials.races r
SET office_id = mapping.office_id::uuid,
    updated_at = now()
FROM essentials.elections e,
(VALUES
  ('Salt Lake County Council District 1', 'd490589b-1205-4d39-8515-a73892b39232'),
  ('Salt Lake County Council District 3', '6e10fb50-0d39-4793-83cb-65bc02f4131e'),
  ('Salt Lake County Council District 5', 'fec9ad7c-7f7d-4d2c-b39f-0f4cedeba493')
) AS mapping(position_name, office_id)
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.position_name = mapping.position_name;

COMMIT;

-- Verification:
--   SELECT r.position_name, r.primary_party, r.office_id,
--          d.label, d.geo_id
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   JOIN essentials.offices o ON o.id = r.office_id
--   JOIN essentials.districts d ON d.id = o.district_id
--   WHERE e.state = 'UT'
--     AND r.position_name LIKE 'Salt Lake County Council District%'
--   ORDER BY r.position_name, r.primary_party;

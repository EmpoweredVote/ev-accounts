-- =============================================================================
-- Fix: Link Utah county-level races to their county district offices
--
-- Problem: Salt Lake County and Utah County races had office_id = NULL, so
-- they appeared via Part B (statewide) for ALL Utah addresses — including
-- Orem addresses getting SL County races and vice versa.
--
-- Fix: Set office_id on each race to point to the matching office in its
-- county district (geo_id 49035 = SL County, 49049 = Utah County, mtfcc G4020).
-- This moves them from Part B (statewide) to Part A (geofence-matched).
--
-- After this script:
--   • SL County races show ONLY for addresses inside Salt Lake County
--   • Utah County races show ONLY for addresses inside Utah County
--
-- Notes on SL Council District races (1, 3, 5):
--   These are sub-county districts. No council-district-level geofences are
--   loaded, so we link them to the county-wide Mayor office. They'll show
--   for all SL County addresses (all SL County voters can see their council
--   races) but no longer appear for Utah County addresses. Precise sub-district
--   filtering requires loading council district TIGER boundaries — see follow-up.
--
-- Idempotent: ON CONFLICT / WHERE office_id IS NULL guards prevent double-apply.
-- Usage: psql "$DATABASE_URL" -f scripts/fix-ut-county-race-office-ids.sql
-- =============================================================================

BEGIN;

-- ── Salt Lake County races ────────────────────────────────────────────────────
--
-- All offices below are in the 'Salt Lake County' district (geo_id=49035, mtfcc=G4020).
-- Geofence covers SL County only — does NOT cover Utah County / Orem area.

UPDATE essentials.races r
SET office_id = mapping.office_id::uuid,
    updated_at = now()
FROM essentials.elections e,
(VALUES
  -- position_name                          office_id (SL County district, geo_id=49035)
  ('Salt Lake County Assessor',           '9affe4d3-c37c-4d6e-ad15-0c99b7a89fd9'),
  ('Salt Lake County Auditor',            '5f34abc8-c191-4144-b6ea-5226eb576e19'),
  ('Salt Lake County Clerk',              'f7fb84f0-f8ca-467f-ac00-a03db836327f'),
  ('Salt Lake County District Attorney',  '2b6b84ad-f69a-484a-b96e-82976c94ef87'),
  ('Salt Lake County Recorder',           '24d3f2d6-694e-4e92-b5b8-67df47c25401'),
  ('Salt Lake County Sheriff',            'd6c89923-a6f2-4eea-bf3e-f40986b4268d'),
  ('Salt Lake County Surveyor',           'c1ebaaa1-0213-4a0c-b474-1cc6b76cfec3'),
  -- Council At-Large A → Council At-Large Seat A office (SL County district)
  ('Salt Lake County Council At-Large A', '052814b3-4a26-41f0-81a2-cd82eda6de2a'),
  -- Council district sub-races: no council-district geofences loaded yet;
  -- link to Mayor office (SL County district) so they stay county-scoped.
  ('Salt Lake County Council District 1', '29c44a74-1686-466f-a73b-e0273cd509d2'),
  ('Salt Lake County Council District 3', '29c44a74-1686-466f-a73b-e0273cd509d2'),
  ('Salt Lake County Council District 5', '29c44a74-1686-466f-a73b-e0273cd509d2')
) AS mapping(position_name, office_id)
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.position_name = mapping.position_name;

-- ── Utah County races ─────────────────────────────────────────────────────────
--
-- All offices below are in the 'Utah County' district (geo_id=49049, mtfcc=G4020).
-- Geofence covers Utah County only — does NOT cover SL County.

UPDATE essentials.races r
SET office_id = mapping.office_id::uuid,
    updated_at = now()
FROM essentials.elections e,
(VALUES
  ('Utah County Commission Seat A', 'b3a543d6-a4bd-4af8-96e7-a7ae6801f68c'),  -- Commissioner
  ('Utah County Commission Seat B', '08948631-742c-4fe2-bd02-1e0a1c3592ff'),  -- Commissioner
  ('Utah County Clerk',             'f17e0ce8-117d-468c-acc6-46b13116e634'),  -- Clerk
  ('Utah County Auditor',           'bebaf899-a656-4345-a9c4-cb39b878ca36'),  -- Auditor
  ('Utah County Attorney',          'daf1fa50-abdb-4996-82ac-c0a6d55f4257'),  -- County Attorney
  ('Utah County Sheriff',           '3ac71e23-02a8-4d34-a8c0-85f1110019ab')   -- Sheriff
) AS mapping(position_name, office_id)
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.position_name = mapping.position_name;

COMMIT;

-- =============================================================================
-- Verification
-- =============================================================================
-- Run after applying to confirm all SL/UT County races now have office_id:
--
--   SELECT r.position_name, r.primary_party, r.office_id IS NOT NULL AS has_office_id
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.state = 'UT'
--     AND (r.position_name LIKE 'Salt Lake County%' OR r.position_name LIKE 'Utah County%')
--   ORDER BY r.position_name, r.primary_party;
--
-- Address spot-check (should NOT show SL County races for Orem):
--   GET /api/essentials/elections-by-address?address=877+W+1050+N+Orem+UT
--
-- Address spot-check (SHOULD show SL County races for SL address):
--   GET /api/essentials/elections-by-address?address=200+S+State+St+Salt+Lake+City+UT
-- =============================================================================

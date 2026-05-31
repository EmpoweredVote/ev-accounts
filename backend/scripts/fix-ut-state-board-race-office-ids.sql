-- =============================================================================
-- Fix: Link Utah State Board of Education races to their STATE_BOARD offices
--
-- Problem: USBE races were seeded with office_id = NULL (see
-- seed-ut-2026-06-23-primary.sql lines 31-32, which deferred this backfill).
-- With no office link they surfaced via electionService Part B (statewide
-- lookup), where district_type comes back NULL and inferDistrictType()
-- classified "...Board of Education..." as SCHOOL → Local tier. So every Utah
-- address saw ALL USBE district races, mis-filed under Local.
--
-- Fix: Set office_id on each race to the matching office in its STATE_BOARD
-- district (one office per USBE district 1-15, geo_id ocd-division/.../sboe:N,
-- mtfcc X0003). This moves them from Part B (statewide) to Part A (geofence-
-- matched), and Part A returns the real d.district_type = 'STATE_BOARD' → State.
--
-- After this script:
--   • Each USBE race shows ONLY for addresses inside its board district
--   • USBE races appear under the State tier (State Board of Education)
--
-- The inferDistrictType() STATE_BOARD branch (electionService.ts) is a
-- defense-in-depth fallback for any USBE race that ever lacks an office link.
--
-- Idempotent: WHERE office_id IS NULL guard prevents double-apply.
-- Usage: psql "$DATABASE_URL" -f scripts/fix-ut-state-board-race-office-ids.sql
-- =============================================================================

BEGIN;

UPDATE essentials.races r
SET office_id = o.id,
    updated_at = now()
FROM essentials.elections e,
     essentials.offices o
     JOIN essentials.districts d ON d.id = o.district_id
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.office_id IS NULL
  AND r.position_name LIKE 'Utah State Board of Education District %'
  AND d.district_type = 'STATE_BOARD'
  -- Match the race's district number to the office's STATE_BOARD district.
  -- One office exists per district, so this is a 1:1 link (Dem + Rep primary
  -- races for the same seat both point at the same office).
  AND substring(r.position_name from 'District ([0-9]+)') = d.district_id;

COMMIT;

-- =============================================================================
-- Verification — every USBE race should now have an office_id:
--
--   SELECT r.position_name, r.primary_party, r.office_id IS NOT NULL AS linked
--   FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.state = 'UT'
--     AND r.position_name LIKE 'Utah State Board of Education%'
--   ORDER BY r.position_name, r.primary_party;
--
-- Address spot-check (Orem 84057 → board district 11 or 14, under State tier):
--   GET /api/essentials/elections-by-address?address=877+W+1050+N+Orem+UT
-- =============================================================================

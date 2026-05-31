-- =============================================================================
-- Fix: Link Utah U.S. House / State Senate / State House races to their offices
--
-- Problem: A subset of district-scoped legislative races were seeded with
-- office_id = NULL (all 4 U.S. House districts, plus several open-seat / late-
-- patch State House & Senate districts). With no office link they surface via
-- electionService Part B (statewide), so EVERY Utah address sees them — e.g. an
-- Orem address showing all four U.S. House races and out-of-area legislative races.
--
-- Fix: Set office_id to the existing office in the matching district so the race
-- moves to Part A (PostGIS geofence -> district -> race.office_id) and shows only
-- for addresses inside that district. Matched by district label:
--   U.S. House District N      -> NATIONAL_LOWER 'Congressional District N' (geo_id 490N, mtfcc G5200)
--   Utah State Senate District N -> STATE_UPPER  'State Senate District N'  (geo_id 49xxx,  mtfcc G5210)
--   Utah State House District N  -> STATE_LOWER  'State House District N'   (geo_id 49xxx,  mtfcc G5220)
--
-- (Companion to fix-ut-county-race-office-ids.sql and
--  fix-ut-state-board-race-office-ids.sql — same Part B -> Part A correction.)
--
-- Idempotent: WHERE office_id IS NULL guard prevents double-apply. Each district
-- has exactly one office, so the join is 1:1.
-- Usage: psql "$DATABASE_URL" -f scripts/fix-ut-legislative-race-office-ids.sql
-- =============================================================================

BEGIN;

UPDATE essentials.races r
SET office_id = o.id,
    updated_at = now()
FROM essentials.elections e,
     essentials.districts d
     JOIN essentials.offices o ON o.district_id = d.id
WHERE r.election_id = e.id
  AND e.state = 'UT'
  AND r.office_id IS NULL
  AND lower(d.state) = 'ut'
  AND (
       (r.position_name LIKE 'U.S. House District %'
          AND d.district_type = 'NATIONAL_LOWER'
          AND d.label = 'Congressional District ' || substring(r.position_name from 'District ([0-9]+)'))
    OR (r.position_name LIKE 'Utah State Senate District %'
          AND d.district_type = 'STATE_UPPER'
          AND d.label = 'State Senate District ' || substring(r.position_name from 'District ([0-9]+)'))
    OR (r.position_name LIKE 'Utah State House District %'
          AND d.district_type = 'STATE_LOWER'
          AND d.label = 'State House District ' || substring(r.position_name from 'District ([0-9]+)'))
  );

COMMIT;

-- =============================================================================
-- Verification — no district-scoped UT legislative race should remain unlinked:
--
--   SELECT r.position_name, r.primary_party
--   FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
--   WHERE e.state = 'UT' AND r.office_id IS NULL
--     AND (r.position_name LIKE 'U.S. House District %'
--       OR r.position_name LIKE 'Utah State Senate District %'
--       OR r.position_name LIKE 'Utah State House District %')
--   ORDER BY r.position_name, r.primary_party;   -- expect 0 rows
--
-- Address spot-check (Orem 84057 → U.S. House D3, State Senate D23, one State House):
--   GET /api/essentials/elections-by-address?address=877+W+1050+N+Orem+UT
-- =============================================================================

-- =============================================================================
-- Migration 1392: Document Plano, TX Council Member Place 6 as a genuine
-- vacancy (Phase 218 Plan 05 — discovered during the phase-close verification
-- battery, not part of the original 21-office target list).
--
-- FINDING (2026-07-24, Phase 218 Plan 05 Task 1): the phase-close SQL gate
-- battery found `essentials.offices` "Council Member Place 6" for City of
-- Plano, Texas (geo_id 4858016) with politician_id IS NULL and is_vacant IS
-- NOT TRUE (ambiguous) — a gap RESEARCH.md/CONTEXT.md's original live count
-- never flagged (Plano's only named target was Place 7 / Shun Thomas).
--
-- D-04 evidence exhausted before declaring this a documented vacancy (not a
-- fabricated incumbent, per the phase's evidence-only rule):
--   1. plano.gov's own current official roster page
--      (https://www.plano.gov/mayor-and-city-council, live-fetched 2026-07-24)
--      lists exactly Mayor John B. Muns + 7 named councilmembers (Rick Horne,
--      Vidal Quintanilla, Bob Kehr, Chris Krupa Downs, Maria Tu, Steve Lavine,
--      Shun Thomas) — matching Places 1-5, 7, 8 in the DB 1:1 by cross-
--      reference of each person's individual plano.gov bio page (each bio
--      page states its own Place number). No 8th councilmember (Place 6) is
--      named anywhere on the city's own current roster.
--   2. ballotpedia.org/City_elections_in_Plano,_Texas_(2026) (live-fetched
--      2026-07-24) — the site's dedicated 2026 Plano election tracker — names
--      only the Place 7 special election (Shun Thomas, Jan 31 2026); no Place
--      6 race, candidate, or vacancy notice appears anywhere on that page.
--
-- Both an official primary source (city's own site) and a semi-official
-- election tracker (Ballotpedia) independently confirm no 8th sitting
-- councilmember and no pending Place 6 election — the seat is currently
-- vacant on the real council, not merely under-seeded in the DB. No
-- placeholder politician row inserted, matching the established TX-23/SD4
-- pattern (migrations 105/109): only offices.is_vacant is flipped.
--
-- Idempotent: guarded by `politician_id IS NULL` so a re-run is a no-op once
-- applied (or once a future phase seats a real winner and clears is_vacant).
-- =============================================================================

BEGIN;

UPDATE essentials.offices o
   SET is_vacant = true
  FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
 WHERE o.chamber_id = ch.id
   AND g.geo_id = '4858016'
   AND o.title = 'Council Member Place 6'
   AND o.politician_id IS NULL
   AND o.is_vacant IS NOT TRUE;

COMMIT;

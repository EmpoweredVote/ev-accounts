-- =====================================================================================
-- Data cull: Utah June-23-2026 primary losers still 'active' in race_candidates.
--
-- Source: `.planning/todos/2026-07-09-ut-primary-losers-cull.md` — Ballotpedia district
--   pages (primary-results sections, fetched 2026-07-09 via /wiki/api.php parse) for the
--   7 state-leg losers; Daily Herald + electionresults.utah.gov Primary06232026 for the
--   3 Utah County Commission losers. Margins decisive on all 10.
--
--   Evan Done (D)      SD-13  lost to Catten 44.1-32.8
--   Taylor Paden (D)   SD-13  23.0%
--   Tayler Khater (D)  SD-14  lost to inc. Pitcher 77.6-22.4
--   Kelly Smith (R)    SD-21  lost to inc. Brammer 56.8-43.2
--   Alexis Wheeler (R) HD-29  lost to Birch 64.9-35.1
--   Gloria Vindas (R)  HD-38  lost to McConnehey 60.6-39.4
--   Eryn Russo (R)     HD-41  lost to Croft 62.5-37.5
--   Brent Bowles (R)   UtahCo Comm A  lost to Kaufusi 55.73-44.27
--   Isaac Paxman (R)   UtahCo Comm B  2nd of 3 (35.21%)
--   Carolina Herrin (R) UtahCo Comm B 3rd of 3 (22.68%)
--
-- Dan McCay (SD-18, lost to Fiefia 69.5-30.5) was ALREADY 'withdrawn' when this
-- migration was authored (verified live 2026-07-12) — not touched here.
--
-- Convention: 'withdrawn' is the only non-active candidate_status (CHECK constraint
-- allows active/filed/withdrawn); it is the established cull value (108 prior rows).
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

UPDATE essentials.race_candidates
SET candidate_status = 'withdrawn'
WHERE politician_id IN (
  '77dc9a42-5f37-4608-89a1-10e60f86a3a1',  -- Evan Done, UT SD-13
  '327298e7-e42c-4dfa-9f1d-55cfd48e0659',  -- Taylor Paden, UT SD-13
  '28df85e8-73c8-4def-bdd1-6929ff083590',  -- Tayler Khater, UT SD-14
  '92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4',  -- Kelly Smith, UT SD-21
  '860cd9e1-75ed-4094-8657-5b5d8dc02539',  -- Alexis Wheeler, UT HD-29
  '1ff4157d-be90-46d0-9ad8-121255277473',  -- Gloria Vindas, UT HD-38
  '62146875-3316-42e5-91f6-fdac6c420b32',  -- Eryn Russo, UT HD-41
  'b71ec1b6-7d9e-406b-a30a-8c0710278d5e',  -- Brent Bowles, UtahCo Commission A
  'b4aac990-f353-4ea7-bdb3-d5cf2cd232c8',  -- Isaac Paxman, UtahCo Commission B
  '2ddafa6c-f5b8-40d6-a8d8-fce8f4849463'   -- Carolina Herrin, UtahCo Commission B
)
AND candidate_status IN ('active', 'filed');

COMMIT;

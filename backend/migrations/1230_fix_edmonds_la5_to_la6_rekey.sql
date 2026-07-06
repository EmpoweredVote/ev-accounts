-- 1230: Correct Rick Edmonds' district — LA-5 → LA-6 re-key (Phase 163-09 flag resolution)
--
-- WHY: The 163-06 LA seed placed Rick Edmonds (state senator, R-Baton Rouge) in LA-5,
-- sourced from the Phase-160 field table (Wikipedia snapshot of his Feb-11-2026 LA-5
-- qualifying). He has since SWITCHED to LA-6 to challenge incumbent Cleo Fields (D) —
-- driven by the SB121/Act 2 redistricting that turned LA-6 into a White-majority,
-- Baton-Rouge-centered seat where Edmonds (the only Republican living in Baton Rouge)
-- has a geographic advantage. Confirmed 2026-07-06 via his own campaign site body copy
-- (rickedmonds.com — "candidate for Louisiana's 6th Congressional District"), the
-- Livingston Parish News LA-6 finance-committee story, and Louisiana Illuminator/Ballotpedia
-- coverage of the switch. (His campaign page <title> and the initial announcement articles
-- still say "5th" — stale; body copy is current.)
--
-- EFFECT: moves his single race_candidates row from the LA-5 race (visible "LA 2026
-- Statewide General") to the LA-6 race (WITHHELD "LA 2026 Congressional Redistricting -
-- Polygon Pending"), and re-keys his external_id -220503 → -220605 for band consistency
-- (LA-6 = -2206xx; -220605 is the next free slot after Appeaning/Davis/Johnson/Williams).
-- His 2 already-pushed federal-24 stances ride on his politician_id (UUID) and are untouched.
-- LA-6 is non-surfacing (withheld), so nothing changes on /elections; per-district active
-- counts become LA-5=12, LA-6=6 (update the 163-11 gate expectations accordingly).
--
-- Idempotent: guarded on the pre-move state; re-run is a no-op once applied.

BEGIN;

-- 1) Re-point the race_candidates row LA-5 → LA-6 (only if still on the LA-5 race).
UPDATE essentials.race_candidates rc
SET race_id = (
      SELECT r.id FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      WHERE r.position_name = 'U.S. Representative District 6'
        AND e.name = 'LA 2026 Congressional Redistricting - Polygon Pending'
    ),
    updated_at = now()
WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -220503)
  AND rc.race_id = (
      SELECT r.id FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      WHERE r.position_name = 'U.S. Representative District 5'
        AND e.name = 'LA 2026 Statewide General'
    );

-- 2) Re-key external_id -220503 → -220605 (only if -220605 is free).
UPDATE essentials.politicians
SET external_id = -220605
WHERE external_id = -220503
  AND NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -220605);

COMMIT;

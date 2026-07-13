-- =====================================================================================
-- Data fix: delete 6 fabricated "Utah County Commissioner" office rows held by
-- 2026 CANDIDATES — a NEW variant of the candidate-office leak.
--
-- FOUND 2026-07-12 while running the Kaufusi title check from
--   `.planning/todos/2026-07-09-ut-primary-losers-cull.md`. The flag asked whether
--   any DB title says "Mayor of Provo" (Kaufusi is the FORMER Provo mayor, voted out
--   2025) — it doesn't. Instead: ALL SIX Utah County Commission 2026 candidates
--   (Bowles, Herrin, Spencer, Allen, Paxman, Kaufusi) hold PLAIN-TITLED
--   "Utah County Commissioner" offices with is_vacant=false, as if they were sitting
--   commissioners. None of them is: the 2026 general is Nov-3, and three of the six
--   (Bowles, Paxman, Herrin) LOST their June-23 primaries (culled in mig 1323).
--
-- LEAK CLASS: the standing officials-surface guard (`o.title NOT ILIKE 'Candidate
--   for%'`, see project_senate_candidate_office_leak) assumes candidate offices are
--   titled "Candidate for ..." — these rows carry the OFFICEHOLDER title, so the
--   guard cannot catch them and all 6 surface as sitting Utah County Commissioners.
--
-- SCOPE CHECK (live 2026-07-12): the pattern is exactly these 6 rows — no other
--   UtahCo/SLCo office rows exist at all (the REAL sitting commissioners — Gordon,
--   Beltran, Powers Gardner — were never seeded as officials; that is a coverage
--   gap, not a leak, left for a future county-officials wave). No race references
--   these office ids; races.office_id is the only FK onto offices.
--
-- FIX: delete the 6 rows (candidates need no offices row — elections surfacing
--   rides races/race_candidates). politicians.office_id (non-FK denormalized
--   column) cleared first where it points at a doomed row.
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

WITH doomed(office_id) AS (VALUES
  ('ac54025d-bdae-40bf-8aac-a79cc7020894'::uuid),  -- Brent Bowles      (lost primary)
  ('88fb4f88-e3f3-45aa-9787-09b0f8768412'::uuid),  -- Carolina Herrin   (lost primary)
  ('044b5d5c-185b-43c9-8365-d92c77f29e90'::uuid),  -- David Spencer     (general candidate)
  ('5dc00597-a2db-4745-9047-e39e7a4147c4'::uuid),  -- Fred J. Allen     (general candidate)
  ('b13c8473-3c2f-438f-b74a-20d36119b90c'::uuid),  -- Isaac Paxman      (lost primary)
  ('8224b570-6f61-4b10-8871-d7016303c5ee'::uuid)   -- Michelle Kaufusi  (general candidate; FORMER Provo mayor)
),
clear_denorm AS (
  UPDATE essentials.politicians SET office_id = NULL
  WHERE office_id IN (SELECT office_id FROM doomed)
)
DELETE FROM essentials.offices WHERE id IN (SELECT office_id FROM doomed);

COMMIT;

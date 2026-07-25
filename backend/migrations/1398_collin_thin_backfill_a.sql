-- =============================================================================
-- Migration 1398: Murphy Mayor sourced backfill (Collin thin-city backfill A)
-- Murphy (4850100)
-- (Phase 219 Plan 07 — elections-candidates-backfill)
--
-- SOURCED-ONLY SCOPE (operator decision, 2026-07-24): this migration seeds
-- EXACTLY ONE race — Murphy Mayor — because it is the only one of the 25
-- offices originally drafted for this migration that has a real, cited
-- election finding (not merely an inferred cycle from a politician's term-
-- start date). Every other draft race was removed per operator instruction;
-- see the REMOVED-OFFICES list below.
--
-- ============================================================
-- MURPHY MAYOR — the one sourced race (KEEP)
-- ============================================================
-- Migration 096's own header comment ("Murphy Mayor (Scott Bradley) —
-- re-elected unopposed May 3, update term to 2026-2029") is a citable,
-- HIGH-confidence prior finding that this seat WAS on the May 2026 ballot,
-- uncontested, and was simply never seeded as a race by migration 100 (an
-- oversight — Scott Bradley's `valid_to` in the live politicians row still
-- reads 2026-05-01; the migration 096 TODO to bump it to 2029 was never
-- executed either; this migration does NOT touch that politicians-table
-- staleness, out of this phase's races/candidates-only scope). This is a
-- real D-03 declared-elected-unopposed backfill under the SHARED '2026
-- Texas Municipal General' election row (resolved by name/date/state, never
-- a hardcoded literal UUID) — not a fabrication, not an inference.
--
-- ============================================================
-- REMOVED OFFICES (operator decision: SOURCED-ONLY, no term-date inference)
-- ============================================================
-- The following 24 offices were DRAFTED in an earlier version of this
-- migration using ONLY each officeholder's already-cited term-start date
-- (from migrations 094/096/097) to infer a reference-election year (2024 or
-- 2025), with NO independently-sourced election citation (no canvass, no
-- news, no city elections-page confirmation) for the election itself. The
-- operator ruled this inference-only approach out of scope for this
-- migration. All INSERTs for these offices, and the now-unused minted
-- election rows that would have anchored them, have been REMOVED from this
-- file entirely (they never run, so there is nothing to guard against
-- re-seeding — there is no code path left that could create them).
--
-- These 24 offices remain [OPEN — no sourced election this session;
-- officeholder known but the election wrapper was inference-only]. This is
-- NOT a defect — per Phase 219's Pitfall 4 ("'0 unseated offices' != 'races
-- complete'"), an office with a known, real officeholder can legitimately
-- have zero sourced elections to seed a race from. Phase 219 Plan 09
-- (COVERAGE) treats these as documented-open, not as bugs to auto-fix.
--
--   Lucas (4845012):   Mayor, Council Member Place 3, 4, 5, 6
--   Murphy (4850100):  Council Member Place 1, 2, 4, 6
--   Allen (4801924):   Council Member Place 1, 3, 4, 5, 6
--   Anna (4803300):    Mayor, Council Member Place 1, 2, 4, 6
--   Prosper:           Mayor, Council Member Place 1, 2, 4, 6
--     NOTE (geo_id correction): the draft of this migration used geo_id
--     4863276 for Prosper. The operator has flagged Prosper's REAL geo_id as
--     4859696 (Town of Prosper) — 4863276 appears to be stale/incorrect.
--     Since Prosper seeds NOTHING in this final version, this is a
--     documentation-only note for a future Prosper reconcile; no SQL in
--     this file references either geo_id for Prosper.
--
-- Removed election rows that are no longer minted anywhere in this file:
-- 'Lucas TX City General 2024', 'Murphy TX City General 2024',
-- 'Murphy TX City General 2025', 'Allen TX City General 2024',
-- 'Allen TX City General 2025', 'Anna TX City General 2024',
-- 'Prosper TX City General 2024', 'Prosper TX City General 2025'.
--
-- ============================================================
-- IDEMPOTENCY / CONVENTIONS
-- ============================================================
-- Race via ON CONFLICT (election_id, position_name) WHERE primary_party IS
-- NULL DO NOTHING (migration 044's real partial-unique constraint).
-- Candidate via WHERE NOT EXISTS (race_id, full_name) guard. D-06
-- antipartisan: primary_party NULL. D-07: zero inform.* writes (verified by
-- the apply-script's before/after gate). Office lookup guarded by an
-- explicit `IF v_office_id IS NULL THEN RAISE EXCEPTION` check (office_id is
-- nullable on essentials.races per migration 042 — without this guard, a
-- wrong geo_id/title would silently create an orphan race instead of
-- failing loudly). candidate_status='active' (schema CHECK permits only
-- active/withdrawn/filed — migration 042/Phase-219-RESEARCH Pitfall 2);
-- "who won" is expressed purely via politician_id linkage.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_shared UUID;
  v_office_id       UUID;
  v_race            UUID;
  v_politician      UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- Resolve the shared 2026-05-02 row by name/date/state (never a hardcoded
  -- literal UUID).
  -- ------------------------------------------------------------------
  SELECT id INTO v_election_shared FROM essentials.elections
   WHERE name = '2026 Texas Municipal General' AND election_date = '2026-05-02' AND state = 'TX';

  IF v_election_shared IS NULL THEN
    RAISE EXCEPTION 'Migration 1398: shared 2026 Texas Municipal General election row not found — aborting';
  END IF;

  -- ============================================================
  -- MURPHY (geo_id 4850100) — Mayor, under the SHARED row
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4850100' AND o.title = 'Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1398: Murphy (4850100) Mayor office not found — aborting'; END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_shared, v_office_id, 'Murphy Mayor', 1, NULL, 'Declared elected — unopposed; incumbent Scott Bradley re-elected May 3 2026, per migration 096''s own header note (never previously seeded as a race)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_shared AND r.position_name = 'Murphy Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Scott Bradley', 'Scott', 'Bradley', true, 'active', 'migration 096 header note ("re-elected unopposed May 3"); murphytx.org'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Scott Bradley');

END $$;

COMMIT;

-- =============================================================================
-- Migration 1396: Plano (Jan-2026 special) + Weston (November-cycle) races
-- Plano (4858016), Weston (4877740)
-- (Phase 219 Plan 05 — elections-candidates-backfill)
--
-- Seeds essentials.elections + essentials.races + essentials.race_candidates for
-- the two most staggered zero-race Collin cities resolved in 219-PREFLIGHT.md §4.
-- Neither city is linked to the shared '2026 Texas Municipal General'
-- (2026-05-02, id 8eaba170-95f5-4c98-849e-19ff93a17680) row anywhere in this
-- file — both mint their OWN election row(s) by (name, election_date, state),
-- resolved via `elections_name_date_state_unique` (migration 044), never a
-- hardcoded literal UUID.
--
-- ============================================================
-- PLANO (geo_id 4858016) — ONE new election row: Jan 31, 2026 special
-- ============================================================
-- 'Plano TX City Special 2026', 2026-01-31.
--
-- Plano is the most complex zero-race city: 3-year staggered terms across
-- 2023-2026 for its 9 offices (Mayor + Council Member Place 1-8, per migration
-- 088). Of these 9 offices, this migration seeds exactly ONE race:
--
-- Council Member Place 7 (special election, Jan 31 2026): Shun Thomas won
-- ~60.4%, no runoff needed. PREFLIGHT §4 cites only Thomas's win percentage —
-- no opponent name is cited anywhere in 219-PREFLIGHT.md or 219-RESEARCH.md for
-- this race. Per the plan's explicit instruction, this migration seeds Thomas
-- as the sole cited candidate and does NOT fabricate an opponent; the race's
-- description documents that the full filed field was not sourced this
-- session. is_incumbent=false: the special election filled what was, per every
-- source, an OPEN seat (Thomas was not already the Place 7 officeholder before
-- this election — he became so as a result of it). Thomas's politician_id is
-- reused from `offices.politician_id` (already seated by migration 091,
-- pre-dating Phase 218) — no new politician row, no new headshot work; his
-- existing photo (if any) carries through the FK automatically.
-- Sources: plano.gov/1402/Elections; Ballotpedia "City elections in Plano,
-- Texas (2026)"; Community Impact (all carried from 219-RESEARCH.md/PREFLIGHT,
-- not re-fetched fresh this session — no conflicting signal found).
--
-- Council Member Place 6: a DOCUMENTED GENUINE VACANCY (migration 1392, Phase
-- 218) — deliberately NO race is seeded for this office anywhere in this file.
-- This is a hard prohibition (D-03/backstop), enforced by the apply-script's
-- explicit expected-0 gate on this exact office_id.
--
-- Plano's other 7 offices (Mayor, Places 1-5, 8) span staggered 2023/2024/2025
-- cycles that were NOT researched this session (219-RESEARCH.md's own Pitfall 3
-- explicitly flags per-seat staggered term-history depth as exceeding this
-- backfill's cheap research horizon) — deliberately NO SQL for them. Documented
-- open gap per PREFLIGHT §7, not guessed.
--
-- ============================================================
-- WESTON (geo_id 4877740) — ONE new election row: November 2024 general
-- ============================================================
-- 'Weston TX City General 2024', 2024-11-05 (Texas November uniform election
-- date, 2024).
--
-- Weston votes on its own November cycle, NOT the shared May TX municipal
-- date — confirmed by Phase 218 ("no May-2026 election"). Of Weston's 6
-- offices (Mayor + Council Member Place 1-5, per migrations 090/1388), this
-- migration seeds exactly ONE race:
--
-- Council Member Place 5: Marla Johnston, term 2024-11-01 -> 2026-11-01 (per
-- 218/1389 seating). This is the only Weston seat with a cited term-date range
-- tying it to a specific election cycle this session; the exact election date
-- and full per-seat roster were left [OPEN] in PREFLIGHT §4/§7 — no web-search
-- tooling was available to this executor to resolve them fresh this session, so
-- per the plan's explicit fallback instruction, this migration seeds ONLY
-- Johnston under a minted 'Weston TX City General 2024' row dated 2024-11-05
-- (the plan's own cited fallback date for this exact scenario). No opponent
-- name and no incumbency citation exist for this seat this session —
-- is_incumbent is seeded false (not fabricated true), and the race description
-- documents that the roster was not independently re-verified. Johnston's
-- politician_id is reused from `offices.politician_id` (already seated by
-- migration 1389 from a new office row created in migration 1388 — a genuine
-- 6th aldermanic seat the DB was previously missing).
-- Source: westontexas.com/page/Mayor_Aldermen (per 218, live-fetched; carried
-- forward, not re-fetched fresh this session).
--
-- Weston's other 5 offices (Mayor, Places 1-4) were seeded in migration 098
-- with placeholder term dates ('2024-05-01 -> 2027-05-01', a May cycle) that do
-- NOT match Weston's confirmed November voting cycle and are NOT independently
-- cited to any specific election this session — deliberately NO SQL for them.
-- Documented open gap per PREFLIGHT §7, not guessed.
--
-- ============================================================
-- IDEMPOTENCY / CONVENTIONS
-- ============================================================
-- Own election rows via ON CONFLICT (name, election_date, state) DO NOTHING
-- (migration 044's elections_name_date_state_unique constraint), resolved by
-- name/date/state afterward — never a hardcoded literal election UUID as an
-- INSERT target. Races via ON CONFLICT (election_id, position_name) WHERE
-- primary_party IS NULL DO NOTHING (migration 044's real partial-unique
-- constraint). Candidates via WHERE NOT EXISTS (race_id, full_name) guard.
-- D-06 antipartisan: primary_party NULL on both races. D-07: zero inform.*
-- writes (verified by the apply-script's before/after gate). Every office
-- lookup is guarded by an explicit `IF v_office_id IS NULL THEN RAISE
-- EXCEPTION` check (office_id is nullable on essentials.races per migration
-- 042 — without this guard, a wrong geo_id/title would silently create an
-- orphan race instead of failing loudly). candidate_status='active' on every
-- row (schema CHECK constraint permits only active/withdrawn/filed — see
-- migration 042/Phase-219-RESEARCH Pitfall 2); "who won" is expressed purely
-- via politician_id linkage, never via candidate_status.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_plano_special UUID;
  v_election_weston_gen    UUID;
  v_office_id              UUID;
  v_race                   UUID;
  v_politician             UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- Mint (or reuse) Plano's own 2026-01-31 Special election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES ('Plano TX City Special 2026', '2026-01-31', 'TX', 'special', 'city', 'Special election, Council Member Place 7; Shun Thomas won ~60.4%, no runoff')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_plano_special FROM essentials.elections
   WHERE name = 'Plano TX City Special 2026' AND election_date = '2026-01-31' AND state = 'TX';

  IF v_election_plano_special IS NULL THEN
    RAISE EXCEPTION 'Migration 1396: Plano TX City Special 2026 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Mint (or reuse) Weston's own 2024-11-05 General election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES ('Weston TX City General 2024', '2024-11-05', 'TX', 'general', 'city', 'Weston''s own November uniform-election-cycle row; the city does not vote on the shared May TX municipal date (confirmed by Phase 218)')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_weston_gen FROM essentials.elections
   WHERE name = 'Weston TX City General 2024' AND election_date = '2024-11-05' AND state = 'TX';

  IF v_election_weston_gen IS NULL THEN
    RAISE EXCEPTION 'Migration 1396: Weston TX City General 2024 election row not found after mint — aborting';
  END IF;

  -- ============================================================
  -- PLANO (geo_id 4858016) — Special race: Council Member Place 7
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4858016' AND o.title = 'Council Member Place 7';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1396: Plano (4858016) Council Member Place 7 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_plano_special, v_office_id, 'Plano Council Member Place 7 Special', 1, NULL, 'Shun Thomas won ~60.4%, no runoff, Jan 31 2026; no opponent name found in any cited source this session — full filed field not sourced, not fabricated')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_plano_special AND r.position_name = 'Plano Council Member Place 7 Special';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Shun Thomas', 'Shun', 'Thomas', false, 'active', 'plano.gov/1402/Elections; Ballotpedia City elections in Plano, Texas (2026); Community Impact'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Shun Thomas');

  -- PLANO Council Member Place 6: deliberately NO SQL here — documented genuine
  -- vacancy per migration 1392. Never seed a race for this office_id. Verified
  -- by the apply-script's explicit expected-0 gate.
  --
  -- PLANO Mayor, Places 1-5, 8: deliberately NO SQL here — staggered
  -- 2023/2024/2025 term-history not resolved this session, [OPEN] per
  -- PREFLIGHT §4/§7 (RESEARCH.md Pitfall 3).

  -- ============================================================
  -- WESTON (geo_id 4877740) — General race: Council Member Place 5
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1396: Weston (4877740) Council Member Place 5 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_weston_gen, v_office_id, 'Weston Council Member Place 5', 1, NULL, 'Marla Johnston, term 2024-11-01 to 2026-11-01; opponent/incumbency not independently cited this session, full roster not re-verified')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_weston_gen AND r.position_name = 'Weston Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Marla Johnston', 'Marla', 'Johnston', false, 'active', 'westontexas.com/page/Mayor_Aldermen'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Marla Johnston');

  -- WESTON Mayor, Places 1-4: deliberately NO SQL here — migration 098's
  -- placeholder May-cycle term dates do not match Weston's confirmed November
  -- voting cycle and are not independently cited to any specific election this
  -- session, [OPEN] per PREFLIGHT §4/§7.

END $$;

COMMIT;

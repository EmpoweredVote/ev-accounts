-- =============================================================================
-- Migration 1399: Parker photo-link UPDATE + Frisco Place 1 special-election
-- backfill (Collin thin-city backfill B)
-- Parker (4855152), Celina (4813684), Frisco (4827684), Fairview (4825224),
-- Lowry Crossing (4844308)
-- (Phase 219 Plan 08 — elections-candidates-backfill)
--
-- SOURCED-ONLY SCOPE (operator decision, 2026-07-24, same standard applied in
-- migration 1398): this migration seeds EXACTLY ONE new race — Frisco Council
-- Member Place 1 (Ann Anderson's Feb-2026 special election) — plus the Parker
-- politician_id link-up UPDATE (D-05, not a new race, not an inferred
-- election). Every other race-less office across these 5 cities was checked
-- against every source available to this executor this session (219-
-- RESEARCH.md, 219-PREFLIGHT.md, and every prior Collin migration's own
-- header/inline comments — no WebSearch/WebFetch tool was available this
-- session) and found to have ONLY a term-start-date citation (from migrations
-- 094/096/097/098), never an independently-sourced election result. Per the
-- operator's SOURCED-ONLY ruling, a bare term-start date is NOT sufficient to
-- infer/mint a race — see the REMAINING [OPEN] OFFICES list below.
--
-- ============================================================
-- PARKER (geo_id 4855152) — politician_id link-up (KEEP, D-05 photo reuse)
-- ============================================================
-- Parker's EXISTING migration-100 race_candidates rows for Lee Pettle (Mayor),
-- Buddy Pilgrim (Council Member Place 3), and Billy Barron (Council Member
-- Place 5) were seeded with no politician_id (migration 100 predates these
-- people's Phase-218 seating). Migration 1389 has since seated all three as
-- the current officeholders for their respective offices (offices.politician_id
-- is now set for each). This UPDATE links the EXISTING race_candidates rows to
-- their now-existing politician_id — a photo/profile carry-through only. It is
-- NOT a new race and NOT an inferred election; the underlying races (Parker
-- Mayor / Parker Councilmember At-Large) were already seeded from the real
-- May-2026 Collin County canvass in migration 100. Guarded by
-- `politician_id IS NULL` so a second run affects 0 rows (idempotent, never
-- overwrites a non-NULL value).
--
-- ============================================================
-- FRISCO (geo_id 4827684) — Council Member Place 1, Ann Anderson (SEED, sourced)
-- ============================================================
-- Migration 094's own header/inline comment (`094_allen_frisco_politicians.sql`
-- line 361) states explicitly: "Won special election February 2026;
-- is_appointed=false (elected, not appointed)" — a citable, real
-- election-outcome finding (not a bare term-date inference; the comment
-- affirmatively distinguishes "elected" from "appointed"), matching migration
-- 1398's Murphy Mayor precedent for what counts as SOURCED. No opponent name
-- or vote tally is cited anywhere in this codebase for this race — per D-04's
-- "full filed field" intent tempered by the no-fabrication rule, only Ann
-- Anderson (the one cited winner) is seeded; the race's description documents
-- that the full filed field was not sourced this session (mirrors migration
-- 1396's Plano Place 7 precedent for exactly this situation). Its own NEW
-- election row is minted (a Feb-2026 special != the shared May-2026 date),
-- resolved by name/date/state, never a hardcoded literal UUID. is_incumbent
-- =false: no source states Anderson held this seat before the special election
-- (the "elected, not appointed" phrasing implies an open/vacant-seat special,
-- not a retention). Her politician_id is reused from `offices.politician_id`
-- (already seated by migration 094) — no new politician row, no new headshot
-- work; her existing photo (if any) carries through the FK automatically.
--
-- ============================================================
-- REMAINING [OPEN] OFFICES (no sourced election this session)
-- ============================================================
-- Parker (4855152):        Council Member Place 1 (Roxanne Bogdan), Place 2
--                           (Colleen Halbert), Place 4 (Darrel Sharpe) —
--                           term-date only (migration 098).
-- Celina (4813684):        Council Member Place 1 (Philip Ferguson), Place 2
--                           (Eddie Cawlfield), Place 3 (Andy Hopkins), Place 6
--                           (Brandon Grumbles) — term-date only (migration 096).
-- Frisco (4827684):        Council Member Place 2 (Burt Thakur), Place 3
--                           (Angelia Pelham), Place 4 (Jared Elad) — term-date
--                           only (migration 094).
-- Fairview (4825224):      Mayor (John Hubbard), Council Member Seat 1 (Rich
--                           Connelly), Seat 3 (Jill Hawkins), Seat 5 (Pat
--                           Sheehan) — term-date only (migration 097).
-- Lowry Crossing (4844308): Mayor (Pat Kelly), Council Member Place 1 (Scott
--                           Pitchure), Place 2 (Tammy Hodges), Place 3 (Eusebio
--                           "Joe" Trujillo III) (migration 098), Place 5 (Chris
--                           Madrid), Place 6 (Agur Rios), Place 7 (Cindy Cash)
--                           (migration 1389, explicitly flagged there as
--                           "DB-gap continuing incumbent" — an inference, not a
--                           cited election) — all term-date only.
--
-- These 17 offices remain [OPEN — no sourced election this session;
-- officeholder known but the election wrapper was inference-only]. This is NOT
-- a defect — per Phase 219's Pitfall 4 ("'0 unseated offices' != 'races
-- complete'"), an office with a known, real officeholder can legitimately have
-- zero sourced elections to seed a race from. A future reconcile with live
-- WebSearch/WebFetch tooling could resolve some of these.
--
-- ============================================================
-- IDEMPOTENCY / CONVENTIONS
-- ============================================================
-- Own election row via ON CONFLICT (name, election_date, state) DO NOTHING
-- (migration 044's elections_name_date_state_unique constraint), resolved by
-- name/date/state afterward — never a hardcoded literal election UUID as an
-- INSERT target. Race via ON CONFLICT (election_id, position_name) WHERE
-- primary_party IS NULL DO NOTHING (migration 044's real partial-unique
-- constraint). Candidate via WHERE NOT EXISTS (race_id, full_name) guard.
-- Parker UPDATE via `politician_id IS NULL` guard (net-zero re-run, never
-- overwrites). D-06 antipartisan: primary_party NULL. D-07: zero inform.*
-- writes (verified by the apply-script's before/after gate). Office lookup
-- guarded by an explicit `IF v_office_id IS NULL THEN RAISE EXCEPTION` check
-- (office_id is nullable on essentials.races per migration 042 — without this
-- guard, a wrong geo_id/title would silently create an orphan race instead of
-- failing loudly). candidate_status='active' (schema CHECK permits only
-- active/withdrawn/filed — migration 042/Phase-219-RESEARCH Pitfall 2); "who
-- won" is expressed purely via politician_id linkage. Existing migration-100
-- races for these 5 cities are NEVER touched by this migration (verified by
-- the apply-script's per-city race-count-unchanged gate).
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_frisco_special UUID;
  v_office_id               UUID;
  v_race                    UUID;
  v_politician              UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- PARKER (4855152) — link existing race_candidates rows to their now-
  -- existing politician_id (D-05 photo reuse). Guarded WHERE politician_id
  -- IS NULL so re-run is net-zero; never overwrites a non-NULL value.
  -- ------------------------------------------------------------------

  -- Lee Pettle — Parker Mayor
  SELECT o.politician_id INTO v_politician FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4855152' AND o.title = 'Mayor';

  IF v_politician IS NULL THEN
    RAISE NOTICE 'Migration 1399: Parker Mayor politician_id not found — Pettle link-up skipped (idempotent no-op)';
  ELSE
    UPDATE essentials.race_candidates
       SET politician_id = v_politician
     WHERE full_name = 'Lee Pettle' AND politician_id IS NULL;
    RAISE NOTICE 'Migration 1399: Parker Mayor (Lee Pettle) politician_id link-up applied (or already net-zero) — %', v_politician;
  END IF;

  -- Buddy Pilgrim — Parker Council Member Place 3
  SELECT o.politician_id INTO v_politician FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 3';

  IF v_politician IS NULL THEN
    RAISE NOTICE 'Migration 1399: Parker Place 3 politician_id not found — Pilgrim link-up skipped (idempotent no-op)';
  ELSE
    UPDATE essentials.race_candidates
       SET politician_id = v_politician
     WHERE full_name = 'Buddy Pilgrim' AND politician_id IS NULL;
    RAISE NOTICE 'Migration 1399: Parker Place 3 (Buddy Pilgrim) politician_id link-up applied (or already net-zero) — %', v_politician;
  END IF;

  -- Billy Barron — Parker Council Member Place 5
  SELECT o.politician_id INTO v_politician FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 5';

  IF v_politician IS NULL THEN
    RAISE NOTICE 'Migration 1399: Parker Place 5 politician_id not found — Barron link-up skipped (idempotent no-op)';
  ELSE
    UPDATE essentials.race_candidates
       SET politician_id = v_politician
     WHERE full_name = 'Billy Barron' AND politician_id IS NULL;
    RAISE NOTICE 'Migration 1399: Parker Place 5 (Billy Barron) politician_id link-up applied (or already net-zero) — %', v_politician;
  END IF;

  -- ------------------------------------------------------------------
  -- FRISCO (4827684) — mint own Feb-2026 special-election row, then the
  -- Council Member Place 1 race + sole cited candidate.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES (
    'Frisco TX City Special 2026', '2026-02-01', 'TX', 'special', 'city',
    'Special election, Council Member Place 1; Ann Anderson elected per migration 094 header note ("Won special election February 2026"); exact day and opponent(s) not cited in any source found this session'
  )
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_frisco_special FROM essentials.elections
   WHERE name = 'Frisco TX City Special 2026' AND election_date = '2026-02-01' AND state = 'TX';

  IF v_election_frisco_special IS NULL THEN
    RAISE EXCEPTION 'Migration 1399: Frisco TX City Special 2026 election row not found after mint — aborting';
  END IF;

  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1399: Frisco (4827684) Council Member Place 1 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (
    v_election_frisco_special, v_office_id, 'Frisco Council Member Place 1 Special', 1, NULL,
    'Ann Anderson elected, Feb 2026 special election (migration 094 header note: "Won special election February 2026"); no opponent name or exact day cited in any source this session — full filed field not sourced, not fabricated'
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r
   WHERE r.election_id = v_election_frisco_special AND r.position_name = 'Frisco Council Member Place 1 Special';

  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Ann Anderson', 'Ann', 'Anderson', false, 'active',
    'migration 094 header note ("Won special election February 2026"); friscotexas.gov/directory.aspx?EID=925'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Ann Anderson');

END $$;

COMMIT;

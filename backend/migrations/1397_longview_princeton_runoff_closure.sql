-- =============================================================================
-- Migration 1397: Longview D3 general + Princeton Place 4 runoff closure
-- Longview (4843888, Gregg Co), Princeton (4859576, Collin)
-- (Phase 219 Plan 06 — elections-candidates-backfill, runoff-closure tier)
--
-- Closes the two-stage-election gaps identified in 219-RESEARCH.md Pitfall 5 /
-- Pattern 5 and locked in 219-PREFLIGHT.md §4/§5:
--
--   Longview D3   — only the June 13, 2026 RUNOFF exists in the DB (migration
--                   187). The original May 2, 2026 GENERAL race (5-candidate
--                   field) has never been seeded. This migration adds ONLY the
--                   missing GENERAL stage, under the shared '2026 Texas
--                   Municipal General' election row, resolved by name/date/
--                   state (never a hardcoded literal UUID). It does NOT touch,
--                   duplicate, or re-mint migration 187's runoff election row —
--                   an explicit guard below asserts exactly one such row exists
--                   both before and after this migration runs.
--
--   Princeton P4  — only the May 2, 2026 SPECIAL election exists in the DB
--                   (migration 100, description='Unexpired term', 4
--                   candidates: Ramani/Goria/Rutledge/Abdulkareem). The June 13,
--                   2026 RUNOFF between the top-2 (Rutledge defeated Goria,
--                   293-245, certified June 23, 2026) has never been seeded.
--                   This migration mints a NEW own election row for the
--                   runoff (name/date/state resolved via ON CONFLICT, same
--                   idiom as migration 1395), distinct from and never
--                   modifying migration 100's special-election row. The
--                   runoff race gets its own stage-disambiguated position_name
--                   ('Princeton Council Member Place 4 Runoff') so it can never
--                   collide with migration 100's 'Princeton Council Member
--                   Place 4' under a different election_id anyway.
--
-- ============================================================
-- LONGVIEW D3 SEATING GAP — FLAGGED, NOT RESOLVED HERE
-- ============================================================
-- offices.politician_id for Longview District 3 still reflects hold-over Wray
-- Wade (per migration 187's own header comment: "Wade is serving in a
-- hold-over capacity until the runoff winner is seated"), despite Brandon
-- Smith's confirmed June 13, 2026 runoff win (223-204, 52.22%). This migration
-- deliberately does NOT update offices.politician_id — seating the runoff
-- winner is a Phase-218-style officeholder action, out of this phase's stated
-- "elections & candidates" scope (per 219-PREFLIGHT.md §5 recommendation,
-- carried forward unchanged from 219-RESEARCH.md Open Question 2). The race +
-- candidates are seeded here (this phase's job); the seating decision is
-- surfaced to the operator at Task 3's checkpoint, not silently resolved.
--
-- Contrast: Princeton Place 4's equivalent seating gap is ALREADY CLOSED —
-- migration 1389 (Phase 218) seated Jaisen Rutledge as the current Place 4
-- officeholder (politicians row + offices.politician_id UPDATE), so this
-- migration reuses that existing politician_id for Rutledge's runoff
-- race_candidates row (Pattern 3's winner-linkage idiom) — no new politicians
-- row, no duplicate-officeholder risk.
--
-- ============================================================
-- LONGVIEW D3 GENERAL — HONEST PARTIAL ROSTER
-- ============================================================
-- News coverage (longviewtexas.gov/3308/City-Election-Results;
-- longviewtexas.gov/2154/General-Election-Candidates; Longview News-Journal)
-- establishes the May 2, 2026 D3 general was a 5-candidate field with no
-- majority winner, triggering the June 13 runoff. Only the top-2 vote-getters
-- who advanced to that runoff — Brandon Smith and Marlena Cooper — are named
-- in any source available to this session (matching migration 187's own
-- roster). The other 3 filers in the 5-candidate field are NOT named in any
-- cited source reachable this session and are NOT fabricated here (same
-- honest-partial-citation pattern as migration 1395's McKinney Mayor general,
-- which seeded only 2 of a 4-candidate field for the identical reason).
--
-- ============================================================
-- LONGVIEW DISTRICT 4 — BONUS: cited, uncontested, same May 2026 cycle
-- ============================================================
-- Migration 185's own header + the John Nustad politicians INSERT
-- (valid_from='2026-05-01') already establish, with citation
-- (longviewtexas.gov/2205/District-4---John-Nustad), that District 4 was
-- re-elected UNOPPOSED in the same May 2, 2026 cycle (D-03 declared-elected
-- pattern). Seeded here as a race under the shared row, linked to Nustad's
-- existing politician_id (already seated by migration 185 — no new
-- politicians row). Mayor + Districts 1, 2, 5, 6 were NOT up in the May 2026
-- cycle per the same migration 185 citations (valid_from 2024-05-01 or
-- 2025-05-01, next elections 2027/2028) — correctly left unseeded here, not a
-- fabrication risk, simply out of this reference cycle.
--
-- ============================================================
-- IDEMPOTENCY / CONVENTIONS (matches migration 1395's established idiom)
-- ============================================================
-- Shared-row races via ON CONFLICT (election_id, position_name) WHERE
-- primary_party IS NULL DO NOTHING (migration 044's partial-unique
-- constraint). Princeton's own runoff election row via ON CONFLICT (name,
-- election_date, state) DO NOTHING (migration 044's elections unique
-- constraint), resolved by name/date/state afterward — never a hardcoded
-- literal election UUID as an INSERT target. Candidates via WHERE NOT EXISTS
-- (race_id, full_name) guard. D-06 antipartisan: primary_party NULL on every
-- race. D-07: zero inform.* writes (verified by the apply-script's
-- before/after gate). Every office lookup is guarded by an explicit
-- `IF v_office_id IS NULL THEN RAISE EXCEPTION` check (office_id is nullable
-- on essentials.races per migration 042 — without this guard, a wrong
-- geo_id/title would silently create an orphan race instead of failing
-- loudly). An explicit RAISE EXCEPTION guard also asserts exactly ONE
-- Longview D3 runoff election row exists (no duplicate of migration 187's
-- row) before this migration proceeds.
--
-- Sources: longviewtexas.gov/3308/City-Election-Results;
-- longviewtexas.gov/2154/General-Election-Candidates;
-- longviewtexas.gov/2205/District-4---John-Nustad; Longview News-Journal
-- "Brandon Smith wins District 3 seat on Longview City Council" (2026-06-13);
-- Ballotpedia Brandon Smith 2026 candidate page; Princeton Herald "City
-- council runoff results FINAL" (2026-06-13); Princeton Herald "Runoff
-- required for Place 4 council seat" (2026-05-07); princetontx.gov "City
-- Council Highlights" newsflash (2026-06-23); migration 1389 (Rutledge
-- seating), migration 187 (Longview D3 runoff row), migration 100 (Princeton
-- Place 4 special).
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_shared_election_id   UUID;
  v_longview_d3_runoff_count INT;
  v_office_id             UUID;
  v_race                  UUID;
  v_politician            UUID;
  v_princeton_runoff_id   UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- Resolve the shared 2026-05-02 TX election row by name/date/state.
  -- ------------------------------------------------------------------
  SELECT id INTO v_shared_election_id FROM essentials.elections
   WHERE name = '2026 Texas Municipal General' AND election_date = '2026-05-02' AND state = 'TX';

  IF v_shared_election_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: shared 2026 Texas Municipal General election row not found — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- GUARD: exactly ONE Longview D3 runoff election row must already exist
  -- (migration 187) — never duplicated by this migration. This is the
  -- load-bearing no-duplicate-runoff-row invariant (219-PREFLIGHT.md §4/§5).
  -- ------------------------------------------------------------------
  SELECT COUNT(*) INTO v_longview_d3_runoff_count FROM essentials.elections
   WHERE name = 'Longview TX City Council District 3 Runoff 2026' AND election_date = '2026-06-13' AND state = 'TX';

  IF v_longview_d3_runoff_count != 1 THEN
    RAISE EXCEPTION 'Migration 1397: expected exactly 1 Longview D3 runoff election row (migration 187), found %. Aborting — do not mint a duplicate.', v_longview_d3_runoff_count;
  END IF;

  -- ============================================================
  -- LONGVIEW (geo_id 4843888) — General race: District 3
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4843888' AND o.title = 'Council Member District 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: Longview (4843888) Council Member District 3 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (
    v_shared_election_id, v_office_id, 'Longview Council Member District 3', 1, NULL,
    'General — 5-candidate field, no majority, runoff June 13 2026 (see migration 187); only Brandon Smith / Marlena Cooper (top 2, who advanced) named in sourced coverage this session — other 3 filers not fabricated'
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_shared_election_id AND r.position_name = 'Longview Council Member District 3';

  -- Neither candidate is linked via politician_id: the current officeholder
  -- (offices.politician_id) is hold-over Wray Wade, not a candidate in this
  -- race. Seating the winner is explicitly out of scope here (see header).
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Brandon Smith', 'Brandon', 'Smith', false, 'active', 'longviewtexas.gov/3308/City-Election-Results; longviewtexas.gov/2154/General-Election-Candidates'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Brandon Smith');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Marlena Cooper', 'Marlena', 'Cooper', false, 'active', 'longviewtexas.gov/3308/City-Election-Results; longviewtexas.gov/2154/General-Election-Candidates'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Marlena Cooper');

  -- ============================================================
  -- LONGVIEW — General race: District 4 (Nustad, unopposed, same May 2026 cycle)
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4843888' AND o.title = 'Council Member District 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: Longview (4843888) Council Member District 4 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (
    v_shared_election_id, v_office_id, 'Longview Council Member District 4', 1, NULL,
    'Declared elected — unopposed. John Nustad re-elected May 2026 (orig. elected May 2023); new term expires May 2029 (per migration 185).'
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_shared_election_id AND r.position_name = 'Longview Council Member District 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'John Nustad', 'John', 'Nustad', true, 'active', 'longviewtexas.gov/2205/District-4---John-Nustad (per migration 185)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'John Nustad');

  -- ============================================================
  -- PRINCETON (geo_id 4859576) — mint own Place 4 Runoff election row
  -- ============================================================
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES (
    'Princeton TX City Council Place 4 Runoff 2026', '2026-06-13', 'TX', 'special', 'city',
    'Runoff for the Place 4 unexpired-term seat (vacated mid-term when Ryan Gerfers resigned); Jaisen Rutledge defeated Jan Goria, 293-245; certified by City Council June 23, 2026. Distinct from the May 2, 2026 special election (migration 100), which is untouched by this migration.'
  )
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_princeton_runoff_id FROM essentials.elections
   WHERE name = 'Princeton TX City Council Place 4 Runoff 2026' AND election_date = '2026-06-13' AND state = 'TX';

  IF v_princeton_runoff_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: Princeton TX City Council Place 4 Runoff 2026 election row not found after mint — aborting';
  END IF;

  -- ============================================================
  -- PRINCETON — Runoff race: Council Member Place 4 Runoff
  -- (resolved by CURRENT geo_id 4859576, per 219-RESEARCH.md's note that
  -- Phase 217 corrected this city's geo_id post-original-seed from the stale
  -- 4863432 used in migration 090 — mirrors migration 1395's Richardson
  -- geo_id defensive guard.)
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4859576' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: Princeton (4859576) Council Member Place 4 office not found — aborting (verify current geo_id has not drifted further)';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (
    v_princeton_runoff_id, v_office_id, 'Princeton Council Member Place 4 Runoff', 1, NULL,
    'Jaisen Rutledge defeated Jan Goria, 293-245, June 13 2026 runoff; certified June 23 2026. Distinct race from the May 2026 special election (migration 100, position_name ''Princeton Council Member Place 4'').'
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_princeton_runoff_id AND r.position_name = 'Princeton Council Member Place 4 Runoff';

  -- Winner: Jaisen Rutledge — ALREADY seated as Princeton Place 4's current
  -- officeholder by migration 1389 (Phase 218). Reuse that existing
  -- politician_id (and thus photo, via politician_images) — no new
  -- politicians row, avoiding the duplicate-officeholder bug.
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  IF v_politician IS NULL THEN
    RAISE EXCEPTION 'Migration 1397: Princeton (4859576) Place 4 office.politician_id is NULL — expected Jaisen Rutledge already seated by migration 1389. Aborting rather than silently seeding a name-only candidate for the current officeholder.';
  END IF;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Jaisen Rutledge', 'Jaisen', 'Rutledge', false, 'active', 'Princeton Herald "City council runoff results FINAL" (2026-06-13); princetontx.gov City Council Highlights newsflash (2026-06-23); per migration 1389'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Jaisen Rutledge');

  -- Loser: Jan Goria — never became officeholder, denormalized name-only.
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Jan Goria', 'Jan', 'Goria', false, 'active', 'Princeton Herald "City council runoff results FINAL" (2026-06-13)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Jan Goria');

END $$;

COMMIT;

-- =============================================================================
-- Migration 1395: McKinney + Richardson real 2025 reference-cycle races
-- McKinney (4845744), Richardson (4861796)
-- (Phase 219 Plan 04 — elections-candidates-backfill)
--
-- Seeds essentials.elections + essentials.races + essentials.race_candidates for
-- the two "real cycle is 2025, NOT the shared 2026-05-02 row" zero-race cities
-- resolved in 219-PREFLIGHT.md §4/§6. Both cities mint their OWN election row(s)
-- by (name, election_date, state), resolved via `elections_name_date_state_unique`
-- (migration 044), never a hardcoded literal UUID. NEITHER city is linked to the
-- shared '2026 Texas Municipal General' (2026-05-02) row anywhere in this file —
-- McKinney's last election was 2025 (migration 100's own header comment already
-- excludes it); Richardson's 2026-05-02 ballot was a charter/bond-only special
-- election with ZERO council seats (confirmed via 2 independent sources per
-- PREFLIGHT). This is the load-bearing "wrong-row" invariant this migration must
-- never violate — enforced by the apply-script's explicit gate.
--
-- ============================================================
-- MCKINNEY (geo_id 4845744) — TWO own election rows
-- ============================================================
-- General:  'McKinney TX City General 2025'  2025-05-03
-- Runoff:   'McKinney TX City Runoff 2025'    2025-06-07
--
-- Of McKinney's 7 offices (Mayor + Council Member At-Large Place 1 + Place 2 +
-- Council Member District 1-4, per migration 088), 4 were confirmed up in the
-- 2025 cycle this session: Mayor, District 1, At-Large Place 1, and a seat cited
-- throughout PREFLIGHT/RESEARCH as "Place 3." The other 3 offices (District 2,
-- District 4, At-Large Place 2) were NOT confirmed up in 2025 and are left
-- race-less, [OPEN] per PREFLIGHT — no cycle guessed for them.
--
-- *** ASSUMPTION FLAGGED FOR ORCHESTRATOR VERIFICATION (highest-priority item) ***
-- Migration 088 (McKinney's original office seeding) never created any office
-- literally titled "Place 3" — the 7 real DB titles are exactly: 'Mayor',
-- 'Council Member At-Large Place 1', 'Council Member At-Large Place 2',
-- 'Council Member District 1'..'District 4'. PREFLIGHT/RESEARCH's "Place 3"
-- citation (Feltus defeated Warren, ~54%, May 3 2025) does not literally match
-- any of these 7 titles. This migration maps "Place 3" -> 'Council Member
-- District 3' on the reasoning that McKinney's staggered numbering (District 1
-- confirmed same session, District 3 unconfirmed either way) most plausibly
-- continues a sequential 1-4 numbering that local news sometimes shortens to
-- "Place N" regardless of district/at-large status. This mapping was NOT
-- independently re-verified against mckinneytexas.org this session (no web
-- access available to this executor) — the orchestrator MUST confirm this
-- office-title mapping (or correct it) before running Task 3. If the mapping is
-- wrong, the defensive `IF v_office_id IS NULL THEN RAISE EXCEPTION` guard below
-- makes this migration fail LOUDLY at apply time rather than silently seeding an
-- orphan race (office_id is nullable on essentials.races per migration 042) or
-- linking the wrong seat.
--
-- Sources: mckinneytexas.org/139/Elections, mckinneytexas.org/2084/2025-Runoff-Election;
-- dallasnews.com/news/elections/2025/06/07/mckinney-mayoral-council-runoff-election-results-bill-cox-scott-sanford-2025/;
-- nbcdfw.com/news/politics/lone-star-politics/mckinney-elects-new-mayor/3858560/;
-- communityimpact.com/dallas-fort-worth/mckinney/election/2025/06/07/bill-cox-is-mckinneys-next-mayor-voting-results-show/;
-- citizenportal.ai McKinney-council-certifies-June-7-runoff-Bill-Cox-Ernest-Lynch-to-be-sworn-in;
-- KERA News mckinney-election-results-mayor-city-council-2025; collincountyvotes.com/mckinney-may-2025-election-recap.
--
-- Mayor (General, May 3 2025): 4-candidate field, no majority -> runoff. Only 2
-- of the 4 filed candidates' names were sourced this session (Bill Cox, Scott
-- Sanford, the top-2 who advanced) — the other 2 candidates in the field are NOT
-- named in any cited source this session and are NOT fabricated here; the
-- General race therefore seeds only the 2 cited names, not a false "complete"
-- 4-candidate field.
--   Mayor Runoff (June 7 2025): Bill Cox defeated Scott Sanford, 52.55%.
-- WINNER LINKAGE: Bill Cox is McKinney's new mayor (an open-seat win — "McKinney
-- elects new mayor," no incumbent citation found for either candidate this
-- session) -> is_incumbent=false for both Cox and Sanford in both the general and
-- runoff race. Linked via offices.politician_id (assumes Phase-218-equivalent
-- current-officeholder seating already reflects Cox as Mayor; NOT independently
-- DB-verified this session — orchestrator to confirm before Task 3, per plan's
-- politician-linkage instruction).
--
-- At-Large Place 1 (General, May 3 2025): 5-candidate field, no majority ->
-- runoff. Only 2 of the 5 filed candidates' names were sourced this session
-- (Ernest Lynch 29.33%, Garrison 19.97% — the top-2 who advanced); the other 3
-- are NOT named in any cited source this session and are NOT fabricated here.
-- Garrison's first name was never sourced this session (surname-only citation);
-- seeded as full_name='Garrison', first_name=NULL, last_name='Garrison' — an
-- honest partial citation, not a fabricated first name.
--   At-Large Place 1 Runoff (June 7 2025): Ernest Lynch defeated Garrison,
--   certified alongside Cox (per this plan's own runoff-pairing text).
-- WINNER LINKAGE: Ernest Lynch, is_incumbent=false (no incumbency citation found
-- this session), linked via offices.politician_id in both the general and
-- runoff race (same person/photo).
--
-- District 1 (General, May 3 2025): incumbent Justin Beller, unopposed (D-03
-- single declared-elected candidate). is_incumbent=true (explicit "incumbent"
-- citation). Linked via offices.politician_id.
--
-- "Place 3" -> Council Member District 3 (General, May 3 2025): Feltus defeated
-- Warren, ~54%. Neither candidate's first name was ever sourced this session
-- (surname-only citations throughout PREFLIGHT/RESEARCH) — seeded as
-- full_name='Feltus'/'Warren', first_name=NULL, an honest partial citation, not
-- a fabricated first name. No incumbency citation found for either -> both
-- is_incumbent=false. Winner (Feltus) linked via offices.politician_id.
--
-- ============================================================
-- RICHARDSON (geo_id 4861796) — ONE own election row
-- ============================================================
-- 'Richardson TX City General 2025', 2025-05-03.
--
-- *** GEO_ID NOTE FOR ORCHESTRATOR ***
-- This phase's planning docs (219-PREFLIGHT.md/219-RESEARCH.md, both compiled
-- from a live Task-1 DB probe this session) consistently give Richardson's
-- geo_id as 4861796. The ORIGINAL Richardson seeding migrations (089, 095, 099 —
-- pre-Phase-217) instead used geo_id 4863500 (migration 088/089's own header
-- comment: "FIPS place GEOID: 4863500"). This migration trusts the
-- live-DB-probed value (4861796) as current ground truth, consistent with
-- RESEARCH's documented pattern of Phase 217 correcting several cities' stale
-- geo_ids post-initial-seed (Plano/Princeton/Van Alstyne are explicitly named
-- there; Richardson's correction, if it happened, was not explicitly logged in
-- that table). If 4861796 is wrong and the live value is still 4863500, every
-- office lookup below will find 0 rows and this migration will RAISE EXCEPTION
-- (safe, loud failure — never a silent no-op or wrong-city write). Orchestrator:
-- verify `SELECT geo_id FROM essentials.governments WHERE name ILIKE '%Richardson%' AND state='TX'`
-- before running Task 3.
--
-- Richardson's 6-councilmember + Mayor structure (per migration 089): Mayor +
-- Council Member District 1-4 (= Richardson's own "Place 1-4") + Council Member
-- Place 5 + Place 6. Of these 7 offices, 2 are confirmed/cited this session:
--
-- Mayor: Amir Omar (6,672 votes, 55.3%) defeated incumbent Bob Dubey (5,084,
-- ~41%) and Alan C. North (485, ~3%). CORRECTS RESEARCH.md's erroneous "Paul
-- Voelker won Mayor" claim — no source found this session supports a Voelker
-- win; Omar's win is independently confirmed across 3 sources. is_incumbent:
-- Omar=false (challenger, defeated the incumbent), Dubey=true (cited
-- incumbent), North=false. Winner (Omar) linked via offices.politician_id.
-- Sources: communityimpact.com/dallas-fort-worth/richardson/election/2025/05/03/amir-omar-wins-richardson-mayoral-election-unofficial-totals-show/;
-- cor.net/Home/Components/News/News/8145/; richardsontoday.com/new-mayor-council-sworn-in/.
--
-- Council Member Place 6: incumbent Arefin Shamsul (7,023 votes) defeated Lisa
-- Kupfer (4,240 votes) in a straight 2-candidate race. CORRECTS RESEARCH.md's
-- erroneous "3-way runoff (Burdette/Frederick/Shamsul)" claim — confirmed no
-- runoff occurred for Place 6 this cycle (same communityimpact.com citation).
-- is_incumbent: Shamsul=true (cited incumbent), Kupfer=false. Winner (Shamsul)
-- linked via offices.politician_id.
--
-- Places 1-5: NOT independently re-verified this session (no source found
-- reporting contested results for them beyond Mayor + Place 6) — left
-- race-less, [OPEN] per PREFLIGHT §4/§7.
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
-- General vs runoff seats use DISTINCT city-prefixed position_names ('McKinney
-- Mayor' vs 'McKinney Mayor Runoff'; 'McKinney Council Member At-Large Place 1'
-- vs '... Runoff') so they can never ON CONFLICT-collide with each other.
-- D-06 antipartisan: primary_party NULL on every race. D-07: zero inform.*
-- writes (verified by the apply-script's before/after gate). election_type for
-- the runoff row is 'special' (schema CHECK on essentials.elections has no
-- literal 'runoff' value — matches migration 187's Longview D3 runoff
-- precedent). Every office lookup is guarded by an explicit
-- `IF v_office_id IS NULL THEN RAISE EXCEPTION` check (office_id is nullable on
-- essentials.races per migration 042 — without this guard, a wrong geo_id/title
-- would silently create an orphan race instead of failing loudly).
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_mck_gen    UUID;
  v_election_mck_runoff UUID;
  v_election_rich       UUID;
  v_office_id           UUID;
  v_race                UUID;
  v_politician          UUID;
BEGIN
  -- ------------------------------------------------------------------
  -- Mint (or reuse) McKinney's own 2025-05-03 General election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level)
  VALUES ('McKinney TX City General 2025', '2025-05-03', 'TX', 'general', 'city')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_mck_gen FROM essentials.elections
   WHERE name = 'McKinney TX City General 2025' AND election_date = '2025-05-03' AND state = 'TX';

  IF v_election_mck_gen IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney TX City General 2025 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Mint (or reuse) McKinney's own 2025-06-07 Runoff election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES ('McKinney TX City Runoff 2025', '2025-06-07', 'TX', 'special', 'city', 'Runoff for Mayor and Council Member At-Large Place 1; no candidate achieved a majority in the May 3, 2025 general election.')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_mck_runoff FROM essentials.elections
   WHERE name = 'McKinney TX City Runoff 2025' AND election_date = '2025-06-07' AND state = 'TX';

  IF v_election_mck_runoff IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney TX City Runoff 2025 election row not found after mint — aborting';
  END IF;

  -- ------------------------------------------------------------------
  -- Mint (or reuse) Richardson's own 2025-05-03 General election row.
  -- ------------------------------------------------------------------
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level)
  VALUES ('Richardson TX City General 2025', '2025-05-03', 'TX', 'general', 'city')
  ON CONFLICT (name, election_date, state) DO NOTHING;

  SELECT id INTO v_election_rich FROM essentials.elections
   WHERE name = 'Richardson TX City General 2025' AND election_date = '2025-05-03' AND state = 'TX';

  IF v_election_rich IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: Richardson TX City General 2025 election row not found after mint — aborting';
  END IF;

  -- ============================================================
  -- MCKINNEY (geo_id 4845744) — General race: Mayor
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4845744' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney (4845744) Mayor office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_gen, v_office_id, 'McKinney Mayor', 1, NULL, 'General — 4-candidate field, no majority, runoff June 7 2025; only Cox/Sanford (top 2) named in sourced coverage this session')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_gen AND r.position_name = 'McKinney Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Bill Cox', 'Bill', 'Cox', false, 'active', 'dallasnews.com mckinney-mayoral-council-runoff-election-results-bill-cox-scott-sanford-2025'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Bill Cox');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Scott Sanford', 'Scott', 'Sanford', false, 'active', 'dallasnews.com mckinney-mayoral-council-runoff-election-results-bill-cox-scott-sanford-2025'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Scott Sanford');

  -- ============================================================
  -- MCKINNEY — Runoff race: Mayor Runoff
  -- ============================================================
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_runoff, v_office_id, 'McKinney Mayor Runoff', 1, NULL, 'Bill Cox defeated Scott Sanford, 52.55%, June 7 2025')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_runoff AND r.position_name = 'McKinney Mayor Runoff';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Bill Cox', 'Bill', 'Cox', false, 'active', 'dallasnews.com mckinney-mayoral-council-runoff-election-results-bill-cox-scott-sanford-2025; nbcdfw.com mckinney-elects-new-mayor; communityimpact.com bill-cox-is-mckinneys-next-mayor'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Bill Cox');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Scott Sanford', 'Scott', 'Sanford', false, 'active', 'dallasnews.com mckinney-mayoral-council-runoff-election-results-bill-cox-scott-sanford-2025'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Scott Sanford');

  -- ============================================================
  -- MCKINNEY — General race: Council Member District 1 (Beller, unopposed)
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney (4845744) Council Member District 1 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_gen, v_office_id, 'McKinney Council Member District 1', 1, NULL, 'Declared elected — incumbent Justin Beller, unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_gen AND r.position_name = 'McKinney Council Member District 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Justin Beller', 'Justin', 'Beller', true, 'active', 'mckinneytexas.org/139/Elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Justin Beller');

  -- ============================================================
  -- MCKINNEY — General race: "Place 3" -> Council Member District 3
  -- (SEE MIGRATION-HEADER ASSUMPTION NOTE — office-title mapping unconfirmed)
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney (4845744) Council Member District 3 office not found — aborting (this is the assumed mapping for PREFLIGHT''s "Place 3" citation; verify before re-running)';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_gen, v_office_id, 'McKinney Council Member District 3', 1, NULL, 'Feltus defeated Warren, ~54% (cited as "Place 3" in source coverage; mapped to District 3 — see migration header note)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_gen AND r.position_name = 'McKinney Council Member District 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Feltus', NULL, 'Feltus', false, 'active', 'mckinneytexas.org/139/Elections; KERA News mckinney-election-results-mayor-city-council-2025 (surname only sourced this session)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Feltus');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Warren', NULL, 'Warren', false, 'active', 'mckinneytexas.org/139/Elections; KERA News mckinney-election-results-mayor-city-council-2025 (surname only sourced this session)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Warren');

  -- ============================================================
  -- MCKINNEY — General race: Council Member At-Large Place 1
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4845744' AND o.title = 'Council Member At-Large Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: McKinney (4845744) Council Member At-Large Place 1 office not found — aborting';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_gen, v_office_id, 'McKinney Council Member At-Large Place 1', 1, NULL, 'General — 5-candidate field, no majority, runoff June 7 2025; only Lynch/Garrison (top 2) named in sourced coverage this session')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_gen AND r.position_name = 'McKinney Council Member At-Large Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Ernest Lynch', 'Ernest', 'Lynch', false, 'active', 'citizenportal.ai McKinney-council-certifies-June-7-runoff-Bill-Cox-Ernest-Lynch-to-be-sworn-in'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Ernest Lynch');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Garrison', NULL, 'Garrison', false, 'active', 'KERA News mckinney-election-results-mayor-city-council-2025 (surname only sourced this session)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Garrison');

  -- ============================================================
  -- MCKINNEY — Runoff race: Council Member At-Large Place 1 Runoff
  -- ============================================================
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_mck_runoff, v_office_id, 'McKinney Council Member At-Large Place 1 Runoff', 1, NULL, 'Ernest Lynch defeated Garrison, certified alongside Cox, June 7 2025')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_mck_runoff AND r.position_name = 'McKinney Council Member At-Large Place 1 Runoff';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Ernest Lynch', 'Ernest', 'Lynch', false, 'active', 'citizenportal.ai McKinney-council-certifies-June-7-runoff-Bill-Cox-Ernest-Lynch-to-be-sworn-in'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Ernest Lynch');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Garrison', NULL, 'Garrison', false, 'active', 'KERA News mckinney-election-results-mayor-city-council-2025 (surname only sourced this session)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Garrison');

  -- ============================================================
  -- RICHARDSON (geo_id 4861796) — General race: Mayor
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4861796' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: Richardson (4861796) Mayor office not found — aborting (see migration header GEO_ID NOTE — Richardson may still be seeded under stale geo_id 4863500)';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_rich, v_office_id, 'Richardson Mayor', 1, NULL, 'Amir Omar defeated incumbent Bob Dubey and Alan C. North, 6672-5084-485 (55.3%-41%-3%)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_rich AND r.position_name = 'Richardson Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Amir Omar', 'Amir', 'Omar', false, 'active', 'communityimpact.com amir-omar-wins-richardson-mayoral-election-unofficial-totals-show; cor.net News/8145; richardsontoday.com new-mayor-council-sworn-in'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Amir Omar');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Bob Dubey', 'Bob', 'Dubey', true, 'active', 'communityimpact.com amir-omar-wins-richardson-mayoral-election-unofficial-totals-show (cited incumbent)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Bob Dubey');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Alan C. North', 'Alan C.', 'North', false, 'active', 'communityimpact.com amir-omar-wins-richardson-mayoral-election-unofficial-totals-show'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Alan C. North');

  -- ============================================================
  -- RICHARDSON — General race: Council Member Place 6
  -- ============================================================
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4861796' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1395: Richardson (4861796) Council Member Place 6 office not found — aborting (see migration header GEO_ID NOTE)';
  END IF;

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_rich, v_office_id, 'Richardson Council Member Place 6', 1, NULL, 'Incumbent Arefin Shamsul defeated Lisa Kupfer, 7023-4240; straight 2-candidate race, no runoff')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_rich AND r.position_name = 'Richardson Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Arefin Shamsul', 'Arefin', 'Shamsul', true, 'active', 'communityimpact.com amir-omar-wins-richardson-mayoral-election-unofficial-totals-show (full unofficial results, cited incumbent)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Arefin Shamsul');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Lisa Kupfer', 'Lisa', 'Kupfer', false, 'active', 'communityimpact.com amir-omar-wins-richardson-mayoral-election-unofficial-totals-show (full unofficial results)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Lisa Kupfer');

  -- RICHARDSON Places 1-5: deliberately NO SQL here — not independently
  -- re-verified this session, [OPEN] per PREFLIGHT §4/§7. Documented open gap,
  -- verified by the apply-script's explicit expected-0 gate.
  --
  -- MCKINNEY District 2, District 4, At-Large Place 2: deliberately NO SQL here
  -- — not confirmed up in the 2025 cycle this session, [OPEN] per PREFLIGHT §4/§7.

END $$;

COMMIT;

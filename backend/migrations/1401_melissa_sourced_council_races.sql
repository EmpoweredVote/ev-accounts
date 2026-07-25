-- =============================================================================
-- Migration 1401: Melissa TX city-council races (sourced canvass reconcile)
-- Melissa (4847496, Collin Co)
-- (Phase 219 follow-up — operator-approved [OPEN] reconcile, 2026-07-24)
--
-- Seeds the 5 Melissa city-council races that were resolved to a REAL, cited
-- election result during the post-219 sourcing reconcile (Melissa was the one
-- zero-race city left documented-open after Phase 219 proper, because no roster
-- was sourced during execution). Evidence: Collin County Elections' official
-- machine-readable canvass exports (the canonical results data), corroborated by
-- Ballotpedia's Collin County candidate rosters. Melissa's city council is on the
-- Texas May uniform date with 3-year staggered terms; the two most-recent cycles
-- are May 3 2025 (Mayor/Place2/Place4) and May 4 2024 (Place1/Place3/Place5/6).
-- The May 2 2026 ballot was ISD/school-district only for the city (confirmed in
-- 219-PREFLIGHT.md) — NOT seeded here.
--
-- SEEDED (cited):
--   Mayor 2025          — Jay Northcut 1602 def Rajae Kennedy 230 (contested)
--   Council Member P2 2025 — Rendell Hendrickson, unopposed/declared elected
--   Council Member P4 2025 — Joseph Armstrong, unopposed/declared elected (incumbent since May 2022)
--   Council Member P1 2024 — Preston Taylor 1312 def Shannon Sweat 1100 (contested)
--   Council Member P3 2024 — Dana Conklin 1324 def Emeka Eluka 1024 (contested)
--   All 5 winners are the current offices.politician_id holders (DB-verified) —
--   linked for photo/profile carry-through; losers denormalized name-only.
--
-- LEFT [OPEN] (deliberately NOT seeded — no independently-sourced candidate name):
--   Council Member Place 5 (2024) and Place 6 (2024) — these seats are absent from
--   the county's official all-races export (a §2.053 unopposed-cancellation
--   signature), but NO cited candidate name was found (only the excluded
--   current-officeholder cross-check Ackerman/Lehr). Per the SOURCED-ONLY standard
--   they stay documented-open pending a City Secretary records request — not
--   seeded from the officeholder alone.
--
-- Sources: collincountytx.gov/Elections/election-results-archive — "May 3, 2025
-- Joint Elections All Races Export" (CSV) + "May 4, 2024 Joint Election Combined
-- Accumulated Totals" (CSV, official final) + its Statement-of-Votes-Cast PDF;
-- ballotpedia.org/Collin_County,_Texas,_elections,_2025 (+ /2024);
-- legistorm.com/person/bio/508433 (Armstrong term May 2022-). Note the unopposed
-- P2/P4 (2025) winners are corroborated by Ballotpedia's sole-candidate listing
-- (same SOURCED bar as migration 1398 Murphy Mayor / 1399 Frisco Place 1).
--
-- Idempotent: own election rows via ON CONFLICT (name, election_date, state) DO
-- NOTHING; races via ON CONFLICT (election_id, position_name) WHERE primary_party
-- IS NULL DO NOTHING; candidates via WHERE NOT EXISTS (race_id, full_name).
-- D-06 antipartisan: primary_party NULL. candidate_status='active' (winner via
-- politician_id, never a status value). Office lookups RAISE EXCEPTION on miss.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_e2025      UUID;
  v_e2024      UUID;
  v_office_id  UUID;
  v_race       UUID;
  v_politician UUID;
BEGIN
  -- Mint Melissa's own 2025-05-03 and 2024-05-04 election rows.
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES ('Melissa TX City General 2025', '2025-05-03', 'TX', 'general', 'city', 'Melissa city council May 2025 uniform-date cycle (Mayor, Place 2, Place 4)')
  ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_e2025 FROM essentials.elections WHERE name='Melissa TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_e2025 IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa 2025 election row not found after mint'; END IF;

  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description)
  VALUES ('Melissa TX City General 2024', '2024-05-04', 'TX', 'general', 'city', 'Melissa city council May 2024 uniform-date cycle (Place 1, Place 3)')
  ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_e2024 FROM essentials.elections WHERE name='Melissa TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_e2024 IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa 2024 election row not found after mint'; END IF;

  -- ===== 2025 cycle =====

  -- Mayor — Jay Northcut (1602) def Rajae Kennedy (230)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4847496' AND o.title='Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa Mayor office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_e2025, v_office_id, 'Melissa Mayor', 1, NULL, 'Northcut defeated Kennedy, 1602-230 (87.5%)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_e2025 AND r.position_name='Melissa Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Jay Northcut', 'Jay', 'Northcut', true, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export; ballotpedia.org/Jay_Northcut_(Mayor_of_Melissa,_Texas,_candidate_2025)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Jay Northcut');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Rajae Kennedy', 'Rajae', 'Kennedy', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export; ballotpedia.org/Collin_County,_Texas,_elections,_2025'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Rajae Kennedy');

  -- Place 2 — Rendell Hendrickson (unopposed, declared elected)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4847496' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa Place 2 office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_e2025, v_office_id, 'Melissa Council Member Place 2', 1, NULL, 'Declared elected — unopposed (Ballotpedia sole candidate; race cancelled per TX §2.053, absent from county canvass)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_e2025 AND r.position_name='Melissa Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Rendell Hendrickson', 'Rendell', 'Hendrickson', false, 'active', 'ballotpedia.org/Collin_County,_Texas,_elections,_2025 (sole candidate); cityofmelissa.com/202/City-Council'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Rendell Hendrickson');

  -- Place 4 — Joseph Armstrong (unopposed, declared elected; incumbent since May 2022)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4847496' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa Place 4 office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_e2025, v_office_id, 'Melissa Council Member Place 4', 1, NULL, 'Declared elected — unopposed (Ballotpedia sole candidate; incumbent since May 2022 per LegiStorm; absent from county canvass)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_e2025 AND r.position_name='Melissa Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Joseph Armstrong', 'Joseph', 'Armstrong', true, 'active', 'ballotpedia.org/Collin_County,_Texas,_elections,_2025 (sole candidate); legistorm.com/person/bio/508433 (term May 2022-)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Joseph Armstrong');

  -- ===== 2024 cycle =====

  -- Place 1 — Preston Taylor (1312) def Shannon Sweat (1100)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4847496' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa Place 1 office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_e2024, v_office_id, 'Melissa Council Member Place 1', 1, NULL, 'Taylor defeated Sweat, 1312-1100 (54.4%)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_e2024 AND r.position_name='Melissa Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Preston Taylor', 'Preston', 'Taylor', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Preston Taylor');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Shannon Sweat', 'Shannon', 'Sweat', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Shannon Sweat');

  -- Place 3 — Dana Conklin (1324) def Emeka Eluka (1024)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id
   WHERE g.geo_id='4847496' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION 'Migration 1401: Melissa Place 3 office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_e2024, v_office_id, 'Melissa Council Member Place 3', 1, NULL, 'Conklin defeated Eluka, 1324-1024 (56.4%)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_e2024 AND r.position_name='Melissa Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Dana Conklin', 'Dana', 'Conklin', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dana Conklin');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Emeka Eluka', 'Emeka', 'Eluka', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Emeka Eluka');

END $$;

COMMIT;

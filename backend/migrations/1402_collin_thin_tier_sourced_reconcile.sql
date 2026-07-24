-- =============================================================================
-- Migration 1402: Allen/Anna/Lucas/Murphy/Prosper thin-tier sourced reconcile
-- (Phase 219 follow-up — SOURCED-ONLY reconcile of inference-only [OPEN] seats)
--
-- Phase 219 plan 07 (migration 1398) was reduced to SOURCED-ONLY per operator
-- decision, leaving these 24 seats documented-[OPEN] because no election roster
-- was sourced during execution (no web tooling that session). A dedicated
-- WebSearch sourcing pass resolved all 24 from PRIMARY sources — the Collin
-- County Elections official machine-readable canvass exports (May 4 2024 + May 3
-- 2025 "all races") for contested seats, and official Town/City unopposed-
-- candidate certifications / cancellation notices for declared-elected seats.
-- Every candidate row carries its citation in the `source` column. All 24 winners
-- are the current offices.politician_id holders (DB-verified) and are linked for
-- photo/profile carry-through; losers are denormalized name-only.
--
-- Cycle corrections vs the 1398 term-date guesses (sourced): Murphy P1/P2 and Anna
-- P2/P6 are 2025 (not 2024; those cities/seats were absent from the 2024 canvass);
-- Lucas P5 is 2025 (cancelled-unopposed). Declared-elected-unopposed seats: Lucas
-- P5/P6 (2025), Allen P4/P6 (2025), all 5 Prosper seats, Murphy P2 (on-ballot
-- unopposed) — seeded as a single cited candidate per D-03.
--
-- Idempotent: own election rows via ON CONFLICT (name,election_date,state) DO
-- NOTHING; races via ON CONFLICT (election_id, position_name) WHERE primary_party
-- IS NULL DO NOTHING; candidates via WHERE NOT EXISTS. primary_party NULL (D-06);
-- candidate_status='active' (winner via politician_id). All election dates are
-- past (2024/2025) — D-02 holds. Existing races for these offices are untouched
-- (all 24 offices were race-less before this migration, DB-verified).
-- Sources: collincountytx.gov results-archive May-2024/May-2025 canvass exports;
-- prospertx.gov/DocumentCenter View/1094 (2024) + View/4327 (2025) unopposed
-- certifications; collincountyvotes.com Allen May-2025 recap; lucastexas.us 2025
-- cancellation notice + campaign-reporting filings.
-- =============================================================================

BEGIN;
DO $$
DECLARE
  v_lucas24 UUID; v_lucas25 UUID; v_murphy25 UUID; v_allen24 UUID; v_allen25 UUID; v_anna24 UUID; v_anna25 UUID; v_prosper24 UUID; v_prosper25 UUID;
  v_office_id UUID; v_race UUID; v_politician UUID;
BEGIN
-- Auto-generated body for migration 1402 (Pass-A thin-tier reconcile).
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Lucas TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_lucas24 FROM essentials.elections WHERE name='Lucas TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_lucas24 IS NULL THEN RAISE EXCEPTION '1402: Lucas TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Lucas TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_lucas25 FROM essentials.elections WHERE name='Lucas TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_lucas25 IS NULL THEN RAISE EXCEPTION '1402: Lucas TX City General 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Murphy TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_murphy25 FROM essentials.elections WHERE name='Murphy TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_murphy25 IS NULL THEN RAISE EXCEPTION '1402: Murphy TX City General 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Allen TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_allen24 FROM essentials.elections WHERE name='Allen TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_allen24 IS NULL THEN RAISE EXCEPTION '1402: Allen TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Allen TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_allen25 FROM essentials.elections WHERE name='Allen TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_allen25 IS NULL THEN RAISE EXCEPTION '1402: Allen TX City General 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Anna TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_anna24 FROM essentials.elections WHERE name='Anna TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_anna24 IS NULL THEN RAISE EXCEPTION '1402: Anna TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Anna TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_anna25 FROM essentials.elections WHERE name='Anna TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_anna25 IS NULL THEN RAISE EXCEPTION '1402: Anna TX City General 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Prosper TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_prosper24 FROM essentials.elections WHERE name='Prosper TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_prosper24 IS NULL THEN RAISE EXCEPTION '1402: Prosper TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Prosper TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_prosper25 FROM essentials.elections WHERE name='Prosper TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_prosper25 IS NULL THEN RAISE EXCEPTION '1402: Prosper TX City General 2025 row missing'; END IF;

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4845012' AND o.title='Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4845012/Mayor not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lucas24, v_office_id, 'Lucas Mayor', 1, NULL, 'Kuykendall defeated Peele, 767-738') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lucas24 AND r.position_name='Lucas Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Dusty Kuykendall','Dusty','Kuykendall', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dusty Kuykendall');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Kathleen A. Peele','Kathleen','Peele', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Kathleen A. Peele');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4845012' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4845012/Council Member Place 3 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lucas24, v_office_id, 'Lucas Council Member Place 3', 1, NULL, 'Bierman defeated Syed, 1189-248') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lucas24 AND r.position_name='Lucas Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Chris Bierman','Chris','Bierman', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Chris Bierman');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Suhail Syed','Suhail','Syed', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Suhail Syed');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4845012' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4845012/Council Member Place 4 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lucas24, v_office_id, 'Lucas Council Member Place 4', 1, NULL, 'Lawrence defeated Williams, 1028-363') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lucas24 AND r.position_name='Lucas Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Phil Lawrence','Phil','Lawrence', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Phil Lawrence');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Joe Williams','Joe','Williams', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Joe Williams');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4845012' AND o.title='Council Member Place 5';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4845012/Council Member Place 5 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lucas25, v_office_id, 'Lucas Council Member Place 5', 1, NULL, 'Declared elected — unopposed (May 2025 election cancelled)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lucas25 AND r.position_name='Lucas Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Debbie Fisher','Debbie','Fisher', false, 'active', 'lucastexas.us March 2025 election-cancelled notice (Seats 5 & 6 unopposed); lucastexas.us/179/Campaign-Reporting' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Debbie Fisher');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4845012' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4845012/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lucas25, v_office_id, 'Lucas Council Member Place 6', 1, NULL, 'Declared elected — unopposed re-election, May 2025 (won contested 2024 special 945-408)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lucas25 AND r.position_name='Lucas Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Neil Peterson','Neil','Peterson', false, 'active', 'lucastexas.us March 2025 election-cancelled notice (Seats 5 & 6 unopposed); lucastexas.us/179/Campaign-Reporting' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Neil Peterson');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4850100' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4850100/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_murphy25, v_office_id, 'Murphy Council Member Place 1', 1, NULL, 'Abraham defeated Khan, 2069-946') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_murphy25 AND r.position_name='Murphy Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Elizabeth Abraham','Elizabeth','Abraham', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Elizabeth Abraham');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Nadeem A. Khan','Nadeem','Khan', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Nadeem A. Khan');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4850100' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4850100/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_murphy25, v_office_id, 'Murphy Council Member Place 2', 1, NULL, 'Declared elected — unopposed (1876 votes, no opponent)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_murphy25 AND r.position_name='Murphy Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Scott Smith','Scott','Smith', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Scott Smith');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4850100' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4850100/Council Member Place 4 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_murphy25, v_office_id, 'Murphy Council Member Place 4', 1, NULL, 'Oltmann defeated Stout, 1941-599') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_murphy25 AND r.position_name='Murphy Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Ken Oltmann','Ken','Oltmann', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Ken Oltmann');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Chris Stout','Chris','Stout', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Chris Stout');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4850100' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4850100/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_murphy25, v_office_id, 'Murphy Council Member Place 6', 1, NULL, 'Butler defeated Rasul, 2339-636') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_murphy25 AND r.position_name='Murphy Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Jené Butler','Jené','Butler', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Jené Butler');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Qasim Rasul','Qasim','Rasul', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Qasim Rasul');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4801924' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4801924/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_allen24, v_office_id, 'Allen Council Member Place 1', 1, NULL, 'Schaeffer 3475 def Scott 1827, Razvi 917') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_allen24 AND r.position_name='Allen Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Michael Schaeffer','Michael','Schaeffer', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Michael Schaeffer');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Dave Scott','Dave','Scott', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dave Scott');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Esrar Razvi','Esrar','Razvi', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Esrar Razvi');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4801924' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4801924/Council Member Place 3 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_allen24, v_office_id, 'Allen Council Member Place 3', 1, NULL, 'Cook 2916 def Cornette 2201, Hamid 1097') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_allen24 AND r.position_name='Allen Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Ken Cook','Ken','Cook', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Ken Cook');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Dave Cornette','Dave','Cornette', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dave Cornette');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Saad Hamid','Saad','Hamid', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Saad Hamid');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4801924' AND o.title='Council Member Place 5';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4801924/Council Member Place 5 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_allen24, v_office_id, 'Allen Council Member Place 5', 1, NULL, 'Clemencich 3027 def Shafer 1967, Naseh 993, Merrill 221') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_allen24 AND r.position_name='Allen Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Carl Clemencich','Carl','Clemencich', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Carl Clemencich');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Dave Shafer','Dave','Shafer', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dave Shafer');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Zeeshan Naseh','Zeeshan','Naseh', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Zeeshan Naseh');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Walter Merrill','Walter','Merrill', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Walter Merrill');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4801924' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4801924/Council Member Place 4 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_allen25, v_office_id, 'Allen Council Member Place 4', 1, NULL, 'Declared elected — unopposed (May 2025 election cancelled)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_allen25 AND r.position_name='Allen Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Amy Gnadt','Amy','Gnadt', false, 'active', 'collincountyvotes.com/allen-may-2025-local-election-recap (Places 4 & 6 uncontested, declared elected)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Amy Gnadt');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4801924' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4801924/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_allen25, v_office_id, 'Allen Council Member Place 6', 1, NULL, 'Declared elected — unopposed (May 2025 election cancelled)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_allen25 AND r.position_name='Allen Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Ben Trahan','Ben','Trahan', false, 'active', 'collincountyvotes.com/allen-may-2025-local-election-recap (Places 4 & 6 uncontested, declared elected)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Ben Trahan');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4803300' AND o.title='Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4803300/Mayor not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_anna24, v_office_id, 'Anna Mayor', 1, NULL, 'Cain defeated Atchley, 913-660') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_anna24 AND r.position_name='Anna Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Pete Cain','Pete','Cain', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Pete Cain');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Randy Atchley','Randy','Atchley', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Randy Atchley');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4803300' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4803300/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_anna24, v_office_id, 'Anna Council Member Place 1', 1, NULL, 'Toten defeated Heath, 887-598') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_anna24 AND r.position_name='Anna Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Kevin Toten','Kevin','Toten', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Kevin Toten');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Bryan Heath','Bryan','Heath', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Bryan Heath');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4803300' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4803300/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_anna25, v_office_id, 'Anna Council Member Place 2', 1, NULL, 'Bryan won (460 votes) in a 4-way field') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_anna25 AND r.position_name='Anna Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Nathan Bryan','Nathan','Bryan', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Nathan Bryan');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Allison Inesta','Allison','Inesta', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Allison Inesta');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Nichole Hunt','Nichole','Hunt', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Nichole Hunt');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Hugh F. Heath','Hugh','Heath', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Hugh F. Heath');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4803300' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4803300/Council Member Place 4 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_anna25, v_office_id, 'Anna Council Member Place 4', 1, NULL, 'Herndon defeated Miller, 741-255') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_anna25 AND r.position_name='Anna Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Kelly Patterson-Herndon','Kelly','Patterson-Herndon', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Kelly Patterson-Herndon');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Lee Miller','Lee','Miller', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Lee Miller');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4803300' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4803300/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_anna25, v_office_id, 'Anna Council Member Place 6', 1, NULL, 'Singh defeated Atchley, 741-255') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_anna25 AND r.position_name='Anna Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Manny Singh','Manny','Singh', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Manny Singh');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Randy Atchley','Randy','Atchley', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Randy Atchley');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4859696' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4859696/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_prosper24, v_office_id, 'Prosper Council Member Place 2', 1, NULL, 'Declared elected — unopposed (Feb 2024 Town certification)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_prosper24 AND r.position_name='Prosper Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Craig Andres','Craig','Andres', false, 'active', 'prospertx.gov/DocumentCenter/View/1094 (Town Secretary Feb-2024 Certification of Unopposed Candidates)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Craig Andres');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4859696' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4859696/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_prosper24, v_office_id, 'Prosper Council Member Place 6', 1, NULL, 'Declared elected — unopposed (Feb 2024 Town certification)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_prosper24 AND r.position_name='Prosper Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Cameron Reeves','Cameron','Reeves', false, 'active', 'prospertx.gov/DocumentCenter/View/1094 (Town Secretary Feb-2024 Certification of Unopposed Candidates)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Cameron Reeves');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4859696' AND o.title='Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4859696/Mayor not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_prosper25, v_office_id, 'Prosper Mayor', 1, NULL, 'Declared elected — unopposed (Feb 2025 Town certification)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_prosper25 AND r.position_name='Prosper Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'David F. Bristol','David','Bristol', false, 'active', 'prospertx.gov/DocumentCenter/View/4327 (Town Secretary Feb-2025 Certification of Unopposed Candidates)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='David F. Bristol');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4859696' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4859696/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_prosper25, v_office_id, 'Prosper Council Member Place 1', 1, NULL, 'Declared elected — unopposed (Feb 2025 Town certification)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_prosper25 AND r.position_name='Prosper Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Marcus E. Ray','Marcus','Ray', false, 'active', 'prospertx.gov/DocumentCenter/View/4327 (Town Secretary Feb-2025 Certification of Unopposed Candidates)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Marcus E. Ray');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4859696' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1402: office 4859696/Council Member Place 4 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_prosper25, v_office_id, 'Prosper Council Member Place 4', 1, NULL, 'Declared elected — unopposed (Feb 2025 Town certification)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_prosper25 AND r.position_name='Prosper Council Member Place 4';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Chris Kern','Chris','Kern', false, 'active', 'prospertx.gov/DocumentCenter/View/4327 (Town Secretary Feb-2025 Certification of Unopposed Candidates)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Chris Kern');

END $$;
COMMIT;

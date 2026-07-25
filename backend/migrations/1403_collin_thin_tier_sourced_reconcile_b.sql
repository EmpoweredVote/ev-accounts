-- =============================================================================
-- Migration 1403: Celina/Frisco/Lowry Crossing thin-tier sourced reconcile
-- (Phase 219 follow-up — SOURCED-ONLY reconcile of inference-only [OPEN] seats)
--
-- Sources the remaining 1399 [OPEN] seats that were resolvable to a REAL cited
-- election from PRIMARY records (Collin County official canvass CSV/xlsx/PDF
-- exports for May 2024, May 2025, June 2025 runoff, and Nov 2025). Every candidate
-- row carries its citation. Winners are the current offices.politician_id holders
-- (DB-verified) and linked — EXCEPT Frisco Place 4 (see below). 14 races.
--
-- SEEDED:
--   Celina P2/P3 (2024 contested), P1 (2025 contested), P6 (2025 sole-candidate);
--   Frisco P3 (2024 contested), P2 (June-2025 runoff, Thakur), P4 (June-2025 runoff);
--   Lowry Crossing Mayor + Places 1/2/3/5/6/7 (Nov-4-2025; the county models these
--   as 2-seat Wards 1/2/3, each uncontested — seeded as declared-elected per seat).
--
-- FRISCO PLACE 4 — DATA CORRECTION FLAG: the official Collin County June-7-2025
-- runoff canvass (double-verified xlsx + official-final PDF) shows GOPAL PONANGI
-- won 53.89%-46.11% over Jared Elad. The DB currently seats Jared Elad (the LOSER)
-- as Place 4's officeholder. This migration seeds the RACE correctly (Ponangi
-- winner name-only; Elad loser linked to his existing politician_id) but does NOT
-- change offices.politician_id — the officeholder seating correction (reseat
-- Ponangi, retire Elad) is surfaced to the operator, not auto-applied.
--
-- NOT seeded here (documented [OPEN], honest gaps):
--   Parker P1/P2/P4 — sourced (2025-05-03 at-large: Bogdan/Sharpe/Halbert won top-3
--     of 6) but Parker uses a single vote-for-N at-large contest that does not map
--     onto the per-Place office model without creating confusing duplicate at-large
--     data; deferred rather than mis-modeled.
--   Fairview Mayor/Seat1/Seat3/Seat5 — sourcing too weak for the SOURCED-ONLY bar
--     (canvass-absence + LegiStorm term-start dates, no primary cancellation/
--     certification document); needs a Town Secretary records request.
--
-- Idempotent (ON CONFLICT / WHERE NOT EXISTS). primary_party NULL (D-06);
-- candidate_status='active'. All dates past (D-02). Existing races untouched.
-- =============================================================================

BEGIN;
DO $$
DECLARE
  v_celina24 UUID; v_celina25 UUID; v_frisco24 UUID; v_friscoRun25 UUID; v_lowry25 UUID;
  v_office_id UUID; v_race UUID; v_politician UUID;
BEGIN
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Celina TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_celina24 FROM essentials.elections WHERE name='Celina TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_celina24 IS NULL THEN RAISE EXCEPTION '1403: Celina TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Celina TX City General 2025','2025-05-03','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_celina25 FROM essentials.elections WHERE name='Celina TX City General 2025' AND election_date='2025-05-03' AND state='TX';
  IF v_celina25 IS NULL THEN RAISE EXCEPTION '1403: Celina TX City General 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Frisco TX City General 2024','2024-05-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_frisco24 FROM essentials.elections WHERE name='Frisco TX City General 2024' AND election_date='2024-05-04' AND state='TX';
  IF v_frisco24 IS NULL THEN RAISE EXCEPTION '1403: Frisco TX City General 2024 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Frisco TX City Runoff 2025','2025-06-07','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_friscoRun25 FROM essentials.elections WHERE name='Frisco TX City Runoff 2025' AND election_date='2025-06-07' AND state='TX';
  IF v_friscoRun25 IS NULL THEN RAISE EXCEPTION '1403: Frisco TX City Runoff 2025 row missing'; END IF;
  INSERT INTO essentials.elections (name, election_date, state, election_type, jurisdiction_level, description) VALUES ('Lowry Crossing TX City General 2025','2025-11-04','TX','general','city','Sourced canvass reconcile (Phase 219 follow-up)') ON CONFLICT (name, election_date, state) DO NOTHING;
  SELECT id INTO v_lowry25 FROM essentials.elections WHERE name='Lowry Crossing TX City General 2025' AND election_date='2025-11-04' AND state='TX';
  IF v_lowry25 IS NULL THEN RAISE EXCEPTION '1403: Lowry Crossing TX City General 2025 row missing'; END IF;

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4813684' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4813684/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_celina24, v_office_id, 'Celina Council Member Place 2', 1, NULL, 'Cawlfield defeated Hogue, 1057-472') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_celina24 AND r.position_name='Celina Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Eddie Cawlfield','Eddie','Cawlfield', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Eddie Cawlfield');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'David Hogue','David','Hogue', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='David Hogue');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4813684' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4813684/Council Member Place 3 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_celina24, v_office_id, 'Celina Council Member Place 3', 1, NULL, 'Hopkins 1029 def Pace 426, Porcher 93') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_celina24 AND r.position_name='Celina Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Andy Hopkins','Andy','Hopkins', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Andy Hopkins');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Ghentry Pace','Ghentry','Pace', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Ghentry Pace');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Julissa Casas Porcher','Julissa','Porcher', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Julissa Casas Porcher');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4813684' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4813684/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_celina25, v_office_id, 'Celina Council Member Place 1', 1, NULL, 'Ferguson defeated Allan, 983-854') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_celina25 AND r.position_name='Celina Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Philip Ferguson','Philip','Ferguson', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Philip Ferguson');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Dorothy Allan','Dorothy','Allan', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Dorothy Allan');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4813684' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4813684/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_celina25, v_office_id, 'Celina Council Member Place 6', 1, NULL, 'Declared elected — sole candidate on ballot (1417 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_celina25 AND r.position_name='Celina Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Brandon Grumbles','Brandon','Grumbles', false, 'active', 'collincountytx.gov May-3-2025 Joint Elections All Races Export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Brandon Grumbles');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4827684' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4827684/Council Member Place 3 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_frisco24, v_office_id, 'Frisco Council Member Place 3', 1, NULL, 'Pelham defeated Redmond, 4496-2091') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_frisco24 AND r.position_name='Frisco Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Angelia Pelham','Angelia','Pelham', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Angelia Pelham');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'John Redmond','John','Redmond', false, 'active', 'collincountytx.gov May-4-2024 Joint Election Combined Accumulated Totals (official final)' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='John Redmond');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4827684' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4827684/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_friscoRun25, v_office_id, 'Frisco Council Member Place 2 Runoff', 1, NULL, 'Thakur defeated Meinershagen in June-7-2025 runoff, 3676-3322 (52.53%); first round 2025-05-03 was a 3-way') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_friscoRun25 AND r.position_name='Frisco Council Member Place 2 Runoff';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Burt Thakur','Burt','Thakur', false, 'active', 'collincountytx.gov June-7-2025 Runoff official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Burt Thakur');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Tammy Meinershagen','Tammy','Meinershagen', false, 'active', 'collincountytx.gov June-7-2025 Runoff official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Tammy Meinershagen');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Mayor';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Mayor not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Mayor', 1, NULL, 'Kelly defeated Cooper, 210-176 (54.40%)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Pat Kelly','Pat','Kelly', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Pat Kelly');
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Sally Cooper','Sally','Cooper', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Sally Cooper');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 1';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 1 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 1', 1, NULL, 'Declared elected — Ward 1 (2-seat ward), uncontested (51 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Scott Pitchure','Scott','Pitchure', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Scott Pitchure');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 5';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 5 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 5', 1, NULL, 'Declared elected — Ward 1 (2-seat ward), uncontested (54 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Chris Madrid','Chris','Madrid', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Chris Madrid');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 2';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 2 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 2', 1, NULL, 'Declared elected — Ward 2 (2-seat ward), uncontested (83 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Tammy Hodges','Tammy','Hodges', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Tammy Hodges');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 6';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 6 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 6', 1, NULL, 'Declared elected — Ward 2 (2-seat ward), uncontested (57 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Agur Rios','Agur','Rios', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Agur Rios');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 3';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 3 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 3', 1, NULL, 'Declared elected — Ward 3 (2-seat ward), uncontested (105 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Eusebio "Joe" Trujillo III','Eusebio','Trujillo', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Eusebio "Joe" Trujillo III');

  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4844308' AND o.title='Council Member Place 7';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: office 4844308/Council Member Place 7 not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_lowry25, v_office_id, 'Lowry Crossing Council Member Place 7', 1, NULL, 'Declared elected — Ward 3 (2-seat ward), uncontested (60 votes)') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_lowry25 AND r.position_name='Lowry Crossing Council Member Place 7';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Cindy Cash','Cindy','Cash', false, 'active', 'collincountytx.gov November-4-2025 official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Cindy Cash');

  -- Frisco Council Member Place 4 Runoff (2025-06-07): Ponangi defeated Elad. DB officeholder still Elad (loser) — seating correction flagged to operator.
  SELECT o.id INTO v_office_id FROM essentials.offices o JOIN essentials.chambers ch ON ch.id=o.chamber_id JOIN essentials.governments g ON g.id=ch.government_id WHERE g.geo_id='4827684' AND o.title='Council Member Place 4';
  IF v_office_id IS NULL THEN RAISE EXCEPTION '1403: Frisco Place 4 office not found'; END IF;
  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description) VALUES (v_friscoRun25, v_office_id, 'Frisco Council Member Place 4 Runoff', 1, NULL, 'Gopal Ponangi defeated Jared Elad in June-7-2025 runoff, 3826-3274 (53.89%); first round 2025-05-03 was a 5-way. NOTE: DB officeholder still shows Elad (the loser) — seating correction flagged.') ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;
  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id=v_friscoRun25 AND r.position_name='Frisco Council Member Place 4 Runoff';
  -- winner Ponangi: no politician row exists (not the seated holder) -> name-only
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, 'Gopal Ponangi','Gopal','Ponangi', false, 'active', 'collincountytx.gov June-7-2025 Runoff official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Gopal Ponangi');
  -- loser Elad: link to his existing politician_id (he is the current -- though incorrect -- officeholder)
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id=v_office_id;
  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source) SELECT v_race, v_politician, 'Jared Elad','Jared','Elad', true, 'active', 'collincountytx.gov June-7-2025 Runoff official-final summary + all-races xlsx export' WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id=v_race AND rc.full_name='Jared Elad');

END $$;
COMMIT;

-- CA_0123_seed_in_2026_statewide_exec_races.sql
-- Indiana 2026 general: the three midterm statewide executive offices every Indiana voter
-- (Monroe County included) sees on Nov 3, 2026 — Secretary of State, State Comptroller
-- (Auditor of State), and Treasurer of State.
--
-- Extends the existing 'IN 2026 Statewide General' election (2026-11-03), which until now
-- held ONLY the 9 U.S. House races. These three offices were entirely absent.
--
-- ADDS 3 RACES / 9 CANDIDATES:
--   Secretary of State              Max Engling, Beau Bayh, Lauri A. Shillings, Greg Ballard
--   Comptroller (Auditor of State)  Elise Nieshalla (inc), Jessica Bailey, John Schick
--   Treasurer of State              Daniel Elliott (inc), Coumba Kebe
--
-- MODEL — STATE_EXEC office-bound races, like CO 2026 general (migration 1848); NOT
-- office-less. A race with a NULL office_id never resolves to a district and is invisible
-- to address lookup (the CA office-less 'Governor' race is exactly that latent bug). Each
-- office hangs off a STATE_EXEC district with geo_id '18' (the Indiana statewide geofence),
-- so any in-Indiana address matches it.
--
-- OFFICES — Secretary of State and Treasurer already exist on geofenced ('18') STATE_EXEC
-- districts and are reused. Comptroller existed only on a non-geofenced (empty geo_id)
-- district, so this creates a geofenced 'Indiana Comptroller' district + office to match
-- the SoS/Treasurer pattern.
--
-- PARTY IS NOT STORED PER CANDIDATE (antipartisan invariant). primary_party is NULL on a
-- general race; the certified list carries party for all 9 and it is discarded on purpose.
--
-- INCUMBENT LINKING — the two sitting officials on the ballot (Nieshalla, Elliott) link to
-- their existing politician rows by politician_id, so their profiles/photos attach via the
-- race_candidate_mirror_data trigger. Challengers stay politician_id NULL (never name-matched).
--
-- OCCUPANCY — this seeds the BALLOT only. It does not seat holders on the new Comptroller
-- office (office_terms); statewide-exec occupancy is a separate pre-existing gap. No
-- offices.politician_id is written (that column was dropped in migration 1463).
--
-- SOURCE — The Indiana Citizen 2026 general candidate list (indianacitizen.org, updated
-- 2026-08-12; mirrors the IN SoS Election Division list), cross-checked against Ballotpedia
-- and Wikipedia; June-2026 party-convention nominees. Retrieved 2026-09-21. EXCLUDES one
-- unconfirmed SoS "Socialist Party" name and a certified write-in (write-ins are not printed
-- on the ballot).
--
-- IDEMPOTENCY — district guards on (district_type,state,label); office on (district,title);
-- races on (election_id,position_name); candidates on (race_id,lower(full_name)). No unique
-- indexes back these, so NOT EXISTS, never ON CONFLICT.

BEGIN;

-- ─── Comptroller: geofenced STATE_EXEC district + office (SoS/Treasurer already exist) ───
INSERT INTO essentials.districts (district_type, state, geo_id, label, mtfcc, district_id, ocd_id)
SELECT 'STATE_EXEC', 'IN', '18', 'Indiana Comptroller', '', '', 'ocd-division/country:us/state:in'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type='STATE_EXEC' AND state='IN' AND label='Indiana Comptroller'
);

INSERT INTO essentials.offices
  (title, district_id, role_canonical, representing_state, chamber_id,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT 'Comptroller', d.id, 'comptroller', 'IN', 'c5f568d4-f295-46c4-ad91-dcbba493eab2'::uuid,
       false, false, false
FROM essentials.districts d
WHERE d.district_type='STATE_EXEC' AND d.state='IN' AND d.label='Indiana Comptroller'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title='Comptroller'
  );

-- ─── Races (primary_party NULL: general election) ───────────────────────────────────────
CREATE TEMP TABLE in_exec_race_seed (position_name text, exec_district text, office_title text)
  ON COMMIT DROP;
INSERT INTO in_exec_race_seed VALUES
  ('Secretary of State',             'Indiana Secretary of State', 'Secretary of State'),
  ('Comptroller (Auditor of State)', 'Indiana Comptroller',        'Comptroller'),
  ('Treasurer of State',             'Indiana Treasurer',          'Treasurer');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid, o.id, s.position_name, NULL, 1
FROM in_exec_race_seed s
JOIN essentials.districts d
  ON d.label = s.exec_district AND d.district_type = 'STATE_EXEC' AND d.state = 'IN'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.office_title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
    AND r.position_name = s.position_name
);

-- ─── Candidates ─────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE in_exec_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO in_exec_cand_seed VALUES
  ('Secretary of State',             'Max Engling',        'Max',    'Engling',   false, NULL::uuid),
  ('Secretary of State',             'Beau Bayh',          'Beau',   'Bayh',      false, NULL::uuid),
  ('Secretary of State',             'Lauri A. Shillings', 'Lauri',  'Shillings', false, NULL::uuid),
  ('Secretary of State',             'Greg Ballard',       'Greg',   'Ballard',   false, NULL::uuid),
  ('Comptroller (Auditor of State)', 'Elise Nieshalla',    'Elise',  'Nieshalla', true,  'b1e0cfeb-326d-4985-95a1-52e0f458f6bd'::uuid),
  ('Comptroller (Auditor of State)', 'Jessica Bailey',     'Jessica','Bailey',    false, NULL::uuid),
  ('Comptroller (Auditor of State)', 'John Schick',        'John',   'Schick',    false, NULL::uuid),
  ('Treasurer of State',             'Daniel Elliott',     'Daniel', 'Elliott',   true,  '085e88aa-edfd-435e-90bb-d84c5912efde'::uuid),
  ('Treasurer of State',             'Coumba Kebe',        'Coumba', 'Kebe',      false, NULL::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'The Indiana Citizen 2026 general candidate list (indianacitizen.org, updated 2026-08-12; mirrors IN SoS Election Division), cross-checked vs Ballotpedia/Wikipedia; June-2026 convention nominees. Retrieved 2026-09-21.'
FROM in_exec_cand_seed cs
JOIN essentials.races r
  ON r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
 AND r.position_name = cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_dup int; v_office int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races
   WHERE election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND position_name IN ('Secretary of State','Comptroller (Auditor of State)','Treasurer of State');

  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND r.position_name IN ('Secretary of State','Comptroller (Auditor of State)','Treasurer of State');

  -- 🔴 A race with a NULL office_id never resolves to a district — invisible to address lookup.
  SELECT count(*) INTO v_orphan FROM essentials.races
   WHERE election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND position_name IN ('Secretary of State','Comptroller (Auditor of State)','Treasurer of State')
     AND office_id IS NULL;

  -- Antipartisan: a general race never carries a party.
  SELECT count(*) INTO v_party FROM essentials.races
   WHERE election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
     AND position_name IN ('Secretary of State','Comptroller (Auditor of State)','Treasurer of State')
     AND primary_party IS NOT NULL;

  -- Comptroller office is geofenced (geo_id '18'), or an Indiana address never matches it.
  SELECT count(*) INTO v_office
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.title = 'Comptroller' AND d.label = 'Indiana Comptroller'
     AND d.district_type = 'STATE_EXEC' AND d.geo_id = '18';

  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n
      FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
     WHERE r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c'::uuid
       AND r.position_name IN ('Secretary of State','Comptroller (Auditor of State)','Treasurer of State')
     GROUP BY 1,2 HAVING count(*) > 1) x;

  IF v_races  <> 3 THEN RAISE EXCEPTION 'IN statewide-exec races: expected 3, got %', v_races; END IF;
  IF v_cands  <> 9 THEN RAISE EXCEPTION 'IN statewide-exec candidates: expected 9, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% race(s) with NULL office_id — invisible to address lookup', v_orphan; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% general race(s) carry primary_party', v_party; END IF;
  IF v_office <> 1 THEN RAISE EXCEPTION 'geofenced Comptroller office: expected 1, got %', v_office; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;

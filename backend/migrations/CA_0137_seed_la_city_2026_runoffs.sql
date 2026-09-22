-- CA_0137_seed_la_city_2026_runoffs.sql
-- Seed the Los Angeles CITY offices that went to a November runoff onto '2026 LA County
-- General' (the election object the app already uses for LA city races — the Mayor runoff
-- Bass vs Raman lives there).
--
-- LA city offices are nonpartisan top-two: a June-primary candidate who clears 50% is elected
-- outright (no November race); otherwise the top two advance to a November runoff. Reading the
-- certified June 2 2026 results already loaded on the primary races:
--   Mayor           Bass vs Raman         -> runoff  (ALREADY seeded on the general; not here)
--   City Attorney   McKinney vs Roy       -> runoff  (incumbent Feldstein Soto lost)   SEED
--   Controller      Mejia                 -> WON outright                              (skip)
--   Council Dist 3  Girvan vs Gaspar      -> runoff  (Blumenfield termed out)          SEED
--   Council Dist 9  Mazariegos vs Ugarte  -> runoff  (Price termed out)               SEED
--   Council Dist 1/5/7/11/13/15           -> WON outright                              (skip)
-- Even-numbered council seats are not up until 2028.
--
-- SEEDS 3 RACES / 6 CANDIDATES, reusing the existing geofenced city offices (City Attorney on
-- the Los Angeles city polygon geo_id '0644000'; Council 3 and 9 on their council-district
-- polygons). Nonpartisan -> primary_party NULL; party never stored on candidates. All six
-- advancing candidates already exist as politician rows (they ran in the June primary) and are
-- linked; none is an incumbent (the sitting officeholders either lost or were termed out).
--
-- No Part B (statewide-fallback) leak: LOCAL_EXEC / LOCAL are not statewide district types and
-- every race keeps a non-null office_id, so these are reached only via the Part A geofence match.
--
-- SOURCE: Los Angeles City Clerk / LA County Registrar-Recorder, June 2 2026 Primary Nominating
-- Election official results (the two candidates advancing to the Nov 3 2026 runoff for each seat
-- with no June majority winner). Retrieved 2026-09-22.
--
-- IDEMPOTENCY: races on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── Races (reuse existing city offices; primary_party NULL) ─────────────────────────────
CREATE TEMP TABLE lac_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO lac_race_seed VALUES
  ('Los Angeles City Attorney',            '5a873c59-72ac-488f-8b2c-44dfd04d065c'),
  ('Los Angeles City Council District 3',  '9eb3aa2a-8316-48fc-9385-60de9de476b6'),
  ('Los Angeles City Council District 9',  'b90452f3-360f-4e79-af3a-a43c1d30f754');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, s.office_id, s.position_name, NULL, 1
FROM lac_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (the two advancing per seat; all already have politician rows) ───────────
CREATE TEMP TABLE lac_cand_seed
  (position_name text, full_name text, first_name text, last_name text, politician_id uuid) ON COMMIT DROP;
INSERT INTO lac_cand_seed VALUES
  ('Los Angeles City Attorney','John McKinney','John','McKinney','6cd2e87b-7366-429a-a049-990751bd647f'),
  ('Los Angeles City Attorney','Marissa Roy','Marissa','Roy','7157dd95-0f1b-4e05-bd4f-39317345b47c'),
  ('Los Angeles City Council District 3','Barri Worth Girvan','Barri','Girvan','2cea762f-17c0-42a4-a83f-678a2941c8c9'),
  ('Los Angeles City Council District 3','Timothy Gaspar','Timothy','Gaspar','4632aaf1-6667-4e41-9763-c8b56ca7e702'),
  ('Los Angeles City Council District 9','Estuardo Mazariegos','Estuardo','Mazariegos','92876cb7-9905-4be7-b349-2a4a4ff39846'),
  ('Los Angeles City Council District 9','Jose Ugarte','Jose','Ugarte','a25fea2b-2328-42d7-bb78-5b134a469af1');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, false, 'active',
       'Los Angeles City Clerk / LA County Registrar-Recorder, June 2 2026 Primary Nominating Election official results (top-two advancing to the Nov 3 2026 runoff). Retrieved 2026-09-22.'
FROM lac_cand_seed cs
JOIN essentials.races r
  ON r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_badgeo int; v_dup int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races r JOIN lac_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN lac_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN lac_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN lac_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.primary_party IS NOT NULL;
  SELECT count(*) INTO v_badgeo FROM essentials.races r JOIN lac_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc=d.mtfcc);
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN lac_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 3 THEN RAISE EXCEPTION 'LA city races: expected 3, got %', v_races; END IF;
  IF v_cands  <> 6 THEN RAISE EXCEPTION 'LA city candidates: expected 6, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% LA city race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% LA city race(s) carry primary_party', v_party; END IF;
  IF v_badgeo <> 0 THEN RAISE EXCEPTION '% LA city race(s) not resolvable to a geofence', v_badgeo; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
  RAISE NOTICE 'CA_0137 applied: % races, % candidates', v_races, v_cands;
END $$;

COMMIT;

-- CA_0135_seed_la_superior_court_runoffs_2026.sql
-- Seed the LA County Superior Court judge RUNOFFS onto '2026 LA County General'.
--
-- CA judicial elections are top-two + majority-outright: a June-primary candidate who
-- clears 50% is elected outright (no November race); otherwise the top two advance to a
-- November runoff. Of the 15 LA Superior Court seats on the June 2 2026 ballot, 11 were
-- decided in June (majority winner or sole candidate) and 4 go to a November runoff. Only
-- the 4 runoffs belong on the general ballot; the 11 outright wins must NOT be seeded.
--
-- (Sibling finding, no action here: LA County Assessor (Prang 57.7%), Supervisor Dist 1
-- (Durazo 60.6%) and Dist 3 (Horvath ~63%) all won outright in June — correctly absent
-- from the November ballot. Only the Sheriff race went to a runoff and is already seeded.)
--
-- SEEDS 4 RACES / 8 CANDIDATES. LA Superior Court judges are elected county-wide, so all
-- four offices are created on the existing geofenced Los Angeles County district
-- (geo_id '06037', mtfcc G4020 — the same district the Sheriff/Assessor/DA offices use).
-- Nonpartisan → primary_party NULL; party never stored on candidates. None of the eight
-- runoff candidates is an incumbent (the incumbents who ran were re-elected outright in
-- June), so every candidate is politician_id NULL / is_incumbent false.
--   Office No. 64   Maria Ghobadi (44.06%) · Rhonda A. Haymon (42.14%)
--   Office No. 65   Justin Allen Clayton (36.68%) · Anna Slotky (29.88%)
--   Office No. 87   Anthony (A.J.) Bayne (42.04%) · David DeJute (31.30%)
--   Office No. 131  Donna Tryfman (37.32%) · David Ross (33.23%)
--
-- No Part B (statewide-fallback) leak: COUNTY is not a statewide district type and every
-- race keeps a non-null office_id, so these are reached only via the Part A geofence match.
--
-- SOURCE: Los Angeles County Registrar-Recorder/County Clerk, June 2, 2026 Statewide Direct
-- Primary — Official Canvass (the two candidates advancing to the Nov 3, 2026 runoff for
-- each seat with no June majority winner). Retrieved 2026-09-21.
--
-- IDEMPOTENCY: offices on (district_id, title); races on (election_id, position_name);
-- candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── Offices (4 new, all on the LA County district; nonpartisan) ─────────────────────────
CREATE TEMP TABLE jd_office_seed (office_no int, title text) ON COMMIT DROP;
INSERT INTO jd_office_seed VALUES
  (64, 'Judge of the Superior Court, Office No. 64'),
  (65, 'Judge of the Superior Court, Office No. 65'),
  (87, 'Judge of the Superior Court, Office No. 87'),
  (131,'Judge of the Superior Court, Office No. 131');

INSERT INTO essentials.offices
  (title, district_id, chamber_id, partisan_type, representing_state, seats,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT s.title, '3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid, NULL, 'nonpartisan', 'CA', 1, false, false, false
FROM jd_office_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id='3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid AND o.title=s.title
);

-- ─── Races (bind to the offices just ensured; primary_party NULL) ────────────────────────
CREATE TEMP TABLE jd_race_seed (office_no int, position_name text) ON COMMIT DROP;
INSERT INTO jd_race_seed VALUES
  (64, 'Judge of the Superior Court of Los Angeles County, Office No. 64'),
  (65, 'Judge of the Superior Court of Los Angeles County, Office No. 65'),
  (87, 'Judge of the Superior Court of Los Angeles County, Office No. 87'),
  (131,'Judge of the Superior Court of Los Angeles County, Office No. 131');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, o.id, rs.position_name, NULL, 1
FROM jd_race_seed rs
JOIN jd_office_seed os ON os.office_no=rs.office_no
JOIN essentials.offices o
  ON o.district_id='3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid AND o.title=os.title
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name=rs.position_name
);

-- ─── Candidates (the two advancing per seat; nonpartisan, none incumbent) ────────────────
CREATE TEMP TABLE jd_cand_seed
  (position_name text, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO jd_cand_seed VALUES
  ('Judge of the Superior Court of Los Angeles County, Office No. 64','Maria Ghobadi','Maria','Ghobadi'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 64','Rhonda A. Haymon','Rhonda','Haymon'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 65','Justin Allen Clayton','Justin','Clayton'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 65','Anna Slotky','Anna','Slotky'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 87','Anthony (A.J.) Bayne','Anthony','Bayne'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 87','David DeJute','David','DeJute'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 131','Donna Tryfman','Donna','Tryfman'),
  ('Judge of the Superior Court of Los Angeles County, Office No. 131','David Ross','David','Ross');

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, NULL, cs.full_name, cs.first_name, cs.last_name, false, 'active',
       'Los Angeles County Registrar-Recorder/County Clerk, June 2, 2026 Statewide Direct Primary Official Canvass (top-two advancing to the Nov 3, 2026 runoff). Retrieved 2026-09-21.'
FROM jd_cand_seed cs
JOIN essentials.races r
  ON r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_off int; v_races int; v_cands int; v_orphan int; v_party int; v_badgeo int; v_dup int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o JOIN jd_office_seed s ON s.title=o.title
   WHERE o.district_id='3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid;
  SELECT count(*) INTO v_races FROM essentials.races r JOIN jd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN jd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN jd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN jd_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.primary_party IS NOT NULL;
  -- each seeded race's district must be geofenced (LA County polygon exists)
  SELECT count(*) INTO v_badgeo FROM essentials.races r JOIN jd_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc=d.mtfcc);
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN jd_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='d91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_off    <> 4 THEN RAISE EXCEPTION 'Judge offices: expected 4, got %', v_off; END IF;
  IF v_races  <> 4 THEN RAISE EXCEPTION 'Judge races: expected 4, got %', v_races; END IF;
  IF v_cands  <> 8 THEN RAISE EXCEPTION 'Judge candidates: expected 8, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% judge race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% judge race(s) carry primary_party', v_party; END IF;
  IF v_badgeo <> 0 THEN RAISE EXCEPTION '% judge race(s) not resolvable to a geofence', v_badgeo; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
  RAISE NOTICE 'CA_0135 applied: % offices, % races, % candidates', v_off, v_races, v_cands;
END $$;

COMMIT;

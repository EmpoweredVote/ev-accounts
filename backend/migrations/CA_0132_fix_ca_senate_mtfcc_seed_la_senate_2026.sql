-- CA_0132_fix_ca_senate_mtfcc_seed_la_senate_2026.sql
-- Two parts: (1) fix a statewide geofencing bug on CA State Senate districts, then
-- (2) seed the LA-County 2026 State Senate races onto 'CA 2026 Statewide General'.
--
-- 🔴 (1) mtfcc SWAP FIX. Every CA STATE_UPPER (Senate) district row carries mtfcc 'G5220'
-- (the ASSEMBLY code); every STATE_LOWER (Assembly) row carries 'G5210' (the SENATE code).
-- The address-lookup geofence match keys the district's own mtfcc against the geofence's
-- mtfcc (geo_ids collide: '060NN' is used by both the Senate-NN and Assembly-NN polygons AND
-- by county FIPS), so a Senate office currently resolves to the ASSEMBLY polygon of the same
-- number — wrong voters. This corrects the Senate rows to 'G5210' so they resolve to the
-- Senate polygon. (The Assembly rows' 'G5210'->'G5220' correction ships with the Assembly
-- seed step.) Idempotent: only rows still mislabeled 'G5220' are touched.
--
-- (2) SEEDS 8 RACES / 16 CANDIDATES — the even-numbered Senate districts up in 2026 that
-- overlap LA County (per the LA Registrar), reusing the existing STATE_UPPER offices;
-- primary_party NULL (general; CA top-two, can be D-vs-D):
--   SD 20  Caroline Menjivar (D, inc) · Tony Rodriguez (R)
--   SD 22  Susan Rubio (D, inc) · Mike Netter (R)
--   SD 24  John M. Erickson (D) · Brian Goldsmith (D)            [D-vs-D, open]
--   SD 26  Sara Hernandez (D) · Sarah Rascón (D)                 [D-vs-D, open]
--   SD 28  Lola Smallwood-Cuevas (D, inc) · Joe Lisuzzo (R)
--   SD 30  Bob J. Archuleta (D, inc) · Araceli Martinez (R)
--   SD 34  Avelino Valencia (D) · Rhonda Shader (R)              [open]
--   SD 36  Chris Duncan (D) · Tony Strickland (R, inc)
--
-- Party never stored (antipartisan). The 5 incumbents seeking their own seat link to their
-- existing politician rows; challengers are politician_id NULL.
--
-- SOURCE: California SoS Official Certified List of Candidates, 8/27/2026. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: mtfcc fix guarded on the wrong value; races on (election_id, position_name);
-- candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── (1) Fix the CA Senate mtfcc swap (Senate districts must be G5210) ───────────────────
UPDATE essentials.districts
   SET mtfcc='G5210'
 WHERE district_type='STATE_UPPER' AND upper(state)='CA' AND mtfcc='G5220';

-- ─── (2) Races (reuse existing STATE_UPPER offices; primary_party NULL) ──────────────────
CREATE TEMP TABLE sen_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO sen_race_seed VALUES
  ('State Senate District 20','7a7d8d8e-3af2-4372-a943-6aa92c10fefb'),
  ('State Senate District 22','9705addc-6364-4439-9cc3-9fcbfeb4caaa'),
  ('State Senate District 24','58c7cb0f-6409-4e6a-aa4f-1d146e88eb69'),
  ('State Senate District 26','493a571f-b01b-4253-afbc-ffe3979f52bb'),
  ('State Senate District 28','9a837448-d3d3-4c56-b2bf-8d5e41c22ab1'),
  ('State Senate District 30','a9864785-4397-4f86-94fd-b03bc54bb585'),
  ('State Senate District 34','9d4dce25-ba2b-4835-9490-4ef4bc69d4a5'),
  ('State Senate District 36','e31dfcd0-d34f-4ecd-93cc-409d0e185687');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, s.office_id, s.position_name, NULL, 1
FROM sen_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified top-two) ─────────────────────────────────────────────────────
CREATE TEMP TABLE sen_cand_seed
  (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO sen_cand_seed VALUES
  ('State Senate District 20','Caroline Menjivar','Caroline','Menjivar',true,'4baa73c2-d38b-4d07-894f-1577d5ba43a3'::uuid),
  ('State Senate District 20','Tony Rodriguez','Tony','Rodriguez',false,NULL::uuid),
  ('State Senate District 22','Susan Rubio','Susan','Rubio',true,'b3937fff-ebcf-48d9-b20d-bdf98196e119'::uuid),
  ('State Senate District 22','Mike Netter','Mike','Netter',false,NULL::uuid),
  ('State Senate District 24','John M. Erickson','John','Erickson',false,NULL::uuid),
  ('State Senate District 24','Brian Goldsmith','Brian','Goldsmith',false,NULL::uuid),
  ('State Senate District 26','Sara Hernandez','Sara','Hernandez',false,NULL::uuid),
  ('State Senate District 26','Sarah Rascón','Sarah','Rascón',false,NULL::uuid),
  ('State Senate District 28','Lola Smallwood-Cuevas','Lola','Smallwood-Cuevas',true,'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'::uuid),
  ('State Senate District 28','Joe Lisuzzo','Joe','Lisuzzo',false,NULL::uuid),
  ('State Senate District 30','Bob J. Archuleta','Bob','Archuleta',true,'29e15a5d-d98f-4536-ad62-05b2612f30ca'::uuid),
  ('State Senate District 30','Araceli Martinez','Araceli','Martinez',false,NULL::uuid),
  ('State Senate District 34','Avelino Valencia','Avelino','Valencia',false,NULL::uuid),
  ('State Senate District 34','Rhonda Shader','Rhonda','Shader',false,NULL::uuid),
  ('State Senate District 36','Chris Duncan','Chris','Duncan',false,NULL::uuid),
  ('State Senate District 36','Tony Strickland','Tony','Strickland',true,'863ef272-ea35-482b-aee2-447c06bd469d'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf). Retrieved 2026-09-21.'
FROM sen_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_swap int; v_races int; v_cands int; v_orphan int; v_party int; v_badgeo int; v_dup int;
BEGIN
  -- (1) no CA Senate district left mislabeled
  SELECT count(*) INTO v_swap FROM essentials.districts
   WHERE district_type='STATE_UPPER' AND upper(state)='CA' AND mtfcc<>'G5210';

  SELECT count(*) INTO v_races FROM essentials.races r JOIN sen_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN sen_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN sen_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN sen_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.primary_party IS NOT NULL;
  -- each seeded race's district must now be G5210 with a matching Senate geofence
  SELECT count(*) INTO v_badgeo FROM essentials.races r JOIN sen_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND NOT (d.mtfcc='G5210' AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc='G5210'));
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN sen_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_swap   <> 0 THEN RAISE EXCEPTION '% CA Senate district(s) still mislabeled (not G5210)', v_swap; END IF;
  IF v_races  <> 8 THEN RAISE EXCEPTION 'Senate races: expected 8, got %', v_races; END IF;
  IF v_cands  <> 16 THEN RAISE EXCEPTION 'Senate candidates: expected 16, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% Senate race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% Senate race(s) carry primary_party', v_party; END IF;
  IF v_badgeo <> 0 THEN RAISE EXCEPTION '% Senate race(s) not resolvable to a G5210 Senate geofence', v_badgeo; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;

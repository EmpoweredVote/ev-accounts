-- CA_0133_fix_ca_assembly_mtfcc_seed_la_assembly_2026.sql
-- Two parts: (1) fix a statewide geofencing bug on CA State Assembly districts, then
-- (2) seed the LA-County 2026 State Assembly races onto 'CA 2026 Statewide General'.
--
-- 🔴 (1) mtfcc SWAP FIX (mirror of CA_0132's Senate fix). Every CA STATE_LOWER (Assembly)
-- district row carries mtfcc 'G5210' (the SENATE code) instead of its own 'G5220'. The
-- address-lookup geofence match keys the district's own mtfcc against the geofence's mtfcc
-- (geo_ids collide: '060NN' is used by both the Senate-NN and Assembly-NN polygons AND by
-- county FIPS), so an Assembly office currently resolves to the SENATE polygon of the same
-- number — wrong voters. This corrects the Assembly rows to 'G5220' so they resolve to the
-- Assembly polygon. (CA_0132 already corrected the Senate rows 'G5220'->'G5210'.)
-- Idempotent: only rows still mislabeled 'G5210' are touched.
--
-- (2) SEEDS 24 RACES / 48 CANDIDATES — the Assembly districts that overlap LA County (per the
-- LA Registrar), reusing the existing STATE_LOWER offices; primary_party NULL (general; CA
-- top-two, can be D-vs-D):
--   AD 34  Randall Putz (D) · Charles Frederick Hughes (R)              [open]
--   AD 39  Juan Carrillo (D, inc) · Paul Andre Marsh (R)
--   AD 40  Pilar Schiavo (D, inc) · Rickey Tracy Hayes II (R)
--   AD 41  John Harabedian (D, inc) · Adam Christopher Vena (R)
--   AD 42  Deborah Klein Lopez (D) · Ted Nordblum (R)                   [open]
--   AD 43  Celeste Rodriguez (D, inc) · Ricardo Benitez (R)
--   AD 44  Nicholas "Nick" Schultz (D, inc) · Carolyn Daniels (R)
--   AD 46  Jesse Gabriel (D, inc) · Tracey Schroeder (R)
--   AD 48  Blanca Rubio (D, inc) · Dan T. Tran (R)
--   AD 49  Mike Fong (D, inc) · Long David Liu (R)
--   AD 51  Colin D. Hernandez (D) · Rick Chavez Zbur (D, inc)          [D-vs-D]
--   AD 52  Jessica Caloza (D, inc) · Andrea Lee Anderson (R)
--   AD 53  Michelle Rodriguez (D, inc) · Rafaela Romero (R)
--   AD 54  Mark Gonzalez (D, inc) · Alexandra Briseno (R)
--   AD 55  Ashley M. Brown (D) · Isaac G. Bryan (D, inc)               [D-vs-D]
--   AD 56  Lisa Calderon (D, inc) · Jessica Martinez (R)
--   AD 57  Sade Elhawary (D, inc) · Constance Jewel Menzies (R)
--   AD 61  Tina Simone McKinnor (D, inc) · Brian Lockwood (R)
--   AD 62  José Luis Solache (D, inc) · Paul Irving Jones (R)
--   AD 64  Blanca Pacheco (D, inc) · Raul Ortiz Jr. (R)
--   AD 65  Ayanna Davis (D) · Lydia A. Gutiérrez (R)                    [open]
--   AD 66  Sara Deen (D) · Paul Seo (D)                                 [D-vs-D, open]
--   AD 67  Mark Pulido (D) · Paulo Morales (R)                          [open]
--   AD 69  Carolyn J. Essex (D) · Josh Lowenthal (D, inc)              [D-vs-D]
--
-- Party never stored (antipartisan). The 19 incumbents seeking their own seat link to their
-- existing politician rows (verified against office_terms current holders); challengers and
-- open-seat candidates are politician_id NULL. Five current holders are not on the 2026
-- ballot (AD34 Lackey, AD42 Irwin, AD65 Gipson, AD66 Muratsuchi, AD67 Quirk-Silva) — those
-- seats are open and no candidate is flagged incumbent.
--
-- No Part B (statewide-fallback) leak: STATE_LOWER is not a statewide district type and every
-- race keeps a non-null office_id, so these are reached only via the Part A geofence match.
--
-- SOURCE: California SoS Official Certified List of Candidates, 8/27/2026. Retrieved 2026-09-21.
--
-- IDEMPOTENCY: mtfcc fix guarded on the wrong value; races on (election_id, position_name);
-- candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── (1) Fix the CA Assembly mtfcc swap (Assembly districts must be G5220) ───────────────
UPDATE essentials.districts
   SET mtfcc='G5220'
 WHERE district_type='STATE_LOWER' AND upper(state)='CA' AND mtfcc='G5210';

-- ─── (2) Races (reuse existing STATE_LOWER offices; primary_party NULL) ──────────────────
CREATE TEMP TABLE asm_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO asm_race_seed VALUES
  ('State Assembly District 34','54a4ad72-bcd1-4fe1-b684-bfa7e72152fc'),
  ('State Assembly District 39','35b83356-848d-49ee-8815-14c7885f7dbb'),
  ('State Assembly District 40','e3c96374-ab47-4fa5-9a23-f1b17d1e393e'),
  ('State Assembly District 41','b5bca67c-a70d-496b-909e-cf33839ce017'),
  ('State Assembly District 42','3752046e-327e-472d-8c0d-5ce65061e7a4'),
  ('State Assembly District 43','ac6b849b-7b62-4ea8-912d-d009d9ed8090'),
  ('State Assembly District 44','1854c5b3-a585-495f-a1f2-c4c79a8e7cac'),
  ('State Assembly District 46','2d462db5-4c4d-4d52-90bb-572851612368'),
  ('State Assembly District 48','02cffd4c-9fd6-47c4-ae91-f33c0442efa2'),
  ('State Assembly District 49','68b9d71e-fa8e-4f71-8fac-2e396818c6eb'),
  ('State Assembly District 51','7391433d-3597-487f-8355-f39bb5365079'),
  ('State Assembly District 52','5df342df-1554-47f1-ade4-1007685f934b'),
  ('State Assembly District 53','454f55bc-6f3f-4e2f-8b74-78c0901abcf1'),
  ('State Assembly District 54','a2f330df-16cd-42be-bcd5-006e57cf1d69'),
  ('State Assembly District 55','be3bdca4-d290-474e-aa45-37b336719fa0'),
  ('State Assembly District 56','5badb726-42ee-4919-8574-884cc4e4e3e1'),
  ('State Assembly District 57','7d965633-60b5-419f-8c40-34e1077d2a77'),
  ('State Assembly District 61','35d6cdde-1ce5-423c-9239-97a5b8e54666'),
  ('State Assembly District 62','c92f4112-2a0c-448d-b35d-39596daa1e55'),
  ('State Assembly District 64','1f1502ce-0ab9-4b69-880b-adc8263aa223'),
  ('State Assembly District 65','7803f2a9-9dd2-4f45-8b85-1cf5fd29e785'),
  ('State Assembly District 66','e45c9d52-6288-4865-a2de-dadd73cc18e6'),
  ('State Assembly District 67','4f3b86d7-7795-43ef-bf06-1d2191a9fad3'),
  ('State Assembly District 69','5e24e873-5ddc-407f-b1b3-55037fad21fb');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, s.office_id, s.position_name, NULL, 1
FROM asm_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified top-two) ─────────────────────────────────────────────────────
CREATE TEMP TABLE asm_cand_seed
  (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO asm_cand_seed VALUES
  ('State Assembly District 34','Randall Putz','Randall','Putz',false,NULL::uuid),
  ('State Assembly District 34','Charles Frederick Hughes','Charles','Hughes',false,NULL::uuid),
  ('State Assembly District 39','Juan Carrillo','Juan','Carrillo',true,'b959d608-5674-467e-a1c8-3572c76a729b'::uuid),
  ('State Assembly District 39','Paul Andre Marsh','Paul','Marsh',false,NULL::uuid),
  ('State Assembly District 40','Pilar Schiavo','Pilar','Schiavo',true,'d64c969e-f458-4387-98b5-1e7af8cb42f0'::uuid),
  ('State Assembly District 40','Rickey Tracy Hayes II','Rickey','Hayes',false,NULL::uuid),
  ('State Assembly District 41','John Harabedian','John','Harabedian',true,'0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e'::uuid),
  ('State Assembly District 41','Adam Christopher Vena','Adam','Vena',false,NULL::uuid),
  ('State Assembly District 42','Deborah Klein Lopez','Deborah','Lopez',false,NULL::uuid),
  ('State Assembly District 42','Ted Nordblum','Ted','Nordblum',false,NULL::uuid),
  ('State Assembly District 43','Celeste Rodriguez','Celeste','Rodriguez',true,'f9cbe210-a840-4924-b4aa-a5de0dc143ba'::uuid),
  ('State Assembly District 43','Ricardo Benitez','Ricardo','Benitez',false,NULL::uuid),
  ('State Assembly District 44','Nicholas "Nick" Schultz','Nicholas','Schultz',true,'e31e6ebf-91ea-478f-b4dc-6974888bdffa'::uuid),
  ('State Assembly District 44','Carolyn Daniels','Carolyn','Daniels',false,NULL::uuid),
  ('State Assembly District 46','Jesse Gabriel','Jesse','Gabriel',true,'f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid),
  ('State Assembly District 46','Tracey Schroeder','Tracey','Schroeder',false,NULL::uuid),
  ('State Assembly District 48','Blanca Rubio','Blanca','Rubio',true,'51d15b77-71bb-475e-b86e-c6e1b37b869d'::uuid),
  ('State Assembly District 48','Dan T. Tran','Dan','Tran',false,NULL::uuid),
  ('State Assembly District 49','Mike Fong','Mike','Fong',true,'cacdb3e3-f716-4914-9e32-a95cc632af42'::uuid),
  ('State Assembly District 49','Long David Liu','Long','Liu',false,NULL::uuid),
  ('State Assembly District 51','Colin D. Hernandez','Colin','Hernandez',false,NULL::uuid),
  ('State Assembly District 51','Rick Chavez Zbur','Rick','Zbur',true,'ff77225c-51f9-4628-acc3-020d40382d05'::uuid),
  ('State Assembly District 52','Jessica Caloza','Jessica','Caloza',true,'685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid),
  ('State Assembly District 52','Andrea Lee Anderson','Andrea','Anderson',false,NULL::uuid),
  ('State Assembly District 53','Michelle Rodriguez','Michelle','Rodriguez',true,'108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid),
  ('State Assembly District 53','Rafaela Romero','Rafaela','Romero',false,NULL::uuid),
  ('State Assembly District 54','Mark Gonzalez','Mark','Gonzalez',true,'005d7df1-227e-4110-b254-ec835d5b5e95'::uuid),
  ('State Assembly District 54','Alexandra Briseno','Alexandra','Briseno',false,NULL::uuid),
  ('State Assembly District 55','Ashley M. Brown','Ashley','Brown',false,NULL::uuid),
  ('State Assembly District 55','Isaac G. Bryan','Isaac','Bryan',true,'5cdd28b7-f8be-4968-bc1a-0e7928786980'::uuid),
  ('State Assembly District 56','Lisa Calderon','Lisa','Calderon',true,'0afa998d-94e9-4af4-ba00-256c38869398'::uuid),
  ('State Assembly District 56','Jessica Martinez','Jessica','Martinez',false,NULL::uuid),
  ('State Assembly District 57','Sade Elhawary','Sade','Elhawary',true,'3c2bfe51-9a53-4992-801b-138a1a8ce9ed'::uuid),
  ('State Assembly District 57','Constance Jewel Menzies','Constance','Menzies',false,NULL::uuid),
  ('State Assembly District 61','Tina Simone McKinnor','Tina','McKinnor',true,'522efd15-f5e2-4e1a-8708-aad87410637d'::uuid),
  ('State Assembly District 61','Brian Lockwood','Brian','Lockwood',false,NULL::uuid),
  ('State Assembly District 62','José Luis Solache','José','Solache',true,'1caa9043-2397-4f75-b430-acc0623d64d7'::uuid),
  ('State Assembly District 62','Paul Irving Jones','Paul','Jones',false,NULL::uuid),
  ('State Assembly District 64','Blanca Pacheco','Blanca','Pacheco',true,'c9205ba1-d0c8-4f17-a165-fb2a8fdae742'::uuid),
  ('State Assembly District 64','Raul Ortiz Jr.','Raul','Ortiz',false,NULL::uuid),
  ('State Assembly District 65','Ayanna Davis','Ayanna','Davis',false,NULL::uuid),
  ('State Assembly District 65','Lydia A. Gutiérrez','Lydia','Gutiérrez',false,NULL::uuid),
  ('State Assembly District 66','Sara Deen','Sara','Deen',false,NULL::uuid),
  ('State Assembly District 66','Paul Seo','Paul','Seo',false,NULL::uuid),
  ('State Assembly District 67','Mark Pulido','Mark','Pulido',false,NULL::uuid),
  ('State Assembly District 67','Paulo Morales','Paulo','Morales',false,NULL::uuid),
  ('State Assembly District 69','Carolyn J. Essex','Carolyn','Essex',false,NULL::uuid),
  ('State Assembly District 69','Josh Lowenthal','Josh','Lowenthal',true,'39d99fc2-b8ab-4846-8ff3-bcb65e16bee4'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf). Retrieved 2026-09-21.'
FROM asm_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_swap int; v_races int; v_cands int; v_orphan int; v_party int; v_badgeo int; v_dup int; v_inc int;
BEGIN
  -- (1) no CA Assembly district left mislabeled
  SELECT count(*) INTO v_swap FROM essentials.districts
   WHERE district_type='STATE_LOWER' AND upper(state)='CA' AND mtfcc<>'G5220';

  SELECT count(*) INTO v_races FROM essentials.races r JOIN asm_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN asm_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN asm_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN asm_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.primary_party IS NOT NULL;
  -- each seeded race's district must now be G5220 with a matching Assembly geofence
  SELECT count(*) INTO v_badgeo FROM essentials.races r JOIN asm_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND NOT (d.mtfcc='G5220' AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc='G5220'));
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN asm_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid GROUP BY 1,2 HAVING count(*)>1) x;
  -- every incumbent-flagged candidate must be the current holder of that race's office
  SELECT count(*) INTO v_inc FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN asm_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND rc.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms ot
                      WHERE ot.office_id=r.office_id AND ot.term_end IS NULL AND ot.politician_id=rc.politician_id);

  IF v_swap   <> 0  THEN RAISE EXCEPTION '% CA Assembly district(s) still mislabeled (not G5220)', v_swap; END IF;
  IF v_races  <> 24 THEN RAISE EXCEPTION 'Assembly races: expected 24, got %', v_races; END IF;
  IF v_cands  <> 48 THEN RAISE EXCEPTION 'Assembly candidates: expected 48, got %', v_cands; END IF;
  IF v_orphan <> 0  THEN RAISE EXCEPTION '% Assembly race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0  THEN RAISE EXCEPTION '% Assembly race(s) carry primary_party', v_party; END IF;
  IF v_badgeo <> 0  THEN RAISE EXCEPTION '% Assembly race(s) not resolvable to a G5220 Assembly geofence', v_badgeo; END IF;
  IF v_dup    <> 0  THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
  IF v_inc    <> 0  THEN RAISE EXCEPTION '% incumbent-flagged candidate(s) not the current office holder', v_inc; END IF;
END $$;

COMMIT;

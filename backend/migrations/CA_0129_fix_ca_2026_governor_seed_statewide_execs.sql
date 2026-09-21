-- CA_0129_fix_ca_2026_governor_seed_statewide_execs.sql
-- California 2026 general: fix the Governor race and seed the statewide executive offices.
-- These appear on EVERY California ballot (Los Angeles County included).
--
-- Extends 'CA 2026 Statewide General' (id 728d0074-8a8d-49e3-a68c-78ccdd15434f), which held
-- 52 U.S. House races + one BROKEN office-less "CA Governor" race carrying all 65 June-primary
-- filers (office_id NULL → invisible to address lookup / mis-tiered; wrong for a top-two general).
--
-- 🔴 FIX GOVERNOR: two parts.
--  (1) The existing "CA Governor" race on the general is office-less (office_id NULL) and
--      carries all 65 June-primary filers — the API relabels office-less statewide races to
--      STATE_EXEC, so it WAS rendering as a wrong 65-candidate Governor. That 65-name field is
--      the PRIMARY field, so it is MOVED to 'CA 2026 Statewide Primary' where it belongs (the
--      primary is out of the date window, so it no longer appears on the general). This is a
--      plain election_id repoint — FK-safe, and it does NOT touch essentials.candidate_staging
--      (which references the race via race_id + matched_candidate_id; a DELETE is blocked by
--      those FKs, a move is not).
--  (2) Create Governor as an office-bound STATE_EXEC race (office on the shared California exec
--      district, geo_id '06') with the certified top-two — the same model as every other exec.
--
-- SEEDS 8 RACES / 16 CANDIDATES (all top-two; reuse existing CA STATE_EXEC offices, geo '06';
-- primary_party NULL = general; California top-two can be D-vs-R OR D-vs-D):
--   Governor                         Xavier Becerra (D), Steve Hilton (R)
--   Lieutenant Governor              Fiona Ma (D), Gloria Romero (R)
--   Attorney General                 Rob Bonta (D, inc), Michael E. Gates (R)
--   Secretary of State               Shirley N. Weber (D, inc), Donald P. Wagner (R)
--   Controller                       Malia M. Cohen (D, inc), Herb W. Morgan (R)
--   Treasurer                        Eleni Kounalakis (D), Jennifer Hawks (R)
--   Insurance Commissioner           Ben Allen (D), Jane Kim (D)              [D-vs-D]
--   Superintendent of Public Instr.  Richard Barrera, Sonja Shaw             [nonpartisan]
--
-- Board of Equalization District 3 (LA County) is handled in a FOLLOW-UP: it is a
-- district-based seat that must be geofenced to LA and must NOT use STATE_EXEC (the Part B
-- statewide fallback would leak a STATE_EXEC race to every CA address).
--
-- Party never stored (antipartisan; primary_party NULL). The three incumbents seeking their
-- own seat (Bonta, Weber, Cohen) link to their existing politician rows; everyone else is a
-- challenger or running for a different office → politician_id NULL.
--
-- SOURCE: California Secretary of State Official Certified List of Candidates (8/27/2026),
-- https://elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf .
-- Retrieved 2026-09-21.
--
-- IDEMPOTENCY: delete guarded on the exact broken race (office_id IS NULL); races guard on
-- (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── (1) Move the office-less 65-candidate "CA Governor" race off the general onto the ──────
--         CA statewide primary (its 65 rows are the June primary field). FK-safe repoint.
UPDATE essentials.races
   SET election_id='7529bbe3-fdfd-408c-a902-5ab131016604'::uuid  -- CA 2026 Statewide Primary
 WHERE id='bc936a36-287c-4ffd-abd8-5e4fd798bae5'::uuid
   AND election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
   AND office_id IS NULL AND position_name='CA Governor';

-- ─── (2) Races (office-bound; reuse CA STATE_EXEC offices on the shared geo '06' district) ──
CREATE TEMP TABLE ca_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO ca_race_seed VALUES
  ('Governor',                             '08454462-a1f0-4d11-9f61-aba7a173a3de'),
  ('Lieutenant Governor',                  'afab54f2-73d1-46f0-9beb-5ebc8be30f5a'),
  ('Attorney General',                     '1cd5778d-ae38-44c1-9ee4-a766d3e50e96'),
  ('Secretary of State',                   '3d1b9d8e-c164-4210-985b-dc09c60f5048'),
  ('Controller',                           '0cf695f9-ebf7-4f80-a17e-b444f1ddf91a'),
  ('Treasurer',                            '67f4cf07-63e2-4547-b529-565cf95603b1'),
  ('Insurance Commissioner',              '18e2cad2-e2f3-4559-8909-c80b384d2243'),
  ('Superintendent of Public Instruction','35052ee9-cd38-4040-a1a4-533236dd9b3d');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, s.office_id, s.position_name, NULL, 1
FROM ca_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=s.position_name
);

-- ─── Candidates (certified top-two) ─────────────────────────────────────────────────────
CREATE TEMP TABLE ca_cand_seed
  (position_name text, full_name text, first_name text, last_name text,
   is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO ca_cand_seed VALUES
  ('Governor',            'Xavier Becerra', 'Xavier','Becerra', false, NULL::uuid),
  ('Governor',            'Steve Hilton',   'Steve', 'Hilton',  false, NULL::uuid),
  ('Lieutenant Governor', 'Fiona Ma',       'Fiona', 'Ma',      false, NULL::uuid),
  ('Lieutenant Governor', 'Gloria Romero',  'Gloria','Romero',  false, NULL::uuid),
  ('Attorney General',    'Rob Bonta',      'Rob',   'Bonta',   true,  '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'::uuid),
  ('Attorney General',    'Michael E. Gates','Michael','Gates',  false, NULL::uuid),
  ('Secretary of State',  'Shirley N. Weber','Shirley','Weber',  true,  '4ba62f32-dd20-48ce-8d84-d09bb129ad59'::uuid),
  ('Secretary of State',  'Donald P. Wagner','Donald','Wagner',  false, NULL::uuid),
  ('Controller',          'Malia M. Cohen', 'Malia', 'Cohen',   true,  'ea85dfe3-1092-468e-a799-cb8054c135db'::uuid),
  ('Controller',          'Herb W. Morgan', 'Herb',  'Morgan',  false, NULL::uuid),
  ('Treasurer',           'Eleni Kounalakis','Eleni','Kounalakis',false,NULL::uuid),
  ('Treasurer',           'Jennifer Hawks', 'Jennifer','Hawks', false, NULL::uuid),
  ('Insurance Commissioner','Ben Allen',    'Ben',   'Allen',   false, NULL::uuid),
  ('Insurance Commissioner','Jane Kim',     'Jane',  'Kim',     false, NULL::uuid),
  ('Superintendent of Public Instruction','Richard Barrera','Richard','Barrera',false,NULL::uuid),
  ('Superintendent of Public Instruction','Sonja Shaw','Sonja','Shaw',false,NULL::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf). Retrieved 2026-09-21.'
FROM ca_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_races int; v_cands int; v_orphan int; v_party int; v_dup int; v_badgov int;
BEGIN
  SELECT count(*) INTO v_races FROM essentials.races r JOIN ca_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN ca_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  SELECT count(*) INTO v_orphan FROM essentials.races r JOIN ca_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.office_id IS NULL;
  SELECT count(*) INTO v_party FROM essentials.races r JOIN ca_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.primary_party IS NOT NULL;
  -- the office-less 65-candidate Governor race must no longer be on the general
  SELECT count(*) INTO v_badgov FROM essentials.races
   WHERE election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND office_id IS NULL AND position_name='CA Governor';
  SELECT count(*) INTO v_dup FROM (
    SELECT rc.race_id, lower(rc.full_name) n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
      JOIN ca_race_seed s ON s.position_name=r.position_name
     WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid GROUP BY 1,2 HAVING count(*)>1) x;

  IF v_races  <> 8 THEN RAISE EXCEPTION 'CA exec races: expected 8, got %', v_races; END IF;
  IF v_cands  <> 16 THEN RAISE EXCEPTION 'CA exec candidates: expected 16, got %', v_cands; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% exec race(s) with NULL office_id', v_orphan; END IF;
  IF v_party  <> 0 THEN RAISE EXCEPTION '% general race(s) carry primary_party', v_party; END IF;
  IF v_badgov <> 0 THEN RAISE EXCEPTION 'office-less CA Governor race still on the general (%)', v_badgov; END IF;
  IF v_dup    <> 0 THEN RAISE EXCEPTION '% duplicate candidate name(s) within a race', v_dup; END IF;
END $$;

COMMIT;

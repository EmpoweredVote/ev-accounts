-- CA_0281_az_statewide_november_fields.sql
--
-- Slot CA_0281 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Arizona's seven statewide November races, CA_0278 style. Like the House races before CA_0278, none
-- had ever been reconciled: every row carried a NULL result, so Essentials still listed primary losers
-- (David Schweikert for Governor, Tom Horne for Superintendent, ...) as November candidates. Also
-- corrects David Redkey's stray CD1 row (below).
--
-- Sources (both operator-supplied, 2026-09-24):
--   [GEN] Arizona Secretary of State, 2026 General Election candidate list
--         (apps.arizona.vote/electioninfo/Election/69, State tab; captured by the operator 2026-09-24).
--   [CAN] State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026;
--         20260806_Primary_Canvass.pdf): Governor p.3, Secretary of State p.11, the rest p.12.
--
--   Governor        Biggs (REP), Hobbs (DEM), Lombardo (GRN), Hourihan (NOL)
--                   write-ins + Gertritrude Gonzalez (REP), Alice Novoa (REP)        NEW PEOPLE
--                   not_nominated: Schweikert (REP primary, 88,284 to Biggs 453,819)
--   Secretary of State  Kolodin (REP), Fontes (DEM), + Duwayne Collier (GRN)       NEW PERSON
--                   not_nominated: Swoboda (231,986 to Kolodin 345,675)
--   Attorney General    Petersen (REP), Mayes (DEM)      not_nominated: Glassman
--   Treasurer       Norton (REP), Mansour (DEM)          not_nominated: Haley (lost the REP primary);
--                   Zepeda (in neither [CAN] nor [GEN] — never reached the primary ballot)
--   Superintendent  Yee (REP), Ruiz (DEM)
--                   write-ins Stephen Neal Jr. (NOL, existing row -> is_write_in), + Gerard Davis (GRN)
--                   not_nominated: Horne (incumbent; lost the REP primary to Yee), Newby
--   Mine Inspector  Presmyk (REP), Matlock (DEM)
--   Corporation Commission (2 seats)  Heap, Thompson (REP), Hill, Pratte (DEM), + Mike Cease (GRN)
--                   not_nominated: Myers (incumbent; third of 3 REP candidates for 2 nominations); Marshall (in
--                   neither [CAN] nor [GEN])
--   Collier and Cease won GRN primaries as write-ins ([CAN]) but are printed in November (no mark).
--
-- NOT TOUCHED: the three 'withdrawn' rows (Taylor Robson, Roeberg, Butts); none is on [GEN].
-- Losers keep is_active = true (ruling 2026-09-24). Seated losers (Horne, Myers) keep their seats:
-- losing a primary ends a candidacy, not a term.
--
-- REDKEY, CD1 (row 18e51e01). An early roster put David Redkey in CD1; he ran in CD3 (GRN, CA_0278).
-- Migration 1457 set the CD1 row 'withdrawn' because he was "NOT on the certified general-election
-- field" — but he never withdrew from anything, and Essentials badged him Withdrawn in CD1. The
-- accurate record is the one 1457's own note describes: not on that race's ballot. So: status
-- 'active', result 'not_nominated' (ruling: losers stay active, closed by result). The elections API
-- omits not_nominated rows from ballot lists (#782), so the CD1 card disappears. His stance bucket
-- cannot move: his CD3 row is already active in the same state and election.
--
-- BARE politician rows, 1296 / CA_0280 style: external_id -66000328..-66000332 (the next free numbers in
-- 1296's block at authoring — -66000327 was the last taken; the pre-flight refuses if any is taken by
-- someone else), is_incumbent = false stated explicitly, is_active = true. No politician by these names
-- existed.
--
-- CI: no candidate_status changes except Redkey's (bucket unchanged, above); new people carry no stance
-- rows, so stance-sources buckets cannot move. Every prod-reading CI check is run before and after.
--
-- IDEMPOTENT: inserts by NOT EXISTS; updates guarded on result IS NULL.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the five race_candidates rows whose source ends 'added by CA_0281
--   (2026-09-24)' and the politicians -66000328..-66000332; set result/result_source NULL on rows whose
--   result_source ends 'Recorded by CA_0281 (2026-09-24).' (Neal Jr.: also is_write_in false; Redkey
--   CD1: also candidate_status back to 'withdrawn').

BEGIN;

CREATE TEMP TABLE ca0281_src ON COMMIT DROP AS
SELECT 'Arizona Secretary of State, 2026 General Election candidate list (apps.arizona.vote/electioninfo/Election/69, State tab; captured by the operator 2026-09-24)'::text AS gen,
       'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026; 20260806_Primary_Canvass.pdf pp.3, 11-12)'::text AS can;

-- The seven races: live count afterwards, and how many of those are write-ins.
CREATE TEMP TABLE ca0281_race ON COMMIT DROP AS
SELECT x.position_name, ra.id AS race_id, x.expect, x.write_ins
  FROM (VALUES ('Governor',6,2), ('Secretary of State',3,0), ('Attorney General',2,0), ('Treasurer',2,0),
               ('Superintendent of Public Instruction',4,2), ('State Mine Inspector',2,0),
               ('Arizona Corporation Commission',5,0)) AS x(position_name, expect, write_ins)
  JOIN essentials.elections e ON e.state = 'AZ' AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- Existing rows and their dispositions. note = why, for result_source.
CREATE TEMP TABLE ca0281_upd ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('895a426d-6c65-49fe-adc9-65bad6afab67'::uuid, 'Andy Biggs',           'advanced',      false, 'won the REP primary; on the November ballot'),
  ('fcd85751-3fd7-4c63-9f2a-b3d2552ea23a'::uuid, 'Katie Hobbs',          'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('3d8d0a08-6380-4152-a6ff-15c68d04904c'::uuid, 'Risa Lombardo',        'advanced',      false, 'won the GRN primary; on the November ballot'),
  ('b3a0bcdf-c650-483d-a540-bb17835a8fd1'::uuid, 'Teri Hourihan',        'advanced',      false, 'won the NOL primary; on the November ballot'),
  ('2b414878-e840-4250-906d-d7f74d6b350c'::uuid, 'David Schweikert',     'not_nominated', false, 'lost the REP primary; not on the November ballot'),
  ('d0c18db4-9645-4abc-9057-c9872655a8f9'::uuid, 'Alexander Kolodin',    'advanced',      false, 'won the REP primary; on the November ballot'),
  ('f509b4fb-487c-4d82-a431-e6b94e15054b'::uuid, 'Adrian Fontes',        'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('bff7ced2-9d64-419e-b34b-416fe1e8ece6'::uuid, 'Gina Swoboda',         'not_nominated', false, 'lost the REP primary; not on the November ballot'),
  ('8e18026b-fbe1-4100-b8d3-ed7aa064fbaf'::uuid, 'Warren Petersen',      'advanced',      false, 'won the REP primary; on the November ballot'),
  ('23e673fe-fbae-4d85-9537-6216908285cf'::uuid, 'Kris Mayes',           'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('90f95a3d-55af-40a3-90a1-2a312763ec7d'::uuid, 'Rodney Glassman',      'not_nominated', false, 'lost the REP primary; not on the November ballot'),
  ('fa4c48e3-0f9d-42a2-b80a-748a50873d30'::uuid, 'Elijah Norton',        'advanced',      false, 'won the REP primary; on the November ballot'),
  ('5c91f031-c392-4d9e-9b13-e062fd3d7b70'::uuid, 'Nick Mansour',         'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('a2a04b10-385e-4c10-98f4-0dfc144839ed'::uuid, 'Katherine Haley',      'not_nominated', false, 'lost the REP primary; not on the November ballot'),
  ('62d3bc0a-4541-42fc-8a49-da719992c91d'::uuid, 'Michael Zepeda',       'not_nominated', false, 'in neither the primary canvass nor the November list'),
  ('c380fe5a-e117-44dd-bd85-30ff609e274b'::uuid, 'Kimberly Yee',         'advanced',      false, 'won the REP primary; on the November ballot'),
  ('2bd5d9e9-9655-4120-a724-7bbccbc046d9'::uuid, 'Teresa Ruiz',          'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('7e1b376e-7893-4a2e-9177-69622d1deb0b'::uuid, 'Stephen Neal Jr.',     'advanced',      true,  'registered November write-in candidate (NOL)'),
  ('3c2edfc7-e318-4ea0-ac5d-b33c1b7fcd2b'::uuid, 'Tom Horne',            'not_nominated', false, 'lost the REP primary; not on the November ballot'),
  ('9056d366-1a24-4872-92c4-1046cf02fb33'::uuid, 'Brett Newby',          'not_nominated', false, 'lost the DEM primary; not on the November ballot'),
  ('4cca6a73-3bd8-4614-919d-cfbca7148509'::uuid, 'Les Presmyk',          'advanced',      false, 'won the REP primary; on the November ballot'),
  ('d930ae4d-8991-4815-a135-d02c94d710f7'::uuid, 'Brian Matlock',        'advanced',      false, 'won the DEM primary; on the November ballot'),
  ('e6b78946-64bc-419a-825e-1996945d9849'::uuid, 'Ralph Heap',           'advanced',      false, 'nominated in the REP primary (2 seats); on the November ballot'),
  ('e4b506cc-9c06-48e7-b3ba-9b0cdb14fa08'::uuid, 'Kevin Thompson',       'advanced',      false, 'nominated in the REP primary (2 seats); on the November ballot'),
  ('aa19c814-4908-4fcf-acaf-15c317ad39f3'::uuid, 'Jonathon Hill',        'advanced',      false, 'nominated in the DEM primary (2 seats); on the November ballot'),
  ('7c3c1c0e-a208-4d5e-8429-27f2c8ea11bf'::uuid, 'Clara Pratte',         'advanced',      false, 'nominated in the DEM primary (2 seats); on the November ballot'),
  ('2db1547a-59ed-477e-b38e-8077b53da2dd'::uuid, 'Nick Myers',           'not_nominated', false, 'third in the REP primary for 2 seats; not on the November ballot'),
  ('b39a6569-3a88-4440-9c12-b5ddaa8425ec'::uuid, 'David Marshall',       'not_nominated', false, 'in neither the primary canvass nor the November list')
) AS v(rc_id, full_name, result, write_in, note);

CREATE TEMP TABLE ca0281_new ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000328::bigint, 'Duwayne',     'Collier',  'Duwayne Collier',     'Green',      'Secretary of State',                   false, 'COLLIER, DUWAYNE (GRN)',       'won the GRN primary as a write-in (421); on the November ballot'),
  (-66000329::bigint, 'Mike',        'Cease',    'Mike Cease',          'Green',      'Arizona Corporation Commission',       false, 'CEASE, MIKE (GRN)',            'won the GRN primary as a write-in (213); on the November ballot'),
  (-66000330::bigint, 'Gertritrude', 'Gonzalez', 'Gertritrude Gonzalez','Republican', 'Governor',                             true,  'GONZALEZ, GERTRITRUDE (REP)',  'registered November write-in candidate'),
  (-66000331::bigint, 'Alice',       'Novoa',    'Alice Novoa',         'Republican', 'Governor',                             true,  'NOVOA, ALICE (REP)',           'registered November write-in candidate'),
  (-66000332::bigint, 'Gerard',      'Davis',    'Gerard Davis',        'Green',      'Superintendent of Public Instruction', true,  'DAVIS, GERARD (GRN)',          'registered November write-in candidate')
) AS v(ext, first_name, last_name, full_name, party, position_name, write_in, listed_as, note);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0281_race;
  IF n <> 7 THEN RAISE EXCEPTION 'PRE: resolved % of 7 AZ statewide races', n; END IF;

  SELECT count(*) INTO n FROM ca0281_upd u
    JOIN essentials.race_candidates rc ON rc.id = u.rc_id AND rc.full_name = u.full_name
    JOIN ca0281_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL OR (rc.result = u.result AND rc.result_source LIKE '%Recorded by CA_0281 (2026-09-24).');
  IF n <> 28 THEN RAISE EXCEPTION 'PRE: only % of 28 existing rows are as authored', n; END IF;

  -- Nothing else in these races lacks a result, apart from withdrawn rows.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0281_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.id NOT IN (SELECT rc_id FROM ca0281_upd)
     AND coalesce(rc.source, '') NOT LIKE '%added by CA_0281 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed rows in the AZ statewide races', n; END IF;

  -- None of the five already has a row in its race; external_ids free or ours.
  SELECT count(*) INTO n FROM ca0281_new x JOIN ca0281_race r ON r.position_name = x.position_name
    JOIN essentials.race_candidates rc ON rc.race_id = r.race_id AND rc.last_name = x.last_name
   WHERE coalesce(rc.source, '') NOT LIKE '%added by CA_0281 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the five already have a row in their race', n; END IF;
  SELECT count(*) INTO n FROM ca0281_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source NOT LIKE 'CA_0281 (2026-09-24):%';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000328..-66000332 are taken by someone else', n; END IF;

  -- Redkey CD1: the stray row, withdrawn by 1457 (or already corrected by this file), and his CD3 row live.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.id = '18e51e01-8977-4d8a-8728-49853bd6fe76' AND rc.full_name = 'David Redkey'
     AND ((rc.candidate_status = 'withdrawn' AND rc.result IS NULL)
          OR rc.result_source LIKE '%Recorded by CA_0281 (2026-09-24).');
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: Redkey CD1 row is not as authored'; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.politician_id = '919e5a66-f60c-4710-b684-29d2790fe4da' AND rc.candidate_status = 'active'
     AND rc.result = 'advanced' AND rc.source LIKE '%CA_0278%';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: Redkey CD3 row (CA_0278) not found'; END IF;

  RAISE NOTICE 'CA_0281 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The five new people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true,
       'CA_0281 (2026-09-24): ' || s.gen || ': ' || x.position_name || ', ' || x.listed_as
       || CASE WHEN x.write_in THEN ', Write-In Candidate' ELSE '' END, 'manual'
  FROM ca0281_new x CROSS JOIN ca0281_src s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. Their November candidacies.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, is_write_in, source, result, result_source,
                                        result_recorded_at, last_verified_at)
SELECT r.race_id, p.id, x.full_name, x.first_name, x.last_name, false, 'active', x.write_in,
       s.gen || '; ' || x.listed_as || CASE WHEN x.write_in THEN ', Write-In Candidate' ELSE '' END
       || '; added by CA_0281 (2026-09-24)', 'advanced',
       s.gen || CASE WHEN x.write_in THEN '' ELSE ' and ' || s.can END || ': ' || x.full_name || ' ' || x.note
       || '. Seeded by CA_0281 (2026-09-24).', now(), now()
  FROM ca0281_new x
  CROSS JOIN ca0281_src s
  JOIN ca0281_race r ON r.position_name = x.position_name
  JOIN essentials.politicians p ON p.external_id = x.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- 3. The existing rows' results (Neal Jr. also becomes a write-in).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = u.result,
       is_write_in        = u.write_in,
       result_source      = s.can || ' and ' || s.gen || ': ' || u.full_name || ' ' || u.note
                            || '. Recorded by CA_0281 (2026-09-24).',
       result_recorded_at = now(),
       last_verified_at   = now(),
       updated_at         = now()
  FROM ca0281_upd u CROSS JOIN ca0281_src s
 WHERE rc.id = u.rc_id AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- 4. Redkey's stray CD1 row: not on that race's ballot (he ran in CD3).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET candidate_status   = 'active',
       result             = 'not_nominated',
       result_source      = 'Arizona Secretary of State, 2026 General Election candidate list (apps.arizona.vote/electioninfo/Election/69): David Redkey is not a CD1 candidate; he won the CD3 GRN primary as a write-in (Official Canvass, Jul 21 2026, p.2) and is on the CD3 November ballot (CA_0278). This CD1 row came from a pre-primary roster; 1457 marked it withdrawn, but he never withdrew. Recorded by CA_0281 (2026-09-24).',
       result_recorded_at = now(),
       last_verified_at   = now(),
       updated_at         = now()
 WHERE rc.id = '18e51e01-8977-4d8a-8728-49853bd6fe76' AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0281_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 5 THEN RAISE EXCEPTION 'POST: % of 5 new people are active non-incumbents on exactly one race', n; END IF;

  SELECT count(*) INTO n FROM ca0281_upd u JOIN essentials.race_candidates rc ON rc.id = u.rc_id
   WHERE rc.result = u.result AND rc.is_write_in = u.write_in
     AND rc.result_source LIKE '%Recorded by CA_0281 (2026-09-24).';
  IF n <> 28 THEN RAISE EXCEPTION 'POST: % of 28 existing rows carry their result', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.id = '18e51e01-8977-4d8a-8728-49853bd6fe76' AND rc.result = 'not_nominated'
     AND NOT essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n <> 1 THEN RAISE EXCEPTION 'POST: Redkey CD1 row not corrected'; END IF;

  FOR r IN
    SELECT c.position_name, c.expect, c.write_ins,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.is_write_in
               AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS wi,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.result IS NULL AND rc.candidate_status <> 'withdrawn') AS unresolved
      FROM ca0281_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: AZ % has % live candidates, expected %', r.position_name, r.got, r.expect; END IF;
    IF r.wi <> r.write_ins THEN RAISE EXCEPTION 'POST: AZ % has % live write-ins, expected %', r.position_name, r.wi, r.write_ins; END IF;
    IF r.unresolved <> 0 THEN RAISE EXCEPTION 'POST: AZ % still has % rows without a result', r.position_name, r.unresolved; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0281 applied: 7 AZ statewide November fields match the SOS list; Redkey CD1 row corrected';
END $$;

COMMIT;

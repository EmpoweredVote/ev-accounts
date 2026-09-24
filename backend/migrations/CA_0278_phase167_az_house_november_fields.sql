-- CA_0278_phase167_az_house_november_fields.sql
--
-- Slot CA_0278 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Phase 167 follow-up: Arizona. CA_0273 recorded the CD2 results from the primary canvass but kept
-- Curtis Goodwin flagged (rule 5): without Arizona's November list we could not rule out a candidate we
-- had no row for. The operator has now captured that list, and it covers all nine districts. The other
-- eight AZ November races had never been reconciled at all — every row still carried a NULL result, so
-- CD1 showed eight live candidates for a three-name ballot. This reconciles all nine.
--
-- Sources (both operator-supplied, 2026-09-24):
--   [GEN] Arizona Secretary of State, 2026 General Election candidate list
--         (apps.arizona.vote/electioninfo/Election/69, Federal tab; page captured by the operator
--         2026-09-24 — the site blocks scripted fetches).
--   [CAN] State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026;
--         20260806_Primary_Canvass.pdf, pages 1-3). Every not_nominated below lost that primary here.
--
-- November ballot per district, from [GEN] (write-ins excluded — see below):
--   CD1  Feely (REP), Shah (DEM), Alponte (LBT)       not_nominated: Chaplik, Trobough, Galán-Woods,
--                                                      McCartney, Treble
--   CD2  Crane (REP), Nez (DEM), Goodwin (LBT)        results already written by CA_0273; flag cleared
--   CD3  Ansari (DEM), Redkey (GRN), Aversa (NOL)     + David Redkey: NEW ROW for his existing politician
--                                                      (he won the GRN primary as a write-in, [CAN] p.2;
--                                                      our only row for him is a withdrawn CD1 row)
--   CD4  Jasser (REP), Stanton (DEM), Benoit (NOL)    not_nominated: Newkirk. Tisha Benoit's CD4 row was
--                                                      'withdrawn'; [CAN] has her winning the NOL primary
--                                                      (981) and [GEN] prints her, so it is REINSTATED:
--                                                      candidate_status 'active', result 'advanced'.
--   CD5  Lamb (REP), Lee (DEM)                         not_nominated: Keenan, Hualde, James
--   CD6  Ciscomani (REP), Mendoza (DEM), Peters (LBT), Swing (GRN)
--                                                      + Gary Swing: NEW PERSON (won the GRN primary as a
--                                                      write-in, [CAN] p.2). No existing row by that name.
--   CD7  Butierez (REP), Grijalva (DEM)
--   CD8  Hamadeh (REP), Greene-Placentia (DEM)         not_nominated: Keeler
--   CD9  Gosar (REP), Sterbinsky (DEM)
--
-- WRITE-INS ARE NOT SEEDED. [GEN] also lists seven registered November write-in candidates, each marked
-- "Write-In Candidate": Dev Gupta and Gage Dylan Thunder (CD1), Jacob Parkman (CD3), Steven Sanders
-- (CD4), Michael Dorland (CD6), G. Seville Hatch and William Perry (CD9). They are not printed on the
-- ballot, and a Phase 167 field is the printed ballot. Redkey and Swing were primary write-ins but are
-- printed in November (no write-in mark), so they are in.
--
-- NOT TOUCHED: the seven existing 'withdrawn' rows (Ajluni, Redkey CD1, Descheenie, Davison, Fillmore,
-- Bracht, Bah). None is live, and none is on the November ballot. John Fillmore's row says withdrawn
-- although [CAN] shows 519 NOL votes; either way he is not nominated and not live, so it is left as is.
--
-- BARE politician row for Swing, 1296 / CA_0276 style: external_id -66000320 (the next free number in
-- 1296's block at authoring — -66000319 was the last taken; the pre-flight refuses if it is taken by
-- someone else), is_incumbent = false stated explicitly, is_active = true. Losers keep is_active = true
-- (ruling 2026-09-24).
--
-- CI: Benoit's reinstatement changes her candidate_status. She holds no seat, so check-stance-sources
-- buckets her by her active race: her 2 PRIMARY_SITE_NO_PATH rows move from '-' to 'az'. The baseline in
-- the same PR moves those 2 (az 6 -> 8, '-' 55 -> 53) — measured by running the check's own query for
-- her id before authoring. Redkey carries 8 stance rows, but none is flagged by any check (same probe).
-- Every prod-reading CI check is run before and after the apply; merge only after the apply.
--
-- IDEMPOTENT: inserts by NOT EXISTS; result updates guarded on result IS NULL; Benoit guarded on
-- 'withdrawn'; flag clear on IS NOT NULL.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the two race_candidates rows whose source ends 'added by CA_0278
--   (2026-09-24)' and the politician -66000320; set result/result_source NULL on rows whose result_source
--   ends 'Recorded by CA_0278 (2026-09-24).' (Benoit: also candidate_status back to 'withdrawn');
--   restore provisional_until 2026-08-21 on Goodwin's row (a48d4bf8).

BEGIN;

CREATE TEMP TABLE ca0278_src ON COMMIT DROP AS
SELECT 'Arizona Secretary of State, 2026 General Election candidate list (apps.arizona.vote/electioninfo/Election/69, Federal tab; captured by the operator 2026-09-24)'::text AS gen,
       'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026; 20260806_Primary_Canvass.pdf pp.1-3)'::text AS can;

-- The nine races, and the live count each must hold afterwards (the printed November ballot).
CREATE TEMP TABLE ca0278_race ON COMMIT DROP AS
SELECT x.position_name, ra.id AS race_id, x.expect
  FROM (VALUES ('U.S. Representative District 1',3), ('U.S. Representative District 2',3),
               ('U.S. Representative District 3',3), ('U.S. Representative District 4',3),
               ('U.S. Representative District 5',2), ('U.S. Representative District 6',4),
               ('U.S. Representative District 7',2), ('U.S. Representative District 8',2),
               ('U.S. Representative District 9',2)) AS x(position_name, expect)
  JOIN essentials.elections e ON e.state = 'AZ' AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- Existing rows that need a result (by id + name, each with its disposition).
CREATE TEMP TABLE ca0278_upd ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('744200c2-21e4-4436-b8ca-8cdda2a59eb3'::uuid, 'Jay Feely',                   'advanced'),
  ('ea724c24-8f62-419d-8d44-b724c229a87c'::uuid, 'Amish Shah',                  'advanced'),
  ('5859efd0-34fe-43bf-949e-bc5359f04cd5'::uuid, 'Monica Alponte',              'advanced'),
  ('44f7faf4-648b-4a29-b6f5-e3393cb7ebdd'::uuid, 'Joseph Chaplik',              'not_nominated'),
  ('e2e5e743-fc68-47a5-803b-89f961aca5e8'::uuid, 'John Trobough',               'not_nominated'),
  ('4a85a809-e68e-43bf-aa0b-1c2f5a8bfa22'::uuid, 'Marlene Galán-Woods',         'not_nominated'),
  ('d1a86e38-a018-497e-a56d-fd2484b2ff3b'::uuid, 'Rick McCartney',              'not_nominated'),
  ('9d9dcff0-5d5b-414d-bbe2-6d8ed36e066e'::uuid, 'Jonathan Treble',             'not_nominated'),
  ('de1604fd-b4af-44c7-8b44-33d2c0c7df45'::uuid, 'Yassamin Ansari',             'advanced'),
  ('c3490d9f-24b3-4e0c-bedd-3a530c3ffb8b'::uuid, 'Alan Aversa',                 'advanced'),
  ('bd444d5b-e687-4b8e-a2fe-e9ee9157d31a'::uuid, 'Zuhdi Jasser',                'advanced'),
  ('9f7085a4-5608-4d44-973c-b92e40c50296'::uuid, 'Greg Stanton',                'advanced'),
  ('2a4219ee-f0c3-4103-8f88-ea57c36c9ac5'::uuid, 'Tisha Benoit',                'advanced'),
  ('6c694bd5-1875-4812-8226-079d5a868701'::uuid, 'Kai Newkirk',                 'not_nominated'),
  ('765d27b3-67b3-4be7-b73d-c8031863dade'::uuid, 'Mark Lamb',                   'advanced'),
  ('c36d3e3f-a998-4c00-bdf8-24323aa46895'::uuid, 'Elizabeth Lee',               'advanced'),
  ('d38431e3-beb2-406e-9290-5b244ecd4cb2'::uuid, 'Daniel Keenan',               'not_nominated'),
  ('17d7abeb-a4f5-41bc-809b-8511426bafdf'::uuid, 'Brian Hualde',                'not_nominated'),
  ('6cf82b21-b0bc-4488-8d97-4eb3e8a06d17'::uuid, 'Chris James',                 'not_nominated'),
  ('ab5f522b-7748-4b8e-9e23-c3250d1ae468'::uuid, 'Juan Ciscomani',              'advanced'),
  ('de76acb4-7388-425a-8400-6e39aa3924e2'::uuid, 'JoAnna Mendoza',              'advanced'),
  ('ba9d50dd-343c-4dde-8c92-cf2fd58d77fc'::uuid, 'Jereme Peters',               'advanced'),
  ('253874ea-6251-4890-856d-8d8a6529fbac'::uuid, 'Daniel Butierez',             'advanced'),
  ('87c7fc49-b43b-4b3f-bc3d-ede77cb5cfbf'::uuid, 'Adelita S. Grijalva',         'advanced'),
  ('f996989c-a01e-4a2d-bd77-1f3dda1cb5fe'::uuid, 'Abraham J. Hamadeh',          'advanced'),
  ('d7c90dec-e91d-49e9-8e8e-8f710b80855d'::uuid, 'Bernadette Greene-Placentia', 'advanced'),
  ('3cd0339c-5fee-4fd6-8a15-e6db4e7fe7ef'::uuid, 'Raymond Keeler',              'not_nominated'),
  ('44fb6bc9-ddf9-4fe2-834d-0694c5b449b4'::uuid, 'Paul A. Gosar',               'advanced'),
  ('52ec0d01-905c-484d-99cd-df28212e02be'::uuid, 'Danielle Sterbinsky',         'advanced')
) AS v(rc_id, full_name, result);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0278_race;
  IF n <> 9 THEN RAISE EXCEPTION 'PRE: resolved % of 9 AZ House races', n; END IF;

  -- The update rows are in these races, and untouched or already written by this file.
  SELECT count(*) INTO n FROM ca0278_upd u
    JOIN essentials.race_candidates rc ON rc.id = u.rc_id AND rc.full_name = u.full_name
    JOIN ca0278_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL OR (rc.result = u.result AND rc.result_source LIKE '%Recorded by CA_0278 (2026-09-24).');
  IF n <> 29 THEN RAISE EXCEPTION 'PRE: only % of 29 existing rows are as authored', n; END IF;

  -- Benoit is the one status change: withdrawn now, or already reinstated by this file.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.id = '2a4219ee-f0c3-4103-8f88-ea57c36c9ac5'
     AND (rc.candidate_status = 'withdrawn' OR rc.result_source LIKE '%Recorded by CA_0278 (2026-09-24).');
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: Tisha Benoit CD4 row is not as authored'; END IF;

  -- Nothing else in these races lacks a result, apart from withdrawn rows.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0278_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.id NOT IN (SELECT rc_id FROM ca0278_upd)
     AND coalesce(rc.source, '') NOT LIKE '%added by CA_0278 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed rows in the AZ House races', n; END IF;

  -- CD2: the only flagged row is Goodwin's (or none, once applied).
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0278_race r ON r.race_id = rc.race_id
   WHERE rc.provisional_until IS NOT NULL AND rc.id <> 'a48d4bf8-b07d-4ce8-bda5-6bd6b8b5c359';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % flagged rows other than Goodwin in the AZ House races', n; END IF;

  -- Redkey: the existing person, with no CD3 row yet (or only the one this file added).
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id = '919e5a66-f60c-4710-b684-29d2790fe4da' AND p.full_name = 'David Redkey';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: David Redkey politician row not found'; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0278_race r ON r.race_id = rc.race_id
   WHERE r.position_name = 'U.S. Representative District 3' AND rc.last_name IN ('Redkey', 'Swing')
     AND coalesce(rc.source, '') NOT LIKE '%added by CA_0278 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: Redkey already has a CD3 row'; END IF;

  -- Swing: no row in CD6, and no politician by that name.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0278_race r ON r.race_id = rc.race_id
   WHERE r.position_name = 'U.S. Representative District 6' AND rc.last_name = 'Swing'
     AND coalesce(rc.source, '') NOT LIKE '%added by CA_0278 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: Swing already has a CD6 row'; END IF;
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.last_name = 'Swing' AND p.first_name = 'Gary' AND p.external_id IS DISTINCT FROM -66000320;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: a Gary Swing politician already exists'; END IF;

  -- The external_id is free, or holds exactly the person this file created.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.external_id = -66000320 AND (p.full_name <> 'Gary Swing' OR p.source NOT LIKE 'CA_0278 (2026-09-24):%');
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: external_id -66000320 is taken by someone else'; END IF;

  RAISE NOTICE 'CA_0278 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. Gary Swing.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT -66000320, 'Gary', 'Swing', 'Gary Swing', 'Green', false, true,
       'CA_0278 (2026-09-24): ' || s.gen || ': U.S. Representative in Congress - District No. 6, SWING, GARY (GRN); '
       || s.can || ': (GRN) Gary Swing (Write-In) *, 29', 'manual'
  FROM ca0278_src s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = -66000320);

-- ---------------------------------------------------------------------------
-- 2. The two new November candidacies: Swing (CD6) and Redkey (CD3).
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source, result, result_source, result_recorded_at,
                                        last_verified_at)
SELECT r.race_id, p.id, x.full_name, x.first_name, x.last_name, false, 'active',
       s.gen || '; added by CA_0278 (2026-09-24)', 'advanced',
       s.gen || ' and ' || s.can || ': ' || x.note || '. On the November ballot; seeded by CA_0278 (2026-09-24).',
       now(), now()
  FROM (VALUES
          ('U.S. Representative District 6', 'Gary Swing',   'Gary',  'Swing',  NULL::uuid,
           'won the GRN primary as a write-in (29)'),
          ('U.S. Representative District 3', 'David Redkey', 'David', 'Redkey', '919e5a66-f60c-4710-b684-29d2790fe4da'::uuid,
           'won the GRN primary as a write-in (5)')
       ) AS x(position_name, full_name, first_name, last_name, pid, note)
  CROSS JOIN ca0278_src s
  JOIN ca0278_race r ON r.position_name = x.position_name
  JOIN essentials.politicians p ON p.id = coalesce(x.pid, (SELECT id FROM essentials.politicians WHERE external_id = -66000320))
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- 3. The existing rows' results. Benoit is also reinstated (withdrawn -> active).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = u.result,
       candidate_status   = CASE WHEN rc.id = '2a4219ee-f0c3-4103-8f88-ea57c36c9ac5' THEN 'active' ELSE rc.candidate_status END,
       result_source      = CASE WHEN u.result = 'advanced'
                                 THEN s.gen || ': ' || u.full_name || ' is on the November ballot'
                                 ELSE s.can || ': ' || u.full_name || ' lost the primary; not on ' || s.gen END
                            || CASE WHEN rc.id = '2a4219ee-f0c3-4103-8f88-ea57c36c9ac5'
                                    THEN ' (won the NOL primary, 981, in ' || s.can || '; the earlier withdrawn status is superseded)'
                                    ELSE '' END
                            || '. Recorded by CA_0278 (2026-09-24).',
       result_recorded_at = now(),
       last_verified_at   = now(),
       updated_at         = now()
  FROM ca0278_upd u CROSS JOIN ca0278_src s
 WHERE rc.id = u.rc_id AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- 4. All nine fields are complete: clear Goodwin's flag (rule 5 released).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET provisional_until = NULL, last_verified_at = now(), updated_at = now()
  FROM ca0278_race r
 WHERE rc.race_id = r.race_id AND rc.provisional_until IS NOT NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.external_id = -66000320 AND p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'POST: Gary Swing is not an active non-incumbent on exactly one race'; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.source LIKE '%added by CA_0278 (2026-09-24)' AND rc.result = 'advanced' AND rc.candidate_status = 'active';
  IF n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 new candidacies present', n; END IF;

  SELECT count(*) INTO n FROM ca0278_upd u JOIN essentials.race_candidates rc ON rc.id = u.rc_id
   WHERE rc.result = u.result AND rc.result_source LIKE '%Recorded by CA_0278 (2026-09-24).';
  IF n <> 29 THEN RAISE EXCEPTION 'POST: % of 29 existing rows carry their result', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.id = '2a4219ee-f0c3-4103-8f88-ea57c36c9ac5' AND rc.candidate_status = 'active';
  IF n <> 1 THEN RAISE EXCEPTION 'POST: Tisha Benoit not reinstated'; END IF;

  FOR r IN
    SELECT c.position_name, c.expect,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.provisional_until IS NOT NULL) AS flagged,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.result IS NULL AND rc.candidate_status <> 'withdrawn') AS unresolved
      FROM ca0278_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: AZ % has % live candidates, expected %', r.position_name, r.got, r.expect; END IF;
    IF r.flagged <> 0 THEN RAISE EXCEPTION 'POST: AZ % still has % flagged rows', r.position_name, r.flagged; END IF;
    IF r.unresolved <> 0 THEN RAISE EXCEPTION 'POST: AZ % still has % rows without a result', r.position_name, r.unresolved; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0278 applied: all 9 AZ House November fields match the SOS list; no AZ House row flagged';
END $$;

COMMIT;

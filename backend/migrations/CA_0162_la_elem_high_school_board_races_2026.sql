-- CA_0162_la_elem_high_school_board_races_2026.sql
-- Seed the Nov 3 2026 governing-board contests of the LA-County ELEMENTARY and HIGH-SCHOOL districts, so an
-- address in one of them returns its school-board contest. REQUIRES CA_0158 (verified boards seated) and
-- CA_0161 (trustee-area geography) to be applied first.
--
-- SCOPE: 30 of the 31 boards CA_0158 refreshed -- 22 by trustee area (66 contests, one seat each, bound to
-- the area's seat from CA_0161) and 8 at large (one 3-seat contest each, bound to the lowest-id seat on the
-- whole-district row -- the CA_0142 pattern). GORMAN JOINT has no race: LACOE Bulletin 7112 lists one
-- at-large seat for Nov 2026, but no candidate filed (it is on neither RR/CC list), so the board appoints.
-- SEATS = LACOE Informational Bulletin 7112 (2026-04-02), Attachment 3. KEPPEL is listed "At-Large" there
-- but the Registrar runs it by Trustee Area 1/2/3 (its first by-area cycle for the 2022 at-large seats), so
-- the Registrar's contests are used -- as CA_0142 did for Montebello. LITTLE LAKE also has a special
-- election for the rest of the Trustee Area 5 term (to Dec 12 2028), bound to that vacant seat.
--
-- CANDIDATES = the LA County Registrar-Recorder's Nov 3 2026 candidate list (lavote.gov/Apps/CandidateList/
-- Index?id=4348, read 2026-09-22), ONLY those whose nomination papers were FILED (the list also carries
-- people who only took papers out; 11 such names are excluded, e.g. Maritza Nieves -- the Los Nietos TA4
-- incumbent did not file -- Veronika Dean, Joshua Stiles, Kenny Arroyo, Dev Shah). Names are the ballot names
-- re-cased from the Registrar's upper case; occupational_designation = the ballot designation.
-- is_incumbent = the Registrar's INC flag (E elected / A appointed); all 78 are linked to the politician row
-- seated on that board by CA_0158. Contests with no more candidates than seats are INCLUDED (decision
-- 2026-09-22: show uncontested seats too). Two incumbents meet in Palmdale Trustee Area 1: Nancy Smith and
-- Ralph Velador, both elected at large in 2022, live in the same new area -- the only race with more
-- incumbents than seats.
--   Antelope Valley Joint Union High School Board - Trustee Area 1                         1 seat(s) 2 cand(s) 0 inc
--   Antelope Valley Joint Union High School Board - Trustee Area 4                         1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Antelope Valley Joint Union High School Board - Trustee Area 5                         1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Castaic Union School Board - Trustee Area B                                            1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Castaic Union School Board - Trustee Area D                                            1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Castaic Union School Board - Trustee Area E                                            1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Centinela Valley Union High School Board - Trustee Area 1                              1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Centinela Valley Union High School Board - Trustee Area 2                              1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Centinela Valley Union High School Board - Trustee Area 5                              1 seat(s) 1 cand(s) 1 inc (uncontested)
--   East Whittier City School Board - Trustee Area 1                                       1 seat(s) 2 cand(s) 1 inc
--   East Whittier City School Board - Trustee Area 3                                       1 seat(s) 2 cand(s) 1 inc
--   East Whittier City School Board - Trustee Area 4                                       1 seat(s) 2 cand(s) 1 inc
--   Eastside Union School Board - Trustee Area 1                                           1 seat(s) 3 cand(s) 1 inc
--   Eastside Union School Board - Trustee Area 3                                           1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Eastside Union School Board - Trustee Area 5                                           1 seat(s) 2 cand(s) 1 inc
--   El Monte City School Board                                                             3 seat(s) 3 cand(s) 3 inc (uncontested)
--   El Monte Union High School Board - Trustee Area 3                                      1 seat(s) 2 cand(s) 1 inc
--   El Monte Union High School Board - Trustee Area 4                                      1 seat(s) 2 cand(s) 1 inc
--   El Monte Union High School Board - Trustee Area 5                                      1 seat(s) 2 cand(s) 1 inc
--   Garvey School Board - Trustee Area 1                                                   1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Garvey School Board - Trustee Area 3                                                   1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Garvey School Board - Trustee Area 5                                                   1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Hawthorne School Board                                                                 3 seat(s) 3 cand(s) 2 inc (uncontested)
--   Hermosa Beach City School Board                                                        3 seat(s) 3 cand(s) 1 inc (uncontested)
--   Hughes-Elizabeth Lakes Union School Board - Trustee Area 1                             1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Hughes-Elizabeth Lakes Union School Board - Trustee Area 2                             1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Hughes-Elizabeth Lakes Union School Board - Trustee Area 5                             1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Keppel Union School Board - Trustee Area 1                                             1 seat(s) 2 cand(s) 1 inc
--   Keppel Union School Board - Trustee Area 2                                             1 seat(s) 2 cand(s) 1 inc
--   Keppel Union School Board - Trustee Area 3                                             1 seat(s) 2 cand(s) 1 inc
--   Lancaster School Board - Trustee Area 2                                                1 seat(s) 2 cand(s) 1 inc
--   Lancaster School Board - Trustee Area 4                                                1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Lancaster School Board - Trustee Area 5                                                1 seat(s) 2 cand(s) 1 inc
--   Lawndale Elementary School Board - Trustee Area 1                                      1 seat(s) 2 cand(s) 1 inc
--   Lawndale Elementary School Board - Trustee Area 2                                      1 seat(s) 2 cand(s) 1 inc
--   Lawndale Elementary School Board - Trustee Area 4                                      1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Lennox School Board                                                                    3 seat(s) 4 cand(s) 2 inc
--   Little Lake City School Board - Trustee Area 1                                         1 seat(s) 2 cand(s) 0 inc
--   Little Lake City School Board - Trustee Area 2                                         1 seat(s) 2 cand(s) 0 inc
--   Little Lake City School Board - Trustee Area 5 (Unexpired Term Ending December 12, 202 1 seat(s) 2 cand(s) 0 inc
--   Los Nietos School Board - Trustee Area 2                                               1 seat(s) 2 cand(s) 1 inc
--   Los Nietos School Board - Trustee Area 4                                               1 seat(s) 1 cand(s) 0 inc (uncontested)
--   Los Nietos School Board - Trustee Area 5                                               1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Mountain View School Board                                                             3 seat(s) 5 cand(s) 3 inc
--   Newhall School Board - Trustee Area 1                                                  1 seat(s) 1 cand(s) 0 inc (uncontested)
--   Newhall School Board - Trustee Area 2                                                  1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Newhall School Board - Trustee Area 3                                                  1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Palmdale School Board - Trustee Area 1                                                 1 seat(s) 2 cand(s) 2 inc
--   Palmdale School Board - Trustee Area 3                                                 1 seat(s) 2 cand(s) 0 inc
--   Palmdale School Board - Trustee Area 5                                                 1 seat(s) 2 cand(s) 1 inc
--   Rosemead School Board                                                                  3 seat(s) 3 cand(s) 3 inc (uncontested)
--   Saugus Union School Board - Trustee Area 1                                             1 seat(s) 3 cand(s) 0 inc
--   Saugus Union School Board - Trustee Area 2                                             1 seat(s) 2 cand(s) 1 inc
--   Saugus Union School Board - Trustee Area 5                                             1 seat(s) 2 cand(s) 1 inc
--   South Whittier School Board - Trustee Area 1                                           1 seat(s) 1 cand(s) 1 inc (uncontested)
--   South Whittier School Board - Trustee Area 2                                           1 seat(s) 1 cand(s) 1 inc (uncontested)
--   South Whittier School Board - Trustee Area 5                                           1 seat(s) 2 cand(s) 1 inc
--   Sulphur Springs Union School Board - Trustee Area 3                                    1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Sulphur Springs Union School Board - Trustee Area 4                                    1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Sulphur Springs Union School Board - Trustee Area 5                                    1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Valle Lindo School Board                                                               3 seat(s) 4 cand(s) 3 inc
--   Westside Union School Board                                                            3 seat(s) 4 cand(s) 3 inc
--   Whittier City School Board - Trustee Area 3                                            1 seat(s) 2 cand(s) 1 inc
--   Whittier City School Board - Trustee Area 4                                            1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Whittier City School Board - Trustee Area 5                                            1 seat(s) 2 cand(s) 1 inc
--   Whittier Union High School Board - Trustee Area 1                                      1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Whittier Union High School Board - Trustee Area 4                                      1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Whittier Union High School Board - Trustee Area 5                                      1 seat(s) 2 cand(s) 1 inc
--   William S. Hart Union High School Board - Trustee Area 2                               1 seat(s) 2 cand(s) 0 inc
--   William S. Hart Union High School Board - Trustee Area 3                               1 seat(s) 1 cand(s) 1 inc (uncontested)
--   William S. Hart Union High School Board - Trustee Area 5                               1 seat(s) 2 cand(s) 1 inc
--   Wilsona School Board - Trustee Area 1                                                  1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Wilsona School Board - Trustee Area 2                                                  1 seat(s) 1 cand(s) 1 inc (uncontested)
--   Wilsona School Board - Trustee Area 3                                                  1 seat(s) 1 cand(s) 1 inc (uncontested)
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14); nonpartisan -> primary_party
-- NULL; party is never stored on candidates.
--
-- ROLLBACK: DELETE FROM essentials.races WHERE election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14' AND
--   position_name IN (the 74 in _race) -- race_candidates cascade.
--
-- IDEMPOTENT: races on (election_id, position_name); candidates on (race_id, lower(full_name)).
-- ===================================================================================================

BEGIN;

CREATE TEMP TABLE _race (position_name text PRIMARY KEY, parent_geo text, bind_geo text, bind_office uuid, seats int, rrcc_contest text) ON COMMIT DROP;
INSERT INTO _race VALUES
  ('Antelope Valley Joint Union High School Board - Trustee Area 1','0602820','0602820-ta-1','c6ff47cb-aa1e-48d0-84e0-118b802d215d',1,'ANTELOPE VALLEY JOINT UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Antelope Valley Joint Union High School Board - Trustee Area 4','0602820','0602820-ta-4','955d3a0a-60e8-4e2b-a389-0dc097edd092',1,'ANTELOPE VALLEY JOINT UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Antelope Valley Joint Union High School Board - Trustee Area 5','0602820','0602820-ta-5','b071d0ff-5bce-410d-bfb9-fb25246c6618',1,'ANTELOPE VALLEY JOINT UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Castaic Union School Board - Trustee Area B','0607740','0607740-ta-b','d673dbbc-47b5-41f5-b4c5-1a54b2feef2f',1,'CASTAIC UNION SCHOOL DISTRICT Governing Board Member, Trustee Area B'),
  ('Castaic Union School Board - Trustee Area D','0607740','0607740-ta-d','f5a4bfa6-184e-49e8-9618-6c339fa9c3f2',1,'CASTAIC UNION SCHOOL DISTRICT Governing Board Member, Trustee Area D'),
  ('Castaic Union School Board - Trustee Area E','0607740','0607740-ta-e','5bb14f72-c6f8-4e3d-a11b-00b233b30312',1,'CASTAIC UNION SCHOOL DISTRICT Governing Board Member, Trustee Area E'),
  ('Centinela Valley Union High School Board - Trustee Area 1','0607920','0607920-ta-1','eac642a5-df3e-4e3b-b47f-e1ee738b0824',1,'CENTINELA VALLEY UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Centinela Valley Union High School Board - Trustee Area 2','0607920','0607920-ta-2','6245bff0-ee6a-4991-8792-09a35ad63290',1,'CENTINELA VALLEY UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Centinela Valley Union High School Board - Trustee Area 5','0607920','0607920-ta-5','90db7b74-576a-44fb-acda-b0b9009e7c70',1,'CENTINELA VALLEY UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('East Whittier City School Board - Trustee Area 1','0611850','0611850-ta-1','15d31bfd-6619-46cf-acbc-6e58108cc2e3',1,'EAST WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('East Whittier City School Board - Trustee Area 3','0611850','0611850-ta-3','82312751-ab96-4125-a208-89fca4209a34',1,'EAST WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('East Whittier City School Board - Trustee Area 4','0611850','0611850-ta-4','936eac79-3ddb-42d3-9511-748bb5e92257',1,'EAST WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Eastside Union School Board - Trustee Area 1','0611910','0611910-ta-1','68b215cd-78fe-5162-845d-230e4e8d6ff4',1,'EASTSIDE UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Eastside Union School Board - Trustee Area 3','0611910','0611910-ta-3','89ce3183-4fe6-4c74-b174-d65cb4f35a29',1,'EASTSIDE UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Eastside Union School Board - Trustee Area 5','0611910','0611910-ta-5','01407d0b-414e-4ff4-b09d-30f36442dc6c',1,'EASTSIDE UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('El Monte City School Board','0612090','0612090',NULL,3,'EL MONTE CITY SCHOOL DISTRICT Governing Board Member'),
  ('El Monte Union High School Board - Trustee Area 3','0612120','0612120-ta-3','e0f71367-f495-4abd-8e28-d25fefa1c38d',1,'EL MONTE UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('El Monte Union High School Board - Trustee Area 4','0612120','0612120-ta-4','23a252ac-7eed-4304-9ef4-ed388a7771e5',1,'EL MONTE UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('El Monte Union High School Board - Trustee Area 5','0612120','0612120-ta-5','ebe4748c-0189-4d6a-a0cc-c0b83a7458a6',1,'EL MONTE UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Garvey School Board - Trustee Area 1','0614940','0614940-ta-1','17fc9282-419e-4d49-95f2-182abce3f7bd',1,'GARVEY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Garvey School Board - Trustee Area 3','0614940','0614940-ta-3','2a138c9d-d32e-43fc-885f-02a2aabee3f6',1,'GARVEY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Garvey School Board - Trustee Area 5','0614940','0614940-ta-5','f1fab2ab-232e-4cfa-8620-fc2c3515d4ce',1,'GARVEY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Hawthorne School Board','0616680','0616680',NULL,3,'HAWTHORNE SCHOOL DISTRICT Governing Board Member'),
  ('Hermosa Beach City School Board','0617040','0617040',NULL,3,'HERMOSA BEACH CITY SCHOOL DISTRICT Governing Board Member'),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 1','0617880','0617880-ta-1','05e4d7ac-b5c9-4aee-b95d-dd975004a825',1,'HUGHES-ELIZABETH LAKES UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 2','0617880','0617880-ta-2','fed881cc-3877-451f-a9a2-683cb213cf94',1,'HUGHES-ELIZABETH LAKES UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 5','0617880','0617880-ta-5','7fe3c13b-7cc4-5e33-8f59-815485de9c17',1,'HUGHES-ELIZABETH LAKES UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Keppel Union School Board - Trustee Area 1','0619440','0619440-ta-1','5a324f42-6909-50f4-be0b-698effa6e03d',1,'KEPPEL UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Keppel Union School Board - Trustee Area 2','0619440','0619440-ta-2','eab4164e-3589-5825-a4a3-00743cce6af5',1,'KEPPEL UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Keppel Union School Board - Trustee Area 3','0619440','0619440-ta-3','b9a38fda-67cd-5c87-822b-e8daf695d251',1,'KEPPEL UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Lancaster School Board - Trustee Area 2','0620880','0620880-ta-2','548d38e0-55cf-40e7-b803-2a1341a54312',1,'LANCASTER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Lancaster School Board - Trustee Area 4','0620880','0620880-ta-4','4e651b41-ba63-4921-a8f8-64e2c62e4ce5',1,'LANCASTER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Lancaster School Board - Trustee Area 5','0620880','0620880-ta-5','ce7ad338-cc7f-4fac-bf9f-181b33ae5ca2',1,'LANCASTER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Lawndale Elementary School Board - Trustee Area 1','0621210','0621210-ta-1','099eecaf-9190-4e83-878b-8aba5a695749',1,'LAWNDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Lawndale Elementary School Board - Trustee Area 2','0621210','0621210-ta-2','57d5e5d7-2266-419b-ac61-1f1316e57485',1,'LAWNDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Lawndale Elementary School Board - Trustee Area 4','0621210','0621210-ta-4','466a3b7d-0caa-4f9d-8405-708804d2cfa4',1,'LAWNDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Lennox School Board','0621420','0621420',NULL,3,'LENNOX SCHOOL DISTRICT Governing Board Member'),
  ('Little Lake City School Board - Trustee Area 1','0621930','0621930-ta-1','5b68a7cc-24b3-4c50-a680-f84cc22bf8f7',1,'LITTLE LAKE CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Little Lake City School Board - Trustee Area 2','0621930','0621930-ta-2','206c06a9-3414-4c57-b2ae-11a0467e571f',1,'LITTLE LAKE CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Little Lake City School Board - Trustee Area 5 (Unexpired Term Ending December 12, 2028)','0621930','0621930-ta-5','be269633-0bb3-4d19-a57e-9e5226dba12c',1,'LITTLE LAKE CITY SCHOOL DISTRICT SPECIAL ELECTION Governing Board Member, Trustee Area No. 5 (Unexpired term ending December 12, 2028)'),
  ('Los Nietos School Board - Trustee Area 2','0622890','0622890-ta-2','ca770ab5-cb99-4279-98f0-3e04e5677d68',1,'LOS NIETOS SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Los Nietos School Board - Trustee Area 4','0622890','0622890-ta-4','5d6c83e8-721c-4a68-93ab-844a4d617dfc',1,'LOS NIETOS SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Los Nietos School Board - Trustee Area 5','0622890','0622890-ta-5','aafb5ed7-f658-47f5-9376-aa76bc0d668e',1,'LOS NIETOS SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Mountain View School Board','0626190','0626190',NULL,3,'MOUNTAIN VIEW SCHOOL DISTRICT Governing Board Member'),
  ('Newhall School Board - Trustee Area 1','0627180','0627180-ta-1','b53f0e78-928b-4677-bb10-a9a6085d79f1',1,'NEWHALL SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Newhall School Board - Trustee Area 2','0627180','0627180-ta-2','082dc9f0-d88e-43cd-8f3d-68f836901447',1,'NEWHALL SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Newhall School Board - Trustee Area 3','0627180','0627180-ta-3','da853ec8-4d7a-42be-a419-c98a1197ca9d',1,'NEWHALL SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Palmdale School Board - Trustee Area 1','0629580','0629580-ta-1','b9fb6aae-0612-58dd-b3b3-44bf5ebdaf2a',1,'PALMDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Palmdale School Board - Trustee Area 3','0629580','0629580-ta-3','67b90ecb-63ae-55a7-ba85-246091631d66',1,'PALMDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Palmdale School Board - Trustee Area 5','0629580','0629580-ta-5','e509a63d-9cee-53a8-9afd-296cb717669d',1,'PALMDALE SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Rosemead School Board','0633570','0633570',NULL,3,'ROSEMEAD SCHOOL DISTRICT Governing Board Member'),
  ('Saugus Union School Board - Trustee Area 1','0635970','0635970-ta-1','9d264e21-571e-477b-bce5-3ebaa60e4ed8',1,'SAUGUS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Saugus Union School Board - Trustee Area 2','0635970','0635970-ta-2','e2ca6246-1dae-43ed-81a1-e0ea42cdc202',1,'SAUGUS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Saugus Union School Board - Trustee Area 5','0635970','0635970-ta-5','c44b3d8b-18b2-5ff8-9765-4c8d21e28b1a',1,'SAUGUS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('South Whittier School Board - Trustee Area 1','0637560','0637560-ta-1','974a5638-0aec-4f36-b413-d8dfee2119e9',1,'SOUTH WHITTIER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('South Whittier School Board - Trustee Area 2','0637560','0637560-ta-2','21bafe9c-c44a-4c43-add7-7d9dd0dc211e',1,'SOUTH WHITTIER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('South Whittier School Board - Trustee Area 5','0637560','0637560-ta-5','93b3e1ff-33a9-4dcc-8d26-cea444f07334',1,'SOUTH WHITTIER SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Sulphur Springs Union School Board - Trustee Area 3','0638220','0638220-ta-3','ec1e490c-6ce7-4b7a-924c-be2fa974cc7a',1,'SULPHUR SPRINGS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Sulphur Springs Union School Board - Trustee Area 4','0638220','0638220-ta-4','1b70d3d4-d3b6-4aa8-934e-91812be9ff08',1,'SULPHUR SPRINGS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Sulphur Springs Union School Board - Trustee Area 5','0638220','0638220-ta-5','b3349ce4-1d63-439f-be50-eb0ae9eac959',1,'SULPHUR SPRINGS UNION SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Valle Lindo School Board','0640650','0640650',NULL,3,'VALLE LINDO SCHOOL DISTRICT Governing Board Member'),
  ('Westside Union School Board','0642120','0642120',NULL,3,'WESTSIDE UNION SCHOOL DISTRICT Governing Board Member'),
  ('Whittier City School Board - Trustee Area 3','0642450','0642450-ta-3','2f8d919a-3b94-46b9-96cc-a3cc27e075ef',1,'WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('Whittier City School Board - Trustee Area 4','0642450','0642450-ta-4','29f8892a-3f92-4fce-a4a9-7e1fb40603e9',1,'WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Whittier City School Board - Trustee Area 5','0642450','0642450-ta-5','e54393ad-c9e1-47db-9ca6-e8e1d620af25',1,'WHITTIER CITY SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Whittier Union High School Board - Trustee Area 1','0642480','0642480-ta-1','42248683-bf61-4754-a9f0-daabe7f78741',1,'WHITTIER UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Whittier Union High School Board - Trustee Area 4','0642480','0642480-ta-4','099677aa-53f4-4714-b408-b82189203bc5',1,'WHITTIER UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 4'),
  ('Whittier Union High School Board - Trustee Area 5','0642480','0642480-ta-5','fac57bb5-e0e5-4f28-8b9e-2bdcdda4be21',1,'WHITTIER UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('William S. Hart Union High School Board - Trustee Area 2','0642510','0642510-ta-2','76ba2797-ae0e-454a-bff5-2df6d8b3e482',1,'WILLIAM S. HART UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('William S. Hart Union High School Board - Trustee Area 3','0642510','0642510-ta-3','c4159526-076e-4cb8-9845-b2b1e9f9aab2',1,'WILLIAM S. HART UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3'),
  ('William S. Hart Union High School Board - Trustee Area 5','0642510','0642510-ta-5','d1152eb6-ddeb-4067-bea2-f9d5312c5252',1,'WILLIAM S. HART UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 5'),
  ('Wilsona School Board - Trustee Area 1','0642810','0642810-ta-1','2df78c91-3f8b-58cb-bcf2-38120ecebcee',1,'WILSONA SCHOOL DISTRICT Governing Board Member, Trustee Area No. 1'),
  ('Wilsona School Board - Trustee Area 2','0642810','0642810-ta-2','5cdadc12-668f-4616-85f8-2f244481500c',1,'WILSONA SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2'),
  ('Wilsona School Board - Trustee Area 3','0642810','0642810-ta-3','4f7c7b15-69b8-4bb7-aef2-fa97c50348a6',1,'WILSONA SCHOOL DISTRICT Governing Board Member, Trustee Area No. 3');

CREATE TEMP TABLE _cand (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean, politician_id uuid, designation text) ON COMMIT DROP;
INSERT INTO _cand VALUES
  ('Antelope Valley Joint Union High School Board - Trustee Area 1','Ben Berk','Ben','Berk',false,NULL,'Father/Business Owner'),
  ('Antelope Valley Joint Union High School Board - Trustee Area 1','Sylvia P. Williams','Sylvia','Williams',false,NULL,'Community Advocate/Mother'),
  ('Antelope Valley Joint Union High School Board - Trustee Area 4','Carla Corona','Carla','Corona',true,'6075a347-8818-5ec4-ad08-9a20518aa22b','Governing Board Member, Antelope Valley Joint Union High School District'),
  ('Antelope Valley Joint Union High School Board - Trustee Area 5','Miguel Sanchez IV','Miguel','Sanchez',true,'46a41762-434e-506a-bf5e-c003c3ab828c','Governing Board Member'),
  ('Castaic Union School Board - Trustee Area B','Laura Pearson','Laura','Pearson',true,'c8dace65-f8ae-5032-a2b7-4757a821a178','Incumbent'),
  ('Castaic Union School Board - Trustee Area D','Vincent Titiriga','Vincent','Titiriga',true,'d3243df7-a7b5-5f42-b277-c51b468e303e','Incumbent'),
  ('Castaic Union School Board - Trustee Area E','Mayreen Burk','Mayreen','Burk',true,'02890a06-5e9e-550f-9812-1c2af9992041','Business Owner'),
  ('Centinela Valley Union High School Board - Trustee Area 1','Marisela Ruiz','Marisela','Ruiz',true,'fd6ce9a2-b7ef-52cb-8079-5428ad39cdab','Incumbent'),
  ('Centinela Valley Union High School Board - Trustee Area 2','Hugo M. Rojas','Hugo','Rojas',true,'148e431d-7313-47cc-ae4f-aadba0f7f33e','School Board President'),
  ('Centinela Valley Union High School Board - Trustee Area 5','Estefany Alejandra Castaneda','Estefany','Castaneda',true,'1d2f9313-f72f-5595-89a8-f41faa903db9','Boardmember/Labor Organizer'),
  ('East Whittier City School Board - Trustee Area 1','Lisa Michelle Dabbs','Lisa','Dabbs',true,'e73183bb-8ab6-5678-8f4b-08aec556c5cb','Governing Board Member, East Whittier City School District'),
  ('East Whittier City School Board - Trustee Area 1','Brenda Smith','Brenda','Smith',false,NULL,'Teacher'),
  ('East Whittier City School Board - Trustee Area 3','Christine Chacon Kennedy','Christine','Kennedy',true,'f71bc6eb-b367-52eb-8f5c-e2daf96add10','Incumbent'),
  ('East Whittier City School Board - Trustee Area 3','Michael Ramos','Michael','Ramos',false,NULL,'Phone:
                                 (562) 632-6202'),
  ('East Whittier City School Board - Trustee Area 4','Thomas Baird','Thomas','Baird',true,'4b0e7873-6534-5f9b-be74-db2d055874c6','Appointed Incumbent'),
  ('East Whittier City School Board - Trustee Area 4','Miguel Angel Hernandez Jr.','Miguel','Hernandez',false,NULL,'Law Enforcement Officer'),
  ('Eastside Union School Board - Trustee Area 1','Wayne M. Kalliomaa','Wayne','Kalliomaa',true,'5c7c3ea2-02ed-5f35-8651-e7fd7e14deeb','Appointed Incumbent'),
  ('Eastside Union School Board - Trustee Area 1','Oscar Mejia','Oscar','Mejia',false,NULL,'Aerospace Engineer Manager'),
  ('Eastside Union School Board - Trustee Area 1','Timothy M. Wiley','Timothy','Wiley',false,NULL,'Retired College Administrator'),
  ('Eastside Union School Board - Trustee Area 3','Roger L. Price','Roger','Price',true,'19c3b72e-2b96-5e30-b58f-db7869af2ac7','Appointed Governing Board Member, Eastside Union School District'),
  ('Eastside Union School Board - Trustee Area 5','Julie Ann Bookman','Julie','Bookman',true,'66a52dda-274d-5998-b51a-0bf59b74e11e','Governing Board Member'),
  ('Eastside Union School Board - Trustee Area 5','Anouk Harvey','Anouk','Harvey',false,NULL,'Teacher/Deputy Mayor'),
  ('El Monte City School Board','Lisette Mendez Garcia','Lisette','Garcia',true,'2da3e36f-45e0-5591-a5ae-ea1dce87c5d0','School Psychologist'),
  ('El Monte City School Board','Cesar Peralta','Cesar','Peralta',true,'254e533d-d131-5b34-9027-99a81f545b88','Incumbent'),
  ('El Monte City School Board','Elizabeth "Beth" Rivas','Elizabeth','Rivas',true,'e169f9e9-8f81-52f6-94e1-ecf5f08ebeeb','Incumbent'),
  ('El Monte Union High School Board - Trustee Area 3','Qui Nguyen','Qui','Nguyen',true,'2721420f-8032-5e4d-bee4-bc6795ac3b22','Governing Board Member, El Monte Union High School District'),
  ('El Monte Union High School Board - Trustee Area 3','Kristy Socorro Rowe','Kristy','Rowe',false,NULL,'Special Education Advocate'),
  ('El Monte Union High School Board - Trustee Area 4','Florencio Briones','Florencio','Briones',true,'5e847174-1790-5c61-8bc6-829da06f507e','Governing Board Member, El Monte Union High School District'),
  ('El Monte Union High School Board - Trustee Area 4','Jacqueline Yvette Castañon','Jacqueline','Castañon',false,NULL,'Educator'),
  ('El Monte Union High School Board - Trustee Area 5','Ricardo Padilla','Ricardo','Padilla',true,'a64f8955-568d-5818-bc85-b95cb179b820','Educator/Counselor'),
  ('El Monte Union High School Board - Trustee Area 5','Raul Pardo','Raul','Pardo',false,NULL,'Longshoreman'),
  ('Garvey School Board - Trustee Area 1','Andrew Justin Yam','Andrew','Yam',true,'378cba56-08f7-5bba-ba64-22c1f515cfb7','School Board President'),
  ('Garvey School Board - Trustee Area 3','Ronald B. Trabanino','Ronald','Trabanino',true,'dd2eccee-d3d8-5198-884d-c0758beb3b20',NULL),
  ('Garvey School Board - Trustee Area 5','Paul M. Duran','Paul','Duran',true,'ada9a7d8-259e-5bbc-be3c-a9c911478e3e','Incumbent'),
  ('Hawthorne School Board','Luciano Aguilar','Luciano','Aguilar',true,'54a7eed3-9757-56a8-a493-5cdd4f1370a6','Incumbent'),
  ('Hawthorne School Board','Yaquelin "Ms. Yaquie" Amador','Yaquelin','Amador',false,NULL,'Parent/Paraeducator'),
  ('Hawthorne School Board','Eugene Krank','Eugene','Krank',true,'43667ed4-9a14-5c58-a2ae-d6667f241ba6','Governing Board Member, Hawthorne School District'),
  ('Hermosa Beach City School Board','Jen Cole','Jen','Cole',true,'1a98aa19-6dc0-5a11-8ebd-3a252517f21b','Incumbent'),
  ('Hermosa Beach City School Board','Belinda L. Oakes','Belinda','Oakes',false,NULL,'Chief Financial Officer'),
  ('Hermosa Beach City School Board','Lisa Vargas Gardner','Lisa','Gardner',false,NULL,'School Compliance Specialist'),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 1','Terri A. Moss','Terri','Moss',true,'33587b77-1b7d-5c6b-ae0f-f811932a027a',NULL),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 2','Raelyn Marshall','Raelyn','Marshall',true,'e4685a86-a0a7-5f9f-8a3d-53cf1865ab1e','Appointed Incumbent'),
  ('Hughes-Elizabeth Lakes Union School Board - Trustee Area 5','Lola J. Skelton','Lola','Skelton',true,'40829ed9-4fed-5563-83b9-87750b90777f','Incumbent'),
  ('Keppel Union School Board - Trustee Area 1','Karina Martinez','Karina','Martinez',false,NULL,NULL),
  ('Keppel Union School Board - Trustee Area 1','Blanca Nava','Blanca','Nava',true,'c8730086-8ef0-586d-9b72-4c0a791edf3c','School Board Vice-President'),
  ('Keppel Union School Board - Trustee Area 2','Matthew Gaines','Matthew','Gaines',false,NULL,'Political Director/Parent'),
  ('Keppel Union School Board - Trustee Area 2','Alma I. Rodriguez','Alma','Rodriguez',true,'e1b27b2b-f039-5e7c-b2b1-9668e37963e7','Incumbent'),
  ('Keppel Union School Board - Trustee Area 3','Ana Laura Quiles','Ana','Quiles',false,NULL,NULL),
  ('Keppel Union School Board - Trustee Area 3','Andrew Ramirez','Andrew','Ramirez',true,'7d6c98b7-a053-55ec-b206-5fdd9d29bebd','Governing Board Member, Keppel Union School District'),
  ('Lancaster School Board - Trustee Area 2','Oscar Iraheta','Oscar','Iraheta',false,NULL,'Father/Community Leader'),
  ('Lancaster School Board - Trustee Area 2','Duane G. Winn','Duane','Winn',true,'a47b7e2f-241c-500c-9f2e-2919ae63010a','Incumbent'),
  ('Lancaster School Board - Trustee Area 4','Jullie A. Eutsler','Jullie','Eutsler',true,'ca090dea-fe42-598d-b90d-1cf441b83bf1','44322 HARDWOOD AVE'),
  ('Lancaster School Board - Trustee Area 5','Paula Joyce Clarke-Provinsal','Paula','Clarke-Provinsal',false,NULL,'Small Businesswoman/Cosmetologist'),
  ('Lancaster School Board - Trustee Area 5','Pamela Starlson','Pamela','Starlson',true,'ee16f7ef-91ae-5e3e-90db-168c8e679d62','P O BOX 150'),
  ('Lawndale Elementary School Board - Trustee Area 1','Jennifer R. Bagley','Jennifer','Bagley',false,NULL,'Parent/Entertainment Editor'),
  ('Lawndale Elementary School Board - Trustee Area 1','Bonnie J. Coronado','Bonnie','Coronado',true,'41c5f927-42c8-5310-b7ac-c17634ca5b19','Incumbent'),
  ('Lawndale Elementary School Board - Trustee Area 2','Shirley Rudolph','Shirley','Rudolph',true,'6257be6e-b8c4-50be-8aa9-d825d778c0a2','Incumbent'),
  ('Lawndale Elementary School Board - Trustee Area 2','Varun "Sunny" Tamrakar','Varun','Tamrakar',false,NULL,'Parent Advocate/Educator'),
  ('Lawndale Elementary School Board - Trustee Area 4','Ann M. Phillips','Ann','Phillips',true,'1275ebdd-c7ab-5b41-8932-143ada0bb53e','Incumbent'),
  ('Lennox School Board','José Luis Becerra','José','Becerra',false,NULL,'Wildlife Trapper'),
  ('Lennox School Board','Karina Cordero','Karina','Cordero',true,'ac5d3733-1925-5de1-a2b5-3385385185ff','Incumbent'),
  ('Lennox School Board','Maria de los Angeles Gonzalez','Maria','Gonzalez',true,'1baf211d-d0c6-5447-9abf-fb97442a2e73','School Board President'),
  ('Lennox School Board','Jaime Vaca','Jaime','Vaca',false,NULL,'Fleet Service Clerk'),
  ('Little Lake City School Board - Trustee Area 1','Susana Ramirez','Susana','Ramirez',false,NULL,NULL),
  ('Little Lake City School Board - Trustee Area 1','Eliana Tapia','Eliana','Tapia',false,NULL,'Retired Police Detective'),
  ('Little Lake City School Board - Trustee Area 2','Gabriel J. Jimenez','Gabriel','Jimenez',false,NULL,'Planning Commissioner'),
  ('Little Lake City School Board - Trustee Area 2','Adriana C. Mitre','Adriana','Mitre',false,NULL,'Human Resources Manager'),
  ('Little Lake City School Board - Trustee Area 5 (Unexpired Term Ending December 12, 2028)','Scherise R. Acosta','Scherise','Acosta',false,NULL,'School Attendance Clerk'),
  ('Little Lake City School Board - Trustee Area 5 (Unexpired Term Ending December 12, 2028)','Dora D. Sandoval','Dora','Sandoval',false,NULL,'Economy Efficiency Commissioner'),
  ('Los Nietos School Board - Trustee Area 2','Evelyn Mendez Avdalyan','Evelyn','Avdalyan',true,'3a463055-4b42-503b-b7cb-ce116cc9ceb5','Legal Assistant'),
  ('Los Nietos School Board - Trustee Area 2','Christian Ibarra','Christian','Ibarra',false,NULL,'Data Scientist'),
  ('Los Nietos School Board - Trustee Area 4','Bryan Galarza','Bryan','Galarza',false,NULL,'Phone:
                                 (562) 419-4724'),
  ('Los Nietos School Board - Trustee Area 5','Catherine Martinez','Catherine','Martinez',true,'de280cd0-7351-5719-91be-8b372e3d1dd9','Governing Board Member'),
  ('Mountain View School Board','Adam C. Carranza','Adam','Carranza',true,'c3f6a27c-8462-5ddf-bbea-9000e33a3ce2','Governing Board Member, Mountain View School District'),
  ('Mountain View School Board','Darlene Nava','Darlene','Nava',false,NULL,'Fiscal Services Clerk'),
  ('Mountain View School Board','Griselda Saharai Olivares','Griselda','Olivares',false,NULL,'Para Educator/Parent'),
  ('Mountain View School Board','Veronica B. Sifuentes','Veronica','Sifuentes',true,'71ba46a1-2bb4-5864-94d6-4547969b7fe3','Governing Board Member, Mountain View School District'),
  ('Mountain View School Board','Cindy Wu','Cindy','Wu',true,'be76a99b-a702-4318-9efd-a9e9e4790193','Governing Board Member, Mountain View School District'),
  ('Newhall School Board - Trustee Area 1','Michelle Kampbell','Michelle','Kampbell',false,NULL,'Statewide Nonprofit Director'),
  ('Newhall School Board - Trustee Area 2','Rachelle Haddoak','Rachelle','Haddoak',true,'3ae27906-e072-532a-86a8-c73c2654ed08','Incumbent'),
  ('Newhall School Board - Trustee Area 3','Ernesto A. Smith','Ernesto','Smith',true,'4eeda961-af9c-587c-a277-32a6d4f02a72','Incumbent'),
  ('Palmdale School Board - Trustee Area 1','Nancy K. Smith','Nancy','Smith',true,'85aa8840-af89-5c69-9e10-5aaceff28bd2','Governing Board Member'),
  ('Palmdale School Board - Trustee Area 1','Ralph Velador','Ralph','Velador',true,'96edb270-97e5-5187-8165-a73125ddecfc','School Board President'),
  ('Palmdale School Board - Trustee Area 3','Francisco Magana-Huanosto','Francisco','Magana-Huanosto',false,NULL,'Law Clerk'),
  ('Palmdale School Board - Trustee Area 3','Joann N. Smith','Joann','Smith',false,NULL,'Teacher'),
  ('Palmdale School Board - Trustee Area 5','Marcos Torres Alvarez','Marcos','Alvarez',false,NULL,'Community Organizer'),
  ('Palmdale School Board - Trustee Area 5','Simone Zulu','Simone','Zulu',true,'9cbad854-899a-57f8-90a0-129d94a45394','Governing Board Member'),
  ('Rosemead School Board','Nancy Armenta','Nancy','Armenta',true,'1a89b575-d545-5ded-ba93-ffbd439eaab4','Governing Board Member, Rosemead School District'),
  ('Rosemead School Board','Diane Benitez','Diane','Benitez',true,'dee8de05-2cab-50ca-aecb-0d66360676fd','Incumbent'),
  ('Rosemead School Board','John Quintanilla','John','Quintanilla',true,'a5a53805-85fe-5b01-8990-dcaab536afde','Governing Board Member, Rosemead School District'),
  ('Saugus Union School Board - Trustee Area 1','Natalie Epstein','Natalie','Epstein',false,NULL,'Small Business Owner'),
  ('Saugus Union School Board - Trustee Area 1','Larry Grable','Larry','Grable',false,NULL,'Business Owner/Parent'),
  ('Saugus Union School Board - Trustee Area 1','Kevin Kim','Kevin','Kim',false,NULL,'Attorney/Parent'),
  ('Saugus Union School Board - Trustee Area 2','Alisa Gentry','Alisa','Gentry',false,NULL,'Parent/EMT'),
  ('Saugus Union School Board - Trustee Area 2','Anna Griese','Anna','Griese',true,'90b09547-711f-55aa-8e0a-c0eeefe46827','Governing Board Member, Saugus Union School District'),
  ('Saugus Union School Board - Trustee Area 5','Cindy Larae Hallman','Cindy','Hallman',false,NULL,'Retired Educator'),
  ('Saugus Union School Board - Trustee Area 5','Christopher Trunkey','Christopher','Trunkey',true,'e009e833-974a-57ce-a7ee-32bd4f284181','Governing Board Member, Saugus Union School District'),
  ('South Whittier School Board - Trustee Area 1','Elizabeth Guillen','Elizabeth','Guillen',true,'64faacf6-4f6a-59e6-9c30-0461cec53584','Appointed Incumbent'),
  ('South Whittier School Board - Trustee Area 2','Natalia Barajas','Natalia','Barajas',true,'3c06bce9-b009-548d-a695-f783a0a1abfa','Governing Board Member'),
  ('South Whittier School Board - Trustee Area 5','Adriana Franco','Adriana','Franco',false,NULL,NULL),
  ('South Whittier School Board - Trustee Area 5','Sylvia V. Macias','Sylvia','Macias',true,'96147ed0-0184-5255-875e-2425508bce20','Incumbent'),
  ('Sulphur Springs Union School Board - Trustee Area 3','Paola Trinidad Jellings','Paola','Jellings',true,'a545cd9e-d294-5bef-9a09-b6ce31a39a20','Incumbent'),
  ('Sulphur Springs Union School Board - Trustee Area 4','Ken Chase','Ken','Chase',true,'02c8d4a7-63ee-5965-9b37-121087b67380','Governing Board Member'),
  ('Sulphur Springs Union School Board - Trustee Area 5','Lori MacDonald','Lori','MacDonald',true,'d7e65bfb-5cb4-545b-a961-3dba3531beaf','Incumbent'),
  ('Valle Lindo School Board','Angelica Garcia','Angelica','Garcia',false,NULL,'High School Counselor'),
  ('Valle Lindo School Board','Veronica Lauria','Veronica','Lauria',true,'f3eb5137-822f-5007-b242-5dd383bc485e','Incumbent'),
  ('Valle Lindo School Board','Rudy T. Martinez','Rudy','Martinez',true,'40f14ef7-a963-5f9d-8724-c2e1369437fc','Incumbent'),
  ('Valle Lindo School Board','Jacqueline J. Rubio','Jacqueline','Rubio',true,'58c035bb-582e-529c-a73a-ee4ae2d74532','Incumbent'),
  ('Westside Union School Board','Shameka Andre','Shameka','Andre',false,NULL,'School Administrator'),
  ('Westside Union School Board','John Curiel','John','Curiel',true,'caf0babc-cc93-5e4d-9358-5259f37f0f7a','Board Member, Westside Union School District'),
  ('Westside Union School Board','Jennifer Navarro','Jennifer','Navarro',true,'33423034-becb-58d2-b1e2-78eb79d6038f','School Boardmember/Businesswoman'),
  ('Westside Union School Board','Andrew Rowe','Andrew','Rowe',true,'9ee35644-a523-59a0-bc3a-2551d7423e3b','Incumbent'),
  ('Whittier City School Board - Trustee Area 3','Richard (Rick) Hever','Richard','Hever',true,'1f3c5428-2f6f-5d78-a44e-8351c73b85c9','Governing Board Member, Whittier City SD'),
  ('Whittier City School Board - Trustee Area 3','Norma Natalie Rodarte','Norma','Rodarte',false,NULL,'Retired Administration Secretary'),
  ('Whittier City School Board - Trustee Area 4','Jennifer De Baca Sandoval','Jennifer','Sandoval',true,'f0afac39-cab0-5b7a-84f8-8a3c0ac90e1e','Incumbent'),
  ('Whittier City School Board - Trustee Area 5','Andrew Roble','Andrew','Roble',false,NULL,'Parent/Labor Leader'),
  ('Whittier City School Board - Trustee Area 5','Linda L. Small','Linda','Small',true,'122b6d4c-c851-580e-9b43-fe0e2f96ee80','Incumbent'),
  ('Whittier Union High School Board - Trustee Area 1','Russell Castaneda Calleros','Russell','Calleros',true,'a8a5def3-8ce6-5a5a-b355-4ca27b94308c','Governing Board Member, Whittier Union High School District'),
  ('Whittier Union High School Board - Trustee Area 4','Irma Rodriguez Moisa','Irma','Moisa',true,'4e444a1b-187f-5f22-8f6e-56508f5237c4','Governing Board Member'),
  ('Whittier Union High School Board - Trustee Area 5','Desiree G. Quintero','Desiree','Quintero',false,NULL,'Public Policy Administrator'),
  ('Whittier Union High School Board - Trustee Area 5','Armando Urteaga','Armando','Urteaga',true,'19a80e5e-8d92-5aca-9b33-5ac57b9f81ca','Appointed Board Member, Whittier Union High School District'),
  ('William S. Hart Union High School Board - Trustee Area 2','Bryan Biggers','Bryan','Biggers',false,NULL,'Small Business Owner'),
  ('William S. Hart Union High School Board - Trustee Area 2','Julee Brooks','Julee','Brooks',false,NULL,'Education Nonprofit Executive'),
  ('William S. Hart Union High School Board - Trustee Area 3','Cherise Moore','Cherise','Moore',true,'41076964-edd9-4e7b-866f-79680545bb2c','Incumbent'),
  ('William S. Hart Union High School Board - Trustee Area 5','Stacy Fortner','Stacy','Fortner',false,NULL,'Mother/Technology Consultant'),
  ('William S. Hart Union High School Board - Trustee Area 5','Joe Messina','Joe','Messina',true,'4cee37b3-76a5-40f8-ad03-f30be18886aa','School Board President'),
  ('Wilsona School Board - Trustee Area 1','Robert D. Miller','Robert','Miller',true,'0acea6a3-2323-5423-a922-f5a71a0e9660','Incumbent'),
  ('Wilsona School Board - Trustee Area 2','Anne E. Misicka','Anne','Misicka',true,'6cc9f634-de00-5ff6-ae80-7a1dd7699bac','Website:'),
  ('Wilsona School Board - Trustee Area 3','Daniela Sanchez','Daniela','Sanchez',true,'8d7aaefc-1b95-5214-b0b3-371a5f483dea','Incumbent');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _race;
  IF v_n <> 74 THEN RAISE EXCEPTION 'PRE: % races, expected 74', v_n; END IF;
  SELECT count(*) INTO v_n FROM _cand;
  IF v_n <> 129 THEN RAISE EXCEPTION 'PRE: % candidates, expected 129', v_n; END IF;
  SELECT count(*) INTO v_n FROM _cand WHERE is_incumbent;
  IF v_n <> 78 THEN RAISE EXCEPTION 'PRE: % incumbents, expected 78', v_n; END IF;
  SELECT count(*) INTO v_n FROM _cand c WHERE NOT EXISTS (SELECT 1 FROM _race r WHERE r.position_name = c.position_name);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % candidate(s) point at no race', v_n; END IF;

  -- the election is the LA County Nov 3 2026 general
  SELECT count(*) INTO v_n FROM essentials.elections e
   WHERE e.id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14' AND e.election_date = '2026-11-03';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: election d91a20ce is not the Nov 3 2026 LA general'; END IF;

  -- no position name is already used on that election by some other race (a re-run finds ours)
  SELECT count(*) INTO v_n FROM essentials.races x JOIN _race r ON r.position_name = x.position_name
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                      WHERE o.id = x.office_id AND (d.geo_id = r.parent_geo OR d.geo_id LIKE r.parent_geo || '-ta-%'));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % position name(s) already used by another race', v_n; END IF;

  -- CA_0161 is applied: every trustee-area race's seat sits on its area sub-district
  SELECT count(*) INTO v_n FROM _race r
    JOIN essentials.offices o ON o.id = r.bind_office
    JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = r.bind_geo AND d.district_type = 'SCHOOL' AND d.mtfcc = 'X0002'
   WHERE r.bind_office IS NOT NULL;
  IF v_n <> 66 THEN RAISE EXCEPTION 'PRE: % of 66 trustee-area seats found on their area -- apply CA_0161 first', v_n; END IF;
  -- at-large races: the whole-district row holds the board's seats
  SELECT count(*) INTO v_n FROM _race r
   WHERE r.bind_office IS NULL
     AND (SELECT count(*) FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = r.bind_geo AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420') = 5;
  IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: % of 8 at-large boards hold 5 whole-district seats', v_n; END IF;

  -- every incumbent is linked to a politician who CURRENTLY holds a seat on that board
  SELECT count(*) INTO v_n FROM _cand c JOIN _race r ON r.position_name = c.position_name
   WHERE c.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                       JOIN essentials.offices o ON o.id = och.office_id
                       JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'SCHOOL'
                      WHERE och.politician_id = c.politician_id
                        AND (d.geo_id = r.parent_geo OR d.geo_id LIKE r.parent_geo || '-ta-%'));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % incumbent(s) not linked to a current member of their board', v_n; END IF;
  SELECT count(*) INTO v_n FROM _cand WHERE NOT is_incumbent AND politician_id IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % challenger(s) carry a politician link', v_n; END IF;
END $$;

-- ─── 1. Races ────────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid,
       COALESCE(r.bind_office,
                (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                  WHERE d.geo_id = r.bind_geo AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420'
                  ORDER BY o.id LIMIT 1)),
       r.position_name, NULL, r.seats
  FROM _race r
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races x
                    WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND x.position_name = r.position_name);

-- ─── 2. Candidates ───────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, occupational_designation, source)
SELECT x.id, c.politician_id, c.full_name, c.first_name, c.last_name, c.is_incumbent, 'active', c.designation,
       'LA County Registrar-Recorder, Nov 3 2026 General Election candidate list (lavote.gov/Apps/CandidateList/Index?id=4348), nomination papers filed; seats per LACOE Informational Bulletin 7112 (2026-04-02). Retrieved 2026-09-22. CA_0162.'
  FROM _cand c
  JOIN essentials.races x ON x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND x.position_name = c.position_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = x.id AND lower(rc.full_name) = lower(c.full_name));

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.races x JOIN _race r ON r.position_name = x.position_name
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14' AND x.primary_party IS NULL AND x.seats = r.seats;
  IF v_n <> 74 THEN RAISE EXCEPTION 'POST: % of 74 races present with the right seats', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races x ON x.id = rc.race_id
    JOIN _race r ON r.position_name = x.position_name
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14';
  IF v_n <> 129 THEN RAISE EXCEPTION 'POST: % of 129 candidates present', v_n; END IF;

  -- each race is bound to a seat of its own board: the area seat, or a whole-district seat for at-large
  SELECT count(*) INTO v_bad FROM essentials.races x JOIN _race r ON r.position_name = x.position_name
    JOIN essentials.offices o ON o.id = x.office_id JOIN essentials.districts d ON d.id = o.district_id
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND NOT ((r.bind_office IS NOT NULL AND o.id = r.bind_office AND d.geo_id = r.bind_geo AND d.mtfcc = 'X0002')
           OR (r.bind_office IS NULL AND d.geo_id = r.bind_geo AND d.mtfcc = 'G5420'));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % race(s) bound to the wrong seat', v_bad; END IF;

  -- incumbents: every one linked to a current member of the board; only Palmdale TA1 has more than its seats
  SELECT count(*) INTO v_bad FROM essentials.race_candidates rc JOIN essentials.races x ON x.id = rc.race_id
    JOIN _race r ON r.position_name = x.position_name
   WHERE rc.is_incumbent AND rc.politician_id IS NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % incumbent candidate(s) unlinked', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM essentials.races x JOIN _race r ON r.position_name = x.position_name
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = x.id AND rc.is_incumbent) > x.seats
     AND x.position_name <> 'Palmdale School Board - Trustee Area 1';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % race(s) with more incumbents than seats', v_bad; END IF;

  -- no candidate stores a party (antipartisan) -- the table has no party column; the race has none
  SELECT count(*) INTO v_bad FROM essentials.races x JOIN _race r ON r.position_name = x.position_name
   WHERE x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14' AND x.primary_party IS NOT NULL;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % race(s) carry a primary_party', v_bad; END IF;

  -- END TO END: an interior point of each race's own geography reaches the race through its seat
  SELECT count(*) INTO v_bad FROM _race r
    JOIN essentials.geofence_boundaries me ON me.geo_id = r.bind_geo
                                          AND me.mtfcc IN ('X0002','G5400','G5410')
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries gb
       JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'SCHOOL'
       JOIN essentials.offices o ON o.district_id = d.id
       JOIN essentials.races x ON x.office_id = o.id AND x.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
                              AND x.position_name = r.position_name
      WHERE gb.mtfcc IN ('X0002','G5400','G5410')
        AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry)));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % race(s) not reached from inside their own geography', v_bad; END IF;

  RAISE NOTICE 'CA_0162 applied: 74 races (66 trustee-area, 8 at-large) with 129 candidates (78 incumbents linked) on 2026 LA County General';
END $$;

COMMIT;

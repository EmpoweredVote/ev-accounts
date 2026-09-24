-- CA_0282_az_legislature_november_candidates.sql
--
-- Slot CA_0282 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Seeds the November 2026 fields of Arizona's 60 legislative races (State Senate District 1..30, one
-- seat each; State House District 1..30, races.seats = 2). All 60 race rows existed with ZERO
-- race_candidates, so Essentials showed every AZ legislative race empty.
--
-- Sources (both operator-supplied, 2026-09-24):
--   [GEN] Arizona Secretary of State, 2026 General Election candidate list
--         (apps.arizona.vote/electioninfo/Election/69, State Senator / State Representative sections;
--         captured by the operator 2026-09-24 — the site blocks scripted fetches).
--   [CAN] State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026;
--         20260806_Primary_Canvass.pdf pp.3-11, * = winner).
--
-- THE FIELD IS [GEN], ALL 162 ENTRIES (60 Senate, 102 House). Checked name by name against [CAN]:
--   * every entry without a write-in mark is a starred primary winner in [CAN], except Nick Fierro
--     (SD10, "INDEPENDENT"), who is in no primary — he qualified by nomination petition;
--   * primary winners who won as write-ins are printed in November and carry no mark: Loughrige (SD8),
--     Karp (SD19), Carver (HD2), Skirbst (HD3), Trachsel (HD6), Grayson (HD7). They are ballot rows;
--   * the four entries marked "Write-In Candidate" — Frank Bertone (SD3, REP), Gary Hatch (SD12, REP),
--     Charles "Charlie" Eakins (HD1, LBT), Royce "RJ" Mark Jenkins (HD6, REP) — ran in no primary, so
--     none is a primary loser. They are seeded with is_write_in = true (CA_0279), as CA_0280 did.
--   NO PRIMARY LOSERS ARE ADDED: none of the 60 races has any row, and [GEN] contains none. (Seated
--   members who lost — Tsosie HD6, Stahl Hamilton HD21, Lydia Hernandez HD24 — get no row; they keep
--   their seats until January.)
--
-- PEOPLE. 71 entries are existing politicians: every one is a SEATED Arizona legislator (office_current_
--   holder, AZ STATE_UPPER / STATE_LOWER), matched by surname + given name and checked by hand. 64 run
--   for their own district and chamber (race_candidates.is_incumbent = true, computed from the seat);
--   7 run for the other chamber of the same district and are not incumbents in that race: Contreras,
--   Willoughby, Griffin, Alma Hernandez, Biasiucci (House -> Senate); Gowan, Gonzales (Senate -> House).
--   91 are NEW BARE rows, 1296 / CA_0280 style: external_id -66000333..-66000423 (the next free numbers
--   in 1296's block at authoring — -66000332, CA_0281's, was the last taken; the pre-flight refuses if
--   any is taken by someone else), is_incumbent = false stated explicitly, is_active = true,
--   data_source 'manual'. Party from [GEN]: NOL and INDEPENDENT -> 'Independent' (as CA_0280).
--   Same-name rows REJECTED as different people: Christine King (Miami), Martin J. Jenkins, David Cook
--   x2 (TX), David Rose (CA school board), Michael Braun (inactive indiana_discovery row), David O.
--   Livingston (CA), Jamila Taylor (WA). POSSIBLE DUPLICATE, left unmerged for want of evidence:
--   Richard Grayson (HD7, GRN) shares a name with the AK 2026 U.S. Senate candidate 2fa5d558
--   (-66000076). Nothing on either row ties them together; merge later if a source does.
--
-- CI: new people carry no stance rows. Every existing person already holds an AZ seat, so
--   check-stance-sources buckets them by that seat, not by the new race: no bucket can move, and
--   backend/data/stance-source-baseline.json is unchanged. Every prod-reading CI check is run before
--   and after the dry run.
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the 162 race_candidates rows whose source ends 'added by CA_0282
--   (2026-09-24)', then the politicians -66000333..-66000423.

BEGIN;

CREATE TEMP TABLE ca0282_src ON COMMIT DROP AS
SELECT 'Arizona Secretary of State, 2026 General Election candidate list (apps.arizona.vote/electioninfo/Election/69, State tab; captured by the operator 2026-09-24)'::text AS gen,
       'State of Arizona Official Canvass, 2026 Primary Election - Jul 21, 2026 (report 8/5/2026; 20260806_Primary_Canvass.pdf pp.3-11)'::text AS can;

-- The 60 races: live count afterwards (= [GEN] entries), and how many of those are write-ins.
CREATE TEMP TABLE ca0282_race ON COMMIT DROP AS
SELECT x.position_name, ra.id AS race_id, ra.seats, ra.office_id, x.expect, x.write_ins
  FROM (VALUES
  ('State Senate District 1', 2, 0),
  ('State Senate District 2', 2, 0),
  ('State Senate District 3', 3, 1),
  ('State Senate District 4', 2, 0),
  ('State Senate District 5', 2, 0),
  ('State Senate District 6', 2, 0),
  ('State Senate District 7', 2, 0),
  ('State Senate District 8', 2, 0),
  ('State Senate District 9', 2, 0),
  ('State Senate District 10', 3, 0),
  ('State Senate District 11', 2, 0),
  ('State Senate District 12', 3, 1),
  ('State Senate District 13', 2, 0),
  ('State Senate District 14', 2, 0),
  ('State Senate District 15', 2, 0),
  ('State Senate District 16', 2, 0),
  ('State Senate District 17', 2, 0),
  ('State Senate District 18', 2, 0),
  ('State Senate District 19', 2, 0),
  ('State Senate District 20', 1, 0),
  ('State Senate District 21', 2, 0),
  ('State Senate District 22', 1, 0),
  ('State Senate District 23', 2, 0),
  ('State Senate District 24', 2, 0),
  ('State Senate District 25', 2, 0),
  ('State Senate District 26', 2, 0),
  ('State Senate District 27', 2, 0),
  ('State Senate District 28', 2, 0),
  ('State Senate District 29', 2, 0),
  ('State Senate District 30', 1, 0),
  ('State House District 1', 4, 1),
  ('State House District 2', 3, 0),
  ('State House District 3', 5, 0),
  ('State House District 4', 4, 0),
  ('State House District 5', 2, 0),
  ('State House District 6', 4, 1),
  ('State House District 7', 4, 0),
  ('State House District 8', 3, 0),
  ('State House District 9', 3, 0),
  ('State House District 10', 5, 0),
  ('State House District 11', 4, 0),
  ('State House District 12', 3, 0),
  ('State House District 13', 4, 0),
  ('State House District 14', 3, 0),
  ('State House District 15', 2, 0),
  ('State House District 16', 3, 0),
  ('State House District 17', 4, 0),
  ('State House District 18', 3, 0),
  ('State House District 19', 4, 0),
  ('State House District 20', 2, 0),
  ('State House District 21', 3, 0),
  ('State House District 22', 2, 0),
  ('State House District 23', 4, 0),
  ('State House District 24', 3, 0),
  ('State House District 25', 3, 0),
  ('State House District 26', 5, 0),
  ('State House District 27', 3, 0),
  ('State House District 28', 4, 0),
  ('State House District 29', 3, 0),
  ('State House District 30', 3, 0)
  ) AS x(position_name, expect, write_ins)
  JOIN essentials.elections e ON e.state = 'AZ' AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- The 162 entries of [GEN]. pid = existing politician (full_name = theirs); ext = new bare row.
CREATE TEMP TABLE ca0282_cand ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('State Senate District 1', '489e2fc3-b47a-4304-b959-07e35f010da4'::uuid, NULL::bigint, 'Mark Finchem', NULL, NULL, NULL, 'FINCHEM, MARK (REP)', false),
  ('State Senate District 1', NULL::uuid, -66000333::bigint, 'Christine Ellen Dargon', 'Christine', 'Dargon', 'Democratic', 'DARGON, CHRISTINE ELLEN (DEM)', false),
  ('State Senate District 2', '2785d691-2404-400e-8dde-bcc5a58e419b'::uuid, NULL::bigint, 'Shawnna Bolick', NULL, NULL, NULL, 'BOLICK, SHAWNNA (REP)', false),
  ('State Senate District 2', NULL::uuid, -66000334::bigint, 'Amelia Gallitano', 'Amelia', 'Gallitano', 'Democratic', 'GALLITANO, AMELIA (DEM)', false),
  ('State Senate District 3', '4f7db8ce-def5-4225-b183-654f8f64cb9a'::uuid, NULL::bigint, 'John Kavanagh', NULL, NULL, NULL, 'KAVANAGH, JOHN (REP)', false),
  ('State Senate District 3', NULL::uuid, -66000335::bigint, 'Jeffrey Fortney', 'Jeffrey', 'Fortney', 'Democratic', 'FORTNEY, JEFFREY (DEM)', false),
  ('State Senate District 3', NULL::uuid, -66000336::bigint, 'Frank Bertone', 'Frank', 'Bertone', 'Republican', 'BERTONE, FRANK (REP)', true),
  ('State Senate District 4', 'b769f53e-c9e5-4259-9e00-c20bfa945d15'::uuid, NULL::bigint, 'Carine Werner', NULL, NULL, NULL, 'WERNER, CARINE (REP)', false),
  ('State Senate District 4', NULL::uuid, -66000337::bigint, 'Aaron Lieberman', 'Aaron', 'Lieberman', 'Democratic', 'LIEBERMAN, AARON (DEM)', false),
  ('State Senate District 5', NULL::uuid, -66000338::bigint, 'Christine Marsh', 'Christine', 'Marsh', 'Democratic', 'MARSH, CHRISTINE (DEM)', false),
  ('State Senate District 5', NULL::uuid, -66000339::bigint, 'Jason LaForest', 'Jason', 'LaForest', 'Independent', 'LAFOREST, JASON (NOL)', false),
  ('State Senate District 6', NULL::uuid, -66000340::bigint, 'Lloyd Johnson', 'Lloyd', 'Johnson', 'Republican', 'JOHNSON, LLOYD (REP)', false),
  ('State Senate District 6', NULL::uuid, -66000341::bigint, 'Jamescita Peshlakai', 'Jamescita', 'Peshlakai', 'Democratic', 'PESHLAKAI, JAMESCITA (DEM)', false),
  ('State Senate District 7', '23b7d096-37ad-4b00-8291-c7f0640a22d2'::uuid, NULL::bigint, 'Wendy Rogers', NULL, NULL, NULL, 'ROGERS, WENDY (REP)', false),
  ('State Senate District 7', NULL::uuid, -66000342::bigint, 'Michiel "Mike" Montiel', 'Michiel', 'Montiel', 'Democratic', 'MONTIEL, MICHIEL "MIKE" (DEM)', false),
  ('State Senate District 8', NULL::uuid, -66000343::bigint, 'Bill Loughrige', 'Bill', 'Loughrige', 'Republican', 'LOUGHRIGE, BILL (REP)', false),
  ('State Senate District 8', '68308cfb-52ff-4a9c-8363-9a582ea9a989'::uuid, NULL::bigint, 'Lauren Kuby', NULL, NULL, NULL, 'KUBY, LAUREN (DEM)', false),
  ('State Senate District 9', NULL::uuid, -66000344::bigint, 'Bridget Fitzgibbons', 'Bridget', 'Fitzgibbons', 'Republican', 'FITZGIBBONS, BRIDGET (REP)', false),
  ('State Senate District 9', 'fef8eb85-8360-418d-8239-ccf3a823608b'::uuid, NULL::bigint, 'Kiana Sears', NULL, NULL, NULL, 'SEARS, KIANA MARIA (DEM)', false),
  ('State Senate District 10', '7ab7c163-bfac-4a95-8b94-22d1a4395522'::uuid, NULL::bigint, 'David C. Farnsworth', NULL, NULL, NULL, 'FARNSWORTH, DAVID CHRISTIAN (REP)', false),
  ('State Senate District 10', NULL::uuid, -66000345::bigint, 'Blair Moses', 'Blair', 'Moses', 'Democratic', 'MOSES, BLAIR (DEM)', false),
  ('State Senate District 10', NULL::uuid, -66000346::bigint, 'Nick Fierro', 'Nick', 'Fierro', 'Independent', 'FIERRO, NICK (INDEPENDENT)', false),
  ('State Senate District 11', NULL::uuid, -66000347::bigint, 'Joshua Ayala', 'Joshua', 'Ayala', 'Republican', 'AYALA, JOSHUA (REP)', false),
  ('State Senate District 11', 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2'::uuid, NULL::bigint, 'Catherine Miranda', NULL, NULL, NULL, 'MIRANDA, CATHERINE (DEM)', false),
  ('State Senate District 12', '8dcf58fe-fea2-4dd4-81ac-542432b154cf'::uuid, NULL::bigint, 'Patty Contreras', NULL, NULL, NULL, 'CONTRERAS, PATRICIA "PATTY" (DEM)', false),
  ('State Senate District 12', NULL::uuid, -66000348::bigint, 'Anthony Jason Ramirez', 'Anthony', 'Ramirez', 'Independent', 'RAMIREZ, ANTHONY JASON (NOL)', false),
  ('State Senate District 12', NULL::uuid, -66000349::bigint, 'Gary Hatch', 'Gary', 'Hatch', 'Republican', 'HATCH, GARY (REP)', true),
  ('State Senate District 13', '8edebfca-2e35-4424-85f8-f3ad498a2890'::uuid, NULL::bigint, 'Julie Willoughby', NULL, NULL, NULL, 'WILLOUGHBY, JULIE (REP)', false),
  ('State Senate District 13', NULL::uuid, -66000350::bigint, 'Kristie O''Brien', 'Kristie', 'O''Brien', 'Democratic', 'O''BRIEN, KRISTIE (DEM)', false),
  ('State Senate District 14', NULL::uuid, -66000351::bigint, 'Mylie Biggs', 'Mylie', 'Biggs', 'Republican', 'BIGGS, MYLIE (REP)', false),
  ('State Senate District 14', NULL::uuid, -66000352::bigint, 'Stephanie Walsh', 'Stephanie', 'Walsh', 'Democratic', 'WALSH, STEPHANIE (DEM)', false),
  ('State Senate District 15', '66ca210e-deab-4d07-8a18-48f7079f6f9b'::uuid, NULL::bigint, 'Jake Hoffman', NULL, NULL, NULL, 'HOFFMAN, JAKE (REP)', false),
  ('State Senate District 15', NULL::uuid, -66000353::bigint, 'Jayme Accalia', 'Jayme', 'Accalia', 'Democratic', 'ACCALIA, JAYME (DEM)', false),
  ('State Senate District 16', '8bbf9f70-adee-4801-ab19-7b78f9e70aa1'::uuid, NULL::bigint, 'Thomas "T.J." Shope', NULL, NULL, NULL, 'SHOPE, THOMAS "T.J." (REP)', false),
  ('State Senate District 16', NULL::uuid, -66000354::bigint, 'Elaine Aldrete', 'Elaine', 'Aldrete', 'Democratic', 'ALDRETE, ELAINE (DEM)', false),
  ('State Senate District 17', NULL::uuid, -66000355::bigint, 'Christopher King', 'Christopher', 'King', 'Republican', 'KING, CHRISTOPHER (REP)', false),
  ('State Senate District 17', NULL::uuid, -66000356::bigint, 'Edgar Soto', 'Edgar', 'Soto', 'Democratic', 'SOTO, EDGAR (DEM)', false),
  ('State Senate District 18', NULL::uuid, -66000357::bigint, 'Douglas Everett', 'Douglas', 'Everett', 'Republican', 'EVERETT, DOUGLAS (REP)', false),
  ('State Senate District 18', '179e2cdb-395e-4f7f-a5e1-775ff176ce64'::uuid, NULL::bigint, 'Priya Sundareshan', NULL, NULL, NULL, 'SUNDARESHAN, PRIYA (DEM)', false),
  ('State Senate District 19', '188c386e-087b-4587-9510-da7fc5805575'::uuid, NULL::bigint, 'Gail Griffin', NULL, NULL, NULL, 'GRIFFIN, GAIL (REP)', false),
  ('State Senate District 19', NULL::uuid, -66000358::bigint, 'Bob Karp', 'Bob', 'Karp', 'Democratic', 'KARP, BOB (DEM)', false),
  ('State Senate District 20', 'e4460c64-fa27-4e05-96e8-cc005a478444'::uuid, NULL::bigint, 'Alma Hernandez', NULL, NULL, NULL, 'HERNANDEZ, ALMA (DEM)', false),
  ('State Senate District 21', NULL::uuid, -66000359::bigint, 'Esteban Flores', 'Esteban', 'Flores', 'Republican', 'FLORES, ESTEBAN (REP)', false),
  ('State Senate District 21', '8cbc6c91-4147-4831-ae0e-f4658ce282e8'::uuid, NULL::bigint, 'Rosanna Gabaldón', NULL, NULL, NULL, 'GABALDÓN, ROSANNA (DEM)', false),
  ('State Senate District 22', '901398ea-3180-4b6d-8ba4-9f0dd85d7bb1'::uuid, NULL::bigint, 'Eva Diaz', NULL, NULL, NULL, 'DIAZ, EVA (DEM)', false),
  ('State Senate District 23', NULL::uuid, -66000360::bigint, 'Michelle Altherr', 'Michelle', 'Altherr', 'Republican', 'ALTHERR, MICHELLE (REP)', false),
  ('State Senate District 23', '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636'::uuid, NULL::bigint, 'Brian Fernandez', NULL, NULL, NULL, 'FERNANDEZ, BRIAN (DEM)', false),
  ('State Senate District 24', NULL::uuid, -66000361::bigint, 'Frank Steele', 'Frank', 'Steele', 'Republican', 'STEELE, FRANK (REP)', false),
  ('State Senate District 24', 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8'::uuid, NULL::bigint, 'Analise Ortiz', NULL, NULL, NULL, 'ORTIZ, ANALISE (DEM)', false),
  ('State Senate District 25', 'ebef00e8-7722-4e9b-b5dc-ef95a41a9a40'::uuid, NULL::bigint, 'Timothy "Tim" Dunn', NULL, NULL, NULL, 'DUNN, TIMOTHY "TIM" (REP)', false),
  ('State Senate District 25', NULL::uuid, -66000362::bigint, 'Laura Huber', 'Laura', 'Huber', 'Democratic', 'HUBER, LAURA (DEM)', false),
  ('State Senate District 26', NULL::uuid, -66000363::bigint, 'Jim Bishop', 'Jim', 'Bishop', 'Republican', 'BISHOP, JIM (REP)', false),
  ('State Senate District 26', '4046a3d6-87ba-41bb-afd8-422f017c851b'::uuid, NULL::bigint, 'Flavio Bravo', NULL, NULL, NULL, 'BRAVO, FLAVIO (DEM)', false),
  ('State Senate District 27', '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c'::uuid, NULL::bigint, 'Kevin Payne', NULL, NULL, NULL, 'PAYNE, KEVIN (REP)', false),
  ('State Senate District 27', NULL::uuid, -66000364::bigint, 'Kyle Clayton', 'Kyle', 'Clayton', 'Democratic', 'CLAYTON, KYLE (DEM)', false),
  ('State Senate District 28', '376698b5-a276-4977-b2c3-3d15a822f7d8'::uuid, NULL::bigint, 'Frank Carroll', NULL, NULL, NULL, 'CARROLL, FRANK (REP)', false),
  ('State Senate District 28', NULL::uuid, -66000365::bigint, 'Michael Braun', 'Michael', 'Braun', 'Democratic', 'BRAUN, MICHAEL (DEM)', false),
  ('State Senate District 29', '687e6f07-f71a-41b4-8525-b509b2cebb42'::uuid, NULL::bigint, 'Janae Shamp', NULL, NULL, NULL, 'SHAMP, JANAE (REP)', false),
  ('State Senate District 29', NULL::uuid, -66000366::bigint, 'Eric Stafford', 'Eric', 'Stafford', 'Democratic', 'STAFFORD, ERIC (DEM)', false),
  ('State Senate District 30', 'b1b97401-d1a9-4442-9f78-2749f1853f6e'::uuid, NULL::bigint, 'Leo Biasiucci', NULL, NULL, NULL, 'BIASIUCCI, LEO (REP)', false),
  ('State House District 1', 'b8c33072-6368-4465-8352-14e9fabddfbe'::uuid, NULL::bigint, 'Selina Bliss', NULL, NULL, NULL, 'BLISS, SELINA (REP)', false),
  ('State House District 1', '9cc152b6-c83b-4501-9e1a-2ab50e1db6a7'::uuid, NULL::bigint, 'Quang H Nguyen', NULL, NULL, NULL, 'NGUYEN, QUANG HUU (REP)', false),
  ('State House District 1', NULL::uuid, -66000367::bigint, 'Sandy Zalecki', 'Sandy', 'Zalecki', 'Democratic', 'ZALECKI, SANDY (DEM)', false),
  ('State House District 1', NULL::uuid, -66000368::bigint, 'Charles "Charlie" Eakins', 'Charles', 'Eakins', 'Libertarian', 'EAKINS, CHARLES "CHARLIE" (LBT)', true),
  ('State House District 2', NULL::uuid, -66000369::bigint, 'Paul Carver', 'Paul', 'Carver', 'Republican', 'CARVER, PAUL (REP)', false),
  ('State House District 2', '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04'::uuid, NULL::bigint, 'Justin Wilmeth', NULL, NULL, NULL, 'WILMETH, JUSTIN (REP)', false),
  ('State House District 2', '84bb6849-a68d-42e0-999d-dd0456b9d0b4'::uuid, NULL::bigint, 'Stephanie Simacek', NULL, NULL, NULL, 'SIMACEK, STEPHANIE (DEM)', false),
  ('State House District 3', NULL::uuid, -66000370::bigint, 'George Khalaf', 'George', 'Khalaf', 'Republican', 'KHALAF, GEORGE (REP)', false),
  ('State House District 3', '85937da6-85eb-4d10-946f-2ed3c391a9c9'::uuid, NULL::bigint, 'Cody Reim', NULL, NULL, NULL, 'REIM, CODY (REP)', false),
  ('State House District 3', NULL::uuid, -66000371::bigint, 'Julie Gable', 'Julie', 'Gable', 'Democratic', 'GABLE, JULIE (DEM)', false),
  ('State House District 3', NULL::uuid, -66000372::bigint, 'Richard "Rick" Robert Spargo', 'Richard', 'Spargo', 'Democratic', 'SPARGO, RICHARD "RICK" ROBERT (DEM)', false),
  ('State House District 3', NULL::uuid, -66000373::bigint, 'John Skirbst', 'John', 'Skirbst', 'Independent', 'SKIRBST, JOHN (NOL)', false),
  ('State House District 4', '23675559-e2dd-4e26-abed-2f87954dc70e'::uuid, NULL::bigint, 'Pamela Carter', NULL, NULL, NULL, 'CARTER, PAMELA (REP)', false),
  ('State House District 4', '5293ff0f-0365-4943-89a5-f4017566c8dd'::uuid, NULL::bigint, 'Matt Gress', NULL, NULL, NULL, 'GRESS, MATT (REP)', false),
  ('State House District 4', NULL::uuid, -66000374::bigint, 'Tammy Caputi', 'Tammy', 'Caputi', 'Democratic', 'CAPUTI, TAMMY (DEM)', false),
  ('State House District 4', NULL::uuid, -66000375::bigint, 'Karen Gresham', 'Karen', 'Gresham', 'Democratic', 'GRESHAM, KAREN (DEM)', false),
  ('State House District 5', 'eb8215ef-5e68-431a-a5cf-c226e8c0abf1'::uuid, NULL::bigint, 'Sarah Liguori', NULL, NULL, NULL, 'LIGUORI, SARAH (DEM)', false),
  ('State House District 5', '0df9cd85-3923-48bd-86c2-b7d4b31d510d'::uuid, NULL::bigint, 'Aaron Márquez', NULL, NULL, NULL, 'MÁRQUEZ, AARON (DEM)', false),
  ('State House District 6', 'fe4cbf96-b145-48d7-9fcf-120e6b75c290'::uuid, NULL::bigint, 'Mae Peshlakai', NULL, NULL, NULL, 'PESHLAKAI, MAE (DEM)', false),
  ('State House District 6', NULL::uuid, -66000376::bigint, 'Ian Teller', 'Ian', 'Teller', 'Democratic', 'TELLER, IAN (DEM)', false),
  ('State House District 6', NULL::uuid, -66000377::bigint, 'Brendan Trachsel', 'Brendan', 'Trachsel', 'Green', 'TRACHSEL, BRENDAN (GRN)', false),
  ('State House District 6', NULL::uuid, -66000378::bigint, 'Royce "RJ" Mark Jenkins', 'Royce', 'Jenkins', 'Republican', 'JENKINS, ROYCE "RJ" MARK (REP)', true),
  ('State House District 7', 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7'::uuid, NULL::bigint, 'Walt Blackman', NULL, NULL, NULL, 'BLACKMAN, WALTER "WALT" (REP)', false),
  ('State House District 7', NULL::uuid, -66000379::bigint, 'David Cook Sr.', 'David', 'Cook', 'Republican', 'COOK, DAVID, SR. (REP)', false),
  ('State House District 7', NULL::uuid, -66000380::bigint, 'Samuel "Sam" Martin', 'Samuel', 'Martin', 'Democratic', 'MARTIN, SAMUEL "SAM" (DEM)', false),
  ('State House District 7', NULL::uuid, -66000381::bigint, 'Richard Grayson', 'Richard', 'Grayson', 'Green', 'GRAYSON, RICHARD (GRN)', false),
  ('State House District 8', NULL::uuid, -66000382::bigint, 'Donald Hawker', 'Donald', 'Hawker', 'Republican', 'HAWKER, DONALD (REP)', false),
  ('State House District 8', 'd6f22ab7-5f0a-4d58-b53a-fd69bf4ad556'::uuid, NULL::bigint, 'Janeen Connolly', NULL, NULL, NULL, 'CONNOLLY, JANEEN (DEM)', false),
  ('State House District 8', 'ea0e5f51-f963-45ef-a104-429af91e5f90'::uuid, NULL::bigint, 'Brian Garcia', NULL, NULL, NULL, 'GARCIA, BRIAN (DEM)', false),
  ('State House District 9', NULL::uuid, -66000383::bigint, 'Bradley D. Bettencourt', 'Bradley', 'Bettencourt', 'Republican', 'BETTENCOURT, BRADLEY D. (REP)', false),
  ('State House District 9', 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62'::uuid, NULL::bigint, 'Lorena Austin', NULL, NULL, NULL, 'AUSTIN, LORENA (DEM)', false),
  ('State House District 9', NULL::uuid, -66000384::bigint, 'Jacob D. Martinez', 'Jacob', 'Martinez', 'Democratic', 'MARTINEZ, JACOB D. (DEM)', false),
  ('State House District 10', '2af8f7d8-79ac-4668-9771-fdfff27ecc6c'::uuid, NULL::bigint, 'Justin Olson', NULL, NULL, NULL, 'OLSON, JUSTIN (REP)', false),
  ('State House District 10', NULL::uuid, -66000385::bigint, 'James Rogers', 'James', 'Rogers', 'Republican', 'ROGERS, JAMES (REP)', false),
  ('State House District 10', NULL::uuid, -66000386::bigint, 'Brian Calaway', 'Brian', 'Calaway', 'Democratic', 'CALAWAY, BRIAN (DEM)', false),
  ('State House District 10', NULL::uuid, -66000387::bigint, 'Helen Hunter', 'Helen', 'Hunter', 'Democratic', 'HUNTER, HELEN (DEM)', false),
  ('State House District 10', NULL::uuid, -66000388::bigint, 'David Scott', 'David', 'Scott', 'Independent', 'SCOTT, DAVID (NOL)', false),
  ('State House District 11', NULL::uuid, -66000389::bigint, 'Cesar Aleman', 'Cesar', 'Aleman', 'Republican', 'ALEMAN, CESAR (REP)', false),
  ('State House District 11', NULL::uuid, -66000390::bigint, 'Joseph Charles Dailey', 'Joseph', 'Dailey', 'Republican', 'DAILEY, JOSEPH CHARLES (REP)', false),
  ('State House District 11', '2b044f08-b5ce-4b15-993e-b90c16603c25'::uuid, NULL::bigint, 'Junelle Cavero', NULL, NULL, NULL, 'CAVERO, JUNELLE (DEM)', false),
  ('State House District 11', 'fb949bda-e2f5-49ab-9069-a70da1fb13bd'::uuid, NULL::bigint, 'Oscar De Los Santos', NULL, NULL, NULL, 'DE LOS SANTOS, OSCAR (DEM)', false),
  ('State House District 12', NULL::uuid, -66000391::bigint, 'David Richardson', 'David', 'Richardson', 'Republican', 'RICHARDSON, DAVID (REP)', false),
  ('State House District 12', NULL::uuid, -66000392::bigint, 'Armando Montero', 'Armando', 'Montero', 'Democratic', 'MONTERO, ARMANDO (DEM)', false),
  ('State House District 12', 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b'::uuid, NULL::bigint, 'Stacey Travers', NULL, NULL, NULL, 'TRAVERS, STACEY (DEM)', false),
  ('State House District 13', NULL::uuid, -66000393::bigint, 'Kevin Hartke', 'Kevin', 'Hartke', 'Republican', 'HARTKE, KEVIN (REP)', false),
  ('State House District 13', NULL::uuid, -66000394::bigint, 'Janet Weninger', 'Janet', 'Weninger', 'Republican', 'WENINGER, JANET (REP)', false),
  ('State House District 13', NULL::uuid, -66000395::bigint, 'Racquel "Rockee" Armstrong', 'Racquel', 'Armstrong', 'Democratic', 'ARMSTRONG, RACQUEL "ROCKEE" (DEM)', false),
  ('State House District 13', NULL::uuid, -66000396::bigint, 'Jacob Weinberg', 'Jacob', 'Weinberg', 'Democratic', 'WEINBERG, JACOB (DEM)', false),
  ('State House District 14', NULL::uuid, -66000397::bigint, 'Tyler Andrew Farnsworth', 'Tyler', 'Farnsworth', 'Republican', 'FARNSWORTH, TYLER ANDREW (REP)', false),
  ('State House District 14', '1f7399ee-2434-49dc-9a18-857bfa0e41f1'::uuid, NULL::bigint, 'Laurin Hendrix', NULL, NULL, NULL, 'HENDRIX, LAURIN (REP)', false),
  ('State House District 14', NULL::uuid, -66000398::bigint, 'Mary Rose', 'Mary', 'Rose', 'Democratic', 'ROSE, MARY (DEM)', false),
  ('State House District 15', '9a81dfd3-b70b-45bf-8851-3907d6e12508'::uuid, NULL::bigint, 'Neal Carter', NULL, NULL, NULL, 'CARTER, NEAL (REP)', false),
  ('State House District 15', '29b130a2-1531-4b35-b79e-dc0e8e3c0b93'::uuid, NULL::bigint, 'Michael Way', NULL, NULL, NULL, 'WAY, MICHAEL (REP)', false),
  ('State House District 16', '5dd72969-087b-4db0-b2b1-ee87a1ef11b9'::uuid, NULL::bigint, 'Chris Lopez', NULL, NULL, NULL, 'LOPEZ, CHRIS (REP)', false),
  ('State House District 16', 'cacb84a8-4343-4919-a37c-dfcb6e050243'::uuid, NULL::bigint, 'Teresa Martinez', NULL, NULL, NULL, 'MARTINEZ, TERESA (REP)', false),
  ('State House District 16', NULL::uuid, -66000399::bigint, 'Julia Romero Gusse', 'Julia', 'Gusse', 'Democratic', 'GUSSE, JULIA ROMERO (DEM)', false),
  ('State House District 17', '6a1417b8-cdcd-43f2-a63d-533beaefc563'::uuid, NULL::bigint, 'Rachel Keshel', NULL, NULL, NULL, 'KESHEL, RACHEL "JONES" (REP)', false),
  ('State House District 17', NULL::uuid, -66000400::bigint, 'John Winchester', 'John', 'Winchester', 'Republican', 'WINCHESTER, JOHN (REP)', false),
  ('State House District 17', NULL::uuid, -66000401::bigint, 'Hollace "Holly" Lyon', 'Hollace', 'Lyon', 'Democratic', 'LYON, HOLLACE "HOLLY" (DEM)', false),
  ('State House District 17', 'c72622ac-61d7-4e8b-83a8-565cfca045c0'::uuid, NULL::bigint, 'Kevin Volk', NULL, NULL, NULL, 'VOLK, KEVIN (DEM)', false),
  ('State House District 18', NULL::uuid, -66000402::bigint, 'Bob Dohse', 'Bob', 'Dohse', 'Republican', 'DOHSE, BOB (REP)', false),
  ('State House District 18', 'ce872623-f6bd-4e90-9eba-239ed00c7491'::uuid, NULL::bigint, 'Nancy Gutierrez', NULL, NULL, NULL, 'GUTIERREZ, NANCY (DEM)', false),
  ('State House District 18', 'a7675f41-2e50-413c-9864-8a64969f47f9'::uuid, NULL::bigint, 'Christopher Mathis', NULL, NULL, NULL, 'MATHIS, CHRIS (DEM)', false),
  ('State House District 19', '0ac7beee-f298-4d41-8981-30c3c307fe3d'::uuid, NULL::bigint, 'Lupe Diaz', NULL, NULL, NULL, 'DIAZ, LUPE (REP)', false),
  ('State House District 19', 'e71471f4-bef5-46ef-a1f2-f19f275b558d'::uuid, NULL::bigint, 'David Gowan', NULL, NULL, NULL, 'GOWAN, DAVID (REP)', false),
  ('State House District 19', NULL::uuid, -66000403::bigint, 'Jackie O''Donnell Anderson', 'Jackie', 'Anderson', 'Democratic', 'ANDERSON, JACKIE O''DONNELL (DEM)', false),
  ('State House District 19', NULL::uuid, -66000404::bigint, 'Aiden Nicholette Swallow', 'Aiden', 'Swallow', 'Democratic', 'SWALLOW, AIDEN NICHOLETTE (DEM)', false),
  ('State House District 20', '82f31f9c-754b-4417-bc21-af295b2b4d2b'::uuid, NULL::bigint, 'Sally Ann Gonzales', NULL, NULL, NULL, 'GONZALES, SALLY ANN (DEM)', false),
  ('State House District 20', '6dcc0e46-c944-480b-a432-7b36989d56e9'::uuid, NULL::bigint, 'Betty J Villegas', NULL, NULL, NULL, 'VILLEGAS, BETTY (DEM)', false),
  ('State House District 21', NULL::uuid, -66000405::bigint, 'Christopher Kibbey', 'Christopher', 'Kibbey', 'Republican', 'KIBBEY, CHRISTOPHER (REP)', false),
  ('State House District 21', '5e9c9ca6-5267-4d01-b19d-a7da775d89d9'::uuid, NULL::bigint, 'Consuelo Hernandez', NULL, NULL, NULL, 'HERNANDEZ, CONSUELO (DEM)', false),
  ('State House District 21', NULL::uuid, -66000406::bigint, 'Miranda Lopez', 'Miranda', 'Lopez', 'Democratic', 'LOPEZ, MIRANDA (DEM)', false),
  ('State House District 22', '8d470040-0f53-4881-8b58-5e9563a85f94'::uuid, NULL::bigint, 'Elda Luna-Nájera', NULL, NULL, NULL, 'LUNA-NÁJERA, ELDA (DEM)', false),
  ('State House District 22', NULL::uuid, -66000407::bigint, 'Betsy Munoz', 'Betsy', 'Munoz', 'Democratic', 'MUNOZ, BETSY (DEM)', false),
  ('State House District 23', NULL::uuid, -66000408::bigint, 'Gary Garcia Snyder', 'Gary', 'Garcia Snyder', 'Republican', 'GARCIA SNYDER, GARY (REP)', false),
  ('State House District 23', '81b3d4cc-c502-4fbc-bd75-97773c39b2f5'::uuid, NULL::bigint, 'Michele Peña', NULL, NULL, NULL, 'PEÑA, MICHELE (REP)', false),
  ('State House District 23', NULL::uuid, -66000409::bigint, 'Emilia Cortez', 'Emilia', 'Cortez', 'Democratic', 'CORTEZ, EMILIA (DEM)', false),
  ('State House District 23', 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee'::uuid, NULL::bigint, 'Mariana Sandoval', NULL, NULL, NULL, 'SANDOVAL, MARIANA (DEM)', false),
  ('State House District 24', NULL::uuid, -66000410::bigint, 'Delores McLaughlin', 'Delores', 'McLaughlin', 'Republican', 'MCLAUGHLIN, DELORES (REP)', false),
  ('State House District 24', NULL::uuid, -66000411::bigint, 'Lisbeth Arescurenaga', 'Lisbeth', 'Arescurenaga', 'Democratic', 'ARESCURENAGA, LISBETH (DEM)', false),
  ('State House District 24', NULL::uuid, -66000412::bigint, 'Alberto Flores', 'Alberto', 'Flores', 'Democratic', 'FLORES, ALBERTO (DEM)', false),
  ('State House District 25', '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a'::uuid, NULL::bigint, 'Michael Carbone', NULL, NULL, NULL, 'CARBONE, MICHAEL (REP)', false),
  ('State House District 25', '4176f760-3c74-4a55-8edc-b7897ee80e21'::uuid, NULL::bigint, 'Nick Kupper', NULL, NULL, NULL, 'KUPPER, NICKOLAS "NICK" (REP)', false),
  ('State House District 25', NULL::uuid, -66000413::bigint, 'Tiffany Byrne', 'Tiffany', 'Byrne', 'Democratic', 'BYRNE, TIFFANY (DEM)', false),
  ('State House District 26', NULL::uuid, -66000414::bigint, 'Jonathan McKenna', 'Jonathan', 'McKenna', 'Republican', 'MCKENNA, JONATHAN (REP)', false),
  ('State House District 26', NULL::uuid, -66000415::bigint, 'Frank Roberts', 'Frank', 'Roberts', 'Republican', 'ROBERTS, FRANK (REP)', false),
  ('State House District 26', '49b2db49-6438-437c-90ce-36b97670e30a'::uuid, NULL::bigint, 'Cesar Aguilar', NULL, NULL, NULL, 'AGUILAR, CESAR (DEM)', false),
  ('State House District 26', '1482a2bc-75d8-4aee-865c-53378c415210'::uuid, NULL::bigint, 'Quantá Crews', NULL, NULL, NULL, 'CREWS, QUANTÁ (DEM)', false),
  ('State House District 26', NULL::uuid, -66000416::bigint, 'Hector Gomez', 'Hector', 'Gomez', 'Green', 'GOMEZ, HECTOR (GRN)', false),
  ('State House District 27', '558dc1d6-0365-4707-8373-4ef188aff71c'::uuid, NULL::bigint, 'Lisa Fink', NULL, NULL, NULL, 'FINK, LISA (REP)', false),
  ('State House District 27', '9c481b8d-e373-4409-bccb-bde6534882da'::uuid, NULL::bigint, 'Tony Rivero', NULL, NULL, NULL, 'RIVERO, TONY (REP)', false),
  ('State House District 27', NULL::uuid, -66000417::bigint, 'Deborah Howard', 'Deborah', 'Howard', 'Democratic', 'HOWARD, DEBORAH (DEM)', false),
  ('State House District 28', '43e734b4-4417-4dcd-91c9-f420f3a1b702'::uuid, NULL::bigint, 'David Livingston', NULL, NULL, NULL, 'LIVINGSTON, DAVID (REP)', false),
  ('State House District 28', '184bd445-9f61-4bd3-859f-22522c9ccabd'::uuid, NULL::bigint, 'Beverly Pingerelli', NULL, NULL, NULL, 'PINGERELLI, BEVERLY (REP)', false),
  ('State House District 28', NULL::uuid, -66000418::bigint, 'Barbara Fike', 'Barbara', 'Fike', 'Democratic', 'FIKE, BARBARA (DEM)', false),
  ('State House District 28', NULL::uuid, -66000419::bigint, 'Marc Graham', 'Marc', 'Graham', 'Democratic', 'GRAHAM, MARC (DEM)', false),
  ('State House District 29', '47071c20-df9d-4f9d-9329-25faf64cd163'::uuid, NULL::bigint, 'Steve Montenegro', NULL, NULL, NULL, 'MONTENEGRO, STEVE (REP)', false),
  ('State House District 29', 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8'::uuid, NULL::bigint, 'James Taylor', NULL, NULL, NULL, 'TAYLOR, JAMES (REP)', false),
  ('State House District 29', NULL::uuid, -66000420::bigint, 'Christine Marie Scianna', 'Christine', 'Scianna', 'Democratic', 'SCIANNA, CHRISTINE MARIE (DEM)', false),
  ('State House District 30', NULL::uuid, -66000421::bigint, 'Mike Gannuscio', 'Mike', 'Gannuscio', 'Republican', 'GANNUSCIO, MIKE (REP)', false),
  ('State House District 30', NULL::uuid, -66000422::bigint, 'David Rose', 'David', 'Rose', 'Republican', 'ROSE, DAVID (REP)', false),
  ('State House District 30', NULL::uuid, -66000423::bigint, 'Brian McMahan', 'Brian', 'McMahan', 'Democratic', 'MCMAHAN, BRIAN (DEM)', false)
) AS v(position_name, pid, ext, full_name, first_name, last_name, party, listed_as, write_in);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'race_candidates' AND column_name = 'is_write_in';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: race_candidates.is_write_in missing — apply CA_0279 first'; END IF;

  SELECT count(*) INTO n FROM ca0282_race;
  IF n <> 60 THEN RAISE EXCEPTION 'PRE: resolved % of 60 AZ legislative races', n; END IF;
  SELECT count(*) INTO n FROM ca0282_race
   WHERE seats <> CASE WHEN position_name LIKE 'State House%' THEN 2 ELSE 1 END OR office_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % races have unexpected seats or no office', n; END IF;

  SELECT count(*) INTO n FROM ca0282_cand;
  IF n <> 162 THEN RAISE EXCEPTION 'PRE: % of 162 entries', n; END IF;
  SELECT count(*) INTO n FROM ca0282_cand c LEFT JOIN ca0282_race r USING (position_name) WHERE r.race_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % entries name no race', n; END IF;

  -- The races are empty, apart from rows this file wrote.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0282_race r ON r.race_id = rc.race_id
   WHERE coalesce(rc.source, '') NOT LIKE '%added by CA_0282 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows already in the AZ legislative races', n; END IF;

  -- The 71 existing people: as authored, active, and each holds an AZ legislative seat.
  SELECT count(*) INTO n FROM ca0282_cand c JOIN essentials.politicians p ON p.id = c.pid
   WHERE p.full_name = c.full_name AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   JOIN essentials.offices o ON o.id = och.office_id
                   JOIN essentials.districts d ON d.id = o.district_id
                  WHERE och.politician_id = p.id AND d.state = 'az'
                    AND d.district_type IN ('STATE_UPPER', 'STATE_LOWER'));
  IF n <> 71 THEN RAISE EXCEPTION 'PRE: only % of 71 existing people are seated AZ legislators as authored', n; END IF;
  SELECT count(DISTINCT pid) INTO n FROM ca0282_cand WHERE pid IS NOT NULL;
  IF n <> 71 THEN RAISE EXCEPTION 'PRE: % distinct existing people, expected 71', n; END IF;

  -- The external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0282_cand c JOIN essentials.politicians p ON p.external_id = c.ext
   WHERE p.full_name <> c.full_name OR p.source NOT LIKE 'CA_0282 (2026-09-24):%';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000333..-66000423 are taken by someone else', n; END IF;

  -- No new person already exists in Arizona: no seat there and no AZ candidacy under the same name.
  SELECT count(*) INTO n FROM ca0282_cand c JOIN essentials.politicians p
      ON lower(p.full_name) = lower(c.full_name) AND p.external_id IS DISTINCT FROM c.ext
   WHERE c.ext IS NOT NULL
     AND (EXISTS (SELECT 1 FROM essentials.office_current_holder och
                    JOIN essentials.offices o ON o.id = och.office_id
                    JOIN essentials.districts d ON d.id = o.district_id
                   WHERE och.politician_id = p.id AND lower(d.state) = 'az')
          OR EXISTS (SELECT 1 FROM essentials.race_candidates rc
                       JOIN essentials.races ra ON ra.id = rc.race_id
                       JOIN essentials.elections e ON e.id = ra.election_id
                      WHERE rc.politician_id = p.id AND e.state = 'AZ'));
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % new people already exist in Arizona', n; END IF;

  RAISE NOTICE 'CA_0282 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The 91 new people. 88 go in under the name-duplicate guard.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT c.ext, c.first_name, c.last_name, c.full_name, c.party, false, true,
       'CA_0282 (2026-09-24): ' || s.gen || ': '
       || regexp_replace(c.position_name, '^State (Senate|House) District ', CASE WHEN c.position_name LIKE 'State Senate%'
                         THEN 'State Senator - District No. ' ELSE 'State Representative - District No. ' END)
       || ', ' || c.listed_as || CASE WHEN c.write_in THEN ', Write-In Candidate' ELSE '' END, 'manual'
  FROM ca0282_cand c CROSS JOIN ca0282_src s
 WHERE c.ext IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = c.ext)
   AND c.ext NOT IN (-66000379, -66000381, -66000422);

-- 1b. Three share first + last name with an active row, and are DIFFERENT people:
--     David Cook Sr. (HD7; a former AZ representative) vs David Cook, TX House District 96 (5249613b)
--       and David Cook, Tarrant County (TX) Criminal Court No. 1 candidate (ba3e17b7);
--     David Rose (HD30) vs David Rose, Charter Oak Unified (CA) school board (e28814d6);
--     Richard Grayson (HD7, GRN) vs Richard Grayson, AK 2026 U.S. Senate candidate (2fa5d558) — no
--       source ties the two rows together; see the header (POSSIBLE DUPLICATE).
--     The guard is lifted for these three inserts only, then restored.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT c.ext, c.first_name, c.last_name, c.full_name, c.party, false, true,
       'CA_0282 (2026-09-24): ' || s.gen || ': '
       || regexp_replace(c.position_name, '^State (Senate|House) District ', CASE WHEN c.position_name LIKE 'State Senate%'
                         THEN 'State Senator - District No. ' ELSE 'State Representative - District No. ' END)
       || ', ' || c.listed_as || CASE WHEN c.write_in THEN ', Write-In Candidate' ELSE '' END, 'manual'
  FROM ca0282_cand c CROSS JOIN ca0282_src s
 WHERE c.ext IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = c.ext)
   AND c.ext IN (-66000379, -66000381, -66000422);
SET LOCAL essentials.allow_duplicate_name = 'off';

-- ---------------------------------------------------------------------------
-- 2. The 162 November candidacies. Incumbent = holds a seat of this race's district (same chamber).
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, is_write_in, source, result, result_source,
                                        result_recorded_at, last_verified_at)
SELECT r.race_id, p.id, p.full_name, p.first_name, p.last_name,
       EXISTS (SELECT 1 FROM essentials.office_current_holder och
                 JOIN essentials.offices o ON o.id = och.office_id
                 JOIN essentials.offices ro ON ro.id = r.office_id
                WHERE och.politician_id = p.id AND o.district_id = ro.district_id),
       'active', c.write_in,
       s.gen || '; ' || c.listed_as || CASE WHEN c.write_in THEN ', Write-In Candidate' ELSE '' END
       || '; added by CA_0282 (2026-09-24)', 'advanced',
       CASE WHEN c.write_in
            THEN s.gen || ': ' || p.full_name || ' is a registered November write-in candidate'
            WHEN c.listed_as LIKE '%(INDEPENDENT)'
            THEN s.gen || ': ' || p.full_name || ' is on the November ballot (independent; in no primary, ' || s.can || ')'
            ELSE s.gen || ' and ' || s.can || ': ' || p.full_name || ' won the primary and is on the November ballot' END
       || '. Seeded by CA_0282 (2026-09-24).', now(), now()
  FROM ca0282_cand c
  CROSS JOIN ca0282_src s
  JOIN ca0282_race r ON r.position_name = c.position_name
  JOIN essentials.politicians p ON p.id = coalesce(c.pid, (SELECT id FROM essentials.politicians WHERE external_id = c.ext))
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0282_cand c JOIN essentials.politicians p ON p.external_id = c.ext
   WHERE p.is_active AND NOT p.is_incumbent AND p.full_name = c.full_name
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 91 THEN RAISE EXCEPTION 'POST: % of 91 new people are active non-incumbents on exactly one race', n; END IF;

  SELECT count(*) INTO n FROM ca0282_cand c
   WHERE c.pid IS NOT NULL
     AND (SELECT count(*) FROM essentials.race_candidates rc JOIN ca0282_race cr ON cr.race_id = rc.race_id
           WHERE rc.politician_id = c.pid) = 1;
  IF n <> 71 THEN RAISE EXCEPTION 'POST: % of 71 existing people have exactly one row in these races', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0282_race cr ON cr.race_id = rc.race_id
   WHERE rc.is_incumbent;
  IF n <> 64 THEN RAISE EXCEPTION 'POST: % incumbent rows, expected 64 (71 seated, 7 changing chamber)', n; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0282_race cr ON cr.race_id = rc.race_id;
  IF n <> 162 THEN RAISE EXCEPTION 'POST: % rows in the 60 races, expected 162', n; END IF;

  FOR r IN
    SELECT c.position_name, c.expect, c.write_ins,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.is_write_in
               AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS wi
      FROM ca0282_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: AZ % has % live candidates, expected %', r.position_name, r.got, r.expect; END IF;
    IF r.wi <> r.write_ins THEN RAISE EXCEPTION 'POST: AZ % has % live write-ins, expected %', r.position_name, r.wi, r.write_ins; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0282 applied: 60 AZ legislative November fields seeded (162 candidates, 4 write-ins, 91 new people)';
END $$;

COMMIT;

-- CA_0263_phase167_us_house_mn_nh_ks_de_ma_ri.sql
--
-- Slot CA_0263 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Phase 167 (post-primary reconciliation, 2026 U.S. House), taken over from Chris Cantrell by Chris
-- Andrews on 2026-09-24 after 1853-1859 were applied. Clusters MN, NH, KS, DE, MA and RI: the pre-primary
-- fields seeded into each 2026-11-03 GENERAL U.S. House race with provisional_until, now past, still live.
-- Same shape as 1853 / 1856 / 1857: set result ('advanced' | 'not_nominated'), result_source,
-- result_recorded_at, last_verified_at. Method rule 3 of 167-PROGRESS: reconcile against the state's
-- certified GENERAL roster (it answers "who is on the ballot" and is the only source that surfaces a
-- missing candidate); primary results are the cross-check.
--
--   78 rows: 32 advanced, 46 not_nominated. 73 are the overdue provisional rows (MN 42, NH 20, KS 2,
--   DE 2, MA 1, RI 6); 5 are non-provisional rows in the same races that carried no result
--   (KS CD4 Tyndell, Estes, Cranmer; MA-01 Neal, Whalen).
--
-- RULE 5 — NEVER CLEAR provisional_until ON A FIELD KNOWN TO BE INCOMPLETE. Two races keep their flag:
--   NH CD2 — certified list has Robbie Mahrou (IND); we have no row for him.
--   DE At-Large — certified list has Joseph "Dr. Joe" Arminio, the REPUBLICAN NOMINEE (he beat our Earl
--     Cooper in the 2026-09-15 primary); we have no row for him.
--   Their rows get results but keep provisional_until. Every other race's rows have it cleared.
--   Seeding the missing candidates is not a cull (167-PROGRESS: "Neither missing-candidate case is fixed
--   here"); they are listed in the PR.
--
-- SOURCES (each row's result_source names its state's document)
--   MN  Secretary of State 20261103/cand.txt (the general candidate file; 17 U.S. Representative names)
--       + 20260811/ushouse.txt primary results (certified 2026-08-18). candidates.sos.mn.gov is behind a
--       Radware CAPTCHA (untouched); the results file host is not.
--   NH  Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (operator download; mm.nh.gov blocks
--       scripts).
--   KS  Secretary of State KansasGeneral2026.csv (operator download) + Official Vote Totals.
--   DE  Department of Elections general candidate list (2026-09-24) + primary ENR JSON (OFFICIAL RESULTS).
--   MA  Secretary of the Commonwealth 2026 State Election Candidates (operator copy of the page text).
--       Jeromie Whalen (MA-01, non-provisional) is not on it: not_nominated.
--   RI  2026-09-09 primary ENR API (isOfficialResults true) + the 2026-07-30 Declared Candidates Report
--       (Pedro DeSouza, Independent, qualified for the election ballot). CD2's Republican nominee is
--       Victor Mellor (8,837), not Stephen Skoly (6,380). No post-primary RI list exists; weakest source here.
--
-- NOT HERE: WI CD3/4/6 (4 rows — Provance, Burks, Fitzgibbon, Thurow — none was on the primary ballot and
-- WEC has published no November list: held, untouched, flag intact); TN, CT, AZ (separate).
--
-- IDEMPOTENT: guarded on result IS NULL. Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one
-- transaction, then rolled back and re-read.
-- ROLLBACK (once applied): UPDATE essentials.race_candidates SET result = NULL, result_source = NULL,
--   result_recorded_at = NULL WHERE result_source LIKE '%Recorded by CA_0263 (2026-09-24).'; and restore
--   provisional_until to each state's primary date on the rows it cleared (MN 2026-08-12, NH 2026-09-08,
--   KS 2026-09-01, MA 2026-08-25, RI 2026-09-09).

BEGIN;

CREATE TEMP TABLE ca0263_target ON COMMIT DROP AS
SELECT v.rc_id, v.st, v.full_name, v.result, v.clear_provisional, v.result_source
FROM (VALUES
  ('85137bd6-0219-4bf4-865f-b0621de3daaa'::uuid, 'MN', 'Alex Eaton', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Alex Eaton: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('cc79c259-e989-4d2a-aba0-c4e1ab352aa7'::uuid, 'MN', 'Brad Finstad', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Brad Finstad: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('17912055-5354-452b-92ff-b00a87da63f5'::uuid, 'MN', 'Gregory A. Goetzman', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Gregory A. Goetzman: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('1e1f17e1-26d8-4246-b0a3-52ba981f5e06'::uuid, 'MN', 'Jake Johnson', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Jake Johnson: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('c7a69ad4-2349-40d1-b478-5e9f634bffe7'::uuid, 'MN', 'Oliver R. Morlan', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Oliver R. Morlan: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('fac9640e-758c-4915-9a65-28d152473e16'::uuid, 'MN', 'Abdi Abdulle', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Abdi Abdulle: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('5002c6bd-d487-4392-bb7f-2a794b8a6ce5'::uuid, 'MN', 'Christopher Mosel', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Christopher Mosel: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('4158e0ac-e400-4b01-ac8a-453c5a370308'::uuid, 'MN', 'Eric Pratt', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Eric Pratt: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('c694dd01-bf0f-4251-a8e2-b7d90c6c43e4'::uuid, 'MN', 'Hugh McTavish', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Hugh McTavish: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('8fbb317e-8a84-4889-9583-0841ac69da01'::uuid, 'MN', 'Kaela Berg', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Kaela Berg: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('21727028-c911-4be8-891a-95654de2a820'::uuid, 'MN', 'Matt Little', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Matt Little: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('13bdc18a-3447-49b1-a348-2e39728b8677'::uuid, 'MN', 'Matthew D. Klein', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Matthew D. Klein: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('c3d3e28b-4e31-4f4c-b785-8efbfd3fd70d'::uuid, 'MN', 'Kelly Morrison', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Kelly Morrison: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('dc371fd1-cae5-4d00-ad58-3569e1c1868a'::uuid, 'MN', 'Quentin Wittrock', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Quentin Wittrock: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('d1999bb6-8e1a-43f3-8731-b4fe885f5e35'::uuid, 'MN', 'Tyler Bass', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Tyler Bass: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('35713aef-8dce-4035-84e5-601820b059ea'::uuid, 'MN', 'Aswar Rahman', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Aswar Rahman: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('69d5c0d8-4b88-42d0-a738-e2b932e3789f'::uuid, 'MN', 'Betty McCollum', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Betty McCollum: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('5bc8dfb3-3153-4a1a-acad-49039e8f8883'::uuid, 'MN', 'Gene Rechtzigel', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Gene Rechtzigel: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('cab9b5af-1158-4dc8-85f9-035faeb56d9c'::uuid, 'MN', 'Paul Wikstrom', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Paul Wikstrom: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('21810905-b8de-46a9-8b10-5983270428b9'::uuid, 'MN', 'Paul Xiong', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Paul Xiong: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('6c8f9410-1e43-4715-84ad-2aea43989355'::uuid, 'MN', 'Abbey Zieska', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Abbey Zieska: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('b1fc7c56-3d8c-4d4c-abe3-69153f662c10'::uuid, 'MN', 'Abena A. McKenzie', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Abena A. McKenzie: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('d308b384-2959-4005-bee3-40d9516c6ac9'::uuid, 'MN', 'Angie Windhauser', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Angie Windhauser: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('d89e5a8a-f4cc-4b88-96ea-42ca602a9c9b'::uuid, 'MN', 'Dalia Al-Aqidi', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Dalia Al-Aqidi: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('4aa10c13-4a7f-43bd-93e5-2fe53bfecc07'::uuid, 'MN', 'DeVelle L. Jackson', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). DeVelle L. Jackson: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('b402d5e0-e0fc-4809-80c7-597157d2ae07'::uuid, 'MN', 'Ilhan Omar', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Ilhan Omar: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('b683c3a8-8e53-4aa5-a4e1-7ed80e778f97'::uuid, 'MN', 'John Nagel', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). John Nagel: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('7c87c577-e1bf-4d09-9e73-3bae4726a74a'::uuid, 'MN', 'Julie Trang Le', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Julie Trang Le: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('8fd19d08-d687-4f5f-b7bc-7600fafa0d60'::uuid, 'MN', 'Latonya T. Reeves', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Latonya T. Reeves: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('64a2966a-3076-4018-b5ff-8a77672a100d'::uuid, 'MN', 'Nate Schluter', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Nate Schluter: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('9e400ca5-c186-4f8b-a30d-82238aaa676a'::uuid, 'MN', 'Chris Corey', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Chris Corey: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('d304d71d-8b67-424a-8148-37e8adcca217'::uuid, 'MN', 'Doug Chapin', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Doug Chapin: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('960564d7-8c3a-4da0-a5ef-70920d0fd5ab'::uuid, 'MN', 'Mike Foley', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Mike Foley: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('b1bfe00f-9dce-4c41-9db7-1548956e1663'::uuid, 'MN', 'Tom Emmer', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Tom Emmer: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('4bf01c51-2a3b-4e37-9d78-5049b4f1e01e'::uuid, 'MN', 'Erik Osberg', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Erik Osberg: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('8353a4cb-141f-490e-9145-cd58d3218189'::uuid, 'MN', 'Michelle Fischbach', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Michelle Fischbach: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('79e76625-bd47-4597-8966-40af742e68bd'::uuid, 'MN', 'Steve Carlson', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Steve Carlson: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('d2387a8e-65a1-455e-81b3-e7ca2b3fd986'::uuid, 'MN', 'Anthony Hamilton', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Anthony Hamilton: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('0ce51764-587b-4f9c-93e0-ac6b8940bbdf'::uuid, 'MN', 'John Munter', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). John Munter: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('2aeb7180-a98a-4279-bad0-e7f92acab56b'::uuid, 'MN', 'Luke Gulbranson', 'not_nominated', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Luke Gulbranson: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('98ca2883-f97a-4d54-8849-a91fed0db3ed'::uuid, 'MN', 'Pete Stauber', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Pete Stauber: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('6856c62d-5df7-4c05-8992-9e806f658158'::uuid, 'MN', 'Trina Swanson', 'advanced', true,
   'Minnesota Secretary of State 2026-11-03 general candidate file (electionresultsfiles.sos.mn.gov/20261103/cand.txt); primary results 20260811/ushouse.txt (State Canvassing Board certified 2026-08-18). Trina Swanson: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('4e86b181-3de5-43fa-b6f9-8cebcc29ea62'::uuid, 'NH', 'Anthony DiLorenzo', 'advanced', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Anthony DiLorenzo: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('7c2a2569-5f31-4083-a1d0-8a21b3544c6d'::uuid, 'NH', 'Bill Conlin', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Bill Conlin: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('70babb0a-4b52-44c2-8d3e-772d4c6baddc'::uuid, 'NH', 'Brian Cole', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Brian Cole: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('66e52073-c373-48e8-8411-4869647e9780'::uuid, 'NH', 'Carleigh Beriont', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Carleigh Beriont: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('fe089d2e-7e57-434f-bdbc-388134ded2d6'::uuid, 'NH', 'Christian Urrutia', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Christian Urrutia: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('b6c20e0f-918c-484f-aa41-9d11a3662cd3'::uuid, 'NH', 'Heath Howard', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Heath Howard: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('0978050e-8dbf-40b0-b447-f481e9f02d24'::uuid, 'NH', 'Hollie Noveletsky', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Hollie Noveletsky: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('37b1c338-fab3-4801-8e52-88cb1f5ded16'::uuid, 'NH', 'Lindsey Anderson', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Lindsey Anderson: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('f4554231-c4d6-441b-a108-0444ae241313'::uuid, 'NH', 'Matthew Emerson', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Matthew Emerson: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('b1b8a18c-e0b8-42bb-b119-7b668b318400'::uuid, 'NH', 'Maura Sullivan', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Maura Sullivan: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('18357e37-9923-4c38-85d7-3bb577c2e687'::uuid, 'NH', 'Melissa Bailey', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Melissa Bailey: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('84b50378-9d30-4906-acd3-c7ae4335dbf6'::uuid, 'NH', 'Sarah Bella Spinosa', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Sarah Bella Spinosa: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('58d1f921-eb76-422f-a46c-46c1407329c5'::uuid, 'NH', 'Sarah Chadzynski', 'not_nominated', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Sarah Chadzynski: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('fe026b5f-50cc-494b-8e3a-ff6f12e8fd15'::uuid, 'NH', 'Stefany Shaheen', 'advanced', true,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Stefany Shaheen: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('0a748b7b-f9c6-4ded-a249-375708c01911'::uuid, 'NH', 'Dan Nicholson', 'not_nominated', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Dan Nicholson: NOT on the certified November ballot (lost the primary or never qualified); race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('f7d7f4d0-942b-416b-9b98-ac2d0209d7fc'::uuid, 'NH', 'Lily Tang Williams', 'advanced', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Lily Tang Williams: on the certified November ballot; race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('910046e6-0f0e-4590-9447-97edf90e2b98'::uuid, 'NH', 'Maggie Goodlander', 'advanced', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Maggie Goodlander: on the certified November ballot; race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('1ea89fe6-5826-4f93-9a82-290d05d2d621'::uuid, 'NH', 'Michael Callis', 'not_nominated', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Michael Callis: NOT on the certified November ballot (lost the primary or never qualified); race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('f60745ba-1b14-4132-a4dd-22b6c869222a'::uuid, 'NH', 'Paige Beauchemin', 'not_nominated', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Paige Beauchemin: NOT on the certified November ballot (lost the primary or never qualified); race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('6ded3794-5f4f-4ac4-b189-5723ee4705b1'::uuid, 'NH', 'Victor Orlando', 'not_nominated', false,
   'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24), Representative in Congress. Victor Orlando: NOT on the certified November ballot (lost the primary or never qualified); race stays flagged: certified candidate(s) missing from our field: Robbie Mahrou (IND). Recorded by CA_0263 (2026-09-24).'),
  ('b8eecbc8-18cd-456e-9cda-d67cbf652a28'::uuid, 'KS', 'Drew Cranmer', 'advanced', true,
   'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24) and 2026 Primary Election Official Vote Totals (U.S. House District 4: D Carmichael, Epley, Gilbert, Tyndell; R Estes, McCollum). Drew Cranmer: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('651a06ca-318d-4c40-9f16-ddff0cc593cc'::uuid, 'KS', 'Katy Tyndell', 'advanced', true,
   'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24) and 2026 Primary Election Official Vote Totals (U.S. House District 4: D Carmichael, Epley, Gilbert, Tyndell; R Estes, McCollum). Katy Tyndell: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('42aef057-2dd9-4d18-80f5-93f7d1148460'::uuid, 'KS', 'Michael Gaynor', 'not_nominated', true,
   'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24) and 2026 Primary Election Official Vote Totals (U.S. House District 4: D Carmichael, Epley, Gilbert, Tyndell; R Estes, McCollum). Michael Gaynor: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('5c6aea64-3614-43af-9b8c-6bfd17781bda'::uuid, 'KS', 'Paul Catanese', 'not_nominated', true,
   'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24) and 2026 Primary Election Official Vote Totals (U.S. House District 4: D Carmichael, Epley, Gilbert, Tyndell; R Estes, McCollum). Paul Catanese: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('025a9ecc-5db0-465c-8b42-5e0aea994d41'::uuid, 'KS', 'Ron Estes', 'advanced', true,
   'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24) and 2026 Primary Election Official Vote Totals (U.S. House District 4: D Carmichael, Epley, Gilbert, Tyndell; R Estes, McCollum). Ron Estes: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('70a8e800-6ce0-480b-b986-d2e70acc0c9e'::uuid, 'DE', 'Earl Cooper', 'not_nominated', false,
   'Delaware Department of Elections 2026 General Election candidate list (genl_fcddt_2026.html, 2026-09-24: McBride D Qualified 6/12/2026, Arminio R Qualified 7/14/2026) and the 2026-09-15 primary ENR JSON (OFFICIAL RESULTS: Republican, Arminio over Earl L. Cooper). Earl Cooper: NOT on the certified November ballot (lost the primary or never qualified); race stays flagged: certified candidate(s) missing from our field: Joseph "Dr. Joe" Arminio (R, the nominee). Recorded by CA_0263 (2026-09-24).'),
  ('78dd9d2c-88a5-4f34-a250-ec7e196f1160'::uuid, 'DE', 'Sarah McBride', 'advanced', false,
   'Delaware Department of Elections 2026 General Election candidate list (genl_fcddt_2026.html, 2026-09-24: McBride D Qualified 6/12/2026, Arminio R Qualified 7/14/2026) and the 2026-09-15 primary ENR JSON (OFFICIAL RESULTS: Republican, Arminio over Earl L. Cooper). Sarah McBride: on the certified November ballot; race stays flagged: certified candidate(s) missing from our field: Joseph "Dr. Joe" Arminio (R, the nominee). Recorded by CA_0263 (2026-09-24).'),
  ('2b9cc68e-5eb9-4259-acda-338bf283c58a'::uuid, 'MA', 'Jeromie Whalen', 'not_nominated', true,
   'Secretary of the Commonwealth, 2026 State Election Candidates, Representative in Congress First District (read by the operator 2026-09-24): Richard E. Neal; Nadia Donya Milleron, Independent/Unenrolled. Jeromie Whalen: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('a4aeb4c8-02e1-4c77-83be-76f41775c15d'::uuid, 'MA', 'Nadia Milleron', 'advanced', true,
   'Secretary of the Commonwealth, 2026 State Election Candidates, Representative in Congress First District (read by the operator 2026-09-24): Richard E. Neal; Nadia Donya Milleron, Independent/Unenrolled. Nadia Milleron: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('9bce4e4c-a8b9-43ed-85d5-028a65b47964'::uuid, 'MA', 'Richard Neal', 'advanced', true,
   'Secretary of the Commonwealth, 2026 State Election Candidates, Representative in Congress First District (read by the operator 2026-09-24): Richard E. Neal; Nadia Donya Milleron, Independent/Unenrolled. Richard Neal: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('b31eca69-173a-438b-9eda-20a93d8450dc'::uuid, 'RI', 'Gabe Amo', 'advanced', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Gabe Amo: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('db8645df-c7f0-4624-aac5-3b915fcb6666'::uuid, 'RI', 'Kellie Keenan', 'advanced', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Kellie Keenan: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('8b1ee110-3dc6-4582-a403-3fe8ece8c84b'::uuid, 'RI', 'Pedro DeSouza', 'advanced', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Pedro DeSouza: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('e55dc1ed-14d9-4092-8489-8928ba8690c5'::uuid, 'RI', 'Seth Magaziner', 'advanced', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Seth Magaziner: on the certified November ballot. Recorded by CA_0263 (2026-09-24).'),
  ('06508814-6181-44c4-bced-9a1935fafe55'::uuid, 'RI', 'Stephen Skoly', 'not_nominated', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Stephen Skoly: NOT on the certified November ballot (lost the primary or never qualified). Recorded by CA_0263 (2026-09-24).'),
  ('c967eb2f-8eab-46a7-9a83-2b41353ac073'::uuid, 'RI', 'Victor Mellor', 'advanced', true,
   'Rhode Island 2026-09-09 primary ENR API (isOfficialResults true: CD1 D Amo 56,255, R Keenan 7,155; CD2 D Magaziner 55,135, R Mellor 8,837 over Skoly 6,380) and the Declared Candidates Report (2026-07-30: DeSouza, Independent, qualified for the election ballot). Victor Mellor: on the certified November ballot. Recorded by CA_0263 (2026-09-24).')
) AS v(rc_id, st, full_name, result, clear_provisional, result_source);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0263_target;
  IF n <> 78 THEN RAISE EXCEPTION 'PRE: % rows listed, expected 78', n; END IF;

  -- Each row: same id + name, a 2026-11-03 GENERAL U.S. House race in that state, live, and untouched or
  -- already written by this file.
  SELECT count(*) INTO n
    FROM ca0263_target t
    JOIN essentials.race_candidates rc ON rc.id = t.rc_id AND rc.full_name = t.full_name
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name ~* '^(U\.S\. Representative|U\.S\. House)'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'general'
                               AND e.election_date = '2026-11-03' AND e.state = t.st
   WHERE rc.candidate_status <> 'withdrawn'
     AND (rc.result IS NULL OR (rc.result = t.result AND rc.result_source = t.result_source));
  IF n <> 78 THEN RAISE EXCEPTION 'PRE: only % of 78 rows match id / name / race / state', n; END IF;

  -- Nothing unreviewed: in every race this file touches, every row without a result is listed.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT rc2.race_id FROM essentials.race_candidates rc2 JOIN ca0263_target t ON t.rc_id = rc2.id)
     AND rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.id NOT IN (SELECT rc_id FROM ca0263_target);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows in these races were not reviewed', n; END IF;

  RAISE NOTICE 'CA_0263 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- Record the reconciliation. provisional_until cleared only where the race is complete (rule 5).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = t.result,
       result_source      = t.result_source,
       result_recorded_at = now(),
       last_verified_at   = now(),
       provisional_until  = CASE WHEN t.clear_provisional THEN NULL ELSE rc.provisional_until END,
       updated_at         = now()
  FROM ca0263_target t
 WHERE rc.id = t.rc_id
   AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0263_target t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result = t.result AND rc.result_source = t.result_source
     AND (NOT t.clear_provisional OR rc.provisional_until IS NULL);
  IF n <> 78 THEN RAISE EXCEPTION 'POST: % of 78 rows in the expected end state', n; END IF;

  -- THE POINT: each race's live field equals its certified count (live = is_live_candidate).
  FOR r IN
    SELECT e.state, ra.position_name, x.expect,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = ra.id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got
      FROM (VALUES ('MN','U.S. Representative District 1',2),('MN','U.S. Representative District 2',2),
                   ('MN','U.S. Representative District 3',2),('MN','U.S. Representative District 4',2),
                   ('MN','U.S. Representative District 5',3),('MN','U.S. Representative District 6',2),
                   ('MN','U.S. Representative District 7',2),('MN','U.S. Representative District 8',2),
                   ('NH','U.S. Representative District 1',2),('NH','U.S. Representative District 2',2),
                   ('KS','U.S. Representative District 4',3),('DE','U.S. Representative At-Large',1),
                   ('MA','U.S. House MA-01',2),('RI','U.S. Representative District 1',3),
                   ('RI','U.S. Representative District 2',2)) AS x(st, pos, expect)
      JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
      JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.pos
  LOOP
    IF r.got <> r.expect THEN
      RAISE EXCEPTION 'POST: % % has % live candidates, expected % (certified field we hold)', r.state, r.position_name, r.got, r.expect;
    END IF;
  END LOOP;

  -- Rule 5: the two incomplete races are still flagged.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0263_target t ON t.rc_id = rc.id
   WHERE NOT t.clear_provisional AND rc.provisional_until IS NOT NULL;
  IF n <> (SELECT count(*) FROM ca0263_target WHERE NOT clear_provisional) THEN
    RAISE EXCEPTION 'POST: an incomplete race lost its provisional flag';
  END IF;

  RAISE NOTICE 'CA_0263 applied: 78 rows (32 advanced, 46 not_nominated); NH CD2 and DE stay flagged for missing certified candidates';
END $$;

COMMIT;

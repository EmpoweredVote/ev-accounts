-- CC_0378 — 2026-11-03 California school and community-college boards: record the 49 contests
--           that are decisive against Los Angeles County's own outstanding-ballot estimate.
--
-- WHY THIS FILE EXISTS. 197 school-board seats hand over on 2026-12-11 (Cal. Educ. Code § 5017,
--   second Friday in December, with a 15-day window to the organisational meeting under
--   § 35143). It is the bulk of the December local wave and the second piece of it, after
--   CC_0377's 19 special districts. Same two counties, same pipeline, same arithmetic.
--
-- 🔴🔴 THE HEADLINE IS NOT THE 49. IT IS THAT 96 OF THESE 197 ELECTIONS WERE NEVER HELD.
--   Los Angeles County cancelled them for insufficiency of candidates and the seats are filled
--   by APPOINTMENT IN LIEU OF ELECTION (Educ. Code § 5328 / Elec. Code § 10515). An appointee
--   takes office exactly as if elected, on the same 2026-12-11.
--   ▶ So nearly half of this wave has a determinate outcome today and no result to record,
--     and NOTHING IN OUR DATA SAYS SO. The races sit with candidates, no winner, and no
--     explanation — indistinguishable from a count we have not read yet.
--   🔴 THIS FILE DOES NOT TOUCH THEM. We know the election was cancelled; we do NOT yet know
--     WHO was appointed, and our own candidate rows cannot answer it — they come from the
--     September nomination list, and insufficiency was determined after the extended filing
--     period closed on 2026-08-12. Azusa Trustee Area 3 is the proof: we hold two candidates
--     for one seat and the county still cancelled it, so at least one of ours never qualified.
--     ▶ Naming an appointee from our stale list would be guessing an officeholder, which is
--       this repo's most expensive error. It needs each district's own record. See
--       backend/data/ca-school-boards-2026-results/NOTES.md.
--
-- 🔴 AN ABSENCE IS NOT A FINDING UNTIL A SOURCE NAMES IT. All 96 were checked ONE BY ONE
--   against the RR/CC's own "FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF
--   ELECTION DUE TO INSUFFICIENCY OF CANDIDATES" for this election, and **96 of 96 are named
--   on it**. The list, the parser and its controls are committed beside this file.
--   ⚠ A TENTATIVE version of that list is served from a nearly identical URL and predates the
--     extended nomination period. The check refuses any PDF that does not say FINAL.
--
-- WHAT IT WRITES: 122 existing candidacies UPDATED across 49 races — 59 won, 63 lost, every one
--   result_certainty = 'called'. No politician, race, office or term is created or deleted.
--   🔴 EVERY PRIOR VALUE OF EVERY COLUMN THIS FILE TOUCHES IS NULL on all 122 rows — result,
--     result_certainty, result_source and result_recorded_at alike. There is no history table
--     and no replayable runner, so that is recorded here and the gate REFUSES to overwrite
--     anything that is not NULL.
--
-- THE CALL IS OURS, AND IT IS ARITHMETIC. Neither county publishes a winner flag, so a contest
--   is recorded only when the trailing candidate could not overtake the leader EVEN IF EVERY
--   BALLOT STILL UNCOUNTED IN THAT CONTEST BROKE THEIR WAY. LA's countywide estimate (131,000
--   outstanding against 3,041,114 counted, read 2026-11-08) is apportioned by each contest's
--   share of ballots cast and multiplied by three. The gate recomputes that decision inside
--   this transaction. Method and its limits: CC_0377, and NOTES.md beside it.
--
-- 🔴 52 ANCHORED RACES ARE DELIBERATELY LEFT NULL:
--   - 48 because the margin does not clear the bound. LA certifies by 2026-12-01 and these
--     seats turn over on 2026-12-11, so there is time.
--   - 4 because the district STRADDLES A COUNTY LINE and only Los Angeles's slice was found:
--     Antelope Valley Community College Area 2 and Antelope Valley Joint Union High Area 1
--     (Kern), Las Virgenes Unified (Ventura), Rowland Unified Area 5 (Orange). The county
--     flags these itself in the contest's own text. Ranking a board on one county's share of
--     its electorate is the Wrightwood trap from CC_0377, and it is refused here too.
--
-- ⚠ FOUR RACES CARRY A CANDIDATE THE COUNTY'S FINAL BALLOT DOES NOT, and the result is
--   recorded anyway for everyone who IS on it. Joe Radabaugh (La Cañada Unified), Alfonso
--   Morales (Lynwood Unified), Rick Phillips (Palos Verdes Peninsula Unified) and Tomas Ursua
--   (Pomona Unified Area 1) each hold a candidacy sourced from the September nomination list
--   and appear on no ballot the county printed. Their rows are LEFT UNTOUCHED — "never filed"
--   means deleting the row and "withdrew" means setting candidate_status, and those are
--   opposite acts that need a source neither this file nor the results feed provides.
--   🔴 ONLY POMONA AREA 1 OF THE FOUR IS RECORDED HERE; the other three are held on the bound,
--     so Tomas Ursua is the ONLY name this file's "not on the ballot" allowance may carry.
--     ⚠ The first draft listed all four, and the allowance's own staleness gate refused the
--       file: three of them sit in races this file never measures, so naming them would have
--       been an exemption with nothing behind it. A gated allowance catches its own author.
--
-- SOURCING. results.lavote.gov, election 4348: ElectionResults/GetElectionData (the ballot —
--   every Votes field is 0) joined to ElectionResults/GetCounterData (the counts, keyed by
--   candidate id), then re-read against results.lavote.gov/text-results/4348, which the server
--   renders independently from the same data. All 122 numbers agree across the two readings.
--
-- ⚠ TWO OF THESE RACES MATCH ON A RELAXED NAME. The county prints "CHERYL SHAW WILLIAMS" and
--   "BRANDON GEORGE MYERS" where we hold "Cheryl Williams" and "Brandon Myers", so full-name
--   equality reported both Inglewood contests as if nobody on our ballot was on the county's.
--   The matcher now also compares first-plus-last, and asserts that relaxation stays
--   one-to-one inside a contest before any of it is trusted.
--
-- Slot reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  district     text NOT NULL,
  office_title text NOT NULL,
  race_id      uuid NOT NULL,
  rc_id        uuid PRIMARY KEY,
  ballot_name  text NOT NULL,   -- exactly as Los Angeles County prints it
  votes        int  NOT NULL,
  rank         int  NOT NULL,
  outcome      text NOT NULL CHECK (outcome IN ('won', 'lost'))
) ON COMMIT DROP;

INSERT INTO called (district, office_title, race_id, rc_id, ballot_name, votes, rank, outcome) VALUES
  -- ABC Unified School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 1381 vs bound 783
  ('ABC Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '270cd1c6-014b-4969-9b83-24e2911e3e33'::uuid, '5b75d9c5-576d-459e-b721-6fd8db0366e1'::uuid, 'SOO YOO', 3373, 1, 'won'),
  ('ABC Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '270cd1c6-014b-4969-9b83-24e2911e3e33'::uuid, 'f27b9cdc-8aaa-4608-bb49-4bc731160cd5'::uuid, 'AL BARLEVY', 1992, 2, 'lost'),
  -- Antelope Valley Community College Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 4449 vs bound 2565
  ('Antelope Valley Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'c619f14b-7b05-5efd-9a01-3c0ca9985b52'::uuid, 'accd96af-ee24-440a-8f9d-7e76e6e90883'::uuid, 'BARBARA GAINES', 10747, 1, 'won'),
  ('Antelope Valley Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'c619f14b-7b05-5efd-9a01-3c0ca9985b52'::uuid, 'bcd7553b-18c7-4eb4-9c8c-98662a125f97'::uuid, 'PAMELA FORD', 6298, 2, 'lost'),
  -- Azusa Unified School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 747 vs bound 555
  ('Azusa Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '16f4d35c-f0f9-48f5-8363-ab75eb1c85f2'::uuid, '5e6920a5-0a61-412d-bcc5-28cbdf0fd7b1'::uuid, 'GABRIELA ARELLANES', 2152, 1, 'won'),
  ('Azusa Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '16f4d35c-f0f9-48f5-8363-ab75eb1c85f2'::uuid, '023acff7-789d-42b1-9f96-403affa88f65'::uuid, 'MARCOS C. GONZALES JR.', 1405, 2, 'lost'),
  -- Bellflower Unified School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 2048 vs bound 867
  ('Bellflower Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '21aff53c-3894-4475-a2b6-0695d090035f'::uuid, '112aec39-6d20-42e1-ab59-0bacb40f8a0c'::uuid, 'BRAD W. CRIHFIELD', 3761, 1, 'won'),
  ('Bellflower Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '21aff53c-3894-4475-a2b6-0695d090035f'::uuid, '4ba0b511-fb10-4037-9ef2-c342f6900e4a'::uuid, 'TODD J. ROBERTS', 1713, 2, 'lost'),
  -- Burbank Unified School Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 1076 vs bound 975
  ('Burbank Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '219875d8-4b41-434d-a118-40b6cfca3663'::uuid, 'a37e13f2-3bf8-4a9e-a0a0-40b9fc42ab56'::uuid, 'ROSEMARY T. MORRISON', 3078, 1, 'won'),
  ('Burbank Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '219875d8-4b41-434d-a118-40b6cfca3663'::uuid, '6adddff6-2d7e-4e66-8db1-0ccff43a5966'::uuid, 'PAUL GERARD', 2002, 2, 'lost'),
  ('Burbank Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '219875d8-4b41-434d-a118-40b6cfca3663'::uuid, '1a52f1f5-0ca6-48c3-b509-cbfb3b528ad8'::uuid, 'HAI HO', 688, 3, 'lost'),
  ('Burbank Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '219875d8-4b41-434d-a118-40b6cfca3663'::uuid, 'f521dbd9-cd6c-4879-a4e8-a02212ec004c'::uuid, 'DENNIS M. CONNOR', 293, 4, 'lost'),
  ('Burbank Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '219875d8-4b41-434d-a118-40b6cfca3663'::uuid, 'd55db5ae-8f4d-4348-8804-c2342f919b83'::uuid, 'EVREN OZBEY', 55, 5, 'lost'),
  -- Compton Community College Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 5595 vs bound 1494
  ('Compton Community College Board - Trustee Area 1', 'Board Member (Trustee Area 1)', 'debec051-f18a-5bcf-bf36-b6d570d2998b'::uuid, 'd5d5e513-ac90-4369-8a69-0820a363b6eb'::uuid, 'ANDRES RAMOS', 7916, 1, 'won'),
  ('Compton Community College Board - Trustee Area 1', 'Board Member (Trustee Area 1)', 'debec051-f18a-5bcf-bf36-b6d570d2998b'::uuid, '2fe4015f-682b-4f36-9eb2-92d8bfddbc26'::uuid, 'SKYY D. FISHER', 2321, 2, 'lost'),
  -- Compton Community College Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 4005 vs bound 1629
  ('Compton Community College Board - Trustee Area 2', 'Board Member (Trustee Area 2)', 'eaba170e-c0df-51e7-83da-008cebcefc12'::uuid, 'bfedd19f-54b0-44b5-8082-866ad0657251'::uuid, 'NICOLE J. JONES', 7649, 1, 'won'),
  ('Compton Community College Board - Trustee Area 2', 'Board Member (Trustee Area 2)', 'eaba170e-c0df-51e7-83da-008cebcefc12'::uuid, '8c0e54f1-3421-457f-b50b-75fc67bafda8'::uuid, 'ADRIAN D. CLEVELAND', 3644, 2, 'lost'),
  -- Covina-Valley Unified School Board - Trustee Area 4 — Board Member (Trustee Area 4), 1 seat(s); margin 1155 vs bound 759
  ('Covina-Valley Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '7145b7cb-a854-4f0a-b09a-380b342addf6'::uuid, '56d07d64-9704-40f5-baf0-df0071c311a7'::uuid, 'SIMON WRIGHT', 3005, 1, 'won'),
  ('Covina-Valley Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '7145b7cb-a854-4f0a-b09a-380b342addf6'::uuid, 'd51d59ff-c1a7-4634-820c-5a62c385144c'::uuid, 'GARY C. RODRIGUEZ', 1850, 2, 'lost'),
  -- Culver City Unified Board — Board Member, 3 seat(s); margin 3252 vs bound 2409
  ('Culver City Unified Board', 'Board Member', '66659918-b0a8-401c-aa5d-9e654d16f3ba'::uuid, '50ec9c2a-8058-4442-a82f-597b70764cca'::uuid, 'STEPHANIE LOREDO', 10863, 1, 'won'),
  ('Culver City Unified Board', 'Board Member', '66659918-b0a8-401c-aa5d-9e654d16f3ba'::uuid, '0f221378-b043-49bd-9769-655842b23962'::uuid, 'BRIAN GUERRERO', 9873, 2, 'won'),
  ('Culver City Unified Board', 'Board Member', '66659918-b0a8-401c-aa5d-9e654d16f3ba'::uuid, '2c0f64d7-4eaa-4454-b03c-55cdb1c6471b'::uuid, 'TRISTON EZIDORE', 9640, 3, 'won'),
  ('Culver City Unified Board', 'Board Member', '66659918-b0a8-401c-aa5d-9e654d16f3ba'::uuid, '44d8b42e-4e94-46ee-a1be-9ab69366ffed'::uuid, 'DARREL MENTHE', 6388, 4, 'lost'),
  -- Downey Unified School Board - Trustee Area 7 — Board Member (Trustee Area 7), 1 seat(s); margin 1032 vs bound 747
  ('Downey Unified School Board - Trustee Area 7', 'Board Member (Trustee Area 7)', '3eb6bdf0-2040-4b5c-a516-573d82f2e9f3'::uuid, '911c53d3-1be2-4318-a38e-855753f95888'::uuid, 'BETTY LUZ MONROY', 3095, 1, 'won'),
  ('Downey Unified School Board - Trustee Area 7', 'Board Member (Trustee Area 7)', '3eb6bdf0-2040-4b5c-a516-573d82f2e9f3'::uuid, 'ac01ce31-e5d1-4ebf-b0e3-8dc115cf2e6d'::uuid, 'JOSEPH MANACMUL', 2063, 2, 'lost'),
  -- Duarte Unified School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 271 vs bound 204
  ('Duarte Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '38dbc753-4d65-4547-8c72-44683eef8b25'::uuid, '67e11cfe-45e7-498a-90c7-3f32963a325b'::uuid, 'LIZBETH AQUINO', 828, 1, 'won'),
  ('Duarte Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '38dbc753-4d65-4547-8c72-44683eef8b25'::uuid, '4eb1080c-b353-4faf-9fd6-236b5599fcf4'::uuid, 'REYNA E. DIAZ', 557, 2, 'lost'),
  -- East Whittier City School Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 1199 vs bound 759
  ('East Whittier City School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', 'a0cbc782-fdb0-49ec-89a4-b6f35797932a'::uuid, '3bb73739-caf1-4097-90b5-89123651eaf4'::uuid, 'CHRISTINE CHACON KENNEDY', 2987, 1, 'won'),
  ('East Whittier City School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', 'a0cbc782-fdb0-49ec-89a4-b6f35797932a'::uuid, '1bd5ba2a-3fa9-4ae0-9f03-c413eb18d951'::uuid, 'MICHAEL RAMOS', 1788, 2, 'lost'),
  -- Eastside Union School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 223 vs bound 222
  ('Eastside Union School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '08f6ae5d-714e-4d23-8bb1-8f2fd8d7130f'::uuid, '4feef131-a7e1-47ea-8ce4-ab7122c4cee2'::uuid, 'OSCAR MEJIA', 623, 1, 'won'),
  ('Eastside Union School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '08f6ae5d-714e-4d23-8bb1-8f2fd8d7130f'::uuid, 'd7457708-e21c-45ce-8c03-bf806da4d9a9'::uuid, 'TIMOTHY M. WILEY', 400, 2, 'lost'),
  ('Eastside Union School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '08f6ae5d-714e-4d23-8bb1-8f2fd8d7130f'::uuid, 'b4098ebf-844c-482e-b8a4-93de82ea5696'::uuid, 'WAYNE M. KALLIOMAA', 390, 3, 'lost'),
  -- Eastside Union School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 218 vs bound 156
  ('Eastside Union School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '9d890511-f75d-4149-b80a-f8b8ea6a54c2'::uuid, '6273394d-3de1-43da-9948-c353f1da43a9'::uuid, 'ANOUK HARVEY', 627, 1, 'won'),
  ('Eastside Union School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '9d890511-f75d-4149-b80a-f8b8ea6a54c2'::uuid, '0aa09e34-3492-4a46-a354-3bff0f5d323d'::uuid, 'JULIE ANN BOOKMAN', 409, 2, 'lost'),
  -- El Camino Community College Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 14074 vs bound 6198
  ('El Camino Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '2b2c01d2-e142-598c-a4d4-6dbf855d5967'::uuid, '59c1f442-44c6-46e9-9ffd-355436769a87'::uuid, 'MYLOC DINH', 24101, 1, 'won'),
  ('El Camino Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '2b2c01d2-e142-598c-a4d4-6dbf855d5967'::uuid, '96744c5c-a5f7-4283-be95-904de0830b88'::uuid, 'KEICY CHUNG', 10027, 2, 'lost'),
  -- El Monte Union High School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 2452 vs bound 834
  ('El Monte Union High School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'fd556a2b-1b8f-44e6-a110-04496739170f'::uuid, '53f99977-30fb-4871-9957-791cbbd6714a'::uuid, 'RICARDO PADILLA', 4038, 1, 'won'),
  ('El Monte Union High School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'fd556a2b-1b8f-44e6-a110-04496739170f'::uuid, '89fa2b69-b3de-4878-8e70-126d7b753c27'::uuid, 'RAUL PARDO', 1586, 2, 'lost'),
  -- Hacienda La Puente Unified School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 937 vs bound 765
  ('Hacienda La Puente Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '4c14f7d9-6ca1-49f5-aa0f-4c1ff7ec9c8a'::uuid, 'b23fe9ab-72e1-45c2-81c0-4a521b9fd1d3'::uuid, 'NANCY LOERA', 2544, 1, 'won'),
  ('Hacienda La Puente Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '4c14f7d9-6ca1-49f5-aa0f-4c1ff7ec9c8a'::uuid, 'd7e19a91-fffc-406c-b6e7-ed74bacb3e10'::uuid, 'JOHNATHON "JOHNNY" YODER', 1607, 2, 'lost'),
  ('Hacienda La Puente Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '4c14f7d9-6ca1-49f5-aa0f-4c1ff7ec9c8a'::uuid, 'edc3df54-ce57-4ecb-8f25-630d6fd2e08b'::uuid, 'CARMEN EULALIA BASSO', 858, 3, 'lost'),
  ('Hacienda La Puente Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '4c14f7d9-6ca1-49f5-aa0f-4c1ff7ec9c8a'::uuid, '3b908bca-3ef9-4e35-bda5-0fe2cedc1bda'::uuid, 'RICHARD RODRIGUEZ', 225, 4, 'lost'),
  -- Hacienda La Puente Unified School Board - Trustee Area 4 — Board Member (Trustee Area 4), 1 seat(s); margin 1843 vs bound 942
  ('Hacienda La Puente Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '0ce2e6fb-4888-4fac-82cb-2937eafc7987'::uuid, '598585bd-0566-4eeb-8b3d-b449324434a7'::uuid, 'GINO KWOK', 3690, 1, 'won'),
  ('Hacienda La Puente Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '0ce2e6fb-4888-4fac-82cb-2937eafc7987'::uuid, 'adde41a8-3ede-4bd6-9597-ef3959ec302b'::uuid, 'MELISSA C. SMITH', 1847, 2, 'lost'),
  ('Hacienda La Puente Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '0ce2e6fb-4888-4fac-82cb-2937eafc7987'::uuid, '789c37e0-f563-4eb0-85c5-a40bf7d3fa90'::uuid, 'TRAN BAO SATTER', 599, 3, 'lost'),
  -- Inglewood Unified School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 1600 vs bound 1299
  ('Inglewood Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '9db52f31-e7c0-4167-81a8-a3a48c1405bf'::uuid, 'ce1b607c-0555-44d1-b3cf-22b85655367f'::uuid, 'JOYCE RANDALL', 5322, 1, 'won'),
  ('Inglewood Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '9db52f31-e7c0-4167-81a8-a3a48c1405bf'::uuid, '9e13be3e-7b0e-42c8-83ed-e73b3c2db316'::uuid, 'CHERYL SHAW WILLIAMS', 3722, 2, 'lost'),
  -- Inglewood Unified School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 1638 vs bound 1218
  ('Inglewood Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '1ad28f06-ef6a-4b04-8ea4-52dc0c1d4c81'::uuid, '4e01ed5d-1d27-4ce9-bea5-1a8c6286dddc'::uuid, 'JOE W. BOWERS JR.', 4857, 1, 'won'),
  ('Inglewood Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '1ad28f06-ef6a-4b04-8ea4-52dc0c1d4c81'::uuid, '5e21a149-466e-407d-b344-662b3e831f38'::uuid, 'SHELBY RICHARDSON', 3219, 2, 'lost'),
  -- Inglewood Unified School Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 1943 vs bound 735
  ('Inglewood Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '1b84b757-32ba-42b4-b13b-95d54f521b8d'::uuid, '6f9b3c0c-33ef-4cc8-bc21-7508f882f761'::uuid, 'YARITZA A. GONZALEZ', 3616, 1, 'won'),
  ('Inglewood Unified School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '1b84b757-32ba-42b4-b13b-95d54f521b8d'::uuid, '647ff542-47ad-4b1c-a887-65631b21e3b2'::uuid, 'BRANDON GEORGE MYERS', 1673, 2, 'lost'),
  -- Keppel Union School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 129 vs bound 114
  ('Keppel Union School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '30a5efc5-bd50-427d-95ba-776f95a2ce52'::uuid, 'c2d4a2fe-4e51-410b-90c4-891de1ab2177'::uuid, 'BLANCA NAVA', 423, 1, 'won'),
  ('Keppel Union School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '30a5efc5-bd50-427d-95ba-776f95a2ce52'::uuid, 'ae611b38-a2a2-47c2-9629-08c76c3e265b'::uuid, 'KARINA MARTINEZ', 294, 2, 'lost'),
  -- Keppel Union School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 193 vs bound 147
  ('Keppel Union School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '949d2490-a41f-4e47-907e-7e1af08add04'::uuid, '3c1d5850-c53f-4738-b3f3-325e77fd818d'::uuid, 'ALMA I. RODRIGUEZ', 581, 1, 'won'),
  ('Keppel Union School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '949d2490-a41f-4e47-907e-7e1af08add04'::uuid, '27b8e1fa-97ae-4c1d-9d37-5660811f1e3b'::uuid, 'MATTHEW GAINES', 388, 2, 'lost'),
  -- Lancaster School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 1587 vs bound 612
  ('Lancaster School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '143eb42d-2236-482f-bff5-62ad30869a4f'::uuid, '3097b56b-6b8c-4344-ba9b-c6d1cb0a4c83'::uuid, 'OSCAR IRAHETA', 2848, 1, 'won'),
  ('Lancaster School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '143eb42d-2236-482f-bff5-62ad30869a4f'::uuid, '19558026-b69f-4023-870e-1ec453a20842'::uuid, 'DUANE G. WINN', 1261, 2, 'lost'),
  -- Lawndale Elementary School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 394 vs bound 294
  ('Lawndale Elementary School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '7e2bee9a-4311-4f46-b117-30c157eef1b7'::uuid, 'c3176200-0273-4a09-85cc-46d893dfb133'::uuid, 'VARUN "SUNNY" TAMRAKAR', 1221, 1, 'won'),
  ('Lawndale Elementary School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '7e2bee9a-4311-4f46-b117-30c157eef1b7'::uuid, 'de6a673d-f6b9-4242-ae28-4a5540dc1254'::uuid, 'SHIRLEY RUDOLPH', 827, 2, 'lost'),
  -- Little Lake City School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 335 vs bound 303
  ('Little Lake City School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '294bb127-1857-4cf7-a438-7ef482018f76'::uuid, '8d417760-3ad8-4dde-9073-a4a902100e72'::uuid, 'ELIANA TAPIA', 1164, 1, 'won'),
  ('Little Lake City School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '294bb127-1857-4cf7-a438-7ef482018f76'::uuid, 'b2ee4ac7-8c4d-4e42-8be6-af4fb934c10f'::uuid, 'SUSANA RAMIREZ', 829, 2, 'lost'),
  -- Little Lake City School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 510 vs bound 264
  ('Little Lake City School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'a763810d-48c5-40a6-bc41-355025325ddf'::uuid, '79852088-a16f-4228-b78f-29285ca8a1c7'::uuid, 'DORA D. SANDOVAL', 1139, 1, 'won'),
  ('Little Lake City School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'a763810d-48c5-40a6-bc41-355025325ddf'::uuid, '07d04113-3d82-49bc-a6b7-fde469d283ca'::uuid, 'SCHERISE R. ACOSTA', 629, 2, 'lost'),
  -- Los Angeles Community College Board — Board Member (Seat 4), 1 seat(s); margin 534981 vs bound 201744
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '58bb4818-6d7f-4be4-b735-3b6fe2ef0180'::uuid, 'DARRYN HARRIS', 715068, 1, 'won'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '164694ef-c883-479d-9158-a63c31af3ea5'::uuid, 'ELAINE ALANIZ', 180087, 2, 'lost'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, 'cfdbadaf-dc8b-499c-9f6d-e012f57b25a0'::uuid, 'NANCY PEARLMAN', 167505, 3, 'lost'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '5dc32366-c841-4227-a966-5f0715062733'::uuid, 'ISIDRO J. ARMENTA', 71268, 4, 'lost'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '8c1f20c2-665d-484d-b564-5fd4d75acb11'::uuid, 'PRISCILLA UMANA', 59780, 5, 'lost'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '692978f8-7ff1-406d-9a67-bcce72bb1fc1'::uuid, 'JASON R. AULA', 34923, 6, 'lost'),
  ('Los Angeles Community College Board', 'Board Member (Seat 4)', 'e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, '4c5895e5-6f40-4ccb-9758-5eb46091b4c2'::uuid, 'ADAM BRUNO', 21635, 7, 'lost'),
  -- Monrovia Unified School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 934 vs bound 588
  ('Monrovia Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '6dfd8569-bde8-43c3-8187-48063cb73607'::uuid, 'bd1232ac-772c-43c9-97fa-f343fb610c1d'::uuid, 'ABBY VELTMAN', 2372, 1, 'won'),
  ('Monrovia Unified School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '6dfd8569-bde8-43c3-8187-48063cb73607'::uuid, '1cf9d61a-99ae-4ea8-9a34-284b42ac2304'::uuid, 'MARITZA C. TRAVANTI', 1438, 2, 'lost'),
  -- Mountain View Elementary Board — Board Member, 3 seat(s); margin 1574 vs bound 1143
  ('Mountain View Elementary Board', 'Board Member', '90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid, '7d956514-75ce-44fa-b0da-e04c3b5aeae7'::uuid, 'CINDY WU', 4211, 1, 'won'),
  ('Mountain View Elementary Board', 'Board Member', '90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid, 'b6afebd1-fc50-4504-ab33-efceed50b5d9'::uuid, 'ADAM C. CARRANZA', 3842, 2, 'won'),
  ('Mountain View Elementary Board', 'Board Member', '90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid, 'cf1cdb45-b098-40e1-a14c-2c3f0a499460'::uuid, 'VERONICA B. SIFUENTES', 3730, 3, 'won'),
  ('Mountain View Elementary Board', 'Board Member', '90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid, 'e0a4d990-ad9e-4966-86d1-dc943730092b'::uuid, 'GRISELDA SAHARAI OLIVARES', 2156, 4, 'lost'),
  ('Mountain View Elementary Board', 'Board Member', '90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid, '476fc21c-adc3-40e8-bfe2-628bcad1e858'::uuid, 'DARLENE NAVA', 1513, 5, 'lost'),
  -- Norwalk-La Mirada Unified School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 722 vs bound 669
  ('Norwalk-La Mirada Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '31791a9a-97f2-4498-9d0f-96f2866026bc'::uuid, '227d78d0-7d99-4426-b758-aacbd2e49698'::uuid, 'NORMA AMEZCUA', 2653, 1, 'won'),
  ('Norwalk-La Mirada Unified School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '31791a9a-97f2-4498-9d0f-96f2866026bc'::uuid, '0bd93868-c3d9-4e85-9494-e98d0483dca1'::uuid, 'MARYBEL MICAELA LORENZO', 1931, 2, 'lost'),
  -- Norwalk-La Mirada Unified School Board - Trustee Area 4 — Board Member (Trustee Area 4), 1 seat(s); margin 2295 vs bound 579
  ('Norwalk-La Mirada Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', 'c629a781-086e-43d2-b936-f8a4eb0dde92'::uuid, 'b5002a89-91df-4b23-a414-b22fc7b31e04'::uuid, 'ANTHONY ARMENDAREZ', 3044, 1, 'won'),
  ('Norwalk-La Mirada Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', 'c629a781-086e-43d2-b936-f8a4eb0dde92'::uuid, '574047f5-5099-4f1e-b488-d7c86976f9fc'::uuid, 'JOSUE ALVAREZ', 749, 2, 'lost'),
  -- Palmdale School Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 2471 vs bound 717
  ('Palmdale School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '708e81d8-77e0-41cb-9ba3-2c034a772512'::uuid, '918c92ce-6472-4822-8091-c0e8c5b4aa18'::uuid, 'JOANN N. SMITH', 3656, 1, 'won'),
  ('Palmdale School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '708e81d8-77e0-41cb-9ba3-2c034a772512'::uuid, '45e84528-3b08-45c2-aada-8600b79b9f47'::uuid, 'FRANCISCO MAGANA-HUANOSTO', 1185, 2, 'lost'),
  -- Paramount Unified School Board - Trustee Area 4 — Board Member (Trustee Area 4), 1 seat(s); margin 739 vs bound 426
  ('Paramount Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '9ecbd31b-a8ee-4203-87de-4b19c9227003'::uuid, '0c1f1088-f4fd-4dd3-83a4-9d7a5e19adb7'::uuid, 'YESENIA MARIA CUARENTA', 1847, 1, 'won'),
  ('Paramount Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', '9ecbd31b-a8ee-4203-87de-4b19c9227003'::uuid, '92223c90-169c-4406-bece-33c206db7830'::uuid, 'ALICIA LINDEN ANDERSON', 1108, 2, 'lost'),
  -- Pasadena Area Community College Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 8525 vs bound 2472
  ('Pasadena Area Community College Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '19f2a006-7564-5615-8267-31f68b2da2ee'::uuid, '193f3627-adc9-4c89-b5bd-ae41088f9dbb'::uuid, 'STEVE GIBSON', 12467, 1, 'won'),
  ('Pasadena Area Community College Board - Trustee Area 3', 'Board Member (Trustee Area 3)', '19f2a006-7564-5615-8267-31f68b2da2ee'::uuid, '7eb6bbb6-0c22-4664-a1ad-cb4a66829c80'::uuid, 'DAVID COHER', 3942, 2, 'lost'),
  -- Pasadena Area Community College Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 10021 vs bound 2973
  ('Pasadena Area Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'a846e1c1-d1b0-51b7-b1c7-36de16498be1'::uuid, 'f54fd6d7-23a0-4023-8c5d-2412c743443d'::uuid, 'KRISTINE E. KWONG', 14523, 1, 'won'),
  ('Pasadena Area Community College Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'a846e1c1-d1b0-51b7-b1c7-36de16498be1'::uuid, '5af4e5f7-0779-4179-8b34-599d9e377881'::uuid, 'JENNIFER THOMPSON', 4502, 2, 'lost'),
  -- Pasadena Unified School Board - District 1 — Board Member (District 1), 1 seat(s); margin 1504 vs bound 1125
  ('Pasadena Unified School Board - District 1', 'Board Member (District 1)', 'de728759-3788-4129-bdfd-1ccc6bb5ef96'::uuid, '34ad9972-2212-437c-a8c7-6b30e6dbee9d'::uuid, 'FELITA KEALING', 4450, 1, 'won'),
  ('Pasadena Unified School Board - District 1', 'Board Member (District 1)', 'de728759-3788-4129-bdfd-1ccc6bb5ef96'::uuid, 'fdbe721f-0b28-4321-8a77-114144febca6'::uuid, 'KIMBERLY KENNE', 2946, 2, 'lost'),
  -- Pasadena Unified School Board - District 3 — Board Member (District 3), 1 seat(s); margin 2060 vs bound 1284
  ('Pasadena Unified School Board - District 3', 'Board Member (District 3)', '65e6909a-10d0-404d-b2c9-2a65570eeb3a'::uuid, 'dbcc9e31-db7e-4250-837a-b304ce80857d'::uuid, 'MICHELLE RICHARDSON BAILEY', 5395, 1, 'won'),
  ('Pasadena Unified School Board - District 3', 'Board Member (District 3)', '65e6909a-10d0-404d-b2c9-2a65570eeb3a'::uuid, '1d73fb52-1720-4ae0-a91e-0880baa40e08'::uuid, 'VERONICA ELIAS', 3335, 2, 'lost'),
  -- Pasadena Unified School Board - District 7 — Board Member (District 7), 1 seat(s); margin 2295 vs bound 1857
  ('Pasadena Unified School Board - District 7', 'Board Member (District 7)', 'b365f207-73b4-4318-aee8-8911762a5909'::uuid, '67136c33-2ced-451b-a968-fb55dcb438ba'::uuid, 'CYNTHIA TORRES', 7115, 1, 'won'),
  ('Pasadena Unified School Board - District 7', 'Board Member (District 7)', 'b365f207-73b4-4318-aee8-8911762a5909'::uuid, '2266da44-016e-4098-870e-73a531a66fb2'::uuid, 'DENNIS J. MCNAMARA', 4820, 2, 'lost'),
  -- Pomona Unified School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 1404 vs bound 1248
  ('Pomona Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '0d0f2412-9cb8-499a-ba51-f37b9547fc46'::uuid, '2dcc32fa-251d-4a73-afe9-84f72ee73a82'::uuid, 'LISA C. NASHUA', 3810, 1, 'won'),
  ('Pomona Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '0d0f2412-9cb8-499a-ba51-f37b9547fc46'::uuid, 'dec7ef91-3f69-4988-a3e6-670b3d030502'::uuid, 'CHRISTINE RAQUEL CRUZ-ARVAYO', 2406, 2, 'lost'),
  ('Pomona Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '0d0f2412-9cb8-499a-ba51-f37b9547fc46'::uuid, '93caa4e8-25b6-4de2-8428-0a4c43194e47'::uuid, 'JOHN MENDOZA', 2088, 3, 'lost'),
  -- Pomona Unified School Board - Trustee Area 4 — Board Member (Trustee Area 4), 1 seat(s); margin 4190 vs bound 1059
  ('Pomona Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', 'e1af4001-85e0-4dca-bc03-5e6ca356fb4b'::uuid, 'b73d1828-6f67-41f6-abec-e15e6855937a'::uuid, 'ROBERTA PERLMAN', 5733, 1, 'won'),
  ('Pomona Unified School Board - Trustee Area 4', 'Board Member (Trustee Area 4)', 'e1af4001-85e0-4dca-bc03-5e6ca356fb4b'::uuid, '24a89c4d-39fa-48d8-ae28-05317f57e574'::uuid, 'PAWN KONGKOSONKICHKAN', 1543, 2, 'lost'),
  -- Rowland Unified School Board - Trustee Area 1 — Board Member (Trustee Area 1), 1 seat(s); margin 3097 vs bound 807
  ('Rowland Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '0e3b54cc-2ad4-49ef-9289-047f78ab153e'::uuid, '41cd6fae-70bd-4fbd-a2ca-640d4598a095'::uuid, 'AGNES P. GONZALEZ', 3993, 1, 'won'),
  ('Rowland Unified School Board - Trustee Area 1', 'Board Member (Trustee Area 1)', '0e3b54cc-2ad4-49ef-9289-047f78ab153e'::uuid, '57418d56-c682-4ac0-b721-de68abad857b'::uuid, 'OBIE OBIACORO', 896, 2, 'lost'),
  -- Santa Monica Community College Board — Board Member, 4 seat(s); margin 6121 vs bound 6096
  ('Santa Monica Community College Board', 'Board Member', '64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid, '58da4b18-a601-4ac7-a91c-8653d7242838'::uuid, 'SION ROY', 25361, 1, 'won'),
  ('Santa Monica Community College Board', 'Board Member', '64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid, 'a304f248-df3b-414c-ae72-6bd931a444e0'::uuid, 'TOM PETERS', 23747, 2, 'won'),
  ('Santa Monica Community College Board', 'Board Member', '64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid, '2b1d86ee-6208-471a-be0d-29e43ce2398f'::uuid, 'LUIS BARRERA CASTANON', 22651, 3, 'won'),
  ('Santa Monica Community College Board', 'Board Member', '64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid, '0bc78319-8d9a-4d80-b1ee-a6488e67a11c'::uuid, 'KERA BLADES-SNELL', 20363, 4, 'won'),
  ('Santa Monica Community College Board', 'Board Member', '64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid, '684c24e4-3ee0-42bc-bba5-b12e33885310'::uuid, 'OSCAR DE LA TORRE', 14242, 5, 'lost'),
  -- Santa Monica-Malibu Unified Board — Board Member, 4 seat(s); margin 10604 vs bound 6102
  ('Santa Monica-Malibu Unified Board', 'Board Member', '0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid, '4509b08d-b78b-490f-9904-e925375dfb53'::uuid, 'ALICIA MIGNANO', 25647, 1, 'won'),
  ('Santa Monica-Malibu Unified Board', 'Board Member', '0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid, '156103f8-ac8a-4962-88e6-6855f7fcdece'::uuid, 'ROBBIE STAENBERG', 23692, 2, 'won'),
  ('Santa Monica-Malibu Unified Board', 'Board Member', '0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid, '25bc5bb1-0385-429d-beac-ab05199b7944'::uuid, 'LAURIE LIEBERMAN', 22707, 3, 'won'),
  ('Santa Monica-Malibu Unified Board', 'Board Member', '0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid, '2b9537d4-6779-4acb-8c48-3fec8baf0d25'::uuid, 'STACY ROUSE', 22050, 4, 'won'),
  ('Santa Monica-Malibu Unified Board', 'Board Member', '0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid, 'a90a24f2-57fa-448b-99d0-15fac69e24a3'::uuid, 'HARRY LESHNER', 11446, 5, 'lost'),
  -- Saugus Union School Board - Trustee Area 2 — Board Member (Trustee Area 2), 1 seat(s); margin 2445 vs bound 1461
  ('Saugus Union School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '16d3f5db-00e7-49ce-a2a9-7b8e1c1862ea'::uuid, '69995d9d-7a0d-4f5d-8c93-2102ab175b53'::uuid, 'ANNA GRIESE', 6110, 1, 'won'),
  ('Saugus Union School Board - Trustee Area 2', 'Board Member (Trustee Area 2)', '16d3f5db-00e7-49ce-a2a9-7b8e1c1862ea'::uuid, 'ffe946d0-5d19-4f80-aa3c-47c901a93dc5'::uuid, 'ALISA GENTRY', 3665, 2, 'lost'),
  -- South Whittier School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 210 vs bound 192
  ('South Whittier School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '1ee10945-9593-4887-99e0-7b51bd3bb1ee'::uuid, 'cffee53a-865c-44bd-bf52-9ed630f95ad7'::uuid, 'ADRIANA FRANCO', 712, 1, 'won'),
  ('South Whittier School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', '1ee10945-9593-4887-99e0-7b51bd3bb1ee'::uuid, 'efe84622-cce3-4544-9a33-db11fd8e297f'::uuid, 'SYLVIA V. MACIAS', 502, 2, 'lost'),
  -- Torrance Unified School Board - Trustee Area D — Board Member (Trustee Area D), 1 seat(s); margin 2046 vs bound 1623
  ('Torrance Unified School Board - Trustee Area D', 'Board Member (Trustee Area D)', '84eb2f54-8d89-4ffb-b0f3-8b7497ec18e9'::uuid, 'a9312822-7994-4069-be7f-be4b22f6e254'::uuid, 'JENNIFER MAK', 6330, 1, 'won'),
  ('Torrance Unified School Board - Trustee Area D', 'Board Member (Trustee Area D)', '84eb2f54-8d89-4ffb-b0f3-8b7497ec18e9'::uuid, 'c762669c-fb4c-4312-8ad2-81a4e5069e84'::uuid, 'RYAN RAUZON', 4284, 2, 'lost'),
  -- Whittier City School Board - Trustee Area 3 — Board Member (Trustee Area 3), 1 seat(s); margin 658 vs bound 630
  ('Whittier City School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', 'cc6a7590-2fed-4060-ae9b-bb91a33c73b5'::uuid, 'a9bda01a-7781-4146-9aa3-cf0f74acf072'::uuid, 'NORMA NATALIE RODARTE', 2403, 1, 'won'),
  ('Whittier City School Board - Trustee Area 3', 'Board Member (Trustee Area 3)', 'cc6a7590-2fed-4060-ae9b-bb91a33c73b5'::uuid, '0769ac3d-aa43-47a6-b224-19ce7e8768e1'::uuid, 'RICHARD (RICK) HEVER', 1745, 2, 'lost'),
  -- Whittier Union High School Board - Trustee Area 5 — Board Member (Trustee Area 5), 1 seat(s); margin 4990 vs bound 1554
  ('Whittier Union High School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'e78098ee-a30e-40cf-8a7c-0001b075dfd0'::uuid, '7be8cabe-cc12-48c5-8d25-b8a36d218a2c'::uuid, 'ARMANDO URTEAGA', 7513, 1, 'won'),
  ('Whittier Union High School Board - Trustee Area 5', 'Board Member (Trustee Area 5)', 'e78098ee-a30e-40cf-8a7c-0001b075dfd0'::uuid, '722933b7-b517-4573-a4db-5bb5e2184e56'::uuid, 'DESIREE G. QUINTERO', 2523, 2, 'lost');

-- What each contest is judged against. ballots_cast and est_outstanding come from the county;
-- bound is est_outstanding x 3, and the gate recomputes the decision from these columns rather
-- than taking the presence of a row as the answer.
CREATE TEMP TABLE bound (
  race_id         uuid PRIMARY KEY,
  ballots_cast    int NOT NULL,
  est_outstanding int NOT NULL,
  safety          int NOT NULL,
  bound           int NOT NULL
) ON COMMIT DROP;
INSERT INTO bound (race_id, ballots_cast, est_outstanding, safety, bound) VALUES
  ('270cd1c6-014b-4969-9b83-24e2911e3e33'::uuid,   6043,   261, 3,    783),   -- ABC Unified School Board - Trustee Area 2
  ('c619f14b-7b05-5efd-9a01-3c0ca9985b52'::uuid,  19827,   855, 3,   2565),   -- Antelope Valley Community College Board - Trustee Area 5
  ('16f4d35c-f0f9-48f5-8363-ab75eb1c85f2'::uuid,   4289,   185, 3,    555),   -- Azusa Unified School Board - Trustee Area 5
  ('21aff53c-3894-4475-a2b6-0695d090035f'::uuid,   6688,   289, 3,    867),   -- Bellflower Unified School Board - Trustee Area 5
  ('219875d8-4b41-434d-a118-40b6cfca3663'::uuid,   7527,   325, 3,    975),   -- Burbank Unified School Board - Trustee Area 3
  ('debec051-f18a-5bcf-bf36-b6d570d2998b'::uuid,  11550,   498, 3,   1494),   -- Compton Community College Board - Trustee Area 1
  ('eaba170e-c0df-51e7-83da-008cebcefc12'::uuid,  12598,   543, 3,   1629),   -- Compton Community College Board - Trustee Area 2
  ('7145b7cb-a854-4f0a-b09a-380b342addf6'::uuid,   5852,   253, 3,    759),   -- Covina-Valley Unified School Board - Trustee Area 4
  ('66659918-b0a8-401c-aa5d-9e654d16f3ba'::uuid,  18634,   803, 3,   2409),   -- Culver City Unified Board
  ('3eb6bdf0-2040-4b5c-a516-573d82f2e9f3'::uuid,   5763,   249, 3,    747),   -- Downey Unified School Board - Trustee Area 7
  ('38dbc753-4d65-4547-8c72-44683eef8b25'::uuid,   1574,    68, 3,    204),   -- Duarte Unified School Board - Trustee Area 5
  ('a0cbc782-fdb0-49ec-89a4-b6f35797932a'::uuid,   5866,   253, 3,    759),   -- East Whittier City School Board - Trustee Area 3
  ('08f6ae5d-714e-4d23-8bb1-8f2fd8d7130f'::uuid,   1707,    74, 3,    222),   -- Eastside Union School Board - Trustee Area 1
  ('9d890511-f75d-4149-b80a-f8b8ea6a54c2'::uuid,   1194,    52, 3,    156),   -- Eastside Union School Board - Trustee Area 5
  ('2b2c01d2-e142-598c-a4d4-6dbf855d5967'::uuid,  47956,  2066, 3,   6198),   -- El Camino Community College Board - Trustee Area 5
  ('fd556a2b-1b8f-44e6-a110-04496739170f'::uuid,   6443,   278, 3,    834),   -- El Monte Union High School Board - Trustee Area 5
  ('4c14f7d9-6ca1-49f5-aa0f-4c1ff7ec9c8a'::uuid,   5900,   255, 3,    765),   -- Hacienda La Puente Unified School Board - Trustee Area 2
  ('0ce2e6fb-4888-4fac-82cb-2937eafc7987'::uuid,   7282,   314, 3,    942),   -- Hacienda La Puente Unified School Board - Trustee Area 4
  ('9db52f31-e7c0-4167-81a8-a3a48c1405bf'::uuid,  10043,   433, 3,   1299),   -- Inglewood Unified School Board - Trustee Area 1
  ('1ad28f06-ef6a-4b04-8ea4-52dc0c1d4c81'::uuid,   9417,   406, 3,   1218),   -- Inglewood Unified School Board - Trustee Area 2
  ('1b84b757-32ba-42b4-b13b-95d54f521b8d'::uuid,   5679,   245, 3,    735),   -- Inglewood Unified School Board - Trustee Area 3
  ('30a5efc5-bd50-427d-95ba-776f95a2ce52'::uuid,    869,    38, 3,    114),   -- Keppel Union School Board - Trustee Area 1
  ('949d2490-a41f-4e47-907e-7e1af08add04'::uuid,   1130,    49, 3,    147),   -- Keppel Union School Board - Trustee Area 2
  ('143eb42d-2236-482f-bff5-62ad30869a4f'::uuid,   4716,   204, 3,    612),   -- Lancaster School Board - Trustee Area 2
  ('7e2bee9a-4311-4f46-b117-30c157eef1b7'::uuid,   2264,    98, 3,    294),   -- Lawndale Elementary School Board - Trustee Area 2
  ('294bb127-1857-4cf7-a438-7ef482018f76'::uuid,   2327,   101, 3,    303),   -- Little Lake City School Board - Trustee Area 1
  ('a763810d-48c5-40a6-bc41-355025325ddf'::uuid,   2036,    88, 3,    264),   -- Little Lake City School Board - Trustee Area 5
  ('e11e6a79-97bc-5eea-88db-4404cb79666b'::uuid, 1561128, 67248, 3, 201744),   -- Los Angeles Community College Board
  ('6dfd8569-bde8-43c3-8187-48063cb73607'::uuid,   4541,   196, 3,    588),   -- Monrovia Unified School Board - Trustee Area 5
  ('90daede6-1092-49c2-adb1-3d7cf836d1e7'::uuid,   8841,   381, 3,   1143),   -- Mountain View Elementary Board
  ('31791a9a-97f2-4498-9d0f-96f2866026bc'::uuid,   5170,   223, 3,    669),   -- Norwalk-La Mirada Unified School Board - Trustee Area 2
  ('c629a781-086e-43d2-b936-f8a4eb0dde92'::uuid,   4473,   193, 3,    579),   -- Norwalk-La Mirada Unified School Board - Trustee Area 4
  ('708e81d8-77e0-41cb-9ba3-2c034a772512'::uuid,   5542,   239, 3,    717),   -- Palmdale School Board - Trustee Area 3
  ('9ecbd31b-a8ee-4203-87de-4b19c9227003'::uuid,   3275,   142, 3,    426),   -- Paramount Unified School Board - Trustee Area 4
  ('19f2a006-7564-5615-8267-31f68b2da2ee'::uuid,  19108,   824, 3,   2472),   -- Pasadena Area Community College Board - Trustee Area 3
  ('a846e1c1-d1b0-51b7-b1c7-36de16498be1'::uuid,  23003,   991, 3,   2973),   -- Pasadena Area Community College Board - Trustee Area 5
  ('de728759-3788-4129-bdfd-1ccc6bb5ef96'::uuid,   8699,   375, 3,   1125),   -- Pasadena Unified School Board - District 1
  ('65e6909a-10d0-404d-b2c9-2a65570eeb3a'::uuid,   9921,   428, 3,   1284),   -- Pasadena Unified School Board - District 3
  ('b365f207-73b4-4318-aee8-8911762a5909'::uuid,  14356,   619, 3,   1857),   -- Pasadena Unified School Board - District 7
  ('0d0f2412-9cb8-499a-ba51-f37b9547fc46'::uuid,   9641,   416, 3,   1248),   -- Pomona Unified School Board - Trustee Area 1
  ('e1af4001-85e0-4dca-bc03-5e6ca356fb4b'::uuid,   8192,   353, 3,   1059),   -- Pomona Unified School Board - Trustee Area 4
  ('0e3b54cc-2ad4-49ef-9289-047f78ab153e'::uuid,   6226,   269, 3,    807),   -- Rowland Unified School Board - Trustee Area 1
  ('64bff0f3-370b-50c7-8e58-f2f2a2e6ef9c'::uuid,  47154,  2032, 3,   6096),   -- Santa Monica Community College Board
  ('0f0664d7-1746-4a6e-8f19-1eb2b882243b'::uuid,  47210,  2034, 3,   6102),   -- Santa Monica-Malibu Unified Board
  ('16d3f5db-00e7-49ce-a2a9-7b8e1c1862ea'::uuid,  11298,   487, 3,   1461),   -- Saugus Union School Board - Trustee Area 2
  ('1ee10945-9593-4887-99e0-7b51bd3bb1ee'::uuid,   1469,    64, 3,    192),   -- South Whittier School Board - Trustee Area 5
  ('84eb2f54-8d89-4ffb-b0f3-8b7497ec18e9'::uuid,  12547,   541, 3,   1623),   -- Torrance Unified School Board - Trustee Area D
  ('cc6a7590-2fed-4060-ae9b-bb91a33c73b5'::uuid,   4855,   210, 3,    630),   -- Whittier City School Board - Trustee Area 3
  ('e78098ee-a30e-40cf-8a7c-0001b075dfd0'::uuid,  12008,   518, 3,   1554);   -- Whittier Union High School Board - Trustee Area 5

-- ─── 2. Everything that must be true before a single row is written ───
CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  -- 🔴 unaccent is NOT installed on prod and the county prints PEÑA and LA CAÑADA with the
  --    accent. Fold it here, in the application's own terms, as CLAUDE.md requires.
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc')),
           '[^A-Z0-9]', '', 'g')
$f$;

-- 🔴 AND THE RELAXED FORM, FOR THE TWO INGLEWOOD ROWS. The county prints the middle name and
--    we do not. This drops everything between the first and last word, so "CHERYL SHAW
--    WILLIAMS" and "Cheryl Williams" agree — and a gate below proves it stays one-to-one.
CREATE OR REPLACE FUNCTION pg_temp.shortkey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT CASE WHEN array_length(regexp_split_to_array(btrim(t), '\s+'), 1) > 2
              THEN pg_temp.namekey((regexp_split_to_array(btrim(t), '\s+'))[1])
                   || pg_temp.namekey((regexp_split_to_array(btrim(t), '\s+'))[array_length(regexp_split_to_array(btrim(t), '\s+'), 1)])
              ELSE pg_temp.namekey(t) END
$f$;

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 122 THEN RAISE EXCEPTION 'expected 122 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> 49 THEN RAISE EXCEPTION 'expected 49 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM bound;
  IF n <> 49 THEN RAISE EXCEPTION 'expected 49 bounds, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called c LEFT JOIN bound b ON b.race_id = c.race_id WHERE b.race_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% measured rows belong to a race with no bound', n; END IF;

  -- a positive control: the name comparison must see a row known to exist, or every
  -- "no mismatch found" below is vacuous
  PERFORM 1 FROM essentials.race_candidates WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Soo Yoo');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist — the name gate would pass vacuously'; END IF;
  -- and the relaxed form must actually relax: these two differ ONLY by a middle name
  IF pg_temp.shortkey('CHERYL SHAW WILLIAMS') <> pg_temp.shortkey('Cheryl Williams') THEN
    RAISE EXCEPTION 'the relaxed name key does not join the two spellings it exists for';
  END IF;
  IF pg_temp.shortkey('Soo Yoo') = pg_temp.shortkey('Al Barlevy') THEN
    RAISE EXCEPTION 'the relaxed name key collapses two different people — it is too loose to use';
  END IF;

  -- 🔴 EVERY ROW IS ADDRESSED BY uuid AND THE NAME BESIDE IT IS NOT USED TO FIND IT. A swapped
  --   uuid is invisible to any check the file makes against itself, so the name written here
  --   is compared with the DATABASE ROW'S name. CC_0359 gate D.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.ballot_name || ' (rc ' || c.rc_id || ') is ' ||
           coalesce(rc.full_name, '(no such candidacy)') || ' in the database' AS msg
      FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id
     WHERE rc.id IS NULL
        OR (pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.ballot_name)
            AND pg_temp.shortkey(rc.full_name) <> pg_temp.shortkey(c.ballot_name))) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a measured name does not match the row it is written against: %', txt; END IF;

  -- 🔴 AND THE RELAXATION MUST NOT COLLAPSE TWO PEOPLE INSIDE ONE RACE. Without this, the
  --   middle-name allowance could put one candidate's votes on another's row.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c1.district || ': ' || c1.ballot_name || ' and ' || c2.ballot_name ||
           ' share a relaxed name key' AS msg
      FROM called c1 JOIN called c2
        ON c2.race_id = c1.race_id AND c2.rc_id > c1.rc_id
       AND pg_temp.shortkey(c1.ballot_name) = pg_temp.shortkey(c2.ballot_name)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'two candidates in one race share a relaxed name key: %', txt; END IF;

  -- the candidacy must belong to the race the file says it does
  SELECT string_agg(c.ballot_name || ' sits in race ' || rc.race_id || ', not ' || c.race_id, '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy is attached to the wrong race: %', txt; END IF;

  -- 🔴 THE WAVE'S DEFINITION COMES FROM THE DATABASE, NOT FROM THE FILE: every race here must
  --   be a 2026-11-03 contest for an office that hands over on 2026-12-11.
  SELECT string_agg(c.district || ' -> ' || coalesce(s.swearing_in_date::text, '(no row)') ||
                    ' / ' || coalesce(e.election_date::text, '(no election)'), '; ') INTO txt
    FROM (SELECT DISTINCT race_id, district FROM called) c
    JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.office_swearing_in s
           ON s.office_id = r.office_id AND s.election_date = e.election_date
   WHERE e.election_date <> DATE '2026-11-03'
      OR s.swearing_in_date IS DISTINCT FROM DATE '2026-12-11';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is not a 2026-11-03 contest handing over on 2026-12-11: %', txt; END IF;

  -- the number of winners must equal the seats the race carries — never 1
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || count(*) FILTER (WHERE c.outcome = 'won') ||
           ' winners for ' || r.seats || ' seat(s)' AS msg
      FROM called c JOIN essentials.races r ON r.id = c.race_id
     GROUP BY c.race_id, c.district, r.seats
    HAVING count(*) FILTER (WHERE c.outcome = 'won') <> r.seats) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race records the wrong number of winners: %', txt; END IF;

  -- 🔴 THE COUNTY'S BALLOT MUST BE FULLY MEASURED, OR A WINNER COULD BE HIDDEN. Four races
  --   hold a candidacy the county never printed, so this asks the question the other way
  --   round from CC_0377: every row the file measures must exist, and every candidacy in the
  --   race that is NOT measured must be one of those four named exceptions.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' is in this race and is not measured' AS msg
      FROM (SELECT DISTINCT race_id, district FROM called) c
      JOIN essentials.race_candidates rc ON rc.race_id = c.race_id
     WHERE NOT EXISTS (SELECT 1 FROM called x WHERE x.rc_id = rc.id)
       AND rc.full_name <> 'Tomas Ursua') z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race is only partly measured: %', txt; END IF;

  -- 🔴 AND THE FOUR NAMED EXCEPTIONS MUST STILL BE EXCEPTIONS. If one of them stops being
  --   unmeasured — because the ballot changed, or someone fixed the row — this allowance has
  --   gone stale and must be re-read rather than carried forward.
  SELECT string_agg(z.name, '; ') INTO txt FROM (
    SELECT u.name FROM unnest(ARRAY['Tomas Ursua']) AS u(name)
     WHERE NOT EXISTS (
       SELECT 1 FROM (SELECT DISTINCT race_id FROM called) c
         JOIN essentials.race_candidates rc ON rc.race_id = c.race_id
        WHERE rc.full_name = u.name AND NOT EXISTS (SELECT 1 FROM called x WHERE x.rc_id = rc.id))) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a named not-on-the-ballot exception no longer applies and must be re-read: %', txt; END IF;

  -- 🔴 NOTHING IS OVERWRITTEN.
  SELECT string_agg(rc.full_name || ' already reads result=' || coalesce(rc.result, '(null)'), '; ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL
      OR rc.result_source IS NOT NULL OR rc.result_recorded_at IS NOT NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file only writes over NULL and found a value: %', txt; END IF;

  -- ── the decision itself, recomputed from the measurements ──
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT w.district || ': ' || l.ballot_name || ' (' || l.votes || ') is recorded LOST above ' ||
           w.ballot_name || ' (' || w.votes || ') recorded WON' AS msg
      FROM called w JOIN called l ON l.race_id = w.race_id
     WHERE w.outcome = 'won' AND l.outcome = 'lost' AND l.votes >= w.votes) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a loser out-polls a winner: %', txt; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT z2.district || ': margin ' || z2.margin || ' does not clear its bound of ' || z2.bound ||
           ' (' || z2.est_outstanding || ' estimated outstanding x' || z2.safety || ')' AS msg
      FROM (SELECT c.district, c.race_id,
                   min(c.votes) FILTER (WHERE c.outcome = 'won')
                     - max(c.votes) FILTER (WHERE c.outcome = 'lost') AS margin,
                   b.bound, b.est_outstanding, b.safety
              FROM called c JOIN bound b ON b.race_id = c.race_id
             GROUP BY c.district, c.race_id, b.bound, b.est_outstanding, b.safety) z2
     WHERE z2.margin IS NULL OR z2.margin <= z2.bound) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a recorded contest is not decisive against its own bound: %', txt; END IF;

  SELECT string_agg(b.race_id || ': bound ' || b.bound || ' <> ' || b.est_outstanding || ' x ' || b.safety, '; ') INTO txt
    FROM bound b WHERE b.bound <> b.est_outstanding * b.safety OR b.safety < 3;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a bound does not follow from its own inputs: %', txt; END IF;

  -- 🔴 AN INDEPENDENT FACT, BOTH DIRECTIONS, ON EVERY SINGLE-SEAT OFFICE — the view, not the
  --   file's own table. CC_0358 shipped the self-comparing version and a tamper walked past it.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' is flagged incumbent but the seat is held by ' ||
           coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND rc.is_incumbent AND och.politician_id IS DISTINCT FROM rc.politician_id
    UNION
    SELECT c.district || ': the seat is held by ' || p.full_name ||
           ', who is on this ballot and is NOT flagged incumbent'
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND och.politician_id = rc.politician_id AND NOT rc.is_incumbent) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent flag disagrees with who holds the seat: %', txt; END IF;

  RAISE NOTICE 'CC_0378 pre-checks passed: 122 candidacies, 49 races, all NULL, all decisive against their bounds';
END $$;

-- ─── 3. The write ───
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Los Angeles County RR/CC official results for the 2026-11-03 General Election '
         || '(results.lavote.gov, election 4348; ElectionResults/GetElectionData joined to '
         || 'ElectionResults/GetCounterData and re-read against results.lavote.gov/text-results/4348), '
         || 'count of 2026-11-07 16:38 PT, retrieved 2026-11-08: ' || c.ballot_name || ' '
         || c.votes || ' votes, rank ' || c.rank || '. The county publishes no winner flag; '
         || 'recorded as called by CC_0378 because the margin exceeds three times this contest''s '
         || 'proportional share of the 131,000 ballots the RR/CC reports still outstanding.',
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result_source LIKE '%CC_0378%';
  IF n <> 122 THEN RAISE EXCEPTION 'this file wrote % of its 122 rows', n; END IF;

  SELECT count(*) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result = 'lost')
    INTO n, total FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id;
  IF n <> 59 OR total <> 63 THEN RAISE EXCEPTION 'expected 59 won and 63 lost, wrote % and %', n, total; END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result <> c.outcome OR rc.result_certainty <> 'called' OR rc.result_recorded_at IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% rows did not take the outcome this file measured', n; END IF;

  -- 🔴 THE 148 RACES THIS FILE HOLDS BACK MUST BE UNTOUCHED — the 96 whose election was
  --   cancelled above all, because a result on one of those would assert an election that
  --   never happened.
  SELECT string_agg(d.label || ': ' || rc.full_name || ' = ' || rc.result, '; ') INTO txt
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-11'
     AND r.id NOT IN (SELECT race_id FROM bound)
     AND (rc.result IS NOT NULL OR rc.result_certainty IS NOT NULL OR rc.result_source IS NOT NULL);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race this file holds back has acquired a result: %', txt; END IF;

  -- the wave now stands at exactly 49 of 197 decided
  SELECT count(DISTINCT r.id) FILTER (WHERE rc.result = 'won'), count(*) FILTER (WHERE rc.result IS NULL)
    INTO n, total
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-11';
  IF n <> 49 THEN RAISE EXCEPTION 'the 2026-12-11 wave shows % races with a winner, expected 49', n; END IF;
  IF total <> 270 THEN RAISE EXCEPTION 'the wave shows % candidacies still unrecorded, expected 270', total; END IF;

  -- no race in the wave may hold a loser and no winner
  SELECT string_agg(z.d, '; ') INTO txt FROM (
    SELECT d.label AS d
      FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.office_swearing_in s ON s.office_id = r.office_id AND s.election_date = e.election_date
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03' AND s.swearing_in_date = DATE '2026-12-11'
     GROUP BY d.label
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won') = 0) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race holds a loser and no winner: %', txt; END IF;

  -- 🔴 THE INCUMBENT FLAG IS NOT THIS FILE'S TO MOVE, and a count would never see it move.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.district || ': ' || rc.full_name || ' flagged incumbent, seat held by ' ||
           coalesce(p.full_name, '(nobody)') AS msg
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND rc.is_incumbent AND och.politician_id IS DISTINCT FROM rc.politician_id
    UNION
    SELECT c.district || ': seat held by ' || p.full_name || ', on this ballot, not flagged incumbent'
      FROM called c
      JOIN essentials.race_candidates rc ON rc.id = c.rc_id
      JOIN essentials.races r ON r.id = c.race_id
      JOIN essentials.office_current_holder och ON och.office_id = r.office_id
      JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE r.seats = 1 AND och.politician_id = rc.politician_id AND NOT rc.is_incumbent) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the incumbent flag moved under this file: %', txt; END IF;

  -- 🔴 NOBODY IS SEATED HERE. These winners take office on 2026-12-11, not a day earlier.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN
    RAISE EXCEPTION 'the unflagged offices_missing_terms baseline reads %, not 238 (total %, flagged %)', unflagged, total, flagged;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms ot
    JOIN essentials.races r ON r.office_id = ot.office_id
   WHERE r.id IN (SELECT race_id FROM bound) AND ot.term_start >= DATE '2026-11-04';
  IF n <> 0 THEN RAISE EXCEPTION '% term row(s) start after the election on an office this file touched — nothing here seats anyone', n; END IF;

  RAISE NOTICE 'CC_0378 post-verify passed: 49 of the 197 races decided (59 won / 63 lost, all called), 270 candidacies still open (96 races cancelled), baseline unflagged 238 (total %, flagged %)', total, flagged;
END $$;

COMMIT;

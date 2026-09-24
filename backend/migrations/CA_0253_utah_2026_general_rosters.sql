-- CA_0253_utah_2026_general_rosters.sql
--
-- Slot CA_0253 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- ✅ APPLIED to prod 2026-09-24 (approval Chris Andrews): INSERT 11 / 67 / 123, UPDATE 1 / 1, both gates green.
--
-- Make Utah's 2026-11-03 GENERAL-election rosters match the certified lists, for every office our
-- 2026-06-23 Utah primary covers: Utah State House (HD21-58, HD60-65), Utah State Senate (SD9, 11, 12,
-- 13, 14, 18, 19, 21, 23), the State Board of Education (5, 7, 8, 11, 14), and county offices in Salt
-- Lake, Utah and Davis counties. CA_0240 (PR #734) recorded who won each primary row; this puts those
-- nominees, plus the Forward, Constitution, Libertarian, Independent American and unaffiliated
-- candidates who never ran in a primary, on the November race. Same shape as CA_0233 (PR #728).
--
--   76 in-scope races · 149 certified candidacies · 0 names off the certified lists
--
-- ===========================================================================================
-- 1. SIXTY-SEVEN NEW RACES on "2026 Utah General" (1f4a8e7e-cf91-438a-8b1d-b2c944b97aea)
-- ===========================================================================================
--   Utah had a general race for only 9 of the 76 offices (HD23, 28, 29, 38, 53; SD9, 11, 13, 21).
--   1296 shape: position_name = the primary race's position_name, primary_party '', seats 1, office_id =
--   the seat that is up (the same office_id as the primary race), description 'CA_0253 (2026-09-24): ...'.
--   Davis County's four primary races carry no office_id; their seats are mapped by hand:
--     Clerk c1730f20 (Brian McKenzie) · Sheriff 5edd69b1 (Kelly V. Sparks, not running) ·
--     Commission Seat A 3dd8c09d (Bob J Stevenson, not running — Standard-Examiner / Davis Journal) ·
--     Commission Seat B 1859ca26 (Lorene Kamalu, lost the primary to Susan Lee).
--   "UT 2026 Statewide General" (0bbd9839-...) holds the U.S. House races — Chris Cantrell's Phase 167.
--   It is not touched; the pre-flight refuses if it holds any in-scope position.
--
-- ===========================================================================================
-- 2. CANDIDACIES
-- ===========================================================================================
--   123 new race_candidates rows on the 67 new races: the 112 CA_0240 'won' nominees (their existing
--   politician_id) and 11 new people. The 9 existing races already hold all 26 of their certified
--   candidates (seeded from Ballotpedia); nothing is added to them.
--   is_incumbent on each new row = that person currently holds the race's office (office_current_holder),
--   checked in the pre-flight in both directions. It differs from the primary row's flag once:
--     Mike Smith, Utah County Sheriff — holds the seat; the primary row said false.
--
-- ===========================================================================================
-- 3. THREE CORRECTIONS TO EXISTING ROWS
-- ===========================================================================================
--   a. SD11 general: MacKenzie Miller candidate_status 'active' -> 'withdrawn'. The LG filings list says
--      "Withdrew" (CA_0240 already recorded it on her primary row); she is not on the certified list. Only
--      the status changes (same as Roth's general row in CA_0222).
--   b. SBOE 5 primary row: "Sara Reale" -> "Sarah Reale" (full_name, first_name). The certification and
--      filings list print SARAH REALE, and our politicians row already reads "Sarah Reale".
--   c. None to Jeff Gray, but read this: the Utah County Attorney primary row points at a bare "Jeff Gray"
--      row (35faf7b8, data_source sos_filing, no seat, no answers). The seat holder is "Jeffrey S. Gray"
--      (6b16270a, 8 compass answers). They are one person. The NOVEMBER row uses the seated row, so the
--      ballot shows the incumbent's profile. Merging the duplicate is follow-up work (CA_0229 shape).
--
-- ===========================================================================================
-- 4. ELEVEN NEW politicians ROWS — on a certified November ballot, and not in our data
-- ===========================================================================================
--   Bret Millburn (Davis Commission B, U) · Gregory Beglarian (SLCo Council At-Large A, C) · Casey Poe
--   (SLCo Council D1, L) · Hans V. Andersen (Utah Co Auditor, IAP) · Russ J. Rampton (Utah Co Clerk, FWD) ·
--   Jacob D. Oaks (Utah Co Commission A, IAP) · David Hinckley (Utah Co Commission B, FWD) · Blake
--   Townsend (HD36, D) · Jennifer K. Doud (HD61, C) · Julie Smith (HD63, FWD) · Alan Wessman (HD64, U).
--   BARE records, 1296 style: name, party (spelled as our existing Utah rows spell it), external_id in
--   1296's -66000xxx block (-66000160..-66000170, the next free numbers; the pre-flight refuses if any is
--   taken), is_incumbent = false stated explicitly (a candidate — CLAUDE.md), is_active = true. No
--   portrait, bio or stance research yet. Searched first by surname + first name: no row exists.
--   The other 10 people the originating note listed as missing (Snow, Buss, Colin Smith, Woodfield,
--   Nelson, Nematollahi, Bean, Garrard, Sotelo, Boyd) already exist and already sit on their race.
--
-- ===========================================================================================
-- RULES
-- ===========================================================================================
--   WRITE-INS ARE NOT ON THE ROSTER. The roster is the certified ballot: the names the state and the
--   counties certified for printing. A declared write-in (Charlie Tautuaa HD52, Nancy Lee Peterson HD57,
--   status "Write-In" on the LG list) is not certified for the ballot, is absent from every certification
--   used here, and a voter never sees the name. Adding one would also make the live count disagree with
--   the certified count, which is the gate below. They can be added later as a separate, labelled class.
--   NO RACE FOR "Salt Lake County Recorder". Rashelle Hobbs won that seat on 2024-11-05; it is next up in
--   2028. The 2026 primary race is a seeding error (CA_0240 held its row). Retiring it is separate work.
--   OUT OF SCOPE: offices with no 2026 Utah primary race in our data (e.g. HD59, SD20, Davis County
--   Attorney and Controller, Utah County school boards). They are not on either general election today.
--
-- SOURCES (each row's race_candidates.source names its document; all fetched 2026-09-24)
--   LG    Utah Lieutenant Governor, 2026 General Election Certification (signed 2026-08-28; scanned, OCR
--         reads CHRJSTOFFERSON, CHEVRJER, NATASSIA, KLRK), names taken from vote.utah.gov/2026-candidate-
--         filings (status "Election Candidate", updated 2026-09-08). The two lists agree on all 98
--         legislative and SBOE races apart from those four OCR misreads.
--   SLCO  Salt Lake County Clerk candidate list, status "Election Candidate" (the county's JSON API).
--   UTCO  Utah County Clerk, 2026 General Sample Ballots (corrected), "Certified by the Clerk of Utah
--         County". Its Candidate Records sheet is the 2024 cycle (Commission Seat C) and was not used.
--         Fred J. Allen is printed "J. ALLEN" (same race and party); our name is kept.
--   DAVIS Davis County Clerk, Certification of Candidates and Ballot Propositions for the Regular General
--         Election November 3, 2026 (signed 2026-08-31).
--
-- NOT CHANGED: elections; offices; office_terms; politicians.is_incumbent of existing rows; the 26
-- existing general rows other than Miller's status; primary_party (NULL) on the 9 existing races.
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS and every UPDATE by its pre-image. Dry run: the body
-- wrapped BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then the rollback
-- confirmed by re-reading the rows. Measured 2026-09-24: pass 1 INSERT 11 / 67 / 123, UPDATE 1 / 1, both
-- gates green; pass 2 INSERT 0 / 0 / 0, UPDATE 0 / 0, both gates green; after ROLLBACK the election holds
-- 9 races, no -66000160..-66000170 row, Miller 'active', "Sara Reale".
-- STANCE SOURCES (PR #719 trap): no bucket moves. The 35 flagged stance rows held by people on these
-- rosters (Catten 20, Plumb 5, Allen 5, Pitcher 4, Benson 1) already bucket as 'ut' and stay 'ut'; the 11
-- new people and MacKenzie Miller have no flagged rows.
-- ROLLBACK (once applied): DELETE the race_candidates rows whose source ends 'added by CA_0253
-- (2026-09-24)'; DELETE the 67 races whose description starts 'CA_0253'; DELETE the politicians with
-- external_id -66000160..-66000170 (after confirming nothing else references them); set Miller's SD11
-- general row back to 'active'; set the SBOE 5 primary row back to 'Sara Reale'.

BEGIN;

CREATE TEMP TABLE ca0253_new_race ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Davis County Clerk', 'c1730f20-1bc5-4393-8b8b-2e7c51164242'::uuid),
  ('Davis County Commission Seat A', '3dd8c09d-3e7c-4faf-a150-25ab91c55e32'::uuid),
  ('Davis County Commission Seat B', '1859ca26-8735-4f87-926c-3f2ec7512188'::uuid),
  ('Davis County Sheriff', '5edd69b1-dffd-447a-978c-9bf59f156e8e'::uuid),
  ('Salt Lake County Auditor', '5f34abc8-c191-4144-b6ea-5226eb576e19'::uuid),
  ('Salt Lake County Clerk', 'f7fb84f0-f8ca-467f-ac00-a03db836327f'::uuid),
  ('Salt Lake County Council At-Large A', '052814b3-4a26-41f0-81a2-cd82eda6de2a'::uuid),
  ('Salt Lake County Council District 1', 'd490589b-1205-4d39-8515-a73892b39232'::uuid),
  ('Salt Lake County Council District 3', '6e10fb50-0d39-4793-83cb-65bc02f4131e'::uuid),
  ('Salt Lake County Council District 5', 'fec9ad7c-7f7d-4d2c-b39f-0f4cedeba493'::uuid),
  ('Salt Lake County District Attorney', '2b6b84ad-f69a-484a-b96e-82976c94ef87'::uuid),
  ('Salt Lake County Sheriff', 'd6c89923-a6f2-4eea-bf3e-f40986b4268d'::uuid),
  ('Utah County Attorney', 'daf1fa50-abdb-4996-82ac-c0a6d55f4257'::uuid),
  ('Utah County Auditor', 'bebaf899-a656-4345-a9c4-cb39b878ca36'::uuid),
  ('Utah County Clerk', 'f17e0ce8-117d-468c-acc6-46b13116e634'::uuid),
  ('Utah County Commission Seat A', 'b3a543d6-a4bd-4af8-96e7-a7ae6801f68c'::uuid),
  ('Utah County Commission Seat B', '08948631-742c-4fe2-bd02-1e0a1c3592ff'::uuid),
  ('Utah County Sheriff', '3ac71e23-02a8-4d34-a8c0-85f1110019ab'::uuid),
  ('Utah State Board of Education District 11', '4b768880-cc8d-4ce2-b325-5ef7f65be518'::uuid),
  ('Utah State Board of Education District 14', '2dcd91f8-e7bf-4561-9984-600175c1c345'::uuid),
  ('Utah State Board of Education District 5', '44e14221-418e-4630-979b-4d594df96d86'::uuid),
  ('Utah State Board of Education District 7', '59cff7f8-5a18-4d0f-9878-27505a59327a'::uuid),
  ('Utah State Board of Education District 8', 'db6c721f-50bd-4675-b0a2-414e38e21aa2'::uuid),
  ('Utah State House District 21', 'a327154e-4920-4665-96d7-aa9706ce77dd'::uuid),
  ('Utah State House District 22', '8ecbdeaf-5c48-4835-a554-65175dc198c2'::uuid),
  ('Utah State House District 24', '5ad3f13f-a4f7-4997-90bd-9d89bd79c8ea'::uuid),
  ('Utah State House District 25', '05d15fec-45fa-448e-8ebf-7e35ca01220b'::uuid),
  ('Utah State House District 26', 'be96221a-0889-4ef8-90be-ad764a3616bf'::uuid),
  ('Utah State House District 27', 'a5fd69c2-b313-46a5-89a2-4c09c651b65c'::uuid),
  ('Utah State House District 30', 'f66591fe-5ea6-4147-8053-4bcc7f9cba48'::uuid),
  ('Utah State House District 31', '56cfc94d-7299-4bed-8602-68eaa733f101'::uuid),
  ('Utah State House District 32', 'bab9ee5a-2b94-413e-b6a2-3f152638bec2'::uuid),
  ('Utah State House District 33', '9ebf9f70-7b4b-4a6d-8775-9a3f68c74f9d'::uuid),
  ('Utah State House District 34', '0ddac0df-5d9b-41b7-ada7-3ebbac2d2e2a'::uuid),
  ('Utah State House District 35', '9a1dc0d5-3926-48b3-9f91-666dae5de31c'::uuid),
  ('Utah State House District 36', '495e45d3-c229-450f-9936-2e9f2807f328'::uuid),
  ('Utah State House District 37', '212215a1-e927-402e-9ab4-0d2d69f13d74'::uuid),
  ('Utah State House District 39', '49140efc-8b9e-43b0-941e-ffa8306db21a'::uuid),
  ('Utah State House District 40', '9d5f7bad-4440-45c8-94f1-b347943970ad'::uuid),
  ('Utah State House District 41', 'feaa0c21-a072-425f-86b2-829d74acfb09'::uuid),
  ('Utah State House District 42', '7ed728b7-0daf-4b9e-85da-d887673e1751'::uuid),
  ('Utah State House District 43', 'e6404b63-e7ea-44a3-b42e-e01c3b992a62'::uuid),
  ('Utah State House District 44', '4db22cd2-96aa-4f28-a4d8-9332676a2e7b'::uuid),
  ('Utah State House District 45', 'e05f5467-3626-4ae6-9477-6528c5ff863e'::uuid),
  ('Utah State House District 46', '615c14da-3da0-4c7f-a561-083a9c6cdf15'::uuid),
  ('Utah State House District 47', 'ebf452e1-fa20-4808-8b4a-7dc5240d9d38'::uuid),
  ('Utah State House District 48', '53de52c8-807c-4e03-9c1b-28baf498674a'::uuid),
  ('Utah State House District 49', '31384f46-0f8e-4a04-94f1-a110ef8d20be'::uuid),
  ('Utah State House District 50', '35cf8e64-5b3c-4644-b1b4-f024cbe291fa'::uuid),
  ('Utah State House District 51', '28764d9b-0d52-4e87-8884-d905f0f3aee7'::uuid),
  ('Utah State House District 52', '74ee0979-3885-4d52-a79c-f206b6ba22a0'::uuid),
  ('Utah State House District 54', 'ba5ecae3-36d9-4cd7-9608-931557cd4a01'::uuid),
  ('Utah State House District 55', '42c85b76-0e9b-47ba-a39c-535a75912e6b'::uuid),
  ('Utah State House District 56', '262ebde3-eaf1-4b1c-ab40-dec0cbc15f47'::uuid),
  ('Utah State House District 57', '695cb616-a5c3-47e2-9bab-0c378a66949c'::uuid),
  ('Utah State House District 58', '0b9d70d3-127f-4f4e-9920-1c2839fcd6c6'::uuid),
  ('Utah State House District 60', 'd3a56b11-7d9a-4a8e-b282-61757b492f2b'::uuid),
  ('Utah State House District 61', 'e200d81c-4e8d-4b62-8f52-7dff688b478b'::uuid),
  ('Utah State House District 62', '5e9ac1eb-c074-4622-9ec6-ee51a1ab1c2e'::uuid),
  ('Utah State House District 63', 'b3588b43-31ae-42df-bc63-6f74db90302a'::uuid),
  ('Utah State House District 64', '2ca0f824-4517-42cb-b5b9-33daada43212'::uuid),
  ('Utah State House District 65', '959fcaa2-27d9-4cfd-9baf-d5978b005996'::uuid),
  ('Utah State Senate District 12', '2537c86a-0753-40c7-8187-6b4c4606ff7b'::uuid),
  ('Utah State Senate District 14', '66ccd3c3-915f-466e-bb97-76a4d8d4b391'::uuid),
  ('Utah State Senate District 18', 'bb9ee06d-4099-4f0a-85c5-a7962625b90f'::uuid),
  ('Utah State Senate District 19', '3533f253-93b7-4b4b-a3a1-87ac83d88bb1'::uuid),
  ('Utah State Senate District 23', '16336c50-9fa9-4ef8-b8d9-061c0b898454'::uuid)
) AS v(position_name, office_id);

CREATE TEMP TABLE ca0253_new_pol ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000160::bigint, 'Bret', 'Millburn', 'Bret Millburn', 'Unaffiliated', 'Davis County Commission Seat B', 'DAVIS'),
  (-66000161::bigint, 'Gregory', 'Beglarian', 'Gregory Beglarian', 'Constitution Party', 'Salt Lake County Council At-Large A', 'SLCO'),
  (-66000162::bigint, 'Casey', 'Poe', 'Casey Poe', 'Libertarian', 'Salt Lake County Council District 1', 'SLCO'),
  (-66000163::bigint, 'Hans', 'Andersen', 'Hans V. Andersen', 'Independent American Party', 'Utah County Auditor', 'UTCO'),
  (-66000164::bigint, 'Russ', 'Rampton', 'Russ J. Rampton', 'Utah Forward Party', 'Utah County Clerk', 'UTCO'),
  (-66000165::bigint, 'Jacob', 'Oaks', 'Jacob D. Oaks', 'Independent American Party', 'Utah County Commission Seat A', 'UTCO'),
  (-66000166::bigint, 'David', 'Hinckley', 'David Hinckley', 'Utah Forward Party', 'Utah County Commission Seat B', 'UTCO'),
  (-66000167::bigint, 'Blake', 'Townsend', 'Blake Townsend', 'Democratic', 'Utah State House District 36', 'LG'),
  (-66000168::bigint, 'Jennifer', 'Doud', 'Jennifer K. Doud', 'Constitution Party', 'Utah State House District 61', 'LG'),
  (-66000169::bigint, 'Julie', 'Smith', 'Julie Smith', 'Utah Forward Party', 'Utah State House District 63', 'LG'),
  (-66000170::bigint, 'Alan', 'Wessman', 'Alan Wessman', 'Unaffiliated', 'Utah State House District 64', 'LG')
) AS v(ext, first_name, last_name, full_name, party, position_name, src);

-- src codes: LG = Lieutenant Governor certification; SLCO / UTCO / DAVIS = the county's list (see header).
CREATE TEMP TABLE ca0253_cand ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Davis County Clerk', 'Brian McKenzie', 'Brian', 'McKenzie', '150b9f2d-bdaa-4d86-801a-44db8f182c72'::uuid, NULL::bigint, true, 'DAVIS', false),
  ('Davis County Commission Seat A', 'Kendalyn Harris', 'Kendalyn', 'Harris', 'f738781b-a677-4e8f-ae03-2e6af66a0732'::uuid, NULL::bigint, false, 'DAVIS', false),
  ('Davis County Commission Seat B', 'Bret Millburn', 'Bret', 'Millburn', NULL::uuid, -66000160::bigint, false, 'DAVIS', false),
  ('Davis County Commission Seat B', 'Susan Lee', 'Susan', 'Lee', '98a3c1ba-cb01-4f05-a513-aa03fca5b798'::uuid, NULL::bigint, false, 'DAVIS', false),
  ('Davis County Sheriff', 'Jon Atkin', 'Jon', 'Atkin', '03de8c27-4df1-419e-bab8-ea543c545609'::uuid, NULL::bigint, false, 'DAVIS', false),
  ('Salt Lake County Auditor', 'Ali Cloward', 'Ali', 'Cloward', '28fdb59e-35e8-4725-8610-04dfecc27649'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Auditor', 'Chris Harding', 'Chris', 'Harding', '5b3c303d-066c-4828-a241-a39df55dfaef'::uuid, NULL::bigint, true, 'SLCO', false),
  ('Salt Lake County Clerk', 'Lannie Chapman', 'Lannie', 'Chapman', '9b02727d-1e6a-424a-9f0f-9db5b0ecc6fa'::uuid, NULL::bigint, true, 'SLCO', false),
  ('Salt Lake County Council At-Large A', 'Gregory Beglarian', 'Gregory', 'Beglarian', NULL::uuid, -66000161::bigint, false, 'SLCO', false),
  ('Salt Lake County Council At-Large A', 'Kathleen Anderson', 'Kathleen', 'Anderson', '09d9691d-0352-45c0-9efd-31c38b69c302'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Council At-Large A', 'Zach Robinson', 'Zach', 'Robinson', '50733e01-ff9b-4f37-8095-f68ab05f2305'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Council District 1', 'Casey Poe', 'Casey', 'Poe', NULL::uuid, -66000162::bigint, false, 'SLCO', false),
  ('Salt Lake County Council District 1', 'Jiro Johnson', 'Jiro', 'Johnson', 'd1bd8ce5-1323-4476-8663-be3295998e36'::uuid, NULL::bigint, true, 'SLCO', false),
  ('Salt Lake County Council District 3', 'Luke Maynes', 'Luke', 'Maynes', '00edf7b6-b612-4296-a14e-6b1d0d7de772'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Council District 3', 'Mike Bird', 'Mike', 'Bird', '5d9c347b-d310-4586-b236-68b95c5e50cb'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Council District 5', 'Traci Crockett', 'Traci', 'Crockett', '0919efe0-5abc-401f-88cb-7a3e13788ff4'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Council District 5', 'Sara Cimmers', 'Sara', 'Cimmers', '80847230-82ac-4113-a8ad-b25498cd1ec3'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County District Attorney', 'Sim Gill', 'Sim', 'Gill', '77256186-0ce8-4069-9d06-1d2fd5b4b622'::uuid, NULL::bigint, true, 'SLCO', false),
  ('Salt Lake County District Attorney', 'Kent Davis', 'Kent', 'Davis', '974cd2b6-8dd2-4794-aded-88c6ebc38a30'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Sheriff', 'Shane Manwaring', 'Shane', 'Manwaring', '580a3101-fd21-4712-9f9f-84eafdd3c079'::uuid, NULL::bigint, false, 'SLCO', false),
  ('Salt Lake County Sheriff', 'Rosie Rivera', 'Rosie', 'Rivera', '8c34f0b8-4201-49b4-95a2-d043e99a3eef'::uuid, NULL::bigint, true, 'SLCO', false),
  ('Utah County Attorney', 'Jeffrey S. Gray', 'Jeffrey', 'Gray', '6b16270a-c6c7-46be-9b9c-7def323dc4ef'::uuid, NULL::bigint, true, 'UTCO', false),
  ('Utah County Auditor', 'Gina Tanner', 'Gina', 'Tanner', '18cd2d26-4b62-496c-9ef5-3a1dd54f8f1a'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Auditor', 'Hans V. Andersen', 'Hans', 'Andersen', NULL::uuid, -66000163::bigint, false, 'UTCO', false),
  ('Utah County Clerk', 'Corey Astill', 'Corey', 'Astill', 'fb9afbd5-a74b-41c7-b943-a24b71a5a9d2'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Clerk', 'Russ J. Rampton', 'Russ', 'Rampton', NULL::uuid, -66000164::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat A', 'Jeanne Marie Bowen', 'Jeanne Marie', 'Bowen', '4e3fe9a1-d2d8-426c-a1bb-5a192a420992'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat A', 'Michelle Kaufusi', 'Michelle', 'Kaufusi', 'abf34eb9-8b81-4c9f-8db6-25ba036419c9'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat A', 'Jacob D. Oaks', 'Jacob', 'Oaks', NULL::uuid, -66000165::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat B', 'Fred J. Allen', 'Fred', 'Allen', 'fc23f648-2ec4-4c6c-a9f5-0722b809e6b1'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat B', 'David Spencer', 'David', 'Spencer', 'f43a2014-6b3c-4497-b5bf-c6d04d27ed07'::uuid, NULL::bigint, false, 'UTCO', false),
  ('Utah County Commission Seat B', 'David Hinckley', 'David', 'Hinckley', NULL::uuid, -66000166::bigint, false, 'UTCO', false),
  ('Utah County Sheriff', 'Mike Smith', 'Mike', 'Smith', '59ae2b63-0e76-4e21-93ce-e16994f64581'::uuid, NULL::bigint, true, 'UTCO', false),
  ('Utah State Board of Education District 11', 'Tracy Nuttall', 'Tracy', 'Nuttall', 'c8d40172-2920-4674-a178-5409543b98e3'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Board of Education District 11', 'Lacey Peterson', 'Lacey', 'Peterson', 'e1d4e163-d55f-447f-be1d-7dde05c657ce'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Board of Education District 14', 'Linda Hanks', 'Linda', 'Hanks', '0cba4cd5-9726-42fa-9026-71deaec14e8a'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Board of Education District 5', 'Sarah Reale', 'Sarah', 'Reale', 'e2c26f7a-e7ff-4e77-bc22-0e66cd1e71ce'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Board of Education District 7', 'James Martin', 'James', 'Martin', '0742b1f1-c040-4e36-8e49-168af16b1d6b'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Board of Education District 7', 'Erin Longacre', 'Erin', 'Longacre', '2a7df339-5e2a-42aa-8a60-33af1d08cfe8'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Board of Education District 8', 'Nicole McDermott', 'Nicole', 'McDermott', '3ff96381-9fd3-42d9-b6b4-264342f9888f'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Board of Education District 8', 'Araueni Olivares', 'Araueni', 'Olivares', 'a998731c-a20f-4801-8996-0ac864a8a710'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 21', 'Stephen Otterstrom', 'Stephen', 'Otterstrom', 'e74bafed-c882-48dc-9dcc-36e8fa4adf23'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 22', 'Char Varga', 'Char', 'Varga', '22a48fff-f0a6-435a-b297-629b4342a5d3'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 22', 'Jen Dailey-Provost', 'Jen', 'Dailey-Provost', '633a3500-8458-4719-bd0e-38c161321707'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 24', 'Grant Amjad Miller', 'Grant Amjad', 'Miller', '1e779b2b-8847-4542-9a73-1192c60eca40'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 24', 'Braeden J. Oswald', 'Braeden', 'Oswald', 'd865cd5c-5d1e-422e-83e7-74923e293505'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 25', 'Richard T. Nowak', 'Richard', 'Nowak', '69cff770-42c6-49b4-993f-913c20a9ced6'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 25', 'Angela Romero', 'Angela', 'Romero', '00af7081-b2f4-4b2d-add0-dd1c3d3b4787'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 26', 'Michael E. Finch', 'Michael', 'Finch', '5abcee60-3ffa-49f1-a065-7e29001bbf90'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 26', 'Matt MacPherson', 'Matt', 'MacPherson', 'ad15088a-caab-4234-ad12-a1aa0d148d5b'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 27', 'Anthony Loubet', 'Anthony', 'Loubet', 'c515ad70-3ced-4c95-b697-f3260bd80a71'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 27', 'Liz Oates', 'Liz', 'Oates', '621ee97f-cb3f-4933-8b0f-d6e28c04ce46'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 30', 'Dave Parke', 'Dave', 'Parke', '487fee81-0a6c-4269-8bcf-e046d93b25df'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 30', 'Jake Fitisemanu', 'Jake', 'Fitisemanu', '3ea1438a-880b-476f-972d-4cd8d020e376'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 31', 'Melody Jones', 'Melody', 'Jones', 'e17f8c92-0fdd-46d9-818e-7e0549783832'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 31', 'Verona Mauga', 'Verona', 'Mauga', 'fff09fb0-57ee-479f-bea1-6548cf622167'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 32', 'Aileen Hampton', 'Aileen', 'Hampton', '942e7f99-e802-44ec-86b6-7dde5790e7c8'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 32', 'Sahara Hayes', 'Sahara', 'Hayes', '01e8e34b-dc2e-47af-8c1b-e57e7c51da5e'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 33', 'Doug Owens', 'Doug', 'Owens', '38aec107-ca28-454a-a7f0-d9225fcd4d8b'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 33', 'Anna Reeves', 'Anna', 'Reeves', '6e220dd7-a208-4cde-a68d-ccd8ebfc10d2'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 34', 'Julie Jackson', 'Julie', 'Jackson', 'e79822a0-d968-4e00-b107-de54732134bf'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 35', 'Monique I. Ketcham', 'Monique', 'Ketcham', '9c132830-5d2c-45b3-8ca4-dcbc9c157965'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 35', 'Rosalba Dominguez', 'Rosalba', 'Dominguez', '85eb733f-615f-4709-99ca-d524e793588d'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 36', 'James A. Dunnigan', 'James', 'Dunnigan', '2627f1da-6783-4e12-911d-f54dfd2a7f42'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 36', 'Blake Townsend', 'Blake', 'Townsend', NULL::uuid, -66000167::bigint, false, 'LG', false),
  ('Utah State House District 37', 'Ashlee Matthews', 'Ashlee', 'Matthews', '78af9e6a-adcb-4003-b719-32fe035feae8'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 37', 'Casey Saxton', 'Casey', 'Saxton', 'aa175632-02f2-4981-a0c2-afd5622de396'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 39', 'Drew Howells', 'Drew', 'Howells', '60be4673-e2a5-4bef-9d8b-26f30773819e'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 39', 'Ken Ivory', 'Ken', 'Ivory', 'f3c4cdf1-724e-43d6-ad59-70573badae75'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 40', 'Andrew Stoddard', 'Andrew', 'Stoddard', '4956e47c-d051-4adf-a558-5f29c9f7e854'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 41', 'Darren Croft', 'Darren', 'Croft', '22f0df45-ddc3-4959-8030-674f7b1f9730'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 41', 'John Arthur', 'John', 'Arthur', '4dede46d-7aae-44e0-bc1b-b7246279fc75'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 42', 'Clint Okerlund', 'Clint', 'Okerlund', '74da1006-5f57-476d-91b9-4a158ebc7c6d'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 42', 'Iva Williams', 'Iva', 'Williams', '843b57b4-f65c-4350-8ad7-784faa04ab95'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 43', 'Steve Eliason', 'Steve', 'Eliason', '3e569f2a-041d-43e2-a96f-e007eb7d6656'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 43', 'Ofa Matagi', 'Ofa', 'Matagi', '61dee500-e43b-48be-8cc4-d69f5aa8b929'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 44', 'Jess Birtcher', 'Jess', 'Birtcher', '3a407ec7-e4e8-442a-b533-7a072086fbc9'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 44', 'Jordan Teuscher', 'Jordan', 'Teuscher', 'a3764449-b9d2-48f2-ac15-076a47ef11fb'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 45', 'Tracy Miller', 'Tracy', 'Miller', 'd2d9d65d-138a-4b40-a4de-88642f35ec15'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 45', 'Rod Moser', 'Rod', 'Moser', 'f5b7b29d-141e-408e-94ad-530791ad0c71'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 46', 'Braxten Rutherford', 'Braxten', 'Rutherford', '71e0a3fc-34f6-4ad9-a87a-40f0a2b75858'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 46', 'Cal Roberts', 'Cal', 'Roberts', '9a925e6b-6a07-4cba-abc0-3425b45e9331'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 47', 'Mark A. Strong', 'Mark', 'Strong', '6b4748cf-5c32-4a6e-9476-80e2ed7d8d7d'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 48', 'Benyde Walker', 'Benyde', 'Walker', 'c91e43e9-06f0-4f4a-9846-d891a758a828'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 48', 'Jake Hunsaker', 'Jake', 'Hunsaker', 'ba76e9b6-3681-4d8e-8c74-9099555699e3'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 49', 'Lillian Bowles', 'Lillian', 'Bowles', '596bb59c-d9ea-4fc2-95eb-6ea51c7a4ff4'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 49', 'Candice B. Pierucci', 'Candice', 'Pierucci', '99198363-2ac9-4b56-9d80-7abfe7b2a01a'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 50', 'Stephanie Gricius', 'Stephanie', 'Gricius', '7ebd1d5d-f51f-49fd-98df-3e5223e49208'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 50', 'Kristin Meyer', 'Kristin', 'Meyer', '3636bc00-6b02-4a87-914b-62333979660b'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 51', 'Leah Hansen', 'Leah', 'Hansen', 'ef01b369-5092-4548-bfc3-e3fd611b1039'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 51', 'Brett Nielsen', 'Brett', 'Nielsen', '3d8e57c0-0d6d-4383-8262-9f53c57608f5'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 52', 'Nicole Melling', 'Nicole', 'Melling', '39674cb9-c52b-4bf6-be3b-ac8a73fd3ad1'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 52', 'Cory Maloy', 'Cory', 'Maloy', 'a42272fb-f41b-4a64-86d5-a0a0eeec5b82'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 54', 'Kristina Robinson', 'Kristina', 'Robinson', '867fda53-8e37-4a0b-8d2b-a709c4b070c8'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 54', 'Kristen S. Chevrier', 'Kristen', 'Chevrier', '596c0496-20ba-41f6-8b9a-f511bc7c2de8'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 55', 'Travis Hysell', 'Travis', 'Hysell', 'a4dfdd94-6829-429f-9a5a-abca52ee4d68'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 55', 'Jon Hawkins', 'Jon', 'Hawkins', '8928852d-0688-431b-aad2-bf55275583fb'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 56', 'Natassja Grossman', 'Natassja', 'Grossman', '5194fa5e-0f07-43ea-b3cc-ea159fb92732'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 56', 'Val L. Peterson', 'Val', 'Peterson', '61816aa4-4de0-4e1a-a249-cea5e2a8d169'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 57', 'Nelson T. Abbott', 'Nelson', 'Abbott', 'ec7d4cce-d016-48ba-82d1-4f246d44542e'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 58', 'David Shallenberger', 'David', 'Shallenberger', 'f214eee8-0e54-450a-8a2b-1ca8ce8e9182'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 58', 'Karli Black', 'Karli', 'Black', '3b34a8a9-eae2-4559-99d6-32055b7cbf38'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 60', 'Grant Pace', 'Grant', 'Pace', 'e5c70a0f-1b0a-4ea2-b159-a4d421223929'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 61', 'Lisa Shepherd', 'Lisa', 'Shepherd', '63901c61-d007-4cbd-b3bc-c50a4eaa73f3'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 61', 'Alan Jimenez', 'Alan', 'Jimenez', 'e78c733d-2d46-4e3c-b729-cc3cd9121773'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 61', 'Jennifer K. Doud', 'Jennifer', 'Doud', NULL::uuid, -66000168::bigint, false, 'LG', false),
  ('Utah State House District 62', 'Norman K. Thurston', 'Norman', 'Thurston', '0b36a14c-3d2d-4e05-88ab-47a738d1283b'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 62', 'David Chappell', 'David', 'Chappell', '5b0d6684-3cb7-4c68-80d3-e861006ce9f0'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 63', 'Mark Youngquist', 'Mark', 'Youngquist', '87270bae-4651-4e2f-b2c1-cbed60ccac69'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State House District 63', 'Stephen L. Whyte', 'Stephen', 'Whyte', 'bca7a17c-82d9-4cbc-8858-7763d4c5fe87'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 63', 'Julie Smith', 'Julie', 'Smith', NULL::uuid, -66000169::bigint, false, 'LG', false),
  ('Utah State House District 64', 'Alan Wessman', 'Alan', 'Wessman', NULL::uuid, -66000170::bigint, false, 'LG', false),
  ('Utah State House District 64', 'Jackie Larson', 'Jackie', 'Larson', 'b86c57b4-9835-4fa3-8924-c52e52f19a66'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 65', 'Doug Welton', 'Doug', 'Welton', '2477ac16-810e-4d5c-a71e-a4f3b8f29d1e'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Senate District 12', 'Deidre Tyler', 'Deidre', 'Tyler', '7fd3b34e-c7fb-4ed7-82df-aa92ca4f8916'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Senate District 12', 'Karen Kwan', 'Karen', 'Kwan', '93376853-c225-430c-bf89-dfee26c6c964'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Senate District 14', 'Stephanie Pitcher', 'Stephanie', 'Pitcher', '4f896b69-d922-4838-b54d-51a00a452e08'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Senate District 18', 'A. Dane Anderson', 'A. Dane', 'Anderson', 'b39f5819-f736-43f3-8cad-c866c7aea7f5'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Senate District 18', 'Doug Fiefia', 'Doug', 'Fiefia', '01eac4cc-d6f2-4b33-ab5f-c3d4d2b93dc0'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Senate District 19', 'Kirk Cullimore', 'Kirk', 'Cullimore', '29a72e61-eb0b-44da-b535-974993a59838'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State Senate District 19', 'Shana Anderson', 'Shana', 'Anderson', '8f3acca8-456d-495a-b3f5-d2dd1669213d'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Senate District 23', 'Tucker Smith', 'Tucker', 'Smith', 'a4aaaa16-4512-4098-bc33-aed05158a651'::uuid, NULL::bigint, false, 'LG', false),
  ('Utah State Senate District 23', 'Keith Grover', 'Keith', 'Grover', 'dd75cf82-f0b2-4820-9356-28ccf0ee58f9'::uuid, NULL::bigint, true, 'LG', false),
  ('Utah State House District 23', 'Cabot Nelson', 'Cabot', 'Nelson', 'f46d639e-7c48-44b8-b6e3-29f5cbc7c2e9'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 23', 'Franklin D. Robinson', 'Franklin', 'Robinson', '831323cf-5c9b-4fad-85e4-8b87d59f444c'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 23', 'Hoang Nguyen', 'Hoang', 'Nguyen', '399b6cdd-f76b-4ef1-8cd1-4e30bce075b0'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State House District 28', 'Anita Dalrymple', 'Anita', 'Dalrymple', 'c10d6946-0b00-467d-a7e6-2cd354ff2958'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 28', 'Nicholeen Peck', 'Nicholeen', 'Peck', '4443756f-3108-4399-940e-5632c7ad3ca0'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State House District 28', 'Wales Nematollahi', 'Wales', 'Nematollahi', '4f189eea-23a6-483a-b8f0-62e86ab93717'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 29', 'Jonathan Garrard', 'Jonathan', 'Garrard', 'b30b15ba-c3a1-44ae-a6ab-eb6942a76af4'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 29', 'Sara Snow', 'Sara', 'Snow', 'c242c376-9edd-4c6c-987a-4c85dfd5723f'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 29', 'Sheldon Birch', 'Sheldon', 'Birch', 'a226ad14-7579-4da1-bf2a-dd689f7b01c6'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 29', 'Tynley Bean', 'Tynley', 'Bean', '484ab223-7e24-41be-a171-7e07100b6d2e'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 38', 'Chris McConnehey', 'Chris', 'McConnehey', '75cba240-4715-47cb-80f7-d51cd64e5650'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 38', 'Sergio Sotelo', 'Sergio', 'Sotelo', '07f8f94d-9b15-4c52-9063-2ecd9530dba5'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 53', 'John Boyd', 'John', 'Boyd', '60836cda-1dbf-4ea1-90ee-01d590cf0b70'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State House District 53', 'Kay J. Christofferson', 'Kay', 'Christofferson', '2fa5347c-fb56-443d-8f1d-c1bff270bf9e'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State House District 53', 'Kevin R. Slater', 'Kevin', 'Slater', 'de683367-7986-4550-aa95-7a1896c49d09'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 11', 'Brooks Benson', 'Brooks', 'Benson', '9a171371-be83-456e-acd5-ece936ee84ae'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 11', 'Emily Buss', 'Emily', 'Buss', '70b5e5a8-2ae4-454e-b75e-adb200b7b91d'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State Senate District 13', 'Colin Smith', 'Colin', 'Smith', 'c09917bf-4e94-45d3-a4d8-2bc1b3bde08d'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 13', 'Ryan L. Mahoney', 'Ryan', 'Mahoney', 'b79c73a9-3737-4381-bc2c-d23599095e9c'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 13', 'Silvia Catten', 'Silvia', 'Catten', '63d60b50-2395-4cde-8999-97a9166d3563'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 21', 'Brady Brammer', 'Brady', 'Brammer', '070c1c1c-ac9d-42e0-bff2-3f4467504cba'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State Senate District 21', 'Kandee Myers', 'Kandee', 'Myers', '6c75cc3b-463b-4994-9068-97386a44ad23'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 21', 'Wayne Woodfield', 'Wayne', 'Woodfield', 'e19741dc-0f7b-42a5-a762-fe34c00fb117'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 9', 'J. Lowry Snow', 'J. Lowry', 'Snow', 'c0f2ff16-6712-4f89-91a4-7a014f12bf06'::uuid, NULL::bigint, false, 'LG', true),
  ('Utah State Senate District 9', 'Jen Plumb', 'Jen', 'Plumb', '21786f7a-a6e5-4011-ac87-cecc01a10f9e'::uuid, NULL::bigint, true, 'LG', true),
  ('Utah State Senate District 9', 'Thaddeus A. Evans', 'Thaddeus', 'Evans', 'e5897d26-d1c3-42b2-81ee-37ee18dad5ff'::uuid, NULL::bigint, false, 'LG', true)
) AS v(position_name, full_name, first_name, last_name, politician_id, ext, is_incumbent, src, already_on_race);

-- Certified field size of every in-scope race (= live candidates required afterwards).
CREATE TEMP TABLE ca0253_expect ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Davis County Clerk', 1),
  ('Davis County Commission Seat A', 1),
  ('Davis County Commission Seat B', 2),
  ('Davis County Sheriff', 1),
  ('Salt Lake County Auditor', 2),
  ('Salt Lake County Clerk', 1),
  ('Salt Lake County Council At-Large A', 3),
  ('Salt Lake County Council District 1', 2),
  ('Salt Lake County Council District 3', 2),
  ('Salt Lake County Council District 5', 2),
  ('Salt Lake County District Attorney', 2),
  ('Salt Lake County Sheriff', 2),
  ('Utah County Attorney', 1),
  ('Utah County Auditor', 2),
  ('Utah County Clerk', 2),
  ('Utah County Commission Seat A', 3),
  ('Utah County Commission Seat B', 3),
  ('Utah County Sheriff', 1),
  ('Utah State Board of Education District 11', 2),
  ('Utah State Board of Education District 14', 1),
  ('Utah State Board of Education District 5', 1),
  ('Utah State Board of Education District 7', 2),
  ('Utah State Board of Education District 8', 2),
  ('Utah State House District 21', 1),
  ('Utah State House District 22', 2),
  ('Utah State House District 23', 3),
  ('Utah State House District 24', 2),
  ('Utah State House District 25', 2),
  ('Utah State House District 26', 2),
  ('Utah State House District 27', 2),
  ('Utah State House District 28', 3),
  ('Utah State House District 29', 4),
  ('Utah State House District 30', 2),
  ('Utah State House District 31', 2),
  ('Utah State House District 32', 2),
  ('Utah State House District 33', 2),
  ('Utah State House District 34', 1),
  ('Utah State House District 35', 2),
  ('Utah State House District 36', 2),
  ('Utah State House District 37', 2),
  ('Utah State House District 38', 2),
  ('Utah State House District 39', 2),
  ('Utah State House District 40', 1),
  ('Utah State House District 41', 2),
  ('Utah State House District 42', 2),
  ('Utah State House District 43', 2),
  ('Utah State House District 44', 2),
  ('Utah State House District 45', 2),
  ('Utah State House District 46', 2),
  ('Utah State House District 47', 1),
  ('Utah State House District 48', 2),
  ('Utah State House District 49', 2),
  ('Utah State House District 50', 2),
  ('Utah State House District 51', 2),
  ('Utah State House District 52', 2),
  ('Utah State House District 53', 3),
  ('Utah State House District 54', 2),
  ('Utah State House District 55', 2),
  ('Utah State House District 56', 2),
  ('Utah State House District 57', 1),
  ('Utah State House District 58', 2),
  ('Utah State House District 60', 1),
  ('Utah State House District 61', 3),
  ('Utah State House District 62', 2),
  ('Utah State House District 63', 3),
  ('Utah State House District 64', 2),
  ('Utah State House District 65', 1),
  ('Utah State Senate District 11', 2),
  ('Utah State Senate District 12', 2),
  ('Utah State Senate District 13', 3),
  ('Utah State Senate District 14', 1),
  ('Utah State Senate District 18', 2),
  ('Utah State Senate District 19', 2),
  ('Utah State Senate District 21', 3),
  ('Utah State Senate District 23', 2),
  ('Utah State Senate District 9', 3)
) AS v(position_name, live);

CREATE TEMP TABLE ca0253_src ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('LG',    'Utah Lieutenant Governor, 2026 General Election Certification (vote.utah.gov/wp-content/uploads/2026/09/2026-General-Election-Certification.pdf, signed 2026-08-28); names checked against vote.utah.gov/2026-candidate-filings (status "Election Candidate", updated 2026-09-08)'),
  ('SLCO',  'Salt Lake County Clerk candidate list (apps.saltlakecounty.gov/services/cl/cl-candidate-reporting-service/api/v1/CandidateReporting/GetCandidateJson, status "Election Candidate", fetched 2026-09-24)'),
  ('UTCO',  'Utah County Clerk, 2026 General Sample Ballots, "Certified by the Clerk of Utah County" (vote.utahcounty.gov/cms/uploads/2026_General_Sample_Ballots_Corrected_fb7973b55a.PDF, fetched 2026-09-24)'),
  ('DAVIS', 'Davis County Clerk, Certification of Candidates and Ballot Propositions for the Regular General Election November 3, 2026 (utah.gov/pmn/files/1483981.pdf, signed 2026-08-31)')
) AS v(code, text);

CREATE TEMP TABLE ca0253_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0253_new_race; IF n <> 67  THEN RAISE EXCEPTION 'PRE: % new races, expected 67', n; END IF;
  SELECT count(*) INTO n FROM ca0253_new_pol;  IF n <> 11  THEN RAISE EXCEPTION 'PRE: % new people, expected 11', n; END IF;
  SELECT count(*) INTO n FROM ca0253_cand;     IF n <> 149 THEN RAISE EXCEPTION 'PRE: % candidacies, expected 149', n; END IF;
  SELECT count(*) INTO n FROM ca0253_expect;   IF n <> 76  THEN RAISE EXCEPTION 'PRE: % races expected, expected 76', n; END IF;
  SELECT sum(live) INTO n FROM ca0253_expect;  IF n <> 149 THEN RAISE EXCEPTION 'PRE: certified fields sum to %, expected 149', n; END IF;
  -- The candidacy list and the certified counts agree race by race.
  SELECT count(*) INTO n FROM ca0253_expect x
   WHERE x.live <> (SELECT count(*) FROM ca0253_cand c WHERE c.position_name = x.position_name);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % races whose candidacy list differs from the certified count', n; END IF;

  -- The target election is the one Utah 2026-11-03 general row we expect.
  PERFORM 1 FROM essentials.elections
   WHERE id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND state = 'UT' AND election_date = '2026-11-03'
     AND election_type = 'general';
  IF NOT FOUND THEN RAISE EXCEPTION 'PRE: election 1f4a8e7e is not the UT 2026-11-03 general'; END IF;
  -- Phase 167's election holds none of these positions.
  SELECT count(*) INTO n FROM essentials.races r JOIN ca0253_expect x ON x.position_name = r.position_name
   WHERE r.election_id = '0bbd9839-e278-4fce-8231-bb7117737702';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % in-scope races sit on "UT 2026 Statewide General"', n; END IF;

  -- The 9 existing races are there; the 67 new ones are absent or were created by this file.
  SELECT count(*) INTO n FROM ca0253_expect x
    JOIN essentials.races r ON r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND r.position_name = x.position_name
   WHERE x.position_name NOT IN (SELECT position_name FROM ca0253_new_race);
  IF n <> 9 THEN RAISE EXCEPTION 'PRE: % of 9 existing Utah general races found', n; END IF;
  SELECT count(*) INTO n FROM ca0253_new_race x
    JOIN essentials.races r ON r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND r.position_name = x.position_name
   WHERE r.description IS DISTINCT FROM 'CA_0253 (2026-09-24): 2026-11-03 general-election race for this seat; field = the certified ballot';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the new races already exist, not created by CA_0253', n; END IF;

  -- Each new race's office is a real Utah seat (not a candidacy placeholder) with exactly one holder,
  -- and matches the primary race's office where that has one.
  SELECT count(*) INTO n FROM ca0253_new_race x
    JOIN essentials.offices o ON o.id = x.office_id AND o.title NOT LIKE 'Candidate for%'
   WHERE (SELECT count(*) FROM essentials.office_current_holder och WHERE och.office_id = o.id) = 1;
  IF n <> 67 THEN RAISE EXCEPTION 'PRE: only % of 67 office_ids are held seats', n; END IF;
  SELECT count(*) INTO n FROM ca0253_new_race x
    JOIN essentials.races pr ON pr.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719' AND pr.position_name = x.position_name
   WHERE pr.office_id IS NOT NULL AND pr.office_id <> x.office_id;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % new races disagree with their primary race''s office_id', n; END IF;

  -- is_incumbent is exactly "holds this race's seat", in both directions.
  SELECT count(*) INTO n FROM ca0253_cand c
    JOIN essentials.races r ON r.position_name = c.position_name
     AND r.election_id IN ('1f4a8e7e-cf91-438a-8b1d-b2c944b97aea', '02dee6b2-76cd-4aa3-a365-6ee362f8a719')
    LEFT JOIN ca0253_new_race x ON x.position_name = c.position_name
   WHERE r.election_id = CASE WHEN x.position_name IS NULL THEN '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'::uuid
                              ELSE '02dee6b2-76cd-4aa3-a365-6ee362f8a719'::uuid END
     AND c.is_incumbent IS DISTINCT FROM EXISTS (
           SELECT 1 FROM essentials.office_current_holder och
            WHERE och.office_id = COALESCE(x.office_id, r.office_id) AND och.politician_id = c.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % candidacies whose is_incumbent disagrees with the seat holder', n; END IF;
  SELECT count(*) INTO n FROM ca0253_cand WHERE is_incumbent; IF n <> 56 THEN RAISE EXCEPTION 'PRE: % incumbents, expected 56', n; END IF;

  -- Existing politicians are the active rows named; the 26 already-on-race rows are there and active.
  SELECT count(*) INTO n FROM ca0253_cand c JOIN essentials.politicians p ON p.id = c.politician_id AND p.is_active;
  IF n <> 138 THEN RAISE EXCEPTION 'PRE: % of 138 existing politician_ids found active', n; END IF;
  SELECT count(*) INTO n FROM ca0253_cand c
    JOIN essentials.races r ON r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND r.position_name = c.position_name
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = c.politician_id
   WHERE c.already_on_race AND essentials.is_live_candidate(rc.candidate_status, rc.result)
     AND rc.is_incumbent = c.is_incumbent;
  IF n <> 26 THEN RAISE EXCEPTION 'PRE: % of 26 existing general rows found live', n; END IF;

  -- The new external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0253_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source NOT LIKE 'CA_0253 (2026-09-24):%';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000160..-66000170 are taken by someone else', n; END IF;
  -- No active row by these names already exists (other than one this file created).
  SELECT count(*) INTO n FROM ca0253_new_pol x JOIN essentials.politicians p
      ON lower(p.last_name) = lower(x.last_name) AND lower(p.first_name) = lower(x.first_name) AND p.is_active
   WHERE p.external_id IS DISTINCT FROM x.ext;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the 11 new people already have an active row', n; END IF;

  RAISE NOTICE 'CA_0253 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The eleven new people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true,
       'CA_0253 (2026-09-24): ' || s.text || ' (' || x.position_name || ')', 'manual'
  FROM ca0253_new_pol x JOIN ca0253_src s ON s.code = x.src
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. The sixty-seven new races.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea', x.office_id, x.position_name, '', 1,
       'CA_0253 (2026-09-24): 2026-11-03 general-election race for this seat; field = the certified ballot'
  FROM ca0253_new_race x
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r
                    WHERE r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND r.position_name = x.position_name);

-- ---------------------------------------------------------------------------
-- 3. The 123 new candidacies.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source)
SELECT r.id, COALESCE(c.politician_id, p.id), c.full_name, c.first_name, c.last_name, c.is_incumbent, 'active',
       s.text || '; added by CA_0253 (2026-09-24)'
  FROM ca0253_cand c
  JOIN ca0253_src s ON s.code = c.src
  JOIN essentials.races r ON r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND r.position_name = c.position_name
  LEFT JOIN essentials.politicians p ON p.external_id = c.ext
 WHERE NOT c.already_on_race
   AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND rc.politician_id = COALESCE(c.politician_id, p.id));

-- ---------------------------------------------------------------------------
-- 4. Corrections.
-- ---------------------------------------------------------------------------
-- a. MacKenzie Miller withdrew; she is not on the certified SD11 ballot.
UPDATE essentials.race_candidates SET candidate_status = 'withdrawn', updated_at = now()
 WHERE id = '46919f99-6edc-493c-81f8-761f2582ce8d'
   AND politician_id = 'e125bf5b-3e47-49ff-bcdd-07ab8421b54d' AND candidate_status = 'active';
-- b. SBOE 5: the certified name is SARAH REALE.
UPDATE essentials.race_candidates SET full_name = 'Sarah Reale', first_name = 'Sarah', updated_at = now()
 WHERE id = 'ccc40abd-de7a-43e4-8743-e7e4a57c252b'
   AND politician_id = 'e2c26f7a-e7ff-4e77-bc22-0e66cd1e71ce' AND full_name = 'Sara Reale';

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  -- Every one of the 149 certified candidacies is on its race, linked, and live.
  SELECT count(*) INTO n FROM ca0253_cand c
    JOIN essentials.races ra ON ra.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND ra.position_name = c.position_name
    LEFT JOIN essentials.politicians p ON p.external_id = c.ext
    JOIN essentials.race_candidates rc ON rc.race_id = ra.id AND rc.politician_id = COALESCE(c.politician_id, p.id)
   WHERE essentials.is_live_candidate(rc.candidate_status, rc.result) AND rc.is_incumbent = c.is_incumbent;
  IF n <> 149 THEN RAISE EXCEPTION 'POST: % of 149 certified candidacies present and live', n; END IF;

  -- THE POINT: each of the 76 races carries exactly its certified field as live candidates.
  FOR r IN
    SELECT x.position_name, x.live,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = ra.id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got
      FROM ca0253_expect x
      JOIN essentials.races ra ON ra.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND ra.position_name = x.position_name
  LOOP
    IF r.got <> r.live THEN RAISE EXCEPTION 'POST: % has % live candidates, expected %', r.position_name, r.got, r.live; END IF;
  END LOOP;
  SELECT count(*) INTO n FROM ca0253_expect x
    JOIN essentials.races ra ON ra.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea' AND ra.position_name = x.position_name;
  IF n <> 76 THEN RAISE EXCEPTION 'POST: % of 76 Utah general races found (duplicate or missing race?)', n; END IF;
  SELECT count(*) INTO n FROM essentials.races WHERE election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea';
  IF n <> 76 THEN RAISE EXCEPTION 'POST: "2026 Utah General" holds % races, expected 76', n; END IF;
  -- No Recorder race was created.
  PERFORM 1 FROM essentials.races rr JOIN essentials.elections e ON e.id = rr.election_id
   WHERE e.state = 'UT' AND e.election_date = '2026-11-03' AND rr.position_name = 'Salt Lake County Recorder';
  IF FOUND THEN RAISE EXCEPTION 'POST: a 2026 general Salt Lake County Recorder race exists'; END IF;

  -- The new races carry their seat; the new people are non-incumbent, active, and on exactly one race.
  SELECT count(*) INTO n FROM essentials.races WHERE description LIKE 'CA_0253 (2026-09-24):%' AND office_id IS NOT NULL;
  IF n <> 67 THEN RAISE EXCEPTION 'POST: % of 67 new races with an office_id', n; END IF;
  SELECT count(*) INTO n FROM ca0253_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 11 THEN RAISE EXCEPTION 'POST: % of 11 new people are active non-incumbents on one race', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE source LIKE '%added by CA_0253 (2026-09-24)';
  IF n <> 123 THEN RAISE EXCEPTION 'POST: % rows carry the CA_0253 source, expected 123', n; END IF;

  -- The two corrections landed.
  PERFORM 1 FROM essentials.race_candidates WHERE id = '46919f99-6edc-493c-81f8-761f2582ce8d' AND candidate_status = 'withdrawn';
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Miller SD11 general row is not withdrawn'; END IF;
  PERFORM 1 FROM essentials.race_candidates WHERE id = 'ccc40abd-de7a-43e4-8743-e7e4a57c252b' AND full_name = 'Sarah Reale';
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: SBOE 5 primary row is not "Sarah Reale"'; END IF;

  -- Nothing about seats moved.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> (SELECT missing_terms FROM ca0253_before) THEN RAISE EXCEPTION 'POST: offices_missing_terms moved'; END IF;

  RAISE NOTICE 'CA_0253 applied: 67 races, 11 new people, 123 candidacies, 2 corrections; 76 Utah general rosters match their certified lists';
END $$;

COMMIT;

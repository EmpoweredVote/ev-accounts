-- CA_0233_senate_2026_general_rosters_after_primaries.sql
--
-- Slot CA_0233 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- PR B2 of the CA_0222 follow-ups: make the 2026-11-03 U.S. SENATE general-election rosters match
-- each state's own certified candidate list, in the fourteen states CA_0231 recorded primaries for.
-- CA_0231 records who won; this puts the winners — and the independents and minor-party candidates
-- who never ran in a primary — on the November race. (Phase 167's finding for the House holds here
-- too: a results-driven pass can only remove names; only the certified general list surfaces the
-- candidates we were missing.)
--
-- ===========================================================================================
-- 1. EIGHT NEW RACES — the state had no 2026-11-03 U.S. Senate race row at all
-- ===========================================================================================
--   Same shape as 1296 (position_name 'U.S. Senate <State>', primary_party '', seats 1), plus office_id =
--   the Senate seat that is up (the existing Senate races all carry one), and a description marker.
--   Each state's 2026-11-03 general election row already exists; nothing is added to elections.
--     AK  Sullivan's seat          Peltola, Dan S. Sullivan (inc), Daniel J. Sullivan Jr., Heikes
--     DE  Coons's seat             Coons (inc), Katz
--     FL  Moody's seat (special)   Moody (inc), Nixon, Gillespie (NPA)
--     KS  Marshall's seat          Marshall (inc), Hamilton, Graham (L)
--     MI  Peters's seat (open)     El-Sayed, Rogers, Christensen (L), Long (UST), Marsh (G), Kristy (NL)
--     NH  Shaheen's seat (open)    Pappas, Sununu, Laplante (CON)
--     RI  Reed's seat              Reed (inc), McKay, Bahry (I)
--     WY  Lummis's seat (open)     Hageman, Byrd
--   Alaska: Heikes, not Leslie, is on the certified general list (see CA_0231 for why that primary row
--   is held). Mike Rogers is the former Michigan Representative (ace0b96d), not Rep. Mike Rogers of
--   Alabama.
--
-- ===========================================================================================
-- 2. NOMINEES ADDED TO SIX EXISTING RACES
-- ===========================================================================================
--     MA  + Ayyadurai (I), Tache (PSL)      already: Markey (inc), Deaton; Bech withdrawn
--     ME  + Troy D. Jackson (D)             already: Collins (inc); Platner withdrawn (CA_0222)
--     MN  + Flanagan (DFL), Tafoya (R)      already: Whiting (L), Simonetti (I)
--     OK  + N'Kiyla Thomas (D)              already: Hern, Stinnett, Meinhardt, White  (row merged by CA_0227)
--     TN  + Hagerty (inc), Bradshaw (D)     already: eight independents, all on the certified list
--     VA  + Mizusawa (R)                    already: Warner (inc)
--   No existing row is changed or removed.
--
-- ===========================================================================================
-- 3. ELEVEN NEW politicians ROWS — on a certified November ballot, and not in our data
-- ===========================================================================================
--   Troy D. Jackson (ME, D) · Neil J. Gillespie (FL, NPA) · David C. Graham (KS, L) · Lydia Christensen,
--   Tim Long, Douglas P. Marsh, Walter P. Kristy (MI; L, U.S. Taxpayers, Green, Natural Law) · Edmond
--   Laplante (NH, CON) · Michael Bahry (RI, I) · Shiva Ayyadurai (MA, I) · Joe Tache (MA, PSL).
--   BARE records, 1296 style: name, party, external_id in 1296's -66000xxx block (-66000149..-66000159,
--   the next free numbers; the pre-flight refuses if any is taken), is_incumbent = false stated
--   explicitly (a candidate — CLAUDE.md), is_active = true. No portrait, bio or stance research yet:
--   a certified candidate shown with no profile is an incomplete profile; a certified candidate left
--   off the race is an incorrect ballot. Profiles are follow-up work.
--   Searched first: no active row by these names exists (Donald LaPlante and the committee rows are
--   other people).
--
-- ===========================================================================================
-- SOURCES (each row's race_candidates.source names its state's document)
-- ===========================================================================================
--   AK DE FL MI MN TN VA WY ME — the state's published general candidate list, fetched 2026-09-24.
--   KS NH MA — the state's list, obtained by the operator on 2026-09-24 (the sites are bot-walled to
--     scripts): KansasGeneral2026.csv; NH "CANDIDATE LIST W/ ADDRESS - 09/17/2026"; the MA
--     "2026 State Election Candidates" page text.
--   OK — the State Election Board publishes no November list; the field is its April 3 Candidate List
--     Book plus the official primary and runoff results. The Candidate Withdrawals page lists no Senate
--     candidate.
--   RI — the only list is the 2026-07-30 Declared Candidates Report (Bahry: qualified for the election
--     ballot), plus the certified 2026-09-09 primary. No post-primary list confirms it.
--
-- NOT CHANGED: candidate_status of existing rows (e.g. Collins, Whiting, the TN independents still read
-- 'filed', which is_live_candidate() already treats as live); elections; offices; office_terms.
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS. Dry run: the body wrapped BEGIN; ... ROLLBACK;
-- against prod, applied twice in one transaction, then the rollback confirmed by re-reading the rows.
-- ROLLBACK (once applied): DELETE the race_candidates rows whose source ends 'added by CA_0233
-- (2026-09-24)'; DELETE the eight races whose description starts 'CA_0233'; DELETE the politicians with
-- external_id -66000149..-66000159 (only after confirming nothing else references them).

BEGIN;

CREATE TEMP TABLE ca0233_new_race ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('AK', 'U.S. Senate Alaska', '8fe392b4-a639-4349-a2b7-bb3a63a32416'::uuid, 'Sullivan'),
  ('DE', 'U.S. Senate Delaware', 'b5cd6e9c-4da3-4768-8633-346a170e3ee0'::uuid, 'Coons'),
  ('FL', 'U.S. Senate Florida', '0cd42c43-f72d-474c-87d7-e2682fd95e46'::uuid, 'Moody (special)'),
  ('KS', 'U.S. Senate Kansas', '40481651-6a62-4046-8398-f23dfcf26428'::uuid, 'Marshall'),
  ('MI', 'U.S. Senate Michigan', '1bb21d97-918a-48cb-bc8f-f34cb3a404bc'::uuid, 'Peters (retiring)'),
  ('NH', 'U.S. Senate New Hampshire', 'd37cdff2-581d-43c4-af45-1351a309618a'::uuid, 'Shaheen (retiring)'),
  ('RI', 'U.S. Senate Rhode Island', '61172e93-e725-478f-a41e-891ef715ec2e'::uuid, 'Reed'),
  ('WY', 'U.S. Senate Wyoming', '75eef8b5-4b9c-49bf-8951-76e4fefb53e9'::uuid, 'Lummis (retiring)')
) AS v(st, position_name, office_id, seat_note);

CREATE TEMP TABLE ca0233_new_pol ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000149::bigint, 'Troy', 'Jackson', 'Troy D. Jackson', 'Democratic', 'ME', 'Maine Secretary of State "2026 General Candidate List - FINAL.xlsx" and "2026 Post Primary Withdrawals & Replacement Candidates - Updated 9.22.26" (Jackson received 2026-07-27, replacing Platner)'),
  (-66000150::bigint, 'Neil', 'Gillespie', 'Neil J. Gillespie', 'No Party Affiliation', 'FL', 'Florida Division of Elections candidate list, dos.elections.myflorida.com/candidates/CanList.asp?elecid=20261103-GEN (fetched 2026-09-24)'),
  (-66000151::bigint, 'David', 'Graham', 'David C. Graham', 'Libertarian', 'KS', 'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24; sos.ks.gov is bot-walled to scripts)'),
  (-66000152::bigint, 'Lydia', 'Christensen', 'Lydia Christensen', 'Libertarian', 'MI', 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026)'),
  (-66000153::bigint, 'Tim', 'Long', 'Tim Long', 'U.S. Taxpayers', 'MI', 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026)'),
  (-66000154::bigint, 'Douglas', 'Marsh', 'Douglas P. Marsh', 'Green', 'MI', 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026)'),
  (-66000155::bigint, 'Walter', 'Kristy', 'Walter P. Kristy', 'Natural Law', 'MI', 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026)'),
  (-66000156::bigint, 'Edmond', 'Laplante', 'Edmond Laplante', 'Constitution', 'NH', 'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026-ge-candidate-list.pdf, downloaded by the operator 2026-09-24)'),
  (-66000157::bigint, 'Michael', 'Bahry', 'Michael Bahry', 'Independent', 'RI', 'Rhode Island Department of State Declared Candidates Report (Candidates.xlsx, last modified 2026-07-30: Bahry qualified for the election ballot) plus the certified 2026-09-09 primary (Reed, McKay nominated)'),
  (-66000158::bigint, 'Shiva', 'Ayyadurai', 'Shiva Ayyadurai', 'Independent', 'MA', 'Secretary of the Commonwealth, 2026 State Election Candidates (sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm, read by the operator 2026-09-24; Senator in Congress)'),
  (-66000159::bigint, 'Joe', 'Tache', 'Joe Tache', 'Party for Socialism and Liberation', 'MA', 'Secretary of the Commonwealth, 2026 State Election Candidates (sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm, read by the operator 2026-09-24; Senator in Congress)')
) AS v(ext, first_name, last_name, full_name, party, st, source);

CREATE TEMP TABLE ca0233_cand ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('AK', 'U.S. Senate Alaska', 'Mary Peltola', 'Mary', 'Peltola', '6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba'::uuid, NULL::bigint, false, 'Alaska Division of Elections 2026 General candidate list, elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02; each "(Certified)"); added by CA_0233 (2026-09-24)'),
  ('AK', 'U.S. Senate Alaska', 'Dan S. Sullivan', 'Dan', 'Sullivan', 'a97678bc-8844-4560-87b1-5ef4f8013d96'::uuid, NULL::bigint, true, 'Alaska Division of Elections 2026 General candidate list, elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02; each "(Certified)"); added by CA_0233 (2026-09-24)'),
  ('AK', 'U.S. Senate Alaska', 'Daniel J. Sullivan Jr.', 'Daniel', 'Sullivan', 'f0a46feb-43bc-4620-a81f-3bbf7e3cec9c'::uuid, NULL::bigint, false, 'Alaska Division of Elections 2026 General candidate list, elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02; each "(Certified)"); added by CA_0233 (2026-09-24)'),
  ('AK', 'U.S. Senate Alaska', 'Gerald L. Heikes', 'Gerald', 'Heikes', '3c926073-86ec-41c1-8d38-fa0728889d38'::uuid, NULL::bigint, false, 'Alaska Division of Elections 2026 General candidate list, elections.alaska.gov/candidates/?election=26genr (updated 2026-09-02; each "(Certified)"); added by CA_0233 (2026-09-24)'),
  ('DE', 'U.S. Senate Delaware', 'Chris Coons', 'Chris', 'Coons', 'eaab08fa-c93d-44de-ad8e-06275658dddc'::uuid, NULL::bigint, true, 'Delaware Department of Elections, 2026 General Election candidate list elections.delaware.gov/candidates/candidatelist/genl_fcddt_2026.html (updated 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('DE', 'U.S. Senate Delaware', 'Michael Katz', 'Michael', 'Katz', '5828d7f9-cd77-4d24-9295-3ea27645ade7'::uuid, NULL::bigint, false, 'Delaware Department of Elections, 2026 General Election candidate list elections.delaware.gov/candidates/candidatelist/genl_fcddt_2026.html (updated 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('FL', 'U.S. Senate Florida', 'Ashley Moody', 'Ashley', 'Moody', 'f6c97c43-41e3-45ae-bdaa-c339f2e6ed4d'::uuid, NULL::bigint, true, 'Florida Division of Elections candidate list, dos.elections.myflorida.com/candidates/CanList.asp?elecid=20261103-GEN (fetched 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('FL', 'U.S. Senate Florida', 'Angie Nixon', 'Angie', 'Nixon', '0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid, NULL::bigint, false, 'Florida Division of Elections candidate list, dos.elections.myflorida.com/candidates/CanList.asp?elecid=20261103-GEN (fetched 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('FL', 'U.S. Senate Florida', 'Neil J. Gillespie', 'Neil', 'Gillespie', NULL::uuid, -66000150::bigint, false, 'Florida Division of Elections candidate list, dos.elections.myflorida.com/candidates/CanList.asp?elecid=20261103-GEN (fetched 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('KS', 'U.S. Senate Kansas', 'Roger Marshall', 'Roger', 'Marshall', '9df12eb2-bc9a-4083-8004-1af4167342ea'::uuid, NULL::bigint, true, 'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24; sos.ks.gov is bot-walled to scripts); added by CA_0233 (2026-09-24)'),
  ('KS', 'U.S. Senate Kansas', 'Adam Hamilton', 'Adam', 'Hamilton', '5149b843-8e34-4ccd-8e0a-590d7fc17233'::uuid, NULL::bigint, false, 'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24; sos.ks.gov is bot-walled to scripts); added by CA_0233 (2026-09-24)'),
  ('KS', 'U.S. Senate Kansas', 'David C. Graham', 'David', 'Graham', NULL::uuid, -66000151::bigint, false, 'Kansas Secretary of State 2026 General Election candidate list (KansasGeneral2026.csv, downloaded by the operator 2026-09-24; sos.ks.gov is bot-walled to scripts); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Abdul El-Sayed', 'Abdul', 'El-Sayed', 'ec0cfeae-a512-4ce2-a8f2-a25b00112b9b'::uuid, NULL::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Mike Rogers', 'Mike', 'Rogers', 'ace0b96d-8ef8-4aca-8928-6848ae430da6'::uuid, NULL::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Lydia Christensen', 'Lydia', 'Christensen', NULL::uuid, -66000152::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Tim Long', 'Tim', 'Long', NULL::uuid, -66000153::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Douglas P. Marsh', 'Douglas', 'Marsh', NULL::uuid, -66000154::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('MI', 'U.S. Senate Michigan', 'Walter P. Kristy', 'Walter', 'Kristy', NULL::uuid, -66000155::bigint, false, 'Michigan Bureau of Elections Official Candidate Listing, General Election 2026-11-03 (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026); added by CA_0233 (2026-09-24)'),
  ('NH', 'U.S. Senate New Hampshire', 'Chris Pappas', 'Chris', 'Pappas', '36c07696-c330-45c8-aad9-eac9ee560cf1'::uuid, NULL::bigint, false, 'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026-ge-candidate-list.pdf, downloaded by the operator 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('NH', 'U.S. Senate New Hampshire', 'John E. Sununu', 'John', 'Sununu', 'ffb0dcac-385a-4df3-a441-cdbd0e713c1d'::uuid, NULL::bigint, false, 'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026-ge-candidate-list.pdf, downloaded by the operator 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('NH', 'U.S. Senate New Hampshire', 'Edmond Laplante', 'Edmond', 'Laplante', NULL::uuid, -66000156::bigint, false, 'New Hampshire Secretary of State "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026-ge-candidate-list.pdf, downloaded by the operator 2026-09-24); added by CA_0233 (2026-09-24)'),
  ('RI', 'U.S. Senate Rhode Island', 'Jack Reed', 'Jack', 'Reed', 'afd8d31b-9f88-4eb9-8a88-46e5ef914267'::uuid, NULL::bigint, true, 'Rhode Island Department of State Declared Candidates Report (Candidates.xlsx, last modified 2026-07-30: Bahry qualified for the election ballot) plus the certified 2026-09-09 primary (Reed, McKay nominated); added by CA_0233 (2026-09-24)'),
  ('RI', 'U.S. Senate Rhode Island', 'Raymond McKay', 'Raymond', 'McKay', 'fc0af762-06d0-4722-b6eb-7e3852eb725a'::uuid, NULL::bigint, false, 'Rhode Island Department of State Declared Candidates Report (Candidates.xlsx, last modified 2026-07-30: Bahry qualified for the election ballot) plus the certified 2026-09-09 primary (Reed, McKay nominated); added by CA_0233 (2026-09-24)'),
  ('RI', 'U.S. Senate Rhode Island', 'Michael Bahry', 'Michael', 'Bahry', NULL::uuid, -66000157::bigint, false, 'Rhode Island Department of State Declared Candidates Report (Candidates.xlsx, last modified 2026-07-30: Bahry qualified for the election ballot) plus the certified 2026-09-09 primary (Reed, McKay nominated); added by CA_0233 (2026-09-24)'),
  ('WY', 'U.S. Senate Wyoming', 'Harriet Hageman', 'Harriet', 'Hageman', '1e08c7c7-68c1-4498-90b2-20850bac1c80'::uuid, NULL::bigint, false, 'Wyoming Secretary of State 2026_WY_General_Election_Candidates.csv (2026-09-09); added by CA_0233 (2026-09-24)'),
  ('WY', 'U.S. Senate Wyoming', 'James Byrd', 'James', 'Byrd', 'f8869b74-2a0c-40b7-93b4-40f32eec7108'::uuid, NULL::bigint, false, 'Wyoming Secretary of State 2026_WY_General_Election_Candidates.csv (2026-09-09); added by CA_0233 (2026-09-24)'),
  ('MA', 'U.S. Senate Massachusetts', 'Shiva Ayyadurai', 'Shiva', 'Ayyadurai', NULL::uuid, -66000158::bigint, false, 'Secretary of the Commonwealth, 2026 State Election Candidates (sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm, read by the operator 2026-09-24; Senator in Congress); added by CA_0233 (2026-09-24)'),
  ('MA', 'U.S. Senate Massachusetts', 'Joe Tache', 'Joe', 'Tache', NULL::uuid, -66000159::bigint, false, 'Secretary of the Commonwealth, 2026 State Election Candidates (sec.state.ma.us/divisions/elections/research-and-statistics/2026-state-election-candidates.htm, read by the operator 2026-09-24; Senator in Congress); added by CA_0233 (2026-09-24)'),
  ('ME', 'U.S. Senate Maine', 'Troy D. Jackson', 'Troy', 'Jackson', NULL::uuid, -66000149::bigint, false, 'Maine Secretary of State "2026 General Candidate List - FINAL.xlsx" and "2026 Post Primary Withdrawals & Replacement Candidates - Updated 9.22.26" (Jackson received 2026-07-27, replacing Platner); added by CA_0233 (2026-09-24)'),
  ('MN', 'U.S. Senate Minnesota', 'Peggy Flanagan', 'Peggy', 'Flanagan', 'c788d228-1757-4069-bca4-6a9586819dc8'::uuid, NULL::bigint, false, 'Minnesota Secretary of State electionresultsfiles.sos.mn.gov/20261103/cand.txt (U.S. Senator); added by CA_0233 (2026-09-24)'),
  ('MN', 'U.S. Senate Minnesota', 'Michele Tafoya', 'Michele', 'Tafoya', 'b53157a3-709f-4a0a-8799-19834923d795'::uuid, NULL::bigint, false, 'Minnesota Secretary of State electionresultsfiles.sos.mn.gov/20261103/cand.txt (U.S. Senator); added by CA_0233 (2026-09-24)'),
  ('OK', 'U.S. Senate Oklahoma', 'N''Kiyla Thomas', 'N''Kiyla', 'Thomas', '1e8ea8a4-61d5-44f7-84b9-3aa6633a16e6'::uuid, NULL::bigint, false, 'Oklahoma State Election Board 2026 Candidate List Book (as of 2026-04-03) plus the Official Results of the 2026-06-16 primary (Hern) and 2026-08-25 runoff (Thomas); added by CA_0233 (2026-09-24)'),
  ('TN', 'U.S. Senate Tennessee', 'Bill Hagerty', 'Bill', 'Hagerty', '0dd5daa6-87cf-43a7-a1ee-25349ae35e27'::uuid, NULL::bigint, true, 'Tennessee Secretary of State "Candidates for United States Senate, November 3, 2026 General Election" (sos-prod.tnsosgovfiles.com/.../USSenate_Nov2026.pdf, modified 2026-09-03); added by CA_0233 (2026-09-24)'),
  ('TN', 'U.S. Senate Tennessee', 'Marquita Bradshaw', 'Marquita', 'Bradshaw', 'fb90463e-8edf-4d54-9c3b-9e9dbd559b14'::uuid, NULL::bigint, false, 'Tennessee Secretary of State "Candidates for United States Senate, November 3, 2026 General Election" (sos-prod.tnsosgovfiles.com/.../USSenate_Nov2026.pdf, modified 2026-09-03); added by CA_0233 (2026-09-24)'),
  ('VA', 'U.S. Senate Virginia', 'Bert Mizusawa', 'Bert', 'Mizusawa', '98b68ee6-95b8-41a2-82fc-779ea4a28458'::uuid, NULL::bigint, false, 'Virginia Department of Elections "2026 November Federal Offices Candidate List (rev 9-14-2026)"; added by CA_0233 (2026-09-24)')
) AS v(st, position_name, full_name, first_name, last_name, politician_id, ext, is_incumbent, source);

-- Live-candidate count every one of the fourteen general races must have afterwards.
CREATE TEMP TABLE ca0233_expect ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('AK', 'U.S. Senate Alaska', 4),
  ('DE', 'U.S. Senate Delaware', 2),
  ('FL', 'U.S. Senate Florida', 3),
  ('KS', 'U.S. Senate Kansas', 3),
  ('MI', 'U.S. Senate Michigan', 6),
  ('NH', 'U.S. Senate New Hampshire', 3),
  ('RI', 'U.S. Senate Rhode Island', 3),
  ('WY', 'U.S. Senate Wyoming', 2),
  ('MA', 'U.S. Senate Massachusetts', 4),
  ('ME', 'U.S. Senate Maine', 2),
  ('MN', 'U.S. Senate Minnesota', 4),
  ('OK', 'U.S. Senate Oklahoma', 5),
  ('TN', 'U.S. Senate Tennessee', 10),
  ('VA', 'U.S. Senate Virginia', 2)
) AS v(st, position_name, live);

CREATE TEMP TABLE ca0233_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0233_new_race; IF n <> 8  THEN RAISE EXCEPTION 'PRE: % new races, expected 8', n; END IF;
  SELECT count(*) INTO n FROM ca0233_new_pol;  IF n <> 11 THEN RAISE EXCEPTION 'PRE: % new people, expected 11', n; END IF;
  SELECT count(*) INTO n FROM ca0233_cand;     IF n <> 35 THEN RAISE EXCEPTION 'PRE: % candidacies, expected 35', n; END IF;

  -- Each of the fourteen states has exactly one 2026-11-03 general election row.
  SELECT count(*) INTO n FROM ca0233_expect x
   WHERE (SELECT count(*) FROM essentials.elections e
           WHERE e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general') <> 1;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % states do not have exactly one 2026-11-03 general election', n; END IF;

  -- The eight new races: absent, or already created by this migration.
  SELECT count(*) INTO n FROM ca0233_new_race x
    JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
    JOIN essentials.races r ON r.election_id = e.id AND r.position_name = x.position_name
   WHERE r.description IS DISTINCT FROM ('CA_0233 (2026-09-24): ' || x.seat_note || ' seat');
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the new races already exist, not created by CA_0233', n; END IF;
  -- The six existing races are there.
  SELECT count(*) INTO n FROM ca0233_expect x
    JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
    JOIN essentials.races r ON r.election_id = e.id AND r.position_name = x.position_name
   WHERE x.st NOT IN (SELECT st FROM ca0233_new_race);
  IF n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 existing general Senate races found', n; END IF;

  -- Each new race's office is a real U.S. Senate seat in that state (not a candidacy placeholder).
  SELECT count(*) INTO n FROM ca0233_new_race x
    JOIN essentials.offices o ON o.id = x.office_id::uuid AND o.title NOT LIKE 'Candidate for%'
    JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'NATIONAL_UPPER' AND d.state = x.st;
  IF n <> 8 THEN RAISE EXCEPTION 'PRE: only % of 8 office_ids are that state''s U.S. Senate seat', n; END IF;

  -- The five incumbents hold the seat their race is for (EXISTS per office: office-rooted, no fan-out).
  SELECT count(*) INTO n FROM ca0233_cand c JOIN ca0233_new_race x ON x.st = c.st
   WHERE c.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = x.office_id::uuid AND och.politician_id = c.politician_id);
  IF n <> 5 THEN RAISE EXCEPTION 'PRE: only % of 5 incumbents hold their race''s seat', n; END IF;

  -- Existing politicians are the active rows named.
  SELECT count(*) INTO n FROM ca0233_cand c
    JOIN essentials.politicians p ON p.id = c.politician_id AND p.is_active
   WHERE c.politician_id IS NOT NULL;
  IF n <> (SELECT count(*) FROM ca0233_cand WHERE politician_id IS NOT NULL) THEN
    RAISE EXCEPTION 'PRE: an existing politician_id is missing or inactive';
  END IF;

  -- The new external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0233_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source IS DISTINCT FROM ('CA_0233 (2026-09-24): ' || x.source);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000149..-66000159 are taken by someone else', n; END IF;

  RAISE NOTICE 'CA_0233 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The eleven new people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true,
       'CA_0233 (2026-09-24): ' || x.source, 'manual'
  FROM ca0233_new_pol x
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. The eight new races.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, x.office_id::uuid, x.position_name, '', 1, 'CA_0233 (2026-09-24): ' || x.seat_note || ' seat'
  FROM ca0233_new_race x
  JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = e.id AND r.position_name = x.position_name);

-- ---------------------------------------------------------------------------
-- 3. The candidacies.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source)
SELECT r.id, COALESCE(c.politician_id, p.id), c.full_name, c.first_name, c.last_name, c.is_incumbent, 'active', c.source
  FROM ca0233_cand c
  JOIN essentials.elections e ON e.state = c.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races r ON r.election_id = e.id AND r.position_name = c.position_name
  LEFT JOIN essentials.politicians p ON p.external_id = c.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND rc.politician_id = COALESCE(c.politician_id, p.id));

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  -- Every candidacy is on its race, linked, active.
  SELECT count(*) INTO n FROM ca0233_cand c
    JOIN essentials.elections e ON e.state = c.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
    JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = c.position_name
    LEFT JOIN essentials.politicians p ON p.external_id = c.ext
    JOIN essentials.race_candidates rc ON rc.race_id = ra.id AND rc.politician_id = COALESCE(c.politician_id, p.id)
   WHERE rc.candidate_status = 'active' AND rc.is_incumbent = c.is_incumbent;
  IF n <> 35 THEN RAISE EXCEPTION 'POST: % of 35 candidacies present', n; END IF;

  -- THE POINT: each of the fourteen races carries exactly its certified field as live candidates.
  FOR r IN
    SELECT x.st, x.live, (SELECT count(*) FROM essentials.race_candidates rc
                           WHERE rc.race_id = ra.id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got
      FROM ca0233_expect x
      JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
      JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name
  LOOP
    IF r.got <> r.live THEN RAISE EXCEPTION 'POST: % general Senate race has % live candidates, expected %', r.st, r.got, r.live; END IF;
  END LOOP;
  SELECT count(*) INTO n FROM ca0233_expect x
    JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
    JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;
  IF n <> 14 THEN RAISE EXCEPTION 'POST: % of 14 general Senate races found (duplicate or missing race?)', n; END IF;

  -- The new races carry their seat; the new people are non-incumbent, active, and on exactly one race.
  SELECT count(*) INTO n FROM essentials.races WHERE description LIKE 'CA_0233 (2026-09-24):%' AND office_id IS NOT NULL;
  IF n <> 8 THEN RAISE EXCEPTION 'POST: % of 8 new races with an office_id', n; END IF;
  SELECT count(*) INTO n FROM ca0233_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 11 THEN RAISE EXCEPTION 'POST: % of 11 new people are active non-incumbents on one race', n; END IF;

  -- Nothing about seats moved.
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> (SELECT missing_terms FROM ca0233_before) THEN RAISE EXCEPTION 'POST: offices_missing_terms moved'; END IF;

  RAISE NOTICE 'CA_0233 applied: 8 races, 11 new people, 35 candidacies; 14 general Senate rosters match their certified lists';
END $$;

COMMIT;

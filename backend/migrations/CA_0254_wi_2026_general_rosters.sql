-- CA_0254_wi_2026_general_rosters.sql
--
-- Slot CA_0254 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Make Wisconsin's 2026-11-03 general-election rosters for the ASSEMBLY (99 races), the STATE SENATE
-- (17 races) and the five STATEWIDE races (Governor, Lieutenant Governor, Attorney General, Secretary of
-- State, State Treasurer) match the Wisconsin Elections Commission's November ballot list. Same shape as
-- CA_0233 (the 2026 Senate general rosters). CA_0243 recorded who won the 2026-08-11 primary; this puts
-- the winners — and the independents and minor-party candidates who never ran in a primary — on the
-- November race.
--
-- ===========================================================================================
-- SOURCE
-- ===========================================================================================
--   Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election -
--   11/3/2026" (printed 2026-08-25 16:39, the day WEC certified the primary canvass; file last modified
--   2026-08-26), linked from elections.wi.gov/elections as "Candidates on Ballot By
--   Election_November 3 2026 General Election.pdf" (media/40951). A copy downloads with plain curl from
--   elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf
--   It lists 128 offices and 260 candidates. This file uses the 121 in scope: 241 names on 121 races.
--   The 8 U.S. Representative offices (19 names) are Chris Cantrell's Phase 167 and are NOT touched.
--   Each race's candidate count equals WEC's printed "Total Number of ... Candidates".
--
--   The list is WEC's official November ballot list. It does not carry the word "certified"; it is
--   the only November list WEC publishes and it is the list its elections page links for this election.
--
-- ===========================================================================================
-- 1. NO NEW RACES
-- ===========================================================================================
--   "WI 2026 Statewide General" (588c66dc-31ef-4bbc-b4f6-6da5876a5a38) already holds all 121 races,
--   each with an office_id. Governor and Lieutenant Governor are separate race rows here; WEC prints the
--   ticket on one line ("Tom Tiffany / David Varnam", "David Crowley / Sarah Godlewski"), so each half
--   goes on its own race.
--
-- ===========================================================================================
-- 2. 239 NEW CANDIDACIES (241 on the list; 2 already present)
-- ===========================================================================================
--   * 231 names are CA_0243 'won' rows — the 2026-08-11 party nominees (Republican, Democratic, and the
--     three Wisconsin Green nominees: Pete Karas SoS, David Schupbach AD5, Robert Longwell-Grice AD10).
--     Every WEC name matches its primary row's name exactly; the politician_id is reused. Two of them —
--     Attorney General Josh Kaul (inc) and Eric Toney — are already on the race and are left unchanged,
--     so 229 of these are new rows.
--   * 10 names are not in our data and get a new politicians row (section 3).
--   * is_incumbent = the person holds the race's office today (office_current_holder on races.office_id,
--     an office-rooted read: no fan-out). That gives 98 incumbents, and it agrees with WEC's
--     "Incumbent:" line on every race (excluding "Filed Notification of Noncandidacy" seats). Josh Kaul and
--     John S. Leiber are the two statewide incumbents; Godlewski (current Secretary of State) is NOT the
--     incumbent of the Lieutenant Governor race.
--   * Uncontested (1 candidate): SD3, SD27, AD12, AD27, AD83, AD84, AD97, AD99.
--     Three candidates: Secretary of State, SD15, AD5, AD51, AD53, AD69, AD95.
--
-- ===========================================================================================
-- 3. TEN NEW politicians ROWS — on the November ballot, and not in our data
-- ===========================================================================================
--   Mark Becker (SD1, I) · Christian Ellis (SD9, I) · Christopher Dean (SD15, Serving People Not Parties) ·
--   Michael J. Goodwin (AD3, D) · Shena Chapman (AD36, I) · Nathan Tataje (AD51, American Solidarity Party) ·
--   Rachael Dowling (AD53, I) · Tiffany Brault (AD60, I) · Josh Kelley (AD69, I) · Paul Michael Weber (AD95, I).
--   BARE records, 1296 style: name, party as WEC prints it, is_incumbent = false stated explicitly (none
--   holds a seat — CLAUDE.md), is_active = true. No portrait, bio or stance research yet: profiles are
--   follow-up work.
--   external_id -66000301..-66000310, in 1296's -66000xxx block. NOT the running end (-66000160 on):
--   another session (Utah general rosters) may take those numbers concurrently, and no scan can see a
--   number it has decided to use. Holes are free. The pre-flight refuses if any of the ten is taken.
--   Michael J. Goodwin won the AD3 Democratic primary as a WRITE-IN (556 votes, certified canvass); WEC
--   put him on the November ballot. We have no AD3 Democratic primary race, so he has no primary row;
--   that gap is not closed here.
--   Searched first: no row by these names exists (Josh Becker, Mike Chapman and Michael P Ellis are other
--   people).
--
-- ===========================================================================================
-- 4. ONE EXISTING ROW CLOSED: Jamie Jo Carothers, Governor
-- ===========================================================================================
--   Her November Governor row (source 'ballotpedia', no party) is not on WEC's list: WEC prints two
--   Governor candidates. result := 'not_nominated' (1575's meaning: on a general-election race but did not
--   become a candidate on its ballot, including by never qualifying), with result_source. candidate_status
--   stays 'active' — she did not withdraw, and is_live_candidate() already excludes 'not_nominated'.
--   Changing status would also move her out of the stance-sources "active race" bucket.
--
-- NOT CHANGED: U.S. Representative races and rows (Phase 167); the Racine County races; the primary
-- election and its rows; politicians of existing candidates; elections; offices; office_terms.
-- Noticed, not touched: Governor (D) primary rows for Missy Hughes and Sara Rodriguez now exist with
-- result NULL (both lost the 2026-08-11 primary) — added after CA_0243 by another change.
--
-- STANCE-SOURCES GATE: checked 2026-09-24. check-stance-sources.mjs buckets a seatless politician by the
-- state of their latest candidate_status = 'active' race. Every seatless nominee here already has an active
-- WI primary row, the ten new people have no stance rows, and Carothers' status is unchanged — so no row
-- moves bucket (query: 0 politicians whose bucket would change).
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS; the UPDATE only touches a row whose result is NULL.
-- Dry run: the body wrapped BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then the
-- rollback confirmed by re-reading the rows.
-- ROLLBACK (once applied): DELETE the race_candidates rows whose source ends 'added by CA_0254
-- (2026-09-24)'; DELETE the politicians with external_id -66000301..-66000310 (only after confirming
-- nothing else references them); reset Carothers' row (result, result_source, result_recorded_at := NULL).

BEGIN;

CREATE TEMP TABLE ca0254_new_pol ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000301::bigint, 'Mark', 'Becker', 'Mark Becker', 'Independent', 'State Senate District 1'),
  (-66000302::bigint, 'Christian', 'Ellis', 'Christian Ellis', 'Independent', 'State Senate District 9'),
  (-66000303::bigint, 'Christopher', 'Dean', 'Christopher Dean', 'Serving People Not Parties', 'State Senate District 15'),
  (-66000304::bigint, 'Michael', 'Goodwin', 'Michael J. Goodwin', 'Democratic', 'Assembly District 3'),
  (-66000305::bigint, 'Shena', 'Chapman', 'Shena Chapman', 'Independent', 'Assembly District 36'),
  (-66000306::bigint, 'Nathan', 'Tataje', 'Nathan Tataje', 'American Solidarity Party', 'Assembly District 51'),
  (-66000307::bigint, 'Rachael', 'Dowling', 'Rachael Dowling', 'Independent', 'Assembly District 53'),
  (-66000308::bigint, 'Tiffany', 'Brault', 'Tiffany Brault', 'Independent', 'Assembly District 60'),
  (-66000309::bigint, 'Josh', 'Kelley', 'Josh Kelley', 'Independent', 'Assembly District 69'),
  (-66000310::bigint, 'Paul', 'Weber', 'Paul Michael Weber', 'Independent', 'Assembly District 95')
) AS v(ext, first_name, last_name, full_name, party, position_name);

-- The 241 names WEC prints for the 121 in-scope races. politician_id for an existing person (the CA_0243
-- 'won' row's, or the AG row already on the race); ext for a new person from ca0254_new_pol.
CREATE TEMP TABLE ca0254_cand ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Governor', 'Tom Tiffany', 'Thomas', 'Tiffany', 'a8f96324-50ac-4fa1-b57b-47a998306fe8'::uuid, NULL::bigint, false),
  ('Governor', 'David Crowley', 'David', 'Crowley', 'e9945090-3a5e-4e7e-8601-acb525294a5a'::uuid, NULL::bigint, false),
  ('Lieutenant Governor', 'David Varnam', 'David', 'Varnam', '5af94cba-4e52-4ffc-b331-4a3a4d27bf92'::uuid, NULL::bigint, false),
  ('Lieutenant Governor', 'Sarah Godlewski', 'Sarah', 'Godlewski', '9547b530-f40b-4802-b621-fb64571670e4'::uuid, NULL::bigint, false),
  ('Attorney General', 'Eric Toney', 'Eric', 'Toney', '2bcbbbd9-2200-482a-b63c-ace4d7ac9b79'::uuid, NULL::bigint, false),
  ('Attorney General', 'Josh Kaul', 'Josh', 'Kaul', '9dc798c5-09b7-4d9d-bf8f-e79b0f8c0f74'::uuid, NULL::bigint, true),
  ('Secretary of State', 'Jay Schroeder', 'Jay', 'Schroeder', '22443d74-b683-433d-b3be-03893c8aac89'::uuid, NULL::bigint, false),
  ('Secretary of State', 'JoCasta Zamarripa', 'JoCasta', 'Zamarripa', '4892ed26-cdcc-4c88-82a4-b673f0b43bc9'::uuid, NULL::bigint, false),
  ('Secretary of State', 'Pete Karas', 'Pete', 'Karas', 'd1e1ccd9-4e98-48a7-b9ac-da2cf7d53f02'::uuid, NULL::bigint, false),
  ('State Treasurer', 'John S. Leiber', 'John', 'Leiber', 'c8e496a6-58d6-475a-b6b7-4bf2f15d657b'::uuid, NULL::bigint, true),
  ('State Treasurer', 'Yee Leng Xiong', 'Yee Leng', 'Xiong', '1325d880-95ab-47fb-9a11-e5fd8cf43758'::uuid, NULL::bigint, false),
  ('State Senate District 1', 'Mark Becker', 'Mark', 'Becker', NULL::uuid, -66000301::bigint, false),
  ('State Senate District 1', 'Nic Cravillion', 'Nic', 'Cravillion', 'ab2b087e-4dfa-4d4e-bd37-21a908e7c916'::uuid, NULL::bigint, false),
  ('State Senate District 3', 'Tim Carpenter', 'Tim', 'Carpenter', '5130ee75-9b4e-4095-8a78-245f7402d287'::uuid, NULL::bigint, true),
  ('State Senate District 5', 'Mike Roberts', 'Mike', 'Roberts', '7e5b61d0-7a59-41cf-af7f-9d7daee6422f'::uuid, NULL::bigint, false),
  ('State Senate District 5', 'Robyn Vining', 'Robyn', 'Vining', 'ba7f92e0-6dfb-4832-a4ed-a4ff4a181546'::uuid, NULL::bigint, false),
  ('State Senate District 7', 'Mike Moeller', 'Mike', 'Moeller', 'c65f8016-8db7-4de0-937a-d203025e4993'::uuid, NULL::bigint, false),
  ('State Senate District 7', 'Chris J. Larson', 'Chris', 'Larson', '76a1c7f6-4493-462a-aabd-2307c7cda820'::uuid, NULL::bigint, true),
  ('State Senate District 9', 'Christian Ellis', 'Christian', 'Ellis', NULL::uuid, -66000302::bigint, false),
  ('State Senate District 9', 'Amy Binsfeld', 'Amy', 'Binsfeld', '918c8f91-bd25-448e-994d-cb783150b219'::uuid, NULL::bigint, false),
  ('State Senate District 11', 'Ellen Schutt', 'Ellen', 'Schutt', '2c8c7755-c1cc-45fc-aa04-a5f9fdeec498'::uuid, NULL::bigint, false),
  ('State Senate District 11', 'Adam Duda', 'Adam', 'Duda', '4cd7c5f7-4df5-47a0-98d2-fc06d51d7951'::uuid, NULL::bigint, false),
  ('State Senate District 13', 'John Jagler', 'John', 'Jagler', '6500d1e2-b7f3-4df4-9ca9-c973d91dd573'::uuid, NULL::bigint, true),
  ('State Senate District 13', 'Sasha Ripley', 'Sasha', 'Ripley', 'f7659ceb-413b-4079-ae63-617acf44f58c'::uuid, NULL::bigint, false),
  ('State Senate District 15', 'Christopher Dean', 'Christopher', 'Dean', NULL::uuid, -66000303::bigint, false),
  ('State Senate District 15', 'Scott Fleming', 'Scott', 'Fleming', '41d446fd-8492-4f02-a6cc-9158a3fa7d20'::uuid, NULL::bigint, false),
  ('State Senate District 15', 'Mark Spreitzer', 'Mark', 'Spreitzer', '9767d4aa-c6d5-43be-90b9-e619893b535c'::uuid, NULL::bigint, true),
  ('State Senate District 17', 'Howard Marklein', 'Howard', 'Marklein', '18528793-98ff-447e-80a1-78c6f4edef10'::uuid, NULL::bigint, true),
  ('State Senate District 17', 'Jenna Jacobson', 'Jenna', 'Jacobson', 'cf0a621c-b5a9-4923-9942-a8d6b6d50966'::uuid, NULL::bigint, false),
  ('State Senate District 19', 'Rachael Ann Cabral-Guevara', 'Rachael', 'Cabral-Guevara', '1cdcaa5d-8576-44d4-8d9f-34f321924898'::uuid, NULL::bigint, true),
  ('State Senate District 19', 'Emily Daniels Tseffos', 'Emily', 'Tseffos', '79cd33ab-629e-4682-a2fa-17ec792226a8'::uuid, NULL::bigint, false),
  ('State Senate District 21', 'Jim Croft', 'Jim', 'Croft', '1fca158a-ec5d-4797-9826-07dc678a33a3'::uuid, NULL::bigint, false),
  ('State Senate District 21', 'Trevor Jung', 'Trevor', 'Jung', '2b7018ff-cbb0-4090-9261-daee8c29abae'::uuid, NULL::bigint, false),
  ('State Senate District 23', 'Romaine Robert Quinn', 'Romaine', 'Quinn', 'a0ea7354-d1ff-49d2-a6c4-44a0a8099222'::uuid, NULL::bigint, false),
  ('State Senate District 23', 'Jeff Foster', 'Jeff', 'Foster', '25d579ae-84f6-4724-bf08-cd641cb2295d'::uuid, NULL::bigint, false),
  ('State Senate District 25', 'Erik Severson', 'Erik', 'Severson', 'a1f81b63-9c6f-4eb6-bcf7-e3e0d4bd91b5'::uuid, NULL::bigint, false),
  ('State Senate District 25', 'Charly Ray', 'Charly', 'Ray', '052c0f38-dbf5-426f-b67c-9f7cb9b1cfb4'::uuid, NULL::bigint, false),
  ('State Senate District 27', 'Dianne Hesselbein', 'Dianne', 'Hesselbein', '171dbfaa-58dd-45f4-8526-231d78530461'::uuid, NULL::bigint, true),
  ('State Senate District 29', 'Cory Tomczyk', 'Cory', 'Tomczyk', '10ec6e28-7666-4f86-9f52-9fa4b35d6d6d'::uuid, NULL::bigint, true),
  ('State Senate District 29', 'Gillian Battino', 'Gillian', 'Battino', '25d77091-9955-4a7c-8d22-3f2e8894f030'::uuid, NULL::bigint, false),
  ('State Senate District 31', 'Michele Magadance Skinner', 'Michele', 'Skinner', 'b9e124e0-f552-495a-b742-403167f2b4e5'::uuid, NULL::bigint, false),
  ('State Senate District 31', 'Jeff Smith', 'Jeff', 'Smith', '0d156e09-417d-450a-b757-d44171336fed'::uuid, NULL::bigint, true),
  ('State Senate District 33', 'Chris Kapenga', 'Chris', 'Kapenga', 'fc2aa973-5043-47bc-9bfc-28ed52594724'::uuid, NULL::bigint, true),
  ('State Senate District 33', 'Mike Van Someren', 'Mike', 'Someren', '5e0ad324-0278-4bdf-992e-73a27a89ffcb'::uuid, NULL::bigint, false),
  ('Assembly District 1', 'Joel Kitchens', 'Joel', 'Kitchens', '450a9dfb-a01f-4ad1-b660-517e519c9c0e'::uuid, NULL::bigint, true),
  ('Assembly District 1', 'Renee A. Paplham', 'Renee', 'Paplham', 'a7b5e56b-6160-4313-8787-96549f0a67c9'::uuid, NULL::bigint, false),
  ('Assembly District 2', 'Shae Sortwell', 'Shae', 'Sortwell', '9f534346-6384-4fac-be10-a040ea62c664'::uuid, NULL::bigint, true),
  ('Assembly District 2', 'Alicia Saunders', 'Alicia', 'Saunders', 'e501de3a-6e60-479d-be0e-1632b1dca0bc'::uuid, NULL::bigint, false),
  ('Assembly District 3', 'Ron Tusler', 'Ron', 'Tusler', '62d727b1-8ea6-4607-8759-1db943de2c05'::uuid, NULL::bigint, true),
  ('Assembly District 3', 'Michael J. Goodwin', 'Michael', 'Goodwin', NULL::uuid, -66000304::bigint, false),
  ('Assembly District 4', 'David Steffen', 'David', 'Steffen', '6a2b1e44-55d7-4f9d-b179-d4522bf78e98'::uuid, NULL::bigint, true),
  ('Assembly District 4', 'Alexia Unertl', 'Alexia', 'Unertl', 'e574e81a-3218-4df9-8506-8324f46a26d0'::uuid, NULL::bigint, false),
  ('Assembly District 5', 'Joy Goeben', 'Joy', 'Goeben', '3d9e1ffb-1e2e-445a-a86d-259c630360aa'::uuid, NULL::bigint, true),
  ('Assembly District 5', 'Justin Schumacher', 'Justin', 'Schumacher', 'c9d8ab0e-ccb3-40ee-974c-862debb82340'::uuid, NULL::bigint, false),
  ('Assembly District 5', 'David Schupbach', 'David', 'Schupbach', 'cc26859e-baec-419e-90ea-ff707c346e90'::uuid, NULL::bigint, false),
  ('Assembly District 6', 'Elijah Behnke', 'Elijah', 'Behnke', 'd68b3730-048f-4cb5-a952-104dd75409df'::uuid, NULL::bigint, true),
  ('Assembly District 6', 'Shirley Hinze', 'Shirley', 'Hinze', 'fe1eee99-a787-4217-8988-4f3907cea35e'::uuid, NULL::bigint, false),
  ('Assembly District 7', 'Lee Whiting', 'Lee', 'Whiting', '34058e18-1101-49bc-8f17-2491db82954e'::uuid, NULL::bigint, false),
  ('Assembly District 7', 'Karen Kirsch', 'Karen', 'Kirsch', '0543aef9-357e-4337-8cb2-51c2e1531fea'::uuid, NULL::bigint, true),
  ('Assembly District 8', 'Angel Sanchez', 'Angel', 'Sanchez', '2794aa9b-8442-44c8-a5ef-9e402ff4ef3f'::uuid, NULL::bigint, false),
  ('Assembly District 8', 'Ismael Luna', 'Ismael', 'Luna', 'c20da1c7-53b8-41b8-8e18-293de23a7b4e'::uuid, NULL::bigint, false),
  ('Assembly District 9', 'Sam Guerrero', 'Sam', 'Guerrero', '6dd861ce-da11-4a5f-9716-648d7fe80b2a'::uuid, NULL::bigint, false),
  ('Assembly District 9', 'Priscilla A. Prado', 'Priscilla', 'Prado', 'ea15032b-96a6-4135-bf29-a7e60a2c7153'::uuid, NULL::bigint, true),
  ('Assembly District 10', 'Darrin Madison', 'Darrin', 'Madison', 'aac79124-dd42-4aef-b5a1-73c53ced448f'::uuid, NULL::bigint, true),
  ('Assembly District 10', 'Robert Longwell-Grice', 'Robert', 'Longwell-Grice', '4f23397a-946f-46f4-8098-c8860840fd23'::uuid, NULL::bigint, false),
  ('Assembly District 11', 'Shandowlyon Reaves', 'Shandowlyon', 'Reaves', 'b00e2a59-9414-4205-b203-38ba422a4c9c'::uuid, NULL::bigint, false),
  ('Assembly District 11', 'Sequanna Taylor', 'Sequanna', 'Taylor', '3afc572b-7a49-4cb8-9edd-b57c936cea7b'::uuid, NULL::bigint, true),
  ('Assembly District 12', 'Russell Antonio Goodwin, Sr.', 'Russell', 'Goodwin', 'cdd84abe-0a61-40bb-ba3f-6bf7fab74ba3'::uuid, NULL::bigint, true),
  ('Assembly District 13', 'Mike Morgan', 'Mike', 'Morgan', 'c4607b75-67a8-484a-982b-d3dfcbd675e6'::uuid, NULL::bigint, false),
  ('Assembly District 13', 'Amy Zimmerman', 'Amy', 'Zimmerman', '7c8dea94-8ba3-4f11-b9cb-28ead6724977'::uuid, NULL::bigint, false),
  ('Assembly District 14', 'AmyRose Murphy', 'AmyRose', 'Murphy', 'fb38a66f-59f4-4e14-a01f-55d46ddc3ff7'::uuid, NULL::bigint, false),
  ('Assembly District 14', 'Angelito Tenorio', 'Angelito', 'Tenorio', '57f9eb3c-0554-43ed-b93b-c1ecfbb269fe'::uuid, NULL::bigint, true),
  ('Assembly District 15', 'Adam Neylon', 'Adam', 'Neylon', '8ec2e2fd-f691-4e2c-8b0b-17563155c843'::uuid, NULL::bigint, true),
  ('Assembly District 15', 'Stephen Tryon', 'Stephen', 'Tryon', '267100e6-e581-4ccc-8c25-ef76248a62a4'::uuid, NULL::bigint, false),
  ('Assembly District 16', 'Alciro Deacon', 'Alciro', 'Deacon', '8e53a746-32c5-45ca-9892-0cfa0e76ae45'::uuid, NULL::bigint, false),
  ('Assembly District 16', 'Kalan Haywood', 'Kalan', 'Haywood', '6d736e91-2652-401c-b642-09de30f22a09'::uuid, NULL::bigint, true),
  ('Assembly District 17', 'Charlene Abughrin', 'Charlene', 'Abughrin', '26e9f799-677e-495e-8496-f35f5312a9c5'::uuid, NULL::bigint, false),
  ('Assembly District 17', 'Supreme Moore Omokunde', 'Supreme', 'Moore Omokunde', '125031ca-566f-4f10-a25d-80e3a7866da4'::uuid, NULL::bigint, true),
  ('Assembly District 18', 'Joel Richmond', 'Joel', 'Richmond', 'caf80dec-0c77-464c-bb1c-35cdce8010c2'::uuid, NULL::bigint, false),
  ('Assembly District 18', 'Margaret Arney', 'Margaret', 'Arney', 'fc46160a-cc85-44b2-a28b-dc7a40a37e8c'::uuid, NULL::bigint, true),
  ('Assembly District 19', 'Yasmine B. Outlaw', 'Yasmine', 'Outlaw', '5f83471f-9e95-47ce-aa23-b8e58f89a19a'::uuid, NULL::bigint, false),
  ('Assembly District 19', 'Ryan Clancy', 'Ryan', 'Clancy', '0207b7d2-1195-4672-bb1e-767b00d3f6e4'::uuid, NULL::bigint, true),
  ('Assembly District 20', 'Kyle Cleary', 'Kyle', 'Cleary', '4bb90bad-91cd-4d36-8382-eb36b1d18287'::uuid, NULL::bigint, false),
  ('Assembly District 20', 'Christine M. Sinicki', 'Christine', 'Sinicki', '1c73491e-50bd-4a4f-ac7b-b8e65acdd2bb'::uuid, NULL::bigint, true),
  ('Assembly District 21', 'Dylan Pfaffenbach', 'Dylan', 'Pfaffenbach', '06fe86be-b09e-49ba-ae6e-ea0fd19b5135'::uuid, NULL::bigint, false),
  ('Assembly District 21', 'Daniel J. Bukiewicz', 'Daniel', 'Bukiewicz', 'c8205f59-7eb8-444f-80e5-85911b9b99e7'::uuid, NULL::bigint, false),
  ('Assembly District 22', 'Paul Melotik', 'Paul', 'Melotik', '7c2df740-4334-4ac4-9a4d-3c82031df5fd'::uuid, NULL::bigint, true),
  ('Assembly District 22', 'Dana Glasstein', 'Dana', 'Glasstein', 'b1ba213f-0f67-42c1-ba97-8df8cf2f90c3'::uuid, NULL::bigint, false),
  ('Assembly District 23', 'Aleaner Pabonnie', 'Aleaner', 'Pabonnie', 'a6576108-b79c-4afb-aef5-8744333cc9fe'::uuid, NULL::bigint, false),
  ('Assembly District 23', 'Deb Andraca', 'Deb', 'Andraca', '3736286a-44fb-42ad-8cd0-bcb6a4b985ea'::uuid, NULL::bigint, true),
  ('Assembly District 24', 'Dan Knodl', 'Dan', 'Knodl', '5cf0f099-b460-40f4-9e1a-0663315da02d'::uuid, NULL::bigint, true),
  ('Assembly District 24', 'Matt Brown', 'Matt', 'Brown', '3953219a-0bfc-430b-b062-ead2b23179a6'::uuid, NULL::bigint, false),
  ('Assembly District 25', 'Paul Tittl', 'Paul', 'Tittl', '0d122b39-f293-465a-8d3c-bfde10471705'::uuid, NULL::bigint, true),
  ('Assembly District 25', 'Christopher Able', 'Christopher', 'Able', '0738702f-a6ad-433c-bfc7-38e6d5d59385'::uuid, NULL::bigint, false),
  ('Assembly District 26', 'John Belanger', 'John', 'Belanger', 'b472c683-1555-4f78-b53d-a89916bc6948'::uuid, NULL::bigint, false),
  ('Assembly District 26', 'Joe Sheehan', 'Joe', 'Sheehan', '9d545fd6-2ce1-49a1-bf29-ed77bf7b7f06'::uuid, NULL::bigint, true),
  ('Assembly District 27', 'Lindee Brill', 'Lindee', 'Brill', 'a5f74fc0-4809-40e6-b52f-0bd1e2e86fc5'::uuid, NULL::bigint, true),
  ('Assembly District 28', 'Rob Kreibich', 'Rob', 'Kreibich', '6b10e440-3ab9-4e5e-be02-c61616ea4cf0'::uuid, NULL::bigint, true),
  ('Assembly District 28', 'Robin Lillesve', 'Robin', 'Lillesve', '095d879c-0e81-482a-a56f-7e9a077a5137'::uuid, NULL::bigint, false),
  ('Assembly District 29', 'Treig Pronschinske', 'Treig', 'Pronschinske', '59538da9-a7ca-4e7d-a57b-e576c7d66621'::uuid, NULL::bigint, true),
  ('Assembly District 29', 'Chris Danou', 'Chris', 'Danou', '8846336e-c9cf-441a-bdb5-74323aba3298'::uuid, NULL::bigint, false),
  ('Assembly District 30', 'Shannon Zimmerman', 'Shannon', 'Zimmerman', '842f6e36-3ffa-423c-b445-f38f63060de6'::uuid, NULL::bigint, true),
  ('Assembly District 30', 'Kevin Knoke', 'Kevin', 'Knoke', 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1'::uuid, NULL::bigint, false),
  ('Assembly District 31', 'Tyler August', 'Tyler', 'August', 'dfa3c0a6-c750-4b80-9b60-34689836ad32'::uuid, NULL::bigint, true),
  ('Assembly District 31', 'John Perryman', 'John', 'Perryman', 'a26b2485-1bbe-49ce-a0f2-600fd499bd1a'::uuid, NULL::bigint, false),
  ('Assembly District 32', 'Amanda Nedweski', 'Amanda', 'Nedweski', 'b4e7d7f1-34fb-468e-9f0a-e9e8975d5397'::uuid, NULL::bigint, true),
  ('Assembly District 32', 'Greg Miller', 'Greg', 'Miller', '3ea326c4-7c4d-4235-b443-f1f5c36dfc4a'::uuid, NULL::bigint, false),
  ('Assembly District 33', 'Steve Wicklund', 'Steve', 'Wicklund', '165d3a2e-5515-4a6e-8c5a-8e2caec579ba'::uuid, NULL::bigint, false),
  ('Assembly District 33', 'Maria Elena Bisabarros', 'Maria', 'Bisabarros', '823ce464-e74e-42c5-8fb8-ac4c46407eee'::uuid, NULL::bigint, false),
  ('Assembly District 34', 'Rob Swearingen', 'Rob', 'Swearingen', '0404c82e-7503-4b12-b44d-49d2c990a5a9'::uuid, NULL::bigint, true),
  ('Assembly District 34', 'Merlin Van Buren', 'Merlin', 'Buren', 'fdab433a-e84c-4e2d-9a6a-b9d460205f95'::uuid, NULL::bigint, false),
  ('Assembly District 35', 'Calvin Callahan', 'Calvin', 'Callahan', '1073fd5c-0bac-4f03-8254-892351795937'::uuid, NULL::bigint, true),
  ('Assembly District 35', 'Elizabeth McCrank', 'Elizabeth', 'McCrank', '2751e048-19ac-44c1-a570-428442efde18'::uuid, NULL::bigint, false),
  ('Assembly District 36', 'Shena Chapman', 'Shena', 'Chapman', NULL::uuid, -66000305::bigint, false),
  ('Assembly District 36', 'Jeffrey L. Mursau', 'Jeff', 'Mursau', '58b777cf-d5d6-436b-9229-93ab72d783fb'::uuid, NULL::bigint, true),
  ('Assembly District 37', 'Mark Born', 'Mark', 'Born', '1351c459-aa30-45bb-abe9-feca27e78d92'::uuid, NULL::bigint, true),
  ('Assembly District 37', 'LaToya Bates', 'LaToya', 'Bates', 'f452517e-3e0d-4e59-b915-59cee898c3ed'::uuid, NULL::bigint, false),
  ('Assembly District 38', 'William Penterman', 'Will', 'Penterman', '6293d49b-6a86-41c1-9e2e-5f9ec8188924'::uuid, NULL::bigint, true),
  ('Assembly District 38', 'Terri Wenkman', 'Terri', 'Wenkman', '65ac18ba-45a7-499e-a001-18a5a5ed3aad'::uuid, NULL::bigint, false),
  ('Assembly District 39', 'Alex Dallman', 'Alex', 'Dallman', '20411352-5cd8-49fe-9510-838900689b6a'::uuid, NULL::bigint, true),
  ('Assembly District 39', 'Michael Skivington', 'Michael', 'Skivington', '39bddf48-f8cd-4cda-8bf1-23c6fb29ac15'::uuid, NULL::bigint, false),
  ('Assembly District 40', 'Julie Helmer', 'Julie', 'Helmer', '052da70a-808a-47a9-a954-f1524acc0a3e'::uuid, NULL::bigint, false),
  ('Assembly District 40', 'Karen DeSanto', 'Karen', 'DeSanto', '5277f1a1-99be-4736-8096-07f36833a5cb'::uuid, NULL::bigint, true),
  ('Assembly District 41', 'Tony Kurtz', 'Tony', 'Kurtz', '6576be0a-2c3c-403a-b311-7d652b267aec'::uuid, NULL::bigint, true),
  ('Assembly District 41', 'Zach Commons', 'Zach', 'Commons', '59c99f43-151b-438c-a86b-901da416d9bc'::uuid, NULL::bigint, false),
  ('Assembly District 42', 'Keith F. Miller', 'Keith', 'Miller', '1be41406-5169-4d5d-87b6-f1761b7b2acd'::uuid, NULL::bigint, false),
  ('Assembly District 42', 'Maureen McCarville', 'Maureen', 'McCarville', '21265ed4-0d98-4eb4-b9ea-85821a247d2f'::uuid, NULL::bigint, true),
  ('Assembly District 43', 'Paul McGraw', 'Paul', 'McGraw', '4ca6afa4-51ee-4209-bc92-373fbbd97f79'::uuid, NULL::bigint, false),
  ('Assembly District 43', 'Brienne Brown', 'Brienne', 'Brown', '77707b96-8245-4013-843c-12181ad35ff8'::uuid, NULL::bigint, true),
  ('Assembly District 44', 'Ron Woodman', 'Ron', 'Woodman', 'feeaec60-8753-4e4f-ab2d-790da600656d'::uuid, NULL::bigint, false),
  ('Assembly District 44', 'Ann Roe', 'Ann', 'Roe', '732ee90d-016b-4879-9142-c3583130cf42'::uuid, NULL::bigint, true),
  ('Assembly District 45', 'Jocelyn Jordan', 'Jocelyn', 'Jordan', '9fd31592-37eb-4894-86fe-8646467612d5'::uuid, NULL::bigint, false),
  ('Assembly District 45', 'Clinton Anderson', 'Clint', 'Anderson', 'ad36a437-2193-4725-806b-d9d678579f00'::uuid, NULL::bigint, true),
  ('Assembly District 46', 'John Donohue', 'John', 'Donohue', 'bc992b78-d082-4024-b3a3-277679cbda3a'::uuid, NULL::bigint, false),
  ('Assembly District 46', 'Joan Fitzgerald', 'Joan', 'Fitzgerald', '26902147-6244-4c6e-959b-14a08eb1b56f'::uuid, NULL::bigint, true),
  ('Assembly District 47', 'Sandy Bakk', 'Sandy', 'Bakk', 'a68ecc41-24d4-4f70-b0df-115183be3f18'::uuid, NULL::bigint, false),
  ('Assembly District 47', 'Randy Udell', 'Randy', 'Udell', '79744617-8efa-439f-86fe-b13c253c6cdb'::uuid, NULL::bigint, true),
  ('Assembly District 48', 'Mark Kjorlie', 'Mark', 'Kjorlie', 'd6130ce4-5499-410e-908b-9fa0117d9105'::uuid, NULL::bigint, false),
  ('Assembly District 48', 'Andrew Hysell', 'Andrew', 'Hysell', '674b7c37-fd85-46e7-9087-3fefde2666a4'::uuid, NULL::bigint, true),
  ('Assembly District 49', 'Travis Tranel', 'Travis', 'Tranel', '99444f5f-9093-4d8a-b7bd-1fb6a4157409'::uuid, NULL::bigint, true),
  ('Assembly District 49', 'John Rindy', 'John', 'Rindy', '00a66b60-ef66-4ca8-8ad5-5762bca87e00'::uuid, NULL::bigint, false),
  ('Assembly District 50', 'Jon Aleckson', 'Jon', 'Aleckson', '7ac5d207-2b94-4b39-97be-3c8ba0a5f24e'::uuid, NULL::bigint, false),
  ('Assembly District 50', 'Bill Oemichen', 'Bill', 'Oemichen', '011bee3f-2a87-4590-893d-c6be616fa45a'::uuid, NULL::bigint, false),
  ('Assembly District 51', 'Nathan Tataje', 'Nathan', 'Tataje', NULL::uuid, -66000306::bigint, false),
  ('Assembly District 51', 'Todd Novak', 'Todd', 'Novak', 'a84e1f91-5598-46b3-9a90-6d77cf71083c'::uuid, NULL::bigint, true),
  ('Assembly District 51', 'Ben Gruber', 'Ben', 'Gruber', 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff'::uuid, NULL::bigint, false),
  ('Assembly District 52', 'Reive Pullen', 'Reive', 'Pullen', 'fab1498c-507a-463e-a654-367e49456200'::uuid, NULL::bigint, false),
  ('Assembly District 52', 'Lee Snodgrass', 'Lee', 'Snodgrass', '352ced5f-5466-407c-a839-256de6542b8c'::uuid, NULL::bigint, true),
  ('Assembly District 53', 'Rachael Dowling', 'Rachael', 'Dowling', NULL::uuid, -66000307::bigint, false),
  ('Assembly District 53', 'David Daniels', 'David', 'Daniels', '5079d27a-ae0c-4b0b-b494-7d38f4dc5e98'::uuid, NULL::bigint, false),
  ('Assembly District 53', 'Becky Nichols', 'Becky', 'Nichols', 'f42d0120-f51e-451c-b79e-2a7db2aec953'::uuid, NULL::bigint, false),
  ('Assembly District 54', 'Tim Paterson', 'Tim', 'Paterson', 'a2924044-7508-49b2-b0e1-885f4ccaf5ce'::uuid, NULL::bigint, false),
  ('Assembly District 54', 'Lori Palmeri', 'Lori', 'Palmeri', '5ace10bc-ca43-4165-abf5-c52c5bb1ef01'::uuid, NULL::bigint, true),
  ('Assembly District 55', 'Nate Gustafson', 'Nate', 'Gustafson', 'c2a96302-5df2-4f6c-a96a-0a56b466a604'::uuid, NULL::bigint, true),
  ('Assembly District 55', 'Alex Corrigan', 'Alex', 'Corrigan', '32c10808-4df7-44bb-8098-6b3867f47514'::uuid, NULL::bigint, false),
  ('Assembly District 56', 'Anthony W. Phillips', 'Anthony', 'Phillips', '78c53e55-a6f2-407e-8d04-56a6f20fe1df'::uuid, NULL::bigint, false),
  ('Assembly District 56', 'Grace Abitz', 'Grace', 'Abitz', '9be2bac6-1262-4ee1-a41b-2d84e1007769'::uuid, NULL::bigint, false),
  ('Assembly District 57', 'Kevin Krentz', 'Kevin', 'Krentz', '5241dedb-30c9-49cf-8d0c-f0daafc103f3'::uuid, NULL::bigint, false),
  ('Assembly District 57', 'Joey Marschall', 'Joey', 'Marschall', 'f8ec916e-b7c2-449d-aae4-74fc248b95a9'::uuid, NULL::bigint, false),
  ('Assembly District 58', 'Bernie Newman', 'Bernie', 'Newman', 'b01540ed-5638-4f61-b066-17b27232f4e8'::uuid, NULL::bigint, false),
  ('Assembly District 58', 'Dennis D. Degenhardt', 'Dennis', 'Degenhardt', '1ec1373d-3349-48f7-aaa9-425a59c0c590'::uuid, NULL::bigint, false),
  ('Assembly District 59', 'Bradley Petersen', 'Bradley', 'Petersen', 'e609dce3-0d0e-4685-b6f9-9d959000e2de'::uuid, NULL::bigint, false),
  ('Assembly District 59', 'Jack Holzman', 'Jack', 'Holzman', '6746f7ea-b5a7-47c8-8d60-f41cbbb2e5e0'::uuid, NULL::bigint, false),
  ('Assembly District 60', 'Tiffany Brault', 'Tiffany', 'Brault', NULL::uuid, -66000308::bigint, false),
  ('Assembly District 60', 'Marty Ryan', 'Marty', 'Ryan', '7e07c31e-9507-4872-8410-75dfd2fb145d'::uuid, NULL::bigint, false),
  ('Assembly District 61', 'Bob Donovan', 'Bob', 'Donovan', 'c864b687-0f0d-468d-a674-9e72aee3f8f2'::uuid, NULL::bigint, true),
  ('Assembly District 61', 'Ben Brist', 'Ben', 'Brist', '591924fa-120b-4221-9fee-ebe48159494e'::uuid, NULL::bigint, false),
  ('Assembly District 62', 'Mike Bellagio', 'Mike', 'Bellagio', 'e2a3c2f9-7067-4443-bed0-eabc6efa892a'::uuid, NULL::bigint, false),
  ('Assembly District 62', 'Angelina M. Cruz', 'Angelina', 'Cruz', '11c8f424-55d1-4e28-b297-d6a670a033d6'::uuid, NULL::bigint, true),
  ('Assembly District 63', 'Robert Wittke', 'Bob', 'Wittke', '7c8a7cd3-ac60-4292-81c8-11f1946fb9e0'::uuid, NULL::bigint, true),
  ('Assembly District 63', 'Eddie Phanichkul', 'Eddie', 'Phanichkul', '83f8f9f9-f1f5-457c-8335-d226998eb092'::uuid, NULL::bigint, false),
  ('Assembly District 64', 'Ed Hibsch', 'Ed', 'Hibsch', '22739114-d528-4822-89ad-06885e5f6fbe'::uuid, NULL::bigint, false),
  ('Assembly District 64', 'Tip McGuire', 'Tip', 'McGuire', 'c7f2ee81-9cdc-4b21-8b1b-9a78c75663ac'::uuid, NULL::bigint, true),
  ('Assembly District 65', 'Valerie Kretchmer', 'Valerie', 'Kretchmer', '2fdb3d2a-4a80-4969-a7a6-80f8a8160d26'::uuid, NULL::bigint, false),
  ('Assembly District 65', 'Ben DeSmidt', 'Ben', 'DeSmidt', '1646f089-0f51-45f8-b893-c5886a0e1a69'::uuid, NULL::bigint, true),
  ('Assembly District 66', 'Gina Cefalu Paulick', 'Gina', 'Cefalu-Paulick', '1d3dabab-3ecf-46e0-8a5e-34be8a7d27b9'::uuid, NULL::bigint, false),
  ('Assembly District 66', 'Greta Neubauer', 'Greta', 'Neubauer', '4e65b04a-e607-4905-93ef-1e6ec0552fb6'::uuid, NULL::bigint, true),
  ('Assembly District 67', 'David Armstrong', 'Dave', 'Armstrong', '374fcadb-a124-4a02-b529-5a63ec494bbf'::uuid, NULL::bigint, true),
  ('Assembly District 67', 'Indiana Thompson', 'Indiana', 'Thompson', '5824a4de-323e-455d-b6bd-3387248b18ae'::uuid, NULL::bigint, false),
  ('Assembly District 68', 'Rob Summerfield', 'Rob', 'Summerfield', 'fa25d156-89a7-4a29-ade3-e55688cfcee5'::uuid, NULL::bigint, true),
  ('Assembly District 68', 'Elisha King', 'Elisha', 'King', '85224811-d7d6-448d-9bab-79d9f510ccf6'::uuid, NULL::bigint, false),
  ('Assembly District 69', 'Josh Kelley', 'Josh', 'Kelley', NULL::uuid, -66000309::bigint, false),
  ('Assembly District 69', 'Karen Hurd', 'Karen', 'Hurd', '86c404da-e255-4944-af23-113ad077092d'::uuid, NULL::bigint, true),
  ('Assembly District 69', 'Roger Halls', 'Roger', 'Halls', 'b62fd642-9089-4486-b1e1-19b215812ca9'::uuid, NULL::bigint, false),
  ('Assembly District 70', 'Nancy VanderMeer', 'Nancy', 'VanderMeer', 'cff417b2-5774-4295-beac-151d5015feb6'::uuid, NULL::bigint, true),
  ('Assembly District 70', 'Stephanie Stuve Bodeen', 'Stephanie', 'Bodeen', 'f29e4b9e-6a61-48fc-bb80-afc53aaee9c7'::uuid, NULL::bigint, false),
  ('Assembly District 71', 'Jeff Disher', 'Jeff', 'Disher', 'af5a6c62-eb5f-424b-b73f-94c9196445cb'::uuid, NULL::bigint, false),
  ('Assembly District 71', 'Vinnie Miresse', 'Vinnie', 'Miresse', '7c0b6fe8-da1a-45d8-8732-a411915c0d32'::uuid, NULL::bigint, true),
  ('Assembly District 72', 'Scott Krug', 'Scott', 'Krug', '28d9e7b4-9922-4b53-8def-25f779d2e4d2'::uuid, NULL::bigint, true),
  ('Assembly District 72', 'Christine Maltese', 'Christine', 'Maltese', '08fd2a84-0805-4be9-ab7a-df1275de29ec'::uuid, NULL::bigint, false),
  ('Assembly District 73', 'Frank Kostka', 'Frank', 'Kostka', 'd680d499-1b2f-4e25-b820-315b6e97c394'::uuid, NULL::bigint, false),
  ('Assembly District 73', 'Angela Stroud', 'Angela', 'Stroud', '4ab2cafc-8eca-4cef-b301-830441a22e75'::uuid, NULL::bigint, true),
  ('Assembly District 74', 'Chanz Green', 'Chanz', 'Green', '5c631466-ba33-4731-89a3-ca017444cf78'::uuid, NULL::bigint, true),
  ('Assembly District 74', 'Paul Johnson', 'Paul', 'Johnson', 'b6e5c02d-1869-486e-81db-e0f223637c99'::uuid, NULL::bigint, false),
  ('Assembly District 75', 'Duke Tucker', 'Duke', 'Tucker', '00d0e0fc-ac5d-4610-bf25-d858a85a4b80'::uuid, NULL::bigint, true),
  ('Assembly District 75', 'Keith Mogel', 'Keith', 'Mogel', '07257a30-e7bd-4c83-898e-f786b89237b2'::uuid, NULL::bigint, false),
  ('Assembly District 76', 'Nina Chat', 'Nina', 'Chat', '4def685e-bb63-47e3-8c88-7acedf7b429b'::uuid, NULL::bigint, false),
  ('Assembly District 76', 'Dina Nina Martinez-Rutherford', 'Dina', 'Martinez-Rutherford', 'ac7636a5-edf2-4f32-b712-1fdd5a8909f9'::uuid, NULL::bigint, false),
  ('Assembly District 77', 'Jane McCormick', 'Jane', 'McCormick', '1e8a9fe5-a3c1-40e0-b5cd-dfb6d61b14f1'::uuid, NULL::bigint, false),
  ('Assembly District 77', 'Renuka Mayadev', 'Renuka', 'Mayadev', '7d91fee1-7c0c-41e5-b1f2-fa93849c772c'::uuid, NULL::bigint, true),
  ('Assembly District 78', 'Henry Johnson', 'Henry', 'Johnson', '2005a1e5-b130-43f4-8f6c-8953ff3ed038'::uuid, NULL::bigint, false),
  ('Assembly District 78', 'Shelia Stubbs', 'Shelia', 'Stubbs', 'b4c1f85b-4fd7-4faf-9198-1dfcbc955941'::uuid, NULL::bigint, true),
  ('Assembly District 79', 'John Fons', 'John', 'Fons', '90dda424-9635-490e-92ca-801f516e51b3'::uuid, NULL::bigint, false),
  ('Assembly District 79', 'Lisa Subeck', 'Lisa', 'Subeck', 'dc0e341f-b827-45f7-bcc6-35b8376979b3'::uuid, NULL::bigint, true),
  ('Assembly District 80', 'Simran Arora', 'Simran', 'Arora', '52d16405-dcbd-4c83-b03c-bff8b176e7a1'::uuid, NULL::bigint, false),
  ('Assembly District 80', 'Mike Bare', 'Mike', 'Bare', '79760db0-6741-4290-b4ab-b0de68df3ed3'::uuid, NULL::bigint, true),
  ('Assembly District 81', 'Mark S. Maier', 'Mark', 'Maier', '29b53130-59a5-4537-be75-dc9be8b021ab'::uuid, NULL::bigint, false),
  ('Assembly District 81', 'Alex Joers', 'Alex', 'Joers', '8e804443-d7ac-4103-943f-546a76c4c8bf'::uuid, NULL::bigint, true),
  ('Assembly District 82', 'Bryson Reyes', 'Bryson', 'Reyes', 'db04f75c-76a9-40dd-a742-e71071117f27'::uuid, NULL::bigint, false),
  ('Assembly District 82', 'Rico Camacho', 'Rico', 'Camacho', 'd69fb148-d385-47d0-9fb4-68e89f8fe20e'::uuid, NULL::bigint, false),
  ('Assembly District 83', 'Dave Maxey', 'Dave', 'Maxey', '1d1a1f40-a1e4-4208-bdc0-810571bd11a9'::uuid, NULL::bigint, true),
  ('Assembly District 84', 'Chuck Wichgers', 'Chuck', 'Wichgers', '3db74c79-d91c-4bfb-9d1e-7cfc022cde25'::uuid, NULL::bigint, true),
  ('Assembly District 85', 'Patrick Snyder', 'Pat', 'Snyder', 'f59396a3-66bf-481d-8180-0cf1cfea5280'::uuid, NULL::bigint, true),
  ('Assembly District 85', 'John Kroll', 'John', 'Kroll', '6796601f-fc5e-429b-af63-9ca320047270'::uuid, NULL::bigint, false),
  ('Assembly District 86', 'John Spiros', 'John', 'Spiros', '94794832-a1f2-475f-93eb-2e8d896fd8be'::uuid, NULL::bigint, true),
  ('Assembly District 86', 'Andy Wuethrich', 'Andy', 'Wuethrich', 'fa4813d8-02a3-490e-8b13-1fcda269b919'::uuid, NULL::bigint, false),
  ('Assembly District 87', 'Brent Jacobson', 'Brent', 'Jacobson', '1adb3e54-9f6d-475c-9c4b-9a499f7a9f29'::uuid, NULL::bigint, true),
  ('Assembly District 87', 'Bob Look', 'Bob', 'Look', '7f8d35f9-48b1-40a2-af1e-0591fd16b359'::uuid, NULL::bigint, false),
  ('Assembly District 88', 'Ben Franklin', 'Ben', 'Franklin', '8edbab4d-f89d-4dc2-b558-00f85f4d349a'::uuid, NULL::bigint, true),
  ('Assembly District 88', 'Brandy Tollefson', 'Brandy', 'Tollefson', 'beb7d2dc-1db8-4025-9aa4-032214a71817'::uuid, NULL::bigint, false),
  ('Assembly District 89', 'Bobby R. Lindsey', 'Bobby', 'Lindsey', '1a735221-1367-4192-a2ba-ce18877ce2e4'::uuid, NULL::bigint, false),
  ('Assembly District 89', 'Ryan Spaude', 'Ryan', 'Spaude', '3ab564b4-5b6e-4c25-8ea1-6d85583ef2bf'::uuid, NULL::bigint, true),
  ('Assembly District 90', 'Jessica Henderson', 'Jessica', 'Henderson', '4916d5ac-adcc-4cc1-936b-4983c06c737b'::uuid, NULL::bigint, false),
  ('Assembly District 90', 'Amaad Rivera-Wagner', 'Amaad', 'Rivera-Wagner', 'c2eecef6-b969-43d0-9d19-7d048bf412e5'::uuid, NULL::bigint, true),
  ('Assembly District 91', 'Bruce Stabenow', 'Bruce', 'Stabenow', '191d79cb-8217-41e7-8348-eeeb2ea67b87'::uuid, NULL::bigint, false),
  ('Assembly District 91', 'Jodi Emerson', 'Jodi', 'Emerson', '74f9f4da-7fa4-4b49-899f-ab6ebf7ca1e0'::uuid, NULL::bigint, true),
  ('Assembly District 92', 'Clint Moses', 'Clint', 'Moses', 'aa5b5294-df1a-47dd-bca9-1d7672d29417'::uuid, NULL::bigint, true),
  ('Assembly District 92', 'Jeremiah Fredrickson', 'Jeremiah', 'Fredrickson', 'c3b22f21-fdef-46a9-bb32-680f08459d91'::uuid, NULL::bigint, false),
  ('Assembly District 93', 'Michael Ayala', 'Michael', 'Ayala', '1022f455-9c7e-4b48-890e-d9c520e6b095'::uuid, NULL::bigint, false),
  ('Assembly District 93', 'Christian Phelps', 'Christian', 'Phelps', '2de7b0f1-8e48-439b-a9ec-5f2b2b3ce90f'::uuid, NULL::bigint, true),
  ('Assembly District 94', 'Keith Purnell', 'Keith', 'Purnell', '95946cdd-cc09-4745-a120-d4b27bdd5742'::uuid, NULL::bigint, false),
  ('Assembly District 94', 'Steve Doyle', 'Steve', 'Doyle', 'd08c31db-7c13-4e19-871d-47c76100867d'::uuid, NULL::bigint, true),
  ('Assembly District 95', 'Paul Michael Weber', 'Paul', 'Weber', NULL::uuid, -66000310::bigint, false),
  ('Assembly District 95', 'Cedric Schnitzler', 'Cedric', 'Schnitzler', '00c5279d-7049-47ec-ac59-605fd7a0f623'::uuid, NULL::bigint, false),
  ('Assembly District 95', 'Jill Billings', 'Jill', 'Billings', '7b6ec364-24fc-446e-91e2-617c91d14b8f'::uuid, NULL::bigint, true),
  ('Assembly District 96', 'Jim Green', 'Jim', 'Green', '0036da0e-efe2-4896-94c9-db9ff33917df'::uuid, NULL::bigint, false),
  ('Assembly District 96', 'Tara Johnson', 'Tara', 'Johnson', '94b1866a-cc0a-409a-bd21-367abf8be938'::uuid, NULL::bigint, true),
  ('Assembly District 97', 'Cindi Duchow', 'Cindi', 'Duchow', '9fe7f550-979e-47d1-befe-667bbadf3018'::uuid, NULL::bigint, true),
  ('Assembly District 98', 'Jim Piwowarczyk', 'Jim', 'Piwowarczyk', '1e6711f8-190e-4edd-a2d7-75584e192ce9'::uuid, NULL::bigint, true),
  ('Assembly District 98', 'Matt Philibert', 'Matt', 'Philibert', '4e04a44f-b150-4072-a844-b5cd578ea217'::uuid, NULL::bigint, false),
  ('Assembly District 99', 'Barbara Dittrich', 'Barbara', 'Dittrich', '81359937-26c3-4cda-a621-c678457c85a6'::uuid, NULL::bigint, true)
) AS v(position_name, full_name, first_name, last_name, politician_id, ext, is_incumbent);

-- Live-candidate count each race must have afterwards = WEC's printed total for the office.
CREATE TEMP TABLE ca0254_expect ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Governor', 2),
  ('Lieutenant Governor', 2),
  ('Attorney General', 2),
  ('Secretary of State', 3),
  ('State Treasurer', 2),
  ('State Senate District 1', 2),
  ('State Senate District 3', 1),
  ('State Senate District 5', 2),
  ('State Senate District 7', 2),
  ('State Senate District 9', 2),
  ('State Senate District 11', 2),
  ('State Senate District 13', 2),
  ('State Senate District 15', 3),
  ('State Senate District 17', 2),
  ('State Senate District 19', 2),
  ('State Senate District 21', 2),
  ('State Senate District 23', 2),
  ('State Senate District 25', 2),
  ('State Senate District 27', 1),
  ('State Senate District 29', 2),
  ('State Senate District 31', 2),
  ('State Senate District 33', 2),
  ('Assembly District 1', 2),
  ('Assembly District 2', 2),
  ('Assembly District 3', 2),
  ('Assembly District 4', 2),
  ('Assembly District 5', 3),
  ('Assembly District 6', 2),
  ('Assembly District 7', 2),
  ('Assembly District 8', 2),
  ('Assembly District 9', 2),
  ('Assembly District 10', 2),
  ('Assembly District 11', 2),
  ('Assembly District 12', 1),
  ('Assembly District 13', 2),
  ('Assembly District 14', 2),
  ('Assembly District 15', 2),
  ('Assembly District 16', 2),
  ('Assembly District 17', 2),
  ('Assembly District 18', 2),
  ('Assembly District 19', 2),
  ('Assembly District 20', 2),
  ('Assembly District 21', 2),
  ('Assembly District 22', 2),
  ('Assembly District 23', 2),
  ('Assembly District 24', 2),
  ('Assembly District 25', 2),
  ('Assembly District 26', 2),
  ('Assembly District 27', 1),
  ('Assembly District 28', 2),
  ('Assembly District 29', 2),
  ('Assembly District 30', 2),
  ('Assembly District 31', 2),
  ('Assembly District 32', 2),
  ('Assembly District 33', 2),
  ('Assembly District 34', 2),
  ('Assembly District 35', 2),
  ('Assembly District 36', 2),
  ('Assembly District 37', 2),
  ('Assembly District 38', 2),
  ('Assembly District 39', 2),
  ('Assembly District 40', 2),
  ('Assembly District 41', 2),
  ('Assembly District 42', 2),
  ('Assembly District 43', 2),
  ('Assembly District 44', 2),
  ('Assembly District 45', 2),
  ('Assembly District 46', 2),
  ('Assembly District 47', 2),
  ('Assembly District 48', 2),
  ('Assembly District 49', 2),
  ('Assembly District 50', 2),
  ('Assembly District 51', 3),
  ('Assembly District 52', 2),
  ('Assembly District 53', 3),
  ('Assembly District 54', 2),
  ('Assembly District 55', 2),
  ('Assembly District 56', 2),
  ('Assembly District 57', 2),
  ('Assembly District 58', 2),
  ('Assembly District 59', 2),
  ('Assembly District 60', 2),
  ('Assembly District 61', 2),
  ('Assembly District 62', 2),
  ('Assembly District 63', 2),
  ('Assembly District 64', 2),
  ('Assembly District 65', 2),
  ('Assembly District 66', 2),
  ('Assembly District 67', 2),
  ('Assembly District 68', 2),
  ('Assembly District 69', 3),
  ('Assembly District 70', 2),
  ('Assembly District 71', 2),
  ('Assembly District 72', 2),
  ('Assembly District 73', 2),
  ('Assembly District 74', 2),
  ('Assembly District 75', 2),
  ('Assembly District 76', 2),
  ('Assembly District 77', 2),
  ('Assembly District 78', 2),
  ('Assembly District 79', 2),
  ('Assembly District 80', 2),
  ('Assembly District 81', 2),
  ('Assembly District 82', 2),
  ('Assembly District 83', 1),
  ('Assembly District 84', 1),
  ('Assembly District 85', 2),
  ('Assembly District 86', 2),
  ('Assembly District 87', 2),
  ('Assembly District 88', 2),
  ('Assembly District 89', 2),
  ('Assembly District 90', 2),
  ('Assembly District 91', 2),
  ('Assembly District 92', 2),
  ('Assembly District 93', 2),
  ('Assembly District 94', 2),
  ('Assembly District 95', 3),
  ('Assembly District 96', 2),
  ('Assembly District 97', 1),
  ('Assembly District 98', 2),
  ('Assembly District 99', 1)
) AS v(position_name, live);

CREATE TEMP TABLE ca0254_const ON COMMIT DROP AS
SELECT '588c66dc-31ef-4bbc-b4f6-6da5876a5a38'::uuid AS election_id,
       '1b18a330-319c-41eb-a66d-373f06a6fcf0'::uuid AS carothers_id,
       'Wisconsin Elections Commission, "Candidates on Ballot by Election, 2026 General Election - 11/3/2026" (printed 2026-08-25; elections.wi.gov/sites/default/files/documents/Candidates%20on%20Ballot%20By%20Election_November%203%202026%20General%20Election_0.pdf)'::text AS wec_source,
       (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
       (SELECT count(*) FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
         WHERE r.election_id = '588c66dc-31ef-4bbc-b4f6-6da5876a5a38' AND r.position_name LIKE 'U.S. Representative%') AS us_rep_rows;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; eid uuid := (SELECT election_id FROM ca0254_const);
BEGIN
  SELECT count(*) INTO n FROM ca0254_new_pol; IF n <> 10  THEN RAISE EXCEPTION 'PRE: % new people, expected 10', n; END IF;
  SELECT count(*) INTO n FROM ca0254_cand;    IF n <> 241 THEN RAISE EXCEPTION 'PRE: % candidacies, expected 241', n; END IF;
  SELECT count(*) INTO n FROM ca0254_expect;  IF n <> 121 THEN RAISE EXCEPTION 'PRE: % races, expected 121', n; END IF;
  SELECT sum(live) INTO n FROM ca0254_expect; IF n <> 241 THEN RAISE EXCEPTION 'PRE: expected counts sum to %, not 241', n; END IF;
  SELECT count(*) INTO n FROM (SELECT position_name, politician_id, ext FROM ca0254_cand GROUP BY 1, 2, 3 HAVING count(*) > 1) d;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % duplicate candidacies in the list', n; END IF;

  -- The election is Wisconsin's 2026-11-03 general.
  SELECT count(*) INTO n FROM essentials.elections e
   WHERE e.id = eid AND e.state = 'WI' AND e.election_date = '2026-11-03' AND e.election_type = 'general';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: election % is not the WI 2026-11-03 general', eid; END IF;

  -- Each of the 121 races exists exactly once on that election and carries its seat.
  SELECT count(*) INTO n FROM ca0254_expect x
   WHERE (SELECT count(*) FROM essentials.races r
           WHERE r.election_id = eid AND r.position_name = x.position_name AND r.office_id IS NOT NULL) <> 1;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the 121 races are missing, duplicated or have no office_id', n; END IF;

  -- Existing politicians are the active rows named, and are CA_0243 'won' rows for the same position.
  SELECT count(*) INTO n FROM ca0254_cand c
    JOIN essentials.politicians p ON p.id = c.politician_id AND p.is_active
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates rc
                   JOIN essentials.races r ON r.id = rc.race_id
                   JOIN essentials.elections e ON e.id = r.election_id
                  WHERE rc.politician_id = c.politician_id AND rc.result = 'won'
                    AND e.state = 'WI' AND e.election_date = '2026-08-11' AND r.position_name = c.position_name);
  IF n <> 231 THEN RAISE EXCEPTION 'PRE: only % of 231 existing people are active primary winners for that race', n; END IF;

  -- is_incumbent in the list = holds the race's office today (office-rooted: one row per office).
  SELECT count(*) INTO n FROM ca0254_cand c
    JOIN essentials.races r ON r.election_id = eid AND r.position_name = c.position_name
   WHERE c.is_incumbent IS DISTINCT FROM (c.politician_id IS NOT NULL AND EXISTS (
           SELECT 1 FROM essentials.office_current_holder och
            WHERE och.office_id = r.office_id AND och.politician_id = c.politician_id));
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % candidacies disagree with office_current_holder on incumbency', n; END IF;
  SELECT count(*) INTO n FROM ca0254_cand WHERE is_incumbent; IF n <> 98 THEN RAISE EXCEPTION 'PRE: % incumbents, expected 98', n; END IF;

  -- The new external_ids are free, or hold exactly the person this file created; the names are new.
  SELECT count(*) INTO n FROM ca0254_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source IS DISTINCT FROM ('CA_0254 (2026-09-24): ' || (SELECT wec_source FROM ca0254_const));
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000301..-66000310 are taken by someone else', n; END IF;
  SELECT count(*) INTO n FROM ca0254_new_pol x JOIN essentials.politicians p
      ON lower(p.first_name) = lower(x.first_name) AND lower(p.last_name) = lower(x.last_name)
   WHERE p.external_id IS DISTINCT FROM x.ext;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the new people already exist under another row — reuse it', n; END IF;

  -- Rows already on the in-scope races: only the two AG nominees and Carothers (or this file's own).
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id AND r.election_id = eid
    JOIN ca0254_expect x ON x.position_name = r.position_name
   WHERE (rc.politician_id IS NULL OR rc.politician_id NOT IN ('9dc798c5-09b7-4d9d-bf8f-e79b0f8c0f74', '2bcbbbd9-2200-482a-b63c-ace4d7ac9b79',
                                   (SELECT carothers_id FROM ca0254_const)))
     AND rc.source NOT LIKE '%added by CA_0254 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unexpected rows already on the in-scope races', n; END IF;

  RAISE NOTICE 'CA_0254 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The ten new people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true,
       'CA_0254 (2026-09-24): ' || k.wec_source, 'manual'
  FROM ca0254_new_pol x CROSS JOIN ca0254_const k
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. The candidacies.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source)
SELECT r.id, COALESCE(c.politician_id, p.id), c.full_name, c.first_name, c.last_name, c.is_incumbent, 'active',
       k.wec_source || '; added by CA_0254 (2026-09-24)'
  FROM ca0254_cand c CROSS JOIN ca0254_const k
  JOIN essentials.races r ON r.election_id = k.election_id AND r.position_name = c.position_name
  LEFT JOIN essentials.politicians p ON p.external_id = c.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND rc.politician_id = COALESCE(c.politician_id, p.id));

-- ---------------------------------------------------------------------------
-- 3. Carothers: on our Governor race, not on WEC's ballot.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result = 'not_nominated',
       result_source = k.wec_source || ' lists two Governor candidates (Tiffany/Varnam, Crowley/Godlewski); '
                       || 'Jamie Jo Carothers is not on the November ballot. Recorded by CA_0254 (2026-09-24)',
       result_recorded_at = now(),
       updated_at = now()
  FROM ca0254_const k, essentials.races r
 WHERE r.id = rc.race_id AND r.election_id = k.election_id AND r.position_name = 'Governor'
   AND rc.politician_id = k.carothers_id
   AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record; k ca0254_const%ROWTYPE;
BEGIN
  SELECT * INTO k FROM ca0254_const;

  -- Every candidacy is on its race, linked, active, with the listed incumbency.
  SELECT count(*) INTO n FROM ca0254_cand c
    JOIN essentials.races ra ON ra.election_id = k.election_id AND ra.position_name = c.position_name
    LEFT JOIN essentials.politicians p ON p.external_id = c.ext
    JOIN essentials.race_candidates rc ON rc.race_id = ra.id AND rc.politician_id = COALESCE(c.politician_id, p.id)
   WHERE rc.candidate_status = 'active' AND rc.result IS NULL AND rc.is_incumbent = c.is_incumbent;
  IF n <> 241 THEN RAISE EXCEPTION 'POST: % of 241 candidacies present', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE source LIKE '%added by CA_0254 (2026-09-24)';
  IF n <> 239 THEN RAISE EXCEPTION 'POST: % rows carry the CA_0254 marker, expected 239', n; END IF;

  -- THE POINT: each of the 121 races carries exactly WEC's field as live candidates.
  FOR r IN
    SELECT x.position_name, x.live,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = ra.id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got
      FROM ca0254_expect x
      JOIN essentials.races ra ON ra.election_id = k.election_id AND ra.position_name = x.position_name
  LOOP
    IF r.got <> r.live THEN RAISE EXCEPTION 'POST: % has % live candidates, expected %', r.position_name, r.got, r.live; END IF;
  END LOOP;
  -- ... and no live candidate on those races is outside WEC's list.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.election_id = k.election_id
    JOIN ca0254_expect x ON x.position_name = ra.position_name
   WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)
     AND NOT EXISTS (SELECT 1 FROM ca0254_cand c LEFT JOIN essentials.politicians p ON p.external_id = c.ext
                      WHERE c.position_name = ra.position_name AND COALESCE(c.politician_id, p.id) = rc.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % live candidates on the in-scope races are not on WEC''s list', n; END IF;

  -- Carothers is closed, not withdrawn.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
   WHERE ra.election_id = k.election_id AND ra.position_name = 'Governor' AND rc.politician_id = k.carothers_id
     AND rc.result = 'not_nominated' AND rc.candidate_status = 'active';
  IF n <> 1 THEN RAISE EXCEPTION 'POST: Carothers row not closed as not_nominated'; END IF;

  -- The new people are non-incumbent, active, and on exactly one race.
  SELECT count(*) INTO n FROM ca0254_new_pol x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 10 THEN RAISE EXCEPTION 'POST: % of 10 new people are active non-incumbents on one race', n; END IF;

  -- Nothing outside scope moved.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
   WHERE ra.election_id = k.election_id AND ra.position_name LIKE 'U.S. Representative%';
  IF n <> k.us_rep_rows THEN RAISE EXCEPTION 'POST: U.S. Representative rows moved (Phase 167 scope)'; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> k.missing_terms THEN RAISE EXCEPTION 'POST: offices_missing_terms moved'; END IF;

  RAISE NOTICE 'CA_0254 applied: 10 new people, 239 new candidacies, 1 closed; 121 WI general rosters match WEC''s November ballot list';
END $$;

COMMIT;

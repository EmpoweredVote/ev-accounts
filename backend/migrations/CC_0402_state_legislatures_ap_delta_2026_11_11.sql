-- CC_0402 - 2026-11-03 state legislatures: record the 51 races the Associated Press has
--           CALLED SINCE CC_0381, and the losers on those same ballots.
--
-- WHY THIS FILE EXISTS. CC_0381 recorded 403 called races from a feed read on 2026-11-08 and
--   deliberately left 70 that AP had not called. Re-reading the same per-state feed on
--   2026-11-11 finds 51 of those 70 now called. This file records exactly those, in the same
--   shape and against the same gates.
--   🔴 THE OTHER 19 STILL GET NO ROW. They are not a backlog and they are not a defect: AZ 1,
--     CA 8, CO 3, UT 3 and WA 4 are all still 'Too Early to Call'. These seats turn over in
--     January; an uncalled race is an honest blank, never a guess.
--     ⚠ Colorado is in that list and in no other: CC_0381 wrote all 9 of its called races and
--       this file writes none, so CO appears in the state table below not at all.
--   🔴 NOT ONE RACE WENT BACK TO UNCALLED, AND NOT ONE CALL CHANGED HANDS. All 473 matched races
--     were re-read and all 809 rows CC_0381 wrote were compared against the new read: zero
--     disagree with the outcome already recorded.
--   🔴 AP STILL REPORTS isCertified = false ON ALL 473, so there is nothing to upgrade from
--     'called' to 'certified' anywhere in this tier. A CALL AND A CANVASS ARE TWO FACTS.
--
-- WHAT IT WRITES: 108 existing candidacies UPDATED across 51 races - 56 won, 52 lost, every one
--   result_certainty = 'called'. No politician, race, office, district or term is created,
--   deleted or re-seated. RECORDING A RESULT SEATS NOBODY: these members take office in January
--   and the post-verify asserts that not one office_terms row moved.
--
--     AZ    5 races   10 won    6 lost
--     CA   13 races   13 won   13 lost
--     UT   10 races   10 won   10 lost
--     WA   23 races   23 won   23 lost
--
--   After this file the tier reads 483 winners across 454 called races, against 1,338 races in
--   the tier and 2,340 in the programme.
--
-- 🔴 PRIOR VALUES, BECAUSE AN UPDATE IS FINAL AND THERE IS NO HISTORY TABLE.
--   46 rows carry NULL in all four columns this file touches.
--   62 rows carry result = 'advanced' with a real state citation in result_source - Arizona's
--      Secretary of State candidate list and Washington's August top-two primary canvass, which
--      in Washington is a TRUE AND LOAD-BEARING FACT: 'advanced' there means the candidate came
--      through the top-two primary onto this November ballot.
--   ▶ Those citations are APPENDED, never overwritten, exactly as CC_0381 and CC_0350 did, and
--     the UPDATE reads the LIVE value rather than this file's copy of it. A gate asserts every
--     one of the 62 survives verbatim.
--   ⚠ No row in this file carries a decided result (won/lost/not_nominated/withdrew/runoff) and
--     none carries any result_certainty; both are gated, so a row another pass reached first
--     stops this file rather than being overwritten by it.
--
-- 🔴🔴 THE NAME MATCH IS THE DANGEROUS STEP, AND THIS FILE DEPARTS FROM CC_0381 IN ONE WAY THAT
--   MATTERS. CC_0381 could write "all 12 relaxed token matches are LOSERS", which bounds what a
--   bad match could cost. 🔴 HERE ALL 3 TOKEN MATCHES ARE WINNERS. A wrong one would hand a
--   seat to the wrong person, so they are not taken on AP's word alone. The four bases:
--     'exact-full-name'     95 rows. Identical once case and punctuation are folded.
--     'exact-first-last'     7 rows. First and last name identical; a middle name or a
--                              second surname differs ("Tyler Andrew Farnsworth" against AP's
--                              "Tyler Farnsworth"). The surname is never relaxed.
--     'holder'               3 rows. AP flags the candidate as that seat's incumbent AND
--                              essentials.office_current_holder independently names the politician
--                              our row links to, for that same office. Two facts, neither a name:
--                              AP's "Nickolas Kupper" against our "Nick Kupper" (AZ House 25),
--                              "Jim Dunnigan" against "James A. Dunnigan" (UT House 36) and
--                              "Norm Thurston" against "Norman K. Thurston" (UT House 62).
--     'first-last-tokens'    3 rows, ALL WINNERS, ALL WASHINGTON, EACH READ AGAINST THE
--                              STATE'S OWN CANVASS - see directly below.
--
-- 🟢 WASHINGTON SETTLES ITS OWN THREE, AND IT SETTLES THEM BY PRINTING OUR SPELLING.
--   The Secretary of State publishes the canvass through the API its public results site reads
--   (results.votewa.gov/results/public/api/elections/washington/20261103/data, read 2026-11-11).
--   It is authoritative for the BALLOT and the COUNT and publishes NO winner flag at all - every
--   isWinner is null across all 173 contests, because a state canvasses and does not call.
--   For each of the three, the state prints the LONGER name - OURS - beside AP's exact count:
--     LD 18 Rep Pos. 1  state "Randi L. Knott"             38,396  = AP "Randi Knott"      38,396
--     LD 26 Rep Pos. 2  state "Renee Hernandez Greenfield" 41,311  = AP "Renee Greenfield" 41,311
--     LD  4 Rep Pos. 1  state "Hillary Q. Pham"            29,663  = AP "Hillary Pham"     29,663
--   ▶ That is the evidence: the short AP string and the long stored string are the same person
--     because a second, independent source carries BOTH the long name and the number.
--   🟢 All 23 Washington races were checked this way, not only the three: in every one, the
--     state's own top-N by vote count is exactly the set this file marks 'won'.
--   ⚠ The two sources disagree on 13 of the 46 Washington COUNTS, by 44 to 113 votes - AP lags
--     the canvass, which is still counting. We store no vote counts, so this changes nothing
--     this file writes; it is why every number quoted in a citation is labelled as AP's.
--
-- 🔴 A TOP-VOTE-GETTER CROSS-CHECK IS THE ONLY GATE THAT CAN CATCH A TRANSPOSED WIN, because
--   every other check reads the outcome column beside the name and a file that has swapped two
--   outcomes agrees with itself perfectly. AP publishes the winner FLAG and the VOTE COUNT as
--   independent fields; the gate requires the rows marked 'won' to be exactly the top 'seats'
--   rows by votes. ⚠ Arizona's House elects TWO members per district: 5 races here carry
--   seats = 2 and two winners each, so a one-winner-per-race gate would be WRONG. The gate
--   compares against races.seats. ⚠ Not one of these races is ranked-choice; the emitter refuses
--   a race AP flags rankedChoice, because a later-round winner need not lead on first
--   preferences. ⚠ Ties are not special-cased: there are none here, and a tie would RAISE.
--
-- 🔴 THIS FILE IS DELIBERATELY NOT IDEMPOTENT, AND SAYS SO RATHER THAN CLAIMING OTHERWISE.
--   A second run is REFUSED by the pre-gate above with 'rows this file writes already carry a
--   decided result'. That is the wanted behaviour: a re-run would append this citation on top
--   of the one it wrote the first time, and there is no history table to undo it with. The
--   refusal is watched, not assumed - control V9 plants a decided row and sees the run stop.
--   ▶ If this file has to be applied again, regenerate it against the live rows first.
--
-- SOURCING. AP's own feed, read 2026-11-11. The call is AP's and is labelled as such in every
--   result_source; result_certainty = 'called' NEVER 'certified'.
--
-- CONTROLS. 10 variants of this exact file were run against production inside BEGIN/ROLLBACK,
--   each tamper asserted PRESENT in the file before the variant ran, each watched going RED:
--   a transposed win (caught only by the top-vote-getter gate, because every other check reads
--   the outcome column beside the name); a name that does not match the pinned row; a moved
--   prior value; the citation append removed; a token match claimed for another state; the
--   holder basis without AP's incumbent flag; a call appearing outside the pinned set; a row
--   already decided; and an emptied occupancy snapshot, which proves the vacuity guard.
--
-- Slot CC_0402 reserved via steward. Applied to production 2026-11-__ by Chris Cantrell.

BEGIN;

-- ─── 1. What was measured ───
CREATE TEMP TABLE called (
  state            text NOT NULL,
  district         text NOT NULL,
  office_title     text NOT NULL,
  race_id          uuid NOT NULL,
  rc_id            uuid PRIMARY KEY,
  seats            int  NOT NULL,
  our_name         text NOT NULL,   -- as our row reads today
  ap_name          text NOT NULL,   -- as AP prints it
  ap_race_id       text NOT NULL,
  ap_candidate_id  text NOT NULL,
  party            text,
  votes            int  NOT NULL,
  pct              numeric NOT NULL,
  outcome          text NOT NULL CHECK (outcome IN ('won', 'lost')),
  match_basis      text NOT NULL CHECK (match_basis IN ('exact-full-name', 'exact-first-last', 'holder', 'first-last-tokens')),
  prior_result     text,            -- the value this row carries BEFORE this file runs
  ap_incumbent     boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO called (state, district, office_title, race_id, rc_id, seats, our_name, ap_name,
                    ap_race_id, ap_candidate_id, party, votes, pct, outcome, match_basis,
                    prior_result, ap_incumbent) VALUES
  ('az', 'State House District 14', 'State Representative', '245de781-b526-4c21-88d5-aa733e065a87'::uuid, 'cb3c0ee8-e6c2-4436-a81e-ea81d572936f'::uuid, 2, 'Mary Rose', 'Mary Rose', '20261103AZ3113', '175014', 'Dem', 46648, 34.33, 'won', 'exact-full-name', 'advanced', false),
  ('az', 'State House District 14', 'State Representative', '245de781-b526-4c21-88d5-aa733e065a87'::uuid, 'a170ab53-9f93-49e4-9667-5a3960cbcfde'::uuid, 2, 'Tyler Andrew Farnsworth', 'Tyler Farnsworth', '20261103AZ3113', '175015', 'GOP', 45430, 33.43, 'won', 'exact-first-last', 'advanced', false),
  ('az', 'State House District 14', 'State Representative', '245de781-b526-4c21-88d5-aa733e065a87'::uuid, '9aae028c-a0df-4670-a739-4c07a0725c9c'::uuid, 2, 'Laurin Hendrix', 'Laurin Hendrix', '20261103AZ3113', '102037', 'GOP', 43817, 32.24, 'lost', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 16', 'State Representative', 'add81a51-46b7-4241-b3fc-bd5ae66cf0bc'::uuid, 'a1a5304b-1dd3-46a6-b888-ce2d6de5d6e0'::uuid, 2, 'Julia Romero Gusse', 'Julia Gusse', '20261103AZ3117', '175017', 'Dem', 42927, 37.18, 'won', 'exact-first-last', 'advanced', false),
  ('az', 'State House District 16', 'State Representative', 'add81a51-46b7-4241-b3fc-bd5ae66cf0bc'::uuid, '905c424f-9289-45b7-a2ab-918ae84832a8'::uuid, 2, 'Teresa Martinez', 'Teresa Martinez', '20261103AZ3117', '102041', 'GOP', 37259, 32.27, 'won', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 16', 'State Representative', 'add81a51-46b7-4241-b3fc-bd5ae66cf0bc'::uuid, '5f7a48b3-6071-430d-963a-b40dc4db5fd6'::uuid, 2, 'Chris Lopez', 'Chris Lopez', '20261103AZ3117', '165103', 'GOP', 35276, 30.55, 'lost', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 25', 'State Representative', 'b1f476f9-c8b7-4c14-8e6d-e01d4679b95b'::uuid, 'bbc00082-80dd-4845-93ca-4d75ccda8cea'::uuid, 2, 'Michael Carbone', 'Michael Carbone', '20261103AZ3135', '102080', 'GOP', 45060, 35.39, 'won', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 25', 'State Representative', 'b1f476f9-c8b7-4c14-8e6d-e01d4679b95b'::uuid, 'e30da201-1801-4490-9986-198bc3dd3c9d'::uuid, 2, 'Nick Kupper', 'Nickolas Kupper', '20261103AZ3135', '165120', 'GOP', 42361, 33.27, 'won', 'holder', 'advanced', true),
  ('az', 'State House District 25', 'State Representative', 'b1f476f9-c8b7-4c14-8e6d-e01d4679b95b'::uuid, '42d90216-68f2-4a3e-b055-2d8c24ffd9e8'::uuid, 2, 'Tiffany Byrne', 'Tiffany Byrne', '20261103AZ3135', '175036', 'Dem', 39918, 31.35, 'lost', 'exact-full-name', 'advanced', false),
  ('az', 'State House District 29', 'State Representative', '62a59e3e-bfdd-4d38-a174-771203c87d15'::uuid, 'ad4e22c7-5816-48f6-bd78-8ea1ffb2fba4'::uuid, 2, 'Christine Marie Scianna', 'Christine Scianna', '20261103AZ3143', '175040', 'Dem', 44607, 34.24, 'won', 'exact-first-last', 'advanced', false),
  ('az', 'State House District 29', 'State Representative', '62a59e3e-bfdd-4d38-a174-771203c87d15'::uuid, 'fe10b170-cc1d-432d-b653-4c699f8c1b6e'::uuid, 2, 'Steve Montenegro', 'Steve Montenegro', '20261103AZ3143', '66087', 'GOP', 43531, 33.42, 'won', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 29', 'State Representative', '62a59e3e-bfdd-4d38-a174-771203c87d15'::uuid, 'ed0e370a-ece8-4c3a-b36d-12c3a2a8c39c'::uuid, 2, 'James Taylor', 'James Taylor', '20261103AZ3143', '165130', 'GOP', 42126, 32.34, 'lost', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 4', 'State Representative', 'c3851239-2681-4ab4-8e44-f974db129def'::uuid, '1ac25402-122d-46c5-9f95-c1aa486e1027'::uuid, 2, 'Tammy Caputi', 'Tammy Caputi', '20261103AZ3093', '101729', 'Dem', 58504, 26.31, 'won', 'exact-full-name', 'advanced', false),
  ('az', 'State House District 4', 'State Representative', 'c3851239-2681-4ab4-8e44-f974db129def'::uuid, '32ac9f4d-5a19-40a0-b07b-13bd30693efe'::uuid, 2, 'Karen Gresham', 'Karen Gresham', '20261103AZ3093', '165070', 'Dem', 58247, 26.19, 'won', 'exact-full-name', 'advanced', false),
  ('az', 'State House District 4', 'State Representative', 'c3851239-2681-4ab4-8e44-f974db129def'::uuid, '36025986-7e97-4697-beed-c9a5b35fec6c'::uuid, 2, 'Matt Gress', 'Matt Gress', '20261103AZ3093', '102012', 'GOP', 54987, 24.73, 'lost', 'exact-full-name', 'advanced', true),
  ('az', 'State House District 4', 'State Representative', 'c3851239-2681-4ab4-8e44-f974db129def'::uuid, '9d61f494-fa61-43d4-8f2f-c070312086b7'::uuid, 2, 'Pamela Carter', 'Pamela Carter', '20261103AZ3093', '165071', 'GOP', 50625, 22.77, 'lost', 'exact-full-name', 'advanced', true),
  ('ca', 'Assembly District 12', 'Assembly Member', '8448ebd6-4c91-40ef-a621-15c68aa822f7'::uuid, '10ae24f4-ce49-4fee-bba6-f6e321252207'::uuid, 1, 'Jackie Elward', 'Jackie Elward', '20261103CA5772', '161137', 'Dem', 76646, 56.12, 'won', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 12', 'Assembly Member', '8448ebd6-4c91-40ef-a621-15c68aa822f7'::uuid, 'a67ed82b-5103-4109-8df1-c47624b0dfb9'::uuid, 1, 'Eric Lucan', 'Eric Lucan', '20261103CA5772', '172705', 'Dem', 59930, 43.88, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 3', 'Assembly Member', 'bb1fb812-4881-4483-a1d9-7076df63f8e4'::uuid, '0918af60-b7ec-4677-bb9c-cd4a8f4de531'::uuid, 1, 'Dom Belza', 'Dom Belza', '20261103CA5764', '172694', 'GOP', 72221, 56.23, 'won', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 3', 'Assembly Member', 'bb1fb812-4881-4483-a1d9-7076df63f8e4'::uuid, '0f9262d5-4ca9-4f83-bf1c-a79dc462dba6'::uuid, 1, 'James "Jamie" Johansson', 'James Johansson', '20261103CA5764', '172695', 'GOP', 56215, 43.77, 'lost', 'exact-first-last', NULL, false),
  ('ca', 'Assembly District 34', 'Assembly Member', 'e498dcbe-1426-4eb6-b43a-4ab6635cf974'::uuid, '44e8db66-59dc-48f9-9e2a-80dc19fcdc94'::uuid, 1, 'Charles Frederick Hughes', 'Charles Hughes', '20261103CA5797', '172734', 'GOP', 78627, 52.5, 'won', 'exact-first-last', NULL, false),
  ('ca', 'Assembly District 34', 'Assembly Member', 'e498dcbe-1426-4eb6-b43a-4ab6635cf974'::uuid, 'f680b87a-5dd5-480b-b13b-419b04e79271'::uuid, 1, 'Randall Putz', 'Randall Putz', '20261103CA5797', '172732', 'Dem', 71139, 47.5, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 42', 'Assembly Member', '89e56ea0-980a-41bf-a125-0482537db7aa'::uuid, 'c0ebc8be-2514-4f72-a22c-64466b57546c'::uuid, 1, 'Deborah Klein Lopez', 'Deborah Klein Lopez', '20261103CA5805', '172743', 'Dem', 103143, 56.48, 'won', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 42', 'Assembly Member', '89e56ea0-980a-41bf-a125-0482537db7aa'::uuid, 'd9a7baa0-5627-4140-8212-c36d1bb8e427'::uuid, 1, 'Ted Nordblum', 'Ted Nordblum', '20261103CA5805', '106987', 'GOP', 79469, 43.52, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 47', 'Assembly Member', 'b4c8ebef-7910-4b3e-8aec-17476105b0ec'::uuid, '132e7c82-7e81-4d59-8d37-6b7307d0f4d0'::uuid, 1, 'Leila Namvar', 'Leila Namvar', '20261103CA5810', '172749', 'Dem', 92315, 55.23, 'won', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 47', 'Assembly Member', 'b4c8ebef-7910-4b3e-8aec-17476105b0ec'::uuid, '624bb8de-35e2-43e0-bc6d-48ee70e8149b'::uuid, 1, 'Greg Wallis', 'Greg Wallis', '20261103CA5810', '107004', 'GOP', 74837, 44.77, 'lost', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 63', 'Assembly Member', '6da96a35-f5f2-4fe1-a3c2-ad2afa294870'::uuid, '8f0191e1-b320-48f6-aec1-d3a7179e042e'::uuid, 1, 'Natasha Johnson', 'Natasha Johnson', '20261103CA5825', '172763', 'GOP', 66667, 56.93, 'won', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 63', 'Assembly Member', '6da96a35-f5f2-4fe1-a3c2-ad2afa294870'::uuid, 'd347a923-21b9-4ec5-8f50-bfde888da041'::uuid, 1, 'Kevin Akin', 'Kevin Akin', '20261103CA5825', '106009', 'PFP', 50428, 43.07, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 70', 'Assembly Member', '5e00a153-651b-4a6b-8ffe-e5ef35aea0e6'::uuid, '5ae181a0-bdf7-417d-9c11-4993697b7a77'::uuid, 1, 'Paula Swift', 'Paula Swift', '20261103CA5832', '172780', 'Dem', 76062, 51.79, 'won', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 70', 'Assembly Member', '5e00a153-651b-4a6b-8ffe-e5ef35aea0e6'::uuid, '1dba1f15-f376-4fb8-bb5d-23853580aa4b'::uuid, 1, 'Tri Ta', 'Tri Ta', '20261103CA5832', '107129', 'GOP', 70808, 48.21, 'lost', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 71', 'Assembly Member', 'e97ae0ed-5898-46f1-8054-16658a518c02'::uuid, '5a063383-4fa9-4e08-b5c3-1a448f583184'::uuid, 1, 'Kate Sanchez', 'Kate Sanchez', '20261103CA5833', '107140', 'GOP', 88724, 53.66, 'won', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 71', 'Assembly Member', 'e97ae0ed-5898-46f1-8054-16658a518c02'::uuid, '0e1c3116-bcc6-4890-82b8-a331fb6cf855'::uuid, 1, 'JJ Galvez', 'JJ Galvez', '20261103CA5833', '172781', 'Dem', 76618, 46.34, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'Assembly District 75', 'Assembly Member', '379babf2-e341-4872-873d-b43a31a355d0'::uuid, '30d6b100-a0fa-4149-b68a-c97d0bfabf28'::uuid, 1, 'Carl DeMaio', 'Carl DeMaio', '20261103CA5837', '63709', 'GOP', 102896, 54.93, 'won', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 75', 'Assembly Member', '379babf2-e341-4872-873d-b43a31a355d0'::uuid, 'd40568a1-07e2-4a5c-81a1-fbbe3a19f4f9'::uuid, 1, 'Gerald C. Boursiquot', 'Gerald Boursiquot', '20261103CA5837', '172787', 'Dem', 84418, 45.07, 'lost', 'exact-first-last', NULL, false),
  ('ca', 'Assembly District 9', 'Assembly Member', '97630297-215d-4c34-bea1-2cc2b4238971'::uuid, '4c90bcd6-a27a-41d5-844d-304e29e2810c'::uuid, 1, 'Heath Flora', 'Heath Flora', '20261103CA5770', '105813', 'GOP', 85808, 56.52, 'won', 'exact-full-name', NULL, true),
  ('ca', 'Assembly District 9', 'Assembly Member', '97630297-215d-4c34-bea1-2cc2b4238971'::uuid, '49db0261-e187-4075-b4f0-d34ceb787d67'::uuid, 1, 'Matthew Adams', 'Matthew Adams', '20261103CA5770', '172702', 'Dem', 66013, 43.48, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'State Senate District 26', 'Senator', 'df4e7eb5-144f-4616-978d-33ca222f571e'::uuid, 'c7a5fca4-3c81-4f63-98ec-0ffe9038e972'::uuid, 1, 'Sara Hernandez', 'Sara Hernandez', '20261103CA5859', '65842', 'Dem', 128046, 53.14, 'won', 'exact-full-name', NULL, false),
  ('ca', 'State Senate District 26', 'Senator', 'df4e7eb5-144f-4616-978d-33ca222f571e'::uuid, '3eb0a96f-c301-404e-9084-679308b5eedc'::uuid, 1, 'Sarah Rascón', 'Sarah Rascón', '20261103CA5859', '172683', 'Dem', 112901, 46.86, 'lost', 'exact-full-name', NULL, false),
  ('ca', 'California State Senate district 36', 'Senator', '215dcce6-87e7-4fe8-af5f-8ef901d3d817'::uuid, 'b2ec1902-a2a8-4c10-9c36-6df795c434db'::uuid, 1, 'Chris Duncan', 'Chris Duncan', '20261103CA5864', '106501', 'Dem', 194668, 51.41, 'won', 'exact-full-name', NULL, false),
  ('ca', 'California State Senate district 36', 'Senator', '215dcce6-87e7-4fe8-af5f-8ef901d3d817'::uuid, '8462ca42-1f49-4349-b5d7-c729038cf914'::uuid, 1, 'Tony Strickland', 'Tony Strickland', '20261103CA5864', '52566', 'GOP', 184019, 48.59, 'lost', 'exact-full-name', NULL, true),
  ('ca', 'State Senate District 40', 'Senator', 'b6fb8bc6-a065-4a94-8e47-7aed5512b901'::uuid, 'f10bd7e9-2bc9-4773-98f5-447975e8d92a'::uuid, 1, 'Mara Elliott', 'Mara Elliott', '20261103CA6485', '172691', 'Dem', 189429, 54.09, 'won', 'exact-full-name', NULL, false),
  ('ca', 'State Senate District 40', 'Senator', 'b6fb8bc6-a065-4a94-8e47-7aed5512b901'::uuid, 'a919aab0-5273-415a-b34b-9e17743ae48d'::uuid, 1, 'Kristie Bruce-Lane', 'Kristie Bruce-Lane', '20261103CA6485', '107146', 'GOP', 160790, 45.91, 'lost', 'exact-full-name', NULL, false),
  ('ut', 'State House District 36', 'State Representative District 36', 'b8fa1cbc-679e-47ec-a2b3-fa1c10df59b3'::uuid, 'fdbfc055-57f0-475a-8fee-14aa183daa5b'::uuid, 1, 'Blake Townsend', 'Blake Townsend', '20261103UT45731', '179149', 'Dem', 7502, 53.3, 'won', 'exact-full-name', NULL, false),
  ('ut', 'State House District 36', 'State Representative District 36', 'b8fa1cbc-679e-47ec-a2b3-fa1c10df59b3'::uuid, '992f84f5-fe7a-4c85-a286-cc42281bf231'::uuid, 1, 'James A. Dunnigan', 'Jim Dunnigan', '20261103UT45731', '58501', 'GOP', 6574, 46.7, 'lost', 'holder', NULL, true),
  ('ut', 'State House District 42', 'State Representative District 42', 'ebdf314c-dde3-466f-a07e-05da23ab8250'::uuid, 'c318b39e-93f4-4da1-afeb-4cdc4deaedf9'::uuid, 1, 'Iva Williams', 'Iva Williams', '20261103UT45737', '174465', 'Dem', 10623, 53.44, 'won', 'exact-full-name', NULL, false),
  ('ut', 'State House District 42', 'State Representative District 42', 'ebdf314c-dde3-466f-a07e-05da23ab8250'::uuid, 'e3097238-b34f-4c89-ac4e-e95deaa006dc'::uuid, 1, 'Clint Okerlund', 'Clint Okerlund', '20261103UT45737', '164552', 'GOP', 9256, 46.56, 'lost', 'exact-full-name', NULL, true),
  ('ut', 'State House District 44', 'State Representative District 44', '1f105654-c0cd-418f-8ac1-7b9eef9dfbe0'::uuid, '1a7c2fb7-c6ad-4975-bfaa-07b26ed42100'::uuid, 1, 'Jess Birtcher', 'Jess Birtcher', '20261103UT45739', '174466', 'Dem', 8447, 52.62, 'won', 'exact-full-name', NULL, false),
  ('ut', 'State House District 44', 'State Representative District 44', '1f105654-c0cd-418f-8ac1-7b9eef9dfbe0'::uuid, 'fda550a1-2f2e-4079-8899-fa7f7137b270'::uuid, 1, 'Jordan Teuscher', 'Jordan Teuscher', '20261103UT45739', '151154', 'GOP', 7607, 47.38, 'lost', 'exact-full-name', NULL, true),
  ('ut', 'State House District 45', 'State Representative District 45', 'b2efd418-4434-4530-86c2-315c9b11602f'::uuid, '61bb3ee8-5618-4306-bfa2-bab17d8c352d'::uuid, 1, 'Tracy Miller', 'Tracy Miller', '20261103UT45740', '164556', 'GOP', 8234, 54.22, 'won', 'exact-full-name', NULL, true),
  ('ut', 'State House District 45', 'State Representative District 45', 'b2efd418-4434-4530-86c2-315c9b11602f'::uuid, '103196b8-6e62-4634-9c18-7dd23b38dd54'::uuid, 1, 'Rod Moser', 'Rod Moser', '20261103UT45740', '174468', 'Dem', 6951, 45.78, 'lost', 'exact-full-name', NULL, false),
  ('ut', 'State House District 51', 'State Representative District 51', '17a2d98c-8b78-4337-8344-a4a958a0e104'::uuid, '0256bf9c-8615-4e91-8601-f317b503d697'::uuid, 1, 'Leah Hansen', 'Leah Hansen', '20261103UT45747', '174475', 'GOP', 8485, 56.54, 'won', 'exact-full-name', NULL, true),
  ('ut', 'State House District 51', 'State Representative District 51', '17a2d98c-8b78-4337-8344-a4a958a0e104'::uuid, '936aa7bd-20d4-4a01-a023-1d2299d8979c'::uuid, 1, 'Brett Nielsen', 'Brett Nielsen', '20261103UT45747', '174474', 'Dem', 6521, 43.46, 'lost', 'exact-full-name', NULL, false),
  ('ut', 'State House District 52', 'State Representative District 52', '61aee2ab-8582-4d44-96cb-7c8d6235764e'::uuid, '5453520e-b1ff-4734-98ee-8d002e4b166b'::uuid, 1, 'Cory Maloy', 'Cory Maloy', '20261103UT45748', '150534', 'GOP', 7269, 55.07, 'won', 'exact-full-name', NULL, true),
  ('ut', 'State House District 52', 'State Representative District 52', '61aee2ab-8582-4d44-96cb-7c8d6235764e'::uuid, 'fa08c598-74c0-4228-a4a2-fa35ac6a490f'::uuid, 1, 'Nicole Melling', 'Nicole Melling', '20261103UT45748', '174476', 'Dem', 5775, 43.75, 'lost', 'exact-full-name', NULL, false),
  ('ut', 'State House District 56', 'State Representative District 56', 'f5155ed5-4e9f-45f1-90a3-d6d3c4b78386'::uuid, '86eb3f3e-ff57-4389-bc72-20772c08da69'::uuid, 1, 'Val L. Peterson', 'Val Peterson', '20261103UT45753', '149487', 'GOP', 5669, 57.05, 'won', 'exact-first-last', NULL, true),
  ('ut', 'State House District 56', 'State Representative District 56', 'f5155ed5-4e9f-45f1-90a3-d6d3c4b78386'::uuid, '3de77163-f1a8-4a6c-947f-95e4a8a91781'::uuid, 1, 'Natassja Grossman', 'Natassja Grossman', '20261103UT45753', '174480', 'Dem', 4268, 42.95, 'lost', 'exact-full-name', NULL, false),
  ('ut', 'State House District 62', 'State Representative District 62', 'c82dd59c-c304-481f-a084-44c435a6c5d7'::uuid, 'ed49757a-a57f-4d4b-95f8-0beda83f42e4'::uuid, 1, 'David Chappell', 'David Chappell', '20261103UT45759', '174487', 'Dem', 5156, 53.22, 'won', 'exact-full-name', NULL, false),
  ('ut', 'State House District 62', 'State Representative District 62', 'c82dd59c-c304-481f-a084-44c435a6c5d7'::uuid, '27dffe1b-5d07-44fc-800b-2cfc2a81ed6f'::uuid, 1, 'Norman K. Thurston', 'Norm Thurston', '20261103UT45759', '150313', 'GOP', 4532, 46.78, 'lost', 'holder', NULL, true),
  ('ut', 'State Senate District 19', 'State Senator District 19', '628bf1e7-f5c3-49fa-805e-22d5815fa392'::uuid, '405f2bfb-6c18-447d-a909-701f59630c6d'::uuid, 1, 'Shana Anderson', 'Shana Anderson', '20261103UT45688', '174393', 'Dem', 24318, 53.83, 'won', 'exact-full-name', NULL, false),
  ('ut', 'State Senate District 19', 'State Senator District 19', '628bf1e7-f5c3-49fa-805e-22d5815fa392'::uuid, 'da883043-d439-4894-9b41-67083d33b340'::uuid, 1, 'Kirk Cullimore', 'Kirk Cullimore', '20261103UT45688', '150729', 'GOP', 20856, 46.17, 'lost', 'exact-full-name', NULL, true),
  ('ut', 'State Senate District 23', 'State Senator District 23', 'b9712bd9-95b1-4fd7-abce-62fcef6c81ce'::uuid, '7159f8d9-2301-42a2-96f9-6be3a1816256'::uuid, 1, 'Keith Grover', 'Keith Grover', '20261103UT47189', '148747', 'GOP', 15023, 55.14, 'won', 'exact-full-name', NULL, true),
  ('ut', 'State Senate District 23', 'State Senator District 23', 'b9712bd9-95b1-4fd7-abce-62fcef6c81ce'::uuid, 'ff34a0c2-daef-4cc6-9a1b-307c8f476001'::uuid, 1, 'Tucker Smith', 'Tucker Smith', '20261103UT47189', '174396', 'Dem', 12223, 44.86, 'lost', 'exact-full-name', NULL, false),
  ('wa', 'Legislative (House) District 13', 'State Representative (Position 2)', 'fc710b5c-7ae4-4be7-8b98-5d8a512f7a79'::uuid, 'b028846b-cd88-4642-ba87-7699f84c1140'::uuid, 1, 'Joshua Thompson', 'Joshua Thompson', '20261103WA48179', '176643', 'GOP', 22392, 52.73, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 13', 'State Representative (Position 2)', 'fc710b5c-7ae4-4be7-8b98-5d8a512f7a79'::uuid, 'c0f0259f-b0ba-48b5-a0b5-733690203ace'::uuid, 1, 'Deanna Martinez', 'Deanna Martinez', '20261103WA48179', '176642', 'GOP', 19117, 45.02, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 14', 'State Representative (Position 1)', '83e45b20-b3bb-4338-9c1f-3a7b7db9b9b7'::uuid, 'ace2ac3c-46d9-4a64-8ad8-cf9e3e108ed1'::uuid, 1, 'Chelsea Dimas', 'Chelsea Dimas', '20261103WA48181', '166176', 'Dem', 16090, 57.15, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 14', 'State Representative (Position 1)', '83e45b20-b3bb-4338-9c1f-3a7b7db9b9b7'::uuid, '0855039d-8aed-4262-9975-b3b9e3e323b9'::uuid, 1, 'Gloria Mendoza', 'Gloria Mendoza', '20261103WA48181', '166177', 'GOP', 11957, 42.47, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 14', 'State Representative (Position 2)', 'bb00f65a-8c98-49f6-a8e0-306f543bf51f'::uuid, '5cc6ef63-5d8d-4e9c-bb33-ee54b8d8df94'::uuid, 1, 'Ezequiel Morfin', 'Ezequiel Morfin', '20261103WA48183', '176646', 'Dem', 16385, 57.86, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 14', 'State Representative (Position 2)', 'bb00f65a-8c98-49f6-a8e0-306f543bf51f'::uuid, '7874186d-5cb6-40d6-b17a-9b71358921b3'::uuid, 1, 'Deb Manjarrez', 'Deb Manjarrez', '20261103WA48183', '166180', 'GOP', 11804, 41.69, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 16', 'State Representative (Position 1)', '53ca353b-7d01-4940-9df3-8b986b2334ed'::uuid, 'b44fa5ed-0a81-4df7-b4d8-7f2c468dff6a'::uuid, 1, 'Mark Klicker', 'Mark Klicker', '20261103WA48189', '153495', 'GOP', 27919, 57.69, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 16', 'State Representative (Position 1)', '53ca353b-7d01-4940-9df3-8b986b2334ed'::uuid, '42b5bf27-7374-441d-aed3-a7dc89507604'::uuid, 1, 'Kyle Palmer', 'Kyle Palmer', '20261103WA48189', '176713', 'Dem', 20438, 42.23, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 16', 'State Representative (Position 2)', 'cb91b985-c4d3-4cc3-8242-7db229d34c44'::uuid, '691653a7-2a48-41c0-b414-ebf4e89c51d5'::uuid, 1, 'Skyler Rude', 'Skyler Rude', '20261103WA48191', '152105', 'GOP', 26260, 54.41, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 16', 'State Representative (Position 2)', 'cb91b985-c4d3-4cc3-8242-7db229d34c44'::uuid, '0cc18588-c200-461d-ad58-a491cce1088f'::uuid, 1, 'Derek Sarley', 'Derek Sarley', '20261103WA48191', '176714', 'Dem', 21949, 45.48, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 18', 'State Representative (Position 1)', '1e081e4c-798f-4951-b573-f086db5fd9d2'::uuid, 'e356ee14-7474-4c60-a72d-5aeae50d8e57'::uuid, 1, 'Randi L. Knott', 'Randi Knott', '20261103WA48197', '176723', 'Dem', 38396, 52.36, 'won', 'first-last-tokens', 'advanced', false),
  ('wa', 'Legislative (House) District 18', 'State Representative (Position 1)', '1e081e4c-798f-4951-b573-f086db5fd9d2'::uuid, 'c8b587a8-9434-4c9b-9f97-4deab903094b'::uuid, 1, 'Stephanie McClintock', 'Stephanie McClintock', '20261103WA48197', '154475', 'GOP', 34816, 47.47, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 24', 'State Representative (Position 2)', '1174d142-82d8-4c08-a7a0-c0b78696cae4'::uuid, '422ca576-22ef-40a0-80af-dd0b0e437259'::uuid, 1, 'Kaylee Kuehn', 'Kaylee Kuehn', '20261103WA48223', '176736', 'Dem', 38593, 55.79, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 24', 'State Representative (Position 2)', '1174d142-82d8-4c08-a7a0-c0b78696cae4'::uuid, '2eea7a70-c108-4311-b538-a567723c1b72'::uuid, 1, 'Marcia Kelbon', 'Marcia Kelbon', '20261103WA48223', '166114', 'NPP', 30422, 43.98, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 25', 'State Representative (Position 1)', 'b33b874c-a5f5-42cd-ba36-1c79113ba8fe'::uuid, '0bb1437d-a7a0-4957-b246-cf7f94913ced'::uuid, 1, 'David Berg', 'David Berg', '20261103WA48225', '176739', 'Dem', 28851, 50.76, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 25', 'State Representative (Position 1)', 'b33b874c-a5f5-42cd-ba36-1c79113ba8fe'::uuid, 'ae34b7e0-36a1-441c-8056-3d9067582206'::uuid, 1, 'Michael Keaton', 'Michael Keaton', '20261103WA48225', '166415', 'GOP', 27951, 49.17, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 26', 'State Representative (Position 2)', '5081726a-0517-477c-a9a9-80b6c83bb002'::uuid, 'aa8dae18-7a1f-4f1b-83e8-383ef66db8af'::uuid, 1, 'Renee Hernandez Greenfield', 'Renee Greenfield', '20261103WA48231', '176748', 'Dem', 41311, 53.38, 'won', 'first-last-tokens', 'advanced', false),
  ('wa', 'Legislative (House) District 26', 'State Representative (Position 2)', '5081726a-0517-477c-a9a9-80b6c83bb002'::uuid, 'b2752638-1223-4445-94ea-420ac57ef0df'::uuid, 1, 'Katy Cornell', 'Katy Cornell', '20261103WA48231', '176749', 'GOP', 35947, 46.45, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 29', 'State Representative (Position 1)', 'c4b57c70-4d6f-44c7-a139-f2f4bfc8265b'::uuid, '3ee34273-86cf-4831-bcdb-58106ebfd177'::uuid, 1, 'Krista Perez', 'Krista Perez', '20261103WA48241', '176752', 'Dem', 17570, 49.75, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 29', 'State Representative (Position 1)', 'c4b57c70-4d6f-44c7-a139-f2f4bfc8265b'::uuid, 'ecb532b6-596f-4bd7-bf04-33face611ea3'::uuid, 1, 'Melanie Morgan', 'Melanie Morgan', '20261103WA48241', '152786', 'Dem', 16269, 46.07, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 29', 'State Representative (Position 2)', 'c8253727-c0ea-446c-a0b4-c3ba6388cfe2'::uuid, 'acda8178-7658-4bef-a0ac-c9c5bc5b6126'::uuid, 1, 'Patrick Stickney', 'Patrick Stickney', '20261103WA48243', '176754', 'Dem', 16876, 48.6, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 29', 'State Representative (Position 2)', 'c8253727-c0ea-446c-a0b4-c3ba6388cfe2'::uuid, 'a28106ab-c26d-444e-ba86-f728e803a359'::uuid, 1, 'Joe Bushnell', 'Joe Bushnell', '20261103WA48243', '177353', 'Dem', 16331, 47.03, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 32', 'State Representative (Position 1)', 'ed8e85e4-8953-4b8b-87e6-4156d99055d5'::uuid, '9d582c9e-fe35-4eb4-be64-40a034500c37'::uuid, 1, 'Danica Noble', 'Danica Noble', '20261103WA48253', '176898', 'Dem', 31482, 50.74, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 32', 'State Representative (Position 1)', 'ed8e85e4-8953-4b8b-87e6-4156d99055d5'::uuid, '6865b774-6447-411c-845d-870494506932'::uuid, 1, 'Keith Scully', 'Keith Scully', '20261103WA48253', '176897', 'Dem', 29503, 47.55, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 35', 'State Representative (Position 1)', 'e084fe94-58b1-4a2a-afa8-c0087e020ac3'::uuid, '6fd2b53a-59b9-4546-9bae-8a5c351bafeb'::uuid, 1, 'Dan Griffey', 'Dan Griffey', '20261103WA48265', '150964', 'GOP', 39692, 52.47, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 35', 'State Representative (Position 1)', 'e084fe94-58b1-4a2a-afa8-c0087e020ac3'::uuid, '0c19d244-c862-4ae3-8d16-4067f2583398'::uuid, 1, 'Jim Pierson', 'Jim Pierson', '20261103WA48265', '176911', 'Dem', 35858, 47.4, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 35', 'State Representative (Position 2)', 'c7c5720d-9682-4878-b852-169ba8831747'::uuid, '3de8139a-ac96-4786-a392-55edb0dbe69e'::uuid, 1, 'Travis Couture', 'Travis Couture', '20261103WA48267', '151836', 'GOP', 39508, 52.23, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 35', 'State Representative (Position 2)', 'c7c5720d-9682-4878-b852-169ba8831747'::uuid, 'af8c4329-a3cb-4a6b-9875-4d3f4aa96854'::uuid, 1, 'Maria Littlesun', 'Maria Littlesun', '20261103WA48267', '176913', 'Dem', 36037, 47.64, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 39', 'State Representative (Position 2)', '452429f2-8d1c-44ea-9e1e-68f88b8d5265'::uuid, '92c7382b-89a1-4aeb-b9a4-0c1b99ac27ed'::uuid, 1, 'Steve Ewing', 'Steve Ewing', '20261103WA48283', '176924', 'GOP', 34164, 52.19, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 39', 'State Representative (Position 2)', '452429f2-8d1c-44ea-9e1e-68f88b8d5265'::uuid, 'd816af12-f377-4565-9a46-3f2b18cddfd4'::uuid, 1, 'Ida Keeley', 'Ida Keeley', '20261103WA48283', '176923', 'Dem', 31221, 47.69, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 4', 'State Representative (Position 1)', 'c24f8e8d-8d89-4dc6-b698-7a4f90d54c4b'::uuid, '1944aa90-b747-44b5-aa94-5a3bbc58246f'::uuid, 1, 'Hillary Q. Pham', 'Hillary Pham', '20261103WA48141', '176540', 'GOP', 29663, 49.38, 'won', 'first-last-tokens', 'advanced', false),
  ('wa', 'Legislative (House) District 4', 'State Representative (Position 1)', 'c24f8e8d-8d89-4dc6-b698-7a4f90d54c4b'::uuid, '6a552b7b-4b06-462f-bcda-bc67fba8c8e0'::uuid, 1, 'Trent Maier', 'Trent Maier', '20261103WA48141', '176539', 'GOP', 26442, 44.02, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 48', 'State Representative (Position 2)', 'c9051f29-b9f9-4da9-96b5-fa815495fb35'::uuid, 'c2d17dcd-4602-49c3-833c-7c5953d5ce01'::uuid, 1, 'Jessica Forsythe', 'Jessica Forsythe', '20261103WA48319', '176965', 'Dem', 22531, 52.46, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 48', 'State Representative (Position 2)', 'c9051f29-b9f9-4da9-96b5-fa815495fb35'::uuid, '074133b1-7d71-4d7f-8395-afcceacdcdda'::uuid, 1, 'Amy Walen', 'Amy Walen', '20261103WA48319', '152936', 'Dem', 19802, 46.1, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 5', 'State Representative (Position 1)', 'ec3f4915-92fc-42d8-bc27-0e242c8520ba'::uuid, 'f2c8edf5-b537-45f4-9206-9af55f8aab52'::uuid, 1, 'Zach Hall', 'Zach Hall', '20261103WA48145', '176546', 'Dem', 40559, 56.45, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 5', 'State Representative (Position 1)', 'ec3f4915-92fc-42d8-bc27-0e242c8520ba'::uuid, 'b3dc6d88-49a0-4f26-abd8-d9b43d5a24e7'::uuid, 1, 'Michelle Bennett', 'Michelle Bennett', '20261103WA48145', '176548', 'GOP', 31209, 43.43, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 5', 'State Representative (Position 2)', '31402a43-30b8-4c11-b48e-8185150281bc'::uuid, 'ca2885cc-e37f-491f-83f3-7b7ae6631085'::uuid, 1, 'Lisa Callan', 'Lisa Callan', '20261103WA48147', '152954', 'Dem', 41705, 58.27, 'won', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (House) District 5', 'State Representative (Position 2)', '31402a43-30b8-4c11-b48e-8185150281bc'::uuid, 'fa89eacc-f435-4013-9677-d85a666d6ff2'::uuid, 1, 'Patrick Peacock', 'Patrick Peacock', '20261103WA48147', '166137', 'GOP', 29777, 41.6, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 6', 'State Representative (Position 1)', '0b906e0b-01e3-46f2-a276-44b8dc5b7e91'::uuid, '2bb5e31f-7b58-4293-90ad-ec44f21c5a1f'::uuid, 1, 'Alan Nolan', 'Alan Nolan', '20261103WA48149', '176553', 'GOP', 33953, 53.64, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 6', 'State Representative (Position 1)', '0b906e0b-01e3-46f2-a276-44b8dc5b7e91'::uuid, '788e1108-9937-43fb-b632-e1315141bb7e'::uuid, 1, 'Michaela Kelso', 'Michaela Kelso', '20261103WA48149', '154461', 'Dem', 29219, 46.16, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 6', 'State Representative (Position 2)', '908029ca-b579-4fa9-ad27-da8c98863e66'::uuid, 'cc1503b9-8c4e-497e-8d7f-dfa34d23d3e1'::uuid, 1, 'Jonathan Bingle', 'Jonathan Bingle', '20261103WA48151', '165727', 'GOP', 35863, 56.64, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (House) District 6', 'State Representative (Position 2)', '908029ca-b579-4fa9-ad27-da8c98863e66'::uuid, 'd8396e38-7c1d-48d0-aa17-7faaf31979c1'::uuid, 1, 'Julia Payne', 'Julia Payne', '20261103WA48151', '176554', 'Dem', 27329, 43.16, 'lost', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (Senate) District 32', 'State Senator', 'b7fe196b-f4c8-47b4-8145-49342845a267'::uuid, '37bdc3b0-47f9-4764-8d32-6de499c39ea8'::uuid, 1, 'Cindy Ryu', 'Cindy Ryu', '20261103WA48093', '150942', 'Dem', 32372, 50.85, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (Senate) District 32', 'State Senator', 'b7fe196b-f4c8-47b4-8145-49342845a267'::uuid, '5746c1ff-6379-4761-8b26-99bcd22f405b'::uuid, 1, 'Jesse Salomon', 'Jesse Salomon', '20261103WA48093', '152500', 'Dem', 30278, 47.56, 'lost', 'exact-full-name', 'advanced', true),
  ('wa', 'Legislative (Senate) District 8', 'State Senator', '1a3f1458-3c73-4aaa-8b98-1920f946793c'::uuid, 'd8a513c6-8ea7-48fd-8bf4-91b2e3b07576'::uuid, 1, 'Nikki Torres', 'Nikki Torres', '20261103WA48045', '154227', 'GOP', 27017, 52.69, 'won', 'exact-full-name', 'advanced', false),
  ('wa', 'Legislative (Senate) District 8', 'State Senator', '1a3f1458-3c73-4aaa-8b98-1920f946793c'::uuid, 'ed84e33f-4502-43b6-866e-2b9ef03ee44e'::uuid, 1, 'Gabe Galbraith', 'Gabe Galbraith', '20261103WA48045', '176122', 'GOP', 23244, 45.33, 'lost', 'exact-full-name', 'advanced', false);

-- The citation each row carries before this file touches it, captured from PRODUCTION so the
-- survival gate below compares against the live value and not against this file's own copy.
CREATE TEMP TABLE before_image AS
  SELECT rc.id AS rc_id, rc.result AS result, rc.result_source AS result_source,
         rc.result_certainty AS result_certainty, rc.is_incumbent AS is_incumbent,
         rc.full_name
    FROM essentials.race_candidates rc
    JOIN called c ON c.rc_id = rc.id;

-- Occupancy as it stands before the write, for every office this file touches. Compared after,
-- because "recording a result seats nobody" is a claim and a claim needs a gate.
CREATE TEMP TABLE occupancy_before AS
  SELECT och.office_id, och.politician_id
    FROM essentials.office_current_holder och
   WHERE och.office_id IN (SELECT r.office_id FROM essentials.races r JOIN called c ON c.race_id = r.id);

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  -- 🔴 unaccent is NOT installed on prod and AP returns accents our own rows may drop. Fold
  --    them here, in the application's own terms.
  SELECT regexp_replace(
           upper(translate(coalesce(t, ''),
             'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçÝý',
             'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCcYy')),
           '[^A-Z0-9]', '', 'g')
$f$;

-- ─── 2. Everything that must be true before a single row is written ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM called;
  IF n <> 108 THEN RAISE EXCEPTION 'expected 108 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> 51 THEN RAISE EXCEPTION 'expected 51 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'won';
  IF n <> 56 THEN RAISE EXCEPTION 'expected 56 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'lost';
  IF n <> 52 THEN RAISE EXCEPTION 'expected 52 losers, the file carries %', n; END IF;

  -- POSITIVE CONTROL. Every "no mismatch found" below is vacuous if the comparison cannot see
  -- anything at all, so prove it can before trusting its silence.
  PERFORM 1 FROM essentials.race_candidates
   WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Randi L. Knott');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist - every name gate below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM before_image;
  IF n <> 108 THEN RAISE EXCEPTION 'the before-image sees % of the 108 rows this file names - a gate that reads the wrong rows proves nothing', n; END IF;

  -- 🔴 EVERY ROW IS ADDRESSED BY uuid AND THE NAME BESIDE IT DOES NOT FIND IT. A mistyped id
  --   would otherwise move a win to another seat in silence, so the pin is re-asserted against
  --   production: the row must exist, sit in the stated race, and carry the stated name.
  SELECT count(*) INTO n FROM called c LEFT JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% pinned candidacies do not exist', n; END IF;
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id WHERE rc.race_id <> c.race_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned candidacies sit in a different race: %', txt; END IF;

  -- 🔴 The name is compared against THE DATABASE ROW, never against another column of this
  --   file, because a file that checks itself agrees with itself.
  SELECT string_agg(c.our_name || ' <> ' || rc.full_name, ', ') INTO txt
    FROM called c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE pg_temp.namekey(rc.full_name) <> pg_temp.namekey(c.our_name);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'pinned rows do not carry the name this file states: %', txt; END IF;

  -- the race must be a 2026-11-03 state-legislative race, or this file is writing somewhere else
  SELECT count(*) INTO n
    FROM called c JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03' OR d.district_type NOT IN ('STATE_LOWER', 'STATE_UPPER');
  IF n <> 0 THEN RAISE EXCEPTION '% pinned rows are not in a 2026-11-03 state-legislative race', n; END IF;

  -- 🔴 WINNERS PER RACE MUST EQUAL races.seats, NEVER ONE.
  SELECT string_agg(x.district || ' (' || x.w || ' winners, seats ' || x.seats || ')', ', ') INTO txt
    FROM (SELECT c.district, c.seats, count(*) FILTER (WHERE c.outcome = 'won') AS w
            FROM called c GROUP BY c.race_id, c.district, c.seats) x
   WHERE x.w <> x.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'winner count does not match races.seats: %', txt; END IF;
  SELECT string_agg(c.district, ', ') INTO txt
    FROM called c JOIN essentials.races r ON r.id = c.race_id
   WHERE r.seats <> c.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file states a seat count production disagrees with: %', txt; END IF;

  -- 🔴🔴 THE WINNERS MUST BE THE TOP VOTE-GETTERS. The only gate here that brings in a second,
  --   independent AP field; see the header.
  SELECT string_agg(x.district || ' (' || x.our_name || ')', ', ') INTO txt FROM (
    SELECT c.district, c.our_name, c.outcome,
           rank() OVER (PARTITION BY c.race_id ORDER BY c.votes DESC) AS vote_rank,
           c.seats
      FROM called c
  ) x
   WHERE (x.outcome = 'won') <> (x.vote_rank <= x.seats);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the rows marked won are not the top vote-getters of their race: %', txt; END IF;

  -- 🔴 NOTHING THIS FILE WRITES MAY ALREADY BE DECIDED.
  SELECT string_agg(b.full_name || ' = ' || b.result, ', ') INTO txt
    FROM before_image b WHERE b.result IN ('won', 'lost', 'not_nominated', 'withdrew', 'runoff');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows this file writes already carry a decided result: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result_certainty IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% rows this file writes already carry a certainty - CC_0381 or another pass reached them first', n; END IF;

  -- and the prior value must be exactly the one recorded in the header, or somebody has
  -- written here since the analysis was taken
  SELECT string_agg(b.full_name || ': file says ' || coalesce(c.prior_result, 'NULL')
                    || ', production says ' || coalesce(b.result, 'NULL'), ', ') INTO txt
    FROM called c JOIN before_image b ON b.rc_id = c.rc_id
   WHERE coalesce(b.result, '') <> coalesce(c.prior_result, '');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior values have moved since this file was generated: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced';
  IF n <> 62 THEN RAISE EXCEPTION 'expected 62 rows carrying advanced, production has %', n; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced' AND coalesce(result_source, '') = '';
  IF n <> 0 THEN RAISE EXCEPTION '% advanced rows carry no citation to preserve', n; END IF;

  -- 🔴 THE 'holder' BASIS IS ONLY SOUND IF PRODUCTION STILL AGREES WITH IT. Every row matched
  --   that way is re-checked here against office_current_holder: AP called the candidate the
  --   seat's incumbent, and our own view must name the same politician for that same office.
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE c.match_basis = 'holder'
     AND (och.politician_id IS NULL OR rc.politician_id IS NULL OR och.politician_id <> rc.politician_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows matched on the incumbent basis are no longer the seat holder: %', txt; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 rows on the incumbent basis, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder' AND NOT ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '% rows claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  -- 🔴🔴 THE TOKEN BASIS IS THE ONE THAT CAN HAND A SEAT TO THE WRONG PERSON HERE, BECAUSE ALL
  --   3 OF ITS ROWS ARE WINNERS. The header's evidence is Washington's own canvass, so the
  --   gate holds the shape that evidence has: every token match is a Washington row, and the
  --   name WE store is the LONGER one - AP's string shares our first name and our surname and
  --   drops what sits between. A match relaxed past that shape is refused.
  SELECT count(*) INTO n FROM called WHERE match_basis = 'first-last-tokens';
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 token matches, the file carries %', n; END IF;
  SELECT string_agg(c.our_name || ' / ' || c.ap_name, ', ') INTO txt FROM called c
   WHERE c.match_basis = 'first-last-tokens'
     AND (c.state <> 'wa'
          OR length(c.our_name) <= length(c.ap_name)
          OR upper(split_part(c.our_name, ' ', 1)) <> upper(split_part(c.ap_name, ' ', 1))
          OR upper(regexp_replace(c.our_name, '^.* ', '')) <> upper(regexp_replace(c.ap_name, '^.* ', '')));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a token match is not the Washington long-name shape the header evidences: %', txt; END IF;

  RAISE NOTICE 'pre-checks passed: % candidacies across % races, % won, % lost',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called),
    (SELECT count(*) FROM called WHERE outcome = 'won'), (SELECT count(*) FROM called WHERE outcome = 'lost');
END $$;

-- ─── 3. The write ───
-- 🔴 The existing citation is APPENDED, read from the LIVE column rather than from this file's
--    copy of it, so a row somebody has re-cited since the analysis keeps whatever it now says.
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = 'called',
       result_source = 'Associated Press race call for the 2026-11-03 general election, read '
         || '2026-11-11 from AP''s own per-state results feed '
         || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/races/'
         || upper(c.state) || '/, race ' || c.ap_race_id || ', candidate ' || c.ap_candidate_id
         || '): ' || c.ap_name || coalesce(' (' || c.party || ')', '') || ' '
         || c.votes || ' votes, ' || c.pct || '%, recorded as ' || c.outcome
         || '. AP had not called this race when CC_0381 was written from the 2026-11-08 read.'
         || ' This is AP''s call and NOT the state canvass; AP reports this race as not yet '
         || 'certified. Matched to our row on basis ''' || c.match_basis || '''.'
         || CASE WHEN c.match_basis = 'first-last-tokens'
                 THEN ' Confirmed against the Washington Secretary of State canvass '
                      || '(results.votewa.gov/results/public/api/elections/washington/20261103/data, '
                      || 'read 2026-11-11), which prints this candidate as ''' || c.our_name
                      || ''' with ' || c.votes || ' votes - our spelling and AP''s count, from a '
                      || 'source independent of AP.'
                 ELSE '' END
         || CASE WHEN coalesce(rc.result_source, '') <> ''
                 THEN ' - the citation this row already carried is retained verbatim: ' || rc.result_source
                 ELSE '' END,
       result_recorded_at = now()
  FROM called c
 WHERE rc.id = c.rc_id
   AND rc.result IS NOT DISTINCT FROM c.prior_result;

-- ─── 4. Post-verify ───
DO $$
DECLARE n int; txt text; total int; flagged int; unflagged int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE rc.result = c.outcome AND rc.result_certainty = 'called';
  IF n <> 108 THEN RAISE EXCEPTION 'expected 108 rows written, % carry the outcome this file states', n; END IF;

  -- every row must cite the AP race it came from, by id
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE position(c.ap_race_id in coalesce(rc.result_source, '')) = 0;
  IF n <> 0 THEN RAISE EXCEPTION '% written rows do not name the AP race they came from', n; END IF;

  -- 🔴 THE 62 PRESERVED CITATIONS MUST SURVIVE VERBATIM. There is no history table: if
  --   this fails after a change to the UPDATE, those citations are gone for good.
  SELECT string_agg(b.full_name, ', ') INTO txt
    FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> ''
     AND position(b.result_source in coalesce(rc.result_source, '')) = 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior citations were destroyed rather than appended: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> '' AND position(b.result_source in rc.result_source) > 0;
  IF n <> 62 THEN RAISE EXCEPTION 'expected 62 preserved citations, found %', n; END IF;

  -- the Washington token matches must carry the state's confirmation, by name and by number
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE c.match_basis = 'first-last-tokens'
     AND position('results.votewa.gov' in coalesce(rc.result_source, '')) > 0
     AND position(c.our_name in coalesce(rc.result_source, '')) > 0;
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 token matches citing the state canvass by name, found %', n; END IF;

  -- 🔴 RECORDING A RESULT SEATS NOBODY. These members take office in January; if this file has
  --   moved an officeholder, it has done something it does not claim to do.
  SELECT count(*) INTO n FROM occupancy_before;
  IF n = 0 THEN RAISE EXCEPTION 'the occupancy snapshot is empty - the comparison below would pass vacuously'; END IF;
  SELECT string_agg(x.office_id::text, ', ') INTO txt FROM (
    SELECT coalesce(b.office_id, a.office_id) AS office_id
      FROM occupancy_before b
      FULL OUTER JOIN (
        SELECT och.office_id, och.politician_id
          FROM essentials.office_current_holder och
         WHERE och.office_id IN (SELECT r.office_id FROM essentials.races r JOIN called c ON c.race_id = r.id)
      ) a ON a.office_id = b.office_id
     WHERE a.office_id IS NULL OR b.office_id IS NULL
        OR a.politician_id IS DISTINCT FROM b.politician_id
  ) x;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the current officeholder changed for office(s) % - this file seats nobody', txt; END IF;

  -- 🔴 NOTHING OUTSIDE THE PINNED SET MAY HAVE BEEN WRITTEN, AND THE ONLY HONEST FORM OF THAT
  --   CLAIM IS NOW A COUNT: CC_0381's 809 rows legitimately carry a call, so "zero outside this
  --   file" would be false. If this number is not 809, this file is running beside somebody
  --   else's write and its own counts prove nothing.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND rc.result_certainty = 'called'
     AND rc.id NOT IN (SELECT rc_id FROM called);
  IF n <> 809 THEN RAISE EXCEPTION 'expected CC_0381''s 809 called rows beside this file''s 108, found %', n; END IF;

  -- the tier's own number, which is what this file exists to move
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER') AND rc.result = 'won';
  IF n <> 483 THEN RAISE EXCEPTION 'expected 483 state-legislative winners after this file, found %', n; END IF;

  -- 🔴 THE OCCUPANCY DRIFT BASELINE. This file creates no office, so the unflagged count must
  --   not have moved. It is asserted rather than assumed because a baseline nobody checks is a
  --   baseline that moves under the next author.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;

  RAISE NOTICE 'CC_0402 done: % candidacies across % races, 56 won / 52 lost; tier now 483 winners; occupancy % / % / %',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called), total, flagged, unflagged;
END $$;

DROP TABLE IF EXISTS before_image;
DROP TABLE IF EXISTS occupancy_before;

COMMIT;

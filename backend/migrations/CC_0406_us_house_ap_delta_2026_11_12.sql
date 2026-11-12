-- CC_0406 - 2026-11-03 US House: record the 41 races the Associated Press has CALLED
--           since CC_0350, and the losers on those same ballots. Two of them are the first
--           contests anywhere in this programme that AP reports as CERTIFIED.
--
-- WHY THIS FILE EXISTS. CC_0350 recorded 377 called US House races; later passes (CC_0351,
--   CC_0352, CC_0356) added losers, seeded missing candidates and picked up three late calls.
--   Production stands at 381 of 435 seats with a winner. Re-reading AP's national feed on
--   2026-11-12 finds 41 of the remaining 54 now called. This file records exactly those.
--   🔴 THE OTHER 13 STILL GET NO ROW, and they are not a backlog:
--     10  Too Early to Call
--      2  Runoff
--      1  Awaiting Ranked Choice Results
--     ▶ Two Louisiana seats are in a RUNOFF, not undecided: Louisiana's November contest is a
--       nonpartisan primary and nobody cleared 50%. ME-02 and AK At-Large are RANKED CHOICE and
--       AP is still counting rounds. An uncalled race is an honest blank, never a guess.
--
-- WHAT IT WRITES: 111 existing candidacies UPDATED across 41 races - 41 won, 70 lost. No politician,
--   race, office, district or term is created, deleted or re-seated. RECORDING A RESULT SEATS
--   NOBODY: these members take office on 2027-01-03 and the post-verify asserts that not one
--   office_terms row moved.
--
--     AR   1 races   1 won   1 lost
--     AZ   5 races   5 won  12 lost
--     CA   5 races   5 won   5 lost
--     CO   2 races   2 won   6 lost
--     FL   5 races   5 won   8 lost
--     MT   1 races   1 won   2 lost
--     NC   6 races   6 won   9 lost
--     NJ   1 races   1 won   1 lost
--     NY   4 races   4 won   4 lost
--     OH   1 races   1 won   1 lost
--     SC   2 races   2 won   4 lost
--     TN   2 races   2 won   6 lost
--     UT   2 races   2 won   7 lost
--     VA   2 races   2 won   2 lost
--     WA   2 races   2 won   2 lost
--
--   After this file the tier reads 422 winners across 435 US House races.
--
-- 🔴🔴 THE FIRST 'certified' ROWS OF THE NOVEMBER GENERAL, AND THE WORD IS NOT AP'S ALONE.
--   ⚠ SCOPE THE CLAIM OR IT IS FALSE. 'certified' is NOT a new value in this schema: 489 rows
--     already carry it, across the 2026 primaries and the spring municipal generals - Wisconsin's
--     August partisan primary alone holds 250, Utah's June primary 124. What has never carried it
--     is the GENERAL ELECTION OF 2026-11-03: across all 53 elections held that day, 2,652 rows
--     read 'called' and ZERO read 'certified'. This file writes the first 6, and only 6:
--   South Carolina's 1st and 2nd congressional districts, which AP reports with
--   isCertified = true AND tabulationStatus = 'Vote Certified' AND eevp = 100.
--   ▶ A CALL AND A CANVASS ARE TWO FACTS, so AP's flag was not taken on its own. The South
--     Carolina Election Commission's own results service was read on 2026-11-12 and agrees with
--     AP TO THE VOTE on all four ballot lines of both races:
--       SC-01 (enr-scvotes.org/SC/127300, "Official Results", counties reporting 100%)
--         Nancy Lacore (DEM) 162,103 - 49.66%   Jenny Costa Honeycutt (REP) 158,751 - 48.63%
--         Bill Reeside (LIB) 5,351 - 1.64%      Write-In 218 - 0.07%     total 326,423
--       SC-02 (enr-scvotes.org/SC/127592, the RECOUNT, "County Certified Results: 100.00% (13)")
--         Joe Wilson (REP) 147,785 - 49.80%     Zyon Khalifa (DEM) 144,945 - 48.85%
--         Dayna Alane Smith (WRK) 3,673 - 1.24% Write-In 334 - 0.11%     total 296,737
--   🔴 SC-02 WENT TO A RECOUNT, held 2026-11-10, and that is why this race deserves the word
--     rather than being assumed into it. ⚠ The state publishes TWO pages for it and they do not
--     agree: the general-election summary still shows the PRE-recount figures (Wilson 147,791,
--     Khalifa 144,865, Smith 3,674, total 296,664) while the recount page, updated 2026-11-12,
--     shows the figures above. AP matches the RECOUNT page exactly. The order never changes on
--     any version - Wilson first by about 2,900 votes - so the outcome this file records is not
--     in question, but a file that wrote 'certified' without reading the recount would have been
--     guessing. We store no vote counts; every number quoted in a citation is labelled.
--   🟢 SC-01 IS A FLIP and the namesake trap is real here: the departing member is Nancy MACE
--     (GOP, AP's named incumbent, not on this ballot) and the winner is Nancy LACORE (Dem).
--     Two different Nancys. The match is on the full name and the pin is a uuid.
--
-- 🔴 PRIOR VALUES, BECAUSE AN UPDATE IS FINAL AND THERE IS NO HISTORY TABLE.
--   82 rows carry NULL in all four columns this file touches.
--   29 rows carry result = 'advanced' with a real citation in result_source - Arizona's
--      Secretary of State general-election candidate list and its July primary canvass,
--      Tennessee's and Washington's primary canvasses. 'advanced' is a TRUE AND LOAD-BEARING
--      FACT about the primary, and this file is recording a different election.
--   ▶ Those citations are APPENDED, never overwritten, and the UPDATE reads the LIVE value
--     rather than this file's copy of it. A gate asserts every one of the 29 survives verbatim.
--   ⚠ No row in this file carries a decided result (won/lost/not_nominated/withdrew/runoff) and
--     none carries any result_certainty; both are gated, so a row another pass reached first
--     stops this file rather than being overwritten by it.
--
-- 🔴🔴 THE NAME MATCH IS THE DANGEROUS STEP. 5 bases, and NOT ONE of them is a relaxed
--   surname match. CC_0402 had to defend 3 token matches that were all winners; this file has
--   ZERO token matches, because reading two fields AP already publishes removed the need:
--     'ap-nickname'           7 rows (2 winners). AP's OWN nickname and middle-name fields. AP publishes
--                              {"first":"Thomas","last":"Feely","suffix":"IV","nickname":"Jay"},
--                              so matching our "Jay Feely" READS AP rather than guessing. This
--                              basis did not exist when CC_0402 was written and it is what
--                              removed every token match from this file.
--     'exact-first-last'      8 rows (2 winners). First and last name identical; a middle name or initial differs
--                              ("Andrew R. Garbarino" against AP's "Andrew Garbarino"). The
--                              surname is never relaxed.
--     'exact-full-name'      89 rows (34 winners). Identical once case, punctuation and accents are folded.
--     'holder'                6 rows (3 winners). AP flags the candidate as that seat's incumbent AND
--                              essentials.office_current_holder independently names the politician
--                              our row links to, for that same office. Two facts, neither a name.
--     'reviewed'              1 rows (0 winners). One hand-checked row, matched by ROLE and not by spelling:
--                              NY-01's "Chris Gallant" against AP's "Christopher J. Gallant".
--                              Our row's own cited source names Chris Gallant as the DEMOCRATIC
--                              NOMINEE; the New York State Board of Elections' CERTIFIED June
--                              2026 primary results name that nominee "Christopher J. Gallant",
--                              and he is the ONLY Gallant in the entire statewide primary file.
--                              A district has one Democratic nominee and the state names him.
--   🟢 EVERY NON-EXACT MATCH THAT WON IS CONFIRMED TWICE. All 7 of them are sitting members AP
--     flags as the incumbent AND whom office_current_holder independently names as the holder of
--     that same seat, under the same spelling our row carries. A gate re-asserts that below.
--
-- 🔴 A TOP-VOTE-GETTER CROSS-CHECK IS THE ONLY GATE THAT CAN CATCH A TRANSPOSED WIN, because
--   every other check reads the outcome column beside the name and a file that has swapped two
--   outcomes agrees with itself perfectly. AP publishes the winner FLAG and the VOTE COUNT as
--   independent fields; the gate requires the row marked 'won' to be the top row by votes.
--   ⚠ Every US House race elects one member, so seats = 1 throughout and the gate is checked
--     against races.seats rather than against the constant. ⚠ No race here is ranked-choice;
--     the analyser refuses one, because a later-round winner need not lead on first preferences.
--
-- ⚠ THREE AP BALLOT LINES IN THESE RACES HAVE NO ROW OF OURS AND ARE NOT WRITTEN: NJ-02 Ramon
--   Mora (Oth, 2,845), OH-10 Thomas McMasters (Lib, 8,906) and VA-05 Cooke Harvey (Ind, 5,942).
--   All three LOST, so no winner is missed; they are a candidate-seeding gap for a later pass,
--   not a result this file can record. Creating a candidacy is a different act from recording
--   one, and this file does only the second.
--
-- 🔴 THIS FILE IS DELIBERATELY NOT IDEMPOTENT, AND SAYS SO RATHER THAN CLAIMING OTHERWISE.
--   A second run is REFUSED by the pre-gate with 'rows this file writes already carry a decided
--   result'. A re-run would append this citation on top of the one it wrote the first time and
--   there is no history table to undo it with. The refusal is watched, not assumed.
--   ▶ If this file has to be applied again, regenerate it against the live rows first.
--
-- SOURCING. AP's own national feed, read 2026-11-12, plus the South Carolina Election
--   Commission for the two certified races. Every citation labels which fact it carries.
--   ⚠ AP'S HOUSE FILE HAD NOT MOVED IN 24 HOURS when this was written: the 2026-11-11 and
--     2026-11-12 reads agree on all 435 races - 422 called, 10 too early, 2 runoff, 1 awaiting
--     ranked choice - and on all 14 certified. The delta here is against OUR data, not AP's.
--   ⚠ AP's national file lists 436 House races. The 436th, 20261103US999999, carries
--     statePostal 'US' and NO raceCallStatus; it is a phantom and is excluded by its own shape.
--   🟢 THE MATCH TO OUR RACES IS 1:1 IN BOTH DIRECTIONS: 435 AP House races against our 435,
--     keyed on ocd_id's cd: suffix and AP's seatNum, with zero unmatched on either side.
--     ⚠ One district carries NO ocd_id (CA-33, already recorded and not touched here); it is
--       keyed from its label only because tiger_geoid 0633 independently says district 33.
--     ⚠ AP publishes every single-district state - AK, DE, ND, SD, VT, WY - as "District 1",
--       where our ocd_id reads cd:at-large. AK At-Large is NOT missing from AP, which an
--       earlier read of this delta concluded; it is 20261103AK2015 and is still too early.
--
-- CONTROLS. 12 variants of this exact file were run against production inside BEGIN/ROLLBACK,
--   each tamper asserted PRESENT in the file before the variant ran, each watched going RED:
--   a transposed win (caught only by the top-vote-getter gate); a name that does not match the
--   pinned row; a moved prior value; the citation append removed; the holder basis without AP's
--   incumbent flag; a non-exact WINNER stripped of its second source; certification claimed for
--   a race with no state canvass behind it; the certified count changed; a call appearing
--   outside the pinned set; a row already decided; and an emptied occupancy snapshot.
--   ⚠ TWO CONTROLS FIRST FAILED AT THE WRONG GATE, which is itself the finding: a tamper that
--     also moves a count trips the count gate first and proves nothing about the gate it was
--     aimed at. Both were rebuilt to hold every other number steady - the non-exact-winner
--     control moved to a row the holder gates do not touch, and the certification control MOVES
--     the claim rather than adding one, so the count stays 6.
--
-- Slot CC_0406 reserved via steward. Applied to production 2026-11-12 by Chris Cantrell.

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
  certainty        text NOT NULL CHECK (certainty IN ('called', 'certified')),
  match_basis      text NOT NULL CHECK (match_basis IN ('ap-nickname', 'exact-first-last', 'exact-full-name', 'holder', 'reviewed')),
  prior_result     text,            -- the value this row carries BEFORE this file runs
  ap_incumbent     boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO called (state, district, office_title, race_id, rc_id, seats, our_name, ap_name,
                    ap_race_id, ap_candidate_id, party, votes, pct, outcome, certainty,
                    match_basis, prior_result, ap_incumbent) VALUES
  ('ar', 'Congressional District 2', 'U.S. Representative', '4195963e-5991-4853-b384-97fe6ac8a0f9'::uuid, '2e56944e-6b85-4997-9105-c00c7b585160'::uuid, 1, 'Chris Jones', 'Chris Jones', '20261103AR5105', '70529', 'Dem', 123096, 49.13, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ar', 'Congressional District 2', 'U.S. Representative', '4195963e-5991-4853-b384-97fe6ac8a0f9'::uuid, 'bc89f0c3-9e1e-4c30-a97c-6ddb5da4676c'::uuid, 1, 'J. French Hill', 'French Hill', '20261103AR5105', '63416', 'GOP', 127452, 50.87, 'won', 'called', 'holder', NULL, true),
  ('az', 'Congressional District 1', 'U.S. Representative', '75673cd6-afba-409e-a94a-a50983a3c5c8'::uuid, 'ea724c24-8f62-419d-8d44-b724c229a87c'::uuid, 1, 'Amish Shah', 'Amish Shah', '20261103AZ3004', '101869', 'Dem', 185813, 52.39, 'won', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 1', 'U.S. Representative', '75673cd6-afba-409e-a94a-a50983a3c5c8'::uuid, 'daf07f0e-2ec0-481f-af77-90a8a3f7186f'::uuid, 1, 'Dev Gupta', 'Dev Gupta', '20261103AZ3004', '179207', 'Ind', 14, 0, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 1', 'U.S. Representative', '75673cd6-afba-409e-a94a-a50983a3c5c8'::uuid, '52294def-bc21-47c0-a543-f54cbc42b1de'::uuid, 1, 'Gage Dylan Thunder', 'Gage Dylan Thunder', '20261103AZ3004', '179181', 'NPA', 15, 0, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 1', 'U.S. Representative', '75673cd6-afba-409e-a94a-a50983a3c5c8'::uuid, '744200c2-21e4-4436-b8ca-8cdda2a59eb3'::uuid, 1, 'Jay Feely', 'Thomas Feely', '20261103AZ3004', '174913', 'GOP', 161118, 45.43, 'lost', 'called', 'ap-nickname', 'advanced', false),
  ('az', 'Congressional District 1', 'U.S. Representative', '75673cd6-afba-409e-a94a-a50983a3c5c8'::uuid, '5859efd0-34fe-43bf-949e-bc5359f04cd5'::uuid, 1, 'Monica Alponte', 'Monica Alponte', '20261103AZ3004', '178228', 'Lib', 7700, 2.17, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 2', 'U.S. Representative', '62309566-c8a1-4d3d-b2d1-df0881285296'::uuid, 'a48d4bf8-b07d-4ce8-bda5-6bd6b8b5c359'::uuid, 1, 'Curtis Goodwin', 'Curtis Goodwin', '20261103AZ3006', '178229', 'Lib', 6042, 1.83, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 2', 'U.S. Representative', '62309566-c8a1-4d3d-b2d1-df0881285296'::uuid, '3ff9b0be-a73d-45f3-a82c-522a46c08a1f'::uuid, 1, 'Elijah Crane', 'Eli Crane', '20261103AZ3006', '70963', 'GOP', 163530, 49.61, 'won', 'called', 'holder', 'advanced', true),
  ('az', 'Congressional District 2', 'U.S. Representative', '62309566-c8a1-4d3d-b2d1-df0881285296'::uuid, 'e839b499-a1fb-4315-9daa-fab748fba42b'::uuid, 1, 'Jonathan Nez', 'Jonathan Nez', '20261103AZ3006', '164639', 'Dem', 160084, 48.56, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 5', 'U.S. Representative', '84abf18f-2d9f-411f-8fe6-bbbcd1486acd'::uuid, 'c36d3e3f-a998-4c00-bdf8-24323aa46895'::uuid, 1, 'Elizabeth Lee', 'Elizabeth Lee', '20261103AZ3012', '174922', 'Dem', 157036, 48.32, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 5', 'U.S. Representative', '84abf18f-2d9f-411f-8fe6-bbbcd1486acd'::uuid, '765d27b3-67b3-4be7-b73d-c8031863dade'::uuid, 1, 'Mark Lamb', 'Mark Lamb', '20261103AZ3012', '164629', 'GOP', 167969, 51.68, 'won', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 6', 'U.S. Representative', '67e4186e-ac8b-42cc-bded-59521bc65d19'::uuid, '940fd68a-e883-4ca3-a2be-14e4e568825d'::uuid, 1, 'Gary Swing', 'Gary Swing', '20261103AZ3544', '178694', 'Grn', 3264, 0.91, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 6', 'U.S. Representative', '67e4186e-ac8b-42cc-bded-59521bc65d19'::uuid, 'ba9d50dd-343c-4dde-8c92-cf2fd58d77fc'::uuid, 1, 'Jereme Peters', 'Jereme Peters', '20261103AZ3544', '178232', 'Lib', 4514, 1.26, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 6', 'U.S. Representative', '67e4186e-ac8b-42cc-bded-59521bc65d19'::uuid, 'de76acb4-7388-425a-8400-6e39aa3924e2'::uuid, 1, 'JoAnna Mendoza', 'JoAnna Mendoza', '20261103AZ3544', '101892', 'Dem', 190050, 52.96, 'won', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 6', 'U.S. Representative', '67e4186e-ac8b-42cc-bded-59521bc65d19'::uuid, 'ab5f522b-7748-4b8e-9e23-c3250d1ae468'::uuid, 1, 'Juan Ciscomani', 'Juan Ciscomani', '20261103AZ3544', '70979', 'GOP', 160969, 44.85, 'lost', 'called', 'exact-full-name', 'advanced', true),
  ('az', 'Congressional District 6', 'U.S. Representative', '67e4186e-ac8b-42cc-bded-59521bc65d19'::uuid, 'eb63409b-b57b-454b-b1e5-30a118c77801'::uuid, 1, 'Michael Dorland', 'Michael Dorland', '20261103AZ3544', '179621', 'Ind', 85, 0.02, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('az', 'Congressional District 8', 'U.S. Representative', '0e440715-e733-4d7f-8578-717fb73bebc5'::uuid, 'f996989c-a01e-4a2d-bd77-1f3dda1cb5fe'::uuid, 1, 'Abraham J. Hamadeh', 'Abraham Hamadeh', '20261103AZ3924', '101964', 'GOP', 147023, 51.19, 'won', 'called', 'exact-first-last', 'advanced', true),
  ('az', 'Congressional District 8', 'U.S. Representative', '0e440715-e733-4d7f-8578-717fb73bebc5'::uuid, 'd7c90dec-e91d-49e9-8e8e-8f710b80855d'::uuid, 1, 'Bernadette Greene-Placentia', 'Bernadette Greene-Placentia', '20261103AZ3924', '174923', 'Dem', 140203, 48.81, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('ca', 'District 29', 'Representative', '40190b91-ec57-4da9-9955-1cb3b8b06486'::uuid, 'acac164d-dbef-4407-b83f-f0e3a396b3a2'::uuid, 1, 'Angélica María Dueñas', 'Angélica Dueñas', '20261103CA5719', '66566', 'Dem', 73959, 42.64, 'lost', 'called', 'ap-nickname', NULL, false),
  ('ca', 'District 29', 'Representative', '40190b91-ec57-4da9-9955-1cb3b8b06486'::uuid, '7273850d-f510-4d80-b4f3-74262ccc5257'::uuid, 1, 'Luz Rivas', 'Luz Rivas', '20261103CA5719', '106179', 'Dem', 99498, 57.36, 'won', 'called', 'exact-full-name', NULL, true),
  ('ca', 'Congressional District 7', 'U.S. Representative', '143ffa3e-701f-46dc-ba19-f67c557b58eb'::uuid, '998e3744-1b42-4e02-9e39-f0522037861d'::uuid, 1, 'Doris Matsui', 'Doris Matsui', '20261103CA5697', '51416', 'Dem', 124027, 53.29, 'won', 'called', 'exact-full-name', NULL, true),
  ('ca', 'Congressional District 7', 'U.S. Representative', '143ffa3e-701f-46dc-ba19-f67c557b58eb'::uuid, 'dd2e5d11-a6cc-4156-993b-467e934b0ec4'::uuid, 1, 'Mai Vang', 'Mai Vang', '20261103CA5697', '172516', 'Dem', 108703, 46.71, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ca', 'Congressional District 11', 'U.S. Representative', '586d8394-217f-4321-ad9e-4da4634202d4'::uuid, '9ed5506a-a215-48f2-abb3-fa6493c291f6'::uuid, 1, 'Connie Chan', 'Connie Chan', '20261103CA5701', '172530', 'Dem', 140395, 46.67, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ca', 'Congressional District 11', 'U.S. Representative', '586d8394-217f-4321-ad9e-4da4634202d4'::uuid, 'e4e9c5a6-d1b9-47a8-8658-35a0bc0e8a89'::uuid, 1, 'Scott Wiener', 'Scott Wiener', '20261103CA5701', '105765', 'Dem', 160400, 53.33, 'won', 'called', 'exact-full-name', NULL, false),
  ('ca', 'Congressional District 14', 'U.S. Representative', 'f6579e2c-0012-4e01-be52-f202e3aa25c2'::uuid, 'd656239b-a4a9-49dc-a514-7a656e574dd0'::uuid, 1, 'Aisha Wahab', 'Aisha Wahab', '20261103CA5704', '106729', 'Dem', 120060, 57.58, 'won', 'called', 'exact-full-name', NULL, true),
  ('ca', 'Congressional District 14', 'U.S. Representative', 'f6579e2c-0012-4e01-be52-f202e3aa25c2'::uuid, 'fa3840bb-91fb-4cc0-821d-afb00edc2aad'::uuid, 1, 'Melissa Hernandez', 'Melissa Hernandez', '20261103CA5704', '172536', 'Dem', 88461, 42.42, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ca', 'Congressional District 40', 'U.S. Representative', 'ce3d2c4f-42b2-40bc-9e40-4f96ca1446bb'::uuid, '09e63152-bb1e-443d-ac08-8c7a10d426c2'::uuid, 1, 'Ken Calvert', 'Ken Calvert', '20261103CA5730', '132', 'GOP', 116486, 53.09, 'won', 'called', 'exact-full-name', NULL, true),
  ('ca', 'Congressional District 40', 'U.S. Representative', 'ce3d2c4f-42b2-40bc-9e40-4f96ca1446bb'::uuid, '66fde47b-6385-4b99-8ec8-f42671400ba3'::uuid, 1, 'Young Kim', 'Young Kim', '20261103CA5730', '66573', 'GOP', 102917, 46.91, 'lost', 'called', 'exact-full-name', NULL, true),
  ('co', 'Congressional District 3', 'U.S. Representative', 'ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, 'dfa1b595-8585-4e4b-9b56-3f5456909542'::uuid, 1, 'Clifton Brown', 'Clifton Brown', '20261103CO6615', '178516', 'Una', 5335, 1.6, 'lost', 'called', 'exact-full-name', NULL, false),
  ('co', 'Congressional District 3', 'U.S. Representative', 'ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, '56acb51a-fd05-4807-a619-a2b919e80fa2'::uuid, 1, 'Cory Robertson', 'Cory Robertson', '20261103CO6615', '178815', 'Lib', 5560, 1.67, 'lost', 'called', 'exact-full-name', NULL, false),
  ('co', 'Congressional District 3', 'U.S. Representative', 'ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, '925df3e9-417a-4ca9-9dce-4390668283aa'::uuid, 1, 'Dwayne Romero', 'Dwayne Romero', '20261103CO6615', '174617', 'Dem', 157832, 47.42, 'lost', 'called', 'exact-full-name', NULL, false),
  ('co', 'Congressional District 3', 'U.S. Representative', 'ce19d3f5-742e-4c5e-8fa6-a12dda3c4c57'::uuid, '434d954a-2509-470f-8761-bb925fb1acd8'::uuid, 1, 'Jeff Hurd', 'Jeff Hurd', '20261103CO6615', '164158', 'GOP', 164140, 49.31, 'won', 'called', 'exact-full-name', NULL, true),
  ('co', 'Congressional District 5', 'U.S. Representative', '9973aa26-88fd-417c-8332-dee3923caa59'::uuid, '6f4ccf93-bbe4-4eab-8263-aecef8356b43'::uuid, 1, 'Christopher Mitchell', 'Christopher Mitchell', '20261103CO6617', '71795', 'AmC', 5334, 1.73, 'lost', 'called', 'exact-full-name', NULL, false),
  ('co', 'Congressional District 5', 'U.S. Representative', '9973aa26-88fd-417c-8332-dee3923caa59'::uuid, 'd9cac12d-c608-45a3-8741-d6ae562ea861'::uuid, 1, 'Jeff Crank', 'Jeff Crank', '20261103CO6617', '164202', 'GOP', 141074, 45.8, 'lost', 'called', 'exact-full-name', NULL, true),
  ('co', 'Congressional District 5', 'U.S. Representative', '9973aa26-88fd-417c-8332-dee3923caa59'::uuid, '2e287135-2a7d-424d-879a-14060b2af3b0'::uuid, 1, 'Jessica Killin', 'Jessica Killin', '20261103CO6617', '174619', 'Dem', 155598, 50.52, 'won', 'called', 'exact-full-name', NULL, false),
  ('co', 'Congressional District 5', 'U.S. Representative', '9973aa26-88fd-417c-8332-dee3923caa59'::uuid, '810f6774-2ead-499f-9015-013e7012250e'::uuid, 1, 'Mark "Marky Jr" Elworth', 'Mark Elworth', '20261103CO6617', '178817', 'Lib', 5989, 1.94, 'lost', 'called', 'exact-first-last', NULL, false),
  ('fl', 'Congressional District 7', 'U.S. Representative', '0fb663a2-228f-4d92-bba2-04b28b2d63c7'::uuid, '1e23033d-476b-44a6-8d9c-50a955a4ed75'::uuid, 1, 'Bale Dalton', 'Bale Dalton', '20261103FL10019', '175729', 'Dem', 159669, 49.21, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 7', 'U.S. Representative', '0fb663a2-228f-4d92-bba2-04b28b2d63c7'::uuid, '1db574e4-3d78-4a59-8f4f-6da841210df0'::uuid, 1, 'Christopher Dennison', 'Christopher Dennison', '20261103FL10019', '179001', 'Lib', 3485, 1.07, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 7', 'U.S. Representative', '0fb663a2-228f-4d92-bba2-04b28b2d63c7'::uuid, 'db288487-ef18-4351-be68-8872c8f3c834'::uuid, 1, 'Ryan Elijah', 'Ryan Elijah', '20261103FL10019', '175731', 'GOP', 161300, 49.71, 'won', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 9', 'U.S. Representative', 'e0cb8512-3ec4-4e9e-a41a-854be3f2e318'::uuid, 'a20098ba-4d14-4cff-b6bd-908fd81f2be2'::uuid, 1, 'Dan Green', 'Dan Green', '20261103FL10023', '175734', 'GOP', 141808, 49.74, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 9', 'U.S. Representative', 'e0cb8512-3ec4-4e9e-a41a-854be3f2e318'::uuid, '20ad672f-efd2-4ab0-b7d1-b249b80f816b'::uuid, 1, 'Darren Soto', 'Darren Soto', '20261103FL10023', '65743', 'Dem', 143314, 50.26, 'won', 'called', 'exact-full-name', NULL, true),
  ('fl', 'Congressional District 13', 'U.S. Representative', '645c9cd9-581d-4490-ac22-b4445c8d8ab3'::uuid, '88303bfd-196d-4936-9023-8dccb797ae86'::uuid, 1, 'Anna Paulina Luna', 'Anna Luna', '20261103FL10031', '69410', 'GOP', 155189, 49.48, 'won', 'called', 'ap-nickname', NULL, true),
  ('fl', 'Congressional District 13', 'U.S. Representative', '645c9cd9-581d-4490-ac22-b4445c8d8ab3'::uuid, '8b7cc842-b324-4cba-be28-6e09a24cbce9'::uuid, 1, 'Leela Gray', 'Leela Gray', '20261103FL10031', '175764', 'Dem', 152698, 48.68, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 13', 'U.S. Representative', '645c9cd9-581d-4490-ac22-b4445c8d8ab3'::uuid, 'c597cc54-fdfa-4e55-a7d4-a137fdd09364'::uuid, 1, 'Tony D''Arrigo', 'Tony D''Arrigo', '20261103FL10031', '179004', 'NPA', 5782, 1.84, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 26', 'U.S. Representative', 'a88f8013-ec6f-4169-9ddc-adfd81a445a7'::uuid, '0f99ee2a-88aa-4f9f-bf9e-e5747ed4d8f1'::uuid, 1, 'Deborah Ann Meidinger Hosey', 'Deborah Meidinger Hosey', '20261103FL11586', '179013', 'NPA', 2352, 1.02, 'lost', 'called', 'ap-nickname', NULL, false),
  ('fl', 'Congressional District 26', 'U.S. Representative', 'a88f8013-ec6f-4169-9ddc-adfd81a445a7'::uuid, 'b743bfc5-9286-442b-821d-028524c2e56c'::uuid, 1, 'Mario Diaz-Balart', 'Mario Diaz-Balart', '20261103FL11586', '878', 'GOP', 114578, 49.86, 'won', 'called', 'exact-full-name', NULL, true),
  ('fl', 'Congressional District 26', 'U.S. Representative', 'a88f8013-ec6f-4169-9ddc-adfd81a445a7'::uuid, '351997d1-76d6-4b89-b3ea-b37ecad434ba'::uuid, 1, 'Nicole Locklin', 'Nicole Locklin', '20261103FL11586', '175870', 'Dem', 112874, 49.12, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 27', 'U.S. Representative', '30a0923a-0f21-4df9-a162-1038a0dfe2bd'::uuid, '7dc4f538-d16b-4af2-8f87-4eff4e4a69ba'::uuid, 1, 'Eliott Rodriguez', 'Eliott Rodriguez', '20261103FL11587', '175872', 'Dem', 123433, 49.78, 'lost', 'called', 'exact-full-name', NULL, false),
  ('fl', 'Congressional District 27', 'U.S. Representative', '30a0923a-0f21-4df9-a162-1038a0dfe2bd'::uuid, '34f54e97-7b70-4107-bcaa-4a2a4bdbaa2b'::uuid, 1, 'Maria Elvira Salazar', 'Maria Elvira Salazar', '20261103FL11587', '67671', 'GOP', 124519, 50.22, 'won', 'called', 'exact-full-name', NULL, true),
  ('mt', 'Congressional District 1', 'U.S. Representative', 'd92cf3b1-cd21-4c58-90ee-83232a7fd672'::uuid, 'edcf2068-67a3-482d-b76d-69b8ca957910'::uuid, 1, 'Aaron Flint', 'Aaron Flint', '20261103MT28447', '171717', 'GOP', 124747, 46.62, 'lost', 'called', 'exact-full-name', NULL, false),
  ('mt', 'Congressional District 1', 'U.S. Representative', 'd92cf3b1-cd21-4c58-90ee-83232a7fd672'::uuid, 'a8e9d5d2-9126-44cc-9927-55ba8de2708f'::uuid, 1, 'Nick Sheedy', 'Nick Sheedy', '20261103MT28447', '171718', 'Lib', 7719, 2.88, 'lost', 'called', 'exact-full-name', NULL, false),
  ('mt', 'Congressional District 1', 'U.S. Representative', 'd92cf3b1-cd21-4c58-90ee-83232a7fd672'::uuid, '6ef0926b-4b0d-4371-bc57-38508bb2f390'::uuid, 1, 'Sam Forstag', 'Sam Forstag', '20261103MT28447', '171715', 'Dem', 135096, 50.49, 'won', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 1', 'U.S. Representative', 'f97e2ceb-4dae-4922-8132-3dc89375f351'::uuid, '617b0efa-f9d7-4ea0-af43-bef7c1884f24'::uuid, 1, 'Donald G. Davis', 'Don Davis', '20261103NC35385', '70238', 'Dem', 157506, 50.14, 'won', 'called', 'holder', NULL, true),
  ('nc', 'Congressional District 1', 'U.S. Representative', 'f97e2ceb-4dae-4922-8132-3dc89375f351'::uuid, '47810a9a-24f5-45b4-9fd9-69ca4f27272c'::uuid, 1, 'Laurie Buckhout', 'Laurie Buckhout', '20261103NC35385', '160568', 'GOP', 146707, 46.7, 'lost', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 1', 'U.S. Representative', 'f97e2ceb-4dae-4922-8132-3dc89375f351'::uuid, '088dd2f7-8d2c-48a0-be02-4d44ae37729b'::uuid, 1, 'Tom Bailey', 'Tom Bailey', '20261103NC35385', '34158', 'Lib', 9945, 3.17, 'lost', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 6', 'U.S. Representative', 'ebc2c793-6292-4724-be13-a5d09858ea61'::uuid, '0aff4c63-5e1a-49c7-b478-e6e447d5000f'::uuid, 1, 'Addison P. McDowell', 'Addison McDowell', '20261103NC35389', '160574', 'GOP', 134108, 48.8, 'lost', 'called', 'exact-first-last', NULL, true),
  ('nc', 'Congressional District 6', 'U.S. Representative', 'ebc2c793-6292-4724-be13-a5d09858ea61'::uuid, 'ce9de0c6-8664-4e3f-b0b9-ec1ca2718f91'::uuid, 1, 'Cyril Jefferson', 'Cyril Jefferson', '20261103NC35389', '169330', 'Dem', 140727, 51.2, 'won', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 8', 'U.S. Representative', '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid, '3844dcca-e669-406b-93b3-908d1f6b3c71'::uuid, 1, 'Bo Whitehead', 'Bo Whitehead', '20261103NC35390', '177644', 'Grn', 2909, 0.99, 'lost', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 8', 'U.S. Representative', '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid, '7babd4aa-b54b-4039-8fcd-f26b795b8c2a'::uuid, 1, 'Colby Watson', 'Colby Watson', '20261103NC35390', '169332', 'Dem', 142672, 48.65, 'lost', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 8', 'U.S. Representative', '45f2b223-e5ac-44ef-a50f-7234d682462e'::uuid, '49389e43-4906-482e-9747-32270ce1f642'::uuid, 1, 'Mark Harris', 'Mark Harris', '20261103NC35390', '63306', 'GOP', 147687, 50.36, 'won', 'called', 'exact-full-name', NULL, true),
  ('nc', 'Congressional District 9', 'U.S. Representative', 'f2d5c863-a55c-4bed-a4c5-0dcaa490b90a'::uuid, '7e646800-02dc-4edf-844f-c4996becf7d2'::uuid, 1, 'Richard Hudson', 'Richard Hudson', '20261103NC34975', '61758', 'GOP', 133196, 48.85, 'lost', 'called', 'exact-full-name', NULL, true),
  ('nc', 'Congressional District 9', 'U.S. Representative', 'f2d5c863-a55c-4bed-a4c5-0dcaa490b90a'::uuid, 'ceb86b22-dfae-4541-9072-f5a11b0f4876'::uuid, 1, 'Richard Ojeda', 'Richard Ojeda', '20261103NC34975', '169336', 'Dem', 139486, 51.15, 'won', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 13', 'U.S. Representative', '7528fbba-c2ac-4009-b9e4-4fd9a13488d0'::uuid, '9652ea72-5a36-404b-947b-6c5478a768e6'::uuid, 1, 'Brad Knott', 'Brad Knott', '20261103NC35753', '160591', 'GOP', 152855, 48.04, 'lost', 'called', 'exact-full-name', NULL, true),
  ('nc', 'Congressional District 13', 'U.S. Representative', '7528fbba-c2ac-4009-b9e4-4fd9a13488d0'::uuid, '1623e3a7-18f5-42fd-bcbf-d2d61ab19b22'::uuid, 1, 'Paul Barringer', 'Paul Barringer', '20261103NC35753', '169350', 'Dem', 160839, 50.55, 'won', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 13', 'U.S. Representative', '7528fbba-c2ac-4009-b9e4-4fd9a13488d0'::uuid, 'ea560a20-c48d-45e6-9e8a-26f8d49af511'::uuid, 1, 'Steven Swinton', 'Steven Swinton', '20261103NC35753', '166380', 'Lib', 4510, 1.42, 'lost', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 14', 'U.S. Representative', 'ed9f1b08-472d-451f-a425-74412a241d27'::uuid, 'c6644e53-7015-4405-9815-abba0091e1c7'::uuid, 1, 'Lakesha Womack', 'Lakesha Womack', '20261103NC36216', '169353', 'Dem', 147935, 51.14, 'won', 'called', 'exact-full-name', NULL, false),
  ('nc', 'Congressional District 14', 'U.S. Representative', 'ed9f1b08-472d-451f-a425-74412a241d27'::uuid, '05b15642-84d0-4ef2-a2d4-92b4cb35968a'::uuid, 1, 'Tim Moore', 'Tim Moore', '20261103NC36216', '35346', 'GOP', 141362, 48.86, 'lost', 'called', 'exact-full-name', NULL, true),
  ('nj', 'Congressional District 2', 'U.S. Representative', 'bab7fa90-2102-420a-8b8f-0da4c8c655f1'::uuid, 'c9e6c1f7-110d-4a57-8186-9e74073fe8e2'::uuid, 1, 'Jefferson Van Drew', 'Jeff Van Drew', '20261103NJ31205', '56642', 'GOP', 131086, 48.08, 'lost', 'called', 'holder', NULL, true),
  ('nj', 'Congressional District 2', 'U.S. Representative', 'bab7fa90-2102-420a-8b8f-0da4c8c655f1'::uuid, '281df982-353b-4243-9435-b9f5018b7ab2'::uuid, 1, 'Zack Mullock', 'Zack Mullock', '20261103NJ31205', '172144', 'Dem', 138683, 50.87, 'won', 'called', 'exact-full-name', NULL, false),
  ('ny', 'Congressional District 1', 'U.S. Representative', 'f1415ce1-250b-49d5-afc1-b0f0f624b044'::uuid, '53576042-61e4-4564-985b-3cd7c56184fe'::uuid, 1, 'Chris Gallant', 'Christopher Gallant', '20261103NY36581', '174317', 'Dem', 145869, 48.85, 'lost', 'called', 'reviewed', NULL, false),
  ('ny', 'Congressional District 1', 'U.S. Representative', 'f1415ce1-250b-49d5-afc1-b0f0f624b044'::uuid, '91ac17bb-4199-4d05-98bb-697873bb4925'::uuid, 1, 'Nick LaLota', 'Nicholas LaLota', '20261103NY36581', '71409', 'GOP', 152546, 51.09, 'won', 'called', 'ap-nickname', NULL, true),
  ('ny', 'Congressional District 2', 'U.S. Representative', '05d23321-9f87-412e-9b21-34c812b16c4d'::uuid, 'e5df5e51-9ac7-43d5-9397-df2c90845453'::uuid, 1, 'Andrew R. Garbarino', 'Andrew Garbarino', '20261103NY36582', '68984', 'GOP', 128200, 51.55, 'won', 'called', 'exact-first-last', NULL, true),
  ('ny', 'Congressional District 2', 'U.S. Representative', '05d23321-9f87-412e-9b21-34c812b16c4d'::uuid, '479a4cfc-0788-4280-ac43-59f1aeae0dec'::uuid, 1, 'Patrick Halpin', 'Patrick Halpin', '20261103NY36582', '174320', 'Dem', 120299, 48.37, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ny', 'Congressional District 17', 'U.S. Representative', '82d021d3-f4e9-4465-a5e9-d2ef8358df34'::uuid, 'f55826fe-f730-4702-8164-e3c916ec0776'::uuid, 1, 'Cait Conley', 'Cait Conley', '20261103NY36597', '174325', 'Dem', 167242, 52.96, 'won', 'called', 'exact-full-name', NULL, false),
  ('ny', 'Congressional District 17', 'U.S. Representative', '82d021d3-f4e9-4465-a5e9-d2ef8358df34'::uuid, '1b061ed5-22f4-4628-b733-5af23cf38405'::uuid, 1, 'Michael Lawler', 'Mike Lawler', '20261103NY36597', '71449', 'GOP', 148187, 46.93, 'lost', 'called', 'holder', NULL, true),
  ('ny', 'Congressional District 21', 'U.S. Representative', '6cd0af96-9d2f-4990-9a78-036d60fc2f40'::uuid, '7c443bb5-84df-4489-800f-021a9e9cfb5d'::uuid, 1, 'Anthony Constantino', 'Anthony Constantino', '20261103NY36601', '174348', 'GOP', 140676, 50.8, 'won', 'called', 'exact-full-name', NULL, false),
  ('ny', 'Congressional District 21', 'U.S. Representative', '6cd0af96-9d2f-4990-9a78-036d60fc2f40'::uuid, '29c47ba1-2a42-4573-a3ff-ec877d825214'::uuid, 1, 'Blake Gendebien', 'Blake Gendebien', '20261103NY36601', '174330', 'Dem', 135579, 48.96, 'lost', 'called', 'exact-full-name', NULL, false),
  ('oh', 'Congressional District 10', 'U.S. Representative', '29948b99-ac91-48b3-82a5-5970f6a10ed5'::uuid, '70739b84-24eb-4898-ae65-c97078eeb814'::uuid, 1, 'Kristina Knickerbocker', 'Kristina Knickerbocker', '20261103OH36033', '170962', 'Dem', 149024, 49.34, 'won', 'called', 'exact-full-name', NULL, false),
  ('oh', 'Congressional District 10', 'U.S. Representative', '29948b99-ac91-48b3-82a5-5970f6a10ed5'::uuid, '201b4162-799a-41b8-b959-ef9708f91b55'::uuid, 1, 'Michael R. Turner', 'Mike Turner', '20261103OH36033', '1376', 'GOP', 144086, 47.71, 'lost', 'called', 'holder', NULL, true),
  ('sc', 'Congressional District 1', 'U.S. Representative', '928bdc00-0fed-47e9-b3bb-0d8463257635'::uuid, '47ba3ef3-e592-4833-8173-14d36758b646'::uuid, 1, 'Bill Reeside', 'Bill Reeside', '20261103SC41922', '177982', 'Lib', 5351, 1.64, 'lost', 'certified', 'exact-full-name', NULL, false),
  ('sc', 'Congressional District 1', 'U.S. Representative', '928bdc00-0fed-47e9-b3bb-0d8463257635'::uuid, 'ca63c101-5784-4212-96b0-983094f1bc7f'::uuid, 1, 'Jenny Costa Honeycutt', 'Jenny Costa Honeycutt', '20261103SC41922', '172886', 'GOP', 158751, 48.63, 'lost', 'certified', 'exact-full-name', NULL, false),
  ('sc', 'Congressional District 1', 'U.S. Representative', '928bdc00-0fed-47e9-b3bb-0d8463257635'::uuid, 'e92dc6d7-134d-486e-9f95-418c0a2f4720'::uuid, 1, 'Nancy Lacore', 'Nancy Lacore', '20261103SC41922', '172882', 'Dem', 162103, 49.66, 'won', 'certified', 'exact-full-name', NULL, false),
  ('sc', 'Congressional District 2', 'U.S. Representative', 'ba08d958-2571-46f6-9dc0-b8d8b3a70f38'::uuid, 'e53af66a-ccda-447e-8774-0cb5fee9a02e'::uuid, 1, 'Dayna Alane Smith', 'Dayna Smith', '20261103SC41003', '177983', 'SCW', 3673, 1.24, 'lost', 'certified', 'ap-nickname', NULL, false),
  ('sc', 'Congressional District 2', 'U.S. Representative', 'ba08d958-2571-46f6-9dc0-b8d8b3a70f38'::uuid, '34706ff6-7960-484f-a675-965275d5aa08'::uuid, 1, 'Joe Wilson', 'Joe Wilson', '20261103SC41003', '1410', 'GOP', 147785, 49.8, 'won', 'certified', 'exact-full-name', NULL, true),
  ('sc', 'Congressional District 2', 'U.S. Representative', 'ba08d958-2571-46f6-9dc0-b8d8b3a70f38'::uuid, '23243653-d820-4971-8f2d-e035c15b7fc4'::uuid, 1, 'Zyon Khalifa', 'Zyon Khalifa', '20261103SC41003', '172893', 'Dem', 144945, 48.85, 'lost', 'certified', 'exact-full-name', NULL, false),
  ('tn', 'Congressional District 7', 'U.S. Representative', '47d3a5b5-0916-404b-a92c-8f46efa88029'::uuid, 'f9074a16-0c11-4add-b2ee-216b8b576189'::uuid, 1, 'Andrew J. Koontz', 'Andrew Koontz', '20261103TN43017', '178788', 'Ind', 2603, 1.08, 'lost', 'called', 'exact-first-last', 'advanced', false),
  ('tn', 'Congressional District 7', 'U.S. Representative', '47d3a5b5-0916-404b-a92c-8f46efa88029'::uuid, 'e9ae9a9c-e39c-483d-add0-42c8a443f978'::uuid, 1, 'Darden Copeland', 'Darden Copeland', '20261103TN43017', '169085', 'Dem', 115867, 48.1, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('tn', 'Congressional District 7', 'U.S. Representative', '47d3a5b5-0916-404b-a92c-8f46efa88029'::uuid, 'b69e94f9-c9cc-4160-ba4e-87b2ff041115'::uuid, 1, 'Lowell Reynolds', 'Lowell Reynolds', '20261103TN43017', '178789', 'Ind', 1316, 0.55, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('tn', 'Congressional District 7', 'U.S. Representative', '47d3a5b5-0916-404b-a92c-8f46efa88029'::uuid, 'ffbd114c-7942-4018-8e4d-72bb8145b316'::uuid, 1, 'Matt Van Epps', 'Matt Van Epps', '20261103TN43017', '169074', 'GOP', 121100, 50.27, 'won', 'called', 'exact-full-name', 'advanced', true),
  ('tn', 'Congressional District 9', 'U.S. Representative', '8f437a2a-eb56-4570-b007-69d95563bf8d'::uuid, '8869695a-138a-4d6f-a781-3fb66260db61'::uuid, 1, 'Brent Taylor', 'Brent Taylor', '20261103TN43020', '147801', 'GOP', 111968, 49.63, 'won', 'called', 'exact-full-name', 'advanced', false),
  ('tn', 'Congressional District 9', 'U.S. Representative', '8f437a2a-eb56-4570-b007-69d95563bf8d'::uuid, 'e0613afe-6591-4bc5-ba43-26c9f8cbd3e3'::uuid, 1, 'Dennis Clark', 'Dennis Clark', '20261103TN43020', '69622', 'Ind', 2413, 1.07, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('tn', 'Congressional District 9', 'U.S. Representative', '8f437a2a-eb56-4570-b007-69d95563bf8d'::uuid, '5273ca75-fe58-48d4-b6a4-55d1d4f3663c'::uuid, 1, 'Justin J. Pearson', 'Justin Pearson', '20261103TN43020', '165260', 'Dem', 109429, 48.5, 'lost', 'called', 'exact-first-last', 'advanced', false),
  ('tn', 'Congressional District 9', 'U.S. Representative', '8f437a2a-eb56-4570-b007-69d95563bf8d'::uuid, '191d6401-19ca-4603-9600-52836deb56fa'::uuid, 1, 'Michelle Davis Head', 'Michelle Davis Head', '20261103TN43020', '178794', 'Ind', 1804, 0.8, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('ut', 'Congressional District 2', 'Representative', 'aa725a83-c6d6-4846-91f2-e307fdba7dd0'::uuid, 'd22bc828-827b-45ad-9707-b55e8eff926a'::uuid, 1, 'Blake Moore', 'Blake Moore', '20261103UT45670', '68817', 'GOP', 127143, 50.02, 'won', 'called', 'exact-full-name', NULL, true),
  ('ut', 'Congressional District 2', 'Representative', 'aa725a83-c6d6-4846-91f2-e307fdba7dd0'::uuid, '61e76b24-801e-4a32-b68a-a74eaec0f7e5'::uuid, 1, 'Carlton E. Bowen', 'Carlton Bowen', '20261103UT45670', '167349', 'IAP', 8432, 3.32, 'lost', 'called', 'exact-first-last', NULL, false),
  ('ut', 'Congressional District 2', 'Representative', 'aa725a83-c6d6-4846-91f2-e307fdba7dd0'::uuid, '1b987730-a4a3-461b-b596-b77ba4e66f3f'::uuid, 1, 'Daniel Cottam', 'Daniel Cottam', '20261103UT45670', '68829', 'Lib', 4566, 1.8, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ut', 'Congressional District 2', 'Representative', 'aa725a83-c6d6-4846-91f2-e307fdba7dd0'::uuid, '85a71b4f-56e9-4d36-a609-927ab47839f4'::uuid, 1, 'Peter Crosby', 'Peter Crosby', '20261103UT45670', '174361', 'Dem', 107530, 42.3, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ut', 'Congressional District 2', 'Representative', 'aa725a83-c6d6-4846-91f2-e307fdba7dd0'::uuid, 'defe8a28-e8ba-4ea2-af8e-abe70395e9cb'::uuid, 1, 'Robert M. Moesinger', 'Robert Moesinger', '20261103UT45670', '179146', 'Una', 6517, 2.56, 'lost', 'called', 'exact-first-last', NULL, false),
  ('ut', 'Congressional District 4', 'Representative', '49abd5a1-685f-40ea-9dcf-9b02076de58b'::uuid, '99231c2e-5c35-4984-8bd7-afded67f8822'::uuid, 1, 'Jonny Larsen', 'Jonny Larsen', '20261103UT49548', '174366', 'Dem', 103867, 38.96, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ut', 'Congressional District 4', 'Representative', '49abd5a1-685f-40ea-9dcf-9b02076de58b'::uuid, '48dde82e-0085-4beb-8b50-936530f11fd0'::uuid, 1, 'Mike Kennedy', 'Mike Kennedy', '20261103UT49548', '67064', 'GOP', 142547, 53.47, 'won', 'called', 'exact-full-name', NULL, true),
  ('ut', 'Congressional District 4', 'Representative', '49abd5a1-685f-40ea-9dcf-9b02076de58b'::uuid, 'e178acf2-86be-4479-bf22-cc7ae24ca112'::uuid, 1, 'Steven Burt', 'Steven Burt', '20261103UT49548', '177893', 'Una', 11528, 4.32, 'lost', 'called', 'exact-full-name', NULL, false),
  ('ut', 'Congressional District 4', 'Representative', '49abd5a1-685f-40ea-9dcf-9b02076de58b'::uuid, 'cc7b8bc8-76ad-4667-8dd2-8c1c2a1bcf87'::uuid, 1, 'Taylor Wright', 'Taylor Wright', '20261103UT49548', '177892', 'Lib', 8648, 3.24, 'lost', 'called', 'exact-full-name', NULL, false),
  ('va', 'Congressional District 1', 'U.S. Representative', '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, '1f09e27a-8785-4fe8-8228-4ea5e0b061be'::uuid, 1, 'Rob Wittman', 'Robert Wittman', '20261103VA47001', '57798', 'GOP', 199744, 48.46, 'lost', 'called', 'ap-nickname', NULL, true),
  ('va', 'Congressional District 1', 'U.S. Representative', '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, 'f8ebb3f4-0278-4447-adb1-237a3c149d65'::uuid, 1, 'Shannon Taylor', 'Shannon Taylor', '20261103VA47001', '168785', 'Dem', 211423, 51.29, 'won', 'called', 'exact-full-name', NULL, false),
  ('va', 'Congressional District 5', 'U.S. Representative', '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, '4d7b9bc1-ea59-407c-afdd-0e568e9c2002'::uuid, 1, 'John McGuire', 'John McGuire', '20261103VA47009', '148085', 'GOP', 183775, 50.2, 'won', 'called', 'exact-full-name', NULL, true),
  ('va', 'Congressional District 5', 'U.S. Representative', '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, '4ae4fbf3-65c6-4dbe-8168-181f22cb07f7'::uuid, 1, 'Tom Perriello', 'Tom Perriello', '20261103VA47009', '59015', 'Dem', 175631, 47.98, 'lost', 'called', 'exact-full-name', NULL, false),
  ('wa', 'Congressional District 4', 'U.S. Representative', 'a5a3936e-4339-450d-96e8-518f8567dc2e'::uuid, '3d041480-e27d-4574-bbc3-81fad5ce66de'::uuid, 1, 'Amanda McKinney', 'Amanda McKinney', '20261103WA48011', '176055', 'GOP', 128950, 53.91, 'won', 'called', 'exact-full-name', 'advanced', false),
  ('wa', 'Congressional District 4', 'U.S. Representative', 'a5a3936e-4339-450d-96e8-518f8567dc2e'::uuid, '7a72ee89-e18e-406b-bfef-2434d018bc24'::uuid, 1, 'John Duresky', 'John Duresky', '20261103WA48011', '176056', 'Dem', 109679, 45.86, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('wa', 'Congressional District 5', 'U.S. Representative', '4a654ab8-6bae-43e5-a00b-1e90984e573e'::uuid, 'ae2f6067-247c-439f-b255-44941223199c'::uuid, 1, 'Carmela Conroy', 'Carmela Conroy', '20261103WA48013', '165728', 'Dem', 147897, 48.09, 'lost', 'called', 'exact-full-name', 'advanced', false),
  ('wa', 'Congressional District 5', 'U.S. Representative', '4a654ab8-6bae-43e5-a00b-1e90984e573e'::uuid, '16a00600-bcf6-48dd-bee7-bfc13dddb2d8'::uuid, 1, 'Michael Baumgartner', 'Michael Baumgartner', '20261103WA48013', '62292', 'GOP', 158539, 51.55, 'won', 'called', 'exact-full-name', 'advanced', true);

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
  IF n <> 111 THEN RAISE EXCEPTION 'expected 111 measured candidacies, the file carries %', n; END IF;
  SELECT count(DISTINCT race_id) INTO n FROM called;
  IF n <> 41 THEN RAISE EXCEPTION 'expected 41 races, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'won';
  IF n <> 41 THEN RAISE EXCEPTION 'expected 41 winners, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE outcome = 'lost';
  IF n <> 70 THEN RAISE EXCEPTION 'expected 70 losers, the file carries %', n; END IF;

  -- POSITIVE CONTROL. Every "no mismatch found" below is vacuous if the comparison cannot see
  -- anything at all, so prove it can before trusting its silence.
  PERFORM 1 FROM essentials.race_candidates
   WHERE pg_temp.namekey(full_name) = pg_temp.namekey('Nancy Lacore');
  IF NOT FOUND THEN RAISE EXCEPTION 'the name comparison cannot see a candidacy known to exist - every name gate below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM before_image;
  IF n <> 111 THEN RAISE EXCEPTION 'the before-image sees % of the 111 rows this file names - a gate that reads the wrong rows proves nothing', n; END IF;

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

  -- the race must be a 2026-11-03 US House race, or this file is writing somewhere else
  SELECT count(*) INTO n
    FROM called c JOIN essentials.races r ON r.id = c.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date <> DATE '2026-11-03' OR d.district_type <> 'NATIONAL_LOWER';
  IF n <> 0 THEN RAISE EXCEPTION '% pinned rows are not in a 2026-11-03 US House race', n; END IF;

  -- 🔴 WINNERS PER RACE MUST EQUAL races.seats. Every US House seat elects one member, so this
  --   is 1 everywhere - but it is read from races.seats, not assumed.
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
  IF n <> 0 THEN RAISE EXCEPTION '% rows this file writes already carry a certainty - another pass reached them first', n; END IF;

  -- and the prior value must be exactly the one recorded in the header, or somebody has
  -- written here since the analysis was taken
  SELECT string_agg(b.full_name || ': file says ' || coalesce(c.prior_result, 'NULL')
                    || ', production says ' || coalesce(b.result, 'NULL'), ', ') INTO txt
    FROM called c JOIN before_image b ON b.rc_id = c.rc_id
   WHERE coalesce(b.result, '') <> coalesce(c.prior_result, '');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior values have moved since this file was generated: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced';
  IF n <> 29 THEN RAISE EXCEPTION 'expected 29 rows carrying advanced, production has %', n; END IF;
  SELECT count(*) INTO n FROM before_image WHERE result = 'advanced' AND coalesce(result_source, '') = '';
  IF n <> 0 THEN RAISE EXCEPTION '% advanced rows carry no citation to preserve', n; END IF;

  -- 🔴 THE 'holder' BASIS IS ONLY SOUND IF PRODUCTION STILL AGREES WITH IT.
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE c.match_basis = 'holder'
     AND (och.politician_id IS NULL OR rc.politician_id IS NULL OR och.politician_id <> rc.politician_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'rows matched on the incumbent basis are no longer the seat holder: %', txt; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder';
  IF n <> 6 THEN RAISE EXCEPTION 'expected 6 rows on the incumbent basis, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'holder' AND NOT ap_incumbent;
  IF n <> 0 THEN RAISE EXCEPTION '% rows claim the incumbent basis while AP does not flag them incumbent', n; END IF;

  -- 🔴🔴 EVERY NON-EXACT MATCH THAT WON MUST BE A SITTING MEMBER THE VIEW INDEPENDENTLY NAMES.
  --   This is the gate that bounds what a bad relaxed match could cost: a wrong one would hand
  --   a seat to the wrong person, so no winner may rest on a name comparison alone.
  SELECT string_agg(c.our_name || ' (' || c.district || ')', ', ') INTO txt
    FROM called c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = r.office_id
   WHERE c.outcome = 'won' AND c.match_basis <> 'exact-full-name'
     AND (NOT c.ap_incumbent OR och.politician_id IS NULL OR rc.politician_id IS NULL
          OR och.politician_id <> rc.politician_id);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a winner matched on a non-exact basis is not independently confirmed as the seat holder: %', txt; END IF;

  -- 🔴 NO TOKEN MATCH MAY APPEAR IN THIS FILE. CC_0402 had to defend three; this one has none,
  --   and the CHECK on match_basis above makes the claim structural rather than a comment.
  SELECT count(*) INTO n FROM called WHERE match_basis = 'ap-nickname';
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 rows on AP''s own nickname/middle fields, the file carries %', n; END IF;
  SELECT count(*) INTO n FROM called WHERE match_basis = 'reviewed';
  IF n <> 1 THEN RAISE EXCEPTION 'expected 1 hand-reviewed row, the file carries %', n; END IF;

  -- 🔴🔴 THE 'certified' CLAIM IS SCOPED, because it asserts a canvass and not a call.
  SELECT count(*) INTO n FROM called WHERE certainty = 'certified';
  IF n <> 6 THEN RAISE EXCEPTION 'expected 6 certified rows, the file carries %', n; END IF;
  SELECT string_agg(DISTINCT c.ap_race_id, ', ') INTO txt FROM called c
   WHERE c.certainty = 'certified' AND c.ap_race_id NOT IN ('20261103SC41922', '20261103SC41003');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race claims certification this file holds no state source for: %', txt; END IF;
  SELECT count(*) INTO n FROM called WHERE certainty = 'certified' AND state <> 'sc';
  IF n <> 0 THEN RAISE EXCEPTION '% certified rows are outside South Carolina, which is the only state this file read a canvass for', n; END IF;
  SELECT count(*) INTO n FROM called WHERE certainty = 'called';
  IF n <> 105 THEN RAISE EXCEPTION 'expected 105 called rows, the file carries %', n; END IF;

  RAISE NOTICE 'pre-checks passed: % candidacies across % races, % won, % lost, % certified',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called),
    (SELECT count(*) FROM called WHERE outcome = 'won'), (SELECT count(*) FROM called WHERE outcome = 'lost'),
    (SELECT count(*) FROM called WHERE certainty = 'certified');
END $$;

-- ─── 3. The write ───
-- 🔴 The existing citation is APPENDED, read from the LIVE column rather than from this file's
--    copy of it, so a row somebody has re-cited since the analysis keeps whatever it now says.
UPDATE essentials.race_candidates rc
   SET result = c.outcome,
       result_certainty = c.certainty,
       result_source = 'Associated Press race call for the 2026-11-03 general election, read '
         || '2026-11-12 from AP''s own national results feed '
         || '(interactives.apelections.org/election-results/data-live/2026-11-03/results/national/'
         || ', race ' || c.ap_race_id || ', candidate ' || c.ap_candidate_id
         || '): ' || c.ap_name || coalesce(' (' || c.party || ')', '') || ' '
         || c.votes || ' votes, ' || c.pct || '%, recorded as ' || c.outcome
         || '. AP had not called this race when CC_0350 was written.'
         || CASE WHEN c.certainty = 'certified'
                 THEN ' AP reports this race as CERTIFIED (isCertified = true, tabulationStatus '
                      || '''Vote Certified'', 100% of the expected vote). Confirmed against the '
                      || 'South Carolina Election Commission''s own results service '
                      || '(enr-scvotes.org, read 2026-11-12), which publishes the same four '
                      || 'ballot lines with the same counts and reports every county certified. '
                      || 'This is a CANVASS and not only a call.'
                 ELSE ' This is AP''s call and NOT the state canvass; AP reports this race as '
                      || 'not yet certified.' END
         || ' Matched to our row on basis ''' || c.match_basis || '''.'
         || CASE WHEN c.match_basis = 'ap-nickname'
                 THEN ' AP publishes this candidate''s nickname and middle name as their own '
                      || 'fields; the match reads those fields rather than relaxing the name.'
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
   WHERE rc.result = c.outcome AND rc.result_certainty = c.certainty;
  IF n <> 111 THEN RAISE EXCEPTION 'expected 111 rows written, % carry the outcome and certainty this file states', n; END IF;

  -- every row must cite the AP race it came from, by id
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE position(c.ap_race_id in coalesce(rc.result_source, '')) = 0;
  IF n <> 0 THEN RAISE EXCEPTION '% written rows do not name the AP race they came from', n; END IF;

  -- 🔴 THE 29 PRESERVED CITATIONS MUST SURVIVE VERBATIM. There is no history table: if
  --   this fails after a change to the UPDATE, those citations are gone for good.
  SELECT string_agg(b.full_name, ', ') INTO txt
    FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> ''
     AND position(b.result_source in coalesce(rc.result_source, '')) = 0;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'prior citations were destroyed rather than appended: %', txt; END IF;
  SELECT count(*) INTO n FROM before_image b JOIN essentials.race_candidates rc ON rc.id = b.rc_id
   WHERE coalesce(b.result_source, '') <> '' AND position(b.result_source in rc.result_source) > 0;
  IF n <> 29 THEN RAISE EXCEPTION 'expected 29 preserved citations, found %', n; END IF;

  -- the certified rows must say so, and must name the state source that justifies the word
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN called c ON c.rc_id = rc.id
   WHERE c.certainty = 'certified'
     AND position('enr-scvotes.org' in coalesce(rc.result_source, '')) > 0
     AND position('CANVASS' in coalesce(rc.result_source, '')) > 0;
  IF n <> 6 THEN RAISE EXCEPTION 'expected 6 certified rows citing the state canvass, found %', n; END IF;

  -- 🔴 RECORDING A RESULT SEATS NOBODY. These members take office on 2027-01-03; if this file
  --   has moved an officeholder, it has done something it does not claim to do.
  SELECT count(*) INTO n FROM occupancy_before;
  IF n = 0 THEN RAISE EXCEPTION 'the occupancy snapshot is empty - the comparison below would pass vacuously'; END IF;
  SELECT string_agg(x.office_id::text, ', ') INTO txt FROM (
    SELECT coalesce(b.office_id, a.office_id) AS office_id
      FROM occupancy_before b
      FULL JOIN essentials.office_current_holder a ON a.office_id = b.office_id
     WHERE b.office_id IS NOT NULL
       AND a.politician_id IS DISTINCT FROM b.politician_id
  ) x;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the current officeholder changed for office(s) % - this file seats nobody', txt; END IF;

  -- 🔴 NOTHING OUTSIDE THE PINNED SET MAY HAVE BEEN WRITTEN, and the only honest form of that
  --   claim is a count: CC_0350 and its follow-ups legitimately carry calls here.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type = 'NATIONAL_LOWER'
     AND rc.result_certainty = 'called'
     AND rc.id NOT IN (SELECT rc_id FROM called);
  IF n <> 913 THEN RAISE EXCEPTION 'expected the 913 rows called before this file beside its own, found %', n; END IF;

  -- 🔴🔴 'certified' MUST EXIST NOWHERE ELSE IN THE 2026-11-03 GENERAL. The scope matters and an
  --   earlier draft of this gate got it wrong: the word is already used 489 times for the 2026
  --   primaries and the spring municipal generals, so a repo-wide "zero" is false and the gate
  --   fired on its own header. Across the 53 elections held on 2026-11-03, nothing carried it.
  --   If another pass has started writing it there, the scoping argument above is no longer true
  --   and this file must be re-read before it is trusted.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03'
     AND rc.result_certainty = 'certified' AND rc.id NOT IN (SELECT rc_id FROM called);
  IF n <> 0 THEN RAISE EXCEPTION '% rows outside this file claim certification for 2026-11-03 - nothing did when this file was written', n; END IF;

  -- the tier's own number, which is what this file exists to move
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type = 'NATIONAL_LOWER' AND rc.result = 'won';
  IF n <> 422 THEN RAISE EXCEPTION 'expected 422 US House winners after this file, found %', n; END IF;

  -- 🔴 THE OCCUPANCY DRIFT BASELINE. This file creates no office, so the unflagged count must
  --   not have moved. Asserted rather than assumed, because a baseline nobody checks is a
  --   baseline that moves under the next author.
  SELECT count(*), count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE NOT o.is_vacant)
    INTO total, flagged, unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF unflagged <> 238 THEN RAISE EXCEPTION 'occupancy drift baseline moved: % unflagged, expected 238 (total %, flagged %)', unflagged, total, flagged; END IF;

  RAISE NOTICE 'CC_0406 done: % candidacies across % races, 41 won / 70 lost, 6 certified; tier now 422 winners; occupancy % / % / %',
    (SELECT count(*) FROM called), (SELECT count(DISTINCT race_id) FROM called), total, flagged, unflagged;
END $$;

DROP TABLE IF EXISTS before_image;
DROP TABLE IF EXISTS occupancy_before;

COMMIT;

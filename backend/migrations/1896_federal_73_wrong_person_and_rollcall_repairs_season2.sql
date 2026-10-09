-- 1896_federal_73_wrong_person_and_rollcall_repairs_season2.sql
-- The 73 federal keys that the 2026-08-11 Tier B pass had NEVER AUDITED -- the last cell of the
-- cross-tab from ev-accounts #897, and the last of the federal generic-sourcing block.
--
-- OUTCOME ON THE 73: 42 blanks, 14 citation repairs, 12 sound, 5 blocked.
-- PLUS 23 BLANKS AND 2 BLOCKED KEYS THAT WERE NEVER IN THE 73 AT ALL -- see below, because that
-- is the finding, not a footnote.
--   73 context + 73 answer rows INSERTED into Season 2; 6 existing Season 2 keys UPDATED in place.
--   SEASON 1 IS NOT TOUCHED. Nothing is deleted.
--
-- 🔴 WHY A FORWARD WRITE. Season 1 is CLOSED and IMMUTABLE -- inform.closed_season_is_immutable()
-- rejects any write there and its own error text names the remedy: write in the OPEN season,
-- which shadows the old row on read without destroying history. Shape as 1870, 1893, 1894.
-- 🔑 A BLANK IS `value 0` INSERTED, NEVER A DELETE -- a deleted Season 2 row falls back to
-- Season 1 and the bad chair stays visible (CC_0057). Every blank below CARRIES THE SOURCES IT
-- EXAMINED (migration 1887's rule).
--
-- ══ THE FINDING: WRONG-PERSON CONTAMINATION ═══════════════════════════════════════════════════
-- These rows are not weakly sourced. 40 of them are SOMEBODY ELSE'S RESEARCH filed under the
-- wrong candidate, and the misassignments chain:
--
--     Mike Collins (GA, R) ──> Janak Joshi (CO, R) ──> Alex Vindman (FL, D)
--     Mike Collins (GA, R) ──> Angie Nixon (FL, D)
--     Alex Vindman (FL, D) ──> David Roth (ID, D) ──> Zach Wahls (IA, D)
--
-- Each link is proved from the cited page itself, with a control term so that an absence is
-- evidence and not a claim about the method:
--   * en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about a retired physician who
--     sat in the Colorado House 2011-2017. "Joshi" 11 hits, "Colorado" 8, "Vindman" 0,
--     "Florida" 0. Alex Vindman's six chairs rest on it, and call a Democrat a "Conservative
--     Republican" -- including rung 5, the most extreme rung, on religious freedom.
--   * en.wikipedia.org/wiki/Alexander_Vindman redirects to the article on Alex Vindman.
--     "Vindman" 84 hits, "David Roth" 0. All ten of David Roth's chairs rest on it and recite
--     Vindman's biography -- "testified against presidential abuse of power" -- as Roth's.
--   * rothforidaho.org/solutions/ is headed "SOLUTIONS - David Roth for Idaho". "Idaho" 16 hits,
--     "Wahls" 0, "Iowa" 0. Ten of Zach Wahls's chairs rest on it.
--   * The 2026 Georgia Senate race article: "Georgia" 132 hits, "Angie Nixon" 0, "Joshi" 0. It
--     records the CPAC and Veterans for America First endorsements of Mike Collins that Nixon's
--     rows recite, and it names Collins as the Republican nominee.
--   * Janak Joshi's twelve rows cite ontheissues.org/Senate/Mike_Collins.htm. 🔑 THE DECISIVE
--     TEST NEEDS NEITHER PAGE: his reasoning attributes CONGRESSIONAL acts to him ("opposed
--     Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never served in
--     Congress. Mike Collins has.
-- The database's own records agree: Angie Nixon and Alex Vindman are Florida Senate candidates
-- and Democrats; Janak Joshi is a separate row, Colorado and Republican; Zach Wahls is Iowa and
-- David Roth is Idaho. Six of Joshi's twelve borrowed chairs sit at rung 5.
--
-- 🔴🔴 ONLY 19 OF THESE 40 ROWS WERE EVER IN A QUEUE, AND THAT IS THE LESSON. The generic-source
-- detector asks "is this a generic profile page?" -- so it can only see the contamination that
-- happens to arrive on a generic-looking URL. A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-
-- LOOKING SOURCE THERE IS: Zach Wahls's ten rothforidaho.org rows score perfectly clean, and 2 of
-- his 12 reached the queue. Janak Joshi, whose every row is Mike Collins's, was in NO queue at
-- all; he was found by probing, not by sorting. The repair unit here is the PERSON, not the key.
--
-- Measured corpus-wide (37,259 context rows) so the scale is known and not guessed:
--   a cited person-article sharing no name token with the row it is filed under -> 27 rows,
--   25 keys, 10 politicians; a race article for the wrong state -> 10 rows; reasoning asserting
--   a party the politician's own party field contradicts -> 13 rows. The federal part is fixed
--   here. What is left is LOCAL and is recorded for the non-federal queue, not touched:
--   Katy Yaroslavsky <- Sheila Kuehl (3), Steve Bennett <- Suzette Martinez Valladares (2),
--   Liz Ortega <- Laura Richardson (1), Eddie Morales and Elizabeth Campos <- Dustin Burrows (1
--   each). Also not touched: N'Kiyla Thomas (OK) cites jasmineforok.com, and Gary Crockett (LA)
--   has no source naming him -- both are candidate-cohort work, not federal officeholders.
--
-- ══ THE 14 REPAIRS: a bad citation is not a false claim ═══════════════════════════════════════
-- NONE OF THESE MOVES A CHAIR. Each rests on a roll call verified from the Clerk's own XML,
-- parsing the OVERALL <totals-by-vote> block (<totals-by-party> comes FIRST in the file) and
-- checking the per-member tally equals the declared totals before reading anyone's vote.
--   Frederica Wilson W000808 D-FL (the sheet distinguishes her from Wilson (SC) on every vote):
--     roll 2021/62  H.R. 1   For the People Act          220-210 Yea -> campaign-finance, redistricting
--     roll 2021/385 H.R. 5376 Build Back Better Act      220-213 Yea -> childcare
--     roll 2021/39  H.R. 5   Equality Act                224-206 Yea -> religious-freedom
--     roll 2021/91  H.R. 6   Dream Act                   228-197 Yea -> deportation
--     roll 2025/23  S. 5     Laken Riley Act             263-156 Nay -> deportation
--     roll 2022/420 H.R. 5376 Inflation Reduction Act    220-207 Yea -> taxes
--   Mike Flood F000474 R-NE: rolls 2025/23 Yea, 2025/145 Yea, 2025/190 Aye, 2023/192 Yea.
--   Jay Obernolte O000019 R-CA: roll 2023/192 Yea (H.R. 734, 219-203).
--   James Himes H001047 D-CT: roll 2022/513 Yea (Respect for Marriage Act, 258-169).
--   Nikema Williams W000788 D-GA: roll 2024/151 Yea (H.R. 8035, 311-112).
--   André Carson: original cosponsor, H.R. 15 Equality Act (119th and 118th).
--
-- 🔴🔴 ONE ROW CITED A BILL ITS SUBJECT VOTED AGAINST. Nikema Williams's Ukraine chair was
-- sourced to the 21st Century Peace Through Strength Act (H.R. 8038) -- and the Clerk records her
-- voting NAY on it (roll 2024/145, 360-58). H.R. 8038 was the sanctions-and-TikTok piece of the
-- April 2024 package, not the Ukraine aid appropriation. She voted YEA on the actual aid bill,
-- H.R. 8035, roll 151, 311-112. Retiring on the citation would have been wrong; trusting the
-- citation would have left an inverted row. Only the primary record separates the two.
--
-- 🔴 TWO ROWS NAMED A BILL THAT DOES NOT CONTAIN WHAT THEY SAY. Flood's and Obernolte's
-- trans-athletes chairs rested on the One Big Beautiful Bill Act "including the Protection of
-- Women and Girls in Sports Act language". The cited OBBBA article contains ZERO occurrences of
-- "athlete" or "Protection of Women and Girls", and its only two uses of "sports" are in an
-- educator tax deduction for sports coaches. Both men voted Yea on the actual bill, H.R. 734,
-- roll 2023/192, 219-203 -- a direct and divided vote on exactly this question. Repairs, not
-- blanks, and only because the primary record was checked after the bill article failed.
--
-- ══ 🔴🔴 A REPAIR MUST NOT MOVE A CHAIR, AND IN SEASON 2 THAT IS NOT AUTOMATIC ════════════════
-- 7 of the 12 topics carrying a repair are pinned to a DIFFERENT ladder revision in Season 2
-- than in Season 1, and the re-pin was not cosmetic -- housing and same-sex-marriage rows written
-- earlier sit one rung higher in S2 than in S1 because a rung was inserted. So:
--   * where a Season 2 row already exists, it is UPDATED IN PLACE and ITS value is kept, never
--     Season 1's (Himes 1->2, Carson 1->2, and Wilson's housing row at 3, not 2);
--   * where no Season 2 row exists, the Season 1 value is only carried across after the rung's
--     OWN TEXT was compared in both revisions at that exact value. Every insert below passed:
--     childcare 2 and religious-freedom 2 are character-for-character identical across the two
--     revisions; campaign-finance 2 ("strictly limit corporate donations and dark money groups"
--     vs "Strictly limit corporate and dark-money spending") and deportation 2 and 4 are
--     rewordings; redistricting, taxes, trans-athletes, ukraine-support and healthcare are the
--     SAME revision in both seasons.
-- ⚠ ANDRÉ CARSON / CAMPAIGN-FINANCE IS BLOCKED BY THIS TEST and is the reason it exists. He is a
-- verified original cosponsor of the DISCLOSE Act of 2026 (H.R. 7802) and was seated on Season 1
-- rung 3, "require full disclosure of all political donations". SEASON 2 DELETED THAT RUNG: its
-- rung 3 reads "Keep contribution limits at current levels" and no rung on the Season 2 ladder
-- asks about disclosure at all. Carrying the number across would seat him on a position he was
-- never assessed for; picking a different number would be a new seating decision, not a citation
-- repair. The fact is verified and recorded, and belongs to the ladder-scope register.
--
-- ══ THE OTHER BLANK CLASSES ═══════════════════════════════════════════════════════════════════
-- * A RACE ARTICLE CARRIES NO POSITIONS (14 keys). Dakarai Larriett's ten rows and six of Hallie
--   Shoffner's cite only their 2026 Senate race article. Those pages name the candidate 12 and 22
--   times and contain ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate,
--   immigration, LGBT or voting -- they are candidate lists, endorsements, fundraising, polling.
--   The rows concede it themselves ("standard Democratic position", "Moderate position EXPECTED
--   for Arkansas context ... LIKELY supports reform"), and one reaches its chair "as a Black
--   Democratic candidate in Alabama" -- a chair inferred from the candidate's race and party.
-- * SELF-CONFESSED ABSENCE (2). Pressley and Moulton on data centres both open "has not taken a
--   specific public stance" and then seat a centre chair anyway. A CENTRE CHAIR IS A CLAIM, NOT A
--   NEUTRAL DEFAULT: a reader cannot tell "a moderate on this" from "nobody found anything".
-- * NO REASONING AT ALL (3 keys, 4 rows) -- AND THAT IS THE ENTIRE CLASS IN THE CORPUS. A count
--   over all 36,363 seated rows found exactly four whose reasoning is the empty string: a chair
--   shown to voters with literally nothing asserted behind it. This migration blanks all three
--   keys, so the class is closed AS READ -- the Season 1 rows keep their empty reasoning because
--   Season 1 cannot be written, and the Season 2 blank shadows them. Karen Bass / ai-regulation
--   was NOT in the 73; it is written here because leaving the third key behind would keep a
--   complete, closable class open for the sake of a queue boundary.
-- * NEAR-UNANIMOUS VOTE (1). Dingell / Ukraine rests on the Lend-Lease Act, roll 2022/141,
--   417-10, and she did vote Yea -- verified. It still cannot seat a DISTINCTIVE chair: the same
--   417-10 vote blanked Schrier in 1893 and the same rule blanked Newhouse on 385-41 in 1894.
--   The row had not looked it up either, reasoning that she "was not among the 10 dissenters".
-- * AN OMNIBUS VOTE CANNOT PIN A RUNG (1). Wilson / housing: the BBBA vote is verified, but the
--   Act carried public-housing capital AND subsidies, which are Season 2 rungs 2 and 4, while the
--   seated chair is rung 3, "build NO public housing, but set binding rules".
-- * MISDESCRIBED BILL (1). Wilson / social-security said the One Big Beautiful Bill "proposed
--   converting Social Security savings to private 'Trump accounts'". The cited article describes
--   Trump accounts as childrens' savings accounts with a $1,000 federal deposit for each citizen
--   child "with a social security NUMBER". The row appears to have read the phrase "social
--   security number" as Social Security. It also confesses: "likely cosponsored ... but no direct
--   confirmation found".
-- * ROLE PLUS A DIFFERENT QUESTION (1). Torres / misinformation: she is on the Committee on House
--   Administration and in the New Democrat Coalition, both confirmed on the cited pages -- and
--   NEITHER PAGE CONTAINS "misinformation", "disinformation" OR "content moderation", once.
-- * UNCHECKABLE AS CITED (1). Padilla / school-vouchers. ⚠ congress.gov returns HTTP 403 to
--   automated retrieval, so its member pages were NOT READ and nothing is asserted about what
--   they contain -- never cite an unfetched URL, in either direction.
--
-- ══ WHAT IS LEFT ALONE (12 sound) ═════════════════════════════════════════════════════════════
-- Christian Menefee's 8 rows quote his Ballotpedia Candidate Connection survey and all seven
-- distinctive phrases checked were found verbatim on the page; Kim Farington's abortion row the
-- same, and it correctly declines the most extreme rung for a stated reason. J.D. Vance is a
-- NAMED PLAINTIFF in NRSC v. FEC, which the cited article states outright. Frederica Wilson is a
-- listed member of the Medicare for All Caucus on the cited page -- 🔑 and a CAUSE caucus is not
-- a committee: joining one is a voluntary act declaring a position, where a committee seat is an
-- assignment. That is the line between this and the Dingell/AI subcommittee blank in 1894.
--
-- ══ BLOCKED (7) ═══════════════════════════════════════════════════════════════════════════════
-- 6 keys are on `immigration`, which has NO Season 2 pin -- the Season-1-only 1,678-stance orphan
-- topic, so no Season 2 row can legally exist and neither a blank nor a repair can be written:
-- Alex Vindman, David Roth and Janak Joshi (all wrong-person), Frederica Wilson (a verified Dream
-- Act vote), Dakarai Larriett and Hallie Shoffner. A guard below asserts that absence, so if the
-- topic ever gains a pin this migration's own note FAILS LOUDLY instead of rotting. The 7th is
-- André Carson / campaign-finance, blocked by the deleted rung described above.
--
-- ⚠ Slot 1896 reserved from the DB allocator (steward.migration_slots). Not hand-counted.
-- ⚠ `check:stance-sources` NEVER RUNS ON PRs and was run by hand before and after.

-- ── PRE-GUARDS ────────────────────────────────────────────────────────────────────────────────
DO $pre$
DECLARE n int;
BEGIN
  -- 1. the Season 1 cohort is exactly where it is expected to be, as (politician, topic, value)
  --    TRIPLES. A list of values alone would pass if two rows had swapped chairs.
  SELECT count(*) INTO n FROM (VALUES
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,2::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,1::numeric),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,3::numeric),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,3::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,5::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,5::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,1::numeric),
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,1::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,4::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,5::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,5::numeric),
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,5::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,4::numeric),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,2::numeric),
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,1::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,4::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,5::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,5::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,4::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,5::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,4::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,1::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,2::numeric),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,2::numeric),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,2::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,4::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,1::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,4::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,1::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,2::numeric),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,2::numeric)
  ) AS t(pid, tid, val)
  JOIN inform.politician_answers a
    ON a.politician_id = t.pid AND a.topic_id = t.tid AND a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND a.value = t.val;
  IF n <> 79 THEN
    RAISE EXCEPTION 'migration 1896: expected 79 Season 1 rows at their recorded chairs, found %', n;
  END IF;

  -- 2. the 73 keys being INSERTED have no Season 2 row yet
  SELECT count(*) INTO n FROM inform.politician_answers a WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid)
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1896: % of the 73 insert keys already hold a Season 2 row', n;
  END IF;

  -- 3. the 6 keys being UPDATED do hold a Season 2 row, AT THE VALUE RECORDED HERE.
  --    This is the guard that stops a repair silently re-seating someone: the value written back
  --    for a repair is this one, not Season 1's, because the Season 2 ladder may differ.
  SELECT count(*) INTO n FROM (VALUES
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,4::numeric),  -- Alex Vindman / same-sex-marriage
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,3::numeric),  -- Frederica S. Wilson / housing
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,3::numeric),  -- Pete Aguilar / housing
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,3::numeric),  -- Zach Wahls / housing
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2::numeric),  -- André Carson / same-sex-marriage
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2::numeric)   -- James A. Himes / same-sex-marriage
  ) AS t(pid, tid, val)
  JOIN inform.politician_answers a
    ON a.politician_id = t.pid AND a.topic_id = t.tid AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = t.val;
  IF n <> 6 THEN
    RAISE EXCEPTION 'migration 1896: expected 6 Season 2 rows at their recorded chairs, found %', n;
  END IF;

  -- 4. every topic written here is pinned in Season 2 (the insert carries that revision id)
  SELECT count(DISTINCT topic_id) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id IN (
    '00b95a6a-75db-4521-b523-3326bba938de'::uuid,
    '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,
    'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid,
    '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,
    'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,
    'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,
    '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,
    'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,
    '24e9212c-b011-422a-865c-093e35050901'::uuid,
    'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,
    'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,
    'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,
    '87d20824-a6e9-407b-983c-65440084a0ab'::uuid,
    'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,
    '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,
    '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,
    'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,
    '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,
    '669cac97-66a6-4087-b036-936fbe62efb3'::uuid,
    '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,
    'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,
    'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,
    '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid,
    'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,
    'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid
  );
  IF n <> 25 THEN
    RAISE EXCEPTION 'migration 1896: expected all 25 written topics pinned in Season 2, found %', n;
  END IF;

  -- 5. `immigration` still has NO Season 2 pin. Six keys are parked on that absence; if it ever
  --    gains one, this note must fail loudly rather than quietly go stale.
  SELECT count(*) INTO n FROM inform.season_questions sq
    JOIN inform.compass_topics t ON t.id = sq.topic_id
   WHERE sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND t.topic_key = 'immigration';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1896: immigration now HAS a Season 2 pin (%) -- the 6 blocked keys are writable, revisit', n;
  END IF;
END
$pre$;

-- ── 73 NEW SEASON 2 ROWS ─────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES
-- Alex Padilla / school-vouchers — blank (S1 chair 2 -> blank)
('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','00b95a6a-75db-4521-b523-3326bba938de',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','88858826-90c0-41c9-a3a4-1d9f5b8c5307', NULL,
 $r$Blanked 2026-10-07. The chair rests on one specific claim - that he cosponsored "the Strengthening Public Schools Act" - plus two generalities with no instance attached ("has spoken out against federal voucher proposals", "His Senate voting record reflects opposition"). The single cited source, his congress.gov member page, returns HTTP 403 to automated retrieval and was NOT READ; nothing is asserted here about what it does or does not contain. No bill of that name could be located through an accessible index, and the nearest real titles - "Strengthening America's Public Schools Through Promoting Foreign Investment Act" (H.R. 7132 / H.R. 3983 / S. 823) - are about foreign investment. ⚠ This is NOT a finding that the bill does not exist; it is a finding that the chair cannot be checked as cited. His cosponsorship record is public and this is cheaply re-researchable.$r$,
 ARRAY['https://www.congress.gov/member/alex-padilla/P000145']),

-- Alex Vindman / abortion — blank (S1 chair 5 -> blank)
('a2fee754-f90c-47ff-a3b7-377d55992273','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://leg.colorado.gov/legislators/janak-joshi','https://en.wikipedia.org/wiki/Janak_Joshi']),

-- Alex Vindman / civil-rights — blank (S1 chair 4 -> blank)
('a2fee754-f90c-47ff-a3b7-377d55992273','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']),

-- Alex Vindman / climate-change — blank (S1 chair 4 -> blank)
('a2fee754-f90c-47ff-a3b7-377d55992273','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']),

-- Alex Vindman / fossil-fuels — blank (S1 chair 2 -> blank)
('a2fee754-f90c-47ff-a3b7-377d55992273','a22215c3-6693-4bc2-b248-01aebba14570',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Colorado']),

-- Alex Vindman / religious-freedom — blank (S1 chair 5 -> blank)
('a2fee754-f90c-47ff-a3b7-377d55992273','6b9ba6d9-1001-43f5-b073-4d37130696fd',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi']),

-- Angie Nixon / climate-change — blank (S1 chair 4 -> blank)
('0ac89151-2b8d-4430-b9bd-3a80bef3413b','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Angie Nixon. Angie Nixon is Candidate for U.S. Senate - Florida (Democratic), a Florida state representative from Jacksonville; Mike Collins is the Republican nominee for U.S. Senate in Georgia. These rows cite the 2026 Georgia Senate race article, which contains no mention of Angie Nixon (control term "Georgia" appears 132 times, so the page was read). The reasoning describes "a Republican candidate in Georgia", uses "he", and names the endorsements the same article records for Mike Collins - CPAC and Veterans for America First. Nixon's seven other rows, sourced to her own campaign site, correctly describe a progressive Democrat, so this politician carries two different people's politics at once. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']),

-- Angie Nixon / fossil-fuels — blank (S1 chair 2 -> blank)
('0ac89151-2b8d-4430-b9bd-3a80bef3413b','a22215c3-6693-4bc2-b248-01aebba14570',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Angie Nixon. Angie Nixon is Candidate for U.S. Senate - Florida (Democratic), a Florida state representative from Jacksonville; Mike Collins is the Republican nominee for U.S. Senate in Georgia. These rows cite the 2026 Georgia Senate race article, which contains no mention of Angie Nixon (control term "Georgia" appears 132 times, so the page was read). The reasoning describes "a Republican candidate in Georgia", uses "he", and names the endorsements the same article records for Mike Collins - CPAC and Veterans for America First. Nixon's seven other rows, sourced to her own campaign site, correctly describe a progressive Democrat, so this politician carries two different people's politics at once. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']),

-- Angie Nixon / ukraine-support — blank (S1 chair 4 -> blank)
('0ac89151-2b8d-4430-b9bd-3a80bef3413b','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Angie Nixon. Angie Nixon is Candidate for U.S. Senate - Florida (Democratic), a Florida state representative from Jacksonville; Mike Collins is the Republican nominee for U.S. Senate in Georgia. These rows cite the 2026 Georgia Senate race article, which contains no mention of Angie Nixon (control term "Georgia" appears 132 times, so the page was read). The reasoning describes "a Republican candidate in Georgia", uses "he", and names the endorsements the same article records for Mike Collins - CPAC and Veterans for America First. Nixon's seven other rows, sourced to her own campaign site, correctly describe a progressive Democrat, so this politician carries two different people's politics at once. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Georgia']),

-- Ayanna Pressley / data-centers — blank (S1 chair 3 -> blank)
('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','4559b513-0fd8-4ed1-babd-f3b554162f40',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c48a03d6-b972-4f27-9a8a-d41b07f4a929', NULL,
 $r$Blanked 2026-10-07. The row opens "Pressley has NOT TAKEN A SPECIFIC PUBLIC STANCE on data center siting" and then seats a centre chair anyway, built from her district's geography ("does not have major data center development pressure") and from what she "WOULD LIKELY" do. A centre chair is a claim, not a neutral default: a reader cannot tell "she is a moderate on this" from "nobody found anything". Only a blank says the second. Its only source is her congress.gov member page, which returns HTTP 403 to automated retrieval and was not read.$r$,
 ARRAY['https://congress.gov/member/ayanna-pressley/P000617']),

-- Dakarai Larriett / abortion — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / civil-rights — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / climate-change — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / economic-development — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','eb3d1247-0de1-4b7f-baec-7259861efd53',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af855dba-96f3-4fa0-beb7-43c5edb3f499', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / healthcare — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / school-vouchers — blank (S1 chair 1 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','00b95a6a-75db-4521-b523-3326bba938de',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','88858826-90c0-41c9-a3a4-1d9f5b8c5307', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / social-security — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / taxes — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- Dakarai Larriett / voting-rights — blank (S1 chair 2 -> blank)
('98480c0b-2b26-4098-a830-a2efd88fed29','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL,
 $r$Blanked 2026-10-07. The only source on every one of these ten rows is the 2026 Alabama Senate race article. That page names Larriett twelve times and contains ZERO occurrences of abortion, Medicaid, voucher, Social Security, climate or immigration - it is a candidate list, endorsements, fundraising and polling. It cannot seat a policy chair for anyone. The reasoning says so in its own words on every row ("standard Democratic position", "as a Democrat in Alabama"), and the voting-rights row reaches its chair "as a Black Democratic candidate in Alabama" - a chair inferred from the candidate's race and party. Re-researchable from his campaign material; this is an invitation, not a verdict.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Alabama']),

-- David Roth / abortion — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / civil-rights — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / climate-change — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / healthcare — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / misinformation — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / social-security — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / taxes — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / ukraine-support — blank (S1 chair 1 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Alex_Vindman.htm','https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- David Roth / voting-rights — blank (S1 chair 2 -> blank)
('bc9ec968-d664-4987-8f9c-108f9ae51535','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Alex Vindman's research filed under David Roth. David Roth is Candidate for U.S. Senate - Idaho (Democratic), who withdrew on 2026-09-01; Alex Vindman is Candidate for U.S. Senate - Florida (Democratic). Every one of these rows is sourced to en.wikipedia.org/wiki/Alexander_Vindman, which redirects to the article on Alex Vindman and contains no mention of David Roth (control term "Vindman" appears 84 times, so the page was read). The reasoning recites Vindman's biography - "a veteran who faced retaliation for truth-telling", "testified against presidential disinformation", "someone who testified against presidential abuse of power" - and attributes it to Roth. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Alexander_Vindman']),

-- Debbie Dingell / ukraine-support — blank (S1 chair 2 -> blank)
('91d28127-8183-4b67-a1fb-dc8a150f6199','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Blanked 2026-10-07. THE VOTE IS REAL AND WAS VERIFIED, AND IT STILL CANNOT SEAT THIS CHAIR. Ukraine Democracy Defense Lend-Lease Act (S. 3522): Clerk roll 141, 28 April 2022, On Passage, 417-10 -> Dingell, D000624, D-MI: Yea. Being one of 417 is not a choice a ladder can seat - the same 417-10 vote blanked Schrier in migration 1893, and the same rule blanked Newhouse on a 385-41 vote in 1894. 🔑 The row also did not look the vote up: it reasoned that she "was not among the 10 dissenters ... indicating a yes vote", inferring a vote from absence from a dissent list. She was also NOT VOTING on the April 2024 Ukraine supplemental (rolls 150 and 151), so no divided Ukraine vote of hers is on the record here.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Ukraine_Democracy_Defense_Lend-Lease_Act_of_2022']),

-- Frederica S. Wilson / social-security — blank (S1 chair 2 -> blank)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. The chair rested on three things and none of them holds. (1) THE BILL IS MISDESCRIBED: the row says the One Big Beautiful Bill "proposed converting Social Security savings to private 'Trump accounts'". It did not. The cited article describes Trump accounts as tax-advantaged childrens' savings accounts, with a $1,000 federal deposit for each citizen child born 2025-2028 "with a social security NUMBER" - the row appears to have read "social security number" as Social Security. (2) IT IS A NO VOTE: she did vote against the Act (Clerk rolls 145 and 190, verified), but a no only rejects a package and cannot choose between the chairs on this ladder. (3) THE ROW CONFESSES: "She likely cosponsored Social Security 2100 Act but no direct confirmation found." Her cosponsorship record is public and this is cheaply re-researchable.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Big_Beautiful_Bill','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus']),

-- Hallie Shoffner / abortion — blank (S1 chair 2 -> blank)
('a7307f34-90ca-4d29-8698-4898ed3de05c','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. The only source is the 2026 Arkansas Senate race article, which names Shoffner twenty-two times and contains ZERO occurrences of abortion, LGBT, Social Security, immigration or voting - it carries no policy content at all. The rows concede the method themselves: the immigration row reads "Moderate position EXPECTED for Arkansas context ... LIKELY supports reform". Her economic-development and taxes rows, which cite hallieshoffner.com/priorities and quote it, are sound and are left alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']),

-- Hallie Shoffner / civil-rights — blank (S1 chair 2 -> blank)
('a7307f34-90ca-4d29-8698-4898ed3de05c','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. The only source is the 2026 Arkansas Senate race article, which names Shoffner twenty-two times and contains ZERO occurrences of abortion, LGBT, Social Security, immigration or voting - it carries no policy content at all. The rows concede the method themselves: the immigration row reads "Moderate position EXPECTED for Arkansas context ... LIKELY supports reform". Her economic-development and taxes rows, which cite hallieshoffner.com/priorities and quote it, are sound and are left alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']),

-- Hallie Shoffner / healthcare — blank (S1 chair 2 -> blank)
('a7307f34-90ca-4d29-8698-4898ed3de05c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Blanked 2026-10-07. The only source is the 2026 Arkansas Senate race article, which names Shoffner twenty-two times and contains ZERO occurrences of abortion, LGBT, Social Security, immigration or voting - it carries no policy content at all. The rows concede the method themselves: the immigration row reads "Moderate position EXPECTED for Arkansas context ... LIKELY supports reform". Her economic-development and taxes rows, which cite hallieshoffner.com/priorities and quote it, are sound and are left alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']),

-- Hallie Shoffner / social-security — blank (S1 chair 2 -> blank)
('a7307f34-90ca-4d29-8698-4898ed3de05c','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. The only source is the 2026 Arkansas Senate race article, which names Shoffner twenty-two times and contains ZERO occurrences of abortion, LGBT, Social Security, immigration or voting - it carries no policy content at all. The rows concede the method themselves: the immigration row reads "Moderate position EXPECTED for Arkansas context ... LIKELY supports reform". Her economic-development and taxes rows, which cite hallieshoffner.com/priorities and quote it, are sound and are left alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']),

-- Hallie Shoffner / voting-rights — blank (S1 chair 2 -> blank)
('a7307f34-90ca-4d29-8698-4898ed3de05c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL,
 $r$Blanked 2026-10-07. The only source is the 2026 Arkansas Senate race article, which names Shoffner twenty-two times and contains ZERO occurrences of abortion, LGBT, Social Security, immigration or voting - it carries no policy content at all. The rows concede the method themselves: the immigration row reads "Moderate position EXPECTED for Arkansas context ... LIKELY supports reform". Her economic-development and taxes rows, which cite hallieshoffner.com/priorities and quote it, are sound and are left alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Arkansas']),

-- Janak Joshi / abortion — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / civil-rights — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / climate-change — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / fossil-fuels — blank (S1 chair 4 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','a22215c3-6693-4bc2-b248-01aebba14570',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / healthcare — blank (S1 chair 4 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / judicial-criminal-justice — blank (S1 chair 4 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c334f475-05bd-48ba-9d25-f4de593a3f15', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / social-security — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / taxes — blank (S1 chair 4 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / trans-athletes — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / ukraine-support — blank (S1 chair 5 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Janak Joshi / voting-rights — blank (S1 chair 4 -> blank)
('07a45a9b-7726-41bd-8f67-722b865345ec','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Mike Collins's research filed under Janak Joshi. Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017 and has never served in Congress; Mike Collins is the Republican nominee for U.S. Senate in Georgia and the sitting U.S. Representative for Georgia's 10th district. All twelve rows cite ontheissues.org/Senate/Mike_Collins.htm - a page about Mike Collins, not Joshi - and one also cites the 2026 Georgia Senate race article, which contains no mention of Joshi (control term "Georgia" appears 132 times). 🔑 The decisive test needs neither page: the reasoning attributes CONGRESSIONAL acts to Joshi ("opposed Equality Act", "co-sponsored pro-life legislation"), and Janak Joshi has never been a member of Congress. Mike Collins has. Six of these twelve chairs sit at rung 5, the most extreme rung on their ladder. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://www.ontheissues.org/Senate/Mike_Collins.htm']),

-- Karen Ruth Bass / ai-regulation — blank (S1 chair 3 -> blank)
('21c9e711-fb18-4afb-884f-08acd2b598ba','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blanked 2026-10-07. THIS CHAIR HAD NO REASONING AT ALL - the context row existed with its source set and the reasoning an empty string. Its only source is her congress.gov member page from her time in the House, which returns HTTP 403 to automated retrieval and was not read; she is now Mayor of Los Angeles. ⚠ This key was NOT in the 73-key federal queue. It is written here because a corpus-wide measurement found exactly four empty-reasoning rows across three keys, and leaving the third behind would leave a complete and closable class open for the sake of a queue boundary.$r$,
 ARRAY['https://www.congress.gov/member/karen-bass/B001270']),

-- Norma Torres / misinformation — blank (S1 chair 2 -> blank)
('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL,
 $r$Blanked 2026-10-07. Both halves fail. (1) ROLE, NOT POSITION: she does serve on the Committee on House Administration and in the New Democrat Coalition - both confirmed on the cited pages - but NEITHER PAGE CONTAINS THE WORDS misinformation, disinformation OR content moderation, not once. A committee seat is an assignment, not a position. (2) A DIFFERENT QUESTION: she did vote for the For the People Act (Clerk roll 62, 3 March 2021, 220-210 -> Torres (CA), T000474, D-CA: Yea, verified; the sheet distinguishes her from Torres (NY)), but that Act governs election administration, campaign-finance disclosure and redistricting. This ladder asks about platform and government content restrictions.$r$,
 ARRAY['https://en.wikipedia.org/wiki/House_Administration_Committee','https://en.wikipedia.org/wiki/New_Democrat_Coalition']),

-- Pete Aguilar / ai-regulation — blank (S1 chair 3 -> blank)
('822966a7-5f09-4151-ba43-630afbd676c2','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blanked 2026-10-07. THIS CHAIR HAD NO REASONING AT ALL - the context row existed with its source set and the reasoning an empty string, so a seated chair was being shown to voters with literally nothing asserted behind it. Its only source is his congress.gov member page, which returns HTTP 403 to automated retrieval and was not read. A measurement over the whole corpus found exactly four such rows across three keys, and this migration blanks all of them.$r$,
 ARRAY['https://www.congress.gov/member/pete-aguilar/A000371']),

-- Seth Moulton / data-centers — blank (S1 chair 3 -> blank)
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','4559b513-0fd8-4ed1-babd-f3b554162f40',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c48a03d6-b972-4f27-9a8a-d41b07f4a929', NULL,
 $r$Blanked 2026-10-07. The row opens "Moulton has NOT TAKEN A HIGHLY SPECIFIC PUBLIC STANCE on data center siting" and then seats a centre chair from his committee work and his district ("MA-06 does not have major data center clusters driving local controversy"). A centre chair is a claim, not a neutral default. Its only source is his congress.gov member page, which returns HTTP 403 to automated retrieval and was not read.$r$,
 ARRAY['https://congress.gov/member/seth-moulton/M001196']),

-- Seth Moulton / growth-and-development — blank (S1 chair 2 -> blank)
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','65e8ffd5-5aac-4d40-8862-a321949eafa4', NULL,
 $r$Blanked 2026-10-07. The one concrete instrument is his support for the CHIPS Act, which is federal semiconductor industrial policy; this ladder asks about local growth and development intensity. The rest of the chair is inferred from the character of his district - "His district, which spans suburban communities north of Boston, LEADS HIM TO support mixed development" - which is geography, not a position. Its only source is his congress.gov member page, which returns HTTP 403 to automated retrieval and was not read.$r$,
 ARRAY['https://congress.gov/member/seth-moulton/M001196']),

-- Zach Wahls / abortion — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']),

-- Zach Wahls / ai-regulation — blank (S1 chair 3 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / campaign-finance — blank (S1 chair 1 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','92730f69-ae57-401c-8ad1-2d07834a895d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / civil-rights — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/','https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']),

-- Zach Wahls / climate-change — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / economic-development — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','eb3d1247-0de1-4b7f-baec-7259861efd53',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af855dba-96f3-4fa0-beb7-43c5edb3f499', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / healthcare — blank (S1 chair 1 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / social-security — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','87d20824-a6e9-407b-983c-65440084a0ab',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Idaho']),

-- Zach Wahls / taxes — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Zach Wahls / voting-rights — blank (S1 chair 2 -> blank)
('db66036a-2a1f-4bcf-980e-2f29a336dc5f','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL,
 $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
 ARRAY['https://rothforidaho.org/solutions/']),

-- Frederica S. Wilson / campaign-finance — repair (S1 chair 2, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','92730f69-ae57-401c-8ad1-2d07834a895d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL,
 $r$Wilson voted for the For the People Act (H.R. 1): Clerk roll 62, 3 March 2021, On Passage, 220-210 -> Wilson (FL), W000808, D-FL: Yea. The Act carries the DISCLOSE provisions requiring disclosure of dark-money donors and a voluntary public matching-fund system. Citation repaired 2026-10-07: the vote is real and verified against the primary record, but the cited Wikipedia article about the bill does not name her, so the roll call is now cited directly. The House sheet distinguishes Wilson (FL) from Wilson (SC), who voted Nay.$r$,
 ARRAY['https://en.wikipedia.org/wiki/For_the_People_Act','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://clerk.house.gov/Votes/202162']),

-- Frederica S. Wilson / childcare — repair (S1 chair 2, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','c1ac1330-47f7-44ec-baf3-c913d926b97c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','0e9fe0f2-cfab-4553-99cd-c3195d08e236', NULL,
 $r$Wilson voted for the Build Back Better Act (H.R. 5376): Clerk roll 385, 19 November 2021, On Passage, 220-213 -> Wilson (FL), W000808, D-FL: Yea. The Act carried roughly $400bn for childcare and universal pre-K. Citation repaired 2026-10-07: verified against the primary record because the cited article about the bill does not name her.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Build_Back_Better_Act','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://clerk.house.gov/Votes/2021385']),

-- Frederica S. Wilson / deportation — repair (S1 chair 2, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','44905f3b-e105-4f6c-afc7-5d223813dbac',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','55c3167e-3ad8-425d-a699-b2e91552d912', NULL,
 $r$Two verified votes. (1) Dream Act / American Dream and Promise Act (H.R. 6): Clerk roll 91, 18 March 2021, On Passage, 228-197 -> Wilson (FL), W000808, D-FL: Yea. (2) Laken Riley Act (S. 5): Clerk roll 23, 22 January 2025, On Passage, 263-156 -> Wilson (FL): Nay. Citation repaired 2026-10-07. 🔑 THE ROW PREVIOUSLY GUESSED THE SECOND VOTE: it stated she voted against the Laken Riley Act and then conceded "based on her Progressive Caucus membership and 100% Biden alignment, she almost certainly voted against it". The guess was correct, but a guess is not evidence; the roll call now stands in its place.$r$,
 ARRAY['https://en.wikipedia.org/wiki/American_Dream_and_Promise_Act','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://en.wikipedia.org/wiki/Laken_Riley_Act','https://clerk.house.gov/Votes/202191','https://clerk.house.gov/Votes/202523']),

-- Frederica S. Wilson / redistricting — repair (S1 chair 2, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','48cc9585-ec22-4f53-8d42-6839828dd36f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c7f973fc-33f5-4570-bfe2-bff4ac6141cc', NULL,
 $r$Wilson voted for the For the People Act (H.R. 1): Clerk roll 62, 3 March 2021, On Passage, 220-210 -> Wilson (FL), W000808, D-FL: Yea. The Act requires independent redistricting commissions with equal party representation to draw congressional boundaries, which is the chair. Citation repaired 2026-10-07: verified against the primary record because the cited article about the bill does not name her.$r$,
 ARRAY['https://en.wikipedia.org/wiki/For_the_People_Act','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://clerk.house.gov/Votes/202162']),

-- Frederica S. Wilson / religious-freedom — repair (S1 chair 2, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','6b9ba6d9-1001-43f5-b073-4d37130696fd',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL,
 $r$Wilson voted for the Equality Act (H.R. 5): Clerk roll 39, 25 February 2021, On Passage, 224-206 -> Wilson (FL), W000808, D-FL: Yea. The Act extends federal non-discrimination protection without a religious exemption, which is the chair. Citation repaired 2026-10-07: verified against the primary record because the cited article about the bill does not name her.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Equality_Act_%28United_States%29','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://clerk.house.gov/Votes/202139']),

-- Frederica S. Wilson / taxes — repair (S1 chair 1, kept)
('3fc35d7d-a121-4b5e-b243-b150daf6e628','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Wilson voted for the Inflation Reduction Act (H.R. 5376, Senate amendment): Clerk roll 420, 12 August 2022, On Motion to Concur, 220-207 -> Wilson (FL), W000808, D-FL: Yea. The Act raised the corporate minimum tax and funded IRS enforcement. Citation repaired 2026-10-07. ⚠ REMOVED FROM THIS ROW: the claim that she "voted against the Tax Cuts and Jobs Act (2017, absent/not voting but did not support it)". The cited TCJA article's own House vote table records her as one of exactly two Democrats NOT VOTING. An absence is not a position, and the row contradicted itself inside one sentence.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Inflation_Reduction_Act_of_2022','https://en.wikipedia.org/wiki/Tax_Cuts_and_Jobs_Act_of_2017','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://clerk.house.gov/Votes/2022420']),

-- Jay Obernolte / trans-athletes — repair (S1 chair 4, kept)
('18db5d61-6bce-4f55-ad45-bed01f329548','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL,
 $r$Obernolte voted for the Protection of Women and Girls in Sports Act (H.R. 734): Clerk roll 192, 20 April 2023, On Passage, 219-203 -> Obernolte, O000019, R-CA: Yea (and Nay on the motion to recommit, roll 191). A direct, divided vote on exactly this question. Citation repaired 2026-10-07. 🔴 THE ROW ARGUED FROM THE PARTY, NOT THE MEMBER: it said "Republicans in the 118th and 119th Congresses broadly supported" H.R. 734, which is a claim about a caucus, and rested the rest on the One Big Beautiful Bill Act, whose article contains no athlete or sports-eligibility language at all. He voted for the actual bill; that is now what the row cites.$r$,
 ARRAY['https://www.govtrack.us/congress/members/jay_obernolte/456801','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://clerk.house.gov/Votes/2023192']),

-- Mike Flood / deportation — repair (S1 chair 4, kept)
('527e6a87-9593-4191-bd25-ddfa3159ee52','44905f3b-e105-4f6c-afc7-5d223813dbac',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','55c3167e-3ad8-425d-a699-b2e91552d912', NULL,
 $r$Verified votes. Laken Riley Act (S. 5): Clerk roll 23, 22 January 2025, On Passage, 263-156 -> Flood, F000474, R-NE: Yea. One Big Beautiful Bill Act (H.R. 1): Clerk roll 145, 22 May 2025, On Passage, 215-214 -> Yea; roll 190, 3 July 2025, Motion to Concur, 218-214 -> Aye. Citation repaired 2026-10-07: the votes are real and verified against the primary record, but the cited articles about the bills do not name him.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Laken_Riley_Act','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://clerk.house.gov/Votes/202523','https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190']),

-- Mike Flood / healthcare — repair (S1 chair 4, kept)
('527e6a87-9593-4191-bd25-ddfa3159ee52','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL,
 $r$Flood voted for the One Big Beautiful Bill Act (H.R. 1): Clerk roll 145, 22 May 2025, On Passage, 215-214 -> Flood, F000474, R-NE: Yea; roll 190, 3 July 2025, Motion to Concur, 218-214 -> Aye. The cited article records the Act's Medicaid restrictions and funding cuts. Citation repaired 2026-10-07. ⚠ The row states its own limitation: this is an omnibus vote, so it carries the package rather than this question alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://en.wikipedia.org/wiki/Republican_Study_Committee','https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190']),

-- Mike Flood / medicare/aid — repair (S1 chair 4, kept)
('527e6a87-9593-4191-bd25-ddfa3159ee52','cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL,
 $r$Flood voted for the One Big Beautiful Bill Act (H.R. 1): Clerk roll 145, 22 May 2025, On Passage, 215-214 -> Flood, F000474, R-NE: Yea; roll 190, 3 July 2025, Motion to Concur, 218-214 -> Aye. The cited article carries a "Medicaid restrictions and funding cuts" section. Citation repaired 2026-10-07. ⚠ An omnibus vote carries the package, not this question alone.$r$,
 ARRAY['https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190']),

-- Mike Flood / trans-athletes — repair (S1 chair 4, kept)
('527e6a87-9593-4191-bd25-ddfa3159ee52','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL,
 $r$Flood voted for the Protection of Women and Girls in Sports Act (H.R. 734): Clerk roll 192, 20 April 2023, On Passage, 219-203 -> Flood, F000474, R-NE: Yea. That is a direct, divided vote on exactly this question. Citation repaired 2026-10-07. 🔴 THE ROW HAD THE WRONG BILL: it claimed the One Big Beautiful Bill Act "included the Protection of Women and Girls in Sports Act language". It does not - the cited OBBBA article contains ZERO occurrences of "athlete" or "Protection of Women and Girls", and its only two uses of "sports" are in an educator tax deduction for sports coaches. The chair is right; the instrument named was not.$r$,
 ARRAY['https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://clerk.house.gov/Votes/2023192']),

-- Nikema Williams / ukraine-support — repair (S1 chair 2, kept)
('acb046eb-1db6-44bf-a50b-32d16df15057','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Williams voted for the Ukraine Security Supplemental Appropriations Act, 2024 (H.R. 8035): Clerk roll 151, 20 April 2024, On Passage, 311-112 -> Williams (GA), W000788, D-GA: Yea. The sheet distinguishes Williams (GA) from Williams (TX) and Williams (NY). Citation repaired 2026-10-07. 🔴🔴 THE ROW CITED A BILL SHE VOTED AGAINST: its source was the 21st Century Peace Through Strength Act (H.R. 8038), and the Clerk records Williams (GA) voting NAY on it (roll 145, 20 April 2024, 360-58). H.R. 8038 was the sanctions-and-TikTok piece of the April 2024 package, not the Ukraine aid appropriation. The chair is correct and the aid vote is a genuine 311-112 division; only the instrument was wrong.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus','https://en.wikipedia.org/wiki/21st_Century_Peace_Through_Strength_Act','https://clerk.house.gov/Votes/2024151']);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','00b95a6a-75db-4521-b523-3326bba938de','86d893a1-c1a2-4bbf-b4e5-69ec43221194','88858826-90c0-41c9-a3a4-1d9f5b8c5307', NULL, 0), -- Alex Padilla         / school-vouchers        2 -> blank
  ('a2fee754-f90c-47ff-a3b7-377d55992273','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Alex Vindman         / abortion               5 -> blank
  ('a2fee754-f90c-47ff-a3b7-377d55992273','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Alex Vindman         / civil-rights           4 -> blank
  ('a2fee754-f90c-47ff-a3b7-377d55992273','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- Alex Vindman         / climate-change         4 -> blank
  ('a2fee754-f90c-47ff-a3b7-377d55992273','a22215c3-6693-4bc2-b248-01aebba14570','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL, 0), -- Alex Vindman         / fossil-fuels           2 -> blank
  ('a2fee754-f90c-47ff-a3b7-377d55992273','6b9ba6d9-1001-43f5-b073-4d37130696fd','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL, 0), -- Alex Vindman         / religious-freedom      5 -> blank
  ('0ac89151-2b8d-4430-b9bd-3a80bef3413b','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- Angie Nixon          / climate-change         4 -> blank
  ('0ac89151-2b8d-4430-b9bd-3a80bef3413b','a22215c3-6693-4bc2-b248-01aebba14570','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL, 0), -- Angie Nixon          / fossil-fuels           2 -> blank
  ('0ac89151-2b8d-4430-b9bd-3a80bef3413b','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0), -- Angie Nixon          / ukraine-support        4 -> blank
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','4559b513-0fd8-4ed1-babd-f3b554162f40','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c48a03d6-b972-4f27-9a8a-d41b07f4a929', NULL, 0), -- Ayanna Pressley      / data-centers           3 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Dakarai Larriett     / abortion               2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Dakarai Larriett     / civil-rights           2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- Dakarai Larriett     / climate-change         2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','eb3d1247-0de1-4b7f-baec-7259861efd53','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af855dba-96f3-4fa0-beb7-43c5edb3f499', NULL, 0), -- Dakarai Larriett     / economic-development   2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 0), -- Dakarai Larriett     / healthcare             2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','00b95a6a-75db-4521-b523-3326bba938de','86d893a1-c1a2-4bbf-b4e5-69ec43221194','88858826-90c0-41c9-a3a4-1d9f5b8c5307', NULL, 0), -- Dakarai Larriett     / school-vouchers        1 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- Dakarai Larriett     / social-security        2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 0), -- Dakarai Larriett     / taxes                  2 -> blank
  ('98480c0b-2b26-4098-a830-a2efd88fed29','d1792200-1d3b-4955-a0b7-0e6980d7a7b2','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL, 0), -- Dakarai Larriett     / voting-rights          2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- David Roth           / abortion               2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- David Roth           / civil-rights           2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- David Roth           / climate-change         2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 0), -- David Roth           / healthcare             2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','ddd65d64-9dc7-4208-a30f-59f4b9c0653d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL, 0), -- David Roth           / misinformation         2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- David Roth           / social-security        2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 0), -- David Roth           / taxes                  2 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0), -- David Roth           / ukraine-support        1 -> blank
  ('bc9ec968-d664-4987-8f9c-108f9ae51535','d1792200-1d3b-4955-a0b7-0e6980d7a7b2','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL, 0), -- David Roth           / voting-rights          2 -> blank
  ('91d28127-8183-4b67-a1fb-dc8a150f6199','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0), -- Debbie Dingell       / ukraine-support        2 -> blank
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- Frederica S. Wilson  / social-security        2 -> blank
  ('a7307f34-90ca-4d29-8698-4898ed3de05c','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Hallie Shoffner      / abortion               2 -> blank
  ('a7307f34-90ca-4d29-8698-4898ed3de05c','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Hallie Shoffner      / civil-rights           2 -> blank
  ('a7307f34-90ca-4d29-8698-4898ed3de05c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 0), -- Hallie Shoffner      / healthcare             2 -> blank
  ('a7307f34-90ca-4d29-8698-4898ed3de05c','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- Hallie Shoffner      / social-security        2 -> blank
  ('a7307f34-90ca-4d29-8698-4898ed3de05c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL, 0), -- Hallie Shoffner      / voting-rights          2 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Janak Joshi          / abortion               5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Janak Joshi          / civil-rights           5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- Janak Joshi          / climate-change         5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','a22215c3-6693-4bc2-b248-01aebba14570','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b', NULL, 0), -- Janak Joshi          / fossil-fuels           4 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 0), -- Janak Joshi          / healthcare             4 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c334f475-05bd-48ba-9d25-f4de593a3f15', NULL, 0), -- Janak Joshi          / judicial-criminal-justice 4 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- Janak Joshi          / social-security        5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 0), -- Janak Joshi          / taxes                  4 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','d1618b9c-0b9e-45af-b986-bb33d270b8e4','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL, 0), -- Janak Joshi          / trans-athletes         5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0), -- Janak Joshi          / ukraine-support        5 -> blank
  ('07a45a9b-7726-41bd-8f67-722b865345ec','d1792200-1d3b-4955-a0b7-0e6980d7a7b2','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL, 0), -- Janak Joshi          / voting-rights          4 -> blank
  ('21c9e711-fb18-4afb-884f-08acd2b598ba','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Karen Ruth Bass      / ai-regulation          3 -> blank
  ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6','ddd65d64-9dc7-4208-a30f-59f4b9c0653d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL, 0), -- Norma Torres         / misinformation         2 -> blank
  ('822966a7-5f09-4151-ba43-630afbd676c2','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Pete Aguilar         / ai-regulation          3 -> blank
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','4559b513-0fd8-4ed1-babd-f3b554162f40','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c48a03d6-b972-4f27-9a8a-d41b07f4a929', NULL, 0), -- Seth Moulton         / data-centers           3 -> blank
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4','86d893a1-c1a2-4bbf-b4e5-69ec43221194','65e8ffd5-5aac-4d40-8862-a321949eafa4', NULL, 0), -- Seth Moulton         / growth-and-development 2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Zach Wahls           / abortion               2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Zach Wahls           / ai-regulation          3 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','92730f69-ae57-401c-8ad1-2d07834a895d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL, 0), -- Zach Wahls           / campaign-finance       1 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Zach Wahls           / civil-rights           2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','5f1403f3-90b6-491f-ba54-3c8e46a5ae26', NULL, 0), -- Zach Wahls           / climate-change         2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','eb3d1247-0de1-4b7f-baec-7259861efd53','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af855dba-96f3-4fa0-beb7-43c5edb3f499', NULL, 0), -- Zach Wahls           / economic-development   2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 0), -- Zach Wahls           / healthcare             1 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','87d20824-a6e9-407b-983c-65440084a0ab','86d893a1-c1a2-4bbf-b4e5-69ec43221194','8defc029-0b7e-426f-b838-a2e170f566c9', NULL, 0), -- Zach Wahls           / social-security        2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 0), -- Zach Wahls           / taxes                  2 -> blank
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f','d1792200-1d3b-4955-a0b7-0e6980d7a7b2','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2a18c152-67a0-4380-a381-cb8795110a7c', NULL, 0), -- Zach Wahls           / voting-rights          2 -> blank
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','92730f69-ae57-401c-8ad1-2d07834a895d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL, 2), -- Frederica S. Wilson  / campaign-finance       2 -> 2
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','c1ac1330-47f7-44ec-baf3-c913d926b97c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','0e9fe0f2-cfab-4553-99cd-c3195d08e236', NULL, 2), -- Frederica S. Wilson  / childcare              2 -> 2
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','44905f3b-e105-4f6c-afc7-5d223813dbac','86d893a1-c1a2-4bbf-b4e5-69ec43221194','55c3167e-3ad8-425d-a699-b2e91552d912', NULL, 2), -- Frederica S. Wilson  / deportation            2 -> 2
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','48cc9585-ec22-4f53-8d42-6839828dd36f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c7f973fc-33f5-4570-bfe2-bff4ac6141cc', NULL, 2), -- Frederica S. Wilson  / redistricting          2 -> 2
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','6b9ba6d9-1001-43f5-b073-4d37130696fd','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL, 2), -- Frederica S. Wilson  / religious-freedom      2 -> 2
  ('3fc35d7d-a121-4b5e-b243-b150daf6e628','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 1), -- Frederica S. Wilson  / taxes                  1 -> 1
  ('18db5d61-6bce-4f55-ad45-bed01f329548','d1618b9c-0b9e-45af-b986-bb33d270b8e4','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL, 4), -- Jay Obernolte        / trans-athletes         4 -> 4
  ('527e6a87-9593-4191-bd25-ddfa3159ee52','44905f3b-e105-4f6c-afc7-5d223813dbac','86d893a1-c1a2-4bbf-b4e5-69ec43221194','55c3167e-3ad8-425d-a699-b2e91552d912', NULL, 4), -- Mike Flood           / deportation            4 -> 4
  ('527e6a87-9593-4191-bd25-ddfa3159ee52','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529','86d893a1-c1a2-4bbf-b4e5-69ec43221194','afc91aa2-4d48-4db6-aebd-f4c9788e6ad7', NULL, 4), -- Mike Flood           / healthcare             4 -> 4
  ('527e6a87-9593-4191-bd25-ddfa3159ee52','cab61e8a-64fe-4bbd-bc08-fe9914d0091b','86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL, 4), -- Mike Flood           / medicare/aid           4 -> 4
  ('527e6a87-9593-4191-bd25-ddfa3159ee52','d1618b9c-0b9e-45af-b986-bb33d270b8e4','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL, 4), -- Mike Flood           / trans-athletes         4 -> 4
  ('acb046eb-1db6-44bf-a50b-32d16df15057','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 2)  -- Nikema Williams      / ukraine-support        2 -> 2
;

-- ── 6 EXISTING SEASON 2 ROWS, UPDATED IN PLACE ────────────────────────────────────────────
-- There is no season further forward to write into, and Season 2 is frozen for topics and chairs
-- but OPEN for stances. A repair here keeps the row's OWN value (see the ladder note above).
-- Alex Vindman / same-sex-marriage — blank (S2 chair 4 -> blank)
UPDATE inform.politician_context SET
  reasoning = $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is Janak Joshi's research filed under Alex Vindman. Alex Vindman is Candidate for U.S. Senate - Florida (Democratic); the retired Army officer who testified in the 2019 impeachment inquiry; Janak Joshi is Candidate for U.S. Senate - Colorado (Republican), a retired physician who served in the Colorado House 2011-2017. en.wikipedia.org/wiki/Janak_Joshi is a 2,844-character stub about Joshi: Colorado House District 16 and 14, a 2024 Republican primary loss to Gabe Evans. It contains no mention of Vindman and no mention of Florida. The Colorado race article likewise contains no mention of Vindman or of "Alex" (control term "Colorado" appears 71 times, so the page was read). The reasoning on these rows calls a Democratic candidate a "Conservative Republican". A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
  sources = ARRAY['https://en.wikipedia.org/wiki/Janak_Joshi'],
  updated_at = now()
 WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = 'a2fee754-f90c-47ff-a3b7-377d55992273' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

-- Frederica S. Wilson / housing — blank (S2 chair 3 -> blank)
UPDATE inform.politician_context SET
  reasoning = $r$Blanked 2026-10-07. THE VOTE IS REAL AND VERIFIED AND IT STILL DOES NOT PIN THIS RUNG. Build Back Better Act (H.R. 5376): Clerk roll 385, 19 November 2021, On Passage, 220-213 -> Wilson (FL), W000808, D-FL: Yea. But the Act carried BOTH public-housing capital funding AND subsidy-and-tax-credit programmes, and the Season 2 rungs here separate exactly those: rung 2 is "Build a large public housing sector", rung 3 (the seated chair) is "Build NO public housing, but set binding rules ... like rent caps or required affordable units", and rung 4 is "Set no binding rules, but offer subsidies and tax breaks". A single omnibus vote is consistent with 2 and with 4 and is the one thing it is not evidence for, namely 3. The rest of the row argued from the economic character of her district, which is circumstance rather than position. Re-researchable from her own sponsorships.$r$,
  sources = ARRAY['https://en.wikipedia.org/wiki/Build_Back_Better_Act','https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'],
  updated_at = now()
 WHERE politician_id = '3fc35d7d-a121-4b5e-b243-b150daf6e628' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = '3fc35d7d-a121-4b5e-b243-b150daf6e628' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

-- Pete Aguilar / housing — blank (S2 chair 3 -> blank)
UPDATE inform.politician_context SET
  reasoning = $r$Blanked 2026-10-07. THIS CHAIR HAD NO REASONING AT ALL - in Season 1 and again in Season 2, the context row existed with its source set and the reasoning an empty string. Its only source is his congress.gov member page, which returns HTTP 403 to automated retrieval and was not read. A measurement over the whole corpus found exactly four such rows across three keys, and this migration blanks all of them.$r$,
  sources = ARRAY['https://www.congress.gov/member/pete-aguilar/A000371'],
  updated_at = now()
 WHERE politician_id = '822966a7-5f09-4151-ba43-630afbd676c2' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = '822966a7-5f09-4151-ba43-630afbd676c2' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

-- Zach Wahls / housing — blank (S2 chair 3 -> blank)
UPDATE inform.politician_context SET
  reasoning = $r$Blanked 2026-10-07. 🔴🔴 THE EVIDENCE DESCRIBES A DIFFERENT PERSON. This row is David Roth's research filed under Zach Wahls. Zach Wahls is Candidate for U.S. Senate - Iowa (Democratic); David Roth is Candidate for U.S. Senate - Idaho (Democratic). Ten of these rows cite rothforidaho.org/solutions/, which is headed "SOLUTIONS - David Roth for Idaho" and contains no mention of Wahls and no mention of Iowa (control term "Idaho" appears 16 times). The rest cite the 2026 Idaho Senate race article, which contains no mention of Wahls or of "Zach" (control term "Idaho" appears 27 times). 🔴 A BORROWED CAMPAIGN WEBSITE IS THE MOST SPECIFIC-LOOKING SOURCE THERE IS, which is why only two of these eleven rows ever reached a sourcing-quality queue. A chair must rest on evidence about the person it is shown under, so there is nothing here to keep. The sources examined are kept below so the next reader does not re-derive this from scratch.$r$,
  sources = ARRAY['https://rothforidaho.org/solutions/'],
  updated_at = now()
 WHERE politician_id = 'db66036a-2a1f-4bcf-980e-2f29a336dc5f' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE politician_id = 'db66036a-2a1f-4bcf-980e-2f29a336dc5f' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

-- André Carson / same-sex-marriage — repair (S2 chair 2 kept)
UPDATE inform.politician_context SET
  reasoning = $r$Carson is an ORIGINAL COSPONSOR of the Equality Act (H.R. 15) in both the 119th and the 118th Congress - the cosponsor list records "Carson, Andre [D-IN7, 2008-2026] Original Cosponsor". The Equality Act extends federal non-discrimination protection to LGBTQ people without a carve-out for religious objectors, which is the chair. Citation repaired 2026-10-07: the claim was true but its only source was his congress.gov member page, which returns HTTP 403 to automated retrieval and so could not be read.$r$,
  sources = ARRAY['https://www.congress.gov/member/andre-carson/C001072','https://www.govtrack.us/congress/bills/119/hr15/cosponsors'],
  updated_at = now()
 WHERE politician_id = '91c72443-147f-4d1f-adab-ee415dab5ea6' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
-- value unchanged at 2: this is a citation repair, not a re-seating.

-- James A. Himes / same-sex-marriage — repair (S2 chair 2 kept)
UPDATE inform.politician_context SET
  reasoning = $r$Himes voted for the Respect for Marriage Act (H.R. 8404): Clerk roll 513, 8 December 2022, On Motion to Concur, 258-169 -> Himes, H001047, D-CT: Yea. Citation repaired 2026-10-07: the row inferred the vote from the party bloc ("All House Democrats voted in favor, including Himes") rather than looking it up. The inference was right and the roll call now stands in its place. ⚠ LIMITATION RECORDED: this Act requires recognition of marriages lawfully performed elsewhere, and 39-47 House Republicans voted for it too, so on its own it does not separate the most expansive chair from the next one. The chair is unchanged pending evidence that speaks to that distinction.$r$,
  sources = ARRAY['https://en.wikipedia.org/wiki/Respect_for_Marriage_Act','https://clerk.house.gov/Votes/2022513'],
  updated_at = now()
 WHERE politician_id = '8ce169cb-e9c0-4eca-a927-fbbad7315b98' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6' AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
-- value unchanged at 2: this is a citation repair, not a re-seating.

-- ── POST-GUARDS ───────────────────────────────────────────────────────────────────────────────
DO $post$
DECLARE n int;
BEGIN
  -- every written key has BOTH an answer and a context row in Season 2
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c USING (politician_id, topic_id, season_id)
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid)
  );
  IF n <> 79 THEN
    RAISE EXCEPTION 'migration 1896: expected 79 paired Season 2 rows, found %', n;
  END IF;

  -- the 65 blanks are at 0
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = 0 AND (a.politician_id, a.topic_id) IN (
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid)
  );
  IF n <> 65 THEN
    RAISE EXCEPTION 'migration 1896: expected 65 Season 2 blanks, found %', n;
  END IF;

  -- the 14 repairs are at their ORIGINAL chairs, as triples. A `value IN (...)` list
  -- would pass even if two of them had swapped.
  SELECT count(*) INTO n FROM (VALUES
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid,2::numeric),  -- Frederica S. Wilson / childcare
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,2::numeric),  -- Frederica S. Wilson / redistricting
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2::numeric),  -- James A. Himes / same-sex-marriage
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2::numeric),  -- André Carson / same-sex-marriage
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,2::numeric),  -- Frederica S. Wilson / religious-freedom
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),  -- Jay Obernolte / trans-athletes
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),  -- Mike Flood / trans-athletes
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,2::numeric),  -- Nikema Williams / ukraine-support
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,4::numeric),  -- Mike Flood / medicare/aid
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,2::numeric),  -- Frederica S. Wilson / campaign-finance
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,2::numeric),  -- Frederica S. Wilson / deportation
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,4::numeric),  -- Mike Flood / deportation
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,4::numeric),  -- Mike Flood / healthcare
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,1::numeric)   -- Frederica S. Wilson / taxes
  ) AS t(pid, tid, val)
  JOIN inform.politician_answers a
    ON a.politician_id = t.pid AND a.topic_id = t.tid AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = t.val;
  IF n <> 14 THEN
    RAISE EXCEPTION 'migration 1896: expected 14 repairs at their original chairs, found %', n;
  END IF;

  -- nothing was written for the 7 blocked keys
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- André Carson / campaign-finance
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Janak Joshi / immigration
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Frederica S. Wilson / immigration
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Dakarai Larriett / immigration
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Alex Vindman / immigration
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Hallie Shoffner / immigration
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid)   -- David Roth / immigration
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1896: % blocked keys gained a Season 2 row', n;
  END IF;

  -- SEASON 1 IS UNCHANGED, per row, as triples
  SELECT count(*) INTO n FROM (VALUES
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,2::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,1::numeric),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,3::numeric),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,3::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,5::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,5::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,2::numeric),
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,1::numeric),
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,1::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,4::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,5::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,5::numeric),
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,5::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,4::numeric),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,2::numeric),
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid,1::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,4::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,5::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,5::numeric),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,4::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,5::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,4::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,1::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,2::numeric),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,2::numeric),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid,3::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,2::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,4::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,4::numeric),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,1::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,4::numeric),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,1::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,2::numeric),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid,4::numeric),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,2::numeric),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,2::numeric),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,2::numeric)
  ) AS t(pid, tid, val)
  JOIN inform.politician_answers a
    ON a.politician_id = t.pid AND a.topic_id = t.tid AND a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND a.value = t.val;
  IF n <> 79 THEN
    RAISE EXCEPTION 'migration 1896: Season 1 changed -- expected 79 rows intact, found %', n;
  END IF;

  -- no row written here ships with empty sources or empty reasoning
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (coalesce(array_length(c.sources,1),0) = 0 OR btrim(coalesce(c.reasoning,'')) = '')
     AND (c.politician_id, c.topic_id) IN (
    ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('8ce169cb-e9c0-4eca-a927-fbbad7315b98'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('91c72443-147f-4d1f-adab-ee415dab5ea6'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('18db5d61-6bce-4f55-ad45-bed01f329548'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('91d28127-8183-4b67-a1fb-dc8a150f6199'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('acb046eb-1db6-44bf-a50b-32d16df15057'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'24e9212c-b011-422a-865c-093e35050901'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'87d20824-a6e9-407b-983c-65440084a0ab'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0ac89151-2b8d-4430-b9bd-3a80bef3413b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a2fee754-f90c-47ff-a3b7-377d55992273'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),
    ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('527e6a87-9593-4191-bd25-ddfa3159ee52'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a7307f34-90ca-4d29-8698-4898ed3de05c'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('3fc35d7d-a121-4b5e-b243-b150daf6e628'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('bc9ec968-d664-4987-8f9c-108f9ae51535'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('07a45a9b-7726-41bd-8f67-722b865345ec'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('98480c0b-2b26-4098-a830-a2efd88fed29'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid)
  );
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1896: % rows written with empty sources or empty reasoning', n;
  END IF;

  -- The whole-corpus empty-reasoning class is CLOSED AS READ. ⚠ The first draft of this guard
  -- asserted that NO seated row anywhere carries empty reasoning, and the dry run failed it with
  -- 3 rows -- correctly. Those are the Season 1 rows themselves, and Season 1 is IMMUTABLE, so
  -- they cannot be edited and will always read that way in the table. What a reader sees is the
  -- Season 2 row where one exists, so the right assertion is about rows NOT shadowed by one.
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c USING (politician_id, topic_id, season_id)
   WHERE a.value <> 0 AND btrim(coalesce(c.reasoning,'')) = ''
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers s
                      WHERE s.politician_id = a.politician_id AND s.topic_id = a.topic_id
                        AND s.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1896: % unshadowed seated rows still carry empty reasoning', n;
  END IF;
END
$post$;

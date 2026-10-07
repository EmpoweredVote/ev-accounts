-- 1894_federal_weak_only_28_season2.sql
-- The 28 WEAK_ONLY rows left over from the federal generic-sourcing triage (ev-accounts #897),
-- read one at a time. 27 distinct (politician, topic) keys across 28 rows -- Whatley /
-- same-sex-marriage is the one key that already has BOTH a Season 1 and a Season 2 row.
--
-- OUTCOME: 21 blanks, 4 citation repairs, 1 left alone, 1 blocked.
--   24 context + 24 answer rows INSERTED into Season 2, and 1 Season 2 row UPDATED (Whatley).
--   SEASON 1 IS NOT TOUCHED. Nothing is deleted.
--
-- 🔴 WHY A FORWARD WRITE. Season 1 is CLOSED and IMMUTABLE --
-- `inform.closed_season_is_immutable()` rejects any write there, and its own error text names the
-- remedy: write in the OPEN season, which shadows the old row on read without destroying history.
-- Same shape as migrations 1870 and 1893.
-- 🔑 A BLANK IS `value 0` INSERTED, NEVER A DELETE -- a deleted Season 2 row falls back to Season 1
-- and the bad chair stays visible (CC_0057). Every blank below CARRIES THE SOURCES IT EXAMINED
-- (migration 1887's rule) so the next reader can see what was already looked at.
--
-- ⚠ ONE KEY IS AN UPDATE, NOT AN INSERT. Whatley / same-sex-marriage already holds a Season 2 row
-- (value 5, pinned to revision 8bc3d240, the re-scaled S2 ladder) carrying the same reasoning as its
-- Season 1 row. There is no season further forward to write into, and Season 2 is frozen for topics
-- and chairs but OPEN for stances, so that row is updated in place. The guard asserts it is there,
-- and asserts its value, before touching it.
--
-- ── WHAT "WEAK_ONLY" MEANT, AND WHY IT NEEDED A HUMAN ──────────────────────────────────────────
-- The claim-on-page guard re-tests a row against the ROW'S OWN WORDS rather than a topic lexicon.
-- WEAK_ONLY = the cited page carried some of the row's ordinary words and NONE of its distinctive
-- ones. That is a sort, not a verdict: it is equally consistent with "the page does not support
-- this" and with "the page supports it in different words". All 28 were therefore read by hand,
-- and they split four ways -- which is the point. 97% of the first cut before this one was noise;
-- this cut is roughly 75% real, and the quarter that is not real includes two chairs that are
-- simply CORRECT and were being held up by a bad sentence.
--
-- 🔑🔑 THE SECOND SOURCE DECIDED SEVERAL OF THESE, exactly as it did in migration 1893. The guard
-- only ever tests the article ABOUT THE PERSON. Rows here also cite articles about BILLS (Build
-- Back Better Act, First Step Act, One Big Beautiful Bill Act, USMCA, California v. Texas) and
-- those were fetched and read separately. Two of the four repairs exist only because of that.
--
-- ── THE 4 REPAIRS: the chair was right, the citation was not ────────────────────────────────────
-- A BAD CITATION IS NOT A FALSE CLAIM. None of these four moves a chair.
--
-- 1. Greg Landsman / Abortion -- chair 2 UNCHANGED.
--    The row argued from co-sponsorship of the Women's Health Protection Act and from a 2022
--    campaign contrast. Neither cited page carries either claim. But the cited Ballotpedia page
--    DOES carry, in its own "Notable ballot measure endorsements" table, that Landsman SUPPORTED
--    Ohio Issue 1 (2023). The measure's own Ballotpedia page independently lists "U.S. Rep. Greg
--    Landsman (D)" among its official supporters. Issue 1 wrote a right to reproductive decisions
--    into the Ohio Constitution and "allows the state to restrict abortion after fetal viability,
--    except when necessary to protect the pregnant patient's life or health" -- which is chair 2
--    ("legal and accessible through the second trimester with rare exceptions afterward") almost
--    word for word. A ballot-measure endorsement is his own act on a divided question.
--    ⚠ Ballotpedia sources the endorsement to a post of his on X. That post was NOT fetched, so it
--    is NOT cited here; what is cited is the two pages that were fetched and that carry the fact.
--
-- 2. Nikema Williams / Childcare -- chair 2 UNCHANGED.
--    The row says she voted for the Build Back Better Act. Her own article is silent and the Act's
--    article does not mention her, so the personal claim was uncited. ✅ IT IS TRUE, and is now
--    cited to the primary record: roll call 385 of 19 November 2021, H R 5376 "On Passage",
--    220-213-0-1 -> Williams (GA): Yea. The Act's own article carries the childcare content the
--    chair rests on -- $400bn for childcare and preschools, universal pre-K, and a childcare cost
--    cap of 7% of income for families up to 250% of state median income. Income-capped subsidy at
--    that scale is chair 2 (significantly expand subsidies for low- and middle-income families),
--    not chair 1 (universal regardless of income).
--
-- 3. Thomas H. Kean, Jr. / Medicare and Medicaid -- chair 4 UNCHANGED.
--    The row describes the One Big Beautiful Bill Act accurately and the Act's article confirms
--    every element of that description, including the $5 billion CBO figure for reversing parts of
--    Medicare drug price negotiation and a whole section on "Medicaid restrictions and funding
--    cuts". What it did not carry was HIS VOTE. Now cited to the Clerk: roll 145, 22 May 2025,
--    "On Passage", 215-214 -> Kean: Yea; roll 190, 3 July 2025, "On Motion to Concur in the Senate
--    Amendment", 218-214 -> Kean: Aye.
--    ⚠ STATED PLAINLY BECAUSE IT IS A REAL WEAKNESS: this is an omnibus vote, and the cited article
--    says Kean traded his vote for a SALT deduction deal. A vote for a bill is not proof of assent
--    to each of its parts. It is kept as chair 4 because a recorded vote on a 215-214 question is
--    the strongest instrument this audit has, and the health provisions were central to the bill
--    rather than incidental -- but a direct statement of his on Medicaid would be better evidence.
--
-- 4. Ken Paxton / Medicare and Medicaid -- chair 4 UNCHANGED.
--    His own article states, in its Affordable Care Act section, that "Paxton initiated a lawsuit
--    seeking to have the Affordable Care Act (Obamacare) ruled unconstitutional in its entirety",
--    and the California v. Texas article confirms his office brought one of the original suits and
--    quotes him saying he will keep seeking legal means to challenge the ACA. That is his own act
--    on his own initiative, and voiding the ACA entirely would end its Medicaid expansion.
--    🔴 WHAT IS BEING REMOVED is a QUOTATION. The row attributed to him the phrase "massive
--    government takeover" of healthcare. Neither cited page contains it. Given this project's
--    history with composed citations and invented quotations, an attributed quote that its own
--    sources do not carry is not left in voter-facing prose, even when the chair around it stands.
--
-- ── THE 21 BLANKS ──────────────────────────────────────────────────────────────────────────────
-- ⚖ A BLANK IS NOT A REVERSAL. value 0 says this question has not been answered on this person. It
-- does not assert the opposite chair. Several of these people may well hold the positions they
-- were seated at; what is missing is evidence, not plausibility. 🔑 A BLANK THAT SAYS WHAT WOULD
-- SETTLE IT IS AN INVITATION, so each one names what would.
--
-- They fall into recognisable classes, which is more useful than the list:
--   • ROLE OR PLATFORM AS POSITION (6) -- Whatley x3, Dingell / AI, Ricketts, Ezell-shaped. Being
--     party chair, sitting on the committee with jurisdiction, or belonging to a party whose
--     platform says X is a fact about where someone SITS, not about what they hold.
--     🔴 Whatley is the sharpest case in the cohort: three chairs at rung 5, the most extreme rung
--     on each ladder, and the only thing his article actually carries is that he holds a master's
--     degree in theology. A degree is not a position on marriage.
--   • SELF-CONFESSED ABSENCE (4) -- all four Roy Cooper rows. Three of them say so in their own
--     first sentence: "No specific AI regulation position found", "No specific legislation or clear
--     gubernatorial stance ... found", "No specific tariff or trade policy position found", each
--     followed by "Scored centrist". 🔴 A CENTRE CHAIR IS A CLAIM, NOT A NEUTRAL DEFAULT: a reader
--     cannot tell "he is a moderate on this" from "nobody looked". Only a blank can say the second.
--     The supporting facts offered instead (that he recruited tech employers to NC, that his 2020
--     COVID response included emergency housing protections) appear NOWHERE on the only page cited.
--   • EVIDENCE FOR A DIFFERENT QUESTION (5) -- Biggs (net neutrality, not AI), Grassley (federal
--     sentencing, not jail capacity), Lee (non-consensual deepfake intimate images, not
--     misinformation), Lieu (a conversion-therapy ban and a Transgender Bill of Rights resolution,
--     neither about athletics), Neal (community reinvestment, not zoning). In each the cited
--     evidence is REAL and often well sourced -- it simply describes a different chair.
--     🔑 Two of them say so themselves: Lee's row offers "value=3 ... or targeted statutory
--     intervention on specific harms", and Neal's opens "Neal has not taken a prominent federal
--     position on local zoning reform". When a row argues with its own ladder, believe the row.
--   • UNCITED THIRD-PARTY AGGREGATOR (2) -- both Gimenez rows rest on "iSideWith records him as...".
--     iSideWith is not among the sources, both pages are silent, and a quiz aggregator's inference
--     is not the member's statement even when it is right.
--   • NEAR-UNANIMOUS VOTE (1) -- Newhouse / tariffs rests on the USMCA, which passed the House
--     385-41 with Republicans 192-2. 🔴 THE LEHMAN RULE: being one of 385 cannot establish a
--     DISTINCTIVE position, because it is not a choice a ladder can seat. Same defect that blanked
--     Schrier in migration 1893 (417-10). Neither cited page mentions Newhouse at all.
--   • A "NO" VOTE READ AS A POSITIVE PROGRAMME (1) -- Vindman / taxes. His votes are real and are
--     now in the sources: roll 145 -> Nay, roll 190 -> No, both on the One Big Beautiful Bill Act.
--     🔑🔑 BUT A YES AND A NO ARE NOT SYMMETRIC EVIDENCE. A yes endorses the package's content,
--     which is why Taylor (1893) and Kean (above) can be seated on it. A no only REJECTS it, and
--     rejection is compatible with chairs 1, 2 and 3 alike. Opposing a tax CUT is not advocating a
--     tax RISE -- the same confusion catalogued in [[chair_reasoning_inversion]]. The votes are
--     kept in the sources precisely so the re-research starts from them.
--   • A MISDESCRIBED BILL (1) -- Tim Moore / religious freedom. The row says HB2 (2016) "allowed
--     businesses to deny service based on religious objections". 🔴 IT DID NOT. The cited article
--     describes HB2 as a bathroom bill barring transgender people from facilities matching their
--     gender identity; North Carolina's religious-objection law was a different statute. Worse, the
--     SAME article records Moore BLOCKING a 2017 bill to declare Obergefell "null and void" -- a
--     fact pointing the other way that the row passed over. Read the enacted text, not the title.
--   • A CHAIR FROM ANOTHER CHAIR (1) -- Cooper / homelessness, inferred from Medicaid expansion.
--
-- ── 1 LEFT ALONE ───────────────────────────────────────────────────────────────────────────────
-- Abraham J. Hamadeh / Misinformation, chair 4, IS SOUND and is not written here. His article says
-- he ran on "opposition to censorship by technology corporations" -- his own campaign position, on
-- the cited page, placing him on the speech-protective end of this ladder. ⚠ Recorded for the next
-- reader: the row widens that to "government or platform content restrictions", and the page
-- supports only the platform half. Not worth a write; worth not re-finding from scratch.
--
-- ── 1 BLOCKED, AND IT IS A REAL DEFECT ─────────────────────────────────────────────────────────
-- 🔴 Mike Ezell / Immigration (Season 1 chair 4) is defect-shaped and CANNOT BE WRITTEN. His
-- article carries "he called for stronger border security", which is his own stated position, but
-- the chair also claims he favours "limiting public services for those without legal status" and
-- nothing cited supports that half. It stays as it is because `immigration` HAS NO SEASON 2 PIN --
-- it is the Season-1-only 1,678-stance orphan topic, so no Season 2 row can legally exist for it
-- and there is nowhere forward to write. It joins the 10 Texas deportation rows already waiting on
-- the Season 3 decision. The guard below asserts that absence rather than trusting this comment.
--
-- ⚠ `check:stance-sources` MUST BE RUN BY HAND before merging -- it never runs on pull requests.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- 1. The Season 1 cohort must be exactly the 27 keys that were read, each at the chair that was
  -- read. Naming (politician, topic, value) triples rather than counting rows means a cohort that
  -- has shifted under us fails here instead of being silently overwritten.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND (politician_id, topic_id, value) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','c5ab4eab-702f-49b8-9277-8ea53f3835c6', 5),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d', 5),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762', 5),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a', 2),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023', 1),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f', 2),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901', 4),
       ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c', 2),
       ('0fd6132b-eb62-461d-98f7-8449fb3adbf2','4e2c69ce-591e-4197-9cd5-7aceff79d390', 4),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 3),
       ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4),
       ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3),
       ('ed20dd3f-a463-43c0-b08c-23cbf2a5e387','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd', 4),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 1));
  IF n <> 27 THEN
    RAISE EXCEPTION 'migration 1894: expected the 27 Season 1 keys at their read chairs, found %', n;
  END IF;

  -- 2. Season 2 must hold NONE of the 24 keys about to be inserted, or this is a re-run.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (politician_id, topic_id) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413'),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901'),
       ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
       ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
       ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1894: Season 2 already holds % of the 24 keys to be inserted', n;
  END IF;

  -- 3. The ONE key that is updated instead must be present in Season 2, and still at chair 5.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND politician_id = '867caca5-ab41-4e1b-b051-4a2cd95a335e'
     AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
     AND value = 5;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1894: Whatley/same-sex-marriage Season 2 row not found at chair 5 (found %)', n;
  END IF;

  -- 4. Every Season 2 pin this migration writes under, asserted rather than assumed. 17 topics.
  -- ⚠ NINE of these re-scaled between seasons (ai-regulation, campaign-finance, childcare,
  -- civil-rights, homelessness, medicare/aid, misinformation, religious-freedom,
  -- same-sex-marriage), which is harmless for a blank -- value 0 means unanswered on any ladder --
  -- but is exactly why each repair's chair was re-checked against the SEASON 2 rung text, not the
  -- Season 1 one, before being carried forward.
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (topic_id, topic_revision_id) IN (
       ('c5ab4eab-702f-49b8-9277-8ea53f3835c6','8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'),
       ('666bf03d-81fc-4138-ab15-69ae734c9023','c594dc06-0c70-4707-8ae0-d4bc760172db'),
       ('92730f69-ae57-401c-8ad1-2d07834a895d','ae53ba29-79eb-420f-aac6-ec99f8031ec6'),
       ('af2fdfd6-02c4-49df-b09c-cf8536f4773f','dab46e5c-628a-4360-ad1d-3aaba61768f0'),
       ('c1ac1330-47f7-44ec-baf3-c913d926b97c','0e9fe0f2-cfab-4553-99cd-c3195d08e236'),
       ('0bc588c6-39e1-4084-b5de-cac909b8b762','2010cab0-1968-4f24-b74d-ca47c2f90165'),
       ('4938766b-b45a-46e3-93bd-b8b30651271a','6958fa99-e317-45d7-8076-d11a0a78c897'),
       ('c267e137-0ff9-4e7d-9d13-e3cea1756cd0','f63a4e70-055e-4115-a5e0-3deeb5748816'),
       ('cab61e8a-64fe-4bbd-bc08-fe9914d0091b','38bab357-9790-4cb3-a6d2-c43cbdca615b'),
       ('ddd65d64-9dc7-4208-a30f-59f4b9c0653d','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'),
       ('48cc9585-ec22-4f53-8d42-6839828dd36f','c7f973fc-33f5-4570-bfe2-bff4ac6141cc'),
       ('6b9ba6d9-1001-43f5-b073-4d37130696fd','dfbd847a-294c-49d2-9ac3-69270ea03054'),
       ('d4f18138-a2e0-4110-b925-7387d9d0d16d','ef2a5e59-525a-41fa-94de-ce771df7c927'),
       ('683c8084-2281-4920-a07c-18439b2dd413','9f094155-f604-47e8-93db-54a3142420ca'),
       ('f7e5678d-dadd-4556-a2fc-446e24642ceb','87f8c011-5c70-4f39-a1ea-5cc53c010c60'),
       ('d1618b9c-0b9e-45af-b986-bb33d270b8e4','af2c6427-daf8-4819-93ba-42db212bae68'),
       ('24e9212c-b011-422a-865c-093e35050901','107d180d-a949-4a42-a250-54f0a7683be0'));
  IF n <> 17 THEN
    RAISE EXCEPTION 'migration 1894: Season 2 does not pin the expected revision for all 17 topics (found %)', n;
  END IF;

  -- 5. `immigration` must still have NO Season 2 pin. If it ever gains one, Ezell is writable and
  -- this migration's note about him is stale -- so fail loudly rather than let the note rot.
  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1894: immigration now HAS a Season 2 pin (%) -- Ezell is writable, revisit', n;
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- CONTEXT: 24 rows
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES

-- ── BLANKS ────────────────────────────────────────────────────────────────────────────────────

-- Michael Whatley / Campaign Finance — blank (S1 chair 5)
('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seated Whatley at chair 5, the most extreme rung, on his job rather than on anything he has said or done about campaign finance: that he "served as RNC Chair and is closely aligned with Republican positions opposing campaign finance restrictions", and that "his party role requires fundraising from large donors and PACs without disclosure restrictions". Holding an office that involves raising money is not a position on how money in politics should be regulated, and a party's position is not an individual's. The cited page was read in full and is silent on campaign finance, donors, PACs, disclosure and independent expenditures alike — it is a short article, and none of these words appears anywhere in it. This is a blank, not a finding that the opposite is true: the question has not been answered on this person. Whatley is a candidate for the United States Senate, so this row is voter-facing. It is re-researchable from his own campaign materials or any statement of his on disclosure or contribution limits.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']),

-- Michael Whatley / Civil Rights — blank (S1 chair 5)
('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seated Whatley at chair 5, the most extreme rung, on the claim that he "leads the Trump GOP operation which opposes affirmative action, diversity programs, and race-based government initiatives" and "promotes the NCGOP and RNC platform opposing equity mandates and federal civil rights expansions". That is a party platform attributed to the person who chairs the party. The cited page was read in full and contains no mention of affirmative action, diversity, equity or civil rights at all. One adjacent claim is partly borne out and is worth recording accurately: the row says he "censured Republican senators who crossed party lines", and the page does say the North Carolina state party voted unanimously to censure Senator Richard Burr for voting to convict in an impeachment trial — but the party censured, not Whatley personally, and a censure over an impeachment vote is not a civil-rights position. This is a blank, not a finding that the opposite is true. Whatley is a candidate for the United States Senate, so this row is voter-facing. A statement of his own on any specific civil-rights measure would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']),

-- Roy Cooper / AI Regulation — blank (S1 chair 3)
('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row says so itself, in its own first sentence: "No specific AI regulation position found in Cooper's gubernatorial record or 2026 campaign materials", and then its last: "Scored centrist given the absence of direct evidence." A centre chair is a claim, not a neutral default — a reader seeing chair 3 is told that Cooper has a moderate position on artificial intelligence, when what is actually known is that nobody found one. Only a blank can say the second. The supporting fact offered instead, that "he recruited major tech employers to NC", does not appear anywhere on the only page cited, which contains no mention of artificial intelligence, AI, or technology recruitment. Cooper is a candidate for the United States Senate, so this row is voter-facing. It is re-researchable from any statement of his on AI policy.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']),

-- Roy Cooper / Homelessness — blank (S1 chair 2)
('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','6958fa99-e317-45d7-8076-d11a0a78c897', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Cooper at chair 2 by reasoning across from a different topic: his Medicaid expansion, "which directly addresses healthcare access for homeless populations". Medicaid expansion is real and well documented on the cited page, but it is a health-coverage policy, and a chair on one ladder cannot be derived from a chair on another. The row's homelessness-specific claims — that his 2020 COVID response "included emergency housing protections", that he showed "opposition to criminalization-first approaches to poverty", and that he favours "services and shelter capacity expansion" — appear nowhere on the cited page, which contains no mention of homelessness, shelters, encampments, public camping, eviction or housing of any kind. The row's own strongest sentence is a negative: "No explicit bill banning public camping was signed." An absence of a bill is not a position. Cooper is a candidate for the United States Senate, so this row is voter-facing. Any statement of his on shelter, encampments or supportive housing would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']),

-- Roy Cooper / Misinformation — blank (S1 chair 3)
('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row states its own grounds and they are an absence: "No specific legislation or clear gubernatorial stance on social media misinformation or algorithmic regulation found in Cooper's record", followed by "no direct policy action was documented. Scored centrist." What it offers in place of evidence is an inference from party — "his general alignment with Democratic mainstream and support for democratic norms suggests support for voluntary standards and fact-checking". A party's general disposition is not a person's position, and a centre chair reads to a voter as a finding rather than as a gap. The cited page was read in full and contains no mention of misinformation, disinformation, social media, fact-checking or algorithms. Cooper is a candidate for the United States Senate, so this row is voter-facing. A statement of his on platform regulation or content moderation would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']),

-- Roy Cooper / Tariffs — blank (S1 chair 3)
('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row opens by conceding the point: "No specific tariff or trade policy position found in Cooper's gubernatorial record, where trade policy is primarily a federal issue." It then seats chair 3 anyway, on the inference that "as a pro-economic-development governor who actively recruited international manufacturers to NC, he pragmatically supported trade relationships". Recruiting employers to a state is economic development, not a tariff position, and the cited page carries no mention of tariffs, trade policy, protectionism or international recruitment in any case. The row's own observation that trade is a federal question is the more important one: Cooper is now a candidate for the United States Senate, so the question is squarely within the office he seeks and this row is voter-facing — which is a reason to answer it properly rather than to score it centrist. Any statement of his as a Senate candidate on tariffs would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Roy_Cooper']),

-- Debbie Dingell / AI Regulation — blank (S1 chair 3)
('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Dingell at chair 3 on a committee assignment: she "serves on the Energy & Commerce Committee's Communications & Technology subcommittee, which has jurisdiction over AI policy". The assignment is real and is on the cited page. But sitting on the committee that would consider a question is not holding a position on it — it describes where a member sits, not what she holds, and by that reasoning every member of the subcommittee would receive the same chair. The row then concedes the absence directly: "No documented support for a full ban or strict approval requirements, nor for a fully hands-off approach." The cited page contains no mention of artificial intelligence or AI anywhere, and nothing about her views on it. This is a blank, not a finding that the opposite is true. A bill of hers, a vote, or a statement on AI would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Debbie_Dingell']),

-- Debbie Dingell / Tariffs — blank (S1 chair 3)
('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row makes three specific claims and the cited page carries none of them: that she "has consistently supported targeted tariffs to protect American auto industry jobs", that she backed "trade agreements like USMCA when they include strong labor protections", and that she "does not support blanket high tariffs on all imports". The page was read in full. Its only occurrence of the word "trade" is in the name of a subcommittee she sits on; it has no mention of tariffs, USMCA or NAFTA at all. What it does carry is biography — that she worked for the General Motors Foundation and as a consultant to the American Automobile Policy Council, and that she represents a Michigan district. Employment history and the industry in a district are facts about circumstance, not positions, and inferring a trade stance from them is the same move as inferring one from party. This is a blank, not a finding that the opposite is true: Dingell may well hold exactly the view described. A recorded vote of hers on a trade measure, or a statement on tariffs, would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Debbie_Dingell']),

-- Andy Biggs / AI Regulation — blank (S1 chair 1)
('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Biggs on general ideology extended to a topic it was never about: he "has consistently opposed government regulation across all sectors and is a strong free-market advocate", and "his opposition to net neutrality regulations and general anti-regulatory posture are consistent with allowing AI companies to develop and deploy technology freely". The net-neutrality position is genuine and is on the cited page, in his own words — but it is a position about internet service providers in 2017, and carrying it across to artificial intelligence is an inference the source does not make. The page has an unusually detailed political-positions section covering abortion, agriculture, climate change, COVID-19, healthcare, LGBTQ rights, net neutrality, antitrust and more, and artificial intelligence appears in none of it. "Opposes regulation generally" is a disposition; a ladder rung is a position on a specific question. This is a blank, not a finding that the opposite is true. A statement or vote of his on AI would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Andy_Biggs']),

-- Carlos A. Gimenez / Abortion — blank (S1 chair 4)
('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row rests on a third-party aggregator that is not among its sources: "iSideWith records him as supporting abortion bans, aligning with a restrictive framework." iSideWith is a quiz site whose entries are inferred or self-reported, and citing it second-hand means the reader cannot check the claim at all. The one page actually cited was read in full and contains no mention of abortion, Planned Parenthood or reproductive policy. The row's remaining content is the bare assertion that "Gimenez is pro-life and opposes abortion access", which is the conclusion rather than evidence for it. Its hedge is honest and is worth preserving — "No evidence of support for a complete ban with criminal penalties" — but a chair cannot be built from the absence of evidence for the next rung up. This is a blank, not a finding that the opposite is true: he may well hold a restrictive position. A vote of his, or a statement of his own, would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']),

-- Carlos A. Gimenez / Ukraine-Russia Conflict — blank (S1 chair 4)
('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. Like the abortion row for the same member, this one rests on an aggregator that is not cited: "iSideWith records Gimenez as opposing military supplies and funding to Ukraine." The reader cannot check that, and the one page actually cited was read in full and contains no mention of Ukraine, Russia, foreign aid or military aid. The rest is a generalisation — "he consistently opposes foreign aid spending" — offered without an instance. This matters more than usual here because Ukraine funding has come to repeated recorded votes in the House, so an actual answer is available to anyone who looks: a named roll call would settle this in one step. This is a blank, not a finding that the opposite is true.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Carlos_A._Gimenez']),

-- Chuck Grassley / Jail Capacity — blank (S1 chair 3)
('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','f63a4e70-055e-4115-a5e0-3deeb5748816', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. Unusually for this cohort the evidence here is real, specific and well sourced: the cited First Step Act article confirms every factual claim in the row — that Grassley introduced S. 3649 in November 2018, that it added sentencing-reform provisions, that it drew more than forty bipartisan cosponsors, and that he was one of the measure's Senate champions alongside Durbin, Booker and Lee. None of that is in doubt. What it is not is evidence about jail capacity. The First Step Act governs federal sentencing, earned-time credits and reentry programming in the federal prison system; this ladder asks about jails and their capacity, and its chair 3 — upgrading facilities only as needed to meet constitutional standards, without expanding overall capacity — concerns buildings and bed counts. Nothing cited speaks to facilities, construction, overcrowding or capacity at all, and the row's bridging sentence, that he supports "upgrading facilities to constitutional standards", is not found in either source. Evidence must describe the chair it is seating. This is a blank, not a judgement that his sentencing record is wrong or weak; it is recorded here, with its source, so the next reader does not fetch it again.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Chuck_Grassley','https://en.wikipedia.org/wiki/First_Step_Act']),

-- Pete Ricketts / Misinformation — blank (S1 chair 4)
('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row is a description of a type rather than of a person: "Ricketts is a free-speech conservative who opposes government content moderation mandates. His deregulatory posture and general opposition to government interference in online platforms reflects preference for protecting speech over mandated fact-checking." No instance is given — no bill, no vote, no statement, no date. The cited page was read in full and contains no mention of misinformation, disinformation, content moderation, social media, fact-checking, Section 230, free speech or censorship. The chair was therefore derived from an ideological label, and an ideological label applied to a topic is the single most common defect in this audit. This is a blank, not a finding that the opposite is true: a senator of his politics may well hold exactly this view. A vote or a statement of his on platform regulation would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Pete_Ricketts']),

-- Laurel M. Lee / Misinformation — blank (S1 chair 3)
('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The underlying fact is true and is on the cited page: Lee introduced the bipartisan DEFIANCE Act, addressing non-consensual "deepfake" intimate images, and she serves on the House Task Force on Artificial Intelligence. That is a real legislative act of her own. It is not, however, evidence about misinformation. The DEFIANCE Act creates a civil remedy for image-based sexual abuse; the harm it addresses is to a specific victim, not the circulation of false claims, and the fact that the images are synthetic does not convert the subject into information policy. The chair it was filed under, chair 3, is "encourage voluntary standards for combating misinformation online" — and a binding federal cause of action is close to the opposite of a voluntary standard. The row half-admits the mismatch in its own closing words, offering "value=3 ... or targeted statutory intervention on specific harms", which is a description of a rung this ladder does not have. When a row argues with its own ladder, the row is usually right. This is a blank on misinformation specifically; the DEFIANCE Act is recorded in the sources so the next reader starts from it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Laurel_Lee_(politician)']),

-- Greg Landsman / Redistricting — blank (S1 chair 2)
('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','c7f973fc-33f5-4570-bfe2-bff4ac6141cc', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row states the inference openly rather than evidence: "Landsman as a Democrat from a competitive district supports independent redistricting commissions with equal representation from both parties rather than purely legislative control." The grounds offered are that he "flipped a seat previously held by a long-term Republican benefiting from gerrymandered maps" and that "Ohio has moved toward a bipartisan redistricting commission model" — one a fact about his predecessor, the other a fact about his state. Neither is a position of his. Both cited pages were read. His Wikipedia article contains no mention of redistricting, gerrymandering or commissions; the Ballotpedia page's occurrences of "redistricting" are all site navigation, not content about him. Notably, that same Ballotpedia page DOES carry a section of his own ballot-measure endorsements — it records positions where they exist — and redistricting is not among them. This is a blank, not a finding that the opposite is true. An endorsement, vote or statement of his on map-drawing would settle it.$r$,
 ARRAY['https://ballotpedia.org/Greg_Landsman','https://en.wikipedia.org/wiki/Greg_Landsman']),

-- Tim Moore / Religious Freedom — blank (S1 chair 4)
('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder, because its central claim misdescribes the bill it rests on. The Season 1 row says Moore "was instrumental in passing HB2 (2016), which allowed businesses to deny service based on religious objections". The cited page describes HB2 as a bathroom bill barring transgender people from using facilities matching their gender identity, and as a measure preempting local non-discrimination ordinances. It was not a religious-objection law, and nothing on the page connects it to religious exemptions. Moore's sponsorship of HB2 is real; what it is evidence of is a position on transgender facility access, which is a different question on a different ladder. The row's second ground, that he supported the 2012 state constitutional amendment defining marriage, is also on the page and is also a position about marriage rather than about faith-based exemptions from generally applicable laws. And the same page records a fact that cuts the other way and that the row passed over: in 2017, when conservative members proposed legislation to declare Obergefell "null and void", Moore blocked the bill from advancing. A chair must be seated on evidence about that chair, and a chair seated on a mischaracterised statute is worse than an unanswered one. This is a blank, not a finding that he holds the opposite view; a statement of his on religious exemptions would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Tim_Moore_(North_Carolina_politician)']),

-- Richard Neal / Residential Zoning — blank (S1 chair 3)
('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','ef2a5e59-525a-41fa-94de-ce771df7c927', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row says it in its opening sentence: "Neal has not taken a prominent federal position on local zoning reform." It then seats chair 3 on his tax-credit record instead — "community reinvestment through New Market Tax Credits and affordable housing incentives without mandating specific zoning changes" — and treats the absence of a zoning position as itself the deferential position, "consistent with deference to local governments on land use". That is a chair built out of silence, and it reads to a voter as a considered view on local control. The cited page was read in full and contains no mention of zoning, land use, housing or the New Market Tax Credit, so even the tax-credit premise is uncited there. This is a blank, not a finding that the opposite is true. It is also worth saying plainly for whoever re-researches it: a member of Congress may simply have no position on municipal zoning, and if that proves to be so, a blank is the correct permanent answer rather than a gap to be filled.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Richard_Neal']),

-- Dan Newhouse / Tariffs — blank (S1 chair 3)
('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row offers one instrument and it cannot carry a chair: "He voted for the USMCA (passed 385-41) supporting managed trade." A vote that lopsided cannot establish a DISTINCTIVE position, because being one of 385 is not a choice a ladder can seat — the cited agreement article records the breakdown as Republicans 192 to 2, so his vote is indistinguishable from his conference's. This is the same defect that blanked a Ukraine row in migration 1893 on a 417-10 vote. Everything else in the row is biography used as inference: that he is "an orchardist representing central Washington's agricultural export region", co-chairs an agricultural coalition, and that "his agricultural background places him in the selective-tariff camp". What a district grows is not what its member holds. Both cited pages were read: his own article has a political-positions section covering agriculture, LGBT rights, immigration and Ukraine, with nothing on trade or tariffs, and the USMCA article does not mention him at all. This is a blank, not a finding that the opposite is true. A divided trade vote or a statement of his on tariffs would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Dan_Newhouse','https://en.wikipedia.org/wiki/United_States%E2%80%93Mexico%E2%80%93Canada_Agreement']),

-- Eugene Vindman / Taxation — blank (S1 chair 2)
('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL,
 $r$Blank in Season 2 — researched. The underlying fact is TRUE and has been verified from the primary record rather than left as an assertion: Vindman voted against the One Big Beautiful Bill Act at both of its House votes — Nay on roll call 145 of 22 May 2025, "On Passage", which carried 215-214, and No on roll call 190 of 3 July 2025, "On Motion to Concur in the Senate Amendment", which carried 218-214. Both rolls are cited below. The blank is not about whether he cast those votes. It is that a NO vote and a YES vote are not symmetric evidence. A member who votes FOR a bill endorses its contents, which is why a yes on this same Act can seat a chair. A member who votes AGAINST it has only rejected that package, and rejection is equally consistent with wanting to raise taxes substantially, raise them moderately, or keep the present system as it is — chairs 1, 2 and 3 of this ladder. The Season 1 row chose chair 2, "moderately raise taxes on wealthy people and large companies", but opposing a tax CUT is not advocating a tax RISE, and the row's other ground is how "Democrats characterized OBBBA", which is other people's framing rather than his position. This is a blank, not a finding that the opposite is true, and it is a short step from being answered: the verified roll calls are kept in the sources so that the next reader starts with them, and one statement of his about rates would place him on the ladder.$r$,
 ARRAY['https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190','https://en.wikipedia.org/wiki/Eugene_Vindman','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act']),

-- Ted W. Lieu / Transgender Athletes — blank (S1 chair 1)
('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL,
 $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The row's facts are largely sound: Lieu did author California's 2012 ban on sexual-orientation change efforts for minors, which the cited page confirms in detail, and H.Res. 1058 of the 119th Congress is a real resolution recognising a duty to develop a Transgender Bill of Rights, with 110 cosponsors. Neither is about athletics. The resolution's own subject is medical care, shelter, safety and economic security; the conversion-therapy law concerns sexual orientation, not sport; and the third ground offered, a "100% rating from LGBTQ organizations", is an aggregate someone else computed. The chair assigned is rung 1, the absolute end of this ladder — allowing all transgender athletes to compete "without any restrictions or requirements" — and an absolute rung needs evidence that the person rejects the qualified alternatives, which is precisely what none of this shows. Even granting every fact, the record does not distinguish rung 1 from rung 2. The second cited source is his congress.gov member page, which is a structurally positionless directory listing and which also returns 403 to automated retrieval, so it was not read; that is recorded rather than glossed. This is a blank, not a finding that the opposite is true. A statement or vote of his on athletic eligibility would settle it.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Ted_Lieu','https://www.govtrack.us/congress/bills/119/hres1058']),

-- ── REPAIRS: chair unchanged, evidence replaced ───────────────────────────────────────────────

-- Greg Landsman / Abortion — chair 2 unchanged, reasoning rebuilt on the cited page's own content
('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL,
 $r$Landsman publicly endorsed Ohio Issue 1 of November 2023, the citizen initiative that wrote a right to make one's own reproductive decisions, including abortion, into the Ohio Constitution. Ballotpedia records the endorsement in its table of his notable ballot-measure positions, and the measure's own page independently lists "U.S. Rep. Greg Landsman (D)" among its official supporters. What he endorsed defines the chair: Issue 1 guarantees the right up to fetal viability and allows the state to restrict abortion after viability except where necessary to protect the pregnant patient's life or health. That is chair 2 — legal and accessible through the second trimester, with rare exceptions afterward — rather than chair 1's protection at all stages. It was a contested statewide question decided at a referendum, so taking a side on it is a position rather than an alignment. The chair is unchanged from Season 1; what changed is the evidence under it. The Season 1 row argued instead from co-sponsorship of the Women's Health Protection Act and from a 2022 campaign contrast with an opponent, neither of which appears on either page it cited.$r$,
 ARRAY['https://ballotpedia.org/Greg_Landsman','https://ballotpedia.org/Ohio_Issue_1,_Right_to_Make_Reproductive_Decisions_Including_Abortion_Initiative_(2023)']),

-- Nikema Williams / Childcare — chair 2 unchanged, vote now cited to the Clerk
('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','0e9fe0f2-cfab-4553-99cd-c3195d08e236', NULL,
 $r$Williams voted for the Build Back Better Act, H.R. 5376 of the 117th Congress: Yea on roll call 385 of 19 November 2021, "On Passage", which carried 220-213. The childcare provisions are what place the chair. The Act set aside about $400 billion for childcare and preschool, established universal pre-kindergarten for three- and four-year-olds, and capped childcare costs at 7% of income for families earning up to 250% of a state's median income, with funding routed through provider grants as well as family subsidies. A subsidy of that scale that is still bounded by an income test is chair 2 — significantly expanding subsidies and provider grants for low- and middle-income families — rather than chair 1's publicly funded universal childcare regardless of income. The bill failed in the Senate, but a recorded vote on a measure that passed by seven is a choice, not a formality. The chair is unchanged from Season 1; what changed is the evidence under it. The Season 1 row asserted the vote without citing it: her own article does not mention the Act, and the Act's article does not mention her. It is now cited to the Clerk of the House's own roll-call record, where the sheet distinguishes "Williams (GA)" from "Williams (TX)", so the identification is explicit rather than assumed.$r$,
 ARRAY['https://clerk.house.gov/Votes/2021385','https://en.wikipedia.org/wiki/Build_Back_Better_Act','https://en.wikipedia.org/wiki/Nikema_Williams']),

-- Thomas H. Kean, Jr. / Medicare and Medicaid — chair 4 unchanged, votes now cited to the Clerk
('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL,
 $r$Kean voted for the One Big Beautiful Bill Act, H.R. 1 of the 119th Congress, at both of its House votes: Yea on roll call 145 of 22 May 2025, "On Passage", which carried 215-214, and Aye on roll call 190 of 3 July 2025, "On Motion to Concur in the Senate Amendment", which carried 218-214. The Act reverses parts of Medicare's drug price negotiation programme, allowing more drugs to be purchased without negotiation, which the Congressional Budget Office scored at $5 billion in lost savings over ten years; and it imposes substantial Medicaid restrictions and funding reductions, including work requirements and tightened eligibility, partly offset by an enlarged Rural Hospital Fund. Voting twice for a statute that narrows Medicaid eligibility and weakens Medicare's negotiating position is chair 4 — scale back both programmes, shifting more coverage to private insurance — rather than chair 3's improve-while-controlling-costs. The chair is unchanged from Season 1; what changed is the evidence under it. The Season 1 row described the Act accurately but did not cite his vote, which neither of its sources recorded; the votes are now cited to the Clerk of the House. One limitation is recorded deliberately: this is an omnibus, and the Act's own article says Kean was among the members who traded their votes for a larger SALT deduction. A vote for a bill is not assent to every part of it, and a direct statement of his on Medicaid would be better evidence than a vote on a bill this wide.$r$,
 ARRAY['https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190','https://en.wikipedia.org/wiki/One_Big_Beautiful_Bill_Act','https://en.wikipedia.org/wiki/Tom_Kean_Jr.']),

-- Ken Paxton / Medicare and Medicaid — chair 4 unchanged, unsupported quotation removed
('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
 '86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL,
 $r$As Attorney General of Texas, Paxton initiated the litigation seeking to have the Affordable Care Act ruled unconstitutional in its entirety — the suit that reached the Supreme Court as California v. Texas and was decided in 2021. His own biography records that he brought it, and the case's own article confirms that his office brought one of the original lawsuits and that after the ruling he said he would continue to seek legal means to challenge the Act. Striking down the ACA in full would have ended its Medicaid expansion, under which states extended free or low-cost coverage to low-income residents, and would have returned those people to the private market. Pursuing that outcome, as his own initiative rather than as a party position, is chair 4 — scale back both programmes, shifting more coverage to private insurance. It is not chair 5: nothing on the record shows him seeking to phase out Medicare and Medicaid altogether, and the Season 1 row's caution on that point was correct and is kept. The chair is unchanged from Season 1. What is removed is a quotation: the Season 1 row attributed to him the phrase "massive government takeover" of healthcare, and neither cited page contains it. An attributed quotation that its own sources do not carry does not belong in voter-facing text, whatever its plausibility, so the claim now rests only on the litigation, which both sources do carry.$r$,
 ARRAY['https://en.wikipedia.org/wiki/Ken_Paxton','https://en.wikipedia.org/wiki/California_v._Texas']);

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ANSWERS: 24 rows. 20 blanks at value 0, 4 repairs carrying their Season 1 chair forward.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES
  -- blanks
  ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','ae53ba29-79eb-420f-aac6-ec99f8031ec6', NULL, 0), -- Whatley / campaign-finance   5 -> blank
  ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762','86d893a1-c1a2-4bbf-b4e5-69ec43221194','2010cab0-1968-4f24-b74d-ca47c2f90165', NULL, 0), -- Whatley / civil-rights       5 -> blank
  ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Cooper / ai-regulation       3 -> blank
  ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a','86d893a1-c1a2-4bbf-b4e5-69ec43221194','6958fa99-e317-45d7-8076-d11a0a78c897', NULL, 0), -- Cooper / homelessness        2 -> blank
  ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL, 0), -- Cooper / misinformation      3 -> blank
  ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413','86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL, 0), -- Cooper / tariffs             3 -> blank
  ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Dingell / ai-regulation      3 -> blank
  ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413','86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL, 0), -- Dingell / tariffs            3 -> blank
  ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c594dc06-0c70-4707-8ae0-d4bc760172db', NULL, 0), -- Biggs / ai-regulation        1 -> blank
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 0), -- Gimenez / abortion           4 -> blank
  ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901','86d893a1-c1a2-4bbf-b4e5-69ec43221194','107d180d-a949-4a42-a250-54f0a7683be0', NULL, 0), -- Gimenez / ukraine-support    4 -> blank
  ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0','86d893a1-c1a2-4bbf-b4e5-69ec43221194','f63a4e70-055e-4115-a5e0-3deeb5748816', NULL, 0), -- Grassley / jail-capacity     3 -> blank
  ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL, 0), -- Ricketts / misinformation    4 -> blank
  ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','bd313c07-02a5-4344-8cc3-0e4b4c3b78a1', NULL, 0), -- Lee / misinformation         3 -> blank
  ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','c7f973fc-33f5-4570-bfe2-bff4ac6141cc', NULL, 0), -- Landsman / redistricting     2 -> blank
  ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dfbd847a-294c-49d2-9ac3-69270ea03054', NULL, 0), -- Moore / religious-freedom    4 -> blank
  ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d','86d893a1-c1a2-4bbf-b4e5-69ec43221194','ef2a5e59-525a-41fa-94de-ce771df7c927', NULL, 0), -- Neal / residential-zoning    3 -> blank
  ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413','86d893a1-c1a2-4bbf-b4e5-69ec43221194','9f094155-f604-47e8-93db-54a3142420ca', NULL, 0), -- Newhouse / tariffs           3 -> blank
  ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb','86d893a1-c1a2-4bbf-b4e5-69ec43221194','87f8c011-5c70-4f39-a1ea-5cc53c010c60', NULL, 0), -- Vindman / taxes              2 -> blank
  ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4','86d893a1-c1a2-4bbf-b4e5-69ec43221194','af2c6427-daf8-4819-93ba-42db212bae68', NULL, 0), -- Lieu / trans-athletes        1 -> blank
  -- repairs: chair carried forward unchanged
  ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f','86d893a1-c1a2-4bbf-b4e5-69ec43221194','dab46e5c-628a-4360-ad1d-3aaba61768f0', NULL, 2), -- Landsman / abortion          2 -> 2
  ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c','86d893a1-c1a2-4bbf-b4e5-69ec43221194','0e9fe0f2-cfab-4553-99cd-c3195d08e236', NULL, 2), -- Williams / childcare         2 -> 2
  ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b','86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL, 4), -- Kean / medicare-aid          4 -> 4
  ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b','86d893a1-c1a2-4bbf-b4e5-69ec43221194','38bab357-9790-4cb3-a6d2-c43cbdca615b', NULL, 4); -- Paxton / medicare-aid        4 -> 4

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE ONE UPDATE: Whatley / same-sex-marriage already has a Season 2 row, so it is blanked in
-- place rather than inserted. Season 2 is open; the immutability trigger guards Season 1 only.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
UPDATE inform.politician_context
   SET reasoning = $r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 and Season 2 rows both seated Whatley at chair 5, the most extreme rung, on this reasoning: "Whatley is a conservative Christian (holds theology degree) who aligned with the NC GOP platform opposing same-sex marriage. The NCGOP under his chairmanship maintained the party's traditional marriage position and opposed LGBTQ+ protections." Two separate problems. A degree is not a position: the cited page's only support for any of this is the biographical fact that he earned a master's degree in religion in 1993 and a master's in theology in 1994, which says nothing about what he holds on marriage. And a party platform is not an individual's position, even when that individual chairs the party. Beyond the degree, the cited page was read in full and contains no mention of same-sex marriage, marriage, LGBT people or related protections anywhere. Seating the most extreme available rung on a graduate degree is the clearest case of inference-as-evidence in this cohort. This is a blank, not a finding that the opposite is true — he may well oppose same-sex marriage. Whatley is a candidate for the United States Senate, so this row is voter-facing, and it is re-researchable from his own statements or his campaign's materials.$r$,
       sources = ARRAY['https://en.wikipedia.org/wiki/Michael_Whatley']
 WHERE politician_id = '867caca5-ab41-4e1b-b051-4a2cd95a335e'
   AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
   AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

UPDATE inform.politician_answers
   SET value = 0
 WHERE politician_id = '867caca5-ab41-4e1b-b051-4a2cd95a335e'
   AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
   AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

DO $$
DECLARE n int;
BEGIN
  -- 24 answer rows inserted, and the same 24 context rows beside them. A context row without an
  -- answer row, or the reverse, is invisible to parts of the sourcing gate (migration 1862).
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND EXISTS (SELECT 1 FROM inform.politician_context c
                  WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                    AND c.season_id = a.season_id AND c.reasoning IS NOT NULL)
     AND (a.politician_id, a.topic_id) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413'),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901'),
       ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
       ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
       ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4'));
  IF n <> 24 THEN
    RAISE EXCEPTION 'migration 1894: expected 24 paired Season 2 answer+context rows, found %', n;
  END IF;

  -- 21 blanks in Season 2 across the whole cohort: the 20 inserted plus Whatley/same-sex-marriage.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND value = 0
     AND (politician_id, topic_id) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413'),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901'),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4'));
  IF n <> 21 THEN
    RAISE EXCEPTION 'migration 1894: expected 21 Season 2 blanks, found %', n;
  END IF;

  -- The 4 repairs must land at their ORIGINAL chairs. Naming triples, not a value list: asserting
  -- `value IN (2,2,4,4)` would pass if two of them swapped chairs with each other.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (politician_id, topic_id, value) IN (
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2),
       ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c', 2),
       ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4),
       ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4));
  IF n <> 4 THEN
    RAISE EXCEPTION 'migration 1894: the 4 repairs are not at their original chairs (found %)', n;
  END IF;

  -- Hamadeh was judged SOUND and Ezell is blocked: neither may have gained a Season 2 row here.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (politician_id, topic_id) IN (
       ('ed20dd3f-a463-43c0-b08c-23cbf2a5e387','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('0fd6132b-eb62-461d-98f7-8449fb3adbf2','4e2c69ce-591e-4197-9cd5-7aceff79d390'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1894: Hamadeh/Ezell should have no Season 2 row, found %', n;
  END IF;

  -- Season 1 must be EXACTLY as it was, per row. A forward write that moved history is a failed one.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND (politician_id, topic_id, value) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','c5ab4eab-702f-49b8-9277-8ea53f3835c6', 5),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d', 5),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762', 5),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a', 2),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023', 1),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f', 2),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901', 4),
       ('acb046eb-1db6-44bf-a50b-32d16df15057','c1ac1330-47f7-44ec-baf3-c913d926b97c', 2),
       ('0fd6132b-eb62-461d-98f7-8449fb3adbf2','4e2c69ce-591e-4197-9cd5-7aceff79d390', 4),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 3),
       ('1bc949f5-0696-481c-979b-64cfd494983a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4),
       ('d0ce1d94-216a-46ed-acc8-6febccfe1844','cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3),
       ('ed20dd3f-a463-43c0-b08c-23cbf2a5e387','ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd', 4),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d', 3),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413', 3),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb', 2),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 1));
  IF n <> 27 THEN
    RAISE EXCEPTION 'migration 1894: Season 1 no longer holds its original 27 chairs unchanged (found %)', n;
  END IF;

  -- No blank may ship with an empty source array (migration 1887).
  SELECT count(*) INTO n FROM inform.politician_context c
   JOIN inform.politician_answers a
     ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value = 0
     AND (c.sources IS NULL OR array_length(c.sources,1) IS NULL)
     AND (c.politician_id, c.topic_id) IN (
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','92730f69-ae57-401c-8ad1-2d07834a895d'),
       ('867caca5-ab41-4e1b-b051-4a2cd95a335e','0bc588c6-39e1-4084-b5de-cac909b8b762'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','4938766b-b45a-46e3-93bd-b8b30651271a'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('1f7429f7-1ecd-4f44-abce-03c72d5cf664','683c8084-2281-4920-a07c-18439b2dd413'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('91d28127-8183-4b67-a1fb-dc8a150f6199','683c8084-2281-4920-a07c-18439b2dd413'),
       ('8118811a-aadd-4eb9-9208-de0f5d3b29ad','666bf03d-81fc-4138-ab15-69ae734c9023'),
       ('6cad043f-a4c0-48d5-af76-fdf70d319920','48cc9585-ec22-4f53-8d42-6839828dd36f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
       ('3030383b-2aaf-40fd-9dfb-8867d1d02f99','24e9212c-b011-422a-865c-093e35050901'),
       ('dd5d3f6d-fc82-4774-b510-287ec47cbd84','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
       ('d01ea902-317a-4a66-b346-8b29a91fcd25','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('96cc507d-bb3a-4e25-ae6c-4b937f68f9f4','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
       ('e27f0fc2-ef98-4592-ae87-f6320f2b847e','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
       ('a0cb697c-3158-4680-8e70-c154c3a15cc4','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
       ('85e712ff-8b13-4a29-8c94-cb4394650d73','683c8084-2281-4920-a07c-18439b2dd413'),
       ('9a9d6b64-60b3-40c9-b213-4088d9a51e68','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
       ('3a39c313-b994-447b-b3fd-592e4994769b','d1618b9c-0b9e-45af-b986-bb33d270b8e4'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1894: % blank(s) carry no sources', n;
  END IF;
END $$;

COMMIT;

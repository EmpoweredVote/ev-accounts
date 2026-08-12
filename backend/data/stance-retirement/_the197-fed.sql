-- _the197-fed.sql
-- "The 197" — Tier B rows whose only citation was an encyclopaedia bio that never mentions the
-- topic. Twelve of them rest on a RECORDED VOTE nobody had looked up, so they are re-sourced
-- rather than retired. One is a chair correction.
--
-- 🔑 A BAD CITATION IS NOT A FALSE CLAIM. The Tier B cut measured the SOURCE, not the truth of
-- the sentence. Reading each row and looking for the evidence elsewhere turned a putative
-- retirement queue into twelve properly sourced rows (precedent 1690/1692).
--
-- ⚠ Every citation URL below was fetched and checked for its own content before being written.
-- The Clerk page for H.R.28 contains "Protection of Women and Girls in Sports" and "Tran"; the
-- Senate page for 115-2-271 contains "S. 756", "First Step" and "Risch". A 200 is not identity.
--
-- ⚠ Roll numbers came from the Clerk's own year index, never from recall. H.R.7691's passage
-- vote is 2022 roll 145; the remembered guess was 209. Matching on the bill number alone also
-- is not enough — it first selected an AMENDMENT to H.R.8035 (105-319) and reported it as the
-- Ukraine aid vote (311-112). Bill number AND passage-shaped question, and every matching roll
-- evaluated, because H.R.8404 has two (267-157 in July, 258-169 in December).
--
-- 🔴 CHAIR CORRECTION, Lisa C. McClain / Ukraine - Russia Conflict: 2 -> 4.
-- stored reasoning asserted she "supported the 2024 Ukraine-Israel-Taiwan foreign aid package (360-58)"; 360-58 is H.R.8038, and her vote on the Ukraine bill itself was NAY.
--
-- Rollback: data/stance-retirement/2026-08-12-the-197-fed-rollback.json
BEGIN;

CREATE TEMP TABLE the197_fed_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

-- Derek Tran / Transgender Athletes
--   replaces caucus-membership inference with the recorded vote
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/202512']::text[], reasoning = 'Voted NAY on H.R.28, the Protection of Women and Girls in Sports Act, on 14-Jan-2025 (roll call 12, 218-206). The bill would have barred transgender girls and women from female school athletic programs receiving federal funds; Tran voted against it.'
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid;

-- Dina Titus / Same-Sex Marriage
--   replaces caucus-membership inference with two recorded votes
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2022373','https://clerk.house.gov/Votes/2022513']::text[], reasoning = 'Voted YEA on H.R.8404, the Respect for Marriage Act, at House passage on 19-Jul-2022 (roll call 373, 267-157) and YEA again on the motion to concur in the Senate amendment on 8-Dec-2022 (roll call 513, 258-169). The Act requires federal and interstate recognition of same-sex marriages.'
WHERE politician_id = '786af5d2-9502-401c-a3ed-61de88e589e9'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Lisa C. McClain / Same-Sex Marriage
--   claim was already right; only the citation was an encyclopaedia bio
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2022373','https://clerk.house.gov/Votes/2022513']::text[], reasoning = 'Voted NAY on H.R.8404, the Respect for Marriage Act, at House passage on 19-Jul-2022 (roll call 373, 267-157) and NAY again on the motion to concur in the Senate amendment on 8-Dec-2022 (roll call 513, 258-169). The Act would require all states to recognise same-sex marriages. No record was found of her seeking to prohibit same-sex marriage or impose penalties.'
WHERE politician_id = 'e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- James Risch / Jail Capacity and Incarceration Alternatives
--   one of 12 nays — a lopsided vote, but being in the 12 is the distinctive fact
UPDATE inform.politician_context SET sources = ARRAY['https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=115&session=2&vote=00271']::text[], reasoning = 'Voted NAY on S.756, the First Step Act, on 18 December 2018 (Senate roll call 271, 87-12). The Act reduced mandatory minimums and expanded earned-time credit and diversion for federal prisoners; Risch was one of the twelve senators opposing it.'
WHERE politician_id = '9a41971c-1e38-41b8-a6ec-bec6055a00b3'::uuid AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid;

-- Juan Ciscomani / Taxation and Public Spending
--   both passage votes recorded; each was decided by a single-digit margin
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2025145','https://clerk.house.gov/Votes/2025190']::text[], reasoning = 'Voted YEA on H.R.1, the One Big Beautiful Bill Act, at House passage on 22-May-2025 (roll call 145, 215-214) and again on the motion to concur in the Senate amendment on 3-Jul-2025 (roll call 190, 218-214). The Act makes the 2017 individual tax rates permanent and adds further deductions, reducing federal revenue.'
WHERE politician_id = 'c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid;

-- Brad Finstad / Healthcare Access
--   a vote against a package; it evidences opposition to those provisions, not a stated healthcare philosophy
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2022420']::text[], reasoning = 'Voted NAY on H.R.5376, the Inflation Reduction Act, on 12-Aug-2022 (roll call 420, 220-207). Its health provisions included Medicare drug-price negotiation and a three-year extension of the enhanced ACA premium subsidies.'
WHERE politician_id = 'dc0a717a-67ef-4ca2-9c43-4896fad03392'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid;

-- Norma Torres / Childcare Affordability & Access
--   both are omnibus votes; they evidence support for the packages containing childcare expansion
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2021385','https://clerk.house.gov/Votes/202172']::text[], reasoning = 'Voted YEA on H.R.5376, the Build Back Better Act, on 19-Nov-2021 (roll call 385, 220-213), which carried universal pre-kindergarten and capped childcare costs as a share of family income, and YEA on H.R.1319, the American Rescue Plan Act, on 10-Mar-2021 (roll call 72, 220-211), which expanded the child and dependent care tax credit.'
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid;

-- Norma Torres / Economic Development Incentives
--   IIJA cited at the concurrence vote that enacted it, not the earlier INVEST Act passage
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2022404','https://clerk.house.gov/Votes/2022420','https://clerk.house.gov/Votes/2021369']::text[], reasoning = 'Voted YEA on H.R.4346, the CHIPS and Science Act, on 28-Jul-2022 (roll call 404, 243-187); YEA on H.R.5376, the Inflation Reduction Act, on 12-Aug-2022 (roll call 420, 220-207); and YEA on H.R.3684, the Infrastructure Investment and Jobs Act, on 5-Nov-2021 (roll call 369, 228-206). All three direct targeted federal investment into named industries and infrastructure.'
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid;

-- Elaine Luria / Ukraine - Russia Conflict
--   near-unanimous 368-57 — stated in the reasoning rather than glossed
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2022145']::text[], reasoning = 'Voted YEA on H.R.7691, the Additional Ukraine Supplemental Appropriations Act, on 10-May-2022 (roll call 145, 368-57). The vote was lopsided, so it confirms that she supported the aid rather than distinguishing her from colleagues.'
WHERE politician_id = '2a22bd69-fd7a-4782-9057-4647fdb4e7cb'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;

-- Dusty Johnson / Ukraine - Russia Conflict
--   the 101-112 Republican split was counted off the roll-call sheet itself
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2024151']::text[], reasoning = 'Voted YEA on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on 20-Apr-2024 (roll call 151, 311-112). Republicans split 101 yes to 112 no on that vote, so his yes was against the majority of his own conference.'
WHERE politician_id = '4ec42691-0ce1-4f29-a6ba-0835fe35a963'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;

-- Rick Larsen / Ukraine - Russia Conflict
--   replaces a FiveThirtyEight presidential-alignment score, which is not a Ukraine position
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2024151']::text[], reasoning = 'Voted YEA on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on 20-Apr-2024 (roll call 151, 311-112).'
WHERE politician_id = '3a2bf7c8-5a49-4d53-88c4-0d4bc6ad17b0'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;

-- Frank J. Mrvan / Ukraine - Russia Conflict
--   replaces a vote on Syria war powers, which is a different conflict
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2024151']::text[], reasoning = 'Voted YEA on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on 20-Apr-2024 (roll call 151, 311-112).'
WHERE politician_id = 'e08ec276-3194-41d4-833b-953f27454857'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;

-- Lisa C. McClain / Ukraine - Russia Conflict
--   stored reasoning asserted she "supported the 2024 Ukraine-Israel-Taiwan foreign aid package (360-58)"; 360-58 is H.R.8038, and her vote on the Ukraine bill itself was NAY
UPDATE inform.politician_context SET sources = ARRAY['https://clerk.house.gov/Votes/2024151','https://clerk.house.gov/Votes/2024145','https://clerk.house.gov/Votes/2024152','https://clerk.house.gov/Votes/2022141']::text[], reasoning = 'Voted NAY on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on 20-Apr-2024 (roll call 151, 311-112) — the April 2024 bill that funded continued military assistance to Ukraine. On the same day she voted YEA on H.R.8038, the 21st Century Peace through Strength Act (roll call 145, 360-58), and YEA on H.R.8034, the Israel Security Supplemental (roll call 152, 366-58), so she supported the other bills in that package while opposing the Ukraine appropriation specifically. She had earlier voted YEA on S.3522, the Ukraine Democracy Defense Lend-Lease Act (roll call 141, 417-10), a near-unanimous vote that does not distinguish her position.'
WHERE politician_id = 'e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid AND value = 2;

-- Guard 1: every touched row must now cite a roll-call page and NO encyclopaedia article.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (('b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid), ('786af5d2-9502-401c-a3ed-61de88e589e9'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid), ('e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid), ('9a41971c-1e38-41b8-a6ec-bec6055a00b3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid), ('c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid), ('dc0a717a-67ef-4ca2-9c43-4896fad03392'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid), ('2a22bd69-fd7a-4782-9057-4647fdb4e7cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('4ec42691-0ce1-4f29-a6ba-0835fe35a963'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('3a2bf7c8-5a49-4d53-88c4-0d4bc6ad17b0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('e08ec276-3194-41d4-833b-953f27454857'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid))
    AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%clerk.house.gov/Votes/%' OR s LIKE '%senate.gov/legislative/LIS/roll_call_lists/%')
      OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%wikipedia.org%' OR s LIKE '%ballotpedia.org%'));
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) lack a roll call or still cite an encyclopaedia', bad; END IF;
END $$;

-- Guard 2: exactly 13 rows touched, and the one chair change is the one intended.
DO $$
DECLARE n int; v numeric;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context c WHERE (c.politician_id, c.topic_id) IN (('b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid), ('786af5d2-9502-401c-a3ed-61de88e589e9'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid), ('e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid), ('9a41971c-1e38-41b8-a6ec-bec6055a00b3'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid), ('c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid), ('dc0a717a-67ef-4ca2-9c43-4896fad03392'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid), ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid), ('2a22bd69-fd7a-4782-9057-4647fdb4e7cb'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('4ec42691-0ce1-4f29-a6ba-0835fe35a963'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('3a2bf7c8-5a49-4d53-88c4-0d4bc6ad17b0'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('e08ec276-3194-41d4-833b-953f27454857'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid), ('e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid));
  IF n <> 13 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 13', n; END IF;
  SELECT a.value INTO v FROM inform.politician_answers a
   WHERE a.politician_id = 'e04094d1-247c-40c8-8829-c7cb8654d0ed'::uuid AND a.topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid;
  IF v <> 4 THEN RAISE EXCEPTION 'guard 2 failed: McClain/Ukraine chair is %, expected 4', v; END IF;
END $$;

-- Guard 3: citations and one chair value only — nothing created or deleted.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM the197_fed_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context rows moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 3 failed: answer rows moved % -> %', snap.ans_before, ans_after; END IF;
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'the-197 federal ok: context=% (unchanged) answers=% (unchanged) orphans=%', ctx_after, ans_after, orphans;
END $$;

COMMIT;

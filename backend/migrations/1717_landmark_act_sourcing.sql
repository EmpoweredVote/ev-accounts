-- 1717_landmark_act_sourcing.sql
-- LANDMARK-ACT SOURCING for 23 of the 71 rows migration 1714 corrected but could not re-source.
--
-- 1714 fixed 89 chairs that sat at the OPPOSITE POLE from their own reasoning. It could only
-- re-source 18 of them, because only Civil Rights and Same-Sex Marriage bills had been crawled.
-- These 23 rows name a landmark act outright — the Blueprint for Maryland's Future (11) or the
-- Climate Solutions Now Act (12) — so each act was resolved ONCE and every member tested against
-- its full sponsor list and its passage roll calls.
--
-- 🔑 CHAIRS ARE NOT TOUCHED. Reasoning and sources only; inform.politician_answers is untouched.
--
-- 🔑 SOURCES ARE ADDED, NOT SWAPPED. The encyclopaedia bios on these rows were never checked
-- against the claim. A citation VERIFIED not to carry a claim may be dropped; an unchecked one
-- may not, so every primary citation is prepended and nothing is removed.
--
-- ⚠ TWO ROWS WERE PRE-TENURE — the claim could not be true:
--   Kevin M. Harris  (House 2023-2025, Senate from Dec 2025) credited with the 2021/2022 Act
--   C. Anthony Muse  (Senate 2007-2019, then from 2023) — the Act falls squarely in his gap
-- Retirement is what is left AFTER looking, so both were re-sourced to real in-tenure clean-energy
-- sponsorships (Harris SB0669/SB0923 2026; Muse SB0120 2025, Chapter 516) rather than retired.
--
-- ⚠ A NEAR-UNANIMOUS VOTE IS NOT A POSITION. SB1030/2019 passed the Senate 43-1 and then 45-0;
-- those sheets are deliberately NOT cited. Every vote cited here had >=10% voting against.
--
-- 🔴 THREE IDENTITY TRAPS WERE LIVE IN THIS SET, each of which would have published a false claim:
--   · SB0528/SB0414 are SENATE bills, so their "Washington" is Senator MARY Washington
--     (washington01), not Delegate Alonzo T. Washington (washington02). The sponsor HYPERLINK
--     settles identity where a surname cannot — but a retired slug proves nothing, so HB1300's
--     now-dead 'washington' link falls back to surname plus the chamber gate.
--   · Ron Watson joined the Senate on 31 Aug 2021, AFTER the 2021 session adjourned, so his 2021
--     votes are HOUSE votes; assuming a January swearing-in put him in the wrong chamber.
--   · Sara Love's mgaleg tenure field omits her House service entirely, so her whole Blueprint-era
--     record fell outside her tenure and the test silently never ran.
--
-- Rollback: data/stance-retirement/2026-08-12-landmark-1717-rollback.json
BEGIN;

CREATE TEMP TABLE lm_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;

CREATE TEMP TABLE lm_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO lm_intent (pid, tid, reasoning, sources) VALUES
-- Joanne C. Benson / Climate Change and Environmental Protection — VOTE (vote: 2022RS SB0528 32-15)
('4a7dc8a6-2138-4472-8197-8b878034f029', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Benson voted Yea on SB0528 (2022), the Climate Solutions Now Act, which passed the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]),
-- Nick Charles / Climate Change and Environmental Protection — VOTE (vote: 2022RS SB0528 95-42)
('cf190bac-9369-4175-bd4b-8ba776697d9c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Charles voted Yea on SB0528 (2022), the Climate Solutions Now Act, which passed the House 95-42. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]),
-- Arthur Ellis / Climate Change and Environmental Protection — SPONSOR (sponsor: 2022RS SB0528) (vote: 2022RS SB0528 32-15)
('4754dede-4a3b-4280-a8b1-7497530107f7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Ellis was one of 27 sponsors of SB0528 (2022), the Climate Solutions Now Act, and voted for it on passage, which cleared the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]),
-- Kevin M. Harris / Climate Change and Environmental Protection — RESOURCED_PRETENURE
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Harris is the lead sponsor of SB0669 (2026), which extends the Small Solar Energy Generating System Incentive Program deadline to 2031 and doubles eligible in-State solar capacity from 270 to 540 megawatts. He also introduced SB0923 (2026), establishing solar photovoltaic, energy storage and zero-emission vehicle funds, which he later withdrew.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0669?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0923?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03','https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]),
-- Shaneka Henson / Climate Change and Environmental Protection — VOTE (vote: 2022RS SB0528 95-42)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Henson voted Yea on SB0528 (2022), the Climate Solutions Now Act, which passed the House 95-42. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]),
-- William C. Smith, Jr. / Climate Change and Environmental Protection — SPONSOR (sponsor: 2022RS SB0528) (vote: 2022RS SB0528 32-15)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Smith was one of 27 sponsors of SB0528 (2022), the Climate Solutions Now Act, and voted for it on passage, which cleared the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]),
-- Benjamin F. Kramer / Climate Change and Environmental Protection — SPONSOR (sponsor: 2022RS SB0528) (vote: 2022RS SB0528 32-15)
('7a2d1548-3268-4767-97a8-bb8b142d5a33', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Kramer was one of 27 sponsors of SB0528 (2022), the Climate Solutions Now Act, and voted for it on passage, which cleared the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]),
-- C. Anthony Muse / Climate Change and Environmental Protection — RESOURCED_PRETENURE
('47823046-7dea-4a4f-a11b-0c5890539891', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Muse is the sponsor of SB0120 (2025), enacted as Chapter 516, which bars land-use restrictions that raise the cost of installing a solar collector system by 5% or more, or that cut its efficiency by 10% or more.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0120?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/muse01','https://ballotpedia.org/C._Anthony_Muse']::text[]),
-- Jim Rosapepe / Climate Change and Environmental Protection — SPONSOR (sponsor: 2021RS SB0414) (vote: 2022RS SB0528 32-15)
('9c400214-f007-4a8d-92fe-5f5d23b3838e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Rosapepe was one of 21 sponsors of SB0414 (2021), the Climate Solutions Now Act, and voted Yea on SB0528 (2022), which passed the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]),
-- Jeff Waldstreicher / Climate Change and Environmental Protection — SPONSOR (sponsor: 2022RS SB0528) (vote: 2022RS SB0528 32-15)
('da75c207-bb23-477e-b3c0-7c462394b570', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Waldstreicher was one of 27 sponsors of SB0528 (2022), the Climate Solutions Now Act, and voted for it on passage, which cleared the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]),
-- Alonzo T. Washington / Climate Change and Environmental Protection — VOTE (vote: 2022RS SB0528 95-42)
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Washington voted Yea on SB0528 (2022), the Climate Solutions Now Act, which passed the House 95-42. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02','https://ballotpedia.org/Alonzo_Washington']::text[]),
-- Ron Watson / Climate Change and Environmental Protection — SPONSOR (sponsor: 2022RS SB0528) (vote: 2022RS SB0528 32-15)
('9aef8bfb-8e0c-4f00-9898-c738abe4970c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Watson was one of 27 sponsors of SB0528 (2022), the Climate Solutions Now Act, and voted for it on passage, which cleared the Senate 32-15. Enacted as Chapter 38 of 2022, SB0528 establishes a net-zero statewide greenhouse gas emissions goal and directs benefits to communities it defines as overburdened and underserved.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/2022RS/chapters_noln/Ch_38_sb0528E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]),
-- Joanne C. Benson / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 37-9)
('4a7dc8a6-2138-4472-8197-8b878034f029', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Benson voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]),
-- Nick Charles / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 96-41)
('cf190bac-9369-4175-bd4b-8ba776697d9c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Charles voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the House 96-41. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]),
-- Arthur Ellis / Childcare Affordability & Access — SPONSOR (sponsor: 2019RS SB1030) (vote: 2020RS HB1300 37-9)
('4754dede-4a3b-4280-a8b1-7497530107f7', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Ellis was one of 19 sponsors of SB1030 (2019), the Blueprint for Maryland''s Future, and voted Yea on HB1300 (2020), which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]),
-- Shaneka Henson / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 96-41)
('05c9b5b9-cb2b-4387-ab6b-350b69553fac', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Henson voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the House 96-41. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]),
-- William C. Smith, Jr. / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 37-9)
('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Smith voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1372?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/senate/0749.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith02','https://ballotpedia.org/William_C._Smith']::text[]),
-- Cheryl C. Kagan / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 37-9)
('e35d5990-55c7-42e2-94bc-27cb1c49b5f1', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Kagan voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]),
-- Sara Love / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 96-41)
('c5d2cd24-170a-4f87-8fde-84216fe62806', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Love voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the House 96-41. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02','https://ballotpedia.org/Sara_Love']::text[]),
-- Jim Rosapepe / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 37-9)
('9c400214-f007-4a8d-92fe-5f5d23b3838e', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Rosapepe voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]),
-- Jeff Waldstreicher / Childcare Affordability & Access — SPONSOR (sponsor: 2019RS SB1030) (vote: 2020RS HB1300 37-9)
('da75c207-bb23-477e-b3c0-7c462394b570', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Waldstreicher was one of 19 sponsors of SB1030 (2019), the Blueprint for Maryland''s Future, and voted Yea on HB1300 (2020), which passed the Senate 37-9. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/waldstreicher1','https://ballotpedia.org/Jeff_Waldstreicher']::text[]),
-- Alonzo T. Washington / Childcare Affordability & Access — SPONSOR (sponsor: 2020RS HB1300) (vote: 2020RS HB1300 96-41)
('8c8b0896-dfd0-4d3c-8492-e594d93b78ca', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Washington was one of 7 sponsors of HB1300 (2020), the Blueprint for Maryland''s Future, and voted for it on passage, which cleared the House 96-41. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington02','https://ballotpedia.org/Alonzo_Washington']::text[]),
-- Ron Watson / Childcare Affordability & Access — VOTE (vote: 2020RS HB1300 96-41)
('9aef8bfb-8e0c-4f00-9898-c738abe4970c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'Watson voted Yea on HB1300 (2020), the Blueprint for Maryland''s Future, which passed the House 96-41. Enacted as Chapter 36 of 2021, HB1300 establishes a publicly funded full-day prekindergarten program and extends Child Care Scholarship Program access for income-eligible families.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/2021RS/chapters_noln/Ch_36_hb1300E.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM lm_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: every targeted row now holds its intended reasoning, and carries a primary citation.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM lm_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;
END $$;

-- Guard 2: exactly 23 rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.
DO $$
DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM lm_snapshot;
  SELECT count(*) INTO n FROM lm_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;
  IF n <> 23 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 23', n; END IF;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  -- this pass must not move a single chair; 1714 already set them
  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'landmark sourcing ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;
END $$;

COMMIT;

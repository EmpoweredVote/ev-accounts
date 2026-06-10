-- Phase 112-03: VA House Delegate Stances — Wave 3 (HD-31–36 Central/Shenandoah + HD-56–59 Piedmont East, non-contiguous)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave3.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  50
--   INSERT INTO inform.politician_answers count: 50
--   INSERT INTO inform.politician_context count: 50
--   max_migration at authoring: 325 (psql-applied waves 326–332 not tracked in schema_migrations)
--
-- Stances written (9 delegates with documentable positions):
--   Delores Oates         (HD-31, R): 4 stances — abortion(4), immigration(4), same-sex-marriage(4), voting-rights(4)
--   William D. Wiley      (HD-32, R): 3 stances — abortion(4), same-sex-marriage(4), civil-rights(4)
--   Tony O. Wilt          (HD-34, R): 3 stances — abortion(4), same-sex-marriage(4), civil-rights(4)
--   Chris Runion          (HD-35, R): 6 stances — abortion(4), same-sex-marriage(4), civil-rights(4), religious-freedom(4), taxes(4), school-vouchers(4)
--   Ellen H. McLaughlin   (HD-36, R): 5 stances — abortion(4), taxes(4), healthcare(3), school-vouchers(3), fossil-fuels(3)
--   Thomas A. Garrett Jr. (HD-56, R): 12 stances — abortion(4), immigration(5), same-sex-marriage(4), taxes(4), school-vouchers(4), voting-rights(4), civil-rights(4), religious-freedom(4), fossil-fuels(4), climate-change(4), healthcare(4), social-security(4)
--   May Nivar             (HD-57, D): 4 stances — abortion(2), healthcare(2), medicare/aid(2), school-vouchers(1)
--   Rodney T. Willett     (HD-58, D): 9 stances — abortion(2), healthcare(2), medicare/aid(2), childcare(2), climate-change(3), civil-rights(2), same-sex-marriage(1), school-vouchers(2), housing(3)
--   Hyland F. Fowler Jr.  (HD-59, R): 4 stances — abortion(4), same-sex-marriage(4), civil-rights(4), religious-freedom(4)
--
-- Honest skip (1 delegate — no documentable policy positions found):
--   Justin L. Pence       (HD-33, R): no Ballotpedia page, not on Family Foundation scorecard (newly elected 2025), vpap.org blocked, no campaign website found
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave3-preflight.json):
--   Delores Oates         (HD-31, ext_id -5120031) -> 11b44fd4-cbc4-415e-b567-c63f657fceab
--   William D. Wiley      (HD-32, ext_id -5120032) -> c5490995-b962-4b20-ab8d-56ba1ba8d54b
--   Justin L. Pence       (HD-33, ext_id -5120033) -> e345c9d6-4e28-4416-86de-24ab84c803f9  [skip]
--   Tony O. Wilt          (HD-34, ext_id -5120034) -> 742d2c42-b277-4859-9269-1abc55affbe2
--   Chris Runion          (HD-35, ext_id -5120035) -> f3908370-f489-4a77-96f3-b19bf983618e
--   Ellen H. McLaughlin   (HD-36, ext_id -5120036) -> 94a1f084-689c-4774-8d36-fff2212af94d
--   Thomas A. Garrett Jr. (HD-56, ext_id -5120056) -> e8228875-8fed-4f62-8184-22c5bb0093e1
--   May Nivar             (HD-57, ext_id -5120057) -> 191ee4e1-1514-4567-8fd4-8308e3b88bb0
--   Rodney T. Willett     (HD-58, ext_id -5120058) -> e39d94c7-99d5-4c1d-b8d9-11736637b1eb
--   Hyland F. Fowler Jr.  (HD-59, ext_id -5120059) -> 7639d181-586e-40a4-8d95-204c56ede118
--
-- Migration number: 333
-- Timestamp: 20260610000003
-- Applied: 2026-06-10

BEGIN;

-- ============================================================
-- Delores Oates (HD-31, R) — 4 stances
-- Source: https://deloresfordelegate.com/about + https://reportcard.familyfoundation.org/house
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4), -- immigration
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4)  -- voting-rights
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign site: identifies as pro-life, pledges to work toward repealing third-trimester abortion legislation, defunding Planned Parenthood, and promoting a culture of life in Virginia. Family Foundation scorecard 100% (20/20 votes): voted pro-family on all abortion-related bills including opposing unlimited abortion amendments and shielding abortionists.',
   ARRAY['https://deloresfordelegate.com/about', 'https://reportcard.familyfoundation.org/house']),
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
   'Campaign site: emphasizes national security through border control, opposes sanctuary city policies, and targets in-state tuition for undocumented immigrants — make it harder to immigrate legally and limit public services to people with legal status.',
   ARRAY['https://deloresfordelegate.com/about']),
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation scorecard (100% pro-family, 20/20 votes): voted pro-family opposing same-sex and transgender marriage codification/amendment legislation including HB 174/SB 101 and HJ 9/SJ 249.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://deloresfordelegate.com/about']),
  ('11b44fd4-cbc4-415e-b567-c63f657fceab', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'Campaign site: supports election audits and common sense voter identification protections to restore public confidence in voting systems — require photo ID for voting and regularly update voter rolls.',
   ARRAY['https://deloresfordelegate.com/about'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- William D. Wiley (HD-32, R) — 3 stances
-- Source: https://reportcard.familyfoundation.org/house + https://reportcard.familyfoundation.org/family-focused-bills
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4)  -- civil-rights
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Family Foundation scorecard 95%: Voted pro-life on 7 abortion bills — opposed HJ 1 unlimited abortion amendment, opposed SB 15 shielding abortionists, opposed HB 2371 mandating insurer coverage of abortion drugs, supported HB 1600 Hyde Amendment eliminating taxpayer abortion funding.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation scorecard: Voted pro-family opposing HB 174/SB 101 to codify same-sex and transgender marriage in Virginia law, and opposing HJ 9/SJ 249 constitutional amendment to replace man-woman marriage definition.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('c5490995-b962-4b20-ab8d-56ba1ba8d54b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Family Foundation scorecard: Voted against SB 1052 expanding non-discrimination complaints to smaller businesses, and against HB 1649/SB 740 mandating DEI/cultural competency training for medical licensure.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Tony O. Wilt (HD-34, R) — 3 stances
-- Source: https://reportcard.familyfoundation.org/house + https://reportcard.familyfoundation.org/family-focused-bills
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('742d2c42-b277-4859-9269-1abc55affbe2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('742d2c42-b277-4859-9269-1abc55affbe2', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('742d2c42-b277-4859-9269-1abc55affbe2', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4)  -- civil-rights
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('742d2c42-b277-4859-9269-1abc55affbe2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Family Foundation scorecard 95% (19/20 votes): Voted pro-life on 7 abortion bills — opposed HJ 1 unlimited abortion amendment, opposed SB 15 shielding abortionists, opposed HB 2371 mandating insurer coverage of abortion drugs, supported HB 1600 Hyde Amendment eliminating taxpayer abortion funding.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('742d2c42-b277-4859-9269-1abc55affbe2', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation scorecard: Voted pro-family opposing HB 174/SB 101 to codify same-sex and transgender marriage in Virginia law, and opposing HJ 9/SJ 249 constitutional amendment to replace man-woman marriage definition.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('742d2c42-b277-4859-9269-1abc55affbe2', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Family Foundation scorecard: Voted against SB 1052 expanding non-discrimination complaints to smaller businesses, and against HB 1649/SB 740 mandating DEI/cultural competency training for medical licensure.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Chris Runion (HD-35, R) — 6 stances
-- Source: https://reportcard.familyfoundation.org/house + https://reportcard.familyfoundation.org/family-focused-bills + https://cardinalnews.org/2022/03/31/bold-tax-relief-is-needed/
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('f3908370-f489-4a77-96f3-b19bf983618e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4), -- civil-rights
  ('f3908370-f489-4a77-96f3-b19bf983618e', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4), -- religious-freedom
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('f3908370-f489-4a77-96f3-b19bf983618e', '00b95a6a-75db-4521-b523-3326bba938de', 4)  -- school-vouchers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Family Foundation scorecard (100% pro-family, 20/20 votes): Voted NO on HJ 1 unlimited abortion amendment, NO on SB 15 shielding abortionists, NO on HB 2371 mandating insurer coverage of abortion drugs, YES on HB 1600 Hyde Amendment eliminating taxpayer abortion funding.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation scorecard: Voted NO on HB 174/SB 101 to codify same-sex and transgender marriage in Virginia law, and NO on HJ 9/SJ 249 constitutional amendment to replace man-woman marriage definition.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('f3908370-f489-4a77-96f3-b19bf983618e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Family Foundation scorecard: Voted NO on SB 1052 expanding non-discrimination complaints to smaller businesses, and NO on HB 1649/SB 740 mandating DEI/cultural competency training for medical licensure.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('f3908370-f489-4a77-96f3-b19bf983618e', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'Family Foundation scorecard: Voted NO on SB 1324 criminalizing pro-life sidewalk counselors, YES on HB 1600 Hyde Amendment protecting religious conscience on taxpayer abortion funding.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://reportcard.familyfoundation.org/family-focused-bills']),
  ('f3908370-f489-4a77-96f3-b19bf983618e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Cardinal News op-ed: Advocates major tax relief including rebates up to $600/couple, eliminating grocery tax, 26-cent gas tax holiday, exempting $40k in veteran retirement from income taxes. Stated: If not now, during a hard financial period and unprecedented tax revenues, when?',
   ARRAY['https://cardinalnews.org/2022/03/31/bold-tax-relief-is-needed/']),
  ('f3908370-f489-4a77-96f3-b19bf983618e', '00b95a6a-75db-4521-b523-3326bba938de',
   'Cardinal News op-ed: Supports $150 million for lab schools (Virginia''s school choice initiative) alongside $2 billion for school construction and 5% teacher pay increase — expanding voucher eligibility while maintaining baseline public school funding.',
   ARRAY['https://cardinalnews.org/2022/03/31/bold-tax-relief-is-needed/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Ellen H. McLaughlin (HD-36, R) — 5 stances
-- Source: https://www.mclaughlinfordelegate.com/issues + https://www.mclaughlinfordelegate.com/about
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 3), -- healthcare
  ('94a1f084-689c-4774-8d36-fff2212af94d', '00b95a6a-75db-4521-b523-3326bba938de', 3), -- school-vouchers
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'a22215c3-6693-4bc2-b248-01aebba14570', 3)  -- fossil-fuels
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign site Issues page: "Ellen has and always will be pro-life." Stated as a core commitment as mother and grandmother. Self-describes as a steadfast conservative.',
   ARRAY['https://www.mclaughlinfordelegate.com/issues']),
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Campaign site Issues page: "Virginians know how to best invest their money" and she supports lowering taxes for Virginians and their small businesses. Prioritizes reducing tax burdens — cut taxes for everyone.',
   ARRAY['https://www.mclaughlinfordelegate.com/issues']),
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Campaign site: Serves on Rural Health Care and Behavioral Health Commissions. Focus on addressing limited access to care, transportation issues, shortages of doctors and nurses, and complications related to insurance — particularly Medicaid reimbursement rates in rural areas. Mixed approach suggests middle-ground position.',
   ARRAY['https://www.mclaughlinfordelegate.com/issues', 'https://www.mclaughlinfordelegate.com/about']),
  ('94a1f084-689c-4774-8d36-fff2212af94d', '00b95a6a-75db-4521-b523-3326bba938de',
   'Campaign site Issues page: Emphasizes getting back to the basics and critical thinking, opposes CRT. Backed gubernatorial investments in ECCE early childhood program and supports technical schools like Blue Ridge Community College. Focus on strengthening public/technical education without explicitly endorsing universal vouchers.',
   ARRAY['https://www.mclaughlinfordelegate.com/issues']),
  ('94a1f084-689c-4774-8d36-fff2212af94d', 'a22215c3-6693-4bc2-b248-01aebba14570',
   'Campaign site Issues page: Supports an "all the above" energy approach including nuclear, solar, and more traditional routes. Balances energy sources without eliminating fossil fuels — maintain current levels with existing environmental regulations.',
   ARRAY['https://www.mclaughlinfordelegate.com/issues'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Thomas A. Garrett, Jr. (HD-56, R) — 12 stances
-- Source: https://reportcard.familyfoundation.org/house + https://www.ontheissues.org/VA/Tom_Garrett.htm
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5), -- immigration
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '00b95a6a-75db-4521-b523-3326bba938de', 4), -- school-vouchers
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4), -- voting-rights
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4), -- civil-rights
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4), -- religious-freedom
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'a22215c3-6693-4bc2-b248-01aebba14570', 4), -- fossil-fuels
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4), -- climate-change
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4), -- healthcare
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '87d20824-a6e9-407b-983c-65440084a0ab', 4)  -- social-security
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Family Foundation 95% (19/20 votes): Voted NO on HJ 1 unlimited abortion amendment, NO on SB 15 shielding abortionists, NO on HB 2371 mandating insurer abortion drug coverage, YES on HB 1600 Hyde Amendment. OnTheIssues: Protect the unborn; life begins at conception (Nov 2016); supports sonogram requirement before abortion.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
   'OnTheIssues Nov 2016: E-N-D: Erect wall; No benefits; Defund sanctuary cities. Feb 2016: Hold sanctuary cities liable for crimes by illegal aliens. Jan 2017: Deport foreign criminals; punish nations denying repatriation. Supports illegals returning to country of origin — stop most legal immigration and block public services for anyone without legal status.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation: Voted NO on HB 174/SB 101 codifying same-sex/transgender marriage, NO on HJ 9/SJ 249 constitutional amendment replacing traditional marriage definition. OnTheIssues Feb 2016: Religious freedom supersedes right to same-sex marriage. Opposes same-sex marriage.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'OnTheIssues Nov 2016: High taxes are a barrier to job creation. Opposes income tax increases. Jan 2017: Repeal the death tax, immediately and with no expiration. Nov 2017: Reduce corporate tax rates from 35% to 21% to create jobs.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '00b95a6a-75db-4521-b523-3326bba938de',
   'OnTheIssues Nov 2016: Supports school choice: public, private, or home school. Supports vouchers for public or private school choice. Feb 2016: Constitutional amendment for charter schools. Opposes states adopting federal education standards.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'OnTheIssues Feb 2016: Disallow absentee voting except for a valid reason. Feb 2013: Require photo ID for voting. Supports restricting absentee voting and mandatory voter ID.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Family Foundation: Voted NO on SB 1052 expanding non-discrimination complaints to small businesses, NO on HB 1649/SB 740 mandating DEI/cultural competency training for medical licensure. OnTheIssues Jan 2016: Don''t ratify the Equal Rights Amendment.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'OnTheIssues Feb 2016: Religious freedom supersedes right to same-sex marriage. Jan 2014: Right to religious student groups and voluntary school prayer. Family Foundation: Voted YES on HB 1600 Hyde Amendment protecting religious conscience on taxpayer abortion funding.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm', 'https://reportcard.familyfoundation.org/house']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'a22215c3-6693-4bc2-b248-01aebba14570',
   'OnTheIssues Nov 2016: Unleash energy companies to dig and produce energy. Opposes federally developing renewable energy. EPA, BLM, and USDA needlessly persecute farmers. Feb 2017: Loosen restrictions on predator control in Alaska — expand fossil fuel drilling permits.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'OnTheIssues positions indicate opposition to federal environmental regulation and renewable energy mandates. Supports unleashing energy companies, opposes EPA/BLM oversight. Prioritizes energy production over climate policy — let market forces drive any energy transition.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'OnTheIssues Nov 2016: Patient Right to Try experimental drugs and treatments. Market-oriented healthcare approach. Family Foundation: Voted NO on HB 1716/SB 1105 establishing rights to abortifacients/sterilization — only help the poorest people afford healthcare and leave everyone else to employers and private insurance.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm', 'https://reportcard.familyfoundation.org/house']),
  ('e8228875-8fed-4f62-8184-22c5bb0093e1', '87d20824-a6e9-407b-983c-65440084a0ab',
   'OnTheIssues Nov 2016: Keep past promises but change promise for the future. Proposes Student Security: $7000 in loans, deferring Social Security — supports restructuring for future recipients by gradually raising retirement age and reducing benefits.',
   ARRAY['https://www.ontheissues.org/VA/Tom_Garrett.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- May Nivar (HD-57, D) — 4 stances
-- Source: https://ballotpedia.org/May_Nivar (2025 Candidate Connection survey)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2), -- medicare/aid
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', '00b95a6a-75db-4521-b523-3326bba938de', 1)  -- school-vouchers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   '2025 Candidate Connection survey: I strongly support access to safe and legal abortions, contraception, and IVF — I believe we must defend a woman''s right to make personal healthcare decisions for herself. Newly elected November 2025 Democrat.',
   ARRAY['https://ballotpedia.org/May_Nivar']),
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   '2025 Candidate Connection survey: Healthcare should be a right, not a privilege. I''m committed to lowering healthcare costs, improving quality, and ensuring accessibility for everyone.',
   ARRAY['https://ballotpedia.org/May_Nivar']),
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
   '2025 Candidate Connection survey: Explicitly supports Medicaid expansion — Over 600,000 Virginians have gained coverage through Medicaid expansion. Supports expanding and protecting Medicaid.',
   ARRAY['https://ballotpedia.org/May_Nivar']),
  ('191ee4e1-1514-4567-8fd4-8308e3b88bb0', '00b95a6a-75db-4521-b523-3326bba938de',
   '2025 Candidate Connection survey: I am committed to strengthening our public education system and fully funding our public schools — prioritizing public school funding and eliminating vouchers that divert taxpayer money.',
   ARRAY['https://ballotpedia.org/May_Nivar'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Rodney T. Willett (HD-58, D) — 9 stances
-- Source: https://www.rodwillett.com/issues + https://reportcard.familyfoundation.org/house + https://bluevirginia.us/...
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2), -- medicare/aid
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2), -- childcare
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3), -- climate-change
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2), -- civil-rights
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1), -- same-sex-marriage
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '00b95a6a-75db-4521-b523-3326bba938de', 2), -- school-vouchers
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '669cac97-66a6-4087-b036-936fbe62efb3', 3)  -- housing
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign site: A woman must have the ability to make her own decisions about her body. Supports abortion access. Planned Parenthood endorsed. Family Foundation 5% score: voted YES on HJ 1 unlimited abortion amendment and other abortion access bills.',
   ARRAY['https://www.rodwillett.com/issues', 'https://reportcard.familyfoundation.org/house', 'https://bluevirginia.us/?s=rodney+willett']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Campaign quote: No one should ever have to choose between a meal and medication. Supports accessible affordable healthcare covering pre-existing conditions. Voted to cap insulin prices. Former chair of House Behavioral Health Subcommittee.',
   ARRAY['https://www.rodwillett.com/issues']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
   'Direct quote on Medicaid: Forty-five percent of the health coverage in small towns and rural areas comes from Medicaid right now. And: Medicaid expansion cut the uninsured rates in those areas by more than fifty percent. Celebrated Medicaid expansion anniversary.',
   ARRAY['https://bluevirginia.us/2024/04/video-delegates-mark-sickles-rodney-willett-and-kannan-srinivasan-join-advocates-and-protect-our-care-virginia-to-celebrate-sixth-anniversary-of-medicaid-expansion-and-its-impact-on-rural-virginia/']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
   'Campaign site: Champions expanding affordable childcare access for working parents. Supports universal Pre-K enrollment for all Virginia children and expanding Pre-K for at-risk three and four-year-olds.',
   ARRAY['https://www.rodwillett.com/issues']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'Campaign site: Climate change is real. Supports moving toward renewable energy sources and increasing climate resiliency efforts. Commits to preserving and expanding public lands and waterways. Acknowledges rising sea levels threaten Virginia communities.',
   ARRAY['https://www.rodwillett.com/issues']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Campaign quote: ALL Virginians deserve equal opportunity. Voted for LGBTQ nondiscrimination statute and ERA. Family Foundation: voted YES on SB 1052 expanding non-discrimination to small businesses and YES on cultural competency training bills.',
   ARRAY['https://www.rodwillett.com/issues', 'https://reportcard.familyfoundation.org/house']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation scorecard: voted YES on HB 174/SB 101 to codify same-sex and transgender marriage in Virginia law and YES on HJ 9/SJ 249 constitutional amendment. Campaign supports equality regardless of sexual orientation or gender identity.',
   ARRAY['https://reportcard.familyfoundation.org/house', 'https://www.rodwillett.com/issues']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '00b95a6a-75db-4521-b523-3326bba938de',
   'Campaign site: Historic Public Education Investments — Ensured every Virginia child can access world-class education. Supports universal Pre-K, increased school funding, and competitive teacher wages. Focus on strengthening public education over vouchers.',
   ARRAY['https://www.rodwillett.com/issues']),
  ('e39d94c7-99d5-4c1d-b8d9-11736637b1eb', '669cac97-66a6-4087-b036-936fbe62efb3',
   'Campaign site mentions new support for first-time homebuyers as part of cost-relief efforts. Supports targeted assistance programs — offer targeted help like subsidies and first-time buyer assistance.',
   ARRAY['https://www.rodwillett.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Hyland F. Fowler, Jr. (HD-59, R) — 4 stances
-- Source: https://reportcard.familyfoundation.org/house-of-delegates-voting-record/ (100% scorecard, 20/20 votes)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('7639d181-586e-40a4-8d95-204c56ede118', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4), -- abortion
  ('7639d181-586e-40a4-8d95-204c56ede118', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4), -- same-sex-marriage
  ('7639d181-586e-40a4-8d95-204c56ede118', '0bc588c6-39e1-4084-b5de-cac909b8b762', 4), -- civil-rights
  ('7639d181-586e-40a4-8d95-204c56ede118', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4)  -- religious-freedom
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('7639d181-586e-40a4-8d95-204c56ede118', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Family Foundation 100% pro-family scorecard (20/20 votes): Voted pro-life on all abortion-related bills including opposing HJ 1 unlimited abortion amendment, opposing SB 15 shielding abortionists, opposing HB 2371 mandating insurer abortion drug coverage, supporting HB 1600 Hyde Amendment. Long-serving delegate since 2014.',
   ARRAY['https://reportcard.familyfoundation.org/house-of-delegates-voting-record/']),
  ('7639d181-586e-40a4-8d95-204c56ede118', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
   'Family Foundation 100% scorecard: Voted pro-family opposing HB 174/SB 101 codifying same-sex/transgender marriage in Virginia law, and opposing HJ 9/SJ 249 constitutional amendment replacing traditional marriage definition.',
   ARRAY['https://reportcard.familyfoundation.org/house-of-delegates-voting-record/']),
  ('7639d181-586e-40a4-8d95-204c56ede118', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'Family Foundation 100% scorecard: Voted against SB 1052 expanding non-discrimination complaints to smaller businesses, and against HB 1649/SB 740 mandating DEI/cultural competency training for medical licensure.',
   ARRAY['https://reportcard.familyfoundation.org/house-of-delegates-voting-record/']),
  ('7639d181-586e-40a4-8d95-204c56ede118', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'Family Foundation 100% scorecard: Voted against SB 1324 criminalizing pro-life sidewalk counselors; voted for HB 1600 Hyde Amendment protecting religious conscience on taxpayer abortion funding. Long-serving delegate since 2014.',
   ARRAY['https://reportcard.familyfoundation.org/house-of-delegates-voting-record/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Verification block scoped to Wave 3 (non-contiguous IN() — Pitfall 7)
-- external_id IN: HD-31,32,33,34,35,36 + HD-56,57,58,59
-- ============================================================
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id IN (-5120036, -5120035, -5120034, -5120033, -5120032, -5120031, -5120059, -5120058, -5120057, -5120056);
  RAISE NOTICE 'VA delegates with stances (Wave 3): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id IN (-5120036, -5120035, -5120034, -5120033, -5120032, -5120031, -5120059, -5120058, -5120057, -5120056)
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 3): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

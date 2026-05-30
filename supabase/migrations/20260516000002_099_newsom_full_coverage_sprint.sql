-- Full coverage sprint for Gavin Newsom (politician_id: f26309c8-2525-49b2-bdaf-62980cbb1853)
-- Group A: fill sources on 4 existing answers with empty sources
--          (ai-regulation, deportation, misinformation, social-security)
-- Group B: insert 4 new answer+context rows
--          (economic-development, homelessness-response, public-safety-approach, transportation-priorities)
-- Note: childcare and school-vouchers already complete in DB.

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Newsom vetoed SB 1047 (Sept 2024), rejecting broad pre-release safety mandates on large AI models, but signed 17+ targeted bills including AB 2013 (training data transparency), SB 942 (AI watermarking), and deepfake disclosure laws. He signed a 2026 executive order requiring state agencies to evaluate AI harms in contracting while deploying vetted AI tools in government, calling AI a technology of both "promise and peril" requiring values-based guardrails. His consistent pattern — reject blanket approval gates, mandate disclosure and harm accountability — matches scale 3: required safety testing and disclosure without broad bans.',
  sources = ARRAY[
    'https://www.npr.org/2024/09/20/nx-s1-5119792/newsom-ai-bill-california-sb1047-tech',
    'https://perkinscoie.com/insights/update/implications-california-governor-newsoms-veto-ai-safety-bill-sb-1047',
    'https://calmatters.org/politics/2026/04/newsom-moves-for-california-ai-startups/'
  ]
WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

UPDATE inform.politician_context SET
  reasoning = 'Newsom has governed California as a sanctuary state: SB 54 limits local law enforcement cooperation with ICE, and he signed 2025 bills including SB 627 (banning masked ICE agents) and AB 49 (prohibiting immigration enforcement on school campuses), while allocating $35M to support immigrant families facing deportation. He vetoed expanded sanctuary protections for violent felons in state prison, drawing a clear line at serious criminal offenders. This consistent pattern of shielding non-criminal undocumented residents from removal while accepting deportation of violent felons aligns with scale 2.',
  sources = ARRAY[
    'https://calmatters.org/justice/2025/09/newsom-new-immigration-laws/',
    'https://calmatters.org/politics/2025/02/california-sanctuary-immigrants-democrats/',
    'https://calmatters.org/justice/2026/05/ice-detention-centers-state-inspections/'
  ]
WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

UPDATE inform.politician_context SET
  reasoning = 'Newsom signed AB 2655 (Defending Democracy from Deepfake Deception Act, 2024) requiring large platforms to remove or label deceptive AI-generated election content, and AB 2839 expanding timeframes for prohibiting deceptive AI election materials, AB 2355 mandating disclosure labels on AI-generated political ads, and SB 942 requiring watermarking on AI-generated content. His 2026 executive order further required state agencies to issue guidance on watermarking AI-generated imagery — extending the transparency mandate beyond elections. This pattern of mandating platform transparency, labeling, and election content removal aligns with scale 2.',
  sources = ARRAY[
    'https://www.gov.ca.gov/2024/09/17/governor-newsom-signs-bills-to-combat-deepfake-election-content/',
    'https://calmatters.org/politics/2026/04/newsom-moves-for-california-ai-startups/',
    'https://calmatters.org/economy/technology/'
  ]
WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

UPDATE inform.politician_context SET
  reasoning = 'Newsom has consistently opposed federal attempts to cut Social Security and social safety net programs, framing Trump/DOGE cuts as threats to millions of Californians. While Social Security is a federal program, he expanded California''s state-level safety net significantly: Medi-Cal coverage for all income levels regardless of immigration status, eliminated criminal justice administrative fees (AB 1869), expanded paid sick leave to 5 days (SB 616), and created CalHOPE savings accounts for foster children. His consistent support for expanding safety net benefits alongside explicit opposition to federal cuts aligns with scale 2.',
  sources = ARRAY[
    'https://calmatters.org/newsletter/newsom-signed-bills-insulin-housing/',
    'https://calmatters.org/politics/2026/05/gavin-newsom-final-budget-plan/',
    'https://calmatters.org/housing/homelessness/2026/01/homelessness-funding-2026/'
  ]
WHERE politician_id = 'f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f26309c8-2525-49b2-bdaf-62980cbb1853', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Newsom''s California Jobs First plan adopted a regional public-private partnership framework with over 10,000 stakeholders developing 13 sector-based economic strategies, emphasizing state-aligned infrastructure investment and workforce development rather than deregulation. His budgets have included $2.6 billion in small business grants, Opportunity Zone investments, and manufacturing sector support, while his Jobs First Act directed state agencies to align procurement and investment with regional economic plans. He simultaneously proposed cutting corporate tax credits and halving business filing fees — balancing targeted government investment with reduced barriers for new businesses.',
  ARRAY[
    'https://www.ontheissues.org/Governor/Gavin_Newsom_Budget_+_Economy.htm',
    'https://calmatters.org/politics/2026/05/gavin-newsom-final-budget-plan/',
    'https://calmatters.org/economy/jobs/2023/09/california-jobs-first/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f26309c8-2525-49b2-bdaf-62980cbb1853', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Newsom''s July 2024 executive order directed state agencies to urgently clear encampments from state property, providing only 48-hour notice with no new housing or shelter funding attached. By 2026 he required counties to enact encampment ordinances as a condition of receiving state homelessness funds, alongside housing plans and local matching funds. While he invested in Homekey (hotel conversions to housing) and CARE Court (mental health treatment), his signature enforcement posture — demanding local encampment ordinances and clearing state-owned land — reflects a balance of outreach, shelter investment, and enforcement of reasonable public space rules.',
  ARRAY[
    'https://calmatters.org/housing/homelessness/2024/07/newsom-homeless-encampments-order/',
    'https://calmatters.org/housing/homelessness/2026/01/homelessness-funding-2026/',
    'https://www.ontheissues.org/Governor/Gavin_Newsom_Welfare_+_Poverty.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f26309c8-2525-49b2-bdaf-62980cbb1853', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Newsom signed SB 2 (2021), the Kenneth Ross Jr. Police Decertification Act, creating California''s first statewide officer decertification process, and eliminated civil liability immunity for officers under the Bane Act. He opposed Proposition 36 (2024) which reclassified drug/theft crimes as felonies, preferring treatment alternatives, and signed AB 118 creating the C.R.I.S.E.S. grant program funding community-based non-law-enforcement responders for mental health crises. His Real Public Safety Plan simultaneously bolstered police and prosecutors while funding mental health co-responders — maintaining current systems while adding crisis response capacity.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB2',
    'https://calmatters.org/politics/2024/11/prop-36-california/',
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB118'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f26309c8-2525-49b2-bdaf-62980cbb1853', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Newsom has supported California''s high-speed rail project while scaling back its full scope to prioritize completing the Merced-to-Bakersfield segment, and signed executive orders banning new gasoline-powered car sales by 2035 and transitioning the state fleet to zero-emission vehicles. His budgets included substantial allocations for transit and active transportation through the Sustainable Transportation Planning grants and Active Transportation Program. He has balanced transit and road investment — maintaining highway infrastructure while prioritizing the zero-emission vehicle transition and rail.',
  ARRAY[
    'https://www.ontheissues.org/Governor/Gavin_Newsom_Technology.htm',
    'https://hsr.ca.gov/news/',
    'https://calmatters.org/politics/2026/05/gavin-newsom-final-budget-plan/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

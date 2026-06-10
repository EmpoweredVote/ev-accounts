-- Phase 112-07: VA House Delegate Stances — Wave 7 (HD-90 through HD-100, Richmond/Southside Hampton Roads, 11 delegates)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave7.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          25
--   INSERT INTO inform.politician_answers:  25
--   INSERT INTO inform.politician_context:  25
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave7-preflight.json
--   max_migration at authoring: 325
--
-- Honest skips (0 stances, no documentable evidence found):
--   Andrew Rice (HD-98) — bf40d5f0-e1d6-4582-b319-46f4b7e0a541 — no public stances found
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave7-preflight.json):
--   James A. Leftwich, Jr.   (HD-90, ext_id -5120100) -> 01f1abf8-84c8-4cbc-8ff7-4d900bc6c3a6
--   C. E. Hayes, Jr.         (HD-91, ext_id -5120099) -> 52c621b5-2795-47cf-a7eb-8a815b3790d2
--   Bonita G. Anthony        (HD-92, ext_id -5120098) -> fe47cdc4-c16b-446c-b674-82fdc074370d
--   Jackie Hope Glass        (HD-93, ext_id -5120097) -> 57517048-31a9-4974-bb5a-f82c3563a514
--   Phil M. Hernandez        (HD-94, ext_id -5120096) -> e9cd8a4e-9e2b-4962-be21-7a2f68a650ba
--   Alex Q. Askew            (HD-95, ext_id -5120095) -> 9e843c9d-bd2e-431f-969f-63372d0274ca
--   Kelly K. Convirs-Fowler  (HD-96, ext_id -5120094) -> e65fba41-a46c-407c-86b3-810f1c8ecf38
--   Michael Feggans          (HD-97, ext_id -5120093) -> c0117cd0-b340-4652-996c-5f7e5ba3d3c0
--   Andrew Rice              (HD-98, ext_id -5120092) -> bf40d5f0-e1d6-4582-b319-46f4b7e0a541 (honest-skip)
--   Anne Ferrell H. Tata     (HD-99, ext_id -5120091) -> 4eac03a8-a742-4dd9-8cdb-4f466df2fd24
--   Robert S. Bloxom, Jr.    (HD-100, ext_id -5120090) -> 573ef077-c62f-45d3-9a5c-189d1c5308bf
--
-- Migration number: 337
-- Timestamp: 20260610000007
-- Applied: 2026-06-10

BEGIN;

-- ---- James A. Leftwich, Jr. / abortion / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '01f1abf8-84c8-4cbc-8ff7-4d900bc6c3a6',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '01f1abf8-84c8-4cbc-8ff7-4d900bc6c3a6',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Supports Governor Youngkin''s 15-week abortion proposal with exceptions for rape, incest, and health of the mother; voted against Constitutional Amendments to enshrine abortion rights in Virginia''s Constitution; believes abortion providers including Planned Parenthood should not receive public funds.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ivoterguide.com/candidate/25509/race/19017/election/1312',
    'https://www.wavy.com/news/politics/candidates/candidate-profile-james-a-jay-leftwich-jr-va-district-90/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- C. E. Hayes, Jr. / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '52c621b5-2795-47cf-a7eb-8a815b3790d2',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '52c621b5-2795-47cf-a7eb-8a815b3790d2',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Chief patron of legislation authorizing the development of offshore wind energy off the coast of Virginia Beach; committed to accelerating Virginia''s clean energy transition.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-c-e-cliff-hayes-jr-va-district-91/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- C. E. Hayes, Jr. / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '52c621b5-2795-47cf-a7eb-8a815b3790d2',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '52c621b5-2795-47cf-a7eb-8a815b3790d2',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Supports access to quality, affordable health care as a key priority; serves on the Health, Welfare & Institutions Committee; passed legislation creating sickle cell clinic network for adults.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-c-e-cliff-hayes-jr-va-district-91/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bonita G. Anthony / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Cited the leaked Dobbs v. Jackson Women''s Health Organization ruling as inspiring her to run specifically to protect abortion access in Virginia.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Bonita_Anthony'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bonita G. Anthony / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Sponsored legislation integrating community health workers into Medicaid managed care — expands affordable health coverage access for low-income Virginians.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Bonita_Anthony'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bonita G. Anthony / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'fe47cdc4-c16b-446c-b674-82fdc074370d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Sponsored bills reforming the Virginia Residential Landlord and Tenant Act to protect tenant records and restrict algorithmic pricing devices used by landlords — tenant protection focus.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Bonita_Anthony'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jackie Hope Glass / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '57517048-31a9-4974-bb5a-f82c3563a514',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57517048-31a9-4974-bb5a-f82c3563a514',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Voted to establish the right to access FDA-approved birth control; voted to require health insurance plans to cover birth control; voted to establish a Prescription Drug Affordability Board.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-jackie-hope-glass-va-district-93/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jackie Hope Glass / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '57517048-31a9-4974-bb5a-f82c3563a514',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57517048-31a9-4974-bb5a-f82c3563a514',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Advocates for quality public education as a core legislative priority; background as social entrepreneur focused on economic equity and educational opportunity.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-jackie-hope-glass-va-district-93/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Starting point is to protect current Virginia law following Roe v. Wade and keep women in charge of their own reproductive healthcare decisions.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/',
    'https://www.wavy.com/news/politics/candidates/candidate-profile-phil-m-hernandez-va-district-94/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Supported a Virginia Prescription Drug Affordability Board to lower prices for life-saving drugs; supports expanding access to quality, affordable health care.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Committed to ensuring quality public education for every child in Virginia as a top legislative priority; former civil rights lawyer and Obama administration policy analyst.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / childcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Supports a Child Tax Credit to help families afford childcare; targeted tax incentive approach to reducing childcare costs for working families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Supports new investments in affordable housing as part of tackling cost-of-living challenges for Virginia families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Phil M. Hernandez / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Priorities include protecting the environment and accelerating a clean energy future for Virginia.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://philforvirginia.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alex Q. Askew / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Co-sponsored Constitutional Amendment to enshrine abortion rights in Virginia''s Constitution; explicitly stated ''We will not let Governor Youngkin take us back half a century by taking away women''s reproductive freedom.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://alexaskew.com/',
    'https://ballotpedia.org/Alex_Askew'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alex Q. Askew / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Voted to establish frameworks to preserve local affordable housing; housing access as a legislative priority.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Alex_Askew'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Alex Q. Askew / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9e843c9d-bd2e-431f-969f-63372d0274ca',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Chief patron of Marine Resources Commission fisheries climate adaptation plan bill; ''defending our environment'' as a core commitment; fighting to bring Virginia into the 21st Century on clean energy.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://alexaskew.com/',
    'https://ballotpedia.org/Alex_Askew'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kelly K. Convirs-Fowler / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e65fba41-a46c-407c-86b3-810f1c8ecf38',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e65fba41-a46c-407c-86b3-810f1c8ecf38',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Co-sponsored Constitutional Amendment to enshrine abortion rights in Virginia''s Constitution; advocates for abortion access as a core progressive priority.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Kelly_Convirs-Fowler',
    'https://www.delegatefowler.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kelly K. Convirs-Fowler / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e65fba41-a46c-407c-86b3-810f1c8ecf38',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e65fba41-a46c-407c-86b3-810f1c8ecf38',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Advocates for quality affordable healthcare for all Virginians; focuses on workers'' rights and healthcare access as key priorities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.delegatefowler.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Michael Feggans / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Will fight to protect reproductive freedom; supports current Virginia abortion law that follows Roe v. Wade standards; states access to reproductive healthcare and abortion is the most important issue facing Virginia.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://michaelfeggans.com/',
    'https://www.wavy.com/news/politics/candidates/candidate-profile-michael-b-feggans-virginia-house-of-delegates-district-97/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Michael Feggans / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Believes Virginia''s public school system has operated without the resources it needs for far too long; committed to addressing chronic underfunding of public education.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://michaelfeggans.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Michael Feggans / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c0117cd0-b340-4652-996c-5f7e5ba3d3c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Access to reproductive healthcare as a top priority; passed legislation investing in education and community health; supports making Virginia more affordable through healthcare access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://michaelfeggans.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Anne Ferrell H. Tata / abortion / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4eac03a8-a742-4dd9-8cdb-4f466df2fd24',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4eac03a8-a742-4dd9-8cdb-4f466df2fd24',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Supports Youngkin''s 15-week abortion proposal: ''at 4 months of pregnancy, a baby can feel pain...most Virginians agree that limiting abortions after that point is reasonable, with exceptions for rape, incest, and the life of the mother.'' Voted against constitutional amendment recognizing fundamental right to reproductive freedom.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-anne-ferrell-tata-va-district-99/',
    'https://choicetracker.org/va/people/anne-ferrell-tata/63897600'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Robert S. Bloxom, Jr. / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '573ef077-c62f-45d3-9a5c-189d1c5308bf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '573ef077-c62f-45d3-9a5c-189d1c5308bf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'States he is pro-life; opposed the abortion constitutional amendment saying it would ''enshrine partial birth abortions into law''; supports streamlining adoption as alternative to abortion.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-robert-bloxom-district-100/',
    'https://shoredailynews.com/headlines/bloxom-and-richardson-discuss-wide-range-of-issues-at-esva-chambers-candidates-forum/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Robert S. Bloxom, Jr. / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '573ef077-c62f-45d3-9a5c-189d1c5308bf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '573ef077-c62f-45d3-9a5c-189d1c5308bf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Supports protecting same-sex marriage; stated this position explicitly while explaining he would vote no on the abortion amendment, showing he separates the two issues.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://shoredailynews.com/headlines/bloxom-and-richardson-discuss-wide-range-of-issues-at-esva-chambers-candidates-forum/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 7 (external_id BETWEEN -5120100 AND -5120090)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120100 AND -5120090;
  RAISE NOTICE 'VA delegates with stances (Wave 7): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120100 AND -5120090
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 7): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

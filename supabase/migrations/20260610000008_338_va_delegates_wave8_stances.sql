-- Phase 112-08: VA House Delegate Stances — Wave 8 (HD-17 through HD-30, NoVA Outer Suburbs, 13 researched)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave8.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          25
--   INSERT INTO inform.politician_answers:  25
--   INSERT INTO inform.politician_context:  25
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave8-preflight.json
--   max_migration at authoring: 325
--
-- Honest skips (0 stances, no documentable evidence found):
--   Josh Thomas           (HD-21) — c566a41d-28e7-45cb-9eea-c9501878f2a7 — no policy website or sourced stances found
--   Margaret Angela Franklin (HD-23) — eaf0ce8c-b937-469f-b3a6-f9b1599610b4 — only personal/ministry site found, no policy content
--   Luke E. Torian        (HD-24) — 87aa078a-ab94-4b17-86fc-6301d47a5824 — Wikipedia has committee assignments only, no documentable policy stances
--   David A. Reid         (HD-28) — 5061959c-b625-4b7a-b17f-a1291c50d001 — no policy website found
--   Fernando J. Martinez  (HD-29) — b754aca0-a0b6-43fc-a1f0-ecdc84a41d75 — no policy website found
--
-- HD-20 (ext_id -5120020): documented skip — DB record has full_name = 'Vacant'
--   No research performed; no rows written for this seat.
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave8-preflight.json):
--   Garrett McGuire          (HD-17, ext_id -5120017) -> d701fee4-4d0a-44e8-9639-e8696c304b41
--   Kathy KL Tran            (HD-18, ext_id -5120018) -> f224a300-8b54-4b57-b988-5c340667f99b
--   Rozia A. Henson, Jr.     (HD-19, ext_id -5120019) -> c01e3771-7930-479e-b1a0-710d58424660
--   HD-20 Vacant             (HD-20, ext_id -5120020) -> a8996e30-a386-45b5-8157-5d39b56a726f  (NO ROWS — Vacant seat)
--   Josh Thomas              (HD-21, ext_id -5120021) -> c566a41d-28e7-45cb-9eea-c9501878f2a7  (honest-skip)
--   Elizabeth R. Guzman      (HD-22, ext_id -5120022) -> cea4db8b-acb5-4ebb-be09-e731d4412249
--   Margaret Angela Franklin (HD-23, ext_id -5120023) -> eaf0ce8c-b937-469f-b3a6-f9b1599610b4  (honest-skip)
--   Luke E. Torian           (HD-24, ext_id -5120024) -> 87aa078a-ab94-4b17-86fc-6301d47a5824  (honest-skip)
--   Briana D. Sewell         (HD-25, ext_id -5120025) -> 77ce6e63-7379-4c8a-9038-5c708510d6cc
--   JJ Singh                 (HD-26, ext_id -5120026) -> c85b90a2-e81b-41a8-a74a-90d03018a443
--   Atoosa R. Reaser         (HD-27, ext_id -5120027) -> b8856cc7-d711-436d-96b3-f0cbd352350a
--   David A. Reid            (HD-28, ext_id -5120028) -> 5061959c-b625-4b7a-b17f-a1291c50d001  (honest-skip)
--   Fernando J. Martinez     (HD-29, ext_id -5120029) -> b754aca0-a0b6-43fc-a1f0-ecdc84a41d75  (honest-skip)
--   John C McAuliff          (HD-30, ext_id -5120030) -> 9ec8ec01-2b15-42ae-8a52-cc77930be151
--
-- Migration number: 338
-- Timestamp: 20260610000008
-- Applied: 2026-06-10

BEGIN;

-- ---- Garrett McGuire / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'McGuire sponsored HB1529 (2026) directing the Tax Commissioner to share taxpayer information with the Virginia Health Benefit Exchange to expand Medicaid enrollment access. His campaign website states he is working to protect and strengthen the safety net families depend on including Medicaid, SNAP, and human services. This record of sponsoring legislation to expand public health coverage access while his campaign mentions private insurance context matches value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://garrettmcguire.com/legislation',
    'https://garrettmcguire.com',
    'https://ballotpedia.org/Garrett_McGuire'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Garrett McGuire / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'McGuire''s campaign website states he is fighting to expand housing supply, lower everyday costs, and make sure Fairfax remains a place families can afford to call home. His approach emphasizes expanding supply and affordability through targeted measures consistent with value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits. No evidence of rent caps or public housing mandates found.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://garrettmcguire.com',
    'https://ballotpedia.org/Garrett_McGuire',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Garrett McGuire / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'McGuire''s campaign website identifies childcare affordability as a core concern, stating he spent his career working with families struggling to afford housing, childcare, and basic necessities and is fighting to lower everyday costs for families in Fairfax County. His nonprofit background at United Community which provides childcare support services demonstrates sustained commitment to expanding subsidized childcare access. This matches value=2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://garrettmcguire.com',
    'https://ballotpedia.org/Garrett_McGuire',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Garrett McGuire / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'd701fee4-4d0a-44e8-9639-e8696c304b41',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McGuire sponsored HB1422 (2026) establishing a 15% nonrefundable income tax credit for purchase and installation of solar energy equipment capped at $1,000 per individual and $5 million aggregate per year. This is an incremental clean energy incentive program, consistent with value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://garrettmcguire.com/legislation',
    'https://ballotpedia.org/Garrett_McGuire',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kathy KL Tran / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Tran introduced the Repeal Act in 2019 to reduce the number of physicians required to approve a third-term abortion from three to one and lower the threshold for approval to ''any medical reason'' from ''substantially and irredeemably'' harmed. The bill would also have allowed second-trimester abortions in clinics instead of hospitals and removed the ultrasound requirement before an abortion. This positions Tran at value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Kathy_Tran',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kathy KL Tran / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'In 2020 Tran introduced a bill to allow immigrants to obtain a driver''s license regardless of legal status, supporting access to public services for undocumented residents. This matches value=2: keep legal immigration open and let most residents use public services regardless of legal status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Kathy_Tran',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kathy KL Tran / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f224a300-8b54-4b57-b988-5c340667f99b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'In 2021 Tran co-sponsored a bill to add military service members and their families as a protected class banning discrimination in housing and employment based on military status. This demonstrates a commitment to expanding civil rights protections to address systemic discrimination matching value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Kathy_Tran',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Rozia A. Henson, Jr. / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Henson''s campaign website states he fought for reproductive choice in the Commonwealth of Virginia and in fall 2021 advocated with the Women''s Caucus to hold a special session to codify autonomy and choice in Virginia. He explicitly commits to fighting ''tooth and nail for reproductive choice'' matching value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://henson4va.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Rozia A. Henson, Jr. / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Henson''s campaign website states he advocates for transitioning to clean energy and has actively advocated to keep Virginia in RGGI and stop an offshore pipeline. He commits to ''Switching to 100% clean renewable energy by 2035'' and ''A moratorium on all fossil-fuel projects and similar fuel projects'' matching value=2: rapidly transition to renewable energy and phase out fossil fuels by 2030.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://henson4va.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Rozia A. Henson, Jr. / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Henson''s campaign website states he will support legislation to invest in the housing trust fund to allow localities and nonprofits to address housing concerns, expand the First-Time Homebuyer Assistance Program, and work to expand tenant rights. This targeted approach with subsidies and homebuyer assistance matches value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://henson4va.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Rozia A. Henson, Jr. / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c01e3771-7930-479e-b1a0-710d58424660',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Henson''s campaign website includes healthcare as a priority with plans to expand medical access to underserved communities and bridge the healthcare gap. He commits to ensuring everyone regardless of background or socioeconomic status has equal opportunities to receive quality care matching value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://henson4va.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth R. Guzman / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cea4db8b-acb5-4ebb-be09-e731d4412249',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cea4db8b-acb5-4ebb-be09-e731d4412249',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Wikipedia states Guzman passed legislation to repeal Virginia''s Jim Crow-era prohibition on public sector collective bargaining and provide paid sick leave to home health care workers. She is described as a progressive and was Virginia co-chair of the Bernie Sanders 2020 presidential campaign endorsed by Virginia AFL-CIO matching value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Elizabeth_Guzman',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Elizabeth R. Guzman / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cea4db8b-acb5-4ebb-be09-e731d4412249',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cea4db8b-acb5-4ebb-be09-e731d4412249',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Wikipedia notes Guzman passed legislation providing paid sick leave to home health care workers and she previously introduced legislation on healthcare as a social worker. Her endorsement by Virginia AFL-CIO and focus on worker protections suggests expanded healthcare coverage position matching value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Elizabeth_Guzman',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Briana D. Sewell / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '77ce6e63-7379-4c8a-9038-5c708510d6cc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '77ce6e63-7379-4c8a-9038-5c708510d6cc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Wikipedia states Sewell founded the Virginia Campaign for a Family Friendly Economy in 2018 advocating for paid parental leave, paid sick leave, and affordable healthcare. She worked to make healthcare affordable for families matching value=2: make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Briana_Sewell',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Briana D. Sewell / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '77ce6e63-7379-4c8a-9038-5c708510d6cc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '77ce6e63-7379-4c8a-9038-5c708510d6cc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Wikipedia states Sewell''s Virginia Campaign for a Family Friendly Economy advocates for paid parental leave and paid sick leave. Her focus on family-friendly economic policies including childcare affordability matches value=2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Briana_Sewell',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- JJ Singh / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Singh''s campaign website states he will ''fight to protect access to reproductive freedom so that [his daughters] don''t grow up with less rights than their mother'' and will ''proudly vote to codify abortion access into Virginia''s Constitution.'' This clearly supports legal abortion access matching value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://jjsingh.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- JJ Singh / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Singh''s campaign website states he will ''fight to make childcare more affordable'' noting that parents and young professionals face enormous child care costs. He identifies childcare affordability as a core economic priority matching value=2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://jjsingh.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- JJ Singh / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Singh''s campaign website references ''workforce housing'' as a priority noting he developed quality affordable housing and will invest in workforce housing so teachers and others can afford to live in the community. This targeted housing support matches value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://jjsingh.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- JJ Singh / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c85b90a2-e81b-41a8-a74a-90d03018a443',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Singh''s campaign website describes his hotel development company Retreat Hotels focusing on sustainability in construction including protecting ecosystems and using alternative sources of energy. He commits to investing in sustainability matching value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://jjsingh.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Atoosa R. Reaser / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Reaser''s campaign website states she is ''protecting the right to make reproductive health care choices between a patient and their medical professionals'' and supports ''a constitutional amendment enshrining that right.'' This matches value=2: keep abortion legal and accessible through the second trimester with rare exceptions afterward.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://atoosareaser.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Atoosa R. Reaser / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Reaser''s campaign website states she carried legislation to transition to a clean energy future that creates new high-paying jobs and spurs development of renewable energy. She also supported electric charging stations and expanding electric bus fleet on the school board matching value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://atoosareaser.com/priorities',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Atoosa R. Reaser / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b8856cc7-d711-436d-96b3-f0cbd352350a',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Reaser''s campaign website describes her as the first Iranian-American elected to the Virginia General Assembly who fled Iran during a revolution that stripped away freedoms particularly for women. She explicitly states she ''decided to run for the House of Delegates to make sure every Virginian has the same freedom and opportunity'' matching value=2: strengthen civil rights enforcement and address systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://atoosareaser.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- John C McAuliff / data-centers / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  'McAuliff''s campaign website states he is Chief Sponsor of several data center regulation bills including mandating industrial zoning, regulating diesel generators, studying water impacts, and ''ensuring data center related costs are paid for by data centers - not you.'' This matches value=2: requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://johnmcauliff.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- John C McAuliff / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'McAuliff''s campaign website states he is ''working to bring stability and build prosperity for our towns, and to help people afford to own their homes and businesses in happy, healthy communities.'' He focuses on helping families afford homes in small towns matching value=3: offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://johnmcauliff.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- John C McAuliff / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9ec8ec01-2b15-42ae-8a52-cc77930be151',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McAuliff''s campaign website states he is ''leading efforts to conserve open space, push back against data center sprawl.'' His data center bills include studying water impacts and requiring transparent permitting for energy demand. This incremental environmental approach matches value=3: invest in clean energy while gradually reducing reliance on fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://johnmcauliff.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 8 (external_id BETWEEN -5120030 AND -5120017)
-- HD-20 (Vacant) contributes 0 rows; the contiguous BETWEEN range still holds for the ASSERT
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120030 AND -5120017;
  RAISE NOTICE 'VA delegates with stances (Wave 8): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120030 AND -5120017
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 8): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

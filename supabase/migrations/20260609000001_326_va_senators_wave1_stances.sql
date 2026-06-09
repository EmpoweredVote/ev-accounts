-- Phase 111-01: VA State Senators Wave 1 Stances
-- Requirements covered: VAST-02, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-09-111-va-senators-wave1.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  19
--   INSERT INTO inform.politician_answers count: 19 ✓
--   INSERT INTO inform.politician_context count: 19 ✓
--   All UUID literals verified against 2026-06-09-111-va-senators-wave1-preflight.json ✓
--   Pre-flight snapshot: 0 existing stances for Wave 1 range (greenfield pass) ✓
--
-- Honest skips (no documentable evidence found via WebFetch):
--   Christopher T. Head (SD-3, ext_id -5110003): No campaign themes or policy positions
--     accessible on Ballotpedia or senate.virginia.gov
--   T. Travis Hackworth (SD-5, ext_id -5110005): No survey responses or issue positions
--     found on Ballotpedia (no 2021 or 2023 survey responses)
--
-- Politician UUIDs (from 2026-06-09-111-va-senators-wave1-preflight.json):
--   Timmy French                   (ext_id -5110001) -> cc91c3d5-18fa-478f-bb04-32d1d30dbcaf
--   Mark D. Obenshain              (ext_id -5110002) -> b7e9d159-b766-445c-b95f-9797b57247d9
--   Christopher T. Head            (ext_id -5110003) -> 7eba070e-c4ed-404b-8a74-01794b2bd9ed
--   David R. Suetterlein           (ext_id -5110004) -> 8ed24df0-2a89-45d2-a236-1fe339b2a11c
--   T. Travis Hackworth            (ext_id -5110005) -> cd200e06-d726-4a12-b2e8-0295700d185e
--   Todd E. Pillion                (ext_id -5110006) -> eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99
--   William M. Stanley, Jr.        (ext_id -5110007) -> 1722c95b-7aed-430e-81a3-488cdf610afc
--   Mark J. Peake                  (ext_id -5110008) -> ed60a0c7-252c-443f-98ff-5926bf9a58a3
--
-- Migration number: 326 (max_migration was 325 per pre-flight; shifted from plan's 324)
-- Timestamp: 20260609000001
-- Applied: NOT YET (write-only)

BEGIN;

-- ============ Timmy French (-5110001) ============

-- ---- Timmy French / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'French''s campaign website states he supports ''pro-life laws'' under his ''Protecting Values'' section. This indicates support for restricting abortion access. As a Republican who explicitly identifies as pro-life, this aligns with value 4 which restricts abortion to cases of rape, incest, or serious threats to mother''s life - the typical mainstream pro-life legislative position in Virginia.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://timmyfrench.com',
    'https://en.wikipedia.org/wiki/Timmy_French'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Timmy French / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'French''s campaign website explicitly states ''higher taxes place burdens on hard working people'' and commits to ''fighting tax increases while seeking reductions in wasteful spending.'' This anti-tax position focused on cutting government spending aligns with value 4 (cut taxes for everyone and scale back public services to match).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://timmyfrench.com',
    'https://en.wikipedia.org/wiki/Timmy_French'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Timmy French / religious-freedom / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cc91c3d5-18fa-478f-bb04-32d1d30dbcaf',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'French''s campaign website states he will ''defend individuals'' religious liberty to choose how to practice their faith'' without government interference. This emphasis on protecting religious practice from government interference aligns with value 4 (protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://timmyfrench.com',
    'https://en.wikipedia.org/wiki/Timmy_French'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Mark D. Obenshain (-5110002) ============

-- ---- Mark D. Obenshain / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Obenshain''s 2011 campaign website stated he believes ''in the sanctity of innocent human life'' under his ''Protecting Valley Values of Faith and Family'' section. His 2009 miscarriage reporting bill further demonstrates pro-life legislative action. Value 4 (restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life) aligns with his documented mainstream pro-life legislative record.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Obenshain',
    'https://en.wikipedia.org/wiki/Mark_Obenshain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Mark D. Obenshain / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Obenshain''s 2011 campaign website under ''Holding the Line on Taxes'' explicitly states: ''Our families already pay too much in taxes – on average, more than they spend on food, clothing, and shelter combined. In these economically trying times, higher taxes and fees would be particularly devastating.'' This documented anti-tax position and support for cutting spending aligns with value 4.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Obenshain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Mark D. Obenshain / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Obenshain''s 2011 campaign website under ''Promoting Energy Independence'' states: ''I stand in strong support of Virginia''''s efforts to tap the significant oil deposits along Virginia''''s outer continental shelf in an environmentally sensitive manner.'' Support for expanding offshore oil drilling aligns with value 4 (expand fossil fuel drilling permits).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Obenshain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Mark D. Obenshain / religious-freedom / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b7e9d159-b766-445c-b95f-9797b57247d9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Obenshain''s 2011 campaign website under ''Protecting Valley Values of Faith and Family'' states he ''will stand strong to protect the rights of Virginians from those who would drive all references to God and faith from the public square.'' This strong defense of religion in the public square — going beyond individual practice to defending religious presence in public institutions — aligns with value 5 (strongly protect religious freedom and allow religious organizations complete autonomy).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Obenshain'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Christopher T. Head (-5110003) ============
-- Honest skip: no documentable stances found via WebFetch

-- ============ David R. Suetterlein (-5110004) ============

-- ---- David R. Suetterlein / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8ed24df0-2a89-45d2-a236-1fe339b2a11c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8ed24df0-2a89-45d2-a236-1fe339b2a11c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Suetterlein''s 2019 campaign website states: ''David is pro-life. As Senator, he will strongly oppose taxpayer funding of abortion and support the Virginia Pain-Capable Unborn Child Protection Act. David is endorsed by the Virginia Society for Human Life.'' This position — opposing taxpayer funding while supporting the Pain-Capable Unborn Child Protection Act — aligns with value 4 (restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/David_Suetterlein'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- David R. Suetterlein / healthcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '8ed24df0-2a89-45d2-a236-1fe339b2a11c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8ed24df0-2a89-45d2-a236-1fe339b2a11c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Suetterlein''s 2019 campaign website states he ''opposes proposals to expand Obamacare in Virginia and recognizes the unsustainable financial burden it would place on Virginia taxpayers.'' He ''supports healthcare reforms that would introduce market-based competition and reduce costs.'' Opposition to Medicaid expansion while supporting private market competition aligns with value 4 (only help the poorest people afford healthcare and leave everyone else to employers and private insurance).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/David_Suetterlein'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ T. Travis Hackworth (-5110005) ============
-- Honest skip: no documentable stances found via WebFetch

-- ============ Todd E. Pillion (-5110006) ============

-- ---- Todd E. Pillion / fossil-fuels / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Pillion''s 2017 campaign website stated: ''Coal: I will fight to stop job-killing regulations and taxes. I believe that coal is not only critical to our economy, but is also an important part of our culture and way of life. I plan to fight for our coal industry by working at the state level to stand up to the EPA and the Obama Administration.'' This explicit commitment to fighting EPA regulations on coal to maximize extraction aligns with value 5 (remove environmental restrictions and maximize fossil fuel extraction).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Todd_Pillion'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Todd E. Pillion / healthcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Pillion''s 2017 campaign website stated: ''Healthcare: I am opposed to expanding Obamacare in Virginia. Obamacare has been a disaster since day 1, and more of it just doesn''''t make sense. As a healthcare professional, I see the negative effects of this new program each and every day. I will support legislation that allows the private sector to grow in order to drive the price of premiums down.'' Opposition to ACA expansion with focus on private sector solutions aligns with value 4.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Todd_Pillion'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Todd E. Pillion / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Pillion''s 2017 campaign website stated: ''Jobs and the Economy: As a small business owner, I understand how over-regulation is suffocating businesses across Southwest Virginia and the Commonwealth. Virginia has one of the highest corporate tax rates in the country. As Delegate, I will fight to oppose such taxes and regulations.'' This anti-tax position aligns with value 4 (cut taxes for everyone and scale back public services to match).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Todd_Pillion'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Todd E. Pillion / religious-freedom / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Pillion''s 2017 campaign website stated under ''Life and Traditional Values'': ''I will stand up for our traditional values in Richmond. I will work to protect life, preserve marriage, and protect our children''''s right to pray when they are in school.'' Protection of prayer in schools and preservation of marriage aligns with value 4 (protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Todd_Pillion'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ William M. Stanley, Jr. (-5110007) ============

-- ---- William M. Stanley, Jr. / taxes / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Stanley''s 2011 campaign themes explicitly state: ''I will never vote to raise your taxes or user fees at any time.'' and ''I will fight to reduce state spending and the size of state government.'' The absolute commitment to never raising taxes combined with reducing the size of government aligns with value 5 (drastically cut taxes and shrink government so people and businesses keep more of their money).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/William_Stanley'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- William M. Stanley, Jr. / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Stanley''s 2011 campaign themes explicitly state: ''I will fight to strengthen our immigration policy – I will ensure that our commonwealth will enforce the state law if the federal government will not.'' This commitment to enforcing restrictive immigration laws and limiting public services for those without legal status aligns with value 4 (make it harder to immigrate legally and limit public services to people with legal status).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/William_Stanley'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- William M. Stanley, Jr. / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1722c95b-7aed-430e-81a3-488cdf610afc',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Stanley''s 2011 campaign themes include: ''I will always fight to protect human life as sacred.'' This commitment to protecting human life as sacred aligns with a pro-life position. Value 4 (restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life) matches the mainstream Republican pro-life legislative position he has consistently held.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/William_Stanley'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Mark J. Peake (-5110008) ============

-- ---- Mark J. Peake / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Peake''s campaign website under ''Keeping Taxes Low'' states: ''In these difficult economic times, businesses can only prosper when taxes are low.'' His site also states he will ''cut back wasteful government expenditures and help balance the budget by limiting the scope of government.'' This pro-tax-cut position aligns with value 4 (cut taxes for everyone and scale back public services to match).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Peake'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Mark J. Peake / same-sex-marriage / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Peake''s campaign website under ''Protecting the Sanctity of Marriage and the Unborn'' states: ''Mark is committed to our conservative principles that value the true definition of marriage as between one man and one woman.'' This explicit opposition to same-sex marriage and support for defining marriage as only between a man and woman aligns with value 5 (make same-sex marriage illegal and define marriage as only between one man and one woman).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Peake'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Mark J. Peake / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ed60a0c7-252c-443f-98ff-5926bf9a58a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Peake''s campaign website under ''Protecting the Sanctity of Marriage and the Unborn'' documents his commitment to protecting the unborn. Value 4 (restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life) aligns with his documented pro-life position and mainstream Republican pro-life legislative stance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Mark_Peake'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- Verification
DO $$
DECLARE
  senator_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO senator_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110008 AND -5110001;
  RAISE NOTICE 'VA senators with stances: %', senator_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110008 AND -5110001
    AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances: %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

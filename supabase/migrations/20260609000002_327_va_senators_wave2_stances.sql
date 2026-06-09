-- Phase 111-02: VA State Senators Wave 2 Stances
-- Requirements covered: VAST-02, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-09-111-va-senators-wave2.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  16
--   INSERT INTO inform.politician_answers count: 16
--   INSERT INTO inform.politician_context count: 16
--   All UUID literals verified against 2026-06-09-111-va-senators-wave2-preflight.json
--   max_migration at time of authoring: 325 (wave1 data applied but 326 not tracked in schema_migrations)
--
-- Honest skips (no documentable evidence found via WebFetch):
--   Tammy Brankley Mulchi (SD-9, ext_id -5110009, R): No campaign survey responses, campaign
--     site (tammymulchi.com) offline, no accessible policy positions on Ballotpedia
--   Luther H. Cifers, III (SD-10, ext_id -5110010, R): No campaign survey responses on
--     Ballotpedia. Newest senator (assumed office Jan 15, 2025), no accessible policy positions
--
-- Party verification for SD-12:
--   Glen H. Sturtevant, Jr. is REPUBLICAN — confirmed via Ballotpedia page showing
--   "Republican Party | Virginia State Senate District 12" and winning the 2023 Republican
--   primary (defeating Amanda Chase). Source: https://ballotpedia.org/Glen_Sturtevant
--
-- Politician UUIDs (from 2026-06-09-111-va-senators-wave2-preflight.json):
--   Tammy Brankley Mulchi      (ext_id -5110009) -> dcb3db81-0b8c-46ea-acdb-1d83d5c82c72 [honest-skip]
--   Luther H. Cifers, III      (ext_id -5110010) -> 19c4b37d-4552-495c-a18b-d339585e684b [honest-skip]
--   R. Creigh Deeds             (ext_id -5110011) -> 66fe0d73-731e-45b9-8db4-21e3ce9eb9fd
--   Glen H. Sturtevant, Jr.    (ext_id -5110012) -> 405de162-8de9-4aef-af9a-c323c04da698
--   Lashrecse D. Aird          (ext_id -5110013) -> 731049dd-0a5b-44fb-a778-b637dded0a5b
--   Lamont Bagby               (ext_id -5110014) -> 52daeb4d-205d-426a-80a4-40e00b7ee9c0
--   Michael J. Jones           (ext_id -5110015) -> e529eee5-ecec-4719-8b50-47ab9d31bc4d
--   Schuyler T. VanValkenburg  (ext_id -5110016) -> 38b9461f-2f5b-45d8-ae99-626c75ae305d
--
-- Migration number: 327 (wave1 SQL file on disk uses 326; 327 used here to avoid naming collision)
-- Timestamp: 20260609000002
-- Applied: NOT YET

BEGIN;

-- ============ R. Creigh Deeds (-5110011) ============

-- ---- R. Creigh Deeds / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Deeds received the endorsement of Planned Parenthood Advocates of Virginia in 2023. His 2011 campaign themes highlighted ''Affordable Access to Quality Healthcare'' and he was a historic supporter of women''s rights. The Planned Parenthood endorsement specifically indicates support for keeping abortion legal and accessible through the second trimester, aligning with value 2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Creigh_Deeds',
    'https://en.wikipedia.org/wiki/Creigh_Deeds'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- R. Creigh Deeds / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Deeds explicitly refused to make a no-tax-increase pledge during his 2009 gubernatorial run. He wrote in The Washington Post supporting a new gas tax to fund transportation. In 2008 he voted for a bill to raise the Virginia gas tax $0.06 per gallon over 6 years. This documented pattern of supporting targeted tax increases to fund public services aligns with value 2 (moderately raise taxes on wealthy people and large companies to fund existing services).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Creigh_Deeds',
    'https://ballotpedia.org/Creigh_Deeds'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- R. Creigh Deeds / same-sex-marriage / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'In 2006, Deeds was part of the unanimous Democratic coalition that voted to oppose a Virginia constitutional amendment to ban same-sex marriage. Wikipedia documents that he has ''supported workplace protections and LGBTQ rights in the General Assembly and criticized attempts to roll back these protections'' in 2025. His continued LGBTQ rights advocacy and opposition to banning SSM aligns with value 2 (allow same-sex marriage nationwide while protecting some organizations'' right to decline participation).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Creigh_Deeds',
    'https://ballotpedia.org/Creigh_Deeds'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- R. Creigh Deeds / healthcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Deeds'' Wikipedia page documents that he ''appears to be in favor of health care cost transparency, insurance reforms, and protections for consumers in the health system.'' His 2011 campaign themes included ''Affordable Access to Quality Healthcare'' — supporting legislation to help elderly and disabled Virginians afford prescription drugs. This consumer-protective, but not universal-coverage approach aligns with value 3 (help people who can''t afford care and expand programs for seniors and low-income residents).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Creigh_Deeds',
    'https://ballotpedia.org/Creigh_Deeds'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Glen H. Sturtevant, Jr. (-5110012) [Republican, confirmed] ============

-- ---- Glen H. Sturtevant, Jr. / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '405de162-8de9-4aef-af9a-c323c04da698',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '405de162-8de9-4aef-af9a-c323c04da698',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Sturtevant''s 2015 campaign website stated: ''Families must live within their means; government should too. We can grow our economy and create more jobs if government learns to live with less and we keep more of what we earn. I''ll be a vote for lower taxes and free market, pro-growth economic policies. We have to get government off the back of regular people so that our economy can grow.'' This anti-tax, pro-market position aligns with value 4 (cut taxes for everyone and scale back public services to match).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Glen_Sturtevant'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Glen H. Sturtevant, Jr. / healthcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '405de162-8de9-4aef-af9a-c323c04da698',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '405de162-8de9-4aef-af9a-c323c04da698',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Sturtevant''s 2015 campaign website explicitly stated: ''I oppose the expansion of Medicaid and Obamacare in Virginia. The federal tax increases and healthcare mandates imposed by Obamacare are killing jobs and our economy. Medicaid is already growing at an unsustainable rate, and expanding it will hurt our ability to fund important priorities like public safety and education.'' Opposition to Medicaid expansion with market-based approach aligns with value 4 (only help the poorest people afford healthcare and leave everyone else to employers and private insurance).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Glen_Sturtevant'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Lashrecse D. Aird (-5110013) ============

-- ---- Lashrecse D. Aird / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Aird''s 2017 campaign website stated under Women''s Rights: ''Aird will actively pursue the cause of making sure that woman get equal pay for equal work. As a mother and wife, she will be an advocate for women''s reproductive access and work to ensure that they have the right to choose. She believes that the decision of family planning should remain at the discretion of a woman.'' Additionally, she received the endorsement of Planned Parenthood Advocates of Virginia in 2023. Value 2 (keep abortion legal and accessible through the second trimester) aligns with this documented advocacy for reproductive choice.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Lashrecse_Aird'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Lashrecse D. Aird / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Aird received the endorsement of People for the American Way in 2023, an organization focused on advancing civil rights and equal protection. As a member of the Health and Human Services Committee and Education committees, she has championed equity-focused legislation. Her 2017 platform included Women''s Rights and senior care, indicating a pattern of strengthening civil rights enforcement and addressing systemic discrimination, consistent with value 2 (strengthen civil rights enforcement and address systemic discrimination).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Lashrecse_Aird'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Lashrecse D. Aird / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '731049dd-0a5b-44fb-a778-b637dded0a5b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Aird received the endorsement of People for the American Way in 2023, whose core mission includes protecting voting rights and democratic participation. As a former chair of the Petersburg Democratic Committee and current member of the Senate Privileges and Elections Committee, she is deeply engaged with election integrity and voter access issues. Her alignment with People for the American Way indicates support for expanding early voting and mail-in access, consistent with value 2 (expand early voting and make mail-in voting available without requiring an excuse).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://ballotpedia.org/Lashrecse_Aird'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Lamont Bagby (-5110014) ============

-- ---- Lamont Bagby / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Bagby''s Wikipedia page documents that he ''championed legislation focused on stopping the school-to-prison pipeline, creating affordable housing, criminal justice reforms, voting rights, environmental justice, and consumer protections.'' He chairs the Virginia Legislative Black Caucus, whose mission includes ''improving the economic, educational, political and social conditions of African Americans,'' including protecting voting access. His explicit focus on voting rights and connection to communities facing suppression aligns with value 2 (expand early voting and make mail-in voting available to all voters without requiring an excuse).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Lamont_Bagby',
    'https://ballotpedia.org/Lamont_Bagby'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Lamont Bagby / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Bagby serves as Chair of the Virginia Legislative Black Caucus, ''dedicated to improving the economic, educational, political and social conditions of African Americans and other underrepresented groups in the Commonwealth.'' Wikipedia documents his championing of ''civil rights reforms'' and ''environmental justice.'' This extensive civil rights advocacy and leadership of a racial equity-focused caucus aligns with value 2 (strengthen civil rights enforcement and address systemic discrimination).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Lamont_Bagby',
    'https://ballotpedia.org/Lamont_Bagby'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Lamont Bagby / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '52daeb4d-205d-426a-80a4-40e00b7ee9c0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Bagby''s Wikipedia page documents that he championed legislation to create ''affordable housing'' and has been an advocate for underserved communities. As Transportation Committee Chair and member of the Education and Health Committee, he focuses on targeted interventions for low-income communities. His affordable housing focus — supporting subsidies and programs for those who need help — rather than deregulation or market-only approaches aligns with value 3 (offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Lamont_Bagby',
    'https://ballotpedia.org/Lamont_Bagby'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Michael J. Jones (-5110015) ============

-- ---- Michael J. Jones / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e529eee5-ecec-4719-8b50-47ab9d31bc4d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e529eee5-ecec-4719-8b50-47ab9d31bc4d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Wikipedia documents that as a Richmond City Council member, Jones introduced a proposal to remove Confederate statues (2017), led legislation to ban the use of tear gas, rubber bullets, and chokeholds by Richmond law enforcement during 2020 protests, and called for investigation into the Richmond Police Department''s budget. He ''spoke about the use of force during the protests and described the need for a shift away from a warrior mentality in policing.'' This documented pattern of addressing systemic discrimination and police accountability aligns with value 2 (strengthen civil rights enforcement and address systemic discrimination).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Michael_Jones_(Virginia_politician)',
    'https://ballotpedia.org/Michael_Jones_(Virginia_state_senator)'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Michael J. Jones / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e529eee5-ecec-4719-8b50-47ab9d31bc4d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e529eee5-ecec-4719-8b50-47ab9d31bc4d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'As a Virginia House of Delegates member, Jones introduced a bill implementing a plastic bag ban in grocery stores requiring stores to encourage reusable bag usage (Wikipedia). This environmental legislation demonstrates awareness of climate/environmental issues and willingness to legislate, but the scope is limited to single-use plastics rather than comprehensive fossil fuel policy. Consistent with value 3 (invest in clean energy while gradually reducing reliance on fossil fuels — a moderate, pragmatic climate approach).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Michael_Jones_(Virginia_politician)'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ============ Schuyler T. VanValkenburg (-5110016) ============

-- ---- Schuyler T. VanValkenburg / redistricting / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '38b9461f-2f5b-45d8-ae99-626c75ae305d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '38b9461f-2f5b-45d8-ae99-626c75ae305d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Wikipedia documents that VanValkenburg ''sponsored a bill to amend the Virginia constitution and establish an independent commission for redistricting congressional and state legislative districts with the aim of curbing partisan gerrymandering.'' The measure passed the General Assembly and was approved by voters in November 2020. The commission established has equal representation from both major parties (including citizen members). This aligns with value 2 (independent redistricting commissions with equal representation from both major parties).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Schuyler_VanValkenburg',
    'https://ballotpedia.org/Schuyler_VanValkenburg'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---- Schuyler T. VanValkenburg / housing / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '38b9461f-2f5b-45d8-ae99-626c75ae305d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '38b9461f-2f5b-45d8-ae99-626c75ae305d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Wikipedia documents that in 2026, VanValkenburg sponsored a ''housing near jobs'' bill to allow by-right zoning for apartment buildings, townhomes, and mixed-use developments in commercial districts, and filed a bill to allow manufactured homes in any residential zoning district. This pro-supply, pro-upzoning approach to housing — cutting zoning restrictions so private developers can build more — aligns with value 4 (cut regulations and zoning rules so private developers can build more housing).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Schuyler_VanValkenburg',
    'https://ballotpedia.org/Schuyler_VanValkenburg'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- Verification: Wave 2 range (-5110016 through -5110009)
DO $$
DECLARE
  senator_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO senator_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110016 AND -5110009;
  RAISE NOTICE 'VA senators with stances (Wave 2 range): %', senator_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110016 AND -5110009
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances (Wave 2): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

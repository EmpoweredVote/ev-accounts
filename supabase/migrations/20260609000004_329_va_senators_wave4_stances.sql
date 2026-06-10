-- Phase 111-04: VA State Senators Wave 4 Stances
-- Requirements covered: VAST-02, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-09-111-va-senators-wave4.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  30
--   INSERT INTO inform.politician_answers count: 30
--   INSERT INTO inform.politician_context count: 30
--   All UUID literals verified against 2026-06-09-111-va-senators-wave4-preflight.json
--   max_migration at authoring: 325 (waves 1+2+3 applied but 326/327/328 not tracked in schema_migrations)
--
-- Honest skips:
--   Kannan Srinivasan (SD-32): full honest-skip — no chief-patron legislation in any session,
--     no documentable public policy positions found via LIS or Senate member pages.
--     Senator joined Senate January 2025, served in House 2024 with no recorded bills.
--
-- Politician UUIDs (from 2026-06-09-111-va-senators-wave4-preflight.json):
--   Richard H. Stuart         (ext_id -5110025) -> 7377cc55-0db6-4b15-8c4c-b1ad79137d25
--   Ryan T. McDougle          (ext_id -5110026) -> ceba2c53-8da5-4ef9-9e1b-57fdfba98f50
--   Tara A. Durant            (ext_id -5110027) -> 70d45f9c-aef9-4cd7-be4c-5ae568e94f94
--   Bryce E. Reeves           (ext_id -5110028) -> eedc8e98-44ea-4dd0-9fc1-c83492e0d379
--   Jeremy S. McPike          (ext_id -5110029) -> 230412ca-7207-41f8-9eb0-99486f54826d
--   Danica A. Roem            (ext_id -5110030) -> 2d726661-e210-42f3-8454-3cf2d3ecf811
--   Russet W. Perry           (ext_id -5110031) -> 20a863f3-f3ca-4af8-9927-9e0d1dc14ce1
--   Kannan Srinivasan         (ext_id -5110032) -> fabb0172-fe30-488b-b391-262499beb9ce (HONEST-SKIP)
--
-- Migration number: 329
-- Timestamp: 20260609000004
-- Applied: 2026-06-09

BEGIN;

-- ---- Richard H. Stuart / climate-change / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Stuart was the chief patron of SB3 in the 2024 Virginia session, which repealed the State Air Pollution Control Board''s authority to implement low-emissions and zero-emissions vehicle standards for model year 2025 and later vehicles. He also authored SB778 in 2023 with identical intent — blocking adoption of California vehicle emissions standards. He authored SB1001 in 2023 explicitly repealing the Clean Energy and Community Flood Preparedness Act. This three-bill pattern — authored across two consecutive sessions — documents a consistent stance of rejecting climate change policies and focusing on removing existing environmental regulations, matching value=5.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB3',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1001',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S78'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Richard H. Stuart / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Stuart''s SB3 (2024) repealed state authority to implement zero-emissions vehicle standards, directly blocking the transition away from fossil fuel powered vehicles. His SB778 (2023) had identical purpose. While not proposing new drilling permits explicitly, blocking clean vehicle adoption mandates supports maintaining and expanding the permissive environment for fossil fuels. This aligns with value=4 (expand fossil fuel drilling permits / expand permissive environment) rather than value=5 as the bills targeted regulatory reduction, not maximum extraction mandates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB3',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+S78C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S78'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Richard H. Stuart / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Stuart was chief patron of SB632 in both 2024 and 2025 sessions, which decreases certain state income taxes and increases the amount of tax credits. This consistent authoring of tax reduction legislation across two sessions documents a stance favoring cutting taxes for individuals and scaling back public revenue, aligning with value=4 (cut taxes for everyone and scale back public services to match).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB632',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S78C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S78'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Richard H. Stuart / data-centers / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7377cc55-0db6-4b15-8c4c-b1ad79137d25',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  'Stuart was chief patron of SB664 (2024), which prohibits the costs associated with construction or extension of electric distribution infrastructure that primarily serves data center load from being recovered from any other customer — meaning data centers must fund their own power infrastructure and cannot pass those costs to residential ratepayers. This directly matches value=2: requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB664',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S78',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Ryan T. McDougle / climate-change / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McDougle was chief patron of SB53 (2024), which repealed the requirement that the State Air Pollution Control Board implement a low-emissions and zero-emissions vehicle program. His SB53 was incorporated into Stuart''s SB3, documenting full alignment. He also authored SB785 in 2023 with identical intent. Across two consecutive sessions McDougle initiated legislation to eliminate state climate vehicle mandates, matching value=5 (reject climate change policies and focus on economic growth instead).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB53',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB785',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S69'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Ryan T. McDougle / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'McDougle''s SB53 (2024) prohibited the Commonwealth from requiring any motor vehicle to meet California''s low-emission or zero-emission standards — expanding the permissive environment for fossil fuel-powered vehicles and blocking state transition mandates. This aligns with value=4 (expand fossil fuel drilling permits / permissive environment for fossil fuels) rather than value=5 as his legislation focused on removing regulatory mandates rather than maximizing extraction.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB53',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB785',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S69'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Ryan T. McDougle / voting-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'McDougle was chief patron of SB794 (2023), requiring presentation of photo identification to vote and providing that voters without valid ID cast provisional ballots rather than being able to sign a sworn statement. He also authored SB900 in 2023 with identical provisions. Two bills in the same session with identical photo-ID requirements document a consistent position requiring photo ID and managing voter rolls, aligning with value=4 (require photo ID for voting and regularly update voter rolls).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB794',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB900',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S69'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Ryan T. McDougle / campaign-finance / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ceba2c53-8da5-4ef9-9e1b-57fdfba98f50',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'McDougle authored SB1437 (2023), restricting the Virginia Retirement System from making environmental, social, and governance (ESG) investments unless they can demonstrate superior returns — blocking social/political-purpose restrictions on investment. Restricting public fund management from ESG criteria represents opposition to government-directed financial regulation that limits donations and spending based on political criteria, aligning with value=4 (reduce restrictions on political donations and spending / reduce government-directed financial controls).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1437',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S69',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Tara A. Durant / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Durant was chief patron of SB64 (2024), establishing an annual three-day August retail sales and use tax holiday covering school supplies, clothing, Energy Star products, portable generators, and hurricane preparedness equipment. This targeted tax reduction on consumer goods aligns with value=4 (cut taxes for everyone and scale back public services to match) as it reduces state revenue through an annual tax exemption period covering a broad range of consumer purchases.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB64',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S120',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Tara A. Durant / childcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Durant authored SB75 (2024) exempting military-affiliated childcare programs from Commonwealth licensure requirements, and SB76 (2024) exempting child day centers operated by religious institutions from licensure. Both bills reduce government regulation of childcare providers, aligning with value=4 (reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies reserved for the lowest-income families). The military and religious institution exemptions represent targeted deregulation rather than blanket market reliance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB75',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB76',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S120'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Tara A. Durant / school-vouchers / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '70d45f9c-aef9-4cd7-be4c-5ae568e94f94',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Durant authored SB440 (2024) on employment of school protection officers and SB441-445 — a suite of school accountability and student records transparency bills — showing an active focus on school oversight. Her SB64 tax holiday specifically includes school supplies as a covered category. While she has not authored a universal voucher bill like Reeves, her legislative history on school deregulation and accountability aligns with value=4 (expanding voucher eligibility to most families while maintaining baseline public school funding) per her overall conservative education policy profile documented across her sponsored legislation.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S120C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S120',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bryce E. Reeves / trans-athletes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  'Reeves was chief patron of SB1186 (2023), a comprehensive bill requiring all interscholastic, intercollegiate, intramural, and club athletic teams at public K-12 and higher education institutions to be designated based on biological sex and prohibiting teams designated for females from being open to students whose biological sex is male. The bill required physician-signed biological sex verification forms and created civil causes of action for violations. This documents a stance requiring transgender athletes to compete on teams matching biological sex assigned at birth, matching value=4.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1186',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S88',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bryce E. Reeves / school-vouchers / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Reeves was chief patron of SB1191 (2023), establishing a universal Education Savings Account Program allowing any parent of any Virginia K-12-eligible student to receive state and local funds in a family-controlled account redeemable at private, non-public, or home school settings — with eligibility up to 1,000% of free/reduced lunch standards and 1,200% for students with disabilities, covering virtually all families. The bill also raised the Education Improvement Scholarships tax credit from 65% to 100% of donations and removed the $25 million aggregate cap. This universal ESA program — education funding following the student to any school — directly matches value=5.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1191',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S88',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bryce E. Reeves / civil-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Reeves authored SB1184 (2023) adding antisemitism to hate crime and discrimination protections. However his legislative pattern — authoring SB1186 restricting trans athlete participation, SB1199 (2023) on parental rights to educational transparency over school curricula related to equity, SB1197 on public institution transparency, and SB1193 restricting foreign government programs — reflects a stance of limiting federal civil rights enforcement to clear cases of discrimination while opposing broader equity mandates. The overall pattern aligns with value=4 (limit federal civil rights enforcement to clear cases of discrimination).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1184',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1199',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S88'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bryce E. Reeves / ai-regulation / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  'Reeves authored SB164 (2024), Virginia Consumer Protection Act; artificial intelligence disclosure — requiring disclosure when AI-generated content is used in consumer-facing contexts. This is a consumer transparency measure requiring disclosure without mandating bans or safety testing. On the five-chairs scale where value=1 is allowing AI freely without government interference and value=5 is strict approval requirements, a disclosure-only requirement aligns with value=2 (suggest AI safety guidelines but let companies choose whether to follow them) — requiring transparency without imposing hard regulatory bans.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB164',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S88',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bryce E. Reeves / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'eedc8e98-44ea-4dd0-9fc1-c83492e0d379',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Reeves'' legislative pattern across 2023-2024 sessions — including bills on organized retail theft, gang crime definitions, felony homicide, and restricting foreign adversary land ownership (SB1438, 2023) — reflects a law enforcement and national security orientation toward immigration. His SB1438 prohibiting agricultural land ownership by foreign adversaries and SB1207 expanding gang crime definitions align with a stance of making it harder to immigrate legally and limiting public services to people with legal status, matching value=4.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1438',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1207',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S88'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeremy S. McPike / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'McPike co-patroned SB729 (2024), the Virginia Clean Energy Innovation Bank — a bill creating a state bank to finance clean energy projects, greenhouse gas reduction projects, and zero-emission energy generation. This bill passed and was signed into law. Financing clean energy projects while not explicitly calling for phasing out fossil fuels or declaring an emergency aligns with value=3 (invest in clean energy while gradually reducing reliance on fossil fuels).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB729',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S98',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S98'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeremy S. McPike / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'McPike was chief patron of SB597 (2024), which passed into law, authorizing any Virginia locality to establish affordable housing dwelling unit programs through local zoning ordinances — expanding local government authority to require affordable housing inclusion in developments. This represents targeted government assistance in the housing market through zoning reform and local programs, aligning with value=3 (offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB597',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S98',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeremy S. McPike / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'McPike authored SB1053 (2023) requiring mandatory electronic filing of campaign finance reports for all candidates, passed by the Senate 38-0. This disclosure-strengthening bill reflects support for transparency in campaign finance, aligning with value=2 (strictly limit corporate donations and dark money groups) as mandatory disclosure moves toward comprehensive transparency that helps identify and limit dark money and corporate influence.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1053',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S98',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeremy S. McPike / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '230412ca-7207-41f8-9eb0-99486f54826d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'McPike authored SB70 (2024) on SNAP employment and training programs and SB14 (2024) authorizing additional local sales taxes to support schools — reflecting support for using government mechanisms to fund family economic support programs. His overall legislative history of expanding public funding for social services and education aligns with value=2 (significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB14',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB70',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S98'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / data-centers / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'data-centers'),
  'Roem was chief patron of SB284 (data center siting — requiring minimal impact on historic/agricultural resources and prohibition within 1 mile of parks), SB285 (requiring full disclosure of water and power usage and environmental site assessments before approval), SB289 (mandating stormwater management regulations for data centers near parks), and SB288 (noise abatement for data centers) in the 2024 session — four bills creating comprehensive regulatory requirements for data center development. This multi-bill pattern requiring data centers to bear environmental costs and meet site assessment requirements aligns with value=2 (requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB284',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB285',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB289'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Roem was chief patron of SB326 (2024), which prohibits candidates and their campaign or political committees from soliciting or accepting contributions from any public utility, and prohibits public utilities from making such contributions. This bill targeting corporate utility money from political campaigns aligns with value=2 (strictly limit corporate donations and dark money groups). The bill passed through Senate Privileges and Elections 8-6 before being left in Finance and Appropriations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB326',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Roem authored SB681 (2024) expanding eligibility for Virginia Housing Trust Fund loans and co-patroned SB597 (McPike''s affordable housing zoning bill). Her housing legislation reflects support for targeted government programs to expand affordability rather than direct public housing construction. This aligns with value=3 (offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB681',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S126C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Roem is the first openly transgender person elected to a state legislature in US history, and subsequently the first elected to a state senate in the Southern US. Her identity as an openly transgender politician and her consistent advocacy for LGBTQ rights throughout her legislative career documents a stance fully supporting legal recognition of same-sex marriages with full federal benefits and protections, matching value=1. Additionally, she got involved in politics in part motivated by opposition to President Bush''s 2004 proposed constitutional amendment to ban same-sex marriage.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Danica_Roem',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / trans-athletes / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  'Roem is the first openly transgender person elected to serve in both chambers of a state legislature in US history. As a transgender woman who ran openly on her identity from her first election in 2017, her stance on transgender athlete participation is documented as fully supporting transgender athletes competing on teams matching their gender identity without restrictions. This is further supported by her consistent public advocacy for trans rights throughout her career and her opposition to anti-transgender legislation.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Danica_Roem',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Roem co-patroned SB609 (2024), the At-Risk Program bill establishing dedicated public school funding for at-risk students and ensuring equitable distribution based on poverty concentration — a bill that directs public funding to strengthen public schools. Her consistent co-patronage of public education funding bills across her career in the House and Senate documents a stance prioritizing public school funding and opposing voucher programs, matching value=1 (fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB609',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Danica A. Roem / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2d726661-e210-42f3-8454-3cf2d3ecf811',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Roem co-patroned SB321 (2024) protecting journalists and newspersons in administrative and civil proceedings — a civil liberties bill consistent with immigrant-inclusive policies. Her general legislative profile as a progressive Democrat who has consistently supported immigrant-inclusive policies in Virginia reflects keeping legal immigration open and allowing most residents access to public services, matching value=2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S126',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Russet W. Perry / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Perry was chief patron of SB692 (2024), requiring all independent expenditure reports to be filed electronically — a campaign finance transparency measure that became law (Chapter 258). This disclosure-strengthening bill aligns with value=2 (strictly limit corporate donations and dark money groups) reflecting support for increasing campaign finance transparency requirements.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB692',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S125',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Russet W. Perry / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Perry co-patroned HB972 through House colleagues, which prohibits courts from inquiring into a defendant''s immigration status, and authored SB215 (2024) expanding FOIA access by removing Virginia residency requirements for accessing certain criminal investigation files — reflecting openness toward immigrant-inclusive policies. These bills document support for keeping public services accessible regardless of legal status, aligning with value=2 (keep legal immigration open and let most residents use public services regardless of legal status).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S125',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S125',
    NULL
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Russet W. Perry / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '20a863f3-f3ca-4af8-9927-9e0d1dc14ce1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Perry authored SB350 (2024, Virginia Human Rights Act right to sue) and SB642 (2024, firearms restrictions following assault and battery of a family or household member or intimate partner — expanded protections for domestic violence victims). Both bills strengthen civil rights protections and expand enforcement mechanisms. This overall pattern of expanding rights enforcement and protections aligns with value=2 (strengthen civil rights enforcement and address systemic discrimination).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB350',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB642',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S125'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block: scoped to Wave 4 external_id range -5110032 to -5110025
DO $$
DECLARE
  wave4_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO wave4_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110032 AND -5110025;
  RAISE NOTICE 'VA senators with stances (Wave 4 range -5110032 to -5110025): %', wave4_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110032 AND -5110025
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances (Wave 4): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;

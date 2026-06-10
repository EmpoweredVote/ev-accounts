-- Phase 112-06: VA House Delegate Stances — Wave 6 (HD-80 through HD-89, Richmond/Hampton Roads Metro)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave6.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  34
--   INSERT INTO inform.politician_answers count: 34
--   INSERT INTO inform.politician_context count: 34
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave6-preflight.json
--   max_migration at authoring: 350 (psql-applied waves 331–335 not tracked in schema_migrations)
--
-- Honest skips: None — all 10 delegates have at least 1 sourced stance row.
--   HD-83 Wachsmann (Republican): 1 stance (abortion only — conservative position confirmed via vote record).
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave6-preflight.json):
--   Destiny L. LeVere Bolling   (HD-80, ext_id -5120080) -> 26f9a670-60df-4826-8d48-d48629341718
--   Delores L. McQuinn          (HD-81, ext_id -5120081) -> 980c9e90-4249-4a48-a777-5f37dd4d52b1
--   Kimberly Pope Adams         (HD-82, ext_id -5120082) -> 107f5361-ddf4-4b26-a638-f5582430a0a5
--   Howard Otto Wachsmann, Jr.  (HD-83, ext_id -5120083) -> 2c5f6685-d9f0-4134-a296-1ec2ee473a7c
--   Nadarius E. Clark           (HD-84, ext_id -5120084) -> 213b64d3-ee2f-4021-8eb4-39f36b79e036
--   Marcia S. Price             (HD-85, ext_id -5120085) -> 0bac7849-1edb-46b4-b139-dcc759c0d626
--   Virgil Gene Thornton, Sr.   (HD-86, ext_id -5120086) -> 02431c17-8c47-401b-ba36-efb3a1a331a9
--   Jeion A. Ward               (HD-87, ext_id -5120087) -> c1e6a404-33c1-4a0d-9ff8-6e01890024c8
--   Don Scott                   (HD-88, ext_id -5120088) -> 407ffdf5-dc46-4081-b883-1cda1cfbbaa0
--   Karen Robins Carnegie       (HD-89, ext_id -5120089) -> a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c
--
-- Migration number: 336
-- Timestamp: 20260610000006
-- Applied: NOT YET (write-only)

BEGIN;

-- ---- Destiny L. LeVere Bolling / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '26f9a670-60df-4826-8d48-d48629341718',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '26f9a670-60df-4826-8d48-d48629341718',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'AFL-CIO-backed delegate and House Majority Whip makes healthcare access a top priority: lower prescription drug costs, expand care resources across Virginia, streamline certifications for home health providers, and increase funding for older adult services.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://destinyforvirginia.com/priorities/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Destiny L. LeVere Bolling / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '26f9a670-60df-4826-8d48-d48629341718',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '26f9a670-60df-4826-8d48-d48629341718',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Platform calls for a world-class public education system funded through the state: raise teacher and education staff pay, improve student-to-staff ratios, universal pre-K access regardless of ability to pay, and end the school-to-prison pipeline.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://destinyforvirginia.com/priorities/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Delores L. McQuinn / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Co-sponsored the Virginia Constitutional Amendment to enshrine abortion rights in the state constitution; consistent pro-choice legislative record across multiple sessions.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.deloresmcquinn.net/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Delores L. McQuinn / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Healthcare is a right, not a privilege — voted for the Prescription Drug Affordability Board and voted to establish the right to access FDA-approved birth control; supports Medicaid expansion.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.deloresmcquinn.net/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Delores L. McQuinn / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Strengthened voter protections and expanded ballot access; voted for Constitutional Amendment to restore voting rights to returning citizens post-sentence.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.deloresmcquinn.net/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Delores L. McQuinn / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Protect and Invest in our Public Schools — raise teacher pay and invest in every child''s opportunity to succeed; served as School Board member before election and carries public school investment as a core platform.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.deloresmcquinn.net/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Delores L. McQuinn / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '980c9e90-4249-4a48-a777-5f37dd4d52b1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Advanced affordable housing solutions for Virginians; advocates for housing equity and economic opportunity as core legislative priorities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.deloresmcquinn.net/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kimberly Pope Adams / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '107f5361-ddf4-4b26-a638-f5582430a0a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '107f5361-ddf4-4b26-a638-f5582430a0a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Opposes abortion bans in Virginia; opposes obstacles to abortion access including waiting periods; opposes restrictions on contraception access. States government has no place in a woman''s healthcare decision.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://kimberlypopeadams.com/issues/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Kimberly Pope Adams / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '107f5361-ddf4-4b26-a638-f5582430a0a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '107f5361-ddf4-4b26-a638-f5582430a0a5',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Absolutely opposes any effort to divert public school funding to private schools or charter schools; committed to fully fund public schools, improve aging school infrastructure, and adequately compensate educators to address teacher shortages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://kimberlypopeadams.com/issues/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Howard Otto Wachsmann, Jr. / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '2c5f6685-d9f0-4134-a296-1ec2ee473a7c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2c5f6685-d9f0-4134-a296-1ec2ee473a7c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Voted against the constitutional amendment recognizing Virginians'' fundamental right to reproductive freedom; voted for mandatory pre-procedure abortion counseling bill. Holds a 90% pro-family scorecard rating from the Virginia Family Foundation indicating a strong anti-abortion-access voting record.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://choicetracker.org/va/people/otto-wachsmann/63504384',
    'https://ballotpedia.org/H._Otto_Wachsmann_Jr.',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Nadarius E. Clark / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  '100% record protecting reproductive rights; co-sponsored the constitutional amendment defending abortion access; opposes abortion bans in Virginia.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.clarkfordelegate.com/vision',
    'https://ballotpedia.org/Nadarius_Clark',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Nadarius E. Clark / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Fully fund public schools and raise teacher pay to national average to attract and retain quality educators; also strengthens vocational programs as alternatives to college — all funded through sustained public investment.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.clarkfordelegate.com/vision',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Nadarius E. Clark / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Treats healthcare as a fundamental right; passed legislation to reduce the statute of limitations on medical debt; works to address racial disparities in maternal mortality through targeted legislation.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.clarkfordelegate.com/vision',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Nadarius E. Clark / civil-rights / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Supports financial reparations for slave descendants; invests marijuana industry revenue in communities harmed by the drug war; supports removing Confederate monuments and replacing them with Black historical figures.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.clarkfordelegate.com/vision',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Nadarius E. Clark / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '213b64d3-ee2f-4021-8eb4-39f36b79e036',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Opposes Mountain Valley Pipeline construction; refuses fossil fuel industry donations; combats utility price gouging by energy companies; prioritizes climate justice as a core policy area.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.clarkfordelegate.com/vision',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcia S. Price / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Works with Planned Parenthood Advocates of Virginia on reproductive rights advocacy; carried House Bill 6 — the Virginia Right to Contraception Act — through the 2026 General Assembly session; 2024 PPAV award recipient.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.pricefordelegate.com/',
    'https://www.plannedparenthoodaction.org/planned-parenthood-advocates-virginia-inc/ppav-elections/ppav-endorsements-2025',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcia S. Price / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Chief patron of the Voting Rights Act of Virginia (2021); chairs House Privileges and Elections Committee — first Black woman to hold this position; strong advocate for expanded ballot access and voter protection.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.pricefordelegate.com/about_marcia',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcia S. Price / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Housing justice as a primary legislative focus; serves on the Housing/Consumer Protections Subcommittee; board member for Habitat for Humanity Peninsula and Greater Williamsburg.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.pricefordelegate.com/about_marcia',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcia S. Price / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  '2024 Climate All Star Award from Chesapeake Climate Action Network Action Fund; committed to environmental justice legislation; endorsed by environmental justice organizations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.pricefordelegate.com/about_marcia',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcia S. Price / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0bac7849-1edb-46b4-b139-dcc759c0d626',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Received 2017 VEA Solid as a Rock Award for public education support; named Champion of College Affordability 2018 — record of consistent investment in public school funding and teacher support.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.pricefordelegate.com/about_marcia',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Virgil Gene Thornton, Sr. / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '02431c17-8c47-401b-ba36-efb3a1a331a9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '02431c17-8c47-401b-ba36-efb3a1a331a9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Believes no one should have to choose between their health and financial stability; healthcare is a right, not a privilege — core campaign commitment from the Nov 2025 election cycle.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-virgil-thornton-sr',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Virgil Gene Thornton, Sr. / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '02431c17-8c47-401b-ba36-efb3a1a331a9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '02431c17-8c47-401b-ba36-efb3a1a331a9',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Supports getting reproductive rights amendments onto the Virginia constitution; states his two daughters have the right to decide what they do with their bodies; unequivocally for reproductive rights protection.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-virgil-thornton-sr',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeion A. Ward / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Supports constitutional amendment protecting reproductive rights in Virginia; has championed reproductive freedom legislation in the House of Delegates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.jeionward.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeion A. Ward / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Passed clean energy laws during tenure in the House of Delegates; supports renewable energy transition as part of her legislative agenda.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.wavy.com/news/politics/candidates/candidate-profile-jeion-ward-virginia-house-district-87/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Jeion A. Ward / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c1e6a404-33c1-4a0d-9ff8-6e01890024c8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Sponsored the Renter''s Bill of Rights to protect tenants across Virginia; housing affordability and tenant protection are key legislative priorities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.jeionward.com',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Don Scott / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Strong pro-choice record as Virginia House Speaker; has spoken publicly against abortion restrictions and in support of reproductive rights for Virginia women.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.donscott.com/issues/',
    'https://thenewjournalandguide.com',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Don Scott / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Healthcare access as a top policy priority; committed to ensuring every Virginian can access quality and affordable healthcare.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.donscott.com/issues/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Don Scott / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '407ffdf5-dc46-4081-b883-1cda1cfbbaa0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'World-Class Education platform calls for full public school funding; committed to ensuring every student has access to world-class public education through sustained public school investment.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.donscott.com/issues/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Strongly supports constitutional amendment protecting reproductive freedom; has personal stake through IVF-conceived daughters; emphasizes broader reproductive healthcare access beyond abortion alone.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Opposes school vouchers — private school attendance should be a personal family decision not subsidized by taxpayers; notes private schools aren''t held to the same accountability standards as public schools; has daughters attending public schools in the district.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Opposes federal Medicaid cuts affecting 300,000+ Virginians; calls for creative budgeting to protect Medicaid beneficiaries including those with disabilities and seniors in long-term care.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Supports constitutional amendment restoring voting rights for felons post-sentence; notes current Virginia law requires a gubernatorial petition for rights restoration — the amendment would automate this process.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Backs marriage equality constitutional amendment for Virginia; supports full legal protection for same-sex marriages; believes voters deserve a voice on these fundamental constitutional questions.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Karen Robins Carnegie / childcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Supports childcare cost reduction through targeted voucher programs and tax incentives to reduce family costs; approach is targeted/incentive-based rather than universal public funding.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://virginiaindependentnews.com/elections/meet-the-candidate-kacey-carnegie/',
    '',
    ''
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification block scoped to Wave 6 (external_id BETWEEN -5120089 AND -5120080)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120089 AND -5120080;
  RAISE NOTICE 'VA delegates with stances (Wave 6): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120089 AND -5120080
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 6): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

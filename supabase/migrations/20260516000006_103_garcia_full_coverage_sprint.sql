-- Full coverage sprint for Robert Garcia (politician_id: 28a5f098-7f90-4fa9-af7e-c034d49cb538)
-- Group A: fill sources on 7 existing answers with thin sources
--          (campaign-finance, redistricting, religious-freedom, social-security,
--           tariffs, taxes, ukraine-support)
-- Group B: insert 8 new answer+context rows
--          (childcare, economic-development, homelessness, homelessness-response,
--           misinformation, public-safety-approach, school-vouchers, transportation-priorities)
-- Note: ai-regulation and data-centers skipped — no direct evidence found.

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Garcia co-sponsored the Stop Ballroom Bribery Act (Nov. 2025) with Sen. Warren to ban presidents from accepting private donations for White House renovations and imposing a 2-year lobbying ban on contributors — targeting dark-money corruption at the executive level. As a Progressive Caucus member he has consistently backed strong donation limits and disclosure requirements.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

UPDATE inform.politician_context SET
  reasoning = 'As mayor of Long Beach, Garcia proposed and passed a ballot initiative (Measure BBB) creating an independent redistricting commission for the city — removing elected officials from the process. His membership in the Congressional Progressive Caucus aligns with support for independent non-partisan redistricting nationally.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

UPDATE inform.politician_context SET
  reasoning = 'Garcia is a founding member of the Congressional Freethought Caucus, which is dedicated to maintaining the secular character of government and opposing religious exemptions that override civil rights protections. He supports LGBTQ non-discrimination laws without carve-outs. The Freethought Caucus explicitly backs the Johnson Amendment barring political endorsements by tax-exempt religious groups.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Congressional_Freethought_Caucus',
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

UPDATE inform.politician_context SET
  reasoning = 'OnTheIssues records Garcia as opposing Social Security privatization. He co-founded Mayors 4 Medicare (2020) to advocate universal healthcare access. In March 2026 the Congressional Progressive Caucus — of which Garcia is a member — announced joint opposition to Republican proposals to cut Social Security benefits and healthcare coverage.',
  sources = ARRAY[
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

UPDATE inform.politician_context SET
  reasoning = 'Garcia represents CA-42 (Long Beach), home to the largest US container port; he has consistently opposed broad tariffs that threaten port trade and jobs. As Long Beach mayor he established international trade relationships with Asia, Europe, and Latin America, signaling a pro-trade posture. As a Progressive Caucus member he supports selective environmental tariffs but not sweeping protectionist tariffs.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';

UPDATE inform.politician_context SET
  reasoning = 'Garcia is a member of the Congressional Progressive Caucus, which advocates for significantly higher taxes on wealthy individuals and corporations to fund social programs. He co-founded Mayors 4 Medicare (2020) and committed Long Beach to universal preschool — both requiring progressive revenue sources. His public statements consistently frame taxation as a tool for funding public goods.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

UPDATE inform.politician_context SET
  reasoning = 'Wikipedia documents that Garcia voted in favor of three military aid supplemental packages for Ukraine, Israel, and Taiwan in April 2024, alongside most Democrats. This reflects continued support for Ukrainian defense at current levels without committing to dramatically expanded aid or unconditional escalation.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
WHERE politician_id = '28a5f098-7f90-4fa9-af7e-c034d49cb538' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'As mayor of Long Beach, Garcia announced a goal of universal preschool enrollment and committed the city to the Long Beach College Promise — both reflecting a policy of significantly expanding publicly supported early childhood access. His Progressive Caucus membership aligns with federal investment in childcare subsidies and provider grants for low- and middle-income families.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'As Long Beach mayor, Garcia actively pursued international trade partnerships and city economic development while requiring Project Labor Agreements with construction unions — demonstrating a targeted-incentives approach with labor quality requirements. He recruited businesses while demanding community benefit conditions such as green certifications and worker retention plans.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Garcia introduced a Universal Basic Income proposal for foster youth exiting the system ($1,000/month for 5 years) and is a Progressive Caucus member that opposes criminalizing public sleeping. As mayor he invested in shelter capacity and transitional housing conversions. He supports decriminalizing public presence and redirecting resources toward service connections rather than criminal penalties.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'As Long Beach mayor Garcia''s administration converted hotels into transitional housing and expanded shelter capacity as the primary homelessness response strategy. The city operated outreach programs and service connections. While the city enforced some public-space rules, Garcia''s stated priorities centered on shelter expansion and services rather than enforcement-first approaches.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.longbeach.gov/homelessness/',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
  'Garcia is a member of the Congressional Freethought Caucus, which promotes policy solutions based on reason and science and has called for transparency in how government and institutions handle factual information. His Progressive Caucus membership aligns with support for platform accountability, fact-checking mandates, and algorithmic transparency — opposing both government censorship and unchecked platform misinformation.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Congressional_Freethought_Caucus',
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Garcia''s public safety record is mixed: as Long Beach mayor he received criticism from activists for his financial ties to the Long Beach Police Officers Association union, yet he also championed community programs and proposed ballot initiatives for ethics oversight. As a congressman he has not called for defunding police; his Progressive Caucus affiliation suggests support for adding crisis response teams without reducing core police funding.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  '00b95a6a-75db-4521-b523-3326bba938de',
  'Garcia committed Long Beach to the Long Beach College Promise (free college pathways) and set a goal of universal preschool enrollment — both representing investment in public education institutions. He is a member of the Congressional Progressive Caucus, which strongly opposes voucher programs that divert taxpayer money from public schools to private institutions.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://en.wikipedia.org/wiki/Congressional_Progressive_Caucus',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28a5f098-7f90-4fa9-af7e-c034d49cb538', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '28a5f098-7f90-4fa9-af7e-c034d49cb538',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Garcia is co-chair of the Congressional YIMBY Caucus, which co-introduced the People Over Parking Act (eliminating parking minimums) and the Build More Housing Near Transit Act — both signaling strong support for multimodal transportation investment over car-centric infrastructure. He sits on the House Transportation & Infrastructure Committee''s Highways and Transit subcommittee.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Congressional_YIMBY_Caucus',
    'https://en.wikipedia.org/wiki/Robert_Garcia_(California_congressman)',
    'https://www.ontheissues.org/Robert_Garcia.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

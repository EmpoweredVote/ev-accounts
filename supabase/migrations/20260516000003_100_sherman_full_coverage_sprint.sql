-- Full coverage sprint for Brad Sherman (politician_id: 96c77e2b-df35-4d56-a573-8bc0c15a142d)
-- Group A: fill sources + reasoning on 5 existing answers with empty sources
--          (ai-regulation, campaign-finance, medicare/aid, redistricting, religious-freedom)
-- Group B: insert 7 new answer+context rows
--          (childcare, economic-development, homelessness, homelessness-response,
--           public-safety-approach, school-vouchers, transportation-priorities)

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Sherman introduced the AI Research and Threat Assessment Act (2026) directing NIST to research risks of AI developing autonomous objectives, arguing government must fund safety research since "it is not in the interest of Silicon Valley billionaires to spend money making sure that AI does not develop its own self-awareness." His approach focuses on government-funded risk research and disclosure requirements rather than deployment bans or mandatory pre-release testing — a targeted disclosure and accountability framing consistent with stance 3.',
  sources = ARRAY[
    'https://sherman.house.gov/ai-research-and-threat-assessment-act',
    'https://ballotpedia.org/Brad_Sherman',
    'https://www.ontheissues.org/CA/Brad_Sherman.htm'
  ]
WHERE politician_id = '96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

UPDATE inform.politician_context SET
  reasoning = 'Sherman co-sponsored the DISCLOSE Act requiring full disclosure of independent campaign expenditures post-Citizens United, co-sponsored the Fair Elections Now Act establishing 500% small-donor matching funds, and voted YES on the For the People Act (H.R. 1) which includes public campaign financing via small-donor matching and federal redistricting reform. His record consistently supports public financing and strong disclosure as the path to reducing big-money influence, aligning with stance 2.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Brad_Sherman_Government_Reform.htm',
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman'
  ]
WHERE politician_id = '96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

UPDATE inform.politician_context SET
  reasoning = 'Sherman cosponsored the Social Security 2100: A Sacred Trust Act and voted against the 2025 Republican reconciliation bill that would cut Medicaid, stating it would "take away healthcare from 14 million Americans." He voted for the Inflation Reduction Act (2022) enabling Medicare drug price negotiation and capping insulin costs. His record supports protecting and modestly expanding both Medicare and Medicaid within a public-plus-private insurance framework rather than transitioning to a single-payer system, aligning with stance 2.',
  sources = ARRAY[
    'https://sherman.house.gov/media-center/press-releases/congressman-brad-sherman-hosts-5000-telephone-town-hall-voting-against',
    'https://www.bradsherman.com/meet-brad',
    'https://www.ontheissues.org/CA/Brad_Sherman_Health_Care.htm'
  ]
WHERE politician_id = '96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

UPDATE inform.politician_context SET
  reasoning = 'Sherman co-sponsored and voted YES on the For the People Act (H.R. 1, 2019 and 2021), which requires all states to establish independent nonpartisan redistricting commissions for congressional district boundaries. He also supported the Government By the People Act (2014) which includes redistricting accountability provisions. His record consistently reflects support for removing partisan control of redistricting in favor of independent commissions, fully matching stance 1.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Brad_Sherman_Government_Reform.htm',
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman'
  ]
WHERE politician_id = '96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

UPDATE inform.politician_context SET
  reasoning = 'Sherman cosponsored the Do No Harm Act clarifying that RFRA cannot override anti-discrimination protections in employment and housing, stating "it is more important than ever that Congress pass the Do No Harm Act." He cosponsored the Equality Act (reintroduced April 2025) establishing federal LGBTQ+ non-discrimination protections and voted YES on the Employment Non-Discrimination Act (2007). His record consistently prioritizes civil rights protections over religious exemptions from anti-discrimination law, aligning with stance 2.',
  sources = ARRAY[
    'https://sherman.house.gov/lgbtq',
    'https://www.ontheissues.org/CA/Brad_Sherman_Civil_Rights.htm',
    'https://ballotpedia.org/Brad_Sherman'
  ]
WHERE politician_id = '96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Sherman voted YES on the Build Back Better Act (H.R. 5376, November 2021, passed 220-213) which included $400 billion for universal pre-K, subsidized childcare on a sliding-scale income basis, and expanded the Child Tax Credit. He also co-sponsored the Child Care and Development Block Grant reauthorization and has consistently voted to protect Head Start funding. His record supports heavily subsidized, income-based childcare access rather than universal free childcare, aligning with stance 2.',
  ARRAY[
    'https://www.ontheissues.org/CA/Brad_Sherman_Education.htm',
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Sherman voted YES on the CHIPS and Science Act (2022) providing $52 billion in semiconductor manufacturing subsidies and $170 billion in science research — a direct public-private industrial policy investment. He also voted for the Inflation Reduction Act''s $370 billion in clean energy investment and the Infrastructure Investment and Jobs Act (IIJA, 2021). His approach centers on public-private partnerships and targeted government investment in strategic industries rather than full government ownership or pure deregulation, aligning with stance 2.',
  ARRAY[
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman',
    'https://www.ontheissues.org/CA/Brad_Sherman_Corporations.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Sherman secured $1.5 million for supportive housing for homeless veterans through the West LA VA campus and authored the Housing Unhoused Disabled Veterans Act (passed the House in 2025) to streamline disabled veterans'' access to housing assistance. He consistently supports federal housing investments and housing-first approaches while his public safety record (85% NAPO rating) suggests acceptance of limited enforcement alongside services for encampments. His record reflects a housing-first approach with limited enforcement as a last resort, aligning with stance 2.',
  ARRAY[
    'https://www.bradsherman.com/in-the-news/congressman-sherman%E2%80%99s-bill-to-help-house-homeless-vets-passed-by-house',
    'https://www.bradsherman.com/priorities',
    'https://www.ontheissues.org/CA/Brad_Sherman_Crime.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Sherman introduced the Housing Unhoused Disabled Veterans Act (passed House 2025) and secured $1.5 million for supportive housing at the West LA VA campus. He supported the Inflation Reduction Act and IIJA which include significant housing and community development funding. His record demonstrates a housing-first strategy backed by federal investment, with support for accountability measures; he has not advocated for enforcement-only approaches, aligning with stance 2.',
  ARRAY[
    'https://www.bradsherman.com/in-the-news/congressman-sherman%E2%80%99s-bill-to-help-house-homeless-vets-passed-by-house',
    'https://www.bradsherman.com/priorities',
    'https://www.bradsherman.com/meet-brad'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Sherman cosponsored the George Floyd Justice in Policing Act (H.R. 1280, passed House 220-212 in March 2021) which would lower the officer misconduct criminal intent standard and limit qualified immunity. However, he also has an 85% rating from the National Association of Police Organizations, has worked to "invest more in 911 emergency response, including for firefighters and police," and voted NO on redirecting prison funding to alternative sentencing (2000). His record reflects balanced targeted reforms with accountability while maintaining core law enforcement investment, aligning with stance 3.',
  ARRAY[
    'https://www.ontheissues.org/CA/Brad_Sherman_Crime.htm',
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  '00b95a6a-75db-4521-b523-3326bba938de',
  'Sherman voted NO on the DC Opportunity Scholarship (SOAR Act, 2011), NO on DC vouchers (1998), and NO on allowing federal funds for private/parochial school vouchers (1997). He has a 100% rating from the National Education Association for pro-public education votes and stated he opposes "private and religious school voucher programs." His record is a consistent, long-running opposition to school vouchers with exclusive support for public school investment, fully matching stance 1.',
  ARRAY[
    'https://www.ontheissues.org/CA/Brad_Sherman_Education.htm',
    'https://ballotpedia.org/Brad_Sherman',
    'https://www.bradsherman.com/meet-brad'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('96c77e2b-df35-4d56-a573-8bc0c15a142d', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '96c77e2b-df35-4d56-a573-8bc0c15a142d',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Sherman secured federal funding for the Metro Orange Line (San Fernando Valley bus rapid transit) and for improvements to the 405 and 101 freeways, while actively fighting for funds to build rail through the Sepulveda Pass. He voted for the Infrastructure Investment and Jobs Act (IIJA, 2021) which provides $89 billion for public transit and $66 billion for passenger and freight rail alongside $110 billion for roads. His record reflects balanced investment across transit, rail, and road infrastructure rather than either a car-centric or transit-exclusive approach, aligning with stance 2.',
  ARRAY[
    'https://www.bradsherman.com/meet-brad',
    'https://ballotpedia.org/Brad_Sherman',
    'https://www.ontheissues.org/CA/Brad_Sherman.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

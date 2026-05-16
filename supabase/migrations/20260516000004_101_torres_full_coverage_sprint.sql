-- Full coverage sprint for Norma Torres (politician_id: e4d5cd69-0a54-48d6-9d8c-11da8f091cb6)
-- Group A: fill sources on 4 existing answers with empty sources
--          (campaign-finance, deportation, redistricting, voting-rights)
-- Group B: insert 9 new answer+context rows
--          (ai-regulation, childcare, economic-development, homelessness,
--           homelessness-response, misinformation, public-safety-approach,
--           school-vouchers, transportation-priorities)

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Torres voted YES on a constitutional amendment to overturn Citizens United (Jun 2014) and supported strict limits on party soft-money contributions (Jan 2015). She has consistently backed the For the People Act and the DISCLOSE Act, which impose strict limits on corporate and dark-money donations while keeping small-donor public-matching programs. Her record supports tightly capped private money with full disclosure requirements, aligning with stance 2.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Norma_Torres.htm',
    'https://en.wikipedia.org/wiki/For_the_People_Act_of_2021',
    'https://en.wikipedia.org/wiki/DISCLOSE_Act'
  ]
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

UPDATE inform.politician_context SET
  reasoning = 'Torres, born in Guatemala, holds among the strongest pro-immigrant records in Congress: she received an F-rating on deportation from PVS and Faith2Action (Jul–Sep 2014), voted YES on driver''s licenses for undocumented immigrants (Sep 2013), and in Apr 2017 secured legal representation for children facing deportation. She has consistently opposed mass deportations and supported DREAMer legalization, aligning with stance 2 — deport only serious violent criminals while providing legal status to others.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Norma_Torres.htm',
    'https://ballotpedia.org/Norma_Torres',
    'https://en.wikipedia.org/wiki/Norma_Torres'
  ]
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

UPDATE inform.politician_context SET
  reasoning = 'Torres serves on the House Administration Committee (119th Congress) and has supported the For the People Act, which requires all states to use independent citizen commissions to draw congressional lines — with commissions comprising five Democrats, five Republicans, and five independents — while prohibiting partisan gerrymandering. California already uses such a model and Torres has supported extending it federally, aligning with stance 1.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/For_the_People_Act_of_2021',
    'https://en.wikipedia.org/wiki/House_Administration_Committee',
    'https://www.ontheissues.org/CA/Norma_Torres.htm'
  ]
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

UPDATE inform.politician_context SET
  reasoning = 'Torres backed automatic voter registration (Mar 2015), a pilot for all-mail-in ballots (Aug 2014), and a federal election-day holiday (Mar 2019) according to OnTheIssues. She cosponsored the For the People Act, which mandates automatic voter registration nationally, requires at least two weeks of early voting, and makes mail-in voting available to all voters without an excuse. This comprehensive expansion of access aligns with stance 1.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Norma_Torres.htm',
    'https://en.wikipedia.org/wiki/For_the_People_Act_of_2021',
    'https://en.wikipedia.org/wiki/Norma_Torres'
  ]
WHERE politician_id = 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', '666bf03d-81fc-4138-ab15-69ae734c9023', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  '666bf03d-81fc-4138-ab15-69ae734c9023',
  'Torres serves as Ranking Member of the House Administration Committee''s Oversight Subcommittee (119th Congress) and is a member of the New Democrat Coalition, which describes itself as pro-high-tech-sector and fiscally moderate. No specific AI ban or heavy-regulation legislation is on her record; her coalition supports innovation with targeted oversight rather than broad restrictions. Her profile aligns with stance 3 — require basic safety testing before release, without pre-approval mandates.',
  ARRAY[
    'https://en.wikipedia.org/wiki/House_Administration_Committee',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/Norma_Torres'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Torres voted YES on the Build Back Better Act (Nov 2021, 220–213), which included $400 billion for universal pre-K and subsidized childcare capped at 7% of income for families up to 250% of state median income. She also voted YES on the American Rescue Plan (Feb 2021), which expanded the child and dependent care tax credit to $4,000 per child and allocated $5B for housing support. Her record aligns with stance 2 — significantly expanding subsidies to make childcare affordable for low- and middle-income families.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Build_Back_Better_Act',
    'https://en.wikipedia.org/wiki/American_Rescue_Plan_Act_of_2021',
    'https://en.wikipedia.org/wiki/Norma_Torres'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Torres voted YES on the CHIPS and Science Act (2022), the Inflation Reduction Act''s $370 billion in clean energy and manufacturing investment, and the Infrastructure Investment and Jobs Act (2021). As a New Democrat Coalition member she supports targeted government investment in strategic industries through public-private partnerships rather than either full public ownership or pure deregulation. Her consistent support for federal industrial policy investments aligns with stance 2.',
  ARRAY[
    'https://en.wikipedia.org/wiki/CHIPS_and_Science_Act',
    'https://en.wikipedia.org/wiki/Inflation_Reduction_Act',
    'https://en.wikipedia.org/wiki/Norma_Torres'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Torres sits on the Appropriations Subcommittee on Transportation, Housing and Urban Development (119th Congress), where she works to fund federal homeless services and rental assistance. She voted YES on the American Rescue Plan, which dedicated $5 billion to homelessness programs including shelter conversion and rapid-rehousing. Her approach focuses on housing investment and wraparound services rather than criminalization, aligning with stance 2.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Norma_Torres',
    'https://en.wikipedia.org/wiki/American_Rescue_Plan_Act_of_2021',
    'https://www.ontheissues.org/CA/Norma_Torres.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Torres sits on the Appropriations Subcommittee on Transportation, Housing and Urban Development, securing federal housing and homelessness funding for the Inland Empire. She voted YES on the American Rescue Plan ($5B for homelessness programs) and the IIJA which included substantial community development and housing investment. Her record centers on housing-first investment backed by federal funding with accountability measures, aligning with stance 2.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Norma_Torres',
    'https://en.wikipedia.org/wiki/American_Rescue_Plan_Act_of_2021',
    'https://en.wikipedia.org/wiki/Infrastructure_Investment_and_Jobs_Act'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
  'Torres serves on the House Administration Committee (the primary committee overseeing federal elections and campaign communications), including its Oversight Subcommittee as Ranking Member. She has supported the For the People Act, which mandates rapid disclosure of digital political ad purchasers and funding sources. Her New Democrat Coalition membership supports platform accountability without government content removal, aligning with stance 2 — mandate fact-checking and transparency in how algorithms promote content.',
  ARRAY[
    'https://en.wikipedia.org/wiki/House_Administration_Committee',
    'https://en.wikipedia.org/wiki/For_the_People_Act_of_2021',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Torres described her public safety philosophy as working "with the community to combat crime" (Oct 2014, OnTheIssues). As a New Democrat Coalition moderate she has not supported defunding police; she backed the American Rescue Plan which maintained police funding alongside community investment. Her background as a former 9-1-1 dispatcher reflects support for emergency services. No record of redirecting police budgets to social services; she supports keeping current staffing while adding crisis response capacity, aligning with stance 3.',
  ARRAY[
    'https://www.ontheissues.org/CA/Norma_Torres.htm',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/American_Rescue_Plan_Act_of_2021'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  '00b95a6a-75db-4521-b523-3326bba938de',
  'OnTheIssues records Torres explicitly stating she "Oppose[s] private and religious school voucher programs" (Oct 2015). She additionally supports bilingual education in public schools (Aug 2014) and free community college (Jul 2015), reflecting a strong investment-in-public-schools philosophy. This aligns with stance 1 — fully fund public schools and eliminate voucher programs that divert taxpayer money to private institutions.',
  ARRAY[
    'https://www.ontheissues.org/CA/Norma_Torres.htm',
    'https://en.wikipedia.org/wiki/Norma_Torres',
    'https://en.wikipedia.org/wiki/Every_Student_Succeeds_Act'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Torres voted YES on the Infrastructure Investment and Jobs Act (2021), which allocates $89 billion for public transit and $66 billion for passenger and freight rail alongside $110 billion for roads. As a member of the Appropriations Subcommittee on Transportation, Housing and Urban Development she has worked to fund multimodal infrastructure in the Inland Empire, including rail and bus improvements. Her record reflects balanced investment in both transit/rail and roads, aligning with stance 2.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Infrastructure_Investment_and_Jobs_Act',
    'https://en.wikipedia.org/wiki/Norma_Torres',
    'https://www.ontheissues.org/CA/Norma_Torres.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

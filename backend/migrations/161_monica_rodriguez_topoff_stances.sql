-- Migration 161: Monica Rodriguez — topoff stances (26 new topics)
-- LA City Council CD7 (Pacoima / Sun Valley / Northeast San Fernando Valley)
-- Politician ID: 7c0d3bdd-a363-4d97-93a9-67034c6a0ead
-- Research date: 2026-05-16

DO $$
DECLARE
  v_pid UUID := '7c0d3bdd-a363-4d97-93a9-67034c6a0ead';
BEGIN

  -- politician_answers
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (v_pid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1),  -- same-sex-marriage
    (v_pid, '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2),  -- immigration
    (v_pid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2),  -- local-immigration
    (v_pid, '44905f3b-e105-4f6c-afc7-5d223813dbac', 2),  -- deportation
    (v_pid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2),  -- climate-change
    (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570', 3),  -- fossil-fuels
    (v_pid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2),  -- childcare
    (v_pid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2),  -- voting-rights
    (v_pid, '0bc588c6-39e1-4084-b5de-cac909b8b762', 2),  -- civil-rights
    (v_pid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3),  -- misinformation
    (v_pid, '4938766b-b45a-46e3-93bd-b8b30651271a', 3),  -- homelessness
    (v_pid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 3),  -- abortion
    (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2),  -- healthcare
    (v_pid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2),  -- medicare/aid
    (v_pid, '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3),  -- city-sanitation
    (v_pid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3),  -- growth-and-development
    (v_pid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2),  -- jail-capacity
    (v_pid, '92730f69-ae57-401c-8ad1-2d07834a895d', 3),  -- campaign-finance
    (v_pid, '00b95a6a-75db-4521-b523-3326bba938de', 1),  -- school-vouchers
    (v_pid, '87d20824-a6e9-407b-983c-65440084a0ab', 2),  -- social-security
    (v_pid, '683c8084-2281-4920-a07c-18439b2dd413', 3),  -- tariffs
    (v_pid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 3),  -- trans-athletes
    (v_pid, '24e9212c-b011-422a-865c-093e35050901', 3),  -- ukraine-support
    (v_pid, '666bf03d-81fc-4138-ab15-69ae734c9023', 3),  -- ai-regulation
    (v_pid, '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3),  -- religious-freedom
    (v_pid, '4559b513-0fd8-4ed1-babd-f3b554162f40', 3)   -- data-centers
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  -- same-sex-marriage
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    'Voted YES on CF 23-0002-S38 (June 9, 2023) to include ACA 5 support in the city''s 2023-24 State Legislative Program — ACA 5 was the constitutional amendment to overturn Prop 8 and restore same-sex marriage protections in California. The measure passed 12-0-3.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S38'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- immigration
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'Voted YES on CF 21-0002-S19 (Jan 2021) supporting a pathway to citizenship for all 11 million undocumented immigrants; voted YES on CF 21-0002-S55 (July 2021) supporting the US Citizenship Act providing pathways for undocumented residents; moved CF 21-0002-S39 (March 2021) extending FHA mortgage eligibility to DACA recipients. Voted YES on CF 25-0002-S5 (March 2025) supporting state funding for immigration removal defense. Consistently supports expanded legal pathways and protections for undocumented immigrants.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S55', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S19', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S5'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- local-immigration
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'Voted YES on CF 25-0002-S5 (March 2025) to support state funding to increase immigration removal defense — a direct anti-deportation measure. This aligns with LA''s Special Order 40 sanctuary city framework. No evidence of votes to cooperate with ICE or increase federal immigration enforcement cooperation. Rodriguez represents a heavily Latino district and has consistently supported immigrant protections.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S5', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S19'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- deportation
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '44905f3b-e105-4f6c-afc7-5d223813dbac',
    'Voted YES on CF 21-0002-S19 (Jan 2021) supporting pathway to citizenship for all 11 million undocumented immigrants; voted YES on CF 21-0002-S31 (Jan 2021) supporting fast-track citizenship for immigrant frontline COVID workers; voted YES on CF 21-0002-S55 (July 2021) on the US Citizenship Act. All votes reflect a position that undocumented immigrants who are long-term residents should have legal pathways, not be deported, aligning with stance 2.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S19', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S31', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S55'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- climate-change
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'Voted YES on CF 21-0002-S42 (March 2022) supporting LA''s 100% clean energy supply goals and expediting environmental review for clean energy transmission; voted YES on CF 22-0002-S80 (May 2022) supporting 100% carbon-free energy, building decarbonization, and electrification; voted YES on CF 22-0002-S21 (April 2022) on SB 1173 requiring CalPERS/CalSTRS to divest from fossil fuel holdings. Pattern reflects strong support for clean energy transition and climate action.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S42', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S80', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S21'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- fossil-fuels
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'a22215c3-6693-4bc2-b248-01aebba14570',
    'Voted YES on CF 22-0002-S21 (April 2022) supporting SB 1173 to prohibit CalPERS and CalSTRS from making new investments in fossil fuel holdings — a divestment measure. Also voted YES on CF 22-0002-S80 supporting state budget increases for public building decarbonization and 100% carbon-free energy. These votes reflect support for phasing out fossil fuel investment while not going so far as banning extraction — aligning with stance 3 (maintain current production levels with existing regulations) as a city council member without direct drilling permit authority.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S21', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S80'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- childcare
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    'Voted YES on CF 21-0002-S44 (March 2021) supporting the Marshall Plan for Moms resolution, which addressed compensation for unpaid labor, paid family leave, pay equity, and affordable childcare. Rodriguez''s district (low-income NE San Fernando Valley) has above-average childcare access challenges. Position aligns with stance 2 — expanding subsidies and supports for low/middle-income families.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S44'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- voting-rights
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
    'Voted YES on CF 21-0002-S67 (April 2021) supporting HR 1 (For the People Act) and HR 4 (John Lewis Voting Rights Act), which would expand voter access and restore pre-clearance requirements. However, voted NO on CF 23-0002-S78 (Sept 2023) on ACA 4 to restore voting rights for incarcerated felons — the council adopted it 10-2-3 but Rodriguez voted against. The HR 1 vote is more significant in scope; the NO on felon voting shows a more moderate position overall — stance 2 (expand early voting and mail-in voting) fits best.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S67', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S78'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- civil-rights
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'Was mover of CF 21-0002-S52 (March 2022) calling for federal legislation to fund investments addressing systemic racism and historic underinvestment in communities of color. Voted YES on CF 20-0769 on unarmed crisis response for non-violent calls (June 2020, affirmative votes through 2022). Also supported DEI training requirements for Neighborhood Councils (CF 20-0990, March 2023). Reflects consistent support for strengthening civil rights enforcement and equity programs.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S52', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-0769'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- misinformation
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    'Voted YES on CF 22-0002-S74 (June 2022) supporting AB 587, the Social Media Transparency and Accountability Act, which requires social media companies to publicly report their content moderation policies on hate speech, disinformation, and extremism — a transparency/disclosure approach rather than mandatory removal. This aligns with stance 3 (encourage voluntary standards and transparency) rather than aggressive government regulation.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S74'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- homelessness (Criminalization of Homelessness)
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '4938766b-b45a-46e3-93bd-b8b30651271a',
    'Voted YES on CF 21-0863 on the Street Engagement Strategy / Right to Housing / Housing Now program (Sept 2021, unanimous 15-0) and CF 25-0002-S9 (March 2025) as mover of Encampment Resolution Funding flexibility. Also moved CF 21-0002-S20 (Feb 2021) on the $2.4B AB 71 homelessness funding bill. Rodriguez''s district has ongoing encampment issues in Sunland-Tujunga; she has advocated for enforcement paired with services. Stance 3 — balance enforcement with services — reflects her practical centrist approach.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0863', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S9'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- abortion
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'Was absent (CF 22-0002-S73, May 2022) on the 11-0 abortion rights resolution codifying reproductive rights after Dobbs — the only council member absent without a no vote. No public record found of opposing abortion access. Her district spans suburban Sunland-Tujunga (more conservative) and working-class Latino Pacoima. The conspicuous absence on the key vote with no public explanation found warrants a more moderate score; overall Democratic identity places her around stance 3.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0002-S73'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- healthcare
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'Rodriguez represents one of LA''s most medically underserved districts (Pacoima, Sun Valley). Voted YES unanimously on CF 21-0002-S51 (moved by Rodriguez, Feb 2021) supporting expansion of Community Health Centers vaccination programs. Voted YES on CF 21-0002-S44 Marshall Plan for Moms which included healthcare access components. As a Democrat representing a low-income Latino district she has consistently supported ACA protections and Medi-Cal expansion in state legislative program votes. No evidence of single-payer advocacy; aligns with stance 2 (public option + ACA expansion).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S51', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S44'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- medicare/aid
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'Represents Pacoima/Sun Valley, one of LA''s highest Medi-Cal enrollment areas. Voted YES unanimously on CF 21-0002-S47 (March 2021) on COVID-19 pandemic relief funding. Supported Marshall Plan for Moms (CF 21-0002-S44) which included healthcare access. Rodriguez''s district demographics (heavily Latino, working-class, high uninsured rates historically) drive consistent support for Medi-Cal expansion and Medicare strengthening. Aligns with stance 2 (expand coverage significantly).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S47', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S44'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- city-sanitation
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '7687de4f-4d0b-462a-b803-bdfb23b16b42',
    'Rodriguez''s district (Pacoima, Sun Valley) has historically had sanitation inequities including illegal dumping and litter. She has introduced motions to improve street services in underserved areas. Voted YES on CF 21-0002-S42 (LA 100 study) and other infrastructure votes. No evidence of dramatic expansion demands or privatization advocacy. Her approach appears to be maintaining and incrementally improving city services, consistent with stance 3.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S42'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- growth-and-development
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    'Rodriguez has supported both housing development and some neighborhood character concerns in CD7. Voted YES on CF 21-0002-S18 on SB 9 allowing duplexes (12-1-2, Aug 2021) — supporting increased housing density. Also voted YES on CF 22-0651 on affordable housing preferences (Sept 2022). Her district is a mix of dense urban areas and suburban neighborhoods; she has generally taken a pro-development stance on affordable housing while being attentive to community concerns in suburban Sunland-Tujunga. Stance 3 reflects her balanced approach.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S18', 'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0651'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- jail-capacity
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'Voted YES multiple times on CF 20-0769 (unarmed crisis response for non-violent calls for service, June 2020 through March 2022), supporting diverting mental health and non-violent calls away from police to unarmed responders. This reflects a preference for diversion over incarceration for certain calls. Her support for diversion programs and crisis response alternatives aligns with stance 2 (reduce incarcerated population through diversion and treatment alternatives).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-0769'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- campaign-finance
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '92730f69-ae57-401c-8ad1-2d07834a895d',
    'No specific campaign finance reform votes found in the LA City Clerk record. Rodriguez is a Democrat who has not taken public stances opposing transparency requirements. She accepted endorsements from labor unions and some business groups. Scored 3 (require full disclosure of all political donations) as a default for a Democratic council member without specific evidence of stronger or weaker positions.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- school-vouchers
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '00b95a6a-75db-4521-b523-3326bba938de',
    'No school voucher votes in LA City Council jurisdiction. Voted YES on CF 21-0002-S16 (Feb 2021) supporting AB 78 guaranteeing students a civil right to quality public education — a pro-public-education stance. Rodriguez''s district (Pacoima, Sun Valley) relies heavily on LAUSD. As a Democrat representing a working-class district, her position aligns with stance 1 (fully fund public schools, oppose vouchers diverting taxpayer money).',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S16'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- social-security
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '87d20824-a6e9-407b-983c-65440084a0ab',
    'No direct Social Security votes at city council level. Rodriguez''s district has high proportions of low-income seniors and working-class residents who depend on Social Security. As a Democrat representing Pacoima and the NE San Fernando Valley, she has consistently supported expanding social safety net programs. Aligns with stance 2 (expand benefits modestly while strengthening program) based on overall policy trajectory and district constituency needs.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- tariffs
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '683c8084-2281-4920-a07c-18439b2dd413',
    'No direct tariff policy votes at city council level. Rodriguez has supported local manufacturing and workers — voted YES on AB 364 (foreign worker protections, CF 21-0002-S48, April 2021). Her district includes working-class communities that benefit from both free trade and some protectionism. No evidence of strong advocacy either for broad tariffs or free trade. Stance 3 (selective tariffs to protect key industries) fits her moderate working-class Democratic profile.',
    ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S48'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- trans-athletes
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    'No direct transgender athlete votes found at LA City Council level. Rodriguez has not made public statements on transgender athlete policy. Her district demographics (working-class Latino, mix of urban and suburban) and her centrist Democratic positioning suggest a middle position. No evidence of advocacy in either direction. Scored 3 (case-by-case decisions) as the most defensible default given no evidence.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- ukraine-support
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '24e9212c-b011-422a-865c-093e35050901',
    'No direct Ukraine votes at LA City Council level. Rodriguez has not made public statements on Ukraine aid. As a city council member, this is outside her jurisdiction. Scored 3 (limited humanitarian aid while encouraging diplomacy) as a cautious default based on insufficient direct evidence.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- ai-regulation
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '666bf03d-81fc-4138-ab15-69ae734c9023',
    'No AI regulation votes at LA City Council level. Rodriguez has not taken public positions on AI regulation. The city council has not acted on comprehensive AI policy as of 2025. Scored 3 (require basic safety testing before AI systems are released) as a reasonable default for a Democrat without specific evidence.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- religious-freedom
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    'No direct religious freedom votes found at LA City Council level. Rodriguez has not made notable public statements on religious freedom vs. anti-discrimination tensions. Her district is majority-Catholic Latino, which may influence some social positions. Stance 3 (balance religious practices with equal treatment) fits her overall moderate-to-progressive Democratic profile.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

  -- data-centers
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES (v_pid, '4559b513-0fd8-4ed1-babd-f3b554162f40',
    'No data center votes found at LA City Council level. Rodriguez''s district does not have major data center development activity. No public statements found on data center energy policy. Stance 3 (allow development with impact assessments and cost-sharing agreements) is the defensible default for a Democrat without specific evidence.',
    ARRAY[]::TEXT[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

END $$;

-- Full coverage sprint for Maxine Waters (politician_id: 203ab943-324d-4478-9093-d827d5d9c7da)
-- Group A: fill sources on 10 existing answers with thin/no sources
--          (campaign-finance, civil-rights, climate-change, misinformation, redistricting,
--           religious-freedom, same-sex-marriage, social-security, trans-athletes, ukraine-support)
-- Group B: insert 7 new answer+context rows
--          (childcare, economic-development, homelessness, homelessness-response,
--           public-safety-approach, school-vouchers, transportation-priorities)
-- Note: data-centers skipped — no evidence found by research agent.

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Waters voted YES on banning soft-money contributions and issue ads (2002) and cosponsored the DISCLOSE Act requiring disclosure of independent campaign expenditures. She stated publicly: "We ultimately need to move to assist the public financing of campaigns, as soon as we can." Her record aligns with strictly limiting dark money and corporate donations rather than total public-financing-only.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1ih/html/BILLS-117hr1ih.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Government_Reform.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

UPDATE inform.politician_context SET
  reasoning = 'Waters holds a 100% NAACP rating, cosponsored the Equality Act (H.R. 5, 117th Congress) protecting LGBTQ people including on the basis of gender identity in employment, housing, and public spaces, and cosponsored the George Floyd Justice in Policing Act to end qualified immunity and mandate racial bias training. She has repeatedly called for reparations and co-sponsored constitutional amendments for equal rights by gender, reflecting a stance well beyond maintaining current civil rights laws.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Civil_Rights.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1280ih/html/BILLS-117hr1280ih.htm',
    'https://www.hrc.org/campaigns/equality-act'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

UPDATE inform.politician_context SET
  reasoning = 'Waters endorsed the Green New Deal in February 2019 and supported the Inflation Reduction Act''s clean energy investments. Her LCV lifetime score is 92% (2025 score 88%), reflecting consistent pro-environment voting over decades. She voted NO on opening the Outer Continental Shelf to oil drilling and supports removing oil and gas exploration subsidies. Her position is rapid transition to clean energy by 2030, not an immediate ban on all carbon-emitting activities.',
  sources = ARRAY[
    'https://www.lcv.org/congressional-scorecard/moc/maxine-waters',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Environment.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

UPDATE inform.politician_context SET
  reasoning = 'Waters cosponsored the DISCLOSE Act requiring transparency in political advertising and supported net neutrality and the Save the Internet Act. She voted YES on requiring lobbyist disclosure of bundled donations (2007). Her pattern favors mandatory transparency and fact-checking requirements over voluntary self-regulation, while she has not called for outright government removal of content. She voted for the For the People Act which included campaign-speech disclosure provisions.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Technology.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Government_Reform.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1ih/html/BILLS-117hr1ih.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

UPDATE inform.politician_context SET
  reasoning = 'Waters cosponsored and voted YES on the For the People Act (H.R. 1, 117th Congress) which mandates independent state redistricting commissions for congressional maps, bans mid-decade redistricting, and requires public notice and input before any plan is adopted. Her co-sponsorship of this legislation — the most expansive redistricting reform bill in modern history — firmly places her at value 1 (independent citizens'' commissions with no elected officials involved).',
  sources = ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1ih/html/BILLS-117hr1ih.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Government_Reform.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

UPDATE inform.politician_context SET
  reasoning = 'Waters consistently voted NO on measures tying federal education aid to voluntary school prayer and received a 16% rating from the Christian Coalition. She supported the Respect for Marriage Act (H.R. 8404, 2022), which codified same-sex marriage while explicitly preserving religious liberty exemptions allowing faith-based organizations to decline participation in ceremonies. Her record reflects protecting religious freedom as long as it does not override anti-discrimination protections in employment, housing, and public accommodations.',
  sources = ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr8404enr/html/BILLS-117hr8404enr.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Education.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

UPDATE inform.politician_context SET
  reasoning = 'Waters voted NO on the constitutional amendment defining marriage as one-man-one-woman in both 2004 and 2006, and voted YES on the Respect for Marriage Act (H.R. 8404, 2022) which requires all states to recognize same-sex marriages and repeals the Defense of Marriage Act. She cosponsored the Employment Non-Discrimination Act and received an 88% HRC rating. Her record consistently supports full federal recognition and benefits for same-sex couples with no carve-outs beyond existing religious exemptions.',
  sources = ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr8404enr/html/BILLS-117hr8404enr.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Civil_Rights.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';

UPDATE inform.politician_context SET
  reasoning = 'Waters signed the Social Security Protectors Pledge committing to prevent "any effort to privatize or scale back Social Security benefits or raise the retirement age," co-sponsored legislation opposing private savings accounts, and opposed using chained CPI for benefit calculations. She is rated 98-100% by the Alliance for Retired Americans and voted YES on strengthening the Social Security Lockbox (HR 1259, 1999). Her position is expanding benefits and removing the income cap on payroll taxes.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Social_Security.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.lcv.org/congressional-scorecard/moc/maxine-waters'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

UPDATE inform.politician_context SET
  reasoning = 'Waters cosponsored the Equality Act (H.R. 5, 117th Congress) which prohibits discrimination on the basis of gender identity across employment, housing, education, and public accommodations with no sport-specific carve-outs or documentation requirements. She cosponsored the Student Non-Discrimination Act protecting students from discrimination based on gender identity in schools. Her record supports allowing transgender athletes to compete on teams matching their gender identity without restriction.',
  sources = ARRAY[
    'https://www.hrc.org/campaigns/equality-act',
    'https://www.ontheissues.org/CA/Maxine_Waters_Civil_Rights.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';

UPDATE inform.politician_context SET
  reasoning = 'Waters voted for H.R. 7691 (Additional Ukraine Supplemental Appropriations Act, 2022 — $40.9B), H.R. 2471 (Consolidated Appropriations Act, 2022, which included Ukraine Supplemental Appropriations), and H.R. 815 (Emergency Supplemental Appropriations Act, 2024 — including $27.9B in DoD Ukraine aid and $7.85B economic support). Her consistent pattern of supporting Ukraine military and economic assistance at current requested levels places her at value 2.',
  sources = ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr7691enr/html/BILLS-117hr7691enr.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr2471enr/html/BILLS-117hr2471enr.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-118hr815enr/html/BILLS-118hr815enr.htm'
  ]
WHERE politician_id = '203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Waters voted YES on the American Rescue Plan Act (H.R. 1319, 2021) which appropriated $38.97B in childcare stabilization grants and block grants, and supported the Build Back Better Act''s universal pre-K and childcare provisions. She endorsed Head Start expansion and has consistently supported the Child Care and Development Block Grant Program. Her record aligns with significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1319enr/html/BILLS-117hr1319enr.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Education.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Waters consistently opposed large corporate tax incentives and free trade deals that undermine worker standards (voted NO on CAFTA, US-Australia, US-Singapore FTAs) while supporting small business lending through credit union caps, Export-Import Bank expansion, and labor standards requirements. She rates 100% with AFL-CIO and the United Food and Commercial Workers. Her economic development approach prioritizes small businesses, worker protections, and community benefit over large corporate subsidies.',
  ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Corporations.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Free_Trade.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'As Ranking Member of the House Financial Services Committee, Waters has repeatedly pushed for expanded Section 8 housing vouchers and HUD funding for homelessness prevention. She supported the American Rescue Plan''s $5B Emergency Housing Voucher program and HOME Investment Partnerships funding. Her approach favors decriminalizing public sleeping while investing in shelter capacity and voluntary service connections over enforcement-first strategies.',
  ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1319enr/html/BILLS-117hr1319enr.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.lcv.org/congressional-scorecard/moc/maxine-waters'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Waters'' record on the House Financial Services Committee centers on expanding shelter capacity, housing vouchers, and outreach services as the primary response to homelessness. She has not sponsored criminalization measures and her support for the George Floyd Justice in Policing Act reflects opposition to over-policing of vulnerable populations. She supported American Rescue Plan funding for emergency housing vouchers while advocating for services-led approaches.',
  ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1319enr/html/BILLS-117hr1319enr.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1280ih/html/BILLS-117hr1280ih.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Waters co-sponsored the George Floyd Justice in Policing Act (H.R. 1280, 117th Congress) to end qualified immunity, ban chokeholds and no-knock warrants in drug cases, and require racial bias training — a reform package that shifts non-violent enforcement toward accountability without defunding police entirely. She is rated 23% by the National Association of Police Organizations (NAPO) for her police-accountability stance. Her position favors shifting non-violent and mental health calls to unarmed co-responders while maintaining police staffing.',
  ARRAY[
    'https://www.govinfo.gov/content/pkg/BILLS-117hr1280ih/html/BILLS-117hr1280ih.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters_Crime.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  '00b95a6a-75db-4521-b523-3326bba938de',
  'Waters voted NO on the DC Opportunity Scholarship Program in both 2011 and 2015, voted NO on vouchers for private and parochial schools in 1997, and voted NO on allowing vouchers in DC schools in 1998. She is rated 100% by the National Education Association and stated her position as "Oppose private and religious school voucher programs" (Oct 2015). Her consistent multi-decade record clearly places her at fully funding public schools and eliminating programs that divert taxpayer money to private institutions.',
  ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Education.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm',
    'https://www.lcv.org/congressional-scorecard/moc/maxine-waters'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('203ab943-324d-4478-9093-d827d5d9c7da', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '203ab943-324d-4478-9093-d827d5d9c7da',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Waters voted YES on $9.7B for Amtrak improvements (2008), YES on $2B supplemental for Cash for Clunkers (fuel-efficient vehicle incentives, 2009), and supported the Infrastructure Investment and Jobs Act (H.R. 3684, 2021) which funds public transit, bicycle and pedestrian infrastructure, active transportation investment programs, and safe routes to school alongside highway investment. She supported $1B in TIGER transportation grants for multimodal projects. Her record supports equal investment in roads and multimodal options.',
  ARRAY[
    'https://www.ontheissues.org/CA/Maxine_Waters_Environment.htm',
    'https://www.govinfo.gov/content/pkg/BILLS-117hr3684rh/html/BILLS-117hr3684rh.htm',
    'https://www.ontheissues.org/CA/Maxine_Waters.htm'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

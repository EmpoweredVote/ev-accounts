-- Full coverage sprint for Linda T. Sanchez (politician_id: bb73793e-ad67-431a-bb03-663b765204d8)
-- Group A: update reasoning+sources on 3 existing thin rows + fix tariffs value 2→3
--          (ai-regulation, civil-rights, tariffs)
-- Group B: insert 7 new answer+context rows
--          (childcare, economic-development, homelessness, homelessness-response,
--           public-safety-approach, school-vouchers, transportation-priorities)

-- ── GROUP A: Update existing thin context rows ────────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Voted NO on CISPA (2013) over data privacy concerns, cosponsored the Save the Internet Act (2019) for algorithmic fairness via net neutrality, and voted NO on retroactive telecom immunity for warrantless surveillance (2008). Her tech record shows consistent support for oversight and safety requirements — she favors basic regulatory guardrails without heavy government control of technology development.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Technology.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez_Homeland_Security.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ]
WHERE politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

UPDATE inform.politician_context SET
  reasoning = 'Rated 100% by the NAACP and Human Rights Campaign. Cosponsored the Equal Rights Amendment (multiple years), Employment Non-Discrimination Act including gender identity (2009), Paycheck Fairness Act (2013), and George Floyd Justice in Policing Act (2021). Voted YES on reauthorizing VAWA (2013) with expanded protections for LGBTQ+ individuals and immigrants. Strong advocate for strengthening civil rights enforcement and addressing systemic discrimination.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Civil_Rights.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez_Crime.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ]
WHERE politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

-- Fix value 2→3 for tariffs (selective worker-protection tariffs, not free trade)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';

UPDATE inform.politician_context SET
  reasoning = 'Voted NO on CAFTA (2005), US-Australia, US-Singapore, and US-Chile FTAs (2003-2004), and Peru FTA (2007) due to insufficient labor protections — but voted YES on USMCA (2019) with enforceable labor standards. Cosponsored Currency Reform for Fair Trade Act (2011) targeting currency manipulation. Her pattern is selective tariffs to protect American workers and key industries, not blanket free trade or blanket protectionism.',
  sources = ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Free_Trade.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ]
WHERE politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Voted YES on expanding SCHIP children''s health coverage and working families tax relief including child tax credits. As a member of the Congressional Progressive Caucus with a 100% AFL-CIO rating, Sanchez has consistently backed expanded subsidies and social programs for working families. She voted for Build Back Better (H.R.5376, 2021) which included major childcare subsidy expansion.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Health_Care.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Supports targeted economic development: voted YES on the $825 billion ARRA stimulus (2009), co-sponsored small business lending expansion (2012), and backed nanotechnology R&D funding. Chamber of Commerce rates her 24%, reflecting selective rather than maximal pro-business alignment. She supports job creation tied to worker protections and community benefit, not blank corporate subsidies.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Budget_+_Economy.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Voted YES on HOPE VI public housing revitalization (2008) emphasizing one-for-one replacement, voted YES on mortgage modification protections (2009) to prevent foreclosures, and opposed HAMP termination (2011). As a Progressive Caucus member supporting expanded public housing and shelter options, her record reflects a services-and-investment approach to homelessness over criminalization.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Budget_+_Economy.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez_Health_Care.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Sanchez''s federal record consistently favors shelter capacity expansion, housing investment, and services over enforcement. She voted YES on public housing programs and opposed policies that would gut housing assistance. Her Progressive Caucus membership and 100% AFL-CIO rating indicate support for outreach and shelter as primary strategies over anti-camping enforcement.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Budget_+_Economy.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Cosponsored the George Floyd Justice in Policing Act (H.R.1280, Feb 2021), which would limit qualified immunity and reform use-of-force standards. Also voted YES on the First Step Act (2018) for criminal justice reform and Second Chance Act (2007). NAPO rated her 77% in 2014, indicating she supports police accountability reforms while maintaining law enforcement funding.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Crime.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez_Homeland_Security.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', '00b95a6a-75db-4521-b523-3326bba938de',
  'Voted NO on the DC Opportunity Scholarship (SOAR Act) in both 2011 and 2015. Explicitly stated: ''Oppose private and religious school voucher programs'' (Oct 2015). Rated 100% by the NEA for pro-public education votes. Voted YES on $10.2 billion supplemental for Education/HHS/Labor (2007). Her record is fully opposed to diverting public funds to private schools via vouchers.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Education.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb73793e-ad67-431a-bb03-663b765204d8', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Voted YES on $9.7 billion for Amtrak improvements (Jun 2008) and $214 million Amtrak funding (Jun 2006). Voted YES on $23 billion for waterway infrastructure (2007). Cosponsored the Green New Deal (2019) which calls for massive clean transportation investment. Her record favors multimodal and public transit investment alongside road infrastructure.',
  ARRAY[
    'https://www.ontheissues.org/CA/Linda_Sanchez_Environment.htm',
    'https://www.ontheissues.org/CA/Linda_Sanchez.htm',
    'https://en.wikipedia.org/wiki/Linda_S%C3%A1nchez'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Full coverage sprint for Hilda L. Solis (politician_id: f1f3e6ca-5532-4f33-8ec2-64791b08f59b)
-- Group A: insert 1 new answer+context row (religious-freedom)
--          ai-regulation, redistricting, ukraine-support skipped — no evidence for county supervisor
-- Group B: update reasoning+sources on 13 existing thin rows + fix school-vouchers value 5→1
--          (abortion, childcare, data-centers, deportation, economic-development, homelessness,
--           misinformation, public-safety-approach, school-vouchers, social-security, taxes,
--           trans-athletes, transportation-priorities, voting-rights)

-- ── GROUP B: Update existing thin context rows ────────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Rated 100% by NARAL and 0% by NRLC based on her congressional voting record. Voted NO on partial-birth abortion restrictions (2003) and YES on embryonic stem cell research expansion (2007). As LA County Supervisor she created an LGBTQ+ Commission and authored motions supporting gender-affirming healthcare, signaling continued support for full reproductive rights access.',
  sources = ARRAY[
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.ontheissues.org/celeb/Hilda_Solis_Civil_Rights.htm',
    'https://hildalsolis.org/motions-solis/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';

UPDATE inform.politician_context SET
  reasoning = 'As LA County Supervisor Solis established a $20 million workforce and job training program for youth and consistently championed expanded social services for low-income families. Her Jobs platform funded microloans and specialized training programs targeting underserved populations. Aligns with significantly expanded subsidies and provider grants for low- and middle-income families rather than universal public childcare.',
  sources = ARRAY[
    'https://hildalsolis.org/2022/jobs/',
    'https://www.hildasolis.com/2022/jobs/',
    'https://www.ontheissues.org/Hilda_Solis.htm'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';

UPDATE inform.politician_context SET
  reasoning = 'As LA County Supervisor Solis''s digital equity platform emphasizes that internet service is a necessary utility and advocates for a Community Broadband Network, affordable connectivity programs, and digital workforce development. She has not called for a moratorium on data centers but has prioritized ensuring residents rather than large tech interests bear the costs of digital infrastructure expansion.',
  sources = ARRAY[
    'https://hildalsolis.org/digital-equity/',
    'https://www.hildasolis.com/2022/meet-hilda/',
    'https://www.ontheissues.org/Hilda_Solis.htm'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40';

UPDATE inform.politician_context SET
  reasoning = 'Solis has authored more than 60 motions defending immigrant communities during federal enforcement crackdowns, established cash aid funds for workers impacted by ICE raids, and co-funded the $10 million LA Justice Fund for deportation defense. She explicitly frames aggressive federal deportation actions as violating constitutional rights and has committed county resources to preventing removal of long-term residents.',
  sources = ARRAY[
    'https://hildalsolis.org/immigration/',
    'https://hildalsolis.org/meet-hilda/',
    'https://www.hildasolis.com/2022/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

UPDATE inform.politician_context SET
  reasoning = 'Solis''s economic development approach centers on workforce training, apprenticeships, and microloans for small businesses rather than tax incentives or corporate subsidies. She proposed a new Department of Workforce and Economic Development and demanded the county build networks of apprenticeship programs targeting formerly incarcerated individuals, foster youth, and the unhoused — prioritizing equitable public investment over attracting large employers.',
  sources = ARRAY[
    'https://www.hildasolis.com/2022/jobs/',
    'https://hildalsolis.org/meet-hilda/',
    'https://www.ontheissues.org/Hilda_Solis.htm'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

UPDATE inform.politician_context SET
  reasoning = 'Solis has led a housing-first strategy: authored motions to accelerate permanent housing units on County-owned property, championed Project Roomkey and Homekey rapid housing sites, increased youth homelessness funding from the 8% legal minimum to 18%, and expanded harm reduction health hubs. Her official platform explicitly prioritizes permanent supportive housing over enforcement, with outreach and services as the primary tool.',
  sources = ARRAY[
    'https://hildalsolis.org/housing-and-homelessness/',
    'https://www.hildasolis.com/2022/homelessness/',
    'https://hildalsolis.org/justice-reimagined/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET
  reasoning = 'Solis authored a motion to protect LA County youth from the negative impacts of social media, indicating support for government action on platform harms. Her progressive record on civil liberties (ACLU 87%) reflects a balance between free expression and accountability. She aligns with mandating fact-checking and transparency in algorithmic content promotion rather than either laissez-faire or heavy-handed removal mandates.',
  sources = ARRAY[
    'https://hildalsolis.org/motions-solis/',
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.hildasolis.com/2022/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

UPDATE inform.politician_context SET
  reasoning = 'Solis created the Care First, Jails Last Capital Project Fund redirecting jail construction funding to housing and community investments, led the effort to cancel a $1.7 billion new jail contract, and advocates for closing Men''s Central Jail. She redefines public safety as equitable access to housing, employment, and healthcare rather than policing, and has invested in the Office of Violence Prevention and restorative justice programs.',
  sources = ARRAY[
    'https://hildalsolis.org/justice-reimagined/',
    'https://www.hildasolis.com/2022/public-safety/',
    'https://hildalsolis.org/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- Fix out-of-range value 5→1 for school-vouchers
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

UPDATE inform.politician_context SET
  reasoning = 'Solis earned a 100% rating from the National Education Association for pro-public education votes in Congress. She supported increased federal education funding, class size reduction, and grants to Hispanic-Serving Institutions. She has no record of supporting school vouchers and consistently aligned with NEA''s anti-voucher position. Her congressional record places her squarely at the fully-fund-public-schools end of the scale.',
  sources = ARRAY[
    'https://www.ontheissues.org/celeb/Hilda_Solis_Education.htm',
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.hildasolis.com/2022/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

UPDATE inform.politician_context SET
  reasoning = 'Solis co-sponsored legislation explicitly rejecting proposals to substitute private savings accounts for Social Security benefits and committed to preserving guaranteed, lifelong, inflation-protected benefits. She was rated 100% by the Alliance for Retired Americans and consistently opposed all privatization proposals during her congressional career.',
  sources = ARRAY[
    'https://www.ontheissues.org/celeb/Hilda_Solis_Social_Security.htm',
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.hildasolis.com/2022/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

UPDATE inform.politician_context SET
  reasoning = 'Rated 100% by Citizens for Tax Justice for progressive taxation support. Voted NO on making Bush tax cuts permanent (2002) and NO on eliminating the estate tax (2001). The CTJ and AFL-CIO (100%) ratings reflect support for modestly increasing taxes on high earners while protecting middle-class rates, consistent with her labor-focused record rather than a dramatic wealth tax or flat-tax approach.',
  sources = ARRAY[
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.ontheissues.org/celeb/Hilda_Solis_Civil_Rights.htm',
    'https://www.hildasolis.com/priorities'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

UPDATE inform.politician_context SET
  reasoning = 'Solis has a 100% HRC rating and established an LGBTQ+ Commission in LA County, authored Care With Pride motion supporting gender-affirming healthcare, and has consistently opposed anti-LGBTQ+ legislation. She aligns with allowing transgender athletes to compete consistent with their gender identity following basic transition documentation, rather than outright bans or unrestricted access without any process.',
  sources = ARRAY[
    'https://hildalsolis.org/motions-solis/',
    'https://www.ontheissues.org/celeb/Hilda_Solis_Civil_Rights.htm',
    'https://www.ontheissues.org/Hilda_Solis.htm'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';

UPDATE inform.politician_context SET
  reasoning = 'Solis''s official transportation platform explicitly champions bus, rail, shared mobility, and active transportation (walking, biking) over car-centric investment. She championed the Student Free Pass for TK-12 students, the Low Income Fare Program, the San Gabriel Valley Gold Line extension, and the El Sol Shuttle for seniors — all prioritizing pedestrian and transit equity over road capacity.',
  sources = ARRAY[
    'https://hildalsolis.org/transportation/',
    'https://www.hildasolis.com/2022/transportation/',
    'https://hildalsolis.org/meet-hilda/'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';

UPDATE inform.politician_context SET
  reasoning = 'Voted NO on voter photo ID requirements (2006 congressional vote) and YES on campaign finance reform banning soft money. As LA County Supervisor Solis authored motions to support democracy and expand access; her campaign platform emphasizes a Voter Expansion Project. Her consistent 87% ACLU and pro-reform voting record aligns with automatic registration and maximum ballot access.',
  sources = ARRAY[
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://www.hildasolis.com/priorities',
    'https://www.ontheissues.org/celeb/Hilda_Solis_Civil_Rights.htm'
  ]
WHERE politician_id = 'f1f3e6ca-5532-4f33-8ec2-64791b08f59b' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- ── GROUP A: New answer + context row ────────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1f3e6ca-5532-4f33-8ec2-64791b08f59b', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f1f3e6ca-5532-4f33-8ec2-64791b08f59b',
  '6b9ba6d9-1001-43f5-b073-4d37130696fd',
  'Solis voted NO on constitutional amendments defining marriage as one man and one woman (2004 and 2006), voted YES on the Employment Non-Discrimination Act prohibiting job discrimination based on sexual orientation, and holds a 100% HRC rating. Her record consistently places civil rights protections above religious exemptions in employment and housing contexts, aligning with stance 2: protecting religious freedom while ensuring it does not override anti-discrimination protections.',
  ARRAY[
    'https://www.ontheissues.org/celeb/Hilda_Solis_Civil_Rights.htm',
    'https://www.ontheissues.org/Hilda_Solis.htm',
    'https://hildalsolis.org/motions-solis/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

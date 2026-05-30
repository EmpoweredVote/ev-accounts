-- Full coverage sprint for Curren D. Price Jr. (politician_id: 725d4081-e820-4064-83dc-3f8470bd7c2b)
-- LA City Council District 9; former CA State Senator
-- Group A: add sources to 7 existing thin context rows
--          (economic-development, growth-and-development, homelessness-response,
--           local-immigration, rent-regulation, residential-zoning, transportation-priorities)
-- Group B: insert 9 new answer+context rows
--          (climate-change, deportation, fossil-fuels, homelessness, housing,
--           immigration, same-sex-marriage, childcare, school-vouchers)
-- Skipped: abortion, religious-freedom, trans-athletes — no evidence found

-- ── GROUP A: Add sources to existing thin context rows ───────────────────────

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S4',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=24-0002-S7',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S1'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'economic-development' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0664',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S71',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S59'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'growth-and-development' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-0841',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-1376',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0108'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness-response' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S5',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0106',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S61'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'local-immigration' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0664',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=24-0002-S7',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S51'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'rent-regulation' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S71',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S59',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S2'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'residential-zoning' LIMIT 1
);

UPDATE inform.politician_context SET
  sources = ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-1365',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0002-S77'
  ]
WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b' AND topic_id = (
  SELECT id FROM inform.compass_topics WHERE topic_key = 'transportation-priorities' LIMIT 1
);

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'climate-change' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'Price voted YES on climate mitigation and habitat resilience funding (CF 21-0950, Nov 2021), YES on building sector zero-emissions strategy by 2045 / AB 593 (CF 23-0002-S85, Oct 2023), YES on Cap-and-Trade RPS adjustment credit (CF 25-0002-S25, May 2025), and YES on the Polluters Pay Climate Superfund Act / AB 1243 (CF 25-0002-S44, Jul 2025), holding fossil fuel companies financially responsible for climate damages. This pattern reflects strong commitment to rapid decarbonization.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=21-0950',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S85',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S44'
  ]
FROM inform.compass_topics WHERE topic_key = 'climate-change' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'deportation' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'Price voted YES on AB 1306 / HOME Act (CF 23-0002-S61, Mar 2025) to end state cooperation with federal deportation hearings for incarcerated immigrants; YES on immigration removal defense funding (CF 25-0002-S5, Mar 2025); YES on comprehensive immigration reform including DACA and TPS permanent legal status (CF 25-0002-S67, Aug 2025). As a CA State Senator he voted YES on both California DREAM Acts (AB 130 and AB 131, 2011). This record supports legal pathways and limits deportation cooperation to serious violent criminals.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0002-S61',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S5',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S67'
  ]
FROM inform.compass_topics WHERE topic_key = 'deportation' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'fossil-fuels' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'Price voted YES on the Polluters Pay Climate Superfund Act (CF 25-0002-S44 / AB 1243 + SB 684, Jul 2025) holding fossil fuel companies financially liable for climate damages; YES on zero-emissions port electrification / AB 1023 (CF 25-0002-S20, Apr 2025); and YES on Cap-and-Trade RPS credit reform (CF 25-0002-S25, May 2025). His record supports making new fossil fuel extraction financially untenable through polluter liability and emissions regulations rather than an outright permit ban.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S44',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S20',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S25'
  ]
FROM inform.compass_topics WHERE topic_key = 'fossil-fuels' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'homelessness' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'Price consistently voted YES on CF 20-0841 (crisis housing — tiny homes, safe sleep, shelter expansion) across nine votes from 2020–2021, YES on CF 25-0108 (Prop 1 behavioral health and supportive housing funding, Mar 2025), and YES on Encampment Resolution Funding / CF 25-0002-S9 (Mar 2025). He has not sponsored criminalization-first legislation and his voting pattern reflects a services-expansion approach with decriminalization principles.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=20-0841',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0108',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S9'
  ]
FROM inform.compass_topics WHERE topic_key = 'homelessness' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing: use the known topic_id 669cac97-66a6-4087-b036-936fbe62efb3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('725d4081-e820-4064-83dc-3f8470bd7c2b', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('725d4081-e820-4064-83dc-3f8470bd7c2b', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Price voted YES on the LA Affordable Housing Managed Pipeline / CTCAC Round 2 funding (CF 22-0664, Jun 2022), YES on HOPWA program staffing expansion (CF 22-0576, Jun 2022), YES on affordable housing incentives ordinance (CF 19-0722, Sep 2020), and YES on housing streamlining via SB 423 (CF 23-0002-S71). He has consistently backed subsidized affordable housing construction and state/federal subsidy programs while representing one of LA''s most housing-cost-burdened districts.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0664',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0576',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=19-0722'
  ])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'immigration' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'As a CA State Senator Price voted YES on California DREAM Act (AB 130, Jul 2011) and YES on AB 131 (Aug 2011) providing state financial aid to undocumented students. As LA City Councilmember he voted YES on comprehensive immigration reform including DACA/TPS permanent legal status (CF 25-0002-S67, Aug 2025), YES on immigration legal services funding (CF 25-0002-S48, Jul 2025), and YES on Medi-Cal access for immigrants (CF 25-0002-S43, Aug 2025). His record reflects significant increase in legal immigration and pathways to citizenship.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201120120AB130',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S67',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S48'
  ]
FROM inform.compass_topics WHERE topic_key = 'immigration' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 1
FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'As a CA State Senator Price voted YES on SB 54 (Sep 2009) to allow California to recognize out-of-state same-sex marriages, and voted YES on SB 48 (Apr 2011) — the FAIR Education Act mandating inclusive LGBTQ history in public school curricula. These votes from his time as a senator confirm full support for same-sex marriage recognition and LGBTQ legal equality. He has subsequently represented a Democratic district and taken no contradictory positions.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=200920100SB54',
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201120120SB48'
  ]
FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 2
FROM inform.compass_topics WHERE topic_key = 'childcare' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'Price voted YES on CF 22-0730 (childcare grant for Jim Gilliam Child Care Center in District 9 via California Dept. of Social Services, Aug 2022) and voted YES on Medi-Cal expansion for immigrants (CF 25-0002-S43) signaling support for government-funded social services for low-income families. His district (South Central LA) has significant childcare needs and he has not opposed city childcare subsidy expansions. He was absent on CF 25-0002-S35 (childcare subsidy reimbursement rates measure, Feb 2026) but the measure passed 14-0.',
  ARRAY[
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=22-0730',
    'https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=25-0002-S43'
  ]
FROM inform.compass_topics WHERE topic_key = 'childcare' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id, 1
FROM inform.compass_topics WHERE topic_key = 'school-vouchers' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '725d4081-e820-4064-83dc-3f8470bd7c2b', id,
  'As a CA State Senator Price voted YES on both California DREAM Acts (AB 130, Jul 2011 and AB 131, Aug 2011) expanding public financial aid for undocumented students — consistent with strengthening public funding access rather than diverting funds to private schools. His District 9 includes LAUSD schools in historically underinvested South LA communities, and he has not sponsored or supported any voucher or school choice legislation in his 12+ years on the LA City Council.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201120120AB130',
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=201120120AB131'
  ]
FROM inform.compass_topics WHERE topic_key = 'school-vouchers' LIMIT 1
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

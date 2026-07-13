-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H8 (22 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H8.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Elda Luna-Nájera (State House District 22) / childcare = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Sole prime sponsor of HB4135 (2026), which creates a new $2,000/$1,000 income-tiered state income-tax credit for child care expenses for children age 5 or younger using a certified provider, capped at $15M aggregate. A targeted, income-threshold-based tax credit for child care matches the 'targeted tax credits...for families below a set income threshold' chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4135p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2349']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'childcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elda Luna-Nájera (State House District 22) / healthcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Cosponsor of HB2520 (2026), which prohibits cost-sharing for contraception under regulated private health insurance plans. A coverage mandate on private insurers for a specific benefit matches the 'affordable coverage through a mix of public programs and regulated private insurance' chair. One of several named cosponsors, not prime.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2520p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elda Luna-Nájera (State House District 22) / medicare/aid = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Cosponsor of HB2521 (2026), which raises Arizona's Children's Health Insurance Program (KidsCare/AHCCCS) eligibility threshold from 225% to 300% of the federal poverty level starting October 2026, a significant expansion of a Medicaid-adjacent public coverage program for children. One of 8 named House cosponsors plus a Senate cosponsor.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2521p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elda Luna-Nájera (State House District 22) / abortion = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Cosponsor of HB2530 (2026), a substantial repeal bill removing Arizona's mandatory abortion waiting-period and ultrasound requirements and expanding which licensed providers (including nurse practitioners/midwives) may perform abortion procedures — directly reducing legal barriers to abortion access, unlike narrower reporting-only repeal bills. Matches the 'keep abortion legal and accessible...with rare exceptions' chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2530p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elda Luna-Nájera (State House District 22) / taxes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Cosponsor of HB2636 (2026), which repeals Arizona's flat 2.5% individual income tax and creates a new top bracket taxing income over $1,000,000 at 8% while leaving the rate for all other income at 2.5% — a substantial, wealth-targeted tax increase requiring a legislative supermajority to enact. One of 14 named House cosponsors on Sandoval's bill.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2636p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elda Luna-Nájera (State House District 22) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8d470040-0f53-4881-8b58-5e9563a85f94', ct.id, $ctx$Cosponsor of HB2682 (2026), a bipartisan bill appropriating $5,000,000 to a new DES-administered emergency rental assistance program for tenants with children facing a temporary financial emergency, paid directly to landlords and barring eviction for rent covered by the assistance. Matches the 'targeted help like subsidies for affordable projects' chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2682p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lupe Contreras (State House District 22) / immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, $ctx$Cosponsor of HB2465 (2026, Sandoval prime), which bars state licensing agencies from requiring proof of citizenship or alien status for professional/business licenses and requires acceptance of a federal tax ID in lieu of an SSN — letting residents access a public licensing service regardless of legal status. Matches 'let most residents use public services regardless of legal status.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2465p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2301']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lupe Contreras (State House District 22) / civil-rights = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, $ctx$Cosponsor of HB2931 (2026, Rep. Travers prime), which repeals the sunset date on Arizona's Civil Rights Advisory Board so it continues its existing hearings/investigations function through 2034 rather than terminating — maintaining rather than expanding civil-rights enforcement. Matches 'maintain current civil rights laws while promoting equal opportunity.'$ctx$,
       ARRAY['https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2301']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lupe Contreras (State House District 22) / taxes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'd5466317-d90a-41ce-ba20-30c12429dcb3', ct.id, $ctx$Cosponsor of HB2636 (2026, Sandoval prime), which repeals Arizona's flat 2.5% income tax and creates a new 8% top bracket on income over $1,000,000, leaving the rate on all other income unchanged — a substantial, wealth-targeted tax increase. One of 14 named House cosponsors.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2636p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mariana Sandoval (State House District 23) / immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, $ctx$Prime sponsor of HB2465 (2026), which bars state licensing agencies from requiring proof of citizenship/alien status for professional and business licenses and requires acceptance of a federal tax ID in place of a Social Security number. Matches 'let most residents use public services regardless of legal status.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2465p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2334']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mariana Sandoval (State House District 23) / local-immigration = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, $ctx$Prime sponsor of both HB2880 (2026, 'Immigration Safe Zones' style courthouse/hospital protections — privileges people attending court from civil/immigration arrest and requires hospitals to adopt policies verifying and limiting ICE agents' facility access) and HB2881 (directs the Attorney General to establish policies that 'limit assistance with immigration enforcement' at schools, hospitals, courts, and libraries, and strips citizenship-status questions from certain state applications). Both bills restrict state/local government cooperation with and access for federal immigration enforcement, closest to the most restrictive chair.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2880p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2881p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mariana Sandoval (State House District 23) / taxes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee', ct.id, $ctx$Prime sponsor of HB2636 (2026), which repeals Arizona's flat 2.5% individual income tax rate and creates a new top bracket taxing income over $1,000,000 at 8%, leaving the 2.5% rate for all other income unchanged — a substantial, wealth-targeted tax increase requiring a legislative supermajority to enact.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2636p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Peña (State House District 23) / school-vouchers = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, $ctx$Sole prime sponsor of HB4037 (2026), which creates a new 'education opportunity' income-tax credit (up to $2,000/child at 80% of the base support level) for families whose children are not enrolled in public school and not using an Empowerment Scholarship Account, with no income means-test and only a $15M aggregate program cap — a new state-funded avenue for private/home education funding open broadly to families. Matches 'expanding voucher eligibility to most families.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4037p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2331']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Peña (State House District 23) / civil-rights = 5 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, 5.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, $ctx$Named cosponsor of HCR2044 (2026), a proposed constitutional amendment barring the state from granting 'preferential treatment' or engaging in race-based diversity/equity practices in public employment, education, or contracting, and restricting DEI-related training/programming. Matches 'eliminate affirmative action and all race-based government programs.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hcr2044p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'civil-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michele Peña (State House District 23) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '81b3d4cc-c502-4fbc-bd75-97773c39b2f5', ct.id, $ctx$Cosponsor of HB2682 (2026, bipartisan, Rep. Hernandez A prime), which appropriates $5,000,000 for a new DES emergency rental-assistance program for tenants with children facing a temporary financial emergency, paid directly to landlords with an eviction bar for covered months. Matches 'targeted help like subsidies for affordable projects.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2682p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anna Abeytia (State House District 24) / school-vouchers = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, $ctx$Sole prime sponsor of HB4132 (2026), which imposes a new $200,000 family-income cap (adjusted for inflation) on NEW Empowerment Scholarship Account (ESA) enrollees starting July 2027, tightening Arizona's previously income-uncapped universal ESA program with a means test for future applicants. Matches 'means-tested voucher programs with accountability requirements.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4132p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2366']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anna Abeytia (State House District 24) / immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, $ctx$Cosponsor of HB2465 (2026, Sandoval prime), which bars state licensing agencies from requiring proof of citizenship/alien status for professional and business licenses. Matches 'let most residents use public services regardless of legal status.' One of roughly 18 named cosponsors, a weaker individual signal but a clean single-purpose bill.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2465p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Anna Abeytia (State House District 24) / taxes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '1d2e925a-299f-4504-a4de-815d7a2ee7a6', ct.id, $ctx$Cosponsor of HB2636 (2026, Sandoval prime), which repeals Arizona's flat 2.5% income tax and creates a new 8% top bracket on income over $1,000,000. One of 14 named House cosponsors on a substantial, wealth-targeted tax increase.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2636p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'taxes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia Hernandez (State House District 24) / local-immigration = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, $ctx$Sole prime sponsor of HB4111 (2026), which requires every U.S. Immigration and Customs Enforcement officer operating in Arizona to wear and activate a body-worn camera during public contact, register their name/badge number with DPS, and bars ICE from detaining anyone solely based on perceived race, ethnicity, or national origin — a restrictive, accountability-focused posture toward federal immigration enforcement, the closest available chair on this scale.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4111p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2314']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'local-immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia Hernandez (State House District 24) / immigration = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, $ctx$Prime sponsor (with Rep. Tsosie) of HB2867 (2026), which adds a new statute clarifying that possession of an Arizona driver license, instruction permit, or nonoperating ID is 'not proof of citizenship' and allows applicants without a Social Security number to still obtain a license marked 'federal limitations apply' — extending a core public service (driving privileges) to residents regardless of immigration status. Matches 'let most residents use public services regardless of legal status.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2867p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'immigration'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia Hernandez (State House District 24) / school-vouchers = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, $ctx$Sole prime sponsor of HB4113 (2026), which adds new independent-evaluation-team, audit, and transparency-portal reporting requirements to Arizona's Empowerment Scholarship Account program without changing income eligibility — an accountability-focused rather than eligibility-expanding ESA bill. Matches 'means-tested voucher programs with accountability requirements' in its accountability emphasis.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4113p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia Hernandez (State House District 24) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9', ct.id, $ctx$Cosponsor of HB2682 (2026, bipartisan, Rep. Hernandez A prime), which appropriates $5,000,000 for a new DES emergency rental-assistance program for tenants with children facing a temporary financial emergency, paid directly to landlords with an eviction bar for covered months. Matches 'targeted help like subsidies for affordable projects.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2682p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

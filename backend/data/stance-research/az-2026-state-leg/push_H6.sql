-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H6 (12 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H6.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Chris Lopez (State House District 16) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5dd72969-087b-4db0-b2b1-ee87a1ef11b9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5dd72969-087b-4db0-b2b1-ee87a1ef11b9', ct.id, $ctx$Prime sponsor of HB2942 (2026), which appropriates $12M general fund + $36M Medicaid expenditure authority annually through FY2030-2031 to raise DES reimbursement rates for rehabilitation group homes serving people with intellectual and developmental disabilities. This is a funding increase to strengthen an existing Medicaid-adjacent program rather than a restructuring or eligibility expansion, aligning with 'improve current programs while controlling costs.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2942p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2364']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Martinez (State House District 16) / religious-freedom = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'cacb84a8-4343-4919-a37c-dfcb6e050243', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'religious-freedom'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'cacb84a8-4343-4919-a37c-dfcb6e050243', ct.id, $ctx$Prime sponsor of HB2110 (2026), which requires the governing body of any public school, charter school, community college district, or public university in Arizona to allow a member to pray during a public meeting on request. This affirmatively legislates a right to religious practice within public educational institutions, consistent with protecting religious freedom in public settings.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2110p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2323']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'religious-freedom'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Martinez (State House District 16) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'cacb84a8-4343-4919-a37c-dfcb6e050243', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'cacb84a8-4343-4919-a37c-dfcb6e050243', ct.id, $ctx$Sole sponsor of HB2804 (2026), which creates a new $2M/year state tax credit (2026-2036) for developers of rural affordable housing projects that qualify for the federal Low-Income Housing Tax Credit, targeted at counties under 800,000 population. This is a targeted subsidy for affordable-housing projects, matching 'offer targeted help like subsidies for affordable projects.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2804p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2323']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Volk (State House District 17) / data-centers = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c72622ac-61d7-4e8b-83a8-565cfca045c0', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c72622ac-61d7-4e8b-83a8-565cfca045c0', ct.id, $ctx$Prime sponsor of HB2949 (2026, with 23 Democratic cosponsors), which requires large data centers (100+ MW peak demand) to pay their own energy, generation, and transmission costs and expressly bars public power entities/utilities from passing those costs on to other customers. This is a near-exact match to 'requiring data centers to fund their own...costs and barring utilities from passing data center infrastructure costs to residential customers.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2949p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2365']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kevin Volk (State House District 17) / school-vouchers = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'c72622ac-61d7-4e8b-83a8-565cfca045c0', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'c72622ac-61d7-4e8b-83a8-565cfca045c0', ct.id, $ctx$Sole sponsor of HB4052, the 'Follow the Money Act' (2026), which requires the state to publish itemized lists of approved and disapproved ESA expenses, including prices, in its quarterly reports. This is a financial-transparency/accountability measure layered onto the existing ESA voucher program without touching funding levels or eligibility, closest to the 'accountability requirements' language for participating private schools/programs.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb4052p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2365']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rachel Keshel (State House District 17) / school-vouchers = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '6a1417b8-cdcd-43f2-a63d-533beaefc563', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '6a1417b8-cdcd-43f2-a63d-533beaefc563', ct.id, $ctx$Sole sponsor of HB2832 (2026), which repeals the existing prohibition on a student receiving a School Tuition Organization (STO) scholarship concurrently with an Arizona Empowerment Scholarship Account (ESA) in the same year, expanding the aid families can combine under the voucher/ESA system. This moves in the direction of expanding voucher program generosity/access for participating families.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2832p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2317']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Mathis (State House District 18) / climate-change = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, $ctx$Sole sponsor of HB2551 (2026), creating a governor's Office of Resiliency to address climate-change threats to water/natural resources and requiring electric utilities to generate at least 50% of electricity from renewable sources by 2035, and sole sponsor of HB2535 (2026), which mandates Arizona adopt California's (CARB) vehicle emissions standards for 2028+ model-year vehicles once EPA grants a waiver. Together these reflect a gradual clean-energy transition rather than an immediate ban or market-only approach, matching 'invest in clean energy while gradually reducing reliance on fossil fuels.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2551p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2535p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2322']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Mathis (State House District 18) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, $ctx$Sole sponsor of HB2542 (2026), which adds preventive dental care as a covered AHCCCS (Arizona's Medicaid program) benefit for adults, supplementing the existing emergency-dental/extraction benefit capped at $1,000/year. This is a modest benefit expansion within the current program structure, matching 'improve current programs while controlling costs' rather than a broad coverage overhaul.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2542p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2322']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Mathis (State House District 18) / data-centers = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a7675f41-2e50-413c-9864-8a64969f47f9', ct.id, $ctx$Cosponsor (of 23) on HB2949 (2026), Rep. Volk's bill requiring large data centers to fund their own energy/generation/transmission costs and barring utilities from passing those costs to other customers — matching 'requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2949p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2322']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy Gutierrez (State House District 18) / trans-athletes = 1 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, 1.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, $ctx$Prime sponsor of HB2392 (2026, with 12 Democratic cosponsors), which repeals ARS 15-120.02, Arizona's law requiring student athletes to compete on teams matching biological sex assigned at birth. A full repeal with no replacement restriction matches 'allow all transgender athletes to compete on teams matching their gender identity without any restrictions.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2392p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2310']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'trans-athletes'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy Gutierrez (State House District 18) / school-vouchers = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, $ctx$Prime sponsor of HB2577 (2026, with 10 Democratic cosponsors including Volk), which requires every ESA-participating qualified school and nonpublic online learning program to administer the same statewide standardized assessment used by public schools to its ESA students. This adds an accountability/testing standard for participating private schools without touching funding or eligibility, matching 'allowing...voucher programs with accountability requirements for participating private schools.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2577p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2310']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'school-vouchers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nancy Gutierrez (State House District 18) / data-centers = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'ce872623-f6bd-4e90-9eba-239ed00c7491', ct.id, $ctx$Cosponsor (of 23) on HB2949 (2026), Rep. Volk's bill requiring large data centers to fund their own energy/generation/transmission costs and barring utilities from passing those costs to other customers — matching 'requiring data centers to fund their own dedicated power generation and barring utilities from passing data center infrastructure costs to residential customers.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2949p.pdf', 'https://www.azleg.gov/House/House-member/?legislature=57&session=130&legislator=2310']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'data-centers'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

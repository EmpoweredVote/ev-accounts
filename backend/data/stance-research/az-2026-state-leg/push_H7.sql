-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H7 (7 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H7.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Gail Griffin (State House District 19) / climate-change = 4 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '188c386e-087b-4587-9510-da7fc5805575', ct.id, 4.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '188c386e-087b-4587-9510-da7fc5805575', ct.id, $ctx$Chairs House Natural Resources, Energy & Water and was lead sponsor of HCR2050 (2024), a proposed constitutional amendment barring state or local governments from restricting the manufacture, sale, or use of devices (gas stoves, lawn equipment, etc.) based on energy source, which would block cities from banning fossil-fuel appliances. She defended it as a consumer-choice measure rather than a mandated clean-energy transition, matching stance 4's 'let market forces drive any transition to cleaner energy sources.'$ctx$,
       ARRAY['https://azmirror.com/2024/03/26/arizona-republicans-could-ask-voters-to-enshrine-the-right-to-a-gas-stove-in-the-constitution/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Betty J Villegas (State House District 20) / housing = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '6dcc0e46-c944-480b-a432-7b36989d56e9', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '6dcc0e46-c944-480b-a432-7b36989d56e9', ct.id, $ctx$Prime sponsor of a 2026 housing-reform package: HB2718 caps annual rent increases at the CPI plus 3% (max 7% total annual increase), with the Arizona Department of Housing enforcing violations as an unlawful trade practice — a direct rent-cap/rent-stabilization measure; HB2710 creates 'just cause' eviction protections for tenants of 12+ months, limiting terminations to nonpayment, material lease breach, or owner-occupancy (with mandatory relocation assistance); HB2962 bars landlords statewide from refusing tenants based on Section 8 or other voucher income, with Attorney General enforcement. Together these show active use of state regulation of the rental market to protect tenants, matching stance 2's use of rent caps and regulatory intervention to address affordability.$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2718p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2710p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2962p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Consuelo Hernandez (State House District 21) / medicare/aid = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5e9c9ca6-5267-4d01-b19d-a7da775d89d9', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5e9c9ca6-5267-4d01-b19d-a7da775d89d9', ct.id, $ctx$Prime sponsor of HB2958 (2026), which adds comprehensive dental care coverage (previously capped at $1,000/year for emergency extractions only) for AHCCCS (Arizona Medicaid)-enrolled pregnant women at any stage of pregnancy, funded by a $500,000 state general-fund appropriation plus federal Medicaid match. This is a targeted benefit improvement to an existing program for one population rather than a broad structural expansion of eligibility, matching stance 3's 'improve current programs while controlling costs' rather than stance 2's 'expand Medicaid significantly.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2958p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'medicare/aid'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Consuelo Hernandez (State House District 21) / judicial-government-deference = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5e9c9ca6-5267-4d01-b19d-a7da775d89d9', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'judicial-government-deference'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5e9c9ca6-5267-4d01-b19d-a7da775d89d9', ct.id, $ctx$Prime sponsor of HB2922 (2026), which amends Arizona's obstruction-of-criminal-investigations statute to explicitly exempt a homeowner who 'refuses to open a door to the property for a peace officer' from criminal liability. This affirmatively protects a resident's right to decline voluntary/warrantless entry without facing prosecution, siding with the citizen absent independently established government legal authority, matching stance 2's 'the citizen usually — unless the government has clear legal authority on its side.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2922p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'judicial-government-deference'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Stahl Hamilton (State House District 21) / voting-rights = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, $ctx$Prime sponsor of HB2505 (2026), which requires early voting locations (including county recorder offices) to stay open through the weekend before Election Day — until 7pm Saturday and Sunday, and at least 3pm Monday — while removing the prior 'emergency balloting' procedure that required voters to sign a sworn statement to vote during that window. The effect is to make weekend, pre-Election-Day in-person early voting available to all voters by default rather than only those claiming an emergency, matching stance 2's 'expand early voting periods... available to all voters without requiring an excuse.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2505p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'voting-rights'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Stahl Hamilton (State House District 21) / abortion = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, $ctx$Prime sponsor of HB2526 (2026, repeals ARS 36-2160, which restricted mailing of abortion medication) and HB2527 (2026, repeals ARS 36-3604, which prohibited telemedicine abortion consultations), both cosponsored with a bloc of Democratic representatives and two senators. Both bills remove legal barriers to obtaining abortion care via mail-order medication and telehealth, directly expanding practical legal access without stated evidence on public funding or a specific gestational-limit framework, matching stance 2's 'keep abortion legal and accessible.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2526p.pdf', 'https://www.azleg.gov/legtext/57leg/2R/bills/hb2527p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephanie Stahl Hamilton (State House District 21) / healthcare = 2 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, 2.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '2405145c-f082-47f2-861d-d4efd19e8162', ct.id, $ctx$Prime sponsor of HB2520 (2026), 'contraception; cost sharing prohibition,' which amends Arizona's health insurance code (Title 20) to add a new section barring cost-sharing for contraception coverage across regulated insurance contracts. This is a private-insurance coverage mandate applied broadly rather than means-tested to low-income enrollees, matching stance 2's 'affordable coverage through a mix of public programs and regulated private insurance.'$ctx$,
       ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/hb2520p.pdf']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'healthcare'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

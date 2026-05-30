-- Migration 139: McKinney TX city council Local Lens compass stances
-- Researched 2026-05-11
-- Politicians: Bill Cox (Mayor), Ernest Lynch (At-Large 1), Michael Jones (At-Large 2),
--              Justin Beller (District 1), Patrick Cloutier (District 2),
--              Geré Feltus (District 3), Rick Franklin (District 4)

BEGIN;

-- ============================================================
-- BILL COX — Mayor
-- ID: 1c31b159-d4c1-4756-ba81-a247dbf0af8f
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Cox opened McKinney's first Affordable Housing Summit (April 2026) with remarks on
-- workforce housing as an economic development priority. As P&Z chair he oversaw targeted
-- zoning approvals for mixed-use developments. Aligns with value 3: targeted subsidies,
-- first-time buyer assistance, easier building permits.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from public statements: Cox opened McKinney''s first Affordable Housing Summit (April 2026) emphasizing workforce housing as an economic development priority, saying the challenge is to "put action behind words" on affordable housing. As P&Z Commission chair he oversaw targeted zoning approvals for mixed-use developments. This aligns with answer 3 (targeted subsidies and easier permits) rather than large public programs or pure market reliance.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/nonprofit/2026/04/14/mckinney-front-porch-hosts-first-affordable-housing-summit/',
        'https://www.ntxe-news.com/artman/publish/article_145082.shtml',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/07/16/get-to-know-mckinneys-new-mayor-bill-cox/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No specific vote record found (Cox took office June 2025; Oct 2025 camping ordinance
-- vote breakdown shows 5-2 and 6-1 but individual Cox vote not confirmed in sources).
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Bill Cox''s specific vote on Oct 2025 camping/sleeping ordinances. Checked: communityimpact.com, cbsnews.com/texas, wfaa.com, keranews.org, tx3dnews.com. Cox joined council June 2025 as Mayor and would have presided over the Oct 21 vote but individual vote not confirmed in sources.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Cox stated his challenge is "working with developers to ensure the fabric of McKinney is kept
-- intact while continuing to develop." He chaired P&Z which approved mixed-use projects.
-- Aligns with value 3: allow multifamily near commercial corridors while protecting residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from public statements: Cox said his challenge will be "working with developers to ensure the fabric of McKinney is kept intact." He chaired the P&Z Commission which approved mixed-use and multifamily near commercial corridors while referencing state-law changes as the primary driver of density increases. This matches answer 3 (allow multifamily near commercial corridors while protecting most residential zones).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/07/16/get-to-know-mckinneys-new-mayor-bill-cox/',
        'https://www.keranews.org/news/2025-03-25/four-candidates-are-vying-for-mayor-of-mckinney-heres-what-to-know'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, coxformayor.com, communityimpact.com, keranews.org. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Cox campaign/governance: "making people feel safe and secure" as top goal; McKinney
-- approved 5 new police positions and 7.8% police budget increase (FY2025-26) under Cox.
-- Aligns with value 4: increase police staffing and pay to improve response times.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from governance: Cox stated his top goal is making people "feel safe and secure." The FY2025-26 McKinney budget approved under his leadership added 5 new police positions, increased police budget 7.8% to $47.45M, with public safety accounting for ~47% of general fund. This aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/09/03/mckinney-council-approves-942m-budget-lower-tax-rate-for-fy-2025-26/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/07/16/get-to-know-mckinneys-new-mayor-bill-cox/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, coxformayor.com, communityimpact.com, keranews.org, wfaa.com. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Cox is a commercial real estate principal. Supports using TIRZ/Chapter 380 incentives to
-- attract commercial development ("continue to expand commercial tax base"). Has attended
-- McKinney EDC forums. Aligns with value 4: compete actively for major employers with
-- tax abatements and infrastructure investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from public statements: Cox said McKinney needs to "expand that commercial tax base with companies that fit within what McKinney is" and has championed the city''s use of TIRZ districts and Chapter 380 economic incentives as part of its development strategy. As a commercial real estate professional and P&Z chair, he actively supports competing for businesses through targeted incentives. Aligns with answer 4 (compete actively for major employers with significant tax abatements).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/07/16/get-to-know-mckinneys-new-mayor-bill-cox/',
        'https://www.keranews.org/news/2025-03-25/four-candidates-are-vying-for-mayor-of-mckinney-heres-what-to-know'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Cox supports expanding road capacity (airport expansion, commercial road expansion).
-- Stated goal of giving people "options" for quality of life; road investment focus.
-- Aligns with value 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1c31b159-d4c1-4756-ba81-a247dbf0af8f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from public statements: Cox won the 2025 mayor race explicitly supporting the city''s airport expansion plan. He emphasized road and commercial corridor development as key to McKinney''s future. McKinney''s legislative priorities under his leadership focus on road capacity improvements (US 380 bypass, thoroughfare expansions). Aligns with answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://www.keranews.org/news/2025-06-07/mckinney-voters-appear-to-elect-new-mayor-who-supports-the-citys-airport-expansion',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/07/16/get-to-know-mckinneys-new-mayor-bill-cox/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- ERNEST LYNCH — Council At-Large Place 1
-- ID: c3e2d7a6-8096-4e91-9ee0-3cca445af72e
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Lynch stated he plans to focus on "expanding affordable housing" to accommodate growth.
-- Former EDC chairman — favors targeted programs over direct public housing.
-- Aligns with value 3: targeted subsidies and first-time buyer assistance.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Lynch identified rapid growth straining housing as McKinney''s biggest challenge and stated he plans to focus on "improving infrastructure, expanding affordable housing, and public services." His background as chairman of the McKinney EDC and Chamber of Commerce indicates a preference for public-private partnership programs over direct public housing. Aligns with answer 3 (targeted subsidies, first-time buyer assistance, easier building permits).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/03/06/qa-meet-the-candidates-for-mckinney-city-councils-at-large-1-seat/',
        'https://ballotpedia.org/Ernest_Lynch_(McKinney_City_Council_At-large_Position_1,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Not found. Lynch just took office June 2025; no vote record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Lynch took office June 2025. Checked: ballotpedia.org, communityimpact.com, legistorm.com. No specific statements or votes on homelessness criminalization found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- No specific statements on zoning philosophy found. Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, legistorm.com, lynchformckinney.com. No specific statements on zoning philosophy or zoning votes found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, legistorm.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Lynch was endorsed by McKinney Police and Fire Associations. Top priorities include
-- "supporting first responders." Former Medical City CEO who partnered with first responders.
-- Aligns with value 4: increase police staffing and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Lynch listed "supporting first responders" as a top priority, was endorsed by the McKinney Police and Fire Associations, and said he would support "public safety with the resources and competitive pay needed to keep families safe." This aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://ballotpedia.org/Ernest_Lynch_(McKinney_City_Council_At-large_Position_1,_Texas,_candidate_2025)',
        'https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/03/06/qa-meet-the-candidates-for-mckinney-city-councils-at-large-1-seat/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, legistorm.com. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Lynch chaired McKinney EDC and McKinney Chamber of Commerce. Top priorities include
-- "driving economic growth" through business attraction. Aligns with value 4: compete
-- actively for major employers with tax abatements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background and statements: Lynch served as Chairman of the McKinney Economic Development Corporation and McKinney Chamber of Commerce. He lists "driving economic growth" as a top priority and states "a strong local economy starts with policies that support businesses of all sizes," including attracting employers. This aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://ballotpedia.org/Ernest_Lynch_(McKinney_City_Council_At-large_Position_1,_Texas,_candidate_2025)',
        'https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/06/07/ernest-lynch-secures-at-large-1-seat-in-mckinney-city-council-runoff-race/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Lynch mentioned working with city to expand services for "efficient management of traffic
-- flow" on US 380; no transit/bike specifics found. General road-focused approach.
-- Not enough for a placement — not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — insufficient evidence for placement. Lynch briefly mentioned managing traffic flow on US 380 as a concern during his campaign, but no specific policy position on road vs. transit priorities was found. Checked: ballotpedia.org, communityimpact.com, keranews.org.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/03/06/qa-meet-the-candidates-for-mckinney-city-councils-at-large-1-seat/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- MICHAEL JONES — Council At-Large Place 2
-- ID: 09dbafc2-9252-40e4-9a1c-afda5b069f2e
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Jones voted YES on 4-3 affordable housing partnership (MHA, April 2024).
-- Also supported local housing voucher program (May 2024).
-- Aligns with value 3: targeted subsidies and support programs.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Council vote: Jones voted YES in the 4-3 council vote (April 2024) approving an affordable housing partnership with the McKinney Housing Authority. He also supported the May 2024 local housing voucher program. These votes indicate support for targeted public programs and subsidies for affordable housing. Aligns with answer 3 (targeted help like subsidies, first-time buyer assistance, and easier building permits).',
  ARRAY['https://starlocalmedia.com/mckinneycouriergazette/news/mckinney-council-narrowly-approves-affordable-housing-partnership/article_aacf6833-1213-4892-bb0c-0febfd4bea1f.html',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2024/05/24/mckinney-officials-establish-local-housing-voucher-program/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Jones voted NO on the Oct 2025 camping ordinance (5-2 vote), saying he agreed with
-- keeping public areas safe but cautioned against "selective enforcement."
-- Aligns with value 3: enforcement only when adequate shelter available, divert to services.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Council vote: Jones voted NO on the Oct 21, 2025 camping/sleeping ordinance (5-2 vote). He said he agreed with the intent to keep public areas safe but cautioned against "selective enforcement." This reflects a middle position: not fully criminalizing public sleeping but also not opposed to enforcement — contingent on fair application and service availability. Aligns with answer 3 (enforcement only when adequate shelter available, citations diverting people to services).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- No specific vote or statement on zoning philosophy found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, michaelhjones.com. No specific votes or statements on residential zoning philosophy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, michaelhjones.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Jones listed "public safety" as a priority and supports first responders.
-- Formerly chaired McKinney EDC; pro-police funding in general.
-- Aligns with value 4: increase police staffing and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign priorities: Jones listed improving "public safety" as a top priority. He supported McKinney''s ongoing public safety budget expansions. His caution about selective enforcement in homelessness cases suggests openness to community-oriented policing but no evidence of supporting budget reductions. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/city-county/2023/06/12/qa-get-to-know-michael-jones-new-mckinney-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, michaelhjones.com. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Jones served as first African American Chairman of McKinney EDC board. Prioritizes
-- "welcoming businesses," attracting "companies with higher paying jobs," and economic development.
-- Aligns with value 4: compete actively for major employers with tax abatements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background: Jones is a Commercial Banking Director and served as Chairman of the McKinney Economic Development Corporation board. He explicitly committed to "welcoming businesses to move to McKinney, decreasing property tax rates and encouraging companies with higher paying jobs to join our community." This aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/city-county/2023/06/12/qa-get-to-know-michael-jones-new-mckinney-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Jones listed improving "transportation" as a priority. No transit/bike specifics.
-- Not enough for a specific placement — not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — insufficient evidence for placement. Jones listed transportation improvements as a priority but no specific position on road vs. transit/multimodal spending was found. Checked: ballotpedia.org, communityimpact.com, michaelhjones.com.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/city-county/2023/06/12/qa-get-to-know-michael-jones-new-mckinney-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- JUSTIN BELLER — Council District 1
-- ID: bcdbeae4-04c9-4ea1-8942-bac3ce1a8723
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Beller served 6 years on McKinney Housing Authority. Voted YES (4-3) on affordable housing
-- partnership. Championed local housing voucher program. Called housing gap "so profoundly
-- difficult to address." Strong advocate for targeted programs.
-- Aligns with value 3: targeted subsidies, vouchers, and easier building permits.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Council vote + statements: Beller served 6 years on the McKinney Housing Authority board and voted YES in the 4-3 council vote approving an affordable housing partnership (April 2024). He championed the 2024 local housing voucher program, saying it supplements "the lack of Housing Choice Vouchers." He said McKinney needs housing "for everybody" including renters, first-time buyers, and retirees. Consistent with answer 3 (targeted subsidies, vouchers, and easier building permits).',
  ARRAY['https://starlocalmedia.com/mckinneycouriergazette/news/mckinney-council-narrowly-approves-affordable-housing-partnership/article_aacf6833-1213-4892-bb0c-0febfd4bea1f.html',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2024/05/24/mckinney-officials-establish-local-housing-voucher-program/',
        'https://starlocalmedia.com/mckinneycouriergazette/news/mckinney-official-advocates-for-affordable-housing-solutions/article_e0b798a0-71a4-44c1-bcaa-a6d2995d39f0.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Beller voted NO on both camping ordinances (6-1 and 5-2 in Oct 2025), the lone dissenter
-- on the first ordinance. He voiced concern about displacing people without clear alternatives.
-- Aligns with value 2: decriminalize public sleeping while investing in shelter and outreach.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Council vote: Beller was the sole dissenting vote (6-1) on the first McKinney camping/sleeping ordinance and voted NO again (5-2) on the second ordinance in Oct 2025. He expressed concern about displacing people without providing clear alternatives, indicating preference for shelter and outreach investment over criminalization. Aligns with answer 2 (decriminalizing public sleeping while investing in shelter capacity and voluntary service connections).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/',
        'https://www.cbsnews.com/texas/news/mckinney-passes-controversial-homelessness-ordinances-amid-public-pushback/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Beller advocates for balanced housing supply including affordable rentals, starter homes,
-- and redevelopment (east McKinney). No strong anti-multifamily statements.
-- Aligns with value 3: allow multifamily near commercial corridors while protecting most
-- residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from statements: Beller called affordable multifamily housing a "rare opportunity" to address McKinney''s housing shortage and advocated for a diverse supply including affordable rentals and starter homes. He supported redevelopment of east McKinney while wanting to inform and engage residents in the process. Consistent with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/',
        'https://starlocalmedia.com/mckinneycouriergazette/news/mckinney-official-advocates-for-affordable-housing-solutions/article_e0b798a0-71a4-44c1-bcaa-a6d2952d39f0.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, votebeller Facebook. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Beller acknowledged public safety concerns at Trinity Falls meeting and engaged police
-- chief on those issues. Supports police funding generally (McKinney budgets).
-- No evidence of preferring co-responders or budget redirection.
-- Aligns with value 4 (increase staffing) but note his willingness to consider alternative
-- approaches (homelessness vote). Place at 3: keep current funding while adding crisis response.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from pattern of votes and statements: Beller supported public safety generally and engaged with police chief on community concerns, but his two votes AGAINST homelessness criminalization ordinances (Oct 2025) show preference for service-based alternatives over pure enforcement. This balance — maintain police funding but add crisis response for non-violent situations — aligns with answer 3 (keep current public safety funding while adding crisis response teams).',
  ARRAY['https://tx3dnews.com/mckinney-approves-trinity-falls-despite-concerns/',
        'https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, votebeller Facebook. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Beller is a community banker; previously on 2017 bond committee. Supports responsible
-- development and economic growth. No anti-incentive statements found.
-- Aligns with value 3: targeted incentives with community benefit.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background: Beller is a community banker who served on the McKinney bond committee and supports responsible economic growth. His emphasis on ensuring development "benefits the people" and keeping residents informed suggests support for incentives with accountability and community benefit agreements rather than maximum corporate subsidies. Aligns with answer 3 (targeted incentives with community benefit agreements and job quality requirements).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Not found. Beller acknowledged traffic/infrastructure concerns from residents but no
-- specific modal priority found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcdbeae4-04c9-4ea1-8942-bac3ce1a8723', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — insufficient evidence for placement. Beller acknowledged traffic and infrastructure concerns raised by Trinity Falls residents but no specific position on road vs. transit/multimodal priorities was found. Checked: communityimpact.com, tx3dnews.com, votebeller Facebook.',
  ARRAY['https://tx3dnews.com/mckinney-approves-trinity-falls-despite-concerns/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- PATRICK CLOUTIER — Council District 2
-- ID: 27578980-2e6c-4639-879a-70b510566d0f
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Cloutier called an affordable multifamily housing project a "rare opportunity."
-- Said rising housing costs put people at risk of homelessness. Voted for housing voucher program.
-- Argued for MORE affordable housing in projects (wanted more than 10% dedicated units).
-- Aligns with value 3: targeted subsidies and programs.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Council votes + statements: Cloutier unanimously supported an affordable multifamily project (March 2023) calling it "a rare opportunity." He supported the 2024 housing voucher program, saying "These people might be homeless if it weren''t for this kind of program." He noted the "real gap" in affordable housing is at the lowest income levels and pushed for more dedicated affordable units in projects. Aligns with answer 3 (targeted subsidies, vouchers, and easier building permits).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/development/2023/03/08/new-affordable-multifamily-housing-project-gets-green-light-from-mckinney-officials/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2024/05/24/mckinney-officials-establish-local-housing-voucher-program/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/08/22/mckinney-council-approves-zoning-for-affordable-townhome-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Cloutier made the motion to pass both camping ordinances and voted YES.
-- Also noted Baby Boomer homelessness as a growing problem — aware of service gap.
-- Aligns with value 4: prohibit encampments with warnings and penalties, maintain basic shelter.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', '4938766b-b45a-46e3-93bd-b8b30651271a', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Council vote: Cloutier made the motion to pass both McKinney camping/sleeping ordinances (Oct 2025) and voted YES on both. He acknowledged the service gap, noting "the fastest growing homeless population in the United States is people who are Baby Boomers," but still moved to enforce prohibitions. The ordinances included sunset clauses (expire Oct 2026) and graduated enforcement. Aligns with answer 4 (prohibiting encampments with graduated warnings and penalties, while requiring basic shelter options).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/08/22/mckinney-council-approves-zoning-for-affordable-townhome-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Cloutier served on Zoning Board of Adjustments. He stated "the state took away our ability
-- to restrict multifamily last year" — implying he would have restricted it otherwise.
-- Tabled the 785-acre Billingsley development to get more information.
-- Aligns with value 2: allow modest density increases with strong design review.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from statements and votes: Cloutier said "The state took away our ability to restrict multifamily last year," implying he preferred restricting multifamily zoning before state law changed. He made the motion to TABLE the 785-acre Billingsley development zoning case (May 2025, approved 5-1). He previously served on the Zoning Board of Adjustments. This pattern reflects preference for careful review and design controls rather than broad upzoning. Aligns with answer 2 (allow modest density increases with strong design review and neighborhood input).',
  ARRAY['https://tx3dnews.com/mckinney-approves-trinity-falls-despite-concerns/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/development/2025/05/08/mckinney-council-tables-zoning-case-for-785-acre-billingsley-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, patrickformckinney.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Cloutier served on McKinney Zoning Board and supports public safety funding.
-- No specific statements on police budget levels vs. social services found.
-- Aligns generally with value 4 given his enforcement-first stance on homelessness.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from voting pattern: Cloutier moved and voted for both camping/sleeping ordinances (Oct 2025) favoring a police-enforcement approach to public order. He supported McKinney''s ongoing police budget expansions. No evidence of supporting social service realignment of police funds. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, patrickformckinney.com. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Cloutier served on McKinney EDC board. Co-founder of Legacy Planning Group since 1998.
-- Supports competing for businesses; involved in east McKinney redevelopment.
-- Aligns with value 4: compete actively for major employers.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background: Cloutier served on the McKinney Economic Development Corporation board and identified housing shortage as also a "labor problem" — showing his economic development mindset. As co-founder of a financial advisory firm and former EDC board member, he is aligned with competing actively for businesses. Aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/people/2022/02/10/qa-with-mckinney-city-council-member-patrick-j-cloutier/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Cloutier said "traffic strains are hard in growing areas of the city" — road-focused.
-- No transit/bike specifics found.
-- Aligns with value 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27578980-2e6c-4639-879a-70b510566d0f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from statements: Cloutier noted that "traffic strains are hard in growing areas of the city" in discussions of new development. No statements supporting transit investment, bike infrastructure, or multimodal spending were found. His comments focus on managing vehicular traffic. Aligns with answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://tx3dnews.com/mckinney-approves-trinity-falls-despite-concerns/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- GERÉ FELTUS — Council District 3
-- ID: 23ba75d2-6eed-4b71-9669-78ab3bb82e98
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Feltus publicly stated at a groundbreaking that "addressing workforce housing is not just
-- charity, but economic vitality." She supported a $46M affordable housing project.
-- She balances housing supply concerns with preference for ownership.
-- Aligns with value 3: targeted subsidies and programs.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Council vote + statements: Feltus stated at a groundbreaking that "addressing the workforce housing issue in McKinney is not just a matter of charity, but one of economic vitality." She supported the $46M Palladium USA affordable housing project groundbreaking (2023) and listed workforce housing as a second-term priority. Aligns with answer 3 (targeted subsidies and programs for affordable projects, first-time buyer assistance).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/development/2023/10/02/palladium-usa-officials-break-ground-on-46m-affordable-housing-project-in-mckinney/',
        'https://ballotpedia.org/Gere_Feltus_(McKinney_City_Council_District_3,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Feltus voted NO on the second (citywide) camping ordinance (5-2) but the sources
-- do not confirm she voted NO on the first ordinance. Indicates some hesitation on
-- blanket criminalization while allowing limited enforcement in specific areas.
-- Aligns with value 3: enforcement only when adequate shelter available, divert to services.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Council vote: Feltus voted NO on the second McKinney camping ordinance (citywide ban, 5-2 vote, Oct 2025). One source also indicates she voted against the first downtown-specific ordinance. This pattern — voting against broad criminalization while not opposing all enforcement — suggests preference for service-based approaches before penalties. Aligns with answer 3 (allowing enforcement only when adequate shelter is available, with citations diverting people to services).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/',
        'https://www.cbsnews.com/texas/news/mckinney-passes-controversial-homelessness-ordinances-amid-public-pushback/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Feltus explicitly stated she was "hesitant to vote for rezoning property planned for
-- single-family development" and said "We're not short of multifamily in this area."
-- She prefers ownership housing (townhomes, smaller homes) over rental apartments.
-- Aligns with value 2: allow modest density (ownership types) with strong review.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Direct quotes: Feltus stated she was "hesitant to vote for rezoning property planned for single-family development" and would "rather see ownership developments like smaller homes or townhomes," adding "We''re not short of multifamily in this area." District 3 residents'' top concerns are "developing apartments the right way" and attainable housing. Aligns with answer 2 (allow modest density increases like duplexes and accessory units with strong design review and neighborhood input).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/28/mckinney-council-approves-zoning-for-11-acre-apartment-development/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, feltus4mckinney.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Feltus joined police chief advisory council. Served on Collin College Law Enforcement
-- Academy Advisory Board. Listed public safety as top priority for both terms.
-- Aligns with value 4: increase police staffing and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from background and priorities: Feltus served on the McKinney Police Chief''s advisory council and the Collin College Law Enforcement Academy Advisory Board. She listed public safety as her top campaign priority in both 2021 and 2025 elections. Despite voting against camping criminalization, she consistently supports police department funding. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/',
        'https://ballotpedia.org/Gere_Feltus_(McKinney_City_Council_District_3,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, feltus4mckinney.com. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Feltus served on McKinney EDC board. Lists "balancing the city''s tax base" as priority.
-- Supported workforce housing as economic vitality concern.
-- Aligns with value 3: targeted incentives with community benefit agreements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background: Feltus served on the McKinney EDC board and lists "balancing the city''s tax base" as a priority — suggesting she thinks carefully about what economic incentives yield for taxpayers. She connects workforce housing to economic vitality, indicating a community-benefit framing rather than maximum incentives for any employer. Aligns with answer 3 (targeted incentives with community benefit agreements and job quality requirements).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/',
        'https://ballotpedia.org/Gere_Feltus_(McKinney_City_Council_District_3,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Feltus expressed frustration: "the traffic on 380 is just horrific. It's getting worse,
-- and we're adding more development to it." Focused on road infrastructure and traffic flow.
-- Aligns with value 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23ba75d2-6eed-4b71-9669-78ab3bb82e98', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Direct quote: Feltus stated "the traffic on 380 is just horrific. It''s getting worse, and we''re adding more development to it," expressing frustration with road congestion and calling for infrastructure expansion to keep up with development. No statements in favor of transit or bike investments were found. Aligns with answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2021/07/08/meet-mckinneys-newest-city-council-members-justin-beller-and-gere-feltus/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- RICK FRANKLIN — Council District 4
-- ID: 6ee726c1-79af-4fef-abb8-fa7f4208ae14
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Franklin voted YES (4-3) on affordable housing partnership (MHA, April 2024).
-- Said the need for affordable housing is "more prevalent." Agreed $31M senior project
-- location is "perfect." Supported multiple affordable projects throughout tenure.
-- Aligns with value 3: targeted subsidies and programs.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Council votes + statements: Franklin voted YES in the 4-3 council vote (April 2024) approving an affordable housing partnership with the McKinney Housing Authority, saying the need for affordable housing in McKinney is "more prevalent." He called the location of a proposed $31M senior housing project "perfect" (Feb 2025) and voted for affordable workforce apartments receiving zoning approval (2019). Consistent with answer 3 (targeted subsidies and programs for affordable projects).',
  ARRAY['https://starlocalmedia.com/mckinneycouriergazette/news/mckinney-council-narrowly-approves-affordable-housing-partnership/article_aacf6833-1213-4892-bb0c-0febfd4bea1f.html',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/02/06/mckinney-leaders-lend-support-to-proposed-31m-affordable-senior-housing-project/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/2019/12/03/affordable-workforce-apartments-receive-zoning-approval-by-mckinney-city-council/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Franklin voted YES on camping ordinances (Oct 2025); no specific dissenting statement found.
-- Aligns with value 4: prohibit encampments with graduated warnings and penalties.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', '4938766b-b45a-46e3-93bd-b8b30651271a', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Council vote: Franklin voted YES on both McKinney camping/sleeping ordinances (Oct 2025). No statements expressing preference for service-based alternatives over enforcement were found. The ordinances include graduated enforcement and sunset clauses. Aligns with answer 4 (prohibiting encampments on public property with graduated warnings and penalties, while requiring jurisdictions to maintain basic shelter options).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Franklin as commercial real estate broker supports development; voted yes on zoning cases
-- for housing. His "last big tract of land" comment shows interest in managed development.
-- Aligns with value 3: allow multifamily near commercial corridors while protecting most
-- residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from background and statements: Franklin is a commercial real estate broker who has voted for multiple zoning approvals for housing development, including affordable workforce apartments (2019). He has described northwest McKinney''s last large tract as an opportunity for planned development with an 8-lane thoroughfare. He noted an 11-acre apartment development was one of the "worst ones" he''d seen for density — suggesting he supports development but with quality controls. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2024/10/16/new-municipal-management-district-proposed-for-northwest-mckinney/',
        'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/28/mckinney-council-approves-zoning-for-11-acre-apartment-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, vote-usa.org, franklinfordistrict4 Facebook. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Franklin served 6 years on McKinney EDC, supports city services.
-- Supports police budget. No evidence of preferring service reallocation.
-- Aligns with value 4: increase police staffing and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from voting pattern: Franklin voted YES on both camping ordinances (enforcement-focused) and supported McKinney''s public safety budget expansions. No statements supporting redirection of police funds to social services found. As a longtime McKinney resident since 1963 who ran on quality-of-life issues, he consistently supports robust public safety funding. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://tx3dnews.com/mckinney-passes-ban-public-sleeping-camping/',
        'https://vote-usa.org/Intro.aspx?State=TX&Id=TXFranklinRick'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, vote-usa.org. No statements or votes on ICE detainers or local immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Franklin served 6 years on McKinney EDC and McKinney Alliance Inc.
-- Supports competing for businesses; commercial real estate background.
-- Aligns with value 4: compete actively for major employers.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from background: Franklin served 6 years on the McKinney Economic Development Corporation board and McKinney Alliance Inc. As a commercial real estate broker with 35+ years of experience, he actively supports using tax incentives and economic development tools to attract businesses to McKinney. Aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://communityimpact.com/guides/dallas-fort-worth/mckinney/news/city-county/2019/03/12/qa-rick-franklin-running-for-mckinney-city-council-district-4-seat'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Franklin said he's NOT a proponent of widening US 380 due to economic impact but wants
-- alternative roads to improve congestion. Road-focused but pragmatic.
-- Aligns with value 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ee726c1-79af-4fef-abb8-fa7f4208ae14', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Direct quote: Franklin stated he is "not a proponent of widening the current US 380" due to its economic impact on the city but wants the city to "explore alternative options to expand additional roadways in McKinney to improve congestion and overall flow." His focus is entirely on vehicular traffic and road alternatives — no transit or bike references found. Aligns with answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://communityimpact.com/guides/dallas-fort-worth/mckinney/news/city-county/2019/03/12/qa-rick-franklin-running-for-mckinney-city-council-district-4-seat'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

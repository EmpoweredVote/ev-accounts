BEGIN;

-- PETE CAIN — Mayor
-- ID: d9710a3e-4679-44a5-8bfe-ddbb7b376ab5
-- Sources: annatexas.gov, collincounty.com/mayor-pete-cain, petecainformayor.com (inaccessible),
--          citizenportal.ai FY2026 budget article, ntxe-news.com community survey article

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-12 — no public record found on affordable housing policy. Mayor Cain''s public statements focus on managing rapid growth and preserving Anna''s community character; no statements found on rent caps, subsidies, public housing, or buyer assistance programs. Checked: annatexas.gov/1354/Pete-Cain, collincounty.com/mayor-pete-cain, petecainformayor.com, local news searches.',
  ARRAY['https://www.annatexas.gov/1354/Pete-Cain', 'https://www.collincounty.com/mayor-pete-cain'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-12 — no public record found. Homelessness has not surfaced as a policy issue in Anna city council records, campaign materials, or local news coverage. Anna is a fast-growing suburb with no documented encampment issue. Checked: annatexas.gov agendas/minutes, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-12 — no scorable public record found. Mayor Cain supports downtown mixed residential/commercial/entertainment development and managing growth while preserving community character. City has approved 3,000+ acres of planned residential/commercial development under his tenure. No specific statement found mapping to a particular answer description on density or zoning approach. Checked: annatexas.gov, collincounty.com/mayor-pete-cain, local news.',
  ARRAY['https://www.collincounty.com/mayor-pete-cain', 'https://www.annatexas.gov/1354/Pete-Cain'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-12 — no public record found. No statements on racial equity, civil rights enforcement, or affirmative action found in any reviewed sources. Checked: annatexas.gov, campaign materials, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-12 — no individually attributable scorable stance found. Cain stated he could not look at the budget and be willing to not have "a peace officer" (collincounty.com interview), expressing strong commitment to maintaining public safety staffing. The FY2026 budget unanimously adopted by council added 5 officers, 1 detective, 1 lieutenant, and funded a new police station — but this is a council-wide unanimous vote, not an individually attributed Cain-specific position. Language matches maintaining/increasing staffing (answers 4-5) but not attributable at description-match level to a specific answer. Checked: collincounty.com/mayor-pete-cain, citizenportal.ai FY2026 budget article.',
  ARRAY['https://www.collincounty.com/mayor-pete-cain', 'https://citizenportal.ai/articles/6499663/anna-adopts-297-million-fy2026-budget-and-raises-property-tax-rate-to-fund-police-station'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-12 — no scorable public record found. Cain served on Greater Anna Chamber of Commerce as board member and Chair, indicating business community involvement. City has active EDC/CDC with $8.4M in incentives granted and executed agreements (e.g., Chipotle 2024). No specific statement from Cain on incentive policy approach found. Checked: annatexas.gov, opportunityannatx.com, local news searches.',
  ARRAY['https://opportunityannatx.com/the-edc-cdc/', 'https://www.annatexas.gov/1133/Economic-Development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-12 — no scorable public record found. Anna''s 2025-2026 Work Plan includes road capacity expansions (Rosamond Parkway additional lanes, FM 455 widening co-op with county/TxDOT) and sidewalk improvements. No specific statement from Cain attributing his personal transportation philosophy to a particular answer description. Checked: annatexas.gov work plan, community improvement projects, local news.',
  ARRAY['https://annatexas.gov/DocumentCenter/View/9130/2025-2026-Work-Plan-Update', 'https://www.annatexas.gov/993/Community-Improvement-Program'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9710a3e-4679-44a5-8bfe-ddbb7b376ab5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-12 — no public record found. No statements on ICE cooperation, sanctuary policy, or immigration enforcement found in any reviewed sources. Checked: annatexas.gov, campaign materials, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- KEVIN TOTEN — Council Member Place 1
-- ID: 38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d
-- Sources: annatexas.gov/1072/Kevin-Toten, thefacesofannatx.com/kevin-toten (inaccessible),
--          legistorm.com, citizenportal.ai FY2026 budget article

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-12 — no public record found on affordable housing policy. Toten''s public profile focuses on utility/infrastructure concerns that drew him to public service and law enforcement support activities. No statements found on housing programs, subsidies, or rent policy. Checked: annatexas.gov/1072/Kevin-Toten, legistorm.com, local news searches.',
  ARRAY['https://www.annatexas.gov/1072/Kevin-Toten', 'https://www.legistorm.com/person/bio/508119/Kevin_Matthew_Toten.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-12 — no public record found. Homelessness has not surfaced as a policy issue in Anna city council records or in Toten''s public statements. Checked: annatexas.gov agendas/minutes, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-12 — no scorable public record found. Toten serves as P&Z Commission liaison, indicating zoning involvement, but no specific public statements on density, multifamily, or neighborhood character approach found at the answer-description level. Checked: annatexas.gov/1072/Kevin-Toten, P&Z meeting records, local news.',
  ARRAY['https://www.annatexas.gov/1072/Kevin-Toten', 'https://www.annatexas.gov/891/Planning-Zoning-Commission'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-12 — no public record found. No statements on racial equity, civil rights enforcement, or affirmative action found in any reviewed sources. Checked: annatexas.gov, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-12 — no individually attributable scorable stance found. Toten initiated "Light the Town Blue" as a community show of support for local law enforcement and organizes an annual First Responders Feast. The FY2026 budget (unanimously adopted) added 5 officers, 1 detective, 1 lieutenant, and funded a new police station with a property tax increase — a council-wide vote. Toten''s law enforcement community activities indicate strong public safety orientation, but no individual quote at a specific answer-description level (e.g., "increase police budget as top priority") was found. Checked: annatexas.gov/1072/Kevin-Toten, citizenportal.ai FY2026 budget.',
  ARRAY['https://www.annatexas.gov/1072/Kevin-Toten', 'https://citizenportal.ai/articles/6499663/anna-adopts-297-million-fy2026-budget-and-raises-property-tax-rate-to-fund-police-station'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-12 — no public record found on economic development incentive positions. Toten''s background is in fleet/utility work; no statements on business incentives found. Checked: annatexas.gov, local news searches.',
  ARRAY['https://www.annatexas.gov/1072/Kevin-Toten'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-12 — no scorable public record found. Toten''s interest in public service originated from waterline/utility issues in his neighborhood, not transportation. No specific statements on transportation funding priorities found. Checked: annatexas.gov, local news searches.',
  ARRAY['https://www.annatexas.gov/1072/Kevin-Toten'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('38ba3e31-8b1d-4038-9c5a-e5b16c06aa8d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-12 — no public record found. No statements on ICE cooperation, sanctuary policy, or immigration enforcement found in any reviewed sources. Checked: annatexas.gov, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- NATHAN BRYAN — Council Member Place 2
-- ID: 94d3e41c-60b6-4803-b937-1877aeae84df
-- Sources: annamatters.com (campaign website, partially inaccessible), annatexas.gov/1612/Nathan-Bryan,
--          theannaprogress.com election results 2025

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-12 — no public record found. Bryan supports diverse housing options and "smart growth" per campaign materials, but no specific statements on affordable housing programs, subsidies, rent policy, or buyer assistance found. Checked: annamatters.com, annatexas.gov/1612/Nathan-Bryan, local news searches.',
  ARRAY['https://www.annamatters.com/', 'https://www.annatexas.gov/1612/Nathan-Bryan'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-12 — no public record found. Homelessness has not surfaced as a policy issue in Anna city council records or Bryan''s campaign materials. Checked: annamatters.com, annatexas.gov agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-12 — no scorable public record found. Bryan''s campaign states support for diverse housing options (single-family and multifamily) and "smart growth" but does not specify a zoning approach (density by right, comp plan alignment, etc.) at the level of a specific answer description. His previous council tenure (2012-2020) included approving growth infrastructure. Checked: annamatters.com, annatexas.gov, local news.',
  ARRAY['https://www.annamatters.com/about-anna-city-council', 'https://www.annamatters.com/achievements-infrastructure-development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-12 — no public record found. No statements on racial equity, civil rights enforcement, or affirmative action found in any reviewed sources. Checked: annamatters.com, annatexas.gov, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-12 — no scorable public record found. Bryan''s campaign mentions public safety as a priority alongside infrastructure; the FY2026 budget unanimously adopted added police staffing and a new station, but this is a council-wide vote not individually attributed. No specific statements mapping to a particular answer description found. Checked: annamatters.com, citizenportal.ai FY2026 budget, local news.',
  ARRAY['https://www.annamatters.com/', 'https://citizenportal.ai/articles/6499663/anna-adopts-297-million-fy2026-budget-and-raises-property-tax-rate-to-fund-police-station'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-12 — no scorable public record found. Bryan''s campaign calls for "smart growth" and "attracting businesses that create jobs and opportunities" but does not specify a position on incentive types or levels matching a particular answer description. Checked: annamatters.com, annatexas.gov, local news searches.',
  ARRAY['https://www.annamatters.com/about-anna-city-council'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-12 — no scorable public record found. Bryan''s campaign emphasizes road improvements and expansions for traffic management as a core infrastructure priority, but does not specify a position on multimodal investment, transit, or bike infrastructure at the answer-description level. Checked: annamatters.com/achievements-infrastructure-development, local news.',
  ARRAY['https://www.annamatters.com/achievements-infrastructure-development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94d3e41c-60b6-4803-b937-1877aeae84df', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-12 — no public record found. No statements on ICE cooperation, sanctuary policy, or immigration enforcement found in any reviewed sources. Checked: annamatters.com, annatexas.gov, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- KELLY PATTERSON-HERNDON — Council Member Place 4
-- ID: 6a08be1a-2535-487c-a17c-f2f38263d504
-- Sources: kellyforannacitycouncil.com, annatexas.gov/1562/Kelly-Patterson-Herndon,
--          legistorm.com, thefacesofannatx.com (inaccessible)

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-12 — no scorable public record found. Patterson-Herndon supports diverse housing types (townhomes alongside single-family and multifamily) and homeless prevention services, but these are housing-type diversity and social service statements rather than positions on government affordability programs (subsidies, rent caps, public housing). No statement maps to a specific answer description. Checked: kellyforannacitycouncil.com, annatexas.gov/1562/Kelly-Patterson-Herndon, local news.',
  ARRAY['https://kellyforannacitycouncil.com/', 'https://www.annatexas.gov/1562/Kelly-Patterson-Herndon'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-12 — no scorable public record found. Patterson-Herndon mentions developing "homeless prevention and supportive services and programs to individuals and families at risk of homelessness" but this is a preventive housing approach, not a statement on enforcement or public-space camping policy. No answer description match found. Checked: kellyforannacitycouncil.com, annatexas.gov, local news.',
  ARRAY['https://kellyforannacitycouncil.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- As P&Z Commission Chair (2022-2024), she advocated for "more diverse housing options" specifically
-- mentioning townhomes as a gap between single-family and multifamily. She emphasizes "smart growth"
-- following the Anna 2050 comprehensive plan and revisiting it regularly. This matches Answer 2:
-- "Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'As former P&Z Commission Chair (2022–2024), Patterson-Herndon explicitly called for "more diverse housing options" beyond single-family and multifamily, specifically citing the lack of townhomes in Anna. She emphasizes "smart growth" following the Anna 2050 comprehensive plan with regular updates. This matches allowing modest density increases (townhomes/duplexes) with strong plan-based design review and community input (Answer 2). No evidence of support for broad upzoning or eliminating single-family zones. Source: kellyforannacitycouncil.com.',
  ARRAY['https://kellyforannacitycouncil.com/', 'https://www.annatexas.gov/1562/Kelly-Patterson-Herndon'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-12 — no scorable public record found. Patterson-Herndon emphasizes "transparency and inclusion," "diverse representation in decision-making," and "representing the female perspective" on kellyforannacitycouncil.com, but these are governance/representation statements rather than positions on racial equity programs, civil rights enforcement, or affirmative action. No answer description match found. Checked: kellyforannacitycouncil.com, annatexas.gov, local news.',
  ARRAY['https://kellyforannacitycouncil.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-12 — no scorable public record found. Patterson-Herndon lists "public safety" as a key priority in her five-year vision for Anna. The FY2026 budget (unanimously adopted) added police staffing and a new station, but this is a council-wide vote. No specific individual statement on police funding philosophy at the answer-description level found. Checked: kellyforannacitycouncil.com, citizenportal.ai FY2026 budget, local news.',
  ARRAY['https://kellyforannacitycouncil.com/', 'https://citizenportal.ai/articles/6499663/anna-adopts-297-million-fy2026-budget-and-raises-property-tax-rate-to-fund-police-station'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-12 — no scorable public record found. Patterson-Herndon supports "attract[ing] business and promot[ing] responsible development" with "economic diversification" per campaign website, but this phrasing does not map to a specific incentive approach (targeted vs. broad, community benefit agreements, etc.) at the answer-description level. Checked: kellyforannacitycouncil.com, annatexas.gov, local news.',
  ARRAY['https://kellyforannacitycouncil.com/', 'https://www.annatexas.gov/1133/Economic-Development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Campaign website: wants to "implement smart traffic management systems," "upgrade roads to accommodate
-- growing demand," AND "encourage mixed use development that prioritizes walkability." This is a combined
-- roads + walkability/pedestrian approach matching Answer 3: "Maintain roads while selectively adding
-- transit connections and pedestrian improvements where density supports it."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Patterson-Herndon''s campaign website explicitly calls for: (1) implementing smart traffic management systems for real-time adjustments, (2) upgrading roads to accommodate growing demand, AND (3) encouraging mixed-use development that prioritizes walkability to address traffic bottlenecks. This dual emphasis on road maintenance/capacity AND walkability/pedestrian-friendly development matches Answer 3 ("Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it"). Source: kellyforannacitycouncil.com.',
  ARRAY['https://kellyforannacitycouncil.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6a08be1a-2535-487c-a17c-f2f38263d504', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-12 — no public record found. No statements on ICE cooperation, sanctuary policy, or immigration enforcement found in any reviewed sources. Checked: kellyforannacitycouncil.com, annatexas.gov, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- MANNY SINGH — Council Member Place 6
-- ID: f920ca1a-8263-4662-aa21-1f5964dfa61d
-- Sources: annatexas.gov/1607/Manny-Singh, ballotpedia.org/Manny_Singh,
--          opportunityannatx.com (EDC board), local news searches

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-12 — no public record found. Singh''s campaign focuses on "smart, responsible growth" and protecting neighborhoods, but no specific statements on affordable housing programs, subsidies, or rent policy found. Checked: annatexas.gov/1607/Manny-Singh, ballotpedia.org, Facebook page, local news searches.',
  ARRAY['https://www.annatexas.gov/1607/Manny-Singh', 'https://ballotpedia.org/Manny_Singh_(Anna_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-12 — no public record found. Homelessness has not surfaced as a policy issue in Anna city council records or Singh''s campaign materials. Checked: annatexas.gov, ballotpedia.org, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-12 — no scorable public record found. Singh''s campaign calls for "smart, responsible growth—not unchecked development that puts profit over people" and "protect neighborhoods," which suggests caution on density, but these are general framing statements rather than a specific zoning position mapping to an answer description. Checked: annatexas.gov, ballotpedia.org, local news.',
  ARRAY['https://ballotpedia.org/Manny_Singh_(Anna_City_Council_Place_6,_Texas,_candidate_2025)', 'https://www.annatexas.gov/1607/Manny-Singh'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-12 — no public record found. No statements on racial equity, civil rights enforcement, or affirmative action found in any reviewed sources. Checked: annatexas.gov, ballotpedia.org, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-12 — no scorable public record found. Singh''s campaign mentions "stop crime, protect neighborhoods" and "bring jobs" but this is general safety rhetoric, not a specific position on police budget levels or staffing philosophy at the answer-description level. The FY2026 budget (unanimously adopted) added police staffing, but Singh only joined council in May 2025. No individual quote mapping to a specific answer found. Checked: annatexas.gov, ballotpedia.org, citizenportal.ai FY2026 budget, local news.',
  ARRAY['https://ballotpedia.org/Manny_Singh_(Anna_City_Council_Place_6,_Texas,_candidate_2025)', 'https://citizenportal.ai/articles/6499663/anna-adopts-297-million-fy2026-budget-and-raises-property-tax-rate-to-fund-police-station'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-12 — no scorable public record found. Singh served as EDC/CDC Vice President and his campaign calls for "bring[ing] jobs" and "smart, responsible growth." His EDC background indicates familiarity with incentive tools, but no specific public statement on incentive types, scale, or community benefit requirements found at the answer-description level. Checked: annatexas.gov, opportunityannatx.com, ballotpedia.org, local news.',
  ARRAY['https://www.annatexas.gov/1607/Manny-Singh', 'https://opportunityannatx.com/the-edc-cdc/', 'https://ballotpedia.org/Manny_Singh_(Anna_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-12 — no scorable public record found. Singh''s campaign mentions "build roads" as a priority but this is a single-phrase campaign slogan, not a developed transportation policy position. No specific statement on multimodal investment, transit, or parking policy found. Checked: annatexas.gov, ballotpedia.org, local news.',
  ARRAY['https://ballotpedia.org/Manny_Singh_(Anna_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f920ca1a-8263-4662-aa21-1f5964dfa61d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-12 — no public record found. No statements on ICE cooperation, sanctuary policy, or immigration enforcement found in any reviewed sources. Checked: annatexas.gov, ballotpedia.org, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

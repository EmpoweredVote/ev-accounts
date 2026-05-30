BEGIN;

-- ============================================================
-- RYAN TUBBS — Mayor
-- ID: cb9d6924-77d1-49c9-ab3d-778b0201e623
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- No public record found. Tubbs focuses on infrastructure, fiscal discipline, and growth management.
-- No statements found advocating for or against housing affordability programs.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: Community Impact Celina Q&A (2026-03-10), tubbs4celina.com, Celina Record starlocalmedia.com, celinaedc.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found. Celina is a fast-growing suburb with no documented homelessness policy debate.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina city council coverage. Checked: Community Impact, Celina Record, celina-tx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Tubbs supported the 417-acre annexation that included multifamily/mixed-use. City voted unanimously
-- to amend zoning ordinance in Feb 2026 in response to state SB 840 multifamily law (pre-emptive
-- protection of neighborhood character). Overall posture: manage growth, demand quality development,
-- protect small-town character — closest to answer 2 (modest density with design review/neighborhood input)
-- but without direct literal match. Not placing a stance; evidence is too indirect.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct stance found. Tubbs emphasizes "demand quality development" and maintaining small-town character. Supported 417-acre annexation with mixed-use zoning (2024). City council unanimously amended zoning code Feb 2026 to limit SB 840 multifamily expansion. Positions reflect growth management but no literal match to a specific answer. Checked: Community Impact Q&A 2026-03-10, Celina Record 2026, communityimpact.com.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/10/qa-meet-the-candidates-running-for-celina-mayor/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/02/17/celina-council-amends-zoning-ordinance-in-response-to-state-multifamily-housing-law/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found. No public statements on racial equity or civil rights policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, tubbs4celina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Tubbs explicitly states public safety as a core city priority: "we definitely pride ourselves on
-- public safety" with police/fire/public works accounting for majority of new hires. Approved FY2024-25
-- budget with increased public safety funding. Mentions police/fire keeping pace with growth.
-- Matches answer 4: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from Community Impact Q&A (2026): Tubbs states the city "prides itself on public safety" and that police/fire/public works account for the majority of new city staff hires. Approved FY2024-25 budget increasing police and fire department funding. Frames public safety readiness as keeping pace with growth.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/10/qa-meet-the-candidates-running-for-celina-mayor/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/12/30/best-of-2024-11-stories-from-celina-city-council/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Tubbs cast tie-breaking vote in favor of the EDC director appointment (May 2024), actively promotes
-- EDC and business attraction. Stated goal: "economic development that lowers the residential tax burden."
-- Celina EDC offers incentive packages for qualifying companies. Tubbs supports competing for businesses.
-- Matches answer 4: "Compete actively for major employers with significant tax abatements and infrastructure investment."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from Community Impact (2024-05-22): Tubbs cast tie-breaking vote to appoint new EDC director, stating "Celina is experiencing unprecedented growth, and...Anthony will help our small businesses thrive while fostering the growth of our commercial tax base." Actively supports Celina EDC incentive programs and competing for new businesses. Campaign states "economic development that lowers the residential tax burden."',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/10/qa-meet-the-candidates-running-for-celina-mayor/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Tubbs focuses on road capacity and traffic flow: TxDOT coordination, Sunset Boulevard extension,
-- Coit/Punk Carter Parkway improvements, a 400-space parking garage as part of downtown revitalization.
-- No mention of transit, bike infrastructure, or multimodal options. Closest to answer 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from Celina Record (2026-01) and Community Impact Q&A (2026-03): Tubbs focuses transportation priorities on road capacity — TxDOT coordination for Sunset Boulevard, Coit Road, and Punk Carter Parkway; a 400-space parking garage as part of downtown revitalization. No mention of bike/pedestrian infrastructure or transit. Consistent with answer 4 (road capacity and traffic flow).',
  ARRAY['https://starlocalmedia.com/celinarecord/news/celina-mayor-on-2026-growth-we-re-ready-when-they-are/article_f3a8ab6e-b90e-4335-b17f-ba1e9925ddd8.html', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/10/qa-meet-the-candidates-running-for-celina-mayor/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found. No public statements on immigration enforcement policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9d6924-77d1-49c9-ab3d-778b0201e623', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on local immigration enforcement policy found. Checked: Community Impact, Celina Record, tubbs4celina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- PHILIP FERGUSON — Council Member Place 1
-- ID: 7395cbed-4d2b-42f4-aeff-04b7427b0bc0
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Ferguson: "We MUST have affordable housing" — wait, that was Wigginton. Ferguson''s actual quote:
-- supports diverse housing types (townhomes, condos, multi-generational) but "vote[s] down multi-family
-- projects on a routine basis since we already have so much approved." Also wants to attract big box
-- retail to diversify budget away from developer fees. No explicit affordable housing program stance.
-- No literal match to any answer. Not placing.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found on housing affordability programs. Ferguson supports diverse housing types but routinely votes down multifamily. Focus is on budget diversification via retail sales tax rather than housing affordability. Checked: thebestofcelina.com/philip-ferguson, Community Impact Q&A 2025-03-19, Celina Record.',
  ARRAY['https://www.thebestofcelina.com/philip-ferguson', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2025/03/19/qa-meet-the-candidates-for-celina-city-council-place-1/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Ferguson explicitly stated he "vote[s] down multi-family projects on a routine basis since we already
-- have so much approved." Opposed the 417-acre annexation that included multifamily/apartments.
-- Supports diverse housing types (townhomes, condos) but strictly limits multifamily.
-- Uses "Neighborhood Vision Book" as development roadmap, wants to preserve neighborhood character.
-- Matches answer 1: "Protect existing neighborhood character strictly; require community votes before any rezoning."
-- Strong alignment: routine no votes on multifamily, community survey emphasis, Neighborhood Vision Book.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from thebestofcelina.com and Celina Record annexation coverage: Ferguson states "I vote down multi-family projects on a routine basis since we already have so much approved." Opposed the 417-acre annexation with apartments, citing water supply concerns ("it''s just irresponsible to continue to vote to keep adding more users to a finite resource"). Uses a "Neighborhood Vision Book" as a development roadmap and emphasizes listening to existing residents via annual surveys. Consistent with protecting existing neighborhood character strictly.',
  ARRAY['https://www.thebestofcelina.com/philip-ferguson', 'https://starlocalmedia.com/celinarecord/news/celina-expands-city-limits-by-417-acres-for-development/article_1d352bb7-18aa-4931-98de-544d1ee9d8dd.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Ferguson states he increased police budget 23% and fire 19% for 2025: "I don''t want to see CPD
-- in a constant state of ''catch up'' with public safety." Proactively supports police/fire resources.
-- Matches answer 4: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from thebestofcelina.com: Ferguson states police budget increased 23% and fire budget increased 19% for 2025. Direct quote: "I don''t want to see CPD in a constant state of ''catch up'' with public safety." Backs National Night Out community policing. Consistent with answer 4 (increase police staffing, equipment, and pay).',
  ARRAY['https://www.thebestofcelina.com/philip-ferguson'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Ferguson wants to diversify city budget away from developer fees toward retail sales tax.
-- Plans to attract big box retailers (Costco, Lowe''s, Home Depot, Walmart). Voted for EDC director
-- appointment. Supports using EDC for commercial tax base growth. Matches answer 4: "Compete actively
-- for major employers with significant tax abatements and infrastructure investment."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from thebestofcelina.com and Community Impact Q&A: Ferguson states "our city budget is far too dependent on fees from development" and plans to attract big box retailers (Costco, Lowe''s, Home Depot, Walmart) to generate sales tax. Voted for new EDC director appointment (May 2024). Supports EDC-driven commercial growth strategy. Consistent with answer 4 (compete actively for major employers).',
  ARRAY['https://www.thebestofcelina.com/philip-ferguson', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Ferguson mentions "more new roads, updating existing roads, installing traffic lights, improving
-- neighborhood drainage." Focus on road infrastructure for growth. No mention of transit or bike lanes.
-- Matches answer 4: "Focus on road capacity and traffic flow; transportation investment should serve the majority who drive."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from thebestofcelina.com: Ferguson''s transportation priorities include "more new roads, updating existing roads, installing traffic lights, improving neighborhood drainage." No mention of bike/pedestrian infrastructure or transit. Consistent with answer 4 (road capacity and traffic flow).',
  ARRAY['https://www.thebestofcelina.com/philip-ferguson'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7395cbed-4d2b-42f4-aeff-04b7427b0bc0', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- EDDIE CAWLFIELD — Council Member Place 2
-- ID: 780b7f22-755a-4a92-8bd3-78978edbc564
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Not found. Campaign focuses on small business, community character, infrastructure. No housing program stance.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Cawlfield''s campaign focuses on small business support, community character, and infrastructure. No statements on housing affordability programs. Checked: eddieforcelina.com, Community Impact 2024-05-13, Celina Record.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, eddieforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Cawlfield voted to support the 417-acre annexation with mixed-use/multifamily, stating the council''s
-- vote would have "no impact on water" and predicting the development would proceed regardless.
-- Proposes "smart growth strategies that prioritize thoughtful, sustainable initiatives" and supports
-- mixed-use development. Participated in unanimous Feb 2026 zoning code amendment.
-- Evidence points toward allowing density on corridors while noting market inevitability — closest to
-- answer 3 but no explicit zoning position. Not placing due to insufficient literal match.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct stance found. Cawlfield voted in favor of 417-acre annexation with multifamily/mixed-use, stating council vote would have "no impact on water." Campaign favors "smart growth strategies" and mixed-use development. No explicit zoning philosophy statement found. Checked: Celina Record annexation article, eddieforcelina.com, Community Impact.',
  ARRAY['https://starlocalmedia.com/celinarecord/news/celina-expands-city-limits-by-417-acres-for-development/article_1d352bb7-18aa-4931-98de-544d1ee9d8dd.html', 'https://eddieforcelina.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, eddieforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Cawlfield''s campaign pledges to work closely with law enforcement on proactive safety measures,
-- supports traffic management and crime prevention, and community policing programs. Backed public
-- safety campus plan and fire station No. 3 opening as part of council. No language about redirecting
-- funds or alternative response programs. Consistent with maintaining/increasing current public safety.
-- Matches answer 3 or 4. His language ("proactive safety measures," "community policing") is closer
-- to answer 3 (keep current funding while adding crisis response teams). However, no literal evidence
-- for crisis teams specifically. Not placing due to insufficient literal match.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no direct stance placed. Cawlfield campaign supports "proactive safety measures," community policing programs, and traffic management. As council member, supported public safety campus expansion. No statements on redirecting funds or alternative response models. Checked: eddieforcelina.com, Celina Record, Community Impact.',
  ARRAY['https://eddieforcelina.com/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/12/30/best-of-2024-11-stories-from-celina-city-council/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Cawlfield voted against the new EDC director appointment (May 2024), alongside Hopkins and Koehne.
-- Also proposed requiring all EDC board members to reapply. Campaign strongly emphasizes small business
-- support and "Be the City of Small Business." Describes small businesses as "vital, and truly essential."
-- This suggests prioritizing local entrepreneurs over large corporate subsidies.
-- Matches answer 2: "Small business support and local entrepreneur programs only; avoid large corporate subsidies."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from eddieforcelina.com and Community Impact (2024-05-22, 2024-07-11): Cawlfield voted against new EDC director appointment, proposed requiring all EDC board members to reapply ("That''s the only one that''s an absolute mess"). Campaign explicitly references Celina''s Strategic Plan Goal #7 "Be the City of Small Business" and states locally-owned businesses are "vital, and truly essential, to Celina''s future." Pattern of skepticism toward corporate-oriented EDC direction while championing small/local business. Consistent with answer 2 (small business/local entrepreneur programs; avoid large corporate subsidies).',
  ARRAY['https://eddieforcelina.com/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/07/11/celina-council-asks-economic-development-corporation-board-to-reapply-for-positions/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Not found. No specific transportation priority statements beyond general infrastructure support.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No specific transportation priority statements found beyond general infrastructure support. Checked: eddieforcelina.com, Community Impact, Celina Record.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('780b7f22-755a-4a92-8bd3-78978edbc564', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, eddieforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- ANDY HOPKINS — Council Member Place 3
-- ID: c36e6f78-4828-49cd-9010-988c8a7c7be4
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Not found. Hopkins focuses on corporate campus attraction, small business, downtown development.
-- No housing affordability program stance found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Hopkins focuses on corporate employers, small business, and downtown redevelopment. No statements on housing affordability programs. Checked: hopforcelina.com, Community Impact Q&A 2024-04-15, Celina Record.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, hopforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Hopkins voted in favor of 417-acre annexation with multifamily/mixed-use. Q&A emphasizes
-- infrastructure and "negotiation of development agreements with incoming developers" to secure
-- infrastructure investment. Supports downtown master plan with community input.
-- No explicit zoning ideology statement beyond supporting managed growth. Not placing.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no direct stance placed. Hopkins voted in favor of 417-acre annexation with mixed-use/multifamily. Q&A emphasizes "negotiation of development agreements with incoming developers" and infrastructure. Supported downtown master plan with resident input. No explicit zoning philosophy found. Checked: Celina Record annexation article, Community Impact Q&A 2024-04-15, hopforcelina.com.',
  ARRAY['https://starlocalmedia.com/celinarecord/news/celina-expands-city-limits-by-417-acres-for-development/article_1d352bb7-18aa-4931-98de-544d1ee9d8dd.html', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2024/04/15/qa-meet-the-candidates-running-for-celina-city-council-place-3/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, hopforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Hopkins Q&A states funding police/fire/public works to support growth is a top priority.
-- Supported Fire Station No. 3 opening and Police Headquarters development while on council.
-- Matches answer 4: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from Community Impact Q&A (2024-04-15) and Celina Record (2024-04): Hopkins lists "funding the needs of police, fire and public works to support growth" as a top priority. As council member, backed Fire Station No. 3 opening and Police Headquarters development. Consistent with answer 4 (increase police staffing, equipment, and pay).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2024/04/15/qa-meet-the-candidates-running-for-celina-city-council-place-3/', 'https://starlocalmedia.com/celinarecord/news/celina-get-to-know-your-celina-city-council-candidates-for-place-2-place-3/article_3865446a-fd98-11ee-9f38-e7d8c21c7770.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Hopkins Q&A emphasizes "fostering and attracting small businesses" and "attract responsible
-- corporate campus-type companies" for job creation. Voted against new EDC director appointment
-- alongside Koehne and Cawlfield. Campaign backs Celina Local Business Alliance (small business focus).
-- Opposing corporate-leaning EDC director while advocating for small business and corporate campuses
-- is ambiguous. However, his explicit Q&A goal of attracting "corporate campus-type companies" suggests
-- targeted incentives for specific industries/employers. Matches answer 3: "Targeted incentives for
-- specific industries with community benefit agreements and job quality requirements."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from Community Impact Q&A (2024-04-15): Hopkins lists "attract responsible corporate campus-type companies" for job creation and "fostering and attracting small businesses" as top priorities. Voted against new EDC director appointment (May 2024). Emphasis on responsible/targeted corporate attraction (not blanket incentives) aligns with answer 3 (targeted incentives for specific industries).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2024/04/15/qa-meet-the-candidates-running-for-celina-city-council-place-3/', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Hopkins states "Infrastructure, infrastructure and infrastructure" as his top priority.
-- References tollway development as a key opportunity. Downtown-focused with roads/infrastructure.
-- No mention of transit or bike infrastructure. Consistent with road-focused transportation.
-- Matches answer 4: "Focus on road capacity and traffic flow."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from Celina Record candidate profile (2024): Hopkins states "Infrastructure, infrastructure and infrastructure" as his top priority, referencing tollway development and road infrastructure as key opportunities. No mention of transit, bike lanes, or pedestrian infrastructure. Consistent with answer 4 (road capacity and traffic flow).',
  ARRAY['https://starlocalmedia.com/celinarecord/news/celina-get-to-know-your-celina-city-council-candidates-for-place-2-place-3/article_3865446a-fd98-11ee-9f38-e7d8c21c7770.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c36e6f78-4828-49cd-9010-988c8a7c7be4', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, hopforcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- WENDIE WIGGINTON — Council Member Place 4
-- ID: 04d861e1-8fe2-440b-9332-9382f72e70dd
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Wigginton stated in her 2023 campaign: "We MUST have affordable housing. The goal should be to
-- determine how much affordable housing we need as we grow, work with the developers who will provide it,
-- then strive to maintain our standards into the future and never overbuild or over-develop multi-family."
-- This matches answer 3: "Offer targeted help like subsidies for affordable projects, first-time buyer
-- assistance, and easier building permits" — specifically "working with developers" for affordable units
-- is the closest literal fit (developer partnerships/targeted approach, not rent caps or public housing).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from Celina Record 2023 campaign profile: Wigginton stated "We MUST have affordable housing. The goal should be to determine how much affordable housing we need as we grow, work with the developers who will provide it, then strive to maintain our standards into the future and never overbuild or over-develop multi-family." Targeted developer-partnership approach matches answer 3 (targeted help, working with developers for affordable projects).',
  ARRAY['https://starlocalmedia.com/celinarecord/meet-your-2023-candidates-for-celina-city-council-place-4/article_b33c0ad6-df9c-11ed-a970-23b4ddfa62ca.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, Facebook campaign pages.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Wigginton opposed 417-acre annexation (water supply concerns, calling it potentially "detrimental").
-- 2023 campaign: "never overbuild or over-develop multi-family." Emphasizes "balanced growth" and
-- "right balance of development and businesses." Wants to maintain standards and avoid overdevelopment.
-- Matches answer 2: "Allow modest density increases with strong design review and neighborhood input."
-- Her position is moderate protection of character with some density but strong limits on multifamily.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from Celina Record 2023 campaign profile and annexation vote: Wigginton opposed 417-acre annexation with multifamily, calling it potentially "detrimental." 2023 statement: "never overbuild or over-develop multi-family" and seeks "right balance of development and businesses." Supports maintaining design standards, small-town character, and community traditions. Consistent with answer 2 (modest density increases with strong design review and neighborhood input, not blanket protection or upzoning).',
  ARRAY['https://starlocalmedia.com/celinarecord/meet-your-2023-candidates-for-celina-city-council-place-4/article_b33c0ad6-df9c-11ed-a970-23b4ddfa62ca.html', 'https://starlocalmedia.com/celinarecord/news/celina-expands-city-limits-by-417-acres-for-development/article_1d352bb7-18aa-4931-98de-544d1ee9d8dd.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, Facebook campaign pages.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Wigginton 2023 campaign: "our police and fire have the resources and training they need to keep
-- Celina one of the safest cities in Texas." Prioritizes adequate police/fire resourcing.
-- Matches answer 4: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from Celina Record 2023 campaign profile: Wigginton states she will ensure "our police and fire have the resources and training they need to keep Celina one of the safest cities in Texas." Prioritizes adequate resourcing for public safety departments. Consistent with answer 4 (increase police staffing, equipment, and pay).',
  ARRAY['https://starlocalmedia.com/celinarecord/meet-your-2023-candidates-for-celina-city-council-place-4/article_b33c0ad6-df9c-11ed-a970-23b4ddfa62ca.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Wigginton voted for new EDC director appointment (May 2024). 2023 campaign: "pursue all opportunities
-- to lower taxes for our community continuously and relentlessly" through balanced growth and development.
-- Supports EDC activity. No specific incentive philosophy statement found. Not placing due to
-- insufficient literal match.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no direct stance placed. Wigginton voted for EDC director appointment (May 2024). 2023 campaign states she will "pursue all opportunities to lower taxes" through balanced growth. No specific incentive philosophy statement found. Checked: Celina Record 2023, Community Impact 2024-05-22.',
  ARRAY['https://starlocalmedia.com/celinarecord/meet-your-2023-candidates-for-celina-city-council-place-4/article_b33c0ad6-df9c-11ed-a970-23b4ddfa62ca.html', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Not found. No specific transportation priority statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No specific transportation priority statements found. Checked: Celina Record, Community Impact, Facebook campaign pages.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04d861e1-8fe2-440b-9332-9382f72e70dd', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, Facebook campaign pages.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- MINDY KOEHNE — Council Member Place 5
-- ID: 930b565d-a397-41f5-b03d-0cdebc0e439a
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Not found. Koehne focuses on infrastructure, parks/trails, and public safety. No housing program stance.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Koehne focuses on public safety, parks/trails, and drainage infrastructure. No statements on housing affordability programs. Checked: Celina Record 2023 priorities article, celina-tx.gov, Facebook campaign page.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, celina-tx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Not found. No specific zoning position statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No specific zoning or residential density position statements found. Checked: Celina Record, Community Impact, celina-tx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, celina-tx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Koehne: "fire, police and emergency medical services are top of mind." Entering her 2023 term,
-- highlighted completion of new police station and planned Fire Station No. 3.
-- Matches answer 4: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from Celina Record (2023): Koehne states "fire, police and emergency medical services are top of mind" entering her new term. Highlighted new police station completion and upcoming Fire Station No. 3 as accomplishments. Consistent with answer 4 (increase police/fire staffing and equipment).',
  ARRAY['https://starlocalmedia.com/celinarecord/celina-city-council-member-mindy-koehne-talks-priorities-going-into-next-term/article_8f564702-f0f0-11ed-a13e-df82df2dd265.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Koehne voted against new EDC director appointment (May 2024). No public explanation given.
-- Background as attorney at Coats Rose (real estate/development law) but personal policy on
-- EDC incentives not articulated. Not placing due to insufficient evidence.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no direct stance placed. Koehne voted against new EDC director appointment (May 2024) but no public explanation was given. No explicit economic development incentive philosophy statements found. Checked: Community Impact 2024-05-22, Celina Record, celina-tx.gov.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Koehne mentions trails master plan as a priority: connecting communities through trails as
-- development comes in ("as those communities are built, they are able to connect each community
-- to the master park plan"). Parks/trails emphasis is notable but not a primary transport investment.
-- Also focuses on drainage infrastructure. No transit or road-capacity statements. Not placing.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no direct stance placed. Koehne mentions trails master plan connecting communities as development comes in. Focus is primarily on park/trail connectivity and drainage infrastructure, not road capacity or transit. No explicit transportation investment priority statements. Checked: Celina Record 2023 priorities article.',
  ARRAY['https://starlocalmedia.com/celinarecord/celina-city-council-member-mindy-koehne-talks-priorities-going-into-next-term/article_8f564702-f0f0-11ed-a13e-df82df2dd265.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('930b565d-a397-41f5-b03d-0cdebc0e439a', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, celina-tx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- BRANDON GRUMBLES — Council Member Place 6
-- ID: b167c501-2c43-48b3-8922-e00e060985b3
-- ============================================================

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- Grumbles expects "affordable housing to naturally increase through incoming large developments."
-- Passive/market-based expectation rather than an active policy program. Closest to answer 4
-- (cut regulations/let market decide) but stated as an expectation about market outcomes, not
-- an ideological position against government programs. Not placing due to insufficient literal match.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no direct stance placed. Grumbles expects "affordable housing to naturally increase through incoming large developments" — a market-outcome expectation rather than explicit policy position. No statement supporting or opposing housing programs. Checked: thebestofcelina.com/brandon-grumbles, Community Impact 2023-11-08.',
  ARRAY['https://www.thebestofcelina.com/brandon-grumbles', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2023/11/08/meet-brandon-grumbles-celinas-next-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness not a documented policy issue in Celina coverage. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Grumbles supports "diverse housing options" including mixed-use (residential + retail), but
-- explicitly opposes high-density small-lot developments: warns against "numerous 40-foot lots"
-- due to strain on city and schools. Encourages "good green space for families" and mixed-use.
-- Also participated in unanimous Feb 2026 zoning code amendment to limit SB 840 multifamily.
-- Moderate density with design standards — matches answer 2: "Allow modest density increases
-- (duplexes, accessory units) with strong design review and neighborhood input."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from thebestofcelina.com and Community Impact (2023-11-08): Grumbles supports diverse housing with careful constraints — favors mixed-use developments with "good green space for families" but explicitly warns against high-density small-lot developments ("numerous 40-foot lots"). Wants design standards that are "almost completely top-notch." Participated in unanimous Feb 2026 zoning amendment to limit state-mandated multifamily expansion. Consistent with answer 2 (modest density with strong design review).',
  ARRAY['https://www.thebestofcelina.com/brandon-grumbles', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2023/11/08/meet-brandon-grumbles-celinas-next-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements on civil rights or racial equity policy found. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Grumbles: priorities include equipping police/fire with proper resources. Also uniquely advocates
-- for "mental health professionals" as part of first responder job duties to address psychological strain
-- on officers — this is about officer wellness support, not civilian mental health co-responders.
-- He identified fire departments lacking equipment for high-rise buildings as a gap to address.
-- Overall: equip police/fire adequately. Matches answer 4: "Increase police staffing, equipment, and pay."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from thebestofcelina.com and Community Impact (2023-11-08): Grumbles lists equipping police/fire with proper resources as a priority. Identified fire department equipment gap for high-rise buildings. Advocates for mental health professionals to support first responder officer wellness. Consistent with answer 4 (increase police/fire staffing and equipment). Note: mental health professional reference is for officer support, not civilian co-responder programs.',
  ARRAY['https://www.thebestofcelina.com/brandon-grumbles', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2023/11/08/meet-brandon-grumbles-celinas-next-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Grumbles explicitly: "Large retailers will come to Celina regardless because of the growth...
-- We don''t have to incentivize every one." Reserves incentives for first-to-market businesses
-- and speed-to-market situations. Voted FOR new EDC director (May 2024). Selective, not blanket
-- incentives. Closest to answer 3: "Targeted incentives for specific industries with community
-- benefit agreements and job quality requirements."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from thebestofcelina.com: Grumbles states "Large retailers will come to Celina regardless because of the growth...We don''t have to incentivize every one." He reserves incentives for first-to-market businesses and speed-to-market situations — a targeted, selective approach. Voted in favor of EDC director appointment (May 2024). Consistent with answer 3 (targeted incentives for specific industries/situations, not blanket subsidies).',
  ARRAY['https://www.thebestofcelina.com/brandon-grumbles', 'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/22/celina-economic-development-corporation-appoints-new-director/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Grumbles: roads are the "biggest challenge," county and farm-to-market roads need attention
-- before new subdivisions arrive. Downtown needs roads, sidewalks, and drainage improvements.
-- Also mentions streamlining development permits. No transit or bike lane mentions.
-- Matches answer 4: "Focus on road capacity and traffic flow."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from Community Impact (2023-11-08): Grumbles identifies roads as the "biggest challenge," noting county and farm-to-market roads require attention before new subdivisions arrive. Downtown needs "roads, sidewalks and drainage." No mention of transit, bike infrastructure, or multimodal options. Consistent with answer 4 (road capacity and traffic flow).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2023/11/08/meet-brandon-grumbles-celinas-next-city-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b167c501-2c43-48b3-8922-e00e060985b3', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements on immigration enforcement policy found. Checked: Community Impact, Celina Record, thebestofcelina.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

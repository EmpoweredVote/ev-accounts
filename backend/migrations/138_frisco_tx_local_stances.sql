BEGIN;

-- =============================================================================
-- Migration 138: Frisco, TX City Council — Local Lens Compass Stances
-- Researched: 2026-05-11
-- Politicians: Jeff Cheney (Mayor), Ann Anderson (Place 1), Burt Thakur (Place 2),
--              Angelia Pelham (Place 3), Jared Elad (Place 4), Laura Rummel (Place 5)
-- Topics: 8 Local Lens topics
-- Note: Texas SB4 (2017) requires all TX cities to honor ICE detainers by law;
--       immigration stance reflects mandatory state compliance, not local initiative.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- JEFF CHENEY — Mayor
-- politician_id: ac1ed3c9-db6c-4931-bc55-4d53c6c81b35
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 4
-- Cheney stated "Texas is very much a property-rights state" and that the city
-- cannot force developers to set prices. No public housing, no rent caps. Supports
-- cutting regulations to let private development solve housing supply.
-- Matches: "Cut regulations and zoning rules so private developers can build more housing."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from public statements: Cheney stated "Texas is very much a property-rights state" and that the city cannot compel developers to offer housing at any particular price. He acknowledged the issue and said the city would "work with businesses to explore viable solutions" but rejected mandates. No record of rent caps, inclusionary zoning requirements, or direct public housing support. Philosophy is to let private market respond to demand. Value 4: cut regulations, let private developers decide.',
  ARRAY['https://communityimpact.com/commerce/2017/07/10/frisco-businesses-struggle-hire-high-housing-costs/',
        'https://www.friscotexas.gov/586/Mayor-Jeff-Cheney',
        'https://friscochronicles.com/who-is-jeff-cheney/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Cheney stating a specific position on homeless camping enforcement or encampment policy. Frisco is subject to Texas statewide HB1925 camping ban (2021). No mayoral statement matching a specific stance description found. Checked: friscotexas.gov, Frisco Enterprise (starlocalmedia.com), Community Impact, KERA, Dallas Observer.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 3
-- Cheney has presided over major mixed-use and multifamily developments (Fields West,
-- PGA Frisco, Toyota Stadium area) near commercial corridors. He signed off on
-- upzoning near TIRZ commercial zones while the city's comprehensive plan maintains
-- single-family residential character in established neighborhoods.
-- Matches: "Allow multifamily and mixed-use near commercial corridors while protecting most residential zones."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from council action: Under Cheney''s mayoralty the council has approved major mixed-use/multifamily developments (Fields West, PGA Frisco resort, Toyota Stadium redevelopment) concentrated in TIRZ commercial corridors. Cheney also stated he wanted to pass an ordinance requiring a percentage of open space in new developments, signaling he is protective of neighborhood character. The city''s 2040 Comprehensive Plan permits density near commercial nodes while keeping residential zones largely single-family. Value 3: multifamily and mixed-use near commercial corridors, protect residential zones.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2024/07/05/frisco-council-oks-95m-in-construction-incentives-for-fields-west-development/',
        'https://www.friscotexas.gov/512/Comprehensive-Planning',
        'https://friscochronicles.com/who-is-jeff-cheney/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Cheney making specific statements on civil rights enforcement, affirmative action, or racial equity policy. Frisco operates an Inclusion Committee and Cheney has touted the city''s diversity, but no mayoral statement matching a specific stance description was found. Checked: friscotexas.gov, Frisco Enterprise, Community Impact, Dallas Observer, Local Profile.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Cheney's administration increased police hiring to "most officers in city history,"
-- allocates half of city budget to public safety, and the FY26 budget included
-- $79.9M for the police department with new detective/officer positions.
-- Matches: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from budget and public statements: Frisco hired the most police officers in city history under Cheney. The FY2026 budget allocated $79.9M to the police department for new detective/officer positions, vehicles, and equipment. Half of the city''s general fund budget goes toward public safety. Frisco has been ranked #1 Safest City in America. No record of mental health co-responder redirects or budget shifts away from policing. Value 4: increase police staffing, equipment, and pay.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2025/09/18/frisco-keeps-tax-rate-flat-in-3047m-budget-raises-water-and-sewer-rates/',
        'https://communityimpact.com/dallas-fort-worth/frisco/government/2025/08/12/friscos-3048m-budget-proposes-rate-increase-more-public-safety-positions/',
        'https://localprofile.com/2023/05/11/qa-with-mayor-jeff-cheney/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 4
-- Texas SB4 (2017) requires all TX city law enforcement to honor ICE detainers
-- and share immigration status information. Frisco Police comply as required by state
-- law. No record of Cheney advocating beyond compliance or taking a sanctuary position.
-- Matches: "Honor ICE detainers and share information proactively when federal agencies request it."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from state law context: Texas SB4 (2017) requires all Texas local law enforcement agencies to honor ICE detainers and prohibits sanctuary policies. Frisco complies with this state mandate. Cheney has not publicly advocated for sanctuary protections or for going beyond compliance. No record of limiting ICE cooperation. Value 4 reflects mandatory state compliance without active local pushback. Note: no evidence Cheney directs proactive federal partnership beyond what SB4 requires; value 4 reflects the city''s legal posture.',
  ARRAY['https://www.texastribune.org/2017/05/08/5-things-know-about-sanctuary-cities-law/',
        'https://capitol.texas.gov/tlodocs/85R/analysis/html/SB00004I.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 5
-- Cheney led or presided over: $94.5M Fields West incentive package (TIRZ + tax rebates),
-- $182M Toyota Stadium improvement deal, PGA Frisco public-private partnerships,
-- Universal Kids resort deal. Consistently described as prioritizing any major employer
-- with significant tax abatements. "Tonight's vote marks an important decision in our
-- city's history" (on Fields West). Matches: "Offer maximum incentives to attract any
-- large employer; economic growth is the top city priority."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council votes and public statements: Under Cheney the council approved a $94.5M incentive package for Fields West (TIRZ + $7M sales tax break + $17.5M infrastructure grant), a $182M Toyota Stadium improvement deal, and public-private partnerships for PGA Frisco, Universal Kids resort, and UNT-Frisco campus. Cheney stated "Tonight''s vote marks an important decision in our city''s history" on the Fields West deal. Frisco has been ranked #1 for highest job growth and Cheney''s brand is aggressive economic recruitment. Value 5: maximum incentives to attract large employers, economic growth as top priority.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2024/07/05/frisco-council-oks-95m-in-construction-incentives-for-fields-west-development/',
        'https://www.friscotexas.gov/m/newsflash/home/detail/2176',
        'https://therealdeal.com/texas/dallas/2024/07/09/frisco-oks-95m-incentives-for-karahan-cos-fields-west/',
        'https://starlocalmedia.com/friscoenterprise/news/frisco-mayor-jeff-cheney-delves-into-2025-future-of-city/article_422a3bfc-bf05-11ef-859d-cf9c373b26ba.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 4
-- Cheney's administration invested $50M in road/infrastructure improvements,
-- focuses on highway access and road capacity. The Rail District investment is
-- property development, not mass transit. City's transportation planning centers
-- on road capacity for a car-dependent suburb with no local bus or rail system.
-- Matches: "Focus on road capacity and traffic flow; transportation investment should serve the majority who drive."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac1ed3c9-db6c-4931-bc55-4d53c6c81b35', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from budget and city planning: Frisco''s FY26 budget allocated road and infrastructure projects as a major spending category, with $50M in infrastructure/road improvements noted. Frisco is a car-dependent DFW suburb with no local bus network or light rail. The "Rail District" redevelopment is a real estate/entertainment district, not a commuter rail project. No record of Cheney advocating for bike lanes, pedestrian networks, or transit expansion as priorities. Value 4: focus on road capacity for the driving majority.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2025/09/18/frisco-keeps-tax-rate-flat-in-3047m-budget-raises-water-and-sewer-rates/',
        'https://www.friscotexas.gov/586/Mayor-Jeff-Cheney'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- ANN ANDERSON — Council Place 1
-- politician_id: da010ea4-257d-4582-98cb-ee90063aa31d
-- Elected January 2026 special election; very new to council
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Anderson's platform explicitly calls for "smaller format housing options such as
-- condos, townhomes, and zero lot line home alternatives." She collaborates with
-- nonprofits/faith organizations to connect residents to housing resources.
-- Matches: "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign platform: Anderson''s stated priorities include asking developers to offer "smaller format housing options such as condos, townhomes, and zero lot line home alternatives" and fueling innovation and entrepreneurship. She also emphasizes collaborating with nonprofits, schools, and faith-based organizations to connect residents to housing resources. No advocacy for direct public housing or rent caps. Value 3: targeted help, varied housing formats, community partnerships.',
  ARRAY['https://ann4frisco.com/campaign-priorities/',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2025/12/31/qa-meet-the-candidates-running-for-frisco-city-council-place-1/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Anderson stating a specific position on homeless camping enforcement. She was elected in a January 2026 special election and has a very limited public record of council votes. Checked: ann4frisco.com, communityimpact.com, starlocalmedia.com, ballotpedia.org, keranews.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 3
-- Anderson supports "smart growth and responsible planning" and "smaller format housing
-- options" near existing development. She served on the city's comprehensive planning
-- committee. Philosophy is density-near-corridors, not broad upzoning.
-- Matches: "Allow multifamily and mixed-use near commercial corridors while protecting most residential zones."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign platform and background: Anderson served on Frisco''s comprehensive planning committee and explicitly supports "smart growth and responsible planning." Her housing platform calls for smaller-format housing (condos, townhomes) as infill options, not broad upzoning of single-family neighborhoods. This aligns with allowing density in appropriate locations while protecting established residential zones. Value 3.',
  ARRAY['https://ann4frisco.com/campaign-priorities/',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2025/12/31/qa-meet-the-candidates-running-for-frisco-city-council-place-1/',
        'https://ballotpedia.org/Ann_Anderson_(Frisco_City_Council_Place_1,_Texas,_candidate_2026)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Anderson stating a specific position on civil rights enforcement, affirmative action, or racial equity policy. Her platform emphasizes community inclusion broadly ("Frisco thrives when everyone feels seen, supported, and valued") but no specific policy statement matching a stance description was found. Checked: ann4frisco.com, communityimpact.com, ballotpedia.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Anderson states "public safety is the cornerstone of a thriving community" and
-- advocates for "investing in staffing and training" so police/fire have "personnel,
-- equipment, and training to meet increasing service demands."
-- Matches: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign platform: Anderson''s stated position is that "public safety is the cornerstone of a thriving community" and she advocates "investing in staffing and training to ensure Police and Fire Departments have the personnel, equipment, and training to meet increasing service demands." No mention of redirecting funds, mental health co-responders, or non-police alternatives. Value 4: increase police staffing, equipment, and pay.',
  ARRAY['https://ann4frisco.com/campaign-priorities/',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2025/12/31/qa-meet-the-candidates-running-for-frisco-city-council-place-1/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Anderson stating a specific position on local immigration enforcement beyond Texas SB4 compliance. City of Frisco complies with Texas SB4 (ICE detainer requirement) as a matter of state law. No Anderson statement advocating for or against that baseline found. Checked: ann4frisco.com, communityimpact.com, ballotpedia.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Anderson supports economic development through innovation and entrepreneurship,
-- wants to attract "good-paying jobs" and partner regionally on economic growth.
-- She emphasizes "fueling innovation and entrepreneurship" rather than mega-projects.
-- Matches: "Compete actively for major employers with significant tax abatements and infrastructure investment."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign platform: Anderson''s platform includes "fueling innovation and entrepreneurship" and attracting "good-paying jobs to Frisco" through regional economic partnerships. She also mentions supporting start-ups for "slow and steady organic growth" alongside larger development, suggesting support for competitive incentives for major employers while also valuing local business. Value 4 reflects active competition for major employers with targeted incentives, with a secondary emphasis on smaller-business support.',
  ARRAY['https://ann4frisco.com/campaign-priorities/',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2025/12/31/qa-meet-the-candidates-running-for-frisco-city-council-place-1/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Anderson supports traffic flow improvements via "signal timing and smart technology,"
-- data-driven approaches, and regional coordination. This is not a highway-only or
-- transit-first stance — it's maintenance + selective improvements.
-- Matches: "Maintain roads while selectively adding transit connections and pedestrian improvements where density supports it."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('da010ea4-257d-4582-98cb-ee90063aa31d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign platform: Anderson advocates for "signal timing and smart technology" for better traffic flow, noting that Frisco''s Traffic Management Center has made strides, and also supports partnering with neighboring cities to coordinate transportation. This is a pragmatic, data-driven approach rather than highway-expansion-first or multimodal-first. Value 3: maintain roads while selectively adding improvements where density supports it.',
  ARRAY['https://ann4frisco.com/campaign-priorities/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- BURT THAKUR — Council Place 2
-- politician_id: c11bf372-8190-4b45-b80a-cbd0fb2ba401
-- Elected June 2025 runoff; first Indian-American council member; Navy veteran
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found of Thakur stating a specific position on affordable housing policy. His platform focuses on public safety, veterans support, and economic development. Checked: burt4frisco.com, ballotpedia.org, starlocalmedia.com, keranews.org, yahoo.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Thakur stating a specific position on homeless camping enforcement or encampment policy. Checked: burt4frisco.com, ballotpedia.org, starlocalmedia.com, keranews.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found of Thakur making specific statements on residential zoning policy. His platform focuses on "sustainable urban expansion while maintaining Frisco''s charm and livability" but no specific zoning stance was found. Checked: burt4frisco.com, ballotpedia.org, starlocalmedia.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Thakur stating a specific position on civil rights enforcement or racial equity policy. Checked: burt4frisco.com, ballotpedia.org, yahoo.com (H-1B controversy article), keranews.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Thakur's platform explicitly calls for "building hail and tornado shelters" and
-- "ensuring Fire and Police Department needs are met." Navy veteran background;
-- consistent emphasis on public safety funding.
-- Matches: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign platform: Thakur''s stated priorities include ensuring "Fire and Police Department needs are met" and building public safety infrastructure (hail/tornado shelters). As a U.S. Navy veteran with military background, his orientation is toward funded, staffed public safety departments. No record of redirecting funds or mental health co-responder emphasis. Value 4: increase police staffing, equipment, and pay.',
  ARRAY['https://burt4frisco.com/',
        'https://ballotpedia.org/Burt_Thakur_(Frisco_City_Council_Place_2,_Texas,_candidate_2025)',
        'https://starlocalmedia.com/friscoenterprise/news/runoff-election-2025-burt-thakur-claims-place-2-frisco-city-council-seat/article_9d1c8d6b-6cda-4b54-b7a9-c086e11591e2.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Thakur stating a position on local immigration enforcement beyond Texas SB4 compliance. Note: Thakur, himself a naturalized citizen (immigrated from India), pushed back against allegations of immigration fraud in his own campaign. No policy statements on ICE cooperation found. Checked: burt4frisco.com, yahoo.com, keranews.org, ballotpedia.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Thakur supports "local businesses, creating job opportunities, and fostering economic
-- prosperity" and promotes "innovation, entrepreneurship, and workforce development
-- to attract good paying jobs."
-- Matches: "Compete actively for major employers with significant tax abatements and infrastructure investment."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign platform: Thakur''s stated priorities include supporting "local businesses, creating job opportunities, and fostering economic prosperity" and promoting "innovation, entrepreneurship, and workforce development to attract good paying jobs to Frisco." This aligns with actively competing for employers using incentives. No specific votes on TIRZ packages yet (elected June 2025). Value 4: compete actively for major employers.',
  ARRAY['https://burt4frisco.com/about-us/',
        'https://www.ballotready.org/people/burt-thakur-71f81bef-f89d-4949-8d70-1e1c31d1674e'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c11bf372-8190-4b45-b80a-cbd0fb2ba401', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found of Thakur stating a specific position on transportation priorities. His platform mentions cell phone towers and internet access as infrastructure priorities but not roads, transit, or multimodal planning. Checked: burt4frisco.com, ballotpedia.org, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- ANGELIA PELHAM — Council Place 3 / Mayor Pro Tem
-- politician_id: 5b346b19-d6ee-47e2-acbf-5780ca423264
-- Elected 2021, re-elected 2024; appointed Mayor Pro Tem July 2025
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Pelham cited "demand for multifamily housing should be answered with high-quality
-- development that incorporates offices, hotels and businesses" to increase tax base.
-- Supports targeted commercial/multifamily development; no direct public housing advocacy.
-- Matches: "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from public statements: Pelham stated that "the demand for multifamily housing should be answered with high-quality development that incorporates offices, hotels and businesses" to grow the city''s tax base and lower the burden on single-family homeowners. She also sought to increase the homestead exemption to 20%. This indicates support for mixed-income, targeted development approaches rather than direct public housing or rent caps. Value 3: targeted help through development incentives and programs.',
  ARRAY['https://www.friscotexas.gov/1731/Angelia-Pelham-Mayor-Pro-Tem',
        'https://twu.edu/leading-the-lone-star-state/about-our-speakers/angelia-pelham/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Pelham stating a specific position on homeless camping enforcement or encampment policy. Checked: friscotexas.gov, twu.edu, friscochronicles.com, texasmetronews.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 3
-- Pelham explicitly supports multifamily near commercial zones to grow the tax base
-- while protecting single-family areas. This is the classic "density near corridors"
-- position.
-- Matches: "Allow multifamily and mixed-use near commercial corridors while protecting most residential zones."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from public statements: Pelham explicitly stated that multifamily housing demand "should be answered with high-quality development that incorporates offices, hotels and businesses" — positioning mixed-use/multifamily as a targeted tool near commercial areas, not citywide upzoning. She also advocates protecting single-family residents through homestead exemption increases. This is a clear value 3 position: multifamily and mixed-use near commercial corridors, protect residential zones.',
  ARRAY['https://www.friscotexas.gov/1731/Angelia-Pelham-Mayor-Pro-Tem',
        'https://twu.edu/leading-the-lone-star-state/about-our-speakers/angelia-pelham/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — value 3
-- Pelham founded and has chaired Linking Cultures of Frisco for 15 years, an
-- organization promoting racial/ethnic understanding and providing $100K+ in
-- scholarships. She has been "instrumental in creating a more engaging and inclusive
-- environment." HR executive background includes Frito-Lay, PepsiCo, Disney.
-- Matches: "Maintain current civil rights laws while promoting equal opportunity."
-- (Value 3 rather than 2: community-based equity work without policy mandates or
-- reparations advocacy found in the record; she works within existing systems.)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', '0bc588c6-39e1-4084-b5de-cac909b8b762', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from civic work and public record: Pelham co-founded and has chaired Linking Cultures of Frisco for 15 years, a nonprofit dedicated to connecting the community through "awareness and appreciation of our racial and ethnic backgrounds." The organization hosts an annual MLK Oration Gala providing $100K+ in scholarships. She has been described as "instrumental in creating a more engaging and inclusive environment." As a 35-year HR executive at companies including Disney, PepsiCo, and Frito-Lay, she has deep civil rights and equity experience. However, no specific policy mandates, reparations advocacy, or systemic reform proposals at the council level were found. Value 3: promote equal opportunity and inclusion within existing civil rights framework.',
  ARRAY['https://twu.edu/leading-the-lone-star-state/about-our-speakers/angelia-pelham/',
        'https://www.linkingculturesoffrisco.org/about',
        'https://texasmetronews.com/89528/superb-woman-hon-angelia-pelham/',
        'https://lifestylefrisco.com/linking-cultures-mlk-oration-gala/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Frisco City Council unanimously approved the FY26 public safety budget expansion
-- ($79.9M police department). No record of Pelham dissenting or advocating for
-- redirecting funds. Consistent with city's "safest city" brand and council consensus.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from council consensus: Frisco City Council approved the FY26 budget allocating $79.9M to the police department with new officer positions. No record of Pelham dissenting from the council''s public safety spending priorities. As Mayor Pro Tem, she co-presents city priorities (Grand Park, public safety) at community events. No record of advocating for redirecting police funds or mental health co-responders. Value 4: increase police staffing and funding to support growing city.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/frisco/government/2025/09/18/frisco-keeps-tax-rate-flat-in-3047m-budget-raises-water-and-sewer-rates/',
        'https://www.friscotexas.gov/1731/Angelia-Pelham-Mayor-Pro-Tem'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Pelham stating a specific position on local immigration enforcement beyond Texas SB4 compliance. Her equity/inclusion work focuses on cultural awareness, not immigration policy. Checked: friscotexas.gov, twu.edu, friscochronicles.com, texasmetronews.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Pelham supports multifamily/commercial development to grow the tax base and lower
-- single-family burden. She explicitly supports the city's TIRZ-based economic strategy
-- and is in the council majority that approved major development deals.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from public statements and council action: Pelham supports commercial development to grow the city''s tax base and relieve single-family homeowners. She has been part of the council majority approving major development incentive packages (Fields West, Toyota Stadium). Her economic philosophy is to expand the commercial base through targeted large-development deals. Value 4: compete actively for major employers with significant incentives.',
  ARRAY['https://www.friscotexas.gov/1731/Angelia-Pelham-Mayor-Pro-Tem',
        'https://twu.edu/leading-the-lone-star-state/about-our-speakers/angelia-pelham/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b346b19-d6ee-47e2-acbf-5780ca423264', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found of Pelham stating a specific position on transportation priorities. Checked: friscotexas.gov, twu.edu, friscochronicles.com, x.com/CityOfFriscoTx.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- JARED ELAD — Council Place 4
-- politician_id: 5d8acfc7-5643-418b-a474-3d87898f4e17
-- Elected May 2025; financial advisor; anti-density/anti-mega-project platform
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 4
-- Elad explicitly stated he wants to "slow down density/halt building apartment
-- complexes" and keep city at ~280K not 350K. Prefers market-driven growth with
-- less multifamily. No affordable housing mandate advocacy.
-- Matches: "Cut regulations and zoning rules so private developers can build more housing"
-- — but Elad actually wants LESS multifamily, not more. His position is closer to
-- value 4 (market/private sector) on HOW housing is delivered, while opposing
-- high-density delivery. Best match: value 4 (let market decide, no mandates).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign platform: Elad''s top priorities include "slowing down density/halting building apartment complexes" and keeping Frisco''s population target around 280,000 rather than 350,000. He wants "world-class developments with more open space, less multi-family housing." No advocacy for public housing, rent caps, or inclusionary zoning. His approach is market-based with a preference for lower density. Value 4: rely on private market with reduced regulation, no government housing mandates.',
  ARRAY['https://ivoterguide.com/candidate/87330/race/22885/election/1272',
        'https://ballotpedia.org/Jared_Elad_(Frisco_City_Council_Place_4,_Texas,_candidate_2025)',
        'https://friscochronicles.com/jared-elad-city-council-place-4/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Elad stating a specific position on homeless camping enforcement. Checked: ivoterguide.com, ballotpedia.org, friscochronicles.com, keranews.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 1
-- Elad explicitly wants to "slow down density/halt building apartment complexes,"
-- build with "less multi-family housing," and protect neighborhood character.
-- Population cap goal of 280K vs. plan's 350K. This is the strongest protect-character
-- position on the council.
-- Matches: "Protect existing neighborhood character strictly; require community votes before any rezoning."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign platform and candidate statements: Elad''s top three priorities include "slowing down density/halting building apartment complexes" and building with "world-class developments with more open space, less multi-family housing." He believes the city''s population target should be ~280,000 rather than the comprehensive plan''s 350,000 maximum. This is the most protective-of-neighborhood-character position on the council. Value 1: protect existing neighborhood character strictly.',
  ARRAY['https://ivoterguide.com/candidate/87330/race/22885/election/1272',
        'https://ballotpedia.org/Jared_Elad_(Frisco_City_Council_Place_4,_Texas,_candidate_2025)',
        'https://friscochronicles.com/jared-elad-city-council-place-4/',
        'https://www.keranews.org/news/2025-06-07/frisco-council-member-appears-to-lose-reelection-after-controversial-recordings-burt-thakur-place-2-tammy-meinershagen-lost-jared-elad-place-4'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Elad stating a specific position on civil rights enforcement, affirmative action, or racial equity policy. Checked: ivoterguide.com, ballotpedia.org, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Elad stated he would "cut wasteful spending and prioritize public safety" and
-- supports "additional police officers to handle increased issues that may come with growth."
-- Matches: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign platform: Elad stated he would "cut wasteful spending and prioritize public safety as a council member" and advocates for "additional police officers to handle increased issues that may come with growth." He specifically calls out public safety as fully funded priority. No mention of mental health co-responders or budget redirects. Value 4: increase police staffing and pay.',
  ARRAY['https://ivoterguide.com/candidate/87330/race/22885/election/1272',
        'https://ballotpedia.org/Jared_Elad_(Frisco_City_Council_Place_4,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Elad stating a specific position on local immigration enforcement beyond Texas SB4 compliance. Checked: ivoterguide.com, ballotpedia.org, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 3
-- Elad is skeptical of mega-projects ("vanity projects such as the PAC and Universal")
-- and wants to "focus more on smaller projects for the community" and attract small
-- businesses. He favors targeted community-benefit development over maximum incentives
-- for any large employer.
-- Matches: "Targeted incentives for specific industries with community benefit agreements and job quality requirements."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign platform and public statements: Elad said he would prioritize smaller, community-friendly development projects over mega-projects, and specifically criticized "vanity projects such as the PAC and Universal" as wasteful spending. He wants to attract more small businesses to Frisco rather than competing for any large employer with maximum incentives. He also emphasizes fiscal responsibility and "cutting wasteful spending." This aligns with targeted incentives for specific projects with community benefit, not maximum subsidies for any large employer. Value 3.',
  ARRAY['https://ivoterguide.com/candidate/87330/race/22885/election/1272',
        'https://friscochronicles.com/jared-elad-city-council-place-4/',
        'https://ballotpedia.org/Jared_Elad_(Frisco_City_Council_Place_4,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 4
-- Elad's top three priorities include "addressing traffic in a meaningful way" with
-- a focus on a car-dependent suburb. No mention of transit or multimodal options.
-- His anti-density stance implies auto-centric infrastructure.
-- Matches: "Focus on road capacity and traffic flow; transportation investment should serve the majority who drive."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5d8acfc7-5643-418b-a474-3d87898f4e17', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign platform: Elad''s top three priorities include "addressing traffic in a meaningful way." His anti-density, low-multifamily platform implies a car-first transportation philosophy consistent with a suburban DFW city. No mention of bike lanes, pedestrian networks, or transit alternatives. Value 4: focus on road capacity and traffic flow for the driving majority.',
  ARRAY['https://ivoterguide.com/candidate/87330/race/22885/election/1272',
        'https://friscochronicles.com/jared-elad-city-council-place-4/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- LAURA RUMMEL — Council Place 5 / Deputy Mayor Pro Tem
-- politician_id: 76c3fa35-a286-4fa1-b6da-40300d91f33e
-- Elected 2022 special election, re-elected 2023; financial services VP
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Rummel's platform calls for "smaller format housing options such as condos,
-- townhomes, zero lot line home alternatives." Also implemented 20% homestead
-- exemption and Senior Tax Freeze to keep residents in their homes.
-- Matches: "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign platform and council action: Rummel''s platform calls for "smaller format housing options such as condos, townhomes, zero lot line home alternatives." She also successfully increased the City''s Homestead Exemption from 10% to the maximum 20% and implemented a Senior Tax Freeze — targeted measures to keep existing residents housed without direct public housing or rent controls. Value 3: targeted help through vouchers/exemptions and encouraging diverse housing formats.',
  ARRAY['https://www.laurarummel.com/key-topics',
        'https://ballotpedia.org/Laura_Rummel_(Frisco_City_Council_Place_5,_Texas,_candidate_2026)',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2023/05/06/rummel-wins-re-election-for-frisco-city-council-seat/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Rummel stating a specific position on homeless camping enforcement or encampment policy. Checked: laurarummel.com, ballotpedia.org, communityimpact.com, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 3
-- Rummel explicitly "fought against state laws on zoning not in Frisco's best
-- interest," supporting local control. Her smaller-format housing platform implies
-- targeted density options, not blanket upzoning. Supports city retaining
-- discretion over rezoning decisions.
-- Matches: "Allow multifamily and mixed-use near commercial corridors while protecting most residential zones."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign platform and council action: Rummel "fought against state laws on zoning not in Frisco''s best interest," indicating she supports local discretionary zoning rather than state-imposed upzoning mandates. Her housing platform calls for smaller-format housing (condos, townhomes) as targeted options rather than broad multifamily rezoning. This is a case-by-case, selective-density position. Value 3: multifamily and mixed-use near appropriate corridors, protect residential zones.',
  ARRAY['https://www.laurarummel.com/key-topics',
        'https://ballotpedia.org/Laura_Rummel_(Frisco_City_Council_Place_5,_Texas,_candidate_2026)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Rummel stating a specific position on civil rights enforcement, affirmative action, or racial equity policy. Checked: laurarummel.com, ballotpedia.org, communityimpact.com, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Rummel's platform states she must "continue to approve additional public safety
-- positions to support the growing city" to maintain Frisco's "Safest Cities" ranking.
-- Matches: "Increase police staffing, equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign platform: Rummel''s platform states "Frisco has consistently been rated one of the Safest Cities in America, but to maintain this reputation, she must continue to approve additional public safety positions to support the growing city." No mention of mental health co-responders, budget redirects, or reducing police staffing. Value 4: increase police staffing to keep pace with growth.',
  ARRAY['https://www.laurarummel.com/key-topics',
        'https://ballotpedia.org/Laura_Rummel_(Frisco_City_Council_Place_5,_Texas,_candidate_2026)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Rummel stating a specific position on local immigration enforcement beyond Texas SB4 compliance. Checked: laurarummel.com, ballotpedia.org, communityimpact.com, friscochronicles.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Rummel supports "smart growth" and the city's TIRZ-based economic strategy.
-- As Deputy Mayor Pro Tem, she has been part of the council majority approving
-- major incentive packages. Her platform emphasizes smaller housing formats alongside
-- fueling entrepreneurship, indicating support for targeted large-employer competition.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council action and platform: Rummel has been part of the council majority approving major economic development deals (Fields West $94.5M incentive, Toyota Stadium $182M). Her platform supports "fueling innovation and entrepreneurship" alongside smart growth. As a financial services professional, she supports fiscally sound economic development with significant city investment to attract employers. Value 4: compete actively for major employers with incentives.',
  ARRAY['https://www.laurarummel.com/key-topics',
        'https://ballotpedia.org/Laura_Rummel_(Frisco_City_Council_Place_5,_Texas,_candidate_2026)',
        'https://communityimpact.com/dallas-fort-worth/frisco/election/2023/05/06/rummel-wins-re-election-for-frisco-city-council-seat/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 4
-- Rummel "strategically invested millions in roads and infrastructure" and her
-- proactive plan centers on "continued population increase" requiring more roads.
-- She advocates for technology to improve traffic flow, not transit/multimodal.
-- Matches: "Focus on road capacity and traffic flow; transportation investment should serve the majority who drive."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('76c3fa35-a286-4fa1-b6da-40300d91f33e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign platform and council record: Rummel states a "proactive plan for continued population increase" has been a top priority, including "investing millions into building out new roads." She advocates for "technology and innovation to improve traffic and city services." No mention of bike lanes, pedestrian networks, transit expansion, or reduced parking requirements. Value 4: focus on road capacity and traffic flow.',
  ARRAY['https://www.laurarummel.com/key-topics',
        'https://ballotpedia.org/Laura_Rummel_(Frisco_City_Council_Place_5,_Texas,_candidate_2026)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

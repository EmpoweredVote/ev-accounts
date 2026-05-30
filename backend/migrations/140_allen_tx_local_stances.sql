-- Migration 140: Allen TX city council Local Lens compass stances
-- Researched 2026-05-11
-- Politicians: Michael Schaeffer (Place 1), Tommy Baril (Place 2), Ken Cook (Place 3),
--              Amy Gnadt (Place 4), Carl Clemencich (Place 5), Ben Trahan (Place 6)
-- City: Allen, TX — ~110,000 pop., Collin County; nonpartisan, conservative-leaning suburb

BEGIN;

-- ============================================================
-- MICHAEL SCHAEFFER — Council Place 1
-- ID: c7a0ecf6-b416-474b-9647-a25e404f4bc4
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Schaeffer explicitly opposes new high-density apartments and "has never incentivized,
-- zoned or approved a single apartment." His focus is on commercial tax base growth and
-- "responsible growth." No support for public housing or rent caps. Aligns with value 4
-- (cut regulations, let private developers build) with some deference to market over
-- government intervention — closest to 4 rather than 5 because he supported some
-- targeted commercial/mixed-use development.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Schaeffer declared "I have never incentivized, zoned or approved a single apartment" and opposes new high-density apartment zoning. His approach centers on growing the commercial tax base rather than housing programs. No support for subsidies, rent caps, or public housing found. Aligns with answer 4 (cut regulations, let private developers build) — he opposes government-driven housing production while allowing market forces to determine supply.',
  ARRAY['https://www.mike4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found. Allen is a built-out suburb with no significant visible homelessness
-- issue in public discourse. No statements, votes, or positions found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: mike4allen.com, cityofallen.org, starlocalmedia.com/allenamerican, communityimpact.com. Allen has no significant homelessness policy debate in council records; no statements from Schaeffer on this topic found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Schaeffer ran explicitly against new high-density apartments, stating he "will not support
-- more high-density, high-rise apartments." He supports protecting existing neighborhood
-- character and opposes rezoning against landowners' wishes. Aligns with value 2: allow
-- modest density increases but with strong review and neighborhood protection.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign statements: Schaeffer stated "I will not support more high-density, high-rise apartments that will overload our infrastructure" and emphasized protecting existing neighborhood character. He focuses on downtown revitalization that maintains nostalgic charm rather than broad upzoning. This matches answer 2 (allow modest density with strong design review and neighborhood input) — he allows some growth but explicitly resists high-density multifamily.',
  ARRAY['https://www.mike4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: mike4allen.com, cityofallen.org, starlocalmedia.com, legistorm.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Schaeffer chaired the Allen Police Headquarters bond campaign, served on Allen Public Safety
-- and Recovery Board, and pledges strong support for police equipment, personnel, and
-- facilities. Aligns with value 4: increase police staffing, equipment, and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements and service record: Schaeffer served on the Allen Public Safety and Recovery Board (2017-present) and chaired the Allen Police Headquarters Bond campaign ($97M facility). He pledges to provide "equipment, personnel, and facilities" to maintain Allen''s safety reputation. This aligns with answer 4 (increase police staffing, equipment, and pay). No mention of mental health co-responders or budget redirection.',
  ARRAY['https://www.mike4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-city-council-to-add-new-public-safety-staff-in-new-approved-budget/article_4a89bfbe-531f-11ee-bf82-ef9c66531def.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found. Allen has not adopted a sanctuary policy and Texas SB 8 (2025)
-- mandates 287(g) cooperation statewide; no Schaeffer-specific stance found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: mike4allen.com, cityofallen.org legislative agenda, Allen American archives. No council statements on ICE cooperation or immigration enforcement policy found for Schaeffer specifically.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Schaeffer served 13+ years on Allen EDC Board (including 8 years as President), overseeing
-- aggressive corporate recruitment with tax abatements and infrastructure investment. He then
-- voted with the full council to approve the $950M Kalahari Resort incentive deal (Feb 2025).
-- Aligns with value 4: compete actively for major employers with significant tax abatements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from service record and council votes: Schaeffer spent 13+ years on the Allen EDC Board (8 years as President), an organization whose core mission is recruiting major employers with tax incentives, infrastructure investment, and Chapter 380 agreements. He voted with the full council to approve the Kalahari Resort ($950M) performance-based incentive deal in Feb 2025. Allen''s legislative agenda explicitly supports protecting EDC tools including Texas Enterprise Fund and TIFs. Aligns with answer 4 (compete actively for major employers with significant tax abatements).',
  ARRAY['https://www.mike4allen.com/',
        'https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Schaeffer's campaign focused on aging road infrastructure repairs and highway 121 corridor
-- development. Council unanimously adopted Allen 2045 Plan (April 2025) which includes
-- multimodal language. However Schaeffer's stated priorities are road/infrastructure focused
-- without specific multimodal commitments. Aligns with value 3: maintain roads while
-- selectively adding connections where density supports it.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a0ecf6-b416-474b-9647-a25e404f4bc4', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign materials and council votes: Schaeffer''s campaign cited aging road infrastructure and highway 121 corridor development as priorities. The full council unanimously adopted the Allen 2045 Comprehensive Plan (April 2025), which includes multimodal transportation strategies; however Allen is a car-dependent suburb with no transit infrastructure. Aligns with answer 3 (maintain roads while selectively adding transit/pedestrian improvements where density supports it) — pragmatic road-first approach with openness to selective multimodal investment.',
  ARRAY['https://www.mike4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- TOMMY BARIL — Council Place 2
-- ID: 3b15d821-fc1e-4e7b-bda0-13a669a77a27
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Baril chaired the Allen Downtown Steering Committee which recommended mixed-use housing
-- with targeted density (4-story with step-up transitions) and served as Allen CDC president.
-- Emphasizes "affordable quality of life" without public housing or rent controls.
-- Aligns with value 3: targeted assistance, easier permits, mixed-use near corridors.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from public statements: As Allen Downtown Steering Committee chair, Baril noted "diversity" of housing demand and helped design a mixed-use plan with step-up density (townhomes to 4-story) near corridors while protecting adjacent single-family neighborhoods. He served as Allen CDC president focusing on community development without public housing programs. Aligns with answer 3 (targeted assistance, first-time buyer support, easier permits) rather than rent caps or full market reliance.',
  ARRAY['https://candysdirt.com/2022/08/09/allen-leaders-seek-to-revive-citys-heart-with-more-housing-options-and-revitalization/',
        'https://tommy4allen.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: tommy4allen.com, cityofallen.org, candysdirt.com, starlocalmedia.com, communityimpact.com. Allen has no significant homelessness policy debate; no statements from Baril on this topic found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Baril led development of Allen Downtown Code allowing mixed-use and up to 4-story housing
-- near corridors with step-up transitions protecting adjacent single-family neighborhoods.
-- Council approved Downtown rezoning Jan 2023. Aligns with value 3: allow multifamily near
-- commercial corridors while protecting most residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from public statements and committee work: As Downtown Steering Committee chair, Baril designed the mixed-use zoning framework that allows up to 4-story buildings near corridors while requiring step-up transitions to protect adjacent single-family neighborhoods. He acknowledged "significant support for more housing downtown, but also significant concern about impacts to adjacent single-family neighborhoods." City Council unanimously approved the Downtown District rezoning Jan 2023. Matches answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://candysdirt.com/2022/08/09/allen-leaders-seek-to-revive-citys-heart-with-more-housing-options-and-revitalization/',
        'https://www.cityofallen.org/CivicAlerts.aspx?AID=4930'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: tommy4allen.com, cityofallen.org, candysdirt.com, legistorm.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Baril advocates for well-resourced emergency services with "funding, training, tools and
-- staffing" for first responders. City budget consistently adds police/fire positions.
-- Aligns with value 4: increase police staffing, equipment, and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Baril explicitly supports adequate "funding, training, tools and staffing" for first responders to maintain Allen as "one of the safest communities in the state." He is a member of Allen CERT. The council consistently approves budgets adding police and fire positions. Aligns with answer 4 (increase police staffing, equipment, and pay). No mention of mental health co-responders or budget redirection found.',
  ARRAY['https://tommy4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-city-council-to-add-new-public-safety-staff-in-new-approved-budget/article_4a89bfbe-531f-11ee-bf82-ef9c66531def.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: tommy4allen.com, cityofallen.org, starlocalmedia.com. No statements or votes on ICE cooperation or immigration enforcement policy found for Baril.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Baril served as Allen CDC president, supports economic development tools, and the full
-- council (with Baril absent due to travel) unanimously approved the Kalahari incentive deal.
-- Allen legislative agenda supports TIFs, Chapter 380 agreements, and Texas Enterprise Fund.
-- Aligns with value 4: compete actively for major employers with significant tax abatements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from service record and city policy: Baril served as Allen CDC president, supporting public-private partnerships for development. He supports "new facilities and amenities" in a "fiscally prudent manner." Allen''s legislative agenda (which the council adopted) explicitly supports protecting EDC tools including TIFs and Chapter 380 agreements. Note: Baril was absent from the Feb 25, 2025 Kalahari incentive vote, but his overall record supports competitive incentives. Aligns with answer 4.',
  ARRAY['https://tommy4allen.com/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php',
        'https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Baril's campaign emphasized "new facilities and amenities while addressing aging
-- infrastructure in a fiscally prudent manner." Council unanimously adopted Allen 2045
-- Plan with multimodal language. No specific transit or bike lane advocacy found.
-- Aligns with value 3: maintain roads while selectively adding improvements where density supports it.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b15d821-fc1e-4e7b-bda0-13a669a77a27', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign materials and council votes: Baril emphasizes addressing aging infrastructure while adding new amenities. The full council unanimously adopted the Allen 2045 Comprehensive Plan (April 2025) which includes multimodal transportation strategies for a city transitioning from rapid expansion to redevelopment. No specific advocacy for bike lanes, transit, or pedestrian-first policies found. Aligns with answer 3 (maintain roads while selectively adding transit connections and pedestrian improvements where density supports it).',
  ARRAY['https://tommy4allen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- KEN COOK — Council Place 3
-- ID: 8626a6f8-88c9-456e-b484-499ac8849441
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Cook's 2024 campaign: "provide achievable housing without large-density apartments" and
-- "work with EDC to grow commercial tax base." No public housing or rent cap advocacy.
-- Aligns with value 3-4; closer to 4 given explicit rejection of density and reliance
-- on market-driven growth with targeted permit easing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Cook stated he wants to "provide achievable housing without large-density apartments" and emphasizes growing the commercial tax base rather than housing programs. He served on the P&Z Commission (2021-2024) reviewing development applications under existing market-driven rules. No support for public housing, rent caps, or significant subsidies found. Aligns with answer 4 (cut regulations so private developers can build more housing) — he wants more housing supply but through market mechanisms rather than government programs.',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, communityimpact.com. No statements from Cook on homelessness policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Cook explicitly ran on "providing achievable housing without large-density apartments" and
-- envisions a "vibrant downtown with mixed-use living, green spaces, dining, retail, entertainment."
-- This indicates support for mixed-use near corridors (not broad upzoning). Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign statements: Cook said he wants to "provide achievable housing without large-density apartments" and envisions a "vibrant downtown with mixed-use living, green spaces, dining, retail, and entertainment." He served on the P&Z Commission (2021-2024) applying Allen''s zoning code which concentrates multifamily near commercial corridors. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, communityimpact.com, KenCookforAllen Facebook. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Cook's campaign: "never divert funds to appease small groups" and "keep taxes low."
-- City budget adds police/fire positions each cycle; Allen legislative agenda supports
-- qualified immunity and strong law enforcement. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Cook stated he would "never divert funds to appease small groups" (a reference to reallocation away from police) and supports keeping budgets stable. Allen''s city legislative agenda explicitly supports "strong law enforcement" with qualified immunity protections. The council consistently approves budgets adding police and fire positions. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times and deter crime).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, communityimpact.com. No statements from Cook on immigration enforcement policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Cook: "work with EDC to attract businesses to Allen; grow commercial tax base."
-- Supported the Kalahari incentive deal (voted in favor, Feb 2025). Allen legislative
-- agenda supports all major EDC incentive tools. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign statements and council votes: Cook''s campaign emphasized working "with EDC to attract businesses to Allen" and growing the commercial tax base. He voted with the full council to approve the Kalahari Resort ($950M) performance-based incentive deal (Feb 2025). Allen''s legislative agenda supports TIFs, Chapter 380 agreements, and Texas Enterprise Fund. Aligns with answer 4 (compete actively for major employers with significant tax abatements).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html',
        'https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- No specific transportation stance found. Council adopted Allen 2045 Plan unanimously.
-- No dedicated transport advocacy found for Cook; prior P&Z work focused on land use.
-- Aligns with value 3 based on city-wide approach.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8626a6f8-88c9-456e-b484-499ac8849441', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from council votes: Cook voted with the full council to unanimously adopt the Allen 2045 Comprehensive Plan (April 2025), which includes multimodal transportation strategies. His campaign focused on land use and EDC; no specific transportation advocacy found. Allen is car-dependent; plan supports selective multimodal investment. Aligns with answer 3 (maintain roads while selectively adding transit connections and pedestrian improvements where density supports it).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- AMY GNADT — Council Place 4
-- ID: b0a9801c-7f9d-4d7b-99f5-09360cf69c08
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Gnadt ran on "preserving Allen's strong sense of community while supporting smart growth."
-- No public housing, rent caps, or subsidy advocacy found. 12+ years on Allen ISD Board
-- focused on educational excellence. Aligns with general city approach of market-driven
-- growth with targeted assistance = value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from general candidate profile: Gnadt ran on "preserving Allen''s strong sense of community while supporting smart growth" and "public services." She served 12+ years on Allen ISD Board focused on educational excellence. No housing-specific statements found beyond general "smart growth" framing. The city provides housing assistance through CDBG and targeted subsidies. Aligns with answer 3 (targeted help, first-time buyer assistance, easier building permits) as the default moderate-conservative suburban position consistent with Allen''s overall approach.',
  ARRAY['https://collincountyvotes.com/allen-may-2025-local-election-recap/',
        'https://www.cityofallen.org/business_detail_T4_R83.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: cityofallen.org, collincountyvotes.com, starlocalmedia.com, ballotpedia.org. No statements from Gnadt on homelessness policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- No specific zoning stance found. Gnadt supports "smart growth" and ran unopposed.
-- Council voted unanimously on Jan 2026 zoning changes including commercial and single-family
-- approvals. No high-density opposition or upzoning advocacy found. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from general candidate profile and council votes: Gnadt supports "smart growth" without specific zoning advocacy found. She voted with the council on Jan 2026 zoning changes (unanimous for two of three items; 5-2 for a commercial rezoning). No high-density opposition or broad upzoning advocacy found. Aligns with answer 3 (allow multifamily near commercial corridors while protecting most residential zones) consistent with Allen''s adopted zoning framework.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/allen/government/2026/01/29/check-out-3-zoning-changes-approved-by-allen-city-council/',
        'https://collincountyvotes.com/allen-may-2025-local-election-recap/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: cityofallen.org, collincountyvotes.com, starlocalmedia.com, ballotpedia.org. No statements from Gnadt on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Gnadt supports "public services" generally; city adds police positions each budget cycle.
-- No mental health co-responder or budget reallocation advocacy found. Aligns with value 4
-- based on Allen's consistent pro-police budget record and legislative advocacy.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from general profile and city-wide record: Gnadt supports "public services" including public safety. Allen''s city budgets consistently add police and fire positions; the $97M police headquarters was built during her time as a public official in Allen. Allen''s legislative agenda supports qualified immunity and strong law enforcement. No mental health co-responder or budget reallocation statements found. Aligns with answer 4 (increase police staffing, equipment, and pay).',
  ARRAY['https://collincountyvotes.com/allen-may-2025-local-election-recap/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: cityofallen.org, collincountyvotes.com, starlocalmedia.com. No statements from Gnadt on immigration enforcement policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Gnadt voted with the full council to approve the Kalahari Resort incentive deal (Feb 2025,
-- declared elected unopposed March 2025 — she voted in Feb as incumbent). Allen legislative
-- agenda supports all major EDC incentive tools. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council votes: Gnadt voted with the council (unanimously, Tommy Baril absent) to approve the Kalahari Resort ($950M) performance-based incentive deal on Feb 25, 2025. Allen''s legislative agenda explicitly protects EDC tools including TIFs, Chapter 380 agreements, and Texas Enterprise Fund. Aligns with answer 4 (compete actively for major employers with significant tax abatements).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Gnadt voted with the full council to adopt Allen 2045 Plan unanimously (April 2025).
-- No specific transportation advocacy found. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0a9801c-7f9d-4d7b-99f5-09360cf69c08', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from council votes: Gnadt voted with the full council to unanimously adopt the Allen 2045 Comprehensive Plan (April 2025), which includes multimodal transportation strategies. No specific transportation advocacy found. Aligns with answer 3 (maintain roads while selectively adding transit and pedestrian improvements where density supports it).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- CARL CLEMENCICH — Council Place 5
-- ID: f72c8a0c-61dd-4a86-a205-171e331fcaee
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Clemencich's 2024 campaign: "significant property tax relief through balanced growth
-- and commercial development." His approach is tax-base expansion driven, not housing
-- programs. No public housing or rent cap advocacy. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Clemencich''s 2024 campaign prioritized "significant property tax relief through balanced growth and commercial development." His approach to housing access is through tax relief and commercial expansion rather than subsidies or public programs. He focused on infrastructure balance and responsible buildout. No support for public housing, rent caps, or housing subsidies found. Aligns with answer 4 (cut regulations so private developers can build more housing, letting market determine supply).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html',
        'https://carl4allen.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, carl4allen.com, communityimpact.com. No statements from Clemencich on homelessness policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Clemencich supports "responsible buildout along Highway 121" and "appropriate in-fill
-- development." He does not advocate broad upzoning or oppose all density. His previous
-- council term (2017-2023) included unanimous votes on mixed-use zoning. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from campaign statements and prior council record: Clemencich supports "responsible buildout along Highway 121" and "appropriate in-fill development." During his previous council term (2017-2023), the Allen council unanimously approved mixed-use zoning for The Farm and Gateway projects (2022). He does not advocate for broad upzoning citywide. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html',
        'https://hoodline.com/2024/06/allen-welcomes-ken-cook-and-carl-clemencich-to-city-council-in-civic-transition-ceremony/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, carl4allen.com, communityimpact.com. No statements or votes on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Clemencich served on Allen City Council 2017-2023 when the $97M police HQ was approved
-- and public safety budgets consistently expanded. No reallocation or co-responder advocacy.
-- Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from service record: Clemencich served on Allen City Council from 2017-2023 (6 years) during which the $97M police headquarters was approved and annual budgets added public safety staff. He returned in 2024 continuing the same approach. Allen''s legislative agenda supports qualified immunity and strong law enforcement. No mental health co-responder or reallocation advocacy found. Aligns with answer 4 (increase police staffing, equipment, and pay).',
  ARRAY['https://hoodline.com/2024/06/allen-welcomes-ken-cook-and-carl-clemencich-to-city-council-in-civic-transition-ceremony/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: starlocalmedia.com, cityofallen.org, carl4allen.com. No statements from Clemencich on immigration enforcement policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Clemencich voted with the full council to approve the Kalahari Resort incentive deal
-- (Feb 2025). During his 2017-2023 council term Allen approved multiple corporate recruitment
-- deals. His campaign emphasized growing the commercial tax base. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign statements and council votes: Clemencich voted with the full council to approve the Kalahari Resort ($950M) performance-based incentive deal (Feb 2025). During his 2017-2023 council tenure, Allen approved multiple EDC-driven corporate recruitment packages. His 2024 campaign emphasized growing the commercial tax base through balanced development. Allen''s legislative agenda supports TIFs, Chapter 380 agreements, and Texas Enterprise Fund. Aligns with answer 4.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/',
        'https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Clemencich voted unanimously with council on Allen 2045 Plan (April 2025). His campaign
-- focused on balancing new projects with infrastructure maintenance. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f72c8a0c-61dd-4a86-a205-171e331fcaee', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign statements and council votes: Clemencich''s campaign emphasized "balancing new projects with maintenance and replacement of aging infrastructure." He voted with the full council to unanimously adopt the Allen 2045 Comprehensive Plan (April 2025) which includes multimodal transportation strategies. No specific transit, bike lane, or pedestrian-priority advocacy found. Aligns with answer 3 (maintain roads while selectively adding improvements where density supports it).',
  ARRAY['https://starlocalmedia.com/allenamerican/news/allen-city-council-election-preview-2024-meet-your-candidates/article_91c1aa52-fd0d-11ee-b735-47cfa1679400.html',
        'https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- BEN TRAHAN — Council Place 6 / Mayor Pro Tem
-- ID: 0c983f9c-b510-4c70-a6b3-dc328b68b1f5
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Trahan: "does not support federally funded affordable housing in Allen" but supports
-- "housing solutions that meet the needs of families across several levels of household income."
-- He mentions CDBG and county/state/federal subsidies as acceptable targeted tools.
-- Aligns with value 3: targeted subsidies and assistance, not public housing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from candidate statements: Trahan stated he "does not support federally funded affordable housing in Allen" but does support "housing solutions that meet the needs of families across several levels of household income." He noted the city provides assistance through CDBG and potential subsidies through county, state and federal agencies. This matches answer 3 (targeted help — subsidies, first-time buyer assistance, easier permits) rather than public housing or rent caps. He rejects top-down federal programs but supports targeted local assistance.',
  ARRAY['https://www.trahanforallen.com/',
        'https://starlocalmedia.com/allenamerican/place-4-place-6-spots-on-allen-city-council-each-get-two-candidates-for-may/article_0d8d9df2-911e-11ec-ac74-c7ab352779ab.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: trahanforallen.com, cityofallen.org, starlocalmedia.com, communityimpact.com. Allen has no significant homelessness policy debate; no statements from Trahan on this topic found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- As P&Z Chair (2019-2022) Trahan voted in favor of multifamily/mixed-use near corridors
-- (including high-density projects) while acknowledging neighborhood concerns. He advocated
-- for "step-up" transitions and mixed-use over purely residential density. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from P&Z service and campaign statements: As P&Z Chair (2019-2022) Trahan voted in favor of multifamily/high-density development proposals near corridors while noting citizen concerns. His downtown vision calls for "thoughtful design and attraction of the types of retail, work and live elements." He supports development with community input rather than blanket upzoning or strict protection. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://www.trahanforallen.com/topics',
        'https://texasscorecard.com/local/allen-officials-ignore-residents-concerns-about-high-density-development/',
        'https://candysdirt.com/2022/08/09/allen-leaders-seek-to-revive-citys-heart-with-more-housing-options-and-revitalization/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: trahanforallen.com, cityofallen.org, starlocalmedia.com, communityimpact.com. No statements from Trahan on civil rights enforcement or equity programs found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Trahan states the city should "fully fund parks and recreation, public safety, and
-- infrastructure." Supported $97M police HQ bond. No reallocation or co-responder advocacy.
-- Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements and council record: Trahan states the city should seek to "fully fund parks and recreation, public safety, and infrastructure." He supported the $97M police headquarters facility during his P&Z and council tenure. Allen''s legislative agenda supports qualified immunity and strong law enforcement. No mental health co-responder or budget reallocation statements found. Aligns with answer 4 (increase police staffing, equipment, and pay to improve response times and deter crime).',
  ARRAY['https://www.trahanforallen.com/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: trahanforallen.com, cityofallen.org, starlocalmedia.com. No statements from Trahan on immigration enforcement policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Trahan voted with the full council to approve the Kalahari Resort incentive deal (Feb 2025).
-- He served on P&Z 2011-2022 during multiple EDC corporate recruitment approvals.
-- Allen legislative agenda supports all major EDC incentive tools. Aligns with value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council votes and service record: Trahan voted with the full council to approve the Kalahari Resort ($950M) performance-based incentive deal (Feb 2025). He served on P&Z Commission (2011-2022) during multiple Allen EDC corporate recruitment approvals. Allen''s legislative agenda protects EDC tools including TIFs, Chapter 380 agreements, and Texas Enterprise Fund. Aligns with answer 4 (compete actively for major employers with significant tax abatements).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/allen/development/2025/02/25/kalahari-could-open-proposed-allen-location-by-2030/',
        'https://www.cityofallen.org/government/city_council/legislative_agenda.php'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Trahan's campaign website mentions "new development" as a volunteer focus area and supports
-- infrastructure investment. He voted unanimously with council on Allen 2045 Plan (April 2025).
-- No specific transit or bike lane advocacy found. Aligns with value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c983f9c-b510-4c70-a6b3-dc328b68b1f5', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from council votes: Trahan voted with the full council to unanimously adopt the Allen 2045 Comprehensive Plan (April 2025), which includes multimodal transportation strategies. His campaign emphasizes infrastructure investment and community development. No specific transit, bike lane, or pedestrian-priority advocacy found. Aligns with answer 3 (maintain roads while selectively adding transit connections and pedestrian improvements where density supports it).',
  ARRAY['https://www.trahanforallen.com/',
        'https://starlocalmedia.com/allenamerican/news/allen-2045-comprehensive-plan-to-appear-before-city-council-april-29/article_d51b76e4-aae0-459a-b306-7cd0cc23e751.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

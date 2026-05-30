BEGIN;

-- EUGENE ESCOBAR — Mayor
-- ID: 08cf69c5-1bd4-484f-88c8-8edd05a1b821
-- Research date: 2026-05-11
-- Sources: keranews.org/news/2024-12-16, spectrumlocalnews.com/tx/.../princeton-mayor-extends-moratorium-,
--          wfaa.com/article/news/local/collin-county/princeton-pauses-residential-growth,
--          princetonherald.com/2025/01/02/mayor-escobar-takes-the-helm/

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Escobar''s campaign and mayoral statements focus on growth management and infrastructure but do not address affordable housing policy or any of the specific answer options. Checked: keranews.org, wfaa.com, spectrumlocalnews.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found regarding homelessness policy or public camping enforcement. Checked: keranews.org, wfaa.com, spectrumlocalnews.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
-- Value 2: Allow modest density increases with strong design review and neighborhood input
-- Escobar ran on and enacted a moratorium on all new residential development citing infrastructure overflow,
-- stating Princeton must focus on quality housing with "thoughtful land-use planning" and "responsible growth"
-- before accommodating more density. This is consistent with Answer 2 (modest density with design review/input),
-- not upzoning or open development. He explicitly opposed the developer-growth-first approach (Answer 4/5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Escobar campaigned against rapid uncontrolled residential growth, stating "the city was more focused on growing and bringing in developers" without understanding consequences. As mayor he enacted and extended a moratorium on new residential development to allow time for "thoughtful land-use planning" and infrastructure-first growth management. His official vision emphasizes "preserving Princeton as a family-friendly community" with controlled growth and "strong sense of place." This aligns with Answer 2: allow modest density with design review and neighborhood input, as opposed to broad upzoning.',
  ARRAY['https://www.keranews.org/news/2024-12-16/princeton-voters-elect-mayoral-candidate-who-raised-concerns-about-rapid-growth-oust-incumbent',
        'https://spectrumlocalnews.com/tx/dallas-fort-worth/news/2025/09/04/princeton-mayor-extends-moratorium-',
        'https://www.princetontx.gov/721/Office-of-the-Mayor'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: keranews.org, wfaa.com, spectrumlocalnews.com, princetonherald.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
-- Value 4: Increase police staffing, equipment, and pay to improve response times and deter crime
-- Escobar explicitly stated the city needed 30 additional police officers; identified public safety as his
-- "main concern"; cited hiring more police as a primary goal of the moratorium period.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Escobar stated his primary concern as mayor is public safety, and explicitly cited the need for 30 additional police officers as a core reason for the residential development moratorium. He framed the pause in growth as necessary to "strengthen public safety, repair roads, and ensure our infrastructure can handle the influx of new residents." City materials describe him "building a safer, stronger Princeton" through expanded police and fire services. This aligns with Answer 4: increase police staffing, equipment, and pay to improve response times.',
  ARRAY['https://spectrumlocalnews.com/tx/dallas-fort-worth/news/2025/09/04/princeton-mayor-extends-moratorium-',
        'https://www.keranews.org/news/2024-12-10/former-small-towns-growing-pains-lead-to-tensions-in-mayoral-runoff-election',
        'https://www.nbcdfw.com/news/local/princeton-temporarily-stops-housing-rapid-growth-strains-infrastructure/3653076/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
-- Value 4: Compete actively for major employers with significant tax abatements and infrastructure investment
-- Princeton under Escobar maintains an active EDC offering property tax abatements up to 100% for 10 years
-- and Chapter 380 sales tax rebates. The city''s stated goal is "purposeful economic growth" through
-- incentive-based business recruitment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Princeton''s EDC, which Escobar oversees as mayor, offers property tax abatements up to 100% for up to 10 years and Chapter 380 sales tax rebates to recruit businesses on a case-by-case basis. The city''s stated approach is to "stimulate and encourage purposeful economic growth through new business development, relocation assistance, and expansions." Escobar''s official platform includes "supporting local businesses" and intentional commercial development. The moratorium specifically exempted commercial projects. This aligns with Answer 4: compete actively for major employers with significant tax abatements and infrastructure investment.',
  ARRAY['https://princetonedc.com/why-princeton/incentives',
        'https://princetonedc.com/business-resources/incentives/tax-abatement',
        'https://www.princetontx.gov/298/Economic-Development-Corporation'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. While road congestion on Highway 380 is a known city issue, no specific transportation policy positions or investment priorities are attributable to Escobar by literal statement. Checked: keranews.org, wfaa.com, spectrumlocalnews.com, princetonherald.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08cf69c5-1bd4-484f-88c8-8edd05a1b821', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement posture. Checked: keranews.org, wfaa.com, spectrumlocalnews.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- TERRANCE JOHNSON — Council Member Place 1
-- ID: eb9f2322-ec6b-42f0-9939-e58cd0b843a9
-- Research date: 2026-05-11
-- Sources: keranews.org/news/2024-11-04, keranews.org/news/2024-12-10,
--          dallasobserver.com/news/collin-county-is-booming, princetontx.gov/732/Terrance-Johnson

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy, subsidies, rent caps, or public housing. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness policy or public camping enforcement. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Johnson expressed concern the residential moratorium "sends the wrong message" to commercial developers, but this is about commercial development signals rather than a stated position on residential zoning philosophy or density. No literal match to any answer option found. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Background notes his history as first African American EDC chair but no policy stances found. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No specific public safety policy positions found. General acknowledgment of infrastructure strain including police shortfall but no stated position on police funding levels or alternatives. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
-- Value 4: Compete actively for major employers with significant tax abatements and infrastructure investment
-- Johnson served as EDC Board Chair and was its first African American chairman. He expressed concern that
-- the housing moratorium "sends the wrong message" to commercial developers. He explicitly prioritized
-- bringing major commercial employers (grocery stores, movie theaters) to Princeton and actively supports
-- the EDC''s incentive programs.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Johnson served as chair of the Princeton EDC (first African American chairman) before joining city council, where he now serves as Council Liaison to the EDC. He expressed concern that the residential moratorium "sends the wrong message" to commercial developers, stating "Does it say that we''re not prepared or we don''t welcome development?" He explicitly named a grocery store and movie theater as top priorities for business recruitment. He supports the EDC''s active incentive programs including tax abatements. This aligns with Answer 4: compete actively for major employers with significant tax abatements and infrastructure investment.',
  ARRAY['https://www.keranews.org/news/2024-12-10/former-small-towns-growing-pains-lead-to-tensions-in-mayoral-runoff-election',
        'https://www.dallasobserver.com/news/collin-county-is-booming-princeton-new-housing-cant-keep-up-21081057/',
        'https://princetontx.gov/732/Terrance-Johnson'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Johnson noted that rush hours on Highway 380 take 30-45 minutes, acknowledging traffic congestion as a problem, but made no specific policy statement about transportation investment priorities that matches any answer option literally. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eb9f2322-ec6b-42f0-9939-e58cd0b843a9', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: keranews.org, dallasobserver.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- CRISTINA TODD — Council Member Place 2
-- ID: 3c8d7283-2387-47ff-8a29-1ef7a1e2a554
-- Research date: 2026-05-11
-- Sources: ballotpedia.org/Cristina_Todd, princetontx.new.swagit.com/videos/335687,
--          princetonherald.com/2024/11/21/new-members-join-council/

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy. Checked: ballotpedia.org, princetontx.new.swagit.com (Feb 2025 meeting), princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness or public camping policy. Checked: ballotpedia.org, princetontx.new.swagit.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. At the February 2025 council meeting Todd expressed concern about HOA documents lacking clarity for residents and requested "resident friendly language," but this does not constitute a stated position on residential zoning philosophy or density. Checked: ballotpedia.org, princetontx.new.swagit.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: ballotpedia.org, princetontx.new.swagit.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No specific public safety policy positions found. Checked: ballotpedia.org, princetontx.new.swagit.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. No specific economic development incentive positions found. General transparency/accountability platform only. Checked: ballotpedia.org, princetontx.new.swagit.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No transportation policy positions found. Checked: ballotpedia.org, princetontx.new.swagit.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: ballotpedia.org, princetontx.new.swagit.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- BRYAN WASHINGTON — Council Member Place 3
-- ID: e40be594-2239-4c28-a8ac-d4f86c6d4180
-- Research date: 2026-05-11
-- Sources: wash4council.com, princetontx.gov/722/Council-Members,
--          facebook.com/CityofPrincetonTX, princetontx.gov/m/newsflash/home/detail/471

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy. Checked: wash4council.com, princetontx.gov, facebook.com/CityofPrincetonTX.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness policy or public camping enforcement. Checked: wash4council.com, princetontx.gov, facebook.com/CityofPrincetonTX.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Washington''s focus is on parks, youth sports, and supporting local businesses. No explicit residential zoning philosophy statements found. Checked: wash4council.com, princetontx.gov, facebook.com/CityofPrincetonTX.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: wash4council.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No specific public safety funding or policy positions found. Checked: wash4council.com, princetontx.gov, facebook.com/CityofPrincetonTX.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Washington serves as CDC liaison and supports growing businesses and job creation, but no specific stance on incentive programs, tax abatements, or economic development approach found that matches a specific answer option. Checked: wash4council.com, princetontx.gov, facebook.com/CityofPrincetonTX.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No transportation policy positions found. Checked: wash4council.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: wash4council.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- STEVEN DEFFIBAUGH — Council Member Place 5
-- ID: 7ccb8074-3d74-4493-9eb9-528ac48fea47
-- Research date: 2026-05-11
-- Sources: princetonherald.com/2023/10/12/place-5-city-council-candidate-steven-deffibaugh/,
--          nbcdfw.com/news/local/princeton-extends-moratorium, princetontx.gov/736/Steven-Deffibaugh

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness policy or public camping enforcement. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
-- Value 2: Allow modest density increases with strong design review and neighborhood input
-- Deffibaugh supported the moratorium on residential development, stating it "gives us time to look at the
-- infrastructure, especially for providing water and sewer services." This infrastructure-first approach
-- before allowing more density aligns with Answer 2 (allow modest density with design review and input),
-- not broad upzoning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Deffibaugh has served on Princeton City Council since 2010 and supported the residential development moratorium, stating it "gives us time to look at the infrastructure, especially for providing water and sewer services because that''s one of the things we need to do." He also noted the number of homes has "outpaced city services." His long record of managing Princeton''s planned growth and infrastructure-first approach to development aligns with Answer 2: allow modest density increases with design review and neighborhood input, rather than broad upzoning or laissez-faire development.',
  ARRAY['https://www.nbcdfw.com/news/local/collin-county-city-temporary-new-residential-developments/3742323/',
        'https://princetonherald.com/2023/10/12/place-5-city-council-candidate-steven-deffibaugh/',
        'https://princetontx.gov/736/Steven-Deffibaugh'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
-- Value 4: Increase police staffing, equipment, and pay to improve response times and deter crime
-- Deffibaugh noted increased population leads to more police and fire calls and cited the city hiring
-- more personnel. He has been on council since 2010 and repeatedly supported public safety staffing increases.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Deffibaugh stated that increased population leads to more police and fire department calls and that the city is "in the process of hiring more personnel." He supported the residential moratorium in part to allow time to address public safety staffing shortfalls, noting the police shortage (30 officers needed) as an infrastructure problem requiring correction. His background includes law enforcement experience. This aligns with Answer 4: increase police staffing to improve response times.',
  ARRAY['https://www.nbcdfw.com/news/local/collin-county-city-temporary-new-residential-developments/3742323/',
        'https://princetonherald.com/2023/10/12/place-5-city-council-candidate-steven-deffibaugh/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. No specific statements on economic development incentives or tax abatements beyond general support for city growth. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No transportation policy positions found. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7ccb8074-3d74-4493-9eb9-528ac48fea47', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: princetonherald.com, nbcdfw.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- BEN LONG — Council Member Place 6
-- ID: ec68cd34-0756-4c12-89b9-d1b483cf08e8
-- Research date: 2026-05-11
-- Sources: vote4benlong.com, dallasexpress.com/metroplex/princeton-city-council-candidates-pitch-to-voters/,
--          princetonherald.com/2023/11/07/council-incumbents-re-elected-new-seats-go-to-long-david-graves/,
--          princetontx.new.swagit.com/videos/335687

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy, subsidies, or rent assistance. Checked: vote4benlong.com, dallasexpress.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness policy or public camping enforcement. Checked: vote4benlong.com, dallasexpress.com, princetonherald.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. At the February 2025 meeting Long suggested "phasing improvements for residential building standards," indicating a quality-focused approach, but this does not map to a specific zoning philosophy answer option. Checked: dallasexpress.com, princetontx.new.swagit.com, princetonherald.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: vote4benlong.com, dallasexpress.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No specific public safety policy positions found. Checked: vote4benlong.com, dallasexpress.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Long advocates for more retail and restaurants and for City Hall to provide resources to economic development entities, but his statements focus on community engagement and transparency rather than a specific incentive policy position. No literal match to any answer option. Checked: dallasexpress.com, vote4benlong.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
-- Value 4: Focus on road capacity and traffic flow; transportation investment should serve the majority who drive
-- Long explicitly identified roads as residents'' "#1 concern" and called for repairing/rebuilding old roadways
-- and creating additional roads for traffic growth. He noted Highway 380 is "becoming more dangerous" and
-- congested, and called for City Hall to focus on road investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'In his campaign platform, Long stated roads and infrastructure are his third priority and that many residents identified this as their "#1 concern." He called for City Hall to focus on "repairing and rebuilding the old roadways" plus creating additional roads for traffic growth, noting Highway 380 is "becoming more and more dangerous" and "congested." His platform emphasizes road capacity for vehicles with no mention of transit, bike lanes, or pedestrian infrastructure. This aligns with Answer 4: focus on road capacity and traffic flow; transportation investment should serve the majority who drive.',
  ARRAY['https://dallasexpress.com/metroplex/princeton-city-council-candidates-pitch-to-voters/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ec68cd34-0756-4c12-89b9-d1b483cf08e8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: vote4benlong.com, dallasexpress.com, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- CAROLYN DAVID-GRAVES — Council Member Place 7
-- ID: 2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a
-- Research date: 2026-05-11
-- Sources: vote4cdgraves.com, princetonherald.com/2023/10/12/place-7-city-council-candidate-carolyn-david-graves/,
--          facebook.com/CityofPrincetonTX, princetontx.new.swagit.com/videos/335687

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No statements found on affordable housing policy, subsidies, or rent assistance. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. No statements found on homelessness policy or public camping enforcement. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
-- Value 4: Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
-- David-Graves explicitly stated "we need to be a developer-friendly community" at a housing standards
-- meeting. This statement directly matches the pro-development/streamlined-approvals orientation of Answer 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'At a February 2025 housing standards council meeting, David-Graves stated "we need to be a developer-friendly community." Her campaign platform also identified the dual challenge of "developing the city''s infrastructure to accommodate the growing population while balancing economic development," indicating support for continued growth and development. Her statement sparked public pushback from a resident who called the council "developer-friendly" rather than "resident-friendly." This aligns with Answer 4: upzone broadly and streamline approvals, favoring developer-side policies.',
  ARRAY['https://princetontx.new.swagit.com/videos/335687',
        'https://princetonherald.com/2023/10/12/place-7-city-council-candidate-carolyn-david-graves/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No statements found on civil rights enforcement, racial equity, or affirmative action. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No specific public safety funding or policy positions found. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. While David-Graves expressed a pro-developer orientation in housing standards discussions, no specific statements on economic development incentives, tax abatements, or business recruitment strategy were found that map to a specific answer option. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No transportation policy positions found. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b828401-75d7-4fb4-a3f6-ad1c6f39cc2a', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. No statements found on ICE cooperation, sanctuary policy, or immigration enforcement. Checked: princetonherald.com, facebook.com/CityofPrincetonTX, princetontx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

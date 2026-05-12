BEGIN;

-- =============================================================================
-- Migration 137: Plano, TX City Council — Local Lens Compass Stances
-- Researched: 2026-05-11
-- Politicians: John B. Muns, Maria Tu, Bob Kehr, Rick Horne,
--              Chris Krupa Downs, Steve Lavine, Shun Thomas, Vidal Quintanilla
-- Topics: 8 Local Lens topics
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- JOHN B. MUNS — Mayor
-- politician_id: 5584e869-4a54-4a68-a3c8-c14db45a71c5
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Muns supports targeted mixed-income redevelopment ("we must encourage some affordable
-- housing, both low-density and higher-density, depending on the location and zoning")
-- and praised Park on 14th (80% AMI project). Supports infill/redevelopment, not direct
-- public provision. Matches: "Offer targeted help like subsidies for affordable projects,
-- first-time buyer assistance, and easier building permits."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from public statements: Muns stated the city "must encourage some affordable housing, both low-density and higher-density, depending on the location and zoning" and publicly praised the Park on 14th apartments (80% AMI project) as "critical to the city''s growth." He supports targeted subsidies and infill redevelopment rather than direct public housing or broad rent controls. Former Planning & Zoning Chair; philosophy is case-by-case targeted support. Value 3: targeted subsidies and easier permits.',
  ARRAY['https://www.bisnow.com/dallas-ft-worth/news/commercial-real-estate/plano-chooses-former-pz-chair-john-muns-for-next-mayor-108730',
        'https://www.wfaa.com/article/news/local/collin-county/all-affordable-units-snapped-up-planos-new-park-14th-apartments/287-712647db-7de0-48f2-a485-31a9fb9aa831',
        'https://planomagazine.com/plano-mayor-john-muns/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Muns stating a specific position on homeless camping enforcement. Plano has a Crisis Intervention Team program and receives HUD homelessness grants, but no council vote or mayoral statement matching a specific stance description was found. Checked: plano.gov, Plano Magazine, Community Impact, Bisnow, WFAA, KERA.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 3
-- Muns stated it "would be irresponsible" not to update Plano ordinances in response
-- to SB 840 (allowing multifamily by right in nonresidential zones). Supports
-- multifamily near commercial corridors while protecting residential neighborhoods.
-- Matches: "Allow multifamily and mixed-use near commercial corridors while protecting
-- most residential zones."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from council action and public statement: Mayor Muns said it "would be irresponsible for the city to allow development in areas affected by SB 840 without updating Plano''s local ordinances" — he led compliance with the Texas law allowing multifamily by right in nonresidential zones. Also on record supporting varied housing options and redevelopment of older neighborhoods, while maintaining traditional low-density residential areas. Position reflects allowing density near commercial corridors while protecting residential zones. Value 3.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2025/08/27/plano-council-approves-development-zoning-changes-due-to-new-state-laws/',
        'https://communityimpact.com/dallas-fort-worth/plano-south/government/2025/07/22/plano-officials-anticipate-impacts-to-residential-development-standards-following-texas-legislature-session/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Muns taking a specific position on racial equity, affirmative action, or civil rights enforcement at the local level. Plano has an existing Equal Rights Ordinance but no mayoral statements on strengthening or limiting it were found. Checked: plano.gov, Community Impact, Plano Magazine, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Muns consistently frames public safety as a top city priority. Has emphasized
-- Plano's competitive advantage is its safety and quality of life; supports
-- "continuing to improve" public safety. Matches: "Increase police staffing,
-- equipment, and pay to improve response times and deter crime."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from public statements: Muns consistently identifies Plano''s safety as a core competitive asset for business attraction, stating the city must "keep the community safe" to remain a desirable relocation destination. His platform emphasizes continued investment in public safety services. No record of supporting police budget cuts or social-service redirections. Plano has a Crisis Intervention Team (CIT) program but Muns frames public safety through a law-enforcement-investment lens. Value 4: increase staffing and investment.',
  ARRAY['https://www.plano.gov/1349/Mayor-John-B-Muns',
        'https://capitalanalyticsassociates.com/spotlight-on-john-muns-mayor-city-of-plano/',
        'https://ballotpedia.org/John_Muns'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 3
-- Texas SB4 (2017) prohibits sanctuary city policies statewide; Plano has no
-- sanctuary designation. Muns has made no statements calling for active ICE
-- cooperation beyond legal requirements, nor any statements resisting enforcement.
-- Matches: "Follow federal law as required but do not use city resources for
-- proactive immigration enforcement."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from city policy context: Plano has no sanctuary city designation; Texas SB4 (2017) prohibits local sanctuary policies and requires cooperation with federal immigration law. Muns has made no public statements advocating for proactive ICE cooperation or for limiting enforcement beyond state law. City policy follows state law as required. Value 3 represents the de facto position of Plano under state law compliance without proactive ICE partnership. No direct quote from Muns on this topic found.',
  ARRAY['https://www.plano.gov/1349/Mayor-John-B-Muns',
        'https://ballotpedia.org/John_Muns'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Muns championed a unanimous 8-0 council vote for a $15M TIRZ and 65% property
-- tax abatement for the Texas Research Quarter ($4B life sciences project).
-- Previously served on Economic Development Board. Explicitly supports active
-- competition for major employers with tax incentives.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council votes and public statements: Muns led the unanimous approval of a $15 million TIRZ and 65% property tax abatement (over 25 years) for the Texas Research Quarter life sciences project. Previously served on Plano''s Economic Development Board. Has stated economic development is "a high priority" and supports incentives for businesses "large and small." Also noted that incentives have historically favored large companies while newer strategy broadens to mid-size firms. Value 4: actively compete for major employers with tax abatements.',
  ARRAY['https://dallasinnovates.com/plano-city-council-approves-tax-incentive-plan-for-life-science-hub-at-former-eds-campus/',
        'https://capitalanalyticsassociates.com/spotlight-on-john-muns-mayor-city-of-plano/',
        'https://www.texasresearchquarter.com/texas-research-quarter-receives-city-of-plano-approval-for-development-agreement-supporting-life-sciences-real-estate-project/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Council voted 8-0 for DART withdrawal election (Nov 2025) citing funding
-- inequity ($109M contributed, $44M returned), but later unanimously reversed
-- after a new funding agreement. Muns framed DART reform as improving value
-- rather than eliminating transit. Supports roads + selective transit investment.
-- Matches: "Maintain roads while selectively adding transit connections where
-- density supports it."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5584e869-4a54-4a68-a3c8-c14db45a71c5', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from DART vote record: Muns led the unanimous Nov 2025 vote to hold a DART withdrawal election (citing $109M contributed vs. $44M returned to Plano), then led the unanimous Feb 2026 vote to cancel the election after a new funding agreement secured $61M+ for Plano. Pattern shows pragmatic transit investment: willing to leave if value is poor, willing to stay with better terms. Not a transit-first advocate but not anti-transit. Value 3: maintain roads while selectively adding transit connections.',
  ARRAY['https://www.keranews.org/news/2025-11-05/plano-dart-withdrawal-election-vote',
        'https://www.wfaa.com/article/news/local/collin-county/plano-city-council-approves-dart-funding-agreement-rescinds-withdrawal-election/287-848ee60a-1e32-4984-8c4d-d429c7e2e831'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- MARIA TU — Council Place 1 / Mayor Pro Tem
-- politician_id: d6bf8d34-5a59-419a-8ed7-9c9b4d865799
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Tu supports mixed-income development in appropriate areas (Collin Creek
-- redevelopment with multifamily + retail) but opposes apartments in single-family
-- neighborhoods. Case-by-case targeted approach. Matches value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from 2019 Q&A and council record: Tu stated she supports "well-planned development of varied housing options" in areas like the Collin Creek Mall redevelopment (multifamily + townhomes + office + retail), which "increases economic vitality while reducing traffic." However, she is "not in favor of building apartments in single-family neighborhoods" and prefers case-by-case evaluation. This reflects a targeted-subsidy/smart-growth approach rather than broad intervention or laissez-faire. Value 3: targeted help, easier permits in right locations.',
  ARRAY['https://communityimpact.com/guides/dallas-fort-worth/plano/news/city-county/2019/03/13/candidate-qa-maria-tu-runs-for-place-1-seat-on-plano-city-council/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Tu stating a position on homeless camping enforcement. Checked: Community Impact Q&As, Plano Star Courier, Ballotpedia, plano.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 2
-- Tu opposes apartments in single-family neighborhoods but supports mixed-use
-- in redevelopment areas. Abstained on Heritage Creekside March 2026 vote
-- (multifamily addition). Reflects modest density with strong neighborhood
-- protection. Matches value 2: "Allow modest density increases (duplexes,
-- accessory units) with strong design review and neighborhood input."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from stated position and vote record: Tu has explicitly stated she is "not in favor of building apartments in single-family neighborhoods" and evaluates each rezoning "on a case-by-case basis." In March 2026 she abstained on the Heritage Creekside vote that added multifamily housing under SB 840. This pattern indicates support for protecting neighborhood character with only modest density increases in appropriate locations, consistent with value 2.',
  ARRAY['https://communityimpact.com/guides/dallas-fort-worth/plano/news/city-county/2019/03/13/candidate-qa-maria-tu-runs-for-place-1-seat-on-plano-city-council/',
        'https://www.localprofile.com/real-estate/plano-approves-next-phase-of-heritage-creekside-development-12081025'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Tu stating a specific position on racial equity enforcement or civil rights programs. Checked: Community Impact, Ballotpedia, plano.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no specific record found of Tu stating a position on police budget allocation or public safety staffing levels. General support for public safety services implied but no budget-specific statements found. Checked: Community Impact, Plano Magazine, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 3
-- No Plano sanctuary policy; TX SB4 requires compliance. Tu has not made
-- statements advocating proactive ICE cooperation. Value 3 reflects state-law
-- compliance baseline.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from city policy context: Plano operates under Texas SB4 (2017) which bars sanctuary policies. Tu has made no public statements advocating either proactive ICE cooperation or resistance to federal enforcement. Value 3 reflects the default state-law compliance position. No direct quote from Tu on immigration enforcement found.',
  ARRAY['https://ballotpedia.org/Maria_Tu'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Tu voted with the council on the Texas Research Quarter TIRZ/abatement.
-- Supports business attraction through incentives as part of Plano''s growth model.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from council vote record: Tu was part of the council that unanimously approved the $15M TIRZ and 65% property tax abatement for the Texas Research Quarter life sciences project in August 2024. No dissent from Tu recorded. Plano''s long-standing business-attraction model (Legacy West, corporate HQ hub) reflects active incentive competition. Value 4: actively compete for major employers with significant tax abatements.',
  ARRAY['https://dallasinnovates.com/plano-city-council-approves-tax-incentive-plan-for-life-science-hub-at-former-eds-campus/',
        'https://ballotpedia.org/Maria_Tu'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Tu explicitly supports transit ("absolutely essential to our region") and
-- expressed frustration with DART negotiations but pragmatically supported
-- the new funding deal. She abstained or supported moderate positions on
-- transit. Matches value 3: roads + selective transit additions.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from public statements: As Mayor Pro Tem, Tu stated "I support public transit. In fact, I believe it''s absolutely essential to our region... as we keep growing, public transit will only become more important. That''s why I believe it needs to be improved, and it needs to be expanded." However, she also said "we''ve been continuing talking for six and a half years [with DART] with no results" — frustrated with funding inequity, not opposed to transit itself. Pragmatically backed the Feb 2026 DART funding deal. Reflects maintain roads + selectively add transit where it works. Value 3.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2025/12/29/roundup-planos-local-transit-committee-cotton-belt-trail-and-other-recent-dart-updates/',
        'https://www.nbcdfw.com/news/local/plano-holds-first-vote-in-dart-funding-agreement/3988812/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- BOB KEHR — Council Place 2
-- politician_id: de037c5c-9c00-40c5-ade2-3d322b4a0349
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Kehr says housing costs are a challenge and wants to "keep growing families in
-- Plano, help seniors who want to retire here." No public housing or rent control
-- advocacy; targeted assistance framing. Value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Kehr stated that "with rising costs, the city must find ways to keep growing families in Plano, help seniors who want to retire here, and support young families who want to build lives here." No advocacy for public housing, rent control, or deregulation-only approaches found. Framing aligns with targeted assistance (value 3). Assumed office May 2025; no council vote record yet on housing-specific measures.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/10/qa-meet-the-candidates-for-plano-city-council-place-2/',
        'https://www.bob4plano.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Kehr stating a position on homeless camping enforcement. Assumed office May 2025; limited public record. Checked: bob4plano.org, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found of Kehr stating a specific position on residential zoning density. Campaign focused on housing affordability and economic development in general terms without specifying zoning approaches. Checked: bob4plano.org, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Kehr stating a position on racial equity, civil rights enforcement, or affirmative action. Checked: bob4plano.org, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Kehr explicitly lists "strong public safety" as a core priority. Rhetoric
-- frames investment in police/fire as a key city service. No co-responder or
-- defund framing found. Value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Kehr lists "strong public safety" as a primary city service priority alongside libraries, roads, and infrastructure. Business background and pro-growth platform frame public safety as a city investment priority. No statements on budget reallocation or alternative responders found. Value 4: increase police staffing and pay to improve response and deter crime.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/10/qa-meet-the-candidates-for-plano-city-council-place-2/',
        'https://www.bob4plano.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 3
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Kehr stating a specific position on ICE cooperation or immigration enforcement. Value 3 reflects Texas SB4 compliance baseline for Plano. Checked: bob4plano.org, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Kehr is "passionate about economic development" and notes the tax burden is
-- "carried 50% by businesses." Supports attracting/retaining businesses of all
-- sizes through economic development programs. Value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign statements: Kehr stated he is "passionate about economic development" and emphasized the importance of "attracting and retaining businesses of all sizes to Plano, which helps with prosperity and allows the tax burden to be carried 50% by businesses." This framing clearly supports active incentive use to attract employers. Value 4: compete actively for major employers with tax abatements.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/10/qa-meet-the-candidates-for-plano-city-council-place-2/',
        'https://www.bob4plano.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de037c5c-9c00-40c5-ade2-3d322b4a0349', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no specific record found of Kehr stating a transportation investment philosophy. Campaign focused on economic development, housing affordability, and public safety. Checked: bob4plano.org, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- RICK HORNE — Council Place 3
-- politician_id: bc4a88d7-2f56-48fd-85db-fa1fd4f8547e
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Horne's signature housing position: smaller homes (1,200-1,600 sqft) for
-- young families and seniors; redevelopment of 60s-80s neighborhoods. Targeted
-- workforce housing approach. Matches value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from stated positions: Horne''s signature housing idea is smaller homes (1,200-1,600 sq ft) on smaller lots for young families and seniors, redeveloping older 1960s-1980s neighborhoods where "land is often worth more than the house." His platform explicitly includes "increasing workforce housing and updating aging infrastructure." No advocacy for public housing or rent control; his approach is enabling different housing products through redevelopment incentives and permit streamlining. Value 3: targeted help including easier building permits.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/07/10/qa-get-to-know-new-plano-city-council-member-rick-horne/',
        'https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/04/06/meet-the-candidates-running-for-plano-city-council-place-3/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Horne stating a position on homeless camping enforcement. Checked: Community Impact Q&As, rickhorne4plano.org, Ballotpedia, Plano Star Courier.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 2
-- Horne wants smaller footprint homes with neighborhood character preserved.
-- Does not advocate broad upzoning. Matches value 2: modest density (duplexes,
-- accessory units) with design review.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from stated positions: Horne advocates smaller homes on smaller footprints (1,200-1,600 sqft) "while keeping neighborhood features." He wants to encourage redevelopment of aging single-family areas for affordability without eliminating neighborhood character. This reflects modest density increases (smaller lots, perhaps accessory units or cottage-style) with design standards maintained. Value 2: modest density with strong design review and neighborhood input.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/07/10/qa-get-to-know-new-plano-city-council-member-rick-horne/',
        'https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/04/06/meet-the-candidates-running-for-plano-city-council-place-3/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — value 2
-- Horne explicitly campaigned on "strengthening and supporting the Equal Rights
-- Ordinance" (Plano''s non-discrimination ordinance). Matches value 2: "Strengthen
-- civil rights enforcement and address systemic discrimination."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from campaign platform: Horne explicitly included "strengthening and supporting the Equal Rights Ordinance" as a campaign commitment — Plano''s local non-discrimination ordinance. This is the clearest direct civil rights statement found among all 8 council members. Matches value 2: "Strengthen civil rights enforcement and address systemic discrimination."',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/04/06/meet-the-candidates-running-for-plano-city-council-place-3/',
        'https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/07/10/qa-get-to-know-new-plano-city-council-member-rick-horne/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 3
-- Horne's platform says "support and investment in first responders" and
-- "increased funding for libraries and other city services." Balanced approach
-- — supporting police without defund framing; also supports expanding city
-- services broadly. Matches value 3: keep current funding, add crisis response teams.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign platform: Horne calls for "support and investment in first responders" as part of a broader platform that also includes "increased funding for libraries and other city services." The balanced phrasing — investing in first responders alongside other city services, rather than making police the top priority — suggests a value 3 position: maintain current public safety funding while adding services. No statements on crisis response teams specifically found, but the broad civic investment framing is consistent with maintaining current levels plus additions.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/government/2023/04/06/meet-the-candidates-running-for-plano-city-council-place-3/',
        'https://ballotpedia.org/Rick_Horne'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 3
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Horne stating a specific position on ICE cooperation. He supports the Equal Rights Ordinance which indicates awareness of civil liberties issues, but no immigration enforcement stance found. Value 3 reflects Texas SB4 compliance baseline. Checked: Community Impact, rickhorne4plano.org, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no specific record found of Horne stating a position on corporate tax incentives or economic development approach. His platform focuses on redevelopment, first responders, libraries, Equal Rights Ordinance, and workforce housing. Checked: Community Impact Q&As, Ballotpedia, rickhorne4plano.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no specific record found of Horne stating a transportation investment priority. Checked: Community Impact Q&As, Ballotpedia, rickhorne4plano.org.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- CHRIS KRUPA DOWNS — Council Place 4
-- politician_id: 127b8e69-3900-438c-8361-2cfe24b6c6cf
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no specific record found of Downs stating a position on affordable housing policy. Campaign emphasized infrastructure. Assumed office May 2025; limited public record. Checked: chris4plano.com, Community Impact Q&A, KERA, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Downs stating a position on homeless camping enforcement. Checked: chris4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no specific record found of Downs stating a position on residential zoning density or neighborhood character. Campaign emphasized infrastructure maintenance. Checked: chris4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Downs stating a position on racial equity or civil rights enforcement. Checked: chris4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no specific record found of Downs stating a position on police budget or public safety staffing. Checked: chris4plano.com, Community Impact Q&A, KERA, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Downs stating a position on ICE cooperation or immigration enforcement. Checked: chris4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no specific record found of Downs stating a position on corporate tax incentives or economic development strategy. Checked: chris4plano.com, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Downs highlighted "infrastructure has an impact on local operations" and emphasized
-- keeping infrastructure "up-to-date and improved." Infrastructure-first framing
-- for Plano (auto-oriented suburb) suggests maintaining roads + selective improvements.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign statement: Downs told KERA that "infrastructure has an impact on local operations" and the city must "continue to focus on infrastructure, making sure that it continues to stay up-to-date and improved." In a predominantly auto-oriented suburb like Plano, infrastructure focus primarily means roads and road maintenance. No transit-first or bike-network advocacy found. Value 3: maintain roads while selectively adding transit/pedestrian improvements where density supports it.',
  ARRAY['https://www.keranews.org/news/2025-02-18/whos-running-for-local-office-in-planos-may-election',
        'https://ballotpedia.org/Chris_Krupa_Downs'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- STEVE LAVINE — Council Place 5
-- politician_id: ecef0481-27c7-4955-b822-83d64c7ef63f
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 3
-- Lavine proposes housing solutions for seniors to downsize, "which would free
-- up housing inventory." No public housing or rent control advocacy. Targeted
-- market-enabling approach. Value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Lavine proposes "finding solutions for seniors who want to downsize but do not have options in Plano today, which would free up housing inventory" for families. This is a supply-side, targeted approach — enabling market options rather than public provision or rent control. Value 3: targeted help including first-time buyer assistance and easier permits (enabling downsizing options).',
  ARRAY['https://steve4plano.com/',
        'https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/04/03/qa-meet-the-candidates-for-plano-city-council-place-5/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Lavine stating a position on homeless camping enforcement. Checked: steve4plano.com, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no specific record found of Lavine stating a position on residential zoning density. His housing comments focus on senior downsizing options rather than zoning policy specifics. Checked: steve4plano.com, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found of Lavine stating a position on racial equity or civil rights enforcement. Checked: steve4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Lavine explicitly states he will "continue to invest in police and fire
-- departments to keep Plano one of the safest in America" and frames public
-- safety as "funding public safety teams adequately." Matches value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Lavine explicitly committed to "continuing to invest in police and fire departments to keep Plano one of the safest in America" and stated that "a safe city can be a thriving city," framing public safety investment as foundational to Plano''s competitive position. Also stated "funding public safety teams adequately" as a core commitment. Matches value 4: increase police staffing, equipment, and pay.',
  ARRAY['https://steve4plano.com/',
        'https://steve4plano.com/meet-steve/',
        'https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/04/03/qa-meet-the-candidates-for-plano-city-council-place-5/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Lavine stating a specific position on ICE cooperation or immigration enforcement. Checked: steve4plano.com, Community Impact, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Lavine served on Plano Boards and Commissions for 7+ years; voted with council
-- on Texas Research Quarter TIRZ; "keeping Plano thriving" framing aligns with
-- active business attraction. Value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign platform and Plano context: Lavine''s "keeping Plano safe, affordable, and thriving" platform combined with 7+ years on city boards and commissions aligns with Plano''s active economic development incentive approach. He joined a council that voted unanimously for TIRZ incentives for Texas Research Quarter. No statements opposing corporate incentives found. Value 4: compete actively for major employers.',
  ARRAY['https://steve4plano.com/',
        'https://ballotpedia.org/Steve_Lavine'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Lavine: "embracing forward-thinking mobility solutions to help ease congestion"
-- and Plano is "an integral part of a regional transportation system." He voted
-- for DART withdrawal election citing funding inequity but did not oppose transit
-- itself. Matches value 3: maintain roads + selectively add transit.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign statements and DART vote: Lavine stated he would work toward "forward-thinking mobility solutions to help ease congestion" and acknowledged Plano as "an integral part of a regional transportation system." He voted for the DART withdrawal election (Nov 2025) but framed it as giving citizens the right to choose rather than opposing transit itself ("supporting a withdrawal election doesn''t mean abandoning public transportation"). Then voted to cancel the election after a new funding deal. Pattern: pragmatic road-plus-transit approach. Value 3.',
  ARRAY['https://steve4plano.com/',
        'https://www.keranews.org/news/2025-11-05/plano-dart-withdrawal-election-vote'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- SHUN THOMAS — Council Place 7
-- politician_id: 4272e5cb-40cf-42d9-a493-ae5ca04301bb
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no specific record found of Thomas stating a position on affordable housing policy or subsidies. Checked: Community Impact Q&A Dec 2025, Plano Magazine, voyagedallas.com, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — value 3
-- Thomas advocates "comprehensive wrap-around services for Plano residents in need
-- of support" and will "deliver comprehensive wrap-around services." This combined
-- with her human-services background and community-policing support suggests a
-- services-plus-enforcement balance. Matches value 3: allow enforcement when
-- shelter is available, citations divert to services.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from background and campaign statements: Thomas has a Ph.D. in Human Services and nearly two decades in special education and MTSS support (connecting children in crisis to services). She pledged to "deliver comprehensive wrap-around services for Plano residents in need of support" alongside supporting "first responders and community policing." This service-first, policing-as-partner approach reflects value 3: enforcement only when shelter is available, with citations diverting to services rather than the criminal justice system.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/election/2025/12/19/qa-meet-the-candidates-running-for-plano-city-council-place-7/',
        'https://voyagedallas.com/interview/daily-inspiration-meet-shun-thomas/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 1
-- Thomas voted AGAINST Heritage Creekside development adding multifamily under
-- SB 840 (March 2026). Also stated she would "slow approval of high-density
-- residential developments." This is the most restrictive position found among
-- all council members. Matches value 1: protect existing neighborhood character.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from council vote and campaign statement: Thomas voted AGAINST the Heritage Creekside development that added multifamily housing under SB 840 at the March 23, 2026 council meeting (5-2 vote, Thomas and Quintanilla in opposition). Thomas also stated she would "slow approval of high-density residential developments so infrastructure can accommodate the current population." This is the clearest anti-density position on the council. Value 1: protect existing neighborhood character strictly; resist rezoning approvals.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/election/2025/12/19/qa-meet-the-candidates-running-for-plano-city-council-place-7/',
        'https://www.localprofile.com/real-estate/plano-approves-next-phase-of-heritage-creekside-development-12081025'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no specific record found of Thomas stating a position on racial equity programs or civil rights enforcement. Background in special education and human services suggests awareness of equity issues but no direct statement found. Checked: Community Impact Q&A, voyagedallas.com, Plano Magazine, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 3
-- Thomas supports "first responders and community policing" AND "comprehensive
-- wrap-around services." This is a balanced add-services approach rather than
-- defund or max-police. Matches value 3: keep current funding, add crisis teams.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Thomas explicitly supports "first responders and community policing" while also pledging "comprehensive wrap-around services for Plano residents in need of support." Her human services background (PhD in Human Services, mental health first aid certification, MTSS coordination) aligns with a crisis-response-addition model rather than either defunding or maximizing police. Value 3: keep current public safety funding while adding crisis response teams.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/election/2025/12/19/qa-meet-the-candidates-running-for-plano-city-council-place-7/',
        'https://voyagedallas.com/interview/daily-inspiration-meet-shun-thomas/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found of Thomas stating a position on ICE cooperation or immigration enforcement. Checked: Community Impact Q&A, voyagedallas.com, Plano Magazine, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no specific record found of Thomas stating a position on corporate tax incentives. Her platform mentions "balance business and residential needs to keep taxes low" but no specifics on incentive programs. Checked: Community Impact Q&A, voyagedallas.com, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — value 3
-- Thomas identifies transportation as Plano''s "biggest challenge" and advocates
-- building a "reliable and accessible transit system through listening to residents,
-- studying solutions, and fostering smart partnerships." Also "strengthen reliable
-- transportation options." Balanced transit investment. Value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4272e5cb-40cf-42d9-a493-ae5ca04301bb', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign statements: Thomas identified transportation as Plano''s "biggest challenge" and committed to "building a reliable and accessible transit system through listening to residents, studying solutions, and fostering smart partnerships." Also included "strengthen reliable transportation options" in her council priorities. This balanced approach — responsive to residents, studying solutions, not ideologically transit-first — matches value 3: maintain roads while selectively adding transit connections where density supports it.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/plano-south/election/2025/12/19/qa-meet-the-candidates-running-for-plano-city-council-place-7/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ─────────────────────────────────────────────────────────────────────────────
-- VIDAL QUINTANILLA — Council Place 8
-- politician_id: 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Affordable Housing — value 4
-- Quintanilla''s primary housing position is "keeping property taxes low" so
-- Plano remains affordable. No advocacy for subsidies or public housing.
-- Affordability through low taxes and light regulation. Matches value 4:
-- cut regulations so private developers can build more housing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', '669cac97-66a6-4087-b036-936fbe62efb3', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements: Quintanilla''s housing affordability position is "committed to keeping property taxes low, ensuring that Plano remains an affordable place for all Plano''s residents to live, work, and play." No advocacy for public housing, rent caps, or direct subsidies found. He also voted against Heritage Creekside multifamily addition (March 2026), indicating preference for limiting density mandates rather than encouraging it. Tax-reduction-as-affordability framing aligns with value 4: cut regulations and reduce tax burden so private market determines supply.',
  ARRAY['https://vidalforplano.com/',
        'https://vidalforplano.com/our-mission',
        'https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/12/qa-meet-the-candidates-running-for-plano-city-council-place-8/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found of Quintanilla stating a position on homeless camping enforcement. Checked: vidalforplano.com, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — value 1
-- Quintanilla voted AGAINST Heritage Creekside (March 2026) alongside Thomas.
-- This is a direct vote against multifamily addition. Matches value 1: protect
-- existing neighborhood character; resist rezoning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from council vote: Quintanilla voted AGAINST the Heritage Creekside development that added multifamily housing under SB 840 at the March 23, 2026 council meeting (5-2 approval, with Quintanilla and Thomas dissenting). This vote directly places him against multifamily density increases, consistent with protecting existing neighborhood character. Value 1: protect existing neighborhood character strictly.',
  ARRAY['https://www.localprofile.com/real-estate/plano-approves-next-phase-of-heritage-creekside-development-12081025',
        'https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/12/qa-meet-the-candidates-running-for-plano-city-council-place-8/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — value 3
-- Quintanilla served on Plano''s Community Relations Commission "working to foster
-- inclusivity and unity." As a Mexican American from the Rio Grande Valley, his
-- civic inclusion work aligns with maintaining existing civil rights protections.
-- No advocacy for reparations or affirmative action found. Matches value 3:
-- maintain current civil rights laws while promoting equal opportunity.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', '0bc588c6-39e1-4084-b5de-cac909b8b762', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from civic background: Quintanilla served on the City of Plano''s Community Relations Commission, "working to foster inclusivity and unity." As a Mexican American from the Rio Grande Valley now serving in local government, his background reflects awareness of civil rights issues. No statements advocating for reparations, expanded affirmative action programs, or limiting civil rights enforcement found. Commission service aligns with value 3: maintain current civil rights laws while promoting equal opportunity.',
  ARRAY['https://vidalforplano.com/our-mission',
        'https://ballotpedia.org/Vidal_Quintanilla'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — value 4
-- Quintanilla "stands strong in his support for our police and firefighters,
-- advocating for the resources they need to keep Plano safe and secure."
-- Explicit police investment framing. Matches value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statements: Quintanilla "stands strong in his support for our police and firefighters, advocating for the resources they need to keep Plano safe and secure." This explicit resource-investment framing for police and fire aligns with value 4: increase police staffing, equipment, and pay.',
  ARRAY['https://vidalforplano.com/',
        'https://vidalforplano.com/vidals-keyfocusareas'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — value 3
-- Quintanilla is a Mexican American from the Rio Grande Valley who served on
-- the Community Relations Commission. No statements advocating proactive ICE
-- cooperation found. Texas SB4 compliance baseline. Value 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from background and city policy context: Quintanilla, a Mexican American born in the Rio Grande Valley border region, served on Plano''s Community Relations Commission working to "foster inclusivity and unity." No statements found advocating proactive ICE cooperation or active immigration enforcement partnership. Texas SB4 requires compliance with federal law but prohibits active sanctuary policies. Value 3 reflects the state-law compliance baseline without proactive enforcement advocacy.',
  ARRAY['https://vidalforplano.com/our-mission',
        'https://ballotpedia.org/Vidal_Quintanilla'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — value 4
-- Quintanilla is a "strong advocate for economic development, committed to
-- fostering local businesses, creating job opportunities, and ensuring sustainable
-- growth that benefits all of Plano''s residents." Matches value 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign statements: Quintanilla is described as "a strong advocate for economic development, committed to fostering local businesses, creating job opportunities, and ensuring sustainable growth that benefits all of Plano''s residents." This strong economic development advocacy, combined with a business background (VP of Human Resources, Access Healthcare), aligns with active use of incentives to attract employers. Value 4: compete actively for major employers with tax abatements.',
  ARRAY['https://vidalforplano.com/',
        'https://vidalforplano.com/vidals-keyfocusareas',
        'https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/12/qa-meet-the-candidates-running-for-plano-city-council-place-8/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no specific record found of Quintanilla stating a position on transportation investment priorities. Checked: vidalforplano.com, Community Impact Q&A, Ballotpedia.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

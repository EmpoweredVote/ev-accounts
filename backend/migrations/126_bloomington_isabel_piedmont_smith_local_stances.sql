BEGIN;

-- ============================================================
-- Migration 126: Local Lens compass stances for Isabel Piedmont-Smith
-- Bloomington City Common Council, District 1
-- politician_id: 91f6d45d-5e7e-48f6-aab1-9476d81946b5
-- Researched: 2026-05-11
-- ============================================================

-- 1. AFFORDABLE HOUSING (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Piedmont-Smith co-authored the Bloomington Unified Development Ordinance (UDO, adopted
-- April 2020) and dozens of amendments, including its 15% inclusionary affordable housing requirement
-- mandating that new multi-unit developments include 15% affordable units or pay into the Housing
-- Development Fund. She has consistently advocated for publicly funding housing programs including
-- homeowner repair programs and down payment assistance (in 2025 she specifically urged the city to
-- set aside budget to backfill expected federal cuts to those programs). She proposed a housing summit
-- with affordable housing builders to drive the UDO overhaul. She supported the 2026 inclusionary
-- ordinance increasing the fee-in-lieu from $20,000 to $50,000 per unit. No evidence of supporting
-- direct government-operated public housing (value 1) or a fully market-based approach (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from co-authorship of the UDO, voting record, and public statements. Piedmont-Smith co-authored the Bloomington Unified Development Ordinance (adopted April 2020) and dozens of amendments, including its 15% inclusionary affordable housing requirement: new multi-unit developments must include 15% affordable units or pay into the city''s Housing Development Fund. In April 2025 she urged the council to set aside budget to preserve federal housing programs — homeowner repair initiatives and down payment assistance — anticipating federal cuts, stating "the federal landscape and support for affordable housing from the federal government is very different this year than it was in the past." She proposed a housing summit with affordable housing builders to drive the next UDO overhaul. She supported the 2026 Hopewell PUD affordable housing incentives ordinance requiring inclusionary commitments. She noted that duplexes "by nature are relatively affordable compared to a single family home," framing density itself as a public affordability tool. No evidence of advocating for directly government-built and operated public housing (value 1), nor for a market-only deregulatory approach (values 4-5). Value 2 (require new developments to include affordable units and publicly fund housing) matches her documented record.',
  ARRAY[
    'https://www.idsnews.com/article/2025/04/housing-transportation-udo-2026-budget-city-council',
    'https://www.idsnews.com/article/2021/05/bloomington-city-council-rejects-amendment-offering-affordable-housing-plan',
    'https://bloomington.in.gov/housing/affordable',
    'https://www.ipm.org/news/2026-02-11/council-passes-affordable-housing-incentives-asks-for-more',
    'https://bsquarebulletin.com/bloomington-city-council-district-1-democratic-party-primary-joe-lee-isabel-piedmont-smith/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. CRIMINALIZATION OF HOMELESSNESS (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 1: Protecting the right to sleep in public spaces and redirecting enforcement budgets toward
--          permanent supportive housing and mental health services
-- Evidence: Piedmont-Smith was a co-sponsor (with Flaherty and Rosenbarger) of the 2021 ordinance that
-- would have affirmatively protected houseless encampments — prohibiting the city from displacing a camp
-- unless it could provide "permanent housing" or "transitional housing" as defined by HUD. She asked city
-- staff: "Where can people experiencing homelessness sleep, when no shelter is available to them?" and
-- pressed for sanctioned camping sites, single-room occupancy buildings, or at minimum a place for
-- people to park cars safely. In September 2023 she was among five council members who voted down an
-- ordinance that would have prohibited camping on sidewalks and streets, directly questioning why
-- preventing unhoused individuals from blocking sidewalks was a "higher priority" than other right-of-way
-- issues. The encampment-protection ordinance she co-sponsored failed 4-4. Her framing ("we can't
-- shelter our way out of this problem" was the article headline about this legislation) and her position
-- on the 2023 anti-camping ordinance both match value 1.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', '4938766b-b45a-46e3-93bd-b8b30651271a', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from co-sponsorship, direct quotes, and voting record. In February 2021 Piedmont-Smith co-sponsored (with Flaherty and Rosenbarger) a Bloomington ordinance that would have affirmatively protected houseless encampments: the city could not displace a camp unless it could provide "permanent housing" or "transitional housing" as defined by HUD regulations. She asked city staff directly: "Where can people experiencing homelessness sleep, when no shelter is available to them?" and advocated for "a single-room occupancy building, or a sanctioned camping site, or at least a place where people can park their cars and be safe." The ordinance failed 4-4. In September 2023 she was among five council members who voted down an ordinance prohibiting camping on sidewalks and streets; she asked "Why is that not a higher priority than individuals who may be unhoused blocking sidewalks?" — challenging why enforcement against unhoused people ranked above other right-of-way violations. Her legislative and rhetorical record is consistent with value 1: protecting the right to sleep in public and redirecting resources toward permanent housing and services rather than criminalization. Not value 2 (decriminalize while investing in shelter) — she went further, proposing to protect encampments outright and criticizing the idea that shelter bed expansion alone can solve homelessness.',
  ARRAY[
    'https://bsquarebulletin.com/bloomingtons-proposed-law-protecting-encampments-puts-housing-first-we-cant-shelter-our-way-out-of-this-problem/',
    'https://bsquarebulletin.com/2021/03/04/bloomington-city-council-votes-down-proposed-law-on-protections-for-houseless-on-4-4-tie-at-321-a-m/',
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://bsquarebulletin.com/bloomington-council-votes-down-proposed-law-against-camping-storing-property-in-right-of-way/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. RESIDENTIAL ZONING (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 4: Upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements
-- Evidence: Piedmont-Smith voted FOR introducing the two March 2025 resolutions that would have
-- directed the plan commission to allow duplexes, triplexes, and fourplexes by right in single-family
-- zones and eliminate parking minimums citywide (4-4 tie blocked introduction). She argued publicly
-- for upzoning on "ethical, social justice and environmental grounds" in 2019. In a May 2021 special
-- session she voted AGAINST an amendment that would have removed the UDO's upzoning language,
-- citing her representation of residents in multi-family housing. She proposed the "ripple effect"
-- theory — as higher-income residents move into new higher-density housing, their vacated units
-- become more affordable, driving prices down citywide. No evidence of opposing broad upzoning or
-- requiring community votes (values 1-2). Her consistent position across 2019, 2021, and 2025 is
-- affirmative support for broad multifamily upzoning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from voting record, direct quotes, and stated policy reasoning. In March 2025, Piedmont-Smith voted in favor of introducing two UDO amendment resolutions that would have directed the plan commission to allow duplexes, triplexes, and fourplexes by right in single-family zones and eliminate parking minimums citywide — the vote failed 4-4, blocking even introduction of the measure, but she was among the four who supported it. In a May 2021 special session she voted against an amendment that would have stripped the UDO''s upzoning language, explicitly citing that she represented residents living in multi-family housing. In 2019 she stated support for the upzoning proposal on "ethical, social justice and environmental grounds," though she deferred on that particular vote due to constituent pressure — her stated personal position was pro-upzoning. She proposed the "ripple effect" argument for broad upzoning: as higher-income residents fill new density housing, their vacated older units become available at lower rents, improving citywide affordability. No evidence of supporting neighborhood-veto requirements (value 1), limiting density to modest increases with design review (value 2), or protecting single-family zones (value 3). Her consistent record across 2019, 2021, and 2025 — supporting multifamily by right and parking minimum elimination — matches value 4 (upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements).',
  ARRAY[
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://bloomingtonian.com/2021/05/06/plexes-approved-in-bloomington-but-with-conditions-still-up-for-legislation-political-battle-continues-online-in-divided-city/',
    'https://bsquarebulletin.com/bloomington-city-council-district-1-democratic-party-primary-joe-lee-isabel-piedmont-smith/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: In 2011, Piedmont-Smith sponsored Resolution 11-07 (passed 8-0) opposing Indiana SB 590
-- (the anti-immigration enforcement bill), arguing it "encourages reliance on race and national origin
-- and diverts critical law enforcement resources away from preventing and stopping criminal actions"
-- and impairs the fundamental right to access government. In 2026 she stated that "local elected
-- officials' responsibilities" include upholding civil rights when opposing Flock surveillance use
-- for immigration enforcement. She has consistently stated she does not want Bloomington to "facilitate
-- the removal of people through lack of due process or trampling on their civil liberties."
-- Her campaign priorities include strengthening the social safety net and involving underserved
-- communities in government. No evidence of supporting reparations mandates (value 1) or limiting
-- civil rights enforcement (values 3-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from legislative sponsorship, direct quotes, and consistent public record. In March 2011, Piedmont-Smith co-sponsored Resolution 11-07 (passed 8-0) opposing Indiana Senate Bill 590, which required law enforcement to verify immigration status on "reasonable suspicion." The resolution argued the bill "encourages reliance on race and national origin and diverts critical law enforcement resources" and impairs all citizens'' fundamental right to access government. In 2026 she stated it is "local elected officials'' responsibilities to uphold civil rights" while opposing city surveillance tools that could be used in immigration enforcement. She stated: "I don''t want Bloomington to be able to facilitate the removal of people through lack of due process or trampling on their civil liberties." Her stated campaign priorities include involving underserved communities in government decision-making and strengthening the social safety net. She has served on the board of the South Central Community Action Program (poverty alleviation) and on the Jack Hopkins Social Services Funding Committee. No evidence of calling for racial equity mandates across all institutions or reparations programs (value 1), nor of any position suggesting limiting civil rights enforcement (values 3-5). Value 2 (strengthen civil rights enforcement and address systemic discrimination) best matches her documented record.',
  ARRAY[
    'https://bloomington.in.gov/council/legislation/Resolution/2011/11-07',
    'https://www.idsnews.com/article/2026/02/bloomington-flock-contract-what-to-know',
    'https://www.ipm.org/news/2026-02-06/bloomington-city-council-member-speaks-against-flock-contract',
    'https://bsquarebulletin.com/bloomington-city-council-district-1-democratic-party-primary-joe-lee-isabel-piedmont-smith/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. PUBLIC SAFETY APPROACH (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 2: Maintain current police staffing but shift non-violent calls to unarmed mental health co-responders
-- Evidence: No direct statement from Piedmont-Smith calling to defund or significantly reduce the police
-- budget. However, she consistently pushed to shift enforcement away from unhoused individuals toward
-- social services — she voted against all camping enforcement ordinances, co-sponsored encampment
-- protections, and repeatedly redirected attention toward social support (sanctioned camping sites,
-- SRO buildings, outreach workers). In 2023 Mayor Hamilton proposed adding Community Service Specialists
-- (unarmed civilian responders) for welfare checks and noise complaints — a change Piedmont-Smith
-- supported and engaged with in budget discussions. She noted in 2023 that "we cannot increase the
-- budget; once the mayor proposes the budget, we can only decrease it" — indicating she accepted, rather
-- than tried to increase, existing police funding levels while redirecting non-violent responses.
-- This pattern matches value 2, not defund (value 1) or maintain-plus (values 3-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from voting record, budget positions, and stated priorities; no direct statement on police budget reallocation philosophy found. Piedmont-Smith has not publicly called to defund or significantly cut the police budget. She noted in 2023 budget discussions that "we cannot increase the budget — once the mayor proposes the budget, we can only decrease it, vote yes or vote no," indicating she accepted existing police funding levels rather than seeking increases. Across multiple votes she has opposed using law enforcement to address homelessness, instead consistently directing attention toward social services, outreach workers, and housing as the correct tools for public safety challenges affecting the unhoused population. She co-sponsored the 2021 houseless protections ordinance that would have redirected encampment enforcement toward housing placement. Mayor Hamilton''s 2023 proposal to hire five Community Service Specialists (unarmed civilians handling welfare checks and noise complaints) aligned with Piedmont-Smith''s stated orientation toward non-law-enforcement responses for non-violent situations. No evidence of calling to redirect a significant portion of the police budget (value 1), nor of advocating for expanded police staffing or equipment as a top city priority (values 4-5). The consistent pattern — current police funding accepted, non-violent/welfare calls redirected to unarmed alternatives — matches value 2. This is an inference; no direct quote on police staffing philosophy was found. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, Bloomington.in.gov budget pages 2020-2026.',
  ARRAY[
    'https://www.idsnews.com/article/2023/09/bloomington-police-department-new-policy-proposed',
    'https://bsquarebulletin.com/bloomingtons-proposed-law-protecting-encampments-puts-housing-first-we-cant-shelter-our-way-out-of-this-problem/',
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://bloomington.in.gov/council/public-safety-advisory'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. LOCAL IMMIGRATION ENFORCEMENT (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 1: Refuse all ICE detainers; prohibit city employees from sharing immigration status information
--          with federal agencies
-- Evidence: Piedmont-Smith co-sponsored Resolution 11-07 (2011, passed 8-0) opposing Indiana SB 590
-- which mandated law enforcement verify immigration status — framing immigration enforcement as
-- harmful to civil liberties and law enforcement priorities. In 2026, she pushed to cancel the city's
-- Flock license plate reader contract specifically because Flock's national camera network could give
-- ICE access to Bloomington data. She stated: "I don't want Bloomington to be able to facilitate the
-- removal of people through lack of due process or trampling on their civil liberties" and called
-- having the surveillance data available "problematic" given the "national context of creeping fascism
-- and increasing loss of personal liberties." She explicitly stated the city should not continue its
-- Flock contract, calling Flock "not trustworthy." She also raised the concern that empty jail space
-- could be used by ICE for detainment. These positions go beyond merely not proactively enforcing
-- immigration law (value 3) — she is actively seeking to prevent any pathway for city infrastructure
-- to be used in immigration enforcement, consistent with value 1.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from legislative sponsorship, direct quotes, and public advocacy. In 2011, Piedmont-Smith co-sponsored Resolution 11-07 (passed 8-0) opposing Indiana SB 590, which required law enforcement to verify immigration status on "reasonable suspicion." The resolution argued this approach diverted law enforcement resources and encouraged reliance on race and national origin. In 2026, she became one of the most vocal council members calling for the cancellation of the city''s Flock Safety license plate reader contract, citing specifically that Flock''s national network could give ICE access to Bloomington data without the city''s control. She stated: "I don''t want Bloomington to be able to facilitate the removal of people through lack of due process or trampling on their civil liberties" and called having surveillance data available "problematic" given the political climate around civil liberties. She said: "I don''t trust Flock to follow it, nor to keep camera images and associated data safe in this national context of creeping fascism and increasing loss of personal liberties." She also raised alarm that empty Monroe County Jail space could attract ICE for immigrant detention. The Bloomington Police Department subsequently banned use of Flock data for immigration enforcement in March 2026, and the city ended the Flock contract and data sharing with Indiana law enforcement in April 2026. Piedmont-Smith''s positions — opposing any city technology or infrastructure that could facilitate immigration enforcement, and her 2011 anti-enforcement resolution — are consistent with value 1 (refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies). No statement on ICE detainer policy specifically was found, but her overall posture is to prevent any city-facilitated immigration enforcement pathway.',
  ARRAY[
    'https://bloomington.in.gov/council/legislation/Resolution/2011/11-07',
    'https://www.idsnews.com/article/2026/02/bloomington-flock-contract-what-to-know',
    'https://www.ipm.org/news/2026-02-06/bloomington-city-council-member-speaks-against-flock-contract',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations',
    'https://www.idsnews.com/article/2026/04/bloomington-city-council-flock-county-jail'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. ECONOMIC DEVELOPMENT INCENTIVES (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Not found: Piedmont-Smith voted with the full council (9-0) on the 2022 Catalent tax abatement
-- ($350M investment, 1,000 jobs) but made no recorded statement on her philosophy toward corporate
-- tax incentives or economic development subsidies. No other votes or statements from Piedmont-Smith
-- on economic development incentive packages, TIF districts, or large-employer attraction were found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Piedmont-Smith voted with the full council (9-0) on the 2022 Catalent pharmaceutical tax abatement ($350 million capital investment, 1,000 new jobs), but the article covering the vote does not attribute any statement to her on corporate tax incentive philosophy. No other votes or statements from Piedmont-Smith on economic development incentive packages, TIF districts, large-employer recruitment, or her general philosophy on corporate subsidies versus organic development were found. Her stated campaign priorities emphasize housing, climate, and social safety net, not economic development specifically. Checked: B Square Bulletin, Indiana Daily Student, Indiana Public Media, Indiana Economic Digest, Bloomington.in.gov business pages, Bloomington Economic Development Corporation.',
  ARRAY[
    'https://bsquarebulletin.com/catalent-tax-abatement-okd-in-first-of-two-bloomington-city-council-votes-9-0/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. TRANSPORTATION PRIORITIES (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 1: Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking
--          requirements citywide
-- Evidence: Piedmont-Smith has consistently advocated for non-automotive transportation modes as her
-- stated priority. As a candidate and councilmember she listed "investing in more buses and bike routes"
-- and "greater transportation options, more funds for bus service, bicycle lanes, making it safe to walk"
-- as transportation priorities. She served as chair of the Bloomington Environmental Commission, which
-- aligned with prioritizing sustainable, non-automotive modes. In 2019 she urged the Plan Commission
-- to emphasize "biking, walking, and public transit as transportation modes." She voted for the 2023
-- unanimous Bloomington Transit expansion. She also supported reducing parking minimums as part of
-- the 2025 UDO upzoning resolutions. Her one road-repaving vote (College Mall Road) was explicitly
-- framed as "just moving money around" for a grant already secured — not a statement of road
-- investment as a transportation priority. Value 1 matches her stated multimodal priorities.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91f6d45d-5e7e-48f6-aab1-9476d81946b5', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '91f6d45d-5e7e-48f6-aab1-9476d81946b5',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign statements, committee service, and voting record. Piedmont-Smith has consistently prioritized pedestrian, cycling, and transit investment. As a candidate she listed "investing in more buses and bike routes" and "greater transportation options, more funds for bus service, bicycle lanes, making it safe to walk as well" as her transportation priorities. She urged the Bloomington Plan Commission to emphasize "biking, walking, and public transit as transportation modes" and to protect green space, as part of the 2018 Comprehensive Plan process. She served as chair of the Bloomington Environmental Commission, which aligns with prioritizing sustainable, non-automotive transportation. She voted with the council on the 2023 unanimous approval of a Bloomington Transit expansion. She supported the March 2025 UDO resolutions that included eliminating parking minimums citywide — a direct policy tool reducing car-centric infrastructure requirements. She voted to create the new Transportation Commission in 2025, which was chartered to "prioritize nonautomotive modes and sustainability." Her one case of supporting a road repaving project (College Mall Road, 2020) was framed as "just moving money around" for a state grant already secured — not a statement of investment priority — and she specifically said bike lanes "could be added later." This record across campaign statements, commission service, transit votes, and parking minimum opposition is consistent with value 1 (prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide).',
  ARRAY[
    'https://bsquarebulletin.com/bloomington-city-council-district-1-democratic-party-primary-joe-lee-isabel-piedmont-smith/',
    'https://bsquarebulletin.com/2020/05/14/bloomington-council-committee-digs-into-road-funding-to-weigh-repaving-of-college-mall-road-against-other-transportation-goals/',
    'https://www.idsnews.com/article/2023/08/bloomington-transit-expansion-approved-by-city-council',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bloomington.in.gov/council/smith'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Migration 576: Worcester City Council Stances
-- ============================================================================
-- 11 officials: Mayor + 5 At-Large + 5 District Councillors
-- 86 stance rows total
-- Idempotency: ON CONFLICT DO UPDATE on both tables
-- ============================================================================

BEGIN;

-- ============================================================
-- JOSEPH M. PETTY (Mayor, external_id=-258200001)
-- UUID: a25f862d-26f5-41f0-a32b-c4d59c7769c8
-- ============================================================

-- Petty / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Worcester under Petty operates an Inclusionary Zoning Ordinance requiring affordable units in new developments, an Affordable Housing Trust Fund, down payment assistance programs, and ARPA-funded affordable housing grants (up to $150,000 per unit). The FY25-29 Strategic Plan calls for partnering with nonprofits and private developers to preserve and expand protected affordable housing, and supporting first-time homebuyers — a mix of subsidies and zoning reform without public housing construction or rent caps.$$,
ARRAY['https://www.worcesterma.gov/housing-neighborhood-development','https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/arpa'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Worcester's FY25-29 Strategic Plan explicitly adopts a Housing First approach: "Develop a more comprehensive, place-based, Housing First approach to prevent, and provide pathways out of, homelessness." The city plans a Day Resource Center for the unhoused and the Quality of Life Team refers unhoused individuals to services rather than citing them into the criminal justice system.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/city-manager/quality-of-life-team'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$The FY25-29 Strategic Plan commits to a Housing First strategy, expanding permanent supportive housing, a Day Resource Center, and outreach-based engagement through the Quality of Life Team. Enforcement is not listed as a primary tool — services, housing navigation, and employment resources are. The plan also modifies zoning to encourage housing for people at risk of homelessness near transit.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/city-manager/quality-of-life-team'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Petty's administration created the Department of Sustainability and Resilience (est. 2021) and adopted the Green Worcester Plan targeting net-zero by 2045. Worcester joined the DOE Better Climate Challenge in 2022, committing to reduce GHG emissions by 50% within 10 years — the first Massachusetts municipality to do so. These are significant clean energy investments with gradual fossil fuel reduction timelines.$$,
ARRAY['https://www.worcesterma.gov/sustainability-resilience','https://www.worcesterma.gov/sustainability-resilience/renewable-energy-efficiency'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Worcester's FY25-29 Strategic Plan requires new development to meet "the highest standards for climate resilience and sustainability" including stormwater, energy efficiency, and flood resilience. The city launched Miyawaki forests for urban reforestation, a Stormwater and Green Infrastructure Master Plan, and an Urban Forest Master Plan. The plan mandates developers meet environmental standards and emphasizes protecting green spaces and tree canopy.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/sustainability-resilience/resilience','https://www.worcesterma.gov/sustainability-resilience'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Worcester's goal is to be "the cleanest Gateway City in the nation." The Quality of Life Team proactively addresses illegal dumping, needle removal, and neighborhood beautification in all neighborhoods. The Keep Worcester Clean initiative goes "beyond the basics of municipal sanitation services" with year-round multi-department coordination. The FY25-29 plan commits to a Zero Waste Master Plan.$$,
ARRAY['https://www.worcesterma.gov/city-manager/quality-of-life-team','https://www.worcesterma.gov/keep-worcester-clean','https://www.worcesterma.gov/city-manager/strategic-plan'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Worcester's Mobility Action Plan commits to "safe, equitable and sustainable mobility choices" including Complete Streets, bike infrastructure, Vision Zero (adopted June 2025), and multimodal options. The FY25-29 Strategic Plan prioritizes transit, micro-mobility and pedestrian modes alongside road maintenance. The city supports expanded MBTA commuter rail, Amtrak routes, and commercial air service.$$,
ARRAY['https://www.worcesterma.gov/mobility/worcester-mobility-action-plan','https://www.worcesterma.gov/mobility/vision-zero','https://www.worcesterma.gov/city-manager/strategic-plan'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Worcester's economic development approach includes small business microloans, facade grants, vacant storefront incentives, and ARPA small business grants — primarily focused on local entrepreneurs and small businesses. The FY25-29 Strategic Plan sets a 10,000-job target by 2030, streamlines permitting, and recruits private employers with well-paying jobs while explicitly protecting small businesses from displacement.$$,
ARRAY['https://www.worcesterma.gov/development','https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/arpa'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$The FY25-29 Strategic Plan calls to "update municipal zoning to facilitate more housing types and residential uses" and explicitly encourages accessory dwelling units and other 2- to 3-unit housing typologies in single-family zones. This is a targeted upzoning approach allowing modest density increases while stopping short of eliminating single-family zoning citywide.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/housing-neighborhood-development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / rent-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Petty has stated rent control would be "catastrophic to local municipal budgets," reflecting strong opposition to rent regulation. His administration has not pursued rent regulation despite rising costs — instead relying on supply-side approaches (inclusionary zoning, affordable housing trust funds) and market rents.$$,
ARRAY['https://en.wikipedia.org/wiki/Joseph_Petty'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Worcester's FY25-29 Strategic Plan includes a city-wide harm reduction approach to substance use disorder, community engagement through problem-oriented policing, and youth mentoring programs. The police department runs a CIT Mental Health Outreach program. At the same time, Petty has consistently listed reliable police and fire services as his top priority, and the city has maintained strong police staffing.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/police/community-policing','https://www.worcesterma.gov/mayor'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / local-immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Worcester Police Department's official website states it is "committed to protecting and serving all members of the community, regardless of immigration status." The department publishes FAQs in multiple languages. WPD has Policy 455 on Detention of Foreign Nationals but the city has no formal sanctuary ordinance. Worcester has resettled over 2,000 refugees from 24 countries.$$,
ARRAY['https://www.worcesterma.gov/police','https://www.worcesterma.gov/police/policies-procedures','https://en.wikipedia.org/wiki/Worcester%2C_Massachusetts'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Petty / growth-and-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a25f862d-26f5-41f0-a32b-c4d59c7769c8', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$The FY25-29 Strategic Plan explicitly targets adding 10,000 new jobs by 2030, commits to streamlining the development application review process, and aims to encourage greater certainty for developers. Worcester recruits private employers and residential/commercial developers and uses ARPA funds to support business expansion — an actively pro-growth stance with streamlined permitting.$$,
ARRAY['https://www.worcesterma.gov/city-manager/strategic-plan','https://www.worcesterma.gov/arpa','https://www.worcesterma.gov/development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- KHRYSTIAN E. KING (At-Large, external_id=-258200002)
-- UUID: 802f48ea-e397-4e72-9589-23aa5cee5a39
-- ============================================================

-- King / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$King co-authored a January 2026 order requesting the WRTA hold public hearings on improving bus service, explicitly including rapid transit implementation, same-day paratransit pilots, improved service times, and engagement with the Zero Fare Worcester Coalition and riders' advocates. He also co-authored a January 2026 order on WRTA winter bus stop snow removal.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$King co-signed a February 2026 all-council order requesting public hearings to identify sufficient emergency shelter locations for Worcester's unhoused population during winter 2026-2027, with a focus on volunteer staffing and training. His Public Health and Human Services Committee has pending items on legal representation and rental assistance for eviction-facing residents.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$King co-signed a February 2026 order to hold public hearings securing emergency shelter locations for the unhoused — focused on shelter access and volunteer capacity, not enforcement. As Vice-Chair of the Public Health and Human Services Committee, his record consistently favors service-led and shelter-expansion approaches.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$King's Education Committee held the December 2021 City Manager communication on School Resource Officer removal recommendations — it has remained in committee since 2022 without a recorded call for removal, suggesting neither strong defund sentiment nor active expansion advocacy. His Public Works transparency order and police station repair hold reflect oversight engagement rather than budget reallocation or expansion.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/education/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$King filed a January 2026 order requesting the Commissioner of Public Works brief the City Council on strategies being implemented for snow operations to provide "increased transparency" to the public. He also co-signed a sidewalk installation request for Victoria Ave. adjacent to Greenwood Park. This reflects a service improvement and accountability orientation.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$In May 2026, King held the Belmont Street/Plantation Street Corridor zoning map amendment as First Item of Business — indicating active engagement with corridor-level rezoning. This is a commercial corridor upzoning pattern consistent with allowing multifamily and mixed-use near commercial corridors while protecting most residential zones.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- King / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('802f48ea-e397-4e72-9589-23aa5cee5a39', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$King serves on the Urban Technologies, Innovation and Environment Committee, which has pending items on Worcester's Department of Sustainability and Resilience projects and the Urban Forest Academy Program expansion into Worcester Public Schools. His committee engagement reflects consistent environmental standards without evidence of extreme restriction or deregulation of development.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- SATYA B. MITRA (At-Large, external_id=-258200003)
-- UUID: 22310534-2476-4338-986c-e0e349af29d1
-- ============================================================

-- Mitra / residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Mitra voted YES (11-0) on January 13, 2026 on a package of six ADU zoning ordinance amendments allowing accessory dwelling units citywide — a modest density-increasing measure. On February 3, 2026 he voted YES on commercial/industrial and residential zoning extensions. No evidence of advocating to eliminate single-family zoning or restrict neighborhood character.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=20003','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Mitra voted YES (11-0) on January 13, 2026 on ADU zoning amendments expanding housing options citywide. He spoke and raised questions on the Housing Development TIF for 401-409 Main St., showing engagement with affordable housing tools. Actions reflect maintaining current approaches while allowing housing expansion through zoning tools.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=20003','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$On January 20, 2026, Mitra filed Order 9h calling for SMART Goals for city services, explicitly citing providing services for homeless individuals as an example goal. On February 3, 2026, Mitra co-sponsored Order 9i requesting public hearings to identify safe emergency shelter locations for the unhoused during winter 2026-2027. He also spoke on a hypodermic needle disposal harm reduction ordinance.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=13027','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$On January 20, 2026, Mitra filed a SMART Goals order explicitly including providing services for homeless individuals as a city performance metric. On February 3, 2026, he co-sponsored Order 9i requesting public hearings on emergency shelter locations for the unhoused population. No evidence of supporting camping bans or enforcement-first strategies.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=13027','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$On January 20, 2026, Mitra voted YES (8-3) on Order 9d requesting a review of Union Station security — specifically whether increased police patrols and/or outreach social services are needed, reflecting a balanced approach. On February 3, 2026, Mitra filed Order 9g requesting security cameras at city parks to deter crime. These actions show support for maintaining public safety through both enforcement and social service investment.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=13027','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$On January 20, 2026, Mitra voted YES (9-2) on Order 9o enforcing the city's sign ordinance on businesses along the Main South corridor. On February 3, 2026, he co-sponsored Order 9q on snow removal time restrictions for commercial properties and voted YES on trash receptacle installation. Actions reflect enforcing existing sanitation laws against businesses and property owners while supporting targeted service additions.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=13027','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$On February 3, 2026, Mitra voted YES (11-0) on a Worcester/Framingham MBTA Line working group to advocate for commuter rail infrastructure improvements. He voted YES on EV charging station updates. On January 13, 2026, Mitra filed an order on 25mph speed limit enforcement including whether more officers are needed. These actions show investment in transit improvements and road safety alongside traditional road management.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=12825','https://worcesterma.primegov.com/public/compiledDocument?id=20003'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$On January 20, 2026, Mitra voted YES (11-0) on Resolution 10a recommending reconsideration of a 500-foot tobacco retailer buffer zone restriction specifically to promote economic development and support women- and minority-owned businesses. On January 13, Mitra amended Order 9n to add a business ombudsperson with a Chamber of Commerce referral. Actions show targeted support for small and minority-owned businesses with community benefit framing.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=13027','https://worcesterma.primegov.com/public/compiledDocument?id=20003'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$On February 3, 2026, Mitra voted YES (11-0) on Order 9t requesting storm water runoff locations feasible for rain gardens and retention basins along Lake Quinsigamond and Indian Lake. He voted YES on zoning expansions enabling adaptive reuse and mixed-use development. Pattern reflects applying consistent environmental standards while giving developers reasonable flexibility.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=12825','https://worcesterma.primegov.com/public/compiledDocument?id=13027'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mitra / growth-and-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22310534-2476-4338-986c-e0e349af29d1', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$On January 13, 2026, Mitra voted YES (11-0) on six ADU zoning ordinance amendments. On February 3, 2026, he voted YES (11-0) on multiple zoning district extensions enabling commercial and residential adaptive reuse. Mitra also filed a SMART Goals order to track city service delivery metrics, reflecting proactive planning for demand. Actions show support for managed growth with infrastructure review.$$,
ARRAY['https://worcesterma.primegov.com/public/compiledDocument?id=20003','https://worcesterma.primegov.com/public/compiledDocument?id=12825'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- KATHLEEN M. TOOMEY (At-Large, external_id=-258200004)
-- UUID: 319d1e77-b214-4485-ab8b-b0ebd2703f22
-- ============================================================

-- Toomey / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Toomey chairs the Worcester Standing Committee on Public Safety and states that community policing and public safety are among the city's highest priorities. Her professional background as a Post-Release/Reintegration Specialist with the Worcester County Sheriff's Office and over a decade in healthcare and addiction services signals support for maintaining police presence alongside crisis-response capacity.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Toomey / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Toomey co-signed the February 2026 order requesting hearings on securing emergency shelter for the unhoused population for winter 2026-2027, including volunteer support strategies. Her career as a reintegration specialist and addiction services professional indicates a services-supplemented enforcement posture — not pure criminalization nor full decriminalization — aligning with allowing enforcement only when adequate shelter is available.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Toomey / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$In February 2026, Toomey co-signed a council-wide order requesting Standing Committee on Public Health and Human Services hold hearings to help the city identify and secure emergency shelter for the unhoused population winter 2026-2027, including strategies to increase volunteer support at shelter locations. Her background in addiction services and sheriff's office reintegration work reflects a service/shelter investment posture combined with reasonable public space enforcement.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Toomey / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Toomey serves as Vice Chairperson of the Standing Committee on Economic Development, whose pending docket includes Tax Increment Financing/Exemption report reviews, Ballpark District Improvement Fund oversight, grocery store feasibility analysis, and zoning amendment hearings. The committee's formal review process for TIF/TIE agreements reflects a targeted-incentives model with community review.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Toomey / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Toomey's official city profile states her priority is "maintaining safe streets, sidewalks, and infrastructure" — language consistent with maintaining current sanitation services and enforcing maintenance standards. No evidence of proposals to significantly expand sanitation staffing or privatize services.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Toomey / growth-and-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('319d1e77-b214-4485-ab8b-b0ebd2703f22', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Toomey's official stated priority is "responsible business growth and initiatives that improve quality of life, including maintaining safe streets, sidewalks, and infrastructure." The modifier "responsible" and the infrastructure-quality framing signal a proactive planning posture — investing in infrastructure ahead of growth — rather than either imposing growth limits or removing all regulatory barriers.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- MORRIS A. BERGMAN (At-Large, external_id=-258200005)
-- UUID: 022ec1b6-59e5-4227-95fc-45f2b7102a15
-- ============================================================

-- Bergman / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Bergman co-sponsored the February 3, 2026 whole-council order (Item 9i, 11-0) requesting public hearings to identify and secure sufficient safe emergency shelter locations for the unhoused population for winter 2026-2027, including volunteer capacity. As Vice-Chair of the Public Safety Committee, no authored enforcement-first or camping-ban items were found.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Bergman co-sponsored a February 3, 2026 entire-council order (Item 9i) requesting the Standing Committee on Public Health and Human Services hold public hearings to help the city identify and secure a sufficient number of safe emergency shelter locations for the unhoused population during winter 2026-2027, with a focus on volunteer staffing and training. This reflects expanding shelter capacity and services as the primary response.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Bergman is Vice-Chair of the Public Safety Committee. He voted 11-0 on all public safety items at the February 3, 2026 council meeting including police accreditation review and speed enforcement orders, reflecting support for maintaining current police services. The Municipal and Legislative Operations Committee has a pending order on stiffer criminal penalties for street takeovers. No authored defund/redirect items were found.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-safety/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/municipal-legislative-operations/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Bergman chairs the Standing Committee on Economic Development. He authored a March 17, 2026 order exploring the feasibility of Worcester hosting NCAA championship events. His committee oversees TIF/TIE agreements and the Ballpark District Improvement Fund reserve shortfall, with formal review processes for each. This reflects targeted economic incentives tied to event attraction and development oversight with community review requirements.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$On February 3, 2026, Bergman voted 11-0 on zoning amendments extending manufacturing-general, business-general, and residential-general districts at specific parcels. He previously served on the Zoning Board of Appeals. The pattern of commercial corridor and mixed-use upzoning with case-by-case parcel review reflects allowing multifamily and mixed-use near commercial corridors while maintaining residential zone standards.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / growth-and-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Bergman chairs the Economic Development Committee, which oversees TIF/TIE agreements, the Ballpark District Improvement Fund, and the NCAA host city feasibility study he authored. He also authored a National Grid commercial electrical upgrade costs report, showing proactive attention to infrastructure costs affecting business development. This reflects planning ahead to support responsible expansion with institutional oversight.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Bergman authored Item 9m (Feb 3, 2026, adopted 11-0) requesting a report on all 311 calls about snow plowing issues from January 2024 through January 2026 — focused on public accountability for snow removal services. He co-sponsored Item 9q requesting whether there are time restrictions for commercial snow removal near residential properties. He also voted yes on WooBin trash receptacle installation in Tatnuck Square.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$On February 3, 2026, Bergman voted 11-0 in favor of the Worcester/Framingham MBTA Line working group order, the WRRB commuter rail ridership data order, the pedestrian crossing improvement order on Elm St., and the EV charging station update report. He also voted for the Ernest A. Johnson Tunnel project timelines report reflecting road infrastructure attention. This balanced road and multimodal investment pattern aligns with selectively adding transit connections and pedestrian improvements where demand supports it.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bergman / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('022ec1b6-59e5-4227-95fc-45f2b7102a15', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Bergman's official biography notes membership on the Preservation Worcester board — the city's historic preservation nonprofit. On February 3, 2026, he voted 11-0 on Item 9t (storm water runoff locations for rain gardens and retention basins along Lake Quinsigamond and Indian Lake) and Item 8g (EV charging station update). No authored items pushing strict development restrictions or fee-in-lieu approaches were found.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- GARY ROSEN (At-Large, external_id=-258200006)
-- UUID: 23052e57-ce98-439a-a6fe-c538f26ec959
-- ============================================================

-- Rosen / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Rosen is the lead author of the all-council Feb 3, 2026 order (#9i, adopted 11-0) requesting emergency shelter hearings for the unhoused in winter 2026-2027, with a focus on securing shelter locations and recruiting and training volunteers. His PHHS committee also holds CMHA/Catholic Charities shelter meeting items. No criminalization-of-homelessness orders found.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rosen / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$As Chair of the Public Health and Human Services Committee, Rosen authored the Feb 3, 2026 full-council order (#9i) to hold public hearings on emergency shelter locations for the unhoused and strategies to recruit volunteers for shelter sites — a services-and-shelter-expansion strategy. The committee also holds pending items on shelter system access, evictions, and housing assistance collaboration.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rosen / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Rosen co-authored (with Bilotta, Bergman, and King) a January 13, 2026 order (#13b) requesting public hearings to improve WRTA bus service, explicitly including rapid transit, route changes, same-day paratransit, a Zero Fare Coalition review, and improved metrics. Rosen is also a former Chairman of the WRTA Advisory Board, reflecting longstanding multimodal transit investment priorities alongside roads.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf','https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rosen / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Rosen chairs Public Health and Human Services, through which he co-authored a youth mental health hearing order, held an overdose prevention/safe injection site discussion with the Board of Health, and advanced a comprehensive substance use crisis plan — channeling mental health and addiction responses through the health committee rather than policing. No authored orders redirect or expand the police budget.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rosen / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23052e57-ce98-439a-a6fe-c538f26ec959', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Rosen is not a member of the Public Works Committee and has no authored sanitation orders in the public record. He voted yes with the full council (11-0) on Bergman's 311/snow plow reporting improvement order and the commercial snow removal report order. This pattern — supporting service improvement efforts by others without authoring expanded sanitation programs — is consistent with maintaining current services while enforcing anti-dumping laws.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- TONY ECONOMOU (District 1, external_id=-258200007)
-- UUID: 2a77e3dc-24e2-40c9-a6fa-d134d59ede82
-- ============================================================

-- Economou / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Economou co-signed the February 3, 2026 whole-council order requesting public hearings to secure emergency shelter locations for the unhoused population for winter 2026-2027, with a focus on shelter capacity and volunteer recruitment rather than enforcement. No authored camping-ban or criminalization orders were found across Public Works, Public Safety, or Education committee records.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://worcesterma.gov/elections/elected-officials'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Economou / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Economou co-signed the February 3, 2026 all-council order (#9i, adopted 11-0) requesting the Standing Committee on Public Health and Human Services hold public hearings to identify and secure sufficient safe emergency shelter locations for Worcester's unhoused population during winter 2026-2027, including strategies to increase volunteer staffing at shelter sites. No enforcement-first or camping-ban orders were found in any committee record.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://worcesterma.gov/elections/elected-officials'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Economou / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Economou is a member of the Public Safety Committee, where the current pending item involves a review of the Hospital Guard of the Worcester Police Department. As Vice Chair of the Education Committee, the SRO removal recommendation from the 2021 School Safety Taskforce has been held in committee since May 2022 with no authored push to remove or expand SROs. He also co-signed the April 2026 youth mental health hearings order.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-safety/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/education/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Economou / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Economou chairs the Standing Committee on Public Works, whose pending docket includes the City Manager communication on "Keep Worcester Clean," pothole-related 311 calls since program launch, and pavement restoration standards. He also authored a sidewalk repair order on Winifred Ave. near Duffy Field. This reflects maintaining current sanitation and infrastructure services with accountability tracking.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf','https://worcesterma.gov/elections/elected-officials'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Economou / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$As Chair of the Public Works Committee, Economou oversees sidewalk construction, repair, and street resurfacing petitions citywide. He personally authored sidewalk extension and repair petitions and filed speed hump petitions through the Traffic and Parking Committee. This pedestrian infrastructure focus reflects maintaining roads while selectively adding pedestrian improvements, but no authored WRTA/transit orders or bike-network advocacy were found.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/traffic-parking/pending.pdf','https://worcesterma.gov/elections/elected-officials'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Economou / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a77e3dc-24e2-40c9-a6fa-d134d59ede82', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Economou chairs the Public Works Committee, which holds a stormwater and wetland protection petition and a stormwater berm petition. The committee also holds the Vernon Connected Study and Ernest A. Johnson Tunnel maintenance records. This reflects consistent application of environmental and drainage infrastructure standards — maintaining existing regulations without authored orders to restrict development or eliminate environmental review.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf','https://worcesterma.gov/elections/elected-officials'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- ROBERT A. BILOTTA (District 2, external_id=-258200008)
-- UUID: 9e10d315-a792-4d22-9bcb-cd16247e2fa4
-- ============================================================

-- Bilotta / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Bilotta chairs the Public Service and Transportation Committee and co-authored a January 2026 order requesting WRTA improve bus service including rapid transit implementation, a same-day paratransit pilot, improved service times, and better metrics — explicitly inviting the Zero Fare Worcester Coalition. He also filed multiple pedestrian crosswalk, speed hump, and lighted beacon petitions throughout 2025-2026.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/traffic-parking/pending.pdf','https://worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Bilotta co-signed the February 2026 all-council order requesting hearings to secure emergency shelter for the unhoused — focused on expanding shelter capacity and volunteer support, not enforcement. His pre-council background as chair of the Worcester Together Affordable Housing Coalition and board member of the Center for Living and Working reinforces a services-and-housing approach.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Bilotta co-signed the unanimous all-council order (Feb 3, 2026) requesting the Public Health and Human Services Committee hold hearings to identify sufficient safe and secure emergency shelter locations for the unhoused population for winter 2026-2027, and strategies to increase volunteers at those locations. His profile identifies him as a disability rights and housing advocate.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Bilotta chaired the Worcester Together Affordable Housing Coalition before taking office and authored a June 2026 order requesting a public discussion on amending the city's Inclusionary Zoning Ordinance to increase the Payment in Lieu of constructing affordable housing from 3% to 5% of total construction value — requiring more from developers. His official bio states he believes economic development should foster affordable housing and thriving neighborhoods.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Bilotta's sole-authored order on Inclusionary Zoning (June 2026) shows support for targeted community benefit requirements on development — requiring developers to contribute more to affordable housing rather than offering maximum tax incentives or blocking growth. His profile states economic development should foster affordable housing and thriving neighborhoods, signaling a community-benefit-agreement approach.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Bilotta authored the Inclusionary Zoning increase order (June 2026) requiring affordable units or higher payments from developers in new construction — supporting mixed-use development with affordability requirements rather than blocking density or eliminating zoning protections. This is consistent with allowing multifamily and mixed-use near commercial corridors while maintaining community benefit standards.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bilotta / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e10d315-a792-4d22-9bcb-cd16247e2fa4', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Bilotta co-signed an April 2026 all-council order requesting hearings on youth mental health, behavioral and addiction health issues. He is not a member of the Public Safety Committee and has not authored orders expanding or cutting police budgets. His advocacy background in disability rights and housing suggests a services-inclusive approach consistent with keeping current public safety funding while adding crisis response teams.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JOHN P. FRESOLO (District 3, external_id=-258200009)
-- UUID: bef00532-3286-456f-9668-ef5efe285270
-- ============================================================

-- Fresolo / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Fresolo co-signed the entire-council order (Item 9i, Feb 3 2026) requesting the PHHS committee hold public hearings to identify safe emergency shelter locations for the unhoused population for winter 2026-2027, including strategies to increase volunteer participation at shelters. This services-and-shelter-expansion approach was endorsed by all 11 councillors and the mayor.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Fresolo / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Fresolo co-signed the entire-council shelter hearing order (Item 9i, Feb 3 2026) calling for public hearings to identify emergency shelter locations and volunteer strategies for the unhoused — consistent with expanding shelter capacity as the city's primary homelessness strategy. No authored enforcement or anti-camping ordinance items appear in the public record.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Fresolo / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Fresolo co-signed the entire-council order (Item 4, PHHS, April 28 2026) requesting public hearings on youth mental health, behavioral, and addiction health issues — signaling support for adding crisis and mental health response alongside traditional policing. No authored orders to defund/redirect the police budget or to significantly expand police staffing appear in the public record.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Fresolo / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Fresolo serves as Vice-Chair of the Public Service and Transportation Committee, which is actively reviewing WRTA bus service improvements, the Worcester/Framingham commuter rail line, and snow removal at bus stops. He participates in committee deliberations on multimodal transit but did not author the major WRTA improvement order. His own petitions focus on street resurfacing, indicating a roads-plus-selective-transit stance.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Fresolo / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Fresolo is a member of the Public Works Committee (covering streets, water, sewers, sanitation, snow removal). He personally submitted petitions for street resurfacing on Epworth St. and Puritan Ave. — constituent-service maintenance requests. No authored orders to expand sanitation staffing, target underserved neighborhoods specifically, or privatize services appear in the public record.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Fresolo / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef00532-3286-456f-9668-ef5efe285270', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Fresolo chairs the Veterans' Memorials, Parks and Recreation Committee, which oversees parks, playgrounds, and green space in Worcester. His committee agenda focuses on park naming and memorial preservation. As a Public Works member he participates in storm water runoff and sanitation matters. No authored orders imposing strict environmental review on development or removing local environmental restrictions appear in the record.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/veterans-memorials-parks-recreation/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- LUIS A. OJEDA (District 4, external_id=-258200010)
-- UUID: 8b47525c-5efe-45ec-ba37-c6e15f038b65
-- ============================================================

-- Ojeda / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Ojeda co-signed the February 3 2026 city-wide order to hold public hearings on emergency shelter for the unhoused (order 9i). He also authored a June 2025 order requesting a comprehensive plan for the substance use crisis — a services-focused, not enforcement-first approach. His official priorities include equitable public health. No evidence of criminalization support.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$As a co-signer of the Feb 3 2026 order requesting public hearings to secure sufficient safe and secure emergency shelter locations for the unhoused population in winter 2026-2027, Ojeda's documented approach prioritizes expanding shelter capacity and voluntary service connections. No evidence of support for enforcement-first or camping-ban approaches.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Ojeda co-signed the April 2026 all-council order calling for public hearings on youth mental health and behavioral health services. His UTIE committee reviewed WPD social media policy accountability but there is no evidence of a push to defund police or to significantly expand the police budget. This balanced approach of maintaining public safety funding while adding mental health services fits the keep-current-while-adding-crisis-response stance.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$As member of the Public Service and Transportation committee and Vice-Chair of Traffic and Parking, Ojeda participates in hearings on WRTA bus service improvements and the Worcester/Framingham commuter rail line. His Traffic and Parking petition (Winfield St. resident permit parking) addresses local road access needs. The committee hearings cover both transit expansion and road maintenance, consistent with a balanced maintain-roads-while-adding-transit approach.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-service-transportation/pending.pdf','https://www12.worcesterma.gov/agendas-minutes/standing-committees/traffic-parking/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$As Chair of the Urban Technologies, Innovation and Environment committee, Ojeda oversees the City Manager's updates on Worcester's Green Worcester Plan (net-zero by 2045) and sustainability/resilience projects. A March 2026 City Manager communication on sustainability projects was referred to his committee. His oversight role applies consistent environmental standards without evidence of extreme restriction or deregulation of development.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf','https://www.worcesterma.gov/sustainability-resilience'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Ojeda chairs the UTIE committee, which oversees Worcester's Department of Sustainability and Resilience and the Green Worcester Plan (net-zero 2045 roadmap). A March 2026 City Manager communication on sustainability and resilience projects was routed to his committee for oversight. This places him as an active steward of the city's incremental clean energy transition, consistent with investing in clean energy while gradually reducing fossil fuel reliance.$$,
ARRAY['https://www.worcesterma.gov/sustainability-resilience','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Ojeda's official priority list includes affordable housing initiatives and transformative development for District 4 neighborhoods (Green Island, Kelley Square, Main South, Canal District). No evidence found of support for mass public housing, rent caps, or market-only approaches. Worcester uses a mix of inclusionary zoning, housing trusts, and subsidies consistent with targeted help via subsidies and streamlined permitting.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Ojeda's stated priorities include transformative development for District 4 neighborhoods and creating opportunities for community stakeholders to collaborate. His district (Green Island, Kelley Square, Canal District, Main South) is an underserved urban area where targeted development with community benefit agreements is the documented approach. No evidence of maximum-subsidy corporate attraction or opposition to all incentives.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ojeda / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b47525c-5efe-45ec-ba37-c6e15f038b65', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$As Chair of the Urban Technologies, Innovation and Environment committee, Ojeda oversees environmental quality issues in Worcester. No specific sanitation petitions were found bearing his name; the committee pending agenda focuses on the Green Worcester Plan and accountability mechanisms. The UTIE committee role reflects consistent enforcement of environmental standards rather than significant service expansion or privatization.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JOSE A. RIVERA (District 5, external_id=-258200011)
-- UUID: d18a85ec-abec-4a77-8d13-5b43059b6698
-- ============================================================

-- Rivera / transportation-priorities
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Rivera chairs the Traffic and Parking Committee and his authored orders focus on constituent road-safety improvements: speed humps, 25 MPH signage, parking petitions, crosswalk safety mirrors, and a Jan 2026 order on best practices for traffic signage installation. His work addresses both road safety and pedestrian/ADA needs without eliminating parking or prioritizing rapid transit expansion — consistent with maintaining roads while selectively adding pedestrian improvements.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/traffic-parking/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Rivera co-signed the Feb 3 2026 all-council order requesting PHHS hold public hearings to identify safe and secure emergency shelter locations for winter 2026-2027 and develop strategies to increase volunteer capacity at those locations. This service-and-shelter-first framing — securing shelter beds before winter, not enforcement action — aligns with decriminalizing public sleeping while investing in shelter capacity and outreach.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$The all-council order co-signed by Rivera (Feb 3 2026) directs the city to identify and secure emergency shelter locations far in advance of winter 2026-2027 and to increase volunteer training at those locations. This shelter-capacity-expansion approach — services-first with no enforcement mechanism — matches expanding shelter capacity and services as the primary homelessness strategy.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Rivera co-signed the all-council Item #17n (Apr 28 2026) requesting PHHS hold hearings on youth mental health, behavioral, and addiction issues — a crisis-response-team approach supplementing existing policing. His stated official priorities include public safety and improving community-police relations. No authored orders defunding police or substantially expanding the police budget were found.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-health-human-services/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / city-sanitation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Rivera petitioned for "No Dumping" signage at Chatanika Ave./Cascade Park (May 5 2026) — an enforcement-of-anti-dumping approach — and filed sidewalk resurfacing requests at 5 and 15 Coombs Rd. (June 2 2026). He also petitioned for sidewalk installation on Clover St. and Pine View Ave. repair. These actions reflect maintaining current services while holding residents and property owners to anti-dumping standards.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf','https://www.worcesterma.gov/city-council/standing-committees'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / local-environment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Rivera serves as Vice-Chair of the Urban Technologies, Innovation and Environment Committee, which oversees the city's Sustainability and Resilience projects, the Green Worcester Plan (net-zero 2045), and environmental quality monitoring. No authored orders restricting development or removing environmental standards were found, nor any deregulatory environmental orders. His UTIE membership signals consistent environmental standards with developer flexibility.$$,
ARRAY['https://www.worcesterma.gov/city-council/standing-committees','https://www12.worcesterma.gov/agendas-minutes/standing-committees/urban-technologies-innovation-environment/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Rivera authored an order requesting a discussion on the feasibility of bringing the US Olympic Boxing Trials back to Worcester and other USA Boxing events. His stated priority is supporting local business growth. This targeted, event-based economic development approach — using city convening power to attract specific industries — aligns with targeted incentives for specific industries with community benefit, not a blanket corporate-subsidy or zero-incentive stance.$$,
ARRAY['https://www12.worcesterma.gov/agendas-minutes/standing-committees/economic-development/pending.pdf','https://www.worcesterma.gov/city-council/councilors'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rivera / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d18a85ec-abec-4a77-8d13-5b43059b6698', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Rivera's official stated priorities include expanding affordable housing options for District 5. He filed constituent sidewalk and infrastructure petitions in residential areas consistent with investing in neighborhoods. No authored orders for rent control, large-scale public housing, universal vouchers, or full market deregulation were found. His approach aligns with targeted subsidies, first-time buyer assistance, and permitting improvements.$$,
ARRAY['https://www.worcesterma.gov/city-council/councilors','https://www12.worcesterma.gov/agendas-minutes/standing-committees/public-works/pending.pdf'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- Gate 1: SELECT p.full_name, COUNT(pa.topic_id) as stance_count FROM essentials.politicians p LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id WHERE p.external_id BETWEEN -258200011 AND -258200001 GROUP BY p.full_name ORDER BY stance_count;
-- Gate 2: SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -258200011 AND -258200001) AND pc.politician_id IS NULL;
-- Gate 3: SELECT COUNT(*) AS uncited FROM inform.politician_context pc WHERE pc.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -258200011 AND -258200001) AND (pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL OR array_length(pc.sources, 1) = 0);

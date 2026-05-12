-- Migration 141: Richardson TX city council Local Lens compass stances
-- Researched 2026-05-11
-- Politicians: Amir Omar (Mayor), Curtis Dorian (Place 1), Jennifer Justice (Place 2),
--              Dan Barrios (Place 3), Joe Corcoran (Place 4),
--              Ken Hutchenrider (Place 5), Arefin Shamsul (Place 6)
-- City: Richardson, TX — ~125,000 pop., Collin + Dallas counties;
--   Telecom Corridor tech hub; notably more progressive than most Collin County cities.
--   Mayor Amir Omar is first Muslim mayor of a DFW city.
-- Sources consulted: cor.net, communityimpact.com, marksteger.com (The Wheel),
--   richardsontoday.com, texasmonthly.com, richardsoneconomicdevelopment.com,
--   ballotpedia.org, joeforrichardson.com, ken4richardson.com, danbarriosforcongress.com,
--   lwvrichardson.org, justinneth.substack.com

BEGIN;

-- ============================================================
-- AMIR OMAR — Mayor
-- ID: e9b9877d-c4dc-482e-b52a-cd015a4a6850
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- City commissioned Housing Needs Assessment (late 2024); council approved 390-unit and
-- 443-unit apartment conversions unanimously; council directed staff to pursue opportunity
-- zone designations and CZO review to enable more affordable housing. Omar supports
-- targeted subsidies (CDBG discussion) and zoning reform to increase supply — no public
-- housing or rent caps. Aligns with answer 3 (targeted subsidies, easier permits).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from council record: The council (under both pre-Omar and Omar leadership) commissioned a Housing Needs Assessment (2024) and approved two large apartment conversions (390-unit Jan 2024; 443-unit Feb 2025) unanimously. In Jan 2026, council directed staff to pursue opportunity zone designations and CZO review to enable affordable development and a home repair program for low-income seniors. No evidence of rent controls or public housing advocacy. Aligns with answer 3 (targeted subsidies, affordable project facilitation, easier permits). The CZO update to allow missing middle and infill multifamily was approved in Feb 2026 under Omar''s leadership.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/government/2026/01/14/richardson-to-focus-on-increasing-affordable-housing-supply-with-new-initiatives/',
        'https://communityimpact.com/dallas-fort-worth/richardson/government/2024/01/24/richardson-council-approves-390-unit-apartment-complex-construction/',
        'https://communityimpact.com/dallas-fort-worth/richardson/development/2026/02/06/richardson-set-to-update-comprehensive-zoning-ordinance-to-allow-for-more-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Richardson uses a police-led Homeless Engagement & Liaison Program (HELP, 6 officers);
-- 1,427 contacts in 2025. Police Chief noted enforcement is used when individuals refuse
-- services. City is a member of regional coalitions and exploring interfaith service
-- partnerships. Approach allows enforcement but diverts to services first — answer 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from city policy: Richardson operates the Homeless Engagement & Liaison Program (HELP) via the police department — 6 specially trained officers connect unhoused residents to services (1,427 contacts in 2025). The Police Chief stated enforcement is used when individuals refuse offered resources. Council (Nov 2025) directed staff to explore interfaith alliance and service funding partnerships to fill gap left by discontinued Our Calling partnership. City is a member of All Neighbors Coalition / Housing Forward and Collin County Homeless Coalition. This is consistent with answer 3: enforcement only when shelter/services are available and offered, with citations diverting to services.',
  ARRAY['https://richardsontoday.com/city-council-discusses-richardsons-unhoused-initiatives/',
        'https://justinneth.substack.com/p/richardson-city-council-work-session-ead',
        'https://www.cor.net/government/city-council/council-goals'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Council directed CZO update (Feb 2026) to allow multifamily near commercial corridors
-- and codify missing middle housing by right, removing need for case-by-case special
-- permits. Omar has emphasized neighborhood character while supporting infill and density
-- in appropriate locations. Aligns with answer 3 (multifamily near corridors, protect
-- most residential zones).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from council record: Omar''s council directed city staff (Feb 2026) to update the Comprehensive Zoning Ordinance to codify infill multifamily and missing middle housing by right rather than requiring case-by-case planned development district approvals. Council approved an 80-unit townhome development in Jan 2025 and a 443-unit apartment conversion in Feb 2025. Omar''s campaign emphasized "revitalizing older neighborhoods" and managing limited land for development. No evidence of full citywide upzoning or elimination of single-family-only zones — aligns with answer 3 (multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/development/2026/02/06/richardson-set-to-update-comprehensive-zoning-ordinance-to-allow-for-more-development/',
        'https://communityimpact.com/dallas-fort-worth/richardson/government/2025/01/17/city-council-approves-townhome-development-in-richardson/',
        'https://ballotpedia.org/Amir_Omar_(Richardson_City_Council_Place_7_(Mayor),_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- As first Muslim mayor of a DFW city, Omar explicitly advocates for inclusivity and
-- celebrates Richardson''s diversity. No evidence of reparations or equity mandates;
-- city maintains Community Inclusion and Engagement Commission. Answer 3 (maintain civil
-- rights laws, promote equal opportunity).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '0bc588c6-39e1-4084-b5de-cac909b8b762', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from public record: Amir Omar, a first-generation American of Palestinian and Iranian descent and the first Muslim mayor of a DFW city, has publicly championed inclusivity and Richardson''s diversity, stating he plans to "implement programs that bring residents together and celebrate Richardson''s diversity." The city maintains a Community Inclusion and Engagement Commission. No evidence of advocacy for reparations, race-based mandates, or conversely for eliminating affirmative action. Aligns with answer 3 (maintain civil rights laws, promote equal opportunity).',
  ARRAY['https://en.wikipedia.org/wiki/Amir_Omar',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2025/05/12/qa-meet-amir-omar-richardsons-new-mayor/',
        'https://www.texasmonthly.com/news-politics/richardson-texas-mayor-amir-omar/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Richardson maintains its police force and added a Crisis Intervention Team (partnership
-- with Methodist Richardson Medical Center since 2022). HELP program adds outreach.
-- No defunding language. Omar''s goals include "upgraded safety equipment and advanced
-- technologies for police and fire." Aligns with answer 3 (keep current funding, add
-- crisis response for mental health/addiction).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from city policy and council goals: Richardson Police Department maintains a Crisis Intervention Team (partnership with Methodist Richardson Medical Center, in operation since 2022) that handles mental health crisis calls — achieved ~10% reduction in mental health apprehensions. The HELP program adds 6 officers for homeless outreach. The 2025-27 council goals include upgraded safety equipment for police and fire. No evidence of budget reductions or defunding advocacy. Aligns with answer 3 (keep current public safety funding, add crisis response teams for mental health and addiction calls).',
  ARRAY['https://www.cor.net/government/city-council/council-goals',
        'https://richardsontoday.com/city-council-discusses-richardsons-unhoused-initiatives/',
        'https://www.richardsonpolice.net/about/department-profile'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Direct quote from Texas Monthly (Oct 2025): Omar stated Richardson "has taken a position
-- that we do not want to be a part of any federal machinations when it comes to things
-- like ICE. Obviously, if a person breaks the law, we're going to approach those people
-- as someone who's broken the law. We're not actively blocking anything, but we're not
-- actively participating." Aligns with answer 3 (follow federal law but no proactive
-- immigration enforcement with city resources).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Direct statement: In a Texas Monthly interview (Oct 2025), Omar stated: "Richardson''s taken a position that we do not want to be a part of any federal machinations when it comes to things like ICE. Obviously, if a person breaks the law, we''re going to approach those people as someone who''s broken the law. We''re not actively blocking anything, but we''re not actively participating." At a Feb 2026 UTD town hall, he reiterated this policy predated his election. This matches answer 3 exactly (follow federal law as required, do not use city resources for proactive immigration enforcement).',
  ARRAY['https://www.texasmonthly.com/news-politics/richardson-texas-mayor-amir-omar/',
        'https://www.marksteger.com/2026/02/town-hall-tag-team-omar-and-corcoran.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Richardson actively competes for major employers using 25-50% tax abatements (5-10 yr
-- terms) under Chapter 312, TIF zones, and infrastructure investment. City attracted
-- Micron ($30M, 250 jobs), Collins Aerospace ($57M, 570 jobs). $225M+ new capital in
-- 2024. Omar explicitly supports this as economic development centerpiece. Answer 4
-- (compete actively for major employers with tax abatements and infrastructure investment).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from city policy and council record: Richardson actively uses Chapter 312 tax abatements (25-50% for 5-10 years), TIF zones, and infrastructure investment to compete for major employers. In 2024 the city attracted Micron Technology (~$30M, 250 jobs) and Collins Aerospace ($57M, 570 jobs), totaling $225M+ in capital investment. Richardson''s Economic Development Dept. received the 2025 TEDC Economic Excellence Award. Omar''s stated priority is "continued economic development." The city has a dedicated Economic Development organization (Telecom Corridor). Aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://richardsoneconomicdevelopment.com/local-incentives/',
        'https://richardsoneconomicdevelopment.com/collins-aerospace-to-expand-richardson-research-group-with-57m-investment-and-over-570-new-jobs/',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2025/05/12/qa-meet-amir-omar-richardsons-new-mayor/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Richardson adopted Complete Streets Policy (June 2024), has an Active Transportation
-- Plan linking pedestrian/bike/transit, is pursuing silver-level bike-friendly city
-- designation (2025-27 goal), championed the DART Silver Line, and voted unanimously
-- for new DART governance/GMP agreement (2026). Omar's council goals include DART
-- partnership and multi-modal connectivity. Aligns with answer 2 (invest equally in
-- roads and multimodal; require bike lanes and sidewalks on new road projects).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e9b9877d-c4dc-482e-b52a-cd015a4a6850', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from city policy: Richardson adopted its first Complete Streets Policy (June 2024), updated its Active Transportation Plan (2023), and set a 2025-27 goal to achieve silver-level Bike Friendly City designation. The city voted unanimously (Feb 2026) to approve new DART governance and the General Mobility Program agreement ($2.6M rising to $6.3M/yr). The council actively supports DART Silver Line (opened Oct 2025) and Cotton Belt Regional Trail connections. These actions indicate a balanced, multimodal priority rather than road-only or transit-only. Aligns with answer 2 (invest equally in roads and multimodal options; require bike lanes and sidewalks on new road projects).',
  ARRAY['https://www.cor.net/departments/transportation-mobility/plan-policies/complete-streets',
        'https://www.marksteger.com/2026/02/council-recap-dart.html',
        'https://www.cor.net/government/city-council/council-goals'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- CURTIS DORIAN — Council Place 1
-- ID: 6b512b29-d3c1-4709-829f-df78664ffee1
-- ============================================================

-- Curtis Dorian ran unopposed in 2025. Background: designed/built 75+ homes and 50,000+
-- sq ft commercial space in Richardson. Campaign focused on infrastructure, revitalization,
-- and AAA bond rating maintenance. Did not complete Ballotpedia candidate survey.
-- No public statements on most Local Lens topics found.

-- 1. Affordable Housing — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org (no candidate survey completed), communityimpact.com, curtisforrichardson.com (no detailed policy pages indexed), cor.net. Dorian ran unopposed in 2025; campaign focused on infrastructure and revitalization without specific housing-program positions.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com, cor.net, marksteger.com. No individual statement on homelessness policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com (Place 1 not contested in 2025, no candidate Q&A published), curtisforrichardson.com. Dorian''s homebuilder background suggests market familiarity but no specific zoning-philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com, cor.net. No statement on civil rights or social justice policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com, marksteger.com. No individual statement on police budget or public safety approach found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com. No individual statement on immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com. Campaign mentioned supporting economic development and revitalization but no specific stance on tax incentive philosophy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: ballotpedia.org, communityimpact.com, curtisforrichardson.com. No individual transportation priority statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JENNIFER JUSTICE — Council Place 2
-- ID: d85ff139-293d-49ac-a7a9-3b6681040e98
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Justice explicitly supported the 390-unit apartment complex vote (Jan 2024) stating
-- "I think that it makes sense to develop what is there into something that is needed
-- in North Texas, and that is housing." She also expressed caution about federal CDBG
-- funding dependency ("administrations change and their policies change"). Supports
-- market-enabled housing production and CZO update. Answer 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Mixed evidence: Justice explicitly supported the 390-unit apartment complex vote (Jan 2024), stating "I think that it makes sense to develop what is there into something that is needed in North Texas, and that is housing." She also participated in the Jan 2026 affordable housing initiatives council meeting. However, she expressed caution about federal CDBG funding, stating "Administrations change and their policies change, and we''ve seen a lot of cities that have taken federal dollars that are now taking hits." This combination — supporting affordable project approvals and targeted city-level review, while being cautious about federal funding — aligns with answer 3 (targeted help like subsidies for affordable projects, easier building permits).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/government/2024/01/24/richardson-council-approves-390-unit-apartment-complex-construction/',
        'https://communityimpact.com/dallas-fort-worth/richardson/government/2026/01/14/richardson-to-focus-on-increasing-affordable-housing-supply-with-new-initiatives/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org, marksteger.com, justinneth.substack.com. Justice participated in council-wide homelessness policy (HELP program, regional coalitions) but no individual stance statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found (individual statement beyond council votes)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org, cor.net. Justice voted with the council majority on apartment and townhome rezonings but made no distinct individual zoning philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org, cor.net. No statement on civil rights or social justice policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Justice''s official bio and campaign materials explicitly state: "Strong public safety
-- is a key component to the City''s success, and she will continue to support the
-- recruitment and retention of quality police and fire professionals." Also serves on
-- NCTCOG Executive Board (regional planning). Aligns with answer 4 (increase police
-- staffing and pay to improve response times).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Direct statement from official bio: "Strong public safety is a key component to the City''s success, and she will continue to support the recruitment and retention of quality police and fire professionals." This emphasis on police staffing and retention aligns with answer 4 (increase police staffing, equipment, and pay to improve response times and deter crime). No evidence of defunding or co-responder program advocacy found.',
  ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/jennifer-justice',
        'https://www.jenniferjustice.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org, marksteger.com. No individual statement on immigration enforcement found. City''s general policy (per Mayor Omar and Corcoran) is to follow federal law but not proactively assist ICE.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org. Official bio mentions "fostering a vibrant community, balancing economic growth with community needs" but no specific tax incentive philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d85ff139-293d-49ac-a7a9-3b6681040e98', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, jenniferjustice.org, richardsontoday.com. Justice serves on NCTCOG Executive Board (regional planning) but no specific transportation priority statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- DAN BARRIOS — Council Place 3
-- ID: e8c863a7-d116-480e-a81f-47d26f45e264
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Barrios (2023 campaign): "maintain Richardson as an affordable place to plant roots
-- and live comfortably, including our senior citizens, longtime residents, workforce
-- employees, and young home buyers." Housing needs assessment and comprehensive land use
-- plan updates cited. Also running for Congress on affordability platform. Answer 3
-- (targeted subsidies, first-time buyer assistance, easier permits).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from 2023 campaign statements: Barrios stated he wants to "maintain Richardson as an affordable place to plant roots and live comfortably, including our senior citizens, longtime residents, workforce employees, and young home buyers looking to start their families." He cited the comprehensive land use plan for "having the right mix of housing for our growing workforce." His 2026 congressional campaign emphasizes "confronting the affordability crisis" and strengthening consumer protections. No advocacy for public housing or rent caps found. Aligns with answer 3 (targeted help: subsidies for affordable projects, first-time buyer assistance, easier permits).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/election/2023/04/10/meet-the-2-candidates-running-for-richardson-city-council-place-3/',
        'https://www.danbarriosforcongress.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Barrios has personal ministry experience with homelessness (Body & Soul ministry at
-- First UMC Richardson), single parent support (SPAN), and prison ministry (TDCJ Kairos).
-- His social service background suggests preference for service-led approaches over
-- criminalization. No specific policy statement on public camping found. Answer 2-3;
-- infer 2 (decriminalize public sleeping while investing in shelter capacity and
-- outreach) based on demonstrated values.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from background and ministry record: Barrios has personally served in Richardson''s "Body & Soul" homelessness ministry, the Single Parent Action Network (SPAN), and as a Texas Department of Criminal Justice Kairos prison volunteer through First United Methodist Church Richardson. He also served the American Red Cross in leadership roles for over a decade. This demonstrated commitment to social services and vulnerable populations — combined with his progressive Democratic lean — suggests preference for service-led, non-criminalization approaches. No direct policy statement on public camping found. Inferred answer 2 (decriminalize public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/election/2023/04/10/meet-the-2-candidates-running-for-richardson-city-council-place-3/',
        'https://www.ballotready.org/people/daniel-barrios',
        'https://www.danbarriosforcongress.com/about'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Barrios' 2023 campaign: studies on comprehensive land use plan will affect "creating
-- economic growth" and "having the right mix of housing for our growing workforce."
-- Emphasizes affordable housing mix; no strict neighborhood preservation stance. Answer 3.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from 2023 campaign statement: Barrios stated the comprehensive land use plan will affect "creating economic growth" and "having the right mix of housing for our growing workforce." He also voted with the council majority to approve apartment and townhome rezonings. No evidence of strict neighborhood preservation advocacy or full citywide upzoning. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/election/2023/04/10/meet-the-2-candidates-running-for-richardson-city-council-place-3/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Barrios is a Democrat running for Congress; served on Church & Society committee at
-- First UMC; has Red Cross advocacy background; emphasizes community fairness and
-- opportunity. More progressive than most Richardson council members. Answer 2
-- (strengthen civil rights enforcement, address systemic discrimination).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from background: Barrios is a Democrat running for Congress on a platform of "fairness, accountability, and common sense" with emphasis on consumer protections and expanding opportunity. He served on the Church & Society Committee (social justice focus) at First United Methodist Church Richardson and has advocacy roots in the American Red Cross. His progressive Democratic orientation and social justice ministry background suggest alignment with answer 2 (strengthen civil rights enforcement and address systemic discrimination) rather than the status-quo approach of answer 3. No direct policy statement on reparations or race-specific mandates found.',
  ARRAY['https://www.danbarriosforcongress.com/',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2023/04/10/meet-the-2-candidates-running-for-richardson-city-council-place-3/',
        'https://www.ballotready.org/people/daniel-barrios'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, danbarriosforcongress.com, marksteger.com. Barrios is a Citizen Police Academy graduate suggesting he is not anti-police, but no specific budget position found. His social service ministry background might suggest openness to co-responder approaches, but no explicit statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, danbarriosforcongress.com, marksteger.com. Born in Brownsville, TX (border region); running as progressive Democrat, likely to support limiting ICE cooperation — but no specific city-level statement found. City''s general policy follows federal law without proactive ICE assistance.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, danbarriosforcongress.com. Congressional campaign mentions supporting "small businesses" and avoiding policies that hurt working Americans, suggesting preference for smaller-business support over large corporate abatements — but no Richardson-specific incentive philosophy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8c863a7-d116-480e-a81f-47d26f45e264', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual public record found. Checked: communityimpact.com, ballotpedia.org, danbarriosforcongress.com, marksteger.com. 2023 campaign mentioned improving infrastructure but no specific transportation modal priority statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- JOE CORCORAN — Council Place 4
-- ID: ccd0e6c7-f77c-45d7-bfae-d43125b8133d
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Corcoran's 2021 campaign goals include "increasing land value through more dense
-- housing" and missing middle housing. He championed transit-oriented development.
-- He has also expressed concern about housing market oversaturation (UTD apartments).
-- His approach is to enable private development of denser housing through zoning reform.
-- Answer 3 (targeted help: easier permits, zoning reform for affordable projects).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from campaign statements and council record: Corcoran''s 2021 campaign goals included "walkability, bikeability, and missing middle housing" and "increasing land value through more dense housing." He championed transit-oriented development. He described the CZO update (Feb 2026) as "massive but necessary" and has tracked progress on zoning code review. However, he raised market saturation concerns regarding a 511-unit student apartment development near UTD. This mix — enabling denser market-rate housing through zoning reform without subsidies — aligns with answer 3 (targeted help: first-time buyer assistance, easier building permits) rather than pure deregulation (answer 4).',
  ARRAY['https://www.joeforrichardson.com/meet-joe.html',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2021/03/03/candidate-qa-richardson-city-council-place-4/',
        'https://www.marksteger.com/2026/02/council-recap-development-priorities.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no individual public record found. Checked: joeforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. No individual statement on homelessness criminalization found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Corcoran explicitly supports upzoning and denser housing. Campaign: "increasing land
-- value through more dense housing." Championed TOD, missing middle housing, zoning code
-- update. Called zoning update "massive but necessary." Answer 4 (upzone broadly to allow
-- multifamily by right; streamline approvals).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Direct campaign statements: Corcoran''s 2021 campaign explicitly cited "missing middle housing" and "increasing land value through more dense housing" as goals. He championed transit-oriented development and was a driving force behind the Feb 2026 CZO update initiative, calling it "massive but necessary" and endorsing streamlining special permit approvals by codifying them into the zoning code. He tracked "ongoing review of zoning codes to support new developments" as a 2026 midterm achievement. This consistent pro-density, pro-streamlining record aligns with answer 4 (upzone broadly to allow multifamily by right; streamline approvals and reduce parking requirements).',
  ARRAY['https://www.joeforrichardson.com/meet-joe.html',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2021/03/03/candidate-qa-richardson-city-council-place-4/',
        'https://communityimpact.com/dallas-fort-worth/richardson/development/2026/02/06/richardson-set-to-update-comprehensive-zoning-ordinance-to-allow-for-more-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: joeforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. No statement on civil rights or social justice policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual public record found. Checked: joeforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. No specific police budget or public safety philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- At Feb 2026 UTD town hall, Corcoran co-presented with Mayor Omar and stated that the
-- Richardson Police Department cooperates with ICE "only as legally obligated to enforce
-- local laws." Aligns with answer 3 (follow federal law but no proactive ICE enforcement).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Direct statement: At the February 2026 UTD town hall co-hosted with Mayor Omar, Corcoran stated that the Richardson Police Department cooperates with ICE "only as legally obligated to enforce local laws." This directly matches answer 3 (follow federal law as required but do not use city resources for proactive immigration enforcement).',
  ARRAY['https://www.marksteger.com/2026/02/town-hall-tag-team-omar-and-corcoran.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual public record found. Checked: joeforrichardson.com, communityimpact.com, ballotpedia.org. Campaign mentions lower tax rate each year on council (indicating fiscal conservatism) but no specific corporate incentive philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Corcoran explicitly campaigns on "walkability, bikeability, and missing middle housing,"
-- "creating a safe and enhanced biking and pedestrian culture," "making progress on
-- transit-oriented development," and tracked "Bike Friendly City" designation as a 2026
-- midterm achievement. He voted for DART governance/GMP unanimously. Answer 2 (invest
-- equally in roads and multimodal; require bike lanes and sidewalks on new road projects).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ccd0e6c7-f77c-45d7-bfae-d43125b8133d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Direct campaign statements: Corcoran''s 2021 campaign goals include "walkability, bikeability, and missing middle housing" and "creating a safe and enhanced biking and pedestrian culture." He explicitly championed "making progress on Transit-Oriented Development" and tracked progress on achieving Bike Friendly City designation as a 2026 midterm achievement. He also voted unanimously for the DART governance/GMP agreement (Feb 2026), which dedicates funding to bike/pedestrian transit connections. This consistent multimodal advocacy aligns with answer 2 (invest equally in roads and multimodal; require bike lanes and sidewalks on new road projects).',
  ARRAY['https://www.joeforrichardson.com/meet-joe.html',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2021/03/03/candidate-qa-richardson-city-council-place-4/',
        'https://www.marksteger.com/2026/02/council-recap-dart.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- KEN HUTCHENRIDER — Council Place 5 (Mayor Pro Tem)
-- ID: b0ebf2ca-f1f7-4809-b8eb-94a384dab164
-- ============================================================

-- 1. Affordable Housing — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no individual public record found. Checked: ken4richardson.com (issues page), communityimpact.com, ballotpedia.org, marksteger.com. Campaign emphasis on infrastructure, economic development, and fiscal responsibility (AAA bond rating) but no specific affordable housing program philosophy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no individual public record found. Checked: ken4richardson.com, communityimpact.com, ballotpedia.org, marksteger.com. No individual statement on homelessness policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no individual public record found. Checked: ken4richardson.com, communityimpact.com, ballotpedia.org, marksteger.com. Voted with council majority on rezonings but no distinct zoning philosophy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice — not found
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: ken4richardson.com, communityimpact.com, ballotpedia.org. No statement on civil rights or social justice policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Hutchenrider explicitly advocated adding fire station funding to bond priorities
-- ("I do think we need to have fire station seven in here"). As hospital president (2010+)
-- he runs Methodist Richardson Medical Center''s partnership with RPD on Crisis Intervention
-- Team. His professional background is emergency/healthcare services; his council priorities
-- include fire and police. No defunding stance. Answer 4 (increase staffing and equipment
-- to improve response times).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from council record and professional background: Hutchenrider explicitly advocated for adding fire station funding to potential 2026 bond priorities ("I do think we need to have fire station seven in here"). As President of Methodist Richardson Medical Center since 2010, he runs the hospital''s partnership with the Richardson Police Department on the Crisis Intervention Team (mental health crisis co-response). His healthcare/emergency services background, combined with explicit public safety funding advocacy, aligns with answer 4 (increase police and fire staffing, equipment, and pay to improve response times). No evidence of redirecting funds away from police.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/government/2025/10/07/richardson-council-eyes-infrastructure-drainage-as-priorities-for-potential-2026-bond/',
        'https://www.cor.net/government/city-council/who-are-our-city-council-members/ken-hutchenrider',
        'https://ken4richardson.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no individual public record found. Checked: ken4richardson.com, communityimpact.com, ballotpedia.org, marksteger.com. No individual statement on immigration enforcement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Hutchenrider identifies economic development as one of Richardson''s "largest issues"
-- and wants to "ensure continued economic development." Chairs Business Committee and
-- Education Committee. Hospital leadership role reflects long-term investment in
-- Richardson''s economic infrastructure. Answer 4 (compete actively for major employers
-- with tax abatements and infrastructure investment).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from campaign statements: Hutchenrider identifies economic development as one of Richardson''s "largest issues" stating "I want to ensure continued economic development, focus on infrastructure and on neighborhoods." He chairs both the Business Committee and Education Committee on council. His 15-year leadership of Methodist Richardson Medical Center (a $120M expansion under his tenure) reflects his comfort with major institutional investment. Aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment) — consistent with Richardson''s actual incentive-heavy strategy.',
  ARRAY['https://ken4richardson.com/issues/',
        'https://communityimpact.com/dallas-fort-worth/richardson/election/2023/04/11/meet-the-candidates-running-for-richardson-city-council-place-5/',
        'https://www.cor.net/government/city-council/who-are-our-city-council-members/ken-hutchenrider'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b0ebf2ca-f1f7-4809-b8eb-94a384dab164', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual public record found. Checked: ken4richardson.com, communityimpact.com, ballotpedia.org, marksteger.com. Campaign focuses on infrastructure and economic development but no specific modal transportation priority statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- AREFIN SHAMSUL — Council Place 6
-- ID: 9f93ae55-9228-478d-84a9-971cf4686649
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- In the April 2025 LWV forum, Shamsul stated that the Comprehensive Plan update includes
-- "small housing and missing middle housing" options. He also mentioned "identifying new
-- housing options for the workforce." No advocacy for public housing or rent caps.
-- Answer 3 (targeted help: easier permits, zoning for affordable projects).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Direct statement from April 2025 LWV Forum: Shamsul stated that the Comprehensive Plan update includes "small housing and missing middle housing" as part of addressing housing needs, and described "identifying new housing options for the workforce" as a priority. He has 10 years of experience on the Richardson Zoning Board of Adjustment. No evidence of advocacy for rent controls, public housing, or purely market-driven deregulation. Aligns with answer 3 (targeted help: subsidies for affordable projects, first-time buyer assistance, easier building permits).',
  ARRAY['https://www.marksteger.com/2025/04/lwv-forum-for-richardson-city-council.html',
        'https://www.arefinforrichardson.com/meetarefin',
        'https://ballotpedia.org/Arefin_Shamsul_(Richardson_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no individual public record found. Checked: arefinforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. Shamsul served on RISD Bond Steering Committee and Chamber DEI Task Force but no specific homelessness policy statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Shamsul served on the Richardson Zoning Board of Adjustment and Building and Standards
-- Commission for nearly 10 years before being elected. He explicitly supported CZO update
-- at LWV forum (missing middle housing). He approaches zoning from a technical/engineering
-- perspective. Answer 3 (allow multifamily and mixed-use near commercial corridors while
-- protecting most residential zones).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from background and LWV forum statement: Shamsul served on the Richardson Zoning Board of Adjustment and Building and Standards Commission for nearly 10 years before election, giving him deep familiarity with the city''s zoning processes. At the April 2025 LWV Forum, he mentioned the Comprehensive Plan''s "small housing and missing middle housing" provisions as positive steps. He is a civil engineer (Licensed PE, certified floodplain manager) who approaches planning systematically. No evidence of full citywide upzoning advocacy or strict single-family preservation stance. Aligns with answer 3 (allow multifamily and mixed-use near commercial corridors while protecting most residential zones).',
  ARRAY['https://www.arefinforrichardson.com/meetarefin',
        'https://www.marksteger.com/2025/04/lwv-forum-for-richardson-city-council.html',
        'https://ballotpedia.org/Arefin_Shamsul_(Richardson_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Shamsul served on the Richardson Chamber of Commerce Diversity, Equity, and Inclusion
-- Task Force. Also participated in the Richardson Complete Count Committee for the 2020
-- Census (ensuring all communities counted). Consistent with answer 3 (maintain civil
-- rights laws, promote equal opportunity). No reparations advocacy.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', '0bc588c6-39e1-4084-b5de-cac909b8b762', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from civic engagement record: Shamsul served on the Richardson Chamber of Commerce Diversity, Equity, and Inclusion (DEI) Task Force and on the Richardson Complete Count Committee for the 2020 Census (ensuring all communities, including undercounted immigrant communities, are accurately counted). As a Muslim man of South Asian descent, he has personal stakes in equal opportunity and inclusion. No advocacy for reparations or race-based mandates found, but his DEI task force service indicates active support for equal opportunity. Aligns with answer 3 (maintain civil rights laws while promoting equal opportunity).',
  ARRAY['https://www.arefinforrichardson.com/meetarefin',
        'https://ballotpedia.org/Arefin_Shamsul_(Richardson_City_Council_Place_6,_Texas,_candidate_2025)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual public record found. Checked: arefinforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. Shamsul is a Citizens Police Academy graduate (Class 41) suggesting he is supportive of law enforcement, but no specific budget or co-responder position statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no individual public record found. Checked: arefinforrichardson.com, communityimpact.com, ballotpedia.org, marksteger.com. As Mayor Pro Tem 2023-2025 under Mayor Dubey, Shamsul was part of the council that established Richardson''s no-proactive-ICE-assistance policy, but no individual statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual public record found. Checked: arefinforrichardson.com, communityimpact.com, ballotpedia.org. Campaign mentions infrastructure improvements and staying ahead of maintenance needs but no specific economic incentive philosophy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities — not found (individual statement)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f93ae55-9228-478d-84a9-971cf4686649', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual public record found. Checked: arefinforrichardson.com, communityimpact.com, ballotpedia.org. Campaign mentions "road and pedestrian safety improvements" and "staying ahead of potholes" suggesting road maintenance priority, but no specific modal priority statement found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

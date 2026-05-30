BEGIN;

-- Kerry Thomson, Mayor of Bloomington, Indiana
-- politician_id: 1c6dbdaf-e110-48d3-9b88-27f911d9521f
-- Researched: 2026-05-11
-- Sources: kerryforbloomington.com/platform, bloomington.in.gov press releases,
--          Indiana Public Media (ipm.org), Indiana Daily Student (idsnews.com),
--          The Bloomingtonian

-- ============================================================
-- 1. AFFORDABLE HOUSING
-- topic_id: 669cac97-66a6-4087-b036-936fbe62efb3
-- Value: 2 — Use rent caps, require new developments to include affordable units,
--            and publicly fund new housing
-- Evidence: City invested $9M+ in affordable housing/eviction prevention/supportive
--   housing since 2024. Hopewell South PUD requires 35% permanently affordable units
--   (goal 50%). Low-income housing tax credit project at 307 N Pete Ellis Dr approved.
--   Thomson: "the most housing cost burdened city in the state" and must drive costs down.
--   Note: No evidence of rent caps; placement on publicly funded + inclusionary requirements.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from city press releases and housing report (2025-11-20). Thomson''s administration invested over $9 million into affordable housing, eviction prevention, and supportive housing since 2024. The Hopewell South planned unit development requires at least 35% permanently affordable units with an explicit goal of 50%. The city approved a 206-unit affordable apartment community using federal low-income housing tax credits. Thomson described Bloomington as "the most housing cost burdened city in the state" and said the administration must "drive that cost down." Her approach combines public funding (ARPA dollars, LIHTC), inclusionary requirements in new developments, and streamlining permitting to increase supply. No evidence of rent caps specifically, but the combination of mandatory affordable unit requirements and substantial public investment in housing aligns with value 2.',
  ARRAY[
    'https://bloomington.in.gov/news/2025/11/20/6389',
    'https://bloomington.in.gov/news/2025/07/30/6313',
    'https://www.ipm.org/show/ask-the-mayor/2025-07-16/bloomingtons-thomson-on-udo-changes-hopewell-developer-budget-deficit',
    'https://kerryforbloomington.com/platform',
    'https://www.idsnews.com/article/2025/11/bloomington-housing-homelessness-report-affordability-development'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 2. CRIMINALIZATION OF HOMELESSNESS
-- topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a
-- Value: 2 — Decriminalizing public sleeping while investing in shelter capacity,
--            outreach workers, and voluntary service connections
-- Evidence: Thomson opposed Indiana SB-285 (mandatory arrest after 48-hour warning),
--   stated "we cannot arrest our way out of homelessness." City closes encampments only
--   as last resort after sustained outreach and 30-day notice — not after confirming
--   shelter availability. Hired Homelessness Response Coordinator; partnered with
--   Community Foundation to add 10 case managers. Focuses on housing, treatment,
--   support, and connection. City does conduct encampment closures (not value 1)
--   but decriminalizes as policy preference and invests heavily in outreach/services.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from IPM reporting on SB-285 (2026-03-27) and press conference (2025-07-30). Thomson explicitly opposed Indiana''s new law requiring arrest after a 48-hour warning for public camping, stating: "We know we can''t arrest our way out of homelessness. It''s just going to accumulate fines for people and create situations that are more complicated." She argued that Bloomington''s existing 30-day notice process — which deploys outreach workers and case managers before any closure — should supersede mandatory criminal enforcement. The city hired its first Homelessness Response Coordinator, partnered with the Community Foundation to add 10 case managers, and expanded Stride Crisis Center capacity. Encampment closures occur only "when there are significant and immediate health or safety concerns" and are described as "the end point of long-term outreach, service engagement, and repeated offers of safer alternatives." This reflects decriminalization as the operative approach combined with substantial shelter and outreach investment, matching value 2. (Value 3 would require shelter availability as a precondition for any enforcement action, which Thomson does not explicitly impose.)',
  ARRAY[
    'https://www.ipm.org/news/2026-03-27/bloomington-leaders-advocates-raise-concerns-over-new-homelessness-law',
    'https://bloomingtonian.com/2025/07/30/video-we-cant-arrest-our-way-out-bloomington-mayor-on-homeless-crisis-drug-raids/',
    'https://bloomington.in.gov/news/2025/12/05/6397',
    'https://bloomington.in.gov/news/2025/07/30/6313',
    'https://www.idsnews.com/article/2025/04/indiana-homeless-bill-bloomington-camping'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 3. RESIDENTIAL ZONING
-- topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d
-- Value: 3 — Allow multifamily and mixed-use near commercial corridors while
--            protecting most residential zones
-- Evidence: Thomson supports UDO streamlining and allowing 5-bedroom SRO units in
--   residential areas, and backed the Hopewell mixed-income neighborhood (range of
--   housing types). She characterized UDO changes as "modest adjustments" and opposed
--   the city council resolutions calling for eliminating parking minimums and broad
--   upzoning as too sweeping without proper process. She preferred developing her own
--   measured UDO plan through the planning department. Supports summit district
--   (4,250 units) near corridors and the Hopewell neighborhood as a model for
--   mixed-use/mixed-income development near existing urban fabric.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from IPM Ask the Mayor (2025-07-16) and Indiana Daily Student coverage (2025-04). Thomson characterized her preferred UDO amendments as "modest adjustments" rather than a fundamental overhaul, and she opposed city council resolutions calling for broad elimination of parking minimums and sweeping upzoning across all residential zones, saying the process "should not happen without adequate public input." She supports allowing 5-bedroom SRO units in residential areas and approves mixed-income, multi-type developments like Hopewell South (small detached homes, duplexes, small multifamily, ADUs in a walkable layout). She also backed the Summit District development (up to 4,250 units) which is corridor-adjacent. Her approach prioritizes increasing density near existing urban corridors and through targeted infill rather than citywide rezoning by right. The council''s failed resolutions — which she did not endorse — would have matched value 4 (upzone broadly, eliminate parking minimums). Her own measured, process-driven approach fits value 3.',
  ARRAY[
    'https://www.ipm.org/show/ask-the-mayor/2025-07-16/bloomingtons-thomson-on-udo-changes-hopewell-developer-budget-deficit',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density',
    'https://bloomington.in.gov/news/2025/07/01/6296',
    'https://www.idsnews.com/article/2025/11/hopewell-neighborhood-unified-development-ordinance-pud-bloomington-news',
    'https://bloomington.in.gov/news/2024/08/12/6008'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 4. CIVIL RIGHTS AND SOCIAL JUSTICE
-- topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762
-- Value: 2 — Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Thomson maintains and actively funds Human Rights Commission (enforces
--   civil rights ordinance including ADA and living wage compliance), supports women
--   and minority-owned business inclusion in city contracts, operates equity-focused
--   commissions (Hispanic/Latiné, Black Males, Women, Aging), condemned hate speech,
--   received 10th consecutive perfect score on HRC Municipal Equality Index. Platform
--   states she will oppose "Trump-aligned conservative attacks on equality." No evidence
--   of reparations programs or mandated racial equity requirements in all institutions
--   (value 1). Maintains current civil rights infrastructure and strengthens enforcement.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from bloomington.in.gov/inclusion, campaign platform, and city announcements. Thomson''s administration actively funds and maintains the Bloomington/Monroe County Human Rights Commission, which enforces civil rights laws including ADA and living wage compliance. The city operates five demographic-specific commissions (Hispanic/Latiné, Black Males, Women, Aging, Disability Accessibility) focused on addressing challenges facing those populations. Thomson''s platform states she will "strengthen diversity, equity, and accessibility efforts" and "oppose Trump-aligned conservative attacks on equality from state/federal level." Bloomington received its 10th consecutive perfect score on the Human Rights Campaign''s Municipal Equality Index in 2024. Thomson supports prioritizing women and minority-owned business participation in city contracts. No evidence of reparations programs, mandatory racial equity requirements in all institutions, or positions matching value 1. The active civil rights enforcement infrastructure and opposition to rollbacks of equality protections aligns with value 2.',
  ARRAY[
    'https://bloomington.in.gov/inclusion',
    'https://kerryforbloomington.com/platform',
    'https://bloomington.in.gov/news/2024/11/27/6108',
    'https://bloomington.in.gov/news/2024/11/08/6093',
    'https://bloomington.in.gov/boards/human-rights'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 5. PUBLIC SAFETY APPROACH
-- topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85
-- Value: 3 — Keep current public safety funding while adding crisis response teams
--            for mental health and addiction calls
-- Evidence: Thomson hired 11 new officers (highest sworn-in class in over 30 years),
--   brought police staffing to 96% of authorized strength, AND expanded Mobile
--   Integrated Healthcare program (fire dept) AND Stride Crisis Center as 24/7
--   alternative to 911 for mental health/addiction. She maintained/increased police
--   investment simultaneously with non-police crisis response expansion. No evidence
--   of redirecting police budget to social services (value 1 or 2). No evidence of
--   prioritizing police expansion above all else (value 5).
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from city public safety annual report (2025-05-16) and press releases. Thomson''s administration simultaneously expanded traditional police capacity and crisis response alternatives. In June 2025, eleven officers were sworn in — the highest class sworn in over three decades — bringing police staffing to approximately 96% of authorized strength. The fire department''s Mobile Integrated Healthcare program expanded and saw a "sustained surge in patient interaction." Stride Crisis Center provides 24/7 alternative crisis response for mental health and substance use, reducing 911 demand. Thomson also distributed $117,800 in Violence Reduction Grants and $250,000 in Downtown Outreach Grants. Her campaign platform describes a "community-based, sustainable approach to public safety" working with nonprofits. This dual investment — maintaining and growing police staffing while adding parallel crisis response capacity — fits value 3 (keep current public safety funding while adding crisis response teams). No evidence she redirected police budget to social services (values 1-2), and no evidence she treats police expansion as the top spending priority over all else (value 5).',
  ARRAY[
    'https://bloomington.in.gov/news/2025/06/02/6274',
    'https://bloomington.in.gov/news/2025/05/16/6259',
    'https://www.idsnews.com/article/2025/10/stride-crisis-bloomington-crime-rate-indiana-news-monroe-county-jail',
    'https://kerryforbloomington.com/platform',
    'https://bloomington.in.gov/public-safety/safe-civil'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 6. LOCAL IMMIGRATION ENFORCEMENT
-- topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92
-- Value: 3 — Follow federal law as required but do not use city resources for
--            proactive immigration enforcement
-- Evidence: Thomson statement (2025-05-02): "Federal immigration enforcement falls
--   outside the City''s legal authority." "The role of our police department is to do
--   civil safety. The ICE agents are federal." BPD "assumes no responsibility for the
--   enforcement of federal immigration law." She also said ICE not accessing Flock
--   camera data was her intention. No sanctuary city declaration. No explicit refusal
--   to honor court-ordered detainers. No proactive assistance with ICE operations.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from city statement (2025-05-02) and IPM Ask the Mayor interview. Thomson issued a statement acknowledging "federal immigration enforcement falls outside the City''s legal authority. We cannot prevent federal officers from operating within their jurisdiction." In an interview she stated: "The role of our police department is to do civil safety. The ICE agents are federal." The Bloomington Police Department operates under a policy of assuming "no responsibility for the enforcement of federal immigration law." Thomson said it was her intention that ICE not be able to access data from Flock Safety license-plate cameras. However, she did not declare Bloomington a sanctuary city, and there is no public evidence of explicit policies refusing court-ordered ICE detainers. When ICE conducted operations in the Bloomington area (April 29-May 1, 2025 resulting in 23 arrests), the Monroe County Sheriff''s Office received no advance notification, and Thomson''s response focused on community support resources rather than operational resistance. This position — city police do not enforce immigration law, do not proactively assist ICE, but operate within federal legal constraints — fits value 3.',
  ARRAY[
    'https://bloomington.in.gov/news/2025/05/02/6246',
    'https://www.ipm.org/news/ask-the-mayor-bloomingtons-kerry-thomson-on-ice-response-branding-initiative-parking.php',
    'https://www.idsnews.com/article/2025/05/community-rally-against-ice-presence-bloomington',
    'https://www.idsnews.com/article/2026/01/bloomington-protest-ice-immigration-flock-cameras',
    'https://www.ipm.org/news/2026-01-30/protest-targets-citys-use-of-tech-companys-surveillance-tools'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 7. ECONOMIC DEVELOPMENT INCENTIVES
-- topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53
-- Value: 3 — Targeted incentives for specific industries with community benefit
--            agreements and job quality requirements
-- Evidence: City uses tax abatements (1-10 year), TIF districts, Qualified Opportunity
--   Zones, BUEA zone. Thomson supports convention center expansion for economic impact.
--   She rejected land donation to Dora Hospitality (showing selectivity about subsidy).
--   She said "serious conversations need to take place about what incentives are
--   available" and stressed "highest level of private investment." Platform emphasizes
--   attracting jobs paying living wages and collaboration with university/county/state.
--   Supports targeted affordable housing incentives (LIHTC). Not a no-incentive
--   approach (value 1/2), not maximum incentives for any large employer (value 5).
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from IPM reporting on convention center hotel (2025-12-18), city business incentives page, and campaign platform. Thomson uses targeted economic development incentives through existing tools: tax abatements (1-10 years on increased assessed value), TIF districts, BUEA Urban Enterprise Zone, and Qualified Opportunity Zones. She supported the convention center expansion as an economic development anchor expected to "bring millions of dollars in new spending from outside Bloomington each year." However, she rejected a land donation to Dora Hospitality for a hotel project, demonstrating she does not offer maximum incentives to any developer on request. She stated that "serious conversations need to take place about what incentives are available" and that the city must ensure "the highest level of private investment." Her campaign platform focuses on attracting "jobs paying living wages" and promoting Bloomington as a destination. The Hopewell affordable housing development received LIHTC incentives with affordability requirements attached. This selective, benefit-conditioned use of incentives — not a blanket rejection of corporate subsidies, not a maximum-incentive-for-any-employer approach — fits value 3.',
  ARRAY[
    'https://www.ipm.org/news/2025-12-18/convention-center-hotel-deal-stalls-amid-debate-over-incentives',
    'https://bloomington.in.gov/business/incentives',
    'https://bloomington.in.gov/news/2026/01/21/6431',
    'https://kerryforbloomington.com/platform',
    'https://bloomington.in.gov/departments/esd'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- 8. TRANSPORTATION PRIORITIES
-- topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27
-- Value: 2 — Invest equally in roads and multimodal options; require bike lanes
--            and sidewalks on all new road projects
-- Evidence: Thomson secured $1.44M USDOT Safe Streets grant (total ~$1.8M with match)
--   for multimodal safety. Established Local-Motion Grant Program for bicycle/pedestrian
--   community grants. Built protected bike lanes (E 3rd St Phase 2). Created new
--   Transportation Commission chartered to "prioritize non-automotive modes." Partnered
--   with Bloomington Transit for Traveling Town Hall. Also invests in roads/bridges.
--   Thomson is an avid cyclist. Platform: "improve roads and bridges; expand bike lanes;
--   invest in public transportation." Quotes: streets serve drivers, pedestrians,
--   cyclists, and bus riders equally. Adopted "Vision Zero" plan (eliminate fatal
--   crashes for all users). Parking reduction is aspirational (UDO process ongoing)
--   so value 1 (reduce parking citywide) is premature.
-- ============================================================
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1c6dbdaf-e110-48d3-9b88-27f911d9521f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1c6dbdaf-e110-48d3-9b88-27f911d9521f',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from USDOT grant announcement (2026-02-02), city transportation pages, and campaign platform. Thomson secured a $1.44M federal Safe Streets for All grant (total ~$1.8M with 20% city match) specifically for pedestrian, bicycle, and driver safety improvements. She established the Local-Motion Grant Program to fund community bicycle and pedestrian projects and approved the E 3rd Street Protected Bike Lane Phase 2. The new Transportation Commission is explicitly chartered to operate "through a comprehensive framework which seeks to provide adequate and safe access to all right-of-way users while prioritizing non-automotive modes and sustainability." She hosted a Traveling Town Hall on Bloomington Transit buses to demonstrate public transit commitment. Thomson stated: "Streets are some of the most shared public spaces we have and how they''re designed impacts all of us — whether we''re driving to work, walking our kids to school, biking to the Farmers'' Market, or crossing the street to a bus stop." Her campaign platform commits to improving roads and bridges alongside bike lane expansion and public transportation investment. The city adopted a Vision Zero 2039 plan eliminating fatal and serious crashes for all users. Parking reduction (via UDO) is aspirational and still in process, so value 1 (reduce parking requirements citywide) is not yet an implemented position. Multimodal investment equal to roads investment, with bike/pedestrian infrastructure on new projects, fits value 2.',
  ARRAY[
    'https://bloomington.in.gov/news/2026/02/02/6440',
    'https://bloomington.in.gov/news/2025/10/10/6371',
    'https://bloomington.in.gov/news/2025/10/03/6366',
    'https://www.iustv.com/article/2025/02/city-council-approves-merging-commissions-into-new-transportation-commission',
    'https://kerryforbloomington.com/platform'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

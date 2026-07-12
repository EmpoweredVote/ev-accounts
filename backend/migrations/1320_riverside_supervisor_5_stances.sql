-- =====================================================================================
-- Compass stances: Dr. Yxstian Gutierrez — Riverside County (CA) Board of Supervisors, District 5
-- ext_id: -4010005   politician_id: 26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae
-- Democrat; District 5 Supervisor since Jan 2023 (elected Nov 2022; re-elected June 2026
-- primary, 2nd term). Former Moreno Valley mayor/council member. District covers Moreno
-- Valley, Banning, Beaumont, Calimesa, Nuevo, San Jacinto/Perris area, and the Badlands.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Board
--     vote/resolution, sponsored measure, or on-record public statement/quote) taken during
--     his county tenure (Jan 2023 onward), with real cited source URLs confirmed via web
--     research.
--   * Topics with no clear documented Gutierrez position emit NO row (honest blank). No
--     party inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (4 topics, all applies_local=true):
--   childcare            = 3  (ARPA+Prop10 facility grant funded new infant/toddler classrooms)
--   homelessness-response = 2 (ERF grant: housing, street outreach, wrap-around services)
--   housing              = 3  (down-payment assistance + HHIP affordable-housing subsidies)
--   local-immigration    = 3  (Jan/Feb 2025 measure: follow federal law, no proactive
--                              immigration-status-based action; explicitly not "sanctuary")
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, city-sanitation, civil-rights, climate-change, data-centers,
--          economic-development, fossil-fuels, growth-and-development, homelessness,
--          jail-capacity, local-environment, public-safety-approach, religious-freedom,
--          rent-regulation, residential-zoning, transportation-priorities, trans-athletes.
--          (Workforce/hire-incentive programs like "Employer Connect" and "Hire a Veteran,"
--          heli-hydrant wildfire-response investments, and water-infrastructure projects were
--          found but do not map cleanly to any topic's documented policy-position question, so
--          they were not seeded as stances on economic-development, local-environment, or
--          public-safety-approach.)
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--          ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Yxstian Gutierrez / childcare (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supervisor Gutierrez's office approved $1 million in American Rescue Plan Act (ARPA) funding, matched with $1.4 million in Proposition 10 funds through First 5 Riverside County, to complete new infant and toddler child care classrooms at the Jan Peterson Child Development Center in Moreno Valley, expanding licensed capacity to serve 36 infants and toddlers. This is a targeted public subsidy/facility-grant approach to expanding childcare capacity rather than a universal-funding or market-only stance.$$,
        ARRAY['https://www.citynewsgroup.com/articles/first-5-riverside-county-and-supervisor-gutierrez-celebrate-new-child-care-classrooms-in-moreno-val']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yxstian Gutierrez / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Announcing a $12 million California Encampment Resolution Funding grant for the San Jacinto Riverbed area (in partnership with San Jacinto and Hemet), Gutierrez said on Oct. 27, 2023: "I am determined to use these funds to ensure housing, enhanced street outreach, and essential wrap-around services." He also approved $6,000,000 in Housing and Homelessness Incentive Program funds for the Summit View Apartments in Beaumont (groundbreaking July 2024), a 48-unit project serving people experiencing or at risk of homelessness, and backed emergency shelter funding for Hemet's Valley Restart Shelter. His documented record centers on expanding shelter/housing capacity and outreach/wrap-around services as the primary strategy, with no on-record push for anti-camping enforcement as a first-line tool.$$,
        ARRAY['https://myvalleynews.com/blog/2023/10/27/a-message-from-district-5-county-supervisor-yxstian-gutierrez-2/',
              'https://mynewsla.com/riverside/2023/01/10/former-moval-mayor-takes-seat-on-board-of-supervisors/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yxstian Gutierrez / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Gutierrez launched the First Time Home Buyer Down Payment Assistance Program for District 5 (announced June 2024), offering low- to moderate-income first-time buyers (at or below 120% of area median income) up to 20% of a home's purchase price, capped at $100,000, funded through the county's Department of Housing and Workforce Solutions. He separately approved $6,000,000 in Housing and Homelessness Incentive Program funds toward the 48-unit Summit View Apartments affordable project in Beaumont. This documented record is targeted subsidies/assistance — first-time-buyer down-payment aid and gap funding for affordable projects — not direct public construction/rent caps nor a market-only, government-out-of-housing stance.$$,
        ARRAY['https://myvalleynews.com/blog/2024/06/07/supervisor-yxstian-gutierrez-brings-affordable-housing-to-the-fifth-district/',
              'https://myvalleynews.com/blog/2024/08/03/supervisor-yxstian-gutierrez-champions-more-affordable-housing/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yxstian Gutierrez / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('26d3fdd0-7fd3-4e41-bd1c-88fb6e2dabae',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Jan. 28, 2025 Gutierrez co-sponsored with Board Chair V. Manuel Perez a measure (passed 4-0) directing county staff to build a legal-resource web portal for undocumented residents, evaluate how the county collects/stores immigration-status data, and identify funding for legal aid — followed by a Feb. 4, 2025 resolution (4-1) affirming the county as welcoming to "law-abiding immigrants and refugees." Coverage of the resolution's text states county agencies "will not initiate independent actions based solely on a person's actual or suspected immigration status," while the measure "does not prohibit county agencies from assisting or cooperating with state or federal authorities when required by law." Gutierrez himself said the steps were "consistent with State and Federal laws" and explicitly not a "sanctuary policy." This matches following federal law as required while not directing county resources toward proactive immigration-status enforcement.$$,
        ARRAY['https://kesq.com/news/local-news/2025/01/28/riverside-county-supervisors-propose-new-policy-to-protect-undocumented-immigrants/',
              'https://kesq.com/news/2025/02/04/county-board-passes-resolution-backing-law-abiding-immigrants-refugees/',
              'https://idyllwildtowncrier.com/2025/02/06/supervisors-begin-addressing-immigration-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

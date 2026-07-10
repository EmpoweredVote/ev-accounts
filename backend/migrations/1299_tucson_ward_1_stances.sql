-- =====================================================================================
-- Compass stances: Lane Santa Cruz — City of Tucson (AZ) Council, Ward 1 (Vice Mayor)
-- ext_id: -4008002   politician_id: 4c8cda02-3918-4593-b225-b22651b194d0
-- Democrat; on Council since Dec 2019, re-elected Nov 2023; 2026 Vice Mayor.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   Cited from reachable non-WAF outlets (tucson.com, AZ Luminaria, Tucson Sentinel,
--   AZPM, Democracy Now); tucsonaz.gov agendas NOT cited (Pitfall 4). Discrete 1-5
--   chairs; no defaults; 8 judicial-* topics excluded. AUDIT-ONLY / unregistered.
--
-- SEEDED (5 topics):
--   data-centers              = 1  (led opposition to Project Blue: "Tucson is not for sale"; ICE/surveillance + water concerns)
--   housing                   = 2  (affordable housing on city-owned land, community land trusts, co-ops; source-of-income protections)
--   public-safety-approach    = 2  (sole budget no-vote; police over-tasked with medical/societal ills -> shift to non-police responders)
--   residential-zoning        = 2  (leading champion of the ADU / accessory-dwelling-unit zoning ordinance)
--   transportation-priorities = 1  (fare-free transit as a safety strategy; transit-ambassador funding; transit-first)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   climate-change, deportation, economic-development, fossil-fuels,
--   growth-and-development, healthcare, homelessness, homelessness-response,
--   immigration, jail-capacity, local-environment, local-immigration, medicare/aid,
--   misinformation, redistricting, religious-freedom, rent-regulation,
--   same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--   trans-athletes, ukraine-support, voting-rights.  (judicial-* excluded, Pitfall 8.)
-- =====================================================================================

BEGIN;

-- ----- Santa Cruz / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$As Vice Mayor, Santa Cruz was a leading voice in the Aug. 6, 2025 unanimous rejection of the Amazon-linked "Project Blue" data center, declaring "Giant corporations prefer to operate in the shadows, but Tucson is not for sale." She argued the project offered "very few" long-term jobs and that such data centers "aren't being built to uplift our communities" but to serve "private profit and government surveillance," citing ICE data storage and expanded predictive policing plus the strain on the desert's water. Her documented stance is to halt data-center development rather than approve it — the most restrictive position.$$,
        ARRAY['https://azluminaria.org/2025/08/06/tucson-city-council-rejects-project-blue-amid-intense-community-pressure/',
              'https://www.tucsonsentinel.com/local/report/080625_project_blue/tucson-city-council-pulls-plug-amazons-project-blue/',
              'https://www.democracynow.org/2025/8/7/headlines/tucson_city_council_votes_unanimously_to_reject_project_blue_a_proposed_data_center_linked_to_amazon']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Santa Cruz / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Santa Cruz advocates an active public role in housing affordability: increasing affordable-housing supply on city-owned properties, acquiring properties for housing, partnering with developers on low-cost homes, and supporting community land trusts and cooperative-housing models. She publicly criticized landlords who advertise "No Section 8," and Tucson under her tenure banned source-of-income discrimination against renters using rental aid. That record — publicly funding/producing affordable housing and requiring fair access — fits a substantial government role rather than only targeted subsidies.$$,
        ARRAY['https://tucson.com/news/local/tucson-bans-housing-discrimination-against-tenants-who-receive-rental-aid/article_3afa28f4-40ec-11ed-9b5f-d39273f431aa.html',
              'https://azluminaria.org/2023/10/12/voter-guide-tucsons-ward-1-city-council-race-between-lane-santa-cruz-and-victoria-lem/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Santa Cruz / public-safety-approach (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Santa Cruz cast the lone no-vote on a city budget adoption, saying the council failed to listen to community needs and that in-custody deaths showed "too much was being expected of police officers in addressing medical and societal ills." Her documented argument is that non-violent medical, mental-health and social crises should be handled by appropriate non-police responders rather than sworn officers — a shift-non-violent-calls-to-specialized-responders approach rather than simply expanding the police budget.$$,
        ARRAY['https://tucson.com/news/local/tucson-city-council-approves-1-7b-budget-denies-requests-to-defund-police/article_a6346c2b-ffee-5aaf-a753-728d78055bfc.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Santa Cruz / residential-zoning (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Santa Cruz was described as perhaps the leading council member pushing passage of Tucson's accessory-dwelling-unit (ADU) ordinance, which allows more guest houses/backyard units in residential yards, and she has backed mixed-income and "missing middle" housing. Enabling modest density increases such as accessory units and duplexes — rather than either freezing neighborhood character or eliminating single-family zoning entirely — matches an incremental, ADU-and-duplex density-increase approach.$$,
        ARRAY['https://tucson.com/news/local/subscriber/tim-stellers-column-yimby-takes-on-nimby-in-tucsons-ward-1-race/article_516b5144-150d-11ee-9a35-d3a428e3ed0a.html',
              'https://azluminaria.org/2023/10/12/voter-guide-tucsons-ward-1-city-council-race-between-lane-santa-cruz-and-victoria-lem/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Santa Cruz / transportation-priorities (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4c8cda02-3918-4593-b225-b22651b194d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Santa Cruz is a strong transit-first advocate: she defended keeping Sun Tran fare-free — "More riders means more eyes, more community presence, safer systems. Fare-free is a safety strategy. A fare box is not." — and sponsored an amendment funding transit ambassadors, barrier improvements and panic buttons for the bus system. Prioritizing public transit (and its access and safety) over car-centric road capacity fits a transit-and-active-transportation-first investment priority.$$,
        ARRAY['https://azluminaria.org/2026/06/10/tucson-approves-transit-ambassador-program-and-more-police-patrols-amid-sun-tran-strike-threat/',
              'https://news.azpm.org/p/azpmnews/2026/6/10/230104-tucson-to-invest-in-transit-ambassadors-police-as-potential-bus-drivers-strike-looms/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

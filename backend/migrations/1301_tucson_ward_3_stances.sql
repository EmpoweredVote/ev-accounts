-- =====================================================================================
-- Compass stances: Kevin Dahl — City of Tucson (AZ) Council, Ward 3
-- ext_id: -4008004   politician_id: 3265b939-5585-4edc-a524-2841c7fe6f3d
-- Democrat; council since Dec 2021, re-elected 2025; career conservationist
-- (National Parks Conservation Assoc, Tucson Audubon, Native Seeds/SEARCH).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   Cited from reachable non-WAF outlets (tucson.com/Arizona Daily Star, Tucson
--   Sentinel, Tucson Spotlight, DGT). Discrete 1-5 chairs; no defaults; 8 judicial-*
--   excluded. AUDIT-ONLY / unregistered.
--
-- SEEDED (5 topics):
--   climate-change            = 2  (career conservationist; champions following through on Tucson's Climate Action Plan)
--   data-centers              = 1  (introduced the motion to kill Project Blue; "a hard no" over water/energy/air)
--   homelessness-response     = 2  (staunch supporter of the city's Housing First initiative + affordable housing)
--   local-environment         = 2  (lifelong conservationist; strong environmental review, though backed a battery-factory incentive)
--   transportation-priorities = 1  (champions fare-free transit and walkable neighborhoods)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   deportation, economic-development, fossil-fuels, growth-and-development,
--   healthcare, homelessness, housing, immigration, jail-capacity, local-immigration,
--   medicare/aid, misinformation, public-safety-approach, redistricting,
--   religious-freedom, rent-regulation, residential-zoning, same-sex-marriage,
--   school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support,
--   voting-rights.  (judicial-* excluded, Pitfall 8.)
-- =====================================================================================

BEGIN;

-- ----- Dahl / climate-change (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$A career conservationist, Dahl has made climate resilience a signature priority and publicly pledged to follow through on Tucson's Climate Action Plan: "Our climate resiliency plan, our Climate Action Plan ... I want to follow through with the Climate Action Plan because that's so important to me." Backing aggressive implementation of the city's carbon-neutrality-oriented plan reflects a rapid clean-energy-transition posture rather than a market-only or reject-climate-policy stance.$$,
        ARRAY['https://www.tucsonspotlight.org/dahl-in-ward-3-re-election-campaign/',
              'https://www.tucsonsentinel.com/local/report/102525_dahl_council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dahl / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Dahl was among the first council members to publicly oppose "Project Blue" and introduced the motion to kill it, declaring "I am a hard no on Project Blue and will not support the requested annexation," citing large water and energy use and negative air-quality/climate impacts. In a July 2025 letter he wrote that any project touting "economic gain" while threatening the water supply, air, or climate "should be rejected." He drove the Aug. 6, 2025 unanimous vote ending the deal — a halt-development stance.$$,
        ARRAY['https://tucson.com/news/local/government-politics/article_30e41df9-fb2e-4a14-9412-c4aa87449f1f.html',
              'https://www.tucsonsentinel.com/local/report/080625_project_blue/',
              'https://www.tucsonsentinel.com/local/report/072825_project_blue_council_races/dem-candidates-tucson-council-oppose-proposed-project-blue-data-center']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dahl / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Dahl is a staunch supporter of the city's Housing First initiative and of affordable-housing projects in Ward 3, backing a services-and-housing-led approach to homelessness (permanent/supportive housing and shelter with services) rather than an enforcement-first camping ban. That aligns with expanding shelter and services as the primary strategy.$$,
        ARRAY['https://www.tucsonspotlight.org/dahl-in-ward-3-re-election-campaign/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dahl / local-environment (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Dahl's career leading the Tucson Audubon Society, Native Seeds/SEARCH and the National Parks Conservation Association makes environmental protection central to his votes — he judges projects against their impact on water, air and climate and rejected the data center on those grounds. He has, however, supported an incentive for a water-using American Battery Factory, drawing criticism that it sat in tension with his conservationism — so his record is strong environmental protection with case-by-case judgment rather than an absolute development freeze.$$,
        ARRAY['https://thedgt.org/activist-kevin-dahl-on-protecting-our-national-parks-and-environment/',
              'https://www.tucsonspotlight.org/tucson-ward-3-council-race/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dahl / transportation-priorities (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3265b939-5585-4edc-a524-2841c7fe6f3d', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Since taking office Dahl has championed fare-free transit and walkable neighborhoods as signature accomplishments, consistently prioritizing public transit and pedestrian-friendly design over car-centric road capacity — a transit-and-active-transportation-first investment priority.$$,
        ARRAY['https://www.tucsonspotlight.org/dahl-in-ward-3-re-election-campaign/',
              'https://www.tucsonsentinel.com/local/report/120621_kevin_dahl_inauguration/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

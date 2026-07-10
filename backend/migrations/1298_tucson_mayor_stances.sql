-- =====================================================================================
-- Compass stances: Regina Romero — Mayor, City of Tucson (AZ)
-- ext_id: -4008001   politician_id: 27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5
-- Democrat; Mayor since Dec 2019 (first Latina mayor of Tucson). Current officeholder.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded
--     Mayor & Council vote/motion, sponsored initiative, or on-record public statement)
--     during her tenure, with real cited source URLs from reachable non-WAF AZ outlets
--     (tucson.com/Arizona Daily Star, AZ Luminaria, Tucson Sentinel, AZPM, Tucson
--     Spotlight, KGUN9). tucsonaz.gov agendas/minutes are Akamai-WAF-blocked and are
--     NOT cited (Pitfall 4).
--   * Topics with no clear documented Romero position emit NO row (honest blank). No
--     party inference, no neutral defaults (D-06).
--   * AUDIT-ONLY / unregistered — no migration-ledger entry. Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--   * Values are discrete 1-5 "chairs" (not a polarity scale).
--   * The 8 judicial-* topics are EXCLUDED (no bearing on a mayor) — Pitfall 8.
--
-- SEEDED (9 topics):
--   climate-change            = 2  (2020 climate-emergency decl.; carbon-neutral 2030 ops / 2045 community; Tucson Resilient Together)
--   data-centers              = 1  (Aug 2025 led unanimous rejection of Project Blue + motion to regulate large water users)
--   deportation               = 2  (Nov 2024: vowed to protect Tucson families from separation in mass deportations)
--   economic-development      = 2  (AVANZA under-represented-entrepreneur loan fund + Small Business Center; declined the big Project Blue subsidy)
--   homelessness-response     = 2  (Housing First + expanding shelter/treatment as primary strategy)
--   housing                   = 2  (HAST; Commission on Equitable Housing; El Pueblo city nonprofit developer; public funding)
--   immigration               = 2  (immigrant-welcoming city; called to end Title 42; opposed remain-in-Mexico)
--   local-immigration         = 2  (welcoming-city policy + Immigrant Support Task Force; opposed the AZ sanctuary-city ban)
--   transportation-priorities = 2  (Prop 411 roads + bike/ped 20%; champions fare-free Sun Tran/Sun Link transit)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   fossil-fuels, growth-and-development, healthcare, homelessness, jail-capacity,
--   local-environment, medicare/aid, misinformation, public-safety-approach,
--   redistricting, religious-freedom, rent-regulation, residential-zoning,
--   same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--   trans-athletes, ukraine-support, voting-rights.
-- EXCLUDED judicial-* (Pitfall 8): access-to-justice, bail-pretrial, criminal-justice,
--   government-deference, interpretation, police-accountability, prosecution-priorities,
--   transparency.
-- =====================================================================================

BEGIN;

-- ----- Romero / climate-change (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$In September 2020 Mayor Romero led Tucson's declaration of a climate emergency and committed the city to carbon neutrality by 2030 for city operations (and 2045 community-wide). Her administration adopted the "Tucson Resilient Together" Climate Action and Adaptation Plan (122 actions), built the largest low/no-emission electric bus fleet in the Southwest, and spent more than $160 million on climate projects in 2025. This is an aggressive, near-term transition to renewable energy and away from fossil fuels — not a blanket ban on all emitting activity, and not a market-only or reject-climate-policy posture.$$,
        ARRAY['https://tucson.com/news/local/tucson-declares-climate-emergency-aims-to-go-carbon-neutral-by-2030/article_f5cbed72-50db-5220-ae8e-3583eb6d1a8e.html',
              'https://www.tucsonspotlight.org/tucson-bets-on-partnerships-to-battle-climate-change/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$On Aug. 6, 2025, Mayor Romero and the Council voted unanimously to reject the ~290-acre Amazon-linked "Project Blue" data center after intense community opposition centered on water and energy demand; Romero said "Tucsonans have spoken out loudly and clearly and I hear you" and introduced a motion to create new regulation for large water users and zoning requirements that any future data-center proposal would have to meet. Halting the project and moving to gate future data centers on infrastructure/water impact reflects the most restrictive stance — a moratorium-style hold until infrastructure can support demand without burdening residents.$$,
        ARRAY['https://azluminaria.org/2025/08/06/tucson-city-council-rejects-project-blue-amid-intense-community-pressure/',
              'https://news.azpm.org/p/newsheadlines/2025/8/6/225888-bye-bye-project-blue/',
              'https://tucson.com/news/local/government-politics/article_a8cc0cbc-4836-4f75-8da1-fc9d85c1810f.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / deportation (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$In November 2024 Mayor Romero publicly vowed to protect Tucson families from separation under the incoming administration's mass-deportation plans, emphasizing that the city would not turn its resources toward sweeping removals of long-settled, law-abiding immigrant families. Her documented posture opposes indiscriminate mass deportation and prioritizes keeping established families together, consistent with limiting removal to serious criminal cases rather than blanket enforcement.$$,
        ARRAY['https://tucson.com/news/local/border/article_b834a3ca-ab4e-11ef-ac4b-3b641756409c.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Romero's economic-development record centers on small business and equitable entrepreneurship rather than large corporate subsidies: she backed the AVANZA revolving loan fund for under-represented entrepreneurs, co-located the city's Small Business Program in a single incubation center, and launched the Transform Tucson green-jobs fund. Consistent with that emphasis, in Aug. 2025 she led the rejection of the large "Project Blue" data-center subsidy after community pushback. The documented pattern favors local small-business support over competing for big employers with major tax abatements.$$,
        ARRAY['https://news.azpm.org/s/100149-mayor-romero-delivers-annual-report-on-tucsons-growth-and-challenges/',
              'https://www.tucsonsentinel.com/local/report/080625_project_blue/tucson-city-council-pulls-plug-amazons-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Tucson under Romero operates a Housing First model and her annual reporting emphasizes expanding shelter capacity, treatment beds, and affordable housing as the primary response to homelessness, with outreach and services offered before enforcement. She has touted gains in housing, shelter and treatment and outlined plans to expand each. That services-and-shelter-first approach fits expanding shelter capacity and services as the primary strategy rather than an enforcement-first camping ban.$$,
        ARRAY['https://www.kgun9.com/news/local-news/mayor-romero-touts-housing-homelessness-and-health-gains-outlines-plan-to-expand-treatment-shelter-and-affordable-homes',
              'https://www.tucsonspotlight.org/tucson-city-council-weighs-homelessness-declaration/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Romero created a Commission on Equitable Housing and Development (2020), drove adoption of the Housing Affordability Strategy for Tucson (HAST), and established El Pueblo Housing Development — a city nonprofit developer — to directly build and preserve affordable units, alongside publicly funded projects and expanded affordable-housing production. That active-public-role approach (publicly funding and building affordable housing, requiring affordability in new projects) goes beyond targeted subsidies toward a substantial government role in housing supply.$$,
        ARRAY['https://www.kgun9.com/news/local-news/mayor-romero-touts-housing-homelessness-and-health-gains-outlines-plan-to-expand-treatment-shelter-and-affordable-homes',
              'https://tucson.com/news/local/government-politics/article_3b35681f-5836-466a-982c-27c209303173.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / immigration (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$As mayor of a border city, Romero maintains Tucson's immigrant-welcoming posture — a Migrant Welcome Center and a 2022 Immigrant Support Task Force providing legal aid and resources — and has publicly called for an end to Title 42 and opposed the "Remain in Mexico" policy as harmful to asylum seekers. Her documented record supports keeping immigration channels open and letting residents access services regardless of status, rather than tightening legal immigration or restricting services.$$,
        ARRAY['https://tucson.com/news/local/border/article_b834a3ca-ab4e-11ef-ac4b-3b641756409c.html',
              'https://fronterasdesk.org/content/1775181/tucson-mayor-regina-romero-calls-end-title-42-debate-over-protocol-continues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / local-immigration (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Romero backs Tucson's welcoming-city framework and immigrant-support programs and has publicly opposed the Arizona proposal to constitutionally ban "sanctuary cities," arguing the city should not be forced into proactive federal immigration enforcement against its residents. Tucson's documented practice limits local cooperation with civil immigration enforcement and protects immigrant residents (including crime victims and witnesses) while still complying with binding legal orders — a limited-cooperation posture rather than proactive assistance to ICE.$$,
        ARRAY['https://www.kgun9.com/news/local-news/tucson-mayor-regina-romero-speaks-out-against-proposed-sanctuary-city-ban-in-arizona',
              'https://tucson.com/news/arizona_news/tucson-city-council-votes-to-oppose-constitutional-ban-on-sanctuary-cities/article_9f0ff4f5-b7a9-5b45-9592-b3a6c4d147ff.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Romero / transportation-priorities (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27e6aaca-8af5-4ec5-a30b-ac4aa19d2df5', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Romero championed 2022's Proposition 411 — a half-cent sales tax putting ~80% toward neighborhood street repair and ~20% toward bicycle/pedestrian safety, sidewalks and traffic-calming — and has repeatedly voted to keep Sun Tran/Sun Link transit fare-free (continued Sept. 2025), calling the fare-free system "absolutely worth the investment" so as not to "add additional burdens to our working families." Funding both road maintenance and multimodal/transit improvements reflects a balanced roads-plus-multimodal investment approach.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/051722_prop411_election/tucson-voters-overwhelmingly-ok-continued-1-2-cent-sales-tax-roads/',
              'https://www.tucsonspotlight.org/tucson-city-council-votes-to-keep-public-transit-fare-free/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

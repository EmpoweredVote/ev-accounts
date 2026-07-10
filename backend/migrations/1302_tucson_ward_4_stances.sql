-- =====================================================================================
-- Compass stances: Nikki Lee — City of Tucson (AZ) Council, Ward 4
-- ext_id: -4008005   politician_id: a289a080-4a6c-4a46-8772-84c02c2d4903
-- Democrat; council since Dec 2019, re-elected 2023; Air Force veteran, ex-cybersecurity.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   Cited from reachable non-WAF outlets (AZ Luminaria, Tucson Sentinel, tucson.com).
--   Discrete 1-5 chairs; no defaults; 8 judicial-* excluded. AUDIT-ONLY / unregistered.
--
-- SEEDED (5 topics):
--   data-centers              = 1  (voted for the 7-0 Project Blue rejection; said it "got off on the wrong foot")
--   homelessness-response     = 3  (services + public-drug-use response with expanded court availability; balanced)
--   housing                   = 3  (affordable housing + livable wages + job opportunity; pushed back on housing-funding cuts)
--   public-safety-approach    = 3  (focus on staffing/high-quality services + drug-use prevention + court capacity)
--   transportation-priorities = 3  (one of two votes to reinstate transit fares; fare-free "not sustainable" at ~9% of general fund)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   climate-change, deportation, economic-development, fossil-fuels,
--   growth-and-development, healthcare, homelessness, immigration, jail-capacity,
--   local-environment, local-immigration, medicare/aid, misinformation, redistricting,
--   religious-freedom, rent-regulation, residential-zoning, same-sex-marriage,
--   school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support,
--   voting-rights.  (judicial-* excluded, Pitfall 8.)
-- =====================================================================================

BEGIN;

-- ----- Lee / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Lee joined the Aug. 6, 2025 unanimous (7-0) council vote to reject the "Project Blue" data center, saying the project "got off on the wrong foot" and that the council had heard the public's opposition over recent weeks. (She separately cautioned the project could still be built through other paths regardless of the city's decision.) Her recorded vote was to halt the project within city limits — a stop-development position.$$,
        ARRAY['https://azluminaria.org/2025/08/06/tucson-city-council-rejects-project-blue-amid-intense-community-pressure/',
              'https://www.tucsonsentinel.com/local/report/080525_project_blue_alternatives/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lee / homelessness-response (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Lee pairs services with reasonable public-space accountability: she fought to preserve public-drug-use prevention funding amid budget cuts while also proposing to expand court capacity (a judge available core weekday hours) to address public drug use and safety. That combination of sustained services plus enforcing reasonable public-space rules fits an outreach-shelter-services-with-reasonable-enforcement approach.$$,
        ARRAY['https://azluminaria.org/2026/02/19/facing-27-million-deficit-tucson-leaders-push-back-on-cuts-to-housing-and-public-drug-ordinance/',
              'https://www.tucsonsentinel.com/local/report/102825_council_public_safety/tucson-council-candidates-struggle-with-solutions-public-safety-issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lee / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lee calls homelessness and affordable housing Tucson's greatest problems and links the fix to livable wages, affordable housing, and attracting businesses that create job opportunities; amid a $27M deficit she pushed back on cutting housing funding. Her approach favors targeted affordable-housing support and economic opportunity (subsidies/assistance plus jobs) rather than a maximal public-ownership program or a hands-off market.$$,
        ARRAY['https://azluminaria.org/2026/02/19/facing-27-million-deficit-tucson-leaders-push-back-on-cuts-to-housing-and-public-drug-ordinance/',
              'https://tucson.com/news/local/govt-and-politics/article_66628ce2-d963-11ed-a9e9-87a4a03cb494.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lee / public-safety-approach (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lee frames public safety around maintaining staffing and delivering "high-quality services" through voter-approved funding for parks, roads and public safety, and she emphasizes prevention (preserving public-drug-use prevention funding) plus added court capacity rather than either large cuts or a police-budget-first expansion. That fits keeping public-safety funding in place while adding response capacity for underlying drivers.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/102825_council_public_safety/tucson-council-candidates-struggle-with-solutions-public-safety-issues',
              'https://azluminaria.org/2023/10/13/voter-guide-tucsons-ward-4-city-council-race-between-nikki-lee-and-ross-kaplowitch/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lee / transportation-priorities (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a289a080-4a6c-4a46-8772-84c02c2d4903', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Lee was one of only two council members to vote to reinstate Sun Tran fares, arguing that keeping transit fare-free is "not sustainable" because the city directs roughly 9% of its general fund ("tens of millions of dollars") into transit, "which directly impacts our ability to invest in more services." Her fiscally cautious posture — maintain transit but on a sustainable, partly fare-funded basis while protecting funding for other services — fits a measured, maintain-and-selectively-invest transportation approach rather than an all-in transit-first stance.$$,
        ARRAY['https://azluminaria.org/2026/04/21/tucson-city-council-at-odds-on-how-to-move-forward-with-fare-free-transit/',
              'https://tucson.com/news/local/article_4374c767-9d30-4510-95e4-c67127a931ec.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

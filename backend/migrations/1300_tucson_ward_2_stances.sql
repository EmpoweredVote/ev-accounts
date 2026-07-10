-- =====================================================================================
-- Compass stances: Paul Cunningham — City of Tucson (AZ) Council, Ward 2
-- ext_id: -4008003   politician_id: 29c8d055-b661-4940-a052-20eece394d6f
-- Democrat; longtime council member (Ward 2), term through Dec 2027.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   Cited from reachable non-WAF outlets (AZ Luminaria, Tucson Sentinel, tucson.com).
--   Discrete 1-5 chairs; no defaults; 8 judicial-* excluded. AUDIT-ONLY / unregistered.
--
-- SEEDED (3 topics):
--   data-centers           = 1  (early opponent of Project Blue; ratepayer-cost + secrecy concerns; voted to reject)
--   homelessness-response  = 2  (unsheltered crisis his top priority; motel-shelter purchases + Ward 2 homeless-outreach specialist)
--   public-safety-approach = 3  (rejects the 1980s "catch the bad guys" model; also backs officer retention/hiring bonuses — modernized + funded)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   climate-change, deportation, economic-development, fossil-fuels,
--   growth-and-development, healthcare, homelessness, housing, immigration,
--   jail-capacity, local-environment, local-immigration, medicare/aid, misinformation,
--   redistricting, religious-freedom, rent-regulation, residential-zoning,
--   same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--   trans-athletes, transportation-priorities, ukraine-support, voting-rights.
--   (residential-zoning left blank: the 6-1 four-plex upzoning vote is documented but
--    his individual position within it was not separately confirmed. judicial-* excluded.)
-- =====================================================================================

BEGIN;

-- ----- Cunningham / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Cunningham was an early opponent of the "Project Blue" data center, saying since early July 2025 that he would vote against it. His stated concerns were that Tucson lacks a municipally owned power utility, so there was no way to guarantee data-center power buildout costs would not be passed to residential ratepayers, and he objected to the secrecy of the deal ("I smell a rat"). He joined the Aug. 6, 2025 unanimous vote to reject the project — a halt-development stance rather than conditional approval.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/071425_project_blue/tucson-deal-project-blue-data-centers-would-thirst-water-electricity/',
              'https://azluminaria.org/2025/08/06/tucson-city-council-rejects-project-blue-amid-intense-community-pressure/',
              'https://www.tucsonsentinel.com/local/report/080625_project_blue/tucson-city-council-pulls-plug-amazons-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cunningham / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Cunningham names the unsheltered crisis his top council priority and backs a services-and-shelter-first response: the city's ongoing purchase of motels converted to shelter with services, and he hired a dedicated Homeless Outreach Specialist for Ward 2 to speed service connections for people living unsheltered. That emphasis on expanding shelter capacity and outreach/services fits a shelter-and-services-primary strategy rather than an enforcement-first camping ban.$$,
        ARRAY['https://azluminaria.org/2023/10/13/voter-guide-tucsons-ward-2-city-council-race-among-paul-cunningham-ernie-shack-and-pendleton-spicer/',
              'https://tucson.com/news/local/govt-and-politics/2023-city-elections-meet-the-candidates-for-tucson-city-council-ward-2/article_faf6b9ec-d962-11ed-a5d9-8b48205780d7.html']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cunningham / public-safety-approach (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29c8d055-b661-4940-a052-20eece394d6f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Cunningham calls the 1980s "catching the bad guys" model of public safety antiquated and argues the city needs a broader, more modern approach — while also supporting the sworn workforce through officer retention/milestone bonuses and lateral hiring incentives. Keeping public-safety funding in place while modernizing beyond pure enforcement (broader response to underlying needs, not simply expanding the police budget) fits a keep-funding-and-add-modern-response approach.$$,
        ARRAY['https://azluminaria.org/2023/10/13/voter-guide-tucsons-ward-2-city-council-race-among-paul-cunningham-ernie-shack-and-pendleton-spicer/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

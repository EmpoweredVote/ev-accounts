-- =====================================================================================
-- Compass stances: Miranda Schubert — City of Tucson (AZ) Council, Ward 6
-- ext_id: -4008007   politician_id: bf1901df-040d-4005-86e9-ef3e975295b7
-- Democrat (DSA-endorsed); seated Dec 2, 2025 (succeeding Steve Kozachik).
-- Community organizer; founding member of the Transit for All Coalition.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   TENURE CAVEAT (T-194-TENURE): seated Dec 2025 — positions below are drawn from her
--   documented campaign record / candidate statements, NOT pre-tenure council votes.
--   Cited from reachable non-WAF outlets (Tucson Sentinel, Tucson Spotlight, AZPM).
--   Discrete 1-5 chairs; no defaults; 8 judicial-* excluded. AUDIT-ONLY / unregistered.
--
-- SEEDED (5 topics):
--   data-centers              = 1  (firm "no" on Project Blue over water-security/long-term impacts)
--   homelessness-response     = 2  ("we need more shelter, we need more affordable housing"; services+housing led)
--   housing                   = 2  (housing justice: tenant protections, community land trusts, zoning reform, anti-gentrification)
--   residential-zoning        = 2  (push zoning reforms for a diverse set of housing options / missing middle)
--   transportation-priorities = 1  (founding Transit for All Coalition member; protect fare-free buses; Complete Streets)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   climate-change, deportation, economic-development, fossil-fuels,
--   growth-and-development, healthcare, homelessness, immigration, jail-capacity,
--   local-environment, local-immigration, medicare/aid, misinformation,
--   public-safety-approach, redistricting, religious-freedom, rent-regulation,
--   same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--   trans-athletes, ukraine-support, voting-rights.  (judicial-* excluded, Pitfall 8.)
-- =====================================================================================

BEGIN;

-- ----- Schubert / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$At a July 2, 2025 League of Women Voters forum, Ward 6 candidate Schubert said she was a firm "no" on the Project Blue data center unless she learned more to alleviate concerns about the security of Tucson's water future and the long-term impacts on residents. She was among the Democratic council candidates who opposed the project — a stop/halt-development position on water- and energy-intensive data centers.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/072825_project_blue_council_races/dem-candidates-tucson-council-oppose-proposed-project-blue-data-center',
              'https://www.tucsonsentinel.com/local/report/072425_ward_6_race/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Schubert / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Schubert made homelessness an early priority and framed the answer around supply: "We need more shelter, we need more affordable housing," tying homelessness to housing and services rather than enforcement. That shelter-and-services-first framing fits expanding shelter capacity and services as the primary strategy.$$,
        ARRAY['https://www.tucsonspotlight.org/schubert-champions-housing-and-safety-in-ward-6-bid/',
              'https://www.tucsonspotlight.org/schubert-aims-to-bring-community-centered-approach-to-tucson-city-council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Schubert / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Schubert campaigned on "housing justice," promising to support tenant protections and community land trusts, advocate for policies creating a diverse set of housing options, push zoning reforms, and fight gentrification/displacement. That active, tenant-protective public role (community land trusts, publicly backed affordable options, anti-displacement rules) goes beyond targeted subsidies toward a substantial government role in housing.$$,
        ARRAY['https://www.tucsonspotlight.org/schubert-champions-housing-and-safety-in-ward-6-bid/',
              'https://news.azpm.org/p/azpmnews/2025/11/5/227159-dsa-support-helped-progressive-schubert-win-tucson-city-council-seat/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Schubert / residential-zoning (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$As part of her housing-justice platform, Schubert pledged to push zoning reforms that create a diverse set of housing options across the city. Reforming zoning to allow a wider mix of housing types — "missing middle" and beyond single-family-only — fits enabling greater residential density through incremental zoning change.$$,
        ARRAY['https://www.tucsonspotlight.org/schubert-champions-housing-and-safety-in-ward-6-bid/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Schubert / transportation-priorities (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bf1901df-040d-4005-86e9-ef3e975295b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Schubert is a founding member of the Transit for All Coalition (which advocates free buses in Tucson), promised to protect fare-free transit, and serves on the city's Complete Streets Coordinating Council; she argues that with ~43% of greenhouse-gas emissions coming from cars, expanding public transportation makes for a more sustainable, shaded, walkable city. That is a clear transit-and-active-transportation-first investment priority.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2025/11/5/227159-dsa-support-helped-progressive-schubert-win-tucson-city-council-seat/',
              'https://www.tucsonspotlight.org/schubert-aims-to-bring-community-centered-approach-to-tucson-city-council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- =====================================================================================
-- Compass stances: Selina Barajas — City of Tucson (AZ) Council, Ward 5
-- ext_id: -4008006   politician_id: 01feb7ad-df57-42bd-9533-073a9edf8c52
-- Democrat; seated Dec 2, 2025 (first woman elected in Ward 5, succeeding Richard
-- Fimbres). Urban planner (UCLA MURP).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY (see 1298 header for full conventions).
--   TENURE CAVEAT (T-194-TENURE): seated Dec 2025 — positions below are drawn from her
--   documented campaign record / candidate statements, NOT pre-tenure council votes.
--   Cited from reachable non-WAF outlets (AZ Luminaria, Tucson Sentinel, Tucson
--   Spotlight, UCLA Luskin). Discrete 1-5 chairs; no defaults; 8 judicial-* excluded.
--   AUDIT-ONLY / unregistered.
--
-- SEEDED (5 topics):
--   data-centers          = 1  (opposed Project Blue / "anything that damages our environment or overuses water")
--   economic-development  = 2  (community-focused development centering artists, entrepreneurs, small businesses)
--   homelessness-response = 2  (holistic, tailored pathways; invest in shelter beds + cooling spaces with dignity/services)
--   housing               = 3  (expand first-time homeownership via public-private partnerships; anti-displacement estate help)
--   local-environment     = 2  (environmental justice: clean air/water + more green space in the hottest, lowest-air-quality ward)
--
-- DELIBERATELY BLANK (no clear attributable documented position found): abortion,
--   ai-regulation, campaign-finance, childcare, city-sanitation, civil-rights,
--   climate-change, deportation, fossil-fuels, growth-and-development, healthcare,
--   homelessness, immigration, jail-capacity, local-immigration, medicare/aid,
--   misinformation, public-safety-approach, redistricting, religious-freedom,
--   rent-regulation, residential-zoning, same-sex-marriage, school-vouchers,
--   social-security, tariffs, taxes, trans-athletes, transportation-priorities,
--   ukraine-support, voting-rights.  (judicial-* excluded, Pitfall 8.)
-- =====================================================================================

BEGIN;

-- ----- Barajas / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '4559b513-0fd8-4ed1-babd-f3b554162f40', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$As a Ward 5 candidate during the 2025 Project Blue controversy, Barajas said she was opposed to "anything that damages our environment or overuses water," aligning her with the Democratic council candidates who opposed the data center. Her documented campaign position is to block water- and energy-intensive data-center development rather than approve it.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/072825_project_blue_council_races/',
              'https://azluminaria.org/2025/10/09/tucson-city-council-election-2025-where-candidates-stand-on-housing-transit-taxes/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barajas / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Barajas's campaign centered "community-focused economic development" built around the needs of local artists, entrepreneurs and small businesses and reducing their barriers to resources, rather than competing for large employers with big subsidies. That emphasis on local small-business and entrepreneur support fits a small-business-first economic-development approach.$$,
        ARRAY['https://www.tucsonspotlight.org/barajas-champions-community-needs-in-ward-5/',
              'https://luskin.ucla.edu/selina-barajas-championing-community-culture-and-equity-in-tucsons-ward-5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barajas / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Barajas describes homelessness as complex and situation-specific (addiction, mental illness, lack of ID, criminal records, pet ownership) and proposes holistic, tailored pathways developed with existing nonprofits, plus investing in more shelter beds and cooling spaces "with dignity, programming, and a clear path toward stability." That services-and-shelter-expansion focus fits expanding shelter capacity and services as the primary strategy.$$,
        ARRAY['https://azluminaria.org/2025/10/09/tucson-city-council-election-2025-where-candidates-stand-on-housing-transit-taxes/',
              'https://www.tucsonspotlight.org/barajas-champions-community-needs-in-ward-5/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barajas / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Barajas wants to expand homeownership for Ward 5 residents — especially first-time buyers — through strategic public-private partnerships and "generational" solutions, and to help longtime homeowners with estate planning to prevent displacement. That mix of first-time-buyer assistance and targeted public-private tools fits a targeted-help housing approach rather than direct public housing or a hands-off market.$$,
        ARRAY['https://luskin.ucla.edu/selina-barajas-championing-community-culture-and-equity-in-tucsons-ward-5',
              'https://www.tucsonspotlight.org/barajas-champions-community-needs-in-ward-5/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Barajas / local-environment (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01feb7ad-df57-42bd-9533-073a9edf8c52', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Environmental justice is a core Barajas priority: she notes Ward 5 is the city's hottest ward with the lowest air quality and has made guaranteeing safe clean water and building more green spaces an early focus, championing clean air, water and safe green spaces. That strong protect-and-expand-green-space, clean-air/water posture fits robust local environmental protection.$$,
        ARRAY['https://luskin.ucla.edu/selina-barajas-championing-community-culture-and-equity-in-tucsons-ward-5',
              'https://www.tucsonspotlight.org/barajas-champions-community-needs-in-ward-5/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

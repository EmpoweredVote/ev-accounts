-- =====================================================================================
-- Compass stances: Kara Egbert — Vice Mayor, Town of Sahuarita (AZ)
-- politician_id: 071e2a28-2fef-489a-97e3-15fb5caaee51   (external_id -4014002)
-- Nonpartisan. On the Town Council since 2009 (re-elected 2013); chosen Vice Mayor by the
-- council in 2018 (Vice Mayor is a council-selected TITLE, not a directly elected office).
-- CONFIRMED NOT seeking re-election to Council in 2026 (running instead for Precinct 7
-- Justice of the Peace) — positions below stance her documented record WHILE SEATED only.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Egbert position (an
--     on-record statement in a citable council-candidate Q&A or her official Town bio).
--   * Topics with no clear documented Egbert position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics in scope; the 8
--   judicial-* topics are NEVER seeded for a town official):
--     economic-development      = eb3d1247-0de1-4b7f-baec-7259861efd53
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--     taxes                     = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (3 topics):
--   economic-development   = 4  ("We've increased shopping, employers, parks, roads and residents";
--                                official priority is economic development / bringing the community
--                                together)
--   growth-and-development = 4  ("We've streamlined processes to be efficient for residents and
--                                developers"; touts sustained residential/commercial growth)
--   taxes                  = 2  (voted for the June 10, 2024 unanimous $66M GO bond — a new ~$205/yr
--                                secondary property-tax levy — to fund a rec center, police expansion,
--                                and parks: raising revenue to expand public facilities/services)
--
-- DELIBERATELY BLANK (no clean, attributable documented Egbert position found):
--   Copper World / Hudbay mine & water: no citable Egbert statement or town vote on the mine or
--     water allocation; BLANK. (Fellow member Morales, not Egbert, is the one on record
--     researching Hudbay.)
--   public-safety-approach, housing, transportation-priorities: named as general priorities but
--     with no vote/budget/standard specific enough to map to a chair; BLANK.
--   Other local (data-centers, residential-zoning, homelessness-response, local-immigration,
--     local-environment, climate-change, city-sanitation, etc.): no citable Egbert position.
--   Non-local federal/state (a town vice mayor has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Kara Egbert / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Egbert's record centers on actively expanding Sahuarita's commercial and employment base. In the Green Valley News council-candidate Q&A she summarized her tenure by pointing to results: "We've increased shopping, employers, parks, roads and residents." The Town Council roster likewise lists her defining priority around bringing the community together and sustaining the town's economic maturation (she has described the town as "still young and growing up to adulthood" with more of that path to travel). Treating recruitment of shopping and employers as a core, ongoing town objective — rather than offering no incentives / organic growth only (chair 1) or supporting only small/local business (chair 2) — matches actively competing for and recruiting employers to build the town's economy (chair 4).$$,
        ARRAY['https://www.gvnews.com/news/sahuarita-town-council-q-a/article_289a5536-fc8f-11ec-b4ce-275f084d8941.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kara Egbert / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Egbert is a pro-growth incumbent who highlights making the town's approval process faster for builders. In the Green Valley News council-candidate Q&A she wrote that during her tenure "We've streamlined processes to be efficient for residents and developers," alongside increases in "shopping, employers, parks, roads and residents." Explicitly touting streamlined development processing and sustained residential/commercial growth — rather than growth caps (chair 1), pausing growth until infrastructure catches up (chair 2), or merely planning infrastructure alongside growth (chair 3) — matches streamlining approvals to encourage and accommodate development (chair 4).$$,
        ARRAY['https://www.gvnews.com/news/sahuarita-town-council-q-a/article_289a5536-fc8f-11ec-b4ce-275f084d8941.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kara Egbert / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('071e2a28-2fef-489a-97e3-15fb5caaee51',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Vice Mayor, Egbert was part of the Town Council that on June 10, 2024 unanimously approved a $66 million General Obligation bond resolution for the November ballot — funding a $48M multigenerational recreation center, a $7.5M police-department building expansion, a $7M town-hall remodel, a $2.97M sports-court complex, and public-works and parks/trails improvements, at an estimated cost to taxpayers of "$17.12 per month, or $205.44 per year." Voting to authorize a new secondary-property-tax-backed bond of that size to build out and expand public facilities and services — rather than keeping the town's revenue structure as-is (chair 3) or cutting taxes and scaling back services (chairs 4-5) — matches raising public revenue to fund and expand community services and infrastructure (chair 2).$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

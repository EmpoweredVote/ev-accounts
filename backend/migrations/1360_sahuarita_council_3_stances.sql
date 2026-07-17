-- =====================================================================================
-- Compass stances: Diane Priolo — Council Member, Town of Sahuarita (AZ)
-- politician_id: b9ea3ef0-d4cf-4231-956d-376b6e626ae4   (external_id -4014005)
-- Nonpartisan, at-large. Appointed June 2022 to a vacancy, elected in her own right Aug.
-- 2022, re-elected 2024 (term to 2028). Positions attributed only to her own on-record
-- statements and recorded Council votes.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Priolo position (a recorded
--     Council vote or an on-record 2024 candidate-Q&A statement).
--   * Topics with no clear documented Priolo position emit NO row (honest blank).
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics in scope; the 8
--   judicial-* topics are NEVER seeded for a town official):
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--     taxes                     = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (2 topics):
--   taxes                  = 2  (voted for the June 10, 2024 unanimous $66M GO bond — a new ~$205/yr
--                                secondary property-tax levy — to fund a rec center, police expansion,
--                                and parks: raising revenue to expand public facilities/services)
--   growth-and-development = 3  (supports development only conditionally and at specific intersections;
--                                names adequate water supply, wastewater and infrastructure as the
--                                preconditions — a measured, infrastructure-first growth posture)
--
-- DELIBERATELY BLANK (no clean, attributable documented Priolo position found):
--   Copper World / Hudbay mine & water: Priolo names "adequate water supply" and "wastewater
--     management services" among her top concerns and has been engaged on the town's water/mine
--     information-gathering, but her documented posture is diligence/concern (the council is
--     "continuing to gather information"), not a policy that maps to a local-environment or water
--     chair; BLANK (documented but not chair-mappable).
--   economic-development: her retail wishes (a Trader Joe's, "Mom and Pop-type retail stores and
--     restaurants") are captured within growth-and-development; no distinct employer-recruitment
--     position citable.
--   public-safety-approach: names "a safe community" as a concern but with no specific approach/
--     budget to map to a chair; BLANK.
--   housing, data-centers, transportation-priorities, residential-zoning, homelessness-response,
--     local-immigration, climate-change, city-sanitation: no citable position.
--   Non-local federal/state (a town council member has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Diane Priolo / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9ea3ef0-d4cf-4231-956d-376b6e626ae4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9ea3ef0-d4cf-4231-956d-376b6e626ae4',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Priolo was part of the Town Council that on June 10, 2024 unanimously approved a $66 million General Obligation bond resolution for the November ballot — funding a $48M multigenerational recreation center, a $7.5M police-department building expansion, a $7M town-hall remodel, a $2.97M sports-court complex, and public-works and parks/trails improvements, at an estimated "$17.12 per month, or $205.44 per year" to taxpayers. Voting to authorize a new secondary-property-tax-backed bond of that size to build out and expand public facilities and services — rather than keeping the town's revenue structure as-is (chair 3) or cutting taxes and scaling back services (chairs 4-5) — matches raising public revenue to fund and expand community services and infrastructure (chair 2).$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diane Priolo / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b9ea3ef0-d4cf-4231-956d-376b6e626ae4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b9ea3ef0-d4cf-4231-956d-376b6e626ae4',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Priolo's growth posture is conditional and infrastructure-first. In the Green Valley News 2024 candidate Q&A she framed new development as contingent — "If and when we see development as a result of the Quail Crossing Blvd...it will be at either intersections" — and identified as her major concerns "adequate water supply, wastewater management services, a safe community, coupled with a well maintained infrastructure," while expressing a preference for specific retail (a Trader Joe's, "Mom and Pop-type retail stores and restaurants"). Welcoming measured, node-specific development but insisting that water, wastewater and infrastructure capacity keep pace — rather than growth caps (chair 1), pausing growth (chair 2), or aggressively streamlining/recruiting all development (chair 4) — matches a balanced, plan-infrastructure-alongside-growth approach (chair 3).$$,
        ARRAY['https://www.gvnews.com/news/q-a-sahuarita-town-council-candidates/article_8d54ad14-1a29-11ef-bda6-c7fab303806a.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

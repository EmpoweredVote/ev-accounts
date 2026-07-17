-- =====================================================================================
-- Compass stances: Dr. Steven Gillespie — Council Member, Town of Sahuarita (AZ)
-- politician_id: 9f846d00-9bcd-43cd-b57f-628d031d531c   (external_id -4014004)
-- Nonpartisan, at-large. Appointed June 2022 to a vacancy, elected in his own right Aug.
-- 2022, re-elected 2024 (term to 2028). Doctor of Podiatric Medicine. Positions attributed
-- only to his own on-record statements and recorded Council votes.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Gillespie position (a
--     recorded Council vote or an on-record 2024 candidate-Q&A statement).
--   * Topics with no clear documented Gillespie position emit NO row (honest blank).
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics in scope; the 8
--   judicial-* topics are NEVER seeded for a town official):
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--     public-safety-approach    = e9ebefcd-c496-45e8-b816-a79f8442ba85
--     taxes                     = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (3 topics):
--   public-safety-approach = 4  (top priority is expanding the police department's physical space
--                                as the town grows; voted for the bond's $7.5M police expansion)
--   taxes                  = 2  (voted for the June 10, 2024 unanimous $66M GO bond — a new ~$205/yr
--                                secondary property-tax levy — to fund a rec center, police expansion,
--                                and parks: raising revenue to expand public facilities/services)
--   growth-and-development = 3  (wants targeted commercial development at specific nodes but
--                                emphasizes infrastructure maintenance and services keeping pace)
--
-- DELIBERATELY BLANK (no clean, attributable documented Gillespie position found):
--   Copper World / Hudbay mine & water: no citable individual Gillespie statement or standalone
--     town vote on the mine or water; BLANK.
--   economic-development: his commercial-development wish is captured under growth-and-development;
--     no distinct employer-recruitment position citable.
--   housing, data-centers, transportation-priorities, residential-zoning, homelessness-response,
--     local-immigration, local-environment, climate-change, city-sanitation: no citable position.
--   Non-local federal/state (a town council member has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Steven Gillespie / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gillespie puts investment in policing capacity at the center of his agenda. In the Green Valley News 2024 candidate Q&A he named expanding "the physical space of the police department" as the town grows among his top priorities, alongside a recreation center and infrastructure maintenance, and his Town bio says he "values Sahuarita's community spirit and safety." He then voted for the June 10, 2024 bond package that dedicates $7.5 million specifically to a Police Department building expansion. That posture of growing police staffing, facilities and resources — with no mention of redirecting police funds (chair 1) or adding unarmed/mental-health co-responder teams (chairs 2-3) — matches prioritizing police resources and capacity to deter crime (chair 4).$$,
        ARRAY['https://www.gvnews.com/news/q-a-sahuarita-town-council-candidates/article_8d54ad14-1a29-11ef-bda6-c7fab303806a.html',
              'https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Gillespie / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Gillespie was part of the Town Council that on June 10, 2024 unanimously approved a $66 million General Obligation bond resolution for the November ballot — a package funding a $48M multigenerational recreation center, a $7.5M police-department building expansion, a $7M town-hall remodel, a $2.97M sports-court complex, and public-works and parks/trails improvements, at an estimated cost to taxpayers of "$17.12 per month, or $205.44 per year." Voting to authorize a new secondary-property-tax-backed bond of that size to build out and expand public facilities and services — rather than keeping the town's revenue structure as-is (chair 3) or cutting taxes and scaling back services (chairs 4-5) — matches raising public revenue to fund and expand community services and infrastructure (chair 2).$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven Gillespie / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f846d00-9bcd-43cd-b57f-628d031d531c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Gillespie is growth-positive but frames it around infrastructure and amenities keeping pace. His Town bio says he is "committed to fostering growth, collaboration, and active engagement with residents," and in the 2024 candidate Q&A he said, "I would like to see more commercial developments at the intersection of Quail Crossing Blvd and South Nogales Hwy near the Circle K," while listing infrastructure maintenance, police-department expansion and a multi-generational recreation center among his priorities. Welcoming targeted new commercial development while stressing that infrastructure and public facilities must be built out to serve it — rather than growth caps (chair 1), pausing growth (chair 2), or aggressively streamlining/recruiting all development to grow the tax base (chair 4) — matches a balanced, plan-infrastructure-alongside-growth approach (chair 3).$$,
        ARRAY['https://www.gvnews.com/news/q-a-sahuarita-town-council-candidates/article_8d54ad14-1a29-11ef-bda6-c7fab303806a.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

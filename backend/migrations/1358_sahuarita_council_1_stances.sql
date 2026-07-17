-- =====================================================================================
-- Compass stances: Deborah Morales — Council Member, Town of Sahuarita (AZ)
-- politician_id: c2553fba-f62f-4d58-8a9e-c183f9e8f15d   (external_id -4014003)
-- Nonpartisan, at-large. Former Town 911 dispatcher and permit clerk (first former Town
-- employee elected to the Council); re-elected 2022; running to retain her seat in the
-- July 21, 2026 primary. Positions attributed only to her own on-record statements.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Morales position.
--   * Topics with no clear documented Morales position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics in scope; the 8
--   judicial-* topics are NEVER seeded for a town official):
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--     taxes                     = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (2 topics):
--   growth-and-development = 3  (supports strategic eastward annexation to secure water rights,
--                                but conditions neighborhood annexation on homeowner consent —
--                                a measured, case-by-case expansion posture)
--   taxes                  = 2  (voted for the June 10, 2024 unanimous $66M GO bond — a new ~$205/yr
--                                secondary property-tax levy — to fund a rec center, police expansion,
--                                and parks: raising revenue to expand public facilities/services)
--
-- DELIBERATELY BLANK (no clean, attributable documented Morales position found):
--   Copper World / Hudbay mine & water: Morales is on record that water is "a major concern" and
--     that she "continue[s] to research HudBay," and she framed eastward annexation partly as a
--     way to "own water rights" — but a "concern / still researching" posture is not a policy that
--     maps to a local-environment or water chair; BLANK (documented but not chair-mappable).
--   public-safety-approach: safety is her single most-stated priority (former 911 dispatcher;
--     "prioritize safety," "make sure the safety of residents and employees are continuously met")
--     but with no vote/budget/approach specific enough to map to a chair; BLANK.
--   economic-development, housing, data-centers, transportation-priorities, residential-zoning,
--     homelessness-response, local-immigration, climate-change, city-sanitation: no citable Morales
--     position (her 2026 candidate Q&A/VOTE411 entries were unsubmitted/blank at research time).
--   Non-local federal/state (a town council member has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Deborah Morales / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2553fba-f62f-4d58-8a9e-c183f9e8f15d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2553fba-f62f-4d58-8a9e-c183f9e8f15d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Morales's documented growth posture is measured and case-by-case. In the Green Valley News Sahuarita Town Council Q&A she said, "Yes I do support the annexation going east. It would be an awesome opportunity for Sahuarita [to] own water rights that come with the annexation" — favoring strategic expansion of the town's footprint to secure water and resources. But she paired that with a consent condition on neighborhood annexation: "I am not opposed to annexing a neighborhood unless the homeowners decide they are interested in being a part of Sahuarita." Supporting deliberate, resource-driven expansion while conditioning it on residents' wishes — rather than hard growth caps (chair 1), pausing growth (chair 2), or streamlining/aggressively recruiting all development to grow the tax base (chair 4) — matches a balanced, plan-as-you-grow approach that weighs benefits case by case (chair 3).$$,
        ARRAY['https://www.gvnews.com/news/sahuarita-town-council-q-a/article_289a5536-fc8f-11ec-b4ce-275f084d8941.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Deborah Morales / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2553fba-f62f-4d58-8a9e-c183f9e8f15d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2553fba-f62f-4d58-8a9e-c183f9e8f15d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Morales was part of the Town Council that on June 10, 2024 unanimously approved a $66 million General Obligation bond resolution for the November ballot — funding a $48M multigenerational recreation center, a $7.5M police-department building expansion, a $7M town-hall remodel, a $2.97M sports-court complex, and public-works and parks/trails improvements, at an estimated cost to taxpayers of "$17.12 per month, or $205.44 per year." Voting to authorize a new secondary-property-tax-backed bond of that size to build out and expand public facilities and services — rather than keeping the town's revenue structure as-is (chair 3) or cutting taxes and scaling back services (chairs 4-5) — matches raising public revenue to fund and expand community services and infrastructure (chair 2).$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

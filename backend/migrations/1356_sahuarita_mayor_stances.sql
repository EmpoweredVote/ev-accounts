-- =====================================================================================
-- Compass stances: Tom Murphy — Mayor, Town of Sahuarita (AZ)
-- politician_id: f32cba1e-d672-440a-9a18-41a312119f40   (external_id -4014001)
-- Nonpartisan. Elected to the Town Council in 2013 (most recently 2022); chosen Mayor by
-- the council in Dec. 2016 (Mayor is a council-selected TITLE in Sahuarita, not a directly
-- elected office). Running in the July 21, 2026 primary to retain his at-large Council seat.
-- Positions attributed only to his own on-record statements/bio; no other member's views.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Murphy position (an
--     on-record statement in a citable candidate Q&A or his official Town bio).
--   * Topics with no clear documented Murphy position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics are in scope;
--   the 8 judicial-* topics are NEVER seeded for a town official):
--     economic-development      = eb3d1247-0de1-4b7f-baec-7259861efd53
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--     taxes                     = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (3 topics):
--   economic-development   = 4  (official bio: "furthering the economic development of the town
--                                is the key"; "passionate about economic development"; proactive
--                                business/employer recruitment framing)
--   growth-and-development = 4  ("Our town's future — public safety, infrastructure, parks, schools
--                                and character depends on a strong and growing tax base"; pro-growth)
--   taxes                  = 2  (voted for the June 10, 2024 unanimous $66M GO bond — a new ~$205/yr
--                                secondary property-tax levy — to fund a rec center, police expansion,
--                                and parks: raising revenue to expand public facilities/services)
--
-- DELIBERATELY BLANK (no clean, attributable documented Murphy position found):
--   Copper World / Hudbay mine & water: The council's on-record posture is a JURISDICTIONAL
--     DEFERRAL — Murphy and the council state they "cannot comment on the matter since the mine
--     is outside their jurisdiction" and are "continuing to gather information" (KGUN, 2025/2026).
--     No town vote or citable Murphy environmental-review position exists to map to a chair, so
--     local-environment stays BLANK (honest). (Reporting that Murphy separately endorsed Copper
--     World for jobs appeared in tucson.com, which could not be fetched this session — not cited.)
--   (His "strong and growing tax base" line is captured under growth-and-development; his
--    fiscal posture is otherwise seeded via the bond vote under taxes, above.)
--   transportation-priorities: he opposes Phase 3 of the Sonoran Corridor (El Toro Rd alignment) —
--     opposition to one specific state highway leg, which does not map to the road-vs-transit
--     chairs; BLANK.
--   public-safety-approach: "strong public safety" named as a priority, but with no vote/budget/
--     standard specific enough to map to a chair; BLANK.
--   Other local (data-centers, housing, residential-zoning, homelessness-response, local-immigration,
--     climate-change, city-sanitation, etc.): no citable Murphy position.
--   Non-local federal/state (a town mayor has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Tom Murphy / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Economic development is the throughline of Murphy's public record as Mayor. His official Town bio states that "furthering the economic development of the town is the key to making the town a place where everyone will want to call Sahuarita home," describing an approach built on "economic development, mutually beneficial relationships, and drawing all elements of the community together." The Town Council roster page likewise identifies his defining priority as being "passionate about economic development and building a community where everyone wants to call Sahuarita home." That posture of actively pursuing employers and business investment to build the town's economy — rather than offering no incentives / relying on organic growth (chair 1) or limiting support to small/local business (chair 2) — matches actively competing for major employers and treating economic development as the town's central strategy (chair 4).$$,
        ARRAY['https://sahuaritaaz.gov/directory.aspx?EID=146',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tom Murphy / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Murphy ties the town's future directly to continued growth and an expanding tax base. In the Green Valley News 2026 council-candidate Q&A he wrote, "Our town's future — public safety, infrastructure, parks, schools and character depends on a strong and growing tax base," and said he "remain[s] passionate about serving our community." His official bio frames "communication and collaboration" as "vital to our growth and success." That is a deliberately pro-growth stance that welcomes and encourages development to grow the tax base and fund town services — rather than growth caps (chair 1), pausing growth until infrastructure catches up (chair 2), or merely planning infrastructure alongside growth (chair 3) — matching streamlining/encouraging development to grow the tax base (chair 4).$$,
        ARRAY['https://www.gvnews.com/news/local/q-a-sahuarita-town-council-election/article_6f72fd43-500d-431f-9296-9b955ad7ae46.html',
              'https://sahuaritaaz.gov/directory.aspx?EID=146']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tom Murphy / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f32cba1e-d672-440a-9a18-41a312119f40',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Mayor, Murphy was part of the Town Council that on June 10, 2024 unanimously approved a $66 million General Obligation bond resolution for the November ballot — funding a $48M multigenerational recreation center, a $7.5M police-department building expansion, a $7M town-hall remodel, a $2.97M sports-court complex, and public-works and parks/trails improvements, at an estimated cost to taxpayers of "$17.12 per month, or $205.44 per year." Voting to authorize a new secondary-property-tax-backed bond of that size to build out and expand public facilities and services — rather than keeping the town's revenue structure as-is (chair 3) or cutting taxes and scaling back services (chairs 4-5) — matches raising public revenue to fund and expand community services and infrastructure (chair 2).$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/sahuarita/sahuarita-town-council-approves-66-million-bond-resolution-for-november-ballot']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

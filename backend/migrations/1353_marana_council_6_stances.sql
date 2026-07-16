-- =====================================================================================
-- Compass stances: John Officer — Council Member, Town of Marana (AZ)
-- politician_id: d2690186-3c41-455f-b2c4-a94cb8eb5ff5
-- Nonpartisan; appointed to Council 2017, incumbent seeking re-election in the
-- July 21, 2026 town election. Positions attributed only to his own recorded
-- Council votes and on-record forum statements.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Officer position (a recorded
--     Council vote or an on-record candidate-forum statement), with real cited source URLs
--     confirmed via web research.
--   * Topics with no clear documented Officer position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (2 topics):
--   data-centers            = 4  (voted FOR the Jan 6 2026 Luckett Rd/Project Blue data-center
--                                 rezoning; told the incumbent forum the supporting infrastructure
--                                 "is there ... it's sound" — encouraging development, confident
--                                 capacity/vetting supports it)
--   growth-and-development  = 3  ("Marana has always stuck with sustainable growth. Growth pays
--                                 for growth ... we do our research on it"; campaign theme
--                                 "Keeping Marana Moving Forward, Sustainably" — proactive,
--                                 responsible, infrastructure-supported expansion)
--
-- DELIBERATELY BLANK (no clear attributable documented Officer position found):
--   Local: campaign-finance, city-sanitation, economic-development, homelessness,
--          homelessness-response, housing, local-environment, local-immigration,
--          public-safety-approach, rent-regulation, residential-zoning, taxes,
--          transportation-priorities.
--          (On local-immigration / the proposed ICE detention facility: Officer declined the
--          AZ Luminaria interview and did not attend the July 9 League of Women Voters forum
--          where ICE was discussed, so there is no attributable Officer position on local
--          immigration-enforcement cooperation — the axis this topic measures. His forum water
--          and road-extension remarks do not map cleanly to any compass chair.)
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, civil-rights, climate-change, deportation, fossil-fuels, healthcare,
--          immigration, jail-capacity, medicare/aid, misinformation, redistricting,
--          religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs,
--          trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- John Officer / data-centers (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2690186-3c41-455f-b2c4-a94cb8eb5ff5',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2690186-3c41-455f-b2c4-a94cb8eb5ff5',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$On Jan. 6, 2026 the Marana Town Council voted to rezone roughly 661 acres of agricultural land for the Luckett Road hyperscale data-center project (developed by Beale Infrastructure); AZ Luminaria's 2026 election guide reports that Council members "Officer and Murphy voted in favor" of the rezoning. At the incumbent candidate forum (reported June 24, 2026), Officer defended the project's readiness, saying "the infrastructure is there to maintain whatever they're going to put in (the data center). It's sound," and framed the town's vetting as "we do our research on it." That record — voting to approve the development and publicly vouching that existing infrastructure can support it after review — is an encouraging, proceed-with-transparency posture toward data-center growth (chair 4), rather than conditioning approval on mandated community-benefit/cost-sharing agreements (chair 3), restricting or pausing development (chairs 1-2), or an ideological minimal-barriers/incentives stance (chair 5), neither of which he articulated.$$,
        ARRAY['https://azluminaria.org/2026/06/22/marana-2026-election-guide-what-candidates-say-about-ice-detention-center-data-center/',
              'https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John Officer / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d2690186-3c41-455f-b2c4-a94cb8eb5ff5',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d2690186-3c41-455f-b2c4-a94cb8eb5ff5',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Asked about growth at the incumbent candidate forum (reported June 24, 2026), Officer said, "Marana has always stuck with sustainable growth. Growth pays for growth and we take into consideration things that are brought forward to us and we do our research on it," and pointed to long-range planning such as a "10-year plan" road extension. His campaign runs under the theme "Keeping Marana Moving Forward, Sustainably." A former Planning & Zoning commissioner, he frames growth as something the town plans for responsibly, funds through the growth itself, and studies before acting. That posture — proactive, infrastructure-supported, responsible expansion — matches planning ahead to support responsible growth (chair 3), rather than hard growth caps/voter-approval limits (chairs 1-2) or actively removing barriers and recruiting development to maximize the tax base (chairs 4-5).$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html',
              'https://officer4marana.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- =====================================================================================
-- Compass stances: Josh Nicolson — Oro Valley (AZ) Town Council Member
-- politician_id: 889fe40e-425a-44cc-864f-b191d7c226ae
-- Nonpartisan; elected on the Winfield slate (re-elected 2022), NOT seeking reelection in
-- 2026. Air-traffic controller; Oro Valley resident since 2012. Tenure ~2022–present.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record campaign
--     platform statement or recorded Council vote) taken by Nicolson, with real cited source
--     URLs confirmed via web research.
--   * Topics with no clear documented Nicolson position emit NO row (honest blank). No party
--     inference (he is nonpartisan anyway), no neutral defaults.
--   * Nicolson has a THIN public issue record; a single well-documented seed is the honest,
--     correct result.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (1 topic):
--   growth-and-development = 2  (campaign platform: "striking a balance" between development
--                                and "preserving the irreplaceable beauty"; slate won by
--                                opposing developer-driven overdevelopment / desert destruction)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, city-sanitation, civil-rights, climate-change, data-centers,
--          economic-development, fossil-fuels, homelessness, homelessness-response, housing,
--          jail-capacity, local-environment, local-immigration, public-safety-approach,
--          religious-freedom, rent-regulation, residential-zoning, trans-athletes,
--          transportation-priorities.
--     (His land-use votes — e.g. the May 2026 Oro Valley Town Center parcel and a March 2024
--      apartment rezoning — were parcel-specific and driven by taxpayer-revenue/flexibility
--      concerns, and pointed in opposite directions on density, so they do NOT establish a
--      coherent residential-zoning chair and are left blank. His fiscal votes, e.g. the
--      June 2025 half-cent-sales-tax fund shift, have no matching compass topic.)
--   Non-local federal/state (a town councilmember has no record on these): abortion,
--          ai-regulation, childcare, deportation, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers, social-security,
--          tariffs, taxes, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Josh Nicolson / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('889fe40e-425a-44cc-864f-b191d7c226ae',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('889fe40e-425a-44cc-864f-b191d7c226ae',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$On his campaign platform Nicolson noted the "large amount of construction going on in our town" and argued Oro Valley "can do much to make sure our town is striking a balance between providing for our human citizens and preserving the irreplaceable beauty," urging that development decisions weigh "climate issues that are certain to affect us more and more in the future" and pledging to work "for all the people of Oro Valley, not for any specific group or business." He was elected as part of the Winfield slate, which won office by campaigning against a prior council majority it accused of being too close to developers and responsible for "excessive destruction of the desert and undesirable development." His documented position favors restrained, balanced growth that preserves the town's natural desert setting and slows developer-driven expansion — not aggressive recruitment of development, but also not a hard growth cap or moratorium.$$,
        ARRAY['https://joshfororovalley.com/index.php/issues/',
              'https://tucson.com/news/local/govt-and-politics/article_3a15c5ce-a4cb-5e2b-939f-72ac1bd07d0f.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

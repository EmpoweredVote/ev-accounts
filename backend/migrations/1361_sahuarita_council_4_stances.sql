-- =====================================================================================
-- Compass stances: Kim Lisk — Council Member, Town of Sahuarita (AZ)
-- politician_id: 866f1db3-4614-4d4f-a68b-96a2b7767091   (external_id -4014006)
-- Nonpartisan, at-large. Elected July 2024, SWORN IN NOV. 18, 2024 (term to 2028). Moved to
-- Sahuarita in 2022 from Carnation, WA (prior city-council/mayor experience there).
-- TENURE NOTE: no Sahuarita Council vote or action before Nov. 2024 is attributed to her —
-- in particular the June 10, 2024 town bond vote is NOT attributed to Lisk. Only her own
-- on-record 2024 candidate statements (and any documented post-seating position) are used.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Lisk position.
--   * Topics with no clear documented Lisk position emit NO row (honest blank).
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live compass topics in scope; the 8
--   judicial-* topics are NEVER seeded for a town official):
--     growth-and-development    = fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--
-- SEEDED (1 topic):
--   growth-and-development = 3  (supports additional retail along the Nogales Hwy extension but
--                                requires developer-funded mitigation — road widening, keeping the
--                                walking path — and stresses "the right mix of residential and
--                                commercial" while preventing congestion / preserving quality of life)
--
-- DELIBERATELY BLANK (no clean, attributable documented Lisk position found):
--   Copper World / Hudbay mine, water, data-centers: no citable individual Lisk statement or
--     standalone vote located for 2024-2026; BLANK. (No pre-Nov-2024 town action attributed to her.)
--   taxes: the June 2024 $66M bond predates her swearing-in, so it is NOT attributed to Lisk; no
--     other citable tax/spending position; BLANK.
--   economic-development: her retail-development comments are captured under growth-and-development;
--     no distinct employer-recruitment position citable.
--   public-safety-approach, housing, transportation-priorities, residential-zoning,
--     homelessness-response, local-immigration, local-environment, climate-change, city-sanitation:
--     no citable position.
--   Non-local federal/state (a town council member has no governing record): abortion, ai-regulation,
--     civil-rights, deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Kim Lisk / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('866f1db3-4614-4d4f-a68b-96a2b7767091',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('866f1db3-4614-4d4f-a68b-96a2b7767091',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Lisk's growth posture pairs support for new retail with mandatory developer mitigation and congestion control. In the Green Valley News 2024 candidate Q&A she said "The 1.6-mile extension from Old Nogales to South Nogales highways seems to be ideal for additional retail," but insisted "Any development along this stretch must include mitigation from the developers to expand the road width and keep the walking path," and framed her overall approach as getting "the right mix of residential and commercial" while preserving quality of life and preventing congestion. Welcoming development but conditioning it on developer-funded infrastructure mitigation and a balanced land-use mix — rather than growth caps (chair 1), pausing growth (chair 2), or aggressively streamlining/recruiting all development (chair 4) — matches a balanced, plan-infrastructure-alongside-growth approach (chair 3).$$,
        ARRAY['https://www.gvnews.com/news/q-a-sahuarita-town-council-candidates/article_8d54ad14-1a29-11ef-bda6-c7fab303806a.html',
              'https://sahuaritaaz.gov/274/Town-Council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

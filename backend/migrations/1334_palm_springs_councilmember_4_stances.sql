-- =====================================================================================
-- Compass stances: Naomi Soto — City of Palm Springs (CA) City Council, District 4 (Mayor)
-- ext_id: -4011004   politician_id: d76aaa6c-b6a1-42f4-8b12-67cd523c4cf7
-- Nonpartisan municipal office (party not stored/displayed). Healthcare executive; elected
-- Nov 2024; council-appointed 28th Mayor (rotational 1-yr term, sworn Dec 2025). The Mayor
-- title is a rotational role on her D4 seat — stances below are HER OWN documented positions,
-- NOT the institutional mayoralty.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration. Every seeded topic is backed by a
-- documented, attributable position (here: her on-record campaign platform, which the plan
-- accepts as evidence) with a real cited source URL. AUDIT-ONLY / unregistered. Non-court-scoped
-- office — no court-scoped-* topics. The active directly-elected-mayor petition is background only
-- and is NOT forced into any topic.
--
-- SEEDED (1 topic):
--   economic-development = 2  (named economic development her No. 1 priority; focus on re-engaging
--                              plaza/small-business owners and revitalizing commercial centers with
--                              chronic vacancies — a local small-business-support approach)
--
-- DELIBERATELY BLANK (platform mentions but no clean chair-mappable individual position):
--   housing (raised rising-rents/cost-of-living concerns but no specific chair-mappable policy),
--   and all other local + non-local topics.
-- =====================================================================================

BEGIN;

-- ----- Naomi Soto / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d76aaa6c-b6a1-42f4-8b12-67cd523c4cf7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d76aaa6c-b6a1-42f4-8b12-67cd523c4cf7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Soto identified economic development as her No. 1 campaign priority. Her documented approach is locally focused on supporting and revitalizing existing small businesses and commercial centers rather than competing for large employers with subsidies: she noted the city had accomplished much revitalizing downtown and wanted those best practices applied to other commercial centers, pointing to plazas and business centers with chronic vacancies, encampments, and failing conditions, and advocated accelerating steps to "re-engage plaza owners, small business owners and employees." That focus on small-business/local-commercial revitalization aligns with a small-business-support-and-local-entrepreneurship economic-development approach.$$,
        ARRAY['https://ukenreport.com/naomi-soto-has-designs-on-palm-springs-district-4-seat/',
              'https://naomisoto.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- =====================================================================================
-- Compass stances: Oscar Ortiz — City of Indio (CA) City Council, District 4
-- ext_id: -4012004   politician_id: 4bbba476-c442-42d5-8b5d-07e8fac1481c
-- Nonpartisan municipal office (party not stored/displayed). Elected 2018 (youngest ever elected to
-- the Indio council, unseating a four-term incumbent); represents District 4, the city's
-- highest-poverty district; Indio native, Stanford graduate.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record platform
--     statement) with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Ortiz position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and inform.politician_context.
--   * City Council is a legislative (non-court-scoped) office — no court-scoped topics are referenced.
--   * Reasoning is dollar-quoted; sources are a text[] literal (injection-safe).
--
-- SEEDED (2 topics):
--   housing              = 3  (stated priority on the need for affordable housing options for
--                              residents of his high-poverty district — affordable-access focus,
--                              mechanism not further specified)
--   economic-development = 2  (emphasis on supporting locally owned businesses and bringing in
--                              better-paying jobs via training programs — a local/small-business and
--                              job-quality focus, distinct from large-employer recruitment)
--
-- DELIBERATELY BLANK (stated as a general value but no attributable directional position, or no record):
--   local-environment / city-sanitation (a general "clean environment for our community" value that
--   does not address the development-vs-preservation or sanitation-service tradeoffs those topics ask
--   about), homelessness-response, public-safety-approach, growth-and-development, residential-zoning,
--   rent-regulation, transportation-priorities, campaign-finance, redistricting, local-immigration,
--   and all non-local state/federal topics — no clearly attributable governing position this pass.
-- =====================================================================================

BEGIN;

-- ----- Oscar Ortiz / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4bbba476-c442-42d5-8b5d-07e8fac1481c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4bbba476-c442-42d5-8b5d-07e8fac1481c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ortiz's documented housing priority is affordable access. Representing District 4 — the highest-poverty district in Indio — he has consistently expressed the need for affordable housing options for residents as a central concern. Supporting affordable-housing access and assistance for residents who are priced out, without a documented rent-cap/inclusionary-mandate or a deregulate-for-market-builders mechanism, aligns with offering targeted help such as subsidies and assistance for affordable housing.$$,
        ARRAY['https://ukenreport.com/ortiz-upsets-incumbent-indio/',
              'https://www.indio.org/Home/Components/StaffDirectory/StaffDirectory/42/181']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Oscar Ortiz / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4bbba476-c442-42d5-8b5d-07e8fac1481c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4bbba476-c442-42d5-8b5d-07e8fac1481c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ortiz's documented economic focus is local businesses and job quality rather than large-employer subsidy competition. He emphasizes supporting locally owned businesses and, as his solution to the district's poverty, bringing in better-paying jobs and providing more workforce training programs. Centering local/small business and higher-quality jobs and training, rather than competing with large tax incentives for major outside employers, aligns with prioritizing small-business support and local entrepreneur/workforce programs.$$,
        ARRAY['https://ukenreport.com/ortiz-upsets-incumbent-indio/',
              'https://www.indio.org/Home/Components/StaffDirectory/StaffDirectory/42/181']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

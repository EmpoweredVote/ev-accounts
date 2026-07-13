-- =====================================================================================
-- Compass stances: Waymond Fermon — City of Indio (CA) City Council, District 2 (Mayor Pro Tem)
-- ext_id: -4012002   politician_id: 86fe2b91-d1fa-4c65-8d75-90f181624fe4
-- Nonpartisan municipal office (party not stored/displayed). Second-term councilmember; born and
-- raised in Indio; correctional officer by profession; leads a youth crime-prevention/diversion program.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record platform
--     statement or cited council action) with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Fermon position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and inform.politician_context.
--   * City Council is a legislative (non-court-scoped) office — no court-scoped topics are referenced.
--   * Reasoning is dollar-quoted; sources are a text[] literal (injection-safe).
--
-- SEEDED (3 topics):
--   housing                = 3  (emphasizes affordable and attainable senior/veteran housing and touts
--                                Indio's 2022 state Housing Element certification — targeted-affordability
--                                support rather than rent-cap mandates or deregulation)
--   economic-development   = 4  (champions active redevelopment: the Indio Grand Market Place revival
--                                ending a 30-year vacancy, College of the Desert expansion, a "live,
--                                work, and play" recruitment vision)
--   public-safety-approach = 3  (backed the new city Public Safety Campus AND leads a youth
--                                diversion/prevention program keeping at-risk juveniles out of the
--                                justice system — maintain public safety while adding prevention)
--
-- DELIBERATELY BLANK (named as a challenge but no attributable directional position, or no record):
--   homelessness-response (listed only as an ongoing "challenge," no strategy stated),
--   growth-and-development, local-environment, transportation-priorities, residential-zoning,
--   rent-regulation, city-sanitation, campaign-finance, redistricting, local-immigration, childcare,
--   civil-rights, data-centers, and all non-local state/federal topics — no governing record.
-- =====================================================================================

BEGIN;

-- ----- Waymond Fermon / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fermon's documented housing emphasis is targeted affordability. He identifies "affordable and attainable senior and veteran housing" as an ongoing priority requiring continued attention, and points to Indio earning its state Housing Element certification from the California Department of Housing and Community Development in 2022 as an accomplishment on his watch. That focus on facilitating affordable/attainable housing for specific populations and meeting state affordable-housing planning requirements — rather than city-built public housing, broad rent caps, or pure deregulation — aligns with targeted help such as subsidies and assistance for affordable projects.$$,
        ARRAY['https://ukenreport.com/fermon-seeks-second-term-on-indio-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Waymond Fermon / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Fermon actively promotes drawing development and employers into Indio. He highlights the Indio Grand Market Place redevelopment — reviving a site vacant for more than 30 years, with the Haagen Company commencing construction in 2022 — and the College of the Desert campus expansion (doubling to 80,000 square feet with thousands of added enrollments), framed around making Indio a place "where people want to live, work, and play." Championing major recruited development and redevelopment projects as an economic strategy aligns with actively competing for employers and investment.$$,
        ARRAY['https://ukenreport.com/fermon-seeks-second-term-on-indio-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Waymond Fermon / public-safety-approach (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86fe2b91-d1fa-4c65-8d75-90f181624fe4',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fermon's public-safety record pairs sustained investment with prevention. As a corrections officer who serves on the Coachella Valley Association of Governments Public Safety Committee, he cites the new city Public Safety Campus as a major project of his term and calls public safety a challenge that must be continually addressed; at the same time his signature initiative is a youth outreach/diversion program giving at-risk juveniles first-hand accounts from inmates to keep them out of the incarceration system. Maintaining public-safety capacity while adding prevention and diversion, rather than either cutting police budgets or making enforcement expansion the sole priority, aligns with keeping public-safety funding while adding non-enforcement crisis/prevention response.$$,
        ARRAY['https://ukenreport.com/fermon-seeks-second-term-on-indio-city-council/',
              'https://www.indio.org/Home/Components/StaffDirectory/StaffDirectory/40/181']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

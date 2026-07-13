-- =====================================================================================
-- Compass stances: Elaine Holmes — City of Indio (CA) City Council, District 3 (Mayor)
-- ext_id: -4012003   politician_id: dea49bf0-12b4-40b7-a48c-a3eda018ef04
-- Nonpartisan municipal office (party not stored/displayed). Long-serving councilmember (first
-- elected 2010; multiple rotational mayoral terms, most recent sworn 2025-12-03); Indio small-business
-- owner (downtown trophy/gift shop).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record platform
--     statement or cited council action) with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Holmes position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and inform.politician_context.
--   * City Council is a legislative (non-court-scoped) office — no court-scoped topics are referenced.
--   * Reasoning is dollar-quoted; sources are a text[] literal (injection-safe).
--
-- SEEDED (5 topics):
--   housing                = 2  (council approved plans for ~1,000 new AFFORDABLE apartments; her
--                                housing emphasis is expanding affordable supply, distinct from a
--                                build-volume-via-developers approach)
--   economic-development   = 4  (champions expansion of the city's industrial and large-business
--                                sectors and job creation, alongside being a local small-business
--                                advocate — active employer/investment attraction)
--   growth-and-development = 4  (stated vision to facilitate the growth and development of the city
--                                and its business community)
--   homelessness-response  = 3  (names homelessness a top priority and backs the city's Quality of
--                                Life team — outreach/services paired with public-space enforcement)
--   public-safety-approach = 3  (public safety a stated focus; supports the Quality of Life team —
--                                maintain public safety with a targeted outreach/response component)
--
-- DELIBERATELY BLANK (no clearly attributable individual documented position found this pass):
--   local-environment, climate-change, transportation-priorities, residential-zoning, rent-regulation,
--   city-sanitation, campaign-finance, redistricting, local-immigration, childcare, civil-rights,
--   data-centers, jail-capacity, and all non-local state/federal topics — no governing record.
-- =====================================================================================

BEGIN;

-- ----- Elaine Holmes / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Holmes's documented housing record centers on expanding affordable supply. She and the council approved plans for roughly 1,000 new affordable apartments in Indio, part of a broader affordable-housing push that also includes approved affordable developments in the city's pipeline. Actively approving and advancing dedicated affordable-housing production — rather than leaving supply to the market or focusing only on deregulating for market-rate builders — aligns with using public support and affordable-unit development to expand the housing supply.$$,
        ARRAY['https://ukenreport.com/elaine-holmes-seeks-fourth-term-on-city-council/',
              'https://kesq.com/news/2024/02/15/indio-residents-encourage-the-city-to-approve-a-200-unit-affordable-housing-development/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elaine Holmes / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Holmes runs on active economic expansion. Her stated priorities include education, job creation, and the expansion of the city's industrial and large-business sectors, and as a small-business owner she is also a vocal champion of Indio's local business community. Prioritizing recruitment and expansion of larger employers and industry alongside small-business growth aligns with actively competing for major employers and investment.$$,
        ARRAY['https://ukenreport.com/elaine-holmes-seeks-fourth-term-on-city-council/',
              'https://kesq.com/news/2022/10/06/meet-the-candidates-indio-city-council-election/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elaine Holmes / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Holmes's stated vision is to facilitate the growth and development of Indio and its business community, tied to expanding the industrial and large-business sectors and creating jobs. Actively facilitating and recruiting growth to build the city's economy, rather than capping growth or restricting it to existing infrastructure capacity, aligns with actively recruiting development and streamlining approvals to grow the city.$$,
        ARRAY['https://ukenreport.com/elaine-holmes-seeks-fourth-term-on-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elaine Holmes / homelessness-response (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Holmes names homelessness among her top priorities and backs the city's Quality of Life team, Indio's dedicated homeless-outreach unit that pairs outreach and services with public-space quality-of-life enforcement. Supporting an outreach-and-services model coupled with reasonable public-space enforcement, rather than a pure housing-first no-enforcement approach or an enforcement-first camping-ban approach, aligns with investing in outreach, shelter, and services while enforcing reasonable public-space rules.$$,
        ARRAY['https://ukenreport.com/elaine-holmes-seeks-fourth-term-on-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Elaine Holmes / public-safety-approach (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dea49bf0-12b4-40b7-a48c-a3eda018ef04',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Holmes lists public safety as a core focus and specifically supports the city's Quality of Life team, which combines police presence with outreach and quality-of-life response. Maintaining public-safety capacity while backing a targeted outreach/response unit, rather than either redirecting police funding or making police-budget expansion the single top priority, aligns with keeping public-safety funding while adding targeted crisis/quality-of-life response.$$,
        ARRAY['https://ukenreport.com/elaine-holmes-seeks-fourth-term-on-city-council/',
              'https://kesq.com/news/2022/10/06/meet-the-candidates-indio-city-council-election/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

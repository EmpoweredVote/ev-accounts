-- =====================================================================================
-- Compass stances: Grace Elena Garner — City of Palm Springs (CA) City Council, District 1
-- ext_id: -4011001   politician_id: 13979c8e-df26-4d07-918e-e064fce6dc53
-- Nonpartisan municipal office (party not stored/displayed). First Latina elected to the
-- Palm Springs council (2019); served as Mayor 2023; council's most senior member.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded council
--     vote/motion or on-record statement) with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Garner position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--   * City Council is a NON-court-scoped office — no court-scoped-* topics are referenced.
--
-- SEEDED (2 topics):
--   homelessness-response = 2  (voted AGAINST the encampment-regulation ordinance; championed a
--                               Navigation Center + cooling centers + overnight shelters/services)
--   housing               = 2  (200+ affordable units built; 1% TOT set-aside publicly funding
--                               affordable housing; affordable-unit development actively pursued)
--
-- DELIBERATELY BLANK (no clearly attributable individual documented position found this pass):
--   local-immigration, economic-development, growth-and-development, residential-zoning,
--   rent-regulation, local-environment, climate-change, public-safety-approach, city-sanitation,
--   transportation-priorities, campaign-finance, childcare, civil-rights, data-centers,
--   homelessness, jail-capacity, religious-freedom, trans-athletes, and all non-local
--   federal/state topics (a city councilmember has no governing record on those).
-- =====================================================================================

BEGIN;

-- ----- Grace Elena Garner / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13979c8e-df26-4d07-918e-e064fce6dc53',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13979c8e-df26-4d07-918e-e064fce6dc53',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Garner's documented homelessness record is services-and-shelter led rather than enforcement led. When the City Council voted to regulate homeless encampments, Garner voted against the ordinance, saying, "I don't like this at all. I think it sends the wrong message to people who are in dire need of our help and our support." Her affirmative record is building service capacity: she pushed a Navigation Center and supported cooling centers and overnight shelters in Palm Springs, and advocated stronger staffing and training at city facilities serving the unhoused. That combination — opposing an enforcement-first encampment ordinance while expanding shelter and services as the primary strategy — fits expanding shelter capacity and services as the primary approach, with enforcement not used as the lead tool.$$,
        ARRAY['https://thepalmspringspost.com/city-council-approves-regulating-homeless-encampments-despite-concerns/',
              'https://wewinwithgrace.com/meet-grace/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Grace Elena Garner / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13979c8e-df26-4d07-918e-e064fce6dc53',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13979c8e-df26-4d07-918e-e064fce6dc53',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Garner's housing record is actively interventionist: she is credited with leadership that produced more than 200 affordable-housing units built with hundreds more in the pipeline, funded through the general fund and a set-aside of one percent of all transient occupancy tax (TOT) revenue dedicated to affordable housing, while actively recruiting developers to build affordable units in Palm Springs. Publicly funding new affordable housing and pursuing dedicated affordable-unit development — rather than leaving supply to the market or relying only on light-touch permit incentives — aligns with using public funding and affordable-unit requirements to expand the housing supply.$$,
        ARRAY['https://wewinwithgrace.com/meet-grace/',
              'https://www.palmspringslife.com/40-under-40/2025-honorees/grace-garner/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

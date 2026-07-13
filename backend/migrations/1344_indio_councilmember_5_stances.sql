-- =====================================================================================
-- Compass stances: Benjamin Guitron IV — City of Indio (CA) City Council, District 5
-- ext_id: -4012005   politician_id: f13b83e3-e086-479a-b6e4-9ad63f89f308
-- Nonpartisan municipal office (party not stored/displayed). Elected 2024 (newest councilmember);
-- lifelong Indio resident; 40-year Indio Police Department career, retiring as Police Administrative
-- Officer / public information officer in 2024.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (2024 campaign platform)
--     with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Guitron position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and inform.politician_context.
--   * City Council is a legislative (non-court-scoped) office — no court-scoped topics are referenced.
--   * Reasoning is dollar-quoted; sources are a text[] literal (injection-safe).
--
-- SEEDED (3 topics):
--   public-safety-approach = 4  (career Indio PD officer; made residents' safety and quality of life
--                                his #1 priority and centered supporting public-safety initiatives to
--                                keep neighborhoods secure)
--   economic-development   = 3  ("strategic development that balances expansion with the needs of
--                                residents" — attract business/industry but with a balanced,
--                                community-benefit framing rather than maximal recruitment)
--   growth-and-development = 3  (frames growth as "responsible/strategic development that balances
--                                expansion with the needs of residents" — planned, balanced growth)
--
-- DELIBERATELY BLANK (no clearly attributable individual documented position found this pass):
--   housing, homelessness-response, local-environment, transportation-priorities, residential-zoning,
--   rent-regulation, city-sanitation, campaign-finance, redistricting, local-immigration, childcare,
--   civil-rights, and all non-local state/federal topics — no clearly attributable governing position.
-- =====================================================================================

BEGIN;

-- ----- Benjamin Guitron IV / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Guitron is a 40-year Indio Police Department veteran who retired as the department's Police Administrative Officer. His 2024 campaign made residents' well-being, safety, and quality of life his number-one priority, centered on supporting public-safety initiatives to keep neighborhoods secure while building trust between police and residents. Prioritizing strong support for police and public-safety capacity to keep neighborhoods secure aligns with increasing police staffing and resources to improve response and deter crime.$$,
        ARRAY['https://benguitron.com/',
              'https://ukenreport.com/benjamin-guitron-seeks-to-unseat-ramos-amith/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Guitron IV / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Guitron sees Indio's growth as an opportunity to attract new businesses and industries, but frames it around strategic development that balances expansion with the needs of residents and creates jobs. Supporting business attraction conditioned on community benefit and resident impact — rather than maximal, no-strings recruitment of any large employer — aligns with targeted, community-benefit-conditioned economic development.$$,
        ARRAY['https://benguitron.com/',
              'https://ukenreport.com/benjamin-guitron-seeks-to-unseat-ramos-amith/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin Guitron IV / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f13b83e3-e086-479a-b6e4-9ad63f89f308',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Guitron frames Indio's expansion as responsible, strategic development that balances growth with the needs of residents. Favoring planned, balanced growth that keeps pace with resident needs — rather than imposing growth limits or, at the other end, removing barriers to maximize development pace — aligns with planning proactively and investing to support responsible, balanced expansion.$$,
        ARRAY['https://benguitron.com/',
              'https://ukenreport.com/benjamin-guitron-seeks-to-unseat-ramos-amith/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

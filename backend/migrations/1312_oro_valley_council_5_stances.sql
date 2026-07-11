-- =====================================================================================
-- Compass stances: Mary Murphy — Oro Valley (AZ) Town Council Member (at-large)
-- politician_id: aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c
-- Nonpartisan; community advocate; Town Council member seated July 2024.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record
--     campaign-questionnaire statement of priorities) taken during her candidacy/tenure,
--     with a real cited source URL confirmed via web research.
--   * Topics with no clear documented Murphy position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- SEEDED (4 topics):
--   growth-and-development  = 2  (careful management of limited growth; infrastructure must be
--                                 concurrent with population growth; strict design guidelines)
--   economic-development    = 2  (help the business community prosper + recruit high-paying
--                                 jobs while preserving OV's unique character — support-led)
--   taxes                    = 3  ("Oro Valley does not need and should not have a property
--                                 tax"; controlled spending; expand the sales-tax base — hold
--                                 the current no-property-tax structure)
--   public-safety-approach  = 4  (commits to funding the police department to keep OV among
--                                 the safest communities in Arizona)
--
-- DELIBERATELY BLANK (no clean attributable compass position found):
--   Local: campaign-finance, childcare, city-sanitation, civil-rights, climate-change,
--          data-centers, homelessness, homelessness-response, housing, jail-capacity,
--          local-environment, local-immigration, rent-regulation, residential-zoning,
--          trans-athletes, transportation-priorities, religious-freedom.
--     (Transparency / "Council on the Corner" and infrastructure-concurrency and
--      water-conservation remarks have no clean compass-chair match; not seeded.)
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, deportation, fossil-fuels, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers, social-security,
--          tariffs, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Murphy / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Murphy says growth must be "consistent with the character of the town" and that infrastructure improvements must accompany new development "concurrent with population growth to ensure we maintain and improve our quality of life," and she opposes lowering design standards, insisting the town keep "strict design guidelines." That maps to allowing growth only where infrastructure and standards can support it — a manage-to-capacity posture rather than actively recruiting or deregulating development.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/mary-murphy/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Murphy / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Murphy's economic-development approach is to encourage town staff to "help the business community prosper" and to recruit high-paying jobs and expand the sales-tax base, all "while preserving Oro Valley's unique beautiful character." Her documented emphasis is on supporting the business community and broadening the revenue base rather than offering major corporate tax abatements or maximal incentives.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/mary-murphy/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Murphy / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Murphy states flatly that "Oro Valley does not need and should not have a property tax," and pairs that with controlled spending, recruiting high-paying jobs, expanding the sales-tax base, and using state shared revenues wisely. Oro Valley currently levies no property tax, so her position is to hold the existing tax structure roughly as-is (no new property tax) while managing spending — not to raise taxes, nor to cut existing taxes and scale back services.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/mary-murphy/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Murphy / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Murphy praises the Oro Valley Police Department's "award-winning Chief with an incredibly professional and dedicated staff" and commits to ensuring the department "receives necessary funding" to keep Oro Valley "one of the safest communities in Arizona." Her documented position is to sustain and fund police staffing and resources rather than redirect the police budget or shift its scope.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/mary-murphy/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

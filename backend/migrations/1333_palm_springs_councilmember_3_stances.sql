-- =====================================================================================
-- Compass stances: Ron deHarte — City of Palm Springs (CA) City Council, District 3
-- ext_id: -4011003   politician_id: 24ba9d44-a972-4125-b370-380b457a226c
-- Nonpartisan municipal office (party not stored/displayed). Elected 2022; served as the
-- 27th Mayor of Palm Springs (2024-2025). Longtime Palm Springs Pride organizer.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration. Every seeded topic is backed by a
-- documented, attributable position with a real cited source URL. Topics with no clearly
-- attributable individual position emit NO row. AUDIT-ONLY / unregistered. Non-court-scoped office —
-- no court-scoped-* topics.
--
-- SEEDED (1 topic):
--   homelessness-response = 3  (voted FOR the July 2024 encampment-regulation ordinance while
--                               framing homelessness within a "safe streets + accessible housing +
--                               sustainability" approach — balanced invest-and-enforce)
--
-- DELIBERATELY BLANK (documented platform themes but no clean single-chair map):
--   economic-development / growth-and-development (his "sound economic development, robust tourism
--     economy, smart growth" platform is real but is thematic, not a chair-mappable action),
--   "radical transparency in city spending" (no matching non-court-scoped compass topic — the only
--     transparency topic is court-scoped and out of scope), plus all other local + non-local topics.
-- =====================================================================================

BEGIN;

-- ----- Ron deHarte / homelessness-response (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24ba9d44-a972-4125-b370-380b457a226c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24ba9d44-a972-4125-b370-380b457a226c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$deHarte, then Mayor Pro Tem, was in the council majority that approved, 3-1, the July 2024 ordinance regulating homeless encampments (making it a violation to set up an encampment or sleep on public property) — an enforcement of public-space rules. He frames homelessness within a broader balanced approach rather than an enforcement-only one, stating that the city "CAN have safe streets, sound economic development, a robust tourism economy, and accessible housing while being a leader in sustainability," and casting a "thriving tourism economy" as "the engine that allows us to fund social progress ... and address challenges like homelessness with actual results." Voting for reasonable public-space enforcement while backing continued housing and service investment fits a balanced approach that invests in outreach, shelter, and services while enforcing reasonable public-space rules.$$,
        ARRAY['https://thepalmspringspost.com/city-council-approves-regulating-homeless-encampments-despite-concerns/',
              'https://www.rondeharte.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Migration 775: Mary Ann Pacheco (Whittier Council, District 1) Stances
-- Phase 137 follow-up (v15.0 reconciliation). external_id -700405; politician_id resolved by subquery.
BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT id, 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0 FROM essentials.politicians WHERE external_id = -700405
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT id, 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Council Member Pacheco prioritizes the safety and security of Whittier residents, advocating for community policing and comprehensive safety initiatives — a community-oriented, balanced public-safety approach.$$,
ARRAY['https://www.maryannforwhittier.com/issues']::text[]::text[]
FROM essentials.politicians WHERE external_id = -700405
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT id, '669cac97-66a6-4087-b036-936fbe62efb3', 2.0 FROM essentials.politicians WHERE external_id = -700405
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT id, '669cac97-66a6-4087-b036-936fbe62efb3',
$$Pacheco champions affordable-housing solutions: developing affordable units, collaborating with developers to incentivize affordable construction, and creating first-time-homebuyer programs for current low- to mid-income residents — a strongly pro-affordable-housing position.$$,
ARRAY['https://www.maryannforwhittier.com/issues']::text[]::text[]
FROM essentials.politicians WHERE external_id = -700405
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;

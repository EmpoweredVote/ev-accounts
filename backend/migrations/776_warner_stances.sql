-- Migration 776: Cathy Warner (Whittier Council, District 3) Stances
-- Phase 137 follow-up (v15.0 reconciliation). external_id -700406; politician_id resolved by subquery.
BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT id, 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0 FROM essentials.politicians WHERE external_id = -700406
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT id, 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Council Member Warner names public safety as her signature, continued priority for Whittier District 3, an enforcement-supportive posture consistent with the council's safety-forward majority.$$,
ARRAY['https://ground.news/article/whittier-election-2024-q-and-a-if-re-elected-cathy-warner-wants-to-continue-prioritizing-public-safety']::text[]::text[]
FROM essentials.politicians WHERE external_id = -700406
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT id, 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0 FROM essentials.politicians WHERE external_id = -700406
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT id, 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Warner serves on the City Council's Goldline Light Rail Ad Hoc Committee, working to extend Metro light-rail service to Whittier — a pro-public-transit transportation priority.$$,
ARRAY['https://www.cityofwhittier.org/government/city-council/city-council-profiles/mayor-pro-tem-cathy-warner']::text[]::text[]
FROM essentials.politicians WHERE external_id = -700406
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;

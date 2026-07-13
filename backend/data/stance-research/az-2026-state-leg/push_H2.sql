-- ============================================================================
-- AZ state-legislature stance wave 2026-07-13 — batch H2 (3 rows)
-- AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
-- inform.politician_context. politician_ids resolved via office/district join
-- (see _ROSTER.csv); topic_ids resolved live via inform.compass_topics.topic_key.
-- Source CSV: 2026-07-13-az-batch-H2.csv  Review log: _REVIEW_FLAGS.md
-- ============================================================================

BEGIN;

-- ----- Matt Gress (State House District 4) / abortion = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5293ff0f-0365-4943-89a5-f4017566c8dd', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5293ff0f-0365-4943-89a5-f4017566c8dd', ct.id, $ctx$Gress made the initial motion forcing the House vote to repeal Arizona's near-total 1864 abortion ban and was one of only three House Republicans (with Wilmeth and Dunn) voting yes on HB2677's 32-28 passage on April 24, 2024, having supported repeal across multiple earlier 2024 attempts (initially as the lone R crossover, costing him a committee post). His vote preserved Arizona's 15-week gestational-limit framework rather than the near-total ban, closest to the first-trimester/exceptions chair. Corroborated by orchestrator 2026-07-13 via the AZ Mirror repeal-vote report.$ctx$,
       ARRAY['https://azmirror.com/2024/04/24/az-house-has-voted-to-repeal-the-1864-abortion-ban-upheld-by-the-supreme-court/', 'https://en.wikipedia.org/wiki/Matt_Gress']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'abortion'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Matt Gress (State House District 4) / housing = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT '5293ff0f-0365-4943-89a5-f4017566c8dd', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5293ff0f-0365-4943-89a5-f4017566c8dd', ct.id, $ctx$Gress sponsored legislation providing financial assistance to mobile home park residents facing displacement due to redevelopment, signed into law by Gov. Hobbs in March 2023 — a targeted subsidy/assistance program rather than broad public housing, rent caps, or market deregulation.$ctx$,
       ARRAY['https://en.wikipedia.org/wiki/Matt_Gress']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'housing'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sarah Liguori (State House District 5) / climate-change = 3 -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'eb8215ef-5e68-431a-a5cf-c226e8c0abf1', ct.id, 3.0
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'eb8215ef-5e68-431a-a5cf-c226e8c0abf1', ct.id, $ctx$Liguori publicly opposed EPA cuts to the federal Solar for All program in October 2025, joining solar advocates to argue the cuts would set Arizona's clean-energy progress backward, consistent with support for continued clean-energy investment rather than a full renewables-by-2030 mandate or market-only approach.$ctx$,
       ARRAY['https://azmirror.com/2025/10/21/solar-advocates-warn-epa-cuts-to-solar-energy-send-arizona-backwards-amid-energy-demands/']::text[]
FROM inform.compass_topics ct WHERE ct.topic_key = 'climate-change'
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

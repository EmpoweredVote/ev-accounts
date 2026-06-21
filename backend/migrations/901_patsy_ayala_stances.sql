-- 901_patsy_ayala_stances.sql
-- Phase 143 / Plan 04 — Patsy Ayala (Councilmember/Mayor Pro Tem, external_id 665689) evidence-only stances.
-- AUDIT-ONLY: apply via raw SQL; does NOT register in schema_migrations (ledger MAX stays 895).
-- Chairs model; evidence-only; 100% citation. Sworn Dec 2024 — thinnest record; only 1 defensible stance.
-- Honest blanks for all other topics (no citable position). SB54 NOT attributed (not seated 2018).

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665689)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id, v.value
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid, 4)   -- transportation-priorities
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665689)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id, v.reasoning, v.sources
FROM pol, (VALUES
  ('ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid,
   $$Ayala's campaign repeatedly frames transportation investment as relieving traffic congestion via infrastructure ('Investing in infrastructure that will relieve traffic congestion'), a road-capacity / serve-drivers orientation with no mention of transit, bike, or pedestrian priority, matching chair 4.$$,
   ARRAY['https://patsyayala.com/','https://santaclaritamagazine.com/2024/09/meet-the-candidates-2024/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

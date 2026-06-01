-- ============================================================================
-- Migration 248: Clean up 6 dead topic IDs from inform.topic_rewrites
-- ============================================================================
-- Context: Six topics were rewritten (new scale/ID created via topic_rewrites):
--   ai-regulation, deportation, healthcare, housing, immigration, taxes
-- Old topic rows are is_live=false but still have orphaned child rows.
-- All 252 orphaned politician_answers have counterparts on new IDs, EXCEPT
-- Mazariegos's taxes stance (value=2) which was only on the old ID.
-- This migration:
--   1. Ports Mazariegos taxes stance + context to the new taxes ID
--   2. Deletes all child rows on old IDs (answers, context, stances, categories,
--      user responses, change history)
--   3. Deletes the 6 dead compass_topics rows and topic_rewrites entries
-- ============================================================================

BEGIN;

-- OLD IDs (dead):
--   ai-regulation : f2a62698-a64c-4f7f-8fba-5971d35c51cf
--   deportation   : 83eeb217-0289-47df-bde9-c53866b5b3e9
--   healthcare    : be60844f-5e21-4fec-ae99-e00e95c1e19b
--   housing       : a9f53bc4-db4e-48e1-8663-c87f2c18b63d
--   immigration   : c6957429-bc9e-48e7-b36f-a102b968a972
--   taxes         : 45ca4740-a861-4c8c-b3b5-0a49cf953501  ← new: f7e5678d-dadd-4556-a2fc-446e24642ceb

-- ---------------------------------------------------------------------------
-- Step 1: Port Mazariegos taxes stance to new taxes topic ID
-- ---------------------------------------------------------------------------
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '92876cb7-9905-4be7-b349-2a4a4ff39846',  -- Estuardo Mazariegos
  'f7e5678d-dadd-4556-a2fc-446e24642ceb',  -- new taxes topic
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '92876cb7-9905-4be7-b349-2a4a4ff39846',
  'f7e5678d-dadd-4556-a2fc-446e24642ceb',
  $$Messaging explicitly targets "wage and rent exploitation by the billionaire class that extracts wealth from CD 9"; ACCE runs a "Tax the Rich" campaign he leads as co-director; positions align with modestly increasing taxes on high earners/corporations while protecting working families; no flat-tax or across-the-board cut signals.$$,
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/', 'https://acceaction.org/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;

-- ---------------------------------------------------------------------------
-- Step 2: Delete all child rows on old topic IDs
-- ---------------------------------------------------------------------------

DELETE FROM inform.compass_change_history
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.compass_responses
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.politician_context
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.politician_answers
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.compass_stances
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.compass_topic_categories
WHERE topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

-- ---------------------------------------------------------------------------
-- Step 3: Delete the dead topic rows and clear topic_rewrites
-- ---------------------------------------------------------------------------

DELETE FROM inform.topic_rewrites
WHERE old_topic_id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

DELETE FROM inform.compass_topics
WHERE id IN (
  'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
  '83eeb217-0289-47df-bde9-c53866b5b3e9',
  'be60844f-5e21-4fec-ae99-e00e95c1e19b',
  'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
  'c6957429-bc9e-48e7-b36f-a102b968a972',
  '45ca4740-a861-4c8c-b3b5-0a49cf953501'
);

COMMIT;

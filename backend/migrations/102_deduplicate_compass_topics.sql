-- Migration 102: Deduplicate compass topics — copy-only, non-destructive
--
-- Each pair has one live (is_live=true) and one archived (is_live=false) topic.
-- The archived topics are the OLD versions from a Plan D rewrite process completed
-- 2026-04-12/14. The inform.topic_rewrites table holds published audit records
-- referencing both old and new topic IDs with ON DELETE RESTRICT — so the archived
-- topics cannot and should not be deleted.
--
-- Strategy: INSERT non-conflict answers and contexts from archived → live topic only.
-- ON CONFLICT DO NOTHING preserves live-topic data where a politician has both.
-- Archived topics are left completely untouched — all their data remains in place.
-- They are already invisible to users (is_live=false). Fully recoverable: revert
-- by deleting any rows on live topics where politician_id matches a row on the
-- archived topic (the archived copy is still there as the source of truth).
--
-- Pairs:
--   Affordable Housing (live 669cac97) ← Affordable Housing and Homelessness (archived a9f53bc4)
--   AI Oversight (live 666bf03d)       ← AI Regulation (archived f2a62698)
--   Deportation Priorities (live 44905f3b) ← Deportation of Immigrants (archived 83eeb217) [all conflicts — no rows to copy]
--   Healthcare Access (live e8dad4a8)  ← Healthcare Access and Affordability (archived be60844f)
--   Immigration and Treatment (live 4e2c69ce) ← Immigration Policy (archived c6957429)
--   Taxation and Public Spending (live f7e5678d) ← Taxation and Gov Spending (archived 45ca4740)

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Affordable Housing and Homelessness → Affordable Housing
--    Non-conflict politicians (only on archived): Ann Anderson, Bill Cox,
--    Geré Feltus, Jay Obernolte, Jim Banks, John B. Muns, Laura Rummel,
--    Michael Schaeffer, Pete Aguilar, Shun Thomas, Steve Lavine, Tony Cardenas
-- ---------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, value
FROM inform.politician_answers
WHERE topic_id = 'a9f53bc4-db4e-48e1-8663-c87f2c18b63d'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, reasoning, sources
FROM inform.politician_context
WHERE topic_id = 'a9f53bc4-db4e-48e1-8663-c87f2c18b63d'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Artificial Intelligence Regulation → Artificial Intelligence Oversight
--    Non-conflict politicians: Karen Ruth Bass, Linda T. Sanchez,
--    Pete Aguilar, Sydney Kamlager-Dove
-- ---------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, value
FROM inform.politician_answers
WHERE topic_id = 'f2a62698-a64c-4f7f-8fba-5971d35c51cf'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid, reasoning, sources
FROM inform.politician_context
WHERE topic_id = 'f2a62698-a64c-4f7f-8fba-5971d35c51cf'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Deportation of Immigrants → Deportation Priorities
--    All 52 archived politicians already exist on the live topic.
--    No rows to copy — nothing to do here.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 4. Healthcare Access and Affordability → Healthcare Access
--    Non-conflict politicians: Curren D. Price Jr., Kerry Thomson
-- ---------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, value
FROM inform.politician_answers
WHERE topic_id = 'be60844f-5e21-4fec-ae99-e00e95c1e19b'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, reasoning, sources
FROM inform.politician_context
WHERE topic_id = 'be60844f-5e21-4fec-ae99-e00e95c1e19b'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5. Immigration Policy → Immigration and Treatment of Immigrants
--    Non-conflict politicians: David G Henry, Matt Pierce, Nathan Hochman,
--    Robert Luna, Trent Deckard
-- ---------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid, value
FROM inform.politician_answers
WHERE topic_id = 'c6957429-bc9e-48e7-b36f-a102b968a972'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid, reasoning, sources
FROM inform.politician_context
WHERE topic_id = 'c6957429-bc9e-48e7-b36f-a102b968a972'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 6. Taxation and Government Spending → Taxation and Public Spending
--    Non-conflict politicians: Angelia Pelham, Burt Thakur, Jeff Cheney,
--    John Lee (LA), Laura Rummel, Michael Schaeffer
-- ---------------------------------------------------------------------------

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, value
FROM inform.politician_answers
WHERE topic_id = '45ca4740-a861-4c8c-b3b5-0a49cf953501'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT politician_id, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, reasoning, sources
FROM inform.politician_context
WHERE topic_id = '45ca4740-a861-4c8c-b3b5-0a49cf953501'::uuid
ON CONFLICT (politician_id, topic_id) DO NOTHING;

COMMIT;

-- 922_laura_bettencourt_stances.sql — Phase 146 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Evidence-only compass stances for Laura Bettencourt (external_id -700657, Palmdale D3).
-- Chairs model; 100% citation; honest blanks. NO judicial topics (D-13). Apply via raw SQL; ledger stays 919.
-- Bettencourt's documented policy record is thin (largely biographical/procedural); only ONE topic met the
-- evidence-only bar with multi-source corroboration. A small set is the correct honest result.
BEGIN;

-- growth-and-development = 1 (lone 4-1 dissent against the Santa Monica RHNA housing-transfer deal)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 1 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-700657 AND t.topic_key='growth-and-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$As Mayor in Feb 2023 she cast the lone dissenting vote (4-1) against even continuing discussions on a deal where Santa Monica would pay Palmdale to absorb a portion of its state-required (RHNA) housing construction. She said "I am wholeheartedly, 100% against this and I would probably fight this with every breath in my body," citing traffic, congestion, air quality, lack of jobs and "more people on the 14 Freeway," saying it "flies in the face of what we're trying to do to improve our community." A growth-limits position resisting development viewed as outpacing local infrastructure and quality of life — matches chair 1.$$,
ARRAY['https://www.santamonicanext.org/2023/02/palmdale-city-managers-loose-lips-sink-housing-transfer-program-before-it-sees-the-light-of-day/','https://www.avpress.com/news/palmdale-santa-monica-talk-housing/article_41407140-ae75-11ed-92f0-73dad0356de7.html']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=-700657 AND t.topic_key='growth-and-development' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;

-- 925_eric_ohlsen_stances.sql — Phase 146 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Evidence-only compass stances for Eric Ohlsen (external_id 692516, Palmdale D4, Mayor since Jan 2026).
-- Chairs model; 100% citation; honest blanks. NO judicial topics (D-13). Apply via raw SQL; ledger stays 919.
-- Thin documented record (largely biography/slogans). The Jan 2023 homeless-village resolution was a
-- jurisdiction/cooperation position (he urged working WITH LA, broadening the language) — NOT an
-- enforcement-vs-services position, so homelessness is an honest blank. His dumping-cleanup environmental
-- material is remediation, not the development-vs-environment chair — local-environment is an honest blank.
BEGIN;

-- transportation-priorities = 4 ("Fix the 14 Freeway" — road/freeway capacity & condition for commuters; no multimodal element)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, 4 FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692516 AND t.topic_key='transportation-priorities' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, $$Ohlsen's campaign platform's only transportation plank focuses squarely on road/freeway capacity and conditions for commuters/drivers: "Fix the 14 Freeway. We have some of the longest commutes in the country. The condition of our roads reflect this and lead to road-related accidents and fatalities. We need to make all aspects of our commute safer." The substance is improving freeway/road capacity and condition for drivers, with no mention of transit, cycling, or pedestrians — matching chair 4 (focus on road capacity for drivers). Documented campaign-platform position (predates his mayoralty); no conflicting later statement found.$$,
ARRAY['https://www.ballotready.org/people/eric-andrew-ohlsen','https://ericforpalmdale.com/']::text[]
FROM essentials.politicians p, inform.compass_topics t
WHERE p.external_id=692516 AND t.topic_key='transportation-priorities' AND t.is_live=true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;

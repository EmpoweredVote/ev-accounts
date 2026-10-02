-- CA_0298 acceptance checks. Run AS trivia_content through the session pooler:
--   psql "host=aws-0-us-west-1.pooler.supabase.com port=5432 dbname=postgres \
--         user=trivia_content.kxsdzaojfaibhuzmclfq sslmode=require" -f backend/scripts/CA_0298-verify.sql
-- psql prompts for the password. Never put it on the command line or in a file.
-- Expected results are in the comments. Check 4 MUST fail.

\echo '1. Who am I (expect trivia_content)'
SELECT current_user;

\echo '2. Row counts (expect the same as ev_api; 2026-10-01: questions 9486, collection_questions 9483, collection_topics 472, generation_jobs 323, topics 214, claim_fingerprints 72, collections 46, bobit_progress 23, question_flags 8, player_stats 4, election_races 1, player_prefs 0, user_collection_mutes 0)'
SELECT 'bobit_progress' AS t, count(*) FROM trivia.bobit_progress
UNION ALL SELECT 'claim_fingerprints', count(*) FROM trivia.claim_fingerprints
UNION ALL SELECT 'collection_questions', count(*) FROM trivia.collection_questions
UNION ALL SELECT 'collection_topics', count(*) FROM trivia.collection_topics
UNION ALL SELECT 'collections', count(*) FROM trivia.collections
UNION ALL SELECT 'election_races', count(*) FROM trivia.election_races
UNION ALL SELECT 'generation_jobs', count(*) FROM trivia.generation_jobs
UNION ALL SELECT 'player_prefs', count(*) FROM trivia.player_prefs
UNION ALL SELECT 'player_stats', count(*) FROM trivia.player_stats
UNION ALL SELECT 'question_flags', count(*) FROM trivia.question_flags
UNION ALL SELECT 'questions', count(*) FROM trivia.questions
UNION ALL SELECT 'topics', count(*) FROM trivia.topics
UNION ALL SELECT 'user_collection_mutes', count(*) FROM trivia.user_collection_mutes
ORDER BY 1;

\echo '3. Insert then delete a test row (expect INSERT 0 1, then DELETE 1). Rolled back at the end.'
BEGIN;
INSERT INTO trivia.topics (name, slug, description)
  VALUES ('CA_0298 test', 'ca-0298-test', 'acceptance test row');
DELETE FROM trivia.topics WHERE slug = 'ca-0298-test';
ROLLBACK;

\echo '4. Read another schema (expect ERROR: permission denied for schema inform)'
SELECT count(*) FROM inform.compass_categories;

\echo '5. similarity (expect 0)'
SELECT extensions.similarity('a', 'b');

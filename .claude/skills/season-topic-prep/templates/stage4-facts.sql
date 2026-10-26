-- Stage 4 step 1 — the topic facts, read-only, as one result set.
-- Fill {{TOPIC_ID}}, {{TOPIC_KEY}} and {{RUNNER_EMAIL}}, then run:
--   npm run db:ro --prefix backend -- --file <abs path to the filled copy> --json
-- (db:ro prints only the last statement's rows, so this is one UNION ALL query.)
-- Columns: k = what the row is; a–e = its values.
SELECT 'revision' AS k, revision::text AS a, status::text AS b, change_class::text AS c, version::text AS d, id::text AS e
  FROM inform.compass_topic_revisions WHERE topic_id = '{{TOPIC_ID}}'
UNION ALL
SELECT 'pin', s.number::text, s.status::text, sq.topic_revision_id::text, sq.question_number::text, s.id::text
  FROM inform.season_questions sq JOIN inform.seasons s ON s.id = sq.season_id WHERE sq.topic_id = '{{TOPIC_ID}}'
UNION ALL
SELECT 'season_question_count', s.number::text, s.status::text, count(*)::text, '', s.id::text
  FROM inform.season_questions sq JOIN inform.seasons s ON s.id = sq.season_id GROUP BY s.number, s.status, s.id
UNION ALL
-- @zero-scope: counts-blanks — rows and seats are both reported; d counts only seated (value > 0) rows.
SELECT 'politician_answers', s.number::text, '', count(*)::text, sum((pa.value > 0)::int)::text, ''
  FROM inform.politician_answers pa JOIN inform.seasons s ON s.id = pa.season_id WHERE pa.topic_id = '{{TOPIC_ID}}' GROUP BY s.number
UNION ALL
SELECT 'politician_context', s.number::text, '', count(*)::text, '', ''
  FROM inform.politician_context pc JOIN inform.seasons s ON s.id = pc.season_id WHERE pc.topic_id = '{{TOPIC_ID}}' GROUP BY s.number
UNION ALL
SELECT 'research_review', coalesce(s.number::text, '-'), r.status::text, count(*)::text, '', ''
  FROM inform.stance_research_review r LEFT JOIN inform.seasons s ON s.id = r.season_id
 WHERE r.topic_key = '{{TOPIC_KEY}}' GROUP BY s.number, r.status
UNION ALL
-- Voter answers as ROWS (what the template's gate counts), by the revision each was GIVEN on, and value.
SELECT 'voter_answer_rows', coalesce(tr.revision::text, '?'), cr.value::text, count(*)::text, '', coalesce(cr.answered_revision_id::text, '')
  FROM inform.compass_responses cr LEFT JOIN inform.compass_topic_revisions tr ON tr.id = cr.answered_revision_id
 WHERE cr.topic_id = '{{TOPIC_ID}}' AND cr.deleted_at IS NULL
 GROUP BY tr.revision, cr.value, cr.answered_revision_id
UNION ALL
SELECT 'actor', u.email::text, '', '', '', u.id::text FROM auth.users u WHERE u.email = '{{RUNNER_EMAIL}}'
ORDER BY 1, 2, 3;

-- Read-back for the CA_0012 dry run. Runs INSIDE the rehearsal transaction, so it
-- shows the end state just before it is thrown away.
--
--   node scripts/dry-run-migration.mjs migrations/CA_0012_compass_revisions_backfill.sql \
--     --verify scripts/CA_0012-verify.sql
--
-- The migration's own gate proves the SQL executed and the counts line up. This
-- proves the ROWS SAY WHAT WE MEANT, which is a different question and the one
-- that matters.
--
-- 🔴 NO psql BACKSLASH COMMANDS. The runner is node-postgres, not psql; a \echo
-- would abort the run with a syntax error.
--
-- 🔴 EVERY CHECK RETURNS A ROW, ALWAYS. The runner skips empty result sets, so a
-- "0 rows means good" query renders as silence — indistinguishable from a query
-- that never ran. Each block below therefore reports a verdict column instead.
-- Read every verdict. Do not skim to "no errors".

-- ── 1. Shape ────────────────────────────────────────────────────────────────
SELECT
  '1. shape' AS step,
  (SELECT count(*) FROM inform.compass_topics)                           AS topics,
  (SELECT count(*) FROM inform.compass_topic_revisions)                  AS revisions,
  (SELECT count(*) FROM inform.compass_topic_revisions WHERE is_current) AS current_revs,
  (SELECT count(*) FROM inform.compass_stance_revisions)                 AS rung_revs,
  (SELECT count(*) FROM (
     SELECT topic_revision_id FROM inform.compass_stance_revisions
     GROUP BY 1 HAVING count(*) <> 5) x)                                 AS ladders_not_five,
  CASE WHEN (SELECT count(*) FROM inform.compass_topics)
          = (SELECT count(*) FROM inform.compass_topic_revisions)
       AND (SELECT count(*) FROM inform.compass_topic_revisions WHERE is_current)
          = (SELECT count(*) FROM inform.compass_topics)
       AND (SELECT count(*) FROM inform.compass_stance_revisions) = 220
       AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions
                       GROUP BY topic_revision_id HAVING count(*) <> 5)
       THEN 'PASS' ELSE 'FAIL' END                                       AS verdict;
-- EXPECT: 44 / 44 / 44 / 220 / 0 / PASS


-- ── 2. Version numbers: the six pre-revised topics must still say 2 ─────────
SELECT
  '2. versions' AS step,
  r.version,
  count(*) AS topics,
  string_agg(t.topic_key, ', ' ORDER BY t.topic_key) AS which
FROM inform.compass_topic_revisions r
JOIN inform.compass_topics t ON t.id = r.topic_id
WHERE r.is_current
GROUP BY r.version
ORDER BY r.version;
-- EXPECT: version 1 -> 38 topics
--         version 2 -> 6 topics: ai-regulation, deportation, healthcare,
--                      housing, immigration, taxes
-- 🔴 If version 2 shows no row, the GREATEST(t.version,1) copy failed and the
--    public record would be claiming these six have never changed.

SELECT
  '2b. version guard' AS step,
  count(*) AS topics_with_wrong_version,
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM inform.compass_topics t
JOIN inform.compass_topic_revisions r ON r.topic_id = t.id AND r.is_current
WHERE r.version <> GREATEST(t.version, 1);


-- ── 3. Every revision is revision 1, published, current, no rung map ───────
SELECT
  '3. revision state' AS step,
  revision, status::text AS status, is_current, change_class::text AS change_class,
  (rung_map IS NULL) AS rung_map_null, count(*) AS n
FROM inform.compass_topic_revisions
GROUP BY 1,2,3,4,5,6
ORDER BY n DESC;
-- EXPECT: exactly ONE row -> 1 | published | t | substantive | t | 44
-- More than one row means the backfill treated some topics differently.


-- ── 4. The public note for the six — this is prose voters will read ────────
SELECT
  '4. public note' AS step,
  t.topic_key, r.version, r.public_note
FROM inform.compass_topic_revisions r
JOIN inform.compass_topics t ON t.id = r.topic_id
WHERE r.version > 1
ORDER BY t.topic_key;
-- EXPECT: 6 rows, each ending "...the earlier wording was not kept."
-- Read the prose itself. It is published.


-- ── 5. Topic content byte-identical to source ─────────────────────────────
SELECT
  '5. topic text' AS step,
  count(*) AS topics_differing,
  string_agg(t.topic_key, ', ' ORDER BY t.topic_key) AS which,
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM inform.compass_topics t
JOIN inform.compass_topic_revisions r ON r.topic_id = t.id AND r.is_current
WHERE t.title         IS DISTINCT FROM r.title
   OR t.short_title   IS DISTINCT FROM r.short_title
   OR t.question_text IS DISTINCT FROM r.question_text;


-- ── 6. Ladder byte-identical, rung for rung ───────────────────────────────
SELECT
  '6. ladder text' AS step,
  count(*) AS rungs_differing,
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM inform.compass_stances s
JOIN inform.compass_topic_revisions r ON r.topic_id = s.topic_id AND r.is_current
LEFT JOIN inform.compass_stance_revisions sr
       ON sr.topic_revision_id = r.id AND sr.value = s.value
WHERE sr.id IS NULL
   OR s.text                 IS DISTINCT FROM sr.text
   OR s.description          IS DISTINCT FROM sr.description
   OR s.supporting_points    IS DISTINCT FROM sr.supporting_points
   OR s.example_perspectives IS DISTINCT FROM sr.example_perspectives;


-- ── 7. Answer provenance: nothing left unstamped ──────────────────────────
SELECT
  '7. provenance' AS step,
  (SELECT count(*) FROM inform.compass_responses)                                         AS responses,
  (SELECT count(*) FROM inform.compass_responses WHERE answered_revision_id IS NULL)      AS resp_null,
  (SELECT count(*) FROM inform.compass_change_history)                                    AS history,
  (SELECT count(*) FROM inform.compass_change_history WHERE answered_revision_id IS NULL) AS hist_null,
  CASE WHEN (SELECT count(*) FROM inform.compass_responses WHERE answered_revision_id IS NULL) = 0
        AND (SELECT count(*) FROM inform.compass_change_history WHERE answered_revision_id IS NULL) = 0
       THEN 'PASS' ELSE 'FAIL' END                                                        AS verdict;
-- EXPECT: both *_null are 0, verdict PASS.
-- The TOTALS are whatever they are now. Do not compare them to a number from an
-- earlier session — they grow with real usage (1,818 -> 1,819 in one hour).


-- ── 8. Provenance points at the RIGHT topic, not merely at something ───────
SELECT
  '8. provenance target' AS step,
  count(*) AS mismatched,
  CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM inform.compass_responses resp
JOIN inform.compass_topic_revisions r ON r.id = resp.answered_revision_id
WHERE r.topic_id <> resp.topic_id;
-- Non-zero means answers were stamped with another topic's revision, which would
-- make every stale-answer notice point at the wrong change.


-- ── 9. Compat views: one row per topic, no fan-out ────────────────────────
SELECT
  '9. views' AS step,
  (SELECT count(*) FROM inform.compass_topics_live)  AS view_topics,
  (SELECT count(*) FROM inform.compass_stances_live) AS view_rungs,
  (SELECT count(*) FROM (
     SELECT id FROM inform.compass_topics_live GROUP BY 1 HAVING count(*) > 1) d) AS duplicated,
  CASE WHEN (SELECT count(*) FROM inform.compass_topics_live)
          = (SELECT count(*) FROM inform.compass_topics)
       AND (SELECT count(*) FROM inform.compass_stances_live)
          = (SELECT count(*) FROM inform.compass_stances)
       AND NOT EXISTS (SELECT 1 FROM inform.compass_topics_live GROUP BY id HAVING count(*) > 1)
       THEN 'PASS' ELSE 'FAIL' END AS verdict;
-- EXPECT: 44 / 220 / 0 / PASS
-- 🔴 duplicated > 0 would silently multiply every topic list in the product.


-- ── 10. The view reproduces the shape today's callers expect ─────────────
SELECT
  '10. view shape' AS step,
  topic_key, title, short_title, is_live, is_active, version, revision,
  change_class::text AS change_class, went_live_at, office_scope, judicial_role
FROM inform.compass_topics_live
ORDER BY topic_key
LIMIT 3;
-- EXPECT: is_live and is_active both true; version/revision populated; nothing
-- NULL here that is NOT NULL in inform.compass_topics today.


-- ── 11. The freeze is armed ──────────────────────────────────────────────
SELECT
  '11. triggers' AS step,
  count(*) AS armed,
  string_agg(tgname, ', ' ORDER BY tgname) AS which,
  CASE WHEN count(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS verdict
FROM pg_trigger
WHERE NOT tgisinternal
  AND tgname IN ('compass_topics_content_frozen',
                 'compass_stances_content_frozen',
                 'compass_topic_revisions_no_content_edits',
                 'compass_stance_revisions_no_published_edits');
-- EXPECT: 4 / PASS.
-- The freeze is NOT fired here on purpose — a RAISE would abort the rehearsal.
-- To prove it bites, after applying for real, in a throwaway transaction:
--   BEGIN;
--     UPDATE inform.compass_topics SET title = title || ' x'
--      WHERE topic_key = 'housing';    -- must RAISE LEGACY_CONTENT_FROZEN
--   ROLLBACK;

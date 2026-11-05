-- CC_0349_politician_answers_effective.sql
-- Author: Chris Cantrell. Slot reserved from the steward allocator 2026-11-04.
--
-- =============================================================================
-- CC_0349: a researched answer whose rung was INVALIDATED must not be shown
-- =============================================================================
-- CC_0061 defines a per-answer disposition (fresh / reworded / moved / invalidated)
-- and CC_0062 built `inform.compass_responses_effective` so that a VOTER's own
-- answer is dropped once the rung it sits on no longer exists. compassService.ts
-- states the reason on the candidate path, in its own words:
--
--     "THIS IS AN EMPOWERED CANDIDATE'S COMPASS AS SHOWN TO VOTERS, so a value
--      whose rung moved under it must not appear here: it would read as a
--      position the candidate never took."
--
-- 🔴 THAT PROTECTION HAS A HOLE. It covers Path A — the few people who answer the
-- compass themselves through an empowered profile — and does not cover Path B,
-- `inform.politician_answers`, which holds the ~33,000 RESEARCHED answers behind
-- almost every profile on the site. Path B consults `rung_map` nowhere, so an
-- official keeps showing a position on a rung the live ladder has deleted.
--
-- This view is the Path B analogue of compass_responses_effective.
--
-- WHAT THIS DOES
--   Creates `inform.politician_answers_effective`: every column of
--   `inform.politician_answers`, minus the rows whose disposition is
--   'invalidated'. Reuses `inform.compass_answer_disposition()` — the one copy of
--   that rule (CC_0061 "has an owner and one copy") — rather than restating it.
--
-- 🔴 DELIBERATELY NOT 'moved', THOUGH compass_responses_effective DROPS BOTH.
--   Measured on production 2026-11-04, suppressing 'moved' here would remove
--   1,658 housing and 638 same-sex-marriage answers on top of the 28 below.
--   For a VOTER's answer, suppression is right: relocating what a person said
--   puts words in their mouth, and the remedy is to ask them again. A RESEARCHED
--   answer has nobody to re-ask, and `rung_map` is defined in
--   compassRevisionService.ts as "where an answer at this rung goes" — so the
--   right treatment of a moved rung is to RELOCATE it, not to hide it.
--   That is a larger editorial change and it rests on each map being correct.
--   Four maps have now been found asserting a false identity (climate-change,
--   school-vouchers, campaign-finance, voting-rights), so no answer is moved on a
--   map's say-so until that map has been checked rung text by rung text.
--   ▶ OPEN: decide 'moved' per topic, after verifying that topic's map.
--
-- MEASURED BLAST RADIUS (production, 2026-11-04, value <> 0, non-draft seasons):
--   same-sex-marriage  invalidated  28 answers   ← the only rows this hides
--   same-sex-marriage  moved       638 answers   ← left alone by this migration
--   housing            moved     1,658 answers   ← left alone by this migration
--   Those 28 sit on Season 1 same-sex-marriage rung 3 ("leave it to the states"),
--   which Season 2 DELETED rather than moved. They cannot be ported at any price;
--   until now they rendered as whatever Season 2 rung 3 happens to say.
--
-- Writes NOTHING. No answer, context, revision or rung_map is modified; this
-- migration creates one read-only view. It seats no chair, so the chair-evidence
-- gate is NOT APPLICABLE and was not run (an "OK: all 0" from it would be vacuous).
--
-- Applied by hand as `postgres` over the supabase-local MCP; there is no
-- migration runner. Verified on row counts, not on absence of an error.

BEGIN;

-- Guard: the disposition function and the promoted-topics source must both exist,
-- or the view would silently define a different rule from CC_0061's.
DO $$
BEGIN
  IF to_regprocedure('inform.compass_answer_disposition(uuid,uuid,numeric)') IS NULL THEN
    RAISE EXCEPTION 'CC_0349: inform.compass_answer_disposition(uuid,uuid,numeric) is missing; CC_0061 must be applied first';
  END IF;
  IF to_regclass('inform.compass_topics_promoted') IS NULL THEN
    RAISE EXCEPTION 'CC_0349: inform.compass_topics_promoted is missing';
  END IF;
END $$;

CREATE OR REPLACE VIEW inform.politician_answers_effective AS
WITH eff AS (
  -- One row per promoted topic, not one per answer: the effective revision is a
  -- property of the topic. Resolving it per answer would run this lateral ~33,000
  -- times on a read that serves every profile page.
  SELECT p.id AS topic_id, e.effective_revision_id
    FROM inform.compass_topics_promoted p
    LEFT JOIN LATERAL (
      SELECT e.id AS effective_revision_id
        FROM inform.compass_topic_revisions pin
        JOIN inform.compass_topic_revisions e
          ON e.topic_id = pin.topic_id
         AND e.version  = pin.version
         AND e.status IN ('published', 'superseded')
       WHERE pin.id = p.season_revision_id
       ORDER BY e.revision DESC
       LIMIT 1
    ) e ON true
)
SELECT pa.politician_id,
       pa.topic_id,
       pa.value,
       pa.write_in_text,
       pa.season_id,
       pa.topic_revision_id,
       pa.editor_id,
       pa.created_at,
       pa.updated_at
  FROM inform.politician_answers pa
  -- LEFT JOIN, so a topic that is not promoted keeps its answers: the disposition
  -- function returns 'fresh' when the effective revision is NULL, and an
  -- unpromoted topic has no live ladder to have deleted anything.
  LEFT JOIN eff ON eff.topic_id = pa.topic_id
 WHERE inform.compass_answer_disposition(
         pa.topic_revision_id, eff.effective_revision_id, pa.value
       ) IS DISTINCT FROM 'invalidated';

COMMENT ON VIEW inform.politician_answers_effective IS
  'inform.politician_answers minus answers whose rung was INVALIDATED by the live '
  'ladder (CC_0349). The Path B analogue of compass_responses_effective (CC_0062). '
  'Does NOT drop ''moved'' answers — see CC_0349 for why.';

GRANT SELECT ON inform.politician_answers_effective TO anon, authenticated, service_role;

COMMIT;

-- VERIFICATION (run after COMMIT, as separate statements):
--
--   -- exactly the 28 same-sex-marriage rows are hidden, and nothing else
--   SELECT (SELECT count(*) FROM inform.politician_answers)           AS base,
--          (SELECT count(*) FROM inform.politician_answers_effective) AS effective,
--          (SELECT count(*) FROM inform.politician_answers)
--            - (SELECT count(*) FROM inform.politician_answers_effective) AS hidden;
--   -- expect hidden = 28
--
--   -- and that every hidden row is same-sex-marriage rung 3
--   SELECT ct.topic_key, pa.value, count(*)
--     FROM inform.politician_answers pa
--     JOIN inform.compass_topics ct ON ct.id = pa.topic_id
--    WHERE NOT EXISTS (
--            SELECT 1 FROM inform.politician_answers_effective e
--             WHERE e.politician_id = pa.politician_id
--               AND e.topic_id = pa.topic_id
--               AND e.season_id = pa.season_id)
--    GROUP BY 1, 2;
--
-- ROLLBACK:  DROP VIEW inform.politician_answers_effective;

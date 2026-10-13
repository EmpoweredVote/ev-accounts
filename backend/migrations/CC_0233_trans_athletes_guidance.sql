-- CC_0233 — rewrite the `trans-athletes` guidance line. Review change, first of its kind.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL. `CC_0232` seeded the original.
--
--
-- ══ WHAT WAS WRONG WITH IT ═══════════════════════════════════════════════════════════════════
--
--   was:  Where eligibility should be drawn, and on what basis.
--   now:  Whether gender identity or sex at birth decides which team someone plays on, or
--         whether it turns on the particular sport.
--
-- The old line was neutral, which is the hard half, and said nothing, which is the rest of the
-- job. "Where eligibility should be drawn" is a paraphrase of the question directly above it —
-- "How should sports leagues determine eligibility for transgender athletes?" — so a reader who
-- did not already know what the disagreement was about learned nothing by reading it twice.
--
-- The ladder holds three real positions, and the line now names all three:
--
--   1-2  the team follows the athlete's gender identity
--   3    it turns on the requirements of the particular sport
--   4-5  the team follows sex at birth, out to exclusion from organized sport
--
-- Each end is given in the plain words that side uses for its own position, which is the only
-- way this line can sit above those five options without putting a thumb on them.
--
-- ⚠ IT DOES NOT NAME RUNG 5 SEPARATELY, AND THAT IS A JUDGEMENT, NOT AN OVERSIGHT. Rung 5 is a
-- ban on competing at all, which is a different KIND of claim from the other four rather than a
-- stricter version of rung 4. Spelling it out ran to twenty-eight words against a twelve-to-
-- twenty-word house length, and a line that long stops being read. The option itself is on
-- screen directly underneath, in its own words, which is where a reader meets it either way.

BEGIN;

UPDATE inform.compass_topic_revisions r
   SET guidance = 'Whether gender identity or sex at birth decides which team someone plays on, '
                  'or whether it turns on the particular sport.'
  FROM inform.compass_topics t
 WHERE t.topic_key = 'trans-athletes'
   AND r.topic_id = t.id;

-- The served revision is resolved from the season's pin at read time, so "did the UPDATE touch
-- the row a voter actually sees?" is not answerable by counting affected rows. Ask the question
-- the way the API asks it.
DO $$
DECLARE v_live TEXT;
BEGIN
  SELECT eff.guidance INTO v_live
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topics t ON t.id = p.id AND t.topic_key = 'trans-athletes'
    JOIN LATERAL (
      SELECT e.guidance
        FROM inform.compass_topic_revisions pin
        JOIN inform.compass_topic_revisions e
          ON e.topic_id = pin.topic_id AND e.version = pin.version
         AND e.status IN ('published', 'superseded')
       WHERE pin.id = p.season_revision_id
       ORDER BY e.revision DESC
       LIMIT 1
    ) eff ON true;

  IF v_live IS NULL THEN
    RAISE EXCEPTION 'GUIDANCE_MISSING: trans-athletes is not promoted, or its served revision has no guidance';
  END IF;
  IF v_live NOT LIKE 'Whether gender identity or sex at birth%' THEN
    RAISE EXCEPTION 'GUIDANCE_NOT_SERVED: the served revision still reads %', v_live;
  END IF;
END $$;

COMMIT;

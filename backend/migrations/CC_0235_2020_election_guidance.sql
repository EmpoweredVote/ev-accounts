-- CC_0235 — rewrite the `2020-election` guidance line.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL. `CC_0232` seeded the original.
-- Third review batch. `CC_0233` (trans-athletes) and `CC_0234` (Ukraine, Israel) came first.
--
--
-- ══ 🔴 THE ONE LINE WHERE NEUTRALITY IS NOT THE EASY PART ════════════════════════════════════
--
--   was:  Whether the certified result settled the question, or whether real doubts about it
--         remain.
--   now:  Whether anything went wrong in 2020, and whether it was enough to change who won.
--
-- Every other guidance line names an axis between two POSITIONS, and nothing about naming them
-- commits the product to either. This question is different in kind: its rungs are claims about
-- WHAT HAPPENED, and a line that stays even-handed about a matter of fact can end up asserting
-- that the fact is unsettled.
--
-- That is exactly what the old line did. "Whether real doubts about it remain" is not a
-- description of what the reader is choosing between — it is a claim about the world, that
-- doubts exist and are real. The compass has no business making that claim, in either
-- direction. Flipping it to the opposite assertion would be the same error wearing the other
-- coat.
--
-- The new line gets out of the way. It describes the CHOICE and says nothing about the record:
-- whether anything went wrong is left open, whether it was enough is left open, and the reader
-- supplies both answers. That is more neutral than the line it replaces, not softer.
--
--
-- ══ AND IT IS ALSO THE MORE USEFUL READING OF THE LADDER ═════════════════════════════════════
--
--   1  the election was fair and Joe Biden won legitimately
--   2  Joe Biden won, but the election had real problems worth fixing
--   3  there was some fraud, but not enough to change the result
--   4  fraud or irregularities may have been enough to change the result
--   5  the election was stolen from Donald Trump through widespread fraud
--
-- Two things move here, not one. How much went wrong climbs the whole ladder — nothing,
-- administrative problems, some fraud, widespread fraud. Whether it changed the OUTCOME turns
-- over exactly once, between 3 and 4.
--
-- ⚠ SO RUNGS 1, 2 AND 3 ALL SAY BIDEN WON, and that is not obvious at a glance: rung 3 names
-- fraud and still lands on the same conclusion as rung 1. A reader who skims and reads "fraud"
-- as the dividing word picks the wrong rung. The line now names both movements, so the hinge
-- between 3 and 4 is findable.
--
-- "Went wrong" rather than "fraud" is deliberate and load-bearing: rung 2 alleges no fraud at
-- all, only "real problems worth fixing". A line that framed the whole ladder as a question
-- about fraud would have no room for the rung that explicitly is not one.

BEGIN;

UPDATE inform.compass_topic_revisions r
   SET guidance = 'Whether anything went wrong in 2020, and whether it was enough to change who won.'
  FROM inform.compass_topics t
 WHERE t.topic_key = '2020-election'
   AND r.topic_id = t.id;

-- Checked on the SERVED revision. Which revision a voter reads is resolved from the season's
-- pin at read time, so an affected-row count cannot answer "did this reach anybody?".
DO $$
DECLARE v_live TEXT;
BEGIN
  SELECT eff.guidance INTO v_live
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topics t ON t.id = p.id AND t.topic_key = '2020-election'
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
    RAISE EXCEPTION 'GUIDANCE_MISSING: 2020-election is not promoted, or its served revision has no guidance';
  END IF;
  IF v_live NOT LIKE 'Whether anything went wrong in 2020%' THEN
    RAISE EXCEPTION 'GUIDANCE_NOT_SERVED: the served revision still reads %', v_live;
  END IF;
END $$;

COMMIT;

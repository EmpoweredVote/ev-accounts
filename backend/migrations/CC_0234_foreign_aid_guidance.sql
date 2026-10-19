-- CC_0234 — rewrite the `ukraine-support` and `israel-military-aid` guidance lines.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL. `CC_0232` seeded the originals.
-- Second review batch; `CC_0233` was the first (trans-athletes) and reads the same way.
--
--
-- ══ WHAT BOTH OLD LINES GOT WRONG, AND IT WAS THE SAME THING ═════════════════════════════════
--
--   ukraine  was:  Whether support should continue, grow, narrow, or end.
--   israel   was:  Whether aid should continue as it is, carry conditions, or end.
--
-- Both read the ladder as a dial — more aid at one end, none at the other — and so described
-- the SHAPE of the options instead of the disagreement inside them. "Continue, grow, narrow, or
-- end" is true of any question about a quantity, which is another way of saying it is true of
-- nothing in particular. A reader learned the rungs went up and down, which they could see.
--
-- Neither ladder is actually a dial. Each rung carries its own ARGUMENT, and the arguments are
-- what a voter is choosing between.
--
--
-- ══ UKRAINE: THREE CLAIMS, NOT FIVE AMOUNTS ══════════════════════════════════════════════════
--
--   1  increase aid
--   2  keep current levels "to help Ukraine defend itself"
--   3  limited humanitarian aid only, "while encouraging diplomatic negotiations to end the war"
--   4  reduce it and "focus American resources on domestic priorities instead"
--   5  end it and "stay completely out of the conflict"
--
-- Rungs 1-2 hold that the aid is what lets Ukraine hold on. Rung 3 holds the opposite — that
-- arming the war is what keeps it going, and the way out is the negotiating table. Rungs 4-5
-- are a different argument again, about what America owes elsewhere and at home. The new line
-- states the first two in the words each side uses for its own position, and names the third.
--
--
-- ══ ISRAEL: THE AXIS IS STRINGS, NOT AMOUNT ══════════════════════════════════════════════════
--
--   1  full aid, "with no new conditions"
--   2  continue, but require compliance with humanitarian and human-rights law
--   3  block offensive weapons, continue defensive support such as missile defense
--   4  sharply cut, "as a step toward ending it"
--   5  end all military aid
--
-- Rung 3 gives this away: it is not less aid than rung 2, it is a different KIND of condition —
-- on the weapon rather than on the conduct. So the question running through 1 to 3 is whether
-- the aid comes with strings at all, with 4-5 answering a further question about whether the
-- relationship continues. A line about "levels" misses every bit of that.

BEGIN;

UPDATE inform.compass_topic_revisions r
   SET guidance = g.guidance
  FROM (VALUES
    ('ukraine-support',
     'Whether aid helps Ukraine hold its ground or works against a negotiated end, '
     'and how far American resources should stretch.'),
    ('israel-military-aid',
     'Whether the aid is an unconditional commitment, leverage over how it is used, '
     'or something to wind down.')
  ) AS g(topic_key, guidance)
  JOIN inform.compass_topics t ON t.topic_key = g.topic_key
 WHERE r.topic_id = t.id;

-- Checked on the SERVED revision, for both. Which revision a voter reads is resolved from the
-- season's pin at read time, so an affected-row count cannot answer "did this reach anybody?".
DO $$
DECLARE
  v_key  TEXT;
  v_want TEXT;
  v_live TEXT;
BEGIN
  FOR v_key, v_want IN
    SELECT * FROM (VALUES
      ('ukraine-support',     'Whether aid helps Ukraine hold its ground%'),
      ('israel-military-aid', 'Whether the aid is an unconditional commitment%')
    ) AS x(k, w)
  LOOP
    SELECT eff.guidance INTO v_live
      FROM inform.compass_topics_promoted p
      JOIN inform.compass_topics t ON t.id = p.id AND t.topic_key = v_key
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
      RAISE EXCEPTION 'GUIDANCE_MISSING: % is not promoted, or its served revision has no guidance', v_key;
    END IF;
    IF v_live NOT LIKE v_want THEN
      RAISE EXCEPTION 'GUIDANCE_NOT_SERVED: % still reads %', v_key, v_live;
    END IF;
  END LOOP;
END $$;

COMMIT;

-- 1862_retire_oconnell_public_safety_approach.sql
-- Mayor Freddie O'Connell, public-safety-approach, Season 2: retire the chair-4 answer and rewrite
-- the reasoning as a documented blank. One answer row, one context row.
--
-- 🔴 THE EVIDENCE IS UNDER-DETERMINED BETWEEN CHAIR 3 AND CHAIR 4, WHICH MEANS IT EVIDENCES NEITHER.
-- The row was flagged for review by the pass that created it (2026-09-11). Chair 4's instruments --
-- staffing, equipment, pay -- do appear verbatim in his own list, under an ad headlined "invest in
-- police", and he rejects the defund reading. But asked what that line means he answers "we already
-- have", and locates the constraint in RECRUITMENT CLASS SIZE rather than in budget level. That is
-- chair 3's funding posture, not chair 4's. Chair 3 was rejected at seating time only because its
-- distinguishing clause -- crisis response teams -- is absent from the interview.
-- So the record supports "he funds the police" and does not discriminate between the two chairs that
-- differ on how much. Same failure mode as the Nashville blanks already recorded in that pass: a
-- bare direction under-determines the chair, and we seat only where the rationale is given.
--
-- 🔑 WHY A BLANK IS EARNED HERE, AND NOT A DELETE (mig 1755's remedy). The question applies to him --
-- a mayor can hold a position on public-safety approach, and in fact clearly does. Deleting the
-- context would discard the record of what was read. The looking is ON THE RECORD: two Banner pieces,
-- both named below, one of them a trap that cost a pass to identify. Same gate, same shape, opposite
-- remedy -- see 1755 vs 1756/1757.
--
-- ⚠ THE "Researched YYYY-MM-DD" PREFIX IS A CARVE-OUT, NOT A LICENCE. It exempts the row from the
-- gate's ORPHAN_CONTEXT branch, so it could exempt anything prefixed with it. It is legitimate here
-- only because the row states what was read (2 pieces, named) and why each failed to place him.
--
-- 🔑 THE SECOND SOURCE IS A TRAP AND THE BLANK SAYS SO. nashvillebanner.com/2023/11/21/
-- oconnell-outlines-policy-initiatives-for-term/ reports his TRANSITION COMMITTEES' recommendations,
-- not his positions. Its most quotable line belongs to a committee report. Seating him from it would
-- be the same attribution error as seating from a bill title. Recorded in the reasoning so the next
-- pass does not spend itself rediscovering that.
--
-- SOURCES ARE NOT TOUCHED. The citation records what was checked, which is exactly what a documented
-- blank should carry -- the same shape as the cited blanks the gate already carves out.
--
-- ▶ NOT A CLAIM THAT HE HAS NO VIEW. If a record turns up that names a mechanism -- a budget
-- amendment, a hiring ordinance, a co-response programme -- he is a re-seat candidate. The blank says
-- the chair is unevidenced, not that the position is absent.
--
-- His transportation-priorities row (chair 1, same Banner interview) is UNAFFECTED and stands: it
-- names the instrument -- the IMPROVE Act referendum for dedicated transit funding.
--
-- Nashville coverage goes 38 -> 38 officials with rows (he keeps transportation-priorities), so the
-- essentials coverage chip does not move. Checked, not assumed -- see the guard below.
--
-- Rollback: data/stance-retirement/2026-09-12-oconnell-public-safety-1862-rollback.json

BEGIN;

CREATE TEMP TABLE oc_target ON COMMIT DROP AS
SELECT pa.politician_id AS pid, pa.topic_id AS tid, pa.season_id AS sid
FROM inform.politician_answers pa
JOIN inform.compass_topics t ON t.id = pa.topic_id
WHERE pa.politician_id = 'a5fd7757-33e0-428c-bc7a-4224aac9e4ab'
  AND t.topic_key = 'public-safety-approach';

-- GUARD 1: exactly the one row, at exactly the chair we are retiring. If the row has already been
-- corrected or removed by another pass, stop rather than write over someone else's decision.
DO $$
DECLARE n int; v numeric;
BEGIN
  SELECT count(*) INTO n FROM oc_target;
  IF n <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 O''Connell public-safety-approach answer, found %', n;
  END IF;
  SELECT pa.value INTO v
    FROM inform.politician_answers pa JOIN oc_target t
      ON t.pid = pa.politician_id AND t.tid = pa.topic_id AND t.sid = pa.season_id;
  IF v <> 4 THEN
    RAISE EXCEPTION 'expected the seated chair to be 4, found % -- someone has already moved it', v;
  END IF;
END $$;

CREATE TEMP TABLE oc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DELETE FROM inform.politician_answers pa
USING oc_target t
WHERE pa.politician_id = t.pid AND pa.topic_id = t.tid AND pa.season_id = t.sid;

-- @context-decision: rewritten-as-blank -- the topic applies to a mayor and two Banner pieces were
-- read in full; the reasoning now states what was checked and why neither places him on a chair.
UPDATE inform.politician_context pc
SET reasoning = 'Researched 2026-09-12 - 2 Nashville Banner pieces read in full; no chair is '
              || 'evidenced. The 2023-08-31 one-on-one is under-determined between chairs 3 and 4: '
              || 'chair 4''s instruments (staffing, equipment, pay) appear verbatim in his own ad '
              || 'copy, but asked what "invest in police" means he answers that we already have, and '
              || 'locates the constraint in recruitment class size rather than budget level, which '
              || 'is chair 3''s funding posture; chair 3''s distinguishing crisis-response-team '
              || 'clause is absent. The 2023-11-21 piece reports his transition COMMITTEES'' '
              || 'recommendations, not his own positions, so nothing in it is attributable to him.',
    updated_at = now()
FROM oc_target t
WHERE pc.politician_id = t.pid AND pc.topic_id = t.tid AND pc.season_id = t.sid;

-- GUARD 2: the answer deleted above must not leave gate-visible orphan context behind. This is
-- check-stance-sources.mjs's ORPHAN_CONTEXT predicate, applied to the row THIS migration touched, so
-- the decision is forced here instead of surfacing in CI as someone else's regression.
-- ⚠ Keep the two regexes character-identical to the gate's.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM oc_target t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';

  IF new_orphans > 0 THEN
    RAISE EXCEPTION
      'context guard: % row(s) lost their answer but kept reasoning that still describes a position. '
      'Delete that context, or rewrite it as a documented blank, IN THIS MIGRATION -- not later.',
      new_orphans;
  END IF;
END $$;

-- GUARD 3: magnitudes. Exactly one answer gone, no context row gained or lost, and the reasoning
-- must no longer assert the chair-4 case.
DO $$
DECLARE a_delta int; c_delta int; stale int;
BEGIN
  SELECT s.ans_before - (SELECT count(*) FROM inform.politician_answers),
         (SELECT count(*) FROM inform.politician_context) - s.ctx_before
    INTO a_delta, c_delta
    FROM oc_snap s;
  IF a_delta <> 1 THEN RAISE EXCEPTION 'expected exactly 1 answer deleted, got %', a_delta; END IF;
  IF c_delta <> 0 THEN RAISE EXCEPTION 'expected 0 net context rows, got %', c_delta; END IF;

  SELECT count(*) INTO stale
    FROM oc_target t JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid AND pc.season_id = t.sid
   WHERE pc.reasoning LIKE 'Banner 1:1%';
  IF stale > 0 THEN RAISE EXCEPTION 'the old chair-4 reasoning survived the rewrite'; END IF;
END $$;

-- GUARD 4: the coverage chip must not move. He keeps transportation-priorities, so Nashville stays at
-- 38 officials with at least one answer. Asserted rather than assumed, because a pass that empties a
-- politician is how a chip silently goes stale (see mig 1538/1540).
DO $$
DECLARE remaining int;
BEGIN
  SELECT count(*) INTO remaining
    FROM inform.politician_answers
   WHERE politician_id = 'a5fd7757-33e0-428c-bc7a-4224aac9e4ab' AND value <> 0;
  IF remaining < 1 THEN
    RAISE EXCEPTION 'this emptied O''Connell (% rows left) -- the Nashville coverage chip needs a '
                    'decision before this can land', remaining;
  END IF;
END $$;

COMMIT;

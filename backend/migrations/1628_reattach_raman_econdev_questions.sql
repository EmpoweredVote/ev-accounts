-- 1628_reattach_raman_econdev_questions.sql
--
-- Moves Nithya Raman's three economic-development answers off the legacy pooled question
-- (ded400bd, origin='compass', and owned by the retired JUNE PRIMARY race) onto the two
-- race-local moderator questions created in 1626. Bass's side was attached in 1627; this
-- completes both sets.
--
-- Gate 2 (question-as-unit design) checked per quote — each genuinely answers the question it is
-- being attached to:
--
--   644bc8e7 -> FILM.  "reducing red tape in City Hall to make sure that productions have no bar
--                       to being able to film here. I also would create a real film office here."
--                      Forward, city-lever, and mechanism-bearing (institutional capacity).
--   79641bcb -> FILM.  "a tax credit that has no cap, that is guaranteed years into the future."
--                      Forward. Note this is a STATE lever the mayor would advocate for, not a
--                      city lever — see the pairing note below.
--   f7625f7b -> DOWNTOWN. "It needs more public safety officials on the streets. It needs work
--                      with businesses to ensure that businesses aren't just fleeing downtown LA."
--                      Answers the question, but see the two caveats below.
--
-- e7f20cf7 ("Small businesses are what gives a neighborhood its character") is deliberately LEFT
-- on the legacy question: it answers neither of the two new ones.
--
-- ── TWO DEPENDENCIES THIS MIGRATION DOES NOT RESOLVE ──────────────────────────────────────────
--
-- 1. f7625f7b LEAKS THE OPPONENT ON THE BLIND CARD. Its deidentified_text still contains
--    "Instead, what Mayor Bass has done is to dismantle our economic development department" —
--    naming the other candidate on a card whose entire premise is that the reader does not know
--    who is speaking. A separate session is fixing this. Attaching does NOT increase the risk
--    (the row is already an equally-selectable draft on the legacy question), but the downtown
--    question MUST NOT be taken live until that fix lands.
--
--    That quote also carries a second weakness: much of it is diagnosis ("needs attention",
--    "needs real care", "needs regular cleanups") rather than prescription, and its closing
--    clause is a record attack. It is Raman's only downtown answer, so it is attached rather than
--    withheld — but it is the weaker half of that set.
--
-- 2. EDITOR NOTES ARE STILL EMPTY on all three rows. Notes are curator text requiring human
--    sign-off on wording, so this migration deliberately does not invent them. No row here can go
--    live until it has one.
--
-- ── PAIRING NOTE FOR WHOEVER SELECTS ──────────────────────────────────────────────────────────
--
-- The film question now holds 2 drafts per candidate, and the pairing choice matters:
--   * Bass (TheWrap) x Raman 644bc8e7 — BOTH on city levers (permitting and red tape). Directly
--     rival, and the strongest available comparison.
--   * Bass (TheWrap) x Raman 79641bcb — city permitting against state tax-credit advocacy. Likely
--     to read INCOMMENSURABLE: no shared axis on which preferring one means anything.
-- Selecting the second pairing would manufacture a comparison out of two different questions.

BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id IN ('644bc8e7-4545-4f50-b40e-0c2b6ae0a055',
                '79641bcb-46d8-464d-b72d-1e6110308fea',
                'f7625f7b-634f-49d4-9155-ab38455ba400')
     AND politician_id = '26dbe16a-9dff-42c0-939f-5b5e529063ca'
     AND readrank_selected = false;
  IF n <> 3 THEN
    RAISE EXCEPTION 'Aborting: expected 3 Raman draft rows, found %.', n;
  END IF;
END $$;

UPDATE essentials.quotes
   SET question_id = (SELECT id FROM essentials.readrank_questions
                       WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
                         AND question_text = 'What should Los Angeles do to keep film and television production from leaving?')
 WHERE id IN ('644bc8e7-4545-4f50-b40e-0c2b6ae0a055',
              '79641bcb-46d8-464d-b72d-1e6110308fea');

UPDATE essentials.quotes
   SET question_id = (SELECT id FROM essentials.readrank_questions
                       WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
                         AND question_text = 'How should Los Angeles respond to the decline of its downtown core?')
 WHERE id = 'f7625f7b-634f-49d4-9155-ab38455ba400';

-- Guard: both questions must now carry BOTH candidates, and nothing may have gone live.
DO $$
DECLARE nf integer; nd integer; nlive integer;
BEGIN
  SELECT count(DISTINCT q.politician_id) INTO nf
    FROM essentials.quotes q JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
     AND rq.question_text LIKE 'What should Los Angeles do to keep film%';
  SELECT count(DISTINCT q.politician_id) INTO nd
    FROM essentials.quotes q JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
     AND rq.question_text LIKE 'How should Los Angeles respond to the decline%';
  SELECT count(*) INTO nlive
    FROM essentials.quotes q JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d' AND rq.origin = 'moderator'
     AND q.readrank_selected;
  IF nf <> 2 OR nd <> 2 THEN
    RAISE EXCEPTION 'Aborting: expected 2 candidates on each question, got film=% downtown=%.', nf, nd;
  END IF;
  IF nlive <> 0 THEN
    RAISE EXCEPTION 'Aborting: these are drafts; found % live.', nlive;
  END IF;
END $$;

COMMIT;

-- 1626_la_mayor_econdev_question_split.sql
--
-- Splits LA Mayor's economic-development question in two. The per-set comparability pass found
-- the existing question pools two unrelated debate exchanges — downtown revitalization and
-- film-industry flight — and BOTH candidates spoke to both halves, so the blur is a scoping
-- defect in the question, not a defect in any quote.
--
-- Both questions are derived from the moderator's actual prompts at the 2026-05-06 NBC4 /
-- Telemundo 52 debate (meeting f2cf80ef-a811-4d95-990d-b9c598284eb6), neutralised per
-- QUOTE-CURATION-PRINCIPLES §7.3. The moderator's framings were loaded and are not reused
-- verbatim:
--   downtown, seg-361: "can we afford to let downtown LA die?"  — presupposes its own answer
--   film,     seg-394: "a lot of people think we're nowhere close to where we should be"
--                                                               — imports framing as fact
--
-- Gate 1 (neutral generalisation, question-as-unit design): an opponent can answer either in the
-- opposite direction without it feeling rigged — "that is Sacramento's job, not the city's" for
-- film, "focus resources elsewhere" for downtown.
-- Blind: neither names a candidate. "Los Angeles" is the race, which §7.3 permits.
-- On-axis: both are species of the Compass economic-development question, so origin='moderator'
-- needs no off-axis declaration and §7.2 coupling continues to apply.
--
-- NO QUOTES ARE ATTACHED. Gate 2 requires that an attached quote genuinely answers the question,
-- and on current material Karen Bass has no forward-looking answer to either half: both her
-- economic-development quotes (ce9bb5b9 film, b2d1f06d downtown) are flagged `not-forward` at high
-- severity — they recite record ("we have expedited permits", "we have a strategy that is
-- working"). Attaching them would launder record into a pseudo-position, which §3 forbids.
-- Both questions are therefore created empty, as a durable question bank, pending a forward Bass
-- answer. The comparability model §10 front-loads the question harvest for exactly this reason:
-- questions outlive any one sourcing pass.
--
-- KNOWN ISSUE, NOT FIXED HERE: the LA Mayor GENERAL race (9e888818) owns zero readrank_questions
-- rows, while its quotes reference 22 questions all owned by the JUNE PRIMARY race (24bc3631) —
-- the same root cause as the mis-pointed pipeline row fixed in 1619. Consequence:
-- readrankQuestionsService.listRaceQuestions('9e888818') returns nothing, so the coverage grid is
-- blind for this race. These two rows are created on the GENERAL race, which is correct; the 22
-- need a decision (repoint vs duplicate) and a migration of their own.

BEGIN;

INSERT INTO essentials.readrank_questions
  (id, race_id, topic_key, question_text, origin, source_ref, status, updated_by)
VALUES
  (gen_random_uuid(),
   '9e888818-c50b-4c61-a106-a0839ff2479d',
   'economic-development',
   'What should Los Angeles do to keep film and television production from leaving?',
   'moderator',
   jsonb_build_object('meeting_id', 'f2cf80ef-a811-4d95-990d-b9c598284eb6',
                      'segment_index', 394, 'start_time', 4848,
                      'video_url', 'https://www.youtube.com/watch?v=8rI3A6alVHM',
                      'note', 'Moderator framing neutralised; see migration header.'),
   'confirmed',
   'spec-2026-08-07-showcase-contrast'),

  (gen_random_uuid(),
   '9e888818-c50b-4c61-a106-a0839ff2479d',
   'economic-development',
   'How should Los Angeles respond to the decline of its downtown core?',
   'moderator',
   jsonb_build_object('meeting_id', 'f2cf80ef-a811-4d95-990d-b9c598284eb6',
                      'segment_index', 357, 'start_time', 4468,
                      'video_url', 'https://www.youtube.com/watch?v=8rI3A6alVHM',
                      'note', 'Moderator framing neutralised; see migration header.'),
   'confirmed',
   'spec-2026-08-07-showcase-contrast');

-- Guard: exactly two moderator-origin economic-development questions on the general race, and
-- no quote attached to either.
DO $$
DECLARE nq integer; na integer;
BEGIN
  SELECT count(*) INTO nq FROM essentials.readrank_questions
   WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
     AND topic_key = 'economic-development' AND origin = 'moderator';
  IF nq <> 2 THEN
    RAISE EXCEPTION 'Aborting: expected 2 moderator questions, found %.', nq;
  END IF;

  SELECT count(*) INTO na FROM essentials.quotes q
    JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d' AND rq.origin = 'moderator';
  IF na <> 0 THEN
    RAISE EXCEPTION 'Aborting: expected 0 attached quotes, found %.', na;
  END IF;
END $$;

COMMIT;

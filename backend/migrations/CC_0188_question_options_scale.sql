-- CC_0188_question_options_scale.sql
--
-- A numeric question may store a 7-mark ascending scale with its correct answer
-- centred at index 3. At serve time the server rolls s in 1..4 and shows the window
-- marks[s-1 .. s+2]; the answer's index in that window is 4-s, so the roll maps onto
-- positions D/C/B/A uniformly while the options still read ascending.
--
-- Nullable on purpose: `options` remains the 4-element source of truth and a question
-- without a scale behaves exactly as before. This column never replaces `options`.
ALTER TABLE trivia.questions
  ADD COLUMN IF NOT EXISTS options_scale jsonb;

COMMENT ON COLUMN trivia.questions.options_scale IS
  '7 ascending numeric option values, correct answer at index 3. NULL = no scale; serve `options` as stored.';

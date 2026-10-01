import type { Question } from './sessionService.js';
import { isValidScale, rollWindow } from './questionQuality/answerScale.js';
import { hasFixedPositionOption } from './questionQuality/answerPlacement.js';

/**
 * A question as the player will see it this session.
 *
 * Position is chosen HERE, per session, rather than being baked into the row. That is
 * the whole point: the stored position was a pure function of `externalId`, and the API
 * serves `externalId` as the question `id` (questionService transformDBQuestions) while
 * stripAnswers() removes only `correctAnswer`. Anything static is therefore derivable,
 * or tabulatable by replay. A per-session roll is not.
 *
 * Numeric questions with a scale get a 4-mark window, so they still read ascending.
 * Everything else is shuffled. Fixed-position option sets are left alone.
 *
 * Returns a new object; never mutates the input.
 */
export function presentQuestion(q: Question, rng: () => number = Math.random): Question {
  if (hasFixedPositionOption(q.options)) return { ...q };

  if (isValidScale(q.optionsScale)) {
    const roll = 1 + Math.floor(rng() * 4);
    const { options, correctAnswer } = rollWindow(q.optionsScale!, Math.min(roll, 4));
    return { ...q, options, correctAnswer };
  }

  // A present-but-invalid scale is a data problem on this specific row, not an
  // ordinary prose/legacy-numeric question. isValidScale's contract is to degrade to
  // "current behavior" (the stored, already-placed order) rather than risk serving a
  // window the answer isn't in -- so this is a deliberate passthrough, distinct from
  // the shuffle branch below, which only ever sees `optionsScale == null`.
  if (q.optionsScale != null) return { ...q };

  // Fisher-Yates over indices, so the answer is tracked by position and duplicate
  // option text cannot retarget it.
  const idx = q.options.map((_, i) => i);
  for (let i = idx.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [idx[i], idx[j]] = [idx[j], idx[i]];
  }
  return {
    ...q,
    options: idx.map((i) => q.options[i]),
    correctAnswer: idx.indexOf(q.correctAnswer),
  };
}

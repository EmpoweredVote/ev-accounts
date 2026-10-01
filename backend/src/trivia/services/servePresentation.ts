import type { Question } from './sessionService.js';
import { isValidScale, rollWindow } from './questionQuality/answerScale.js';
import { hasFixedPositionOption, magnitudeValues, isBoundedSeries } from './questionQuality/answerPlacement.js';

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

  // A legacy numeric question (optionsScale null, pre-dating Task 1/7's backfill) whose
  // options form an UNBOUNDED magnitude series -- populations, years, dollar amounts,
  // distances -- must keep its stored ascending order. Shuffling would scramble numbers
  // that are supposed to read in sequence, which is exactly why scaled numerics exist:
  // to vary position while *staying* ascending. Until Task 7 backfills optionsScale,
  // these rows simply get no per-session position variation -- that preserves today's
  // behaviour rather than regressing it.
  //
  // A BOUNDED series (small whole-number domains like term lengths: min <= 2, max <= 12)
  // is the one magnitude series that write-time code deliberately permutes rather than
  // sorts (see isBoundedSeries' doc comment) -- it is not stored ascending, so nothing is
  // lost by varying it per session, and it falls through to the shuffle below.
  const values = magnitudeValues(q.options);
  if (values && !isBoundedSeries(values)) return { ...q };

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

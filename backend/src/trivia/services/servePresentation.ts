import type { Question } from './sessionService.js';
import { isValidScale, rollWindow, SCALE_ANSWER_INDEX } from './questionQuality/answerScale.js';
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
 * `optionsScale` is deliberately dropped from every return value, even when it was
 * never used (invalid, mismatched, or absent). `SCALE_ANSWER_INDEX` is fixed, so a
 * served `optionsScale` is a plaintext answer key -- stripAnswers() only ever removes
 * `correctAnswer`, not this field -- and carrying it also grows the Upstash session
 * payload by 7 strings per question for no reason once presentation has consumed it.
 *
 * Returns a new object; never mutates the input.
 */
export function presentQuestion(q: Question, rng: () => number = Math.random): Question {
  const { optionsScale, ...rest } = q;

  if (hasFixedPositionOption(rest.options)) return { ...rest };

  // The scale must be well-formed AND agree with this question's actual answer.
  // isValidScale only checks internal shape (length, unit, strict ascent) -- it has no
  // way to know whether SCALE_ANSWER_INDEX actually holds *this* question's answer, so a
  // backfill that writes a well-formed but misaligned scale (wrong index, or copied from
  // a sibling row) would otherwise serve a self-consistent question whose "correct"
  // option the real answer never was, with no audit signal. A mismatch falls through to
  // the passthrough below, exactly like an invalid scale.
  if (isValidScale(optionsScale) && optionsScale![SCALE_ANSWER_INDEX] === rest.options[rest.correctAnswer]) {
    const roll = 1 + Math.floor(rng() * 4);
    const { options, correctAnswer } = rollWindow(optionsScale!, roll);
    return { ...rest, options, correctAnswer };
  }

  // A present-but-unusable scale (invalid shape, or valid shape but misaligned with the
  // question's real answer) is a data problem on this specific row, not an ordinary
  // prose/legacy-numeric question. The contract is to degrade to "current behavior" (the
  // stored, already-placed order) rather than risk serving a window the answer isn't in
  // -- so this is a deliberate passthrough, distinct from the shuffle branch below, which
  // only ever sees `optionsScale == null`.
  if (optionsScale != null) return { ...rest };

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
  const values = magnitudeValues(rest.options);
  if (values && !isBoundedSeries(values)) return { ...rest };

  // Fisher-Yates over indices, so the answer is tracked by position and duplicate
  // option text cannot retarget it.
  const idx = rest.options.map((_, i) => i);
  for (let i = idx.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [idx[i], idx[j]] = [idx[j], idx[i]];
  }
  return {
    ...rest,
    options: idx.map((i) => rest.options[i]),
    correctAnswer: idx.indexOf(rest.correctAnswer),
  };
}

import { magnitudeValues } from './answerPlacement.js';

/** Marks in a scale. A window of 4 over n marks gives n-3 placements; 7 is the
 *  smallest n that reaches all four positions, and every roll 1..4 is valid. */
export const SCALE_LENGTH = 7;

/** Where the correct answer sits in a scale. Centred, so all four rolls include it. */
export const SCALE_ANSWER_INDEX = 3;

/**
 * Whether a stored scale is safe to roll against.
 *
 * Deliberately strict and silent: NULL is the common case (prose questions, and every
 * numeric question written before scales existed), not an error. Anything that fails
 * here falls back to the stored `options`, so a bad scale degrades to current
 * behaviour instead of serving a window the answer might not be in.
 */
export function isValidScale(scale: string[] | null | undefined): boolean {
  if (!Array.isArray(scale) || scale.length !== SCALE_LENGTH) return false;
  // magnitudeValues enforces one unit and no prose dates, but is 4-length by contract,
  // so check the scale in overlapping 4-windows -- which is exactly what will be served.
  for (let i = 0; i + 4 <= SCALE_LENGTH; i++) {
    if (!magnitudeValues(scale.slice(i, i + 4))) return false;
  }
  const values = scale.map((s) => magnitudeValues([s, s, s, s])![0]);
  for (let i = 1; i < values.length; i++) {
    if (!(values[i] > values[i - 1])) return false; // strict: a tie is not orderable
  }
  return true;
}

/**
 * The 4 marks shown for a given roll, and where the answer lands among them.
 *
 * roll s shows marks[s-1 .. s+2]; the answer is at SCALE_ANSWER_INDEX, so its index in
 * the window is SCALE_ANSWER_INDEX - (s-1) = 4 - s. s=1 -> D, s=4 -> A.
 *
 * Throws outside 1..4 rather than returning a window without the answer in it: a
 * window missing its answer scores every player wrong, which is worse than a 500.
 */
export function rollWindow(
  scale: string[],
  roll: number
): { options: string[]; correctAnswer: number } {
  if (!Number.isInteger(roll) || roll < 1 || roll > 4) {
    throw new Error(`roll must be an integer 1..4, got ${roll}`);
  }
  const start = roll - 1;
  return {
    options: scale.slice(start, start + 4),
    correctAnswer: SCALE_ANSWER_INDEX - start,
  };
}

/**
 * The scale generator's rules, as tests, so CI holds them rather than a person
 * remembering to run `npx tsx scripts/build-answer-scales.ts --selftest`.
 *
 * Every case here decides whether a real question gets a scale, and four of them exist
 * because the generator got it wrong first:
 *
 *  - it proposed "1 members | 3 members | ..." for a council, because the stored options
 *    are all plural and no stored answer is 1
 *  - it proposed a ONE-JUSTICE supreme court, because the floor was read off the option
 *    ("9") which carries no unit, while the word "justices" is in the question
 *  - then, once the question was read too, "the state Supreme Court" tripped the
 *    50-states ceiling and beat the floor
 *  - it proposed Interstates 1, 4, 7, 13, 16 and 19, because "Interstate 10" parses as
 *    a quantity
 *
 * An accept case asserts the EXACT marks. "A scale came back" passed while the generator
 * was still proposing the one-justice court.
 */
import { describe, it, expect } from 'vitest';
import { proposeScale, CONTROL_CASES } from './build-answer-scales.js';

describe('proposeScale', () => {
  for (const [question, options, correctAnswer, want, why, expected] of CONTROL_CASES) {
    it(`${want}s: ${why}`, () => {
      const got = proposeScale(question, options, correctAnswer);
      if (want === 'refuse') {
        expect(got.scale, `expected a refusal, got ${got.scale?.join(' | ')}`).toBeUndefined();
        expect(got.reason).toBeTruthy();
        return;
      }
      expect(got.reason, `expected a scale, was refused: ${got.reason}`).toBeUndefined();
      expect(got.scale).toHaveLength(7);
      if (expected) expect(got.scale!.join(' | ')).toBe(expected);
    });
  }

  it('puts the stored answer at index 3, byte for byte', () => {
    // The serve path compares optionsScale[3] to options[correctAnswer] with ===, and
    // falls back to the stored options on any mismatch. A scale that fails this is not
    // wrong in a visible way -- it is simply never used, which is worse.
    const got = proposeScale(
      'How many members serve on the council?',
      ['9 members', '11 members', '13 members', '15 members'],
      2,
    );
    expect(got.scale![3]).toBe('13 members');
  });

  it('spaces every mark equally, so no option is singled out by its spacing', () => {
    const got = proposeScale('How many schools?', ['34', '44', '54', '64'], 1);
    const values = got.scale!.map(Number);
    const gaps = values.slice(1).map((v, i) => v - values[i]);
    expect(new Set(gaps).size).toBe(1);
  });
});

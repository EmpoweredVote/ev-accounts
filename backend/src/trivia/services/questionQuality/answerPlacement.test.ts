import { describe, it, expect } from 'vitest';
import {
  placeAnswer,
  magnitudeRank,
  magnitudeValues,
  hasFixedPositionOption,
} from './answerPlacement.js';

/**
 * Ported from the CTC repo's scripts/verify-answer-placement.ts when the guard was folded
 * into the engine. That repo has no test runner, so its checks live in a script; here they
 * are a normal vitest file. Keep the two in step — the CTC copy still guards the content
 * scripts that repo continues to own.
 */

describe('magnitudeValues — what counts as a comparable series', () => {
  it('treats plain numbers as a series', () => {
    expect(magnitudeValues(['8', '10', '12', '15'])).not.toBeNull();
  });

  it('treats a shared unit as a series', () => {
    expect(magnitudeValues(['2 years', '4 years', '6 years', '8 years'])).not.toBeNull();
  });

  // The singular/plural trap, fixed 2026-09-08: unitOf() singularises its residue, so
  // "1 year" and "2 years" share a unit. 18 active questions were hidden by this alone.
  it('sees through singular/plural inflection', () => {
    expect(magnitudeValues(['1 year', '2 years', '4 years', '6 years'])).not.toBeNull();
  });

  it('sees through y/ies inflection', () => {
    expect(
      magnitudeValues([
        '1 constituency',
        '2 constituencies',
        '3 constituencies',
        '4 constituencies',
      ])
    ).not.toBeNull();
  });

  // Same fix, ordinal half: the residue used to be "st district" against "nd district".
  it('sees through ordinal suffixes', () => {
    expect(
      magnitudeValues(['1st District', '3rd District', '22nd District', '30th District'])
    ).not.toBeNull();
  });

  it('does not collapse genuinely different units', () => {
    expect(magnitudeValues(['5 miles', '10 minutes', '15 members', '20 acres'])).toBeNull();
  });

  it('rejects mixed units — digit extraction would sort 500 above 3', () => {
    expect(magnitudeValues(['$500 million', '$3 billion', '$1 billion', '$2 billion'])).toBeNull();
  });

  it('rejects prose dates', () => {
    expect(
      magnitudeValues(['July 4, 1776', 'June 15, 1780', 'March 4, 1789', 'May 1, 1790'])
    ).toBeNull();
  });

  it('rejects non-numeric options', () => {
    expect(magnitudeValues(['Alice', 'Bob', 'Carol', 'Dave'])).toBeNull();
  });
});

describe('magnitudeRank — rank reads values, never positions', () => {
  it('ranks the smallest 1 and the largest 4', () => {
    expect(magnitudeRank(['5', '7', '9', '12'], 0)).toBe(1);
    expect(magnitudeRank(['5', '7', '9', '12'], 3)).toBe(4);
  });

  it('ranks a bracketed middle 3', () => {
    expect(magnitudeRank(['1776', '1780', '1788', '1791'], 2)).toBe(3);
  });

  it('ranks unsorted input by value', () => {
    expect(magnitudeRank(['100', '160', '200', '120'], 1)).toBe(3);
  });
});

describe('sorting — an unbounded numeric series sorts, so position equals rank', () => {
  it('sorts ascending and reports the placement', () => {
    const placed = placeAnswer(
      ['100 members', '160 members', '200 members', '120 members'],
      1,
      'q'
    );
    expect(placed.options).toEqual(['100 members', '120 members', '160 members', '200 members']);
    expect(placed.placement).toBe('sorted');
    expect(placed.correctAnswer).toBe(2);
    expect(placed.options[placed.correctAnswer]).toBe('160 members');
  });

  it('tracks the answer by index, so duplicate option text cannot retarget it', () => {
    const placed = placeAnswer(['5', '5', '9', '12'], 1, 'dup');
    expect(placed.options[placed.correctAnswer]).toBe('5');
  });
});

describe('bounded series — rank is fixed by the world, so permute instead of sorting', () => {
  // Legislative terms are 1/2/4/6 years, so a 2-year answer is structurally rank 2.
  // Sorting would pin it to position B across the bank — exporting a rank bias that
  // content cannot fix into a position bias that did not previously exist.
  it('permutes a term-length series', () => {
    const opts = ['1 year', '2 years', '4 years', '6 years'];
    const placed = placeAnswer(opts, 1, 'mas-006');
    expect(placed.placement).toBe('permuted');
    expect(placed.options[placed.correctAnswer]).toBe('2 years');
    expect([...placed.options].sort()).toEqual([...opts].sort());
  });

  it('stays measurable — rank is unchanged by permuting', () => {
    expect(magnitudeRank(['1 year', '2 years', '4 years', '6 years'], 1)).toBe(2);
  });

  it('leaves large-magnitude series sorting', () => {
    const placed = placeAnswer(['800,000', '1,000,000', '2,250,000', '5,000,000'], 2, 'stlmo-020');
    expect(placed.placement).toBe('sorted');
  });

  it('leaves label-style ordinals sorting — they read naturally in order', () => {
    const placed = placeAnswer(
      ['13th Amendment', '14th Amendment', '15th Amendment', '19th Amendment'],
      2,
      'q058'
    );
    expect(placed.placement).toBe('sorted');
  });

  it('does not treat a non-integer series as bounded', () => {
    const placed = placeAnswer(['1 mile', '5 miles', '12.5 miles', '25 miles'], 2, 'stlmo-058');
    expect(placed.placement).toBe('sorted');
  });
});

describe('permuting — prose', () => {
  it('permutes and preserves the answer', () => {
    const opts = ['Council-Manager', 'Strong-Mayor', 'Commission', 'Mayor-Council'];
    const placed = placeAnswer(opts, 0, 'sprmo-001');
    expect(placed.placement).toBe('permuted');
    expect(placed.options[placed.correctAnswer]).toBe('Council-Manager');
    expect([...placed.options].sort()).toEqual([...opts].sort());
  });

  it('is deterministic for a given seed, or draft review churns', () => {
    const a = placeAnswer(['W', 'X', 'Y', 'Z'], 0, 'stable-seed');
    const b = placeAnswer(['W', 'X', 'Y', 'Z'], 0, 'stable-seed');
    expect(a.correctAnswer).toBe(b.correctAnswer);
  });
});

describe('refusals — malformed or position-sensitive input is returned untouched', () => {
  it('leaves "all of the above" in place', () => {
    const fixed = ['Red', 'Blue', 'Green', 'All of the above'];
    expect(hasFixedPositionOption(fixed)).toBe(true);
    const placed = placeAnswer(fixed, 3, 's');
    expect(placed.correctAnswer).toBe(3);
    expect(placed.placement).toBe('unchanged');
  });

  it('leaves the wrong option count untouched', () => {
    const three = ['A', 'B', 'C'];
    const placed = placeAnswer(three, 0, 's');
    expect(placed.placement).toBe('unchanged');
    expect(placed.options).toBe(three);
  });

  it('leaves an out-of-range index untouched', () => {
    expect(placeAnswer(['A', 'B', 'C', 'D'], 7, 's').placement).toBe('unchanged');
    expect(placeAnswer(['A', 'B', 'C', 'D'], -1, 's').placement).toBe('unchanged');
  });
});

describe('the invariant that matters most — the answer text never changes', () => {
  const shapes: Array<[string, string[], number]> = [
    ['numeric-series', ['8', '10', '12', '15'], 1],
    ['prose', ['Alpha', 'Beta', 'Gamma', 'Delta'], 0],
    ['mixed-units', ['$500 million', '$3 billion', '$1 billion', '$2 billion'], 0],
    ['prose-dates', ['July 4, 1776', 'June 15, 1780', 'March 4, 1789', 'May 1, 1790'], 1],
    ['label-style', ['13th Amendment', '14th Amendment', '15th Amendment', '19th Amendment'], 2],
    ['bounded', ['1 year', '2 years', '4 years', '6 years'], 1],
  ];

  it.each(shapes)('preserves the answer and the option set for %s', (name, options, correct) => {
    const placed = placeAnswer(options, correct, 'seed-' + name);
    expect(placed.options[placed.correctAnswer]).toBe(options[correct]);
    expect([...placed.options].sort()).toEqual([...options].sort());
  });
});

describe('distribution over a realistic batch', () => {
  it('spreads prose answers across all four positions', () => {
    // 400 questions with pipeline-shaped ids, all arriving at position 0 as the generators
    // produce them. Hash placement is uniform only in expectation, so this asserts a band,
    // not an exact split.
    const counts = [0, 0, 0, 0];
    const N = 400;
    for (let i = 1; i <= N; i++) {
      const id = 'xyz-' + String(i).padStart(3, '0');
      counts[placeAnswer(['One', 'Two', 'Three', 'Four'], 0, id).correctAnswer]++;
    }
    const worst = (100 * Math.max(...counts)) / N;
    expect(worst).toBeLessThan(32);
    expect(counts.every((c) => c > 0)).toBe(true);
  });
});

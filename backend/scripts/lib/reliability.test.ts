import { describe, it, expect } from 'vitest';
import { alphaNominal, wilsonLowerBound, isSevereError, certify, chairCategory, type Unit } from './reliability.js';

/** Coder-major matrix (rows = coders) → unit-major (rows = units), the shape alphaNominal takes. */
const byUnit = (coders: (string | null)[][]): Unit[] =>
  coders[0].map((_, u) => coders.map((c) => c[u]));
const n = null;

describe('alphaNominal — positive controls (spec 3.5: trust nothing until these pass)', () => {
  it('reproduces Krippendorff (2011) "Computing Krippendorff\'s Alpha-Reliability", 4 observers x 12 units, nominal alpha = 0.743', () => {
    const s = (xs: (number | null)[]) => xs.map((x) => (x === null ? null : String(x)));
    const r = alphaNominal(byUnit([
      s([1, 2, 3, 3, 2, 1, 4, 1, 2, n, n, n]),
      s([1, 2, 3, 3, 2, 2, 4, 1, 2, 5, n, 3]),
      s([n, 3, 3, 3, 2, 3, 4, 2, 2, 5, 1, n]),
      s([1, 2, 3, 3, 2, 4, 4, 1, 2, 5, 1, n]),
    ]));
    expect(r.alpha).toBeCloseTo(0.743421052631579, 12);
    expect(r.pairableValues).toBe(40);
  });
  it('reproduces the 3-coder x 15-unit example with missing data, nominal alpha = 0.691', () => {
    const s = (xs: (number | null)[]) => xs.map((x) => (x === null ? null : String(x)));
    const r = alphaNominal(byUnit([
      s([n, n, n, n, n, 3, 4, 1, 2, 1, 1, 3, 3, n, 3]),
      s([1, n, 2, 1, 3, 3, 4, 3, n, n, n, n, n, n, n]),
      s([n, n, 2, 1, 3, 4, 4, n, 2, 1, 1, 3, 3, n, 4]),
    ]));
    expect(r.alpha).toBeCloseTo(0.691358024691358, 12);
    expect(r.pairableValues).toBe(26);
  });
});

describe('alphaNominal — edge cases', () => {
  it('is 1 for perfect agreement across more than one category', () => {
    expect(alphaNominal([['1', '1', '1'], ['4', '4', '4'], ['BLANK', 'BLANK', 'BLANK']]).alpha).toBe(1);
  });
  it('is null (undefined) when every value is the same category — no expected disagreement', () => {
    expect(alphaNominal([['2', '2', '2'], ['2', '2', '2']]).alpha).toBeNull();
  });
  it('ignores units with fewer than two values', () => {
    const r = alphaNominal([['1', null, null], ['1', '1', '1'], ['3', '3', '3']]);
    expect(r.units).toBe(2);
    expect(r.alpha).toBe(1);
  });
  it('treats BLANK as its own nominal category (a 1-vs-BLANK split is a disagreement)', () => {
    expect(alphaNominal([['1', 'BLANK'], ['4', '4'], ['BLANK', 'BLANK']]).alpha).toBeLessThan(1);
  });
});

describe('wilsonLowerBound — the scale in spec 3.3', () => {
  it('50/50 -> 0.929 (passes 0.90)', () => expect(wilsonLowerBound(50, 50)).toBeCloseTo(0.92865, 4));
  it('49/50 -> 0.895 (fails 0.90)', () => expect(wilsonLowerBound(49, 50)).toBeCloseTo(0.89505, 4));
  it('98/100 -> 0.930 (passes)', () => expect(wilsonLowerBound(98, 100)).toBeCloseTo(0.92999, 4));
  it('n = 0 -> 0', () => expect(wilsonLowerBound(0, 0)).toBe(0));
});

describe('isSevereError', () => {
  it('a seated chair where gold is BLANK is severe', () => expect(isSevereError(4, null, false)).toBe(true));
  it('opposite sides of the ladder are severe', () => expect(isSevereError(1, 5, false)).toBe(true));
  it('adjacent chairs on one side are an error but not severe', () => expect(isSevereError(4, 5, false)).toBe(false));
  it('the middle rung is never "the other side"', () => expect(isSevereError(3, 5, false)).toBe(false));
  it('on an off-axis topic every wrong chair is severe', () => expect(isSevereError(4, 5, true)).toBe(true));
  it('a machine BLANK is never severe (it never publishes)', () => expect(isSevereError(null, 3, false)).toBe(false));
  it('agreement is not an error', () => expect(isSevereError(2, 2, false)).toBe(false));
});

describe('certify — spec 3.3', () => {
  const ok = { goldN: 50, m1: 0.85, m2: 0.82, unanimousCorrect: 50, unanimousTotal: 50, severe: 0 };
  it('certifies when all four conditions hold', () => {
    const r = certify(ok);
    expect(r.certified).toBe(true);
    expect(r.reasons).toEqual([]);
  });
  it('names every failed condition', () => {
    const r = certify({ goldN: 49, m1: 0.79, m2: null, unanimousCorrect: 49, unanimousTotal: 50, severe: 1 });
    expect(r.certified).toBe(false);
    expect(r.reasons).toEqual(['gold-n 49 < 50', 'm1 0.790 < 0.80', 'm2 undefined', 'm3 wilson-low 0.895 < 0.90', 'm4 severe 1 > 0']);
  });
});

describe('chairCategory', () => {
  it('maps a blank to BLANK and a chair to its digit', () => {
    expect(chairCategory(null)).toBe('BLANK');
    expect(chairCategory(3)).toBe('3');
  });
});

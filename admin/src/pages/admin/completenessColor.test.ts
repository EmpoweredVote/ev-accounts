import { describe, it, expect } from 'vitest';
import { completenessColor, NOT_STARTED, GAMMA, KNEE } from './completenessColor';

describe('completenessColor', () => {
  it('untracked (null) → not-started grey', () => {
    expect(completenessColor(null)).toBe(NOT_STARTED);
    expect(NOT_STARTED).toBe('#e5e7eb');
  });

  it('0% → pale sage (ramp floor, distinct from grey)', () => {
    expect(completenessColor(0)).toBe('rgb(207, 227, 196)');
  });

  it('100% → yellow (only at fully complete)', () => {
    expect(completenessColor(100)).toBe('rgb(254, 209, 46)');
  });

  it('the gamma knee lands exactly on purple', () => {
    const kneeScore = 100 * Math.pow(KNEE, 1 / GAMMA);
    expect(completenessColor(kneeScore)).toBe('rgb(125, 91, 166)');
  });

  it('distinguishes low scores (gamma expands the low end)', () => {
    expect(completenessColor(4)).not.toBe(completenessColor(30));
    expect(completenessColor(4)).not.toBe(NOT_STARTED);
  });

  it('clamps above 100 to yellow', () => {
    expect(completenessColor(150)).toBe('rgb(254, 209, 46)');
  });
});

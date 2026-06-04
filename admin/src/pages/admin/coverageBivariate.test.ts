import { describe, it, expect } from 'vitest';
import { bucketBreadth, bucketDepth, bivariateColor, PALETTE, NOT_STARTED } from './coverageBivariate';

describe('bucketBreadth (thresholds <0.10 / <0.50 / >=0.50)', () => {
  it('low below 0.10', () => { expect(bucketBreadth(0)).toBe('low'); expect(bucketBreadth(0.099)).toBe('low'); });
  it('med at the 0.10 boundary up to <0.50', () => { expect(bucketBreadth(0.10)).toBe('med'); expect(bucketBreadth(0.499)).toBe('med'); });
  it('high at the 0.50 boundary', () => { expect(bucketBreadth(0.50)).toBe('high'); expect(bucketBreadth(1)).toBe('high'); });
});

describe('bucketDepth (thresholds <33 / <66 / >=66, on 0..100)', () => {
  it('low below 33', () => { expect(bucketDepth(0)).toBe('low'); expect(bucketDepth(32.9)).toBe('low'); });
  it('med at 33 up to <66', () => { expect(bucketDepth(33)).toBe('med'); expect(bucketDepth(65.9)).toBe('med'); });
  it('high at 66', () => { expect(bucketDepth(66)).toBe('high'); expect(bucketDepth(100)).toBe('high'); });
});

describe('bivariateColor — all 9 cells', () => {
  const cases: [number, number, string][] = [
    [0.0, 0,   PALETTE.low.low],
    [0.3, 0,   PALETTE.low.med],
    [0.8, 0,   PALETTE.low.high],
    [0.0, 50,  PALETTE.med.low],
    [0.3, 50,  PALETTE.med.med],
    [0.8, 50,  PALETTE.med.high],
    [0.0, 80,  PALETTE.high.low],
    [0.3, 80,  PALETTE.high.med],
    [0.8, 80,  PALETTE.high.high],
  ];
  it.each(cases)('breadth=%s depth=%s → %s', (b, d, hex) => {
    expect(bivariateColor(b, d)).toBe(hex);
  });
});

describe('bivariateColor — edges', () => {
  it('0 started (breadth 0, depth 0) → the empty near-white cell', () => {
    expect(bivariateColor(0, 0)).toBe('#ece8e0');
  });
  it('exposes the not-started grey separately', () => {
    expect(NOT_STARTED).toBe('#e5e7eb');
  });
});

import { describe, it, expect } from 'vitest';
import { statusBadge, flagReasons, pct, REJECT_REASONS } from './evidenceReviewFormat';
describe('evidenceReviewFormat', () => {
  it('statusBadge maps green/flagged', () => {
    expect(statusBadge('green').kind).toBe('green');
    expect(statusBadge('flagged').kind).toBe('flagged');
  });
  it('flagReasons reads gate_flags.reasons defensively', () => {
    expect(flagReasons({ reasons: ['judge:no-mechanism'] })).toEqual(['judge:no-mechanism']);
    expect(flagReasons(null)).toEqual([]);
  });
  it('pct formats or n/a', () => { expect(pct(0.8)).toBe('0.80'); expect(pct(null)).toBe('n/a'); });
  it('reason enum excludes wrong-tag', () => { expect(REJECT_REASONS).not.toContain('wrong-tag'); });
});

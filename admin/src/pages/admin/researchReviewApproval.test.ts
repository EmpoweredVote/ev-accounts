import { describe, it, expect } from 'vitest';
import { overrideNeedsReasoning } from './researchReviewApproval';

const base = { proposedValue: 3, proposedReasoning: 'supports moderate reform' };

describe('overrideNeedsReasoning', () => {
  it('false when the edited value is not yet valid (null)', () => {
    expect(overrideNeedsReasoning({ ...base, editedValue: null, editedReasoning: '' })).toBe(false);
  });
  it('false when the edited value equals the proposed value, regardless of reasoning', () => {
    expect(overrideNeedsReasoning({ ...base, editedValue: 3, editedReasoning: '' })).toBe(false);
    expect(overrideNeedsReasoning({ ...base, editedValue: 3, editedReasoning: 'supports moderate reform' })).toBe(false);
  });
  it('true when the value changed and the reasoning is blank', () => {
    expect(overrideNeedsReasoning({ ...base, editedValue: 4, editedReasoning: '' })).toBe(true);
    expect(overrideNeedsReasoning({ ...base, editedValue: 4, editedReasoning: '   ' })).toBe(true);
  });
  it('true when the value changed and the reasoning is untouched (equals the proposal, after trim)', () => {
    expect(overrideNeedsReasoning({ ...base, editedValue: 4, editedReasoning: 'supports moderate reform' })).toBe(true);
    expect(overrideNeedsReasoning({ ...base, editedValue: 4, editedReasoning: '  supports moderate reform  ' })).toBe(true);
  });
  it('false when the value changed and the reasoning was genuinely edited', () => {
    expect(overrideNeedsReasoning({ ...base, editedValue: 4, editedReasoning: 'now argues for stronger reform' })).toBe(false);
  });
});

describe('blanks on the review page (CA_0303)', () => {
  it('labels a blank by its reason, never as value 0', async () => {
    const { proposedLabel } = await import('./researchReviewApproval');
    expect(proposedLabel(0, 'direction-only')).toBe('Blank — direction-only');
    expect(proposedLabel(3, null)).toBe('value 3');
    expect(proposedLabel(null, null)).toBeNull();
  });
  it('approves 0 only with one of the six reasons — the queued one, or the reviewer\'s', async () => {
    const { approvableValue } = await import('./researchReviewApproval');
    const blank = { proposedValue: 0, proposedBlankReason: 'no-evidence' };
    expect(approvableValue({ ...blank, editedValue: '0', blankReason: '' })).toEqual({ value: 0, blankReason: 'no-evidence' });
    expect(approvableValue({ proposedValue: 3, proposedBlankReason: null, editedValue: '0', blankReason: '' })).toBeNull();
    expect(approvableValue({ proposedValue: 3, proposedBlankReason: null, editedValue: '0', blankReason: 'adjacent-chairs' }))
      .toEqual({ value: 0, blankReason: 'adjacent-chairs' });
    expect(approvableValue({ ...blank, editedValue: '2', blankReason: '' })).toEqual({ value: 2, blankReason: null });
    expect(approvableValue({ ...blank, editedValue: '6', blankReason: '' })).toBeNull();
  });
});

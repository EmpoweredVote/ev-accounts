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

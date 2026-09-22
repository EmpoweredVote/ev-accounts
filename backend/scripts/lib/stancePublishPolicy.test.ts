import { describe, it, expect } from 'vitest';
import { decidePublish, type PolicyInput } from './stancePublishPolicy.js';
import type { GateFinding } from './stanceGate.js';

const f = (check_id: GateFinding['check_id'], severity: GateFinding['severity']): GateFinding =>
  ({ full_name: 'Jane Doe', topic_key: 'healthcare', check_id, severity, what: '' });
const base: PolicyInput = {
  proposedValue: 2, verifiedSourceCount: 1, threshold: 1, gateFindings: [],
  politicianResolved: true, existingOpenSeasonValue: null,
};

describe('decidePublish', () => {
  it('auto-pushes only a clean, verified, NEW record row', () => {
    expect(decidePublish(base)).toEqual({ action: 'auto-push' });
  });
  it('routes an unresolved politician to review first', () => {
    expect(decidePublish({ ...base, politicianResolved: false, gateFindings: [f('no-source', 'high')] }))
      .toEqual({ action: 'review', reasons: ['unresolved-politician'] });
  });
  it('sends any high gate finding back to research — before the verifier count is even considered', () => {
    expect(decidePublish({ ...base, verifiedSourceCount: 0, gateFindings: [f('party-inference', 'high')] }))
      .toEqual({ action: 're-research', reasons: ['gate-high'] });
  });
  it('sends an unverified row back to research', () => {
    expect(decidePublish({ ...base, verifiedSourceCount: 0 })).toEqual({ action: 're-research', reasons: ['below-threshold'] });
  });
  it('treats a matching open-season value as a no-op', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 2 })).toEqual({ action: 'unchanged' });
  });
  it('never changes an existing open-season value without a human', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 4 })).toEqual({ action: 'review', reasons: ['value-change'] });
  });
  it('treats an editor blank (0) as an existing value — re-seating it is an editor call', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 0 })).toEqual({ action: 'review', reasons: ['value-change'] });
  });
  it('queues statement evidence for review, accumulating other reasons', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 5,
      gateFindings: [f('statement-needs-review', 'medium'), f('level-unknown', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['statement-evidence', 'gate-medium', 'value-change'] });
  });
});

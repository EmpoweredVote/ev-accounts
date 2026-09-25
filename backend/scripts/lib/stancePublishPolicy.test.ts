import { describe, it, expect } from 'vitest';
import { decidePublish, type PolicyInput } from './stancePublishPolicy.js';
import type { GateFinding } from './stanceGate.js';

const f = (check_id: GateFinding['check_id'], severity: GateFinding['severity']): GateFinding =>
  ({ full_name: 'Jane Doe', topic_key: 'healthcare', check_id, severity, what: '' });
// autoPushEnabled: true so the precedence tests below keep asserting what they asserted before
// review-all mode existed; the review-all tests at the end pin the default.
const base: PolicyInput = {
  proposedValue: 2, verifiedSourceCount: 1, threshold: 1, gateFindings: [],
  politicianResolved: true, existingOpenSeasonValue: null, displayedValue: null, autoPushEnabled: true,
};

describe('decidePublish', () => {
  it('auto-pushes only a clean, verified, NEW record row', () => {
    expect(decidePublish(base)).toEqual({ action: 'auto-push' });
  });
  it('routes an unresolved politician to review when that is the only high finding', () => {
    expect(decidePublish({ ...base, politicianResolved: false, gateFindings: [f('unknown-politician', 'high')] }))
      .toEqual({ action: 'review', reasons: ['unresolved-politician'] });
  });
  it('sends an unresolved politician with another high finding back to research, not review', () => {
    expect(decidePublish({ ...base, politicianResolved: false, gateFindings: [f('no-source', 'high')] }))
      .toEqual({ action: 're-research', reasons: ['gate-high'] });
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
  // C43/D3: a scope finding is recorded in its own bucket, not folded into re-research.
  it('routes a topic-out-of-scope finding to out-of-scope, not re-research', () => {
    expect(decidePublish({ ...base, gateFindings: [f('topic-out-of-scope', 'high')] })).toEqual({ action: 'out-of-scope' });
  });
  it('routes to out-of-scope even alongside another high finding', () => {
    expect(decidePublish({ ...base, gateFindings: [f('topic-out-of-scope', 'high'), f('party-inference', 'high')] }))
      .toEqual({ action: 'out-of-scope' });
  });
  it('routes to out-of-scope even when the politician has not resolved', () => {
    expect(decidePublish({ ...base, politicianResolved: false, gateFindings: [f('topic-out-of-scope', 'high')] }))
      .toEqual({ action: 'out-of-scope' });
  });
  it('queues statement evidence for review, accumulating other reasons', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 5,
      gateFindings: [f('statement-needs-review', 'medium'), f('level-unknown', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['statement-evidence', 'gate-medium', 'value-change'] });
  });
});

// Ruling 2026-09-22: nothing auto-publishes until the Plan 2 chair-fit classifier exists.
describe('decidePublish — review-all mode (autoPushEnabled false, the default)', () => {
  const reviewAll: PolicyInput = { ...base, autoPushEnabled: false };
  it('queues a new clean row that would otherwise auto-push, with reason review-all-mode', () => {
    expect(decidePublish(reviewAll)).toEqual({ action: 'review', reasons: ['review-all-mode'] });
  });
  it('auto-pushes the same row only when the run opted in', () => {
    expect(decidePublish({ ...reviewAll, autoPushEnabled: true })).toEqual({ action: 'auto-push' });
  });
  it('leaves every earlier decision unchanged — review-all only replaces auto-push', () => {
    expect(decidePublish({ ...reviewAll, gateFindings: [f('topic-out-of-scope', 'high')] }))
      .toEqual({ action: 'out-of-scope' });
    expect(decidePublish({ ...reviewAll, politicianResolved: false, gateFindings: [f('unknown-politician', 'high')] }))
      .toEqual({ action: 'review', reasons: ['unresolved-politician'] });
    expect(decidePublish({ ...reviewAll, gateFindings: [f('party-inference', 'high')] }))
      .toEqual({ action: 're-research', reasons: ['gate-high'] });
    expect(decidePublish({ ...reviewAll, verifiedSourceCount: 0 })).toEqual({ action: 're-research', reasons: ['below-threshold'] });
    expect(decidePublish({ ...reviewAll, existingOpenSeasonValue: 2 })).toEqual({ action: 'unchanged' });
    expect(decidePublish({ ...reviewAll, existingOpenSeasonValue: 4 })).toEqual({ action: 'review', reasons: ['value-change'] });
    expect(decidePublish({ ...reviewAll, gateFindings: [f('statement-needs-review', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['statement-evidence'] });
    expect(decidePublish({ ...reviewAll, gateFindings: [f('level-unknown', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['gate-medium'] });
  });
});

// Ruling 2026-09-24: a row that would change what voters see now always goes to a person.
describe('decidePublish — replaces-published-chair', () => {
  it('an S1 chair shown as the fallback (no S2 row), proposing a different value → review, even with --auto-push', () => {
    for (const autoPushEnabled of [true, false]) {
      expect(decidePublish({ ...base, autoPushEnabled, existingOpenSeasonValue: null, displayedValue: 4 }))
        .toEqual({ action: 'review', reasons: ['replaces-published-chair'] });
    }
  });
  it('an S1 blank (0) shown as the fallback counts as a published chair too', () => {
    expect(decidePublish({ ...base, displayedValue: 0 })).toEqual({ action: 'review', reasons: ['replaces-published-chair'] });
  });
  // Decision (documented in stancePublishPolicy.ts): the same chair as the S1 fallback is NOT
  // `unchanged`. No S2 row exists, so the write creates one — new reasoning and citations, judged
  // against S2's served text — and that row replaces what voters see. A person approves the carry.
  it('the SAME value as the S1 fallback → review with replaces-published-chair, not unchanged', () => {
    expect(decidePublish({ ...base, proposedValue: 4, displayedValue: 4 }))
      .toEqual({ action: 'review', reasons: ['replaces-published-chair'] });
  });
  it('a matching OPEN-season value stays unchanged (displayed equals it)', () => {
    expect(decidePublish({ ...base, proposedValue: 4, existingOpenSeasonValue: 4, displayedValue: 4 }))
      .toEqual({ action: 'unchanged' });
  });
  it('a different OPEN-season value keeps value-change and adds nothing else', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 4, displayedValue: 4 }))
      .toEqual({ action: 'review', reasons: ['value-change'] });
  });
  it('no displayed value → the behaviour before the ruling', () => {
    expect(decidePublish({ ...base, displayedValue: null })).toEqual({ action: 'auto-push' });
    expect(decidePublish({ ...base, displayedValue: null, autoPushEnabled: false }))
      .toEqual({ action: 'review', reasons: ['review-all-mode'] });
  });
  it('combines with other review reasons, and gate-high still wins', () => {
    expect(decidePublish({ ...base, displayedValue: 3, gateFindings: [f('statement-needs-review', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['statement-evidence', 'replaces-published-chair'] });
    expect(decidePublish({ ...base, displayedValue: 3, gateFindings: [f('no-source', 'high')] }))
      .toEqual({ action: 're-research', reasons: ['gate-high'] });
  });
});

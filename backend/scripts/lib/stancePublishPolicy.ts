/**
 * stancePublishPolicy — the one place that decides whether a researched stance may be written
 * without a human. Pure and tested, so an unattended (scheduled) run makes exactly the decision
 * an interactive one does.
 *
 * Only a NEW, record-evidenced, gate-clean, page-verified row auto-publishes. Everything else is
 * either sent back to research (defective) or queued for a person (inform.stance_research_review).
 */
import type { GateFinding } from './stanceGate.js';

export type ReviewReason = 'unresolved-politician' | 'statement-evidence' | 'gate-medium' | 'value-change';
export type ReReason = 'gate-high' | 'below-threshold';
export type Decision =
  | { action: 'auto-push' }
  | { action: 'unchanged' }
  | { action: 'review'; reasons: ReviewReason[] }
  | { action: 're-research'; reasons: ReReason[] };

export interface PolicyInput {
  proposedValue: number;
  verifiedSourceCount: number;
  threshold: number;
  gateFindings: GateFinding[];
  politicianResolved: boolean;
  /** Value already stored in the OPEN season; null = none. A 0 is an editor's blank and counts. */
  existingOpenSeasonValue: number | null;
}

export function decidePublish(i: PolicyInput): Decision {
  if (!i.politicianResolved) {
    // Unresolved → review, so a person can link the right record — but only when that is ALL
    // that is wrong. Any other high finding means the research itself is defective, and an
    // unresolved-politician review queue is not the place to fix a bad citation or a party
    // inference (ruling 2026-09-22, R2).
    const otherHigh = i.gateFindings.some((f) => f.severity === 'high' && f.check_id !== 'unknown-politician');
    return otherHigh ? { action: 're-research', reasons: ['gate-high'] } : { action: 'review', reasons: ['unresolved-politician'] };
  }
  if (i.gateFindings.some((f) => f.severity === 'high')) return { action: 're-research', reasons: ['gate-high'] };
  if (i.verifiedSourceCount < i.threshold) return { action: 're-research', reasons: ['below-threshold'] };
  if (i.existingOpenSeasonValue !== null && i.existingOpenSeasonValue === i.proposedValue) return { action: 'unchanged' };

  const reasons: ReviewReason[] = [];
  if (i.gateFindings.some((f) => f.check_id === 'statement-needs-review')) reasons.push('statement-evidence');
  if (i.gateFindings.some((f) => f.severity === 'medium' && f.check_id !== 'statement-needs-review')) reasons.push('gate-medium');
  // 🔴 A value already in the open season is never changed without a human — including a 0 (blank).
  if (i.existingOpenSeasonValue !== null) reasons.push('value-change');
  return reasons.length ? { action: 'review', reasons } : { action: 'auto-push' };
}

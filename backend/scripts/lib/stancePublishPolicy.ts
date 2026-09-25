/**
 * stancePublishPolicy — the one place that decides whether a researched stance may be written
 * without a human. Pure and tested, so an unattended (scheduled) run makes exactly the decision
 * an interactive one does.
 *
 * Only a NEW, record-evidenced, gate-clean, page-verified row CAN auto-publish — and even that row
 * goes to a person unless the run opted in with `autoPushEnabled` (verify-stance-research.ts
 * `--auto-push`). Everything else is either sent back to research (defective) or queued for a
 * person (inform.stance_research_review).
 *
 * Review-all is the default (ruling 2026-09-22, "nothing auto-publishes"): the gate proves a row
 * cites a real page and names an instrument, but nothing yet proves the evidence fits the CHAIR
 * rather than just the direction. Until the Plan 2 chair-fit classifier exists, a person approves
 * every stance — and those decisions are the labeled set that classifier is trained and measured on.
 */
import type { GateFinding } from './stanceGate.js';

export type ReviewReason =
  | 'unresolved-politician' | 'statement-evidence' | 'gate-medium' | 'value-change' | 'review-all-mode'
  | 'replaces-published-chair';
export type ReReason = 'gate-high' | 'below-threshold';
export type Decision =
  | { action: 'auto-push' }
  | { action: 'unchanged' }
  | { action: 'review'; reasons: ReviewReason[] }
  | { action: 're-research'; reasons: ReReason[] }
  // C43/D3: a scope finding is not a research defect — re-researching the same (person, topic) pair
  // cannot fix it, because the office simply does not hold this question. Recorded, never re-queued.
  | { action: 'out-of-scope' };

export interface PolicyInput {
  proposedValue: number;
  verifiedSourceCount: number;
  threshold: number;
  gateFindings: GateFinding[];
  politicianResolved: boolean;
  /** Value already stored in the OPEN season; null = none. A 0 is an editor's blank and counts. */
  existingOpenSeasonValue: number | null;
  /**
   * What VOTERS SEE for this pair now (ruling 2026-09-24): the newest PUBLISHED season's answer,
   * null when there is none or the open season does not ask the topic — the same resolution as the
   * review page's "Voters see now" (seasonService.DISPLAYED_VALUES_SQL). A 0 is a blank and counts.
   * With an open-season value it equals that value; without one it is an older season's chair
   * (the Season 1 fallback) that a write here would replace.
   */
  displayedValue: number | null;
  /**
   * The run explicitly opted in to unattended publishing (`--auto-push`). False = review-all: a row
   * that would otherwise auto-push is queued with reason 'review-all-mode'. Never read from an env
   * var — it must be a deliberate per-run choice.
   */
  autoPushEnabled: boolean;
}

export function decidePublish(i: PolicyInput): Decision {
  // C43/D3: checked first and unconditionally. A scope finding means the OFFICE does not hold this
  // question — not that the evidence is bad — so it is never folded into the generic gate-high
  // re-research bucket (which invites re-queuing the same pair) and never blocked on the politician
  // resolving first (an out-of-scope topic is out of scope whether or not the person is known).
  if (i.gateFindings.some((f) => f.check_id === 'topic-out-of-scope')) return { action: 'out-of-scope' };
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
  // Ruling 2026-09-24: a row that would change what voters see now is never written without a
  // person, even with --auto-push. With no open-season value, a displayed value can only be an
  // older season's chair (or blank) shown as the fallback — and the write REPLACES it, because the
  // new open-season row wins the read path's newest-season collapse, bringing new reasoning and
  // citations with it. That holds even when the proposed chair EQUALS the displayed one: the S1 row
  // was evidenced against S1's ladder, and carrying it into S2 is a new claim against S2's served
  // text, so a same-value carry is `review`, not `unchanged` (`unchanged` is kept for a matching
  // OPEN-season value, where nothing voters see would move).
  const replacesFallback = i.existingOpenSeasonValue === null && i.displayedValue !== null;

  const reasons: ReviewReason[] = [];
  if (i.gateFindings.some((f) => f.check_id === 'statement-needs-review')) reasons.push('statement-evidence');
  if (i.gateFindings.some((f) => f.severity === 'medium' && f.check_id !== 'statement-needs-review')) reasons.push('gate-medium');
  // 🔴 A value already in the open season is never changed without a human — including a 0 (blank).
  if (i.existingOpenSeasonValue !== null) reasons.push('value-change');
  if (replacesFallback) reasons.push('replaces-published-chair');
  if (reasons.length) return { action: 'review', reasons };
  // Every check passed. Review-all (the default) still sends it to a person — see the header.
  return i.autoPushEnabled ? { action: 'auto-push' } : { action: 'review', reasons: ['review-all-mode'] };
}

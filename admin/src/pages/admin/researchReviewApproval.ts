/**
 * Pure approval-gate logic for the research-review detail page (task 5, requirement 3), mirroring
 * the server rule in researchEvidenceService.ts#resolveResearchReview: a valueOverride that
 * differs from the proposed value must carry a reasoningOverride that is present and different
 * from the proposed reasoning. This only saves the round trip — the server enforces the same rule
 * (422 INCOMPLETE) regardless of what the UI disables.
 */

export interface OverrideReasoningCheck {
  proposedValue: number | null;
  proposedReasoning: string;
  /** The parsed numeric value currently in the Value field, or null when it is blank/invalid. */
  editedValue: number | null;
  editedReasoning: string;
}

/**
 * true = the edited value differs from the proposal and the reasoning has not been changed to
 * explain it — Approve should be disabled with a reason. false = no override in play (the value
 * matches the proposal, or is not yet a valid 1-5), or the reasoning was genuinely edited.
 */
export function overrideNeedsReasoning(args: OverrideReasoningCheck): boolean {
  const { proposedValue, proposedReasoning, editedValue, editedReasoning } = args;
  if (editedValue === null || editedValue === proposedValue) return false;
  const trimmed = editedReasoning.trim();
  return trimmed === '' || trimmed === proposedReasoning.trim();
}

/**
 * Codebook V6's six blank reasons — a copy of backend/src/lib/blankReasons.ts (the admin app does
 * not import backend code). Keep the two in step; the server refuses any other reason (422).
 */
export const BLANK_REASONS = ['no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable'] as const;

/**
 * How a proposed value reads to a reviewer (spec 2026-10-07-season2-blank-review-design.md §3.5):
 * a chair as "value N", a blank (0) as "Blank — <reason>", never as "value 0".
 */
export function proposedLabel(proposedValue: number | null, proposedBlankReason: string | null | undefined): string | null {
  if (proposedValue === null) return null;
  if (proposedValue === 0) return `Blank — ${proposedBlankReason || 'reason not recorded'}`;
  return `value ${proposedValue}`;
}

/**
 * The value the Approve button may send, mirroring the server: a chair 1-5, or 0 (a blank) that
 * carries a reason — the reviewer's choice, or the queued blank's own. null = not approvable yet.
 */
export function approvableValue(args: {
  editedValue: string; proposedValue: number | null; proposedBlankReason: string | null | undefined; blankReason: string;
}): { value: number; blankReason: string | null } | null {
  const v = Number(args.editedValue);
  if (args.editedValue.trim() === '' || !Number.isInteger(v) || v < 0 || v > 5) return null;
  if (v !== 0) return { value: v, blankReason: null };
  const reason = args.blankReason || (args.proposedValue === 0 ? args.proposedBlankReason ?? '' : '');
  return (BLANK_REASONS as readonly string[]).includes(reason) ? { value: 0, blankReason: reason } : null;
}

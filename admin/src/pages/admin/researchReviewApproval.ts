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

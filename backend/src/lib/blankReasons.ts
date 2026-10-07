/**
 * Codebook V6's six blank reasons — why no chair fits. One list for the coder label validator
 * (scripts/lib/coderLabel.ts), the stance gate, review-queue approval, and the CA_0303 CHECK on
 * inform.stance_research_review.proposed_blank_reason (keep that CHECK in step with this list).
 */
export const BLANK_REASONS = ['no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable'] as const;
export type BlankReason = typeof BLANK_REASONS[number];
export const isBlankReason = (s: unknown): s is BlankReason =>
  typeof s === 'string' && (BLANK_REASONS as readonly string[]).includes(s);

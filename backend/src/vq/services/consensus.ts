/**
 * consensus.ts
 * Pure consensus determination algorithm — no I/O, no database calls.
 *
 * Takes structured input (pre-fetched submission data) and returns a result
 * object describing the consensus state. Fully unit-testable without mocks.
 *
 * Algorithm stages (in order):
 *   1. Filter eligible submissions (credibilityScore >= 40)
 *   2. Check minimum submission count (< 4 → pending)
 *   3. Group submissions by normalized answer via answersMatch
 *   4. Compute answer distribution and find top answer group
 *   5. Check human participation floor (< 40% human among 5+ total → needs_more_human_verification)
 *   6. Check conflicting state (13+ total, < 85% alignment → conflicting)
 *   7. Determine confidence level (high / moderate / low / pending)
 *   8. Check bridging diversity (only when alignment meets a threshold)
 *   9. Return resolved result with correct/incorrect submission ID split
 */

import { answersMatch } from './normalization.js';

// ============================================================
// CONSENSUS THRESHOLDS
// ============================================================

export const CONSENSUS_THRESHOLDS = {
  HIGH: { min_submissions: 7, min_alignment: 85 },
  MODERATE: { min_submissions: 5, min_alignment: 80 },
  LOW: { min_submissions: 4, min_alignment: 75 },
  CONFLICT_THRESHOLD: 13,
  HUMAN_FLOOR: 0.40,
  HUMAN_FLOOR_MIN_TOTAL: 5,
} as const;

// ============================================================
// CREDIBILITY DELTAS
// Per CONTEXT.md: asymmetric deltas — wrong answers cost more than correct earn.
// INCORRECT_IGNORED: -15 (harshest; user did nothing)
// INCORRECT_ACKNOWLEDGED: -8 (~50% of ignored; user engaged with feedback)
// INCORRECT_CONTESTED: 0 (contested with evidence; outcome uncertain; no penalty)
// ============================================================

export const CREDIBILITY_DELTAS = {
  CORRECT: 5,
  INCORRECT_IGNORED: -15,
  INCORRECT_ACKNOWLEDGED: -8,
  INCORRECT_CONTESTED: 0,
} as const;

// ============================================================
// INPUT TYPES
// ============================================================

export interface ConsensusSubmission {
  id: string;
  userId: string;
  normalizedAnswer: string;
  submitterType: 'human_connected' | 'human_empowered' | 'ai_agent';
  credibilityScore: number;   // from user_veracity_profiles; quarantine threshold < 40
  accuracyRate: number | null; // from user_veracity_profiles; null for new users (treated as mid band)
  createdAt: string;           // ISO 8601
}

export interface ConsensusInput {
  questId: string;
  questType: 'official' | 'fact' | 'policy';
  bridgingWaived: boolean;  // admin escape hatch — skip bridging diversity check when true
  submissions: ConsensusSubmission[];
}

// ============================================================
// RESULT TYPES
// ============================================================

export type ConsensusResultType =
  | {
      status: 'pending';
      reason: string;
    }
  | {
      status: 'needs_more_human_verification';
      reason: string;
      humanCount: number;
      totalCount: number;
      humanPercentage: number;
    }
  | {
      status: 'bridging_failed';
      reason: string;
    }
  | {
      status: 'resolved';
      consensusAnswer: string;
      confidenceLevel: 'high' | 'moderate' | 'low';
      totalSubmissions: number;
      alignmentPercentage: number;
      humanCount: number;
      aiCount: number;
      humanPercentage: number;
      answerDistribution: Record<string, number>;
      correctSubmissionIds: string[];
      incorrectSubmissionIds: string[];
    }
  | {
      status: 'conflicting';
      totalSubmissions: number;
      alignmentPercentage: number;
      answerDistribution: Record<string, number>;
      humanCount: number;
      aiCount: number;
      humanPercentage: number;
    };

// ============================================================
// INTERNAL HELPERS
// ============================================================

/**
 * Accuracy band for bridging diversity check.
 * - high: accuracyRate >= 80
 * - mid: accuracyRate >= 40 && < 80, OR null (new users default to mid)
 * - low: accuracyRate < 40
 */
type AccuracyBand = 'high' | 'mid' | 'low';

function getAccuracyBand(accuracyRate: number | null): AccuracyBand {
  if (accuracyRate === null) return 'mid';
  if (accuracyRate >= 80) return 'high';
  if (accuracyRate >= 40) return 'mid';
  return 'low';
}

interface AnswerGroup {
  representativeAnswer: string; // the normalized answer string for this group
  submissionIds: string[];       // IDs of all submissions in this group
}

/**
 * Group eligible submissions by normalized answer using answersMatch.
 *
 * Strategy: iterate submissions in order. For each submission, check if its
 * normalizedAnswer matches any existing group's representative via answersMatch.
 * If yes, add to that group. If no, create a new group. This is O(n*g) where g
 * is the number of distinct answer groups — acceptable for the small n expected
 * in consensus evaluation (< 200 submissions per quest).
 */
function groupByAnswer(submissions: ConsensusSubmission[]): AnswerGroup[] {
  const groups: AnswerGroup[] = [];

  for (const submission of submissions) {
    let matched = false;
    for (const group of groups) {
      if (answersMatch(submission.normalizedAnswer, group.representativeAnswer)) {
        group.submissionIds.push(submission.id);
        matched = true;
        break;
      }
    }
    if (!matched) {
      groups.push({
        representativeAnswer: submission.normalizedAnswer,
        submissionIds: [submission.id],
      });
    }
  }

  return groups;
}

/**
 * Build answer distribution map from groups.
 * Keys are the representative normalized answer strings; values are counts.
 */
function buildDistribution(groups: AnswerGroup[]): Record<string, number> {
  const dist: Record<string, number> = {};
  for (const group of groups) {
    dist[group.representativeAnswer] = group.submissionIds.length;
  }
  return dist;
}

// ============================================================
// MAIN ALGORITHM
// ============================================================

/**
 * computeConsensus — pure consensus determination function.
 *
 * Takes pre-fetched submission data and returns a ConsensusResultType.
 * No I/O, no side effects. Safe to call in unit tests without any mocks.
 */
export function computeConsensus(input: ConsensusInput): ConsensusResultType {
  const { bridgingWaived, submissions } = input;

  // --------------------------------------------------------
  // Stage 1: Filter eligible submissions
  // Credibility score >= 40 is the quarantine threshold per CONTEXT.md.
  // Quarantined submissions are stored but excluded from consensus math.
  // --------------------------------------------------------
  const eligible = submissions.filter((s) => s.credibilityScore >= 40);
  const totalEligible = eligible.length;

  // --------------------------------------------------------
  // Stage 2: Check minimum submission count
  // Lowest threshold (LOW) requires 4 submissions.
  // --------------------------------------------------------
  if (totalEligible < CONSENSUS_THRESHOLDS.LOW.min_submissions) {
    return {
      status: 'pending',
      reason: `Insufficient eligible submissions (${totalEligible})`,
    };
  }

  // --------------------------------------------------------
  // Stage 3: Group by normalized answer
  // --------------------------------------------------------
  const groups = groupByAnswer(eligible);

  // Find top answer group (largest count)
  const topGroup = groups.reduce((best, g) =>
    g.submissionIds.length > best.submissionIds.length ? g : best
  );
  const topGroupCount = topGroup.submissionIds.length;

  // --------------------------------------------------------
  // Stage 4: Compute alignment percentage and distribution
  // --------------------------------------------------------
  const alignmentPercentage = (topGroupCount / totalEligible) * 100;
  const answerDistribution = buildDistribution(groups);

  // --------------------------------------------------------
  // Stage 5: Count human vs AI participation
  // --------------------------------------------------------
  const humanCount = eligible.filter((s) => s.submitterType !== 'ai_agent').length;
  const aiCount = totalEligible - humanCount;
  const humanPercentage = totalEligible > 0 ? (humanCount / totalEligible) * 100 : 0;

  // --------------------------------------------------------
  // Stage 6: Check human participation floor
  // If 5+ total eligible and < 40% are human → needs_more_human_verification
  // --------------------------------------------------------
  if (
    totalEligible >= CONSENSUS_THRESHOLDS.HUMAN_FLOOR_MIN_TOTAL &&
    humanCount / totalEligible < CONSENSUS_THRESHOLDS.HUMAN_FLOOR
  ) {
    return {
      status: 'needs_more_human_verification',
      reason: `Human participation ${humanPercentage.toFixed(1)}% is below the 40% minimum floor`,
      humanCount,
      totalCount: totalEligible,
      humanPercentage,
    };
  }

  // --------------------------------------------------------
  // Stage 7: Check conflicting state
  // 13+ total eligible submissions with < 85% alignment → conflicting
  // --------------------------------------------------------
  if (
    totalEligible >= CONSENSUS_THRESHOLDS.CONFLICT_THRESHOLD &&
    alignmentPercentage < CONSENSUS_THRESHOLDS.HIGH.min_alignment
  ) {
    return {
      status: 'conflicting',
      totalSubmissions: totalEligible,
      alignmentPercentage,
      answerDistribution,
      humanCount,
      aiCount,
      humanPercentage,
    };
  }

  // --------------------------------------------------------
  // Stage 8: Determine confidence level
  // Check thresholds highest → lowest.
  // Must be checked BEFORE bridging: if alignment doesn't meet any threshold
  // we return pending regardless of bridging — no point checking diversity.
  // --------------------------------------------------------
  let confidenceLevel: 'high' | 'moderate' | 'low' | null = null;

  if (
    totalEligible >= CONSENSUS_THRESHOLDS.HIGH.min_submissions &&
    alignmentPercentage >= CONSENSUS_THRESHOLDS.HIGH.min_alignment
  ) {
    confidenceLevel = 'high';
  } else if (
    totalEligible >= CONSENSUS_THRESHOLDS.MODERATE.min_submissions &&
    alignmentPercentage >= CONSENSUS_THRESHOLDS.MODERATE.min_alignment
  ) {
    confidenceLevel = 'moderate';
  } else if (
    totalEligible >= CONSENSUS_THRESHOLDS.LOW.min_submissions &&
    alignmentPercentage >= CONSENSUS_THRESHOLDS.LOW.min_alignment
  ) {
    confidenceLevel = 'low';
  }

  if (!confidenceLevel) {
    return {
      status: 'pending',
      reason: `Alignment ${alignmentPercentage.toFixed(1)}% does not meet any confidence threshold with ${totalEligible} eligible submissions`,
    };
  }

  // --------------------------------------------------------
  // Stage 9: Bridging diversity check (CONSENSUS-05)
  //
  // Purpose: prevent a homogeneous cluster from locking in the wrong answer.
  // Only runs after we confirm alignment meets a threshold — if it didn't we
  // already returned pending above. Bridging on a non-qualifying set is moot.
  //
  // Check: among top-answer submitters, how many distinct accuracy bands are
  // represented? If only 1 band AND bridgingWaived is false AND top group
  // has >= 3 submitters → block consensus.
  //
  // Accuracy bands:
  //   high: accuracyRate >= 80
  //   mid:  accuracyRate >= 40 && < 80, OR null (new users)
  //   low:  accuracyRate < 40
  //
  // Not enforced when top group < 3 (too few people to form a faction).
  // --------------------------------------------------------
  if (!bridgingWaived && topGroup.submissionIds.length >= 3) {
    const topGroupSubmissions = eligible.filter((s) =>
      topGroup.submissionIds.includes(s.id)
    );
    const bands = new Set(topGroupSubmissions.map((s) => getAccuracyBand(s.accuracyRate)));

    if (bands.size === 1) {
      return {
        status: 'bridging_failed',
        reason:
          `All ${topGroup.submissionIds.length} top-answer submitters are in the ` +
          `same accuracy band (${[...bands][0]}). Consensus blocked pending diverse participation.`,
      };
    }
  }

  // --------------------------------------------------------
  // Stage 10: Build resolved result
  // Split submission IDs: top group → correct; all others → incorrect
  // --------------------------------------------------------
  const topGroupIdSet = new Set(topGroup.submissionIds);
  const correctSubmissionIds = eligible
    .filter((s) => topGroupIdSet.has(s.id))
    .map((s) => s.id);
  const incorrectSubmissionIds = eligible
    .filter((s) => !topGroupIdSet.has(s.id))
    .map((s) => s.id);

  return {
    status: 'resolved',
    consensusAnswer: topGroup.representativeAnswer,
    confidenceLevel,
    totalSubmissions: totalEligible,
    alignmentPercentage,
    humanCount,
    aiCount,
    humanPercentage,
    answerDistribution,
    correctSubmissionIds,
    incorrectSubmissionIds,
  };
}

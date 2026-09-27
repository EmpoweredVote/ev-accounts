/**
 * Quality Gate — the judgement half of the nightly pipeline's rules check.
 *
 * `wnews-0134` asked what year a past event happened and offered 2026 as an
 * option. The rule that catches that existed in `services/qualityRules`;
 * nothing in the nightly pipeline ever called it. This module holds the
 * decision that closes the gap, deliberately free of the database and of the
 * Anthropic client so it can be tested for nothing — the same move
 * `skipReasonFor()` made in `pipelineCron.ts`.
 *
 * ROLLOUT: enforcement is OFF by default. The rules always run and every
 * violation is counted; only the refusal to write is flagged. Chris's stated
 * preference at decision time was to log first and enforce after observing a
 * night or two, because the engine has never been pointed at news-shaped
 * content and its false-positive rate there is unknown — `checkPureLookup`
 * flags "in what year was..." shapes, which is a perfectly ordinary news
 * question.
 *
 * `suppressed` is the number that rollout turns on: questions that WOULD have
 * been blocked and were written anyway. Read it before flipping the flag.
 */

import type { Violation } from '../../services/qualityRules/types.js';

/** Set to the exact string "true" to make blocking violations actually block. */
export const QUALITY_RULES_ENFORCE_ENV = 'TRIVIA_QUALITY_RULES_ENFORCE';

/** Cap on the per-run sample list written into generation_jobs.notes. */
export const MAX_SAMPLES = 20;

/**
 * Whether blocking violations block.
 *
 * Read per question rather than captured at module load: a flag you cannot
 * flip without a redeploy is not a flagged rollout, and a module-level const
 * would make tests that set the variable assert against a stale value.
 */
export function qualityRulesEnforced(env: NodeJS.ProcessEnv = process.env): boolean {
  return env[QUALITY_RULES_ENFORCE_ENV] === 'true';
}

export interface QualityRuleStats {
  /** Questions the engine successfully evaluated. */
  audited: number;
  /** Of those, how many carried at least one blocking violation. */
  withBlocking: number;
  /** Of those, how many carried violations but none blocking. */
  withAdvisoryOnly: number;
  /** Questions the gate actually refused to write (enforcement ON). */
  blocked: number;
  /** Questions that WOULD have been refused had enforcement been on
   *  (enforcement OFF). The cost of switching the flag on, measured in advance.
   *  Counted at the gate, so a suppressed question that then loses its insert
   *  to an external_id conflict is still counted here. */
  suppressed: number;
  /** Questions whose audit threw. Contained, never propagated. */
  ruleErrors: number;
  /** Questions written WITHOUT a usable verdict, because their audit threw.
   *  These are counted in neither `audited` nor any violation tally, so
   *  `written <= audited` is NOT an invariant — this is the third outcome. */
  writtenUnaudited: number;
  /** Violation tally by rule name, blocking and advisory alike. */
  byRule: Record<string, number>;
  /** `externalId:rule` (or `externalId:ERROR:message`) for the first
   *  MAX_SAMPLES offenders, so a bad night is diagnosable and not merely
   *  countable — the reason `blockReasons` exists next to `blocked`. */
  samples: string[];
}

export function emptyQualityRuleStats(): QualityRuleStats {
  return {
    audited: 0,
    withBlocking: 0,
    withAdvisoryOnly: 0,
    blocked: 0,
    suppressed: 0,
    ruleErrors: 0,
    writtenUnaudited: 0,
    byRule: {},
    samples: [],
  };
}

export interface GateDecision {
  /** False only when enforcement is on AND a blocking violation was found. */
  write: boolean;
  blocking: Violation[];
  advisory: Violation[];
}

export function decideRuleGate(violations: Violation[], enforce: boolean): GateDecision {
  const blocking = violations.filter(v => v.severity === 'blocking');
  const advisory = violations.filter(v => v.severity !== 'blocking');
  return {
    write: !(enforce && blocking.length > 0),
    blocking,
    advisory,
  };
}

function pushSample(stats: QualityRuleStats, sample: string): void {
  if (stats.samples.length < MAX_SAMPLES) stats.samples.push(sample);
}

export function recordGate(
  stats: QualityRuleStats,
  externalId: string,
  decision: GateDecision,
  enforce: boolean,
): void {
  stats.audited++;

  for (const v of [...decision.blocking, ...decision.advisory]) {
    stats.byRule[v.rule] = (stats.byRule[v.rule] ?? 0) + 1;
  }

  if (decision.blocking.length > 0) {
    stats.withBlocking++;
    if (enforce) stats.blocked++;
    else stats.suppressed++;
    pushSample(stats, `${externalId}:${decision.blocking[0].rule}`);
  } else if (decision.advisory.length > 0) {
    stats.withAdvisoryOnly++;
  }
}

export function recordRuleError(
  stats: QualityRuleStats,
  externalId: string,
  err: unknown,
): void {
  stats.ruleErrors++;
  const message = err instanceof Error ? err.message : String(err);
  pushSample(stats, `${externalId}:ERROR:${message.slice(0, 120)}`);
}

/**
 * Whether this claim should be fingerprinted in the dedup ledger.
 *
 * run-pipeline records a fingerprint after writing, and that suppresses the
 * story for CLAIM_WINDOW_DAYS = 14. Its comment promises that a claim whose
 * candidates were ALL rejected is deliberately NOT remembered, so a transient
 * failure cannot bury a story permanently.
 *
 * That promise held while the model's own quality gate was the last filter
 * before the write. It stops holding once the rules engine runs INSIDE the
 * write path: `written` can be empty purely because this gate refused. The
 * news prompt generates a single question for a straightforward claim, so one
 * blocking violation would otherwise cost the story a fortnight.
 *
 * An empty `written` with nothing blocked is the original benign case — every
 * insert hit an external_id conflict, which means the content is already there.
 */
export function shouldRecordClaim(writtenCount: number, stats: QualityRuleStats): boolean {
  return writtenCount > 0 || stats.blocked === 0;
}

/** Record a question written without a verdict, because its audit threw. */
export function recordWrittenUnaudited(stats: QualityRuleStats): void {
  stats.writtenUnaudited++;
}

/** Fold `from` into `into`. `from` is left untouched. */
export function mergeQualityRuleStats(into: QualityRuleStats, from: QualityRuleStats): void {
  into.audited += from.audited;
  into.withBlocking += from.withBlocking;
  into.withAdvisoryOnly += from.withAdvisoryOnly;
  into.blocked += from.blocked;
  into.suppressed += from.suppressed;
  into.ruleErrors += from.ruleErrors;
  into.writtenUnaudited += from.writtenUnaudited;
  for (const [rule, n] of Object.entries(from.byRule)) {
    into.byRule[rule] = (into.byRule[rule] ?? 0) + n;
  }
  for (const s of from.samples) pushSample(into, s);
}

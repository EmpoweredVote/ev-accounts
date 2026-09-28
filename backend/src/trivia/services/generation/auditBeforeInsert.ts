/**
 * The quality gate for the two officeholder generators.
 *
 * ev-accounts #816 put the rules engine on the news pipeline's write path and
 * nothing else. `replacementGenerator` was fixed separately. That left
 * `CurrentTermQuestionGenerator` and `ElectionQuestionGenerator` inserting
 * straight into `trivia.questions` with no rule ever consulted — the same
 * defect at two more addresses.
 *
 * Both generators write `status: 'draft'`, so nothing they produce reaches a
 * player until it is activated. That lowers the urgency; it does not remove the
 * defect. A question with simultaneously-true options is just as wrong the day
 * someone activates it, and by then the generation run that produced it is long
 * gone and nobody is looking at it.
 *
 * This lives in one place because the two call sites are otherwise identical.
 * Two copies of a gate is how the copies drift, which is the failure this whole
 * workstream keeps running into.
 */

import { auditQuestion } from '../qualityRules/index.js';
import type { QuestionInput, Violation } from '../qualityRules/types.js';
import {
  qualityRulesEnforcement,
  decideRuleGate,
  enforcedRuleNames,
} from '../../scripts/international/qualityGate.js';

export interface AuditBeforeInsertResult {
  /** False only when a blocking violation came from an ENFORCED rule. */
  write: boolean;
  /** Every blocking violation, enforced or not. */
  blocking: Violation[];
  /** The blocking violations whose rules enforce. Empty when `write` is true. */
  enforced: Violation[];
  /** True when the audit itself threw. The question is written regardless. */
  errored: boolean;
}

/**
 * Audit a PLACED question and decide whether to insert it.
 *
 * Call this AFTER `placeAnswer` and before the insert. The engine must judge the
 * question that actually gets stored: `placeAnswer` moves the correct answer off
 * index 0, and a rule that reads `correctAnswer` would otherwise be judging a
 * question that never existed.
 *
 * `skipUrlCheck` is not an optimisation. `checkLearnMoreLink` fetches
 * `source.url` and raises a BLOCKING violation on any non-timeout failure, so
 * leaving it on would put an HTTP round trip inside the generation loop and make
 * the verdict depend on network weather.
 *
 * Enforcement is per rule and shared with the nightly pipeline — see
 * TRIVIA_QUALITY_RULES_ENFORCE. Rules that are not enforced still run, and their
 * violations are still logged; they simply do not refuse the write.
 */
export async function auditBeforeInsert(
  question: QuestionInput,
): Promise<AuditBeforeInsertResult> {
  const enforcement = qualityRulesEnforcement();

  let violations: Violation[];
  try {
    const audit = await auditQuestion(question, { skipUrlCheck: true });
    violations = audit.violations;
  } catch (err) {
    // A rule that throws is our defect. Refusing to write would turn a bug in
    // the engine into silent content loss, which is strictly worse than the
    // unaudited question — so log it loudly and let the insert proceed.
    const message = err instanceof Error ? err.message : String(err);
    console.warn(
      `  [QualityRules] audit THREW for ${question.externalId} — writing unaudited — ${message}`,
    );
    return { write: true, blocking: [], enforced: [], errored: true };
  }

  const decision = decideRuleGate(violations, enforcement);

  if (decision.blocking.length > 0) {
    const all = decision.blocking.map(v => v.rule).join(', ');
    const verdict = decision.enforced.length > 0
      ? `BLOCKED (${decision.enforced.map(v => v.rule).join(', ')})`
      : `WOULD BLOCK (enforcing ${enforcedRuleNames().join(',') || 'nothing'})`;
    console.log(
      `  [QualityRules] ${verdict} ${question.externalId} — ${all} — "${question.text.slice(0, 60)}"`,
    );
    for (const v of decision.enforced) {
      if (v.evidence) console.log(`      ${v.evidence}`);
    }
  }

  return {
    write: decision.write,
    blocking: decision.blocking,
    enforced: decision.enforced,
    errored: false,
  };
}

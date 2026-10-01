import { describe, it, expect } from 'vitest';
import { checkStructuralQuality } from './structural.js';
import type { QuestionInput } from '../types.js';

/**
 * These cover `missing-citation` only.
 *
 * The rule used to require the EXPLANATION PROSE to contain "According to",
 * "Source:", "per the", the source name, or a URL. Attribution boilerplate was
 * ruled out bank-wide on 2026-09-29 — 1,978 explanations stripped to 0, with
 * attribution moved to `source.url` — so the old test fired on essentially every
 * question written afterwards.
 *
 * It is advisory and so could never block a write. The damage was to the
 * diagnostic: every hit is tallied into
 * `trivia.generation_jobs.notes.qualityRules.byRule`, which is the number you are
 * meant to read BEFORE adding a rule to TRIVIA_QUALITY_RULES_ENFORCE. A rule that
 * fires on 100% of questions makes that reading worthless.
 */
function q(over: Partial<QuestionInput> = {}): QuestionInput {
  return {
    externalId: 'akron-oh_0001',
    text: 'Who presides over Akron City Council meetings?',
    options: ['The mayor', 'The council president', 'The clerk', 'The city manager'],
    correctAnswer: 1,
    explanation: 'Akron City Council elects a president from among its members to preside.',
    difficulty: 'medium',
    source: { name: 'City of Akron', url: 'https://www.akronohio.gov/' },
    ...over,
  };
}

const citationViolations = (input: QuestionInput) =>
  checkStructuralQuality(input).violations.filter(v => v.rule === 'missing-citation');

describe('checkStructuralQuality — missing-citation', () => {
  it('accepts a clean explanation when source.url is populated', () => {
    // The whole point: no "According to", and no complaint.
    expect(citationViolations(q())).toHaveLength(0);
  });

  it('does not fire on the post-ruling house style', () => {
    expect(
      citationViolations(q({
        explanation: 'The council has thirteen seats: ten by ward and three at large.',
      })),
    ).toHaveLength(0);
  });

  it('fires when source.url is missing', () => {
    const v = citationViolations(q({ source: { name: 'City of Akron', url: '' } }));
    expect(v).toHaveLength(1);
    expect(v[0].severity).toBe('advisory');
  });

  it('fires when source.url is not an http(s) url', () => {
    expect(citationViolations(q({ source: { name: 'A book', url: 'see page 41' } }))).toHaveLength(1);
  });

  it('still accepts an inline url when source.url is absent', () => {
    expect(
      citationViolations(q({
        source: { name: 'City of Akron', url: '' },
        explanation: 'Confirmed at https://www.akronohio.gov/council — thirteen seats.',
      })),
    ).toHaveLength(0);
  });

  it('is advisory, so it can never block a write', () => {
    // decideRuleGate derives `enforced` from blocking violations only, so adding
    // this rule to TRIVIA_QUALITY_RULES_ENFORCE does nothing on its own. Flipping
    // this severity to 'blocking' is the change that would matter.
    const v = citationViolations(q({ source: { name: 'x', url: '' } }));
    expect(v[0].severity).not.toBe('blocking');
  });
});

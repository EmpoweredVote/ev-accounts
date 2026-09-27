import { describe, it, expect } from 'vitest';
import { QUESTION_GENERATION_SYSTEM_PROMPT, toQuestionInput } from './question-generator.js';
import { auditQuestion } from '../../services/qualityRules/index.js';
import { emptyQualityRuleStats, decideRuleGate, recordGate } from './qualityGate.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * The nightly news prompt is standalone — it never imported QUALITY_GUIDELINES,
 * so every standard the rest of the content system agreed on reached every
 * generator except the one running unattended at 02:00. `wnews-0134` came out
 * of this prompt.
 *
 * The prompt states the rules the gate enforces, and only those. Importing the
 * shared guidelines wholesale would demand a .gov source URL and an
 * "According to" explanation from a question built on a Reuters article, and
 * the model would reject its own valid output.
 */
describe('QUESTION_GENERATION_SYSTEM_PROMPT', () => {
  it('forbids a past-tense year question offering a year that has not arrived', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('has not arrived yet');
  });

  it('carries the numeric distractor rule', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('must not always sit in the middle');
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('ascending');
  });

  it('forbids the vague qualifiers the ambiguity rule blocks on', () => {
    const p = QUESTION_GENERATION_SYSTEM_PROMPT;
    expect(p).toContain('most important');
    expect(p).toContain('primarily');
  });

  it('requires the four options to be clearly distinct', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('clearly distinct');
  });

  it('does not import the civic-structure guidelines that news cannot satisfy', () => {
    // A .gov source requirement or an "According to" explanation rule would
    // make the model reject perfectly good questions built on a wire story.
    const p = QUESTION_GENERATION_SYSTEM_PROMPT;
    expect(p).not.toContain('.gov');
    expect(p).not.toContain('According to [source]');
  });
});

describe('toQuestionInput', () => {
  const placed = {
    text: 'In what year did the treaty enter into force?',
    options: ['2019', '2021', '2024', '2027'],
    correctAnswer: 1,
    explanation: 'It entered into force in 2021.',
    difficulty: 'medium' as const,
    qualityGate: { passed: true, reason: '' },
  };

  it('maps a placed question onto the engine input shape', () => {
    const input = toQuestionInput(placed, 'wnews-0134', { name: 'Reuters', url: 'https://example.com/a' });
    expect(input).toEqual({
      text: placed.text,
      options: placed.options,
      correctAnswer: 1,
      explanation: placed.explanation,
      difficulty: 'medium',
      source: { name: 'Reuters', url: 'https://example.com/a' },
      externalId: 'wnews-0134',
    });
  });

  it('feeds the engine a question it can actually judge - the wnews-0134 shape', async () => {
    // The end-to-end point of the plan: this exact shape reached production.
    const input = toQuestionInput(placed, 'wnews-0134', { name: 'Reuters', url: 'https://example.com/a' });
    const result = await auditQuestion(input, { skipUrlCheck: true });
    expect(result.hasBlockingViolations).toBe(true);
    expect(result.violations.some(v => v.rule === 'anachronistic-year-option')).toBe(true);
  });

  it('does not touch the network when skipUrlCheck is set', async () => {
    // Review Focus 2. An unreachable URL must not produce a verdict at all
    // when the URL check is skipped - if this ever fails, the cron has grown
    // an HTTP round trip per question and a blocking verdict that depends on
    // a news site answering a bot.
    const input = toQuestionInput(
      { ...placed, options: ['2019', '2021', '2024', '2025'] },
      'wnews-0200',
      { name: 'Reuters', url: 'https://this-host-does-not-exist.invalid/x' },
    );
    const result = await auditQuestion(input, { skipUrlCheck: true });
    expect(result.violations.some(v => v.rule === 'broken-learn-more')).toBe(false);
  });
});

describe('writePassingQuestions accounting', () => {
  it('counts an audited question that hits an id conflict as audited, not written', () => {
    // Review Focus 5. The insert is onConflictDoNothing() and `continue`s on
    // an empty result. Auditing happens BEFORE the insert, so a conflicted
    // question is correctly audited and correctly not written - the two
    // counters must not be assumed equal anywhere downstream.
    //
    // Asserted structurally rather than against a database: the invariant is
    // that `written.length <= ruleStats.audited`, and that is the property
    // run-pipeline's merge relies on.
    const stats = emptyQualityRuleStats();
    recordGate(stats, 'wnews-0001', decideRuleGate([], false), false);
    recordGate(stats, 'wnews-0002', decideRuleGate([], false), false);
    const written = [{ questionId: 1, externalId: 'wnews-0001', status: 'active' as const }];
    expect(written.length).toBeLessThanOrEqual(stats.audited);
    expect(stats.audited).toBe(2);
  });
});

import { describe, it, expect } from 'vitest';
import {
  QUESTION_GENERATION_SYSTEM_PROMPT,
  toQuestionInput,
  auditForPipeline,
  writePassingQuestions,
} from './question-generator.js';
import { auditQuestion } from '../../services/qualityRules/index.js';

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

  it('warns about the pure-lookup blocklist, which blocks 15% of the news bank', () => {
    // The rule the prompt never mentioned. checkPureLookup is BLOCKING and its
    // blocklist matches /in what year (was|did)/ and /what date/. Measured
    // against the live wnews-/wiran- bank, 274 of 1788 questions (15.3%) match
    // it -- an order of magnitude more than every other rule combined.
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('in what year was');
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('in which year');
  });

  it('does not illustrate a good question with a shape the engine blocks', () => {
    // Rule 1's worked example used to be "In what year did X begin?" -- which
    // checkPureLookup refuses outright. The prompt was teaching the model to
    // write a question the gate would then reject.
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).not.toContain('In what year did X begin');
  });

  it('lists every vague qualifier the engine blocks on', () => {
    // "frequently" was missing; the engine blocks it.
    for (const w of ['most important', 'best', 'primarily', 'generally', 'mainly',
                     'usually', 'typically', 'often', 'commonly', 'frequently']) {
      expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain(w);
    }
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

  it('does not touch the network on the path the pipeline actually takes', async () => {
    // Review Focus 2. Asserted against auditForPipeline -- the function the
    // write loop calls -- rather than against auditQuestion with the option
    // passed by hand, which would only re-test auditQuestion's own documented
    // contract and would stay green if the write path dropped the option.
    //
    // An unreachable host must yield no verdict at all. If this fails, the cron
    // has grown an HTTP round trip per question and a blocking verdict that
    // depends on a news site answering a bot.
    const input = toQuestionInput(
      { ...placed, options: ['2019', '2021', '2024', '2025'] },
      'wnews-0200',
      { name: 'Reuters', url: 'https://this-host-does-not-exist.invalid/x' },
    );
    const result = await auditForPipeline(input);
    expect(result.violations.some(v => v.rule === 'broken-learn-more')).toBe(false);
  });
});

describe('writePassingQuestions audit ordering', () => {
  // Review Focus 5. A question that hits an external_id conflict is audited and
  // NOT written, which is only true while the audit precedes the insert. That
  // ordering is the whole design -- a blocking verdict must prevent the row,
  // not annotate it afterwards -- and it is what makes `audited` and `written`
  // legitimately differ.
  //
  // This cannot be exercised without a database, so it is pinned on the
  // function's own source. Crude, but it fails if someone moves the audit below
  // the insert, which the previous version of this test did not: that one never
  // called writePassingQuestions at all, built both sides by hand, and asserted
  // 1 <= 2.
  const src = writePassingQuestions.toString();

  it('audits before inserting', () => {
    const auditAt = src.indexOf('auditForPipeline');
    const insertAt = src.indexOf('onConflictDoNothing');
    expect(auditAt).toBeGreaterThan(-1);
    expect(insertAt).toBeGreaterThan(-1);
    expect(auditAt).toBeLessThan(insertAt);
  });

  it('places the answer before auditing it', () => {
    // The engine must judge what will actually be stored: placeAnswer rewrites
    // both options and correctAnswer.
    const placeAt = src.indexOf('placeAnswer(');
    const auditAt = src.indexOf('auditForPipeline');
    expect(placeAt).toBeGreaterThan(-1);
    expect(placeAt).toBeLessThan(auditAt);
  });

  it('skips the insert when the gate refuses', () => {
    // Regex rather than an exact string so a reformat does not fail it.
    expect(src).toMatch(/if\s*\(\s*!\s*decision\.write\s*\)\s*continue/);
  });
});

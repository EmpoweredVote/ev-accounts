import { describe, it, expect } from 'vitest';
import { QUESTION_GENERATION_SYSTEM_PROMPT } from './question-generator.js';

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

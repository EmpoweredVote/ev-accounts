import { describe, it, expect } from 'vitest';
import { QuestionSchema, ATTRIBUTION_OPENER } from './question-schema.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * Explanations are not allowed to open with "According to ..." — attribution belongs in
 * `source.url`, and the opener is noise the player reads past. That was ruled on 2026-09-29,
 * when 1,978 explanations were rewritten to remove it.
 *
 * The sweep was DATA ONLY. It relaxed the structural rule and deleted the schema refine that
 * had REQUIRED the opener, but left every prompt still ordering it — "Every explanation MUST
 * begin with: 'According to [source name], ...'". So the generator kept obeying the old rule:
 * a run on 2026-10-02 produced 8 of 8 with the opener, three days after the ruling, and nobody
 * noticed until those questions were read one at a time two weeks later.
 *
 * The prompts are fixed. This is the half that does not depend on the model complying, and
 * these tests are what stop the refine being quietly dropped again the next time it is
 * inconvenient.
 *
 * The anchoring matters as much as the ban. "according to" mid-sentence is ordinary English
 * and must pass, or the rule becomes something the next person argues with instead of keeps.
 */
describe('explanation attribution opener', () => {
  const valid = {
    externalId: 'tst-001',
    text: 'How many members serve on the city council?',
    options: ['Five', 'Seven', 'Nine', 'Eleven'],
    correctAnswer: 2,
    difficulty: 'easy' as const,
    topicCategory: 'city-government',
    source: { name: 'City of Bloomington', url: 'https://bloomington.in.gov/council' },
    expiresAt: null,
  };
  const parse = (explanation: string) => QuestionSchema.safeParse({ ...valid, explanation });

  it('rejects the opener the bank was swept clear of', () => {
    expect(parse('According to bloomington.in.gov, the council has nine members.').success)
      .toBe(false);
  });

  it('rejects it whatever the case or leading whitespace', () => {
    expect(parse('  according to the city charter, the council has nine members.').success)
      .toBe(false);
  });

  it('rejects the other attribution openers, not just that one phrase', () => {
    expect(parse('Per the city charter, the council has nine members in total.').success)
      .toBe(false);
    expect(parse('Source: the city charter. The council has nine members.').success)
      .toBe(false);
    expect(parse('As reported by the Herald-Times, the council has nine members.').success)
      .toBe(false);
  });

  it('ACCEPTS "according to" mid-sentence, which is ordinary English', () => {
    // The whole reason the pattern is anchored. A rule that fires here would be a false
    // positive on a correct explanation, and false positives are how rules get switched off.
    expect(parse('The filing deadline depends on the county, according to state law.').success)
      .toBe(true);
  });

  it('accepts an explanation that opens with the fact', () => {
    expect(parse("The council has nine members, six elected by district and three at large.").success)
      .toBe(true);
  });

  it('does not reject a word that merely starts with "per"', () => {
    // `per\s` and not `per` — otherwise "Personnel decisions rest with the manager" fails.
    expect(parse('Personnel decisions rest with the city manager under the charter.').success)
      .toBe(true);
    expect(ATTRIBUTION_OPENER.test('Permits are issued by the planning department here.'))
      .toBe(false);
  });

  it('still enforces the length bounds it always did', () => {
    expect(parse('Too short.').success).toBe(false);
    expect(parse('x'.repeat(501)).success).toBe(false);
  });
});

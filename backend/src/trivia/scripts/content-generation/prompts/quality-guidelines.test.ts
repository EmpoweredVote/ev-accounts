import { describe, it, expect } from 'vitest';
import { QUALITY_GUIDELINES } from './quality-guidelines.js';
import { buildSystemPrompt } from './system-prompt.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * This file exists in two repos. CTC's copy grew a §6a on numeric distractors;
 * ev-accounts' copy did not — and ev-accounts is the engine that generates
 * nightly content, so the standard that mattered was the one that lacked it.
 * The divergence was measurable in the data: across 1,154 four-option numeric
 * questions the correct value sat third of four 54% of the time.
 *
 * These assertions are a tripwire, not a spellcheck. If a future edit drops
 * §6a again, this fails rather than the next content audit finding it.
 */
describe('QUALITY_GUIDELINES', () => {
  it('carries §6a, the numeric distractor rule', () => {
    expect(QUALITY_GUIDELINES).toContain('### 6a. Numeric distractors');
  });

  it('tells the writer to vary which bracket the answer falls in', () => {
    expect(QUALITY_GUIDELINES).toContain('must NOT always sit in the middle');
  });

  it('forbids moving the correct value to achieve placement', () => {
    expect(QUALITY_GUIDELINES).toContain('Never move the correct value');
  });

  it('requires one unit per question and ascending order', () => {
    expect(QUALITY_GUIDELINES).toContain('One unit per question');
    expect(QUALITY_GUIDELINES).toContain('Order them ascending');
  });

  it('keeps position rotation and distractor choice as separate concerns', () => {
    // A reviewer who conflates these will "fix" the 54% figure by shuffling
    // A/B/C/D, which does nothing — a player who sorts the numbers mentally is
    // unaffected by position.
    expect(QUALITY_GUIDELINES).toContain('does not fix this');
  });
});

/**
 * WHY THIS EXISTS
 * ---------------
 * The prompt used to say "Easy: 40% / Medium: 40% / Hard: 20%" and define the
 * tiers by nothing at all. A percentage alone never worked: measured across the
 * live bank, questions labelled easy are answered correctly 50.0% of the time —
 * identical to medium, and only 25 points above blind guessing.
 *
 * The revised rubric classifies by what the player must BRING, sets 30% easy as
 * a floor rather than a target, and adds the distractor rule, which is the part
 * that actually moves the number.
 */
describe('buildSystemPrompt — difficulty rubric', () => {
  // Signature: (localeName, topicDistribution, localeSlug?, officeholders?)
  // The slug is what selects the Fremont calibration block, so it must be passed.
  const prompt = () => buildSystemPrompt('Fremont, CA', { 'local-government': 10 }, 'fremont-ca');

  it('states the easy floor, not a 40% target', () => {
    expect(prompt()).toContain('At least 30% of the batch must be EASY');
    expect(prompt()).not.toContain('Easy: 40% of questions');
  });

  it('classifies by what the player must bring', () => {
    const p = prompt();
    expect(p).toContain('someone who lives there would likely know it without study');
    expect(p).toContain('needs specific study');
  });

  it('restricts easy officeholders to the headline executive', () => {
    expect(prompt()).toContain('named holders of any office below the headline');
  });

  it('carries the distractor rule, with the measured figure', () => {
    const p = prompt();
    expect(p).toContain("An easy question's three distractors must be ones a resident rules out instantly");
    expect(p).toContain('50.0%');
  });

  it('does not leave a locale block contradicting the floor', () => {
    // The Fremont calibration carried its own "Target: 40% easy". One locale
    // quietly exempting itself from the floor is how the floor stops meaning
    // anything.
    expect(prompt()).not.toContain('Target: 40% easy');
  });
});

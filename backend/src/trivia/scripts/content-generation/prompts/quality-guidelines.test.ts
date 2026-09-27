import { describe, it, expect } from 'vitest';
import { QUALITY_GUIDELINES } from './quality-guidelines.js';

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

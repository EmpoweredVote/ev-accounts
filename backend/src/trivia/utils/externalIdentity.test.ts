import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  mintForConfig,
  mintExternalId,
  collectionKeyOf,
  isLegacyExternalId,
  NEW_EXTERNAL_ID_RE,
  LEGACY_EXTERNAL_ID_RE,
  nextSequence,
} from './externalIdentity.js';
import { QuestionSchema } from '../scripts/content-generation/question-schema.js';

const VALID_QUESTION = {
  externalId: 'akron-oh_0001',
  text: 'Who presides over Akron City Council meetings?',
  options: ['The mayor', 'The council president', 'The clerk', 'The city manager'],
  correctAnswer: 1,
  explanation:
    'Akron City Council elects a president from among its members, who presides over its meetings.',
  difficulty: 'medium',
  topicCategory: 'city-government',
  source: { name: 'City of Akron', url: 'https://www.akronohio.gov/' },
  expiresAt: null,
};

describe('mintExternalId', () => {
  it('pads the sequence to four digits', () => {
    expect(mintExternalId('akron-oh', 1)).toBe('akron-oh_0001');
    expect(mintExternalId('akron-oh', 42)).toBe('akron-oh_0042');
    expect(mintExternalId('akron-oh', 9999)).toBe('akron-oh_9999');
  });

  // Review Focus 2: rollover must widen, never truncate.
  it('widens past four digits rather than truncating', () => {
    expect(mintExternalId('akron-oh', 10000)).toBe('akron-oh_10000');
  });

  it('rejects a slug containing an underscore', () => {
    expect(() => mintExternalId('akron_oh', 1)).toThrow(/underscore/i);
  });

  it('rejects a non-positive sequence', () => {
    expect(() => mintExternalId('akron-oh', 0)).toThrow(/positive/i);
  });
});

describe('collectionKeyOf', () => {
  it('returns the slug for a new-scheme id', () => {
    expect(collectionKeyOf('akron-oh_0001')).toBe('akron-oh');
    expect(collectionKeyOf('bainbridge-island-wa_0107')).toBe('bainbridge-island-wa');
  });

  // Review Focus 3: legacy ids must still yield their prefix.
  it('returns the prefix for a legacy id', () => {
    expect(collectionKeyOf('ins-049')).toBe('ins');
    expect(collectionKeyOf('pla-172')).toBe('pla');
    expect(collectionKeyOf('wiran-1761')).toBe('wiran');
  });

  it('returns the whole string for an id with no separator', () => {
    expect(collectionKeyOf('q001')).toBe('q001');
  });

  // Review Focus 1: a slug containing digits must not confuse the split.
  it('handles a slug containing digits', () => {
    expect(collectionKeyOf('route-66-ca_0001')).toBe('route-66-ca');
  });
});

describe('isLegacyExternalId', () => {
  it('classifies both schemes', () => {
    expect(isLegacyExternalId('ins-049')).toBe(true);
    expect(isLegacyExternalId('q001')).toBe(true);
    expect(isLegacyExternalId('akron-oh_0001')).toBe(false);
  });
});

describe('regexes', () => {
  it('NEW matches slug ids only', () => {
    expect(NEW_EXTERNAL_ID_RE.test('akron-oh_0001')).toBe(true);
    expect(NEW_EXTERNAL_ID_RE.test('route-66-ca_0001')).toBe(true);
    expect(NEW_EXTERNAL_ID_RE.test('ins-049')).toBe(false);
  });

  it('LEGACY matches three- and four-digit prefix ids', () => {
    expect(LEGACY_EXTERNAL_ID_RE.test('ins-049')).toBe(true);
    expect(LEGACY_EXTERNAL_ID_RE.test('wiran-1761')).toBe(true);
    expect(LEGACY_EXTERNAL_ID_RE.test('akron-oh_0001')).toBe(false);
  });

  it('matches a widened id, so the minter and the validator agree', () => {
    expect(NEW_EXTERNAL_ID_RE.test(mintExternalId('akron-oh', 10000))).toBe(true);
    expect(NEW_EXTERNAL_ID_RE.test('akron-oh_123456')).toBe(true);
  });

  it('still rejects an under-padded sequence', () => {
    expect(NEW_EXTERNAL_ID_RE.test('akron-oh_1')).toBe(false);
    expect(NEW_EXTERNAL_ID_RE.test('akron-oh_001')).toBe(false);
  });
});

describe('nextSequence', () => {
  it('starts at 1 when the collection is empty', () => {
    expect(nextSequence(null)).toBe(1);
    expect(nextSequence(undefined)).toBe(1);
  });

  it('continues from the highest existing sequence', () => {
    expect(nextSequence('673')).toBe(674);
    expect(nextSequence(673)).toBe(674);
  });

  it('treats an unparseable max as empty', () => {
    expect(nextSequence('not-a-number')).toBe(1);
  });

  it('treats zero and negative maxima as empty', () => {
    expect(nextSequence(0)).toBe(1);
    expect(nextSequence(-5)).toBe(1);
  });
});

describe('QuestionSchema externalId', () => {
  it('accepts a slug-derived id', () => {
    expect(QuestionSchema.safeParse(VALID_QUESTION).success).toBe(true);
  });

  it('accepts legacy three- and four-digit ids', () => {
    for (const id of ['ins-049', 'pla-172', 'wiran-1761', 'climc-0092']) {
      const r = QuestionSchema.safeParse({ ...VALID_QUESTION, externalId: id });
      expect(r.success, `${id} should be accepted`).toBe(true);
    }
  });

  it('rejects a malformed id', () => {
    for (const id of ['AKRON-OH_0001', 'akron-oh_1', 'akron-oh-0001', '_0001']) {
      const r = QuestionSchema.safeParse({ ...VALID_QUESTION, externalId: id });
      expect(r.success, `${id} should be rejected`).toBe(false);
    }
  });

  it('accepts bare federal ids, which have no separator', () => {
    for (const id of ['q001', 'q047', 'q161']) {
      const r = QuestionSchema.safeParse({ ...VALID_QUESTION, externalId: id });
      expect(r.success, `${id} should be accepted`).toBe(true);
    }
  });
});

describe('QuestionSchema explanation', () => {
  // Chris ruled attribution boilerplate out bank-wide on 2026-09-29: 1,978
  // explanations opening "According to ..." were stripped to 0. The validator
  // still REQUIRED that phrase, so every newly generated question would have
  // reintroduced it. Attribution belongs in source.url.
  it('accepts an explanation with no "According to" boilerplate', () => {
    expect(QuestionSchema.safeParse(VALID_QUESTION).success).toBe(true);
  });

  it('still requires a source url', () => {
    const { source, ...withoutSource } = VALID_QUESTION;
    expect(QuestionSchema.safeParse(withoutSource).success).toBe(false);
  });
});

/**
 * WHY THIS EXISTS (Controller Ruling 22)
 * ---------------------------------------
 * The rule "legacy mints THREE digits in the cron and locale generators, FOUR
 * in the international generators, and these must never be unified" is
 * enforced only by five hand-copied, module-private `mintFor` implementations
 * plus a comment. An earlier version of this test pinned a LOCAL reimplementation
 * of those helpers (its own inline `padStart(3, '0')` / `padStart(4, '0')`) —
 * which pins the test's own copy, not production. If someone DRYs the five
 * `mintFor` copies tomorrow and unifies the padding width, that test would stay
 * green while the invariant it existed to protect silently broke. A pinning
 * test that cannot fail is worthless.
 *
 * Fixed the same way replacementGenerator.test.ts pins the module-private
 * config-detection guard in this same directory tree: read the REAL, current
 * source text, extract the exact prefixed-branch expression verbatim, and
 * evaluate it with `new Function` (never `eval`, and only ever against
 * literal test inputs defined in this file) rather than hand-copying it. This
 * proves the CURRENT code, as written, produces the pinned width, and it
 * fails exactly if either site's padStart width changes.
 *
 * Only these two ev-accounts sites are pinned here:
 *   - THREE-digit: src/trivia/cron/replacementGenerator.ts, mintFor()
 *   - FOUR-digit:  src/trivia/scripts/international/question-generator.ts
 * The three hand-copied CTC-side copies (backend/src/scripts/content-generation
 * in the CTC repo: locale, state, and the replacement-generator equivalent)
 * cannot be pinned from here — that repo has no test runner. Coverage of the
 * width invariant is therefore partial; a change made only on that side is
 * still untested until it is carried over, same as the rule already noted for
 * nested-options.
 */
describe('legacy mint WIDTH at the real call sites', () => {
  // The widths used to be five hand-copied `padStart(3|4, '0')` expressions,
  // pinned here by extracting them from source. They are now an argument to
  // mintForConfig, so the risk moved: nobody can "unify the widths" any more,
  // but someone can still change the number passed at a call site.
  //
  // So this pins the ARGUMENTS instead. mintForConfig's own behaviour is tested
  // directly below; this only asserts each caller asks for the width its
  // collection's existing ids actually use.
  const REPLACEMENT_GENERATOR_SRC = readFileSync(
    fileURLToPath(new URL('../cron/replacementGenerator.ts', import.meta.url)),
    'utf-8',
  );
  const INTL_QUESTION_GENERATOR_SRC = readFileSync(
    fileURLToPath(new URL('../scripts/international/question-generator.ts', import.meta.url)),
    'utf-8',
  );

  it('the replacement cron takes the THREE-digit default', () => {
    const call = REPLACEMENT_GENERATOR_SRC.match(/return mintForConfig\(([^)]*)\);/);
    expect(call, 'mintForConfig call not found — did the cron stop using it?').not.toBeNull();
    // No third argument means the default of 3. An explicit 4 here would mint
    // `bli-0007` where the database holds `bli-007`.
    expect(call![1]).not.toMatch(/,\s*4\s*$/);
  });

  it('the international generator asks for FOUR digits explicitly', () => {
    const call = INTL_QUESTION_GENERATOR_SRC.match(/mintForConfig\(\s*\{[^}]*\},\s*nextIdNum,\s*(\d)\s*,?\s*\)/);
    expect(call, 'mintForConfig call not found — did the generator stop using it?').not.toBeNull();
    expect(call![1]).toBe('4');
  });

  it('the two widths still differ, so neither caller can be "tidied" into the other', () => {
    const legacy = { externalIdPrefix: 'bli', collectionSlug: 'bloomington-in' };
    expect(mintForConfig(legacy, 7, 3)).toBe('bli-007');
    expect(mintForConfig(legacy, 7, 4)).toBe('bli-0007');
  });
});

describe('mintForConfig', () => {
  it('mints the three-digit legacy shape by default', () => {
    const legacy = { externalIdPrefix: 'bli', collectionSlug: 'bloomington-in' };
    expect(mintForConfig(legacy, 7)).toBe('bli-007');
    expect(mintForConfig(legacy, 146)).toBe('bli-146');
  });

  it('mints the four-digit legacy shape when asked', () => {
    const legacy = { externalIdPrefix: 'wiran', collectionSlug: 'war-in-iran' };
    expect(mintForConfig(legacy, 7, 4)).toBe('wiran-0007');
    expect(mintForConfig(legacy, 1761, 4)).toBe('wiran-1761');
  });

  it('the two widths are genuinely different and must stay that way', () => {
    const legacy = { externalIdPrefix: 'bli', collectionSlug: 'bloomington-in' };
    expect(mintForConfig(legacy, 7, 3)).not.toBe(mintForConfig(legacy, 7, 4));
  });

  it('falls through to the slug scheme when no prefix is present, at either width', () => {
    const modern = { collectionSlug: 'akron-oh' };
    expect(mintForConfig(modern, 1)).toBe('akron-oh_0001');
    expect(mintForConfig(modern, 1, 4)).toBe('akron-oh_0001');
  });

  it('treats an empty-string prefix as absent, matching the truthiness branch', () => {
    expect(mintForConfig({ externalIdPrefix: '', collectionSlug: 'akron-oh' }, 1)).toBe('akron-oh_0001');
  });
});

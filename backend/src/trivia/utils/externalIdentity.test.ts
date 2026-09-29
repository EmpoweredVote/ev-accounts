import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
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
describe('legacy mint shape (pinned against the REAL mintFor sites — Controller Ruling 22)', () => {
  const REPLACEMENT_GENERATOR_SRC = readFileSync(
    fileURLToPath(new URL('../cron/replacementGenerator.ts', import.meta.url)),
    'utf-8',
  );
  const INTL_QUESTION_GENERATOR_SRC = readFileSync(
    fileURLToPath(new URL('../scripts/international/question-generator.ts', import.meta.url)),
    'utf-8',
  );

  // Anchored on `if (config.externalIdPrefix) {` — mintFor()'s own guard —
  // so this can only ever match its prefixed-branch return, never an
  // unrelated template literal elsewhere in the file.
  const MINT_3_RE = /if \(config\.externalIdPrefix\) \{[\s\S]*?return (`[\s\S]*?`);/;
  // Anchored on `const externalId = externalIdPrefix` — unique in this file —
  // so this can only ever match this ternary's truthy branch.
  const MINT_4_RE = /const externalId = externalIdPrefix[\s\S]*?\?\s*(`[\s\S]*?`)[\s\S]*?:\s*mintExternalId/;

  const mint3Match = REPLACEMENT_GENERATOR_SRC.match(MINT_3_RE);
  const mint4Match = INTL_QUESTION_GENERATOR_SRC.match(MINT_4_RE);

  it('the three-digit expression is present and extractable from replacementGenerator.ts', () => {
    // Guards against this whole suite going vacuously green if a refactor
    // changes the code's shape enough that MINT_3_RE stops matching anything.
    expect(mint3Match).not.toBeNull();
  });

  it('the four-digit expression is present and extractable from question-generator.ts', () => {
    expect(mint4Match).not.toBeNull();
  });

  let mintPrefixed3: (config: { externalIdPrefix?: string }, seq: number) => string;
  let mintPrefixed4: (externalIdPrefix: string | undefined, nextIdNum: number) => string;

  beforeAll(() => {
    if (!mint3Match) {
      throw new Error(
        'mintFor() three-digit branch not found in replacementGenerator.ts -- ' +
          'update MINT_3_RE in externalIdentity.test.ts to match the current source.',
      );
    }
    if (!mint4Match) {
      throw new Error(
        'question-generator.ts four-digit branch not found -- update MINT_4_RE ' +
          'in externalIdentity.test.ts to match the current source.',
      );
    }
    // eslint-disable-next-line no-new-func -- deliberately evaluating the
    // exact expression extracted from the real source above, not a
    // hand-copied duplicate of it.
    mintPrefixed3 = new Function(
      'config',
      'seq',
      `return ${mint3Match[1]};`,
    ) as (config: { externalIdPrefix?: string }, seq: number) => string;
    // eslint-disable-next-line no-new-func
    mintPrefixed4 = new Function(
      'externalIdPrefix',
      'nextIdNum',
      `return ${mint4Match[1]};`,
    ) as (externalIdPrefix: string | undefined, nextIdNum: number) => string;
  });

  it('mints the three-digit legacy shape when a prefix is present (real replacementGenerator.ts code)', () => {
    expect(mintPrefixed3({ externalIdPrefix: 'bli' }, 7)).toBe('bli-007');
    expect(mintPrefixed3({ externalIdPrefix: 'bli' }, 146)).toBe('bli-146');
  });

  it('mints the four-digit legacy shape for the international generator (real question-generator.ts code)', () => {
    // A small seq is the width-sensitive case: 1761 is 4 digits regardless of
    // whether padStart's width argument is 3 or 4, so it alone would not
    // catch a regression to 3. 7 does — 'wiran-007' vs 'wiran-0007'.
    expect(mintPrefixed4('wiran', 7)).toBe('wiran-0007');
    expect(mintPrefixed4('wiran', 1761)).toBe('wiran-1761');
  });

  it('the two widths are still deliberately different (the invariant this suite protects)', () => {
    expect(mintPrefixed3({ externalIdPrefix: 'bli' }, 7)).not.toBe(mintPrefixed4('bli', 7));
    expect(mintPrefixed3({ externalIdPrefix: 'bli' }, 7)).toBe('bli-007');
    expect(mintPrefixed4('bli', 7)).toBe('bli-0007');
  });

  it('the slug-scheme fallback (mintExternalId, shared and already covered above) is unaffected by either width', () => {
    expect(mintExternalId('akron-oh', 1)).toBe('akron-oh_0001');
  });
});

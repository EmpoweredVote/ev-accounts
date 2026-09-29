import { describe, it, expect } from 'vitest';
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

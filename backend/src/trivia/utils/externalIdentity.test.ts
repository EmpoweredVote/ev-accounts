import { describe, it, expect } from 'vitest';
import {
  mintExternalId,
  collectionKeyOf,
  isLegacyExternalId,
  NEW_EXTERNAL_ID_RE,
  LEGACY_EXTERNAL_ID_RE,
  nextSequence,
} from './externalIdentity.js';

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
});

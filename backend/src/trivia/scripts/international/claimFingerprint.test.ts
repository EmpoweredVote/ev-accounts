import { describe, it, expect } from 'vitest';
import { fingerprintClaim, normalizeValue } from './claimFingerprint.js';

describe('normalizeValue', () => {
  it('strips unit nouns so 89 and "89 years old" collide', () => {
    expect(normalizeValue('89 years old')).toBe(normalizeValue('89'));
  });

  it('strips thousands separators', () => {
    expect(normalizeValue('1,287 people')).toBe(normalizeValue('1287'));
  });

  it('strips multiple comma groups in one pass', () => {
    expect(normalizeValue('1,234,567')).toBe(normalizeValue('1234567'));
  });

  it('strips approximation hedges', () => {
    expect(normalizeValue('approximately 5,000 people')).toBe(normalizeValue('over 5000'));
  });

  it('keeps distinct numbers distinct', () => {
    expect(normalizeValue('43.8%')).not.toBe(normalizeValue('44%'));
  });

  it('normalises date spelling but not date identity', () => {
    expect(normalizeValue('September 8, 2026')).toBe(normalizeValue('september 8 2026'));
    expect(normalizeValue('September 8, 2026')).not.toBe(normalizeValue('September 7, 2026'));
  });
});

describe('fingerprintClaim', () => {
  const harald = { subject: 'King Harald V', attribute: 'age at death' };

  it('collides on the same fact expressed two ways (wiran-1578 / wiran-1661)', () => {
    const a = fingerprintClaim({ ...harald, value: '89' });
    const b = fingerprintClaim({ ...harald, value: '89 years old' });
    expect(a.topicKey).toBe(b.topicKey);
    expect(a.valueKey).toBe(b.valueKey);
  });

  it('collides on the 35-year reign (wiran-1579 / wiran-1659)', () => {
    const a = fingerprintClaim({ subject: 'King Harald V', attribute: 'length of reign', value: '35 years' });
    const b = fingerprintClaim({ subject: 'king harald v', attribute: 'Length of Reign', value: '35 years' });
    expect(a).toEqual(b);
  });

  it('collides on the Canada tariff date (wiran-1615 / wiran-1635)', () => {
    const a = fingerprintClaim({
      subject: "Canada's retaliatory tariffs on US goods",
      attribute: 'date took effect',
      value: 'September 8, 2026',
    });
    const b = fingerprintClaim({
      subject: 'Canada retaliatory tariffs on US goods',
      attribute: 'date took effect',
      value: 'september 8 2026',
    });
    expect(a).toEqual(b);
  });

  it('shares a topic key but differs on value for a contradiction (Meta ads in India: 84 vs 78)', () => {
    const a = fingerprintClaim({ subject: 'Meta CSAM advertisements in India', attribute: 'count', value: '84 advertisements' });
    const b = fingerprintClaim({ subject: 'Meta CSAM advertisements in India', attribute: 'count', value: '78 advertisements' });
    expect(a.topicKey).toBe(b.topicKey);
    expect(a.valueKey).not.toBe(b.valueKey);
  });

  it('shares a topic key but differs on value for the AfD share (43.8% vs 44%)', () => {
    const a = fingerprintClaim({ subject: 'AfD Saxony-Anhalt 2026', attribute: 'vote share', value: '43.8%' });
    const b = fingerprintClaim({ subject: 'AfD Saxony-Anhalt 2026', attribute: 'vote share', value: '44%' });
    expect(a.topicKey).toBe(b.topicKey);
    expect(a.valueKey).not.toBe(b.valueKey);
  });

  it('does not collide unrelated stories that share an answer (wiran-1611 / wiran-1657, both "2026")', () => {
    const a = fingerprintClaim({ subject: 'Russia-North Korea Tumen River road bridge', attribute: 'year opened', value: '2026' });
    const b = fingerprintClaim({ subject: 'Uganda withdrawal from the Invictus Games', attribute: 'year announced', value: '2026' });
    expect(a.topicKey).not.toBe(b.topicKey);
  });

  it('does not collide unrelated stories dated the same day (wiran-1630 / wiran-1635)', () => {
    const a = fingerprintClaim({ subject: 'UK sanctions on Israeli settlements', attribute: 'date announced', value: 'September 8, 2026' });
    const b = fingerprintClaim({ subject: "Canada's retaliatory tariffs on US goods", attribute: 'date took effect', value: 'September 8, 2026' });
    expect(a.topicKey).not.toBe(b.topicKey);
  });

  it('does not collide unrelated stories sharing a month (wiran-1639 / wiran-1665, both "August 2026")', () => {
    const a = fingerprintClaim({ subject: 'Meta CSAM advertisements peak month', attribute: 'month', value: 'August 2026' });
    const b = fingerprintClaim({ subject: 'Russia jet-powered Geran drone daily attacks on Ukraine', attribute: 'month began', value: 'August 2026' });
    expect(a.topicKey).not.toBe(b.topicKey);
  });

  it('distinguishes two attributes of one subject', () => {
    const a = fingerprintClaim({ subject: 'MV June Aster ferry fire', attribute: 'people aboard', value: '134' });
    const b = fingerprintClaim({ subject: 'MV June Aster ferry fire', attribute: 'people missing', value: '86' });
    expect(a.topicKey).not.toBe(b.topicKey);
  });
});

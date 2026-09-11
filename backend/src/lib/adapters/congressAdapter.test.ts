import { describe, it, expect } from 'vitest';
import { parseCongressUrl } from './congressAdapter.js';

describe('parseCongressUrl', () => {
  it('parses a house-bill overview URL (congress is a slug)', () => {
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/house-bill/1234'))
      .toEqual({ kind: 'bill', congress: 119, billType: 'hr', number: 1234 });
  });

  it('ignores bill sub-paths (/cosponsors, /text, /all-actions)', () => {
    const base = { kind: 'bill', congress: 118, billType: 's', number: 42 };
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/cosponsors')).toEqual(base);
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/text')).toEqual(base);
    expect(parseCongressUrl('https://www.congress.gov/bill/118th-congress/senate-bill/42/all-actions')).toEqual(base);
  });

  it('maps every bill-type slug to its API code', () => {
    const t = (slug: string) => parseCongressUrl(`https://www.congress.gov/bill/119th-congress/${slug}/1`);
    expect(t('house-resolution')).toMatchObject({ billType: 'hres' });
    expect(t('senate-resolution')).toMatchObject({ billType: 'sres' });
    expect(t('house-joint-resolution')).toMatchObject({ billType: 'hjres' });
    expect(t('senate-joint-resolution')).toMatchObject({ billType: 'sjres' });
    expect(t('house-concurrent-resolution')).toMatchObject({ billType: 'hconres' });
    expect(t('senate-concurrent-resolution')).toMatchObject({ billType: 'sconres' });
  });

  it('parses a member URL with a name slug and trailing bioguideId', () => {
    expect(parseCongressUrl('https://www.congress.gov/member/ayanna-pressley/P000617'))
      .toEqual({ kind: 'member', bioguideId: 'P000617' });
  });

  it('parses a member URL that carries a query string', () => {
    expect(parseCongressUrl('https://www.congress.gov/member/linda-sanchez/S001156?q=%7B%22x%22%3A1%7D'))
      .toEqual({ kind: 'member', bioguideId: 'S001156' });
  });

  it('returns null for out-of-scope and non-congress URLs', () => {
    expect(parseCongressUrl('https://www.congress.gov/event/119th-congress/senate-event/LC73719/text')).toBeNull();
    expect(parseCongressUrl('https://www.congress.gov/congressional-record/119th-congress/x/1')).toBeNull();
    expect(parseCongressUrl('https://www.congress.gov/committee/house-committee/foo')).toBeNull();
    expect(parseCongressUrl('https://example.com/bill/119th-congress/house-bill/1')).toBeNull();
    expect(parseCongressUrl('not a url')).toBeNull();
  });

  it('returns null for adversarial bill-type slugs matching Object.prototype members', () => {
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/constructor/1234')).toBeNull();
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/__proto__/1234')).toBeNull();
  });

  it('returns null for a non-numeric bill number', () => {
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/house-bill/abc')).toBeNull();
  });

  it('is case-insensitive on the host', () => {
    expect(parseCongressUrl('https://WWW.CONGRESS.GOV/bill/119th-congress/house-bill/1'))
      .toEqual({ kind: 'bill', congress: 119, billType: 'hr', number: 1 });
  });

  it('parses a bill overview URL with a trailing slash', () => {
    expect(parseCongressUrl('https://www.congress.gov/bill/119th-congress/house-bill/1234/'))
      .toEqual({ kind: 'bill', congress: 119, billType: 'hr', number: 1234 });
  });
});

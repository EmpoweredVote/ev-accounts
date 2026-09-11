import { describe, it, expect } from 'vitest';
import { parseCongressUrl, fetchCongressPageText } from './congressAdapter.js';
import { matchSnippet, checkNameProximity } from '../researchVerifier.js';

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

/** Minimal Response-like fake for a JSON-or-text body. */
function fakeRes(body: unknown, ok = true): Response {
  return {
    ok,
    status: ok ? 200 : 404,
    json: async () => body,
    text: async () => (typeof body === 'string' ? body : JSON.stringify(body)),
  } as unknown as Response;
}

/** Route a fake api.congress.gov client by URL substring. Unlisted → 404. */
function routedFetch(routes: Array<[string, unknown]>): (url: string) => Promise<Response> {
  return async (url: string) => {
    for (const [needle, body] of routes) {
      if (url.includes(needle)) return fakeRes(body);
    }
    return fakeRes({ error: 'not found' }, false);
  };
}

describe('fetchCongressPageText', () => {
  const KEY = 'test-key';

  it('returns null when the URL is not a congress.gov bill/member', async () => {
    const r = await fetchCongressPageText('https://example.com/x', { apiKey: KEY, fetchImpl: routedFetch([]) });
    expect(r).toBeNull();
  });

  it('is a no-op (null) when no key is available', async () => {
    delete process.env.CONGRESS_GOV_API_KEY;
    const r = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/1', {
      fetchImpl: routedFetch([['/bill/', { bill: { title: 'x' } }]]),
    });
    expect(r).toBeNull();
  });

  it('builds a composite that a stored bill snippet verifies against', async () => {
    const summary =
      'This bill directs the Secretary to establish a grant program that expands ' +
      'access to affordable childcare for working families across every state and ' +
      'territory, and authorizes appropriations for fiscal years 2025 through 2030.';
    const fetchImpl = routedFetch([
      ['/bill/119/hr/1234?', { bill: {
        title: 'Affordable Childcare for Working Families Act',
        policyArea: { name: 'Families' },
        sponsors: [{ fullName: 'Rep. Ayanna Pressley' }],
        latestAction: { text: 'Referred to the Committee on Education.' },
      } }],
      ['/bill/119/hr/1234/summaries', { summaries: [{ text: `<p>${summary}</p>` }] }],
      ['/bill/119/hr/1234/cosponsors', { cosponsors: [{ fullName: 'Rep. Katherine Clark' }] }],
      ['/bill/119/hr/1234/actions', { actions: [{ text: 'Introduced in House.' }] }],
      ['/bill/119/hr/1234/text', { textVersions: [] }],
    ]);

    const text = await fetchCongressPageText(
      'https://www.congress.gov/bill/119th-congress/house-bill/1234/cosponsors',
      { apiKey: KEY, fetchImpl },
    );
    expect(text).toBeTruthy();
    expect(text!).toContain('Affordable Childcare for Working Families Act');
    expect(text!).toContain('Pressley');

    // The stored snippet (>=25 words) must verify through the real matcher, and
    // the sponsor's name must sit within the proximity window of the match.
    const snippet = summary; // a research agent quoting the CRS summary verbatim
    const m = matchSnippet(snippet, text!);
    expect(m.verdict).toBe('verified');
    if (m.verdict === 'verified') {
      const prox = checkNameProximity({
        fullName: 'Ayanna Pressley', lastName: 'Pressley', pageText: text!,
        matchOffsetInNormalized: m.matchOffset,
      });
      expect(prox.verdict).toBe('verified');
    }
  });

  it('falls through (null) when the bill endpoint 404s', async () => {
    const r = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/9', {
      apiKey: KEY, fetchImpl: routedFetch([]), // every route 404s
    });
    expect(r).toBeNull();
  });

  it('best-effort /text: a text-hop failure still returns the metadata composite', async () => {
    const fetchImpl = routedFetch([
      ['/bill/119/hr/5?', { bill: { title: 'Test Act of 2025 for the public record and general welfare', sponsors: [{ fullName: 'Rep. Seth Moulton' }] } }],
      // no /summaries, /cosponsors, /actions, /text routes → all 404 (swallowed)
    ]);
    const text = await fetchCongressPageText('https://www.congress.gov/bill/119th-congress/house-bill/5/text', { apiKey: KEY, fetchImpl });
    expect(text).toContain('Test Act of 2025');
  });

  it('builds member text from the member endpoint', async () => {
    const fetchImpl = routedFetch([
      ['/member/P000617', { member: {
        directOrderName: 'Ayanna Pressley',
        partyHistory: [{ partyName: 'Democratic' }],
        state: 'Massachusetts',
        terms: [{ chamber: 'House of Representatives' }],
      } }],
    ]);
    const text = await fetchCongressPageText('https://www.congress.gov/member/ayanna-pressley/P000617', { apiKey: KEY, fetchImpl });
    expect(text).toContain('Ayanna Pressley');
    expect(text).toContain('Massachusetts');
  });
});

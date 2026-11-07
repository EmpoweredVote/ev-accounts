import { describe, it, expect } from 'vitest';
import { parseIgaUrl, igaGet, igaHeaders, isIgaHost, fetchIgaPageText, type FetchLike } from './igaAdapter.js';
import { namesParty } from '../partyLabels.js';

const KEY = 'test-token-0123456789';
const noSleep = async () => {};

/** A fake fetch serving a table of URL → response, recording each request. */
function fakeFetch(table: Record<string, () => Response>) {
  const calls: { url: string; headers: Record<string, string>; redirect?: string }[] = [];
  const fetchImpl: FetchLike = async (url, init) => {
    calls.push({ url, headers: (init?.headers ?? {}) as Record<string, string>, redirect: init?.redirect as string });
    const r = table[url];
    return r ? r() : new Response('not found', { status: 404 });
  };
  return { fetchImpl, calls };
}
const json = (o: unknown) => () => new Response(JSON.stringify(o), { status: 200, headers: { 'content-type': 'application/json' } });

describe('parseIgaUrl', () => {
  it('maps bill pages to the API bill name', () => {
    expect(parseIgaUrl('https://iga.in.gov/legislative/2025/bills/senate/10/details')).toEqual({ kind: 'bill', session: '2025', bill: 'SB0010' });
    expect(parseIgaUrl('https://iga.in.gov/legislative/2026/bills/house/1264')).toEqual({ kind: 'bill', session: '2026', bill: 'HB1264' });
    expect(parseIgaUrl('https://iga.in.gov/legislative/2025/resolutions/senate/72')).toEqual({ kind: 'bill', session: '2025', bill: 'SR0072' });
  });
  it('maps legislator pages to the API slug', () => {
    expect(parseIgaUrl('https://iga.in.gov/legislative/2025/legislators/legislator_scott_alexander_1'))
      .toEqual({ kind: 'legislator', session: '2025', slug: 'scott_alexander_1' });
  });
  it('keeps any PDF document, without query or fragment', () => {
    expect(parseIgaUrl('https://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/SB0010.04.ENRH.pdf#page=2'))
      .toEqual({ kind: 'pdf', url: 'https://iga.in.gov/pdf-documents/124/2025/senate/bills/SB0010/SB0010.04.ENRH.pdf' });
  });
  it('refuses API addresses, other pages, other hosts and plain http', () => {
    expect(parseIgaUrl('https://api.iga.in.gov/2025/bills/sb0010')).toBeNull();
    expect(parseIgaUrl('https://iga.in.gov/session/2025/video/livestreams')).toBeNull();
    expect(parseIgaUrl('https://example.com/legislative/2025/bills/senate/10')).toBeNull();
    expect(parseIgaUrl('http://iga.in.gov/legislative/2025/bills/senate/10')).toBeNull();
  });
});

describe('igaGet', () => {
  it('sends the token as Indiana asks: x-api-key and the iga-api-client user-agent', async () => {
    const { fetchImpl, calls } = fakeFetch({ 'https://api.iga.in.gov/x': json({}) });
    await igaGet('https://api.iga.in.gov/x', 'application/json', { apiKey: KEY, fetchImpl, sleep: noSleep });
    expect(calls[0].headers).toMatchObject({ 'x-api-key': KEY, 'User-Agent': `iga-api-client-${KEY}` });
    expect(calls[0].redirect).toBe('manual');
    expect(igaHeaders(KEY)['User-Agent']).toBe(`iga-api-client-${KEY}`);
  });

  it('follows a redirect between the IGA hosts', async () => {
    const { fetchImpl, calls } = fakeFetch({
      'https://api.iga.in.gov/r': () => new Response(null, { status: 302, headers: { location: 'https://iga.in.gov/pdf-documents/a.pdf' } }),
      'https://iga.in.gov/pdf-documents/a.pdf': () => new Response('%PDF-1.4', { status: 200 }),
    });
    const res = await igaGet('https://api.iga.in.gov/r', 'application/pdf', { apiKey: KEY, fetchImpl, sleep: noSleep });
    expect(await res!.text()).toBe('%PDF-1.4');
    expect(calls.map((c) => c.url)).toEqual(['https://api.iga.in.gov/r', 'https://iga.in.gov/pdf-documents/a.pdf']);
  });

  it('🔴 never sends the token to another host, even on a redirect', async () => {
    const { fetchImpl, calls } = fakeFetch({
      'https://api.iga.in.gov/r': () => new Response(null, { status: 302, headers: { location: 'https://evil.example/steal' } }),
    });
    expect(await igaGet('https://api.iga.in.gov/r', 'application/json', { apiKey: KEY, fetchImpl, sleep: noSleep })).toBeNull();
    expect(await igaGet('https://evil.example/x', 'application/json', { apiKey: KEY, fetchImpl, sleep: noSleep })).toBeNull();
    expect(calls.map((c) => c.url)).toEqual(['https://api.iga.in.gov/r']);
    expect(isIgaHost('http://iga.in.gov/x')).toBe(false);
  });

  it('retries a 429 after Retry-After, then gives up', async () => {
    let n = 0;
    const waits: number[] = [];
    const fetchImpl: FetchLike = async () => (++n < 3 ? new Response('', { status: 429, headers: { 'retry-after': '2' } }) : new Response('{}', { status: 200 }));
    const res = await igaGet('https://api.iga.in.gov/x', 'application/json', { apiKey: KEY, fetchImpl, sleep: async (ms) => { waits.push(ms); } });
    expect(res?.status).toBe(200);
    expect(waits.filter((w) => w === 2000)).toHaveLength(2);
    n = -10;
    expect(await igaGet('https://api.iga.in.gov/x', 'application/json', { apiKey: KEY, fetchImpl, sleep: noSleep })).toBeNull();
  });

  it('does nothing without a key', async () => {
    const { fetchImpl, calls } = fakeFetch({});
    expect(await igaGet('https://api.iga.in.gov/x', 'application/json', { apiKey: '', fetchImpl, sleep: noSleep })).toBeNull();
    expect(calls).toHaveLength(0);
  });
});

describe('fetchIgaPageText', () => {
  const person = (first: string, last: string, title: string) =>
    ({ position_title: title, firstName: first, lastName: last, party: 'Republican', fullName: `${title} ${first} ${last}`, link: '/x' });

  it('builds a bill page from the API with names and no party', async () => {
    const { fetchImpl } = fakeFetch({
      'https://api.iga.in.gov/2025/bills/sb0010': json({
        billName: 'SB0010', title: 'A BILL FOR AN ACT to amend the Indiana Code concerning elections.', description: 'Voter registration.',
        latestVersion: { shortDescription: 'Voter registration.', digest: 'Specifies that proof of identification may not include a document issued by an educational institution.' },
        authors: [person('Blake', 'Doriot', 'Senator')], sponsors: [person('Kendell', 'Culp', 'Representative')],
        all_rollcalls: [{ chamber: { name: 'House' }, rollcall_number: '340', target: 'SB0010.03.COMH', results: { yea: 66, nay: 26 } }],
      }),
      'https://api.iga.in.gov/2025/bills/sb0010/actions': json({ items: [{ date: '2025-01-14T10:59:01', chamber: { name: 'Senate' }, description: 'First reading: referred to Committee on Elections' }] }),
    });
    const t = (await fetchIgaPageText('https://iga.in.gov/legislative/2025/bills/senate/10/details', { apiKey: KEY, fetchImpl, sleep: noSleep }))!;
    expect(t).toContain('SB 10 (2025): Voter registration.');
    expect(t).toContain('Authors: Senator Blake Doriot');
    expect(t).toContain('Sponsors: Representative Kendell Culp');
    expect(t).toContain('2025-01-14 Senate: First reading: referred to Committee on Elections');
    expect(t).toContain('House roll call 340: SB0010.03.COMH yea 66, nay 26');
    expect(namesParty(t)).toBe(false);
    expect(t).not.toContain(KEY);
  });

  it('builds a legislator page, and returns null for the empty record of an unknown slug', async () => {
    const { fetchImpl } = fakeFetch({
      'https://api.iga.in.gov/2025/legislators/scott_alexander_1': json({ firstName: 'Scott', lastName: 'Alexander', party: 'Republican', chamber: { name: 'Senate' }, district: 'Senate District 26' }),
      'https://api.iga.in.gov/2025/legislators/scott_alexander_1/bills/authored': json({ items: [{ billName: 'SB0123', description: 'Unemployment compensation.' }] }),
      'https://api.iga.in.gov/2025/legislators/nobody_1': json({ firstName: '', lastName: '', party: '' }),
    });
    const t = (await fetchIgaPageText('https://iga.in.gov/legislative/2025/legislators/legislator_scott_alexander_1', { apiKey: KEY, fetchImpl, sleep: noSleep }))!;
    expect(t).toContain('Scott Alexander');
    expect(t).toContain('Authored bills (2025):\nSB 123: Unemployment compensation.');
    expect(namesParty(t)).toBe(false);
    expect(await fetchIgaPageText('https://iga.in.gov/legislative/2025/legislators/legislator_nobody_1', { apiKey: KEY, fetchImpl, sleep: noSleep })).toBeNull();
  });

  it('returns null for a PDF link that serves the JavaScript shell', async () => {
    const { fetchImpl } = fakeFetch({ 'https://iga.in.gov/pdf-documents/a.pdf': () => new Response('<!doctype html><p>You need to enable JavaScript</p>', { status: 200 }) });
    expect(await fetchIgaPageText('https://iga.in.gov/pdf-documents/a.pdf', { apiKey: KEY, fetchImpl, sleep: noSleep })).toBeNull();
  });

  it('does nothing for an out-of-scope URL or without a key', async () => {
    const { fetchImpl, calls } = fakeFetch({});
    expect(await fetchIgaPageText('https://iga.in.gov/session/2025/video/livestreams', { apiKey: KEY, fetchImpl })).toBeNull();
    expect(await fetchIgaPageText('https://iga.in.gov/legislative/2025/bills/senate/10', { apiKey: '', fetchImpl })).toBeNull();
    expect(calls).toHaveLength(0);
  });
});

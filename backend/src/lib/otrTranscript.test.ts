import { describe, it, expect } from 'vitest';
import { otrMeetingId, segmentsToText, fetchOtrTranscriptText, withOtrTranscripts } from './otrTranscript.js';
import { verifyEvidence, createPageFetcher, type StanceRow, type EvidenceRow } from './researchVerifier.js';

const ID = '0a1b2c3d-1111-4222-8333-444455556666';
const URL_ = `https://ontherecord.empowered.vote/meetings/${ID}`;
const QUOTE = 'I will fight to protect a woman\'s right to choose and I will veto any bill that restricts access to abortion care in California, because these decisions belong between a patient and her doctor';

const seg = (speakerName: string, text: string, politicianSlug = '') => ({ speakerName, text, politicianSlug, startTime: 0 });
// Two pages of 2 segments each; totalCount 4.
const pages: Record<string, unknown> = {
  1: { totalCount: 4, segments: [seg('Moderator', 'Where do you stand on abortion?'), seg('Xavier Becerra', 'I will fight to protect a woman\'s right to choose', 'pol-1')] },
  2: { totalCount: 4, segments: [seg('Xavier Becerra', 'and I will veto any bill that restricts access to abortion care in California, because these decisions belong between a patient and her doctor', 'pol-1'), seg('Steve Hilton', 'Next question, because these decisions belong elsewhere.', 'pol-2')] },
};
const fakeJson = async (url: string) => {
  const m = /transcript\?page=(\d+)/.exec(url);
  if (!m || !url.includes(`/meetings/${ID}/`)) throw new Error(`unexpected ${url}`);
  return pages[m[1]] ?? { totalCount: 4, segments: [] };
};

describe('otrMeetingId', () => {
  it('extracts the uuid from a meeting url, tolerating a trailing slash, query and case', () => {
    expect(otrMeetingId(URL_)).toBe(ID);
    expect(otrMeetingId(`${URL_}/?t=90`)).toBe(ID);
    expect(otrMeetingId(URL_.toUpperCase().replace('HTTPS', 'https'))).toBe(ID);
  });
  it('returns null for any other url', () => {
    expect(otrMeetingId('https://example.com/meetings/' + ID)).toBeNull();
    expect(otrMeetingId('https://ontherecord.empowered.vote/politicians/x')).toBeNull();
  });
});

describe('segmentsToText', () => {
  it('merges consecutive same-speaker segments into one labelled turn', () => {
    const t = segmentsToText([seg('A B', 'one', 'p'), seg('A B', 'two', 'p'), seg('C D', 'three')]);
    expect(t).toBe('A B: one two\nC D: three');
  });
  it('restricts to one speaker by id or by name', () => {
    const segs = [seg('A B', 'one', 'p'), seg('C D', 'three'), seg('A B', 'four', 'p')];
    expect(segmentsToText(segs, { politicianId: 'p' })).toBe('A B: one\nA B: four');
    expect(segmentsToText(segs, { name: 'c d' })).toBe('C D: three');
  });
});

describe('fetchOtrTranscriptText', () => {
  it('reads every page', async () => {
    const text = await fetchOtrTranscriptText(ID, { fetchJson: fakeJson });
    expect(text).toContain('Xavier Becerra: I will fight');
    expect(text).toContain('Steve Hilton: Next question');
  });
  it('throws on an empty transcript', async () => {
    await expect(fetchOtrTranscriptText(ID, { fetchJson: async () => ({ totalCount: 0, segments: [] }) })).rejects.toThrow(/empty/);
  });
});

describe('withOtrTranscripts', () => {
  it('routes non-OTR urls to the base fetcher and OTR urls to the API', async () => {
    const f = withOtrTranscripts(createPageFetcher(async (u) => `page ${u}`), { fetchJson: fakeJson });
    expect(await f('https://example.com/x')).toEqual({ ok: true, text: 'page https://example.com/x' });
    const r = await f(URL_);
    expect(r.ok && r.text).toContain('Xavier Becerra:');
  });
  it('turns an API failure into a failed fetch, not a throw', async () => {
    const f = withOtrTranscripts(createPageFetcher(async () => ''), { fetchJson: async () => { throw new Error('GET -> 500'); } });
    expect(await f(URL_)).toEqual({ ok: false, reason: 'GET -> 500' });
  });
  it('caches per url', async () => {
    let calls = 0;
    const f = withOtrTranscripts(createPageFetcher(async () => ''), { fetchJson: async (u) => { calls++; return fakeJson(u); } });
    await f(URL_); await f(URL_);
    expect(calls).toBe(2); // two pages, once
  });
});

describe('POSITIVE CONTROL: a known quote in a transcript must verify end to end', () => {
  const stance: StanceRow = { full_name: 'Xavier Becerra', politician_id: 'pol-1', topic_key: 'abortion', value: 1, reasoning: 'r', source_urls: [URL_] };
  const ev = (snippet: string): EvidenceRow => ({ full_name: 'Xavier Becerra', topic_key: 'abortion', source_url: URL_, snippet, snippet_index: 1 });
  const run = async (fetcher: ReturnType<typeof withOtrTranscripts>, snippet: string) =>
    verifyEvidence({
      stanceRows: [stance], evidenceRows: [ev(snippet)], fetcher, threshold: 1,
      politicianNames: { 'Xavier Becerra': { fullName: 'Xavier Becerra', lastName: 'Becerra', aliases: [] } } as any,
    });

  it('verifies the quote through the OTR resolver', async () => {
    const out = await run(withOtrTranscripts(createPageFetcher(async () => '<html><div id="root"></div></html>'), { fetchJson: fakeJson }), QUOTE);
    expect(out.pushable).toHaveLength(1);
  });
  it('control: without the resolver the SPA shell fails the same quote (proves the detector sees the difference)', async () => {
    const out = await run(createPageFetcher(async () => '<html><div id="root"></div></html>') as any, QUOTE);
    expect(out.pushable).toHaveLength(0);
  });
  it('a quote the transcript does not contain still fails', async () => {
    const fake = 'I will abolish the state income tax entirely and personally cut every single department budget by half starting on my first day in office, no exceptions';
    const out = await run(withOtrTranscripts(createPageFetcher(async () => ''), { fetchJson: fakeJson }), fake);
    expect(out.pushable).toHaveLength(0);
  });
});

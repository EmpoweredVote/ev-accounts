// backend/scripts/lib/snapshotSources.test.ts
import { describe, it, expect } from 'vitest';
import { excerptWindows, buildSnapshot } from './snapshotSources.js';
import type { SourceEntry } from './sourcesManifest.js';

const words = (n: number, w = 'filler') => Array.from({ length: n }, (_, i) => `${w}${i}`).join(' ');
const page = `${words(400, 'a')} The Senator said “we will repeal the fuel standard” today. ${words(400, 'b')}`;

describe('excerptWindows', () => {
  it('keeps the anchor plus context on both sides, in original case, and marks the cuts', () => {
    const x = excerptWindows(page, ['we will repeal the fuel standard'], 5)!;
    // anchor = tokens 403..408; 5 words either side → tokens 398..413
    expect(x).toBe('… a398 a399 The Senator said “we will repeal the fuel standard” today. b0 b1 b2 b3 …');
  });
  it('matches whole words only ("the" does not match "there")', () => {
    expect(excerptWindows('there fuel standard is here', ['the fuel standard'], 1)).toBeNull();
  });
  it('matches the anchor with the verifier normalisation (curly quotes, case)', () => {
    expect(excerptWindows(page, ['WE WILL REPEAL THE FUEL STANDARD'], 2)).toContain('repeal the fuel standard');
  });
  it('merges overlapping windows into one', () => {
    const x = excerptWindows(page, ['The Senator said', 'the fuel standard'], 3)!;
    expect(x.split(' … ').length).toBe(1);
  });
  it('returns null when no anchor is on the page (nothing can be excerpted -> not codable)', () => {
    expect(excerptWindows(page, ['a sentence that is not there'], 5)).toBeNull();
  });
});

const entry = (over: Partial<SourceEntry> = {}): SourceEntry => ({
  url: 'https://news.example/story/1', source_kind: 'news', politician_id: 'p1', office_id: 'o1',
  topic_keys: ['fossil-fuels'], instruments: [], pointer_passages: ['we will repeal the fuel standard'], candidate_quotes: [], ...over,
});

describe('buildSnapshot', () => {
  const id = () => 'snap-1';
  it('stores excerpt windows only for a news source, and hashes the whole fetched page', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: page, failure: null, fetchedBy: 'code', newId: id });
    expect(s.ok).toBe(true);
    expect(s.excerpt_only).toBe(true);
    expect(s.snapshot_text!.length).toBeLessThan(page.length);
    expect(s.page_sha256).toMatch(/^[0-9a-f]{64}$/);
  });
  it('stores the full whitespace-collapsed text for a public record', () => {
    const s = buildSnapshot({ entry: entry({ source_kind: 'public-record' }), fetchedText: 'A   bill\n\ntext', failure: null, fetchedBy: 'code', newId: id });
    expect(s.snapshot_text).toBe('A bill text');
    expect(s.excerpt_only).toBe(false);
  });
  it('records a fetch failure as not codable', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: null, failure: 'robots_disallowed', fetchedBy: 'code', newId: id });
    expect(s).toMatchObject({ ok: false, failure: 'robots_disallowed', snapshot_text: null, page_sha256: null });
  });
  it('records a news page whose anchors are missing as not codable', () => {
    const s = buildSnapshot({ entry: entry({ pointer_passages: ['absent text here'] }), fetchedText: page, failure: null, fetchedBy: 'code', newId: id });
    expect(s).toMatchObject({ ok: false, failure: 'anchor-not-found' });
  });
});

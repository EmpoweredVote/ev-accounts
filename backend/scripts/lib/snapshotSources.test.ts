// backend/scripts/lib/snapshotSources.test.ts
import { describe, it, expect } from 'vitest';
import { join, resolve } from 'node:path';
import { excerptWindows, buildSnapshot, snapshotIdFor, resolveHumanSavedPath, MAX_EXCERPT_WORDS } from './snapshotSources.js';
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
  // Final review item 7.
  const two = `${words(50, 'a')} alpha beta ${words(50, 'b')} gamma delta ${words(50, 'c')}`;
  it('joins two separate windows with a single ellipsis', () => {
    expect(excerptWindows(two, ['alpha beta', 'gamma delta'], 2))
      .toBe('… a48 a49 alpha beta b0 b1 … b48 b49 gamma delta c0 c1 …');
  });
  it('keeps whole windows up to the word cap, truncates the last one, and ends it with an ellipsis', () => {
    expect(excerptWindows(two, ['alpha beta', 'gamma delta'], 2, 8)).toBe('… a48 a49 alpha beta b0 b1 … b48 b49 …');
  });
  it('never returns more than MAX_EXCERPT_WORDS page words (spec 1.2)', () => {
    const far = `${words(400, 'a')} one two ${words(400, 'b')} three four ${words(400, 'c')} five six ${words(400, 'd')}`;
    const x = excerptWindows(far, ['one two', 'three four', 'five six'])!;
    const pageWords = x.split(' ').filter((w) => w !== '…');
    expect(MAX_EXCERPT_WORDS).toBe(400);
    expect(pageWords.length).toBe(400);
    expect(x).toContain('one two');
    expect(x).not.toContain('five six');
    expect(x.endsWith(' …')).toBe(true);
  });
});

describe('snapshotIdFor (final review item 5)', () => {
  const base = { batchId: 'b1', url: 'https://x.example/a', pageSha256: 'f'.repeat(64), snapshotText: 'excerpt' };
  it('is a UUID (version 5 layout)', () =>
    expect(snapshotIdFor(base)).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/));
  it('is deterministic for the same batch, url, page and excerpt', () => expect(snapshotIdFor(base)).toBe(snapshotIdFor({ ...base })));
  it('changes when the excerpt text changes', () => expect(snapshotIdFor({ ...base, snapshotText: 'other' })).not.toBe(snapshotIdFor(base)));
  it('changes with the batch, url or page hash', () => {
    expect(snapshotIdFor({ ...base, batchId: 'b2' })).not.toBe(snapshotIdFor(base));
    expect(snapshotIdFor({ ...base, url: 'https://x.example/b' })).not.toBe(snapshotIdFor(base));
    expect(snapshotIdFor({ ...base, pageSha256: 'e'.repeat(64) })).not.toBe(snapshotIdFor(base));
  });
});

describe('resolveHumanSavedPath (final review item 12)', () => {
  const dir = '/tmp/batch-x';
  it('resolves a path inside the batch dir', () => expect(resolveHumanSavedPath(dir, 'saved/a.html')).toBe(join(resolve(dir), 'saved/a.html')));
  it.each([['../other/a.html'], ['/etc/passwd'], ['saved/../../a.html'], ['.']])('refuses %s', (p) =>
    expect(resolveHumanSavedPath(dir, p)).toBeNull());
});

const entry = (over: Partial<SourceEntry> = {}): SourceEntry => ({
  url: 'https://news.example/story/1', source_kind: 'news', politician_id: 'p1', office_id: 'o1',
  topic_keys: ['fossil-fuels'], instruments: [], pointer_passages: ['we will repeal the fuel standard'], candidate_quotes: [], ...over,
});

describe('buildSnapshot', () => {
  const id = 'batch-1';
  it('stores excerpt windows only for a news source, and hashes the whole fetched page', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: page, failure: null, fetchedBy: 'code', batchId: id });
    expect(s.ok).toBe(true);
    expect(s.excerpt_only).toBe(true);
    expect(s.snapshot_text!.length).toBeLessThan(page.length);
    expect(s.page_sha256).toMatch(/^[0-9a-f]{64}$/);
  });
  it('stores the full whitespace-collapsed text for a public record', () => {
    const s = buildSnapshot({ entry: entry({ source_kind: 'public-record' }), fetchedText: 'A   bill\n\ntext', failure: null, fetchedBy: 'code', batchId: id });
    expect(s.snapshot_text).toBe('A bill text');
    expect(s.excerpt_only).toBe(false);
  });
  it('records a fetch failure as not codable', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: null, failure: 'robots_disallowed', fetchedBy: 'code', batchId: id });
    expect(s).toMatchObject({ ok: false, failure: 'robots_disallowed', snapshot_text: null, page_sha256: null });
  });
  it('records a news page whose anchors are missing as not codable', () => {
    const s = buildSnapshot({ entry: entry({ pointer_passages: ['absent text here'] }), fetchedText: page, failure: null, fetchedBy: 'code', batchId: id });
    expect(s).toMatchObject({ ok: false, failure: 'anchor-not-found' });
  });
  it('gives a re-run of the same page the same snapshot_id', () => {
    const a = buildSnapshot({ entry: entry(), fetchedText: page, failure: null, fetchedBy: 'code', batchId: id });
    const b = buildSnapshot({ entry: entry(), fetchedText: page, failure: null, fetchedBy: 'code', batchId: id });
    expect(a.snapshot_id).toBe(b.snapshot_id);
    expect(a.snapshot_id).toBe(snapshotIdFor({ batchId: id, url: a.url, pageSha256: a.page_sha256!, snapshotText: a.snapshot_text! }));
  });
});

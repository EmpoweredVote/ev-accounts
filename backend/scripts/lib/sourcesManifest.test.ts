import { describe, it, expect } from 'vitest';
import { parseSourcesManifest, isExcerptOnly } from './sourcesManifest.js';

const entry = {
  url: 'https://le.utah.gov/~2022/bills/static/HB0011.html', source_kind: 'public-record',
  politician_id: 'p1', office_id: 'o1', topic_keys: ['trans-athletes'], instruments: ['H.B. 11 (2022)'],
  pointer_passages: ['requires students to compete on teams matching their sex at birth'], candidate_quotes: [],
};
const manifest = (sources: unknown[]) => ({ batch_id: '2026-09-26-adams', sources });

describe('parseSourcesManifest', () => {
  it('accepts a well-formed manifest', () => {
    const r = parseSourcesManifest(manifest([entry]));
    expect(r.ok).toBe(true);
  });
  it.each(['value', 'chair', 'reasoning', 'stance', 'proposed_value'])(
    'refuses the collector-opinion key %s (spec §1.1: the collector writes no opinion)', (k) => {
      const r = parseSourcesManifest(manifest([{ ...entry, [k]: 4 }]));
      expect(r).toEqual({ ok: false, errors: [`sources[0]: collector-opinion key "${k}" is not allowed`] });
    });
  it('refuses an unknown source kind and a URL without a path', () => {
    const r = parseSourcesManifest(manifest([{ ...entry, source_kind: 'blog', url: 'https://example.com' }]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors).toEqual(['sources[0]: source_kind blog not allowed', 'sources[0]: url has no path']);
  });
  it('requires at least one anchor for an excerpt-only kind (news/pointer), else nothing can be excerpted', () => {
    const r = parseSourcesManifest(manifest([{ ...entry, source_kind: 'news', pointer_passages: [], candidate_quotes: [] }]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors).toEqual(['sources[0]: news source needs a pointer_passage or candidate_quote to excerpt around']);
  });
  it('accepts a human-saved page path', () => {
    expect(parseSourcesManifest(manifest([{ ...entry, human_saved_path: 'human-saved/hb11.html' }])).ok).toBe(true);
  });
});

describe('isExcerptOnly', () => {
  it('stores excerpts only for news and pointers (spec §5.4)', () => {
    expect(isExcerptOnly('news')).toBe(true);
    expect(isExcerptOnly('pointer')).toBe(true);
    expect(isExcerptOnly('public-record')).toBe(false);
    expect(isExcerptOnly('own-site')).toBe(false);
    expect(isExcerptOnly('transcript')).toBe(false);
  });
});

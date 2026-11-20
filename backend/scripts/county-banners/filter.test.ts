import { describe, it, expect } from 'vitest';
import { filterCandidates, MIN_LONG_EDGE } from './filter.js';
import type { CandidateFile } from './types.js';

const fileWith = (o: Partial<CandidateFile>): CandidateFile => ({
  title: 't', url: 'u', width: 2000, height: 1200, licence: 'CC BY 4.0', author: 'A Photographer',
  date: null, sourceCategory: 'c', lat: null, lon: null, ...o,
});

describe('filterCandidates', () => {
  it('rejects a source under 1700px on the long edge and keeps one at exactly 1700', () => {
    const r = filterCandidates([fileWith({ width: 1699, height: 900 }), fileWith({ width: 1700, height: 900 })]);
    expect(r.rejected.too_small).toBe(1);
    expect(r.kept).toHaveLength(1);
    expect(MIN_LONG_EDGE).toBe(1700);
  });

  it('measures the LONG edge, so a tall source qualifies on its height', () => {
    const r = filterCandidates([fileWith({ width: 1200, height: 2400 })]);
    expect(r.kept).toHaveLength(1);
  });

  it('counts an absent licence separately from a non-free one', () => {
    const r = filterCandidates([fileWith({ licence: null }), fileWith({ licence: 'All rights reserved' })]).rejected;
    expect(r.licence_absent).toBe(1);
    expect(r.licence_non_free).toBe(1);
  });

  it('rejects a file with no author even when the licence is free', () => {
    const r = filterCandidates([fileWith({ author: null, licence: 'CC BY 4.0' })]);
    expect(r.rejected.author_absent).toBe(1);
    expect(r.kept).toHaveLength(0);
  });

  it('keeps a CC0 file with an author', () => {
    expect(filterCandidates([fileWith({ licence: 'CC0' })]).kept).toHaveLength(1);
  });

  it('accepts public domain and CC BY-SA as free', () => {
    const r = filterCandidates([fileWith({ licence: 'Public domain' }), fileWith({ licence: 'CC BY-SA 3.0' })]);
    expect(r.kept).toHaveLength(2);
  });

  it('reports rejection reasons that sum with the keeps to the input length', () => {
    const input = [fileWith({}), fileWith({ width: 100, height: 100 }), fileWith({ licence: null }), fileWith({ author: null })];
    const r = filterCandidates(input);
    const rejected = Object.values(r.rejected).reduce((a, b) => a + b, 0);
    expect(r.kept.length + rejected).toBe(input.length);
  });
});

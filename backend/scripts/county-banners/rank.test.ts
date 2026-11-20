import { describe, it, expect } from 'vitest';
import { rankCandidates, PAGE_SIZE } from './rank.js';
import type { CandidateFile } from './types.js';

const c = (title: string, width: number, height: number): CandidateFile => ({
  title, url: 'u', width, height, licence: 'CC BY 4.0', author: 'A', date: null,
  sourceCategory: 'c', lat: null, lon: null,
});

describe('rankCandidates', () => {
  it('prefers a source with vertical slack over one already at the asset ratio', () => {
    // 3.148:1 has NO slack; the operator could set neither crop lever on it.
    const flat = c('flat.jpg', 3148, 1000);
    const tall = c('tall.jpg', 3000, 2000);
    expect(rankCandidates([flat, tall])[0].title).toBe('tall.jpg');
  });

  it('prefers a larger source at equal shape', () => {
    expect(rankCandidates([c('small.jpg', 1800, 1200), c('big.jpg', 3000, 2000)])[0].title).toBe('big.jpg');
  });

  it('is a total order with no ties, so the ranking is reproducible', () => {
    const items = [c('b.jpg', 2000, 1200), c('a.jpg', 2000, 1200), c('c.jpg', 2000, 1200)];
    expect(rankCandidates(items).map((x) => x.title)).toEqual(rankCandidates([...items].reverse()).map((x) => x.title));
  });

  it('does not rank by category name', () => {
    const a = { ...c('a.jpg', 2000, 1200), sourceCategory: 'Category:Zebra' };
    const b = { ...c('b.jpg', 2000, 1200), sourceCategory: 'Category:Aardvark' };
    expect(rankCandidates([a, b]).map((x) => x.title)).toEqual(['a.jpg', 'b.jpg']);
  });

  it('does not mutate its input', () => {
    const items = [c('b.jpg', 1800, 1200), c('a.jpg', 3000, 2000)];
    rankCandidates(items);
    expect(items.map((x) => x.title)).toEqual(['b.jpg', 'a.jpg']);
  });

  it('shows five at a time', () => { expect(PAGE_SIZE).toBe(5); });
});

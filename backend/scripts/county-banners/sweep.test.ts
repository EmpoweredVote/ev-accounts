import { describe, it, expect } from 'vitest';
import { sweepCategories, countyCategoryRoots, type ApiFn } from './sweep.js';

function file(title: string) {
  return { title, imageinfo: [{ url: `https://u/${title}`, width: 2000, height: 1200,
    extmetadata: { LicenseShortName: { value: 'CC BY 4.0' }, Artist: { value: 'A Photographer' }, DateTimeOriginal: { value: '2020' } } }] };
}
/** A fake Commons: a subcategory tree, a file listing per category, and categories that throw. */
function fakeApi(tree: Record<string, string[]>, files: Record<string, string[]>, errorOn: string[] = []): ApiFn {
  return async (p) => {
    const cat = String(p.gcmtitle ?? p.cmtitle);
    if (errorOn.includes(cat)) throw new Error('category exploded');
    if (p.cmtype === 'subcat') return { query: { categorymembers: (tree[cat] ?? []).map((t) => ({ title: t })) } };
    return { query: { pages: (files[cat] ?? []).map(file) } };
  };
}

describe('sweepCategories', () => {
  it('walks one level of subcategories by default', async () => {
    const api = fakeApi({ 'Category:Root': ['Category:A', 'Category:B'] },
      { 'Category:Root': ['r.jpg'], 'Category:A': ['a.jpg'], 'Category:B': ['b.jpg'] });
    const out = await sweepCategories(['Category:Root'], { api });
    expect(out.map((f) => f.title).sort()).toEqual(['a.jpg', 'b.jpg', 'r.jpg']);
  });

  it('de-duplicates a file that appears in two categories, keeping the first', async () => {
    const api = fakeApi({ 'Category:Root': ['Category:A'] }, { 'Category:Root': ['same.jpg'], 'Category:A': ['same.jpg'] });
    const out = await sweepCategories(['Category:Root'], { api });
    expect(out).toHaveLength(1);
    expect(out[0].sourceCategory).toBe('Category:Root');
  });

  it('records licence, author, width and height on every file', async () => {
    const api = fakeApi({ 'Category:Root': [] }, { 'Category:Root': ['x.jpg'] });
    const [f] = await sweepCategories(['Category:Root'], { api });
    expect(f).toMatchObject({ licence: 'CC BY 4.0', author: 'A Photographer', width: 2000, height: 1200 });
  });

  it('continues past a category that errors and reports it', async () => {
    const seen: string[] = [];
    const api = fakeApi({ 'Category:Root': ['Category:Bad', 'Category:Good'] },
      { 'Category:Root': [], 'Category:Good': ['good.jpg'] }, ['Category:Bad']);
    const out = await sweepCategories(['Category:Root'], { api, onError: (c) => seen.push(c) });
    expect(out.map((f) => f.title)).toEqual(['good.jpg']);
    expect(seen).toContain('Category:Bad');
  });

  it('follows the continue cursor instead of truncating at one page', async () => {
    // Silent truncation at the page limit would cost recall and look like a clean run.
    let call = 0;
    const api: ApiFn = async (p) => {
      if (p.cmtype === 'subcat') return { query: { categorymembers: [] } };
      call++;
      return call === 1
        ? { query: { pages: [file('p1.jpg')] }, continue: { gcmcontinue: 'NEXT' } }
        : { query: { pages: [file('p2.jpg')] } };
    };
    const out = await sweepCategories(['Category:Root'], { api });
    expect(out.map((f) => f.title)).toEqual(['p1.jpg', 'p2.jpg']);
  });
});

describe('countyCategoryRoots', () => {
  it('includes the county seat among the roots', () => {
    expect(countyCategoryRoots('Dawson County', 'Nebraska', 'Lexington'))
      .toEqual(expect.arrayContaining([expect.stringContaining('Lexington')]));
  });
  it('does not append "County" to a name that already carries it', () => {
    expect(countyCategoryRoots('Dawson County', 'Nebraska', null).join('|')).not.toMatch(/County County/);
  });
  it('omits the seat when none is known, and still returns roots', () => {
    const roots = countyCategoryRoots('Dawson County', 'Nebraska', null);
    expect(roots.length).toBeGreaterThan(0);
    expect(roots.join('|')).not.toMatch(/null/);
  });
});

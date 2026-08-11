import { describe, it, expect } from 'vitest';
import { hasRenderablePhoto, HAS_RENDERABLE_PHOTO_SQL } from './photoCoverage.js';

describe('hasRenderablePhoto', () => {
  it('counts a hosted image row', () => {
    expect(hasRenderablePhoto({ images: [{ url: 'https://cdn/x.jpg' }] })).toBe(true);
  });

  it('counts a custom url', () => {
    expect(hasRenderablePhoto({ photo_custom_url: 'https://cdn/x.jpg' })).toBe(true);
  });

  it('does NOT count the research breadcrumbs that pollute photo_origin_url', () => {
    // These are the real values in prod, not hypotheticals: 97 + 48 + 1 + 1 rows.
    for (const v of [
      'searched:no_results',
      'explored',
      'searched:circular_crop_only',
      'local:public/images/HollyHarvey_.jfif',
      'wvc-ut.gov/city-council', // a host with no scheme — still not fetchable as a src
    ]) {
      expect(hasRenderablePhoto({ photo_origin_url: v })).toBe(false);
    }
  });

  it('does NOT count empty or whitespace-only values, which are non-NULL', () => {
    expect(hasRenderablePhoto({ photo_origin_url: '' })).toBe(false);
    expect(hasRenderablePhoto({ photo_origin_url: '   ' })).toBe(false);
    expect(hasRenderablePhoto({ photo_custom_url: '' })).toBe(false);
    expect(hasRenderablePhoto({})).toBe(false);
  });

  it('COUNTS an image URL that has no file extension', () => {
    // Do not "tighten" this into an extension check. Verified 2026-08-11:
    // this exact URL returns 200 image/jpeg, and dccouncil.gov/councilmembers/
    // returns 200 text/html. The two are indistinguishable by URL shape, so an
    // extension test silently condemns working portraits.
    expect(
      hasRenderablePhoto({
        photo_origin_url:
          'https://www.cityofinglewood.org/ImageRepository/Document?documentID=20637',
      })
    ).toBe(true);
  });

  it('counts a roster page too — the predicate measures "could render", not "is a face"', () => {
    // Honest about its own limit: separating these needs a per-row content-type
    // fetch, which is a verification project, not a predicate.
    expect(hasRenderablePhoto({ photo_origin_url: 'https://dccouncil.gov/councilmembers/' })).toBe(
      true
    );
  });

  it('SQL fragment references only the p/img aliases it documents', () => {
    const aliases = [...HAS_RENDERABLE_PHOTO_SQL.matchAll(/\b([a-z]+)\./g)].map((m) => m[1]);
    expect(new Set(aliases)).toEqual(new Set(['img', 'p']));
  });
});

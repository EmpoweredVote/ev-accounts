import { describe, it, expect } from 'vitest';
import {
  ASSET_W, ASSET_H, DESKTOP_RATIO, MOBILE_RATIO,
  assetRect, bandRect, parseFocus, formatFocus,
} from './countyBannerCrop';

describe('assetRect — where the 3.148:1 asset is cut out of the source', () => {
  it('cuts the asset flush to the top at anchor 0', () => {
    expect(assetRect(3400, 2000, 0)).toEqual({ x: 0, y: 0, w: 3400, h: 1080 });
  });

  it('cuts it flush to the bottom at anchor 1', () => {
    expect(assetRect(3400, 2000, 1)).toEqual({ x: 0, y: 920, w: 3400, h: 1080 });
  });

  it('centres at anchor 0.5', () => {
    expect(assetRect(3400, 2000, 0.5).y).toBe(460);
  });

  it('ignores the anchor on a source wider than the asset ratio', () => {
    // 🔴 A panorama has NO vertical slack, so the anchor has nothing to move. The crop becomes
    // height-limited and centred horizontally. Plan 1's ranking prefers sources with slack, but
    // a panorama can still be the only option a county has.
    const r = assetRect(4000, 500, 0);
    expect(r.h).toBe(500);
    expect(r.w).toBeCloseTo(1574.07, 2);
    expect(r.y).toBe(0);
    expect(r.x).toBeCloseTo((4000 - 1574.07) / 2, 1);
  });

  it('gives the same rect at every anchor when there is no slack', () => {
    expect(assetRect(4000, 500, 0)).toEqual(assetRect(4000, 500, 1));
  });

  it('clamps an anchor outside 0..1 rather than cropping outside the source', () => {
    expect(assetRect(3400, 2000, 2).y).toBe(920);
    expect(assetRect(3400, 2000, -1).y).toBe(0);
  });
});

describe('bandRect — where a band sits inside the 1700x540 asset', () => {
  it('places the 6:1 desktop band by focus', () => {
    const r = bandRect(DESKTOP_RATIO, '50% 30%');
    expect(r.h).toBeCloseTo(283.33, 2);   // 1700 / 6
    expect(r.y).toBeCloseTo(77.0, 1);     // 0.30 * (540 - 283.33)
    expect(r.x).toBe(0);
    expect(r.w).toBe(ASSET_W);
  });

  it('centres the desktop band at 50%', () => {
    expect(bandRect(DESKTOP_RATIO, '50% 50%').y).toBeCloseTo(128.33, 2);
  });

  it('the desktop band is 52.5% of the asset height', () => {
    expect(bandRect(DESKTOP_RATIO, '50% 50%').h / ASSET_H).toBeCloseTo(0.525, 3);
  });

  it('the mobile band is 96.9% of the asset', () => {
    expect(bandRect(MOBILE_RATIO, '50% 50%').h / ASSET_H).toBeCloseTo(0.969, 3);
  });

  it('falls back to centred when the focus cannot be read, rather than throwing', () => {
    // The preview must still render for a row whose stored focus is nonsense; the SAVE is what
    // refuses it, in the service.
    expect(bandRect(DESKTOP_RATIO, 'centre').y).toBeCloseTo(128.33, 2);
  });
});

describe('focus strings', () => {
  it('parseFocus reads two percentages', () => {
    expect(parseFocus('50% 30%')).toEqual({ x: 0.5, y: 0.3 });
    expect(parseFocus('0% 100%')).toEqual({ x: 0, y: 1 });
  });

  it('parseFocus returns null for a string it cannot read', () => {
    expect(parseFocus('50% 30')).toBeNull();
    expect(parseFocus('centre')).toBeNull();
    expect(parseFocus('')).toBeNull();
  });

  it('formatFocus round-trips through parseFocus', () => {
    const s = formatFocus(0.5, 0.3);
    expect(s).toBe('50% 30%');
    expect(parseFocus(s)).toEqual({ x: 0.5, y: 0.3 });
  });

  it('formatFocus keeps whole percentages whole, so the stored string stays readable', () => {
    expect(formatFocus(0.25, 0)).toBe('25% 0%');
  });
});

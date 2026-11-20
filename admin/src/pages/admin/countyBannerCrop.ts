/**
 * The two crop levers, as arithmetic. No React, no DOM — so the geometry can be pinned by
 * tests with exact numbers instead of eyeballed in a browser.
 *
 * 🔴 THERE ARE TWO INDEPENDENT DECISIONS AND A FRAME THAT READS CORRECTLY ON ONE SURFACE CAN BE
 * WRONG ON THE OTHER.
 *
 *   1. VERTICAL ANCHOR — where the 3.148:1 asset is cut out of the full source photograph.
 *      Governs what MOBILE sees, which renders 13:4 and shows 96.9% of the asset.
 *   2. FOCUS — a CSS object-position string that slides the 6:1 band within the asset.
 *      Governs what DESKTOP sees, which is only 52.5% of the asset's height.
 *
 * Certify on the band AND on the asset. The Aberdeen "ROAD CLOSED" sign was invisible in the
 * desktop band and dominant on mobile.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */

export const ASSET_W = 1700;
export const ASSET_H = 540;
export const ASSET_RATIO = ASSET_W / ASSET_H;      // 3.148...
export const DESKTOP_RATIO = 6;                     // the band desktop renders
export const MOBILE_RATIO = 13 / 4;                 // 3.25 — what mobile renders

export interface Rect { x: number; y: number; w: number; h: number }

function clamp01(n: number): number {
  if (Number.isNaN(n)) return 0.5;
  return Math.min(1, Math.max(0, n));
}

/**
 * The 3.148:1 rectangle cut out of a source of `srcW` x `srcH`, positioned by `verticalAnchor`
 * (0 = flush to the top, 1 = flush to the bottom).
 *
 * A source TALLER than the asset ratio has vertical slack, and the anchor moves the crop
 * through it. A source WIDER than the asset ratio has none: the crop is then height-limited and
 * centred horizontally, and the anchor has nothing to move. Both cases are real — plan 1's
 * ranking prefers slack, but a panorama can still be the only option a county has.
 */
export function assetRect(srcW: number, srcH: number, verticalAnchor: number): Rect {
  const a = clamp01(verticalAnchor);
  if (srcW / srcH > ASSET_RATIO) {
    const w = srcH * ASSET_RATIO;
    return { x: (srcW - w) / 2, y: 0, w, h: srcH };
  }
  const h = srcW / ASSET_RATIO;
  return { x: 0, y: (srcH - h) * a, w: srcW, h };
}

/**
 * Where a band of the given aspect ratio sits inside the 1700x540 asset, placed by `focus`.
 *
 * Follows CSS `object-fit: cover` semantics: the percentage is the share of the OVERFLOW that
 * sits before the box, so '50% 30%' puts 30% of the spare height above the band.
 *
 * An unreadable focus renders centred rather than throwing — the preview must still draw for a
 * row whose stored string is nonsense. Refusing it is the SAVE's job, in the service.
 */
export function bandRect(ratio: number, focus: string): Rect {
  const f = parseFocus(focus) ?? { x: 0.5, y: 0.5 };
  const h = Math.min(ASSET_H, ASSET_W / ratio);
  const w = Math.min(ASSET_W, ASSET_H * ratio);
  return { x: (ASSET_W - w) * f.x, y: (ASSET_H - h) * f.y, w, h };
}

/** `'50% 30%'` -> `{ x: 0.5, y: 0.3 }`. `null` when the string is not an object-position. */
export function parseFocus(focus: string): { x: number; y: number } | null {
  const m = /^\s*(\d{1,3}(?:\.\d+)?)%\s+(\d{1,3}(?:\.\d+)?)%\s*$/.exec(focus ?? '');
  if (!m) return null;
  const x = Number(m[1]) / 100;
  const y = Number(m[2]) / 100;
  if (x > 1 || y > 1) return null;
  return { x, y };
}

/**
 * `0.5, 0.3` -> `'50% 30%'`.
 *
 * 🔴 This string is what gets STORED and copied downstream verbatim — `getBuildingImages` reads
 * it. Keep whole percentages whole so the value stays readable to a person checking a banner.
 */
export function formatFocus(x: number, y: number): string {
  const pct = (n: number) => {
    const v = clamp01(n) * 100;
    return Number.isInteger(v) ? String(v) : v.toFixed(1);
  };
  return `${pct(x)}% ${pct(y)}%`;
}

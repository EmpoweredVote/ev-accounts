/**
 * Stage 4 -- RENDER THE FULL SOURCE FRAME, UNCROPPED.
 *
 * 🔴🔴 THIS MODULE MUST NEVER CROP, AND THAT IS THE WHOLE POINT OF IT.
 *
 * The banner has TWO independent crop levers and the operator sets both:
 *
 *   - the VERTICAL ANCHOR -- where the 3.148:1 asset is cut out of the source
 *     photograph. This governs what a phone sees (mobile keeps 96.9% of the asset).
 *   - the FOCUS -- a CSS object-position that slides the 6:1 desktop band within the
 *     asset. Desktop keeps 52.5% of asset height, rows 128-412 of 540.
 *
 * Both levers live in the vertical slack between the source's shape and 3.148:1. A
 * pre-cropped file has thrown that slack away, so rendering a crop here would silently
 * remove BOTH of the operator's controls while still producing a picture that looks
 * fine on the review page. The first pass did exactly this.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'node:fs';

/** Display width in the review editor. Big enough to judge, small enough to load 5 per county. */
export const MAX_EDGE = 1100;

/** JPEG quality for review renders. These are never shipped; they are looked at. */
const QUALITY = 72;

export interface RenderedFrame {
  width: number;
  height: number;
  /** The SOURCE's aspect ratio. Below 3.148 means there is slack to crop within. */
  srcRatio: number;
}

/**
 * Write the whole source frame, downscaled to fit MAX_EDGE, to `outPath`.
 *
 * Downscale only -- an image already under the cap is written at its own size rather
 * than upscaled, because upscaling invents detail the operator would then judge.
 */
export async function renderSourceFrame(buf: Buffer, outPath: string): Promise<RenderedFrame> {
  const img = await loadImage(buf);
  const srcW = img.width;
  const srcH = img.height;
  const scale = Math.min(MAX_EDGE / srcW, MAX_EDGE / srcH, 1);
  const w = Math.max(1, Math.round(srcW * scale));
  const h = Math.max(1, Math.round(srcH * scale));

  const canvas = createCanvas(w, h);
  // The full source, corner to corner. No source rectangle, so nothing can be cut.
  canvas.getContext('2d').drawImage(img, 0, 0, w, h);
  fs.writeFileSync(outPath, canvas.toBuffer('image/jpeg', QUALITY));

  return { width: w, height: h, srcRatio: Number((srcW / srcH).toFixed(4)) };
}

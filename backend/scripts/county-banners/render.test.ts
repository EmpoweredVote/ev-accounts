import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createCanvas, loadImage } from '@napi-rs/canvas';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { renderSourceFrame, MAX_EDGE } from './render.js';

let dir: string;
beforeAll(() => { dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cb-render-')); });
afterAll(() => { fs.rmSync(dir, { recursive: true, force: true }); });

/** A real JPEG of the given size — not a stub; the point is to measure real pixels. */
function jpeg(w: number, h: number): Buffer {
  const c = createCanvas(w, h);
  const ctx = c.getContext('2d');
  ctx.fillStyle = '#4477aa';
  ctx.fillRect(0, 0, w, h);
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, Math.max(1, Math.floor(w / 10)), Math.max(1, Math.floor(h / 10)));
  return c.toBuffer('image/jpeg');
}

describe('renderSourceFrame', () => {
  it('keeps the whole frame — it never crops', async () => {
    // srcRatio alone cannot catch a crop: it is computed from the SOURCE and would read
    // the same either way. The OUTPUT's own aspect ratio is what proves nothing was cut.
    const r = await renderSourceFrame(jpeg(2000, 3000), path.join(dir, 'tall.jpg'));
    expect(r.width / r.height).toBeCloseTo(2000 / 3000, 2);
    expect(r.srcRatio).toBeCloseTo(2000 / 3000, 3);
  });

  it('downscales the long edge to 1100 and preserves the aspect ratio', async () => {
    const r = await renderSourceFrame(jpeg(3000, 2000), path.join(dir, 'wide.jpg'));
    expect(Math.max(r.width, r.height)).toBe(MAX_EDGE);
    expect(r.width / r.height).toBeCloseTo(3000 / 2000, 2);
  });

  it('leaves an image smaller than the cap alone', async () => {
    const r = await renderSourceFrame(jpeg(800, 600), path.join(dir, 'small.jpg'));
    expect(r.width).toBe(800);
    expect(r.height).toBe(600);
  });

  it('downscales on HEIGHT when the source is tall', async () => {
    const r = await renderSourceFrame(jpeg(1000, 3000), path.join(dir, 'verytall.jpg'));
    expect(r.height).toBe(MAX_EDGE);
  });

  it('reports srcRatio so a source with no vertical slack can be identified', async () => {
    const r = await renderSourceFrame(jpeg(3148, 1000), path.join(dir, 'flat.jpg'));
    expect(r.srcRatio).toBeCloseTo(3.148, 2);
  });

  it('writes a real readable image to disk', async () => {
    const out = path.join(dir, 'written.jpg');
    await renderSourceFrame(jpeg(2000, 1200), out);
    expect(fs.statSync(out).size).toBeGreaterThan(1000);
  });
});

describe('renderSourceFrame — pixel evidence that nothing was cut', () => {
  /**
   * 🔴 THIS IS THE ONLY TEST THAT CAN CATCH A CROP.
   *
   * A crop changes the CONTENT, not the output's dimensions: drawing a source rectangle
   * into the same canvas leaves width, height and srcRatio identical. A deliberate crop
   * was planted during development and every dimension-based assertion still passed.
   * So the source carries markers in the extreme top and bottom rows and this test
   * reads them back out of the written file.
   */
  function marked(w: number, h: number): Buffer {
    const c = createCanvas(w, h);
    const ctx = c.getContext('2d');
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(0, 0, w, Math.max(1, Math.round(h * 0.04)));              // top marker
    ctx.fillStyle = '#00ff00';
    ctx.fillRect(0, h - Math.max(1, Math.round(h * 0.04)), w, Math.max(1, Math.round(h * 0.04))); // bottom marker
    return c.toBuffer('image/png');
  }

  async function cornerColours(file: string) {
    const img = await loadImage(fs.readFileSync(file));
    const c = createCanvas(img.width, img.height);
    const ctx = c.getContext('2d');
    ctx.drawImage(img, 0, 0);
    const top = ctx.getImageData(Math.floor(img.width / 2), 0, 1, 1).data;
    const bottom = ctx.getImageData(Math.floor(img.width / 2), img.height - 1, 1, 1).data;
    return { topRed: top[0] > 140 && top[1] < 110, bottomGreen: bottom[1] > 140 && bottom[0] < 110 };
  }

  it('keeps the top row of the source', async () => {
    const out = path.join(dir, 'marked-top.jpg');
    await renderSourceFrame(marked(1200, 2000), out);
    expect((await cornerColours(out)).topRed).toBe(true);
  });

  it('keeps the bottom row of the source', async () => {
    const out = path.join(dir, 'marked-bottom.jpg');
    await renderSourceFrame(marked(1200, 2000), out);
    expect((await cornerColours(out)).bottomGreen).toBe(true);
  });
});

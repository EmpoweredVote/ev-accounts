/**
 * pdfMarkedText — PDF text with drawn strike-throughs kept as `[deleted: …]` fences.
 *
 * Indiana bill PDFs mark deleted words ONLY with a thin filled rectangle drawn across the text line.
 * Plain text extraction (pdf-parse) drops the rectangle, so the deleted words read as law. This module
 * reads the page geometry with pdfjs-dist and wraps every struck word in a fence.
 *
 * Rules (spec 2026-09-27-amendment-markup-design.md, constraints):
 * - A strike rectangle is a FILLED path whose height is < 1.5 pt.
 * - It strikes a text item when its centre lies strictly above the item's baseline and below
 *   baseline + 0.6 × the item's height. At or below the baseline it is an underline — ignored.
 * - A word is deleted when ≥ 60 % of its x-range is covered by the union of such rectangles.
 * - Adjacent deleted words (across items and across line ends) merge into ONE fence.
 *
 * Text items are mostly whole lines, so a word's x-range inside an item is estimated from its share of
 * the item's characters.
 */

export interface PdfTextItem { str: string; x: number; y: number; width: number; height: number; fontName: string }
export interface PdfRect { x0: number; x1: number; y0: number; y1: number }   // page coordinates, y up
export interface PageGeometry { items: PdfTextItem[]; rects: PdfRect[] }

/** Strike rectangles are thinner than this (pt). */
export const MAX_STRIKE_HEIGHT = 1.5;
/** A strike's centre must lie below baseline + this × font height. */
export const STRIKE_BAND = 0.6;
/** Share of a word's width that strikes must cover for the word to be deleted. */
export const MIN_COVERAGE = 0.6;
/** Items whose baselines differ by at most this (pt) share a line. */
const LINE_TOLERANCE = 1;

interface Word { text: string; deleted: boolean }

function coveredLength(lo: number, hi: number, spans: Array<[number, number]>): number {
  const clipped = spans
    .map(([a, b]) => [Math.max(a, lo), Math.min(b, hi)] as [number, number])
    .filter(([a, b]) => b > a)
    .sort((p, q) => p[0] - q[0]);
  let total = 0;
  let curA = -Infinity;
  let curB = -Infinity;
  for (const [a, b] of clipped) {
    if (a > curB) {
      if (curB > curA) total += curB - curA;
      curA = a;
      curB = b;
    } else if (b > curB) {
      curB = b;
    }
  }
  if (curB > curA) total += curB - curA;
  return total;
}

function strikesFor(item: PdfTextItem, rects: PdfRect[]): Array<[number, number]> {
  const top = item.y + STRIKE_BAND * item.height;
  return rects
    .filter((r) => {
      if (r.y1 - r.y0 >= MAX_STRIKE_HEIGHT) return false;
      const c = (r.y0 + r.y1) / 2;
      return c > item.y && c < top;
    })
    .map((r) => [Math.min(r.x0, r.x1), Math.max(r.x0, r.x1)] as [number, number]);
}

function itemWords(item: PdfTextItem, rects: PdfRect[]): Word[] {
  const len = item.str.length;
  if (len === 0) return [];
  const spans = strikesFor(item, rects);
  const words: Word[] = [];
  for (const m of item.str.matchAll(/\S+/g)) {
    const start = m.index ?? 0;
    const end = start + m[0].length;
    const lo = item.x + (start / len) * item.width;
    const hi = item.x + (end / len) * item.width;
    const w = hi - lo;
    const deleted = spans.length > 0 && w > 0 && coveredLength(lo, hi, spans) >= MIN_COVERAGE * w;
    words.push({ text: m[0], deleted });
  }
  return words;
}

/** Pure: geometry → page text with [deleted: …] fences. Items in reading order (top→bottom, left→right). */
export function markedTextFromGeometry(g: PageGeometry): string {
  const items = g.items.filter((i) => i.str.trim() !== '');
  const sorted = [...items].sort((a, b) => b.y - a.y || a.x - b.x);
  const lines: PdfTextItem[][] = [];
  let lineY = Number.NaN;
  for (const it of sorted) {
    if (lines.length > 0 && Math.abs(it.y - lineY) <= LINE_TOLERANCE) {
      lines[lines.length - 1].push(it);
    } else {
      lines.push([it]);
      lineY = it.y;
    }
  }

  const words: Word[] = [];
  for (const line of lines) {
    line.sort((a, b) => a.x - b.x);
    for (const it of line) words.push(...itemWords(it, g.rects));
  }

  const out: string[] = [];
  let run: string[] = [];
  const flush = () => {
    if (run.length > 0) out.push(`[deleted: ${run.join(' ')}]`);
    run = [];
  };
  for (const w of words) {
    if (w.deleted) {
      run.push(w.text);
    } else {
      flush();
      out.push(w.text);
    }
  }
  flush();
  return out.join(' ');
}

// ── pdfjs-dist wrapper ────────────────────────────────────────────────────────────────────────────

type Matrix = [number, number, number, number, number, number];
const IDENTITY: Matrix = [1, 0, 0, 1, 0, 0];

function multiply(m: Matrix, n: Matrix): Matrix {
  // Result = n applied first, then m (PDF `cm` semantics: new CTM = n × m).
  return [
    n[0] * m[0] + n[1] * m[2],
    n[0] * m[1] + n[1] * m[3],
    n[2] * m[0] + n[3] * m[2],
    n[2] * m[1] + n[3] * m[3],
    n[4] * m[0] + n[5] * m[2] + m[4],
    n[4] * m[1] + n[5] * m[3] + m[5],
  ];
}

function applyToBox(m: Matrix, [xMin, yMin, xMax, yMax]: number[]): PdfRect {
  const pts = [[xMin, yMin], [xMax, yMin], [xMin, yMax], [xMax, yMax]].map(([x, y]) => [
    m[0] * x + m[2] * y + m[4],
    m[1] * x + m[3] * y + m[5],
  ]);
  const xs = pts.map((p) => p[0]);
  const ys = pts.map((p) => p[1]);
  return { x0: Math.min(...xs), x1: Math.max(...xs), y0: Math.min(...ys), y1: Math.max(...ys) };
}

/** Bounding box of a pdf.js 5 path (DrawOPS: 0 moveTo, 1 lineTo, 2 curveTo, 3 quadraticCurveTo, 4 closePath). */
function boxFromPathData(data: ArrayLike<number>): number[] | null {
  const argc: Record<number, number> = { 0: 2, 1: 2, 2: 6, 3: 4, 4: 0 };
  let xMin = Infinity, yMin = Infinity, xMax = -Infinity, yMax = -Infinity;
  for (let i = 0; i < data.length;) {
    const n = argc[data[i]];
    if (n === undefined) return null;
    for (let j = 0; j < n; j += 2) {
      const x = data[i + 1 + j];
      const y = data[i + 2 + j];
      xMin = Math.min(xMin, x); xMax = Math.max(xMax, x);
      yMin = Math.min(yMin, y); yMax = Math.max(yMax, y);
    }
    i += 1 + n;
  }
  return Number.isFinite(xMin) ? [xMin, yMin, xMax, yMax] : null;
}

/** Bounding box of a pre-v5 path: `[ops[], coords[]]` — coords are x,y pairs. */
function boxFromCoords(coords: ArrayLike<number>): number[] | null {
  let xMin = Infinity, yMin = Infinity, xMax = -Infinity, yMax = -Infinity;
  for (let i = 0; i + 1 < coords.length; i += 2) {
    xMin = Math.min(xMin, coords[i]); xMax = Math.max(xMax, coords[i]);
    yMin = Math.min(yMin, coords[i + 1]); yMax = Math.max(yMax, coords[i + 1]);
  }
  return Number.isFinite(xMin) ? [xMin, yMin, xMax, yMax] : null;
}

/** pdfjs-dist wrapper: every page's geometry. */
export async function pdfGeometry(data: Uint8Array): Promise<PageGeometry[]> {
  const { getDocument, OPS } = await import('pdfjs-dist/legacy/build/pdf.mjs');
  const FILL_OPS = new Set<number>([
    OPS.fill, OPS.eoFill, OPS.fillStroke, OPS.eoFillStroke, OPS.closeFillStroke, OPS.closeEOFillStroke,
  ]);
  // pdfjs may transfer (detach) the buffer it is given; hand it a copy.
  const doc = await getDocument({ data: new Uint8Array(data), verbosity: 0, isEvalSupported: false }).promise;
  const pages: PageGeometry[] = [];
  try {
    for (let p = 1; p <= doc.numPages; p++) {
      const page = await doc.getPage(p);
      const tc = await page.getTextContent();
      const items: PdfTextItem[] = [];
      for (const raw of tc.items) {
        if (!('str' in raw) || raw.str === '') continue;
        items.push({
          str: raw.str,
          x: raw.transform[4],
          y: raw.transform[5],
          width: raw.width,
          height: raw.height,
          fontName: raw.fontName,
        });
      }

      const ol = await page.getOperatorList();
      const rects: PdfRect[] = [];
      let ctm: Matrix = [...IDENTITY];
      const stack: Matrix[] = [];
      for (let i = 0; i < ol.fnArray.length; i++) {
        const fn = ol.fnArray[i];
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const args: any = ol.argsArray[i];
        if (fn === OPS.save) {
          stack.push(ctm);
        } else if (fn === OPS.restore) {
          ctm = stack.pop() ?? [...IDENTITY];
        } else if (fn === OPS.transform) {
          ctm = multiply(ctm, args as Matrix);
        } else if (fn === OPS.paintFormXObjectBegin) {
          stack.push(ctm);
          if (Array.isArray(args?.[0]) || ArrayBuffer.isView(args?.[0])) ctm = multiply(ctm, Array.from(args[0] as ArrayLike<number>) as Matrix);
        } else if (fn === OPS.paintFormXObjectEnd) {
          ctm = stack.pop() ?? [...IDENTITY];
        } else if (fn === OPS.constructPath && Array.isArray(args)) {
          let paintOp: number;
          let box: number[] | null = null;
          if (typeof args[0] === 'number') {
            // pdf.js 5: [paintOp, [pathData], minMax]
            paintOp = args[0];
            const mm = args[2];
            if (mm && mm.length === 4 && Array.from(mm as ArrayLike<number>).every(Number.isFinite)) box = Array.from(mm);
            else if (Array.isArray(args[1]) && args[1][0]) box = boxFromPathData(args[1][0]);
          } else {
            // older pdf.js: [ops[], coords[], minMax]; the paint op follows.
            paintOp = ol.fnArray[i + 1];
            const mm = args[2];
            if (mm && mm.length === 4 && Array.from(mm as ArrayLike<number>).every(Number.isFinite)) box = Array.from(mm);
            else if (args[1]) box = boxFromCoords(args[1]);
          }
          if (!box || !FILL_OPS.has(paintOp)) continue;
          const r = applyToBox(ctm, box);
          if (r.y1 - r.y0 < MAX_STRIKE_HEIGHT) rects.push(r);
        }
      }
      pages.push({ items, rects });
      page.cleanup();
    }
  } finally {
    await doc.destroy();
  }
  return pages;
}

/** Whole document: pages' marked text joined with '\n', whitespace collapsed per line. */
export async function pdfMarkedText(data: Uint8Array): Promise<string> {
  const pages = await pdfGeometry(data);
  return pages
    .map((g) => markedTextFromGeometry(g).replace(/\s+/g, ' ').trim())
    .join('\n');
}

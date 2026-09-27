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
 * - A word is deleted when ≥ 60 % of its x-range is covered by the union of such rectangles, OR when a
 *   strike rectangle is assigned to it (each rect goes to the word it overlaps most — Indiana draws one
 *   rect per struck word) AND that assignment is confident: the rect covers ≥ 30 % of the word's width,
 *   OR ≥ 50 % of the rect's own width lies on the word. A rect that is "best" for a word only weakly (a
 *   graze from a neighbour's rect, with no better candidate on the line) does not by itself force a
 *   delete — the word's fate then falls back to the ordinary coverage rule below, which already fails
 *   closed on genuine partial coverage.
 * - FAIL CLOSED: a word 30–60 % covered with no rect assigned is doubt, and is fenced too (counted as
 *   `ambiguous`). Doubtful text is never presented as law.
 * - Adjacent deleted words (across items and across line ends) merge into ONE fence.
 *
 * Text items are mostly whole lines, so a word's x-range inside an item is placed by its share of the
 * item's total glyph width (widths from the operator list's showText glyphs, per font loadedName). An item
 * with any character of unknown width falls back to character-count share, counted as `widthFallbacks`.
 */

export interface PdfTextItem { str: string; x: number; y: number; width: number; height: number; fontName: string }
export interface PdfRect { x0: number; x1: number; y0: number; y1: number }   // page coordinates, y up
/** Glyph advance widths (1/1000 em) per font loadedName (= PdfTextItem.fontName), keyed by unicode. */
export type FontWidths = Record<string, Record<string, number>>;
export interface PageGeometry { items: PdfTextItem[]; rects: PdfRect[]; fontWidths?: FontWidths }
export interface MarkedTextStats { text: string; fences: number; ambiguous: number; widthFallbacks: number }

/** Strike rectangles are thinner than this (pt). */
export const MAX_STRIKE_HEIGHT = 1.5;
/** A strike's centre must lie below baseline + this × font height. */
export const STRIKE_BAND = 0.6;
/** Share of a word's width that strikes must cover for the word to be deleted. */
export const MIN_COVERAGE = 0.6;
/** Coverage from here up to MIN_COVERAGE, with no strike assigned, is DOUBT — fenced (fail closed). */
export const AMBIGUOUS_COVERAGE = 0.3;
/** A rect assigned to a word (its best overlap on the line) forces a delete only if it covers this share of the word's width... */
export const MIN_ASSIGN_WORD_COVERAGE = 0.3;
/** ...OR this share of the RECT's own width lies on the word (a short word fully under a wider rect). */
export const MIN_ASSIGN_RECT_COVERAGE = 0.5;
/** Items whose baselines differ by at most this (pt) share a line. */
const LINE_TOLERANCE = 1;

interface Word { text: string; lo: number; hi: number; item: PdfTextItem; struck: boolean; deleted: boolean }

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

/** Does this rect sit in the strike band of this item (thin, centre strictly above baseline, below baseline + 0.6 h)? */
function inStrikeBand(r: PdfRect, item: PdfTextItem): boolean {
  if (r.y1 - r.y0 >= MAX_STRIKE_HEIGHT) return false;
  const c = (r.y0 + r.y1) / 2;
  return c > item.y && c < item.y + STRIKE_BAND * item.height;
}

const span = (r: PdfRect): [number, number] => [Math.min(r.x0, r.x1), Math.max(r.x0, r.x1)];

/**
 * Split an item into words with x-ranges. Positions come from the font's glyph widths (share of the
 * item's total glyph width); if any character of the item has no known width, the whole item falls back
 * to character-count share and `fallback` is true.
 */
function itemWords(item: PdfTextItem, fontWidths: FontWidths | undefined): { words: Word[]; fallback: boolean } {
  const chars = [...item.str];
  if (chars.length === 0) return { words: [], fallback: false };
  const map = fontWidths?.[item.fontName];
  let adv: number[] | null = map ? chars.map((ch) => map[ch]) : null;
  if (adv && adv.some((w) => typeof w !== 'number' || !Number.isFinite(w) || w < 0)) adv = null;
  const fallback = adv === null;
  const widths = adv ?? chars.map(() => 1);
  const total = widths.reduce((a, b) => a + b, 0);
  const cum = [0];
  for (const w of widths) cum.push(cum[cum.length - 1] + w);
  const at = (k: number) => item.x + (total > 0 ? cum[k] / total : k / chars.length) * item.width;

  const words: Word[] = [];
  let k = 0;
  while (k < chars.length) {
    if (/\s/.test(chars[k])) { k++; continue; }
    const start = k;
    while (k < chars.length && !/\s/.test(chars[k])) k++;
    words.push({ text: chars.slice(start, k).join(''), lo: at(start), hi: at(k), item, struck: false, deleted: false });
  }
  return { words, fallback };
}

/** Pure, with counts: geometry → page text with [deleted: …] fences. */
export function markedTextFromGeometryWithStats(g: PageGeometry): MarkedTextStats {
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

  let widthFallbacks = 0;
  let ambiguous = 0;
  const words: Word[] = [];
  for (const line of lines) {
    line.sort((a, b) => a.x - b.x);
    const lineWords: Word[] = [];
    for (const it of line) {
      const r = itemWords(it, g.fontWidths);
      if (r.fallback) widthFallbacks++;
      lineWords.push(...r.words);
    }
    // Signal 2: Indiana draws one rect per struck word — give each strike rect to the word it overlaps most,
    // but only trust that assignment (force a delete) when it is confident (see MIN_ASSIGN_*_COVERAGE
    // above). A weak "best" — the only candidate on the line, grazed rather than struck — is left to the
    // ordinary coverage rule below instead of being forced.
    for (const rect of g.rects) {
      const [a, b] = span(rect);
      const rectWidth = b - a;
      let best: Word | null = null;
      let bestOverlap = 0;
      for (const w of lineWords) {
        if (!inStrikeBand(rect, w.item)) continue;
        const o = Math.min(b, w.hi) - Math.max(a, w.lo);
        if (o > bestOverlap) { bestOverlap = o; best = w; }
      }
      if (!best) continue;
      const wordWidth = best.hi - best.lo;
      const wordShare = wordWidth > 0 ? bestOverlap / wordWidth : 0;
      const rectShare = rectWidth > 0 ? bestOverlap / rectWidth : 0;
      if (wordShare >= MIN_ASSIGN_WORD_COVERAGE || rectShare >= MIN_ASSIGN_RECT_COVERAGE) best.struck = true;
    }
    // Signal 1: coverage by the union of strike rects in the word's item band.
    for (const w of lineWords) {
      const width = w.hi - w.lo;
      const spans = g.rects.filter((r) => inStrikeBand(r, w.item)).map(span);
      const cover = spans.length > 0 && width > 0 ? coveredLength(w.lo, w.hi, spans) / width : 0;
      if (cover >= MIN_COVERAGE || w.struck) {
        w.deleted = true;
      } else if (cover >= AMBIGUOUS_COVERAGE) {
        w.deleted = true; // fail closed: doubtful text is never presented as law
        ambiguous++;
      }
    }
    words.push(...lineWords);
  }

  const out: string[] = [];
  let run: string[] = [];
  let fences = 0;
  // A literal `]` inside the deleted text would close the fence early (and a downstream reader
  // splitting on `[deleted: ... ]` would then treat the rest of the original sentence as deleted, or
  // not-deleted, depending on which `]` it paired with) -- swap it for the visually similar U+3015
  // RIGHT TORTOISE SHELL BRACKET, which cannot be confused with the fence's own delimiter.
  const fenceSafe = (s: string) => s.replace(/\]/g, '〕');
  const flush = () => {
    if (run.length > 0) { out.push(`[deleted: ${fenceSafe(run.join(' '))}]`); fences++; }
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
  return { text: out.join(' '), fences, ambiguous, widthFallbacks };
}

/** Pure: geometry → page text with [deleted: …] fences. Items in reading order (top→bottom, left→right). */
export function markedTextFromGeometry(g: PageGeometry): string {
  return markedTextFromGeometryWithStats(g).text;
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
      const fontWidths: FontWidths = {};
      let font = '';
      let ctm: Matrix = [...IDENTITY];
      const stack: Matrix[] = [];
      for (let i = 0; i < ol.fnArray.length; i++) {
        const fn = ol.fnArray[i];
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const args: any = ol.argsArray[i];
        if (fn === OPS.setFont) {
          font = String(args?.[0] ?? '');
          fontWidths[font] ??= {};
        } else if (fn === OPS.showText && Array.isArray(args?.[0])) {
          const map = (fontWidths[font] ??= {});
          for (const glyph of args[0]) {
            if (glyph && typeof glyph === 'object' && typeof glyph.unicode === 'string' && typeof glyph.width === 'number') {
              const cps = [...glyph.unicode];
              if (cps.length === 1) map[glyph.unicode] = map[glyph.unicode] ?? glyph.width;
              else for (const cp of cps) map[cp] = map[cp] ?? glyph.width / cps.length; // ligature: split evenly
            }
          }
        } else if (fn === OPS.save) {
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
      pages.push({ items, rects, fontWidths });
      page.cleanup();
    }
  } finally {
    await doc.destroy();
  }
  return pages;
}

/** Whole document with counts: fences, ambiguous words (fenced, fail closed), items placed by character count. */
export async function pdfMarkedTextWithStats(data: Uint8Array): Promise<MarkedTextStats> {
  const pages = (await pdfGeometry(data)).map(markedTextFromGeometryWithStats);
  return {
    text: pages.map((p) => p.text.replace(/\s+/g, ' ').trim()).join('\n'),
    fences: pages.reduce((n, p) => n + p.fences, 0),
    ambiguous: pages.reduce((n, p) => n + p.ambiguous, 0),
    widthFallbacks: pages.reduce((n, p) => n + p.widthFallbacks, 0),
  };
}

/** Whole document: pages' marked text joined with '\n', whitespace collapsed per line. */
export async function pdfMarkedText(data: Uint8Array): Promise<string> {
  return (await pdfMarkedTextWithStats(data)).text;
}

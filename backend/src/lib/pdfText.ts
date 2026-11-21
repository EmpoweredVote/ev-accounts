// backend/src/lib/pdfText.ts
/**
 * pdfText — plain text out of a fetched PDF (spec 2026-09-25-stance-quote-codebook-reliability-design.md
 * §5.4: "PDFs are snapshotted as extracted text; the hash is on the PDF bytes").
 *
 * Why this exists: fetchViaHttp used to decode EVERY non-HTML body as UTF-8 text, so a PDF reached
 * snapshot-sources as "%PDF-1.4 …" raw bytes (7 MB), reported ok:true, and the coders choked on it
 * (2026-10-07, goldentogether.com GT_*.pdf). Strike-through detection for amended bill text is a
 * separate collector (scripts/pdf-snapshot.ts); this is the plain reader for every other PDF.
 */
const PDF_MAGIC = '%PDF-';

/** True when the bytes start with the PDF magic. A claimed content-type is not trusted on its own. */
export function looksLikePdfBytes(buf: Uint8Array): boolean {
  return buf.length >= 5 && Buffer.from(buf.subarray(0, 5)).toString('latin1') === PDF_MAGIC;
}

/** Magic bytes decide; the content-type is ignored (hosts mislabel PDFs as octet-stream, errors as pdf). */
export function isPdfResponse(_contentType: string, buf: Uint8Array): boolean {
  return looksLikePdfBytes(buf);
}

/** A pdfjs text run: its string, its transform (x at [4], baseline y at [5]), width, and end-of-line flag. */
export interface RunLike {
  str: string;
  transform: number[];
  width: number;
  hasEOL?: boolean;
}

/** Two runs closer than this (PDF units) on one baseline are one piece of text, printed in two runs. */
const TOUCH_GAP = 0.5;

/**
 * Join a page's text runs. Runs are joined by a space, except where the next run starts on the same
 * baseline exactly where the last one ended and neither side has its own space: those are one word
 * printed in two runs. Small capitals do this (Nevada bill texts from 2019 print "HANSEN" as a large
 * "H" run and a smaller "ANSEN" run, and "HAFEN," as "HAFEN" and ","), and a space there split every
 * sponsor's name, so neither a snippet nor the surname could be found (Nevada, 2026-11-21).
 */
export function joinTextRuns(items: RunLike[]): string {
  let out = '';
  let prev: RunLike | null = null;
  for (const i of items) {
    if (prev) {
      const touching = !prev.hasEOL && prev.str !== '' && i.str !== ''
        && !/\s$/.test(prev.str) && !/^\s/.test(i.str)
        && Math.abs(i.transform[5] - prev.transform[5]) < 1
        && Math.abs(i.transform[4] - (prev.transform[4] + prev.width)) < TOUCH_GAP;
      out += touching ? '' : ' ';
    }
    out += i.str;
    prev = i;
  }
  return out;
}

/** Extract a PDF's text, pages joined by newlines, whitespace collapsed per page. Throws on a bad PDF. */
export async function extractPdfText(data: Uint8Array): Promise<string> {
  const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs');
  // pdfjs may transfer (detach) the buffer it is given; hand it a copy.
  const task = getDocument({ data: new Uint8Array(data), verbosity: 0 });
  const doc = await task.promise;
  try {
    const pages: string[] = [];
    for (let p = 1; p <= doc.numPages; p++) {
      const tc = await (await doc.getPage(p)).getTextContent();
      pages.push(joinTextRuns(tc.items.filter((i) => 'str' in i) as RunLike[]).replace(/\s+/g, ' ').trim());
    }
    return pages.filter(Boolean).join('\n');
  } finally {
    await task.destroy();
  }
}

/**
 * One positioned text run of a PDF page: page (from 1), left x, baseline y (PDF units, y grows upward), width, and the
 * direction the text runs, in quarter turns counter-clockwise from left-to-right (0; a page printed sideways is 1 or -1).
 */
export interface PdfTextItem {
  page: number;
  x: number;
  y: number;
  w: number;
  str: string;
  dir?: number;
}

/**
 * Extract a PDF's text runs with their positions, for layouts that the joined text loses: a roll call
 * prints members in four columns, and only the positions tell one name from the next. Empty runs are
 * dropped. Throws on a bad PDF.
 */
export async function extractPdfItems(data: Uint8Array): Promise<PdfTextItem[]> {
  const { getDocument } = await import('pdfjs-dist/legacy/build/pdf.mjs');
  const task = getDocument({ data: new Uint8Array(data), verbosity: 0 });
  const doc = await task.promise;
  try {
    const out: PdfTextItem[] = [];
    for (let p = 1; p <= doc.numPages; p++) {
      const tc = await (await doc.getPage(p)).getTextContent();
      for (const i of tc.items) {
        if (!('str' in i) || !i.str.trim()) continue;
        out.push({ page: p, x: i.transform[4], y: i.transform[5], w: i.width, str: i.str, dir: Math.round(Math.atan2(i.transform[1], i.transform[0]) / (Math.PI / 2)) });
      }
    }
    return out;
  } finally {
    await task.destroy();
  }
}

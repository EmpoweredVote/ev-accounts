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
      pages.push(tc.items.map((i) => ('str' in i ? i.str : '')).join(' ').replace(/\s+/g, ' ').trim());
    }
    return pages.filter(Boolean).join('\n');
  } finally {
    await task.destroy();
  }
}

/** One positioned text run of a PDF page: page (from 1), left x, baseline y (PDF units, y grows upward), width. */
export interface PdfTextItem {
  page: number;
  x: number;
  y: number;
  w: number;
  str: string;
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
        out.push({ page: p, x: i.transform[4], y: i.transform[5], w: i.width, str: i.str });
      }
    }
    return out;
  } finally {
    await task.destroy();
  }
}

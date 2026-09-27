// backend/scripts/pdf-snapshot.ts
/**
 * pdf-snapshot.ts — collector script for a `marked` PDF source (Indiana bill-text PDFs, iga.in.gov):
 * extracts a PDF's text with strike-through detection (pdfMarkedText.ts) so deleted words survive as
 * `[deleted: …]` fences, and writes it as a human-saved page for snapshot-sources.ts (spec
 * 2026-09-27-amendment-markup-design.md §3). Appends a trailer line recording how the text was
 * produced, so amendmentMarkup() (snapshotSources.ts) can read `kept` off the file alone.
 *
 * Two modes:
 *   npx tsx scripts/pdf-snapshot.ts --url <pdf-url> --referer <bill-page-url> --out <file>
 *     Network mode. iga.in.gov's bill-text PDFs need the Referer of the bill's details page and
 *     answer a plain `Accept: application/pdf` request; the host carries no robots restriction
 *     (checked 2026-09-27, KNOWN_DISALLOW_HOSTS in verificationFetch.ts does not list it), but
 *     robots.txt is honoured anyway — fail closed on any OTHER known-disallow host this collector is
 *     later pointed at. A redirect to a different origin gets its own robots.txt check before its
 *     body is trusted.
 *
 *   npx tsx scripts/pdf-snapshot.ts --file <saved.pdf> --url <canonical pdf url> --out <file>
 *     Saved-file mode, for a PDF a person already downloaded in a browser (the honest-UA fetch above
 *     is blocked by some hosts' bot detection — see task-2-report.md). Skips the network and robots
 *     entirely (nothing is fetched); `--url` is recorded in the trailer only, to say what the saved
 *     bytes are a copy of.
 *
 * Both modes gate on the file actually being a PDF (the `%PDF-` magic bytes — not just a claimed
 * content-type, which a saved file doesn't even have) and REFUSE TO WRITE when pdfMarkedTextWithStats
 * reports any `ambiguous` word (30–60 % strike coverage with no rect confidently assigned to it) or
 * any `widthFallbacks` item (a font with no usable glyph widths, so words were placed by character
 * count instead) — fail closed: a person can save the page's text another way instead of coding
 * against a page this reader is not confident it read correctly.
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { pdfMarkedTextWithStats } from './lib/pdfMarkedText.js';
import { robotsAllows, EMPOWERED_VOTE_UA, HTTP_TIMEOUT_MS } from '../src/lib/verificationFetch.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const url = arg('--url');
const referer = arg('--referer');
const out = arg('--out');
const file = arg('--file');
const USAGE = 'usage: --url <pdf-url> --referer <bill-page-url> --out <file>\n' +
  '   or: --file <saved.pdf> --url <canonical pdf url> --out <file>';
if (!url || !out || (!file && !referer)) {
  console.error(USAGE);
  process.exit(2);
}

const PDF_MAGIC = '%PDF-';
const looksLikePdfBytes = (buf: Uint8Array) => buf.length >= 5 && Buffer.from(buf.subarray(0, 5)).toString('latin1') === PDF_MAGIC;

let buf: Uint8Array;
let fromSavedFile: boolean;

if (file) {
  fromSavedFile = true;
  buf = new Uint8Array(readFileSync(file));
  // A saved file has no content-type to trust in the first place — the magic bytes are the ONLY gate.
  if (!looksLikePdfBytes(buf)) {
    console.error(`refused: ${file} does not start with the PDF magic bytes (${PDF_MAGIC})`);
    process.exit(1);
  }
} else {
  fromSavedFile = false;
  if (!(await robotsAllows(url))) {
    console.error(`robots.txt disallows ${url} — refused (fail closed)`);
    process.exit(1);
  }

  const res = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(HTTP_TIMEOUT_MS),
    headers: {
      'user-agent': EMPOWERED_VOTE_UA,
      accept: 'application/pdf,*/*',
      referer: referer!,
    },
  });
  if (!res.ok) {
    console.error(`fetch failed: HTTP ${res.status} ${url}`);
    process.exit(1);
  }
  // A redirect can land on a different origin than the one whose robots.txt we just checked.
  if (new URL(res.url).origin !== new URL(url).origin && !(await robotsAllows(res.url))) {
    console.error(`robots.txt disallows the redirect target ${res.url} — refused (fail closed)`);
    process.exit(1);
  }
  const ctype = res.headers.get('content-type') ?? '';
  buf = new Uint8Array(await res.arrayBuffer());
  // A non-PDF response (an HTML error/interstitial page, most often) must never be handed to the PDF
  // parser as if it were one — refuse it explicitly rather than let pdfMarkedText throw an opaque error.
  if (!ctype.includes('pdf') && !looksLikePdfBytes(buf)) {
    console.error(`refused: response is not a PDF (content-type "${ctype}") ${url}`);
    process.exit(1);
  }
}

const stats = await pdfMarkedTextWithStats(buf);
if (stats.widthFallbacks > 0 || stats.ambiguous > 0) {
  console.error(
    `refused to write: ${stats.ambiguous} ambiguous word(s) and ${stats.widthFallbacks} item(s) placed by ` +
    `character-count fallback (no usable font widths) — this reader is not confident it read every strike ` +
    `correctly (fail closed). Save the page's text another way instead.`);
  process.exit(1);
}

const trailer = fromSavedFile
  ? `[extracted by pdf-snapshot.ts with strike detection, ${new Date().toISOString()}, ${url}, from saved file]`
  : `[extracted by pdf-snapshot.ts with strike detection, ${new Date().toISOString()}, ${url}]`;
writeFileSync(out, `${stats.text}\n${trailer}\n`, 'utf8');
console.log(`wrote ${out} (${stats.text.length} chars, ${stats.fences} fence(s)${fromSavedFile ? ', from saved file' : ''})`);

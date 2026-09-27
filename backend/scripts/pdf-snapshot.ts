// backend/scripts/pdf-snapshot.ts
/**
 * pdf-snapshot.ts — collector script for a `marked` PDF source (Indiana bill-text PDFs, iga.in.gov):
 * fetches the PDF, extracts its text with strike-through detection (pdfMarkedText.ts) so deleted
 * words survive as `[deleted: …]` fences, and writes it as a human-saved page for snapshot-sources.ts
 * (spec 2026-09-27-amendment-markup-design.md §3). Appends a trailer line recording how the text was
 * produced, so amendmentMarkup() (snapshotSources.ts) can read `kept` off the file alone.
 *
 *   npx tsx scripts/pdf-snapshot.ts --url <pdf-url> --referer <bill-page-url> --out <file>
 *
 * iga.in.gov's bill-text PDFs need the Referer of the bill's details page and answer a plain
 * `Accept: application/pdf` request; the host carries no robots restriction (checked 2026-09-27,
 * KNOWN_DISALLOW_HOSTS in verificationFetch.ts does not list it), but robots.txt is honoured anyway —
 * fail closed on any OTHER known-disallow host this collector is later pointed at.
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { pdfMarkedText } from './lib/pdfMarkedText.js';
import { robotsAllows, EMPOWERED_VOTE_UA } from '../src/lib/verificationFetch.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const url = arg('--url');
const referer = arg('--referer');
const out = arg('--out');
if (!url || !referer || !out) {
  console.error('usage: --url <pdf-url> --referer <bill-page-url> --out <file>');
  process.exit(2);
}

if (!(await robotsAllows(url))) {
  console.error(`robots.txt disallows ${url} — refused (fail closed)`);
  process.exit(1);
}

const res = await fetch(url, {
  redirect: 'follow',
  headers: {
    'user-agent': EMPOWERED_VOTE_UA,
    accept: 'application/pdf,*/*',
    referer,
  },
});
if (!res.ok) {
  console.error(`fetch failed: HTTP ${res.status} ${url}`);
  process.exit(1);
}
const ctype = res.headers.get('content-type') ?? '';
const buf = new Uint8Array(await res.arrayBuffer());
// A non-PDF response (an HTML error/interstitial page, most often) must never be handed to the PDF
// parser as if it were one — refuse it explicitly rather than let pdfMarkedText throw an opaque error.
const looksLikePdf = ctype.includes('pdf') || (buf.length >= 5 && Buffer.from(buf.subarray(0, 5)).toString('latin1') === '%PDF-');
if (!looksLikePdf) {
  console.error(`refused: response is not a PDF (content-type "${ctype}") ${url}`);
  process.exit(1);
}

const text = await pdfMarkedText(buf);
const trailer = `[extracted by pdf-snapshot.ts with strike detection, ${new Date().toISOString()}, ${url}]`;
writeFileSync(out, `${text}\n${trailer}\n`, 'utf8');
console.log(`wrote ${out} (${text.length} chars, ${text.includes('[deleted: ') ? 'fences found' : 'no fences found'})`);

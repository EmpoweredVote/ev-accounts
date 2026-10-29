/**
 * Will this snippet actually verify? Ask before you write it into evidence.csv.
 *
 * WHY THIS EXISTS (Knight slice 4, Philadelphia, 2026-10-29). `normalizeText` in
 * `src/lib/researchVerifier.ts` does NOT strip HTML — it lowercases and collapses whitespace and
 * nothing else. So the verifier matches a snippet against the page's RAW MARKUP, and a passage
 * that crosses an element boundary can never match, however verbatim it is.
 *
 * That is not obvious from any other signal. The snippet that triggered this was word-for-word
 * correct, present in a fresh fetch under an HTML-stripping reader, and the URL returned HTTP 200
 * to both curl and fetch. Every ordinary check said the source was fine; the row still came back
 * `below-threshold`. Legistar renders a bill's Title and its Sponsors in separate table cells, so a
 * span running from one into the other is unmatchable.
 *
 * Run this BEFORE committing evidence rows. It reports, per candidate, whether the verifier would
 * match the whole snippet and — when it would not — the longest prefix that does match and the
 * words it breaks after, which is almost always the tag boundary.
 *
 *   npx tsx scripts/check-snippet-verifiable.ts candidates.json
 *
 * candidates.json: [{ "id": "...", "url": "https://…", "text": "the exact passage" }, …]
 *
 * A PDF cannot be pre-tested here (the verifier does its own extraction); those are reported and
 * skipped rather than guessed at.
 */
import fs from 'node:fs';
import { normalizeText } from '../src/lib/researchVerifier.js';

const MIN_WORDS = 25;

type Candidate = { id: string; url: string; text: string };

const path = process.argv[2];
if (!path) {
  console.error('usage: npx tsx scripts/check-snippet-verifiable.ts <candidates.json>');
  process.exit(2);
}

const candidates: Candidate[] = JSON.parse(fs.readFileSync(path, 'utf8'));
const pages = new Map<string, string | null>();
let failures = 0;

for (const c of candidates) {
  if (!pages.has(c.url)) {
    const res = await fetch(c.url);
    const buf = Buffer.from(await res.arrayBuffer());
    pages.set(c.url, buf.subarray(0, 4).toString() === '%PDF' ? null : normalizeText(buf.toString('utf8')));
  }
  const page = pages.get(c.url);
  if (page === null) {
    console.log(`SKIP  ${c.id}  PDF — the verifier extracts these itself, cannot pre-test here`);
    continue;
  }

  const needle = normalizeText(c.text);
  const words = needle.split(/\s+/);
  if (page.includes(needle)) {
    const short = words.length < MIN_WORDS;
    if (short) failures++;
    console.log(`${short ? 'SHORT' : 'PASS '} ${c.id}  words=${words.length}${short ? `  (under the ${MIN_WORDS}-word floor)` : ''}`);
    continue;
  }

  failures++;
  let best = 0;
  for (let k = words.length; k > 0; k--) {
    if (page.includes(words.slice(0, k).join(' '))) { best = k; break; }
  }
  console.log(`FAIL  ${c.id}  words=${words.length}  longest-prefix=${best}` +
    (best >= MIN_WORDS ? '  (would publish truncated)' : '  (TOO SHORT — row would go below-threshold)'));
  if (best > 0) console.log(`        breaks after: …${words.slice(Math.max(0, best - 7), best).join(' ')}`);
}

process.exit(failures ? 1 : 0);

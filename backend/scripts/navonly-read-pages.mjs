#!/usr/bin/env node
/**
 * Fetch every surviving citation and extract enough of it to decide, BY READING, whether it states a
 * position attributable to the politician who cites it.
 *
 * WHY IT EXTRACTS RATHER THAN SCORES. The tempting move is a substantive/nav classifier. This audit has
 * over-fired sixteen times on exactly that move, so this script deliberately stops short of a verdict:
 * it produces evidence for a human to read. The signals it reports are the ones that have actually
 * mattered here:
 *
 *   · 🔴 NAV-INFLATED WORD COUNTS. On .gov sites the site-wide menu is repeated in the markup, so raw
 *     word counts and even surname counts are meaningless — cityofsacramento.gov/mayor showed 147 name
 *     hits and ~19,700 words that were almost entirely nav. So nav/header/footer/script/style are
 *     stripped and BODY figures are reported separately from raw ones.
 *   · 🔴 A TEXT EXTRACTOR THAT FAILS LOOKS LIKE AN EMPTY PAGE. elanaforbend.com/about read as an empty
 *     200 and is 28,269 bytes of real content — my extractor choked on its markup. So raw byte size is
 *     always reported alongside extracted length; a big page with tiny extracted text is an EXTRACTION
 *     FAILURE to inspect by hand, never an "empty page".
 *   · Link density, because an agenda/minutes index is mostly links and little prose.
 *   · Whether the surname appears in body prose at all — a page that never names the person cannot
 *     attribute a position to them.
 *
 * Resumable by cache: each URL is fetched once. Writes navonly-pages.json.
 *
 * Usage (from backend/):  node scripts/navonly-read-pages.mjs [--limit N]
 */
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'data', 'stance-retirement');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36';
const argv = process.argv.slice(2);
const LIMIT = Number((argv.indexOf('--limit') !== -1 && argv[argv.indexOf('--limit') + 1]) || 999);

const ws = JSON.parse(readFileSync(path.join(DIR, 'navonly-workset.json'), 'utf8'));
const CACHE = path.join(DIR, 'navonly-pages.json');
let cache = {};
try { cache = JSON.parse(readFileSync(CACHE, 'utf8')); } catch { /* first run */ }

function fetchRaw(url) {
  try {
    const out = execFileSync('curl', ['-sS', '-L', '--compressed', '--max-time', '25', '-A', UA,
                                      '-w', '\\n@@STATUS:%{http_code}', url],
                             { encoding: 'utf8', timeout: 30_000, maxBuffer: 20 * 1024 * 1024 });
    const m = out.match(/\n@@STATUS:(\d+)$/);
    return { status: m ? Number(m[1]) : 0, body: m ? out.slice(0, m.index) : out };
  } catch (e) {
    const out = e.stdout ?? '';
    const m = String(out).match(/\n@@STATUS:(\d+)$/);
    return { status: m ? Number(m[1]) : 0, body: m ? String(out).slice(0, m.index) : '' };
  }
}

/** Strip the chrome, then the tags. Body text only — see the nav-inflation note above. */
function extract(html) {
  let s = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, ' ');
  const title = (s.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? '').replace(/\s+/g, ' ').trim();

  // Prefer an explicit main/article region when the page marks one — but VERIFY it before trusting it.
  // 🔴 WordPress emits an EMPTY <main id="wp--skip-link--target"> as a skip-link anchor, so preferring
  // <main> blindly extracted zero words from 178KB of real content on every actonmass.org topic page and
  // reported them as empty. Take the main region only when it actually holds more text than the rest of
  // the document would give; otherwise fall back. Same failure family as elanaforbend.com.
  const toText = (h) => h
    .replace(/<nav[\s\S]*?<\/nav>/gi, ' ')
    .replace(/<header[\s\S]*?<\/header>/gi, ' ')
    .replace(/<footer[\s\S]*?<\/footer>/gi, ' ')
    .replace(/<form[\s\S]*?<\/form>/gi, ' ');

  const mainRegion = s.match(/<(?:main|article)\b[^>]*>([\s\S]*?)<\/(?:main|article)>/i)?.[1];
  const clean = (h) => h.replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&').replace(/&#\d+;/g, ' ').replace(/\s+/g, ' ').trim();

  const fullStripped = toText(s);
  const fullText = clean(fullStripped);
  let stripped = fullStripped, text = fullText, usedMain = false;
  if (mainRegion) {
    const mStripped = toText(mainRegion);
    const mText = clean(mStripped);
    // Only honour <main> if it is a real content region, not a skip anchor.
    if (mText.length > 200 && mText.length >= fullText.length * 0.25) {
      stripped = mStripped; text = mText; usedMain = true;
    }
  }

  const linkCount = (stripped.match(/<a\b/gi) ?? []).length;
  return { title, text, linkCount, usedMain };
}

const todo = ws.workset.filter((w) => !cache[w.url]).slice(0, LIMIT);
console.log(`${ws.workset.length} survivor urls, ${ws.workset.length - todo.length} cached, fetching ${todo.length}\n`);

for (const [i, w] of todo.entries()) {
  const { status, body } = fetchRaw(w.url);
  const { title, text, linkCount, usedMain } = extract(body);
  const words = text ? text.split(' ').length : 0;
  // Surname hits in BODY text only. A name that appears solely in the site menu proves nothing.
  const surnames = w.names.map((n) => n.split(/\s+/).pop()).filter((x) => x && x.length > 2);
  const nameHits = {};
  for (const sn of surnames) {
    // 🔴 ESCAPE the surname, do not STRIP it. The first version removed non-word characters, turning
    // "Farley-Bouvier" into "FarleyBouvier" — zero hits on a page titled "Representative Tricia
    // Farley-Bouvier". It silently broke every hyphenated name in the corpus (Kamlager-Dove,
    // Arena-DeRosa, Lungo-Koehn) and each one read as "page never mentions this politician".
    const esc = sn.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    nameHits[sn] = (text.match(new RegExp(`(^|[^\\w-])${esc}([^\\w-]|$)`, 'gi')) ?? []).length;
  }

  cache[w.url] = { url: w.url, rows: w.rows, names: w.names, status,
                   raw_bytes: body.length, title, body_words: words, link_count: linkCount,
                   used_main_region: usedMain, name_hits_in_body: nameHits,
                   // A large page that extracts to almost nothing is an extractor failure, not an empty
                   // page. Flagged rather than scored — it needs eyes.
                   extraction_suspect: body.length > 8000 && words < 120,
                   // Cache the extracted text so the CLASSIFIER can be fixed and re-run without
                   // re-fetching 105 pages. Three classification bugs were found after the first fetch;
                   // re-fetching each time would have made finding the rest slow enough to skip.
                   text: text.slice(0, 20000),
                   excerpt: text.slice(0, 600) };
  writeFileSync(CACHE, `${JSON.stringify(cache, null, 2)}\n`);
  console.log(`[${i + 1}/${todo.length}] ${String(status).padEnd(4)} ${String(words).padStart(6)}w ${String(linkCount).padStart(4)}L  ${w.url.slice(0, 88)}`);
}
console.log(`\nwrote ${path.relative(process.cwd(), CACHE)}`);

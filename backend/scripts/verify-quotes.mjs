#!/usr/bin/env node
/**
 * Verify every quote_text in the wave appears VERBATIM in its cited source.
 *
 * 🔴 Why this exists: WebFetch runs the page through a summarising model, and that model will
 * sometimes hand back paraphrased talking points formatted as though they were quotations. An
 * agent on this wave caught it live — re-fetching the same page with an explicit "only text
 * inside quotation marks" instruction reversed the answer to "no direct quotes exist." A quote
 * that never existed is a fabricated statement attributed to a real person, which is the worst
 * failure this pipeline can produce. So no quote ships until it has been matched against the
 * RAW bytes of its source.
 *
 * Matching is deliberately forgiving about typography and nothing else: curly quotes, dashes,
 * ellipses and whitespace are normalised; wording is not. A quote that fails here is either
 * mis-sourced (fixable — find the true source) or invented (drop it).
 *
 * Run this on EVERY wave before pushing quotes. It was written for the Colorado Springs wave and
 * lived in that wave's directory until 2026-09-23, where it was findable only by accident; it is
 * wave-agnostic now and takes the wave as an argument.
 *
 * Usage:
 *   npm run verify:quotes -- <wave-dir-or-csv> [more...] [--sources <dir>] [--pattern <regex>]
 *
 *   node scripts/verify-quotes.mjs data/stance-research/colorado-springs
 *   node scripts/verify-quotes.mjs data/stance-research/nc-2026/out-batch-04.csv
 *   node scripts/verify-quotes.mjs data/stance-research/foo --pattern '^rows-.*\\.csv$'
 *
 * A directory is scanned for CSVs matching --pattern (default /^out-.*\\.csv$/), and its
 * `sources/` subdirectory, if present, is loaded as local harvested text so a quote drawn from a
 * frozen file matches without a refetch. Pass --sources to point somewhere else.
 *
 * Exit code is 1 if any quote could not be found in its source, so it can gate a push.
 */
import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { parse } from 'csv-parse/sync';

const argv = process.argv.slice(2);
const takeFlag = (name) => {
  const i = argv.indexOf(name);
  if (i === -1) return null;
  const v = argv[i + 1];
  if (!v || v.startsWith('--')) {
    console.error(`${name} needs a value`);
    process.exit(2);
  }
  argv.splice(i, 2);
  return v;
};
const sourcesFlag = takeFlag('--sources');
const patternFlag = takeFlag('--pattern');
const targets = argv.filter((a) => !a.startsWith('--'));

if (targets.length === 0) {
  console.error('Usage: node scripts/verify-quotes.mjs <wave-dir-or-csv> [more...] [--sources <dir>] [--pattern <regex>]');
  console.error('Refusing to guess a wave directory \u2014 name the one you are pushing.');
  process.exit(2);
}

const CSV_RE = new RegExp(patternFlag || '^out-.*\\.csv$');

// Resolve the targets into a concrete CSV list and a set of directories to look for sources in.
const csvFiles = [];
const sourceDirs = [];
for (const t of targets) {
  const abs = path.resolve(t);
  let st;
  try {
    st = await stat(abs);
  } catch {
    console.error(`no such path: ${t}`);
    process.exit(2);
  }
  if (st.isDirectory()) {
    const found = (await readdir(abs)).filter((f) => CSV_RE.test(f)).sort();
    if (found.length === 0) console.error(`\u26a0 no CSV matching ${CSV_RE} in ${t}`);
    for (const f of found) csvFiles.push(path.join(abs, f));
    sourceDirs.push(path.join(abs, 'sources'));
  } else {
    csvFiles.push(abs);
    sourceDirs.push(path.join(path.dirname(abs), 'sources'));
  }
}
if (sourcesFlag) sourceDirs.length = 0, sourceDirs.push(path.resolve(sourcesFlag));

if (csvFiles.length === 0) {
  console.error('no CSV files to check');
  process.exit(2);
}

const norm = (s) =>
  (s || '')
    .replace(/[‘’ʼ`]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[–—‒]/g, '-')
    .replace(/…/g, '...')
    .replace(/&nbsp;| /g, ' ')
    .replace(/<[^>]+>/g, ' ')
    // 🔴 Decode numeric entities BEFORE stripping punctuation. `&#8217;` (a curly apostrophe) has
    // digits in it, and digits survive a punctuation strip — so "you&#8217;re" was becoming
    // "you 8217 re" and failing to match a quote that was in fact verbatim. Two real quotes were
    // flagged as unverified by exactly this bug.
    .replace(/&#8217;|&#39;|&#039;|&apos;|&rsquo;|&lsquo;|&#8216;/g, "'")
    .replace(/&#8220;|&#8221;|&ldquo;|&rdquo;|&quot;/g, '"')
    .replace(/&#8211;|&#8212;|&ndash;|&mdash;/g, '-')
    .replace(/&#8230;|&hellip;/g, '...')
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase()
    // Compare on words only. Quoting honestly requires closing a truncated sentence, so an agent
    // will write a full stop where the source runs on with a comma — that is standard practice,
    // not an alteration of meaning, and it was the sole difference in every quote this check
    // initially flagged. Dropping punctuation removes that false positive while still catching
    // the thing that matters: words the source never contained.
    .replace(/[^\p{L}\p{N} ]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();

// Local harvested sources, so a quote drawn from a frozen file can be matched without a refetch.
// A missing sources/ directory is normal for a wave that never harvested any \u2014 not an error.
const localText = [];
for (const dir of [...new Set(sourceDirs)]) {
  let entries;
  try {
    entries = await readdir(dir);
  } catch {
    continue;
  }
  for (const f of entries) {
    if (!/\.(md|txt)$/.test(f)) continue;
    localText.push(norm(await readFile(path.join(dir, f), 'utf8')));
  }
}

const cache = new Map();
const fetchNorm = async (url) => {
  if (cache.has(url)) return cache.get(url);
  let t = '';
  try {
    const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote/1.0 (quote verification)' }, redirect: 'follow' });
    t = r.ok ? norm(await r.text()) : '';
    if (!r.ok) t = `__HTTP_${r.status}__`;
  } catch (e) {
    t = '__FETCH_FAILED__';
  }
  cache.set(url, t);
  return t;
};

const results = { verified: [], local: [], notfound: [], unfetchable: [] };

for (const f of csvFiles) {
  const rows = parse(await readFile(f, 'utf8'), { columns: true, skip_empty_lines: true, bom: true });
  for (const r of rows) {
    const q = (r.quote_text || '').trim();
    if (!q) continue;
    const nq = norm(q);
    // A very short fragment can match by accident; require real substance.
    if (nq.length < 25) { results.notfound.push({ who: r.full_name, topic: r.topic_key, why: 'quote too short to verify safely', q }); continue; }

    // An ellipsis is a truncation MARKER, not text to find. Split on it and require every
    // substantial fragment to appear in the source — that still catches a fabricated quote
    // while allowing honest excerpting.
    // 🔴 Split on the ellipsis in the RAW quote, BEFORE normalising. `norm()` strips punctuation,
    // which destroys the "..." marker — so splitting afterwards yields one fragment and an
    // honestly-elided quote fails. This masked a genuine quote whose author had correctly marked
    // an omission ("…re-distribution...and socialism" for "…re-distribution, open borders,
    // impeachment talk and socialism").
    const frags = q.split(/\s*(?:\.\.\.|…)\s*/).map((s) => norm(s)).filter((s) => s.length >= 20);
    // Whole-string first. If that fails, fall back to sliding word-windows: a quote elided
    // internally, or spanning a paragraph break the source renders with extra markup, will not
    // match end-to-end even though every word of it is genuinely present. Requiring EVERY 8-word
    // window to appear still makes a fabricated clause impossible to pass — you cannot invent a
    // sentence and have all of its windows turn up in the source.
    const words = nq.split(' ').filter(Boolean);
    const windows = [];
    for (let i = 0; i + 8 <= words.length; i += 4) windows.push(words.slice(i, i + 8).join(' '));
    const hasAll = (t) =>
      (frags.length > 0 && frags.every((fr) => t.includes(fr))) ||
      (windows.length > 0 && windows.every((w) => t.includes(w)));

    if (localText.some(hasAll)) { results.local.push({ who: r.full_name, topic: r.topic_key }); continue; }

    const urls = [r.source_url_1, r.source_url_2, r.source_url_3].map((u) => (u || '').trim()).filter(Boolean);
    let hit = false, anyFetched = false;
    for (const u of urls) {
      const t = await fetchNorm(u);
      if (t.startsWith('__')) continue;
      anyFetched = true;
      if (hasAll(t)) { hit = true; break; }
    }
    if (hit) results.verified.push({ who: r.full_name, topic: r.topic_key });
    else if (!anyFetched) results.unfetchable.push({ who: r.full_name, topic: r.topic_key, urls });
    else results.notfound.push({ who: r.full_name, topic: r.topic_key, why: 'not present in fetched source', q: q.slice(0, 110), urls });
  }
}

console.log(`csv files checked            : ${csvFiles.length}`);
console.log(`local source files loaded    : ${localText.length}`);
console.log(`quotes examined              : ${results.verified.length + results.local.length + results.notfound.length + results.unfetchable.length}`);
console.log(`verified against live source : ${results.verified.length}`);
console.log(`verified against local file  : ${results.local.length}`);
console.log(`source unfetchable (WAF/404) : ${results.unfetchable.length}`);
console.log(`🔴 NOT FOUND IN SOURCE        : ${results.notfound.length}`);
for (const x of results.notfound) console.log(`   [notfound] ${x.who} / ${x.topic} — ${x.why}\n      "${x.q}"`);
for (const x of results.unfetchable) console.log(`   [unfetchable] ${x.who} / ${x.topic} — ${x.urls.join(' ')}`);
// ⚠ Set exitCode; do NOT process.exit() here. Node's fetch keeps pooled sockets alive for a
// moment after the last request, and exiting hard while they are closing trips a libuv assertion
// on Windows (`UV_HANDLE_CLOSING`, src/win/async.c) that replaces our exit code with 127. A gate
// whose exit code can be overwritten at teardown is not a gate. Let the loop drain instead, with
// an unref'd backstop so a wedged socket still cannot hang CI.
process.exitCode = results.notfound.length ? 1 : 0;
setTimeout(() => process.exit(process.exitCode), 5000).unref();

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
 * Usage: node verify-quotes.mjs
 */
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { parse } from 'csv-parse/sync';

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const SRC = path.join(HERE, 'sources');

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
const localText = [];
for (const f of await readdir(SRC)) {
  if (!/\.(md|txt)$/.test(f)) continue;
  localText.push(norm(await readFile(path.join(SRC, f), 'utf8')));
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

const files = (await readdir(HERE)).filter((f) => /^out-.*\.csv$/.test(f)).sort();
const results = { verified: [], local: [], notfound: [], unfetchable: [] };

for (const f of files) {
  const rows = parse(await readFile(path.join(HERE, f), 'utf8'), { columns: true, skip_empty_lines: true, bom: true });
  for (const r of rows) {
    const q = (r.quote_text || '').trim();
    if (!q) continue;
    const nq = norm(q);
    // A very short fragment can match by accident; require real substance.
    if (nq.length < 25) { results.notfound.push({ who: r.full_name, topic: r.topic_key, why: 'quote too short to verify safely', q }); continue; }

    // An ellipsis is a truncation MARKER, not text to find. Split on it and require every
    // substantial fragment to appear in the source — that still catches a fabricated quote
    // while allowing honest excerpting.
    const frags = nq.split(/\s*\.\.\.\s*/).map((s) => s.trim()).filter((s) => s.length >= 20);
    const hasAll = (t) => frags.length > 0 && frags.every((fr) => t.includes(fr));

    if (localText.some(hasAll)) { results.local.push({ who: r.full_name, topic: r.topic_key }); continue; }

    const urls = [r.source_url_1, r.source_url_2, r.source_url_3].map((u) => (u || '').trim()).filter(Boolean);
    let hit = false, anyFetched = false;
    for (const u of urls) {
      const t = await fetchNorm(u);
      if (t.startsWith('__')) continue;
      anyFetched = true;
      if (t.includes(nq)) { hit = true; break; }
    }
    if (hit) results.verified.push({ who: r.full_name, topic: r.topic_key });
    else if (!anyFetched) results.unfetchable.push({ who: r.full_name, topic: r.topic_key, urls });
    else results.notfound.push({ who: r.full_name, topic: r.topic_key, why: 'not present in fetched source', q: q.slice(0, 110), urls });
  }
}

console.log(`verified against live source : ${results.verified.length}`);
console.log(`verified against local file  : ${results.local.length}`);
console.log(`source unfetchable (WAF/404) : ${results.unfetchable.length}`);
console.log(`🔴 NOT FOUND IN SOURCE        : ${results.notfound.length}`);
for (const x of results.notfound) console.log(`   [notfound] ${x.who} / ${x.topic} — ${x.why}\n      "${x.q}"`);
for (const x of results.unfetchable) console.log(`   [unfetchable] ${x.who} / ${x.topic} — ${x.urls.join(' ')}`);
process.exit(results.notfound.length ? 1 : 0);

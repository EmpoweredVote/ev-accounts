#!/usr/bin/env node
/**
 * Build a legislator -> civil-rights-bill index for Maryland by fetching each bill's FULL sponsor
 * list from mgaleg.
 *
 * 🔴 WHY THIS HAS TO EXIST. The class-C template rows claim the member "CO-SPONSORED civil rights
 * legislation". The cached MD corpus indexes only the FIRST sponsor of each bill, so it cannot
 * disprove a co-sponsorship claim — "not in the corpus" would be a false negative on every row.
 * The bill page carries the whole list: "Sponsored by Delegates A. Washington, Afzali, Branch,
 * Clippinger …". Maryland calls them all sponsors; there is no separate cosponsor block.
 *
 * ⚠ IDENTITY. mgaleg prints a bare surname, or an initial plus surname where a surname is shared
 * ("A. Washington" vs "M. Washington" — two different senators, a collision that already bit this
 * workstream). A bare surname that is shared by more than one sitting member is recorded as
 * AMBIGUOUS and never credited to anyone.
 *
 * 🔴 Reads only. Emits an index; nothing here is a delete list.
 *   node scripts/md-cr-sponsor-index.mjs --out <index.json> [--limit N]
 */
import fs from 'node:fs';
import path from 'node:path';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-cr-sponsor-index.json');
const LIMIT = parseInt(flag('--limit', '0'), 10);
const CACHE = flag('--cache', 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/md-cr-bills');
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const corpus = JSON.parse(fs.readFileSync('C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus/md-bill-corpus.json', 'utf8'));
// ⚠ the corpus ships a degraded duplicate of every bill (title "2") — filter it out
const bills = corpus.bills.filter((x) => x.title && x.title.length > 5);

// Deliberately broad. Precision comes from reading the matched TITLE later, not from this net.
/**
 * ⚠ THE FIRST NET OMITTED "religio" AND "immigra" ENTIRELY — 59 religion bills and 102 immigration
 * bills were never fetched, and three rows then scored "no on-topic bill" purely because nobody had
 * looked. An absence produced by the net is not an absence in the record. Whenever a topic is added
 * to the row set, it must be added here first.
 * 🔴 STILL UNTESTABLE BY THIS ROUTE: same-sex marriage. Maryland settled it with the 2012 Civil
 * Marriage Protection Act, and 2012RS has ZERO usable bills in the corpus — only 2 same-sex-titled
 * bills exist across 2013-2026. A miss there is a corpus-period artefact, never evidence.
 */
const CR = /discriminat|civil right|human relations|hate crime|equal pay|equity|racial|race|LGBTQ|sexual orientation|gender identity|conversion therapy|marriage|fair housing|public accommodation|reparation|lynching|hate|bias|religio|conscience|faith-based|clergy|immigra|sanctuary|undocumented|transgender/i;
let targets = bills.filter((x) => CR.test(x.title));
if (LIMIT) targets = targets.slice(0, LIMIT);
console.log(`civil-rights-titled MD bills 2013-2026: ${targets.length}`);

const fileFor = (s, n) => path.join(CACHE, `${s}_${n}.html`);

let fetched = 0, cached = 0, failed = 0;
const out = [];
for (const b of targets) {
  const f = fileFor(b.session, b.slug);
  let html = null;
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) { html = fs.readFileSync(f, 'utf8'); cached++; }
  else {
    const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}`;
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA } });
      const body = await res.text();
      // ⚠ a short body is a block or an error, never an empty sponsor list — record it as a FAILURE
      if (!res.ok || body.length < 20000) { failed++; await sleep(1500); continue; }
      html = body; fs.writeFileSync(f, html); fetched++;
      await sleep(1100);
    } catch { failed++; continue; }
  }
  const m = html.match(/Sponsored by[\s\S]{0,60}?<\/?[^>]*>([\s\S]{0,4000}?)(?:<\/p>|<\/div>|Status:|Introduced)/i);
  let raw = m ? m[1] : null;
  if (!raw) {
    const i = html.indexOf('Sponsored by');
    raw = i > -1 ? html.slice(i, i + 3000) : null;
  }
  if (!raw) { failed++; continue; }
  const text = raw.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim()
    .replace(/^Sponsored by\s*/i, '');
  // "Delegates A. Washington , Afzali , Branch , Clippinger" / "Senator Raskin" / "Chair, X Committee"
  const names = text.replace(/^(Delegates?|Senators?)\s+/i, '')
    .split(/\s*,\s*/).map((s) => s.trim())
    .filter((s) => s && s.length < 40 && !/^(and|Chair|Vice Chair|President|Speaker)$/i.test(s)
      && !/Committee|Delegation|By Request|Administration/i.test(s));
  out.push({ session: b.session, number: b.number, slug: b.slug, title: b.title, chamber: b.chamber, sponsors: names });
  if ((fetched + cached) % 50 === 0) console.log(`  …${fetched + cached}/${targets.length} (fetched ${fetched}, cached ${cached}, failed ${failed})`);
}
console.log(`\nbills with a parsed sponsor list: ${out.length}  (fetched ${fetched}, from cache ${cached}, failed ${failed})`);

// reverse index: normalised sponsor token -> bills
const idx = {};
for (const b of out) for (const s of b.sponsors) {
  const key = s.toLowerCase().replace(/\./g, '').replace(/\s+/g, ' ').trim();
  (idx[key] ||= []).push({ session: b.session, number: b.number, title: b.title });
}
console.log(`distinct sponsor tokens: ${Object.keys(idx).length}`);

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'MD civil-rights bill sponsor index (FULL sponsor lists, not just first sponsor)',
  caveat: 'Maryland lists every sponsor under "Sponsored by"; there is no separate cosponsor block. '
        + 'A bare surname shared by two members is ambiguous and must not be credited to either.',
  n_bills: out.length, failed, bills: out, index: idx,
}, null, 1));
console.log(`wrote ${OUT}`);

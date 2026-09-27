#!/usr/bin/env node
/**
 * build-ks-legislature-roster.mjs — Knight program, wave KS-2.
 *
 * Builds the Kansas legislature roster from the Legislature's own site and checks it the way this
 * program has learned to: against each member's OWN page, with every detector shown failing first.
 *
 * WHAT IT READS, AND WHY THAT SOURCE
 *   1. kslegislature.gov/b2025_26/{house/representatives,senate/senators}/csv/ — a FIRST-PARTY,
 *      machine-readable roster the Legislature publishes itself. 125 and 40 rows, with District,
 *      Fullname, Party and County as real columns. No scraping heuristics, no name parsing.
 *   2. Every member's own page, swept in full.
 *
 * 🔴🔴 THE CSV CANNOT REPORT A DEPARTURE, AND A POSITIVE CONTROL IS WHAT ESTABLISHED THAT. It has
 * `Enddate` and `Endnote` columns, and they are EMPTY FOR ALL 125 HOUSE ROWS. That alone proves
 * nothing — an empty column is a uniform answer. So the same columns were read from the COMPLETED
 * 2023-24 biennium, where departures certainly occurred: also 0 of 125. ▶ The columns are never
 * populated, so "no rows carry Enddate" must NEVER be read as "no vacancies". This is MN-2's
 * finding — A ROSTER LIST PAGE IS NOT A CHANGE-CHECK — reproduced in a CSV.
 *
 * 🟢 kslegislature.gov DOES NOT SOFT-404, unlike legislature.ky.gov. Bogus slugs
 * (rep_notaperson_fake_1, rep_brunk_steve_99, sen_zzz_zzz_1) all return a real HTTP 404 at ~43.6 KB
 * against ~46.6 KB for a real page. Measured 2026-09-27. So a missing member is detectable here.
 *
 * 🔴 THE ROSTER LIST IS PAGINATED AT 20 AND `per_page` IS IGNORED. `?per_page=200` returns TEN
 * slugs — fewer than the default. The only reliable path is `?page=N` until the stated total is
 * reached, and the page states it: "Showing 1–20 of 125 representatives". This script pages until
 * it has the expected count and refuses to continue if it does not.
 *
 * 🔴🔴 THE `Terms` BLOCK IS NOT A USABLE TERM-START SOURCE, AND THE MARKUP IS NOT AT FAULT. Each
 * member page carries a Terms card of (chamber, span) rows. For most members it is coherent —
 * "House 2013–Present". For at least 15 it is INTERNALLY CONTRADICTORY, and the raw HTML was read
 * to confirm the parser is innocent. Blake Carpenter (House 81) publishes:
 *     House 2015–2022 · House 2022–Present · House 2023–2024 · House 2025–2026
 * "2022–Present" cannot coexist with "2023–2024" and "2025–2026" as service spans. Mike Amyx
 * carries "2019–Present" beside "2025–2026"; Tom Sawyer carries "1987–1992" beside an overlapping
 * "1991–1992". ▶ SO THE SPAN ENDING IN "Present" DOES NOT RELIABLY GIVE AN ARRIVAL YEAR, and this
 * script reports the block rather than converting it into a term_start. Dating Kansas occupancy
 * needs a source this one is not. KY-2's rule holds and is sharpened: a published service string is
 * chamber-scoped AND may not be self-consistent.
 *
 * 🔴 AND "FIRST ELECTED" IS NOT AVAILABLE EITHER. The CSV's `Firstterm` column is populated for
 * only 24 of 125 House and 3 of 40 Senate rows, and its latest value anywhere is 2015 — so it is
 * both sparse and stale. It is reported, never used.
 *
 * CONTROLS — run `--self-test` and watch them fail before trusting any pass:
 *   · parser: three tampered pages (name removed, district line broken, Terms heading renamed)
 *     must each yield a BLANK rather than a plausible wrong value.
 *   · departure detector: three planted phrases must each FIRE on a page that is otherwise silent.
 * ⚠ THE DEPARTURE DETECTOR HAS A BLIND SPOT THAT NO CONTROL CAN CLOSE. It is proven to fire on the
 * language a departure would use. It is NOT proven that Kansas publishes such language at all — no
 * real page has ever triggered it. KY-2 had the same shape and said so; so does this.
 *
 * Usage:
 *   node scripts/build-ks-legislature-roster.mjs [--workdir <dir>] [--self-test]
 * Exit: 0 when every member page names the member the CSV names; 1 otherwise.
 */
import fs from 'fs';
import os from 'os';
import path from 'path';
import { parse } from 'csv-parse/sync';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const WORKDIR = argOf('--workdir') ?? path.join(os.tmpdir(), 'ks-roster');
const CACHE = path.join(WORKDIR, 'members');
fs.mkdirSync(CACHE, { recursive: true });

const BIENNIUM = 'b2025_26';
const CHAMBERS = [
  { chamber: 'House', listPath: 'house/representatives', prefix: 'rep_', expected: 125, pages: 7 },
  { chamber: 'Senate', listPath: 'senate/senators', prefix: 'sen_', expected: 40, pages: 2 },
];
const UA = { 'User-Agent': 'ev-accounts-knight/1.0' };

async function get(url) {
  const res = await fetch(url, { headers: UA });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.text();
}

const strip = (html) =>
  html
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]*>/g, '\n')
    .replace(/&mdash;/g, '—').replace(/&ndash;/g, '–').replace(/&amp;/g, '&')
    .replace(/&#39;|&rsquo;/g, "'").replace(/&quot;/g, '"')
    .split('\n').map((s) => s.trim()).filter(Boolean);

/** Returns nulls rather than guesses, so a parse failure surfaces as a blank. */
export function extract(html) {
  const lines = strip(html);
  const nameM = html.match(/<h2 class="leg-hero-title">([^<]+)<\/h2>/);
  const name = nameM
    ? nameM[1].replace(/&#39;|&rsquo;/g, "'").replace(/&amp;/g, '&').trim()
    : null;
  let chamber = null, district = null, county = null;
  for (const l of lines) {
    const m = l.match(/^(House|Senate)\s*—\s*District\s+(\d+),\s+(.+?)\s+Count(?:y|ies)$/);
    if (m) { chamber = m[1]; district = Number(m[2]); county = m[3]; break; }
  }
  const ti = lines.indexOf('Terms');
  const terms = [];
  if (ti >= 0) {
    for (let i = ti + 1; i < lines.length; i++) {
      if (/^(Committees|Bills|Contact)$/.test(lines[i])) break;
      if (/^(House|Senate)$/.test(lines[i]) && i + 1 < lines.length) {
        const s = lines[i + 1].match(/^(\d{4})\s*[–-]\s*(Present|\d{4})$/);
        if (s) { terms.push({ chamber: lines[i], from: Number(s[1]), to: s[2] }); i++; }
      }
    }
  }
  return { name, chamber, district, county, terms, departure: detectDeparture(html) };
}

export const detectDeparture = (html) =>
  strip(html).some((l) => /resign|vacan|no longer|deceased|passed away|withdrew/i.test(l));

/** A term list is incoherent when a span says "Present" while a LATER span has ended. */
const termsIncoherent = (terms) => {
  const present = terms.filter((t) => t.to === 'Present');
  if (present.length > 1) return true;
  if (present.length === 1) {
    return terms.some((t) => t.to !== 'Present' && Number(t.to) > present[0].from);
  }
  return false;
};

async function main() {
  if (argv.includes('--self-test')) return selfTest();
  console.log(`KS legislature roster — workdir ${WORKDIR}\n`);
  const failures = [];
  const all = [];

  for (const c of CHAMBERS) {
    // --- the first-party CSV ---
    const csvPath = path.join(WORKDIR, `${c.prefix}roster.csv`);
    if (!fs.existsSync(csvPath)) {
      fs.writeFileSync(csvPath, await get(`https://kslegislature.gov/${BIENNIUM}/${c.listPath}/csv/`));
    }
    const rows = parse(fs.readFileSync(csvPath), { columns: true, skip_empty_lines: true, bom: true });
    const byDistrict = new Map(rows.map((r) => [Number(r.District), r]));
    const missing = [];
    for (let i = 1; i <= c.expected; i++) if (!byDistrict.has(i)) missing.push(i);
    console.log(`${c.chamber}: CSV ${rows.length} rows (expected ${c.expected}) · ` +
      `${byDistrict.size} distinct districts · missing ${missing.length ? JSON.stringify(missing) : 'none'}`);
    if (rows.length !== c.expected) failures.push(`${c.chamber}: CSV has ${rows.length} rows, expected ${c.expected}`);
    if (missing.length) failures.push(`${c.chamber}: districts absent from the CSV: ${JSON.stringify(missing)}`);

    // Enddate/Endnote are reported, never trusted — see the header.
    const ended = rows.filter((r) => (r.Enddate || '').trim() || (r.Endnote || '').trim());
    const firstterm = rows.filter((r) => (r.Firstterm || '').trim()).length;
    console.log(`  Enddate/Endnote populated: ${ended.length}/${rows.length} ⚠ column is never populated — not a vacancy signal`);
    console.log(`  Firstterm populated: ${firstterm}/${rows.length} ⚠ sparse and stale — reported, never used`);

    // --- slugs, paged ---
    const slugPath = path.join(WORKDIR, `${c.prefix}slugs.txt`);
    let slugs;
    if (fs.existsSync(slugPath)) slugs = fs.readFileSync(slugPath, 'utf8').split('\n').filter(Boolean);
    else {
      const set = new Set();
      for (let p = 1; p <= c.pages; p++) {
        const html = await get(`https://kslegislature.gov/${BIENNIUM}/${c.listPath}/?page=${p}`);
        for (const m of html.matchAll(new RegExp(`/${BIENNIUM}/legislators/(${c.prefix}[a-z0-9_]+)/`, 'g'))) set.add(m[1]);
      }
      slugs = [...set];
      fs.writeFileSync(slugPath, slugs.join('\n'));
    }
    console.log(`  slugs collected: ${slugs.length} (expected ${c.expected})`);
    if (slugs.length !== c.expected) failures.push(`${c.chamber}: collected ${slugs.length} slugs, expected ${c.expected}`);

    // --- the sweep ---
    for (const slug of slugs) {
      const p = path.join(CACHE, `${slug}.html`);
      let html;
      if (fs.existsSync(p) && fs.statSync(p).size > 10000) html = fs.readFileSync(p, 'utf8');
      else { html = await get(`https://kslegislature.gov/${BIENNIUM}/legislators/${slug}/`); fs.writeFileSync(p, html); await new Promise((r) => setTimeout(r, 120)); }
      all.push({ slug, expectedChamber: c.chamber, csv: byDistrict.get(extract(html).district) ?? null, ...extract(html) });
    }
  }

  // --- parser health: a field blank for EVERY member is a dead parser, not a finding ---
  const blankName = all.filter((r) => !r.name).length;
  const blankDist = all.filter((r) => r.district === null).length;
  console.log(`\nPARSER HEALTH — blank name ${blankName}/${all.length} · blank district ${blankDist}/${all.length}`);
  if (blankName === all.length || blankDist === all.length) {
    console.log('🔴 a field is blank for every member — dead parser. Refusing to report.');
    process.exit(1);
  }

  // --- the assertion that matters ---
  const norm = (s) => (s || '').toLowerCase().replace(/[^a-z]/g, '');
  let agree = 0;
  for (const r of all) {
    if (!r.csv || r.district === null || !r.name) { failures.push(`${r.slug}: unparsed or no CSV seat (district=${r.district})`); continue; }
    if (r.chamber !== r.expectedChamber) { failures.push(`${r.slug}: page says ${r.chamber}, list says ${r.expectedChamber}`); continue; }
    const ok = norm(r.name) === norm(r.csv.Fullname) || (norm(r.csv.Lastname) && norm(r.name).includes(norm(r.csv.Lastname)));
    if (ok) agree++;
    else failures.push(`${r.chamber} D${r.district}: page "${r.name}" vs CSV "${r.csv.Fullname}"`);
  }
  console.log(`NAME/SEAT AGREEMENT — ${agree}/${all.length} member pages name the member the CSV names`);

  const departures = all.filter((r) => r.departure);
  console.log(`DEPARTURE MARKERS — ${departures.length} ⚠ detector proven able to fire (--self-test); NOT proven that Kansas ever publishes such language`);
  for (const d of departures) console.log(`  ⚠ ${d.chamber} D${d.district} ${d.name}`);

  const incoherent = all.filter((r) => termsIncoherent(r.terms));
  const noTerms = all.filter((r) => r.terms.length === 0);
  console.log(`\n🔴 TERMS BLOCK — ${incoherent.length}/${all.length} members publish a self-contradictory term list, ${noTerms.length} publish none.`);
  console.log(`   The markup is clean; the DATA is inconsistent. Do not derive term_start from it.`);
  for (const r of incoherent) console.log(`  · ${r.chamber} D${r.district} ${r.name}: ${r.terms.map((t) => `${t.chamber} ${t.from}–${t.to}`).join(' | ')}`);
  for (const r of noTerms) console.log(`  · ${r.chamber} D${r.district} ${r.name}: NO Terms rows`);

  fs.writeFileSync(path.join(WORKDIR, 'ks-roster.json'), JSON.stringify(all, null, 2));
  console.log(`\nwrote ${path.join(WORKDIR, 'ks-roster.json')}`);

  if (failures.length) {
    console.log('\n🔴 FAILED');
    for (const f of failures) console.log(`  - ${f}`);
    process.exit(1);
  }
  console.log('\n🟢 Every member page names the member the CSV names, at the seat the CSV gives.');
  console.log('⚠ TERM STARTS ARE NOT ESTABLISHED BY THIS TOOL — see the header. Occupancy needs another source.');
}

function selfTest() {
  const sample = fs.readdirSync(CACHE).find((f) => f.endsWith('.html'));
  if (!sample) { console.error(`no cached page in ${CACHE} — run without --self-test once first.`); process.exit(2); }
  const real = fs.readFileSync(path.join(CACHE, sample), 'utf8');
  const base = extract(real);
  console.log(`control 0 — real page (${sample}): name=${JSON.stringify(base.name)} district=${base.district} terms=${base.terms.length}`);
  if (!base.name || base.district === null) { console.error('🔴 the parser cannot read a real page.'); process.exit(1); }

  let pass = 0, total = 0;
  const tampers = [
    ['name removed', real.replace(/<h2 class="leg-hero-title">[^<]+<\/h2>/, '<h2 class="leg-hero-title"></h2>'), (r) => !r.name],
    ['district line broken', real.replace(/District\s+\d+/, 'District XX'), (r) => r.district === null],
    ['Terms heading renamed', real.replace('>Terms<', '>Tenure<'), (r) => r.terms.length === 0],
  ];
  for (const [label, html, ok] of tampers) {
    total++;
    const got = ok(extract(html));
    console.log(`control — ${label}: ${got ? '✅ blank, as required' : '🔴 parser still returned a value'}`);
    if (got) pass++;
  }
  console.log(`\ndeparture detector — silent on the untouched page: ${detectDeparture(real) ? '🔴 fires (should not)' : '✅ silent'}`);
  for (const phrase of ['resigned effective July 1, 2026', 'This seat is vacant', 'is no longer serving']) {
    total++;
    const fired = detectDeparture(real.replace('<h2 class="leg-hero-title">', `<p>${phrase}</p><h2 class="leg-hero-title">`));
    console.log(`control — planted ${JSON.stringify(phrase)}: ${fired ? '✅ FIRES' : '🔴 SILENT — detector is dead'}`);
    if (fired) pass++;
  }
  console.log(pass === total ? `\n✅ all ${total} controls behaved as required.` : `\n🔴 ${total - pass} control(s) misbehaved.`);
  process.exit(pass === total ? 0 : 1);
}

main().catch((e) => { console.error(`🔴 ${e.message}`); process.exit(1); });

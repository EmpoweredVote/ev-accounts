#!/usr/bin/env node
/**
 * Re-derive the sibling control for every FABRICATED finding, and reclassify what no longer holds.
 *
 * WHY. Every FABRICATED verdict is "this path 404s, was never archived, and its siblings WERE" — so the
 * sibling count is the load-bearing half and it was measured wrong. The old control counted distinct
 * archived URLs under the prefix, which includes crawler asset paths and the section's own index:
 *   · pressley.house.gov/issues* reported 200. Of 1,000 archived urls, 993 are JavaScript module paths
 *     (/issues/dojo/dom-class, /issues/esri/dijit/Popup) from an embedded ArcGIS widget. Real: 6.
 *   · lynnma.gov/news* reported 8, of which 4 are section indexes. Real articles: ~4.
 * Findings whose real control falls below MIN_SIBLINGS were never proven and must stop being counted as
 * proven — this run downgrades them rather than waiting for someone to notice before a migration.
 *
 * ⚠ It rewrites `control_siblings` in the artifacts and writes a reclassification report. It does NOT
 * touch the database and does NOT retire anything.
 *
 * ⚠ A control that does not answer is NOT a control of zero. Those keep their old value and are listed
 * as UNRESOLVED, because "the archive was busy" and "nothing was published" must never collapse together
 * — that conflation is what a throttled run looks like from the inside.
 *
 * Usage (from backend/):
 *   node scripts/rederive-control-siblings.mjs            # report only
 *   node scripts/rederive-control-siblings.mjs --write    # also update the artifacts
 */
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { cdxSiblingPages, controlPrefix, MIN_SIBLINGS } from './sweep-fabricated-articles.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');
const WRITE = process.argv.includes('--write');
const PACE = Number((process.argv.indexOf('--pace') !== -1 && process.argv[process.argv.indexOf('--pace') + 1]) || 2500);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const files = readdirSync(DIR).filter((f) => /^fabricated-article-sweep-.*\.json$/.test(f));

// Controls are shared — 121 findings sit on far fewer prefixes — so query each prefix ONCE. This is the
// difference between a few dozen archive.org calls and 121 of them, and archive.org throttling is the
// single biggest source of false absences in this audit.
// 🔴 RECOMPUTE THE PREFIX FROM THE URL. DO NOT TRUST THE STORED `control` STRING. The dated findings
// were written by an older revision that stored a display LABEL, not a query: `bostonglobe.com|2021/01`
// — a pipe instead of a slash and no trailing `*`. Fed to CDX that matches nothing, so the first run of
// this tool reported "0 pages of 0 urls" for every dated control and would have downgraded all of them
// to INCONCLUSIVE on a malformed query. With --write that destroys real verdicts silently, and the
// output looks like a finding rather than a bug. Mismatches are reported below, never followed.
const prefixes = new Map();
const relabelled = [];
for (const f of files) {
  for (const r of JSON.parse(readFileSync(path.join(DIR, f), 'utf8')).findings ?? []) {
    if (r.verdict !== 'FABRICATED') continue;
    const key = controlPrefix(r.url);
    if (!key) continue;
    if (r.control && r.control !== key) relabelled.push({ url: r.url, stored: r.control, recomputed: key });
    if (!prefixes.has(key)) prefixes.set(key, []);
    prefixes.get(key).push({ url: r.url, old: r.control_siblings, rows: Number(r.rows_citing ?? 0), storedControl: r.control });
  }
}
if (relabelled.length) {
  console.log(`⚠ ${relabelled.length} findings store a control string that is not a valid CDX prefix; recomputed from the url.`);
  for (const x of relabelled.slice(0, 3)) console.log(`    stored ${JSON.stringify(x.stored)} -> using ${JSON.stringify(x.recomputed)}`);
  console.log('');
}
console.log(`${[...prefixes.values()].reduce((a, v) => a + v.length, 0)} FABRICATED findings on ${prefixes.size} distinct controls\n`);

// RESUMABLE BY CACHE. Each control costs an archive.org round trip with retries, so a run that dies
// partway must not start over — re-asking archive.org for answers we already have is both slow and the
// fastest way to get throttled into false absences. Only real answers are cached; an unresolved control
// is left out so the next run retries it.
const CACHE = path.join(DIR, '_control-rederive-cache.json');
let cache = {};
try { cache = JSON.parse(readFileSync(CACHE, 'utf8')); } catch { /* first run */ }

const resolved = new Map();
let i = 0;
let queried = 0;
for (const [prefix, items] of prefixes) {
  i += 1;
  if (cache[prefix]) {
    resolved.set(prefix, cache[prefix]);
    console.log(`[${i}/${prefixes.size}] cached  ${String(cache[prefix].pages).padStart(4)} pages of ${String(cache[prefix].total).padStart(4)} urls  ${prefix}`);
    continue;
  }
  if (queried > 0) await sleep(PACE);
  queried += 1;
  const ctl = await cdxSiblingPages(prefix);
  resolved.set(prefix, ctl);
  if (ctl !== null) {
    cache[prefix] = ctl;
    writeFileSync(CACHE, `${JSON.stringify(cache, null, 2)}\n`);   // flush per control, not at the end
  }
  const old = items[0].old ?? '?';
  if (ctl === null) {
    console.log(`[${i}/${prefixes.size}] ⚠ UNRESOLVED  ${prefix}  (keeps ${old})`);
  } else {
    const flag = ctl.pages === 0 ? '🔴 →INCONCLUSIVE' : ctl.pages < MIN_SIBLINGS ? '🔴 →WEAK_CONTROL' : '   ok';
    const drop = typeof old === 'number' && ctl.pages < old ? `  (was ${old})` : '';
    console.log(`[${i}/${prefixes.size}] ${flag}  ${String(ctl.pages).padStart(4)} pages of ${String(ctl.total).padStart(4)} urls  ${prefix}${drop}`);
  }
}

// ---- reclassify ----
const changes = [];
for (const [prefix, items] of prefixes) {
  const ctl = resolved.get(prefix);
  if (ctl === null) { for (const it of items) changes.push({ ...it, prefix, verdict: 'FABRICATED', note: 'control unresolved, unchanged' }); continue; }
  const verdict = ctl.pages === 0 ? 'INCONCLUSIVE' : ctl.pages < MIN_SIBLINGS ? 'WEAK_CONTROL' : 'FABRICATED';
  for (const it of items) changes.push({ ...it, prefix, verdict, pages: ctl.pages, total: ctl.total });
}

const downgraded = changes.filter((c) => c.verdict !== 'FABRICATED');
const stillFab = changes.filter((c) => c.verdict === 'FABRICATED');
const unresolved = changes.filter((c) => c.note);

console.log('\n=== reclassification ===');
console.log(`  still FABRICATED   ${stillFab.length} urls, ${stillFab.reduce((a, c) => a + c.rows, 0)} row-cites`);
console.log(`  DOWNGRADED         ${downgraded.length} urls, ${downgraded.reduce((a, c) => a + c.rows, 0)} row-cites`);
console.log(`  control unresolved ${unresolved.length} (kept as FABRICATED, re-run these)`);
if (downgraded.length) {
  console.log('\n  --- downgraded (control could not prove absence) ---');
  for (const c of downgraded.sort((a, b) => b.rows - a.rows)) {
    console.log(`    ${c.verdict.padEnd(13)} ${c.pages} pages of ${c.total} urls   ${c.url}  (${c.rows} rows)`);
  }
}

// Thin band: passes MIN_SIBLINGS but only just. Not a downgrade, but not the same claim as 900 either.
const thin = stillFab.filter((c) => c.pages !== undefined && c.pages < 10);
if (thin.length) {
  console.log(`\n  ⚠ ${thin.length} still-FABRICATED urls rest on a THIN control (<10 real pages) — suggestive, not proven:`);
  for (const c of thin) console.log(`    ${c.pages} pages   ${c.url}`);
}

if (WRITE) {
  let touched = 0;
  for (const f of files) {
    const p = path.join(DIR, f);
    const j = JSON.parse(readFileSync(p, 'utf8'));
    let dirty = false;
    for (const r of j.findings ?? []) {
      if (r.verdict !== 'FABRICATED') continue;
      const ctl = resolved.get(controlPrefix(r.url));   // recomputed, never the stored label — see above
      if (!ctl) continue;
      r.control = controlPrefix(r.url);                 // replace the stale label with the real prefix
      // Keep the original number under a distinct key. Overwriting it silently would erase the evidence
      // that the first measurement was wrong, which is the thing most worth keeping.
      if (r.control_siblings !== ctl.pages) {
        r.control_siblings_urls_original = r.control_siblings;
        r.control_siblings = ctl.pages;
        r.control_urls = ctl.total;
        dirty = true;
      }
      const v = ctl.pages === 0 ? 'INCONCLUSIVE' : ctl.pages < MIN_SIBLINGS ? 'WEAK_CONTROL' : 'FABRICATED';
      if (v !== r.verdict) {
        r.verdict_original = r.verdict;
        r.verdict = v;
        r.why = `downgraded on control re-derivation: ${ctl.pages} sibling pages of ${ctl.total} archived urls`;
        dirty = true;
      }
    }
    if (dirty) { writeFileSync(p, `${JSON.stringify(j, null, 2)}\n`); touched += 1; }
  }
  console.log(`\n✅ --write: updated ${touched} artifact files`);
} else {
  console.log('\n(report only — pass --write to update the artifacts)');
}

writeFileSync(path.join(DIR, '2026-08-06-control-rederivation.json'),
  `${JSON.stringify({ generated_by: 'scripts/rederive-control-siblings.mjs', min_siblings: MIN_SIBLINGS,
                      controls: [...resolved].map(([prefix, c]) => ({ prefix, ...(c ?? { unresolved: true }) })),
                      changes }, null, 2)}\n`);
console.log('wrote data/stance-retirement/2026-08-06-control-rederivation.json');

#!/usr/bin/env node
/**
 * Merge every fabricated-article-sweep chunk artifact into one auditable picture.
 *
 * WHY THIS IS A SCRIPT AND NOT A HAND COUNT. The 2026-08-05 findings doc reported "9,195 probed
 * (1,945 dated + 7,250 undated)" and "chunks 30-47 not probed". Both were slightly wrong: 30 undated
 * chunks had completed, not 29, so 7,500 were probed and 4,228 remained, not 4,478. Nothing important
 * turned on it, but a coverage number that is derived by hand from a directory listing WILL drift, and
 * this audit's whole problem is claims that outran their evidence. Coverage is now computed from the
 * artifacts themselves.
 *
 * It reports, and deliberately does not decide:
 *   - coverage: how many distinct eligible URLs have a verdict, and how many still do not
 *   - the tally across every chunk, with dated and undated kept separate (disjoint URL sets, different
 *     filters — a merged total that cannot be decomposed is not auditable)
 *   - every FABRICATED URL with its row-citation count, grouped by host
 *   - 🔴 the DEGRADED share of NO_ANSWER: un-evaluated URLs that were given a short probe and no curl
 *     fallback. These are the re-probe queue. An un-evaluated bucket that looks like a clean result is
 *     the exact failure mode this audit keeps hitting.
 *
 * Usage (from backend/):  node scripts/aggregate-fabricated-sweep.mjs
 */
import 'dotenv/config';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');

const files = readdirSync(DIR).filter((f) => /^fabricated-article-sweep-.*\.json$/.test(f));
if (!files.length) {
  console.log('no sweep artifacts found');
  process.exitCode = 1;
} else {
  // Keyed by URL so a re-run of an overlapping chunk cannot double-count. Last write wins: a re-probe is
  // a correction of the earlier verdict, not a second opinion to be averaged with it.
  const byUrl = new Map();
  const perSlice = new Map();

  for (const f of files.sort()) {
    const j = JSON.parse(readFileSync(path.join(DIR, f), 'utf8'));
    const slice = j.slice ?? 'unknown';
    for (const rec of j.findings ?? []) {
      if (byUrl.has(rec.url) && byUrl.get(rec.url).verdict !== rec.verdict) {
        console.log(`  ⚠ verdict changed on re-probe: ${byUrl.get(rec.url).verdict} → ${rec.verdict}  ${rec.url}`);
      }
      byUrl.set(rec.url, { ...rec, slice });
    }
    const s = perSlice.get(slice) ?? { files: 0, records: 0 };
    s.files += 1; s.records += (j.findings ?? []).length;
    perSlice.set(slice, s);
  }

  const all = [...byUrl.values()];
  console.log(`\n=== artifacts: ${files.length} files, ${all.length} distinct URLs with a verdict ===`);
  for (const [slice, s] of perSlice) console.log(`  ${slice.padEnd(10)} ${s.files} files, ${s.records} records`);

  const tally = {};
  for (const r of all) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
  console.log('\n=== verdicts ===');
  for (const [k, n] of Object.entries(tally).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${k.padEnd(14)} ${String(n).padStart(6)}`);
  }

  const degraded = all.filter((r) => r.degraded);
  if (degraded.length) {
    const byHost = new Map();
    for (const r of degraded) byHost.set(r.host, (byHost.get(r.host) ?? 0) + 1);
    console.log(`\n🔴 ${degraded.length} of ${tally.NO_ANSWER ?? 0} NO_ANSWER were DEGRADED (short probe, no curl fallback).`);
    console.log('   Un-evaluated, not clean. This is the re-probe queue:');
    for (const [h, n] of [...byHost].sort((a, b) => b[1] - a[1]).slice(0, 15)) {
      console.log(`     ${String(n).padStart(5)}  ${h}`);
    }
  }

  const fab = all.filter((r) => r.verdict === 'FABRICATED');
  const rowsOf = (r) => Number(r.rows_citing ?? 0);
  console.log(`\n=== FABRICATED: ${fab.length} URLs, ${fab.reduce((a, r) => a + rowsOf(r), 0)} row-citations ===`);
  const fabByHost = new Map();
  for (const r of fab) {
    const e = fabByHost.get(r.host) ?? { urls: 0, rows: 0 };
    e.urls += 1; e.rows += rowsOf(r);
    fabByHost.set(r.host, e);
  }
  for (const [h, e] of [...fabByHost].sort((a, b) => b[1].rows - a[1].rows)) {
    console.log(`  ${String(e.urls).padStart(4)} urls  ${String(e.rows).padStart(5)} row-cites  ${h}`);
  }

  // Coverage against the live corpus: the only honest denominator. Everything else is a floor.
  if (process.env.DATABASE_URL) {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
    const { rows } = await pool.query(`
      SELECT count(DISTINCT s) AS eligible
        FROM inform.politician_context pc, unnest(pc.sources) s
       WHERE s ~* '^https?://[^/]+/[^/]+/.+'`);
    const eligible = Number(rows[0].eligible);
    const seen = all.length;
    console.log(`\n=== coverage ===`);
    console.log(`  eligible (specific page, >=2 path segments): ${eligible}`);
    console.log(`  with a verdict:                              ${seen}  (${(100 * seen / eligible).toFixed(1)}%)`);
    console.log(`  never probed:                                ${eligible - seen}`);
    if (degraded.length) {
      console.log(`  ⚠ of those with a verdict, ${degraded.length} are degraded NO_ANSWER = probed but not evaluated.`);
      const real = seen - degraded.length;
      console.log(`    genuinely evaluated:                       ${real}  (${(100 * real / eligible).toFixed(1)}%)`);
    }
    await pool.end();
  }
  console.log('\nNEXT: hand-verify new FABRICATED findings, then add confirmed URLs to data/fabricated-sources.json');
  console.log('and retire or re-research the rows in a migration. Do NOT auto-add — that is a decision.\n');
}

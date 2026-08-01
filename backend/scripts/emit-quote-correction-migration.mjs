#!/usr/bin/env node
/**
 * Emit the reasoning-correction migration and its rollback record from the hand-written proposals
 * file. Generated rather than hand-written because 16 SQL string literals carrying apostrophes,
 * em-dashes and embedded quotations are exactly where a stray escape silently changes voter-facing
 * text -- and the text is the whole point of the change.
 *
 * 🔴 IT REFUSES TO EMIT ANYTHING IT CANNOT PROVE.
 *   - every `verbatim` string must still be present on the cited site (re-checked here, not trusted
 *     from the earlier run) -- otherwise the correction would install a fresh unverifiable quotation
 *   - every target row must exist with a non-empty reasoning, so the rollback record is real
 *   - no proposal may introduce `''` into stored text: a doubled apostrophe reads as a closing double
 *     quote to the extractor and silently discards the quotation (the Billy Nord bug)
 *
 * Usage (from backend/):
 *   node scripts/emit-quote-correction-migration.mjs <proposals.json> <migration.sql> <rollback.json>
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';
import { crawlSite } from './lib/site-crawl.mjs';
import { norm } from './lib/claim-match.mjs';

const [proposalsFile, sqlOut, rollbackOut] = process.argv.slice(2);
if (!proposalsFile || !sqlOut || !rollbackOut) {
  console.error('usage: emit-quote-correction-migration.mjs <proposals.json> <migration.sql> <rollback.json>');
  process.exit(2);
}
const { proposals } = JSON.parse(readFileSync(proposalsFile, 'utf8'));
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** SQL single-quoted literal. The ONLY escaping needed, and it is done in one place. */
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`;

const refusals = [];

// ---- 1. the stored text must not contain a doubled apostrophe -------------------------------
for (const p of proposals) {
  if (/''/.test(p.reasoning)) refusals.push(`${p.name}/${p.topic}: reasoning contains '' (reads as a closing double quote)`);
}

// ---- 2. every row must exist, and its current text is the rollback record --------------------
const { rows: current } = await pool.query(
  `SELECT pc.politician_id::text AS pid, pc.topic_id::text AS tid, pc.reasoning, pc.sources
     FROM inform.politician_context pc
     JOIN unnest($1::uuid[], $2::uuid[]) AS k(pid, tid)
       ON pc.politician_id = k.pid AND pc.topic_id = k.tid`,
  [proposals.map((p) => p.pid), proposals.map((p) => p.tid)],
);
await pool.end();
const byKey = new Map(current.map((r) => [`${r.pid}|${r.tid}`, r]));
for (const p of proposals) {
  const row = byKey.get(`${p.pid}|${p.tid}`);
  if (!row) { refusals.push(`${p.name}/${p.topic}: row not found in inform.politician_context`); continue; }
  if (!row.reasoning?.trim()) refusals.push(`${p.name}/${p.topic}: existing reasoning is empty`);
  if (row.reasoning === p.reasoning) refusals.push(`${p.name}/${p.topic}: proposed text is identical to current`);
}

// ---- 3. re-verify every replacement quote against the live site ------------------------------
const bySite = new Map();
for (const p of proposals) {
  if (!bySite.has(p.cited)) bySite.set(p.cited, []);
  bySite.get(p.cited).push(p);
}
for (const [site, rows] of bySite) {
  const s = await crawlSite(site, { hostDelay: 900, maxPages: 8, minBody: 600, cacheTtlHours: 24 });
  if (!s.ok) { for (const r of rows) refusals.push(`${r.name}/${r.topic}: site unreadable (${s.reason})`); continue; }
  const hay = norm(s.pages.map((pg) => `${pg.body} ${pg.chrome ?? ''}`).join(' '));
  for (const r of rows) {
    for (const q of r.verbatim) {
      if (!hay.includes(norm(q))) refusals.push(`${r.name}/${r.topic}: not verbatim on site -> "${q}"`);
    }
  }
}

if (refusals.length) {
  console.error(`REFUSED — ${refusals.length} problem(s); nothing written:`);
  for (const r of refusals) console.error(`  ✗ ${r}`);
  process.exit(1);
}

// ---- 4. rollback record, then the migration --------------------------------------------------
writeFileSync(rollbackOut, `${JSON.stringify({
  _comment: 'Rollback record for the quote-correction migration: the EXACT prior reasoning for every '
    + 'row it rewrites. Restore by UPDATE ... SET reasoning = <before> for each key.',
  generated: new Date().toISOString().slice(0, 10),
  rows: proposals.map((p) => ({
    pid: p.pid, tid: p.tid, name: p.name, topic: p.topic, cited: p.cited,
    before: byKey.get(`${p.pid}|${p.tid}`).reasoning,
    after: p.reasoning,
    why: p.was,
  })),
}, null, 2)}\n`);

const L = [];
L.push('-- 1518_correct_primary_site_quote_text.sql');
L.push('--');
L.push('-- Correct the QUOTATIONS in 16 published stance rows whose cited campaign site supports the');
L.push('-- claim but does not contain the words the row put in quotation marks. NOTHING IS RETIRED HERE');
L.push('-- and no stance VALUE changes -- only the text a voter reads.');
L.push(`--   Rollback record: data/stance-retirement/${rollbackOut.split(/[\\/]/).pop()}`);
L.push(`--   Proposals:       data/stance-retirement/${proposalsFile.split(/[\\/]/).pop()}`);
L.push('--   Reading queue:   data/stance-retirement/2026-08-01-quote-corrections.md');
L.push('--');
L.push('-- WHY THIS MATTERS MORE THAN THE GATE COUNTS. inform.politician_context.reasoning is VOTER-FACING');
L.push('-- (Citations.jsx renders it under "Why this position?"). Quotation marks around words the source');
L.push('-- never said are a fabricated quote on a live candidate card, whether or not the stance is right.');
L.push('--');
L.push('-- 🔴 THIS IS A CORRECTION PASS, NOT A RETIREMENT PASS. Every row below KEEPS its stance and its');
L.push('-- source; all that changes is that the quoted words are now the page\'s own. Each replacement');
L.push('-- string was re-fetched and matched against the live site by');
L.push('-- scripts/emit-quote-correction-migration.mjs, which refuses to emit if any string is absent.');
L.push('');
for (const p of proposals) {
  L.push(`-- ${p.name} / ${p.topic}: ${p.was}`);
}
L.push('');
L.push('BEGIN;');
L.push('');
for (const p of proposals) {
  L.push(`-- ${p.name} / ${p.topic} — ${p.cited}`);
  L.push(`UPDATE inform.politician_context SET reasoning = ${lit(p.reasoning)}`);
  L.push(` WHERE politician_id = ${lit(p.pid)} AND topic_id = ${lit(p.tid)};`);
  L.push('');
}
L.push('DO $$');
L.push('DECLARE');
L.push('  v_bad int;');
L.push('BEGIN');
L.push('  -- Every row must now carry its corrected text, and none may be left with the old wording.');
for (const p of proposals) {
  L.push(`  SELECT count(*) INTO v_bad FROM inform.politician_context`);
  L.push(`   WHERE politician_id = ${lit(p.pid)} AND topic_id = ${lit(p.tid)}`);
  L.push(`     AND reasoning IS DISTINCT FROM ${lit(p.reasoning)};`);
  L.push(`  IF v_bad <> 0 THEN RAISE EXCEPTION '${p.name.replace(/'/g, "''")} / ${p.topic.replace(/'/g, "''")} not corrected'; END IF;`);
}
L.push('');
L.push('  -- No corrected row may have lost its sources or its stance.');
L.push('  SELECT count(*) INTO v_bad FROM inform.politician_context pc');
L.push('    JOIN unnest(ARRAY[');
L.push(proposals.map((p) => `      ${lit(p.pid)}::uuid`).join(',\n'));
L.push('    ], ARRAY[');
L.push(proposals.map((p) => `      ${lit(p.tid)}::uuid`).join(',\n'));
L.push('    ]) AS k(pid, tid) ON pc.politician_id = k.pid AND pc.topic_id = k.tid');
L.push('   WHERE cardinality(pc.sources) = 0;');
L.push("  IF v_bad <> 0 THEN RAISE EXCEPTION 'a corrected row lost its sources'; END IF;");
L.push('END $$;');
L.push('');
L.push('COMMIT;');
writeFileSync(sqlOut, `${L.join('\n')}\n`);

console.log(`verified ${proposals.length} proposals; wrote:`);
console.log(`  ${sqlOut}`);
console.log(`  ${rollbackOut}`);

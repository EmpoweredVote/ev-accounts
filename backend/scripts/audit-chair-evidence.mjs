#!/usr/bin/env node
/**
 * How many of the chairs corrected in migs 1726/1727/1729/1730 are EVIDENCED FOR THAT CHAIR?
 *
 * 🔑 THE STANDARD: the five chairs are five DISTINCT stances, not a polarity scale. To seat a
 * politician in a chair you need evidence describing THAT chair, with sources. A citation that
 * establishes only the DIRECTION (pro/anti) under-determines which of the two or three chairs on
 * that side the person actually holds.
 *
 * This measures the gap those four migrations left: chairs are now non-contradictory, but
 * "non-contradictory" is a weaker claim than "evidenced".
 *
 * 🔴 Reads only.  node scripts/audit-chair-evidence.mjs
 */
import fs from 'node:fs';
import pg from 'pg';

const FILES = [
  ['1726', 'data/stance-retirement/2026-08-12-medicaid-misaligned-1726-rollback.json'],
  ['1727', 'data/stance-retirement/2026-08-12-batch-inversion-1727-rollback.json'],
  ['1729', 'data/stance-retirement/2026-08-12-national-rescan-1729-rollback.json'],
  ['1730', 'data/stance-retirement/2026-08-12-reversed-ladder-1730-rollback.json'],
];

const pairs = [];
for (const [mig, f] of FILES) {
  const j = JSON.parse(fs.readFileSync(`backend/${f}`, 'utf8'));
  for (const r of j.rows) pairs.push({ mig, pid: r.politician_id, tid: r.topic_id, chair: r.chair_after });
}

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// A source that could evidence a SPECIFIC chair: a bill, a roll call, an ordinance, a hearing
// record. A bio or an aggregator profile can establish direction at best.
const INSTRUMENT = /(legislature|mgaleg|leginfo|congress\.gov|govtrack|clerk\.house|senate\.gov\/legislative|\/bill|\/legislation|rollcall|roll_call|ordinance|agenda|minutes|\.pdf|capitol|legiscan)/i;
const AGGREGATOR = /(ballotpedia|wikipedia|ontheissues|votesmart|isidewith|opensecrets|followthemoney)/i;

const out = { total: 0, instrument: 0, aggregator_only: 0, other_only: 0, none: 0 };
const byMig = {};

for (const p of pairs) {
  const { rows } = await pool.query(
    'SELECT reasoning, sources FROM inform.politician_context WHERE politician_id=$1 AND topic_id=$2',
    [p.pid, p.tid],
  );
  const src = rows[0]?.sources || [];
  byMig[p.mig] ??= { total: 0, instrument: 0, aggregator_only: 0, other_only: 0, none: 0 };
  out.total++; byMig[p.mig].total++;
  let bucket;
  if (!src.length) bucket = 'none';
  else if (src.some((s) => INSTRUMENT.test(s))) bucket = 'instrument';
  else if (src.some((s) => AGGREGATOR.test(s))) bucket = 'aggregator_only';
  else bucket = 'other_only';
  out[bucket]++; byMig[p.mig][bucket]++;
}
await pool.end();

const pct = (n) => `${((n / out.total) * 100).toFixed(0)}%`;
console.log(`chairs corrected across 1726/1727/1729/1730: ${out.total}`);
console.log(`  cites a primary instrument (bill/roll call/ordinance/minutes): ${out.instrument}  ${pct(out.instrument)}`);
console.log(`  aggregator/bio only (Ballotpedia, Wikipedia, OnTheIssues, …):  ${out.aggregator_only}  ${pct(out.aggregator_only)}`);
console.log(`  other sources only:                                           ${out.other_only}  ${pct(out.other_only)}`);
console.log(`  no sources at all:                                            ${out.none}  ${pct(out.none)}`);
console.log('\nby migration:');
for (const [m, v] of Object.entries(byMig)) {
  console.log(`  ${m}: ${String(v.total).padStart(3)} rows — instrument ${v.instrument}, aggregator-only ${v.aggregator_only}, other ${v.other_only}, none ${v.none}`);
}

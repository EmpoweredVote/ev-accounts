#!/usr/bin/env node
/**
 * Blast radius of a set of fabricated URLs: what retiring them would actually cost.
 *
 * WHY IT IS A SCRIPT. The 2026-08-05 findings doc worked this out by hand for 87 URLs and its own
 * conclusion was that "the three-way split must be computed in the migration rather than copied from
 * here". The same applies to the numbers that justify the migration. Hand-derived blast radius is how a
 * chip gets flipped on a government that still had coverage, or missed on one that did not.
 *
 * THE SPLIT IT REPORTS, which is the shape of any remedy:
 *   SOLE_SOURCED   — the row cites nothing but fabricated URLs. Unambiguous retirement.
 *   NAV_ONLY       — every surviving citation is a nav/landing page, which the 2026-08-04 operator
 *                    ruling already excludes as coverage. Retirement by transitive application (mig 1562).
 *   HAS_COSOURCE   — a real citation survives. STRIP the fabricated citation, do NOT retire the row.
 *
 * ⚠ It reports. It does not decide, and it writes nothing to the database.
 *
 * Occupancy is joined through office_current_holder -> offices -> chambers -> governments. There is no
 * offices.government_id and politicians.office_id is not the occupancy record.
 *
 * Usage (from backend/):
 *   node scripts/fabricated-impact-report.mjs                     # every FABRICATED in every artifact
 *   node scripts/fabricated-impact-report.mjs --since-doc         # only URLs not in the 2026-08-05 87
 */
import 'dotenv/config';
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');
const argv = process.argv.slice(2);

// A nav/landing page for this purpose = at most one path segment, i.e. no specific page. Same rule the
// sweep uses for eligibility, applied to the SURVIVING citations rather than the fabricated one.
const isNavPage = (u) => {
  try { return new URL(u).pathname.split('/').filter(Boolean).length <= 1; } catch { return false; }
};

const fabricated = new Map();   // url -> {control_siblings, slice}
for (const f of readdirSync(DIR).filter((x) => /^fabricated-article-sweep-.*\.json$/.test(x))) {
  const j = JSON.parse(readFileSync(path.join(DIR, f), 'utf8'));
  for (const r of (j.findings ?? []).filter((y) => y.verdict === 'FABRICATED')) {
    fabricated.set(r.url, { control_siblings: r.control_siblings, control: r.control, host: r.host });
  }
}

let urls = [...fabricated.keys()];
if (argv.includes('--since-doc')) {
  const prior = path.join(DIR, '2026-08-05-fabricated-confirmed-87.json');
  try {
    const known = new Set(JSON.parse(readFileSync(prior, 'utf8')).map?.((x) => x.url ?? x) ?? []);
    urls = urls.filter((u) => !known.has(u));
    console.log(`--since-doc: ${known.size} previously confirmed excluded\n`);
  } catch { console.log(`--since-doc: could not read ${path.basename(prior)}, reporting all\n`); }
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows } = await pool.query(`
  SELECT pc.politician_id, pc.topic_id, pc.sources, p.full_name AS politician,
         g.name AS government, o.title AS office
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id
    LEFT JOIN LATERAL (
      SELECT o2.title, o2.chamber_id
        FROM essentials.office_current_holder och
        JOIN essentials.offices o2 ON o2.id = och.office_id
       WHERE och.politician_id = pc.politician_id
       ORDER BY o2.title LIMIT 1
    ) o ON true
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
   WHERE pc.sources && $1::text[]`, [urls]);

const classify = (sources) => {
  const survivors = sources.filter((s) => !fabricated.has(s));
  if (!survivors.length) return 'SOLE_SOURCED';
  if (survivors.every(isNavPage)) return 'NAV_ONLY';
  return 'HAS_COSOURCE';
};

const split = { SOLE_SOURCED: 0, NAV_ONLY: 0, HAS_COSOURCE: 0 };
const pols = new Map();
const govs = new Map();
for (const r of rows) {
  const k = classify(r.sources);
  split[k] += 1;
  const pe = pols.get(r.politician_id) ?? { name: r.politician, government: r.government, hit: 0, retire: 0 };
  pe.hit += 1;
  if (k !== 'HAS_COSOURCE') pe.retire += 1;
  pols.set(r.politician_id, pe);
  const ge = govs.get(r.government ?? '(unresolved)') ?? { rows: 0, pols: new Set() };
  ge.rows += 1; ge.pols.add(r.politician_id);
  govs.set(r.government ?? '(unresolved)', ge);
}

console.log(`=== ${urls.length} fabricated URLs cited by ${rows.length} stance rows, ${pols.size} politicians ===\n`);
console.log('--- remedy split (rows) ---');
console.log(`  SOLE_SOURCED   ${String(split.SOLE_SOURCED).padStart(5)}  retire — nothing else cited`);
console.log(`  NAV_ONLY       ${String(split.NAV_ONLY).padStart(5)}  retire — only nav/landing pages survive (2026-08-04 ruling)`);
console.log(`  HAS_COSOURCE   ${String(split.HAS_COSOURCE).padStart(5)}  STRIP the citation, keep the row`);

// Would-drop-to-zero needs the politician's WHOLE answer set, not just the rows in this finding set.
const zeroing = [];
const orphans = [];
for (const [id, e] of pols) {
  if (e.retire === 0) continue;
  const { rows: tot } = await pool.query(
    'SELECT count(*)::int AS n FROM inform.politician_answers WHERE politician_id = $1', [id]);
  // 🔴 total === 0 is NOT "would drop to zero" — they are already there. These are the orphan-context
  // class (voter-facing reasoning with no answer behind it, ~546 rows corpus-wide, still undiagnosed).
  // Counting them as coverage loss would overstate the blast radius and mis-drive a chip decision.
  if (tot[0].n === 0) orphans.push({ ...e, total: 0 });
  else if (tot[0].n <= e.retire) zeroing.push({ ...e, total: tot[0].n });
}
console.log(`\n--- politicians who would drop to ZERO answers: ${zeroing.length} ---`);
for (const z of zeroing.sort((a, b) => b.retire - a.retire)) {
  console.log(`  ${z.name} (${z.government ?? 'unresolved'}) — losing ${z.retire} of ${z.total}`);
}
if (orphans.length) {
  console.log(`\n--- ⚠ ${orphans.length} already at zero answers (orphan context rows, not a coverage loss) ---`);
  for (const o of orphans) console.log(`  ${o.name} (${o.government ?? 'unresolved'}) — ${o.retire} context row(s), 0 answers`);
}

console.log('\n--- by government (chip check) ---');
for (const [g, e] of [...govs].sort((a, b) => b[1].rows - a[1].rows)) {
  console.log(`  ${String(e.rows).padStart(4)} rows  ${String(e.pols.size).padStart(3)} pols  ${g}`);
}

// Control strength decides how much any of this is worth. A finding resting on 8 archived siblings is
// not the same claim as one resting on 200, and a single MIN_SIBLINGS threshold hides the difference.
console.log('\n--- evidence strength (archived siblings in the control) ---');
const buckets = { '5-9 (THIN)': 0, '10-49': 0, '50-199': 0, '200+': 0 };
for (const u of urls) {
  const n = fabricated.get(u).control_siblings ?? 0;
  buckets[n < 10 ? '5-9 (THIN)' : n < 50 ? '10-49' : n < 200 ? '50-199' : '200+'] += 1;
}
for (const [k, n] of Object.entries(buckets)) console.log(`  ${k.padEnd(12)} ${n} urls`);
const thin = urls.filter((u) => (fabricated.get(u).control_siblings ?? 0) < 10);
if (thin.length) {
  console.log('\n  ⚠ THIN-CONTROL urls — treat as suggestive, not proven:');
  for (const u of thin) console.log(`     ${fabricated.get(u).control_siblings} siblings  ${u}`);
}
await pool.end();

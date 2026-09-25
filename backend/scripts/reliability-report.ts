/**
 * reliability-report.ts — M1 (coder-vs-coder α, nominal) per stratum across every batch stored in
 * inform.stance_coder_labels (spec §3.1). Read-only. M2–M4 need blind gold, which starts in P2.
 * A row's stratum = the weakest evidence class any valid coder rested its chair on (spec §3.2).
 *   npx tsx scripts/reliability-report.ts [--codebook 0.2]
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { alphaNominal, chairCategory, type Unit } from './lib/reliability.js';
import { CODEBOOK_VERSION } from './lib/coderLabel.js';

const i = process.argv.indexOf('--codebook');
const version = i > 0 ? process.argv[i + 1] : CODEBOOK_VERSION;
const { rows } = await pool.query(
  `SELECT l.batch_id, l.politician_id, l.office_id, l.topic_id, l.coder_slot, l.valid, l.value, l.rests_on, l.source_codes,
          (SELECT string_agg(DISTINCT r.role_scope, ',') FROM inform.compass_topic_roles r WHERE r.topic_id = l.topic_id) AS levels
     FROM inform.stance_coder_labels l
    WHERE l.codebook_version = $1 AND NOT l.is_diagnostic AND l.coder_slot BETWEEN 1 AND 3`, [version]);
await pool.end();

const order = ['statement-other', 'statement-answer', 'record']; // weakest first
const units = new Map<string, { level: string; classes: Set<string>; values: (string | null)[] }>();
for (const r of rows) {
  const key = `${r.batch_id}|${r.politician_id}|${r.office_id}|${r.topic_id}`;
  const u = units.get(key) ?? { level: String(r.levels ?? 'unknown'), classes: new Set<string>(), values: [null, null, null] };
  u.values[r.coder_slot - 1] = r.valid ? chairCategory(r.value) : null;
  if (r.valid) {
    for (const p of r.source_codes as { snapshot_id: string; v3_class: string }[]) {
      if ((r.rests_on as string[]).includes(p.snapshot_id)) u.classes.add(p.v3_class);
    }
  }
  units.set(key, u);
}
// A unit's stratum = the weakest class ANY coder rested on; 'blank' when no coder seated a chair.
const stratumOf = (u: { level: string; classes: Set<string> }) => `${u.level} × ${order.find((c) => u.classes.has(c)) ?? 'blank'}`;
const byStratum = new Map<string, Unit[]>();
for (const u of units.values()) byStratum.set(stratumOf(u), [...(byStratum.get(stratumOf(u)) ?? []), u.values]);
console.log(`codebook ${version} — ${units.size} coded rows\n`);
console.log('stratum'.padEnd(40), 'rows'.padStart(6), 'M1 α'.padStart(8), '  M2–M4');
for (const [s, us] of [...byStratum].sort()) {
  const a = alphaNominal(us);
  console.log(s.padEnd(40), String(us.length).padStart(6), (a.alpha === null ? 'undef' : a.alpha.toFixed(3)).padStart(8), '  n/a (no gold until P2)');
}
const all = alphaNominal([...units.values()].map((u) => u.values));
console.log(`\nall strata: M1 α = ${all.alpha === null ? 'undef' : all.alpha.toFixed(3)} (target ≥ 0.80, spec §3.3)`);

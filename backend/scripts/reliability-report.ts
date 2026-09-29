/**
 * reliability-report.ts — M1 (coder-vs-coder α, nominal) per stratum across every batch stored in
 * inform.stance_coder_labels (spec §3.1), and M2–M4 against blind gold in inform.stance_gold_labels
 * (mode blind, submitted, not excluded_from_cert; the newest decision per row). Read-only.
 * A row's stratum = the SEAT's level (stance_coder_labels.level, written from coding-context.json
 * seat.level — the same level codingReport uses) × the weakest evidence class any valid coder rested
 * its chair on (spec §3.2).
 *   npx tsx scripts/reliability-report.ts [--codebook 0.2]
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { alphaNominal, certify, chairCategory, goldMeasures, type Unit, blankMeasures } from './lib/reliability.js';
import { CODEBOOK_VERSION } from './lib/coderLabel.js';

const i = process.argv.indexOf('--codebook');
const version = i > 0 ? process.argv[i + 1] : CODEBOOK_VERSION;
const { rows } = await pool.query(
  `SELECT l.batch_id, l.politician_id, l.office_id, l.topic_id, l.coder_slot, l.valid, l.value, l.rests_on, l.source_codes, l.level
     FROM inform.stance_coder_labels l
    WHERE l.codebook_version = $1 AND NOT l.is_diagnostic AND l.coder_slot BETWEEN 1 AND 3`, [version]);
// Blind gold (spec §3.3): the newest counted decision per (politician, office, topic). A decision a
// later row supersedes is not the answer any more.
const { rows: goldRows } = await pool.query(
  `SELECT DISTINCT ON (g.politician_id, g.office_id, g.topic_id)
          g.politician_id, g.office_id, g.topic_id, g.final_value, t.topic_key
     FROM inform.stance_gold_labels g JOIN inform.compass_topics t ON t.id = g.topic_id
    WHERE g.mode = 'blind' AND g.blind_submitted_at IS NOT NULL AND NOT g.excluded_from_cert
      AND NOT EXISTS (SELECT 1 FROM inform.stance_gold_labels s WHERE s.supersedes_id = g.id)
    ORDER BY g.politician_id, g.office_id, g.topic_id, g.created_at DESC`);
await pool.end();
// Off-axis ladders (CLAUDE.md "Never assume polarity"): there, any wrong unanimous chair is severe.
const OFF_AXIS = new Set(['residential-zoning', 'growth-and-development', 'judicial-government-deference']);
const gold = new Map(goldRows.map((g) => [`${g.politician_id}|${g.office_id}|${g.topic_id}`, g as { final_value: number | null; topic_key: string }]));

const order = ['statement-other', 'statement-answer', 'record']; // weakest first
const units = new Map<string, { level: string; classes: Set<string>; values: (string | null)[]; goldKey: string }>();
for (const r of rows) {
  const key = `${r.batch_id}|${r.politician_id}|${r.office_id}|${r.topic_id}`;
  const u = units.get(key) ?? { level: String(r.level ?? 'unknown'), classes: new Set<string>(), values: [null, null, null],
    goldKey: `${r.politician_id}|${r.office_id}|${r.topic_id}` };
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
const byStratum = new Map<string, { units: Unit[]; pairs: { coders: (string | null)[]; gold: number | null; offAxis: boolean }[] }>();
for (const u of units.values()) {
  const b = byStratum.get(stratumOf(u)) ?? { units: [], pairs: [] };
  b.units.push(u.values);
  const g = gold.get(u.goldKey);
  if (g) b.pairs.push({ coders: u.values, gold: g.final_value, offAxis: OFF_AXIS.has(g.topic_key) });
  byStratum.set(stratumOf(u), b);
}
console.log(`codebook ${version} — ${units.size} coded rows, ${[...byStratum.values()].reduce((n, b) => n + b.pairs.length, 0)} with blind gold\n`);
console.log('stratum'.padEnd(32), 'rows'.padStart(5), 'M1 α'.padStart(7), 'gold'.padStart(5), 'M2 α'.padStart(7), '  M3 unan ok/n', ' M4', '  certified?');
const fmt = (a: number | null) => (a === null ? 'undef' : a.toFixed(3));
for (const [s, b] of [...byStratum].sort()) {
  const m1 = alphaNominal(b.units).alpha;
  const g = goldMeasures(b.pairs);
  const c = certify({ goldN: b.pairs.length, m1, m2: g.m2, unanimousCorrect: g.unanimousCorrect, unanimousTotal: g.unanimousTotal, severe: g.severe });
  // 'blank' = no coder seated a chair: a diagnostic bucket, never certified (ruling 2026-09-28).
  const cert = s.endsWith('statement-other') ? 'never (Q2)' : s.endsWith('× blank') ? 'diagnostic (blanks publish no chair)' : c.certified ? 'YES' : `no — ${c.reasons.join('; ')}`;
  console.log(s.padEnd(32), String(b.units.length).padStart(5), fmt(m1).padStart(7), String(b.pairs.length).padStart(5), fmt(g.m2).padStart(7),
    `  ${g.unanimousCorrect}/${g.unanimousTotal}`.padEnd(14), String(g.severe).padStart(3), ' ', cert);
}
// Blanks (spec §3.1 "Blanks"): over every row whose coder consensus is BLANK, in any stratum.
const allPairs = [...units.values()].flatMap((u) => { const g = gold.get(u.goldKey); return g ? [{ key: `${g.topic_key} ${u.goldKey.split('|')[0].slice(0, 8)}`, coders: u.values, gold: g.final_value }] : []; });
const bm = blankMeasures(allPairs);
console.log(`\nblanks (diagnostic): precision ${bm.blankCorrect}/${bm.blankConsensus} (Wilson low ${bm.precisionWilsonLow.toFixed(3)}); missed chairs ${bm.missed.length}` +
  (bm.missed.length ? ` — ${bm.missed.map((m) => `${m.key} (gold ${m.gold})`).join(', ')}` : ''));
const all = alphaNominal([...units.values()].map((u) => u.values));
console.log(`\nall strata: M1 α = ${fmt(all.alpha)} (target ≥ 0.80, spec §3.3). A stratum certifies only with ≥ 50 blind gold items.`);

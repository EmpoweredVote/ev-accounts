/**
 * reliability-report.ts — M1 (coder-vs-coder α, nominal) per stratum across every batch stored in
 * inform.stance_coder_labels (spec §3.1), and M2–M4 against blind gold in inform.stance_gold_labels
 * (mode blind, submitted, not excluded_from_cert; the newest decision per row). Read-only.
 * A row's stratum = the SEAT's level (stance_coder_labels.level, written from coding-context.json
 * seat.level — the same level codingReport uses) × the weakest evidence class any valid coder rested
 * its chair on (spec §3.2) × the evidence basis (CA_0302, ruling 2026-10-06 option B): 'own-words' when
 * compass_topic_roles marks the topic own-words-only at that level, else 'record'. The basis is read
 * as it stands NOW, not as it stood when the row was coded — roles change rarely, and a changed role
 * changes which stratum a row belongs to, which is the point. Own-words strata print with an
 * "own-words" tag; a certification of a record stratum never covers them.
 *   npx tsx scripts/reliability-report.ts [--codebook 0.2] [--run rr1] [--exclude-batches a,b]
 * A re-run of the coders over saved gold inputs (spec §3.4, after a codebook change) is stored under
 * batch ids ending "-<run>" (e.g. "2026-10-01-shadow-wesco-sb101-rr1"). By default those are left out,
 * so the original figures do not move; --run <tag> reports ONLY that re-run. --exclude-batches drops
 * the named batches (base names, the "-<run>" suffix ignored) — used to report a re-run without the
 * gold items whose adjudication wrote the rule being tested.
 * --record --models a,b,c --note "..." (repeatable) writes one inform.reliability_certifications row
 * per CERTIFIED stratum (never a blank or statement-other one), from the figures computed here — no
 * hand-typed numbers. The table is append-only; a decertification is a later row. --note lines go in
 * `reason` prefixed "note:" (the run, the leakage control, who approved it).
 * --latest scores the CURRENT setup: for each batch, the rows of its newest run (the highest "-rrN", else
 * the original coding). After a re-run, fresh batches coded under the new prompts have no "-rrN" copy, so
 * neither the default nor --run sees the setup as it now stands. Not combinable with --run.
 * --slot N scores ONE coder alone (e.g. --slot 1 = the Opus coder) as if it were the whole system: its
 * answer is the "consensus" and every chair it seats is "unanimous". M1 (coder-vs-coder) does not exist
 * for one coder and is printed n/a; the verdict reads "M2–M4 only" and is never recorded (--record is
 * refused) — certifying a single coder needs a spec ruling first.
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { alphaNominal, certify, chairCategory, goldMeasures, type Unit, blankMeasures } from './lib/reliability.js';
import { CODEBOOK_VERSION } from './lib/coderLabel.js';

const i = process.argv.indexOf('--codebook');
const version = i > 0 ? process.argv[i + 1] : CODEBOOK_VERSION;
const ri = process.argv.indexOf('--run');
const run = ri > 0 ? process.argv[ri + 1] : null;
const xi = process.argv.indexOf('--exclude-batches');
const excluded = new Set(xi > 0 ? process.argv[xi + 1].split(',').map((b) => b.trim()).filter(Boolean) : []);
const si = process.argv.indexOf('--slot');
const slot = si > 0 ? Number(process.argv[si + 1]) : null;
if (slot !== null && process.argv.includes('--record')) { console.error('--record is refused with --slot: a single coder is not a certifiable setup without a spec ruling'); process.exit(2); }
const RERUN = /-rr\d+$/;
const baseName = (b: string) => b.replace(RERUN, '');
const { rows: allRows } = await pool.query(
  `SELECT l.batch_id, l.politician_id, l.office_id, l.topic_id, l.coder_slot, l.valid, l.value, l.rests_on, l.source_codes, l.level
     FROM inform.stance_coder_labels l
    WHERE l.codebook_version = $1 AND NOT l.is_diagnostic AND l.coder_slot BETWEEN 1 AND 3`, [version]);
const latest = process.argv.includes('--latest');
if (latest && run) { console.error('--latest and --run are exclusive: --latest already picks each batch\'s newest run'); process.exit(2); }
const runNo = (b: string) => Number(b.match(RERUN)?.[0].slice(3) ?? 0);
const newest = new Map<string, number>();
for (const r of allRows) newest.set(baseName(r.batch_id), Math.max(newest.get(baseName(r.batch_id)) ?? 0, runNo(r.batch_id)));
const inView = (b: string) => latest ? runNo(b) === newest.get(baseName(b)) : run ? b.endsWith(`-${run}`) : !RERUN.test(b);
const rows = allRows.filter((r) => (slot === null || r.coder_slot === slot) && inView(r.batch_id) && !excluded.has(baseName(r.batch_id)));
// Blind gold (spec §3.3): the newest counted decision per (politician, office, topic). A decision a
// later row supersedes is not the answer any more.
const { rows: goldRows } = await pool.query(
  `SELECT DISTINCT ON (g.politician_id, g.office_id, g.topic_id)
          g.politician_id, g.office_id, g.topic_id, g.final_value, t.topic_key
     FROM inform.stance_gold_labels g JOIN inform.compass_topics t ON t.id = g.topic_id
    WHERE g.mode = 'blind' AND g.blind_submitted_at IS NOT NULL AND NOT g.excluded_from_cert
      AND NOT EXISTS (SELECT 1 FROM inform.stance_gold_labels s WHERE s.supersedes_id = g.id)
    ORDER BY g.politician_id, g.office_id, g.topic_id, g.created_at DESC`);
// Off-axis ladders (CLAUDE.md "Never assume polarity"): there, any wrong unanimous chair is severe.
const OFF_AXIS = new Set(['residential-zoning', 'growth-and-development', 'judicial-government-deference']);
const gold = new Map(goldRows.map((g) => [`${g.politician_id}|${g.office_id}|${g.topic_id}`, g as { final_value: number | null; topic_key: string }]));

// Evidence basis per (topic, level). to_jsonb so the report still runs before CA_0302 (absent → record).
const { rows: roleRows } = await pool.query(
  `SELECT r.topic_id, r.role_scope, to_jsonb(r)->>'evidence_basis' AS basis FROM inform.compass_topic_roles r`);
const basisOf = new Map(roleRows.map((r) => [`${r.topic_id}|${r.role_scope}`, r.basis === 'own-words' ? 'own-words' : 'record']));

const order = ['statement-other', 'statement-answer', 'record']; // weakest first
const units = new Map<string, { level: string; basis: string; classes: Set<string>; values: (string | null)[]; goldKey: string }>();
for (const r of rows) {
  const key = `${r.batch_id}|${r.politician_id}|${r.office_id}|${r.topic_id}`;
  const u = units.get(key) ?? { level: String(r.level ?? 'unknown'), basis: basisOf.get(`${r.topic_id}|${r.level}`) ?? 'record', classes: new Set<string>(), values: [null, null, null],
    goldKey: `${r.politician_id}|${r.office_id}|${r.topic_id}` };
  if (slot !== null) u.values = [0, 1, 2].map(() => (r.valid ? chairCategory(r.value) : null)); // one coder stands in for all three
  else u.values[r.coder_slot - 1] = r.valid ? chairCategory(r.value) : null;
  if (r.valid) {
    for (const p of r.source_codes as { snapshot_id: string; v3_class: string }[]) {
      if ((r.rests_on as string[]).includes(p.snapshot_id)) u.classes.add(p.v3_class);
    }
  }
  units.set(key, u);
}
// A unit's stratum = the weakest class ANY coder rested on; 'blank' when no coder seated a chair.
// The level part carries " own-words" for an own-words stratum, so the record strata print exactly as before.
const stratumOf = (u: { level: string; basis: string; classes: Set<string> }) =>
  `${u.level}${u.basis === 'own-words' ? ' own-words' : ''} × ${order.find((c) => u.classes.has(c)) ?? 'blank'}`;
const byStratum = new Map<string, { units: Unit[]; pairs: { coders: (string | null)[]; gold: number | null; offAxis: boolean }[] }>();
for (const u of units.values()) {
  const b = byStratum.get(stratumOf(u)) ?? { units: [], pairs: [] };
  b.units.push(u.values);
  const g = gold.get(u.goldKey);
  if (g) b.pairs.push({ coders: u.values, gold: g.final_value, offAxis: OFF_AXIS.has(g.topic_key) });
  byStratum.set(stratumOf(u), b);
}
console.log(`codebook ${version}${slot !== null ? ` — coder slot ${slot} ALONE` : ''}${run ? ` — re-run ${run}` : ''}${excluded.size ? ` — ${excluded.size} batch(es) excluded` : ''} — ${units.size} coded rows, ${[...byStratum.values()].reduce((n, b) => n + b.pairs.length, 0)} with blind gold\n`);
console.log('stratum'.padEnd(32), 'rows'.padStart(5), 'M1 α'.padStart(7), 'gold'.padStart(5), 'M2 α'.padStart(7), '  M3 unan ok/n', ' M4', '  certified?');
const record = process.argv.includes('--record');
const mi = process.argv.indexOf('--models');
const modelSet = (mi > 0 ? process.argv[mi + 1] : 'opus,sonnet,sonnet').split(',');
const notes = process.argv.flatMap((a, k) => (a === '--note' ? [`note: ${process.argv[k + 1]}`] : []));
const toRecord: { level: string; basis: string; cls: string; n: number; m1: number | null; m2: number | null; m3: number; severe: number }[] = [];
const fmt = (a: number | null) => (a === null ? 'undef' : a.toFixed(3));
for (const [s, b] of [...byStratum].sort()) {
  const m1 = slot !== null ? null : alphaNominal(b.units).alpha;
  const g = goldMeasures(b.pairs);
  const c = certify({ goldN: b.pairs.length, m1, m2: g.m2, unanimousCorrect: g.unanimousCorrect, unanimousTotal: g.unanimousTotal, severe: g.severe });
  // 'blank' = no coder seated a chair: a diagnostic bucket, never certified (ruling 2026-09-28).
  const cSingle = slot !== null ? c.reasons.filter((x) => x !== 'm1 undefined') : null;
  const cert = cSingle !== null && !s.endsWith('× blank') && !s.endsWith('statement-other') ? (cSingle.length ? `M2–M4 only: no — ${cSingle.join('; ')}` : 'M2–M4 only: PASS (not a certification)') : s.endsWith('statement-other') ? 'never (Q2)' : s.endsWith('× blank') ? 'diagnostic (blanks publish no chair)' : c.certified ? 'YES' : `no — ${c.reasons.join('; ')}`;
  if (cert === 'YES') { const [lvlPart, cls] = s.split(' × '); const [lvl, tag] = lvlPart.split(' '); toRecord.push({ level: lvl, basis: tag === 'own-words' ? 'own-words' : 'record', cls, n: b.pairs.length, m1, m2: g.m2, m3: c.m3WilsonLow, severe: g.severe }); }
  console.log(s.padEnd(32), String(b.units.length).padStart(5), fmt(m1).padStart(7), String(b.pairs.length).padStart(5), fmt(g.m2).padStart(7),
    `  ${g.unanimousCorrect}/${g.unanimousTotal}`.padEnd(14), String(g.severe).padStart(3), ' ', cert);
}
// Blanks (spec §3.1 "Blanks"): over every row whose coder consensus is BLANK, in any stratum.
const allPairs = [...units.values()].flatMap((u) => { const g = gold.get(u.goldKey); return g ? [{ key: `${g.topic_key} ${u.goldKey.split('|')[0].slice(0, 8)}`, coders: u.values, gold: g.final_value }] : []; });
const bm = blankMeasures(allPairs);
console.log(`\nblanks (diagnostic): precision ${bm.blankCorrect}/${bm.blankConsensus} (Wilson low ${bm.precisionWilsonLow.toFixed(3)}); missed chairs ${bm.missed.length}` +
  (bm.missed.length ? ` — ${bm.missed.map((m) => `${m.key} (gold ${m.gold})`).join(', ')}` : ''));
const all = slot !== null ? { alpha: null } : alphaNominal([...units.values()].map((u) => u.values));
console.log(`\nall strata: M1 α = ${fmt(all.alpha)} (target ≥ 0.80, spec §3.3). A stratum certifies only with ≥ 50 blind gold items.`);
if (record) {
  for (const r of toRecord) {
    const { rows: [row] } = await pool.query(
      `INSERT INTO inform.reliability_certifications (level, evidence_class, evidence_basis, topic_id, codebook_version, model_set, n, m1_alpha, m2_alpha, m3_wilson_low, m4_severe, certified, reason)
       VALUES ($1, $2, $3, NULL, $4, $5, $6, $7, $8, $9, $10, true, $11) RETURNING id, computed_at`,
      [r.level, r.cls, r.basis, version, modelSet, r.n, r.m1, r.m2, r.m3, r.severe, notes]);
    console.log(`recorded certification ${row.id} — ${r.level} ${r.basis} × ${r.cls} at ${row.computed_at.toISOString()}`);
  }
  if (!toRecord.length) console.log('--record: no stratum certified; nothing written');
}
await pool.end();

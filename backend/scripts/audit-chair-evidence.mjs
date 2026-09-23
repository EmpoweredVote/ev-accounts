#!/usr/bin/env node
/**
 * Is each corrected chair EVIDENCED FOR THAT CHAIR?
 *
 * 🔑 THE STANDARD (see CLAUDE.md): the five chairs are five DISTINCT stances, not a polarity
 * rating. To seat a politician in a chair you need evidence describing THAT chair, with sources.
 * A citation that establishes only the DIRECTION (pro/anti) under-determines which of the two or
 * three chairs on that side the person holds — seating anyway is an unevidenced claim.
 *
 * ⚠ "The least extreme option the reasoning supports" is a TIEBREAKER, not evidence. Reaching for
 * it is the signal that the row is not yet evidenced.
 *
 * Modes (reads only):
 *   node scripts/audit-chair-evidence.mjs                     — report across all four migrations
 *   node scripts/audit-chair-evidence.mjs --check <file.json> — GATE: exit 1 if any listed row's
 *                                                               reasoning names no instrument
 *   node scripts/audit-chair-evidence.mjs --csv <file.csv>   — GATE, PRE-WRITE: same test against a
 *                                                               research CSV's `reasoning` column
 *   node scripts/audit-chair-evidence.mjs --worklist <out>    — emit the unevidenced rows by state
 *
 * Run it at BOTH ends of a batch: `--csv` before the push (so a bad row is fixed in the CSV, not in
 * prod), and `--check` after it. `--check` reads the STORED reasoning, so pointing it at rows that do
 * not exist yet passes vacuously — see the note on the CSV branch below.
 *
 * `--check` expects `{"rows": [{politician_id, topic_id, chair_after}]}`. A bare JSON ARRAY, or rows
 * keyed `value` instead of `chair_after`, yields ZERO pairs and therefore a vacuous OK — so write the
 * campaign's `written-<batch>.json` in that exact shape and it doubles as this gate's input.
 *
 * 🔴 NAME THE SEASON FOR ANY PAIR THAT HAS ROWS IN MORE THAN ONE. Context and answers are keyed
 * (politician_id, topic_id, season_id). Without a season the lookup below joins every context row of
 * the pair to every answer row and judges whichever comes back first — on CA_0190 it read four
 * untouched SEASON 1 rows and failed them, while the Season 2 rows the migration wrote were never
 * looked at. So a `season_id` on the row, or at the top of the file, scopes the lookup to that
 * season's context and that season's answer. Files without one read exactly as before.
 *
 * ⚠ PATHS.
 *   · The `--check` argument is resolved UNDER `backend/data/stance-retirement/` unless it already
 *     starts with `data/` (a leading `backend/` is stripped first). So `--check foo.json` reads
 *     `backend/data/stance-retirement/foo.json`, NOT `./foo.json` — pass a `data/...`-rooted path to
 *     point elsewhere. This is a quirk of where the rollback fixtures live, not a general file arg.
 *   · The connection string comes from `process.env.DATABASE_URL` first, then from `backend/.env`
 *     resolved RELATIVE TO THIS SCRIPT (so cwd does not matter and no OS-specific absolute path is
 *     baked in). The DB modes (`--check`, `--worklist`, default) need it; `--csv` never touches the
 *     database.
 */
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { NAMES_INSTRUMENT, INSTRUMENT_SRC } from './lib/chair-evidence-patterns.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CHECK = flag('--check');
const WORKLIST = flag('--worklist');
const CSV = flag('--csv');

const DEFAULT_FILES = [
  ['1726', 'data/stance-retirement/2026-08-12-medicaid-misaligned-1726-rollback.json'],
  ['1727', 'data/stance-retirement/2026-08-12-batch-inversion-1727-rollback.json'],
  ['1729', 'data/stance-retirement/2026-08-12-national-rescan-1729-rollback.json'],
  ['1730', 'data/stance-retirement/2026-08-12-reversed-ladder-1730-rollback.json'],
];

const files = CHECK ? [['check', CHECK.replace(/^backend\//, '')]] : DEFAULT_FILES;
const pairs = [];
for (const [mig, f] of files) {
  const j = JSON.parse(fs.readFileSync(f.startsWith('data/') ? f : `data/stance-retirement/${f}`, 'utf8'));
  for (const r of j.rows || []) {
    pairs.push({ mig, pid: r.politician_id, tid: r.topic_id, chair: r.chair_after, season: r.season_id ?? j.season_id ?? null });
  }
}

// --csv: GATE A RESEARCH CSV *BEFORE* IT IS WRITTEN.
//
// 🔑 Why this mode exists. `--check` reads the reasoning from the DATABASE, so it can only judge rows
// that already exist. Run against a batch that has not been pushed yet, every pair misses
// (`if (!r[0]) continue`) and it prints "OK: all 0 row(s)" and exits 0 — a VACUOUS PASS, the same
// failure shape as a seated-count query that forgets `politician_id IS NOT NULL`. The NC campaign
// plan called for exactly that run order, which is what surfaced this.
//
// Same pattern, same standard, applied to the CSV column instead of the stored column, so a row that
// cannot name its instrument is fixed in the CSV rather than corrected in prod afterwards.
//
// ⚠ THIS GATE IS NECESSARY, NOT SUFFICIENT. It is a LEXICAL test: it asks whether the reasoning NAMES
// an instrument, never whether that instrument establishes THAT CHAIR rather than merely a direction.
// On the NC pilot it passed 10 of Ager's 15 rows while only 5 met the bar. A human still has to read
// the chair text against the instrument. Passing here is the floor, not the finding.
if (CSV) {
  const { parse } = await import('csv-parse/sync');
  const rows = parse(fs.readFileSync(CSV), { columns: true, skip_empty_lines: true });
  const scored = rows
    .filter((r) => String(r.value ?? '').trim() !== '')   // a blank spoke seats no chair, so it owes nothing
    .map((r) => ({ ...r, ok: NAMES_INSTRUMENT.test(r.reasoning || '') }));
  const bad = scored.filter((r) => !r.ok);
  if (bad.length) {
    console.error(`FAIL: ${bad.length} of ${scored.length} row(s) seat a chair on reasoning that names no instrument, act or vote.`);
    for (const r of bad.slice(0, 20)) {
      console.error(`  · ${r.full_name} / ${r.topic_key} → chair ${r.value}: ${(r.reasoning || '').slice(0, 90)}`);
    }
    if (bad.length > 20) console.error(`  … and ${bad.length - 20} more`);
    console.error('\nA chair needs evidence describing THAT chair. Source it, or leave the spoke blank.');
    process.exit(1);
  }
  console.log(`OK: all ${scored.length} valued row(s) name an instrument, act or vote.`);
  console.log('Reminder: this is a lexical floor. It cannot tell a chair-shaped instrument from a directional one.');
  process.exit(0);
}

// The environment wins; otherwise read backend/.env RELATIVE TO THIS SCRIPT. This previously read
// 'C:/EV-Accounts/backend/.env', which exists on exactly one machine and threw ENOENT on every
// macOS/Linux checkout — the same fix already applied in scripts/apply-migration-file.mjs and
// scripts/030-run-sweep.mjs.
let url = process.env.DATABASE_URL;
if (!url) {
  const envPath = new URL('../.env', import.meta.url);   // .../backend/.env
  let env;
  try { env = fs.readFileSync(envPath, 'utf8'); }
  catch { console.error(`refusing: DATABASE_URL is not set and ${fileURLToPath(envPath)} is not readable`); process.exit(2); }
  url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l))?.replace(/^DATABASE_URL=/, '').trim();
}
if (!url) { console.error('refusing: DATABASE_URL is not set (backend/.env)'); process.exit(2); }
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const rows = [];
let blanked = 0;
for (const p of pairs) {
  const { rows: r } = await pool.query(
    `SELECT c.reasoning, c.sources, pol.full_name AS name, o.representing_state AS state,
            t.short_title AS topic, t.title AS topic_title, a.value AS chair_now
       FROM inform.politician_context c
       JOIN essentials.politicians pol ON pol.id = c.politician_id
       LEFT JOIN essentials.offices o ON o.id = pol.office_id
       JOIN inform.compass_topics t ON t.id = c.topic_id
       LEFT JOIN inform.politician_answers a
              ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
             AND ($3::uuid IS NULL OR a.season_id = c.season_id)
      WHERE c.politician_id = $1 AND c.topic_id = $2
        AND ($3::uuid IS NULL OR c.season_id = $3)`,
    [p.pid, p.tid, p.season],
  );
  if (!r[0]) continue;
  // A BLANKED SPOKE IS RESOLVED, NOT OWED. The debt is "chairs seated without evidence for that
  // chair"; a row with no answer seats no chair, so counting its directional reasoning as debt
  // would keep the number from ever converging and invite a future pass to redo settled rows.
  // value 0 is the season-era blank (CC_0057) and seats no chair either.
  if (r[0].chair_now == null || Number(r[0].chair_now) === 0) { blanked++; continue; }
  rows.push({
    ...p, ...r[0],
    names_instrument: NAMES_INSTRUMENT.test(r[0].reasoning || ''),
    instrument_src: (r[0].sources || []).some((s) => INSTRUMENT_SRC.test(s)),
  });
}
await pool.end();

const unevidenced = rows.filter((r) => !r.names_instrument);
const pct = (n) => `${((n / rows.length) * 100).toFixed(0)}%`;

if (CHECK) {
  if (unevidenced.length) {
    console.error(`FAIL: ${unevidenced.length} of ${rows.length} row(s) seat a chair on reasoning that names no instrument, act or vote.`);
    for (const r of unevidenced.slice(0, 20)) console.error(`  · ${r.name} / ${r.topic} → chair ${r.chair}: ${(r.reasoning || '').slice(0, 90)}`);
    if (unevidenced.length > 20) console.error(`  … and ${unevidenced.length - 20} more`);
    console.error('\nA chair needs evidence describing THAT chair. Source it, or leave the spoke blank.');
    process.exit(1);
  }
  console.log(`OK: all ${rows.length} row(s) name an instrument, act or vote.`);
  process.exit(0);
}

console.log(`chairs corrected: ${rows.length + blanked}  (${blanked} since blanked — a blank spoke seats no chair and is resolved)`);
console.log(`  sources include a primary instrument:            ${rows.filter((r) => r.instrument_src).length}  ${pct(rows.filter((r) => r.instrument_src).length)}`);
console.log(`  reasoning NAMES a specific instrument/act/vote:  ${rows.length - unevidenced.length}  ${pct(rows.length - unevidenced.length)}`);
console.log(`  reasoning is DIRECTIONAL ONLY (not evidenced):   ${unevidenced.length}  ${pct(unevidenced.length)}`);

const byState = {};
for (const r of unevidenced) {
  const st = r.state || '??';
  byState[st] ??= { n: 0, pols: new Set(), topics: {} };
  byState[st].n++; byState[st].pols.add(r.name);
  byState[st].topics[r.topic] = (byState[st].topics[r.topic] || 0) + 1;
}
console.log('\nunevidenced rows by state:');
for (const [st, v] of Object.entries(byState).sort((a, b) => b[1].n - a[1].n)) {
  console.log(`  ${st.padEnd(3)} ${String(v.n).padStart(3)} rows · ${v.pols.size} politicians`);
}

if (WORKLIST) {
  fs.writeFileSync(WORKLIST, JSON.stringify({
    pass: 'chairs seated by inference — owed evidence describing THAT chair',
    standard: 'To sit in a chair you need evidence describing that chair, with sources. Direction is not a chair.',
    n: unevidenced.length,
    by_state: Object.fromEntries(Object.entries(byState).map(([k, v]) => [k, { rows: v.n, politicians: [...v.pols].sort(), topics: v.topics }])),
    rows: unevidenced.map((r) => ({
      politician_id: r.pid, name: r.name, state: r.state, topic: r.topic_title, topic_id: r.tid,
      chair_seated: r.chair, reasoning: r.reasoning, sources: r.sources, from_migration: r.mig,
    })),
  }, null, 1));
  console.log(`\nwrote ${WORKLIST}`);
}

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
 *   node scripts/audit-chair-evidence.mjs --worklist <out>    — emit the unevidenced rows by state
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CHECK = flag('--check');
const WORKLIST = flag('--worklist');

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
  for (const r of j.rows || []) pairs.push({ mig, pid: r.politician_id, tid: r.topic_id, chair: r.chair_after });
}

// Does the reasoning name something that can distinguish ONE chair from its neighbour — a bill, an
// act, an ordinance, a recorded vote? A description of direction cannot.
const NAMES_INSTRUMENT =
  /(\bHB\s?\d|\bSB\s?\d|\bH\.R\.|\bS\.J\.Res|\bAB-?\s?\d|\bLD\s?\d|\bSJR\s?\d|\bAct\b|\bOrdinance\b|voted (YES|NO|Yea|Nay|AYE|NAY)|roll call|Chapter \d)/;
// A source that could carry such an instrument, as opposed to a bio or an aggregator profile.
const INSTRUMENT_SRC =
  /(legislature|mgaleg|leginfo|congress\.gov|govtrack|clerk\.house|senate\.gov\/legislative|\/bill|\/legislation|rollcall|roll_call|ordinance|agenda|minutes|\.pdf|capitol|legiscan)/i;

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
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
      WHERE c.politician_id = $1 AND c.topic_id = $2`,
    [p.pid, p.tid],
  );
  if (!r[0]) continue;
  // A BLANKED SPOKE IS RESOLVED, NOT OWED. The debt is "chairs seated without evidence for that
  // chair"; a row with no answer seats no chair, so counting its directional reasoning as debt
  // would keep the number from ever converging and invite a future pass to redo settled rows.
  if (r[0].chair_now == null) { blanked++; continue; }
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

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
  for (const r of j.rows || []) pairs.push({ mig, pid: r.politician_id, tid: r.topic_id, chair: r.chair_after });
}

// Does the reasoning name something that can distinguish ONE chair from its neighbour — a bill, an
// act, an ordinance, a recorded vote? A description of direction cannot.
// ⚠ MUNICIPAL VOCABULARY (added 2026-08-13, mig 1738). The original pattern was built for state
// legislatures and could not see a single thing a CITY COUNCIL does — 14 of the 31 California rows
// named a real instrument it scored as "directional only". The additions are deliberately NARROW,
// because the point is never that a word appears:
//   · "Resolution No." / "Ordinance No." require the NUMBER, so a numbered adopted instrument
//     passes and a passing mention of "the sanctuary ordinance" does not.
//   · "referral approved/adopted/considered" requires the referral to have been ACTED ON. Berkeley
//     referrals carry no number, and an unqualified "referral" would have admitted the withdrawn
//     item this very migration had to remove (2025-03-11 Item 15, "removed from the agenda").
// ⚠ WIDENED TWICE, EACH TIME ONLY ALONGSIDE ROWS ALREADY VERIFIED BY READING THE SOURCE.
// The original list was STATE-LEGISLATURE shaped and could not see a city council's vocabulary at
// all; mig 1738 added the municipal terms, requiring a NUMBER so that an unadopted referral could not
// sneak through. Mig 1740 adds the two forms a MAYOR's record takes, for the same reason:
//   · `Measure \d+\.\d+` — a numbered measure inside an adopted municipal plan. San Diego's 2022
//     Climate Action Plan is Gloria's actual instrument (he proposed and signed it; the Council
//     adopted it unanimously), and its commitments live in numbered measures such as Measure 1.1
//     "phase out 45% of natural gas usage from existing buildings by 2030". The decimal is required
//     precisely so that vague prose, or a bare ballot "Measure A", cannot satisfy it.
//   · `O-#####` / `R-######` — San Diego's ordinance and resolution numbering, e.g. Ordinance
//     O-21528 N.S. (Climate Action Plan Consistency Regulations) and Resolution R-316659.
// ⚠ WIDENED A THIRD TIME (2026-08-19, Travis County wave), for the vocabulary of a COUNTY
// COMMISSIONERS COURT. The pattern was state-legislature shaped, then learned city councils (1738)
// and mayors (1740); it still could not see a single thing a county does. Two additions, both
// deliberately narrow and both copying the shape of an existing rule:
//   · `Proposition [A-Z0-9]{1,3}` — a LETTERED/NUMBERED ballot proposition. This is the "Measure A"
//     objection answered rather than repeated: the identifier is required, so vague prose cannot
//     pass, and the rows it admits are county propositions actually put to and carried at an
//     election (Travis County Proposition A, Nov 2024, 59.43%). A county's budget-and-ballot
//     instruments have no bill number; this is the identifier they do have.
//   · `Commissioners Court (approved|adopted|voted)` — requires the BODY TO HAVE ACTED, exactly the
//     test already applied to `referrals? (approved|adopted|considered)`. An unqualified
//     "Commissioners Court" would have admitted every passing mention of the body and is not used.
// ⚠ WHAT THIS WIDENING DELIBERATELY DOES NOT RESCUE. Five rows in the same verified wave still fail,
//    and that is the correct result, not an oversight: a diversion steering committee, a solar
//    installation programme, an early-case-review process and a campaign platform are PROGRAMMES,
//    not instruments. They may well be sound evidence, but they are not the thing this gate tests,
//    and inventing lexical hooks for them would make passing mean nothing.
// 🔑 The point of the gate is that PASSING MEANS SOMETHING. All three widenings were paired with rows whose
//    instruments had been read in the source document, and in each case the recorded proof is that the
//    debt fell by exactly the number of rows touched — never more.
// ⚠ WIDENED A FOURTH TIME (2026-08-24, NC stance campaign), for two FALSE NEGATIVES measured on the
// three-person NC pilot — rows whose evidence was read at the source and confirmed, which this gate
// nevertheless failed. Same discipline as the three widenings above: narrow, identifier-bearing, and
// paired with rows already verified by reading the instrument.
//   · `(House|Senate) Bill \d` — North Carolina numbers its bills `H 509` / `S 467`, not `HB 509`, so
//     an NC citation written in house style was invisible here. The fix requires the CHAMBER WORD and
//     the number rather than admitting a bare `H\d`, which would match far too much ordinary prose.
//     Verified rows: H509 Right to Reproductive Freedom Act and H20 Fair Maps Act (operative text read
//     on ncleg.gov), H1189 Datacenter Transparency Act (moratorium text read), H1229.
//   · `S.L. 20NN-NNN` — a North Carolina SESSION LAW, the identifier an enacted bill carries after
//     ratification. Verified row: Mayfield's Aye on H951/S.L. 2021-165.
//   · CASE. The pattern was case-sensitive, so `Voted Aye` and `Senate Roll Call S-464` both failed
//     while `voted AYE` and `roll call` passed. That is an accident of transcription, not a
//     difference in evidence. Only the vote/roll-call alternatives are made case-tolerant — the whole
//     regex is NOT given an `i` flag, because `\bAct\b` would then match the ordinary verb "act" and
//     passing would stop meaning anything.
// ⚠ WIDENED A FIFTH TIME (2026-09-08, Senate gun-policy pass), for a whole COHORT of false negatives:
// U.S. SENATE bills. The pattern had `\bH\.R\.` from the start but never its Senate sibling, and named
// a federal statute only when the title carried the word `Act`. So every row citing a Senate bill by
// number, and every named federal statute whose title is a `Ban of <year>` rather than an `Act`,
// scored "directional only" — including the LIVE CC_0074 rows (Padilla, Schiff, "the Assault Weapons
// Ban of 2025") and all 42 Assault Weapons Ban rows of CC_0078, each verified at source by
// verify-reresearch-rows (every distinctive term present in the cited bill text). Two additions, both
// narrow and identifier-bearing, both paired with rows already verified by reading the instrument:
//   · `S. <number>` — a U.S. Senate bill, the sibling of `\bH\.R\.`. The negative lookbehind
//     `(?<![A-Za-z]\.)` keeps it from firing on a preceding initialism or middle initial, so
//     `U.S. 2024` and `Angus S. King` do NOT match while `S. 1531` and `S.1531` do. A digit is
//     required, exactly so a bare middle initial cannot pass. Verified rows: CC_0078's S. 1531 / S. 25
//     / S. 3214 cohort.
//   · `Ban of <year>` — a named federal statute whose short title ends in a ban and a year rather
//     than "Act", e.g. "Assault Weapons Ban of 2025" (S. 1531) and "Assault Weapons Ban of 2023"
//     (S. 25). The capitalised `Ban` and the four-digit year are both required, so ordinary prose
//     ("a ban of some kind") cannot satisfy it. Verified rows: the same cohort, whose reasoning names
//     the ban by its exact short title, present in the cited bill text.
const NAMES_INSTRUMENT =
  /(\bHB\s?\d|\bSB\s?\d|\b(?:House|Senate) Bill \d{1,4}\b|\bS\.L\. 20\d{2}-\d{1,4}\b|\bH\.R\.|\bS\.J\.Res|\bAB-?\s?\d|\bLD\s?\d|\bSJR\s?\d|\bAct\b|\bOrdinance\b|[Vv]oted (YES|Yes|NO|No|Yea|YEA|Nay|NAY|AYE|Aye)|[Rr]oll [Cc]all|Chapter \d|Resolution No\.|Ordinance No\.|referrals? (approved|adopted|considered)|recorded roll call|Measure \d+\.\d+|\bO-\d{4,5}\b|\bR-\d{5,6}\b|\bProposition [A-Z0-9]{1,3}\b|Commissioners Court (approved|adopted|voted)|(?<![A-Za-z]\.)\bS\.\s?\d{1,4}\b|\bBan of (?:19|20)\d{2}\b)/;
// A source that could carry such an instrument, as opposed to a bio or an aggregator profile.
const INSTRUMENT_SRC =
  /(legislature|mgaleg|leginfo|congress\.gov|govtrack|clerk\.house|senate\.gov\/legislative|\/bill|\/legislation|rollcall|roll_call|ordinance|agenda|minutes|\.pdf|capitol|legiscan)/i;

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

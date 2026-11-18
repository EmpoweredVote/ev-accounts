#!/usr/bin/env node
/**
 * Fail if any result citation claims somebody beat an incumbent who did not lose that race.
 *
 * Verdicts: scripts/lib/incumbent-claims.mjs (pure, tested) — read its header for the two
 * opposite grammars that share these words, and for why the name is never parsed out of prose.
 *
 *   npm run check:incumbent-claims --prefix backend
 *   npm run check:incumbent-claims --prefix backend -- --verbose   # print every claim examined
 *
 * ── WHAT THIS GUARDS, AND WHAT IT CANNOT ─────────────────────────────────────────────────────
 *
 * `CC_0447` put "defeating incumbent Jared Golden" on a voter-facing page for ME-02. Golden held
 * the seat and was not a candidate. The generator that wrote it now carries the three-branch test
 * (`backend/data/house-2026-late-losers/match-losers.mjs`), so the bulk path is covered.
 *
 * 🔴 THIS IS FOR THE CLAIM THAT ARRIVES ANY OTHER WAY — typed into a migration by hand, pasted
 *    from a source, or written by a future pass that never reads the matcher. `result_source` has
 *    no history table and nothing re-reads it, so a false sentence sits there until a person
 *    happens to look.
 *
 * ⚠ IT PROVES THE CLAIM IS SELF-CONSISTENT WITH OUR OWN BALLOT, NOT THAT IT IS TRUE. If a race's
 *   rows are themselves wrong, a claim agreeing with them passes. The answer to that is
 *   `match-losers.mjs`, which reads AP's ballot — a source outside this database.
 *
 * ── 🔴 WHY IT DOES NOT RUN ON PULL REQUESTS ──────────────────────────────────────────────────
 *
 * It queries the live database, and migrations here are applied ad hoc, never replayed by a
 * deploy. A PR's SQL has not touched production yet, so there is nothing new for this to see on a
 * PR — and a master-only gate that reads prod data FAILS ON THE NEXT MERGE AND NAMES AN INNOCENT
 * AUTHOR (CLAUDE.md, Verification rules). It rides the non-PR `reachability` job for exactly the
 * reasons written on that job, and ▶ A MIGRATION THAT WRITES SUCH A CITATION SHOULD CARRY THIS
 * ASSERTION IN ITS OWN POST-VERIFY, as a delta, which is what `CC_0452` did and what blocks the
 * guilty change rather than the next one.
 *
 * ── FAILURE BEHAVIOUR ────────────────────────────────────────────────────────────────────────
 *
 * 🔴 NO DATABASE_URL -> SKIP, exit 0, and SAY SO. Forks get no secrets.
 * ⚠ Both the skip and the pass print the number of citations SCANNED and claims EXAMINED. A gate
 *   that reports no violations over rows it never read is the exact shape of a detector that has
 *   quietly stopped working, and this repo has had two of those. READ THE COUNT, NOT THE VERDICT.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import dotenv from 'dotenv';

import { checkCitation, SELF_DESCRIBED_LOSER, RE_ELECTED } from './lib/incumbent-claims.mjs';

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
dotenv.config({ path: path.join(backendDir, '.env'), quiet: true });

const VERBOSE = process.argv.includes('--verbose');

// 🔴 SO THE GATE CAN BE WATCHED GOING RED WITHOUT WRITING TO PRODUCTION. A control has to hand
// this tampered rows, and the only alternative — planting a false citation in prod and rolling
// back — cannot work, because the check opens its own connection and would never see an
// uncommitted row. `match-losers.mjs` carries the same escape hatch for the same reason.
// The file is the SQL's own result shape: [{ id, race_id, full_name, first_name, last_name,
// result, result_source, state, geo_id }].
const rowsFromIdx = process.argv.indexOf('--rows-from');
const ROWS_FROM = rowsFromIdx === -1 ? null : process.argv[rowsFromIdx + 1];

if (!ROWS_FROM && !process.env.DATABASE_URL) {
  console.log('check:incumbent-claims SKIPPED — no DATABASE_URL in the environment.');
  console.log('  Forks get no secrets, so this exits 0 rather than red-walling an outside PR.');
  console.log('  0 citations scanned. Nothing was checked.');
  process.exit(0);
}

const pool = ROWS_FROM ? null : new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// Every row of every race that holds at least one citation mentioning an incumbent. The claim's
// own race is pulled WHOLE -- the gate needs the losers to match against, and every row in it to
// decide whether a bare surname is ambiguous.
const SQL = `
  WITH races_with_a_claim AS (
    SELECT DISTINCT race_id
      FROM essentials.race_candidates
     WHERE result_source ~* 'defeat(ing|ed)\\s+incumbents?\\s'
        OR result_source ~* 'the\\s+defeated\\s+incumbent'
        OR result_source ~* 'incumbent\\s+re-?elected'
  )
  SELECT rc.id, rc.race_id, rc.full_name, rc.first_name, rc.last_name,
         rc.result, rc.result_source,
         r.position_name,
         d.state, d.geo_id
    FROM essentials.race_candidates rc
    JOIN races_with_a_claim w ON w.race_id = rc.race_id
    JOIN essentials.races r    ON r.id = rc.race_id
    LEFT JOIN essentials.offices   o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   ORDER BY rc.race_id, rc.full_name
`;

const TOTAL_SQL = `
  SELECT count(*) AS n FROM essentials.race_candidates WHERE result_source IS NOT NULL
`;

try {
  let rows;
  let citationsInRepo;
  if (ROWS_FROM) {
    rows = JSON.parse(fs.readFileSync(ROWS_FROM, 'utf8'));
    citationsInRepo = rows.filter((r) => r.result_source).length;
    console.log(`⚠ CONTROL MODE — rows read from ${path.basename(ROWS_FROM)}, not from the database.`);
  } else {
    const [a, b] = await Promise.all([pool.query(SQL), pool.query(TOTAL_SQL)]);
    rows = a.rows;
    citationsInRepo = Number(b.rows[0].n);
  }

  const byRace = new Map();
  for (const row of rows) {
    if (!byRace.has(row.race_id)) byRace.set(row.race_id, []);
    byRace.get(row.race_id).push(row);
  }

  let claimsExamined = 0;
  let selfDescribed = 0;
  let reElected = 0;
  let rowsWithACitation = 0;
  const failures = [];

  for (const [, raceRows] of byRace) {
    const losers = raceRows.filter((r) => r.result === 'lost');
    for (const row of raceRows) {
      if (!row.result_source) continue;
      rowsWithACitation += 1;
      const { claimsFound, violations } = checkCitation(row, losers, raceRows);
      claimsExamined += claimsFound;
      if (SELF_DESCRIBED_LOSER.test(row.result_source)) selfDescribed += 1;
      if (RE_ELECTED.test(row.result_source)) reElected += 1;
      for (const v of violations) {
        failures.push({ row, ...v });
      }
      if (VERBOSE && claimsFound > 0) {
        const seat = [row.state, row.geo_id].filter(Boolean).join(' ');
        console.log(`  examined: ${row.full_name} (${seat || row.position_name || 'seat unknown'}) `
          + `— ${claimsFound} claim(s), ${violations.length} violation(s)`);
      }
    }
  }

  // Read the COUNT, not the verdict.
  console.log(`Incumbent claims: ${byRace.size} race(s) hold a citation mentioning an incumbent; `
    + `${rowsWithACitation} citation(s) in them read, out of ${citationsInRepo} repo-wide.`);
  console.log(`  examined: ${claimsExamined} defeat-the-incumbent claim(s), `
    + `${selfDescribed} self-described-loser, ${reElected} incumbent-re-elected.`);

  if (claimsExamined === 0 && byRace.size > 0) {
    console.error('\n🔴 The SQL matched races, but the parser found no claims in any of them.');
    console.error('   Those two disagree, which means one of them is broken. Not a pass.');
    process.exit(1);
  }

  if (failures.length === 0) {
    console.log('✅ Every claim names somebody who holds a losing row in that same race.');
    process.exit(0);
  }

  console.error(`\n🔴 ${failures.length} citation claim(s) name an incumbent who did not lose:\n`);
  for (const f of failures) {
    const seat = [f.row.state, f.row.geo_id].filter(Boolean).join(' ') || f.row.position_name || '';
    console.error(`  ${f.row.full_name}${seat ? ` (${seat})` : ''} — race ${f.row.race_id}`);
    console.error(`    rule : ${f.rule}`);
    console.error(`    why  : ${f.detail ?? f.why}`);
    if (f.unmatched) console.error(`    text : "…${f.unmatched}…"`);
    console.error(`    row  : ${f.row.id}`);
  }
  console.error('\nAP\'s `incumbent` is an attribute of the SEAT, not a ballot line. "The winner is');
  console.error('not the incumbent" does not mean "the winner beat the incumbent" — the incumbent');
  console.error('may simply not have been a candidate. See backend/data/me02-open-seat-2026/OPEN-SEAT.md');
  console.error('and the three-branch test in backend/data/house-2026-late-losers/match-losers.mjs.');
  process.exit(1);
} catch (err) {
  console.error('check:incumbent-claims could not read the database:', err.message);
  process.exit(1);
} finally {
  if (pool) await pool.end();
}

#!/usr/bin/env node
/**
 * The controls behind `check-incumbent-claims.mjs`, so the gate is watched GOING RED rather than
 * trusted because it printed a tick. It reads the real rows out of production ONCE, plants one
 * fault per control in a copy, and runs the gate against that copy.
 *
 * 🔴 NOTHING IS EVER WRITTEN TO THE DATABASE. The check opens its own connection, so a tampered
 *    row inside an uncommitted transaction would be invisible to it anyway — which is why the
 *    gate takes `--rows-from` at all.
 *
 * 🔴 EVERY BUILDER REFUSES A TAMPER THAT DID NOT APPLY. A control that silently changed nothing
 *    reports the same clean exit as the real thing, and this repo has had exactly that: a `sed`
 *    that failed on a quoting error left a 0-byte migration and the dry run called it OK.
 *
 *   node scripts/lib/incumbent-claims-controls.mjs
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import pg from 'pg';
import dotenv from 'dotenv';

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
dotenv.config({ path: path.join(backendDir, '.env'), quiet: true });
const CHECK = path.join(backendDir, 'scripts', 'check-incumbent-claims.mjs');
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'incumbent-controls-'));

if (!process.env.DATABASE_URL) {
  console.error('These controls need DATABASE_URL: they tamper with the REAL rows, so that a');
  console.error('control cannot pass against a fixture that no longer resembles production.');
  process.exit(2);
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false },
});

// Pull whole races, so a control can edit a citation AND the rows it is checked against.
const { rows: LIVE } = await pool.query(`
  WITH races_with_a_claim AS (
    SELECT DISTINCT race_id FROM essentials.race_candidates
     WHERE result_source ~* 'defeat(ing|ed)\\s+incumbents?\\s'
        OR result_source ~* 'the\\s+defeated\\s+incumbent'
        OR result_source ~* 'incumbent\\s+re-?elected')
  SELECT rc.id, rc.race_id, rc.full_name, rc.first_name, rc.last_name,
         rc.result, rc.result_source, r.position_name, d.state, d.geo_id
    FROM essentials.race_candidates rc
    JOIN races_with_a_claim w ON w.race_id = rc.race_id
    JOIN essentials.races r    ON r.id = rc.race_id
    LEFT JOIN essentials.offices   o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   ORDER BY rc.race_id, rc.full_name`);
await pool.end();

if (LIVE.length === 0) {
  console.error('No rows came back. A control suite with nothing to tamper proves nothing.');
  process.exit(2);
}

const find = (rows, pred, what) => {
  const r = rows.find(pred);
  if (!r) throw new Error(`no row matching ${what} — the tamper cannot apply`);
  return r;
};
const theClaimant = (rows) =>
  find(rows, (r) => /defeat(?:ing|ed)\s+incumbents?\s/i.test(r.result_source ?? ''),
    'a citation making a defeat-the-incumbent claim');

const CONTROLS = {
  A: {
    note: 'the named incumbent is replaced by somebody on NO row — the ME-02 defect itself',
    expect: 'defeated-incumbent-must-have-lost',
    edit: (rows) => {
      const row = theClaimant(rows);
      row.result_source = row.result_source.replace(
        /(defeat(?:ing|ed)\s+incumbents?\s+)([^.]*)/i, '$1Jared Golden');
    },
  },
  B: {
    note: 'the named incumbent is swapped for the WINNER of the same race',
    expect: 'did not lose it',
    edit: (rows) => {
      const row = theClaimant(rows);
      const winner = find(rows, (r) => r.race_id === row.race_id && r.result === 'won', 'a winner');
      row.result_source = row.result_source.replace(
        /(defeat(?:ing|ed)\s+incumbents?\s+)([^.]*)/i, `$1${winner.full_name}`);
    },
  },
  C: {
    note: "the loser's row is re-marked 'won', so the claim stops being true without being edited",
    expect: 'defeated-incumbent-must-have-lost',
    edit: (rows) => {
      const row = theClaimant(rows);
      const loser = find(rows, (r) => r.race_id === row.race_id && r.result === 'lost', 'a loser');
      loser.result = 'won';
    },
  },
  D: {
    note: 'a SECOND name is appended to the claim, and that one is on no row',
    expect: 'defeated-incumbent-must-have-lost',
    edit: (rows) => {
      const row = theClaimant(rows);
      row.result_source = row.result_source.replace(
        /(defeat(?:ing|ed)\s+incumbents?\s+)([^.]*)/i, '$1$2 and Nobody Atall');
    },
  },
  E: {
    note: '"the defeated incumbent" moved onto a row that WON',
    expect: 'self-described-defeated-incumbent-must-have-lost',
    edit: (rows) => {
      const row = find(rows, (r) => r.result === 'won' && r.result_source, 'a winner with a citation');
      row.result_source += ' Also: the defeated incumbent.';
    },
  },
  F: {
    note: '"Incumbent re-elected" moved onto a row that LOST',
    expect: 'incumbent-re-elected-must-have-won',
    edit: (rows) => {
      const row = find(rows, (r) => r.result === 'lost' && r.result_source, 'a loser with a citation');
      row.result_source += ' Incumbent re-elected.';
    },
  },
  G: {
    note: 'the MIRROR grammar — "Incumbent X defeated Y", which is true and must NOT fire',
    expect: null, // must stay green
    edit: (rows) => {
      const row = find(rows, (r) => r.result_source, 'any row with a citation');
      row.result_source +=
        ' Ballotpedia: "Incumbent Ann Wagner defeated Peter Pfeifer, Brandon Wilkinson, '
        + 'Matthew Grant, and Elizabeth Sparks-Holmes in the Republican primary for U.S. House."';
    },
  },
  H: {
    note: 'a bare surname where TWO candidates in the race share it — the namesake hole',
    expect: 'defeated-incumbent-must-have-lost',
    edit: (rows) => {
      const row = theClaimant(rows);
      const loser = find(rows, (r) => r.race_id === row.race_id && r.result === 'lost', 'a loser');
      const winner = find(rows, (r) => r.race_id === row.race_id && r.result === 'won', 'a winner');
      // Give the winner the loser's surname, then claim a defeat naming only that surname.
      winner.last_name = loser.last_name;
      winner.full_name = `${winner.first_name} ${loser.last_name}`;
      row.result_source = row.result_source.replace(
        /(defeat(?:ing|ed)\s+incumbents?\s+)([^.]*)/i, `$1${loser.last_name}`);
    },
  },
  I: {
    note: 'every citation emptied — the blank sheet that must NOT read as a pass',
    expect: 'disagree',
    edit: (rows) => { for (const r of rows) r.result_source = null; },
  },
};

let failed = 0;
console.log(`baseline: ${LIVE.length} live row(s) across `
  + `${new Set(LIVE.map((r) => r.race_id)).size} race(s), untampered\n`);

for (const [letter, c] of Object.entries(CONTROLS)) {
  const copy = JSON.parse(JSON.stringify(LIVE));
  let built = true;
  try { c.edit(copy); } catch (e) { built = false; console.log(`${letter}  🔴 ${e.message}`); }
  if (!built) { failed += 1; continue; }

  if (JSON.stringify(copy) === JSON.stringify(LIVE)) {
    console.log(`${letter}  🔴 TAMPER DID NOT APPLY — rows unchanged. This control proves nothing.`);
    failed += 1;
    continue;
  }

  const file = path.join(TMP, `${letter}.json`);
  fs.writeFileSync(file, JSON.stringify(copy, null, 2));

  let out;
  let code = 0;
  try {
    // stderr is PIPED, not inherited: a failing control prints the gate's whole report, and nine
    // of those bury the summary this script exists to show.
    out = execFileSync(process.execPath, [CHECK, '--rows-from', file],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch (e) {
    out = `${e.stdout ?? ''}${e.stderr ?? ''}`;
    code = e.status ?? 1;
  }

  const wantedRed = c.expect !== null;
  const wentRed = code !== 0;
  const sawExpected = c.expect === null ? true : out.includes(c.expect);
  const ok = wantedRed === wentRed && sawExpected;
  if (!ok) failed += 1;

  console.log(`${letter}  ${ok ? '✅' : '🔴'} ${c.note}`);
  console.log(`    expected ${wantedRed ? `RED on "${c.expect}"` : 'GREEN (must not fire)'}`
    + ` — got exit ${code}`);
  const line = out.split('\n').find((l) => /rule :|disagree|✅|🔴/.test(l));
  if (line) console.log(`    ${line.trim()}`);
}

console.log(`\n${Object.keys(CONTROLS).length} control(s) run, ${failed} did not behave as designed.`);
process.exit(failed ? 1 : 0);

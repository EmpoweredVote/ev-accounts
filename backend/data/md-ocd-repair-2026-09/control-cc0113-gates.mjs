/**
 * control-cc0113-gates.mjs
 *
 * 🔴 A GATE THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GATE.
 *
 * Runs every gate in CC_0113 against a deliberately broken state and requires it to RAISE.
 * Nothing is written: each case runs in its own transaction and always ROLLBACKs.
 *
 * The migration is split at its `Post-verify gate` banner so a mutation can be planted BETWEEN
 * the repair and the gate. The gate text being judged is therefore the real one, letter for
 * letter, rather than a copy edited to fail.
 *
 * ⚠ EVERY CASE ASSERTS WHAT IT PLANTED — `rows` is a rowcount the case declares in advance, and a
 *   mismatch aborts the case rather than letting its verdict stand. A control that aborts for the
 *   wrong reason proves nothing, and a control that plants a real change in the WRONG PLACE looks
 *   exactly like a pass (MN-4 shipped two of those before they were caught).
 *
 *   node control-cc0113-gates.mjs
 */
import fs from 'fs';
import path from 'path';
import pg from 'pg';

const MIG = path.join(import.meta.dirname, '..', '..', 'migrations', 'CC_0113_md_ocd_suffix_repair.sql');
const raw = fs.readFileSync(MIG, 'utf8').replace(/^BEGIN;$/m, '').replace(/^COMMIT;$/m, '');
const i = raw.search(/^-- ─── Post-verify gate/m);
if (i < 0) throw new Error('no post-verify banner — the split is what makes this control real');
const REPAIR = raw.slice(0, i); // pre-flight + both UPDATEs
const GATE = raw.slice(i); // the post-verify DO block

const MD_LOWER = `lower(state)='md' AND district_type::text='STATE_LOWER'`;

const CASES = [
  // ── pre-flight (mutate BEFORE the migration runs) ──────────────────────────────────────────
  {
    g: 'PRE 1  the damage is not 42/42',
    stage: 'before',
    rows: 1,
    sql: `UPDATE essentials.districts SET ocd_id = ocd_id || 'A' WHERE geo_id = '2401A'`,
    want: /expected 42 collapsed districts and 42 collapsed boundaries, found 41 and 42/,
  },
  {
    g: 'PRE 2  a corrected id is already taken',
    stage: 'before',
    rows: 1,
    // ⚠ 24003, not 2403. MD's SLDLST codes are THREE characters, so a whole delegate district is
    // '24'+'003'; `2403` is Maryland's 3rd CONGRESSIONAL district and the first draft of this
    // control planted on it. The gate fired anyway — correctly, since any row holding the id is a
    // clash — but the control was not testing what it claimed.
    sql: `UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:md/sldl:1A' WHERE geo_id='24003' AND ${MD_LOWER}`,
    want: /corrected ocd_id\(s\) are already held by another district row/,
  },

  // ── post-verify (repair, then plant, then gate) ────────────────────────────────────────────
  {
    g: 'GATE 1  a collapsed row survives',
    stage: 'after',
    rows: 1,
    sql: `UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:md/sldl:1' WHERE geo_id='2401A'`,
    want: /still carry a collapsed ocd_id/,
  },
  {
    g: 'GATE 2  a district row goes missing',
    stage: 'after',
    rows: 1,
    sql: `DELETE FROM essentials.districts WHERE geo_id='24003' AND ${MD_LOWER}`,
    want: /MD STATE_LOWER is 70 row\(s\) with 70 distinct ocd_id, expected 71 and 71/,
  },
  {
    g: 'GATE 3  the two tables disagree',
    stage: 'after',
    rows: 1,
    // Ends in a letter (so GATE 1 passes) and stays distinct (so GATE 2 passes) — only the
    // districts-vs-boundaries agreement is broken.
    sql: `UPDATE essentials.geofence_boundaries SET ocd_id='ocd-division/country:us/state:md/sldl:99Q' WHERE geo_id='2401A' AND mtfcc='G5220'`,
    want: /disagree with their boundary row on ocd_id/,
  },
  {
    g: 'GATE 4  a repaired suffix is malformed',
    stage: 'after',
    rows: 2,
    // BOTH tables, identically, so GATE 3 passes and GATE 4 is the one left to fire. 'Z' is not
    // a Maryland subdistrict letter.
    sql:
      `UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:md/sldl:1Z' WHERE geo_id='2401A'; ` +
      `UPDATE essentials.geofence_boundaries SET ocd_id='ocd-division/country:us/state:md/sldl:1Z' WHERE geo_id='2401A' AND mtfcc='G5220'`,
    want: /repaired ocd_id\(s\) are malformed/,
  },
  {
    g: 'GATE 5  the seat denominator is short',
    stage: 'after',
    rows: 1,
    // A STATE_UPPER row: invisible to gates 1-4, which are all STATE_LOWER.
    sql: `DELETE FROM essentials.districts WHERE lower(state)='md' AND district_type::text='STATE_UPPER' AND geo_id='24047'`,
    want: /seat denominator is 117, expected 118/,
  },
  {
    g: 'GATE 6  Massachusetts moved',
    stage: 'after',
    rows: 1,
    // 🔴 IT MUST COME OUT OF THE COLLAPSED GROUP. The first draft took the lowest-id MA row,
    // which already held a UNIQUE ocd_id — swapping one unique value for another left `distinct`
    // at 161 and the gate passed, correctly. MA's ONLY shared value is `sldu:NaN`, held by 40
    // rows, so the plant has to come from there for `distinct` to move 161 -> 162.
    sql: `UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:ma/sldu:ctl' WHERE id = (SELECT id FROM essentials.districts WHERE ocd_id='ocd-division/country:us/state:ma/sldu:NaN' ORDER BY id LIMIT 1)`,
    want: /Massachusetts moved — 200 rows \/ 162 distinct/,
  },
  {
    g: 'GATE 7  another state drops a letter',
    stage: 'after',
    rows: 1,
    // Minnesota is correct in production; breaking one MN row proves the national sweep looks
    // beyond Maryland.
    sql: `UPDATE essentials.districts SET ocd_id='ocd-division/country:us/state:mn/sldl:8' WHERE geo_id='2708A'`,
    want: /state-legislative row\(s\) nationally still drop a geo_id letter/,
  },
];

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
let pass = 0;
let fail = 0;

for (const c of CASES) {
  await client.query('BEGIN');
  await client.query("SET LOCAL statement_timeout = '300s'");
  let verdict = '';
  try {
    if (c.stage === 'after') await client.query(REPAIR);

    let planted = 0;
    for (const stmt of c.sql.split(/;\s*(?=(?:UPDATE|DELETE|INSERT)\b)/i)) {
      planted += (await client.query(stmt)).rowCount ?? 0;
    }
    if (planted !== c.rows) {
      console.log(`  ✗ PLANT   ${c.g.padEnd(34)} touched ${planted} row(s), declared ${c.rows} — its verdict would prove nothing`);
      fail++;
      await client.query('ROLLBACK');
      continue;
    }

    if (c.stage === 'before') await client.query(REPAIR);
    await client.query(GATE);
  } catch (e) {
    verdict = String(e.message ?? e);
  }
  await client.query('ROLLBACK');

  if (!verdict) {
    console.log(`  ✗ PASSED  ${c.g.padEnd(34)} the gate did not refuse a deliberately broken state`);
    fail++;
  } else if (!c.want.test(verdict)) {
    console.log(`  ✗ WRONG   ${c.g.padEnd(34)} refused, but for another reason: ${verdict.replace(/\s+/g, ' ').slice(0, 130)}`);
    fail++;
  } else {
    console.log(`  ✓ REFUSED ${c.g.padEnd(34)} ${verdict.replace(/\s+/g, ' ').slice(0, 108)}`);
    pass++;
  }
}

// 🟢 THE POSITIVE HALF. The unmutated migration must pass its own gate, and must be idempotent:
//    running it twice in one transaction must reach the same verdict, exercising the 0/0
//    early-return in the pre-flight.
for (const [label, times] of [['the real migration passes its gate', 1], ['and again, idempotent', 2]]) {
  await client.query('BEGIN');
  await client.query("SET LOCAL statement_timeout = '300s'");
  let err = '';
  try {
    for (let n = 0; n < times; n++) {
      await client.query(REPAIR);
      await client.query(GATE);
    }
  } catch (e) {
    err = String(e.message ?? e);
  }
  await client.query('ROLLBACK');
  if (err) {
    console.log(`  ✗ REFUSED ${label.padEnd(34)} ${err.replace(/\s+/g, ' ').slice(0, 120)}`);
    fail++;
  } else {
    console.log(`  ✓ PASSED  ${label.padEnd(34)} as it must`);
    pass++;
  }
}

console.log(`\n${pass} verdict(s) correct · ${fail} wrong`);
await client.end();
process.exit(fail ? 1 : 0);

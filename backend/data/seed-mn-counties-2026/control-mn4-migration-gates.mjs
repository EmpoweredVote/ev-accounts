/**
 * control-mn4-migration-gates.mjs
 *
 * 🔴 A GATE THAT HAS NEVER BEEN SEEN TO FAIL IS NOT A GATE.
 *
 * Runs every gate in CC_0111 and CC_0112 against a deliberately broken state and requires it to
 * RAISE. Nothing is written: each case runs in its own transaction and always ROLLBACKs.
 *
 * The migrations are split at their `Post-verify gate` banner so a mutation can be planted
 * BETWEEN the inserts and the gate. That way the gate text being judged is the real one, letter
 * for letter, rather than a copy edited to fail.
 *
 * ⚠ AND EVERY CASE ASSERTS WHAT IT PLANTED. MN-3 shipped two controls that planted something
 *   other than what they claimed and both looked like passes -- a greedy regex deleted three
 *   inserts instead of one, and a "two seats, one person" control duplicated a person row and
 *   tripped a unique index before the gate was ever reached. A control that aborts for the wrong
 *   reason proves nothing, so `plant` here is a rowcount the case declares in advance.
 *
 *   node control-mn4-migration-gates.mjs
 */
import fs from 'fs';
import path from 'path';
import pg from 'pg';

const MIG = path.join(import.meta.dirname, '..', '..', 'migrations');
const SPLIT = /^-- ─── Post-verify gate/m;

function halves(file) {
  const raw = fs.readFileSync(path.join(MIG, file), 'utf8').replace(/^BEGIN;$/m, '').replace(/^COMMIT;$/m, '');
  const i = raw.search(SPLIT);
  if (i < 0) throw new Error(`${file}: no post-verify banner found -- the split is what makes this control real`);
  return [raw.slice(0, i), raw.slice(i)];
}

const [S1, S2] = halves('CC_0111_mn_counties_structure.sql'); // structure: inserts | gate
const [O1, O2] = halves('CC_0112_mn_counties_officials.sql'); // occupancy: inserts | gate

const SLC = "'27137'";
const RAM = "'27123'";
const officeOf = (gov, title) => `
  (SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.geo_id = ${gov} AND o.title = ${title} LIMIT 1)`;

/**
 * stage: 'preflight'  -> mutate, then run ALL of CC_0111
 *        'structure'  -> run CC_0111 inserts, mutate, then CC_0111's gate
 *        'occupancy'  -> run CC_0111, then CC_0112 inserts, mutate, then CC_0112's gate
 */
const CASES = [
  // ── CC_0111 pre-flight ──────────────────────────────────────────────────────────────────
  { g: 'PRE 1  X0054 short',            stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.geofence_boundaries WHERE mtfcc='X0054' AND geo_id='st-louis-mn-commissioner-district-7'`, want: /X0054 holds 6/ },
  { g: 'PRE 2  X0055 short',            stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.geofence_boundaries WHERE mtfcc='X0055' AND geo_id='ramsey-mn-commissioner-district-7'`, want: /X0055 holds 6/ },
  { g: 'PRE 3  St. Louis polygon gone', stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.geofence_boundaries WHERE geo_id='27137' AND mtfcc='G4020'`, want: /27137\/G4020 \(St\. Louis\) is missing/ },
  { g: 'PRE 4  Ramsey polygon gone',    stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.geofence_boundaries WHERE geo_id='27123' AND mtfcc='G4020'`, want: /27123\/G4020 \(Ramsey\) is missing/ },
  { g: 'PRE 5  St. Louis COUNTY district gone', stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.districts WHERE geo_id='27137' AND district_type::text='COUNTY'`, want: /COUNTY district 27137/ },
  { g: 'PRE 6  Ramsey COUNTY district gone',    stage: 'preflight', rows: 1, sql: `DELETE FROM essentials.districts WHERE geo_id='27123' AND district_type::text='COUNTY'`, want: /COUNTY district 27123/ },
  { g: 'PRE 7  X0054 from the wrong service',   stage: 'preflight', rows: 1, sql: `UPDATE essentials.geofence_boundaries SET source='some other map' WHERE mtfcc='X0054' AND geo_id='st-louis-mn-commissioner-district-1'`, want: /Open_Data\/MapServer\/21/ },
  { g: 'PRE 8  X0055 from the wrong service',   stage: 'preflight', rows: 1, sql: `UPDATE essentials.geofence_boundaries SET source='some other map' WHERE mtfcc='X0055' AND geo_id='ramsey-mn-commissioner-district-1'`, want: /BOUND_CommissionerDistrict2022/ },

  // ── CC_0111 post-verify ─────────────────────────────────────────────────────────────────
  { g: 'STR 1  a government missing',   stage: 'structure', rows: 1, sql: `DELETE FROM essentials.governments WHERE geo_id='27123'`, want: /expected 2 county governments, got 1/ },
  { g: 'STR 2  a chamber missing',      stage: 'structure', rows: 1, sql: `DELETE FROM essentials.chambers c USING essentials.governments g WHERE g.id=c.government_id AND g.geo_id='27137' AND c.name='Office of the Auditor'`, want: /expected 4 St\. Louis \+ 3 Ramsey chambers, got 3 \+ 3/ },
  { g: 'STR 3  Ramsey gains an auditor', stage: 'structure', rows: 1, sql: `UPDATE essentials.offices SET title='County Auditor' WHERE id = ${officeOf(RAM, "'Sheriff'")}`, want: /Ramsey has an elected auditor\/treasurer\/recorder/ },
  { g: 'STR 4  a coroner appears',      stage: 'structure', rows: 1, sql: `UPDATE essentials.offices SET title='Coroner' WHERE id = ${officeOf(SLC, "'Sheriff'")}`, want: /neither county elects one/ },
  { g: 'STR 5  a district missing',     stage: 'structure', rows: 1, sql: `DELETE FROM essentials.districts WHERE geo_id='st-louis-mn-commissioner-district-4'`, want: /expected 14 commissioner districts, got 13/ },
  { g: 'STR 6  an office missing',      stage: 'structure', rows: 1, sql: `DELETE FROM essentials.offices WHERE id = ${officeOf(SLC, "'Auditor/Treasurer'")}`, want: /expected 10 St\. Louis \+ 9 Ramsey offices, got 9 \+ 9/ },
  { g: 'STR 7  a district loses its office', stage: 'structure', rows: 1, sql: `UPDATE essentials.offices SET district_id = (SELECT id FROM essentials.districts WHERE geo_id='27137' AND district_type::text='COUNTY') WHERE district_id = (SELECT id FROM essentials.districts WHERE geo_id='st-louis-mn-commissioner-district-7')`, want: /does not carry exactly one office/ },
  { g: 'STR 8  a district loses its polygon', stage: 'structure', rows: 1, sql: `DELETE FROM essentials.geofence_boundaries WHERE mtfcc='X0055' AND geo_id='ramsey-mn-commissioner-district-3'`, want: /have no polygon/ },

  // ── CC_0112 post-verify ─────────────────────────────────────────────────────────────────
  { g: 'OCC 1  a person outside the band', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.politicians SET external_id=-9999001 WHERE external_id=-2735001`, want: /expected 19 people in the reserved band, got 18/ },
  { g: 'OCC 2  an office missing',      stage: 'occupancy', rows: 1, sql: `DELETE FROM essentials.offices WHERE id = ${officeOf(RAM, "'County Attorney'")}`, want: /expected 19 offices, got 18/ },
  { g: 'OCC 3  a seat left vacant',     stage: 'occupancy', rows: 1, sql: `DELETE FROM essentials.office_terms WHERE office_id = ${officeOf(RAM, "'Sheriff'")}`, want: /expected 19 seated, got 18/ },
  { g: 'OCC 4  the county split wrong', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.offices SET chamber_id = (SELECT c.id FROM essentials.chambers c JOIN essentials.governments g ON g.id=c.government_id WHERE g.geo_id='27137' AND c.name='Office of the Sheriff') WHERE id = ${officeOf(RAM, "'Sheriff'")}`, want: /expected 10 St\. Louis \+ 9 Ramsey seated, got 11 \+ 8/ },
  { g: 'OCC 5  one person on two seats', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET politician_id = (SELECT id FROM essentials.politicians WHERE external_id=-2735001) WHERE office_id = ${officeOf(SLC, "'Commissioner, District 2'")}`, want: /held by 18 distinct people/ },
  { g: 'OCC 6  an extra historical term', stage: 'occupancy', rows: 1, sql: `INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source) SELECT ${officeOf(SLC, "'Sheriff'")}, (SELECT id FROM essentials.politicians WHERE external_id=-2735008), DATE '2015-01-05', DATE '2018-01-01', 'day', 'elected', 'control'`, want: /expected 19 term rows, got 20/ },
  { g: 'OCC 7  an undated term',        stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET term_start=NULL WHERE office_id = ${officeOf(SLC, "'Commissioner, District 1'")}`, want: /carry no term_start/ },
  { g: 'OCC 8  a term that self-vacates', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET term_end=DATE '2030-01-01' WHERE office_id = ${officeOf(RAM, "'Commissioner, District 1'")}`, want: /carry a term_end/ },
  { g: 'OCC 9  a term at unknown precision', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET start_precision='unknown' WHERE office_id = ${officeOf(RAM, "'Commissioner, District 2'")}`, want: /at unknown precision/ },
  { g: 'OCC 10 the precision mix flattened', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET start_precision='month' WHERE office_id = ${officeOf(SLC, "'Commissioner, District 1'")}`, want: /precision mix is 5 day \/ 8 month \/ 6 year/ },
  { g: 'OCC 11 a commissioner claims a day', stage: 'occupancy', rows: 2, sql: `UPDATE essentials.office_terms SET start_precision='day' WHERE office_id = ${officeOf(RAM, "'Commissioner, District 1'")}; UPDATE essentials.office_terms SET start_precision='month' WHERE office_id = ${officeOf(RAM, "'Sheriff'")}`, want: /commissioner term\(s\) claim a day/ },
  { g: 'OCC 12 an officer off the statutory day', stage: 'occupancy', rows: 1, sql: `UPDATE essentials.office_terms SET term_start=DATE '2023-01-03' WHERE office_id = ${officeOf(SLC, "'County Attorney'")}`, want: /not 2023-01-02 at day precision/ },
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
    if (c.stage !== 'preflight') await client.query(S1);
    if (c.stage === 'occupancy') {
      await client.query(S2);
      await client.query(O1);
    }

    // ── plant, and assert the plant ──────────────────────────────────────────────────────
    let planted = 0;
    for (const stmt of c.sql.split(/;\s*(?=(?:UPDATE|DELETE|INSERT)\b)/i)) {
      const r = await client.query(stmt);
      planted += r.rowCount ?? 0;
    }
    if (planted !== c.rows) {
      console.log(`  ✗ PLANT   ${c.g.padEnd(34)} touched ${planted} row(s), declared ${c.rows} -- its verdict would prove nothing`);
      fail++;
      await client.query('ROLLBACK');
      continue;
    }

    // ── the real gate, unedited ──────────────────────────────────────────────────────────
    if (c.stage === 'preflight') await client.query(S1);
    if (c.stage !== 'occupancy') await client.query(S2);
    else await client.query(O2);
    verdict = '';
  } catch (e) {
    verdict = String(e.message ?? e);
  }
  await client.query('ROLLBACK');

  if (!verdict) {
    console.log(`  ✗ PASSED  ${c.g.padEnd(34)} the gate did not refuse a deliberately broken state`);
    fail++;
  } else if (!c.want.test(verdict)) {
    console.log(`  ✗ WRONG   ${c.g.padEnd(34)} refused, but for another reason: ${verdict.slice(0, 120)}`);
    fail++;
  } else {
    console.log(`  ✓ REFUSED ${c.g.padEnd(34)} ${verdict.replace(/\s+/g, ' ').slice(0, 104)}`);
    pass++;
  }
}

console.log(`\n${pass} gate(s) watched failing · ${fail} did not behave as required`);
await client.end();
process.exit(fail ? 1 : 0);

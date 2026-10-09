#!/usr/bin/env node
/**
 * ms2-migration-controls.mjs — Knight program, slice 16 (MS), wave MS-2.
 *
 * Writes the dry-run script for the MS-2 migration pair, plus one TAMPERED copy per gate.
 * Every tampered copy MUST fail, and must fail on the gate it targets. A gate never watched
 * failing is a guess about what the defect looks like (ND-3's rule).
 *
 * 🔴 EACH TAMPER MOVES EXACTLY ONE THING, AND THE EARLIER GATES' QUANTITIES ARE HELD CONSTANT
 * WHERE POSSIBLE. MI-3 found three of five controls shadowed by a total-count gate that fired
 * first, so the gate they targeted was never exercised. Where a tamper unavoidably trips an
 * earlier gate, that is stated in the control's own name.
 *
 * Usage:
 *   node scripts/ms2-migration-controls.mjs          # writes the scripts
 *   then run each with psql and confirm the expected failure
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MIG = path.join(HERE, '..', 'migrations');
const OUT = path.join(HERE, '..', 'data', 'seed-ms-2026', '_dryrun');
fs.mkdirSync(OUT, { recursive: true });

const strip = (f) => fs.readFileSync(path.join(MIG, f), 'utf8')
  .replace(/^BEGIN;\s*$/m, '')
  .replace(/^COMMIT;\s*$/m, '');

const BASE = `BEGIN;\n${strip('CC_0169_ms_legislature_structure.sql')}\n${strip('CC_0170_ms_legislature_incumbents.sql')}\nROLLBACK;\n`;
fs.writeFileSync(path.join(OUT, 'ms2_dryrun.sql'), BASE);

const controls = [];
const add = (name, expect, transform) => {
  const out = transform(BASE);
  if (out === BASE) throw new Error(`control ${name} changed NOTHING — it would pass for the wrong reason`);
  fs.writeFileSync(path.join(OUT, `${name}.sql`), out);
  controls.push({ name, expect });
};

// 1. One Senate district gets no office. Targets the structure gate's 52-office assertion and
//    its per-district assertion; the per-district one is the point, the count fires first.
add('c1_missing_senate_office', 'MS-2 gate: expected 52 MS Senate offices, found 51', (s) =>
  s.replace(
    "WHERE lower(d.state) = 'ms'\n  AND d.district_type::text = 'STATE_UPPER'\n  AND NOT EXISTS",
    "WHERE lower(d.state) = 'ms'\n  AND d.district_type::text = 'STATE_UPPER'\n  AND d.geo_id <> '28052'\n  AND NOT EXISTS",
  ));

// 2. A COUNTY district receives a legislative office. Targets the geo_id-collision gate, which
//    is the one Mississippi most needs — Harrison County and Senate District 47 are both 28047.
add('c2_county_gets_office', 'MS COUNTY district(s) received a legislative office', (s) =>
  s.replace(
    "WHERE lower(d.state) = 'ms'\n  AND d.district_type::text = 'STATE_UPPER'\n  AND NOT EXISTS",
    "WHERE lower(d.state) = 'ms'\n  AND d.district_type::text IN ('STATE_UPPER', 'COUNTY')\n  AND NOT EXISTS",
  ));

// 3. Chris Johnson's SD-44 term gets his CAREER start date. Targets the career-vs-seat gate.
//    ⚠ It also moves the dated-term count from 7 to 8, so the dated gate fires first — the
//    control is therefore run twice, once with the dated count adjusted, to reach the real gate.
const johnsonRow = BASE.match(/ {2}\('28044', 'STATE_UPPER', (-\d+)::bigint, 'Chris Johnson', NULL::date, 'unknown'\)/);
if (!johnsonRow) throw new Error('could not find the Chris Johnson term row to tamper with');
add('c3a_johnson_dated', 'expected exactly 7 dated MS legislative terms', (s) =>
  s.replace(johnsonRow[0], `  ('28044', 'STATE_UPPER', ${johnsonRow[1]}::bigint, 'Chris Johnson', '2020-01-01'::date, 'year')`));
add('c3b_johnson_dated_count_adjusted', 'Senate District 44 must be held by Chris Johnson with an UNDATED term', (s) =>
  s.replace(johnsonRow[0], `  ('28044', 'STATE_UPPER', ${johnsonRow[1]}::bigint, 'Chris Johnson', '2020-01-01'::date, 'year')`)
    .replace('IF v_dated <> 7 THEN', 'IF v_dated <> 8 THEN'));

// 4. One term row removed. Targets the unseated-office gate — the one failure mode CI cannot
//    catch, because an office with no term row is invisible and nothing errors.
// ⚠ IT MUST BE A MIDDLE ROW, NOT THE LAST ONE. The first version removed the final HD-122 row,
//    which is the only row without a trailing comma, so the tampered file had a dangling comma
//    and psql died on a SYNTAX ERROR before reaching any gate. A CONTROL THAT ABORTS FOR THE
//    WRONG REASON PROVES NOTHING — ND-4's rule, and it looked like a passing control because the
//    run did indeed fail.
// ⚠ AND THE TERM-COUNT GATE SHADOWS THE UNSEATED-OFFICE GATE, so removing a row alone never
//    exercises the target. MI-3 found three of five controls shadowed exactly this way. c4b
//    holds the earlier gate's quantity constant by relaxing it to 173, which is the only way to
//    reach the assertion that actually matters — the one for the failure CI cannot catch.
const midTerm = BASE.match(/\n {2}\('28121', 'STATE_LOWER'[^\n]*,[^\n]*\n/);
if (!midTerm) throw new Error('could not find the HD-121 term row to remove (it must carry a trailing comma)');
add('c4a_missing_term', 'expected 174 MS legislative terms, found 173', (s) => s.replace(midTerm[0], '\n'));
add('c4b_missing_term_count_adjusted', 'MS legislative office(s) carry no term', (s) => s
  .replace(midTerm[0], '\n')
  .replace('IF v_terms <> 174 THEN', 'IF v_terms <> 173 THEN')
  .replace('IF v_seated <> 174 THEN', 'IF v_seated <> 173 THEN'));

// 5. A person inserted without is_incumbent. Targets the hidden-from-address-search gate.
add('c5_not_incumbent', 'not flagged is_incumbent', (s) =>
  s.replace(
    "FROM ms_namesakes n\nWHERE NOT EXISTS",
    "FROM ms_namesakes n\nWHERE NOT EXISTS",
  ).replace(
    /(INSERT INTO essentials\.politicians \(external_id, full_name, first_name, last_name, source, is_incumbent, is_active\)\nSELECT n\.external_id, n\.full_name, n\.first_name, n\.last_name, '[^']*(?:''[^']*)*', )true(, true\nFROM ms_namesakes n)/,
    '$1false$2',
  ));

console.log(`wrote ${controls.length + 1} scripts to ${OUT}`);
for (const c of controls) console.log(`  ${c.name}  -> must fail with: ${c.expect}`);

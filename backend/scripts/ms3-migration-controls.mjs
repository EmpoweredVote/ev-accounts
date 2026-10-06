#!/usr/bin/env node
/**
 * ms3-migration-controls.mjs — Knight program, wave MS-3.
 *
 * Builds the CC_0171 + CC_0172 dry run as ONE transaction ending in ROLLBACK, and one TAMPERED
 * copy per gate, so that every gate is watched failing on its own target before the real apply.
 *
 * 🔴 A CONTROL THAT ABORTS FOR THE WRONG REASON PROVES NOTHING — MS-2 paid for this when a control
 * died on a SQL syntax error and the run "failed", which looked like a pass. So each control here
 * declares the message it EXPECTS, and a control that fails with a different message is reported
 * as BROKEN, not as passing.
 *
 * 🔴 AND AN EARLIER GATE CAN SHADOW A LATER ONE — MS-2 paid for that twice, MS-3's boundary loader
 * twice more. Each tamper below is chosen so the gate it targets is the FIRST one that can see it;
 * where the obvious tamper would trip something earlier, the comment says so and the tamper is
 * different.
 *
 * Usage:
 *   node scripts/ms3-migration-controls.mjs --dry-run     # clean run, must COMMIT-then-ROLLBACK cleanly
 *   node scripts/ms3-migration-controls.mjs --controls    # every tampered copy, each must abort
 *   node scripts/ms3-migration-controls.mjs --all
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import * as dotenv from 'dotenv';
dotenv.config();

const PSQL = process.env.PSQL_BIN || 'C:/Program Files/PostgreSQL/18/bin/psql';
const MIGRATIONS = 'migrations';
const OUT = 'data/seed-biloxi-2026/_dryrun';
const STRUCTURE = join(MIGRATIONS, 'CC_0171_biloxi_structure.sql');
const OCCUPANCY = join(MIGRATIONS, 'CC_0172_biloxi_incumbents.sql');

const strip = (sql) =>
  sql
    .split(/\r?\n/)
    .filter((l) => !/^\s*(BEGIN|COMMIT)\s*;\s*$/i.test(l))
    .join('\n');

const BODY = `${strip(readFileSync(STRUCTURE, 'utf8'))}\n\n${strip(readFileSync(OCCUPANCY, 'utf8'))}`;

/** Insert `sql` immediately before the first line matching `marker`. */
function before(body, marker, sql) {
  const i = body.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker}`);
  const at = body.lastIndexOf('\n', i) + 1;
  return body.slice(0, at) + sql + '\n' + body.slice(at);
}

/**
 * Insert before the LAST line matching `marker`.
 * 🔴 Both migrations carry a line reading "Post-verify gate", so `before` lands in the STRUCTURE
 * gate — which runs before the people exist. A tamper placed there hits nothing and the control
 * reports DID NOT FIRE, which reads like a missing gate rather than a misplaced tamper.
 */
function beforeLast(body, marker, sql) {
  const i = body.lastIndexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker}`);
  const at = body.lastIndexOf('\n', i) + 1;
  return body.slice(0, at) + sql + '\n' + body.slice(at);
}

const STRUCT_GATE = '-- ─── Post-verify gate ─';
const OCC_PREFLIGHT = '-- ─── 0. Pre-flight: the eight offices must exist ─';

const CONTROLS = [
  {
    id: 'c1-preflight-wards',
    why: 'the structure migration must refuse to run without the seven ward polygons',
    expect: /pre-flight: expected 7 X0073 Biloxi ward polygons, found 6/,
    tamper: (b) =>
      `DELETE FROM essentials.geofence_boundaries WHERE geo_id = 'biloxi-ms-ward-3' AND mtfcc = 'X0073';\n${b}`,
  },
  {
    id: 'c2-preflight-foreign-x0073',
    why: 'X0073 has no allocator, so a row that is not Biloxi\'s must stop the migration',
    expect: /X0073 polygon\(s\) are not Biloxi wards/,
    // 🔴 ADDING an eighth X0073 row trips the count gate first. RENAME one instead: the count stays
    // at 7 and only the ownership check can object.
    tamper: (b) =>
      `UPDATE essentials.geofence_boundaries SET geo_id = 'somebody-elses-district'
        WHERE geo_id = 'biloxi-ms-ward-1' AND mtfcc = 'X0073';\n${b}`,
  },
  {
    id: 'c3-preflight-place-polygon',
    why: 'the citywide mayor hangs on the TIGER place polygon, which must exist',
    expect: /expected the TIGER place polygon 2806220\/G4110/,
    tamper: (b) =>
      `DELETE FROM essentials.geofence_boundaries WHERE geo_id = '2806220' AND mtfcc = 'G4110';\n${b}`,
  },
  {
    id: 'c4-one-office-per-ward',
    why: 'a total of 7 council offices would also pass with one ward doubled and another empty',
    expect: /Biloxi ward\(s\) do not hold exactly 1 office/,
    // 🔴 ADDING an office trips the total-office gate first, so the per-ward gate stays unproven —
    // and the per-ward gate exists precisely because the total cannot see this. MOVE one instead:
    // the total stays 8, ward 3 holds two and ward 7 holds none. That is the shape the gate is for.
    tamper: (b) =>
      before(
        b,
        STRUCT_GATE,
        `UPDATE essentials.offices SET district_id =
           (SELECT id FROM essentials.districts WHERE geo_id = 'biloxi-ms-ward-3' AND mtfcc = 'X0073')
          WHERE district_id =
           (SELECT id FROM essentials.districts WHERE geo_id = 'biloxi-ms-ward-7' AND mtfcc = 'X0073');`,
      ),
  },
  {
    id: 'c5-office-without-polygon',
    why: 'the one failure mode CI cannot catch: an office on a district with no geometry',
    // 🔴 The obvious tamper — add a district with no polygon — trips the district COUNT gate first.
    // Removing the polygon AFTER the pre-flight leaves every count right and only this gate can see it.
    expect: /Biloxi office\(s\) sit on a district with NO polygon/,
    tamper: (b) =>
      before(
        b,
        STRUCT_GATE,
        `DELETE FROM essentials.geofence_boundaries WHERE geo_id = 'biloxi-ms-ward-4' AND mtfcc = 'X0073';`,
      ),
  },
  {
    id: 'c6-ms2-legislature-untouched',
    why: 'a city wave has no business moving the 174 legislative offices MS-2 seated',
    expect: /expected 174 Mississippi legislative offices from MS-2, found 173/,
    tamper: (b) =>
      before(
        b,
        STRUCT_GATE,
        `DELETE FROM essentials.offices o
           USING essentials.districts d
          WHERE d.id = o.district_id AND d.mtfcc = 'G5210' AND lower(d.state) = 'ms'
            AND o.id = (SELECT o2.id FROM essentials.offices o2
                          JOIN essentials.districts d2 ON d2.id = o2.district_id
                         WHERE d2.mtfcc = 'G5210' AND lower(d2.state) = 'ms'
                         ORDER BY o2.id LIMIT 1);`,
      ),
  },
  {
    id: 'c7-seated-count',
    why: 'office_current_holder LEFT JOINs from offices, so the gate must count politician_id',
    expect: /expected 8 seated Biloxi offices, found 7/,
    tamper: (b) =>
      `${b}\nDO $tamper$ BEGIN
         DELETE FROM essentials.office_terms ot
          USING essentials.offices o, essentials.districts d
          WHERE ot.office_id = o.id AND o.district_id = d.id
            AND d.geo_id = 'biloxi-ms-ward-2' AND d.mtfcc = 'X0073';
       END $tamper$;`,
    // 🔴 This one runs AFTER the occupancy gate, so it cannot prove that gate. It is rebuilt below
    // as c7b; kept here only to document why the naive placement is wrong.
    skip: true,
  },
  {
    id: 'c7b-seated-count',
    why: 'office_current_holder LEFT JOINs from offices, so the gate must count politician_id',
    expect: /expected 8 seated Biloxi offices, found 7/,
    tamper: (b) =>
      b.replace(
        "  ('biloxi-ms-ward-2', 'X0073', -2766406::bigint, '2025-06-30'::date, 'day',   'elected'),\n",
        '',
      ),
  },
  {
    id: 'c8-mayor-oath-date',
    why: 'the mayor was sworn on 2015-05-18, two days before his advertised inauguration',
    expect: /mayor term_start is 2015-05-20, expected 2015-05-18/,
    tamper: (b) => b.replace("-2766408::bigint, '2015-05-18'::date", "-2766408::bigint, '2015-05-20'::date"),
  },
  {
    id: 'c9-ward7-date',
    why: 'dating Ward 7 to 2025 would make the mayor\'s own "four new council members" wrong by one',
    // 🔴 Changing the PRECISION too trips the day/month split gate first and leaves this one
    // unproven. Move only the DATE and keep 'month', so the split still reads 7 and 1 and the
    // Ward 7 assertion is the first gate that can see the change.
    expect: /Ward 7 term_start is 2025-06-30, expected 2024-03-01/,
    tamper: (b) => b.replace("'2024-03-01'::date, 'month'", "'2025-06-30'::date, 'month'"),
  },
  {
    id: 'c10-precision-split',
    why: 'a later pass must not quietly promote Ward 7 to day precision without the minutes',
    expect: /expected 7 day-precision and 1 month-precision terms, found 8 and 0/,
    tamper: (b) => b.replace("'2024-03-01'::date, 'month'", "'2024-03-19'::date, 'day'  "),
  },
  {
    id: 'c11-is-incumbent',
    why: 'is_incumbent defaults to false, and a seated person without it is hidden from address search',
    expect: /Biloxi official\(s\) are not is_incumbent\/is_active/,
    tamper: (b) =>
      beforeLast(
        b,
        '-- ─── Post-verify gate ─',
        `UPDATE essentials.politicians SET is_incumbent = false WHERE external_id = -2766404;`,
      ),
  },
  {
    id: 'c12-ms2-seats-untouched',
    why: 'MS-2\'s 174 seats must still be seated after a city wave',
    expect: /expected 174 seated Mississippi legislative offices from MS-2, found 173/,
    tamper: (b) =>
      `${b.slice(0, b.lastIndexOf('-- ─── Post-verify gate ─'))}
       DELETE FROM essentials.office_terms ot
        USING essentials.offices o, essentials.districts d
        WHERE ot.office_id = o.id AND o.district_id = d.id
          AND d.mtfcc = 'G5220' AND lower(d.state) = 'ms'
          AND ot.office_id = (SELECT o2.id FROM essentials.offices o2
                                JOIN essentials.districts d2 ON d2.id = o2.district_id
                               WHERE d2.mtfcc = 'G5220' AND lower(d2.state) = 'ms'
                               ORDER BY o2.id LIMIT 1);
       ${b.slice(b.lastIndexOf('-- ─── Post-verify gate ─'))}`,
  },
];

// 🔴 psql writes RAISE NOTICE to STDERR, so the gate messages — the only evidence a gate actually
// ran — are invisible to a stdout-only capture. Both streams are kept, on success and on failure.
function runSql(path) {
  const r = spawnSync(PSQL, [process.env.DATABASE_URL, '-v', 'ON_ERROR_STOP=1', '-f', path], {
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
  return { ok: r.status === 0, out: `${r.stdout || ''}${r.stderr || ''}` };
}

function write(name, body) {
  mkdirSync(OUT, { recursive: true });
  const p = join(OUT, name);
  writeFileSync(p, `BEGIN;\n\n${body}\n\nROLLBACK;\n`, 'utf8');
  return p;
}

const wantClean = process.argv.includes('--dry-run') || process.argv.includes('--all');
const wantControls = process.argv.includes('--controls') || process.argv.includes('--all');
let failures = 0;

if (wantClean) {
  const p = write('clean.sql', BODY);
  const r = runSql(p);
  const notices = (r.out.match(/NOTICE:.*/g) || []).join('\n');
  if (!r.ok) {
    console.log(`🔴 CLEAN DRY RUN FAILED\n${r.out}`);
    failures++;
  } else {
    console.log(`✅ clean dry run: both migrations ran inside one transaction and rolled back.\n${notices}`);
  }
}

if (wantControls) {
  console.log('\n── controls ──────────────────────────────────────────────────────────');
  for (const c of CONTROLS) {
    if (c.skip) {
      console.log(`  ${c.id.padEnd(30)} SKIPPED BY DESIGN — ${c.why} (see the comment; it runs after the gate it would test)`);
      continue;
    }
    const p = write(`${c.id}.sql`, c.tamper(BODY));
    const r = runSql(p);
    if (r.ok) {
      console.log(`  ${c.id.padEnd(30)} 🔴 DID NOT FIRE — ${c.why}`);
      failures++;
    } else if (!c.expect.test(r.out)) {
      const first = (r.out.match(/ERROR:.*/) || ['(no ERROR line)'])[0];
      console.log(`  ${c.id.padEnd(30)} 🔴 BROKEN — aborted for the WRONG reason: ${first.slice(0, 160)}`);
      failures++;
    } else {
      const msg = (r.out.match(/ERROR:.*/) || [''])[0];
      console.log(`  ${c.id.padEnd(30)} ✅ fired — ${msg.replace(/^ERROR:\s*/, '').slice(0, 130)}`);
    }
  }
}

if (failures) {
  console.log(`\n🔴 ${failures} problem(s). Nothing may be applied until every control fires on its own target.`);
  process.exit(1);
}
console.log('\nAll requested checks passed.');

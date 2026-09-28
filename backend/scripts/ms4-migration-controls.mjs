#!/usr/bin/env node
/**
 * ms4-migration-controls.mjs — Knight program, wave MS-4.
 *
 * Builds the CC_0173 + CC_0174 dry run as ONE transaction ending in ROLLBACK, and one TAMPERED
 * copy per gate, so every gate is watched failing on its own target before the real apply.
 *
 * 🔴 A CONTROL THAT ABORTS FOR THE WRONG REASON PROVES NOTHING, so each control declares the
 * message it EXPECTS and a mismatch is reported as BROKEN rather than as a pass.
 * 🔴 AND AN EARLIER GATE SHADOWS A LATER ONE BY DEFAULT — five of MS-3's nineteen controls were
 * shadowed on first writing. Each tamper below is chosen so the gate it targets is the FIRST that
 * can see it; where the obvious tamper would trip something earlier, the comment says so.
 *
 * Usage:
 *   node scripts/ms4-migration-controls.mjs --dry-run
 *   node scripts/ms4-migration-controls.mjs --controls
 *   node scripts/ms4-migration-controls.mjs --all
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import * as dotenv from 'dotenv';
dotenv.config();

const PSQL = process.env.PSQL_BIN || 'C:/Program Files/PostgreSQL/18/bin/psql';
const OUT = 'data/seed-harrison-2026/_dryrun';
const STRUCTURE = join('migrations', 'CC_0173_harrison_county_structure.sql');
const OCCUPANCY = join('migrations', 'CC_0174_harrison_county_incumbents.sql');

const strip = (sql) =>
  sql.split(/\r?\n/).filter((l) => !/^\s*(BEGIN|COMMIT)\s*;\s*$/i.test(l)).join('\n');

const BODY = `${strip(readFileSync(STRUCTURE, 'utf8'))}\n\n${strip(readFileSync(OCCUPANCY, 'utf8'))}`;

const STRUCT_GATE = '-- ─── Post-verify gate ─';

function before(body, marker, sql) {
  const i = body.indexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker}`);
  const at = body.lastIndexOf('\n', i) + 1;
  return body.slice(0, at) + sql + '\n' + body.slice(at);
}
/** 🔴 Both migrations carry a "Post-verify gate" line; a tamper meant for the SECOND must use this. */
function beforeLast(body, marker, sql) {
  const i = body.lastIndexOf(marker);
  if (i < 0) throw new Error(`marker not found: ${marker}`);
  const at = body.lastIndexOf('\n', i) + 1;
  return body.slice(0, at) + sql + '\n' + body.slice(at);
}

const D = (n) => `(SELECT id FROM essentials.districts WHERE geo_id = 'harrison-ms-supervisor-district-${n}' AND mtfcc = 'X0074')`;

const CONTROLS = [
  {
    id: 'c1-preflight-supervisor-polygons',
    why: 'the structure migration must refuse to run without the five supervisor polygons',
    expect: /pre-flight: expected 5 X0074 Harrison County supervisor polygons, found 4/,
    tamper: (b) => `DELETE FROM essentials.geofence_boundaries WHERE geo_id = 'harrison-ms-supervisor-district-3' AND mtfcc = 'X0074';\n${b}`,
  },
  {
    id: 'c2-preflight-foreign-x0074',
    why: 'X0074 has no allocator, so a row that is not Harrison County\'s must stop the migration',
    // 🔴 ADDING a sixth row trips the count gate first; RENAME one so the count stays at 5.
    expect: /X0074 polygon\(s\) are not Harrison County supervisor districts/,
    tamper: (b) => `UPDATE essentials.geofence_boundaries SET geo_id = 'somebody-elses-district' WHERE geo_id = 'harrison-ms-supervisor-district-1' AND mtfcc = 'X0074';\n${b}`,
  },
  {
    id: 'c3-preflight-county-polygon',
    why: 'the seven countywide officers hang on the TIGER county polygon, which must exist',
    expect: /expected the TIGER county polygon 28047\/G4020, found 0/,
    tamper: (b) => `DELETE FROM essentials.geofence_boundaries WHERE geo_id = '28047' AND mtfcc = 'G4020';\n${b}`,
  },
  {
    id: 'c4-county-row-duplicated',
    why: 'a second Harrison County row would split the county and leave half of it unreachable',
    // The pre-flight already refuses two county rows, which is the earliest place this can be seen.
    expect: /expected exactly 1 Harrison County COUNTY districts row \(28047\/G4020\), found 2/,
    tamper: (b) => `INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
                    VALUES ('28047', 'Harrison County (TAMPER)', 'COUNTY', 'ms', 'G4020');\n${b}`,
  },
  {
    id: 'c5-four-offices-per-district',
    why: 'a total of 20 district offices is also what one empty district and one doubled would give',
    // 🔴 MOVE an office rather than add one: the total stays 27 and only the per-district gate sees it.
    expect: /supervisor district\(s\) do not hold exactly 4 offices/,
    tamper: (b) => before(b, STRUCT_GATE,
      `UPDATE essentials.offices SET district_id = ${D(1)} WHERE title = 'Constable, District 5';`),
  },
  {
    id: 'c6-offices-per-chamber',
    why: '"four per district" can be satisfied by the wrong four — the chamber counts pin which four',
    // Moving the CHAMBER leaves every district at four, so only the per-chamber gate can object.
    expect: /Harrison County chamber\(s\) hold the wrong number of offices/,
    tamper: (b) => before(b, STRUCT_GATE,
      `UPDATE essentials.offices SET chamber_id =
         (SELECT c.id FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id
           WHERE g.name = 'Harrison County, Mississippi, US' AND c.name = 'Harrison County Board of Supervisors')
        WHERE title = 'Constable, District 5';`),
  },
  {
    id: 'c7-office-without-polygon',
    why: 'the one failure mode CI cannot catch: an office on a district with no geometry',
    // Removing the polygon AFTER the pre-flight leaves every count right; only this gate sees it.
    expect: /Harrison County office\(s\) sit on a district with NO polygon/,
    tamper: (b) => before(b, STRUCT_GATE,
      `DELETE FROM essentials.geofence_boundaries WHERE geo_id = 'harrison-ms-supervisor-district-4' AND mtfcc = 'X0074';`),
  },
  {
    id: 'c8-biloxi-untouched',
    why: 'a county wave has no business moving the 8 Biloxi offices MS-3 seated',
    expect: /expected 8 Biloxi offices from MS-3, found 7/,
    tamper: (b) => before(b, STRUCT_GATE,
      `DELETE FROM essentials.offices o USING essentials.chambers c, essentials.governments g
        WHERE o.chamber_id = c.id AND c.government_id = g.id
          AND g.name = 'City of Biloxi, Mississippi, US'
          AND o.title = 'Council Member, Ward 6';`),
  },
  {
    id: 'c9-legislature-untouched',
    why: 'nor the 174 legislative offices MS-2 seated',
    expect: /expected 174 Mississippi legislative offices from MS-2, found 173/,
    tamper: (b) => before(b, STRUCT_GATE,
      `DELETE FROM essentials.offices o USING essentials.districts d
        WHERE d.id = o.district_id AND d.mtfcc = 'G5210' AND lower(d.state) = 'ms'
          AND o.id = (SELECT o2.id FROM essentials.offices o2
                        JOIN essentials.districts d2 ON d2.id = o2.district_id
                       WHERE d2.mtfcc = 'G5210' AND lower(d2.state) = 'ms' ORDER BY o2.id LIMIT 1);`),
  },
  {
    id: 'c10-seated-count',
    why: 'office_current_holder LEFT JOINs from offices, so the gate must count politician_id',
    expect: /expected 27 seated Harrison County offices, found 26/,
    tamper: (b) => b.replace(
      "  ('Constable, District 3',             -2766416::bigint, '2024-01-01'::date, 'year',    'elected'),\n", ''),
  },
  {
    id: 'c11-precision-split',
    why: 'a later pass must not promote the three undated election commissioners by copying colleagues',
    expect: /expected 5 day \/ 19 year \/ 3 unknown terms, found 5 \/ 20 \/ 2/,
    tamper: (b) => b.replace(
      "('Election Commissioner, District 3', -2766411::bigint, NULL,               'unknown', 'unknown')",
      "('Election Commissioner, District 3', -2766411::bigint, '2024-01-01'::date, 'year',    'elected')"),
  },
  {
    id: 'c12-supervisor-oath-date',
    why: 'the first Monday of January 2024 was a legal holiday; the term began on the Tuesday',
    // 🔴 Keep the precision so the 5/19/3 split still passes and this gate is the first to see it.
    expect: /supervisor term_start is 2024-01-01, expected 2024-01-02/,
    tamper: (b) => b.replace(
      "('Supervisor, District 3',            -2766433::bigint, '2024-01-02'::date, 'day',     'elected')",
      "('Supervisor, District 3',            -2766433::bigint, '2024-01-01'::date, 'day',     'elected')"),
  },
  {
    id: 'c13-undated-commissioners-are-1-3-5',
    why: 'the 5/19/3 counts alone cannot see the unknown landing on the WRONG three districts',
    // Swap which commissioner is undated: counts stay 5/19/3, only the by-district assertion moves.
    expect: /expected Election Commissioners 1, 3 and 5 undated, found 2 of 3/,
    tamper: (b) => b
      .replace("('Election Commissioner, District 1', -2766413::bigint, NULL,               'unknown', 'unknown')",
               "('Election Commissioner, District 1', -2766413::bigint, '2024-01-01'::date, 'year',    'elected')")
      .replace("('Election Commissioner, District 2', -2766412::bigint, '2024-01-01'::date, 'year',    'elected')",
               "('Election Commissioner, District 2', -2766412::bigint, NULL,               'unknown', 'unknown')"),
  },
  {
    id: 'c14-is-incumbent',
    why: 'is_incumbent defaults to false, and a seated person without it is hidden from address search',
    expect: /Harrison County official\(s\) are not is_incumbent\/is_active/,
    tamper: (b) => beforeLast(b, STRUCT_GATE,
      `UPDATE essentials.politicians SET is_incumbent = false WHERE external_id = -2766419;`),
  },
  {
    id: 'c15-four-distinct-people-per-district',
    why: 'four terms held by one person would pass a count of 20',
    expect: /supervisor district\(s\) do not hold 4 DISTINCT people/,
    tamper: (b) => beforeLast(b, STRUCT_GATE,
      `UPDATE essentials.office_terms ot SET politician_id =
         (SELECT id FROM essentials.politicians WHERE external_id = -2766435)
        FROM essentials.offices o
       WHERE ot.office_id = o.id AND o.title = 'Constable, District 1';`),
  },
  {
    id: 'c16-biloxi-seats-untouched',
    why: 'MS-3\'s 8 seats must still be seated after a county wave',
    expect: /expected 8 seated Biloxi offices from MS-3, found 7/,
    tamper: (b) => beforeLast(b, STRUCT_GATE,
      `DELETE FROM essentials.office_terms ot USING essentials.offices o, essentials.districts d
        WHERE ot.office_id = o.id AND o.district_id = d.id
          AND d.geo_id = 'biloxi-ms-ward-4' AND d.mtfcc = 'X0073';`),
  },
];

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
  if (!r.ok) {
    console.log(`🔴 CLEAN DRY RUN FAILED\n${r.out}`);
    failures++;
  } else {
    console.log('✅ clean dry run: both migrations ran inside one transaction and rolled back.');
    console.log((r.out.match(/NOTICE:.*/g) || []).join('\n'));
  }
}

if (wantControls) {
  console.log('\n── controls ──────────────────────────────────────────────────────────');
  for (const c of CONTROLS) {
    const p = write(`${c.id}.sql`, c.tamper(BODY));
    const r = runSql(p);
    if (r.ok) {
      console.log(`  ${c.id.padEnd(38)} 🔴 DID NOT FIRE — ${c.why}`);
      failures++;
    } else if (!c.expect.test(r.out)) {
      const first = (r.out.match(/ERROR:.*/) || ['(no ERROR line)'])[0];
      console.log(`  ${c.id.padEnd(38)} 🔴 BROKEN — wrong reason: ${first.slice(0, 150)}`);
      failures++;
    } else {
      const msg = (r.out.match(/ERROR:.*/) || [''])[0];
      console.log(`  ${c.id.padEnd(38)} ✅ fired — ${msg.replace(/^ERROR:\s*/, '').slice(0, 110)}`);
    }
  }
}

if (failures) {
  console.log(`\n🔴 ${failures} problem(s). Nothing may be applied until every control fires on its own target.`);
  process.exit(1);
}
console.log('\nAll requested checks passed.');

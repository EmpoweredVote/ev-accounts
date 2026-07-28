#!/usr/bin/env -S npx tsx
/**
 * coverage-init.ts — generate a coverage YAML for a state from the live DB.
 *
 *   npx tsx scripts/coverage-init.ts --state ca [--write]
 *
 * Produces data/coverage/<state>.yaml with:
 *   • Chamber-aggregate rows — U.S. House (cd), State Senate (sldu), State House
 *     (sldl). expected_seats = TIGER legislative-layer counts (true seat totals).
 *   • A statewide-offices row (Governor / U.S. Senate / constitutional officers)
 *     where records attach to the bare state OCD. expected_seats: null.
 *   • Local rows — counties / cities / school districts that have politicians.
 *     expected_seats = current loaded roster (BASELINE — verify against official sizes).
 * Auto columns are snapshotted at generation; the admin API recomputes them live.
 * rules.skip_topics and universe.tribes are left empty for a human to fill.
 *
 * Without --write it prints the YAML to stdout (dry run).
 */
import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import { pool } from '../src/lib/db.js';
import { computeLocationStats, type LocationStats } from '../src/lib/coverageService.js';

const STATE = (() => {
  const i = process.argv.indexOf('--state');
  return (i >= 0 ? process.argv[i + 1] ?? '' : '').toLowerCase();
})();
const WRITE = process.argv.includes('--write');
if (!STATE) {
  console.error('Usage: coverage-init.ts --state <code> [--write]');
  process.exit(1);
}

const STATE_FIPS: Record<string, string> = {
  al: '01', ak: '02', az: '04', ar: '05', ca: '06', co: '08', ct: '09', de: '10',
  fl: '12', ga: '13', hi: '15', id: '16', il: '17', in: '18', ia: '19', ks: '20',
  ky: '21', la: '22', me: '23', md: '24', ma: '25', mi: '26', mn: '27', ms: '28',
  mo: '29', mt: '30', ne: '31', nv: '32', nh: '33', nj: '34', nm: '35', ny: '36',
  nc: '37', nd: '38', oh: '39', ok: '40', or: '41', pa: '42', ri: '44', sc: '45',
  sd: '46', tn: '47', tx: '48', ut: '49', vt: '50', va: '51', wa: '53', wv: '54',
  wi: '55', wy: '56',
};
// Complete map. It previously held only the states that already had a coverage file, so
// `--state wi` would have emitted `state_name: undefined` into the YAML — silently, since
// nothing validates it. STATE_FIPS above is already complete; these two should stay in step.
const STATE_NAME: Record<string, string> = {
  al: 'Alabama', ak: 'Alaska', az: 'Arizona', ar: 'Arkansas', ca: 'California',
  co: 'Colorado', ct: 'Connecticut', de: 'Delaware', fl: 'Florida', ga: 'Georgia',
  hi: 'Hawaii', id: 'Idaho', il: 'Illinois', in: 'Indiana', ia: 'Iowa',
  ks: 'Kansas', ky: 'Kentucky', la: 'Louisiana', me: 'Maine', md: 'Maryland',
  ma: 'Massachusetts', mi: 'Michigan', mn: 'Minnesota', ms: 'Mississippi', mo: 'Missouri',
  mt: 'Montana', ne: 'Nebraska', nv: 'Nevada', nh: 'New Hampshire', nj: 'New Jersey',
  nm: 'New Mexico', ny: 'New York', nc: 'North Carolina', nd: 'North Dakota', oh: 'Ohio',
  ok: 'Oklahoma', or: 'Oregon', pa: 'Pennsylvania', ri: 'Rhode Island', sc: 'South Carolina',
  sd: 'South Dakota', tn: 'Tennessee', tx: 'Texas', ut: 'Utah', vt: 'Vermont',
  va: 'Virginia', wa: 'Washington', wv: 'West Virginia', wi: 'Wisconsin', wy: 'Wyoming',
};

const FIPS = STATE_FIPS[STATE];
const STATE_PREFIX = `ocd-division/country:us/state:${STATE}`;

function titleCase(slug: string): string {
  return slug.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

/** slug→display-name maps from TIGER geofence names, per category. */
async function geofenceNames(mtfcc: string, strip: RegExp): Promise<Map<string, string>> {
  if (!FIPS) return new Map();
  const { rows } = await pool.query<{ name: string }>(
    `SELECT name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = $2`,
    [FIPS, mtfcc],
  );
  const map = new Map<string, string>();
  for (const r of rows) {
    // name is nullable and IS null in practice — MA has 5 G5420 rows with no name, IN has 159
    // across G5220/G5210/G5200, VA 1. Unguarded, r.name.replace() threw
    // "Cannot read properties of null (reading 'replace')" and took the whole run down, which is
    // why `--state ma` produced no output at all while ca/or/tx succeeded.
    if (!r.name || !r.name.trim()) continue;
    const slug = r.name.replace(strip, '').toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
    if (!slug) continue;
    map.set(slug, r.name.replace(strip, '').trim());
  }
  return map;
}

async function geofenceCount(mtfcc: string): Promise<number> {
  if (!FIPS) return 0;
  const { rows } = await pool.query<{ n: string }>(
    `SELECT COUNT(*) n FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = $2`,
    [FIPS, mtfcc],
  );
  return Number(rows[0]?.n ?? 0);
}

/** Distinct jurisdiction OCD ids of one kind that have ≥1 active politician. */
async function localJurisdictions(kind: string): Promise<string[]> {
  const { rows } = await pool.query<{ ocd: string }>(
    `SELECT DISTINCT regexp_replace(d.ocd_id, $1, $2) AS ocd
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id
       -- (dropped in migration 1463). This join is exactly one row per office, so it cannot fan out.
       -- coverageService.ts and coverageMapService.ts were ported at the time; this script was
       -- missed, which left it dead against the live schema — every run failed with
       -- "column o.politician_id does not exist", which is why no coverage file has been added since.
       JOIN essentials.office_current_holder och ON och.office_id = o.id
       JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active = true
      WHERE d.ocd_id LIKE $3 AND d.ocd_id ~ $4
      ORDER BY ocd`,
    [`^(${STATE_PREFIX}/${kind}:[^/]+).*$`, '\\1', `${STATE_PREFIX}/%`, `/${kind}:`],
  );
  return rows.map((r) => r.ocd);
}

interface Row {
  ocd_id: string;
  ocd_kind?: string;
  match?: 'subtree' | 'exact' | 'kind';
  name: string;
  level: 'federal' | 'state' | 'county' | 'local' | 'school';
  expected_seats: number | null;
  stats: LocationStats;
}

async function build(): Promise<{ rows: Row[]; universeCats: string[] }> {
  const rows: Row[] = [];

  // 1. Chambers (aggregate by kind) — expected = TIGER seat universe.
  const chambers: { kind: string; mtfcc: string; name: string; level: Row['level'] }[] = [
    { kind: 'cd', mtfcc: 'G5200', name: 'U.S. House delegation', level: 'federal' },
    { kind: 'sldu', mtfcc: 'G5210', name: 'State Senate', level: 'state' },
    { kind: 'sldl', mtfcc: 'G5220', name: 'State House', level: 'state' },
  ];
  for (const c of chambers) {
    const stats = await computeLocationStats({ ocd_id: STATE_PREFIX, ocd_kind: c.kind, match: 'kind' });
    if (stats.stances.total === 0) continue;
    const expected = (await geofenceCount(c.mtfcc)) || null;
    rows.push({ ocd_id: STATE_PREFIX, ocd_kind: c.kind, match: 'kind', name: c.name, level: c.level, expected_seats: expected, stats });
  }

  // 2. Statewide offices (Governor / U.S. Senate / constitutional officers) — exact OCD.
  const swStats = await computeLocationStats({ ocd_id: STATE_PREFIX, match: 'exact' });
  if (swStats.stances.total > 0) {
    rows.push({ ocd_id: STATE_PREFIX, match: 'exact', name: 'Statewide offices (Gov, U.S. Senate, officers)', level: 'state', expected_seats: null, stats: swStats });
  }

  // 3. Local rows — counties / cities / school districts with politicians.
  const locals: { kind: string; mtfcc: string; strip: RegExp; level: Row['level']; suffix: string }[] = [
    { kind: 'county', mtfcc: 'G4020', strip: / county$/i, level: 'county', suffix: ' County' },
    { kind: 'place', mtfcc: 'G4110', strip: / (city|town)$/i, level: 'local', suffix: '' },
    { kind: 'school_district', mtfcc: 'G5420', strip: / school district$/i, level: 'school', suffix: ' School District' },
  ];
  for (const l of locals) {
    const names = await geofenceNames(l.mtfcc, l.strip);
    for (const ocd of await localJurisdictions(l.kind)) {
      const slug = ocd.split(`/${l.kind}:`)[1] ?? '';
      const stats = await computeLocationStats({ ocd_id: ocd, match: 'subtree' });
      const display = (names.get(slug) ?? titleCase(slug)) + l.suffix;
      rows.push({ ocd_id: ocd, match: 'subtree', name: display, level: l.level, expected_seats: stats.stances.total || null, stats });
    }
  }

  // Universe categories present (geofence denominator exists).
  const universeCats: string[] = [];
  for (const [mtfcc, label] of [['G4020', 'counties'], ['G4110', 'places'], ['G5420', 'schools']] as const) {
    if ((await geofenceCount(mtfcc)) > 0) universeCats.push(label);
  }
  return { rows, universeCats };
}

function emitYaml(rows: Row[]): string {
  const L: string[] = [];
  L.push(`# Empowered Vote — Data Coverage Tracker: ${STATE_NAME[STATE] ?? STATE.toUpperCase()}`);
  L.push('# Generated by scripts/coverage-init.ts from the live DB. See data/coverage/README.md.');
  L.push('# expected_seats: chambers = real TIGER seat counts; local bodies = loaded-roster');
  L.push('#   BASELINE (verify against official council/board sizes). null = unknown.');
  L.push('# Fill in rules.skip_topics and universe.tribes by hand as needed.');
  L.push('');
  L.push(`state: ${STATE.toUpperCase()}`);
  L.push(`state_name: ${STATE_NAME[STATE] ?? STATE.toUpperCase()}`);
  L.push('synced_at: null');
  L.push('');
  L.push('universe:');
  L.push(`  state_fips: "${FIPS ?? ''}"`);
  L.push('  tribes: []   # add federally recognized tribes for this state (no geofences yet)');
  L.push('');
  L.push('rules:');
  L.push('  skip_topics: []   # add jurisdiction rules, e.g. topics barred by state law');
  L.push('  notes: []');
  L.push('');
  L.push('locations:');
  const groups: { level: Row['level']; title: string }[] = [
    { level: 'federal', title: 'Federal delegation' },
    { level: 'state', title: 'State government' },
    { level: 'county', title: 'Counties' },
    { level: 'local', title: 'Cities & municipalities' },
    { level: 'school', title: 'School districts' },
  ];
  for (const g of groups) {
    const inGroup = rows.filter((r) => r.level === g.level);
    if (inGroup.length === 0) continue;
    L.push(`  # ── ${g.title} (${inGroup.length}) ──`);
    for (const r of inGroup) {
      L.push(`  - ocd_id: ${r.ocd_id}`);
      if (r.ocd_kind) L.push(`    ocd_kind: ${r.ocd_kind}`);
      if (r.match && r.match !== 'subtree') L.push(`    match: ${r.match}`);
      L.push(`    name: ${/[:#]/.test(r.name) ? JSON.stringify(r.name) : r.name}`);
      L.push(`    level: ${r.level}`);
      L.push('    status: active');
      L.push(`    expected_seats: ${r.expected_seats ?? 'null'}`);
      L.push('    geofenced: true');
      L.push('    donors: none');
      L.push('    candidates: none');
      L.push('    treasury: none');
      L.push(`    populated: ${r.stats.populated}`);
      L.push(`    headshots: ${r.stats.headshots}`);
      L.push(`    stances: { researched: ${r.stats.stances.researched}, total: ${r.stats.stances.total} }`);
      L.push(`    last_researched: ${r.stats.last_researched ?? 'null'}`);
      L.push('');
    }
  }
  return L.join('\n');
}

async function main(): Promise<void> {
  const { rows, universeCats } = await build();
  const yaml = emitYaml(rows);
  console.error(`[coverage-init] ${STATE.toUpperCase()} — ${rows.length} rows | universe categories: ${universeCats.join(', ') || 'none'}`);
  if (WRITE) {
    const out = path.resolve(import.meta.dirname, '../data/coverage', `${STATE}.yaml`);
    fs.writeFileSync(out, yaml + '\n', 'utf8');
    console.error(`[coverage-init] Wrote ${out}`);
  } else {
    process.stdout.write(yaml + '\n');
    console.error('[coverage-init] (dry run — pass --write to save)');
  }
  await pool.end();
}

main().catch((e) => {
  console.error('[coverage-init] FATAL', e);
  process.exit(1);
});

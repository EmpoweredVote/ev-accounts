#!/usr/bin/env -S npx tsx
/**
 * coverage-sync.ts — refresh the AUTO columns of a coverage YAML from the live DB.
 *
 *   npx tsx scripts/coverage-sync.ts --state ut [--dry-run]
 *
 * Auto columns (per data/coverage/README.md): populated, headshots, stances,
 * last_researched — plus the top-level synced_at stamp. Manual columns
 * (geofenced, donors, candidates, treasury, status) and rules are never touched.
 *
 * Writes are SURGICAL line edits (not yaml.dump) so the file's comments,
 * section headers, and hand-authored formatting are preserved.
 *
 * Join logic is shared with the admin API via computeLocationStats() in
 * src/lib/coverageService.ts — one source of truth for the SQL.
 */
import 'dotenv/config';
import fs from 'node:fs';
import { pool } from '../src/lib/db.js';
import {
  coverageFilePath,
  readCoverageFile,
  computeLocationStats,
  computeTreasuryForState,
  resolveLocationGeoIds,
  locationTreasury,
  type LocationStats,
  type Tristate,
} from '../src/lib/coverageService.js';

function arg(name: string): string | null {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] ?? null : null;
}
const DRY_RUN = process.argv.includes('--dry-run');
const STATE = (arg('--state') ?? 'ut').toLowerCase();

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

function fmtStances(s: { researched: number; total: number }): string {
  return `{ researched: ${s.researched}, total: ${s.total} }`;
}
function fmtLast(d: string | null): string {
  return d ?? 'null';
}

async function main(): Promise<void> {
  const file = coverageFilePath(STATE);
  if (!fs.existsSync(file)) {
    console.error(`[coverage-sync] No coverage file: ${file}`);
    process.exit(1);
  }

  // Parse to get the ordered list of locations, then compute stats per row.
  // Keyed by ARRAY INDEX (chamber-aggregate rows can share the same ocd_id).
  const parsed = readCoverageFile(STATE);
  const treasury = await computeTreasuryForState(STATE);
  const geoIdByOcd = await resolveLocationGeoIds(parsed.locations);
  const stats: LocationStats[] = [];
  const treasuryByIndex: Tristate[] = [];
  for (const loc of parsed.locations) {
    stats.push(await computeLocationStats(loc));
    treasuryByIndex.push(locationTreasury(loc, treasury, geoIdByOcd.get(loc.ocd_id)));
  }

  // Report the diff.
  console.error(`[coverage-sync] ${STATE.toUpperCase()} — ${parsed.locations.length} locations\n`);
  console.error(
    `${'jurisdiction'.padEnd(34)} ${'populated'.padEnd(10)} ${'headshots'.padEnd(10)} ${'stances'.padEnd(12)} last`,
  );
  parsed.locations.forEach((loc, i) => {
    const s = stats[i];
    const changed =
      loc.populated !== s.populated ||
      loc.headshots !== s.headshots ||
      loc.treasury !== treasuryByIndex[i] ||
      loc.stances?.researched !== s.stances.researched ||
      loc.stances?.total !== s.stances.total ||
      (loc.last_researched ?? null) !== s.last_researched;
    const flag = changed ? '*' : ' ';
    console.error(
      `${flag} ${loc.name.padEnd(32)} ${String(s.populated).padEnd(10)} ${s.headshots.padEnd(10)} ${`${s.stances.researched}/${s.stances.total}`.padEnd(12)} ${fmtLast(s.last_researched)}`,
    );
  });

  if (DRY_RUN) {
    console.error('\n[coverage-sync] --dry-run: no file written. (* = would change)');
    await pool.end();
    return;
  }

  // Surgical line edits: track the current location block by counting ocd_id
  // lines (index-based — chamber rows share an ocd_id), rewrite only the four
  // auto-field lines within each block + synced_at.
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  let blockIdx = -1;
  let syncedStamped = false;
  const out = lines.map((raw) => {
    // These files are checked out CRLF on Windows, so every line arrives with a trailing "\r".
    // Match against the stripped text and re-append the original ending. Two bugs came from not
    // doing this: the `$`-anchored synced_at regex NEVER matched (JS `.` does not match `\r`, so
    // `.*$` cannot reach end-of-string), leaving the stamp permanently stale even though the script
    // reported writing it; and the auto-field replacements below silently dropped the "\r",
    // leaving the file with mixed line endings.
    const eol = raw.endsWith('\r') ? '\r' : '';
    const line = eol ? raw.slice(0, -1) : raw;
    const keep = () => raw;
    const put = (s: string) => s + eol;

    if (/^synced_at:/.test(line) && !syncedStamped) {
      syncedStamped = true;
      return put(`synced_at: ${today()}`);
    }
    const ocd = line.match(/^\s*-\s*ocd_id:\s*\S+\s*$/);
    if (ocd) {
      blockIdx += 1;
      return keep();
    }
    if (blockIdx < 0) return keep();
    const s = stats[blockIdx];
    if (!s) return keep();
    const indent = line.match(/^(\s+)\w/)?.[1] ?? '    ';
    if (/^\s+populated:/.test(line)) return put(`${indent}populated: ${s.populated}`);
    if (/^\s+headshots:/.test(line)) return put(`${indent}headshots: ${s.headshots}`);
    if (/^\s+treasury:/.test(line)) return put(`${indent}treasury: ${treasuryByIndex[blockIdx]}`);
    if (/^\s+stances:/.test(line)) return put(`${indent}stances: ${fmtStances(s.stances)}`);
    if (/^\s+last_researched:/.test(line)) return put(`${indent}last_researched: ${fmtLast(s.last_researched)}`);
    return keep();
  });

  fs.writeFileSync(file, out.join('\n'), 'utf8');
  console.error(`\n[coverage-sync] Wrote ${file} (synced_at: ${today()}).`);
  await pool.end();
}

main().catch((e) => {
  console.error('[coverage-sync] FATAL', e);
  process.exit(1);
});

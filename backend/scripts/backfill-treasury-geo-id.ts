#!/usr/bin/env -S npx tsx
/**
 * backfill-treasury-geo-id.ts — populate treasury.municipalities.geo_id from the
 * TIGER geofence backbone (essentials.geofence_boundaries), so treasury budget data
 * joins to coverage jurisdictions exactly instead of by fuzzy name+state slug.
 *
 *   npx tsx backend/scripts/backfill-treasury-geo-id.ts              # dry run (default)
 *   npx tsx backend/scripts/backfill-treasury-geo-id.ts --state ca   # one state only
 *   npx tsx backend/scripts/backfill-treasury-geo-id.ts --write      # apply
 *
 * Matching (identical to treasuryService.resolveTreasuryGeoId, shared helpers):
 *   entity_type → mtfcc:  city/town/municipality → G4110, county → G4020, school_district → G5420
 *   state (2-letter)      → FIPS via STATE_ABBR_TO_FIPS
 *   normalized name match (treasury name kept whole except counties; geofence suffix stripped)
 *
 * SAFE: additive — only sets geo_id where it is currently NULL, never overwrites.
 * Townships / libraries / special / nonprofit / conservancy rows have no TIGER place
 * geometry and are expected to stay NULL (reported, not an error). Dry run by default.
 */
// Load .env (from backend/ cwd) BEFORE importing src/lib — env.ts validates at import time.
// Run from ev-accounts/backend, matching the other backfill scripts.
import 'dotenv/config';
import pg from 'pg';
import {
  STATE_ABBR_TO_FIPS,
  TREASURY_ENTITY_MTFCC,
  treasuryNameSlug,
  geofenceNameSlug,
} from '../src/lib/treasuryService.js';

const WRITE = process.argv.includes('--write');
const STATE_FILTER = (() => {
  const i = process.argv.indexOf('--state');
  return i >= 0 ? (process.argv[i + 1] ?? '').toLowerCase() : null;
})();

interface MuniRow {
  id: string;
  name: string;
  state: string;
  entity_type: string | null;
  geo_id: string | null;
  budgets: number;
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('DATABASE_URL environment variable is required');
    process.exit(1);
  }
  const pool = new pg.Pool({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } });

  try {
    const { rows: munis } = await pool.query<MuniRow>(
      `SELECT m.id, m.name, m.state, m.entity_type, m.geo_id, COUNT(b.id)::int AS budgets
         FROM treasury.municipalities m
         LEFT JOIN treasury.budgets b ON b.municipality_id = m.id
        ${STATE_FILTER ? 'WHERE lower(m.state) = $1' : ''}
        GROUP BY m.id, m.name, m.state, m.entity_type, m.geo_id
        ORDER BY m.state, m.name`,
      STATE_FILTER ? [STATE_FILTER] : [],
    );

    // Preload geofences once per (fips, mtfcc) needed, into a slug→geo_id map.
    const geofenceCache = new Map<string, Map<string, string[]>>(); // `${fips}|${mtfcc}` → slug → geo_ids
    async function geofencesFor(fips: string, mtfcc: string): Promise<Map<string, string[]>> {
      const key = `${fips}|${mtfcc}`;
      let m = geofenceCache.get(key);
      if (m) return m;
      m = new Map();
      const { rows } = await pool.query<{ geo_id: string; name: string }>(
        `SELECT geo_id, name FROM essentials.geofence_boundaries WHERE state = $1 AND mtfcc = $2`,
        [fips, mtfcc],
      );
      for (const r of rows) {
        const s = geofenceNameSlug(r.name, mtfcc);
        const arr = m.get(s) ?? [];
        arr.push(r.geo_id);
        m.set(s, arr);
      }
      geofenceCache.set(key, m);
      return m;
    }

    const resolved: { row: MuniRow; geoId: string }[] = [];
    const alreadySet: MuniRow[] = [];
    const ambiguous: MuniRow[] = [];
    const unmatched: MuniRow[] = [];
    const unsupported: MuniRow[] = []; // entity_type or state not mappable

    for (const row of munis) {
      if (row.geo_id) {
        alreadySet.push(row);
        continue;
      }
      const mtfcc = row.entity_type ? TREASURY_ENTITY_MTFCC[row.entity_type] : undefined;
      const fips = STATE_ABBR_TO_FIPS[row.state.toLowerCase()];
      if (!mtfcc || !fips) {
        unsupported.push(row);
        continue;
      }
      const slug = treasuryNameSlug(row.name, row.entity_type!);
      const hits = (await geofencesFor(fips, mtfcc)).get(slug) ?? [];
      if (hits.length === 1) resolved.push({ row, geoId: hits[0] });
      else if (hits.length > 1) ambiguous.push(row);
      else unmatched.push(row);
    }

    // ---- Report ----
    const withBudget = (rs: MuniRow[]) => rs.filter((r) => r.budgets > 0).length;
    console.log(`\n${WRITE ? '🖊  WRITE' : '🔎 DRY RUN'} — treasury.municipalities geo_id backfill`);
    console.log(`${'='.repeat(64)}`);
    console.log(`Scope:              ${STATE_FILTER ? STATE_FILTER.toUpperCase() : 'all states'}`);
    console.log(`Total municipalities: ${munis.length}`);
    console.log(`  already had geo_id: ${alreadySet.length}`);
    console.log(`  resolved now:       ${resolved.length} (${withBudget(resolved.map((r) => r.row))} budget-bearing)`);
    console.log(`  ambiguous (skipped):${ambiguous.length}`);
    console.log(`  unmatched:          ${unmatched.length} (${withBudget(unmatched)} budget-bearing)`);
    console.log(`  unsupported type:   ${unsupported.length} (${withBudget(unsupported)} budget-bearing)`);

    // Per-state resolved-with-budget breakdown (the number coverage cares about)
    const byState = new Map<string, { resolvedB: number; totalB: number }>();
    for (const r of munis.filter((m) => m.budgets > 0)) {
      const s = byState.get(r.state) ?? { resolvedB: 0, totalB: 0 };
      s.totalB++;
      byState.set(r.state, s);
    }
    for (const { row } of resolved) {
      if (row.budgets > 0) byState.get(row.state)!.resolvedB++;
    }
    console.log('\nBudget-bearing municipalities — geo_id resolved / total, by state:');
    for (const [st, s] of [...byState.entries()].sort()) {
      console.log(`  ${st}: ${s.resolvedB}/${s.totalB}`);
    }

    const showList = (label: string, rs: MuniRow[]) => {
      if (rs.length === 0) return;
      console.log(`\n${label} (${rs.length}):`);
      for (const r of rs.slice(0, 60)) {
        console.log(`  ${r.budgets > 0 ? '💰' : '  '} ${r.name} (${r.entity_type ?? '?'}, ${r.state})`);
      }
      if (rs.length > 60) console.log(`  … +${rs.length - 60} more`);
    };
    showList('UNMATCHED (no geofence by name)', unmatched);
    showList('AMBIGUOUS (multiple geofences, skipped)', ambiguous);
    showList('UNSUPPORTED (entity_type/state not mappable — expected NULL)', unsupported);

    if (!WRITE) {
      console.log('\n[DRY RUN] — no rows written. Re-run with --write to apply.');
      return;
    }

    // ---- Write (only NULL geo_id rows; never overwrite) ----
    let written = 0;
    for (const { row, geoId } of resolved) {
      const res = await pool.query(
        `UPDATE treasury.municipalities SET geo_id = $1, updated_at = now()
          WHERE id = $2 AND geo_id IS NULL`,
        [geoId, row.id],
      );
      written += res.rowCount ?? 0;
    }
    console.log(`\n✅ Wrote geo_id to ${written} municipalities.`);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});

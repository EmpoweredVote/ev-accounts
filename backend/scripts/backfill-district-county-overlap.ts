/**
 * backfill-district-county-overlap.ts
 *
 * Populates essentials.district_county_overlap (migration 1315): for every sub-state
 * district polygon in essentials.geofence_boundaries, the G4020 counties it overlaps
 * (ST_Intersects + a positive ST_Area(ST_Intersection) so edge-only touches don't count).
 *
 * This is the multi-minute spatial computation that Read & Rank's /api/readrank/races
 * endpoint used to run on EVERY request (~30 s). Run it once after migration 1315, and
 * again whenever new geography is loaded into geofence_boundaries:
 *
 *   cd backend && npx tsx scripts/backfill-district-county-overlap.ts
 *
 * Idempotent and per-layer transactional: each district layer is rebuilt (delete + insert)
 * in its own transaction, so a rerun refreshes cleanly and one layer failing doesn't lose
 * the others.
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// Sub-state district layers whose county overlap drives readrank's county relevance tier.
// Keep in sync with COUNTY_OVERLAP_LAYERS in src/lib/readrankService.ts.
const DISTRICT_LAYERS = ['G5200', 'G5210', 'G5220', 'G5400', 'G5410', 'G5420', 'G4040'];

async function main(): Promise<void> {
  const client = await pool.connect();
  let grandTotal = 0;
  try {
    // Heavy spatial join — lift the per-statement timeout for this maintenance session.
    await client.query('SET statement_timeout = 0');
    for (const layer of DISTRICT_LAYERS) {
      const started = Date.now();
      try {
        await client.query('BEGIN');
        await client.query('DELETE FROM essentials.district_county_overlap WHERE district_layer = $1', [layer]);
        const { rowCount } = await client.query(
          `INSERT INTO essentials.district_county_overlap (district_layer, district_geoid, county_geoid)
           SELECT d.mtfcc, d.geo_id, c.geo_id
           FROM essentials.geofence_boundaries d
           JOIN essentials.geofence_boundaries c
             ON c.mtfcc = 'G4020'
            AND ST_Intersects(c.geometry, d.geometry)
            AND ST_Area(ST_Intersection(c.geometry, d.geometry)) > 1e-9
           WHERE d.mtfcc = $1`,
          [layer],
        );
        await client.query('COMMIT');
        grandTotal += rowCount ?? 0;
        console.log(`${layer}: ${rowCount ?? 0} overlap rows (${((Date.now() - started) / 1000).toFixed(1)}s)`);
      } catch (err) {
        await client.query('ROLLBACK').catch(() => { /* connection may be dead */ });
        throw err;
      }
    }
    console.log(`Done — ${grandTotal} district→county overlap rows across ${DISTRICT_LAYERS.length} layers.`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('backfill-district-county-overlap failed:', err);
  process.exit(1);
});

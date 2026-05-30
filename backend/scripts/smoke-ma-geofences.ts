/**
 * smoke-ma-geofences.ts
 * Phase 38: Cambridge district smoke test
 *
 * Usage: npx tsx scripts/smoke-ma-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Executor must compare against FindMyLegislator ground truth manually.
 * Any mismatch triggers MassGIS fallback investigation.
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const TEST_ADDRESSES = [
  // North Cambridge — expected MA-05 congressional (geo_id 2505)
  { label: 'Porter Square, North Cambridge', lon: -71.1190, lat: 42.3876 },
  // South Cambridge / Kendall Square — expected MA-07 congressional (geo_id 2507)
  { label: 'Kendall Square / MIT area', lon: -71.0870, lat: 42.3626 },
  // Central Cambridge / Harvard Square — verify place boundary + MA-05
  { label: 'Harvard Square, Central Cambridge', lon: -71.1190, lat: 42.3732 },
  // Cambridge/Somerville border (Inman Square area) — verify G4110 returns Cambridge not Somerville
  { label: 'Inman Square (Cambridge/Somerville border)', lon: -71.1015, lat: 42.3733 },
];

async function main() {
  if (!process.env.DATABASE_URL) {
    process.stderr.write('ERROR: DATABASE_URL not set\n');
    process.exit(1);
  }
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  try {
    for (const addr of TEST_ADDRESSES) {
      console.log(`\n=== ${addr.label} (${addr.lon}, ${addr.lat}) ===`);
      const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
        `SELECT geo_id, name, mtfcc
         FROM essentials.geofence_boundaries
         WHERE state = '25'
           AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
         ORDER BY mtfcc`,
        [addr.lon, addr.lat],
      );
      if (res.rows.length === 0) {
        console.log('  WARNING: no boundaries matched — check coordinates');
      }
      for (const row of res.rows) {
        console.log(`  ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }
    }

    // County G4020 → US House rep intersection test (MAGEO-04)
    console.log('\n=== Middlesex County G4020 → US House rep intersection ===');
    const countyRes = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
      `SELECT gb2.geo_id, gb2.name, gb2.mtfcc
       FROM essentials.geofence_boundaries gb1
       JOIN essentials.geofence_boundaries gb2
         ON gb1.mtfcc = 'G4020'
        AND gb2.mtfcc = 'G5200'
        AND ST_Intersects(gb1.geometry, gb2.geometry)
       WHERE gb1.state = '25' AND gb1.geo_id = '25017'
       ORDER BY gb2.geo_id`,
    );
    console.log(`  G4020 (Middlesex) intersects ${countyRes.rows.length} G5200 districts:`);
    for (const row of countyRes.rows) {
      console.log(`    geo_id=${row.geo_id}  name=${row.name}`);
    }
  } finally {
    await client.end();
  }
  console.log('\nSmoke test complete. Compare G5200/G5210/G5220/G4110 values against FindMyLegislator.');
  console.log('Any mismatch → investigate MassGIS fallback per CONTEXT.md.');
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

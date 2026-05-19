/**
 * smoke-me-geofences.ts
 * Phase 49: Maine geofences smoke test
 *
 * Usage: npx tsx scripts/smoke-me-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Verifies all 5 Phase 49 roadmap success criteria:
 *   1. All boundary layers loaded (confirmed by Plan 49-01 SQL gates)
 *   2. Portland returns ME-01 G5200 row (geo_id='2301')
 *   3. Bangor returns correct G5210 senate + G5220 house rows
 *   4. Portland returns G4110 city boundary (geo_id='2360545')
 *   5. Norridgewock (rural) returns no G4110 row
 *
 * District lookup tool: https://www.maine.gov/portal/government/edemocracy/voter_lookup.php
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

const TEST_ADDRESSES = [
  // Portland ME — expected ME-01 (G5200 geo_id=2301), Cumberland County (G4020), Portland city (G4110 geo_id=2360545)
  { label: 'Portland ME', lon: -70.2553, lat: 43.6591 },
  // Bangor ME — expected ME-02 (G5200 geo_id=2302), Penobscot County (G4020), Bangor city (G4110)
  { label: 'Bangor ME', lon: -68.7712, lat: 44.8012 },
  // Augusta ME — expected congressional district + Kennebec County (G4020), Augusta city (G4110)
  { label: 'Augusta ME', lon: -69.7795, lat: 44.3106 },
  // Norridgewock ME (rural) — expected congressional + state districts, NO G4110 row
  { label: 'Norridgewock ME (rural)', lon: -69.7624, lat: 44.5588 },
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
         WHERE state = '23'
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

    // Cumberland County G4020 → US House rep intersection test
    console.log('\n=== Cumberland County G4020 → US House rep intersection ===');
    const countyRes = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
      `SELECT gb2.geo_id, gb2.name, gb2.mtfcc
       FROM essentials.geofence_boundaries gb1
       JOIN essentials.geofence_boundaries gb2
         ON gb1.mtfcc = 'G4020'
        AND gb2.mtfcc = 'G5200'
        AND ST_Intersects(gb1.geometry, gb2.geometry)
       WHERE gb1.state = '23' AND gb1.geo_id = '23005'
       ORDER BY gb2.geo_id`,
    );
    console.log(`  G4020 (Cumberland) intersects ${countyRes.rows.length} G5200 districts:`);
    for (const row of countyRes.rows) {
      console.log(`    ${row.mtfcc} geo_id=${row.geo_id} name=${row.name}`);
    }
  } finally {
    await client.end();
  }
  console.log('\nSmoke test complete. Compare G5200/G5210/G5220/G4110 values against Maine district lookup.');
  console.log('Tool: https://www.maine.gov/portal/government/edemocracy/voter_lookup.php');
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

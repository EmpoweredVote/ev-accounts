/**
 * smoke-ma-towns.ts
 * Phase 48: MA COUSUB town boundary smoke test
 *
 * Tests point-in-polygon routing for MA G4040 towns loaded in Phase 48.
 * Confirms Lexington + Concord return G4040 rows; Cambridge returns G4110 only.
 *
 * Usage: npx tsx scripts/smoke-ma-towns.ts
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

interface TestPoint {
  label: string;
  lon: number;
  lat: number;
  expectG4040: boolean;         // true = expect a G4040 row; false = expect none
  expectedGeoId?: string;       // if set, assert this geo_id appears in G4040 results
}

const TEST_POINTS: TestPoint[] = [
  // Lexington town center — must return G4040 geo_id='2501735215'
  {
    label: 'Lexington MA center',
    lon: -71.2298, lat: 42.4473,
    expectG4040: true,
    expectedGeoId: '2501735215',
  },
  // Concord town center — must return G4040 geo_id='2501715060'
  {
    label: 'Concord MA center',
    lon: -71.3490, lat: 42.4604,
    expectG4040: true,
    expectedGeoId: '2501715060',
  },
  // Cambridge (incorporated city) — must return G4110 (not G4040)
  // FUNCSTAT='F' guard should have excluded Cambridge from G4040
  {
    label: 'Cambridge MA (Harvard Square)',
    lon: -71.1190, lat: 42.3732,
    expectG4040: false,
  },
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

  let failures = 0;

  try {
    for (const pt of TEST_POINTS) {
      console.log(`\n=== ${pt.label} (${pt.lon}, ${pt.lat}) ===`);
      const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
        `SELECT geo_id, name, mtfcc
         FROM essentials.geofence_boundaries
         WHERE state = '25'
           AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
         ORDER BY mtfcc`,
        [pt.lon, pt.lat],
      );

      const g4040Rows = res.rows.filter(r => r.mtfcc === 'G4040');
      const g4110Rows = res.rows.filter(r => r.mtfcc === 'G4110');

      for (const row of res.rows) {
        console.log(`  ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }

      // Assert G4040 expectation
      if (pt.expectG4040 && g4040Rows.length === 0) {
        console.error(`  FAIL: expected G4040 row but none found`);
        failures++;
      } else if (!pt.expectG4040 && g4040Rows.length > 0) {
        console.error(`  FAIL: expected NO G4040 row but found: ${g4040Rows.map(r => r.geo_id).join(', ')}`);
        failures++;
      }

      // Assert specific geo_id if provided
      if (pt.expectedGeoId) {
        const found = g4040Rows.some(r => r.geo_id === pt.expectedGeoId);
        if (!found) {
          console.error(`  FAIL: expected geo_id=${pt.expectedGeoId} in G4040 results but not found`);
          failures++;
        } else {
          console.log(`  PASS: geo_id=${pt.expectedGeoId} confirmed`);
        }
      }

      // Cambridge-specific: G4110 must still be present
      if (pt.label.includes('Cambridge') && g4110Rows.length === 0) {
        console.error(`  FAIL: Cambridge should still return G4110 row`);
        failures++;
      }
    }
  } finally {
    await client.end();
  }

  console.log(`\n${'─'.repeat(60)}`);
  if (failures === 0) {
    console.log('MA towns smoke test PASSED — all assertions met.');
  } else {
    console.error(`MA towns smoke test FAILED — ${failures} assertion(s) failed.`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

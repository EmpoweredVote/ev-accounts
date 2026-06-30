/**
 * smoke-or-westmetro-school.ts
 * Phase 174: West-metro Oregon school-district geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-or-westmetro-school.ts
 *
 * Verifies Phase 174 roadmap success criteria:
 *   SC1 — Beaverton City Hall returns G5420 geo_id 4101920 (Beaverton SD 48J)
 *   SC2 — Hillsboro City Hall returns G5420 geo_id 4100023 (Hillsboro SD 1J)
 *   SC3 — Tigard City Hall returns G5420 geo_id 4112240 (Tigard-Tualatin SD 23J)
 *   SC4 — Forest Grove City Hall returns G5420 geo_id 4105160 (Forest Grove SD 15)
 *   SC5 — Sherwood City Hall returns G5420 geo_id 4111290 (Sherwood SD 88J)
 *   SC6 — Exactly 5 west-metro G5420 rows exist with source='tiger_unsd_or_2024_westmetro'
 *
 * D-03: All 5 districts demonstrate routing a real in-district address to the correct geo_id.
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

interface AddressTest {
  label: string;
  lon: number;
  lat: number;
  expectedMtfcc: string[];
  forbiddenMtfcc?: string[];
  expectedGeoIds?: Record<string, string>; // mtfcc → geo_id
}

const TEST_ADDRESSES: AddressTest[] = [
  {
    label: 'Beaverton City Hall (Beaverton SD 48J)',
    lon: -122.8011, lat: 45.4871,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4101920' },
  },
  {
    label: 'Hillsboro City Hall (Hillsboro SD 1J)',
    lon: -122.9898, lat: 45.5229,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4100023' },
  },
  {
    label: 'Tigard City Hall (Tigard-Tualatin SD 23J)',
    lon: -122.7714, lat: 45.4312,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4112240' },
  },
  {
    label: 'Forest Grove City Hall (Forest Grove SD 15)',
    lon: -123.1073, lat: 45.5195,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4105160' },
  },
  {
    label: 'Sherwood City Hall (Sherwood SD 88J)',
    lon: -122.8404, lat: 45.3565,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4111290' },
  },
];

async function queryBoundaries(
  client: Client,
  lon: number,
  lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
    `SELECT geo_id, name, mtfcc
     FROM essentials.geofence_boundaries
     WHERE state = '41'
       AND mtfcc = 'G5420'
       AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
     ORDER BY name`,
    [lon, lat],
  );
  return res.rows;
}

async function main() {
  if (!process.env['DATABASE_URL']) {
    process.stderr.write('ERROR: DATABASE_URL not set\n');
    process.exit(1);
  }
  const client = new Client({
    connectionString: process.env['DATABASE_URL'],
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();

  let allPassed = true;
  const errors: string[] = [];

  try {
    // -------------------------------------------------------------------------
    // SC6: West-metro G5420 count assertion
    // -------------------------------------------------------------------------
    console.log('\n=== SC6: West-metro G5420 row count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE state = '41'
         AND mtfcc = 'G5420'
         AND source = 'tiger_unsd_or_2024_westmetro'`
    );
    const wmCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  West-metro G5420 count: ${wmCount} (expected 5)`);
    if (wmCount !== 5) {
      const msg = `west-metro G5420 count: expected 5, got ${wmCount}`;
      errors.push(msg);
      allPassed = false;
      console.log(`  ERROR: ${msg}`);
    } else {
      console.log('  SC6: West-metro count OK');
    }

    // -------------------------------------------------------------------------
    // Address tests (SC1–SC5)
    // -------------------------------------------------------------------------
    for (const addr of TEST_ADDRESSES) {
      console.log(`\n=== ${addr.label} (${addr.lon}, ${addr.lat}) ===`);
      const rows = await queryBoundaries(client, addr.lon, addr.lat);

      if (rows.length === 0) {
        const msg = `${addr.label}: no boundaries matched — check coordinates`;
        console.log(`  WARNING: ${msg}`);
        errors.push(msg);
        allPassed = false;
        continue;
      }

      for (const row of rows) {
        console.log(`  ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }

      const returnedMtfcc = new Set(rows.map(r => r.mtfcc));

      // Check expected mtfcc present
      for (const mtfcc of addr.expectedMtfcc) {
        if (!returnedMtfcc.has(mtfcc)) {
          const msg = `${addr.label}: expected ${mtfcc} but not found`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        }
      }

      // Check forbidden mtfcc absent
      for (const mtfcc of addr.forbiddenMtfcc ?? []) {
        if (returnedMtfcc.has(mtfcc)) {
          const matchedRow = rows.find(r => r.mtfcc === mtfcc);
          const msg = `${addr.label}: forbidden ${mtfcc} found (geo_id=${matchedRow?.geo_id ?? '?'}, name=${matchedRow?.name ?? '?'})`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        }
      }

      // Check specific geo_ids
      for (const [mtfcc, expectedGeoId] of Object.entries(addr.expectedGeoIds ?? {})) {
        const matchedRow = rows.find(r => r.mtfcc === mtfcc);
        if (!matchedRow) {
          const msg = `${addr.label}: ${mtfcc} not returned — cannot verify geo_id`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        } else if (matchedRow.geo_id !== expectedGeoId) {
          const msg = `${addr.label}: ${mtfcc} geo_id expected ${expectedGeoId}, got ${matchedRow.geo_id}`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        } else {
          console.log(`  OK: ${mtfcc} geo_id=${matchedRow.geo_id} (${matchedRow.name})`);
        }
      }
    }

  } finally {
    await client.end();
  }

  // -------------------------------------------------------------------------
  // Final result
  // -------------------------------------------------------------------------
  console.log('\n=== Smoke Test Results ===');
  if (allPassed) {
    console.log('ALL ASSERTIONS PASSED');
    console.log('\nPhase 174 roadmap success criteria:');
    console.log('  SC1: Beaverton City Hall returns G5420 geo_id 4101920 (Beaverton SD 48J) [PASS]');
    console.log('  SC2: Hillsboro City Hall returns G5420 geo_id 4100023 (Hillsboro SD 1J) [PASS]');
    console.log('  SC3: Tigard City Hall returns G5420 geo_id 4112240 (Tigard-Tualatin SD 23J) [PASS]');
    console.log('  SC4: Forest Grove City Hall returns G5420 geo_id 4105160 (Forest Grove SD 15) [PASS]');
    console.log('  SC5: Sherwood City Hall returns G5420 geo_id 4111290 (Sherwood SD 88J) [PASS]');
    console.log('  SC6: Exactly 5 west-metro G5420 rows with source=tiger_unsd_or_2024_westmetro [PASS]');
    process.exit(0);
  } else {
    console.log(`FAILED (${errors.length} assertion(s)):`);
    for (const err of errors) {
      console.log(`  - ${err}`);
    }
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

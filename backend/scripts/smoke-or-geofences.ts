/**
 * smoke-or-geofences.ts
 * Phase 72: Oregon geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-or-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Verifies Phase 72 roadmap success criteria:
 *   SC1 — Portland City Hall returns G4110 (city, 4159000) + G4020 (county, 41051) + G5200 + G5210 + G5220
 *   SC2 — Bend rural point returns G4020 + G5200 + G5210 + G5220; NO G4110 (unincorporated Deschutes County)
 *   SC3 — All 6 CD + 30 senate + 60 assembly + 36 counties + N cities present in DB
 *   SC4 — 3 OR addresses each return correct district names with zero NULL tiers
 *
 * District lookup: https://oregonlegislature.gov/findyourlegislator/
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
    // Portland OR City Hall — incorporated city in Multnomah County
    // Note: geo_ids are ASSUMED (STATEFP='41' + PLACEFP='59000' for Portland; '41051' for Multnomah County)
    // Both geo_ids will be confirmed after the place layer loads
    label: 'Portland OR City Hall',
    lon: -122.6794,
    lat: 45.5231,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4110: '4159000', // Portland city (ASSUMED — confirm after load)
      G4020: '41051',   // Multnomah County (ASSUMED — confirm after load)
    },
  },
  {
    // Bend OR rural point — unincorporated Deschutes County outside city limits
    // This coordinate is chosen to be outside Bend city limits; if it falls inside
    // Bend city limits when tested, update to lon: -121.4, lat: 44.12 (firmly rural)
    label: 'Bend OR (unincorporated Deschutes County)',
    lon: -121.3153,
    lat: 44.0582,
    expectedMtfcc: ['G4020', 'G5200', 'G5210', 'G5220'],
    forbiddenMtfcc: ['G4110'],
  },
  {
    // Salem OR — state capital, incorporated city in Marion County
    label: 'Salem OR (state capital, Marion County)',
    lon: -123.0351,
    lat: 44.9429,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
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
       AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
     ORDER BY mtfcc`,
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
    // SC3: Layer counts (all rows present)
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Layer counts for state=\'41\' ===');
    const countRes = await client.query<{ mtfcc: string; row_count: string }>(
      `SELECT mtfcc, COUNT(*) AS row_count
       FROM essentials.geofence_boundaries
       WHERE state = '41'
         AND mtfcc IN ('G4020','G4110','G5200','G5210','G5220')
       GROUP BY mtfcc ORDER BY mtfcc`,
    );
    const expectedCounts: Record<string, number> = {
      G4020: 36,   // counties
      G4110: 241,  // incorporated cities (confirmed via dry-run 2026-05-28)
      G5200: 6,    // congressional districts
      G5210: 30,   // state senate districts
      G5220: 60,   // state house districts
    };
    const actualCounts: Record<string, number> = {};
    for (const row of countRes.rows) {
      actualCounts[row.mtfcc] = parseInt(row.row_count, 10);
      console.log(`  ${row.mtfcc}: ${row.row_count} rows`);
    }
    for (const [mtfcc, expected] of Object.entries(expectedCounts)) {
      const actual = actualCounts[mtfcc] ?? 0;
      if (actual !== expected) {
        const msg = `SC3 FAIL: ${mtfcc} expected ${expected} rows, got ${actual}`;
        console.log(`  ERROR: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
    }
    if (Object.keys(actualCounts).length === Object.keys(expectedCounts).length) {
      console.log('  SC3: All layer counts OK');
    }

    // -------------------------------------------------------------------------
    // Address tests (SC1, SC2, SC4)
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

      // SC4: No NULL names in returned rows
      const nullNameRows = rows.filter(r => r.name === null || r.name === '');
      if (nullNameRows.length > 0) {
        const msg = `${addr.label}: ${nullNameRows.length} rows with NULL/empty name (SC4 violation)`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
    }

    // -------------------------------------------------------------------------
    // OR target city geo_id lookup
    // -------------------------------------------------------------------------
    console.log('\n=== OR Target City geo_id Lookup (G4110) ===');
    const targetCityRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE state = '41'
         AND mtfcc = 'G4110'
         AND name IN (
           'Portland city',
           'Salem city',
           'Eugene city'
         )
       ORDER BY name`,
    );

    console.log(`  Found ${targetCityRes.rows.length} OR target cities:`);
    for (const row of targetCityRes.rows) {
      console.log(`  ${row.name}: geo_id=${row.geo_id}`);
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
    console.log('\nPhase 72 roadmap success criteria:');
    console.log('  SC1: Portland City Hall returns G4110 (4159000) + G4020 (41051) + G5200 + G5210 + G5220 [PASS]');
    console.log('  SC2: Bend rural point returns G4020 + G5200 + G5210 + G5220; NO G4110 [PASS]');
    console.log('  SC3: All 6 CD + 30 senate + 60 house + 36 counties + N cities present [PASS]');
    console.log('  SC4: 3 addresses each return non-NULL names across all tiers [PASS]');
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

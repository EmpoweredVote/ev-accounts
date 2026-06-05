/**
 * smoke-md-geofences.ts
 * Phase 91: Maryland geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-md-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Verifies Phase 91 roadmap success criteria:
 *   SC1 — Baltimore City Hall returns G4110 (city, 2404000) + G4020 (city-county, 24510) + G5200 + G5210 + G5220
 *   SC2 — Garrett County rural point returns G4020 + G5200 + G5210 + G5220; NO G4110 (unincorporated)
 *   SC3 — All 8 CD + 47 senate + [N] house + 24 counties + N cities present in DB
 *   SC4 — 3 MD addresses each return correct district names with zero NULL tiers
 *
 * District lookup: https://mgaleg.maryland.gov/mgawebsite/Members/Index/
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
    // Baltimore City Hall — D-01 invariant: BOTH G4110 (incorporated city) AND G4020 (city-as-county)
    label: 'Baltimore City Hall',
    lon: -76.6107,
    lat: 39.2908,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4110: '2404000', // Baltimore city (incorporated place)
      G4020: '24510',   // Baltimore city (independent city-county)
    },
  },
  {
    // Garrett County rural point — unincorporated; must NOT return G4110
    // If G4110 is returned, the coordinate fell inside Oakland city; shift to (-79.45, 39.65)
    label: 'Rural Garrett County MD (unincorporated)',
    lon: -79.3,
    lat: 39.53,
    expectedMtfcc: ['G4020', 'G5200', 'G5210', 'G5220'],
    forbiddenMtfcc: ['G4110'],
  },
  {
    // Leonardtown MD — Phase 95 (St. Mary's County) dependency validation
    label: "Leonardtown MD (St. Mary's County)",
    lon: -76.6358,
    lat: 38.2912,
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
     WHERE state = '24'
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
    console.log('\n=== SC3: Layer counts for state=\'24\' ===');
    const countRes = await client.query<{ mtfcc: string; row_count: string }>(
      `SELECT mtfcc, COUNT(*) AS row_count
       FROM essentials.geofence_boundaries
       WHERE state = '24'
         AND mtfcc IN ('G4020','G4110','G5200','G5210','G5220')
       GROUP BY mtfcc ORDER BY mtfcc`,
    );
    const expectedCounts: Record<string, number> = {
      G4020: 24,   // counties (23 counties + Baltimore City independent city)
      G4110: 157,  // incorporated cities — confirmed via dry-run 2026-06-05 (TIGER 2024 G4110 only; TIGERweb 311 included G4210 CDPs)
      G5200: 8,    // congressional districts
      G5210: 47,   // state senate districts
      G5220: 71,   // house sub-districts — confirmed via dry-run 2026-06-05 (71 MD SLDL polygons; NOT 141 delegates)
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
    // MD target city geo_id lookup
    // -------------------------------------------------------------------------
    console.log('\n=== MD Target City geo_id Lookup (G4110) ===');
    const targetCityRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE state = '24'
         AND mtfcc = 'G4110'
         AND name IN (
           'Baltimore city',
           'Annapolis city',
           'Rockville city'
         )
       ORDER BY name`,
    );

    console.log(`  Found ${targetCityRes.rows.length} MD target cities:`);
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
    console.log('\nPhase 91 roadmap success criteria:');
    console.log('  SC1: Baltimore City Hall returns G4110 (2404000) + G4020 (24510) + G5200 + G5210 + G5220 [PASS]');
    console.log('  SC2: Garrett County rural returns G4020 + G5200 + G5210 + G5220; NO G4110 [PASS]');
    console.log('  SC3: All 8 CD + 47 senate + N house + 24 counties + N cities present [PASS]');
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

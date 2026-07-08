/**
 * smoke-az-geofences.ts
 * Phase 190: Arizona geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-az-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Verifies Phase 190 roadmap success criteria:
 *   SC1 — Catalina Foothills (unincorporated Pima County) returns G4020 + G5200 + G5210 + G5220;
 *          NO G4110 and NO G4040 (unincorporated — no city/township boundary covers it)
 *   SC2 — Each of the 5 incorporated municipalities (Tucson, Oro Valley, Marana, Sahuarita,
 *          South Tucson) returns G4110 + G4020 + G5200 + G5210 + G5220 (all tiers)
 *   SC3 — All G4020 (15 counties) + G4110 ([DRY-RUN-COUNT] municipalities) + G5200 (9 CDs) +
 *          G5210 (30 Senate) + G5220 (30 House polygons per D-04) rows present in DB
 *   SC4 — All 6 test addresses return correct district names with zero NULL tiers
 *
 * District lookup: https://www.azleg.gov/
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
    // Catalina Foothills — unincorporated Pima County (north of Tucson city limits)
    // SC1 invariant: NO G4110 (no incorporated city), NO G4040 (no township)
    // Must return Pima County (G4020) + federal/state legislative tiers only
    label: 'Catalina Foothills (unincorporated Pima County)',
    lon: -110.9210,
    lat: 32.3130,
    expectedMtfcc: ['G4020', 'G5200', 'G5210', 'G5220'],
    forbiddenMtfcc: ['G4110', 'G4040'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
  },
  {
    // City of Tucson City Hall — incorporated city (AZ flagship Tucson-metro)
    // SC2: must return G4110 (Tucson city) + county + all legislative tiers
    label: 'City of Tucson (City Hall)',
    lon: -110.9760,
    lat: 32.2226,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
  },
  {
    // Oro Valley Town Hall — incorporated town
    // SC2: must return G4110 (Oro Valley town) + county + all legislative tiers
    label: 'Oro Valley (Town Hall)',
    lon: -110.9770,
    lat: 32.4160,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
  },
  {
    // Marana Town Hall — incorporated town
    // NOTE: Marana straddles Pima/Pinal; Town Hall is in Pima (04019). If the chosen
    // coordinate lands in Pinal (04021), pick a Pima-side coordinate or document.
    label: 'Marana (Town Hall)',
    lon: -111.2210,
    lat: 32.4300,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
  },
  {
    // Sahuarita Town Hall — incorporated town
    // SC2: must return G4110 (Sahuarita town) + county + all legislative tiers
    label: 'Sahuarita (Town Hall)',
    lon: -110.9720,
    lat: 31.9260,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
  },
  {
    // South Tucson City Hall — separate 1-sq-mi incorporated city fully enclaved
    // within Tucson. The G4110 returned must be 'South Tucson city', NOT 'Tucson city'.
    label: 'South Tucson (City Hall)',
    lon: -110.9700,
    lat: 32.1980,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4020: '04019', // Pima County
    },
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
     WHERE state = '04'
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
    console.log('\n=== SC3: Layer counts for state=\'04\' ===');
    const countRes = await client.query<{ mtfcc: string; row_count: string }>(
      `SELECT mtfcc, COUNT(*) AS row_count
       FROM essentials.geofence_boundaries
       WHERE state = '04'
         AND mtfcc IN ('G4020','G4110','G5200','G5210','G5220')
       GROUP BY mtfcc ORDER BY mtfcc`,
    );
    const expectedCounts: Record<string, number> = {
      G4020: 15,  // 15 AZ counties (NO independent cities, unlike VA/NV)
      G4110: 0,   // SENTINEL — Task 3 dry-run reveals actual count (~91 AZ G4110 municipalities); must match EXPECTED_AZ_MTFCC.place
      G5200: 9,   // 9 AZ congressional districts
      G5210: 30,  // 30 AZ legislative districts (single senator each)
      G5220: 0,   // SENTINEL — Task 3 dry-run confirms 30 (D-04: 30 legislative-district polygons, NOT 60)
    };
    const actualCounts: Record<string, number> = {};
    for (const row of countRes.rows) {
      actualCounts[row.mtfcc] = parseInt(row.row_count, 10);
      console.log(`  ${row.mtfcc}: ${row.row_count} rows`);
    }
    let sc3Passed = true;
    for (const [mtfcc, expected] of Object.entries(expectedCounts)) {
      const actual = actualCounts[mtfcc] ?? 0;
      if (actual !== expected) {
        const msg = `SC3 FAIL: ${mtfcc} expected ${expected} rows, got ${actual}`;
        console.log(`  ERROR: ${msg}`);
        errors.push(msg);
        allPassed = false;
        sc3Passed = false;
      }
    }
    if (sc3Passed && Object.keys(actualCounts).length === Object.keys(expectedCounts).length) {
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
    // AZ target municipality geo_id lookup
    // -------------------------------------------------------------------------
    console.log('\n=== AZ Target Municipality geo_id Lookup (G4110) ===');
    const targetCityRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE state = '04'
         AND mtfcc = 'G4110'
         AND name IN (
           'Tucson city',
           'Oro Valley town',
           'Marana town',
           'Sahuarita town',
           'South Tucson city'
         )
       ORDER BY name`,
    );

    console.log(`  Found ${targetCityRes.rows.length} AZ target municipalities:`);
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
    console.log('\nPhase 190 roadmap success criteria:');
    console.log('  SC1: Catalina Foothills returns G4020 (Pima County) + G5200 + G5210 + G5220; NO G4110/G4040 [PASS]');
    console.log('  SC2: Tucson/Oro Valley/Marana/Sahuarita/South Tucson each return G4110 + G4020 + G5200 + G5210 + G5220 [PASS]');
    console.log('  SC3: All county/city/CD/SLDU/SLDL layer counts match expected values [PASS]');
    console.log('  SC4: All 6 addresses return non-NULL names across all tiers [PASS]');
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

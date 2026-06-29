/**
 * smoke-nv-geofences.ts
 * Phase 158: Nevada geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-nv-geofences.ts
 *
 * Prints which geofence_boundaries rows cover each test address.
 * Verifies Phase 158 roadmap success criteria:
 *   SC1 — Las Vegas Strip (unincorporated Clark County) returns G4020 + G5200 + G5210 + G5220;
 *          NO G4110 (Strip is unincorporated — no incorporated city boundary covers it)
 *   SC2 — Each of the 4 incorporated cities (Las Vegas, Henderson, North Las Vegas, Boulder City)
 *          returns G4110 + G4020 + G5200 + G5210 + G5220 (all tiers)
 *   SC3 — All G4020 (17 counties) + G4110 ([DRY-RUN-COUNT] cities) + G5200 (4 CDs) +
 *          G5210 (21 Senate) + G5220 ([DRY-RUN-COUNT] Assembly) rows present in DB
 *   SC4 — All 5 test addresses return correct district names with zero NULL tiers
 *
 * District lookup: https://www.leg.state.nv.us/
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
    // Las Vegas Strip (near the Bellagio) — unincorporated Clark County
    // SC1 invariant: NO G4110 (no incorporated city), NO G4040 (no township)
    // Must return Clark County (G4020) + federal/state legislative tiers only
    label: 'Las Vegas Strip (unincorporated Clark County)',
    lon: -115.1728,
    lat: 36.1147,
    expectedMtfcc: ['G4020', 'G5200', 'G5210', 'G5220', 'G5420'],
    forbiddenMtfcc: ['G4110', 'G4040'],
    expectedGeoIds: {
      G4020: '32003', // Clark County
      G5420: '3200060', // Clark County School District (CCSD covers the whole county)
    },
  },
  {
    // City of Las Vegas City Hall — incorporated city
    // SC2: must return G4110 (Las Vegas city) + county + all legislative tiers
    label: 'City of Las Vegas (City Hall)',
    lon: -115.1497,
    lat: 36.1716,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220', 'G5420'],
    expectedGeoIds: {
      G4020: '32003', // Clark County
      G5420: '3200060', // Clark County School District (CCSD covers the whole county)
    },
  },
  {
    // Henderson NV City Hall — incorporated city (NV's 2nd-largest)
    // SC2: must return G4110 (Henderson city) + county + all legislative tiers
    label: 'Henderson NV (City Hall)',
    lon: -114.9817,
    lat: 36.0397,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220', 'G5420'],
    expectedGeoIds: {
      G4020: '32003', // Clark County
      G5420: '3200060', // Clark County School District (CCSD covers the whole county)
    },
  },
  {
    // North Las Vegas NV City Hall — incorporated city
    // SC2: must return G4110 (North Las Vegas city) + county + all legislative tiers
    label: 'North Las Vegas NV (City Hall)',
    lon: -115.1175,
    lat: 36.1989,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220', 'G5420'],
    expectedGeoIds: {
      G4020: '32003', // Clark County
      G5420: '3200060', // Clark County School District (CCSD covers the whole county)
    },
  },
  {
    // Boulder City NV City Hall — incorporated city (only NV city that prohibits casinos)
    // SC2: must return G4110 (Boulder City city) + county + all legislative tiers
    label: 'Boulder City NV (City Hall)',
    lon: -114.8330,
    lat: 35.9786,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220', 'G5420'],
    expectedGeoIds: {
      G4020: '32003', // Clark County
      G5420: '3200060', // Clark County School District (CCSD covers the whole county)
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
     WHERE state = '32'
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
    console.log('\n=== SC3: Layer counts for state=\'32\' ===');
    const countRes = await client.query<{ mtfcc: string; row_count: string }>(
      `SELECT mtfcc, COUNT(*) AS row_count
       FROM essentials.geofence_boundaries
       WHERE state = '32'
         AND mtfcc IN ('G4020','G4110','G5200','G5210','G5220')
       GROUP BY mtfcc ORDER BY mtfcc`,
    );
    const expectedCounts: Record<string, number> = {
      G4020: 17,  // 16 NV counties + Carson City independent city-county
      G4110: 19,  // confirmed via dry-run 2026-06-23 — 19 NV G4110 incorporated places
      G5200: 4,   // 4 NV congressional districts (post-2022 redistricting)
      G5210: 21,  // 21 NV State Senate districts (single-member)
      G5220: 42,  // confirmed via dry-run 2026-06-23 — 42 NV G5220 single-member Assembly polygons
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
    // NV target city geo_id lookup
    // -------------------------------------------------------------------------
    console.log('\n=== NV Target City geo_id Lookup (G4110) ===');
    const targetCityRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE state = '32'
         AND mtfcc = 'G4110'
         AND name IN (
           'Las Vegas city',
           'Henderson city',
           'North Las Vegas city',
           'Boulder City city'
         )
       ORDER BY name`,
    );

    console.log(`  Found ${targetCityRes.rows.length} NV target cities:`);
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
    console.log('\nPhase 158 roadmap success criteria:');
    console.log('  SC1: Las Vegas Strip returns G4020 (Clark County) + G5200 + G5210 + G5220; NO G4110 [PASS]');
    console.log('  SC2: Las Vegas/Henderson/North Las Vegas/Boulder City each return G4110 + G4020 + G5200 + G5210 + G5220 [PASS]');
    console.log('  SC3: All county/city/CD/SLDU/SLDL layer counts match expected values [PASS]');
    console.log('  SC4: All 5 addresses return non-NULL names across all tiers [PASS]');
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

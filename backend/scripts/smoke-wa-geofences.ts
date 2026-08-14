/**
 * smoke-wa-geofences.ts
 * Washington geofences smoke test (Seattle deep seed, Task 1)
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-wa-geofences.ts
 *
 * Verifies:
 *   SC1 — Seattle City Hall returns G4110 (5363000) + G4020 (53033) + G5200 + G5210 + G5220
 *   SC2 — Rural King County returns G4020 (53033) + G5200 + G5210 + G5220; NO G4110
 *   SC3 — Layer counts: 39 counties + 281 cities + 10 CD + 49 senate + 49 house
 *   SC4 — All returned rows carry non-NULL names
 *
 * !! WA MTFCC ORIENTATION IS INVERTED relative to a plain TIGER reading:
 *      G5210 = STATE_UPPER (Senate), G5220 = STATE_LOWER (House).
 *    Confirmed by the boundary NAMES themselves ("Legislative (Senate) District N"
 *    carries mtfcc G5210). Matches how CA/VA/NV/AZ are handled in this codebase.
 *
 * !! WA legislative districts are MULTI-MEMBER: 49 districts, each electing one
 *    senator and TWO representatives over the SAME boundary. G5220 is therefore
 *    49 polygons covering 98 seats, NOT 98 polygons.
 *
 * !! geo_id is NOT unique across MTFCCs in WA: '53001' is simultaneously Adams
 *    County (G4020), Legislative District 1 Senate (G5210) and House (G5220).
 *    Any join against districts must key on (geo_id, mtfcc).
 *
 * All expected values below were confirmed against the database on 2026-08-13.
 * District lookup: https://app.leg.wa.gov/DistrictFinder/
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
    // Seattle City Hall, 600 4th Ave — the routing case this whole load exists for.
    label: 'Seattle City Hall',
    lon: -122.3301,
    lat: 47.6039,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4110: '5363000', // Seattle city (CONFIRMED 2026-08-13)
      G4020: '53033',   // King County (CONFIRMED 2026-08-13)
      G5200: '5307',    // Congressional District 7 (CONFIRMED 2026-08-13)
      G5210: '53034',   // Legislative (Senate) District 34 (CONFIRMED 2026-08-13)
      G5220: '53034',   // Legislative (House) District 34 (CONFIRMED 2026-08-13)
    },
  },
  {
    // Unincorporated King County east of Snoqualmie — negative test. A point that
    // returns G4110 here would mean city polygons are over-covering.
    label: 'Rural King County (unincorporated, east of Snoqualmie)',
    lon: -121.75,
    lat: 47.42,
    expectedMtfcc: ['G4020', 'G5200', 'G5210', 'G5220'],
    forbiddenMtfcc: ['G4110'],
    expectedGeoIds: {
      G4020: '53033',   // King County (CONFIRMED 2026-08-13)
    },
  },
  {
    // Olympia — state capital, second incorporated city, different county.
    label: 'Olympia (state capital)',
    lon: -122.9007,
    lat: 47.0379,
    expectedMtfcc: ['G4020', 'G4110', 'G5200', 'G5210', 'G5220'],
    expectedGeoIds: {
      G4110: '5351300', // Olympia city (CONFIRMED 2026-08-13)
      G4020: '53067',   // Thurston County (CONFIRMED 2026-08-13)
    },
  },
];

interface BoundaryRow { mtfcc: string; geo_id: string; name: string }

async function queryBoundaries(client: Client, lon: number, lat: number): Promise<BoundaryRow[]> {
  // ST_MakePoint takes (longitude, latitude) — reversing them is the single most
  // common cause of a zero-row result here.
  const res = await client.query<BoundaryRow>(
    `SELECT mtfcc, geo_id, name
     FROM essentials.geofence_boundaries
     WHERE state = '53'
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
    // SC3: Layer counts
    // -------------------------------------------------------------------------
    console.log("\n=== SC3: Layer counts for state='53' ===");
    const countRes = await client.query<{ mtfcc: string; row_count: string }>(
      `SELECT mtfcc, COUNT(*) AS row_count
       FROM essentials.geofence_boundaries
       WHERE state = '53'
         AND mtfcc IN ('G4020','G4110','G5200','G5210','G5220')
       GROUP BY mtfcc ORDER BY mtfcc`,
    );
    const expectedCounts: Record<string, number> = {
      G4020: 39,   // counties (pre-existing)
      G4110: 281,  // incorporated cities/towns (confirmed via pre-flight assertion 2026-08-13)
      G5200: 10,   // congressional districts (pre-existing)
      G5210: 49,   // STATE_UPPER — senate districts
      G5220: 49,   // STATE_LOWER — house polygons covering 98 seats (NOT 98)
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
    if (allPassed) console.log('  SC3: All layer counts OK');

    // -------------------------------------------------------------------------
    // SC5: Multi-member guard — G5220 must be 49 polygons, never 98.
    // -------------------------------------------------------------------------
    console.log('\n=== SC5: Multi-member district guard ===');
    const lowerRes = await client.query<{ n: string }>(
      `SELECT COUNT(*) AS n FROM essentials.districts
       WHERE state ILIKE 'wa' AND district_type = 'STATE_LOWER'`,
    );
    const lowerCount = parseInt(lowerRes.rows[0]?.n ?? '0', 10);
    console.log(`  STATE_LOWER district rows: ${lowerCount}`);
    if (lowerCount !== 49) {
      const msg =
        `SC5 FAIL: expected 49 STATE_LOWER polygons (49 districts x 2 seats = 98 reps), got ${lowerCount}. ` +
        `A count of 98 would mean single-member polygons and invalidates the two-offices-per-district model.`;
      console.log(`  ERROR: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC5: 49 polygons covering 98 house seats — multi-member model intact');
    }

    // -------------------------------------------------------------------------
    // Address tests (SC1, SC2, SC4)
    // -------------------------------------------------------------------------
    for (const addr of TEST_ADDRESSES) {
      console.log(`\n=== ${addr.label} (${addr.lon}, ${addr.lat}) ===`);
      const rows = await queryBoundaries(client, addr.lon, addr.lat);

      if (rows.length === 0) {
        const msg = `${addr.label}: no boundaries matched — check coordinate order (lng, lat)`;
        console.log(`  WARNING: ${msg}`);
        errors.push(msg);
        allPassed = false;
        continue;
      }

      for (const row of rows) {
        console.log(`  ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }

      const returnedMtfcc = new Set(rows.map(r => r.mtfcc));

      for (const mtfcc of addr.expectedMtfcc) {
        if (!returnedMtfcc.has(mtfcc)) {
          const msg = `${addr.label}: expected ${mtfcc} but not found`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        }
      }

      for (const mtfcc of addr.forbiddenMtfcc ?? []) {
        if (returnedMtfcc.has(mtfcc)) {
          const matchedRow = rows.find(r => r.mtfcc === mtfcc);
          const msg = `${addr.label}: forbidden ${mtfcc} found (geo_id=${matchedRow?.geo_id ?? '?'}, name=${matchedRow?.name ?? '?'})`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        }
      }

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

      const nullNameRows = rows.filter(r => r.name === null || r.name === '');
      if (nullNameRows.length > 0) {
        const msg = `${addr.label}: ${nullNameRows.length} rows with NULL/empty name (SC4 violation)`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
    }

  } finally {
    await client.end();
  }

  console.log('\n=== Smoke Test Results ===');
  if (allPassed) {
    console.log('ALL ASSERTIONS PASSED');
    console.log('  SC1: Seattle City Hall returns G4110 (5363000) + G4020 (53033) + G5200 + G5210 + G5220 [PASS]');
    console.log('  SC2: Rural King County returns G4020 + G5200 + G5210 + G5220; NO G4110 [PASS]');
    console.log('  SC3: 39 counties + 281 cities + 10 CD + 49 senate + 49 house present [PASS]');
    console.log('  SC4: All addresses return non-NULL names across all tiers [PASS]');
    console.log('  SC5: 49 STATE_LOWER polygons — multi-member model intact [PASS]');
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

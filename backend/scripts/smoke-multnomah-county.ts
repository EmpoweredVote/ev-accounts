/**
 * smoke-multnomah-county.ts
 * Phase 83: Multnomah County routing smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-multnomah-county.ts
 *
 * Verifies Phase 83 success criteria:
 *   SC1 — Portland City Hall (-122.6794, 45.5231) returns G4020 (41051) AND G4110 (4159000)
 *   SC2 — Portland City Hall returns exactly 5 COUNTY commissioner names via districts+offices+politicians JOIN
 *   SC3 — Unincorporated Multnomah County coordinate (-122.2, 45.5) returns G4020 (41051)
 *         but ZERO G4110 boundaries; also returns exactly 5 COUNTY commissioner names
 *   SC4 — Section-split check: geo_id='41051' has COUNTY district row (0 orphans)
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
  expectedGeoIds?: Record<string, string>;
}

const TEST_ADDRESSES: AddressTest[] = [
  {
    // Portland City Hall — incorporated city inside Multnomah County
    // Expects BOTH G4020 (county, 41051) and G4110 (Portland city, 4159000)
    label: 'Portland OR City Hall',
    lon: -122.6794,
    lat: 45.5231,
    expectedMtfcc: ['G4020', 'G4110'],
    expectedGeoIds: {
      G4020: '41051',   // Multnomah County
      G4110: '4159000', // Portland city
    },
  },
  {
    // Corbett, OR — unincorporated Multnomah County (outside all G4110 city boundaries)
    // Expects G4020 ONLY for local tiers; G4110 must be ABSENT
    // Coordinate VERIFIED via DB query 2026-05-31: returns G4020 (41051) only; no G4110
    label: 'Corbett OR (unincorporated Multnomah County)',
    lon: -122.2,
    lat: 45.5,
    expectedMtfcc: ['G4020'],
    forbiddenMtfcc: ['G4110'],
  },
];

const EXPECTED_COMMISSIONER_NAMES = new Set([
  'Jessica Vega Pederson',
  'Meghan Moyer',
  'Shannon Singleton',
  'Julia Brim-Edwards',
  'Vince Jones-Dixon',
]);

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

async function queryCountyOfficials(
  client: Client,
  lon: number,
  lat: number
): Promise<Array<{ full_name: string; district_type: string }>> {
  const res = await client.query<{ full_name: string; district_type: string }>(
    `SELECT p.full_name, d.district_type
     FROM essentials.politicians p
     JOIN essentials.offices o ON o.politician_id = p.id
     JOIN essentials.districts d ON d.id = o.district_id
     JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
     WHERE gb.state = '41'
       AND d.district_type = 'COUNTY'
       AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
     ORDER BY p.full_name`,
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
    // Pre-flight: verify Phase 72 G4020 geofence boundary for geo_id='41051' exists
    // -------------------------------------------------------------------------
    console.log('\n=== Pre-flight: Phase 72 G4020 geofence integrity ===');
    const pfRes = await client.query<{ geo_id: string; name: string; mtfcc: string; state: string }>(
      `SELECT geo_id, name, mtfcc, state
       FROM essentials.geofence_boundaries
       WHERE geo_id = '41051' AND mtfcc = 'G4020'`,
    );
    if (pfRes.rows.length !== 1) {
      console.error(`Pre-flight FAILED: expected 1 G4020 row for geo_id='41051', found ${pfRes.rows.length}`);
      console.error('Phase 72 geofence load may be missing — cannot run smoke test');
      process.exit(1);
    }
    const pfRow = pfRes.rows[0];
    console.log(`  G4020 row confirmed: geo_id=${pfRow.geo_id}  name=${pfRow.name}  state=${pfRow.state}`);

    // -------------------------------------------------------------------------
    // Pre-flight: verify unincorporated Corbett coordinate returns no G4110
    // (catches the edge case where the coordinate was updated to a city-boundary point)
    // -------------------------------------------------------------------------
    console.log('\n=== Pre-flight: Corbett OR coordinate validation ===');
    const corbettAddr = TEST_ADDRESSES.find(a => a.label.includes('Corbett'))!;
    const corbettBounds = await queryBoundaries(client, corbettAddr.lon, corbettAddr.lat);
    const corbettHasG4110 = corbettBounds.some(r => r.mtfcc === 'G4110');
    if (corbettHasG4110) {
      const g4110Row = corbettBounds.find(r => r.mtfcc === 'G4110');
      console.error(`Pre-flight FAILED: Corbett coordinate (${corbettAddr.lon}, ${corbettAddr.lat}) falls inside G4110 boundary: geo_id=${g4110Row?.geo_id} name=${g4110Row?.name}`);
      console.error('Update TEST_ADDRESSES with a verified unincorporated Multnomah County coordinate');
      process.exit(1);
    }
    const corbettHasG4020 = corbettBounds.some(r => r.mtfcc === 'G4020');
    if (!corbettHasG4020) {
      console.error(`Pre-flight FAILED: Corbett coordinate (${corbettAddr.lon}, ${corbettAddr.lat}) does not return any G4020 boundary`);
      console.error('Coordinate may be outside Multnomah County — update TEST_ADDRESSES');
      process.exit(1);
    }
    console.log(`  Corbett coordinate confirmed: G4020 present, G4110 absent`);

    // -------------------------------------------------------------------------
    // SC1: Portland City Hall boundary checks
    // -------------------------------------------------------------------------
    console.log('\n=== SC1/SC3: Boundary tests ===');
    for (const addr of TEST_ADDRESSES) {
      console.log(`\n--- ${addr.label} (${addr.lon}, ${addr.lat}) ---`);
      const rows = await queryBoundaries(client, addr.lon, addr.lat);

      if (rows.length === 0) {
        const msg = `${addr.label}: no boundaries matched — check coordinates`;
        console.log(`  FAIL: ${msg}`);
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
        } else {
          console.log(`  OK: ${mtfcc} present`);
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
        } else {
          console.log(`  OK: ${mtfcc} absent (correct — no city boundary at this address)`);
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

    // -------------------------------------------------------------------------
    // SC2: Portland City Hall — COUNTY officials count + name set
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: Portland City Hall COUNTY officials ===');
    const portlandAddr = TEST_ADDRESSES.find(a => a.label.includes('Portland'))!;
    const portlandOfficials = await queryCountyOfficials(client, portlandAddr.lon, portlandAddr.lat);
    console.log(`  Returned ${portlandOfficials.length} COUNTY officials (expected 5):`);
    for (const o of portlandOfficials) {
      console.log(`    ${o.full_name} (${o.district_type})`);
    }
    if (portlandOfficials.length !== 5) {
      const msg = `SC2 FAIL: Portland City Hall returned ${portlandOfficials.length} COUNTY officials (expected 5)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      const returnedNames = new Set(portlandOfficials.map(o => o.full_name));
      let namesMismatch = false;
      for (const name of EXPECTED_COMMISSIONER_NAMES) {
        if (!returnedNames.has(name)) {
          const msg = `SC2 FAIL: expected commissioner '${name}' not in Portland result`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
          namesMismatch = true;
        }
      }
      if (!namesMismatch) {
        console.log('  SC2: All 5 commissioner names match expected set [PASS]');
      }
    }

    // -------------------------------------------------------------------------
    // SC3: Unincorporated Multnomah County — COUNTY officials count + name set
    // (boundaries already checked above; this checks the officials join)
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Corbett OR COUNTY officials ===');
    const corbettOfficials = await queryCountyOfficials(client, corbettAddr.lon, corbettAddr.lat);
    console.log(`  Returned ${corbettOfficials.length} COUNTY officials (expected 5):`);
    for (const o of corbettOfficials) {
      console.log(`    ${o.full_name} (${o.district_type})`);
    }
    if (corbettOfficials.length !== 5) {
      const msg = `SC3 FAIL: Corbett OR returned ${corbettOfficials.length} COUNTY officials (expected 5)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      const returnedNames = new Set(corbettOfficials.map(o => o.full_name));
      let namesMismatch = false;
      for (const name of EXPECTED_COMMISSIONER_NAMES) {
        if (!returnedNames.has(name)) {
          const msg = `SC3 FAIL: expected commissioner '${name}' not in Corbett result`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
          namesMismatch = true;
        }
      }
      if (!namesMismatch) {
        console.log('  SC3: All 5 commissioner names match expected set at unincorporated address [PASS]');
      }
    }

    // -------------------------------------------------------------------------
    // SC4: Section-split check — every G4020 geofence for geo_id='41051'
    //       has a matching COUNTY districts row (0 orphans)
    // -------------------------------------------------------------------------
    console.log("\n=== SC4: Section-split check (geo_id='41051') ===");
    const splitRes = await client.query<{ geo_id: string }>(`
      SELECT gb.geo_id
      FROM essentials.geofence_boundaries gb
      WHERE gb.geo_id = '41051'
        AND gb.mtfcc = 'G4020'
        AND NOT EXISTS (
          SELECT 1 FROM essentials.districts d
          WHERE d.geo_id = gb.geo_id
            AND d.district_type = 'COUNTY'
            AND d.state = 'or'
        )
    `);
    if (splitRes.rows.length > 0) {
      const msg = `SC4 FAIL: section-split orphan for geo_id='41051' — COUNTY district row missing`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log("  SC4: Section-split check OK (COUNTY district row present for geo_id='41051')");
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
    console.log('\nPhase 83 success criteria:');
    console.log('  SC1: Portland City Hall returns G4020 (41051) + G4110 (4159000) [PASS]');
    console.log('  SC2: Portland City Hall returns exactly 5 COUNTY commissioner names [PASS]');
    console.log('  SC3: Corbett OR (unincorporated) returns G4020 only + 5 COUNTY officials, NO G4110 [PASS]');
    console.log('  SC4: Section-split check — 0 orphans for geo_id=41051 [PASS]');
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

/**
 * smoke-fremont-geofences.ts
 * Phase 67-01: Fremont council district geofence smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-fremont-geofences.ts
 *
 * Verifies Phase 67-01 geofence outcomes:
 *   SC1 — Exactly 6 Fremont council district rows in geofence_boundaries
 *          (filtered by geo_id LIKE 'fremont-council-district-%' AND mtfcc='X0008' AND state='06')
 *   SC2 — Fremont City Hall (lon=-121.9886, lat=37.5483) returns exactly 1 council district
 *          (log which district, do NOT assert specific district number — polygon edges vary)
 *   SC3 — Oakland (lon=-122.2711, lat=37.8044) returns 0 Fremont council rows
 *          (outside Fremont — confirms no false positive)
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function queryFremontCouncilBoundaries(
  client: Client, lon: number, lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(`
    SELECT geo_id, name, mtfcc
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE 'fremont-council-district-%'
      AND mtfcc = 'X0008'
      AND state = '06'
      AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
    ORDER BY geo_id
  `, [lon, lat]);
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
    // SC1: Count of Fremont council district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: Fremont council district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'fremont-council-district-%'
         AND mtfcc = 'X0008'
         AND state = '06'`
    );
    const fremontCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  Fremont council district rows: ${fremontCount}`);
    if (fremontCount === 6) {
      console.log('  SC1: PASS (6 rows)');
    } else {
      const msg = `SC1 FAIL: expected 6 rows, got ${fremontCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: Fremont City Hall point inside exactly 1 district
    // Fremont City Hall: 3300 Capitol Ave, Fremont CA
    // Coordinates: lon=-121.9886, lat=37.5483
    // Log which district is returned — do NOT hard-code the district number assertion
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: Fremont City Hall (-121.9886, 37.5483) ===');
    const fremontRows = await queryFremontCouncilBoundaries(client, -121.9886, 37.5483);
    console.log(`  Rows returned: ${fremontRows.length}`);
    for (const row of fremontRows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (fremontRows.length === 1) {
      console.log(`  SC2: PASS (Fremont City Hall → ${fremontRows[0].geo_id} / ${fremontRows[0].name})`);
    } else {
      const msg = `SC2 FAIL: Fremont City Hall returned ${fremontRows.length} rows (expected 1)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: Oakland, CA — must return 0 Fremont council rows (negative test)
    // Oakland City Hall: lon=-122.2711, lat=37.8044
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Oakland, CA (-122.2711, 37.8044) ===');
    const oaklandRows = await queryFremontCouncilBoundaries(client, -122.2711, 37.8044);
    console.log(`  Rows returned: ${oaklandRows.length}`);
    if (oaklandRows.length === 0) {
      console.log('  SC3: PASS (Oakland returns 0 rows — no false positive)');
    } else {
      const msg = `SC3 FAIL: Oakland returned ${oaklandRows.length} Fremont row(s) — false positive`;
      console.log(`  FAIL: ${msg}`);
      for (const row of oaklandRows) {
        console.log(`  unexpected match: geo_id=${row.geo_id} / ${row.name}`);
      }
      errors.push(msg);
      allPassed = false;
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
    console.log('\nPhase 67-01 smoke test success criteria:');
    console.log('  SC1: 6 Fremont council district rows in geofence_boundaries (X0008) [PASS]');
    console.log('  SC2: Fremont City Hall resolves to exactly 1 council district [PASS]');
    console.log('  SC3: Oakland returns 0 Fremont council district rows (no false positive) [PASS]');
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

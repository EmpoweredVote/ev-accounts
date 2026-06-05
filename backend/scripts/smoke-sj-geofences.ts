/**
 * smoke-sj-geofences.ts
 * Phase 64-01: San Jose council district geofence smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-sj-geofences.ts
 *
 * Verifies Phase 64-01 geofence outcomes:
 *   SC1 — Exactly 10 SJ council district rows in geofence_boundaries
 *          (filtered by geo_id LIKE 'sj-council-district-%' AND mtfcc='X0010' AND state='06')
 *   SC2 — SJ City Hall (lon=-121.88, lat=37.335) returns exactly 1 council district
 *          (confirmed District 3 via live ArcGIS spatial query)
 *   SC3 — Oakland (lon=-122.2711, lat=37.8044) returns 0 SJ council rows
 *          (outside San Jose — confirms no false positive)
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function querySJCouncilBoundaries(
  client: Client, lon: number, lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(`
    SELECT geo_id, name, mtfcc
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE 'sj-council-district-%'
      AND mtfcc = 'X0010'
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
    // SC1: Count of SJ council district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: SJ council district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sj-council-district-%'
         AND mtfcc = 'X0010'
         AND state = '06'`
    );
    const sjCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  SJ council district rows: ${sjCount}`);
    if (sjCount === 10) {
      console.log('  SC1: PASS (10 rows)');
    } else {
      const msg = `SC1 FAIL: expected 10 rows, got ${sjCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: SJ City Hall point inside exactly 1 district
    // SJ City Hall: 200 E Santa Clara St, San Jose CA
    // Coordinates: lon=-121.88, lat=37.335
    // Confirmed District 3 (Anthony Tordillos) via live ArcGIS spatial query
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: SJ City Hall (-121.88, 37.335) ===');
    const sjRows = await querySJCouncilBoundaries(client, -121.88, 37.335);
    console.log(`  Rows returned: ${sjRows.length}`);
    for (const row of sjRows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (sjRows.length === 1) {
      console.log(`  SC2: PASS (SJ City Hall → ${sjRows[0].geo_id} / ${sjRows[0].name})`);
    } else {
      const msg = `SC2 FAIL: SJ City Hall returned ${sjRows.length} rows (expected 1)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: Oakland, CA — must return 0 SJ council rows (negative test)
    // Oakland City Hall: lon=-122.2711, lat=37.8044
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Oakland, CA (-122.2711, 37.8044) ===');
    const oaklandRows = await querySJCouncilBoundaries(client, -122.2711, 37.8044);
    console.log(`  Rows returned: ${oaklandRows.length}`);
    if (oaklandRows.length === 0) {
      console.log('  SC3: PASS (Oakland returns 0 rows — no false positive)');
    } else {
      const msg = `SC3 FAIL: Oakland returned ${oaklandRows.length} SJ row(s) — false positive`;
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
    console.log('\nPhase 64-01 smoke test success criteria:');
    console.log('  SC1: 10 SJ council district rows in geofence_boundaries (X0010) [PASS]');
    console.log('  SC2: SJ City Hall resolves to exactly 1 council district [PASS]');
    console.log('  SC3: Oakland returns 0 SJ council district rows (no false positive) [PASS]');
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

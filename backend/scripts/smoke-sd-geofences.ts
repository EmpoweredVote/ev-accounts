/**
 * smoke-sd-geofences.ts
 * Phase 65-01: San Diego council district geofence smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-sd-geofences.ts
 *
 * Verifies Phase 65-01 geofence outcomes:
 *   SC1 — Exactly 9 SD council district rows in geofence_boundaries
 *          (filtered by geo_id LIKE 'sd-council-district-%' AND mtfcc='X0007')
 *   SC2 — San Diego City Hall (lon=-117.1546, lat=32.7157) returns exactly 1 council district
 *          (do NOT hard-code District 3 — research says City Hall is District 3 (Stephen Whitburn)
 *           but polygon edges may vary; assert rowCount === 1, log the district name)
 *   SC3 — Tijuana point (lon=-117.0382, lat=32.5149) returns 0 SD council rows
 *          (outside SD City — confirms no false positive across the US/Mexico border)
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function querySdCouncilBoundaries(
  client: Client, lon: number, lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(`
    SELECT geo_id, name, mtfcc
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE 'sd-council-district-%'
      AND mtfcc = 'X0007'
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
    // SC1: Count of SD council district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: SD council district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sd-council-district-%'
         AND mtfcc = 'X0007'
         AND state = '06'`
    );
    const sdCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  SD council district rows: ${sdCount}`);
    if (sdCount === 9) {
      console.log('  SC1: PASS (9 rows)');
    } else {
      const msg = `SC1 FAIL: expected 9 rows, got ${sdCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: San Diego City Hall point inside exactly 1 district
    // Research indicates City Hall (202 C Street, Downtown) is in District 3
    // (Stephen Whitburn territory) — log result but do not hard-code the assertion
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: San Diego City Hall (-117.1546, 32.7157) ===');
    const sdRows = await querySdCouncilBoundaries(client, -117.1546, 32.7157);
    console.log(`  Rows returned: ${sdRows.length}`);
    for (const row of sdRows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (sdRows.length === 1) {
      console.log(`  SC2: PASS (SD City Hall → ${sdRows[0].geo_id} / ${sdRows[0].name})`);
    } else {
      const msg = `SC2 FAIL: SD City Hall returned ${sdRows.length} rows (expected 1)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: Tijuana, Mexico — must return 0 SD council rows (negative test)
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Tijuana, Mexico (-117.0382, 32.5149) ===');
    const tjRows = await querySdCouncilBoundaries(client, -117.0382, 32.5149);
    console.log(`  Rows returned: ${tjRows.length}`);
    if (tjRows.length === 0) {
      console.log('  SC3: PASS (Tijuana returns 0 rows — no false positive)');
    } else {
      const msg = `SC3 FAIL: Tijuana returned ${tjRows.length} SD row(s) — false positive`;
      console.log(`  FAIL: ${msg}`);
      for (const row of tjRows) {
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
    console.log('\nPhase 65-01 smoke test success criteria:');
    console.log('  SC1: 9 SD council district rows in geofence_boundaries (X0007) [PASS]');
    console.log('  SC2: San Diego City Hall resolves to exactly 1 council district [PASS]');
    console.log('  SC3: Tijuana returns 0 SD council district rows (no false positive) [PASS]');
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

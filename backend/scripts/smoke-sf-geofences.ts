/**
 * smoke-sf-geofences.ts
 * Phase 63-01: San Francisco supervisor district geofence smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-sf-geofences.ts
 *
 * 3 gates:
 *   SC1 — 11 rows in geofence_boundaries with geo_id LIKE 'sf-supervisor-district-%',
 *          mtfcc='X0006', state='06'
 *   SC2 — SF City Hall (-122.4194, 37.7793) returns exactly 1 sf-supervisor-district-* row
 *   SC3 — Oakland City Hall (-122.2711, 37.8044) returns 0 rows (no false positive)
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

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
    // SC1: Count of SF supervisor district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: SF supervisor district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sf-supervisor-district-%'
         AND mtfcc = 'X0006'
         AND state = '06'`
    );
    const sfCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  SF supervisor district rows: ${sfCount}`);
    if (sfCount === 11) {
      console.log('  SC1: PASS (11 rows)');
    } else {
      const msg = `SC1 FAIL: expected 11 rows, got ${sfCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: SF City Hall point inside exactly 1 district
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: SF City Hall (-122.4194, 37.7793) ===');
    const sfRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sf-supervisor-district-%'
         AND mtfcc = 'X0006'
         AND state = '06'
         AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))`,
      [-122.4194, 37.7793]
    );
    console.log(`  Rows returned: ${sfRes.rowCount}`);
    for (const row of sfRes.rows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (sfRes.rowCount === 1) {
      console.log(`  SC2: PASS (SF City Hall → ${sfRes.rows[0].geo_id} / ${sfRes.rows[0].name})`);
    } else {
      const msg = `SC2 FAIL: expected exactly 1 row, got ${sfRes.rowCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: Oakland City Hall point outside all SF districts
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Oakland City Hall (-122.2711, 37.8044) ===');
    const oaklandRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sf-supervisor-district-%'
         AND mtfcc = 'X0006'
         AND state = '06'
         AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))`,
      [-122.2711, 37.8044]
    );
    console.log(`  Rows returned: ${oaklandRes.rowCount}`);
    if (oaklandRes.rowCount === 0) {
      console.log('  SC3: PASS (Oakland returns 0 rows — no false positive)');
    } else {
      const msg = `SC3 FAIL: Oakland returned ${oaklandRes.rowCount} row(s) — expected 0`;
      console.log(`  FAIL: ${msg}`);
      for (const row of oaklandRes.rows) {
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
    console.log('\nPhase 63-01 smoke test success criteria:');
    console.log('  SC1: 11 SF supervisor district rows in geofence_boundaries (X0006) [PASS]');
    console.log('  SC2: SF City Hall resolves to exactly 1 supervisor district [PASS]');
    console.log('  SC3: Oakland City Hall returns 0 SF supervisor district rows [PASS]');
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

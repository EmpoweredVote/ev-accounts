/**
 * smoke-sacramento-geofences.ts
 * Phase 66-01: Sacramento council district geofence smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-sacramento-geofences.ts
 *
 * Verifies Phase 66-01 geofence outcomes:
 *   Gate 1 — Exactly 8 Sacramento council district rows in geofence_boundaries
 *             (filtered by geo_id LIKE 'sacramento-council-district-%' AND mtfcc='X0011' AND state='06')
 *   Gate 2 — Sacramento City Hall (lon=-121.4944, lat=38.5816) returns exactly 1 council district
 *             (district name logged but not hardcoded — boundary may be updated)
 *   Gate 3 — San Jose City Hall (lon=-121.88, lat=37.335) returns 0 Sacramento council rows
 *             (outside Sacramento — confirms no false positive across cities)
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
    // Gate 1: Count of Sacramento council district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== Gate 1: Sacramento council district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE geo_id LIKE 'sacramento-council-district-%'
         AND mtfcc = 'X0011'
         AND state = '06'`
    );
    const sacCount = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  Sacramento council district rows: ${sacCount}`);
    if (sacCount === 8) {
      console.log('  Gate 1: PASS (8 rows)');
    } else {
      const msg = `Gate 1 FAIL: expected 8 rows, got ${sacCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // Gate 2: Sacramento City Hall point inside exactly 1 district
    // Sacramento City Hall: 915 I St, Sacramento CA 95814
    // Coordinates: lon=-121.4944, lat=38.5816
    // District name logged but not hardcoded — boundary source may be updated
    // -------------------------------------------------------------------------
    console.log('\n=== Gate 2: Sacramento City Hall (-121.4944, 38.5816) ===');
    const sacHallRes = await client.query<{ geo_id: string; name: string }>(
      `SELECT geo_id, name
       FROM essentials.geofence_boundaries
       WHERE mtfcc = 'X0011'
         AND geo_id LIKE 'sacramento-council-district-%'
         AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))`,
      [-121.4944, 38.5816]
    );
    console.log(`  Rows returned: ${sacHallRes.rowCount}`);
    for (const row of sacHallRes.rows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (sacHallRes.rowCount === 1) {
      console.log(`  Gate 2: PASS (Sacramento City Hall → ${sacHallRes.rows[0].geo_id} / ${sacHallRes.rows[0].name})`);
    } else {
      const msg = `Gate 2 FAIL: Sacramento City Hall returned ${sacHallRes.rowCount} rows (expected 1)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // Gate 3: San Jose City Hall — must return 0 Sacramento council rows (negative test)
    // San Jose City Hall: 200 E Santa Clara St, San Jose CA
    // Coordinates: lon=-121.88, lat=37.335
    // -------------------------------------------------------------------------
    console.log('\n=== Gate 3: San Jose City Hall (-121.88, 37.335) ===');
    const sjRes = await client.query<{ cnt: string }>(
      `SELECT COUNT(*) AS cnt
       FROM essentials.geofence_boundaries
       WHERE mtfcc = 'X0011'
         AND geo_id LIKE 'sacramento-council-district-%'
         AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))`,
      [-121.88, 37.335]
    );
    const sjCount = parseInt(sjRes.rows[0].cnt, 10);
    console.log(`  Rows returned: ${sjCount}`);
    if (sjCount === 0) {
      console.log('  Gate 3: PASS (San Jose City Hall returns 0 Sacramento rows — no false positive)');
    } else {
      const msg = `Gate 3 FAIL: San Jose City Hall returned ${sjCount} Sacramento council row(s) — false positive`;
      console.log(`  FAIL: ${msg}`);
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
    console.log('ALL GATES PASSED');
    console.log('\nPhase 66-01 smoke test success criteria:');
    console.log('  Gate 1: 8 Sacramento council district rows in geofence_boundaries (X0011) [PASS]');
    console.log('  Gate 2: Sacramento City Hall resolves to exactly 1 council district [PASS]');
    console.log('  Gate 3: San Jose City Hall returns 0 Sacramento council rows (no false positive) [PASS]');
    process.exit(0);
  } else {
    console.log(`FAILED (${errors.length} gate(s)):`);
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

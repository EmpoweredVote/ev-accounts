/**
 * smoke-lausd-geofences.ts
 * Phase 58: LAUSD board district geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-lausd-geofences.ts
 *
 * Verifies Phase 58 roadmap success criteria:
 *   SC1 — Exactly 7 LAUSD rows in geofence_boundaries (geo_id LIKE filter — NOT raw mtfcc count)
 *   SC2 — Downtown LA (lon=-118.2437, lat=34.0522) returns at least 1 LAUSD board district row
 *   SC3 — Pasadena City Hall (lon=-118.1437, lat=34.1478) returns 0 LAUSD rows
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function queryLausdBoundaries(
  client: Client,
  lon: number,
  lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
    `SELECT geo_id, name, mtfcc
     FROM essentials.geofence_boundaries
     WHERE geo_id LIKE 'lausd-board-district-%'
       AND mtfcc = 'G5420'
       AND state = '06'
       AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
     ORDER BY geo_id`,
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
    // SC1: LAUSD board district row count (filter by geo_id pattern, NOT raw mtfcc)
    // CRITICAL: There are already 346 G5420 rows from TIGER UNSD (Phase 57).
    // Querying raw mtfcc would return 353, not 7.
    // -------------------------------------------------------------------------
    console.log("\n=== SC1: LAUSD board district row count ===");
    const countRes = await client.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'lausd-board-district-%'
        AND mtfcc = 'G5420'
        AND state = '06'
    `);
    const total = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  LAUSD board district rows: ${total}`);
    if (total !== 7) {
      const msg = `SC1 FAIL: expected 7 LAUSD rows, got ${total}`;
      console.log(`  ERROR: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log("  SC1: Count OK (7 rows)");
    }

    // -------------------------------------------------------------------------
    // SC2: Positive test — downtown LA must return at least 1 LAUSD board district row
    // Do NOT hard-code which board district number — district boundaries can change
    // -------------------------------------------------------------------------
    console.log("\n=== SC2: Downtown LA positive test (-118.2437, 34.0522) ===");
    const laRows = await queryLausdBoundaries(client, -118.2437, 34.0522);
    if (laRows.length === 0) {
      const msg = "SC2 FAIL: downtown LA returned no LAUSD board district row";
      console.log(`  ERROR: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      for (const row of laRows) {
        console.log(`  ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }
      console.log("  SC2: Positive test OK");
    }

    // -------------------------------------------------------------------------
    // SC3: Negative test — Pasadena City Hall must return 0 LAUSD rows
    // Pasadena is served by Pasadena Unified, not LAUSD
    // -------------------------------------------------------------------------
    console.log("\n=== SC3: Pasadena City Hall negative test (-118.1437, 34.1478) ===");
    const pasadenaRows = await queryLausdBoundaries(client, -118.1437, 34.1478);
    if (pasadenaRows.length > 0) {
      for (const row of pasadenaRows) {
        console.log(`  UNEXPECTED: ${row.mtfcc}  geo_id=${row.geo_id}  name=${row.name}`);
      }
      const msg = `SC3 FAIL: Pasadena returned ${pasadenaRows.length} LAUSD row(s) — false positive`;
      console.log(`  ERROR: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log("  SC3: Negative test OK (no LAUSD rows for Pasadena)");
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
    console.log('\nPhase 58 roadmap success criteria:');
    console.log('  SC1: Exactly 7 LAUSD board district rows (geo_id LIKE filter, not raw mtfcc) [PASS]');
    console.log('  SC2: Downtown LA (-118.2437, 34.0522) returns at least 1 LAUSD board district row [PASS]');
    console.log('  SC3: Pasadena City Hall (-118.1437, 34.1478) returns 0 LAUSD rows [PASS]');
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

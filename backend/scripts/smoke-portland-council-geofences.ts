/**
 * smoke-portland-council-geofences.ts
 * Phase 76: Portland OR council district geofences smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-portland-council-geofences.ts
 *
 * Verifies Phase 76-01 outcomes (success criteria SC-1 .. SC-4):
 *   SC1 — Exactly 4 Portland OR council district rows in geofence_boundaries
 *         (filtered by geo_id LIKE 'portland-or-council-district-%' AND mtfcc='X0012' AND state='41')
 *   SC2 — Portland City Hall (lon=-122.6794, lat=45.5231) returns exactly 1 council district
 *         (do NOT hard-code which district — assert rowCount === 1, log the district name)
 *   SC3 — Salem OR (lon=-123.0351, lat=44.9429) returns 0 Portland council rows (negative test, outside Portland)
 *   SC4 — Section-split check: every geo_id in geofence_boundaries matching
 *         'portland-or-council-district-%' has a corresponding row in essentials.districts (0 orphans)
 */
import 'dotenv/config';
import { Client } from 'pg';

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const errors: string[] = [];
let allPassed = true;

async function queryPortlandCouncilBoundaries(
  client: Client, lon: number, lat: number
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(`
    SELECT geo_id, name, mtfcc
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE 'portland-or-council-district-%'
      AND mtfcc = 'X0012'
      AND state = '41'
      AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($1, $2), 4326))
    ORDER BY geo_id
  `, [lon, lat]);
  return res.rows;
}

async function main() {
  const client = new Client({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();

    // -------------------------------------------------------------------------
    // SC1: Count of Portland OR council district rows in geofence_boundaries
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: Portland OR council district boundary count ===');
    const countRes = await client.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE geo_id LIKE 'portland-or-council-district-%'
        AND mtfcc = 'X0012'
        AND state = '41'
    `);
    const total = parseInt(countRes.rows[0].cnt, 10);
    console.log(`  Portland OR council district rows: ${total}`);
    if (total !== 4) {
      const msg = `SC1 FAIL: expected 4 Portland OR council district rows, got ${total}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC1: Count OK (4 rows)');
    }

    // -------------------------------------------------------------------------
    // SC2: Portland City Hall positive test
    // Portland City Hall: 1221 SW 4th Ave, Portland OR
    // Coordinates: lon=-122.6794, lat=45.5231
    // Log which district is returned — do NOT hard-code the district number
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: Portland City Hall (-122.6794, 45.5231) ===');
    const portlandRows = await queryPortlandCouncilBoundaries(client, -122.6794, 45.5231);
    console.log(`  Rows returned: ${portlandRows.length}`);
    for (const row of portlandRows) {
      console.log(`  district: geo_id=${row.geo_id}  name=${row.name}`);
    }
    if (portlandRows.length !== 1) {
      const msg = `SC2 FAIL: Portland City Hall returned ${portlandRows.length} rows (expected 1)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`  SC2: Portland City Hall → ${portlandRows[0].geo_id} (${portlandRows[0].name})`);
    }

    // -------------------------------------------------------------------------
    // SC3: Salem OR negative test — must return 0 Portland council rows
    // Salem OR City Hall: lon=-123.0351, lat=44.9429
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Salem OR (-123.0351, 44.9429) ===');
    const salemRows = await queryPortlandCouncilBoundaries(client, -123.0351, 44.9429);
    console.log(`  Rows returned: ${salemRows.length}`);
    if (salemRows.length > 0) {
      const msg = `SC3 FAIL: Salem OR returned ${salemRows.length} Portland row(s) — false positive`;
      console.log(`  FAIL: ${msg}`);
      for (const row of salemRows) {
        console.log(`  unexpected match: geo_id=${row.geo_id} / ${row.name}`);
      }
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC3: Negative test OK (Salem returns 0 Portland council districts)');
    }

    // -------------------------------------------------------------------------
    // SC4: Section-split check — every geofence has a matching districts row
    // Detects orphaned geofence_boundaries rows that have no matching essentials.districts row.
    // Established project pattern — run after EVERY seeding phase. Zero rows = clean.
    // -------------------------------------------------------------------------
    console.log('\n=== SC4: Section-split check ===');
    const splitRes = await client.query<{ geo_id: string }>(`
      SELECT gb.geo_id
      FROM essentials.geofence_boundaries gb
      WHERE gb.geo_id LIKE 'portland-or-council-district-%'
        AND gb.mtfcc = 'X0012'
        AND NOT EXISTS (
          SELECT 1 FROM essentials.districts d
          WHERE d.geo_id = gb.geo_id
            AND d.district_type = 'LOCAL'
            AND d.state = 'or'
        )
    `);
    if (splitRes.rowCount && splitRes.rowCount > 0) {
      const msg = `SC4 FAIL: ${splitRes.rowCount} section-split orphan(s): ${splitRes.rows.map(r => r.geo_id).join(', ')}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC4: Section-split check OK (0 orphans — geofences ↔ districts paired)');
    }

  } finally {
    await client.end();
  }

  // -------------------------------------------------------------------------
  // Final result
  // -------------------------------------------------------------------------
  console.log('\n=== Smoke Test Results ===');
  if (allPassed) {
    console.log('\nALL ASSERTIONS PASSED');
    console.log('  SC1 [PASS] — 4 Portland OR council district rows present');
    console.log('  SC2 [PASS] — Portland City Hall resolves to 1 council district');
    console.log('  SC3 [PASS] — Salem OR returns 0 Portland council districts');
    console.log('  SC4 [PASS] — Section-split check returns 0 orphans');
    process.exit(0);
  } else {
    console.error(`\nFAILED (${errors.length} assertion(s)):`);
    for (const e of errors) console.error(`  ${e}`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Smoke test error:', err);
  process.exit(1);
});

/**
 * smoke-phase86.ts
 * Phase 86: Multnomah County School Districts smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-phase86.ts
 *
 * Verifies Phase 86 success criteria:
 *   SC1 — 6 G5420 geofence_boundaries rows for OR (state='41', source='tiger_unsd_or_2024')
 *   SC2 — 6 SCHOOL district rows in essentials.districts for the 6 target GEOIDs
 *   SC3 — Portland City Hall (-122.6794, 45.5231) returns >= 7 PPS board members via SCHOOL routing JOIN
 *   SC4 — Riverdale (-122.6794, 45.4472) returns >= 5 Riverdale board members (geo_id='4110560')
 *          and does NOT return PPS members (district isolation)
 *   SC5 — Section-split check: all 6 G5420 geo_ids have a SCHOOL district row (0 orphans)
 */

import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

interface AddressTest {
  label: string;
  lon: number;
  lat: number;
  expectedMtfcc: string[];
  expectedGeoIds?: Record<string, string>;
}

const TEST_ADDRESSES: AddressTest[] = [
  {
    label: 'Portland City Hall (PPS zone)',
    lon: -122.6794,
    lat: 45.5231,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4110040' },
  },
  {
    label: 'Riverdale (SW Portland — polygon centroid)',
    lon: -122.6627,
    lat: 45.4450,
    expectedMtfcc: ['G5420'],
    expectedGeoIds: { G5420: '4110560' },
  },
];

const TARGET_GEOIDS = ['4110040', '4109480', '4110520', '4102800', '4103940', '4110560'];

async function querySchoolOfficials(
  client: Client,
  lon: number,
  lat: number,
): Promise<Array<{ full_name: string; geo_id: string; district_type: string }>> {
  const res = await client.query<{ full_name: string; geo_id: string; district_type: string }>(
    `SELECT p.full_name, d.geo_id, d.district_type
     FROM essentials.politicians p
     JOIN essentials.office_current_holder och ON och.politician_id = p.id
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
     WHERE gb.state = '41'
       AND d.district_type = 'SCHOOL'
       AND gb.mtfcc = 'G5420'
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
    // SC1: 6 G5420 rows loaded by load-or-school-boundaries.ts
    // -------------------------------------------------------------------------
    console.log('\n=== SC1: G5420 geofence_boundaries count ===');
    const g5420Res = await client.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.geofence_boundaries
      WHERE state = '41'
        AND mtfcc = 'G5420'
        AND source = 'tiger_unsd_or_2024'
    `);
    const g5420Count = parseInt(g5420Res.rows[0].cnt, 10);
    console.log(`  G5420 rows (state='41', source='tiger_unsd_or_2024'): ${g5420Count} (expected 6)`);
    if (g5420Count !== 6) {
      const msg = `SC1 FAIL: expected 6 G5420 rows for OR, found ${g5420Count}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC1: G5420 geofence count OK [PASS]');
    }

    // -------------------------------------------------------------------------
    // SC2: 6 SCHOOL district rows in essentials.districts
    // -------------------------------------------------------------------------
    console.log('\n=== SC2: SCHOOL district rows count ===');
    const schoolDistRes = await client.query<{ cnt: string }>(`
      SELECT COUNT(*) AS cnt
      FROM essentials.districts
      WHERE district_type = 'SCHOOL'
        AND state = 'or'
        AND geo_id IN ('4110040','4109480','4110520','4102800','4103940','4110560')
    `);
    const schoolDistCount = parseInt(schoolDistRes.rows[0].cnt, 10);
    console.log(`  SCHOOL district rows (state='or', 6 target GEOIDs): ${schoolDistCount} (expected 6)`);
    if (schoolDistCount !== 6) {
      const msg = `SC2 FAIL: expected 6 SCHOOL district rows, found ${schoolDistCount}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC2: SCHOOL district count OK [PASS]');
    }

    // -------------------------------------------------------------------------
    // SC3: Portland City Hall returns >= 7 PPS board members (geo_id='4110040')
    // -------------------------------------------------------------------------
    console.log('\n=== SC3: Portland City Hall PPS board members ===');
    const portlandOfficials = await querySchoolOfficials(client, -122.6794, 45.5231);
    console.log(`  Portland City Hall returned ${portlandOfficials.length} SCHOOL officials (expected >= 7):`);
    for (const o of portlandOfficials) {
      console.log(`    ${o.full_name} (geo_id=${o.geo_id})`);
    }
    if (portlandOfficials.length < 7) {
      const msg = `SC3 FAIL: Portland City Hall returned ${portlandOfficials.length} PPS officials (expected >= 7)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      // Also verify all returned officials are PPS (geo_id='4110040')
      const nonPps = portlandOfficials.filter(o => o.geo_id !== '4110040');
      if (nonPps.length > 0) {
        const msg = `SC3 FAIL: Portland City Hall returned officials not from PPS (geo_id!='4110040'): ${nonPps.map(o => `${o.full_name}(${o.geo_id})`).join(', ')}`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      } else {
        console.log(`  SC3: Portland City Hall returns ${portlandOfficials.length} PPS board members (all geo_id='4110040') [PASS]`);
      }
    }

    // -------------------------------------------------------------------------
    // SC4: Riverdale returns >= 5 Riverdale board members AND no PPS members
    // -------------------------------------------------------------------------
    console.log('\n=== SC4: Riverdale school district isolation ===');
    const riverdaleOfficials = await querySchoolOfficials(client, -122.6627, 45.4450);
    console.log(`  Riverdale returned ${riverdaleOfficials.length} SCHOOL officials (expected >= 5):`);
    for (const o of riverdaleOfficials) {
      console.log(`    ${o.full_name} (geo_id=${o.geo_id})`);
    }
    if (riverdaleOfficials.length < 5) {
      const msg = `SC4 FAIL: Riverdale returned ${riverdaleOfficials.length} officials (expected >= 5)`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      // Verify all returned are Riverdale (geo_id='4110560')
      const nonRiverdale = riverdaleOfficials.filter(o => o.geo_id !== '4110560');
      if (nonRiverdale.length > 0) {
        const msg = `SC4 FAIL: Riverdale returned officials not from Riverdale district: ${nonRiverdale.map(o => `${o.full_name}(${o.geo_id})`).join(', ')}`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      } else {
        // Verify no PPS members returned
        const ppsOfficials = riverdaleOfficials.filter(o => o.geo_id === '4110040');
        if (ppsOfficials.length > 0) {
          const msg = `SC4 FAIL: Riverdale returned PPS board members (district isolation failure): ${ppsOfficials.map(o => o.full_name).join(', ')}`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        } else {
          console.log(`  SC4: Riverdale returns ${riverdaleOfficials.length} Riverdale board members and 0 PPS members [PASS]`);
        }
      }
    }

    // -------------------------------------------------------------------------
    // SC5: Section-split check — all 6 G5420 geo_ids have SCHOOL district rows
    // -------------------------------------------------------------------------
    console.log('\n=== SC5: Section-split check ===');
    const splitRes = await client.query<{ geo_id: string }>(`
      SELECT gb.geo_id
      FROM essentials.geofence_boundaries gb
      WHERE gb.geo_id IN ('4110040','4109480','4110520','4102800','4103940','4110560')
        AND gb.mtfcc = 'G5420'
        AND NOT EXISTS (
          SELECT 1 FROM essentials.districts d
          WHERE d.geo_id = gb.geo_id
            AND d.district_type = 'SCHOOL'
            AND d.state = 'or'
        )
    `);
    if (splitRes.rows.length > 0) {
      const orphanGeoIds = splitRes.rows.map(r => r.geo_id).join(', ');
      const msg = `SC5 FAIL: section-split detected ${splitRes.rows.length} G5420 geofence(s) without SCHOOL district rows: ${orphanGeoIds}`;
      console.log(`  FAIL: ${msg}`);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log('  SC5: Section-split check OK — all 6 G5420 geofences have SCHOOL district rows [PASS]');
    }

  } finally {
    await client.end();
  }

  // -------------------------------------------------------------------------
  // Final result
  // -------------------------------------------------------------------------
  console.log('\n=== Phase 86 Smoke Test Results ===');
  if (allPassed) {
    console.log('ALL ASSERTIONS PASSED');
    console.log('\nPhase 86 success criteria:');
    console.log('  SC1: 6 G5420 geofence_boundaries rows (state=\'41\', source=\'tiger_unsd_or_2024\') [PASS]');
    console.log('  SC2: 6 SCHOOL district rows (state=\'or\', 6 target GEOIDs) [PASS]');
    console.log('  SC3: Portland City Hall returns >= 7 PPS board members [PASS]');
    console.log('  SC4: Riverdale returns >= 5 Riverdale board members, 0 PPS members [PASS]');
    console.log('  SC5: Section-split check — 0 orphan G5420 geofences [PASS]');
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

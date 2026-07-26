/**
 * smoke-phase89-in.ts
 * Phase 89 Plan 01: IN school routing smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-phase89-in.ts
 *
 * Verifies Phase 89 Plan 01 success criteria (migration 264 applied):
 *   SC1 — 2 G5420 geofence_boundaries rows for IN (state='18', source='tiger_unsd_in_2024')
 *   SC2 — 2 SCHOOL districts rows for IN (district_type='SCHOOL', state='in', GEOIDs 1804770+1800630)
 *   SC3 — Indianapolis coordinate (-86.1581, 39.7684) returns >= 7 IPS commissioners including Hope Duke Star + Hasaan Rashid; does NOT include Gayle Cosby
 *   SC4 — Bloomington coordinate (-86.5264, 39.1653) returns >= 7 MCCSC trustees including Aja Jester; does NOT include Brandon Shurr
 *   SC5 — Section-split check: 0 orphan G5420 rows for the 2 IN GEOIDs
 *   SC6 — Zero IPS or MCCSC offices have NULL district_id
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  if (!process.env['DATABASE_URL']) {
    console.error('ERROR: DATABASE_URL not set');
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
    // SC1: 2 G5420 geofence_boundaries rows for IN with correct source
    // -------------------------------------------------------------------------
    const sc1Res = await client.query<{ cnt: number }>(
      `SELECT COUNT(*)::int AS cnt
       FROM essentials.geofence_boundaries
       WHERE state = '18'
         AND mtfcc = 'G5420'
         AND source = 'tiger_unsd_in_2024'`
    );
    const sc1Count = sc1Res.rows[0].cnt;
    if (sc1Count === 2) {
      console.log('SC1: PASS (2 G5420 geofence_boundaries rows for IN with source=tiger_unsd_in_2024)');
    } else {
      const msg = `SC1: FAIL — expected 2 G5420 IN geofence rows (source=tiger_unsd_in_2024), found ${sc1Count}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: 2 SCHOOL districts rows for IN (state='in' lowercase per routing convention)
    // -------------------------------------------------------------------------
    const sc2Res = await client.query<{ cnt: number }>(
      `SELECT COUNT(*)::int AS cnt
       FROM essentials.districts
       WHERE district_type = 'SCHOOL'
         AND state = 'in'
         AND geo_id IN ('1804770', '1800630')`
    );
    const sc2Count = sc2Res.rows[0].cnt;
    if (sc2Count === 2) {
      console.log('SC2: PASS (2 SCHOOL districts rows for IN with state=in, geo_ids 1804770+1800630)');
    } else {
      const msg = `SC2: FAIL — expected 2 SCHOOL districts rows for IN (geo_ids 1804770+1800630, state='in'), found ${sc2Count}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: IPS routing — Indianapolis coordinate returns >= 7 commissioners
    //      Must include Hope Duke Star AND Hasaan Rashid; must NOT include Gayle Cosby
    // -------------------------------------------------------------------------
    const sc3Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.office_current_holder och ON och.politician_id = p.id
       JOIN essentials.offices o ON o.id = och.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '18'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-86.1581, 39.7684]
    );
    const sc3Names = new Set(sc3Res.rows.map(r => r.full_name));
    const sc3GeoIds = new Set(sc3Res.rows.map(r => r.geo_id));
    const sc3Count = sc3Res.rows.length;

    if (sc3Count < 7) {
      const msg = `SC3: FAIL — Indianapolis routing returned ${sc3Count} IPS commissioners (expected >= 7); names: ${Array.from(sc3Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc3Names.has('Hope Duke Star')) {
      const msg = `SC3: FAIL — 'Hope Duke Star' not in Indianapolis routing results (${sc3Count} rows returned)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc3Names.has('Hasaan Rashid')) {
      const msg = `SC3: FAIL — 'Hasaan Rashid' not in Indianapolis routing results (${sc3Count} rows returned)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (sc3Names.has('Gayle Cosby')) {
      const msg = `SC3: FAIL — 'Gayle Cosby' still present in Indianapolis routing results (should have been replaced by Hasaan Rashid)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc3GeoIds.has('1804770') || sc3GeoIds.size !== 1) {
      const msg = `SC3: FAIL — expected all rows to have geo_id='1804770', got: ${Array.from(sc3GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC3: PASS — Indianapolis routing returned ${sc3Count} IPS commissioners including Hope Duke Star + Hasaan Rashid; Gayle Cosby absent`);
      for (const row of sc3Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC4: MCCSC routing — Bloomington coordinate returns >= 7 trustees
    //      Must include Aja Jester; must NOT include Brandon Shurr
    // -------------------------------------------------------------------------
    const sc4Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.office_current_holder och ON och.politician_id = p.id
       JOIN essentials.offices o ON o.id = och.office_id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '18'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-86.5264, 39.1653]
    );
    const sc4Names = new Set(sc4Res.rows.map(r => r.full_name));
    const sc4GeoIds = new Set(sc4Res.rows.map(r => r.geo_id));
    const sc4Count = sc4Res.rows.length;

    if (sc4Count < 7) {
      const msg = `SC4: FAIL — Bloomington routing returned ${sc4Count} MCCSC trustees (expected >= 7); names: ${Array.from(sc4Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc4Names.has('Aja Jester')) {
      const msg = `SC4: FAIL — 'Aja Jester' not in Bloomington routing results (${sc4Count} rows returned)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (sc4Names.has('Brandon Shurr')) {
      const msg = `SC4: FAIL — 'Brandon Shurr' still present in Bloomington routing results (should have been replaced by Aja Jester)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc4GeoIds.has('1800630') || sc4GeoIds.size !== 1) {
      const msg = `SC4: FAIL — expected all rows to have geo_id='1800630', got: ${Array.from(sc4GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC4: PASS — Bloomington routing returned ${sc4Count} MCCSC trustees including Aja Jester; Brandon Shurr absent`);
      for (const row of sc4Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC5: Section-split check — 0 orphan G5420 rows for the 2 IN GEOIDs
    //      Each G5420 geofence row must have a matching SCHOOL districts row
    // -------------------------------------------------------------------------
    const sc5Res = await client.query<{ geo_id: string }>(
      `SELECT gb.geo_id
       FROM essentials.geofence_boundaries gb
       WHERE gb.geo_id IN ('1804770', '1800630')
         AND gb.mtfcc = 'G5420'
         AND NOT EXISTS (
           SELECT 1 FROM essentials.districts d
           WHERE d.geo_id = gb.geo_id
             AND d.district_type = 'SCHOOL'
             AND d.state = 'in'
         )`
    );
    if (sc5Res.rows.length === 0) {
      console.log('SC5: PASS — section-split check: 0 orphan G5420 rows for GEOIDs 1804770+1800630');
    } else {
      const orphans = sc5Res.rows.map(r => r.geo_id).join(', ');
      const msg = `SC5: FAIL — section-split orphans found for geo_ids: ${orphans} (missing SCHOOL districts rows with state='in')`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC6: Office back-fill — zero IPS or MCCSC offices have NULL district_id
    // -------------------------------------------------------------------------
    const sc6Res = await client.query<{ cnt: number }>(
      `SELECT COUNT(*)::int AS cnt
       FROM essentials.offices o
       JOIN essentials.chambers ch ON ch.id = o.chamber_id
       JOIN essentials.governments g ON g.id = ch.government_id
       WHERE (g.name LIKE 'Indianapolis Public Schools%'
          OR g.name LIKE 'Monroe County Community School%')
         AND o.district_id IS NULL`
    );
    const sc6Count = sc6Res.rows[0].cnt;
    if (sc6Count === 0) {
      console.log('SC6: PASS — 0 IPS or MCCSC offices have NULL district_id');
    } else {
      const msg = `SC6: FAIL — ${sc6Count} IPS or MCCSC offices still have NULL district_id (office back-fill incomplete)`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

  } finally {
    await client.end();
  }

  // -------------------------------------------------------------------------
  // Final result
  // -------------------------------------------------------------------------
  console.log('\n=== Phase 89 IN Smoke Test Results ===');
  if (allPassed) {
    console.log('ALL ASSERTIONS PASSED');
    process.exit(0);
  } else {
    console.log(`FAILED (${errors.length} assertion(s)):`);
    for (const err of errors) {
      console.log(`  - ${err}`);
    }
    process.exit(1);
  }
}

main().catch(err => { console.error('Smoke test error:', err); process.exit(1); });

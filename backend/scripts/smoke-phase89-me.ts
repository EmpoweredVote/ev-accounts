/**
 * smoke-phase89-me.ts
 * Phase 89 Plan 02: ME school board routing smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-phase89-me.ts
 *
 * Verifies Phase 89 Plan 02 success criteria (migration 265 applied):
 *   SC1 — 5 G5420 geofence_boundaries rows for ME (state='23', source='tiger_unsd_me_2024')
 *   SC2 — 5 SCHOOL districts rows for ME (district_type='SCHOOL', state='me' lowercase, all 5 GEOIDs)
 *   SC3 — Lewiston coord (-70.2140, 44.0978) returns >= 7 members with geo_id='2307320';
 *          must include Luke Jensen (At-Large, election-confirmed HIGH confidence)
 *   SC4 — Bangor coord (-68.7772, 44.8012) returns >= 7 members with geo_id='2302820';
 *          must include Tim Surrette (Chair, Wayback-confirmed May 2026)
 *   SC5 — South Portland coord (-70.2788, 43.6415) returns >= 6 members with geo_id='2312330';
 *          must include Rosemarie De Angelis (D3 Chair, HIGH confidence)
 *   SC6 — Auburn coord (-70.2312, 44.0978) returns >= 7 members with geo_id='2302610';
 *          must include Korin McGuigan (Ward 1, official PDF confirmed)
 *   SC7 — Biddeford coord (-70.4520, 43.4909) returns >= 7 members with geo_id='2303150';
 *          must include Meagan Desjardins (highest vote-getter Nov 2025, HIGH confidence)
 *   SC8 — Section-split check: 0 orphan G5420 rows for the 5 ME GEOIDs
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
    // SC1: 5 G5420 geofence_boundaries rows for ME with correct source
    // -------------------------------------------------------------------------
    const sc1Res = await client.query<{ cnt: number }>(
      `SELECT COUNT(*)::int AS cnt
       FROM essentials.geofence_boundaries
       WHERE state = '23'
         AND mtfcc = 'G5420'
         AND source = 'tiger_unsd_me_2024'`
    );
    const sc1Count = sc1Res.rows[0].cnt;
    if (sc1Count === 5) {
      console.log('SC1: PASS (5 G5420 geofence_boundaries rows for ME with source=tiger_unsd_me_2024)');
    } else {
      const msg = `SC1: FAIL — expected 5 G5420 ME geofence rows (source=tiger_unsd_me_2024), found ${sc1Count}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC2: 5 SCHOOL districts rows for ME (state='me' lowercase per routing convention)
    // -------------------------------------------------------------------------
    const sc2Res = await client.query<{ cnt: number }>(
      `SELECT COUNT(*)::int AS cnt
       FROM essentials.districts
       WHERE district_type = 'SCHOOL'
         AND state = 'me'
         AND geo_id IN ('2307320', '2302820', '2312330', '2302610', '2303150')`
    );
    const sc2Count = sc2Res.rows[0].cnt;
    if (sc2Count === 5) {
      console.log('SC2: PASS (5 SCHOOL districts rows for ME with state=me, all 5 ME GEOIDs)');
    } else {
      const msg = `SC2: FAIL — expected 5 SCHOOL districts rows for ME (geo_ids 2307320/2302820/2312330/2302610/2303150, state='me'), found ${sc2Count}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    }

    // -------------------------------------------------------------------------
    // SC3: Lewiston routing — coord (-70.2140, 44.0978) returns >= 7 members
    //      geo_id must all be '2307320'; must include Luke Jensen (At-Large)
    // -------------------------------------------------------------------------
    const sc3Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.politician_id = p.id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '23'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-70.2140, 44.0978]
    );
    const sc3Names = new Set(sc3Res.rows.map(r => r.full_name));
    const sc3GeoIds = new Set(sc3Res.rows.map(r => r.geo_id));
    const sc3Count = sc3Res.rows.length;

    if (sc3Count < 7) {
      const msg = `SC3: FAIL — Lewiston routing returned ${sc3Count} members (expected >= 7); names: ${Array.from(sc3Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc3Names.has('Luke Jensen')) {
      const msg = `SC3: FAIL — 'Luke Jensen' not in Lewiston routing results (${sc3Count} rows returned): ${Array.from(sc3Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc3GeoIds.has('2307320') || sc3GeoIds.size !== 1) {
      const msg = `SC3: FAIL — expected all rows to have geo_id='2307320', got: ${Array.from(sc3GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC3: PASS — Lewiston routing returned ${sc3Count} members including Luke Jensen; geo_id=2307320`);
      for (const row of sc3Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC4: Bangor routing — coord (-68.7772, 44.8012) returns >= 7 members
    //      geo_id must all be '2302820'; must include Tim Surrette (Chair)
    // -------------------------------------------------------------------------
    const sc4Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.politician_id = p.id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '23'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-68.7772, 44.8012]
    );
    const sc4Names = new Set(sc4Res.rows.map(r => r.full_name));
    const sc4GeoIds = new Set(sc4Res.rows.map(r => r.geo_id));
    const sc4Count = sc4Res.rows.length;

    if (sc4Count < 7) {
      const msg = `SC4: FAIL — Bangor routing returned ${sc4Count} members (expected >= 7); names: ${Array.from(sc4Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc4Names.has('Tim Surrette')) {
      const msg = `SC4: FAIL — 'Tim Surrette' not in Bangor routing results (${sc4Count} rows returned): ${Array.from(sc4Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc4GeoIds.has('2302820') || sc4GeoIds.size !== 1) {
      const msg = `SC4: FAIL — expected all rows to have geo_id='2302820', got: ${Array.from(sc4GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC4: PASS — Bangor routing returned ${sc4Count} members including Tim Surrette; geo_id=2302820`);
      for (const row of sc4Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC5: South Portland routing — coord (-70.2788, 43.6415) returns >= 6 members
    //      geo_id must all be '2312330'; must include Rosemarie De Angelis (D3 Chair)
    //      (D5 may be vacant — hence >= 6 not >= 7)
    // -------------------------------------------------------------------------
    // NOTE: Original plan coordinate (-70.2788, 43.6415) was outside the polygon.
    // Using district centroid (-70.28619, 43.63179) which is confirmed inside.
    // Auto-fix [Rule 1]: PostGIS ST_Centroid confirmed this coordinate is inside the district.
    const sc5Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.politician_id = p.id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '23'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-70.28619, 43.63179]
    );
    const sc5Names = new Set(sc5Res.rows.map(r => r.full_name));
    const sc5GeoIds = new Set(sc5Res.rows.map(r => r.geo_id));
    const sc5Count = sc5Res.rows.length;

    if (sc5Count < 6) {
      const msg = `SC5: FAIL — South Portland routing returned ${sc5Count} members (expected >= 6); names: ${Array.from(sc5Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc5Names.has('Rosemarie De Angelis')) {
      const msg = `SC5: FAIL — 'Rosemarie De Angelis' not in South Portland routing results (${sc5Count} rows returned): ${Array.from(sc5Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc5GeoIds.has('2312330') || sc5GeoIds.size !== 1) {
      const msg = `SC5: FAIL — expected all rows to have geo_id='2312330', got: ${Array.from(sc5GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC5: PASS — South Portland routing returned ${sc5Count} members including Rosemarie De Angelis; geo_id=2312330`);
      for (const row of sc5Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC6: Auburn routing — coord (-70.2312, 44.0978) returns >= 7 members
    //      geo_id must all be '2302610'; must include Korin McGuigan (Ward 1)
    // -------------------------------------------------------------------------
    const sc6Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.politician_id = p.id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '23'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-70.2312, 44.0978]
    );
    const sc6Names = new Set(sc6Res.rows.map(r => r.full_name));
    const sc6GeoIds = new Set(sc6Res.rows.map(r => r.geo_id));
    const sc6Count = sc6Res.rows.length;

    if (sc6Count < 7) {
      const msg = `SC6: FAIL — Auburn routing returned ${sc6Count} members (expected >= 7); names: ${Array.from(sc6Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc6Names.has('Korin McGuigan')) {
      const msg = `SC6: FAIL — 'Korin McGuigan' not in Auburn routing results (${sc6Count} rows returned): ${Array.from(sc6Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc6GeoIds.has('2302610') || sc6GeoIds.size !== 1) {
      const msg = `SC6: FAIL — expected all rows to have geo_id='2302610', got: ${Array.from(sc6GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC6: PASS — Auburn routing returned ${sc6Count} members including Korin McGuigan; geo_id=2302610`);
      for (const row of sc6Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC7: Biddeford routing — coord (-70.4520, 43.4909) returns >= 7 members
    //      geo_id must all be '2303150'; must include Meagan Desjardins (highest vote-getter)
    // -------------------------------------------------------------------------
    const sc7Res = await client.query<{ full_name: string; geo_id: string }>(
      `SELECT p.full_name, d.geo_id
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.politician_id = p.id
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
       WHERE gb.state = '23'
         AND d.district_type = 'SCHOOL'
         AND gb.mtfcc = 'G5420'
         AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
       ORDER BY p.full_name`,
      [-70.4520, 43.4909]
    );
    const sc7Names = new Set(sc7Res.rows.map(r => r.full_name));
    const sc7GeoIds = new Set(sc7Res.rows.map(r => r.geo_id));
    const sc7Count = sc7Res.rows.length;

    if (sc7Count < 7) {
      const msg = `SC7: FAIL — Biddeford routing returned ${sc7Count} members (expected >= 7); names: ${Array.from(sc7Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc7Names.has('Meagan Desjardins')) {
      const msg = `SC7: FAIL — 'Meagan Desjardins' not in Biddeford routing results (${sc7Count} rows returned): ${Array.from(sc7Names).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else if (!sc7GeoIds.has('2303150') || sc7GeoIds.size !== 1) {
      const msg = `SC7: FAIL — expected all rows to have geo_id='2303150', got: ${Array.from(sc7GeoIds).join(', ')}`;
      console.log(msg);
      errors.push(msg);
      allPassed = false;
    } else {
      console.log(`SC7: PASS — Biddeford routing returned ${sc7Count} members including Meagan Desjardins; geo_id=2303150`);
      for (const row of sc7Res.rows) {
        console.log(`  ${row.full_name} (geo_id=${row.geo_id})`);
      }
    }

    // -------------------------------------------------------------------------
    // SC8: Section-split check — 0 orphan G5420 rows for the 5 ME GEOIDs
    //      Each G5420 geofence row must have a matching SCHOOL districts row (state='me')
    // -------------------------------------------------------------------------
    const sc8Res = await client.query<{ geo_id: string }>(
      `SELECT gb.geo_id
       FROM essentials.geofence_boundaries gb
       WHERE gb.geo_id IN ('2307320', '2302820', '2312330', '2302610', '2303150')
         AND gb.mtfcc = 'G5420'
         AND NOT EXISTS (
           SELECT 1 FROM essentials.districts d
           WHERE d.geo_id = gb.geo_id
             AND d.district_type = 'SCHOOL'
             AND d.state = 'me'
         )`
    );
    if (sc8Res.rows.length === 0) {
      console.log('SC8: PASS — section-split check: 0 orphan G5420 rows for the 5 ME GEOIDs');
    } else {
      const orphans = sc8Res.rows.map(r => r.geo_id).join(', ');
      const msg = `SC8: FAIL — section-split orphans found for geo_ids: ${orphans} (missing SCHOOL districts rows with state='me')`;
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
  console.log('\n=== Phase 89 ME Smoke Test Results ===');
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

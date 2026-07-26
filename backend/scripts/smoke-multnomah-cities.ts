/**
 * smoke-multnomah-cities.ts
 * Phase 84: Multnomah smaller cities routing smoke test
 *
 * Usage (from C:/EV-Accounts/backend):
 *   npx tsx scripts/smoke-multnomah-cities.ts
 *
 * Verifies Phase 84 success criteria:
 *   SC1 — Each city centroid returns G4110 with correct geo_id
 *   SC2 — Each city centroid returns LOCAL + LOCAL_EXEC officials via districts JOIN
 *   SC3 — Section-split check: all 5 G4110 geo_ids have LOCAL + LOCAL_EXEC district rows (0 orphans)
 */
import { Client } from 'pg';
import * as dotenv from 'dotenv';
dotenv.config();

interface AddressTest {
  label: string;
  lon: number;
  lat: number;
  expectedMtfcc: string[];
  forbiddenMtfcc?: string[];
  expectedGeoIds?: Record<string, string>;
}

const TEST_ADDRESSES: AddressTest[] = [
  {
    label: 'Gresham (centroid)',
    lon: -122.441364519028,
    lat: 45.5021166610009,
    expectedMtfcc: ['G4110'],
    expectedGeoIds: { G4110: '4131250' },
  },
  {
    label: 'Troutdale (centroid)',
    lon: -122.395436661508,
    lat: 45.5372271419675,
    expectedMtfcc: ['G4110'],
    expectedGeoIds: { G4110: '4174850' },
  },
  {
    label: 'Fairview (centroid)',
    lon: -122.438921112803,
    lat: 45.5469083700965,
    expectedMtfcc: ['G4110'],
    expectedGeoIds: { G4110: '4124250' },
  },
  {
    label: 'Wood Village (centroid)',
    lon: -122.420492816904,
    lat: 45.5357895342016,
    expectedMtfcc: ['G4110'],
    expectedGeoIds: { G4110: '4183950' },
  },
  {
    label: 'Maywood Park (centroid)',
    lon: -122.56177821613,
    lat: 45.5525170048598,
    expectedMtfcc: ['G4110'],
    expectedGeoIds: { G4110: '4146730' },
  },
];
// All 5 centroids verified against production DB [VERIFIED: DB query 2026-05-31]

const EXPECTED_NAMES_BY_GEO_ID: Record<string, string[]> = {
  '4131250': [
    'Travis Stovall',
    'Kayla Brown',
    'Eddy Morales',
    'Cathy Keathley',
    'Jerry Hinton',
    'Sue Piazza',
    'Janine Gladfelter',
  ],
  '4174850': [
    'David Ripma',
    'Carol Allen',
    'Jesse Davidson',
    'John Leamy',
    'Glenn White',
    'Geoffrey Wunn',
    'Zach Andrews',
  ],
  '4124250': [
    'Keith Kudrna',
    'Jeff Dennerline',
    'Steve Marker',
    "E'an Todd",
    'Jenni Weber',
    'Steve Owen',
    'Paul Copeland',
  ],
  '4183950': [
    'Jairo Rios-Campos',
    'Dara Tan',
    'John Miner',
    'Charlene Gothard',
    'Patricia Smith',
  ],
  '4146730': [
    'Jim Akers',
    'Kevin Bussema',
    'Jeff Baltzell',
    'Miriam Berman',
    'Thomas Welander',
  ],
};

async function queryBoundaries(
  client: Client,
  lon: number,
  lat: number,
): Promise<Array<{ geo_id: string; name: string; mtfcc: string }>> {
  const res = await client.query<{ geo_id: string; name: string; mtfcc: string }>(
    `SELECT geo_id, name, mtfcc
     FROM essentials.geofence_boundaries
     WHERE state = '41'
       AND ST_Covers(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
     ORDER BY mtfcc`,
    [lon, lat],
  );
  return res.rows;
}

// Replaces queryCountyOfficials — queries LOCAL and LOCAL_EXEC officials for a city coordinate
async function queryLocalOfficials(
  client: Client,
  lon: number,
  lat: number,
): Promise<Array<{ full_name: string; district_type: string }>> {
  const res = await client.query<{ full_name: string; district_type: string }>(
    `SELECT p.full_name, d.district_type
     FROM essentials.politicians p
     JOIN essentials.office_current_holder och ON och.politician_id = p.id
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.districts d ON d.id = o.district_id
     JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
                                            AND gb.mtfcc = 'G4110'
     WHERE gb.state = '41'
       AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
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
    // Pre-flight: verify all 5 G4110 city boundaries exist (Phase 72 load)
    // -------------------------------------------------------------------------
    console.log('\n=== Pre-flight: Phase 72 G4110 city boundary integrity ===');
    const pfRes = await client.query<{ count: string }>(
      `SELECT COUNT(*) FROM essentials.geofence_boundaries
       WHERE geo_id IN ('4131250','4174850','4124250','4183950','4146730')
         AND mtfcc = 'G4110'`,
    );
    const pfCount = parseInt(pfRes.rows[0].count, 10);
    if (pfCount !== 5) {
      console.error(
        `Pre-flight FAIL: not all 5 G4110 city boundaries loaded (found ${pfCount}) — Phase 72 must be re-applied`,
      );
      await client.end();
      process.exit(1);
    }
    console.log(`  All 5 G4110 city boundaries confirmed`);

    // -------------------------------------------------------------------------
    // SC1 + SC2: Per-city boundary and officials checks
    // -------------------------------------------------------------------------
    for (const addr of TEST_ADDRESSES) {
      console.log(`\n=== ${addr.label} ===`);

      // SC1: Boundary check
      const boundaries = await queryBoundaries(client, addr.lon, addr.lat);
      const returnedMtfcc = new Set(boundaries.map(r => r.mtfcc));

      for (const mtfcc of addr.expectedMtfcc) {
        if (!returnedMtfcc.has(mtfcc)) {
          const msg = `SC1 FAIL: ${addr.label}: expected ${mtfcc} but not found`;
          console.log(`  FAIL: ${msg}`);
          errors.push(msg);
          allPassed = false;
        } else {
          console.log(`  SC1: ${mtfcc} present`);
        }
      }

      if (addr.expectedGeoIds) {
        for (const [mtfcc, expectedGeoId] of Object.entries(addr.expectedGeoIds)) {
          const matchedRow = boundaries.find(r => r.mtfcc === mtfcc);
          if (!matchedRow) {
            const msg = `SC1 FAIL: ${addr.label}: ${mtfcc} not returned — cannot verify geo_id`;
            console.log(`  FAIL: ${msg}`);
            errors.push(msg);
            allPassed = false;
          } else if (matchedRow.geo_id !== expectedGeoId) {
            const msg = `SC1 FAIL: ${addr.label}: ${mtfcc} geo_id expected ${expectedGeoId}, got ${matchedRow.geo_id}`;
            console.log(`  FAIL: ${msg}`);
            errors.push(msg);
            allPassed = false;
          } else {
            console.log(`  SC1: ${mtfcc} geo_id=${matchedRow.geo_id} (${matchedRow.name}) [PASS]`);
          }
        }
      }

      // SC2: Officials check
      const officials = await queryLocalOfficials(client, addr.lon, addr.lat);
      const expectedGeoId = addr.expectedGeoIds?.['G4110'];
      if (!expectedGeoId) {
        errors.push(`SC2 FAIL: ${addr.label}: no G4110 expectedGeoId to look up names`);
        allPassed = false;
        continue;
      }

      const expectedNames = EXPECTED_NAMES_BY_GEO_ID[expectedGeoId] ?? [];
      const returnedNames = officials.map(o => o.full_name).sort();
      const sortedExpected = [...expectedNames].sort();

      console.log(
        `  SC2: Returned ${officials.length} officials (expected ${expectedNames.length}):`,
      );
      for (const o of officials) {
        console.log(`    ${o.full_name} (${o.district_type})`);
      }

      if (officials.length !== expectedNames.length) {
        const msg = `SC2 FAIL: ${addr.label}: got ${officials.length} officials, expected ${expectedNames.length}`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }

      const missingNames = sortedExpected.filter(n => !returnedNames.includes(n));
      const unexpectedNames = returnedNames.filter(n => !sortedExpected.includes(n));

      if (missingNames.length > 0) {
        const msg = `SC2 FAIL: ${addr.label}: missing officials: ${missingNames.join(', ')}`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
      if (unexpectedNames.length > 0) {
        const msg = `SC2 FAIL: ${addr.label}: unexpected officials: ${unexpectedNames.join(', ')}`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
      if (missingNames.length === 0 && unexpectedNames.length === 0 && officials.length === expectedNames.length) {
        console.log(`  SC2: All ${expectedNames.length} officials match expected set [PASS]`);
      }
    }

    // -------------------------------------------------------------------------
    // SC3: Section-split check — all 5 G4110 geo_ids must have LOCAL + LOCAL_EXEC
    // -------------------------------------------------------------------------
    console.log('\n=== SC_SPLIT: Section-split check (5 cities) ===');
    const splitRes = await client.query<{ geo_id: string; name: string }>(`
      SELECT gb.geo_id, gb.name
      FROM essentials.geofence_boundaries gb
      WHERE gb.geo_id IN ('4131250','4174850','4124250','4183950','4146730')
        AND gb.mtfcc = 'G4110'
        AND NOT EXISTS (
          SELECT 1 FROM essentials.districts d
          WHERE d.geo_id = gb.geo_id
            AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
            AND d.state = 'or'
        )
    `);

    if (splitRes.rows.length > 0) {
      for (const row of splitRes.rows) {
        const msg = `SC_SPLIT FAIL: no LOCAL/LOCAL_EXEC district for geo_id='${row.geo_id}' (${row.name})`;
        console.log(`  FAIL: ${msg}`);
        errors.push(msg);
        allPassed = false;
      }
    } else {
      console.log('  SC_SPLIT: All 5 cities have LOCAL + LOCAL_EXEC district rows [PASS]');
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
    console.log('\nPhase 84 success criteria:');
    console.log('  SC1: All 5 city centroids return correct G4110 geo_id [PASS]');
    console.log('  SC2: All 5 cities return LOCAL + LOCAL_EXEC officials [PASS]');
    console.log('  SC3: Section-split check — 0 orphans across 5 cities [PASS]');
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

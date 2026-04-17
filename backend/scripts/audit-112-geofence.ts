/**
 * audit-112-geofence.ts — Geofence smoke test for Monroe County May 5, 2026 primary (AUDIT-08).
 *
 * Runs 6 strategically chosen Monroe County addresses through the PostGIS geofence stack
 * to verify that each address resolves to the expected races. Also reports races that have
 * no geofence link (office_id IS NULL) — these are address-independent.
 *
 * Output: CSV to stdout with columns: address_label,position_name,primary_party,candidate_name
 *   After the main CSV, a second section is output:
 *   UNLINKED_RACES,position_name,primary_party,candidate_count
 * Progress/summary messages go to stderr.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/audit-112-geofence.ts             # Full CSV report
 *   npx tsx scripts/audit-112-geofence.ts --dry-run   # List 6 addresses and unlinked race count only
 *
 * NOTE: Coordinates are pre-geocoded (Census Geocoder API, April 2026) to avoid runtime
 * external API calls. ST_MakePoint takes (longitude, latitude) order.
 *
 * References:
 *   - link-monroe-county-races-to-geofences.sql (geofence join pattern — ST_Covers)
 *   - RESEARCH.md Pitfall 5: unlinked races (office_id IS NULL) must be reported separately
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TestAddress {
  label: string;
  address: string;
  lat: number;
  lng: number;
  expectedTownship: string;
  expectedStateDistrict: string;
}

interface GeofenceRow {
  position_name: string;
  primary_party: string | null;
  full_name: string | null;
}

interface UnlinkedRaceRow {
  position_name: string;
  primary_party: string | null;
  candidate_count: string;
}

interface ElectionRow {
  id: string;
  name: string;
}

// ---------------------------------------------------------------------------
// Test addresses with pre-geocoded coordinates
// Coordinates sourced from Census Geocoder API (benchmark: Public_AR_Current, April 2026).
// ST_MakePoint takes (longitude, latitude) — note x=lng, y=lat convention.
// ---------------------------------------------------------------------------

const TEST_ADDRESSES: TestAddress[] = [
  {
    label: 'Bloomington City Center',
    address: '200 W Kirkwood Ave, Bloomington IN 47404',
    lat: 39.166646,
    lng: -86.534947,
    expectedTownship: 'Bloomington',
    expectedStateDistrict: 'D-61',
  },
  {
    label: 'Perry Township (SE)',
    address: '4600 E Moores Pike, Bloomington IN 47401',
    lat: 39.115926,
    lng: -86.475955,
    expectedTownship: 'Perry',
    expectedStateDistrict: 'D-61 or D-60',
  },
  {
    label: 'Clear Creek Township',
    address: '4800 W Vernal Pike, Bloomington IN 47404',
    lat: 39.186208,
    lng: -86.596295,
    expectedTownship: 'Clear Creek',
    expectedStateDistrict: 'D-60',
  },
  {
    label: 'Richland Township (Rural)',
    address: '5891 W Rockport Rd, Bloomington IN 47403',
    lat: 39.094693,
    lng: -86.584827,
    expectedTownship: 'Richland',
    expectedStateDistrict: 'D-60',
  },
  {
    label: 'IU Campus',
    address: '1001 E 17th St, Bloomington IN 47408',
    lat: 39.179084,
    lng: -86.521168,
    expectedTownship: 'Bloomington',
    expectedStateDistrict: 'D-61',
  },
  {
    label: 'Ellettsville',
    address: '104 Temperance St, Ellettsville IN 47429',
    lat: 39.231254,
    lng: -86.621252,
    expectedTownship: 'Perry area',
    expectedStateDistrict: 'D-46 or D-62',
  },
];

// ---------------------------------------------------------------------------
// CSV helpers
// ---------------------------------------------------------------------------

function escapeCsv(value: string | null | undefined): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Step 1: Validate election exists (same gate pattern as other audit scripts)
  const electionResult = await pool.query<ElectionRow>(`
    SELECT id, name
    FROM essentials.elections
    WHERE election_date = '2026-05-05' AND state = 'IN'
  `);

  const elections = electionResult.rows;
  console.error(`Found ${elections.length} election(s) for 2026-05-05 IN`);

  if (elections.length === 0) {
    console.error('ERROR: No election found for election_date=2026-05-05, state=IN. Aborting.');
    await pool.end();
    process.exit(1);
  }

  if (elections.length > 1) {
    console.error(`WARNING: Found ${elections.length} elections. Continuing with all matching rows.`);
    for (const e of elections) {
      console.error(`  Election: id=${e.id}, name=${e.name}`);
    }
  } else {
    console.error(`  Election: id=${elections[0].id}, name=${elections[0].name}`);
  }

  // Step 2: Query B — Unlinked races (office_id IS NULL), runs once (address-independent).
  // Per Pitfall 5: some races may not have been linked to geofences — report them separately.
  const unlinkedResult = await pool.query<UnlinkedRaceRow>(`
    SELECT r.position_name, r.primary_party, COUNT(rc.id) AS candidate_count
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.candidate_status = 'active'
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND r.office_id IS NULL
    GROUP BY r.id, r.position_name, r.primary_party
    ORDER BY r.position_name, r.primary_party
  `);

  const unlinkedRaces = unlinkedResult.rows;
  console.error(`Unlinked races (not address-scoped): ${unlinkedRaces.length}`);

  // Step 3: DRY_RUN — list addresses and unlinked count, then exit
  if (DRY_RUN) {
    console.log(`Geofence smoke test — 6 test addresses:`);
    for (let i = 0; i < TEST_ADDRESSES.length; i++) {
      const addr = TEST_ADDRESSES[i];
      console.log(
        `  Address ${i + 1} (${addr.label}): ${addr.address} [lat=${addr.lat}, lng=${addr.lng}]`,
      );
    }
    console.log(`Unlinked races (office_id IS NULL): ${unlinkedRaces.length}`);
    await pool.end();
    return;
  }

  // Step 4: Write CSV header for geofence-resolved races
  process.stdout.write('address_label,position_name,primary_party,candidate_name\n');

  // Step 5: For each test address, run Query A — geofence-resolved races
  for (let i = 0; i < TEST_ADDRESSES.length; i++) {
    const addr = TEST_ADDRESSES[i];

    const geofenceResult = await pool.query<GeofenceRow>(
      `
      SELECT r.position_name, r.primary_party, rc.full_name
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.candidate_status = 'active'
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
      WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
        AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
      ORDER BY r.position_name, r.primary_party
      `,
      [addr.lng, addr.lat], // NOTE: ST_MakePoint(longitude, latitude)
    );

    const rows = geofenceResult.rows;

    if (rows.length === 0) {
      // No races resolved — output sentinel row
      process.stdout.write(
        [escapeCsv(addr.label), 'NO_RACES_RESOLVED', '', ''].join(',') + '\n',
      );
    } else {
      for (const row of rows) {
        const line = [
          escapeCsv(addr.label),
          escapeCsv(row.position_name),
          escapeCsv(row.primary_party),
          escapeCsv(row.full_name),
        ].join(',');
        process.stdout.write(line + '\n');
      }
    }

    console.error(`Address ${i + 1} (${addr.label}): ${rows.length} races resolved`);

    // Phase 121 GEO-01/GEO-02 exclusivity assertion — Kirkwood must resolve to
    // exactly one Monroe County Council race (D4 per Monroe County GIS ground truth).
    if (addr.label === 'Bloomington City Center') {
      const councilRaces = rows.filter((r) =>
        typeof r.position_name === 'string' &&
        r.position_name.startsWith('Monroe County Council District'),
      );
      if (councilRaces.length !== 1) {
        console.error(
          `[121-geo] FAIL: Expected exactly 1 MCC Council race for Kirkwood, got ${councilRaces.length}`,
        );
        if (councilRaces.length > 0) {
          console.error(
            `[121-geo]   Races: ${councilRaces.map((r) => r.position_name).join(', ')}`,
          );
        }
        process.exitCode = 2; // non-zero exit signals failing smoke test
      } else {
        console.error(
          `[121-geo] PASS: Kirkwood returns exactly 1 MCC Council race: ${councilRaces[0].position_name}`,
        );
      }
    }
  }

  // Step 6: Output unlinked races section
  process.stdout.write('\nUNLINKED_RACES,position_name,primary_party,candidate_count\n');
  for (const row of unlinkedRaces) {
    const line = [
      'UNLINKED_RACES',
      escapeCsv(row.position_name),
      escapeCsv(row.primary_party),
      escapeCsv(row.candidate_count),
    ].join(',');
    process.stdout.write(line + '\n');
  }

  console.error(`Unlinked races (not address-scoped): ${unlinkedRaces.length}`);
  console.error('Geofence smoke test complete.');
  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});

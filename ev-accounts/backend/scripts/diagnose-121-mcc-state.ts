/**
 * diagnose-121-mcc-state.ts — Read-only diagnostic for Phase 121 (MCC D1→D4 geofence repair).
 *
 * Captures current live state of Monroe County Council (MCC) district wiring in the dev DB
 * by running three read-only SELECT queries and writing results to a CSV file.
 *
 * Queries:
 *   1. BOUNDARIES — Are any sub-district MCC polygons present in geofence_boundaries?
 *   2. OFFICES    — Which district do the 4 MCC office rows currently link to?
 *   3. KIRKWOOD   — How many council races does the Kirkwood point match via ST_Covers?
 *
 * Output:
 *   - Stdout: human-readable summary with grep-able tokens:
 *       [121-diag] boundaries_18105_count=N
 *       [121-diag] mcc_offices_linked_to_18105=N
 *       [121-diag] kirkwood_mcc_count=N
 *   - File: .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/diagnosis.csv
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/diagnose-121-mcc-state.ts
 *
 * IMPORTANT: This script is READ-ONLY. No INSERT, UPDATE, DELETE, ALTER, DROP, or CREATE.
 * Evidence of root cause at phase start — do not modify data.
 *
 * References:
 *   - .planning/phases/121-county-council-d1-d4-geofence-repair/121-RESEARCH.md § Live DB Diagnosis
 *   - ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql §§1a, 2a
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

// Path to the evidence output directory (relative to ev-accounts/backend/scripts/).
// Directory layout: <workspace-root>/ev-accounts/backend/scripts/diagnose-121-mcc-state.ts
//   __dirname = <workspace-root>/ev-accounts/backend/scripts
//   ../../../  = <workspace-root>
//   .planning/ = <workspace-root>/.planning
const EVIDENCE_DIR = path.resolve(
  __dirname,
  '..', '..', '..', '.planning', 'phases',
  '121-county-council-d1-d4-geofence-repair', 'evidence',
);
const CSV_PATH = path.join(EVIDENCE_DIR, 'diagnosis.csv');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface BoundaryRow {
  geo_id: string;
  name: string;
  mtfcc: string;
  state: string;
}

interface OfficeRow {
  title: string;
  geo_id: string;
  district_type: string;
  label: string;
  district_mtfcc: string | null;
}

interface KirkwoodRow {
  position_name: string;
  primary_party: string | null;
  geo_id: string;
  district_type: string;
}

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

function csvRow(...fields: (string | null | undefined)[]): string {
  return fields.map(escapeCsv).join(',');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const lines: string[] = [];

  // =========================================================================
  // Query 1: BOUNDARIES — Are any sub-district MCC polygons present?
  // =========================================================================
  const boundaryResult = await pool.query<BoundaryRow>(`
    SELECT geo_id, name, mtfcc, state
    FROM essentials.geofence_boundaries
    WHERE geo_id LIKE '18105%'
    ORDER BY geo_id
  `);
  const boundaries = boundaryResult.rows;

  lines.push(csvRow('section', 'col1', 'col2', 'col3', 'col4', 'col5'));
  lines.push(csvRow('BOUNDARIES', 'geo_id', 'name', 'mtfcc', 'state', ''));

  if (boundaries.length === 0) {
    lines.push(csvRow('BOUNDARIES', 'NONE', '', '', '', ''));
  } else {
    for (const row of boundaries) {
      lines.push(csvRow('BOUNDARIES', row.geo_id, row.name, row.mtfcc, row.state, ''));
    }
  }

  // Count rows with geo_id starting with '18105' (includes the county-wide '18105' itself)
  const boundaries18105Count = boundaries.length;
  // Count only sub-district rows (those with more than just '18105')
  const subDistrictCount = boundaries.filter((r) => r.geo_id !== '18105').length;

  console.log(`[121-diag] boundaries_18105_count=${boundaries18105Count}`);
  console.log(`[121-diag] sub_district_polygon_count=${subDistrictCount}`);

  // =========================================================================
  // Query 2: OFFICES — Which district do the 4 MCC office rows link to?
  // =========================================================================
  const officeResult = await pool.query<OfficeRow>(`
    SELECT o.title, d.geo_id, d.district_type, d.label, d.mtfcc AS district_mtfcc
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.title LIKE 'Monroe County Council District%'
    ORDER BY o.title
  `);
  const offices = officeResult.rows;

  lines.push(csvRow('OFFICES', 'title', 'geo_id', 'district_type', 'label', 'district_mtfcc'));

  if (offices.length === 0) {
    lines.push(csvRow('OFFICES', 'NONE', '', '', '', ''));
  } else {
    for (const row of offices) {
      lines.push(
        csvRow('OFFICES', row.title, row.geo_id, row.district_type, row.label, row.district_mtfcc),
      );
    }
  }

  const officesLinkedTo18105 = offices.filter((r) => r.geo_id === '18105').length;
  console.log(`[121-diag] mcc_offices_linked_to_18105=${officesLinkedTo18105}`);

  // =========================================================================
  // Query 3: KIRKWOOD — How many council races does the Kirkwood point match?
  // =========================================================================
  // Kirkwood coordinate: 200 W Kirkwood Ave, Bloomington IN 47404
  // lat=39.166646, lng=-86.534947 (pre-geocoded, Census Geocoder April 2026)
  // ST_MakePoint takes (longitude, latitude) — note x=lng, y=lat.
  const kirkwoodResult = await pool.query<KirkwoodRow>(`
    SELECT r.position_name, r.primary_party, d.geo_id, d.district_type
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
    WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
      AND r.position_name LIKE 'Monroe County Council%'
      AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-86.534947, 39.166646), 4326))
    ORDER BY r.position_name
  `);
  const kirkwoodRows = kirkwoodResult.rows;

  lines.push(csvRow('KIRKWOOD', 'position_name', 'primary_party', 'geo_id', 'district_type', ''));

  if (kirkwoodRows.length === 0) {
    lines.push(csvRow('KIRKWOOD', 'NONE', '', '', '', ''));
  } else {
    for (const row of kirkwoodRows) {
      lines.push(
        csvRow(
          'KIRKWOOD',
          row.position_name,
          row.primary_party,
          row.geo_id,
          row.district_type,
          '',
        ),
      );
    }
  }

  const kirkwoodMccCount = kirkwoodRows.length;
  console.log(`[121-diag] kirkwood_mcc_count=${kirkwoodMccCount}`);

  // =========================================================================
  // Write CSV to evidence directory
  // =========================================================================
  fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  fs.writeFileSync(CSV_PATH, lines.join('\n') + '\n', 'utf-8');
  console.log(`[121-diag] CSV written to: ${CSV_PATH}`);

  // =========================================================================
  // Human-readable summary
  // =========================================================================
  console.log('');
  console.log('=== Phase 121 MCC State Diagnosis ===');
  console.log(`Geofence boundaries with geo_id LIKE '18105%': ${boundaries18105Count}`);
  console.log(`  Sub-district polygons (geo_id != '18105'):    ${subDistrictCount}`);
  console.log(`MCC offices linked to county-wide geo_id='18105': ${officesLinkedTo18105}`);
  console.log(`Kirkwood point → MCC Council races matched: ${kirkwoodMccCount}`);
  console.log('');

  if (kirkwoodMccCount === 4) {
    console.log(
      'ROOT CAUSE CONFIRMED: All 4 MCC District races match Kirkwood because all 4 offices',
    );
    console.log(
      "  link to the shared county-wide geo_id='18105' polygon. Sub-district polygons are",
    );
    console.log('  missing. Fix: import 4 per-district polygons (Wave 1) and re-link offices (Wave 2).');
  } else if (kirkwoodMccCount === 1) {
    console.log(
      'HYPOTHESIS DISPROVEN: Kirkwood returns exactly 1 council race — the bug may already be fixed.',
    );
    console.log('  Revise Phase 121 scope before Wave 1 — consult planner.');
  } else if (kirkwoodMccCount === 0) {
    console.log(
      'UNEXPECTED: Kirkwood returns 0 council races — check election date and office linking.',
    );
  } else {
    console.log(
      `UNEXPECTED COUNT (${kirkwoodMccCount}): Review diagnosis CSV for details.`,
    );
  }

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});

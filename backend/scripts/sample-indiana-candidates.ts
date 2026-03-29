/**
 * sample-indiana-candidates.ts
 *
 * Validates that Indiana Secretary of State Excel candidate data maps
 * correctly to the 042_election_schema.sql column types.
 *
 * PURPOSE: Phase 97 data source validation (D-03). Demonstrates feasibility
 * of the Phase 98 import pipeline before committing to the full build.
 *
 * ANTIPARTISAN NOTE: The Indiana SoS Excel file includes a "Political Party"
 * column. This script explicitly skips that column per D-04 (antipartisan policy).
 * Party affiliation is never stored in any Empowered Vote table.
 *
 * Run: cd ev-accounts/backend && npx tsx scripts/sample-indiana-candidates.ts
 */

import * as https from 'https';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// ─── Schema types (matching 042_election_schema.sql) ─────────────────────────

interface ElectionRecord {
  name: string;
  election_date: string;        // ISO date string: YYYY-MM-DD
  election_type: 'primary' | 'general' | 'retention' | 'special';
  jurisdiction_level: 'federal' | 'state' | 'county' | 'city' | 'district';
  state: string;                // char(2): 'IN'
}

interface RaceRecord {
  position_name: string;        // e.g. "Indiana State Senate District 40"
  seats: number;
}

interface CandidateRecord {
  full_name: string;
  last_name: string;
  first_name?: string;
  is_incumbent: boolean;
  candidate_status: 'active' | 'withdrawn' | 'filed';
  source: string;               // 'sos_excel'
  external_id?: string;         // SoS filing ID if available
  // NOTE: NO party field — antipartisan policy (D-04)
}

interface SampleRecord {
  election: ElectionRecord;
  race: RaceRecord;
  candidate: CandidateRecord;
}

// ─── Column mapping (source → schema) ────────────────────────────────────────

/**
 * Indiana SoS Excel columns → 042 schema mapping.
 *
 * ACTUAL columns in the 2026 Primary Excel file (live download confirmed):
 *   Row 0: ["ALL COUNTIES", "2026 PRIMARY ELECTION - 5/5/2026"] (metadata)
 *   Row 1: [] (blank)
 *   Row 2: ["OFFICE", "CANDIDATE NAME", "POLITICAL PARTY", "DISTRICT", "DATE FILED"] (header)
 *   Row 3+: data rows
 *
 * NOTE: No separate "LAST NAME" or "INCUMBENT" columns — last name is extracted
 * from "CANDIDATE NAME" (last word), and incumbent is not in this file.
 * Source Excel uses ALL CAPS column names; normalize to match.
 *
 * Columns EXCLUDED:
 *   POLITICAL PARTY → EXCLUDED per antipartisan policy (D-04)
 */
const COLUMN_MAPPING: Record<string, string | 'EXCLUDED'> = {
  'OFFICE':           'races.position_name',
  'CANDIDATE NAME':   'race_candidates.full_name',
  'DISTRICT':         'races.position_name (suffix — combined with OFFICE)',
  'DATE FILED':       'race_candidates.source metadata (provenance only)',
  'POLITICAL PARTY':  'EXCLUDED',   // Antipartisan policy (D-04)
  // NOTE: No LAST NAME or INCUMBENT columns in this SoS file
  // last_name: extracted from CANDIDATE NAME (last word)
  // is_incumbent: not available in this source — defaults to false
};

// ─── Download helper ──────────────────────────────────────────────────────────

function downloadFile(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        const redirectUrl = response.headers.location!;
        file.close();
        fs.unlinkSync(destPath);
        downloadFile(redirectUrl, destPath).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        file.close();
        reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => { file.close(); resolve(); });
    }).on('error', (err) => {
      file.close();
      fs.unlink(destPath, () => reject(err));
    });
  });
}

// ─── Parse Excel rows → schema records ───────────────────────────────────────

function parseExcelRow(row: Record<string, unknown>, electionName: string, electionDate: string, electionType: 'primary' | 'general'): SampleRecord {
  // OFFICE column → races.position_name (combine with DISTRICT for specificity)
  // The SoS file uses ALL CAPS column names, normalized here.
  const office = String(row['OFFICE'] ?? row['Office'] ?? '').trim();
  const district = String(row['DISTRICT'] ?? row['District'] ?? '').trim();

  // DISTRICT column contains the full district description (e.g. "United States Representative, Eighth District")
  // Use it as the full position name when available; otherwise combine Office + short district number
  let positionName: string;
  if (district && district.length > 4) {
    // Full description available (e.g. "United States Representative, Eighth District")
    positionName = district;
  } else if (district) {
    positionName = `${office} District ${district}`;
  } else {
    positionName = office;
  }

  // CANDIDATE NAME → race_candidates.full_name
  const fullName = String(row['CANDIDATE NAME'] ?? row['Candidate Name'] ?? '').trim();

  // Extract last name from full name (last word) — no separate LAST NAME column in SoS file
  const nameParts = fullName.split(/\s+/);
  const lastName = nameParts.length > 0 ? nameParts[nameParts.length - 1] : '';
  const firstName = nameParts.length > 1 ? nameParts[0] : undefined;

  // INCUMBENT: Not present in this SoS file — defaults to false
  // The SoS filing list does not distinguish incumbents from challengers.
  // Incumbent flag must be set manually or derived by matching politician_id.
  const isIncumbent = false;

  // DATE FILED: Source metadata only (provenance, not a direct schema column)
  // "POLITICAL PARTY" column: EXPLICITLY SKIPPED per antipartisan policy (D-04)

  return {
    election: {
      name: electionName,
      election_date: electionDate,
      election_type: electionType,
      jurisdiction_level: 'state',
      state: 'IN',
    },
    race: {
      position_name: positionName,
      seats: 1,
    },
    candidate: {
      full_name: fullName,
      last_name: lastName,
      first_name: firstName,
      is_incumbent: isIncumbent,
      candidate_status: 'active',
      source: 'sos_excel',
    },
  };
}

// ─── Mock fallback records (when Excel download fails) ───────────────────────

/**
 * Mock records based on confirmed column names from RESEARCH.md.
 * Used when the SoS Excel URL is inaccessible (e.g., filing deadline passed,
 * URL changed, network issue). These demonstrate the expected data shape.
 */
function getMockRecords(): SampleRecord[] {
  // Note: "POLITICAL PARTY" column present in source but EXCLUDED (D-04)
  // Matches actual SoS Excel column names (ALL CAPS, confirmed from live download)
  // DISTRICT contains full district description string (e.g. "United States Representative, Eighth District")
  // No LAST NAME or INCUMBENT columns in the actual SoS Excel file
  const mockRows = [
    { OFFICE: 'US REPRESENTATIVE',        'CANDIDATE NAME': 'Mary Allen',        'POLITICAL PARTY': 'Democratic', DISTRICT: 'United States Representative, Eighth District',       'DATE FILED': 46042 },
    { OFFICE: 'US REPRESENTATIVE',        'CANDIDATE NAME': 'Mario Foradori',    'POLITICAL PARTY': 'Democratic', DISTRICT: 'United States Representative, Eighth District',       'DATE FILED': 46049 },
    { OFFICE: 'US REPRESENTATIVE',        'CANDIDATE NAME': 'Mark Messmer',      'POLITICAL PARTY': 'Republican', DISTRICT: 'United States Representative, Eighth District',       'DATE FILED': 46055 },
    { OFFICE: 'STATE SENATOR',            'CANDIDATE NAME': 'Andrea Hunley',     'POLITICAL PARTY': 'Democratic', DISTRICT: 'State Senate District 40',                            'DATE FILED': 46043 },
    { OFFICE: 'STATE SENATOR',            'CANDIDATE NAME': 'Drew Farrand',      'POLITICAL PARTY': 'Republican', DISTRICT: 'State Senate District 40',                            'DATE FILED': 46050 },
    { OFFICE: 'STATE REPRESENTATIVE',     'CANDIDATE NAME': 'Tonya Pfaff',       'POLITICAL PARTY': 'Democratic', DISTRICT: 'State Representative District 43',                    'DATE FILED': 46044 },
    { OFFICE: 'STATE REPRESENTATIVE',     'CANDIDATE NAME': 'Heath VanNatter',   'POLITICAL PARTY': 'Republican', DISTRICT: 'State Representative District 38',                    'DATE FILED': 46051 },
    { OFFICE: 'STATE REPRESENTATIVE',     'CANDIDATE NAME': 'Matthew Commons',   'POLITICAL PARTY': 'Republican', DISTRICT: 'State Representative District 61',                    'DATE FILED': 46058 },
    { OFFICE: 'STATE SENATOR',            'CANDIDATE NAME': 'Eric Koch',         'POLITICAL PARTY': 'Republican', DISTRICT: 'State Senate District 44',                            'DATE FILED': 46060 },
    { OFFICE: 'STATE REPRESENTATIVE',     'CANDIDATE NAME': 'Jeff Ellington',    'POLITICAL PARTY': 'Republican', DISTRICT: 'State Representative District 62',                    'DATE FILED': 46062 },
  ];

  return mockRows.map(row => parseExcelRow(row, '2026 Indiana Primary', '2026-05-05', 'primary'));
}

// ─── Main execution ───────────────────────────────────────────────────────────

async function main() {
  console.log('=================================================================');
  console.log('Indiana SoS Candidate Data — Schema Validation (Phase 97, D-03)');
  console.log('=================================================================\n');

  // ── Column mapping summary ──────────────────────────────────────────────────
  console.log('## Column Mapping: Indiana SoS Excel → 042 Schema\n');
  console.log('(SoS file uses ALL CAPS column names — confirmed from live Excel download)');
  console.log();
  console.log('Source Column         Schema Target');
  console.log('─────────────────────────────────────────────────────────────────────');
  for (const [source, target] of Object.entries(COLUMN_MAPPING)) {
    const marker = target === 'EXCLUDED' ? '  *** EXCLUDED ***' : '';
    console.log(`  ${source.padEnd(22)}→  ${target}${marker}`);
  }
  console.log();
  console.log('  Note: No LAST NAME or INCUMBENT columns in the SoS file.');
  console.log('        last_name extracted from CANDIDATE NAME (last word).');
  console.log('        is_incumbent not available in filing data — defaults false;');
  console.log('        incumbents identified by matching politician_id at import time.');
  console.log();

  // Highlight the antipartisan exclusion
  console.log('NOTE: Skipping party column per antipartisan policy (D-04)');
  console.log('      "Political Party" column present in source but NEVER stored.');
  console.log();

  // ── Attempt to download Indiana SoS Excel ──────────────────────────────────
  let records: SampleRecord[] = [];
  let dataSource = 'live';

  // Try Primary first (most current for 2026), then General as fallback
  const urls = [
    {
      url: 'https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx',
      electionName: '2026 Indiana Primary',
      electionDate: '2026-05-05',
      electionType: 'primary' as const,
    },
    {
      url: 'https://www.in.gov/sos/elections/files/General-Candidate-List-February-25,-2026.xlsx',
      electionName: '2026 Indiana General Election',
      electionDate: '2026-11-03',
      electionType: 'general' as const,
    },
  ];

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let xlsx: any = null;
  try {
    const xlsxModule = await import('xlsx');
    // Handle both default export and named export (ESM vs CJS interop)
    xlsx = xlsxModule.default ?? xlsxModule;
  } catch {
    console.log('INFO: xlsx package not installed — using mock data.');
    console.log('      Install with: cd ev-accounts/backend && npm install xlsx\n');
  }

  if (xlsx) {
    for (const target of urls) {
      const tmpPath = path.join(os.tmpdir(), `in-sos-candidates-${Date.now()}.xlsx`);
      try {
        console.log(`Downloading: ${target.url}`);
        await downloadFile(target.url, tmpPath);

        const workbook = xlsx.readFile(tmpPath);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        // The SoS Excel file structure:
        //   Row 0: ["ALL COUNTIES", "2026 PRIMARY ELECTION - 5/5/2026"] (metadata)
        //   Row 1: [] (blank)
        //   Row 2: ["OFFICE", "CANDIDATE NAME", "POLITICAL PARTY", "DISTRICT", "DATE FILED"] (header)
        //   Row 3+: data
        // Use defval: '' to avoid undefined for missing cells.
        const rows: Record<string, unknown>[] = xlsx.utils.sheet_to_json(worksheet, {
          range: 2,   // start from row index 2 (the header row)
          defval: '',
        });

        console.log(`  Downloaded: ${rows.length} rows found in "${sheetName}"\n`);

        // Extract first 10 rows
        records = rows.slice(0, 10).map(row =>
          parseExcelRow(row, target.electionName, target.electionDate, target.electionType)
        );

        // Clean up temp file
        fs.unlinkSync(tmpPath);
        dataSource = 'live_sos_excel';
        break;
      } catch (err) {
        console.log(`  Failed: ${(err as Error).message}`);
        // Try next URL
        try { fs.unlinkSync(tmpPath); } catch { /* ignore */ }
      }
    }
  }

  // Fallback to mock data if download failed or xlsx not available
  if (records.length === 0) {
    console.log('Falling back to mock data based on confirmed SoS column names.\n');
    records = getMockRecords();
    dataSource = 'mock_fallback';
  }

  // ── Print sample records ────────────────────────────────────────────────────
  console.log(`## Sample Records (source: ${dataSource})\n`);
  console.log('First 10 rows mapped to 042 schema structure:\n');

  records.forEach((rec, i) => {
    console.log(`--- Record ${i + 1} ---`);
    console.log(JSON.stringify(rec, null, 2));
    console.log();
  });

  // ── Schema fit assessment ───────────────────────────────────────────────────
  console.log('=================================================================');
  console.log('## Schema Fit Assessment');
  console.log('=================================================================\n');

  const issues: string[] = [];
  const confirmations: string[] = [];

  // Check: all records have required fields
  const missingFullName = records.filter(r => !r.candidate.full_name).length;
  const missingPosition = records.filter(r => !r.race.position_name).length;
  const missingLastName = records.filter(r => !r.candidate.last_name).length;

  if (missingFullName > 0) {
    issues.push(`${missingFullName} records missing full_name`);
  } else {
    confirmations.push('full_name: all records populated');
  }

  if (missingPosition > 0) {
    issues.push(`${missingPosition} records missing position_name`);
  } else {
    confirmations.push('position_name: all records populated (Office + District combined)');
  }

  if (missingLastName > 0) {
    issues.push(`${missingLastName} records missing last_name`);
  } else {
    confirmations.push('last_name: all records populated');
  }

  // Check election_date format (must be ISO date for PostgreSQL date type)
  const validDates = records.every(r => /^\d{4}-\d{2}-\d{2}$/.test(r.election.election_date));
  if (validDates) {
    confirmations.push('election_date: ISO format (YYYY-MM-DD) — compatible with PostgreSQL date type');
  } else {
    issues.push('election_date: NOT in ISO format — incompatible with PostgreSQL date type');
  }

  // Check candidate_status enum
  const validStatuses = ['active', 'withdrawn', 'filed'];
  const invalidStatus = records.filter(r => !validStatuses.includes(r.candidate.candidate_status)).length;
  if (invalidStatus > 0) {
    issues.push(`${invalidStatus} records with invalid candidate_status`);
  } else {
    confirmations.push('candidate_status: all values in enum (active | withdrawn | filed)');
  }

  // Check election_type enum
  const validTypes = ['primary', 'general', 'retention', 'special'];
  const invalidType = records.filter(r => !validTypes.includes(r.election.election_type)).length;
  if (invalidType > 0) {
    issues.push(`${invalidType} records with invalid election_type`);
  } else {
    confirmations.push('election_type: all values in enum (primary | general | retention | special)');
  }

  // Confirm no party data in output
  const hasPartyData = records.some(r => {
    const str = JSON.stringify(r);
    return /party|partisan/i.test(str);
  });
  if (hasPartyData) {
    issues.push('CRITICAL: party data found in output — antipartisan violation!');
  } else {
    confirmations.push('party_name: CONFIRMED absent from all output records (antipartisan policy enforced)');
  }

  console.log('Confirmations:');
  confirmations.forEach(c => console.log(`  ✓ ${c}`));

  if (issues.length > 0) {
    console.log('\nIssues:');
    issues.forEach(i => console.log(`  ✗ ${i}`));
  } else {
    console.log('\nResult: CLEAN FIT — Indiana SoS data maps to 042 schema without schema changes needed.');
  }

  // ── Excluded columns summary ────────────────────────────────────────────────
  console.log('\n─────────────────────────────────────────────────────────────────────');
  console.log('## Excluded Columns\n');
  const excluded = Object.entries(COLUMN_MAPPING).filter(([, v]) => v === 'EXCLUDED');
  excluded.forEach(([col]) => {
    console.log(`  ${col}: EXCLUDED — antipartisan policy (D-04)`);
    console.log('  "Skipping party column per antipartisan policy (D-04)"');
  });

  // ── Unmapped columns (for Phase 98 awareness) ───────────────────────────────
  console.log('\n─────────────────────────────────────────────────────────────────────');
  console.log('## Unmapped / Metadata Columns (no schema target, Phase 98 note)\n');
  console.log('  Date Filed: Stored as provenance metadata only — not a direct schema column.');
  console.log('              Could be stored in source text field or external_id for audit trail.');

  console.log('\n=================================================================');
  console.log('Sample parsing complete. See DATA_SOURCES.md for full documentation.');
  console.log('=================================================================\n');
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});

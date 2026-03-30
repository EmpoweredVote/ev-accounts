/**
 * importElectionData.ts — Election data import CLI
 *
 * Imports upcoming election, race, and candidate records into:
 *   essentials.elections, essentials.races, essentials.race_candidates
 *
 * Sources:
 *   --source indiana-sos   Indiana Secretary of State Excel (state + federal races for Monroe County)
 *   --source la-roster     LA County Public Officials HTML (incumbent roster for 2026 primary)
 *
 * Usage:
 *   npx tsx scripts/importElectionData.ts --source indiana-sos [--election-type primary|general]
 *   npx tsx scripts/importElectionData.ts --source la-roster
 *   npx tsx scripts/importElectionData.ts --source indiana-sos --commit
 *
 * Options:
 *   --source <name>             Data source handler: indiana-sos | la-roster (required)
 *   --election-type <type>      primary | general (indiana-sos only, default: primary)
 *   --commit                    Write to database (default: dry-run preview only)
 *
 * Evolved from: ev-accounts/backend/scripts/sample-indiana-candidates.ts (Phase 97 scaffold)
 * See: .planning/phases/98-election-data-import/98-RESEARCH.md for architecture decisions
 */

// ANTIPARTISAN POLICY: Party column present in source data but NEVER stored on candidates.
// Empowered Vote derives political alignment from compass answers, legislative votes,
// and sourced quotes. Party labels on individual candidates are partisan signals that
// undermine voter independence. See 042_election_schema.sql for full rationale.
//
// For PRIMARY elections: party is stored on races.primary_party (the structural
// container for the race), not on race_candidates. This is required for closed/
// semi-closed primary states where voters need to know which primary they can vote in.
// For GENERAL elections: primary_party is NULL.

import * as https from 'https';
import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';
import pg from 'pg';
import { parse as parseHtml } from 'node-html-parser';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { Pool } = pg;

// =============================================================================
// Types — matching 042_election_schema.sql
// =============================================================================

interface ElectionRecord {
  name: string;
  election_date: string;        // ISO date: YYYY-MM-DD
  election_type: 'primary' | 'general' | 'retention' | 'special';
  jurisdiction_level: 'federal' | 'state' | 'county' | 'city' | 'district';
  state: string;                // char(2): 'IN' | 'CA'
}

interface RaceRecord {
  position_name: string;
  primary_party: string | null; // primary elections only — ANTIPARTISAN: never on candidates
  seats: number;
  office_id?: string | null;    // resolved via office lookup; nullable
}

interface CandidateRecord {
  full_name: string;
  last_name: string;
  first_name?: string;
  is_incumbent: boolean;
  candidate_status: 'active' | 'withdrawn' | 'filed';
  source: string;
  external_id?: string;
  politician_id?: string | null;
  match_type?: 'incumbent' | 'cross-office' | 'ambiguous' | 'none';
  // NOTE: NO party field — ANTIPARTISAN POLICY (D-04, see comment block at top of file)
}

interface ParsedRace {
  race: RaceRecord;
  candidates: CandidateRecord[];
}

interface ParsedElection {
  election: ElectionRecord;
  races: ParsedRace[];
}

// =============================================================================
// CLI argument parsing
// =============================================================================

const args = process.argv.slice(2);

function getArgValue(flag: string): string | undefined {
  const idx = args.indexOf(flag);
  if (idx === -1) return undefined;
  const val = args[idx + 1];
  // Don't return another flag as a value
  if (!val || val.startsWith('--')) return undefined;
  return val;
}

const sourceFlag = getArgValue('--source');
const electionTypeArg = getArgValue('--election-type');
const electionTypeFlag = (electionTypeArg === 'general' ? 'general' : 'primary') as 'primary' | 'general';
const isCommit = args.includes('--commit');
const isDryRun = !isCommit;

if (!sourceFlag || !['indiana-sos', 'la-roster'].includes(sourceFlag)) {
  console.error('ERROR: --source is required. Use --source indiana-sos or --source la-roster');
  process.exit(1);
}

// =============================================================================
// DB Pool (standalone pattern — same as importBudgetHierarchy.ts)
// =============================================================================

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// =============================================================================
// Download helper — supports HTTP redirect following (from sample-indiana-candidates.ts)
// =============================================================================

function downloadFile(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (response) => {
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

function fetchUrl(url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        const redirectUrl = response.headers.location!;
        fetchUrl(redirectUrl).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode} for ${url}`));
        return;
      }
      let body = '';
      response.on('data', (chunk: Buffer) => { body += chunk.toString(); });
      response.on('end', () => resolve(body));
    }).on('error', reject);
  });
}

// =============================================================================
// Monroe County district filter (D-11)
// Only include races for districts that cover Bloomington/Monroe County IN
// =============================================================================

// Monroe County district identifiers (D-11)
// DISTRICT column format varies:
//   US House: "United States Representative, Ninth District"
//   State Senate: "State Senator, District 40"
//   State House: "State Representative, District 060" (zero-padded)
const MONROE_COUNTY_DISTRICTS = [
  'ninth district',   // IN-09 US House (contains Bloomington)
  'district 40',      // State Senate District 40 (Monroe County) — matches "District 40"
  'district 60',      // State House District 60 — matches "District 060" and "District 60"
  'district 61',      // State House District 61 — matches "District 061" and "District 61"
  'district 62',      // State House District 62 — matches "District 062" and "District 62"
  'district 060',     // Zero-padded form used in state rep rows
  'district 061',
  'district 062',
];

// Offices to include: US Representative, State Senator, State Representative
// Exclude: County Convention Delegates, precinct committeemen, and other internal party races
const ALLOWED_OFFICES = [
  'us representative',
  'state senator',
  'state representative',
  'united states representative',
  'united states senator',
];

function isMonroeCountyDistrict(districtText: string, officeText: string): boolean {
  const lowerDistrict = districtText.toLowerCase();
  const lowerOffice = officeText.toLowerCase();

  // Must match a Monroe County district
  const districtMatch = MONROE_COUNTY_DISTRICTS.some(d => lowerDistrict.includes(d));
  if (!districtMatch) return false;

  // Must be a legislative/congressional office (not convention delegates, precinct committeemen, etc.)
  const officeMatch = ALLOWED_OFFICES.some(o => lowerOffice.includes(o));
  return officeMatch;
}

// =============================================================================
// Excel row parser — from sample-indiana-candidates.ts (preserved + extended)
// =============================================================================

function parseExcelRow(
  row: Record<string, unknown>,
  electionType: 'primary' | 'general'
): { positionName: string; primaryParty: string | null; fullName: string; lastName: string; firstName?: string } {
  const office = String(row['OFFICE'] ?? row['Office'] ?? '').trim();
  const district = String(row['DISTRICT'] ?? row['District'] ?? '').trim();

  // ANTIPARTISAN POLICY: party is stored on the RACE, never on the CANDIDATE
  // For primary elections: races.primary_party captures the party-scoped primary container
  // For general elections: primary_party is NULL
  const rawParty = String(row['POLITICAL PARTY'] ?? row['Political Party'] ?? '').trim();
  const primaryParty = electionType === 'primary' && rawParty ? rawParty : null;
  // DO NOT pass rawParty to the candidate record — antipartisan policy enforced here

  // Position name: use full DISTRICT description when available
  let positionName: string;
  if (district && district.length > 4) {
    positionName = district;
  } else if (district) {
    positionName = `${office} District ${district}`;
  } else {
    positionName = office;
  }

  const fullName = String(row['CANDIDATE NAME'] ?? row['Candidate Name'] ?? '').trim();
  const nameParts = fullName.split(/\s+/);
  const lastName = nameParts.length > 0 ? nameParts[nameParts.length - 1] : '';
  const firstName = nameParts.length > 1 ? nameParts[0] : undefined;

  return { positionName, primaryParty, fullName, lastName, firstName };
}

// =============================================================================
// Two-pass incumbent matching (D-05, D-06, D-07)
// =============================================================================

interface MatchResult {
  politicianId: string | null;
  isIncumbent: boolean;
  matchType: 'incumbent' | 'cross-office' | 'ambiguous' | 'none';
}

async function matchCandidate(
  pool: pg.Pool,
  candidateFullName: string,
  raceOfficeId: string | null | undefined
): Promise<MatchResult> {
  // Pass 1 — Office-based match: find the current politician holding this office
  if (raceOfficeId) {
    const officeMatch = await pool.query<{ id: string; full_name: string }>(
      `SELECT p.id, p.full_name
       FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
       WHERE o.id = $1
         AND p.is_active = true`,
      [raceOfficeId]
    );

    if (
      officeMatch.rows.length > 0 &&
      officeMatch.rows[0].full_name.toLowerCase() === candidateFullName.toLowerCase()
    ) {
      return {
        politicianId: officeMatch.rows[0].id,
        isIncumbent: true,
        matchType: 'incumbent',
      };
    }
  }

  // Pass 2 — Name-based match: cross-office filer or challenger with existing profile
  const nameMatch = await pool.query<{ id: string; full_name: string }>(
    `SELECT id, full_name
     FROM essentials.politicians
     WHERE LOWER(full_name) = LOWER($1)
       AND is_active = true
     LIMIT 2`,
    [candidateFullName]
  );

  if (nameMatch.rows.length === 1) {
    // Exactly one match → cross-office filer or known challenger (D-07)
    return {
      politicianId: nameMatch.rows[0].id,
      isIncumbent: false,
      matchType: 'cross-office',
    };
  }

  if (nameMatch.rows.length > 1) {
    // Ambiguous — flag for manual review (D-06)
    console.warn(
      `  WARNING: POSSIBLE MATCH -- needs verification: "${candidateFullName}" matches ${nameMatch.rows.length} politicians`
    );
    return {
      politicianId: null,
      isIncumbent: false,
      matchType: 'ambiguous',
    };
  }

  return { politicianId: null, isIncumbent: false, matchType: 'none' };
}

// =============================================================================
// Office ID lookup for races — attempts to resolve essentials.offices by label
// =============================================================================

async function lookupOfficeId(
  pool: pg.Pool,
  positionName: string,
  state: string
): Promise<string | null> {
  // Extract a simplified district label for matching
  // e.g. "United States Representative, Ninth District" → "Ninth District"
  //      "State Senate District 40" → "District 40"
  const districtMatch = positionName.match(/district\s+\d+|ninth\s+district|[\w]+\s+district/i);
  if (!districtMatch) return null;

  const districtLabel = districtMatch[0];

  const result = await pool.query<{ id: string }>(
    `SELECT o.id
     FROM essentials.offices o
     JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.state = $1
       AND (
         o.title ILIKE '%' || $2 || '%'
         OR d.label ILIKE '%' || $2 || '%'
       )
     LIMIT 1`,
    [state, districtLabel]
  );

  return result.rows[0]?.id ?? null;
}

// =============================================================================
// Upsert helpers (D-03 — idempotent re-runs)
// =============================================================================

async function upsertElection(
  pool: pg.Pool,
  election: ElectionRecord,
  client: pg.PoolClient
): Promise<string> {
  // ON CONFLICT on (name, election_date, state) — constraint from migration 044
  const result = await client.query<{ id: string }>(
    `INSERT INTO essentials.elections
       (name, election_date, election_type, jurisdiction_level, state)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (name, election_date, state) DO UPDATE
       SET updated_at = now()
     RETURNING id`,
    [
      election.name,
      election.election_date,
      election.election_type,
      election.jurisdiction_level,
      election.state,
    ]
  );
  return result.rows[0].id;
}

async function upsertRace(
  pool: pg.Pool,
  electionId: string,
  race: RaceRecord,
  client: pg.PoolClient
): Promise<string> {
  // Two-branch upsert to handle PostgreSQL NULL behavior in UNIQUE constraints:
  //
  // Branch A (primary_party NOT NULL): Use ON CONFLICT ON CONSTRAINT to match the
  //   races_election_position_party_unique constraint from migration 044.
  //
  // Branch B (primary_party IS NULL): PostgreSQL treats NULLs as distinct in UNIQUE
  //   constraints, so ON CONFLICT never fires for NULL. Use explicit SELECT-then-INSERT/UPDATE
  //   pattern targeting the partial unique index (idx_races_election_position_no_party).
  //   This is idempotent and race-safe within a serializable transaction.

  if (race.primary_party !== null) {
    // Branch A: named constraint ON CONFLICT works for non-null primary_party
    const result = await client.query<{ id: string }>(
      `INSERT INTO essentials.races
         (election_id, office_id, position_name, primary_party, seats)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT ON CONSTRAINT races_election_position_party_unique DO UPDATE
         SET office_id = COALESCE(EXCLUDED.office_id, essentials.races.office_id),
             updated_at = now()
       RETURNING id`,
      [
        electionId,
        race.office_id ?? null,
        race.position_name,
        race.primary_party,
        race.seats,
      ]
    );
    return result.rows[0].id;
  }

  // Branch B: primary_party IS NULL — general/retention/special races
  // SELECT first; if found, UPDATE; if not, INSERT. Targets the partial unique index.
  const existing = await client.query<{ id: string }>(
    `SELECT id FROM essentials.races
     WHERE election_id = $1 AND position_name = $2 AND primary_party IS NULL`,
    [electionId, race.position_name]
  );

  if (existing.rows.length > 0) {
    // UPDATE existing row
    await client.query(
      `UPDATE essentials.races
       SET office_id = COALESCE($1, office_id),
           updated_at = now()
       WHERE id = $2`,
      [race.office_id ?? null, existing.rows[0].id]
    );
    return existing.rows[0].id;
  }

  // INSERT new row
  const inserted = await client.query<{ id: string }>(
    `INSERT INTO essentials.races
       (election_id, office_id, position_name, primary_party, seats)
     VALUES ($1, $2, $3, NULL, $4)
     RETURNING id`,
    [
      electionId,
      race.office_id ?? null,
      race.position_name,
      race.seats,
    ]
  );
  return inserted.rows[0].id;
}

async function upsertCandidate(
  pool: pg.Pool,
  raceId: string,
  candidate: CandidateRecord,
  client: pg.PoolClient
): Promise<void> {
  // Upsert by external_id (partial unique index where external_id IS NOT NULL)
  // Preserve manual edits: photo_url and politician_id NOT updated on conflict
  await client.query(
    `INSERT INTO essentials.race_candidates
       (race_id, full_name, first_name, last_name,
        is_incumbent, candidate_status, source, external_id,
        last_verified_at, politician_id)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now(), $9)
     ON CONFLICT (external_id) WHERE external_id IS NOT NULL
     DO UPDATE SET
       full_name        = EXCLUDED.full_name,
       is_incumbent     = EXCLUDED.is_incumbent,
       candidate_status = EXCLUDED.candidate_status,
       last_verified_at = now()
     -- NOTE: photo_url and politician_id NOT updated on conflict to preserve manual edits`,
    [
      raceId,
      candidate.full_name,
      candidate.first_name ?? null,
      candidate.last_name,
      candidate.is_incumbent,
      candidate.candidate_status,
      candidate.source,
      candidate.external_id ?? null,
      candidate.politician_id ?? null,
    ]
  );
}

// =============================================================================
// External ID generation
// =============================================================================

function makeExternalId(prefix: string, fullName: string): string {
  const normalized = fullName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  return `${prefix}-${normalized}`;
}

// =============================================================================
// Dry-run summary printer
// =============================================================================

function printDryRunSummary(
  data: ParsedElection,
  stats: {
    incumbents: number;
    crossOffice: number;
    ambiguous: number;
    unmatched: number;
    officesNotFound: number;
    partyRowsSkipped: number;
  }
): void {
  const { election, races } = data;

  console.log('\n=== DRY RUN (pass --commit to write to DB) ===\n');
  console.log(`Election: ${election.name} (${election.election_date}, ${election.election_type}, ${election.state})`);

  for (const { race, candidates } of races) {
    const partyLabel = race.primary_party ? ` [${race.primary_party} Primary]` : '';
    console.log(`\nRace: ${race.position_name}${partyLabel}`);
    console.log(`  Office ID: ${race.office_id ?? 'UNMATCHED'}`);
    console.log('  Candidates:');

    for (const c of candidates) {
      const matchStr = `match=${c.match_type ?? 'none'}`;
      const pidStr = c.politician_id ? ` politician_id=${c.politician_id}` : '';
      const incumbentStr = c.is_incumbent ? ' [INCUMBENT]' : '';
      console.log(`    - ${c.full_name} [${c.candidate_status.toUpperCase()}]${incumbentStr} ${matchStr}${pidStr} external_id=${c.external_id ?? 'none'}`);
    }
  }

  const totalCandidates = races.reduce((sum, r) => sum + r.candidates.length, 0);
  console.log('\nSummary:');
  console.log(`  Elections: 1`);
  console.log(`  Races: ${races.length}`);
  console.log(`  Candidates: ${totalCandidates}`);
  console.log(`  Incumbents matched: ${stats.incumbents}`);
  console.log(`  Cross-office matches: ${stats.crossOffice}`);
  console.log(`  Ambiguous (needs review): ${stats.ambiguous}`);
  console.log(`  Unmatched (new challengers): ${stats.unmatched}`);
  console.log(`  Offices not found: ${stats.officesNotFound}`);
  console.log(`  Skipped party column per antipartisan policy: ${stats.partyRowsSkipped} rows`);
}

// =============================================================================
// Indiana SoS source handler (--source indiana-sos)
// =============================================================================

async function handleIndianaSos(
  electionType: 'primary' | 'general'
): Promise<ParsedElection> {
  const SOS_URLS = {
    primary: {
      url: 'https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx',
      electionName: '2026 Indiana Primary',
      electionDate: '2026-05-05',
    },
    general: {
      url: 'https://www.in.gov/sos/elections/files/General-Candidate-List-February-25,-2026.xlsx',
      electionName: '2026 Indiana General Election',
      electionDate: '2026-11-03',
    },
  };

  const target = SOS_URLS[electionType];

  console.log(`\n[Indiana SoS] Downloading ${electionType} candidate list...`);
  console.log(`  URL: ${target.url}`);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let xlsx: any = null;
  try {
    const xlsxModule = await import('xlsx');
    xlsx = xlsxModule.default ?? xlsxModule;
  } catch {
    console.error('ERROR: xlsx package not found. Install with: npm install --save-dev xlsx');
    process.exit(1);
  }

  let rows: Record<string, unknown>[] = [];
  const tmpPath = path.join(os.tmpdir(), `in-sos-candidates-${Date.now()}.xlsx`);

  try {
    await downloadFile(target.url, tmpPath);
    const workbook = xlsx.readFile(tmpPath);
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];

    // SoS Excel structure:
    //   Row 0: ["ALL COUNTIES", "2026 PRIMARY ELECTION..."] (metadata)
    //   Row 1: [] (blank)
    //   Row 2: ["OFFICE", "CANDIDATE NAME", "POLITICAL PARTY", "DISTRICT", "DATE FILED"] (header)
    //   Row 3+: data
    rows = xlsx.utils.sheet_to_json(worksheet, { range: 2, defval: '' });
    console.log(`  Downloaded: ${rows.length} total rows in the state`);
    fs.unlinkSync(tmpPath);
  } catch (err) {
    try { fs.unlinkSync(tmpPath); } catch { /* ignore */ }
    console.error(`\nERROR: Failed to download Indiana SoS Excel: ${(err as Error).message}`);
    console.error('       The SoS URL may have changed after the filing deadline.');
    console.error('       Check: https://www.in.gov/sos/elections/voter-information/candidate-information/');
    process.exit(1);
  }

  // Apply Monroe County district filter (D-11)
  // Filter by both district (coverage area) and office type (legislative races only)
  const filteredRows = rows.filter(row => {
    const district = String(row['DISTRICT'] ?? '').trim();
    const office = String(row['OFFICE'] ?? '').trim();
    return isMonroeCountyDistrict(district, office);
  });

  console.log(`  Monroe County filter: ${filteredRows.length} rows (from ${rows.length} statewide)`);

  // Count party rows skipped per ANTIPARTISAN POLICY
  const partyRowsSkipped = filteredRows.filter(row => String(row['POLITICAL PARTY'] ?? '').trim()).length;

  // Group by (positionName + primaryParty) to create one race per group
  const raceMap = new Map<string, { race: RaceRecord; rawCandidates: Array<{ row: Record<string, unknown> }> }>();

  for (const row of filteredRows) {
    const parsed = parseExcelRow(row, electionType);
    if (!parsed.fullName) continue; // skip empty rows

    const raceKey = `${parsed.positionName}|||${parsed.primaryParty ?? ''}`;
    if (!raceMap.has(raceKey)) {
      // Determine jurisdiction level
      let jurisdictionLevel: 'federal' | 'state' = 'state';
      const positionLower = parsed.positionName.toLowerCase();
      if (positionLower.includes('united states representative') || positionLower.includes('united states senator')) {
        jurisdictionLevel = 'federal';
      }

      raceMap.set(raceKey, {
        race: {
          position_name: parsed.positionName,
          primary_party: parsed.primaryParty,
          seats: 1,
          office_id: null,
        },
        rawCandidates: [],
      });
      // Store jurisdiction level for use at election level
      void jurisdictionLevel; // election-level jurisdiction is 'state' for Indiana (covers both federal + state races)
    }
    raceMap.get(raceKey)!.rawCandidates.push({ row });
  }

  // Build election record
  const electionRecord: ElectionRecord = {
    name: target.electionName,
    election_date: target.electionDate,
    election_type: electionType,
    jurisdiction_level: 'state',
    state: 'IN',
  };

  // Perform office ID lookups and candidate matching
  const parsedRaces: ParsedRace[] = [];
  let incumbentCount = 0;
  let crossOfficeCount = 0;
  let ambiguousCount = 0;
  let unmatchedCount = 0;
  let officesNotFound = 0;

  for (const [, { race, rawCandidates }] of raceMap) {
    // Attempt office lookup
    const officeId = await lookupOfficeId(pool, race.position_name, 'IN');
    if (!officeId) officesNotFound++;
    race.office_id = officeId;

    const candidates: CandidateRecord[] = [];

    for (const { row } of rawCandidates) {
      const parsed = parseExcelRow(row, electionType);
      const externalIdPrefix = electionType === 'primary' ? 'sos-in-2026p' : 'sos-in-2026g';
      const externalId = makeExternalId(externalIdPrefix, parsed.fullName);

      // Two-pass incumbent matching
      const match = await matchCandidate(pool, parsed.fullName, officeId);

      if (match.matchType === 'incumbent') incumbentCount++;
      else if (match.matchType === 'cross-office') crossOfficeCount++;
      else if (match.matchType === 'ambiguous') ambiguousCount++;
      else unmatchedCount++;

      candidates.push({
        full_name: parsed.fullName,
        last_name: parsed.lastName,
        first_name: parsed.firstName,
        is_incumbent: match.isIncumbent,
        candidate_status: 'active',
        source: 'sos_excel',
        external_id: externalId,
        politician_id: match.politicianId,
        match_type: match.matchType,
      });
    }

    parsedRaces.push({ race, candidates });
  }

  printDryRunSummary(
    { election: electionRecord, races: parsedRaces },
    {
      incumbents: incumbentCount,
      crossOffice: crossOfficeCount,
      ambiguous: ambiguousCount,
      unmatched: unmatchedCount,
      officesNotFound,
      partyRowsSkipped,
    }
  );

  return { election: electionRecord, races: parsedRaces };
}

// =============================================================================
// LA County source handler (--source la-roster, D-08, D-10)
// =============================================================================

async function handleLaRoster(): Promise<ParsedElection> {
  // Structured HTML page confirmed in RESEARCH.md (Pitfall 2)
  // Fetch the county offices page — lists all 5 supervisors with district info
  const LA_COUNTY_URL =
    'https://lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices';

  console.log('\n[LA County] Fetching Public Officials roster...');
  console.log(`  URL: ${LA_COUNTY_URL}`);

  let htmlBody = '';
  try {
    htmlBody = await fetchUrl(LA_COUNTY_URL);
  } catch (err) {
    console.error(`\nERROR: Failed to fetch LA County officials page: ${(err as Error).message}`);
    console.error('  Suggestion: Enter officials manually via the staging data-entry tool (/api/staging/*)');
    console.error('  Known LA County incumbents (as of 2026-03-29):');
    console.error('    Board of Supervisors: Hilda Solis (D1), Holly Mitchell (D2), Lindsey Horvath (D3), Janice Hahn (D4), Kathryn Barger (D5)');
    console.error('    Sheriff: Robert Luna');
    console.error('    DA: Nathan Hochman');
    console.error('    Assessor: Jeff Prang');
    process.exit(1);
  }

  console.log(`  Fetched: ${htmlBody.length} bytes`);

  // Parse HTML with node-html-parser
  const root = parseHtml(htmlBody);

  // Extract official names and positions from the page
  // The lavote.gov county-offices page lists officials with patterns like:
  //   "District 1 - Hilda L. Solis" or similar structured text
  // We look broadly for any text matching supervisor district patterns
  const candidates: Array<{ name: string; position: string }> = [];

  // Strategy 1: Look for district-pattern text in the page
  const allText = root.textContent;
  const supervisorPatterns = [
    /District\s+(\d+)\s*[-–]\s*([A-Z][a-z]+(?:\s+[A-Z]\.?)?\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/g,
  ];

  for (const pattern of supervisorPatterns) {
    let match;
    pattern.lastIndex = 0;
    while ((match = pattern.exec(allText)) !== null) {
      const distNum = match[1];
      const name = match[2].trim();
      if (name && distNum) {
        candidates.push({
          name,
          position: `Board of Supervisors District ${distNum}`,
        });
      }
    }
  }

  // Strategy 2: Parse structured list items or table cells
  if (candidates.length === 0) {
    // Try to find names in list items or paragraphs mentioning "Supervisor"
    const paragraphs = root.querySelectorAll('p, li, td, h2, h3, h4');
    for (const el of paragraphs) {
      const text = el.text.trim();
      const districtMatch = text.match(/District\s+(\d+)/i);
      if (districtMatch) {
        // Look for a name following the district reference
        const nameMatch = text.match(/[-–:]\s*([A-Z][a-z]+(?:\s+[A-Z]\.?)?\s+[A-Z][a-z]+)/);
        if (nameMatch) {
          candidates.push({
            name: nameMatch[1].trim(),
            position: `Board of Supervisors District ${districtMatch[1]}`,
          });
        }
      }
    }
  }

  // Fallback: use known incumbents if scrape yields 0 results (Pitfall 2 fallback)
  if (candidates.length === 0) {
    console.warn('  WARNING: HTML parse returned 0 officials. Using known incumbents as fallback.');
    console.warn('           The page structure may have changed. Verify against lavote.gov manually.');
    const KNOWN_INCUMBENTS = [
      { name: 'Hilda L. Solis', position: 'Board of Supervisors District 1' },
      { name: 'Holly J. Mitchell', position: 'Board of Supervisors District 2' },
      { name: 'Lindsey P. Horvath', position: 'Board of Supervisors District 3' },
      { name: 'Janice Hahn', position: 'Board of Supervisors District 4' },
      { name: 'Kathryn Barger', position: 'Board of Supervisors District 5' },
    ];
    candidates.push(...KNOWN_INCUMBENTS);
  }

  // Deduplicate by name
  const seen = new Set<string>();
  const uniqueCandidates = candidates.filter(c => {
    if (seen.has(c.name)) return false;
    seen.add(c.name);
    return true;
  });

  console.log(`  Found ${uniqueCandidates.length} officials`);

  // LA County primary election record
  const electionRecord: ElectionRecord = {
    name: '2026 LA County Primary',
    election_date: '2026-06-02',
    election_type: 'primary',
    jurisdiction_level: 'county',
    state: 'CA',
  };

  // Build races and candidates
  const parsedRaces: ParsedRace[] = [];
  let incumbentCount = 0;
  let crossOfficeCount = 0;
  let ambiguousCount = 0;
  let unmatchedCount = 0;
  let officesNotFound = 0;

  for (const official of uniqueCandidates) {
    const officeId = await lookupOfficeId(pool, official.position, 'CA');
    if (!officeId) officesNotFound++;

    const match = await matchCandidate(pool, official.name, officeId);
    if (match.matchType === 'incumbent') incumbentCount++;
    else if (match.matchType === 'cross-office') crossOfficeCount++;
    else if (match.matchType === 'ambiguous') ambiguousCount++;
    else unmatchedCount++;

    const externalId = makeExternalId('la-roster-2026', official.name);

    const candidate: CandidateRecord = {
      full_name: official.name,
      last_name: official.name.split(/\s+/).pop() ?? '',
      first_name: official.name.split(/\s+/)[0],
      is_incumbent: true, // LA roster is incumbents-only per D-08
      candidate_status: 'active',
      source: 'la_roster',
      external_id: externalId,
      politician_id: match.politicianId,
      match_type: match.matchType,
    };

    parsedRaces.push({
      race: {
        position_name: official.position,
        primary_party: null, // ANTIPARTISAN: no party on LA County races at this stage
        seats: 1,
        office_id: officeId,
      },
      candidates: [candidate],
    });
  }

  printDryRunSummary(
    { election: electionRecord, races: parsedRaces },
    {
      incumbents: incumbentCount,
      crossOffice: crossOfficeCount,
      ambiguous: ambiguousCount,
      unmatched: unmatchedCount,
      officesNotFound,
      partyRowsSkipped: 0, // LA roster HTML does not expose party data
    }
  );

  return { election: electionRecord, races: parsedRaces };
}

// =============================================================================
// Commit to database (--commit mode)
// =============================================================================

async function commitToDatabase(data: ParsedElection): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const electionId = await upsertElection(pool, data.election, client);
    console.log(`\n[COMMIT] Election upserted: ${electionId}`);

    let raceCount = 0;
    let candidateCount = 0;

    for (const { race, candidates } of data.races) {
      const raceId = await upsertRace(pool, electionId, race, client);
      raceCount++;

      for (const candidate of candidates) {
        await upsertCandidate(pool, raceId, candidate, client);
        candidateCount++;
      }
    }

    await client.query('COMMIT');
    console.log(`[COMMIT] Done. Upserted ${raceCount} races, ${candidateCount} candidates.`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[COMMIT] ERROR — transaction rolled back:', (err as Error).message);
    throw err;
  } finally {
    client.release();
  }
}

// =============================================================================
// Main entry point
// =============================================================================

async function main(): Promise<void> {
  console.log('=================================================================');
  console.log('importElectionData.ts — Election Data Import CLI (Phase 98)');
  console.log('=================================================================');
  console.log(`Source:        ${sourceFlag}`);
  console.log(`Election type: ${electionTypeFlag}`);
  console.log(`Mode:          ${isDryRun ? 'DRY RUN (no DB writes)' : 'COMMIT (will write to DB)'}`);

  let parsedData: ParsedElection;

  if (sourceFlag === 'indiana-sos') {
    parsedData = await handleIndianaSos(electionTypeFlag);
  } else {
    // la-roster
    parsedData = await handleLaRoster();
  }

  if (!isDryRun) {
    console.log('\nWriting to database...');
    await commitToDatabase(parsedData);
  } else {
    console.log('\n[DRY RUN] No changes written to DB. Rerun with --commit to apply.');
  }

  await pool.end();
}

main().catch(err => {
  console.error('\nFatal error:', (err as Error).message);
  pool.end().catch(() => undefined);
  process.exit(1);
});

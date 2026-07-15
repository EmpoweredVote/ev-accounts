/**
 * campaignFinanceService — transparent_motivations schema DB queries for campaign finance.
 *
 * WHY THIS FILE EXISTS:
 * The transparent_motivations schema is NOT in the PostgREST exposed schema list.
 * ALL reads must use pool.query() (direct postgres).
 *
 * Purpose: Public API for campaign finance data — summary + contributions endpoints.
 * Ported from Go: EV-Backend/internal/campaign_finance/public_handlers.go + sector.go
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses. politician_source_id is NEVER exposed in public JSON.
 *
 * Decimal note: The pg driver returns decimal/numeric columns as JavaScript strings.
 * Always call Number() on: amount fields, totals, sums.
 */

import { pool } from './db.js';
import { normalizeDonorName } from './adapters/normalizeDonorName.js';

// ---------------------------------------------------------------------------
// TypeScript interfaces — ported from models.go
// ---------------------------------------------------------------------------

export interface PoliticianSource {
  id: string;
  essentials_politician_id: string;
  source_system: string;
  external_id: string;
  research_status: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface Donor {
  id: string;
  name: string;
  normalized_name: string;
  donor_type: string;
  city: string;
  state: string;
  employer: string;
  occupation: string;
  created_at: string;
  updated_at: string;
}

export interface Committee {
  id: string;
  name: string;
  committee_type: string;
  source_system: string;
  external_id: string;
  politician_source_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface Contribution {
  id: string;
  donor_id: string | null;
  committee_id: string | null;
  // NOTE: politician_source_id intentionally excluded from public exports
  amount: number;
  contribution_date: string | null;
  election_cycle: string;
  confidence_level: string;
  data_source: string;
  source_transaction_id: string;
  created_at: string;
  updated_at: string;
}

export interface DataSourceMetadata {
  id: number;
  source_system: string;
  last_sync_at: string | null;
  last_sync_status: string;
  last_record_count: number;
  notes: string;
  created_at: string;
  updated_at: string;
}

export interface IngestionRun {
  id: number;
  adapter_name: string;
  politician_source_id: string | null;
  election_cycle: string;
  started_at: string;
  completed_at: string | null;
  status: string;
  records_fetched: number;
  records_inserted: number;
  records_skipped: number;
  records_unresolved: number;
  errors: number;
  duration_ms: number;
  notes: string;
  source_e_tag: string;
  z_ip_downloaded_at: string | null;
}

export interface UnresolvedContribution {
  id: number;
  adapter_name: string;
  ingestion_run_id: number;
  raw_row: Record<string, unknown>;
  row_number: number;
  external_id: string;
  status: string;
  created_at: string;
}

// ---------------------------------------------------------------------------
// Public response types (no politician_source_id exposed)
// ---------------------------------------------------------------------------

export interface SectorEntry {
  sector: string;
  total: number;
  count: number;
}

export interface TopDonorEntry {
  name: string;
  donor_type: string;
  employer: string;
  occupation: string;
  sector: string;
  total_amount: number;
  contribution_count: number;
  confidence_level: string;
}

export interface SummaryResponse {
  politician_id: string;
  cycle: string;
  total_raised: number;
  contribution_count: number;
  confidence_level: string;
  data_source: string;
  last_sync_at: string | null;
  available_cycles: string[];
  individual_total: number;
  pac_total: number;
  sector_breakdown: SectorEntry[];
  top_donors: TopDonorEntry[];
  coverage_status?: string;
  outside_spending: OutsideSpendingResponse;
}

export interface ContributionResult {
  id: string;
  donor_name: string;
  donor_type: string;
  employer: string;
  occupation: string;
  sector: string;
  amount: number;
  contribution_date: string;
  confidence_level: string;
  data_source: string;
}

export interface PageInfo {
  has_next_page: boolean;
  end_cursor: string;
  total_count: number;
}

export interface ContributionsResponse {
  results: ContributionResult[];
  page_info: PageInfo;
}

// ---------------------------------------------------------------------------
// Internal DB row types (pg query result shapes)
// ---------------------------------------------------------------------------

interface CycleRow {
  election_cycle: string;
}

interface TotalsRow {
  total_raised: string;       // numeric -> string (sum of ingested itemized rows)
  non_fec_total: string;      // numeric -> string (sum of non-FEC ingested rows)
  contribution_count: string; // bigint -> string
  confidence_level_n: string; // int -> string
  individual_total: string;   // numeric -> string
  pac_total: string;          // numeric -> string
}

interface OccupationRow {
  occupation: string;
  amount: string; // numeric -> string
}

interface DonorRow {
  contributor_name: string;
  total_amount: string;       // numeric -> string
  contribution_count: string; // bigint -> string
  confidence_level_n: string; // int -> string
  raw_record: string | null;  // jsonb -> string (pg returns as string or null)
}

interface ContribRow {
  id: string;
  amount: string;             // numeric -> string
  contribution_date: string | null;
  election_cycle: string;
  confidence_level: string;
  data_source: string;
  raw_record: string | null;  // jsonb -> string
  donor_name_normalized: string | null;
}

interface MetaRow {
  last_sync_at: string | null;
}

interface TotalCountRow {
  count: string; // bigint -> string
}

// ---------------------------------------------------------------------------
// Sector classifier — ported from sector.go
// CRITICAL: Go map has random iteration order. TypeScript MUST use an ordered
// array of [keyword, sector] tuples so first-match-wins is deterministic.
// Order: more specific terms first (e.g., "software engineer" before "engineer").
// ---------------------------------------------------------------------------

const occupationSectorMap: Array<[string, string]> = [
  ['attorney', 'Legal'],
  ['lawyer', 'Legal'],
  ['counsel', 'Legal'],
  ['paralegal', 'Legal'],
  ['software engineer', 'Technology'],
  ['software developer', 'Technology'],
  ['programmer', 'Technology'],
  ['data scientist', 'Technology'],
  ['physician', 'Healthcare'],
  ['doctor', 'Healthcare'],
  ['surgeon', 'Healthcare'],
  ['dentist', 'Healthcare'],
  ['nurse', 'Healthcare'],
  ['pharmacist', 'Healthcare'],
  ['therapist', 'Healthcare'],
  ['professor', 'Education'],
  ['teacher', 'Education'],
  ['instructor', 'Education'],
  ['principal', 'Education'],
  ['superintendent', 'Education'],
  ['retired', 'Retired'],
  ['homemaker', 'Homemaker'],
  ['housewife', 'Homemaker'],
  ['banker', 'Finance/Insurance'],
  ['financial advisor', 'Finance/Insurance'],
  ['financial analyst', 'Finance/Insurance'],
  ['accountant', 'Finance/Insurance'],
  ['cpa', 'Finance/Insurance'],
  ['actuary', 'Finance/Insurance'],
  ['insurance', 'Finance/Insurance'],
  ['investment', 'Finance/Insurance'],
  ['broker', 'Finance/Insurance'],
  ['realtor', 'Real Estate'],
  ['real estate', 'Real Estate'],
  ['property manager', 'Real Estate'],
  ['farmer', 'Agriculture'],
  ['rancher', 'Agriculture'],
  ['agronomist', 'Agriculture'],
  ['executive', 'Business'],
  ['ceo', 'Business'],
  ['coo', 'Business'],
  ['cfo', 'Business'],
  ['president', 'Business'],
  ['director', 'Business'],
  ['manager', 'Business'],
  ['consultant', 'Business'],
  // NOTE: 'developer' placed after 'software developer' so 'software developer'
  // matches first for that specific occupation string.
  ['developer', 'Technology'],
  // NOTE: 'engineer' placed after 'software engineer' for same reason.
  ['engineer', 'Engineering'],
  ['architect', 'Engineering'],
  ['student', 'Student'],
  ['self-employed', 'Business'],
  ['self employed', 'Business'],
  ['entrepreneur', 'Business'],
];

/**
 * classifySector lowercases and trims the occupation string, then checks
 * occupationSectorMap for the first keyword match (first-match-wins).
 * Returns "Other/Unclassified" if no keyword matches.
 * Ported from ClassifySector() in sector.go.
 */
export function classifySector(occupation: string): string {
  const lower = occupation.toLowerCase().trim();
  if (!lower) return 'Other/Unclassified';
  for (const [keyword, sector] of occupationSectorMap) {
    if (lower.includes(keyword)) return sector;
  }
  return 'Other/Unclassified';
}

// ---------------------------------------------------------------------------
// Raw record parsing helpers — ported from sector.go
// ---------------------------------------------------------------------------

interface FecRawRecord {
  entity_type?: string;
  contributor_committee_id?: string;
  contributor_occupation?: string;
  contributor_employer?: string;
  contributor_name?: string;
  [key: string]: unknown;
}

function parseRawRecord(rawRecord: string | object | null): FecRawRecord {
  if (!rawRecord) return {};
  if (typeof rawRecord === 'object') return rawRecord as FecRawRecord;
  try {
    return JSON.parse(rawRecord) as FecRawRecord;
  } catch {
    return {};
  }
}

function extractDonorType(rawRecord: string | object | null): string {
  const rec = parseRawRecord(rawRecord);
  // Indiana CFA-4 data uses a simple 'type' field set at ingest time
  const simpleType = (rec.type as string | undefined)?.toLowerCase();
  if (simpleType === 'pac' || simpleType === 'corporate_direct') return 'pac';
  if (simpleType === 'direct' || simpleType === 'in_kind') return 'individual';
  // FEC / Socrata / Netfile use entity_type
  const entityType = (rec.entity_type ?? '').toUpperCase().trim();
  if (entityType.startsWith('IND')) return 'individual';
  if (entityType.startsWith('COM') || entityType.startsWith('PAC')) return 'pac';
  if (rec.contributor_committee_id) return 'pac';
  if (entityType !== '') return 'pac';
  return 'unknown';
}

function extractOccupation(rawRecord: string | object | null): string {
  const rec = parseRawRecord(rawRecord);
  return (rec.contributor_occupation ?? (rec['con_occp'] as string | undefined)) ?? '';
}

function extractEmployer(rawRecord: string | object | null): string {
  const rec = parseRawRecord(rawRecord);
  return (rec.contributor_employer ?? (rec['con_empr'] as string | undefined)) ?? '';
}

function extractContributorName(rawRecord: string | object | null): string {
  const rec = parseRawRecord(rawRecord);
  if (rec.contributor_name) return rec.contributor_name;
  const socrataName = rec['con_name'] as string | undefined;
  if (socrataName) return socrataName;
  // Netfile: composite last + first
  const last = (rec['Tran_NamL'] as string | undefined) ?? '';
  const first = (rec['Tran_NamF'] as string | undefined) ?? '';
  return `${last} ${first}`.trim();
}

// ---------------------------------------------------------------------------
// Cursor encode/decode — ported from public_handlers.go
// Format: base64("RFC3339date|UUID")
// ---------------------------------------------------------------------------

/**
 * encodeCursor base64-encodes a cursor from a contribution_date + id pair.
 */
export function encodeCursor(date: Date, id: string): string {
  const raw = `${date.toISOString()}|${id}`;
  return Buffer.from(raw).toString('base64');
}

/**
 * decodeCursor decodes a base64 cursor back into a Date and UUID string.
 * Throws on invalid format.
 */
export function decodeCursor(cursor: string): { date: Date; id: string } {
  let decoded: string;
  try {
    decoded = Buffer.from(cursor, 'base64').toString('utf8');
  } catch {
    throw new Error('invalid cursor encoding');
  }
  const pipeIndex = decoded.indexOf('|');
  if (pipeIndex === -1) throw new Error('invalid cursor format');
  const datePart = decoded.slice(0, pipeIndex);
  const idPart = decoded.slice(pipeIndex + 1);
  const date = new Date(datePart);
  if (isNaN(date.getTime())) throw new Error('invalid cursor date');
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(idPart)) {
    throw new Error('invalid cursor id');
  }
  return { date, id: idPart };
}

// ---------------------------------------------------------------------------
// Utility functions — ported from public_handlers.go
// ---------------------------------------------------------------------------

/**
 * defaultCompletedCycle returns the most recently completed even-year election cycle.
 * "Completed" means prior to the current year: e.g. in 2026, returns "2024".
 */
export function defaultCompletedCycle(): string {
  let year = new Date().getFullYear();
  if (year % 2 !== 0) {
    year -= 1;
  } else {
    year -= 2;
  }
  return String(year);
}

/**
 * validateConfidence maps a lowercase query param to the DB confidence_level value.
 * Returns null when omitted, throws on invalid value.
 */
export function validateConfidence(raw: string | undefined): string | null {
  if (!raw) return null;
  switch (raw.toLowerCase()) {
    case 'high':
      return 'HIGH';
    case 'medium':
      return 'MEDIUM';
    case 'estimated':
      return 'ESTIMATED';
    default:
      throw new Error(`invalid confidence value "${raw}": must be high, medium, or estimated`);
  }
}

// ---------------------------------------------------------------------------
// Confidence rank helpers
// ---------------------------------------------------------------------------

const confidenceLabel: Record<number, string> = { 1: 'HIGH', 2: 'MEDIUM', 3: 'ESTIMATED' };

// ---------------------------------------------------------------------------
// detectCoverageStatus — classify zero-state politicians by data availability
// ---------------------------------------------------------------------------

/**
 * detectCoverageStatus classifies a politician with no confirmed contributions
 * into one of three coverage statuses:
 *   - 'data_pending'       — has source rows but no contributions ingested yet
 *   - 'local_unavailable'  — local/county office; filings are paper/offline
 *   - 'no_data'            — federal/state office with no sources on file
 */
async function detectCoverageStatus(politicianId: string): Promise<string> {
  // Count candidate_committee sources only — ie_committee rows represent PAC/IE spending
  // linked to this politician's race, not the politician's own fundraising committee.
  // A politician with only ie_committee sources has genuinely no candidate fundraising.
  const sourceCountResult = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND source_type = 'candidate_committee'`,
    [politicianId]
  );
  const sourceCount = Number(sourceCountResult.rows[0]?.cnt ?? 0);

  if (sourceCount > 0) {
    return 'data_pending';
  }

  // No source rows — check the politician's office district_type
  const officeResult = await pool.query<{ district_type: string | null }>(
    `SELECT d.district_type
     FROM essentials.offices o
     LEFT JOIN essentials.districts d ON d.id = o.district_id
     WHERE o.politician_id = $1 AND o.is_vacant = false
     LIMIT 1`,
    [politicianId]
  );

  const districtType = officeResult.rows[0]?.district_type ?? null;
  const localTypes = ['LOCAL', 'LOCAL_EXEC', 'COUNTY', 'SCHOOL'];

  if (districtType && localTypes.includes(districtType)) {
    return 'local_unavailable';
  }

  return 'no_data';
}

// ---------------------------------------------------------------------------
// getSummary — ported from SummaryHandler in public_handlers.go
// ---------------------------------------------------------------------------

/**
 * getAuthoritativeFecTotal returns FEC's authoritative total receipts for a
 * politician's confirmed FEC source(s) in a cycle, summed from the cached
 * transparent_motivations.fec_candidate_totals table (populated offline from FEC's
 * candidate totals endpoint). Returns null when no cached total exists.
 *
 * WHY: total_raised summed from ingested Schedule A rows structurally undercounts —
 * Schedule A holds only itemized contributions (unitemized small-dollar money is
 * never in it), and big raisers may be capped. FEC's receipts figure is the
 * authoritative headline. This read never calls FEC (cache only).
 */
async function getAuthoritativeFecTotal(
  politicianId: string,
  cycle: string
): Promise<number | null> {
  try {
    const r = await pool.query<{ receipts: string | null }>(
      `SELECT SUM(t.receipts) AS receipts
       FROM transparent_motivations.fec_candidate_totals t
       JOIN transparent_motivations.politician_sources ps
         ON ps.external_id = t.external_id
       WHERE ps.essentials_politician_id = $1
         AND ps.source_system LIKE 'fec%'
         AND ps.research_status = 'confirmed'
         AND t.cycle = $2`,
      [politicianId, cycle]
    );
    const v = r.rows[0]?.receipts;
    return v == null ? null : Number(v);
  } catch {
    // Table may not exist yet (pre-migration) — fall back to itemized sum.
    return null;
  }
}

/**
 * getSummary returns the campaign finance summary for a politician.
 * Returns a zero-state object (not null/error) when politician has no contributions.
 * politician_source_id is never exposed in the returned object.
 */
export async function getSummary(
  politicianId: string,
  cycle?: string,
  confidence?: string | null
): Promise<{ summary: SummaryResponse; updatedAt: string | null }> {
  const confidenceFilter = confidence ?? null;

  // Query available cycles
  const availCycleResult = await pool.query<CycleRow>(
    `SELECT DISTINCT c.election_cycle
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND ps.research_status = 'confirmed'
     ORDER BY c.election_cycle DESC`,
    [politicianId]
  );

  const availableCycles: string[] = availCycleResult.rows.map((r) => r.election_cycle);

  // Default to the most-recent cycle that actually has data (available_cycles is DESC).
  // Using the last *completed* even year (defaultCompletedCycle) returns $0 for a
  // current-term filer whose only data is the in-progress cycle. An explicit ?cycle= wins.
  const effectiveCycle = cycle ?? availableCycles[0] ?? defaultCompletedCycle();

  // Return zero-state when no data found — not 404
  if (availableCycles.length === 0) {
    const [coverageStatus, outsideSpending] = await Promise.all([
      detectCoverageStatus(politicianId),
      getOutsideSpendingForPolitician(politicianId),
    ]);
    return {
      summary: {
        politician_id: politicianId,
        cycle: effectiveCycle,
        total_raised: 0,
        contribution_count: 0,
        confidence_level: '',
        data_source: '',
        last_sync_at: null,
        available_cycles: [],
        individual_total: 0,
        pac_total: 0,
        sector_breakdown: [],
        top_donors: [],
        coverage_status: coverageStatus,
        outside_spending: outsideSpending,
      },
      updatedAt: null,
    };
  }

  // Build params for filtered queries
  const baseParams: unknown[] = [politicianId, effectiveCycle];
  let confidenceClause = '';
  if (confidenceFilter) {
    confidenceClause = `AND c.confidence_level = $${baseParams.length + 1}`;
    baseParams.push(confidenceFilter);
  }

  // Query totals
  const totalsResult = await pool.query<TotalsRow>(
    `SELECT
       COALESCE(SUM(c.amount), 0) AS total_raised,
       COALESCE(SUM(c.amount) FILTER (WHERE c.data_source != 'fec'), 0) AS non_fec_total,
       COUNT(*) AS contribution_count,
       COALESCE(MIN(CASE c.confidence_level
           WHEN 'HIGH'      THEN 1
           WHEN 'MEDIUM'    THEN 2
           WHEN 'ESTIMATED' THEN 3
           ELSE 4 END), 0) AS confidence_level_n,
       COALESCE(SUM(CASE
           WHEN c.raw_record->>'type' IN ('direct', 'in_kind')
             OR c.raw_record->>'entity_type' LIKE 'IND%'
           THEN c.amount ELSE 0 END), 0) AS individual_total,
       COALESCE(SUM(CASE
           WHEN c.raw_record->>'type' IN ('pac', 'corporate_direct')
             OR (COALESCE(c.raw_record->>'entity_type', '') != ''
                 AND c.raw_record->>'entity_type' NOT LIKE 'IND%')
           THEN c.amount ELSE 0 END), 0) AS pac_total
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${confidenceClause}`,
    baseParams
  );

  const tRow = totalsResult.rows[0];
  const confidenceN = Number(tRow?.confidence_level_n ?? 0);
  const overallConfidence = confidenceLabel[confidenceN] ?? 'HIGH';

  // Headline total_raised: prefer FEC's authoritative receipts (cached) over the
  // itemized-row sum, which undercounts (unitemized + capped). When authoritative
  // is available, use it for the FEC portion and keep any non-FEC (state/local)
  // itemized sum on top. Otherwise fall back to the itemized sum as before.
  const itemizedTotal = Number(tRow?.total_raised ?? 0);
  const nonFecTotal = Number(tRow?.non_fec_total ?? 0);
  const authoritativeFec = await getAuthoritativeFecTotal(politicianId, effectiveCycle);
  const effectiveTotalRaised =
    authoritativeFec != null ? authoritativeFec + nonFecTotal : itemizedTotal;

  // Query occupations for sector breakdown (TypeScript-side classification)
  const occResult = await pool.query<OccupationRow>(
    `SELECT
       COALESCE(c.raw_record->>'contributor_occupation', c.raw_record->>'con_occp', '') AS occupation,
       c.amount
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${confidenceClause}`,
    baseParams
  );

  const sectorAccum = new Map<string, { total: number; count: number }>();
  for (const row of occResult.rows) {
    const sector = classifySector(row.occupation);
    const acc = sectorAccum.get(sector) ?? { total: 0, count: 0 };
    acc.total += Number(row.amount);
    acc.count += 1;
    sectorAccum.set(sector, acc);
  }

  // Sort sectors by total descending, take top 10
  const sectorBreakdown: SectorEntry[] = Array.from(sectorAccum.entries())
    .map(([sector, acc]) => ({ sector, total: acc.total, count: acc.count }))
    .sort((a, b) => b.total - a.total)
    .slice(0, 10);

  // Query top donors
  const donorResult = await pool.query<DonorRow>(
    `SELECT
       COALESCE(c.raw_record->>'contributor_name', c.raw_record->>'con_name', NULLIF(trim(concat(c.raw_record->>'Tran_NamL', ' ', c.raw_record->>'Tran_NamF')), ''), c.donor_name_normalized, '') AS contributor_name,
       SUM(c.amount) AS total_amount,
       COUNT(*) AS contribution_count,
       MIN(CASE c.confidence_level
           WHEN 'HIGH'      THEN 1
           WHEN 'MEDIUM'    THEN 2
           WHEN 'ESTIMATED' THEN 3
           ELSE 4 END) AS confidence_level_n,
       MIN(c.raw_record::text)::jsonb AS raw_record
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${confidenceClause}
     GROUP BY COALESCE(c.raw_record->>'contributor_name', c.raw_record->>'con_name', NULLIF(trim(concat(c.raw_record->>'Tran_NamL', ' ', c.raw_record->>'Tran_NamF')), ''), c.donor_name_normalized, '')
     ORDER BY total_amount DESC
     LIMIT 20`,
    baseParams
  );

  const topDonors: TopDonorEntry[] = donorResult.rows.map((row) => {
    const occ = extractOccupation(row.raw_record);
    const confN = Number(row.confidence_level_n);
    return {
      name: row.contributor_name,
      donor_type: extractDonorType(row.raw_record),
      employer: extractEmployer(row.raw_record),
      occupation: occ,
      sector: classifySector(occ),
      total_amount: Number(row.total_amount),
      contribution_count: Number(row.contribution_count),
      confidence_level: confidenceLabel[confN] ?? '',
    };
  });

  // Derive primary data_source from actual contributions (most common source for this politician/cycle)
  const dataSourceResult = await pool.query<{ data_source: string }>(
    `SELECT c.data_source
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
     GROUP BY c.data_source
     ORDER BY COUNT(*) DESC
     LIMIT 1`,
    [politicianId, effectiveCycle]
  );
  const primaryDataSource = dataSourceResult.rows[0]?.data_source ?? 'fec';

  // Query last_sync_at for freshness header — use the actual data source
  const sourceSystemMap: Record<string, string> = {
    fec: 'fec',
    indiana: 'indiana_zip_etag_2026',
    cal_access: 'cal_access',
    la_city: 'la_city',
  };
  const metaSourceSystem = sourceSystemMap[primaryDataSource] ?? primaryDataSource;
  const metaResult = await pool.query<MetaRow>(
    `SELECT last_sync_at
     FROM transparent_motivations.data_source_metadata
     WHERE source_system = $1
     LIMIT 1`,
    [metaSourceSystem]
  );
  const lastSyncAt = metaResult.rows[0]?.last_sync_at ?? null;

  // Fetch outside spending in parallel with the final data source metadata query
  const outsideSpending = await getOutsideSpendingForPolitician(politicianId);

  const summary: SummaryResponse = {
    politician_id: politicianId,
    cycle: effectiveCycle,
    total_raised: effectiveTotalRaised,
    contribution_count: Number(tRow?.contribution_count ?? 0),
    confidence_level: overallConfidence,
    data_source: primaryDataSource,
    last_sync_at: lastSyncAt,
    available_cycles: availableCycles,
    individual_total: Number(tRow?.individual_total ?? 0),
    pac_total: Number(tRow?.pac_total ?? 0),
    sector_breakdown: sectorBreakdown,
    top_donors: topDonors,
    outside_spending: outsideSpending,
  };

  return { summary, updatedAt: lastSyncAt };
}

/**
 * mostRecentCycleWithData returns the newest election cycle that has confirmed
 * contributions for a politician, or null if none. Used to default endpoints to a
 * cycle that actually has data rather than the last completed even year.
 */
async function mostRecentCycleWithData(politicianId: string): Promise<string | null> {
  const r = await pool.query<CycleRow>(
    `SELECT c.election_cycle
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1 AND ps.research_status = 'confirmed'
     ORDER BY c.election_cycle DESC
     LIMIT 1`,
    [politicianId]
  );
  return r.rows[0]?.election_cycle ?? null;
}

// ---------------------------------------------------------------------------
// getContributions — ported from ContributionsHandler in public_handlers.go
// ---------------------------------------------------------------------------

/**
 * getContributions returns cursor-paginated contributions for a politician.
 * Default limit 50, max 100.
 * Cursor uses contribution_date DESC, id DESC ordering.
 * politician_source_id is never exposed in returned objects.
 */
export async function getContributions(
  politicianId: string,
  options: {
    cursor?: string;
    limit?: number;
    cycle?: string;
    confidence?: string | null;
  } = {}
): Promise<{ response: ContributionsResponse; updatedAt: string | null }> {
  const effectiveCycle = options.cycle ?? (await mostRecentCycleWithData(politicianId)) ?? defaultCompletedCycle();
  const confidenceFilter = options.confidence ?? null;

  // Clamp limit: default 50, max 100
  let limit = options.limit ?? 50;
  if (limit < 1) limit = 1;
  if (limit > 100) limit = 100;

  // Decode cursor if provided
  let cursorDate: Date | null = null;
  let cursorId: string | null = null;
  if (options.cursor) {
    const decoded = decodeCursor(options.cursor);
    cursorDate = decoded.date;
    cursorId = decoded.id;
  }

  // Build params array — use $N numbered params, NEVER interpolate cursor values
  const queryParams: unknown[] = [politicianId, effectiveCycle];
  let confidenceClause = '';
  if (confidenceFilter) {
    confidenceClause = `AND c.confidence_level = $${queryParams.length + 1}`;
    queryParams.push(confidenceFilter);
  }

  let cursorClause = '';
  if (cursorDate !== null && cursorId !== null) {
    cursorClause = `AND (c.contribution_date, c.id::text) < ($${queryParams.length + 1}, $${queryParams.length + 2})`;
    queryParams.push(cursorDate.toISOString(), cursorId);
  }

  // Fetch limit+1 to detect if there's a next page
  const pageResult = await pool.query<ContribRow>(
    `SELECT
       c.id,
       c.amount,
       c.contribution_date,
       c.election_cycle,
       c.confidence_level,
       c.data_source,
       c.raw_record,
       c.donor_name_normalized
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${confidenceClause}
       ${cursorClause}
     ORDER BY c.contribution_date DESC, c.id DESC
     LIMIT ${limit + 1}`,
    queryParams
  );

  let rawResults = pageResult.rows;
  const hasNextPage = rawResults.length > limit;
  if (hasNextPage) rawResults = rawResults.slice(0, limit);

  // Build response items
  const results: ContributionResult[] = rawResults.map((row) => {
    const occ = extractOccupation(row.raw_record);
    return {
      id: row.id,
      donor_name: row.donor_name_normalized || extractContributorName(row.raw_record),
      donor_type: extractDonorType(row.raw_record),
      employer: extractEmployer(row.raw_record),
      occupation: occ,
      sector: classifySector(occ),
      amount: Number(row.amount),
      contribution_date: row.contribution_date
        ? new Date(row.contribution_date).toISOString().slice(0, 10)
        : '',
      confidence_level: row.confidence_level,
      data_source: row.data_source,
    };
  });

  // Build end_cursor from last result (only when there is a next page)
  let endCursor = '';
  if (hasNextPage && rawResults.length > 0) {
    const last = rawResults[rawResults.length - 1];
    if (last.contribution_date) {
      endCursor = encodeCursor(new Date(last.contribution_date), last.id);
    }
  }

  // Count total matching rows (no cursor, no limit) for page_info.total_count
  const countParams: unknown[] = [politicianId, effectiveCycle];
  let countConfidenceClause = '';
  if (confidenceFilter) {
    countConfidenceClause = `AND c.confidence_level = $${countParams.length + 1}`;
    countParams.push(confidenceFilter);
  }

  const countResult = await pool.query<TotalCountRow>(
    `SELECT COUNT(*) AS count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${countConfidenceClause}`,
    countParams
  );
  const totalCount = Number(countResult.rows[0]?.count ?? 0);

  // Query last_sync_at for freshness header
  const metaResult = await pool.query<MetaRow>(
    `SELECT last_sync_at
     FROM transparent_motivations.data_source_metadata
     WHERE source_system = 'fec'
     LIMIT 1`
  );
  const updatedAt = metaResult.rows[0]?.last_sync_at ?? null;

  return {
    response: {
      results,
      page_info: {
        has_next_page: hasNextPage,
        end_cursor: endCursor,
        total_count: totalCount,
      },
    },
    updatedAt,
  };
}

// ---------------------------------------------------------------------------
// campaignFinanceInit — startup schema connectivity check
// Replaces Go Init()'s AutoMigrate role. Schema is already created.
// Express only verifies it's reachable — does NOT migrate.
// ---------------------------------------------------------------------------

/**
 * campaignFinanceInit verifies that the transparent_motivations schema is reachable
 * at server startup. Throws if not reachable — server should not start without the schema.
 */
export async function campaignFinanceInit(): Promise<void> {
  try {
    await pool.query('SELECT 1 FROM transparent_motivations.politician_sources LIMIT 1');
    console.log('campaign-finance: transparent_motivations schema verified');
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('campaign-finance: FATAL — transparent_motivations schema not reachable:', message);
    throw err;
  }
}

// ---------------------------------------------------------------------------
// Admin service functions — sources CRUD, audit log, ingestion runs
// Ported from EV-Backend/internal/campaign_finance/handlers.go
// ---------------------------------------------------------------------------

// DB row types for admin queries

interface SourceRow {
  id: string;
  essentials_politician_id: string;
  source_system: string;
  external_id: string;
  research_status: string;
  notes: string;
  created_at: string;
  updated_at: string;
}

interface IngestionRunRow {
  id: string;
  adapter_name: string;
  politician_source_id: string | null;
  election_cycle: string;
  started_at: string;
  completed_at: string | null;
  status: string;
  records_fetched: string;
  records_inserted: string;
  records_skipped: string;
  records_unresolved: string;
  errors: string;
  duration_ms: string;
  notes: string;
  source_e_tag: string;
  z_ip_downloaded_at: string | null;
}

// Input types for sources CRUD

export interface CreateSourceInput {
  essentials_politician_id: string;
  source_system: string;
  external_id?: string;
  research_status?: string;
  notes?: string;
}

export interface UpdateSourceInput {
  essentials_politician_id?: string;
  source_system?: string;
  external_id?: string;
  research_status?: string;
  notes?: string;
}

/**
 * getSourcesByPolitician returns all politician_sources rows for a given
 * essentials_politician_id, ordered by created_at DESC.
 */
export async function getSourcesByPolitician(politicianId: string): Promise<PoliticianSource[]> {
  const result = await pool.query<SourceRow>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
     ORDER BY created_at DESC`,
    [politicianId]
  );

  return result.rows.map((r) => ({
    id: r.id,
    essentials_politician_id: r.essentials_politician_id,
    source_system: r.source_system,
    external_id: r.external_id,
    research_status: r.research_status,
    notes: r.notes,
    created_at: r.created_at,
    updated_at: r.updated_at,
  }));
}

/**
 * createSource inserts a new row into politician_sources.
 * Defaults research_status to 'needs_research' if not provided.
 * Returns the created row.
 */
export async function createSource(data: CreateSourceInput): Promise<PoliticianSource> {
  const researchStatus = data.research_status ?? 'needs_research';
  const externalId = data.external_id ?? '';
  const notes = data.notes ?? '';

  const result = await pool.query<SourceRow>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, essentials_politician_id, source_system, external_id,
               research_status, notes, created_at, updated_at`,
    [data.essentials_politician_id, data.source_system, externalId, researchStatus, notes]
  );

  const r = result.rows[0];
  return {
    id: r.id,
    essentials_politician_id: r.essentials_politician_id,
    source_system: r.source_system,
    external_id: r.external_id,
    research_status: r.research_status,
    notes: r.notes,
    created_at: r.created_at,
    updated_at: r.updated_at,
  };
}

/**
 * getSourceById returns a single politician_sources row by ID.
 * Returns null if not found.
 */
export async function getSourceById(id: string): Promise<PoliticianSource | null> {
  const result = await pool.query<SourceRow>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE id = $1`,
    [id]
  );

  if (result.rows.length === 0) return null;
  const r = result.rows[0];
  return {
    id: r.id,
    essentials_politician_id: r.essentials_politician_id,
    source_system: r.source_system,
    external_id: r.external_id,
    research_status: r.research_status,
    notes: r.notes,
    created_at: r.created_at,
    updated_at: r.updated_at,
  };
}

/**
 * updateSource updates allowed fields on a politician_sources row.
 * Only whitelisted fields are updated — prevents SQL injection via field names.
 * Returns the updated row, or null if not found.
 */
export async function updateSource(
  id: string,
  data: UpdateSourceInput
): Promise<PoliticianSource | null> {
  // Build SET clause from explicit whitelist — NEVER interpolate field names from user input
  const setClauses: string[] = [];
  const params: unknown[] = [];
  let paramIdx = 1;

  if (data.essentials_politician_id !== undefined) {
    setClauses.push(`essentials_politician_id = $${paramIdx++}`);
    params.push(data.essentials_politician_id);
  }
  if (data.source_system !== undefined) {
    setClauses.push(`source_system = $${paramIdx++}`);
    params.push(data.source_system);
  }
  if (data.external_id !== undefined) {
    setClauses.push(`external_id = $${paramIdx++}`);
    params.push(data.external_id);
  }
  if (data.research_status !== undefined) {
    setClauses.push(`research_status = $${paramIdx++}`);
    params.push(data.research_status);
  }
  if (data.notes !== undefined) {
    setClauses.push(`notes = $${paramIdx++}`);
    params.push(data.notes);
  }

  if (setClauses.length === 0) {
    // Nothing to update — return current row
    return getSourceById(id);
  }

  // Always bump updated_at
  setClauses.push(`updated_at = NOW()`);

  params.push(id); // final param for WHERE id = $N

  const result = await pool.query<SourceRow>(
    `UPDATE transparent_motivations.politician_sources
     SET ${setClauses.join(', ')}
     WHERE id = $${paramIdx}
     RETURNING id, essentials_politician_id, source_system, external_id,
               research_status, notes, created_at, updated_at`,
    params
  );

  if (result.rows.length === 0) return null;
  const r = result.rows[0];
  return {
    id: r.id,
    essentials_politician_id: r.essentials_politician_id,
    source_system: r.source_system,
    external_id: r.external_id,
    research_status: r.research_status,
    notes: r.notes,
    created_at: r.created_at,
    updated_at: r.updated_at,
  };
}

/**
 * deleteSource removes a row from politician_sources by ID.
 * Returns true if a row was deleted, false if not found.
 */
export async function deleteSource(id: string): Promise<boolean> {
  const result = await pool.query(
    `DELETE FROM transparent_motivations.politician_sources WHERE id = $1`,
    [id]
  );
  return (result.rowCount ?? 0) > 0;
}

/**
 * logSourceAudit inserts a row into source_audit_log.
 * Records the before/after state of a politician_sources row for accountability.
 * This is best-effort — errors are logged but do not fail the calling request.
 *
 * Ported from writeAuditLog() in handlers.go.
 */
export async function logSourceAudit(
  sourceId: string,
  userId: string,
  username: string,
  action: string,
  oldValue: unknown,
  newValue: unknown
): Promise<void> {
  const oldJson = oldValue !== null ? JSON.stringify(oldValue) : null;
  const newJson = newValue !== null ? JSON.stringify(newValue) : null;

  await pool.query(
    `INSERT INTO transparent_motivations.source_audit_log
       (politician_source_id, changed_by_user_id, changed_by_username, action, old_value, new_value, changed_at)
     VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, NOW())`,
    [sourceId, userId, username, action, oldJson, newJson]
  );
}

/**
 * getIngestionRuns returns recent ingestion_runs rows for the admin dashboard.
 * Optionally filtered by adapter_name. Default limit 50.
 */
export async function getIngestionRuns(
  adapterName?: string,
  limit = 50
): Promise<IngestionRun[]> {
  // Clamp limit to a safe range
  const safeLimit = Math.min(Math.max(limit, 1), 500);

  let query: string;
  let params: unknown[];

  if (adapterName) {
    query = `SELECT id, adapter_name, politician_source_id, election_cycle,
                    started_at, completed_at, status, records_fetched, records_inserted,
                    records_skipped, records_unresolved, errors, duration_ms,
                    notes, source_e_tag, z_ip_downloaded_at
             FROM transparent_motivations.ingestion_runs
             WHERE adapter_name = $1
             ORDER BY started_at DESC
             LIMIT $2`;
    params = [adapterName, safeLimit];
  } else {
    query = `SELECT id, adapter_name, politician_source_id, election_cycle,
                    started_at, completed_at, status, records_fetched, records_inserted,
                    records_skipped, records_unresolved, errors, duration_ms,
                    notes, source_e_tag, z_ip_downloaded_at
             FROM transparent_motivations.ingestion_runs
             ORDER BY started_at DESC
             LIMIT $1`;
    params = [safeLimit];
  }

  const result = await pool.query<IngestionRunRow>(query, params);

  return result.rows.map((r) => ({
    id: Number(r.id),
    adapter_name: r.adapter_name,
    politician_source_id: r.politician_source_id,
    election_cycle: r.election_cycle,
    started_at: r.started_at,
    completed_at: r.completed_at,
    status: r.status,
    records_fetched: Number(r.records_fetched),
    records_inserted: Number(r.records_inserted),
    records_skipped: Number(r.records_skipped),
    records_unresolved: Number(r.records_unresolved),
    errors: Number(r.errors),
    duration_ms: Number(r.duration_ms),
    notes: r.notes,
    source_e_tag: r.source_e_tag,
    z_ip_downloaded_at: r.z_ip_downloaded_at,
  }));
}

/**
 * getConfirmedFecSources returns all politician_sources rows with source_system='fec'
 * and research_status='confirmed'. Used by the batch FEC ingest handler.
 */
export async function getConfirmedFecSources(): Promise<PoliticianSource[]> {
  const result = await pool.query<SourceRow>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE source_system IN ('fec', 'fec_house', 'fec_senate')
       AND research_status = 'confirmed'
     ORDER BY created_at ASC`,
    []
  );

  return result.rows.map((r) => ({
    id: r.id,
    essentials_politician_id: r.essentials_politician_id,
    source_system: r.source_system,
    external_id: r.external_id,
    research_status: r.research_status,
    notes: r.notes,
    created_at: r.created_at,
    updated_at: r.updated_at,
  }));
}

/**
 * getMostRecentIngestionRun returns the most recent ingestion_runs row for the
 * given adapter_name (by started_at DESC). Returns null if none found.
 * Used by the batch ingest handler to return the ingestion_run_id in the response.
 */
export async function getMostRecentIngestionRun(adapterName: string): Promise<IngestionRun | null> {
  const result = await pool.query<IngestionRunRow>(
    `SELECT id, adapter_name, politician_source_id, election_cycle,
            started_at, completed_at, status, records_fetched, records_inserted,
            records_skipped, records_unresolved, errors, duration_ms,
            notes, source_e_tag, z_ip_downloaded_at
     FROM transparent_motivations.ingestion_runs
     WHERE adapter_name = $1
     ORDER BY started_at DESC
     LIMIT 1`,
    [adapterName]
  );

  if (result.rows.length === 0) return null;
  const r = result.rows[0];
  return {
    id: Number(r.id),
    adapter_name: r.adapter_name,
    politician_source_id: r.politician_source_id,
    election_cycle: r.election_cycle,
    started_at: r.started_at,
    completed_at: r.completed_at,
    status: r.status,
    records_fetched: Number(r.records_fetched),
    records_inserted: Number(r.records_inserted),
    records_skipped: Number(r.records_skipped),
    records_unresolved: Number(r.records_unresolved),
    errors: Number(r.errors),
    duration_ms: Number(r.duration_ms),
    notes: r.notes,
    source_e_tag: r.source_e_tag,
    z_ip_downloaded_at: r.z_ip_downloaded_at,
  };
}

/**
 * getIngestionRunAfter returns the most recent ingestion_runs row for a
 * given politician_source_id + election_cycle that started after startedAfter.
 * Used by IngestFEC JWT route to retrieve the run ID after a synchronous ingest.
 * Returns null if none found.
 */
export async function getIngestionRunAfter(
  politicianSourceId: string,
  cycle: string,
  startedAfter: Date
): Promise<IngestionRun | null> {
  const result = await pool.query<IngestionRunRow>(
    `SELECT id, adapter_name, politician_source_id, election_cycle,
            started_at, completed_at, status, records_fetched, records_inserted,
            records_skipped, records_unresolved, errors, duration_ms,
            notes, source_e_tag, z_ip_downloaded_at
     FROM transparent_motivations.ingestion_runs
     WHERE politician_source_id = $1
       AND election_cycle = $2
       AND started_at >= $3
     ORDER BY started_at DESC
     LIMIT 1`,
    [politicianSourceId, cycle, startedAfter.toISOString()]
  );

  if (result.rows.length === 0) return null;
  const r = result.rows[0];
  return {
    id: Number(r.id),
    adapter_name: r.adapter_name,
    politician_source_id: r.politician_source_id,
    election_cycle: r.election_cycle,
    started_at: r.started_at,
    completed_at: r.completed_at,
    status: r.status,
    records_fetched: Number(r.records_fetched),
    records_inserted: Number(r.records_inserted),
    records_skipped: Number(r.records_skipped),
    records_unresolved: Number(r.records_unresolved),
    errors: Number(r.errors),
    duration_ms: Number(r.duration_ms),
    notes: r.notes,
    source_e_tag: r.source_e_tag,
    z_ip_downloaded_at: r.z_ip_downloaded_at,
  };
}

// ---------------------------------------------------------------------------
// Unresolved queue service functions — ported from unresolved_handlers.go
// ---------------------------------------------------------------------------

export interface UnresolvedAggregationEntry {
  external_id: string;
  adapter_name: string;
  status: string;
  contribution_count: number;
  first_seen_at: string;
  last_seen_at: string;
  candidate_name: string;
}

/**
 * getUnresolvedAggregation returns unresolved contributions grouped by
 * (adapter_name, external_id), ordered by count descending.
 *
 * @param showStatus - 'active' (default) or 'dismissed'
 * @param source - optional filter by adapter_name
 */
export async function getUnresolvedAggregation(
  showStatus = 'active',
  source?: string
): Promise<UnresolvedAggregationEntry[]> {
  const params: unknown[] = [showStatus];
  let sourceFilter = '';
  if (source) {
    sourceFilter = ` AND adapter_name = $${params.length + 1}`;
    params.push(source);
  }

  const result = await pool.query<{
    external_id: string;
    adapter_name: string;
    status: string;
    contribution_count: string; // bigint -> string
    first_seen_at: string;
    last_seen_at: string;
    candidate_name: string | null;
  }>(
    `SELECT
       external_id,
       adapter_name,
       status,
       COUNT(*) AS contribution_count,
       MIN(created_at) AS first_seen_at,
       MAX(created_at) AS last_seen_at,
       MAX(raw_row->>'CandidateName') AS candidate_name
     FROM transparent_motivations.unresolved_contributions
     WHERE status = $1${sourceFilter}
     GROUP BY external_id, adapter_name, status
     ORDER BY contribution_count DESC`,
    params
  );

  return result.rows.map((r) => ({
    external_id: r.external_id,
    adapter_name: r.adapter_name,
    status: r.status,
    contribution_count: Number(r.contribution_count),
    first_seen_at: r.first_seen_at,
    last_seen_at: r.last_seen_at,
    candidate_name: r.candidate_name ?? '',
  }));
}

/**
 * getUnresolvedByExternalId returns individual unresolved_contributions rows
 * for a given (adapter_name, external_id) pair.
 */
export async function getUnresolvedByExternalId(
  adapterName: string,
  externalId: string
): Promise<UnresolvedContribution[]> {
  const result = await pool.query<{
    id: string;
    adapter_name: string;
    ingestion_run_id: string;
    raw_row: unknown;
    row_number: string;
    external_id: string;
    status: string;
    created_at: string;
  }>(
    `SELECT id, adapter_name, ingestion_run_id, raw_row, row_number,
            external_id, status, created_at
     FROM transparent_motivations.unresolved_contributions
     WHERE adapter_name = $1 AND external_id = $2
     ORDER BY row_number ASC`,
    [adapterName, externalId]
  );

  return result.rows.map((r) => ({
    id: Number(r.id),
    adapter_name: r.adapter_name,
    ingestion_run_id: Number(r.ingestion_run_id),
    raw_row: r.raw_row as Record<string, unknown>,
    row_number: Number(r.row_number),
    external_id: r.external_id,
    status: r.status,
    created_at: r.created_at,
  }));
}

/**
 * findOrCreatePoliticianSource finds an existing politician_source by
 * (essentials_politician_id, source_system, external_id), or creates a new confirmed one.
 *
 * Used by the unresolved queue resolve handler to create a permanent link
 * between an unresolved externalId and a known politician.
 */
export async function findOrCreatePoliticianSource(
  politicianId: string,
  adapterName: string,
  externalId: string
): Promise<PoliticianSource> {
  // Try to find existing source
  const findResult = await pool.query<{
    id: string;
    essentials_politician_id: string;
    source_system: string;
    external_id: string;
    research_status: string;
    notes: string;
    created_at: string;
    updated_at: string;
  }>(
    `SELECT id, essentials_politician_id, source_system, external_id,
            research_status, notes, created_at, updated_at
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1 AND source_system = $2 AND external_id = $3
     LIMIT 1`,
    [politicianId, adapterName, externalId]
  );

  if (findResult.rows.length > 0) {
    return findResult.rows[0] as PoliticianSource;
  }

  // Create new confirmed source
  const insertResult = await pool.query<{
    id: string;
    essentials_politician_id: string;
    source_system: string;
    external_id: string;
    research_status: string;
    notes: string;
    created_at: string;
    updated_at: string;
  }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, $2, $3, 'confirmed', '')
     RETURNING id, essentials_politician_id, source_system, external_id,
               research_status, notes, created_at, updated_at`,
    [politicianId, adapterName, externalId]
  );

  return insertResult.rows[0] as PoliticianSource;
}

/**
 * getUnresolvedRowsForBackfill fetches all active unresolved_contributions
 * rows for a given (adapter_name, external_id) pair, returning raw_row as JSON.
 */
export async function getUnresolvedRowsForBackfill(
  adapterName: string,
  externalId: string
): Promise<UnresolvedContribution[]> {
  const result = await pool.query<{
    id: string;
    adapter_name: string;
    ingestion_run_id: string;
    raw_row: unknown;
    row_number: string;
    external_id: string;
    status: string;
    created_at: string;
  }>(
    `SELECT id, adapter_name, ingestion_run_id, raw_row, row_number,
            external_id, status, created_at
     FROM transparent_motivations.unresolved_contributions
     WHERE adapter_name = $1 AND external_id = $2 AND status = 'active'`,
    [adapterName, externalId]
  );

  return result.rows.map((r) => ({
    id: Number(r.id),
    adapter_name: r.adapter_name,
    ingestion_run_id: Number(r.ingestion_run_id),
    raw_row: r.raw_row as Record<string, unknown>,
    row_number: Number(r.row_number),
    external_id: r.external_id,
    status: r.status,
    created_at: r.created_at,
  }));
}

/**
 * markUnresolvedResolved marks all active rows for (adapter_name, external_id) as resolved.
 * Returns the number of rows affected.
 */
export async function markUnresolvedResolved(
  adapterName: string,
  externalId: string
): Promise<number> {
  const result = await pool.query(
    `UPDATE transparent_motivations.unresolved_contributions
     SET status = 'resolved'
     WHERE adapter_name = $1 AND external_id = $2 AND status = 'active'`,
    [adapterName, externalId]
  );
  return result.rowCount ?? 0;
}

/**
 * markUnresolvedDismissed marks all active rows for (adapter_name, external_id) as dismissed.
 * Returns the number of rows affected.
 */
export async function markUnresolvedDismissed(
  adapterName: string,
  externalId: string
): Promise<number> {
  const result = await pool.query(
    `UPDATE transparent_motivations.unresolved_contributions
     SET status = 'dismissed'
     WHERE adapter_name = $1 AND external_id = $2 AND status = 'active'`,
    [adapterName, externalId]
  );
  return result.rowCount ?? 0;
}

/**
 * markUnresolvedActive restores dismissed rows to active for (adapter_name, external_id).
 * Returns the number of rows affected.
 */
export async function markUnresolvedActive(
  adapterName: string,
  externalId: string
): Promise<number> {
  const result = await pool.query(
    `UPDATE transparent_motivations.unresolved_contributions
     SET status = 'active'
     WHERE adapter_name = $1 AND external_id = $2 AND status = 'dismissed'`,
    [adapterName, externalId]
  );
  return result.rowCount ?? 0;
}

// ---------------------------------------------------------------------------
// Donor Search — types + service function
// ---------------------------------------------------------------------------

export interface DonorContributionRow {
  date: string | null;
  amount: number;
  employer: string;
  city: string;
  state: string;
  confidence_level: string;
}

export interface DonorSearchGroup {
  politician_id: string;
  politician_name: string;
  office_title: string | null;
  jurisdiction: string | null;
  district: string | null;
  total_donated: number;
  contribution_count: number;
  mode_confidence: string;
  contributions: DonorContributionRow[];
}

export interface DonorSearchResponse {
  query: string;
  politicians: DonorSearchGroup[];
}

/**
 * modeConfidence returns the confidence_level value that appears most often
 * across a set of contribution rows. Falls back to 'HIGH' if list is empty.
 */
function modeConfidence(contributions: Array<{ confidence_level: string }>): string {
  const counts: Record<string, number> = {};
  for (const c of contributions) {
    counts[c.confidence_level] = (counts[c.confidence_level] ?? 0) + 1;
  }
  return Object.entries(counts).sort(([, a], [, b]) => b - a)[0]?.[0] ?? 'HIGH';
}

/**
 * searchDonors — public donor name search, cycle-agnostic.
 *
 * Normalizes the raw query via normalizeDonorName() before any SQL, uses
 * pg_trgm word_similarity with a GIN index for fuzzy, word-order-insensitive
 * matching, and returns results grouped by politician.
 *
 * politician_source_id is NEVER exposed in any response field.
 */
export async function searchDonors(rawQuery: string): Promise<DonorSearchResponse> {
  const normalized = normalizeDonorName(rawQuery);

  // Anonymous donors carry no useful information — return empty immediately.
  if (normalized === 'anonymous') {
    return { query: rawQuery, politicians: [] };
  }

  // Calibrate similarity threshold by normalized query length.
  const threshold =
    normalized.length <= 4 ? 0.15 :
    normalized.length <= 7 ? 0.20 :
    0.25;

  const sql = `
    WITH donor_matches AS (
      SELECT DISTINCT c.donor_name_normalized
      FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
      WHERE c.donor_name_normalized operator(extensions.%>) $1
        AND extensions.word_similarity($1, c.donor_name_normalized) >= ${threshold}
        AND ps.research_status = 'confirmed'
      LIMIT 50
    ),
    grouped AS (
      SELECT
        ps.essentials_politician_id,
        SUM(c.amount) AS total_donated,
        COUNT(*) AS contribution_count,
        json_agg(json_build_object(
          'date', c.contribution_date,
          'amount', c.amount,
          'employer', COALESCE(c.raw_record->>'contributor_employer', c.raw_record->>'con_empr'),
          'city', COALESCE(c.raw_record->>'contributor_city', c.raw_record->>'con_city_nm'),
          'state', COALESCE(c.raw_record->>'contributor_state', c.raw_record->>'con_state_nm'),
          'confidence_level', c.confidence_level
        ) ORDER BY c.contribution_date DESC) AS contributions
      FROM transparent_motivations.contributions c
      JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
      JOIN donor_matches dm ON c.donor_name_normalized = dm.donor_name_normalized
      WHERE ps.research_status = 'confirmed'
      GROUP BY ps.essentials_politician_id
    )
    SELECT p.id AS politician_id, p.full_name AS politician_name,
      o.title AS office_title, g.name AS jurisdiction, d.label AS district,
      gr.total_donated, gr.contribution_count, gr.contributions
    FROM grouped gr
    JOIN essentials.politicians p ON p.id = gr.essentials_politician_id
    LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    ORDER BY gr.total_donated DESC
  `;

  const result = await pool.query(sql, [normalized]);

  const politicians: DonorSearchGroup[] = result.rows.map((row) => {
    // pg returns json_agg as a parsed JS array already
    const rawContribs: Array<{
      date: string | null;
      amount: string | number;
      employer: string | null;
      city: string | null;
      state: string | null;
      confidence_level: string;
    }> = Array.isArray(row.contributions) ? row.contributions : [];

    const contributions: DonorContributionRow[] = rawContribs.map((c) => ({
      date: c.date ?? null,
      amount: Number(c.amount),
      employer: c.employer ?? '',
      city: c.city ?? '',
      state: c.state ?? '',
      confidence_level: c.confidence_level,
    }));

    return {
      politician_id: row.politician_id as string,
      politician_name: row.politician_name as string,
      office_title: (row.office_title as string | null) ?? null,
      jurisdiction: (row.jurisdiction as string | null) ?? null,
      district: (row.district as string | null) ?? null,
      total_donated: Number(row.total_donated),
      contribution_count: Number(row.contribution_count),
      mode_confidence: modeConfidence(contributions),
      contributions,
    };
  });

  return { query: rawQuery, politicians };
}

// ---------------------------------------------------------------------------
// Outside spending types and helper
// ---------------------------------------------------------------------------

export interface OutsideSpendingCommittee {
  cmt_id: string;
  cmt_nm: string;
  total_amount: number;
  contribution_count: number;
  top_donors: Array<{ donor_name: string; amount: number }>;
}

export interface OutsideSpendingResponse {
  committees: OutsideSpendingCommittee[];
}

// DB row types for outside spending queries

interface IeCommitteeTotalsRow {
  cmt_id: string;
  cmt_nm: string;
  total_amount: string;  // numeric -> string
  contribution_count: string; // bigint -> string
}

interface IeTopDonorRow {
  cmt_id: string;
  donor_name: string | null;
  amount: string; // numeric -> string
}

/**
 * getOutsideSpendingForPolitician returns IE committee spending data linked to a politician.
 *
 * Sources: transparent_motivations.politician_sources rows with source_type='ie_committee'
 * and research_status='confirmed'. Contribution rows are linked via politician_source_id.
 *
 * cmt_id is stored in politician_sources.external_id.
 * cmt_nm is stored in politician_sources.notes as JSON text (notes::jsonb->>'cmt_nm').
 *
 * Returns { committees: [] } when no IE sources exist — never omits the key.
 */
async function getOutsideSpendingForPolitician(
  politicianId: string
): Promise<OutsideSpendingResponse> {
  // Query IE committee totals.
  // Join through external_id (cmt_id) rather than politician_source_id directly — the unique
  // constraint on (data_source, source_transaction_id) means contributions land on whichever
  // politician_source row ingested first. All politician_sources sharing the same cmt_id must
  // be checked so every politician linked to the committee sees the same totals.
  const totalsResult = await pool.query<IeCommitteeTotalsRow>(
    `WITH ie_cmt_ids AS (
       SELECT external_id AS cmt_id,
              notes::jsonb->>'cmt_nm' AS cmt_nm
         FROM transparent_motivations.politician_sources
        WHERE essentials_politician_id = $1
          AND source_type = 'ie_committee'
          AND research_status = 'confirmed'
     ),
     ie_all_sources AS (
       SELECT ps.id, ps.external_id AS cmt_id
         FROM transparent_motivations.politician_sources ps
         JOIN ie_cmt_ids ic ON ps.external_id = ic.cmt_id
        WHERE ps.source_system = 'la_socrata'
     )
     SELECT ic.cmt_id,
            ic.cmt_nm,
            COALESCE(SUM(c.amount), 0)::numeric AS total_amount,
            COUNT(c.*) AS contribution_count
       FROM ie_cmt_ids ic
       LEFT JOIN ie_all_sources ias ON ias.cmt_id = ic.cmt_id
       LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = ias.id
      GROUP BY ic.cmt_id, ic.cmt_nm
      ORDER BY total_amount DESC`,
    [politicianId]
  );

  if (totalsResult.rows.length === 0) {
    return { committees: [] };
  }

  // Query top donors per IE committee (top 10 per committee, UI shows top 5)
  const topDonorsResult = await pool.query<IeTopDonorRow>(
    `WITH ie_cmt_ids AS (
       SELECT external_id AS cmt_id
         FROM transparent_motivations.politician_sources
        WHERE essentials_politician_id = $1
          AND source_type = 'ie_committee'
          AND research_status = 'confirmed'
     ),
     ie_all_sources AS (
       SELECT ps.id, ps.external_id AS cmt_id
         FROM transparent_motivations.politician_sources ps
         JOIN ie_cmt_ids ic ON ps.external_id = ic.cmt_id
        WHERE ps.source_system = 'la_socrata'
     )
     SELECT ias.cmt_id,
            c.donor_name_normalized AS donor_name,
            SUM(c.amount)::numeric AS amount
       FROM ie_all_sources ias
       JOIN transparent_motivations.contributions c ON c.politician_source_id = ias.id
      GROUP BY ias.cmt_id, c.donor_name_normalized
      ORDER BY ias.cmt_id, amount DESC`,
    [politicianId]
  );

  // Group top donors by cmt_id
  const donorsByCmtId = new Map<string, Array<{ donor_name: string; amount: number }>>();
  for (const row of topDonorsResult.rows) {
    const existing = donorsByCmtId.get(row.cmt_id) ?? [];
    if (existing.length < 10) {
      existing.push({
        donor_name: row.donor_name ?? '',
        amount: Number(row.amount),
      });
      donorsByCmtId.set(row.cmt_id, existing);
    }
  }

  const committees: OutsideSpendingCommittee[] = totalsResult.rows.map((row) => ({
    cmt_id: row.cmt_id,
    cmt_nm: row.cmt_nm ?? '',
    total_amount: Number(row.total_amount),
    contribution_count: Number(row.contribution_count),
    top_donors: donorsByCmtId.get(row.cmt_id) ?? [],
  }));

  return { committees };
}

// ---------------------------------------------------------------------------
// getCouncilVotes — LA City Council voting record for a politician
// ---------------------------------------------------------------------------

export interface CouncilVote {
  vote_date: string;           // YYYY-MM-DD
  council_file_number: string | null;
  description: string;
  vote: 'YES' | 'NO' | 'ABSENT' | 'ABSTAIN' | 'RECUSE' | 'PRESENT';
  meeting_type: string;
  item_number: string;
}

export interface CouncilVotesResponse {
  politician_id: string;
  votes: CouncilVote[];
  total: number;
  yes_total: number;
  no_total: number;
  absent_total: number;
}

/**
 * getCouncilVotes returns recent LA City Council vote records for a politician.
 * Reads from meetings.la_council_votes — up to 100 most recent, most recent first.
 */
export async function getCouncilVotes(
  politicianId: string,
  options: { limit?: number; offset?: number; voteFilter?: string } = {}
): Promise<CouncilVotesResponse> {
  const limit = Math.min(options.limit ?? 50, 100);
  const offset = options.offset ?? 0;
  const voteFilter = options.voteFilter && options.voteFilter !== 'ALL' ? options.voteFilter : null;

  const countResult = await pool.query<{ cnt: string; yes_cnt: string; no_cnt: string; absent_cnt: string }>(
    `SELECT
       COUNT(*) AS cnt,
       COUNT(*) FILTER (WHERE vote = 'YES') AS yes_cnt,
       COUNT(*) FILTER (WHERE vote = 'NO') AS no_cnt,
       COUNT(*) FILTER (WHERE vote = 'ABSENT') AS absent_cnt
     FROM meetings.la_council_votes WHERE politician_id = $1`,
    [politicianId]
  );
  const total = Number(countResult.rows[0]?.cnt ?? 0);
  const yes_total = Number(countResult.rows[0]?.yes_cnt ?? 0);
  const no_total = Number(countResult.rows[0]?.no_cnt ?? 0);
  const absent_total = Number(countResult.rows[0]?.absent_cnt ?? 0);

  if (total === 0) {
    return { politician_id: politicianId, votes: [], total: 0, yes_total: 0, no_total: 0, absent_total: 0 };
  }

  const result = await pool.query<{
    vote_date: string;
    council_file_number: string | null;
    agenda_description: string | null;
    vote: string;
    meeting_type: string | null;
    item_number: string | null;
  }>(
    `SELECT vote_date, council_file_number, agenda_description, vote, meeting_type, item_number
     FROM meetings.la_council_votes
     WHERE politician_id = $1 AND ($2::text IS NULL OR vote = $2::text)
     ORDER BY vote_date DESC, item_number ASC
     LIMIT $3 OFFSET $4`,
    [politicianId, voteFilter, limit, offset]
  );

  const votes: CouncilVote[] = result.rows.map(r => ({
    vote_date: r.vote_date,
    council_file_number: r.council_file_number ?? null,
    description: r.agenda_description ?? '',
    vote: r.vote as CouncilVote['vote'],
    meeting_type: r.meeting_type ?? '',
    item_number: r.item_number ?? '',
  }));

  return { politician_id: politicianId, votes, total, yes_total, no_total, absent_total };
}

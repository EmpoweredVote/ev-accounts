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
  source_etag: string;
  zip_downloaded_at: string | null;
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
  total_raised: string;       // numeric -> string
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
}

function parseRawRecord(rawRecord: string | null): FecRawRecord {
  if (!rawRecord) return {};
  try {
    return JSON.parse(rawRecord) as FecRawRecord;
  } catch {
    return {};
  }
}

function extractDonorType(rawRecord: string | null): string {
  const rec = parseRawRecord(rawRecord);
  const entityType = (rec.entity_type ?? '').toUpperCase().trim();
  if (entityType.startsWith('IND')) return 'individual';
  if (entityType.startsWith('COM') || entityType.startsWith('PAC')) return 'pac';
  if (rec.contributor_committee_id) return 'pac';
  if (entityType !== '') return 'pac';
  return 'unknown';
}

function extractOccupation(rawRecord: string | null): string {
  return parseRawRecord(rawRecord).contributor_occupation ?? '';
}

function extractEmployer(rawRecord: string | null): string {
  return parseRawRecord(rawRecord).contributor_employer ?? '';
}

function extractContributorName(rawRecord: string | null): string {
  return parseRawRecord(rawRecord).contributor_name ?? '';
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
// getSummary — ported from SummaryHandler in public_handlers.go
// ---------------------------------------------------------------------------

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
  const effectiveCycle = cycle ?? defaultCompletedCycle();
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

  // Return zero-state when no data found — not 404
  if (availableCycles.length === 0) {
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
       COUNT(*) AS contribution_count,
       COALESCE(MIN(CASE c.confidence_level
           WHEN 'HIGH'      THEN 1
           WHEN 'MEDIUM'    THEN 2
           WHEN 'ESTIMATED' THEN 3
           ELSE 4 END), 0) AS confidence_level_n,
       COALESCE(SUM(CASE WHEN c.raw_record->>'entity_type' LIKE 'IND%' THEN c.amount ELSE 0 END), 0) AS individual_total,
       COALESCE(SUM(CASE WHEN c.raw_record->>'entity_type' NOT LIKE 'IND%' OR c.raw_record->>'entity_type' IS NULL THEN c.amount ELSE 0 END), 0) AS pac_total
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

  // Query occupations for sector breakdown (TypeScript-side classification)
  const occResult = await pool.query<OccupationRow>(
    `SELECT
       COALESCE(c.raw_record->>'contributor_occupation', '') AS occupation,
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
       COALESCE(c.raw_record->>'contributor_name', '') AS contributor_name,
       SUM(c.amount) AS total_amount,
       COUNT(*) AS contribution_count,
       MIN(CASE c.confidence_level
           WHEN 'HIGH'      THEN 1
           WHEN 'MEDIUM'    THEN 2
           WHEN 'ESTIMATED' THEN 3
           ELSE 4 END) AS confidence_level_n,
       (array_agg(c.raw_record ORDER BY c.amount DESC))[1] AS raw_record
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON c.politician_source_id = ps.id
     WHERE ps.essentials_politician_id = $1
       AND c.election_cycle = $2
       AND ps.research_status = 'confirmed'
       ${confidenceClause}
     GROUP BY c.raw_record->>'contributor_name'
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

  // Query last_sync_at for FEC freshness header
  const metaResult = await pool.query<MetaRow>(
    `SELECT last_sync_at
     FROM transparent_motivations.data_source_metadata
     WHERE source_system = 'fec'
     LIMIT 1`
  );
  const lastSyncAt = metaResult.rows[0]?.last_sync_at ?? null;

  const summary: SummaryResponse = {
    politician_id: politicianId,
    cycle: effectiveCycle,
    total_raised: Number(tRow?.total_raised ?? 0),
    contribution_count: Number(tRow?.contribution_count ?? 0),
    confidence_level: overallConfidence,
    data_source: 'fec',
    last_sync_at: lastSyncAt,
    available_cycles: availableCycles,
    individual_total: Number(tRow?.individual_total ?? 0),
    pac_total: Number(tRow?.pac_total ?? 0),
    sector_breakdown: sectorBreakdown,
    top_donors: topDonors,
  };

  return { summary, updatedAt: lastSyncAt };
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
  const effectiveCycle = options.cycle ?? defaultCompletedCycle();
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
       c.raw_record
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
      donor_name: extractContributorName(row.raw_record),
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

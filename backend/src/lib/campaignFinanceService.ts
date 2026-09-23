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

/**
 * CompositionResponse — authoritative FEC breakdown of total receipts for the grassroots
 * composition bar (quick-032). Grassroots (unitemized ≤$200) is computed from FEC's authoritative
 * summary figures, NOT from ingested itemized rows, and its share is against the authoritative
 * total. Present only for politicians with a cached FEC totals row and total>0. See
 * .planning/decisions/DISCLOSURE-THRESHOLD-POLICY.md.
 */
export interface CompositionResponse {
  source: 'fec';
  total: number;              // authoritative FEC receipts
  grassroots: number;         // individual_unitemized (≤$200, never named)
  large_individual: number;   // individual_itemized (>$200, named in top donors)
  pac_committee: number;      // PAC + party committee contributions
  self_funding: number;       // candidate_contribution
  other: number;              // max(0, total - the four buckets above)
  grassroots_share: number;   // grassroots / total, 0..1
}

/**
 * PacEntry / PacListResponse — the itemized "PACs & committees" list (quick-032). Built from
 * contributions with entity_type IN ('PAC','PTY') — real political action committees + party
 * committees, which match FEC's authoritative PAC figure almost exactly. This deliberately EXCLUDES
 * self-funding (CAN), joint-fundraising/victory-fund transfers (COM), and candidate-committee
 * transfers (CCM), which the entity-based individual/PAC split wrongly lumps into "PAC" (see
 * memory project_pac_classification). Names support click-through: internal donor search + an
 * FEC.gov committee search link.
 */
export interface PacEntry {
  name: string;
  entity_type: string;        // 'PAC' | 'PTY'
  total_amount: number;
  contribution_count: number;
}
export interface PacListResponse {
  pacs: PacEntry[];           // top PACs/party committees by amount
  total_amount: number;       // sum across ALL PAC/PTY rows (not just the top listed)
  count: number;              // number of distinct PAC/party committees on file
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
  composition?: CompositionResponse;
  pac_contributions?: PacListResponse;
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
  // FEC / Socrata / Netfile use entity_type. Classify consistently with the individual/PAC split
  // (see PAC_CASE_SQL): IND + CAN (candidate/self) are people; PAC + PTY are true PACs; other
  // committees/orgs (COM/CCM/ORG) are 'committee' (building icon) but NOT labeled a PAC — this
  // stops self-funding and victory-fund transfers from showing up as PACs.
  const entityType = (rec.entity_type ?? '').toUpperCase().trim();
  if (entityType.startsWith('IND') || entityType.startsWith('CAN')) return 'individual';
  if (entityType.startsWith('PAC') || entityType.startsWith('PTY')) return 'pac';
  if (entityType.startsWith('COM') || entityType.startsWith('CCM') || entityType.startsWith('ORG')) return 'committee';
  if (rec.contributor_committee_id) return 'committee';
  if (entityType !== '') return 'committee';
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
 *   - 'data_pending'       — has a confirmed committee but no contributions ingested yet
 *   - 'local_unavailable'  — local/county office; filings are paper/offline
 *   - 'no_data'            — federal/state office with no confirmed committee on file
 */
async function detectCoverageStatus(politicianId: string): Promise<string> {
  // Count candidate_committee sources only — ie_committee rows represent PAC/IE spending
  // linked to this politician's race, not the politician's own fundraising committee.
  // A politician with only ie_committee sources has genuinely no candidate fundraising.
  //
  // Confirmed links only, like every other read in this file. 'data_pending' renders as
  // "filings for this candidate have been sourced and are being processed", and the ingestion
  // scheduler reads confirmed links only, so no other status is a filing on its way:
  // 'disputed' and 'not_applicable' are the wrong committee, and 'needs_research' is an
  // unchecked surname match (migration 1792) that waiting will never turn into data.
  //
  // ⚠ Until 2026-09-23 this count had no research_status filter. Migration 1792 and the
  // committee-link audits CA_0166, CA_0174, CA_0177 and CA_0178 all say every read path requires
  // 'confirmed' and nothing reads 'needs_research' — that was false here: their demoted and
  // disputed links kept the pending banner up. Fixing it moved 343 active politicians off
  // 'data_pending' (248 to 'local_unavailable', 95 to 'no_data'; measured on prod that day).
  // Admin CRUD and write-path lookups aside, the one read that still counts every status is
  // HAS_ANY_CONTRIBUTION_SQL (donorCoverage.ts), deliberately, for the admin coverage maps.
  const sourceCountResult = await pool.query<{ cnt: string }>(
    `SELECT COUNT(*) AS cnt
     FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1
       AND source_type = 'candidate_committee'
       AND research_status = 'confirmed'`,
    [politicianId]
  );
  const sourceCount = Number(sourceCountResult.rows[0]?.cnt ?? 0);

  if (sourceCount > 0) {
    return 'data_pending';
  }

  // No source rows — check the politician's office district_type
  const officeResult = await pool.query<{ district_type: string | null }>(
    `SELECT d.district_type
     -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
     FROM essentials.office_current_holder och
     JOIN essentials.offices o ON o.id = och.office_id
     LEFT JOIN essentials.districts d ON d.id = o.district_id
     WHERE och.politician_id = $1 AND o.is_vacant = false
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
 * getFecComposition returns FEC's authoritative receipt composition for a politician's confirmed
 * FEC source(s) in a cycle, summed from the cached fec_candidate_totals table (quick-032). Used to
 * build the grassroots composition bar. Returns null when no cached composition exists (pre-
 * migration, non-FEC politician, or totals row without a receipts figure) so the UI simply omits
 * the bar. Grassroots (unitemized) is FEC-authoritative — never derived from ingested rows.
 */
async function getFecComposition(
  politicianId: string,
  cycle: string
): Promise<CompositionResponse | null> {
  try {
    const r = await pool.query<{
      total: string | null; grassroots: string | null; large_individual: string | null;
      pac: string | null; party: string | null; self_contrib: string | null; self_loans: string | null;
    }>(
      `SELECT SUM(t.receipts)              AS total,
              SUM(t.individual_unitemized) AS grassroots,
              SUM(t.individual_itemized)   AS large_individual,
              SUM(t.pac_contributions)     AS pac,
              SUM(t.party_contributions)   AS party,
              SUM(t.candidate_self)        AS self_contrib,
              SUM(t.candidate_loans)       AS self_loans
       FROM transparent_motivations.fec_candidate_totals t
       JOIN transparent_motivations.politician_sources ps
         ON ps.external_id = t.external_id
       WHERE ps.essentials_politician_id = $1
         AND ps.source_system LIKE 'fec%'
         AND ps.research_status = 'confirmed'
         AND t.cycle = $2`,
      [politicianId, cycle]
    );
    const row = r.rows[0];
    const total = Number(row?.total ?? 0);
    // Need an authoritative total AND at least the grassroots figure to be meaningful.
    if (!row || total <= 0 || row.grassroots == null) return null;

    const grassroots = Number(row.grassroots ?? 0);
    const large_individual = Number(row.large_individual ?? 0);
    const pac_committee = Number(row.pac ?? 0) + Number(row.party ?? 0);
    // Self-funders usually LOAN their campaign rather than contribute — count both.
    const self_funding = Number(row.self_contrib ?? 0) + Number(row.self_loans ?? 0);
    const other = Math.max(0, total - grassroots - large_individual - pac_committee - self_funding);
    return {
      source: 'fec',
      total,
      grassroots,
      large_individual,
      pac_committee,
      self_funding,
      other,
      grassroots_share: grassroots / total,
    };
  } catch {
    // Table/columns may not exist yet (pre-migration) — omit the bar.
    return null;
  }
}

const PAC_LIST_LIMIT = 25;

/**
 * getPacContributions returns the itemized "PACs & committees" list for a politician + cycle,
 * from contributions with entity_type IN ('PAC','PTY'). Real PACs + party committees only —
 * excludes self-funding, victory-fund/JFC transfers, and candidate-committee transfers that the
 * entity-based split misclassifies as PAC (see project_pac_classification). Returns null when the
 * politician has no PAC/party rows for the cycle. Scoped to the politician's confirmed sources so
 * it only scans that politician's contributions (fast), never the whole table.
 */
async function getPacContributions(
  politicianId: string,
  cycle: string
): Promise<PacListResponse | null> {
  // Totals across ALL PAC/party rows (not just the top listed).
  const totalsRes = await pool.query<{ total: string | null; count: string }>(
    `SELECT COALESCE(SUM(c.amount), 0) AS total, COUNT(DISTINCT ${DONOR_NAME_SQL}) AS count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1 AND ps.research_status = 'confirmed'
       AND c.election_cycle = $2
       AND c.raw_record->>'entity_type' IN ('PAC', 'PTY')`,
    [politicianId, cycle]
  );
  const total = Number(totalsRes.rows[0]?.total ?? 0);
  const count = Number(totalsRes.rows[0]?.count ?? 0);
  if (count === 0 || total <= 0) return null;

  const listRes = await pool.query<{ name: string; entity_type: string; total: string; n: string }>(
    `SELECT ${DONOR_NAME_SQL} AS name,
            MAX(c.raw_record->>'entity_type') AS entity_type,
            SUM(c.amount) AS total,
            COUNT(*) AS n
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1 AND ps.research_status = 'confirmed'
       AND c.election_cycle = $2
       AND c.raw_record->>'entity_type' IN ('PAC', 'PTY')
     GROUP BY ${DONOR_NAME_SQL}
     ORDER BY total DESC
     LIMIT ${PAC_LIST_LIMIT}`,
    [politicianId, cycle]
  );

  const pacs: PacEntry[] = listRes.rows
    .filter((r) => r.name && r.name.trim() !== '')
    .map((r) => ({
      name: r.name,
      entity_type: r.entity_type ?? 'PAC',
      total_amount: Number(r.total),
      contribution_count: Number(r.n),
    }));

  return { pacs, total_amount: total, count };
}

// ---------------------------------------------------------------------------
// Pre-aggregation layer (quick-030 Task 4)
//
// refreshSummaryAgg recomputes one (politician_source_id, election_cycle) row of
// transparent_motivations.contribution_summary_agg from the contributions table, so
// getSummary can read the tiny agg table instead of scanning the multi-GB contributions
// table. Cost moves from every profile READ to each ingest WRITE. Called from
// runIngestion after a pair's upsert and by the one-time backfill script.
// ---------------------------------------------------------------------------

/** Individual/PAC split — identical CASE logic to getSummary's live totals query. */
// Individual vs PAC/committee split. FEC entity types: IND (individual), CAN (candidate/self),
// CCM (candidate committee transfer), COM (committee incl. joint-fundraising/victory funds),
// ORG (organization), PAC (political action committee), PTY (party committee).
// PAC = real PACs + party committees ONLY. The old logic counted "anything not IND" as PAC, which
// grossly overstated PAC money by lumping in self-funding (CAN), victory-fund/JFC transfers
// (COM/CCM), and orgs (ORG) — e.g. a self-funder's own loans or a candidate's victory fund showed
// as "PAC." 'PAC'+'PTY' matches FEC's authoritative PAC figure (see project_pac_classification).
// Self-funding, transfers, and orgs fall into NEITHER bucket (honestly not individual-donor money
// nor PAC money); the difference from total_raised is those + unitemized.
const INDIVIDUAL_CASE_SQL = `CASE
  WHEN c.raw_record->>'type' IN ('direct', 'in_kind')
    OR c.raw_record->>'entity_type' LIKE 'IND%'
  THEN c.amount ELSE 0 END`;
const PAC_CASE_SQL = `CASE
  WHEN c.raw_record->>'type' IN ('pac', 'corporate_direct')
    OR c.raw_record->>'entity_type' IN ('PAC', 'PTY')
  THEN c.amount ELSE 0 END`;
const CONFIDENCE_RANK_SQL = `CASE c.confidence_level
  WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 WHEN 'ESTIMATED' THEN 3 ELSE 4 END`;
/** Donor name coalesce — identical to getSummary's live top-donor grouping key. */
const DONOR_NAME_SQL = `COALESCE(c.raw_record->>'contributor_name', c.raw_record->>'con_name', NULLIF(trim(concat(c.raw_record->>'Tran_NamL', ' ', c.raw_record->>'Tran_NamF')), ''), c.donor_name_normalized, '')`;

/** How many donors to persist per source+cycle. > the 20 getSummary returns, so a merge
 *  across a politician's sources still yields the correct global top 20 in the common case. */
const AGG_TOP_DONORS = 40;

const confidenceRank = (label: string): number =>
  label === 'HIGH' ? 1 : label === 'MEDIUM' ? 2 : label === 'ESTIMATED' ? 3 : 4;

/**
 * refreshSummaryAgg recomputes the agg row for one (politician_source_id, election_cycle).
 * Idempotent (upsert). Deletes the row when the pair has no contributions. Best-effort:
 * throws are the caller's to swallow so an agg failure never fails an ingest.
 */
export async function refreshSummaryAgg(politicianSourceId: string, cycle: string): Promise<void> {
  const totalsRes = await pool.query<{
    contribution_count: string; total_amount: string; confidence_min: string;
    individual_total: string; pac_total: string; data_source: string | null;
  }>(
    `SELECT COUNT(*) AS contribution_count,
            COALESCE(SUM(c.amount), 0) AS total_amount,
            COALESCE(MIN(${CONFIDENCE_RANK_SQL}), 1) AS confidence_min,
            COALESCE(SUM(${INDIVIDUAL_CASE_SQL}), 0) AS individual_total,
            COALESCE(SUM(${PAC_CASE_SQL}), 0) AS pac_total,
            MAX(c.data_source) AS data_source
     FROM transparent_motivations.contributions c
     WHERE c.politician_source_id = $1 AND c.election_cycle = $2`,
    [politicianSourceId, cycle]
  );
  const t = totalsRes.rows[0];
  const count = Number(t?.contribution_count ?? 0);

  if (count === 0) {
    await pool.query(
      `DELETE FROM transparent_motivations.contribution_summary_agg
       WHERE politician_source_id = $1 AND election_cycle = $2`,
      [politicianSourceId, cycle]
    );
    return;
  }

  // Sector rollup — group by occupation (few distinct values) then classify in TS,
  // exactly as the live getSummary path does. Store ALL sectors (getSummary takes top 10).
  const occRes = await pool.query<{ occupation: string; total: string; count: string }>(
    `SELECT COALESCE(c.raw_record->>'contributor_occupation', c.raw_record->>'con_occp', '') AS occupation,
            SUM(c.amount) AS total, COUNT(*) AS count
     FROM transparent_motivations.contributions c
     WHERE c.politician_source_id = $1 AND c.election_cycle = $2
     GROUP BY 1`,
    [politicianSourceId, cycle]
  );
  const sectorAccum = new Map<string, { total: number; count: number }>();
  for (const row of occRes.rows) {
    const sector = classifySector(row.occupation);
    const acc = sectorAccum.get(sector) ?? { total: 0, count: 0 };
    acc.total += Number(row.total);
    acc.count += Number(row.count);
    sectorAccum.set(sector, acc);
  }
  const sectorBreakdown: SectorEntry[] = Array.from(sectorAccum.entries())
    .map(([sector, acc]) => ({ sector, total: acc.total, count: acc.count }))
    .sort((a, b) => b.total - a.total);

  // Top donors for this source+cycle.
  const donorRes = await pool.query<{
    contributor_name: string; total_amount: string; contribution_count: string;
    confidence_level_n: string; raw_record: object | string | null;
  }>(
    `SELECT ${DONOR_NAME_SQL} AS contributor_name,
            SUM(c.amount) AS total_amount,
            COUNT(*) AS contribution_count,
            MIN(${CONFIDENCE_RANK_SQL}) AS confidence_level_n,
            MIN(c.raw_record::text)::jsonb AS raw_record
     FROM transparent_motivations.contributions c
     WHERE c.politician_source_id = $1 AND c.election_cycle = $2
     GROUP BY ${DONOR_NAME_SQL}
     ORDER BY total_amount DESC
     LIMIT ${AGG_TOP_DONORS}`,
    [politicianSourceId, cycle]
  );
  const topDonors: TopDonorEntry[] = donorRes.rows.map((row) => {
    const occ = extractOccupation(row.raw_record);
    return {
      name: row.contributor_name,
      donor_type: extractDonorType(row.raw_record),
      employer: extractEmployer(row.raw_record),
      occupation: occ,
      sector: classifySector(occ),
      total_amount: Number(row.total_amount),
      contribution_count: Number(row.contribution_count),
      confidence_level: confidenceLabel[Number(row.confidence_level_n)] ?? '',
    };
  });

  await pool.query(
    `INSERT INTO transparent_motivations.contribution_summary_agg
       (politician_source_id, election_cycle, data_source, contribution_count, total_amount,
        individual_total, pac_total, confidence_min, sector_breakdown, top_donors, refreshed_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10::jsonb, now())
     ON CONFLICT (politician_source_id, election_cycle) DO UPDATE SET
       data_source        = EXCLUDED.data_source,
       contribution_count = EXCLUDED.contribution_count,
       total_amount       = EXCLUDED.total_amount,
       individual_total   = EXCLUDED.individual_total,
       pac_total          = EXCLUDED.pac_total,
       confidence_min     = EXCLUDED.confidence_min,
       sector_breakdown   = EXCLUDED.sector_breakdown,
       top_donors         = EXCLUDED.top_donors,
       refreshed_at       = now()`,
    [
      politicianSourceId, cycle, t?.data_source ?? '', count,
      Number(t?.total_amount ?? 0), Number(t?.individual_total ?? 0), Number(t?.pac_total ?? 0),
      Number(t?.confidence_min ?? 1), JSON.stringify(sectorBreakdown), JSON.stringify(topDonors),
    ]
  );
}

/**
 * refreshSummaryAggForSource refreshes the agg for every election_cycle present for a
 * politician_source (a single pair-ingest can touch multiple cycles for non-FEC sources).
 * Called from runIngestion after a successful upsert.
 *
 * Cycles are read from the agg table too, not only from contributions: an ingest that
 * PRUNES rows (Cal-Access drops superseded amendments) can empty a cycle, and a cycle with
 * no contributions left would otherwise never be revisited, leaving its agg row stale.
 * refreshSummaryAgg deletes the agg row for such a cycle.
 */
export async function refreshSummaryAggForSource(politicianSourceId: string): Promise<void> {
  const cyclesRes = await pool.query<{ election_cycle: string }>(
    `SELECT election_cycle FROM transparent_motivations.contributions
     WHERE politician_source_id = $1
     UNION
     SELECT election_cycle FROM transparent_motivations.contribution_summary_agg
     WHERE politician_source_id = $1`,
    [politicianSourceId]
  );
  for (const r of cyclesRes.rows) {
    await refreshSummaryAgg(politicianSourceId, r.election_cycle);
  }
}

interface AggRow {
  election_cycle: string;
  data_source: string;
  contribution_count: string;
  total_amount: string;
  individual_total: string;
  pac_total: string;
  confidence_min: number;
  sector_breakdown: SectorEntry[];
  top_donors: TopDonorEntry[];
}

/**
 * getSummaryFromAgg builds the summary from the pre-aggregated table, merging across a
 * politician's confirmed sources. Returns null when the agg cannot serve the request
 * (politician not backfilled yet, or the requested cycle has no agg row) so getSummary
 * transparently falls back to the live-scan path. Only used when no confidence filter is
 * applied — the agg is precomputed unfiltered.
 */
async function getSummaryFromAgg(
  politicianId: string,
  cycle?: string
): Promise<{ summary: SummaryResponse; updatedAt: string | null } | null> {
  const cyclesRes = await pool.query<CycleRow>(
    `SELECT DISTINCT a.election_cycle
     FROM transparent_motivations.contribution_summary_agg a
     JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
     WHERE ps.essentials_politician_id = $1 AND ps.research_status = 'confirmed'
     ORDER BY a.election_cycle DESC`,
    [politicianId]
  );
  if (cyclesRes.rows.length === 0) return null; // not backfilled / no itemized data — fall back

  const availableCycles = cyclesRes.rows.map((r) => r.election_cycle);
  const effectiveCycle = cycle ?? availableCycles[0] ?? defaultCompletedCycle();

  const rowsRes = await pool.query<AggRow>(
    `SELECT a.election_cycle, a.data_source, a.contribution_count, a.total_amount,
            a.individual_total, a.pac_total, a.confidence_min, a.sector_breakdown, a.top_donors
     FROM transparent_motivations.contribution_summary_agg a
     JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
     WHERE ps.essentials_politician_id = $1 AND a.election_cycle = $2 AND ps.research_status = 'confirmed'`,
    [politicianId, effectiveCycle]
  );
  // Politician has agg for other cycles but not this one — let the live path serve it.
  if (rowsRes.rows.length === 0) return null;

  let contributionCount = 0;
  let individualTotal = 0;
  let pacTotal = 0;
  let itemizedTotal = 0;
  let nonFecTotal = 0;
  let confMin = 4;
  const sectorAccum = new Map<string, { total: number; count: number }>();
  const donorAccum = new Map<string, TopDonorEntry>();
  const dataSourceCount = new Map<string, number>();

  for (const row of rowsRes.rows) {
    const cnt = Number(row.contribution_count);
    contributionCount += cnt;
    individualTotal += Number(row.individual_total);
    pacTotal += Number(row.pac_total);
    itemizedTotal += Number(row.total_amount);
    if (row.data_source !== 'fec') nonFecTotal += Number(row.total_amount);
    confMin = Math.min(confMin, Number(row.confidence_min));
    dataSourceCount.set(row.data_source, (dataSourceCount.get(row.data_source) ?? 0) + cnt);

    for (const s of row.sector_breakdown ?? []) {
      const acc = sectorAccum.get(s.sector) ?? { total: 0, count: 0 };
      acc.total += Number(s.total);
      acc.count += Number(s.count);
      sectorAccum.set(s.sector, acc);
    }
    for (const d of row.top_donors ?? []) {
      const existing = donorAccum.get(d.name);
      if (existing) {
        existing.total_amount += Number(d.total_amount);
        existing.contribution_count += Number(d.contribution_count);
        if (confidenceRank(d.confidence_level) < confidenceRank(existing.confidence_level)) {
          existing.confidence_level = d.confidence_level;
        }
      } else {
        donorAccum.set(d.name, {
          ...d,
          total_amount: Number(d.total_amount),
          contribution_count: Number(d.contribution_count),
        });
      }
    }
  }

  const sectorBreakdown: SectorEntry[] = Array.from(sectorAccum.entries())
    .map(([sector, acc]) => ({ sector, total: acc.total, count: acc.count }))
    .sort((a, b) => b.total - a.total)
    .slice(0, 10);

  const topDonors: TopDonorEntry[] = Array.from(donorAccum.values())
    .sort((a, b) => b.total_amount - a.total_amount)
    .slice(0, 20);

  const overallConfidence = confidenceLabel[confMin] ?? 'HIGH';
  const primaryDataSource = Array.from(dataSourceCount.entries())
    .sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'fec';

  // Headline stays authoritative FEC receipts + non-FEC itemized (unchanged from live path).
  const authoritativeFec = await getAuthoritativeFecTotal(politicianId, effectiveCycle);
  const effectiveTotalRaised =
    authoritativeFec != null ? authoritativeFec + nonFecTotal : itemizedTotal;

  const sourceSystemMap: Record<string, string> = {
    fec: 'fec', indiana: 'indiana_zip_etag_2026', cal_access: 'cal_access', la_city: 'la_city',
  };
  const metaSourceSystem = sourceSystemMap[primaryDataSource] ?? primaryDataSource;
  const metaResult = await pool.query<MetaRow>(
    `SELECT last_sync_at FROM transparent_motivations.data_source_metadata
     WHERE source_system = $1 LIMIT 1`,
    [metaSourceSystem]
  );
  const lastSyncAt = metaResult.rows[0]?.last_sync_at ?? null;

  const outsideSpending = await getOutsideSpendingForPolitician(politicianId);
  const composition = await getFecComposition(politicianId, effectiveCycle);
  const pacContributions = await getPacContributions(politicianId, effectiveCycle);

  const summary: SummaryResponse = {
    politician_id: politicianId,
    cycle: effectiveCycle,
    total_raised: effectiveTotalRaised,
    contribution_count: contributionCount,
    confidence_level: overallConfidence,
    data_source: primaryDataSource,
    last_sync_at: lastSyncAt,
    available_cycles: availableCycles,
    individual_total: individualTotal,
    pac_total: pacTotal,
    sector_breakdown: sectorBreakdown,
    top_donors: topDonors,
    ...(composition ? { composition } : {}),
    ...(pacContributions ? { pac_contributions: pacContributions } : {}),
    outside_spending: outsideSpending,
  };
  return { summary, updatedAt: lastSyncAt };
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

  // Fast path: serve from the pre-aggregated table when no confidence filter is applied
  // (the agg is precomputed unfiltered). Falls through to the live-scan path below when
  // the politician has no agg rows yet (pre-backfill) or the requested cycle has none.
  if (confidenceFilter === null) {
    try {
      const fast = await getSummaryFromAgg(politicianId, cycle);
      if (fast) return fast;
    } catch (err) {
      console.warn('[campaignFinanceService] agg fast-path failed, falling back to live scan:', err instanceof Error ? err.message : String(err));
    }
  }

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
       -- PAC = real PACs + party committees only (see INDIVIDUAL_CASE_SQL/PAC_CASE_SQL comment);
       -- excludes self-funding (CAN), victory-fund/JFC + candidate transfers (COM/CCM), orgs (ORG).
       COALESCE(SUM(CASE
           WHEN c.raw_record->>'type' IN ('pac', 'corporate_direct')
             OR c.raw_record->>'entity_type' IN ('PAC', 'PTY')
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
  const composition = await getFecComposition(politicianId, effectiveCycle);
  const pacContributions = await getPacContributions(politicianId, effectiveCycle);

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
    ...(composition ? { composition } : {}),
    ...(pacContributions ? { pac_contributions: pacContributions } : {}),
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
 * Normalizes the raw query via normalizeDonorName() before any SQL, fuzzy-matches
 * names against the distinct-donor-names matview (donor_names_search) with pg_trgm
 * word_similarity + GIN, then aggregates the matched names' contributions grouped
 * by politician. (Matching the matview, not the 26.9M-row contributions table, is
 * what keeps common surnames fast — see the donor_matches CTE note below.)
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
      -- Fuzzy-match against the distinct-donor-names matview
      -- (transparent_motivations.donor_names_search), NOT the 26.9M-row contributions table.
      -- A common surname like 'smith' is trigram-similar to ~231K contribution rows, so matching
      -- there forced a word_similarity recheck over ~1M heap rows (~58s). The matview holds each
      -- confirmed donor name once, so the recheck runs over distinct names and returns in well
      -- under a second. ORDER BY similarity so the LIMIT 50 keeps the best matches (the old
      -- unordered LIMIT picked an arbitrary 50). Matview is refreshed nightly (migration 1387).
      SELECT dn.donor_name_normalized
      FROM transparent_motivations.donor_names_search dn
      WHERE dn.donor_name_normalized operator(extensions.%>) $1
        AND extensions.word_similarity($1, dn.donor_name_normalized) >= ${threshold}
      ORDER BY extensions.word_similarity($1, dn.donor_name_normalized) DESC
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
    -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
    -- is_vacant constrains the MATCH, not a downstream join: an office that holds a current term
    -- while still flagged is_vacant would otherwise add a duplicate row with no office label, and
    -- this query has no DISTINCT ON to absorb that. Migration 1465 reconciled the 5 offices that
    -- were in that state, so the count is 0 today -- the shape stays because nothing PREVENTS the
    -- state recurring (a stale roster sync is all it takes) and the derived join is correct either
    -- way.
    LEFT JOIN (
      SELECT och.politician_id AS holder_id, o.*
        FROM essentials.office_current_holder och
        JOIN essentials.offices o ON o.id = och.office_id
       WHERE o.is_vacant = false
    ) o ON o.holder_id = p.id
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

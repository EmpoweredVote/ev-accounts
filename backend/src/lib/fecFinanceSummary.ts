/**
 * fecFinanceSummary.ts — the federal finance_summary writer, shared by the CLI script and the job.
 *
 *   scripts/run-fec-finance-summary.ts   by hand: full run, --dry-run, --candidates-only, --politician
 *   job `fec-finance-summary`            scheduled: runFecFinanceSummaryJob() — stalest first, capped
 *
 * Populates `essentials.politicians.finance_summary` for every active federal politician —
 * sitting senators and representatives, the candidates seated on migration-196
 * "Candidate for U.S. Senate — <State>" placeholders, and anyone in an upcoming federal race
 * (race_candidates, same predicate as fecResearch's queue) — using the FEC API.
 *
 * This is the ONLY writer of finance_summary for federal politicians. Senate candidates used to
 * have their own script (senate-candidate-fec.ts, deleted): it re-searched FEC for IDs that
 * fecResearch's auto-match queue now owns, and deleted and rewrote confirmed politician_sources
 * rows as it went.
 *
 * CLI usage: tsx scripts/run-fec-finance-summary.ts [--dry-run] [--candidates-only] [--politician <uuid> ...]
 *   --dry-run          Resolve every FEC ID and print the plan. No FEC calls, no DB writes.
 *   --candidates-only  Only politicians whose chosen office is sought, not held: a "Candidate for …"
 *                      placeholder or an upcoming federal race row.
 *   --politician <id>  Only this essentials.politicians id; repeat the flag for several. For a
 *                      refresh after an FEC-ID fix (CA_0230 corrected six at once) without a
 *                      two-hour full run. Each id must resolve to an active federal politician
 *                      the full run would summarise, or the script exits before any FEC call.
 *
 * Requires environment variables:
 *   DATABASE_URL   — PostgreSQL connection string (in .env)
 *   FEC_API_KEY    — FEC API key (register at api.data.gov/signup/). Not needed for --dry-run.
 *
 * One office per person. A politician can hold a seat AND seek one — nine sitting
 * Representatives were running for Senate on 2026-09-23 — and finance_summary is one column read
 * without office context, so one committee has to win. The SOUGHT seat wins: FEC showed every
 * one of the nine's House committees either filing nothing for 2025-26 (five) or drained into
 * the Senate committee (four, $0-$30 cash left after $0.6M-$2.5M of transfers). The House
 * committee would show a campaign that has already ended.
 *
 * Crosswalk strategy — the FEC ID must be for the CHOSEN office's chamber (ID prefix S or H):
 *   Path 2 (primary): transparent_motivations.politician_sources, research_status = 'confirmed',
 *                     external_id prefixed with the chamber letter
 *   Path 1 (fallback, sitting members only): bioguide_id or full name -> congress-legislators
 *                     YAML -> id.fec[] (YAML source used: theunitedstates.io JSON returned 410 Gone)
 *   A candidate resolves through Path 2 only: the YAML lists sitting members, so a match there is
 *   the committee for the office they hold, never the campaign they are running.
 *
 * FEC API calls per politician:
 *   1. GET /v1/candidates/search/?candidate_id=X  -> committee_id
 *      (fallback: GET /v1/candidate/X/committees/?designation=P)
 *   2. GET /v1/candidates/totals/?candidate_id=X&cycle=2026 -> receipts
 *   3. GET /v1/schedules/schedule_a/by_employer/?committee_id=Y&cycle=2026 -> top donors
 *
 * Rate limit: every FEC call goes through scripts/lib/fecGetJson.ts — the shared limiter
 * (acquireFecSlot, FEC_RATE_LIMIT_PER_MINUTE, default 15/min) plus 429/timeout retry. The key is
 * SHARED with the scheduled ingest and every other session: a private 1500ms sleep here lost 13
 * of 50 people to HTTP 429 on 2026-09-23. At 15/min, --candidates-only (~50 x 3 calls) takes
 * ~10 minutes and a full run (~580 x 3) about 2 hours. Without UPSTASH_REDIS_REST_URL/TOKEN in
 * the environment the limiter counts this process only, not the scheduled job.
 */

import { load as yamlLoad } from 'js-yaml';
import { pool } from './db.js';
import { fecGetJson } from './fecGetJson.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
// Note: theunitedstates.io/congress-legislators/legislators-current.json returned HTTP 410 (Gone) on 2026-06-04.
// Using YAML source from unitedstates/congress-legislators GitHub repo instead (same authoritative data).
// js-yaml is already in backend/package.json (^4.1.1) — no new dependency.
// RESEARCH.md fallback path A1: "Fall back to YAML + js-yaml package; same data, extra parsing step"
const LEGISLATORS_YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';

const FEC_BASE = 'https://api.open.fec.gov/v1';
const FEC_SEARCH_URL = `${FEC_BASE}/candidates/search/`;
const FEC_TOTALS_URL = `${FEC_BASE}/candidates/totals/`;
const FEC_BY_EMPLOYER_URL = `${FEC_BASE}/schedules/schedule_a/by_employer/`;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FecEmployerRow {
  committee_id: string;
  employer: string | null;
  total: number;
  count: number;
  cycle: number;
}

interface FinanceSummary {
  /** Omitted entirely when FEC has no totals row — absent means unknown, never $0. */
  total_raised?: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';
  /** When this summary was written (ISO). The job refreshes the stalest first; absent = never stamped. */
  refreshed_at: string;
}

interface Legislator {
  id: { bioguide: string; fec?: string[] };
  name: { first: string; last: string; official_full?: string };
  terms: Array<{ type: 'sen' | 'rep'; start: string; end: string; state: string }>;
}

interface FederalPolitician {
  id: string;
  bioguide_id: string | null;
  full_name: string;
  /** Chamber of the chosen office — and so the required FEC ID prefix. */
  chamber_short: 'S' | 'H';
  /** The chosen office is a "Candidate for …" placeholder: a seat sought, not held. */
  is_candidate: boolean;
}

// ---------------------------------------------------------------------------
// Crosswalk builders
// ---------------------------------------------------------------------------

interface CrosswalkMaps {
  bioguideMap: Map<string, string>;
  /** Lowercase normalized full-name -> FEC ID. Covers senators without bioguide_id in our DB. */
  nameMap: Map<string, string>;
}

/**
 * Builds bioguide -> FEC candidate_id AND full-name -> FEC candidate_id maps from the
 * congress-legislators YAML source.
 *
 * Background: The theunitedstates.io JSON endpoint returned HTTP 410 Gone on 2026-06-04.
 * YAML from unitedstates/congress-legislators GitHub is the same authoritative data.
 *
 * Most Phase 73-added senators have NULL bioguide_id in the DB — the name map provides
 * a fallback so "Amy Klobuchar" in our DB can match "Amy Klobuchar" in YAML.
 *
 * Filters FEC IDs by chamber (S-prefix for senators, H-prefix for House members).
 * Per Pitfall 4: a legislator can have multiple FEC IDs across chambers — pick the chamber-correct one.
 */
async function buildCrosswalkMaps(): Promise<CrosswalkMaps> {
  console.log('[crosswalk] Fetching congress-legislators YAML from GitHub...');
  const resp = await fetch(LEGISLATORS_YAML_URL, {
    signal: AbortSignal.timeout(60_000),
  });
  if (!resp.ok) {
    throw new Error(`Failed to fetch legislators-current.yaml: HTTP ${resp.status}`);
  }
  const yamlText = await resp.text();
  const legislators = yamlLoad(yamlText) as Legislator[];
  if (!Array.isArray(legislators)) {
    throw new Error('legislators-current.yaml did not parse to an array');
  }
  const bioguideMap = new Map<string, string>();
  const nameMap = new Map<string, string>();
  for (const leg of legislators) {
    if (!leg.id.fec || leg.id.fec.length === 0) continue;
    const lastTerm = leg.terms[leg.terms.length - 1];
    if (!lastTerm) continue;
    const isSenate = lastTerm.type === 'sen';
    // Pick FEC ID matching current chamber (S-prefix for senators, H-prefix for House)
    const fecId =
      leg.id.fec.find(id => (isSenate ? id.startsWith('S') : id.startsWith('H'))) ??
      leg.id.fec[0];
    if (!fecId) continue;
    bioguideMap.set(leg.id.bioguide, fecId);
    // Also add name variants for senators and representatives without bioguide in DB
    const firstName = leg.name.first;
    const lastName = leg.name.last;
    const officialFull = leg.name.official_full;
    // Standard "First Last" format (covers most cases like "Amy Klobuchar")
    nameMap.set(`${firstName} ${lastName}`.toLowerCase(), fecId);
    // Official full name (e.g. "Bernard Sanders" for Bernie Sanders)
    if (officialFull) {
      nameMap.set(officialFull.toLowerCase(), fecId);
    }
  }
  console.log(
    `[crosswalk] Built maps: bioguide=${bioguideMap.size}, name=${nameMap.size} entries.`,
  );
  return { bioguideMap, nameMap };
}

// ---------------------------------------------------------------------------
// DB queries
// ---------------------------------------------------------------------------

/**
 * Returns every active federal politician, one row per person, with the office that decides
 * which FEC committee summarises them.
 *
 * Occupancy is resolved through essentials.office_current_holder -- essentials.offices is a SEAT
 * and holds no occupant (ADR 0002 phase 5 dropped offices.politician_id in migration 1463).
 *
 * 🔴 The join is politician-rooted, so a person comes back once per federal office they hold:
 * a sitting Representative running for Senate is two rows, House seat and Senate placeholder.
 * The old plain DISTINCT kept both (the chamber differs), and a `Candidate for%` exclusion hid
 * the problem by dropping candidates altogether -- which also left every pure candidate without
 * a finance_summary. DISTINCT ON (p.id) keeps one row, and the SOUGHT seat wins (see the header
 * for the evidence). This is the opposite of essentialsService's "a seat held beats a seat
 * sought": that rule picks what to CALL someone; this one picks whose money is live.
 *
 * A state officeholder running for Congress has only the placeholder or the race row among
 * federal offices, so they arrive as a candidate (Justin J. Pearson, TN-9, 2026-09-24).
 *
 * Race rows (added 2026-09-24): an upcoming election, not withdrawn, result empty or 'advanced' —
 * so a primary loser is NOT summarised for a campaign that is over. A sitting member's race for
 * their own chamber is re-election, and is filtered out so they stay "sitting". The earlier
 * counts below predate the race rows. On 2026-09-23 (--dry-run against prod): 580 people — 428
 * representatives, 102 senators (two of them DC's shadow senators, who have no FEC committee and
 * are skipped) and 50 candidates, the nine Representatives above among them.
 */
async function getFederalPoliticiansFromDb(opts: {
  candidatesOnly: boolean;
  only: string[];
  stalestFirst: boolean;
}): Promise<FederalPolitician[]> {
  const sql = `
    SELECT id, bioguide_id, full_name, chamber_short, is_candidate
    FROM (
      SELECT DISTINCT ON (p.id)
        p.id,
        p.bioguide_id,
        p.full_name,
        p.finance_summary,
        -- a confirmed FEC link made or re-checked in the last 14 days: a new person for the job
        EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                 WHERE ps.essentials_politician_id = p.id AND ps.source_system LIKE 'fec%'
                   AND ps.research_status = 'confirmed'
                   AND GREATEST(ps.created_at, ps.updated_at) >= now() - interval '14 days') AS recent_link,
        CASE
          WHEN d.district_type = 'NATIONAL_UPPER' THEN 'S'
          ELSE 'H'
        END AS chamber_short,
        (seat.via_race OR COALESCE(o.title, '') ILIKE 'Candidate for%') AS is_candidate
      FROM essentials.politicians p
      JOIN (
        -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
        SELECT och.politician_id, och.office_id, false AS via_race
          FROM essentials.office_current_holder och
        UNION ALL
        -- The office SOUGHT, from a race that can still send the person to office -- the same
        -- predicate as fecResearch's queue (#723). Most candidates have no "Candidate for"
        -- placeholder seat, so without this they were never summarised: 832 House candidates
        -- with a confirmed FEC link, 1 summary, on 2026-09-24.
        SELECT rc.politician_id, r.office_id, true AS via_race
          FROM essentials.race_candidates rc
          JOIN essentials.races r ON r.id = rc.race_id
          JOIN essentials.elections e ON e.id = r.election_id
         WHERE e.election_date >= CURRENT_DATE
           AND rc.candidate_status IS DISTINCT FROM 'withdrawn'
           AND (rc.result IS NULL OR rc.result = 'advanced')
      ) seat ON seat.politician_id = p.id
      JOIN essentials.offices o ON o.id = seat.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE p.is_active = true
        AND d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
        -- A member running again for their own chamber is re-election, not a new campaign: keep
        -- them "sitting" so their congress-legislators fallback (Path 1) still applies.
        AND NOT (seat.via_race AND EXISTS (
              SELECT 1 FROM essentials.office_current_holder h
                JOIN essentials.offices ho ON ho.id = h.office_id
                JOIN essentials.districts hd ON hd.id = ho.district_id
               WHERE h.politician_id = p.id AND hd.district_type = d.district_type))
      ORDER BY p.id,
               (seat.via_race OR COALESCE(o.title, '') ILIKE 'Candidate for%') DESC,
               seat.via_race ASC,
               o.id
    ) one_per_person
    WHERE ($1::boolean = false OR is_candidate)
      AND (cardinality($2::uuid[]) = 0 OR id = ANY($2::uuid[]))
    -- stalestFirst (the scheduled job), three groups:
    --   0  no summary and a recent FEC link: someone new (fec-auto-match confirmed them this week)
    --   1  a summary, oldest refreshed_at first (written before refreshed_at existed = oldest)
    --   2  no summary and an older link: FEC has an ID but no principal committee (~65 on 2026-09-25).
    --      Last, so they cannot take the cap every day; a new filer still gets 14 daily tries in group 0.
    ORDER BY CASE WHEN $3::boolean THEN
               CASE WHEN finance_summary IS NULL AND recent_link THEN 0
                    WHEN finance_summary IS NOT NULL THEN 1 ELSE 2 END END,
             CASE WHEN $3::boolean THEN finance_summary->>'refreshed_at' END ASC NULLS FIRST,
             full_name
  `;
  const result = await pool.query<FederalPolitician>(sql, [opts.candidatesOnly, opts.only, opts.stalestFirst]);

  // A --politician id that is not an active federal officeholder or candidate would otherwise be a
  // silent no-op: the run "succeeds" having summarised nobody.
  const found = new Set(result.rows.map(r => r.id));
  const missing = opts.only.filter(id => !found.has(id));
  if (missing.length > 0) {
    throw new Error(
      `--politician id(s) not among the active federal politicians this script summarises` +
        `${opts.candidatesOnly ? ' as candidates' : ''}: ${missing.join(', ')}`,
    );
  }
  return result.rows;
}

/**
 * Path 2 crosswalk: look up the confirmed FEC ID for one chamber from
 * transparent_motivations.politician_sources. Returns null if there is none.
 *
 * Bound to the chamber by the ID's own prefix (FEC IDs start H, S or P), not by source_system:
 *   - The old query took ANY confirmed fec% row, newest `created_at` first. created_at is NULL on
 *     nearly every row (3 of 146 fec_senate, 20 of 516 fec_house on 2026-09-23), so for someone
 *     with a House AND a Senate ID the pick was arbitrary.
 *   - source_system is not reliable enough to bind on: five Virginia Representatives carry the
 *     legacy value 'fec', and Roger Marshall's 'fec_senate' row holds his old House ID
 *     (H6KS01179), which FEC shows filing nothing for 2025-26. The prefix skips that row and his
 *     Senate ID comes from Path 1.
 */
async function lookupFecIdViaSources(
  politicianId: string,
  chamber: 'S' | 'H',
): Promise<string | null> {
  const sql = `
    SELECT external_id
    FROM transparent_motivations.politician_sources
    WHERE essentials_politician_id = $1
      AND source_system LIKE 'fec%'
      AND research_status = 'confirmed'
      AND upper(left(external_id, 1)) = $2
    ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id
    LIMIT 1
  `;
  const result = await pool.query<{ external_id: string }>(sql, [politicianId, chamber]);
  return result.rows[0]?.external_id ?? null;
}

/**
 * Resolves the FEC candidate ID for the politician's chosen office:
 *   Path 2 first (politician_sources confirmed rows — highest confidence)
 *   Path 1a (bioguide -> congress-legislators map) — sitting members only
 *   Path 1b (full-name -> congress-legislators name map — for senators without bioguide_id in DB)
 * Every path must yield an ID for the chosen chamber. Returns null if none does.
 */
async function resolveFecId(
  p: FederalPolitician,
  crosswalk: CrosswalkMaps,
): Promise<string | null> {
  // Path 2: politician_sources (primary — catches 2026 candidates already matched)
  const fromSources = await lookupFecIdViaSources(p.id, p.chamber_short);
  if (fromSources) return fromSources;

  // A candidate's ID comes from a confirmed row or not at all. congress-legislators lists sitting
  // members, so a hit there is the committee for the seat they HOLD — for a Representative
  // running for Senate, exactly the drained House committee this script is choosing against.
  // fecResearch's auto-match queue is how a candidate gets a confirmed row.
  if (p.is_candidate) return null;

  // Path 1a: bioguide -> congress-legislators crosswalk (incumbents with bioguide in DB)
  // Path 1b: name-based match for senators/reps without bioguide_id in DB
  // Phase 73 inserted 100 senators without bioguide_id — Path 1b covers them
  const fromBioguide =
    p.bioguide_id && p.bioguide_id.trim() !== '' ? crosswalk.bioguideMap.get(p.bioguide_id) : undefined;
  const fromCrosswalk = fromBioguide ?? crosswalk.nameMap.get(p.full_name.toLowerCase());
  if (!fromCrosswalk) return null;

  // The YAML picks an ID by the legislator's own latest term; our office can disagree (a name
  // collision, or a member who changed chamber). Never summarise the wrong chamber's committee.
  if (!fromCrosswalk.toUpperCase().startsWith(p.chamber_short)) {
    console.warn(
      `  [SKIP] congress-legislators gave ${fromCrosswalk} for ${p.full_name}, ` +
        `but the chosen office is chamber ${p.chamber_short}`,
    );
    return null;
  }
  return fromCrosswalk;
}

// ---------------------------------------------------------------------------
// FEC API calls
// ---------------------------------------------------------------------------

/**
 * Fetches the principal committee ID for an FEC candidate.
 * Required for the by_employer endpoint (committee_id, NOT candidate_id — Pitfall 2).
 */
async function fetchCommitteeId(fecCandidateId: string, apiKey: string): Promise<string | null> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    per_page: '1',
  });
  const data = await fecGetJson<{
    results: Array<{ principal_committees: Array<{ committee_id: string }> }>;
  }>(`${FEC_SEARCH_URL}?${params}`, `candidates/search ${fecCandidateId}`);
  const principal = data.results[0]?.principal_committees?.[0]?.committee_id;
  if (principal) return principal;

  // /candidates/search/ can return no principal_committees for a new filer; the deleted
  // senate-candidate-fec.ts carried this fallback for candidates. designation=P asks for the
  // principal campaign committee only — its unfiltered results[0] could be any authorized one.
  const fallbackParams = new URLSearchParams({ api_key: apiKey, designation: 'P', per_page: '1' });
  const fallbackData = await fecGetJson<{ results?: Array<{ committee_id: string }> }>(
    `${FEC_BASE}/candidate/${encodeURIComponent(fecCandidateId)}/committees/?${fallbackParams}`,
    `candidate/${fecCandidateId}/committees`,
  );
  return fallbackData.results?.[0]?.committee_id ?? null;
}

/**
 * Fetches total raised (receipts) for an FEC candidate in the given cycle.
 *
 * Returns null — NOT 0 — when FEC has no totals row for this candidate+cycle.
 * "We don't know" and "they raised nothing" are different facts and must not
 * collapse onto the same value.
 *
 * ⚠ election_full=false is REQUIRED. It defaults to TRUE, which asks for totals
 * over a candidate's full ELECTION cycle rather than the two-year period. A
 * senator whose election_years are [2022, 2028] has no 2026 election cycle, so
 * cycle=2026 returned zero results and the old `?? 0` recorded that absence as a
 * real $0. That silently zeroed 65 sitting members — e.g. Padilla showed $0
 * against an actual $1,502,700.32, and Mark Kelly against $40,775,022.69.
 * With election_full=false the same call returns the 2025-26 period totals.
 *
 * Per Pitfall 5: always coerce to Number() — never store raw string.
 */
async function fetchTotalRaised(fecCandidateId: string, apiKey: string): Promise<number | null> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    cycle: FEC_CYCLE,
    election_full: 'false',
    per_page: '1',
  });
  const data = await fecGetJson<{ results?: Array<{ receipts?: unknown }> }>(
    `${FEC_TOTALS_URL}?${params}`,
    `candidates/totals ${fecCandidateId}`,
  );
  const row = data.results?.[0];
  if (!row || row.receipts == null) return null;
  const receipts = Number(row.receipts);
  return Number.isFinite(receipts) ? receipts : null;
}

/**
 * Fetches top donors by employer for an FEC committee.
 * Filters out null/empty employer strings.
 * "NOT EMPLOYED" / "SELF EMPLOYED" are kept per RESEARCH.md open question #1.
 * Caps at TOP_DONORS_LIMIT entries.
 */
async function fetchTopDonorsByEmployer(
  committeeId: string,
  apiKey: string,
): Promise<Array<{ employer: string; amount: number; count: number }>> {
  const params = new URLSearchParams({
    api_key: apiKey,
    committee_id: committeeId,
    cycle: FEC_CYCLE,
    per_page: String(TOP_DONORS_LIMIT + 5), // fetch extra to account for null filtering
    sort: '-total',
  });
  const data = await fecGetJson<{ results: FecEmployerRow[] }>(
    `${FEC_BY_EMPLOYER_URL}?${params}`,
    `schedule_a/by_employer ${committeeId}`,
  );
  return data.results
    .filter((r): r is FecEmployerRow & { employer: string } =>
      r.employer != null && r.employer.trim() !== '',
    )
    .slice(0, TOP_DONORS_LIMIT)
    .map(r => ({
      employer: r.employer,
      amount: Number(r.total),
      count: Number(r.count),
    }));
}

/**
 * Writes the finance_summary JSONB to essentials.politicians for the given politician ID.
 * Uses parameterized UPDATE with explicit ::jsonb cast.
 */
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

export interface FinanceSummaryRunOptions {
  /** Resolve FEC IDs and print the plan. No FEC calls, no DB writes. */
  dryRun?: boolean;
  /** Only people whose chosen office is sought, not held. */
  candidatesOnly?: boolean;
  /** Only these essentials.politicians ids. Each must be one the full run would summarise. */
  onlyPoliticians?: string[];
  /** Never-summarised first, then oldest refreshed_at (the job). Default: by name. */
  stalestFirst?: boolean;
  /**
   * Stop after this many people have been sent to FEC (an FEC ID resolved). People with no FEC ID
   * cost no FEC calls and do not count, so ~150 unresolvable people at the front of the queue
   * cannot use up a run. Default: no limit.
   */
  maxFecPeople?: number;
}

export interface FinanceSummaryRunResult {
  dry_run?: true;
  /** People looked at. */
  processed: number;
  /** People sent to FEC (an FEC ID resolved). Under dryRun: IDs resolved. */
  attempted: number;
  /** Under dryRun this counts FEC IDs resolved, not summaries written. */
  succeeded: number;
  skipped_no_fec_id: number;
  errors: number;
  /** People the cap left for a later run. */
  deferred: number;
  durationSec: number;
}

export async function runFecFinanceSummary(opts: FinanceSummaryRunOptions = {}): Promise<FinanceSummaryRunResult> {
  const dryRun = opts.dryRun ?? false;
  const candidatesOnly = opts.candidatesOnly ?? false;
  const only = (opts.onlyPoliticians ?? []).map(id => id.toLowerCase());
  const maxFecPeople = opts.maxFecPeople ?? Infinity;

  // --dry-run makes no FEC calls, so it needs no key.
  if (!dryRun && !process.env.FEC_API_KEY) {
    throw new Error('FEC_API_KEY is not set. Register at https://api.data.gov/signup/');
  }
  const apiKey = process.env.FEC_API_KEY ?? '';
  console.log('[fec-finance-summary] Starting FEC finance summary ingestion...');
  if (dryRun) console.log('[fec-finance-summary] --dry-run: resolving FEC IDs only. No FEC calls, no DB writes.');
  console.log(`[fec-finance-summary] Cycle: ${FEC_CYCLE}`);

  const startMs = Date.now();
  const crosswalk = await buildCrosswalkMaps();
  const politicians = await getFederalPoliticiansFromDb({ candidatesOnly, only, stalestFirst: opts.stalestFirst ?? false });
  const candidateCount = politicians.filter(p => p.is_candidate).length;
  console.log(
    `[fec-finance-summary] Found ${politicians.length} active federal politicians ` +
      `(${candidateCount} summarised as candidates${candidatesOnly ? ', --candidates-only' : ''}` +
      `${only.length > 0 ? `, --politician x${only.length}` : ''}` +
      `${Number.isFinite(maxFecPeople) ? `, at most ${maxFecPeople} sent to FEC` : ''}).`,
  );

  let processed = 0;
  let attempted = 0;
  let succeeded = 0;
  let skipped_no_fec_id = 0;
  let errors = 0;
  const skippedNames: string[] = [];
  const errorDetails: Array<{ name: string; error: string }> = [];

  for (const p of politicians) {
    if (attempted >= maxFecPeople) break;
    processed++;
    const role = p.is_candidate ? 'candidate' : 'sitting';
    console.log(`\n[${processed}/${politicians.length}] ${p.full_name} (${p.chamber_short}, ${role})`);

    try {
      const fecId = await resolveFecId(p, crosswalk);
      if (!fecId) {
        console.warn(
          p.is_candidate
            ? `  [SKIP] No confirmed ${p.chamber_short}-prefixed FEC ID for candidate ${p.full_name} ` +
                `(fecResearch's auto-match queue confirms candidate IDs)`
            : `  [SKIP] No FEC ID found for ${p.full_name} (politician_sources + congress-legislators both empty)`,
        );
        skipped_no_fec_id++;
        skippedNames.push(p.full_name);
        continue;
      }
      attempted++;
      console.log(`  FEC ID: ${fecId}`);

      if (dryRun) {
        succeeded++;
        continue;
      }

      const committeeId = await fetchCommitteeId(fecId, apiKey);
      if (!committeeId) {
        console.warn(`  [SKIP] No principal committee found for ${p.full_name} (${fecId})`);
        skipped_no_fec_id++;
        skippedNames.push(`${p.full_name} (no committee)`);
        continue;
      }
      console.log(`  Committee: ${committeeId}`);

      const totalRaised = await fetchTotalRaised(fecId, apiKey);
      if (totalRaised === null) {
        console.warn(
          `  [WARN] FEC has no ${FEC_CYCLE} totals row for ${p.full_name} (${fecId}) — ` +
            `writing finance_summary WITHOUT total_raised (unknown, not $0).`,
        );
      } else {
        console.log(`  Total raised: $${totalRaised.toLocaleString()}`);
      }

      const topDonors = await fetchTopDonorsByEmployer(committeeId, apiKey);
      console.log(`  Top donors: ${topDonors.length} employer entries`);

      // Build strict finance_summary object (never spread raw FEC response — T-90-04)
      // total_raised is omitted rather than zeroed when FEC has no totals row.
      const summary: FinanceSummary = {
        ...(totalRaised !== null ? { total_raised: totalRaised } : {}),
        top_donors: topDonors,
        cycle: FEC_CYCLE,
        source: 'FEC',
        refreshed_at: new Date().toISOString(),
      };

      await updateFinanceSummary(p.id, summary);
      console.log(`  [OK] finance_summary written.`);
      succeeded++;
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(`  [ERROR] ${p.full_name}: ${errMsg}`);
      errors++;
      errorDetails.push({ name: p.full_name, error: errMsg });
    }
  }

  const result: FinanceSummaryRunResult = {
    ...(dryRun ? { dry_run: true as const } : {}),
    processed,
    attempted,
    succeeded,
    skipped_no_fec_id,
    errors,
    deferred: politicians.length - processed,
    durationSec: Number(((Date.now() - startMs) / 1000).toFixed(1)),
  };

  console.log('\n=== FEC FINANCE SUMMARY RUN COMPLETE ===');
  console.log(JSON.stringify(result));
  if (skippedNames.length > 0) {
    console.log('\n--- Skipped politicians (no FEC ID) ---');
    for (const name of skippedNames) console.log(`  - ${name}`);
  }
  if (errorDetails.length > 0) {
    console.log('\n--- Errored politicians ---');
    for (const e of errorDetails) console.log(`  - ${e.name}: ${e.error}`);
  }
  return result;
}

/** People the scheduled job sends to FEC per run. ~3 calls each at 15/min: 150 is ~30 min. */
export const JOB_DEFAULT_MAX_FEC_PEOPLE = 150;

/**
 * The scheduled entry point (job `fec-finance-summary`). New people first (no summary, FEC link
 * confirmed in the last 14 days), then the oldest refreshed_at, then people FEC has no committee for;
 * it stops after
 * FEC_FINANCE_SUMMARY_MAX_PEOPLE (default 150) people sent to FEC. With ~1,430 resolvable people
 * a daily run turns the whole set over in about ten days, and a person whose FEC link was
 * confirmed that morning (fec-auto-match runs first) is summarised the same day.
 *
 * jobs/run.ts fails a run only when the job throws, and a failed FEC call is counted, not
 * thrown, so a run where EVERY attempt failed (revoked key, FEC down) would exit 0. That case
 * throws here, like runFecAutoMatchJob.
 */
export async function runFecFinanceSummaryJob(): Promise<FinanceSummaryRunResult> {
  const raw = process.env.FEC_FINANCE_SUMMARY_MAX_PEOPLE;
  const max = raw ? Number(raw) : JOB_DEFAULT_MAX_FEC_PEOPLE;
  if (!Number.isInteger(max) || max < 1) {
    throw new Error(`FEC_FINANCE_SUMMARY_MAX_PEOPLE must be a positive integer, got ${JSON.stringify(raw)}`);
  }
  const result = await runFecFinanceSummary({ stalestFirst: true, maxFecPeople: max });
  if (result.attempted > 0 && result.errors === result.attempted) {
    throw new Error(`fec-finance-summary: all ${result.attempted} FEC attempts failed; nothing was written`);
  }
  return result;
}

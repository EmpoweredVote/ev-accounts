/**
 * fecResearch — FEC candidate auto-match service.
 *
 * For each federal politician in essentials.politicians without a confirmed FEC
 * politician_source — a sitting member, or a candidate seated on a migration-196
 * "Candidate for U.S. Senate — <State>" placeholder — searches the FEC candidates
 * API by name + state + office,
 * scores the results, and either auto-confirms a high-confidence match or queues
 * it for human review.
 *
 * Match strategy (in priority order):
 *   1. bioguide_id match (FEC and DB share this ID) → confirmed, score 1.0
 *   2. Normalized last name exact + first name starts-with, 1 candidate → confirmed, score 0.9
 *   3. Normalized last name exact, 1 candidate → needs_research, score 0.6
 *   4. Multiple candidates, unclear match → needs_research, lists all in notes
 *   5. No candidates found → needs_research with note
 *
 * Inserts a politician_sources row for each politician processed.
 * Non-aborting: per-politician errors are logged and counted.
 */

import { pool } from './db.js';
import { createSource } from './campaignFinanceService.js';
import { acquireFecSlot } from './fecRateLimiter.js';

const FEC_CANDIDATES_URL = 'https://api.open.fec.gov/v1/candidates/';
const SLEEP_BETWEEN_SEARCHES_MS = 1500; // stay well under 1000 req/hr

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface UnmatchedPolitician {
  id: string;
  full_name: string;
  bioguide_id: string | null;
  fec_office: 'H' | 'S';
  source_system: 'fec_house' | 'fec_senate';
  representing_state: string;
  /** Queued from a "Candidate for …" placeholder: a seat sought, not held. */
  is_candidate: boolean;
}

export interface FecCandidate {
  candidate_id: string;
  name: string;
  office: string;
  state: string;
  party: string;
  bioguide_id: string | null;
  office_full?: string;
  party_full?: string;
  district?: string;
  election_years?: number[];
  incumbent_challenge_full?: string;
}

export type MatchStatus = 'confirmed' | 'needs_research';

export interface MatchResult {
  politician_id: string;
  politician_name: string;
  status: MatchStatus;
  source_system: string;
  representing_state: string;
  is_candidate: boolean;
  candidates_found: number;
  selected_fec_id: string | null;
  selected_fec_name: string | null;
  confidence: number;
  source_id: string | null;
  notes: string;
  error: string | null;
}

export interface AutoMatchSummary {
  processed: number;
  auto_confirmed: number;
  needs_review: number;
  errors: number;
  results: MatchResult[];
}

// ---------------------------------------------------------------------------
// Name normalization helpers
// ---------------------------------------------------------------------------

const ACCENT_MAP: Record<string, string> = {
  á: 'a', à: 'a', â: 'a', ä: 'a', ã: 'a',
  é: 'e', è: 'e', ê: 'e', ë: 'e',
  í: 'i', ì: 'i', î: 'i', ï: 'i',
  ó: 'o', ò: 'o', ô: 'o', ö: 'o', õ: 'o',
  ú: 'u', ù: 'u', û: 'u', ü: 'u',
  ñ: 'n', ç: 'c',
};

function stripAccents(s: string): string {
  return s
    .toLowerCase()
    .split('')
    .map(c => ACCENT_MAP[c] ?? c)
    .join('');
}

/** Normalize a name for comparison: lowercase, strip accents and punctuation. */
export function normalize(name: string): string {
  return stripAccents(name).replace(/[^a-z\s]/g, '').trim();
}

/**
 * Parse a FEC-format name "LAST, FIRST MIDDLE" into { first, last }.
 * FEC names are uppercase; we normalize after parsing.
 */
export function parseFecName(fecName: string): { first: string; last: string } {
  const commaIdx = fecName.indexOf(',');
  if (commaIdx === -1) {
    // No comma — treat entire name as last name
    return { first: '', last: normalize(fecName) };
  }
  const last = normalize(fecName.slice(0, commaIdx).trim());
  const firstPart = fecName.slice(commaIdx + 1).trim().split(/\s+/)[0] ?? '';
  const first = normalize(firstPart);
  return { first, last };
}

/** Generational suffixes that must not be mistaken for a last name. */
const NAME_SUFFIXES = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);

/**
 * Parse our DB full_name "First [Middle] Last" into { first, last }.
 * Strips trailing generational suffixes (Jr, Sr, II–V) BEFORE picking the last
 * token — otherwise "Nicholas J. Begich III" yields last name "iii" and fails to
 * match the FEC record "BEGICH, NICHOLAS III". Compound last names are handled
 * naively by taking the first token as first name and last token as last name.
 */
export function parseDbName(fullName: string): { first: string; last: string } {
  const tokens = normalize(fullName).split(/\s+/).filter(Boolean);
  // Strip trailing suffix tokens (keep at least one token as the name).
  while (tokens.length > 1 && NAME_SUFFIXES.has(tokens[tokens.length - 1]!)) {
    tokens.pop();
  }
  if (tokens.length === 0) return { first: '', last: '' };
  if (tokens.length === 1) return { first: '', last: tokens[0]! };
  return { first: tokens[0]!, last: tokens[tokens.length - 1]! };
}

// ---------------------------------------------------------------------------
// Match scoring
// ---------------------------------------------------------------------------

export function scoreMatch(politician: UnmatchedPolitician, candidate: FecCandidate): number {
  // bioguide is a reliable identifier when both sides have it
  if (
    politician.bioguide_id &&
    candidate.bioguide_id &&
    politician.bioguide_id === candidate.bioguide_id
  ) {
    return 1.0;
  }

  const db = parseDbName(politician.full_name);
  const fec = parseFecName(candidate.name);

  if (!db.last || !fec.last) return 0;

  const lastMatch = db.last === fec.last;
  if (!lastMatch) return 0;

  // Last name matches — check first name
  if (db.first && fec.first) {
    if (db.first === fec.first) return 0.9;
    if (fec.first.startsWith(db.first) || db.first.startsWith(fec.first)) return 0.85;
  }

  // Last name only match
  return 0.6;
}

// ---------------------------------------------------------------------------
// FEC API search
// ---------------------------------------------------------------------------

export async function searchFecCandidates(
  name: string,
  state: string,
  office: 'H' | 'S',
  apiKey: string
): Promise<FecCandidate[]> {
  const params = new URLSearchParams({
    api_key: apiKey,
    q: name,
    state,
    office,
    per_page: '20',
  });

  // FEC-03: this admin-triggered auto-match path shares the FEC key with the
  // daily cron but not its distributed lock — without the shared limiter it
  // can collide with a concurrent cron run and reintroduce the 429 tail
  // (174-RESEARCH.md Pitfall 2). Acquire before every call, including the
  // last-name fallback search in runFecAutoMatch.
  await acquireFecSlot();
  const response = await fetch(`${FEC_CANDIDATES_URL}?${params.toString()}`, {
    signal: AbortSignal.timeout(30_000),
  });

  if (!response.ok) {
    throw new Error(`FEC candidates search failed: HTTP ${response.status} for "${name}" ${state} ${office}`);
  }

  const data = await response.json() as {
    results: Array<{
      candidate_id: string;
      name: string;
      office: string;
      office_full?: string;
      state: string;
      party: string;
      party_full?: string;
      district?: string;
      election_years?: number[];
      incumbent_challenge_full?: string;
      bioguide_id?: string | null;
    }>;
  };

  return (data.results ?? []).map(r => ({
    candidate_id: r.candidate_id,
    name: r.name,
    office: r.office,
    office_full: r.office_full,
    state: r.state,
    party: r.party,
    party_full: r.party_full,
    district: r.district,
    election_years: r.election_years,
    incumbent_challenge_full: r.incumbent_challenge_full,
    bioguide_id: r.bioguide_id ?? null,
  }));
}

// ---------------------------------------------------------------------------
// DB query — unmatched federal politicians
// ---------------------------------------------------------------------------

// Candidates are queued ON PURPOSE (ruling 2026-09-23, Chris Andrews). This query
// predates the migration-196 "Candidate for U.S. Senate — <State>" placeholders and
// used to catch their holders by accident — most were hidden by `is_vacant = false`
// until CA_0195 backfilled the NULLs. Candidates do file with the FEC, and the
// dedicated scripts/senate-candidate-fec.ts is deleted (#676; it joined the dropped
// offices.politician_id), so this queue is their route in. The SELECT says so.
// scripts/run-fec-finance-summary.ts reads the confirmed rows it writes.
//
// 🔴 One row per person. office_current_holder is politician-rooted here, so a
// sitting Representative who is running for Senate comes back twice — House seat
// and Senate placeholder — and plain DISTINCT keeps both, because the chamber
// differs. A SEAT HELD BEATS A SEAT SOUGHT, as in essentialsService.
export async function getUnmatchedFederalPoliticians(): Promise<UnmatchedPolitician[]> {
  const result = await pool.query<{
    id: string;
    full_name: string;
    bioguide_id: string | null;
    chamber_name: string;
    representing_state: string;
    is_candidate: boolean;
  }>(
    `SELECT DISTINCT ON (p.id)
       p.id,
       p.full_name,
       p.bioguide_id,
       c.name AS chamber_name,
       o.representing_state,
       (COALESCE(o.title, '') ILIKE 'Candidate for%') AS is_candidate
     FROM essentials.politicians p
     -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
     JOIN essentials.office_current_holder och ON och.politician_id = p.id
     JOIN essentials.offices o ON o.id = och.office_id
     JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE p.is_active = true
       AND p.is_vacant = false
       AND (c.name LIKE 'U.S. House%' OR c.name LIKE 'U.S. Senate%')
       AND NOT EXISTS (
         SELECT 1
         FROM transparent_motivations.politician_sources ps
         WHERE ps.essentials_politician_id = p.id
           AND ps.source_system LIKE 'fec%'
       )
     ORDER BY p.id,
              (COALESCE(o.title, '') ILIKE 'Candidate for%') ASC,
              o.id`
  );

  return result.rows.map(row => {
    // The FEC files a candidate under the office SOUGHT, so a placeholder's chamber
    // is the right office for a candidate too — this is not an incumbency test.
    const isSenate = row.chamber_name.startsWith('U.S. Senate');
    return {
      id: row.id,
      full_name: row.full_name,
      bioguide_id: row.bioguide_id,
      fec_office: isSenate ? 'S' : 'H',
      source_system: isSenate ? 'fec_senate' : 'fec_house',
      representing_state: row.representing_state,
      is_candidate: row.is_candidate,
    };
  });
}

// ---------------------------------------------------------------------------
// Main orchestration
// ---------------------------------------------------------------------------

const sleep = (ms: number): Promise<void> => new Promise(r => setTimeout(r, ms));

export async function runFecAutoMatch(opts?: { limit?: number }): Promise<AutoMatchSummary> {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) {
    throw new Error('FEC_API_KEY is not set — cannot run auto-match');
  }

  const allUnmatched = await getUnmatchedFederalPoliticians();
  // Optional batching: process at most `limit` politicians this call. Because
  // getUnmatchedFederalPoliticians only returns politicians WITHOUT an fec source,
  // repeated calls drain the queue — safe to run in successive batches to stay
  // under the FEC 1,000 req/hr key ceiling.
  const politicians = opts?.limit != null ? allUnmatched.slice(0, opts.limit) : allUnmatched;
  const results: MatchResult[] = [];
  let autoConfirmed = 0;
  let needsReview = 0;
  let errors = 0;

  for (let i = 0; i < politicians.length; i++) {
    const p = politicians[i]!;

    if (i > 0) await sleep(SLEEP_BETWEEN_SEARCHES_MS);

    const result: MatchResult = {
      politician_id: p.id,
      politician_name: p.full_name,
      status: 'needs_research',
      source_system: p.source_system,
      representing_state: p.representing_state,
      is_candidate: p.is_candidate,
      candidates_found: 0,
      selected_fec_id: null,
      selected_fec_name: null,
      confidence: 0,
      source_id: null,
      notes: '',
      error: null,
    };

    try {
      const candidates = await searchFecCandidates(
        p.full_name,
        p.representing_state,
        p.fec_office,
        apiKey
      );

      result.candidates_found = candidates.length;

      // Fallback: if full-name search returns nothing, retry with last name only.
      // Handles nicknames (e.g. "Jim" stored in DB, "James" in FEC).
      let fallbackUsed = false;
      if (candidates.length === 0) {
        const lastName = parseDbName(p.full_name).last;
        if (lastName) {
          await sleep(SLEEP_BETWEEN_SEARCHES_MS);
          const fallback = await searchFecCandidates(lastName, p.representing_state, p.fec_office, apiKey);
          if (fallback.length > 0) {
            candidates.push(...fallback);
            result.candidates_found = fallback.length;
            fallbackUsed = true;
          }
        }
      }

      if (candidates.length === 0) {
        result.notes = p.is_candidate
          ? 'No FEC candidates found — candidate may not have filed yet, or name mismatch'
          : 'No FEC candidates found — may be newly elected or name mismatch';
      } else {
        // Score all candidates, pick the best
        const scored = candidates
          .map(c => ({ candidate: c, score: scoreMatch(p, c) }))
          .sort((a, b) => b.score - a.score);

        const best = scored[0]!;
        // Single result from last-name fallback: unambiguous match in correct state/office.
        // Bump to 0.8 to trigger auto-confirm even without first-name confirmation.
        const effectiveScore = (fallbackUsed && candidates.length === 1 && best.score >= 0.6)
          ? 0.8
          : best.score;
        result.confidence = effectiveScore;
        result.selected_fec_id = best.candidate.candidate_id;
        result.selected_fec_name = best.candidate.name;

        if (effectiveScore >= 0.8) {
          result.status = 'confirmed';
        } else {
          result.status = 'needs_research';
          // Store all candidates in notes for human review
          result.notes = JSON.stringify(
            scored.map(s => ({
              candidate_id: s.candidate.candidate_id,
              name: s.candidate.name,
              party: s.candidate.party,
              score: s.score,
            }))
          );
        }
      }

      // Insert politician_source row
      const inserted = await createSource({
        essentials_politician_id: p.id,
        source_system: p.source_system,
        external_id: result.selected_fec_id ?? '',
        research_status: result.status,
        notes: result.notes,
      });
      result.source_id = inserted.id;

      if (result.status === 'confirmed') {
        autoConfirmed++;
        console.log(
          `[fecResearch] confirmed: ${p.full_name} → ${result.selected_fec_id} (score ${result.confidence})`
        );
      } else {
        needsReview++;
        console.log(
          `[fecResearch] needs_review: ${p.full_name} — ${candidates.length} candidates, best score ${result.confidence}`
        );
      }
    } catch (err) {
      result.error = err instanceof Error ? err.message : String(err);
      errors++;
      console.error(`[fecResearch] error for ${p.full_name}: ${result.error}`);
    }

    results.push(result);
  }

  return {
    processed: politicians.length,
    auto_confirmed: autoConfirmed,
    needs_review: needsReview,
    errors,
    results,
  };
}

/**
 * run-house-source-triage.ts — Phase 102 House + Deferred Candidate Source Triage
 *
 * Queries the live Supabase DB to identify:
 *   1. US House representatives (NATIONAL_LOWER) with unsourced or weak-sourced stances
 *   2. Deferred 2026 Senate candidates (NATIONAL_UPPER, is_incumbent=false) with weak-sourced stances
 *      — Dooley, Shoffner, Alme deferred from Phase 101 (19 homepage-only stances)
 *
 * Outputs:
 *   .planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md
 *   .planning/phases/102-federal-house-remediation/102-HOUSE-TARGETS.csv
 *
 * Sourced definition (locked from Phase 100 — D-01):
 *   1. A row exists in inform.politician_context with the same (politician_id, topic_id).
 *   2. sources is NOT NULL.
 *   3. array_length(sources, 1) IS NOT NULL (i.e., not an empty array).
 *   4. At least one element of sources passes: url IS NOT NULL AND trim(url) <> ''.
 *
 * Weak source: context row exists with at least one non-blank URL, but every non-blank
 * URL matches the homepage-only pattern '^https?://[^/]+/?$' (domain root, no path).
 *
 * Dual scope:
 *   NATIONAL_LOWER: district_type = 'NATIONAL_LOWER', is_active = true (expected: 0 flagged)
 *   NATIONAL_UPPER_DEFERRED: district_type = 'NATIONAL_UPPER', is_incumbent = false, is_active = true (expected: 3 flagged, 19 weak stances)
 *
 * Usage:
 *   cd backend
 *   npx tsx scripts/run-house-source-triage.ts             # Full triage (writes files)
 *   npx tsx scripts/run-house-source-triage.ts --dry-run   # Counts to stderr, no files written
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import { writeFileSync, mkdirSync } from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

if (!process.env.DATABASE_URL) {
  console.error('Fatal: DATABASE_URL is not set. Ensure backend/.env exists and contains DATABASE_URL.');
  process.exit(1);
}

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// SOURCED and UNSOURCED CASE expressions — copied verbatim from
// run-senator-source-triage.ts (Phase 100 locked sourced definition, D-01)
// ---------------------------------------------------------------------------

// A stance counts as sourced when:
//   - pc.politician_id IS NOT NULL  (context row exists)
//   - pc.sources IS NOT NULL
//   - array_length(pc.sources, 1) IS NOT NULL  (NOT an empty array — Postgres returns NULL for empty arrays)
//   - EXISTS at least one non-blank URL element
const SOURCED_CASE = `
  CASE
    WHEN pc.politician_id IS NOT NULL
         AND pc.sources IS NOT NULL
         AND array_length(pc.sources, 1) IS NOT NULL
         AND EXISTS (
           SELECT 1 FROM unnest(pc.sources) AS s(url)
           WHERE url IS NOT NULL AND trim(url) <> ''
         )
    THEN 1
    ELSE 0
  END`;

// Logical inverse of SOURCED_CASE
const UNSOURCED_CASE = `
  CASE
    WHEN pc.politician_id IS NULL
         OR pc.sources IS NULL
         OR array_length(pc.sources, 1) IS NULL
         OR NOT EXISTS (
           SELECT 1 FROM unnest(pc.sources) AS s(url)
           WHERE url IS NOT NULL AND trim(url) <> ''
         )
    THEN 1
    ELSE 0
  END`;

// Postgres regex pattern for homepage-only URL detection (D-01 weak-source scope).
// Matches domain root with no path component, e.g. https://www.senator.gov or https://sd07.senate.ca.gov/
const HOMEPAGE_ONLY_REGEX = `'^https?://[^/]+/?$'`;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface SummaryRow {
  total_politicians: string;
  total_stances: string;
  unsourced_stance_count: string;
  weak_stance_count: string;
}

interface TargetRow {
  full_name: string;
  politician_id: string;
  scope: 'NATIONAL_LOWER' | 'NATIONAL_UPPER_DEFERRED';
  state: string;
  party: string;
  total_stances: string;
  unsourced_count: string;
  weak_count: string;
  affected_topic_keys: string[];
  classification: string;
}

interface DetailRow {
  full_name: string;
  politician_id: string;
  scope: 'NATIONAL_LOWER' | 'NATIONAL_UPPER_DEFERRED';
  state: string;
  topic_key: string;
  current_value: number;
  current_sources: string[] | null;
  source_status: string;
}

// ---------------------------------------------------------------------------
// HOUSE_POLITICIANS_CTE — NATIONAL_LOWER incumbents (all active)
// No is_incumbent filter — all 122 active NATIONAL_LOWER politicians are is_incumbent=true
// per 102-RESEARCH.md Live DB State. Removing the filter is robust to future flips.
// DISTINCT ON (p.id) prevents Cartesian product for reps with multiple office rows.
// ---------------------------------------------------------------------------

const HOUSE_POLITICIANS_CTE = `
  house_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
      AND d.district_type = 'NATIONAL_LOWER'
    WHERE p.is_active = true
    ORDER BY p.id
  )`;

// ---------------------------------------------------------------------------
// DEFERRED_CANDIDATES_CTE — 2026 Senate candidates deferred from Phase 101
// Dooley (GA), Shoffner (AR), Alme (MT) — NATIONAL_UPPER, is_incumbent=false
// DISTINCT ON (p.id) prevents multi-office Cartesian inflation.
// ---------------------------------------------------------------------------

const DEFERRED_CANDIDATES_CTE = `
  deferred_candidates AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
      AND d.district_type = 'NATIONAL_UPPER'
    WHERE p.is_active = true
      AND p.is_incumbent = false
    ORDER BY p.id
  )`;

// ---------------------------------------------------------------------------
// Query A — House triage summary (total_politicians, total_stances, unsourced, weak)
// ---------------------------------------------------------------------------

async function queryHouseSummary(): Promise<SummaryRow> {
  const result = await pool.query<SummaryRow>(`
    WITH ${HOUSE_POLITICIANS_CTE}
    SELECT
      (SELECT COUNT(*) FROM house_politicians)::text AS total_politicians,
      COUNT(pa.topic_id)::text AS total_stances,
      COALESCE(SUM(${UNSOURCED_CASE}), 0)::text AS unsourced_stance_count,
      COUNT(
        CASE
          WHEN pc.politician_id IS NOT NULL
            AND pc.sources IS NOT NULL
            AND array_length(pc.sources, 1) IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL
                AND trim(url) <> ''
                AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
            )
            AND EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          THEN 1
        END
      )::text AS weak_stance_count
    FROM house_politicians hp
    JOIN inform.politician_answers pa ON pa.politician_id = hp.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query A (deferred candidates) — Summary for NATIONAL_UPPER_DEFERRED scope
// ---------------------------------------------------------------------------

async function queryDeferredCandidateSummary(): Promise<SummaryRow> {
  const result = await pool.query<SummaryRow>(`
    WITH ${DEFERRED_CANDIDATES_CTE}
    SELECT
      (SELECT COUNT(*) FROM deferred_candidates)::text AS total_politicians,
      COUNT(pa.topic_id)::text AS total_stances,
      COALESCE(SUM(${UNSOURCED_CASE}), 0)::text AS unsourced_stance_count,
      COUNT(
        CASE
          WHEN pc.politician_id IS NOT NULL
            AND pc.sources IS NOT NULL
            AND array_length(pc.sources, 1) IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL
                AND trim(url) <> ''
                AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
            )
            AND EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          THEN 1
        END
      )::text AS weak_stance_count
    FROM deferred_candidates dc
    JOIN inform.politician_answers pa ON pa.politician_id = dc.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query B — Per-house-rep target list
// Only reps with at least one unsourced OR weak-sourced stance.
// ---------------------------------------------------------------------------

async function queryHouseTargets(): Promise<TargetRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    party: string;
    total_stances: string;
    unsourced_count: string;
    weak_count: string;
    affected_topic_keys: string | null;
    classification: string;
  }>(`
    WITH ${HOUSE_POLITICIANS_CTE},
    per_rep AS (
      SELECT
        hp.id AS politician_id,
        hp.full_name,
        hp.state,
        hp.party,
        COUNT(pa.topic_id) AS total_stances,
        SUM(${UNSOURCED_CASE}) AS unsourced_count,
        COUNT(
          CASE
            WHEN pc.politician_id IS NOT NULL
              AND pc.sources IS NOT NULL
              AND array_length(pc.sources, 1) IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL
                  AND trim(url) <> ''
                  AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
              )
              AND EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL AND trim(url) <> ''
              )
            THEN 1
          END
        ) AS weak_count,
        array_agg(DISTINCT t.topic_key) FILTER (
          WHERE (
            -- unsourced
            pc.politician_id IS NULL
            OR pc.sources IS NULL
            OR array_length(pc.sources, 1) IS NULL
            OR NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          ) OR (
            -- weak-sourced
            pc.politician_id IS NOT NULL
            AND pc.sources IS NOT NULL
            AND array_length(pc.sources, 1) IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL
                AND trim(url) <> ''
                AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
            )
            AND EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          )
        ) AS affected_topic_keys
      FROM house_politicians hp
      JOIN inform.politician_answers pa ON pa.politician_id = hp.id
      LEFT JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
      GROUP BY hp.id, hp.full_name, hp.state, hp.party
      HAVING SUM(${UNSOURCED_CASE}) > 0
        OR COUNT(
          CASE
            WHEN pc.politician_id IS NOT NULL
              AND pc.sources IS NOT NULL
              AND array_length(pc.sources, 1) IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL
                  AND trim(url) <> ''
                  AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
              )
              AND EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL AND trim(url) <> ''
              )
            THEN 1
          END
        ) > 0
    )
    SELECT
      full_name,
      politician_id::text,
      state,
      party,
      total_stances::text,
      unsourced_count::text,
      weak_count::text,
      array_to_string(affected_topic_keys, '|') AS affected_topic_keys,
      CASE
        WHEN unsourced_count > 0 AND weak_count = 0 THEN 'unsourced_only'
        WHEN unsourced_count = 0 AND weak_count > 0 THEN 'weak_only'
        ELSE 'both'
      END AS classification
    FROM per_rep
    ORDER BY state ASC, full_name ASC
  `);

  return result.rows.map((r) => ({
    ...r,
    scope: 'NATIONAL_LOWER' as const,
    affected_topic_keys: r.affected_topic_keys ? r.affected_topic_keys.split('|') : [],
  }));
}

// ---------------------------------------------------------------------------
// Query B (deferred candidates) — Per-candidate target list
// Only candidates with at least one unsourced OR weak-sourced stance.
// ---------------------------------------------------------------------------

async function queryDeferredCandidateTargets(): Promise<TargetRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    party: string;
    total_stances: string;
    unsourced_count: string;
    weak_count: string;
    affected_topic_keys: string | null;
    classification: string;
  }>(`
    WITH ${DEFERRED_CANDIDATES_CTE},
    per_candidate AS (
      SELECT
        dc.id AS politician_id,
        dc.full_name,
        dc.state,
        dc.party,
        COUNT(pa.topic_id) AS total_stances,
        SUM(${UNSOURCED_CASE}) AS unsourced_count,
        COUNT(
          CASE
            WHEN pc.politician_id IS NOT NULL
              AND pc.sources IS NOT NULL
              AND array_length(pc.sources, 1) IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL
                  AND trim(url) <> ''
                  AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
              )
              AND EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL AND trim(url) <> ''
              )
            THEN 1
          END
        ) AS weak_count,
        array_agg(DISTINCT t.topic_key) FILTER (
          WHERE (
            -- unsourced
            pc.politician_id IS NULL
            OR pc.sources IS NULL
            OR array_length(pc.sources, 1) IS NULL
            OR NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          ) OR (
            -- weak-sourced
            pc.politician_id IS NOT NULL
            AND pc.sources IS NOT NULL
            AND array_length(pc.sources, 1) IS NOT NULL
            AND NOT EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL
                AND trim(url) <> ''
                AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
            )
            AND EXISTS (
              SELECT 1 FROM unnest(pc.sources) AS s(url)
              WHERE url IS NOT NULL AND trim(url) <> ''
            )
          )
        ) AS affected_topic_keys
      FROM deferred_candidates dc
      JOIN inform.politician_answers pa ON pa.politician_id = dc.id
      LEFT JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
      GROUP BY dc.id, dc.full_name, dc.state, dc.party
      HAVING SUM(${UNSOURCED_CASE}) > 0
        OR COUNT(
          CASE
            WHEN pc.politician_id IS NOT NULL
              AND pc.sources IS NOT NULL
              AND array_length(pc.sources, 1) IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL
                  AND trim(url) <> ''
                  AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
              )
              AND EXISTS (
                SELECT 1 FROM unnest(pc.sources) AS s(url)
                WHERE url IS NOT NULL AND trim(url) <> ''
              )
            THEN 1
          END
        ) > 0
    )
    SELECT
      full_name,
      politician_id::text,
      state,
      party,
      total_stances::text,
      unsourced_count::text,
      weak_count::text,
      array_to_string(affected_topic_keys, '|') AS affected_topic_keys,
      CASE
        WHEN unsourced_count > 0 AND weak_count = 0 THEN 'unsourced_only'
        WHEN unsourced_count = 0 AND weak_count > 0 THEN 'weak_only'
        ELSE 'both'
      END AS classification
    FROM per_candidate
    ORDER BY state ASC, full_name ASC
  `);

  return result.rows.map((r) => ({
    ...r,
    scope: 'NATIONAL_UPPER_DEFERRED' as const,
    affected_topic_keys: r.affected_topic_keys ? r.affected_topic_keys.split('|') : [],
  }));
}

// ---------------------------------------------------------------------------
// Query C — Affected-topic detail rollup for NATIONAL_LOWER (per rep × topic_key)
// ---------------------------------------------------------------------------

async function queryHouseTopicDetail(): Promise<DetailRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    topic_key: string;
    current_value: number;
    current_sources: string[] | null;
    source_status: string;
  }>(`
    WITH ${HOUSE_POLITICIANS_CTE}
    SELECT
      hp.full_name,
      hp.id::text AS politician_id,
      hp.state,
      t.topic_key,
      pa.value AS current_value,
      pc.sources AS current_sources,
      CASE
        -- unsourced
        WHEN pc.politician_id IS NULL
          OR pc.sources IS NULL
          OR array_length(pc.sources, 1) IS NULL
          OR NOT EXISTS (
            SELECT 1 FROM unnest(pc.sources) AS s(url)
            WHERE url IS NOT NULL AND trim(url) <> ''
          )
        THEN 'unsourced'
        -- weak-sourced
        WHEN NOT EXISTS (
          SELECT 1 FROM unnest(pc.sources) AS s(url)
          WHERE url IS NOT NULL
            AND trim(url) <> ''
            AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
        )
        AND EXISTS (
          SELECT 1 FROM unnest(pc.sources) AS s(url)
          WHERE url IS NOT NULL AND trim(url) <> ''
        )
        THEN 'weak'
        ELSE NULL
      END AS source_status
    FROM house_politicians hp
    JOIN inform.politician_answers pa ON pa.politician_id = hp.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN inform.compass_topics t ON t.id = pa.topic_id
    WHERE (
      -- unsourced
      pc.politician_id IS NULL
      OR pc.sources IS NULL
      OR array_length(pc.sources, 1) IS NULL
      OR NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
    ) OR (
      -- weak-sourced
      pc.politician_id IS NOT NULL
      AND pc.sources IS NOT NULL
      AND array_length(pc.sources, 1) IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL
          AND trim(url) <> ''
          AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
      )
      AND EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
    )
    ORDER BY hp.state ASC, hp.full_name ASC, t.topic_key ASC
  `);
  return result.rows.map((r) => ({ ...r, scope: 'NATIONAL_LOWER' as const }));
}

// ---------------------------------------------------------------------------
// Query C (deferred candidates) — Topic detail rollup for NATIONAL_UPPER_DEFERRED
// ---------------------------------------------------------------------------

async function queryDeferredCandidateTopicDetail(): Promise<DetailRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    topic_key: string;
    current_value: number;
    current_sources: string[] | null;
    source_status: string;
  }>(`
    WITH ${DEFERRED_CANDIDATES_CTE}
    SELECT
      dc.full_name,
      dc.id::text AS politician_id,
      dc.state,
      t.topic_key,
      pa.value AS current_value,
      pc.sources AS current_sources,
      CASE
        -- unsourced
        WHEN pc.politician_id IS NULL
          OR pc.sources IS NULL
          OR array_length(pc.sources, 1) IS NULL
          OR NOT EXISTS (
            SELECT 1 FROM unnest(pc.sources) AS s(url)
            WHERE url IS NOT NULL AND trim(url) <> ''
          )
        THEN 'unsourced'
        -- weak-sourced
        WHEN NOT EXISTS (
          SELECT 1 FROM unnest(pc.sources) AS s(url)
          WHERE url IS NOT NULL
            AND trim(url) <> ''
            AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
        )
        AND EXISTS (
          SELECT 1 FROM unnest(pc.sources) AS s(url)
          WHERE url IS NOT NULL AND trim(url) <> ''
        )
        THEN 'weak'
        ELSE NULL
      END AS source_status
    FROM deferred_candidates dc
    JOIN inform.politician_answers pa ON pa.politician_id = dc.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN inform.compass_topics t ON t.id = pa.topic_id
    WHERE (
      -- unsourced
      pc.politician_id IS NULL
      OR pc.sources IS NULL
      OR array_length(pc.sources, 1) IS NULL
      OR NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
    ) OR (
      -- weak-sourced
      pc.politician_id IS NOT NULL
      AND pc.sources IS NOT NULL
      AND array_length(pc.sources, 1) IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL
          AND trim(url) <> ''
          AND trim(url) !~ ${HOMEPAGE_ONLY_REGEX}
      )
      AND EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
    )
    ORDER BY dc.state ASC, dc.full_name ASC, t.topic_key ASC
  `);
  return result.rows.map((r) => ({ ...r, scope: 'NATIONAL_UPPER_DEFERRED' as const }));
}

// ---------------------------------------------------------------------------
// Report builder
// ---------------------------------------------------------------------------

function buildReport(
  houseSummary: SummaryRow,
  deferredSummary: SummaryRow,
  houseTargets: TargetRow[],
  deferredTargets: TargetRow[],
  houseDetails: DetailRow[],
  deferredDetails: DetailRow[],
  runDate: string,
): string {
  const combinedTargets = [...houseTargets, ...deferredTargets];

  const houseFlagged = houseTargets.length;
  const deferredFlagged = deferredTargets.length;
  const totalFlagged = houseFlagged + deferredFlagged;

  // Weak stance totals for the scoping note
  const deferredWeakTotal = deferredDetails.filter((d) => d.source_status === 'weak').length;

  // --- Executive Summary — NATIONAL_LOWER ---
  const houseUnsourcedOnly = houseTargets.filter((t) => t.classification === 'unsourced_only').length;
  const houseWeakOnly = houseTargets.filter((t) => t.classification === 'weak_only').length;
  const houseBoth = houseTargets.filter((t) => t.classification === 'both').length;

  const houseExecSummary = `### NATIONAL_LOWER (US House Representatives)

| Metric | Value |
|--------|-------|
| total_politicians | ${houseSummary.total_politicians} |
| total_stances | ${houseSummary.total_stances} |
| unsourced_stance_count | ${houseSummary.unsourced_stance_count} |
| weak_stance_count | ${houseSummary.weak_stance_count} |
| Representatives flagged | ${houseFlagged} |
| — unsourced_only | ${houseUnsourcedOnly} |
| — weak_only | ${houseWeakOnly} |
| — both | ${houseBoth} |`;

  // --- Executive Summary — NATIONAL_UPPER_DEFERRED ---
  const deferredUnsourcedOnly = deferredTargets.filter((t) => t.classification === 'unsourced_only').length;
  const deferredWeakOnly = deferredTargets.filter((t) => t.classification === 'weak_only').length;
  const deferredBoth = deferredTargets.filter((t) => t.classification === 'both').length;

  const deferredExecSummary = `### NATIONAL_UPPER_DEFERRED (2026 Senate Candidates — deferred from Phase 101)

| Metric | Value |
|--------|-------|
| total_politicians | ${deferredSummary.total_politicians} |
| total_stances | ${deferredSummary.total_stances} |
| unsourced_stance_count | ${deferredSummary.unsourced_stance_count} |
| weak_stance_count | ${deferredSummary.weak_stance_count} |
| Candidates flagged | ${deferredFlagged} |
| — unsourced_only | ${deferredUnsourcedOnly} |
| — weak_only | ${deferredWeakOnly} |
| — both | ${deferredBoth} |`;

  // --- Methodology block ---
  const methodology = `## Methodology

**Sourced definition (locked Phase 100 — D-01):**
A stance counts as sourced when ALL of the following are true:
1. A row exists in \`inform.politician_context\` with the same \`(politician_id, topic_id)\` composite key.
2. \`sources\` is NOT NULL.
3. \`array_length(sources, 1)\` is NOT NULL (Postgres returns NULL for empty arrays).
4. At least one element of \`sources\` passes \`url IS NOT NULL AND trim(url) <> ''\`.

**Weak-source detection:**
A sourced row is classified as "weak" when every non-blank URL matches the homepage-only pattern:
\`^https?://[^/]+/?$\`
(domain root with no path, e.g. \`https://www.senator.gov\`).
Applied via Postgres \`~\` operator against every non-blank element of \`inform.politician_context.sources\`.

**Dual scope:**
- \`NATIONAL_LOWER\`: \`essentials.offices JOIN essentials.districts WHERE district_type = 'NATIONAL_LOWER'\`
  with \`DISTINCT ON (politician_id)\` to prevent multi-office Cartesian inflation.
  Active politicians only (\`p.is_active = true\`). No \`is_incumbent\` filter (all active NATIONAL_LOWER are incumbents per live DB state).
- \`NATIONAL_UPPER_DEFERRED\`: \`district_type = 'NATIONAL_UPPER' AND p.is_incumbent = false\`
  — captures the 3 Senate candidates (Dooley, Shoffner, Alme) deferred from Phase 101.
  Their \`is_vacant = false\` office records caused them to appear in Phase 101 NATIONAL_UPPER queries;
  their homepage-only sources drove V2 = 19 in 101-VERIFICATION.md.`;

  // --- NATIONAL_LOWER Unsourced ---
  const houseUnsourcedTargets = houseTargets.filter(
    (t) => t.classification === 'unsourced_only' || t.classification === 'both',
  );

  let houseUnsourcedSection = `## NATIONAL_LOWER — Unsourced Stances\n\n`;
  if (houseUnsourcedTargets.length === 0) {
    houseUnsourcedSection += '_No NATIONAL_LOWER representatives with unsourced stances found._\n';
  } else {
    for (const rep of houseUnsourcedTargets) {
      const repDetails = houseDetails.filter(
        (d) => d.politician_id === rep.politician_id && d.source_status === 'unsourced',
      );
      houseUnsourcedSection += `### ${rep.full_name} (${rep.state}, ${rep.party})\n\n`;
      houseUnsourcedSection += `- **politician_id:** ${rep.politician_id}\n`;
      houseUnsourcedSection += `- **unsourced_count:** ${rep.unsourced_count}\n`;
      houseUnsourcedSection += `- **Affected topics:**\n\n`;
      houseUnsourcedSection += `| topic_key | current_value | current_sources |\n`;
      houseUnsourcedSection += `|-----------|---------------|----------------|\n`;
      for (const d of repDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        houseUnsourcedSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      houseUnsourcedSection += '\n';
    }
  }

  // --- NATIONAL_LOWER Weak-Sourced ---
  const houseWeakTargets = houseTargets.filter(
    (t) => t.classification === 'weak_only' || t.classification === 'both',
  );

  let houseWeakSection = `## NATIONAL_LOWER — Weak-Sourced Stances\n\n`;
  if (houseWeakTargets.length === 0) {
    houseWeakSection += '_No NATIONAL_LOWER representatives with weak-sourced stances found._\n';
  } else {
    for (const rep of houseWeakTargets) {
      const repDetails = houseDetails.filter(
        (d) => d.politician_id === rep.politician_id && d.source_status === 'weak',
      );
      houseWeakSection += `### ${rep.full_name} (${rep.state}, ${rep.party})\n\n`;
      houseWeakSection += `- **politician_id:** ${rep.politician_id}\n`;
      houseWeakSection += `- **weak_count:** ${rep.weak_count}\n`;
      houseWeakSection += `- **Affected topics (homepage-only source URL):**\n\n`;
      houseWeakSection += `| topic_key | current_value | current_sources |\n`;
      houseWeakSection += `|-----------|---------------|----------------|\n`;
      for (const d of repDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        houseWeakSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      houseWeakSection += '\n';
    }
  }

  // --- Deferred Candidates Unsourced ---
  const deferredUnsourcedTargets = deferredTargets.filter(
    (t) => t.classification === 'unsourced_only' || t.classification === 'both',
  );

  let deferredUnsourcedSection = `## Deferred Candidates (NATIONAL_UPPER non-incumbent) — Unsourced Stances\n\n`;
  if (deferredUnsourcedTargets.length === 0) {
    deferredUnsourcedSection += '_No deferred candidates with unsourced stances found._\n';
  } else {
    for (const candidate of deferredUnsourcedTargets) {
      const candDetails = deferredDetails.filter(
        (d) => d.politician_id === candidate.politician_id && d.source_status === 'unsourced',
      );
      deferredUnsourcedSection += `### ${candidate.full_name} (${candidate.state}, ${candidate.party})\n\n`;
      deferredUnsourcedSection += `- **politician_id:** ${candidate.politician_id}\n`;
      deferredUnsourcedSection += `- **unsourced_count:** ${candidate.unsourced_count}\n`;
      deferredUnsourcedSection += `- **Affected topics:**\n\n`;
      deferredUnsourcedSection += `| topic_key | current_value | current_sources |\n`;
      deferredUnsourcedSection += `|-----------|---------------|----------------|\n`;
      for (const d of candDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        deferredUnsourcedSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      deferredUnsourcedSection += '\n';
    }
  }

  // --- Deferred Candidates Weak-Sourced ---
  const deferredWeakTargets = deferredTargets.filter(
    (t) => t.classification === 'weak_only' || t.classification === 'both',
  );

  let deferredWeakSection = `## Deferred Candidates (NATIONAL_UPPER non-incumbent) — Weak-Sourced Stances\n\n`;
  if (deferredWeakTargets.length === 0) {
    deferredWeakSection += '_No deferred candidates with weak-sourced stances found._\n';
  } else {
    for (const candidate of deferredWeakTargets) {
      const candDetails = deferredDetails.filter(
        (d) => d.politician_id === candidate.politician_id && d.source_status === 'weak',
      );
      deferredWeakSection += `### ${candidate.full_name} (${candidate.state}, ${candidate.party})\n\n`;
      deferredWeakSection += `- **politician_id:** ${candidate.politician_id}\n`;
      deferredWeakSection += `- **weak_count:** ${candidate.weak_count}\n`;
      deferredWeakSection += `- **Affected topics (homepage-only source URL):**\n\n`;
      deferredWeakSection += `| topic_key | current_value | current_sources |\n`;
      deferredWeakSection += `|-----------|---------------|----------------|\n`;
      for (const d of candDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        deferredWeakSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      deferredWeakSection += '\n';
    }
  }

  // --- Combined Target List ---
  let targetTable = `## Combined Target List\n\n`;
  targetTable += `| full_name | politician_id | scope | state | party | total_stances | unsourced_count | weak_count | classification | affected_topic_keys |\n`;
  targetTable += `|-----------|---------------|-------|-------|-------|---------------|-----------------|------------|----------------|--------------------|\n`;
  for (const t of combinedTargets) {
    targetTable += `| ${t.full_name} | ${t.politician_id} | ${t.scope} | ${t.state} | ${t.party} | ${t.total_stances} | ${t.unsourced_count} | ${t.weak_count} | ${t.classification} | ${t.affected_topic_keys.join(', ')} |\n`;
  }
  if (combinedTargets.length === 0) {
    targetTable += `_No flagged politicians in either scope._\n`;
  }

  // --- Plan 02 Scoping Note ---
  const scopingNote = `## Plan 02 Scoping

**NATIONAL_LOWER flagged (FEDX-02 V1):** ${houseFlagged} — FEDX-02 V1 trivially passes (0 unsourced/weak House stances)
**Deferred candidates flagged (NATIONAL_UPPER_DEFERRED):** ${deferredFlagged} candidates, ${deferredWeakTotal} total weak stances

${houseFlagged > 0 ? `WARNING: NATIONAL_LOWER count is non-zero (${houseFlagged} flagged) — drift from research-time state. Plan 02 must be re-sized to include NATIONAL_LOWER remediation.\n` : ''}
**Recommended batching: 1 research plan** (${deferredFlagged} deferred candidates ≤ 10 threshold — per 102-RESEARCH.md Phase Plan Structure)
- 1 research plan covers all 3 deferred candidates (one research-stances agent dispatch per candidate)
- Dispatch order: Dooley (GA, 6 weak topics), Shoffner (AR, 5 weak topics), Alme (MT, 8 weak topics)

Machine-readable target list: \`102-HOUSE-TARGETS.csv\``;

  return `# Phase 102 — House Triage Report

Generated: ${runDate}

---

## Executive Summary

${houseExecSummary}

${deferredExecSummary}

---

${methodology}

---

${houseUnsourcedSection}

---

${houseWeakSection}

---

${deferredUnsourcedSection}

---

${deferredWeakSection}

---

${targetTable}

---

${scopingNote}
`;
}

// ---------------------------------------------------------------------------
// CSV builder
// Header: full_name,politician_id,scope,state,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification
// affected_topic_keys stored as pipe-delimited string inside a double-quoted field.
// ---------------------------------------------------------------------------

function buildCsv(rows: TargetRow[]): string {
  const header = 'full_name,politician_id,scope,state,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification';
  const dataRows = rows.map((r) => {
    const escapedName = `"${r.full_name.replace(/"/g, '""')}"`;
    const topicKeys = `"${r.affected_topic_keys.join('|')}"`;
    return `${escapedName},${r.politician_id},${r.scope},${r.state},${r.party},${r.total_stances},${r.unsourced_count},${r.weak_count},${topicKeys},${r.classification}`;
  });
  return [header, ...dataRows].join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const runDate = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  console.error('Phase 102 House + Deferred Candidate Source Triage — starting queries...');

  // Query A — Summary counts (both scopes)
  console.error('  Query A: NATIONAL_LOWER summary counts...');
  const houseSummary = await queryHouseSummary();
  console.error(`    NATIONAL_LOWER total_politicians: ${houseSummary.total_politicians}`);
  console.error(`    NATIONAL_LOWER total_stances: ${houseSummary.total_stances}`);
  console.error(`    NATIONAL_LOWER unsourced_stance_count: ${houseSummary.unsourced_stance_count}`);
  console.error(`    NATIONAL_LOWER weak_stance_count: ${houseSummary.weak_stance_count}`);

  console.error('  Query A: NATIONAL_UPPER_DEFERRED summary counts...');
  const deferredSummary = await queryDeferredCandidateSummary();
  console.error(`    NATIONAL_UPPER_DEFERRED total_politicians: ${deferredSummary.total_politicians}`);
  console.error(`    NATIONAL_UPPER_DEFERRED total_stances: ${deferredSummary.total_stances}`);
  console.error(`    NATIONAL_UPPER_DEFERRED unsourced_stance_count: ${deferredSummary.unsourced_stance_count}`);
  console.error(`    NATIONAL_UPPER_DEFERRED weak_stance_count: ${deferredSummary.weak_stance_count}`);

  if (DRY_RUN) {
    console.error('\nDry run complete — no files written.');
    await pool.end();
    return;
  }

  // Query B — Per-target lists
  console.error('  Query B: NATIONAL_LOWER target list...');
  const houseTargets = await queryHouseTargets();
  console.error(`    NATIONAL_LOWER flagged: ${houseTargets.length}`);

  console.error('  Query B: NATIONAL_UPPER_DEFERRED target list...');
  const deferredTargets = await queryDeferredCandidateTargets();
  console.error(`    NATIONAL_UPPER_DEFERRED flagged: ${deferredTargets.length}`);

  const combinedTargets = [...houseTargets, ...deferredTargets];

  // Query C — Topic-level detail
  console.error('  Query C: NATIONAL_LOWER affected topic detail...');
  const houseDetails = await queryHouseTopicDetail();
  console.error(`    NATIONAL_LOWER affected stance rows: ${houseDetails.length}`);

  console.error('  Query C: NATIONAL_UPPER_DEFERRED affected topic detail...');
  const deferredDetails = await queryDeferredCandidateTopicDetail();
  console.error(`    NATIONAL_UPPER_DEFERRED affected stance rows: ${deferredDetails.length}`);

  // Build and write outputs
  console.error('\nBuilding report and CSV...');

  const report = buildReport(
    houseSummary,
    deferredSummary,
    houseTargets,
    deferredTargets,
    houseDetails,
    deferredDetails,
    runDate,
  );
  const csv = buildCsv(combinedTargets);

  const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '102-federal-house-remediation');
  mkdirSync(phaseDir, { recursive: true });

  const reportPath = path.resolve(phaseDir, '102-TRIAGE-REPORT.md');
  writeFileSync(reportPath, report, 'utf8');
  console.error(`  Written: ${reportPath}`);

  const csvPath = path.resolve(phaseDir, '102-HOUSE-TARGETS.csv');
  writeFileSync(csvPath, csv, 'utf8');
  console.error(`  Written: ${csvPath}`);

  // Plan 02 scope summary
  const deferredWeakTotal = deferredDetails.filter((d) => d.source_status === 'weak').length;
  const houseFlagged = houseTargets.length;
  const deferredFlagged = deferredTargets.length;

  console.log(
    `Plan 02 scope: ${houseFlagged} NATIONAL_LOWER + ${deferredFlagged} deferred candidates flagged (${deferredWeakTotal} total weak stances) — recommended batching: 1 research plan (per 102-RESEARCH.md Phase Plan Structure)`
  );

  console.error('\nTriage complete.');
  await pool.end();
  process.exit(0);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end().catch(() => {});
  process.exit(1);
});

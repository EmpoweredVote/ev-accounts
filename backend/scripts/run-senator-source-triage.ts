/**
 * run-senator-source-triage.ts — Phase 101 Senator Source Triage
 *
 * Queries the live Supabase DB to identify US Senators with unsourced
 * or weak-sourced stances in inform.politician_answers / inform.politician_context.
 * Scope: district_type = 'NATIONAL_UPPER' (100 senators).
 *
 * Outputs:
 *   .planning/phases/101-candidate-profiles/101-TRIAGE-REPORT.md
 *   .planning/phases/101-candidate-profiles/101-SENATOR-TARGETS.csv
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
 * Usage:
 *   cd backend
 *   npx tsx scripts/run-senator-source-triage.ts             # Full triage (writes files)
 *   npx tsx scripts/run-senator-source-triage.ts --dry-run   # Counts to stderr, no files written
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
// run-source-coverage-audit.ts (Phase 100 locked sourced definition, D-01)
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
  total_senators: string;
  total_stances: string;
  unsourced_stance_count: string;
  weak_stance_count: string;
}

interface TargetRow {
  full_name: string;
  politician_id: string;
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
  state: string;
  topic_key: string;
  current_value: number;
  current_sources: string[] | null;
  source_status: string;
}

// ---------------------------------------------------------------------------
// senate_politicians CTE — reusable across queries
// DISTINCT ON (p.id) prevents Cartesian product for senators with multiple office rows.
// ---------------------------------------------------------------------------

const SENATE_POLITICIANS_CTE = `
  senate_politicians AS (
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
      AND p.is_incumbent = true
    ORDER BY p.id
  )`;

// ---------------------------------------------------------------------------
// Query A — Senate triage summary (total_senators, total_stances, unsourced, weak)
// ---------------------------------------------------------------------------

async function querySenatorSummary(): Promise<SummaryRow> {
  const result = await pool.query<SummaryRow>(`
    WITH ${SENATE_POLITICIANS_CTE}
    SELECT
      (SELECT COUNT(*) FROM senate_politicians)::text AS total_senators,
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
    FROM senate_politicians sp
    JOIN inform.politician_answers pa ON pa.politician_id = sp.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query B — Per-senator target list
// Only senators with at least one unsourced OR weak-sourced stance.
// ---------------------------------------------------------------------------

async function querySenatorTargets(): Promise<TargetRow[]> {
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
    WITH ${SENATE_POLITICIANS_CTE},
    per_senator AS (
      SELECT
        sp.id AS politician_id,
        sp.full_name,
        sp.state,
        sp.party,
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
      FROM senate_politicians sp
      JOIN inform.politician_answers pa ON pa.politician_id = sp.id
      LEFT JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
      GROUP BY sp.id, sp.full_name, sp.state, sp.party
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
    FROM per_senator
    ORDER BY state ASC, full_name ASC
  `);

  return result.rows.map((r) => ({
    ...r,
    affected_topic_keys: r.affected_topic_keys ? r.affected_topic_keys.split('|') : [],
  }));
}

// ---------------------------------------------------------------------------
// Query C — Affected-topic detail rollup (per senator × topic_key)
// Used in the report for per-senator topic lists.
// ---------------------------------------------------------------------------

async function querySenatorTopicDetail(): Promise<DetailRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    topic_key: string;
    current_value: number;
    current_sources: string[] | null;
    source_status: string;
  }>(`
    WITH ${SENATE_POLITICIANS_CTE}
    SELECT
      sp.full_name,
      sp.id::text AS politician_id,
      sp.state,
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
    FROM senate_politicians sp
    JOIN inform.politician_answers pa ON pa.politician_id = sp.id
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
    ORDER BY sp.state ASC, sp.full_name ASC, t.topic_key ASC
  `);
  return result.rows;
}

// ---------------------------------------------------------------------------
// Report builder
// ---------------------------------------------------------------------------

function determineBatchingTier(totalFlagged: number): string {
  if (totalFlagged <= 10) return '1 plan (≤10 senators)';
  if (totalFlagged <= 25) return '2 plans (11–25 senators, A–M / N–Z split)';
  return '3 plans (26+ senators)';
}

function buildReport(
  summary: SummaryRow,
  targets: TargetRow[],
  details: DetailRow[],
  runDate: string,
): string {
  const totalFlagged = targets.length;
  const unsourcedOnly = targets.filter((t) => t.classification === 'unsourced_only').length;
  const weakOnly = targets.filter((t) => t.classification === 'weak_only').length;
  const both = targets.filter((t) => t.classification === 'both').length;
  const batchingTier = determineBatchingTier(totalFlagged);

  // --- Executive Summary table ---
  const execSummary = `## Executive Summary

| Metric | Value |
|--------|-------|
| total_senators | ${summary.total_senators} |
| total_stances | ${summary.total_stances} |
| unsourced_stance_count | ${summary.unsourced_stance_count} |
| weak_stance_count | ${summary.weak_stance_count} |
| Senators flagged | ${totalFlagged} |
| — unsourced_only | ${unsourcedOnly} |
| — weak_only | ${weakOnly} |
| — both | ${both} |`;

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

**Senate scope:**
\`essentials.offices JOIN essentials.districts WHERE district_type = 'NATIONAL_UPPER'\`
with \`DISTINCT ON (politician_id)\` to prevent multi-office Cartesian inflation.
Active politicians only (\`p.is_active = true\`).`;

  // --- Unsourced Senator Stances ---
  const unsourcedTargets = targets.filter(
    (t) => t.classification === 'unsourced_only' || t.classification === 'both',
  );

  let unsourcedSection = `## Unsourced Senator Stances\n\n`;
  if (unsourcedTargets.length === 0) {
    unsourcedSection += '_No senators with unsourced stances found._\n';
  } else {
    for (const senator of unsourcedTargets) {
      const senatorDetails = details.filter(
        (d) => d.politician_id === senator.politician_id && d.source_status === 'unsourced',
      );
      unsourcedSection += `### ${senator.full_name} (${senator.state}, ${senator.party})\n\n`;
      unsourcedSection += `- **politician_id:** ${senator.politician_id}\n`;
      unsourcedSection += `- **unsourced_count:** ${senator.unsourced_count}\n`;
      unsourcedSection += `- **Affected topics:**\n\n`;
      unsourcedSection += `| topic_key | current_value | current_sources |\n`;
      unsourcedSection += `|-----------|---------------|----------------|\n`;
      for (const d of senatorDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        unsourcedSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      unsourcedSection += '\n';
    }
  }

  // --- Weak-Sourced Senator Stances ---
  const weakTargets = targets.filter(
    (t) => t.classification === 'weak_only' || t.classification === 'both',
  );

  let weakSection = `## Weak-Sourced Senator Stances\n\n`;
  if (weakTargets.length === 0) {
    weakSection += '_No senators with weak-sourced stances found._\n';
  } else {
    for (const senator of weakTargets) {
      const senatorDetails = details.filter(
        (d) => d.politician_id === senator.politician_id && d.source_status === 'weak',
      );
      weakSection += `### ${senator.full_name} (${senator.state}, ${senator.party})\n\n`;
      weakSection += `- **politician_id:** ${senator.politician_id}\n`;
      weakSection += `- **weak_count:** ${senator.weak_count}\n`;
      weakSection += `- **Affected topics (homepage-only source URL):**\n\n`;
      weakSection += `| topic_key | current_value | current_sources |\n`;
      weakSection += `|-----------|---------------|----------------|\n`;
      for (const d of senatorDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        weakSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      weakSection += '\n';
    }
  }

  // --- Combined Target List ---
  let targetTable = `## Combined Target List\n\n`;
  targetTable += `| full_name | politician_id | state | party | total_stances | unsourced_count | weak_count | classification | affected_topic_keys |\n`;
  targetTable += `|-----------|---------------|-------|-------|---------------|-----------------|------------|----------------|--------------------|\n`;
  for (const t of targets) {
    targetTable += `| ${t.full_name} | ${t.politician_id} | ${t.state} | ${t.party} | ${t.total_stances} | ${t.unsourced_count} | ${t.weak_count} | ${t.classification} | ${t.affected_topic_keys.join(', ')} |\n`;
  }

  // --- Plan 02 Scoping Note ---
  const scopingNote = `## Plan 02 Scoping Note

**Senators flagged (requiring research):** ${totalFlagged}
- unsourced_only: ${unsourcedOnly}
- weak_only: ${weakOnly}
- both (unsourced + weak): ${both}

**Recommended batching:** ${batchingTier} (per D-03 thresholds: ≤10 = 1 plan, 11–25 = 2 plans, 26+ = 3 plans)

Machine-readable target list: \`101-SENATOR-TARGETS.csv\``;

  return `# Phase 101 — Senator Triage Report

Generated: ${runDate}

---

${execSummary}

---

${methodology}

---

${unsourcedSection}

---

${weakSection}

---

${targetTable}

---

${scopingNote}
`;
}

// ---------------------------------------------------------------------------
// CSV builder
// affected_topic_keys stored as pipe-delimited string inside a double-quoted field.
// ---------------------------------------------------------------------------

function buildCsv(rows: TargetRow[]): string {
  const header = 'full_name,politician_id,state,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification';
  const dataRows = rows.map((r) => {
    const escapedName = `"${r.full_name.replace(/"/g, '""')}"`;
    const topicKeys = `"${r.affected_topic_keys.join('|')}"`;
    return `${escapedName},${r.politician_id},${r.state},${r.party},${r.total_stances},${r.unsourced_count},${r.weak_count},${topicKeys},${r.classification}`;
  });
  return [header, ...dataRows].join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const runDate = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  console.error('Phase 101 Senator Source Triage — starting queries...');

  // Query A — Summary counts
  console.error('  Query A: senator summary counts...');
  const summary = await querySenatorSummary();
  console.error(`    total_senators: ${summary.total_senators}`);
  console.error(`    total_stances: ${summary.total_stances}`);
  console.error(`    unsourced_stance_count: ${summary.unsourced_stance_count}`);
  console.error(`    weak_stance_count: ${summary.weak_stance_count}`);

  if (DRY_RUN) {
    console.error('\nDry run complete — no files written.');
    await pool.end();
    return;
  }

  // Query B — Per-senator targets
  console.error('  Query B: per-senator target list...');
  const targets = await querySenatorTargets();
  console.error(`    Senators flagged: ${targets.length}`);

  // Query C — Topic-level detail
  console.error('  Query C: affected topic detail...');
  const details = await querySenatorTopicDetail();
  console.error(`    Affected stance rows: ${details.length}`);

  // Build and write outputs
  console.error('\nBuilding report and CSV...');

  const report = buildReport(summary, targets, details, runDate);
  const csv = buildCsv(targets);

  const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '101-candidate-profiles');
  mkdirSync(phaseDir, { recursive: true });

  const reportPath = path.resolve(phaseDir, '101-TRIAGE-REPORT.md');
  writeFileSync(reportPath, report, 'utf8');
  console.error(`  Written: ${reportPath}`);

  const csvPath = path.resolve(phaseDir, '101-SENATOR-TARGETS.csv');
  writeFileSync(csvPath, csv, 'utf8');
  console.error(`  Written: ${csvPath}`);

  // Plan 02 scope summary
  const totalFlagged = targets.length;
  const unsourcedOnly = targets.filter((t) => t.classification === 'unsourced_only').length;
  const weakOnly = targets.filter((t) => t.classification === 'weak_only').length;
  const both = targets.filter((t) => t.classification === 'both').length;

  let batchingLabel: string;
  if (totalFlagged <= 10) batchingLabel = '1 plan';
  else if (totalFlagged <= 25) batchingLabel = '2 plans';
  else batchingLabel = '3 plans';

  console.log(
    `Plan 02 scope: ${totalFlagged} senators flagged (${unsourcedOnly} unsourced + ${weakOnly} weak-sourced + ${both} both) — recommended batching: ${batchingLabel} (per D-03)`
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

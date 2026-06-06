/**
 * run-ca-source-triage.ts — Phase 103 CA State Politician Source Triage
 *
 * Queries the live Supabase DB to identify CA state politicians (Assembly, Senate,
 * statewide executives) with unsourced or weak-sourced stances.
 *
 * Outputs:
 *   .planning/phases/103-state-remediation-ca-md/103-CA-TRIAGE-REPORT.md
 *   .planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv
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
 * CA scope: district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC') AND state = 'CA'
 * (Verified via live DB pre-flight in Plan 01 Task 1 — 103-CA-TRIAGE-REPORT.md Step E)
 *
 * Dual detection: unsourced stances + weak-source (homepage-only) stances.
 * HAVING clause: SUM(unsourced_case) > 0 OR COUNT(weak_case) > 0 — captures both.
 *
 * Usage:
 *   cd backend
 *   npx tsx scripts/run-ca-source-triage.ts             # Full triage (writes files)
 *   npx tsx scripts/run-ca-source-triage.ts --dry-run   # Counts to stderr, no files written
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import { writeFileSync, mkdirSync, readFileSync, existsSync } from 'node:fs';

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
// run-house-source-triage.ts (Phase 100 locked sourced definition, D-01)
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
  state: string;
  district_type: string;
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
  district_type: string;
  topic_key: string;
  current_value: number;
  current_sources: string[] | null;
  source_status: string;
}

// ---------------------------------------------------------------------------
// CA_POLITICIANS_CTE — all active CA state-tier politicians
// district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC') verified via
// live DB pre-flight in Plan 01 Task 1 — 103-CA-TRIAGE-REPORT.md Step E.
// DISTINCT ON (p.id) prevents Cartesian product for politicians with multiple office rows.
// ---------------------------------------------------------------------------

const CA_POLITICIANS_CTE = `
  ca_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state,
      d.district_type
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
    WHERE p.is_active = true
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
    ORDER BY p.id
  )`;

// ---------------------------------------------------------------------------
// Query A — CA triage summary (total_politicians, total_stances, unsourced, weak)
// ---------------------------------------------------------------------------

async function queryCASummary(): Promise<SummaryRow> {
  const result = await pool.query<SummaryRow>(`
    WITH ${CA_POLITICIANS_CTE}
    SELECT
      (SELECT COUNT(*) FROM ca_politicians)::text AS total_politicians,
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
    FROM ca_politicians cp
    JOIN inform.politician_answers pa ON pa.politician_id = cp.id
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query B — Per-CA-politician target list
// Only politicians with at least one unsourced OR weak-sourced stance.
// ---------------------------------------------------------------------------

async function queryCATargets(): Promise<TargetRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    district_type: string;
    party: string;
    total_stances: string;
    unsourced_count: string;
    weak_count: string;
    affected_topic_keys: string | null;
    classification: string;
  }>(`
    WITH ${CA_POLITICIANS_CTE},
    per_politician AS (
      SELECT
        cp.id AS politician_id,
        cp.full_name,
        cp.state,
        cp.district_type,
        cp.party,
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
      FROM ca_politicians cp
      JOIN inform.politician_answers pa ON pa.politician_id = cp.id
      LEFT JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id
        AND pc.topic_id = pa.topic_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
      GROUP BY cp.id, cp.full_name, cp.state, cp.district_type, cp.party
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
      district_type,
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
    FROM per_politician
    ORDER BY classification DESC, full_name ASC
  `);

  return result.rows.map((r) => ({
    ...r,
    affected_topic_keys: r.affected_topic_keys ? r.affected_topic_keys.split('|') : [],
  }));
}

// ---------------------------------------------------------------------------
// Query C — Affected-topic detail rollup (per CA politician × topic_key)
// ---------------------------------------------------------------------------

async function queryCATopicDetail(): Promise<DetailRow[]> {
  const result = await pool.query<{
    full_name: string;
    politician_id: string;
    state: string;
    district_type: string;
    topic_key: string;
    current_value: number;
    current_sources: string[] | null;
    source_status: string;
  }>(`
    WITH ${CA_POLITICIANS_CTE}
    SELECT
      cp.full_name,
      cp.id::text AS politician_id,
      cp.state,
      cp.district_type,
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
    FROM ca_politicians cp
    JOIN inform.politician_answers pa ON pa.politician_id = cp.id
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
    ORDER BY cp.district_type ASC, cp.full_name ASC, t.topic_key ASC
  `);
  return result.rows;
}

// ---------------------------------------------------------------------------
// Report builder — preserves pre-flight section from Task 1, then adds report body
// ---------------------------------------------------------------------------

function buildReport(
  summary: SummaryRow,
  targets: TargetRow[],
  details: DetailRow[],
  runDate: string,
  existingReportPath: string,
): string {
  // PRESERVE the pre-flight discoveries section from Task 1 (103-CA-TRIAGE-REPORT.md)
  let preflightSection = '';
  if (!existsSync(existingReportPath)) {
    console.error('Fatal: 103-CA-TRIAGE-REPORT.md does not exist. Task 1 must run before Task 3.');
    process.exit(1);
  }
  const existingContent = readFileSync(existingReportPath, 'utf8');
  const preflightStart = existingContent.indexOf('## Pre-flight discoveries (Plan 01 Task 1)');
  if (preflightStart !== -1) {
    // Extract until the next ## heading or EOF
    const afterPreflight = existingContent.slice(preflightStart);
    // Find next ## heading after the pre-flight section
    const nextHeadingMatch = afterPreflight.slice(2).match(/\n## /);
    if (nextHeadingMatch && nextHeadingMatch.index !== undefined) {
      preflightSection = afterPreflight.slice(0, nextHeadingMatch.index + 2);
    } else {
      preflightSection = afterPreflight;
    }
  }

  const flaggedCount = targets.length;
  const unsourcedOnly = targets.filter((t) => t.classification === 'unsourced_only').length;
  const weakOnly = targets.filter((t) => t.classification === 'weak_only').length;
  const both = targets.filter((t) => t.classification === 'both').length;

  // Plan 02 batching tier
  let batchingTier: string;
  if (flaggedCount <= 10) {
    batchingTier = `Recommended batching: 1 research plan (≤ 10 threshold)`;
  } else if (flaggedCount <= 25) {
    batchingTier = `Recommended batching: 2 research plans (11–25 threshold — split alphabetically or by district_type)`;
  } else {
    batchingTier = `Recommended batching: 3+ research plans (26+ threshold — planner discretion)`;
  }

  // --- Executive Summary ---
  const execSummary = `## Executive Summary

| Metric | Value |
|--------|-------|
| total_politicians | ${summary.total_politicians} |
| total_stances | ${summary.total_stances} |
| unsourced_stance_count | ${summary.unsourced_stance_count} |
| weak_stance_count | ${summary.weak_stance_count} |
| Politicians flagged | ${flaggedCount} |
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

**Weak-source detection (Phase 101 D-01):**
A sourced row is classified as "weak" when every non-blank URL matches the homepage-only pattern:
\`^https?://[^/]+/?$\`
(domain root with no path, e.g. \`https://www.senator.gov\` or \`https://sd07.senate.ca.gov/\`).
Applied via Postgres \`~\` operator against every non-blank element of \`inform.politician_context.sources\`.

**CA dual-detection scope (CONTEXT.md D-01):**
This triage captures both:
- (1) Politicians with unsourced stances (missing context row, empty sources array, blank URLs)
- (2) Politicians with weak-source stances (ALL non-blank URLs are homepage-only)

HAVING clause: \`SUM(unsourced_case) > 0 OR COUNT(weak_case) > 0\` — includes both categories.

**CA politician scope (CONTEXT.md D-02):**
\`essentials.offices JOIN essentials.districts WHERE d.state = 'CA' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')\`
with \`DISTINCT ON (politician_id)\` to prevent multi-office Cartesian inflation.
Active politicians only (\`p.is_active = true\`).`;

  // --- CA Unsourced Stances section ---
  const unsourcedTargets = targets.filter(
    (t) => t.classification === 'unsourced_only' || t.classification === 'both',
  );

  let unsourcedSection = `## CA — Unsourced Stances\n\n`;
  if (unsourcedTargets.length === 0) {
    unsourcedSection += '_No CA politicians with unsourced stances found._\n';
  } else {
    for (const pol of unsourcedTargets) {
      const polDetails = details.filter(
        (d) => d.politician_id === pol.politician_id && d.source_status === 'unsourced',
      );
      unsourcedSection += `### ${pol.full_name} (${pol.district_type}, ${pol.party})\n\n`;
      unsourcedSection += `- **politician_id:** ${pol.politician_id}\n`;
      unsourcedSection += `- **unsourced_count:** ${pol.unsourced_count}\n`;
      unsourcedSection += `- **Affected topics:**\n\n`;
      unsourcedSection += `| topic_key | current_value | current_sources |\n`;
      unsourcedSection += `|-----------|---------------|----------------|\n`;
      for (const d of polDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        unsourcedSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      unsourcedSection += '\n';
    }
  }

  // --- CA Weak-Sourced Stances section ---
  const weakTargets = targets.filter(
    (t) => t.classification === 'weak_only' || t.classification === 'both',
  );

  let weakSection = `## CA — Weak-Sourced Stances (homepage-only)\n\n`;
  if (weakTargets.length === 0) {
    weakSection += '_No CA politicians with weak-sourced stances found._\n';
  } else {
    for (const pol of weakTargets) {
      const polDetails = details.filter(
        (d) => d.politician_id === pol.politician_id && d.source_status === 'weak',
      );
      weakSection += `### ${pol.full_name} (${pol.district_type}, ${pol.party})\n\n`;
      weakSection += `- **politician_id:** ${pol.politician_id}\n`;
      weakSection += `- **weak_count:** ${pol.weak_count}\n`;
      weakSection += `- **Affected topics (homepage-only source URL):**\n\n`;
      weakSection += `| topic_key | current_value | current_sources |\n`;
      weakSection += `|-----------|---------------|----------------|\n`;
      for (const d of polDetails) {
        const sourcesDisplay = d.current_sources && d.current_sources.length > 0
          ? d.current_sources.join(', ')
          : '_(none)_';
        weakSection += `| ${d.topic_key} | ${d.current_value} | ${sourcesDisplay} |\n`;
      }
      weakSection += '\n';
    }
  }

  // --- Combined Target List table ---
  // Sorted: both → unsourced_only → weak_only, then by full_name
  const sortedTargets = [...targets].sort((a, b) => {
    const classOrder: Record<string, number> = { both: 0, unsourced_only: 1, weak_only: 2 };
    const classA = classOrder[a.classification] ?? 3;
    const classB = classOrder[b.classification] ?? 3;
    if (classA !== classB) return classA - classB;
    return a.full_name.localeCompare(b.full_name);
  });

  let targetTable = `## Combined Target List\n\n`;
  targetTable += `| full_name | district_type | party | unsourced_count | weak_count | classification | affected_topic_keys |\n`;
  targetTable += `|-----------|---------------|-------|-----------------|------------|----------------|--------------------|\n`;
  for (const t of sortedTargets) {
    const topicsPreview = t.affected_topic_keys.join('|');
    const truncated = topicsPreview.length > 80 ? topicsPreview.slice(0, 77) + '...' : topicsPreview;
    targetTable += `| ${t.full_name} | ${t.district_type} | ${t.party} | ${t.unsourced_count} | ${t.weak_count} | ${t.classification} | ${truncated} |\n`;
  }
  if (sortedTargets.length === 0) {
    targetTable += `_No flagged CA politicians._\n`;
  }

  // --- Plan 02 Scoping Note ---
  const scopingNote = `## Plan 02 Scoping

**Total CA politicians flagged:** ${flaggedCount}
- unsourced_only: ${unsourcedOnly}
- weak_only: ${weakOnly}
- both: ${both}

**${batchingTier}**

Machine-readable target list: \`.planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv\``;

  return `# Phase 103 — CA State Source Triage Report

Generated: ${runDate}

---

${preflightSection}
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
// Header: full_name,politician_id,state,district_type,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification
// affected_topic_keys stored as pipe-delimited string inside a double-quoted field.
// ---------------------------------------------------------------------------

function buildCsv(rows: TargetRow[]): string {
  const header = 'full_name,politician_id,state,district_type,party,total_stances,unsourced_count,weak_count,affected_topic_keys,classification';
  const dataRows = rows.map((r) => {
    const escapedName = `"${r.full_name.replace(/"/g, '""')}"`;
    const topicKeys = `"${r.affected_topic_keys.join('|')}"`;
    return `${escapedName},${r.politician_id},${r.state},${r.district_type},${r.party},${r.total_stances},${r.unsourced_count},${r.weak_count},${topicKeys},${r.classification}`;
  });
  return [header, ...dataRows].join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const runDate = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  console.error('Phase 103 CA State Source Triage — starting queries...');

  // Query A — Summary counts
  console.error('  Query A: CA summary counts...');
  const summary = await queryCASummary();
  console.error(`    total_politicians: ${summary.total_politicians}`);
  console.error(`    total_stances: ${summary.total_stances}`);
  console.error(`    unsourced_stance_count: ${summary.unsourced_stance_count}`);
  console.error(`    weak_stance_count: ${summary.weak_stance_count}`);

  if (DRY_RUN) {
    console.error('\nDry-run preview — fetching first 5 target politicians...');
    const targets = await queryCATargets();
    console.error(`    Total flagged politicians: ${targets.length}`);
    console.error('    First 5 targets:');
    for (const t of targets.slice(0, 5)) {
      console.error(`      - ${t.full_name} (${t.district_type}, ${t.party}) — classification: ${t.classification}, unsourced: ${t.unsourced_count}, weak: ${t.weak_count}`);
    }
    console.error('\nDry run complete — no files written.');
    await pool.end();
    return;
  }

  // Query B — Per-target list
  console.error('  Query B: CA target list...');
  const targets = await queryCATargets();
  console.error(`    CA flagged: ${targets.length}`);

  // Query C — Topic-level detail
  console.error('  Query C: CA affected topic detail...');
  const details = await queryCATopicDetail();
  console.error(`    CA affected stance rows: ${details.length}`);

  // Build and write outputs
  console.error('\nBuilding report and CSV...');

  const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '103-state-remediation-ca-md');
  mkdirSync(phaseDir, { recursive: true });

  const reportPath = path.resolve(phaseDir, '103-CA-TRIAGE-REPORT.md');
  const report = buildReport(summary, targets, details, runDate, reportPath);
  writeFileSync(reportPath, report, 'utf8');
  console.error(`  Written: ${reportPath}`);

  const csvPath = path.resolve(phaseDir, '103-CA-TARGETS.csv');
  const csv = buildCsv(targets);
  writeFileSync(csvPath, csv, 'utf8');
  console.error(`  Written: ${csvPath}`);

  // Stdout summary line
  const flaggedCount = targets.length;
  const totalUnsourced = parseInt(summary.unsourced_stance_count, 10);
  const totalWeak = parseInt(summary.weak_stance_count, 10);

  let batchingTier: string;
  if (flaggedCount <= 10) {
    batchingTier = '1 research plan (≤ 10 threshold)';
  } else if (flaggedCount <= 25) {
    batchingTier = '2 research plans (11–25 threshold)';
  } else {
    batchingTier = '3+ research plans (26+ threshold)';
  }

  console.log(
    `Plan 02 scope: ${flaggedCount} CA politicians flagged (${totalUnsourced} unsourced + ${totalWeak} weak-source stances) — recommended batching: ${batchingTier}`
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

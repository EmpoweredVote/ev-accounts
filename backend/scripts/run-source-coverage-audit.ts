/**
 * run-source-coverage-audit.ts — Phase 100 Source Coverage Audit
 *
 * Queries the live Supabase DB to establish a baseline of how many
 * inform.politician_answers rows have real source URLs in
 * inform.politician_context.sources[], broken down by tier and milestone cohort.
 *
 * Outputs:
 *   .planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md
 *   .planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv
 *
 * "Sourced" definition (operationalized for v2.7):
 *   1. A row exists in inform.politician_context with the same (politician_id, topic_id).
 *   2. sources is NOT NULL.
 *   3. array_length(sources, 1) IS NOT NULL (i.e., the array is not empty).
 *   4. At least one element of sources is a non-blank string (trim(element) != '').
 *
 * Usage:
 *   cd backend
 *   npx tsx scripts/run-source-coverage-audit.ts             # Full audit (writes files)
 *   npx tsx scripts/run-source-coverage-audit.ts --dry-run   # Counts to stderr, no files written
 */

import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import { writeFileSync } from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TotalRow {
  total_stances: string;
  sourced_stances: string;
  unsourced_stances: string;
  pct_sourced: string;
}

interface TierRow {
  tier: string;
  tier_rank: string;
  total_stances: string;
  sourced_stances: string;
  unsourced_stances: string;
  pct_sourced: string;
}

interface CohortRow {
  cohort: string;
  total_stances: string;
  sourced_stances: string;
  unsourced_stances: string;
  pct_sourced: string;
}

interface TargetRow {
  full_name: string;
  politician_id: string;
  tier: string;
  tier_rank: string;
  total_stances: string;
  unsourced_count: string;
  unsourced_pct: string;
  majority_unsourced: boolean;
}

interface WeakSourceRow {
  weak_source_count: string;
}

interface MdOfficialRow {
  full_name: string;
  politician_id: string;
  stance_count: string;
}

// ---------------------------------------------------------------------------
// Helper: SOURCED CASE expression (used in multiple queries)
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

// ---------------------------------------------------------------------------
// Query A — Total & Sourced Count (SRCA-01 executive summary)
// ---------------------------------------------------------------------------

async function queryTotal(): Promise<TotalRow> {
  const result = await pool.query<TotalRow>(`
    SELECT
      COUNT(pa.topic_id)::text AS total_stances,
      SUM(${SOURCED_CASE})::text AS sourced_stances,
      (COUNT(pa.topic_id) - SUM(${SOURCED_CASE}))::text AS unsourced_stances,
      ROUND(SUM(${SOURCED_CASE}) * 100.0 / NULLIF(COUNT(pa.topic_id), 0), 1)::text AS pct_sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    WHERE pa.politician_id IN (
      SELECT id FROM essentials.politicians WHERE is_active = true
    )
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query B — Tier Breakdown (SRCA-01 tier table)
// Tier derived from essentials.districts.district_type via DISTINCT ON subquery.
// City sub-classification: LOCAL officials whose government name ILIKE 'City of %'.
// NEVER use essentials.offices.title — "Senator" matches both US and State Senators.
// ---------------------------------------------------------------------------

async function queryTierBreakdown(): Promise<TierRow[]> {
  const result = await pool.query<TierRow>(`
    WITH tier_assignments AS (
      SELECT DISTINCT ON (p.id)
        p.id AS politician_id,
        CASE
          WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
            THEN 'Federal'
          WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
            THEN 'State'
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            AND g.name ILIKE 'City of %'
            THEN 'City'
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            THEN 'Local'
          ELSE 'Unknown'
        END AS tier,
        CASE
          WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
            THEN 1
          WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
            THEN 2
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            AND g.name ILIKE 'City of %'
            THEN 3
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            THEN 3
          ELSE 4
        END AS tier_rank
      FROM essentials.politicians p
      LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.governments g ON g.id = d.government_id
      WHERE p.is_active = true
      ORDER BY p.id, tier_rank ASC
    )
    SELECT
      ta.tier,
      ta.tier_rank::text,
      COUNT(pa.topic_id)::text AS total_stances,
      SUM(${SOURCED_CASE})::text AS sourced_stances,
      (COUNT(pa.topic_id) - SUM(${SOURCED_CASE}))::text AS unsourced_stances,
      ROUND(SUM(${SOURCED_CASE}) * 100.0 / NULLIF(COUNT(pa.topic_id), 0), 1)::text AS pct_sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN tier_assignments ta ON ta.politician_id = pa.politician_id
    GROUP BY ta.tier, ta.tier_rank
    ORDER BY ta.tier_rank ASC, ta.tier ASC
  `);
  return result.rows;
}

// ---------------------------------------------------------------------------
// Query C — Milestone Cohort Breakdown (SRCA-01 cohort table)
// ---------------------------------------------------------------------------

async function queryMilestoneCohorts(): Promise<CohortRow[]> {
  const cohorts: CohortRow[] = [];

  // v2.3 senators: district_type = 'NATIONAL_UPPER'
  const senResult = await pool.query<{ total: string; sourced: string }>(`
    SELECT
      COUNT(pa.topic_id)::text AS total,
      SUM(${SOURCED_CASE})::text AS sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN essentials.offices o ON o.politician_id = pa.politician_id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'NATIONAL_UPPER'
    JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
  `);
  const senRow = senResult.rows[0];
  const senTotal = parseInt(senRow.total, 10);
  const senSourced = parseInt(senRow.sourced, 10);
  cohorts.push({
    cohort: 'v2.3 — US Senators (100 senators)',
    total_stances: senRow.total,
    sourced_stances: senRow.sourced,
    unsourced_stances: String(senTotal - senSourced),
    pct_sourced: senTotal > 0 ? String(Math.round((senSourced / senTotal) * 1000) / 10) : '0.0',
  });

  // v2.4 candidates: external_id BETWEEN -400143 AND -400101
  const candResult = await pool.query<{ total: string; sourced: string }>(`
    SELECT
      COUNT(pa.topic_id)::text AS total,
      SUM(${SOURCED_CASE})::text AS sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
      AND p.is_active = true
      AND p.external_id BETWEEN -400143 AND -400101
  `);
  const candRow = candResult.rows[0];
  const candTotal = parseInt(candRow.total, 10);
  const candSourced = parseInt(candRow.sourced, 10);
  cohorts.push({
    cohort: 'v2.4 — 2026 Senate Candidates (43 candidates)',
    total_stances: candRow.total,
    sourced_stances: candRow.sourced,
    unsourced_stances: String(candTotal - candSourced),
    pct_sourced: candTotal > 0 ? String(Math.round((candSourced / candTotal) * 1000) / 10) : '0.0',
  });

  // v2.5 city officials: government is one of the 5 known CA cities
  const cityResult = await pool.query<{ total: string; sourced: string }>(`
    SELECT
      COUNT(pa.topic_id)::text AS total,
      SUM(${SOURCED_CASE})::text AS sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
    JOIN essentials.offices o ON o.politician_id = pa.politician_id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.governments g ON g.id = d.government_id
      AND g.name IN (
        'City of San Francisco',
        'City of San Jose',
        'City of San Diego',
        'City of Berkeley',
        'City of Fremont'
      )
  `);
  const cityRow = cityResult.rows[0];
  const cityTotal = parseInt(cityRow.total, 10);
  const citySourced = parseInt(cityRow.sourced, 10);
  cohorts.push({
    cohort: 'v2.5 — City Officials (SF, SJ, SD, Berkeley, Fremont)',
    total_stances: cityRow.total,
    sourced_stances: cityRow.sourced,
    unsourced_stances: String(cityTotal - citySourced),
    pct_sourced: cityTotal > 0 ? String(Math.round((citySourced / cityTotal) * 1000) / 10) : '0.0',
  });

  // MD officials migrations 269–271: Wes Moore, Aruna Miller, Anthony Brown,
  // Brooke Lierman, Dereck Davis — external_id range -240005 to -240001
  // These are expected to have zero stance rows.
  const mdResult = await pool.query<{ total: string; sourced: string }>(`
    SELECT
      COUNT(pa.topic_id)::text AS total,
      SUM(${SOURCED_CASE})::text AS sourced
    FROM inform.politician_answers pa
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
      AND p.external_id BETWEEN -240005 AND -240001
  `);
  const mdRow = mdResult.rows[0];
  const mdTotal = parseInt(mdRow.total, 10);
  const mdSourced = parseInt(mdRow.sourced, 10);
  cohorts.push({
    cohort: 'Migrations 269–271 — MD Officials (Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis)',
    total_stances: mdRow.total,
    sourced_stances: mdRow.sourced,
    unsourced_stances: String(mdTotal - mdSourced),
    pct_sourced: '0.0 (0 stances — Phase 103 STAX-02 scope)',
  });

  return cohorts;
}

// ---------------------------------------------------------------------------
// Query D — Per-Politician Target List (SRCA-02 CSV)
// Uses Pattern 3 from 100-RESEARCH.md.
// DISTINCT ON in tier subquery prevents multi-office Cartesian products.
// HAVING > 0 includes only politicians with at least one unsourced stance.
// City detection: LOCAL/LOCAL_EXEC politicians under "City of X" governments.
// ---------------------------------------------------------------------------

async function queryTargetList(): Promise<TargetRow[]> {
  const result = await pool.query<TargetRow>(`
    SELECT
      p.full_name,
      p.id::text AS politician_id,
      COALESCE(tier_subq.tier, 'Unknown') AS tier,
      COALESCE(tier_subq.tier_rank, 4)::text AS tier_rank,
      COUNT(pa.topic_id)::text AS total_stances,
      SUM(
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
        END
      )::text AS unsourced_count,
      ROUND(
        SUM(
          CASE
            WHEN pc.politician_id IS NULL
                 OR pc.sources IS NULL
                 OR array_length(pc.sources, 1) IS NULL
                 OR NOT EXISTS (
                   SELECT 1 FROM unnest(pc.sources) AS s(url)
                   WHERE url IS NOT NULL AND trim(url) <> ''
                 )
            THEN 1.0
            ELSE 0.0
          END
        ) / NULLIF(COUNT(pa.topic_id), 0) * 100,
        1
      )::text AS unsourced_pct,
      (
        SUM(
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
          END
        ) > COUNT(pa.topic_id) / 2.0
      ) AS majority_unsourced
    FROM inform.politician_answers pa
    JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
    LEFT JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id
      AND pc.topic_id = pa.topic_id
    LEFT JOIN (
      SELECT DISTINCT ON (p2.id)
        p2.id AS pid,
        CASE
          WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
            THEN 'Federal'
          WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
            THEN 'State'
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            AND g.name ILIKE 'City of %'
            THEN 'City'
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            THEN 'Local'
          ELSE 'Unknown'
        END AS tier,
        CASE
          WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
            THEN 1
          WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
            THEN 2
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            AND g.name ILIKE 'City of %'
            THEN 3
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            THEN 3
          ELSE 4
        END AS tier_rank
      FROM essentials.politicians p2
      LEFT JOIN essentials.offices o ON o.politician_id = p2.id AND o.is_vacant = false
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.governments g ON g.id = d.government_id
      WHERE p2.is_active = true
      ORDER BY p2.id, (
        CASE
          WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
            THEN 1
          WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
            THEN 2
          WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
            THEN 3
          ELSE 4
        END
      ) ASC
    ) tier_subq ON tier_subq.pid = p.id
    WHERE p.is_active = true
    GROUP BY p.full_name, p.id, tier_subq.tier, tier_subq.tier_rank
    HAVING SUM(
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
      END
    ) > 0
    ORDER BY
      COALESCE(tier_subq.tier_rank, 4) ASC NULLS LAST,
      (
        SUM(
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
          END
        ) > COUNT(pa.topic_id) / 2.0
      ) DESC,
      SUM(
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
        END
      ) DESC,
      p.full_name ASC
  `);
  return result.rows;
}

// ---------------------------------------------------------------------------
// Query E — Weak Source Count (homepage-only URLs)
// Count context rows where the only non-blank element matches a domain-root pattern.
// These are counted as SOURCED in the totals but flagged here.
// ---------------------------------------------------------------------------

async function queryWeakSources(): Promise<WeakSourceRow> {
  const result = await pool.query<WeakSourceRow>(`
    SELECT COUNT(*)::text AS weak_source_count
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id AND p.is_active = true
    WHERE pc.sources IS NOT NULL
      AND array_length(pc.sources, 1) IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL
          AND trim(url) <> ''
          AND trim(url) !~ '^https?://[^/]+/?$'
      )
      AND EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
  `);
  return result.rows[0];
}

// ---------------------------------------------------------------------------
// Query F — MD Officials Dedicated Section
// Five MD officials from migrations 269–271 (external_id -240005 to -240001).
// Expected: zero stance rows each. Listed as:
//   Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis
// Note: DB full_names include middle initials (Anthony G. Brown, Dereck E. Davis).
// ---------------------------------------------------------------------------

async function queryMdOfficials(): Promise<MdOfficialRow[]> {
  const result = await pool.query<MdOfficialRow>(`
    SELECT
      p.full_name,
      p.id::text AS politician_id,
      COUNT(pa.topic_id)::text AS stance_count
    FROM essentials.politicians p
    LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
    WHERE p.external_id BETWEEN -240005 AND -240001
    GROUP BY p.full_name, p.id
    ORDER BY p.external_id DESC
  `);
  return result.rows;
}

// ---------------------------------------------------------------------------
// Report builder
// ---------------------------------------------------------------------------

function buildReport(
  total: TotalRow,
  tiers: TierRow[],
  cohorts: CohortRow[],
  mdOfficials: MdOfficialRow[],
  weakCount: string,
  runDate: string,
): string {
  const tierTable = tiers.map((t) =>
    `| ${t.tier} | ${t.total_stances} | ${t.sourced_stances} | ${t.unsourced_stances} | ${t.pct_sourced}% |`
  ).join('\n');

  const cohortTable = cohorts.map((c) =>
    `| ${c.cohort} | ${c.total_stances} | ${c.sourced_stances} | ${c.unsourced_stances} | ${c.pct_sourced}% |`
  ).join('\n');

  const mdTable = mdOfficials.map((m) =>
    `| ${m.full_name} | ${m.politician_id} | ${m.stance_count} | MD | No stances yet — Phase 103 STAX-02 scope |`
  ).join('\n');

  return `# Phase 100 — Source Coverage Audit Report

Generated: ${runDate}

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Stances | ${total.total_stances} |
| Sourced Stances | ${total.sourced_stances} |
| Unsourced Stances | ${total.unsourced_stances} |
| % Sourced | ${total.pct_sourced}% |

---

## Tier Breakdown

| Tier | Total Stances | Sourced | Unsourced | % Sourced |
|------|--------------|---------|-----------|-----------|
${tierTable}

---

## Milestone Cohorts

| Cohort | Total Stances | Sourced | Unsourced | % Sourced |
|--------|--------------|---------|-----------|-----------|
${cohortTable}

---

## "Sourced" Definition

A stance in \`inform.politician_answers\` counts as **sourced** for v2.7 Source Integrity when ALL of the following are true:

1. A row exists in \`inform.politician_context\` with the same \`(politician_id, topic_id)\` composite key.
2. \`sources\` is NOT NULL (defensive; schema default is \`'{}'\` but early rows cannot be assumed).
3. \`array_length(sources, 1)\` is NOT NULL — Postgres returns NULL for empty arrays, not 0. This detects the \`ARRAY[]::text[]\` pattern used in migrations where no evidence was found (confirmed in migration 233: 2 CA Assembly stances).
4. At least one element of \`sources\` passes \`url IS NOT NULL AND trim(url) <> ''\` — eliminates blank-string array elements.

Conditions that make a stance **unsourced**:
- Missing context row (orphan answer — no matching row in \`politician_context\`)
- Context row exists but \`sources = ARRAY[]::text[]\` (empty array)
- Context row exists but \`sources IS NULL\`
- Context row exists but all elements are blank strings

**Weak sources** (counted as sourced, noted separately): Context rows where the only non-blank URL is a domain root with no path (e.g., \`https://sd07.senate.ca.gov\`). These technically pass the four-rule test above but may lack specific evidence. Count: **${weakCount}** rows. Remediation phases 101–104 should evaluate these under QUAL-01 ("URL links to a primary source").

This definition is locked for all v2.7 remediation phases (101–104). Every phase that sources a stance or deletes one must apply this same standard.

---

## Weak Sources Note

**${weakCount}** stance(s) have a context row with at least one non-blank URL, but every non-blank URL matches the homepage-only pattern \`^https?://[^/]+/?$\` (a domain root with no path component, e.g., \`https://sd07.senate.ca.gov\`).

These rows are counted as **sourced** in all totals above. Phases 101–104 should review these rows against QUAL-01: "every updated or added stance links to a primary source that contains specific evidence of the politician's position." A homepage URL alone does not satisfy QUAL-01.

**Recommendation for remediation phases:** Filter target politicians by checking whether any of their sourced URLs match the homepage pattern. Treat homepage-only rows as low-confidence sources during the Chair methodology re-verification step.

---

## MD Officials (Migrations 269–271)

The following 5 Maryland state executive officials were added in migrations 269 (chambers), 270 (politicians + offices), and 271 (headshots). As of this audit, they have zero stance rows in \`inform.politician_answers\`. They are **not** included in the TARGET-LIST.csv (which lists politicians with at least one unsourced stance). Their research is scoped to Phase 103, requirement STAX-02.

MD official names in plan references: Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis.
DB full_names (with middle initials where applicable): see table below.

| Full Name (DB) | Politician ID | Stance Count | Expected State | Note |
|----------------|---------------|-------------|----------------|------|
${mdTable}

**Phase 103 action (STAX-02):** Research stances from scratch for all 5 officials using the Chair methodology. Every added stance must have a context row with at least one real primary source URL.

---

## Methodology Notes

- **Database:** Live Supabase production database (connection via \`DATABASE_URL\` in \`backend/.env\`)
- **Run date:** ${runDate}
- **Query patterns:** See \`100-RESEARCH.md\` Patterns 1–5 for the SQL templates used here
- **All queries use \`pool.query()\`** — the \`inform\` schema is not in the PostgREST exposed schema list; PostgREST calls silently fail for \`inform.*\`
- **Active politicians only:** All queries filter \`WHERE p.is_active = true\` to exclude historical/inactive records
- **Tier classification source:** \`essentials.districts.district_type\` via offices join — never from \`essentials.offices.title\` (title="Senator" matches both US and State senators)
- **DISTINCT ON in tier subquery:** Prevents multi-office Cartesian product inflation (a politician with multiple office rows produces only one tier assignment, using the highest-priority tier rank)
- **City vs Local distinction:** City = LOCAL/LOCAL_EXEC district where \`essentials.governments.name ILIKE 'City of %'\`
- **Cohort scoping:**
  - v2.3 senators: \`district_type = 'NATIONAL_UPPER'\`
  - v2.4 candidates: \`external_id BETWEEN -400143 AND -400101\`
  - v2.5 city officials: government name IN ('City of San Francisco', 'City of San Jose', 'City of San Diego', 'City of Berkeley', 'City of Fremont')
  - MD officials: \`external_id BETWEEN -240005 AND -240001\`
`;
}

// ---------------------------------------------------------------------------
// CSV builder
// ---------------------------------------------------------------------------

function buildCsv(rows: TargetRow[]): string {
  const header = 'full_name,politician_id,tier,tier_rank,total_stances,unsourced_count,unsourced_pct,majority_unsourced';
  const dataRows = rows.map((r) => {
    const escapedName = `"${r.full_name.replace(/"/g, '""')}"`;
    return `${escapedName},${r.politician_id},${r.tier},${r.tier_rank},${r.total_stances},${r.unsourced_count},${r.unsourced_pct},${r.majority_unsourced}`;
  });
  return [header, ...dataRows].join('\n') + '\n';
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const runDate = new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

  console.error('Phase 100 Source Coverage Audit — starting queries...');

  // Query A — Totals
  console.error('  Query A: total and sourced counts...');
  const total = await queryTotal();
  console.error(`    Total stances: ${total.total_stances}`);
  console.error(`    Sourced: ${total.sourced_stances} (${total.pct_sourced}%)`);
  console.error(`    Unsourced: ${total.unsourced_stances}`);

  // Query B — Tier breakdown
  console.error('  Query B: tier breakdown...');
  const tiers = await queryTierBreakdown();
  for (const t of tiers) {
    console.error(`    ${t.tier}: ${t.total_stances} total, ${t.unsourced_stances} unsourced (${t.pct_sourced}% sourced)`);
  }

  // Query C — Milestone cohorts
  console.error('  Query C: milestone cohorts...');
  const cohorts = await queryMilestoneCohorts();
  for (const c of cohorts) {
    console.error(`    ${c.cohort}: ${c.total_stances} total, ${c.unsourced_stances} unsourced`);
  }

  // Query D — Target list
  console.error('  Query D: per-politician target list...');
  const targets = await queryTargetList();
  console.error(`    Politicians with unsourced stances: ${targets.length}`);

  // Query E — Weak sources
  console.error('  Query E: weak (homepage-only) source count...');
  const weakResult = await queryWeakSources();
  const weakCount = weakResult.weak_source_count;
  console.error(`    Weak source rows: ${weakCount}`);

  // Query F — MD officials
  console.error('  Query F: MD officials (migrations 269-271)...');
  const mdOfficials = await queryMdOfficials();
  for (const m of mdOfficials) {
    console.error(`    ${m.full_name}: ${m.stance_count} stances`);
  }

  if (DRY_RUN) {
    console.error('\nDry run complete — no files written.');
    await pool.end();
    return;
  }

  // Build and write outputs
  console.error('\nBuilding report and CSV...');

  const report = buildReport(total, tiers, cohorts, mdOfficials, weakCount, runDate);
  const csv = buildCsv(targets);

  const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '100-source-coverage-audit');
  const reportPath = path.resolve(phaseDir, '100-AUDIT-REPORT.md');
  const csvPath = path.resolve(phaseDir, '100-TARGET-LIST.csv');

  writeFileSync(reportPath, report, 'utf8');
  console.error(`  Written: ${reportPath}`);

  writeFileSync(csvPath, csv, 'utf8');
  console.error(`  Written: ${csvPath}`);

  console.error('\nAudit complete.');
  await pool.end();
  process.exit(0);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end().catch(() => {});
  process.exit(1);
});

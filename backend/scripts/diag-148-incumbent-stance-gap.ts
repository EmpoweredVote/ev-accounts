/**
 * Phase 148 — Field Resolution + Stance-Gap Diagnostic (READ-ONLY)
 *
 * Produces the DB half of the Wave-1 (CA/TX/FL/NY) US House field table:
 *   - Per-district incumbent -> essentials.politicians.id map (by geo_id, NEVER computed external_id)
 *   - Each incumbent's current compass stance count + top-up tier
 *   - Explicit enumeration of the two confirmed vacancies (FL-20 1220, TX-23 4823)
 *
 * SELECT-ONLY. Never INSERT/UPDATE/DELETE. Never pass --commit. Re-runnable / idempotent.
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-148-incumbent-stance-gap.ts
 *
 * Task 2 (CSV emit) is gated behind the read-only queries below and writes the
 * git-tracked phase-dir artifact 148-incumbent-map.csv (NOT a production DB write).
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';

// --- constants ------------------------------------------------------------
const WAVE1_FIPS = ['06', '48', '12', '36'] as const; // CA, TX, FL, NY
const FIPS_TO_STATE: Record<string, string> = {
  '06': 'CA',
  '48': 'TX',
  '12': 'FL',
  '36': 'NY',
};
const EXPECTED_PER_STATE: Record<string, number> = { '06': 52, '48': 38, '12': 28, '36': 26 };
const FEDERAL_TOPIC_BAR = 24;

// Confirmed vacancies (live-verified): FL-20 geo_id 1220, TX-23 geo_id 4823.
const VACANCY_GEO_IDS = new Set(['1220', '4823']);

const CSV_PATH = resolve(
  process.cwd(),
  '..',
  '.planning',
  'phases',
  '148-field-resolution-stance-gap-diagnostic',
  '148-incumbent-map.csv',
);

// --- row types ------------------------------------------------------------
interface IncumbentRow {
  state_fips: string;
  geo_id: string;
  politician_id: string;
  external_id: number | null;
  full_name: string;
  is_active: boolean;
  stance_count: number;
}

function topUpTier(stanceCount: number, vacant: boolean): 'zero' | 'partial' | 'done' | 'vacant' {
  if (vacant) return 'vacant';
  if (stanceCount === 0) return 'zero';
  if (stanceCount < FEDERAL_TOPIC_BAR) return 'partial';
  return 'done';
}

function csvField(value: unknown): string {
  if (value === null || value === undefined) return '';
  const s = String(value);
  // RFC-4180: quote any field containing comma, quote, CR, or LF.
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

async function main(): Promise<void> {
  console.log('=== Phase 148 incumbent + stance-gap diagnostic (READ-ONLY) ===\n');

  // -----------------------------------------------------------------------
  // Query A: per-district incumbent map (mapped incumbents only)
  // Join districts -> offices -> politicians on geo_id, scoped to NATIONAL_LOWER.
  // Map by (district_type, geo_id) ONLY — never compute/filter by external_id.
  // inform.politician_answers has NO id column -> COUNT(*), never COUNT(pa.id).
  // -----------------------------------------------------------------------
  const queryA = await pool.query<IncumbentRow>(
    `
    SELECT substr(d.geo_id, 1, 2)                       AS state_fips,
           d.geo_id                                     AS geo_id,
           p.id                                         AS politician_id,
           p.external_id                                AS external_id,
           p.full_name                                  AS full_name,
           p.is_active                                  AS is_active,
           (SELECT COUNT(*) FROM inform.politician_answers pa
             WHERE pa.politician_id = p.id)::int        AS stance_count
    FROM essentials.districts   d
    JOIN essentials.offices     o ON o.district_id = d.id
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE d.district_type = 'NATIONAL_LOWER'
      AND substr(d.geo_id, 1, 2) = ANY($1::text[])
    ORDER BY state_fips, d.geo_id
    `,
    [WAVE1_FIPS],
  );
  const incumbents = queryA.rows;
  console.log(`Query A — mapped incumbent rows: ${incumbents.length}  (expected 142 = 144 districts - 2 vacancies)\n`);

  // -----------------------------------------------------------------------
  // Query B: per-state stance-gap summary
  // -----------------------------------------------------------------------
  const queryB = await pool.query(
    `
    WITH inc AS (
      SELECT substr(d.geo_id, 1, 2) AS fips,
             p.id                    AS pid,
             (SELECT COUNT(*) FROM inform.politician_answers pa
               WHERE pa.politician_id = p.id)::int AS sc
      FROM essentials.districts   d
      JOIN essentials.offices     o ON o.district_id = d.id
      JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE d.district_type = 'NATIONAL_LOWER'
        AND substr(d.geo_id, 1, 2) = ANY($1::text[])
      GROUP BY substr(d.geo_id, 1, 2), p.id
    )
    SELECT fips,
           COUNT(*)                                 AS incumbent_records,
           COUNT(*) FILTER (WHERE sc = 0)           AS zero_stance,
           COUNT(*) FILTER (WHERE sc BETWEEN 1 AND 23) AS under24,
           COUNT(*) FILTER (WHERE sc >= 24)         AS at_or_above_24,
           MIN(sc)                                  AS min_sc,
           MAX(sc)                                  AS max_sc,
           ROUND(AVG(sc), 1)                        AS avg_sc
    FROM inc
    GROUP BY fips
    ORDER BY fips
    `,
    [WAVE1_FIPS],
  );
  console.log('Query B — per-state stance gap:');
  console.table(
    queryB.rows.map((r) => ({
      state: FIPS_TO_STATE[r.fips] ?? r.fips,
      fips: r.fips,
      incumbents: Number(r.incumbent_records),
      zero: Number(r.zero_stance),
      'partial(1-23)': Number(r.under24),
      'done(>=24)': Number(r.at_or_above_24),
      min: Number(r.min_sc),
      max: Number(r.max_sc),
      avg: Number(r.avg_sc),
    })),
  );
  console.log('');

  // -----------------------------------------------------------------------
  // Query C: vacancy detection (offices with holder_ct != 1)
  // -----------------------------------------------------------------------
  const queryC = await pool.query(
    `
    SELECT substr(d.geo_id, 1, 2)      AS fips,
           d.geo_id                    AS geo_id,
           COUNT(o.id)                 AS office_ct,
           COUNT(o.politician_id)      AS holder_ct
    FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE d.district_type = 'NATIONAL_LOWER'
      AND substr(d.geo_id, 1, 2) = ANY($1::text[])
    GROUP BY substr(d.geo_id, 1, 2), d.geo_id
    HAVING COUNT(o.politician_id) <> 1
    ORDER BY d.geo_id
    `,
    [WAVE1_FIPS],
  );
  console.log('Query C — districts with non-1 incumbent holders (vacancies / anomalies):');
  console.table(
    queryC.rows.map((r) => ({
      state: FIPS_TO_STATE[r.fips] ?? r.fips,
      geo_id: r.geo_id,
      office_ct: Number(r.office_ct),
      holder_ct: Number(r.holder_ct),
    })),
  );
  console.log('');

  // -----------------------------------------------------------------------
  // Per-state district tally (incumbents + vacancies = full district set)
  // -----------------------------------------------------------------------
  const tallyRes = await pool.query(
    `
    SELECT substr(d.geo_id, 1, 2) AS fips, COUNT(*) AS district_ct
    FROM essentials.districts d
    WHERE d.district_type = 'NATIONAL_LOWER'
      AND substr(d.geo_id, 1, 2) = ANY($1::text[])
    GROUP BY substr(d.geo_id, 1, 2)
    ORDER BY fips
    `,
    [WAVE1_FIPS],
  );
  console.log('Per-state district tally (expected CA 52 / TX 38 / FL 28 / NY 26 = 144):');
  let tallyTotal = 0;
  for (const r of tallyRes.rows) {
    const ct = Number(r.district_ct);
    tallyTotal += ct;
    const expected = EXPECTED_PER_STATE[r.fips];
    const flag = expected === ct ? 'OK' : `MISMATCH (expected ${expected})`;
    console.log(`  ${FIPS_TO_STATE[r.fips] ?? r.fips} (${r.fips}): ${ct}  ${flag}`);
  }
  console.log(`  TOTAL: ${tallyTotal}  (expected 144)\n`);

  // =======================================================================
  // Task 2: emit 148-incumbent-map.csv (git-tracked phase-dir artifact)
  // Build the complete 144-row district set = mapped incumbents + 2 vacancies.
  // =======================================================================
  const vacancyRows = queryC.rows.filter((r) => VACANCY_GEO_IDS.has(String(r.geo_id)));
  const unexpectedHolders = queryC.rows.filter((r) => !VACANCY_GEO_IDS.has(String(r.geo_id)));

  type CsvRow = {
    state: string;
    cd: number;
    geo_id: string;
    incumbent_name: string;
    incumbent_pid: string;
    incumbent_external_id: string;
    incumbent_is_active: string;
    incumbent_stance_count: number;
    incumbent_top_up_tier: string;
    sortFips: string;
  };

  const csvRows: CsvRow[] = [];

  // Mapped incumbents
  for (const r of incumbents) {
    const cd = parseInt(r.geo_id.slice(2), 10);
    csvRows.push({
      state: FIPS_TO_STATE[r.state_fips] ?? r.state_fips,
      cd,
      geo_id: r.geo_id,
      incumbent_name: r.full_name,
      incumbent_pid: r.politician_id,
      incumbent_external_id: r.external_id === null ? '' : String(r.external_id),
      incumbent_is_active: String(r.is_active),
      incumbent_stance_count: Number(r.stance_count),
      incumbent_top_up_tier: topUpTier(Number(r.stance_count), false),
      sortFips: r.state_fips,
    });
  }

  // Vacancies (no incumbent record to reuse)
  for (const r of vacancyRows) {
    const geoId = String(r.geo_id);
    const fips = geoId.slice(0, 2);
    const cd = parseInt(geoId.slice(2), 10);
    csvRows.push({
      state: FIPS_TO_STATE[fips] ?? fips,
      cd,
      geo_id: geoId,
      incumbent_name: 'VACANT',
      incumbent_pid: '',
      incumbent_external_id: '',
      incumbent_is_active: '',
      incumbent_stance_count: 0,
      incumbent_top_up_tier: 'vacant',
      sortFips: fips,
    });
  }

  // Stable sort: by state FIPS then cd
  csvRows.sort((a, b) => (a.sortFips === b.sortFips ? a.cd - b.cd : a.sortFips.localeCompare(b.sortFips)));

  const header = [
    'state',
    'cd',
    'geo_id',
    'incumbent_name',
    'incumbent_pid',
    'incumbent_external_id',
    'incumbent_is_active',
    'incumbent_stance_count',
    'incumbent_top_up_tier',
  ];
  const lines = [header.join(',')];
  for (const r of csvRows) {
    lines.push(
      [
        csvField(r.state),
        csvField(r.cd),
        csvField(r.geo_id),
        csvField(r.incumbent_name),
        csvField(r.incumbent_pid),
        csvField(r.incumbent_external_id),
        csvField(r.incumbent_is_active),
        csvField(r.incumbent_stance_count),
        csvField(r.incumbent_top_up_tier),
      ].join(','),
    );
  }
  // Single trailing newline after the last data row -> file is exactly 145 lines.
  const csvContent = lines.join('\n') + '\n';

  // Hard guard: exactly 144 data rows before writing.
  const dataRowCount = csvRows.length;
  if (dataRowCount !== 144) {
    console.error(
      `FATAL: CSV would have ${dataRowCount} data rows, expected exactly 144. ` +
        `Refusing to write 148-incumbent-map.csv.`,
    );
    await pool.end();
    process.exit(1);
  }

  writeFileSync(CSV_PATH, csvContent, 'utf8');
  console.log(`Wrote ${CSV_PATH}`);
  console.log(`  data rows: ${dataRowCount}  (header + data = ${lines.length} lines)`);

  // Per-state CSV reconciliation
  const perStateCsv: Record<string, number> = {};
  for (const r of csvRows) perStateCsv[r.state] = (perStateCsv[r.state] ?? 0) + 1;
  console.log(
    `  per-state CSV rows: CA ${perStateCsv['CA'] ?? 0} / TX ${perStateCsv['TX'] ?? 0} / ` +
      `FL ${perStateCsv['FL'] ?? 0} / NY ${perStateCsv['NY'] ?? 0}`,
  );
  const vacantCount = csvRows.filter((r) => r.incumbent_top_up_tier === 'vacant').length;
  console.log(`  vacant rows: ${vacantCount}  (expected 2: geo_id 1220, 4823)`);

  if (unexpectedHolders.length > 0) {
    console.warn('\nWARNING: districts with unexpected (non-1, non-vacancy) holder counts:');
    for (const r of unexpectedHolders) {
      console.warn(`  geo_id ${r.geo_id}: holder_ct=${Number(r.holder_ct)}, office_ct=${Number(r.office_ct)}`);
    }
  }

  console.log('\nDiagnostic complete (read-only; the only write was the git-tracked CSV artifact).');
  await pool.end();
}

main().catch(async (err) => {
  console.error('Diagnostic failed:', err);
  try {
    await pool.end();
  } catch {
    /* noop */
  }
  process.exit(1);
});

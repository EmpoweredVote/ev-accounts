/**
 * Phase 160 — Field Resolution + Stance-Gap Diagnostic (READ-ONLY)
 *
 * Produces the DB half of the Wave-3 (38-state / 178-district) US House field table:
 *   - Per-district incumbent -> essentials.politicians.id map (by geo_id, NEVER computed external_id)
 *   - Each incumbent's current federal-24 compass stance count + top-up tier (report-only per D-02)
 *   - Explicit enumeration of every district with a non-1 holder count (vacancies / anomalies)
 *
 * Wave-3 has NO known expected vacancy set this session — Query C returned 0 rows live
 * against prod (unlike Wave-2's GA-13/NJ-11/VA-11/GA-14). EXPECTED_VACANCY_GEO_IDS is
 * kept as an empty Set so the code path stays generic: if a retirement surfaces as a
 * 0-holder row between this diagnostic run and seeding time, it self-flags via the
 * unexpected-vacancy WARNING block below rather than being silently missed.
 *
 * SELECT-ONLY. Never INSERT/UPDATE/DELETE. Never pass --commit. Re-runnable / idempotent.
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-160-incumbent-stance-gap.ts
 *
 * The CSV emit is gated behind the read-only queries below and writes the git-tracked
 * phase-dir artifact 160-incumbent-map.csv (NOT a production DB write).
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';

// --- constants ------------------------------------------------------------
// WA=53 AZ=04 TN=47 MA=25 IN=18 MD=24 MN=27 MO=29 WI=55 CO=08 AL=01 SC=45 LA=22
// KY=21 OR=41 CT=09 OK=40 AR=05 IA=19 KS=20 MS=28 NV=32 UT=49 NM=35 NE=31 WV=54
// ID=16 HI=15 ME=23 NH=33 RI=44 MT=30 AK=02 DE=10 ND=38 SD=46 VT=50 WY=56
const WAVE3_FIPS = [
  '53', '04', '47', '25', '18', '24', '27', '29', '55', '08', '01', '45', '22', '21',
  '41', '09', '40', '05', '19', '20', '28', '32', '49', '35', '31', '54', '16', '15',
  '23', '33', '44', '30', '02', '10', '38', '46', '50', '56',
] as const;
const FIPS_TO_STATE: Record<string, string> = {
  '53': 'WA',
  '04': 'AZ',
  '47': 'TN',
  '25': 'MA',
  '18': 'IN',
  '24': 'MD',
  '27': 'MN',
  '29': 'MO',
  '55': 'WI',
  '08': 'CO',
  '01': 'AL',
  '45': 'SC',
  '22': 'LA',
  '21': 'KY',
  '41': 'OR',
  '09': 'CT',
  '40': 'OK',
  '05': 'AR',
  '19': 'IA',
  '20': 'KS',
  '28': 'MS',
  '32': 'NV',
  '49': 'UT',
  '35': 'NM',
  '31': 'NE',
  '54': 'WV',
  '16': 'ID',
  '15': 'HI',
  '23': 'ME',
  '33': 'NH',
  '44': 'RI',
  '30': 'MT',
  '02': 'AK',
  '10': 'DE',
  '38': 'ND',
  '46': 'SD',
  '50': 'VT',
  '56': 'WY',
};
const EXPECTED_PER_STATE: Record<string, number> = {
  '53': 10, // WA
  '04': 9, // AZ
  '47': 9, // TN
  '25': 9, // MA
  '18': 9, // IN
  '24': 8, // MD
  '27': 8, // MN
  '29': 8, // MO
  '55': 8, // WI
  '08': 8, // CO
  '01': 7, // AL
  '45': 7, // SC
  '22': 6, // LA
  '21': 6, // KY
  '41': 6, // OR
  '09': 5, // CT
  '40': 5, // OK
  '05': 4, // AR
  '19': 4, // IA
  '20': 4, // KS
  '28': 4, // MS
  '32': 4, // NV
  '49': 4, // UT
  '35': 3, // NM
  '31': 3, // NE
  '54': 2, // WV
  '16': 2, // ID
  '15': 2, // HI
  '23': 2, // ME
  '33': 2, // NH
  '44': 2, // RI
  '30': 2, // MT
  '02': 1, // AK
  '10': 1, // DE
  '38': 1, // ND
  '46': 1, // SD
  '50': 1, // VT
  '56': 1, // WY
};
const EXPECTED_TOTAL = 178;
const FEDERAL_TOPIC_BAR = 24;

// Wave-3: no known expected vacancy set this session (Query C returned 0 rows live).
// Kept generic/empty — do NOT hardcode a special-seat geo_id here.
const EXPECTED_VACANCY_GEO_IDS = new Set<string>([]);

const CSV_PATH = resolve(
  process.cwd(),
  '..',
  '.planning',
  'phases',
  '160-field-resolution-stance-gap-diagnostic',
  '160-incumbent-map.csv',
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
  console.log('=== Phase 160 incumbent + stance-gap diagnostic (READ-ONLY, 38 states / 178 districts) ===\n');

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
    [WAVE3_FIPS],
  );
  const incumbents = queryA.rows;
  console.log(`Query A — mapped incumbent rows: ${incumbents.length}  (expected ${EXPECTED_TOTAL} - (count of 0-holder districts))\n`);

  // -----------------------------------------------------------------------
  // Query B: per-state stance-gap summary (report-only per D-02)
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
    [WAVE3_FIPS],
  );
  console.log('Query B — per-state stance gap (report-only; partials NOT topped up per D-02):');
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
  let totalZero = 0;
  let totalPartial = 0;
  let totalDone = 0;
  for (const r of queryB.rows) {
    totalZero += Number(r.zero_stance);
    totalPartial += Number(r.under24);
    totalDone += Number(r.at_or_above_24);
  }
  console.log(`\nAggregate tier split: ${totalZero} zero / ${totalPartial} partial / ${totalDone} done (baseline expectation: 13 zero / 154 partial / 11 done)\n`);

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
    [WAVE3_FIPS],
  );
  console.log('Query C — districts with non-1 incumbent holders (vacancies / anomalies), expected EMPTY for Wave-3:');
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
    [WAVE3_FIPS],
  );
  console.log('Per-state district tally (38 states, expected total 178):');
  let tallyTotal = 0;
  for (const r of tallyRes.rows) {
    const ct = Number(r.district_ct);
    tallyTotal += ct;
    const expected = EXPECTED_PER_STATE[r.fips];
    const flag = expected === ct ? 'OK' : `MISMATCH (expected ${expected})`;
    console.log(`  ${FIPS_TO_STATE[r.fips] ?? r.fips} (${r.fips}): ${ct}  ${flag}`);
  }
  console.log(`  TOTAL: ${tallyTotal}  (expected ${EXPECTED_TOTAL})\n`);

  // =======================================================================
  // Emit 160-incumbent-map.csv (git-tracked phase-dir artifact)
  // Build the complete 178-row district set = mapped incumbents (1-holder) +
  // a VACANT row for each 0-holder district. Robust: vacant rows are derived
  // from Query C's ACTUAL 0-holder districts (not a hardcoded list), so the
  // file adapts to whatever the DB state is at run time.
  // =======================================================================
  const zeroHolder = queryC.rows.filter((r) => Number(r.holder_ct) === 0);
  const multiHolder = queryC.rows.filter((r) => Number(r.holder_ct) > 1);
  const zeroHolderGeoIds = new Set(zeroHolder.map((r) => String(r.geo_id)));

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

  // Mapped incumbents (1-holder districts)
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

  // Vacancies (0-holder districts — no incumbent record to reuse)
  for (const r of zeroHolder) {
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
  const csvContent = lines.join('\n') + '\n';

  // Hard guard: exactly 178 data rows before writing.
  const dataRowCount = csvRows.length;
  if (dataRowCount !== EXPECTED_TOTAL) {
    console.error(
      `FATAL: CSV would have ${dataRowCount} data rows, expected exactly ${EXPECTED_TOTAL} ` +
        `(mapped incumbents ${incumbents.length} + 0-holder vacancies ${zeroHolder.length}). ` +
        `A mismatch usually means a >1-holder anomaly district (see Query C). Refusing to write 160-incumbent-map.csv.`,
    );
    if (multiHolder.length > 0) {
      console.error('  >1-holder anomaly districts:');
      for (const r of multiHolder) console.error(`    geo_id ${r.geo_id}: holder_ct=${Number(r.holder_ct)}`);
    }
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
    '  per-state CSV rows: ' +
      Object.entries(perStateCsv)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([st, ct]) => `${st} ${ct}`)
        .join(' / '),
  );
  const vacantRowsOut = csvRows.filter((r) => r.incumbent_top_up_tier === 'vacant');
  console.log(
    `  vacant rows: ${vacantRowsOut.length}  (0-holder geo_ids: ${vacantRowsOut.map((r) => r.geo_id).join(', ') || 'none'})`,
  );
  const tierCounts: Record<string, number> = {};
  for (const r of csvRows) tierCounts[r.incumbent_top_up_tier] = (tierCounts[r.incumbent_top_up_tier] ?? 0) + 1;
  console.log(
    `  tier split: zero=${tierCounts.zero ?? 0} / partial=${tierCounts.partial ?? 0} / done=${tierCounts.done ?? 0} / vacant=${tierCounts.vacant ?? 0}`,
  );

  // WARNING block: surface surprises vs the expected (empty) special-seat set.
  const expectedSet = new Set(EXPECTED_VACANCY_GEO_IDS);
  const unexpectedVacant = vacantRowsOut.filter((r) => !expectedSet.has(r.geo_id));
  const missingExpectedVacant = [...expectedSet].filter((g) => !zeroHolderGeoIds.has(g));
  if (unexpectedVacant.length > 0) {
    console.warn('\nWARNING: 0-holder districts NOT in the expected special-seat set (investigate — possible retirement/vacancy since research):');
    for (const r of unexpectedVacant) console.warn(`  geo_id ${r.geo_id} (${r.state}-${r.cd})`);
  }
  if (missingExpectedVacant.length > 0) {
    console.warn('\nWARNING: expected-vacant special seats that are currently 1-holder in the DB (stale incumbent still present):');
    for (const g of missingExpectedVacant) {
      const inc = incumbents.find((r) => String(r.geo_id) === g);
      console.warn(`  geo_id ${g}: holder = "${inc?.full_name ?? '(unknown)'}"`);
    }
  }
  if (multiHolder.length > 0) {
    console.warn('\nWARNING: districts with >1 incumbent holders (data anomaly):');
    for (const r of multiHolder) console.warn(`  geo_id ${r.geo_id}: holder_ct=${Number(r.holder_ct)}, office_ct=${Number(r.office_ct)}`);
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

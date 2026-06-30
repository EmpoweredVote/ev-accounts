/**
 * Phase 154 — Field Resolution + Stance-Gap Diagnostic (READ-ONLY)
 *
 * Produces the DB half of the Wave-2 (PA/IL/OH/GA/NC/MI/NJ/VA) US House field table:
 *   - Per-district incumbent -> essentials.politicians.id map (by geo_id, NEVER computed external_id)
 *   - Each incumbent's current compass stance count + top-up tier (report-only per D-02)
 *   - Explicit enumeration of every district with a non-1 holder count (vacancies / post-v2.17 special seats)
 *
 * Wave-2 expected 0-holder special seats: GA-13 (1313), NJ-11 (3411), VA-11 (5111).
 * GA-14 (1314) is resolved LIVE (Open Question 1 / Pitfall 6): if 0-holder -> VACANT/new-record;
 * if 1-holder=Fuller -> maps normally; if 1-holder=MTG -> stale-incumbent anomaly flagged.
 * NJ-11 (Pitfall 5): if Sherrill's stale office row still exists, Query A returns her (1-holder, mapped);
 * the Plan-02 field table overrides her with Mejia. This script only reports — no NJ-11 special-casing.
 *
 * SELECT-ONLY. Never INSERT/UPDATE/DELETE. Never pass --commit. Re-runnable / idempotent.
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-154-incumbent-stance-gap.ts
 *
 * Task 2 (CSV emit) is gated behind the read-only queries below and writes the
 * git-tracked phase-dir artifact 154-incumbent-map.csv (NOT a production DB write).
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';

// --- constants ------------------------------------------------------------
// PA=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51
const WAVE2_FIPS = ['42', '17', '39', '13', '37', '26', '34', '51'] as const;
const FIPS_TO_STATE: Record<string, string> = {
  '42': 'PA',
  '17': 'IL', // IL state FIPS 17 — keys are 2-char state prefixes (substr(geo_id,1,2)); no collision with the geo_id CD suffix.
  '39': 'OH',
  '13': 'GA',
  '37': 'NC',
  '26': 'MI',
  '34': 'NJ',
  '51': 'VA',
};
const EXPECTED_PER_STATE: Record<string, number> = {
  '42': 17,
  '17': 17,
  '39': 15,
  '13': 14,
  '37': 14,
  '26': 13,
  '34': 12,
  '51': 11,
};
const EXPECTED_TOTAL = 113;
const FEDERAL_TOPIC_BAR = 24;

// Known/expected 0-holder special seats (RESEARCH §Special Seat Resolutions):
// GA-13 (Scott deceased), NJ-11 (Sherrill -> NJ gov), VA-11 (Connolly deceased; Walkinshaw special-seated, not in DB).
const EXPECTED_VACANCY_GEO_IDS = new Set(['1313', '3411', '5111']);
// GA-14 resolved live (Pitfall 6): Clay Fuller special-seated Apr 7 2026, replacing MTG.
const GA14_GEO_ID = '1314';

const CSV_PATH = resolve(
  process.cwd(),
  '..',
  '.planning',
  'phases',
  '154-field-resolution-stance-gap-diagnostic',
  '154-incumbent-map.csv',
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
  console.log('=== Phase 154 incumbent + stance-gap diagnostic (READ-ONLY) ===\n');

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
    [WAVE2_FIPS],
  );
  const incumbents = queryA.rows;
  console.log(`Query A — mapped incumbent rows: ${incumbents.length}  (expected ${EXPECTED_TOTAL} - (count of 0-holder special seats))\n`);

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
    [WAVE2_FIPS],
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
    [WAVE2_FIPS],
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
    [WAVE2_FIPS],
  );
  console.log('Per-state district tally (expected PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11 = 113):');
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
  // Task 2: emit 154-incumbent-map.csv (git-tracked phase-dir artifact)
  // Build the complete 113-row district set = mapped incumbents (1-holder) +
  // a VACANT row for each 0-holder district. Robust: vacant rows are derived
  // from Query C's ACTUAL 0-holder districts (not a hardcoded list), so the
  // file adapts to whatever the DB cleanup state is. The expected set is used
  // only for the WARNING (surprises in either direction) + the GA-14 anomaly.
  // =======================================================================
  const zeroHolder = queryC.rows.filter((r) => Number(r.holder_ct) === 0);
  const multiHolder = queryC.rows.filter((r) => Number(r.holder_ct) > 1);
  const zeroHolderGeoIds = new Set(zeroHolder.map((r) => String(r.geo_id)));

  // GA-14 live resolution (Pitfall 6 / Open Question 1).
  const ga14Incumbent = incumbents.find((r) => String(r.geo_id) === GA14_GEO_ID);
  const ga14Vacant = zeroHolderGeoIds.has(GA14_GEO_ID);
  if (ga14Vacant) {
    console.log(`GA-14 (${GA14_GEO_ID}): 0-holder -> Clay Fuller (R, special-seated Apr 7 2026) is a NEW-RECORD need (VACANT row).`);
  } else if (ga14Incumbent) {
    const nm = ga14Incumbent.full_name.toLowerCase();
    if (nm.includes('greene') || nm.includes('taylor greene') || nm.includes('marjorie')) {
      console.warn(`STALE-INCUMBENT ANOMALY: GA-14 holder is "${ga14Incumbent.full_name}" (MTG), not Fuller. The seeding phase MUST treat Fuller as a new-record need, not reuse this stale incumbent (RESEARCH Open Question 1).`);
    } else {
      console.log(`GA-14 (${GA14_GEO_ID}): 1-holder = "${ga14Incumbent.full_name}" — maps normally as the incumbent.`);
    }
  }

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

  // Hard guard: exactly 113 data rows before writing.
  const dataRowCount = csvRows.length;
  if (dataRowCount !== EXPECTED_TOTAL) {
    console.error(
      `FATAL: CSV would have ${dataRowCount} data rows, expected exactly ${EXPECTED_TOTAL} ` +
        `(mapped incumbents ${incumbents.length} + 0-holder vacancies ${zeroHolder.length}). ` +
        `A mismatch usually means a >1-holder anomaly district (see Query C). Refusing to write 154-incumbent-map.csv.`,
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
    `  per-state CSV rows: PA ${perStateCsv['PA'] ?? 0} / IL ${perStateCsv['IL'] ?? 0} / ` +
      `OH ${perStateCsv['OH'] ?? 0} / GA ${perStateCsv['GA'] ?? 0} / NC ${perStateCsv['NC'] ?? 0} / ` +
      `MI ${perStateCsv['MI'] ?? 0} / NJ ${perStateCsv['NJ'] ?? 0} / VA ${perStateCsv['VA'] ?? 0}`,
  );
  const vacantRowsOut = csvRows.filter((r) => r.incumbent_top_up_tier === 'vacant');
  console.log(
    `  vacant rows: ${vacantRowsOut.length}  (0-holder geo_ids: ${vacantRowsOut.map((r) => r.geo_id).join(', ') || 'none'})`,
  );

  // WARNING block: surface surprises in either direction vs the expected special-seat set.
  const expectedSet = new Set(EXPECTED_VACANCY_GEO_IDS);
  if (ga14Vacant) expectedSet.add(GA14_GEO_ID);
  const unexpectedVacant = vacantRowsOut.filter((r) => !expectedSet.has(r.geo_id));
  const missingExpectedVacant = [...expectedSet].filter((g) => !zeroHolderGeoIds.has(g));
  if (unexpectedVacant.length > 0) {
    console.warn('\nWARNING: 0-holder districts NOT in the expected special-seat set (investigate):');
    for (const r of unexpectedVacant) console.warn(`  geo_id ${r.geo_id} (${r.state}-${r.cd})`);
  }
  if (missingExpectedVacant.length > 0) {
    console.warn(
      '\nWARNING: expected-vacant special seats that are currently 1-holder in the DB (stale incumbent still present):',
    );
    for (const g of missingExpectedVacant) {
      const inc = incumbents.find((r) => String(r.geo_id) === g);
      console.warn(`  geo_id ${g}: holder = "${inc?.full_name ?? '(unknown)'}" — Plan 02 field table OVERRIDES with the real 2026 nominee (Pitfall 5).`);
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

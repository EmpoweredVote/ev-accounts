/**
 * Phase 160 — Race/Candidate Pre-Existence Audit (READ-ONLY)
 *
 * Sweeps ANY election_date (never filtered to 2026-11-03 only) across all 38 Wave-3
 * states / 178 districts to discover pre-existing `essentials.races` +
 * `essentials.race_candidates` rows the seeding phases (161-165) must reuse, not
 * duplicate.
 *
 * RESEARCH.md Critical Finding 4 (proven live this session): the ROADMAP's "none of
 * the 38 states have pre-seeded 2026 House races" claim is FALSE for at least 5 states
 * — ME (2 races), MD (8), MA (9), NV (4), and OR (6) already have races scaffolded on
 * 2026-11-03 (29 rows total). NV additionally has 9 real race_candidates wired
 * (including all 4 incumbents). ME, IN, and UT have stale primary-era race_candidates
 * rows, including a confirmed data-quality bug: IN-9's Democratic primary losers
 * (Graham/Meyer/Peck/Roark) are incorrectly flagged is_incumbent=true, while the actual
 * sitting incumbent Erin Houchin is flagged is_incumbent=false. NV-2 has a
 * race_candidates row (Lynn Chapman) with politician_id NULL, violating the
 * non-null-politician_id invariant.
 *
 * SELECT-ONLY. No write statements of any kind, ever. Never pass --commit. Re-runnable /
 * idempotent. This script documents these anomalies for the OWNING seeding phase to
 * fix (162 for IN-9, 165 for NV-2) — it does NOT fix them.
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-160-race-preexistence-audit.ts
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';

// --- constants ------------------------------------------------------------
const WAVE3_FIPS = [
  '53', '04', '47', '25', '18', '24', '27', '29', '55', '08', '01', '45', '22', '21',
  '41', '09', '40', '05', '19', '20', '28', '32', '49', '35', '31', '54', '16', '15',
  '23', '33', '44', '30', '02', '10', '38', '46', '50', '56',
] as const;
const FIPS_TO_STATE: Record<string, string> = {
  '53': 'WA', '04': 'AZ', '47': 'TN', '25': 'MA', '18': 'IN', '24': 'MD', '27': 'MN',
  '29': 'MO', '55': 'WI', '08': 'CO', '01': 'AL', '45': 'SC', '22': 'LA', '21': 'KY',
  '41': 'OR', '09': 'CT', '40': 'OK', '05': 'AR', '19': 'IA', '20': 'KS', '28': 'MS',
  '32': 'NV', '49': 'UT', '35': 'NM', '31': 'NE', '54': 'WV', '16': 'ID', '15': 'HI',
  '23': 'ME', '33': 'NH', '44': 'RI', '30': 'MT', '02': 'AK', '10': 'DE', '38': 'ND',
  '46': 'SD', '50': 'VT', '56': 'WY',
};

const CSV_PATH = resolve(
  process.cwd(),
  '..',
  '.planning',
  'phases',
  '160-field-resolution-stance-gap-diagnostic',
  '160-race-preexistence-audit.csv',
);

function csvField(value: unknown): string {
  if (value === null || value === undefined) return '';
  const s = String(value);
  // RFC-4180: quote any field containing comma, quote, CR, or LF.
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

interface DetailRow {
  fips: string;
  geo_id: string;
  election_date: Date;
  election_name: string;
  race_id: string;
  rc_id: string | null;
  politician_id: string | null;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean | null;
  candidate_status: string | null;
  last_verified_at: Date | null;
  source: string | null;
  external_id: string | null;
  created_at: Date | null;
  updated_at: Date | null;
  occupational_designation: string | null;
  website_url: string | null;
}

async function main(): Promise<void> {
  console.log('=== Phase 160 / race + candidate pre-existence audit (READ-ONLY, ANY election_date, 38 states) ===\n');

  // -----------------------------------------------------------------------
  // Summary query: sweeps ANY election_date (NOT filtered to 2026-11-03).
  // -----------------------------------------------------------------------
  const summary = await pool.query(
    `
    SELECT substr(d.geo_id,1,2) AS fips, el.election_date, el.name AS election_name,
           COUNT(DISTINCT r.id) AS race_ct, COUNT(rc.id) AS cand_ct
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
    WHERE d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id,1,2) = ANY($1::text[])
    GROUP BY fips, el.election_date, el.name
    ORDER BY fips, el.election_date
    `,
    [WAVE3_FIPS],
  );
  console.log('Summary — pre-existing races/candidates by state + election (ANY election_date):');
  console.table(
    summary.rows.map((r) => ({
      state: FIPS_TO_STATE[r.fips] ?? r.fips,
      election_date: r.election_date.toISOString().slice(0, 10),
      election_name: r.election_name,
      race_ct: Number(r.race_ct),
      cand_ct: Number(r.cand_ct),
    })),
  );
  console.log('');

  // -----------------------------------------------------------------------
  // Detail query: grain = one row per race + candidate (LEFT JOIN preserves
  // 0-candidate races, e.g. MD's 8 scaffolded-but-empty races).
  // -----------------------------------------------------------------------
  // NOTE: rc.* is deliberately NOT used here — race_candidates has its own `race_id`
  // column, and a naive `r.id AS race_id, rc.*` would let the (possibly-NULL, for
  // 0-candidate races) rc.race_id silently overwrite r.id's alias in the parsed row
  // object (duplicate column names collapse to the last one in node-postgres). Every
  // rc.* column except race_id is listed explicitly instead.
  const detail = await pool.query<DetailRow>(
    `
    SELECT substr(d.geo_id,1,2) AS fips, d.geo_id, el.election_date, el.name AS election_name,
           r.id AS race_id,
           rc.id AS rc_id, rc.politician_id, rc.full_name, rc.first_name, rc.last_name,
           rc.photo_url, rc.is_incumbent, rc.candidate_status, rc.last_verified_at,
           rc.source, rc.external_id, rc.created_at, rc.updated_at,
           rc.occupational_designation, rc.website_url
    FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
    WHERE d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id,1,2) = ANY($1::text[])
    ORDER BY fips, d.geo_id, el.election_date
    `,
    [WAVE3_FIPS],
  );
  console.log(`Detail query — pre-existing race/candidate rows found: ${detail.rows.length}\n`);

  // -----------------------------------------------------------------------
  // Anomaly detection + console.warn per the WARNING-block style.
  // IN-9 (geo_id 1809): Houchin (the real incumbent, confirmed via 160-incumbent-map.csv,
  //   pid 68568faf-1e0f-4ca2-89d9-bda625665712) is flagged is_incumbent=false; her four
  //   Democratic-primary opponents (Graham/Meyer/Peck/Roark) are flagged is_incumbent=true.
  // NV-2 (geo_id 3202): Lynn Chapman's race_candidates row has politician_id IS NULL.
  // -----------------------------------------------------------------------
  const IN9_HOUCHIN_PID = '68568faf-1e0f-4ca2-89d9-bda625665712';
  const rowsOut: Array<Record<string, unknown>> = [];
  let in9AnomalyCount = 0;
  let nv2AnomalyCount = 0;

  for (const r of detail.rows) {
    const state = FIPS_TO_STATE[r.fips] ?? r.fips;
    const geoId = String(r.geo_id);
    const cd = parseInt(geoId.slice(2), 10);
    let anomaly = '';

    if (state === 'IN' && geoId === '1809') {
      const isHouchin = r.politician_id === IN9_HOUCHIN_PID;
      if (isHouchin && r.is_incumbent === false) {
        anomaly = 'IN9-INCUMBENT-FLAG-BUG';
        in9AnomalyCount++;
      } else if (!isHouchin && r.is_incumbent === true) {
        anomaly = 'IN9-INCUMBENT-FLAG-BUG';
        in9AnomalyCount++;
      }
    }
    if (state === 'NV' && geoId === '3202' && r.rc_id !== null && r.politician_id === null) {
      anomaly = 'NV2-NULL-PID';
      nv2AnomalyCount++;
    }

    rowsOut.push({
      state,
      cd,
      geo_id: geoId,
      election_date: r.election_date.toISOString().slice(0, 10),
      election_name: r.election_name,
      existing_race_id: r.race_id,
      candidate_pid: r.politician_id ?? '',
      is_incumbent: r.is_incumbent === null ? '' : String(r.is_incumbent),
      anomaly,
      rc_id: r.rc_id ?? '',
      full_name: r.full_name ?? '',
      first_name: r.first_name ?? '',
      last_name: r.last_name ?? '',
      photo_url: r.photo_url ?? '',
      candidate_status: r.candidate_status ?? '',
      last_verified_at: r.last_verified_at ? new Date(r.last_verified_at).toISOString() : '',
      source: r.source ?? '',
      external_id: r.external_id ?? '',
      created_at: r.created_at ? new Date(r.created_at).toISOString() : '',
      updated_at: r.updated_at ? new Date(r.updated_at).toISOString() : '',
      occupational_designation: r.occupational_designation ?? '',
      website_url: r.website_url ?? '',
    });
  }

  if (in9AnomalyCount > 0) {
    console.warn(
      `\nWARNING (IN-9 incumbent-flag bug): geo_id 1809's pre-existing race_candidates rows mislabel ` +
        `incumbency — Erin Houchin (pid ${IN9_HOUCHIN_PID}) is the TRUE sitting incumbent per the ` +
        `160-incumbent-map.csv (confirmed 25 stances), but is flagged is_incumbent=false, while her four ` +
        `May-5 primary opponents (Graham/Meyer/Peck/Roark) are incorrectly flagged is_incumbent=true. ` +
        `MUST fix, not propagate (Phase 162).`,
    );
  }
  if (nv2AnomalyCount > 0) {
    console.warn(
      `\nWARNING (NV-2 NULL politician_id): NV-2's (geo_id 3202) pre-existing race_candidates row for ` +
        `Lynn Chapman has politician_id IS NULL, violating the non-null-politician_id invariant. ` +
        `MUST fix, not recreate (Phase 165).`,
    );
  }

  // Populate existing_race_id per-district summary for the 29 ME/MD/MA/NV/OR Nov-3 rows.
  const nov3ExistingRaceStates = new Set(['ME', 'MD', 'MA', 'NV', 'OR']);
  const nov3Rows = rowsOut.filter(
    (r) => r.election_date === '2026-11-03' && nov3ExistingRaceStates.has(r.state as string),
  );
  const distinctNov3Districts = new Set(nov3Rows.map((r) => r.geo_id));
  console.log(
    `\nPre-existing Nov-3 races across ME/MD/MA/NV/OR: ${distinctNov3Districts.size} districts ` +
      `(expected 29: ME 2 / MD 8 / MA 9 / NV 4 / OR 6).`,
  );

  // -----------------------------------------------------------------------
  // Emit 160-race-preexistence-audit.csv — full-column dump.
  // -----------------------------------------------------------------------
  const header = [
    'state',
    'cd',
    'geo_id',
    'election_date',
    'election_name',
    'existing_race_id',
    'candidate_pid',
    'is_incumbent',
    'anomaly',
    'rc_id',
    'full_name',
    'first_name',
    'last_name',
    'photo_url',
    'candidate_status',
    'last_verified_at',
    'source',
    'external_id',
    'created_at',
    'updated_at',
    'occupational_designation',
    'website_url',
  ];
  const lines = [header.join(',')];
  for (const r of rowsOut) {
    lines.push(header.map((col) => csvField(r[col])).join(','));
  }
  const csvContent = lines.join('\n') + '\n';
  writeFileSync(CSV_PATH, csvContent, 'utf8');
  console.log(`\nWrote ${CSV_PATH}`);
  console.log(`  data rows: ${rowsOut.length}  (header + data = ${lines.length} lines)`);
  console.log(`  anomaly rows: IN9-INCUMBENT-FLAG-BUG=${in9AnomalyCount}, NV2-NULL-PID=${nv2AnomalyCount}`);

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

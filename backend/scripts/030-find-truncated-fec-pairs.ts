/**
 * 030-find-truncated-fec-pairs.ts — audit: which FEC (source, cycle) pairs are TRUNCATED.
 *
 * Part of quick-030 (FEC completeness sweep), Task 2a. Builds the ranked work-list the
 * sweep (030-completeness-sweep.ts) consumes.
 *
 * A pair is TRUNCATED when its LATEST completed / completed_with_warning ingestion_run
 * either:
 *   (a) recorded "fetched X of expected Y" in notes with X/Y < THRESHOLD (default 0.95), or
 *   (b) has no expected recorded but landed exactly on a known record cap (2500 = pre-029,
 *       50000 = post-029) — an organic count almost never lands exactly on a round cap, so
 *       this catches capped runs whose completeness note was not written.
 *
 * Ranked biggest-expected-first (biggest-money races first — that is where corruption
 * hides and where under-capture defeats the tool's purpose).
 *
 * Usage:
 *   tsx scripts/030-find-truncated-fec-pairs.ts [threshold] [--json path]
 *     threshold  — coverage bar below which a pair counts as truncated (default 0.95)
 *     --json     — also write the full ranked work-list to this path (default: scripts/030-truncated-pairs.json)
 *
 * Importable: getTruncatedPairs(threshold) returns the same ranked list for the sweep to reuse.
 */

import 'dotenv/config';
import fs from 'fs';
import { pool } from '../src/lib/db.js';

/** Known per-politician record caps used over the project's history. */
export const KNOWN_FEC_CAPS = [2500, 50000] as const;

/**
 * Plausibility ceiling for a pair's "expected" record count. Some old API runs recorded a
 * bogus expected (e.g. 113,097,321 — a conduit committee's total) when a candidate resolved
 * to a shared/conduit committee. No real single candidate committee's itemized individual
 * count comes close (the largest legitimate value observed is ~2.35M). Any expected above
 * this is treated as noise: the pair is NOT judged "truncated" on it (surfaced separately as
 * a data anomaly). Sits well above the largest real value and far below the bogus ones.
 */
export const MAX_PLAUSIBLE_EXPECTED = 5_000_000;

export interface TruncatedPair {
  sourceId: string;
  externalId: string;
  fullName: string;
  representingState: string;
  cycle: string;
  captured: number;
  /** FEC expected count when known (from the completeness note); null when only a cap was hit. */
  expected: number | null;
  /** captured/expected * 100 when expected is known, else null. */
  coveragePct: number | null;
}

/**
 * getTruncatedPairs returns every FEC (source, cycle) pair whose latest completed run is
 * below the coverage threshold, ranked by expected (then captured) descending. This is the
 * single source of truth for "is this pair truncated" — the sweep reuses it so a resumed
 * run recomputes the same work-list and skips pairs already brought to >= threshold.
 */
export async function getTruncatedPairs(threshold = 0.95): Promise<TruncatedPair[]> {
  const r = await pool.query<{
    source_id: string;
    external_id: string;
    full_name: string;
    representing_state: string | null;
    cycle: string;
    captured: string;
    expected: string | null;
    coverage_pct: string | null;
  }>(
    `WITH latest AS (
       SELECT DISTINCT ON (ir.politician_source_id, ir.election_cycle)
              ir.politician_source_id, ir.election_cycle, ir.records_fetched, ir.notes
       FROM transparent_motivations.ingestion_runs ir
       WHERE ir.adapter_name = 'fec'
         AND ir.status IN ('completed', 'completed_with_warning')
       ORDER BY ir.politician_source_id, ir.election_cycle, ir.completed_at DESC
     ),
     parsed AS (
       SELECT l.*,
         (regexp_match(l.notes, 'fetched ([0-9]+) of expected ([0-9]+)'))[1]::bigint AS captured,
         (regexp_match(l.notes, 'fetched ([0-9]+) of expected ([0-9]+)'))[2]::bigint AS expected
       FROM latest l
     )
     SELECT p.politician_source_id AS source_id,
            ps.external_id,
            pol.full_name,
            (SELECT o.representing_state FROM essentials.offices o
             WHERE o.politician_id = pol.id LIMIT 1) AS representing_state,
            p.election_cycle AS cycle,
            COALESCE(p.captured, p.records_fetched)::text AS captured,
            p.expected::text AS expected,
            CASE WHEN p.expected IS NOT NULL AND p.expected > 0
                 THEN round(100.0 * p.captured / p.expected, 2) END::text AS coverage_pct
     FROM parsed p
     JOIN transparent_motivations.politician_sources ps ON ps.id = p.politician_source_id
     JOIN essentials.politicians pol ON pol.id = ps.essentials_politician_id
     WHERE (p.expected IS NOT NULL AND p.expected > 0 AND p.expected <= $3
            AND p.captured::numeric / p.expected < $1)
        OR (p.expected IS NULL AND p.records_fetched = ANY($2::int[]))
     ORDER BY COALESCE(p.expected, p.records_fetched) DESC, COALESCE(p.captured, p.records_fetched) DESC`,
    [threshold, KNOWN_FEC_CAPS as unknown as number[], MAX_PLAUSIBLE_EXPECTED]
  );

  return r.rows.map((row) => ({
    sourceId: row.source_id,
    externalId: row.external_id,
    fullName: row.full_name,
    representingState: row.representing_state ?? '',
    cycle: row.cycle,
    captured: Number(row.captured),
    expected: row.expected != null ? Number(row.expected) : null,
    coveragePct: row.coverage_pct != null ? Number(row.coverage_pct) : null,
  }));
}

export interface ExpectedAnomaly {
  fullName: string;
  cycle: string;
  captured: number;
  expected: number;
}

/** Pairs whose latest run recorded an implausibly large expected (conduit/shared-committee
 *  noise). Surfaced so the anomaly is visible rather than silently excluded from the audit. */
export async function getExpectedAnomalies(): Promise<ExpectedAnomaly[]> {
  const r = await pool.query<{ full_name: string; cycle: string; captured: string; expected: string }>(
    `WITH latest AS (
       SELECT DISTINCT ON (ir.politician_source_id, ir.election_cycle)
              ir.politician_source_id, ir.election_cycle, ir.notes
       FROM transparent_motivations.ingestion_runs ir
       WHERE ir.adapter_name = 'fec' AND ir.status IN ('completed','completed_with_warning')
         AND ir.notes ~ 'expected [0-9]+'
       ORDER BY ir.politician_source_id, ir.election_cycle, ir.completed_at DESC
     ),
     parsed AS (
       SELECT l.*,
         (regexp_match(l.notes,'fetched ([0-9]+) of expected ([0-9]+)'))[1]::bigint AS captured,
         (regexp_match(l.notes,'fetched ([0-9]+) of expected ([0-9]+)'))[2]::bigint AS expected
       FROM latest l
     )
     SELECT pol.full_name, p.election_cycle AS cycle, p.captured::text, p.expected::text
     FROM parsed p
     JOIN transparent_motivations.politician_sources ps ON ps.id = p.politician_source_id
     JOIN essentials.politicians pol ON pol.id = ps.essentials_politician_id
     WHERE p.expected > $1
     ORDER BY p.expected DESC`,
    [MAX_PLAUSIBLE_EXPECTED]
  );
  return r.rows.map((x) => ({ fullName: x.full_name, cycle: x.cycle, captured: Number(x.captured), expected: Number(x.expected) }));
}

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL not set');
    process.exit(1);
  }

  const threshold = process.argv[2] && !process.argv[2].startsWith('--') ? parseFloat(process.argv[2]) : 0.95;
  const jsonIdx = process.argv.indexOf('--json');
  const jsonPath = jsonIdx >= 0 ? (process.argv[jsonIdx + 1] ?? 'scripts/030-truncated-pairs.json') : 'scripts/030-truncated-pairs.json';

  const pairs = await getTruncatedPairs(threshold);

  const withExpected = pairs.filter((p) => p.expected != null);
  const deficit = withExpected.reduce((s, p) => s + Math.max((p.expected ?? 0) - p.captured, 0), 0);

  console.log(`\n=== FEC TRUNCATION AUDIT (threshold ${(threshold * 100).toFixed(0)}%) ===`);
  console.log(`Truncated pairs: ${pairs.length}`);
  console.log(`  with known expected count: ${withExpected.length}`);
  console.log(`  cap-boundary only (no expected recorded): ${pairs.length - withExpected.length}`);
  console.log(`Approx. itemized-row deficit (sum of expected-captured): ${deficit.toLocaleString()}`);

  console.log(`\n--- Top 25 by expected (biggest races first) ---`);
  for (const p of pairs.slice(0, 25)) {
    const cov = p.coveragePct != null ? `${p.coveragePct}%` : 'cap';
    const exp = p.expected != null ? p.expected.toLocaleString() : `cap@${p.captured}`;
    console.log(`  [${p.cycle}] ${p.representingState.padEnd(2)} ${p.fullName.padEnd(28)} ${p.captured.toLocaleString().padStart(10)} / ${exp.padStart(11)}  (${cov})`);
  }

  const anomalies = await getExpectedAnomalies();
  if (anomalies.length > 0) {
    console.log(`\n--- Excluded ${anomalies.length} data anomaly pair(s) (implausible expected > ${MAX_PLAUSIBLE_EXPECTED.toLocaleString()}, treated as noise not truncation) ---`);
    for (const a of anomalies) {
      console.log(`  [${a.cycle}] ${a.fullName.padEnd(28)} captured ${a.captured.toLocaleString()} / bogus expected ${a.expected.toLocaleString()} — likely a source linked to a conduit/shared committee (investigate linkage)`);
    }
  }

  fs.writeFileSync(jsonPath, JSON.stringify(pairs, null, 2));
  console.log(`\nWork-list written to ${jsonPath} (${pairs.length} pairs).`);

  await pool.end();
  process.exit(0);
}

// Only run main when invoked directly (not when imported by the sweep).
const invokedDirectly = process.argv[1] && /030-find-truncated-fec-pairs\.ts$/.test(process.argv[1]);
if (invokedDirectly) {
  main().catch((err) => { console.error('[030-audit] Fatal:', err); process.exit(1); });
}

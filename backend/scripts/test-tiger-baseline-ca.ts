/**
 * test-tiger-baseline-ca.ts
 *
 * Phase 130 D-13 / PIPE-03: CA byte-equivalence snapshot harness.
 *
 * Runs the new state-parameterized TIGER loader against the configured DB for
 * FIPS 06 (California), dumps a `(geo_id, mtfcc, md5(ST_AsBinary(geometry)))`
 * CSV using the EXACT SQL from ARCHITECTURE.md §6.1, and diffs that fresh dump
 * against the committed baseline at
 * `ev-accounts/backend/scripts/fixtures/tiger_baseline_ca.csv`.
 *
 * Per D-13, ANY delta — row-count, geo_id-set, or row_hash — fails the gate.
 * Exit code 0 means byte-identity (modulo trailing newline tolerance); exit
 * code 1 means at least one of: loader failed, row count differs, set differs,
 * or a (geo_id, mtfcc) pair has a different `row_hash`.
 *
 * Also emits per-MTFCC counts for both baseline and fresh on stdout in the
 * shape:
 *   MTFCC_COUNTS_BASELINE: <mtfcc>=<count>
 *   MTFCC_COUNTS_FRESH: <mtfcc>=<count>
 * (one line per mtfcc, sorted ascending), so the verification-evidence step
 * can build the `| mtfcc | baseline_count | fresh_count | delta |` table
 * deterministically from harness stdout.
 *
 * Usage:
 *   npx tsx scripts/test-tiger-baseline-ca.ts            # diff-only (no truncate)
 *   npx tsx scripts/test-tiger-baseline-ca.ts --truncate # DELETE state='06' before re-load
 *
 * Re-runnable in CI for future TIGER vintage changes (D-12 says the baseline
 * stays put unless the user explicitly accepts a baseline change).
 */

import { Client } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { spawnSync } from 'child_process';
import { fileURLToPath } from 'url';
import * as dotenv from 'dotenv';
dotenv.config();

// ─── Constants ───────────────────────────────────────────────────────────────

const FIPS = '06';
const STATE = 'CA';
const LAYERS = 'cd,sldu,sldl,unsd,place';

const SCRIPTS_DIR = path.dirname(fileURLToPath(import.meta.url));
const BASELINE_PATH = path.join(SCRIPTS_DIR, 'fixtures', 'tiger_baseline_ca.csv');
const FRESH_PATH = '/tmp/tiger_fresh_ca.csv';
const LOADER_PATH = path.join(SCRIPTS_DIR, 'load-state-tiger-boundaries.ts');

// EXACT SQL from ARCHITECTURE.md §6.1 — do not paraphrase.
const HASH_DUMP_SQL = `
  SELECT geo_id, mtfcc, md5(ST_AsBinary(geometry)) AS row_hash
  FROM essentials.geofence_boundaries
  WHERE state = '06'
  ORDER BY geo_id, mtfcc
`;

// ─── CLI parsing ─────────────────────────────────────────────────────────────

interface CliArgs {
  truncate: boolean;
}

function parseArgs(argv: string[]): CliArgs {
  let truncate = false;
  for (const a of argv) {
    if (a === '--truncate') truncate = true;
  }
  return { truncate };
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

interface HashRow {
  geo_id: string;
  mtfcc: string;
  row_hash: string;
}

function readHashCsv(filePath: string): { header: string; rows: HashRow[] } {
  const raw = fs.readFileSync(filePath, 'utf8');
  // Tolerate trailing newlines.
  const lines = raw.split('\n').filter((l) => l.length > 0);
  if (lines.length === 0) {
    throw new Error(`empty CSV: ${filePath}`);
  }
  const header = lines[0];
  const rows: HashRow[] = lines.slice(1).map((line, i) => {
    const parts = line.split(',');
    if (parts.length !== 3) {
      throw new Error(
        `malformed row ${i + 2} in ${filePath} (expected 3 cols, got ${parts.length}): ${line}`,
      );
    }
    return { geo_id: parts[0], mtfcc: parts[1], row_hash: parts[2] };
  });
  return { header, rows };
}

function rowKey(r: HashRow): string {
  return `${r.geo_id}|${r.mtfcc}`;
}

function mtfccCounts(rows: HashRow[]): Map<string, number> {
  const m = new Map<string, number>();
  for (const r of rows) {
    m.set(r.mtfcc, (m.get(r.mtfcc) ?? 0) + 1);
  }
  return m;
}

function emitMtfccCounts(label: 'BASELINE' | 'FRESH', rows: HashRow[]): void {
  const counts = mtfccCounts(rows);
  const sortedKeys = Array.from(counts.keys()).sort();
  for (const k of sortedKeys) {
    process.stdout.write(`MTFCC_COUNTS_${label}: ${k}=${counts.get(k)}\n`);
  }
}

// ─── Steps ───────────────────────────────────────────────────────────────────

async function maybeTruncate(client: Client, args: CliArgs): Promise<void> {
  if (!args.truncate) {
    console.log('[test-tiger-baseline-ca] --truncate not set; skipping pre-clean.');
    return;
  }
  console.log(`[test-tiger-baseline-ca] DELETE FROM essentials.geofence_boundaries WHERE state = '${FIPS}'`);
  const res = await client.query(
    `DELETE FROM essentials.geofence_boundaries WHERE state = $1`,
    [FIPS],
  );
  console.log(`[test-tiger-baseline-ca] deleted ${res.rowCount ?? 0} rows.`);
}

function runLoader(): void {
  console.log(
    `[test-tiger-baseline-ca] running new loader (load-state-tiger-boundaries.ts) for ${STATE} / FIPS ${FIPS} / layers ${LAYERS}`,
  );
  const result = spawnSync(
    'npx',
    ['tsx', LOADER_PATH, '--state', STATE, '--fips', FIPS, '--layers', LAYERS],
    { stdio: 'inherit', cwd: path.resolve(SCRIPTS_DIR, '..') },
  );
  if (result.status !== 0) {
    console.error(
      `[test-tiger-baseline-ca] loader exited with status ${result.status}; aborting snapshot diff.`,
    );
    process.exit(1);
  }
}

async function dumpFresh(client: Client): Promise<void> {
  console.log(`[test-tiger-baseline-ca] dumping fresh hash CSV to ${FRESH_PATH}`);
  const res = await client.query(HASH_DUMP_SQL);
  const out = ['geo_id,mtfcc,row_hash'];
  for (const r of res.rows) {
    out.push(`${r.geo_id},${r.mtfcc},${r.row_hash}`);
  }
  fs.writeFileSync(FRESH_PATH, out.join('\n') + '\n', 'utf8');
  console.log(`[test-tiger-baseline-ca] wrote ${res.rows.length} rows to ${FRESH_PATH}`);
}

interface DiffResult {
  ok: boolean;
  reasons: string[];
}

function diff(): DiffResult {
  const baseline = readHashCsv(BASELINE_PATH);
  const fresh = readHashCsv(FRESH_PATH);

  // Always emit per-MTFCC counts for evidence-table assembly, regardless of
  // outcome (the verifier wants to see them in the failure case too).
  emitMtfccCounts('BASELINE', baseline.rows);
  emitMtfccCounts('FRESH', fresh.rows);

  const reasons: string[] = [];

  if (baseline.header !== fresh.header) {
    reasons.push(
      `header mismatch: baseline=${JSON.stringify(baseline.header)} fresh=${JSON.stringify(fresh.header)}`,
    );
  }

  if (baseline.rows.length !== fresh.rows.length) {
    reasons.push(
      `row count delta: baseline=${baseline.rows.length} fresh=${fresh.rows.length}`,
    );
  }

  const baseMap = new Map(baseline.rows.map((r) => [rowKey(r), r] as const));
  const freshMap = new Map(fresh.rows.map((r) => [rowKey(r), r] as const));

  const inBaselineNotFresh: HashRow[] = [];
  const hashDeltas: Array<{ k: string; baseHash: string; freshHash: string }> = [];
  for (const [k, br] of baseMap) {
    const fr = freshMap.get(k);
    if (!fr) {
      inBaselineNotFresh.push(br);
      continue;
    }
    if (br.row_hash !== fr.row_hash) {
      hashDeltas.push({ k, baseHash: br.row_hash, freshHash: fr.row_hash });
    }
  }

  const inFreshNotBaseline: HashRow[] = [];
  for (const [k, fr] of freshMap) {
    if (!baseMap.has(k)) {
      inFreshNotBaseline.push(fr);
    }
  }

  if (inBaselineNotFresh.length > 0) {
    reasons.push(`${inBaselineNotFresh.length} rows in baseline missing from fresh`);
    for (const r of inBaselineNotFresh.slice(0, 20)) {
      console.error(`  baseline-not-fresh: ${rowKey(r)} hash=${r.row_hash}`);
    }
  }
  if (inFreshNotBaseline.length > 0) {
    reasons.push(`${inFreshNotBaseline.length} rows in fresh missing from baseline`);
    for (const r of inFreshNotBaseline.slice(0, 20)) {
      console.error(`  fresh-not-baseline: ${rowKey(r)} hash=${r.row_hash}`);
    }
  }
  if (hashDeltas.length > 0) {
    reasons.push(
      `${hashDeltas.length} (geo_id, mtfcc) pairs differ in row_hash (silent geometry drift)`,
    );
    for (const d of hashDeltas.slice(0, 20)) {
      console.error(`  hash-drift: ${d.k} baseline=${d.baseHash} fresh=${d.freshHash}`);
    }
  }

  return { ok: reasons.length === 0, reasons };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  if (!fs.existsSync(BASELINE_PATH)) {
    console.error(`[test-tiger-baseline-ca] baseline missing: ${BASELINE_PATH}`);
    process.exit(1);
  }
  if (!fs.existsSync(LOADER_PATH)) {
    console.error(`[test-tiger-baseline-ca] loader missing: ${LOADER_PATH}`);
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('[test-tiger-baseline-ca] DATABASE_URL not set in env');
    process.exit(1);
  }

  const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  try {
    await maybeTruncate(client, args);
  } finally {
    // Close before spawning child loader (it opens its own connection).
    await client.end();
  }

  // Spawn child loader (uses its own DB client). We re-open ours afterwards
  // for the dump.
  runLoader();

  const dumpClient = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await dumpClient.connect();
  try {
    await dumpFresh(dumpClient);
  } finally {
    await dumpClient.end();
  }

  const result = diff();
  if (!result.ok) {
    console.error(`\nSNAPSHOT FAIL: CA / FIPS ${FIPS} — ${result.reasons.length} delta(s):`);
    for (const r of result.reasons) console.error(`  - ${r}`);
    process.exit(1);
  }

  // baseline.rows.length is the canonical row count when the snapshot is
  // byte-identical to the fresh dump (which it must be at this branch).
  const { rows } = readHashCsv(BASELINE_PATH);
  console.log(
    `\nSNAPSHOT PASS: CA / FIPS ${FIPS} — ${rows.length} rows match baseline.`,
  );
  process.exit(0);
}

main().catch((err) => {
  console.error('[test-tiger-baseline-ca] fatal:', err);
  process.exit(1);
});

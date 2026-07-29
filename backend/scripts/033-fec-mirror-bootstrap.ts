/**
 * 033-fec-mirror-bootstrap.ts — bootstrap a local DuckDB exploration mirror of FEC bulk
 * data (quick-260729-0jn, Phase D infrastructure rule from fec-deep-exploration-plan.md).
 *
 * "Thinking copy" (this mirror — full bulk columns, DuckDB, local, freely regenerable)
 * vs. "serving copy" (production Supabase — slim raw_record, authoritative, the read
 * path for the app). Whole-table SQL happens HERE, never against production: the
 * 2026-07-28 incident (a hash-agg spill that filled the Supabase disk) is exactly the
 * failure mode this script exists to make impossible.
 *
 * SAFETY (CON-01, non-negotiable): this script MUST NOT import `../src/lib/db.js`,
 * must NEVER read `DATABASE_URL`, and never opens a connection to Supabase. Every
 * table it builds comes from FEC's public bulk downloads (fec.gov) or local re-derivation
 * of what was already downloaded. Nothing here writes to, or even connects to, prod.
 *
 * Disk contract (CON-08): `indiv{YY}.zip` is multi-GB (2022 cycle: ~5.2 GB compressed).
 * Before any download of an `indiv` file this script requires >=25 GB free in the mirror
 * directory. Once the response headers are known, it re-checks the actual
 * `Content-Length * 5 + 5 GB` against free space and aborts BEFORE writing a single byte
 * if that doesn't fit (covers the multi-GB extracted .txt sitting next to the still-kept
 * .zip while a DuckDB table is built from it). Downloads stream straight to disk — no
 * whole-file buffering. If a zip already sits at `<mirror>/raw/` and its size matches the
 * server's Content-Length, download is skipped entirely (safe to re-run this script after
 * an interrupted session).
 *
 * Mirror location: this directory is intentionally OUTSIDE both git repos (CON-03) — only
 * this script is checked in; the mirror itself (multi-GB of regenerable data) never is.
 *
 * CLI:
 *   tsx scripts/033-fec-mirror-bootstrap.ts load <cycle> <fileKind> [--mirror DIR] [--table NAME] [--sample N] [--keep-extract]
 *   tsx scripts/033-fec-mirror-bootstrap.ts smoke [--mirror DIR]
 *
 * Examples:
 *   tsx scripts/033-fec-mirror-bootstrap.ts load 2022 ccl --mirror G:/FEC-Mirror
 *   tsx scripts/033-fec-mirror-bootstrap.ts load 2022 indiv --mirror G:/FEC-Mirror
 *   tsx scripts/033-fec-mirror-bootstrap.ts load 2022 oth --mirror G:/FEC-Mirror --table oth22_raw --sample 5
 *   tsx scripts/033-fec-mirror-bootstrap.ts smoke --mirror G:/FEC-Mirror
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import readline from 'node:readline';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { execFileSync } from 'node:child_process';
import unzipper from 'unzipper';

const BULK_BASE = 'https://www.fec.gov/files/bulk-downloads';
const GB = 1024 * 1024 * 1024;

// Pinned DuckDB CLI release — never fetch a "latest" redirect target implicitly. If this
// is bumped, update the version string here (the README records whichever version was
// actually resolved, including its SHA-256, at bootstrap time).
const PINNED_DUCKDB_VERSION = '1.5.5';
function duckdbReleaseUrl(version: string): string {
  return `https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-windows-amd64.zip`;
}

// Repos this mirror must never live inside of (CON-03).
const FORBIDDEN_ROOTS = [
  path.resolve('C:/EV-Accounts'),
  path.resolve('C:/Transparent Motivations'),
];

// Known, verified bulk-file column layouts (FEC data dictionary:
// https://www.fec.gov/files/bulk-downloads/data_dictionaries/{indiv,ccl}_header_file.csv,
// cross-checked against fecBulkLoader.ts's I_* column-index constants). Anything else
// loads positionally (see loadOne) with a printed warning — never guess a named layout
// for a file that hasn't been sampled and checked against FEC's own header file.
const FILE_SPECS: Record<string, string[]> = {
  indiv: [
    'cmte_id', 'amndt_ind', 'rpt_tp', 'transaction_pgi', 'image_num', 'transaction_tp',
    'entity_tp', 'name', 'city', 'state', 'zip_code', 'employer', 'occupation',
    'transaction_dt', 'transaction_amt', 'other_id', 'tran_id', 'file_num', 'memo_cd',
    'memo_text', 'sub_id',
  ],
  ccl: ['cand_id', 'cand_election_yr', 'fec_election_yr', 'cmte_id', 'cmte_tp', 'cmte_dsgn', 'linkage_id'],
  // quick-260729-0jn (Task 3, EXPL-C1): verified against FEC's official header dictionary
  // (fec.gov/files/bulk-downloads/data_dictionaries/oth_header_file.csv) AND sampled —
  // 200,000 lines all showed exactly 21 fields, matching the 21-column header exactly. Same
  // physical layout as `indiv` (this is the "any transaction from one committee to another"
  // file), so it reuses the same column names — semantics differ (the entity/name fields
  // describe the OTHER committee/person in the transaction, not necessarily an individual).
  oth: [
    'cmte_id', 'amndt_ind', 'rpt_tp', 'transaction_pgi', 'image_num', 'transaction_tp',
    'entity_tp', 'name', 'city', 'state', 'zip_code', 'employer', 'occupation',
    'transaction_dt', 'transaction_amt', 'other_id', 'tran_id', 'file_num', 'memo_cd',
    'memo_text', 'sub_id',
  ],
  // quick-260729-0jn (Task 3, EXPL-C1): the official header dictionary
  // (oppexp_header_file.csv) lists 25 named columns, but 200,000 sampled 2022-cycle lines
  // ALL show exactly 26 pipe-delimited fields — positions 1-25 line up perfectly against the
  // documented layout (verified against recognizable values: line_num, form_tp_cd,
  // sched_tp_cd, category codes, tran_id format), and position 26 is consistently empty. This
  // is a genuine, verified discrepancy from the published spec (an undocumented trailing
  // field), not a guess — recorded here and in the findings doc rather than silently dropped.
  oppexp: [
    'cmte_id', 'amndt_ind', 'rpt_yr', 'rpt_tp', 'image_num', 'line_num', 'form_tp_cd',
    'sched_tp_cd', 'name', 'city', 'state', 'zip_code', 'transaction_dt', 'transaction_amt',
    'transaction_pgi', 'purpose', 'category', 'category_desc', 'memo_cd', 'memo_text',
    'entity_tp', 'sub_id', 'file_num', 'tran_id', 'back_ref_tran_id', 'undocumented_trailing_col',
  ],
};

// --------------------------------------------------------------------------
// CLI arg parsing
// --------------------------------------------------------------------------

function flagVal(argv: string[], name: string): string | undefined {
  const i = argv.indexOf(name);
  return i >= 0 ? argv[i + 1] : undefined;
}

function hasFlag(argv: string[], name: string): boolean {
  return argv.includes(name);
}

// --------------------------------------------------------------------------
// Mirror directory resolution + guard (CON-03)
// --------------------------------------------------------------------------

function resolveMirrorDir(argv: string[]): string {
  const raw = flagVal(argv, '--mirror') ?? process.env.FEC_MIRROR_DIR ?? 'C:/FEC-Mirror';
  const resolved = path.resolve(raw);
  for (const forbidden of FORBIDDEN_ROOTS) {
    if (resolved === forbidden || resolved.startsWith(forbidden + path.sep)) {
      console.error(`[033] mirror must live outside both git repos — pass --mirror (resolved to ${resolved}, inside ${forbidden})`);
      process.exit(1);
    }
  }
  return resolved;
}

// --------------------------------------------------------------------------
// Disk pre-flight (CON-08)
// --------------------------------------------------------------------------

function assertFreeSpace(dir: string, requiredBytes: number, context: string): void {
  fs.mkdirSync(dir, { recursive: true });
  const stat = fs.statfsSync(dir);
  const freeBytes = stat.bavail * stat.bsize;
  const reqGb = (requiredBytes / GB).toFixed(1);
  const freeGb = (freeBytes / GB).toFixed(1);
  if (freeBytes < requiredBytes) {
    console.error(`[033] INSUFFICIENT DISK SPACE (${context}): need ${reqGb} GB, have ${freeGb} GB free at ${dir}.`);
    console.error('[033] Pass --mirror pointing at a roomier drive (e.g. --mirror D:/FEC-Mirror) and re-run.');
    process.exit(1);
  }
  console.log(`[033] disk pre-flight OK (${context}): need ${reqGb} GB, have ${freeGb} GB free at ${dir}.`);
}

// --------------------------------------------------------------------------
// DuckDB CLI acquisition (no new npm dependency — local-only tool)
// --------------------------------------------------------------------------

interface DuckdbMeta {
  exe: string;
  source: 'PATH' | 'mirror-bin' | 'downloaded';
  version?: string;
  sha256?: string;
  url?: string;
}

function metaPath(mirrorDir: string): string {
  return path.join(mirrorDir, 'bin', '.duckdb-meta.json');
}

async function resolveDuckdbCli(mirrorDir: string): Promise<DuckdbMeta> {
  // 1. Already on PATH.
  try {
    execFileSync('duckdb', ['--version'], { stdio: 'pipe' });
    console.log('[033] using duckdb already on PATH');
    return { exe: 'duckdb', source: 'PATH' };
  } catch {
    // not on PATH — fall through
  }

  const binDir = path.join(mirrorDir, 'bin');
  const exePath = path.join(binDir, 'duckdb.exe');

  // 2. Already downloaded into this mirror previously.
  if (fs.existsSync(exePath)) {
    console.log(`[033] using previously-downloaded duckdb at ${exePath}`);
    const metaFile = metaPath(mirrorDir);
    if (fs.existsSync(metaFile)) {
      const meta = JSON.parse(fs.readFileSync(metaFile, 'utf8')) as DuckdbMeta;
      return { ...meta, exe: exePath, source: 'mirror-bin' };
    }
    return { exe: exePath, source: 'mirror-bin' };
  }

  // 3. Download the pinned official release. Print the exact resolved URL and the
  // SHA-256 of the downloaded zip — never fetch a "latest" redirect target implicitly.
  fs.mkdirSync(binDir, { recursive: true });
  const url = duckdbReleaseUrl(PINNED_DUCKDB_VERSION);
  console.log(`[033] downloading DuckDB CLI v${PINNED_DUCKDB_VERSION} from ${url}`);
  const res = await fetch(url);
  if (!res.ok || !res.body) throw new Error(`DuckDB CLI download failed: HTTP ${res.status} for ${url}`);
  const buf = Buffer.from(await res.arrayBuffer());
  const sha256 = crypto.createHash('sha256').update(buf).digest('hex');
  console.log(`[033] downloaded ${buf.length.toLocaleString()} bytes — SHA-256: ${sha256}`);

  const directory = await unzipper.Open.buffer(buf);
  const entry = directory.files.find((f) => /duckdb\.exe$/i.test(f.path));
  if (!entry) throw new Error(`duckdb.exe not found inside ${url} — zip contents: ${directory.files.map((f) => f.path).join(', ')}`);
  await new Promise<void>((resolve, reject) => {
    entry.stream().pipe(fs.createWriteStream(exePath)).on('close', resolve).on('error', reject);
  });

  const meta: DuckdbMeta = { exe: exePath, source: 'downloaded', version: PINNED_DUCKDB_VERSION, sha256, url };
  fs.writeFileSync(metaPath(mirrorDir), JSON.stringify(meta, null, 2));
  return meta;
}

// --------------------------------------------------------------------------
// DuckDB CLI invocation
// --------------------------------------------------------------------------

/**
 * Conservative memory_limit + a temp_directory on the (roomy) mirror drive, prepended to
 * every DuckDB invocation. This machine has been observed to have as little as ~5.5 GB of
 * free physical RAM at times (other processes competing for it), and DuckDB's default
 * memory_limit (a fraction of detected total RAM) can exceed what is actually free, which
 * surfaces as "Out of Memory Error: Allocation failure" rather than a graceful disk spill.
 * Capping memory_limit well under free RAM and pointing temp_directory at the mirror disk
 * (5+ TB free, per the pre-flight checks) makes DuckDB spill large intermediate CSV-parse
 * buffers to disk instead of erroring out.
 */
function memorySafetyPragmas(mirrorDir: string): string {
  const tmpDir = path.join(mirrorDir, 'tmp').replace(/\\/g, '/');
  fs.mkdirSync(path.join(mirrorDir, 'tmp'), { recursive: true });
  return `SET memory_limit='3GB'; SET temp_directory='${tmpDir}'; `;
}

function runDuckSql(exe: string, dbPath: string, mirrorDir: string, sql: string): void {
  execFileSync(exe, [dbPath, '-c', memorySafetyPragmas(mirrorDir) + sql], { stdio: 'inherit', maxBuffer: 1024 * 1024 * 64 });
}

/** Run SQL and parse `-json` output into an array of rows. Returns [] on an empty result. */
function queryDuckJson<T = Record<string, unknown>>(exe: string, dbPath: string, mirrorDir: string, sql: string): T[] {
  const out = execFileSync(exe, [dbPath, '-json', '-c', memorySafetyPragmas(mirrorDir) + sql], { encoding: 'utf8', maxBuffer: 1024 * 1024 * 64 });
  const trimmed = out.trim();
  if (!trimmed) return [];
  return JSON.parse(trimmed) as T[];
}

// --------------------------------------------------------------------------
// Download (streamed, no whole-file buffering) with skip-if-already-present
// --------------------------------------------------------------------------

async function ensureDownloaded(url: string, destZip: string, mirrorDir: string, isIndiv: boolean): Promise<void> {
  const headRes = await fetch(url, { method: 'HEAD' });
  if (!headRes.ok) throw new Error(`HEAD failed: HTTP ${headRes.status} for ${url}`);
  const expectedLen = Number(headRes.headers.get('content-length') ?? '0');

  if (fs.existsSync(destZip)) {
    const st = fs.statSync(destZip);
    if (expectedLen > 0 && st.size === expectedLen) {
      console.log(`[033] ${destZip} already present (${st.size.toLocaleString()} bytes, matches server) — skipping download`);
      return;
    }
    console.log(`[033] ${destZip} exists but size differs (have ${st.size.toLocaleString()}, server has ${expectedLen.toLocaleString()}) — re-downloading`);
  }

  if (isIndiv) {
    assertFreeSpace(mirrorDir, 25 * GB, 'pre-download floor for indiv (25 GB)');
  }
  if (expectedLen > 0) {
    assertFreeSpace(mirrorDir, expectedLen * 5 + 5 * GB, `content-length-based check (Content-Length=${expectedLen.toLocaleString()} * 5 + 5 GB)`);
  }

  console.log(`[033] downloading ${url} -> ${destZip} (Content-Length=${expectedLen.toLocaleString()})`);
  const res = await fetch(url);
  if (!res.ok || !res.body) throw new Error(`download failed: HTTP ${res.status} for ${url}`);
  const nodeStream = Readable.fromWeb(res.body as Parameters<typeof Readable.fromWeb>[0]);
  await pipeline(nodeStream, fs.createWriteStream(destZip));
  const finalSize = fs.statSync(destZip).size;
  console.log(`[033] download complete: ${finalSize.toLocaleString()} bytes`);
}

/** Extract the single entry inside a zip to a destination path. Constant memory. */
async function extractSingleEntry(zipPath: string, destPath: string): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const out = fs.createReadStream(zipPath).pipe(unzipper.ParseOne()).pipe(fs.createWriteStream(destPath));
    out.on('close', resolve);
    out.on('finish', resolve);
    out.on('error', reject);
  });
}

/** Print the first N lines of a file with their pipe-split field counts (column-position eyeball check). */
async function printSample(txtPath: string, n: number): Promise<void> {
  const rl = readline.createInterface({ input: fs.createReadStream(txtPath), crlfDelay: Infinity });
  let i = 0;
  for await (const line of rl) {
    if (i >= n) break;
    const fields = line.split('|');
    console.log(`[033][sample ${i}] fields=${fields.length} | ${line}`);
    i++;
  }
  rl.close();
}

/** Derive col00..colNN names from the maximum field count seen in the first 1,000 lines. */
async function derivePositionalNames(txtPath: string): Promise<string[]> {
  const rl = readline.createInterface({ input: fs.createReadStream(txtPath), crlfDelay: Infinity });
  let maxFields = 0;
  let i = 0;
  for await (const line of rl) {
    if (i >= 1000) break;
    const fields = line.split('|').length;
    if (fields > maxFields) maxFields = fields;
    i++;
  }
  rl.close();
  const names: string[] = [];
  for (let c = 0; c < maxFields; c++) names.push(`col${String(c).padStart(2, '0')}`);
  return names;
}

function buildCreateTableSql(table: string, csvPath: string, names: string[]): string {
  const posixPath = csvPath.replace(/\\/g, '/');
  const namesClause = `[${names.map((n) => `'${n}'`).join(',')}]`;
  return `CREATE OR REPLACE TABLE ${table} AS SELECT * FROM read_csv('${posixPath}', delim='|', header=false, quote='', escape='', all_varchar=true, null_padding=true, ignore_errors=true, names=${namesClause});`;
}

// --------------------------------------------------------------------------
// README generation — regenerated after every successful load/smoke, never drifts
// --------------------------------------------------------------------------

function writeReadme(mirrorDir: string, duck: DuckdbMeta, tableLog: string[]): void {
  const dbPath = path.join(mirrorDir, 'fec_mirror.duckdb');
  let inventory = '(no tables yet)';
  if (fs.existsSync(dbPath)) {
    try {
      const tables = queryDuckJson<{ table_name: string }>(duck.exe, dbPath, mirrorDir, `SELECT table_name FROM information_schema.tables WHERE table_schema='main' ORDER BY 1;`);
      const rows = tables.map((t) => {
        const [{ n }] = queryDuckJson<{ n: number }>(duck.exe, dbPath, mirrorDir, `SELECT count(*) AS n FROM ${t.table_name};`);
        return `| ${t.table_name} | ${n.toLocaleString()} |`;
      });
      inventory = rows.length ? `| table | rows |\n|---|---|\n${rows.join('\n')}` : '(no tables yet)';
    } catch (err) {
      inventory = `(inventory query failed: ${err instanceof Error ? err.message : String(err)})`;
    }
  }

  const duckdbLine = duck.version
    ? `DuckDB CLI v${duck.version} — downloaded from ${duck.url ?? '(unknown url)'} — SHA-256: ${duck.sha256 ?? '(unknown)'}`
    : `DuckDB CLI resolved via ${duck.source} (${duck.exe})`;

  const readme = `# FEC-Mirror — local exploration copy (quick-260729-0jn)

**Do not confuse this with production.** This directory is the "thinking copy": a full-column,
local, disposable DuckDB re-download of FEC's public bulk data, used for whole-table SQL
exploration. Production Supabase (\`transparent_motivations.contributions\`) is the "serving
copy" — authoritative, slim \`raw_record\`, and it must NEVER receive a whole-table aggregate
query (CON-01; the 2026-07-28 incident is why this mirror exists at all).

This directory is intentionally OUTSIDE both git repos (\`C:/EV-Accounts\` and
\`C:/Transparent Motivations\`). Nothing under here is committed anywhere. Everything under
here is safely deletable and freely re-downloadable from fec.gov — delete the whole
directory any time and re-run the commands below to rebuild it.

## DuckDB CLI

${duckdbLine}

## Regenerate

\`\`\`
cd C:/EV-Accounts/backend
npx tsx scripts/033-fec-mirror-bootstrap.ts load 2022 ccl --mirror ${mirrorDir}
npx tsx scripts/033-fec-mirror-bootstrap.ts load 2022 indiv --mirror ${mirrorDir}
npx tsx scripts/033-fec-mirror-bootstrap.ts smoke --mirror ${mirrorDir}
\`\`\`

## Commands run this session

${tableLog.length ? tableLog.map((l) => `- \`${l}\``).join('\n') : '(none recorded this run)'}

## Table inventory

${inventory}

## Raw zips

\`<mirror>/raw/\` holds the downloaded \`.zip\` files (kept — small relative to the extracted
text, and re-downloadable in seconds if deleted). Extracted \`.txt\` files are deleted after
each load unless \`--keep-extract\` was passed.
`;
  fs.writeFileSync(path.join(mirrorDir, 'README.md'), readme);
  console.log(`[033] wrote ${path.join(mirrorDir, 'README.md')}`);
}

// --------------------------------------------------------------------------
// load subcommand
// --------------------------------------------------------------------------

async function runLoad(cycle: string, fileKind: string, argv: string[]): Promise<void> {
  const mirrorDir = resolveMirrorDir(argv);
  const rawDir = path.join(mirrorDir, 'raw');
  fs.mkdirSync(rawDir, { recursive: true });
  fs.mkdirSync(path.join(mirrorDir, 'bin'), { recursive: true });

  const yy = cycle.slice(-2);
  const url = `${BULK_BASE}/${cycle}/${fileKind}${yy}.zip`;
  const zipPath = path.join(rawDir, `${fileKind}${yy}.zip`);
  const txtPath = path.join(rawDir, `${fileKind}${yy}.txt`);
  const table = flagVal(argv, '--table') ?? `${fileKind}${yy}`;
  const sampleN = flagVal(argv, '--sample') ? parseInt(flagVal(argv, '--sample')!, 10) : undefined;
  const keepExtract = hasFlag(argv, '--keep-extract');

  await ensureDownloaded(url, zipPath, mirrorDir, fileKind === 'indiv');

  console.log(`[033] extracting ${zipPath} -> ${txtPath}`);
  await extractSingleEntry(zipPath, txtPath);

  if (sampleN) {
    console.log(`[033] --sample ${sampleN}: first ${sampleN} raw lines of ${fileKind}${yy}`);
    await printSample(txtPath, sampleN);
  }

  const spec = FILE_SPECS[fileKind];
  const names = spec ?? await derivePositionalNames(txtPath);
  if (!spec) {
    console.warn(`[033] WARNING: '${fileKind}' has no verified named FILE_SPECS entry — loading POSITIONALLY as [${names.join(', ')}]. Sample and confirm against FEC's published layout before drawing conclusions.`);
  }

  const duck = await resolveDuckdbCli(mirrorDir);
  const dbPath = path.join(mirrorDir, 'fec_mirror.duckdb');
  const sql = buildCreateTableSql(table, txtPath, names);
  console.log(`[033] loading into table '${table}' (db=${dbPath})`);
  runDuckSql(duck.exe, dbPath, mirrorDir, sql);

  if (!keepExtract) {
    fs.rmSync(txtPath, { force: true });
    console.log(`[033] deleted extracted ${txtPath} (pass --keep-extract to retain)`);
  } else {
    console.log(`[033] kept extracted ${txtPath} (--keep-extract)`);
  }

  const [{ n: rowCount }] = queryDuckJson<{ n: number }>(duck.exe, dbPath, mirrorDir, `SELECT count(*) AS n FROM ${table};`);
  console.log(`[033] ${table}: ${Number(rowCount).toLocaleString()} rows loaded`);

  writeReadme(mirrorDir, duck, [`load ${cycle} ${fileKind} --mirror ${mirrorDir}${flagVal(argv, '--table') ? ` --table ${table}` : ''}`]);
}

// --------------------------------------------------------------------------
// smoke subcommand
// --------------------------------------------------------------------------

async function runSmoke(argv: string[]): Promise<void> {
  const mirrorDir = resolveMirrorDir(argv);
  const dbPath = path.join(mirrorDir, 'fec_mirror.duckdb');
  if (!fs.existsSync(dbPath)) {
    console.error(`[033] no mirror database at ${dbPath} — run 'load 2022 ccl' and 'load 2022 indiv' first`);
    process.exit(1);
  }
  const duck = await resolveDuckdbCli(mirrorDir);
  let failed = false;

  // (a) ccl22 exact row count
  const [{ n: cclN }] = queryDuckJson<{ n: number }>(duck.exe, dbPath, mirrorDir, `SELECT count(*) AS n FROM ccl22;`);
  const cclOk = Number(cclN) === 7682;
  console.log(`[033][smoke a] ccl22 rows = ${cclN} (expected exactly 7682) — ${cclOk ? 'PASS' : 'FAIL'}`);
  if (!cclOk) failed = true;

  // (b) indiv22 row count within band, delta from verified 63,885,803
  const [{ n: indivN }] = queryDuckJson<{ n: number }>(duck.exe, dbPath, mirrorDir, `SELECT count(*) AS n FROM indiv22;`);
  const indivNum = Number(indivN);
  const delta = indivNum - 63_885_803;
  const indivOk = indivNum >= 63_800_000 && indivNum <= 63_950_000;
  console.log(`[033][smoke b] indiv22 rows = ${indivNum.toLocaleString()} (band 63,800,000-63,950,000; delta from 63,885,803 quick-031 baseline = ${delta >= 0 ? '+' : ''}${delta.toLocaleString()}) — ${indivOk ? 'PASS' : 'FAIL'}`);
  if (!indivOk) failed = true;

  // (c) amendment-chain visibility, cycle-wide
  const amndtDist = queryDuckJson<{ amndt_ind: string; n: number }>(duck.exe, dbPath, mirrorDir, `SELECT amndt_ind, count(*) AS n FROM indiv22 GROUP BY 1 ORDER BY 2 DESC;`);
  const distinctNonEmpty = amndtDist.filter((r) => r.amndt_ind && r.amndt_ind.trim() !== '').length;
  const amndtOk = distinctNonEmpty >= 2;
  console.log(`[033][smoke c] amndt_ind distribution cycle-wide: ${JSON.stringify(amndtDist)} — ${distinctNonEmpty} distinct non-empty values — ${amndtOk ? 'PASS' : 'FAIL'}`);
  if (!amndtOk) failed = true;

  // (d) amendment-chain visibility, Warnock 2022 principal committee — reported for
  // information (this is the plan's originally-assumed demo committee), but NOT gated.
  // Verified empirically (quick-260729-0jn): 100% of C00736876's 1,079,333 indiv22 rows
  // carry amndt_ind='A' — every report this committee ever filed for the 2022 cycle was
  // eventually amended, so there is no surviving 'N' (new/original) row to contrast
  // against. This is a genuine, verified property of the real data (confirmed: all SUB_IDs
  // distinct, no duplicate/malformed rows), not a mirror or query defect — a real finding
  // worth carrying into A1, not a reason to fail the smoke test on a now-falsified
  // assumption. See README / SUMMARY for the write-up.
  const warnockDist = queryDuckJson<{ amndt_ind: string; n: number }>(duck.exe, dbPath, mirrorDir, `SELECT amndt_ind, count(*) AS n FROM indiv22 WHERE cmte_id='C00736876' GROUP BY 1 ORDER BY 2 DESC;`);
  console.log(`[033][smoke d] amndt_ind distribution for C00736876 (Warnock 2022, informational — see comment above): ${JSON.stringify(warnockDist)}`);

  // (d') per-committee amendment-chain visibility, gated: prove the mechanism itself
  // works (a per-committee GROUP BY on amndt_ind returns >1 distinct value for SOME real,
  // named committee), rather than asserting it must hold for the one specific committee
  // the plan assumed. NRSC (C00027466) is a large, well-known, non-conduit committee
  // verified to show real amndt_ind diversity.
  const nrscDist = queryDuckJson<{ amndt_ind: string; n: number }>(duck.exe, dbPath, mirrorDir, `SELECT amndt_ind, count(*) AS n FROM indiv22 WHERE cmte_id='C00027466' GROUP BY 1 ORDER BY 2 DESC;`);
  const nrscOk = nrscDist.length > 1;
  console.log(`[033][smoke d'] amndt_ind distribution for C00027466 (NRSC 2022): ${JSON.stringify(nrscDist)} — ${nrscOk ? 'PASS' : 'FAIL'}`);
  if (!nrscOk) failed = true;

  // (e) report-type spread for the same committee — informational only, not gated
  const rptDist = queryDuckJson<{ rpt_tp: string; n: number }>(duck.exe, dbPath, mirrorDir, `SELECT rpt_tp, count(*) AS n FROM indiv22 WHERE cmte_id='C00736876' GROUP BY 1 ORDER BY 2 DESC LIMIT 10;`);
  console.log(`[033][smoke e] rpt_tp distribution for C00736876 (informational, not gated): ${JSON.stringify(rptDist)}`);

  writeReadme(mirrorDir, duck, ['smoke --mirror ' + mirrorDir]);

  if (failed) {
    console.error('[033] smoke FAILED — see gates above');
    process.exit(1);
  }
  console.log('[033] smoke PASSED');
}

// --------------------------------------------------------------------------
// main
// --------------------------------------------------------------------------

async function main(): Promise<void> {
  const [, , sub, ...rest] = process.argv;
  if (sub === 'load') {
    const [cycle, fileKind, ...flags] = rest;
    if (!cycle || !/^\d{4}$/.test(cycle) || !fileKind) {
      console.error('usage: tsx scripts/033-fec-mirror-bootstrap.ts load <cycle> <fileKind> [--mirror DIR] [--table NAME] [--sample N] [--keep-extract]');
      process.exit(1);
    }
    await runLoad(cycle, fileKind, flags);
  } else if (sub === 'smoke') {
    await runSmoke(rest);
  } else {
    console.error('usage: tsx scripts/033-fec-mirror-bootstrap.ts load <cycle> <fileKind> [--mirror DIR] [--table NAME] [--sample N] [--keep-extract]');
    console.error('   or: tsx scripts/033-fec-mirror-bootstrap.ts smoke [--mirror DIR]');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('[033] Fatal:', err);
  process.exit(1);
});

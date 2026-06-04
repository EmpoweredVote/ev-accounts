/**
 * verify-stance-research.ts — deterministic verification gate for /research-stances.
 *
 * Reads a batch directory's `stances.csv` + `evidence.csv`, fetches each cited
 * URL with headless Chromium, and checks every snippet appears verbatim on the
 * page (after normalization) with the politician's name within 500 characters.
 * No LLM in the loop. See .claude/skills/research-stances/README.md and
 * docs/superpowers/specs/2026-04-30-stance-research-verification-design.md.
 *
 *   Dry-run (default): prints the pushable / re-research / review partition,
 *     including the failed-source URLs to feed a re-research --exclude-urls list.
 *   --apply: pushes pushable rows to inform.politician_answers +
 *     inform.politician_context + inform.politician_context_evidence, and writes
 *     below-threshold / unresolved rows to inform.stance_research_review.
 *
 * Usage:
 *   npx tsx scripts/verify-stance-research.ts --dir data/stance-research/<batch> \
 *     [--threshold 2] [--batch-id <id>] [--apply] [--re-researched]
 *
 * Idempotent: re-running the same batch (e.g. after appending re-research rows
 * to the CSVs) is safe — all writes are upserts / replace-by-key.
 */
import { readFileSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';
import { pool } from '../src/lib/db.js';
import { parseStancesCsv, parseEvidenceCsv } from '../src/lib/stanceResearchCsv.js';
import {
  verifyEvidence,
  createPageFetcher,
  type StanceRow,
  type EvidenceRow,
  type PoliticianNames,
  type VerifiedRow,
} from '../src/lib/researchVerifier.js';
import { createVerificationFetchSession } from '../src/lib/verificationFetch.js';
import {
  buildEvidenceRowsForInsert,
  buildReviewRowForInsert,
  replaceEvidence,
  upsertReviewRow,
} from '../src/lib/researchEvidenceService.js';

// ---------------------------------------------------------------- args
function flag(name: string): boolean {
  return process.argv.includes(name);
}
function opt(name: string, def?: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}

const DIR = opt('--dir');
if (!DIR) {
  console.error('ERROR: --dir <batch directory> is required');
  process.exit(2);
}
// Default 1 verified source (cheap mode — avoids a re-research wave). Override
// with --threshold or the RESEARCH_STANCES_THRESHOLD env var.
const THRESHOLD = Number(opt('--threshold', process.env.RESEARCH_STANCES_THRESHOLD ?? '1'));
const BATCH_ID = opt('--batch-id', basename(DIR.replace(/\/+$/, '')))!;
const APPLY = flag('--apply');
const RE_RESEARCHED = flag('--re-researched'); // stamp review rows as re_research_attempted

// ---------------------------------------------------------------- load CSVs
const stancesPath = join(DIR, 'stances.csv');
const evidencePath = join(DIR, 'evidence.csv');
if (!existsSync(stancesPath)) {
  console.error(`ERROR: ${stancesPath} not found`);
  process.exit(2);
}
const allStances: StanceRow[] = parseStancesCsv(readFileSync(stancesPath, 'utf8'));
const evidenceRows: EvidenceRow[] = existsSync(evidencePath)
  ? parseEvidenceCsv(readFileSync(evidencePath, 'utf8'))
  : [];

// value=null rows are an explicit "insufficient evidence" signal: skip verification,
// drop in normal mode (never pushed, never queued).
const nullRows = allStances.filter((s) => s.value === null);
const stanceRows = allStances.filter((s) => s.value !== null);

// ---------------------------------------------------------------- resolve names + topics
const csvNames = [...new Set(stanceRows.map((s) => s.full_name))];
const { rows: polRows } = csvNames.length
  ? await pool.query<{ id: string; full_name: string }>(
      `SELECT id, full_name FROM essentials.politicians
       WHERE full_name = ANY($1)
          OR lower(full_name) = ANY(SELECT lower(n) FROM unnest($1::text[]) AS n)`,
      [csvNames],
    )
  : { rows: [] };
const dbByLower = new Map(polRows.map((p) => [p.full_name.toLowerCase(), p]));

const lastToken = (name: string) => name.trim().split(/\s+/).filter(Boolean).slice(-1)[0] ?? name;

const politicianNames: PoliticianNames = {};
const idByName = new Map<string, string | null>(); // csv name -> politician_id (or null if unmatched)
for (const name of csvNames) {
  const db = dbByLower.get(name.toLowerCase());
  const canonical = db?.full_name ?? name;
  politicianNames[name] = { fullName: canonical, lastName: lastToken(canonical) };
  idByName.set(name, db?.id ?? null);
}

const { rows: topicRows } = await pool.query<{ topic_id: string; topic_key: string }>(
  `SELECT id AS topic_id, topic_key FROM inform.compass_topics WHERE is_live = true`,
);
const topicIdByKey = new Map(topicRows.map((t) => [t.topic_key, t.topic_id]));

// ---------------------------------------------------------------- verify
// Tiered fetch ladder (HTTP → headless Chromium → Wayback), reusing one browser
// across the batch. No LLM in the loop.
const fetchSession = createVerificationFetchSession();
const fetcher = createPageFetcher(fetchSession.fetch);
const { pushable, needsReResearch } = await verifyEvidence({
  stanceRows,
  evidenceRows,
  fetcher,
  threshold: THRESHOLD,
  politicianNames,
});
await fetchSession.close();

// A below-threshold row is re-researchable only if its politician resolved; an
// unresolved politician can never push, so it routes straight to review.
const reResearch = needsReResearch.filter((r) => idByName.get(r.stance.full_name));
const unresolved = needsReResearch.filter((r) => !idByName.get(r.stance.full_name));

const failedUrls = (row: VerifiedRow) => row.failedSources.map((s) => s.url);

// ---------------------------------------------------------------- report
console.log(`\n=== verify-stance-research — batch "${BATCH_ID}" (threshold ${THRESHOLD}) ===`);
console.log(
  `stance rows: ${allStances.length} (${stanceRows.length} scored, ${nullRows.length} value=null skipped) | evidence rows: ${evidenceRows.length}`,
);
console.log(
  `\nPUSHABLE: ${pushable.length}   RE-RESEARCH: ${reResearch.length}   UNRESOLVED→REVIEW: ${unresolved.length}`,
);

if (pushable.length) {
  console.log('\n--- pushable (>= threshold verified sources) ---');
  for (const r of pushable) {
    console.log(`  PUSH\t${r.stance.full_name}\t${r.stance.topic_key}\tvalue=${r.stance.value}\tverified_sources=${r.verifiedSources.length}`);
  }
}
if (reResearch.length) {
  console.log('\n--- below threshold → re-research ONE pass, exclude these failed URLs ---');
  for (const r of reResearch) {
    console.log(`  RE-RESEARCH\t${r.stance.full_name}\t${r.stance.topic_key}\tverified=${r.verifiedSources.length}/${THRESHOLD}\texclude-urls=${failedUrls(r).join(',') || '(none — no sources captured)'}`);
  }
}
if (unresolved.length) {
  console.log('\n--- unresolved politician (not in essentials.politicians) → review queue ---');
  for (const r of unresolved) {
    console.log(`  REVIEW\t${r.stance.full_name}\t${r.stance.topic_key}\t(no politician_id — preserved as full_name_raw)`);
  }
}
if (nullRows.length) {
  console.log('\n--- value=null (skipped; not pushed, not queued) ---');
  for (const s of nullRows) console.log(`  SKIP\t${s.full_name}\t${s.topic_key}`);
}

// ---------------------------------------------------------------- apply
if (!APPLY) {
  console.log('\n(dry-run — pass --apply to write answers/context/evidence and review-queue rows)');
  await pool.end();
  process.exit(0);
}

console.log('\n=== --apply: writing to database ===');
let pushed = 0;
let evidenceWritten = 0;
let reviewed = 0;
const errors: string[] = [];
const pushedPoliticianIds = new Set<string>();

for (const row of pushable) {
  const pid = idByName.get(row.stance.full_name)!;
  const tid = topicIdByKey.get(row.stance.topic_key);
  if (!pid || !tid) {
    errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${!pid ? 'no politician_id' : 'unknown topic_key'} — skipped`);
    continue;
  }
  try {
    await pool.query(
      `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
      [pid, tid, row.stance.value],
    );
    const sources = row.verifiedSources.map((s) => s.url);
    await pool.query(
      `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (politician_id, topic_id)
       DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
      [pid, tid, row.stance.reasoning, sources],
    );
    const evRows = buildEvidenceRowsForInsert({ row, politicianId: pid, topicId: tid, batchId: BATCH_ID });
    await replaceEvidence(evRows);
    pushed++;
    evidenceWritten += evRows.length;
    pushedPoliticianIds.add(pid);
    console.log(`  PUSHED ${row.stance.full_name}/${row.stance.topic_key} value=${row.stance.value} (${evRows.length} snippets)`);
  } catch (e: any) {
    errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
  }
}

for (const row of [...reResearch, ...unresolved]) {
  const pid = idByName.get(row.stance.full_name) ?? null;
  const tid = pid ? topicIdByKey.get(row.stance.topic_key) ?? null : null;
  try {
    await upsertReviewRow(
      buildReviewRowForInsert({
        row,
        politicianId: pid,
        topicId: tid,
        batchId: BATCH_ID,
        threshold: THRESHOLD,
        reResearchAttempted: RE_RESEARCHED,
      }),
    );
    reviewed++;
    console.log(`  REVIEW ${row.stance.full_name}/${row.stance.topic_key} (${pid ? 'pending' : 'unresolved_politician'})`);
  } catch (e: any) {
    errors.push(`REVIEW ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
  }
}

if (pushedPoliticianIds.size) {
  await pool.query(
    `UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY($1::uuid[])`,
    [[...pushedPoliticianIds]],
  );
}

console.log(
  `\nSUMMARY: pushed=${pushed} (snippets=${evidenceWritten}) reviewed=${reviewed} stamped=${pushedPoliticianIds.size} errors=${errors.length}`,
);
if (errors.length) {
  errors.forEach((e) => console.log('  ' + e));
  process.exitCode = 1;
}
await pool.end();

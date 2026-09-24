/**
 * export-written-ledger.ts — the audit-chair-evidence ledger for a batch's RESOLVED review rows,
 * after human approval (Task 7 of docs/superpowers/plans/2026-09-23-stance-program-reconciliation.md).
 *
 * verify-stance-research.ts --apply already writes <dir>/written-<batch>.json for rows IT wrote
 * directly (auto-push). Under review-all (the default — ruling 2026-09-22), almost nothing is
 * auto-pushed: a person approves each row in the admin review queue afterward
 * (resolveResearchReview, inform.stance_research_review.status = 'resolved'), so this script is
 * how THOSE rows get audited. It reads only:
 *   - inform.stance_research_review (read-only — no INSERT/UPDATE/DELETE in this script), for the
 *     batch's resolved rows and the value ACTUALLY written to inform.politician_answers (never
 *     proposed_value, which a reviewer's valueOverride can leave stale);
 *   - <dir>/research.csv, for each pair's evidence_type — the review row does not store one
 *     (stance_research_review has no evidence_type column).
 *
 * Global Constraint: "audit-chair-evidence --check runs on record rows only" — a `statement` row
 * (the person's own words) cannot name an instrument, act or vote by definition, so it is dropped
 * here rather than let it read as an unevidenced record row when audit-chair-evidence runs. A row
 * this script cannot classify against research.csv at all is also dropped, and listed — never
 * guessed into either lane.
 *
 * Usage:
 *   npx tsx scripts/export-written-ledger.ts --batch <id> --dir <dir>
 * Writes <dir>/written-<batch>.json, the shape scripts/audit-chair-evidence.mjs --check reads:
 *   { "season_id": "<uuid>" | null, "rows": [{ politician_id, topic_id, chair_after, season_id }] }
 *
 * Positive-control rule (CLAUDE.md): a detector that finds nothing must not report a clean, empty
 * result — audit-chair-evidence.mjs's own header calls an empty `rows[]` a VACUOUS PASS, not a
 * clean batch. So this script REFUSES to write an empty ledger, with a message that distinguishes
 * "0 resolved rows for this batch" (wrong --batch, or nothing approved yet) from "N resolved rows,
 * 0 classified as record" (every row was statement evidence, or unclassifiable) — either is a
 * batch nothing should be exported for, but they are different problems.
 *
 * Exit: 0 ok. 2 usage, an unreadable/unparsable research.csv, or an empty result (0 resolved rows,
 * or 0 of them classify as record evidence).
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';
import { stanceKey } from '../src/lib/researchVerifier.js';
import { reviewLadderColumnsExist } from '../src/lib/researchEvidenceService.js';
import {
  buildLedgerFile, classifyResolvedRows, evidenceTypeByKey,
  type ResearchCsvRow, type ResolvedReviewRow,
} from './lib/writtenLedger.js';

function opt(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i !== -1 && i + 1 < process.argv.length ? process.argv[i + 1] : undefined;
}

const BATCH = opt('--batch');
const DIR = opt('--dir');
if (!BATCH || !DIR) {
  console.error('usage: export-written-ledger.ts --batch <id> --dir <dir>');
  process.exit(2);
}

const researchPath = join(DIR, 'research.csv');
if (!existsSync(researchPath)) {
  console.error(`ERROR: ${researchPath} not found`);
  process.exit(2);
}
let researchRecords: Record<string, string>[];
try {
  researchRecords = parse(readFileSync(researchPath, 'utf8'), {
    columns: true, skip_empty_lines: true, relax_column_count: true,
  }) as Record<string, string>[];
} catch (err) {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`ERROR: ${researchPath} is not valid CSV: ${msg}`);
  process.exit(2);
}
// Positive-control rule: a parse of 0 rows cannot classify anything, and must not read the same
// as "no record rows" further down — refuse now, distinctly, before any DB query.
if (researchRecords.length === 0) {
  console.error(`REFUSING: parsed 0 rows from ${researchPath} — an empty parse cannot classify anything`);
  process.exit(2);
}
const csvRows: ResearchCsvRow[] = researchRecords.map((r) => ({
  full_name: (r.full_name ?? '').trim(),
  topic_key: (r.topic_key ?? '').trim(),
  evidence_type: (r.evidence_type ?? '').trim(),
}));
const typeByKey = evidenceTypeByKey(csvRows, stanceKey);

// ---------------------------------------------------------------- read-only DB query
// CA_0264 (topic_revision_id/season_id on stance_research_review) may not be applied yet (per the
// migration's own commit, "NOT APPLIED") — probe rather than assume, same pattern
// verify-stance-research.ts already uses via reviewLadderColumnsExist(). Without it, a legacy row
// carries no season_id of its own; the open season is the only season available for the join,
// read-only, same as every other legacy-row fallback in researchEvidenceService.ts.
const ladderColumns = await reviewLadderColumnsExist();
const seasonIdSelect = ladderColumns ? 'r.season_id' : 'NULL::uuid';
const { rows: dbRows } = await pool.query<{
  full_name_raw: string; topic_key: string;
  politician_id: string | null; topic_id: string | null;
  season_id: string | null; chair_after: string | null;
}>(
  `SELECT r.full_name_raw, r.topic_key,
          r.politician_id::text AS politician_id, r.topic_id::text AS topic_id,
          COALESCE(${seasonIdSelect}, open_season.id)::text AS season_id,
          a.value::text AS chair_after
     FROM inform.stance_research_review r
     LEFT JOIN inform.seasons open_season ON open_season.status = 'open'
     LEFT JOIN inform.politician_answers a
            ON a.politician_id = r.politician_id AND a.topic_id = r.topic_id
           AND a.season_id = COALESCE(${seasonIdSelect}, open_season.id)
    WHERE r.batch_id = $1 AND r.status = 'resolved'`,
  [BATCH],
);
await pool.end();

if (dbRows.length === 0) {
  console.error(`REFUSING: 0 resolved review row(s) found for batch "${BATCH}" in inform.stance_research_review `
    + '— check the --batch id, or that anything has actually been approved yet');
  process.exit(2);
}

const resolvedRows: ResolvedReviewRow[] = dbRows.map((r) => ({
  full_name_raw: r.full_name_raw,
  topic_key: r.topic_key,
  politician_id: r.politician_id,
  topic_id: r.topic_id,
  season_id: r.season_id,
  chair_after: r.chair_after === null ? null : Number(r.chair_after),
}));
const { included, excluded } = classifyResolvedRows(resolvedRows, typeByKey, stanceKey);

console.log(`resolved review rows for batch "${BATCH}": ${resolvedRows.length}`);
if (excluded.length) {
  console.log(`excluded ${excluded.length} of ${resolvedRows.length} row(s) (not record evidence, or unclassifiable):`);
  for (const e of excluded) console.log(`  · ${e}`);
}

// Positive-control rule, second half: "N resolved, 0 classified as record" is a DIFFERENT failure
// than "0 resolved" above, and gets its own message — every row here was statement evidence, or
// nothing matched research.csv, which is worth knowing before assuming the batch is simply clean.
if (included.length === 0) {
  console.error(`REFUSING to write an empty ledger: 0 of ${resolvedRows.length} resolved row(s) classified as record evidence. `
    + 'audit-chair-evidence --check on an empty rows[] is a vacuous pass (see its own header), not a clean batch.');
  process.exit(2);
}

const outPath = join(DIR, `written-${BATCH}.json`);
writeFileSync(outPath, JSON.stringify(buildLedgerFile(included), null, 2));
console.log(`wrote ${outPath} (${included.length} record row(s) of ${resolvedRows.length} resolved)`);
process.exit(0);

/**
 * queue-coded-batch.ts — the coder pipeline's publish writer. It puts a coded batch's unanimous
 * chairs into the EXISTING review queue (inform.stance_research_review); a person approves each on
 * the review page, and resolveResearchReview writes the answer, the context (with its CA_0300
 * evidence tier) and one politician_context_evidence row per source (with its CA_0301 date).
 * Nothing here publishes: no stratum is certified (spec 2026-09-25 §7 P3), and review-all stands.
 *
 * Run AFTER code-stance-batch.ts --apply (which writes coding-report.json and stores the labels):
 *
 *   npx tsx scripts/queue-coded-batch.ts --dir <batch> (--season-id <uuid> | --season open|draft|<uuid>) [--apply]
 *
 * Dry-run by default. --apply writes every row and links its labels (stance_coder_labels.review_id)
 * in ONE transaction. Re-running is safe: a row a person already decided is left alone.
 */
import 'dotenv/config';
import { seasonIdFromArgs, SeasonTargetError } from './lib/seasonTarget.js';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CODEBOOK_VERSION, validateCoderLabelFile, type CoderRow } from './lib/coderLabel.js';
import { consensusSlot, type CoderRowLabel } from './lib/agreement.js';
import { buildCoderReviewRow, type CoderReviewRow, type SnapshotInfo } from './lib/coderQueue.js';
import type { RowReport } from './lib/codingReport.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const APPLY = process.argv.includes('--apply');
// --season-id <uuid> (as before) or --season open|draft|<uuid>; a batch dir built for another season is refused.
let seasonId: string | undefined;
try {
  // A uuid (--season-id, as before) needs no database; --season open|draft resolves through the pool.
  seasonId = (dir ? await seasonIdFromArgs(process.argv, dir,
    async (q, p) => (await import('../src/lib/db.js')).pool.query(q, p)) : null) ?? undefined;
} catch (e) {
  if (!(e instanceof SeasonTargetError)) throw e;
  console.error(`ERROR: ${e.message}`);
  process.exit(2);
}
if (!dir || !seasonId) { console.error('usage: --dir <batch> (--season-id <uuid> | --season open|draft|<uuid>) [--apply]'); process.exit(2); }

const reportPath = join(dir, 'coding-report.json');
if (!existsSync(reportPath)) { console.error(`no ${reportPath} — run code-stance-batch.ts first`); process.exit(1); }
const report = JSON.parse(readFileSync(reportPath, 'utf8')) as { codebook_version: string; rows: RowReport[] };
if (report.codebook_version !== CODEBOOK_VERSION) {
  console.error(`coding-report.json is codebook ${report.codebook_version}, this code is ${CODEBOOK_VERSION} — re-run code-stance-batch.ts`);
  process.exit(1);
}
if (report.rows.some((r) => r.outcome.kind === 'unanimous-chair' && !('evidence_tier' in r))) {
  console.error('coding-report.json predates the evidence tier (CA_0300) — re-run code-stance-batch.ts');
  process.exit(1);
}

const context = JSON.parse(readFileSync(join(dir, 'coding-context.json'), 'utf8'));
const batchId: string = context.batch_id;
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const snapshotInfo = new Map<string, SnapshotInfo>(snapshots.filter((s) => s.ok && s.snapshot_text)
  .map((s) => [s.snapshot_id, { url: s.url, source_kind: s.source_kind, snapshot_text: s.snapshot_text! }]));
const snapshotText = new Map([...snapshotInfo].map(([id, s]) => [id, s.snapshot_text]));

// The consensus row per key: the same validation and the same consensusSlot the report used.
const bySlot = new Map<number, Map<string, CoderRow>>();
for (const slot of [1, 2, 3]) {
  const p = join(dir, 'labels', `coder-${slot}.json`);
  const rows = new Map<string, CoderRow>();
  if (existsSync(p)) {
    const v = validateCoderLabelFile(JSON.parse(readFileSync(p, 'utf8')), { snapshotText, expectedSlot: slot });
    if (v.fileErrors.length === 0) for (const r of v.rows) if (r.row && !rows.has(r.key)) rows.set(r.key, r.row);
  }
  bySlot.set(slot, rows);
}

const queued: CoderReviewRow[] = [];
for (const r of report.rows) {
  const topic = (context.topics as { topic_id: string; topic_key: string; served_revision_id: string }[]).find((t) => t.topic_key === r.topic_key);
  if (!topic || r.outcome.kind !== 'unanimous-chair') continue;
  const labels: CoderRowLabel[] = [1, 2, 3].flatMap((slot) => {
    const row = bySlot.get(slot)!.get(r.key);
    return row ? [{ slot, valid: true, value: row.v6_value, blank_reason: row.v6_blank_reason, rests_on: row.rests_on, needs_source: row.needs_source }] : [];
  });
  const consensusRow = bySlot.get(consensusSlot(labels, r.outcome.value))!.get(r.key)!;
  const row = buildCoderReviewRow({
    batchId, seasonId, codebookVersion: CODEBOOK_VERSION, seat: context.seat, topic, report: r, consensusRow, snapshots: snapshotInfo,
  });
  if (row) queued.push(row);
}

const skipped = report.rows.filter((r) => r.outcome.kind !== 'unanimous-chair');
for (const q of queued) {
  console.log(`queue  ${q.topic_key.padEnd(28)} chair ${q.proposed_value}  ${(q.evidence_tier ?? '-').padEnd(13)} `
    + `${q.verified_source_count}/${q.evidence.length} source(s) publishable  [${q.queue_reasons.join(', ')}]`);
  for (const u of q.unpublishable) console.log(`         no publishable window: ${u} (a reviewer can add it as a human-verified URL)`);
}
for (const r of skipped) console.log(`skip   ${r.topic_key.padEnd(28)} ${r.outcome.kind}`);

if (!APPLY) {
  console.log(`\ndry run: ${queued.length} row(s) would be queued, ${skipped.length} skipped. Re-run with --apply.`);
  process.exit(0);
}

const { pool } = await import('../src/lib/db.js');
const client = await pool.connect();
let written = 0; let decided = 0;
try {
  await client.query('BEGIN');
  for (const q of queued) {
    // The labels must already be stored (code-stance-batch.ts --apply): the review row links to them.
    const { rows: [{ n }] } = await client.query<{ n: string }>(
      `SELECT count(*) AS n FROM inform.stance_coder_labels
        WHERE batch_id = $1 AND politician_id = $2 AND office_id = $3 AND topic_id = $4 AND coder_slot BETWEEN 1 AND 3`,
      [q.batch_id, q.politician_id, q.office_id, q.topic_id]);
    if (Number(n) !== 3) throw new Error(`${q.topic_key}: ${n}/3 coder labels stored — run code-stance-batch.ts --apply first`);

    // Same idempotent key and the same "never resurrect a decision" guard as upsertReviewRow.
    const res = await client.query<{ id: string }>(
      `INSERT INTO inform.stance_research_review
         (batch_id, politician_id, full_name_raw, topic_id, topic_key, proposed_value, proposed_reasoning, evidence,
          verified_source_count, threshold, status, re_research_attempted, season_id, served_revision_id,
          queue_reasons, evidence_type, review_mode, codebook_version, unanimous, consensus_value, office_id, evidence_tier)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, 1, 'pending', false, $10, $11,
               $12::text[], $13, 'standard', $14, true, $15, $16, $17)
       ON CONFLICT (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key)
       DO UPDATE SET proposed_value = EXCLUDED.proposed_value, proposed_reasoning = EXCLUDED.proposed_reasoning,
         evidence = EXCLUDED.evidence, verified_source_count = EXCLUDED.verified_source_count,
         queue_reasons = EXCLUDED.queue_reasons, evidence_type = EXCLUDED.evidence_type,
         codebook_version = EXCLUDED.codebook_version, consensus_value = EXCLUDED.consensus_value,
         evidence_tier = EXCLUDED.evidence_tier, served_revision_id = EXCLUDED.served_revision_id
       WHERE inform.stance_research_review.status IN ('pending', 'unresolved_politician')
       RETURNING id`,
      [q.batch_id, q.politician_id, q.full_name_raw, q.topic_id, q.topic_key, q.proposed_value, q.proposed_reasoning,
        JSON.stringify(q.evidence), q.verified_source_count, q.season_id, q.served_revision_id, q.queue_reasons,
        q.evidence_type, q.codebook_version, q.consensus_value, q.office_id, q.evidence_tier]);
    if (res.rowCount === 0) { decided++; continue; }
    await client.query(
      `UPDATE inform.stance_coder_labels SET review_id = $1
        WHERE batch_id = $2 AND politician_id = $3 AND office_id = $4 AND topic_id = $5`,
      [res.rows[0].id, q.batch_id, q.politician_id, q.office_id, q.topic_id]);
    written++;
  }
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK').catch(() => undefined);
  console.error(`ERROR: nothing was queued — ${(err as Error).message}`);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
if (!process.exitCode) console.log(`queued ${written} row(s) for review; ${decided} already decided and left alone.`);

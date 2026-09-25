/**
 * code-stance-batch.ts — SHADOW coding report for one politician's batch (spec §7 P1).
 * Reads coding-context.json, snapshots.json and labels/coder-{1,2,3}.json; writes coding-report.json
 * and needs-source.json. Changes NOTHING that is published. --apply stores the labels in
 * inform.stance_coder_labels (needs CA_<slot> applied and the operator's OK).
 *   npx tsx scripts/code-stance-batch.ts --dir <batch> --season-id <uuid> --models "opus,sonnet,sonnet" [--apply]
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { buildCodingReport } from './lib/codingReport.js';
import { validateCoderLabelFile, CODEBOOK_VERSION } from './lib/coderLabel.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const seasonId = arg('--season-id'); const models = (arg('--models') ?? '').split(',');
const APPLY = process.argv.includes('--apply');
if (!dir || !seasonId || models.length !== 3) { console.error('usage: --dir <batch> --season-id <uuid> --models "m1,m2,m3" [--apply]'); process.exit(2); }

const context = JSON.parse(readFileSync(join(dir, 'coding-context.json'), 'utf8'));
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const snapshotText = new Map(snapshots.filter((s) => s.ok && s.snapshot_text).map((s) => [s.snapshot_id, s.snapshot_text!]));
const files = new Map<number, unknown>();
const rawText = new Map<number, string>();
for (const slot of [1, 2, 3]) {
  const p = join(dir, 'labels', `coder-${slot}.json`);
  if (!existsSync(p)) continue;
  const t = readFileSync(p, 'utf8');
  rawText.set(slot, t);
  try { files.set(slot, JSON.parse(t)); } catch { files.set(slot, t); } // prose → invalid, not a crash
}
const report = buildCodingReport({ context, files, snapshotText });
writeFileSync(join(dir, 'coding-report.json'), JSON.stringify({ codebook_version: CODEBOOK_VERSION, models, ...report }, null, 2));
writeFileSync(join(dir, 'needs-source.json'), JSON.stringify(report.needsSource, null, 2));

console.log(`M1 (batch) alpha = ${report.m1.alpha === null ? 'undefined' : report.m1.alpha.toFixed(3)} over ${report.m1.units} rows`);
for (const v of report.validity) console.log(`coder ${v.slot}: ${v.fileErrors.length ? v.fileErrors.join('; ') : 'file ok'}, ${v.rowErrors} invalid row(s)`);
for (const r of report.rows) console.log(`${r.shadow.padEnd(27)} ${r.topic_key.padEnd(28)} ${r.outcome.kind}${r.shadow_reasons.length ? `  [${r.shadow_reasons.join(', ')}]` : ''}`);
if (report.needsSource.length) console.log(`\n${report.needsSource.length} row(s) request sources → ${join(dir, 'needs-source.json')} (collector fetches, then re-snapshot and re-code all three)`);

if (APPLY) {
  const { pool } = await import('../src/lib/db.js');
  for (const slot of [1, 2, 3]) {
    const raw = files.get(slot);
    if (raw === undefined) continue;
    const v = validateCoderLabelFile(raw, { snapshotText, expectedSlot: slot });
    const sha = createHash('sha256').update(rawText.get(slot)!).digest('hex');
    // validateCoderLabelFile returns one entry per raw row, in order — so index aligns them, and an
    // INVALID row is still stored (valid=false, with its errors): an invalid label is data (spec §5.5).
    const rawRows = ((raw as { rows?: unknown[] }).rows ?? []) as Record<string, any>[];
    for (let idx = 0; idx < v.rows.length; idx++) {
      const r = v.rows[idx];
      const row = rawRows[idx];
      if (r.key === '?' || !row) continue; // no identifiable (politician, office, topic) — nothing to key it on
      const valid = v.fileErrors.length === 0 && r.errors.length === 0;
      await pool.query(
        `INSERT INTO inform.stance_coder_labels (batch_id, politician_id, office_id, topic_id, season_id, served_revision_id, coder_slot, model,
            codebook_version, value, blank_reason, rests_on, source_codes, quote_codes, needs_source, valid, validation_errors, label_sha256, raw_output)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
         ON CONFLICT (batch_id, politician_id, office_id, topic_id, coder_slot) DO NOTHING`,
        [context.batch_id, row.politician_id, row.office_id, row.topic_id, seasonId, row.served_revision_id, slot, models[slot - 1], CODEBOOK_VERSION,
         valid ? row.v6_value : null, valid ? row.v6_blank_reason : null, valid ? row.rests_on : [], JSON.stringify(row.passages ?? []),
         JSON.stringify(row.quotes ?? []), JSON.stringify(row.needs_source ?? []), valid, [...v.fileErrors, ...r.errors], sha, row]);
    }
  }
  await pool.end();
  console.log('stored coder labels in inform.stance_coder_labels (shadow; nothing published)');
}

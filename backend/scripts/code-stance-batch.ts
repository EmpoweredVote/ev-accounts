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
import type { CoderRow } from './lib/coderLabel.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';
import { buildDisagreementDigest } from './lib/disagreementDigest.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const seasonId = arg('--season-id'); const models = (arg('--models') ?? '').split(',');
const APPLY = process.argv.includes('--apply');
if (!dir || !seasonId || models.length !== 3 || models.some((m) => m.trim().length === 0)) {
  console.error('usage: --dir <batch> --season-id <uuid> --models "m1,m2,m3" (each name non-empty) [--apply]');
  process.exit(2);
}

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

// Improvement loop 1 (spec sec10.1): which codebook variables did the coders read differently?
const validRows = new Map<number, CoderRow[]>();
for (const [slot, raw] of files) {
  const v = validateCoderLabelFile(raw, { snapshotText, expectedSlot: slot });
  if (v.fileErrors.length) continue;
  const seenKeys = new Set<string>();
  const rows: CoderRow[] = [];
  for (const r of v.rows) {
    if (!r.row || r.errors.length !== 0) continue;
    if (seenKeys.has(r.key)) continue; // duplicate row key within this file — keep only the first (matches codingReport.ts)
    seenKeys.add(r.key);
    rows.push(r.row);
  }
  validRows.set(slot, rows);
}
const digest = buildDisagreementDigest(validRows);
writeFileSync(join(dir, 'disagreement-digest.json'), JSON.stringify({ codebook_version: CODEBOOK_VERSION, ...digest }, null, 2));
console.log(`most-split codebook variables: ${digest.ranked.slice(0, 3).join(', ') || 'none'} -> ${join(dir, 'disagreement-digest.json')}`);

if (APPLY) {
  // Scope filter (fix round 1, item 1): only rows that belong to THIS batch's seat and topic set may
  // be inserted. A row with a foreign politician/office/topic id is skipped, never inserted and never
  // allowed to abort the slot — it is reported and the loop moves on.
  const topicIds = new Set<string>((context.topics as { topic_id: string }[]).map((t) => t.topic_id));
  const inScope = (row: Record<string, any>) =>
    row.politician_id === context.seat.politician_id && row.office_id === context.seat.office_id && topicIds.has(row.topic_id);

  const { pool } = await import('../src/lib/db.js');
  let totalInserted = 0;
  let totalAlreadyPresent = 0;
  try {
    for (const slot of [1, 2, 3]) {
      const raw = files.get(slot);
      if (raw === undefined) continue;
      const v = validateCoderLabelFile(raw, { snapshotText, expectedSlot: slot });
      const sha = createHash('sha256').update(rawText.get(slot)!).digest('hex');
      // validateCoderLabelFile returns one entry per raw row, in order — so index aligns them, and an
      // INVALID row is still stored (valid=false, with its errors): an invalid label is data (spec §5.5).
      const rawRows = ((raw as { rows?: unknown[] }).rows ?? []) as Record<string, any>[];
      // Item 3: store the FILE's own codebook_version; fall back to the constant only when absent.
      const rawVersion = raw !== null && typeof raw === 'object' ? (raw as { codebook_version?: unknown }).codebook_version : undefined;
      const fileVersion = typeof rawVersion === 'string' && rawVersion.length > 0 ? rawVersion : CODEBOOK_VERSION;

      // Item 4: flag and dedupe (politician, office, topic) keys within this one file — keep only the
      // first occurrence, matching what buildCodingReport already does for the report.
      const firstIndexForKey = new Map<string, number>();
      const dupKeys = new Set<string>();
      for (let idx = 0; idx < rawRows.length; idx++) {
        const row = rawRows[idx];
        if (!row) continue;
        const key = `${row.politician_id}|${row.office_id}|${row.topic_id}`;
        if (firstIndexForKey.has(key)) dupKeys.add(key);
        else firstIndexForKey.set(key, idx);
      }
      if (dupKeys.size) console.warn(`coder ${slot}: duplicate row key(s) [${[...dupKeys].join(', ')}] — keeping only the first occurrence`);

      const client = await pool.connect();
      let slotInserted = 0;
      let slotAlreadyPresent = 0;
      try {
        await client.query('BEGIN');
        for (let idx = 0; idx < v.rows.length; idx++) {
          const r = v.rows[idx];
          const row = rawRows[idx];
          if (r.key === '?' || !row) continue; // no identifiable (politician, office, topic) — nothing to key it on
          const key = `${row.politician_id}|${row.office_id}|${row.topic_id}`;
          if (firstIndexForKey.get(key) !== idx) continue; // duplicate occurrence — first already handled/skipped
          if (!inScope(row)) { console.warn(`coder ${slot}: row ${key} skipped (not in this batch)`); continue; }
          const valid = v.fileErrors.length === 0 && r.errors.length === 0;
          const result = await client.query(
            `INSERT INTO inform.stance_coder_labels (batch_id, politician_id, office_id, topic_id, season_id, served_revision_id, coder_slot, model,
                codebook_version, value, blank_reason, rests_on, source_codes, quote_codes, needs_source, valid, validation_errors, label_sha256, raw_output)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
             ON CONFLICT (batch_id, politician_id, office_id, topic_id, coder_slot) DO NOTHING`,
            [context.batch_id, row.politician_id, row.office_id, row.topic_id, seasonId, row.served_revision_id, slot, models[slot - 1], fileVersion,
             valid ? row.v6_value : null, valid ? row.v6_blank_reason : null, valid ? row.rests_on : [], JSON.stringify(row.passages ?? []),
             JSON.stringify(row.quotes ?? []), JSON.stringify(row.needs_source ?? []), valid, [...v.fileErrors, ...r.errors], sha, row]);
          // Item 2: ON CONFLICT DO NOTHING means rowCount === 0 for a row that was already there —
          // that is a re-apply, not a fresh insert, so count the two separately.
          if (result.rowCount && result.rowCount > 0) slotInserted++; else slotAlreadyPresent++;
        }
        await client.query('COMMIT');
        totalInserted += slotInserted;
        totalAlreadyPresent += slotAlreadyPresent;
      } catch (e) {
        await client.query('ROLLBACK');
        console.error(`coder ${slot}: transaction failed and was rolled back — ${(e as Error).message}`);
      } finally {
        client.release();
      }
    }
  } finally {
    await pool.end();
  }
  console.log(`stored coder labels in inform.stance_coder_labels (shadow; nothing published): ${totalInserted} inserted, ${totalAlreadyPresent} already present`);
  if (totalAlreadyPresent > 0) {
    console.warn(
      'WARNING: this batch appears to have already been applied — the old labels were kept (ON CONFLICT DO NOTHING never overwrites). ' +
      'Re-snapshot into a fresh batch directory and re-code all three before applying again.',
    );
    process.exit(1);
  }
}

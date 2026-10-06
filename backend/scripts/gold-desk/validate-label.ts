/**
 * validate-label.ts — validate one coder's label file against its batch's snapshots, the same way
 * code-stance-batch does, and print the result as JSON: { fileErrors, rows: [{ key, errors, value,
 * blank_reason }] }. Used by repair.py to give a coder its own validation errors back.
 *   npx tsx scripts/gold-desk/validate-label.ts <batch-dir> <slot>
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { validateCoderLabelFile } from '../lib/coderLabel.js';
import type { SnapshotRecord } from '../lib/snapshotSources.js';

const [dir, slotArg] = process.argv.slice(2);
const slot = Number(slotArg);
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const snapshotText = new Map(snapshots.filter((s) => s.ok && s.snapshot_text).map((s) => [s.snapshot_id, s.snapshot_text!]));
const raw = JSON.parse(readFileSync(join(dir, 'labels', `coder-${slot}.json`), 'utf8'));
const v = validateCoderLabelFile(raw, { snapshotText, expectedSlot: slot });
const rawRows = (raw?.rows ?? []) as Record<string, unknown>[];
console.log(JSON.stringify({
  fileErrors: v.fileErrors,
  rows: v.rows.map((r, i) => ({ key: r.key, errors: r.errors, value: rawRows[i]?.v6_value ?? null, blank_reason: rawRows[i]?.v6_blank_reason ?? null })),
}));

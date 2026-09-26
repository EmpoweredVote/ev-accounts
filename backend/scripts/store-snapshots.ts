/**
 * store-snapshots.ts — stores a batch's EXISTING snapshots.json in inform.source_snapshots, without
 * fetching anything. Use it when the coders have already coded the batch: `snapshot-sources --apply`
 * re-fetches every page, so a page that changed since would get a new snapshot id the coders never
 * cited — and a robots-disallowed site would be fetched again.
 *
 *   npx tsx scripts/store-snapshots.ts --dir data/stance-research/<batch> [--apply]
 *
 * Dry-run by default. One transaction per batch; ON CONFLICT (id) DO NOTHING (ids are deterministic).
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { SnapshotRecord } from './lib/snapshotSources.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const APPLY = process.argv.includes('--apply');
if (!dir) { console.error('usage: --dir <batch dir> [--apply]'); process.exit(2); }

const manifest = JSON.parse(readFileSync(join(dir, 'sources.json'), 'utf8')) as { batch_id: string };
const snaps = (JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[]).filter((s) => s.ok && s.snapshot_text);
console.log(`${manifest.batch_id}: ${snaps.length} codable snapshot(s)`);
if (!APPLY) { console.log('dry run — re-run with --apply to store'); process.exit(0); }

const { pool } = await import('../src/lib/db.js');
const client = await pool.connect();
let inserted = 0;
try {
  await client.query('BEGIN');
  for (const s of snaps) {
    const r = await client.query(
      `INSERT INTO inform.source_snapshots (id, batch_id, url, source_kind, fetched_by, page_sha256, snapshot_text, excerpt_only)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (id) DO NOTHING`,
      [s.snapshot_id, manifest.batch_id, s.url, s.source_kind, s.fetched_by, s.page_sha256, s.snapshot_text, s.excerpt_only]);
    inserted += r.rowCount ?? 0;
  }
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
  console.error(`rolled back — nothing stored: ${(e as Error).message}`);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
if (!process.exitCode) console.log(`inserted ${inserted} (${snaps.length - inserted} already present)`);

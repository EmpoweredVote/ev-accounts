// backend/scripts/snapshot-sources.ts
/**
 * snapshot-sources.ts — fetch every source in <batch>/sources.json through the verifier's fetch
 * ladder (HTTP → Wayback, robots respected), or read a human-saved page (spec §5.4), and write
 * <batch>/snapshots.json. --apply also inserts inform.source_snapshots (needs CA_<slot> applied and the
 * operator's OK). No LLM in the loop.
 *   npx tsx scripts/snapshot-sources.ts --dir data/stance-research/<batch> [--apply]
 * Exit 0 always writes the file; failures are listed and are not codable (spec §5.4).
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { parseSourcesManifest } from './lib/sourcesManifest.js';
import { buildSnapshot, type SnapshotRecord } from './lib/snapshotSources.js';
import { createPageFetcher } from '../src/lib/researchVerifier.js';
import { createVerificationFetchSession, htmlToText } from '../src/lib/verificationFetch.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir');
const APPLY = process.argv.includes('--apply');
if (!dir) { console.error('usage: --dir <batch dir> [--apply]'); process.exit(2); }

const parsed = parseSourcesManifest(JSON.parse(readFileSync(join(dir, 'sources.json'), 'utf8')));
if (!parsed.ok) { console.error(parsed.errors.join('\n')); process.exit(2); }
const { manifest } = parsed;

const session = createVerificationFetchSession();
const fetcher = createPageFetcher(session.fetch);
const out: SnapshotRecord[] = [];
for (const entry of manifest.sources) {
  if (entry.human_saved_path) {
    const html = readFileSync(join(dir, entry.human_saved_path), 'utf8');
    out.push(buildSnapshot({ entry, fetchedText: htmlToText(html), failure: null, fetchedBy: 'human', newId: randomUUID }));
    continue;
  }
  const r = await fetcher(entry.url);
  out.push(r.ok
    ? buildSnapshot({ entry, fetchedText: r.text, failure: null, fetchedBy: 'code', newId: randomUUID })
    : buildSnapshot({ entry, fetchedText: null, failure: r.reason, fetchedBy: 'code', newId: randomUUID }));
}
await session.close();
writeFileSync(join(dir, 'snapshots.json'), JSON.stringify(out, null, 2));
const bad = out.filter((s) => !s.ok);
console.log(`${out.length - bad.length}/${out.length} sources snapshotted → ${join(dir, 'snapshots.json')}`);
for (const s of bad) console.log(`  NOT CODABLE  ${s.failure}  ${s.url}${s.source_kind === 'public-record' || s.source_kind === 'own-site' ? '  → a person may save it in a browser (spec §5.4)' : ''}`);

if (APPLY) {
  const { pool } = await import('../src/lib/db.js');
  for (const s of out.filter((x) => x.ok)) {
    await pool.query(
      `INSERT INTO inform.source_snapshots (id, batch_id, url, source_kind, fetched_by, page_sha256, snapshot_text, excerpt_only)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (batch_id, url, page_sha256) DO NOTHING`,
      [s.snapshot_id, manifest.batch_id, s.url, s.source_kind, s.fetched_by, s.page_sha256, s.snapshot_text, s.excerpt_only]);
  }
  await pool.end();
  console.log('inserted into inform.source_snapshots');
}

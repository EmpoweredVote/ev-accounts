/**
 * record-gold-labels.ts — writes a person's gold decisions (goldLabels.ts file format) into
 * inform.stance_gold_labels (CA_0292, append-only). Dry-run by default; --apply writes, in ONE
 * transaction, and skips an entry already stored (same politician, office, topic, served revision,
 * mode and blind_submitted_at) — so a re-run adds nothing.
 *
 * The topic id and the served revision come from the batch's own topics.json (topics.all.json when the
 * batch was trimmed): gold is bound to the exact ladder text the coders were shown.
 *
 *   npx tsx scripts/record-gold-labels.ts --file <gold.json> --season-id <open season uuid> [--apply]
 *
 * The gold file must live OUTSIDE the repo (it may never reach a coder prompt).
 */
import 'dotenv/config';
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseGoldFile } from './lib/goldLabels.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const file = arg('--file'); const seasonId = arg('--season-id'); const APPLY = process.argv.includes('--apply');
if (!file || !seasonId) { console.error('usage: --file <gold.json> --season-id <uuid> [--apply]'); process.exit(2); }
const repoRoot = resolve(new URL('../..', import.meta.url).pathname);
if (resolve(file).startsWith(repoRoot + '/')) { console.error(`refusing: ${file} is inside the repo — gold must never be where a coder input could read it`); process.exit(2); }

const parsed = parseGoldFile(JSON.parse(readFileSync(file, 'utf8')));
if (!parsed.ok) { console.error(parsed.errors.join('\n')); process.exit(1); }

const dataDir = join(repoRoot, 'backend', 'data', 'stance-research');
const rows = parsed.entries.map((e) => {
  const dir = join(dataDir, e.batch);
  const f = existsSync(join(dir, 'topics.all.json')) ? join(dir, 'topics.all.json') : join(dir, 'topics.json');
  const t = (JSON.parse(readFileSync(f, 'utf8')) as { topic_id: string; topic_key: string; served_revision_id: string }[]).find((x) => x.topic_key === e.topic_key);
  if (!t) { console.error(`${e.item}: topic ${e.topic_key} not in ${f}`); process.exit(1); }
  return { e, topic_id: t.topic_id, served_revision_id: t.served_revision_id };
});

for (const { e } of rows) {
  const a = (x: { value: number | null; blank_reason: string | null }) => x.value ?? `BLANK ${x.blank_reason}`;
  console.log(`${e.item.padEnd(4)} ${e.topic_key.padEnd(24)} blind ${String(a(e.blind)).padEnd(22)} final ${String(a(e.final)).padEnd(22)} ${e.excluded_from_cert ? 'EXCLUDED' : 'counts'}`);
}
if (!APPLY) { console.log(`\ndry run: ${rows.length} entr(ies). Re-run with --apply to write.`); process.exit(0); }

const { pool } = await import('../src/lib/db.js');
const client = await pool.connect();
let inserted = 0; let present = 0;
try {
  await client.query('BEGIN');
  for (const { e, topic_id, served_revision_id } of rows) {
    const { rows: dup } = await client.query(
      `SELECT 1 FROM inform.stance_gold_labels WHERE politician_id = $1 AND office_id = $2 AND topic_id = $3 AND served_revision_id = $4
          AND mode = $5 AND blind_submitted_at IS NOT DISTINCT FROM $6::timestamptz`,
      [e.politician_id, e.office_id, topic_id, served_revision_id, e.mode, e.blind.submitted_at]);
    if (dup.length) { present++; continue; }
    await client.query(
      `INSERT INTO inform.stance_gold_labels (politician_id, office_id, topic_id, season_id, served_revision_id, mode,
         blind_value, blind_blank_reason, blind_submitted_at, final_value, final_blank_reason, source_judgments,
         codebook_version, reviewer_id, excluded_from_cert)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`,
      [e.politician_id, e.office_id, topic_id, seasonId, served_revision_id, e.mode,
        e.blind.value, e.blind.blank_reason, e.blind.submitted_at, e.final.value, e.final.blank_reason,
        JSON.stringify([{ item: e.item, batch: e.batch, note: e.note }]), e.codebook_version, e.reviewer_id, e.excluded_from_cert]);
    inserted++;
  }
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
  await pool.end();
}
console.log(`\nwrote ${inserted}, already present ${present}.`);

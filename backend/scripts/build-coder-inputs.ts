/**
 * build-coder-inputs.ts — writes <batch>/coding-context.json and <batch>/coder-inputs/coder-{1,2,3}.md
 * for ONE politician (one politician per run, ruling 2026-09-23). Reads the DB (read-only) for the
 * seat: a seated person via office_current_holder, a candidate via their race.
 * 🔴 A politician-rooted office_current_holder join can return several offices (CLAUDE.md) — pass
 * --office when it does; the script refuses to guess.
 *   npx tsx scripts/build-coder-inputs.ts --dir <batch> --politician <uuid> [--office <uuid>]
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { pool } from '../src/lib/db.js';
import { buildCoderPrompt, seedFor, type SeatContext, type PromptTopic } from './lib/coderPrompt.js';
import { annexPath } from './lib/codebookAnnex.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';
import { seatJurisdictionNames } from './lib/seatJurisdiction.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const politicianId = arg('--politician'); const officeArg = arg('--office');
if (!dir || !politicianId) { console.error('usage: --dir <batch> --politician <uuid> [--office <uuid>]'); process.exit(2); }
const repoRoot = resolve(process.cwd(), '..');
// The batch id is the dir name; sources.json's batch_id (what snapshot-sources stores) must agree,
// or the stored snapshots and the stored labels would sit under two different batch ids.
const batchId = dir.split('/').filter(Boolean).pop()!;
const sourcesPath = join(dir, 'sources.json');
if (existsSync(sourcesPath)) {
  const manifestBatch = (JSON.parse(readFileSync(sourcesPath, 'utf8')) as { batch_id?: unknown }).batch_id;
  if (manifestBatch !== undefined && manifestBatch !== batchId) {
    console.error(`sources.json batch_id ${String(manifestBatch)} != batch dir name ${batchId} — rename one so they agree`);
    process.exit(2);
  }
}

const politicians = JSON.parse(readFileSync(join(dir, 'politicians.json'), 'utf8')) as { full_name: string; politician_id: string; level: string | null; race_id: string | null }[];
const pol = politicians.find((p) => p.politician_id === politicianId);
if (!pol) { console.error(`politician ${politicianId} not in ${dir}/politicians.json`); process.exit(2); }

let seat: SeatContext;
const held = await pool.query(
  `SELECT och.office_id::text, o.title, o.representing_state, o.representing_city,
          och.term_start::text, och.term_end::text,
          (SELECT ot.start_precision FROM essentials.office_terms ot
            WHERE ot.office_id = och.office_id AND ot.politician_id = och.politician_id
              AND ot.term_start IS NOT DISTINCT FROM och.term_start
            ORDER BY ot.term_start DESC NULLS LAST LIMIT 1) AS start_precision
     FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
    WHERE och.politician_id = $1`, [politicianId]);
const heldAll = held.rows;
const heldRows = officeArg ? heldAll.filter((r) => r.office_id === officeArg) : heldAll;
if (officeArg && heldAll.length > 0 && heldRows.length === 0) {
  console.error(`--office ${officeArg} is not one of this politician's current offices: ${heldAll.map((r) => `${r.office_id} (${r.title})`).join(', ')}`);
  process.exit(2);
}
if (heldRows.length > 1) {
  console.error(`politician holds ${heldRows.length} offices — pass --office one of: ${heldRows.map((r) => `${r.office_id} (${r.title})`).join(', ')}`);
  process.exit(2);
}
if (heldRows.length === 1) {
  const r = heldRows[0];
  seat = { politician_id: politicianId, full_name: pol.full_name, level: pol.level, mode: 'seated', office_id: r.office_id, office_title: r.title,
    jurisdiction_names: seatJurisdictionNames(r.representing_state, r.representing_city), term_start: r.term_start, start_precision: r.start_precision, term_end: r.term_end, election_date: null };
} else if (pol.race_id) {
  const race = await pool.query(
    `SELECT r.office_id::text, o.title, o.representing_state, o.representing_city, e.election_date::text
       FROM essentials.races r
       LEFT JOIN essentials.offices o ON o.id = r.office_id
       JOIN essentials.elections e ON e.id = r.election_id
      WHERE r.id = $1`, [pol.race_id]);
  if (race.rowCount !== 1) { console.error(`race ${pol.race_id} not found`); process.exit(2); }
  const r = race.rows[0];
  if (!r.office_id) { console.error(`race ${pol.race_id} has no office_id — cannot establish the office being coded`); process.exit(2); }
  if (officeArg && r.office_id !== officeArg) {
    console.error(`--office ${officeArg} does not match this politician's race office ${r.office_id} (${r.title}) — cannot establish the office being coded`);
    process.exit(2);
  }
  seat = { politician_id: politicianId, full_name: pol.full_name, level: pol.level, mode: 'candidate', office_id: r.office_id, office_title: r.title,
    jurisdiction_names: seatJurisdictionNames(r.representing_state, r.representing_city), term_start: null, start_precision: null, term_end: null, election_date: r.election_date };
} else { console.error('no current seat and no race — cannot establish the office being coded'); process.exit(2); }
await pool.end();

const topicsRaw = JSON.parse(readFileSync(join(dir, 'topics.json'), 'utf8')) as Omit<PromptTopic, 'annexMd'>[];
const topics: PromptTopic[] = topicsRaw.map((t) => {
  const p = annexPath(repoRoot, t.topic_key);
  return { topic_id: t.topic_id, topic_key: t.topic_key, served_revision_id: t.served_revision_id, question_text: t.question_text, stances: t.stances,
    annexMd: existsSync(p) ? readFileSync(p, 'utf8') : null };
});
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const codebookMd = readFileSync(join(repoRoot, 'docs', 'codebook', 'stance-and-quote-codebook.md'), 'utf8');
writeFileSync(join(dir, 'coding-context.json'), JSON.stringify({ batch_id: batchId, seat, topics }, null, 2));
mkdirSync(join(dir, 'coder-inputs'), { recursive: true });
mkdirSync(join(dir, 'labels'), { recursive: true });
for (const slot of [1, 2, 3] as const) {
  const labelPath = resolve(dir, 'labels', `coder-${slot}.json`);
  const text = buildCoderPrompt({ codebookMd, seat, topics, snapshots, slot, seed: seedFor(batchId, slot), labelPath });
  const p = join(dir, 'coder-inputs', `coder-${slot}.md`);
  writeFileSync(p, text);
  console.log(`${p}  sha256 ${createHash('sha256').update(text).digest('hex').slice(0, 12)}  (${text.length} chars)`);
}

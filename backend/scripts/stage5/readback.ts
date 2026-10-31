/**
 * readback — after a write, count what the draft season now holds for the batch's people (STAGE5 step 7.14).
 *
 *   npx tsx --env-file=.env scripts/stage5/readback.ts --topic <key> <ids file> [--batch-id <id>]
 *
 * <ids file>: one politician id per line (the people the batch wrote). Prints outcomes by type, passages,
 * and review rows by batch and status; compare them with PREVIEW.md. Read-only.
 */
import { readFileSync } from 'node:fs';
import { pool } from '../../src/lib/db.js';
import { draftSeasonId, flag, topicId } from './batch-db.js';

const usage = 'readback.ts --topic <key> <ids file> [--batch-id <id>]';
const topic = flag('--topic', usage);
const batch = flag('--batch-id', usage, '');
const file = process.argv.slice(2).filter((a, i, all) => !a.startsWith('--') && !['--topic', '--batch-id'].includes(all[i - 1]))[0];
if (!file) { console.error(`usage: ${usage}`); process.exit(2); }
const ids = readFileSync(file, 'utf8').split('\n').map((l) => l.trim()).filter(Boolean);
const tid = await topicId(topic);
const sid = await draftSeasonId();
const q = async (label: string, sql: string, params: unknown[]) => console.log(label, JSON.stringify((await pool.query(sql, params)).rows));
await q('outcomes', `SELECT outcome, count(*)::int FROM inform.topic_research_outcomes
  WHERE topic_id = $1 AND season_id = $2 AND politician_id = ANY($3::uuid[]) GROUP BY 1 ORDER BY 1`, [tid, sid, ids]);
await q('passages', `SELECT count(*)::int FROM inform.own_words_passages
  WHERE topic_id = $1 AND season_id = $2 AND politician_id = ANY($3::uuid[])`, [tid, sid, ids]);
await q('review', `SELECT batch_id, status, count(*)::int FROM inform.stance_research_review
  WHERE topic_key = $1 AND season_id = $2 AND politician_id = ANY($3::uuid[]) ${batch ? 'AND batch_id = $4' : ''}
  GROUP BY 1, 2 ORDER BY 1, 2`, batch ? [topic, sid, ids, batch] : [topic, sid, ids]);
await pool.end();

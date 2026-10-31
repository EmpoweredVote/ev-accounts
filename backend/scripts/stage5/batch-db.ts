/** Shared lookups for the Stage 5 batch tools: the topic id and the draft season, never hard-coded. */
import { pool } from '../../src/lib/db.js';
import { resolveSeasonTarget } from '../lib/seasonTarget.js';

export async function topicId(topicKey: string): Promise<string> {
  const { rows } = await pool.query<{ id: string }>('SELECT id FROM inform.compass_topics WHERE topic_key = $1', [topicKey]);
  if (rows.length !== 1) throw new Error(`topic "${topicKey}" not found in inform.compass_topics`);
  return rows[0].id;
}

export async function draftSeasonId(): Promise<string> {
  const season = await resolveSeasonTarget('draft', (sql, params) => pool.query(sql, params as unknown[]));
  return season.id;
}

/** --name value from argv, or the fallback; exits 2 with the usage line when required and missing. */
export function flag(name: string, usage: string, fallback?: string): string {
  const i = process.argv.indexOf(name);
  const v = i >= 0 ? process.argv[i + 1] : fallback;
  if (v === undefined) { console.error(`usage: ${usage}`); process.exit(2); }
  return v;
}

/**
 * s1-sources — for every blank row whose verifier report shows an answer voters see from an earlier season,
 * list that answer's cited sources (STAGE5 step 7.5).
 *
 *   npx tsx --env-file=.env scripts/stage5/s1-sources.ts --topic <key> <batch dir>
 *
 * Reads <batch>/publish-report.json (a verifier dry run) and <batch>/politicians.json (the bundle).
 * Writes <batch>/fallback/fallback-required.json. Read-only on the database.
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { pool } from '../../src/lib/db.js';
import { flag, topicId } from './batch-db.js';

const usage = 's1-sources.ts --topic <key> <batch dir>';
const topic = flag('--topic', usage);
const dir = process.argv.slice(2).filter((a, i, all) => !a.startsWith('--') && all[i - 1] !== '--topic')[0];
if (!dir) { console.error(`usage: ${usage}`); process.exit(2); }
const tid = await topicId(topic);
const rep = JSON.parse(readFileSync(`${dir}/publish-report.json`, 'utf8')) as any[];
const pols = JSON.parse(readFileSync(`${dir}/politicians.json`, 'utf8')) as any[];
const pid = Object.fromEntries(pols.map((p: any) => [p.full_name, p.politician_id]));
const out: Record<string, unknown> = {};
for (const r of rep.filter((x) => x.value === 0 && x.displayed_value)) {
  const q = await pool.query(
    `SELECT c.sources FROM inform.politician_context c JOIN inform.seasons s ON s.id = c.season_id
      WHERE c.politician_id = $1 AND c.topic_id = $2 AND s.number = $3`,
    [pid[r.full_name], tid, r.displayed_value.season]);
  const src = (q.rows[0]?.sources ?? []) as any[];
  const urls = src.map((s: any) => (typeof s === 'string' ? s : s.url ?? s.source_url)).filter(Boolean);
  out[r.full_name] = { politician_id: pid[r.full_name], season1_value: r.displayed_value.value, season: r.displayed_value.season, action: r.action, reasons: r.reasons, urls };
  console.log(r.full_name, r.displayed_value.value, r.action, urls.length, urls.join(' '));
}
mkdirSync(`${dir}/fallback`, { recursive: true });
writeFileSync(`${dir}/fallback/fallback-required.json`, JSON.stringify(out, null, 1));
await pool.end();

/**
 * list-discovered-sources.ts — the On the Record discovery rows for one person, approved/ingested first.
 * Read-only. A research run checks these before its own web search (research-stances STEP 0.5): an
 * approved row is a source a person has already judged worth using; an ingested row is also an On the
 * Record meeting (extract-otr.mjs --politician reads its transcript).
 *
 *   npx tsx scripts/list-discovered-sources.ts --politician <uuid> [--race <uuid> ...] [--json]
 *
 * Matches a row when the person is in matched_politician_ids, or when the row is linked to one of the
 * given races (a race-linked row may name the person only in its title). Rejected and auto_filtered rows
 * are listed last, for completeness — they are not sources.
 */
import 'dotenv/config';

const opts = (n: string) => process.argv.flatMap((a, i) => (a === n && process.argv[i + 1] ? [process.argv[i + 1]] : []));
const pid = opts('--politician')[0];
const races = opts('--race');
const JSON_OUT = process.argv.includes('--json');
if (!pid || !/^[0-9a-f-]{36}$/i.test(pid) || races.some((r) => !/^[0-9a-f-]{36}$/i.test(r))) {
  console.error('usage: list-discovered-sources.ts --politician <uuid> [--race <uuid> ...] [--json]');
  process.exit(2);
}
const { pool } = await import('../src/lib/db.js');
const { rows } = await pool.query(
  `SELECT d.status, d.route, d.event_kind_guess, d.original_vs_clip, d.published_at::date::text AS published,
          d.title, d.url, d.channel_name,
          ($1::uuid = ANY (d.matched_politician_ids)) AS names_person
     FROM essentials.discovered_sources d
    WHERE $1::uuid = ANY (d.matched_politician_ids) OR d.race_id = ANY ($2::uuid[])
    ORDER BY CASE d.status WHEN 'ingested' THEN 0 WHEN 'approved' THEN 1 WHEN 'pending' THEN 2
                           WHEN 'deferred' THEN 3 ELSE 4 END, d.published_at DESC NULLS LAST`,
  [pid, races]);
await pool.end();
if (JSON_OUT) { console.log(JSON.stringify(rows, null, 2)); process.exit(0); }
for (const r of rows) {
  console.log([r.status.padEnd(13), (r.route ?? '').padEnd(12), (r.event_kind_guess ?? '').padEnd(17), r.published ?? '          ',
    r.names_person ? 'person' : 'race  ', (r.title ?? '').slice(0, 80), r.url].join(' | '));
}
console.log(`${rows.length} row(s): ${rows.filter((r) => r.status === 'ingested' || r.status === 'approved').length} approved/ingested`);

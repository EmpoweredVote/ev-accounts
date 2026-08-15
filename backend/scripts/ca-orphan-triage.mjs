// Which of the 39 CA orphans are the 4 that grew past the 08-08 baseline of 35?
// The baseline records a COUNT, not a row list, so "which four are new" cannot be read off it. What can
// be tested is which orphans were touched by the passes that ran after it -- Berkeley (1738/1739) and
// San Diego (1740), both 2026-08-13, the window the gate went red in.
import 'dotenv/config';
import pg from 'pg';
import { readFileSync } from 'node:fs';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const SQL = `
WITH orph AS (
  SELECT pc.politician_id, pc.topic_id, pc.reasoning, pc.sources
  FROM inform.politician_context pc
  LEFT JOIN inform.politician_answers pa
    ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
  WHERE pa.politician_id IS NULL
    AND coalesce(cardinality(pc.sources), 0) > 0
    AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
    AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
), st AS (
  SELECT o.*, lower(coalesce(seat.state, seat.representing_state, cand.state,'')) AS state
  FROM orph o
  LEFT JOIN LATERAL (SELECT ofc.representing_state, d.state FROM essentials.office_current_holder och
     JOIN essentials.offices ofc ON ofc.id=och.office_id LEFT JOIN essentials.districts d ON d.id=ofc.district_id
     WHERE och.politician_id=o.politician_id ORDER BY ofc.title LIMIT 1) seat ON true
  LEFT JOIN LATERAL (SELECT lower(e.state::text) AS state FROM essentials.race_candidates rc
     JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
     WHERE rc.politician_id=o.politician_id AND rc.candidate_status='active'
     ORDER BY e.election_date DESC LIMIT 1) cand ON true
)
SELECT s.politician_id, s.topic_id, s.reasoning, s.sources,
       p.first_name || ' ' || p.last_name AS name,
       coalesce(t.short_title, t.title) AS topic,
       (SELECT string_agg(DISTINCT ofc.title, ' | ') FROM essentials.office_terms ot
          JOIN essentials.offices ofc ON ofc.id = ot.office_id
         WHERE ot.politician_id = s.politician_id) AS offices
  FROM st s
  JOIN essentials.politicians p ON p.id = s.politician_id
  JOIN inform.compass_topics t  ON t.id = s.topic_id
 WHERE s.state = 'ca'
 ORDER BY p.last_name, topic`;

const { rows } = await pool.query(SQL);
await pool.end();

const touched = new Map();
for (const f of [
  '2026-08-13-ca-berkeley-1738-rollback.json',
  '2026-08-13-ca-berkeley-1739-rollback.json',
  '2026-08-13-ca-sandiego-1740-rollback.json',
]) {
  const j = JSON.parse(readFileSync(`data/stance-retirement/${f}`, 'utf8'));
  for (const r of j.rows ?? []) {
    const pid = r.politician_id ?? r.pid;
    const tid = r.topic_id ?? r.tid;
    if (pid && tid) touched.set(`${pid}|${tid}`, { file: f, ...r });
  }
}

const fromAug13 = rows.filter((r) => touched.has(`${r.politician_id}|${r.topic_id}`));
const older = rows.filter((r) => !touched.has(`${r.politician_id}|${r.topic_id}`));

console.log(`CA orphans: ${rows.length}  (baseline 35, so 4 are new)`);
console.log(`  touched by the 08-13 Berkeley/San Diego passes: ${fromAug13.length}`);
console.log(`  not touched by them: ${older.length}\n`);
for (const r of fromAug13) {
  console.log(`08-13  ${r.name} — ${r.topic}  [${r.offices ?? 'no office'}]`);
  console.log(`       ${r.reasoning.slice(0, 200)}`);
  console.log(`       sources: ${(r.sources ?? []).join(' ')}\n`);
}

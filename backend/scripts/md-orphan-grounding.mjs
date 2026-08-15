// Match every MD ORPHAN_CONTEXT row to the migration that blanked it, so each rewrite can be grounded
// in an adjudicated finding instead of a fresh guess.
//
// The blanks in 1731/1734/1736 were NOT "we could not be bothered" -- 1736's header records that all
// ~2,765 candidate bills behind those rows were read to the end of every list. That is what earns the
// right to write "researched, nothing scorable found" into these rows: the looking already happened and
// is on the record. A row this script CANNOT match is a row nobody has shown was read, and it must be
// left alone rather than given a blank it did not earn.
import 'dotenv/config';
import pg from 'pg';
import { readFileSync, writeFileSync } from 'node:fs';

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
       coalesce(t.short_title, t.title) AS topic
  FROM st s
  JOIN essentials.politicians p ON p.id = s.politician_id
  JOIN inform.compass_topics t  ON t.id = s.topic_id
 WHERE s.state = 'md'
 ORDER BY topic, p.last_name`;

const { rows: orphans } = await pool.query(SQL);
await pool.end();

// Index every blanked row from the three MD passes by politician+topic.
const blanked = new Map();
// 1732 must be in this list. Leaving it out stranded Jim Rosapepe / Voting Rights as "nobody has shown
// this was read" when in fact 1732 read it and recorded a reason -- the absence was in my index, not in
// the record. Exactly the failure this workstream keeps naming: a tool's gap looks identical to a
// politician having no record.
for (const mig of ['1731', '1732', '1734', '1736']) {
  const j = JSON.parse(readFileSync(`data/stance-retirement/2026-08-12-md-chairs-${mig}-rollback.json`, 'utf8'));
  for (const b of j.blanked ?? []) {
    blanked.set(`${b.politician_id}|${b.topic_id}`, { mig, ...b });
  }
}

const matched = [];
const unmatched = [];
for (const o of orphans) {
  const b = blanked.get(`${o.politician_id}|${o.topic_id}`);
  if (b) matched.push({ ...o, mig: b.mig, candidates_read: b.candidates_read, why: b.why ?? null });
  else unmatched.push(o);
}

// A grounded blank needs BOTH a record that the reading happened and a stated reason it failed.
// candidates_read alone says how hard someone looked, not what they concluded.
const noWhy = matched.filter((m) => !m.why);

console.log(`MD orphans: ${orphans.length}`);
console.log(`  matched to a 1731/1734/1736 blank: ${matched.length}`);
console.log(`    of those, missing a per-row "why": ${noWhy.length}`);
console.log(`  NOT matched (nobody has shown these were read): ${unmatched.length}`);
console.log('\nmatched by migration:');
for (const mig of ['1731', '1732', '1734', '1736']) {
  const n = matched.filter((m) => m.mig === mig).length;
  console.log(`  ${mig}: ${n}`);
}
console.log('\nrows with no per-row why, by topic:');
const byTopic = {};
for (const m of noWhy) byTopic[m.topic] = (byTopic[m.topic] ?? 0) + 1;
console.log(byTopic);
console.log('\nUNMATCHED rows:');
for (const u of unmatched) console.log(`  ${u.name} — ${u.topic}`);

writeFileSync(
  'data/stance-retirement/2026-08-14-md-orphan-grounding.json',
  JSON.stringify({ n_orphans: orphans.length, matched, unmatched }, null, 1),
);
console.log('\nwrote data/stance-retirement/2026-08-14-md-orphan-grounding.json');

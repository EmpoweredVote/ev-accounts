// Can the 119 deleted judicial rows be relocated to judicial-criminal-justice / public-safety-approach?
//
// Answering that needs three facts per row, none of which is "the evidence looks good":
//   1. Does the politician ALREADY have an answer on the destination topic? Then there is nothing to
//      relocate -- the topic is seated and re-parenting would collide with a live published chair.
//   2. Do they already have a CONTEXT row there? Overwriting it would destroy someone else's research.
//   3. What office do they hold? public-safety-approach asks "How should YOUR COMMUNITY fund and
//      operate public safety services?" -- a local budget question. A US Senator has no community
//      police budget, which is the same category error the judicial ladders had, wearing a friendlier
//      topic name.
import 'dotenv/config';
import pg from 'pg';
import { readFileSync, writeFileSync } from 'node:fs';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const cap = JSON.parse(
  readFileSync('data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json', 'utf8'),
);

const DEST = {
  'judicial-criminal-justice': '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'public-safety-approach': 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
};

const pids = [...new Set(cap.rows.map((r) => r.politician_id))];

const { rows: state } = await pool.query(
  `SELECT p.id,
          p.first_name || ' ' || p.last_name AS name,
          (SELECT string_agg(DISTINCT o.title, ' | ') FROM essentials.office_terms ot
             JOIN essentials.offices o ON o.id = ot.office_id
            WHERE ot.politician_id = p.id) AS offices,
          EXISTS (SELECT 1 FROM inform.politician_answers a
                   WHERE a.politician_id = p.id AND a.topic_id = $2) AS has_cj_answer,
          EXISTS (SELECT 1 FROM inform.politician_context c
                   WHERE c.politician_id = p.id AND c.topic_id = $2) AS has_cj_context,
          EXISTS (SELECT 1 FROM inform.politician_answers a
                   WHERE a.politician_id = p.id AND a.topic_id = $3) AS has_ps_answer,
          EXISTS (SELECT 1 FROM inform.politician_context c
                   WHERE c.politician_id = p.id AND c.topic_id = $3) AS has_ps_context
     FROM essentials.politicians p
    WHERE p.id = ANY($1::uuid[])`,
  [pids, DEST['judicial-criminal-justice'], DEST['public-safety-approach']],
);
await pool.end();

const byId = new Map(state.map((s) => [s.id, s]));

/** Federal or state office => "your community" does not name anything they control. */
const isLocal = (offices) => {
  const o = (offices ?? '').toLowerCase();
  if (!o) return null;
  if (/u\.s\.|senate|representative|congress/.test(o)) return false;
  if (/^senator|^delegate|assembly|state /.test(o)) return false;
  return /council|mayor|supervisor|commissioner|alderman|board/.test(o) ? true : null;
};

const rows = cap.rows.map((r) => {
  const s = byId.get(r.politician_id) ?? {};
  return {
    name: r.name,
    source_topic: r.topic_key,
    offices: s.offices ?? null,
    local: isLocal(s.offices),
    dest_cj_taken: s.has_cj_answer || s.has_cj_context,
    dest_ps_taken: s.has_ps_answer || s.has_ps_context,
  };
});

const tally = (pred) => rows.filter(pred).length;
console.log(`captured rows: ${rows.length}  politicians: ${pids.length}\n`);

for (const src of Object.keys(cap.by_topic)) {
  const g = rows.filter((r) => r.source_topic === src);
  console.log(`${src}  (${g.length} rows)`);
  console.log(`   destination criminal-justice already has an answer or context: ${g.filter((r) => r.dest_cj_taken).length}`);
  console.log(`   destination public-safety already has an answer or context:    ${g.filter((r) => r.dest_ps_taken).length}`);
  const loc = { local: 0, nonlocal: 0, unknown: 0 };
  for (const r of g) loc[r.local === true ? 'local' : r.local === false ? 'nonlocal' : 'unknown']++;
  console.log(`   office level — local ${loc.local} · federal/state ${loc.nonlocal} · unclear ${loc.unknown}\n`);
}

console.log('OVERALL');
console.log(`  rows whose criminal-justice slot is free: ${tally((r) => !r.dest_cj_taken)}`);
console.log(`  rows whose public-safety slot is free:    ${tally((r) => !r.dest_ps_taken)}`);
console.log(`  rows held by a federal or state officeholder: ${tally((r) => r.local === false)}`);

writeFileSync('data/stance-retirement/2026-08-14-judicial-relocation-survey.json', JSON.stringify(rows, null, 1));
console.log('\nwrote data/stance-retirement/2026-08-14-judicial-relocation-survey.json');

// Freeze the season 1 state and local compass ladders for the NC stance campaign.
//
// Every research agent in the campaign must score against identical ladder text, so the two
// scale files are generated from prod rather than transcribed. Re-run this if the season 2
// revision lands mid-campaign -- do not hand-patch the output.
//
//   cd backend && node scripts/gen-nc-campaign-scales.mjs
//
// Plan: .planning/workstreams/nc-stance-campaign/PLAN.md (Task 2)
import 'dotenv/config';
import { mkdirSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

const OUT_DIR = 'data/stance-research/nc-campaign';
const SCOPES = { state: { file: 'scale-state.txt', expect: 28 }, local: { file: 'scale-local.txt', expect: 22 } };

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// role_scope drives the topic set: a state member and a local officeholder answer different
// ladders, and an agent handed the wrong scale invents topic_keys that do not exist for its role.
const { rows } = await pool.query(
  `SELECT tr.role_scope, t.topic_key, t.id AS topic_id, t.question_text, s.value, s.text
     FROM inform.compass_topic_roles tr
     JOIN inform.compass_topics t ON t.id = tr.topic_id AND t.is_live = true
     JOIN inform.compass_stances s ON s.topic_id = t.id
    WHERE tr.role_scope = ANY($1::text[])
    ORDER BY tr.role_scope, t.topic_key, s.value`,
  [Object.keys(SCOPES)]
);

mkdirSync(OUT_DIR, { recursive: true });

for (const [scope, { file, expect }] of Object.entries(SCOPES)) {
  const topics = new Map();
  for (const r of rows.filter((r) => r.role_scope === scope)) {
    if (!topics.has(r.topic_key)) topics.set(r.topic_key, { id: r.topic_id, question: r.question_text, rungs: [] });
    topics.get(r.topic_key).rungs.push(r);
  }

  const blocks = [...topics].map(([key, t]) => {
    // A missing rung is a silent defect -- the chair the evidence names would simply be absent
    // from the ladder the agent reads, and it would pin the nearest one instead.
    if (t.rungs.length !== 5) throw new Error(`${scope}/${key}: ${t.rungs.length} rungs, expected 5`);
    const lines = t.rungs.map((r) => `  ${r.value} = "${r.text}"`).join('\n');
    return `${key} (id: ${t.id})\nQuestion: "${t.question}"\n${lines}`;
  });

  if (blocks.length !== expect) throw new Error(`${scope}: ${blocks.length} topics, expected ${expect}`);

  const header = [
    `NC STANCE CAMPAIGN -- ${scope.toUpperCase()} COMPASS LADDER (${blocks.length} topics)`,
    `Pulled verbatim from inform.compass_topics + inform.compass_stances (is_live) on ${new Date().toISOString().slice(0, 10)}`,
    `by backend/scripts/gen-nc-campaign-scales.mjs. Season 1 ladders, pre-ADR-0004 revision.`,
    ``,
    `The value you assign MUST be the chair whose text the evidence names. Never average, and never`,
    `use party or district geography as a proxy. If two adjacent chairs both fit, SKIP the topic.`,
    `Chair polarity is NOT uniform across this list -- read each ladder, do not assume 1 = most.`,
    '='.repeat(96),
    ``,
  ].join('\n');

  writeFileSync(`${OUT_DIR}/${file}`, header + blocks.join('\n\n') + '\n');
  console.log(`${file}: ${blocks.length} topics, ${blocks.length * 5} stance texts`);
}

await pool.end();

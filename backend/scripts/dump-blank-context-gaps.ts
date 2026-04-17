import { writeFileSync } from 'node:fs';
import { pool } from '../src/lib/db.js';

const { rows: gapRows } = await pool.query(`
  SELECT pa.politician_id, p.full_name,
         COALESCE(o.title, '') AS office_title,
         COALESCE(c.name, '')  AS chamber_name,
         t.id AS topic_id, t.topic_key, t.title AS topic_title, t.question_text AS topic_question,
         pa.value::float AS current_value
  FROM inform.politician_answers pa
  JOIN inform.compass_topics t ON t.id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN essentials.offices o ON o.politician_id = p.id
  LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE t.is_live = true
    AND (pc.reasoning IS NULL OR btrim(pc.reasoning) = '')
  ORDER BY p.full_name, t.topic_key
`);

const topicIds = [...new Set(gapRows.map(r => r.topic_id))];
const { rows: stanceRows } = await pool.query(
  `SELECT topic_id, value::int AS value, text FROM inform.compass_stances WHERE topic_id = ANY($1::uuid[]) ORDER BY topic_id, value`,
  [topicIds]
);
const stancesByTopic = new Map<string, { value: number; text: string }[]>();
for (const s of stanceRows) {
  if (!stancesByTopic.has(s.topic_id)) stancesByTopic.set(s.topic_id, []);
  stancesByTopic.get(s.topic_id)!.push({ value: s.value, text: s.text });
}

type Gap = {
  topic_id: string;
  topic_key: string;
  topic_title: string;
  topic_question: string;
  stances: { value: number; text: string }[];
  current_value: number;
};
type Group = {
  politician_id: string;
  full_name: string;
  office_title: string;
  chamber_name: string;
  gaps: Gap[];
};

const byPolitician = new Map<string, Group>();
for (const r of gapRows) {
  if (!byPolitician.has(r.politician_id)) {
    byPolitician.set(r.politician_id, {
      politician_id: r.politician_id,
      full_name: r.full_name,
      office_title: r.office_title,
      chamber_name: r.chamber_name,
      gaps: [],
    });
  }
  byPolitician.get(r.politician_id)!.gaps.push({
    topic_id: r.topic_id,
    topic_key: r.topic_key,
    topic_title: r.topic_title,
    topic_question: r.topic_question,
    stances: stancesByTopic.get(r.topic_id) ?? [],
    current_value: r.current_value,
  });
}

const groups = [...byPolitician.values()].sort((a, b) => a.full_name.localeCompare(b.full_name));
const out = {
  generated_at: new Date().toISOString(),
  politicians: groups.length,
  total_gaps: gapRows.length,
  groups,
};

const outPath = '/tmp/blank-context-gaps.json';
writeFileSync(outPath, JSON.stringify(out, null, 2));
console.log(`Wrote ${outPath}`);
console.log(`  politicians: ${groups.length}`);
console.log(`  total gaps:  ${gapRows.length}`);
for (const g of groups) console.log(`  ${g.full_name}: ${g.gaps.length} gaps`);

await pool.end();

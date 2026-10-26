#!/usr/bin/env node
// Dump every Massachusetts bill page cited by a SERVING, VOTER-FACING stance row, together with
// the prose that cites it. Input for the title-vs-prose detector this citation pass owes.
import 'dotenv/config';
import pg from 'pg';
import { writeFileSync } from 'node:fs';

const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const S2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const S3 = '7b3a066c-815d-43b2-a6a0-6a3029778075';

const SQL = `
WITH serving AS (
  SELECT DISTINCT ON (pa.politician_id, pa.topic_id)
         pa.politician_id, pa.topic_id, pa.season_id, pa.value,
         pc.reasoning, pc.sources, p.full_name
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE p.is_active AND pa.season_id <> $2::uuid
   ORDER BY pa.politician_id, pa.topic_id, (pa.season_id = $1::uuid) DESC
)
SELECT s.politician_id, s.topic_id, s.full_name, s.value,
       (s.season_id = $1::uuid) AS is_s2,
       t.topic_key, s.reasoning, u AS url
  FROM serving s
  JOIN inform.compass_topics t ON t.id = s.topic_id,
  LATERAL unnest(s.sources) u
 WHERE s.value <> 0
   AND u ~ 'malegislature\\.gov/Bills/[0-9]+/[HS][0-9]+'
`;

const { rows } = await pool.query(SQL, [S2, S3]);
await pool.end();

const out = rows.map(r => ({
  politician_id: r.politician_id,
  topic_id: r.topic_id,
  full_name: r.full_name,
  topic_key: r.topic_key,
  value: Number(r.value),
  is_s2: r.is_s2,
  url: r.url,
  bill_path: (r.url.match(/(\/Bills\/[0-9]+\/[HS][0-9]+)/) || [])[1],
  reasoning: r.reasoning,
}));

const dir = process.argv[2];
writeFileSync(`${dir}/ma-citations.json`, JSON.stringify(out, null, 1));
const bills = [...new Set(out.map(o => o.bill_path))].sort();
writeFileSync(`${dir}/ma-bill-paths.txt`, bills.join('\n') + '\n');
console.log(`citations=${out.length} rows=${new Set(out.map(o => o.politician_id + o.topic_id)).size} distinct_bills=${bills.length}`);

import 'dotenv/config';
import { writeFileSync } from 'fs';
import { Pool } from 'pg';
const KEYS = ['abortion','healthcare','housing','rent-regulation','residential-zoning','taxes',
 'climate-change','fossil-fuels','local-environment','civil-rights','trans-athletes',
 'school-vouchers','childcare','homelessness','homelessness-response','public-safety-approach',
 'jail-capacity','local-immigration','transportation-priorities','growth-and-development',
 'economic-development','voting-rights','redistricting','campaign-finance','data-centers'];
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl:{rejectUnauthorized:false}});
const { rows } = await pool.query(
 `SELECT t.topic_key, t.title, t.question_text, s.value, s.text
    FROM inform.compass_topics t JOIN inform.compass_stances s ON s.topic_id=t.id
   WHERE t.is_live AND t.is_active AND t.topic_key = ANY($1::text[])
   ORDER BY array_position($1::text[], t.topic_key), s.value`, [KEYS]);
let out = `OREGON STATE-LEG TOPIC SCALES — Bend ballot cohort (HD 53, HD 54, SD 27)
Pulled verbatim from inform.compass_topics + inform.compass_stances (is_live AND is_active).
Generated ${new Date().toISOString().slice(0,10)} by scripts/gen-topic-scale.mjs.

The value you assign MUST be the chair whose text the evidence supports. Never average, never use
party or district geography as a proxy. If two adjacent chairs both fit, SKIP the topic.
${'='.repeat(80)}\n`;
let cur = '';
for (const r of rows) {
  if (r.topic_key !== cur) {
    cur = r.topic_key;
    out += `\n${r.topic_key} — "${r.question_text}"  [${r.title}]\n`;
  }
  out += `${r.value}  ${r.text}\n`;
}
writeFileSync('data/stance-research/or-bend-stateleg/_TOPIC_SCALE_STATELEG.txt', out);
console.log(`wrote ${rows.length} stance texts across ${new Set(rows.map(r=>r.topic_key)).size} topics`);
await pool.end();

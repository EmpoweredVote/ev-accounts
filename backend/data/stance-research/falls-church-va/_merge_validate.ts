import 'dotenv/config';
import { parse } from 'csv-parse/sync';
import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

const DIR = 'data/stance-research/falls-church-va';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

function repairQuad(s: string) { return s.replace(/"""""+/g, '"""').replace(/""""/g, '"""'); }

(async () => {
  // live topic keys
  const tk = await pool.query(`SELECT topic_key, id FROM inform.compass_topics WHERE is_live=true`);
  const topicId = new Map<string,string>(tk.rows.map((r:any)=>[r.topic_key, r.id]));

  const files = readdirSync(DIR).filter(f => f.endsWith('.csv'));
  const merged: any[] = [];
  const problems: string[] = [];
  for (const f of files) {
    let raw = readFileSync(`${DIR}/${f}`, 'utf8');
    raw = repairQuad(raw);
    let recs: any[];
    try {
      recs = parse(raw, { columns: true, skip_empty_lines: true, relax_quotes: true, relax_column_count: true, trim: true });
    } catch (e:any) { problems.push(`PARSE FAIL ${f}: ${e.message}`); continue; }
    for (const r of recs) {
      if (!r.topic_key) continue;
      const ext = parseInt(r.external_id);
      const val = parseInt(r.value);
      if (!topicId.has(r.topic_key)) { problems.push(`${f}: unknown topic_key '${r.topic_key}' (${r.full_name})`); continue; }
      if (!(val>=1 && val<=5)) { problems.push(`${f}: bad value '${r.value}' (${r.full_name}/${r.topic_key})`); continue; }
      if (!(ext<0)) { problems.push(`${f}: bad external_id '${r.external_id}' (${r.full_name})`); continue; }
      merged.push({ ...r, external_id: ext, value: val, _file: f });
    }
  }

  // dedupe (external_id, topic_key)
  const seen = new Map<string,any>();
  for (const m of merged) {
    const key = `${m.external_id}|${m.topic_key}`;
    if (seen.has(key)) problems.push(`DUP ${key} (${m.full_name}) — keeping first`);
    else seen.set(key, m);
  }
  const rows = [...seen.values()];

  // resolve external_id -> politician uuid (only our FC ids)
  const exts = [...new Set(rows.map(r=>r.external_id))];
  const pr = await pool.query(`SELECT external_id, id, full_name FROM essentials.politicians WHERE external_id = ANY($1::bigint[])`, [exts]);
  const polId = new Map<number,string>(pr.rows.map((r:any)=>[parseInt(r.external_id), r.id]));
  const polName = new Map<number,string>(pr.rows.map((r:any)=>[parseInt(r.external_id), r.full_name]));
  for (const e of exts) if (!polId.has(e)) problems.push(`external_id ${e} not found in politicians`);

  // per-politician + per-topic-key tallies
  const byPol: Record<string, number> = {};
  const byTopic: Record<string, number> = {};
  for (const r of rows) {
    const n = polName.get(r.external_id) || String(r.external_id);
    byPol[n] = (byPol[n]||0)+1;
    byTopic[r.topic_key] = (byTopic[r.topic_key]||0)+1;
  }

  console.log('=== VALIDATION ===');
  console.log('files:', files.join(', '));
  console.log('total valid stance rows:', rows.length);
  console.log('distinct politicians with >=1 stance:', Object.keys(byPol).length);
  console.log('\n=== rows per politician ===');
  for (const [n,c] of Object.entries(byPol).sort((a,b)=>b[1]-a[1])) console.log(`  ${c}  ${n}`);
  console.log('\n=== rows per topic ===');
  for (const [t,c] of Object.entries(byTopic).sort((a,b)=>b[1]-a[1])) console.log(`  ${c}  ${t}`);
  console.log('\n=== PROBLEMS ===');
  console.log(problems.length ? problems.join('\n') : '(none)');

  // build resolved push payload
  const payload = rows.map(r => ({
    politician_id: polId.get(r.external_id),
    external_id: r.external_id,
    full_name: polName.get(r.external_id),
    topic_id: topicId.get(r.topic_key),
    topic_key: r.topic_key,
    value: r.value,
    reasoning: r.reasoning || '',
    sources: [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean),
    quote_text: r.quote_text || '',
    quote_deidentified: r.quote_deidentified || '',
  })).filter(p => p.politician_id);

  // sources sanity: every row must have >=1 source (evidence-only)
  const noSrc = payload.filter(p => p.sources.length === 0);
  if (noSrc.length) console.log(`\nWARNING: ${noSrc.length} rows have NO source URL:`, noSrc.map(p=>`${p.full_name}/${p.topic_key}`).join(', '));
  else console.log('\nAll rows have >=1 source URL ✓');

  writeFileSync(`${DIR}/_resolved.json`, JSON.stringify(payload, null, 2));
  console.log(`\nWrote _resolved.json (${payload.length} rows) for push.`);
  await pool.end();
})();

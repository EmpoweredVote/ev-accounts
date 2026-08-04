// Probe the https:// form of every scheme-less citation, so the repair is informed rather than blind.
//
// The defect being fixed is narrow: these sources are not URLs. 312 citations across 166 rows are stored
// as "votemiller.com" or "laist.com/news/.../la-mayor" with no scheme, so NOTHING that fetches a source
// can read them -- every reachability verdict ever recorded for those rows was made against an unfetchable
// string. Prepending the scheme is a formatting repair and asserts nothing about the page.
//
// ⚠ SO THIS SCRIPT DOES NOT DECIDE RETIREMENTS. It records what each repaired URL serves, so that (a) the
// migration can prepend the scheme, and (b) any repaired URL that turns out dead enters the ordinary
// reachability queue with its status recorded rather than being silently "fixed" into a broken citation.
// ⚠ Classify every non-200: 403 = bot block (renders fine for a voter), 202/429/503 = throttled,
// 404/410 = gone. Only "gone" is a citation defect, and even then it is a reading queue, not a delete list.
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { Pool } from 'pg';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  WITH cite AS (
    SELECT c.politician_id, c.topic_id, s AS url
      FROM inform.politician_context c
      JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
      CROSS JOIN LATERAL unnest(c.sources) AS s
     WHERE s NOT ILIKE 'http://%' AND s NOT ILIKE 'https://%'
  )
  SELECT url, count(*) AS citations, count(DISTINCT (politician_id, topic_id)) AS rows_citing
    FROM cite GROUP BY url ORDER BY citations DESC`);
await pool.end();

async function probe(raw) {
  const url = 'https://' + raw;
  try {
    const r = await fetch(url, { headers: { 'user-agent': UA }, redirect: 'follow', signal: AbortSignal.timeout(25000) });
    const body = r.status === 200 ? await r.text().catch(() => '') : '';
    return { url, status: r.status, bytes: body.length || null, final: r.url !== url ? r.url : null };
  } catch (e) {
    return { url, status: 0, error: e.message.slice(0, 70) };
  }
}

const out = [];
const LIMIT = 5;
let i = 0;
await Promise.all(Array.from({ length: LIMIT }, async () => {
  while (i < rows.length) {
    const r = rows[i++];
    const p = await probe(r.url);
    // A thin 200 is not an absent claim, and a large 404 body is still a 404 -- record both numbers.
    const cls = p.status === 200 ? (p.bytes && p.bytes > 1500 ? 'OK' : 'OK_THIN')
      : p.status === 403 ? 'BOT_BLOCKED'
      : [202, 429, 503].includes(p.status) ? 'THROTTLED'
      : [404, 410].includes(p.status) ? 'GONE'
      : p.status === 0 ? 'NO_RESPONSE' : `HTTP_${p.status}`;
    out.push({ raw: r.url, citations: Number(r.citations), rows: Number(r.rows_citing), shape: r.url.includes('/') ? 'HOST_PATH' : 'BARE_HOST', ...p, class: cls });
    console.log(`  ${cls.padEnd(12)} ${String(p.status).padStart(3)} ${String(p.bytes ?? '').padStart(7)}  ${r.url.slice(0, 92)}`);
    await sleep(600);
  }
}));

const tally = out.reduce((m, r) => { m[r.class] = (m[r.class] || 0) + 1; return m; }, {});
const citesBy = out.reduce((m, r) => { m[r.class] = (m[r.class] || 0) + r.citations; return m; }, {});
writeFileSync('data/stance-retirement/2026-08-04-schemeless-probe.json',
  JSON.stringify({ generated: new Date().toISOString().slice(0, 10), distinct: out.length,
    citations: out.reduce((n, r) => n + r.citations, 0), by_class: tally, citations_by_class: citesBy, urls: out }, null, 2));

console.log('\n=== by class (distinct strings / citations) ===');
for (const k of Object.keys(tally)) console.log(`  ${k}: ${tally[k]} / ${citesBy[k]}`);
console.log(`\nrepairable to a live URL: ${out.filter((r) => ['OK', 'OK_THIN', 'BOT_BLOCKED', 'THROTTLED'].includes(r.class)).reduce((n, r) => n + r.citations, 0)} citations`);
console.log(`repaired-but-dead (enter reachability queue): ${out.filter((r) => ['GONE', 'NO_RESPONSE'].includes(r.class)).reduce((n, r) => n + r.citations, 0)} citations`);

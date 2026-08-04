// Verify a re-research CSV before it becomes a migration:
//  1. it parses into exactly the expected 7 columns
//  2. value is a discrete integer 1-5 (never fractional — the CHECK permits 0.5 steps, so the guard
//     has to live outside the schema)
//  3. the politician resolves to exactly one essentials.politicians row, and the topic_key to one live
//     compass topic whose compass_topic_roles admit the officeholder's tier
//  4. every cited URL is fetched and every distinctive claim term in the reasoning appears in its RAW
//     HTML — the standard migration 1542 established after a row cited a CRS summary for a claim the
//     bill text did not carry
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';
import { crawlSite } from './lib/site-crawl.mjs';

const file = process.argv[2];
if (!file) {
  console.error('usage: node scripts/_tmp-verify-reresearch-csv.mjs <csv>');
  process.exit(1);
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQ = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQ) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') inQ = false;
      else field += c;
    } else if (c === '"') inQ = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); if (row.some((f) => f.trim())) rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  row.push(field);
  if (row.some((f) => f.trim())) rows.push(row);
  return rows;
}

const parsed = parseCsv(readFileSync(file, 'utf8'));
const header = parsed[0];
const EXPECT = ['full_name', 'topic_key', 'value', 'reasoning', 'source_url_1', 'source_url_2', 'source_url_3'];
if (header.join(',') !== EXPECT.join(',')) {
  console.error(`FAIL header: got ${header.join(',')}`);
  process.exit(1);
}
const rows = parsed.slice(1).map((r) => Object.fromEntries(EXPECT.map((k, i) => [k, (r[i] ?? '').trim()])));
console.log(`parsed ${rows.length} row(s), ${header.length} columns\n`);

// stopwords so "the/and/city" are not treated as distinctive claim terms
const STOP = new Set(('the a an and or of to in on at for with by from as is was were be been it its this that '
  + 'said says which who whom whose what when where while than then there their they them he she his her out into '
  + 'up down over under about after before more most half no not any all each city council plan would could should').split(' '));

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
let failures = 0;

for (const r of rows) {
  console.log('='.repeat(90));
  console.log(`${r.full_name} / ${r.topic_key} = ${r.value}`);

  const v = Number(r.value);
  if (!Number.isInteger(v) || v < 1 || v > 5) { console.log(`  🔴 FAIL value not a discrete 1-5: ${r.value}`); failures++; }

  const { rows: pol } = await pool.query(
    `SELECT p.id, p.full_name, g.name AS government, g.type AS gov_type, o.title
       FROM essentials.politicians p
       LEFT JOIN essentials.office_terms ot ON ot.politician_id = p.id
       LEFT JOIN essentials.offices o  ON o.id = ot.office_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
       LEFT JOIN essentials.governments g ON g.id = c.government_id
      WHERE lower(p.full_name) = lower($1)`,
    [r.full_name],
  );
  if (pol.length !== 1) { console.log(`  🔴 FAIL politician resolves to ${pol.length} rows`); failures++; }
  else console.log(`  politician ${pol[0].id}  ${pol[0].government} — ${pol[0].title}`);

  const { rows: topic } = await pool.query(
    `SELECT t.id, t.title, t.is_live, t.is_active,
            (SELECT array_agg(role_scope) FROM inform.compass_topic_roles WHERE topic_id = t.id) AS scopes
       FROM inform.compass_topics t WHERE t.topic_key = $1`,
    [r.topic_key],
  );
  if (topic.length !== 1) { console.log(`  🔴 FAIL topic_key resolves to ${topic.length} rows`); failures++; }
  else {
    const t = topic[0];
    console.log(`  topic ${t.id}  ${t.title}  live=${t.is_live} active=${t.is_active} tiers=${(t.scopes || []).join('+') || '(all)'}`);
    if (!t.is_live || !t.is_active) { console.log('  🔴 FAIL topic not live/active'); failures++; }
    const local = !t.scopes || t.scopes.includes('local');
    if (!local) { console.log('  🔴 FAIL topic excludes the local tier — would never display'); failures++; }
    const { rows: existing } = await pool.query(
      'SELECT value FROM inform.politician_answers WHERE politician_id = $1 AND topic_id = $2',
      [pol[0]?.id, t.id],
    );
    console.log(existing.length ? `  ⚠ row already exists at value ${existing[0].value} — this is an UPDATE, not an INSERT` : '  no existing answer — INSERT');
  }

  const urls = [r.source_url_1, r.source_url_2, r.source_url_3].filter(Boolean);
  if (!urls.length) { console.log('  🔴 FAIL no sources'); failures++; }

  const terms = [...new Set(r.reasoning.toLowerCase().replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/)
    .filter((w) => w.length > 4 && !STOP.has(w)))];

  // raw = tags-stripped HTML with only <script>/<style> removed, the same standard read-site.mjs uses:
  // a miss in an extracted body is a report about the extractor, a miss in raw is a real absence
  const rawOf = (html) => (html || '')
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;|&#160;/g, ' ')
    .replace(/&#8217;|&rsquo;/g, "'")
    .replace(/&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
    .replace(/\s+/g, ' ')
    .toLowerCase();

  const allRaw = [];
  for (const u of urls) {
    let res;
    try { res = await crawlSite(u, { maxPages: 1 }); } catch (e) { console.log(`  🔴 FAIL fetch ${u}: ${e.message}`); failures++; continue; }
    if (!res.ok) {
      // classify before reading anything as absence: 403 = bot block, 202/429/503 = throttled,
      // 404/410 = gone, thin body = paywall or JS shell. Only "gone" is a citation defect.
      console.log(`  🔴 FAIL unreadable ${u} — ${res.reason}${res.dead ? ' (DEAD)' : ' (UNREADABLE, not proof of absence)'}`);
      failures++;
      continue;
    }
    const raw = res.pages.map((p) => rawOf(p.html)).join(' ');
    allRaw.push(raw);
    const miss = terms.filter((t) => !raw.includes(t));
    console.log(`  ${miss.length ? '⚠' : '✅'} ${u}  raw=${raw.length}c  terms ${terms.length - miss.length}/${terms.length}`);
    if (miss.length) console.log(`     absent here: ${miss.join(', ')}`);
  }
  // a term is satisfied if ANY cited source carries it
  const union = allRaw.join(' ');
  const uncovered = terms.filter((t) => !union.includes(t));
  if (uncovered.length) { console.log(`  🔴 FAIL ${uncovered.length} claim term(s) on NO cited page: ${uncovered.join(', ')}`); failures++; }
  else console.log(`  ✅ all ${terms.length} distinctive claim terms carried by the cited pages`);
}

console.log('='.repeat(90));
console.log(failures ? `🔴 ${failures} failure(s)` : '✅ all checks passed');
await pool.end();
process.exit(failures ? 1 : 0);

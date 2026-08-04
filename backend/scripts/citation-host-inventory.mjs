// Citation-level inventory of every host cited by a live stance row.
//
// 🔴 WHY THIS EXISTS, AND WHY IT IS NOT THE EARLIER HOST SWEEP. Every previous sweep evaluated a ROW:
// the 2026-08-01 sweep required that *every* source on a row be a bare host, and the invented-domain
// sweep worked the FETCH_FAILED bucket. Both are blind to a dead host that shares a row with a
// co-source that merely looks resolvable. That blind spot hid `newtonobserver.com` -- 48 rows across 18
// politicians, 0 of them sole-sourced, 45 paired with a composed newtonma.gov path (migration 1548).
// So this inventory is keyed on the CITATION, and it reports, per host, how much of the corpus would
// lose its evidence if that host turned out not to exist.
//
// 🔴 IT PROPOSES NOTHING AND WRITES NOTHING TO THE DATABASE. It emits a ranked READING/PROBE QUEUE.
// Nine-plus times on this workstream a detector's first cut was too broad; nothing here is a verdict.
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows } = await pool.query(`
  WITH cite AS (
    SELECT c.politician_id, c.topic_id, s AS url,
           lower(regexp_replace(s, '^https?://(www\\.)?([^/:]+).*$', '\\2')) AS host,
           (s ~ '^https?://[^/]+/.+') AS has_path,
           array_length(c.sources, 1) AS n_src
      FROM inform.politician_context c
      JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
      CROSS JOIN LATERAL unnest(c.sources) AS s
  )
  SELECT host,
         count(*)                                   AS citations,
         count(DISTINCT (politician_id, topic_id))   AS rows_touched,
         count(DISTINCT politician_id)               AS politicians,
         count(*) FILTER (WHERE n_src = 1)           AS on_sole_sourced_rows,
         count(*) FILTER (WHERE has_path)            AS with_path,
         min(url)                                    AS example
    FROM cite
   GROUP BY host
   ORDER BY citations DESC`);

// Governments each host's politicians belong to -- a host cited ONLY within one city is the shape an
// invented local outlet takes; a national aggregator spreads across many.
const { rows: geo } = await pool.query(`
  WITH cite AS (
    SELECT lower(regexp_replace(s, '^https?://(www\\.)?([^/:]+).*$', '\\2')) AS host, c.politician_id
      FROM inform.politician_context c
      JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
      CROSS JOIN LATERAL unnest(c.sources) AS s
  )
  SELECT cite.host, count(DISTINCT g.name) AS governments, min(g.name) AS example_government
    FROM cite
    LEFT JOIN essentials.office_terms ot ON ot.politician_id = cite.politician_id
    LEFT JOIN essentials.offices o  ON o.id = ot.office_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
   GROUP BY cite.host`);
const geoMap = Object.fromEntries(geo.map((g) => [g.host, g]));

// The invented-outlet signature: a place-word plus a newspaper-word, cited inside a single government.
// Derived from the six known cases (newtonobserver, medfordmirror, newtonvillearea, alhambraource,
// walthamtribunenews, walthamatch) -- NOT a verdict, a probe order.
const PRESS = /(observer|mirror|tribune|patch|gazette|herald|times|post|news|journal|beacon|press|record|chronicle|dispatch|sentinel|examiner|ledger|bulletin|reporter|monitor|courier|star|voice|advocate|review|leader|inquirer|telegram|globe|banner|citizen|independent|register|item|eagle|enterprise|standard|daily|local|wire|source|ource|atch)/;
const KNOWN_REAL = new Set(['ballotpedia.org', 'web.archive.org', 'congress.gov', 'govinfo.gov', 'senate.gov',
  'house.gov', 'wikipedia.org', 'vote411.org', 'fec.gov', 'opensecrets.org', 'followthemoney.org',
  'nytimes.com', 'washingtonpost.com', 'wsj.com', 'apnews.com', 'reuters.com', 'npr.org', 'politico.com',
  'bostonglobe.com', 'latimes.com', 'sfchronicle.com', 'figcitynews.com', 'newtonbeacon.org',
  'beverlypress.com', 'masslive.com', 'wbur.org', 'cbsnews.com', 'nbcnews.com', 'abcnews.go.com']);

const scored = rows.map((r) => {
  const g = geoMap[r.host] || {};
  const govs = Number(g.governments || 0);
  const looksPress = PRESS.test(r.host);
  const singleCity = govs === 1;
  const gov = !!/\.gov$/.test(r.host);
  const known = KNOWN_REAL.has(r.host) || [...KNOWN_REAL].some((k) => r.host.endsWith('.' + k) || r.host === k);
  // probe priority: unverified press-shaped host confined to one government, weighted by exposure
  let priority = 0;
  if (!known) {
    if (looksPress && singleCity) priority = 3;
    else if (looksPress) priority = 2;
    else if (!gov && singleCity) priority = 1;
  }
  return {
    host: r.host,
    citations: Number(r.citations),
    rows_touched: Number(r.rows_touched),
    politicians: Number(r.politicians),
    on_sole_sourced_rows: Number(r.on_sole_sourced_rows),
    without_path: Number(r.citations) - Number(r.with_path),
    governments: govs,
    example_government: g.example_government || null,
    example: r.example,
    priority,
    flags: [known ? 'known-real' : null, looksPress ? 'press-shaped' : null, singleCity ? 'single-government' : null, gov ? 'dot-gov' : null].filter(Boolean),
  };
});

const queue = scored.filter((s) => s.priority > 0).sort((a, b) => b.priority - a.priority || b.rows_touched - a.rows_touched);

writeFileSync('data/stance-retirement/2026-08-04-citation-host-inventory.json',
  JSON.stringify({ generated: new Date().toISOString().slice(0, 10), total_hosts: scored.length, hosts: scored }, null, 2));

let md = `# Citation-level host inventory — probe queue\n\n`;
md += `Generated ${new Date().toISOString().slice(0, 10)} by \`scripts/citation-host-inventory.mjs\`.\n\n`;
md += `**${scored.length} distinct hosts** across ${scored.reduce((n, s) => n + s.citations, 0)} citations on live stance rows.\n\n`;
md += `🔴 This is a **probe queue, not a delete list.** Keyed on the CITATION, because every earlier sweep\n`;
md += `was keyed on the ROW and was therefore blind to a dead host sharing a row with a co-source that\n`;
md += `merely looked resolvable — the blind spot that hid \`newtonobserver.com\` (48 rows, 18 politicians,\n`;
md += `0 sole-sourced, migration 1548).\n\n`;
md += `\`rows_touched\` is the exposure: how many live stance rows cite this host at all.\n\n`;
md += `## Priority 3 — press-shaped host confined to a single government (the six known invented outlets' shape)\n\n`;
md += `| host | citations | rows | politicians | sole-sourced cites | government |\n|---|---|---|---|---|---|\n`;
for (const s of queue.filter((q) => q.priority === 3)) {
  md += `| \`${s.host}\` | ${s.citations} | ${s.rows_touched} | ${s.politicians} | ${s.on_sole_sourced_rows} | ${s.example_government ?? '—'} |\n`;
}
md += `\n## Priority 2 — press-shaped, spread across governments\n\n`;
md += `| host | citations | rows | politicians | governments |\n|---|---|---|---|---|\n`;
for (const s of queue.filter((q) => q.priority === 2)) {
  md += `| \`${s.host}\` | ${s.citations} | ${s.rows_touched} | ${s.politicians} | ${s.governments} |\n`;
}
md += `\n## Priority 1 — non-.gov host confined to one government\n\n`;
md += `| host | citations | rows | politicians | government |\n|---|---|---|---|---|\n`;
for (const s of queue.filter((q) => q.priority === 1)) {
  md += `| \`${s.host}\` | ${s.citations} | ${s.rows_touched} | ${s.politicians} | ${s.example_government ?? '—'} |\n`;
}
writeFileSync('data/stance-retirement/2026-08-04-citation-host-inventory.md', md);

console.log(`hosts ${scored.length} · citations ${scored.reduce((n, s) => n + s.citations, 0)}`);
console.log(`probe queue: P3 ${queue.filter((q) => q.priority === 3).length} · P2 ${queue.filter((q) => q.priority === 2).length} · P1 ${queue.filter((q) => q.priority === 1).length}`);
console.log('\ntop 15 by exposure within the queue:');
for (const s of queue.slice(0, 15)) console.log(`  P${s.priority}  ${String(s.rows_touched).padStart(4)} rows  ${String(s.politicians).padStart(3)} pols  ${s.host}  [${s.flags.join(',')}]`);
await pool.end();

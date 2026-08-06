#!/usr/bin/env node
/**
 * Build the reading queue for the NAV_ONLY re-classification.
 *
 * WHY. The remedy split turns on one question per row: once the fabricated citations are removed, does
 * anything REAL still support this stance? My first pass answered it structurally — a survivor counted as
 * a nav page if its path had <=1 segment — and that is a floor, not the rule. The 2026-08-04 operator
 * ruling is "does this page state a position attributable to this person", which cannot be read off a
 * URL. Live proof in both directions, from this very corpus:
 *   · lynnma.gov/city-council/minutes (19 rows) — depth 2, counted as a real co-source, is an INDEX.
 *   · wikipedia.org/wiki/Ed_Markey (15 rows) — depth 2, and genuinely states positions.
 * So the survivors have to be fetched and read.
 *
 * ⚠ SCOPE. Only citations that will actually be REMOVED count as losses. The 4 mechanical re-points and
 * the 1 withdrawn finding are excluded: those rows keep a working citation after repair, so they were
 * never retirement candidates and must not inflate the queue.
 *
 * Writes navonly-workset.json: one entry per distinct surviving URL with the rows that depend on it.
 */
import 'dotenv/config';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'data', 'stance-retirement');

// Excluded from "will be removed" — repaired, not deleted. See the scope note above.
const REPOINT = new Set([
  'https://kamlager-dove.house.gov/issues/health-care',
  'https://moulton.house.gov/issues/national-security',
  'https://moulton.house.gov/issues/jobs-economy',
  'https://pressley.house.gov/issues/criminal-justice',
]);
const WITHDRAWN = new Set(['https://lynch.house.gov/issues/technology']);

const fabricated = new Set();
for (const f of readdirSync(DIR).filter((x) => /^fabricated-article-sweep-.*\.json$/.test(x))) {
  for (const r of JSON.parse(readFileSync(path.join(DIR, f), 'utf8')).findings ?? []) {
    if (r.verdict === 'FABRICATED' && !REPOINT.has(r.url) && !WITHDRAWN.has(r.url)) fabricated.add(r.url);
  }
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT pc.politician_id, pc.topic_id, pc.sources, pc.reasoning,
         p.full_name, p.last_name, g.name AS government
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id
    LEFT JOIN LATERAL (
      SELECT o2.chamber_id FROM essentials.office_current_holder och
        JOIN essentials.offices o2 ON o2.id = och.office_id
       WHERE och.politician_id = pc.politician_id LIMIT 1
    ) o ON true
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
   WHERE pc.sources && $1::text[]`, [[...fabricated]]);

const byUrl = new Map();
const rowRecs = [];
for (const r of rows) {
  const survivors = r.sources.filter((s) => !fabricated.has(s));
  rowRecs.push({ politician_id: r.politician_id, topic_id: r.topic_id, name: r.full_name,
                 last_name: r.last_name, government: r.government, survivors,
                 reasoning: (r.reasoning ?? '').slice(0, 200) });
  for (const s of survivors) {
    if (!byUrl.has(s)) byUrl.set(s, { url: s, rows: 0, names: new Set() });
    const e = byUrl.get(s);
    e.rows += 1; e.names.add(r.full_name);
  }
}

const workset = [...byUrl.values()]
  .map((e) => ({ url: e.url, rows: e.rows, names: [...e.names] }))
  .sort((a, b) => b.rows - a.rows);

writeFileSync(path.join(DIR, 'navonly-workset.json'),
  `${JSON.stringify({ fabricated_removed: fabricated.size, affected_rows: rowRecs.length,
                      distinct_survivor_urls: workset.length, workset, rows: rowRecs }, null, 2)}\n`);

console.log(`fabricated urls being REMOVED: ${fabricated.size}`);
console.log(`rows affected:                 ${rowRecs.length}`);
console.log(`rows with ZERO survivors:      ${rowRecs.filter((r) => !r.survivors.length).length}  (sole-sourced, retire regardless)`);
console.log(`distinct survivor urls to read:${workset.length}\n`);
console.log('top survivor urls by rows depending on them:');
for (const w of workset.slice(0, 25)) console.log(`  ${String(w.rows).padStart(3)}  ${w.url}`);
await pool.end();

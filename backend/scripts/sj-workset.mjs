#!/usr/bin/env node
/**
 * Build the survivor reading queue for the somervillejournal.com cluster (the 8th fabricated cluster).
 *
 * WHY THIS HOST IS A FABRICATION AND NOT A RE-POINT, which every earlier note in this workstream got
 * wrong. The standing advice was "genuine paper, dead domain — re-point to Wayback, do NOT retire".
 * There is nothing to point to:
 *   ✅ positive control passes — the host has 3,000 captures spanning 2001→2025.
 *   🔴 ZERO captures of the cited paths, and ZERO archived urls under /2020*, /2022* or /2024*: the
 *      date-slug scheme NEVER existed on this domain.
 *   🔴 the real article scheme was numeric — somervillejournal.com/20418049.htm.
 *   🔴 from 2021 the domain was a PDF SPAM FARM (1,801 of 2,000 captures are
 *      cgi-bin/content/view.php?data=…&filetype=pdf), yet citations are dated 2019–2025.
 * The genuine Somerville Journal was a Wicked Local paper; real coverage lives at
 * wickedlocal.com/somerville*. Matching a row's claim to one of those is per-row research, never
 * mechanical — the 1564 lesson that a re-point is valid only if the TARGET carries the CLAIM.
 *
 * 🔑 The general error: "the publication is real" was checked at BRAND level and never at DOMAIN-ERA or
 * PATH-SCHEME level. Ask all three: does the outlet exist · did THIS DOMAIN serve journalism AT THE
 * CITED DATE · does the cited PATH SCHEME appear in the archive at all.
 *
 * Emits sj-workset.json in the same shape navonly-read-pages.mjs / navonly-classify.mjs consume, so the
 * SAME reading rules decide this cluster. Run them with --prefix sj.
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'data', 'stance-retirement');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows: fabRows } = await pool.query(
  `SELECT DISTINCT s AS url FROM inform.politician_context pc, unnest(pc.sources) s
    WHERE s ILIKE '%somervillejournal%' ORDER BY 1`);
const fabricated = new Set(fabRows.map((r) => r.url));

const { rows } = await pool.query(`
  SELECT pc.politician_id, pc.topic_id, pc.sources, pc.reasoning, p.full_name, g.name AS government
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id
    LEFT JOIN LATERAL (
      SELECT o2.chamber_id FROM essentials.office_current_holder och
        JOIN essentials.offices o2 ON o2.id = och.office_id
       WHERE och.politician_id = pc.politician_id LIMIT 1
    ) o ON true
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s ILIKE '%somervillejournal%')`);

const byUrl = new Map();
const rowRecs = [];
for (const r of rows) {
  const survivors = r.sources.filter((s) => !fabricated.has(s));
  rowRecs.push({ politician_id: r.politician_id, topic_id: r.topic_id, name: r.full_name,
                 government: r.government, survivors, reasoning: (r.reasoning ?? '').slice(0, 200) });
  for (const s of survivors) {
    if (!byUrl.has(s)) byUrl.set(s, { url: s, rows: 0, names: new Set() });
    const e = byUrl.get(s); e.rows += 1; e.names.add(r.full_name);
  }
}

const workset = [...byUrl.values()].map((e) => ({ url: e.url, rows: e.rows, names: [...e.names] }))
  .sort((a, b) => b.rows - a.rows);

writeFileSync(path.join(DIR, 'sj-workset.json'),
  `${JSON.stringify({ fabricated_removed: fabricated.size, affected_rows: rowRecs.length,
                      distinct_survivor_urls: workset.length,
                      fabricated_urls: [...fabricated].sort(), workset, rows: rowRecs }, null, 2)}\n`);

console.log(`somervillejournal urls being removed: ${fabricated.size}`);
console.log(`rows affected:                        ${rowRecs.length}`);
console.log(`rows with ZERO survivors:             ${rowRecs.filter((r) => !r.survivors.length).length}`);
console.log(`distinct survivor urls to read:       ${workset.length}`);
await pool.end();

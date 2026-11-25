#!/usr/bin/env node
// match-people.mjs — read-only. For every holder of the cities in structure.json, list existing
// politician rows with the same surname and first name (or first initial), with any current seat.
// Positive control first: 'Sharon Tucker' (Fort Wayne mayor, CC_0091) must match.
import 'dotenv/config';
import fs from 'node:fs'; import path from 'node:path'; import pg from 'pg';
const DIR = path.dirname(new URL(import.meta.url).pathname);
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const clean = (n) => n.replace(/["“”][^"“”]*["“”]/g, ' ').replace(/\([^)]*\)/g, ' ').replace(/\b(Jr|Sr|II|III|IV)\.?$/i, '').replace(/\s+/g, ' ').trim();
async function find(name) {
  const parts = clean(name).split(' ');
  const first = parts[0], last = parts[parts.length - 1];
  const { rows } = await pool.query(`
    SELECT p.id, p.external_id, p.full_name, p.is_active,
           string_agg(DISTINCT o.title || ' @ ' || coalesce(g.name, '?'), '; ') AS seats
    FROM essentials.politicians p
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = c.government_id
    WHERE lower(p.last_name) = lower($1) AND (lower(p.first_name) = lower($2) OR lower(p.full_name) LIKE lower($2) || '%')
    GROUP BY p.id`, [last, first]);
  return rows;
}
const ctl = await find('Sharon Tucker');
if (!ctl.length) { console.error('CONTROL FAILED: Sharon Tucker not matched'); process.exit(2); }
console.log(`control ok: Sharon Tucker -> ${ctl.length} row(s)`);
const S = JSON.parse(fs.readFileSync(path.join(DIR, 'structure.json'), 'utf8'));
let scanned = 0, hits = 0;
for (const s of S) {
  const j = JSON.parse(fs.readFileSync(path.join(DIR, 'cities', s.slug + '.json'), 'utf8'));
  for (const h of j.holders) {
    if (h.name == null) { console.log(`VACANT ${s.slug.padEnd(18)} ${h.office}`); continue; }
    scanned++;
    const r = await find(h.name);
    if (r.length) hits++;
    console.log(`${r.length ? 'MATCH' : '  -  '} ${s.slug.padEnd(18)} ${h.office.padEnd(27)} ${h.name}` +
      r.map((x) => `\n        id=${x.id} ext=${x.external_id} '${x.full_name}' active=${x.is_active} seats=[${x.seats ?? ''}]`).join(''));
  }
}
const { rows: [b] } = await pool.query(`SELECT min(external_id) AS min_ext FROM essentials.politicians`);
console.log(`\nscanned ${scanned} holders, ${hits} with a same-name row. lowest external_id in use: ${b.min_ext}`);
await pool.end();

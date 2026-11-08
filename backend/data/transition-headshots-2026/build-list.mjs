#!/usr/bin/env node
// The complete list of 2026-11-03 winners who have NO headshot anywhere — the sourcing queue.
//
// 🔴 THERE ARE THREE PLACES A PHOTO CAN LIVE AND A PERSON IS ONLY "MISSING" IF ALL THREE ARE
//   EMPTY. politicians.photo_custom_url is the scalar the backend reads; a
//   politician_images row of type 'default' is what the grid reads from images[];
//   race_candidates.photo_url is the one nothing sweeps and it BEATS the fixed image on ballot
//   pages. A query against any one of them alone under- or over-counts.
// 🔴 IT ALSO REPORTS THE ROWS WHERE THE SCALAR AND THE IMAGE ROW DISAGREE. Writing one without
//   the other is a known defect in this repo: the person looks fine on one surface and blank on
//   the other, and no gate catches it.
//
// This script DECIDES NOTHING ABOUT LICENCES. It says who is missing a face, not where to get
// one. Sourcing rules (press/official/public-domain only, the credit line as the licence test,
// mirror at native size, and the fact that nothing we run checks whether an image CONTAINS a
// face) are in the memory files named in NOTES.md.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const require = createRequire(process.env.RESOLVE_FROM || import.meta.url);
const pg = require('pg');

const outDir = process.argv[2] || '.';
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const { rows } = await client.query(`
  WITH winners AS (
    SELECT rc.politician_id, rc.id AS rc_id, rc.full_name, rc.photo_url AS rc_photo,
           d.district_type, lower(d.state) AS state, d.label AS district_label,
           o.title AS office_title, o.id AS office_id, r.id AS race_id, rc.website_url,
           (SELECT och.politician_id FROM essentials.office_current_holder och
             WHERE och.office_id = o.id) AS current_holder,
           s.swearing_in_date
      FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.office_swearing_in s
             ON s.office_id = o.id AND s.election_date = e.election_date
     WHERE e.election_date = DATE '2026-11-03' AND rc.result = 'won'
  )
  SELECT w.*, p.full_name AS person_name, p.is_active, p.is_incumbent,
         p.photo_custom_url, p.photo_origin_url, p.photo_restriction_code,
         (SELECT count(*) FROM essentials.politician_images pi
           WHERE pi.politician_id = w.politician_id AND pi.type = 'default') AS default_images,
         (SELECT count(*) FROM essentials.politician_images pi
           WHERE pi.politician_id = w.politician_id) AS any_images,
         p.source AS person_source
    FROM winners w
    JOIN essentials.politicians p ON p.id = w.politician_id
   ORDER BY w.district_type, w.state, w.district_label, p.full_name`);
await client.end();

const has = (v) => v !== null && v !== undefined && String(v).trim() !== '';
const missing = rows.filter((r) => !has(r.photo_custom_url) && Number(r.default_images) === 0 && !has(r.rc_photo));
const mismatch = rows.filter((r) => has(r.photo_custom_url) !== (Number(r.default_images) > 0));

// POSITIVE CONTROL: a "missing" set computed from three columns is meaningless if the query
// cannot see a photo that exists. Assert the opposite class is populated before trusting it.
const withPhoto = rows.length - missing.length;
if (withPhoto < 100) throw new Error('only ' + withPhoto + ' winners read as HAVING a photo - the three-column check cannot see photos, so the missing list is meaningless');

const csvEsc = (v) => {
  const s = v === null || v === undefined ? '' : String(v);
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};
const cols = ['politician_id', 'person_name', 'full_name', 'district_type', 'state', 'district_label',
  'office_title', 'is_new_to_seat', 'swearing_in_date', 'photo_restriction_code', 'website_url',
  'person_source', 'any_images', 'race_id', 'rc_id'];
const line = (r) => cols.map((c) => csvEsc(c === 'is_new_to_seat'
  ? (r.current_holder !== r.politician_id ? 'new' : 're-elected')
  : r[c])).join(',');

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'headshot-queue-2026-11-08.csv'),
  cols.join(',') + '\n' + missing.map(line).join('\n') + '\n');
fs.writeFileSync(path.join(outDir, 'headshot-queue-2026-11-08.json'),
  JSON.stringify({ generated_at: new Date().toISOString(), winners: rows.length,
    missing: missing.length, scalar_vs_image_row_mismatch: mismatch.length,
    rows: missing, mismatches: mismatch.map((m) => ({ politician_id: m.politician_id, name: m.person_name,
      photo_custom_url: m.photo_custom_url, default_images: Number(m.default_images) })) }, null, 1));

const by = (sel) => { const m = {}; for (const r of missing) { const k = sel(r); m[k] = (m[k] || 0) + 1; } return m; };
console.log('2026-11-03 winners: ' + rows.length + '  (a photo somewhere: ' + withPhoto + ', the positive control)');
console.log('NO photo in any of the three places: ' + missing.length);
console.log('  of those, NEW to the seat: ' + missing.filter((r) => r.current_holder !== r.politician_id).length);
console.log('  photo-restricted (a licence refusal already recorded): ' + missing.filter((r) => has(r.photo_restriction_code)).length);
console.log('  holding an image row of some other type: ' + missing.filter((r) => Number(r.any_images) > 0).length);
console.log('');
console.log('by tier:  ' + Object.entries(by((r) => r.district_type)).sort((a, b) => b[1] - a[1]).map(([k, v]) => k + ' ' + v).join(' · '));
console.log('by state: ' + Object.entries(by((r) => r.state)).sort((a, b) => b[1] - a[1]).map(([k, v]) => k + ' ' + v).join(' · '));
console.log('');
console.log('🔴 scalar/image-row disagreement (one written without the other): ' + mismatch.length);
for (const m of mismatch) console.log('   ' + m.person_name + ' — photo_custom_url=' + (has(m.photo_custom_url) ? 'set' : 'EMPTY') + ', default image rows=' + m.default_images);
console.log('');
console.log('wrote ' + path.join(outDir, 'headshot-queue-2026-11-08.csv') + ' and .json');

/**
 * MN-5 stage 5, Senate half: harvest the 67 official Senate portraits and resolve each one to the
 * production office row it belongs to.
 *
 * RESOLVED BY OFFICE, NEVER BY NAME (the GA-6 rule). The key is (chamber -> MTFCC, district geo_id):
 * STATE_UPPER -> G5210. The name rides along only as a redundancy check, and it is checked TWICE:
 * against the production row and against the portrait's own alt text, because an alt naming someone
 * else outvotes the page. A disagreement is reported and skipped, never resolved by guessing.
 *
 * The portrait URL comes from each senator's OWN bio page, not from the mem_bio_pic filename in
 * _sen-members.json and not from Open States. All three agree today; the member page is the one that
 * is authoritative tomorrow.
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const DATA = path.resolve(process.argv[2] ?? 'C:/EV-Accounts/backend/data');
const OUT = path.join(DATA, 'seed-mn-headshots-2026');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';

const roster = JSON.parse(fs.readFileSync(path.join(DATA, 'mn-legislature-roster.json'), 'utf8')).roster;
const senators = roster.filter((m) => m.chamber === 'STATE_UPPER' && !m.vacant);
if (senators.length !== 67) throw new Error(`expected 67 senators in the roster, got ${senators.length}`);

const { Client } = pg;
const db = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await db.connect();
const { rows: prod } = await db.query(`
  SELECT d.geo_id, d.mtfcc, o.id AS office_id, o.title, p.id AS politician_id, p.full_name,
         btrim(coalesce(p.photo_custom_url, '')) <> '' AS has_custom,
         (img.politician_id IS NOT NULL) AS has_image_row
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE g.name = 'State of Minnesota' AND c.name_formal = 'Minnesota Senate'`);
await db.end();
const byGeo = new Map(prod.filter((r) => r.mtfcc === 'G5210').map((r) => [r.geo_id, r]));
console.log(`production: ${prod.length} Senate offices, ${byGeo.size} keyed by (G5210, geo_id)`);

const norm = (s) => (s ?? '').normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
  .replace(/^(sen\.?|senator)\s+/i, '').replace(/[^a-z\s]/g, '').replace(/\s+/g, ' ').trim();
const surname = (s) => norm(s).split(' ').slice(-1)[0];

const cands = [];
const problems = [];
for (const m of senators) {
  const res = await fetch(m.senate_bio_url, { headers: { 'User-Agent': UA } });
  const html = await res.text();
  if (!res.ok) { problems.push(`${m.full_name} (SD-${m.district}): bio page HTTP ${res.status}`); continue; }
  const tag = [...html.matchAll(/<img[^>]*src=['"]\/graphics\/[^'"]+['"][^>]*>/gi)].map((x) => x[0]);
  if (tag.length !== 1) { problems.push(`${m.full_name} (SD-${m.district}): ${tag.length} portrait tags on the bio page`); continue; }
  const src = tag[0].match(/src=['"]([^'"]+)['"]/i)[1];
  const alt = (tag[0].match(/alt=['"]([^'"]*)['"]/i) ?? [, ''])[1].trim();
  const row = byGeo.get(m.geo_id);
  if (!row) { problems.push(`${m.full_name} (SD-${m.district}): no production office for geo_id ${m.geo_id}`); continue; }
  if (!row.politician_id) { problems.push(`SD-${m.district}: production office is unseated`); continue; }
  // redundancy checks -- surname, against BOTH the production row and the image's own alt text
  if (surname(row.full_name) !== surname(m.full_name)) {
    problems.push(`SD-${m.district}: production holds "${row.full_name}", roster says "${m.full_name}"`); continue;
  }
  if (surname(alt) !== surname(m.full_name)) {
    problems.push(`SD-${m.district}: portrait alt says "${alt}", roster says "${m.full_name}"`); continue;
  }
  cands.push({
    politician_id: row.politician_id,
    name: row.full_name,
    office: `Senator, District ${m.district}`,
    cohort: 'Minnesota Senate',
    url: new URL(src, 'https://www.senate.mn/').href,
    page: m.senate_bio_url,
    license: 'press_use',
    positional: false,
    _geo_id: m.geo_id,
    _alt: alt,
    _already: { has_custom: row.has_custom, has_image_row: row.has_image_row },
  });
}

fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, 'candidates-senate.json'), JSON.stringify(cands, null, 1));
console.log(`resolved ${cands.length} of 67 · ${problems.length} problem(s)`);
for (const p of problems) console.log(`  ${p}`);

/**
 * MN-6: harvest the 133 official Minnesota House portraits and resolve each one to the production
 * office row it belongs to.
 *
 * 🔴 THIS RUNS ONLY BECAUSE PERMISSION WAS GRANTED. The House's Photo and Digital Image Use Policy
 * forbids digital alteration "in any way, including cropping", which is exactly what this pipeline
 * does. Mike Cook, Minnesota House of Representatives, granted the request by email on 2026-09-17:
 *
 *   "We are good with your request. To make it easy, feel free to just credit Minnesota House of
 *    Representatives for the whole set."
 *
 * The request asked for three specific things and the grant covers all three: storing our own copy
 * rather than hotlinking, cropping to a common 4:5 frame, and a credit. He waived the policy's
 * per-photographer credit in favour of a blanket one. The two staff photographers he named, Andrew
 * VonBank and Michele Jokinen, are recorded in the wave notes but are NOT written per row, because
 * the House does not publish which of them took which portrait and a guessed credit is worse than
 * the blanket credit we were offered.
 *
 * ⚠ THE GRANT IS TO US, NOT TO THE FILES. Open States serves the same house.mn.gov images under the
 * same copyright and no grant reaches them. ⚠ THE SENATE IS NOT COVERED by this email.
 *
 * RESOLVED BY OFFICE, NEVER BY NAME (the GA-6 rule). The key is (chamber -> MTFCC, district geo_id):
 * STATE_LOWER -> G5220. The name rides along only as a redundancy check, and it is checked TWICE:
 * against the production row and against the portrait's own alt text, because an alt naming someone
 * else outvotes the page. A disagreement is reported and skipped, never resolved by guessing.
 *
 * The portrait URL comes from each member's OWN profile page, not from the memberimgls94/<district>
 * pattern and not from Open States. The pattern is predictable and that is the problem: it would
 * still produce a URL for a member whose page has been re-pointed, and it cannot carry the `?v=`
 * revision the page publishes.
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const DATA = path.resolve(process.argv[2] ?? 'C:/ev-accounts-mn-6/backend/data');
const OUT = path.join(DATA, 'seed-mn-headshots-2026');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';
const CREDIT = 'Minnesota House of Representatives (used by permission, 2026-09-17)';

const roster = JSON.parse(fs.readFileSync(path.join(DATA, 'mn-legislature-roster.json'), 'utf8')).roster;
const members = roster.filter((m) => m.chamber === 'STATE_LOWER' && !m.vacant);
if (members.length !== 133) throw new Error(`expected 133 seated House members in the roster, got ${members.length}`);

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
   WHERE g.name = 'State of Minnesota' AND c.name_formal = 'Minnesota House of Representatives'`);
await db.end();

const byGeo = new Map(prod.filter((r) => r.mtfcc === 'G5220').map((r) => [r.geo_id, r]));
console.log(`production: ${prod.length} House offices, ${byGeo.size} keyed by (G5220, geo_id)`);
if (byGeo.size !== 134) throw new Error(`expected 134 House offices keyed by (G5220, geo_id), got ${byGeo.size}`);

// \ud83d\udd34 THE HOUSE SERVES HTML-ENCODED NAMES, AND THE alt ATTRIBUTE IS NOT EXEMPT. MN-2 found eight
// member names written as `Mar&#237;a Isa P&#233;rez-Vega` in the roster; the same encoding is in
// the portrait's alt text. Undecoded, the surname check reads "prezvega" against "perezvega" and
// rejects a correct match. Decode -- never widen the comparison to let the mismatch through, which
// would also let a genuinely wrong alt through.
const decodeEntities = (s) => (s ?? '')
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(parseInt(d, 10)))
  .replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&nbsp;/g, ' ')
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');

const norm = (s) => (s ?? '').normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
  .replace(/^(rep\.?|representative)\s+/i, '').replace(/[^a-z\s]/g, '').replace(/\s+/g, ' ').trim();
const surname = (s) => norm(s).split(' ').slice(-1)[0];

const cands = [];
const problems = [];
for (const m of members) {
  let html;
  try {
    const res = await fetch(m.house_profile_url, { headers: { 'User-Agent': UA } });
    if (!res.ok) { problems.push(`${m.full_name} (HD-${m.district}): profile HTTP ${res.status}`); continue; }
    html = await res.text();
  } catch (e) {
    problems.push(`${m.full_name} (HD-${m.district}): profile fetch failed — ${e.message}`); continue;
  }

  // The portrait is the ONLY memberimgls img on the page. Anything else is a page we do not
  // understand, and an unexpected count is reported rather than resolved by taking the first.
  const tags = [...html.matchAll(/<img[^>]*memberimgls[^>]*>/gi)].map((x) => x[0]);
  if (tags.length !== 1) { problems.push(`${m.full_name} (HD-${m.district}): ${tags.length} portrait tags on the profile page`); continue; }
  const src = tags[0].match(/src=['"]([^'"]+)['"]/i)?.[1];
  const alt = decodeEntities((tags[0].match(/alt=['"]([^'"]*)['"]/i)?.[1] ?? '').trim());
  if (!src) { problems.push(`${m.full_name} (HD-${m.district}): portrait tag carries no src`); continue; }

  const row = byGeo.get(m.geo_id);
  if (!row) { problems.push(`${m.full_name} (HD-${m.district}): no production office for geo_id ${m.geo_id}`); continue; }
  if (!row.politician_id) { problems.push(`HD-${m.district}: production office is unseated`); continue; }
  if (surname(row.full_name) !== surname(m.full_name)) {
    problems.push(`HD-${m.district}: production holds "${row.full_name}", roster says "${m.full_name}"`); continue;
  }
  if (surname(alt) !== surname(m.full_name)) {
    problems.push(`HD-${m.district}: portrait alt says "${alt}", roster says "${m.full_name}"`); continue;
  }

  cands.push({
    politician_id: row.politician_id,
    name: row.full_name,
    office: `Representative, District ${m.district}`,
    cohort: 'Minnesota House',
    url: new URL(src, 'https://www.house.mn.gov/').href,
    page: m.house_profile_url,
    license: CREDIT,
    positional: false,
    _geo_id: m.geo_id,
    _alt: alt,
    _already: { has_custom: row.has_custom, has_image_row: row.has_image_row },
  });
}

fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, 'candidates-house.json'), JSON.stringify(cands, null, 1));
console.log(`resolved ${cands.length} of ${members.length} · ${problems.length} problem(s)`);
for (const p of problems) console.log(`  ${p}`);

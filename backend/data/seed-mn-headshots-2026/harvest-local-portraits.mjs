/**
 * MN-5 stage 5, local and county half: find a portrait for each of the 37 Duluth, Saint Paul,
 * St. Louis County and Ramsey County officials.
 *
 * 🔴 IT READS THE PAGE LIVE, and keeps the body. MN-3 and MN-4 captured these same pages for TERM
 * DATES, and their copies are already wrong about portraits: all four Duluth at-large pages carried
 * `/media/12005/headshot.jpg` in the capture, while the live pages carry three different files.
 * A capture is evidence about the question it was taken for.
 *
 * Reported, never picked silently: an `src` or `alt` that NAMES the person scores highest; an opaque
 * CMS filename (/media/12005/headshot.jpg) is flagged `positional`, because a seat-keyed or generic
 * filename is exactly where wrong-person errors hide. Those get a verify-face flag on the sheet.
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const DATA = path.resolve('C:/EV-Accounts/backend/data');
const OUT = path.join(DATA, 'seed-mn-headshots-2026');
const PAGES = path.join(OUT, '_pages');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';
fs.mkdirSync(PAGES, { recursive: true });

const cityIdx = JSON.parse(fs.readFileSync(path.join(DATA, 'seed-mn-cities-2026/_member-pages-index.json'), 'utf8'));
const cntyIdx = JSON.parse(fs.readFileSync(path.join(DATA, 'seed-mn-counties-2026/_county-pages-index.json'), 'utf8'));

const norm = (s) => (s ?? '').normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z]/g, '');
const words = (n) => (n ?? '').split(/[\s.]+/).filter((w) => w.length > 2).map(norm);
const surname = (n) => words(n).slice(-1)[0];
const namesPerson = (i, name) => {
  const hay = norm(`${i.src} ${i.alt}`);
  return words(name).some((w) => hay.includes(w));
};

const { Client } = pg;
const db = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await db.connect();
const { rows: prod } = await db.query(`
  SELECT g.name AS government, c.name_formal AS body, o.title, p.id AS politician_id, p.full_name,
         (img.politician_id IS NOT NULL) AS has_image_row
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE g.name IN ('City of Duluth, Minnesota, US','City of Saint Paul, Minnesota, US',
                    'St. Louis County, Minnesota, US','Ramsey County, Minnesota, US')`);
await db.end();
const seated = prod.filter((r) => r.politician_id);
console.log(`production: ${prod.length} local/county offices, ${seated.length} seated`);

// Resolve the roster name to the production row on SURNAME PLUS FIRST NAME, never on the whole
// string: production holds "Kimberly J. Maki" where the county page says "Kimberly Maki", and an
// exact-string match drops her. A surname that is ambiguous inside one government is reported.
function resolve(name, government) {
  const cands = seated.filter((r) => r.government === government && surname(r.full_name) === surname(name));
  if (cands.length === 1) return cands[0];
  const tighter = cands.filter((r) => words(r.full_name)[0] === words(name)[0]);
  return tighter.length === 1 ? tighter[0] : null;
}

const GOV = { Duluth: 'City of Duluth, Minnesota, US', 'Saint Paul': 'City of Saint Paul, Minnesota, US',
              'St. Louis': 'St. Louis County, Minnesota, US', Ramsey: 'Ramsey County, Minnesota, US' };
const NOISE = /\.svg(\?|$)|logo|icon|sprite|spacer|badge|seal|facebook|twitter|linkedin|instagram|youtube|banner|courthouse|building|map/i;
const OPAQUE = /\/media\/\d+\/(headshot|photo|image|portrait)\b|^\/?(images?|photos?)\/\d+\.(jpg|png)/i;

const out = [];
for (const [idx, kind] of [[cityIdx, 'city'], [cntyIdx, 'county']]) {
  for (const m of idx) {
    const key = kind === 'city' ? m.city : m.county;
    const url = m.finalUrl ?? m.url;
    const cache = path.join(PAGES, `${key}-${(m.seat ?? '').replace(/\W+/g, '')}-${surname(m.name)}.html`);
    let html = '';
    let status = 'cache';
    if (fs.existsSync(cache)) html = fs.readFileSync(cache, 'utf8');
    else {
      const res = await fetch(url, { headers: { 'User-Agent': UA } });
      status = `HTTP ${res.status}`;
      html = await res.text();
      if (res.ok) fs.writeFileSync(cache, html);
    }
    const imgs = [...html.matchAll(/<img[^>]*>/gi)].map((t) => ({
      tag: t[0],
      src: (t[0].match(/src=["']([^"']+)["']/i) ?? [, ''])[1],
      alt: (t[0].match(/alt=["']([^"']*)["']/i) ?? [, ''])[1],
    // 🔴 A NAME BEATS THE NOISE FILTER. The first cut dropped Duluth's mayor, because his portrait
    // is `reinert_roger_formal-headshot_-with-seal.jpg` and the filter refuses anything matching
    // `seal` -- the city seal is IN the photograph. A filename that names the person is evidence;
    // the noise list is only a guess about filenames that carry no name at all.
    })).filter((i) => i.src && (namesPerson(i, m.name) || (!NOISE.test(i.src) && !NOISE.test(i.alt))));
    const want = words(m.name);
    const scored = imgs.map((i) => {
      const hay = norm(i.src + ' ' + i.alt);
      const hits = want.filter((w) => hay.includes(w)).length;
      return { src: new URL(i.src, url).href, alt: i.alt, names_person: hits > 0, hits,
               positional: hits === 0 && OPAQUE.test(i.src) };
    }).sort((a, b) => b.hits - a.hits);
    const row = resolve(m.name, GOV[key]);
    out.push({ cohort: key === 'Duluth' || key === 'Saint Paul' ? `City of ${key}` : `${key} County`,
               seat: m.seat, name: m.name, page: url, fetched: status,
               politician_id: row?.politician_id ?? null, prod_name: row?.full_name ?? null,
               prod_office: row?.title ?? null, has_image_row: row?.has_image_row ?? null,
               images: scored.slice(0, 5) });
  }
}
fs.writeFileSync(path.join(OUT, 'local-harvest.json'), JSON.stringify(out, null, 1));
const named = out.filter((o) => o.images.some((i) => i.names_person)).length;
const positional = out.filter((o) => !o.images.some((i) => i.names_person) && o.images.some((i) => i.positional)).length;
console.log(`${out.length} officials · ${named} with a NAMED image · ${positional} only an opaque filename · ` +
            `${out.length - named - positional} with nothing`);
const unresolved = out.filter((o) => !o.politician_id);
console.log(`unmatched to production: ${unresolved.map((o) => o.name).join(', ') || 'none'}`);

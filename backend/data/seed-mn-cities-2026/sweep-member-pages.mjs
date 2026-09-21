/**
 * MN-3 change-check: read each of the 18 members' OWN page.
 *
 * MN-2's finding was that a roster LIST page is not a change-check -- house.mn.gov listed a member
 * three months after he resigned, and the only in-band signal was a banner on his own profile. The
 * same discipline applies to a city council, and Saint Paul has already given a hint that it is
 * needed: sub-pages still live under `/ward-4-councilmember-mitra-jalali/` while both the ward
 * layer and the council index name Molly Coleman.
 *
 *   node sweep-member-pages.mjs            fetch and scan
 *   node sweep-member-pages.mjs --control  plant each defect shape and require it to be reported
 *
 * 🔴 SAINT PAUL'S WARD URLs ARE NOT UNIFORM. Wards 1-6 are `/ward-N`; ward 7 is
 * `/ward-7-cheniqua-johnson`, and the old ward-4 sub-pages still sit under
 * `/ward-4-councilmember-mitra-jalali/`. A slug that embeds the member's name breaks when the
 * member changes, so these URLs are re-derived from the council index, never remembered.
 */
import fs from 'fs';

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36';

const SEATS = [
  // Duluth -- 5 districts, 4 at large, 1 mayor.
  ['Duluth', 'Mayor', 'Roger J. Reinert', 'https://duluthmn.gov/mayor/'],
  ['Duluth', 'District 1', 'Wendy Durrwachter', 'https://duluthmn.gov/city-council/city-councilors/wendy-durrwachter/'],
  ['Duluth', 'District 2', 'Diane Desotelle', 'https://duluthmn.gov/city-council/city-councilors/diane-desotelle/'],
  ['Duluth', 'District 3', 'Roz Randorf', 'https://duluthmn.gov/city-council/city-councilors/roz-randorf/'],
  ['Duluth', 'District 4', 'David Clanaugh', 'https://duluthmn.gov/city-council/city-councilors/david-clanaugh/'],
  ['Duluth', 'District 5', 'Janet Kennedy', 'https://duluthmn.gov/city-council/city-councilors/janet-kennedy/'],
  ['Duluth', 'At Large', 'Arik Forsman', 'https://duluthmn.gov/city-council/city-councilors/arik-forsman/'],
  ['Duluth', 'At Large', 'Jordon Johnson', 'https://duluthmn.gov/city-council/city-councilors/jordon-johnson/'],
  ['Duluth', 'At Large', 'Lynn Marie Nephew', 'https://duluthmn.gov/city-council/city-councilors/lynn-marie-nephew/'],
  ['Duluth', 'At Large', 'Terese Tomanek', 'https://duluthmn.gov/city-council/city-councilors/terese-tomanek/'],
  // Saint Paul -- 7 wards, 1 mayor.
  ['Saint Paul', 'Mayor', 'Kaohly Her', 'https://www.stpaul.gov/departments/mayors-office'],
  ['Saint Paul', 'Ward 1', 'Anika Bowie', 'https://www.stpaul.gov/department/city-council/ward-1'],
  ['Saint Paul', 'Ward 2', 'Rebecca Noecker', 'https://www.stpaul.gov/department/city-council/ward-2'],
  ['Saint Paul', 'Ward 3', 'Saura Jost', 'https://www.stpaul.gov/department/city-council/ward-3'],
  ['Saint Paul', 'Ward 4', 'Molly Coleman', 'https://www.stpaul.gov/department/city-council/ward-4'],
  ['Saint Paul', 'Ward 5', 'HwaJeong Kim', 'https://www.stpaul.gov/department/city-council/ward-5'],
  ['Saint Paul', 'Ward 6', 'Nelsie Yang', 'https://www.stpaul.gov/department/city-council/ward-6'],
  ['Saint Paul', 'Ward 7', 'Cheniqua Johnson', 'https://www.stpaul.gov/department/city-council/ward-7-cheniqua-johnson'],
];

/** Names a page may legitimately mention that are NOT the seat's holder. */
const PREDECESSORS = ['Mitra Jalali', 'Melvin Carter', 'Emily Larson', 'Kaohly Vang Her'];

const strip = (h) =>
  h
    .replace(/<script[\s\S]*?<\/script>/g, ' ')
    .replace(/<style[\s\S]*?<\/style>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ');

const PATTERNS = [
  /\bresign\w*[^.]{0,130}/gi,
  /\bvacan\w*[^.]{0,110}/gi,
  /\bstepp?(?:ed|ing) down[^.]{0,110}/gi,
  /\bdeceased\b[^.]{0,90}/gi,
  /\bpassed away[^.]{0,90}/gi,
  /\bwas appointed[^.]{0,110}/gi,
  /\bappointed to (?:the |fill)[^.]{0,110}/gi,
  /\bsworn in[^.]{0,110}/gi,
  /\bspecial election[^.]{0,110}/gi,
  /\b(?:interim|acting) councilm?(?:ember|an|woman)?[^.]{0,90}/gi,
  /\bformer councilmember[^.]{0,90}/gi,
];

const scan = (t) => {
  const out = [];
  for (const re of PATTERNS) {
    const hits = t.match(re);
    if (hits) for (const h of hits) out.push(h.trim().replace(/\s+/g, ' ').slice(0, 160));
  }
  return [...new Set(out)];
};

fs.mkdirSync('_member-pages', { recursive: true });

const rows = [];
let i = 0;
async function worker() {
  while (i < SEATS.length) {
    const [city, seat, name, url] = SEATS[i++];
    const file = `_member-pages/${city.replace(/\s+/g, '')}-${seat.replace(/\s+/g, '')}.html`;
    try {
      const r = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
      const body = await r.text();
      fs.writeFileSync(file, body);
      rows.push({ city, seat, name, url, status: r.status, len: body.length, file, finalUrl: r.url });
    } catch (e) {
      rows.push({ city, seat, name, url, status: 'ERR', err: e.message, len: 0, file: null });
    }
  }
}
await Promise.all(Array.from({ length: 4 }, worker));
rows.sort((a, b) => SEATS.findIndex((s) => s[0] === a.city && s[1] === a.seat && s[2] === a.name)
  - SEATS.findIndex((s) => s[0] === b.city && s[1] === b.seat && s[2] === b.name));
fs.writeFileSync('_member-pages-index.json', JSON.stringify(rows, null, 1));

const bad = rows.filter((r) => r.status !== 200 || r.len < 2000);
console.log(`pages fetched: ${rows.length}; non-200 or suspiciously short: ${bad.length}`);
for (const b of bad) console.log(`  ${b.city} ${b.seat}: status ${b.status}, ${b.len} bytes`);

console.log('\n-- IDENTITY: does the page name the person the roster says holds the seat? ------');
let identityFail = 0;
const notes = [];
for (const r of rows) {
  if (!r.file) { identityFail++; continue; }
  // 🔴 A 404 BODY IS STILL A FULL PAGE. Saint Paul's 404 is 110 KB and mentions "Johnson" twice,
  // so a surname-only identity test PASSED on it. Status is checked before content, always.
  if (r.status !== 200) {
    identityFail++;
    console.log(`  ✗ ${r.city} ${r.seat}: HTTP ${r.status} -- not a member page, whatever it contains`);
    continue;
  }
  const t = strip(fs.readFileSync(r.file, 'utf8'));
  r.text = t;
  const last = r.name.split(/\s+/).slice(-1)[0];
  const hasFull = t.toLowerCase().includes(r.name.toLowerCase());
  const hasLast = new RegExp(`\\b${last}\\b`, 'i').test(t);
  if (!hasFull && !hasLast) {
    identityFail++;
    console.log(`  ✗ ${r.city} ${r.seat}: page never names ${r.name}`);
  } else {
    console.log(`  ✓ ${r.city} ${String(r.seat).padEnd(11)} ${r.name.padEnd(20)} ${hasFull ? 'full name' : 'surname only'}`);
  }
  // Does it name somebody ELSE who used to hold a seat?
  for (const p of PREDECESSORS) {
    if (p !== r.name && t.toLowerCase().includes(p.toLowerCase())) {
      notes.push({ ...r, text: undefined, note: `names a predecessor: ${p}` });
    }
  }
  for (const n of scan(t)) notes.push({ ...r, text: undefined, note: n });
}
console.log(`identity failures: ${identityFail}`);

console.log(`\n-- STATUS LANGUAGE: ${notes.length} hit(s) -- a reading queue, not a verdict ------`);
for (const n of notes) console.log(`  ${n.city} ${String(n.seat).padEnd(11)} ${String(n.name).padEnd(20)} :: ${n.note}`);

if (process.argv.includes('--control')) {
  console.log('\n-- POSITIVE CONTROLS (the scanner must FAIL before its zeroes are believed) -----');
  const base = rows.find((r) => r.text);
  const shapes = [
    ['resignation', 'Councilmember Control resigned effective March 3, 2026'],
    ['vacancy', 'This seat is currently vacant'],
    ['appointment', 'was appointed to fill the vacancy in July 2025'],
    ['successor', 'was sworn in on January 6, 2026'],
    ['stepping down', 'announced she is stepping down at the end of the year'],
    ['interim', 'serving as interim councilmember until the special election'],
  ];
  for (const [label, planted] of shapes) {
    const n = scan(base.text + ' ' + planted).length - scan(base.text).length;
    console.log(`  ${label.padEnd(14)} -> ${n > 0 ? `+${n} hit(s) OK` : 'NOT REPORTED -- scanner is blind to this shape'}`);
  }
  console.log(`  unmodified baseline (${base.city} ${base.seat}) -> ${scan(base.text).length} hit(s)`);
}

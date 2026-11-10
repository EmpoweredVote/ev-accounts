#!/usr/bin/env node
/**
 * parse-ne-canvass-counties.mjs — which counties are in each Nebraska board district,
 * read from the Secretary of State's official canvass books.
 *
 * 🔴🔴 WHY THIS EXISTS AT ALL, AND IT IS THE WHOLE POINT OF THE NEBRASKA IMPORT.
 *   Alabama, Louisiana and New Mexico each defined their board districts in STATUTE, as lists of
 *   counties or parishes, and the loaders gated the geometry on that text. Nebraska does not.
 *   LB 5, LB 7 and LB 8 of the 2021 First Special Session each "set the boundaries … by the
 *   adoption of maps by reference" and name no county at all: the law is a set of map sheets
 *   filed with the Clerk of the Legislature. The maps themselves are published only as raster
 *   PDFs with no text layer.
 *   ▶ So the composition gate cannot be read out of the law. It is built instead from the
 *   SECRETARY OF STATE'S CANVASS BOOKS: the official, certified report of who voted where. A
 *   county that cast votes in the race for District 7 is in District 7, and a county split
 *   between two districts casts votes in both. That is evidence from outside the map in the
 *   strongest sense available — the election was actually administered on these boundaries by
 *   93 county election officials, and the result was certified by the Board of State Canvassers.
 *
 * COVERAGE. Every district of all three bodies has been elected at least once under the 2021
 *   maps, so three canvass books cover all 21:
 *     2022 general  — PSC 4, 5          · SBOE 5, 6, 7, 8 · Regents 6, 7
 *     2024 general  — PSC 1, 3          · SBOE 1, 2, 3, 4 · Regents 3, 4, 5, 8
 *     2026 primary  — PSC 2             · SBOE 5, 6, 7, 8 · Regents 1, 2, 4
 *   🟢 SBOE 5-8 AND REGENTS 4 ARE READ TWICE, FROM DIFFERENT ELECTIONS, AND THE TWO READINGS
 *   MUST AGREE. That is this file's own control: five districts whose county lists are derived
 *   from two separate canvasses four years apart. A parser that mis-assigns a column cannot
 *   produce the same wrong answer twice from two differently laid out books.
 *
 * ⚠ WHAT A CANVASS CANNOT SEE. A county appears in a district's table because somebody there
 *   cast a ballot in that race. A sliver of a split county holding no voters at all would be
 *   missing. The loaders therefore treat the canvass list as the EXPECTATION and report any
 *   county the geometry says is split but the canvass does not — measured, never waved through.
 *
 * ⚠ AND IT CANNOT SEE AN UNCONTESTED RACE EITHER. A Nebraska nonpartisan primary with two or
 *   fewer candidates does not appear on the primary ballot (Neb. Rev. Stat. 32-811), so a body's
 *   district can be missing from a primary canvass for a reason that has nothing to do with
 *   geography. This is why the general-election books carry most of the load.
 *
 * The canvass PDFs are downloaded, untrusted data: each one's sha256 is checked against the
 * constant below before a byte of it is parsed, and nothing in them is executed.
 *
 * Usage (from backend/):
 *   node data/state-exec-2026-results/parse-ne-canvass-counties.mjs <pdfdir> <outdir> [--offline]
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';

const [, , PDFDIR, OUTDIR, ...rest] = process.argv;
if (!PDFDIR || !OUTDIR) throw new Error('usage: parse-ne-canvass-counties.mjs <pdfdir> <outdir> [--offline]');
const OFFLINE = rest.includes('--offline');

const BOOKS = [
  {
    key: '2022-general',
    url: 'https://sos.nebraska.gov/sites/default/files/doc/elections/2022/2022%20General%20Canvass%20Book.pdf',
    title: 'Official Report of the Nebraska Board of State Canvassers, General Election, November 8, 2022',
    sha256: null, // filled on first run; see RECORDED_SHA below
  },
  {
    key: '2024-general',
    url: 'https://sos.nebraska.gov/sites/default/files/doc/elections/2024/2024%20General%20Canvass%20Book.pdf',
    title: 'Official Report of the Nebraska Board of State Canvassers, General Election, November 5, 2024',
    sha256: null,
  },
  {
    key: '2026-primary',
    url: 'https://sos.nebraska.gov/sites/default/files/doc/elections/2026/2026_Primary_Canvass_Book.pdf',
    title: 'Official Report of the Nebraska Board of State Canvassers, Primary Election, May 12, 2026',
    sha256: null,
  },
];

// 🔴 THE DIGESTS ARE THE PROVENANCE. A canvass book is a final, certified document and does not
//    change; if one of these stops matching, the file at that URL is not the one this gate was
//    built from, and the run must stop rather than re-derive a composition from something new.
const RECORDED_SHA = {
  '2022-general': 'bf1634f18964b1ab616a474c5f185680058bbb6a8856431c79ab2a04930b6e53',
  '2024-general': '4887fb1caab820ab737adaaff9b73ee601e37a707fb0002d8901fd674e8efbe9',
  '2026-primary': 'd1b2ce9b9746a4faddc2700ce613b3cd620ec1b9bd3f9bacf5e36d9586055fba',
};

const BODIES = {
  psc: { heading: /^Public Service Commissioner$/, count: 5, label: 'Public Service Commissioner' },
  sboe: { heading: /^Member of the State Board of Education$/, count: 8, label: 'State Board of Education' },
  regents: { heading: /^Member of the Board of Regents of the University of Nebraska$/, count: 8, label: 'University of Nebraska Board of Regents' },
};

// Nebraska's 93 counties, as production spells them (essentials.geofence_boundaries, mtfcc
// G4020, state '31'), paired with the bare name the canvass books print.
const COUNTIES = ['Adams', 'Antelope', 'Arthur', 'Banner', 'Blaine', 'Boone', 'Box Butte', 'Boyd', 'Brown',
  'Buffalo', 'Burt', 'Butler', 'Cass', 'Cedar', 'Chase', 'Cherry', 'Cheyenne', 'Clay', 'Colfax', 'Cuming',
  'Custer', 'Dakota', 'Dawes', 'Dawson', 'Deuel', 'Dixon', 'Dodge', 'Douglas', 'Dundy', 'Fillmore',
  'Franklin', 'Frontier', 'Furnas', 'Gage', 'Garden', 'Garfield', 'Gosper', 'Grant', 'Greeley', 'Hall',
  'Hamilton', 'Harlan', 'Hayes', 'Hitchcock', 'Holt', 'Hooker', 'Howard', 'Jefferson', 'Johnson', 'Kearney',
  'Keith', 'Keya Paha', 'Kimball', 'Knox', 'Lancaster', 'Lincoln', 'Logan', 'Loup', 'McPherson', 'Madison',
  'Merrick', 'Morrill', 'Nance', 'Nemaha', 'Nuckolls', 'Otoe', 'Pawnee', 'Perkins', 'Phelps', 'Pierce',
  'Platte', 'Polk', 'Red Willow', 'Richardson', 'Rock', 'Saline', 'Sarpy', 'Saunders', 'Scotts Bluff',
  'Seward', 'Sheridan', 'Sherman', 'Sioux', 'Stanton', 'Thayer', 'Thomas', 'Thurston', 'Valley',
  'Washington', 'Wayne', 'Webster', 'Wheeler', 'York'];
if (COUNTIES.length !== 93) throw new Error(`the county list holds ${COUNTIES.length} names, not Nebraska's 93`);
// Longest first, so "Box Butte" is matched before "Box" could be and "Red Willow" before "Red".
const COUNTY_RE = new RegExp(`^(${[...COUNTIES].sort((a, b) => b.length - a.length).join('|')})\\b`);

// 🔴🔴 THE SECTION IS BOUNDED BY THE BOOK'S OWN TABLE OF CONTENTS, NOT BY A LIST OF HEADINGS I
//   THOUGHT OF. The first version of this file closed a body's section when it met a heading
//   from a hand-written blacklist, and a heading that is not on the list does not close
//   anything — it silently keeps the section open and feeds another office's districts into
//   this one. That is not hypothetical: the 2024 book puts "Judge of the District Court",
//   "District 3", "Lancaster" a few pages after the Board of Regents, and a blacklist that had
//   not thought of judges would have recorded Lancaster as part of Regents District 3. The
//   number would have looked perfectly plausible.
//   ▶ So the page range comes from the TOC, and the section ends at the TOC's OWN next entry.
//   A heading nobody anticipated is now outside the pages being read at all.
const TOC_LINE = /^(.+?)\s*\.{5,}\s*(\d+)$/;

const dl = async (b) => {
  const file = path.join(PDFDIR, `${b.key}.pdf`);
  if (!OFFLINE) {
    const r = await fetch(b.url, { headers: { 'User-Agent': 'ev-accounts/1.0 (Nebraska board district import)' } });
    if (!r.ok) throw new Error(`${b.key}: HTTP ${r.status} from ${b.url}`);
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.subarray(0, 5).toString() !== '%PDF-') throw new Error(`${b.key}: the response is not a PDF`);
    fs.mkdirSync(PDFDIR, { recursive: true });
    fs.writeFileSync(file, buf);
  }
  if (!fs.existsSync(file)) throw new Error(`${b.key}: ${file} does not exist — run without --offline`);
  const sha = crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  b.sha256 = sha;
  if (RECORDED_SHA[b.key] !== 'FILL' && RECORDED_SHA[b.key] !== sha) {
    throw new Error(`${b.key}: sha256 is ${sha}, the recorded digest is ${RECORDED_SHA[b.key]} — the document at that URL has changed`);
  }
  return file;
};

const pages = (file, from, to) => execFileSync('pdftotext',
  ['-f', String(from), '-l', String(to), '-table', file, '-'],
  { encoding: 'latin1', maxBuffer: 256 * 1024 * 1024 });

/** The book's table of contents: [{title, page}], in printed order. */
function readToc(file) {
  const txt = pages(file, 1, 12);
  const toc = [];
  for (const raw of txt.split('\n')) {
    const m = raw.trim().replace(/\s+/g, ' ').match(TOC_LINE);
    if (m) toc.push({ title: m[1].trim(), page: Number(m[2]) });
  }
  if (toc.length < 20) throw new Error(`${file}: the table of contents yielded only ${toc.length} entries`);
  // The printed page number and the PDF page index agree in every canvass book; prove it rather
  // than assume it, by checking a page's own footer.
  return toc;
}

/** One body's county lists in one book: district -> Set(county), or null if it is not in it. */
function readSection(file, toc, bodyKey) {
  const B = BODIES[bodyKey];
  const i = toc.findIndex(e => B.heading.test(e.title));
  if (i < 0) return null;
  const next = toc[i + 1];
  if (!next) throw new Error(`${file}: "${toc[i].title}" is the last TOC entry, so its section has no end`);
  const txt = pages(file, toc[i].page, next.page);

  const out = new Map();
  let open = false;
  let districts = null;   // [{d, at}] from the most recent District-header line
  let columns = null;     // [{d, from, to}] once a County-header line has been seen

  const add = (d, county) => {
    if (!out.has(d)) out.set(d, new Set());
    out.get(d).add(county);
  };

  for (const raw of txt.split('\n')) {
    const flat = raw.trim().replace(/\s+/g, ' ');
    if (!flat) continue;

    if (B.heading.test(flat)) { open = true; districts = null; columns = null; continue; }
    if (open && flat === next.title) break;          // the TOC's own next office closes it
    if (!open) continue;

    // A "District N" header line. There may be one (centred over two county columns) or several.
    const ds = [...raw.matchAll(/\bDistrict\s+(\d+)\b/g)].map(m => ({ d: Number(m[1]), at: m.index }));
    if (ds.length) { districts = ds; columns = null; continue; }

    // A "County" column-header line fixes where each district's county column starts.
    const cols = [...raw.matchAll(/\bCounty\b/g)].map(m => m.index);
    if (cols.length && /^County\b/.test(flat)) {
      if (!districts) throw new Error(`a County header with no District header above it: "${flat}"`);
      if (districts.length === 1) {
        columns = cols.map((at, i) => ({ d: districts[0].d, from: at - 2, to: i + 1 < cols.length ? cols[i + 1] - 2 : Infinity }));
      } else if (districts.length === cols.length) {
        const sorted = [...districts].sort((a, b) => a.at - b.at);
        columns = cols.map((at, i) => ({ d: sorted[i].d, from: at - 2, to: i + 1 < cols.length ? cols[i + 1] - 2 : Infinity }));
      } else {
        throw new Error(`${districts.length} District header(s) over ${cols.length} County column(s): "${flat}"`);
      }
      continue;
    }

    if (!columns) continue;
    for (const c of columns) {
      const seg = raw.slice(Math.max(0, c.from), c.to === Infinity ? undefined : c.to);
      const m = seg.replace(/^\s+/, '').match(COUNTY_RE);
      if (m) add(c.d, m[1]);
    }
  }
  if (!open) throw new Error(`${file}: the TOC puts "${toc[i].title}" on page ${toc[i].page}, and that page does not carry the heading`);
  return out;
}

const readings = {};
for (const b of BOOKS) {
  const file = await dl(b);
  const toc = readToc(file);
  readings[b.key] = {};
  for (const key of Object.keys(BODIES)) readings[b.key][key] = readSection(file, toc, key) ?? new Map();
  const summary = Object.entries(readings[b.key])
    .map(([k, m]) => `${k} ${[...m.keys()].sort((x, y) => x - y).join(',') || '-'}`).join(' · ');
  console.log(`${b.key}  sha256 ${b.sha256.slice(0, 16)}  ${summary}`);
}

fs.mkdirSync(OUTDIR, { recursive: true });
const report = [];

for (const [key, B] of Object.entries(BODIES)) {
  // Merge the books, and make every district read twice agree.
  const merged = new Map();          // district -> Set(county)
  const seenIn = new Map();          // district -> [book keys]
  for (const b of BOOKS) {
    for (const [d, set] of readings[b.key][key]) {
      if (!seenIn.has(d)) seenIn.set(d, []);
      seenIn.get(d).push(b.key);
      if (!merged.has(d)) { merged.set(d, new Set(set)); continue; }
      const was = [...merged.get(d)].sort().join(', ');
      const now = [...set].sort().join(', ');
      // 🟢 THE TWO-READINGS CONTROL. Same district, two canvasses, two page layouts.
      if (was !== now) {
        throw new Error(`${key} district ${d} reads differently in ${seenIn.get(d).join(' and ')}:\n  ${was}\n  ${now}`);
      }
    }
  }

  const got = [...merged.keys()].sort((a, b) => a - b);
  const want = Array.from({ length: B.count }, (_, i) => i + 1);
  if (got.join(',') !== want.join(',')) {
    throw new Error(`${key}: the canvasses cover districts ${got.join(',')}, not all of 1..${B.count}`);
  }

  // county -> districts
  const byCounty = new Map();
  for (const [d, set] of merged) for (const c of set) {
    if (!byCounty.has(c)) byCounty.set(c, []);
    byCounty.get(c).push(d);
  }
  const missing = COUNTIES.filter(c => !byCounty.has(c));
  if (missing.length) throw new Error(`${key}: ${missing.length} county/counties cast no vote in any district — ${missing.join(', ')}`);
  if (byCounty.size !== 93) throw new Error(`${key}: the canvasses name ${byCounty.size} counties, not 93`);

  const whole = [];
  const split = [];
  for (const c of COUNTIES) {
    const ds = byCounty.get(c).slice().sort((a, b) => a - b);
    if (ds.length === 1) whole.push({ district: ds[0], county: `${c} County` });
    else split.push({ county: `${c} County`, districts: ds });
  }

  const doubleRead = [...seenIn.entries()].filter(([, v]) => v.length > 1).map(([d]) => d).sort((a, b) => a - b);

  const out = {
    body: key,
    label: B.label,
    districts: B.count,
    source: 'Nebraska Secretary of State, Official Report of the Board of State Canvassers. The ' +
      'county list for each district is the set of counties that cast votes in that district\'s ' +
      'race. Nebraska\'s board districts are set by map reference and no statute lists a county.',
    books: BOOKS.map(b => ({ key: b.key, title: b.title, url: b.url, sha256: b.sha256 })),
    readTwice: doubleRead,
    whole,
    split,
  };
  fs.writeFileSync(path.join(OUTDIR, `ne-${key}-counties-2026-11-07.json`), JSON.stringify(out, null, 2));
  report.push(`${B.label}: ${whole.length} whole · ${split.length} split · districts read twice: ${doubleRead.join(', ') || 'none'}`);
  for (const s of split) report.push(`    split  ${s.county} -> ${s.districts.join(', ')}`);
}

console.log('\n' + report.join('\n'));

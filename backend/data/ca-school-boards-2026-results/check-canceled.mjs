#!/usr/bin/env node
// Cross-check every race with no county contest against LA County's own FINAL LIST OF
// CANCELED ELECTIONS.
//
// 🔴🔴 AN ABSENCE IS NOT A FINDING UNTIL A SOURCE NAMES IT. 96 of our 197 school-board races
//   have no contest in the county's results. That is consistent with "the election was
//   cancelled for insufficiency of candidates" and equally consistent with "our race row is
//   wrong about which seat was up" — and the second would be ours to fix. The RR/CC publishes
//   the list, so the check runs FROM THE SOURCE'S LIST rather than from our silence:
//   content.lavote.gov/docs/rrcc/documents/canceled-elections-november-2026.pdf
//   ("FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION DUE TO INSUFFICIENCY
//   OF CANDIDATES", General Election November 3, 2026, 4 pages, retrieved 2026-11-08).
//   ⚠ A TENTATIVE VERSION IS SERVED FROM A NEARLY IDENTICAL URL and predates the extended
//   nomination period, so it disagrees with the final one. Check the title says FINAL.
//
// Usage: node check-canceled.mjs <analysis.json> <canceled.pdf>
import fs from 'node:fs';
import zlib from 'node:zlib';

const analysis = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const pdf = fs.readFileSync(process.argv[3]);

// ── pull the text out of the PDF's content streams ──
const chunks = [];
for (let i = 0; ;) {
  const s = pdf.indexOf('stream', i);
  if (s < 0) break;
  let b = s + 6;
  if (pdf[b] === 13) b++;
  if (pdf[b] === 10) b++;
  const e = pdf.indexOf('endstream', b);
  if (e < 0) break;
  // 🔴 SKIP THE EMBEDDED FONT PROGRAMS. They inflate to binary whose printable fragments
  //   ("AdobeUCS", "Arial", a Monotype licence) land between the pages and run into the first
  //   district name on the next page — "AdobeUCS Glendora" matched nothing and Glendora's two
  //   cancelled seats read as seats the county had not cancelled.
  //   A font stream's dictionary carries /Length1 (or a CIDFont/Type1C subtype) and a page's
  //   content stream does not, so the document itself says which is which.
  const dict = pdf.subarray(Math.max(0, s - 2000), s).toString('latin1');
  const open = dict.lastIndexOf('<<');
  if (open >= 0 && /\/Length1|\/Subtype\s*\/(Type1C|CIDFontType0C|OpenType)/.test(dict.slice(open))) { i = e + 9; continue; }
  let data = pdf.subarray(b, e);
  try { data = zlib.inflateSync(data); } catch { i = e + 9; continue; }
  // A ToUnicode CMap is not a font PROGRAM and carries no /Length1, so the dictionary test
  // above lets it through; it still is not page content, and its "AdobeUCS" marker was what
  // ran into Glendora's name. A CMap says so in its own first lines.
  if (/begincmap|\/Adobe\s*\/UCS/.test(data.toString('latin1').slice(0, 400))) { i = e + 9; continue; }
  for (const m of data.toString('latin1').matchAll(/\((?:\\.|[^\\()])*\)/g)) {
    chunks.push(m[0].slice(1, -1).replace(/\\([()\\])/g, '$1')
      .replace(/\\(\d{1,3})/g, (_, o) => String.fromCharCode(parseInt(o, 8))));
  }
  i = e + 9;
}
// embedded font programs leave unreadable runs between pages; keep the printable ones
const text = chunks.join('').split(/[^\x20-\x7E]+/).filter((s) => s.trim().length > 2)
  .join(' ').replace(/\s+/g, ' ');

if (!/FINAL LIST OF CANCELED ELECTIONS/.test(text)) {
  throw new Error('this PDF does not say FINAL LIST OF CANCELED ELECTIONS — a tentative list is served from a nearly identical URL');
}
if (!/INSUFFICIENCY OF CANDIDATES/.test(text)) throw new Error('the cancellation reason heading is missing');

// ── parse the entries ──
const HEADINGS = ['COMMUNITY COLLEGE DISTRICTS', 'HIGH SCHOOL DISTRICTS', 'UNIFIED SCHOOL DISTRICTS',
  'ELEMENTARY SCHOOL DISTRICTS', 'GENERAL DISTRICTS', 'CITIES'];
const entries = [];
const body = text.slice(text.indexOf('INSUFFICIENCY OF CANDIDATES'));

// 🔴🔴 BOUND THE PARSE BY THE DOCUMENT'S OWN STRUCTURE. A first draft walked the whole body
//   with one regex that allowed a district name up to 40 characters. "TES COMMUNITY COLLEGE
//   DISTRICTS Cerritos" is exactly 40, so the name SWALLOWED THE HEADING, and because the
//   leftmost match wins it beat the heading alternative that started four characters later.
//   The entire COMMUNITY COLLEGE DISTRICTS section vanished — 8 districts, 13 seats — and
//   every one of them was then reported as "not on the cancelled list", which reads as a
//   finding about the county's document rather than about this parser.
//   ▶ Split on the headings FIRST, then read entries inside each section, bounded by the
//     document's own parentheses rather than by a character budget.
const splitRe = new RegExp(`(${HEADINGS.join('|')})`, 'g');
const parts = body.split(splitRe);
for (let i = 1; i < parts.length; i += 2) {
  const section = parts[i];
  // within a section every entry ends at a ')', so cut there and take the text before the '('
  for (const piece of parts[i + 1].split(')')) {
    const p = piece.indexOf('(');
    if (p < 0) continue;
    const name = piece.slice(0, p)
      .replace(/Page \d+ of \d+/g, '')            // page furniture runs into the first name of a page
      .replace(/^[\s A-Z]*(?=[A-Z][a-z])/, '')   // drop a sub-heading like "COUNTY WATER DISTRICTS"
      .trim().replace(/\*$/, '').trim();
    const inside = piece.slice(p + 1);
    if (!name || !/^[A-Z]/.test(name)) continue;
    // "1, 2, and 5" -> 1, 2, 5. The "and" form was dropping the LAST area of every entry
    // that had three or more, which silently lost 11 real seats.
    // "C, E, and B U/T ending 12/28" -> C, E, B: the last area carries the UNEXPIRED term and
    // its trailing words are part of the same list item, not a separate one.
    const areas = [...inside.matchAll(/(?:Trustee Area|Division|District)\s+([A-Z0-9][^)]*)/g)]
      .flatMap((a) => a[1].replace(/\s+and\s+/g, ', ').split(/\s*,\s*/)
        .map((x) => /^([A-Z0-9]+)(\s+U\/T\b.*)?$/.exec(x.trim())?.[1] ?? null).filter(Boolean));
    entries.push({ section, name, inside, areas, fullTerm: /Full Term/i.test(inside) });
    // ⚠ ONE SCHOOL SEAT IS FILED UNDER ITS CITY, NOT UNDER A SCHOOL HEADING: the CITIES
    //   section carries "Pasadena (Pasadena Unified School Board of Education 5)". Emit it
    //   under the district's own name as well, or it reads as a seat the county never
    //   cancelled.
    const nested = /([A-Z][A-Za-z.' -]*?Unified)\s+School\s+(?:District\s+)?Board of Education\s+([A-Z0-9]+)/.exec(inside);
    if (nested) entries.push({ section, name: nested[1], inside, areas: [nested[2]], fullTerm: false });
  }
}
if (entries.length < 80) throw new Error(`parsed only ${entries.length} cancelled entries — the list has more`);
const sections = new Set(entries.map((e) => e.section));
for (const h of HEADINGS) if (!sections.has(h)) throw new Error(`the parser found no entries under "${h}" — a whole section was lost`);

// 🔴 positive controls before any "not on the list" is believed: one plain entry, one whose
//   area is the last of three (the "and" case), and one from the section the first draft lost
for (const [who, ok] of [
  ['Azusa Trustee Area 3', entries.some((e) => e.name === 'Azusa' && e.areas.includes('3'))],
  ['Centinela Valley Union Trustee Area 5 (the "and" case)', entries.some((e) => e.name === 'Centinela Valley Union' && e.areas.includes('5'))],
  ['Cerritos Trustee Area 7 (community colleges)', entries.some((e) => e.name === 'Cerritos' && e.areas.includes('7'))],
]) {
  if (!ok) throw new Error(`the parser cannot see ${who}, which the document plainly lists — every "not found" below would be vacuous`);
}

// ── our side ──
// ⚠ our labels say "Trustee Area N", "Division N" AND "District N" — Pasadena Unified is the
//   one that says District, and reading only the first two left its whole label as the name.
const strip = (label) => {
  const area = /\s-\s(?:Trustee Area|Division|District)\s+([A-Z0-9]+)\s*$/.exec(label)?.[1] ?? null;
  let name = label.replace(/\s-\s(?:Trustee Area|Division|District)\s+[A-Z0-9]+\s*$/, '')
    .replace(/\s*(Unified|Elementary|High|Community College)?\s*(School)?\s*Board(\s*of\s*Education)?\s*$/i, '')
    .replace(/\s*(Unified|Elementary|High|Community College)\s*$/i, '')
    .trim();
  return { name, area };
};
const key = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, '');
// the PDF abbreviates some names ("Acton-Agua" for Acton-Agua Dulce); accept a prefix either way
const nameMatches = (ours, theirs) => {
  const a = key(ours); const b = key(theirs);
  return a === b || a.startsWith(b) || b.startsWith(a);
};

const unmatched = analysis.report.filter((r) => !r.anchor);
const found = [];
const missing = [];
for (const r of unmatched) {
  const { name, area } = strip(r.district);
  const hit = entries.find((e) => nameMatches(name, e.name)
    && (area ? e.areas.includes(area) : e.fullTerm || e.areas.length === 0));
  if (hit) found.push({ race: r.district, as: `${hit.section}: ${hit.name} (${hit.inside})` });
  else missing.push({ race: r.district, looked_for: `${name}${area ? ' / area ' + area : ' / full term'}` });
}

console.log(`LA County FINAL list parsed: ${entries.length} cancelled entries across ${new Set(entries.map((e) => e.section)).size} sections`);
console.log(`our races with no county contest: ${unmatched.length}`);
console.log(`  ✔ named on the cancelled list: ${found.length}`);
console.log(`  ✘ NOT on the cancelled list:   ${missing.length}`);
for (const m of missing) console.log(`      ${m.race}   (looked for ${m.looked_for})`);

// the reverse direction: cancelled school seats the county names and we hold no race for.
// It is a different question — a gap in our data, not in this one — so it is only reported.
const SCHOOL_SECTIONS = new Set(['COMMUNITY COLLEGE DISTRICTS', 'HIGH SCHOOL DISTRICTS',
  'UNIFIED SCHOOL DISTRICTS', 'ELEMENTARY SCHOOL DISTRICTS']);
const ourNames = analysis.report.map((r) => strip(r.district));
let unheld = 0;
for (const e of entries.filter((x) => SCHOOL_SECTIONS.has(x.section))) {
  const slots = e.areas.length ? e.areas : [null];
  for (const a of slots) {
    const held = ourNames.some((o) => nameMatches(o.name, e.name) && (a ? o.area === a : o.area === null));
    if (!held) unheld++;
  }
}
console.log(`\ncancelled school seats the county lists that we hold no 2026-12-11 race for: ${unheld}`);
console.log('  (a seeding question, not a results one — reported, not acted on)');
process.exit(missing.length ? 1 : 0);

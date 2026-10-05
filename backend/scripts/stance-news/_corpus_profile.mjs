// Profile a swept corpus BEFORE reading it. Usage: node _corpus_profile.mjs <slug> "Full Name" [alias ...]
//
// Four measurements, each one a rule that has already cost a real failure in this programme:
//
//  1. 🔴 KEY-COLLISION LOSS — `_index.json` length vs files on disk. The Saint Paul sweep lost 86 of
//     342 articles (25%) to a truncated filename key and NOTHING WARNED. The corpus looked complete.
//  2. 🔴 NOISE RATIO — how many files contain the FULL name, not just the surname. The keep-filter
//     matches the surname alone and cannot see this: Janet Kennedy's corpus was 359 files of which
//     23 named her (94% noise — RFK Jr., JFK, Justice Kennedy, the Kennedy Center).
//  3. 🔴 AMBIGUITY — files naming a DIFFERENT person with the same surname. A bare-surname
//     attribution in those files cannot be trusted and must come from a labelled block.
//  4. OUTLET SPREAD — an outlet listed as working that contributed nothing is blind, not empty.
//     Minnesota Reformer contributed zero to the original Saint Paul sweep because the tool sent a
//     Chrome UA, which Reformer 403s, and the error was swallowed.
//
// It also counts campaign-era material, which the ruling of 2026-10-05 made admissible.
import fs from 'node:fs';
import path from 'node:path';

const SLUG = process.argv[2];
const NAMES = process.argv.slice(3);
if (!SLUG || !NAMES.length) { console.error('usage: _corpus_profile.mjs <slug> "Full Name" [alias ...]'); process.exit(1); }
const DIR = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
const SURNAME = NAMES[0].split(/\s+/).pop();

const idx = JSON.parse(fs.readFileSync(path.join(DIR, '_index.json'), 'utf8'));
const files = fs.readdirSync(DIR).filter((f) => f.endsWith('.txt'));

console.log(`\n=== ${SLUG} :: ${NAMES.join(' | ')}`);
console.log(`1. KEY COLLISIONS   named ${idx.length} | on disk ${files.length} | ${idx.length === files.length ? '✅ none lost' : `🔴 ${idx.length - files.length} LOST`}`);

// Sentence-starters that are not first names — without this stoplist the ambiguity filter excluded
// almost everything and produced a false zero of its own.
const STOP = new Set(['In', 'When', 'Like', 'And', 'But', 'The', 'If', 'As', 'At', 'For', 'With',
  'Councilmember', 'Councilor', 'Council', 'Member', 'President', 'Vice', 'Mayor', 'Ward', 'District',
  'Said', 'Says', 'After', 'Before', 'Both', 'That', 'This', 'While', 'Since', 'Where', 'Though']);
const otherRe = new RegExp(`([A-Z][a-z]+|[A-Z]\\.(?:\\s?[A-Z]\\.)?)\\s+${SURNAME}\\b`, 'g');

let full = 0, surnameOnly = 0, ambiguous = 0, campaign = 0;
const outlets = new Map();
const byUrl = new Map(idx.map((e) => [e.url, e]));
const CAMP = /\b(candidate|candidacy|campaign trail|running for|endorse[sd]|endorsement|candidate forum|questionnaire|voter guide)\b/i;

for (const f of files) {
  const t = fs.readFileSync(path.join(DIR, f), 'utf8');
  const hasFull = NAMES.some((n) => t.includes(n));
  if (hasFull) full++; else if (t.includes(SURNAME)) surnameOnly++;
  if (hasFull) {
    const others = new Set();
    for (const m of t.matchAll(otherRe)) {
      const first = m[1];
      if (STOP.has(first)) continue;
      if (NAMES.some((n) => n.endsWith(`${first} ${SURNAME}`) || n.includes(first))) continue;
      others.add(first);
    }
    if (others.size) ambiguous++;
    if (CAMP.test(t)) campaign++;
  }
}
console.log(`2. NOISE RATIO      ${full} of ${files.length} files name "${NAMES[0]}" (${Math.round((full / Math.max(files.length, 1)) * 100)}% signal) | ${surnameOnly} carry only the surname "${SURNAME}"`);
if (full && full / files.length < 0.35) console.log(`   🔴 HIGH NOISE — the keep-filter matched the surname alone. Read only the ${full} that name her.`);
console.log(`3. AMBIGUITY        ${ambiguous} of the ${full} also name a DIFFERENT <First> ${SURNAME} — no bare-surname attribution in those`);
console.log(`4. CAMPAIGN-ERA     ${campaign} of the ${full} carry candidate/campaign language (admissible since the ruling 2026-10-05)`);

for (const e of idx) outlets.set(e.outlet, (outlets.get(e.outlet) || 0) + 1);
console.log('5. OUTLET SPREAD');
for (const [k, v] of [...outlets].sort((a, b) => b[1] - a[1])) console.log(`     ${k.padEnd(26)} ${v}`);
const listed = ['minnpost.com', 'sahanjournal.com', 'minnesotareformer.com', 'twincities.com'];
for (const o of listed) if (!outlets.has(o)) console.log(`     🔴 ${o} CONTRIBUTED NOTHING — treat as blind, not empty`);
console.log(`\n   (MPR News and Racket are NOT covered by any sweep: MPR's article pages are not citable,`);
console.log(`    Racket's search is blind. Say so in the reasoning — do not claim to have covered them.)`);

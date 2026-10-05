// Attribute quotes to one member, safely for common surnames.
// Usage: node attribute.mjs <slug> "First Last"
import fs from 'node:fs';

// 🔴 This was a hardcoded absolute path into ONE session's scratchpad, which is deleted when that
// session ends — the script then reads nothing and reports a clean zero. Corpus root is now an
// argument: SWEEP_OUT, or data/stance-news, the same default sweep_duluth.mjs writes to.
import path from 'node:path';
import { findAttributed, parseName, nameRe } from './attribution.mjs';

import crypto from 'node:crypto';
// 🔴🔴 Corpus filenames were base64url(url).slice(0, 60). 45 bytes of URL is not past a shared
// path prefix, so SIXTEEN Duluth News Tribune news articles wrote to ONE file and 50 named
// articles became 26 on disk — a corpus that looked complete and was half gone. Hash the WHOLE
// url. Any truncation of a key derived from a structured string collides where the structure is.
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);
const ROOT = process.env.SWEEP_OUT || 'data/stance-news';
const SLUG = process.argv[2];
const NAME = process.argv[3];
// argv[4]: extra first-name spellings, pipe-separated, e.g. "Hwa ?Jeong".
// A member's own name can be spelled more than one way, and the database spelling
// is not always the newsroom's: "HwaJeong Kim" found 8 articles, "Hwa Jeong Kim" 27.
const ALT = (process.argv[4] || '').trim();
const { first: FIRST, middles: MIDDLES, surname: SURNAME } = parseName(NAME);
const FIRSTRE = ALT ? `(?:${FIRST}|${ALT})` : FIRST;
// Middle tokens belong to the SAME person — forgive them in the ambiguity check below.
const OWNWORDS = new Set([FIRST, ...MIDDLES]);
const ALTWORDS = ALT ? ALT.split('|').map((s) => s.replace(/[^A-Za-z]/g, ' ').trim().split(/\s+/)).flat() : [];

const LQ = String.fromCharCode(8220), RQ = String.fromCharCode(8221);

// Words that can precede a surname at a sentence start without being a first name.
const STOP = new Set(['In', 'When', 'Like', 'But', 'And', 'The', 'For', 'If', 'As', 'At', 'With', 'That', 'This',
  'She', 'He', 'They', 'Also', 'Said', 'After', 'Before', 'Councilmember', 'Council', 'Member', 'Mayor', 'Ward',
  'Then', 'While', 'Though', 'Both', 'Her', 'His', 'Their', 'Of', 'To', 'On', 'By', 'From', 'So', 'Yet', 'Now',
  'President', 'Representative', 'Senator', 'Commissioner', 'Chair', 'Vice', 'Former', 'Incumbent', 'Candidate',
  // 🔴 The stoplist is a VOCABULARY, and it was Saint Paul's. Duluth's council title is "Councilor",
  // not "Councilmember" — that one word excluded 9 of 50 Randorf articles as "a different Randorf".
  // The rest are caption, nav and section labels that sit immediately before a name.
  'Councilor', 'Counselor', 'Alderman', 'Alderwoman', 'Supervisor', 'Trustee',
  'Councilors', 'Councilmembers', 'Members', 'Picture', 'Group', 'Submit', 'Video', 'Image',
  'Neither', 'Either', 'Nor', 'Because', 'Since', 'Although', 'However', 'Meanwhile', 'Still',
  // 🔴 'My Nephew' is the ordinary-word surname collision, capitalised. 'Support'/'Design' are
  // nav labels. A surname that is an ordinary English word needs these or it excludes itself.
  'My', 'Your', 'Our', 'Its', 'Support', 'Design', 'Photo', 'Read', 'Watch', 'Listen', 'Share',
  'Editors', 'Agenda', 'Glean', 'Is', 'Are', 'Was', 'Were', 'Has', 'Had', 'Will', 'Would', 'Can',
  'Contact', 'Newsletter', 'Team', 'Careers', 'Weather', 'Sports', 'Communities', 'Events',
  'Local', 'News', 'District', 'Vote', 'Business', 'Opinion', 'Editorial', 'Letters', 'Column',
  'Columns', 'Photo', 'Photos', 'Video', 'Subscribers', 'Sections', 'Tags', 'Share', 'Listen',
  'By', 'Elect', 'Re', 'Vice-President', 'Duluth', 'City', 'Third', 'Second', 'First', 'Fourth',
  'Fifth', 'At', 'Large', 'Northland', 'Minnesota', 'Our', 'View', 'Endorsement', 'Pro', 'Con']);

const idxFile = ['_index.json', '../' + SLUG + '-named.json'].map((n) => path.join(ROOT, SLUG, n)).find((p) => fs.existsSync(p));
if (!idxFile) { console.error('no corpus index under ' + path.join(ROOT, SLUG) + ' — run the sweep first'); process.exit(1); }
const named = JSON.parse(fs.readFileSync(idxFile, 'utf8'));
if (!named.length) { console.error('corpus index is EMPTY — that is a broken sweep, not a finding'); process.exit(1); }
const out = [];
let ambiguous = 0, clean = 0;
const others = new Set();

for (const a of named) {
  const f = path.join(ROOT, SLUG, corpusKey(a.url) + '.txt');
  let t;
  try { t = fs.readFileSync(f, 'utf8'); } catch { continue; }

  // Another real person with this surname? Ignore sentence-starter false positives.
  const fulls = new Set([...t.matchAll(new RegExp(`\\b([A-Z][a-z]+)\\s+${SURNAME}\\b`, 'g'))].map((m) => m[1]));
  for (const w of OWNWORDS) fulls.delete(w);
  for (const w of ALTWORDS) fulls.delete(w);
  for (const w of [...fulls]) if (STOP.has(w)) fulls.delete(w);
  if (fulls.size) { ambiguous++; for (const w of fulls) others.add(`${w} ${SURNAME}`); continue; }
  clean++;

  for (const q of findAttributed(t, FIRSTRE, MIDDLES, SURNAME)) out.push({ url: a.url, quote: q });
}

const seen = new Set(), uniq = [];
for (const o of out) { const k = o.quote.slice(0, 80); if (seen.has(k)) continue; seen.add(k); uniq.push(o); }

console.log(`articles naming "${NAME}": ${named.length}`);
console.log(`  excluded, a different ${SURNAME} present: ${ambiguous}${others.size ? ' -> ' + [...others].join(', ') : ''}`);
console.log(`  clean articles used: ${clean}`);
console.log(`attributed: ${out.length} | unique: ${uniq.length}`);
fs.writeFileSync(path.join(ROOT, SLUG, '_attributed.json'), JSON.stringify(uniq, null, 1));
uniq.forEach((o, i) => {
  console.log(`\n[${i + 1}] ${o.url.replace('https://www.', '').replace('https://', '').slice(0, 88)}`);
  console.log('    ' + o.quote.slice(0, 280));
});

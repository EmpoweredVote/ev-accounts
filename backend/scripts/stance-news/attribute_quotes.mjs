// Attribute quotes to one member, safely for common surnames.
// Usage: node attribute.mjs <slug> "First Last"
import fs from 'node:fs';

// 🔴 This was a hardcoded absolute path into ONE session's scratchpad, which is deleted when that
// session ends — the script then reads nothing and reports a clean zero. Corpus root is now an
// argument: SWEEP_OUT, or data/stance-news, the same default sweep_duluth.mjs writes to.
import path from 'node:path';
const ROOT = process.env.SWEEP_OUT || 'data/stance-news';
const SLUG = process.argv[2];
const NAME = process.argv[3];
// argv[4]: extra first-name spellings, pipe-separated, e.g. "Hwa ?Jeong".
// A member's own name can be spelled more than one way, and the database spelling
// is not always the newsroom's: "HwaJeong Kim" found 8 articles, "Hwa Jeong Kim" 27.
const ALT = (process.argv[4] || '').trim();
const [FIRST, ...rest] = NAME.split(/\s+/);
const SURNAME = rest.join(' ');
const FIRSTRE = ALT ? `(?:${FIRST}|${ALT})` : FIRST;
const ALTWORDS = ALT ? ALT.split('|').map((s) => s.replace(/[^A-Za-z]/g, ' ').trim().split(/\s+/)).flat() : [];

const LQ = String.fromCharCode(8220), RQ = String.fromCharCode(8221);
const VERB = 'said|says|told|added|argued|noted|explained|wrote|asked|countered|replied';

// Words that can precede a surname at a sentence start without being a first name.
const STOP = new Set(['In', 'When', 'Like', 'But', 'And', 'The', 'For', 'If', 'As', 'At', 'With', 'That', 'This',
  'She', 'He', 'They', 'Also', 'Said', 'After', 'Before', 'Councilmember', 'Council', 'Member', 'Mayor', 'Ward',
  'Then', 'While', 'Though', 'Both', 'Her', 'His', 'Their', 'Of', 'To', 'On', 'By', 'From', 'So', 'Yet', 'Now',
  'President', 'Representative', 'Senator', 'Commissioner', 'Chair', 'Vice', 'Former', 'Incumbent', 'Candidate']);

const idxFile = ['_index.json', '../' + SLUG + '-named.json'].map((n) => path.join(ROOT, SLUG, n)).find((p) => fs.existsSync(p));
if (!idxFile) { console.error('no corpus index under ' + path.join(ROOT, SLUG) + ' — run the sweep first'); process.exit(1); }
const named = JSON.parse(fs.readFileSync(idxFile, 'utf8'));
if (!named.length) { console.error('corpus index is EMPTY — that is a broken sweep, not a finding'); process.exit(1); }
const out = [];
let ambiguous = 0, clean = 0;
const others = new Set();

for (const a of named) {
  const f = path.join(ROOT, SLUG, Buffer.from(a.url).toString('base64url').slice(0, 60) + '.txt');
  let t;
  try { t = fs.readFileSync(f, 'utf8'); } catch { continue; }

  // Another real person with this surname? Ignore sentence-starter false positives.
  const fulls = new Set([...t.matchAll(new RegExp(`\\b([A-Z][a-z]+)\\s+${SURNAME}\\b`, 'g'))].map((m) => m[1]));
  fulls.delete(FIRST);
  for (const w of ALTWORDS) fulls.delete(w);
  for (const w of [...fulls]) if (STOP.has(w)) fulls.delete(w);
  if (fulls.size) { ambiguous++; for (const w of fulls) others.add(`${w} ${SURNAME}`); continue; }
  clean++;

  const re = new RegExp(`${LQ}([^${RQ}]{35,500})${RQ}`, 'g');
  const nm = `(?:${FIRST}\\s+)?${SURNAME}`;
  let m;
  while ((m = re.exec(t)) !== null) {
    const after = t.slice(m.index + m[0].length, m.index + m[0].length + 70);
    const before = t.slice(Math.max(0, m.index - 70), m.index);
    // The speech verb is REQUIRED. Making it optional attributed a school principal's
    // quote to Yang, because the NEXT SENTENCE merely began with her name.
    const tagA = new RegExp(`^[,.]?\\s*(?:${VERB})\\s+(?:council\\s*member\\s+|councilmember\\s+|council\\s+president\\s+)?${nm}`, 'i').test(after)
      || new RegExp(`^[,.]?\\s*${nm}\\s+(?:${VERB})`, 'i').test(after);
    const tagB = new RegExp(`${nm}\\s+(?:${VERB})[,:]?\\s*$`, 'i').test(before);
    if (tagA || tagB) out.push({ url: a.url, quote: m[1].trim() });
  }
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

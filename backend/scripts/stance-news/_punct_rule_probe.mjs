// What did the "a quote ending in a full stop is not followed by its own attribution" rule drop?
// Usage: node _punct_rule_probe.mjs <slug> "Full Name"
//
// The rule stopped a rec-centre worker's testimony being attributed to Council President Noecker.
// But it removed 24 of Mayor Her's 88 quotes, and a rule that discards a quarter of a member's
// real evidence is as damaging as the misattribution it prevents. This prints exactly what it
// dropped, with context, so the trade-off is read rather than assumed.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { parseName } from './attribution.mjs';

const SLUG = process.argv[2];
const NAME = process.argv[3];
const DIR = path.join(process.env.SWEEP_OUT || 'data/stance-news', SLUG);
const { first, middles, surname } = parseName(NAME);
const nm = `(?:${first}\\s+)?${(middles || []).map((m) => `(?:${m}\\s+)?`).join('')}${surname}`;
const VERB = 'said|says|told|added|argued|asked|wrote|noted|explained|replied|continued|responded|warned|stressed';
const Q = /[“"]([^”"]{40,})[”"]/g;

const idx = JSON.parse(fs.readFileSync(path.join(DIR, '_index.json'), 'utf8'));
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);
let dropped = 0;
for (const e of idx) {
  const f = path.join(DIR, key(e.url) + '.txt');
  if (!fs.existsSync(f)) continue;
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes(NAME)) continue;
  let m;
  Q.lastIndex = 0;
  while ((m = Q.exec(t)) !== null) {
    const inner = m[1].trim();
    if (!/[.!?]$/.test(inner)) continue;                 // only the ones the rule touches
    const after = t.slice(m.index + m[0].length, m.index + m[0].length + 70);
    if (!new RegExp(`^[,.]?\\s*${nm}\\s+(?:${VERB})`, 'i').test(after)
      && !new RegExp(`^[,.]?\\s*(?:${VERB})\\s+${nm}`, 'i').test(after)) continue;
    dropped++;
    console.log(`\n[${dropped}] ${e.url.replace(/^https?:\/\/(www\.)?/, '').slice(0, 86)}`);
    console.log(`  QUOTE: "${inner.slice(0, 150)}"`);
    console.log(`  AFTER: ${after.replace(/\s+/g, ' ').slice(0, 90)}`);
    const before = t.slice(Math.max(0, m.index - 170), m.index).replace(/\s+/g, ' ');
    console.log(`  BEFORE: …${before.slice(-150)}`);
  }
}
console.log(`\ndropped by the punctuation rule: ${dropped}`);

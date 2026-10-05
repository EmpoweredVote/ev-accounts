// Print each attributed quote with surrounding context, so attribution can be SETTLED by reading.
// Usage: node quote_context.mjs <slug> [n ...]      (no n = all)
// The strict attribution rule finds candidates safely; it does not settle them. README, Minnesota §3.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const SLUG = process.argv[2];
const PICK = process.argv.slice(3).map(Number);
const ROOT = process.env.SWEEP_OUT || 'data/stance-news';
const DIR = path.join(ROOT, SLUG);
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);
const q = JSON.parse(fs.readFileSync(path.join(DIR, '_attributed.json'), 'utf8'));
q.forEach((o, i) => {
  const n = i + 1;
  if (PICK.length && !PICK.includes(n)) return;
  const t = fs.readFileSync(path.join(DIR, corpusKey(o.url) + '.txt'), 'utf8');
  const at = t.indexOf(o.quote.slice(0, 60));
  console.log('='.repeat(78));
  console.log(`[${n}] ${o.url}`);
  console.log(t.slice(Math.max(0, at - 420), at + o.quote.length + 260).trim());
  console.log('');
});

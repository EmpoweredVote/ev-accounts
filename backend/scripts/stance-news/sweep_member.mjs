// Sweep one member using SEVERAL name spellings, merged.
// Usage: node sweep-aliases.mjs <slug> "Primary Name" "Alias One" "Alias Two" ...
import fs from 'node:fs';

import crypto from 'node:crypto';
// 🔴🔴 Corpus filenames were base64url(url).slice(0, 60). 45 bytes of URL is not past a shared
// path prefix, so SIXTEEN Duluth News Tribune news articles wrote to ONE file and 50 named
// articles became 26 on disk — a corpus that looked complete and was half gone. Hash the WHOLE
// url. Any truncation of a key derived from a structured string collides where the structure is.
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);

const P = 'C:/Users/Chris/AppData/Local/Temp/claude/C--EV-Accounts/e6365231-862e-4798-ba8d-61bcd06426c1/scratchpad/outlets/';
const SLUG = process.argv[2];
const NAMES = process.argv.slice(3);
const SURNAME = NAMES[0].split(/\s+/).pop();

const TOPICS = ['election 2020', 'child care', 'trash garbage sanitation', 'racial equity civil rights',
  'climate clean energy', 'data center', 'economic development subsidy', 'growth development', 'homelessness',
  'encampment shelter', 'affordable housing', 'environment pollution', 'immigration ICE', 'minimum wage',
  'police public safety', 'ranked choice voting', 'religious', 'zoning', 'rent stabilization', 'transit transportation'];

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36';
const LQ = String.fromCharCode(8220), RQ = String.fromCharCode(8221);

const wp = async (host, q) => {
  try {
    const r = await fetch(`https://${host}/wp-json/wp/v2/search?search=${encodeURIComponent(q)}&per_page=20`, { headers: { 'user-agent': UA } });
    if (!r.ok) return [];
    const a = await r.json();
    return (Array.isArray(a) ? a : []).map((x) => ({ url: x.url, outlet: host }));
  } catch { return []; }
};
const ref = async (q) => {
  try {
    const r = await fetch(`https://minnesotareformer.com/?s=${encodeURIComponent(q)}`, { headers: { 'user-agent': UA } });
    if (!r.ok) return [];
    const h = await r.text();
    return [...new Set([...h.matchAll(/href="(https:\/\/minnesotareformer\.com\/20\d\d\/[^"]+)"/g)].map((m) => m[1]))].map((u) => ({ url: u, outlet: 'minnesotareformer.com' }));
  } catch { return []; }
};
const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
  .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ')
  .replace(/&#8217;/g, String.fromCharCode(8217)).replace(/&#8220;/g, LQ).replace(/&#8221;/g, RQ)
  .replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();

const all = new Map();
for (const n of NAMES) for (const a of [...await wp('www.minnpost.com', n), ...await wp('sahanjournal.com', n), ...await ref(n)]) all.set(a.url, a);
const nameOnly = all.size;
for (const n of NAMES) for (const v of TOPICS) {
  for (const a of [...await wp('www.minnpost.com', `${n} ${v}`), ...await wp('sahanjournal.com', `${n} ${v}`)]) all.set(a.url, a);
  process.stdout.write('.');
}
console.log(`\nspellings: ${NAMES.join(' | ')}`);
console.log(`name-only: ${nameOnly} | corpus unique: ${all.size}`);

fs.mkdirSync(P + SLUG, { recursive: true });
const queue = [...all.values()];
const named = [];
let ok = 0, bad = 0;
async function worker() {
  while (queue.length) {
    const a = queue.shift();
    try {
      const r = await fetch(a.url, { headers: { 'user-agent': UA } });
      if (!r.ok) { bad++; continue; }
      const t = strip(await r.text());
      ok++;
      if (NAMES.some((n) => t.includes(n))) {
        named.push({ ...a });
        fs.writeFileSync(`${P}${SLUG}/${corpusKey(a.url)}.txt`, t);
      }
    } catch { bad++; }
  }
}
await Promise.all([...Array(6)].map(worker));
console.log(`fetched ${ok} | failed ${bad} | naming any spelling: ${named.length}`);
fs.writeFileSync(`${P}${SLUG}-named.json`, JSON.stringify(named, null, 1));

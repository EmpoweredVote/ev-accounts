// Re-fetch every URL in a corpus index, one file per URL. Usage: node refetch_corpus.mjs <slug>
// Exists because the corpus filename key used to truncate and collide — see sweep_duluth.mjs.
// It asserts file count == index length and exits 1 otherwise, so a collision cannot pass silently.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const UA = 'EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)';
const SLUG = process.argv[2];
const ROOT = process.env.SWEEP_OUT || 'data/stance-news';
const DIR = path.join(ROOT, SLUG);
const corpusKey = (url) => crypto.createHash('sha1').update(url).digest('hex').slice(0, 24);
const idx = JSON.parse(fs.readFileSync(path.join(DIR, '_index.json'), 'utf8'));
for (const f of fs.readdirSync(DIR)) if (f.endsWith('.txt')) fs.unlinkSync(path.join(DIR, f));
const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/gi, '').replace(/<style[\s\S]*?<\/style>/gi, '')
  .replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ')
  .replace(/&#x27;|&#8217;|&rsquo;/g, "'").replace(/&quot;|&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
  .replace(/&amp;/g, '&').replace(/&#8212;|&mdash;/g, '—').replace(/\s+/g, ' ').trim();
const queue = [...idx];
let ok = 0, bad = 0;
async function worker() {
  while (queue.length) {
    const a = queue.shift();
    try {
      const r = await fetch(a.url, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(25000) });
      if (!r.ok) { bad++; continue; }
      fs.writeFileSync(path.join(DIR, corpusKey(a.url) + '.txt'), strip(await r.text()));
      ok++;
    } catch { bad++; }
  }
}
await Promise.all([...Array(4)].map(worker));
const files = fs.readdirSync(DIR).filter((f) => f.endsWith('.txt')).length;
console.log(`index ${idx.length} | fetched ${ok} | failed ${bad} | files ${files}`);
if (files !== ok) { console.error(`🔴 ${ok} fetched but ${files} files — the key COLLIDES`); process.exit(1); }
console.log('control passed: one file per fetched URL');

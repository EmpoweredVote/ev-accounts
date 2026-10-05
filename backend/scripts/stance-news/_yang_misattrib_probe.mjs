// Why did 18 of Nelsie Yang's 34 attributed quotes come from articles that never name her?
// Specifically: an article about KAYING Yang, a different person entirely.
//
// The ambiguity check should have excluded that article. Two candidate causes:
//   (a) isTitleCase (added 2026-10-05) suppressed the "Kaying Yang" pair as a headline, or
//   (b) the check never saw it, because the pair only appears in a form the regex misses.
// This tells them apart.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const DIR = 'data/stance-news/yang';
const key = (u) => crypto.createHash('sha1').update(u).digest('hex').slice(0, 24);

function isTitleCase(text, i, len) {
  const before = text.slice(Math.max(0, i - 60), i).split(/\s+/).filter(Boolean).slice(-4);
  const after = text.slice(i + len, i + len + 60).split(/\s+/).filter(Boolean).slice(0, 4);
  const words = [...before, ...after].filter((w) => /^[A-Za-z]{4,}$/.test(w));
  if (words.length < 3) return false;
  const caps = words.filter((w) => /^[A-Z]/.test(w)).length;
  return caps / words.length >= 0.75;
}

const att = JSON.parse(fs.readFileSync(path.join(DIR, '_attributed.json'), 'utf8'));
const urls = [...new Set(att.map((a) => a.url))];
let offenders = 0;

for (const u of urls) {
  const f = path.join(DIR, key(u) + '.txt');
  if (!fs.existsSync(f)) { console.log(`?? no file for ${u}`); continue; }
  const t = fs.readFileSync(f, 'utf8');
  if (t.includes('Nelsie Yang')) continue;
  offenders++;
  const kept = new Set(), suppressed = new Set();
  for (const m of t.matchAll(/\b([A-Z][a-z]+)\s+(?:[A-Z]\.\s+){0,2}Yang\b/g)) {
    if (isTitleCase(t, m.index, m[0].length)) suppressed.add(m[1]); else kept.add(m[1]);
  }
  console.log(`\n🔴 ${u.slice(0, 92)}`);
  console.log(`   names "Nelsie Yang": NO`);
  console.log(`   pairs KEPT by the check (would exclude the article): ${[...kept].slice(0, 10).join(', ') || '(NONE — the check saw nothing)'}`);
  console.log(`   pairs SUPPRESSED as title-case: ${[...suppressed].slice(0, 10).join(', ') || '(none)'}`);
  const quotes = att.filter((a) => a.url === u).length;
  console.log(`   quotes wrongly attributed from it: ${quotes}`);
}
console.log(`\narticles contributing quotes that never name her: ${offenders} of ${urls.length}`);

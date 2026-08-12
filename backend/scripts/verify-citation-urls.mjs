#!/usr/bin/env node
/**
 * Fetch EVERY citation URL a generated migration is about to write and confirm the page carries the
 * thing the row cites it for.
 *
 * 🔴 THE RULE THIS ENFORCES: never cite an unfetched URL, and a 200 is not identity confirmation.
 * Both halves matter — mig 1519's near-miss was a page that resolved fine and was about a different
 * person. So this checks status AND content: the bill designator must appear on the page.
 *
 *   node scripts/verify-citation-urls.mjs --sql <migration.sql>
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const SQL = flag('--sql');
if (!SQL) { console.error('need --sql'); process.exit(2); }

const sql = fs.readFileSync(SQL, 'utf8');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Pair each UPDATE's source URLs with the bill designators named in the same statement's reasoning.
const stmts = sql.split(/\nUPDATE inform\.politician_context/).slice(1);
const jobs = [];
for (const s of stmts) {
  const urls = [...s.matchAll(/'(https?:\/\/[^']+)'/g)].map((m) => m[1]);
  const bills = [...s.matchAll(/\b([HS])\.?\s?(R|Con\.?\s?Res|Res|J\.?\s?Res)?\.?\s?(\d{1,5})\b/g)]
    .map((m) => ({ chamber: m[1], kind: (m[2] || '').replace(/[^A-Za-z]/g, ''), num: m[3] }));
  for (const u of urls) jobs.push({ url: u, bills });
}
const seen = new Set();
const uniq = jobs.filter((j) => { const k = j.url; if (seen.has(k)) return false; seen.add(k); return true; });
console.log(`${uniq.length} distinct citation URL(s) to verify\n`);

let bad = 0;
for (const j of uniq) {
  const res = await fetch(j.url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
  const body = await res.text();
  // Which of the statement's bills does this page actually carry? A roll-call page names exactly one.
  const carried = j.bills.filter((b) => new RegExp(`\\b${b.chamber}\\.?\\s?(R\\.?|Con\\.?\\s?Res\\.?|Res\\.?|J\\.?\\s?Res\\.?)?\\s?${b.num}\\b`, 'i').test(body)
    || new RegExp(`>\\s*${b.chamber}\\s*(R|CON RES|RES)?\\s*${b.num}\\s*<`, 'i').test(body));
  const ok = res.ok && body.length > 5000 && carried.length > 0;
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'BAD '} ${res.status} ${String(body.length).padStart(7)}b  carries=[${carried.map((c) => c.chamber + (c.kind || 'R') + c.num).join(',') || 'NONE'}]  ${j.url}`);
  await sleep(600);
}
console.log(`\n${bad ? `🔴 ${bad} URL(s) failed — do not commit` : '✅ every citation URL resolves and names a bill from its own row'}`);
process.exit(bad ? 1 : 0);

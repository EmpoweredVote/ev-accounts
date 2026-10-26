#!/usr/bin/env node
// The detector the wrong-bill pass owes: compare the OFFICIAL TITLE of each cited Massachusetts
// bill page against the prose of the row that cites it.
//
// Why a title sweep and not a number comparison: when a row is miscited, the prose and the link
// carry the SAME wrong number, so any check that compares the two halves agrees with itself and is
// blind. Only the page's own title disagrees.
//
// This is a READING QUEUE, not a gate. Low overlap is a reason to open the page, not a verdict:
// a row can legitimately cite a bill it never names (a roll call backing a sentence about a vote).
import { readFileSync } from 'node:fs';

const dir = process.argv[2];
const cites = JSON.parse(readFileSync(`${dir}/ma-citations.json`, 'utf8'));

const titles = new Map();
for (const line of readFileSync(`${dir}/ma-bill-titles.tsv`, 'utf8').split('\n')) {
  if (!line.trim()) continue;
  const [path, code, header, title] = line.split('\t');
  titles.set(path, { code, header: (header || '').trim(), title: (title || '').trim() });
}

// Words that carry no identity: every Massachusetts bill title starts "An Act relative to ...".
const STOP = new Set(('an act relative to the of and for in a by on or with concerning further ' +
  'providing establishing certain matters authorizing an relating regarding said that this ' +
  'commonwealth general laws massachusetts city town').split(' '));

const words = s => (s.toLowerCase().match(/[a-z]{3,}/g) || []).filter(w => !STOP.has(w));

const rows = [];
for (const c of cites) {
  const t = titles.get(c.bill_path);
  if (!t) { rows.push({ ...c, verdict: 'NOT_FETCHED' }); continue; }
  if (t.code !== '200') { rows.push({ ...c, ...t, verdict: `HTTP_${t.code}` }); continue; }
  const tw = [...new Set(words(t.title))];
  const prose = c.reasoning.toLowerCase();
  const hit = tw.filter(w => prose.includes(w));
  const isOrder = /^\s*Order\b/.test(t.header);
  rows.push({
    ...c, ...t,
    title_words: tw.length,
    matched: hit.length,
    ratio: tw.length ? hit.length / tw.length : 1,
    verdict: isOrder ? 'CITES_AN_ORDER' : (tw.length === 0 ? 'NO_TITLE' : (hit.length === 0 ? 'NO_OVERLAP' : 'ok')),
  });
}

const flagged = rows.filter(r => r.verdict !== 'ok');
const byVerdict = {};
for (const r of rows) byVerdict[r.verdict] = (byVerdict[r.verdict] || 0) + 1;

console.log('citations examined :', rows.length);
console.log('distinct bills     :', new Set(rows.map(r => r.bill_path)).size);
for (const [k, v] of Object.entries(byVerdict).sort((a, b) => b[1] - a[1])) console.log(`  ${k.padEnd(16)} ${v}`);

console.log('\n--- NO_OVERLAP / CITES_AN_ORDER, worst first (the reading queue) ---');
for (const r of flagged.filter(r => r.verdict === 'CITES_AN_ORDER' || r.verdict === 'NO_OVERLAP')
                      .sort((a, b) => (a.ratio ?? 0) - (b.ratio ?? 0)).slice(0, 60)) {
  console.log(`${r.verdict}  ${r.bill_path}  [${r.topic_key} ${r.value}${r.is_s2 ? ' S2' : ' S1'}]  ${r.full_name}`);
  console.log(`    page : ${r.title}`);
  console.log(`    prose: ${r.reasoning.replace(/\s+/g, ' ').slice(0, 170)}`);
}

// a low but non-zero overlap is the next band worth reading
const weak = rows.filter(r => r.verdict === 'ok' && r.ratio <= 0.2);
console.log(`\n--- weak overlap (ratio <= 0.20): ${weak.length} citations ---`);
for (const r of weak.sort((a, b) => a.ratio - b.ratio).slice(0, 25)) {
  console.log(`${(r.ratio).toFixed(2)}  ${r.bill_path}  [${r.topic_key}]  ${r.full_name}  :: ${r.title}`);
}

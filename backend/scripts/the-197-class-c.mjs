#!/usr/bin/env node
/**
 * Class C of "the 197" — the TEMPLATE rows. One sentence, filled in per legislator, over a source
 * that never mentions the topic:
 *   "X co-sponsored civil rights legislation including anti-discrimination protections —
 *    strong supporter of civil rights expansion in <County>."
 *
 * 🔑 WHAT MAKES THIS A CLASS AND NOT A COINCIDENCE: the same skeleton recurs across unrelated
 * legislators with only the name and county swapped. A claim that generic cannot have come from
 * reading a source. Detect it by SHAPE — short, no instrument, no date, no quote, and built from a
 * small stock vocabulary — then read every hit, because the shape catches honest short rows too.
 *
 * 🔴 Reads only. Emits a reading queue.
 *   node scripts/the-197-class-c.mjs
 */
import fs from 'node:fs';

const G = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197.json', 'utf8'));
const CB = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-class-b.json', 'utf8'));
const { extractInstruments } = await import('./lib/md-instruments.mjs');

// already dispositioned in migs 1710 / 1711
const DONE = new Set([
  ...CB.class_b.map((r) => `${r.politician_id}|${r.topic_id}`),
  ...JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-fed-rollback.json', 'utf8')).rows.map((r) => `${r.pid}|${r.tid}`),
  ...JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-class-b-rollback.json', 'utf8')).rows.map((r) => `${r.pid}|${r.tid}`),
]);

// The stock vocabulary the template is assembled from.
const STOCK = /co-?sponsored|backs?|backed|supports?|supported|champion|consistent(ly)?|strong supporter|has been an? (active |vocal )?(supporter|advocate|champion)/i;
const TOPICWORDS = /civil rights|anti-?discrimination|racial equity|LGBTQ?\+? (protections|rights)|marriage equality|equal rights|protections for/i;
const HASDATE = /\b(19|20)\d\d\b/;
const HASQUOTE = /["'“”]/;

const rows = G.rows
  .filter((r) => !DONE.has(`${r.politician_id}|${r.topic_id}`))
  .map((r) => {
    const why = (r.reasoning || '').replace(/\s+/g, ' ');
    return { ...r, why, instruments: extractInstruments(why), words: why.split(/\s+/).length };
  });

const isTemplate = (r) => !r.instruments.length && !HASDATE.test(r.why) && !HASQUOTE.test(r.why)
  && r.words <= 45 && STOCK.test(r.why) && TOPICWORDS.test(r.why);

const classC = rows.filter(isTemplate);
const nearMiss = rows.filter((r) => !isTemplate(r) && !r.instruments.length && r.words <= 45 && STOCK.test(r.why));

console.log(`undispositioned rows: ${rows.length}`);
console.log(`  · TEMPLATE shape (class C): ${classC.length}`);
console.log(`  · short + stock verb but no topic vocabulary (near-miss, read too): ${nearMiss.length}\n`);

const show = (list, title) => {
  console.log(`\n${'='.repeat(80)}\n${title}\n${'='.repeat(80)}`);
  let i = 0;
  for (const r of list.sort((a, b) => a.full_name.localeCompare(b.full_name))) {
    const host = new URL(r.article).hostname.replace('en.wikipedia.org', 'WP').replace('ballotpedia.org', 'BP');
    console.log(`[${String(++i).padStart(2)}] ${r.full_name} | ${r.topic} | chair ${r.answer_value} | ${host} | ${r.words}w`);
    console.log(`     ${r.why}`);
  }
};
show(classC, 'CLASS C — TEMPLATE ROWS');
show(nearMiss, 'NEAR-MISS — short + stock verb, different topic vocabulary');

fs.writeFileSync('data/stance-retirement/2026-08-12-the-197-class-c.json',
  JSON.stringify({ pass: 'class C — template rows',
    caveat: 'A READING QUEUE. The shape catches honest short rows too, and the MD corpus indexes '
          + 'SPONSORS ONLY, so it cannot disprove a CO-sponsorship claim.',
    n_template: classC.length, n_near_miss: nearMiss.length, class_c: classC, near_miss: nearMiss }, null, 1));
console.log(`\nwrote data/stance-retirement/2026-08-12-the-197-class-c.json`);

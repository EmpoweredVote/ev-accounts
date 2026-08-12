#!/usr/bin/env node
/**
 * Class B of "the 197" — rows whose OWN REASONING declares that no evidence was found.
 *
 * 🔑 THE TEST IS NOT THE PHRASE, IT IS WHAT THE PHRASE DOES. "No evidence" appears in two opposite
 * kinds of row:
 *   - NARROWING, and legitimate: McClain / Same-Sex Marriage says "no record was found of her
 *     seeking to prohibit same-sex marriage" to pick between chairs 4 and 5 — on a row carried by a
 *     recorded NAY vote. The absence refines a conclusion the evidence already supports.
 *   - LOAD-BEARING, and the defect: Wicker / Campaign Finance says "No bill sponsorships or floor
 *     statements on tightening campaign finance were found" and then states a chair anyway. The
 *     absence IS the argument.
 * So: flag on an absence phrase, then require that the row names NO instrument and cites nothing
 * but the encyclopaedia bio — and then READ every hit. This is a reading queue.
 *
 * 🔴 Reads only.
 *   node scripts/the-197-class-b.mjs
 */
import fs from 'node:fs';

const G = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197.json', 'utf8'));
const ONPAGE = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-claim-on-page.json', 'utf8'));
const { extractInstruments } = await import('./lib/md-instruments.mjs');

const onpage = new Map(ONPAGE.rows.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));

// Deliberately broad — precision comes from reading, not from the regex.
const ABSENCE = /\bno (specific|direct|clear|strong|evidence|record|authored|bill|public|documented|[A-Za-z]+ )?[a-z ]{0,40}?(was |were )?(found|located|identified)\b|\bno evidence\b|\bnot found\b|\bhas not (introduced|advocated|publicly|co-?sponsored)\b|\bno [a-z ]{0,30}record of\b|\bdocument no\b|\bstance inferred\b|\bno clear public position\b/i;
// Words that mark the sentence as INFERENCE rather than evidence.
const INFER = /\b(suggest|suggests|indicate|indicates|imply|implies|implying|likely|most likely|would|aligns? with|consistent with|reflects?|inferred|typically|generally)\b/i;

const rows = G.rows.map((r) => {
  const why = (r.reasoning || '').replace(/\s+/g, ' ');
  const instruments = extractInstruments(why);
  const op = onpage.get(`${r.politician_id}|${r.topic_id}`);
  return { ...r, why, instruments,
    absence: ABSENCE.test(why), infers: INFER.test(why),
    page_class: op?.class, strong_hits: op?.strong_hits || [] };
});

const hits = rows.filter((r) => r.absence);
const classB = hits.filter((r) => !r.instruments.length);
const withInstr = hits.filter((r) => r.instruments.length);

console.log(`absence phrase present: ${hits.length} of ${rows.length}`);
console.log(`  · names no instrument (CLASS B candidates): ${classB.length}`);
console.log(`  · names an instrument (read separately): ${withInstr.length}\n`);

const show = (list, title) => {
  console.log(`\n${'='.repeat(78)}\n${title}\n${'='.repeat(78)}`);
  let i = 0;
  for (const r of list.sort((a, b) => a.full_name.localeCompare(b.full_name))) {
    console.log(`\n[${++i}] ${r.full_name} | ${r.topic} | chair ${r.answer_value}`);
    console.log(`    page: ${r.page_class}${r.strong_hits.length ? '  hits=' + r.strong_hits.slice(0, 4).join(' ; ') : ''}`);
    console.log(`    srcs: ${JSON.stringify(r.sources)}`);
    console.log(`    infers: ${r.infers}${r.instruments.length ? '  instruments: ' + r.instruments.join(', ') : ''}`);
    console.log(`    why:  ${r.why}`);
  }
};
show(classB, 'CLASS B CANDIDATES — absence declared, no instrument named');
show(withInstr, 'ABSENCE PHRASE BUT NAMES AN INSTRUMENT — check whether the absence is narrowing');

fs.writeFileSync('data/stance-retirement/2026-08-12-the-197-class-b.json',
  JSON.stringify({ pass: 'class B candidates — self-declared absence', n: classB.length,
    caveat: 'A READING QUEUE. 1678 retired 82 of 1,055 on this same test.',
    class_b: classB, absence_with_instrument: withInstr }, null, 1));
console.log(`\nwrote data/stance-retirement/2026-08-12-the-197-class-b.json`);

#!/usr/bin/env node
/**
 * Audit what migration 1685 actually attached: does each cited bill correspond to the instrument the
 * row's reasoning NAMES?
 *
 * WHY THIS EXISTS: sponsorship matching proved the legislator sponsored the bill. It did NOT prove the
 * bill is the one the reasoning is talking about. Two ways that can fail:
 *   1. BARE BILL NUMBER IS AMBIGUOUS ACROSS SESSIONS. "HB0810" is "Exploitation of Vulnerable Adults"
 *      in 2014RS and "Economic Development Tax Credit" in 2015RS. Matching a number over 14 sessions
 *      and then confirming sponsorship can attach a real-but-unrelated bill.
 *   2. A LOOSE act-name match (token-subset) can land on a differently-named bill.
 *
 * Verdicts per attached citation:
 *   TITLE_CARRIES_ACT  - the act name from the reasoning is in the bill title (strongest)
 *   NUMBER_AND_YEAR    - bill number matches AND the reasoning's stated year matches the session
 *   NUMBER_ONLY        - number matches but the reasoning names a different year -> SUSPECT
 *   NO_FIT             - neither -> SUSPECT
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const wl = JSON.parse(fs.readFileSync(flag('--worklist'), 'utf8'));
const sp = JSON.parse(fs.readFileSync(flag('--sponsorship'), 'utf8'));

const norm = (s) => s.toLowerCase().replace(/[‘’']/g, '').replace(/[^a-z0-9 ]+/g, ' ')
  .replace(/\bmarylands?\b/g, ' ').replace(/\bof \d{4}\b/g, ' ').replace(/\s+/g, ' ').trim();

const wlByKey = new Map(wl.rows.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));
const applied = sp.rows.filter((r) => r.verdict === 'SPONSOR_CONFIRMED');

const findings = [];
for (const r of applied) {
  const w = wlByKey.get(`${r.politician_id}|${r.topic_id}`);
  const reasoning = w.reasoning || '';
  const attached = r.evidence.filter((e) => e.matched_slug)
    .sort((a, b) => a.session.localeCompare(b.session)).slice(0, 4);

  for (const e of attached) {
    const inst = e.instrument;
    const isNum = /^[SH]B\d{4}$/.test(inst);
    let verdict;
    if (!isNum) {
      verdict = norm(e.title).includes(norm(inst)) ? 'TITLE_CARRIES_ACT' : 'NO_FIT';
    } else {
      const numOk = e.number.toUpperCase() === inst;
      // Years the reasoning mentions next to that number, or anywhere.
      const years = [...reasoning.matchAll(/\b(20\d{2})\b/g)].map((m) => m[1]);
      const sessYear = e.session.slice(0, 4);
      if (numOk && years.length && years.includes(sessYear)) verdict = 'NUMBER_AND_YEAR';
      else if (numOk && !years.length) verdict = 'NUMBER_AND_YEAR';
      else if (numOk) verdict = 'NUMBER_ONLY';
      else verdict = 'NO_FIT';
    }
    findings.push({
      politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
      instrument: inst, from_bill_number: isNum, attached: `${e.session} ${e.number}`,
      title: e.title, verdict,
      url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${e.slug}?ys=${e.session}`,
      reasoning,
    });
  }
}

const tally = findings.reduce((m, f) => { m[f.verdict] = (m[f.verdict] || 0) + 1; return m; }, {});
console.log('citations attached by 1685:', findings.length);
console.log(JSON.stringify(tally, null, 2));
console.log('\n=== SUSPECT citations ===');
for (const f of findings.filter((x) => x.verdict === 'NUMBER_ONLY' || x.verdict === 'NO_FIT')) {
  console.log(`\n[${f.verdict}] ${f.politician} / ${f.topic}`);
  console.log(`  instrument named : ${f.instrument}`);
  console.log(`  attached         : ${f.attached}  ${f.title.slice(0, 90)}`);
  console.log(`  reasoning        : ${f.reasoning.slice(0, 190)}`);
}
if (flag('--out')) fs.writeFileSync(flag('--out'), JSON.stringify({ tally, findings }, null, 1));

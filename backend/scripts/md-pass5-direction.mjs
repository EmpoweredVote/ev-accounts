#!/usr/bin/env node
/**
 * PASS 5, STEP 3 -- does the ROLL-CALL VOTE agree with what the stance CLAIMS?
 *
 * 🔴 WHY THIS STEP EXISTS. Step 2 reported "12 NAY" and I nearly presented those as 12 stances crediting a
 * politician with a bill they voted against. Reading them showed the opposite: most of those rows SAY the
 * politician OPPOSED the bill ("has opposed aggressive climate mandates", "voted against the Abortion Care
 * Access Act"), so a Nay CONFIRMS them. The step-2 `claim_verb` field was naive -- it matched the word
 * "supported" anywhere in the sentence, including inside "supported continued fossil fuel development
 * including OPPOSING the Climate Solutions Now Act".
 *
 * So: read the polarity attached to the NAMED INSTRUMENT, not the sentence as a whole, then compare.
 *   CONSISTENT   -- support+Yea, or oppose+Nay
 *   CONTRADICTED -- support+Nay, or oppose+Yea   <-- the real defect
 *   DIRECTION_UNCLEAR -- polarity not determinable; a human reads it
 *
 * 🔴 Reads only.
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), OUT = flag('--out');
if (!IN) { console.error('need --in'); process.exit(2); }

const OPPOSE = /\b(oppos\w*|against|skeptic\w*|critici\w*|resist\w*|reject\w*|voted no|fought)\b/i;
// ⚠ "led"/"lead" are NOT support markers — "he has LED OPPOSITION to tax increases" is the counter-example
// that made Simonaire read UNCLEAR. Only verbs that are unambiguously pro-instrument belong here.
const SUPPORT = /\b(support\w*|back\w*|champion\w*|advocat\w*|voted for|voted yes|co-?sponsor\w*|sponsor\w*|push\w*|driver|architect|author\w*|prioriti\w*)\b/i;

/**
 * Polarity of the CLAUSE THAT GOVERNS THE INSTRUMENT — not a window around it.
 *
 * 🔴 A 90-CHAR WINDOW WAS WRONG AND IT MANUFACTURED 8 FAKE CONTRADICTIONS. On the topic
 * "School Vouchers & Public Education Funding" the reasoning naturally contains BOTH polarities:
 * "opposes private school vouchers … backed the Blueprint for Maryland's Future". The window pulled the
 * VOUCHER opposition onto the BLUEPRINT and reported 8 legislators as contradicting a Yea they cast
 * correctly. Two different objects, two different polarities, in one sentence.
 *
 * Fix: take the text BEFORE the instrument, cut it at the nearest clause boundary (comma, semicolon,
 * " and ", " while "), and score only that final fragment — the words actually governing this instrument.
 */
function directionFor(reasoning, instrumentTitle) {
  const text = reasoning ?? '';
  const keys = [];
  const paren = (instrumentTitle ?? '').match(/\(([^)]{4,60})\)/);
  if (paren) keys.push(paren[1]);
  if (instrumentTitle) keys.push(instrumentTitle.split(/\s+-\s+/)[0]);
  for (const k of ['Climate Solutions Now', 'Abortion Care Access', 'Blueprint for Maryland', 'Police Accountability']) keys.push(k);

  for (const k of keys) {
    if (!k) continue;
    const i = text.toLowerCase().indexOf(k.toLowerCase().slice(0, 24));
    if (i === -1) continue;
    const before = text.slice(0, i);
    // the governing clause = everything after the last clause boundary
    // ⚠ '.' MUST be a boundary. "Kramer opposes private school vouchers. He … backed the Blueprint"
    // otherwise merges two sentences of OPPOSITE polarity about DIFFERENT objects into one fragment,
    // which reads UNCLEAR and buries a perfectly consistent row.
    const frag = before.split(/[.,;]|\band\b|\bwhile\b|\bbut\b|\bincluding\b/i).pop() ?? before;
    const opp = OPPOSE.test(frag), sup = SUPPORT.test(frag);
    if (opp && !sup) return { dir: 'OPPOSE', basis: frag.trim().slice(-90) };
    if (sup && !opp) return { dir: 'SUPPORT', basis: frag.trim().slice(-90) };
    if (opp && sup) return { dir: 'UNCLEAR', basis: frag.trim().slice(-90), note: 'both polarities inside the governing clause' };
    // nothing in the immediate clause: widen once, to the sentence containing the instrument
    const sentStart = before.lastIndexOf('.') + 1;
    const sent = text.slice(sentStart, Math.min(text.length, i + k.length + 60));
    const o2 = OPPOSE.test(sent), s2 = SUPPORT.test(sent);
    if (o2 && !s2) return { dir: 'OPPOSE', basis: sent.trim().slice(0, 120) };
    if (s2 && !o2) return { dir: 'SUPPORT', basis: sent.trim().slice(0, 120) };
    return { dir: 'UNCLEAR', basis: sent.trim().slice(0, 120) };
  }
  const opp = OPPOSE.test(text), sup = SUPPORT.test(text);
  if (opp && !sup) return { dir: 'OPPOSE', basis: text.slice(0, 120) };
  if (sup && !opp) return { dir: 'SUPPORT', basis: text.slice(0, 120) };
  return { dir: 'UNCLEAR', basis: text.slice(0, 120) };
}

/**
 * Is the bill the roll call settled on actually the instrument the claim names?
 * 🔴 A BARE BILL NUMBER IS AMBIGUOUS ACROSS SESSIONS (the mig-1686 defect). Valderrama's claim names
 * "HB0444 (2026)" and the roll call settled on 2018 HB0444, "Estates and Trusts". Such a verdict is VOID.
 * Accept when the bill title carries a named act that the reasoning also names, or when the reasoning's
 * stated year matches the bill's session.
 */
function billIdentityOk(reasoning, bill, title) {
  const text = (reasoning ?? '').toLowerCase();
  const session = (bill ?? '').slice(0, 4);
  const num = (bill ?? '').split(/\s+/)[1] ?? '';
  const statedYears = [...(reasoning ?? '').matchAll(/\b(20\d{2})\b/g)].map((m) => m[1]);
  const numberInClaim = new RegExp(`\\b${num.replace(/^([SH]B)0*/, '$1\\s*0*')}\\b`, 'i').test(reasoning ?? '');

  // a named act shared by title and reasoning is the strongest signal
  const paren = (title ?? '').match(/\(([^)]{4,60})\)/);
  const named = [paren?.[1], (title ?? '').split(/\s+-\s+/)[0]].filter(Boolean);
  for (const n of named) {
    const key = n.toLowerCase().replace(/\s+of\s+\d{4}$/, '').trim();
    if (key.length >= 8 && text.includes(key.slice(0, 24))) return { ok: true, why: `title act "${n}" appears in the claim` };
  }
  if (numberInClaim && statedYears.length && statedYears.includes(session)) return { ok: true, why: 'bill number and stated year agree' };
  if (numberInClaim && !statedYears.length) return { ok: true, why: 'bill number matches, no year stated' };
  if (numberInClaim) return { ok: false, why: `claim says ${statedYears.join('/')} but the vote is from ${session}` };
  return { ok: true, why: 'instrument matched by act name, not a bare number' };
}

const j = JSON.parse(fs.readFileSync(IN, 'utf8'));
const settled = j.rows.filter((r) => ['YEA', 'NAY'].includes(r.result));

const out = settled.map((r) => {
  const d = directionFor(r.reasoning, r.settled_on?.title);
  const id = billIdentityOk(r.reasoning, r.settled_on?.bill, r.settled_on?.title);
  let verdict;
  if (!id.ok) verdict = 'VOID_WRONG_BILL';
  else if (d.dir === 'UNCLEAR') verdict = 'DIRECTION_UNCLEAR';
  else if ((d.dir === 'SUPPORT' && r.result === 'YEA') || (d.dir === 'OPPOSE' && r.result === 'NAY')) verdict = 'CONSISTENT';
  else verdict = 'CONTRADICTED';
  return {
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    vote: r.result, claim_direction: d.dir, basis: d.basis, note: d.note ?? null,
    bill_identity: id,
    bill: r.settled_on?.bill, bill_title: r.settled_on?.title, action: r.settled_on?.action,
    vote_pdf: r.settled_on ? `https://mgaleg.maryland.gov${r.settled_on.vote}` : null,
    reasoning: r.reasoning, verdict,
  };
});

const tally = out.reduce((m, x) => { m[x.verdict] = (m[x.verdict] || 0) + 1; return m; }, {});
console.log('settled rows:', out.length);
console.log(JSON.stringify(tally, null, 2));
for (const v of ['CONTRADICTED', 'VOID_WRONG_BILL', 'DIRECTION_UNCLEAR']) {
  const rs = out.filter((x) => x.verdict === v);
  if (!rs.length) continue;
  console.log(`\n=== ${v} (${rs.length}) ===`);
  for (const r of rs) {
    console.log(`· ${r.politician} / ${r.topic}`);
    console.log(`    claim reads ${r.claim_direction}, vote was ${r.vote} on ${r.bill} ${(r.bill_title ?? '').slice(0, 55)}`);
    console.log(`    reasoning: ${r.reasoning.slice(0, 165)}`);
  }
}
if (OUT) fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD pass 5 step 3 - claim direction vs vote', tally, rows: out }, null, 1));

#!/usr/bin/env node
/**
 * PASS 5, STEP 2 -- ROLL-CALL evidence for the in-tenure NO_SPONSOR_LINK rows.
 *
 * A sponsor list cannot settle "supported"/"backed"/"voted for". Maryland publishes each floor vote as a
 * PDF linked from the bill page, so the claim IS checkable -- carefully.
 *
 * MECHANICS THAT MATTER
 *  - Vote PDFs are read with `pdftotext -table` (this box has Xpdf 4.00, which has no -bbox-layout).
 *    -layout INTERLEAVES the Yea and Nay columns onto shared lines and is unsafe; -table yields a clean
 *    grid under each section header. Cells are split on 2+ spaces so multi-word surnames survive
 *    ("Palakovich Carr", "Sample-Hughes").
 *  - 🔑 SELF-CHECK: the PDF declares its own tallies ("95 Yeas  42 Nays  4 Absent"). If the parse does not
 *    reproduce every declared count EXACTLY, the parse is VOID and the row is UNKNOWN. No guessing.
 *  - 🔑 PASSAGE ONLY. A bill has many recorded votes and most are floor amendments; a Nay on a hostile
 *    amendment is not opposition to the bill. Only Actions matching "Third Reading Passed", "Concurs" or
 *    "Overridden" are read.
 *  - 🔑 CHAMBER MATTERS. Surnames collide ACROSS chambers (Alonzo Washington in the House, Mary Washington
 *    in the Senate, same session). The member's chamber for that session is derived from their service
 *    history; if it cannot be determined, the row is UNKNOWN rather than guessed.
 *  - 🔑 IDENTITY. A bare surname counts only if no disambiguated form of that surname appears in the same
 *    vote. Where the sheet writes "Jones, D." / "Jones, R.", the target's initial must select exactly one.
 *    Anything else is AMBIGUOUS, never a guess.
 *  - ⚠ The presiding officer is listed as "Speaker" / "President", not by name, so their own vote is not
 *    attributable by surname -- reported as PRESIDING_NOT_ATTRIBUTABLE.
 *
 * 🔴 Reads only. Emits a worklist.
 */
import fs from 'node:fs';
import path from 'node:path';
import { chamberSpans as spansFromTenure, chamberFor as chamberForYear } from './lib/md-tenure.mjs';
// 🔑 the vote reading now lives in lib/md-rollcall.mjs, shared with md-landmark-acts.mjs so the two
// passes cannot drift. The rules it encodes (-table, the declared-count self-check, passage-only,
// surname ambiguity) were all learned here.
import { passageVotes, voteText as voteTextIn, parseVote, locate } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), BILLS = flag('--bills'), VOTES = flag('--votes'), OUT = flag('--out');
const LIMIT = parseInt(flag('--limit', '0'), 10);
const ONLY = flag('--only');
if (!IN || !BILLS || !VOTES || !OUT) { console.error('need --in --bills --votes --out'); process.exit(2); }
fs.mkdirSync(VOTES, { recursive: true });

// chamber logic lives in lib/md-tenure.mjs so it cannot drift from the tenure screen
const chamberSpans = (lines) => spansFromTenure((lines ?? []).join(' '));
const chamberFor = chamberForYear;
const voteText = (href) => voteTextIn(href, VOTES);

const tenure = JSON.parse(fs.readFileSync(IN, 'utf8'));
let rows = tenure.rows.filter((r) => r.verdict === 'IN_TENURE_NEEDS_ROLLCALL');
if (ONLY) rows = rows.filter((r) => r.politician === ONLY);
if (LIMIT) rows = rows.slice(0, LIMIT);
console.log(`roll-call checking ${rows.length} rows…`);

const out = [];
let n = 0;
for (const r of rows) {
  const spans = chamberSpans(r.service_lines);
  const yearInClaim = (r.reasoning.match(/\b(20\d{2})\b/) ?? [])[1];
  const bills = [...r.bills_in_tenure].sort((a, b) => {
    if (yearInClaim) {
      const ay = a.session.startsWith(yearInClaim) ? 0 : 1;
      const by = b.session.startsWith(yearInClaim) ? 0 : 1;
      if (ay !== by) return ay - by;
    }
    return parseInt(b.session, 10) - parseInt(a.session, 10);
  });

  const attempts = [];
  let settled = null;
  for (const b of bills) {
    const year = parseInt(b.session, 10);
    const ch = chamberFor(spans, year);
    if (!ch) { attempts.push({ bill: `${b.session} ${b.number}`, note: 'chamber undetermined for that session' }); continue; }
    const billFile = path.join(BILLS, `${b.slug}-${b.session}.html`);
    if (!fs.existsSync(billFile)) { attempts.push({ bill: `${b.session} ${b.number}`, note: 'bill page not cached' }); continue; }
    const votes = passageVotes(fs.readFileSync(billFile, 'utf8')).filter((v) => v.chamber === ch);
    if (!votes.length) { attempts.push({ bill: `${b.session} ${b.number}`, chamber: ch, note: 'no passage vote recorded for that chamber' }); continue; }
    for (const v of votes) {
      const txt = await voteText(v.href);
      if (!txt) { attempts.push({ bill: `${b.session} ${b.number}`, vote: v.href, note: 'pdf unavailable' }); continue; }
      const p = parseVote(txt);
      if (!p.ok) { attempts.push({ bill: `${b.session} ${b.number}`, vote: v.href, note: p.reason }); continue; }
      const loc = locate(p.blocks, r.politician);
      attempts.push({ bill: `${b.session} ${b.number}`, title: b.title, chamber: ch, action: v.action, vote: v.href, verdict: loc.verdict, matched: loc.matched ?? null, candidates: loc.candidates ?? null });
      if (['YEA', 'NAY', 'NOT_VOTING', 'EXCUSED', 'ABSENT'].includes(loc.verdict)) { settled = { ...attempts[attempts.length - 1] }; break; }
    }
    if (settled) break;
  }

  out.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    claim_verb: r.claim_verb, reasoning: r.reasoning, service_lines: r.service_lines,
    result: settled ? settled.verdict : 'UNRESOLVED',
    settled_on: settled ?? null, attempts,
  });
  if (++n % 10 === 0) console.log(`  …${n}/${rows.length}`);
}

const tally = out.reduce((m, x) => { m[x.result] = (m[x.result] || 0) + 1; return m; }, {});
console.log('\n' + JSON.stringify(tally, null, 2));
for (const x of out) {
  console.log(`\n[${x.result}] ${x.politician} / ${x.topic}  (claim: ${x.claim_verb})`);
  if (x.settled_on) console.log(`   ${x.settled_on.chamber} ${x.settled_on.bill} ${x.settled_on.action} -> ${x.settled_on.verdict} (as "${x.settled_on.matched}")`);
  else for (const a of x.attempts.slice(0, 3)) console.log(`   · ${a.bill ?? '?'}: ${a.note ?? a.verdict}`);
}
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD pass 5 step 2 - roll calls', tally, rows: out }, null, 1));

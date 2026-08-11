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
import { execFileSync } from 'node:child_process';
import { parse } from 'node-html-parser';
import { chamberSpans as spansFromTenure, chamberFor as chamberForYear } from './lib/md-tenure.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), BILLS = flag('--bills'), VOTES = flag('--votes'), OUT = flag('--out');
const LIMIT = parseInt(flag('--limit', '0'), 10);
const ONLY = flag('--only');
if (!IN || !BILLS || !VOTES || !OUT) { console.error('need --in --bills --votes --out'); process.exit(2); }
fs.mkdirSync(VOTES, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ⚠ mgaleg writes BOTH "Third Reading Passed" and "Third ReadingS Passed" (plural), plus
// "…with Amendments". Requiring the singular silently skipped a real passage vote on HB1300/2020 and
// reported "no passage vote recorded" for it. Keep this tolerant.
const PASSAGE = /(Third Readings? Passed|Concurs|Overridden)/i;

// chamber logic lives in lib/md-tenure.mjs so it cannot drift from the tenure screen
const chamberSpans = (lines) => spansFromTenure((lines ?? []).join(' '));
const chamberFor = chamberForYear;

/** passage votes on a bill page, per chamber */
function passageVotes(billHtml) {
  const root = parse(billHtml);
  const out = [];
  for (const a of root.querySelectorAll('a[href*="/votes/"]')) {
    // ⚠ some hrefs carry surrounding whitespace (" /2019RS/votes/senate/1096.pdf"), which makes fetch()
    // throw ERR_INVALID_URL mid-run. Trim before use.
    const href = (a.getAttribute('href') || '').trim();
    const tr = a.closest('tr');
    if (!tr) continue;
    const text = tr.text.replace(/\s+/g, ' ').trim();
    const m = text.match(/Action (.+)$/);
    const action = (m ? m[1] : text).replace(/Proceedings.*/i, '').trim();
    if (!PASSAGE.test(action) || /Floor Amendment/i.test(action)) continue;
    const chamber = /\/votes\/house\//.test(href) ? 'house' : /\/votes\/senate\//.test(href) ? 'senate' : null;
    if (!chamber) continue;
    out.push({ href, chamber, action });
  }
  return [...new Map(out.map((v) => [v.href, v])).values()];
}

async function voteText(href) {
  const name = href.replace(/[^A-Za-z0-9]/g, '_');
  const pdf = path.join(VOTES, `${name}.pdf`);
  const txt = path.join(VOTES, `${name}.table.txt`);
  if (fs.existsSync(txt)) return fs.readFileSync(txt, 'utf8');
  if (!fs.existsSync(pdf)) {
    const res = await fetch(`https://mgaleg.maryland.gov${href}`, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    await sleep(900);
    if (buf.length < 5_000 || buf.slice(0, 4).toString() !== '%PDF') return null;
    fs.writeFileSync(pdf, buf);
  }
  try { execFileSync('pdftotext', ['-table', pdf, txt], { stdio: 'ignore' }); } catch { return null; }
  return fs.existsSync(txt) ? fs.readFileSync(txt, 'utf8') : null;
}

const SECTIONS = [
  { key: 'YEA', re: /^Voting\s+Yea\s*-\s*(\d+)/i },
  { key: 'NAY', re: /^Voting\s+Nay\s*-\s*(\d+)/i },
  { key: 'NOT_VOTING', re: /^Not\s+Voting\s*-\s*(\d+)/i },
  { key: 'EXCUSED', re: /^Excused\s+from\s+Voting\s*-\s*(\d+)/i },
  { key: 'ABSENT', re: /^Excused\s*\(Absent\)\s*-\s*(\d+)/i },
];

/** Parse the -table text into {YEA:[names],…}; returns null if declared counts are not reproduced. */
function parseVote(text) {
  const lines = text.split(/\r?\n/);
  const blocks = {}; const declared = {};
  let cur = null;
  for (const raw of lines) {
    const line = raw.replace(/\s+$/, '');
    if (!line.trim()) continue;
    let matched = false;
    for (const s of SECTIONS) {
      const m = line.trim().match(s.re);
      if (m) { cur = s.key; declared[cur] = parseInt(m[1], 10); blocks[cur] = blocks[cur] ?? []; matched = true; break; }
    }
    if (matched) continue;
    if (!cur) continue;
    if (/Indicates Vote Change/i.test(line)) { cur = null; continue; }
    for (const cell of line.split(/\s{2,}/)) {
      const c = cell.trim().replace(/\*/g, '').trim();
      if (!c) continue;
      if (/^\d+$/.test(c)) continue;
      if (/^(Yeas?|Nays?|Not Voting|Excused|Absent)$/i.test(c)) continue;
      blocks[cur].push(c);
    }
  }
  // 🔑 the self-check: every declared count must be reproduced exactly
  for (const s of SECTIONS) {
    if (declared[s.key] == null) continue;
    if ((blocks[s.key] ?? []).length !== declared[s.key]) {
      return { ok: false, reason: `parse mismatch ${s.key}: declared ${declared[s.key]}, parsed ${(blocks[s.key] ?? []).length}` };
    }
  }
  return { ok: true, blocks, declared };
}

const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop();
const initialOf = (n) => n.trim()[0].toUpperCase();

/** Find the target in a parsed vote. */
function locate(blocks, fullName) {
  const sur = surnameOf(fullName).toLowerCase();
  const init = initialOf(fullName);
  const hits = [];
  let sawPresiding = false;
  for (const [section, names] of Object.entries(blocks)) {
    for (const n of names) {
      if (/^(Speaker|President)$/i.test(n)) { sawPresiding = true; continue; }
      const base = n.split(',')[0].trim().toLowerCase();
      if (base !== sur) continue;
      const m = n.match(/,\s*([A-Z])\./);
      hits.push({ section, name: n, initial: m ? m[1] : null });
    }
  }
  if (!hits.length) return { verdict: sawPresiding ? 'NOT_PRESENT_OR_PRESIDING' : 'NOT_PRESENT', sawPresiding };
  if (hits.length === 1 && !hits[0].initial) return { verdict: hits[0].section, matched: hits[0].name };
  const byInit = hits.filter((h) => h.initial === init);
  if (byInit.length === 1) return { verdict: byInit[0].section, matched: byInit[0].name };
  return { verdict: 'AMBIGUOUS', candidates: hits.map((h) => h.name) };
}

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

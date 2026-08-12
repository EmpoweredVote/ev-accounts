/**
 * Maryland floor-vote and sponsor-list reading, shared so two passes cannot drift.
 *
 * 🔴 EXTRACTED VERBATIM from md-pass5-rollcall.mjs, which learned every rule here the hard way.
 * md-landmark-acts.mjs needs the same reading, and a second copy would be a second set of bugs.
 *
 * MECHANICS THAT MATTER
 *  - Vote PDFs are read with `pdftotext -table` (this box has Xpdf 4.00, which has no -bbox-layout).
 *    -layout INTERLEAVES the Yea and Nay columns onto shared lines and is unsafe; -table yields a clean
 *    grid under each section header. Cells are split on 2+ spaces so multi-word surnames survive
 *    ("Palakovich Carr", "Sample-Hughes").
 *  - 🔑 SELF-CHECK: the PDF declares its own tallies ("95 Yeas  42 Nays  4 Absent"). If the parse does not
 *    reproduce every declared count EXACTLY, the parse is VOID and the row is UNKNOWN. No guessing.
 *  - 🔑 PASSAGE ONLY. A bill has many recorded votes and most are floor amendments; a Nay on a hostile
 *    amendment is not opposition to the bill.
 *  - 🔑 IDENTITY. A bare surname counts only if no disambiguated form of that surname appears in the same
 *    vote. Where the sheet writes "Jones, D." / "Jones, R.", the target's initial must select exactly one.
 *    Anything else is AMBIGUOUS, never a guess.
 *  - ⚠ The presiding officer is listed as "Speaker" / "President", not by name, so their own vote is not
 *    attributable by surname -- reported as NOT_PRESENT_OR_PRESIDING.
 */
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { parse } from 'node-html-parser';

export const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ⚠ mgaleg writes BOTH "Third Reading Passed" and "Third ReadingS Passed" (plural), plus
// "…with Amendments". Requiring the singular silently skipped a real passage vote on HB1300/2020 and
// reported "no passage vote recorded" for it. Keep this tolerant.
export const PASSAGE = /(Third Readings? Passed|Concurs|Overridden)/i;

/** passage votes on a bill page, per chamber */
export function passageVotes(billHtml) {
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

/** Fetch (or reuse) a vote PDF and return its `pdftotext -table` text; null if unavailable. */
export async function voteText(href, votesDir) {
  const name = href.replace(/[^A-Za-z0-9]/g, '_');
  const pdf = path.join(votesDir, `${name}.pdf`);
  const txt = path.join(votesDir, `${name}.table.txt`);
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

/** Parse the -table text into {YEA:[names],…}; returns {ok:false} if declared counts are not reproduced. */
export function parseVote(text) {
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

export const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop();
export const initialOf = (n) => n.trim()[0].toUpperCase();

/** Find the target in a parsed vote. */
export function locate(blocks, fullName) {
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

/**
 * The FULL sponsor list off a bill page.
 *
 * 🔴 Maryland lists every sponsor under "Sponsored by"; there is no separate cosponsor block, so this
 * is the only way to test a co-sponsorship claim. Kept identical to md-cr-sponsor-index.mjs.
 * ⚠ "The President (By Request - Administration)" and "The Speaker" are dropped: they name an office,
 * not a member, so a landmark bill carried by leadership can have a sponsor list that credits nobody.
 */
export function sponsorsOf(html) {
  const m = html.match(/Sponsored by[\s\S]{0,60}?<\/?[^>]*>([\s\S]{0,4000}?)(?:<\/p>|<\/div>|Status:?|Introduced)/i);
  let raw = m ? m[1] : null;
  if (!raw) {
    const i = html.indexOf('Sponsored by');
    raw = i > -1 ? html.slice(i, i + 3000) : null;
  }
  if (!raw) return null;
  const text = raw.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim()
    .replace(/^Sponsored by\s*/i, '');
  // 🔴 THE LEAD SPONSOR HIDES BEHIND THE LEADERSHIP PREFIX. HB1300/2020 reads "The Speaker (By Request
  // - Commission on Innovation and Excellence in Education) and Delegates McIntosh, Kaiser, …", so a
  // plain comma split puts the whole prefix AND McIntosh in one over-long first cell, which the 40-char
  // filter then discarded — losing a named sponsor on exactly the landmark bills leadership carries.
  // Strip the office prefix first, then the "Delegates"/"Senators" keyword.
  return text
    .replace(/^\s*The\s+(Speaker|President)\s*(\([^)]*\))?\s*(and\s+)?/i, '')
    .replace(/^\s*Chair[^,]*,[^()]*?Committee\s*(\([^)]*\))?\s*(and\s+)?/i, '')
    .replace(/^(Delegates?|Senators?)\s+/i, '')
    .split(/\s*,\s*/)
    // ⚠ the last sponsor arrives glued to the next field — "and Lee Status Enacted under Article II"
    // on SB0528/2022 — which is under the 40-char cap, so it survived the filter and SILENTLY LOST a
    // sponsor. Trim the trailing prose and the "and " before matching, never after.
    .map((s) => s.trim().replace(/^and\s+/i, '').replace(/\s+(Status|Introduced|Enacted)\b[\s\S]*$/i, '').trim())
    .filter((s) => s && s.length < 40 && !/^(and|Chair|Vice Chair|President|Speaker)$/i.test(s)
      && !/Committee|Delegation|By Request|Administration/i.test(s));
}

/**
 * 🔑 THE SPONSOR LIST IS HYPERLINKED, AND A SLUG IS IDENTITY WHERE A SURNAME IS ONLY A GUESS.
 * Each name under "Sponsored by" links to /Members/Details/<slug>. SB0528/2022 links its "Washington"
 * to `washington01` — Senator MARY Washington — while our Alonzo T. Washington is `washington02`. Read
 * off the surname alone, those are the same person; read off the slug, they never were.
 *
 * ⚠ Slugs are not eternal. HB1300/2020 links to a bare `washington` that now returns NotFound, so an
 * older bill can carry a slug that no longer resolves. A slug MISMATCH is therefore only decisive when
 * the slug still exists; otherwise fall back to surname plus the chamber gate.
 */
export function sponsorSlugs(html) {
  const i = html.indexOf('Sponsored by');
  if (i < 0) return [];
  const seg = html.slice(i, i + 4000);
  return [...seg.matchAll(/Members\/Details\/([A-Za-z0-9_-]+)[^>]*>([^<]{0,40})/g)]
    .map((m) => ({ slug: m[1], label: m[2].trim() }));
}

/**
 * Is `fullName` on a sponsor list? Same identity discipline as `locate`: a bare surname counts only
 * when no initialled form of that surname is also present.
 */
export function locateSponsor(sponsors, fullName) {
  const sur = surnameOf(fullName).toLowerCase();
  const init = initialOf(fullName);
  const hits = sponsors
    .map((s) => ({ raw: s, base: s.replace(/^([A-Z])\.\s*/, '').toLowerCase().trim(), initial: (s.match(/^([A-Z])\.\s/) || [])[1] || null }))
    .filter((h) => h.base === sur);
  if (!hits.length) return { verdict: 'NOT_SPONSOR' };
  if (hits.length === 1 && !hits[0].initial) return { verdict: 'SPONSOR', matched: hits[0].raw };
  const byInit = hits.filter((h) => h.initial === init);
  if (byInit.length === 1) return { verdict: 'SPONSOR', matched: byInit[0].raw };
  return { verdict: 'AMBIGUOUS', candidates: hits.map((h) => h.raw) };
}

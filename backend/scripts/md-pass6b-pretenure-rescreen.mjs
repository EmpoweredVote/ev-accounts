#!/usr/bin/env node
/**
 * PASS 6b -- RE-SCREEN the 21 PRE_TENURE_ALL_BILLS verdicts from pass 6.
 *
 * 🔴 WHY: those verdicts are NOT trustworthy. md-pass5-tenure-screen.mjs judged tenure against the
 * bills that pass 6's resolver had attached, and that resolution was wrong in two ways:
 *   1. it resolved instruments across ALL sessions, so a member was screened against 2013RS bills
 *      when the instrument they actually name is from 2026 (Mark Edelson);
 *   2. 🔑 **THE TENURE ITSELF WAS UNDERSTATED: the screen reads the member's CURRENT mgaleg page,
 *      which carries only their CURRENT CHAMBER.** A chamber switch erases the earlier service
 *      entirely -- Sara Love's Senate page says "since June 13, 2024" while `love01?ys=2023RS`
 *      says "Delegate Sara Love ... Member of the House since January 9, 2019". Five years of
 *      service, invisible. Extends the known "slugs change when a member switches chamber" rule
 *      to TENURE, not just to URL resolution.
 *
 * 🔑 Gate on bill identity BEFORE believing a TENURE verdict, exactly as before believing a VOTE
 * verdict. A pre-tenure verdict is a claim that something was IMPOSSIBLE -- the strongest claim in
 * this workstream and the one that justifies deletion (mig 1692). It must not rest on the wrong bill.
 *
 * 🔴 Reads only. Emits a decision table for a human.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const TENURE = flag('--tenure'), CORPUS = flag('--corpus'), CACHE = flag('--cache'), OUT = flag('--out');
if (!TENURE || !CORPUS || !CACHE || !OUT) { console.error('need --tenure --corpus --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * CORRECTED tenure. Each entry is the EARLIEST date the member held ANY seat, read from the mgaleg
 * member page for the chamber they held at that time -- not from whatever page they occupy today.
 * ⚠ Sara Love is the whole reason this table exists; her current (Senate) page hides 2019-2024.
 */
const TENURE_FROM = {
  'Adrian Boafo': '2023-01-11',
  'Ashanti Martinez': '2023-02-24',
  'Denise Roberts': '2024-01-08',
  'Derrick Coley': '2026-01-13',
  'Karen Toles': '2022-01-12',      // "General Assembly since January 12, 2022" -- 2022 session ran Jan 12-Apr 11
  'Kent Roberson': '2023-05-30',
  'Kym Taylor': '2023-01-11',
  'Mark Edelson': '2023-01-11',
  'Mary A. Lehman': '2019-01-09',
  'Sara Love': '2019-01-09',        // CORRECTED: love01?ys=2023RS = "Delegate Sara Love", House since 2019-01-09
};

/**
 * CORRECTED instrument -> the sessions it actually exists in, read out of the 73,232-bill corpus.
 * ⚠ "Maryland RELIEF Act" is the one the resolver got WRONG: it matched 2013-2015 *tax* relief acts
 * because the real 2021 act is titled "...Entrepreneurs, and Families (RELIEF) Act" -- a
 * PARENTHESISED ACRONYM, the same lookup limitation that hid the Affordable Housing PILOT act.
 */
const INSTRUMENTS = {
  "Blueprint for Maryland's Future": { sessions: ['2019', '2020', '2021', '2022', '2023', '2024', '2025', '2026'], match: /Blueprint for Maryland/i },
  'Maryland Abortion Care Access Act': { sessions: ['2022'], match: /^Abortion Care Access Act$/i },
  'Maryland RELIEF Act': { sessions: ['2021'], match: /Entrepreneurs, and Families \(RELIEF\) Act/i },
  'Climate Solutions Now Act': { sessions: ['2021', '2022', '2025'], match: /Climate Solutions Now/i },
  'Maryland Voting Rights Act': { sessions: ['2022', '2023', '2024', '2025', '2026'], match: /Voting Rights Act of \d{4}/i },
  'Limitations and Climate Alignment Act': { sessions: ['2024', '2025', '2026'], match: /Cost Recovery - Limitations|Climate Alignment Act/i },
  SB0539: { sessions: null, match: null },
};

const { bills } = JSON.parse(fs.readFileSync(CORPUS, 'utf8'));
const tenure = JSON.parse(fs.readFileSync(TENURE, 'utf8'));
const rows = (tenure.rows || tenure).filter((r) => r.verdict === 'PRE_TENURE_ALL_BILLS');

async function sponsorSlugs(slug, session) {
  const file = path.join(CACHE, `${slug}-${session}.html`);
  let html = null;
  if (fs.existsSync(file) && fs.statSync(file).size > 20_000) html = fs.readFileSync(file, 'utf8');
  else {
    const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`;
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    if (/Error\/NotFound/i.test(res.url) || body.length < 20_000) { await sleep(1200); return null; }
    html = body; fs.writeFileSync(file, html); await sleep(1300);
  }
  const root = parse(html);
  let dd = null;
  for (const dt of root.querySelectorAll('dt')) if (/sponsored by/i.test(dt.text)) { dd = dt.nextElementSibling; break; }
  const slugs = new Set();
  if (dd) for (const a of dd.querySelectorAll('a[href*="Members/Details/"]')) {
    const m = (a.getAttribute('href') || '').match(/Details\/([A-Za-z0-9]+)/);
    if (m) slugs.add(m[1].toLowerCase());
  }
  return slugs;
}

const out = [];
for (const r of rows) {
  const from = TENURE_FROM[r.politician];
  const fromYear = from ? Number(from.slice(0, 4)) : null;
  const instName = Object.keys(INSTRUMENTS).find((k) => (r.reasoning || '').toLowerCase().includes(k.toLowerCase().replace(/^maryland /, '')))
    || Object.keys(INSTRUMENTS).find((k) => (r.reasoning || '').includes(k));
  const inst = instName ? INSTRUMENTS[instName] : null;

  // Sessions of the instrument that fall inside the member's tenure. A session that STARTS in the
  // year they were seated counts only if they were seated before it adjourned (MD sits Jan-Apr).
  const inTenure = (inst?.sessions || []).filter((y) => {
    const yr = Number(y);
    if (yr > fromYear) return true;
    if (yr < fromYear) return false;
    return from.slice(5) <= '04-11'; // seated during that session
  });

  let verdict, evidence = [];
  if (!inst || !inst.sessions) {
    verdict = 'NEEDS_MANUAL';
  } else if (!inTenure.length) {
    verdict = 'PRE_TENURE_CONFIRMED';
  } else {
    verdict = 'IN_TENURE_RESCREENED';
    const cands = bills.filter((b) => inTenure.includes(b.session.slice(0, 4)) && inst.match.test(b.title));
    const uniq = [...new Map(cands.map((b) => [b.number + b.session, b])).values()];
    for (const b of uniq.slice(0, 14)) {
      const s = await sponsorSlugs(b.slug, b.session);
      if (s && s.has((r.cited_slug || '').toLowerCase())) {
        evidence.push({ session: b.session, number: b.number, title: b.title, url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}` });
      }
    }
  }
  out.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    cited_slug: r.cited_slug, tenure_from: from, instrument: instName,
    instrument_sessions: inst?.sessions || null, sessions_in_tenure: inTenure,
    claim_verb: r.claim_verb, original_verdict: 'PRE_TENURE_ALL_BILLS', verdict,
    sponsor_evidence: evidence,
    needs_rollcall: verdict === 'IN_TENURE_RESCREENED' && !evidence.length,
    reasoning: r.reasoning,
  });
  console.log(`${verdict.padEnd(22)} ${r.politician} / ${r.topic}  [${instName || '?'}] in-tenure=${inTenure.join(',') || 'none'} sponsor=${evidence.length}`);
}

const tally = out.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
fs.writeFileSync(OUT, JSON.stringify({
  pass: 'MD pass 6b - re-screen of contaminated PRE_TENURE verdicts',
  caveat: 'A PRE_TENURE verdict claims the stance was IMPOSSIBLE. Confirmed only where the instrument '
        + 'exists in NO session inside the member\'s corrected tenure. Everything else needs evidence, '
        + 'not deletion. Sponsorship miss on a "voted" claim is UNVERIFIED, never false.',
  tally, rows: out,
}, null, 1));
console.log('\n' + JSON.stringify(tally, null, 2));

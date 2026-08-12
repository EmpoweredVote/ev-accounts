#!/usr/bin/env node
/**
 * LANDMARK-ACT SOURCING for the rows corrected by migration 1714.
 *
 * 🔑 WHY THIS IS THE CHEAP HALF. Of the 71 rows still owed sourcing, only 24 name an instrument, and
 * they name just THREE things between them: the Blueprint for Maryland's Future (11), the Climate
 * Solutions Now Act (12), and two 2026 bills Kevin Harris sponsored by number (1). Resolve each act
 * ONCE, pull its full sponsor list and its passage roll calls, then test every member against it.
 * The other 47 rows name nothing and need the full class-C crawl instead — not this script.
 *
 * 🔴 THIS IS NOT "APPEND A CITATION". Most of these rows ALREADY carry an mgaleg bill or vote URL that
 * nobody ever checked — and this workstream exists because migration 1535 found 1,166 citations at
 * pages that never existed. So every stored mgaleg URL is fetched AS STORED and reported alongside the
 * independently-derived evidence. A stored citation that the record does not support is a finding, not
 * a starting point.
 *
 * 🔑 SPONSORSHIP BEATS A VOTE, and both are reported. "Backed the Blueprint" is carried by a sponsor
 * listing; failing that, by a Yea on a passage vote. ⚠ The Blueprint bills are carried by leadership
 * ("The Speaker", "The President"), whose sponsor lists credit an office rather than members — so for
 * those bills the roll call is expected to be the only route, and a NOT_SPONSOR there means nothing.
 *
 * ⚠ WHICH BILLS COUNT. The corpus holds 21 Blueprint-titled bills across 2019-2026, most of them later
 * "- Alterations". A row saying the member "backed the Blueprint" is about the ENACTMENT, so only the
 * establishing and implementing bills are candidates. Everything excluded is logged, never dropped
 * silently.
 *
 * 🔴 Reads only. Emits a worklist to be READ; it is not a change list.
 *   node scripts/md-landmark-acts.mjs --out <report.json>
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
// 🔑 chamberForSession, not chamberFor: it is month-aware, and Ron Watson's August 2021 appointment to
// the Senate would otherwise credit his 2021 SESSION votes to a chamber he did not sit in until months
// after it adjourned.
import { chamberSpans, chamberForSession, tenureText } from './lib/md-tenure.mjs';
import { passageVotes, voteText, parseVote, locate, sponsorsOf, sponsorSlugs, locateSponsor, UA } from './lib/md-rollcall.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-landmark-acts.json');
const ONLY = flag('--only');

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const BILLS = path.join(CACHE, 'bill-cache');
const VOTES = path.join(CACHE, 'vote-cache');
const MEMBERS = path.join(CACHE, 'member-cache');
for (const d of [BILLS, VOTES, MEMBERS]) fs.mkdirSync(d, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const corpus = JSON.parse(fs.readFileSync(path.join(CACHE, 'md-bill-corpus.json'), 'utf8'));
// ⚠ the corpus ships a degraded duplicate of every bill (title "2") — filter it out
const allBills = corpus.bills.filter((x) => x.title && x.title.length > 5);

// ── the acts, resolved from the corpus by title so nothing here is typed from memory ────────────
const ACTS = [
  {
    key: 'blueprint',
    claim: /Blueprint for Maryland'?’?s Future/i,
    title: /Blueprint for Maryland'?’?s Future/i,
    // The establishing act (2019), its implementation (2020, vetoed and overridden in 2021) and the
    // 2021 revisions. Later "- Alterations" bills amend a law already on the books and are not what
    // "backed the Blueprint" refers to.
    keep: /^(The )?Blueprint for Maryland'?’?s Future( - (Implementation|Revisions))?$/i,
  },
  {
    key: 'climate-solutions-now',
    claim: /Climate Solutions Now Act/i,
    title: /Climate Solutions Now Act/i,
    // 2021 (passed the Senate, died in the House) and 2022 (enacted). The 2025 "Affordability Act" is
    // a different bill amending it.
    keep: /^Climate Solutions Now Act of (2021|2022)$/i,
  },
];
for (const a of ACTS) {
  const all = allBills.filter((b) => a.title.test(b.title));
  a.bills = all.filter((b) => a.keep.test(b.title.trim()))
    .sort((x, y) => x.session.localeCompare(y.session) || x.number.localeCompare(y.number));
  a.excluded = all.filter((b) => !a.keep.test(b.title.trim()));
}
console.log('acts resolved from the corpus:');
for (const a of ACTS) {
  console.log(`\n  ${a.key}: ${a.bills.length} candidate bill(s)`);
  for (const b of a.bills) console.log(`     ✓ ${b.session} ${b.number} "${b.title}"`);
  console.log(`     (${a.excluded.length} same-titled bill(s) excluded as later amendments:)`);
  for (const b of a.excluded) console.log(`     · ${b.session} ${b.number} "${b.title.slice(0, 90)}"`);
}

/**
 * 🔴 HIDDEN PRIOR-CHAMBER SERVICE. Sara Love's mgaleg page states her tenure as "Member of the Maryland
 * Senate since June 13, 2024" and says NOTHING about the House — yet the corpus records "Delegate Love"
 * first-sponsoring House bills in every session from 2019RS to 2024RS. Trusting the page put her whole
 * Blueprint-era service outside her tenure, and the test then silently never ran.
 *
 * So the tenure screen is CHECKED against the legislative record: any session where the corpus shows
 * this surname sponsoring, but the tenure spans say the member was not there, is reported. A bare
 * surname is not identity, so this is a READING FLAG, never an automatic span.
 */
const sponsorSessions = (fullName) => {
  const sur = fullName.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
  const re = new RegExp(`^(Delegate|Senator)s?\\s+${sur.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
  const seen = {};
  for (const b of allBills) {
    if (!b.sponsor || !re.test(b.sponsor.trim())) continue;
    const ch = /^Delegate/i.test(b.sponsor.trim()) ? 'house' : 'senate';
    (seen[b.session] ||= new Set()).add(ch);
  }
  return Object.fromEntries(Object.entries(seen).map(([s, v]) => [s, [...v]]));
};

/**
 * ⚠ TENURE OVERRIDES — only where the page is demonstrably incomplete, with the evidence stated.
 * The spans here are used INSTEAD of the page's, never merged with it.
 */
const TENURE_OVERRIDE = {
  // mgaleg's Tenure field omits her House service entirely; the corpus has "Delegate Love" first-
  // sponsoring House bills in 2019RS-2024RS, and "Senator Love" from 2025RS. Mary Ann Love (the only
  // other Delegate Love in the corpus) left in 2015, so 2019+ is unambiguous.
  'Sara Love': [{ chamber: 'house', from: 2019, to: 2024, src: 'corpus: "Delegate Love" 2019RS-2024RS (mgaleg tenure field omits it)' },
    { chamber: 'senate', from: 2024, to: 9999, src: 'mgaleg: Member of the Maryland Senate since June 13, 2024' }],
};

// ── fetch helpers ───────────────────────────────────────────────────────────────────────────────
async function billHtml(slug, session) {
  const f = path.join(BILLS, `${slug}-${session}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) return fs.readFileSync(f, 'utf8');
  const url = `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${session}`;
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  const body = await res.text();
  await sleep(1100);
  // ⚠ a short body is a block or an error page, never an empty bill — never cache it as truth
  if (!res.ok || body.length < 20000) return null;
  fs.writeFileSync(f, body);
  return body;
}
/**
 * Does a member slug still resolve to a person? Returns the page title, or null for a retired slug.
 *
 * 🔴 A RETIRED SLUG CANNOT DISPROVE IDENTITY. HB1300/2020 links its sponsor "Washington" to a bare
 * `washington` that now returns NotFound. Treating that as "a different member" retired Alonzo T.
 * Washington's genuine sponsorship of the bill he is in fact listed on — a false negative manufactured
 * by mgaleg's own URL churn. Only a slug that still resolves, to someone else, is evidence of someone
 * else.
 */
const slugNameCache = new Map();
async function slugResolvesTo(slug) {
  if (slugNameCache.has(slug)) return slugNameCache.get(slug);
  const html = await memberHtml(slug);
  const title = html ? (html.match(/<title>([^<]*)<\/title>/i) || [])[1] || '' : '';
  const name = /notfound/i.test(title) || !title.trim() ? null : title.replace(/^Members\s*-\s*/i, '').trim();
  slugNameCache.set(slug, name);
  return name;
}

async function memberHtml(slug) {
  const f = path.join(MEMBERS, `${slug}.html`);
  if (fs.existsSync(f) && fs.statSync(f).size > 5000) return fs.readFileSync(f, 'utf8');
  const res = await fetch(`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}`, { headers: { 'User-Agent': UA } });
  const body = await res.text();
  await sleep(1100);
  if (!res.ok || body.length < 5000) return null;
  fs.writeFileSync(f, body);
  return body;
}
/** Fetch a STORED citation exactly as stored, to test whether it resolves at all. */
async function checkStored(url) {
  const f = path.join(CACHE, 'stored-check', url.replace(/[^A-Za-z0-9]/g, '_').slice(0, 150) + '.txt');
  fs.mkdirSync(path.dirname(f), { recursive: true });
  if (fs.existsSync(f)) return JSON.parse(fs.readFileSync(f, 'utf8'));
  let rec;
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const buf = Buffer.from(await res.arrayBuffer());
    rec = { url, status: res.status, bytes: buf.length, final: res.url,
      pdf: buf.slice(0, 4).toString() === '%PDF' };
    await sleep(900);
  } catch (e) { rec = { url, status: null, error: String(e.message || e) }; }
  fs.writeFileSync(f, JSON.stringify(rec));
  return rec;
}

// ── the rows ────────────────────────────────────────────────────────────────────────────────────
const OWED = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-chair-fix-sourcing-owed.json', 'utf8'));
let rows = OWED.rows.filter((r) => ACTS.some((a) => a.claim.test(r.old_reasoning)));
if (ONLY) rows = rows.filter((r) => r.name === ONLY);
console.log(`\n${rows.length} owed row(s) name a landmark act.\n`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const out = [];
for (const r of rows) {
  // 🔑 production is the truth, not the owed file — 1714 has been applied since it was written
  const { rows: got } = await pool.query(
    `SELECT p.full_name, t.title AS topic, a.value, c.reasoning, c.sources
       FROM inform.politician_context c
       JOIN essentials.politicians p ON p.id = c.politician_id
       LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
       LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
      WHERE c.politician_id = $1::uuid AND c.topic_id = $2::uuid`, [r.politician_id, r.topic_id]);
  if (got.length !== 1) { out.push({ ...r, error: `expected 1 row, got ${got.length}` }); continue; }
  const live = got[0];
  if (live.full_name !== r.name) { out.push({ ...r, error: `identity mismatch: ${live.full_name}` }); continue; }

  const act = ACTS.find((a) => a.claim.test(live.reasoning));
  const sources = live.sources || [];
  const slug = (sources.map((s) => (s.match(/Members\/Details\/([A-Za-z0-9_-]+)/) || [])[1]).filter(Boolean))[0] || null;

  // (1) every stored mgaleg citation, fetched as stored
  const stored = [];
  for (const s of sources.filter((s) => /mgaleg\.maryland\.gov/.test(s))) stored.push(await checkStored(s));

  // (2) tenure -> chamber by year, checked against the legislative record
  let spans = [], tenure = null, override = null;
  if (slug) {
    const html = await memberHtml(slug);
    if (html) { tenure = tenureText(html); spans = chamberSpans(tenure); }
  }
  if (TENURE_OVERRIDE[live.full_name]) { spans = TENURE_OVERRIDE[live.full_name]; override = spans[0].src; }
  const sponsoredIn = sponsorSessions(live.full_name);
  const hiddenService = Object.entries(sponsoredIn)
    .filter(([s]) => !chamberForSession(spans, parseInt(s, 10)))
    .map(([s, ch]) => `${s} (${ch.join('/')})`);

  // (3) test the member against each candidate bill of the act
  const evidence = [];
  for (const b of act.bills) {
    const year = parseInt(b.session, 10);
    const ch = chamberForSession(spans, year);
    const html = await billHtml(b.slug, b.session);
    if (!html) { evidence.push({ bill: `${b.session} ${b.number}`, note: 'bill page unavailable' }); continue; }

    // ⚠ EVERY Maryland bill has at least one sponsor, so an EMPTY list is a parse failure, never an
    // absence. Reporting it as NOT_SPONSOR would manufacture a false negative — the same mistake the
    // sponsor index made when its net omitted whole topics.
    //
    // 🔴 CHAMBER GATE. A bill's sponsor list holds members of the bill's OWN chamber, so a surname on a
    // Senate bill cannot be a Delegate. Without this gate the pass credited Alonzo T. Washington — a
    // Delegate until 2023 — with sponsoring SB0414 and SB0528, whose "Washington" is Senator MARY
    // Washington. That is the exact cross-chamber collision this workstream has already been bitten by,
    // and a wrong chamber is a wrong PERSON, not a near miss.
    const sponsors = sponsorsOf(html);
    // 🔑 the hyperlinked slug settles identity where the surname cannot — see sponsorSlugs()
    const slugs = sponsorSlugs(html);
    const slugHit = slug ? slugs.find((s) => s.slug === slug) : null;
    const sur = live.full_name.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)\.?$/i, '').trim().split(/\s+/).pop().toLowerCase();
    const rivals = slug && !slugHit
      ? slugs.filter((s) => s.label.replace(/^[A-Z]\.\s*/, '').toLowerCase() === sur) : [];
    // a rival only counts if its slug STILL RESOLVES — see slugResolvesTo()
    let slugSaysNo = false, rivalName = null;
    for (const rv of rivals) {
      const nm = await slugResolvesTo(rv.slug);
      if (nm) { slugSaysNo = true; rivalName = `${nm} [${rv.slug}]`; break; }
    }

    const sp = !sponsors ? { verdict: 'NO_SPONSOR_BLOCK' }
      : sponsors.length === 0 ? { verdict: 'SPONSOR_LIST_UNPARSED' }
      : slugHit ? { verdict: 'SPONSOR', matched: `${slugHit.label} [${slugHit.slug}]`, by: 'slug' }
      // a surname on the list that links to a DIFFERENT member is someone else, full stop
      : slugSaysNo ? { verdict: 'NOT_SPONSOR', by: 'slug-mismatch', note: `that surname on this list is ${rivalName}` }
      : !ch ? { verdict: 'CHAMBER_UNKNOWN' }
      : ch !== b.chamber ? { verdict: 'WRONG_CHAMBER', note: `${b.chamber} bill; member sat in the ${ch}` }
      : locateSponsor(sponsors, live.full_name);

    const votes = passageVotes(html);
    const mine = ch ? votes.filter((v) => v.chamber === ch) : [];
    const voteResults = [];
    for (const v of mine) {
      const txt = await voteText(v.href, VOTES);
      if (!txt) { voteResults.push({ ...v, verdict: 'PDF_UNAVAILABLE' }); continue; }
      const p = parseVote(txt);
      if (!p.ok) { voteResults.push({ ...v, verdict: 'PARSE_VOID', reason: p.reason }); continue; }
      const loc = locate(p.blocks, live.full_name);
      voteResults.push({ ...v, verdict: loc.verdict, matched: loc.matched ?? null,
        candidates: loc.candidates ?? null, declared: p.declared });
    }
    evidence.push({
      bill: `${b.session} ${b.number}`, slug: b.slug, session: b.session, title: b.title,
      url: `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${b.slug}?ys=${b.session}`,
      // ⚠ "no chamber" has two very different causes and they must not be reported as one: the member
      // was NOT SERVING (a real pre-tenure finding — the claim cannot be true), or the tenure could not
      // be read (we simply do not know). Conflating them turns ignorance into a verdict.
      chamber: ch,
      chamber_note: ch ? null : spans.length ? 'NOT_SERVING in that session' : 'TENURE_UNPARSED — chamber unknown',
      sponsor: sp.verdict, sponsor_matched: sp.matched ?? null, sponsor_by: sp.by ?? 'surname',
      sponsor_note: sp.note ?? null, n_sponsors: sponsors ? sponsors.length : null,
      votes: voteResults,
    });
  }

  const yea = evidence.flatMap((e) => e.votes.filter((v) => v.verdict === 'YEA').map((v) => ({ ...v, bill: e.bill, url: e.url })));
  const sponsored = evidence.filter((e) => e.sponsor === 'SPONSOR');
  out.push({
    politician_id: r.politician_id, topic_id: r.topic_id, name: live.full_name, topic: live.topic,
    chair: Number(live.value), act: act.key, reasoning: live.reasoning, sources, member_slug: slug,
    tenure, spans, tenure_override: override, sponsored_sessions: sponsoredIn, hidden_service: hiddenService,
    stored, evidence,
    carries: sponsored.length ? 'SPONSOR' : yea.length ? 'YEA' : 'NONE',
  });
  const w = out[out.length - 1];
  console.log(`  ${w.carries.padEnd(7)} ${live.full_name} / ${live.topic}`
    + (hiddenService.length ? `   ⚠ sponsors outside tenure: ${hiddenService.join(', ')}` : ''));
}
await pool.end();

const tally = out.reduce((m, x) => { m[x.carries ?? 'ERROR'] = (m[x.carries ?? 'ERROR'] || 0) + 1; return m; }, {});
console.log('\n' + JSON.stringify(tally, null, 2));
fs.writeFileSync(OUT, JSON.stringify({ pass: 'landmark-act sourcing for the mig-1714 rows', tally, rows: out }, null, 1));
console.log(`wrote ${OUT}`);

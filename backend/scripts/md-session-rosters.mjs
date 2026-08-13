#!/usr/bin/env node
/**
 * Resolve each Maryland member's SESSION-CORRECT mgaleg slug, so the sessions that
 * md-member-legislation.mjs reports as UNAVAILABLE_SESSION become readable.
 *
 * 🔑 THE PROBLEM. An mgaleg member record is CHAMBER-SCOPED and the slug is retired when a member
 * moves. Ask `washington02` (Alonzo's Senate slug) for 2020RS and you get a 200 with an empty
 * legislation list — not an error. Treating that as "sponsored nothing" manufactures a false absence
 * for every chamber-switcher, which is the defect class this workstream exists to remove. The fix is
 * to ask under the slug that session actually used.
 *
 * 🔴🔴 THE SPEC'S MECHANISM DOES NOT EXIST — DO NOT REINSTATE IT.
 * `.planning/todos/2026-08-12-md-unreadable-sessions-fallback.md` proposed reading the per-session
 * chamber rosters at `Members/Index/house?ys=<session>` / `Members/Index?ys=<session>`. Both return
 * 200 with a plausible roster, and both IGNORE `ys` entirely. Measured 2026-08-12: the 2013RS and
 * 2019RS House responses are the same 220,196 bytes and the ONLY textual difference is the `ys`
 * echoed into the Facebook and Twitter share links; the slug sets are identical. Both serve the
 * CURRENT roster — the giveaway is `<img src="/2026RS/images/...">` on a page requested as 2019RS.
 * The "confirmation" that the 2019 Senate roster carried `washington01`/`kramer02`/`muse01` did not
 * discriminate, because those members are in the CURRENT Senate too. The page carries anachronisms
 * that settle it: the "2019 Senate roster" lists Sara Love, who did not join the Senate until June
 * 2024. The Members/Index page has no session <select> at all — mgaleg publishes no historical
 * roster. A 200 is not a session.
 *
 * ✅ WHAT ACTUALLY WORKS, and it is cheaper: the legislation search page renders a SPONSOR INDEX that
 * IS session-scoped, keyed on `session` (not `ys`):
 *     https://mgaleg.maryland.gov/mgawebsite/Search/Legislation?session=2013rs
 * Its `#valueSponsors` options are `value="<slug>#<h|s|o>"` with the full display name:
 *     washington a#h = Washington, Alonzo T., Delegate
 *     kramer b#h     = Kramer, Benjamin F., Delegate
 * One fetch per session — 13, not 26 — and it yields slug + chamber + FULL NAME together.
 *
 * 🔴 AND IT IS THE ONLY THING THAT FINDS THEM. Alonzo Washington's and Benjamin Kramer's House-era
 * slugs contain a SPACE (`washington a`, `kramer b`). No amount of guessing `<surname><NN>` reaches
 * them; a shape probe of 7 variants each returned the 56,073-byte "no record" page every time. The
 * comment in md-member-legislation.mjs claiming Alonzo's House record is the retired `washington`
 * slug is WRONG — `washington?ys=2016RS` is *Mary L.* Washington, 247 bills. That is the surname
 * trap firing on the very member the trap was written about.
 *
 * 🔴 IDENTITY RULES (a slug is identity; a surname is a guess)
 *  - Match on FULL NAME, never surname. The 2019 House `watson02` is COURTNEY Watson, not Ron; Ron is
 *    `watson03`. `washington01`/`washington02` are Mary and Alonzo and both sat in the 2019 Senate.
 *  - Then VERIFY: fetch the member-session page and re-check the name the PAGE ITSELF displays. A
 *    roster match that the page contradicts is discarded, not reconciled.
 *  - A record exists for that session iff the page carries a session-scoped portrait path
 *    `/<session>/images/`. Bill count is NOT the test — a member may sponsor nothing.
 *  - Page signatures: 56,073 bytes with no <h2> = no such record; ~62-65KB with a name but no
 *    session image = the slug exists but not in that session.
 *
 * ⚠ THE SPONSOR INDEX IS NOT A ROSTER, IN BOTH DIRECTIONS.
 *  - It UNDER-includes: it lists members who sponsored at least one bill. A member absent from it is
 *    recorded NOT_IN_SPONSOR_INDEX — which is NOT "absent from the chamber". Only the tenure spans
 *    decide that, and this script says so explicitly rather than letting an absence read as a
 *    finding. That distinction is the whole point of the pass.
 *  - It OVER-includes at a TERM BOUNDARY: the 2015RS index carries 258 members, not 188, because 70
 *    members of the 2011-2014 term (Arora, Bobo, McDermott …) are still listed; 69 of them also
 *    appear in 2014RS. So membership in the index is not membership in the session.
 *    ✅ The RECORD test catches it: `mcdermott?ys=2015RS` returns 63,039 bytes with his name, no
 *    session portrait path and 0 bills (rejected), while `?ys=2014RS` returns 404,844 bytes with
 *    `/2014RS/images/` and 200 bills (accepted). Never accept an index row without that check.
 *
 * 🔴 Reads only. Emits a slug map; nothing here decides a chair or writes a citation.
 *   node scripts/md-session-rosters.mjs [--in <legislation.json>] [--out <map.json>] [--only "Name"]
 */
import fs from 'node:fs';
import path from 'node:path';
import { UA } from './lib/md-rollcall.mjs';
import { chamberForSession } from './lib/md-tenure.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in', 'data/stance-retirement/2026-08-12-chairs-owed-md-legislation.json');
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-md-session-slugmap.json');
const ONLY = flag('--only');
/** the session whose sponsor index is searched for members carrying no slug at all */
const BASE_SESSION = flag('--base-session', '2026RS');

const CACHE = 'C:/Users/Chris/AppData/Local/Temp/ev-stance-cache/mdcorpus';
const ROSTERS = path.join(CACHE, 'roster-cache');
const SESS = path.join(CACHE, 'member-session-cache');
for (const d of [ROSTERS, SESS]) fs.mkdirSync(d, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── name handling ───────────────────────────────────────────────────────────────────────────────
const SUFFIX = /^(jr|sr|ii|iii|iv|v)\.?$/i;
const norm = (s) => (s || '').toLowerCase().replace(/[.,]/g, '').replace(/\s+/g, ' ').trim();

/**
 * "Washington, Alonzo T., Delegate" -> {name: 'Alonzo T. Washington', chamber: 'house'}
 * ⚠ the suffix is its own comma-part ("Smith, William C., Jr., Senator"), so strip the title first,
 * then lift a trailing Jr./Sr./III before deciding which part is the surname.
 */
export function parseRosterName(display) {
  let parts = display.split(',').map((s) => s.trim()).filter(Boolean);
  let chamber = null;
  if (parts.length && /^(Delegate|Senator)$/i.test(parts[parts.length - 1])) {
    chamber = /^Senator$/i.test(parts.pop()) ? 'senate' : 'house';
  }
  let suffix = null;
  if (parts.length > 2 && SUFFIX.test(parts[parts.length - 1])) suffix = parts.pop();
  if (parts.length < 2) return { name: parts.join(' '), chamber, surname: parts[0] || '', given: '' };
  const [surname, given] = parts;
  return { name: `${given} ${surname}${suffix ? `, ${suffix}` : ''}`, chamber, surname, given, suffix };
}

/** given-name compatibility: "Ron"~"Ronald", "Nick"~"Nicholas", "Kevin M."~"Kevin Michael" */
function givenCompatible(a, b) {
  const at = norm(a).split(' ').filter(Boolean);
  const bt = norm(b).split(' ').filter(Boolean);
  if (!at.length || !bt.length) return false;
  const one = (x, y) => x === y || (x.length === 1 && y.startsWith(x)) || (y.length === 1 && x.startsWith(y))
    || (x.length > 2 && y.startsWith(x)) || (y.length > 2 && x.startsWith(y));
  return one(at[0], bt[0]);
}

// ── the session-scoped sponsor index ────────────────────────────────────────────────────────────
async function sponsorIndex(session) {
  const f = path.join(ROSTERS, `sponsors-${session}.html`);
  let h = fs.existsSync(f) && fs.statSync(f).size > 100000 ? fs.readFileSync(f, 'utf8') : null;
  if (!h) {
    const url = `https://mgaleg.maryland.gov/mgawebsite/Search/Legislation?session=${session.toLowerCase()}`;
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    const body = await res.text();
    await sleep(1200);
    // ⚠ a short body is a block or an error page, never an empty sponsor list
    if (!res.ok || body.length < 100000) throw new Error(`${session}: sponsor index ${res.status}, ${body.length}B`);
    fs.writeFileSync(f, body); h = body;
  }
  const i = h.indexOf('id="valueSponsors"');
  if (i < 0) throw new Error(`${session}: no #valueSponsors select — the page shape changed`);
  const block = h.slice(i, h.indexOf('</select>', i));
  const rows = [];
  for (const m of block.matchAll(/<option[^>]*value="([^"]*)"[^>]*>([^<]*)</g)) {
    const [, value, label] = m;
    if (!value) continue;
    const [slug, kind] = value.split('#');
    if (kind === 'o') continue;                       // committees, delegations, agencies
    const p = parseRosterName(label.trim());
    // ⚠ the value's #h/#s marker is authoritative for chamber; the LABEL's title is often missing
    // ("Henson, Shaneka" with no ", Delegate"), so it must not clobber the marker.
    rows.push({ session, slug, display: label.trim(), ...p, chamber: kind === 's' ? 'senate' : 'house' });
  }
  if (rows.length < 100) throw new Error(`${session}: only ${rows.length} members parsed — refusing a partial index`);
  return rows;
}

/** ⚠ a 200 is not identity. Confirm the name the PAGE displays, and that the session record exists. */
async function verify(slug, session) {
  const f = path.join(SESS, `${slug}-${session}.html`);
  let h = fs.existsSync(f) && fs.statSync(f).size > 5000 ? fs.readFileSync(f, 'utf8') : null;
  if (!h) {
    const url = `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${encodeURIComponent(slug)}?ys=${session}`;
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    const body = await res.text();
    await sleep(1200);
    if (!res.ok || body.length < 5000) return { status: 'FETCH_FAILED' };
    fs.writeFileSync(f, body); h = body;
  }
  const h2 = (h.match(/<h2>\s*(?:Delegate|Senator)?\s*([^<]{2,80}?)\s*<\/h2>/) || [])[1] || null;
  const alt = (h.match(/images\/[^"']+\.jpg"\s*alt="([^"]+)"/i) || [])[1] || null;
  const imgSession = (h.match(/\/(\d{4}(?:RS|S\d))\/images\//) || [])[1] || null;
  const bills = new Set([...h.matchAll(/Legislation\/Details\/([a-z]{2}\d{4})\?ys=(\w+)/g)]
    .filter((m) => m[2] === session).map((m) => m[1])).size;
  // the session portrait path is the record test — NOT the bill count
  const status = imgSession === session ? 'RECORD' : (h2 ? 'SLUG_EXISTS_OTHER_SESSION' : 'NO_RECORD');
  return { status, h2, alt, imgSession, bills, bytes: h.length };
}

// ── the owed work: members × sessions md-member-legislation.mjs could not read ───────────────────
const leg = JSON.parse(fs.readFileSync(IN, 'utf8')).rows;
const members = {};
for (const r of leg) {
  if (ONLY && r.name !== ONLY) continue;
  const m = (members[r.name] ??= { name: r.name, current_slug: r.member_slug, spans: r.spans || [], unreadable: new Set() });
  for (const s of r.sessions_unreadable || []) m.unreadable.add(s);
}
const owed = Object.values(members).filter((m) => m.unreadable.size);
/**
 * ⚠ A SECOND, DIFFERENT GAP. Some members have no slug AT ALL — nothing in their row's `sources`
 * carries a `Members/Details/` URL, so md-member-legislation.mjs skips them entirely and they read
 * ZERO sessions. That is not a wrong-session slug, it is a missing one, and it looks identical in the
 * output (no candidates) while having nothing to do with chamber scoping. The same session sponsor
 * index answers it, matched on full name and verified against the member page.
 */
const needBase = Object.values(members).filter((m) => !m.current_slug);
const SESSIONS = [...new Set([...owed.flatMap((m) => [...m.unreadable]),
  ...(needBase.length ? [BASE_SESSION] : [])])].sort();
console.log(`${owed.length} member(s) with unreadable sessions; `
  + `${needBase.length} member(s) with NO slug at all${needBase.length ? `: ${needBase.map((m) => m.name).join(', ')}` : ''}`);
console.log(`${SESSIONS.length} session index/indexes to fetch: ${SESSIONS.join(', ')}`);
console.log(`complete already (0 unreadable, has a slug): ${Object.values(members)
  .filter((m) => !m.unreadable.size && m.current_slug).map((m) => m.name).join(', ') || 'none'}\n`);

// ── 1. one sponsor index per session ────────────────────────────────────────────────────────────
const index = {};
for (const s of SESSIONS) {
  index[s] = await sponsorIndex(s);
  const h = index[s].filter((r) => r.chamber === 'house').length;
  console.log(`  ${s}: ${index[s].length} members in the sponsor index (${h} house / ${index[s].length - h} senate)`);
}

// ── 2. match FULL NAME (+ the chamber the member actually sat in), then verify ───────────────────
/** every index entry across all sessions that is this member, by full name */
function entriesFor(name) {
  const want = norm(name);
  const sur = want.split(' ').pop();
  const given = name.split(' ').slice(0, -1).join(' ');
  const out = [];
  for (const s of SESSIONS) {
    for (const r of index[s]) {
      if (norm(r.name) === want) out.push({ ...r, match: 'EXACT' });
      // 🔴 surname alone is NEVER enough — it must also be given-name compatible
      else if (norm(r.surname) === sur && givenCompatible(r.given, given)) out.push({ ...r, match: 'INEXACT' });
    }
  }
  return out;
}

/** the page must agree about WHO this is, on surname AND given name */
function pageAgrees(pageName, wantName) {
  if (!pageName) return false;
  const want = norm(wantName);
  if (norm(pageName) === want) return true;
  return norm(pageName).split(' ').pop() === want.split(' ').pop()
    && givenCompatible(pageName.split(' ')[0], wantName.split(' ')[0]);
}

const resolutions = []; const unresolved = [];
for (const m of owed) {
  const all = entriesFor(m.name);
  console.log(`\n${m.name}  [current: ${m.current_slug || 'none'}]`);
  for (const s of [...m.unreadable].sort()) {
    const year = parseInt(s, 10);
    // 🔴🔴 THE APPOINTED-MID-YEAR TRAP, AGAIN. The sponsor index labels a member by the chamber they
    // ended the session in, not the one they legislated in. Ron Watson joined the Senate on August
    // 31 2021 — months AFTER the 2021 session adjourned — so the 2021 index lists him as a Senator
    // (watson04, ZERO bills) while every 2021 bill of his sits under his House slug watson03. Same
    // shape for Sara Love, whose 2024 index carries BOTH love01#h and love02#s. The tenure spans,
    // which are month-aware, decide; the index label does not.
    const expected = chamberForSession(m.spans, year);
    let hits = index[s].filter((r) => all.some((a) => a.slug === r.slug && a.session === s));
    let via = 'INDEX';
    if (expected && hits.some((r) => r.chamber === expected)) hits = hits.filter((r) => r.chamber === expected);
    else if (expected && hits.length) {
      // indexed only under the wrong chamber — take this member's slug for the RIGHT chamber from
      // any other session and let the member page for THIS session confirm or reject it.
      const cross = [...new Set(all.filter((a) => a.chamber === expected).map((a) => a.slug))];
      if (cross.length) {
        hits = cross.map((slug) => ({ ...all.find((a) => a.slug === slug), session: s }));
        via = 'CROSS_SESSION';
      }
    }
    if (!hits.length) {
      // ⚠ NOT being in the sponsor index is not yet an absence. Before saying so, ask the member
      // route directly under EVERY slug this member is known to have used, in any session. Only
      // when none of them holds a record for this session — and the tenure span agrees — is the
      // absence a real one rather than an unread one.
      const known = [...new Set([...all.map((a) => a.slug), m.current_slug].filter(Boolean))];
      const probes = [];
      for (const slug of known) {
        const v = await verify(slug, s);
        const pn = v.h2 || (v.alt ? parseRosterName(v.alt).name : null);
        probes.push({ slug, status: v.status, page_name: pn, n_bills: v.bills });
        if (v.status === 'RECORD' && pageAgrees(pn, m.name)) probes.at(-1).hit = true;
      }
      const hit = probes.find((p) => p.hit);
      if (hit) {   // the index was incomplete, the member route was not
        resolutions.push({ name: m.name, session: s, slug: hit.slug, chamber: expected,
          expected_chamber: expected, resolved_via: 'SLUG_PROBE', roster_name: null, match: 'PROBE',
          page_name: hit.page_name, n_bills: hit.n_bills, zero_bills: hit.n_bills === 0 });
        console.log(`   ${s}  ✓ ${hit.slug.padEnd(16)} ${String(expected).padEnd(6)} "${hit.page_name}" `
          + `${hit.n_bills} bill(s)  ⚠ found by slug probe, absent from the sponsor index`);
        continue;
      }
      // ⚠ A YEAR-GRANULAR SPAN BOUNDARY IS NOT SERVICE. mgaleg writes "House of Delegates 2014-2016"
      // for a member ELECTED in November 2014 and seated in January 2015, and "Senate 2007-2019" for
      // one whose service ended as the 2019 session convened. On such a boundary year the member did
      // not sit for that session, so no record is the correct answer rather than a missing one.
      const boundary = (m.spans || []).filter((sp) => (sp.from === year || sp.to === year)
        && !/\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s*\d{4}/.test(sp.src || ''));
      const inOffice = expected != null && !boundary.length;
      unresolved.push({ name: m.name, session: s,
        reason: inOffice ? 'ABSENT_NO_RECORD_UNDER_ANY_KNOWN_SLUG'
          : boundary.length ? 'ABSENT_AT_YEAR_GRANULAR_SPAN_BOUNDARY' : 'NOT_IN_OFFICE',
        expected_chamber: expected, boundary_spans: boundary.map((b) => b.src),
        spans: m.spans, slugs_probed: probes,
        note: inOffice
          ? 'Not in the session sponsor index AND no session record under any known slug, while the '
            + 'tenure puts the member in office — READ THIS ONE; it is not yet a real absence.'
          : boundary.length
            ? 'The session year sits on a YEAR-GRANULAR tenure boundary (no month/day in the span), '
              + 'and no record exists under any known slug: consistent with a REAL absence — the '
              + 'member was not seated for this session. Confirm against the quoted span.'
            : 'The tenure spans put this member outside the legislature for this session — a REAL '
              + 'absence, not an unread one.' });
      console.log(`   ${s}  ${inOffice ? '⚠ NO record under any known slug — READ THIS'
        : boundary.length ? '∅ absent: year-granular tenure boundary' : '∅ NOT IN OFFICE (tenure)'}`
        + ` [probed ${probes.map((p) => `${p.slug}:${p.status}`).join(', ')}]`
        + (boundary.length ? `  — "${boundary[0].src}"` : ''));
      continue;
    }
    // verify every surviving candidate; only a unique confirmed record may be emitted
    const confirmed = [];
    for (const hit of hits) {
      const v = await verify(hit.slug, s);
      const pageName = v.h2 || (v.alt ? parseRosterName(v.alt).name : null);
      if (v.status === 'RECORD' && pageAgrees(pageName, m.name)) confirmed.push({ hit, v, pageName });
      else console.log(`   ${s}  · rejected ${hit.slug} → ${v.status}${pageName ? ` page says "${pageName}"` : ''}`);
    }
    if (!confirmed.length) {
      unresolved.push({ name: m.name, session: s, reason: 'VERIFY_FAILED',
        tried: hits.map((h) => h.slug), expected_chamber: expected });
      console.log(`   ${s}  ✗ no candidate verified (tried ${hits.map((h) => h.slug).join(', ')})`);
      continue;
    }
    if (confirmed.length > 1) {   // never guess between two confirmed identities
      unresolved.push({ name: m.name, session: s, reason: 'AMBIGUOUS', expected_chamber: expected,
        detail: confirmed.map((c) => `${c.hit.slug}=${c.hit.display}`) });
      console.log(`   ${s}  AMBIGUOUS — ${confirmed.map((c) => c.hit.slug).join(' | ')}`);
      continue;
    }
    const { hit, v, pageName } = confirmed[0];
    resolutions.push({ name: m.name, session: s, slug: hit.slug, chamber: hit.chamber,
      expected_chamber: expected, resolved_via: via, roster_name: hit.display, match: hit.match,
      page_name: pageName, n_bills: v.bills, zero_bills: v.bills === 0 });
    console.log(`   ${s}  ✓ ${hit.slug.padEnd(16)} ${String(hit.chamber).padEnd(6)} "${pageName}" ${v.bills} bill(s)`
      + (hit.match === 'INEXACT' ? '  ⚠ INEXACT name' : '') + (via === 'CROSS_SESSION' ? '  ⚠ chamber-corrected' : '')
      + (v.bills === 0 ? '  ⚠ ZERO bills — record exists but is empty' : ''));
  }
}

// ── 2b. members with no slug at all: resolve a BASE slug the same way ───────────────────────────
const baseSlugs = {};
for (const m of needBase) {
  const all = entriesFor(m.name);
  if (!all.length) {
    unresolved.push({ name: m.name, session: BASE_SESSION, reason: 'BASE_SLUG_NOT_IN_SPONSOR_INDEX',
      note: 'No sponsor-index entry under this full name in any fetched session.' });
    console.log(`\n${m.name}  ∅ no sponsor-index entry under this full name`);
    continue;
  }
  // prefer the newest session this member appears in — that is the record most likely to be live
  const bySession = [...all].sort((a, b) => b.session.localeCompare(a.session));
  const tried = [];
  let done = null;
  for (const cand of bySession) {
    if (tried.some((t) => t.slug === cand.slug && t.session === cand.session)) continue;
    const v = await verify(cand.slug, cand.session);
    const pageName = v.h2 || (v.alt ? parseRosterName(v.alt).name : null);
    tried.push({ slug: cand.slug, session: cand.session, status: v.status, page_name: pageName });
    if (v.status === 'RECORD' && pageAgrees(pageName, m.name)) { done = { cand, v, pageName }; break; }
  }
  if (!done) {
    unresolved.push({ name: m.name, session: BASE_SESSION, reason: 'BASE_SLUG_VERIFY_FAILED', tried });
    console.log(`\n${m.name}  ✗ no candidate verified (${tried.map((t) => `${t.slug}@${t.session}:${t.status}`).join(', ')})`);
    continue;
  }
  // ⚠ a slug is only unambiguous if no OTHER full-name match resolves to a different slug
  const rivals = [...new Set(all.map((a) => a.slug))].filter((s) => s !== done.cand.slug);
  baseSlugs[m.name] = { slug: done.cand.slug, chamber: done.cand.chamber, from_session: done.cand.session,
    roster_name: done.cand.display, match: done.cand.match, page_name: done.pageName, rival_slugs: rivals };
  console.log(`\n${m.name}  ✓ base slug ${done.cand.slug} (${done.cand.chamber}, from ${done.cand.session}) `
    + `"${done.pageName}"${rivals.length ? `   ⚠ other slugs under this name: ${rivals.join(', ')}` : ''}`);
}

// ── 3. emit ─────────────────────────────────────────────────────────────────────────────────────
const slugmap = {};
for (const r of resolutions) (slugmap[r.name] ??= {})[r.session] = r.slug;
fs.writeFileSync(OUT, JSON.stringify({
  pass: 'MD session-correct member slugs, from the session-scoped sponsor index',
  mechanism: 'Search/Legislation?session=<session> #valueSponsors — the Members/Index ys= roster is '
    + 'NOT session-scoped and must not be used; see the header of this script',
  caveat: 'The sponsor index lists members who sponsored at least one bill. NOT_IN_SPONSOR_INDEX is '
    + 'not evidence of absence from the chamber — only the tenure spans decide that.',
  n_resolved: resolutions.length, n_unresolved: unresolved.length, n_base_slugs: Object.keys(baseSlugs).length,
  base_slugs: baseSlugs, slugmap, resolutions, unresolved,
}, null, 1));

console.log(`\n${resolutions.length} (member, session) pair(s) resolved; ${unresolved.length} unresolved.`);
for (const u of unresolved) console.log(`   ${u.reason.padEnd(26)} ${u.name} / ${u.session}${u.slug ? ` [${u.slug}]` : ''}`);
console.log(`wrote ${OUT}`);

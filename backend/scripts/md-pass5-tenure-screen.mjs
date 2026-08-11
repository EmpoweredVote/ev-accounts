#!/usr/bin/env node
/**
 * PASS 5, STEP 1 -- TENURE SCREEN for the 157 NO_SPONSOR_LINK rows.
 *
 * Before hunting roll calls, settle the cheap decisive question: was the politician even in office when
 * the bill they are credited with was considered? If not, the claim is IMPOSSIBLE (the Guzzone pattern,
 * mig 1692) and no roll call can rescue it.
 *
 * 🔑 This also protects the roll-call pass from its worst failure mode: a member who was not serving does
 *    not appear in the vote list at all, so ABSENCE FROM A ROLL CALL WOULD READ AS "did not support" when
 *    it really means "was not there". Screen tenure first so absence is only ever interpreted in-tenure.
 *
 * Service history is read off the mgaleg member page, which lists every chamber and span, e.g.
 *   "Member of the Senate since January 9, 2019." / "Member of the House of Delegates 2011-2019."
 *   "House of Delegates December 19, 2012 to January 30, 2023."
 * The EARLIEST year found across all such lines is the service start.
 *
 * 🔴 Reads only.
 */
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'node-html-parser';
import { tenureText, chamberSpans, serviceStart as svcStart } from './lib/md-tenure.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const WORKLIST = flag('--worklist'), SPONS = flag('--sponsorship'), CACHE = flag('--cache'), OUT = flag('--out');
if (!WORKLIST || !SPONS || !CACHE || !OUT) { console.error('need --worklist --sponsorship --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const wl = JSON.parse(fs.readFileSync(WORKLIST, 'utf8'));
const sp = JSON.parse(fs.readFileSync(SPONS, 'utf8'));
const rows = sp.rows.filter((r) => r.verdict === 'NO_SPONSOR_LINK');
const wlBy = new Map(wl.rows.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));

/** The member page, fetched in whatever form resolves; identity is not at stake here, only dates. */
async function memberPage(slug) {
  const file = path.join(CACHE, `${slug.replace(/[^A-Za-z0-9]/g, '_')}.html`);
  if (fs.existsSync(file)) { const c = fs.readFileSync(file, 'utf8'); return c === '<DEAD>' ? null : c; }
  for (const u of [`https://mgaleg.maryland.gov/mgawebsite/Members/Details/${encodeURI(slug)}`,
                   ...['2026RS', '2023RS', '2021RS', '2019RS'].map((y) => `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${encodeURI(slug)}?ys=${y}`)]) {
    const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    await sleep(1200);
    if (/Error\/NotFound/i.test(res.url) || body.length < 10_000) continue;
    fs.writeFileSync(file, body); return body;
  }
  fs.writeFileSync(file, '<DEAD>'); return null;
}

/**
 * Earliest service year, from the STRUCTURED Tenure field only.
 * ⚠ The first version regexed all page text and captured nav menus, office addresses and hearing
 * notices, producing junk spans and PRE_TENURE verdicts built on noise. See lib/md-tenure.mjs.
 */
function serviceStart(html) {
  const tenure = tenureText(html);
  const spans = chamberSpans(tenure);
  return { start: svcStart(spans, tenure), lines: tenure ? [tenure] : [], spans };
}

/**
 * ⚠ Take the cited slug from the LIVE DB, never from the pass-4b snapshot. That snapshot predates migs
 * 1689/1693, which repaired 33+5 politicians' dead member slugs; reading it made 39 rows look
 * TENURE_UNKNOWN purely because the stale copy still held `bagnall`, `hill04`, `west01`…
 * A screen run on stale inputs reports the state of the inputs, not of production.
 */
const pg = (await import('pg')).default;
const env2 = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const dburl = env2.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: dburl, ssl: { rejectUnauthorized: false } });
const { rows: liveSlugs } = await pool.query(`
  SELECT DISTINCT c.politician_id, substring(s from 'Members/Details/([^?#]+)') AS slug
  FROM inform.politician_context c CROSS JOIN LATERAL unnest(c.sources) AS s
  WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Members/Details/%'`);
await pool.end();
const slugByPid = new Map(liveSlugs.filter((r) => r.slug).map((r) => [r.politician_id, decodeURIComponent(r.slug)]));

// One page per politician.
const starts = new Map();
for (const r of rows) {
  if (starts.has(r.politician)) continue;
  const slug = slugByPid.get(r.politician_id);
  if (!slug) { starts.set(r.politician, { start: null, lines: [], slug: null }); continue; }
  const html = await memberPage(slug);
  starts.set(r.politician, html ? { ...serviceStart(html), slug } : { start: null, lines: [], slug });
}

const out = [];
for (const r of rows) {
  const w = wlBy.get(`${r.politician_id}|${r.topic_id}`);
  const bills = [];
  for (const i of (w?.instruments ?? [])) for (const h of i.hits) bills.push({ session: h.session, number: h.number, title: h.title, slug: h.slug, instrument: i.instrument });
  const uniq = [...new Map(bills.map((b) => [`${b.session}|${b.number}`, b])).values()];
  const st = starts.get(r.politician);
  const latest = uniq.length ? Math.max(...uniq.map((b) => parseInt(b.session, 10))) : null;
  const inTenure = uniq.filter((b) => st?.start != null && parseInt(b.session, 10) >= st.start);

  let verdict;
  if (!uniq.length) verdict = 'NO_BILL_RESOLVED';
  else if (st?.start == null) verdict = 'TENURE_UNKNOWN';
  else if (!inTenure.length) verdict = 'PRE_TENURE_ALL_BILLS';
  else verdict = 'IN_TENURE_NEEDS_ROLLCALL';

  out.push({
    politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    cited_slug: st?.slug ?? null, service_start: st?.start ?? null, service_lines: st?.lines ?? [],
    reasoning: r.reasoning, claim_verb: /\bsponsor/i.test(r.reasoning) ? 'sponsored' : /\bvoted\b/i.test(r.reasoning) ? 'voted' : 'supported/backed',
    bills: uniq, bills_in_tenure: inTenure, latest_bill_session: latest, verdict,
  });
}

const tally = out.reduce((m, x) => { m[x.verdict] = (m[x.verdict] || 0) + 1; return m; }, {});
console.log(JSON.stringify(tally, null, 2));
console.log('\n=== PRE_TENURE_ALL_BILLS (claim impossible) ===');
for (const x of out.filter((y) => y.verdict === 'PRE_TENURE_ALL_BILLS')) {
  console.log(`  ${x.politician} (from ${x.service_start}) / ${x.topic}`);
  console.log(`     bills: ${x.bills.map((b) => b.session + ' ' + b.number).join(', ')}`);
  console.log(`     claim: ${x.reasoning.slice(0, 110)}`);
}
console.log('\n=== TENURE_UNKNOWN / NO_BILL_RESOLVED ===');
for (const x of out.filter((y) => y.verdict === 'TENURE_UNKNOWN' || y.verdict === 'NO_BILL_RESOLVED')) {
  console.log(`  [${x.verdict}] ${x.politician} / ${x.topic}  slug=${x.cited_slug}`);
}
fs.writeFileSync(OUT, JSON.stringify({ pass: 'MD pass 5 step 1 - tenure screen', tally, rows: out }, null, 1));

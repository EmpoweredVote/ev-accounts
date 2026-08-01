#!/usr/bin/env node
/**
 * Repair the PRIMARY_SITE_NO_PATH cohort: find the page on the subject's own site that carries the
 * claim, so the citation points at it instead of at the front door.
 *
 * WHY THIS IS A REPAIR AND NOT A RETIREMENT. These 601 rows cite a bare root with no path. The first
 * write-up called the class "indefensible on their face" and proposed retiring it wholesale. Measured
 * 2026-07-31, that description fits exactly ONE row: 596 cite the candidate's own campaign site, 5 an
 * officeholder's own .gov office site, 1 a multi-subject reference root. Six sampled homepages were
 * fetched and grepped for the exact claim credited to them and 6 of 6 contained it -- these sites put
 * their issues content on the front page. The citation is imprecise, not absent, and 367 of the rows
 * are live on candidate cards. Retiring them would have deleted ~596 true, sourced rows.
 *
 * 🔴 THIS SCRIPT MAY NEVER SWAP IN A DIFFERENT SOURCE. The site is already right. The only edit it
 * proposes is a MORE SPECIFIC URL ON THE SAME HOST, and only when the claim verifies there. Anything
 * else -- claim not found, site unreadable, JS-only shell -- is reported, never guessed at.
 *
 * VERDICTS
 *   DEEP_PAGE         the claim verifies on an interior page; propose that URL          (apply)
 *   HOMEPAGE_ANCHOR   claim verifies on the homepage inside a section with an id        (apply)
 *   HOMEPAGE_ONLY     claim verifies, but only on the homepage and with no anchor       (leave; correct as-is)
 *   NOT_FOUND         site read fine, claim is on none of its pages                     (human read)
 *   UNREADABLE        non-200, empty, or a JS shell -- NEVER counted as NOT_FOUND       (re-run)
 *   UNTESTABLE        no quote and no distinctive term survived extraction              (human read)
 *
 * 🔴 A THIN BODY IS NOT AN ABSENT CLAIM. A React/Vue campaign site serves an empty shell to a plain
 * fetch. Scoring that as "claim not on the site" is the same false negative as Ballotpedia's silent
 * HTTP 202, which already produced one wrong sweep. Under MIN_BODY chars => UNREADABLE, full stop.
 *
 * Matchers come from ./lib/claim-match.mjs -- the same calibrated quote/term logic the citation audit
 * uses, including the chair-label and apostrophe fixes. Do not re-implement them here.
 *
 * Usage (from backend/):
 *   node scripts/repair-primary-site-paths.mjs --limit 20 --out data/stance-retirement/repair-sample.json
 *   node scripts/repair-primary-site-paths.mjs --out data/stance-retirement/2026-07-31-primary-site-paths.json
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';
import { parse } from 'node-html-parser';
import {
  extractQuotes, quotePresent, looseIncludes, candidateTerms, identityTerms, isChairLabel,
} from './lib/claim-match.mjs';
// Fetching, text extraction and link discovery MOVED VERBATIM to lib/site-crawl.mjs on 2026-08-01 so
// propose-quote-corrections.mjs reads the exact same page text this pass scored. Do not re-implement.
import { crawlSite, pooled } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const LIMIT = parseInt(flag('--limit', '0'), 10);
const OUT = flag('--out');
const HOST_DELAY = parseInt(flag('--host-delay', '900'), 10);   // between requests to ONE host
const CONCURRENCY = parseInt(flag('--concurrency', '6'), 10);   // distinct hosts in flight
const MAX_PAGES = parseInt(flag('--max-pages', '8'), 10);       // interior pages per site
const MIN_BODY = parseInt(flag('--min-body', '600'), 10);
const NO_CACHE = argv.includes('--no-cache');

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/** Crawl tuning passed through to lib/site-crawl.mjs. Defaults are the values the 223-site run used. */
const CRAWL = {
  hostDelay: HOST_DELAY, maxPages: MAX_PAGES, minBody: MIN_BODY, noCache: NO_CACHE,
  cacheTtlHours: parseInt(flag('--cache-ttl-hours', '24'), 10),
};

/** Mirrors check-stance-sources.mjs PRIMARY_SITE_NO_PATH. Keep the two predicates in step. */
const QUERY = `
  SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid, pa.value,
         pc.reasoning, pc.sources,
         p.first_name, p.last_name,
         coalesce(t.short_title, t.title, pa.topic_id::text) AS topic,
         lower(coalesce(seat.state, seat.representing_state, cand.state, '')) AS st,
         coalesce(seat.title, '') AS office_title,
         coalesce(seat.label, '') AS district_label,
         coalesce(seat.city, '')  AS office_city
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN LATERAL (
    SELECT o.representing_state, o.title, d.state, d.label, d.city
    FROM essentials.office_current_holder och
    JOIN essentials.offices o        ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE och.politician_id = pa.politician_id ORDER BY o.title LIMIT 1
  ) seat ON true
  LEFT JOIN LATERAL (
    SELECT lower(e.state::text) AS state
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    WHERE rc.politician_id = pa.politician_id AND rc.candidate_status = 'active'
    ORDER BY e.election_date DESC LIMIT 1
  ) cand ON true
  WHERE pa.value <> 0
    AND cardinality(pc.sources) > 0
    AND NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s WHERE btrim(s, '/') !~* '^https?://(www\\.)?[a-z0-9.-]+$')
    AND EXISTS (
      SELECT 1 FROM unnest(pc.sources) s
       WHERE lower(regexp_replace(btrim(s, '/'), '^https?://(www\\.)?', '')) NOT IN (
         'ballotpedia.org', 'wikipedia.org', 'en.wikipedia.org', 'vote411.org', 'votesmart.org',
         'ontheissues.org', 'opensecrets.org', 'followthemoney.org', 'govtrack.us',
         'legiscan.com', 'congress.gov', 'senate.gov', 'house.gov', 'ourcampaigns.com'))
  ORDER BY pa.politician_id, pa.topic_id`;

/**
 * 🔴 A SITE-BUILDER ID IS NOT AN ANCHOR. Wix, Squarespace and Elementor emit generated ids --
 * #comp-jtv6vr22, #block-41cf7465e2e27be0ae35, #dropdown-41cf...-2 -- that change whenever the owner
 * edits the page. Citing one produces a URL that silently stops resolving to the quoted passage, which
 * is WORSE than citing the homepage: a dead anchor reads as a dead citation. Measured on the 12-site
 * smoke run, 11 of 11 proposed anchors were of this kind. Only human-authored ids qualify.
 */
/**
 * 🔴 ALLOW-LIST THE ANCHOR, DO NOT BLOCK-LIST IT. Two rounds of blocking generated ids just moved the
 * junk: first #comp-jtv6vr22 and #block-41cf..., then #page and #PAGES_CONTAINER, then #zi245S,
 * #ui-id-6, #container02, #accordion-1-content-1, #modal-1. Every round the filter got longer and the
 * next builder invented a new shape -- the same losing pattern as the keyword probe and the template
 * clusterer, where each refinement reclassifies rows and the residue still is not signal.
 *
 * The property that actually matters is not "was this hand-written" but "does the name tell a reader
 * what it points at". A topical anchor (#issues, #priorities, #platform) survives page edits because
 * it describes content; a structural one (#container02) is a position and moves. So the id must
 * CONTAIN a topical word, and anything else falls back to HOMEPAGE_ONLY -- which is a correct,
 * honest citation, not a failure.
 */
const TOPICAL_ID = /issue|priorit|platform|policy|policies|position|promise|about|bio|stand|vision|plan|agenda|value|why|solution|topic|belief|mission/i;
const MEANINGFUL_ID = /^[a-z][a-z0-9]*(?:[-_][a-z0-9]+){0,3}$/i;

/**
 * The id of the nearest ancestor section that contains `needle`, so a single-page site can still be
 * cited precisely. Returns null when nothing matches -- an anchor is a bonus, never a requirement.
 */
/**
 * 🔴 AN ANCHOR THAT WRAPS THE WHOLE PAGE IS NOT AN ANCHOR. After the generated-id filter the next
 * batch of proposals was #page, #PAGES_CONTAINER, #mid and #content -- ids that pass any
 * human-readability test and enclose the entire document, so the "deep link" lands exactly where the
 * bare homepage already landed. An anchor earns its place only by NARROWING: the section it names has
 * to be a fraction of the page, or there is no anchor worth citing and HOMEPAGE_ONLY is the honest
 * answer. Single-page campaign sites frequently have none, and that is a fine outcome.
 */
const WRAPPER_ID = /^(page|pages?_?container|main|content|wrapper|root|app|body|site|top|mid|middle|inner|outer|container|layout|canvas)$/i;
const ANCHOR_MAX_SHARE = 0.4;

function anchorFor(html, needle, pageLen) {
  if (!needle) return null;
  const root = parse(html);
  const want = needle.toLowerCase().slice(0, 60);
  const candidates = root.querySelectorAll('section[id],div[id],article[id],main[id]');
  let best = null;
  for (const el of candidates) {
    const id = el.getAttribute('id');
    if (!id || !MEANINGFUL_ID.test(id) || id.length > 32) continue;
    if (WRAPPER_ID.test(id) || !TOPICAL_ID.test(id)) continue;
    const txt = (el.textContent ?? '').replace(/\s+/g, ' ').toLowerCase();
    if (!txt.includes(want)) continue;
    // Prefer the SMALLEST enclosing section -- the outermost wrapper contains the whole page.
    if (!best || txt.length < best.len) best = { id, len: txt.length };
  }
  if (!best) return null;
  return best.len <= Math.max(400, pageLen * ANCHOR_MAX_SHARE) ? best.id : null;
}

// ---------------------------------------------------------------------------- per-row judgement

function judgeRow(row, pages, chairs = new Map()) {
  const ident = identityTerms(row);
  // A quoted chair label is our own answer text, not the source's words -- see isChairLabel.
  const quotes = extractQuotes(row.reasoning)
    .filter((q) => !isChairLabel(q, chairs.get(row.tid) ?? []));
  const terms = candidateTerms(row.reasoning)
    .filter((t) => !ident.has(t.toLowerCase()))
    .filter((t) => ![...ident].some((i) => i.length > 3 && t.toLowerCase().includes(i)));

  const testableQuotes = quotes.filter((q) => pages.some((p) => quotePresent(p.body, q) !== null));
  if (!testableQuotes.length && !terms.length) {
    return { verdict: 'UNTESTABLE', quotes: quotes.length, terms: 0 };
  }

  const scored = pages.map((p) => {
    const qf = testableQuotes.filter((q) => quotePresent(p.body, q) === true);
    const tf = terms.filter((t) => looseIncludes(p.body, t));
    return { page: p, qFound: qf, tFound: tf };
  });

  // A quote governs whenever the row has one -- it is long, verbatim and unambiguous. Terms only
  // decide when there is no quote to test, and then a lone term is not enough to move a citation.
  //
  // 🔴 ONE VERIFIED QUOTE IS ENOUGH TO LOCATE THE PAGE; DO NOT REQUIRE ALL OF THEM. Requiring every
  // quote scored Stu Baker's housing row NOT_FOUND when "one new city in each state" was plainly on
  // the page and only the second quote was missing. A row legitimately draws on more than one page,
  // and this tool's job is to find WHERE the claim lives, not to adjudicate the whole row -- that is
  // the citation audit's job. Partial matches are reported, never silently promoted.
  const useQuotes = testableQuotes.length > 0;
  const hits = useQuotes
    ? scored.filter((s) => s.qFound.length > 0)
    : scored.filter((s) => s.tFound.length >= Math.min(2, terms.length) && s.tFound.length > 0);

  if (!hits.length) {
    // 🔴 A CLIENT-RENDERED SHELL IS AN UNREAD PAGE, NOT AN ABSENT CLAIM. Wix/Squarespace/React sites
    // serve a megabyte of HTML that yields a few thousand characters of text to a plain fetch --
    // richardsonforcongress.net is 1,027k of HTML and 7k of text, 0.7%. The body clears MIN_BODY, so
    // the thin-body guard never fires, and the row lands in NOT_FOUND looking exactly like evidence.
    // Same false negative as the silent HTTP 202 that produced one wrong sweep already. A positive
    // find on such a page is still a find; only the NEGATIVE is downgraded to unknown.
    const shell = pages.every((p) => p.html.length > 150_000 && p.body.length / p.html.length < 0.03);
    return {
      verdict: shell ? 'UNREADABLE' : 'NOT_FOUND',
      why: shell ? 'client-rendered shell: text is <3% of html on every page read' : undefined,
      quotes: testableQuotes.length, terms: terms.length,
    };
  }

  // Prefer an interior page over the front door; among interior pages prefer the strongest evidence.
  hits.sort((a, b) => (a.page.isHome - b.page.isHome)
    || (b.qFound.length - a.qFound.length)
    || (b.tFound.length - a.tFound.length)
    || a.page.url.length - b.page.url.length);
  const win = hits[0];
  const evidence = useQuotes ? win.qFound[0] : win.tFound[0];

  if (!win.page.isHome) {
    // A single matched term with no quote is thin evidence for moving a citation. It is usually right
    // -- the page is on the host we already cite -- but it is not verification, so it is held out of
    // the auto-apply set and reported separately rather than quietly counted as a repair.
    const weak = !useQuotes && win.tFound.length < 2;
    return {
      verdict: weak ? 'DEEP_PAGE_WEAK' : 'DEEP_PAGE', url: win.page.url, evidence,
      quotes: testableQuotes.length, terms: terms.length,
      matched_quotes: win.qFound.length, matched_terms: win.tFound.length,
      partial: useQuotes && win.qFound.length < testableQuotes.length,
    };
  }
  const anchor = anchorFor(win.page.html, evidence, win.page.body.length);
  return {
    verdict: anchor ? 'HOMEPAGE_ANCHOR' : 'HOMEPAGE_ONLY',
    url: anchor ? `${win.page.url}#${anchor}` : win.page.url, evidence,
    quotes: testableQuotes.length, terms: terms.length,
    matched_quotes: win.qFound.length, matched_terms: win.tFound.length,
    partial: useQuotes && win.qFound.length < testableQuotes.length,
  };
}

// ---------------------------------------------------------------------------- run

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const { rows } = await pool.query(QUERY);
  // Chair labels per topic, so a row that quotes the answer WE assigned is not tested against the page.
  const chairRows = await pool.query('SELECT topic_id::text AS tid, text FROM inform.compass_stances');
  await pool.end();
  const chairs = new Map();
  for (const c of chairRows.rows) {
    if (!chairs.has(c.tid)) chairs.set(c.tid, []);
    chairs.get(c.tid).push(c.text);
  }

  // One site per politician: their bare root is the same across all their rows.
  const sites = new Map();
  for (const r of rows) {
    const root = r.sources.find((s) => /^https?:\/\//i.test(s.trim()))?.trim().replace(/\/$/, '');
    if (!root) continue;
    if (!sites.has(root)) sites.set(root, []);
    sites.get(root).push(r);
  }
  let list = [...sites.entries()];
  if (LIMIT) list = list.slice(0, LIMIT);
  console.log(`${rows.length} rows across ${sites.size} sites; crawling ${list.length} (concurrency ${CONCURRENCY})`);

  let done = 0;
  const results = [];
  await pooled(list, CONCURRENCY, async ([root, siteRows]) => {
    // 🔴 ONE BAD SITE MUST NOT COST THE OTHER 222. Whatever a stranger's web server does -- half-closed
    // socket, malformed markup, redirect loop -- it is a fact about that site, recorded against that
    // site, and never a reason to lose the whole crawl.
    let site;
    try { site = await crawlSite(root, CRAWL); }
    catch (e) { site = { ok: false, dead: false, reason: `crawl threw: ${e.message}`, pages: [] }; }
    for (const r of siteRows) {
      const base = {
        pid: r.pid, tid: r.tid, name: `${r.first_name} ${r.last_name}`, st: r.st, topic: r.topic,
        value: r.value, cited: root, pages_read: site.pages.length, reasoning: r.reasoning,
      };
      results.push(site.ok
        ? { ...base, ...judgeRow(r, site.pages, chairs) }
        : { ...base, verdict: site.dead ? 'DEAD_SITE' : 'UNREADABLE', why: site.reason });
    }
    done += 1;
    if (done % 20 === 0) console.log(`  ${done}/${list.length} sites`);
  });

  const tally = {};
  for (const r of results) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
  console.log('\nverdicts');
  for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${k.padEnd(18)} ${String(v).padStart(4)}`);
  }
  const applyable = results.filter((r) => r.verdict === 'DEEP_PAGE' || r.verdict === 'HOMEPAGE_ANCHOR');
  console.log(`\napplyable (a more specific URL on the SAME host, claim verified there): ${applyable.length}`);
  console.log('HOMEPAGE_ONLY rows are already correct -- the claim is on the front page and there is no anchor.');
  console.log('NOT_FOUND / UNTESTABLE need a human read. UNREADABLE needs a re-run, never a retirement.');

  if (OUT) {
    writeFileSync(OUT, `${JSON.stringify({
      _comment: 'PRIMARY_SITE_NO_PATH repair proposal. Only DEEP_PAGE and HOMEPAGE_ANCHOR are applyable, '
        + 'and each proposes a MORE SPECIFIC URL ON THE SAME HOST where the claim was verified present. '
        + 'This tool never swaps in a different source and never retires a row. UNREADABLE is a fetch '
        + 'failure or a JS-only shell, NOT evidence the claim is absent.',
      generated: { rows: results.length, sites: list.length, tally },
      rows: results,
    }, null, 2)}\n`);
    console.log(`\nwritten to ${OUT}`);
  }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });

#!/usr/bin/env node
/**
 * TIER B of the national generic-sourcing audit: rows sourced only by a Wikipedia/Ballotpedia
 * article ABOUT the politician.
 *
 * 🔑 THE QUESTION THAT SPLITS THIS TIER: does the cited article actually have a POLITICAL POSITIONS
 * section? A legislature member page never does -- that is why Tier A is defect-shaped by
 * construction. An encyclopaedia article MIGHT, and for prominent figures usually does, so
 * "Wikipedia only" is NOT automatically a defect. This measures which is which.
 *
 * 🔑 MEASURED ON RAW HTML, never on extracted text (MD pass 2: an extraction bug manufactured 27
 * false absences by slicing every page at the first "See also", and the marker it searched for could
 * not exist in tag-stripped text). Absence is the trigger for a negative verdict, so it must be
 * conservative.
 *
 * ⚠⚠ BALLOTPEDIA RATE-LIMITS after ~50 rapid requests and then answers HTTP 202 with a ZERO-BYTE
 * body, which scores as "dead" and produced a bogus 50-dead result once before. So: >=2.2s spacing
 * for Ballotpedia, and ABORT THE WHOLE RUN on the first zero-byte response rather than recording it.
 * A 200 is not proof of existence either -- Ballotpedia serves a title derived from the URL for
 * pages that do not exist; `"wgArticleId":0` is the real test.
 *
 * 🔴 Reads only. Emits an audit.
 *   node scripts/tier-b-positions-section.mjs --cache <dir> --out <out.json> [--limit N]
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const CACHE = flag('--cache'), OUT = flag('--out');
const LIMIT = parseInt(flag('--limit', '0'), 10);
if (!CACHE || !OUT) { console.error('need --cache --out'); process.exit(2); }
fs.mkdirSync(CACHE, { recursive: true });

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows } = await pool.query(`
  WITH src AS (
    SELECT c.politician_id, c.topic_id, u,
           COALESCE(substring(u FROM 'web\\.archive\\.org/web/[0-9]+(?:id_)?/(https?://.*)$'), u) AS nu
    FROM inform.politician_context c, unnest(c.sources) u
  ), cls AS (
    SELECT politician_id, topic_id, nu,
      CASE WHEN nu ILIKE '%en.wikipedia.org/wiki/%'
        OR (nu ILIKE '%ballotpedia.org/%' AND nu NOT ILIKE '%candidate_connection%')
        OR nu ILIKE '%/mgawebsite/members/details/%' OR nu ILIKE '%capitol.texas.gov/members/memberinfo%'
        OR nu ILIKE '%malegislature.gov/legislators/profile%'
        OR nu ILIKE '%legislature.maine.gov/%memberprofiles%'
        OR nu ILIKE '%azleg.gov/house/house-member%' OR nu ILIKE '%azleg.gov/senate/senate-member%'
        OR nu ILIKE '%ballotready.org/people/%' OR nu ILIKE '%congress.gov/member/%'
        OR nu ILIKE '%govtrack.us/congress/members/%' THEN 1 ELSE 0 END AS is_generic,
      (nu ILIKE '%wikipedia.org/wiki/%' OR nu ILIKE '%ballotpedia.org/%') AS is_encyc
    FROM src
  ), agg AS (SELECT politician_id, topic_id, count(*) n_src, sum(is_generic) n_gen FROM cls GROUP BY 1,2),
  bad AS (SELECT politician_id, topic_id FROM agg WHERE n_gen = n_src)
  SELECT p.full_name, b.politician_id, b.topic_id, t.title AS topic, c.nu AS article, ctx.reasoning
  FROM bad b
  JOIN cls c ON c.politician_id=b.politician_id AND c.topic_id=b.topic_id AND c.is_encyc
  JOIN inform.politician_context ctx ON ctx.politician_id=b.politician_id AND ctx.topic_id=b.topic_id
  JOIN essentials.politicians p ON p.id=b.politician_id
  LEFT JOIN inform.compass_topics t ON t.id=b.topic_id`);
await pool.end();

// 🔑 Only articles that are ABOUT the politician belong to Tier B. An article about a BILL, an
// ELECTION or a CAUCUS is Tier C -- my first cut wrongly lumped them together because they share the
// /wiki/ path. Compare the slug against the surname before calling anything a bio.
const surnameOf = (n) => n.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim().split(/\s+/).pop().toLowerCase();
const tierB = rows.filter((r) => {
  const slug = (r.article.match(/(?:\/wiki|ballotpedia\.org)\/([^?#]+)$/) || [])[1] || '';
  return slug.toLowerCase().replace(/_/g, ' ').includes(surnameOf(r.full_name));
});
console.log(`encyclopaedia-sourced rows: ${rows.length}  |  about the person (Tier B): ${tierB.length}`);

let urls = [...new Set(tierB.map((r) => r.article))];
if (LIMIT) urls = urls.slice(0, LIMIT);
console.log(`distinct articles to fetch: ${urls.length}\n`);

const fileFor = (u) => path.join(CACHE, encodeURIComponent(u).replace(/[^A-Za-z0-9%._-]/g, '_').slice(-180) + '.html');

const info = new Map();
let n = 0;
for (const u of urls) {
  const f = fileFor(u);
  let html = null;
  if (fs.existsSync(f) && fs.statSync(f).size > 2_000) html = fs.readFileSync(f, 'utf8');
  else {
    const isBp = /ballotpedia\.org/i.test(u);
    const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow' });
    const body = await res.text();
    // ⚠ The rate-limit tell: a zero-byte body. Abort rather than record it as absence.
    if (body.length === 0) {
      console.error(`\n🔴 ZERO-BYTE BODY at ${u} after ${n} fetches — rate limited. Aborting so the`);
      console.error('   run cannot record a blocking artefact as data. Re-run later; the cache persists.');
      break;
    }
    html = body; fs.writeFileSync(f, html);
    await sleep(isBp ? 2200 : 1200);
  }
  // Ballotpedia serves a 200 with a URL-derived title for pages that do not exist.
  const aid = (html.match(/"wgArticleId"\s*:\s*(\d+)/) || [])[1];
  const exists = aid === undefined ? null : Number(aid) > 0;
  // RAW-HTML section detection -- headings carry an id/anchor, which tag-stripped text destroys.
  const hasPositions = /id="Political_positions"|id="Political_views"|id="Positions"|id="Political_positions_and_votes"|>\s*Political positions\s*<|>\s*Political views\s*<|>\s*Issues\s*<|id="Campaign_themes"|>\s*Campaign themes\s*</i.test(html);
  info.set(u, { exists, hasPositions, bytes: html.length });
  if (++n % 40 === 0) console.log(`  …${n}/${urls.length}`);
}
console.log(`fetched/loaded ${info.size} article(s)\n`);

const out = tierB.filter((r) => info.has(r.article)).map((r) => {
  const i = info.get(r.article);
  return {
    politician: r.full_name, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    article: r.article, article_exists: i.exists, has_positions_section: i.hasPositions,
    verdict: i.exists === false ? 'ARTICLE_DOES_NOT_EXIST'
      : i.hasPositions ? 'HAS_POSITIONS_SECTION' : 'BIO_WITHOUT_POSITIONS',
    reasoning: r.reasoning,
  };
});
const tally = out.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
const pols = {};
for (const r of out) (pols[r.verdict] ||= new Set()).add(r.politician_id);

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'Tier B - does the cited encyclopaedia article carry political positions?',
  caveat: 'HAS_POSITIONS_SECTION does NOT mean the row is sourced -- the section must also cover THIS '
        + 'topic, which is the next test. BIO_WITHOUT_POSITIONS is the defect-shaped class. '
        + 'Nothing here is a delete list.',
  tally, rows: out,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
for (const [k, v] of Object.entries(pols)) console.log(`${k}: ${v.size} politicians`);

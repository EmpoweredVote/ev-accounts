#!/usr/bin/env node
/**
 * Turn the NOT_FOUND cohort into a READING QUEUE: for every row whose quote the repair pass could not
 * find, show what the cited page actually says in the same place.
 *
 * WHY THIS EXISTS. `repair-primary-site-paths.mjs` reports NOT_FOUND when a row's quoted string is on
 * none of the site's pages. Hand-sampling 15 of those rows found that ~two-thirds are INEXACT QUOTES
 * OVER SUBSTANCE THAT IS ON THE PAGE -- Troy Slaten's page says "money should NEVER be a barrier to
 * justice" where the row wrote "should NOT be"; Ken Vaz's page says "secure the border, enforce
 * immigration law" with the row's wording slightly off. The remedy for those is to FIX THE QUOTE, not
 * to delete the row. But fixing a quote needs the page's exact words, and NOT_FOUND is a bare verdict
 * that carries none.
 *
 * 🔴 THIS TOOL PROPOSES NOTHING AND RETIRES NOTHING. It emits evidence for a human to read. Seven
 * consecutive times on this workstream a detector's findings shrank once someone read the pages, and
 * the tooling has never once been right that a row should be deleted. So the output is deliberately
 * shaped as "here is the closest thing on the page", never as "this row fails".
 *
 * 🔴 A NON-200 IS NOT AN ABSENT CLAIM -- CLASSIFY IT. This trap has been hit three times here, most
 * expensively when 214 silent HTTP-202s nearly recorded 168 correctly-sourced rows as unsupported. A
 * site that read fine for the repair pass and fails now yields RECHECK, never a verdict about the row.
 *
 * WHAT IT MEASURES. For each quote fragment, the best-scoring window of page text of the same length,
 * scored on stemmed content-token overlap. The winning window is then widened to its enclosing
 * sentence and emitted VERBATIM, because a correction has to paste the page's own words back into
 * voter-facing text -- `inform.politician_context.reasoning` renders under "Why this position?".
 *
 * VERDICTS (all of them mean "read this", none mean "act")
 *   QUOTE_NEAR      >= NEAR    substance is on the page; wording differs. The quote-fix candidates
 *   QUOTE_PARTIAL   >= PARTIAL some of it is there; could be a splice, a paraphrase or a wrong page
 *   QUOTE_ABSENT    <  PARTIAL nothing close on any page read. Shannon Taylor's "tariff" shape
 *   NO_QUOTE        the row characterises rather than quotes -- term evidence is reported instead
 *   RECHECK         site unreadable/blocked NOW. Says nothing about the row
 *
 * Matchers come from ./lib/claim-match.mjs and fetching from ./lib/site-crawl.mjs -- the same code the
 * repair pass ran, so the text scored here is the text scored there. Do not re-implement either.
 *
 * Usage (from backend/):
 *   node scripts/propose-quote-corrections.mjs --out data/stance-retirement/2026-08-01-quote-corrections.json \
 *                                              --md  data/stance-retirement/2026-08-01-quote-corrections.md
 *   node scripts/propose-quote-corrections.mjs --limit 5     # smoke run, 5 sites
 */
import 'dotenv/config';
import { writeFileSync, readFileSync } from 'node:fs';
import { Pool } from 'pg';
import {
  extractQuotes, quoteFragments, quotePresent, norm, looseIncludes,
  candidateTerms, identityTerms, stemLine,
} from './lib/claim-match.mjs';
import { crawlSite, pooled } from './lib/site-crawl.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in', 'data/stance-retirement/2026-08-01-primary-site-paths.json');
const OUT = flag('--out');
const MD = flag('--md');
const LIMIT = parseInt(flag('--limit', '0'), 10);
const CONCURRENCY = parseInt(flag('--concurrency', '6'), 10);
const VERDICT = flag('--verdict', 'NOT_FOUND');

/**
 * Thresholds are for TRIAGE ORDER ONLY -- nothing is applied off them, so they are tuned to put the
 * most likely quote-fixes at the top of a human's reading list, not to be a decision boundary.
 * Calibrated on the four rows already hand-verified in the 15-row sample: Slaten (one word differs)
 * and Vaz (wording slightly off) must land NEAR; Vail, whose two quoted phrases are absent from a 10k
 * page, must land ABSENT.
 */
const NEAR = 0.72;
const PARTIAL = 0.45;

const CRAWL = { hostDelay: 900, maxPages: 8, minBody: 600, cacheTtlHours: 24 };
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// ---------------------------------------------------------------------------- span search

/**
 * Words of `text` with their character offsets, so a winning window can be mapped back to the
 * VERBATIM source text. Scoring happens on the normalised form; the output never does.
 */
function tokenize(text) {
  const out = [];
  for (const m of text.matchAll(/[A-Za-z0-9][A-Za-z0-9'’-]*/g)) {
    out.push({ raw: m[0], at: m.index, end: m.index + m[0].length, key: stemLine(norm(m[0])) });
  }
  return out;
}

/**
 * 🔴 SCORE ON THE FRAGMENT'S RARE WORDS, NOT ON ALL OF THEM. A quote is mostly function words, and a
 * window of any English prose matches those. Weighting every token equally scored a random paragraph
 * of a campaign homepage at 0.6 against Ken Vaz's border quote -- above PARTIAL, on text with nothing
 * to do with it. Inverse document frequency over THIS SITE's pages is the cheap fix: a word appearing
 * on every page carries nearly no weight, and "deportation" carries almost all of it.
 */
function idfOver(pages) {
  const df = new Map();
  for (const p of pages) {
    for (const k of new Set(tokenize(p.body).map((t) => t.key))) df.set(k, (df.get(k) ?? 0) + 1);
  }
  const n = Math.max(1, pages.length);
  return (k) => Math.log((n + 1) / ((df.get(k) ?? 0) + 0.5));
}

/**
 * Best-matching window of `pageToks` for `fragToks`, scored as the share of the fragment's IDF mass
 * present in the window. Windows are the fragment's length, plus a little slack, because the page
 * usually says the same thing with a word or two more.
 */
function bestWindow(pageToks, fragToks, idf) {
  const want = new Map();
  for (const t of fragToks) want.set(t.key, (want.get(t.key) ?? 0) + 1);
  let total = 0;
  for (const [k, c] of want) total += idf(k) * c;
  if (total <= 0) return null;

  const size = Math.min(pageToks.length, Math.max(4, Math.round(fragToks.length * 1.35)));
  if (!pageToks.length) return null;

  const have = new Map();
  let mass = 0;
  const push = (k, d) => {
    const need = want.get(k);
    if (!need) return;
    const cur = have.get(k) ?? 0;
    const next = cur + d;
    have.set(k, next);
    if (d > 0 && cur < need) mass += idf(k);
    if (d < 0 && next < need) mass -= idf(k);
  };

  let best = null;
  for (let i = 0; i < pageToks.length; i++) {
    push(pageToks[i].key, 1);
    if (i >= size) push(pageToks[i - size].key, -1);
    if (i >= size - 1) {
      const score = mass / total;
      if (!best || score > best.score) best = { score, from: i - size + 1, to: i };
    }
  }
  return best;
}

/**
 * Widen a token window to the sentence(s) enclosing it, and return the page's VERBATIM text.
 *
 * 🔴 NEVER CUT MID-WORD. The first version fell back to a raw character slice when the sentence span
 * ran long, and emitted "liminate mandatory minimums" and "t may be nice for a family". This text is
 * proposed as a REPLACEMENT QUOTE in voter-facing reasoning; a span that starts mid-word either gets
 * pasted in as-is or has to be re-derived by hand, and the first of those is how a correction pass
 * introduces the fabrication it exists to remove. Every boundary snaps outward to whitespace.
 */
function verbatimSpan(body, pageToks, win) {
  const a = pageToks[win.from].at;
  const b = pageToks[win.to].end;
  const snapBack = (i) => { while (i > 0 && /\S/.test(body[i - 1])) i -= 1; return i; };
  const snapFwd = (i) => { while (i < body.length && /\S/.test(body[i])) i += 1; return i; };

  let s = body.lastIndexOf('. ', a);
  let e = body.indexOf('. ', b);
  s = s === -1 ? snapBack(Math.max(0, a - 160)) : s + 2;
  e = e === -1 ? snapFwd(Math.min(body.length, b + 160)) : e + 1;
  // Sentence boundaries are unreliable on collapsed campaign-site text (bullet lists run together), so
  // cap the span -- a 900-character "quote" is not usable as a correction.
  const span = body.slice(s, e).trim();
  if (span.length <= 420) return span;
  return body.slice(snapBack(Math.max(0, a - 40)), snapFwd(Math.min(body.length, b + 60))).trim();
}

/** For every fragment of every quote, the closest thing on any page read. */
function locateQuotes(quotes, pages) {
  const idf = idfOver(pages);
  const toks = pages.map((p) => ({ page: p, toks: tokenize(p.body) }));
  return quotes.map((q) => {
    const frags = quoteFragments(q);
    const found = pages.some((p) => quotePresent(p.body, q) === true);
    const parts = (frags.length ? frags : [q]).map((f) => {
      const ft = tokenize(f);
      let best = null;
      for (const { page, toks: pt } of toks) {
        const w = bestWindow(pt, ft, idf);
        if (w && (!best || w.score > best.score)) {
          best = { score: w.score, url: page.url, text: verbatimSpan(page.body, pt, w) };
        }
      }
      return { fragment: f, best };
    });
    const score = parts.length ? Math.min(...parts.map((p) => p.best?.score ?? 0)) : 0;
    return { quote: q, already_present: found, score: +score.toFixed(3), parts };
  });
}

/**
 * For rows that characterise rather than quote, the term evidence plus the page sentences that come
 * closest to the reasoning as a whole -- which is the only reading material a term verdict can offer.
 */
function locateTerms(row, terms, pages) {
  const idf = idfOver(pages);
  const matched = [];
  const missing = [];
  for (const t of terms) {
    const on = pages.find((p) => looseIncludes(p.body, t));
    (on ? matched : missing).push(on ? { term: t, url: on.url } : { term: t });
  }
  const ft = tokenize(row.reasoning);
  let best = null;
  for (const p of pages) {
    const pt = tokenize(p.body);
    const w = bestWindow(pt, ft, idf);
    if (w && (!best || w.score > best.score)) {
      best = { score: +w.score.toFixed(3), url: p.url, text: verbatimSpan(p.body, pt, w) };
    }
  }
  return { matched, missing, closest: best };
}

// ---------------------------------------------------------------------------- run

/**
 * The cohort is PINNED BY THE INPUT FILE, not re-derived. The gate's cohort predicate lives in
 * check-stance-sources.mjs and repair-primary-site-paths.mjs and must stay in step with itself; a
 * third copy here would be a third thing to keep in step. Rows are fetched by explicit key instead.
 */
const BY_KEY = `
  SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid, pa.value,
         pc.reasoning, pc.sources,
         p.first_name, p.last_name,
         coalesce(t.short_title, t.title, pa.topic_id::text) AS topic,
         lower(coalesce(seat.state, seat.representing_state, cand.state, '')) AS st,
         coalesce(seat.title, '') AS office_title,
         coalesce(seat.label, '') AS district_label,
         coalesce(seat.city, '')  AS office_city
  FROM unnest($1::uuid[], $2::uuid[]) AS k(pid, tid)
  JOIN inform.politician_answers pa
    ON pa.politician_id = k.pid AND pa.topic_id = k.tid
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
  ORDER BY pa.politician_id, pa.topic_id`;

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

  const input = JSON.parse(readFileSync(IN, 'utf8'));
  const want = input.rows.filter((r) => r.verdict === VERDICT);
  console.log(`${want.length} ${VERDICT} rows in ${IN}`);

  const { rows } = await pool.query(BY_KEY, [want.map((r) => r.pid), want.map((r) => r.tid)]);
  await pool.end();

  // 🔴 A ROW THAT VANISHED BETWEEN THE TWO RUNS IS NOT A ROW THAT WAS FIXED. Report the shortfall
  // rather than quietly working a smaller set -- a silently shrinking cohort is how a partial pass
  // gets recorded as a complete one.
  if (rows.length !== want.length) {
    console.log(`⚠ ${want.length - rows.length} row(s) in the input are no longer live in the DB; `
      + 'they are reported as GONE and worked no further.');
  }
  const live = new Set(rows.map((r) => `${r.pid}|${r.tid}`));
  const gone = want.filter((r) => !live.has(`${r.pid}|${r.tid}`));

  const sites = new Map();
  for (const r of rows) {
    const root = r.sources.find((s) => /^https?:\/\//i.test(s.trim()))?.trim().replace(/\/$/, '');
    if (!root) continue;
    if (!sites.has(root)) sites.set(root, []);
    sites.get(root).push(r);
  }
  let list = [...sites.entries()];
  if (LIMIT) list = list.slice(0, LIMIT);
  console.log(`${rows.length} live rows across ${sites.size} sites; crawling ${list.length}`);

  const results = [];
  let done = 0;
  await pooled(list, CONCURRENCY, async ([root, siteRows]) => {
    let site;
    try { site = await crawlSite(root, CRAWL); }
    catch (e) { site = { ok: false, reason: `crawl threw: ${e.message}`, pages: [] }; }
    for (const r of siteRows) {
      const base = {
        pid: r.pid, tid: r.tid, name: `${r.first_name} ${r.last_name}`, st: r.st, topic: r.topic,
        value: r.value, cited: root, reasoning: r.reasoning, pages_read: site.pages.length,
      };
      if (!site.ok) {
        // Says nothing about the row. The repair pass READ this site -- if it cannot be read now, that
        // is a fact about today's fetch.
        results.push({ ...base, verdict: 'RECHECK', why: site.reason });
        continue;
      }
      const ident = identityTerms(r);
      const quotes = extractQuotes(r.reasoning);
      const terms = candidateTerms(r.reasoning)
        .filter((t) => !ident.has(t.toLowerCase()))
        .filter((t) => ![...ident].some((i) => i.length > 3 && t.toLowerCase().includes(i)));

      if (!quotes.length) {
        results.push({ ...base, verdict: 'NO_QUOTE', terms: locateTerms(r, terms, site.pages),
          pages: site.pages.map((p) => p.url) });
        continue;
      }
      const located = locateQuotes(quotes, site.pages);
      const score = Math.max(...located.map((q) => q.score));
      const verdict = score >= NEAR ? 'QUOTE_NEAR' : score >= PARTIAL ? 'QUOTE_PARTIAL' : 'QUOTE_ABSENT';
      results.push({ ...base, verdict, score, quotes: located,
        terms: locateTerms(r, terms, site.pages), pages: site.pages.map((p) => p.url) });
    }
    done += 1;
    if (done % 10 === 0) console.log(`  ${done}/${list.length} sites`);
  });

  for (const g of gone) results.push({ ...g, verdict: 'GONE', why: 'no longer in inform.politician_answers' });

  const tally = {};
  for (const r of results) tally[r.verdict] = (tally[r.verdict] ?? 0) + 1;
  console.log('\nverdicts');
  for (const [k, v] of Object.entries(tally).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${k.padEnd(16)} ${String(v).padStart(4)}`);
  }
  console.log('\nEvery verdict here means READ THIS. None of them means retire, and none is applied.');

  if (OUT) {
    writeFileSync(OUT, `${JSON.stringify({
      _comment: 'Reading queue for the NOT_FOUND cohort. For each row, the closest VERBATIM text on the '
        + 'cited site to the quote the row attributes to it. QUOTE_NEAR means the substance is there and '
        + 'the wording is wrong -- fix the quote. Nothing here is a retirement list, and no threshold in '
        + 'this file was ever used to change a row without a human reading the page.',
      generated: { rows: results.length, sites: list.length, thresholds: { NEAR, PARTIAL }, tally },
      rows: results,
    }, null, 2)}\n`);
    console.log(`written to ${OUT}`);
  }
  if (MD) { writeFileSync(MD, renderMd(results, tally)); console.log(`written to ${MD}`); }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });

// ---------------------------------------------------------------------------- readable output

function renderMd(results, tally) {
  const order = ['QUOTE_NEAR', 'QUOTE_PARTIAL', 'QUOTE_ABSENT', 'NO_QUOTE', 'RECHECK', 'GONE'];
  const L = [];
  L.push('# NOT_FOUND reading queue — what the cited pages actually say\n');
  L.push('Generated by `scripts/propose-quote-corrections.mjs`. **Nothing here has been applied.**');
  L.push('Every row below is a row a human has to read; the tool only supplies the page\'s own words.\n');
  L.push('| verdict | rows | meaning |');
  L.push('|---|---|---|');
  const meaning = {
    QUOTE_NEAR: 'substance is on the page, wording differs — **fix the quote**',
    QUOTE_PARTIAL: 'partly there — splice, paraphrase, or wrong page',
    QUOTE_ABSENT: 'nothing close on any page read',
    NO_QUOTE: 'row characterises rather than quotes — term evidence only',
    RECHECK: '⚠ site unreadable **today** — says nothing about the row',
    GONE: 'row no longer live in the DB',
  };
  for (const k of order) if (tally[k]) L.push(`| \`${k}\` | ${tally[k]} | ${meaning[k]} |`);
  L.push('');
  for (const k of order) {
    const group = results.filter((r) => r.verdict === k);
    if (!group.length) continue;
    L.push(`\n## ${k} — ${group.length}\n`);
    for (const r of group.sort((a, b) => (b.score ?? 0) - (a.score ?? 0))) {
      L.push(`### ${r.name} — ${r.topic} (${r.st}, chair ${r.value})`);
      L.push(`\`${r.cited}\` · ${r.pages_read} page(s) read${r.score != null ? ` · score ${r.score}` : ''}`);
      if (r.why) L.push(`\n**${r.why}**`);
      L.push(`\n> **row says:** ${r.reasoning}\n`);
      for (const q of r.quotes ?? []) {
        L.push(`- **quoted:** "${q.quote}" — score ${q.score}${q.already_present ? ' (present!)' : ''}`);
        for (const p of q.parts) {
          L.push(`  - closest on page (${p.best?.score?.toFixed(2) ?? 'n/a'}): ${p.best ? `"${p.best.text}"` : '—'}`);
          if (p.best) L.push(`    - ${p.best.url}`);
        }
      }
      if (r.terms) {
        if (r.terms.missing?.length) L.push(`- **terms absent:** ${r.terms.missing.map((t) => `\`${t.term}\``).join(', ')}`);
        if (r.terms.matched?.length) L.push(`- **terms present:** ${r.terms.matched.map((t) => `\`${t.term}\``).join(', ')}`);
        if (r.terms.closest) L.push(`- **closest passage (${r.terms.closest.score}):** "${r.terms.closest.text}"\n  - ${r.terms.closest.url}`);
      }
      L.push('');
    }
  }
  return `${L.join('\n')}\n`;
}

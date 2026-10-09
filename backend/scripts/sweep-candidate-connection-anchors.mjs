#!/usr/bin/env node
/**
 * Fetch every Ballotpedia page the corpus deep-links with #Campaign_themes and record WHAT IS
 * BEHIND THE ANCHOR. Writes data/candidate-connection-anchors.json, which check-stance-sources.mjs
 * reads.
 *
 * WHY THIS EXISTS. check-stance-sources.mjs carves out a Ballotpedia citation when the URL carries
 * #Campaign_themes, because a Candidate Connection survey answer is the candidate's own words
 * (ruling 2026-10-07). That carve-out is granted ON THE URL ALONE — the gate runs SQL and has no
 * page text — and the file has said so in a comment since the day it was written:
 *
 *     🔴 THIS SQL CAN TEST THE URL ONLY. It has no page text.
 *
 * The protection was that the anchor is only ever appended by deep-link-candidate-connection.mjs,
 * for CC_VERIFIED rows, with the pre-write gate requiring the same check. Nothing ENFORCES that.
 * Hand-append "#Campaign_themes" to any Ballotpedia bio and the row passes a gate that cannot see
 * the page. That is the standing exposure this sweep closes: the gate stops trusting the URL
 * string and starts trusting a recorded observation of the page.
 *
 * 🔑 THE ARCHITECTURE IS NOT NEW — it is FABRICATED_SOURCE's, which the gate already describes:
 * "deciding that a cited article never existed requires fetching ... network work that
 * archive.org rate-limits and 504s, so it must not run in CI". Same split here. The fetching lives
 * in this on-demand sweep; the gate only compares against what the sweep confirmed. A CI job that
 * made 160 requests to a host that rate-limits would be flaky, and a flaky gate gets ignored.
 *
 * THREE VERDICTS, and the third one is the whole reason this is careful:
 *   own-words    the section carries the candidate's own text — a completed survey, or a quoted
 *                campaign website under the same heading. The carve-out is earned.
 *   empty        the section exists and carries NO words from the candidate, or the anchor points
 *                at a section that is not on the page at all. The carve-out is unearned.
 *   unreachable  the fetch did not produce a page we can read.
 *
 * 🔴🔴 `unreachable` IS NOT `empty`, AND CONFLATING THEM IS THE BUG THIS CORPUS KEEPS MAKING.
 * Ballotpedia answers 202 to a fast sweep — 122 of the first 160 requests in the 2026-10-08 pass
 * were challenged, and the first run scored them as absent pages. A 402/403 is an access barrier,
 * not an absence. An unreachable page is written to the manifest as `unreachable` and is NOT in
 * the verified set, so the gate REPORTS it as unverified and never FAILS on it.
 *
 * ⚠ THE 2026-10-08 SWEEP WAS WRONG THREE TIMES BEFORE IT WAS RIGHT, and every error inflated the
 * same number (19 pages -> 15 -> 1 -> 0). All four fixes are reproduced here deliberately:
 *   1. script/style are stripped from the WHOLE document, not inside the already-sliced section,
 *      or a section opening with Ballotpedia's survey stylesheet reads CSS as prose.
 *   2. the AFFIRMATIVE test runs BEFORE the no-survey notice. Ballotpedia lists every cycle it has
 *      asked about, so most pages say both "completed ... in 2026" and "did not complete ... 2020".
 *   3. HTML ENTITIES ARE DECODED before matching. Ballotpedia writes Ballotpedia&#39;s, so every
 *      pattern containing an apostrophe failed silently. This alone moved 33 pages.
 *   4. the own-words test accepts a "Campaign website" subsection OR a bare year heading above a
 *      quote, not one fixed phrasing.
 *
 * Usage (from backend/, needs DATABASE_URL):
 *   node scripts/sweep-candidate-connection-anchors.mjs
 *   node scripts/sweep-candidate-connection-anchors.mjs --limit 5     # smoke test
 *   node scripts/sweep-candidate-connection-anchors.mjs --delay 1500  # default 3000ms
 */
import 'dotenv/config';
import { writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';
import { parse } from 'node-html-parser';
import { CC_SECTION_ID, CC_ANCHOR_PATTERN, withoutFragment, NO_SURVEY_NOTICE, sectionText }
  from './lib/candidate-connection.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'data', 'candidate-connection-anchors.json');

const argv = process.argv.slice(2);
const num = (flag, dflt) => {
  const i = argv.indexOf(flag);
  return i === -1 ? dflt : Number(argv[i + 1]);
};
const LIMIT = num('--limit', 0);
// One request every three seconds. The 2026-10-08 pass established this: faster gets 202s.
const DELAY_MS = num('--delay', 3000);
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) '
  + 'Chrome/127.0.0.0 Safari/537.36';

/**
 * Affirmative: the page states a COMPLETED survey. Tested first -- see correction 2.
 *
 * 🔴🔴 CORRECTION 5, FOUND BY A UNIT TEST ON 2026-10-09 AND NOT BY ANY SWEEP.
 * "has not completed Ballotpedia's Candidate Connection survey" CONTAINS "completed Ballotpedia's
 * Candidate Connection survey" as a substring. A bare affirmative match therefore reads the
 * NEGATIVE notice as proof of a completed survey -- the exact inverse of correction 2, and worse,
 * because it silently converts an empty page into a verified one. Running the affirmative first
 * (which correction 2 requires) is what exposes the row to this.
 * ⚠ The 2026-10-08 sweep's published regex has this same shape, so its "0 pages carrying nothing
 * from the candidate" may be partly an artifact of it. This sweep was re-run after the fix.
 * The match is therefore rejected when negated within the 24 characters before it.
 */
const COMPLETED_SURVEY = /completed\s+Ballotpedia'?s?\s+(?:\d{4}\s+)?Candidate\s+Connection\s+survey/gi;
const NEGATED_BEFORE = /\b(?:not|never|hasn't|haven't|didn't)\b[^.]{0,24}$/i;

/** True when the page affirmatively states a completed survey, negations excluded. */
function statesCompletedSurvey(text) {
  for (const m of text.matchAll(COMPLETED_SURVEY)) {
    const before = text.slice(Math.max(0, m.index - 24), m.index);
    if (!NEGATED_BEFORE.test(before)) return true;
  }
  return false;
}
/** Own words without a survey: a quoted campaign website, or a bare year heading above a quote. */
const CAMPAIGN_WEBSITE = /campaign\s+website/i;
const YEAR_HEADING = /\b(19|20)\d{2}\b/;
/**
 * 🔴 CORRECTION 6, also found by the unit test: an APOSTROPHE IS NOT A QUOTATION MARK. Testing for
 * /["“”']/ matched the apostrophe in "Ballotpedia's", so any section mentioning Ballotpedia and a
 * year scored as "quotes the candidate directly" -- which is every no-survey notice on the site.
 * A quote means a DOUBLE-quoted span with something substantial inside it.
 */
const QUOTED_PASSAGE = /["“][^"“”]{12,}["”]/;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Decode entities. Twice: '&amp;#39;' occurs. See correction 3 -- this alone moved 33 pages. */
export function decode(s) {
  const once = (t) => String(t)
    .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(Number(d)))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&nbsp;/g, ' ')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
  return once(once(s));
}

async function fetchPage(url, attempt = 1) {
  let res;
  try {
    res = await fetch(url, { headers: { 'user-agent': UA, accept: 'text/html' }, redirect: 'follow' });
  } catch (err) {
    return { ok: false, why: `network: ${err.message}` };
  }
  // 🔴 A 202 is a BOT CHALLENGE, not an absent page. Back off and retry rather than scoring it.
  if (res.status === 202 || res.status === 429 || res.status === 503) {
    if (attempt >= 4) return { ok: false, why: `HTTP ${res.status} after ${attempt} attempts` };
    await sleep(DELAY_MS * attempt * 2);
    return fetchPage(url, attempt + 1);
  }
  if (!res.ok) return { ok: false, why: `HTTP ${res.status}` };
  return { ok: true, html: await res.text() };
}

export function classify(html) {
  const root = parse(html);
  // Correction 1: strip from the WHOLE document, before slicing the section.
  root.querySelectorAll('script, style').forEach((n) => n.remove());
  const section = sectionText(root, CC_SECTION_ID);
  if (section === null) {
    return { verdict: 'empty', why: `no #${CC_SECTION_ID} section on the page — the anchor points nowhere` };
  }
  const text = decode(section);
  if (!text.trim()) return { verdict: 'empty', why: 'section is present but empty' };
  // Correction 2: affirmative FIRST. Correction 5: but not when it is negated.
  if (statesCompletedSurvey(text)) {
    return { verdict: 'own-words', why: 'states a completed Candidate Connection survey' };
  }
  const noSurvey = NO_SURVEY_NOTICE.test(text);
  // Correction 4: either shape of own words counts.
  if (CAMPAIGN_WEBSITE.test(text) || (YEAR_HEADING.test(text) && QUOTED_PASSAGE.test(text))) {
    return {
      verdict: 'own-words',
      why: noSurvey ? 'no survey, but quotes the candidate\'s campaign website' : 'quotes the candidate directly',
    };
  }
  if (noSurvey) return { verdict: 'empty', why: 'section states the survey was not completed and quotes nothing' };
  return { verdict: 'empty', why: 'section carries no survey and no quoted candidate words' };
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('FAIL: DATABASE_URL is not set. This sweep reads the live corpus.');
    process.exitCode = 2;
    return;
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(`
    SELECT DISTINCT regexp_replace(s, '#.*$', '') AS page, count(*) OVER () AS total
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE s ~* $1
     ORDER BY page`, [CC_ANCHOR_PATTERN]);
  await pool.end();

  let pages = rows.map((r) => r.page);
  if (LIMIT > 0) pages = pages.slice(0, LIMIT);
  console.log(`${pages.length} distinct pages deep-linked with #${CC_SECTION_ID}`);

  // Keep any previous verdict for a page we cannot reach this run: an access barrier must not
  // delete a verification we already made.
  const prev = existsSync(OUT) ? JSON.parse(readFileSync(OUT, 'utf8')) : { pages: [] };
  const prevByPage = new Map((prev.pages ?? []).map((p) => [p.page, p]));

  const out = [];
  for (let i = 0; i < pages.length; i++) {
    const page = pages[i];
    if (i) await sleep(DELAY_MS);
    const got = await fetchPage(page);
    let rec;
    if (!got.ok) {
      const keep = prevByPage.get(page);
      if (keep && keep.verdict !== 'unreachable') {
        rec = { ...keep, note: `kept from ${keep.checkedAt}; this run: ${got.why}` };
      } else {
        rec = { page, verdict: 'unreachable', why: got.why, checkedAt: new Date().toISOString() };
      }
    } else {
      const c = classify(got.html);
      rec = { page, verdict: c.verdict, why: c.why, checkedAt: new Date().toISOString() };
    }
    out.push(rec);
    const mark = rec.verdict === 'own-words' ? '.' : rec.verdict === 'empty' ? 'E' : '?';
    process.stdout.write(mark);
    if ((i + 1) % 50 === 0) process.stdout.write(` ${i + 1}\n`);
  }
  process.stdout.write('\n');

  const tally = out.reduce((a, r) => ((a[r.verdict] = (a[r.verdict] ?? 0) + 1), a), {});
  const doc = {
    note: 'What is behind each Ballotpedia #Campaign_themes anchor the corpus cites. Read by '
      + 'check-stance-sources.mjs: `own-words` earns the BALLOTPEDIA_ONLY carve-out, `empty` FAILS '
      + 'as CC_ANCHOR_EMPTY, and anything absent from this file REPORTS as CC_ANCHOR_UNVERIFIED. '
      + 'Regenerate with scripts/sweep-candidate-connection-anchors.mjs.',
    unreachableIsNotEmpty: 'A page that could not be fetched is recorded `unreachable`, never '
      + '`empty`. It therefore reports as unverified and can never fail the build. Ballotpedia '
      + 'answers 202 to a fast sweep; a challenge is not an absent page.',
    generatedAt: new Date().toISOString(),
    counts: { pages: out.length, ...tally },
    pages: out,
  };
  writeFileSync(OUT, `${JSON.stringify(doc, null, 1)}\n`);
  console.log(`\n${JSON.stringify(doc.counts)}\nwrote ${path.relative(process.cwd(), OUT)}`);
}

// Importable for tests; sweeps only when run as a script.
if (process.argv[1]?.endsWith('sweep-candidate-connection-anchors.mjs')) main();

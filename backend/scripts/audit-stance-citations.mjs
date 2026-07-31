#!/usr/bin/env node
/**
 * Article-body citation audit — the workhorse of the stance re-sourcing backlog.
 *
 * WHY THIS EXISTS AS A SCRIPT. This test has now been hand-rolled three times: once WRONGLY (stripping
 * raw HTML, which drags in Ballotpedia's mega-menu and made every page match most terms -- the run that
 * produced the "keyword probing has no signal" conclusion), once correctly for the A1 Oregon cohort, and
 * once semi-manually through Playwright to resolve nine pages 1508 had held back. 560 rows across 20+
 * states remain. Re-deriving the method a fourth time is how the first version got it wrong, so every
 * hard-won guard below is encoded here rather than described in a markdown file.
 *
 * WHAT IT DECIDES, AND WHAT IT DOES NOT. It judges the CITATION: do the row's own distinctive claim
 * terms appear in the article body of the page it cites? A row can fail here and still be true -- it
 * just is not sourced by what it cites. It cannot judge whether a present term SUPPORTS the recorded
 * chair, which is why PARTIAL_SUPPORT and SUPPORTED are never auto-retired.
 *
 * THE GUARDS, each of which cost a wrong answer to learn:
 *
 *  1. 🔴 SERIAL, ~1.3s APART. Ballotpedia rate-limits SILENTLY: parallel fetches return HTTP 202 with an
 *     EMPTY body, and `r.ok` is TRUE for 202, so a naive probe records "term not found" for a page it
 *     never read and the false negative looks exactly like evidence.
 *  2. 🔴 ARTICLE BODY ONLY -- `#mw-content-text`, script/style removed, then textContent. NOT the raw
 *     HTML. Chrome is ~10% of the text this way versus dominating it. Verified against Playwright
 *     innerText on the same pages: term results agree exactly.
 *  3. 🔴 A SHORT PAGE IS USUALLY A DISAMBIGUATION STUB, NOT A FAILED FETCH. Test for "may refer to"
 *     before blaming extraction. /Rob_Wagner redirects to /Robert_Wagner and lists five unrelated
 *     Robert Wagners; four more A1 pages were the same. Those are DEAD citations, not unreadable ones.
 *  4. 🔴 ON A DEAD CITATION, CHECK THE CORRECT PAGE TOO. The disambiguation list names the right entry;
 *     follow it and re-run the terms. All five A1 cases failed there as well, which is what proved
 *     re-pointing the URL would not rescue them -- a conclusion no amount of reasoning could reach.
 *  5. 🔴 DROP IDENTITY TERMS. A page names its subject's city, county, chamber and alma mater because it
 *     is that person's page; matching them proves nothing about a policy claim. Without this filter 13
 *     A1 rows scored as supported on things like "House Majority Leader" and "Forest Grove"; with it, 6.
 *  6. 🔴 DROP CORPUS-COMMON TERMS. Ballotpedia's nav names every policy area on every page, so terms
 *     appearing on more than CORPUS_MAX of the fetched pages carry no information.
 *  7. 🔴 A TERM'S PRESENCE IS NOT SUPPORT. Travis Nelson's page contains "Medicaid" only as a
 *     SPONSORED-legislation entry for a 2026 bill on Medicaid payments to reproductive health providers,
 *     while his row claimed a VOTE for Medicaid EXPANSION. Hence PARTIAL_SUPPORT is a queue, not a pass.
 *  8. 🔴 A POLITICIAN-LEVEL VERDICT IS NOT A ROW-LEVEL VERDICT. The first A1 sweep reported 139 failures
 *     by applying one verdict to all of a person's rows; at row level it was 83. Everything here is
 *     keyed on (politician_id, topic_id).
 *
 * 🔴 THE CAMPAIGN-THEMES FLAG STRENGTHENS A FAILURE, IT DOES NOT RESCUE ONE. An earlier version of this
 * summary claimed the opposite -- that a CITATION_FAILS row whose page has Campaign themes should be
 * re-sourced rather than retired. That is backwards, and it matters because it points the wrong way on a
 * retirement decision. The term test reads the WHOLE article body, and Campaign themes is PART of that
 * body. So terms-absent on a page that carries campaign themes means the claim is missing from the
 * candidate's own stated positions too -- the cleanest kind of failure, not a softer one. The flag is
 * only informative in the other direction: a page with NO themes and NO completed survey could never
 * have sourced a challenger's position, so citing it was hopeless from the start.
 *
 * Measured in TX: campaign themes are present on 100% of the 55 pages, so the flag does not discriminate
 * within that cohort at all -- it is a property of Ballotpedia candidate pages generally. Reported for
 * that reason rather than used as a filter.
 *
 * RESIDUAL RISK, stated because the tool cannot close it: campaign themes may express a position in
 * DIFFERENT WORDS than the row's terms ("healthcare for all" vs "universal healthcare"). Term absence is
 * then a true statement about the citation and a possible false negative about the claim. That is why
 * CITATION_FAILS on a themes-bearing page deserves a sampled human read before a bulk retirement.
 *
 * Usage (from backend/):
 *   node scripts/audit-stance-citations.mjs --state tx --out data/stance-retirement/tx.json
 *   node scripts/audit-stance-citations.mjs --state tx --limit 20      # calibration run
 *   node scripts/audit-stance-citations.mjs --pids a,b,c               # specific politicians
 *   node scripts/audit-stance-citations.mjs --state tx --delay 3200    # after a rate-limit run
 *   node scripts/audit-stance-citations.mjs --state tx --print QUOTE_ABSENT
 *
 * 🔴 IF A RUN REPORTS UNKNOWN_PAGE_UNREAD, RE-RUN THOSE PAGES AT A HIGHER --delay BEFORE READING THE
 * TALLY. Running this twice in quick succession trips Ballotpedia's limiter: a second TX pass at 1300ms
 * put 42 rows across 12 pages into UNKNOWN. The guard is working when that happens -- the tally is
 * simply incomplete until they are re-read, and they must never be counted as failures.
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { Pool } from 'pg';
import { parse } from 'node-html-parser';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const STATE = flag('--state');
const PIDS = flag('--pids');
const LIMIT = parseInt(flag('--limit', '0'), 10);
const OUT = flag('--out');
const DELAY = parseInt(flag('--delay', '1300'), 10);
/**
 * 🔴 0.75, NOT 0.25, AND IT COST A WRONG VERDICT TO LEARN. This filter exists to kill Ballotpedia's
 * SITE CHROME -- the nav names every policy area on every page, so those terms sit near 100%
 * prevalence. It is not meant to kill genuinely shared policy vocabulary. At 0.25 on the 6-page Oregon
 * residue it dropped "walkout", which is the load-bearing term for four Senate Republicans who all
 * joined the same walkout -- flipping Kim Thatcher from PARTIAL_SUPPORT to CITATION_FAILS on a corpus
 * artifact, i.e. toward retiring a row whose citation actually holds. A small, homogeneous cohort makes
 * a discriminating term look common. Hence a high threshold AND the >=8-page gate below.
 */
const CORPUS_MAX = parseFloat(flag('--corpus-max', '0.75'));
const MIN_BODY = parseInt(flag('--min-body', '1500'), 10);
const PRINT = flag('--print');

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const STATE_NAMES = {
  al: 'Alabama', ak: 'Alaska', az: 'Arizona', ar: 'Arkansas', ca: 'California', co: 'Colorado',
  ct: 'Connecticut', de: 'Delaware', fl: 'Florida', ga: 'Georgia', hi: 'Hawaii', id: 'Idaho',
  il: 'Illinois', in: 'Indiana', ia: 'Iowa', ks: 'Kansas', ky: 'Kentucky', la: 'Louisiana',
  me: 'Maine', md: 'Maryland', ma: 'Massachusetts', mi: 'Michigan', mn: 'Minnesota', ms: 'Mississippi',
  mo: 'Missouri', mt: 'Montana', ne: 'Nebraska', nv: 'Nevada', nh: 'New Hampshire', nj: 'New Jersey',
  nm: 'New Mexico', ny: 'New York', nc: 'North Carolina', nd: 'North Dakota', oh: 'Ohio', ok: 'Oklahoma',
  or: 'Oregon', pa: 'Pennsylvania', ri: 'Rhode Island', sc: 'South Carolina', sd: 'South Dakota',
  tn: 'Tennessee', tx: 'Texas', ut: 'Utah', vt: 'Vermont', va: 'Virginia', wa: 'Washington',
  wv: 'West Virginia', wi: 'Wisconsin', wy: 'Wyoming', dc: 'District of Columbia',
};

// ---------------------------------------------------------------------------- cohort

const QUERY = `
  SELECT
    pa.politician_id::text AS pid, pa.topic_id::text AS tid, pa.value,
    pc.reasoning, pc.sources,
    p.first_name, p.last_name,
    coalesce(t.short_title, t.title, pa.topic_id::text) AS topic,
    lower(coalesce(seat.state, seat.representing_state, cand.state, '')) AS st,
    coalesce(seat.title, '')  AS office_title,
    coalesce(seat.label, '')  AS district_label,
    coalesce(seat.city, '')   AS office_city,
    (seat.office_id IS NOT NULL) AS seated,
    (cand.state IS NOT NULL)     AS on_ballot
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
  -- LIMIT-1 laterals, never a join: office_current_holder is one row per OFFICE and people hold two,
  -- so joining on politician_id fans the result set out. Same trap as CLAUDE.md's is_vacant note.
  LEFT JOIN LATERAL (
    SELECT och.office_id, o.title, o.representing_state, o.representing_city AS city, d.state, d.label
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
      AND rc.is_incumbent = false AND e.election_date >= CURRENT_DATE
    ORDER BY e.election_date LIMIT 1
  ) cand ON true
  WHERE pa.value <> 0
    AND pc.reasoning IS NOT NULL
    AND cardinality(pc.sources) > 0
    AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT ILIKE '%ballotpedia%')`;

// ---------------------------------------------------------------------------- term extraction

const STOP = new Set(('the a an and or but of for to in on at by with from as is are was were be been being that this ' +
  'these those it its his her their our your they he she we you i not no nor so than then there here when where ' +
  'which who whom whose what how why all any both each few more most other some such only own same too very can ' +
  'will just should now also including includes include support supported supports supporting oppose opposed ' +
  'opposes opposing voted vote votes voting backed backs back consistent strong record position measures measure ' +
  'legislation bill bills policy policies during throughout part while against toward towards').split(/\s+/));

const CAP_PHRASE = /\b[A-Z][a-zA-Z']+(?:\s+(?:of|for|and|the|de|van)\s+|\s+)(?:[A-Z][a-zA-Z']+)(?:(?:\s+(?:of|for|and|the)\s+|\s+)[A-Z][a-zA-Z']+)*/g;
const HYPHEN = /\b[a-zA-Z]{2,}(?:-[a-zA-Z]{2,})+\b/g;
const SINGLE_CAP = /\b[A-Z][a-zA-Z']{4,}\b/g;
const BILLREF = /\b(?:H\.?\s?B|S\.?\s?B|HJR|SJR|HCR|SCR|A\.?\s?B|AJR|LD|LB|HF|SF|H\.?\s?R|S\.?\s?R|H\.?\s?Con\.?\s?Res|S\.?\s?J\.?\s?Res|RES|ORD|HJ|SJ)\s*[-.\s]?\s*\d+[A-Za-z]?\b/gi;
const MEASUREREF = /\b(?:Measure|Proposition|Prop|Question|Initiative|Amendment)\s*\.?\s*\d+[A-Za-z]?\b/gi;

/**
 * 🔴 NO ARBITRARY BIGRAMS. The first version of this extractor paired any two adjacent long words,
 * which produced "issue because", "scale closest", "people without", "dentist emphasizes". Those are
 * prose fragments, not claim terms: they are RARE, so the corpus-frequency filter keeps them, and they
 * land in `missing` and push genuinely-supported rows down to PARTIAL_SUPPORT. Calibrated against the
 * A1 audit, whose term lists were tight -- ["cap-and-trade","job-killing","walkout"] for Drazan,
 * ["Corporate Activity Tax","Lane County","anti-tax"] for Harbick. Multi-word phrases come from a
 * curated policy lexicon instead, which is high-precision by construction.
 */
const POLICY_PHRASES = [
  'border security', 'immigration enforcement', 'sanctuary city', 'sanctuary state', 'cap and trade',
  'voter id', 'photo id', 'clean energy', 'public option', 'single payer', 'school choice',
  'right to work', 'minimum wage', 'paid leave', 'family leave', 'gun control', 'assault weapons',
  'background checks', 'red flag', 'medicaid expansion', 'school vouchers', 'charter schools',
  'rent control', 'rent stabilization', 'affordable housing', 'criminal justice', 'police accountability',
  'qualified immunity', 'death penalty', 'campaign finance', 'dark money', 'donor disclosure',
  'term limits', 'ranked choice', 'vote by mail', 'automatic voter registration', 'gender affirming',
  'transgender athletes', 'parental rights', 'critical race theory', 'carbon tax', 'net metering',
  'fossil fuel', 'universal healthcare', 'public transit', 'zoning reform', 'inclusionary zoning',
  'corporate tax', 'income tax', 'sales tax', 'property tax', 'estate tax', 'payroll tax',
  'student debt', 'tuition free', 'universal pre', 'planned parenthood', 'parental notification',
  'heartbeat bill', 'late term', 'conscience protection', 'religious exemption', 'union dues',
  'collective bargaining', 'prevailing wage', 'tort reform', 'eminent domain', 'civil asset forfeiture',
  'bail reform', 'mandatory minimum', 'drug decriminalization', 'harm reduction', 'needle exchange',
  'work requirements', 'block grant', 'balanced budget', 'rainy day', 'kicker rebate',
];

/**
 * Frequent English and civic words that are worthless as claim terms. Single tokens only. The dynamic
 * corpus filter catches most of these when enough pages are read, but it needs ~8+ pages to be
 * reliable, and a small run must not therefore score a row on "Health" or "Participated".
 */
const COMMON_TOKEN = new Set(('republican republicans democrat democrats democratic senate house senator ' +
  'representative assembly legislature legislative congress congressional state states federal government ' +
  'governor mayor council county city district committee chair chairman speaker leader caucus session ' +
  'health healthcare education school schools tax taxes taxation budget spending revenue funding fund ' +
  'program programs bill bills law laws act acts policy policies measure measures legislation vote votes ' +
  'voted voting voter voters election elections campaign campaigns candidate candidates primary general ' +
  'participated supported opposed backed sponsored cosponsored introduced passed failed approved rejected ' +
  'public private community communities family families worker workers business businesses industry ' +
  'industries resident residents people person persons citizen citizens american americans national ' +
  'security social justice rights protection protections access expansion reform regulations regulation ' +
  'environmental economic financial social political conservative progressive liberal moderate ' +
  'platform position positions record records issue issues emphasizes calls scale closest current ' +
  'legal status alternatives controlled individually entitlements guilty aliens undocumented ' +
  'affecting blocking ending mandates approaches').split(/\s+/));

/**
 * Single tokens come from a CURATED lexicon, not a length rule. A generic ">=6 chars and not common"
 * rule leaked "because", "country", "explicit", "exception", "activity", "authorize" -- ordinary prose
 * words that are rare enough to survive a frequency filter and so become fake evidence in either
 * direction. These are the single words that actually carry a policy claim, and the A1 audit's real
 * finds are all here: walkout, quorum, sanctuary, medicaid.
 *
 * Under-extraction is SAFE here and over-extraction is not: a row with no surviving term becomes
 * UNTESTABLE, which this tool reports as a decision to be made rather than a retirement.
 */
const POLICY_TOKENS = new Set(('walkout quorum filibuster gerrymander gerrymandering sanctuary medicaid medicare ' +
  'obamacare vouchers voucher charter fracking pipeline pipelines abortion contraception ' +
  'trans transgender nonbinary immigration deportation daca ice asylum refugee refugees ' +
  'unionize unionization strikes picketing minimum wages tipped ' +
  'firearms firearm handgun handguns suppressors magazines ' +
  'marijuana cannabis psilocybin decriminalize decriminalization ' +
  'redistricting apportionment ballots absentee provisional gerrymandered ' +
  'vaccination vaccine mandate mandates masking lockdown lockdowns ' +
  'tariffs subsidies subsidy privatize privatization nationalize ' +
  'homelessness encampments upzoning downzoning setbacks ' +
  'reparations affirmative desegregation bussing ' +
  'nuclear renewables solar wind geothermal hydropower emissions ' +
  'kicker referendum initiative recall supermajority ' +
  'earmarks pork sequestration deficits surplus ' +
  'euthanasia hospice palliative telehealth ' +
  'homeschool homeschooling tenure creationism ' +
  'annexation zoning easement moratorium ordinance').split(/\s+/));

/**
 * 🔴 QUOTE-BEARING ROWS MUST BE JUDGED ON THE QUOTE, NOT ON DISTINCTIVE TERMS. Discovered on the TX
 * cohort, whose rows are a different breed from Oregon's: they quote campaign websites and Candidate
 * Connection surveys directly ("Resist any attempts to impose a national school voucher scheme") rather
 * than asserting bills. The term test produced FALSE FAILURES on them for three reasons, none of which
 * is evidence about the citation:
 *
 *   - morphology: the row's term was "vouchers", the page says "voucher"
 *   - the row's INTERPRETIVE vocabulary is not the source's: a row may correctly quote "the right to
 *     make their own healthcare decisions" and then reasonably label it abortion access. "abortion"
 *     being absent says something about the label, not about whether the citation checks out
 *   - extractor artifacts: "His Candidate Connection" (a capitalised phrase starting on the row's own
 *     pronoun) and "Paul Ryan's" (possessive that cannot match "Paul Ryan")
 *
 * A quote is a far stronger test than a term: it is long, verbatim and unambiguous. So when a row
 * contains quoted material, the quote verdict governs and the term verdict is reported alongside.
 */
/**
 * 🔴 PAIR THE QUOTE MARKS; DO NOT REGEX ACROSS THEM. And an apostrophe is NOT a quote mark. The first
 * version used /["“”']([^"“”]{25,400}?)["“”']/g and produced pure artifacts on the TX cohort:
 *
 *   - "s tariff authority and lower"   <- started mid-word inside Congress's, because ' was a delimiter
 *   - "a top plank -- citing his career in the Border Patrol"   <- the UNQUOTED prose BETWEEN two real
 *     quotes, because the regex matched from one closing mark to the next opening mark
 *
 * Both look exactly like a missing quote and would have put well-sourced rows on a retirement list.
 * Marks are therefore consumed in order, strictly as open/close pairs.
 *
 * 🔴 AN ELLIPSIS MEANS SPLICED, NON-CONTIGUOUS TEXT. "lower drug costs ... end surprise billing" can
 * never match a page verbatim, so the quote is split on the ellipsis and each fragment tested
 * separately. A quote counts as verified when every fragment long enough to be distinctive is present.
 */
function extractQuotes(reasoning) {
  const marks = /["“”]/g;
  const positions = [];
  for (const m of reasoning.matchAll(marks)) positions.push(m.index);
  const out = [];
  for (let i = 0; i + 1 < positions.length; i += 2) {
    const q = reasoning.slice(positions[i] + 1, positions[i + 1]).trim();
    // >=3 words, not >=4. At >=4, Casey Shepard's quote "compassionate immigration reform" was skipped,
    // the row fell through to the term test, and its only surviving term was the author's own coinage
    // "reform-oriented" -- producing a CITATION_FAILS on a row whose quote was very likely on the page.
    if (q.length >= 20 && /[a-z]/i.test(q) && q.split(/\s+/).length >= 3) out.push(q);
  }
  return out;
}

/** Fragments of a quote that are long enough to be distinctive, split on elided spans. */
function quoteFragments(q) {
  return q.split(/\s*(?:\.\.\.|…)\s*/).map((f) => f.trim()).filter((f) => norm(f).length >= 20);
}

/** A quote is present when every distinctive fragment of it is present. */
function quotePresent(body, q) {
  const frags = quoteFragments(q);
  if (!frags.length) return null;                     // nothing testable in it
  return frags.every((f) => looseIncludes(body, f));
}

/** Normalise for comparison: fold case, curly quotes, bracketed edits and all punctuation/space runs. */
function norm(s) {
  return s.toLowerCase()
    .replace(/[‘’“”]/g, "'")
    .replace(/\[[^\]]*\]/g, '')            // "advocate[s]" -> "advocate"
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/** Does `needle` appear in `haystack` allowing a simple plural/singular difference per word? */
function looseIncludes(haystack, needle) {
  const h = norm(haystack);
  const n = norm(needle);
  if (!n) return false;
  if (h.includes(n)) return true;
  const stem = (w) => w.replace(/(?:ies|es|s)$/, '');
  const nStem = n.split(' ').map(stem).join(' ');
  return nStem.length > 3 && h.split(' ').map(stem).join(' ').includes(nStem);
}

function candidateTerms(reasoning) {
  const text = reasoning.replace(/https?:\/\/\S+/g, ' ');
  const lower = text.toLowerCase();
  const seen = new Map();                       // lowercased -> original casing
  const add = (s) => {
    // Strip a leading pronoun/determiner the capitalised-phrase regex swept up from the row's own prose
    // ("His Candidate Connection"), and drop possessives that can never match the page ("Paul Ryan's").
    const v = s.trim().replace(/\s+/g, ' ').replace(/[.,;:]$/, '')
      .replace(/^(?:His|Her|Their|Its|The|A|An|He|She|They)\s+/i, '')
      .replace(/['’]s\b/g, '');
    if (v.length < 5) return;
    const k = v.toLowerCase();
    if (STOP.has(k) || COMMON_TOKEN.has(k)) return;
    if (!seen.has(k)) seen.set(k, v);
  };

  for (const re of [BILLREF, MEASUREREF, CAP_PHRASE, HYPHEN]) {
    re.lastIndex = 0;
    for (const m of text.matchAll(re)) add(m[0]);
  }
  for (const p of POLICY_PHRASES) if (lower.includes(p)) add(p);

  // Single tokens from the curated policy lexicon only.
  for (const m of text.matchAll(/\b[a-zA-Z][a-zA-Z']{3,}\b/g)) {
    const k = m[0].toLowerCase();
    if (POLICY_TOKENS.has(k)) add(m[0]);
  }

  // Drop any term wholly contained in a longer kept term ("oregon health" under "Oregon Health Plan",
  // "Security" under "Social Security") -- it is the same evidence counted twice.
  const kept = [...seen.values()];
  return kept.filter((t) => !kept.some((o) => o !== t && o.length > t.length
    && o.toLowerCase().includes(t.toLowerCase())));
}

/**
 * Identity terms: everything a page names because of WHOSE page it is. Built per row from the
 * politician's own name, district, office and state rather than a global list, because "Portland" is
 * identity for a Portland member and a real policy token for nobody else's page.
 */
function identityTerms(row) {
  const bits = [
    row.first_name, row.last_name, row.office_title, row.district_label, row.office_city,
    STATE_NAMES[row.st], row.st?.toUpperCase(),
  ].filter(Boolean);
  const set = new Set();
  for (const b of bits) {
    set.add(String(b).toLowerCase());
    for (const w of String(b).split(/[^A-Za-z]+/)) if (w.length >= 4) set.add(w.toLowerCase());
  }
  for (const generic of ['state house', 'state senate', 'house district', 'senate district', 'city council',
    'majority leader', 'minority leader', 'house majority', 'senate republican', 'senate democrat',
    'republican party', 'democratic party', 'state representative', 'state senator', 'county commission']) set.add(generic);
  return set;
}

// ---------------------------------------------------------------------------- fetching

async function fetchBody(url, tries = 2) {
  for (let i = 0; i < tries; i++) {
    if (i) await sleep(DELAY * 2);
    let res;
    try {
      res = await fetch(url, { headers: { 'User-Agent': UA, Accept: 'text/html' }, redirect: 'follow', signal: AbortSignal.timeout(45000) });
    } catch (e) {
      if (i === tries - 1) return { status: 0, error: e.message, body: '', finalUrl: url };
      continue;
    }
    const html = await res.text();
    // 🔴 202-with-empty-body is the silent rate limit. Anything not 200 is UNKNOWN, never a miss.
    if (res.status !== 200) { if (i === tries - 1) return { status: res.status, body: '', finalUrl: res.url || url }; continue; }
    const root = parse(html);
    const el = root.querySelector('#mw-content-text');
    if (!el) return { status: 200, body: '', noContentDiv: true, finalUrl: res.url || url, html: html.length };
    el.querySelectorAll('script,style').forEach((n) => n.remove());
    const body = el.textContent.replace(/\s+/g, ' ').trim();
    const links = el.querySelectorAll('a').map((a) => ({ text: a.textContent.trim(), href: a.getAttribute('href') || '' }));
    return { status: 200, body, links, finalUrl: res.url || url, html: html.length };
  }
  return { status: 0, body: '', finalUrl: url };
}

const isDisambig = (body) => /\bmay refer to\b|\bdisambiguation page\b/i.test(body.slice(0, 600));

/** Follow the disambiguation list to the entry for this politician's state. */
function resolveDisambig(page, row) {
  const want = STATE_NAMES[row.st];
  if (!want) return null;
  for (const l of page.links ?? []) {
    if (new RegExp(`\\(${want}\\)`, 'i').test(l.text) || new RegExp(`\\(${want}\\b`, 'i').test(l.href)) {
      return l.href.startsWith('http') ? l.href : `https://ballotpedia.org${l.href}`;
    }
  }
  const base = decodeURIComponent(page.finalUrl.split('/').pop() || '');
  return base ? `https://ballotpedia.org/${encodeURIComponent(base)}_(${want.replace(/ /g, '_')})` : null;
}

const pageFlags = (body) => ({
  campaign_themes: /campaign themes/i.test(body),
  survey_not_completed: /did not complete|has not completed|not yet completed/i.test(body),
  scorecards: /scorecard/i.test(body),
  sponsored_legislation: /sponsored legislation/i.test(body),
});

// ---------------------------------------------------------------------------- main

(async () => {
  if (!process.env.DATABASE_URL) { console.log('SKIP: DATABASE_URL not set.'); process.exit(0); }

  let sql = QUERY;
  const params = [];
  if (PIDS) { params.push(PIDS.split(',').map((s) => s.trim())); sql += ` AND pa.politician_id = ANY($${params.length}::uuid[])`; }
  const { rows: all } = await pool.query(sql, params);

  // Comma-separated so a sweep can be split into passes that each finish and write their own report.
  // A full-cohort run is ~199 pages, which at a safe delay exceeds a 10-minute command cap and dies
  // before the write step, losing everything. Chunk it.
  let rows = all;
  if (STATE) {
    const want = new Set(STATE.toLowerCase().split(',').map((s) => s.trim()));
    rows = rows.filter((r) => want.has(r.st) || (want.has('none') && !r.st));
  }
  rows.sort((a, b) => `${a.last_name}${a.topic}`.localeCompare(`${b.last_name}${b.topic}`));
  if (LIMIT) rows = rows.slice(0, LIMIT);

  const byUrl = new Map();
  for (const r of rows) {
    const url = (r.sources ?? []).find((s) => /ballotpedia\.org/i.test(s)) ?? (r.sources ?? [])[0];
    r._url = url;
    if (!byUrl.has(url)) byUrl.set(url, []);
    byUrl.get(url).push(r);
  }

  console.log(`${rows.length} rows / ${new Set(rows.map((r) => r.pid)).size} politicians / ${byUrl.size} distinct pages`);
  console.log(`fetching serially at ${DELAY}ms — ETA ~${Math.ceil((byUrl.size * DELAY) / 60000)} min\n`);

  const pages = new Map();
  let n = 0;
  for (const url of byUrl.keys()) {
    n++;
    const page = await fetchBody(url);
    let resolved = null;
    if (page.status === 200 && isDisambig(page.body)) {
      const target = resolveDisambig(page, byUrl.get(url)[0]);
      if (target) { await sleep(DELAY); resolved = await fetchBody(target); resolved.url = target; }
    }
    pages.set(url, { ...page, resolved });
    const tag = page.status !== 200 ? `HTTP ${page.status}`
      : isDisambig(page.body) ? `DISAMBIG -> ${resolved ? `${resolved.status} ${resolved.body.length}ch` : 'unresolved'}`
        : `${page.body.length}ch`;
    console.log(`  [${String(n).padStart(3)}/${byUrl.size}] ${url.replace('https://ballotpedia.org', '')}  ${tag}`);
    await sleep(DELAY);
  }

  // Corpus frequency over the pages actually read, computed AFTER all fetches.
  const readBodies = [...pages.values()].map((p) => (p.resolved?.body?.length > p.body.length ? p.resolved.body : p.body))
    .filter((b) => b.length >= MIN_BODY).map((b) => b.toLowerCase());
  const corpusHits = (term) => readBodies.filter((b) => b.includes(term.toLowerCase())).length;

  const results = [];
  for (const r of rows) {
    const page = pages.get(r._url);
    const dis = page.status === 200 && isDisambig(page.body);
    const eff = dis && page.resolved?.status === 200 ? page.resolved : page;      // page we can actually test on
    const ident = identityTerms(r);

    const raw = candidateTerms(r.reasoning);
    const dropIdent = [], dropCommon = [], terms = [];
    for (const t of raw) {
      if (ident.has(t.toLowerCase()) || [...ident].some((i) => i.length >= 5 && t.toLowerCase() === i)) { dropIdent.push(t); continue; }
      if (readBodies.length >= 8 && corpusHits(t) / readBodies.length > CORPUS_MAX) { dropCommon.push(t); continue; }
      terms.push(t);
    }

    const testable = eff.status === 200 && eff.body.length >= MIN_BODY && !isDisambig(eff.body);
    const found = testable ? terms.filter((t) => looseIncludes(eff.body, t)) : [];
    const missing = testable ? terms.filter((t) => !found.includes(t)) : terms;

    // Quotes govern where present: verbatim text is unambiguous where a single term is not.
    const allQuotes = extractQuotes(r.reasoning);
    // A quote with no distinctive fragment (all of it elided) is not testable and must not count as
    // absent -- that is the same false-negative class as an unread page.
    const quotes = testable ? allQuotes.filter((q) => quotePresent(eff.body, q) !== null) : allQuotes;
    const qUntestable = allQuotes.filter((q) => !quotes.includes(q));
    const qFound = testable ? quotes.filter((q) => quotePresent(eff.body, q)) : [];
    const qMissing = testable ? quotes.filter((q) => !qFound.includes(q)) : quotes;

    let verdict;
    if (dis && !(page.resolved?.status === 200 && page.resolved.body.length >= MIN_BODY)) verdict = 'DEAD_CITATION_UNRESOLVED';
    else if (dis && testable && (qFound.length || found.length)) verdict = 'DEAD_CITATION_BUT_CORRECT_PAGE_MATCHES';
    else if (dis && testable && (quotes.length || terms.length)) verdict = 'DEAD_CITATION_ALSO_FAILS';
    else if (dis) verdict = 'DEAD_CITATION_UNTESTABLE';
    else if (!testable) verdict = 'UNKNOWN_PAGE_UNREAD';
    else if (quotes.length) {
      verdict = qFound.length === quotes.length ? 'QUOTE_VERIFIED'
        : qFound.length ? 'QUOTE_PARTIAL' : 'QUOTE_ABSENT';
    } else if (!terms.length) verdict = 'UNTESTABLE';
    else if (!found.length) verdict = 'CITATION_FAILS';
    else if (missing.length) verdict = 'PARTIAL_SUPPORT';
    else verdict = 'SUPPORTED';

    results.push({
      pid: r.pid, tid: r.tid, name: `${r.first_name} ${r.last_name}`, topic: r.topic, value: r.value,
      state: r.st, seated: r.seated, on_ballot: r.on_ballot,
      office: r.office_title, district: r.district_label,
      cited_url: r._url, cited_status: page.status, cited_chars: page.body.length, cited_disambiguation: dis,
      correct_url: dis ? (page.resolved?.url ?? null) : null,
      correct_chars: dis ? (page.resolved?.body.length ?? 0) : null,
      tested_chars: testable ? eff.body.length : 0,
      verdict,
      quotes_tested: quotes, quotes_found: qFound, quotes_missing: qMissing, quotes_untestable: qUntestable,
      terms_tested: terms, found, missing,
      dropped_identity: dropIdent, dropped_corpus_common: dropCommon,
      page: testable ? pageFlags(eff.body) : null,
      reasoning: r.reasoning,
    });
  }

  const tally = {};
  for (const x of results) tally[x.verdict] = (tally[x.verdict] ?? 0) + 1;

  console.log('\nverdict                                  rows  politicians');
  for (const [v, c] of Object.entries(tally).sort((a, b) => b[1] - a[1])) {
    const pols = new Set(results.filter((x) => x.verdict === v).map((x) => x.pid)).size;
    console.log(`  ${v.padEnd(38)} ${String(c).padStart(4)}  ${String(pols).padStart(11)}`);
  }

  // 🔴 UNTESTABLE IS NOT A RETIRE CANDIDATE. Retiring the 27 untestable A1 rows was an operator
  // DECISION (an untestable citation cannot meet a bar that requires a supporting source), not a
  // property this tool gets to presume for every future cohort. It is also the verdict most sensitive
  // to the extractor's own coverage: a term this script fails to recognise shows up here. Reported as
  // its own bucket so the decision stays explicit and visible.
  const RETIRE = new Set(['CITATION_FAILS', 'QUOTE_ABSENT', 'DEAD_CITATION_ALSO_FAILS', 'DEAD_CITATION_UNTESTABLE']);
  const HUMAN = new Set(['PARTIAL_SUPPORT', 'SUPPORTED', 'QUOTE_VERIFIED', 'QUOTE_PARTIAL', 'DEAD_CITATION_BUT_CORRECT_PAGE_MATCHES']);
  const cand = results.filter((x) => RETIRE.has(x.verdict));
  const resourceable = cand.filter((x) => x.page?.campaign_themes);
  const untestable = results.filter((x) => x.verdict === 'UNTESTABLE');
  const themesPct = results.filter((x) => x.page).length
    ? Math.round((results.filter((x) => x.page?.campaign_themes).length / results.filter((x) => x.page).length) * 100)
    : 0;
  console.log(`\nretire candidates (citation demonstrably fails):  ${cand.length}`);
  console.log(`  of these, the page DOES carry candidate-stated content (campaign themes): ${resourceable.length}`);
  console.log(`  -> that STRENGTHENS the failure: the claim is absent from the candidate's own stated`);
  console.log(`     positions too, since campaign themes are part of the body searched.`);
  console.log(`  campaign themes present on ${themesPct}% of pages read — check this before treating it as a signal.`);
  console.log(`needs a human read (a term IS present):           ${results.filter((x) => HUMAN.has(x.verdict)).length}`);
  console.log(`UNTESTABLE — policy decision, not auto-retire:    ${untestable.length}`);
  console.log(`unknown (page unread):                           ${results.filter((x) => x.verdict === 'UNKNOWN_PAGE_UNREAD').length}   <- re-run, never score as a miss`);

  if (PRINT) {
    const sel = results.filter((x) => x.verdict === PRINT);
    console.log(`\n--- ${PRINT} (${sel.length}) ---`);
    for (const x of sel) {
      console.log(`\n${x.name} — ${x.topic} (value ${x.value})  ${x.cited_url.replace('https://ballotpedia.org', '')}`);
      if (x.quotes_missing?.length) console.log(`  quote NOT on page: "${x.quotes_missing[0].slice(0, 150)}"`);
      if (x.missing?.length) console.log(`  terms missing: ${JSON.stringify(x.missing)}`);
      if (x.found?.length) console.log(`  terms found:   ${JSON.stringify(x.found)}`);
      console.log(`  reasoning: ${x.reasoning.replace(/https?:\/\/\S+/g, '').trim().slice(0, 200)}`);
    }
  }

  if (OUT) {
    const p = path.resolve(OUT);
    writeFileSync(p, `${JSON.stringify({
      _comment: 'Article-body citation audit. Judges the CITATION, not the claim: a row can fail here and still be true. PARTIAL_SUPPORT/SUPPORTED are NEVER auto-retired -- a term\'s presence is not support. UNKNOWN_PAGE_UNREAD must be re-run, never scored as a miss.',
      generated: { state: STATE ?? 'all', rows: results.length, pages: byUrl.size, corpus_pages: readBodies.length, corpus_max: CORPUS_MAX, min_body: MIN_BODY },
      tally, rows: results,
    }, null, 2)}\n`);
    console.log(`\nwritten to ${path.relative(process.cwd(), p)}`);
  }

  await pool.end();
})().catch(async (e) => {
  console.error('FAIL:', e.message);
  try { await pool.end(); } catch { /* closed */ }
  process.exit(2);
});

#!/usr/bin/env node
/**
 * For CHARACTERISATION rows -- the ones that describe a source rather than quote it -- show what the
 * cited site says ABOUT THE ROW'S TOPIC, so a human can judge whether it supports the chair.
 *
 * WHY THE OTHER TOOLS CANNOT DO THIS. `repair-primary-site-paths.mjs` scores a row by looking for the
 * row's own distinctive terms on the page, and `claim-match.mjs` already documents why that is weak
 * evidence for this shape of row: a row may correctly describe a page in its own vocabulary, so the
 * absence of the row's LABEL says something about the label and nothing about the citation. Of the 78
 * rows this tool is built for, a hand sample found the clear majority correctly sourced with only the
 * author's coinages missing ("tax-avoidance", "loophole-closing", "pro-choice").
 *
 * 🔴 SO IT DELIBERATELY DOES NOT SCORE THE PAGE AGAINST THE ROW. Searching a page for what the row
 * claims is how a reviewer confirms whatever the row already said -- the failure mode that produced a
 * wrong verdict on Travis Nelson (page contains "Medicaid", row claims a Medicaid-expansion VOTE, and
 * presence was read as support). Instead the page is searched with a lexicon built from the COMPASS
 * TOPIC ITSELF -- its title, its question, and the text of all five chairs -- which is independent of
 * what this particular row asserts. The reviewer then compares two things side by side: what the page
 * says about the topic, and what the row says it says.
 *
 * Output is grouped BY SITE, because 78 rows sit on 54 sites and several sites carry a whole compass.
 * Reading a site once and judging all of its rows together is both cheaper and more consistent.
 *
 * 🔴 IT PROPOSES NOTHING. Every row it prints is a row to read. On this workstream the detectors have
 * been corrected nine times and have never once been right that a row should be deleted.
 *
 * Usage (from backend/):
 *   node scripts/probe-topic-evidence.mjs --in data/stance-retirement/2026-08-01-noquote-queue.json \
 *        --md data/stance-retirement/2026-08-01-topic-evidence.md
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';
import { crawlSite, pooled } from './lib/site-crawl.mjs';
import { norm, stemLine, STOP, COMMON_TOKEN } from './lib/claim-match.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in', 'data/stance-retirement/2026-08-01-noquote-queue.json');
const OUT = flag('--out');
const MD = flag('--md');
const VERDICT = flag('--verdict', 'NO_QUOTE');
const TOP = parseInt(flag('--top', '3'), 10);
const CONCURRENCY = parseInt(flag('--concurrency', '6'), 10);

const CRAWL = { hostDelay: 900, maxPages: 8, minBody: 600, cacheTtlHours: 24 };
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// ---------------------------------------------------------------------------- topic lexicon

/**
 * Words that carry the topic, taken from the topic's own definition rather than from the row.
 * All five chairs are used, not just the one the row picked -- a page arguing the OPPOSITE of the
 * recorded chair is exactly what a reviewer most needs to see, and a lexicon built from one chair
 * would hide it.
 */
function topicLexicon(topic, stances) {
  const src = [topic.title, topic.short_title, topic.question_text, ...stances.map((s) => s.text)]
    .filter(Boolean).join(' ');
  const seen = new Set();
  for (const w of norm(src).split(' ')) {
    if (w.length < 4) continue;
    if (STOP.has(w) || COMMON_TOKEN.has(w)) continue;
    seen.add(stemLine(w));
  }
  return seen;
}

function tokenize(text) {
  const out = [];
  for (const m of text.matchAll(/[A-Za-z0-9][A-Za-z0-9'’-]*/g)) {
    out.push({ at: m.index, end: m.index + m[0].length, key: stemLine(norm(m[0])) });
  }
  return out;
}

/** Sentence-ish spans of a page, with their character offsets. */
function segments(body) {
  const out = [];
  let start = 0;
  const re = /(?<=[.!?])\s+/g;
  let m;
  while ((m = re.exec(body))) {
    if (m.index - start > 40) out.push({ from: start, to: m.index });
    start = m.index + m[0].length;
  }
  if (body.length - start > 40) out.push({ from: start, to: body.length });
  // Campaign sites collapse bullet lists into one long "sentence"; split the monsters on capital runs.
  return out.flatMap((s) => {
    const text = body.slice(s.from, s.to);
    if (text.length <= 600) return [s];
    const parts = [];
    for (let i = 0; i < text.length; i += 400) parts.push({ from: s.from + i, to: Math.min(s.to, s.from + i + 400) });
    return parts;
  });
}

/** The page passages that talk about this topic the most, scored on distinct lexicon hits. */
function topicPassages(pages, lex) {
  const scored = [];
  for (const p of pages) {
    const body = `${p.body} ${p.chrome ?? ''}`;
    const toks = tokenize(body);
    for (const seg of segments(body)) {
      const hits = new Set();
      for (const t of toks) {
        if (t.at >= seg.from && t.end <= seg.to && lex.has(t.key)) hits.add(t.key);
      }
      if (hits.size >= 2) {
        scored.push({
          url: p.url, hits: hits.size, terms: [...hits].slice(0, 8),
          text: body.slice(seg.from, seg.to).trim().slice(0, 420),
        });
      }
    }
  }
  scored.sort((a, b) => b.hits - a.hits);
  // De-duplicate near-identical passages (nav repeated across pages).
  const out = [];
  for (const s of scored) {
    if (out.some((o) => norm(o.text).slice(0, 120) === norm(s.text).slice(0, 120))) continue;
    out.push(s);
    if (out.length >= TOP) break;
  }
  return out;
}

// ---------------------------------------------------------------------------- run

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }
  const input = JSON.parse(readFileSync(IN, 'utf8'));
  const want = input.rows.filter((r) => r.verdict === VERDICT);
  console.log(`${want.length} ${VERDICT} rows`);

  const topicRows = await pool.query(
    'SELECT id::text, title, short_title, question_text FROM inform.compass_topics WHERE id = ANY($1::uuid[])',
    [[...new Set(want.map((r) => r.tid))]],
  );
  const stanceRows = await pool.query(
    'SELECT topic_id::text AS tid, value, text FROM inform.compass_stances WHERE topic_id = ANY($1::uuid[]) ORDER BY value',
    [[...new Set(want.map((r) => r.tid))]],
  );
  await pool.end();

  const topics = new Map(topicRows.rows.map((t) => [t.id, t]));
  const stances = new Map();
  for (const s of stanceRows.rows) {
    if (!stances.has(s.tid)) stances.set(s.tid, []);
    stances.get(s.tid).push(s);
  }
  const lexicons = new Map();
  for (const [tid, t] of topics) lexicons.set(tid, topicLexicon(t, stances.get(tid) ?? []));

  const sites = new Map();
  for (const r of want) {
    if (!sites.has(r.cited)) sites.set(r.cited, []);
    sites.get(r.cited).push(r);
  }
  console.log(`${sites.size} sites to read`);

  const results = [];
  let done = 0;
  await pooled([...sites.entries()], CONCURRENCY, async ([site, rows]) => {
    let s;
    try { s = await crawlSite(site, CRAWL); }
    catch (e) { s = { ok: false, reason: `crawl threw: ${e.message}`, pages: [] }; }
    const entry = { site, ok: s.ok, why: s.reason, pages: s.pages.map((p) => p.url), rows: [] };
    for (const r of rows) {
      const chairs = stances.get(r.tid) ?? [];
      const chair = chairs.find((c) => Number(c.value) === Math.round(Number(r.value)));
      entry.rows.push({
        pid: r.pid, tid: r.tid, name: r.name, st: r.st, topic: r.topic, value: r.value,
        chair_text: chair?.text ?? null,
        question: topics.get(r.tid)?.question_text ?? null,
        reasoning: r.reasoning,
        // 🔴 evidence is gathered against the TOPIC, never against this row's claim.
        evidence: s.ok ? topicPassages(s.pages, lexicons.get(r.tid) ?? new Set()) : [],
      });
    }
    results.push(entry);
    done += 1;
    if (done % 10 === 0) console.log(`  ${done}/${sites.size} sites`);
  });

  results.sort((a, b) => b.rows.length - a.rows.length || a.site.localeCompare(b.site));
  const noEvidence = results.flatMap((e) => e.rows).filter((r) => !r.evidence.length).length;
  console.log(`\nrows with NO topic passage found on the site: ${noEvidence} — read these first, `
    + 'but note an empty result is a prompt to look, never a verdict.');

  if (OUT) writeFileSync(OUT, `${JSON.stringify({ generated: { rows: want.length, sites: sites.size }, sites: results }, null, 2)}\n`);
  if (MD) { writeFileSync(MD, render(results)); console.log(`written to ${MD}`); }
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });

function render(results) {
  const L = [];
  const total = results.reduce((n, e) => n + e.rows.length, 0);
  L.push('# Characterisation rows — what each cited site says about the topic\n');
  L.push(`${total} rows across ${results.length} sites. Generated by \`scripts/probe-topic-evidence.mjs\`.`);
  L.push('**Nothing here is applied and nothing is proposed.** Each row needs a human read.\n');
  L.push('Passages are found using a lexicon built from the COMPASS TOPIC (its question and all five');
  L.push('chair texts), **not** from the row\'s own wording — so the evidence is independent of the claim.');
  L.push('An empty evidence list means the topic vocabulary did not appear; that is a prompt to look at');
  L.push('the site, **not** a finding that the claim is unsupported.\n');
  for (const e of results) {
    L.push(`\n## ${e.site} — ${e.rows.length} row(s)`);
    if (!e.ok) { L.push(`\n⚠ **site unreadable today: ${e.why}** — says nothing about these rows.\n`); continue; }
    L.push(`pages read: ${e.pages.map((p) => `\`${p}\``).join(' · ')}\n`);
    for (const r of e.rows) {
      L.push(`### ${r.name} — ${r.topic} (${r.st}, chair ${r.value})`);
      if (r.chair_text) L.push(`- **chair ${r.value} means:** ${r.chair_text}`);
      L.push(`- **row says:** ${r.reasoning}`);
      if (!r.evidence.length) L.push('- **topic passages found:** _none_ — read the site before concluding anything');
      for (const ev of r.evidence) {
        L.push(`- **page (${ev.hits} topic terms: ${ev.terms.join(', ')}):** "${ev.text}"`);
        L.push(`  - ${ev.url}`);
      }
      L.push('');
    }
  }
  return `${L.join('\n')}\n`;
}

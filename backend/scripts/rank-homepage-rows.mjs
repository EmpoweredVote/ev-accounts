#!/usr/bin/env node
/**
 * Turn the calibrated signal into a READING ORDER for the PRIMARY_SITE_NO_PATH backlog.
 *
 * The signal was calibrated on the 78 hand-labelled NO_QUOTE rows -- see
 * scripts/calibrate-noquote-signals.mjs for the numbers and for why "the source is a bare campaign
 * homepage" is NOT the signal (it is constant across that whole bucket and orders nothing).
 *
 * What predicts a defect is the REASONING doing work the SOURCE should do: arguing from absence,
 * leaning on party/employer/endorser, leaning on district geography, or hedging. Plus one site-level
 * shape -- several rows cut from a single thin page.
 *
 * 🔴 THESE NUMBERS ARE IN-SAMPLE AND THEREFORE OPTIMISTIC. The patterns below were written AFTER
 * reading the 78 rows they score well on. Working the top of this queue is the out-of-sample test;
 * if the hit rate holds near the calibrated 43-60%, the signal is real. If it collapses, the signal
 * was overfitted and this file should be deleted, not defended.
 *
 * 🔴 AND IT CANNOT SEE FABRICATION. Every severe defect it MISSED was written confidently --
 * Welford's invented 'free healthcare' quotation reads like the best-sourced row in the cohort. A
 * queue built on hedging language will systematically skip the worst failure mode, so this ranks
 * reading order and must never be mistaken for coverage.
 *
 * Usage (from backend/):
 *   node scripts/rank-homepage-rows.mjs --out data/stance-retirement/2026-08-01-homepage-reading-queue.md
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out');

const HEDGE = /\b(implies?|suggests?|strongly implies|would (?:strongly )?favou?r|presumably|likely|appears? to)\b/i;
// "no mention" added after a control row exposed it as a miss: Anderson/Transportation reasons "No
// mention of transit, bike lanes, or pedestrian infrastructure in her platform" and went UNFLAGGED
// into the control sample, where it read as a defect. A false negative in the control silently
// inflates the control's defect rate and makes the signal look worse than it is.
const FROM_ABSENCE = /\b(no mention|no evidence|no documented|not found|no specific|without (?:any )?explicit|does not (?:explicitly )?(?:state|call|mention)|rather than any)\b/i;
const PRIOR = /\b(former Republican|former Democrat|his party|her party|their party|party'?s? (?:platform|majority|position)|Republican majority|Democratic majority|pro-business coalition|endorsed by|worked for|previously worked|aligned with conservative groups?)\b/i;
// ⚠ ANCHOR "strongly pro-" TO A PLACE NOUN. Unanchored it matched "a strongly pro-economic-development
// position" -- a description of the CANDIDATE, which is the row doing its job, not a district prior.
const GEOGRAPHY = /\b(district is|district'?s economy|represents [A-Z]|heart of the|region is|county is|deep(?:ly)? (?:red|blue)|(?:district|county|region|state|area|city)\b[^.]{0,40}\bstrongly pro-)/i;

// NOTE: splitting "argues from absence" into establish-vs-narrow was tried and REJECTED. It is an
// appealing distinction -- using absence to rule out a more extreme chair is ordinary good practice,
// using it to conjure a position is the defect -- but measured against the 78 labels the two halves
// came out 4/5 and 3/5 defective. The data does not support the split at that n, so the combined
// pattern stays until more labels exist. Do not re-split it on the strength of the story alone.

const MARKERS = [
  ['argues from absence', FROM_ABSENCE],
  ['party/employer/endorser', PRIOR],
  ['district/geography', GEOGRAPHY],
  ['hedges', HEDGE],
];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

  // Same shape as the gate's PRIMARY_SITE_NO_PATH bucket: a published row whose every source is a
  // bare host with no path, and which is not one of the aggregator domains the gate handles apart.
  const { rows } = await pool.query(`
    SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid,
           p.first_name || ' ' || p.last_name AS name,
           coalesce(t.short_title, t.title) AS topic,
           pa.value, pc.sources, pc.reasoning
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
      LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
     WHERE pa.value <> 0
       AND pc.sources IS NOT NULL AND array_length(pc.sources, 1) > 0
       AND NOT EXISTS (
             SELECT 1 FROM unnest(pc.sources) s
              WHERE btrim(regexp_replace(btrim(s, '/'), '^https?://(www\\.)?', '')) LIKE '%/%')
       AND NOT EXISTS (
             SELECT 1 FROM unnest(pc.sources) s
              WHERE lower(regexp_replace(btrim(s, '/'), '^https?://(www\\.)?', '')) IN (
                'ballotpedia.org','wikipedia.org','en.wikipedia.org','vote411.org','votesmart.org',
                'ontheissues.org','opensecrets.org','followthemoney.org','govtrack.us',
                'legiscan.com','congress.gov','senate.gov','house.gov','ourcampaigns.com'))`);
  await pool.end();

  // Exclude the 78 already read, so this is genuinely the unread remainder.
  const read = new Set();
  try {
    const q = JSON.parse(readFileSync('data/stance-retirement/2026-08-01-noquote-queue.json', 'utf8'));
    for (const r of q.rows) read.add(`${r.pid}|${r.tid}`);
  } catch { /* fall through — everything counts as unread */ }

  const unread = rows.filter((r) => !read.has(`${r.pid}|${r.tid}`));

  // Site-level shape: several rows cut from one host. (Page count needs a crawl, so host row-count
  // is the fetch-free stand-in for the Kirkland shape.)
  const perHost = new Map();
  const host = (r) => { try { return new URL(r.sources[0]).hostname.replace(/^www\./, ''); } catch { return r.sources[0]; } };
  for (const r of unread) perHost.set(host(r), (perHost.get(host(r)) ?? 0) + 1);

  // 🔴 THE SITE-SHAPE SIGNAL DOES NOT TRANSFER, AND IS DELIBERATELY NOT SCORED.
  // In the labelled cohort the feature was "3+ rows AND the site is ONE PAGE" (1.5x lift), and page
  // count requires a crawl. Bare host row-count is the only fetch-free stand-in, and it flags 327 of
  // 517 unread rows -- 63%. A signal that fires on two thirds of the population is not a ranking, it
  // is a restatement of "candidates have several stances on their own site". Kept as an ANNOTATION
  // so a reader can see it, never as a reason to read a row.
  const scored = unread.map((r) => {
    const hits = MARKERS.filter(([, re]) => re.test(r.reasoning ?? '')).map(([n]) => n);
    return { ...r, hits, many: perHost.get(host(r)) >= 3, score: hits.length };
  }).filter((r) => r.score > 0)
    .sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));

  const flaggedByText = scored.filter((r) => r.hits.length).length;
  console.log(`PRIMARY_SITE_NO_PATH-shaped rows: ${rows.length}  ·  already read: ${rows.length - unread.length}`
    + `  ·  unread: ${unread.length}`);
  console.log(`flagged by at least one signal: ${scored.length}  (${flaggedByText} by a reasoning marker)`);
  const tally = {};
  for (const [n] of MARKERS) tally[n] = scored.filter((r) => r.hits.includes(n)).length;
  tally['3+ rows on one host'] = scored.filter((r) => r.many).length;
  console.log(Object.entries(tally).map(([k, v]) => `  ${k}: ${v}`).join('\n'));

  if (!OUT) return;
  const L = [];
  L.push('# PRIMARY_SITE_NO_PATH — calibrated reading queue\n');
  L.push(`${scored.length} of ${unread.length} unread rows carry at least one risk signal. `
    + 'Generated by `scripts/rank-homepage-rows.mjs`.\n');
  L.push('🔴 **A READING ORDER, NOT A DELETE LIST.** Calibrated in-sample on the 78 rows of the');
  L.push('`NO_QUOTE` review (60% precision / 56% recall for reasoning markers alone; 43% / 75% with');
  L.push('the site-shape signal added) — the patterns were written after reading those rows, so the');
  L.push('real hit rate is whatever the top of this queue turns out to be.\n');
  L.push('⚠ **It cannot see fabrication.** Every severe defect it missed was written confidently.\n');
  for (const s of [4, 3, 2, 1]) {
    const grp = scored.filter((r) => r.score === s);
    if (!grp.length) continue;
    L.push(`\n## ${s} signal${s > 1 ? 's' : ''} — ${grp.length} row(s)\n`);
    for (const r of grp) {
      const tags = [...r.hits, ...(r.many ? [`${perHost.get(host(r))} rows on ${host(r)}`] : [])];
      L.push(`### ${r.name} — ${r.topic} (chair ${r.value})`);
      L.push(`- signals: **${tags.join('** · **')}**`);
      L.push(`- source: ${r.sources.join(' · ')}`);
      L.push(`- reasoning: ${r.reasoning}`);
      L.push('');
    }
  }
  writeFileSync(OUT, `${L.join('\n')}\n`);
  console.log(`\nwritten to ${OUT}`);
})().catch(async (e) => { console.error('FAIL:', e); try { await pool.end(); } catch {} process.exit(2); });

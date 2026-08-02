#!/usr/bin/env node
/**
 * Calibrate candidate risk signals for characterisation rows against the 78 HAND-LABELLED rows of
 * the NO_QUOTE cohort (see data/stance-retirement/2026-08-01-characterisation-review.md).
 *
 * WHY THIS EXISTS, AND WHAT IT REPLACED. The signal this workstream first proposed was "the row's
 * only source is a bare campaign homepage". It cannot be calibrated here and must not be used to
 * rank the backlog:
 *
 *   🔴 ALL 78 LABELLED ROWS ARE BARE HOMEPAGES — 78 of 78, zero variance.
 *
 * That is not a coincidence, it is the definition of the bucket they were drawn from:
 * PRIMARY_SITE_NO_PATH selects rows whose citation has no path. So the feature separates that bucket
 * from the rest of the corpus and orders NOTHING inside it. The original observation (homepage-cited
 * rows drift, instrument-cited rows hold) came from comparing in-cohort rows against SEVEN
 * out-of-cohort rows chosen by hand -- suggestive, but not a sample, and not a control.
 *
 * So this tool asks the question that is actually answerable with the labels in hand: OF THE THINGS
 * THAT VARY WITHIN THE COHORT, WHICH ONE PREDICTS A DEFECT? Every feature below is computable for
 * all 535 PRIMARY_SITE_NO_PATH rows without reading a page, so anything that scores well here can
 * rank the untouched remainder.
 *
 * 🔴 IT RANKS, IT DOES NOT CONVICT. Nine times on this workstream a detector has been corrected and
 * shrunk; the output here is a reading order, never a delete list. A row is a "defect" below only
 * because a human read it and said so.
 *
 * Usage (from backend/):  node scripts/calibrate-noquote-signals.mjs
 */
import { readFileSync } from 'node:fs';

const D = 'data/stance-retirement';
const queue = JSON.parse(readFileSync(`${D}/2026-08-01-noquote-queue.json`, 'utf8'));
const eviJson = JSON.parse(readFileSync(`${D}/2026-08-01-topic-evidence.json`, 'utf8'));
const rollback = JSON.parse(readFileSync(`${D}/2026-08-01-characterisation-remedies-rollback.json`, 'utf8'));

const rows = queue.rows.filter((r) => r.verdict === 'NO_QUOTE');
const key = (p, t) => `${p}|${t}`;

// ---- labels. 25 rows were resolved as non-keep; every other row in the cohort was read and kept.
const remedy = new Map(rollback.rows.map((r) => [key(r.politician_id, r.topic_id), r.remedy]));

// ---- per-row evidence from the topic probe, plus the size of the site actually read.
const evi = new Map();
const siteRowCount = new Map();
for (const s of eviJson.sites) {
  for (const r of s.rows) {
    evi.set(key(r.pid, r.tid), { n: r.evidence.length, pages: s.pages.length, ok: s.ok });
    siteRowCount.set(key(r.pid, r.tid), s.rows.length);
  }
}

// ---------------------------------------------------------------------------- features
//
// Each returns true/false and is computable WITHOUT fetching anything, so it can be applied to the
// whole PRIMARY_SITE_NO_PATH backlog. `reasoning` is the row's own voter-facing text.

const HEDGE = /\b(implies?|suggests?|strongly implies|would (?:strongly )?favou?r|presumably|likely|appears? to)\b/i;
const FROM_ABSENCE = /\b(no evidence|no documented|not found|no specific|without (?:any )?explicit|does not (?:explicitly )?(?:state|call|mention)|rather than any)\b/i;
const PRIOR = /\b(former Republican|former Democrat|his party|her party|their party|party'?s? (?:platform|majority|position)|Republican majority|Democratic majority|pro-business coalition|endorsed by|worked for|previously worked|aligned with conservative groups?)\b/i;
// ⚠ "strongly pro-" alone matched "a strongly pro-economic-development position" -- a description of
// the CANDIDATE, not a district prior. Anchored to a place noun.
const GEOGRAPHY = /\b(district is|district'?s economy|represents [A-Z]|heart of the|region is|county is|deep(?:ly)? (?:red|blue)|(?:district|county|region|state|area|city)\b[^.]{0,40}\bstrongly pro-)/i;
const ABSENCE_ESTABLISH = /\b(no evidence|no documented|not found|no specific|no direct|nothing (?:on|in) the (?:site|page))\b/i;
const ABSENCE_NARROW = /\b(does not (?:explicitly )?(?:state|call|mention)|rather than any|without (?:any )?explicit)\b/i;

const FEATURES = {
  'probe found NO topic passage': (r) => (evi.get(key(r.pid, r.tid))?.n ?? 0) === 0,
  'site is ONE page only': (r) => (evi.get(key(r.pid, r.tid))?.pages ?? 9) === 1,
  'chair is extreme (1 or 5)': (r) => Number(r.value) === 1 || Number(r.value) === 5,
  'reasoning hedges (implies/likely/would favour)': (r) => HEDGE.test(r.reasoning ?? ''),
  'reasoning argues FROM ABSENCE': (r) => FROM_ABSENCE.test(r.reasoning ?? ''),
  // 🔴 THE SPLIT THAT MATTERS. Spot-checking the corpus queue showed "argues from absence" conflates
  // two opposite things:
  //   ESTABLISHING — no evidence exists, therefore the chair. The defect. ("no authored mass
  //     deportation bill found ... aligns with stance 4")
  //   NARROWING   — the candidate does not go as far as a MORE extreme chair, therefore this one.
  //     Correct, ordinary practice. ("he does not call for the government to build all housing, so
  //     this sits at the second chair rather than the most maximalist option")
  // Lumping them punishes good reasoning and buries the bad. Measured separately below.
  'ABSENCE-TO-ESTABLISH (no evidence/not found)': (r) => ABSENCE_ESTABLISH.test(r.reasoning ?? ''),
  'ABSENCE-TO-NARROW (does not call/rather than)': (r) => ABSENCE_NARROW.test(r.reasoning ?? ''),
  'reasoning leans on PARTY / EMPLOYER / ENDORSER': (r) => PRIOR.test(r.reasoning ?? ''),
  'reasoning leans on DISTRICT / GEOGRAPHY': (r) => GEOGRAPHY.test(r.reasoning ?? ''),
  'row quoted our own chair label': (r) => !!r.chair_quoted,
  // Aimed at the Kirkland shape: one thin page asked to support a whole compass. Site-level, so it
  // catches confidently-written rows that no text marker can reach.
  'site carries 3+ rows AND is one page': (r) => {
    const e = evi.get(key(r.pid, r.tid));
    return !!e && e.pages === 1 && (siteRowCount.get(key(r.pid, r.tid)) ?? 0) >= 3;
  },
  'site cited is a bare homepage': (r) => { try { return new URL(r.cited).pathname.replace(/\/$/, '') === ''; } catch { return false; } },
};

// ---------------------------------------------------------------------------- scoring

const isDefect = (r) => remedy.has(key(r.pid, r.tid));
const isSevere = (r) => ['retire', 'chair'].includes(remedy.get(key(r.pid, r.tid)));

function score(rows, feat, target) {
  const withF = rows.filter(feat);
  const without = rows.filter((r) => !feat(r));
  const dW = withF.filter(target).length;
  const dO = without.filter(target).length;
  return {
    n: withF.length,
    hits: dW,
    rate: withF.length ? dW / withF.length : 0,
    nOut: without.length,
    rateOut: without.length ? dO / without.length : 0,
    recall: dW + dO ? dW / (dW + dO) : 0,
  };
}

function table(title, target) {
  const base = rows.filter(target).length / rows.length;
  console.log(`\n${title}`);
  console.log(`base rate: ${(base * 100).toFixed(1)}%  (${rows.filter(target).length}/${rows.length})\n`);
  console.log('  feature                                          n   flagged  rate    rest    lift  recall');
  console.log('  '.padEnd(2) + '-'.repeat(94));
  const scored = Object.entries(FEATURES)
    .map(([name, f]) => [name, score(rows, f, target)])
    .sort((a, b) => b[1].rate - a[1].rate);
  for (const [name, s] of scored) {
    const lift = s.rateOut > 0 ? (s.rate / s.rateOut).toFixed(1) + 'x' : (s.rate > 0 ? 'inf' : '—');
    const flag = s.n === 0 ? '  (no variance — untestable)'
      : s.n === rows.length ? '  🔴 CONSTANT — untestable, orders nothing'
        : s.n < 6 ? '  ⚠ n too small' : '';
    console.log(`  ${name.padEnd(46)} ${String(s.n).padStart(3)}  ${String(s.hits).padStart(6)}`
      + `  ${(s.rate * 100).toFixed(0).padStart(4)}%  ${(s.rateOut * 100).toFixed(0).padStart(4)}%`
      + `  ${String(lift).padStart(5)}  ${(s.recall * 100).toFixed(0).padStart(4)}%${flag}`);
  }
}

console.log(`NO_QUOTE calibration — ${rows.length} hand-labelled rows`);
console.log(`labels: ${rows.filter(isDefect).length} defect (13 retire · 3 chair · 9 reasoning), `
  + `${rows.length - rows.filter(isDefect).length} keep`);

table('=== TARGET: any defect (row needed ANY change) ===', isDefect);
table('=== TARGET: severe only (voter saw a WRONG CHAIR: retire + chair) ===', isSevere);

// ---------------------------------------------------------------------------- combinations
console.log('\n=== combining the two best absence-shaped signals ===\n');
const noPassage = FEATURES['probe found NO topic passage'];
const onePage = FEATURES['site is ONE page only'];
const fromAbsence = FEATURES['reasoning argues FROM ABSENCE'];
const hedge = FEATURES['reasoning hedges (implies/likely/would favour)'];
const prior = FEATURES['reasoning leans on PARTY / EMPLOYER / ENDORSER'];
const geo = FEATURES['reasoning leans on DISTRICT / GEOGRAPHY'];

// 🔴 THE CANDIDATE. Not a grab-bag: all four markers are the same tell in different clothes -- the
// REASONING is carrying the weight the SOURCE should carry. That is the thing every defect in this
// cohort had in common, and it is why site shape (page count, chair value) does not predict.
const unsourcedInference = (r) => fromAbsence(r) || prior(r) || geo(r) || hedge(r);
const thinSiteManyRows = FEATURES["site carries 3+ rows AND is one page"];

const combos = {
  'no topic passage OR one-page site': (r) => noPassage(r) || onePage(r),
  'no topic passage AND one-page site': (r) => noPassage(r) && onePage(r),
  'one-page site OR argues from absence': (r) => onePage(r) || fromAbsence(r),
  'UNSOURCED INFERENCE or thin-site-many-rows': (r) => unsourcedInference(r) || thinSiteManyRows(r),
  'UNSOURCED INFERENCE (absence|prior|geo|hedge)': unsourcedInference,
};
console.log('  combination                                      n   flagged  rate    rest    lift  recall');
console.log('  ' + '-'.repeat(94));
for (const [name, f] of Object.entries(combos)) {
  const s = score(rows, f, isSevere);
  const lift = s.rateOut > 0 ? (s.rate / s.rateOut).toFixed(1) + 'x' : (s.rate > 0 ? 'inf' : '—');
  console.log(`  ${name.padEnd(46)} ${String(s.n).padStart(3)}  ${String(s.hits).padStart(6)}`
    + `  ${(s.rate * 100).toFixed(0).padStart(4)}%  ${(s.rateOut * 100).toFixed(0).padStart(4)}%`
    + `  ${String(lift).padStart(5)}  ${(s.recall * 100).toFixed(0).padStart(4)}%   (severe target)`);
}

// ---------------------------------------------------------------------------- misses
// What a signal MISSES matters more than what it catches: a reading order that systematically skips
// a whole failure mode is worse than no order at all, because it looks like coverage.
console.log('\n=== severe defects MISSED by UNSOURCED INFERENCE ===\n');
const best = combos["UNSOURCED INFERENCE (absence|prior|geo|hedge)"];
for (const r of rows.filter((x) => isSevere(x) && !best(x))) {
  console.log(`  ${r.name} / ${r.topic} (${r.st}, chair ${r.value}) — ${remedy.get(key(r.pid, r.tid))}`);
}

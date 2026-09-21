#!/usr/bin/env node
/**
 * INSTRUMENT-TOPIC DETECTOR — "is the bill this row cites actually about this row's topic?"
 *
 * 🔑 WHY IT EXISTS. On 2026-09-20 the Texas immigration cohort was found seating Deportation
 * Priorities chairs 4 and 5 on SB 17 (foreign nationals buying real PROPERTY) and SB 16 (proof of
 * citizenship to REGISTER TO VOTE). Neither is a removal instrument. The borrowed-ladder probe
 * (ladder-language-probe.mjs) found three of them only by accident, because one bill
 * description happened to reproduce another ladder's wording. This asks the question directly.
 *
 * 🔴 TITLES AND RUNG TEXT COME FROM compass_topic_revisions / compass_stance_revisions ONLY, and each
 * context row's title from ITS OWN topic_revision_id. The equivalent columns on the pre-versioning
 * tables stopped being maintained at CA_0012 (ADR 0004): on 2026-09-08, 29 of the 60 topics in the
 * open season disagreed with their season pin, 16 of them on all five rungs. Reading the stale copy
 * returns a complete, plausible ladder on the right subject, so it fails silently — which is exactly
 * the failure mode this detector exists to catch. Reading via topic_revision_id is also simply more
 * correct here: a row has to be judged against the ladder it was actually written against.
 * Enforced by scripts/check-ladder-text-reads.mjs.
 *
 * METHOD — the corpus is its own dictionary.
 *   1. Every time a row cites a bill it usually describes it in the same breath:
 *        "SB 17 (89th) banning certain foreign nationals from purchasing real property"
 *      Harvest those descriptions corpus-wide, keyed by bill AND SESSION (a bare bill number is not
 *      an identity — TX SB 4 is the sanctuary-city ban in the 85th and illegal-entry in the 88th).
 *   2. Build a document per topic from its title plus every rung text across every revision, and an
 *      IDF over those documents. Ladder prose is highly distinctive, so this discriminates well.
 *   3. Score each bill's pooled description against every topic. The argmax is what the CORPUS
 *      thinks the bill is about — independent of where any single row filed it.
 *   4. Flag a row when the bill's own description points at a different topic by a clear margin.
 *   5. Separately flag bills whose descriptions DISAGREE WITH EACH OTHER (this is how HB 17 was
 *      caught being called "property restrictions" 29 times and "ICE enforcement" 12 times).
 *
 * ⚠ THIS IS A READING QUEUE, NOT A VERDICT. Every first cut in this workstream over-fires. Adjacent
 * topics legitimately share vocabulary, and one bill can genuinely bear on two topics. Ranked by
 * margin so the top of the list is worth a human's time first.
 *
 *   node scripts/instrument-topic-affinity.mjs --out out.json [--min-cites 3] [--margin 0.25]
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', null);
const MIN_CITES = Number(flag('--min-cites', 3));
const MARGIN = Number(flag('--margin', 0.25));

// Skips itself (exit 0) when DATABASE_URL is absent, so forks get a green skip rather than a red
// build they cannot fix — same contract as the other live-DB checks in ci.yml.
const cs = process.env.DATABASE_URL;
if (!cs) { console.log('DATABASE_URL absent — skipping instrument-topic self-test.'); process.exit(0); }
const pool = new pg.Pool({ connectionString: cs, ssl: { rejectUnauthorized: false } });

const { rows: rungs } = await pool.query(`
  SELECT r.topic_id, r.title, sr.text
  FROM inform.compass_stance_revisions sr
  JOIN inform.compass_topic_revisions r ON r.id = sr.topic_revision_id`);

const { rows: ctx } = await pool.query(`
  SELECT c.politician_id, c.topic_id, c.season_id, s.name AS season, tr.title AS topic,
         p.full_name, c.reasoning, c.sources, a.value::int AS chair
  FROM inform.politician_context c
  JOIN inform.compass_topic_revisions tr ON tr.id = c.topic_revision_id
  JOIN inform.seasons s ON s.id = c.season_id
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.politician_answers a
    ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id AND a.season_id=c.season_id
  WHERE c.reasoning IS NOT NULL`);
await pool.end();

// ---------- topic documents + IDF -------------------------------------------------
const STOP = new Set(('the a an and or of to in on for with without by at as is are be been it its this that those these ' +
  'be or not no any all more most less least than then so such other same only own very can will would should could may ' +
  'must new any each every both few many much other some one two three four five').split(' '));
const toks = (s) => s.toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').split(/\s+/).filter((w) => w.length > 3 && !STOP.has(w));

// 🔴🔴 A LADDER IS THE WRONG DICTIONARY, AND THIS COST A WHOLE BUILD. The first version modelled a
// topic as the bag of words in its five rungs. Rungs describe POSITIONS on an axis in abstract
// language; bill descriptions are CONCRETE. "MaineCare", "sheriffs", "nationals", "abortion" appear
// in no rung text at all, so scoring was decided by survivors like "from", "requiring", "services"
// and an abortion-funding bill classified as "Data Center Development & Energy Costs".
// Fix: learn each topic's vocabulary from the REASONING CORPUS of rows filed under it — thousands of
// concrete sentences — with proper tf-idf. Rung text is folded in but cannot dominate.
// ⚠ Residual circularity, stated so it is not forgotten: a wholly misfiled cohort teaches its wrong
// topic its own vocabulary (LD 427's 82 rows would have taught Residential Zoning some transport
// words). 82 rows against thousands dilutes it, and the per-row test below is leave-one-topic-out,
// but this detector is weakest exactly where a misfile is LARGE and UNIFORM.
const topicDoc = new Map();   // topic_id -> {title, tf:Map}
const bump = (tid, title, w, n = 1) => {
  if (!topicDoc.has(tid)) topicDoc.set(tid, { title, tf: new Map() });
  const tf = topicDoc.get(tid).tf;
  tf.set(w, (tf.get(w) || 0) + n);
};
for (const r of rungs) for (const w of toks(`${r.text} ${r.title}`)) bump(r.topic_id, r.title, w, 3);
for (const row of ctx) for (const w of toks(row.reasoning)) bump(row.topic_id, row.topic, w, 1);

const N = topicDoc.size;
const df = new Map();
for (const { tf } of topicDoc.values()) for (const w of tf.keys()) df.set(w, (df.get(w) || 0) + 1);
const idf = (w) => Math.log((N + 1) / (1 + (df.get(w) || 0)));

// per-topic L2 norm over tf-idf, so a wordy topic cannot win on volume
const norms = new Map();
for (const [tid, { tf }] of topicDoc) {
  let s = 0;
  for (const [w, n] of tf) { const v = (1 + Math.log(n)) * idf(w); s += v * v; }
  norms.set(tid, Math.sqrt(s) || 1);
}

const scoreAgainstTopics = (text) => {
  const ws = [...new Set(toks(text))].filter((w) => (df.get(w) || 0) > 0 && (df.get(w) || 0) < N * 0.6);
  let qn = 0;
  for (const w of ws) qn += idf(w) * idf(w);
  qn = Math.sqrt(qn) || 1;
  const out = [];
  for (const [tid, { tf }] of topicDoc) {
    let s = 0;
    for (const w of ws) {
      const n = tf.get(w);
      if (n) s += idf(w) * (1 + Math.log(n)) * idf(w);
    }
    out.push([tid, s / (qn * norms.get(tid))]);
  }
  out.sort((a, b) => b[1] - a[1]);
  return out;
};

// ---------- SELF-TEST: the scorer must classify known instruments before it is trusted ----------
// 🔑 A detector that has not been shown to work on a string whose answer you already know is not a
// detector. The first build of this file failed every one of these and still printed 376 findings.
const SELFTEST = [
  ['barring the MaineCare program from covering abortion services', ['Reproductive Rights and Abortion Access']],
  ['requiring proof of citizenship to register to vote', ['Voting Rights and Electoral Integrity']],
  // the three immigration ladders are near-synonymous in vocabulary; any of them is a correct family
  ['requiring sheriffs to sign ICE cooperation agreements',
    ['Local Immigration Enforcement', 'Deportation Priorities', 'Immigration and Treatment of Immigrants']],
  // 🔴 KNOWN LIMITATION, kept as a standing demonstration — see the note below. Expected to FAIL.
  ['eliminating mandatory parking space minimums in municipal building codes', ['Transportation Priorities'], 'KNOWN-FAIL'],
];
let passed = 0, checked = 0;
console.log('SELF-TEST');
for (const [text, expect, known] of SELFTEST) {
  const top = scoreAgainstTopics(text).slice(0, 3);
  const got = topicDoc.get(top[0][0]).title;
  const ok = expect.includes(got);
  if (!known) { checked++; if (ok) passed++; }
  console.log(`  ${known ? (ok ? '⚠ known-fail now PASSES' : '⚠ known-fail') : ok ? '✅' : '❌'} "${text.slice(0, 52)}…"`);
  console.log(`      → ${top.map(([tid, s]) => `${topicDoc.get(tid).title} ${s.toFixed(3)}`).join('  |  ')}`);
}
console.log(`  ${passed}/${checked} known instruments classified correctly\n`);
console.log(`🔴 THE KNOWN-FAIL IS THE POINT, NOT A BUG TO TUNE AWAY. "Parking minimums" classifies as
   Residential Zoning because the 82 misfiled LD 427 rows TAUGHT that topic the vocabulary. A corpus-
   consensus detector cannot find a LARGE, UNIFORM misfile: the misfile becomes its training data.
   Use it for SMALL misfiles. For large uniform ones use ladder-language-probe.mjs, whose
   ground truth is ladder text written independently of the corpus. The two are complementary.\n`);
if (argv.includes('--selftest')) process.exit(passed === checked ? 0 : 1);
if (passed < checked) {
  console.error('🔴 SELF-TEST FAILED — refusing to emit findings from a scorer that cannot classify known bills.');
  console.error('   Re-run with --force to see the output anyway.');
  if (!argv.includes('--force')) process.exit(1);
}

// ---------- harvest bill descriptions ---------------------------------------------
// 🔴 THE DESCRIPTION WINDOW IS THE WHOLE DIFFICULTY. A naive "text after the bill number" swallows
// the row's own argument about its own topic, so the bill inherits the topic of whoever cited it and
// the detector becomes circular. Take only APPOSITIVE description -- a parenthetical, or a relative
// clause introduced by which/that/requiring/banning/prohibiting/establishing/creating/allowing --
// and stop at the first clause break.
const BILL = /\b(HB|SB|HJR|SJR|HCR|SCR|AB|LD|HR|SR)\s*\.?\s*(\d{1,4})\b/gi;
const APPOS = /^\s*(?:\(([^)]{10,140})\)|,?\s*(?:which|that)\s+([^.;]{10,140})|,\s*(?:the\s+)?((?:requiring|banning|prohibiting|establishing|creating|allowing|repealing|eliminating|expanding|restricting|mandating|authorizing|directing)[^.;]{8,140}))/i;
// session: an explicit LegSess, or an ordinal legislature, or a 4-digit year that is NOT the bill number
const SESS_SRC = /LegSess=(\d{2,3}[A-Z0-9]*)/i;
const SESS_ORD = /\b(\d{1,3})(?:st|nd|rd|th)\s+(?:Leg|Legislature|Session)/i;
const SESS_YEAR = /\((?:[^)]*?\b)?(20[0-2]\d)\b/;

const billDesc = new Map();   // key -> {num, sess, descs:[{text,topic_id}], rows:[]}
for (const row of ctx) {
  const hay = row.reasoning;
  const srcs = (row.sources || []).join(' ');
  let m; BILL.lastIndex = 0;
  const seen = new Set();
  while ((m = BILL.exec(hay))) {
    const num = `${m[1].toUpperCase()} ${m[2]}`;
    const after = hay.slice(m.index + m[0].length, m.index + m[0].length + 200);
    const ap = after.match(APPOS);
    const desc = ap ? (ap[1] || ap[2] || ap[3] || '').trim() : null;

    const sm = srcs.match(SESS_SRC) || after.match(SESS_ORD) || after.match(SESS_YEAR);
    let sess = sm ? sm[1] : '?';
    if (sess === m[2]) sess = '?';           // the bill number is not a session
    const key = `${num}@${sess}`;
    if (seen.has(key)) continue;
    seen.add(key);
    if (!billDesc.has(key)) billDesc.set(key, { key, num, sess, descs: [], rows: [] });
    const e = billDesc.get(key);
    // ⚠ a parenthetical is often a CITATION, not a description: "(House Roll Call #534, 6/16/2025)",
    // "(89th Leg., 2025)". Those carry no subject matter and poison both the affinity score and the
    // disagreement test. Require real words and reject citation-shaped text.
    const isCitation = /roll\s*call|^\s*\d|\bleg\.?\b|\bsess|\bchapter\b|\bch\.\s*\d|signed into law|^\W*\d{1,3}(st|nd|rd|th)/i.test(desc || '')
      && toks(desc || '').length < 6;
    const contentWords = toks(desc || '').filter((w) => (df.get(w) || 0) < N * 0.6).length;
    if (desc && desc.length > 12 && !isCitation && contentWords >= 3) {
      e.descs.push({ text: desc, topic_id: row.topic_id });
    }
    e.rows.push(row);
  }
}
console.log(`${ctx.length} context rows; ${billDesc.size} distinct bill@session keys`);

// ---------- what does the corpus think each bill is about? ------------------------
const findings = [];
const disagreements = [];
for (const e of billDesc.values()) {
  if (e.rows.length < MIN_CITES || e.descs.length === 0) continue;

  // internal disagreement: do independently-written descriptions of the SAME bill argmax differently?
  const votes = new Map();
  for (const d of e.descs) {
    const t = scoreAgainstTopics(d.text)[0];
    if (t[1] <= 0) continue;
    votes.set(t[0], (votes.get(t[0]) || 0) + 1);
  }
  if (votes.size > 1) {
    const sorted = [...votes].sort((a, b) => b[1] - a[1]);
    const [t1, n1] = sorted[0], [t2, n2] = sorted[1];
    if (n2 >= 2 && n2 / n1 >= 0.34) {
      disagreements.push({ bill: e.key, cites: e.rows.length, descs: e.descs.length,
        a: `${topicDoc.get(t1).title} (${n1})`, b: `${topicDoc.get(t2).title} (${n2})`,
        sample_a: e.descs.find((d) => scoreAgainstTopics(d.text)[0][0] === t1)?.text.slice(0, 90),
        sample_b: e.descs.find((d) => scoreAgainstTopics(d.text)[0][0] === t2)?.text.slice(0, 90) });
    }
  }

  // 🔑 LEAVE-ONE-TOPIC-OUT. To judge whether bill B belongs to topic T, pool ONLY the descriptions
  // of B written by rows filed under a topic OTHER than T. Otherwise the bill is defined by the very
  // rows under test and the detector agrees with itself.
  for (const row of e.rows) {
    const outside = e.descs.filter((d) => d.topic_id !== row.topic_id);
    if (outside.length < 2) continue;                    // not enough independent evidence to judge
    const ranked = scoreAgainstTopics(outside.map((d) => d.text).join(' . '));
    const [bestTid, bestScore] = ranked[0];
    if (bestScore <= 0) continue;
    const filedEntry = ranked.find(([tid]) => tid === row.topic_id);
    const filedScore = filedEntry ? filedEntry[1] : 0;
    const margin = bestScore - filedScore;
    if (bestTid !== row.topic_id && margin >= MARGIN) {
      findings.push({
        bill: e.key, cites: e.rows.length, independent_descs: outside.length,
        margin: +margin.toFixed(3),
        full_name: row.full_name, season: row.season, chair: row.chair,
        filed_under: row.topic, bill_reads_as: topicDoc.get(bestTid).title,
        desc: outside[0].text.slice(0, 110),
        politician_id: row.politician_id, topic_id: row.topic_id,
      });
    }
  }
}

findings.sort((a, b) => b.margin - a.margin);
console.log(`\n${findings.length} rows where the cited bill reads as a DIFFERENT topic (margin >= ${MARGIN})`);

const pairs = new Map();
for (const f of findings) {
  const k = `${f.filed_under}  <-  bill reads as: ${f.bill_reads_as}`;
  if (!pairs.has(k)) pairs.set(k, []);
  pairs.get(k).push(f);
}
console.log('\nBY PAIR:');
for (const [k, v] of [...pairs].sort((a, b) => b[1].length - a[1].length).slice(0, 20)) {
  const bills = [...new Set(v.map((x) => x.bill))].slice(0, 4).join(', ');
  console.log(`  ${String(v.length).padStart(4)}  ${k}   [${bills}]`);
}

console.log(`\n${disagreements.length} bills the corpus DESCRIBES INCONSISTENTLY:`);
for (const d of disagreements.sort((a, b) => b.cites - a.cites).slice(0, 12)) {
  console.log(`  ${d.bill} (${d.cites} cites, ${d.descs} descriptions): ${d.a}  vs  ${d.b}`);
  console.log(`      A: "${d.sample_a}"`);
  console.log(`      B: "${d.sample_b}"`);
}

if (OUT) fs.writeFileSync(OUT, JSON.stringify({ findings, disagreements }, null, 1));

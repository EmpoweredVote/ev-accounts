#!/usr/bin/env node
/**
 * Find rows where the stored CHAIR is the opposite pole from the row's own REASONING.
 *
 * 🔴 THE DEFECT. On Civil Rights, chair 5 reads "eliminate affirmative action and all race-based
 * government programs" — yet Alonzo Washington's row reads "As an African American senator in PG
 * County, he prioritizes racial justice" AT CHAIR 5. The compass dot and the "Why this position?"
 * text then say opposite things about the same person. This is not a sourcing fault; it is a wrong
 * voter-facing position.
 *
 * 🔑 THE HARD PART IS POLARITY, AND IT MUST NOT BE ASSUMED. Chairs are 1-5 discrete options, NOT a
 * left-right axis, and the direction is topic-specific: on Fossil Fuel Policy the RESTRICTIVE chair
 * is the pro-climate one, so any "expansive = chair 1" lexicon inverts. Hand-asserting a direction
 * per topic is exactly how a detector manufactures findings.
 *
 * 🔑 SO LET THE CORPUS DEFINE IT. For each topic, measure how PRO- and ANTI-worded reasoning
 * distributes across the five chairs. With hundreds of rows per topic the majority pattern IS the
 * polarity, and the inversions are the minority that break it. A topic whose pattern is weak or
 * non-monotonic is reported UNCALIBRATED and no row in it is flagged.
 *
 * 🔴 Reads only. Emits a reading queue. Every flag must be read before anything is changed.
 *   node scripts/chair-inversion-scan.mjs --out <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-chair-inversion-scan.json');

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: stances } = await pool.query(
  `SELECT t.id AS topic_id, t.title, s.value, s.text
   FROM inform.compass_stances s JOIN inform.compass_topics t ON t.id = s.topic_id ORDER BY t.title, s.value`);
const { rows } = await pool.query(
  `SELECT c.politician_id, c.topic_id, t.title AS topic, a.value, c.reasoning, c.sources, p.full_name
   FROM inform.politician_context c
   JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
   JOIN essentials.politicians p ON p.id=c.politician_id
   JOIN inform.compass_topics t ON t.id=c.topic_id
   WHERE c.reasoning IS NOT NULL AND length(c.reasoning) > 20`);
await pool.end();
console.log(`rows with a chair and reasoning: ${rows.length}`);

/**
 * Polarity of the REASONING, measured only from how the politician is said to relate to the topic —
 * never from the topic's own vocabulary, which carries no direction.
 * ⚠ Negations are handled explicitly: "has not supported" is ANTI, not PRO.
 */
const PRO = /\b(supports?|supported|supporting|champions?|championed|backs?|backed|advocat\w*|co-?sponsored|sponsored|voted (for|yes|in favour|in favor)|led efforts|has been a (strong |vocal |leading )?(supporter|advocate|champion)|prioriti[sz]es)\b/i;
const ANTI = /\b(oppos\w+|voted against|against expansions?|rejects?|rejected|has not (supported|advocated|co-?sponsored|backed)|no evidence of support|resisted|blocked|sought to (limit|restrict|repeal)|limiting|restricting|would (eliminate|repeal))\b/i;
const polarity = (t) => {
  const p = PRO.test(t), a = ANTI.test(t);
  // "has not supported" matches both; ANTI wins because the negation is the operative word.
  if (a) return 'ANTI';
  if (p) return 'PRO';
  return null;
};

/**
 * 🔴 THE FIRST CUT FIRED ON 1,442 ROWS — 4.4% OF THE CORPUS — AND WAS MOSTLY NOISE, because a verb
 * has an OBJECT and the regex cannot see it:
 *   · "co-sponsored a resolution OPPOSING Senate Bill 590" is a PRO civil-rights act, scored ANTI.
 *   · "voted AGAINST the GOP budget that would cut Medicaid" is PRO healthcare, scored ANTI.
 *   · "cosponsored legislation to BLOCK DEI programs" is ANTI civil-rights, scored PRO.
 *   · "supports LIMITED government-funded healthcare" is ANTI, scored PRO.
 * Opposition language flips meaning with whatever is being opposed, in both directions.
 *
 * 🔑 SO MATCH ON WHAT DISTINGUISHES THE REAL DEFECT. The confirmed inversions read as wholly and
 * unambiguously supportive with NO oppositional or restrictive word anywhere: "consistently
 * supported civil rights legislation including racial equity measures, LGBTQ protections, and
 * anti-discrimination laws … he prioritizes racial justice" — sitting at chair 5, "eliminate
 * affirmative action". A single restrictive marker anywhere in the sentence disqualifies the row
 * from this test, because then the direction depends on an object this cannot read.
 */
const RESTRICTIVE_ANYWHERE = /\b(against|oppos\w*|block\w*|roll ?back|rolled back|repeal\w*|defund\w*|rescind\w*|cut\w*|restrict\w*|limit\w*|prohibit\w*|\bban\w*|reduc\w*|eliminat\w*|den(y|ied|ying)|reject\w*|overturn\w*|strike down|struck down|work requirement|crack ?down|curb\w*|tighten\w*|not\b|never\b|no\b|without\b|declin\w*|resist\w*|skeptic\w*|doubt\w*)/i;
const cleanPro = (t) => PRO.test(t) && !RESTRICTIVE_ANYWHERE.test(t);

// ── calibrate each topic from its own rows ────────────────────────────────────────────────────
const byTopic = {};
for (const r of rows) (byTopic[r.topic_id] ||= { topic: r.topic, rows: [] }).rows.push(r);

const report = [];
for (const [tid, g] of Object.entries(byTopic)) {
  const dist = {};
  for (const r of g.rows) {
    const v = Number(r.value); const pol = polarity(r.reasoning);
    if (!pol) continue;
    (dist[v] ||= { PRO: 0, ANTI: 0 })[pol]++;
  }
  const vals = Object.keys(dist).map(Number).sort((a, b) => a - b);
  const share = {};
  for (const v of vals) { const d = dist[v]; const n = d.PRO + d.ANTI; share[v] = n >= 8 ? d.PRO / n : null; }
  const usable = vals.filter((v) => share[v] !== null);
  // Polarity is the sign of the correlation between chair value and PRO-share.
  let dir = null, strength = 0;
  if (usable.length >= 3) {
    const lo = usable.slice(0, Math.ceil(usable.length / 2));
    const hi = usable.slice(Math.floor(usable.length / 2));
    const avg = (a) => a.reduce((s, v) => s + share[v], 0) / a.length;
    const d = avg(lo) - avg(hi);
    strength = Math.abs(d);
    // strong, consistent gap required — a weak gap means the topic is UNCALIBRATED
    if (strength >= 0.35) dir = d > 0 ? 'LOW_IS_PRO' : 'HIGH_IS_PRO';
  }
  report.push({ topic_id: tid, topic: g.topic, n: g.rows.length, dist, share, dir, strength: +strength.toFixed(2) });
}
report.sort((a, b) => b.n - a.n);

console.log('\nPER-TOPIC CALIBRATION (PRO-share by chair; direction inferred from the corpus itself)');
console.log('topic'.padEnd(48) + 'n     ' + [1, 2, 3, 4, 5].map((v) => `c${v}`.padStart(6)).join('') + '   dir');
for (const t of report) {
  const cells = [1, 2, 3, 4, 5].map((v) => (t.share[v] == null ? '   -  ' : t.share[v].toFixed(2).padStart(6))).join('');
  console.log(t.topic.slice(0, 47).padEnd(48) + String(t.n).padEnd(6) + cells + '   ' + (t.dir || `UNCALIBRATED(${t.strength})`));
}

// ── flag rows that break their topic's calibrated polarity ────────────────────────────────────
const flags = [];
for (const t of report) {
  if (!t.dir) continue;
  const proEnd = t.dir === 'LOW_IS_PRO' ? [1, 2] : [4, 5];
  const antiEnd = t.dir === 'LOW_IS_PRO' ? [4, 5] : [1, 2];
  for (const r of byTopic[t.topic_id].rows) {
    const v = Number(r.value);
    // Only the unambiguous direction is tested: wholly supportive wording at the ANTI pole.
    if (!antiEnd.includes(v) || !cleanPro(r.reasoning)) continue;
    flags.push({ ...r, value: v, reasoning_polarity: 'CLEAN_PRO', topic_dir: t.dir,
      chair_text: stances.find((s) => s.topic_id === r.topic_id && s.value === v)?.text });
  }
}
console.log(`\nFLAGGED: ${flags.length} row(s) across ${new Set(flags.map((f) => f.topic)).size} topic(s)`);
const byT = {};
for (const f of flags) (byT[f.topic] ||= []).push(f);
for (const [k, v] of Object.entries(byT).sort((a, b) => b[1].length - a[1].length)) console.log(`  ${String(v.length).padStart(4)}  ${k}`);

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'chair vs reasoning polarity — corpus-calibrated',
  caveat: 'A READING QUEUE. Polarity is inferred per topic from the corpus majority; topics with a '
        + 'weak or inconsistent pattern are UNCALIBRATED and contribute no flags. Every flag must be '
        + 'read: "supported removing the Confederate emblem" is PRO-worded on a correctly ANTI row.',
  calibration: report, n_flags: flags.length, flags,
}, null, 1));
console.log(`\nwrote ${OUT}`);

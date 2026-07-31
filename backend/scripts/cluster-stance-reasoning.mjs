#!/usr/bin/env node
/**
 * Template clustering for compass stance `reasoning` — a FETCH-FREE fabrication detector.
 *
 * WHY THIS EXISTS. The stance re-sourcing backlog has one cheap signal and several expensive ones.
 * The expensive ones need a serial fetch of every cited page at ~1.3s (Ballotpedia rate-limits, and
 * it does so SILENTLY — see .planning/todos/2026-07-30-stance-resourcing-backlog.md). This one needs
 * no network at all: if seven different people carry a byte-identical sentence about their voting
 * record, that sentence was generated from a template rather than read off a source. It found exactly
 * that during the A1 Oregon audit ("Supported civil rights and anti-discrimination measures;
 * consistent progressive voting record from Portland district." x7) and has now been re-derived by
 * hand twice, which is the reason it is a committed script instead of a third ad-hoc run.
 *
 * 🔴 A CLUSTER IS NOT A VERDICT. It is evidence about how a row was PRODUCED, not proof that its
 * citation fails. A real shared position can produce similar prose — "voted for the bipartisan
 * infrastructure package" is true of many members at once. So this script ranks rows for scrutiny and
 * never proposes a deletion. Retirement still requires the article-body test on the cited page.
 *
 * 🔴 RUN IT GLOBALLY, NOT PER COHORT. The backlog doc originally said "run first on each of A2-A6".
 * That is weaker than it looks: the Portland skeleton spanned seven politicians, so a skeleton shared
 * between an Oregon row and a Virginia row is entirely plausible and a per-cohort run cannot see it by
 * construction. Default scope here is therefore every live answer in the cohort at once, and --all
 * widens it to all 33k answers in prod.
 *
 * THREE TIERS, WEAKEST LAST.
 *   IDENTICAL — same reasoning string, ≥2 distinct politicians. Strongest; needs no interpretation.
 *   SKELETON  — same string after proper nouns, bill numbers and digits are removed. This is what
 *               catches a template whose blanks were filled with different names and districts.
 *   NEAR      — trigram Jaccard ≥ threshold on the skeleton. Catches light paraphrase.
 *
 * Proper-noun stripping deliberately removes EVERY capitalised token including sentence-initial ones.
 * That destroys some signal, but it does so identically on both sides of every comparison, which is
 * what matters. Trying to spare sentence openers means the same template scores as two skeletons
 * depending on which clause it starts with.
 *
 * A CROSS-TOPIC cluster is worse than a same-topic one. Two members sharing a Healthcare sentence
 * might share a position; one sentence doing duty for Healthcare AND Immigration is a template with
 * the subject swapped. Reported separately for that reason.
 *
 * Usage (from backend/):
 *   node scripts/cluster-stance-reasoning.mjs                      # the 596-row Ballotpedia-only cohort
 *   node scripts/cluster-stance-reasoning.mjs --all                # every live answer with context
 *   node scripts/cluster-stance-reasoning.mjs --near 0.8           # loosen the paraphrase threshold
 *   node scripts/cluster-stance-reasoning.mjs --min-len 40         # ignore very short reasoning
 *   node scripts/cluster-stance-reasoning.mjs --out data/x.json    # write the full report
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { Pool } from 'pg';

const argv = process.argv.slice(2);
const ALL = argv.includes('--all');
const flag = (name, dflt) => {
  const i = argv.indexOf(name);
  return i > -1 ? argv[i + 1] : dflt;
};
const NEAR = parseFloat(flag('--near', '0.85'));
const MIN_LEN = parseInt(flag('--min-len', '25'), 10);
const OUT = flag('--out', null);

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

/**
 * The cohort predicate. `sources` citing nothing but Ballotpedia is the backlog's Workstream A
 * definition; it is also the predicate the CI guard enforces going forward, so the two agree by
 * construction rather than by comment.
 */
const BALLOTPEDIA_ONLY = `
  cardinality(pc.sources) > 0
  AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT ILIKE '%ballotpedia%')`;

/**
 * Visibility is NOT occupancy. compassService surfaces answers for non-incumbent ACTIVE candidates in
 * any upcoming race with no office required, so a politician holding no seat can still be on a live
 * candidate card. Measured 2026-07-31: 422 of the cohort's 443 not-seated answers are visible this
 * way. Ranking a cohort as invisible because it holds no office is how that got missed the first time.
 */
const QUERY = `
  SELECT
    pa.politician_id,
    pa.topic_id,
    pa.value,
    trim(pc.reasoning)                      AS reasoning,
    pc.sources,
    p.first_name || ' ' || p.last_name      AS name,
    coalesce(t.short_title, t.title)        AS topic,
    lower(coalesce(d.state, o.representing_state, '')) AS st,
    coalesce(o.title, '')                   AS office_title,
    (och.politician_id IS NOT NULL)         AS seated,
    EXISTS (
      SELECT 1 FROM essentials.race_candidates rc
      JOIN essentials.races r  ON r.id = rc.race_id
      JOIN essentials.elections e ON e.id = r.election_id
      WHERE rc.politician_id = pa.politician_id
        AND rc.candidate_status = 'active'
        AND rc.is_incumbent = false
        AND e.election_date >= CURRENT_DATE
    )                                       AS live_candidate
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN essentials.office_current_holder och ON och.politician_id = pa.politician_id
  LEFT JOIN essentials.offices o   ON o.id = och.office_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE pa.value <> 0
    AND pc.reasoning IS NOT NULL
    AND length(trim(pc.reasoning)) >= $1
    ${ALL ? '' : `AND ${BALLOTPEDIA_ONLY}`}`;

const BILL = /\b(?:H\.?\s?B|S\.?\s?B|HJR|SJR|HCR|SCR|A\.?\s?B|AJR|SCA|ACA|LD|LB|HF|SF|H\.?\s?R|S\.?\s?R|H\.?\s?Con\.?\s?Res|S\.?\s?Con\.?\s?Res|H\.?\s?J\.?\s?Res)\s*[-.\s]?\s*\d+[A-Za-z]?\b/gi;
const MEASURE = /\b(?:Measure|Proposition|Prop|Amendment|Question|Initiative|Referendum|Chapter|Act|Article|Title|Resolution|Bill)\s*\.?\s*\d+[A-Za-z]?\b/gi;

/**
 * 🔴 THE DISCRIMINATOR THAT MAKES THIS SCRIPT USABLE — measured, not assumed.
 *
 * Run without it, clustering ranks the BEST rows highest and is worse than useless. 54 Wisconsin
 * Assembly members voting Yes on AJR-102 legitimately produce one identical sentence; so do 78 Maine
 * representatives who share an MRTL scorecard outcome, and 20 Oregon members who voted YES on HB 2002.
 * Those are precisely the rows sourced to a real vote record. At corpus scale they were every one of
 * the top clusters, so "6% of rows cluster" carried no information about fabrication at all.
 *
 * What made the original Portland finding suspicious was not that it repeated — it was that it
 * repeated while naming NO instrument. "Supported civil rights and anti-discrimination measures;
 * consistent progressive voting record from Portland district." cites nothing that could be looked up,
 * so repetition across seven people has no shared-vote explanation available to it.
 *
 * ANCHORED — the shared text names a bill, resolution, ballot measure, named Act or a scorecard. A
 *            shared vote explains the repetition. Expected; NOT a finding.
 * GENERIC  — no instrument named anywhere in the shared text. Repetition has no innocent explanation
 *            of that kind. This is the finding class, and it is the only tier worth a fetch.
 */
/**
 * The vocabulary was widened once, deliberately, after the first corpus run. It initially missed
 * `RES-142` (Wisconsin municipal resolutions), `HJ 9` (Virginia joint resolutions) and "Act on Mass
 * tracker" (a real Massachusetts co-sponsorship record), and so reported ~40 legitimate clusters as
 * generic. Under-reading the vocabulary manufactures findings, which is the failure this whole
 * workstream exists to undo — so when in doubt a pattern belongs HERE, making the generic set smaller
 * and higher-precision.
 */
const INSTRUMENT = [
  BILL,
  MEASURE,
  /\b(?:scorecard|roll[- ]call|vote rating|key votes|tracker)\b/i,
  /\b[A-Z][A-Za-z]*\s+(?:Act|Amendment|Resolution)\b/,          // "Laken Riley Act", "SAVE Act"
  /\b(?:RES|RESO|ORD|ORD\.|AJR|SJR|HJ|SJ|HD|SD|LR)[-\s]?\.?\s?\d+/i, // RES-142, HJ 9, ORD 24
  /\b(?:Measure|Proposition|Prop|Question)\s+\d+/i,
  /\b\d{1,2}\s?[-–]\s?\d{1,2}\b(?=[^\n]{0,40}\b(?:vote|approv|passed|failed|decision)\w*)/i, // "7-0 approval"
  /\b(?:vote|approv|passed|failed)\w*[^\n]{0,40}\b\d{1,2}\s?[-–]\s?\d{1,2}\b/i,              // "passed 218-214"
  /\bhttps?:\/\/[^\s]*(?:legislature|legis|olis|congress\.gov|govtrack|senate\.gov|house\.gov|actonmass|leg\.)/i,
];

function namesInstrument(text) {
  return INSTRUMENT.some((re) => { re.lastIndex = 0; return re.test(text); });
}

/**
 * Collapse a reasoning string to its skeleton: no bills, no measures, no digits, no capitalised
 * tokens, no punctuation, single-spaced. Two rows with the same skeleton were written to the same
 * shape with different nouns dropped in.
 */
function skeleton(text) {
  return text
    .replace(BILL, ' ')
    .replace(MEASURE, ' ')
    .replace(/\b[A-Z][\w'’-]*/g, ' ')   // every capitalised token, sentence-initial included
    .replace(/\d+/g, ' ')
    .replace(/[^\w\s]/g, ' ')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function trigrams(s) {
  const out = new Set();
  const t = ` ${s} `;
  for (let i = 0; i + 3 <= t.length; i++) out.add(t.slice(i, i + 3));
  return out;
}

function jaccard(a, b) {
  let inter = 0;
  for (const g of a) if (b.has(g)) inter++;
  return inter / (a.size + b.size - inter);
}

function visibility(r) {
  if (r.seated) return 'seated';
  if (r.live_candidate) return 'candidate-card';
  return 'invisible';
}

/** Group rows by a key, keeping only groups spanning ≥2 DISTINCT politicians. */
function groupBy(rows, keyFn) {
  const m = new Map();
  for (const r of rows) {
    const k = keyFn(r);
    if (!k) continue;
    if (!m.has(k)) m.set(k, []);
    m.get(k).push(r);
  }
  return [...m.entries()]
    .map(([key, members]) => ({ key, members }))
    .filter((g) => new Set(g.members.map((m2) => m2.politician_id)).size >= 2)
    .sort((a, b) => b.members.length - a.members.length);
}

function describe(g) {
  const people = new Set(g.members.map((m) => m.politician_id));
  const topics = new Set(g.members.map((m) => m.topic ?? m.topic_id));
  const states = new Set(g.members.map((m) => m.st).filter(Boolean));
  const vis = new Set(g.members.map(visibility));
  const anchored = g.members.filter((m) => namesInstrument(m.reasoning)).length;
  const cls = anchored === g.members.length ? 'ANCHORED' : anchored === 0 ? 'GENERIC' : 'MIXED';
  return {
    anchor_class: cls,
    generic_rows: g.members.length - anchored,
    rows: g.members.length,
    politicians: people.size,
    topics: topics.size,
    cross_topic: topics.size > 1,
    cross_state: states.size > 1,
    states: [...states].sort(),
    topic_names: [...topics].sort(),
    visibility: [...vis].sort(),
    sample: g.members[0].reasoning,
    members: g.members.map((m) => ({
      politician_id: m.politician_id,
      name: m.name,
      topic: m.topic ?? m.topic_id,
      value: m.value,
      state: m.st,
      office: m.office_title,
      visibility: visibility(m),
      names_instrument: namesInstrument(m.reasoning),
      reasoning: m.reasoning,
      sources: m.sources,
    })),
  };
}

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    process.exit(0);
  }

  const { rows } = await pool.query(QUERY, [MIN_LEN]);
  const scope = ALL ? 'ALL live answers with context' : 'Ballotpedia-only cohort';
  console.log(`scope: ${scope} — ${rows.length} rows, ${new Set(rows.map((r) => r.politician_id)).size} politicians\n`);

  for (const r of rows) r._skel = skeleton(r.reasoning);

  const identical = groupBy(rows, (r) => r.reasoning);
  const identicalRowIds = new Set(identical.flatMap((g) => g.members.map((m) => `${m.politician_id}|${m.topic_id}`)));

  // SKELETON clusters, minus anything already reported as IDENTICAL — otherwise every identical
  // cluster is reported twice and the totals double-count.
  const skelAll = groupBy(rows, (r) => r._skel || null);
  const skel = skelAll
    .map((g) => ({ ...g, members: g.members.filter((m) => !identicalRowIds.has(`${m.politician_id}|${m.topic_id}`)) }))
    .filter((g) => new Set(g.members.map((m) => m.politician_id)).size >= 2);
  const skelRowIds = new Set(skel.flatMap((g) => g.members.map((m) => `${m.politician_id}|${m.topic_id}`)));

  // NEAR: single-link agglomeration over rows not already clustered exactly. O(n^2) on the residue,
  // which is fine at cohort scale; --all makes this the slow part, so it is capped.
  // Restricted to GENERIC rows. An anchored row that paraphrases another anchored row is two members
  // describing the same vote in slightly different words — the dominant and innocent case — so
  // including them buries the signal AND makes the O(n^2) unaffordable at corpus scale.
  const residue = rows.filter((r) => {
    const id = `${r.politician_id}|${r.topic_id}`;
    return r._skel && !identicalRowIds.has(id) && !skelRowIds.has(id) && !namesInstrument(r.reasoning);
  });
  let near = [];
  const NEAR_CAP = 6000;
  if (residue.length > NEAR_CAP) {
    console.log(`NOTE: ${residue.length} generic rows exceed the ${NEAR_CAP}-row NEAR cap — paraphrase tier SKIPPED, exact tiers are complete.\n`);
  } else {
    const grams = residue.map((r) => trigrams(r._skel));
    const parent = residue.map((_, i) => i);
    const find = (i) => (parent[i] === i ? i : (parent[i] = find(parent[i])));
    for (let i = 0; i < residue.length; i++) {
      for (let j = i + 1; j < residue.length; j++) {
        if (jaccard(grams[i], grams[j]) >= NEAR) parent[find(i)] = find(j);
      }
    }
    const buckets = new Map();
    residue.forEach((r, i) => {
      const root = find(i);
      if (!buckets.has(root)) buckets.set(root, []);
      buckets.get(root).push(r);
    });
    near = [...buckets.values()]
      .map((members) => ({ key: members[0]._skel, members }))
      .filter((g) => new Set(g.members.map((m) => m.politician_id)).size >= 2)
      .sort((a, b) => b.members.length - a.members.length);
  }

  const report = {
    _comment:
      'Template clusters in compass stance reasoning. A cluster is evidence about how a row was ' +
      'PRODUCED, not proof its citation fails — it ranks rows for the article-body test and never ' +
      'justifies deletion on its own.',
    generated_scope: scope,
    near_threshold: NEAR,
    min_reasoning_length: MIN_LEN,
    rows_examined: rows.length,
    tiers: {
      IDENTICAL: identical.map(describe),
      SKELETON: skel.map(describe),
      NEAR: near.map(describe),
    },
  };

  const TIERS = ['IDENTICAL', 'SKELETON', 'NEAR'];
  const every = TIERS.flatMap((t) => report.tiers[t].map((g) => ({ tier: t, ...g })));
  const tierRows = (t) => report.tiers[t].reduce((a, g) => a + g.rows, 0);

  console.log('tier        clusters   rows   ANCHORED  MIXED  GENERIC   generic rows');
  for (const t of TIERS) {
    const gs = report.tiers[t];
    const cnt = (c) => gs.filter((g) => g.anchor_class === c).length;
    console.log(
      `${t.padEnd(10)}  ${String(gs.length).padStart(8)}  ${String(tierRows(t)).padStart(5)}  ` +
      `${String(cnt('ANCHORED')).padStart(9)}  ${String(cnt('MIXED')).padStart(5)}  ${String(cnt('GENERIC')).padStart(7)}  ` +
      `${String(gs.reduce((a, g) => a + g.generic_rows, 0)).padStart(13)}`,
    );
  }

  const clusteredRows = new Set(every.flatMap((g) => g.members.map((m) => `${m.politician_id}|${m.topic}`)));
  const genericRows = new Set(every.flatMap((g) => g.members.filter((m) => !m.names_instrument)
    .map((m) => `${m.politician_id}|${m.topic}`)));
  const pct = (n) => `${Math.round((n / rows.length) * 100)}%`;
  console.log(`\n${clusteredRows.size} of ${rows.length} rows (${pct(clusteredRows.size)}) sit in a cluster.`);
  console.log(`${genericRows.size} of those (${pct(genericRows.size)} of corpus) name NO instrument — this is the actionable set.`);

  const byVis = {};
  for (const g of every) for (const m of g.members) if (!m.names_instrument) byVis[m.visibility] = (byVis[m.visibility] ?? 0) + 1;
  console.log(`generic clustered rows by visibility: ${JSON.stringify(byVis)}`);

  const show = (label, list) => {
    console.log(`\n${label}`);
    if (!list.length) { console.log('  (none)'); return; }
    for (const g of list) {
      const tags = [g.cross_topic ? 'CROSS-TOPIC' : null, g.cross_state ? 'CROSS-STATE' : null].filter(Boolean).join(' ');
      console.log(`\n  [${g.tier}/${g.anchor_class}] ${g.rows} rows / ${g.politicians} people / ${g.topics} topic(s) ${tags}`);
      console.log(`    states: ${g.states.join(',') || '-'}   visibility: ${g.visibility.join(',')}`);
      console.log(`    "${g.sample.slice(0, 170)}${g.sample.length > 170 ? '…' : ''}"`);
      console.log(`    ${g.members.slice(0, 8).map((m) => `${m.name} (${m.topic})`).join('; ')}${g.members.length > 8 ? ' …' : ''}`);
    }
  };

  show('🔴 GENERIC / MIXED clusters — no instrument named, THE ACTIONABLE SET:',
    every.filter((g) => g.anchor_class !== 'ANCHORED').sort((a, b) => b.generic_rows - a.generic_rows).slice(0, 25));
  show('ANCHORED clusters (largest 5) — a shared vote explains these; NOT findings:',
    every.filter((g) => g.anchor_class === 'ANCHORED').sort((a, b) => b.rows - a.rows).slice(0, 5));

  report.actionable_generic_rows = genericRows.size;
  report.clustered_rows = clusteredRows.size;

  if (OUT) {
    const p = path.resolve(OUT);
    writeFileSync(p, `${JSON.stringify(report, null, 2)}\n`);
    console.log(`\nfull report written to ${path.relative(process.cwd(), p)}`);
  }

  await pool.end();
})().catch(async (err) => {
  console.error('FAIL: cluster-stance-reasoning errored:', err.message);
  try { await pool.end(); } catch { /* already closed */ }
  process.exit(2);
});

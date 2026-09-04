#!/usr/bin/env node
/**
 * cohort-worksheet.mjs — the research worksheet for a cohort × the open season.
 *
 * Emits two files into <outdir>:
 *
 *   ladders.md   the verbatim question and all five rung texts for every topic
 *                in scope, taken from the revision THIS SEASON PINNED
 *   rows.csv     one row per (politician, topic) still owed an answer, in the
 *                exact 7 columns verify-reresearch-rows.mjs expects, with
 *                value / reasoning / sources left EMPTY for a researcher
 *
 * It is modelled on reresearch-worksheet.mjs, which does the same job for the
 * 2026-08-03 retirement worklist and is hard-bound to that JSON. This one is
 * driven by a live cohort and the open season instead, so it can be pointed at
 * the Season 2 federal pass without editing a worklist file.
 *
 * 🔴 THE LADDER MUST COME FROM THE SEASON'S PINNED REVISION, NOT is_current.
 * ADR 0006 (Option Y): a season serves the wording of the version it pinned, so
 * a researcher placing someone against `compass_stances_current` can be reading
 * rungs the open season does not serve. compass_stance_revisions keyed by
 * season_questions.topic_revision_id is the set actually shown to voters. This
 * is the same trap compassService documents at length; a worksheet that got it
 * wrong would produce placements against text nobody sees.
 *
 * ⚠ IT WRITES NO VALUES, AND THAT IS NOT A LIMITATION TO BE FIXED. Every row is
 * a claim about a real person that a voter will read, and the pipeline behind it
 * assumes a human chose the rung and the citation: verify-reresearch-rows.mjs
 * fetches every cited URL and requires the reasoning's distinctive terms to
 * appear in its raw HTML. A generated placement would either fail that gate or,
 * worse, pass it with a source that happens to contain the words.
 *
 * ⚠ "OWED" MEANS NO ANSWER IN ANY PUBLISHED SEASON — not "none in the open one".
 * The read path takes the newest season per topic and every non-draft season
 * counts, so a senator's Season 1 answer on Climate Change still displays and is
 * not owed. Scoping the test to the open season instead reported 3,240 owed rows
 * for the Senate where the true figure is far smaller, which would have sent
 * researchers to redo answers that already stand.
 *
 * RUN: node scripts/cohort-worksheet.mjs --tier=federal --cohort=senate --topics=new <outdir>
 *      node scripts/cohort-worksheet.mjs --tier=federal --cohort=all               <outdir>
 *
 *      --topics=new  restricts to topics NO EARLIER SEASON ASKED — the Season 2
 *                    additions, which is what a "the extra N questions" pass means.
 *                    Omit it for every topic the season asks of this tier.
 *
 * Needs DATABASE_URL (session pooler string; the direct host is IPv6-only).
 */
import 'dotenv/config';
import { writeFileSync, mkdirSync } from 'fs';
import path from 'node:path';
import pg from 'pg';
import { SITTING_SENATOR_SQL, COMPASS_TIERS } from './lib/office-tiers.mjs';

const args = process.argv.slice(2);
const outdir = args.find((a) => !a.startsWith('--'));
const flag = (name) => {
  const hit = args.find((a) => a.startsWith(`--${name}=`));
  return hit ? hit.slice(name.length + 3) : null;
};
const tier = flag('tier');
const cohort = flag('cohort') ?? 'all';
const topicsMode = flag('topics') ?? 'all';
if (!['all', 'new'].includes(topicsMode)) {
  console.error('cohort-worksheet: --topics must be "all" or "new".');
  process.exit(1);
}

if (!outdir || !tier) {
  console.error('usage: node scripts/cohort-worksheet.mjs --tier=<federal|state|local|judicial> [--cohort=senate|house|exec|all] <outdir>');
  process.exit(1);
}
if (!COMPASS_TIERS.includes(tier)) {
  console.error(`cohort-worksheet: --tier must be one of ${COMPASS_TIERS.join(', ')}`);
  process.exit(1);
}
if (!process.env.DATABASE_URL) {
  console.error('cohort-worksheet: DATABASE_URL is not set.');
  process.exit(1);
}

const SEAT_JOIN = `
       LEFT JOIN essentials.office_current_holder h ON h.politician_id = p.id
       LEFT JOIN essentials.offices  o ON o.id = COALESCE(p.office_id, h.office_id)
       LEFT JOIN essentials.districts d ON d.id = o.district_id`;

/** Which seats this run covers. See federal-cohort.mjs for why each clause is shaped this way. */
const COHORT_PREDICATE = {
  senate: SITTING_SENATOR_SQL,
  house: `(d.ocd_id LIKE '%/cd:%' AND o.title NOT ILIKE '%shadow senator%')`,
  exec: `(d.ocd_id = 'ocd-division/country:us' AND o.title IN ('President', 'Vice President'))`,
};
COHORT_PREDICATE.all = `(${[COHORT_PREDICATE.senate, COHORT_PREDICATE.house, COHORT_PREDICATE.exec].join(' OR ')})`;

if (!COHORT_PREDICATE[cohort]) {
  console.error(`cohort-worksheet: --cohort must be one of ${Object.keys(COHORT_PREDICATE).join(', ')}`);
  process.exit(1);
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

/** Topics the OPEN season asks that admit this tier. No role rows = all but judicial. */
const TOPICS_SQL = `
  SELECT q.topic_id, q.topic_revision_id, q.question_number,
         pr.topic_key, pr.title, pr.question_text,
         (SELECT array_agg(role_scope ORDER BY role_scope)
            FROM inform.compass_topic_roles r WHERE r.topic_id = q.topic_id) AS scopes,
         NOT EXISTS (
           SELECT 1 FROM inform.season_questions q0
             JOIN inform.seasons s0 ON s0.id = q0.season_id AND s0.number < s.number
            WHERE q0.topic_id = q.topic_id) AS is_new_this_season
    FROM inform.season_questions q
    JOIN inform.seasons s ON s.id = q.season_id AND s.status = 'open'
    JOIN inform.compass_topics_promoted pr ON pr.id = q.topic_id
   ORDER BY q.question_number`;

const PEOPLE_SQL = `
  SELECT DISTINCT ON (p.id) p.id, p.full_name, p.party, o.title
    FROM essentials.politicians p ${SEAT_JOIN}
   WHERE p.is_active AND NOT COALESCE(p.is_vacant, false)
     AND ${COHORT_PREDICATE[cohort]}
   ORDER BY p.id, o.title`;

try {
  const [{ rows: topics }, { rows: people }] = await Promise.all([
    pool.query(TOPICS_SQL),
    pool.query(PEOPLE_SQL),
  ]);

  const inTier = topics
    .filter((t) => (!t.scopes || t.scopes.length === 0 ? tier !== 'judicial' : t.scopes.includes(tier)))
    .filter((t) => topicsMode === 'all' || t.is_new_this_season);

  if (!inTier.length) {
    console.error(`cohort-worksheet: the open season asks nothing that admits the ${tier} tier.`);
    process.exit(1);
  }
  if (!people.length) {
    console.error(`cohort-worksheet: cohort "${cohort}" matched nobody.`);
    process.exit(1);
  }

  // The ladder each topic's season pinned — never compass_stances_current.
  const { rows: rungs } = await pool.query(
    `SELECT sr.topic_revision_id, sr.value, sr.text
       FROM inform.compass_stance_revisions sr
      WHERE sr.topic_revision_id = ANY($1::uuid[])
      ORDER BY sr.topic_revision_id, sr.value`,
    [inTier.map((t) => t.topic_revision_id)],
  );

  // Any answer in any PUBLISHED season stands and displays — see the header. A
  // Season 1 answer is not owed again just because Season 2 opened.
  // Scoped to the topics THIS RUN covers. Counting held pairs across every topic
  // and subtracting them from an in-scope total is how the summary line first
  // reported "-1430 rows are owed" while the CSV, which filters per pair, held
  // the correct 900.
  const { rows: held } = await pool.query(
    `SELECT DISTINCT a.politician_id, a.topic_id
       FROM inform.politician_answers a
       JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
      WHERE a.politician_id = ANY($1::uuid[])
        AND a.topic_id = ANY($2::uuid[])`,
    [people.map((p) => p.id), inTier.map((t) => t.topic_id)],
  );
  const alreadyHeld = new Set(held.map((h) => `${h.politician_id}|${h.topic_id}`));

  mkdirSync(outdir, { recursive: true });

  const md = [
    `# Research worksheet — ${cohort} cohort, ${tier} tier`,
    '',
    `Generated ${new Date().toISOString()} against the OPEN season.`,
    '',
    `${people.length} people × ${inTier.length} topics = ${people.length * inTier.length} pairs; ` +
      `${alreadyHeld.size} pairs already hold a standing answer in some published season, so **${people.length * inTier.length - alreadyHeld.size} rows are owed**.`,
    '',
    'Rung text below is the wording THIS SEASON PINNED (ADR 0006) — not `compass_stances_current`.',
    'Place each person on one of the five rungs. A blank is a real outcome: if no rung states what',
    'they hold, leave the row out and say so, rather than choosing the nearest rung.',
    '',
  ];
  for (const t of inTier) {
    md.push(`## Q${t.question_number}. ${t.title}  \`${t.topic_key}\``);
    md.push('');
    md.push(`**${t.question_text}**`);
    md.push('');
    md.push(`_tiers: ${(t.scopes || []).join(', ') || 'all (cross-cutting)'}_`);
    md.push('');
    for (const r of rungs.filter((r) => r.topic_revision_id === t.topic_revision_id)) {
      md.push(`- **${r.value}** — ${r.text}`);
    }
    md.push('');
  }
  writeFileSync(path.join(outdir, 'ladders.md'), md.join('\n'), 'utf8');

  const esc = (s) => (/[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s);
  const csv = ['full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3'];
  let owed = 0;
  for (const p of people) {
    for (const t of inTier) {
      if (alreadyHeld.has(`${p.id}|${t.topic_id}`)) continue;
      csv.push(`${esc(p.full_name)},${t.topic_key},,,,,`);
      owed++;
    }
  }
  writeFileSync(path.join(outdir, 'rows.csv'), `${csv.join('\n')}\n`, 'utf8');

  console.log(`\ncohort-worksheet — ${cohort} / ${tier}\n`);
  console.log(`  ${String(people.length).padStart(5)}  people`);
  console.log(`  ${String(inTier.length).padStart(5)}  topics the open season asks for this tier`);
  console.log(`  ${String(alreadyHeld.size).padStart(5)}  pairs already hold a standing answer`);
  console.log(`  ${String(owed).padStart(5)}  ROWS OWED  → ${path.join(outdir, 'rows.csv')}`);
  console.log(`\n  ladders → ${path.join(outdir, 'ladders.md')}`);
  console.log('\n  Fill value / reasoning / source_url_*, then:');
  console.log(`    node scripts/verify-reresearch-rows.mjs ${path.join(outdir, 'rows.csv')} --tier=${tier}\n`);
} finally {
  await pool.end();
}

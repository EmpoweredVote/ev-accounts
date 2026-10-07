#!/usr/bin/env node
/**
 * Place the FEDERAL generic-only cohort inside the 2026-08-11 Tier B cross-tab, without re-fetching.
 *
 * WHY: the national generic-sourcing queue was re-measured on 2026-10-06 at 3,266 keys, and the
 * federal slice (578 keys / 216 politicians) was picked as the first block to work. Before fetching
 * anything, the question is how much of it the 08-11 Tier B pass already answered — that pass
 * recorded a per-(politician,topic) verdict for 2,031 keys and those records survive even though
 * its HTML cache does not.
 *
 * 🔑 THE FEDERAL SLICE IS A TIER B PROBLEM, NOT A ROLL-CALL ONE. 533 of its keys cite Wikipedia and
 * only 13 cite congress.gov/govtrack, so the first test is "does the cited ARTICLE carry this
 * position?", not "how did they vote?". Picking it for the roll-call toolchain would have been
 * picking it for the wrong reason.
 *
 * 🔴 CHECK THE FIELD NAMES IN THE RECORD BEFORE TRUSTING AN EMPTY RESULT. A first run of this
 * script read `row.topic_present`, which does not exist in the coverage JSON — the field is
 * `coverage` ('TOPIC_PRESENT'|'TOPIC_ABSENT'|'ARTICLE_DEAD'). Every key therefore scored "present"
 * and both defect quadrants came back EMPTY, which reads exactly like good news. The real numbers
 * are 39 and 53. An all-clear from a join is a claim about your join first and the data second.
 *
 * ⚠ TOPIC LABELS COME FROM `topic_key`, NEVER `compass_topics.title`. That column is the FROZEN v1
 * wording and 29 of 60 topics disagree with their season pin, so a worklist labelled from it can
 * name a question nobody was asked. CI's `frozen ladder text` guard caught exactly that in the
 * first draft of this script. These tools are season-agnostic triage, so the stable key is the
 * right label; anything needing the real wording must read the season's pinned revision.
 *
 * 🔴 Reads only. Writes a worklist, never the DB.
 *   node scripts/federal-tierb-crosstab.mjs --out <worklist.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv.includes('--out') ? process.argv[process.argv.indexOf('--out') + 1] : null;

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// Same generic predicate as tier-a-generic-member-pages.mjs, restricted to federal officeholders.
const { rows: fed } = await pool.query(`
  WITH src AS (
    SELECT c.politician_id, c.topic_id,
           COALESCE(substring(u FROM 'web\\.archive\\.org/web/[0-9]+(?:id_)?/(https?://.*)$'), u) AS nu
    FROM inform.politician_context c, unnest(c.sources) u
  ), cls AS (
    SELECT politician_id, topic_id, nu,
      CASE WHEN nu ILIKE '%en.wikipedia.org/wiki/%'
        OR (nu ILIKE '%ballotpedia.org/%' AND nu NOT ILIKE '%candidate_connection%')
        OR nu ILIKE '%/mgawebsite/members/details/%' OR nu ILIKE '%capitol.texas.gov/members/memberinfo%'
        OR nu ILIKE '%malegislature.gov/legislators/profile%'
        OR nu ILIKE '%legislature.maine.gov/%memberprofiles%'
        OR nu ILIKE '%azleg.gov/house/house-member%' OR nu ILIKE '%azleg.gov/senate/senate-member%'
        OR nu ILIKE '%ballotready.org/people/%' OR nu ILIKE '%congress.gov/member/%'
        OR nu ILIKE '%govtrack.us/congress/members/%' THEN 1 ELSE 0 END AS is_generic
    FROM src
  ), agg AS (
    SELECT politician_id, topic_id, count(*) n_src, sum(is_generic) n_gen,
           array_agg(DISTINCT nu) AS srcs
    FROM cls GROUP BY 1,2
  ), bad AS (SELECT * FROM agg WHERE n_gen = n_src)
  SELECT DISTINCT b.politician_id, b.topic_id, b.srcs,
         p.full_name, t.topic_key, ch.name AS chamber
  FROM bad b
  JOIN essentials.politicians p ON p.id = b.politician_id
  JOIN essentials.office_terms ot ON ot.politician_id = p.id
  JOIN essentials.offices o  ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  LEFT JOIN inform.compass_topics t ON t.id = b.topic_id
  WHERE g.name = 'United States Federal Government'
`);
await pool.end();

// ⚠ One politician can hold two federal offices (House then Senate), so the office join duplicates.
// The UNIT IS THE KEY (politician, topic) — collapse before counting or the total is inflated.
const keys = new Map();
for (const r of fed) {
  const k = `${r.politician_id}|${r.topic_id}`;
  if (!keys.has(k)) keys.set(k, { ...r, chambers: new Set() });
  keys.get(k).chambers.add(r.chamber);
}
console.log(`federal generic-only KEYS: ${keys.size}  (join rows before collapsing: ${fed.length})`);
console.log(`federal politicians: ${new Set([...keys.values()].map((r) => r.politician_id)).size}\n`);

const cov = JSON.parse(fs.readFileSync(
  'C:/EV-Accounts/backend/data/stance-retirement/2026-08-11-tier-b-coverage.json', 'utf8'));
const prior = new Map();
for (const r of cov.rows) prior.set(`${r.politician_id}|${r.topic_id}`, r);

const tab = new Map();
const unseen = [];
const work = [];
for (const [k, r] of keys) {
  const p = prior.get(k);
  let cell;
  if (!p) { cell = 'NOT IN THE 08-11 RECORD (never audited)'; unseen.push(r); }
  else if (p.coverage === 'ARTICLE_DEAD' || p.article_exists === false) cell = 'ARTICLE DEAD';
  else cell = `${p.verdict === 'HAS_POSITIONS_SECTION' ? 'HAS positions' : 'no positions '} | ${p.coverage}`;
  tab.set(cell, (tab.get(cell) || 0) + 1);
  work.push({
    politician: r.full_name, politician_id: r.politician_id,
    topic_key: r.topic_key, topic_id: r.topic_id,
    chambers: [...r.chambers], sources: r.srcs, cell,
    prior_verdict: p ? p.verdict : null,
  });
}

console.log('CROSS-TAB of the federal cohort against the 2026-08-11 Tier B record:');
for (const [k, v] of [...tab.entries()].sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(4)}  ${k}`);
console.log(`\nnever audited: ${unseen.length} keys / ${new Set(unseen.map((u) => u.politician_id)).size} politicians`);
console.log('⚠ TOPIC_ABSENT is a SORT, not a verdict — run claim-on-page-input.mjs then');
console.log('  the-197-claim-on-page.mjs over those cells before treating any of them as defects.');

if (OUT) {
  fs.writeFileSync(OUT, JSON.stringify({ generated: new Date().toISOString(), keys: keys.size, work }, null, 2));
  console.log(`\nworklist -> ${OUT}`);
}

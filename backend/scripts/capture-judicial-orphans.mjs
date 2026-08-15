// One-shot capture: every ORPHAN_CONTEXT row sitting on a role-conduct judicial ladder.
//
// WHY THIS EXISTS. Migration 1735 blanked 117 answers on the three role-conduct judicial topics as a
// category error and deliberately KEPT their context; those 117 are already captured verbatim in
// 2026-08-12-judicial-scope-1735-rollback.json. Two more rows (Smith, Waldstreicher / Bail &
// Pretrial) are the SAME category error but were already answer-less when 1735 ran, so 1735 -- which
// drives FROM politician_answers -- could not see them and they are captured NOWHERE. Deleting the
// cohort without capturing those two would be an unrecorded loss of research.
//
// So this re-captures all 119 from live data rather than trusting the older file to cover them.
// Reasoning and sources are stored verbatim; the qualification test from 1735 is re-run per row and
// recorded, so the file proves the category error still held at capture time rather than asserting it.
import 'dotenv/config';
import pg from 'pg';
import { writeFileSync } from 'node:fs';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Mirrors check-stance-sources.mjs ORPHAN_CONTEXT exactly -- shape exclusion for empty sources, then
// the two blank carve-outs. If the gate's predicate ever changes, this capture must be regenerated.
const SQL = `
WITH orph AS (
  SELECT pc.politician_id, pc.topic_id, pc.reasoning, pc.sources
  FROM inform.politician_context pc
  LEFT JOIN inform.politician_answers pa
    ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
  WHERE pa.politician_id IS NULL
    AND coalesce(cardinality(pc.sources), 0) > 0
    AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
    AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)'
),
holds AS (
  SELECT ot.politician_id,
         bool_or(o.title ILIKE '%judge%' OR o.title ILIKE '%justice%') AS is_judge,
         bool_or(o.title ILIKE '%district attorney%' OR o.title ILIKE '%state''s attorney%'
              OR o.title ILIKE '%city attorney%' OR o.title ILIKE '%county attorney%'
              OR o.title ILIKE '%prosecut%' OR o.title ILIKE '%solicitor%'
              OR o.title ILIKE '%attorney general%' OR o.title ILIKE '%corporation counsel%') AS is_da
    FROM essentials.office_terms ot JOIN essentials.offices o ON o.id = ot.office_id GROUP BY 1),
runs AS (
  SELECT rc.politician_id,
         bool_or(COALESCE(o2.title,'') ILIKE '%judge%' OR COALESCE(o2.title,'') ILIKE '%justice%'
              OR r.position_name ILIKE '%court%' OR r.position_name ILIKE '%judge%'
              OR r.position_name ILIKE '%justice%') AS runs_judge,
         bool_or(COALESCE(o2.title,'') ILIKE '%attorney%' OR COALESCE(o2.title,'') ILIKE '%prosecut%'
              OR r.position_name ILIKE '%attorney%' OR r.position_name ILIKE '%prosecut%'
              OR r.position_name ILIKE '%solicitor%') AS runs_da
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.offices o2 ON o2.id = r.office_id GROUP BY 1)
SELECT o.politician_id, o.topic_id, o.reasoning, o.sources,
       p.first_name || ' ' || p.last_name AS name,
       t.topic_key, t.title AS topic, t.judicial_role,
       (SELECT string_agg(DISTINCT off.title, ' | ') FROM essentials.office_terms ot
          JOIN essentials.offices off ON off.id = ot.office_id
         WHERE ot.politician_id = o.politician_id) AS offices,
       (SELECT string_agg(DISTINCT r.position_name, ' | ') FROM essentials.race_candidates rc
          JOIN essentials.races r ON r.id = rc.race_id
         WHERE rc.politician_id = o.politician_id) AS running_for,
       CASE WHEN t.judicial_role = 'judge'
            THEN COALESCE(h.is_judge,false) OR COALESCE(rn.runs_judge,false)
            ELSE COALESCE(h.is_da,false)    OR COALESCE(rn.runs_da,false) END AS qualifies_now
  FROM orph o
  JOIN inform.compass_topics t ON t.id = o.topic_id AND t.judicial_role IS NOT NULL
  JOIN essentials.politicians p ON p.id = o.politician_id
  LEFT JOIN holds h  ON h.politician_id = o.politician_id
  LEFT JOIN runs  rn ON rn.politician_id = o.politician_id
 ORDER BY t.topic_key, p.last_name, p.first_name`;

const { rows } = await pool.query(SQL);
await pool.end();

// A row that qualifies is NOT a category error and must not be swept up in the delete. Refuse to emit
// rather than quietly filtering: if this ever fires, the cohort changed and the migration needs rewriting.
const qualifying = rows.filter((r) => r.qualifies_now);
if (qualifying.length > 0) {
  console.error(`REFUSING: ${qualifying.length} row(s) qualify for the role and are not category errors:`);
  for (const r of qualifying) console.error(`  ${r.name} — ${r.topic} (${r.offices ?? 'no office'})`);
  process.exit(1);
}

const byTopic = {};
for (const r of rows) byTopic[r.topic_key] = (byTopic[r.topic_key] ?? 0) + 1;

const out = {
  pass: 'judicial role-conduct ladders — context left behind when the answer was blanked as a category error',
  migration: '1755_judicial_orphan_context_delete.sql',
  captured_at: '2026-08-14',
  note:
    'Rows deleted from inform.politician_context. Every row sits on a ladder that asks about the ' +
    'subject\'s own conduct in a role they neither hold nor seek, so the position it describes cannot ' +
    'exist for that person. 117 of these are the answers blanked by migration 1735 (their answers are ' +
    'in 2026-08-12-judicial-scope-1735-rollback.json); the remaining 2 were already answer-less then ' +
    'and are captured here for the first time. reasoning/sources are verbatim — restoring is an INSERT ' +
    'from this file.',
  qualification_test:
    'Re-ran migration 1735\'s holds-or-runs-for-the-role predicate at capture time. All rows returned ' +
    'false; the script refuses to emit if any row qualifies.',
  n_rows: rows.length,
  by_topic: byTopic,
  rows,
};

const path = 'data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json';
writeFileSync(path, JSON.stringify(out, null, 1));
console.log(`captured ${rows.length} rows -> ${path}`);
console.log(byTopic);

/**
 * build-stance-topic-bundle.ts — the exact question set a stance-research batch is scored against.
 *
 * 🔴 Reads the OPEN season's pinned ladder revisions (season_questions -> compass_topic_revisions
 * -> compass_stance_revisions), NEVER the frozen legacy inform.compass_stances. On 2026-09-22,
 * 29 of the open season's 60 ladders differed from the legacy text: a researcher shown the legacy
 * text scores against a sentence the stored answer is not an answer to.
 *
 * Usage (from backend/):
 *   npx tsx scripts/build-stance-topic-bundle.ts --dir data/stance-research/<batch> \
 *     [--race <race_id> ...] [--politician <uuid>:<federal|state|local|judicial|school> ...]
 * Writes <dir>/topics.json and <dir>/politicians.json, then prints one TOPIC SCALE REFERENCE
 * block per office level present — paste the matching block into each researcher prompt.
 * politicians.json holds ONE entry per politician_id: a person reached by a --race and also given
 * by --politician (the documented way to set a level the race could not) is one entry, with the
 * --politician level.
 * `school` (CA_0256) is a K-12 school board: its reference block lists only topics with an explicit
 * `school` role row (the eight Education Lens topics). A community-college board on a --race resolves
 * to level unknown (topicApplicability.ts, COMMUNITY_COLLEGE_LABEL_RE) — it is outside every level. So
 * does a school board filed on a LOCAL district (SCHOOL_BOARD_OFFICE_RE): re-type the district first.
 * Exit: 0 ok, 1 no open season / malformed ladder, 2 usage (including a malformed uuid).
 */
import 'dotenv/config';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import {
  appliesFromRoles, appliesToLevel, levelForDistrict, type Level,
} from '../src/lib/topicApplicability.js';

const LEVELS: Level[] = ['federal', 'state', 'local', 'judicial', 'school'];
function opts(name: string): string[] {
  const out: string[] = [];
  process.argv.forEach((a, i) => { if (a === name && process.argv[i + 1]) out.push(process.argv[i + 1]); });
  return out;
}
const DIR = opts('--dir')[0];
const RACES = opts('--race');
const MANUAL = opts('--politician');
if (!DIR || (!RACES.length && !MANUAL.length)) {
  console.error('usage: build-stance-topic-bundle.ts --dir <batch> [--race <id> ...] [--politician <uuid>:<level> ...]');
  process.exit(2);
}
// Validate every id BEFORE any query: a malformed uuid used to reach `id = $1` and crash with an
// uncaught "invalid input syntax for type uuid" (exit 1) instead of this script's usage exit 2.
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
for (const r of RACES) {
  if (!UUID_RE.test(r)) { console.error(`ERROR: --race ${r}: not a uuid`); process.exit(2); }
}
const manualArgs: { id: string; level: Level }[] = [];
for (const m of MANUAL) {
  const [id, lvl, ...rest] = m.split(':');
  if (!UUID_RE.test(id ?? '') || rest.length) {
    console.error(`ERROR: --politician ${m}: expected <uuid>:<level>, and "${id}" is not a uuid`);
    process.exit(2);
  }
  if (!LEVELS.includes(lvl as Level)) { console.error(`ERROR: --politician ${m}: level must be one of ${LEVELS.join('|')}`); process.exit(2); }
  const lower = id.toLowerCase(); // essentials ids come back as lower-case text
  const prior = manualArgs.find((a) => a.id === lower);
  if (prior && prior.level !== lvl) {
    console.error(`ERROR: --politician ${lower} is given twice with different levels (${prior.level}, ${lvl}) — one person has one level in a bundle`);
    process.exit(2);
  }
  if (!prior) manualArgs.push({ id: lower, level: lvl as Level });
}

const { rows: raw } = await pool.query(`
  SELECT t.id::text AS topic_id, t.topic_key, sq.topic_revision_id::text AS topic_revision_id,
         sq.question_number, tr.title, tr.question_text,
         (SELECT json_agg(json_build_object('value', sr.value, 'text', sr.text) ORDER BY sr.value)
            FROM inform.compass_stance_revisions sr
           WHERE sr.topic_revision_id = sq.topic_revision_id) AS stances,
         (SELECT coalesce(json_agg(json_build_object('role_scope', r.role_scope)), '[]'::json)
            FROM inform.compass_topic_roles r WHERE r.topic_id = t.id) AS roles
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = sq.topic_id
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   ORDER BY sq.question_number`);
if (!raw.length) {
  console.error('ERROR: no open season, or it has no season_questions — refusing to write an empty bundle');
  await pool.end();
  process.exit(1);
}
const topics = raw.map(({ roles, ...t }) => {
  if (!Array.isArray(t.stances) || t.stances.length !== 5) {
    console.error(`ERROR: ${t.topic_key} has ${t.stances?.length ?? 0} rungs, expected 5`);
    process.exit(1);
  }
  return { ...t, ...appliesFromRoles(roles) };
});

type Pol = { full_name: string; politician_id: string; level: Level | null; race_id: string | null };
// Keyed by politician_id: one person given twice (--race and --politician, or two races) is ONE
// entry. Two entries for one id would otherwise read to stance-gate as two namesakes.
const byId = new Map<string, Pol>();
if (RACES.length) {
  const { rows } = await pool.query(`
    SELECT DISTINCT ON (p.id) p.full_name, p.id::text AS politician_id, r.id::text AS race_id,
           d.district_type, d.is_judicial, d.label AS district_label,
           o.title AS office_title, ch.name AS chamber_name, ch.name_formal AS chamber_name_formal
      FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.offices o ON o.id = r.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.politicians p ON p.id = rc.politician_id
     WHERE r.id = ANY($1::uuid[])
     ORDER BY p.id, r.id`, [RACES]);
  for (const r of rows) {
    byId.set(r.politician_id, { full_name: r.full_name, politician_id: r.politician_id, race_id: r.race_id,
      level: levelForDistrict(r.district_type, r.is_judicial, r.district_label,
        [r.office_title, r.chamber_name, r.chamber_name_formal]) });
  }
  const { rows: [{ n }] } = await pool.query(
    `SELECT count(*)::int AS n FROM essentials.race_candidates
      WHERE race_id = ANY($1::uuid[]) AND politician_id IS NULL`, [RACES]);
  if (n) console.log(`note: ${n} candidate(s) on these races have no politician record and were skipped — they cannot hold a stance`);
}
for (const { id, level } of manualArgs) {
  const { rows } = await pool.query('SELECT full_name FROM essentials.politicians WHERE id = $1', [id]);
  if (!rows.length) { console.error(`ERROR: politician ${id} not found`); process.exit(2); }
  const onRace = byId.get(id);
  if (onRace) {
    // Same person as a --race candidate: keep the race_id, take the explicit level.
    if (onRace.level !== level) {
      console.log(`note: ${onRace.full_name} (${id}) is on a --race and given by --politician — one entry, level ${level} (was ${onRace.level ?? 'unknown'})`);
    }
    byId.set(id, { ...onRace, level });
  } else {
    byId.set(id, { full_name: rows[0].full_name, politician_id: id, level, race_id: null });
  }
}
await pool.end();
const politicians: Pol[] = [...byId.values()];

mkdirSync(DIR, { recursive: true });
writeFileSync(join(DIR, 'topics.json'), JSON.stringify(topics, null, 2));
writeFileSync(join(DIR, 'politicians.json'), JSON.stringify(politicians, null, 2));
console.log(`wrote ${topics.length} open-season topics and ${politicians.length} politician(s) to ${DIR}`);

for (const level of LEVELS) {
  if (!politicians.some((p) => p.level === level)) continue;
  const inScope = topics.filter((t) => appliesToLevel(t, level));
  console.log(`\n===== TOPIC SCALE REFERENCE (${level}) — ${inScope.length} topics =====`);
  if (!inScope.length) {
    // An empty reference must not read as "nothing to find". For school it means CA_0256's role rows are absent.
    console.log(`⚠ no open-season topic applies at the ${level} level — do not research${level === 'school' ? ' (are CA_0256\'s school role rows applied?)' : ''}`);
  }
  for (const t of inScope) {
    console.log(`\n${t.topic_key} (id: ${t.topic_id}, revision: ${t.topic_revision_id})`);
    console.log(`Question: "${t.question_text}"`);
    for (const s of t.stances) console.log(`  ${s.value} = "${s.text}"`);
  }
}
const unknown = politicians.filter((p) => !p.level);
if (unknown.length) console.log(`\n⚠ level unknown (scope cannot be checked): ${unknown.map((p) => p.full_name).join(', ')}`);

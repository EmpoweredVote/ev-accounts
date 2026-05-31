/**
 * Seed 2026 Utah County Commission candidate politician records + compass stances.
 *
 * Mirrors the established candidate pattern (e.g. Lilliana Young, Indiana):
 *   - essentials.politicians row (office_id null, slug, bio, source)
 *   - essentials.offices row with chamber_id/district_id NULL so the candidate
 *     does NOT leak into address/geofence lookups (ST_Intersects needs a district)
 *   - essentials.race_candidates.politician_id linked
 *   - inform.politician_answers + politician_context upserted (PK politician_id,topic_id)
 *   - essentials.politicians.last_stances_researched_at stamped
 *
 * Idempotent: re-running reuses an already-linked politician_id instead of
 * creating duplicates. Candidates with no researched stances (Bowen, Allen) are
 * intentionally NOT given politician records.
 *
 * Source CSVs: data/stance-research/2026-05-31-utah-county-commission-batch*.csv
 */
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const CSV_DIR = join(process.cwd(), 'data/stance-research');
const CSV_PREFIX = '2026-05-31-utah-county-commission-batch';

type Row = {
  full_name: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

// Candidate metadata. office title = office sought (matches Lilliana convention).
const CANDIDATES: Record<string, { first: string; last: string; slug: string; bio: string }> = {
  'Michelle Kaufusi': { first: 'Michelle', last: 'Kaufusi', slug: 'michelle-kaufusi',
    bio: 'Mayor of Provo, Utah and 2026 candidate for the Utah County Commission (Seat A).' },
  'Brent Bowles': { first: 'Brent', last: 'Bowles', slug: 'brent-bowles',
    bio: '2026 candidate for the Utah County Commission (Seat A).' },
  'Carolina Herrin': { first: 'Carolina', last: 'Herrin', slug: 'carolina-herrin',
    bio: 'Career law enforcement professional and 2026 candidate for the Utah County Commission (Seat B).' },
  'David Spencer': { first: 'David', last: 'Spencer', slug: 'david-spencer',
    bio: 'Orem City Council member and 2026 candidate for the Utah County Commission (Seat B).' },
  'Isaac Paxman': { first: 'Isaac', last: 'Paxman', slug: 'isaac-paxman',
    bio: 'Provo Deputy Mayor and 2026 candidate for the Utah County Commission (Seat B).' },
  'Fred J. Allen': { first: 'Fred', last: 'Allen', slug: 'fred-allen',
    bio: '2026 candidate for the Utah County Commission (Seat B).' },
};

const SOURCE = 'utah-county-discovery';
const OFFICE_TITLE = 'Utah County Commissioner';

// --- Load CSV rows ---
const files = readdirSync(CSV_DIR).filter(f => f.startsWith(CSV_PREFIX) && f.endsWith('.csv')).sort();
const allRows: Row[] = [];
for (const f of files) {
  const content = readFileSync(join(CSV_DIR, f), 'utf8');
  const rows = parse(content, { columns: true, skip_empty_lines: true, relax_column_count: true }) as Row[];
  allRows.push(...rows);
}
console.log(`Loaded ${allRows.length} stance rows from ${files.length} files: ${files.join(', ')}`);

// Group rows by candidate
const byCandidate = new Map<string, Row[]>();
for (const r of allRows) {
  if (!r.full_name) continue;
  if (!byCandidate.has(r.full_name)) byCandidate.set(r.full_name, []);
  byCandidate.get(r.full_name)!.push(r);
}

// --- Resolve topic_key -> topic_id ---
const { rows: topicRows } = await pool.query(
  `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
);
const topicIdByKey = new Map<string, string>(topicRows.map((t: any) => [t.topic_key, t.id]));

// --- Resolve the Utah County Commission 2026 races (for race_candidate linking) ---
const { rows: ucRaces } = await pool.query(`
  SELECT r.id FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE r.position_name ILIKE 'Utah County Commission%'
    AND e.state = 'UT' AND e.election_date >= '2026-01-01'
`);
const ucRaceIds: string[] = ucRaces.map((r: any) => r.id);
console.log(`Utah County Commission races: ${ucRaceIds.length}`);

let polCreated = 0, polReused = 0, linked = 0, answers = 0, contexts = 0;
const stampedIds: string[] = [];
const errors: string[] = [];

for (const [fullName, rows] of byCandidate) {
  const meta = CANDIDATES[fullName];
  if (!meta) { errors.push(`No metadata for ${fullName} — skipped`); continue; }

  // Find the race_candidate row for this candidate within UC races
  const { rows: rcRows } = await pool.query(
    `SELECT id, politician_id FROM essentials.race_candidates
     WHERE full_name = $1 AND race_id = ANY($2::uuid[])`, [fullName, ucRaceIds]);
  if (!rcRows.length) { errors.push(`No race_candidate for ${fullName} in UC races`); continue; }

  // Reuse existing politician if already linked (idempotency)
  let politicianId: string | null = rcRows.find((r: any) => r.politician_id)?.politician_id ?? null;
  if (!politicianId) {
    // Also guard against an existing politician with the same slug
    const { rows: existing } = await pool.query(
      `SELECT id FROM essentials.politicians WHERE slug = $1`, [meta.slug]);
    if (existing.length) {
      politicianId = existing[0].id;
      polReused++;
    } else {
      const { rows: ins } = await pool.query(
        `INSERT INTO essentials.politicians
           (full_name, first_name, last_name, slug, bio_text, source, is_incumbent, is_active)
         VALUES ($1,$2,$3,$4,$5,$6,false,true)
         RETURNING id`,
        [fullName, meta.first, meta.last, meta.slug, meta.bio, SOURCE]);
      politicianId = ins[0].id;
      polCreated++;
      // descriptive office: NULL chamber/district => no geofence/address leak
      await pool.query(
        `INSERT INTO essentials.offices (politician_id, title, representing_state, chamber_id, district_id)
         VALUES ($1,$2,'UT',NULL,NULL)`, [politicianId, OFFICE_TITLE]);
    }
  } else {
    polReused++;
  }

  // Link all of this candidate's race_candidate rows
  const upd = await pool.query(
    `UPDATE essentials.race_candidates SET politician_id = $1, updated_at = now()
     WHERE full_name = $2 AND race_id = ANY($3::uuid[]) AND (politician_id IS NULL OR politician_id = $1)`,
    [politicianId, fullName, ucRaceIds]);
  linked += upd.rowCount ?? 0;

  // Upsert stances
  for (const r of rows) {
    const topicId = topicIdByKey.get(r.topic_key);
    if (!topicId) { errors.push(`${fullName}: unknown topic_key ${r.topic_key}`); continue; }
    const value = Number(r.value);
    if (!Number.isFinite(value) || value < 1 || value > 5) {
      errors.push(`${fullName}/${r.topic_key}: bad value '${r.value}'`); continue;
    }
    const sources = [r.source_url_1, r.source_url_2, r.source_url_3].map(s => s?.trim()).filter(Boolean);
    try {
      await pool.query(
        `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
         VALUES ($1,$2,$3)
         ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
        [politicianId, topicId, value]);
      answers++;
      await pool.query(
        `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources`,
        [politicianId, topicId, r.reasoning, sources]);
      contexts++;
    } catch (e: any) {
      errors.push(`${fullName}/${r.topic_key}: ${e.message}`);
    }
  }

  stampedIds.push(politicianId);
  console.log(`OK ${fullName} -> ${politicianId} (${rows.length} stances)`);
}

// Stamp research timestamp
if (stampedIds.length) {
  await pool.query(
    `UPDATE essentials.politicians SET last_stances_researched_at = now() WHERE id = ANY($1::uuid[])`,
    [stampedIds]);
}

console.log(`\nSUMMARY: politicians_created=${polCreated} reused=${polReused} race_candidates_linked=${linked} answers=${answers} contexts=${contexts} stamped=${stampedIds.length} errors=${errors.length}`);
if (errors.length) { errors.forEach(e => console.log('  ERR ' + e)); process.exitCode = 1; }
await pool.end();

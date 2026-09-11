/**
 * Apply the Nashville Metro Council stance pass (Banner 2023 Voter's Guide questionnaires).
 *
 *   npx tsx scripts/apply-nashville-metro-council-stances.ts [--dry-run]
 *
 * CSV columns: politician_id,topic_id,topic_key,value,notes,source_url
 *
 * Unlike the older per-person apply scripts, this one sets season_id and topic_revision_id.
 * Both are populated on 100% of the existing 35,877 answers, so leaving them NULL would make
 * these the only seasonless rows in the corpus. season = the currently OPEN season;
 * topic_revision = THE REVISION THAT SEASON PINS in inform.season_questions -- NOT the row
 * flagged is_current. The two differ in practice: for 4 of these 10 topics Season 2 pins
 * revision 1 while is_current is revision 3 or 4, and the pin FK rejects the is_current id.
 *
 * This is currently the ONLY applier in the repo that handles the seasons schema. The other
 * ~148 apply-*-stances.ts scripts predate it and will fail against it on two counts: they
 * use ON CONFLICT (politician_id, topic_id) when the PK is now
 * (politician_id, topic_id, season_id), and they leave season_id/topic_revision_id NULL.
 * Port from this file, not from them.
 *
 * It also takes the source from its own `source_url` column rather than regexing a URL out of
 * the notes: every one of these rows cites a page that was actually fetched, and a stance row
 * whose source array is empty is exactly the unverifiable-evidence defect the corpus audits for.
 */
import 'dotenv/config';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import pg from 'pg';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DRY = process.argv.includes('--dry-run');
// Optional CSV path arg so later passes over the same city reuse this applier rather than
// forking it -- a fork is how the other ~148 drifted out of sync with the schema.
const ARG = process.argv.slice(2).find((a) => !a.startsWith('--'));
const CSV = ARG
  ? path.resolve(ARG)
  : path.join(__dirname, '..', 'data', 'stance-research',
              '2026-09-11-nashville-metro-council-pilot.csv');

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  const rows = parse(readFileSync(CSV, 'utf8'), { columns: true, skip_empty_lines: true }) as
    Array<Record<string, string>>;

  const bad = rows.filter((r) => !/^[1-5]$/.test(r.value) || !r.source_url || !r.politician_id);
  if (bad.length) throw new Error(`${bad.length} malformed row(s); first: ${JSON.stringify(bad[0])}`);

  const { rows: seasons } = await pool.query(
    `SELECT id, name FROM inform.seasons WHERE status = 'open'`);
  if (seasons.length !== 1) throw new Error(`expected exactly 1 open season, got ${seasons.length}`);
  const seasonId = seasons[0].id as string;
  console.log(`season: ${seasons[0].name} (${seasonId})`);
  console.log(`${rows.length} rows for ${new Set(rows.map((r) => r.politician_id)).size} politicians`);

  if (DRY) { console.log('DRY RUN — nothing written.'); await pool.end(); return; }

  const client = await pool.connect();
  let answers = 0, contexts = 0;
  try {
    await client.query('BEGIN');
    for (const r of rows) {
      // The pin FK is (season_id, topic_id, topic_revision_id) -> season_questions, so the
      // revision must be the one THIS SEASON pins, not merely the is_current row: for 4 of
      // these 10 topics Season 2 pins revision 1 while is_current is revision 3 or 4.
      // Chair TEXT is unaffected either way - inform.compass_stances has no revision column,
      // so the wording seated against is the single live chair text.
      const rev = await client.query(
        `SELECT topic_revision_id AS id FROM inform.season_questions
          WHERE season_id = $1 AND topic_id = $2`,
        [seasonId, r.topic_id]);
      if (rev.rowCount !== 1) {
        throw new Error(`topic ${r.topic_key} is not in the open season's question set`);
      }
      const revisionId = rev.rows[0].id as string;

      const a = await client.query(
        `INSERT INTO inform.politician_answers
           (politician_id, topic_id, value, season_id, topic_revision_id)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (politician_id, topic_id, season_id)
         DO UPDATE SET value = EXCLUDED.value,
                       season_id = EXCLUDED.season_id,
                       topic_revision_id = EXCLUDED.topic_revision_id`,
        [r.politician_id, r.topic_id, parseInt(r.value, 10), seasonId, revisionId]);
      answers += a.rowCount ?? 0;

      const c = await client.query(
        `INSERT INTO inform.politician_context
           (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (politician_id, topic_id, season_id)
         DO UPDATE SET reasoning = EXCLUDED.reasoning,
                       sources = EXCLUDED.sources,
                       season_id = EXCLUDED.season_id,
                       topic_revision_id = EXCLUDED.topic_revision_id`,
        [r.politician_id, r.topic_id, r.notes, [r.source_url], seasonId, revisionId]);
      contexts += c.rowCount ?? 0;
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
  console.log(`answers upserted: ${answers}, context upserted: ${contexts}`);
  await pool.end();
}

main().catch((err) => { console.error(err); process.exit(1); });

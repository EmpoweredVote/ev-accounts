/**
 * Load photo URLs for UT 2026 primary candidates from the research TSV.
 *
 * Source: data/election-research/2026-06-23-ut-candidate-photos.tsv
 *
 * For linked candidates (race_candidates.politician_id IS NOT NULL):
 *   - Sets essentials.politicians.photo_origin_url (only if no photo already set)
 *   - getPoliticianById returns this as fallback when politician_images is empty
 *
 * For unlinked challengers (no politician_id):
 *   - Sets race_candidates.photo_url (only if currently NULL)
 *   - getCandidateById uses COALESCE(rc.photo_url, pi.url) so this surfaces immediately
 *
 * Idempotent: both UPDATE paths guard on NULL so re-running is safe.
 * Rows with empty photo_source_url are silently skipped.
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';

const TSV_PATH = join(process.cwd(), 'data/election-research/2026-06-23-ut-candidate-photos.tsv');

type TsvRow = {
  race_candidate_id: string;
  politician_id_tsv: string; // may be stale — always re-query from DB
  full_name: string;
  photo_source_url: string;
  source_url: string;
  notes: string;
};

function parseTsv(path: string): TsvRow[] {
  const lines = readFileSync(path, 'utf8').split('\n').filter(Boolean);
  const headers = lines[0].split('\t');
  return lines.slice(1).map(line => {
    const cols = line.split('\t');
    return {
      race_candidate_id: cols[0]?.trim() ?? '',
      politician_id_tsv:  cols[1]?.trim() ?? '',
      full_name:          cols[2]?.trim() ?? '',
      photo_source_url:   cols[3]?.trim() ?? '',
      source_url:         cols[4]?.trim() ?? '',
      notes:              cols[5]?.trim() ?? '',
    };
  });
}

const rows = parseTsv(TSV_PATH);
console.log(`Loaded ${rows.length} rows from TSV`);

let linked = 0, unlinked = 0, skippedNoPhoto = 0, skippedAlready = 0, errors = 0;

for (const row of rows) {
  if (!row.race_candidate_id) continue;

  if (!row.photo_source_url) {
    skippedNoPhoto++;
    console.log(`SKIP (no photo)  ${row.full_name}`);
    continue;
  }

  // Always query live politician_id — TSV column may be stale
  const { rows: rcRows } = await pool.query(
    `SELECT politician_id, photo_url FROM essentials.race_candidates WHERE id = $1`,
    [row.race_candidate_id],
  );

  if (!rcRows.length) {
    console.log(`ERR  (rc not found) ${row.full_name} (${row.race_candidate_id})`);
    errors++;
    continue;
  }

  const { politician_id, photo_url: existing_rc_photo } = rcRows[0];

  if (politician_id) {
    // Linked candidate — set photo_origin_url on the politician row
    const result = await pool.query(
      `UPDATE essentials.politicians
          SET photo_origin_url = $1
        WHERE id = $2
          AND photo_origin_url IS NULL
          AND photo_custom_url IS NULL
        RETURNING id`,
      [row.photo_source_url, politician_id],
    );
    if (result.rowCount) {
      linked++;
      console.log(`OK   (linked)   ${row.full_name} -> ${politician_id}`);
    } else {
      skippedAlready++;
      console.log(`SKIP (has photo) ${row.full_name} -> ${politician_id}`);
    }
  } else {
    // Unlinked challenger — set photo_url on race_candidates
    if (existing_rc_photo) {
      skippedAlready++;
      console.log(`SKIP (has photo) ${row.full_name} (unlinked)`);
      continue;
    }
    await pool.query(
      `UPDATE essentials.race_candidates SET photo_url = $1 WHERE id = $2`,
      [row.photo_source_url, row.race_candidate_id],
    );
    unlinked++;
    console.log(`OK   (unlinked)  ${row.full_name} -> ${row.race_candidate_id}`);
  }
}

console.log(`\nSUMMARY: linked_updated=${linked} unlinked_updated=${unlinked} skipped_no_photo=${skippedNoPhoto} skipped_already_set=${skippedAlready} errors=${errors}`);
await pool.end();

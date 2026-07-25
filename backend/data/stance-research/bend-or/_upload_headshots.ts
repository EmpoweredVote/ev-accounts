/**
 * Upload processed Bend, OR headshots to the politician_photos bucket and register
 * essentials.politician_images rows.
 *
 * Idempotent: storage upload uses x-upsert, the image row insert is NOT EXISTS-guarded.
 *
 * Patti Adair special case: migration 1415 merged her duplicate identity (-410501 -> -4101703)
 * and repointed the old campaign-sourced image row, whose URL still embeds the RETIRED
 * politician uuid. Uploading her official county portrait would otherwise leave two image rows,
 * so any row for her that does not match the canonical `<uuid>-headshot.jpg` path is removed.
 *
 * Run: node --import tsx data/stance-research/bend-or/_upload_headshots.ts
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const DIR = 'data/stance-research/bend-or/headshots';
const PROJECT = 'kxsdzaojfaibhuzmclfq';
const STORAGE_UPLOAD = `https://${PROJECT}.supabase.co/storage/v1/object/politician_photos/`;
const CDN = `https://${PROJECT}.storage.supabase.co/storage/v1/object/public/politician_photos/`;
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

type Row = {
  external_id: number;
  full_name: string;
  source_page: string;
  license: string;
  file: string;
  ok: boolean;
};

(async () => {
  const review: Row[] = JSON.parse(readFileSync(`${DIR}/_review.json`, 'utf8')).filter((r: Row) => r.ok);
  const exts = review.map((r) => r.external_id);
  const pr = await pool.query(
    `SELECT external_id, id FROM essentials.politicians WHERE external_id = ANY($1::bigint[])`,
    [exts],
  );
  const polId = new Map<number, string>(pr.rows.map((r: any) => [parseInt(r.external_id, 10), r.id]));

  let uploaded = 0;
  let inserted = 0;
  let skipped = 0;
  let pruned = 0;

  for (const r of review) {
    const pid = polId.get(r.external_id);
    if (!pid) {
      console.log(`SKIP ${r.full_name}: no politician row for ${r.external_id}`);
      skipped++;
      continue;
    }
    const filename = `${pid}-headshot.jpg`;
    const bytes = readFileSync(`${DIR}/${r.file}`);
    const up = await fetch(STORAGE_UPLOAD + filename, {
      method: 'POST',
      headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'image/jpeg', 'x-upsert': 'true' },
      body: bytes,
    });
    if (!up.ok) {
      console.log(`UPLOAD FAIL ${r.full_name}: ${up.status} ${await up.text()}`);
      skipped++;
      continue;
    }
    uploaded++;
    const url = CDN + filename;

    // drop any stale image row for this politician that points somewhere else (Adair merge)
    const del = await pool.query(
      `DELETE FROM essentials.politician_images WHERE politician_id = $1 AND url <> $2`,
      [pid, url],
    );
    if (del.rowCount) pruned += del.rowCount;

    await pool.query(
      `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
       SELECT $1, $2, 'default', $3
       WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = $1 AND url = $2)`,
      [pid, url, r.license],
    );
    await pool.query(
      `UPDATE essentials.politicians SET photo_origin_url = $2
       WHERE id = $1 AND photo_origin_url IS DISTINCT FROM $2`,
      [pid, r.source_page],
    );
    inserted++;
    console.log(`OK ${r.full_name.padEnd(24)} -> ${filename}`);
  }
  console.log(`\nUploaded ${uploaded}, image rows ${inserted}, stale rows pruned ${pruned}, skipped ${skipped}.`);
  await pool.end();
})();

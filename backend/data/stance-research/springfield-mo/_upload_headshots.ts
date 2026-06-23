import 'dotenv/config';
import { readFileSync } from 'fs';
import { Pool } from 'pg';

const DIR = 'data/stance-research/springfield-mo/headshots';
const PROJECT = 'kxsdzaojfaibhuzmclfq';
const STORAGE_UPLOAD = `https://${PROJECT}.supabase.co/storage/v1/object/politician_photos/`;
const CDN = `https://${PROJECT}.storage.supabase.co/storage/v1/object/public/politician_photos/`;
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

(async () => {
  const review: any[] = JSON.parse(readFileSync(`${DIR}/_review.json`, 'utf8')).filter((r:any)=>r.ok);
  const exts = review.map(r=>r.external_id);
  const pr = await pool.query(`SELECT external_id, id FROM essentials.politicians WHERE external_id = ANY($1::bigint[])`, [exts]);
  const polId = new Map<number,string>(pr.rows.map((r:any)=>[parseInt(r.external_id), r.id]));

  let uploaded=0, inserted=0, skipped=0;
  for (const r of review) {
    const pid = polId.get(r.external_id);
    if (!pid) { console.log(`SKIP ${r.full_name}: no politician row`); skipped++; continue; }
    const filename = `${pid}-headshot.jpg`;
    const bytes = readFileSync(`${DIR}/${r.external_id}.jpg`);
    // upload (upsert)
    const up = await fetch(STORAGE_UPLOAD + filename, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${KEY}`, 'Content-Type': 'image/jpeg', 'x-upsert': 'true' },
      body: bytes,
    });
    if (!up.ok) { console.log(`UPLOAD FAIL ${r.full_name}: ${up.status} ${await up.text()}`); skipped++; continue; }
    uploaded++;
    const url = CDN + filename;
    // insert image row only if not already present for this url
    await pool.query(`
      INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
      SELECT $1,$2,'default',$3
      WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id=$1 AND url=$2)`,
      [pid, url, r.license]);
    await pool.query(`UPDATE essentials.politicians SET photo_origin_url=$2 WHERE id=$1 AND photo_origin_url IS DISTINCT FROM $2`,
      [pid, r.source_page]);
    inserted++;
    console.log(`OK ${r.full_name.padEnd(22)} -> ${filename}`);
  }
  console.log(`\nUploaded ${uploaded}, image rows ${inserted}, skipped ${skipped}.`);
  await pool.end();
})();

#!/usr/bin/env -S npx tsx
/**
 * backfill-politician-photos.ts
 *
 * Downloads photos from photo_origin_url for politicians who have an external
 * URL but no entry in essentials.politician_images, then re-hosts them on
 * Supabase Storage and inserts politician_images records.
 *
 *   npx tsx backend/scripts/backfill-politician-photos.ts              # dry run
 *   npx tsx backend/scripts/backfill-politician-photos.ts --write      # apply
 *   npx tsx backend/scripts/backfill-politician-photos.ts --write --limit 20
 *
 * Safe: only inserts politician_images where none exist. Never overwrites.
 * Skips politicians where the download fails (logs and continues).
 */
import 'dotenv/config';
import pg from 'pg';

import { EMPOWERED_VOTE_UA } from '../src/lib/fetchPageContent.js';

const WRITE = process.argv.includes('--write');
const LIMIT_IDX = process.argv.indexOf('--limit');
const LIMIT = LIMIT_IDX >= 0 ? parseInt(process.argv[LIMIT_IDX + 1] ?? '999999', 10) : 999999;

const SUPABASE_URL = process.env.SUPABASE_URL!;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const BUCKET = 'politician_photos';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

// Honest, contactable user-agent (see EMPOWERED_VOTE_UA / decision 0003 rung 0).
// Verified 2026-09-01 that the government/CDN photo hosts in this corpus
// (ncleg.gov, sboe.dc.gov, S3, Google Cloud Storage, Squarespace/Wix CDNs,
// CivicEngine, Wikimedia) serve identical bytes under this UA and the old spoof.
const FETCH_HEADERS = {
  'User-Agent': EMPOWERED_VOTE_UA,
  Accept: 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
};

async function fetchImage(url: string): Promise<{ data: Buffer; contentType: string } | null> {
  try {
    const res = await fetch(url, { headers: FETCH_HEADERS, redirect: 'follow', signal: AbortSignal.timeout(15_000) });
    if (!res.ok) {
      console.log(`  ✗ HTTP ${res.status} — ${url}`);
      return null;
    }
    const contentType = res.headers.get('content-type') ?? 'image/jpeg';
    // Reject HTML pages masquerading as images
    if (contentType.includes('text/html')) {
      console.log(`  ✗ Got HTML (page URL, not direct image) — ${url}`);
      return null;
    }
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length < 1000) {
      console.log(`  ✗ Response too small (${buf.length} bytes) — ${url}`);
      return null;
    }
    return { data: buf, contentType };
  } catch (err: unknown) {
    console.log(`  ✗ Fetch error — ${url} — ${(err as Error).message}`);
    return null;
  }
}

async function uploadToStorage(politicianId: string, data: Buffer, contentType: string): Promise<string | null> {
  const path = `${politicianId}/default.jpg`;
  const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${path}`;

  const res = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      'Content-Type': contentType,
    },
    body: data,
  });

  if (!res.ok) {
    const body = await res.text();
    console.log(`  ✗ Storage upload failed (${res.status}): ${body}`);
    return null;
  }

  return `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${path}`;
}

async function run() {
  const client = await pool.connect();
  try {
    // Fetch politicians with external photo_origin_url and no politician_images entry
    const { rows } = await client.query<{ id: string; full_name: string; photo_origin_url: string }>(`
      SELECT p.id, p.full_name, p.photo_origin_url
      FROM essentials.politicians p
      WHERE p.is_active = true
        AND p.photo_origin_url IS NOT NULL
        AND p.photo_origin_url NOT IN ('', 'explored', 'searched:no_results')
        AND p.photo_origin_url NOT LIKE 'searched:%'
        AND p.photo_origin_url LIKE 'http%'
        AND NOT EXISTS (
          SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id
        )
      ORDER BY p.full_name
      LIMIT $1
    `, [LIMIT]);

    console.log(`\nFound ${rows.length} politicians with external-only photos (limit: ${LIMIT})`);
    if (!WRITE) console.log('DRY RUN — pass --write to apply\n');

    let success = 0, skipped = 0, failed = 0;

    for (const pol of rows) {
      console.log(`\n[${success + skipped + failed + 1}/${rows.length}] ${pol.full_name}`);
      console.log(`  URL: ${pol.photo_origin_url}`);

      if (!WRITE) {
        console.log('  → dry run, skipping download');
        skipped++;
        continue;
      }

      const img = await fetchImage(pol.photo_origin_url);
      if (!img) { failed++; continue; }

      console.log(`  ↓ Downloaded ${img.data.length} bytes (${img.contentType})`);

      const publicUrl = await uploadToStorage(pol.id, img.data, img.contentType);
      if (!publicUrl) { failed++; continue; }

      console.log(`  ↑ Uploaded → ${publicUrl}`);

      await client.query(`
        INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
        VALUES ($1, $2, 'default', '')
        ON CONFLICT DO NOTHING
      `, [pol.id, publicUrl]);

      console.log('  ✓ Inserted politician_images record');
      success++;

      // Brief pause to avoid hammering origin servers
      await new Promise(r => setTimeout(r, 300));
    }

    console.log(`\n── Summary ──`);
    console.log(`  Success:  ${success}`);
    console.log(`  Skipped:  ${skipped} (dry run)`);
    console.log(`  Failed:   ${failed}`);
    console.log(`  Total:    ${rows.length}`);
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch(err => { console.error(err); process.exit(1); });

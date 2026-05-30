// Phase 133 / D-06 — fetch source photo, re-host to Supabase Storage, dual-write to DB.
// Pattern source: ev-accounts/backend/scripts/import-123-photo-expansion.ts:100-308.
import { createClient } from '@supabase/supabase-js';
import type { PoolClient } from 'pg';

const BUCKET = 'politician_photos';

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } },
);

async function fetchImageBytes(url: string): Promise<Buffer> {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} fetching ${url}`);
  const ct = r.headers.get('content-type') ?? '';
  if (!ct.startsWith('image/')) {
    throw new Error(`Non-image content-type ${ct} from ${url}`);
  }
  return Buffer.from(await r.arrayBuffer());
}

function detectExt(url: string): { ext: string; contentType: string } {
  const m = url.toLowerCase().match(/\.(png|gif|webp|jpg|jpeg)(?:\?|$)/);
  const raw = m?.[1] ?? 'jpg';
  const ext = raw === 'jpeg' ? 'jpg' : raw;
  const contentType =
    ext === 'png' ? 'image/png' :
    ext === 'gif' ? 'image/gif' :
    ext === 'webp' ? 'image/webp' :
    'image/jpeg';
  return { ext, contentType };
}

let _hasUniqueIdx: boolean | null = null;
async function detectUniqueConstraint(client: PoolClient): Promise<boolean> {
  if (_hasUniqueIdx !== null) return _hasUniqueIdx;
  const { rowCount } = await client.query(
    `SELECT 1 FROM pg_indexes
      WHERE schemaname='essentials' AND tablename='politician_images'
        AND indexdef ILIKE '%UNIQUE%politician_id%type%'
      LIMIT 1`,
  );
  _hasUniqueIdx = (rowCount ?? 0) > 0;
  return _hasUniqueIdx;
}

/**
 * Fetches sourceUrl, uploads to politician_photos/ut/{externalIdAbs}.{ext},
 * dual-writes to essentials.politician_images + essentials.politicians.photo_custom_url.
 * Returns the public CDN URL, or null on fetch failure (caller continues silently per D-06).
 */
export async function rehostPhoto(
  client: PoolClient,
  politicianId: string,
  externalId: number,
  sourceUrl: string | null,
): Promise<string | null> {
  if (!sourceUrl) return null;
  let bytes: Buffer;
  try {
    bytes = await fetchImageBytes(sourceUrl);
  } catch (e) {
    console.warn(`[photo] skip ${politicianId} (${sourceUrl}): ${(e as Error).message}`);
    return null;
  }

  const { ext, contentType } = detectExt(sourceUrl);
  const externalIdAbs = Math.abs(externalId);
  const filePath = `ut/${externalIdAbs}.${ext}`;

  const { error: upErr } = await supabaseAdmin.storage
    .from(BUCKET)
    .upload(filePath, bytes, { contentType, upsert: true });
  if (upErr) throw new Error(`Storage upload failed for ${filePath}: ${upErr.message}`);

  const { data: { publicUrl } } = supabaseAdmin.storage.from(BUCKET).getPublicUrl(filePath);

  const hasUnique = await detectUniqueConstraint(client);
  if (hasUnique) {
    await client.query(
      `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
       VALUES ($1, $2, 'default', 'sourced')
       ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url`,
      [politicianId, publicUrl],
    );
  } else {
    await client.query(
      `DELETE FROM essentials.politician_images WHERE politician_id = $1 AND type = 'default'`,
      [politicianId],
    );
    await client.query(
      `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
       VALUES ($1, $2, 'default', 'sourced')`,
      [politicianId, publicUrl],
    );
  }

  // Dual write (Pitfall 2 of import-123): some renderers read photo_custom_url directly.
  await client.query(
    `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
    [publicUrl, politicianId],
  );

  return publicUrl;
}

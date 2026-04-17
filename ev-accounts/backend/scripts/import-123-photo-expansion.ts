/**
 * import-123-photo-expansion.ts -- Phase 123 Plan 01 import script
 *
 * Photo-only import. Reads approved photo URLs from 123-REVIEW-DATA.md (via JSON
 * sidecar import-123-data.json), downloads each image, uploads to the Supabase
 * Storage bucket `politician_photos`, and performs the dual write:
 *   1. INSERT into `essentials.politician_images` (type='default')  [primary render path]
 *   2. UPDATE `essentials.politicians.photo_custom_url`             [fallback render path]
 *
 * For candidates without a slug, one is derived from `full_name` and written to
 * `essentials.politicians.slug` before the Storage upload path is constructed.
 *
 * Usage:
 *   npx tsx scripts/import-123-photo-expansion.ts              # dry-run
 *   npx tsx scripts/import-123-photo-expansion.ts --commit     # write
 *
 * Patterns from: 120-BIO-METHODOLOGY.md (dual photo write, contentType pitfall)
 * Analog:        import-120-contested-bios-photos.ts
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';
import pg from 'pg';
import { createClient } from '@supabase/supabase-js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

// =============================================================================
// CLI
// =============================================================================

const isCommit = process.argv.includes('--commit');
const isDryRun = !isCommit;

// =============================================================================
// Clients
// =============================================================================

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

const BUCKET = 'politician_photos';

// =============================================================================
// Types
// =============================================================================

interface PhotoImport {
  /** UUID from essentials.politicians */
  politician_id: string;
  /** Display name for logging */
  full_name: string;
  /**
   * Slug for the Supabase Storage path. If the politician has no slug in the
   * DB, provide a derived value here and set write_slug = true.
   */
  slug: string;
  /**
   * Direct URL to download the source image from.
   * null / empty string means NO_PHOTO — skip this candidate.
   */
  photo_source_url: string | null;
  /**
   * If true, the slug provided here will be written to politicians.slug in
   * the same transaction (candidate currently lacks a slug).
   */
  write_slug?: boolean;
}

// =============================================================================
// Helpers
// =============================================================================

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUuid(value: string): boolean {
  return UUID_RE.test(value);
}

/** Derive a URL-safe slug from a full name */
function deriveSlug(fullName: string): string {
  return fullName
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-');
}

async function fetchImageBytes(url: string): Promise<Buffer> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} fetching image: ${url}`);
  }
  const arrayBuffer = await response.arrayBuffer();
  return Buffer.from(arrayBuffer);
}

function detectExt(url: string): { ext: string; contentType: string } {
  const match = url.toLowerCase().match(/\.(png|gif|webp|jpg|jpeg)(?:\?|$)/);
  const raw = match?.[1] ?? 'jpg';
  const ext = raw === 'jpeg' ? 'jpg' : raw;
  const contentType =
    ext === 'png'
      ? 'image/png'
      : ext === 'gif'
        ? 'image/gif'
        : ext === 'webp'
          ? 'image/webp'
          : 'image/jpeg';
  return { ext, contentType };
}

// =============================================================================
// Pre-flight constraint check
// =============================================================================

async function detectUniqueConstraint(): Promise<boolean> {
  const constraintCheck = await pool.query(
    `SELECT 1 FROM pg_constraint
     WHERE conrelid = 'essentials.politician_images'::regclass
       AND contype = 'u'
       AND array_length(conkey, 1) = 2
     LIMIT 1`,
  );
  const hasUniqueConstraint = constraintCheck.rows.length > 0;
  console.log(
    hasUniqueConstraint
      ? '[info] politician_images unique constraint found -- using ON CONFLICT upsert'
      : '[info] politician_images unique constraint NOT found -- using DELETE+INSERT pattern',
  );
  return hasUniqueConstraint;
}

// =============================================================================
// Per-candidate processing
// =============================================================================

interface Stats {
  processed: number;
  photosUploaded: number;
  slugsWritten: number;
  skipped: number;
  errors: number;
}

async function processCandidate(
  candidate: PhotoImport,
  hasUniqueConstraint: boolean,
  stats: Stats,
): Promise<void> {
  stats.processed++;

  // Validation
  if (!isUuid(candidate.politician_id)) {
    console.error(
      `[error] ${candidate.full_name}: invalid politician_id UUID`,
    );
    stats.errors++;
    return;
  }

  // Skip NO_PHOTO entries
  if (!candidate.photo_source_url) {
    console.log(`[skip] ${candidate.full_name} -- NO_PHOTO`);
    stats.skipped++;
    return;
  }

  // Determine effective slug (write_slug path or use provided)
  let slug = candidate.slug;
  if (!slug) {
    slug = deriveSlug(candidate.full_name);
    console.log(
      `[info] ${candidate.full_name}: no slug provided, derived: ${slug}`,
    );
  }

  // Pre-flight: check current DB state
  const { rows } = await pool.query<{
    has_photo: boolean;
    current_slug: string | null;
  }>(
    `SELECT
       (EXISTS (SELECT 1 FROM essentials.politician_images pi
                WHERE pi.politician_id = p.id AND pi.type = 'default')) AS has_photo,
       p.slug AS current_slug
     FROM essentials.politicians p WHERE p.id = $1`,
    [candidate.politician_id],
  );
  const existing = rows[0];
  if (!existing) {
    console.error(
      `[error] ${candidate.full_name}: politician_id not found in essentials.politicians`,
    );
    stats.errors++;
    return;
  }

  if (existing.has_photo) {
    console.log(
      `[skip] ${candidate.full_name} -- already has a default photo`,
    );
    stats.skipped++;
    return;
  }

  const needsSlug = candidate.write_slug === true && !existing.current_slug;

  if (isDryRun) {
    const actions: string[] = [`photo=${candidate.photo_source_url}`];
    if (needsSlug) actions.push(`slug=${slug}`);
    console.log(`[dry-run] ${candidate.full_name} -> ${actions.join(', ')}`);
    stats.photosUploaded++;
    if (needsSlug) stats.slugsWritten++;
    return;
  }

  // COMMIT path -- per-candidate transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Optional slug write
    if (needsSlug) {
      await client.query(
        `UPDATE essentials.politicians SET slug = $1 WHERE id = $2`,
        [slug, candidate.politician_id],
      );
    }

    // Download + upload image
    const imageBytes = await fetchImageBytes(candidate.photo_source_url);
    const { ext, contentType } = detectExt(candidate.photo_source_url);
    const filePath = `phase123_2026/${slug}.${ext}`;

    // NEVER omit contentType -- Pitfall 7 (see 120-BIO-METHODOLOGY.md)
    const { error: uploadError } = await supabaseAdmin.storage
      .from(BUCKET)
      .upload(filePath, imageBytes, {
        contentType,
        upsert: true,
      });
    if (uploadError) {
      throw new Error(`Storage upload failed: ${uploadError.message}`);
    }

    const {
      data: { publicUrl },
    } = supabaseAdmin.storage.from(BUCKET).getPublicUrl(filePath);

    // Primary render path -- politician_images row (Pitfall 2)
    if (hasUniqueConstraint) {
      await client.query(
        `INSERT INTO essentials.politician_images
           (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')
         ON CONFLICT (politician_id, type)
         DO UPDATE SET url = EXCLUDED.url`,
        [candidate.politician_id, publicUrl],
      );
    } else {
      await client.query(
        `DELETE FROM essentials.politician_images
         WHERE politician_id = $1 AND type = 'default'`,
        [candidate.politician_id],
      );
      await client.query(
        `INSERT INTO essentials.politician_images
           (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')`,
        [candidate.politician_id, publicUrl],
      );
    }

    // Fallback render path -- photo_custom_url (Pitfall 2)
    await client.query(
      `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
      [publicUrl, candidate.politician_id],
    );

    await client.query('COMMIT');

    const parts = ['photo'];
    if (needsSlug) parts.push('slug');
    console.log(`[ok] ${candidate.full_name} [${parts.join('+')}] -> ${publicUrl}`);
    stats.photosUploaded++;
    if (needsSlug) stats.slugsWritten++;
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`[error] ${candidate.full_name}:`, (err as Error).message);
    stats.errors++;
  } finally {
    client.release();
  }
}

// =============================================================================
// Main
// =============================================================================

async function main(): Promise<void> {
  console.log('=================================================================');
  console.log('import-123-photo-expansion.ts -- Phase 123 Plan 02');
  console.log('=================================================================');
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no DB writes)' : 'COMMIT'}`);

  const dataPath = path.resolve(__dirname, 'import-123-data.json');
  if (!fs.existsSync(dataPath)) {
    throw new Error(
      `Data file not found: ${dataPath}\n` +
        'Run export-123-review-data.ts to generate import-123-data.json from the approved REVIEW-DATA.',
    );
  }
  const raw = fs.readFileSync(dataPath, 'utf-8');
  const importData: PhotoImport[] = JSON.parse(raw);
  const withPhotos = importData.filter((c) => !!c.photo_source_url);
  console.log(
    `Loaded ${importData.length} candidate(s); ${withPhotos.length} have a photo URL to upload`,
  );

  const hasUniqueConstraint = await detectUniqueConstraint();

  const stats: Stats = {
    processed: 0,
    photosUploaded: 0,
    slugsWritten: 0,
    skipped: 0,
    errors: 0,
  };

  for (const candidate of importData) {
    await processCandidate(candidate, hasUniqueConstraint, stats);
  }

  console.log('');
  console.log(
    `[done] ${stats.processed} candidates processed, ` +
      `${stats.photosUploaded} photos uploaded, ` +
      `${stats.slugsWritten} slugs written, ` +
      `${stats.skipped} skipped, ` +
      `${stats.errors} errors`,
  );
  if (isDryRun) {
    console.log('[DRY RUN] No changes written to DB. Rerun with --commit to apply.');
  }

  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', (err as Error).message);
  pool.end().catch(() => undefined);
  process.exit(1);
});

/**
 * import-120-contested-bios-photos.ts -- Phase 120 Plan 03 import script
 *
 * Writes approved bios (UPDATE essentials.politicians.bio_text) and, where a
 * photo_source_url is provided, downloads the photo, uploads to the Supabase
 * Storage bucket `politician_photos`, and INSERTs a `politician_images` row
 * (type='default') + UPDATEs `photo_custom_url` (dual write -- Pitfall 2).
 *
 * Usage:
 *   npx tsx scripts/import-120-contested-bios-photos.ts              # dry-run
 *   npx tsx scripts/import-120-contested-bios-photos.ts --commit     # write
 *
 * Patterns from: 120-PATTERNS.md (transaction-per-candidate, dual photo write)
 * Analog:        importElectionData.ts (dotenv / pg.Pool init, --commit flag)
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

interface CandidateImport {
  politician_id: string;
  full_name: string;
  slug: string;
  bio_text: string;
  photo_source_url: string | null;
}

// =============================================================================
// Helpers
// =============================================================================

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isUuid(value: string): boolean {
  return UUID_RE.test(value);
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
  biosWritten: number;
  photosUploaded: number;
  slugsWritten: number;
  skipped: number;
  errors: number;
}

async function processCandidate(
  candidate: CandidateImport,
  hasUniqueConstraint: boolean,
  stats: Stats,
): Promise<void> {
  stats.processed++;

  // Validation (V5 -- input validation)
  if (!isUuid(candidate.politician_id)) {
    console.error(
      `[error] ${candidate.full_name}: invalid politician_id UUID`,
    );
    stats.errors++;
    return;
  }
  if (!candidate.slug || typeof candidate.slug !== 'string') {
    console.error(`[error] ${candidate.full_name}: invalid/empty slug`);
    stats.errors++;
    return;
  }
  if (candidate.bio_text.length > 180) {
    console.error(
      `[error] ${candidate.full_name} bio too long: ${candidate.bio_text.length} chars`,
    );
    stats.errors++;
    return;
  }

  // Pre-flight: inspect current DB state
  const { rows } = await pool.query<{
    bio_text: string | null;
    slug: string | null;
    has_photo: boolean;
  }>(
    `SELECT p.bio_text,
            p.slug,
            (EXISTS (SELECT 1 FROM essentials.politician_images pi
                     WHERE pi.politician_id = p.id AND pi.type = 'default')) AS has_photo
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

  const needsBio = !existing.bio_text;
  const needsPhoto = !existing.has_photo && !!candidate.photo_source_url;
  const needsSlug = !existing.slug && !!candidate.slug;

  if (!needsBio && !needsPhoto && !needsSlug) {
    console.log(`[skip] ${candidate.full_name} already has bio and photo`);
    stats.skipped++;
    return;
  }

  if (isDryRun) {
    const actions: string[] = [];
    if (needsBio) actions.push(`bio(${candidate.bio_text.length} chars)`);
    if (needsSlug) actions.push(`slug=${candidate.slug}`);
    if (needsPhoto) actions.push(`photo=${candidate.photo_source_url}`);
    console.log(
      `[dry-run] ${candidate.full_name} -> ${actions.join(', ') || 'no-op'}`,
    );
    if (needsBio) stats.biosWritten++;
    if (needsSlug) stats.slugsWritten++;
    if (needsPhoto) stats.photosUploaded++;
    return;
  }

  // COMMIT path -- wrap in a per-candidate transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    if (needsBio) {
      await client.query(
        `UPDATE essentials.politicians
         SET bio_text = $1, updated_at = now()
         WHERE id = $2`,
        [candidate.bio_text, candidate.politician_id],
      );
    }

    if (needsSlug) {
      await client.query(
        `UPDATE essentials.politicians
         SET slug = $1, updated_at = now()
         WHERE id = $2`,
        [candidate.slug, candidate.politician_id],
      );
    }

    if (needsPhoto && candidate.photo_source_url) {
      const imageBytes = await fetchImageBytes(candidate.photo_source_url);
      const { ext, contentType } = detectExt(candidate.photo_source_url);
      const filePath = `monroe_2026/${candidate.slug}.${ext}`;

      // NEVER omit contentType -- Pitfall 7
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

      // Primary render path -- politician_images row
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
        `UPDATE essentials.politicians
         SET photo_custom_url = $1, updated_at = now()
         WHERE id = $2`,
        [publicUrl, candidate.politician_id],
      );
    }

    await client.query('COMMIT');
    const parts: string[] = [];
    if (needsBio) {
      parts.push('bio');
      stats.biosWritten++;
    }
    if (needsSlug) {
      parts.push('slug');
      stats.slugsWritten++;
    }
    if (needsPhoto) {
      parts.push('photo');
      stats.photosUploaded++;
    }
    console.log(`[ok] ${candidate.full_name} [${parts.join('+')}]`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(
      `[error] ${candidate.full_name}:`,
      (err as Error).message,
    );
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
  console.log('import-120-contested-bios-photos.ts -- Phase 120 Plan 03');
  console.log('=================================================================');
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no DB writes)' : 'COMMIT'}`);

  const dataPath = path.resolve(__dirname, 'import-120-data.json');
  if (!fs.existsSync(dataPath)) {
    throw new Error(`Data file not found: ${dataPath}`);
  }
  const raw = fs.readFileSync(dataPath, 'utf-8');
  const importData: CandidateImport[] = JSON.parse(raw);
  console.log(`Loaded ${importData.length} candidate(s) from import-120-data.json`);

  const hasUniqueConstraint = await detectUniqueConstraint();

  const stats: Stats = {
    processed: 0,
    biosWritten: 0,
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
      `${stats.biosWritten} bios written, ` +
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

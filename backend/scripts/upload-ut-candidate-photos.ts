/**
 * upload-ut-candidate-photos.ts
 *
 * Downloads candidate headshots and re-hosts them in Supabase Storage.
 * Reads a TSV file produced by the photo-research workflow.
 *
 * TSV columns (tab-separated, header row):
 *   race_candidate_id  politician_id  full_name  photo_source_url
 *
 * For challengers (politician_id empty):
 *   Uploads to politician_photos/ut/candidates/{race_candidate_id}.{ext}
 *   Sets race_candidates.photo_url = CDN URL
 *
 * For incumbents (politician_id present):
 *   Uploads to politician_photos/{politician_id}/default.{ext}
 *   Upserts essentials.politician_images (type='default', license='sourced')
 *   Updates essentials.politicians.photo_custom_url
 *
 * Usage:
 *   npx tsx scripts/upload-ut-candidate-photos.ts --tsv data/ut-candidate-photos.tsv
 *   npx tsx scripts/upload-ut-candidate-photos.ts --tsv data/ut-candidate-photos.tsv --commit
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';
import pg from 'pg';
import { createClient } from '@supabase/supabase-js';

import { EMPOWERED_VOTE_UA } from '../src/lib/fetchPageContent.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const tsvIdx = args.indexOf('--tsv');
if (tsvIdx === -1 || !args[tsvIdx + 1]) {
  console.error('Usage: npx tsx scripts/upload-ut-candidate-photos.ts --tsv <file> [--commit]');
  process.exit(1);
}
const tsvPath = path.resolve(args[tsvIdx + 1]);

// ---------------------------------------------------------------------------
// Clients
// ---------------------------------------------------------------------------

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } },
);

const BUCKET = 'politician_photos';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CandidatePhoto {
  race_candidate_id: string;
  politician_id: string;
  full_name: string;
  photo_source_url: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const MAGIC: Array<{ sig: number[]; ext: string; ct: string }> = [
  { sig: [0xff, 0xd8, 0xff], ext: 'jpg', ct: 'image/jpeg' },
  { sig: [0x89, 0x50, 0x4e, 0x47], ext: 'png', ct: 'image/png' },
  { sig: [0x52, 0x49, 0x46, 0x46], ext: 'webp', ct: 'image/webp' }, // RIFF…WEBP
  { sig: [0x47, 0x49, 0x46], ext: 'gif', ct: 'image/gif' },
];

function detectFromBytes(buf: Buffer): { ext: string; ct: string } | null {
  for (const { sig, ext, ct } of MAGIC) {
    if (sig.every((b, i) => buf[i] === b)) return { ext, ct };
  }
  return null;
}

function refererFor(url: string): string {
  try { return new URL(url).origin + '/'; } catch { return ''; }
}

async function fetchImage(url: string): Promise<{ bytes: Buffer; contentType: string; ext: string }> {
  const resp = await fetch(url, {
    headers: {
      'User-Agent': EMPOWERED_VOTE_UA,
      'Referer': refererFor(url),
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    },
  });
  if (!resp.ok) throw new Error(`HTTP ${resp.status} for ${url}`);

  const bytes = Buffer.from(await resp.arrayBuffer());
  const ct = (resp.headers.get('content-type') ?? '').split(';')[0].trim();

  const extMap: Record<string, string> = {
    'image/jpeg': 'jpg', 'image/jpg': 'jpg', 'image/png': 'png',
    'image/gif': 'gif', 'image/webp': 'webp',
  };

  // Try URL extension first
  const urlExt = url.toLowerCase().match(/\.(jpg|jpeg|png|gif|webp)(?:\?|$)/)?.[1];
  const extFromUrl = urlExt ? (urlExt === 'jpeg' ? 'jpg' : urlExt) : null;

  // If content-type looks like an image, use it
  if (ct.startsWith('image/')) {
    const ext = extFromUrl ?? extMap[ct] ?? 'jpg';
    return { bytes, contentType: ct, ext };
  }

  // Otherwise (binary/octet-stream, etc) — detect from magic bytes
  const detected = detectFromBytes(bytes);
  if (detected) {
    return { bytes, contentType: detected.ct, ext: extFromUrl ?? detected.ext };
  }

  // Last resort: trust URL extension if present
  if (extFromUrl) {
    const ctGuess = extMap[extFromUrl] ? `image/${extFromUrl === 'jpg' ? 'jpeg' : extFromUrl}` : 'image/jpeg';
    return { bytes, contentType: ctGuess, ext: extFromUrl };
  }

  throw new Error(`Cannot detect image type (ct="${ct}") from ${url}`);
}

async function uploadToStorage(filePath: string, bytes: Buffer, contentType: string): Promise<string> {
  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(filePath, bytes, { contentType, upsert: true });
  if (error) throw new Error(`Storage upload failed for ${filePath}: ${error.message}`);
  const { data: { publicUrl } } = supabase.storage.from(BUCKET).getPublicUrl(filePath);
  return publicUrl;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const raw = fs.readFileSync(tsvPath, 'utf8');
  const lines = raw.trim().split('\n');
  const header = lines[0].split('\t').map(h => h.trim());
  const records: CandidatePhoto[] = lines.slice(1)
    .filter(l => l.trim())
    .map(line => {
      const cols = line.split('\t').map(c => c.trim());
      return {
        race_candidate_id: cols[header.indexOf('race_candidate_id')] ?? '',
        politician_id: cols[header.indexOf('politician_id')] ?? '',
        full_name: cols[header.indexOf('full_name')] ?? '',
        photo_source_url: cols[header.indexOf('photo_source_url')] ?? '',
      };
    })
    .filter(r => r.race_candidate_id && r.photo_source_url);

  console.log(`Loaded ${records.length} candidates from TSV`);
  console.log(`Mode: ${isCommit ? 'COMMIT' : 'DRY RUN'}\n`);

  const client = await pool.connect();
  let ok = 0, skip = 0, fail = 0;

  try {
    for (const rec of records) {
      const isIncumbent = !!rec.politician_id;
      const label = `${rec.full_name} [${isIncumbent ? 'incumbent' : 'challenger'}]`;

      let bytes: Buffer, contentType: string, ext: string;
      try {
        ({ bytes, contentType, ext } = await fetchImage(rec.photo_source_url));
      } catch (e) {
        console.log(`  SKIP ${label}: ${(e as Error).message}`);
        skip++;
        continue;
      }

      const storagePath = isIncumbent
        ? `${rec.politician_id}/default.${ext}`
        : `ut/candidates/${rec.race_candidate_id}.${ext}`;

      console.log(`  ${isCommit ? 'UPLOAD' : 'WOULD UPLOAD'} ${label}`);
      console.log(`    src  : ${rec.photo_source_url}`);
      console.log(`    dest : ${BUCKET}/${storagePath} (${bytes.length} bytes, ${contentType})`);

      if (!isCommit) { ok++; continue; }

      try {
        const cdnUrl = await uploadToStorage(storagePath, bytes, contentType);

        if (isIncumbent) {
          // Check for unique constraint (may not exist on all envs)
          const { rowCount } = await client.query(
            `SELECT 1 FROM pg_indexes
             WHERE schemaname='essentials' AND tablename='politician_images'
               AND indexdef ILIKE '%UNIQUE%politician_id%type%' LIMIT 1`,
          );
          if ((rowCount ?? 0) > 0) {
            await client.query(
              `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
               VALUES ($1, $2, 'default', 'sourced')
               ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url, photo_license = 'sourced'`,
              [rec.politician_id, cdnUrl],
            );
          } else {
            await client.query(
              `DELETE FROM essentials.politician_images WHERE politician_id = $1 AND type = 'default'`,
              [rec.politician_id],
            );
            await client.query(
              `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
               VALUES ($1, $2, 'default', 'sourced')`,
              [rec.politician_id, cdnUrl],
            );
          }
          // Dual-write fallback path
          await client.query(
            `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
            [cdnUrl, rec.politician_id],
          );
        } else {
          // Update race_candidates.photo_url for challengers
          await client.query(
            `UPDATE essentials.race_candidates SET photo_url = $1 WHERE id = $2`,
            [cdnUrl, rec.race_candidate_id],
          );
        }

        console.log(`    CDN  : ${cdnUrl}`);
        ok++;
      } catch (e) {
        console.log(`    FAIL : ${(e as Error).message}`);
        fail++;
      }
    }
  } finally {
    client.release();
    await pool.end();
  }

  console.log(`\nDone: ${ok} ok, ${skip} skipped (bad URL), ${fail} failed`);
  if (!isCommit) console.log('\nRe-run with --commit to apply.');
}

main().catch(e => { console.error(e); process.exit(1); });

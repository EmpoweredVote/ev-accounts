/**
 * import-utah-state-exec-photos.ts
 *
 * One-off: re-host headshots for the 5 Utah STATE_EXEC officials that had no
 * politician_images row (Governor, Lt. Governor, Attorney General, Treasurer,
 * Auditor). Mirrors the pattern in scripts/lib/photo-rehost.ts and
 * scripts/upload-ut-candidate-photos.ts.
 *
 * For each official:
 *   - fetch source headshot
 *   - upload to politician_photos/{politician_id}/default.{ext}
 *   - replace essentials.politician_images (type='default')
 *   - dual-write essentials.politicians.photo_custom_url
 *
 * Sources + licenses (attribution noted for CC-licensed images):
 *   Spencer Cox      CC BY-SA 4.0  Gage Skidmore (Wikimedia Commons)
 *   Deidre Henderson CC0 / PD      official state portrait (Wikimedia Commons)
 *   Derek Brown      CC BY 4.0     Legalcomms17 (Wikimedia Commons)
 *   Marlo Oaks       official .gov treasurer.utah.gov
 *   Tina Cannon      official .gov auditor.utah.gov
 *
 * Usage:
 *   npx tsx scripts/import-utah-state-exec-photos.ts            # dry run
 *   npx tsx scripts/import-utah-state-exec-photos.ts --commit   # apply
 */

import * as path from 'path';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';
import pg from 'pg';
import { createClient } from '@supabase/supabase-js';

import { EMPOWERED_VOTE_UA } from '../src/lib/fetchPageContent.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const isCommit = process.argv.slice(2).includes('--commit');

const BUCKET = 'politician_photos';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } },
);

interface Target {
  politician_id: string;
  name: string;
  office: string;
  source_url: string;
  photo_license: string; // existing label vocabulary: public_domain | press_use | sourced
}

const TARGETS: Target[] = [
  {
    politician_id: 'b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6',
    name: 'Spencer Cox',
    office: 'Governor',
    source_url:
      'https://upload.wikimedia.org/wikipedia/commons/9/94/Spencer_Cox_-_54856206905_%28cropped%29.jpg',
    photo_license: 'sourced', // CC BY-SA 4.0, Gage Skidmore
  },
  {
    politician_id: 'f72689da-fe02-4bdd-977f-bb7760a42fb2',
    name: 'Deidre Henderson',
    office: 'Lieutenant Governor',
    source_url:
      'https://upload.wikimedia.org/wikipedia/commons/5/5b/Official_portrait_of_Utah_Lt._Gov._Deidre_Henderson.png',
    photo_license: 'public_domain', // CC0
  },
  {
    politician_id: '1844a5e3-8ea5-4ee5-9377-066378b25b49',
    name: 'Derek Brown',
    office: 'Attorney General',
    source_url:
      'https://upload.wikimedia.org/wikipedia/commons/d/d2/Utah_Attorney_General_Derek_Brown_in_the_Gold_Room.png',
    photo_license: 'sourced', // CC BY 4.0, Legalcomms17
  },
  {
    politician_id: '919b82e8-bac3-428f-9896-423832e4538f',
    name: 'Marlo Oaks',
    office: 'State Treasurer',
    source_url:
      'https://treasurer.utah.gov/wp-content/uploads/Utah-Treasurer-Marlo-Oaks_White-Background-1-1-scaled.jpg',
    photo_license: 'sourced',
  },
  {
    politician_id: '9eac661a-e4c5-4bdf-9883-ee612dab53a8',
    name: 'Tina Cannon',
    office: 'State Auditor',
    source_url:
      'https://storage.googleapis.com/wp-media-osa/b99c7677-meet-auditor-tina-m-cannon-scaled.jpg',
    photo_license: 'sourced',
  },
];

const MAGIC: Array<{ sig: number[]; ext: string; ct: string }> = [
  { sig: [0xff, 0xd8, 0xff], ext: 'jpg', ct: 'image/jpeg' },
  { sig: [0x89, 0x50, 0x4e, 0x47], ext: 'png', ct: 'image/png' },
  { sig: [0x52, 0x49, 0x46, 0x46], ext: 'webp', ct: 'image/webp' },
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

  const urlExt = url.toLowerCase().match(/\.(jpg|jpeg|png|gif|webp)(?:\?|$)/)?.[1];
  const extFromUrl = urlExt ? (urlExt === 'jpeg' ? 'jpg' : urlExt) : null;

  const detected = detectFromBytes(bytes);
  if (detected) return { bytes, contentType: detected.ct, ext: extFromUrl ?? detected.ext };

  if (ct.startsWith('image/')) {
    const extMap: Record<string, string> = {
      'image/jpeg': 'jpg', 'image/png': 'png', 'image/gif': 'gif', 'image/webp': 'webp',
    };
    return { bytes, contentType: ct, ext: extFromUrl ?? extMap[ct] ?? 'jpg' };
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

async function main() {
  console.log(`Utah STATE_EXEC headshots — ${TARGETS.length} officials`);
  console.log(`Mode: ${isCommit ? 'COMMIT' : 'DRY RUN'}\n`);

  const client = await pool.connect();
  let ok = 0, skip = 0, fail = 0;

  try {
    for (const t of TARGETS) {
      const label = `${t.name} (${t.office})`;

      let bytes: Buffer, contentType: string, ext: string;
      try {
        ({ bytes, contentType, ext } = await fetchImage(t.source_url));
      } catch (e) {
        console.log(`  SKIP ${label}: ${(e as Error).message}`);
        skip++;
        continue;
      }

      const storagePath = `${t.politician_id}/default.${ext}`;
      console.log(`  ${isCommit ? 'UPLOAD' : 'WOULD UPLOAD'} ${label}`);
      console.log(`    src  : ${t.source_url}`);
      console.log(`    dest : ${BUCKET}/${storagePath} (${bytes.length} bytes, ${contentType}, license=${t.photo_license})`);

      if (!isCommit) { ok++; continue; }

      try {
        const cdnUrl = await uploadToStorage(storagePath, bytes, contentType);

        // No UNIQUE(politician_id, type) on prod → replace-by-delete.
        await client.query(
          `DELETE FROM essentials.politician_images WHERE politician_id = $1 AND type = 'default'`,
          [t.politician_id],
        );
        await client.query(
          `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
           VALUES ($1, $2, 'default', $3)`,
          [t.politician_id, cdnUrl, t.photo_license],
        );
        await client.query(
          `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
          [cdnUrl, t.politician_id],
        );

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

  console.log(`\nDone: ${ok} ok, ${skip} skipped, ${fail} failed`);
  if (!isCommit) console.log('\nRe-run with --commit to apply.');
}

main().catch(e => { console.error(e); process.exit(1); });

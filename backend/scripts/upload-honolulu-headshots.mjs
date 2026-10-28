#!/usr/bin/env node
/**
 * Mirror the eleven Honolulu officeholder portraits into Supabase storage.
 *
 * Reads local files from a directory of <slug>.<ext> and uploads them to the
 * `politician_photos` bucket. Prints the public URL of each. Writes NOTHING to the database —
 * CC_0305 does that, using the URLs this prints.
 *
 * 🔴 WE MIRROR RATHER THAN HOTLINK. A council Squarespace CDN URL can be re-cut, re-sized or
 *    expire; one of these eleven already had: HoLIS's own PhotoURL for District I returns 404 at
 *    every size, so the city's GIS is already pointing at a photo that no longer exists.
 *
 * 🔴 SEND BOTH `apikey` AND `Authorization`. A lone Bearer is refused as HTTP 400 with a body of
 *    403 "Invalid Compact JWS", which reads like a missing object and sends you looking in the
 *    wrong place.
 *
 * ⚠ The credential is read from the environment and is never printed, not even in an error.
 *
 *   node scripts/upload-honolulu-headshots.mjs --dir <path> [--dry-run]
 */
import fs from 'node:fs';
import path from 'node:path';

const ARGV = process.argv.slice(2);
const DRY = ARGV.includes('--dry-run');
const DIR = (ARGV.find((a) => a.startsWith('--dir=')) || '').split('=')[1] || null;

const BUCKET = 'politician_photos';
const PREFIX = 'honolulu-2026';

const SUPABASE_URL = process.env.SUPABASE_URL;
const KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const die = (msg) => {
  console.error(`\n❌ ${msg}\n`);
  process.exit(1);
};

if (!DIR) die('pass --dir=<path to the folder of images>');
if (!SUPABASE_URL) die('SUPABASE_URL is not set');
if (!KEY) die('SUPABASE_SERVICE_ROLE_KEY is not set');

const TYPES = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

const files = fs
  .readdirSync(DIR)
  .filter((f) => TYPES[path.extname(f).toLowerCase()])
  .sort();

if (files.length === 0) die(`no images found in ${DIR}`);
console.log(`${files.length} image(s) to mirror into ${BUCKET}/${PREFIX}/\n`);

const results = [];
for (const f of files) {
  const ext = path.extname(f).toLowerCase();
  const key = `${PREFIX}/${f}`;
  const body = fs.readFileSync(path.join(DIR, f));
  const url = `${SUPABASE_URL.replace(/\/$/, '')}/storage/v1/object/${BUCKET}/${key}`;

  if (DRY) {
    console.log(`  would upload ${f.padEnd(28)} ${(body.length / 1024).toFixed(0).padStart(5)} KB -> ${key}`);
    results.push({ file: f, key });
    continue;
  }

  // x-upsert so a re-run replaces rather than 409s.
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      apikey: KEY,
      Authorization: `Bearer ${KEY}`,
      'Content-Type': TYPES[ext],
      'x-upsert': 'true',
    },
    body,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    die(`upload of ${f} failed: HTTP ${res.status} ${text.slice(0, 200)}`);
  }
  console.log(`  uploaded ${f.padEnd(28)} ${(body.length / 1024).toFixed(0).padStart(5)} KB`);
  results.push({ file: f, key });
}

if (DRY) {
  console.log('\n--dry-run: nothing uploaded.');
  process.exit(0);
}

// Read each one back over the PUBLIC url. An upload that returns 200 and is then unreadable is
// the failure mode that matters; the CDN is a different host from the API.
console.log('\nverifying each object over its public URL:');
const base = `${SUPABASE_URL.replace(/\/$/, '')}/storage/v1/object/public/${BUCKET}/`;
let bad = 0;
for (const r of results) {
  const pub = base + r.key;
  const res = await fetch(pub, { method: 'GET' });
  const len = Number(res.headers.get('content-length') || 0);
  const ok = res.ok && len > 2048;
  if (!ok) bad += 1;
  console.log(`  ${ok ? '✓' : '✗'} HTTP ${res.status} ${String(len).padStart(8)} B  ${pub}`);
}
if (bad) die(`${bad} object(s) did not read back`);
console.log(`\n✅ ${results.length} portrait(s) mirrored and readable.`);

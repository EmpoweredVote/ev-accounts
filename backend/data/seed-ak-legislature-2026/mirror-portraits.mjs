/**
 * Mirrors the 60 Alaska Legislature portraits into Supabase storage.
 *
 *   node --import ../../scripts/lib/main-checkout-fallback.mjs mirror-portraits.mjs <portraitDir> [--apply]
 *
 * Without --apply it lists what it would upload and uploads nothing.
 *
 * 🔴 BOTH HEADERS, ALWAYS. Supabase storage needs `apikey` AND `Authorization`; a lone Bearer is
 *    refused as HTTP 400 with a body saying 403 "Invalid Compact JWS", which reads like a missing
 *    object rather than a missing header.
 *
 * ⚠ MIRRORED, NOT HOTLINKED, and not re-encoded. Bytes go up exactly as akleg.gov served them —
 *   nothing is resized, re-compressed or upscaled. 58 of the 60 are 450x600; George Rauscher's is
 *   400x600 and Bryce Edgmon's is 150x200, which is ALL Alaska publishes for him (every variant
 *   of his file — /450x600/, the bare path and /rounded/ — is the same 150x200 image, and the
 *   only other picture of him on the site is a 222x159 LANDSCAPE leadership banner, which is not
 *   a headshot shape). Upscaling it would invent detail.
 */
import fs from 'node:fs';
import path from 'node:path';

const BUCKET = 'politician_photos';
const PREFIX = 'ak-legislature-2026';
const portraitDir = process.argv[2];
const apply = process.argv.includes('--apply');
if (!portraitDir) { console.error('usage: node mirror-portraits.mjs <portraitDir> [--apply]'); process.exit(2); }

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('SUPABASE_URL and a secret key must be set'); process.exit(2); }

const dir = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const roster = JSON.parse(fs.readFileSync(path.join(dir, 'roster-final.json'), 'utf8'));
if (roster.length !== 60) { console.error(`expected 60 roster rows, got ${roster.length}`); process.exit(1); }

export const slugOf = (r) => r.chamber === 'Senate'
  ? `sen-${String(r.district_code).toLowerCase()}`
  : `hse-${String(r.district_code).padStart(2, '0')}`;

let ok = 0; const failed = [];
for (const r of roster) {
  const src = path.join(portraitDir, r.member_code.toUpperCase() + '.jpg');
  if (!fs.existsSync(src)) { failed.push(`${r.full_name}: no local file ${src}`); continue; }
  const body = fs.readFileSync(src);
  const objectPath = `${PREFIX}/${slugOf(r)}.jpg`;
  if (!apply) { console.log(`would upload ${String(body.length).padStart(7)}b -> ${objectPath}  (${r.full_name})`); ok++; continue; }
  const res = await fetch(`${url}/storage/v1/object/${BUCKET}/${objectPath}`, {
    method: 'POST',
    headers: {
      apikey: key,                       // 🔴 both, see header note
      Authorization: `Bearer ${key}`,
      'Content-Type': 'image/jpeg',
      'x-upsert': 'true',
    },
    body,
  });
  if (!res.ok) { failed.push(`${r.full_name} -> ${objectPath}: HTTP ${res.status} ${(await res.text()).slice(0, 200)}`); continue; }
  ok++;
  process.stdout.write(`\ruploaded ${ok}/60`);
}
console.log(`\n${apply ? 'uploaded' : 'would upload'} ${ok}/60`);
if (failed.length) { console.error(`FAILED ${failed.length}:\n  ` + failed.join('\n  ')); process.exit(1); }

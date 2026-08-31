#!/usr/bin/env node
/**
 * Fail loudly on politicians whose photo_origin_url is a DEAD LINK.
 *
 * WHY THIS EXISTS. photoCoverage.ts's HAS_RENDERABLE_PHOTO_SQL counts a
 * politician as having a photo when photo_origin_url merely `LIKE 'http%'`. That
 * predicate reads the SHAPE of the value, not whether it resolves. A 404 that
 * starts with "http" is therefore counted as coverage while rendering broken to a
 * voter — strictly worse than a blank, because a blank puts the person in the
 * headshot backlog and a dead link hides them from it.
 *
 * Found the hard way on the Colorado wave: 7 of 92 legislator portrait URLs
 * carried over from Open States were 404s on leg.colorado.gov. Every one was
 * structurally valid, from an official source, and named the right person.
 * URL IDENTITY IS NOT LIVENESS.
 *
 * 🔴 THE CHECK IS THE BYTES, NOT THE STATUS AND NOT THE EXTENSION.
 *   - `r.ok` is not enough: a WAF rejection can be HTTP 200 or 202.
 *   - The extension is not enough: this repo has been burned classifying images
 *     by file extension before.
 * So this reads the leading bytes and requires a real JPEG/PNG/GIF/WebP magic
 * number, plus a minimum body size to reject 1x1 spacers and error pages that
 * happen to be served as images.
 *
 * This does NOT run in CI: it makes one network request per row and the upstream
 * hosts rate-limit. Run it after any wave that writes photo_origin_url, and
 * before trusting a coverage number.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/verify-photo-origin-urls.mjs --band -829999 -810001
 *   node scripts/verify-photo-origin-urls.mjs --state co
 *   node scripts/verify-photo-origin-urls.mjs --state fl --district-type STATE_LOWER,STATE_UPPER
 *   node scripts/verify-photo-origin-urls.mjs --band -849999 -810001 --fix-sql
 */
import 'dotenv/config';
import pg from 'pg';
import { spawnSync } from 'node:child_process';

const argv = process.argv.slice(2);
const bandIx = argv.indexOf('--band');
const stateIx = argv.indexOf('--state');
const dtypeIx = argv.indexOf('--district-type');
/** Optional narrowing of --state to one tier. A state's local half and its legislature are
 *  different cohorts: for a hand-seeded local official photo_origin_url is correctly the SOURCE
 *  PAGE (HTML), which this check would call dead. Only run it where the field holds an image. */
const DTYPES = (() => {
  if (dtypeIx === -1) return null;
  const v = argv[dtypeIx + 1];
  if (!v || v.startsWith('--')) { console.error('--district-type needs a comma-separated value'); process.exit(2); }
  return v.split(',').map((t) => t.trim());
})();
const EMIT_SQL = argv.includes('--fix-sql');
const LIMIT = (() => { const i = argv.indexOf('--limit'); return i === -1 ? null : Number(argv[i + 1]); })();

if (bandIx === -1 && stateIx === -1) {
  console.error('usage: --band <lo> <hi> | --state <xx> [--district-type A,B]   [--limit N] [--fix-sql]');
  process.exit(2);
}
// --district-type narrows the --state query only. Accepting it silently beside --band would
// sweep the whole band while the operator believes the run is scoped to one tier -- and with
// --fix-sql that writes NULLs over rows they never meant to touch.
if (DTYPES && bandIx !== -1) {
  console.error('--district-type applies to --state only; it does not narrow --band.');
  process.exit(2);
}
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

/** Minimum plausible portrait. Below this it is a spacer, an icon, or an error page. */
const MIN_BYTES = 2000;

/**
 * 🔴 A BARE `Mozilla/5.0` IS ITSELF A DETECTOR FAULT.
 * www.flhouse.gov sits behind an F5 BIG-IP WAF that answers a short UA with a
 * 244-byte "Request Rejected" page — as HTTP 200, Content-Type text/html. Run
 * with the short UA and ALL 116 Florida House portraits report dead; every one
 * of them is alive and 67KB. A full, current browser UA is what gets through.
 * The uniform verdict is the tell: a whole cohort failing identically means the
 * checker is blocked, not that the cohort rotted. Confirm one row by hand before
 * believing a sweep.
 */
const BROWSER_UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

/**
 * Fetch through curl, not global fetch.
 * Headers alone are not enough here: with the SAME Chrome UA and Accept, curl
 * gets the 67KB JPEG and undici still gets the 244-byte rejection, so the WAF is
 * fingerprinting below the header layer (TLS/JA3). Shelling out is the fix that
 * actually works. Returns the body bytes plus the status curl reports.
 */
function httpGet(url) {
  const r = spawnSync('curl', [
    '-sS', '-L', '--max-time', '30',
    '-A', BROWSER_UA,
    '-H', 'Accept: image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    '-H', 'Accept-Language: en-US,en;q=0.9',
    '-w', '\n%{http_code}', url,
  ], { maxBuffer: 64 * 1024 * 1024, encoding: 'buffer' });
  if (r.error) throw r.error;
  if (r.status !== 0) throw new Error((r.stderr?.toString() || `curl exit ${r.status}`).trim());
  const out = r.stdout;
  const nl = out.lastIndexOf(0x0a);
  return { status: Number(out.slice(nl + 1).toString('latin1')), body: out.slice(0, nl) };
}

function imageKind(b) {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'JPEG';
  if (b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'PNG';
  if (b.length >= 3 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46) return 'GIF';
  if (b.length >= 12 && b.slice(0, 4).toString('latin1') === 'RIFF' && b.slice(8, 12).toString('latin1') === 'WEBP') return 'WEBP';
  // 🔴 AVIF/HEIC ARE ISOBMFF, NOT A LEADING SIGNATURE -- the brand sits at bytes 4..11.
  // This script sends a browser Accept header (below), so hosts that content-negotiate WILL
  // answer in a modern format: static.wixstatic.com returns AVIF for the very same URL that
  // gives PNG to a bare request. A format we cannot NAME is not the same as "not an image",
  // and here that difference is destructive -- --fix-sql NULLs photo_origin_url for every
  // row this function returns null for, so an unrecognised AVIF portrait would be erased.
  if (b.length >= 12 && b.slice(4, 8).toString('latin1') === 'ftyp') {
    const brand = b.slice(8, 12).toString('latin1');
    if (brand === 'avif' || brand === 'avis') return 'AVIF';
    if (brand.startsWith('hei') || brand.startsWith('mif')) return 'HEIC';
  }
  return null;
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();

const where = bandIx !== -1
  ? { sql: 'p.external_id BETWEEN $1 AND $2', params: [Number(argv[bandIx + 1]), Number(argv[bandIx + 2])] }
  : { sql: `EXISTS (
        SELECT 1 FROM essentials.office_current_holder och
        JOIN essentials.offices o ON o.id = och.office_id
        JOIN essentials.districts d ON d.id = o.district_id
        WHERE och.politician_id = p.id AND lower(d.state) = lower($1)
          ${DTYPES ? 'AND d.district_type = ANY($2)' : ''})`,
      params: DTYPES ? [argv[stateIx + 1], DTYPES] : [argv[stateIx + 1]] };

const { rows } = await client.query(
  `SELECT p.id, p.full_name, p.photo_origin_url
     FROM essentials.politicians p
    WHERE ${where.sql}
      AND p.photo_origin_url IS NOT NULL
      AND p.photo_origin_url LIKE 'http%'
    ORDER BY p.full_name
    ${LIMIT ? `LIMIT ${LIMIT}` : ''}`,
  where.params,
);
await client.end();

console.log(`checking ${rows.length} photo_origin_url value(s)\n`);

const dead = [];
let live = 0;
for (const r of rows) {
  let verdict;
  try {
    const res = httpGet(r.photo_origin_url);
    const buf = res.body;
    const kind = imageKind(buf);
    if (!kind) verdict = `HTTP ${res.status}, ${buf.length}B, not an image`;
    else if (buf.length < MIN_BYTES) verdict = `HTTP ${res.status}, ${kind} but only ${buf.length}B`;
    else { live++; continue; }
  } catch (e) {
    verdict = `fetch failed: ${e.message}`;
  }
  dead.push({ ...r, verdict });
  console.log(`  DEAD  ${r.full_name.padEnd(28)} ${verdict}`);
}

console.log(`\nlive ${live} · dead ${dead.length} of ${rows.length}`);

if (dead.length && EMIT_SQL) {
  console.log('\n-- clearing dead links is the honest state: a blank puts the person in the');
  console.log('-- headshot backlog, a 404 hides them from it while rendering broken.');
  console.log('UPDATE essentials.politicians SET photo_origin_url = NULL WHERE id IN (');
  console.log(dead.map((d) => `  '${d.id}'`).join(',\n'));
  console.log(');');
}

process.exit(dead.length ? 1 : 0);

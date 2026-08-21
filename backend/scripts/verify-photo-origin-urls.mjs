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
 *   node scripts/verify-photo-origin-urls.mjs --band -849999 -810001 --fix-sql
 */
import 'dotenv/config';
import pg from 'pg';

const argv = process.argv.slice(2);
const bandIx = argv.indexOf('--band');
const stateIx = argv.indexOf('--state');
const EMIT_SQL = argv.includes('--fix-sql');
const LIMIT = (() => { const i = argv.indexOf('--limit'); return i === -1 ? null : Number(argv[i + 1]); })();

if (bandIx === -1 && stateIx === -1) {
  console.error('usage: --band <lo> <hi> | --state <xx>   [--limit N] [--fix-sql]');
  process.exit(2);
}
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

/** Minimum plausible portrait. Below this it is a spacer, an icon, or an error page. */
const MIN_BYTES = 2000;

function imageKind(b) {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'JPEG';
  if (b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'PNG';
  if (b.length >= 3 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46) return 'GIF';
  if (b.length >= 12 && b.slice(0, 4).toString('latin1') === 'RIFF' && b.slice(8, 12).toString('latin1') === 'WEBP') return 'WEBP';
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
        WHERE och.politician_id = p.id AND lower(d.state) = lower($1))`, params: [argv[stateIx + 1]] };

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
    const res = await fetch(r.photo_origin_url, { headers: { 'user-agent': 'Mozilla/5.0' }, redirect: 'follow' });
    const buf = Buffer.from(await res.arrayBuffer());
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

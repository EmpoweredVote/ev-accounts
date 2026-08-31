#!/usr/bin/env node
/**
 * Byte-check what a voter's browser is actually asked to load as a headshot.
 *
 * WHY THIS IS NOT verify-photo-origin-urls.mjs. That script checks ONE column. This one
 * checks the value the READ PATH composes, which is a different thing:
 *
 *     COALESCE(p.photo_custom_url, p.photo_origin_url, '')
 *
 * That is what backend/src/lib/districtQueries.ts (DISTRICT_SELECT_FIELDS, the
 * address-search path) hands to the frontend as the photo, and it NEVER READS
 * essentials.politician_images. So a person can have a perfectly good mirrored image row
 * and still be served something else entirely -- which is exactly how 71 Florida local
 * officials ended up handing an HTML PAGE to an <img src> (fixed in CC_0019).
 *
 * 🔴 THE EXTENSION IS NOT THE TEST, AND NEITHER IS THE STATUS.
 * North Carolina's portraits live at https://www.ncleg.gov/Members/MemberImage/H/758/Low
 * -- no extension at all -- and serve a real image/jpeg. Classifying by extension would
 * have condemned 134 working rows. A WAF rejection arrives as HTTP 200. So this reads the
 * leading bytes and requires a real magic number, plus a minimum size to reject spacers.
 *
 * Fetches through curl, not global fetch: some government WAFs (F5 BIG-IP on
 * www.flhouse.gov, for one) reject undici on its TLS fingerprint and answer HTTP 200 with
 * a 244-byte rejection page, no matter what headers are set.
 *
 * Not in CI -- one network request per row, and the upstream hosts rate-limit.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/verify-rendered-photo-urls.mjs --all
 *   node scripts/verify-rendered-photo-urls.mjs --state wa
 *   node scripts/verify-rendered-photo-urls.mjs --all --no-extension-only --json out.json
 */
import 'dotenv/config';
import pg from 'pg';
import { spawnSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

const argv = process.argv.slice(2);
const stateIx = argv.indexOf('--state');
const jsonIx = argv.indexOf('--json');
const ALL = argv.includes('--all');
/** Restrict to values carrying no image extension -- the population most likely to be a page. */
const NO_EXT_ONLY = argv.includes('--no-extension-only');
const CONCURRENCY = (() => { const i = argv.indexOf('--concurrency'); return i === -1 ? 8 : Number(argv[i + 1]); })();

if (!ALL && stateIx === -1) {
  console.error('usage: --all | --state <xx>   [--no-extension-only] [--json FILE] [--concurrency N]');
  process.exit(2);
}
if (!process.env.DATABASE_URL) { console.error('DATABASE_URL not set'); process.exit(2); }

const MIN_BYTES = 2000;
const BROWSER_UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

function imageKind(b) {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return 'JPEG';
  if (b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'PNG';
  if (b.length >= 3 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46) return 'GIF';
  if (b.length >= 12 && b.slice(0, 4).toString('latin1') === 'RIFF' && b.slice(8, 12).toString('latin1') === 'WEBP') return 'WEBP';
  return null;
}

function httpGet(url) {
  const r = spawnSync('curl', [
    '-sS', '-L', '--max-time', '30',
    '-A', BROWSER_UA,
    '-H', 'Accept: image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    '-w', '\\n%{http_code}\\n%{content_type}', url,
  ], { maxBuffer: 64 * 1024 * 1024, encoding: 'buffer' });
  if (r.error) throw r.error;
  if (r.status !== 0) throw new Error((r.stderr?.toString() || `curl exit ${r.status}`).trim());
  const out = r.stdout;
  const nl2 = out.lastIndexOf(0x0a);
  const nl1 = out.lastIndexOf(0x0a, nl2 - 1);
  return {
    status: Number(out.slice(nl1 + 1, nl2).toString('latin1')),
    contentType: out.slice(nl2 + 1).toString('latin1').trim(),
    body: out.slice(0, nl1),
  };
}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();

const params = [];
let stateFilter = '';
if (!ALL) { params.push(argv[stateIx + 1]); stateFilter = 'AND lower(d.state) = lower($1)'; }

const { rows } = await client.query(
  `WITH held AS (
     SELECT DISTINCT och.politician_id AS pid, lower(d.state) AS st, d.district_type
       FROM essentials.offices o
       JOIN essentials.districts d ON d.id = o.district_id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
      WHERE och.politician_id IS NOT NULL ${stateFilter}
   )
   SELECT p.id, p.full_name, h.st, h.district_type,
          COALESCE(NULLIF(btrim(p.photo_custom_url), ''), p.photo_origin_url, '') AS rendered
     FROM held h
     JOIN essentials.politicians p ON p.id = h.pid
    WHERE COALESCE(NULLIF(btrim(p.photo_custom_url), ''), p.photo_origin_url, '') LIKE 'http%'
    ORDER BY h.st, p.full_name`,
  params,
);
await client.end();

const targets = NO_EXT_ONLY
  ? rows.filter((r) => !/\.(jpg|jpeg|png|webp|gif)(\?|$)/i.test(r.rendered))
  : rows;

console.log(`checking ${targets.length} rendered URL(s) with concurrency ${CONCURRENCY}\n`);

const results = [];
let done = 0;
async function worker(queue) {
  for (;;) {
    const r = queue.shift();
    if (!r) return;
    let verdict, ok = false, kind = null, status = null, ctype = null, bytes = 0;
    try {
      const res = httpGet(r.rendered);
      status = res.status; ctype = res.contentType; bytes = res.body.length;
      kind = imageKind(res.body);
      if (!kind) verdict = `HTTP ${status}, ${bytes}B, ${ctype || 'no content-type'} -- NOT AN IMAGE`;
      else if (bytes < MIN_BYTES) verdict = `HTTP ${status}, ${kind} but only ${bytes}B`;
      else { ok = true; verdict = `${kind} ${bytes}B`; }
    } catch (e) {
      verdict = `fetch failed: ${e.message}`;
    }
    results.push({ ...r, ok, kind, status, ctype, bytes, verdict });
    done += 1;
    if (!ok) console.log(`  BROKEN [${r.st}] ${r.full_name.padEnd(28)} ${verdict}`);
    if (done % 50 === 0) console.log(`  ... ${done}/${targets.length}`);
  }
}
const queue = [...targets];
await Promise.all(Array.from({ length: Math.max(1, CONCURRENCY) }, () => worker(queue)));

const broken = results.filter((r) => !r.ok);
console.log(`\nreal images ${results.length - broken.length} · broken ${broken.length} of ${results.length}`);

const byState = {};
for (const b of broken) byState[b.st] = (byState[b.st] || 0) + 1;
if (broken.length) {
  console.log('\nbroken by state:');
  for (const [st, n] of Object.entries(byState).sort((a, b) => b[1] - a[1])) console.log(`  ${st}  ${n}`);
  const byHost = {};
  for (const b of broken) {
    const h = (b.rendered.split('/')[2] || '?');
    byHost[h] = (byHost[h] || 0) + 1;
  }
  console.log('\nbroken by host:');
  for (const [h, n] of Object.entries(byHost).sort((a, b) => b[1] - a[1]).slice(0, 20)) console.log(`  ${String(n).padStart(4)}  ${h}`);
}

if (jsonIx !== -1) {
  writeFileSync(argv[jsonIx + 1], JSON.stringify(results, null, 2));
  console.log(`\nwrote ${argv[jsonIx + 1]}`);
}
process.exit(0);

#!/usr/bin/env node
/**
 * ks-portrait-candidates.mjs — Knight program, wave KS-5.
 *
 * Joins the bound portrait manifest to the people production actually holds, and writes the
 * candidates file that render-headshot-contact-sheet.py and import-headshot-candidates.py share.
 * READ-ONLY against the database. Uploads nothing, writes no image.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * THE JOIN IS (chamber, district), AND THE NAME IS A CHECK.
 *
 * bind-ks-portraits.py already tied each photo to a district and a name using two independent
 * documents — the member's own page and the Legislature's first-party CSV. This adds the third:
 * production's own `politicians.full_name`, seated by CC_0157 from that same CSV months earlier.
 * If the three disagree, the row is refused rather than imported under a guess.
 *
 * 🔴 A NAME JOIN WOULD HAVE BEEN THE WEAKEST LINK AVAILABLE. KS-2 recorded three Mike Thompsons,
 * two of them seated in this legislature at once, one published as both "Mike" and "Michael".
 * District is an integer, unique within a chamber, and identical on both sides.
 *
 * ▶ `bytes_from` points at the file already on disk, so the contact sheet renders and the importer
 * ships THE SAME BYTES that were measured. Re-fetching between approval and import would let the
 * host serve something else in between — and this host already alternates between two encodings
 * of one image at the same URL.
 *
 * ⚠ LICENCE: `press_use`. The Kansas Legislature publishes NO photo policy and NO copyright notice
 * on its member pages — checked at /li/, the member pages and the footer. The restrictive terms at
 * portal.kansas.gov ("not for republication, distribution ... or preparation of derivative works")
 * define their own scope as "the Kansas.gov website", a different site run by a different operator,
 * and are NOT asserted over kslegislature.gov. ▶ Absence of a policy is not a licence; it is the
 * same footing as Georgia and Florida in MN-5, and the opposite of the Minnesota House, which
 * published an actual refusal. Recorded here so the next reader does not have to re-derive it.
 *
 * Usage:
 *   node scripts/ks-portrait-candidates.mjs            # writes .tmp-all-candidates.json
 *   node scripts/ks-portrait-candidates.mjs --check    # report only, write nothing
 */
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import * as dotenv from 'dotenv';
dotenv.config({ quiet: true });

const CHECK = process.argv.includes('--check');
const BOUND = 'data/seed-ks-2026/ks-portrait-bound.json';
const OUT = '.tmp-all-candidates.json';
const LICENSE = 'press_use';

const fail = (m) => { console.error(`\n🔴 ${m}`); process.exit(1); };
const norm = (s) => (s ?? '').normalize('NFKD').replace(/[^\p{L}\p{N}]+/gu, '').toLowerCase();

const bound = JSON.parse(fs.readFileSync(BOUND, 'utf8'));
if (bound.length !== 165) fail(`${BOUND} holds ${bound.length} rows, expected 165`);

if (!process.env.DATABASE_URL) fail('DATABASE_URL is not set');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();
const { rows: seated } = await client.query(`
  SELECT c.name AS chamber,
         (regexp_match(d.label, 'District\\s+(\\d+)$'))[1] AS district,
         p.id AS politician_id, p.full_name, o.title,
         p.photo_custom_url IS NOT NULL AS renderable
    FROM essentials.office_current_holder och
    JOIN essentials.offices o  ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'State of Kansas'
     AND c.name IN ('Kansas House of Representatives','Kansas Senate')`);
await client.end();

if (seated.length !== 165) fail(`production holds ${seated.length} seated Kansas legislators, expected 165`);

const key = (ch, d) => `${ch}#${d}`;
const byKey = new Map(seated.map((r) => [key(r.chamber, r.district), r]));

const cands = [];
const mismatches = [];
const alreadyDone = [];
for (const b of bound) {
  const hit = byKey.get(key(b.chamber, b.district));
  if (!hit) fail(`${b.slug}: ${b.chamber} district ${b.district} is not seated in production`);
  // THE THIRD DOCUMENT. Production was seated from the same CSV months ago; if it has drifted,
  // that is a finding, not something to paper over with a photo.
  if (norm(hit.full_name) !== norm(b.full_name)) {
    mismatches.push(`${b.chamber} d${b.district}: production "${hit.full_name}" vs roster "${b.full_name}"`);
    continue;
  }
  if (hit.renderable) { alreadyDone.push(hit.full_name); continue; }
  const file = path.resolve(b.file);
  if (!fs.existsSync(file)) fail(`${b.slug}: ${file} is not on disk`);
  cands.push({
    politician_id: hit.politician_id,
    name: hit.full_name,
    office: `${hit.title}, District ${b.district}`,
    cohort: b.chamber,
    url: b.url,
    bytes_from: file,
    page: `https://kslegislature.gov/b2025_26/legislators/${b.slug}/`,
    license: LICENSE,
    positional: false,       // the filename carries the member's own name, not a seat number
    src_w: b.width,
    src_h: b.height,
  });
}

console.log(`bound rows            ${bound.length}`);
console.log(`seated in production  ${seated.length}`);
console.log(`already renderable    ${alreadyDone.length}${alreadyDone.length ? ` (${alreadyDone.join(', ')})` : ''}`);
console.log(`name mismatches       ${mismatches.length}`);
for (const m of mismatches) console.log(`   🔴 ${m}`);
console.log(`candidates            ${cands.length}`);

if (mismatches.length) {
  fail(`${mismatches.length} name(s) disagree between the Legislature's roster and production. ` +
       `Resolve them before importing — a photo attached across a mismatch is the wrong face.`);
}
if (CHECK) { console.log('\n--check: wrote nothing.'); process.exit(0); }

fs.writeFileSync(OUT, JSON.stringify(cands, null, 1));
console.log(`\nwrote ${OUT} (${cands.length} candidates)`);
console.log('▶ next: python scripts/render-headshot-contact-sheet.py');

#!/usr/bin/env -S npx tsx
// Phase 133 / POL-05 — UT State Board of Education (15 members).
// Source: https://schools.utah.gov/board/utah/members.php (HTML scrape).
// HTML structure (VERIFIED 2026-05-14): inline-styled <p> blocks, each member has
//   <a href="/board/members/utah/{slug}.php"><img src="/board/_board_/{Photo}.jpg" alt="Full Name"></a>
//   <a href="...">Full Name</a><br></span></span><span ...>District N</span>
// Regex extraction is more robust than cheerio selectors against this inline markup.
import 'dotenv/config';
import pg from 'pg';
import { assignExternalId } from './lib/external-id.js';
import { upsertPolitician, upsertOffice, replaceContacts } from './lib/politician-upsert.js';
import { rehostPhoto } from './lib/photo-rehost.js';

const ROSTER_URL = 'https://schools.utah.gov/board/utah/members.php';
const DRY_RUN = process.argv.includes('--dry-run');

interface ScrapedMember {
  name: string;
  districtNumber: number;
  photoUrl: string | null;
  profileUrl: string | null;
}

async function fetchHtml(url: string): Promise<string> {
  const r = await fetch(url, { headers: { 'User-Agent': 'EmpoweredVote/1.0 (UT roster ingest)' } });
  if (!r.ok) throw new Error(`HTTP ${r.status} fetching ${url}`);
  return await r.text();
}

function scrapeRoster(html: string): ScrapedMember[] {
  // Pattern: each member appears as a profile-anchor-img block followed shortly
  // by the same anchor with name text and a District N span.
  // Match: <a href="/board/members/utah/{slug}.php"><img src="{photo}" alt="{name}">
  // Then within the next ~600 chars: District (\d+)
  const blockRe = /<a href="(\/board\/members\/utah\/[^"]+\.php)"[^>]*>\s*<img src="([^"]+)"[^>]*alt="([^"]+)"/g;
  const members: ScrapedMember[] = [];
  let m: RegExpExecArray | null;
  while ((m = blockRe.exec(html)) !== null) {
    const profileHref = m[1];
    const photoSrc = m[2];
    const altName = m[3].trim();
    // Look for "District N" in the next 800 chars
    const tail = html.slice(m.index, m.index + 1200);
    const distMatch = tail.match(/District\s+(\d+)/);
    if (!distMatch) continue;
    const district = parseInt(distMatch[1], 10);
    members.push({
      name: altName,
      districtNumber: district,
      photoUrl: new URL(photoSrc, ROSTER_URL).toString(),
      profileUrl: new URL(profileHref, ROSTER_URL).toString(),
    });
  }
  // Dedupe by district number (each member appears multiple times in the HTML)
  const byDistrict = new Map<number, ScrapedMember>();
  for (const m of members) {
    if (!byDistrict.has(m.districtNumber)) byDistrict.set(m.districtNumber, m);
  }
  return Array.from(byDistrict.values()).sort((a, b) => a.districtNumber - b.districtNumber);
}

function splitName(name: string): { first: string; last: string } {
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return { first: parts[0], last: parts[0] };
  return { first: parts.slice(0, -1).join(' '), last: parts[parts.length - 1] };
}

async function resolveDistrict(client: pg.PoolClient, n: number): Promise<{ id: string; geo_id: string }> {
  const geoId = `ocd-division/country:us/state:ut/sboe:${n}`;
  const found = await client.query<{ id: string }>(
    `SELECT id FROM essentials.districts
      WHERE state ILIKE 'ut' AND district_type='STATE_BOARD' AND geo_id=$1
      LIMIT 1`, [geoId],
  );
  if (found.rowCount && found.rowCount > 0) return { id: found.rows[0].id, geo_id: geoId };
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, district_id, state, geo_id)
     VALUES ($1, $2, 'STATE_BOARD', $3, 'ut', $1)
     RETURNING id`,
    [geoId, `Utah State Board of Education District ${n}`, String(n)],
  );
  return { id: ins.rows[0].id, geo_id: geoId };
}

async function main(): Promise<void> {
  console.error(`[ut-sboe] fetching ${ROSTER_URL}…`);
  const html = await fetchHtml(ROSTER_URL);
  const members = scrapeRoster(html);
  console.error(`[ut-sboe] scraped ${members.length} unique members (expected 15)`);
  if (members.length !== 15) {
    console.error('[ut-sboe] WARNING: count mismatch — inspect HTML structure');
    for (const m of members) console.error(`  - District ${m.districtNumber}: ${m.name}`);
  }
  if (members.length === 0) { process.exit(1); }

  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  const stats = { inserted: 0, updated: 0, photos: 0, errors: 0 };
  let idx = 0;
  for (const m of members) {
    idx++;
    const { first, last } = splitName(m.name);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const district = await resolveDistrict(client, m.districtNumber);
      const { external_id } = await assignExternalId(pool, district.geo_id, 'state_board_of_education', { dataSource: 'ut-sboe-roster', fullName: m.name });
      if (DRY_RUN) {
        console.error(`[dry] ${m.name} -> sboe:${m.districtNumber} ext_id=${external_id}`);
        await client.query('ROLLBACK');
        continue;
      }
      const { inserted } = await upsertPolitician(client, {
        external_id, full_name: m.name, first_name: first, last_name: last,
        data_source: 'ut-sboe-roster', photo_origin_url: m.photoUrl,
      }, idx);
      if (inserted) stats.inserted++; else stats.updated++;

      const polRow = await client.query<{ id: string }>(`SELECT id FROM essentials.politicians WHERE external_id=$1`, [external_id]);
      const polId = polRow.rows[0].id;

      await upsertOffice(client, {
        politician_id: polId, district_id: district.id,
        title: `State Board of Education District ${m.districtNumber}`,
        representing_state: 'UT', seats: 1,
      });

      await replaceContacts(client, polId, 'ut-sboe-roster', [
        { politician_id: polId, source: 'ut-sboe-roster', email: null, contact_type: 'office', website_url: m.profileUrl },
      ]);

      if (m.photoUrl) {
        const url = await rehostPhoto(client, polId, external_id, m.photoUrl);
        if (url) stats.photos++;
      }
      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      stats.errors++;
      console.error(`[ut-sboe] ERROR ${m.name}: ${(e as Error).message}`);
    } finally {
      client.release();
    }
  }

  console.error(`[ut-sboe] DONE inserted=${stats.inserted} updated=${stats.updated} photos=${stats.photos} errors=${stats.errors}`);
  if (stats.errors > 0) process.exitCode = 2;
  await pool.end();
}

main().catch((e) => { console.error('[ut-sboe] FATAL', e); process.exit(1); });

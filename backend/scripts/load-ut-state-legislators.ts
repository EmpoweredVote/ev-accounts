#!/usr/bin/env -S npx tsx
// Phase 133 / POL-06 — UT Senate (29) + UT House (75).
// Source: glen.le.utah.gov via LE_UTAH_DEV_TOKEN (URL path segment).
//
// ANTIPARTISAN: source returns party; never persist.
// IDEMPOTENT: D-07 hash + ON CONFLICT (external_id) DO UPDATE via politician-upsert.
//
// LE_UTAH field shape VERIFIED 2026-05-14:
//   { fullName, formatName, id, image, house ('H'|'S'), party, district,
//     serviceStart, profession, email, cell, workPhone, homePhone, address, bio, ... }
import 'dotenv/config';
import pg from 'pg';
import { assignExternalId } from './lib/external-id.js';
import { upsertPolitician, upsertOffice, replaceContacts } from './lib/politician-upsert.js';
import { rehostPhoto } from './lib/photo-rehost.js';

const DRY_RUN = process.argv.includes('--dry-run');
const LOG_FIRST = process.argv.includes('--log-first-record');

interface LegislatorRecord {
  fullName: string;         // "Last, First M."
  formatName: string;       // "First M. Last"
  id: string;               // "PETERT"
  image?: string | null;    // full URL
  house: 'H' | 'S';
  party?: string;           // captured but never written
  district: string;         // "1"
  email?: string;
  cell?: string;
  workPhone?: string;
  homePhone?: string;
}

async function fetchRoster(token: string): Promise<LegislatorRecord[]> {
  const url = `https://glen.le.utah.gov/legislators/${token}`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`LE_UTAH fetch failed: HTTP ${r.status}`);
  const j = await r.json() as { legislators?: LegislatorRecord[] };
  if (!Array.isArray(j.legislators)) {
    throw new Error(`Unexpected LE_UTAH JSON shape; keys=${Object.keys(j).join(',')}`);
  }
  return j.legislators;
}

function splitName(formatName: string): { first: string; last: string } {
  // "First M. Last" -> first="First M.", last="Last"
  const parts = formatName.trim().split(/\s+/);
  if (parts.length === 1) return { first: parts[0], last: parts[0] };
  const last = parts[parts.length - 1];
  const first = parts.slice(0, -1).join(' ');
  return { first, last };
}

async function resolveOrCreateDistrict(
  client: pg.PoolClient,
  chamber: 'H' | 'S',
  districtNum: number,
): Promise<{ id: string; geo_id: string }> {
  const districtType = chamber === 'S' ? 'STATE_UPPER' : 'STATE_LOWER';
  const ocdSegment = chamber === 'S' ? 'sldu' : 'sldl';
  const ocdId = `ocd-division/country:us/state:ut/${ocdSegment}:${districtNum}`;

  const found = await client.query<{ id: string; geo_id: string | null }>(
    `SELECT id, geo_id FROM essentials.districts
      WHERE state ILIKE 'ut' AND district_type=$1
        AND (ocd_id=$2 OR ocd_id LIKE '%' || $3 || ':' || $4)
      LIMIT 1`,
    [districtType, ocdId, ocdSegment, String(districtNum)],
  );
  if (found.rowCount && found.rowCount > 0) {
    const row = found.rows[0];
    return { id: row.id, geo_id: row.geo_id ?? ocdId };
  }
  // Create missing row (shouldn't happen — TIGER from 131 should have populated all)
  console.warn(`[ut-legis] WARN creating missing district row for ${chamber}${districtNum}`);
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, district_id, state, geo_id)
     VALUES ($1, $2, $3, $4, 'ut', $1)
     RETURNING id`,
    [ocdId, `UT ${chamber === 'S' ? 'Senate' : 'House'} District ${districtNum}`, districtType, String(districtNum)],
  );
  return { id: ins.rows[0].id, geo_id: ocdId };
}

async function main(): Promise<void> {
  const token = process.env.LE_UTAH_DEV_TOKEN;
  if (!token) { console.error('FATAL: LE_UTAH_DEV_TOKEN not set'); process.exit(1); }

  console.error(`[ut-legis] fetching from glen.le.utah.gov…`);
  const records = await fetchRoster(token);
  console.error(`[ut-legis] ${records.length} records received`);

  if (LOG_FIRST && records.length > 0) {
    console.error('[ut-legis] FIRST RECORD KEYS:', Object.keys(records[0]).join(', '));
  }

  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });

  const stats = { inserted: 0, updated: 0, photos: 0, skipped_photo: 0, collisions: 0 };
  const errors: Array<{ name: string; err: string }> = [];
  let idx = 0;

  for (const rec of records) {
    idx++;
    try {
      const chamber = (String(rec.house).toUpperCase().startsWith('S') ? 'S' : 'H') as 'S' | 'H';
      const districtNum = Number(rec.district);
      if (!districtNum || !rec.formatName) {
        throw new Error(`Missing required fields: id=${rec.id} formatName=${rec.formatName} district=${rec.district}`);
      }
      const { first, last } = splitName(rec.formatName);
      const role = chamber === 'S' ? 'state_senator' : 'state_representative';

      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const district = await resolveOrCreateDistrict(client, chamber, districtNum);
        const { external_id, collided } = await assignExternalId(pool, district.geo_id, role, { dataSource: 'ut-legislator-le-utah', fullName: rec.formatName });
        if (collided) stats.collisions++;

        if (DRY_RUN) {
          console.error(`[dry] ${rec.formatName} -> ${chamber}${districtNum} ext_id=${external_id}`);
          await client.query('ROLLBACK');
          continue;
        }

        const { inserted } = await upsertPolitician(client, {
          external_id,
          full_name: rec.formatName,
          first_name: first,
          last_name: last,
          data_source: 'ut-legislator-le-utah',
          photo_origin_url: rec.image ?? null,
        }, idx);
        if (inserted) stats.inserted++; else stats.updated++;

        const polRow = await client.query<{ id: string }>(
          `SELECT id FROM essentials.politicians WHERE external_id=$1`, [external_id]);
        const politicianId = polRow.rows[0].id;

        await upsertOffice(client, {
          politician_id: politicianId,
          district_id: district.id,
          title: chamber === 'S' ? `State Senator District ${districtNum}` : `State Representative District ${districtNum}`,
          representing_state: 'UT',
          description: null,
          seats: 1,
        });

        const phone = rec.workPhone || rec.cell || rec.homePhone || null;
        await replaceContacts(client, politicianId, 'ut-legislator-le-utah', [
          {
            politician_id: politicianId,
            source: 'ut-legislator-le-utah',
            email: rec.email ?? null,
            phone,
            contact_type: 'office',
          },
        ]);

        if (rec.image) {
          const url = await rehostPhoto(client, politicianId, external_id, rec.image);
          if (url) stats.photos++; else stats.skipped_photo++;
        }

        await client.query('COMMIT');
      } catch (e) {
        await client.query('ROLLBACK');
        throw e;
      } finally {
        client.release();
      }
    } catch (e) {
      errors.push({ name: rec.formatName ?? rec.id ?? '?', err: (e as Error).message });
    }
  }

  console.error(`[ut-legis] DONE inserted=${stats.inserted} updated=${stats.updated} photos=${stats.photos} skipped_photo=${stats.skipped_photo} collisions=${stats.collisions} errors=${errors.length}`);
  if (errors.length > 0) {
    for (const e of errors) console.error(`  ERROR ${e.name}: ${e.err}`);
    process.exitCode = 2;
  }
  await pool.end();
}

main().catch((e) => { console.error('[ut-legis] FATAL', e); process.exit(1); });

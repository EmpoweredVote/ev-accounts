#!/usr/bin/env -S npx tsx
// Phase 133 / POL-04 — UT unified school district boards (41).
// All members attach to whole-district G5420 SCHOOL row (LAUSD pattern per CONTEXT D-04 / POL-04 floor).
//
// Reads TSVs from data/rosters/manual/<slug>_school_district.tsv (one per district).
// Skips placeholder rows where full_name === 'PENDING_RESEARCH' (Task 6.1 scaffolding floor —
// real rosters fill these in over time without breaking idempotency).
//
// ANTIPARTISAN: party affiliation never persisted (politician-upsert.ts INSERT list omits `party`).
import 'dotenv/config';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';
import { assignExternalId } from './lib/external-id';
import { upsertPolitician, upsertOffice, replaceContacts } from './lib/politician-upsert';
import { splitPersonName } from './lib/split-person-name';
import { rehostPhoto } from './lib/photo-rehost';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MANIFEST = path.resolve(__dirname, '../data/sources/ut_school_rosters.json');
const ROSTERS_DIR = path.resolve(__dirname, '../data/rosters/manual');
const DRY_RUN = process.argv.includes('--dry-run');
const DISTRICT_FILTER = (() => {
  const idx = process.argv.indexOf('--district');
  return idx >= 0 ? process.argv[idx + 1] ?? null : null;
})();

interface SchoolRecord {
  district_geo_id: string;
  district_name: string;
  source: string;
  source_url: string | null;
  has_subdistrict_polygons: boolean;
  status: string;
  notes?: string;
}

interface DistrictStats {
  ins: number;
  upd: number;
  err: number;
  skipped_placeholders: number;
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

function districtSlug(districtName: string): string {
  return slugify(districtName).replace(/_school_district$/, '');
}

async function resolveSchoolDistrict(
  client: pg.PoolClient,
  geoId: string,
  label: string,
): Promise<string> {
  // The SCHOOL district row's geo_id MUST equal the TIGER G5420 UNSD geofence's
  // geo_id (a FIPS code like '4900360') — essentialsService.ts joins
  // geofence_boundaries.geo_id = districts.geo_id. The G5420 row has no ocd_id,
  // so match it by name (UNSD names equal district_name exactly) and adopt its geo_id.
  let effectiveGeoId = geoId;
  const place = await client.query<{ geo_id: string }>(
    `SELECT geo_id FROM essentials.geofence_boundaries
      WHERE state='49' AND mtfcc='G5420' AND name ILIKE $1 LIMIT 1`,
    [label],
  );
  if (place.rowCount && place.rowCount > 0) {
    effectiveGeoId = place.rows[0].geo_id;
  }
  const found = await client.query<{ id: string }>(
    `SELECT id FROM essentials.districts WHERE state ILIKE 'ut' AND district_type='SCHOOL' AND geo_id=$1 LIMIT 1`,
    [effectiveGeoId],
  );
  if (found.rowCount && found.rowCount > 0) return found.rows[0].id;
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, state, geo_id)
     VALUES ($1, $2, 'SCHOOL', 'ut', $3) RETURNING id`,
    [geoId, label, effectiveGeoId],
  );
  return ins.rows[0].id;
}

async function loadDistrict(pool: pg.Pool, district: SchoolRecord): Promise<DistrictStats> {
  const slug = districtSlug(district.district_name);
  const tsvCandidates = [
    path.join(ROSTERS_DIR, `${slug}_school_district.tsv`),
    path.join(ROSTERS_DIR, `${slug}_sd.tsv`),
  ];
  const tsvPath = tsvCandidates.find((p) => fs.existsSync(p));
  const stats: DistrictStats = { ins: 0, upd: 0, err: 0, skipped_placeholders: 0 };

  if (!tsvPath) {
    console.error(`[ut-school] SKIP ${district.district_name}: no TSV at ${tsvCandidates.join(' or ')}`);
    stats.err = 1;
    return stats;
  }

  const lines = fs.readFileSync(tsvPath, 'utf-8').split(/\r?\n/).filter((l) => l.trim());
  if (lines.length === 0) return stats;
  const header = lines.shift()!.split('\t').map((h) => h.trim());

  let idx = 0;
  for (const line of lines) {
    idx++;
    const cells = line.split('\t');
    const row: Record<string, string> = {};
    header.forEach((h, i) => {
      row[h] = (cells[i] ?? '').trim();
    });
    if (!row.full_name || !row.role) continue;

    // Skip Task 6.1 scaffolding placeholders. Once a real roster replaces them,
    // the loader inserts normally and idempotent re-runs follow.
    if (row.full_name === 'PENDING_RESEARCH') {
      stats.skipped_placeholders++;
      continue;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const districtId = await resolveSchoolDistrict(client, district.district_geo_id, district.district_name);

      // D-07 hash key: scope by district + role so 'Board Member Seat 1' in Granite != Jordan.
      const hashRole = `school_${slug}_${slugify(row.role)}`;
      const dataSource = `ut-school-${slug}`;
      const { external_id } = await assignExternalId(pool, district.district_geo_id, hashRole, { dataSource, fullName: row.full_name });

      if (DRY_RUN) {
        await client.query('ROLLBACK');
        console.error(`[dry] ${row.full_name} (${row.role}) -> ${district.district_geo_id} ext=${external_id}`);
        continue;
      }

      const name = splitPersonName(row.full_name);
      const { inserted } = await upsertPolitician(
        client,
        {
          external_id,
          full_name: row.full_name,
          first_name: name.first,
          last_name: name.last,
          middle_initial: name.middle_initial,
          name_suffix: name.suffix,
          data_source: dataSource,
          photo_origin_url: row.photo_url || null,
        },
        idx,
      );
      if (inserted) stats.ins++;
      else stats.upd++;

      const polRow = await client.query<{ id: string }>(
        `SELECT id FROM essentials.politicians WHERE external_id=$1`,
        [external_id],
      );
      const polId = polRow.rows[0].id;

      await upsertOffice(client, {
        politician_id: polId,
        district_id: districtId,
        title: row.role,
        representing_state: 'UT',
        representing_city: district.district_name,
        seats: 1,
      });

      await replaceContacts(client, polId, dataSource, [
        {
          politician_id: polId,
          source: dataSource,
          email: row.email || null,
          phone: row.phone || null,
          contact_type: 'office',
        },
      ]);

      if (row.photo_url) {
        try {
          await rehostPhoto(client, polId, external_id, row.photo_url);
        } catch (photoErr) {
          // D-06: photo failures are non-fatal — log and continue.
          console.error(`[ut-school] photo skip ${slug} ${row.full_name}: ${(photoErr as Error).message}`);
        }
      }

      await client.query('COMMIT');
    } catch (e) {
      try {
        await client.query('ROLLBACK');
      } catch {
        /* connection may already be released; swallow */
      }
      stats.err++;
      console.error(`[ut-school] ERROR ${slug} ${row.full_name}: ${(e as Error).message}`);
    } finally {
      client.release();
    }
  }
  console.error(
    `[ut-school] ${slug}: ins=${stats.ins} upd=${stats.upd} err=${stats.err} placeholders=${stats.skipped_placeholders}`,
  );
  return stats;
}

async function main(): Promise<void> {
  let districts: SchoolRecord[] = JSON.parse(fs.readFileSync(MANIFEST, 'utf-8'));
  if (DISTRICT_FILTER) {
    districts = districts.filter((d) => districtSlug(d.district_name) === DISTRICT_FILTER);
    if (districts.length === 0) {
      const available = (JSON.parse(fs.readFileSync(MANIFEST, 'utf-8')) as SchoolRecord[])
        .map((d) => districtSlug(d.district_name)).join(', ');
      console.error(`[ut-school] No district found with slug "${DISTRICT_FILTER}". Available: ${available}`);
      process.exit(1);
    }
    console.error(`[ut-school] --district filter: processing ${districts[0].district_name} only`);
  }
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  const tot: DistrictStats = { ins: 0, upd: 0, err: 0, skipped_placeholders: 0 };
  for (const d of districts) {
    const s = await loadDistrict(pool, d);
    tot.ins += s.ins;
    tot.upd += s.upd;
    tot.err += s.err;
    tot.skipped_placeholders += s.skipped_placeholders;
  }
  console.error(
    `[ut-school] TOTAL inserted=${tot.ins} updated=${tot.upd} errors=${tot.err} placeholders=${tot.skipped_placeholders} (districts=${districts.length})`,
  );
  if (tot.err > 0) process.exitCode = 2;
  await pool.end();
}

main().catch((e) => {
  console.error('[ut-school] FATAL', e);
  process.exit(1);
});

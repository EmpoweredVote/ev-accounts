#!/usr/bin/env -S npx tsx
// Phase 133 / POL-02 — UT county officials loader.
//
// Reads ut_county_rosters.json + per-county TSV under data/rosters/manual/.
// Council counties attach council seats by district (when geo_id provided);
// commission counties + at-large electeds attach to G4020 whole-county.
//
// ANTIPARTISAN: this loader has no `party` column in its TsvRow interface;
// upstream upsert lib also omits party. T-133-04-03 mitigation.
//
// Stub rows (full_name === 'PENDING_RESEARCH') are intentionally SKIPPED to
// avoid polluting the politicians table with placeholders. Operator fills the
// TSV with real names then re-runs idempotently (D-08).
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

const MANIFEST = path.resolve(__dirname, '../data/sources/ut_county_rosters.json');
const ROSTERS_DIR = path.resolve(__dirname, '../data/rosters/manual');
const DRY_RUN = process.argv.includes('--dry-run');
const ONLY_COUNTY = process.argv.find(
  (_a, i) => i > 0 && process.argv[i - 1] === '--county',
);

interface CountyRecord {
  county_name: string;
  fips: string;
  geo_id_county: string;
  government_shape: 'council' | 'commission';
  status: string;
  council_district_template?: string | null;
  expected_council_seats?: number;
  expected_commissioners?: number;
  expected_at_large_officers?: number;
}

interface TsvRow {
  external_id: string;
  full_name: string;
  role: string;
  geo_id: string;
  email: string;
  phone: string;
  term_start: string;
  term_end: string;
  photo_url: string;
  source: string;
}

function readTsv(filePath: string): TsvRow[] {
  const txt = fs.readFileSync(filePath, 'utf-8');
  const lines = txt.split(/\r?\n/).filter((l) => l.trim().length > 0);
  if (lines.length === 0) return [];
  const header = lines.shift()!.split('\t').map((h) => h.trim());
  const rows: TsvRow[] = [];
  for (const line of lines) {
    const cells = line.split('\t');
    const row: Record<string, string> = {};
    header.forEach((h, i) => {
      row[h] = (cells[i] ?? '').trim();
    });
    rows.push(row as unknown as TsvRow);
  }
  return rows;
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

async function resolveCountyDistrict(
  client: pg.PoolClient,
  countyOcdId: string,
): Promise<{ id: string; geo_id: string }> {
  // Prefer the TIGER-derived COUNTY row (FIPS geo_id like '49035', ocd_id =
  // the OCD form). essentialsService.ts routes G4020 → district_type='COUNTY',
  // so at-large/county-wide officials must attach to THAT row, not a new LOCAL one.
  const found = await client.query<{ id: string; geo_id: string | null }>(
    `SELECT id, geo_id FROM essentials.districts
      WHERE state ILIKE 'ut'
        AND (ocd_id=$1 OR geo_id=$1)
        AND district_type IN ('COUNTY','LOCAL')
      ORDER BY (district_type='COUNTY') DESC LIMIT 1`,
    [countyOcdId],
  );
  if (found.rowCount && found.rowCount > 0) {
    return { id: found.rows[0].id, geo_id: found.rows[0].geo_id ?? countyOcdId };
  }
  // No existing row — create as COUNTY (not LOCAL) so G4020 routing matches.
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, district_id, state, geo_id)
     VALUES ($1, $2, 'COUNTY', NULL, 'ut', $1) RETURNING id`,
    [countyOcdId, `Utah county ${countyOcdId}`],
  );
  return { id: ins.rows[0].id, geo_id: countyOcdId };
}

async function resolveCouncilDistrict(
  client: pg.PoolClient,
  geoId: string,
): Promise<{ id: string; geo_id: string }> {
  const found = await client.query<{ id: string }>(
    `SELECT id FROM essentials.districts
      WHERE state ILIKE 'ut' AND geo_id=$1 AND district_type='LOCAL'
      LIMIT 1`,
    [geoId],
  );
  if (found.rowCount && found.rowCount > 0) {
    return { id: found.rows[0].id, geo_id: geoId };
  }
  const districtNumMatch = geoId.match(/council_district:(\d+)/);
  const districtNum = districtNumMatch?.[1] ?? null;
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, district_id, state, geo_id)
     VALUES ($1, $2, 'LOCAL', $3, 'UT', $1) RETURNING id`,
    [geoId, `Council District ${districtNum ?? '?'}`, districtNum],
  );
  return { id: ins.rows[0].id, geo_id: geoId };
}

async function loadCounty(
  pool: pg.Pool,
  county: CountyRecord,
): Promise<{ ins: number; upd: number; err: number; skipped: number }> {
  const slug = slugify(county.county_name);
  const tsvPath = path.join(ROSTERS_DIR, `${slug}_county.tsv`);
  const stats = { ins: 0, upd: 0, err: 0, skipped: 0 };

  if (!fs.existsSync(tsvPath)) {
    console.error(`[ut-county] SKIP ${county.county_name}: missing ${tsvPath}`);
    stats.err++;
    return stats;
  }
  const rows = readTsv(tsvPath);

  let idx = 0;
  for (const row of rows) {
    idx++;
    if (!row.full_name || !row.role) {
      console.error(`[ut-county] SKIP row in ${slug}: missing full_name/role`);
      stats.err++;
      continue;
    }
    // Stub placeholder rows are intentionally not loaded.
    if (row.full_name === 'PENDING_RESEARCH') {
      stats.skipped++;
      continue;
    }
    const targetGeoId = row.geo_id?.trim() || county.geo_id_county;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const district = targetGeoId.includes('council_district:')
        ? await resolveCouncilDistrict(client, targetGeoId)
        : await resolveCountyDistrict(client, targetGeoId);

      const hashRole = `county_${slug}_${slugify(row.role)}`;
      const { external_id } = await assignExternalId(pool, district.geo_id, hashRole, { dataSource: `ut-county-${slug}`, fullName: row.full_name });

      if (DRY_RUN) {
        console.error(
          `[dry] ${row.full_name} (${row.role}) -> ${targetGeoId} ext=${external_id}`,
        );
        await client.query('ROLLBACK');
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
          data_source: `ut-county-${slug}`,
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
        district_id: district.id,
        title: row.role,
        representing_state: 'UT',
        representing_city: county.county_name,
        seats: 1,
      });

      await replaceContacts(client, polId, `ut-county-${slug}`, [
        {
          politician_id: polId,
          source: `ut-county-${slug}`,
          email: row.email || null,
          phone: row.phone || null,
          contact_type: 'office',
        },
      ]);

      if (row.photo_url) {
        try {
          await rehostPhoto(client, polId, external_id, row.photo_url);
        } catch (e) {
          console.warn(
            `[ut-county] photo skip ${slug} ${row.full_name}: ${(e as Error).message}`,
          );
        }
      }

      if (row.term_start || row.term_end) {
        await client.query(
          `INSERT INTO essentials.experiences (politician_id, title, organization, type, start, "end")
           VALUES ($1, $2, $3, 'office', $4, $5)`,
          [
            polId,
            row.role,
            `${county.county_name} County`,
            row.term_start || null,
            row.term_end || null,
          ],
        );
      }

      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      stats.err++;
      console.error(
        `[ut-county] ERROR ${slug} ${row.full_name}: ${(e as Error).message}`,
      );
    } finally {
      client.release();
    }
  }
  console.error(
    `[ut-county] ${slug}: ins=${stats.ins} upd=${stats.upd} err=${stats.err} skipped=${stats.skipped} (${rows.length} rows)`,
  );
  return stats;
}

async function main(): Promise<void> {
  const counties: CountyRecord[] = JSON.parse(fs.readFileSync(MANIFEST, 'utf-8'));
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  const targets = ONLY_COUNTY
    ? counties.filter((c) => slugify(c.county_name) === ONLY_COUNTY)
    : counties;
  let totIns = 0;
  let totUpd = 0;
  let totErr = 0;
  let totSkipped = 0;
  for (const c of targets) {
    const s = await loadCounty(pool, c);
    totIns += s.ins;
    totUpd += s.upd;
    totErr += s.err;
    totSkipped += s.skipped;
  }
  console.error(
    `[ut-county] TOTAL inserted=${totIns} updated=${totUpd} errors=${totErr} skipped_stubs=${totSkipped}`,
  );
  if (totErr > 0) process.exitCode = 2;
  await pool.end();
}

main().catch((e) => {
  console.error('[ut-county] FATAL', e);
  process.exit(1);
});

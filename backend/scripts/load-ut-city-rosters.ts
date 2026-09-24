#!/usr/bin/env -S npx tsx
// Phase 133 / POL-03 — UT city councils + mayors.
// Dispatches per record.source: 'featureserver' (SLC, Provo) | 'manual_csv' (others).
// SLC: CITYCOUNCIL_MEMBER field via services.arcgis.com (132 D-04 verified).
// Provo: COUNCIL_MEMBER + EMAIL/PHONE/TERM_EXPIRES/picture via gispublicweb.provo.org.
// Others: TSV stubs under data/rosters/manual/{slug}_city.tsv + {slug}_mayor.tsv.
//
// ANTIPARTISAN: no party column inserted (politician-upsert.ts enforces).
//
// Skips rows whose full_name is "PENDING_RESEARCH" (stub TSV rows pre-research).
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

const MANIFEST = path.resolve(__dirname, '../data/sources/ut_city_rosters.json');
const ROSTERS_DIR = path.resolve(__dirname, '../data/rosters/manual');
const DRY_RUN = process.argv.includes('--dry-run');
const CITY_FILTER = (() => {
  const idx = process.argv.indexOf('--city');
  return idx >= 0 ? process.argv[idx + 1] ?? null : null;
})();

interface CityRecord {
  jurisdiction_id: string;
  city_name: string;
  source: 'featureserver' | 'scrape' | 'manual_csv';
  source_url: string | null;
  fields?: Record<string, string | null>;
  geo_id_template?: string;
  status: string;
  expected_seats?: number;
  mayor_district_type?: string;
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

function placeSlug(jurisdictionId: string): string {
  return jurisdictionId.match(/place:([^/]+)/)?.[1] ?? '';
}

function isStubName(name: string): boolean {
  return /^PENDING_RESEARCH/i.test(name.trim());
}

async function fetchFeatures(url: string): Promise<Array<{ properties?: Record<string, unknown>; attributes?: Record<string, unknown> }>> {
  const r = await fetch(url);
  if (!r.ok) throw new Error(`HTTP ${r.status} fetching ${url}`);
  const j = await r.json();
  if (!Array.isArray(j?.features)) throw new Error(`No features in ${url}`);
  return j.features;
}

async function resolveDistrict(
  client: pg.PoolClient, geoId: string, districtType: string,
  label: string, districtNum?: string, cityName?: string,
): Promise<string> {
  // For whole-place attachments (city council at-large / mayor), the district
  // row's geo_id MUST equal the TIGER G4110 place geofence's geo_id (a 7-digit
  // FIPS place code like '4955980') — essentialsService.ts joins
  // geofence_boundaries.geo_id = districts.geo_id. The G4110 row has no ocd_id,
  // so we match it by name ("{City} city" / "{City} town") and adopt its geo_id.
  let effectiveGeoId = geoId;
  const isWholePlace = !geoId.includes('/ward:');
  if (isWholePlace && cityName) {
    const place = await client.query<{ geo_id: string }>(
      `SELECT geo_id FROM essentials.geofence_boundaries
        WHERE state='49' AND mtfcc='G4110'
          AND (name ILIKE $1 OR name ILIKE $2)
        LIMIT 1`,
      [`${cityName} city`, `${cityName} town`],
    );
    if (place.rowCount && place.rowCount > 0) {
      effectiveGeoId = place.rows[0].geo_id;
    }
  }
  const found = await client.query<{ id: string }>(
    `SELECT id FROM essentials.districts WHERE state ILIKE 'ut' AND geo_id=$1 AND district_type=$2 LIMIT 1`,
    [effectiveGeoId, districtType],
  );
  if (found.rowCount && found.rowCount > 0) return found.rows[0].id;
  const ins = await client.query<{ id: string }>(
    `INSERT INTO essentials.districts (ocd_id, label, district_type, district_id, state, geo_id)
     VALUES ($1, $2, $3, $4, 'ut', $5) RETURNING id`,
    [geoId, label, districtType, districtNum ?? null, effectiveGeoId],
  );
  return ins.rows[0].id;
}

async function ingest(
  pool: pg.Pool, idx: number, city: CityRecord,
  fullName: string, role: string, targetGeoId: string,
  districtType: string,
  opts: { email?: string | null; phone?: string | null; photo?: string | null; sourceSlug: string },
): Promise<void> {
  if (isStubName(fullName)) {
    console.error(`[ut-city] SKIP stub ${city.city_name} role=${role} (PENDING_RESEARCH)`);
    return;
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const districtLabel = `${city.city_name} ${role}`;
    // district_id drives the card subtitle: a numeric ward/district number, or '0'
    // for at-large council seats (whole-place attachment) so the frontend renders
    // "At-Large". Mayors/officers (non-LOCAL) keep null.
    const explicitNum = role.match(/\b(\d+)\b/)?.[1];
    const isWholePlaceCouncil =
      districtType === 'LOCAL' && /council/i.test(role) && !targetGeoId.includes('/ward:');
    const districtNum = explicitNum ?? (isWholePlaceCouncil ? '0' : undefined);
    const districtId = await resolveDistrict(client, targetGeoId, districtType, districtLabel, districtNum, city.city_name);

    const slug = placeSlug(city.jurisdiction_id);
    const hashRole = `city_${slug}_${slugify(role)}`;
    // Identity dataSource MUST equal the data_source used in the upsert
    // (opts.sourceSlug) — mayors use `ut-city-{slug}-mayor`, council uses
    // `ut-city-{slug}`. Mismatch breaks idempotent re-run dedup.
    const { external_id } = await assignExternalId(pool, targetGeoId, hashRole, { dataSource: opts.sourceSlug, fullName });

    if (DRY_RUN) {
      console.error(`[dry] ${fullName} (${role}) -> ${targetGeoId} ext=${external_id}`);
      await client.query('ROLLBACK');
      return;
    }

    const name = splitPersonName(fullName);
    await upsertPolitician(client, {
      external_id, full_name: fullName, first_name: name.first, last_name: name.last,
      middle_initial: name.middle_initial, name_suffix: name.suffix,
      data_source: opts.sourceSlug, photo_origin_url: opts.photo ?? null,
    }, idx);

    const polRow = await client.query<{ id: string }>(
      `SELECT id FROM essentials.politicians WHERE external_id=$1`, [external_id],
    );
    const polId = polRow.rows[0].id;

    await upsertOffice(client, {
      politician_id: polId, district_id: districtId,
      title: role, representing_state: 'UT', representing_city: city.city_name, seats: 1,
    });

    await replaceContacts(client, polId, opts.sourceSlug, [
      { politician_id: polId, source: opts.sourceSlug, email: opts.email ?? null, phone: opts.phone ?? null, contact_type: 'office' },
    ]);

    if (opts.photo) await rehostPhoto(client, polId, external_id, opts.photo);
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function loadFeatureServer(pool: pg.Pool, city: CityRecord): Promise<void> {
  if (!city.source_url || !city.fields) throw new Error(`${city.city_name}: missing source_url or fields`);
  if (/^TBD/i.test(city.source_url)) {
    console.error(`[ut-city] SKIP ${city.city_name}: source_url is TBD`);
    return;
  }
  const features = await fetchFeatures(city.source_url);
  console.error(`[ut-city] ${city.city_name} FeatureServer: ${features.length} features`);
  let idx = 0;
  for (const f of features) {
    idx++;
    // ArcGIS GeoJSON uses .properties; ArcGIS native JSON uses .attributes.
    const p = (f.properties ?? f.attributes ?? {}) as Record<string, unknown>;
    const memberField = city.fields.council_member!;
    const districtField = city.fields.district_number!;
    const name = String(p[memberField] ?? '').trim();
    const districtRaw = String(p[districtField] ?? '').trim();
    if (!name || !districtRaw) {
      console.error(`[ut-city] ${city.city_name}: skip feature missing name/district (member="${name}" district="${districtRaw}")`);
      continue;
    }
    const isAtLarge = /at[- ]?large|^AL$/i.test(districtRaw);
    const wardNum = districtRaw.match(/\d+/)?.[0];
    const geoId = isAtLarge
      ? city.jurisdiction_id
      : `${city.jurisdiction_id}/ward:${wardNum ?? districtRaw}`;
    const role = isAtLarge ? 'Council At-Large' : `Council Ward ${wardNum ?? districtRaw}`;
    await ingest(pool, idx, city, name, role, geoId, 'LOCAL', {
      email: city.fields.email ? (p[city.fields.email] as string | null) : null,
      phone: city.fields.phone ? (p[city.fields.phone] as string | null) : null,
      photo: city.fields.photo ? (p[city.fields.photo] as string | null) : null,
      sourceSlug: `ut-city-${placeSlug(city.jurisdiction_id)}`,
    });
  }
}

function readTsv(p: string): Array<Record<string, string>> {
  const lines = fs.readFileSync(p, 'utf-8').split(/\r?\n/).filter((l) => l.trim() && !l.startsWith('#'));
  if (lines.length === 0) return [];
  const header = lines.shift()!.split('\t').map((h) => h.trim());
  return lines.map((line) => {
    const cells = line.split('\t');
    const row: Record<string, string> = {};
    header.forEach((h, i) => { row[h] = (cells[i] ?? '').trim(); });
    return row;
  });
}

async function loadTsv(pool: pg.Pool, city: CityRecord): Promise<void> {
  const slug = placeSlug(city.jurisdiction_id);
  const tsv = path.join(ROSTERS_DIR, `${slug}_city.tsv`);
  if (!fs.existsSync(tsv)) {
    console.error(`[ut-city] SKIP ${city.city_name}: ${tsv} missing`);
    return;
  }
  const rows = readTsv(tsv);
  let idx = 0;
  for (const row of rows) {
    idx++;
    if (!row.full_name || !row.role) continue;
    const isMayor = /^mayor$/i.test(row.role);
    const geoId = row.geo_id || city.jurisdiction_id;
    await ingest(pool, idx, city, row.full_name, row.role, geoId,
      isMayor ? 'LOCAL_EXEC' : 'LOCAL', {
      email: row.email || null, phone: row.phone || null, photo: row.photo_url || null,
      sourceSlug: `ut-city-${slug}`,
    });
  }
}

async function loadMayorTsv(pool: pg.Pool, city: CityRecord): Promise<void> {
  const slug = placeSlug(city.jurisdiction_id);
  const tsv = path.join(ROSTERS_DIR, `${slug}_mayor.tsv`);
  if (!fs.existsSync(tsv)) return;
  const rows = readTsv(tsv);
  let idx = 0;
  for (const row of rows) {
    idx++;
    if (!row.full_name) continue;
    await ingest(pool, idx, city, row.full_name, 'Mayor', city.jurisdiction_id,
      'LOCAL_EXEC', {
      email: row.email || null, phone: row.phone || null, photo: row.photo_url || null,
      sourceSlug: `ut-city-${slug}-mayor`,
    });
  }
}

async function main(): Promise<void> {
  let cities: CityRecord[] = JSON.parse(fs.readFileSync(MANIFEST, 'utf-8'));
  if (CITY_FILTER) {
    cities = cities.filter((c) => placeSlug(c.jurisdiction_id) === CITY_FILTER);
    if (cities.length === 0) {
      const available = (JSON.parse(fs.readFileSync(MANIFEST, 'utf-8')) as CityRecord[])
        .map((c) => placeSlug(c.jurisdiction_id)).join(', ');
      console.error(`[ut-city] No city found with slug "${CITY_FILTER}". Available: ${available}`);
      process.exit(1);
    }
    console.error(`[ut-city] --city filter: processing ${cities[0].city_name} only`);
  }
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  for (const c of cities) {
    try {
      if (c.source === 'featureserver') {
        await loadFeatureServer(pool, c);
      } else if (c.status === 'manual_csv') {
        await loadTsv(pool, c);
      }
      // Always check for a separate mayor TSV (SLC/Provo mayors come from here).
      await loadMayorTsv(pool, c);
    } catch (e) {
      console.error(`[ut-city] ERROR ${c.city_name}: ${(e as Error).message}`);
      process.exitCode = 2;
    }
  }
  await pool.end();
}

main().catch((e) => { console.error('[ut-city] FATAL', e); process.exit(1); });

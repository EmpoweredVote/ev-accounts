#!/usr/bin/env -S npx tsx
// Phase 132 — Generic config-driven ArcGIS loader.
// Reads data/arcgis_sources.json; for each active|manual_geojson record,
// fetches GeoJSON and upserts to essentials.geofence_boundaries.
//
// Pattern source: ev-accounts/backend/scripts/import-mcc-district-polygons.ts
// Composite key: (geo_id, mtfcc) — ON CONFLICT DO NOTHING.
// state column = '49' (FIPS) per Phase 130 D-01.

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import https from 'https';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOURCES_PATH = path.resolve(__dirname, '../data/arcgis_sources.json');
const STATE_FIPS = '49'; // UT
const CHECK_ONLY = process.argv.includes('--check');
const DRY_RUN = process.argv.includes('--dry-run');

function getFlagValue(flag: string): string | null {
  const idx = process.argv.indexOf(flag);
  return idx >= 0 && idx + 1 < process.argv.length ? process.argv[idx + 1] : null;
}
const ONLY_JURISDICTION = getFlagValue('--jurisdiction');
const ONLY_LAYER_CLASS = getFlagValue('--layer-class');

interface SourceRecord {
  jurisdiction_id: string;
  layer_class: 'county_council' | 'city_ward' | 'sboe' | 'school_subdistrict';
  source_url: string | null;
  /**
   * `name` reads the boundary's display name from a source attribute. `name_template` synthesizes it
   * from the district number instead ('District {N}'), and takes precedence when both are set.
   *
   * name_template exists because several source layers have NO usable district-label field at all --
   * Taylorsville's `NAME` is a census-block description, Holladay's only label reads "Proposed
   * District 1 - 6,174", West Jordan has no label attribute, and Cottonwood Heights' GIS host refuses
   * connections so its fields cannot be inspected. Before it existed, those configs pointed `name` at
   * a COUNCILMEMBER field, which is how 31 boundaries ended up named after people -- and two of Salt
   * Lake City's after people who had already left office (migration 1500). A boundary must not be
   * named after its occupant: the person changes, the district does not.
   */
  field_map:
    | {
        district_num: string;
        name?: string;
        name_template?: string;
        district_num_transform?: 'extract_int';
      }
    | null;
  mtfcc: string;
  geo_id_template: string | null;
  status: 'active' | 'no_source' | 'at_large' | 'manual_geojson';
  notes?: string;
}

interface Counters {
  inserted_boundary: number;
  skipped_boundary: number;
  features_processed: number;
  errors: number;
}

function makeCounters(): Counters {
  return { inserted_boundary: 0, skipped_boundary: 0, features_processed: 0, errors: 0 };
}

function fetchArcGisJson(url: string): Promise<{ features: Array<{ properties: Record<string, unknown>; geometry: unknown }> }> {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        const loc = res.headers.location;
        if (!loc) return reject(new Error(`Redirect with no location from ${url}`));
        return resolve(fetchArcGisJson(loc));
      }
      if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode} from ${url}`));
      const chunks: Buffer[] = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        try {
          resolve(JSON.parse(Buffer.concat(chunks).toString('utf-8')));
        } catch (e) {
          reject(new Error(`Failed to parse JSON from ${url}: ${(e as Error).message}`));
        }
      });
      res.on('error', reject);
    }).on('error', reject);
  });
}

function resolveProp(props: Record<string, unknown>, key: string): unknown {
  if (key in props) return props[key];
  return undefined;
}

async function loadOne(client: pg.PoolClient, rec: SourceRecord, counters: Counters): Promise<void> {
  if (rec.status !== 'active' && rec.status !== 'manual_geojson') {
    console.error(`[132-arcgis] SKIP ${rec.jurisdiction_id} (status=${rec.status})`);
    return;
  }
  if (!rec.source_url || !rec.field_map || !rec.geo_id_template) {
    throw new Error(
      `Record ${rec.jurisdiction_id} status=${rec.status} requires source_url, field_map, geo_id_template`,
    );
  }
  if (!rec.field_map.name && !rec.field_map.name_template) {
    throw new Error(
      `Record ${rec.jurisdiction_id} needs field_map.name or field_map.name_template — ` +
        'refusing to fall back to a layer_class placeholder for a boundary name',
    );
  }

  console.error(`[132-arcgis] LOAD ${rec.jurisdiction_id} (${rec.layer_class}, mtfcc=${rec.mtfcc})`);

  const json =
    rec.status === 'manual_geojson'
      ? JSON.parse(fs.readFileSync(path.resolve(path.dirname(SOURCES_PATH), rec.source_url), 'utf-8'))
      : await fetchArcGisJson(rec.source_url);

  if (!Array.isArray(json.features) || json.features.length === 0) {
    throw new Error(`${rec.jurisdiction_id}: no features in source`);
  }

  const sourceString =
    rec.status === 'manual_geojson'
      ? `manual_digitize_${path.basename(rec.source_url, '.geojson')}`
      : 'ugrc_sgid_2026';

  for (const feature of json.features) {
    counters.features_processed++;
    const props = feature.properties ?? {};
    const districtNum = resolveProp(props, rec.field_map.district_num);

    if (districtNum === undefined || districtNum === null) {
      console.error(
        `[132-arcgis] FATAL ${rec.jurisdiction_id}: field_map.district_num='${rec.field_map.district_num}' ` +
          `not present in feature. Available keys: [${Object.keys(props).join(', ')}]`,
      );
      process.exit(1);
    }

    const rawNum = String(districtNum);
    const resolvedNum = rec.field_map?.district_num_transform === 'extract_int'
      ? rawNum.replace(/\D+/g, '')
      : rawNum;
    const geoId = rec.geo_id_template.replace('{N}', resolvedNum);
    const ocdId = geoId; // OCD-ID equals geo_id for these layers (D-09)
    // name_template wins when set: it is used precisely for the sources that have no usable label
    // attribute, so there is nothing to read. Otherwise read the mapped attribute. The old
    // `layer_class N` fallback is gone — the validation above makes an unnamed record a hard error
    // rather than silently writing "city_ward 3" as a boundary name.
    const nameStr = rec.field_map.name_template
      ? rec.field_map.name_template.replace('{N}', resolvedNum)
      : String(resolveProp(props, rec.field_map.name as string) ?? `District ${resolvedNum}`);

    if (DRY_RUN) {
      // name is echoed because it is the field most likely to be misconfigured: pointing it at a
      // councilmember attribute is what named 38 boundaries after people (migrations 1500, 1501).
      console.error(
        `[132-arcgis] DRY_RUN would insert geo_id=${geoId} mtfcc=${rec.mtfcc} name="${nameStr}"`,
      );
      continue;
    }

    const result = await client.query(
      `
      INSERT INTO essentials.geofence_boundaries
        (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
      VALUES (
        $1, $2, $3, $4, $5,
        public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($6)), 4326),
        $7,
        now()
      )
      ON CONFLICT (geo_id, mtfcc) DO NOTHING
      RETURNING geo_id
      `,
      [geoId, ocdId, nameStr, STATE_FIPS, rec.mtfcc, JSON.stringify(feature.geometry), sourceString],
    );

    if (result.rowCount && result.rowCount > 0) counters.inserted_boundary++;
    else counters.skipped_boundary++;
  }
}

async function runChecks(client: pg.PoolClient, records: SourceRecord[]): Promise<void> {
  let failures = 0;
  for (const rec of records) {
    if (rec.status !== 'active' && rec.status !== 'manual_geojson') continue;
    const prefix = (rec.geo_id_template ?? '').replace('{N}', '');
    const { rows } = await client.query<{ c: string }>(
      `SELECT COUNT(*)::text AS c FROM essentials.geofence_boundaries
        WHERE mtfcc = $1 AND geo_id LIKE $2`,
      [rec.mtfcc, `${prefix}%`],
    );
    const c = parseInt(rows[0].c, 10);
    if (c === 0) {
      console.error(`[132-arcgis] CHECK FAIL ${rec.jurisdiction_id}: 0 rows for mtfcc=${rec.mtfcc} prefix=${prefix}`);
      failures++;
    } else {
      console.error(`[132-arcgis] CHECK PASS ${rec.jurisdiction_id}: ${c} rows`);
    }
  }
  if (failures > 0) process.exitCode = 2;
}

async function main(): Promise<void> {
  if (!process.env.DATABASE_URL) {
    console.error('[132-arcgis] FATAL: DATABASE_URL not set');
    process.exit(1);
  }

  const allRecords: SourceRecord[] = JSON.parse(fs.readFileSync(SOURCES_PATH, 'utf-8'));
  const records = allRecords.filter((r) => {
    if (ONLY_JURISDICTION && r.jurisdiction_id !== ONLY_JURISDICTION) return false;
    if (ONLY_LAYER_CLASS && r.layer_class !== ONLY_LAYER_CLASS) return false;
    return true;
  });

  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  const client = await pool.connect();

  try {
    if (CHECK_ONLY) {
      console.error('[132-arcgis] --check mode: read-only count check (no INSERT)');
      await runChecks(client, records);
      return;
    }

    const counters = makeCounters();
    for (const rec of records) {
      try {
        await loadOne(client, rec, counters);
      } catch (e) {
        counters.errors++;
        console.error(`[132-arcgis] ERROR ${rec.jurisdiction_id}: ${(e as Error).message}`);
      }
    }

    console.error(`[132-arcgis] inserted_boundary=${counters.inserted_boundary}`);
    console.error(`[132-arcgis] skipped_boundary=${counters.skipped_boundary}`);
    console.error(`[132-arcgis] features_processed=${counters.features_processed}`);
    console.error(`[132-arcgis] errors=${counters.errors}`);
    if (counters.errors > 0) process.exitCode = 3;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  console.error('[132-arcgis] FATAL', e);
  process.exit(1);
});

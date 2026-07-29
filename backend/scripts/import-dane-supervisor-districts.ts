/**
 * import-dane-supervisor-districts.ts — Idempotent import of the 37 Dane County
 * Board of Supervisors district polygons.
 *
 * Source: Wisconsin LTSB's hosted feature layer "WI County Supervisory Districts
 * (Current)", filtered to Dane. Verified 2026-07-29: returnCountOnly for
 * CNTY_NAME='Dane' returns exactly 37; f=geojson + outSR=4326 supported (native
 * SR is EPSG:3070, so outSR=4326 is mandatory); maxRecordCount 2000 so all 37
 * arrive in one request; features carry DATE_SUB '7/14/2026' (refreshed this
 * month, post-2022-cycle). Dane County's own ArcGIS is token-locked
 * (dcimapapps.countyofdane.com returns error 499), hence the LTSB layer.
 *   https://services1.arcgis.com/FDsAtKBk8Hy4cAH0/arcgis/rest/services/
 *     WI_County_Supervisory_Districts_Current/FeatureServer/0
 *
 * !! GEOMETRY ONLY. Supervisor NAMES come from board.danecounty.gov/supervisors
 *    (roster in migration 1491), never from GIS attributes — the Racine lesson
 *    (import-racine-supervisor-districts.ts): GIS rosters go stale.
 *
 * Schema produced (mirrors the Racine importer, the direct precedent):
 *   geofence_boundaries: geo_id='55025-sup-d{N}', mtfcc='X-DC-SUP', state='55',
 *                        source='wi_ltsb_gis'
 *   districts:           geo_id='55025-sup-d{N}', district_type='COUNTY', state='wi',
 *                        mtfcc='X-DC-SUP', district_id='sup-d{N}'
 *
 * Why mtfcc='X-DC-SUP': essentialsService requires `mtfcc LIKE 'X%'` (and not
 *   X0001..X0004) with district_type IN ('LOCAL','COUNTY') for custom polygons
 *   to route addresses. Descriptive form follows X-RC-SUP (Racine) / X-MCC-DIST
 *   (Monroe). Verified unused in essentials.districts on 2026-07-29.
 *
 * Usage:
 *   npx tsx scripts/import-dane-supervisor-districts.ts --check   # read-only
 *   npx tsx scripts/import-dane-supervisor-districts.ts           # import (idempotent)
 */

import 'dotenv/config';
import { Pool } from 'pg';

const SERVICE =
  'https://services1.arcgis.com/FDsAtKBk8Hy4cAH0/arcgis/rest/services/' +
  'WI_County_Supervisory_Districts_Current/FeatureServer/0/query';
const EXPECTED = 37;
const MTFCC = 'X-DC-SUP';
const COUNTY_FIPS = '55025';

// Capitol Square Madison, downtown Sun Prairie, downtown Mount Horeb — each must
// land in exactly ONE supervisor district.
const PROBES: Array<{ label: string; lat: number; lng: number }> = [
  { label: 'Capitol Square Madison', lat: 43.0747, lng: -89.384 },
  { label: 'Sun Prairie', lat: 43.1836, lng: -89.2137 },
  { label: 'Mount Horeb', lat: 43.0086, lng: -89.7387 },
];

interface Feature {
  properties: Record<string, unknown>;
  geometry: unknown;
}

async function fetchDistricts(): Promise<Feature[]> {
  const url =
    `${SERVICE}?where=${encodeURIComponent("CNTY_NAME='Dane'")}` +
    `&outFields=${encodeURIComponent('SUPERID,GEOID,LABEL')}&outSR=4326&f=geojson`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`ArcGIS query failed: HTTP ${res.status}`);
  const gj = (await res.json()) as { type?: string; features?: Feature[] };
  const features = gj.features ?? [];
  if (features.length !== EXPECTED) {
    throw new Error(
      `expected ${EXPECTED} supervisor districts, got ${features.length}. ` +
        `Dane County may have redistricted — reconcile the roster in 1491 before importing.`
    );
  }
  const ids = features
    .map((f) => Number(f.properties.SUPERID))
    .sort((a, b) => a - b);
  const wanted = Array.from({ length: EXPECTED }, (_, i) => i + 1);
  if (JSON.stringify(ids) !== JSON.stringify(wanted)) {
    throw new Error(`district ids not a complete 1..${EXPECTED} set: ${JSON.stringify(ids)}`);
  }
  return features;
}

async function main() {
  const checkOnly = process.argv.includes('--check');
  const features = await fetchDistricts();
  console.log(`[dane-sup] fetched ${features.length} districts (ids 1..${EXPECTED} complete)`);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    if (checkOnly) {
      const { rows } = await pool.query(
        `SELECT
           (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc = $1) AS boundaries,
           (SELECT count(*) FROM essentials.districts WHERE mtfcc = $1) AS districts`,
        [MTFCC]
      );
      console.log(`[dane-sup] --check: boundaries=${rows[0].boundaries} districts=${rows[0].districts}`);
      return;
    }

    let insB = 0;
    let insD = 0;
    for (const f of features) {
      const n = Number(f.properties.SUPERID);
      const geoId = `${COUNTY_FIPS}-sup-d${n}`;
      const label = `Dane County Supervisor District ${n}`;
      const json = JSON.stringify(f.geometry);

      // ST_MakeValid + CollectionExtract(...,3): repair ring self-intersections and keep only
      // polygonal geometry — the normalization used by the Racine importer.
      const b = await pool.query(
        `INSERT INTO essentials.geofence_boundaries (geo_id, name, mtfcc, state, geometry, source)
         SELECT $1, $2, $3, '55',
                public.ST_CollectionExtract(
                  public.ST_MakeValid(
                    public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($4)), 4326)
                  ), 3),
                'wi_ltsb_gis'
         ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
        [geoId, label, MTFCC, json]
      );
      insB += b.rowCount ?? 0;

      const d = await pool.query(
        `INSERT INTO essentials.districts
           (geo_id, label, district_type, state, mtfcc, district_id, num_officials)
         SELECT $1, $2, 'COUNTY', 'wi', $3, $4, 1
         WHERE NOT EXISTS (
           SELECT 1 FROM essentials.districts
            WHERE geo_id = $1 AND district_type = 'COUNTY' AND mtfcc = $3
         )`,
        [geoId, label, MTFCC, `sup-d${n}`]
      );
      insD += d.rowCount ?? 0;
    }

    const { rows } = await pool.query(
      `SELECT
         (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc = $1) AS boundaries,
         (SELECT count(*) FROM essentials.districts WHERE mtfcc = $1) AS districts`,
      [MTFCC]
    );
    console.log(
      `[dane-sup] inserted boundaries=${insB} districts=${insD} | ` +
        `totals boundaries=${rows[0].boundaries} districts=${rows[0].districts}`
    );

    // Post-import probe: each address must fall in exactly one supervisor district.
    for (const p of PROBES) {
      const { rows: hit } = await pool.query(
        `SELECT gb.name
           FROM essentials.geofence_boundaries gb
          WHERE gb.mtfcc = $1
            AND public.ST_Covers(gb.geometry,
                  public.ST_SetSRID(public.ST_MakePoint($2::float8, $3::float8), 4326))`,
        [MTFCC, p.lng, p.lat]
      );
      const names = hit.map((r) => r.name).join(', ') || 'NO MATCH';
      console.log(`[dane-sup] probe ${p.label}: ${hit.length} match(es) — ${names}`);
      if (hit.length !== 1) {
        throw new Error(
          `probe '${p.label}' matched ${hit.length} districts, expected exactly 1 ` +
            `(overlapping or gapped polygons would misroute residents)`
        );
      }
    }

    if (Number(rows[0].boundaries) !== EXPECTED || Number(rows[0].districts) !== EXPECTED) {
      process.exitCode = 2;
      console.error(`[dane-sup] FINAL COUNT MISMATCH — expected ${EXPECTED} of each`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[dane-sup] Fatal error:', err);
  process.exit(1);
});

/**
 * import-racine-supervisor-districts.ts — Idempotent import of the 21 Racine County
 * Board of Supervisors district polygons.
 *
 * Source: Racine County's own ArcGIS MapServer (the county publishes this openly; it is
 * also mirrored on their ArcGIS Hub at data-racinecounty.opendata.arcgis.com):
 *   https://arcgis.racinecounty.com/arcgis/rest/services/Supervisor_Districts/Supervisor_Districts/MapServer/0
 * Queried with outSR=4326 & f=geojson, so no reprojection step is needed.
 *
 * !! GEOMETRY ONLY. Do NOT read supervisor NAMES from this layer. Its REPNAME attribute is
 *    materially stale — 10 of 21 disagreed with the county's own roster page when checked on
 *    2026-07-25, and 4 of those were entirely different people (D3, D14, D17, D18). Its
 *    `Photos` field is mismatched too (D1 REPNAME=Coleman but photo 'nickdemske1.jpg').
 *    The roster lives in migration 1446, sourced from
 *    racinecounty.gov/departments/county-board/county-board-of-supervisors-4659.
 *
 * Schema produced (mirrors import-mcc-district-polygons.ts, the Monroe County precedent):
 *   geofence_boundaries: geo_id='55101-sup-d{N}', mtfcc='X-RC-SUP', state='55',
 *                        source='racine_county_gis'
 *   districts:           geo_id='55101-sup-d{N}', district_type='COUNTY', state='wi',
 *                        mtfcc='X-RC-SUP', district_id='sup-d{N}'
 *
 * Why mtfcc='X-RC-SUP': essentialsService.ts requires `mtfcc LIKE 'X%'` AND
 *   mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND district_type IN ('LOCAL','COUNTY')
 *   for a custom polygon to be picked up by the address→politician lookup. An X0005-style
 *   numeric code would collide with the LA/Riverside supervisorial registry, so this uses the
 *   descriptive form Monroe established with 'X-MCC-DIST'.
 *
 * Why state='55' on geofence_boundaries: every other WI row in that table stores 2-digit FIPS
 *   (the lone G4000 state row is the exception, storing 'WI'). The Monroe precedent used USPS
 *   'IN', but WI-internal consistency wins here; the routing join keys on geo_id, not state.
 *   districts.state stays LOWERCASE 'wi' — the convention for the COUNTY/LOCAL tier.
 *
 * Usage:
 *   npx tsx scripts/import-racine-supervisor-districts.ts --check   # read-only, no writes
 *   npx tsx scripts/import-racine-supervisor-districts.ts           # import (idempotent)
 *
 * Idempotency: geofence_boundaries ON CONFLICT (geo_id, mtfcc) DO NOTHING; districts guarded
 *   by WHERE NOT EXISTS on (geo_id, district_type). Re-running inserts 0 and 0.
 */

import 'dotenv/config';
import { Pool } from 'pg';

const SERVICE =
  'https://arcgis.racinecounty.com/arcgis/rest/services/Supervisor_Districts/' +
  'Supervisor_Districts/MapServer/0/query';
const EXPECTED = 21;
const MTFCC = 'X-RC-SUP';
const COUNTY_FIPS = '55101';

// Downtown Racine and Burlington — used as a post-import sanity probe: each must land in
// exactly ONE supervisor district.
const PROBES: Array<{ label: string; lat: number; lng: number }> = [
  { label: 'downtown Racine', lat: 42.7261, lng: -87.7829 },
  { label: 'Burlington', lat: 42.6781, lng: -88.2762 },
  { label: 'Sturtevant', lat: 42.6961, lng: -87.8956 },
];

interface Feature {
  properties: Record<string, unknown>;
  geometry: unknown;
}

async function fetchDistricts(): Promise<Feature[]> {
  const url =
    `${SERVICE}?where=${encodeURIComponent('1=1')}` +
    `&outFields=${encodeURIComponent('DISTRICTID')}&outSR=4326&f=geojson`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`ArcGIS query failed: HTTP ${res.status}`);
  const gj = (await res.json()) as { type?: string; features?: Feature[] };
  const features = gj.features ?? [];
  if (features.length !== EXPECTED) {
    throw new Error(
      `expected ${EXPECTED} supervisor districts, got ${features.length}. ` +
        `Racine County may have redistricted — reconcile the roster in 1446 before importing.`
    );
  }
  const ids = features
    .map((f) => Number(f.properties.DISTRICTID))
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
  console.log(`[racine-sup] fetched ${features.length} districts (ids 1..${EXPECTED} complete)`);

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    if (checkOnly) {
      const { rows } = await pool.query(
        `SELECT
           (SELECT count(*) FROM essentials.geofence_boundaries WHERE mtfcc = $1) AS boundaries,
           (SELECT count(*) FROM essentials.districts WHERE mtfcc = $1) AS districts`,
        [MTFCC]
      );
      console.log(`[racine-sup] --check: boundaries=${rows[0].boundaries} districts=${rows[0].districts}`);
      return;
    }

    let insB = 0;
    let insD = 0;
    for (const f of features) {
      const n = Number(f.properties.DISTRICTID);
      const geoId = `${COUNTY_FIPS}-sup-d${n}`;
      const label = `Racine County Supervisor District ${n}`;
      const json = JSON.stringify(f.geometry);

      // ST_MakeValid + CollectionExtract(...,3): repair ring self-intersections and keep only
      // polygonal geometry — the normalization used by 1642-import-core.mts.
      const b = await pool.query(
        `INSERT INTO essentials.geofence_boundaries (geo_id, name, mtfcc, state, geometry, source)
         SELECT $1, $2, $3, '55',
                public.ST_CollectionExtract(
                  public.ST_MakeValid(
                    public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($4)), 4326)
                  ), 3),
                'racine_county_gis'
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
      `[racine-sup] inserted boundaries=${insB} districts=${insD} | ` +
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
      console.log(`[racine-sup] probe ${p.label}: ${hit.length} match(es) — ${names}`);
      if (hit.length !== 1) {
        throw new Error(
          `probe '${p.label}' matched ${hit.length} districts, expected exactly 1 ` +
            `(overlapping or gapped polygons would misroute residents)`
        );
      }
    }

    if (Number(rows[0].boundaries) !== EXPECTED || Number(rows[0].districts) !== EXPECTED) {
      process.exitCode = 2;
      console.error(`[racine-sup] FINAL COUNT MISMATCH — expected ${EXPECTED} of each`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[racine-sup] Fatal error:', err);
  process.exit(1);
});

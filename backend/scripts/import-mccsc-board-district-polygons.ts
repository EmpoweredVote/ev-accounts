/**
 * import-mccsc-board-district-polygons.ts — Idempotent load of the 7 MCCSC board-district
 * polygons, and relink of the 7 board-member offices to the new per-district rows.
 *
 * PROBLEM: MCCSC's 7 trustees are elected by single-member board district, but all 7
 * offices hung off ONE whole-corporation district (essentials.districts geo_id='1800630',
 * G5420). An address covered the whole corporation, so the lookup returned all 7 members.
 *
 * FIX (data only — no backend code change): create one sub-district + one geofence per
 * board district, then point each office at its sub-district. mtfcc='X0002' is the
 * designated school-subdistrict layer already handled by:
 *   - districtQueries.ts GEOFENCE_DISTRICT_JOIN: (gb.mtfcc='X0002' AND d.district_type='SCHOOL')
 *   - essentialsBrowseService.ts: mtfcc 'X0002' => area_type 'school_subdistrict'
 * After load, a point covers the whole-corp G5420 polygon (→ corp district, now 0 offices)
 * AND exactly one X0002 sub-district (→ its 1 office) → the lookup returns one member.
 *
 * Schema produced (per district N = 1..7):
 *   geofence_boundaries: geo_id='1800630-board-d{N}', mtfcc='X0002', state='18'
 *                        (FIPS, matching the corp G5420 row), source='monroe_county_election_map_arcgis_2026'
 *   districts:           geo_id='1800630-board-d{N}', district_type='SCHOOL', state='in'
 *                        (lowercase, routing convention), mtfcc='X0002', district_id='board-d{N}'
 *   offices:             the office titled '...District {N}' is repointed to the sub-district
 *
 * SOURCE geometry: backend/data/mccsc-board-subdistricts/mccsc-board-districts.geojson
 *   (produced by fetch-mccsc-board-district-polygons.ts; feature.properties.schlbrd = N)
 *
 * Idempotency:
 *   - geofence_boundaries: ON CONFLICT (geo_id, mtfcc) DO NOTHING
 *   - districts:           WHERE NOT EXISTS (district_id = 'board-d{N}')
 *   - offices:             UPDATE only rows still on the corp district (CORP_DISTRICT_GEOID)
 *   Re-running inserts 0 / 0 and updates 0.
 *
 * Usage:
 *   cd ev-accounts/backend
 *   npx tsx scripts/import-mccsc-board-district-polygons.ts --check   # read-only counts
 *   npx tsx scripts/import-mccsc-board-district-polygons.ts           # load (idempotent)
 *
 * ⚠ Writes to the connected DB (DATABASE_URL). Runs inside ONE transaction — all 7
 *   districts + geofences + office relinks commit together or not at all.
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const GEOJSON_PATH = path.resolve(
  __dirname,
  '..',
  'data',
  'mccsc-board-subdistricts',
  'mccsc-board-districts.geojson',
);

const CORP_GEOID = '1800630'; // MCCSC whole-corporation SCHOOL district (G5420)
const MTFCC = 'X0002';
const GB_STATE = '18'; // FIPS — matches the corp G5420 geofence_boundaries.state
const D_STATE = 'in'; // lowercase — districts routing convention
const SOURCE = 'monroe_county_election_map_arcgis_2026';
const EXPECTED = 7;
const CHECK_ONLY = process.argv.includes('--check');

interface Feature {
  geometry: { type: string; coordinates: unknown } | null;
  properties: { schlbrd?: string; [k: string]: unknown };
}
interface FeatureCollection {
  type: string;
  features: Feature[];
}

function loadGeojson(): FeatureCollection {
  let raw: string;
  try {
    raw = fs.readFileSync(GEOJSON_PATH, 'utf8');
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
      throw new Error(
        `GeoJSON not found at ${GEOJSON_PATH}.\n` +
          `  Run: npx tsx scripts/fetch-mccsc-board-district-polygons.ts`,
      );
    }
    throw err;
  }
  const gj = JSON.parse(raw) as FeatureCollection;
  if (gj.type !== 'FeatureCollection' || !Array.isArray(gj.features)) {
    throw new Error('GeoJSON is not a valid FeatureCollection');
  }
  if (gj.features.length !== EXPECTED) {
    throw new Error(`Expected ${EXPECTED} features, got ${gj.features.length}`);
  }
  return gj;
}

async function runChecks(pool: pg.Pool): Promise<void> {
  const q = async (sql: string) => (await pool.query(sql)).rows[0]?.n ?? 0;
  const gb = await q(
    `SELECT count(*) n FROM essentials.geofence_boundaries WHERE geo_id LIKE '${CORP_GEOID}-board-d%' AND mtfcc='${MTFCC}'`,
  );
  const d = await q(
    `SELECT count(*) n FROM essentials.districts WHERE geo_id LIKE '${CORP_GEOID}-board-d%' AND district_type='SCHOOL'`,
  );
  const relinked = await q(
    `SELECT count(*) n FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
       WHERE d.geo_id LIKE '${CORP_GEOID}-board-d%'`,
  );
  const stillOnCorp = await q(
    `SELECT count(*) n FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
       WHERE d.geo_id='${CORP_GEOID}'`,
  );
  console.error(
    `[mccsc-import] --check: geofences=${gb}/7, sub-districts=${d}/7, offices relinked=${relinked}/7, offices still on corp=${stillOnCorp}`,
  );
}

async function main(): Promise<void> {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
  try {
    if (CHECK_ONLY) {
      await runChecks(pool);
      return;
    }

    const gj = loadGeojson();
    const byNum = new Map<string, Feature>();
    for (const f of gj.features) {
      const n = f.properties?.schlbrd;
      if (!n || !/^[1-7]$/.test(n)) throw new Error(`Bad schlbrd value: ${JSON.stringify(n)}`);
      if (!f.geometry) throw new Error(`District ${n} missing geometry`);
      byNum.set(n, f);
    }
    if (byNum.size !== EXPECTED) throw new Error(`Expected districts 1..7, got ${[...byNum.keys()].sort().join(',')}`);

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Guard: corp district must exist and currently hold the 7 offices.
      const corp = await client.query(
        `SELECT id FROM essentials.districts WHERE geo_id=$1 AND district_type='SCHOOL'`,
        [CORP_GEOID],
      );
      if (corp.rowCount !== 1) {
        throw new Error(`Expected exactly 1 corp SCHOOL district for geo_id ${CORP_GEOID}, found ${corp.rowCount}`);
      }
      const corpId: string = corp.rows[0].id;

      let insGb = 0;
      let insD = 0;
      let relinked = 0;

      for (const n of ['1', '2', '3', '4', '5', '6', '7']) {
        const feat = byNum.get(n)!;
        const geoId = `${CORP_GEOID}-board-d${n}`;
        const districtId = `board-d${n}`;
        const label = `Monroe County Community School Board - District ${n}`;
        const geom = JSON.stringify(feat.geometry);

        // 1) geofence_boundaries. ST_Force2D strips any Z; ST_MakeValid repairs ring
        //    self-intersections from the ArcGIS source. Without MakeValid, District 3's
        //    bowtie ring landed invalid and turned the address-search reachability job red
        //    (2026-09-03). A post-load ST_IsValid assertion below is the backstop.
        const gb = await client.query(
          `INSERT INTO essentials.geofence_boundaries
             (geo_id, name, state, mtfcc, geometry, source, imported_at)
           VALUES ($1, $2, $3, $4,
                   public.ST_MakeValid(public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($5)), 4326)),
                   $6, now())
           ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
          [geoId, label, GB_STATE, MTFCC, geom, SOURCE],
        );
        insGb += gb.rowCount ?? 0;

        // 2) districts (district_id is the idempotency key)
        const d = await client.query(
          `INSERT INTO essentials.districts
             (geo_id, district_type, label, state, mtfcc, district_id)
           SELECT $1, 'SCHOOL', $2, $3, $4, $5
           WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_id=$5)`,
          [geoId, label, D_STATE, MTFCC, districtId],
        );
        insD += d.rowCount ?? 0;

        // 3) relink the matching office off the corp district onto this sub-district
        const sub = await client.query(
          `SELECT id FROM essentials.districts WHERE district_id=$1`,
          [districtId],
        );
        const subId: string = sub.rows[0].id;
        const up = await client.query(
          `UPDATE essentials.offices o
              SET district_id=$1
            WHERE o.district_id=$2
              AND o.title ~ ('District[[:space:]]+' || $3 || '([^0-9]|$)')`,
          [subId, corpId, n],
        );
        relinked += up.rowCount ?? 0;
      }

      // Post-condition: every board office must now sit on a sub-district, none on the corp.
      const stillCorp = await client.query(
        `SELECT count(*)::int n FROM essentials.offices o WHERE o.district_id=$1`,
        [corpId],
      );
      const onSubs = await client.query(
        `SELECT count(*)::int n FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
          WHERE d.geo_id LIKE $1`,
        [`${CORP_GEOID}-board-d%`],
      );
      console.error(
        `[mccsc-import] inserted geofences=${insGb}, sub-districts=${insD}, relinked=${relinked}; ` +
          `offices on subs=${onSubs.rows[0].n}, still on corp=${stillCorp.rows[0].n}`,
      );
      if (onSubs.rows[0].n !== 7 || stillCorp.rows[0].n !== 0) {
        throw new Error('Post-condition failed (expected 7 offices on sub-districts, 0 on corp) — rolling back');
      }

      // Validity backstop: no invalid geometry may land (it breaks the address-search
      // reachability job). ST_MakeValid on insert should guarantee this; assert it anyway.
      const invalid = await client.query(
        `SELECT count(*)::int n FROM essentials.geofence_boundaries
          WHERE geo_id LIKE $1 AND mtfcc=$2 AND geometry IS NOT NULL AND NOT public.ST_IsValid(geometry)`,
        [`${CORP_GEOID}-board-d%`, MTFCC],
      );
      if (invalid.rows[0].n !== 0) {
        throw new Error(`Post-condition failed: ${invalid.rows[0].n} imported geofence(s) have invalid geometry — rolling back`);
      }

      await client.query('COMMIT');
      console.error('[mccsc-import] COMMIT ok');
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`[mccsc-import] ROLLBACK: ${(err as Error).message}`);
      process.exitCode = 1;
    } finally {
      client.release();
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error(`[mccsc-import] FAIL: ${(err as Error).message}`);
  process.exit(1);
});

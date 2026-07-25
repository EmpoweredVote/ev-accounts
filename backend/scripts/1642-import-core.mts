/**
 * 1642-import-core.mts — Phase 164.2-02 shared enacted-2026 polygon import core.
 *
 * Reused by the five per-state scripts (1642-{tx,fl,ca,nc,oh}-generate.mts). Each
 * state script supplies a config (FIPS, expected district count, provenance SOURCE,
 * the reprojected-to-EPSG:4326 GeoJSON path, the district property name, and a
 * NEW-map identity anchor) and calls runImport().
 *
 * What this does, per the plan (D-01/D-04/D-08/D-09):
 *   1. Parse the EPSG:4326 GeoJSON (already reprojected via ogr2ogr from the official
 *      state shapefile — see each state script header for the exact source URL + command).
 *   2. NEW-map identity anchor probe (STOP guard, T-1642-01): confirm the state's anchor
 *      point falls in its NEW district under the imported polygons AND differs from the
 *      OLD (G5200) district. If it does not flip, throw — never insert a wrong/old map.
 *   3. --dry-run prints the exact geo_id set + count; the real run inserts ONLY into
 *      essentials.geofence_boundaries as mtfcc='G5200V26', ON CONFLICT (geo_id,mtfcc)
 *      DO NOTHING (idempotent). geo_districts/offices are INTENTIONALLY UNTOUCHED (D-04).
 *
 * All geometry is normalized identically for the probe and the insert:
 *   public.ST_CollectionExtract(public.ST_MakeValid(
 *     public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($json)),4326)),3)
 * — repairs ring self-intersections and keeps polygonal geometry only (as in 1641-tn).
 *
 * All inserts/probes are fully parameterized (V5 — never string-interpolate shapefile
 * text or coordinates).
 */

import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';

export interface ImportConfig {
  state: string;        // abbreviation, e.g. 'TX'
  stateFips: string;    // 2-digit FIPS, e.g. '48'
  expected: number;     // expected district feature count
  source: string;       // provenance string written to geofence_boundaries.source
  geojsonPath: string;  // path to the reprojected EPSG:4326 GeoJSON
  districtCandidates: string[]; // property-name variants for the district number
  anchor: {             // NEW-map identity anchor (must flip vs OLD G5200)
    name: string; lon: number; lat: number; expectNew: string; expectOld: string;
  };
}

export const MTFCC = 'G5200V26';

// The single normalized-geometry SQL expression, used verbatim for probe + insert.
const GEOM_EXPR = (paramIdx: number) =>
  `public.ST_CollectionExtract(public.ST_MakeValid(` +
  `public.ST_SetSRID(public.ST_Force2D(public.ST_GeomFromGeoJSON($${paramIdx})),4326)),3)`;

function resolveColumn(record: Record<string, unknown>, candidates: string[]): string {
  for (const c of candidates) if (c in record) return c;
  throw new Error(
    `Column resolution failed: none of [${candidates.join(', ')}] present. ` +
    `Available: [${Object.keys(record).join(', ')}].`,
  );
}

interface GeoJsonFeature { type: string; geometry: unknown; properties: Record<string, unknown>; }

export async function runImport(cfg: ImportConfig): Promise<void> {
  const DRY_RUN = process.argv.includes('--dry-run');
  const tag = `[1642-${cfg.state.toLowerCase()}-generate]`;
  console.log(`${tag} ${cfg.state} enacted-2026 congressional districts -> ${MTFCC}`);
  if (DRY_RUN) console.log('  DRY RUN — no DB writes');

  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

  try {
    const raw = fs.readFileSync(cfg.geojsonPath, 'utf8');
    const fc = JSON.parse(raw) as { type: string; features: GeoJsonFeature[] };
    if (fc.type !== 'FeatureCollection' || !Array.isArray(fc.features)) {
      throw new Error('Unexpected GeoJSON shape: expected a FeatureCollection');
    }
    if (fc.features.length !== cfg.expected) {
      throw new Error(`Expected exactly ${cfg.expected} ${cfg.state} features, got ${fc.features.length}`);
    }

    // Map District -> geo_id, dedup-check.
    const rows: { geoId: string; districtNum: number; geomJson: string }[] = [];
    const seen = new Set<string>();
    for (const f of fc.features) {
      const props = f.properties ?? {};
      const col = resolveColumn(props, cfg.districtCandidates);
      // Extract the first integer from the district field — handles numeric ("9"),
      // zero-padded ("01"), and labelled ("CD 01" / "Congressional District 01") variants.
      const m = String(props[col]).match(/\d+/);
      const districtNum = m ? Number(m[0]) : NaN;
      if (!Number.isInteger(districtNum) || districtNum < 1 || districtNum > cfg.expected) {
        throw new Error(`Bad district number ${String(props[col])} (expected 1-${cfg.expected})`);
      }
      const geoId = cfg.stateFips + String(districtNum).padStart(2, '0');
      if (seen.has(geoId)) throw new Error(`Duplicate district ${geoId} in feed`);
      seen.add(geoId);
      if (!f.geometry) throw new Error(`District ${districtNum}: feature has no geometry`);
      rows.push({ geoId, districtNum, geomJson: JSON.stringify(f.geometry) });
    }
    rows.sort((a, b) => a.districtNum - b.districtNum);

    // ── NEW-map identity anchor probe (STOP guard) ──────────────────────────
    const a = cfg.anchor;
    // NEW: which imported feature covers the anchor point?
    let newGeoId: string | null = null;
    for (const r of rows) {
      const q = await pool.query(
        `SELECT public.ST_Covers(${GEOM_EXPR(1)}, public.ST_SetSRID(public.ST_MakePoint($2,$3),4326)) AS c`,
        [r.geomJson, a.lon, a.lat],
      );
      if (q.rows[0]?.c === true) { newGeoId = r.geoId; break; }
    }
    // OLD: which current-vintage G5200 district covers the anchor point?
    const oldQ = await pool.query(
      `SELECT geo_id FROM essentials.geofence_boundaries
       WHERE mtfcc='G5200' AND length(geo_id)=4 AND substr(geo_id,1,2)=$1
         AND public.ST_Covers(geometry, public.ST_SetSRID(public.ST_MakePoint($2,$3),4326))
       LIMIT 1`,
      [cfg.stateFips, a.lon, a.lat],
    );
    const oldGeoId: string | null = oldQ.rows[0]?.geo_id ?? null;

    console.log(`  anchor ${a.name} (${a.lon},${a.lat}): NEW=${newGeoId} OLD=${oldGeoId} (expect NEW=${a.expectNew}, OLD=${a.expectOld})`);
    if (newGeoId !== a.expectNew) {
      throw new Error(`ANCHOR FAIL (${cfg.state}): point resolves to NEW ${newGeoId}, expected ${a.expectNew}. Wrong/old plan or mis-projected — STOP, do not insert.`);
    }
    if (oldGeoId !== a.expectOld) {
      throw new Error(`ANCHOR FAIL (${cfg.state}): OLD G5200 resolves to ${oldGeoId}, expected ${a.expectOld}. Baseline mismatch — STOP.`);
    }
    if (newGeoId === oldGeoId) {
      throw new Error(`ANCHOR FAIL (${cfg.state}): NEW == OLD (${newGeoId}) — the map did not move at the anchor. STOP.`);
    }
    console.log(`  anchor OK: enacted map flips ${oldGeoId} -> ${newGeoId}`);

    if (DRY_RUN) {
      console.log(`  [dry-run] would insert ${rows.length} rows: ${rows.map(r => r.geoId).join(', ')}`);
      console.log(`\nDRY-RUN complete — ${rows.length} ${cfg.state} districts (expected ${cfg.expected}).`);
      return;
    }

    // ── Real insert ─────────────────────────────────────────────────────────
    let inserted = 0, already = 0;
    for (const r of rows) {
      const name = `Congressional District ${r.districtNum}`;
      const res = await pool.query(
        `INSERT INTO essentials.geofence_boundaries
           (geo_id, ocd_id, name, state, mtfcc, geometry, source, imported_at)
         VALUES ($1, NULL, $2, $3, $4, ${GEOM_EXPR(5)}, $6, now())
         ON CONFLICT (geo_id, mtfcc) DO NOTHING`,
        [r.geoId, name, cfg.stateFips, MTFCC, r.geomJson, cfg.source],
      );
      if ((res.rowCount ?? 0) > 0) { inserted++; console.log(`  inserted geo_id=${r.geoId} (${name})`); }
      else { already++; console.log(`  already_exists geo_id=${r.geoId} (${name})`); }
    }
    console.log(`\n=== ${cfg.state} Summary ===`);
    console.log(`  geofence_boundaries inserted:        ${inserted}`);
    console.log(`  geofence_boundaries already existed: ${already}`);
    console.log(`  geo_districts: INTENTIONALLY UNTOUCHED (D-04 no-touch)`);
  } finally {
    await pool.end();
  }
}

import { pool } from './db.js';
import { FIPS_TO_USPS, USPS_TO_FIPS } from './usStateCodes.js';

export interface BoundaryResult {
  hasBoundary: true;
  layer: string;
  geoid: string;
  name: string;
  bbox: [number, number, number, number];
  geojson: { type: 'Polygon' | 'MultiPolygon'; coordinates: unknown };
}
export type BoundaryResponse = BoundaryResult | { hasBoundary: false };

/**
 * Simplified constituency geometry for the Read & Rank motif, keyed by TIGER
 * MTFCC + geo_id. Returns { hasBoundary: false } when absent so the frontend
 * falls back to the dot-field. Tolerance ~0.001 deg suits a ~64px render.
 *
 * Antimeridian handling: geometries that cross 180 deg longitude (Alaska's
 * Aleutians, and the US union that contains them) otherwise report a ~359 deg
 * envelope, which the frontend projects as a near-global sliver. When the
 * envelope spans more than 180 deg we ST_ShiftLongitude into the 0..360 frame
 * so the bbox and path stay tight and compact. Normal boundaries are untouched.
 */
export async function getBoundary(layer: string, geoid: string): Promise<BoundaryResponse> {
  const { rows } = await pool.query<{
    geo_id: string; mtfcc: string; name: string | null;
    minx: number | null; miny: number | null; maxx: number | null; maxy: number | null;
    geojson: string | null;
  }>(
    `WITH b AS (
       SELECT geo_id, mtfcc, name,
              CASE WHEN (ST_XMax(geometry) - ST_XMin(geometry)) > 180
                   THEN ST_ShiftLongitude(geometry)
                   ELSE geometry END AS geom
       FROM essentials.geofence_boundaries
       WHERE mtfcc = $1 AND geo_id = $2
       LIMIT 1
     )
     SELECT geo_id, mtfcc, name,
            ST_XMin(ST_Envelope(geom)) AS minx, ST_YMin(ST_Envelope(geom)) AS miny,
            ST_XMax(ST_Envelope(geom)) AS maxx, ST_YMax(ST_Envelope(geom)) AS maxy,
            ST_AsGeoJSON(ST_SimplifyPreserveTopology(geom, 0.001)) AS geojson
     FROM b`,
    [layer, geoid],
  );

  const row = rows[0];
  if (!row || !row.geojson || row.minx == null) return { hasBoundary: false };

  return {
    hasBoundary: true,
    layer: row.mtfcc,
    geoid: row.geo_id,
    name: row.name ?? '',
    bbox: [Number(row.minx), Number(row.miny), Number(row.maxx), Number(row.maxy)],
    geojson: JSON.parse(row.geojson),
  };
}

/**
 * Batch variant of getBoundary. Accepts an array of {layer, geoid} refs,
 * deduplicates, fetches all matching boundaries in one query, and returns
 * a Map keyed by "layer:geoid". Refs not found in the DB are simply absent
 * from the map — callers should treat that as hasBoundary:false.
 */
export async function getBoundaryBatch(
  refs: Array<{ layer: string; geoid: string }>,
): Promise<Map<string, BoundaryResult>> {
  const unique = new Map<string, { layer: string; geoid: string }>();
  for (const ref of refs) unique.set(`${ref.layer}:${ref.geoid}`, ref);
  if (unique.size === 0) return new Map();

  const pairs = [...unique.values()];
  const placeholders = pairs.map((_, i) => `($${i * 2 + 1}, $${i * 2 + 2})`).join(', ');

  const { rows } = await pool.query<{
    geo_id: string; mtfcc: string; name: string | null;
    minx: number | null; miny: number | null; maxx: number | null; maxy: number | null;
    geojson: string | null;
  }>(
    `WITH b AS (
       SELECT geo_id, mtfcc, name,
              CASE WHEN (ST_XMax(geometry) - ST_XMin(geometry)) > 180
                   THEN ST_ShiftLongitude(geometry)
                   ELSE geometry END AS geom
       FROM essentials.geofence_boundaries
       WHERE (mtfcc, geo_id) IN (${placeholders})
     )
     SELECT geo_id, mtfcc, name,
            ST_XMin(ST_Envelope(geom)) AS minx, ST_YMin(ST_Envelope(geom)) AS miny,
            ST_XMax(ST_Envelope(geom)) AS maxx, ST_YMax(ST_Envelope(geom)) AS maxy,
            ST_AsGeoJSON(ST_SimplifyPreserveTopology(geom, 0.001)) AS geojson
     FROM b`,
    pairs.flatMap((r) => [r.layer, r.geoid]),
  );

  const result = new Map<string, BoundaryResult>();
  for (const row of rows) {
    if (!row.geojson || row.minx == null || row.miny == null || row.maxx == null || row.maxy == null) continue;
    let geojson: BoundaryResult['geojson'];
    try {
      geojson = JSON.parse(row.geojson);
    } catch {
      console.warn(`[getBoundaryBatch] malformed geojson for ${row.mtfcc}:${row.geo_id}, skipping`);
      continue;
    }
    result.set(`${row.mtfcc}:${row.geo_id}`, {
      hasBoundary: true,
      layer: row.mtfcc,
      geoid: row.geo_id,
      name: row.name ?? '',
      bbox: [Number(row.minx), Number(row.miny), Number(row.maxx), Number(row.maxy)],
      geojson,
    });
  }
  return result;
}

/** A computed frame: the dissolved union of the counties a district overlaps. */
export interface UnionFrame {
  bbox: [number, number, number, number];
  geojson: { type: 'Polygon' | 'MultiPolygon'; coordinates: unknown };
  /** GEOIDs of the G4020 counties this district overlaps. Drives the county relevance tier. */
  countyGeoIds: string[];
}

/**
 * Frame geometry + member county GEOIDs for sub-state districts (state-legislative,
 * school, township): the union of the counties (G4020) each district actually overlaps.
 * The union geometry is used as the visual frame for state-leg districts; the member
 * GEOIDs (countyGeoIds) drive read-rank's county relevance tier for all of them.
 * Keyed by "layer:geoid" of the district (the child), matching the refs passed in.
 *
 * Counties are matched by genuine areal overlap — ST_Intersects (GiST-indexed)
 * then a positive ST_Area(ST_Intersection) so districts sharing only an edge
 * with a neighbouring county don't drag that county into the frame. Geometry is
 * simplified and antimeridian-shifted exactly like getBoundary, so the embedded
 * frame matches the child's projection conventions.
 */
export async function getCountyUnionFrames(
  refs: Array<{ layer: string; geoid: string }>,
): Promise<Map<string, UnionFrame>> {
  const unique = new Map<string, { layer: string; geoid: string }>();
  for (const ref of refs) unique.set(`${ref.layer}:${ref.geoid}`, ref);
  if (unique.size === 0) return new Map();

  const pairs = [...unique.values()];
  // VALUES needs explicit types on the first row so the JOIN columns resolve to text.
  const values = pairs
    .map((_, i) => (i === 0 ? `($1::text, $2::text)` : `($${i * 2 + 1}, $${i * 2 + 2})`))
    .join(', ');

  const { rows } = await pool.query<{
    layer: string; geoid: string;
    minx: number | null; miny: number | null; maxx: number | null; maxy: number | null;
    geojson: string | null;
    county_geoids: string[] | null;
  }>(
    `WITH dist AS (
       SELECT v.layer, v.geoid, gb.geometry
       FROM (VALUES ${values}) AS v(layer, geoid)
       JOIN essentials.geofence_boundaries gb
         ON gb.mtfcc = v.layer AND gb.geo_id = v.geoid
     ),
     u AS (
       SELECT d.layer, d.geoid, ST_Multi(ST_Union(c.geometry)) AS geom,
              array_agg(DISTINCT c.geo_id ORDER BY c.geo_id) AS county_geoids
       FROM dist d
       JOIN essentials.geofence_boundaries c
         ON c.mtfcc = 'G4020'
        AND ST_Intersects(c.geometry, d.geometry)
        AND ST_Area(ST_Intersection(c.geometry, d.geometry)) > 1e-9
       GROUP BY d.layer, d.geoid
     ),
     s AS (
       SELECT layer, geoid, county_geoids,
              CASE WHEN (ST_XMax(geom) - ST_XMin(geom)) > 180
                   THEN ST_ShiftLongitude(geom) ELSE geom END AS geom
       FROM u
     )
     SELECT layer, geoid, county_geoids,
            ST_XMin(ST_Envelope(geom)) AS minx, ST_YMin(ST_Envelope(geom)) AS miny,
            ST_XMax(ST_Envelope(geom)) AS maxx, ST_YMax(ST_Envelope(geom)) AS maxy,
            ST_AsGeoJSON(ST_SimplifyPreserveTopology(geom, 0.001)) AS geojson
     FROM s`,
    pairs.flatMap((r) => [r.layer, r.geoid]),
  );

  const result = new Map<string, UnionFrame>();
  for (const row of rows) {
    if (!row.geojson || row.minx == null || row.miny == null || row.maxx == null || row.maxy == null) continue;
    let geojson: UnionFrame['geojson'];
    try {
      geojson = JSON.parse(row.geojson);
    } catch {
      console.warn(`[getCountyUnionFrames] malformed geojson for ${row.layer}:${row.geoid}, skipping`);
      continue;
    }
    result.set(`${row.layer}:${row.geoid}`, {
      bbox: [Number(row.minx), Number(row.miny), Number(row.maxx), Number(row.maxy)],
      geojson,
      countyGeoIds: row.county_geoids ?? [],
    });
  }
  return result;
}

/**
 * The G4020 counties each sub-state district overlaps — keyed by "layer:geoid" of
 * the district. This is the county set that drives read-rank's county relevance tier.
 *
 * Reads the precomputed `essentials.district_county_overlap` table (populated by
 * scripts/backfill-district-county-overlap.ts) with an indexed lookup. The overlap is
 * static geometry data; computing it live (ST_Intersects + ST_Area(ST_Intersection)
 * over full-resolution polygons for ~300 districts) took ~30 s on every /readrank/races
 * request — see migration 1315. A district absent from the table (e.g. new geography not
 * yet backfilled) simply yields no counties, so the caller degrades to `countyGeoIds: []`.
 */
export async function getDistrictCountyGeoIds(
  refs: Array<{ layer: string; geoid: string }>,
): Promise<Map<string, string[]>> {
  const unique = new Map<string, { layer: string; geoid: string }>();
  for (const ref of refs) unique.set(`${ref.layer}:${ref.geoid}`, ref);
  if (unique.size === 0) return new Map();

  const pairs = [...unique.values()];
  // VALUES needs explicit types on the first row so the JOIN columns resolve to text.
  const values = pairs
    .map((_, i) => (i === 0 ? `($1::text, $2::text)` : `($${i * 2 + 1}, $${i * 2 + 2})`))
    .join(', ');

  const { rows } = await pool.query<{ layer: string; geoid: string; county_geoids: string[] | null }>(
    `SELECT o.district_layer AS layer, o.district_geoid AS geoid,
            array_agg(o.county_geoid ORDER BY o.county_geoid) AS county_geoids
       FROM essentials.district_county_overlap o
       JOIN (VALUES ${values}) AS v(layer, geoid)
         ON v.layer = o.district_layer AND v.geoid = o.district_geoid
      GROUP BY o.district_layer, o.district_geoid`,
    pairs.flatMap((r) => [r.layer, r.geoid]),
  );

  const result = new Map<string, string[]>();
  for (const row of rows) result.set(`${row.layer}:${row.geoid}`, row.county_geoids ?? []);
  return result;
}

/** County (G4020) GEOIDs for each USPS state, keyed by state code. Read-only.
 *  Used to assign statewide races to every county so they surface in each county view.
 *  The `state` column in geofence_boundaries is 2-digit FIPS, so USPS input is mapped
 *  to FIPS for the query, and the result is re-keyed back to USPS for callers. */
export async function getStateCountyGeoIds(uspsStates: string[]): Promise<Map<string, string[]>> {
  const states = [...new Set(uspsStates.filter(Boolean))];
  if (states.length === 0) return new Map();

  const fipsCodes: string[] = [];
  for (const usps of states) {
    const fips = USPS_TO_FIPS[usps];
    if (!fips) continue; // unknown state code — skip rather than query garbage
    fipsCodes.push(fips);
  }
  if (fipsCodes.length === 0) return new Map();

  const { rows } = await pool.query<{ state: string; geo_id: string }>(
    `SELECT state, geo_id
       FROM essentials.geofence_boundaries
      WHERE mtfcc = 'G4020' AND state = ANY($1)
      ORDER BY geo_id`,
    [fipsCodes],
  );
  const map = new Map<string, string[]>();
  for (const r of rows) {
    const usps = FIPS_TO_USPS[r.state];
    if (!usps) continue;
    const list = map.get(usps) ?? [];
    list.push(r.geo_id);
    map.set(usps, list);
  }
  return map;
}

/** Display names for county (G4020) GEOIDs. Read-only; labels the browse county picker. */
export async function getCountyNames(geoIds: string[]): Promise<Record<string, string>> {
  const ids = [...new Set(geoIds.filter(Boolean))];
  if (ids.length === 0) return {};
  const { rows } = await pool.query<{ geo_id: string; name: string }>(
    `SELECT geo_id, name
       FROM essentials.geofence_boundaries
      WHERE mtfcc = 'G4020' AND geo_id = ANY($1)`,
    [ids],
  );
  const out: Record<string, string> = {};
  for (const r of rows) out[r.geo_id] = r.name;
  return out;
}

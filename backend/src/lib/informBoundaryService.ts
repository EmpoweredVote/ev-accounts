import { pool } from './db.js';

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

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

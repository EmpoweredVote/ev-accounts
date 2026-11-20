/**
 * Stage 2 -- PRECISION. Where was this photograph actually taken?
 *
 * 🔴🔴 GEOMETRY IS THE ONLY TRUSTWORTHY MEMBERSHIP KEY. Sweeping a category named for a
 * county returns photographs from other counties and other STATES: a Colorado river
 * photograph once topped seven Nebraska counties, and sweeping the Indiana Dunes
 * categories for Gary returned Porter County. The county's own TIGER polygon is the
 * arbiter and nothing else is.
 *
 * 🔴 FILES WITH NO COORDINATES ARE KEPT SEPARATELY AS `unlocated`, NOT DISCARDED.
 * Carried forward from geocheck-commons-candidates.py: absence of a coordinate is not
 * evidence the photograph is elsewhere, and some of the best candidates are older
 * uploads with no GPS. They simply cannot be cleared automatically -- the spec's
 * round-2 caption rule is what will clear them.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import { commonsApi } from './commonsClient.js';
import type { ApiFn } from './sweep.js';
import type { CandidateFile } from './types.js';

/** Minimal shape of a database query, so tests need no live connection. */
export type QueryFn = (sql: string, params?: unknown[]) => Promise<Array<Record<string, unknown>>>;

/**
 * A county the pipeline was asked about has no polygon to test against.
 *
 * 🔴 This is a THROW and not an empty result on purpose. A county with no polygon
 * matches nothing, and "matched nothing" is exactly what a county with no photographs
 * looks like. A detector that reports "nothing found" is untrusted until it can tell
 * those two apart.
 */
export class MissingPolygonError extends Error {
  constructor(public readonly stateFips: string, message: string, public readonly geoids: string[] = []) {
    super(message);
    this.name = 'MissingPolygonError';
  }
}

const COUNTY_SQL = `
  SELECT geo_id,
         name,
         geometry IS NULL AS geom_null,
         CASE WHEN geometry IS NULL THEN false ELSE ST_IsValid(geometry) END AS geom_valid,
         CASE WHEN geometry IS NULL THEN false
              ELSE ST_XMin(geometry) >= -180 AND ST_XMax(geometry) <= 180
               AND ST_YMin(geometry) >= -90  AND ST_YMax(geometry) <= 90
         END AS geom_in_bounds
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4020' AND state = $1
   ORDER BY geo_id`;

// (mtfcc, geo_id) is the key -- geo_id alone is NOT unique and collides across layers.
const CONTAINS_SQL = `
  SELECT g.geo_id, f.title
    FROM unnest($2::text[], $3::float8[], $4::float8[]) AS f(title, lat, lon)
    JOIN essentials.geofence_boundaries g
      ON g.mtfcc = 'G4020'
     AND g.state = $1
     AND ST_Contains(g.geometry, ST_SetSRID(ST_MakePoint(f.lon, f.lat), 4326))`;

export interface AttachOptions { api?: ApiFn }

/** Fill in lat/lon from Commons, 50 titles per request. */
export async function attachCoordinates(files: CandidateFile[], opts: AttachOptions = {}): Promise<CandidateFile[]> {
  const api = opts.api ?? commonsApi;
  const coords = new Map<string, { lat: number; lon: number }>();
  for (let i = 0; i < files.length; i += 50) {
    const batch = files.slice(i, i + 50);
    const d = (await api({ action: 'query', titles: batch.map((f) => f.title).join('|'), prop: 'coordinates', coprimary: 'all', colimit: 500 })) as
      { query?: { pages?: Array<{ title: string; coordinates?: Array<{ lat?: number; lon?: number }> }> } };
    for (const p of d.query?.pages ?? []) {
      const c = p.coordinates?.[0];
      if (typeof c?.lat === 'number' && typeof c?.lon === 'number') coords.set(p.title, { lat: c.lat, lon: c.lon });
    }
  }
  return files.map((f) => {
    const c = coords.get(f.title);
    return c ? { ...f, lat: c.lat, lon: c.lon } : f;
  });
}

/** Every county in the state, from our own boundary table. */
export async function listCounties(stateFips: string, query: QueryFn): Promise<Array<{ geoid: string; name: string }>> {
  const rows = await query(COUNTY_SQL, [stateFips]);
  if (rows.length === 0) {
    throw new MissingPolygonError(stateFips, `No G4020 county polygons for state '${stateFips}'. Refusing to report zero candidates for a state we cannot test against.`);
  }
  // 🔴 A COUNTY'S POLYGON CAN BE PRESENT AND USELESS, and then that county matches
  // nothing and arrives at the operator looking exactly like a county with no
  // photographs. NULL, invalid, and valid-but-in-the-wrong-CRS all do this: Holladay's
  // five wards were Web Mercator metres tagged SRID 4326 and passed every other
  // geometric check while matching no address at all.
  const unusable = rows.filter((r) => r.geom_null === true || r.geom_valid === false || r.geom_in_bounds === false);
  if (unusable.length > 0) {
    const named = unusable.map((r) => `${String(r.geo_id)} (${String(r.name)})`).join(', ');
    throw new MissingPolygonError(
      stateFips,
      `${unusable.length} county polygon(s) in state '${stateFips}' are NULL, invalid, or outside earth bounds: ${named}. Refusing to report zero candidates for a county we cannot test against.`,
      unusable.map((r) => String(r.geo_id)),
    );
  }
  return rows.map((r) => ({ geoid: String(r.geo_id), name: String(r.name) }));
}

export interface AssignResult {
  located: Map<string, CandidateFile[]>;
  unlocated: CandidateFile[];
  outside: CandidateFile[];
}

/** Sort files into the counties that contain them, those we cannot place, and those outside. */
export async function assignToCounties(files: CandidateFile[], stateFips: string, query: QueryFn): Promise<AssignResult> {
  // Establish the state HAS polygons before concluding anything from a non-match.
  await listCounties(stateFips, query);

  const located = new Map<string, CandidateFile[]>();
  const unlocated = files.filter((f) => f.lat === null || f.lon === null);
  const placeable = files.filter((f) => f.lat !== null && f.lon !== null);
  if (placeable.length === 0) return { located, unlocated, outside: [] };

  const rows = await query(CONTAINS_SQL, [
    stateFips,
    placeable.map((f) => f.title),
    placeable.map((f) => f.lat as number),
    placeable.map((f) => f.lon as number),
  ]);

  const byTitle = new Map(placeable.map((f) => [f.title, f]));
  const matched = new Set<string>();
  for (const r of rows) {
    const title = String(r.title);
    const geoid = String(r.geo_id);
    const file = byTitle.get(title);
    if (!file) continue;
    matched.add(title);
    const list = located.get(geoid) ?? [];
    list.push(file);
    located.set(geoid, list);
  }
  // A coordinate inside no county is a finding -- a bad geotag or a photo genuinely
  // elsewhere. It is counted and returned, never quietly dropped.
  const outside = placeable.filter((f) => !matched.has(f.title));
  return { located, unlocated, outside };
}

/**
 * The names of places inside a county, and whether we hold a place list for that state at all.
 *
 * 🔴 THE SECOND HALF OF THAT RETURN IS THE POINT. Measured on prod 2026-11-20: 52 states have
 * G4020 county polygons and only 32 have G4110 place polygons — Nebraska and Delaware, the two
 * states this programme has swept, have NONE. An empty list therefore means one of two
 * completely different things, and a caption rule that could not tell them apart would report
 * "no caption evidence" across 20 states and look like a finding rather than a gap.
 *
 * `placeListAvailable` is false only when the STATE has no place polygons. A county that
 * genuinely contains no incorporated place returns an empty list with the flag TRUE.
 */
const PLACES_SQL = `
  WITH c AS (
    SELECT geometry FROM essentials.geofence_boundaries
     WHERE mtfcc = 'G4020' AND state = $1 AND geo_id = $2
  ), p AS (
    SELECT name, geometry FROM essentials.geofence_boundaries
     WHERE mtfcc = 'G4110' AND state = $1
  )
  SELECT (SELECT count(*) FROM p) AS state_places,
         coalesce((
           SELECT array_agg(p.name ORDER BY p.name)
             FROM p, c
            WHERE ST_Contains(c.geometry, ST_Centroid(p.geometry))
         ), ARRAY[]::text[]) AS places`;

export async function listPlacesInCounty(
  stateFips: string, geoid: string, query: QueryFn,
): Promise<{ places: string[]; placeListAvailable: boolean }> {
  const rows = await query(PLACES_SQL, [stateFips, geoid]);
  const row = rows[0] ?? {};
  // 🔴 TIGER STORES THE LSAD SUFFIX IN THE NAME: 'Champaign city', 'Bondville village',
  // 'St. Joseph village'. A caption says "Urbana, Illinois", never "Urbana city, Illinois", so
  // matching the stored names verbatim would have made this list DEAD WEIGHT in all 32 states
  // that have one — present, queried, and never matching anything. Found by running this query
  // against prod rather than against the fake db in the tests above.
  const places = ((row.places as string[] | null) ?? [])
    .map((n) => n.replace(/\s+(city|town|village|borough|municipality|township|CDP)$/i, '').trim())
    .filter(Boolean);
  return {
    places: [...new Set(places)],
    placeListAvailable: Number(row.state_places ?? 0) > 0,
  };
}

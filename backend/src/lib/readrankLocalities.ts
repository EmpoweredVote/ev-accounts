import { pool } from './db.js';
import { USPS_TO_FIPS, FIPS_TO_USPS } from './usStateCodes.js';

/**
 * Read & Rank — city-name lookup. Maps a typed city name to the incorporated
 * place(s) (Census G4110) and the county each sits in, so the app can open that
 * county's browse view without a geocoder.
 *
 * Data shape (verified against prod): essentials.geofence_boundaries.name carries
 * the Census LSAD suffix ("Irvine city", "Bethel Park municipality", "Indianapolis
 * city (balance)"), but ~580 places (mostly Indiana towns) carry none ("Akron").
 * `state` is a 2-digit FIPS code, not USPS.
 */

export type LocalityQueryResult =
  | { ok: true; q: string; state: string | null }
  | { ok: false; message: string };

export interface Locality {
  name: string;
  state: string;
  placeGeoid: string;
  countyGeoid: string;
}

const Q_RE = /^[\p{L}\p{M} .'’-]+$/u;
const STATE_RE = /^[A-Za-z]{2}$/;

/** Census place suffixes seen in G4110 names, longest first so stripping is greedy. */
const BASE_SUFFIXES = [
  'consolidated government',
  'metropolitan government',
  'unified government',
  'metro government',
  'metro township',
  'urban county',
  'municipality',
  'township',
  'borough',
  'village',
  'city',
  'town',
];
const SUFFIXES = BASE_SUFFIXES.flatMap((s) => [`${s} (balance)`, s]);

const SUFFIX_RE = new RegExp(`^(.+?) (?:${SUFFIXES.map((s) => s.replace(/[()]/g, '\\$&')).join('|')})$`, 'i');

/** Drop one trailing Census suffix. Leaves unsuffixed names (and a bare suffix word) alone. */
export function stripPlaceSuffix(name: string): string {
  const m = SUFFIX_RE.exec(name);
  return m ? m[1] : name;
}

export function validateLocalityQuery(rawQ: unknown, rawState: unknown): LocalityQueryResult {
  if (typeof rawQ !== 'string') return { ok: false, message: 'q is required' };
  const q = rawQ.trim();
  if (q.length < 2 || q.length > 60) return { ok: false, message: 'q must be 2-60 characters' };
  if (!Q_RE.test(q)) return { ok: false, message: 'q may contain only letters, spaces, periods, apostrophes and hyphens' };
  if (rawState === undefined || rawState === '') return { ok: true, q, state: null };
  if (typeof rawState !== 'string' || !STATE_RE.test(rawState)) {
    return { ok: false, message: 'state must be a 2-letter USPS code' };
  }
  return { ok: true, q, state: rawState.toUpperCase() };
}

const LOCALITY_SQL = `
  SELECT b.name,
         b.state,
         b.geo_id AS place_geoid,
         cc.county_geo_id AS county_geoid
    FROM essentials.geofence_boundaries b
    JOIN essentials.geofence_child_county cc
      ON cc.child_geo_id = b.geo_id AND cc.child_mtfcc = 'G4110'
   WHERE b.mtfcc = 'G4110'
     AND b.name IS NOT NULL
     AND cc.county_geo_id IS NOT NULL
     AND public.f_unaccent(lower(b.name)) = ANY (
           ARRAY(SELECT public.f_unaccent(lower(c)) FROM unnest($1::text[]) AS c))
     AND ($2::text IS NULL OR b.state = $2::text)
   ORDER BY b.state, b.name
   LIMIT 10`;

interface LocalityRow {
  name: string;
  state: string;
  place_geoid: string;
  county_geoid: string;
}

/**
 * Places whose name equals `q` (case- and accent-insensitive, with or without the
 * Census suffix). `state` is USPS or null. An unknown USPS code matches nothing.
 */
export async function findLocalities(q: string, state: string | null): Promise<Locality[]> {
  let fips: string | null = null;
  if (state) {
    fips = USPS_TO_FIPS[state.toUpperCase()] ?? null;
    if (!fips) return [];
  }
  const candidates = [q, ...SUFFIXES.map((s) => `${q} ${s}`)];
  const { rows } = await pool.query<LocalityRow>(LOCALITY_SQL, [candidates, fips]);
  return rows.map((r) => ({
    name: stripPlaceSuffix(r.name),
    state: FIPS_TO_USPS[r.state] ?? r.state,
    placeGeoid: r.place_geoid,
    countyGeoid: r.county_geoid,
  }));
}

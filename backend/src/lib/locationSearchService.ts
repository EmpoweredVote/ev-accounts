/**
 * locationSearchService — bare place-name resolver (RSLV-01/04/06/07).
 *
 * WHY THIS FILE EXISTS:
 * Exposes searchPlaceNames(query, limit), a pg_trgm/f_unaccent ranked,
 * disambiguated resolver over essentials.governments (curated, deep-seeded
 * places) UNIONed with the nationwide essentials.gazetteer_places /
 * essentials.gazetteer_counties reference tables (Phase 212-01/212-03 —
 * trgm GIN indexes + 32,333 places / 3,222 counties live in production).
 *
 * Modeled directly on campaignFinanceSearchService.ts's word_similarity() +
 * f_unaccent() + length-calibrated-threshold idiom (see that file for the
 * canonical pattern this mirrors).
 *
 * Guarantees (see 212-CONTEXT.md D-05/D-06/D-07, 212-RESEARCH.md Pitfall 3):
 *   - D-05 label format: "Name, ST · <City|County|State>".
 *   - D-06 ranking: curated rows (source_boost=1) outrank Gazetteer-only rows
 *     (source_boost=0); ties broken by trigram similarity, then exact-match,
 *     then name A→Z (amended 2026-07-20 — no population column exists in any
 *     source table, so population is NEVER used as a tiebreak).
 *   - D-07 coverage signal: has_local_data is computed from a live
 *     EXISTS(...essentials.chambers...) check, never from the frontend's
 *     static coverage catalog file.
 *   - RSLV-07 wrong-state guard: every candidate's `state` is sourced from
 *     the matched row's own state column (governments.state or the
 *     geofence_boundaries FIPS it's paired with) — never inferred from the
 *     query string. Multiple matches ALWAYS return the full ranked list;
 *     this resolver never silently collapses to one "best guess" row.
 *   - RSLV-04: this file does NOT import the Census one-line address
 *     geocoder helper — that geocoder stays street-address-only.
 *   - 212-06 gap closure: curated governments whose own geo_id is NULL
 *     resolve their real place-level geo_id/mtfcc via a LATERAL lookup over
 *     chambers -> offices -> districts (the single linked G4110/G4020
 *     district), so they become resolvable and correctly dedupe against
 *     their gazetteer/geofence twin instead of emitting an unresolvable
 *     duplicate candidate.
 *
 * All response objects are built from explicit field whitelists (never
 * object spread); internal governments.id UUIDs are never exposed.
 */

import { pool } from './db.js';
import { FIPS_TO_ABBREV } from './essentialsBrowseService.js';

// ---------------------------------------------------------------------------
// Public interfaces
// ---------------------------------------------------------------------------

export interface PlaceCandidate {
  geo_id: string;
  mtfcc: string;
  label: string;
  state: string;
  area_type: string;
  has_local_data: boolean;
}

export class LocationSearchQueryTooShortError extends Error {
  constructor(message = 'Query must be at least 2 characters') {
    super(message);
    this.name = 'LocationSearchQueryTooShortError';
  }
}

// ---------------------------------------------------------------------------
// DB row interface (internal — never exposed directly)
// ---------------------------------------------------------------------------

interface LocationSearchRow {
  geo_id: string;
  mtfcc: string | null;
  name: string;
  gov_state: string | null;
  geofence_state_fips: string | null;
  gov_type: string | null;
  has_local_data: boolean;
  sim: string; // pg returns numeric as string
  exact_match: boolean;
}

// ---------------------------------------------------------------------------
// Static 50-state name/abbrev exact match (Pattern 2 step 2, 212-RESEARCH.md)
// ---------------------------------------------------------------------------

const STATE_ABBREV_TO_NAME: Record<string, string> = {
  AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California',
  CO: 'Colorado', CT: 'Connecticut', DE: 'Delaware', DC: 'District of Columbia',
  FL: 'Florida', GA: 'Georgia', HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois',
  IN: 'Indiana', IA: 'Iowa', KS: 'Kansas', KY: 'Kentucky', LA: 'Louisiana',
  ME: 'Maine', MD: 'Maryland', MA: 'Massachusetts', MI: 'Michigan',
  MN: 'Minnesota', MS: 'Mississippi', MO: 'Missouri', MT: 'Montana',
  NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey',
  NM: 'New Mexico', NY: 'New York', NC: 'North Carolina', ND: 'North Dakota',
  OH: 'Ohio', OK: 'Oklahoma', OR: 'Oregon', PA: 'Pennsylvania',
  RI: 'Rhode Island', SC: 'South Carolina', SD: 'South Dakota',
  TN: 'Tennessee', TX: 'Texas', UT: 'Utah', VT: 'Vermont', VA: 'Virginia',
  WA: 'Washington', WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming',
};

// ---------------------------------------------------------------------------
// Candidate assembly helpers
// ---------------------------------------------------------------------------

/**
 * A place row's state must come from the row itself — never the query
 * string (RSLV-07). governments.state (and gazetteer_places/counties.state)
 * are already USPS abbrevs; geofence_boundaries.state is FIPS and must be
 * mapped via the shared FIPS_TO_ABBREV table when a matched row has no
 * direct state of its own (WARNING: governments.state can be null for some
 * curated rows whose only state signal is the paired geofence).
 */
function resolveStateAbbrev(govState: string | null, geofenceStateFips: string | null): string {
  if (govState) return govState.toUpperCase();
  if (geofenceStateFips) {
    const mapped = FIPS_TO_ABBREV[geofenceStateFips];
    if (mapped) return mapped;
  }
  return '';
}

/** mtfcc wins when present (it's the more precise geofence-derived signal); falls back to the government/gazetteer type hint. */
function deriveAreaType(mtfcc: string | null, govType: string | null): string {
  if (mtfcc === 'G4110') return 'City';
  if (mtfcc === 'G4020') return 'County';
  if (govType) {
    if (govType.toLowerCase() === 'state') return 'State';
    return govType;
  }
  return 'City';
}

/** D-05 label format: "Name, ST · Type" — State rows omit the redundant ", ST" (e.g. "Illinois · State"). */
function buildLabel(name: string, stateAbbrev: string, areaType: string): string {
  if (areaType === 'State') return `${name} · State`;
  return `${name}, ${stateAbbrev} · ${areaType}`;
}

function mapRow(row: LocationSearchRow): PlaceCandidate {
  const state = resolveStateAbbrev(row.gov_state, row.geofence_state_fips);
  const areaType = deriveAreaType(row.mtfcc, row.gov_type);
  return {
    geo_id: row.geo_id,
    mtfcc: row.mtfcc ?? '',
    label: buildLabel(row.name, state, areaType),
    state,
    area_type: areaType,
    has_local_data: Boolean(row.has_local_data),
  };
}

// ---------------------------------------------------------------------------
// searchPlaceNames
// ---------------------------------------------------------------------------

/**
 * Resolve a bare place-name query to a ranked, disambiguated candidate list.
 *
 * @param query - The search string (must be >= 2 chars, else throws
 *                LocationSearchQueryTooShortError — the /resolve route,
 *                Plan 05, maps this to a 422).
 * @param limit - Max results to return.
 */
export async function searchPlaceNames(query: string, limit: number): Promise<PlaceCandidate[]> {
  const trimmed = (query ?? '').trim();
  if (trimmed.length < 2) {
    throw new LocationSearchQueryTooShortError();
  }

  // Static 50-state name/abbrev exact match: a bare 2-letter query that is a
  // valid USPS abbreviation is expanded to its full state name before
  // matching, so "IL" surfaces the "Illinois" State-tier government row
  // (whose governments.name is the full state name, not the abbrev).
  const stateExpansion = STATE_ABBREV_TO_NAME[trimmed.toUpperCase()];
  const effectiveQuery = stateExpansion ?? trimmed;

  // Threshold calibration copied verbatim from campaignFinanceSearchService.ts,
  // re-derived from the effective (possibly state-expanded) query length —
  // this is the ONLY interpolated value in the SQL below, and it is entirely
  // code-derived (never user input), matching the existing project convention.
  const threshold = effectiveQuery.length <= 4 ? 0.15 : effectiveQuery.length <= 7 ? 0.25 : 0.30;

  // Basic input-validation clamp on limit (V5 Input Validation) — never trust
  // a caller-supplied limit past a sane ceiling.
  const safeLimit = Number.isFinite(limit) && limit > 0 ? Math.min(Math.floor(limit), 50) : 10;

  // NOTE: only $1 (effectiveQuery) and $2 (safeLimit) are parameterized user
  // input. threshold above is the only interpolated value, and it is
  // code-derived from string length, never from the query text itself —
  // identical discipline to campaignFinanceSearchService.ts.
  const sql = `
    WITH curated AS (
      -- One row per essentials.governments.id (DISTINCT ON (g.id)) even though
      -- governments has NO unique constraint on geo_id and a government can
      -- join to multiple geofence_boundaries rows for the same geo_id — this
      -- prevents a single logical place from fanning out into duplicate
      -- candidates (WARNING 5 / join fan-out guard).
      --
      -- 212-06 gap-closure fix (D-01/D-02 defect): 204 curated governments
      -- carry governments.geo_id = NULL, which used to emit an unresolvable
      -- geo_id:null / mtfcc:'' candidate that also duplicated its
      -- gazetteer/geofence twin (e.g. "City of Bloomington, Indiana, US" vs.
      -- the Gazetteer's "Bloomington city, IN"). place_district resolves the
      -- REAL place-level geo_id for those governments via
      -- chambers -> offices -> districts, picking the single G4110 (place)
      -- or G4020 (county) district linked to that government (LIMIT 1 —
      -- deterministic; every office on a government's own chamber shares the
      -- same district geo_id, e.g. Mayor/Clerk/At-Large all carry 1805860 for
      -- Bloomington). Only fires when governments.geo_id IS NULL — a
      -- government that already has its own geo_id never needs this fallback.
      SELECT DISTINCT ON (g.id)
        COALESCE(g.geo_id, place_district.district_geo_id) AS geo_id,
        COALESCE(gb.mtfcc, place_district.district_mtfcc) AS mtfcc,
        g.name,
        g.state AS gov_state,
        gb.state AS geofence_state_fips,
        g.type AS gov_type,
        EXISTS (
          SELECT 1 FROM essentials.chambers ch WHERE ch.government_id = g.id
        ) AS has_local_data,
        1 AS source_boost,
        extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(g.name))) AS sim,
        (lower(g.name) = lower($1)) AS exact_match
      FROM essentials.governments g
      LEFT JOIN LATERAL (
        SELECT d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc
        FROM essentials.chambers ch2
        JOIN essentials.offices o2 ON o2.chamber_id = ch2.id
        JOIN essentials.districts d ON d.id = o2.district_id
        WHERE ch2.government_id = g.id
          AND d.mtfcc IN ('G4110', 'G4020')
        ORDER BY d.geo_id
        LIMIT 1
      ) place_district ON g.geo_id IS NULL
      LEFT JOIN essentials.geofence_boundaries gb
        ON gb.geo_id = COALESCE(g.geo_id, place_district.district_geo_id)
      WHERE public.f_unaccent(lower(g.name)) operator(extensions.%>) public.f_unaccent(lower($1))
        AND extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(g.name))) >= ${threshold}
      ORDER BY g.id, gb.mtfcc NULLS LAST
    ),
    gazetteer AS (
      -- Nationwide Census Gazetteer fallback (Phase 212-01/212-03) — never
      -- curated, so has_local_data is always false and source_boost is 0
      -- (always ranks below a curated match for the same geo_id).
      SELECT
        gp.geo_id,
        'G4110'::text AS mtfcc,
        gp.name,
        gp.state AS gov_state,
        NULL::text AS geofence_state_fips,
        'City'::text AS gov_type,
        false AS has_local_data,
        0 AS source_boost,
        extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(gp.name))) AS sim,
        (lower(gp.name) = lower($1)) AS exact_match
      FROM essentials.gazetteer_places gp
      WHERE public.f_unaccent(lower(gp.name)) operator(extensions.%>) public.f_unaccent(lower($1))
        AND extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(gp.name))) >= ${threshold}
      UNION ALL
      SELECT
        gc.geo_id,
        'G4020'::text AS mtfcc,
        gc.name,
        gc.state AS gov_state,
        NULL::text AS geofence_state_fips,
        'County'::text AS gov_type,
        false AS has_local_data,
        0 AS source_boost,
        extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(gc.name))) AS sim,
        (lower(gc.name) = lower($1)) AS exact_match
      FROM essentials.gazetteer_counties gc
      WHERE public.f_unaccent(lower(gc.name)) operator(extensions.%>) public.f_unaccent(lower($1))
        AND extensions.word_similarity(public.f_unaccent(lower($1)), public.f_unaccent(lower(gc.name))) >= ${threshold}
    ),
    combined AS (
      SELECT * FROM curated
      UNION ALL
      SELECT * FROM gazetteer
    ),
    deduped AS (
      -- A curated place and its Gazetteer-only counterpart can share a
      -- geo_id (e.g. a fully-seeded city also present in the Gazetteer) —
      -- prefer the curated (higher source_boost) row so one logical place
      -- never emits two candidates.
      SELECT DISTINCT ON (geo_id) *
      FROM combined
      ORDER BY geo_id, source_boost DESC
    )
    SELECT geo_id, mtfcc, name, gov_state, geofence_state_fips, gov_type, has_local_data, sim, exact_match
    FROM deduped
    ORDER BY source_boost DESC, sim DESC, exact_match DESC, name ASC
    LIMIT $2
  `;

  const { rows } = await pool.query<LocationSearchRow>(sql, [effectiveQuery, safeLimit]);
  return rows.map(mapRow);
}

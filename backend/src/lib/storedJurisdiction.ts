/**
 * storedJurisdiction — the one place that answers "what districts do we hold for this account".
 *
 * Two sources, because two tiers store them in two places (CA_0368, design
 * docs/superpowers/specs/2026-11-07-basic-account-address-districts-only-design.md):
 *
 *   connect.connected_profiles     Connected accounts. Districts plus an encrypted point, so
 *                                  the weekly re-check and the 2026 congressional fallback can
 *                                  re-resolve them.
 *   inform.account_jurisdictions   Basic accounts. Districts ONLY — no point, no address.
 *
 * 🔴 A basic account's districts must never be written to connected_profiles: a row there is
 * what makes an account Connected (middleware/tierGuards.ts). That is why there are two tables
 * and why every reader goes through here instead of choosing one.
 *
 * The Connected row wins whenever it holds any location at all. A basic row is used when it
 * does not — which also covers an account promoted to Connected that has not yet entered its
 * address on the Connected path: its basic districts keep working until it does, and
 * POST /api/connect/set-location then deletes the basic row.
 */
import { pool } from './db.js';

export interface StoredJurisdiction {
  source: 'connected' | 'basic';
  /** Connected: the profile's own flag. Basic: always true — the row exists only because they added an address. */
  location_consent: boolean;
  /** An encrypted point is on file. Always false for a basic row, which never has one. */
  has_coords: boolean;
  congressional_geo_id: string | null;
  congressional_district_name: string | null;
  state_senate_geo_id: string | null;
  state_senate_district_name: string | null;
  state_house_geo_id: string | null;
  state_house_district_name: string | null;
  county_geo_id: string | null;
  county_name: string | null;
  school_district_geo_id: string | null;
  school_district_name: string | null;
  city_council_geo_id: string | null;
  city_council_district_name: string | null;
  municipality_geo_id: string | null;
  jurisdiction_state: string | null;
  jurisdiction_city: string | null;
  city_geo_id: string | null;
  state_geo_id: string | null;
  nation_geo_id: string | null;
}

const COLUMNS = `congressional_geo_id, congressional_district_name,
       state_senate_geo_id, state_senate_district_name,
       state_house_geo_id, state_house_district_name,
       county_geo_id, county_name,
       school_district_geo_id, school_district_name,
       city_council_geo_id, city_council_district_name,
       municipality_geo_id,
       jurisdiction_state, jurisdiction_city,
       city_geo_id, state_geo_id, nation_geo_id`;

/**
 * A Connected row "holds a location" when the flag is set, a point is on file, or any district
 * was stored. The last two keep the old readers' behaviour: they read connected_profiles with
 * no consent filter, so a Connected row with districts must never fall through to a basic row.
 */
export const STORED_JURISDICTION_SQL = `
  SELECT * FROM (
    SELECT 1 AS pri, 'connected' AS source, location_consent = true AS location_consent,
           (encrypted_lat IS NOT NULL) AS has_coords, ${COLUMNS}
      FROM connect.connected_profiles
     WHERE user_id = $1
       AND (location_consent = true
            OR encrypted_lat IS NOT NULL
            OR congressional_geo_id IS NOT NULL
            OR state_senate_geo_id IS NOT NULL
            OR county_geo_id IS NOT NULL)
    UNION ALL
    SELECT 2, 'basic', true, false, ${COLUMNS}
      FROM inform.account_jurisdictions
     WHERE user_id = $1
  ) s
  ORDER BY pri
  LIMIT 1`;

/** The stored districts for this account, or null when neither source holds any. */
export async function readStoredJurisdiction(userId: string): Promise<StoredJurisdiction | null> {
  const { rows } = await pool.query<StoredJurisdiction & { pri: number }>(STORED_JURISDICTION_SQL, [userId]);
  const row = rows[0];
  if (!row) return null;
  const { pri: _pri, ...rest } = row;
  return rest;
}

/**
 * The public `jurisdiction` object GET /api/account/me and GET /api/account/me/jurisdiction
 * return. Built from an explicit whitelist — never spread a row.
 */
export function toJurisdictionResponse(j: StoredJurisdiction | null | undefined): Record<string, string | null> {
  return {
    congressional_district: j?.congressional_geo_id ?? null,
    congressional_district_name: j?.congressional_district_name ?? null,
    state_senate_district: j?.state_senate_geo_id ?? null,
    state_senate_district_name: j?.state_senate_district_name ?? null,
    state_house_district: j?.state_house_geo_id ?? null,
    state_house_district_name: j?.state_house_district_name ?? null,
    county: j?.county_geo_id ?? null,
    county_name: j?.county_name ?? null,
    school_district: j?.school_district_geo_id ?? null,
    school_district_name: j?.school_district_name ?? null,
    state: j?.jurisdiction_state ?? null,
    city: j?.jurisdiction_city ?? null,
    city_council_district: j?.city_council_geo_id ?? null,
    city_council_district_name: j?.city_council_district_name ?? null,
    // 🔴 Census FIPS geoids — deliberately NOT named `state`/`city` (already taken by the
    // USPS code and place name above). Civic Spaces keys a slice on the geoid.
    state_geoid: j?.state_geo_id ?? null,
    city_geoid: j?.city_geo_id ?? null,
    nation_geoid: j?.nation_geo_id ?? null,
  };
}

/**
 * basicJurisdictionService — store a BASIC account's districts, and nothing else (CA_0368).
 *
 * Design: docs/superpowers/specs/2026-11-07-basic-account-address-districts-only-design.md.
 *
 * The caller hands over a geocoded point. This resolves the districts at that point, writes
 * them to inform.account_jurisdictions, refreshes the TIGER district cache, and returns.
 * 🔴 The point and the address are never written anywhere and never logged. They live only in
 * this call's arguments.
 */
import { adminRpc } from './supabase.js';
import { pool } from './db.js';
import { resolvedDistrictCount } from './jurisdictionPayload.js';
import type { GeocodeResult } from './geocodingService.js';

export interface BasicLocationResult {
  location_consent: true;
  first_location: boolean;
  jurisdiction: Record<string, string | null>;
}

/**
 * Resolve and store. Throws on a resolver or write failure; the route answers 500.
 *
 * In the 10 states with a 2026 congressional map, the 2026 district is stored, not the old
 * one. A Connected account keeps the old id and is corrected live at read time from its
 * stored point (resolveCongressional2026 in routes/essentials.ts); a basic row has no point,
 * so it can never be corrected later, and the 2026 map is the one still true after the
 * January 2027 promotion.
 */
export async function saveBasicJurisdiction(
  userId: string,
  coords: Pick<GeocodeResult, 'lat' | 'lng' | 'state' | 'city'>
): Promise<BasicLocationResult> {
  const { data, error } = await adminRpc(
    'resolve_jurisdiction_at_point',
    { p_lat: coords.lat, p_lng: coords.lng },
    'connect'
  );
  if (error) throw new Error(`resolve_jurisdiction_at_point failed: ${error.message}`);
  const j = (data ?? {}) as Record<string, string | null>;

  const { data: cd2026 } = await adminRpc(
    'resolve_congressional_2026_at_point',
    { p_lat: coords.lat, p_lng: coords.lng },
    'connect'
  );
  const congressional = typeof cd2026 === 'string' && cd2026 ? cd2026 : (j.congressional ?? null);
  // The 2026 function returns an id, not a name. When it moved the district, read the new
  // district's own label; the old one beside a new id would name the wrong district.
  let congressionalName = j.congressional_name ?? null;
  if (congressional !== (j.congressional ?? null)) {
    const { rows: labelRows } = await pool.query<{ label: string | null }>(
      `SELECT label FROM essentials.districts
        WHERE geo_id = $1 AND district_type = 'NATIONAL_LOWER'
        ORDER BY label LIMIT 1`,
      [congressional]
    );
    congressionalName = labelRows[0]?.label ?? null;
  }

  if (resolvedDistrictCount(j) === 0) {
    // Written anyway, as on the Connected path: the address changed, so the old districts are
    // wrong. Say so, because an unresolved point raises no error (see jurisdictionPayload.ts).
    console.warn(
      `[basicJurisdiction] UNRESOLVED — a geocoded address for user ${userId} resolved no district ` +
        `(${coords.city}, ${coords.state}). Writing the empty jurisdiction.`
    );
  }

  const { rows } = await pool.query<{ inserted: boolean }>(
    `INSERT INTO inform.account_jurisdictions (
       user_id,
       congressional_geo_id, congressional_district_name,
       state_senate_geo_id, state_senate_district_name,
       state_house_geo_id, state_house_district_name,
       county_geo_id, county_name,
       school_district_geo_id, school_district_name,
       city_council_geo_id, city_council_district_name,
       municipality_geo_id,
       jurisdiction_state, jurisdiction_city,
       city_geo_id, state_geo_id, nation_geo_id,
       resolved_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, now())
     ON CONFLICT (user_id) DO UPDATE SET
       congressional_geo_id = EXCLUDED.congressional_geo_id,
       congressional_district_name = EXCLUDED.congressional_district_name,
       state_senate_geo_id = EXCLUDED.state_senate_geo_id,
       state_senate_district_name = EXCLUDED.state_senate_district_name,
       state_house_geo_id = EXCLUDED.state_house_geo_id,
       state_house_district_name = EXCLUDED.state_house_district_name,
       county_geo_id = EXCLUDED.county_geo_id,
       county_name = EXCLUDED.county_name,
       school_district_geo_id = EXCLUDED.school_district_geo_id,
       school_district_name = EXCLUDED.school_district_name,
       city_council_geo_id = EXCLUDED.city_council_geo_id,
       city_council_district_name = EXCLUDED.city_council_district_name,
       municipality_geo_id = EXCLUDED.municipality_geo_id,
       jurisdiction_state = EXCLUDED.jurisdiction_state,
       jurisdiction_city = EXCLUDED.jurisdiction_city,
       city_geo_id = EXCLUDED.city_geo_id,
       state_geo_id = EXCLUDED.state_geo_id,
       nation_geo_id = EXCLUDED.nation_geo_id,
       resolved_at = now()
     RETURNING (xmax = 0) AS inserted`,
    [
      userId,
      congressional,
      congressionalName,
      j.state_senate ?? null,
      j.state_senate_name ?? null,
      j.state_house ?? null,
      j.state_house_name ?? null,
      j.county ?? null,
      j.county_name ?? null,
      j.school_district ?? null,
      j.school_district_name ?? null,
      j.city_council ?? null,
      j.city_council_name ?? null,
      j.municipality ?? null,
      coords.state,
      coords.city,
      j.city ?? null,
      j.state ?? null,
      j.nation ?? null,
    ]
  );

  // TIGER district cache (fail-open): districts out, the point is not stored. essentials is
  // not in PostgREST's exposed schemas — pool.query, not adminRpc.
  try {
    await pool.query(`SELECT essentials.cache_user_districts($1, $2, $3)`, [userId, coords.lat, coords.lng]);
  } catch {
    console.error('[basicJurisdiction] district cache failed (non-fatal)');
  }

  return {
    location_consent: true,
    first_location: rows[0]?.inserted === true,
    jurisdiction: {
      congressional_district: congressional,
      congressional_district_name: congressionalName,
      state_senate_district: j.state_senate ?? null,
      state_senate_district_name: j.state_senate_name ?? null,
      state_house_district: j.state_house ?? null,
      state_house_district_name: j.state_house_name ?? null,
      county: j.county ?? null,
      county_name: j.county_name ?? null,
      school_district: j.school_district ?? null,
      school_district_name: j.school_district_name ?? null,
      state: coords.state,
      city: coords.city,
      city_council_district: j.city_council ?? null,
      city_council_district_name: j.city_council_name ?? null,
    },
  };
}

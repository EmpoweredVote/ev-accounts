/**
 * essentialsService — public politician data lookups for CompassV2 frontend.
 *
 * WHY THIS FILE EXISTS:
 * Route files must not reference the service-role client directly (enforced
 * by architecture.test.ts). This service wraps all DB access for the
 * GET /api/essentials/politicians endpoint using supabaseAnon only.
 *
 * essentials.politicians rows are public reference data — no user-owned data,
 * no sensitive fields, no RLS bypass needed. supabaseAnon (anon key, RLS
 * enforced) is the correct client for this table.
 *
 * After Phase 35 deduplication, essentials.politicians is the unified source
 * of truth for politician identity. inform-specific columns (office_title,
 * district_type, district_label, etc.) are not present in this table.
 *
 * All response objects are built from EXPLICIT field whitelists. DB rows are
 * NEVER spread into responses.
 *
 * Phase 38 additions:
 *   - getRepresentativesByAddress — Census Geocoder -> PostGIS geofence -> politicians
 *   - getPoliticiansFlatList — Go-parity flat list for /api/essentials/politicians
 *   - getPoliticianById — full profile with nested contacts, images, degrees, experiences
 *   - getGovernmentById — government with nested chambers list
 *   - getChamberById — chamber with parent government
 *   - getDistrictById — district with politicians + chamber + government context
 *
 * DB schema notes (Phase 38 investigation):
 *   - governments: id, name, type, state, city — NO is_elected or election_frequency
 *   - chambers: election_frequency (text), NOT governments
 *   - is_elected derived: NOT COALESCE(o.is_appointed_position, false)
 *   - politician_contacts: politician_id FK, email, phone, fax, contact_type, website_url, source
 *   - politician_images: politician_id FK, url, type, photo_license
 *   - degrees: politician_id FK, degree, major, school, grad_year
 *   - experiences: politician_id FK, title, organization, type, start, end
 */

import { pool } from './db.js';
import { geocodeAddress, GeocodingError } from './geocodingService.js';

// Re-export GeocodingError so callers can import from one place if needed
export { GeocodingError };

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/**
 * Go-parity flat politician record.
 *
 * Field naming follows the Go server response shape exactly so that frontends
 * built against the Go server can migrate to Express without response changes.
 * Null string fields are coerced to '' (empty string) to match Go convention.
 */
export interface PoliticianFlatRecord {
  id: string;
  external_id: number | null;
  first_name: string;
  middle_initial: string;
  last_name: string;
  preferred_name: string;
  name_suffix: string;
  full_name: string;
  party: string;
  photo_origin_url: string;
  web_form_url: string;
  urls: string[] | null;
  email_addresses: string[] | null;
  office_title: string;
  representing_state: string;
  representing_city: string;
  district_type: string;
  district_label: string;
  district_id: string;
  geo_id: string;
  mtfcc: string;
  chamber_name: string;
  chamber_name_formal: string;
  government_name: string;
  government_body_name: string;
  government_body_url: string;
  is_elected: boolean;
  election_frequency: string;
  committees: null;
  bio_text: string | null;
  slug: string | null;
  is_incumbent: boolean;
  images: Array<{ id: string; url: string; type: string; photo_license: string }>;
}

export interface AddressSearchResult {
  politicians: PoliticianFlatRecord[];
  jurisdiction: {
    district_type: string;
    district_id: string;
    district_label: string;
    mtfcc: string;
  } | null;
  matchedAddress: string;
}

export interface PoliticianRecord {
  id: string;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  preferred_name: string | null;
  photo_origin_url: string | null;
  is_active: boolean;
  is_vacant: boolean | null;
  is_incumbent: boolean;
  party: string | null;
  party_short_name: string | null;
  slug: string | null;
  bio_text: string | null;
}

export interface PoliticianGroup {
  party: string | null;
  incumbent: PoliticianRecord | null;
  candidates: PoliticianRecord[];
}

// ---------------------------------------------------------------------------
// getPoliticiansGrouped
// ---------------------------------------------------------------------------

/**
 * Fetch active politicians from essentials.politicians and group by party.
 *
 * After Phase 35 deduplication, essentials.politicians is the unified source
 * of truth. inform-specific columns (office_title, district_type, is_candidate,
 * etc.) are not present; essentials uses is_incumbent to distinguish incumbents
 * from non-incumbents.
 *
 * Filters applied:
 *   - is_active = true  (exclude deactivated/removed records)
 *
 * When includeCandidates is false:
 *   - Returns only rows where is_incumbent = true
 *   - Each group: { party, incumbent: politician, candidates: [] }
 *
 * When includeCandidates is true:
 *   - Returns all active politicians (incumbents + non-incumbents)
 *   - Each group: { party, incumbent: first incumbent in party, candidates: non-incumbents }
 *
 * Ordering: non-null party groups first (alphabetical), null last.
 *
 * On DB error: throws (NOT a silent empty array).
 */
export async function getPoliticiansGrouped(
  includeCandidates: boolean
): Promise<PoliticianGroup[]> {
  // Uses pool.query() — essentials schema is not exposed via PostgREST.
  // Build parameterized query with optional incumbent filter.
  const baseSelect = `
    SELECT id, full_name, first_name, last_name, preferred_name,
           photo_origin_url, is_active, is_vacant, is_incumbent,
           party, party_short_name, slug, bio_text
    FROM essentials.politicians
    WHERE is_active = true`;

  const queryText = includeCandidates
    ? `${baseSelect} ORDER BY party ASC NULLS LAST, last_name ASC, first_name ASC`
    : `${baseSelect} AND is_incumbent = true ORDER BY party ASC NULLS LAST, last_name ASC, first_name ASC`;

  const { rows } = await pool.query<{
    id: string;
    full_name: string | null;
    first_name: string | null;
    last_name: string | null;
    preferred_name: string | null;
    photo_origin_url: string | null;
    is_active: boolean;
    is_vacant: boolean | null;
    is_incumbent: boolean;
    party: string | null;
    party_short_name: string | null;
    slug: string | null;
    bio_text: string | null;
  }>(queryText);

  // Group by party
  const groupMap = new Map<string | null, PoliticianGroup>();

  for (const row of rows) {
    const key = row.party ?? null;
    const record: PoliticianRecord = {
      id: row.id,
      full_name: row.full_name,
      first_name: row.first_name,
      last_name: row.last_name,
      preferred_name: row.preferred_name,
      photo_origin_url: row.photo_origin_url,
      is_active: row.is_active,
      is_vacant: row.is_vacant,
      is_incumbent: row.is_incumbent,
      party: row.party,
      party_short_name: row.party_short_name,
      slug: row.slug,
      bio_text: row.bio_text,
    };

    if (!groupMap.has(key)) {
      groupMap.set(key, {
        party: key,
        incumbent: null,
        candidates: [],
      });
    }

    const group = groupMap.get(key)!;

    if (record.is_incumbent) {
      // First incumbent seen for this party becomes the group incumbent
      if (group.incumbent === null) {
        group.incumbent = record;
      } else {
        group.candidates.push(record);
      }
    } else {
      group.candidates.push(record);
    }
  }

  // Sort groups: non-null party first (alphabetical), null last
  const groups = Array.from(groupMap.values());
  groups.sort((a, b) => {
    if (a.party === null && b.party === null) return 0;
    if (a.party === null) return 1;
    if (b.party === null) return -1;
    return a.party.localeCompare(b.party);
  });

  return groups;
}

// ---------------------------------------------------------------------------
// batchFetchImages — shared by flat list and search results
// ---------------------------------------------------------------------------

/**
 * Batch-fetch politician images and attach to records.
 * Matches Go server behavior of including images[] on every politician in list results.
 */
async function batchFetchImages(
  politicians: Array<{ id: string; images?: Array<{ id: string; url: string; type: string; photo_license: string }> }>
): Promise<void> {
  if (politicians.length === 0) return;

  const ids = politicians.map((p) => p.id);
  const { rows } = await pool.query(
    `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license
     FROM essentials.politician_images
     WHERE politician_id = ANY($1)`,
    [ids]
  );

  // Group images by politician_id
  const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string }>>();
  for (const row of rows) {
    const pid = row.politician_id as string;
    if (!imageMap.has(pid)) imageMap.set(pid, []);
    imageMap.get(pid)!.push({
      id: row.id as string,
      url: row.url ?? '',
      type: row.type ?? '',
      photo_license: row.photo_license ?? '',
    });
  }

  // Attach to each politician
  for (const p of politicians) {
    p.images = imageMap.get(p.id) ?? [];
  }
}

// ---------------------------------------------------------------------------
// getPoliticiansFlatList
// ---------------------------------------------------------------------------

/**
 * Fetch all active politicians and return as a Go-parity flat list.
 *
 * Joins politicians → offices → districts → chambers → governments.
 * Null string fields are coerced to '' (empty string) to match Go convention.
 *
 * includeCandidates=false: returns only incumbents (is_incumbent = true)
 * includeCandidates=true:  returns all active politicians
 */
export async function getPoliticiansFlatList(
  includeCandidates?: boolean,
  options?: { q?: string; limit?: number; offset?: number; state?: string }
): Promise<PoliticianFlatRecord[]> {
  const incumbentFilter = includeCandidates ? '' : 'AND p.is_incumbent = true';

  const params: unknown[] = [];
  let searchFilter = '';
  let stateFilter = '';
  let limitClause = '';
  let offsetClause = '';

  if (options?.q) {
    params.push(`%${options.q}%`);
    const idx = params.length;
    searchFilter = `AND (p.full_name ILIKE $${idx} OR p.first_name ILIKE $${idx} OR p.last_name ILIKE $${idx})`;
  }

  if (options?.state) {
    params.push(options.state);
    stateFilter = `AND o.representing_state = $${params.length}`;
  }

  if (options?.limit) {
    params.push(options.limit);
    limitClause = `LIMIT $${params.length}`;
  }

  if (options?.offset) {
    params.push(options.offset);
    offsetClause = `OFFSET $${params.length}`;
  }

  const queryText = `
    SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE p.is_active = true
    ${incumbentFilter}
    ${searchFilter}
    ${stateFilter}
    ORDER BY p.full_name
    ${limitClause}
    ${offsetClause}
  `;

  const { rows } = await pool.query(queryText, params.length > 0 ? params : undefined);

  const politicians: PoliticianFlatRecord[] = rows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name ?? '',
    middle_initial: row.middle_initial ?? '',
    last_name: row.last_name ?? '',
    preferred_name: row.preferred_name ?? '',
    name_suffix: row.name_suffix ?? '',
    full_name: row.full_name ?? '',
    party: row.party ?? '',
    photo_origin_url: row.photo_origin_url ?? '',
    web_form_url: row.web_form_url ?? '',
    urls: row.urls ?? null,
    email_addresses: row.email_addresses ?? null,
    office_title: row.office_title ?? '',
    representing_state: row.representing_state ?? '',
    representing_city: row.representing_city ?? '',
    district_type: row.district_type ?? '',
    district_label: row.district_label ?? '',
    district_id: row.district_id ?? '',
    geo_id: row.geo_id ?? '',
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    government_name: row.government_name ?? '',
    government_body_name: row.government_body_name ?? '',
    government_body_url: row.government_body_url ?? '',
    is_elected: !row.is_appointed_position,
    election_frequency: row.election_frequency ?? '',
    committees: null,
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    is_incumbent: row.is_incumbent ?? false,
    images: [],
  }));

  await batchFetchImages(politicians);
  return politicians;
}

// ---------------------------------------------------------------------------
// getRepresentativesByAddress
// ---------------------------------------------------------------------------

/**
 * Geocode an address via Census Geocoder, then find all active politicians
 * whose geofence boundary covers that coordinate via PostGIS ST_Covers.
 *
 * IMPORTANT coordinate order:
 *   Census x = longitude, Census y = latitude
 *   ST_MakePoint($1, $2) = (longitude, latitude) = (Census x, Census y)
 *   $1 is ALWAYS longitude, $2 is ALWAYS latitude.
 *
 * GeocodingError is NOT caught here — callers (route handlers) catch it
 * and return the appropriate HTTP status code.
 *
 * Returns { politicians: [], jurisdiction: null } when no boundaries match.
 */
export async function getRepresentativesByAddress(
  address: string,
  { includeChallengers = false }: { includeChallengers?: boolean } = {}
): Promise<AddressSearchResult> {
  // Geocode via Census Geocoder. GeocodingError propagates to caller.
  const { lat, lng, matchedAddress, state } = await geocodeAddress(address);

  // CRITICAL: ST_MakePoint takes (longitude, latitude) = (Census x, Census y)
  // $1 = lng (Census coordinates.x), $2 = lat (Census coordinates.y)
  const districtQueryText = `
    SELECT DISTINCT ON (COALESCE(p.id, o.id))
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id,
           d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.mtfcc = gb.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.politicians p ON o.politician_id = p.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE public.ST_Covers(
      gb.geometry,
      public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
    )
    AND (p.is_active = true OR o.is_vacant = true)
    ${includeChallengers ? '' : 'AND COALESCE(p.is_incumbent, true) = true'}
    ORDER BY COALESCE(p.id, o.id)
  `;

  // Statewide politicians — includes President/VP, Senators, Governor, Supreme Court
  const statewideQueryText = `
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id,
           d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.politicians p ON o.politician_id = p.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', 'NATIONAL_JUDICIAL')
    AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
    AND p.is_active = true
    ORDER BY p.id
  `;

  // $1 = longitude (Census coordinates.x), $2 = latitude (Census coordinates.y)
  const [districtResult, statewideResult] = await Promise.all([
    pool.query(districtQueryText, [lng, lat]),
    state ? pool.query(statewideQueryText, [state]) : Promise.resolve({ rows: [] as unknown[] }),
  ]);
  const rows = [...districtResult.rows, ...(statewideResult.rows as typeof districtResult.rows)];

  if (rows.length === 0) {
    return { politicians: [], jurisdiction: null, matchedAddress };
  }

  const politicians: PoliticianFlatRecord[] = rows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name ?? '',
    middle_initial: row.middle_initial ?? '',
    last_name: row.last_name ?? '',
    preferred_name: row.preferred_name ?? '',
    name_suffix: row.name_suffix ?? '',
    full_name: row.full_name ?? '',
    party: row.party ?? '',
    photo_origin_url: row.photo_origin_url ?? '',
    web_form_url: row.web_form_url ?? '',
    urls: row.urls ?? null,
    email_addresses: row.email_addresses ?? null,
    office_title: row.office_title ?? '',
    representing_state: row.representing_state ?? '',
    representing_city: row.representing_city ?? '',
    district_type: row.district_type ?? '',
    district_label: row.district_label ?? '',
    district_id: row.district_id ?? '',
    geo_id: row.geo_id ?? '',
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    government_name: row.government_name ?? '',
    government_body_name: row.government_body_name ?? '',
    government_body_url: row.government_body_url ?? '',
    is_elected: !row.is_appointed_position,
    election_frequency: row.election_frequency ?? '',
    committees: null,
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    is_incumbent: row.is_incumbent ?? false,
    images: [],
  }));

  await batchFetchImages(politicians);

  const firstRow = rows[0];
  const jurisdiction = {
    district_type: firstRow.district_type ?? '',
    district_id: firstRow.district_id ?? '',
    district_label: firstRow.district_label ?? '',
    mtfcc: firstRow.mtfcc ?? '',
  };

  return { politicians, jurisdiction, matchedAddress };
}

// ---------------------------------------------------------------------------
// PoliticianDetail types
// ---------------------------------------------------------------------------

export interface PoliticianContact {
  id: string;
  source: string;
  email: string;
  phone: string;
  fax: string;
  contact_type: string;
  website_url: string;
}

export interface PoliticianImage {
  id: string;
  url: string;
  type: string;
  photo_license: string;
}

export interface PoliticianDegree {
  id: string;
  degree: string;
  major: string;
  school: string;
  grad_year: number | null;
}

export interface PoliticianExperience {
  id: string;
  title: string;
  organization: string;
  type: string;
  start: string;
  end: string;
}

/**
 * Full politician profile with all nested data from essentials schema.
 *
 * Extends PoliticianFlatRecord with nested arrays for contacts, images,
 * degrees, and experiences. Nested arrays are [] (not null) when no data exists.
 *
 * office_id and government_id included for deep linking to related entities.
 */
export interface PoliticianDetail {
  // Identity
  id: string;
  external_id: number | null;
  first_name: string;
  middle_initial: string;
  last_name: string;
  preferred_name: string;
  name_suffix: string;
  full_name: string;
  party: string;
  party_short_name: string;
  // Contact / web
  photo_origin_url: string;
  web_form_url: string;
  urls: string[] | null;
  email_addresses: string[] | null;
  // Biography
  bio_text: string | null;
  slug: string | null;
  total_years_in_office: number | null;
  // Status flags
  is_incumbent: boolean;
  is_appointed: boolean;
  is_vacant: boolean;
  is_active: boolean;
  is_elected: boolean;
  // Office details
  office_id: string | null;
  office_title: string;
  representing_state: string;
  representing_city: string;
  office_seats: number | null;
  is_appointed_position: boolean;
  // District details
  district_type: string;
  district_label: string;
  district_id: string;
  geo_id: string;
  district_state: string;
  mtfcc: string;
  // Chamber details
  chamber_name: string;
  chamber_name_formal: string;
  election_frequency: string;
  // Government details
  government_id: string | null;
  government_name: string;
  // Nested arrays
  contacts: PoliticianContact[];
  images: PoliticianImage[];
  degrees: PoliticianDegree[];
  experiences: PoliticianExperience[];
  addresses: Array<{
    id: string;
    politician_id: string;
    address_1: string;
    address_2: string;
    address_3: string;
    state: string;
    postal_code: string;
    phone_1: string;
    phone_2: string;
  }>;
  identifiers: Array<{
    id: string;
    politician_id: string;
    identifier_type: string;
    identifier_value: string;
  }>;
  notes: string[];
}

// ---------------------------------------------------------------------------
// politicianExists
// ---------------------------------------------------------------------------

/**
 * Lightweight existence check for a politician.
 *
 * Used by legislative subroutes to return 404 before issuing heavier queries.
 * Returns true if an active politician with the given ID exists.
 *
 * Uses pool.query() — essentials schema is not PostgREST-exposed.
 */
export async function politicianExists(id: string): Promise<boolean> {
  const { rows } = await pool.query(
    'SELECT 1 FROM essentials.politicians WHERE id = $1 AND is_active = true',
    [id]
  );
  return rows.length > 0;
}

// ---------------------------------------------------------------------------
// getPoliticianById
// ---------------------------------------------------------------------------

/**
 * Fetch a single politician's full profile with all nested tables.
 *
 * Base query: single politician joined to offices → districts → chambers → governments.
 * Nested data: parallel queries for contacts, images, degrees, experiences.
 *
 * Returns null when no politician with the given ID exists.
 * All null string fields coerced to '' for Go convention.
 * Nested arrays are [] when no records exist (never null).
 *
 * Uses pool.query() only — essentials schema is NOT in PostgREST exposed list.
 */
export async function getPoliticianById(id: string): Promise<PoliticianDetail | null> {
  // Base query: politician + office + district + chamber + government
  const baseQuery = `
    SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party, p.party_short_name,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug,
           p.total_years_in_office, p.is_incumbent, p.is_appointed, p.is_vacant,
           p.is_active, p.office_id, p.notes,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.seats AS office_seats,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id,
           d.mtfcc, d.state AS district_state,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name, g.id AS government_id
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.politician_id = p.id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE p.id = $1
  `;

  // Run base query + all nested queries in parallel
  const [baseResult, contactsResult, imagesResult, degreesResult, experiencesResult, addressesResult, identifiersResult] =
    await Promise.all([
      pool.query(baseQuery, [id]),
      pool.query(
        `SELECT id, source, email, phone, fax, contact_type, website_url
         FROM essentials.politician_contacts
         WHERE politician_id = $1`,
        [id]
      ),
      pool.query(
        `SELECT id, url, type, photo_license
         FROM essentials.politician_images
         WHERE politician_id = $1`,
        [id]
      ),
      pool.query(
        `SELECT id, degree, major, school, grad_year
         FROM essentials.degrees
         WHERE politician_id = $1`,
        [id]
      ),
      pool.query(
        `SELECT id, title, organization, type, start, "end"
         FROM essentials.experiences
         WHERE politician_id = $1`,
        [id]
      ),
      pool.query(
        `SELECT id, politician_id, address1 AS address_1, address2 AS address_2, address3 AS address_3,
                state, postal_code, phone1 AS phone_1, phone2 AS phone_2
         FROM essentials.addresses
         WHERE politician_id = $1`,
        [id]
      ),
      pool.query(
        `SELECT id, politician_id, identifier_type, identifier_value
         FROM essentials.identifiers
         WHERE politician_id = $1`,
        [id]
      ),
    ]);

  // Politician not found
  if (baseResult.rows.length === 0) {
    return null;
  }

  const row = baseResult.rows[0];

  const contacts: PoliticianContact[] = contactsResult.rows.map((r) => ({
    id: r.id as string,
    source: r.source ?? '',
    email: r.email ?? '',
    phone: r.phone ?? '',
    fax: r.fax ?? '',
    contact_type: r.contact_type ?? '',
    website_url: r.website_url ?? '',
  }));

  const images: PoliticianImage[] = imagesResult.rows.map((r) => ({
    id: r.id as string,
    url: r.url ?? '',
    type: r.type ?? '',
    photo_license: r.photo_license ?? '',
  }));

  const degrees: PoliticianDegree[] = degreesResult.rows.map((r) => ({
    id: r.id as string,
    degree: r.degree ?? '',
    major: r.major ?? '',
    school: r.school ?? '',
    grad_year: r.grad_year != null ? Number(r.grad_year) : null,
  }));

  const experiences: PoliticianExperience[] = experiencesResult.rows.map((r) => ({
    id: r.id as string,
    title: r.title ?? '',
    organization: r.organization ?? '',
    type: r.type ?? '',
    start: r.start ?? '',
    end: r.end ?? '',
  }));

  return {
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name ?? '',
    middle_initial: row.middle_initial ?? '',
    last_name: row.last_name ?? '',
    preferred_name: row.preferred_name ?? '',
    name_suffix: row.name_suffix ?? '',
    full_name: row.full_name ?? '',
    party: row.party ?? '',
    party_short_name: row.party_short_name ?? '',
    photo_origin_url: row.photo_origin_url ?? '',
    web_form_url: row.web_form_url ?? '',
    urls: row.urls ?? null,
    email_addresses: row.email_addresses ?? null,
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    total_years_in_office: row.total_years_in_office != null ? Number(row.total_years_in_office) : null,
    is_incumbent: row.is_incumbent ?? false,
    is_appointed: row.is_appointed ?? false,
    is_vacant: row.is_vacant ?? false,
    is_active: row.is_active ?? false,
    // is_elected derived: NOT appointed position. governments table has no is_elected column.
    is_elected: !row.is_appointed_position,
    office_id: row.office_id ?? null,
    office_title: row.office_title ?? '',
    representing_state: row.representing_state ?? '',
    representing_city: row.representing_city ?? '',
    office_seats: row.office_seats != null ? Number(row.office_seats) : null,
    is_appointed_position: row.is_appointed_position ?? false,
    district_type: row.district_type ?? '',
    district_label: row.district_label ?? '',
    district_id: row.district_id ?? '',
    geo_id: row.geo_id ?? '',
    district_state: row.district_state ?? '',
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    // election_frequency is on chambers, not governments.
    election_frequency: row.election_frequency ?? '',
    government_id: row.government_id ?? null,
    government_name: row.government_name ?? '',
    contacts,
    images,
    degrees,
    experiences,
    addresses: addressesResult.rows.map((r) => ({
      id: r.id as string,
      politician_id: r.politician_id as string,
      address_1: r.address_1 ?? '',
      address_2: r.address_2 ?? '',
      address_3: r.address_3 ?? '',
      state: r.state ?? '',
      postal_code: r.postal_code ?? '',
      phone_1: r.phone_1 ?? '',
      phone_2: r.phone_2 ?? '',
    })),
    identifiers: identifiersResult.rows.map((r) => ({
      id: r.id as string,
      politician_id: r.politician_id as string,
      identifier_type: r.identifier_type ?? '',
      identifier_value: r.identifier_value ?? '',
    })),
    notes: row.notes ?? [],
  };
}

// ---------------------------------------------------------------------------
// GovernmentDetail types + getGovernmentById
// ---------------------------------------------------------------------------

export interface ChamberSummary {
  id: string;
  name: string;
  name_formal: string;
  type: string;
  election_frequency: string;
}

/**
 * Government entity with nested list of its chambers.
 *
 * governments table: id, name, type, state, city (no is_elected, no election_frequency).
 * election_frequency lives on chambers.
 */
export interface GovernmentDetail {
  id: string;
  name: string;
  type: string;
  state: string;
  city: string;
  chambers: ChamberSummary[];
}

/**
 * Fetch a single government by ID with its associated chambers.
 *
 * Returns null when no government with the given ID exists.
 * All null string fields coerced to '' for Go convention.
 * Chambers array is [] when the government has no chambers.
 *
 * Uses pool.query() only — essentials schema is NOT in PostgREST exposed list.
 */
export async function getGovernmentById(id: string): Promise<GovernmentDetail | null> {
  const [govResult, chambersResult] = await Promise.all([
    pool.query(
      `SELECT id, name, type, state, city
       FROM essentials.governments
       WHERE id = $1`,
      [id]
    ),
    pool.query(
      `SELECT id, name, name_formal, type, election_frequency
       FROM essentials.chambers
       WHERE government_id = $1
       ORDER BY name`,
      [id]
    ),
  ]);

  if (govResult.rows.length === 0) {
    return null;
  }

  const row = govResult.rows[0];

  const chambers: ChamberSummary[] = chambersResult.rows.map((r) => ({
    id: r.id as string,
    name: r.name ?? '',
    name_formal: r.name_formal ?? '',
    type: r.type ?? '',
    election_frequency: r.election_frequency ?? '',
  }));

  return {
    id: row.id as string,
    name: row.name ?? '',
    type: row.type ?? '',
    state: row.state ?? '',
    city: row.city ?? '',
    chambers,
  };
}

// ---------------------------------------------------------------------------
// ChamberDetail types + getChamberById
// ---------------------------------------------------------------------------

export interface GovernmentSummary {
  id: string;
  name: string;
  type: string;
  state: string;
  city: string;
}

/**
 * Chamber entity with parent government context.
 */
export interface ChamberDetail {
  id: string;
  name: string;
  name_formal: string;
  type: string;
  election_frequency: string;
  government: GovernmentSummary;
}

/**
 * Fetch a single chamber by ID with its parent government.
 *
 * Returns null when no chamber with the given ID exists.
 * All null string fields coerced to '' for Go convention.
 *
 * Uses pool.query() only — essentials schema is NOT in PostgREST exposed list.
 */
export async function getChamberById(id: string): Promise<ChamberDetail | null> {
  const { rows } = await pool.query(
    `SELECT ch.id, ch.name, ch.name_formal, ch.type, ch.election_frequency,
            g.id AS gov_id, g.name AS gov_name, g.type AS gov_type,
            g.state AS gov_state, g.city AS gov_city
     FROM essentials.chambers ch
     LEFT JOIN essentials.governments g ON g.id = ch.government_id
     WHERE ch.id = $1`,
    [id]
  );

  if (rows.length === 0) {
    return null;
  }

  const row = rows[0];

  return {
    id: row.id as string,
    name: row.name ?? '',
    name_formal: row.name_formal ?? '',
    type: row.type ?? '',
    election_frequency: row.election_frequency ?? '',
    government: {
      id: row.gov_id ?? '',
      name: row.gov_name ?? '',
      type: row.gov_type ?? '',
      state: row.gov_state ?? '',
      city: row.gov_city ?? '',
    },
  };
}

// ---------------------------------------------------------------------------
// DistrictDetail types + getDistrictById
// ---------------------------------------------------------------------------

export interface DistrictPoliticianSummary {
  id: string;
  full_name: string;
  party: string;
  is_incumbent: boolean;
  photo_origin_url: string;
}

/**
 * District entity with active politicians, parent chamber, and government context.
 */
export interface DistrictDetail {
  id: string;
  external_id: string;
  label: string;
  district_type: string;
  district_id: string;
  state: string;
  mtfcc: string;
  geo_id: string;
  politicians: DistrictPoliticianSummary[];
  chamber: { id: string; name: string };
  government: { id: string; name: string };
}

/**
 * Fetch a single district by ID with its active politicians, chamber, and government.
 *
 * Returns null when no district with the given ID exists.
 * All null string fields coerced to '' for Go convention.
 * Politicians array is [] when no active politicians are assigned.
 *
 * Join path:
 *   districts → offices (district_id) → politicians (office_id, is_active=true)
 *   offices → chambers (chamber_id) → governments (government_id)
 *
 * Uses pool.query() only — essentials schema is NOT in PostgREST exposed list.
 */
export async function getDistrictById(id: string): Promise<DistrictDetail | null> {
  // First fetch the district itself to verify it exists
  const districtResult = await pool.query(
    `SELECT d.id, d.external_id, d.label, d.district_type, d.district_id, d.geo_id,
            d.state, d.mtfcc, d.geo_id,
            ch.id AS chamber_id, ch.name AS chamber_name,
            g.id AS gov_id, g.name AS gov_name
     FROM essentials.districts d
     LEFT JOIN essentials.offices o ON o.district_id = d.id
     LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
     LEFT JOIN essentials.governments g ON g.id = ch.government_id
     WHERE d.id = $1
     LIMIT 1`,
    [id]
  );

  if (districtResult.rows.length === 0) {
    return null;
  }

  const dRow = districtResult.rows[0];

  // Fetch active politicians for this district
  const politiciansResult = await pool.query(
    `SELECT p.id, p.full_name, p.party, p.is_incumbent, p.photo_origin_url
     FROM essentials.offices o
     JOIN essentials.politicians p ON o.politician_id = p.id
     WHERE o.district_id = $1
       AND p.is_active = true
     ORDER BY p.is_incumbent DESC, p.full_name`,
    [id]
  );

  const politicians: DistrictPoliticianSummary[] = politiciansResult.rows.map((r) => ({
    id: r.id as string,
    full_name: r.full_name ?? '',
    party: r.party ?? '',
    is_incumbent: r.is_incumbent ?? false,
    photo_origin_url: r.photo_origin_url ?? '',
  }));

  return {
    id: dRow.id as string,
    external_id: dRow.external_id ?? '',
    label: dRow.label ?? '',
    district_type: dRow.district_type ?? '',
    district_id: dRow.district_id ?? '',
    state: dRow.state ?? '',
    mtfcc: dRow.mtfcc ?? '',
    geo_id: dRow.geo_id ?? '',
    politicians,
    chamber: {
      id: dRow.chamber_id ?? '',
      name: dRow.chamber_name ?? '',
    },
    government: {
      id: dRow.gov_id ?? '',
      name: dRow.gov_name ?? '',
    },
  };
}

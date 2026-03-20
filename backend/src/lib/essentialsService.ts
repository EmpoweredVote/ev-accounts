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
  mtfcc: string;
  chamber_name: string;
  chamber_name_formal: string;
  government_name: string;
  is_elected: boolean;
  election_frequency: string;
  committees: null;
  bio_text: string | null;
  slug: string | null;
}

export interface AddressSearchResult {
  politicians: PoliticianFlatRecord[];
  jurisdiction: {
    district_type: string;
    district_id: string;
    district_label: string;
    mtfcc: string;
  } | null;
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
  includeCandidates?: boolean
): Promise<PoliticianFlatRecord[]> {
  const incumbentFilter = includeCandidates ? '' : 'AND p.is_incumbent = true';

  const queryText = `
    SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party, p.photo_origin_url, p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position,
           d.district_type, d.label AS district_label, d.geo_id AS district_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.id = p.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE p.is_active = true
    ${incumbentFilter}
    ORDER BY p.full_name
  `;

  const { rows } = await pool.query(queryText);

  return rows.map((row) => ({
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
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    government_name: row.government_name ?? '',
    // is_elected derived: NOT appointed. governments table has no is_elected column.
    is_elected: !row.is_appointed_position,
    // election_frequency is on chambers, not governments.
    election_frequency: row.election_frequency ?? '',
    committees: null,
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
  }));
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
  address: string
): Promise<AddressSearchResult> {
  // Geocode via Census Geocoder. GeocodingError propagates to caller.
  const { lat, lng } = await geocodeAddress(address);

  // CRITICAL: ST_MakePoint takes (longitude, latitude) = (Census x, Census y)
  // $1 = lng (Census coordinates.x), $2 = lat (Census coordinates.y)
  const queryText = `
    SELECT p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party, p.photo_origin_url, p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position,
           d.district_type, d.label AS district_label, d.geo_id AS district_id,
           d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.politicians p ON p.office_id = o.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE public.ST_Covers(
      gb.geometry,
      public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
    )
    AND p.is_active = true
  `;

  // $1 = longitude (Census coordinates.x), $2 = latitude (Census coordinates.y)
  const { rows } = await pool.query(queryText, [lng, lat]);

  if (rows.length === 0) {
    return { politicians: [], jurisdiction: null };
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
    mtfcc: row.mtfcc ?? '',
    chamber_name: row.chamber_name ?? '',
    chamber_name_formal: row.chamber_name_formal ?? '',
    government_name: row.government_name ?? '',
    // is_elected derived: NOT appointed. governments table has no is_elected column.
    is_elected: !row.is_appointed_position,
    // election_frequency is on chambers, not governments.
    election_frequency: row.election_frequency ?? '',
    committees: null,
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
  }));

  const firstRow = rows[0];
  const jurisdiction = {
    district_type: firstRow.district_type ?? '',
    district_id: firstRow.district_id ?? '',
    district_label: firstRow.district_label ?? '',
    mtfcc: firstRow.mtfcc ?? '',
  };

  return { politicians, jurisdiction };
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
           p.photo_origin_url, p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug,
           p.total_years_in_office, p.is_incumbent, p.is_appointed, p.is_vacant,
           p.is_active, p.office_id,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.seats AS office_seats,
           d.district_type, d.label AS district_label, d.geo_id AS district_id,
           d.mtfcc, d.state AS district_state,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           g.name AS government_name, g.id AS government_id
    FROM essentials.politicians p
    LEFT JOIN essentials.offices o ON o.id = p.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    WHERE p.id = $1
  `;

  // Run base query + all nested queries in parallel
  const [baseResult, contactsResult, imagesResult, degreesResult, experiencesResult] =
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
  };
}

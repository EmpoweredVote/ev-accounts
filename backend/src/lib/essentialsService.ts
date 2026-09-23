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
import { cache } from './cache.js';
import { geocodeAddress, GeocodingError } from './geocodingService.js';
import {
  buildZipDistrictQuery,
  buildZipStatesQuery,
  buildZipCountyQuery,
  buildZctaExistsQuery,
  rollUpAmbiguity,
  ZIP_CACHE_KEY_PREFIX,
  ZIP_CACHE_TTL_SECONDS,
} from './zipQueries.js';
// Phase 213 (RSLV-03): the coordinate-only entry point below reuses the
// Phase 212 national-fallback floor + single-House-rep derivation. Safe
// against circular-import breakage — essentialsBrowseService.ts only
// imports PoliticianFlatRecord/FinanceSummary from this file via
// `import type`, which is erased at compile time (no runtime cycle).
import { FIPS_TO_ABBREV, getStatewideOfficials, getPoliticiansByArea } from './essentialsBrowseService.js';


// Shared SQL text for every "who holds office here" lookup. Lives in its own
// side-effect-free module so it can be unit-tested without db.js env validation
// killing the run (see districtQueries.ts header).
import {
  UPCOMING_ELECTIONS_LATERAL,
  DISTRICT_SELECT_FIELDS,
  DISTRICT_JOINS,
  buildDistrictQuery,
  buildStatewideQuery,
} from './districtQueries.js';
export { GeocodingError };

/**
 * Enclave-city alias map.
 * Some cities are entirely enclosed within a larger USPS city boundary,
 * so Census TIGER / the geocoder returns the surrounding city name.
 * When the user's address string contains the enclave city name but the
 * geocoder returns the host city, substitute the enclave's G4110 centroid.
 *
 * Structure: { enclaveNameLower: { hostCity: string; lat: number; lng: number } }
 * Add new entries here as new enclave cities are onboarded.
 */
const ENCLAVE_CITY_ALIASES: Record<string, { hostCity: string; lat: number; lng: number }> = {
  'maywood park': { hostCity: 'portland', lat: 45.5525170, lng: -122.5617782 },
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/**
 * Campaign finance summary sourced from FEC data ingested by run-fec-finance-summary.ts.
 * Stored as JSONB on essentials.politicians.finance_summary.
 * null for non-federal politicians and federal politicians without matched FEC IDs.
 */
export interface FinanceSummary {
  /**
   * Absent when FEC has no totals row for the cycle — unknown, NOT $0.
   * Migration 1657 removed the key from rows the loader had silently zeroed;
   * consumers must distinguish `undefined` from `0` rather than `|| 0` them together.
   */
  total_raised?: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';
}

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
  chamber_url: string;
  government_type: string;
  is_elected: boolean;
  /**
   * ADR 0003. 'full' for an ordinary seat; 'committee_only' or 'non_voting' for a holder
   * who cannot cast a floor vote — the six territory/DC House delegates, DC's two shadow
   * senators, Maine's three tribal representatives.
   *
   * 🔴 representation_note is REQUIRED whenever voting_powers <> 'full', and the client MUST
   * render it with the seat. Until 2026-08-18 the address path selected NEITHER column, so
   * nine non-voting seats reached voters looking exactly like ordinary ones — a voter told
   * to "contact your representative" about a floor vote their delegate cannot cast.
   */
  voting_powers: 'full' | 'committee_only' | 'non_voting';
  representation_note: string | null;
  is_appointed: boolean;
  faces_retention_vote: boolean;
  election_frequency: string;
  policy_engagement_level: 'full' | 'record_only' | 'none';
  committees: Array<{ name: string; position: string; urls: string[] }>;
  bio_text: string | null;
  slug: string | null;
  is_incumbent: boolean;
  term_start: string;
  term_end: string;
  term_date_precision: string;
  appointment_date: string;
  office_description: string;
  is_vacant: boolean;
  vacant_since: string | null;
  next_primary_date: string;
  next_general_date: string;
  images: Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>;
  finance_summary: FinanceSummary | null;
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
  tribal_land: { on_reservation: boolean; name?: string };
  /** User's home county (5-digit FIPS GEOID + name), or null when unresolved. */
  county: { geoid: string; name: string } | null;
  /**
   * Phase 216 (LOC-01/02): incorporated-place signal, distinct from the
   * officials-joined `county` field above. `incorporated` is `null` (unknown)
   * outside PLACE_LOADED_STATES so the frontend suppresses the "Unincorporated"
   * label rather than false-positiving a real city in an un-loaded state.
   * `county_name` is populated whenever a G4020 row covers the point,
   * regardless of the place-loaded-state gate (D-03: county is always safe).
   */
  locality: { incorporated: boolean | null; place_name: string | null; county_name: string | null };
  /**
   * Resolved jurisdiction GEOIDs (congressional/state senate/state house/county/school),
   * derived from the same covering-district rows `county` and the single-district
   * `jurisdiction` field above are built from. Each field is null when that district
   * type wasn't among the covering rows. Consumed by read-rank for geographic
   * `isLocal` matching (see readrankService.getPlayableRaces).
   *
   * Named distinctly from `jurisdiction` above (an unrelated, pre-existing field of a
   * different shape carrying a single district) to avoid a naming collision — routes
   * are free to expose this under a `jurisdiction` JSON key of their own since JSON
   * keys aren't constrained by this TS interface's field name.
   */
  jurisdictionGeoIds: JurisdictionGeoIds;
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
  politicians: Array<{ id: string; images?: Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }> }>
): Promise<void> {
  if (politicians.length === 0) return;

  const ids = politicians.map((p) => p.id);
  const { rows } = await pool.query(
    `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point
     FROM essentials.politician_images
     WHERE politician_id = ANY($1)`,
    [ids]
  );

  // Group images by politician_id
  const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
  for (const row of rows) {
    const pid = row.politician_id as string;
    if (!imageMap.has(pid)) imageMap.set(pid, []);
    imageMap.get(pid)!.push({
      id: row.id as string,
      url: row.url ?? '',
      type: row.type ?? '',
      photo_license: row.photo_license ?? '',
      focal_point: (row.focal_point as string) ?? null,
    });
  }

  // Attach to each politician
  for (const p of politicians) {
    p.images = imageMap.get(p.id) ?? [];
  }
}

// ---------------------------------------------------------------------------
// batchFetchCommittees — shared by flat list, search results, and browse
// ---------------------------------------------------------------------------

/**
 * Batch-fetch committee memberships from legislative_committee_memberships +
 * legislative_committees and attach to politician records.
 *
 * Maps to Go-parity shape: { name, position, urls } where:
 *   name = committee name
 *   position = membership role (Chair, Member, etc.)
 *   urls = committee source URLs (empty array if none)
 */
async function batchFetchCommittees(
  politicians: Array<{ id: string; committees?: Array<{ name: string; position: string; urls: string[] }> }>
): Promise<void> {
  if (politicians.length === 0) return;

  const ids = politicians.map((p) => p.id);
  const { rows } = await pool.query(
    `SELECT m.politician_id,
            COALESCE(c.name, '') AS name,
            COALESCE(m.role, 'Member') AS position
     FROM essentials.legislative_committee_memberships m
     JOIN essentials.legislative_committees c ON c.id = m.committee_id
     WHERE m.politician_id = ANY($1)
     ORDER BY m.is_current DESC, c.name ASC`,
    [ids]
  );

  const committeeMap = new Map<string, Array<{ name: string; position: string; urls: string[] }>>();
  for (const row of rows) {
    const pid = row.politician_id as string;
    if (!committeeMap.has(pid)) committeeMap.set(pid, []);
    committeeMap.get(pid)!.push({
      name: row.name ?? '',
      position: row.position ?? 'Member',
      urls: [],
    });
  }

  for (const p of politicians) {
    p.committees = committeeMap.get(p.id) ?? [];
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
  // Candidate placeholder offices ("Candidate for U.S. Senate — ...", mig 196) are excluded from
  // the incumbents-only view: their holders can be incumbents of OTHER offices (Talarico TX House,
  // Paxton AG), so is_incumbent alone cannot exclude them.
  //
  // 🔴 `och.office_id IS NOT NULL` — an incumbent HOLDS A SEAT NOW, and only office_terms can say so.
  // is_incumbent is a cached flag, and it defaulted to true until CA_0188, so every insert that
  // omitted it created an "incumbent": this list returned 1,817 active rows with no office at all
  // (2026-09-23; cleared by CA_0181-CA_0187). The flag stays in the filter because it is what marks
  // a seated person as not-a-candidate, but it can no longer admit someone the view says holds nothing.
  const incumbentFilter = includeCandidates
    ? ''
    : "AND och.office_id IS NOT NULL AND p.is_incumbent = true AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'";

  const params: unknown[] = [];
  let searchFilter = '';
  let stateFilter = '';
  let limitClause = '';
  let offsetClause = '';

  if (options?.q) {
    params.push(`%${options.q}%`);
    const idx = params.length;
    // Fold accents on BOTH sides via public.f_unaccent so typing the ASCII form
    // finds accented names (e.g. "Munoz" matches "Muñoz", "Jose" matches "José").
    // ILIKE keeps it case-insensitive; f_unaccent is IMMUTABLE (same helper the
    // campaign-finance name search uses).
    searchFilter = `AND (public.f_unaccent(p.full_name) ILIKE public.f_unaccent($${idx}) OR public.f_unaccent(p.preferred_name) ILIKE public.f_unaccent($${idx}) OR public.f_unaccent(p.first_name) ILIKE public.f_unaccent($${idx}) OR public.f_unaccent(p.last_name) ILIKE public.f_unaccent($${idx}) OR public.f_unaccent(CONCAT(p.first_name, ' ', p.last_name)) ILIKE public.f_unaccent($${idx}))`;
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

  // 🔴 DISTINCT ON (p.id) — ONE ROW PER PERSON, not one per office they hold.
  // The office_current_holder join below is politician-rooted, so a person holding two offices
  // yielded two result rows. That is what returned two "Aaron Freeman"s, and it also made LIMIT
  // and OFFSET count duplicates, so a page of 50 could contain fewer than 50 people.
  // DISTINCT ON needs its own ORDER BY starting at p.id, which would fight the caller's
  // ORDER BY full_name and the pagination — hence the wrapper: dedupe inside, sort and paginate
  // outside. Preference for which office represents the person is the same one getPoliticianById
  // uses: a real reachable seat first, then not vacant, then o.id for stability.
  const queryText = `
    SELECT * FROM (
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           COALESCE(NULLIF(o.description, ''), pd_specific.description, pd_generic.description, '') AS office_description,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           ch.policy_engagement_level,
           g.name AS government_name,
           g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url,
           upcoming.next_primary_date, upcoming.next_general_date
    FROM essentials.politicians p
    -- ADR 0002 phase 3: which office this person holds NOW, via
    -- essentials.office_current_holder (office_terms + dual-read fallback), so a future-dated
    -- term takes effect on its own date.
    -- 🔴 THIS JOIN IS POLITICIAN-ROOTED AND CAN FAN OUT, and the comment here used to say it
    -- could not. The view is one row per OFFICE, so joining FROM offices is safe; joining FROM
    -- politicians returns one row PER OFFICE THE PERSON HOLDS. The office_terms exclusion
    -- constraint forbids two people on one office and cannot see one person on two — and people
    -- do hold two, whether a duplicate row from a discovery sweep or a genuine second seat.
    -- There is no DISTINCT below: a person holding two offices yields two result rows. That is
    -- what returned two "Aaron Freeman"s until CC_0103 removed the duplicate office (2026-09-12).
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.position_descriptions pd_specific
      ON pd_specific.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
      AND pd_specific.district_type = d.district_type
    LEFT JOIN essentials.position_descriptions pd_generic
      ON pd_generic.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
      AND pd_generic.district_type = ''
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    ${UPCOMING_ELECTIONS_LATERAL}
    WHERE p.is_active = true
    ${incumbentFilter}
    ${searchFilter}
    ${stateFilter}
    ORDER BY p.id,
             -- 🔴 A SEAT HELD BEATS A SEAT SOUGHT. The migration-196 "Candidate for ..." rows are
             -- real offices with a district AND a chamber, so without this they win on the
             -- checks below and a sitting U.S. Representative is reported as a Senate candidate.
             (COALESCE(o.title, '') ILIKE 'Candidate for%') ASC,
             (o.district_id IS NOT NULL) DESC,
             (o.chamber_id IS NOT NULL) DESC,
             COALESCE(o.is_vacant, false) ASC,
             o.id
    ) s
    ORDER BY s.full_name
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
    chamber_url: row.chamber_url ?? '',
    government_type: row.government_type ?? '',
    is_elected: !row.is_appointed_position,
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: row.is_appointed ?? false,
    faces_retention_vote: row.faces_retention_vote ?? false,
    election_frequency: row.election_frequency ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    is_incumbent: row.is_incumbent ?? false,
    term_start: row.term_start ?? '',
    term_end: row.term_end ?? '',
    term_date_precision: row.term_date_precision ?? '',
    appointment_date: row.appointment_date ?? '',
    office_description: row.office_description ?? '',
    is_vacant: row.is_vacant ?? false,
    vacant_since: row.vacant_since ?? null,
    next_primary_date: row.next_primary_date ?? '',
    next_general_date: row.next_general_date ?? '',
    images: [],
    finance_summary: row.finance_summary ?? null,
  }));

  await Promise.all([batchFetchImages(politicians), batchFetchCommittees(politicians)]);
  return politicians;
}

// ---------------------------------------------------------------------------
// getRepresentativesByAddress / getRepresentativesByCoordinate
// (shared point-resolution core: resolveOfficialsAtPoint, further below)
// ---------------------------------------------------------------------------

/** A county-wide district row carries the county's 5-digit FIPS as its geo_id. Sub-county seats
 *  (commissioner precincts, supervisor and council districts) are typed COUNTY too but carry geo_ids
 *  of their own ('ramsey-mn-commissioner-district-1', '55101-sup-d8'). Measured 2026-09-23: all 3,260
 *  COUNTY districts with a 5-digit geo_id have a G4020 geofence; no sub-county COUNTY district does. */
const isCountyFips = (geoId?: string | null): boolean => /^\d{5}$/.test(geoId ?? '');

/** Pick the user's county (GEOID + name) from the geofence district rows.
 *  A county is a county-wide COUNTY row, else a G4020 row (a county court). Null when absent —
 *  never a sub-county seat: the rows arrive in politician-id order, so "the first COUNTY row" used to
 *  be whichever seat's holder sorted first (Ramsey MN, Miami-Dade and Racine reported a commissioner or
 *  supervisor district as the county).
 *  `name` (the geofence_boundaries.name, e.g. "Monroe County") is the real county
 *  name; `district_label` is a seat label (e.g. "At-Large") and is only a fallback
 *  for rows that don't carry the geofence name (e.g. tests, callers without the join). */
export function pickCountyFromDistrictRows(
  rows: Array<{ mtfcc?: string | null; district_type?: string | null; geo_id?: string | null; district_label?: string | null; name?: string | null }>,
): { geoid: string; name: string } | null {
  // Prefer the COUNTY row; fall back to a G4020 row only if no county-wide COUNTY row exists.
  // (County-level courts can also be G4020 with the same county geo_id but a court name.)
  const row =
    rows.find((r) => r.district_type === 'COUNTY' && isCountyFips(r.geo_id)) ??
    rows.find((r) => r.mtfcc === 'G4020' && isCountyFips(r.geo_id));
  if (!row || !row.geo_id) return null;
  return { geoid: row.geo_id, name: row.name ?? row.district_label ?? '' };
}

/** Pick the user's resolved jurisdiction GEOIDs from the geofence district rows
 *  (the same rows pickCountyFromDistrictRows reads). Each field is the geo_id of
 *  the row whose district_type maps to it, or null when no such row is present.
 *  county prefers a county-wide COUNTY row, falling back to a county-wide JUDICIAL
 *  row (mirrors pickCountyFromDistrictRows' COUNTY-first preference for county-level
 *  courts sharing the same geo_id); a sub-county seat or a multi-county court is never
 *  the county. */
export function pickJurisdictionFromDistrictRows(
  rows: Array<{ district_type?: string | null; geo_id?: string | null }>,
): JurisdictionGeoIds {
  const geoIdForType = (type: string): string | null => rows.find((r) => r.district_type === type)?.geo_id || null;
  const countyFipsForType = (type: string): string | null =>
    rows.find((r) => r.district_type === type && isCountyFips(r.geo_id))?.geo_id || null;
  return {
    congressional: geoIdForType('NATIONAL_LOWER'),
    state_senate: geoIdForType('STATE_UPPER'),
    state_house: geoIdForType('STATE_LOWER'),
    county: countyFipsForType('COUNTY') ?? countyFipsForType('JUDICIAL'),
    school_district: geoIdForType('SCHOOL'),
  };
}

/**
 * States where the TIGER place layer (G4110/G4120 CDPs+incorporated places)
 * is loaded with meaningful coverage. Derived from a live DB ground-truth
 * query against essentials.geofence_boundaries (2026-07-22, see Phase 216
 * CONTEXT.md): `SELECT LEFT(geo_id,2), COUNT(*) FROM ... WHERE mtfcc='G4110'
 * GROUP BY 1`. Missouri (MO) is intentionally EXCLUDED despite having 1
 * incidental G4110 row loaded — that single row is not meaningful coverage,
 * and gating on it would false-positive real MO cities as "unincorporated".
 * A static list (rather than a dynamic "any G4110 row for this state" gate)
 * matches the TIGER loader's own "adding a state is a code change, on
 * purpose" philosophy and avoids a per-request query + magic threshold.
 */
export const PLACE_LOADED_STATES = new Set([
  'AZ', 'CA', 'IN', 'ME', 'MD', 'MA', 'NV', 'OR', 'TX', 'UT', 'VA',
]);

/**
 * buildLocality — pure gate/shape helper for the Phase 216 `locality` field
 * (LOC-01/02). Mirrors the `tribal_land` precedent's default-then-flip
 * shape, but with a three-state `incorporated` (true/false/null) instead of
 * a boolean, because "no place hit" is only meaningful signal inside a
 * place-loaded state (LOC-02).
 *
 * `county_name` is computed UNCONDITIONALLY from `countyRow` regardless of
 * the state gate (D-03: county boundaries are loaded nationwide and are
 * always safe to surface).
 */
export function buildLocality(
  state: string | null | undefined,
  placeRows: Array<{ name?: string | null }>,
  countyRow: { name?: string | null } | null | undefined,
): { incorporated: boolean | null; place_name: string | null; county_name: string | null } {
  const county_name = countyRow?.name ?? null;

  if (!state || !PLACE_LOADED_STATES.has(state.toUpperCase())) {
    return { incorporated: null, place_name: null, county_name };
  }

  if (placeRows.length > 0) {
    return { incorporated: true, place_name: placeRows[0].name ?? null, county_name };
  }

  return { incorporated: false, place_name: null, county_name };
}

/**
 * mapPoliticianRow — DB row -> PoliticianFlatRecord, via an EXPLICIT field
 * whitelist (house rule: rows are NEVER spread into responses).
 *
 * Shared by the point path and the ZIP/area path so the two cannot return
 * differently-shaped politicians. NOTE: essentialsBrowseService.mapBrowseRow and
 * the mapper in getPoliticiansFlatList are two further copies of this same field
 * set — consolidating those is worth doing, but is not this change's job.
 */
function mapPoliticianRow(row: Record<string, any>): PoliticianFlatRecord {
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
    chamber_url: row.chamber_url ?? '',
    government_type: row.government_type ?? '',
    is_elected: !row.is_appointed_position,
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: row.is_appointed ?? false,
    faces_retention_vote: row.faces_retention_vote ?? false,
    election_frequency: row.election_frequency ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: row.bio_text ?? null,
    slug: row.slug ?? null,
    is_incumbent: row.is_incumbent ?? false,
    term_start: row.term_start ?? '',
    term_end: row.term_end ?? '',
    term_date_precision: row.term_date_precision ?? '',
    appointment_date: row.appointment_date ?? '',
    office_description: row.office_description ?? '',
    is_vacant: row.is_vacant ?? false,
    vacant_since: row.vacant_since ?? null,
    next_primary_date: row.next_primary_date ?? '',
    next_general_date: row.next_general_date ?? '',
    images: [],
    finance_summary: row.finance_summary ?? null,
  };
}
/**
 * resolveOfficialsAtPoint — the shared coordinate->officials core, extracted
 * from getRepresentativesByAddress (Phase 213, D-04) so a precise point can
 * be resolved WITHOUT a Census geocode. Both getRepresentativesByAddress
 * (which still geocodes first) and getRepresentativesByCoordinate (which
 * never geocodes) call this same helper — kept private so it isn't a public
 * API surface of its own.
 *
 * `stateAbbrev` may be '' when the caller could not determine a state (mirrors
 * the pre-extraction behavior: the statewide query only runs when state is
 * truthy). `matchedAddress` is echoed into the result verbatim — callers that
 * have no reverse geocode (the coordinate path) MUST pass ''.
 */
async function resolveOfficialsAtPoint(
  point: { lng: number; lat: number },
  stateAbbrev: string,
  matchedAddress: string,
  { includeChallengers = false }: { includeChallengers?: boolean } = {}
): Promise<AddressSearchResult> {
  const resolvedLng = point.lng;
  const resolvedLat = point.lat;
  const state = stateAbbrev;

  // Officials whose district polygon COVERS this point. Built from the shared
  // district-query text (districtQueries.ts) so the point path and the ZIP/area
  // path cannot drift apart — notably on the MTFCC-to-district_type mapping.
  //
  // CRITICAL: ST_MakePoint takes (longitude, latitude) = (Census x, Census y)
  // $1 = lng (Census coordinates.x), $2 = lat (Census coordinates.y)
  //
  // ⚠ ev-cto decision 0006: this and every spatial predicate below pin SRID 4326 and use ST_SetSRID +
  // ST_Covers, which read NO coordinate-system table — so the anon write grant on public.spatial_ref_sys
  // (which we cannot revoke) stays harmless. Introducing ST_Transform or a ::geography cast here would
  // read spatial_ref_sys and re-open that accepted risk; get sign-off. CI guards it (check-postgis-spatial-ref-guard.mjs).
  const districtQueryText = buildDistrictQuery({
    // geofence_name feeds pickCountyFromDistrictRows — the county's real name,
    // as opposed to district_label, which is a seat label ("At-Large").
    extraSelect: ', gb.name AS geofence_name',
    spatialPredicate: `ST_Covers(
      gb.geometry,
      ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
    )`,
    includeChallengers,
  });

  // Statewide politicians — includes President/VP, Senators, Governor, Supreme Court
  const statewideQueryText = buildStatewideQuery();

  // D-06 / Pitfall 5: narrow tribal-lands lookup, always-present block.
  const tribalQueryText = `
    SELECT geo_id, name
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'X0004'
      AND ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
    LIMIT 1
  `;

  // Phase 216 (LOC-01): narrow incorporated-place lookup — mirrors tribalQueryText
  // exactly except for the mtfcc filter. Zero rows = no incorporated place covers
  // this point (place-loaded states only; see buildLocality/PLACE_LOADED_STATES).
  const placeQueryText = `
    SELECT geo_id, name
    FROM essentials.geofence_boundaries
    WHERE mtfcc IN ('G4110', 'G4120')
      AND ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
    LIMIT 1
  `;

  // Phase 216 (LOC-01/D-03): dedicated county-name probe. Counties are loaded
  // nationwide, so this is always a safe, unconditional signal — unlike
  // placeQueryText above, its result is never gated by PLACE_LOADED_STATES.
  const countyNameQueryText = `
    SELECT geo_id, name
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G4020'
      AND ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
    LIMIT 1
  `;

  // $1 = longitude (Census coordinates.x), $2 = latitude (Census coordinates.y)
  const [districtResult, statewideResult, tribalResult, placeResult, countyNameResult] = await Promise.all([
    pool.query(districtQueryText, [resolvedLng, resolvedLat]),
    state ? pool.query(statewideQueryText, [state]) : Promise.resolve({ rows: [] as unknown[] }),
    pool.query(tribalQueryText, [resolvedLng, resolvedLat]),
    pool.query(placeQueryText, [resolvedLng, resolvedLat]),
    pool.query(countyNameQueryText, [resolvedLng, resolvedLat]),
  ]);
  const rows = [...districtResult.rows, ...(statewideResult.rows as typeof districtResult.rows)];

  // Default to off-reservation; flip to on-reservation only if the X0004 query matches.
  let tribal_land: { on_reservation: boolean; name?: string } = { on_reservation: false };
  if (tribalResult.rows.length > 0) {
    tribal_land = { on_reservation: true, name: tribalResult.rows[0].name as string };
  }

  const locality = buildLocality(state, placeResult.rows, countyNameResult.rows[0] ?? null);

  if (rows.length === 0) {
    // Early-return path: explicit tribal_land defaulting to on_reservation: false when no district match.
    return {
      politicians: [],
      jurisdiction: null,
      matchedAddress,
      tribal_land: tribal_land ?? { on_reservation: false },
      county: null,
      jurisdictionGeoIds: {
        congressional: null, state_senate: null, state_house: null, county: null, school_district: null,
      },
      locality,
    };
  }

  const politicians: PoliticianFlatRecord[] = rows.map(mapPoliticianRow);

  await Promise.all([batchFetchImages(politicians), batchFetchCommittees(politicians)]);

  const firstRow = rows[0];
  const jurisdiction = {
    district_type: firstRow.district_type ?? '',
    district_id: firstRow.district_id ?? '',
    district_label: firstRow.district_label ?? '',
    mtfcc: firstRow.mtfcc ?? '',
  };

  const county = pickCountyFromDistrictRows(
    districtResult.rows.map((r) => ({ ...r, name: r.geofence_name })),
  );
  const jurisdictionGeoIds = pickJurisdictionFromDistrictRows(districtResult.rows);
  return { politicians, jurisdiction, matchedAddress, tribal_land, county, jurisdictionGeoIds, locality };
}

// ---------------------------------------------------------------------------
// ZIP (area) resolution
// ---------------------------------------------------------------------------

/** A politician plus how much of the ZIP their district covers. */
export interface AreaOfficial extends PoliticianFlatRecord {
  /**
   * Fraction (0-1] of the ZIP's area this official's district covers.
   * null for statewide offices: a state contains the whole ZIP, so a percentage
   * there would be noise rather than information.
   */
  share: number | null;
}

export interface ZipSearchResult {
  zip: string;
  /** USPS abbreviations for every state covering >=1% of the ZIP. */
  states: string[];
  /** The county covering the largest part of the ZIP, or null. */
  county: { geoid: string; name: string } | null;
  politicians: AreaOfficial[];
  /** Offices this ZIP cannot pin down, e.g. [{ STATE_LOWER, 4 }]. */
  ambiguity: Array<{ district_type: string; count: number }>;
}

/**
 * resolveOfficialsInArea — every official serving any part of a ZIP.
 *
 * The area analogue of resolveOfficialsAtPoint. A point falls on one side of every
 * district line; an area straddles them, so this legitimately returns four state
 * house members for a ZIP like 46220 — that is the answer, not a bug.
 *
 * Returns null when no ZCTA polygon exists for the ZIP: a well-formed string that
 * is not a real ZIP, which the route reports as 404 rather than as an empty result.
 *
 * `zip` MUST already be normalized to 5 digits (see normalizeZip).
 */
export async function resolveOfficialsInArea(zip: string): Promise<ZipSearchResult | null> {
  const [districtResult, statesResult, countyResult] = await Promise.all([
    pool.query(buildZipDistrictQuery(), [zip]),
    pool.query(buildZipStatesQuery(), [zip]),
    pool.query(buildZipCountyQuery(), [zip]),
  ]);

  // A missing ZCTA makes the CTE empty, which makes every query above return zero
  // rows — indistinguishable from a real ZIP we cover nothing in. Ask directly.
  if (districtResult.rows.length === 0 && statesResult.rows.length === 0) {
    const exists = await pool.query(buildZctaExistsQuery(), [zip]);
    if (exists.rows.length === 0) return null;
  }

  const states = statesResult.rows
    .map((r) => FIPS_TO_ABBREV[r.fips as string])
    .filter((abbrev): abbrev is string => Boolean(abbrev));

  // Statewide officials for every state the ZIP meaningfully touches — the same
  // query the point path runs, once per state. Roughly 1% of ZIPs cross a state
  // line, and those genuinely have two delegations.
  const statewideRows = states.length > 0
    ? (await Promise.all(states.map((s) => pool.query(buildStatewideQuery(), [s]))))
        .flatMap((r) => r.rows)
    : [];

  const politicians: AreaOfficial[] = [
    ...districtResult.rows.map((row) => ({
      ...mapPoliticianRow(row),
      share: row.share != null ? Number(row.share) : null,
    })),
    ...statewideRows.map((row) => ({ ...mapPoliticianRow(row), share: null })),
  ];

  await Promise.all([batchFetchImages(politicians), batchFetchCommittees(politicians)]);

  const countyRow = countyResult.rows[0];
  return {
    zip,
    states,
    county: countyRow
      ? { geoid: countyRow.geoid as string, name: (countyRow.name as string) ?? '' }
      : null,
    politicians,
    // Keyed on geo_id, not on politician count: 29 judges on one county court is
    // one district, not 29 ambiguities. See rollUpAmbiguity.
    ambiguity: rollUpAmbiguity(
      districtResult.rows.map((r) => ({
        district_type: (r.district_type as string) ?? '',
        geo_id: (r.geo_id as string) ?? '',
      })),
    ),
  };
}


/** Cached wrapper around resolveOfficialsInArea. */
export async function getOfficialsByZip(zip: string): Promise<ZipSearchResult | null> {
  const cacheKey = `${ZIP_CACHE_KEY_PREFIX}${zip}`;
  const cached = await cache.get<ZipSearchResult>(cacheKey);
  if (cached !== null) return cached;

  const result = await resolveOfficialsInArea(zip);
  // A negative result is cached too, but cache.get returns null for both "miss"
  // and "cached null", so an unknown ZIP re-runs the lookup. Accepted: correctness
  // over a sentinel, and unknown ZIPs are rare traffic.
  await cache.set(cacheKey, result, ZIP_CACHE_TTL_SECONDS);
  return result;
}

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
  const { lat, lng, matchedAddress, state, city } = await geocodeAddress(address);

  // Enclave-city alias override: some cities have streets stored under a
  // surrounding city's USPS name in Census TIGER. If the address string
  // names an enclave city but the geocoder returned its host city, substitute
  // the enclave's G4110 centroid so PostGIS hits the correct boundary.
  // Dual-condition: raw address must name the enclave AND geocoder must have
  // returned the host city (checked via matchedAddress OR addressComponents.city).
  let resolvedLat = lat;
  let resolvedLng = lng;
  const addrLower = address.toLowerCase();
  for (const [enclaveName, alias] of Object.entries(ENCLAVE_CITY_ALIASES)) {
    if (
      addrLower.includes(enclaveName) &&
      (matchedAddress.toLowerCase().includes(alias.hostCity) || city.toLowerCase() === alias.hostCity)
    ) {
      resolvedLat = alias.lat;
      resolvedLng = alias.lng;
      break;
    }
  }

  return resolveOfficialsAtPoint(
    { lng: resolvedLng, lat: resolvedLat },
    state,
    matchedAddress,
    { includeChallengers },
  );
}

// ---------------------------------------------------------------------------
// getRepresentativesByCoordinate (Phase 213, RSLV-03/RSLV-05, D-04/D-05/D-06)
// ---------------------------------------------------------------------------

/**
 * Statewide-tier district types the shared core's statewideQueryText
 * selects. Used only to detect the "zero state-scoped rows returned"
 * fallback condition for the D-05 state floor below — mirrors that query's
 * WHERE clause exactly so the fallback fires only on a genuine miss.
 */
const STATEWIDE_DISTRICT_TYPES = new Set([
  'NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', 'NATIONAL_JUDICIAL', 'JUDICIAL',
]);

/**
 * pickHouseRep — the exact single-House-rep selection precedent from
 * routes/essentialsLocationSearch.ts, INLINED here rather than imported so
 * lib/ never depends on routes/ (the dependency direction must stay
 * one-way: routes/ -> lib/, never the reverse).
 */
function pickHouseRep(
  records: PoliticianFlatRecord[],
  cdGeoId: string,
): PoliticianFlatRecord | null {
  return records.find((r) => r.district_type === 'NATIONAL_LOWER' && r.geo_id === cdGeoId) ?? null;
}

/**
 * Derive the 2-letter state abbreviation covering (lat, lng) WITHOUT a
 * Census geocode (D-04). Prefers an already-seeded congressional/county
 * district row; falls back to the raw G4000 state-boundary TIGER layer for
 * a valid-in-bbox point in an otherwise-unseeded area, so a state can still
 * usually be determined even where no local politicians exist yet.
 */
async function deriveStateAbbrevForPoint(lng: number, lat: number): Promise<string | null> {
  // CRITICAL: ST_MakePoint($1, $2) = (longitude, latitude) — $1 is ALWAYS
  // lng, $2 is ALWAYS lat. Same non-negotiable order as resolveOfficialsAtPoint.
  const { rows } = await pool.query<{ district_type: string; geo_id: string }>(
    `
    SELECT DISTINCT d.district_type, d.geo_id
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
      AND (
        (gb.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
        OR (gb.mtfcc = 'G4020' AND d.district_type IN ('COUNTY', 'JUDICIAL'))
      )
    WHERE ST_Covers(
      gb.geometry,
      ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
    )
    `,
    [lng, lat],
  );

  const preferred =
    rows.find((r) => r.district_type === 'NATIONAL_LOWER') ??
    rows.find((r) => r.district_type === 'COUNTY') ??
    rows[0];

  if (preferred?.geo_id) {
    const fips = preferred.geo_id.slice(0, 2);
    if (FIPS_TO_ABBREV[fips]) return FIPS_TO_ABBREV[fips];
  }

  // Fallback: valid-in-bbox point with no seeded district row at all — try
  // the raw state-boundary TIGER layer directly.
  const { rows: stateRows } = await pool.query<{ geo_id: string }>(
    `
    SELECT geo_id
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G4000'
      AND ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
    LIMIT 1
    `,
    [lng, lat],
  );
  const fips = stateRows[0]?.geo_id;
  return fips ? FIPS_TO_ABBREV[fips] ?? null : null;
}

/**
 * Find the congressional district (G5200) geo_id covering (lat, lng). Used
 * ONLY as the single-House-rep fallback below, when the shared core's own
 * district query returned zero NATIONAL_LOWER rows (a genuinely-unseeded
 * congressional district) — never to fetch the whole area roster.
 */
async function findCoveringCdGeoId(lng: number, lat: number): Promise<string | null> {
  // CRITICAL: ST_MakePoint($1, $2) = (longitude, latitude) — $1 is ALWAYS
  // lng, $2 is ALWAYS lat. Same non-negotiable order as resolveOfficialsAtPoint.
  const { rows } = await pool.query<{ geo_id: string }>(
    `
    SELECT geo_id
    FROM essentials.geofence_boundaries
    WHERE mtfcc = 'G5200'
      AND ST_Covers(
        geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
    LIMIT 1
    `,
    [lng, lat],
  );
  return rows[0]?.geo_id ?? null;
}

/**
 * getRepresentativesByCoordinate — coordinate-only entry point (RSLV-03).
 *
 * MUST NOT call geocodeAddress (D-04/RSLV-04) — the caller's point is
 * already precise, so no Census round-trip is needed or wanted. Resolves
 * the covering state via deriveStateAbbrevForPoint, then runs the SAME
 * shared point-resolution core getRepresentativesByAddress uses
 * (resolveOfficialsAtPoint), so the precise point resolves the exact single
 * US House rep from its own ST_Covers coverage (RSLV-05) without ever
 * merging the nationwide getFederalOfficials() roster into the result.
 *
 * D-05: resolveOfficialsAtPoint's statewideQueryText already returns the
 * state-scoped Senators/Governor/state-exec floor for the normal seeded
 * case. ONLY when it returns zero state-scoped rows (unseeded state) do we
 * pay for the extra getStatewideOfficials(abbrev) round-trip, so a valid US
 * point never comes back with an empty politicians array.
 *
 * D-06: matchedAddress is always '' — there is no reverse geocode for a raw
 * coordinate, and the submitted lat/lng is never placed anywhere in the
 * returned AddressSearchResult.
 */
export async function getRepresentativesByCoordinate(
  lat: number,
  lng: number,
): Promise<AddressSearchResult> {
  const stateAbbrev = await deriveStateAbbrevForPoint(lng, lat);

  const result = await resolveOfficialsAtPoint({ lng, lat }, stateAbbrev ?? '', '');

  const seenIds = new Set(result.politicians.map((p) => p.id));

  // D-05 state-scoped floor — ONLY as a fallback when the shared core
  // returned zero state-scoped rows. Never calls/merges getFederalOfficials().
  if (stateAbbrev && !result.politicians.some((p) => STATEWIDE_DISTRICT_TYPES.has(p.district_type))) {
    const floor = await getStatewideOfficials(stateAbbrev);
    for (const p of floor) {
      if (!seenIds.has(p.id)) {
        result.politicians.push(p);
        seenIds.add(p.id);
      }
    }
  }

  // Single-House-rep fallback — only when the shared core's own district
  // query found no NATIONAL_LOWER row (genuinely-unseeded CD); adds at most
  // that one representative, never the whole area roster.
  if (!result.politicians.some((p) => p.district_type === 'NATIONAL_LOWER')) {
    const cdGeoId = await findCoveringCdGeoId(lng, lat);
    if (cdGeoId) {
      const houseReps = await getPoliticiansByArea(cdGeoId, 'G5200');
      const rep = pickHouseRep(houseReps, cdGeoId);
      if (rep && !seenIds.has(rep.id)) {
        result.politicians.push(rep);
        seenIds.add(rep.id);
      }
    }
  }

  // D-06: no reverse geocode; never echo or derive a location label, and
  // never carry the raw coordinate anywhere in the returned object.
  result.matchedAddress = '';

  return result;
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
  focal_point: string | null;
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
  /**
   * ADR 0003. 'full' for an ordinary seat; 'committee_only' or 'non_voting' for a holder
   * who cannot cast a floor vote — the six territory/DC House delegates, DC's two shadow
   * senators, Maine's three tribal representatives.
   *
   * 🔴 representation_note is REQUIRED whenever voting_powers <> 'full', and the client MUST
   * render it with the seat. Until 2026-08-18 the address path selected NEITHER column, so
   * nine non-voting seats reached voters looking exactly like ordinary ones — a voter told
   * to "contact your representative" about a floor vote their delegate cannot cast.
   */
  voting_powers: 'full' | 'committee_only' | 'non_voting';
  representation_note: string | null;
  // Term dates
  term_start: string;
  term_end: string;
  term_date_precision: string;
  appointment_date: string;
  // Office details
  office_id: string | null;
  office_title: string;
  office_description: string;
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
  policy_engagement_level: 'full' | 'record_only' | 'none';
  // Government details
  government_id: string | null;
  government_name: string;
  chamber_url: string;
  government_type: string;
  // Nested arrays
  committees: Array<{ name: string; position: string; urls: string[] }>;
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
  next_primary_date: string;
  next_general_date: string;
  finance_summary: FinanceSummary | null;
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
           p.is_active, p.office_id, p.notes, p.finance_summary,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.voting_powers, o.representation_note,
           o.is_appointed_position, o.seats AS office_seats,
           COALESCE(NULLIF(o.description, ''), pd_specific.description, pd_generic.description, '') AS office_description,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id,
           d.mtfcc, d.state AS district_state,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           ch.policy_engagement_level,
           g.name AS government_name, g.id AS government_id,
           g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url,
           upcoming.next_primary_date, upcoming.next_general_date
    FROM essentials.politicians p
    -- ADR 0002 phase 3: which office this person holds NOW, via
    -- essentials.office_current_holder (office_terms + dual-read fallback), so a future-dated
    -- term takes effect on its own date.
    -- 🔴 THIS JOIN IS POLITICIAN-ROOTED AND CAN FAN OUT, and the comment here used to say it
    -- could not. The view is one row per OFFICE, so joining FROM offices is safe; joining FROM
    -- politicians returns one row PER OFFICE THE PERSON HOLDS. The office_terms exclusion
    -- constraint forbids two people on one office and cannot see one person on two — and people
    -- do hold two, whether a duplicate row from a discovery sweep or a genuine second seat.
    -- There is no DISTINCT below: a person holding two offices yields two result rows. That is
    -- what returned two "Aaron Freeman"s until CC_0103 removed the duplicate office (2026-09-12).
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.position_descriptions pd_specific
      ON pd_specific.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
      AND pd_specific.district_type = d.district_type
    LEFT JOIN essentials.position_descriptions pd_generic
      ON pd_generic.normalized_position_name = COALESCE(NULLIF(o.normalized_position_name, ''), o.title)
      AND pd_generic.district_type = ''
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    ${UPCOMING_ELECTIONS_LATERAL}
    WHERE p.id = $1
    -- 🔴 DETERMINISTIC PICK. A person may hold more than one office, so this can return several
    -- rows and the caller reads rows[0]. Without an ORDER BY that was whichever row Postgres
    -- happened to return, which is how a profile could report an office the person merely sought.
    -- Preference: a seat HELD before a seat SOUGHT, then a real reachable seat (has a district,
    -- then a chamber), then one not flagged vacant, then o.id so repeated calls agree.
    -- 🔴 The "Candidate for ..." rule is load-bearing and was missing from the first draft. Those
    -- rows carry a district AND a chamber, so they won every other check, and this query reported
    -- Harriet Hageman and Angie Craig — both sitting U.S. Representatives — as Senate candidates.
    -- Unlike the list query above, this one has no NOT ILIKE Candidate-for filter to lean on.
    ORDER BY (COALESCE(o.title, '') ILIKE 'Candidate for%') ASC,
             (o.district_id IS NOT NULL) DESC,
             (o.chamber_id IS NOT NULL) DESC,
             COALESCE(o.is_vacant, false) ASC,
             o.id
    LIMIT 1
  `;

  // Run base query + all nested queries in parallel
  const [baseResult, contactsResult, imagesResult, degreesResult, experiencesResult, addressesResult, identifiersResult, committeesResult] =
    await Promise.all([
      pool.query(baseQuery, [id]),
      pool.query(
        `SELECT id, source, email, phone, fax, contact_type, website_url
         FROM essentials.politician_contacts
         WHERE politician_id = $1
         ORDER BY CASE contact_type
           WHEN 'primary' THEN 0
           WHEN 'office' THEN 1
           WHEN 'office_website' THEN 2
           WHEN 'district' THEN 3
           WHEN 'central' THEN 4
           WHEN 'city_website' THEN 5
           WHEN 'campaign' THEN 6
           WHEN 'personal' THEN 7
           ELSE 8
         END`,
        [id]
      ),
      pool.query(
        `SELECT id, url, type, photo_license, focal_point
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
      pool.query(
        `SELECT COALESCE(c.name, '') AS name,
                COALESCE(m.role, 'Member') AS position
         FROM essentials.legislative_committee_memberships m
         JOIN essentials.legislative_committees c ON c.id = m.committee_id
         WHERE m.politician_id = $1
         ORDER BY m.is_current DESC, c.name ASC`,
        [id]
      ),
    ]);

  // Politician not found
  if (baseResult.rows.length === 0) {
    return null;
  }

  // ⚠ The query above is politician-rooted and has no DISTINCT and no ORDER BY, so for a person
  // holding more than one office this picks an ARBITRARY one and reports its title as theirs.
  // Until CC_0103 that could render "Governor" for someone who merely ran for governor.
  const row = baseResult.rows[0];

  const committees = committeesResult.rows.map((r) => ({
    name: r.name ?? '',
    position: r.position ?? 'Member',
    urls: [] as string[],
  }));

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
    focal_point: (r.focal_point as string) ?? null,
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
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    term_start: row.term_start ?? '',
    term_end: row.term_end ?? '',
    term_date_precision: row.term_date_precision ?? '',
    appointment_date: row.appointment_date ?? '',
    office_id: row.office_id ?? null,
    office_title: row.office_title ?? '',
    office_description: row.office_description ?? '',
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
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    government_id: row.government_id ?? null,
    government_name: row.government_name ?? '',
    chamber_url: row.chamber_url ?? '',
    government_type: row.government_type ?? '',
    committees,
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
    next_primary_date: row.next_primary_date ?? '',
    next_general_date: row.next_general_date ?? '',
    finance_summary: row.finance_summary ?? null,
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
  policy_engagement_level: 'full' | 'record_only' | 'none';
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
      `SELECT id, name, name_formal, type, election_frequency, policy_engagement_level
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
    policy_engagement_level: (r.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
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
  policy_engagement_level: 'full' | 'record_only' | 'none';
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
            ch.policy_engagement_level,
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
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
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
     -- ADR 0002 phase 3: occupant via essentials.office_current_holder, not the snapshot column.
     JOIN essentials.office_current_holder och ON och.office_id = o.id
     JOIN essentials.politicians p ON p.id = och.politician_id
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

// ---------------------------------------------------------------------------
// getRepresentativesByJurisdiction
//
// Returns politicians for a user's pre-resolved jurisdiction GEOIDs. No
// geocoding required — matches directly against essentials.districts.geo_id.
// Used by GET /api/essentials/representatives/me for Connected users.
//
// jurisdiction fields use the same TIGER/Line GEOID format stored by
// connect.resolve_user_jurisdiction: congressional="1807", county="18097", etc.
// ---------------------------------------------------------------------------

export interface JurisdictionGeoIds {
  congressional: string | null;
  state_senate: string | null;
  state_house: string | null;
  county: string | null;
  school_district: string | null;
}

export async function getRepresentativesByJurisdiction(
  jurisdiction: JurisdictionGeoIds
): Promise<PoliticianFlatRecord[]> {
  const { congressional, state_senate, state_house, county, school_district } = jurisdiction;

  // Build per-type conditions for district-based lookup
  const conditions: string[] = [];
  const params: string[] = [];

  if (congressional) {
    params.push(congressional);
    conditions.push(`(d.district_type = 'NATIONAL_LOWER' AND d.geo_id = $${params.length})`);
  }
  if (state_senate) {
    params.push(state_senate);
    conditions.push(`(d.district_type = 'STATE_UPPER' AND d.geo_id = $${params.length})`);
  }
  if (state_house) {
    params.push(state_house);
    conditions.push(`(d.district_type = 'STATE_LOWER' AND d.geo_id = $${params.length})`);
  }
  if (county) {
    params.push(county);
    conditions.push(`(d.district_type IN ('COUNTY', 'JUDICIAL') AND d.geo_id = $${params.length})`);
  }
  if (school_district) {
    params.push(school_district);
    conditions.push(`(d.district_type = 'SCHOOL' AND d.geo_id = $${params.length})`);
  }

  if (conditions.length === 0) return [];

  // Shared with the point/area paths — see districtQueries.ts. Aliased locally so
  // the query text below reads unchanged.
  const SELECT_FIELDS = DISTRICT_SELECT_FIELDS;
  const JOINS = DISTRICT_JOINS;

  const districtQueryText = `
    SELECT ${SELECT_FIELDS}
    FROM essentials.districts d
    ${JOINS}
    WHERE (${conditions.join(' OR ')})
    AND (p.is_active = true OR o.is_vacant = true)
    AND COALESCE(p.is_incumbent, true) = true AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY COALESCE(p.id, o.id)
  `;

  // Statewide politicians (senators, president, governor) — derive state from congressional GEOID.
  // NATIONAL_UPPER senators represent the whole state; their district geo_id is the 2-char state FIPS.
  // Look up the state abbreviation from the congressional district record to match d.state.
  let statewideRows: Record<string, unknown>[] = [];
  if (congressional) {
    const stateRes = await pool.query<{ state: string }>(
      `SELECT state FROM essentials.districts WHERE geo_id = $1 AND district_type = 'NATIONAL_LOWER' LIMIT 1`,
      [congressional]
    );
    if (stateRes.rows.length > 0) {
      const state = stateRes.rows[0].state;
      // The same statewide query the address path uses. This used to be an inline copy that still
      // decided "statewide court" by geo_id LENGTH (anything not 5 chars), so any JUDICIAL district with its own
      // non-county polygon came back for EVERY user in the state: Indiana's Court of Appeals
      // Districts 1-3 (7-char geo_ids, migration 1832) and, once CA_0189 linked it, California's
      // Second Appellate District ('06-appellate-district-2'). buildStatewideQuery's rule is
      // "statewide iff no geofence below the state outline".
      const sw = await pool.query(buildStatewideQuery(), [state]);
      statewideRows = sw.rows as Record<string, unknown>[];
    }
  }

  const districtResult = await pool.query(districtQueryText, params);
  const allRows = [
    ...(districtResult.rows as Record<string, unknown>[]),
    ...statewideRows,
  ];

  // Deduplicate: same politician may appear via multiple district matches
  const seen = new Set<string>();
  const uniqueRows = allRows.filter((row) => {
    const key = (row.id as string | null) != null
      ? (row.id as string)
      : `vacant-${row.geo_id ?? ''}-${row.district_id ?? ''}`;

    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  const politicians: PoliticianFlatRecord[] = uniqueRows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: (row.first_name as string) ?? '',
    middle_initial: (row.middle_initial as string) ?? '',
    last_name: (row.last_name as string) ?? '',
    preferred_name: (row.preferred_name as string) ?? '',
    name_suffix: (row.name_suffix as string) ?? '',
    full_name: (row.full_name as string) ?? '',
    party: (row.party as string) ?? '',
    photo_origin_url: (row.photo_origin_url as string) ?? '',
    web_form_url: (row.web_form_url as string) ?? '',
    urls: (row.urls as string[] | null) ?? null,
    email_addresses: (row.email_addresses as string[] | null) ?? null,
    office_title: (row.office_title as string) ?? '',
    representing_state: (row.representing_state as string) ?? '',
    representing_city: (row.representing_city as string) ?? '',
    district_type: (row.district_type as string) ?? '',
    district_label: (row.district_label as string) ?? '',
    district_id: (row.district_id as string) ?? '',
    geo_id: (row.geo_id as string) ?? '',
    mtfcc: (row.mtfcc as string) ?? '',
    chamber_name: (row.chamber_name as string) ?? '',
    chamber_name_formal: (row.chamber_name_formal as string) ?? '',
    government_name: (row.government_name as string) ?? '',
    government_body_name: (row.government_body_name as string) ?? '',
    government_body_url: (row.government_body_url as string) ?? '',
    chamber_url: (row.chamber_url as string) ?? '',
    government_type: (row.government_type as string) ?? '',
    is_elected: !(row.is_appointed_position as boolean),
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: (row.is_appointed as boolean) ?? false,
    faces_retention_vote: (row.faces_retention_vote as boolean) ?? false,
    election_frequency: (row.election_frequency as string) ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: (row.bio_text as string | null) ?? null,
    slug: (row.slug as string | null) ?? null,
    is_incumbent: (row.is_incumbent as boolean) ?? false,
    term_start: (row.term_start as string) ?? '',
    term_end: (row.term_end as string) ?? '',
    term_date_precision: (row.term_date_precision as string) ?? '',
    appointment_date: (row.appointment_date as string) ?? '',
    office_description: '',
    is_vacant: (row.is_vacant as boolean) ?? false,
    vacant_since: (row.vacant_since as string | null) ?? null,
    next_primary_date: (row.next_primary_date as string) ?? '',
    next_general_date: (row.next_general_date as string) ?? '',
    images: [],
    finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
  }));

  await Promise.all([batchFetchImages(politicians), batchFetchCommittees(politicians)]);

  return politicians;
}

// ---------------------------------------------------------------------------
// getLocalOfficialsByUserId
//
// Returns politicians for LOCAL and LOCAL_EXEC district types by calling
// the connect.resolve_user_local_officials RPC, which decrypts the user's
// stored coordinates and performs a live PostGIS ST_Covers lookup.
//
// Called from GET /api/essentials/representatives/me (Path 1) to supplement
// the pre-computed geo_id lookup, which does not cover LOCAL/LOCAL_EXEC
// because city council sub-districts require coordinate-based polygon lookup.
// ---------------------------------------------------------------------------

export async function getLocalOfficialsByUserId(userId: string): Promise<PoliticianFlatRecord[]> {
  // Step 1: resolve LOCAL/LOCAL_EXEC geo_ids for this user via PostGIS RPC
  const rpcResult = await pool.query<{ geo_id: string; district_type: string }>(
    `SELECT * FROM connect.resolve_user_local_officials($1)`,
    [userId]
  );

  if (rpcResult.rows.length === 0) return [];

  const geoIds = rpcResult.rows.map((r) => r.geo_id);

  // Step 2: fetch politicians for those geo_ids. The COLUMN LIST and JOIN CHAIN are
  // now shared with every other district lookup (districtQueries.ts) — they were
  // byte-identical copies, and the point-path result set was verified unchanged
  // against prod after consolidating them.
  //
  // The geo-pair MAPPING BLOCK further down remains intentionally duplicated —
  // do NOT fold it into getRepresentativesByJurisdiction.
  //
  // Aliased locally so the query text below reads unchanged.
  const SELECT_FIELDS = DISTRICT_SELECT_FIELDS;
  const JOINS = DISTRICT_JOINS;

  const queryText = `
    SELECT ${SELECT_FIELDS}
    FROM essentials.districts d
    ${JOINS}
    WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC')
      AND d.geo_id = ANY($1::text[])
      AND (p.is_active = true OR o.is_vacant = true)
      AND COALESCE(p.is_incumbent, true) = true AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'
    ORDER BY COALESCE(p.id, o.id)
  `;

  const result = await pool.query(queryText, [geoIds]);

  const politicians: PoliticianFlatRecord[] = (result.rows as Record<string, unknown>[]).map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: (row.first_name as string) ?? '',
    middle_initial: (row.middle_initial as string) ?? '',
    last_name: (row.last_name as string) ?? '',
    preferred_name: (row.preferred_name as string) ?? '',
    name_suffix: (row.name_suffix as string) ?? '',
    full_name: (row.full_name as string) ?? '',
    party: (row.party as string) ?? '',
    photo_origin_url: (row.photo_origin_url as string) ?? '',
    web_form_url: (row.web_form_url as string) ?? '',
    urls: (row.urls as string[] | null) ?? null,
    email_addresses: (row.email_addresses as string[] | null) ?? null,
    office_title: (row.office_title as string) ?? '',
    representing_state: (row.representing_state as string) ?? '',
    representing_city: (row.representing_city as string) ?? '',
    district_type: (row.district_type as string) ?? '',
    district_label: (row.district_label as string) ?? '',
    district_id: (row.district_id as string) ?? '',
    geo_id: (row.geo_id as string) ?? '',
    mtfcc: (row.mtfcc as string) ?? '',
    chamber_name: (row.chamber_name as string) ?? '',
    chamber_name_formal: (row.chamber_name_formal as string) ?? '',
    government_name: (row.government_name as string) ?? '',
    government_body_name: (row.government_body_name as string) ?? '',
    government_body_url: (row.government_body_url as string) ?? '',
    chamber_url: (row.chamber_url as string) ?? '',
    government_type: (row.government_type as string) ?? '',
    is_elected: !(row.is_appointed_position as boolean),
    voting_powers: (row.voting_powers as 'full' | 'committee_only' | 'non_voting') ?? 'full',
    representation_note: (row.representation_note as string | null) ?? null,
    is_appointed: (row.is_appointed as boolean) ?? false,
    faces_retention_vote: (row.faces_retention_vote as boolean) ?? false,
    election_frequency: (row.election_frequency as string) ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: (row.bio_text as string | null) ?? null,
    slug: (row.slug as string | null) ?? null,
    is_incumbent: (row.is_incumbent as boolean) ?? false,
    term_start: (row.term_start as string) ?? '',
    term_end: (row.term_end as string) ?? '',
    term_date_precision: (row.term_date_precision as string) ?? '',
    appointment_date: (row.appointment_date as string) ?? '',
    office_description: '',
    is_vacant: (row.is_vacant as boolean) ?? false,
    vacant_since: (row.vacant_since as string | null) ?? null,
    next_primary_date: (row.next_primary_date as string) ?? '',
    next_general_date: (row.next_general_date as string) ?? '',
    images: [],
    finance_summary: (row.finance_summary as FinanceSummary | null) ?? null,
  }));

  await Promise.all([batchFetchImages(politicians), batchFetchCommittees(politicians)]);

  return politicians;
}

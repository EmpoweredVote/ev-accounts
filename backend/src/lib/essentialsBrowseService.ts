/**
 * essentialsBrowseService — browse-by-location endpoints.
 *
 * Provides cascading location selection (State → County → City/Township)
 * and area-based politician lookup via PostGIS geofence intersection.
 *
 * This replaces the need for geocoding area queries (cities, ZIPs, counties)
 * which the Census Geocoder cannot handle.
 */

import { pool } from './db.js';
import type { PoliticianFlatRecord } from './essentialsService.js';

// FIPS → state abbreviation mapping
const FIPS_TO_ABBREV: Record<string, string> = {
  '01': 'AL', '02': 'AK', '04': 'AZ', '05': 'AR', '06': 'CA',
  '08': 'CO', '09': 'CT', '10': 'DE', '11': 'DC', '12': 'FL',
  '13': 'GA', '15': 'HI', '16': 'ID', '17': 'IL', '18': 'IN',
  '19': 'IA', '20': 'KS', '21': 'KY', '22': 'LA', '23': 'ME',
  '24': 'MD', '25': 'MA', '26': 'MI', '27': 'MN', '28': 'MS',
  '29': 'MO', '30': 'MT', '31': 'NE', '32': 'NV', '33': 'NH',
  '34': 'NJ', '35': 'NM', '36': 'NY', '37': 'NC', '38': 'ND',
  '39': 'OH', '40': 'OK', '41': 'OR', '42': 'PA', '44': 'RI',
  '45': 'SC', '46': 'SD', '47': 'TN', '48': 'TX', '49': 'UT',
  '50': 'VT', '51': 'VA', '53': 'WA', '54': 'WV', '55': 'WI',
  '56': 'WY',
};

const ABBREV_TO_FIPS: Record<string, string> = {};
for (const [fips, abbrev] of Object.entries(FIPS_TO_ABBREV)) {
  ABBREV_TO_FIPS[abbrev] = fips;
}

export interface BrowseState {
  abbreviation: string;
  fips: string;
  politician_count: number;
}

export interface BrowseArea {
  geo_id: string;
  name: string;
  mtfcc: string;
  area_type: string; // "county", "city", "township"
}

/**
 * Get states that have politician data.
 */
export async function getStatesWithData(): Promise<BrowseState[]> {
  const { rows } = await pool.query(`
    SELECT DISTINCT o.representing_state AS state, COUNT(DISTINCT p.id) AS cnt
    FROM essentials.offices o
    JOIN essentials.politicians p ON o.politician_id = p.id
    WHERE p.is_active = true
    AND o.representing_state IS NOT NULL
    AND o.representing_state != ''
    AND o.representing_state NOT IN ('US')
    GROUP BY o.representing_state
    ORDER BY o.representing_state
  `);

  return rows.map((r) => ({
    abbreviation: r.state as string,
    fips: ABBREV_TO_FIPS[r.state as string] ?? '',
    politician_count: Number(r.cnt),
  }));
}

/**
 * Get browsable areas (counties, cities, townships) for a state.
 * Returns areas from geofence_boundaries grouped by type.
 */
export async function getAreasForState(stateAbbrev: string): Promise<BrowseArea[]> {
  const fips = ABBREV_TO_FIPS[stateAbbrev.toUpperCase()];
  if (!fips) return [];

  const { rows } = await pool.query(`
    SELECT DISTINCT gb.geo_id, gb.name, gb.mtfcc
    FROM essentials.geofence_boundaries gb
    WHERE gb.state = $1
    AND gb.mtfcc IN ('G4020', 'G4110', 'G4120', 'G4040')
    ORDER BY gb.mtfcc, gb.name
  `, [fips]);

  return rows.map((r) => {
    const mtfcc = r.mtfcc as string;
    let area_type = 'other';
    if (mtfcc === 'G4020') area_type = 'county';
    else if (mtfcc === 'G4110' || mtfcc === 'G4120') area_type = 'city';
    else if (mtfcc === 'G4040') area_type = 'township';

    return {
      geo_id: r.geo_id as string,
      name: r.name as string,
      mtfcc,
      area_type,
    };
  });
}

/**
 * Compute all overlapping district geo_ids for a given area boundary, plus the
 * area's resolved state abbreviation.
 *
 * Extracted from getPoliticiansByArea so it can be shared with elections lookups.
 * Uses the same bidirectional PostGIS intersection logic:
 *   1. Sub-districts whose center falls WITHIN the area
 *   2. Larger non-city districts that CONTAIN the area's center
 *   3. Legislative districts that INTERSECT the area
 *
 * The returned `geoIds` array always includes the input `geoId` itself first.
 */
export async function getOverlappingGeoIdsForArea(
  geoId: string,
  mtfcc: string
): Promise<{ geoIds: string[]; stateAbbrev: string | null }> {
  const intersectionQuery = `
    SELECT DISTINCT gb2.geo_id, gb2.mtfcc
    FROM essentials.geofence_boundaries gb1
    JOIN essentials.geofence_boundaries gb2 ON gb2.geo_id != gb1.geo_id
    WHERE gb1.geo_id = $1 AND gb1.mtfcc = $2
    AND (
      -- Sub-districts whose representative point falls WITHIN the area
      public.ST_Contains(gb1.geometry, public.ST_PointOnSurface(gb2.geometry))
      -- Larger non-city districts that CONTAIN the area's center point
      OR (public.ST_Contains(gb2.geometry, public.ST_PointOnSurface(gb1.geometry))
          AND gb2.mtfcc NOT IN ('G4110', 'G4120'))
      -- Legislative districts that have ANY geometric overlap
      OR (public.ST_Intersects(gb1.geometry, gb2.geometry)
          AND gb2.mtfcc IN ('G5200', 'G5210', 'G5220'))
    )
  `;

  const { rows: geoMatches } = await pool.query(intersectionQuery, [geoId, mtfcc]);
  const geoIds = [geoId, ...geoMatches.map((r) => r.geo_id as string)];

  const { rows: areaRows } = await pool.query(
    `SELECT state FROM essentials.geofence_boundaries WHERE geo_id = $1 AND mtfcc = $2 LIMIT 1`,
    [geoId, mtfcc]
  );

  const stateFips = areaRows.length > 0 ? (areaRows[0].state as string) : null;
  const stateAbbrev = stateFips ? FIPS_TO_ABBREV[stateFips] ?? null : null;

  return { geoIds, stateAbbrev };
}

/**
 * Find all politicians whose districts overlap with a given area boundary.
 * Uses the same bidirectional PostGIS intersection logic as the Go backend.
 *
 * 1. Sub-districts whose center falls WITHIN the area
 * 2. Larger districts that CONTAIN the area's center (excluding city boundaries)
 * 3. Legislative districts that INTERSECT the area
 *
 * Then supplements with statewide officials (senators, governor).
 */
export async function getPoliticiansByArea(
  geoId: string,
  mtfcc: string
): Promise<PoliticianFlatRecord[]> {
  // Step 1: Compute all overlapping district geo_ids + resolved state via shared helper
  const { geoIds: allGeoIds, stateAbbrev } = await getOverlappingGeoIdsForArea(geoId, mtfcc);

  if (allGeoIds.length === 0) return [];

  // Step 2: Find politicians in matched districts
  const politicianQuery = `
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party, COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url, p.web_form_url,
           p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency,
           ch.policy_engagement_level,
           g.name AS government_name,
           g.type AS government_type,
           COALESCE(gvb.display_name, '') AS government_body_name,
           COALESCE(gvb.website_url, '') AS government_body_url,
           COALESCE(ch.website_url, '') AS chamber_url
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.politicians p ON o.politician_id = p.id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    WHERE d.geo_id = ANY($1)
    AND p.is_active = true
    ORDER BY p.id
  `;

  const { rows: polRows } = await pool.query(politicianQuery, [allGeoIds]);

  // Step 3: Use stateAbbrev (resolved by getOverlappingGeoIdsForArea) to add statewide officials
  let statewideRows: typeof polRows = [];
  if (stateAbbrev) {
    const statewideQuery = `
      SELECT DISTINCT ON (p.id)
             p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
             p.preferred_name, p.name_suffix, p.party, COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url, p.web_form_url,
             p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
             o.title AS office_title, o.representing_state, o.representing_city,
             o.is_appointed_position, o.is_vacant, o.vacant_since,
             p.is_appointed, o.faces_retention_vote,
             d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
             ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
             ch.election_frequency,
             ch.policy_engagement_level,
             g.name AS government_name,
             g.type AS government_type,
             COALESCE(gvb.display_name, '') AS government_body_name,
             COALESCE(gvb.website_url, '') AS government_body_url,
             COALESCE(ch.website_url, '') AS chamber_url
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON o.politician_id = p.id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
        AND gvb.geo_id = d.geo_id
        AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', 'NATIONAL_EXEC')
      AND (d.state = $1 OR d.district_type = 'NATIONAL_EXEC')
      AND p.is_active = true
      ORDER BY p.id
    `;
    const result = await pool.query(statewideQuery, [stateAbbrev]);
    statewideRows = result.rows;
  }

  // Combine and deduplicate
  const allRows = [...polRows, ...statewideRows];
  const seen = new Set<string>();
  const uniqueRows = allRows.filter((r) => {
    const id = r.id as string;
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  });

  const politicians: PoliticianFlatRecord[] = uniqueRows.map((row) => ({
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
    office_description: '',
    is_vacant: row.is_vacant ?? false,
    vacant_since: row.vacant_since ?? null,
    next_primary_date: row.next_primary_date ?? '',
    next_general_date: row.next_general_date ?? '',
    images: [],
  }));

  // Batch-fetch images and committees
  if (politicians.length > 0) {
    const ids = politicians.map((p) => p.id);
    const [{ rows: imgRows }, { rows: commRows }] = await Promise.all([
      pool.query(
        `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point
         FROM essentials.politician_images WHERE politician_id = ANY($1)`,
        [ids]
      ),
      pool.query(
        `SELECT m.politician_id,
                COALESCE(c.name, '') AS name,
                COALESCE(m.role, 'Member') AS position
         FROM essentials.legislative_committee_memberships m
         JOIN essentials.legislative_committees c ON c.id = m.committee_id
         WHERE m.politician_id = ANY($1)
         ORDER BY m.is_current DESC, c.name ASC`,
        [ids]
      ),
    ]);
    const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
    for (const r of imgRows) {
      const pid = r.politician_id as string;
      if (!imageMap.has(pid)) imageMap.set(pid, []);
      imageMap.get(pid)!.push({
        id: r.id as string,
        url: r.url ?? '',
        type: r.type ?? '',
        photo_license: r.photo_license ?? '',
        focal_point: (r.focal_point as string) ?? null,
      });
    }
    const committeeMap = new Map<string, Array<{ name: string; position: string; urls: string[] }>>();
    for (const r of commRows) {
      const pid = r.politician_id as string;
      if (!committeeMap.has(pid)) committeeMap.set(pid, []);
      committeeMap.get(pid)!.push({
        name: r.name ?? '',
        position: r.position ?? 'Member',
        urls: [],
      });
    }
    for (const p of politicians) {
      p.images = imageMap.get(p.id) ?? [];
      (p as { committees: Array<{ name: string; position: string; urls: string[] }> }).committees = committeeMap.get(p.id) ?? [];
    }
  }

  return politicians;
}

/**
 * Find all politicians for a specific list of government geo_ids.
 * Queries directly through governments → chambers → offices → politicians,
 * bypassing the geofence/district infrastructure (for jurisdictions whose
 * city boundaries and district records haven't been loaded).
 */
export async function getPoliticiansByGovernmentList(
  governmentGeoIds: string[],
  stateAbbrev?: string,
  options: { countyGeoId?: string } = {}
): Promise<PoliticianFlatRecord[]> {
  if (governmentGeoIds.length === 0) return [];
  const { countyGeoId } = options;

  const { rows } = await pool.query<Record<string, unknown>>(`
    SELECT DISTINCT ON (p.id)
           p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
           p.preferred_name, p.name_suffix, p.party,
           COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
           p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
           COALESCE(p.valid_from, '') AS term_start,
           COALESCE(p.valid_to, '') AS term_end,
           COALESCE(p.term_date_precision, '') AS term_date_precision,
           COALESCE(p.appointment_date::text, '') AS appointment_date,
           o.title AS office_title, o.representing_state, o.representing_city,
           o.is_appointed_position, o.is_vacant, o.vacant_since,
           p.is_appointed, o.faces_retention_vote,
           CASE
             WHEN g.type IN ('LOCAL', 'City', 'Town', 'Township')
                  AND LOWER(o.title) ~ '(mayor|city manager|city administrator|city secretary)'
               THEN 'LOCAL_EXEC'
             WHEN g.type IN ('LOCAL', 'City', 'Town', 'Township') THEN 'LOCAL'
             WHEN g.type = 'County' THEN 'COUNTY'
             WHEN g.type = 'School District' THEN 'SCHOOL'
             ELSE ''
           END AS district_type,
           COALESCE(d.label, '') AS district_label,
           COALESCE(d.district_id, '') AS district_id,
           COALESCE(d.geo_id, g.geo_id) AS geo_id, COALESCE(d.mtfcc, '') AS mtfcc,
           ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
           ch.election_frequency, ch.policy_engagement_level,
           g.name AS government_name, g.type AS government_type,
           COALESCE(ch.website_url, '') AS chamber_url,
           '' AS government_body_name, '' AS government_body_url
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.politicians p ON p.id = o.politician_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE g.geo_id = ANY($1)
      AND p.is_active = true
      AND p.is_vacant = false
    ORDER BY p.id
  `, [governmentGeoIds]);

  // Supplemental query: add state-wide and federal officials (same as by-area Step 3)
  let statewideRows: typeof rows = [];
  if (stateAbbrev) {
    const { rows: swRows } = await pool.query<Record<string, unknown>>(`
      SELECT DISTINCT ON (p.id)
             p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
             p.preferred_name, p.name_suffix, p.party,
             COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
             p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
             COALESCE(p.valid_from, '') AS term_start,
             COALESCE(p.valid_to, '') AS term_end,
             COALESCE(p.term_date_precision, '') AS term_date_precision,
             COALESCE(p.appointment_date::text, '') AS appointment_date,
             o.title AS office_title, o.representing_state, o.representing_city,
             o.is_appointed_position, o.is_vacant, o.vacant_since,
             p.is_appointed, o.faces_retention_vote,
             d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
             ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
             ch.election_frequency, ch.policy_engagement_level,
             g.name AS government_name, g.type AS government_type,
             COALESCE(gvb.display_name, '') AS government_body_name,
             COALESCE(gvb.website_url, '') AS government_body_url,
             COALESCE(ch.website_url, '') AS chamber_url
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON o.politician_id = p.id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
        AND gvb.geo_id = d.geo_id
        AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE d.district_type IN ('NATIONAL_UPPER', 'STATE_EXEC', 'NATIONAL_EXEC', 'NATIONAL_JUDICIAL')
        AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
        AND p.is_active = true
      ORDER BY p.id
    `, [stateAbbrev]);
    statewideRows = swRows;
  }

  // Third query: PostGIS intersection for US House (NATIONAL_LOWER) reps
  // whose congressional district boundary (G5200) intersects the given county boundary (G4020).
  // Only runs when countyGeoId is provided — zero impact on existing callers.
  let congressionalRows: typeof rows = [];
  if (countyGeoId) {
    const { rows: cdRows } = await pool.query<Record<string, unknown>>(`
      SELECT DISTINCT ON (p.id)
             p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
             p.preferred_name, p.name_suffix, p.party,
             COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
             p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
             COALESCE(p.valid_from, '') AS term_start,
             COALESCE(p.valid_to, '') AS term_end,
             COALESCE(p.term_date_precision, '') AS term_date_precision,
             COALESCE(p.appointment_date::text, '') AS appointment_date,
             o.title AS office_title, o.representing_state, o.representing_city,
             o.is_appointed_position, o.is_vacant, o.vacant_since,
             p.is_appointed, o.faces_retention_vote,
             d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
             ch.name AS chamber_name, ch.name_formal AS chamber_name_formal,
             ch.election_frequency, ch.policy_engagement_level,
             g.name AS government_name, g.type AS government_type,
             COALESCE(gvb.display_name, '') AS government_body_name,
             COALESCE(gvb.website_url, '') AS government_body_url,
             COALESCE(ch.website_url, '') AS chamber_url
      FROM essentials.geofence_boundaries county_gb
      JOIN essentials.geofence_boundaries cd_gb
        ON public.ST_Intersects(county_gb.geometry, cd_gb.geometry)
       AND cd_gb.mtfcc IN ('G5200', 'G5210', 'G5220')
      JOIN essentials.districts d
        ON d.geo_id = cd_gb.geo_id
       AND d.mtfcc = cd_gb.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.politicians p ON p.id = o.politician_id AND p.is_active = true
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
      LEFT JOIN essentials.governments g ON g.id = ch.government_id
      LEFT JOIN essentials.government_bodies gvb
        ON gvb.state = d.state
       AND gvb.geo_id = d.geo_id
       AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
      WHERE county_gb.geo_id = $1
        AND county_gb.mtfcc = 'G4020'
      ORDER BY p.id
    `, [countyGeoId]);
    congressionalRows = cdRows;
  }

  // Merge and deduplicate by politician ID
  const seen = new Set<string>();
  const allRows = [...rows, ...statewideRows, ...congressionalRows].filter((r) => {
    const id = r.id as string;
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  });

  const politicians: PoliticianFlatRecord[] = allRows.map((row) => ({
    id: row.id as string,
    external_id: row.external_id != null ? Number(row.external_id) : null,
    first_name: row.first_name as string ?? '',
    middle_initial: row.middle_initial as string ?? '',
    last_name: row.last_name as string ?? '',
    preferred_name: row.preferred_name as string ?? '',
    name_suffix: row.name_suffix as string ?? '',
    full_name: row.full_name as string ?? '',
    party: row.party as string ?? '',
    photo_origin_url: row.photo_origin_url as string ?? '',
    web_form_url: row.web_form_url as string ?? '',
    urls: row.urls as string[] ?? null,
    email_addresses: row.email_addresses as string[] ?? null,
    office_title: row.office_title as string ?? '',
    representing_state: row.representing_state as string ?? '',
    representing_city: row.representing_city as string ?? '',
    district_type: row.district_type as string ?? '',
    district_label: row.district_label as string ?? '',
    district_id: row.district_id as string ?? '',
    geo_id: row.geo_id as string ?? '',
    mtfcc: row.mtfcc as string ?? '',
    chamber_name: row.chamber_name as string ?? '',
    chamber_name_formal: row.chamber_name_formal as string ?? '',
    government_name: row.government_name as string ?? '',
    government_body_name: row.government_body_name as string ?? '',
    government_body_url: row.government_body_url as string ?? '',
    chamber_url: row.chamber_url as string ?? '',
    government_type: row.government_type as string ?? '',
    is_elected: !(row.is_appointed_position as boolean),
    is_appointed: row.is_appointed as boolean ?? false,
    faces_retention_vote: row.faces_retention_vote as boolean ?? false,
    election_frequency: row.election_frequency as string ?? '',
    policy_engagement_level: (row.policy_engagement_level as 'full' | 'record_only' | 'none') ?? 'full',
    committees: [],
    bio_text: row.bio_text as string ?? null,
    slug: row.slug as string ?? null,
    is_incumbent: row.is_incumbent as boolean ?? false,
    term_start: row.term_start as string ?? '',
    term_end: row.term_end as string ?? '',
    term_date_precision: row.term_date_precision as string ?? '',
    appointment_date: row.appointment_date as string ?? '',
    office_description: '',
    next_primary_date: '',
    next_general_date: '',
    images: [],
    is_vacant: row.is_vacant as boolean ?? false,
    vacant_since: row.vacant_since as string ?? '',
  }));

  // Attach images
  if (politicians.length > 0) {
    const ids = politicians.map((p) => p.id);
    const { rows: imgRows } = await pool.query(
      `SELECT id, politician_id, url, type, COALESCE(photo_license, '') AS photo_license, focal_point FROM essentials.politician_images WHERE politician_id = ANY($1)`,
      [ids]
    );
    const imageMap = new Map<string, Array<{ id: string; url: string; type: string; photo_license: string; focal_point: string | null }>>();
    for (const r of imgRows) {
      const pid = r.politician_id as string;
      if (!imageMap.has(pid)) imageMap.set(pid, []);
      imageMap.get(pid)!.push({ id: r.id as string, url: r.url, type: r.type, photo_license: r.photo_license, focal_point: (r.focal_point as string) ?? null });
    }
    for (const p of politicians) p.images = imageMap.get(p.id) ?? [];
  }

  return politicians;
}

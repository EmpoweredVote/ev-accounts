/**
 * districtQueries — the shared SQL text for every "who holds office here" lookup.
 *
 * WHY THIS FILE IS SEPARATE FROM essentialsService.ts:
 * these are PURE STRING BUILDERS with no import that touches the environment, so
 * they are unit-testable. essentialsService.ts pulls in ./db.js, which validates
 * env vars at import time and process.exits when they are absent — importing it
 * from a unit test kills the whole run. Same reasoning as geoIdGuard.ts.
 *
 * The column list and join chain below previously existed in FOUR near-identical
 * copies inside essentialsService.ts (the point path's district query and its
 * statewide query, getRepresentativesByJurisdiction, getLocalOfficialsByUserId).
 * They are one copy now, because the MTFCC-to-district_type mapping is
 * load-bearing and must stay in step with MTFCC_DISTRICT_TYPE_GUARD in
 * geoIdGuard.ts — four hand-synced copies is three chances to drift.
 *
 * NONE of these strings may ever interpolate request input. Callers compose
 * predicates from code-authored SQL only; user values arrive as $n bind params.
 */

import { FALLBACK_EXCLUDED_MTFCC_SQL_LIST } from './geoIdGuard.js';

/**
 * Next primary/general date per office, as a lateral so a politician with no
 * upcoming race still returns a row.
 */
export const UPCOMING_ELECTIONS_LATERAL = `
  LEFT JOIN LATERAL (
    SELECT
      MIN(CASE WHEN e.election_type = 'primary' THEN e.election_date END)::text AS next_primary_date,
      MIN(CASE WHEN e.election_type = 'general' THEN e.election_date END)::text AS next_general_date
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = p.id
    WHERE e.election_date >= CURRENT_DATE
      -- The candidate_status = 'active' test is stricter than the shared predicate (it also
      -- excludes 'filed'); kept as-is. is_live_candidate adds the not_nominated rule (mig 1582).
      AND (r.office_id = o.id OR (rc.politician_id IS NOT NULL
                                  AND rc.candidate_status = 'active'
                                  AND essentials.is_live_candidate(rc.candidate_status, rc.result)))
  ) upcoming ON true
`;

/** Politician/office/district column list. Callers add layer-specific columns
 *  (e.g. `gb.name AS geofence_name`) via buildDistrictQuery's extraSelect. */
export const DISTRICT_SELECT_FIELDS = `
    DISTINCT ON (COALESCE(p.id, o.id))
    p.id, p.external_id, p.full_name, p.first_name, p.last_name, p.middle_initial,
    p.preferred_name, p.name_suffix, p.party,
    COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url,
    p.web_form_url, p.urls, p.email_addresses, p.bio_text, p.slug, p.is_incumbent,
    p.finance_summary,
    COALESCE(p.valid_from, '') AS term_start,
    COALESCE(p.valid_to, '') AS term_end,
    COALESCE(p.term_date_precision, '') AS term_date_precision,
    COALESCE(p.appointment_date::text, '') AS appointment_date,
    o.title AS office_title, o.representing_state, o.representing_city,
    o.voting_powers, o.representation_note,
    o.is_appointed_position, o.is_vacant, o.vacant_since,
    p.is_appointed, o.faces_retention_vote,
    d.district_type, d.label AS district_label, d.district_id, d.geo_id, d.mtfcc,
    ch.name AS chamber_name, ch.name_formal AS chamber_name_formal, ch.election_frequency,
    ch.policy_engagement_level,
    g.name AS government_name,
    g.type AS government_type,
    COALESCE(gvb.display_name, '') AS government_body_name,
    COALESCE(gvb.website_url, '') AS government_body_url,
    COALESCE(ch.website_url, '') AS chamber_url,
    upcoming.next_primary_date, upcoming.next_general_date
`;

/** offices -> current holder -> chamber/government joins, shared by every
 *  district query. Expects essentials.districts aliased `d`. */
export const DISTRICT_JOINS = `
    JOIN essentials.offices o ON o.district_id = d.id
    -- ADR 0002: occupant resolved at QUERY TIME via essentials.office_current_holder, so a term
    -- with a future term_start takes effect on its own date with nothing scheduled. Exactly one
    -- row per office — office_terms' exclusion constraint makes two concurrent occupants
    -- impossible — so this cannot fan the result set out.
    -- Phase 5 dropped offices.politician_id, so office_terms is now the ONLY source of occupancy.
    -- That also closed the old dual-read gap where a term ending with no successor kept reporting
    -- the expired holder; such a seat now correctly reads as vacant.
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state
      AND gvb.geo_id = d.geo_id
      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
    ${UPCOMING_ELECTIONS_LATERAL}
`;

/**
 * geofence_boundaries -> districts join, with the MTFCC-to-district_type mapping
 * that prevents cross-layer matching (SLDU vs SLDL, county vs legislative).
 *
 * KEEP IN STEP WITH MTFCC_DISTRICT_TYPE_GUARD in src/lib/geoIdGuard.ts.
 */
export const GEOFENCE_DISTRICT_JOIN = `
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
      AND (
        -- MTFCC-to-district_type mapping prevents cross-matching (e.g., SLDU vs SLDL)
        (gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')
        OR (gb.mtfcc = 'G5220' AND d.district_type = 'STATE_LOWER')
        -- DC ONLY: TIGER files DC's 8 wards as the SLDL layer (G5220, geo_id 11001..11008) because
        -- the DC Council IS DC's legislature. Its ward seats are typed CITY_COUNCIL and the SBOE's
        -- STATE_BOARD_EDUCATION (migration 1852 reclassified DC's board from SCHOOL_BOARD), so
        -- without this all 16 stay unreachable by address (migrations 1485, 1852).
        -- SCOPED TO DC deliberately — unscoped, another state's state-house geofence could match a
        -- same-geo_id council district and surface the wrong officials.
        -- Keep in step with MTFCC_DISTRICT_TYPE_GUARD in src/lib/geoIdGuard.ts.
        OR (gb.mtfcc = 'G5220' AND lower(d.state) = 'dc' AND d.district_type IN ('CITY_COUNCIL','STATE_BOARD_EDUCATION'))
        OR (gb.mtfcc = 'G5200' AND d.district_type = 'NATIONAL_LOWER')
        OR (gb.mtfcc = 'G4020' AND d.district_type IN ('COUNTY', 'JUDICIAL'))
        -- PR ONLY: a municipio IS both the county-equivalent and the municipality. TIGER files all
        -- 78 in the county layer (G4020), but their executive is an alcalde, so they are typed
        -- LOCAL_EXEC like every other mayor (migration 1728). SCOPED TO PR deliberately — G4020
        -- geo_ids are state-FIPS-prefixed, so 72xxx belongs to Puerto Rico alone.
        -- Keep in step with MTFCC_DISTRICT_TYPE_GUARD in src/lib/geoIdGuard.ts.
        OR (gb.mtfcc = 'G4020' AND lower(d.state) = 'pr' AND d.district_type = 'LOCAL_EXEC')
        OR (gb.mtfcc = 'G4040' AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
        OR (gb.mtfcc IN ('G4110', 'G4120') AND d.district_type IN ('LOCAL', 'LOCAL_EXEC'))
        OR (gb.mtfcc IN ('G5400', 'G5410', 'G5420') AND d.district_type = 'SCHOOL')
        OR (gb.mtfcc = 'X0001' AND d.district_type IN ('LOCAL', 'COUNTY'))
        OR (gb.mtfcc = 'X0002' AND d.district_type = 'SCHOOL')
        OR (gb.mtfcc = 'X0003' AND d.district_type = 'STATE_BOARD_EDUCATION')
        -- X0004 (tribal) does NOT join to districts in v1; surfaced via tribal_land response field
        -- X0029: appellate districts whose geometry is a union of whole counties and so has no TIGER
        -- layer of its own — Indiana Court of Appeals Districts 1-3 (migration 1832). EXPLICIT here
        -- and in MTFCC_DISTRICT_TYPE_GUARD; the two must stay in step, and the X catch-all in
        -- geoIdGuard.ts does NOT admit JUDICIAL, so relying on a catch-all would leave these
        -- reachable through this join but UNREACHABLE to check-address-reachability.mjs.
        OR (gb.mtfcc = 'X0029' AND d.district_type = 'JUDICIAL')
        OR (gb.mtfcc LIKE 'X%' AND gb.mtfcc NOT IN ('X0001','X0002','X0003','X0004') AND d.district_type IN ('LOCAL', 'COUNTY', 'JUDICIAL'))
        -- Fallback: if MTFCC not in known set, match any district type for this geo_id.
        -- G5200V26 (2026-vintage congressional boundaries) intentionally excluded: reps feed
        -- stays on G5200; only the elections opt-in join (electionService.ts) may reach V26.
        -- G6350 (ZCTA / ZIP polygons) excluded too: a ZIP has no districts of its own and its
        -- bare 5-digit geo_id can collide with a district geo_id. ZIPs resolve by AREA OVERLAP.
        OR (gb.mtfcc NOT IN (${FALLBACK_EXCLUDED_MTFCC_SQL_LIST})
            AND gb.mtfcc NOT LIKE 'X%')
      )
`;

/** Excludes challenger/placeholder rows unless a caller opts in. */
export const INCUMBENTS_ONLY_CLAUSE =
  "AND COALESCE(p.is_incumbent, true) = true AND COALESCE(o.title, '') NOT ILIKE 'Candidate for%'";

/**
 * buildDistrictQuery — the ONE geofence->districts->officials query, parameterized
 * on its spatial predicate.
 *
 * The point path (ST_Covers against a coordinate) and the area path (overlap
 * against a ZCTA polygon) differ ONLY in that predicate and in a couple of extra
 * select columns. Everything structural — the column list, the MTFCC mapping, the
 * occupancy joins, the active/vacant rule — is shared, so the two cannot drift.
 *
 * `spatialPredicate`, `extraSelect`, `withPrefix` and `orderByTail` are composed
 * by callers from trusted, code-authored SQL ONLY — never from request input. All
 * user-supplied values arrive as $n bind parameters.
 */
export function buildDistrictQuery(opts: {
  withPrefix?: string;
  extraSelect?: string;
  spatialPredicate: string;
  orderByTail?: string;
  includeChallengers?: boolean;
}): string {
  const {
    withPrefix = '',
    extraSelect = '',
    spatialPredicate,
    orderByTail = '',
    includeChallengers = false,
  } = opts;
  return `
    ${withPrefix}
    SELECT ${DISTRICT_SELECT_FIELDS}
           ${extraSelect}
    ${GEOFENCE_DISTRICT_JOIN}
    ${DISTRICT_JOINS}
    WHERE ${spatialPredicate}
    AND (p.is_active = true OR o.is_vacant = true)
    ${includeChallengers ? '' : INCUMBENTS_ONLY_CLAUSE}
    ORDER BY COALESCE(p.id, o.id)${orderByTail}
  `;
}

/**
 * buildStatewideQuery — officials elected by a whole state (President/VP,
 * Senators, Governor and other state executives, state supreme/appellate courts).
 *
 * $1 = state abbreviation. Not geofenced: a statewide seat has no polygon of its
 * own, so it is admitted by district_type + state instead.
 */
export function buildStatewideQuery(): string {
  return `
    SELECT ${DISTRICT_SELECT_FIELDS}
    FROM essentials.districts d
    ${DISTRICT_JOINS}
    WHERE (
      d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', 'NATIONAL_JUDICIAL', 'JUDICIAL')
      -- DC's CITYWIDE seats: Mayor, Attorney General, Council Chairman, the 4 at-large Council
      -- members (all on geo_id 'dc-council-at-large') and the at-large SBOE member. They are
      -- elected by the whole city, exactly like a Governor or state AG, but DC has no STATE_EXEC
      -- district so nothing here admitted them and they were unreachable by address.
      --
      -- KEYED ON THE AT-LARGE geo_ids, NOT on district_type, and that is load-bearing: DC's 8 WARD
      -- seats are also district_type CITY_COUNCIL, so admitting the type would return all eight
      -- ward councilmembers for EVERY DC address — the ward seats already resolve correctly and
      -- individually through the geofence join (migration 1485).
      -- Nor can this key on ocd_id: the at-large SBOE member shares
      -- state:dc/school_district:district_of_columbia with the 8 SBOE ward seats.
      OR (lower(d.state) = 'dc' AND d.geo_id IN ('dc-council-at-large', 'dc-sboe-at-large'))
    )
    AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
    AND (p.is_active = true OR o.is_vacant = true)
    ${INCUMBENTS_ONLY_CLAUSE}
    -- JUDICIAL: a court belongs here only if it is elected by the WHOLE state. The test is whether
    -- the court has geography of its own, NOT how long its geo_id happens to be.
    --
    -- This was a geo_id-LENGTH test — "county courts carry a 5-digit FIPS, everything else is
    -- statewide". That misread every Indiana Court of Appeals district: judges of Districts 1, 2 and 3
    -- stand for retention before THEIR DISTRICT'S voters only, but their geo_ids are 7 characters, so
    -- the length rule returned all of them for every Indiana address — a District 1 judge shown to a
    -- District 3 voter. Only Districts 4 and 5 (at large, one judge from each of the first three) and
    -- the Supreme Court genuinely retain statewide.
    --
    -- The honest test: a JUDICIAL district is statewide iff it has no geofence below the state
    -- outline. G4000 is excluded from the EXISTS because a statewide seat legitimately resolves
    -- against its state outline; any OTHER layer means the court has its own polygon and must be
    -- matched spatially instead (migration 1832 gave Indiana's Districts 1-3 X0029 polygons).
    --
    -- ⚠ d.geo_id IS NOT NULL is load-bearing. ~504 California JUDICIAL rows carry a NULL geo_id;
    -- under the old rule LENGTH(NULL) != 5 is NULL, so they were excluded. Without this clause the
    -- NOT EXISTS would be vacuously TRUE and all 504 would surface on every California address.
    -- Measured against prod: with it, this rule admits exactly the same rows as the old one
    -- (CA 0, IN 16, WI 1); without it, CA jumps 0 -> 504.
    --
    -- Keep in step with STATEWIDE_RESOLVED in scripts/check-address-reachability.mjs.
    AND (
      d.district_type != 'JUDICIAL'
      OR (d.geo_id IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gsw
                           WHERE gsw.geo_id = d.geo_id AND gsw.mtfcc <> 'G4000'))
    )
    ORDER BY COALESCE(p.id, o.id)
  `;
}

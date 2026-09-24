import { pool } from './db.js';
import { MTFCC_DISTRICT_TYPE_GUARD, type GeoPair } from './geoIdGuard.js';
import { getOverlappingGeoIdsForGovernments } from './essentialsBrowseService.js';
import {
  groupElectionRows,
  type ElectionRow,
  type ElectionResult,
} from './electionGrouping.js';

// ANTIPARTISAN RATIONALE: party excluded from candidate records.
// Party context for primary elections lives on the RACE (races.primary_party), never on candidates.
// This enforces Empowered Vote's antipartisan mission at the query layer.

// ---------------------------------------------------------------------------
// Shared SQL fragments — every elections lookup selects the same race/candidate
// columns and applies the same post-election visibility window so results are
// identical regardless of how the matching districts were resolved.
//
// Visibility (UTC-safe):
//   - Primaries / other: 30 days after election_date
//   - General elections: through Dec 31 of the election year (until Jan 1)
// ---------------------------------------------------------------------------

const ELECTION_VISIBILITY_WINDOW = `(
  (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
  OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
)`;

/**
 * Race-level "candidate field is not final yet" date, or NULL.
 *
 * Reads the convention migration 1456 established for
 * essentials.race_candidates.provisional_until: a non-null value means the row is a
 * PRE-RESOLUTION placeholder, and the date is the first day it can be RE-VERIFIED (1456
 * pairs it with the "cull >= <date>" wording in source). ~300 rows across a dozen states
 * carry one; migration 1469 added the Bend/Deschutes cohort.
 *
 * The predicate is 1456's staleness pair with its date clause dropped. 1456's
 * stale_provisional_candidates VIEW answers an ops question — "which rows are OVERDUE for
 * re-verification" — so it requires provisional_until <= CURRENT_DATE. This answers a
 * reader-facing one — "is this field settled" — which is true from the moment the row is
 * seeded, well before the deadline. Same last_verified_at comparison ('<', matching 1456
 * exactly) so both clear on the same event: a re-derive that stamps last_verified_at past
 * provisional_until, or an operator NULLing the flag (what 1457 does). Never on the
 * calendar alone — otherwise a re-check that never happens silently becomes a claim that
 * the field is final.
 *
 * MAX() because a race is provisional until its LAST outstanding row is resolved. Cast to
 * text so node-postgres returns 'YYYY-MM-DD' instead of a local-midnight Date.
 */
const PROVISIONAL_UNTIL = `(
  SELECT MAX(rc2.provisional_until)::text
  FROM essentials.race_candidates rc2
  WHERE rc2.race_id = r.id
    AND rc2.provisional_until IS NOT NULL
    AND (rc2.last_verified_at IS NULL OR rc2.last_verified_at < rc2.provisional_until)
)`;

const RACE_SELECT = `
  e.id           AS election_id,
  e.name         AS election_name,
  e.election_date,
  e.election_type,
  e.jurisdiction_level,
  r.id           AS race_id,
  r.position_name,
  r.primary_party,
  r.seats,
  ${PROVISIONAL_UNTIL} AS provisional_until,
  rc.id          AS candidate_id,
  rc.full_name,
  rc.first_name,
  rc.last_name,
  COALESCE(rc.photo_url, pi.url) AS photo_url,
  rc.is_incumbent,
  rc.candidate_status,
  rc.result,
  COALESCE(rc.is_write_in, false) AS is_write_in,
  rc.politician_id`;

/**
 * The candidates a race's ballot list shows. A `not_nominated` row (mig 1574) ran in the
 * primary and did not become the nominee, so it is not on this race's ballot — mig 1582 took
 * it out of every liveness COUNT but left these lists alone, and they rendered 292 primary
 * losers as active November candidates (2026-09-24). The condition sits in the ON clause, not
 * the WHERE, so a race whose every row is filtered still comes back (with no candidates).
 * Withdrawn rows are kept: the client badges them.
 */
const BALLOT_CANDIDATE_JOIN = `LEFT JOIN essentials.race_candidates rc
        ON rc.race_id = r.id AND rc.result IS DISTINCT FROM 'not_nominated'`;

const PHOTO_LATERAL = `
  LEFT JOIN LATERAL (
    SELECT url FROM essentials.politician_images
    WHERE politician_id = rc.politician_id AND type = 'default'
    LIMIT 1
  ) pi ON rc.politician_id IS NOT NULL`;

/**
 * District-specific races whose office links to a district matching one of the
 * resolved (geo_id, mtfcc) pairs. The MTFCC guard keys off district_type + the
 * geofence MTFCC, so it is robust to unpopulated districts.mtfcc and to the
 * 5-digit GEOID collision (e.g. State House 35 vs Salt Lake County, both 49035).
 */
async function fetchDistrictRaceRows(geoPairs: (GeoPair | null | undefined)[]): Promise<ElectionRow[]> {
  const pairs = geoPairs.filter((p): p is GeoPair => !!p && !!p.geo_id && !!p.mtfcc);
  if (pairs.length === 0) return [];
  const { rows } = await pool.query<ElectionRow>(
    `
      SELECT DISTINCT ${RACE_SELECT},
        d.district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      ${BALLOT_CANDIDATE_JOIN}
      ${PHOTO_LATERAL}
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN unnest($1::text[], $2::text[]) AS gp(geo_id, mtfcc)
        ON gp.geo_id = d.geo_id AND ${MTFCC_DISTRICT_TYPE_GUARD}
      WHERE ${ELECTION_VISIBILITY_WINDOW}
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `,
    [pairs.map((p) => p.geo_id), pairs.map((p) => p.mtfcc)]
  );
  return rows;
}

// District types that are statewide (or nation-wide, surfaced per state): the
// state executives (Governor, Lt. Gov, AG, Sec. of State, Treasurer, Comptroller,
// etc.), US Senate, and President. These are matched by state — never by the
// user's sub-state district stack — so they must appear for every resident.
const STATEWIDE_DISTRICT_TYPES = ['STATE_EXEC', 'NATIONAL_UPPER', 'NATIONAL_EXEC'];

/**
 * Statewide / at-large races for a state — Governor, statewide execs, US Senate,
 * President. State code must be uppercase (elections.state is always uppercase;
 * districts.state is mixed-case 'ut'/'UT').
 *
 * A race qualifies as statewide when EITHER:
 *   - it has no office link (r.office_id IS NULL) — the canonical convention, OR
 *   - its office maps to a statewide district_type (STATE_EXEC / NATIONAL_UPPER /
 *     NATIONAL_EXEC).
 * The second branch makes the feed resilient to races that were seeded WITH an
 * office_id (a recurring ingestion mistake): such a race was previously invisible
 * — skipped here for having an office_id, and skipped by the district/government
 * paths because a whole-state "district" is not in any resident's local stack.
 * Sub-state offices (STATE_LOWER/UPPER, NATIONAL_LOWER, county/local) are
 * deliberately excluded — they remain geography-matched by fetchDistrictRaceRows.
 */
async function fetchStatewideRaceRows(state: string): Promise<ElectionRow[]> {
  const { rows } = await pool.query<ElectionRow>(
    `
      SELECT DISTINCT ${RACE_SELECT},
        NULL::text AS district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      ${BALLOT_CANDIDATE_JOIN}
      ${PHOTO_LATERAL}
      LEFT JOIN essentials.offices o ON o.id = r.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      -- Case-insensitive: not every caller uppercases the state before calling
      -- (e.g. the /elections/me path passes stored jurisdiction_state verbatim).
      WHERE upper(e.state) = upper($1::text)
        AND (
          r.office_id IS NULL
          OR d.district_type = ANY($2::text[])
        )
        AND ${ELECTION_VISIBILITY_WINDOW}
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `,
    [state, STATEWIDE_DISTRICT_TYPES]
  );
  return rows;
}

/**
 * Races whose office links (office → chamber → government) to one of the given
 * government geo_ids. Catches city/township at-large offices that have no
 * geofence/district record and therefore aren't found by geo-pair resolution.
 */
async function fetchGovernmentRaceRows(governmentGeoIds: string[]): Promise<ElectionRow[]> {
  if (governmentGeoIds.length === 0) return [];
  const { rows } = await pool.query<ElectionRow>(
    `
      SELECT DISTINCT ${RACE_SELECT},
        NULL::text AS district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      ${BALLOT_CANDIDATE_JOIN}
      ${PHOTO_LATERAL}
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.chambers ch ON ch.id = o.chamber_id
      JOIN essentials.governments g ON g.id = ch.government_id
      WHERE g.geo_id = ANY($1::text[])
        AND ${ELECTION_VISIBILITY_WINDOW}
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `,
    [governmentGeoIds]
  );
  return rows;
}

export interface CandidateDetail {
  candidate_id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  /** Registered write-in for this race (CA_0279). */
  is_write_in: boolean;
  politician_id: string | null;
  position_name: string;
  election_date: string | null;
  election_type: string | null;
}

/**
 * Returns upcoming elections for an explicit list of government geo_ids.
 *
 * Mirrors the address/area path's full overlapping stack:
 *   - Government-linked races (city/township at-large offices)
 *   - District races resolved from the government geofences (county, school,
 *     state-board, state house/senate, US house) via PostGIS overlap
 *   - Statewide / at-large races (office_id IS NULL) for the resolved state
 *
 * Previously this only returned government-linked races, so curated
 * browse-by-government-list deep links showed "no elections" wherever the
 * upcoming races were district-linked (the common case).
 */
export async function getElectionsByGovernmentGeoIds(
  governmentGeoIds: string[]
): Promise<ElectionResult[]> {
  if (governmentGeoIds.length === 0) return [];

  // Resolve the overlapping district stack + state from the government geofences.
  const { geoPairs, stateAbbrev: geoState } = await getOverlappingGeoIdsForGovernments(governmentGeoIds);

  // Prefer the geofence-derived state; fall back to representing_state on any
  // office for these governments (governments whose boundaries aren't loaded).
  let stateAbbrev = geoState;
  if (!stateAbbrev) {
    const { rows } = await pool.query<{ representing_state: string }>(
      `
        SELECT o.representing_state
        FROM essentials.governments g
        JOIN essentials.chambers ch ON ch.government_id = g.id
        JOIN essentials.offices o ON o.chamber_id = ch.id
        WHERE g.geo_id = ANY($1::text[])
          AND o.representing_state IS NOT NULL
          AND o.representing_state != ''
        LIMIT 1
      `,
      [governmentGeoIds]
    );
    stateAbbrev = rows[0]?.representing_state ?? null;
  }
  // elections.state is uppercase; UT governments are stored as both 'ut' and 'UT'.
  const stateCode = stateAbbrev ? stateAbbrev.toUpperCase() : null;

  const [govtRows, districtRows, statewideRows] = await Promise.all([
    fetchGovernmentRaceRows(governmentGeoIds),
    fetchDistrictRaceRows(geoPairs),
    stateCode ? fetchStatewideRaceRows(stateCode) : Promise.resolve([] as ElectionRow[]),
  ]);

  return groupElectionRows([...govtRows, ...districtRows, ...statewideRows]);
}

/**
 * Fetch a single race candidate by ID, joining race and election context.
 * Returns null for withdrawn candidates or unknown IDs.
 */
export async function getCandidateById(candidateId: string): Promise<CandidateDetail | null> {
  const queryText = `
    SELECT
      rc.id           AS candidate_id,
      rc.full_name,
      rc.first_name,
      rc.last_name,
      COALESCE(rc.photo_url, pi.url) AS photo_url,
      rc.is_incumbent,
      COALESCE(rc.is_write_in, false) AS is_write_in,
      rc.politician_id,
      r.position_name,
      e.election_date::text AS election_date,
      e.election_type
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = rc.politician_id AND type = 'default'
      LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
    WHERE rc.id = $1
      AND essentials.is_live_candidate(rc.candidate_status, rc.result)
  `;
  const { rows } = await pool.query(queryText, [candidateId]);
  return (rows[0] as CandidateDetail) ?? null;
}

/**
 * Returns upcoming elections with races and candidates for a set of stored
 * (geo_id, mtfcc) district pairs.
 *
 * - District races: matched via the MTFCC guard against the pairs
 * - Statewide races (office_id IS NULL): matched by e.state = state
 */
export async function getElectionsByGeoIds(
  geoPairs: (GeoPair | null | undefined)[],
  state: string | null | undefined
): Promise<ElectionResult[]> {
  const [districtRows, statewideRows] = await Promise.all([
    fetchDistrictRaceRows(geoPairs),
    state ? fetchStatewideRaceRows(state) : Promise.resolve([] as ElectionRow[]),
  ]);
  return groupElectionRows([...districtRows, ...statewideRows]);
}

/**
 * Returns upcoming elections with races and candidates for a geographic coordinate.
 *
 * - Part A: geofence-matched district-specific races (US House, State House, etc.)
 * - Part B: statewide/at-large races (Governor, US Senate, etc.) matched by state
 *
 * CRITICAL: PostGIS convention — ST_MakePoint($1, $2) = (longitude, latitude)
 * so $1 = lng, $2 = lat.
 */
export async function getElectionsByCoordinate(lat: number, lng: number): Promise<ElectionResult[]> {
  // Part A: Geofence-matched district-specific races
  // $1 = lng (longitude), $2 = lat (latitude) per PostGIS convention
  const geofenceQueryText = `
    SELECT DISTINCT ${RACE_SELECT},
      d.district_type
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    ${BALLOT_CANDIDATE_JOIN}
    ${PHOTO_LATERAL}
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    -- D-01 dual-map opt-in: prefer the 2026-vintage congressional geometry
    -- (mtfcc = 'G5200V26') for a NATIONAL_LOWER geo_id when one exists, else
    -- fall back to the current-vintage branch. States with no G5200V26 rows
    -- fall straight through — zero blast radius until 2026 polygons land.
    JOIN LATERAL (
      SELECT geometry FROM essentials.geofence_boundaries gbv
       WHERE gbv.geo_id = d.geo_id AND gbv.mtfcc = 'G5200V26'
         AND d.district_type = 'NATIONAL_LOWER'
      UNION ALL
      SELECT geometry FROM essentials.geofence_boundaries gbo
       WHERE gbo.geo_id = d.geo_id
         AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gbo.mtfcc = d.mtfcc)
         AND NOT EXISTS (
           SELECT 1 FROM essentials.geofence_boundaries x
            WHERE x.geo_id = d.geo_id AND x.mtfcc = 'G5200V26'
         )
      LIMIT 1
    ) gb ON true
    WHERE gb.geometry IS NOT NULL
      AND ST_Covers(
        gb.geometry,
        ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
      )
      AND ${ELECTION_VISIBILITY_WINDOW}
    ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
  `;

  // Part B: State code lookup — determine the state from the geofence-matched
  // districts. districts.state is dirty: for a single covering point it can hold
  // the 2-letter USPS code ('CA'/'ca'), the 2-digit FIPS code ('06'), and 'US'
  // (the national layer) all at once. The old `DISTINCT ... LIMIT 1` had no
  // ORDER BY, so it non-deterministically returned e.g. '06', which matches no
  // elections.state and silently dropped every statewide race (Governor, etc.).
  // Take the DOMINANT proper 2-letter alpha code, ignoring FIPS and 'US'.
  const stateQueryText = `
    SELECT upper(d.state) AS state
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
    WHERE ST_Covers(
      gb.geometry,
      ST_SetSRID(ST_MakePoint($1::float8, $2::float8), 4326)
    )
    AND d.state ~ '^[A-Za-z]{2}$'
    AND upper(d.state) <> 'US'
    GROUP BY upper(d.state)
    ORDER BY count(*) DESC, upper(d.state)
    LIMIT 1
  `;

  const [geofenceResult, stateResult] = await Promise.all([
    pool.query<ElectionRow>(geofenceQueryText, [lng, lat]),
    pool.query<{ state: string }>(stateQueryText, [lng, lat]),
  ]);

  // Already uppercased in SQL; keep the guard defensive. elections.state is
  // always uppercase, so this is the value Part B matches on.
  const stateCode = stateResult.rows[0]?.state?.toUpperCase() ?? null;

  const statewideRows = stateCode ? await fetchStatewideRaceRows(stateCode) : [];

  return groupElectionRows([...geofenceResult.rows, ...statewideRows]);
}

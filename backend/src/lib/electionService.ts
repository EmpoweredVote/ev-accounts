import { pool } from './db.js';

// ANTIPARTISAN RATIONALE: party excluded from candidate records.
// Party context for primary elections lives on the RACE (races.primary_party), never on candidates.
// This enforces Empowered Vote's antipartisan mission at the query layer.

interface ElectionCandidate {
  candidate_id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  candidate_status: string;
  politician_id: string | null;
}

interface ElectionRace {
  race_id: string;
  position_name: string;
  primary_party: string | null;
  seats: number;
  district_type: string | null;
  candidates: ElectionCandidate[];
}

interface ElectionResult {
  election_id: string;
  election_name: string;
  election_date: string;
  election_type: string;
  jurisdiction_level: string;
  races: ElectionRace[];
}

// Row type returned from SQL queries
interface ElectionRow {
  election_id: string;
  election_name: string;
  election_date: Date | string;
  election_type: string;
  jurisdiction_level: string;
  race_id: string;
  position_name: string;
  primary_party: string | null;
  seats: number;
  district_type: string | null;
  candidate_id: string | null;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean | null;
  candidate_status: string | null;
  politician_id: string | null;
}

/**
 * Infer district_type from position_name when office_id is not linked.
 * Falls back to jurisdiction_level-based mapping.
 */
function inferDistrictType(positionName: string, jurisdictionLevel: string): string | null {
  const p = positionName.toLowerCase();

  // Federal
  if (p.includes('united states representative') || p.includes('u.s. representative') || p.includes('u.s. house'))
    return 'NATIONAL_LOWER';
  if (p.includes('united states senator') || p.includes('u.s. senator') || p.includes('u.s. senate'))
    return 'NATIONAL_UPPER';
  if (p.includes('president'))
    return 'NATIONAL_EXEC';

  // State
  if (p.includes('state representative') || p.includes('state house') || p.includes('state assembly'))
    return 'STATE_LOWER';
  if (p.includes('state senator') || p.includes('state senate'))
    return 'STATE_UPPER';
  if (p.includes('governor') || p.includes('lieutenant governor'))
    return 'STATE_EXEC';
  // State constitutional officers — must precede LOCAL catch-all, which also matches
  // 'treasurer', 'commissioner', 'clerk', 'auditor', 'assessor', etc.
  if (p.includes('attorney general') ||
      p.includes('secretary of state') ||
      p.includes('state treasurer') ||
      p.includes('state controller') ||
      p.includes('state comptroller') ||
      p.includes('state auditor') ||
      p.includes('insurance commissioner') ||
      p.includes('superintendent of public instruction') ||
      p.includes('superintendent of schools'))
    return 'STATE_EXEC';

  // Local
  if (p.includes('mayor'))
    return 'LOCAL_EXEC';
  if (p.includes('council') || p.includes('commissioner') || p.includes('trustee') || p.includes('clerk') || p.includes('auditor') || p.includes('treasurer') || p.includes('assessor') || p.includes('recorder') || p.includes('coroner') || p.includes('sheriff') || p.includes('surveyor') || p.includes('prosecutor'))
    return 'LOCAL';
  if (p.includes('county'))
    return 'COUNTY';
  if (p.includes('school') || p.includes('education'))
    return 'SCHOOL';
  if (p.includes('judge') || p.includes('justice'))
    return 'JUDICIAL';

  // Fallback: jurisdiction_level
  const levelMap: Record<string, string> = {
    federal: 'NATIONAL_EXEC',
    state: 'STATE_EXEC',
    local: 'LOCAL_EXEC',
  };
  return levelMap[jurisdictionLevel] ?? null;
}

export interface CandidateDetail {
  candidate_id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  politician_id: string | null;
  position_name: string;
  election_date: string | null;
  election_type: string | null;
}

/**
 * Returns upcoming elections for an explicit list of government geo_ids.
 * Joins through governments → chambers → offices → races → elections,
 * bypassing the geofence/district infrastructure.
 */
export async function getElectionsByGovernmentGeoIds(
  governmentGeoIds: string[]
): Promise<ElectionResult[]> {
  if (governmentGeoIds.length === 0) return [];

  const districtQueryText = `
    SELECT DISTINCT
      e.id           AS election_id,
      e.name         AS election_name,
      e.election_date,
      e.election_type,
      e.jurisdiction_level,
      r.id           AS race_id,
      r.position_name,
      r.primary_party,
      r.seats,
      rc.id          AS candidate_id,
      rc.full_name,
      rc.first_name,
      rc.last_name,
      COALESCE(rc.photo_url, pi.url) AS photo_url,
      rc.is_incumbent,
      rc.candidate_status,
      rc.politician_id,
      NULL::text AS district_type
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = rc.politician_id AND type = 'default'
      LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    WHERE g.geo_id = ANY($1::text[])
      AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
    ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
  `;

  const stateQueryText = `
    SELECT o.representing_state
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    WHERE g.geo_id = ANY($1::text[])
      AND o.representing_state IS NOT NULL
      AND o.representing_state != ''
    LIMIT 1
  `;

  const [districtResult, stateResult] = await Promise.all([
    pool.query<ElectionRow>(districtQueryText, [governmentGeoIds]),
    pool.query<{ representing_state: string }>(stateQueryText, [governmentGeoIds]),
  ]);

  const districtRows = districtResult.rows;
  const stateAbbrev = stateResult.rows[0]?.representing_state ?? null;

  let statewideRows: ElectionRow[] = [];
  if (stateAbbrev) {
    const statewideQueryText = `
      SELECT DISTINCT
        e.id           AS election_id,
        e.name         AS election_name,
        e.election_date,
        e.election_type,
        e.jurisdiction_level,
        r.id           AS race_id,
        r.position_name,
        r.primary_party,
        r.seats,
        rc.id          AS candidate_id,
        rc.full_name,
        rc.first_name,
        rc.last_name,
        COALESCE(rc.photo_url, pi.url) AS photo_url,
        rc.is_incumbent,
        rc.candidate_status,
        rc.politician_id,
        NULL::text AS district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
      LEFT JOIN LATERAL (
        SELECT url FROM essentials.politician_images
        WHERE politician_id = rc.politician_id AND type = 'default'
        LIMIT 1
      ) pi ON rc.politician_id IS NOT NULL
      WHERE r.office_id IS NULL
        AND e.state = $1
        AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `;
    const result = await pool.query<ElectionRow>(statewideQueryText, [stateAbbrev]);
    statewideRows = result.rows;
  }

  const allRows = [...districtRows, ...statewideRows];
  const seenCandidates = new Set<string>();
  const dedupedRows = allRows.filter((row) => {
    if (row.candidate_id !== null) {
      if (seenCandidates.has(row.candidate_id)) return false;
      seenCandidates.add(row.candidate_id);
    }
    return true;
  });

  if (dedupedRows.length === 0) return [];

  const electionsMap = new Map<string, ElectionResult>();
  const racesMap = new Map<string, ElectionRace>();

  for (const row of dedupedRows) {
    const electionDate =
      row.election_date instanceof Date
        ? row.election_date.toISOString().split('T')[0]
        : String(row.election_date).split('T')[0];

    if (!electionsMap.has(row.election_id)) {
      electionsMap.set(row.election_id, {
        election_id: row.election_id,
        election_name: row.election_name,
        election_date: electionDate,
        election_type: row.election_type,
        jurisdiction_level: row.jurisdiction_level,
        races: [],
      });
    }

    if (!racesMap.has(row.race_id)) {
      const race: ElectionRace = {
        race_id: row.race_id,
        position_name: row.position_name,
        primary_party: row.primary_party,
        seats: row.seats,
        district_type: row.district_type,
        candidates: [],
      };
      racesMap.set(row.race_id, race);
      electionsMap.get(row.election_id)!.races.push(race);
    }

    if (row.candidate_id !== null) {
      racesMap.get(row.race_id)!.candidates.push({
        candidate_id: row.candidate_id,
        full_name: row.full_name!,
        first_name: row.first_name,
        last_name: row.last_name,
        photo_url: row.photo_url,
        is_incumbent: row.is_incumbent!,
        candidate_status: row.candidate_status!,
        politician_id: row.politician_id,
      });
    }
  }

  for (const election of electionsMap.values()) {
    for (const race of election.races) {
      if (!race.district_type) {
        race.district_type = inferDistrictType(race.position_name, election.jurisdiction_level);
      }
    }
  }

  return Array.from(electionsMap.values()).sort((a, b) =>
    a.election_date.localeCompare(b.election_date)
  );
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
      AND rc.candidate_status != 'withdrawn'
  `;
  const { rows } = await pool.query(queryText, [candidateId]);
  return (rows[0] as CandidateDetail) ?? null;
}

/**
 * Returns upcoming elections with races and candidates for a set of stored district GEO IDs.
 *
 * Used by GET /essentials/elections/me — avoids coordinate decryption by querying
 * directly against the stored geo_ids on connected_profiles.
 *
 * - District races: matched by d.geo_id = ANY(geoIds)
 * - Statewide races (office_id IS NULL): matched by e.state = state
 */
export async function getElectionsByGeoIds(
  geoIds: (string | null | undefined)[],
  state: string | null | undefined
): Promise<ElectionResult[]> {
  const activeGeoIds = geoIds.filter((g): g is string => !!g);

  let districtRows: ElectionRow[] = [];

  if (activeGeoIds.length > 0) {
    const districtQueryText = `
      SELECT DISTINCT
        e.id           AS election_id,
        e.name         AS election_name,
        e.election_date,
        e.election_type,
        e.jurisdiction_level,
        r.id           AS race_id,
        r.position_name,
        r.primary_party,
        r.seats,
        rc.id          AS candidate_id,
        rc.full_name,
        rc.first_name,
        rc.last_name,
        COALESCE(rc.photo_url, pi.url) AS photo_url,
        rc.is_incumbent,
        rc.candidate_status,
        rc.politician_id,
        d.district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      LEFT JOIN essentials.race_candidates rc
        ON rc.race_id = r.id
      LEFT JOIN LATERAL (
        SELECT url FROM essentials.politician_images
        WHERE politician_id = rc.politician_id AND type = 'default'
        LIMIT 1
      ) pi ON rc.politician_id IS NOT NULL
      JOIN essentials.offices o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE d.geo_id = ANY($1::text[])
        AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `;
    const result = await pool.query<ElectionRow>(districtQueryText, [activeGeoIds]);
    districtRows = result.rows;
  }

  let statewideRows: ElectionRow[] = [];
  if (state) {
    const statewideQueryText = `
      SELECT DISTINCT
        e.id           AS election_id,
        e.name         AS election_name,
        e.election_date,
        e.election_type,
        e.jurisdiction_level,
        r.id           AS race_id,
        r.position_name,
        r.primary_party,
        r.seats,
        rc.id          AS candidate_id,
        rc.full_name,
        rc.first_name,
        rc.last_name,
        COALESCE(rc.photo_url, pi.url) AS photo_url,
        rc.is_incumbent,
        rc.candidate_status,
        rc.politician_id,
        NULL::text AS district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      LEFT JOIN essentials.race_candidates rc
        ON rc.race_id = r.id
      LEFT JOIN LATERAL (
        SELECT url FROM essentials.politician_images
        WHERE politician_id = rc.politician_id AND type = 'default'
        LIMIT 1
      ) pi ON rc.politician_id IS NOT NULL
      WHERE r.office_id IS NULL
        AND e.state = $1
        AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `;
    const result = await pool.query<ElectionRow>(statewideQueryText, [state]);
    statewideRows = result.rows;
  }

  const allRows = [...districtRows, ...statewideRows];
  const seenCandidates = new Set<string>();
  const dedupedRows = allRows.filter((row) => {
    if (row.candidate_id !== null) {
      if (seenCandidates.has(row.candidate_id)) return false;
      seenCandidates.add(row.candidate_id);
    }
    return true;
  });

  if (dedupedRows.length === 0) return [];

  const electionsMap = new Map<string, ElectionResult>();
  const racesMap = new Map<string, ElectionRace>();

  for (const row of dedupedRows) {
    const electionDate =
      row.election_date instanceof Date
        ? row.election_date.toISOString().split('T')[0]
        : String(row.election_date).split('T')[0];

    if (!electionsMap.has(row.election_id)) {
      electionsMap.set(row.election_id, {
        election_id: row.election_id,
        election_name: row.election_name,
        election_date: electionDate,
        election_type: row.election_type,
        jurisdiction_level: row.jurisdiction_level,
        races: [],
      });
    }

    if (!racesMap.has(row.race_id)) {
      const race: ElectionRace = {
        race_id: row.race_id,
        position_name: row.position_name,
        primary_party: row.primary_party,
        seats: row.seats,
        district_type: row.district_type,
        candidates: [],
      };
      racesMap.set(row.race_id, race);
      electionsMap.get(row.election_id)!.races.push(race);
    }

    if (row.candidate_id !== null) {
      racesMap.get(row.race_id)!.candidates.push({
        candidate_id: row.candidate_id,
        full_name: row.full_name!,
        first_name: row.first_name,
        last_name: row.last_name,
        photo_url: row.photo_url,
        is_incumbent: row.is_incumbent!,
        candidate_status: row.candidate_status!,
        politician_id: row.politician_id,
      });
    }
  }

  for (const election of electionsMap.values()) {
    for (const race of election.races) {
      if (!race.district_type) {
        race.district_type = inferDistrictType(race.position_name, election.jurisdiction_level);
      }
    }
  }

  return Array.from(electionsMap.values()).sort((a, b) =>
    a.election_date.localeCompare(b.election_date)
  );
}

/**
 * Returns upcoming elections with races and candidates for a geographic coordinate.
 *
 * Uses two complementary queries:
 * - Part A: geofence-matched races (district-specific: US House, State House, etc.)
 * - Part B: statewide/at-large races (Governor, US Senate, etc.) matched by state code
 *
 * CRITICAL: PostGIS convention — ST_MakePoint($1, $2) = (longitude, latitude)
 * so $1 = lng, $2 = lat
 *
 * Withdrawn candidates are excluded from all results.
 * Post-election visibility windows (UTC-safe):
 * - Primaries / other: 30 days after election_date
 * - General elections: through Dec 31 of the election year (until Jan 1)
 */
export async function getElectionsByCoordinate(lat: number, lng: number): Promise<ElectionResult[]> {
  // Part A: Geofence-matched district-specific races
  // Joins through: geofence_boundaries -> districts -> offices -> races -> elections
  // $1 = lng (longitude), $2 = lat (latitude) per PostGIS convention
  const geofenceQueryText = `
    SELECT DISTINCT
      e.id           AS election_id,
      e.name         AS election_name,
      e.election_date,
      e.election_type,
      e.jurisdiction_level,
      r.id           AS race_id,
      r.position_name,
      r.primary_party,
      r.seats,
      rc.id          AS candidate_id,
      rc.full_name,
      rc.first_name,
      rc.last_name,
      COALESCE(rc.photo_url, pi.url) AS photo_url,
      rc.is_incumbent,
      rc.candidate_status,
      rc.politician_id,
      d.district_type
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    LEFT JOIN essentials.race_candidates rc
      ON rc.race_id = r.id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = rc.politician_id AND type = 'default'
      LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries gb
      ON gb.geo_id = d.geo_id
      AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
    WHERE gb.geometry IS NOT NULL
      AND public.ST_Covers(
        gb.geometry,
        public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
      )
      AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
    ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
  `;

  // Part B: State code lookup — determine state from any geofence-matched district
  const stateQueryText = `
    SELECT DISTINCT d.state
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
    WHERE public.ST_Covers(
      gb.geometry,
      public.ST_SetSRID(public.ST_MakePoint($1::float8, $2::float8), 4326)
    )
    AND d.state IS NOT NULL
    LIMIT 1
  `;

  // Execute Part A and state lookup in parallel
  const [geofenceResult, stateResult] = await Promise.all([
    pool.query<ElectionRow>(geofenceQueryText, [lng, lat]),
    pool.query<{ state: string }>(stateQueryText, [lng, lat]),
  ]);

  const stateCode = stateResult.rows[0]?.state ?? null;

  // Part B: Statewide/at-large races (office_id IS NULL) for the matched state
  // These are races for positions like Governor, US Senator that span the whole state
  let statewideRows: ElectionRow[] = [];
  if (stateCode) {
    const statewideQueryText = `
      SELECT DISTINCT
        e.id           AS election_id,
        e.name         AS election_name,
        e.election_date,
        e.election_type,
        e.jurisdiction_level,
        r.id           AS race_id,
        r.position_name,
        r.primary_party,
        r.seats,
        rc.id          AS candidate_id,
        rc.full_name,
        rc.first_name,
        rc.last_name,
        COALESCE(rc.photo_url, pi.url) AS photo_url,
        rc.is_incumbent,
        rc.candidate_status,
        rc.politician_id,
        NULL::text AS district_type
      FROM essentials.elections e
      JOIN essentials.races r ON r.election_id = e.id
      LEFT JOIN essentials.race_candidates rc
        ON rc.race_id = r.id
      LEFT JOIN LATERAL (
        SELECT url FROM essentials.politician_images
        WHERE politician_id = rc.politician_id AND type = 'default'
        LIMIT 1
      ) pi ON rc.politician_id IS NOT NULL
      WHERE r.office_id IS NULL
        AND e.state = $1
        AND (
        (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
        OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
      )
      ORDER BY e.election_date, r.position_name, rc.is_incumbent DESC
    `;
    const statewideResult = await pool.query<ElectionRow>(statewideQueryText, [stateCode]);
    statewideRows = statewideResult.rows;
  }

  // Merge Part A + Part B, deduplicate by candidate_id
  const allRows = [...geofenceResult.rows, ...statewideRows];
  const seenCandidates = new Set<string>();
  const dedupedRows = allRows.filter((row) => {
    if (row.candidate_id !== null) {
      if (seenCandidates.has(row.candidate_id)) return false;
      seenCandidates.add(row.candidate_id);
    }
    return true;
  });

  if (dedupedRows.length === 0) {
    return [];
  }

  // Group: elections -> races -> candidates
  const electionsMap = new Map<string, ElectionResult>();
  const racesMap = new Map<string, ElectionRace>();

  for (const row of dedupedRows) {
    // Normalize election_date to ISO date string (YYYY-MM-DD)
    const electionDate =
      row.election_date instanceof Date
        ? row.election_date.toISOString().split('T')[0]
        : String(row.election_date).split('T')[0];

    if (!electionsMap.has(row.election_id)) {
      electionsMap.set(row.election_id, {
        election_id: row.election_id,
        election_name: row.election_name,
        election_date: electionDate,
        election_type: row.election_type,
        jurisdiction_level: row.jurisdiction_level,
        races: [],
      });
    }

    if (!racesMap.has(row.race_id)) {
      const race: ElectionRace = {
        race_id: row.race_id,
        position_name: row.position_name,
        primary_party: row.primary_party,
        seats: row.seats,
        district_type: row.district_type,
        candidates: [],
      };
      racesMap.set(row.race_id, race);
      electionsMap.get(row.election_id)!.races.push(race);
    }

    if (row.candidate_id !== null) {
      const candidate: ElectionCandidate = {
        candidate_id: row.candidate_id,
        full_name: row.full_name!,
        first_name: row.first_name,
        last_name: row.last_name,
        photo_url: row.photo_url,
        is_incumbent: row.is_incumbent!,
        candidate_status: row.candidate_status!,
        politician_id: row.politician_id,
      };
      racesMap.get(row.race_id)!.candidates.push(candidate);
    }
  }

  // Post-process: derive synthetic district_type for races without office_id link.
  // Infers from position_name first (more accurate), falls back to jurisdiction_level.
  for (const election of electionsMap.values()) {
    for (const race of election.races) {
      if (!race.district_type) {
        race.district_type = inferDistrictType(race.position_name, election.jurisdiction_level);
      }
    }
  }

  // Return elections sorted by election_date ascending
  return Array.from(electionsMap.values()).sort((a, b) =>
    a.election_date.localeCompare(b.election_date)
  );
}

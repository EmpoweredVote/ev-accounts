/**
 * Pure (DB-free) election grouping + district-type inference.
 *
 * Extracted from electionService so the row→ElectionResult[] grouping can be
 * unit-tested without a database connection, and shared by every elections
 * lookup (by-coordinate, by-geo-ids, by-government-list) so they group and sort
 * identically.
 */

export interface ElectionCandidate {
  candidate_id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  candidate_status: string;
  /**
   * Outcome of this race for this candidate, or null when not yet recorded (mig 1574).
   * 'not_nominated' means they did not become the nominee — the API already excludes those
   * from every liveness count via essentials.is_live_candidate (mig 1582), but the field is
   * passed through so clients can render a finished race without re-querying.
   */
  result: string | null;
  politician_id: string | null;
}

export interface ElectionRace {
  race_id: string;
  position_name: string;
  primary_party: string | null;
  seats: number;
  district_type: string | null;
  /**
   * Set when this race's candidate field is not yet final: the first date it can be
   * re-verified (ISO 'YYYY-MM-DD'), per the race_candidates.provisional_until
   * convention from migration 1456. Non-null only while the field is ALSO still
   * unverified (see PROVISIONAL_UNTIL in electionService), so it clears on
   * re-verification rather than on the calendar. Clients render an advisory note;
   * null means "field presented as final".
   */
  provisional_until: string | null;
  candidates: ElectionCandidate[];
}

export interface ElectionResult {
  election_id: string;
  election_name: string;
  election_date: string;
  election_type: string;
  jurisdiction_level: string;
  races: ElectionRace[];
}

/** Row shape returned from the election SQL queries. */
export interface ElectionRow {
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
  /** ISO date string ('YYYY-MM-DD') or null — cast to text in SQL so pg does not hand back a Date. */
  provisional_until: string | null;
  candidate_id: string | null;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean | null;
  candidate_status: string | null;
  result: string | null;
  politician_id: string | null;
}

/**
 * Infer district_type from position_name when office_id is not linked.
 * Falls back to jurisdiction_level-based mapping.
 */
export function inferDistrictType(positionName: string, jurisdictionLevel: string): string | null {
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
  // State Board of Education — elected by district but a state-level body. Must precede
  // the SCHOOL catch-all below, whose 'education'/'school' match would pull these into
  // the Local tier (matches essentials.districts.district_type = 'STATE_BOARD_EDUCATION',
  // the dedicated education type; migration 1852 reclassified STATE_BOARD/SCHOOL_BOARD into it).
  // 'sboe' covers DC's "SBOE Member (Ward N)" title style; the two long forms cover Utah's.
  if (p.includes('state board of education') || p.includes('state school board') || p.includes('sboe'))
    return 'STATE_BOARD_EDUCATION';

  // Local
  if (p.includes('mayor'))
    return 'LOCAL_EXEC';
  if (p.includes('council') || p.includes('commissioner') || p.includes('trustee') || p.includes('clerk') || p.includes('auditor') || p.includes('treasurer') || p.includes('assessor') || p.includes('recorder') || p.includes('coroner') || p.includes('sheriff') || p.includes('surveyor') || p.includes('prosecutor') || p.includes('controller') || (p.includes('attorney') && !p.includes('attorney general') && !p.includes('county')))
    return 'LOCAL';
  if (p.includes('county') || p.includes('supervisor'))
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
    county: 'COUNTY',
  };
  return levelMap[jurisdictionLevel] ?? null;
}

/**
 * Group flat election rows into elections → races → candidates.
 *
 * - Deduplicates candidates by (race_id, candidate_id) so a candidate surfaced
 *   by more than one source query (e.g. district + statewide) appears once.
 * - Keeps races whose candidate_id is null (LEFT JOIN, no declared candidates).
 * - Derives a synthetic district_type via inferDistrictType for races whose row
 *   carries none (office_id-unlinked / statewide races).
 * - Returns elections sorted by election_date ascending.
 */
export function groupElectionRows(rows: ElectionRow[]): ElectionResult[] {
  const seenCandidates = new Set<string>();
  const dedupedRows = rows.filter((row) => {
    if (row.candidate_id !== null) {
      const key = `${row.race_id}:${row.candidate_id}`;
      if (seenCandidates.has(key)) return false;
      seenCandidates.add(key);
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
        provisional_until: row.provisional_until ?? null,
        candidates: [],
      };
      racesMap.set(row.race_id, race);
      electionsMap.get(row.election_id)!.races.push(race);
    }

    if (row.candidate_id !== null) {
      racesMap.get(row.race_id)!.candidates.push({
        candidate_id: row.candidate_id,
        full_name: row.full_name ?? '',
        first_name: row.first_name,
        last_name: row.last_name,
        photo_url: row.photo_url,
        is_incumbent: row.is_incumbent ?? false,
        candidate_status: row.candidate_status ?? 'unknown',
        result: row.result ?? null,
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

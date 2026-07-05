export type MapLevel = 'county' | 'local' | 'school';
export type Metric = 'completeness' | 'elections';

export interface StateScore {
  fips: string; code: string; name: string; score: number;
  jurisdiction_count: number; populated_count: number;
  breadth: number; depth: number;
  counties_started: number; counties_total: number;
  cities_started: number; cities_total: number;
  schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number;
}

export interface JurisdictionScore {
  ocd_id: string; name: string; level: MapLevel; county_fips: string | null;
  score: number; populated: boolean; roster_actual: number; expected_seats: number | null;
  headshots: { withPhoto: number; total: number }; stances: { researched: number; total: number };
  donors_n: { withDonors: number; total: number };
  geofenced: boolean; treasury: 'none' | 'partial' | 'full'; donors: 'none' | 'partial' | 'full';
}

export interface CountyScore {
  fips: string; name: string; score: number;
  jurisdiction_count: number; populated_count: number; jurisdictions: JurisdictionScore[];
  breadth: number; depth: number; county_govt_started: boolean;
  cities_started: number; cities_total: number; schools_started: number; schools_total: number;
  roster_pct: number; stances_pct: number; photo_pct: number; donors_pct: number;
  treasury: 'none' | 'partial' | 'full';
}

export interface ElectionRace { race_id: string; position_name: string; seats: number; candidate_count: number; ocd_id: string | null; tier: 0 | 1 | 2 | 3; }
export interface StateElection {
  fips: string; code: string; election_date: string; election_type: string;
  coverage: number; races_total: number; races_covered: number;
  // Weighted 3-tier depth score (D-04) over statewide/legislative races, 0..100.
  depthScore: number;
  // Per-tier tallies over the same statewide/legislative race set.
  tierCounts: { t0: number; t1: number; t2: number; t3: number };
  countyCoverage: { status: 'unknown' | 'scored'; coverage: number; races_total: number; races_covered: number };
  statewideRaces: ElectionRace[];
}
export interface CountyElection { fips: string; name: string; status: 'unknown' | 'scored'; coverage: number; races: ElectionRace[]; }

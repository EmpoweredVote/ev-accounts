import { describe, it, expect } from 'vitest';
import { groupElectionRows, inferDistrictType, type ElectionRow } from './electionGrouping.js';

const row = (over: Partial<ElectionRow> = {}): ElectionRow => ({
  election_id: 'e1',
  election_name: 'Test Election',
  election_date: '2026-06-23',
  election_type: 'primary',
  jurisdiction_level: 'state',
  race_id: 'r1',
  position_name: 'State Representative District 24',
  primary_party: null,
  seats: 1,
  district_type: null,
  provisional_until: null,
  candidate_id: 'c1',
  full_name: 'Jane Doe',
  first_name: 'Jane',
  last_name: 'Doe',
  photo_url: null,
  is_incumbent: false,
  candidate_status: 'active',
  result: null,
  politician_id: null,
  ...over,
});

describe('groupElectionRows', () => {
  it('groups rows into elections → races → candidates', () => {
    const out = groupElectionRows([
      row({ candidate_id: 'c1', full_name: 'Jane Doe' }),
      row({ candidate_id: 'c2', full_name: 'John Roe' }),
    ]);
    expect(out).toHaveLength(1);
    expect(out[0].races).toHaveLength(1);
    expect(out[0].races[0].candidates.map((c) => c.full_name)).toEqual(['Jane Doe', 'John Roe']);
  });

  it('deduplicates a candidate that appears in the same race twice (district + statewide overlap)', () => {
    const out = groupElectionRows([
      row({ race_id: 'r1', candidate_id: 'c1' }),
      row({ race_id: 'r1', candidate_id: 'c1' }),
    ]);
    expect(out[0].races[0].candidates).toHaveLength(1);
  });

  it('carries provisional_until onto the race, defaulting to null', () => {
    const out = groupElectionRows([
      row({ race_id: 'r1', candidate_id: 'c1', provisional_until: '2026-08-28' }),
      row({ race_id: 'r2', candidate_id: 'c2', position_name: 'Mayor' }),
    ]);
    const byId = Object.fromEntries(out[0].races.map((r) => [r.race_id, r.provisional_until]));
    expect(byId).toEqual({ r1: '2026-08-28', r2: null });
  });

  it('keeps a race with no candidates (LEFT JOIN null candidate_id)', () => {
    const out = groupElectionRows([row({ candidate_id: null, full_name: null })]);
    expect(out[0].races).toHaveLength(1);
    expect(out[0].races[0].candidates).toHaveLength(0);
  });

  it('infers district_type from position_name when the row has none', () => {
    const out = groupElectionRows([row({ district_type: null, position_name: 'State Representative District 24' })]);
    expect(out[0].races[0].district_type).toBe('STATE_LOWER');
  });

  it('preserves an explicit district_type from the row', () => {
    const out = groupElectionRows([row({ district_type: 'SCHOOL', position_name: 'Board Member' })]);
    expect(out[0].races[0].district_type).toBe('SCHOOL');
  });

  it('sorts elections by date ascending', () => {
    const out = groupElectionRows([
      row({ election_id: 'late', race_id: 'rl', election_date: '2026-11-03' }),
      row({ election_id: 'early', race_id: 're', election_date: '2026-06-23' }),
    ]);
    expect(out.map((e) => e.election_id)).toEqual(['early', 'late']);
  });

  it('normalizes a Date election_date to YYYY-MM-DD', () => {
    const out = groupElectionRows([row({ election_date: new Date('2026-06-23T00:00:00Z') })]);
    expect(out[0].election_date).toBe('2026-06-23');
  });

  it('returns [] for no rows', () => {
    expect(groupElectionRows([])).toEqual([]);
  });
});

describe('inferDistrictType', () => {
  it('maps US House / Senate / President', () => {
    expect(inferDistrictType('United States Representative', 'federal')).toBe('NATIONAL_LOWER');
    expect(inferDistrictType('U.S. Senator', 'federal')).toBe('NATIONAL_UPPER');
    expect(inferDistrictType('President of the United States', 'federal')).toBe('NATIONAL_EXEC');
  });
  it('maps state legislature + governor', () => {
    expect(inferDistrictType('State Senator', 'state')).toBe('STATE_UPPER');
    expect(inferDistrictType('State Representative', 'state')).toBe('STATE_LOWER');
    expect(inferDistrictType('Governor', 'state')).toBe('STATE_EXEC');
  });
  it('classifies State Board of Education as STATE_BOARD_EDUCATION before SCHOOL catch-all', () => {
    expect(inferDistrictType('State Board of Education District 4', 'state')).toBe('STATE_BOARD_EDUCATION');
    expect(inferDistrictType('SBOE Member (Ward 4)', 'state')).toBe('STATE_BOARD_EDUCATION');
  });
  it('maps local + county + school', () => {
    expect(inferDistrictType('Mayor', 'local')).toBe('LOCAL_EXEC');
    expect(inferDistrictType('City Council Member', 'local')).toBe('LOCAL');
    expect(inferDistrictType('County Commissioner', 'county')).toBe('LOCAL');
    expect(inferDistrictType('School Board Member', 'local')).toBe('SCHOOL');
  });
});

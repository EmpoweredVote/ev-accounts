import { describe, it, expect } from 'vitest';
import {
  identifyFederal, identifyRollCalls, identifyState, parsePrinted, parseRosterTsv, pickSessionList, splitFull,
  type RosterPerson, type SessionList,
} from './identityMatch.js';

// Every name here is invented.
const list = (members: string[], session = '87th Legislature (2021)', state = 'TX'): SessionList => ({
  state, chamber: 'house', session, source_url: 'https://example.org/members', members: members.map((full_name) => ({ full_name })),
});
const person = (id: string, full_name: string, over: Partial<RosterPerson> = {}): RosterPerson => ({
  id, full_name, state: 'TX', level: 'state', chamber: 'house', ...over,
});

describe('names', () => {
  it('splits "Last, First" and drops suffixes and middle initials', () => {
    expect(splitFull('Hunter, Todd')).toMatchObject({ first: 'todd', last: 'hunter' });
    expect(splitFull('Todd A. Hunter Jr.')).toMatchObject({ first: 'todd', last: 'hunter' });
  });
  it('reads initials, a state hint and a two-word surname', () => {
    expect(parsePrinted('Smith, J.')).toEqual({ surname: 'smith', initials: ['j'], stateHint: null });
    expect(parsePrinted('Smith (TX)')).toEqual({ surname: 'smith', initials: [], stateHint: 'TX' });
    expect(parsePrinted('Martinez Fischer').surname).toBe('martinez fischer');
  });
});

describe('identifyState', () => {
  it('does not link a 2021 member to a different current member with the same surname (the false link)', () => {
    const r = identifyState('Taylor', list(['Van Taylor', 'Ann Brooks']), [person('p1', 'Lynn Taylor')]);
    expect(r.grade).toBe('not-in-roster');
    expect(r.politician_id).toBeUndefined();
    expect(r.session_name).toBe('Van Taylor');
  });

  it('leaves a session member who fits two roster people unlinked', () => {
    const r = identifyState('Garcia', list(['Maria Garcia']), [person('p1', 'Maria Garcia'), person('p2', 'Mariana Garcia')]);
    expect(r.grade).toBe('ambiguous');
    expect(r.politician_id).toBeUndefined();
    expect(r.roster_candidates).toHaveLength(2);
  });

  it('narrows two same-surname session members by the printed initial, then confirms', () => {
    const roster = [person('p1', 'Dana Price'), person('p2', 'Robert Price')];
    const r = identifyState('Price, R.', list(['Dana Price', 'Robert Price']), roster);
    expect(r).toMatchObject({ grade: 'confirmed', politician_id: 'p2' });
    expect(identifyState('Price', list(['Dana Price', 'Robert Price']), roster).grade).toBe('ambiguous');
  });

  it('accepts a quoted nickname as first-name agreement', () => {
    const r = identifyState('Moss', list(['William "Bill" Moss']), [person('p1', 'Bill Moss')]);
    expect(r).toMatchObject({ grade: 'confirmed', politician_id: 'p1' });
  });

  it('refuses when no member list covers the vote year', () => {
    expect(pickSessionList([list(['A B'], '2015 session')], 'TX', 'house', '2021-05-01')).toBeNull();
    expect(identifyState('B', null, []).grade).toBe('no-session-list');
  });
});

describe('identifyFederal', () => {
  const roster = [
    person('f1', 'Pat Smith', { state: 'TX', level: 'federal', term_start: '2025-01-03' }),
    person('f2', 'Lee Smith', { state: 'OH', level: 'federal', term_start: '2019-01-03' }),
  ];
  it('uses the printed state and refuses a vote cast before the current term', () => {
    const r = identifyFederal('Smith (TX)', 'house', '2024-07-10', roster);
    expect(r.grade).toBe('prior-service');
    expect(r.politician_id).toBeUndefined();
    expect(identifyFederal('Smith (OH)', 'house', '2024-07-10', roster)).toMatchObject({ grade: 'confirmed', politician_id: 'f2' });
    expect(identifyFederal('Smith', 'house', '2024-07-10', roster).grade).toBe('ambiguous');
  });
});

describe('identifyRollCalls', () => {
  it('tallies confirmed names by vote', () => {
    const [rc] = identifyRollCalls(
      [{ instrument_id: 'TX-SB-1-2021', state: 'TX', chamber: 'house', date: '2021-08-31', motion: 'final', yea_names: ['Price, R.'], nay_names: ['Taylor'], other_names: [] }],
      [list(['Robert Price', 'Van Taylor'])],
      [person('p2', 'Robert Price'), person('p1', 'Lynn Taylor')],
    );
    expect(rc.tally).toEqual({ 'confirmed:yea': 1, 'not-in-roster': 1 });
  });
});

describe('parseRosterTsv', () => {
  it('parses by header and rejects a bad level', () => {
    const ok = parseRosterTsv('id\tfull_name\tstate\tlevel\tchamber\np1\tA B\ttx\tstate\tHouse\n', 'r.tsv');
    expect(ok[0]).toEqual({ id: 'p1', full_name: 'A B', state: 'TX', level: 'state', chamber: 'house' });
    expect(() => parseRosterTsv('id\tfull_name\tstate\tlevel\np1\tA B\tTX\tcity\n', 'r.tsv')).toThrow(/line 2: level/);
  });
});

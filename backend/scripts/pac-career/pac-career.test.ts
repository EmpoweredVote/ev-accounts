import { describe, expect, it } from 'vitest';
import { classify, nameKey, verdictOf } from './pac-career.js';

describe('classify', () => {
  it('reads FEC committee codes into the ruled buckets', () => {
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'C' })).toBe('corporate'); // Cummins Inc. PAC
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'T' })).toBe('corporate'); // trade association
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'W' })).toBe('corporate');
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'L' })).toBe('other_pac'); // labor
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'M' })).toBe('other_pac'); // membership
    expect(classify({ tp: 'Q', dsgn: 'D', org: '' })).toBe('other_pac'); // leadership PAC
    expect(classify({ tp: 'N', dsgn: 'U', org: '' })).toBe('other_pac'); // nonconnected
    expect(classify({ tp: 'S', dsgn: 'P', org: '' })).toBe('candidate'); // another senator's campaign
    expect(classify({ tp: 'N', dsgn: 'A', org: '' })).toBe('candidate'); // authorized committee
    expect(classify({ tp: 'Y', dsgn: 'U', org: '' })).toBe('party');
    expect(classify(undefined)).toBe('unknown');
    expect(classify({ tp: '', dsgn: '', org: '' })).toBe('unknown');
  });
});

describe('nameKey', () => {
  it('matches the same person across a House id and a Senate id', () => {
    expect(nameKey('MURPHY, CHRISTOPHER S')).toEqual(nameKey('MURPHY, CHRISTOPHER SCOTT MR.'));
    expect(nameKey('MURPHY, CHRISTOPHER SCOTT MR.')).toEqual({ last: 'MURPHY', first: 'CHRISTOPHER' });
  });
  it('does not match a different first name', () => {
    expect(nameKey('MURPHY, CHRIS')).not.toEqual(nameKey('MURPHY, CHRISTOPHER'));
  });
});

describe('verdictOf', () => {
  const base = { career: { receipts: 100, first_cycle: 2020, last_cycle: 2024, through: '2024-12-31' }, unreconciled: [] as number[] };
  const kept = (k: Partial<Record<'corporate' | 'other_pac' | 'candidate' | 'party' | 'unknown', number>>) =>
    ({ corporate: 0, other_pac: 0, candidate: 0, party: 0, unknown: 0, ...k });
  it('a refunded corporate gift nets to none', () => {
    expect(verdictOf({ ...base, kept: kept({ corporate: 0, other_pac: 5000 }) })).toBe('NO_CORPORATE_PAC_MONEY');
  });
  it('money from other candidates alone is not PAC money', () => {
    expect(verdictOf({ ...base, kept: kept({ candidate: 2000 }) })).toBe('NO_PAC_MONEY');
  });
  it('never claims "none" over an unreconciled cycle or an unclassified gift', () => {
    expect(verdictOf({ ...base, unreconciled: [2018], kept: kept({}) })).toBe('UNVERIFIED');
    expect(verdictOf({ ...base, kept: kept({ unknown: 1 }) })).toBe('UNVERIFIED');
  });
  it('kept corporate money wins over everything', () => {
    expect(verdictOf({ ...base, unreconciled: [2018], kept: kept({ corporate: 1 }) })).toBe('TOOK_CORPORATE_PAC_MONEY');
  });
});

import { lastKeptCycle, partyByName } from './pac-career.js';

describe('lastKeptCycle', () => {
  it('a refund cancels the newest gift first (Murphy: Cummins 2018 kept, 2024 refunded in 2026)', () => {
    const ev = new Map([['C00377952', [{ cycle: 2018, amt: 2000 }, { cycle: 2024, amt: 3000 }, { cycle: 2026, amt: -3000 }]]]);
    expect(lastKeptCycle(ev)).toBe(2018);
  });
  it('fully refunded means none', () => {
    expect(lastKeptCycle(new Map([['X', [{ cycle: 2024, amt: 1000 }, { cycle: 2024, amt: -1000 }]]]))).toBeNull();
  });
});

describe('partyByName', () => {
  it('reads unregistered local party committees', () => {
    expect(partyByName('SOUTHBURY DEMOCRATS')).toBe(true);
    expect(partyByName('DEMOCRATIC TOWN COMMITTEE OF AVON')).toBe(true);
    expect(partyByName('LINCOLN COUNTY REPUBLICAN PARTY')).toBe(true);
  });
  it('does not swallow PACs or firms', () => {
    expect(partyByName('ROBINSON & COLE, LLP')).toBe(false);
    expect(partyByName('COALITION FOR FAMILY SECURITY')).toBe(false);
    expect(partyByName('LATINO CITIZENS FOR RESPECT')).toBe(false);
  });
});

import { describe, expect, it } from 'vitest';
import { classify, nameKey, verdictOf, parseFiling, namesToBuckets, normName, committeeKindAt } from './pac-career.js';

describe('classify', () => {
  it('reads FEC committee codes into the ruled buckets', () => {
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'C' })).toBe('corporate'); // Cummins Inc. PAC
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'T' })).toBe('trade'); // trade association
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'V' })).toBe('coop'); // Dairy Farmers of America
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'W' })).toBe('corporate'); // State Farm Mutual
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
  const kept = (k: Partial<Record<'corporate' | 'trade' | 'coop' | 'other_pac' | 'candidate' | 'party' | 'unknown', number>>) =>
    ({ corporate: 0, trade: 0, coop: 0, other_pac: 0, candidate: 0, party: 0, unknown: 0, ...k });
  it('a refunded corporate gift nets to none', () => {
    expect(verdictOf({ ...base, kept: kept({ corporate: 0, other_pac: 5000 }) })).toBe('NO_CORPORATE_PAC_MONEY');
    // trade-group and co-op money is shown, but is not company PAC money
    expect(verdictOf({ ...base, kept: kept({ trade: 24090, coop: 3250 }) })).toBe('NO_CORPORATE_PAC_MONEY');
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

describe('parseFiling', () => {
  const FS = '\x1c';
  const row = (n: number, set: Record<number, string>) => Array.from({ length: n }, (_, i) => set[i] ?? '').join(FS);
  const sa = (amt: string, id: string, memo = '') => row(45, { 0: 'SA11C', 5: 'PAC', 6: 'ACME PAC', 20: amt, 25: id, 42: memo });
  const sb = (amt: string, id: string) => row(44, { 0: 'SB20C', 5: 'PAC', 6: 'ACME PAC', 20: amt, 24: id });
  const v8 = ['HDR', 'FEC', '8.5', 'X'].join(FS);

  it('reads PAC gifts and refunds by their v8 positions', () => {
    const rows = parseFiling([v8, sa('5000.00', 'c00000001'), sb('1000.00', 'C00000002'), row(45, { 0: 'SA11AI', 20: '50' })].join('\n'));
    expect(rows).toEqual([
      { line: 'SA11C', amt: 5000, id: 'C00000001', name: 'ACME PAC' },
      { line: 'SB20C', amt: 1000, id: 'C00000002', name: 'ACME PAC' },
    ]);
  });

  it('skips memo rows, which are not money received', () => {
    expect(parseFiling([v8, sa('2500', 'C1', 'X'), sa('100', 'C2')].join('\n'))!.map((r) => r.amt)).toEqual([100]);
  });

  it('refuses a pre-v8 file rather than guessing its columns', () => {
    expect(parseFiling(['HDR', 'FEC', '6.4'].join(FS) + '\n' + sa('5000', 'C1'))).toBeNull();
  });
});

describe('namesToBuckets', () => {
  it('maps a registered name to its bucket after normalising punctuation and case', () => {
    const m = namesToBuckets([{ name: 'IBEW PAC Voluntary Fund', tp: 'Q', dsgn: 'B', org: 'L' }]);
    expect(m.get(normName('Ibew PAC, Voluntary Fund'))).toBe('other_pac');
  });
  it('drops a name shared by committees of different kinds', () => {
    const m = namesToBuckets([
      { name: 'EUREKA PAC', tp: 'Q', dsgn: 'B', org: 'C' },
      { name: 'Eureka PAC', tp: 'Q', dsgn: 'U', org: 'L' },
    ]);
    expect(m.has('EUREKA PAC')).toBe(false);
  });
});

describe('committeeKindAt', () => {
  const at = (org: string) => new Map([['C1', { name: 'X PAC', tp: 'Q', dsgn: 'B', org }]]);
  it('outvotes a one-year coding slip in the gift year', () => {
    // NEA Fund shape: labor either side, corporation in the gift year.
    const m = new Map([[2020, at('L')], [2022, at('L')], [2024, at('C')], [2026, at('L')]]);
    expect(committeeKindAt(m, 'C1', 2024)).toBe('other_pac');
  });
  it('keeps a lasting change of code, even against a long earlier history', () => {
    // Trial lawyers shape: trade group through 2022, membership group from 2024.
    const m = new Map([[2016, at('T')], [2018, at('T')], [2020, at('T')], [2022, at('T')], [2024, at('M')], [2026, at('M')]]);
    expect(committeeKindAt(m, 'C1', 2024)).toBe('other_pac');
  });
  it('keeps the newest code when there is no later year to contradict it', () => {
    // Freethought shape: corporation through 2024, membership group in 2026.
    const m = new Map([[2022, at('C')], [2024, at('C')], [2026, at('M')]]);
    expect(committeeKindAt(m, 'C1', 2026)).toBe('other_pac');
  });
  it('falls back to the nearest listed cycle outside the window', () => {
    expect(committeeKindAt(new Map([[2010, at('C')]]), 'C1', 2026)).toBe('corporate');
  });
});

import { describe, expect, it } from 'vitest';
import {
  classify, committeeKindAt, computeCareer, giverKeyOf, lastKeptCycle, parseFiling, partyByName, reconciles,
  reportKeyOf, sumByGiver, type KindsByCommittee, type PersonInput,
} from './pacCareer.js';

describe('classify', () => {
  it('reads FEC committee codes into the ruled kinds (2026-11-18: corporate is C and W only)', () => {
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'C' })).toBe('corporate'); // Cummins Inc. PAC
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'W' })).toBe('corporate');
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'T' })).toBe('trade');
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'V' })).toBe('coop');
    expect(classify({ tp: 'Q', dsgn: 'B', org: 'L' })).toBe('other_pac'); // labor
    expect(classify({ tp: 'Q', dsgn: 'D', org: '' })).toBe('other_pac'); // leadership PAC
    expect(classify({ tp: 'S', dsgn: 'P', org: '' })).toBe('candidate');
    expect(classify({ tp: 'N', dsgn: 'A', org: '' })).toBe('candidate');
    expect(classify({ tp: 'Y', dsgn: 'U', org: '' })).toBe('party');
    expect(classify(undefined)).toBe('unknown');
    expect(classify({ tp: '', dsgn: '', org: '' })).toBe('unknown');
  });
});

const kindsOf = (id: string, byCycle: [number, string][]): KindsByCommittee =>
  new Map([[id, new Map(byCycle.map(([c, org]) => [c, { tp: 'Q', dsgn: 'B', org }]))]]);

describe('committeeKindAt', () => {
  it('outvotes a one-cycle slip (NEA Fund: labor 2022 and 2026, corporation 2024)', () => {
    expect(committeeKindAt(kindsOf('C1', [[2022, 'L'], [2024, 'C'], [2026, 'L']]), 'C1', 2024)).toBe('other_pac');
  });
  it('keeps a lasting change', () => {
    expect(committeeKindAt(kindsOf('C1', [[2020, 'T'], [2022, 'T'], [2024, 'M'], [2026, 'M']]), 'C1', 2024)).toBe('other_pac');
    expect(committeeKindAt(kindsOf('C1', [[2020, 'T'], [2022, 'T'], [2024, 'M'], [2026, 'M']]), 'C1', 2022)).toBe('trade');
  });
  it('uses the nearest listed cycle, the later on a tie', () => {
    expect(committeeKindAt(kindsOf('C1', [[2010, 'C']]), 'C1', 2026)).toBe('corporate');
    expect(committeeKindAt(kindsOf('C1', [[2020, 'C'], [2024, 'L']]), 'C1', 2022)).toBe('other_pac');
  });
  it('knows nothing about an unlisted committee', () => {
    expect(committeeKindAt(new Map(), 'C1', 2024)).toBeUndefined();
  });
});

describe('lastKeptCycle', () => {
  it('a refund cancels the newest gift first (Murphy: Cummins 2018 kept, 2024 refunded in 2026)', () => {
    expect(lastKeptCycle(new Map([['C00377952', [{ cycle: 2018, amt: 2000 }, { cycle: 2024, amt: 3000 }, { cycle: 2026, amt: -3000 }]]]))).toBe(2018);
  });
  it('fully refunded means none', () => {
    expect(lastKeptCycle(new Map([['X', [{ cycle: 2024, amt: 1000 }, { cycle: 2024, amt: -1000 }]]]))).toBeNull();
  });
});

describe('partyByName', () => {
  it('reads unregistered local party committees, and not firms', () => {
    expect(partyByName('SOUTHBURY DEMOCRATS')).toBe(true);
    expect(partyByName('DEMOCRATIC TOWN COMMITTEE OF AVON')).toBe(true);
    expect(partyByName('ROBINSON & COLE, LLP')).toBe(false);
  });
});

describe('reconciles', () => {
  it('allows $1 or 0.5%, whichever is larger', () => {
    expect(reconciles(100, 100.99)).toBe(true);
    expect(reconciles(100, 101.5)).toBe(false);
    expect(reconciles(1_000_000, 1_004_000)).toBe(true);
    expect(reconciles(1_000_000, 1_006_000)).toBe(false);
  });
});

describe('parseFiling', () => {
  const FS = '\x1c';
  const row = (n: number, set: Record<number, string>) => Array.from({ length: n }, (_, i) => set[i] ?? '').join(FS);
  const v8 = ['HDR', 'FEC', '8.3', 'X'].join(FS);
  const f3 = (form = 'F3N', l11c = '6000.00', l20c = '1000.00') =>
    row(95, { 0: form, 1: 'C00492645', 11: 'Q3', 15: '20180701', 16: '20180930', 36: l11c, 53: l20c });
  const sa = (amt: string, id: string, memo = '') => row(45, { 0: 'SA11C', 6: 'ACME PAC', 20: amt, 25: id, 42: memo });
  const sb = (amt: string, id: string) => row(44, { 0: 'SB20C', 6: 'ACME PAC', 20: amt, 24: id });

  it('reads the summary page and the itemized gifts and refunds', () => {
    const p = parseFiling([v8, f3(), sa('5000.00', 'c00000001'), sa('1000', ''), sb('1000.00', 'C00000002'), row(45, { 0: 'SA11AI', 20: '50' })].join('\n'))!;
    expect(p).toMatchObject({ committeeId: 'C00492645', form: 'F3N', reportType: 'Q3', coverageStart: '2018-07-01', coverageEnd: '2018-09-30', cycle: 2018, line11cTotal: 6000, line20cTotal: 1000 });
    expect(p.rows).toEqual([
      { line: 'SA11C', amt: 5000, id: 'C00000001', name: 'ACME PAC' },
      { line: 'SA11C', amt: 1000, id: '', name: 'ACME PAC' },
      { line: 'SB20C', amt: 1000, id: 'C00000002', name: 'ACME PAC' },
    ]);
    expect(reportKeyOf(p)).toBe('Q3|2018-07-01|2018-09-30');
  });
  it('an amendment keys to the same report as its original', () => {
    const a = parseFiling([v8, f3('F3A')].join('\n'))!;
    const n = parseFiling([v8, f3('F3N')].join('\n'))!;
    expect(reportKeyOf(a)).toBe(reportKeyOf(n));
  });
  it('skips memo rows', () => {
    expect(parseFiling([v8, f3(), sa('2500', 'C00000001', 'X'), sa('100', 'C00000002')].join('\n'))!.rows.map((r) => r.amt)).toEqual([100]);
  });
  it('refuses a pre-v8 file and a non-campaign form', () => {
    expect(parseFiling([['HDR', 'FEC', '6.4'].join(FS), f3()].join('\n'))).toBeNull();
    expect(parseFiling([v8, row(10, { 0: 'F3XN', 1: 'C00000009' })].join('\n'))).toBeNull();
  });
});

describe('sumByGiver', () => {
  it('sums per committee id, falls back to the name, and keeps refunds apart', () => {
    const s = sumByGiver([
      { refund: false, amt: 1000, id: 'C00000001', name: 'A PAC' },
      { refund: false, amt: 500, id: 'C00000001', name: 'A PAC' },
      { refund: true, amt: 500, id: 'C00000001', name: 'A PAC' },
      { refund: false, amt: 250, id: '', name: 'Southbury Democrats' },
    ]);
    expect(s).toEqual([
      { giverKey: 'C00000001', giverId: 'C00000001', giverName: 'A PAC', received: 1500, refunded: 500, n: 3 },
      { giverKey: 'NAME:SOUTHBURY DEMOCRATS', giverId: null, giverName: 'Southbury Democrats', received: 250, refunded: 0, n: 1 },
    ]);
    expect(giverKeyOf('bad', 'X')).toBe('NAME:X');
  });
});

describe('computeCareer', () => {
  const CORP = 'C00000001';
  const LABOR = 'C00000002';
  const kinds: KindsByCommittee = new Map([
    [CORP, new Map([[2018, { tp: 'Q', dsgn: 'B', org: 'C' }], [2024, { tp: 'Q', dsgn: 'B', org: 'C' }]])],
    [LABOR, new Map([[2018, { tp: 'Q', dsgn: 'B', org: 'L' }]])],
  ]);
  const base = (over: Partial<PersonInput> = {}): PersonInput => ({
    politicianId: 'p1',
    ids: [{ id: 'S2CT00132', status: 'confirmed', shared: false, totalsFetched: true }],
    totals: [{ id: 'S2CT00132', cycle: 2018, receipts: 100_000, pac: 3000, pacRefunds: 0, coverageEnd: '2018-12-31' }],
    committees: [{ id: 'S2CT00132', cycle: 2018, committeeId: 'C00492645' }],
    reports: [{ committeeId: 'C00492645', reportKey: 'Q3|a|b', cycle: 2018, source: 'efiling', itemized11c: 3000, itemized20c: 0 }],
    gifts: [{ committeeId: 'C00492645', reportKey: 'Q3|a|b', giverKey: LABOR, giverId: LABOR, giverName: 'IBEW', received: 3000, refunded: 0 }],
    ...over,
  });

  it('labor money only: no corporate PAC money, verified', () => {
    const r = computeCareer(base(), kinds);
    expect(r.verdict).toBe('no_corporate_pac');
    expect(r.kept.other_pac).toBe(3000);
    expect(r.cycles[0]).toMatchObject({ cycle: 2018, reconciled: true, source: 'efiling' });
  });

  it('a corporate gift refunded later nets to none (money kept, not money received)', () => {
    const r = computeCareer(base({
      totals: [
        { id: 'S2CT00132', cycle: 2018, receipts: 100_000, pac: 0, pacRefunds: 0, coverageEnd: null },
        { id: 'S2CT00132', cycle: 2024, receipts: 100_000, pac: 3000, pacRefunds: 0, coverageEnd: null },
        { id: 'S2CT00132', cycle: 2026, receipts: 100_000, pac: 0, pacRefunds: 3000, coverageEnd: '2026-09-30' },
      ],
      committees: [{ id: 'S2CT00132', cycle: 2024, committeeId: 'C00492645' }, { id: 'S2CT00132', cycle: 2026, committeeId: 'C00492645' }],
      reports: [
        { committeeId: 'C00492645', reportKey: 'Q1|24', cycle: 2024, source: 'efiling', itemized11c: 3000, itemized20c: 0 },
        { committeeId: 'C00492645', reportKey: 'Q1|26', cycle: 2026, source: 'efiling', itemized11c: 0, itemized20c: 3000 },
      ],
      gifts: [
        { committeeId: 'C00492645', reportKey: 'Q1|24', giverKey: CORP, giverId: CORP, giverName: 'CUMMINS', received: 3000, refunded: 0 },
        { committeeId: 'C00492645', reportKey: 'Q1|26', giverKey: CORP, giverId: CORP, giverName: 'CUMMINS', received: 0, refunded: 3000 },
      ],
    }), kinds);
    expect(r.kept.corporate).toBe(0);
    expect(r.received.corporate).toBe(3000);
    expect(r.verdict).toBe('no_pac');
    expect(r.through).toBe('2026-09-30');
  });

  it('kept corporate money is takes_corporate, even with another cycle unreconciled', () => {
    const r = computeCareer(base({
      totals: [
        { id: 'S2CT00132', cycle: 2018, receipts: 1, pac: 3000, pacRefunds: 0, coverageEnd: null },
        { id: 'S2CT00132', cycle: 2020, receipts: 1, pac: 9999, pacRefunds: 0, coverageEnd: null },
      ],
      gifts: [{ committeeId: 'C00492645', reportKey: 'Q3|a|b', giverKey: CORP, giverId: CORP, giverName: 'X', received: 3000, refunded: 0 }],
    }), kinds);
    expect(r.verdict).toBe('takes_corporate');
    expect(r.lastCorporateCycle).toBe(2018);
    expect(r.why).toEqual(['cycle_unreconciled']);
  });

  it('never claims "none" over an unreconciled cycle', () => {
    const r = computeCareer(base({ totals: [{ id: 'S2CT00132', cycle: 2018, receipts: 1, pac: 5000, pacRefunds: 0, coverageEnd: null }] }), kinds);
    expect(r.verdict).toBe('unverified');
    expect(r.why).toEqual(['cycle_unreconciled']);
    expect(r.cycles[0]).toMatchObject({ fecPac: 5000, itemizedPac: 3000, reconciled: false });
  });

  it('reads a cycle from FEC processed data when the e-filings do not reconcile but it does', () => {
    const r = computeCareer(base({
      reports: [
        { committeeId: 'C00492645', reportKey: 'Q3|a|b', cycle: 2018, source: 'efiling', itemized11c: 1000, itemized20c: 0 },
        { committeeId: 'C00492645', reportKey: 'api:2018', cycle: 2018, source: 'api', itemized11c: 3000, itemized20c: 0 },
      ],
      gifts: [
        { committeeId: 'C00492645', reportKey: 'Q3|a|b', giverKey: CORP, giverId: CORP, giverName: 'X', received: 1000, refunded: 0 },
        { committeeId: 'C00492645', reportKey: 'api:2018', giverKey: LABOR, giverId: LABOR, giverName: 'IBEW', received: 3000, refunded: 0 },
      ],
    }), kinds);
    expect(r.cycles[0]).toMatchObject({ source: 'api', reconciled: true });
    expect(r.kept.corporate).toBe(0);
    expect(r.verdict).toBe('no_corporate_pac');
  });

  it('an unclassifiable giver, an id under review, or never-fetched totals blocks a "none" claim', () => {
    const unknown = computeCareer(base({ gifts: [{ committeeId: 'C00492645', reportKey: 'Q3|a|b', giverKey: 'NAME:FRIENDS OF X', giverId: null, giverName: 'Friends of X', received: 3000, refunded: 0 }] }), kinds);
    expect(unknown).toMatchObject({ verdict: 'unverified', why: ['unknown_giver'] });
    const party = computeCareer(base({ gifts: [{ committeeId: 'C00492645', reportKey: 'Q3|a|b', giverKey: 'NAME:SOUTHBURY DEMOCRATS', giverId: null, giverName: 'Southbury Democrats', received: 3000, refunded: 0 }] }), kinds);
    expect(party.verdict).toBe('no_pac');
    const review = computeCareer(base({ ids: [...base().ids, { id: 'H6CT05124', status: 'needs_review', shared: false, totalsFetched: true }] }), kinds);
    expect(review).toMatchObject({ verdict: 'unverified', why: ['id_needs_review'] });
    const unfetched = computeCareer(base({ ids: [{ id: 'S2CT00132', status: 'confirmed', shared: false, totalsFetched: false }] }), kinds);
    expect(unfetched.why).toContain('totals_not_fetched');
    expect(unfetched.verdict).toBe('unverified');
  });

  it('counts identical totals under two ids once (two ids sharing one committee)', () => {
    const t = { cycle: 2018, receipts: 100_000, pac: 3000, pacRefunds: 0, coverageEnd: '2018-12-31' };
    const r = computeCareer(base({
      ids: [{ id: 'S2CT00132', status: 'confirmed', shared: false, totalsFetched: true }, { id: 'S8CT00132', status: 'confirmed', shared: false, totalsFetched: true }],
      totals: [{ id: 'S2CT00132', ...t }, { id: 'S8CT00132', ...t }],
    }), kinds);
    expect(r.careerReceipts).toBe(100_000);
    expect(r.verdict).toBe('no_corporate_pac');
  });

  it('a candidate who never raised money is no_receipts', () => {
    const r = computeCareer(base({ totals: [], reports: [], gifts: [] }), kinds);
    expect(r.verdict).toBe('no_receipts');
  });
});

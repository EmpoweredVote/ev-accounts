import { describe, it, expect } from 'vitest';
import { generalElectionDay, legalTermStart, tenureStartInSeat, classifyStart, districtNumber, surnameMatches, officialSurname, type OsRole } from './termStartRules.js';

describe('generalElectionDay — the Tuesday after the first Monday in November', () => {
  it.each([[2018, '2018-11-06'], [2020, '2020-11-03'], [2022, '2022-11-08'], [2024, '2024-11-05'], [2026, '2026-11-03']])(
    '%i → %s', (y, d) => expect(generalElectionDay(y)).toBe(d));
});

describe('legalTermStart', () => {
  it('Indiana: the day after the general election (IN Const. art. 4 §3)', () => {
    expect(legalTermStart('IN', 'upper', 2020)).toBe('2020-11-04');
    expect(legalTermStart('IN', 'lower', 2024)).toBe('2024-11-06');
  });
  it('California: the first Monday in December (CA Const. art. IV §2(a))', () => {
    expect(legalTermStart('CA', 'upper', 2022)).toBe('2022-12-05');
    expect(legalTermStart('CA', 'lower', 2018)).toBe('2018-12-03');
  });
  it('refuses a state it has no rule for', () => expect(() => legalTermStart('TX', 'upper', 2020)).toThrow(/no term-start rule/));
});

const role = (start: string, end: string | undefined, district: string, type: 'upper' | 'lower' = 'upper'): OsRole =>
  ({ start_date: start, end_date: end, type, district });

describe('tenureStartInSeat', () => {
  it('returns the current role start for this chamber and district', () =>
    expect(tenureStartInSeat([role('2020-11-04', undefined, '40')], 'upper', '40')).toBe('2020-11-04'));
  it('joins contiguous earlier roles in the same seat', () =>
    expect(tenureStartInSeat([role('2024-11-06', undefined, '40'), role('2020-11-04', '2024-11-06', '40')], 'upper', '40')).toBe('2020-11-04'));
  it('does NOT join a role in another district (a new seat after redistricting)', () =>
    expect(tenureStartInSeat([role('2022-12-05', undefined, '26'), role('2018-12-03', '2022-12-05', '24')], 'upper', '26')).toBe('2022-12-05'));
  it('does NOT join a non-contiguous earlier stint in the same seat', () =>
    expect(tenureStartInSeat([role('2022-12-05', undefined, '10'), role('2012-12-03', '2016-12-05', '10')], 'upper', '10')).toBe('2022-12-05'));
  it('returns null when there is no current role for this seat', () => {
    expect(tenureStartInSeat([role('2018-12-03', '2022-12-05', '24')], 'upper', '24')).toBeNull();
    expect(tenureStartInSeat([role('2020-11-04', undefined, '40', 'lower')], 'upper', '40')).toBeNull();
  });
});

describe('classifyStart', () => {
  it('a date equal to the legal rule for its year is day precision', () =>
    expect(classifyStart('IN', 'upper', '2020-11-04')).toEqual({ term_start: '2020-11-04', start_precision: 'day', flag: null }));
  it('an off-rule date (special election, appointment) is stored as the year only and flagged', () =>
    expect(classifyStart('CA', 'lower', '2024-06-17')).toEqual({ term_start: '2024-01-01', start_precision: 'year', flag: 'off-rule-date 2024-06-17' }));
  it('a malformed date is refused', () => expect(() => classifyStart('CA', 'upper', '2024-6-1')).toThrow(/not YYYY-MM-DD/));
});

describe('districtNumber', () => {
  it.each([
    ['Indiana State Senate - District 40', '40'], ['State House District 44', '44'], ['Assembly District 29', '29'],
    ['California State Senate district 20', '20'], ['Indiana House of Representatives - District 061', '61'], ['At-large', null],
  ])('%s → %s', (label, n) => expect(districtNumber(label)).toBe(n));
});

describe('surnameMatches', () => {
  it('matches accent- and case-insensitively on the family name', () => {
    expect(surnameMatches('Maria Elena Durazo', 'Durazo')).toBe(true);
    expect(surnameMatches('Sasha Renée Pérez', 'Pérez')).toBe(true);
    expect(surnameMatches('Sasha Renee Perez', 'Pérez')).toBe(true);
  });
  it('matches a hyphenated or multi-word family name as a whole', () => {
    expect(surnameMatches('Lola Smallwood-Cuevas', 'Smallwood-Cuevas')).toBe(true);
    expect(surnameMatches('Lori Goss-reaves', 'Goss-Reaves')).toBe(true);
  });
  it('does not match a different person in the seat', () => expect(surnameMatches('Eric A Koch', 'Yoder')).toBe(false));
  it('does not match on a substring of a longer name', () => expect(surnameMatches('Tim Leeson', 'Lee')).toBe(false));
});

describe('officialSurname', () => {
  it.each([['Steven S. Choi Ph.D.', 'Choi'], ['Akilah Weber Pierson M.D.', 'Pierson'], ['José Luis Solache Jr.', 'Solache'], ['Solache Jr.', 'Solache'], ['Shelli Yoder', 'Yoder'], ['Lori Goss-Reaves', 'Goss-Reaves']])(
    '%s → %s', (n, s) => expect(officialSurname(n)).toBe(s));
});

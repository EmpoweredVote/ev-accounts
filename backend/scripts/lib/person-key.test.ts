import { describe, expect, it } from 'vitest';
import { personKeys, surname, firstToken, findPairs, isSplit } from './person-key.mjs';

const shares = (a: Parameters<typeof personKeys>[0], b: Parameters<typeof personKeys>[0]) =>
  personKeys(a).some((k) => personKeys(b).includes(k));

describe('personKeys — the real pairs it must propose', () => {
  it('leading middle initial inside last_name (Pearson, CA_0267/CA_0270)', () => {
    expect(shares({ first_name: 'Justin', last_name: 'J. Pearson' }, { first_name: 'Justin', last_name: 'Pearson' })).toBe(true);
  });
  it('nickname vs formal first name (Klein, CA_0270)', () => {
    expect(shares({ first_name: 'Matthew', last_name: 'D. Klein' }, { first_name: 'Matt', last_name: 'Klein' })).toBe(true);
  });
  it('suffix on one row only (Morales, CA_0182)', () => {
    expect(shares({ first_name: 'Eloy', last_name: 'Morales Jr.' }, { first_name: 'Eloy', last_name: 'Morales' })).toBe(true);
  });
  it('curly vs straight apostrophe (Thomas, CA_0227)', () => {
    expect(shares({ first_name: 'N’Kiyla', last_name: 'Thomas' }, { first_name: "N'Kiyla", last_name: 'Thomas' })).toBe(true);
  });
  it('preferred_name and alternate_names count', () => {
    expect(shares({ first_name: 'Kimberley', last_name: 'Driscoll', alternate_names: ['Kim Driscoll'] },
      { first_name: 'Kim', last_name: 'Driscoll' })).toBe(true);
    expect(shares({ first_name: 'Robert', last_name: 'Smith', preferred_name: 'Rusty' },
      { first_name: 'Rusty', last_name: 'Smith' })).toBe(true);
  });
  it('"chris" meets both Christopher and Christine', () => {
    expect(shares({ first_name: 'Chris', last_name: 'Lee' }, { first_name: 'Christopher', last_name: 'Lee' })).toBe(true);
    expect(shares({ first_name: 'Chris', last_name: 'Lee' }, { first_name: 'Christine', last_name: 'Lee' })).toBe(true);
  });
});

describe('personKeys — what it must not join', () => {
  it('different surnames', () => {
    expect(shares({ first_name: 'Matt', last_name: 'Klein' }, { first_name: 'Matt', last_name: 'Kline' })).toBe(false);
  });
  it('different given names outside one nickname group', () => {
    expect(shares({ first_name: 'Christopher', last_name: 'Lee' }, { first_name: 'Christine', last_name: 'Lee' })).toBe(false);
  });
});

describe('pieces', () => {
  it('firstToken drops initials and quoted nicknames', () => {
    expect(firstToken('Justin J.')).toBe('justin');
    expect(firstToken('Wendell "Wells"')).toBe('wendell');
    expect(firstToken('J. Robert')).toBe('robert');
  });
  it('surname keeps a single-token name', () => {
    expect(surname('Jr.')).toBe('jr');
    expect(surname('de la Cruz')).toBe('de la cruz');
  });
});

describe('findPairs', () => {
  const row = (id: string, first_name: string, last_name: string, st: string, extra: Record<string, unknown> = {}) =>
    ({ id, first_name, last_name, st, fec: [] as string[], seated: false, answers: 0, ...extra });

  it('pairs a Klein-shaped name in one state, not across states', () => {
    const got = findPairs([row('a', 'Matthew', 'D. Klein', 'mn'), row('b', 'Matt', 'Klein', 'mn'), row('c', 'Matt', 'Klein', 'wi')]);
    expect([...got.keys()]).toEqual(['a|b']);
  });
  it('pairs a row with no state on name alone', () => {
    expect([...findPairs([row('a', 'Ann', 'Lee', ''), row('b', 'Ann', 'Lee', 'ca')]).keys()]).toEqual(['a|b']);
  });
  it('pairs a shared FEC id whatever the names', () => {
    const got = findPairs([row('a', 'Ann', 'Lee', 'ca', { fec: ['fec_house:H1'] }), row('b', 'Bo', 'Kim', 'tx', { fec: ['fec_house:H1'] })]);
    expect([...got.get('a|b')!.why]).toEqual(['SHARED_FEC']);
  });
  it('isSplit: seat on one row, answers only on the other', () => {
    const p = findPairs([row('a', 'Ann', 'Lee', 'ca', { seated: true }), row('b', 'Ann', 'Lee', 'ca', { answers: 4 })]).get('a|b')!;
    expect(isSplit(p)).toBe(true);
  });
});

import { describe, expect, it } from 'vitest';
import { houseSeat, matchHolders, normName, surnameAgrees, type OfficialMember, type OurHolder } from './bioguideMatch.js';

const fips = (s: string) => ({ California: '06', Alaska: '02', Texas: '48', Guam: '66' } as Record<string, string>)[s];
const off = (o: Partial<OfficialMember>): OfficialMember => ({ bioguideId: 'X000001', name: 'Doe, Jane', state: 'California', district: 23, chamber: 'House', ...o });
const ours = (o: Partial<OurHolder>): OurHolder => ({ politician_id: 'p1', full_name: 'Jane Doe', last_name: 'Doe', bioguide_id: null, chamber: 'House', seat: '0623', ...o });

describe('names', () => {
  it('drops accents and punctuation', () => expect(normName("Sánchez O'Neill")).toBe('sanchez oneill'));
  it('matches a hyphenated surname word by word', () => expect(surnameAgrees({ full_name: 'Maria Salazar Lopez', last_name: null }, 'salazar-lopez')).toBe(true));
  it('does not match a different surname', () => expect(surnameAgrees({ full_name: 'Jane Smith', last_name: 'Smith' }, 'doe')).toBe(false));
  it('pads an at-large seat to 00', () => expect(houseSeat('02', null)).toBe('0200'));
});

describe('matchHolders', () => {
  const run = (h: OurHolder[], o: OfficialMember[], owners = new Map<string, string[]>()) => matchHolders(h, o, fips, owners).matches.map((m) => m.cls);
  it('is clean when seat and surname agree', () => expect(run([ours({})], [off({})])).toEqual(['clean']));
  it('is unclear when the seat holder has another surname', () => expect(run([ours({})], [off({ name: 'Roe, Rick' })])).toEqual(['name-differs']));
  it('reports a seat with no official member', () => expect(run([ours({ seat: '0601' })], [off({})])).toEqual(['no-official']));
  it('never matches on surname alone across seats', () => expect(run([ours({ seat: '0624' })], [off({})])).toEqual(['no-official']));
  it('flags an id already carried by another row', () => expect(run([ours({})], [off({})], new Map([['X000001', ['p2']]]))).toEqual(['id-taken']));
  it('keeps an existing equal id, and flags a different one', () => {
    expect(run([ours({ bioguide_id: 'X000001' })], [off({})])).toEqual(['already-set']);
    expect(run([ours({ bioguide_id: 'Y000002' })], [off({})])).toEqual(['id-differs']);
  });
  it('matches a delegate to our CD-98 seat', () => expect(run([ours({ seat: '6698', full_name: 'James C. Moylan', last_name: 'Moylan' })], [off({ state: 'Guam', district: 0, name: 'Moylan, James C.' })])).toEqual(['clean']));
  it('picks the right senator of two by surname', () => {
    const r = matchHolders([ours({ chamber: 'Senate', seat: '48', full_name: 'Ted Cruz', last_name: 'Cruz' })],
      [off({ chamber: 'Senate', state: 'Texas', district: null, name: 'Cornyn, John', bioguideId: 'C001056' }), off({ chamber: 'Senate', state: 'Texas', district: null, name: 'Cruz, Ted', bioguideId: 'C001098' })], fips, new Map());
    expect(r.matches[0].official?.bioguideId).toBe('C001098');
    expect(r.officialsWithoutSeat.map((m) => m.bioguideId)).toEqual(['C001056']);
  });
});

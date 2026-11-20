import { describe, it, expect } from 'vitest';
import { familyAgrees, matchState, seatKey, type Holder, type OsPerson } from './legislatorSeatMatch.js';

const h = (pid: string, chamber: 'upper' | 'lower', ocdTail: string, label: string, fullName: string, state = 'xx'): Holder =>
  ({ politicianId: pid, state, chamber, ocdTail, label, fullName });
const os = (ocdId: string, chamber: 'upper' | 'lower', district: string, name: string, links = ''): OsPerson =>
  ({ ocdId, chamber, district, name, links });

describe('seatKey', () => {
  it('folds the spellings states use', () => {
    expect(seatKey('State House District 007')).toBe('7');
    expect(seatKey('TX House District 10')).toBe('10');
    expect(seatKey('1st Barnstable District')).toBe(seatKey('1st Barnstable'));
    expect(seatKey('Barnstable-Dukes-Nantucket District')).toBe(seatKey('Barnstable, Dukes and Nantucket'));
    expect(seatKey('61A')).toBe('61a');
  });
});

describe('familyAgrees', () => {
  it('ignores suffixes and credentials, and spaces inside a family name', () => {
    expect(familyAgrees('Timothy Reeder, MD', 'Tim Reeder')).toBe(true);
    expect(familyAgrees('Sam C. Mims, V', 'Sam Mims')).toBe(true);
    expect(familyAgrees('Rosalyn D. Henderson-Myers, Ph.D.', 'Rosalyn Henderson-Myers')).toBe(true);
    expect(familyAgrees('Dean Van Schoiack', 'Dean VanSchoiack')).toBe(true);
    expect(familyAgrees('Sylvia Wayfer Baker', 'Sylvia Wayfer')).toBe(true);
  });
  it('never takes a middle initial or a different family name', () => {
    expect(familyAgrees('Mark T. Johnson', 'Mark T Smith')).toBe(false);
    expect(familyAgrees('Caroline Fairly', 'Caroline Dunmoyer')).toBe(false);
    expect(familyAgrees('Ann Lee', 'Ann Leeds')).toBe(false);
  });
});

describe('matchState', () => {
  it('pairs single-member seats by seat, with the family name as a check', () => {
    const r = matchState('xx', [h('p1', 'lower', '1', 'State House District 1', 'Ann Lee'), h('p2', 'upper', '1', 'Senate District 1', 'Bo Kim')],
      [os('ocd-person/a', 'lower', '1', 'Ann Lee'), os('ocd-person/b', 'upper', '1', 'Bo Kim')]);
    expect(r.problems).toEqual([]);
    expect(r.rows.map((x) => `${x.politicianId}:${x.idValue}:${x.matchMethod}`)).toEqual(['p1:ocd-person/a:seat', 'p2:ocd-person/b:seat']);
  });

  it('refuses a seat whose holder differs (a newer member, or a namesake elsewhere)', () => {
    const r = matchState('xx', [h('p1', 'lower', '19', 'State House District 19', 'Nicholas Neal')], [os('ocd-person/a', 'lower', '19', 'Julie Olthoff')]);
    expect(r.rows).toEqual([]);
    expect(r.problems[0]).toMatch(/Nicholas Neal/);
  });

  it('never matches across seats, even on the same name', () => {
    const r = matchState('xx', [h('p1', 'lower', '1', 'D1', 'Ann Lee')], [os('ocd-person/a', 'lower', '2', 'Ann Lee')]);
    expect(r.rows).toEqual([]);
  });

  it('splits a multi-member seat by family name, and refuses a family name shared inside it', () => {
    const ok = matchState('xx', [h('p1', 'lower', '5', 'D5', 'Ann Lee'), h('p2', 'lower', '5', 'D5', 'Bo Kim')],
      [os('ocd-person/b', 'lower', '5', 'Bo Kim'), os('ocd-person/a', 'lower', '5', 'Ann Lee')]);
    expect(ok.rows.map((x) => `${x.politicianId}:${x.idValue}`).sort()).toEqual(['p1:ocd-person/a', 'p2:ocd-person/b']);
    const twin = matchState('xx', [h('p1', 'lower', '34a', 'D34A', 'Andre Johnson'), h('p2', 'lower', '34a', 'D34A', 'Steve Johnson')],
      [os('ocd-person/a', 'lower', '34A', 'Andre Johnson'), os('ocd-person/b', 'lower', '34A', 'Steve Johnson')]);
    expect(twin.rows).toEqual([]);
    expect(twin.problems).toHaveLength(2);
  });

  it("uses our label when the state names districts (MA), and Idaho's A/B seats fold onto ours", () => {
    const ma = matchState('ma', [h('p1', 'lower', '1', '1st Barnstable District', 'Chris Flanagan')], [os('ocd-person/a', 'lower', '1st Barnstable', 'Chris Flanagan')]);
    expect(ma.rows).toHaveLength(1);
    const id = matchState('id', [h('p1', 'lower', '16', 'State House District 16', 'Ann Lee'), h('p2', 'lower', '16', 'State House District 16', 'Bo Kim')],
      [os('ocd-person/a', 'lower', '16A', 'Ann Lee'), os('ocd-person/b', 'lower', '16B', 'Bo Kim')]);
    expect(id.rows.filter((x) => x.idType === 'openstates')).toHaveLength(2);
  });

  it("adds the legislature's own id where it is one per person (GA), by id crosswalk", () => {
    const r = matchState('ga', [h('p1', 'lower', '20', 'D20', 'Larry Walker, III')],
      [os('ocd-person/a', 'lower', '20', 'Larry Walker', 'https://www.legis.ga.gov/members/house/230?session=1029;https://www.legis.ga.gov/members/house/230')]);
    expect(r.rows.map((x) => `${x.idType}:${x.idValue}:${x.matchMethod}`)).toEqual(['openstates:ocd-person/a:seat', 'ga-member:230:id_crosswalk']);
  });

  it('writes no id that two people would hold', () => {
    const r = matchState('xx', [h('p1', 'lower', '1', 'D1', 'Ann Lee'), h('p2', 'lower', '2', 'D2', 'Bo Lee')],
      [os('ocd-person/same', 'lower', '1', 'Ann Lee'), os('ocd-person/same', 'lower', '2', 'Bo Lee')]);
    expect(r.rows).toEqual([]);
    expect(r.problems.join()).toMatch(/matched 2 people/);
  });
});

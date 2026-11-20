import { describe, it, expect } from 'vitest';
import {
  familyAgrees, matchMinnesota, parseCsv, parseLrlCurrent, parseOpenStatesPeople, parseSenateMembers,
  type SeatHolder,
} from './mnMemberIds.js';
import { loadMemberIds } from './memberIds.js';

// Shape of lrl.mn.gov/legdb/current (2026-11-19), cut down.
const card = (id: string, t: 'Rep' | 'Sen', name: string, d: string) =>
  `<div class='media-body'> <h5 class='mt-0 mb-0'><a href='/legdb/fulldetail?id=${id}'><b>${t}. ${name}</b></a> </h5> <span style=''>District: ${d}</span> </div>`;
const lrlHtml = [
  card('15301', 'Rep', 'Paul H. Anderson', '12A'), card('15610', 'Rep', 'Patricia Anderson', '33A'),
  card('15485', 'Sen', 'Mark T. Johnson', '01'),
].join('\n');
const senateJson = { members: [{ mem_id: 1217, dist: '1', preferred_full_name: 'Mark T. Johnson', preferred_last_name: 'Johnson' }] };
const osCsv = 'id,name,current_chamber,current_district,links,sources\n'
  + 'ocd-person/a,Paul Anderson,lower,12A,https://www.house.mn.gov/members/profile/15301,x\n'
  + 'ocd-person/b,"Patti Anderson",lower,33A,https://www.house.mn.gov/members/profile/15610,x\n'
  + 'ocd-person/c,Mark Johnson,upper,1,https://www.senate.mn/members/member_bio.html?mem_id=1217,x\n';
const holders: SeatHolder[] = [
  { politicianId: 'p1', chamber: 'house', district: '12A', fullName: 'Paul Anderson', photoOriginUrl: 'https://www.house.mn.gov/members/profile/15301' },
  { politicianId: 'p2', chamber: 'house', district: '33A', fullName: 'Patti Anderson', photoOriginUrl: null },
  { politicianId: 'p3', chamber: 'senate', district: '1', fullName: 'Mark T. Johnson', photoOriginUrl: 'https://www.senate.mn/members/member_bio.html?mem_id=1217' },
];
const sources = { lrl: 'lrl', senate: 'sen', openStates: 'os' };
const base = () => ({
  holders: holders.map((h) => ({ ...h })), lrl: parseLrlCurrent(lrlHtml), senate: parseSenateMembers(senateJson),
  openStates: parseOpenStatesPeople(osCsv), sources,
});

describe('mnMemberIds', () => {
  it('parses the three sources', () => {
    expect(parseLrlCurrent(lrlHtml)).toEqual([
      { lrlId: '15301', chamber: 'house', district: '12A', name: 'Paul H. Anderson' },
      { lrlId: '15610', chamber: 'house', district: '33A', name: 'Patricia Anderson' },
      { lrlId: '15485', chamber: 'senate', district: '1', name: 'Mark T. Johnson' },
    ]);
    expect(parseSenateMembers(senateJson)[0]).toMatchObject({ memId: '1217', district: '1' });
    expect(parseCsv('a,b\n"x, ""y""",2\n')).toEqual([{ a: 'x, "y"', b: '2' }]);
  });

  it('matches every seat, by seat, with ids crosswalked to Open States', () => {
    const { rows, problems } = matchMinnesota(base());
    expect(problems).toEqual([]);
    const got = rows.map((r) => `${r.politicianId} ${r.idType} ${r.idValue} ${r.matchMethod}`).sort();
    expect(got).toEqual([
      'p1 mn-lrl 15301 seat', 'p1 openstates ocd-person/a id_crosswalk',
      'p2 mn-lrl 15610 seat', 'p2 openstates ocd-person/b id_crosswalk',
      'p3 mn-lrl 15485 seat', 'p3 mn-senate-mem 1217 seat', 'p3 openstates ocd-person/c id_crosswalk',
    ]);
  });

  it('refuses a seat whose family name differs (a namesake or a stale record)', () => {
    const a = base();
    a.holders[0].fullName = 'Paul Smith';
    a.holders[0].photoOriginUrl = null;
    const { rows, problems } = matchMinnesota(a);
    expect(problems.join()).toMatch(/Paul Smith .*family name differs/);
    expect(rows.some((r) => r.politicianId === 'p1')).toBe(false);
  });

  it('refuses when the stored House photo number is not the LRL id', () => {
    const a = base();
    a.holders[0].photoOriginUrl = 'https://www.house.mn.gov/members/profile/14999';
    expect(matchMinnesota(a).problems.join()).toMatch(/photo URL has House id 14999/);
  });

  it('reports a seat LRL lists that we do not hold, and a doubled seat', () => {
    const a = base();
    a.holders = a.holders.filter((h) => h.politicianId !== 'p2');
    expect(matchMinnesota(a).problems.join()).toMatch(/house\|33A: LRL lists Patricia Anderson/);
    const b = base();
    b.holders.push({ ...b.holders[0], politicianId: 'p9' });
    expect(matchMinnesota(b).problems.join()).toMatch(/2 current holders/);
  });

  it('family name check ignores suffixes and needs a whole word', () => {
    expect(familyAgrees('John Smith Jr.', 'John A. Smith')).toBe(true);
    expect(familyAgrees('Ann Lee', 'Ann Leeds')).toBe(false);
  });
});

describe('loadMemberIds', () => {
  it('groups trusted rows by person and type', async () => {
    const seen: unknown[][] = [];
    const ids = await loadMemberIds(async (_q, p) => {
      seen.push(p);
      return { rows: [{ pid: 'p1', id_type: 'mn-lrl', id_value: '15301' }] };
    }, ['p1'], ['mn-lrl']);
    expect(ids.get('p1')).toEqual({ 'mn-lrl': ['15301'] });
    expect(seen[0][2]).toEqual(['seat', 'id_crosswalk', 'manual']);
  });

  it('returns nothing (callers keep their name rules) before CA_0401 adds match_method', async () => {
    const ids = await loadMemberIds(async () => { throw Object.assign(new Error('no column'), { code: '42703' }); }, ['p1'], ['mn-lrl']);
    expect(ids.size).toBe(0);
  });
});

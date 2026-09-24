import { describe, it, expect } from 'vitest';
import {
  appliesFromRoles, appliesToLevel, levelForDistrict, isCommunityCollegeBoard, namesSchoolBoard,
} from './topicApplicability.js';

describe('appliesFromRoles', () => {
  it('treats a topic with no role rows as cross-cutting — but never judicial and never school', () => {
    expect(appliesFromRoles([])).toEqual({
      applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, applies_school: false,
    });
  });
  it('limits a topic to exactly its listed scopes', () => {
    expect(appliesFromRoles([{ role_scope: 'local' }])).toEqual({
      applies_federal: false, applies_state: false, applies_local: true, applies_judicial: false, applies_school: false,
    });
    expect(appliesFromRoles([{ role_scope: 'judicial' }]).applies_judicial).toBe(true);
  });
  it('reads a school row, and only a school row turns school on (CA_0256)', () => {
    // An Education Lens topic after CA_0256: local + state + school.
    const edu = appliesFromRoles([{ role_scope: 'local' }, { role_scope: 'state' }, { role_scope: 'school' }]);
    expect(edu).toEqual({
      applies_federal: false, applies_state: true, applies_local: true, applies_judicial: false, applies_school: true,
    });
    // school-vouchers: federal + state, no school row — excluded (ruling 2026-09-24).
    expect(appliesFromRoles([{ role_scope: 'federal' }, { role_scope: 'state' }]).applies_school).toBe(false);
  });
});

describe('appliesToLevel', () => {
  it('reads the matching flag', () => {
    const local = appliesFromRoles([{ role_scope: 'local' }]);
    expect(appliesToLevel(local, 'local')).toBe(true);
    expect(appliesToLevel(local, 'state')).toBe(false);
    expect(appliesToLevel(local, 'school')).toBe(false);
  });
  it('a school board gets an explicit-school topic, and not a cross-cutting or local-only one', () => {
    expect(appliesToLevel(appliesFromRoles([{ role_scope: 'school' }]), 'school')).toBe(true);
    expect(appliesToLevel(appliesFromRoles([]), 'school')).toBe(false);
    expect(appliesToLevel(appliesFromRoles([{ role_scope: 'local' }]), 'school')).toBe(false);
  });
});

describe('levelForDistrict', () => {
  it.each([
    ['NATIONAL_LOWER', false, null, 'federal'], ['NATIONAL_UPPER', false, null, 'federal'],
    ['STATE_EXEC', false, null, 'state'], ['STATE_LOWER', false, null, 'state'],
    ['STATE_BOARD_EDUCATION', false, 'Utah State Board of Education District 3', 'state'],
    ['COUNTY', false, null, 'local'], ['LOCAL', false, null, 'local'],
    ['SCHOOL', false, 'Monroe County Community School Corporation', 'school'],
    ['SCHOOL', false, 'Los Angeles Unified School District - Board District 4', 'school'],
    ['JUDICIAL', true, null, 'judicial'], ['COUNTY', true, null, 'judicial'],
  ] as const)('%s (judicial=%s, label=%s) -> %s', (t, j, label, want) => {
    expect(levelForDistrict(t, j, label, [])).toBe(want);
  });
  it('keeps a community-college board out of the school level — null, not school and not local', () => {
    expect(levelForDistrict('SCHOOL', false, 'Santa Monica Community College Board', [])).toBeNull();
    expect(levelForDistrict('SCHOOL', false, 'Cerritos Community College Board - Trustee Area 3', [])).toBeNull();
  });
  it('a "Community School" corporation is K-12, not a community college', () => {
    // MCCSC and RBB are "Community School Corporation"s — the rule must not catch them.
    expect(levelForDistrict('SCHOOL', false, 'Richland-Bean Blossom Community School Corporation', [])).toBe('school');
  });
  it('a SCHOOL district with no label is unknown, since it cannot be told from a community college', () => {
    expect(levelForDistrict('SCHOOL', false, null, [])).toBeNull();
    expect(levelForDistrict('SCHOOL', false, '', [])).toBeNull();
  });
  it('a school board filed on a LOCAL district is unknown, not local — a person must re-type it', () => {
    // The four Maine shapes on prod (2026-09-24): title and chamber name as stored.
    expect(levelForDistrict('LOCAL', false, 'Portland', ['School Board Member (District 1)', 'Board of Public Education'])).toBeNull();
    expect(levelForDistrict('LOCAL', false, 'Augusta', ['School Board Chair', 'School Committee'])).toBeNull();
    expect(levelForDistrict('LOCAL', false, 'Lewiston', ['School Committee Member (Ward 3)', 'School Committee'])).toBeNull();
    expect(levelForDistrict('LOCAL', false, 'Westbrook', ['School Board Member (Ward 1)', 'School Board'])).toBeNull();
    // A chamber name alone is enough.
    expect(levelForDistrict('CITY', false, 'X', ['Member', 'Board of Education'])).toBeNull();
  });
  it('an ordinary local office stays local, including trustees who are not school trustees', () => {
    expect(levelForDistrict('LOCAL', false, 'Portland', ['City Councilor (District 1)', 'City Council'])).toBe('local');
    expect(levelForDistrict('LOCAL', false, 'Wind Point', ['Village Trustee', 'Village Board'])).toBe('local');
    expect(levelForDistrict('TOWNSHIP', false, 'Richland', ['Richland Township Trustee', null])).toBe('local');
    expect(levelForDistrict('LOCAL', false, 'Altadena', ['Trustee (At-Large)', 'Altadena Library District Board of Trustees'])).toBe('local');
  });
  it('the office rule does not touch a SCHOOL district', () => {
    expect(levelForDistrict('SCHOOL', false, 'Monroe County Community School Corporation', ['Board Member', 'School Board'])).toBe('school');
  });
  it('returns null for a type it has never seen, so scope is reported unknown rather than guessed', () => {
    expect(levelForDistrict('SOMETHING_NEW', false, 'x', [])).toBeNull();
    expect(levelForDistrict(null, null, null, [])).toBeNull();
  });
});

describe('isCommunityCollegeBoard', () => {
  it.each([
    ['Santa Monica Community College Board', true],
    ['LOS ANGELES COMMUNITY COLLEGE BOARD', true],
    ['Monroe County Community School Corporation', false],
    ['College Place School District', false],
    [null, false],
  ] as const)('%s -> %s', (label, want) => {
    expect(isCommunityCollegeBoard(label)).toBe(want);
  });
});

describe('namesSchoolBoard', () => {
  it.each([
    [['School Board Member (At-Large 1)'], true],
    [['Member', 'School Committee'], true],
    [['Portland Board of Public Education'], true],
    [['Board of Education'], true],
    [['Village Trustee', 'Village Board'], false],
    [['City Council'], false],
    [[null, undefined], false],
  ] as const)('%j -> %s', (labels, want) => {
    expect(namesSchoolBoard(labels)).toBe(want);
  });
});

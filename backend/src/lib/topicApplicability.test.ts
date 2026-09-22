import { describe, it, expect } from 'vitest';
import { appliesFromRoles, appliesToLevel, levelForDistrict } from './topicApplicability.js';

describe('appliesFromRoles', () => {
  it('treats a topic with no role rows as cross-cutting — but never judicial', () => {
    expect(appliesFromRoles([])).toEqual({
      applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false,
    });
  });
  it('limits a topic to exactly its listed scopes', () => {
    expect(appliesFromRoles([{ role_scope: 'local' }])).toEqual({
      applies_federal: false, applies_state: false, applies_local: true, applies_judicial: false,
    });
    expect(appliesFromRoles([{ role_scope: 'judicial' }]).applies_judicial).toBe(true);
  });
});

describe('appliesToLevel', () => {
  it('reads the matching flag', () => {
    const local = appliesFromRoles([{ role_scope: 'local' }]);
    expect(appliesToLevel(local, 'local')).toBe(true);
    expect(appliesToLevel(local, 'state')).toBe(false);
  });
});

describe('levelForDistrict', () => {
  it.each([
    ['NATIONAL_LOWER', false, 'federal'], ['NATIONAL_UPPER', false, 'federal'],
    ['STATE_EXEC', false, 'state'], ['STATE_LOWER', false, 'state'],
    ['COUNTY', false, 'local'], ['LOCAL', false, 'local'], ['SCHOOL', false, 'local'],
    ['JUDICIAL', true, 'judicial'], ['COUNTY', true, 'judicial'],
  ] as const)('%s (judicial=%s) -> %s', (t, j, want) => {
    expect(levelForDistrict(t, j)).toBe(want);
  });
  it('returns null for a type it has never seen, so scope is reported unknown rather than guessed', () => {
    expect(levelForDistrict('SOMETHING_NEW', false)).toBeNull();
    expect(levelForDistrict(null, null)).toBeNull();
  });
});

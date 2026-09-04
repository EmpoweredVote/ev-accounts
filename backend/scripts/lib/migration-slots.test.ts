import { describe, it, expect } from 'vitest';
import { slotOf, slotKey } from './migration-slots.mjs';

// The slot parser is the shared vocabulary between the collision CHECKER
// (check-migration-numbers.mjs) and the steward ALLOCATOR. Both must agree on
// exactly which files are migrations and which slot each one occupies, or the
// allocator will hand out a number the checker already considers claimed.
//
// These are the rules CLAUDE.md states and the checker already encodes; this
// file pins them so extracting the logic cannot quietly change them.

describe('slotOf', () => {
  it('reads a namespaced slot', () => {
    expect(slotOf('CC_0068_lomita_final_three_headshots.sql'))
      .toEqual({ ns: 'CC', num: '68', key: 'CC_68' });
  });

  it('reads an un-namespaced slot', () => {
    expect(slotOf('1463_office_terms.sql'))
      .toEqual({ ns: '', num: '1463', key: '1463' });
  });

  it('treats leading zeros as the same slot, so CA_0001 and CA_1 collide', () => {
    expect(slotKey('CA_0001_first.sql')).toBe(slotKey('CA_1_first.sql'));
  });

  it('does not treat a namespaced slot as the bare number', () => {
    expect(slotKey('CA_1500_x.sql')).not.toBe(slotKey('1500_x.sql'));
  });

  it('upper-cases the namespace so cc_ and CC_ are one namespace', () => {
    expect(slotOf('cc_0068_x.sql')?.ns).toBe('CC');
  });

  it('ignores a file that is not a numbered migration', () => {
    expect(slotOf('README.md')).toBeNull();
    expect(slotOf('_templates/answer_delete_context_guard.sql')).toBeNull();
  });

  it('reads a full path, not just a basename', () => {
    expect(slotOf('backend/migrations/CC_0068_x.sql')?.key).toBe('CC_68');
  });
});

import { describe, it, expect } from 'vitest';
import { HOUSE_ALSO, unMojibake } from './me-member-lists.js';

describe('Maine member lists — the House roster', () => {
  it('puts back UTF-8 that was read as Latin-1, and leaves a clean name alone', () => {
    // Open States' 2026-11 extract spells Owen Casás "CasÃ¡s"
    expect(unMojibake('Owen D. CasÃ¡s')).toBe('Owen D. Casás');
    expect(unMojibake('Owen D. Casás')).toBe('Owen D. Casás');
    expect(unMojibake('Tiffany Roberts')).toBe('Tiffany Roberts');
    // the shape of double encoding that does not decode is an error, not a name passed on
    expect(() => unMojibake('CasÃ\u0080\u0080s')).toThrow(/does not decode/);
  });

  it('sources every alternate name from the House\'s own member profile, as an archived copy', () => {
    for (const a of HOUSE_ALSO) {
      expect(a.source).toMatch(/^https:\/\/web\.archive\.org\/web\/\d{14}id_\/http:\/\/legislature\.maine\.gov(?::80)?\/house\/house\/MemberProfiles\/Details\/\d+$/);
      expect(a.legislatures.every((l) => l >= 128 && l <= 130)).toBe(true);
    }
  });
});

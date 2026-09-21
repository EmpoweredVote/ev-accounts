import { describe, it, expect } from 'vitest';
import { ocdDistrictSuffix } from './ocdDistrictSuffix.js';

// 🔴 WHY THIS EXISTS. `load-state-tiger-boundaries.ts` built the OCD-ID suffix for both state
//    legislative layers with `parseInt(districtNum, 10)`. That is correct for a state whose
//    district codes are plain numbers — and silently wrong for one whose codes carry a letter.
//
//    Minnesota's TIGER SLDLST codes are '01A'..'67B'. parseInt('08A') is 8, so 08A and 08B both
//    became `ocd-division/country:us/state:mn/sldl:8`. Measured against the real TIGER 2024 FIPS
//    27 file on 2026-09-12: 134 House districts collapse to 67 distinct OCD-IDs, all 67 pairs
//    colliding. geo_id was unaffected (134 of 134 distinct) because it comes from the raw GEOID.
//
// 🔴 NOTHING WOULD HAVE CAUGHT IT. essentials.districts has no unique constraint on ocd_id, so
//    the duplicates write silently; address search resolves on geo_id and never on ocd_id, so
//    check:reachability and every identity anchor stay green. It is already in production for
//    Maryland, whose delegate districts are 1A/1B/1C: 71 sldl rows, 47 distinct ocd_ids.
//    North Dakota and South Dakota carry the same shape and are still to be loaded.
//
// ⚠ THE POINT OF THIS FUNCTION IS THAT IT CHANGES NOTHING ELSE. Measured 2026-09-12: all 2,400
//   existing STATE_UPPER/STATE_LOWER ocd_ids across 18 states have a plain-digit suffix, and 40
//   Massachusetts rows have the literal suffix 'NaN'. Both groups must come out byte-identical.

describe('ocdDistrictSuffix', () => {
  describe('plain numeric codes — the 2,400 existing rows must not move', () => {
    it('strips leading zeros, as parseInt did', () => {
      expect(ocdDistrictSuffix('043')).toBe('43');
      expect(ocdDistrictSuffix('008')).toBe('8');
      expect(ocdDistrictSuffix('001')).toBe('1');
    });

    it('leaves an unpadded number alone', () => {
      expect(ocdDistrictSuffix('1')).toBe('1');
      expect(ocdDistrictSuffix('67')).toBe('67');
      expect(ocdDistrictSuffix('120')).toBe('120');
    });

    it('maps an all-zero code to 0, as parseInt did', () => {
      expect(ocdDistrictSuffix('000')).toBe('0');
    });
  });

  describe('lettered codes — the defect', () => {
    it('keeps the letter, so A and B do not collapse', () => {
      expect(ocdDistrictSuffix('08A')).toBe('8A');
      expect(ocdDistrictSuffix('08B')).toBe('8B');
      expect(ocdDistrictSuffix('08A')).not.toBe(ocdDistrictSuffix('08B'));
    });

    it('strips the padding but not the letter', () => {
      expect(ocdDistrictSuffix('01A')).toBe('1A');
      expect(ocdDistrictSuffix('67B')).toBe('67B');
    });

    it('uppercases the letter so casing cannot fork one district into two', () => {
      expect(ocdDistrictSuffix('08a')).toBe('8A');
      expect(ocdDistrictSuffix('08a')).toBe(ocdDistrictSuffix('08A'));
    });

    it('handles a multi-letter suffix (Maryland delegate districts run 1A/1B/1C)', () => {
      expect(ocdDistrictSuffix('01C')).toBe('1C');
    });
  });

  describe("Minnesota's real code set", () => {
    // L2022: 67 Senate districts, each divided into House districts A and B.
    const mnHouseCodes = Array.from({ length: 67 }, (_, i) => i + 1)
      .flatMap((n) => ['A', 'B'].map((half) => `${String(n).padStart(2, '0')}${half}`));

    it('is 134 codes', () => {
      expect(mnHouseCodes).toHaveLength(134);
      expect(mnHouseCodes[0]).toBe('01A');
      expect(mnHouseCodes[133]).toBe('67B');
    });

    it('🔴 produces 134 DISTINCT suffixes — the whole point', () => {
      const out = mnHouseCodes.map(ocdDistrictSuffix);
      expect(new Set(out).size).toBe(134);
    });

    it('CONTROL: the old parseInt rule produces only 67, proving the test can tell them apart', () => {
      const old = mnHouseCodes.map((c) => String(parseInt(c, 10)));
      expect(new Set(old).size).toBe(67);
    });

    it('the 67 Senate codes are unaffected', () => {
      const senate = Array.from({ length: 67 }, (_, i) => String(i + 1).padStart(3, '0'));
      const out = senate.map(ocdDistrictSuffix);
      expect(new Set(out).size).toBe(67);
      expect(out[0]).toBe('1');
      expect(out[66]).toBe('67');
    });
  });

  describe('inputs that must keep their CURRENT behaviour, wrong though it looks', () => {
    it("returns 'NaN' for a non-numeric name, as parseInt did — 40 MA rows depend on it", () => {
      expect(ocdDistrictSuffix('First Essex')).toBe('NaN');
      expect(ocdDistrictSuffix('ZZZ')).toBe('NaN');
    });

    it("returns '0' for a missing code, as `districtNum ?? '0'` did", () => {
      expect(ocdDistrictSuffix(undefined)).toBe('0');
      expect(ocdDistrictSuffix(null)).toBe('0');
      expect(ocdDistrictSuffix('')).toBe('0');
    });
  });
});

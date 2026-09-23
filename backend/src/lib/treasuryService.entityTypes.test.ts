import { describe, it, expect, vi } from 'vitest';

const query = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query } }));

import { parseEntityTypes, KNOWN_ENTITY_TYPES } from './treasuryService.js';

/**
 * ⚠⚠ AN UNKNOWN TYPE IS A CALLER BUG, NOT AN EMPTY RESULT. Answering `[]` for
 * `?entity_type=citty` would let a typo read as "there are no such places",
 * which is the same class of silent wrongness as an unmatched slug rendering
 * someone else's budget.
 */
describe('parseEntityTypes', () => {
  it('accepts a CSV of known types', () => {
    expect(parseEntityTypes('city,town')).toEqual({ values: ['city', 'town'] });
  });

  it('trims whitespace and ignores empty segments', () => {
    expect(parseEntityTypes(' city , , town ')).toEqual({ values: ['city', 'town'] });
  });

  it('rejects an unknown type by NAMING it', () => {
    expect(parseEntityTypes('city,citty')).toEqual({ invalid: 'citty' });
  });

  it('treats absent or empty input as no filter', () => {
    expect(parseEntityTypes(undefined)).toEqual({ values: [] });
    expect(parseEntityTypes('')).toEqual({ values: [] });
  });

  it('accepts every type the CHECK constraint permits, not just the ones seeded today', () => {
    // Mirrors municipalities_entity_type_check (TT migration
    // 20260903000000_pa_borough_entity_type.sql) — all fourteen, including
    // special_district/school_district/conservancy/library, which are legal
    // rows with zero instances today.
    for (const t of ['city', 'county', 'township', 'village', 'borough',
                     'nonprofit', 'state', 'municipality', 'special_district',
                     'school_district', 'conservancy', 'library', 'town', 'federal']) {
      expect(KNOWN_ENTITY_TYPES.has(t)).toBe(true);
    }
    expect(KNOWN_ENTITY_TYPES.size).toBe(14);
  });
});

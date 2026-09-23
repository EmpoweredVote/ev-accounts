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

  it('knows every type the table actually holds', () => {
    // Measured 2026-09-22 against production: these ten and nothing else.
    for (const t of ['city', 'town', 'township', 'village', 'borough',
                     'municipality', 'county', 'state', 'nonprofit', 'federal']) {
      expect(KNOWN_ENTITY_TYPES.has(t)).toBe(true);
    }
  });
});

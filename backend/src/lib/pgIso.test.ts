import { describe, it, expect } from 'vitest';

import { toIsoStringOrNull } from './pgIso.js';

describe('toIsoStringOrNull', () => {
  it('returns null for null and undefined', () => {
    expect(toIsoStringOrNull(null)).toBeNull();
    expect(toIsoStringOrNull(undefined)).toBeNull();
  });

  it('converts a Date (pg timestamptz) to an ISO-8601 UTC string', () => {
    expect(toIsoStringOrNull(new Date('2026-07-29T22:30:00Z'))).toBe(
      '2026-07-29T22:30:00.000Z',
    );
  });

  it('passes strings through unchanged', () => {
    expect(toIsoStringOrNull('2026-07-29T18:30:00-04:00')).toBe(
      '2026-07-29T18:30:00-04:00',
    );
  });
});

/**
 * Guards the gap between "the SQL selects it" and "the API returns it".
 *
 * WHY THIS EXISTS
 *
 * `photo_restriction` shipped to production once and did nothing. The column was in all ten
 * payload queries, the sub-select was verified against the production database and returned the
 * right object, `tsc` was clean, CI was green, and the API still did not serve the field —
 * because every one of these services projects rows through an explicit
 * `rows.map(row => ({ ...named fields... }))`, and a field nobody copies is simply dropped.
 *
 * 🔴 TYPESCRIPT CANNOT SEE THIS. `pool.query` returns `any`-shaped rows, so adding a column to a
 * SQL string and forgetting the projection is invisible to the compiler. So is a new query added
 * later that copies the neighbouring `photo_origin_url` line without this one.
 *
 * ⚠ AND A DATABASE TEST CANNOT SEE IT EITHER. Querying prod proves the SQL is right, which is
 * exactly what was proven before shipping the broken version. The only test that catches it runs
 * a row THROUGH the mapper.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./geocodingService.js', () => ({
  geocodeAddress: vi.fn(),
  GeocodingError: class GeocodingError extends Error {},
}));

import { pool } from './db.js';
import { getPoliticiansFlatList } from './essentialsService.js';
import { PHOTO_RESTRICTION_SELECT_SQL } from './photoRestriction.js';

const RESTRICTION = {
  code: 'sd-legislature-2026',
  authority: 'South Dakota Legislative Research Council',
  label: 'Portrait use restricted',
  headline: 'Why these members have no photograph',
  body: 'First paragraph.\n\nSecond paragraph.',
};

function row(extra: Record<string, unknown> = {}) {
  return {
    id: 'p1', full_name: 'Al Novstrup', first_name: 'Al', last_name: 'Novstrup',
    photo_origin_url: '', office_title: 'Representative',
    ...extra,
  };
}

describe('photo_restriction survives the row projection', () => {
  beforeEach(() => vi.mocked(pool.query).mockReset());

  it('carries the object from the row all the way to the returned record', async () => {
    vi.mocked(pool.query).mockResolvedValue({ rows: [row({ photo_restriction: RESTRICTION })] } as never);

    const out = await getPoliticiansFlatList(false);

    // The whole point: not merely defined, but the SAME object the query returned. A mapper that
    // copies a truthy placeholder would pass a `toBeDefined` check and still serve wrong copy.
    expect(out[0].photo_restriction).toEqual(RESTRICTION);
    expect(out[0].photo_restriction?.body).toContain('\n\n');
  });

  it('is null — never undefined — for an unrestricted person', async () => {
    // The frontend renders on truthiness, so null and undefined behave alike there. They do NOT
    // behave alike in JSON: `undefined` makes the key vanish from the response entirely, which is
    // precisely how the first broken version looked from outside.
    vi.mocked(pool.query).mockResolvedValue({ rows: [row()] } as never);

    const out = await getPoliticiansFlatList(false);

    expect(out[0]).toHaveProperty('photo_restriction');
    expect(out[0].photo_restriction).toBeNull();
  });

  it('asks the database for the column in the first place', async () => {
    vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

    await getPoliticiansFlatList(false);

    // A projection that copies a column no query selects is the same bug facing the other way:
    // every row would silently be null. Assert both halves are present.
    const sql = String(vi.mocked(pool.query).mock.calls[0][0]);
    expect(sql).toContain('photo_restriction');
    expect(PHOTO_RESTRICTION_SELECT_SQL).toContain('essentials.photo_restrictions');
  });
});

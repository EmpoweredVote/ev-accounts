import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { findLocalities, stripPlaceSuffix, validateLocalityQuery } from './readrankLocalities.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockQuery.mockResolvedValue({ rows: [] });
});

describe('validateLocalityQuery', () => {
  it('rejects missing, short, long and badly-charactered q', () => {
    expect(validateLocalityQuery(undefined, undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery('', undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery(' a ', undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery('x'.repeat(61), undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery('Irvine; DROP TABLE', undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery('Irv1ne', undefined)).toMatchObject({ ok: false });
    expect(validateLocalityQuery(['a', 'b'], undefined)).toMatchObject({ ok: false });
  });
  it('requires at least one letter', () => {
    for (const q of ['..', "'-'", '. -']) expect(validateLocalityQuery(q, undefined)).toMatchObject({ ok: false });
  });
  it('normalises curly apostrophes', () => {
    expect(validateLocalityQuery('O’Fallon', undefined)).toEqual({ ok: true, q: "O'Fallon", state: null });
  });
  it('accepts accents, period, apostrophe, hyphen, spaces', () => {
    for (const q of ['Irvine', 'St. Paul', "O'Fallon", 'Winston-Salem', 'Cañon City', 'Río Rancho']) {
      expect(validateLocalityQuery(q, undefined)).toEqual({ ok: true, q, state: null });
    }
  });
  it('trims q and uppercases state', () => {
    expect(validateLocalityQuery('  Irvine ', 'ca')).toEqual({ ok: true, q: 'Irvine', state: 'CA' });
  });
  it('rejects bad state', () => {
    for (const s of ['c', 'cal', '1a', 'C!', ['CA', 'IN']]) {
      expect(validateLocalityQuery('Irvine', s)).toMatchObject({ ok: false });
    }
  });
});

describe('stripPlaceSuffix', () => {
  it('removes Census suffixes only', () => {
    expect(stripPlaceSuffix('Irvine city')).toBe('Irvine');
    expect(stripPlaceSuffix('Union City city')).toBe('Union City');
    expect(stripPlaceSuffix('Bethel Park municipality')).toBe('Bethel Park');
    expect(stripPlaceSuffix('Indianapolis city (balance)')).toBe('Indianapolis');
    expect(stripPlaceSuffix('Nashville-Davidson metropolitan government (balance)')).toBe('Nashville-Davidson');
    expect(stripPlaceSuffix('Akron')).toBe('Akron');
    expect(stripPlaceSuffix('city')).toBe('city');
  });
  it('is case-sensitive: capitalised words are part of the name', () => {
    expect(stripPlaceSuffix('Michigan City')).toBe('Michigan City');
    expect(stripPlaceSuffix('Carson City')).toBe('Carson City');
  });
  it('handles city and borough and bare (balance)', () => {
    expect(stripPlaceSuffix('Juneau city and borough')).toBe('Juneau');
    expect(stripPlaceSuffix('Butte-Silver Bow (balance)')).toBe('Butte-Silver Bow');
  });
  it('strips consolidated city-county suffixes', () => {
    expect(stripPlaceSuffix('Lexington-Fayette urban county')).toBe('Lexington-Fayette');
    expect(stripPlaceSuffix('Louisville/Jefferson County metro government (balance)')).toBe('Louisville/Jefferson County');
  });
});

describe('findLocalities', () => {
  it('returns USPS state, stripped name, geoids', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ name: 'Irvine city', state: '06', place_geoid: '0636770', county_geoid: '06059' }],
    });
    const out = await findLocalities('Irvine', 'CA');
    expect(out).toEqual([{ name: 'Irvine', state: 'CA', placeGeoid: '0636770', countyGeoid: '06059' }]);
  });
  it('returns [] when nothing matches', async () => {
    expect(await findLocalities('Nowhereville', null)).toEqual([]);
  });
  it('passes q and state as parameters, never interpolated', async () => {
    const evil = "O'Fallon";
    await findLocalities(evil, 'IL');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).not.toContain('Fallon');
    expect(sql).not.toContain("'IL'");
    expect(sql).not.toContain("'17'");
    expect(params[0]).toContain(evil);
    expect(params[0]).toContain("O'Fallon city");
    expect(params[1]).toBe('17');
    expect(params[2]).toBe(evil);
    expect(sql).toMatch(/LIMIT 10/);
    expect(sql).toMatch(/ORDER BY/);
    expect(sql).toContain("'G4110'");
  });
  it('escapes LIKE wildcards in the prefix param', async () => {
    await findLocalities('A_b.', null);
    expect(mockQuery.mock.calls[0][1][2]).toBe('A\\_b.');
  });
  it('drops rows whose name differs from q only by suffix case (Carson City for Carson)', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ name: 'Carson City', state: '32', place_geoid: '3209700', county_geoid: '32510' }],
    });
    expect(await findLocalities('Carson', null)).toEqual([]);
  });
  it('keeps exact unsuffixed, suffixed, city-and-borough and prefix matches', async () => {
    mockQuery.mockResolvedValue({
      rows: [
        { name: 'Carson City', state: '32', place_geoid: '1', county_geoid: '32510' },
        { name: 'Irvine city', state: '06', place_geoid: '2', county_geoid: '06059' },
        { name: 'Juneau city and borough', state: '02', place_geoid: '3', county_geoid: '02110' },
        { name: 'Lexington-Fayette urban county', state: '21', place_geoid: '4', county_geoid: '21067' },
      ],
    });
    expect((await findLocalities('Carson City', null)).map((l) => l.name)).toEqual(['Carson City']);
    expect((await findLocalities('Irvine', null)).map((l) => l.name)).toEqual(['Irvine']);
    expect((await findLocalities('Juneau', null)).map((l) => l.name)).toEqual(['Juneau']);
    expect((await findLocalities('Lexington', null)).map((l) => l.name)).toEqual(['Lexington-Fayette']);
  });
  it('does not match a suffixed name by whole-name equality (Carson city vs Carson City)', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ name: 'Carson city', state: '06', place_geoid: '1', county_geoid: '06037' }],
    });
    expect(await findLocalities('Carson City', null)).toEqual([]);
  });
  it('drops rows with no USPS mapping', async () => {
    mockQuery.mockResolvedValue({
      rows: [{ name: 'Irvine city', state: '99', place_geoid: '1', county_geoid: '2' }],
    });
    expect(await findLocalities('Irvine', null)).toEqual([]);
  });
  it('passes null state param when no state given', async () => {
    await findLocalities('Springfield', null);
    expect(mockQuery.mock.calls[0][1][1]).toBeNull();
  });
  it('returns [] without querying for an unknown state code', async () => {
    expect(await findLocalities('Irvine', 'ZZ')).toEqual([]);
    expect(mockQuery).not.toHaveBeenCalled();
  });
});

import { describe, it, expect } from 'vitest';
import { attachCoordinates, assignToCounties, listCounties, MissingPolygonError, type QueryFn } from './locate.js';
import type { ApiFn } from './sweep.js';
import type { CandidateFile } from './types.js';

const f = (title: string, lat: number | null = null, lon: number | null = null): CandidateFile => ({
  title, url: 'u', width: 2000, height: 1200, licence: 'CC BY 4.0', author: 'A', date: null,
  sourceCategory: 'Category:X', lat, lon,
});

describe('attachCoordinates', () => {
  it('batches coordinate lookups 50 titles at a time', async () => {
    const batches: number[] = [];
    const api: ApiFn = async (p) => {
      batches.push(String(p.titles).split('|').length);
      return { query: { pages: [] } };
    };
    await attachCoordinates(Array.from({ length: 120 }, (_, i) => f(`f${i}.jpg`)), { api });
    expect(batches).toEqual([50, 50, 20]);
  });

  it('keeps files with no coordinates rather than discarding them', async () => {
    const api: ApiFn = async () => ({ query: { pages: [{ title: 'a.jpg', coordinates: [{ lat: 1, lon: 2 }] }] } });
    const out = await attachCoordinates([f('a.jpg'), f('b.jpg')], { api });
    expect(out).toHaveLength(2);
    expect(out.find((x) => x.title === 'b.jpg')!.lat).toBeNull();
  });
});

/** A fake db: counties present, and which (title -> geoid) the polygon query matches. */
function fakeQuery(countyRows: Array<{ geo_id: string; name: string }>, hits: Array<{ geo_id: string; title: string }>): QueryFn {
  return async (sql: string) => {
    if (/ST_Contains/i.test(sql)) return hits;
    return countyRows;
  };
}
const NE = [{ geo_id: '31047', name: 'Dawson County' }, { geo_id: '31121', name: 'Merrick County' }];

describe('assignToCounties', () => {
  it('assigns a file to the county whose polygon contains it', async () => {
    const q = fakeQuery(NE, [{ geo_id: '31047', title: 'a.jpg' }]);
    const r = await assignToCounties([f('a.jpg', 40.8, -99.7)], '31', q);
    expect(r.located.get('31047')!.map((x) => x.title)).toEqual(['a.jpg']);
  });

  it('returns a coordinate inside no county as `outside`, counted, not dropped silently', async () => {
    const q = fakeQuery(NE, []);
    const r = await assignToCounties([f('far.jpg', 39.7, -104.9)], '31', q);
    expect(r.outside.map((x) => x.title)).toEqual(['far.jpg']);
    expect(r.located.size).toBe(0);
  });

  it('keeps files with no coordinates as `unlocated`, never as `outside`', async () => {
    const q = fakeQuery(NE, []);
    const r = await assignToCounties([f('nogeo.jpg')], '31', q);
    expect(r.unlocated.map((x) => x.title)).toEqual(['nogeo.jpg']);
    expect(r.outside).toHaveLength(0);
  });

  it('throws MissingPolygonError naming the state when no county polygons exist', async () => {
    // Review Focus 1: zero candidates must never be indistinguishable from no photographs.
    const q = fakeQuery([], []);
    await expect(assignToCounties([f('a.jpg', 40.8, -99.7)], '31', q)).rejects.toBeInstanceOf(MissingPolygonError);
  });

  it("filters on (mtfcc, geo_id), not geo_id alone", async () => {
    let seen = '';
    const q: QueryFn = async (sql: string) => { seen += sql; return /ST_Contains/i.test(sql) ? [] : NE; };
    await assignToCounties([f('a.jpg', 40.8, -99.7)], '31', q);
    expect(seen).toMatch(/mtfcc\s*=\s*'G4020'/);
  });
});

describe('listCounties', () => {
  it('returns every county in the state with its geoid and name', async () => {
    const r = await listCounties('31', fakeQuery(NE, []));
    expect(r).toEqual([{ geoid: '31047', name: 'Dawson County' }, { geoid: '31121', name: 'Merrick County' }]);
  });
  it('throws MissingPolygonError when the state has no counties at all', async () => {
    await expect(listCounties('99', fakeQuery([], []))).rejects.toBeInstanceOf(MissingPolygonError);
  });
});

describe('listCounties — a polygon can be present and useless', () => {
  const healthy = (geo_id: string, name: string) => ({ geo_id, name, geom_null: false, geom_valid: true, geom_in_bounds: true });

  it('names the offending county when its geometry is invalid', async () => {
    const q: QueryFn = async () => [healthy('31121', 'Merrick County'), { ...healthy('31047', 'Dawson County'), geom_valid: false }];
    await expect(listCounties('31', q)).rejects.toThrow(/31047/);
  });

  it('names the offending county when its geometry is NULL', async () => {
    const q: QueryFn = async () => [{ ...healthy('31047', 'Dawson County'), geom_null: true }];
    await expect(listCounties('31', q)).rejects.toThrow(/31047/);
  });

  it('names the offending county when its coordinates are outside earth bounds', async () => {
    // A Web Mercator polygon tagged SRID 4326 passes every other geometric check.
    const q: QueryFn = async () => [{ ...healthy('31047', 'Dawson County'), geom_in_bounds: false }];
    await expect(listCounties('31', q)).rejects.toThrow(/31047/);
  });

  it('accepts counties whose geometry is healthy', async () => {
    const q: QueryFn = async () => [healthy('31047', 'Dawson County')];
    expect(await listCounties('31', q)).toEqual([{ geoid: '31047', name: 'Dawson County' }]);
  });

  it('asks the database for the geometry health columns', async () => {
    let sql = '';
    const q: QueryFn = async (s) => { sql = s; return [healthy('31047', 'D')]; };
    await listCounties('31', q);
    expect(sql).toMatch(/ST_IsValid/i);
  });
});

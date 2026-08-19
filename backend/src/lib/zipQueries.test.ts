import { describe, it, expect } from 'vitest';
import {
  ZCTA_CTE,
  ZIP_AREA_SPATIAL_PREDICATE,
  ZIP_SHARE_EXPR,
  MULTI_STATE_SHARE_FLOOR,
  buildZipDistrictQuery,
  buildZipStatesQuery,
  buildZipCountyQuery,
  buildZctaExistsQuery,
  rollUpAmbiguity,
  normalizeZip,
  ZIP_CACHE_KEY_PREFIX,
  ZIP_CACHE_TTL_SECONDS,
} from './zipQueries.js';

describe('normalizeZip', () => {
  it('passes a 5-digit ZIP through', () => {
    expect(normalizeZip('46220')).toBe('46220');
  });
  it('truncates ZIP+4 to five digits', () => {
    expect(normalizeZip('46220-1234')).toBe('46220');
  });
  it('trims surrounding whitespace', () => {
    expect(normalizeZip('  46220 ')).toBe('46220');
  });
  it('returns null for anything not ZIP-shaped', () => {
    expect(normalizeZip('4622')).toBeNull();
    expect(normalizeZip('462201')).toBeNull();
    expect(normalizeZip('abcde')).toBeNull();
    expect(normalizeZip('')).toBeNull();
    expect(normalizeZip(null)).toBeNull();
  });
});

describe('ZCTA_CTE', () => {
  it('looks the ZIP polygon up by (geo_id, mtfcc) — the unique key', () => {
    expect(ZCTA_CTE).toContain("mtfcc = 'G6350'");
    expect(ZCTA_CTE).toContain('geo_id = $1');
  });
  it('carries the polygon area so share is one CTE evaluation, not one per row', () => {
    expect(ZCTA_CTE).toContain('public.ST_Area(geometry) AS a');
  });
});

describe('ZIP_AREA_SPATIAL_PREDICATE', () => {
  it('leads with the && bounding-box prefilter so the GIST index drives the scan', () => {
    // Verified 2026-08-18: Index Scan using idx_geofence_boundaries_geometry.
    // An OR of mixed spatial predicates cannot use the index — that was the
    // 2026-07-01 browse-stall regression (4,286ms Parallel Seq Scan).
    expect(ZIP_AREA_SPATIAL_PREDICATE).toContain('OPERATOR(public.&&)');
  });

  it('requires genuine interior overlap, not a shared border', () => {
    expect(ZIP_AREA_SPATIAL_PREDICATE).toContain('public.ST_Intersects');
    expect(ZIP_AREA_SPATIAL_PREDICATE).toContain('NOT public.ST_Touches');
  });

  it('excludes other ZIP polygons from the overlap work', () => {
    // ~30 neighbouring ZCTAs intersect any given ZCTA. The geoIdGuard exclusion
    // already stops them producing rows; this stops us paying to intersect them.
    expect(ZIP_AREA_SPATIAL_PREDICATE).toContain("gb.mtfcc <> 'G6350'");
  });

  it("excludes the state-outline layer so a neighbouring state cannot bypass the 1% floor", () => {
    // ZIP 46360 (Michigan City) clips Michigan by 0.013% of its area. With G4000
    // admitted, that returned Michigan's entire executive branch — Nessel, Benson,
    // Gilchrist, Peters — for an Indiana ZIP, with a bogus 0.013% share, because
    // they came through the DISTRICT query rather than the statewide one and so
    // never met MULTI_STATE_SHARE_FLOOR. Excluded here rather than globally: see
    // the note in geoIdGuard.ts.
    expect(ZIP_AREA_SPATIAL_PREDICATE).toContain("gb.mtfcc <> 'G4000'");
  });

  it('contains no OR — one predicate per branch is the index-driven shape', () => {
    expect(ZIP_AREA_SPATIAL_PREDICATE).not.toMatch(/\bOR\b/);
  });
});

describe('ZIP_SHARE_EXPR', () => {
  it('is a ratio of intersection area to ZIP area', () => {
    expect(ZIP_SHARE_EXPR).toContain('public.ST_Area(public.ST_Intersection');
    expect(ZIP_SHARE_EXPR).toContain('SELECT a FROM zcta');
  });
  it('guards against division by zero', () => {
    expect(ZIP_SHARE_EXPR).toContain('NULLIF');
  });
});

describe('buildZipDistrictQuery', () => {
  const sql = buildZipDistrictQuery();

  it('prepends the ZCTA CTE', () => {
    expect(sql.trimStart().startsWith('WITH zcta AS')).toBe(true);
  });

  it('selects share and the geofence name', () => {
    expect(sql).toContain('AS share');
    expect(sql).toContain('gb.name AS geofence_name');
  });

  it('orders by share descending with nulls last', () => {
    expect(sql).toContain('ORDER BY COALESCE(p.id, o.id), share DESC NULLS LAST');
  });

  it('reuses the shared district join, so it cannot drift from the address path', () => {
    expect(sql).toContain('FROM essentials.geofence_boundaries gb');
    expect(sql).toContain("(gb.mtfcc = 'G5210' AND d.district_type = 'STATE_UPPER')");
  });

  it('excludes challengers, like the address path', () => {
    expect(sql).toContain("NOT ILIKE 'Candidate for%'");
  });
});

describe('buildZipStatesQuery', () => {
  const sql = buildZipStatesQuery();

  it('reads the state-outline layer, whose geo_id is the state FIPS', () => {
    expect(sql).toContain("gb.mtfcc = 'G4000'");
  });

  it('applies the 1% floor so a trivial state-line clip adds no delegation', () => {
    expect(MULTI_STATE_SHARE_FLOOR).toBe(0.01);
    expect(sql).toContain('>= 0.01');
  });

  it('is index-driven', () => {
    expect(sql).toContain('OPERATOR(public.&&)');
  });

  it("excludes the national 'US' outline row that also lives in the G4000 layer", () => {
    // Verified in prod: G4000 holds exactly one non-FIPS row, geo_id 'US'
    // ("United States"), which covers every ZIP and is not a state.
    expect(sql).toContain("gb.geo_id ~ '^[0-9]{2}$'");
  });
});

describe('buildZipCountyQuery', () => {
  const sql = buildZipCountyQuery();

  it('returns the single county covering most of the ZIP', () => {
    expect(sql).toContain("gb.mtfcc = 'G4020'");
    expect(sql).toContain('ORDER BY public.ST_Area(public.ST_Intersection');
    expect(sql).toContain('DESC');
    expect(sql).toContain('LIMIT 1');
  });
});

describe('buildZctaExistsQuery', () => {
  it('distinguishes "not a real ZIP" from "real ZIP, nothing overlaps"', () => {
    const sql = buildZctaExistsQuery();
    expect(sql).toContain("mtfcc = 'G6350'");
    expect(sql).toContain('geo_id = $1');
    expect(sql).toContain('LIMIT 1');
  });
});

describe('ZIP cache key', () => {
  it('is versioned past the deleted stub key', () => {
    // The removed getCandidatesByZip wrote `candidates:zip:${zip}` holding every
    // active empowered_profile. Reusing that key would serve its wrong payload to
    // this reader for up to its 900s TTL after deploy.
    expect(ZIP_CACHE_KEY_PREFIX).toBe('candidates:zip:v2:');
    expect(ZIP_CACHE_KEY_PREFIX).not.toBe('candidates:zip:');
  });

  it('ends in a separator so keys cannot collide', () => {
    expect(ZIP_CACHE_KEY_PREFIX.endsWith(':')).toBe(true);
  });

  it('has a TTL on the order of an hour, not a day', () => {
    expect(ZIP_CACHE_TTL_SECONDS).toBe(3600);
  });
});

describe('rollUpAmbiguity', () => {
  it('counts DISTINCT DISTRICTS, not people — a multi-member body is not ambiguity', () => {
    // THE regression case. Measured against prod for ZIP 46220: 29 judges sit on
    // ONE county court, 10 officials serve ONE county, 7 board members serve ONE
    // school district. Every one of them serves the WHOLE ZIP. Counting people
    // would announce "29 judges serve parts of this ZIP code" — false.
    const rows = [
      ...Array.from({ length: 29 }, () => ({ district_type: 'JUDICIAL', geo_id: '18097' })),
      ...Array.from({ length: 10 }, () => ({ district_type: 'COUNTY', geo_id: '18097' })),
      ...Array.from({ length: 7 }, () => ({ district_type: 'SCHOOL', geo_id: '1804500' })),
    ];
    expect(rollUpAmbiguity(rows)).toEqual([]);
  });

  it('reports a district_type served by more than one district', () => {
    // Two state house districts overlapping the ZIP: the visitor is in one of
    // them and a ZIP cannot say which. That IS ambiguity.
    const rows = [
      { district_type: 'NATIONAL_LOWER', geo_id: '1807' },
      { district_type: 'STATE_UPPER', geo_id: '18033' },
      { district_type: 'STATE_UPPER', geo_id: '18034' },
      { district_type: 'STATE_UPPER', geo_id: '18035' },
      { district_type: 'STATE_LOWER', geo_id: '18086' },
      { district_type: 'STATE_LOWER', geo_id: '18087' },
      { district_type: 'STATE_LOWER', geo_id: '18095' },
      { district_type: 'STATE_LOWER', geo_id: '18096' },
    ];
    expect(rollUpAmbiguity(rows)).toEqual([
      { district_type: 'STATE_LOWER', count: 4 },
      { district_type: 'STATE_UPPER', count: 3 },
    ]);
  });

  it('counts a multi-member body across two districts as two, not as its seat count', () => {
    // Six council members across two council districts is an ambiguity of TWO.
    const rows = [
      ...Array.from({ length: 3 }, () => ({ district_type: 'CITY_COUNCIL', geo_id: 'A' })),
      ...Array.from({ length: 3 }, () => ({ district_type: 'CITY_COUNCIL', geo_id: 'B' })),
    ];
    expect(rollUpAmbiguity(rows)).toEqual([{ district_type: 'CITY_COUNCIL', count: 2 }]);
  });

  it('returns an empty array when every office is unambiguous', () => {
    // One US Representative for a ZIP is an ANSWER, not an ambiguity.
    expect(rollUpAmbiguity([
      { district_type: 'NATIONAL_LOWER', geo_id: '1807' },
      { district_type: 'COUNTY', geo_id: '18097' },
    ])).toEqual([]);
  });

  it('ignores rows with no district_type rather than counting an empty bucket', () => {
    expect(rollUpAmbiguity([
      { district_type: '', geo_id: 'a' }, { district_type: '', geo_id: 'b' },
    ])).toEqual([]);
  });

  it('returns an empty array for an empty input', () => {
    expect(rollUpAmbiguity([])).toEqual([]);
  });

  it('breaks count ties alphabetically so the output is deterministic', () => {
    const rows = [
      { district_type: 'SCHOOL', geo_id: 'a' }, { district_type: 'SCHOOL', geo_id: 'b' },
      { district_type: 'LOCAL', geo_id: 'c' }, { district_type: 'LOCAL', geo_id: 'd' },
    ];
    expect(rollUpAmbiguity(rows)).toEqual([
      { district_type: 'LOCAL', count: 2 },
      { district_type: 'SCHOOL', count: 2 },
    ]);
  });
});

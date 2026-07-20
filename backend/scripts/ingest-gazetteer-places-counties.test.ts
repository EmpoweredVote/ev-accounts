import { describe, it, expect } from 'vitest';

// The script's main() only auto-runs when `import.meta.url` matches
// `file://${process.argv[1]}` (see the isMainModule guard at the bottom of
// ingest-gazetteer-places-counties.ts) — under vitest that never matches, so
// importing it here is side-effect-free (no DB connect, no network call,
// no process.exit).
import {
  parsePlacesLine,
  parseCountiesLine,
  parsePlacesFile,
  parseCountiesFile,
  resolveHeaderIndex,
  buildPlacesUpsertSql,
  buildCountiesUpsertSql,
  placeRecordToParams,
  countyRecordToParams,
  transposeToColumnArrays,
} from './ingest-gazetteer-places-counties.js';

// ─── Fixtures ───────────────────────────────────────────────────────────────

const PLACES_HEADER =
  'USPS|GEOID|ANSICODE|NAME|LSAD|FUNCSTAT|ALAND|AWATER|ALAND_SQMI|AWATER_SQMI|INTPTLAT|INTPTLONG';

const PLACES_FIXTURE = [
  PLACES_HEADER,
  'IL|1770000|00428803|Chicago|25|A|589632533|18857038|227.658|7.281|+41.8375671|-87.6866143',
  'AZ|0465000|00025513|Sun City|57|S|59586843|239164|23.007|0.092|+33.5967631|-112.2721749',
].join('\n');

const COUNTIES_HEADER = 'USPS|GEOID|ANSICODE|NAME|ALAND|AWATER|ALAND_SQMI|AWATER_SQMI|INTPTLAT|INTPTLONG';

const COUNTIES_FIXTURE = [
  COUNTIES_HEADER,
  'IL|17031|01784709|Cook County|2447749139|1785476792|945.106|689.383|+41.8401381|-87.8168707',
  'MD|24510|01702381|Baltimore city|183686063|24473331|70.923|9.450|+39.3050803|-76.6151843',
].join('\n');

// ─── resolveHeaderIndex ─────────────────────────────────────────────────────

describe('resolveHeaderIndex', () => {
  it('resolves a column index by verified header field, case-insensitively', () => {
    const header = PLACES_HEADER.split('|');
    expect(resolveHeaderIndex(header, ['USPS'])).toBe(0);
    expect(resolveHeaderIndex(header, ['GEOID'])).toBe(1);
    expect(resolveHeaderIndex(header, ['NAME'])).toBe(3);
  });

  it('throws when none of the candidates are present (vintage/column-drift guard)', () => {
    const header = PLACES_HEADER.split('|');
    expect(() => resolveHeaderIndex(header, ['NOT_A_REAL_COLUMN'])).toThrow(
      /Gazetteer header resolution failed/,
    );
  });
});

// ─── parsePlacesLine / parsePlacesFile ──────────────────────────────────────

describe('parsePlacesLine', () => {
  it('parses a single Places data line into a record with trimmed fields', () => {
    const header = PLACES_HEADER.split('|');
    const line =
      'IL|1770000|00428803|Chicago|25|A|589632533|18857038|227.658|7.281|+41.8375671|-87.6866143';
    const record = parsePlacesLine(line, header);
    expect(record).not.toBeNull();
    expect(record!.geo_id).toBe('1770000');
    expect(record!.name).toBe('Chicago');
    expect(record!.state).toBe('IL');
    expect(record!.lsad).toBe('25');
    expect(record!.intptlat).toBe('+41.8375671');
    expect(record!.intptlong).toBe('-87.6866143');
  });

  it('returns null for a blank line', () => {
    const header = PLACES_HEADER.split('|');
    expect(parsePlacesLine('', header)).toBeNull();
    expect(parsePlacesLine('   ', header)).toBeNull();
  });

  it('maps a USPS field of "IL" to state "IL" verbatim (never inferred from name)', () => {
    const header = PLACES_HEADER.split('|');
    const line =
      'IL|1770000|00428803|Chicago|25|A|589632533|18857038|227.658|7.281|+41.8375671|-87.6866143';
    const record = parsePlacesLine(line, header)!;
    expect(record.state).toBe('IL');
  });
});

describe('parsePlacesFile', () => {
  it('parses a 3-line fixture (header + 2 data rows) into exactly 2 records', () => {
    const records = parsePlacesFile(PLACES_FIXTURE);
    expect(records).toHaveLength(2);
  });

  it('does not emit the header row as a record', () => {
    const records = parsePlacesFile(PLACES_FIXTURE);
    expect(records.some((r) => r.name === 'NAME')).toBe(false);
    expect(records.some((r) => r.geo_id === 'GEOID')).toBe(false);
  });

  it('correctly splits geo_id/name/state/lsad/intptlat/intptlong for each record', () => {
    const records = parsePlacesFile(PLACES_FIXTURE);
    expect(records[0]).toMatchObject({
      geo_id: '1770000',
      name: 'Chicago',
      state: 'IL',
      lsad: '25',
      intptlat: '+41.8375671',
      intptlong: '-87.6866143',
    });
    expect(records[1]).toMatchObject({
      geo_id: '0465000',
      name: 'Sun City',
      state: 'AZ',
      lsad: '57',
    });
  });

  it('skips blank lines', () => {
    const withBlank = PLACES_FIXTURE + '\n\n';
    const records = parsePlacesFile(withBlank);
    expect(records).toHaveLength(2);
  });
});

// ─── parseCountiesLine / parseCountiesFile ──────────────────────────────────

describe('parseCountiesLine', () => {
  it('parses a single Counties data line (no LSAD column)', () => {
    const header = COUNTIES_HEADER.split('|');
    const line = 'IL|17031|01784709|Cook County|2447749139|1785476792|945.106|689.383|+41.8401381|-87.8168707';
    const record = parseCountiesLine(line, header);
    expect(record).not.toBeNull();
    expect(record!.geo_id).toBe('17031');
    expect(record!.name).toBe('Cook County');
    expect(record!.state).toBe('IL');
  });
});

describe('parseCountiesFile', () => {
  it('parses a 3-line fixture (header + 2 data rows) into exactly 2 records, header not emitted', () => {
    const records = parseCountiesFile(COUNTIES_FIXTURE);
    expect(records).toHaveLength(2);
    expect(records[0]).toMatchObject({ geo_id: '17031', name: 'Cook County', state: 'IL' });
    expect(records[1]).toMatchObject({ geo_id: '24510', name: 'Baltimore city', state: 'MD' });
  });
});

// ─── Upsert SQL construction (idempotency-by-construction, D-11) ────────────

describe('upsert SQL construction (idempotency guarantee)', () => {
  it('buildPlacesUpsertSql contains ON CONFLICT (geo_id) DO UPDATE', () => {
    const sql = buildPlacesUpsertSql();
    expect(sql).toMatch(/ON CONFLICT \(geo_id\) DO UPDATE/);
    expect(sql).toMatch(/INSERT INTO essentials\.gazetteer_places/);
  });

  it('buildCountiesUpsertSql contains ON CONFLICT (geo_id) DO UPDATE', () => {
    const sql = buildCountiesUpsertSql();
    expect(sql).toMatch(/ON CONFLICT \(geo_id\) DO UPDATE/);
    expect(sql).toMatch(/INSERT INTO essentials\.gazetteer_counties/);
  });

  it('upsert SQL is batched via UNNEST (one round trip per batch, not per row — T-212-04)', () => {
    const placesSql = buildPlacesUpsertSql();
    const countiesSql = buildCountiesUpsertSql();
    // Fixed 7/6 array-typed params regardless of how many rows are inside
    // each array — this is what makes the SQL shape batch-size-independent.
    expect(placesSql).toMatch(/UNNEST\(\s*\$1::text\[\], \$2::text\[\], \$3::text\[\], \$4::text\[\],/);
    expect(countiesSql).toMatch(/UNNEST\(\s*\$1::text\[\], \$2::text\[\], \$3::numeric\[\],/);
  });

  it('placeRecordToParams/countyRecordToParams produce positional params matching the SQL column order', () => {
    const header = PLACES_HEADER.split('|');
    const line =
      'IL|1770000|00428803|Chicago|25|A|589632533|18857038|227.658|7.281|+41.8375671|-87.6866143';
    const record = parsePlacesLine(line, header)!;
    const params = placeRecordToParams(record);
    expect(params).toHaveLength(7);
    expect(params[0]).toBe('1770000');
    expect(params[1]).toBe('Chicago');
    expect(params[2]).toBe('IL');

    const cHeader = COUNTIES_HEADER.split('|');
    const cLine = 'IL|17031|01784709|Cook County|2447749139|1785476792|945.106|689.383|+41.8401381|-87.8168707';
    const cRecord = parseCountiesLine(cLine, cHeader)!;
    const cParams = countyRecordToParams(cRecord);
    expect(cParams).toHaveLength(6);
    expect(cParams[0]).toBe('17031');
    expect(cParams[1]).toBe('Cook County');
    expect(cParams[2]).toBe('IL');
  });
});

// ─── Batching (T-212-04: batched inserts, not one round-trip per row) ───────

describe('transposeToColumnArrays', () => {
  it('transposes N per-row tuples into column arrays for a single UNNEST call', () => {
    const rows = [
      ['g1', 'Name1', 'IL'],
      ['g2', 'Name2', 'AZ'],
      ['g3', 'Name3', 'MD'],
    ];
    const columns = transposeToColumnArrays(rows);
    expect(columns).toEqual([
      ['g1', 'g2', 'g3'],
      ['Name1', 'Name2', 'Name3'],
      ['IL', 'AZ', 'MD'],
    ]);
  });

  it('returns an empty array for zero rows', () => {
    expect(transposeToColumnArrays([])).toEqual([]);
  });

  it('round-trips real parsed records into a single set of column arrays (one query per batch, not per row)', () => {
    const records = parsePlacesFile(PLACES_FIXTURE);
    const rows = records.map(placeRecordToParams);
    const columns = transposeToColumnArrays(rows);
    // 7 columns (geo_id, name, state, lsad, aland_sqmi, intptlat, intptlong),
    // each column array holding one entry per source record (2 fixture rows).
    expect(columns).toHaveLength(7);
    expect(columns[0]).toEqual(['1770000', '0465000']); // geo_id column
    expect(columns[1]).toEqual(['Chicago', 'Sun City']); // name column
    expect(columns[2]).toEqual(['IL', 'AZ']); // state column
  });
});

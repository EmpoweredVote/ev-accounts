import { describe, it, expect, vi, beforeEach } from 'vitest';

const query = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query } }));

import { getCities } from './treasuryService.js';

/**
 * Unit coverage for GET /api/treasury/cities' optional `?slug=` filter.
 *
 * ⚠⚠ Lives under `src/` deliberately: CI runs `npm run test:unit`
 * (`vitest run src scripts`), so a contract asserted in `tests/integration/`
 * is asserted NOWHERE. Same reasoning as treasuryService.aliases.test.ts.
 *
 * What this protects: Treasury Tracker resolves `?entity=<slug>` deep links,
 * and financials.empowered.vote now asks for ONE entity by slug instead of
 * downloading all 8,149. The load-bearing property is that narrowing the
 * query cannot change WHICH entity comes back — it may return the same row or
 * nothing, never a different one (TT #158: an unmatched slug used to render
 * Bloomington, Indiana's budget).
 */

const NO_ROWS = { rows: [] };

/**
 * A real WHERE *clause* starts its own line.
 *
 * ⚠ Matching a bare /\bWHERE\b/ does NOT work here, and this cost a red test:
 * the summary projection contains `FILTER (WHERE b.id IS NOT NULL)` mid-line,
 * so a naive check reports a WHERE clause on the UNFILTERED query, and a naive
 * strip chews a hole in the projection instead of removing the clause.
 */
const WHERE_CLAUSE = /^[ \t]*WHERE .*\r?\n/m;

beforeEach(() => {
  query.mockReset();
  query.mockResolvedValue(NO_ROWS);
});

/** The SQL text of the single call made. */
const sql = () => query.mock.calls[0][0] as string;
/** The bound parameters of the single call made. */
const params = () => query.mock.calls[0][1] as unknown[];

describe('getCities — no slug (unchanged behaviour)', () => {
  it('emits no WHERE clause and binds no parameters', async () => {
    await getCities('summary');
    expect(sql()).not.toMatch(WHERE_CLAUSE);
    expect(params()).toEqual([]);
  });

  it('treats an explicit undefined slug as absent', async () => {
    await getCities('summary', undefined);
    expect(sql()).not.toMatch(WHERE_CLAUSE);
    expect(params()).toEqual([]);
  });
});

describe('getCities — slug filter', () => {
  it('binds the slug as a PARAMETER, never interpolated into the SQL', async () => {
    await getCities('summary', 'empowered-vote-ca');
    expect(params()).toEqual(['empowered-vote-ca']);
    // The value itself must not appear in the statement text.
    expect(sql()).not.toContain('empowered-vote-ca');
    expect(sql()).toMatch(WHERE_CLAUSE);
    expect(sql()).toMatch(/= \$1/);
  });

  it('is a WHERE clause only — it does not alter the row contract', async () => {
    await getCities('summary', 'empowered-vote-ca');
    const withSlug = sql();
    query.mockReset();
    query.mockResolvedValue(NO_ROWS);
    await getCities('summary');
    const withoutSlug = sql();

    // ⚠ THE LOAD-BEARING ASSERTION. Removing the WHERE clause from the filtered
    // query must reproduce the unfiltered query EXACTLY. If a future edit makes
    // the slug path also change the join, the GROUP BY, or the HAVING "has a
    // budget or is a grouper county" contract, this fails — because that is how
    // a narrowed query could start returning a row the full list would hide, or
    // hiding one it would show.
    const stripped = withSlug.replace(WHERE_CLAUSE, '');
    const norm = (s: string) => s.replace(/\s+/g, ' ').trim();
    expect(norm(stripped)).toBe(norm(withoutSlug));
  });

  it('keeps the HAVING contract on the filtered path', async () => {
    await getCities('summary', 'empowered-vote-ca');
    expect(sql()).toMatch(/HAVING COUNT\(b\.id\) > 0/);
    expect(sql()).toContain("m.entity_type = 'county'");
  });

  it('returns an empty array for a slug that matches nothing — never a substitute', async () => {
    query.mockResolvedValue(NO_ROWS);
    expect(await getCities('summary', 'no-such-place-zz')).toEqual([]);
  });

  it('uses the same slug expression the coverage endpoint publishes', async () => {
    await getCities('summary', 'x-y');
    // Byte-identical to TT's toSlug:
    //   `${name.toLowerCase().replace(/\s+/g, '-')}-${state.toLowerCase()}`
    expect(sql()).toContain("lower(regexp_replace(m.name, '\\s+', '-', 'g')) || '-' || lower(m.state)");
  });

  it('applies to full mode as well as summary mode', async () => {
    await getCities('full', 'empowered-vote-ca');
    expect(params()).toEqual(['empowered-vote-ca']);
    expect(sql()).toMatch(WHERE_CLAUSE);
  });
});

describe('getCities — entity_type / state / county_id filters', () => {
  it('binds every filter as a PARAMETER, never interpolated', async () => {
    await getCities('summary', undefined, {
      entityTypes: ['city', 'town'], state: 'CA',
      countyId: '391bf791-1c1f-424f-a7a5-1b698c79093f',
    });
    expect(params()).toEqual([
      ['city', 'town'], 'CA', '391bf791-1c1f-424f-a7a5-1b698c79093f',
    ]);
    expect(sql()).not.toContain('CA');
    expect(sql()).toMatch(WHERE_CLAUSE);
  });

  it('ANDs the filters together', async () => {
    await getCities('summary', undefined, { state: 'CA', entityTypes: ['county'] });
    expect(sql()).toMatch(/WHERE .* AND /);
  });

  it('uses = ANY for the type list, so one row cannot match twice', async () => {
    await getCities('summary', undefined, { entityTypes: ['city'] });
    expect(sql()).toMatch(/m\.entity_type = ANY\(\$1\)/);
  });

  // ⚠ THE LOAD-BEARING ASSERTION, same as the slug path's. Stripping the WHERE
  // clause must reproduce the unfiltered query EXACTLY — that is what stops a
  // narrowed query returning a row the full list would hide, or hiding one it
  // would show.
  it('is a WHERE clause only — it does not alter the row contract', async () => {
    await getCities('summary', undefined, { state: 'CA' });
    const filtered = sql();
    query.mockReset();
    query.mockResolvedValue(NO_ROWS);
    await getCities('summary');
    const unfiltered = sql();
    const norm = (s: string) => s.replace(/\s+/g, ' ').trim();
    expect(norm(filtered.replace(WHERE_CLAUSE, ''))).toBe(norm(unfiltered));
  });

  it('keeps the HAVING contract on the filtered path', async () => {
    await getCities('summary', undefined, { state: 'CA' });
    expect(sql()).toMatch(/HAVING COUNT\(b\.id\) > 0/);
    expect(sql()).toContain("m.entity_type = 'county'");
  });

  it('combines with the slug filter, numbering parameters in order', async () => {
    await getCities('summary', 'los-angeles-ca', { state: 'CA' });
    expect(params()).toEqual(['los-angeles-ca', 'CA']);
    expect(sql()).toMatch(/= \$1/);
    expect(sql()).toMatch(/m\.state = \$2/);
  });

  it('treats empty and absent filters as no filter at all', async () => {
    await getCities('summary', undefined, {});
    expect(sql()).not.toMatch(WHERE_CLAUSE);
    expect(params()).toEqual([]);
    query.mockReset();
    query.mockResolvedValue(NO_ROWS);
    await getCities('summary', undefined, { entityTypes: [] });
    expect(sql()).not.toMatch(WHERE_CLAUSE);
    expect(params()).toEqual([]);
  });

  it('returns an empty array when nothing matches — never a substitute', async () => {
    query.mockResolvedValue(NO_ROWS);
    expect(await getCities('summary', undefined, { state: 'ZZ' })).toEqual([]);
  });
});

describe('getCities — ?fields=index', () => {
  it('selects only the index columns and a has_data flag', async () => {
    await getCities('summary', undefined, { fields: 'index' });
    const s = sql();
    expect(s).toContain('m.id');
    expect(s).toContain('m.county_id');
    expect(s).toMatch(/COUNT\(b\.id\) > 0\) AS has_data/);
    // The heavy things must be gone.
    expect(s).not.toContain('m.hero_image_url');
    expect(s).not.toContain('m.population');
    expect(s).not.toContain('dataset_summary');
    expect(s).not.toContain('available_datasets');
  });

  it('keeps the HAVING contract, so index rows are the same population', async () => {
    await getCities('summary', undefined, { fields: 'index' });
    expect(sql()).toMatch(/HAVING COUNT\(b\.id\) > 0/);
  });

  it('maps rows to the lean shape with has_data as a real boolean', async () => {
    query.mockResolvedValue({ rows: [{
      id: 'c1', name: 'Testville', state: 'CA', entity_type: 'city',
      county_id: null, has_data: true, latest_year: '2024',
    }] });
    const [row] = await getCities('summary', undefined, { fields: 'index' });
    expect(row).toEqual({
      id: 'c1', name: 'Testville', state: 'CA', entity_type: 'city',
      county_id: null, has_data: true, latest_year: 2024,
    });
  });

  it('composes with the other filters', async () => {
    await getCities('summary', undefined, { fields: 'index', state: 'CA' });
    expect(params()).toEqual(['CA']);
    expect(sql()).toMatch(WHERE_CLAUSE);
  });

  it('carries the newest fiscal year in the index projection', async () => {
    await getCities('summary', undefined, { fields: 'index' });
    expect(sql()).toMatch(/MAX\(b\.fiscal_year\) AS latest_year/);
  });

  it('coerces latest_year from the string node-postgres returns for bigint', async () => {
    query.mockResolvedValue({ rows: [{
      id: 'c1', name: 'Testville', state: 'CA', entity_type: 'city',
      county_id: null, has_data: true, latest_year: '2024',
    }] });
    const [row] = await getCities('summary', undefined, { fields: 'index' });
    expect(row).toEqual({
      id: 'c1', name: 'Testville', state: 'CA', entity_type: 'city',
      county_id: null, has_data: true, latest_year: 2024,
    });
  });

  it('reports a null latest_year for an entity with no budget rows', async () => {
    query.mockResolvedValue({ rows: [{
      id: 'c2', name: 'Grouper County', state: 'MI', entity_type: 'county',
      county_id: null, has_data: false, latest_year: null,
    }] });
    const [row] = await getCities('summary', undefined, { fields: 'index' });
    expect(row).toEqual({
      id: 'c2', name: 'Grouper County', state: 'MI', entity_type: 'county',
      county_id: null, has_data: false, latest_year: null,
    });
  });
});

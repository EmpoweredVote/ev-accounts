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

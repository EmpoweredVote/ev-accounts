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
/** The matched WHERE clause text (empty string if none). */
const whereClauseText = (s: string) => (s.match(WHERE_CLAUSE) ?? [''])[0];

/**
 * The "has a budget, or is a grouper county" rule, in whichever form the mode
 * emits it.
 *
 * ⚠⚠ ASSERT THE RULE, NOT THE KEYWORD. These tests used to match the literal
 * `HAVING COUNT(b.id) > 0`, which made the keyword the contract instead of the
 * population it selects. Index and summary mode now aggregate inside a LATERAL
 * and spell the same rule `s.budget_count > 0` in a WHERE; full mode still
 * spells it `COUNT(b.id) > 0` in a HAVING, because its array ordering is a
 * documented byte-for-byte contract (see DATASETS_FULL). Both forms admit
 * exactly the same entities, which is the property worth defending — so this
 * accepts either spelling and still fails if the rule goes missing entirely.
 */
const BUDGET_BEARING_RULE = /(HAVING COUNT\(b\.id\)|s\.budget_count) > 0/;

/** Every mode must keep the grouper-county half of the rule too. */
const expectBudgetBearingRule = (s: string) => {
  expect(s).toMatch(BUDGET_BEARING_RULE);
  expect(s).toContain("m.entity_type = 'county'");
  expect(s).toContain('child.county_id = m.id');
};

describe('getCities — no slug (unchanged behaviour)', () => {
  /**
   * ⚠ These two used to assert `not.toMatch(WHERE_CLAUSE)`. That stopped being
   * the right assertion when summary mode moved its budget-bearing rule out of
   * a HAVING and into the WHERE: an unfiltered summary query now HAS a WHERE
   * clause, and it always will. What "no filter" actually means is that nothing
   * the CALLER supplied reached the statement — no bound parameter, and no
   * condition beyond the rule every call carries. That is what these now check,
   * and unlike the old form it would still fail if an unbound caller filter
   * were interpolated into the clause.
   */
  it('binds no parameters and adds no caller condition', async () => {
    await getCities('summary');
    expect(params()).toEqual([]);
    expect(whereClauseText(sql())).not.toMatch(/\$\d/);
    expect(whereClauseText(sql())).not.toMatch(/ AND /);
    expectBudgetBearingRule(sql());
  });

  it('treats an explicit undefined slug as absent', async () => {
    await getCities('summary', undefined);
    expect(params()).toEqual([]);
    expect(whereClauseText(sql())).not.toMatch(/\$\d/);
    expect(whereClauseText(sql())).not.toMatch(/ AND /);
  });

  it('full mode still has no WHERE clause at all when unfiltered', async () => {
    // Full mode keeps the join-and-GROUP-BY shape, so with no caller filter it
    // emits no WHERE clause whatsoever — the original property, still true for
    // the one mode that still works that way.
    await getCities('full', undefined, { state: undefined });
    expect(params()).toEqual([]);
    expect(sql()).not.toMatch(WHERE_CLAUSE);
    expect(sql()).toMatch(/HAVING COUNT\(b\.id\) > 0/);
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

    // ⚠ THE LOAD-BEARING ASSERTION. Everything outside the WHERE clause must be
    // identical, and the filtered WHERE must be the unfiltered WHERE with the
    // caller's condition ADDED — never a different rule. If a future edit makes
    // the slug path also change the join, the lateral, the projection or the
    // "has a budget or is a grouper county" rule, this fails, because that is
    // how a narrowed query could start returning a row the full list would
    // hide, or hiding one it would show.
    const norm = (s: string) => s.replace(/\s+/g, ' ').trim();
    expect(norm(withSlug.replace(WHERE_CLAUSE, ''))).toBe(
      norm(withoutSlug.replace(WHERE_CLAUSE, ''))
    );

    // The unfiltered rule survives verbatim inside the filtered clause, so the
    // filter can only ever narrow the population, never redefine it.
    const ruleOf = (s: string) => norm(whereClauseText(s)).replace(/^WHERE /, '');
    expect(norm(whereClauseText(withSlug))).toContain(ruleOf(withoutSlug));
    expect(norm(whereClauseText(withSlug))).toMatch(/ AND /);
  });

  it('keeps the budget-bearing rule on the filtered path', async () => {
    await getCities('summary', 'empowered-vote-ca');
    expectBudgetBearingRule(sql());
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
    expect(norm(filtered.replace(WHERE_CLAUSE, ''))).toBe(
      norm(unfiltered.replace(WHERE_CLAUSE, ''))
    );

    // ...and the filtered clause is the unfiltered rule plus the caller's
    // condition, never a replacement for it.
    const ruleOf = (s: string) => norm(whereClauseText(s)).replace(/^WHERE /, '');
    expect(norm(whereClauseText(filtered))).toContain(ruleOf(unfiltered));
  });

  it('keeps the budget-bearing rule on the filtered path', async () => {
    await getCities('summary', undefined, { state: 'CA' });
    expectBudgetBearingRule(sql());
  });

  // ⚠⚠ THE PROPERTY "WHERE clause only" ACTUALLY NEEDS. Stripping the WHERE
  // clause (the assertion above) only proves the REST of the query is
  // untouched — it does NOT prove the WHERE clause itself is safe. A future
  // filter written as `WHERE b.fiscal_year = $1` would strip just as cleanly
  // as any other single-line WHERE and pass that assertion, yet it would turn
  // the LEFT JOIN into an effective INNER JOIN: grouper counties (no budget
  // rows of their own) would drop out, and every surviving row's
  // available_datasets/dataset_summary would be silently narrowed to one
  // fiscal year. So assert directly that every filter constrains the m side
  // only. (SLUG_SQL is built from m.name/m.state, so it never trips this.)
  it('every WHERE condition constrains treasury.municipalities (m), never the joined budgets (b)', async () => {
    await getCities('summary', 'x-y', {
      entityTypes: ['city'], state: 'CA',
      countyId: '391bf791-1c1f-424f-a7a5-1b698c79093f',
    });
    const clause = whereClauseText(sql());
    expect(clause).not.toBe('');
    expect(clause).not.toMatch(/\bb\./);
  });

  it('combines with the slug filter, numbering parameters in order', async () => {
    await getCities('summary', 'los-angeles-ca', { state: 'CA' });
    expect(params()).toEqual(['los-angeles-ca', 'CA']);
    expect(sql()).toMatch(/= \$1/);
    expect(sql()).toMatch(/m\.state = \$2/);
  });

  it('treats empty and absent filters as no filter at all', async () => {
    await getCities('summary', undefined, {});
    const bare = sql();
    expect(params()).toEqual([]);
    expect(whereClauseText(bare)).not.toMatch(/ AND /);
    query.mockReset();
    query.mockResolvedValue(NO_ROWS);
    await getCities('summary', undefined, { entityTypes: [] });
    expect(params()).toEqual([]);
    // An empty filter list must produce the same statement as no filter at all.
    expect(sql()).toBe(bare);
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
    expect(s).toMatch(/\(s\.budget_count > 0\) AS has_data/);
    // The heavy things must be gone.
    expect(s).not.toContain('m.hero_image_url');
    expect(s).not.toContain('m.population');
    expect(s).not.toContain('dataset_summary');
    expect(s).not.toContain('available_datasets');
  });

  it('keeps the budget-bearing rule, so index rows are the same population', async () => {
    await getCities('summary', undefined, { fields: 'index' });
    expectBudgetBearingRule(sql());
  });

  it('maps rows to the lean shape, coercing latest_year from the bigint-as-string node-postgres returns', async () => {
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

  // ⚠ Load-bearing: null must stay null, not coerce to 0 or NaN — that would
  // make a grouper county with no budgets of its own look like it has one.
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

/**
 * ⚠⚠⚠ THE SHAPE SPLIT ITSELF, PINNED.
 *
 * `getCities` deliberately emits TWO different query shapes, and a well-meaning
 * "let's make this consistent" refactor in either direction breaks something
 * real and silent:
 *
 *  - Moving FULL mode onto the lateral reorders `available_datasets`. Entities
 *    routinely hold several budget rows per fiscal year (two fund scopes, two
 *    bases) and `ORDER BY b.fiscal_year DESC` leaves those ties UNSPECIFIED, so
 *    the join shape and the lateral shape disagree. Measured against production
 *    on Michigan: same 1,857 entities, same counts, and **1,857 of 1,857** rows
 *    with a differently ordered array. Full mode is a documented byte-for-byte
 *    cross-app contract, so that is a breaking change for any consumer reading
 *    the array positionally.
 *
 *  - Moving SUMMARY or INDEX mode back onto the join costs the index-only scan
 *    and puts ~1.1 seconds back on the landing page's first request, because
 *    `b.id` is not in `idx_budget_municipality_year_type` and `COUNT(b.id)`
 *    therefore has to visit the heap for all 585,630 budget rows.
 *
 * Neither failure shows up in a smoke test: both shapes return the right
 * entities, and one of them is merely slow while the other is merely reordered.
 */
describe('getCities — the two query shapes', () => {
  it('uses the lateral for summary and index mode, and reads no column outside the covering index', async () => {
    for (const filters of [{}, { fields: 'index' as const }]) {
      query.mockReset();
      query.mockResolvedValue(NO_ROWS);
      await getCities('summary', undefined, filters);
      const s = sql();
      expect(s).toContain('LEFT JOIN LATERAL');
      expect(s).not.toMatch(/\bGROUP BY\b/);
      expect(s).not.toMatch(/\bHAVING\b/);
      // The whole point: no reference to a budgets column the index lacks.
      // `b.id`, `reporting_entity`, `derivation` and `audit_grade` are the ones
      // that silently cost the index-only scan.
      expect(s).not.toMatch(/\bb\.id\b/);
      expect(s).not.toMatch(/\bb\.(reporting_entity|derivation|audit_grade)\b/);
    }
  });

  it('keeps full mode on the join-and-GROUP-BY shape, so array ordering cannot shift', async () => {
    await getCities('full', 'plano-tx');
    const s = sql();
    expect(s).not.toContain('LEFT JOIN LATERAL');
    expect(s).toContain('LEFT JOIN treasury.budgets b ON b.municipality_id = m.id');
    expect(s).toMatch(/GROUP BY m\.id/);
    expect(s).toMatch(/HAVING COUNT\(b\.id\) > 0/);
    expect(s).toMatch(/ORDER BY b\.fiscal_year DESC/);
  });

  it('every shape still orders the entity list by name', async () => {
    for (const [mode, filters] of [
      ['summary', {}], ['summary', { fields: 'index' as const }], ['full', {}],
    ] as const) {
      query.mockReset();
      query.mockResolvedValue(NO_ROWS);
      await getCities(mode, 'plano-tx', filters);
      expect(sql()).toMatch(/ORDER BY m\.name\s*$/);
    }
  });
});

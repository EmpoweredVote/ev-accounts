import { describe, it, expect, vi } from 'vitest';

const query = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query } }));

import { getEntityAliases } from './treasuryService.js';

/**
 * Unit coverage for GET /api/treasury/aliases' payload.
 *
 * ⚠⚠ THIS FILE EXISTS BECAUSE THE INTEGRATION TEST DOES NOT RUN. CI runs
 * `npm run test:unit` — `vitest run src scripts` — which does not include
 * `tests/integration/`, and that suite skips without a live database anyway.
 * A contract asserted only there is asserted nowhere. These live under `src/`
 * so they actually execute on every PR.
 *
 * What they protect: Treasury Tracker resolves `?entity=<slug>` deep links
 * against this payload, so its shape decides WHICH ENTITY A READER LANDS ON.
 */

const row = {
  slug: 'birchwood-mn',
  label: 'Birchwood',
  canonical_slug: 'birchwood-village-mn',
  canonical_label: 'Birchwood Village',
};

const rows = (...r: Array<Record<string, string>>) => query.mockResolvedValueOnce({ rows: r });

describe('getEntityAliases — payload contract', () => {
  it('maps a row to slug / label / canonicalSlug / canonicalLabel', async () => {
    rows(row);
    expect(await getEntityAliases()).toEqual([
      {
        slug: 'birchwood-mn',
        label: 'Birchwood',
        canonicalSlug: 'birchwood-village-mn',
        canonicalLabel: 'Birchwood Village',
      },
    ]);
  });

  // ⚠⚠ THE LOAD-BEARING ASSERTION, AND IT IS THE OPPOSITE OF WHAT THIS FILE
  // FIRST ASSERTED. An earlier draft forbade slug keys, on the theory that a
  // second implementation of TT's `toSlug` would drift silently. But this
  // service already owns one (`SLUG_SQL`), and /api/treasury/coverage already
  // emits `slug` precisely so "no consumer ever reconstructs TT's toSlug and
  // drifts". Withholding slugs forces every non-TT consumer to write their own.
  it('emits a slug for both sides, so no consumer reconstructs toSlug', async () => {
    rows(row);
    const [alias] = await getEntityAliases();
    expect(alias).toHaveProperty('slug', 'birchwood-mn');
    expect(alias).toHaveProperty('canonicalSlug', 'birchwood-village-mn');
    expect(Object.keys(alias!).sort()).toEqual(['canonicalLabel', 'canonicalSlug', 'label', 'slug']);
  });

  // ⚠ The two slugs must come from ONE expression. `slugSql(nameCol, stateCol)`
  // is that expression; the coverage catalog's SLUG_SQL is now a call to it.
  // If someone inlines a second regexp here, the alias side and the entity side
  // can disagree — and disagreement does not throw, it just stops matching.
  it('derives both slugs from the same SQL expression', async () => {
    rows(row);
    await getEntityAliases();
    const sql = String(query.mock.calls.at(-1)?.[0] ?? '');
    const slugExprs = sql.match(/lower\(regexp_replace\(/g) ?? [];
    expect(slugExprs, 'expected exactly two slug expressions, alias side and canonical side')
      .toHaveLength(2);
    // Same shape on both sides, differing only in the columns fed to it.
    expect(sql).toMatch(/lower\(regexp_replace\(a\.alias_name, '\\s\+', '-', 'g'\)\) \|\| '-' \|\| lower\(a\.state\)/);
    expect(sql).toMatch(/lower\(regexp_replace\(m\.name, '\\s\+', '-', 'g'\)\) \|\| '-' \|\| lower\(m\.state\)/);
  });

  it('returns an empty array when there are no aliases', async () => {
    rows();
    expect(await getEntityAliases()).toEqual([]);
  });

  it("passes every row through — filtering is the consumer's decision", async () => {
    rows(row, {
      slug: 'marine-on-st-croix-mn',
      label: 'Marine on St Croix',
      canonical_slug: 'marine-on-saint-croix-mn',
      canonical_label: 'Marine on Saint Croix',
    });
    expect(await getEntityAliases()).toHaveLength(2);
  });

  it('joins municipalities so the canonical side is the CURRENT name', async () => {
    rows(row);
    await getEntityAliases();
    const sql = String(query.mock.calls.at(-1)?.[0] ?? '');
    // The alias table stores only the retired name; the live name and its slug
    // must come from municipalities, or a later rename leaves this payload stale.
    expect(sql).toMatch(/JOIN\s+treasury\.municipalities/i);
    expect(sql).toMatch(/m\.name\s+AS\s+canonical_label/i);
  });
});

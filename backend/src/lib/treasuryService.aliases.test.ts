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

const rows = (...r: Array<{ alias_name: string; state: string; canonical_name: string }>) =>
  query.mockResolvedValueOnce({ rows: r });

describe('getEntityAliases — payload contract', () => {
  it('maps a row to aliasName / state / canonicalName', async () => {
    rows({ alias_name: 'Birchwood', state: 'MN', canonical_name: 'Birchwood Village' });
    expect(await getEntityAliases()).toEqual([
      { aliasName: 'Birchwood', state: 'MN', canonicalName: 'Birchwood Village' },
    ]);
  });

  // ⚠⚠ THE LOAD-BEARING ASSERTION. The slug format `<name-hyphenated>-<state>`
  // is owned by Treasury Tracker's `toSlug`. If someone "helpfully" adds a slug
  // to this payload, a second implementation of that format exists — and when
  // the two drift it does not throw, it silently stops matching, so aliases
  // present as missing data rather than as a bug. Fail here instead.
  it('emits NAMES only — no slug key may appear', async () => {
    rows({ alias_name: 'Birchwood', state: 'MN', canonical_name: 'Birchwood Village' });
    const [alias] = await getEntityAliases();
    expect(Object.keys(alias!).sort()).toEqual(['aliasName', 'canonicalName', 'state']);
    for (const forbidden of ['slug', 'canonical', 'canonicalSlug', 'aliasSlug']) {
      expect(alias).not.toHaveProperty(forbidden);
    }
  });

  it('returns an empty array when there are no aliases', async () => {
    rows();
    expect(await getEntityAliases()).toEqual([]);
  });

  it('passes every row through — filtering is the consumer\'s decision', async () => {
    rows(
      { alias_name: 'Birchwood', state: 'MN', canonical_name: 'Birchwood Village' },
      { alias_name: 'Marine on St Croix', state: 'MN', canonical_name: 'Marine on Saint Croix' }
    );
    expect(await getEntityAliases()).toHaveLength(2);
  });

  it('joins municipalities so the canonical name is the CURRENT one', async () => {
    rows({ alias_name: 'Birchwood', state: 'MN', canonical_name: 'Birchwood Village' });
    await getEntityAliases();
    const sql = String(query.mock.calls.at(-1)?.[0] ?? '');
    // The alias table stores only the retired name; the live name must come
    // from municipalities, or a later rename would leave this payload stale.
    expect(sql).toMatch(/JOIN\s+treasury\.municipalities/i);
    expect(sql).toMatch(/m\.name\s+AS\s+canonical_name/i);
  });
});

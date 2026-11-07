/**
 * What `is_incumbent` gets set to when an admin creates a politician.
 *
 * 🔴 THIS WAS THE CA_0188 DEFECT, STILL LIVE IN A WRITE PATH. `adminCreatePolitician` defaulted
 * `is_incumbent` to TRUE, and the route's `CreatePoliticianSchema` does not carry the field at
 * all — so `data.is_incumbent` was always `undefined` and the default always fired. Every
 * politician created through POST /api/admin/compass/politicians was marked a sitting
 * officeholder whether or not they held anything.
 *
 * Worse, the schema DOES accept `is_candidate`, and that value was silently discarded: the
 * function's parameter type has no such field, so an admin who ticked "is candidate" got a row
 * asserting the exact opposite. CA_0188 created 1,817 active "incumbents" with no seat; this is
 * the same shape, one endpoint at a time.
 *
 * CLAUDE.md: set `politicians.is_incumbent` EXPLICITLY on every insert. The column now defaults
 * to false, and an unseated person is not an incumbent — so an unstated value resolves to false,
 * which the daily reconciler then corrects upward if the person really does hold a seat.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('./env.js', () => ({ env: {} }));
vi.mock('./supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('./empowerService.js', () => ({ executeDemotion: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { pool } from './db.js';
import { adminCreatePolitician } from './adminService.js';

/** The value bound to the is_incumbent placeholder of the INSERT. */
async function incumbentParamFor(data: Record<string, unknown>): Promise<unknown> {
  const query = vi.mocked(pool.query);
  query.mockReset();
  query.mockResolvedValue({ rows: [{ id: 'p1' }] } as never);
  await adminCreatePolitician(data as never);
  const call = query.mock.calls[0] as unknown as [string, unknown[]];
  const [sql, params] = call;
  const cols = sql.slice(sql.indexOf('(') + 1, sql.indexOf(')')).split(',').map((c) => c.trim());
  return params[cols.indexOf('is_incumbent')];
}

describe('adminCreatePolitician — is_incumbent', () => {
  beforeEach(() => vi.mocked(pool.query).mockReset());

  it('is false when the caller says nothing, not true', () => {
    // The old default. An admin creating a record asserts nothing about occupancy, and
    // office_terms is the only thing that can.
    return expect(incumbentParamFor({ first_name: 'A', last_name: 'B' })).resolves.toBe(false);
  });

  it('is false when the admin marked them a candidate', () => {
    // 🔴 The field the route accepts and the code used to throw away.
    return expect(
      incumbentParamFor({ first_name: 'A', last_name: 'B', is_candidate: true }),
    ).resolves.toBe(false);
  });

  it('is true when the admin marked them NOT a candidate', () => {
    return expect(
      incumbentParamFor({ first_name: 'A', last_name: 'B', is_candidate: false }),
    ).resolves.toBe(true);
  });

  it('an explicit is_incumbent still wins over is_candidate', () => {
    return expect(
      incumbentParamFor({ first_name: 'A', last_name: 'B', is_candidate: true, is_incumbent: true }),
    ).resolves.toBe(true);
  });

  it('names is_incumbent in the INSERT column list, so check:occupancy can see it', () => {
    const query = vi.mocked(pool.query);
    query.mockReset();
    query.mockResolvedValue({ rows: [{ id: 'p1' }] } as never);
    return adminCreatePolitician({ first_name: 'A', last_name: 'B' } as never).then(() => {
      expect(String(query.mock.calls[0][0])).toMatch(/is_incumbent/);
    });
  });
});
